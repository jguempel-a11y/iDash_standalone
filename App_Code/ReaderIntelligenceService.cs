using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;

/// <summary>
/// ReaderIntelligenceService.cs
/// 
/// Provides dwell-time analysis, location mismatch detection, and
/// automatic location reassignment based on fixed reader observations.
///
/// LOGIC OVERVIEW:
/// 1. Fixed readers update asset.lastobservedtime + asset.lastobservedlocation
///    every time they see a tag.
/// 2. If lastobservedlocation differs from the asset's assigned location
///    (location.name via locationid), the asset is a "mismatch."
/// 3. If the mismatch has persisted for >= dwellTimeHours, the asset
///    is a "dwell candidate" for reassignment.
/// 4. If autoReassignLocation is ON, the system updates locationid
///    to match the observed location automatically.
///
/// This uses the simpler approach (lastobservedtime only, no locationhistory
/// dependency) for maximum reliability across all iDash installations.
///
/// AUDIT TRAIL: All auto-reassignments set lastmodifiedby = 'ReaderIntelligence'
/// so they can be traced/queried later.
/// </summary>
public static class ReaderIntelligenceService
{
    private static readonly string ConfigPath = HttpContext.Current != null
        ? HttpContext.Current.Server.MapPath("~/config/reader_intelligence.json")
        : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config", "reader_intelligence.json");

    private static string ConnStr
    {
        get { return WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    // ═══════════════════════════════════════════════════════════════
    //  CONFIG — Load / Save
    // ═══════════════════════════════════════════════════════════════

    public class IntelConfig
    {
        public int    dwellTimeHours           { get; set; }
        public bool   autoReassignLocation     { get; set; }
        public int    departureTimeoutMinutes   { get; set; }
        public string reportCron               { get; set; }
        public bool   emailReport              { get; set; }
        public string emailRecipients          { get; set; }
        public bool   observationMismatchAlert { get; set; }
        public int    recentWindowDays         { get; set; }
        public List<string> readerIdentities     { get; set; }
        public string lastDwellCheckUtc        { get; set; }
        public int    lastReassignmentCount    { get; set; }

        public IntelConfig()
        {
            dwellTimeHours = 24;
            autoReassignLocation = false;
            departureTimeoutMinutes = 60;
            reportCron = "0 6 * * *";
            emailReport = false;
            emailRecipients = "";
            observationMismatchAlert = true;
            recentWindowDays = 7;
            readerIdentities = new List<string> { "Web Server", "ReaderIntelligence" };
            lastDwellCheckUtc = null;
            lastReassignmentCount = 0;
        }
    }

    public static IntelConfig LoadConfig()
    {
        string path = GetConfigPath();
        if (!File.Exists(path))
            return new IntelConfig();

        try
        {
            string json = File.ReadAllText(path);
            var jss = new JavaScriptSerializer();
            return jss.Deserialize<IntelConfig>(json) ?? new IntelConfig();
        }
        catch
        {
            return new IntelConfig();
        }
    }

    public static void SaveConfig(IntelConfig config)
    {
        string path = GetConfigPath();
        string dir = Path.GetDirectoryName(path);
        if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

        var jss = new JavaScriptSerializer();
        string json = jss.Serialize(config);
        // Pretty-print the JSON
        json = PrettyJson(json);
        File.WriteAllText(path, json);
    }

    private static string GetConfigPath()
    {
        try { return HttpContext.Current.Server.MapPath("~/config/reader_intelligence.json"); }
        catch { return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config", "reader_intelligence.json"); }
    }

    // ═══════════════════════════════════════════════════════════════
    //  MISMATCH DETECTION — Assets where observed ≠ assigned
    // ═══════════════════════════════════════════════════════════════

    public class MismatchAsset
    {
        public long   AssetId           { get; set; }
        public string AssetName         { get; set; }
        public string ObservedLocation  { get; set; }
        public string AssignedLocation  { get; set; }
        public string LastObservedTime  { get; set; }
        public int    HoursAtLocation   { get; set; }
        public bool   ExceedsThreshold  { get; set; }
        public int    CompanyId         { get; set; }
        public string CompanyName       { get; set; }
    }

    /// <summary>
    /// Returns all assets where lastobservedlocation differs from assigned location.
    /// Optionally filtered by companyId (0 = all).
    /// </summary>
    public static List<MismatchAsset> GetMismatchedAssets(int companyId = 0, int readerSiteId = 0)
    {
        var config = LoadConfig();
        var results = new List<MismatchAsset>();

        string companyFilter = companyId > 0
            ? " AND a.companyid = @companyId"
            : "";
        string readerSiteFilter = readerSiteId > 0
            ? " AND a.lastobservedlocation IN (SELECT name FROM dbo.location WHERE companyid = @readerSiteId)" +
              // CRITICAL: only assets that BELONG to the reader's site are mismatch candidates.
              // Cross-site assets observed by this reader are visitors — never reassign them.
              " AND a.companyid = @readerSiteId"
            : "";

        // Always-on guard: the observed location must belong to the SAME company as the asset.
        // This ensures cross-site visitors (e.g. Baltimore assets seen by a Martinsburg reader)
        // NEVER appear as reassignment candidates, regardless of the reader site dropdown.
        string intraFilter = @"
              AND EXISTS (
                  SELECT 1 FROM dbo.location lobs
                  WHERE lobs.name = a.lastobservedlocation
                    AND lobs.companyid = a.companyid
              )";

        string sql = @"
            SELECT 
                a.id AS AssetId,
                a.name AS AssetName,
                a.lastobservedlocation AS ObservedLocation,
                ISNULL(l.name, '(none)') AS AssignedLocation,
                a.lastobservedtime AS LastObservedTime,
                DATEDIFF(HOUR, a.lastobservedtime, GETDATE()) AS HoursAtLocation,
                a.companyid AS CompanyId,
                ISNULL(c.name, '') AS CompanyName
            FROM dbo.asset a
            LEFT JOIN dbo.location l ON a.locationid = l.id
            LEFT JOIN dbo.company c ON a.companyid = c.id
            WHERE a.lastobservedlocation IS NOT NULL
              AND a.lastobservedlocation <> ''
              AND a.lastobservedtime IS NOT NULL
              AND a.lastobservedtime >= DATEADD(DAY, -@recentDays, GETDATE())
              AND (l.name IS NULL OR l.name <> a.lastobservedlocation)"
            + intraFilter + companyFilter + readerSiteFilter +
            " ORDER BY DATEDIFF(HOUR, a.lastobservedtime, GETDATE()) ASC, a.name";

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.CommandTimeout = 60;
                cmd.Parameters.AddWithValue("@recentDays", config.recentWindowDays > 0 ? config.recentWindowDays : 7);
                if (companyId > 0) cmd.Parameters.AddWithValue("@companyId", companyId);
                if (readerSiteId > 0) cmd.Parameters.AddWithValue("@readerSiteId", readerSiteId);

                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        int hours = rdr["HoursAtLocation"] != DBNull.Value
                            ? Convert.ToInt32(rdr["HoursAtLocation"]) : 0;

                        results.Add(new MismatchAsset
                        {
                            AssetId = Convert.ToInt64(rdr["AssetId"]),
                            AssetName = rdr["AssetName"].ToString(),
                            ObservedLocation = rdr["ObservedLocation"].ToString(),
                            AssignedLocation = rdr["AssignedLocation"].ToString(),
                            LastObservedTime = rdr["LastObservedTime"].ToString(),
                            HoursAtLocation = hours,
                            ExceedsThreshold = hours >= config.dwellTimeHours,
                            CompanyId = rdr["CompanyId"] != DBNull.Value
                                ? Convert.ToInt32(rdr["CompanyId"]) : 0,
                            CompanyName = rdr["CompanyName"].ToString()
                        });
                    }
                }
            }
        }

