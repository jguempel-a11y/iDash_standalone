using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using ClosedXML.Excel;

public partial class va_site_maps : System.Web.UI.Page
{
    public string MapsJson = "[]";
    public string CompaniesJson = "[]";
    public string InitialSiteId = "0";

    private string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // ── Auth / Tile Guard (applies to ALL paths including API) ──
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "scan_maps"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        // ── API Router ──
        string api = Request.QueryString["api"];
        if (!string.IsNullOrEmpty(api))
        {
            HandleApi(api);
            return;
        }

        // ── Save Note (POST) ──
        if (Request.HttpMethod == "POST" && !string.IsNullOrEmpty(Request.Form["save_note"]))
        {
            HandleSaveNote();
            return;
        }

        // ── Map Overwrite Upload (existing feature) ──
        if (Request.HttpMethod == "POST" && Request.Files.Count > 0 && !string.IsNullOrEmpty(Request.Form["replace_path"]))
        {
            HandleMapUpload();
            return;
        }

        // ── ENNX File Import ──
        if (Request.HttpMethod == "POST" && Request.Files.Count > 0 && !string.IsNullOrEmpty(Request.Form["ennx_import"]))
        {
            HandleEnnxImport();
            return;
        }

        // ── Normal page load ──
        LoadCompanies();
        LoadMapFiles();
    }


    // ================================================================
    //  COMPANIES
    // ================================================================
    private void LoadCompanies()
    {
        try
        {
            // Respect site-level access — restricted users only see their sites
            var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql;
                SqlCommand cmd;

                if (allowedIds == null)
                {
                    // Admin / wildcard — show all sites
                    sql = "SELECT id, name FROM dbo.company ORDER BY name";
                    cmd = new SqlCommand(sql, conn);
                }
                else if (allowedIds.Count == 0)
                {
                    CompaniesJson = "[]";
                    return;
                }
                else
                {
                    // Site-restricted — build parameterized IN clause
                    var parms = new List<string>();
                    cmd = new SqlCommand();
                    cmd.Connection = conn;
                    for (int i = 0; i < allowedIds.Count; i++)
                    {
                        parms.Add("@id" + i);
                        cmd.Parameters.AddWithValue("@id" + i, allowedIds[i]);
                    }
                    cmd.CommandText = "SELECT id, name FROM dbo.company WHERE id IN (" + string.Join(",", parms) + ") ORDER BY name";
                    sql = null;
                }

                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    var list = new List<object>();
                    while (rdr.Read())
                    {
                        int id = rdr.GetInt32(0);
                        string name = rdr.GetString(1);
                        string station = name.Length >= 3 ? name.Substring(0, 3).Trim() : "";
                        list.Add(new { id = id, name = name, station = station });
                    }
                    var ser = new JavaScriptSerializer();
                    CompaniesJson = ser.Serialize(list);
                }
            }
        }
        catch
        {
            CompaniesJson = "[]";
        }
    }

    // ================================================================
    //  SITE FILTER ENFORCEMENT  (server-side traverse prevention)
    // ================================================================
    /// <summary>
    /// Returns true if the current session user is allowed to access the given companyId.
    /// Writes a JSON error response and returns false if access is denied.
    /// </summary>
    private bool EnforceSiteAccess(string companyId)
    {
        // 0 means "all sites" — only allowed for unrestricted users
        var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);
        if (allowedIds == null) return true; // admin / wildcard — all allowed

        if (string.IsNullOrEmpty(companyId) || companyId == "0")
        {
            // "All sites" requested but user is restricted — deny
            Response.Write("{\"error\":\"Access denied: your account is restricted to specific sites. Select your assigned site from the dropdown.\"}" );
            return false;
        }

        int cid;
        if (!int.TryParse(companyId, out cid) || !allowedIds.Contains(cid))
        {
            Response.Write("{\"error\":\"Access denied: you do not have access to this site.\"}");
            return false;
        }
        return true;
    }


    // ================================================================
    //  MAP FILES (existing logic, enhanced with folder-to-site mapping)
    // ================================================================
    private void LoadMapFiles()
    {
        string mapsPath = Server.MapPath("site_maps");
        if (!Directory.Exists(mapsPath))
        {
            MapsJson = "[]";
            return;
        }

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".pdf", ".bmp" };

        var files = Directory.GetFiles(mapsPath, "*.*", SearchOption.AllDirectories)
            .Where(f => allowedExtensions.Contains(Path.GetExtension(f).ToLower()))
            .Select(f =>
            {
                string name = Path.GetFileName(f);
                string relPath = f.Substring(mapsPath.Length).Replace('\\', '/').TrimStart('/');
                string dir = Path.GetDirectoryName(f);
                string relDir = dir.Length > mapsPath.Length
                                ? dir.Substring(mapsPath.Length).Replace('\\', '/').TrimStart('/')
                                : "Root";

                // Extract building number from filename (e.g., "500-1st Floor Arch.pdf" → "500")
                string building = ExtractBuildingNumber(name);

                return string.Format("{{\"Name\":\"{0}\", \"Path\":\"{1}\", \"Dir\":\"{2}\", \"Ext\":\"{3}\", \"Building\":\"{4}\"}}",
                    HttpUtility.JavaScriptStringEncode(name),
                    HttpUtility.JavaScriptStringEncode(relPath),
                    HttpUtility.JavaScriptStringEncode(relDir),
                    HttpUtility.JavaScriptStringEncode(Path.GetExtension(f).ToLower()),
                    HttpUtility.JavaScriptStringEncode(building)
                );
            }).ToList();

        if (files.Count > 0)
        {
            MapsJson = "[" + string.Join(",", files) + "]";
        }
    }

    /// <summary>
    /// Extracts the building number prefix from a map filename.
    /// Examples: "500-1st Floor Arch.pdf" → "500", "117 Arch Floor Plan.png" → "117"
    /// </summary>
    private string ExtractBuildingNumber(string filename)
    {
        string name = Path.GetFileNameWithoutExtension(filename);
        // Try to extract leading digits (with possible letters like "5B")
        var sb = new StringBuilder();
        foreach (char c in name)
        {
            if (char.IsDigit(c) || (sb.Length > 0 && char.IsLetter(c) && !char.IsWhiteSpace(c)))
            {
                sb.Append(c);
            }
            else if (sb.Length > 0)
            {
                break;
            }
        }
        // Clean up: if result ends with non-digit suffixes like "st", "nd", "rd", "th", strip them
        string result = sb.ToString();
        if (result.Length > 3)
        {
            // Check if it looks like "5001st" — extract just the building number
            // Split at first dash or transition from building to floor
        }
        return result;
    }


    // ================================================================
    //  API ROUTER
    // ================================================================
    private void HandleApi(string action)
    {
        Response.Clear();
        Response.ContentType = "application/json";
        string siteId = Request.QueryString["site"] ?? "0";

        try
        {
            switch (action)
            {
                case "sitestats":
                    if (!EnforceSiteAccess(siteId)) return;
                    Response.Write(GetSiteStatsJson(siteId));
                    break;
                case "locationstats":
                    if (!EnforceSiteAccess(siteId)) return;
                    Response.Write(GetLocationStatsJson(siteId));
                    break;
                case "buildingstats":
                    if (!EnforceSiteAccess(siteId)) return;
                    Response.Write(GetBuildingStatsJson(siteId));
                    break;
                case "assets":
                    if (!EnforceSiteAccess(siteId)) return;
                    string loc = Request.QueryString["location"] ?? "";
                    string filter = Request.QueryString["filter"] ?? "all";
                    Response.Write(GetAssetsJson(siteId, loc, filter));
                    break;
                case "versionhistory":
                    string mapPath = Request.QueryString["map"] ?? "";
                    Response.Write(GetVersionHistoryJson(mapPath));
                    break;
                case "exporttagged":
                    if (!EnforceSiteAccess(siteId)) return;
                    ExportAssetsCsv(siteId, "tagged");
                    return;
                case "exportremaining":
                    if (!EnforceSiteAccess(siteId)) return;
                    ExportAssetsCsv(siteId, "remaining");
                    return;
                case "exportall":
                    if (!EnforceSiteAccess(siteId)) return;
                    ExportAssetsCsv(siteId, "all");
                    return;
                default:
                    Response.Write("{\"error\":\"Unknown API action\"}");
                    break;
            }
        }
        catch (System.Threading.ThreadAbortException) { }
        catch (Exception ex)
        {
            Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
        }
        finally
        {
            try { Response.End(); } catch { }
        }
    }


    // ================================================================
    //  SITE STATS — KPI numbers for a selected company
    // ================================================================
    private string GetSiteStatsJson(string companyId)
    {
        string where = companyId != "0" && !string.IsNullOrEmpty(companyId)
            ? " AND a.companyid = " + int.Parse(companyId)
            : "";

        string sql = @"
            SELECT
                COUNT(*) as Total,
                SUM(CASE WHEN a.text18 = '1' THEN 1 ELSE 0 END) as Tagged,
                SUM(CASE WHEN ISNULL(a.text18,'') <> '1' THEN 1 ELSE 0 END) as Remaining,
                SUM(CASE WHEN a.text18 = '1' AND ISNULL(a.listvalue1,'') LIKE '%IN USE%' THEN 1 ELSE 0 END) as TaggedInUse,
                SUM(CASE WHEN ISNULL(a.text18,'') <> '1' AND ISNULL(a.listvalue1,'') LIKE '%IN USE%' THEN 1 ELSE 0 END) as RemainingInUse,
                COUNT(DISTINCT a.locationname) as UniqueLocations,
                COUNT(DISTINCT a.text19) as UniqueTagTypes,
                COUNT(DISTINCT a.text13) as UniqueEmployees
            FROM dbo.v_asset a
            WHERE 1=1" + where;

        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        return string.Format(
                            "{{\"total\":{0},\"tagged\":{1},\"remaining\":{2},\"taggedInUse\":{3},\"remainingInUse\":{4},\"uniqueLocations\":{5},\"uniqueTagTypes\":{6},\"uniqueEmployees\":{7}}}",
                            rdr["Total"], rdr["Tagged"], rdr["Remaining"],
                            rdr["TaggedInUse"], rdr["RemainingInUse"],
                            rdr["UniqueLocations"], rdr["UniqueTagTypes"], rdr["UniqueEmployees"]
                        );
                    }
                }
            }
        }
        return "{\"total\":0,\"tagged\":0,\"remaining\":0}";
    }


    // ================================================================
    //  LOCATION STATS — Per-location breakdown for map card overlays
    // ================================================================
    private string GetLocationStatsJson(string companyId)
    {
        string where = companyId != "0" && !string.IsNullOrEmpty(companyId)
            ? " AND a.companyid = " + int.Parse(companyId)
            : "";

        string sql = @"
            SELECT
                ISNULL(a.locationname, 'Unknown') as Location,
                SUM(CASE WHEN a.text18 = '1' THEN 1 ELSE 0 END) as Tagged,
                SUM(CASE WHEN ISNULL(a.text18,'') <> '1' THEN 1 ELSE 0 END) as Remaining,
                COUNT(*) as Total
            FROM dbo.v_asset a
            WHERE 1=1" + where + @"
            GROUP BY a.locationname
            ORDER BY a.locationname";

        var results = new List<string>();
        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        results.Add(string.Format(
                            "{{\"location\":\"{0}\",\"tagged\":{1},\"remaining\":{2},\"total\":{3}}}",
                            JsonSafe(rdr["Location"].ToString()),
                            rdr["Tagged"], rdr["Remaining"], rdr["Total"]
                        ));
                    }
                }
            }
        }
        return "[" + string.Join(",", results) + "]";
    }


    // ================================================================
    //  ASSET DETAIL — List of assets for a specific location/building
    // ================================================================
    private string GetAssetsJson(string companyId, string locationFilter, string tagFilter)
    {
        string where = "";
        if (companyId != "0" && !string.IsNullOrEmpty(companyId))
            where += " AND a.companyid = " + int.Parse(companyId);

        if (!string.IsNullOrEmpty(locationFilter) && locationFilter != "all")
            where += " AND a.locationname LIKE @Loc";

        switch (tagFilter)
        {
            case "tagged":
                where += " AND a.text18 = '1'";
                break;
            case "remaining":
                where += " AND (ISNULL(a.text18,'') <> '1')";
                break;
        }

        string sql = @"
            SELECT TOP 500
                a.name as AssetTag,
                ISNULL(a.description,'') as Description,
                ISNULL(a.text1,'') as Manufacturer,
                ISNULL(a.text2,'') as Model,
                ISNULL(a.text3,'') as SerialNumber,
                ISNULL(a.text6,'') as AssignedLocation,
                ISNULL(a.locationname,'Unknown') as LocationName,
                ISNULL(a.text18,'') as Tagged,
                ISNULL(a.text19,'') as TagType,
                ISNULL(a.text16,'') as LocationTagged,
                ISNULL(a.text17,'') as TaggedDate,
                ISNULL(a.text13,'') as EmployeeId,
                ISNULL(a.text8,'') as CMR,
                ISNULL(a.listvalue1,'') as UseStatus,
                ISNULL(a.text20,'') as Notes
            FROM dbo.v_asset a
            WHERE 1=1" + where + @"
            ORDER BY a.text18 DESC, a.locationname, a.name";

        var results = new List<string>();
        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                if (!string.IsNullOrEmpty(locationFilter) && locationFilter != "all")
                    cmd.Parameters.AddWithValue("@Loc", locationFilter + "%");

                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        results.Add(string.Format(
                            "{{\"tag\":\"{0}\",\"desc\":\"{1}\",\"mfg\":\"{2}\",\"model\":\"{3}\",\"serial\":\"{4}\"," +
                            "\"loc\":\"{5}\",\"locName\":\"{6}\",\"tagged\":\"{7}\",\"tagType\":\"{8}\"," +
                            "\"locTagged\":\"{9}\",\"tagDate\":\"{10}\",\"emplId\":\"{11}\",\"cmr\":\"{12}\"," +
                            "\"status\":\"{13}\",\"notes\":\"{14}\"}}",
                            JsonSafe(rdr["AssetTag"].ToString()),
                            JsonSafe(rdr["Description"].ToString()),
                            JsonSafe(rdr["Manufacturer"].ToString()),
                            JsonSafe(rdr["Model"].ToString()),
                            JsonSafe(rdr["SerialNumber"].ToString()),
                            JsonSafe(rdr["AssignedLocation"].ToString()),
                            JsonSafe(rdr["LocationName"].ToString()),
                            JsonSafe(rdr["Tagged"].ToString()),
                            JsonSafe(rdr["TagType"].ToString()),
                            JsonSafe(rdr["LocationTagged"].ToString()),
                            JsonSafe(rdr["TaggedDate"].ToString()),
                            JsonSafe(rdr["EmployeeId"].ToString()),
                            JsonSafe(rdr["CMR"].ToString()),
                            JsonSafe(rdr["UseStatus"].ToString()),
                            JsonSafe(rdr["Notes"].ToString())
                        ));
                    }
                }
            }
        }
        return "[" + string.Join(",", results) + "]";
    }


    // ================================================================
    //  EXCEL / XLSX EXPORT (ClosedXML - MIT License)
    // ================================================================
    private void ExportAssetsCsv(string companyId, string tagFilter)
    {
        string where = "";
        if (companyId != "0" && !string.IsNullOrEmpty(companyId))
            where += " AND a.companyid = " + int.Parse(companyId);

        switch (tagFilter)
        {
            case "tagged":
                where += " AND a.text18 = '1'";
                break;
            case "remaining":
                where += " AND (ISNULL(a.text18,'') <> '1')";
                break;
        }

        string sql = @"
            SELECT
                ISNULL(c.name,'Unknown') as [Site],
                a.name as [Asset Tag],
                ISNULL(a.description,'') as [Description],
                ISNULL(a.text1,'') as [Manufacturer],
                ISNULL(a.text2,'') as [Model],
                ISNULL(a.text3,'') as [Serial #],
                ISNULL(a.text4,'') as [Equipment Category],
                ISNULL(a.text6,'') as [SP + Location],
                ISNULL(a.locationname,'') as [Location Name],
                ISNULL(a.text8,'') as [CMR/EIL],
                ISNULL(a.listvalue1,'') as [Use Status],
                CASE WHEN a.text18='1' THEN 'Yes' ELSE 'No' END as [Tagged],
                ISNULL(a.text19,'') as [Tag Type],
                ISNULL(a.text16,'') as [Location Tagged (Found)],
                ISNULL(a.text17,'') as [Tagged On Date],
                ISNULL(a.text13,'') as [Employee ID],
                ISNULL(a.text20,'') as [Notes]
            FROM dbo.v_asset a
            LEFT JOIN dbo.company c ON a.companyid = c.id
            WHERE 1=1" + where + @"
            ORDER BY a.locationname, a.name";

        using (SqlConnection conn = new SqlConnection(ConnStr))
        using (SqlDataAdapter da = new SqlDataAdapter(sql, conn))
        {
            da.SelectCommand.CommandTimeout = 300;
            DataTable dt = new DataTable();
            da.Fill(dt);

            using (var wb = new XLWorkbook())
            {
                string label = tagFilter == "tagged" ? "Tagged" : (tagFilter == "remaining" ? "Remaining" : "All");
                var ws = wb.Worksheets.Add(label + " Assets");

                // Write header row
                for (int col = 0; col < dt.Columns.Count; col++)
                {
                    ws.Cell(1, col + 1).Value = dt.Columns[col].ColumnName;
                }

                // Style header row
                var headerRange = ws.Range(1, 1, 1, dt.Columns.Count);
                headerRange.Style.Font.Bold = true;
                headerRange.Style.Font.FontColor = XLColor.White;
                headerRange.Style.Fill.BackgroundColor = XLColor.FromArgb(30, 58, 95);
                headerRange.Style.Border.BottomBorder = XLBorderStyleValues.Medium;
                headerRange.Style.Border.BottomBorderColor = XLColor.FromArgb(59, 130, 246);

                // Write data rows
                for (int row = 0; row < dt.Rows.Count; row++)
                {
                    for (int col = 0; col < dt.Columns.Count; col++)
                    {
                        var val = dt.Rows[row][col];
                        ws.Cell(row + 2, col + 1).Value = val != null ? val.ToString() : "";
                    }
                }

                // Auto-fit columns
                if (dt.Rows.Count > 0)
                {
                    ws.Columns(1, dt.Columns.Count).AdjustToContents(8, 50);
                    ws.Range(1, 1, dt.Rows.Count + 1, dt.Columns.Count).SetAutoFilter();
                }

                // Freeze top row
                ws.SheetView.FreezeRows(1);

                string fname = "SiteMap_" + label + "_" + companyId + "_" + DateTime.Now.ToString("yyyyMMdd") + ".xlsx";

                using (var ms = new MemoryStream())
                {
                    wb.SaveAs(ms);
                    byte[] bytes = ms.ToArray();
                    Response.ClearContent();
                    Response.AddHeader("content-disposition", "attachment; filename=" + fname);
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    Response.BinaryWrite(bytes);
                    Response.Flush();
                    Response.Close();
                }
            }
        }
    }


    // ================================================================
    //  ENNX IMPORT — Parse uploaded ENNX text and cross-reference
    // ================================================================
    private void HandleEnnxImport()
    {
        Response.Clear();
        Response.ContentType = "application/json";

        try
        {
            string siteId = Request.Form["site_id"] ?? "0";
            var file = Request.Files[0];

            // Read the ENNX text
            string ennxText;
            using (var sr = new StreamReader(file.InputStream, Encoding.UTF8))
            {
                ennxText = sr.ReadToEnd();
            }

            if (string.IsNullOrWhiteSpace(ennxText))
            {
                Response.Write("{\"error\":\"File is empty\"}");
                Response.End();
                return;
            }

            // Parse ENNX lines — each line is typically an EPC hex tag or asset identifier
            // Format varies but common: lines containing EPC hex values (like "E2806994200040...")
            // or asset names like "613 EE12345"
            var lines = ennxText.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(l => l.Trim())
                .Where(l => !string.IsNullOrEmpty(l) && !l.StartsWith("#") && !l.StartsWith("//"))
                .ToList();

            int totalLines = lines.Count;

            // Try to match against database assets by rfidtag or name
            string where = "";
            if (siteId != "0" && !string.IsNullOrEmpty(siteId))
                where = " AND a.companyid = " + int.Parse(siteId);

            var matchedAssets = new List<string>();
            var unmatchedLines = new List<string>();

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Load all asset rfidtags and names for this site into memory for fast lookup
                string sql = @"
                    SELECT a.name, a.rfidtag, ISNULL(a.text18,'') as Tagged,
                           ISNULL(a.locationname,'') as Location, ISNULL(a.text6,'') as SPLoc
                    FROM dbo.v_asset a
                    WHERE 1=1" + where;

                var assetsByTag = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);
                var assetsByName = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 120;
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            string n = rdr["name"].ToString();
                            string t = rdr["rfidtag"] != DBNull.Value ? rdr["rfidtag"].ToString() : "";
                            string tagged = rdr["Tagged"].ToString();
                            string loc = rdr["Location"].ToString();
                            string spLoc = rdr["SPLoc"].ToString();
                            var info = new[] { n, t, tagged, loc, spLoc };

                            if (!string.IsNullOrEmpty(t) && !assetsByTag.ContainsKey(t))
                                assetsByTag[t] = info;
                            if (!string.IsNullOrEmpty(n) && !assetsByName.ContainsKey(n))
                                assetsByName[n] = info;
                        }
                    }
                }

                // Match each ENNX line
                foreach (string line in lines)
                {
                    string[] match = null;

                    if (assetsByTag.ContainsKey(line))
                        match = assetsByTag[line];
                    else if (assetsByName.ContainsKey(line))
                        match = assetsByName[line];
                    else
                    {
                        // Try partial match (line might contain extra whitespace or prefix)
                        string cleaned = line.Replace(" ", "");
                        foreach (var kvp in assetsByTag)
                        {
                            if (kvp.Key.Replace(" ", "") == cleaned)
                            {
                                match = kvp.Value;
                                break;
                            }
                        }
                    }

                    if (match != null)
                    {
                        matchedAssets.Add(string.Format(
                            "{{\"name\":\"{0}\",\"rfid\":\"{1}\",\"tagged\":\"{2}\",\"loc\":\"{3}\",\"spLoc\":\"{4}\"}}",
                            JsonSafe(match[0]), JsonSafe(match[1]), JsonSafe(match[2]),
                            JsonSafe(match[3]), JsonSafe(match[4])
                        ));
                    }
                    else
                    {
                        unmatchedLines.Add("\"" + JsonSafe(line) + "\"");
                    }
                }
            }

            string result = string.Format(
                "{{\"totalLines\":{0},\"matched\":{1},\"unmatched\":{2},\"matchedAssets\":[{3}],\"unmatchedLines\":[{4}]}}",
                totalLines, matchedAssets.Count, unmatchedLines.Count,
                string.Join(",", matchedAssets),
                string.Join(",", unmatchedLines)
            );
            Response.Write(result);
        }
        catch (Exception ex)
        {
            Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
        }
        finally
        {
            try { Response.End(); } catch { }
        }
    }


    // ================================================================
    //  BUILDING STATS — Per-building tag counts for map card status dots
    // ================================================================
    private string GetBuildingStatsJson(string companyId)
    {
        string where = companyId != "0" && !string.IsNullOrEmpty(companyId)
            ? " AND a.companyid = " + int.Parse(companyId)
            : "";

        // text6 stores location like "SP4C141-500", "SP4A147-500", etc.
        // We extract the building number (last segment after the last dash)
        // Also extract from locationname which has the full location name
        string sql = @"
            SELECT
                CASE
                    WHEN CHARINDEX('-', REVERSE(ISNULL(a.text6,''))) > 0
                    THEN RIGHT(a.text6, CHARINDEX('-', REVERSE(a.text6)) - 1)
                    ELSE ISNULL(a.text6,'')
                END as Building,
                COUNT(*) as Total,
                SUM(CASE WHEN a.text18 = '1' THEN 1 ELSE 0 END) as Tagged,
                SUM(CASE WHEN ISNULL(a.text18,'') <> '1' THEN 1 ELSE 0 END) as Remaining
            FROM dbo.v_asset a
            WHERE ISNULL(a.text6,'') <> ''" + where + @"
            GROUP BY
                CASE
                    WHEN CHARINDEX('-', REVERSE(ISNULL(a.text6,''))) > 0
                    THEN RIGHT(a.text6, CHARINDEX('-', REVERSE(a.text6)) - 1)
                    ELSE ISNULL(a.text6,'')
                END
            ORDER BY Building";

        var results = new List<string>();
        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        results.Add(string.Format(
                            "{{\"building\":\"{0}\",\"total\":{1},\"tagged\":{2},\"remaining\":{3}}}",
                            JsonSafe(rdr["Building"].ToString()),
                            rdr["Total"], rdr["Tagged"], rdr["Remaining"]
                        ));
                    }
                }
            }
        }
        return "[" + string.Join(",", results) + "]";
    }


    // ================================================================
    //  SAVE NOTE — Update text20 (notes) for a specific asset
    // ================================================================
    private void HandleSaveNote()
    {
        Response.Clear();
        Response.ContentType = "application/json";

        try
        {
            string assetName = Request.Form["asset_name"] ?? "";
            string noteText = Request.Form["note_text"] ?? "";
            string siteId = Request.Form["site_id"] ?? "0";

            if (string.IsNullOrEmpty(assetName))
            {
                Response.Write("{\"error\":\"Asset name is required\"}");
                Response.End();
                return;
            }

            string where = "";
            if (siteId != "0" && !string.IsNullOrEmpty(siteId))
                where = " AND companyid = " + int.Parse(siteId);

            string sql = "UPDATE dbo.asset SET text20 = @Note, lastmodified = GETUTCDATE() WHERE name = @Name" + where;

            int rows = 0;
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@Note", noteText);
                    cmd.Parameters.AddWithValue("@Name", assetName);
                    rows = cmd.ExecuteNonQuery();
                }
            }

            Response.Write(string.Format("{{\"success\":true,\"rowsAffected\":{0}}}", rows));
        }
        catch (Exception ex)
        {
            Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
        }
        finally
        {
            try { Response.End(); } catch { }
        }
    }


    // ================================================================
    //  VERSION HISTORY — Track map file versions
    // ================================================================
    private string GetVersionHistoryJson(string mapRelPath)
    {
        if (string.IsNullOrEmpty(mapRelPath))
            return "[]";

        string historyFile = Server.MapPath("site_maps/version_history.json");
        if (!File.Exists(historyFile))
            return "[]";

        try
        {
            string json = File.ReadAllText(historyFile, Encoding.UTF8);
            var ser = new JavaScriptSerializer();
            var allHistory = ser.Deserialize<Dictionary<string, List<Dictionary<string, string>>>>(json);

            if (allHistory != null && allHistory.ContainsKey(mapRelPath))
            {
                return ser.Serialize(allHistory[mapRelPath]);
            }
        }
        catch { }

        return "[]";
    }

    private void SaveVersionHistory(string mapRelPath, string action)
    {
        string historyFile = Server.MapPath("site_maps/version_history.json");
        Dictionary<string, List<Dictionary<string, string>>> allHistory;

        try
        {
            if (File.Exists(historyFile))
            {
                string json = File.ReadAllText(historyFile, Encoding.UTF8);
                var ser = new JavaScriptSerializer();
                allHistory = ser.Deserialize<Dictionary<string, List<Dictionary<string, string>>>>(json);
                if (allHistory == null) allHistory = new Dictionary<string, List<Dictionary<string, string>>>();
            }
            else
            {
                allHistory = new Dictionary<string, List<Dictionary<string, string>>>();
            }

            if (!allHistory.ContainsKey(mapRelPath))
                allHistory[mapRelPath] = new List<Dictionary<string, string>>();

            var entry = new Dictionary<string, string>();
            entry["date"] = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            entry["action"] = action;
            entry["user"] = HttpContext.Current.User.Identity.IsAuthenticated
                ? HttpContext.Current.User.Identity.Name : "system";

            allHistory[mapRelPath].Add(entry);

            // Keep only last 50 entries per map
            if (allHistory[mapRelPath].Count > 50)
                allHistory[mapRelPath] = allHistory[mapRelPath]
                    .Skip(allHistory[mapRelPath].Count - 50).ToList();

            var serializer = new JavaScriptSerializer();
            File.WriteAllText(historyFile, serializer.Serialize(allHistory), Encoding.UTF8);
        }
        catch { /* Version tracking is best-effort */ }
    }


    // ================================================================
    //  MAP UPLOAD — with version control
    // ================================================================
    private void HandleMapUpload()
    {
        try
        {
            string relPath = Request.Form["replace_path"];

            if (relPath.Contains("..") || relPath.Contains(":") || Path.IsPathRooted(relPath))
            {
                Response.StatusCode = 403;
                Response.End();
                return;
            }

            string absPath = Server.MapPath("site_maps/" + relPath);

            // Version control: back up existing file before overwriting
            if (File.Exists(absPath))
            {
                string dir = Path.GetDirectoryName(absPath);
                string nameNoExt = Path.GetFileNameWithoutExtension(absPath);
                string ext = Path.GetExtension(absPath);
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");

                // Count existing versions to get version number
                int versionNum = 1;
                string versionsDir = Path.Combine(dir, ".versions");
                if (!Directory.Exists(versionsDir))
                    Directory.CreateDirectory(versionsDir);

                string[] existingVersions = Directory.GetFiles(versionsDir, nameNoExt + "_v*" + ext);
                versionNum = existingVersions.Length + 1;

                string backupName = string.Format("{0}_v{1}_{2}{3}", nameNoExt, versionNum, timestamp, ext);
                string backupPath = Path.Combine(versionsDir, backupName);
                File.Copy(absPath, backupPath, true);

                // Save version history
                SaveVersionHistory(relPath, "Updated — previous version saved as " + backupName);
            }
            else
            {
                // New file upload — create parent dir if needed
                string dir = Path.GetDirectoryName(absPath);
                if (!Directory.Exists(dir))
                    Directory.CreateDirectory(dir);

                SaveVersionHistory(relPath, "Initial upload");
            }

            Request.Files[0].SaveAs(absPath);

            Response.Clear();
            Response.ContentType = "application/json";
            Response.StatusCode = 200;
            Response.Write("{\"success\":true}");
            try { Response.End(); } catch { }
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            try { Response.End(); } catch { }
        }
    }


    // ================================================================
    //  HELPERS
    // ================================================================
    private string JsonSafe(string val)
    {
        if (val == null) return "";
        return val.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
    }
}
