using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;

public partial class va_zebra_browser_test : System.Web.UI.Page
{
    private static string ConnStr
    {
        get
        {
            string cs = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
            return cs;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.Cache.SetNoStore();
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetSessionState()
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        var session = HttpContext.Current.Session;
        bool isLoggedIn = session != null && session["IsAdminAuthenticated"] != null && (bool)session["IsAdminAuthenticated"];
        string username = isLoggedIn ? Convert.ToString(session["IdashUsername"]) : "";
        string displayName = isLoggedIn ? Convert.ToString(session["IdashDisplayName"] ?? username) : "";
        string role = isLoggedIn ? Convert.ToString(session["IdashUserRole"]) : "";

        var sites = new List<object>();
        if (isLoggedIn)
        {
            var allowedIds = UserManager.GetAllowedCompanyIds(session, ConnStr);
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                string sql = "SELECT id, name FROM dbo.company";
                if (allowedIds != null && allowedIds.Count > 0)
                {
                    sql += " WHERE id IN (" + string.Join(",", allowedIds) + ")";
                }
                else if (allowedIds != null && allowedIds.Count == 0)
                {
                    return js.Serialize(new { success = true, isLoggedIn = true, username = username, displayName = displayName, role = role, sites = sites });
                }
                sql += " ORDER BY name";

                using (var cmd = new SqlCommand(sql, cn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        sites.Add(new { id = Convert.ToInt32(r["id"]), name = r["name"].ToString().Trim() });
                    }
                }
            }
        }

        return js.Serialize(new
        {
            success = true,
            isLoggedIn = isLoggedIn,
            username = username,
            displayName = displayName,
            role = role,
            sites = sites
        });
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string Login(string username, string password)
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            return js.Serialize(new { success = false, error = "Username and password are required." });

        var user = UserManager.Authenticate(username.Trim(), password);
        if (user == null)
            return js.Serialize(new { success = false, error = "Invalid username or password, or account is disabled." });

        var session = HttpContext.Current.Session;
        session["IsAdminAuthenticated"] = true;
        session["IdashUserRole"] = user.Role;
        session["IdashUsername"] = user.Username;
        session["IdashDisplayName"] = user.DisplayName;
        session["IdashTileAccess"] = user.TileAccess;
        session["IdashSiteAccess"] = user.SiteAccess;

        try
        {
            LoginAuditHelper.LogLogin(user.Username, HttpContext.Current.Request.UserHostAddress, true, user.Role);
        }
        catch { }

        return GetSessionState();
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string Logout()
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        var session = HttpContext.Current.Session;
        if (session != null)
        {
            session.Abandon();
        }
        return js.Serialize(new { success = true });
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetSites()
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        var sites = new List<object>();

        try
        {
            var session = HttpContext.Current.Session;
            var allowedIds = session != null ? UserManager.GetAllowedCompanyIds(session, ConnStr) : null;

            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                string sql = "SELECT id, name FROM dbo.company";
                if (allowedIds != null && allowedIds.Count > 0)
                {
                    sql += " WHERE id IN (" + string.Join(",", allowedIds) + ")";
                }
                else if (allowedIds != null && allowedIds.Count == 0)
                {
                    return js.Serialize(new { success = true, sites = sites });
                }
                sql += " ORDER BY name";

                using (var cmd = new SqlCommand(sql, cn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        sites.Add(new { id = Convert.ToInt32(r["id"]), name = r["name"].ToString().Trim() });
                    }
                }
            }
            return js.Serialize(new { success = true, sites = sites });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { success = false, error = ex.Message });
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetLocations(int siteId)
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        var locations = new List<string>();

        // Auto-resolve siteId from session if not provided
        var session = HttpContext.Current.Session;
        if (siteId <= 0 && session != null)
        {
            var allowed = UserManager.GetAllowedCompanyIds(session, ConnStr);
            if (allowed != null && allowed.Count == 1) siteId = allowed[0];
        }

        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                string sql = "SELECT DISTINCT name FROM dbo.location WHERE name IS NOT NULL AND name <> ''";
                if (siteId > 0) sql += " AND companyid = @cid";
                sql += " ORDER BY name";