        return results;
    }

    /// <summary>
    /// Returns only assets that exceed the dwell time threshold — candidates for reassignment.
    /// </summary>
    public static List<MismatchAsset> GetDwellCandidates(int companyId = 0, int readerSiteId = 0)
    {
        return GetMismatchedAssets(companyId, readerSiteId)
            .FindAll(a => a.ExceedsThreshold);
    }

    // ═══════════════════════════════════════════════════════════════
    //  REASSIGNMENT — Update assigned location to match observed
    // ═══════════════════════════════════════════════════════════════

    public class ReassignResult
    {
        public long   AssetId       { get; set; }
        public string AssetName     { get; set; }
        public string OldLocation   { get; set; }
        public string NewLocation   { get; set; }
        public bool   Success       { get; set; }
        public string Error         { get; set; }
    }

    /// <summary>
    /// Reassign a single asset's location to its lastobservedlocation.
    /// Updates locationid, logs to locationhistory, sets audit trail.
    /// </summary>
    public static ReassignResult ReassignAsset(long assetId)
    {
        var result = new ReassignResult { AssetId = assetId };

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var tx = cn.BeginTransaction())
            {
                try
                {
                    // Get asset info
                    string assetName = "", obsLoc = "", oldLoc = "";
                    int companyId = 0, oldLocId = 0;

                    using (var cmd = new SqlCommand(@"
                        SELECT a.name, a.lastobservedlocation, a.companyid, a.locationid,
                               ISNULL(l.name, '') AS assignedLoc
                        FROM dbo.asset a
                        LEFT JOIN dbo.location l ON a.locationid = l.id
                        WHERE a.id = @id", cn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", assetId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            if (!rdr.Read())
                            {
                                result.Error = "Asset not found";
                                return result;
                            }
                            assetName = rdr["name"].ToString();
                            obsLoc = rdr["lastobservedlocation"].ToString();
                            oldLoc = rdr["assignedLoc"].ToString();
                            companyId = rdr["companyid"] != DBNull.Value ? Convert.ToInt32(rdr["companyid"]) : 0;
                            oldLocId = rdr["locationid"] != DBNull.Value ? Convert.ToInt32(rdr["locationid"]) : 0;
                        }
                    }

                    result.AssetName = assetName;
                    result.OldLocation = oldLoc;
                    result.NewLocation = obsLoc;

                    if (string.IsNullOrEmpty(obsLoc))
                    {
                        result.Error = "No observed location";
                        return result;
                    }

                    // Resolve the new locationid from the observed location name
                    int newLocId = 0;
                    using (var cmd = new SqlCommand(@"
                        SELECT TOP 1 id FROM dbo.location 
                        WHERE name = @name AND companyid = @cid
                        ORDER BY id", cn, tx))
                    {
                        cmd.Parameters.AddWithValue("@name", obsLoc);
                        cmd.Parameters.AddWithValue("@cid", companyId);
                        var obj = cmd.ExecuteScalar();
                        if (obj != null && obj != DBNull.Value)
                            newLocId = Convert.ToInt32(obj);
                    }

                    // If location doesn't exist for this company, create it
                    if (newLocId == 0)
                    {
                        using (var cmd = new SqlCommand(@"
                            INSERT INTO dbo.location (name, companyid)
                            VALUES (@name, @cid);
                            SELECT SCOPE_IDENTITY();", cn, tx))
                        {
                            cmd.Parameters.AddWithValue("@name", obsLoc);
                            cmd.Parameters.AddWithValue("@cid", companyId);
                            newLocId = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                    }

                    // Close out old locationhistory entry
                    if (oldLocId > 0)
                    {
                        using (var cmd = new SqlCommand(@"
                            UPDATE dbo.locationhistory
                            SET timeleft = SYSDATETIMEOFFSET()
                            WHERE assetid = @assetId AND locationid = @locId AND timeleft IS NULL", cn, tx))
                        {
                            cmd.Parameters.AddWithValue("@assetId", assetId);
                            cmd.Parameters.AddWithValue("@locId", oldLocId);
                            cmd.ExecuteNonQuery();
                        }
                    }

                    // Create new locationhistory entry
                    using (var cmd = new SqlCommand(@"
                        INSERT INTO dbo.locationhistory (timeseen, assetid, locationid, companyid)
                        VALUES (SYSDATETIMEOFFSET(), @assetId, @locId, @cid)", cn, tx))
                    {
                        cmd.Parameters.AddWithValue("@assetId", assetId);
                        cmd.Parameters.AddWithValue("@locId", newLocId);
                        cmd.Parameters.AddWithValue("@cid", companyId);
                        cmd.ExecuteNonQuery();
                    }

                    // Update the asset's assigned location
                    using (var cmd = new SqlCommand(@"
                        UPDATE dbo.asset SET
                            locationid = @locId,
                            lastmodified = GETDATE(),
                            lastmodifiedby = 'ReaderIntelligence'
                        WHERE id = @id", cn, tx))
                    {
                        cmd.Parameters.AddWithValue("@locId", newLocId);
                        cmd.Parameters.AddWithValue("@id", assetId);
                        cmd.ExecuteNonQuery();
                    }

                    tx.Commit();
                    result.Success = true;
                }
                catch (Exception ex)
                {
                    tx.Rollback();
                    result.Error = ex.Message;
                }
            }
        }

        return result;
    }

    /// <summary>
    /// Batch reassign all dwell candidates. Returns list of results.
    /// </summary>
    public static List<ReassignResult> ReassignAllCandidates(int companyId = 0, int readerSiteId = 0)
    {
        var candidates = GetDwellCandidates(companyId, readerSiteId);
        var results = new List<ReassignResult>();

        foreach (var c in candidates)
        {
            results.Add(ReassignAsset(c.AssetId));
        }

        // Update config with last run info
        var config = LoadConfig();
        config.lastDwellCheckUtc = DateTime.UtcNow.ToString("o");
        config.lastReassignmentCount = results.FindAll(r => r.Success).Count;
        SaveConfig(config);

        return results;
    }

    // ═══════════════════════════════════════════════════════════════
    //  SUMMARY STATS — For dashboard KPI cards
    // ═══════════════════════════════════════════════════════════════

    public class IntelStats
    {
        public int MismatchCount      { get; set; }
        public int DwellCandidates    { get; set; }
        public int ReassignedToday    { get; set; }
        public int DepartedToday      { get; set; }
        public int DwellThresholdHours { get; set; }
    }

    public static IntelStats GetStats(int companyId = 0, int readerSiteId = 0)
    {
        var config = LoadConfig();
        var stats = new IntelStats { DwellThresholdHours = config.dwellTimeHours };

        string companyFilter = companyId > 0 ? " AND a.companyid = " + companyId : "";
        string readerFilter = readerSiteId > 0
            ? " AND a.lastobservedlocation IN (SELECT name FROM dbo.location WHERE companyid = " + readerSiteId + ")"
            : "";

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();

            // Mismatch count + dwell candidates
            string sql = @"
                SELECT 
                    COUNT(*) AS MismatchCount,
                    SUM(CASE WHEN DATEDIFF(HOUR, a.lastobservedtime, GETDATE()) >= @threshold THEN 1 ELSE 0 END) AS DwellCandidates
                FROM dbo.asset a
                LEFT JOIN dbo.location l ON a.locationid = l.id
                WHERE a.lastobservedlocation IS NOT NULL
                  AND a.lastobservedlocation <> ''
                  AND a.lastobservedtime IS NOT NULL
                  AND a.lastobservedtime >= DATEADD(DAY, -@recentDays, GETDATE())
                  AND (l.name IS NULL OR l.name <> a.lastobservedlocation)"
                + companyFilter + readerFilter;

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.CommandTimeout = 60;
                cmd.Parameters.AddWithValue("@threshold", config.dwellTimeHours);
                cmd.Parameters.AddWithValue("@recentDays", config.recentWindowDays > 0 ? config.recentWindowDays : 7);
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        stats.MismatchCount = rdr["MismatchCount"] != DBNull.Value ? Convert.ToInt32(rdr["MismatchCount"]) : 0;
                        stats.DwellCandidates = rdr["DwellCandidates"] != DBNull.Value ? Convert.ToInt32(rdr["DwellCandidates"]) : 0;
                    }
                }
            }

            // Reassigned today (by ReaderIntelligence)
            using (var cmd = new SqlCommand(@"
                SELECT COUNT(*) FROM dbo.asset
                WHERE lastmodifiedby = 'ReaderIntelligence'
                  AND lastmodified >= CAST(GETDATE() AS DATE)" + companyFilter.Replace("a.", ""), cn))
            {
                cmd.CommandTimeout = 30;
                stats.ReassignedToday = (int)cmd.ExecuteScalar();
            }

            // Departed today (locationhistory entries with timeleft today)
            using (var cmd = new SqlCommand(@"
                SELECT COUNT(*) FROM dbo.locationhistory
                WHERE timeleft >= CAST(GETDATE() AS DATE)" +
                (companyId > 0 ? " AND companyid = " + companyId : ""), cn))
            {
                cmd.CommandTimeout = 30;
                stats.DepartedToday = (int)cmd.ExecuteScalar();
            }
        }

        return stats;
    }

    // ═══════════════════════════════════════════════════════════════
    //  HELPERS
    // ═══════════════════════════════════════════════════════════════

    private static string PrettyJson(string json)
    {
        // Simple indentation for readability
        var sb = new System.Text.StringBuilder();
        int indent = 0;
        bool inString = false;
        foreach (char c in json)
        {
            if (c == '"' && (sb.Length == 0 || sb[sb.Length - 1] != '\\'))
                inString = !inString;

            if (!inString)
            {
                if (c == '{' || c == '[')
                {
                    sb.Append(c);
                    sb.AppendLine();
                    indent++;
                    sb.Append(new string(' ', indent * 2));
                }
                else if (c == '}' || c == ']')
                {
                    sb.AppendLine();
                    indent--;
                    sb.Append(new string(' ', indent * 2));
                    sb.Append(c);
                }
                else if (c == ',')
                {
                    sb.Append(c);
                    sb.AppendLine();
                    sb.Append(new string(' ', indent * 2));
                }
                else if (c == ':')
                {
                    sb.Append(": ");
                }
                else if (c != ' ' && c != '\r' && c != '\n')
                {
                    sb.Append(c);
                }
            }
            else
            {
                sb.Append(c);
            }
        }
        return sb.ToString();
    }
}