                using (var cmd = new SqlCommand(sql, cn))
                {
                    if (siteId > 0) cmd.Parameters.AddWithValue("@cid", siteId);
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read()) locations.Add(r[0].ToString().Trim());
                    }
                }
            }
            return js.Serialize(new { success = true, locations = locations, siteId = siteId });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { success = false, error = ex.Message });
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string LoadLocationAssets(string locationName, int siteId)
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        js.MaxJsonLength = int.MaxValue;
        if (string.IsNullOrWhiteSpace(locationName))
            return js.Serialize(new { success = false, message = "Location is required." });

        string cleanLoc = locationName.Trim().ToUpper();
        var assets = new List<object>();

        // Auto-resolve siteId from session if not provided
        var session = HttpContext.Current.Session;
        if (siteId <= 0 && session != null)
        {
            var allowed = UserManager.GetAllowedCompanyIds(session, ConnStr);
            if (allowed != null && allowed.Count == 1) siteId = allowed[0];
        }

        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                // 1. Resolve locationId quickly if siteId is known
                int? locId = null;
                if (siteId > 0)
                {
                    using (var cmdLoc = new SqlCommand("SELECT TOP 1 id FROM dbo.location WHERE name = @loc AND companyid = @cid", cn))
                    {
                        cmdLoc.Parameters.AddWithValue("@loc", cleanLoc);
                        cmdLoc.Parameters.AddWithValue("@cid", siteId);
                        var o = cmdLoc.ExecuteScalar();
                        if (o != null && o != DBNull.Value) locId = Convert.ToInt32(o);
                    }
                }

                // 2. High-performance covered query with reduced columns
                string sql;
                if (siteId > 0 && locId.HasValue)
                {
                    sql = @"
                        SELECT a.id, 
                               a.name, 
                               ISNULL(a.rfidtag, '') as rfidtag, 
                               ISNULL(a.text8, '') as serialnumber, 
                               ISNULL(a.text3, '') as eil,
                               SUBSTRING(ISNULL(a.description, ''), 1, 40) as description
                        FROM dbo.asset a
                        WHERE a.companyid = @cid AND (a.locationid = @locId OR a.text6 = @loc)
                        ORDER BY a.name";
                }
                else
                {
                    sql = @"
                        SELECT a.id, 
                               a.name, 
                               ISNULL(a.rfidtag, '') as rfidtag, 
                               ISNULL(a.text8, '') as serialnumber, 
                               ISNULL(a.text3, '') as eil,
                               SUBSTRING(ISNULL(a.description, ''), 1, 40) as description
                        FROM dbo.asset a
                        LEFT JOIN dbo.location l ON a.locationid = l.id
                        WHERE (UPPER(l.name) = @loc OR UPPER(a.text6) = @loc)";

                    if (siteId > 0) sql += " AND a.companyid = @cid";
                    sql += " ORDER BY a.name";
                }

                using (var cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.AddWithValue("@loc", cleanLoc);
                    if (siteId > 0) cmd.Parameters.AddWithValue("@cid", siteId);
                    if (locId.HasValue) cmd.Parameters.AddWithValue("@locId", locId.Value);

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            assets.Add(new
                            {
                                id = Convert.ToInt64(r["id"]),
                                name = r["name"].ToString().Trim(),
                                rfidtag = r["rfidtag"].ToString().Trim(),
                                serialnumber = r["serialnumber"].ToString().Trim(),
                                eil = r["eil"].ToString().Trim(),
                                description = r["description"].ToString().Trim()
                            });
                        }
                    }
                }
            }

            return js.Serialize(new { success = true, location = cleanLoc, total = assets.Count, assets = assets, siteId = siteId });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { success = false, error = ex.Message });
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string ProcessScan(string scanData, string currentLocation, int siteId)
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        if (string.IsNullOrWhiteSpace(scanData))
            return js.Serialize(new { success = false, message = "Empty scan data" });

        string raw = scanData.Trim();
        string clean = raw.ToUpper();

        // 1. Check if user scanned a Location Barcode (starts with SP)
        if (clean.StartsWith("SP") && !clean.Contains("EE"))
        {
            return js.Serialize(new { 
                success = true, 
                isLocation = true, 
                locationName = clean 
            });
        }

        // 2. Normalize EPC / EE Tag (e.g. 517EE11443FF or 517EE11443 -> 517 EE11443)
        string normalizedName = clean;
        var mEpc = System.Text.RegularExpressions.Regex.Match(clean, @"^(\d{3})EE([A-Z0-9]+)$", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (mEpc.Success)
        {
            string epcCore = mEpc.Groups[2].Value;
            if (epcCore.EndsWith("FF") && epcCore.Length > 2)
                epcCore = epcCore.Substring(0, epcCore.Length - 2);
            normalizedName = mEpc.Groups[1].Value + " EE" + epcCore;
        }

        string cleanNoSpace = clean.Replace(" ", "");
        string normNoSpace = normalizedName.Replace(" ", "");

        // Auto-resolve siteId from session if not provided
        var session = HttpContext.Current.Session;
        if (siteId <= 0 && session != null)
        {
            var allowed = UserManager.GetAllowedCompanyIds(session, ConnStr);
            if (allowed != null && allowed.Count == 1) siteId = allowed[0];
        }

        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                // Sargable query using existing indexes on rfidtag, name, and text8
                string sql = @"
                    SELECT TOP 1 
                        a.id, 
                        a.name, 
                        SUBSTRING(ISNULL(a.description, ''), 1, 40) as description, 
                        ISNULL(a.rfidtag, '') as rfidtag, 
                        ISNULL(a.text8, '') as serialnumber, 
                        ISNULL(a.text3, '') as eil,
                        ISNULL(l.name, ISNULL(a.text6, 'Unassigned')) as dbLocation, 
                        ISNULL(c.name, '') as sitename,
                        a.companyid
                    FROM dbo.asset a
                    LEFT JOIN dbo.location l ON a.locationid = l.id
                    LEFT JOIN dbo.company c ON a.companyid = c.id
                    WHERE (a.rfidtag = @raw 
                           OR a.rfidtag = @norm
                           OR a.rfidtag = @cleanNoSpace
                           OR a.name = @raw 
                           OR a.name = @norm
                           OR a.name = @cleanNoSpace 
                           OR a.name = @normNoSpace
                           OR a.text8 = @raw)";

                if (siteId > 0) sql += " AND a.companyid = @cid";

                using (var cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.AddWithValue("@raw", raw);
                    cmd.Parameters.AddWithValue("@norm", normalizedName);
                    cmd.Parameters.AddWithValue("@cleanNoSpace", cleanNoSpace);
                    cmd.Parameters.AddWithValue("@normNoSpace", normNoSpace);
                    if (siteId > 0) cmd.Parameters.AddWithValue("@cid", siteId);

                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            string dbLoc = r["dbLocation"].ToString().Trim();
                            string curLoc = (currentLocation ?? "").Trim();

                            bool isExpected = false;
                            if (!string.IsNullOrEmpty(curLoc) && !string.IsNullOrEmpty(dbLoc))
                            {
                                isExpected = string.Equals(dbLoc, curLoc, StringComparison.OrdinalIgnoreCase);
                            }

                            var asset = new
                            {
                                success = true,
                                isLocation = false,
                                found = true,
                                isExpected = isExpected,
                                id = Convert.ToInt64(r["id"]),
                                name = r["name"].ToString().Trim(),
                                description = r["description"].ToString().Trim(),
                                rfidtag = r["rfidtag"].ToString().Trim(),
                                serialnumber = r["serialnumber"].ToString().Trim(),
                                eil = r["eil"].ToString().Trim(),
                                dbLocation = dbLoc
                            };
                            return js.Serialize(asset);
                        }
                    }
                }
            }

            // Not found in DB
            return js.Serialize(new { 
                success = true, 
                isLocation = false, 
                found = false, 
                rawTag = raw, 
                normalizedTag = normalizedName 
            });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { success = false, error = ex.Message });
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string CommitInventory(string locationName, string scanDataJson, int siteId, string username)
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        if (string.IsNullOrWhiteSpace(locationName))
            return js.Serialize(new { success = false, error = "Location name is required." });

        try
        {
            var scanned = js.Deserialize<List<Dictionary<string, object>>>(scanDataJson);
            if (scanned == null || scanned.Count == 0)
                return js.Serialize(new { success = false, error = "No assets provided to commit." });

            string cleanLoc = locationName.Trim().ToUpper();
            int updatedCount = 0;

            var session = HttpContext.Current.Session;
            string sessionUser = session != null ? Convert.ToString(session["IdashUsername"]) : "";
            string user = !string.IsNullOrWhiteSpace(username) ? username.Trim() : (!string.IsNullOrWhiteSpace(sessionUser) ? sessionUser : "ZebraScanner");

            if (siteId <= 0 && session != null)
            {
                var allowed = UserManager.GetAllowedCompanyIds(session, ConnStr);
                if (allowed != null && allowed.Count == 1) siteId = allowed[0];
            }

            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                // Find location ID for cleanLoc
                int locId = 0;
                string locSql = "SELECT TOP 1 id FROM dbo.location WHERE UPPER(LTRIM(RTRIM(name))) = @loc";
                if (siteId > 0) locSql += " AND companyid = @cid";

                using (var cmdLoc = new SqlCommand(locSql, cn))
                {
                    cmdLoc.Parameters.AddWithValue("@loc", cleanLoc);
                    if (siteId > 0) cmdLoc.Parameters.AddWithValue("@cid", siteId);
                    var res = cmdLoc.ExecuteScalar();
                    if (res != null && res != DBNull.Value) locId = Convert.ToInt32(res);
                }

                foreach (var item in scanned)
                {
                    long assetId = 0;
                    if (item.ContainsKey("id") && item["id"] != null)
                        assetId = Convert.ToInt64(item["id"]);

                    if (assetId <= 0) continue;

                    string sql = @"
                        UPDATE dbo.asset 
                        SET lastinventoried = SYSDATETIMEOFFSET(),
                            lastmodifiedby = @user,
                            lastmodifieddate = SYSDATETIMEOFFSET()";

                    if (locId > 0)
                    {
                        sql += @", locationid = @locId, text6 = @locName";
                    }

                    sql += " WHERE id = @id";

                    using (var cmd = new SqlCommand(sql, cn))
                    {
                        cmd.Parameters.AddWithValue("@id", assetId);
                        cmd.Parameters.AddWithValue("@user", user);
                        if (locId > 0)
                        {
                            cmd.Parameters.AddWithValue("@locId", locId);
                            cmd.Parameters.AddWithValue("@locName", cleanLoc);
                        }
                        cmd.ExecuteNonQuery();
                        updatedCount++;
                    }
                }
            }

            return js.Serialize(new { success = true, committed = updatedCount, location = cleanLoc, siteId = siteId, user = user });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { success = false, error = ex.Message });
        }
    }
}
