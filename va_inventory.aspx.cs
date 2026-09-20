using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;

public partial class va_inventory : System.Web.UI.Page
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

        // Enforce Authentication Gate
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn)
        {
            string returnUrl = Request.RawUrl;
            Response.Redirect("index.aspx?returnUrl=" + Server.UrlEncode(returnUrl));
            return;
        }

        // Check tile permission
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "scan_inventory"))
        {
            Response.Redirect("index.aspx?err=access");
            return;
        }
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

    private static bool VerifySysUserPassword(string hashedBase64, string providedPassword)
    {
        if (string.IsNullOrEmpty(hashedBase64) || providedPassword == null) return false;
        try
        {
            byte[] bytes = Convert.FromBase64String(hashedBase64);
            if (bytes.Length < 1 + 4 + 4 + 4 + 16 + 32) return false;
            if (bytes[0] != 0x01) return false; // ASP.NET Identity V3 format

            byte[] salt = new byte[16];
            System.Buffer.BlockCopy(bytes, 13, salt, 0, 16);
            byte[] expectedSubkey = new byte[32];
            System.Buffer.BlockCopy(bytes, 29, expectedSubkey, 0, 32);

            using (var kdf = new System.Security.Cryptography.Rfc2898DeriveBytes(
                providedPassword, salt, 10000, System.Security.Cryptography.HashAlgorithmName.SHA256))
            {
                byte[] actual = kdf.GetBytes(32);
                return actual.SequenceEqual(expectedSubkey);
            }
        }
        catch { return false; }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string Login(string username, string password)
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            return js.Serialize(new { success = false, error = "Username and password are required." });

        var session = HttpContext.Current.Session;

        // 1. Try iDash portal users (App_Data/idash_users.json)
        var user = UserManager.Authenticate(username.Trim(), password);
        if (user != null)
        {
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

        // 2. Fallback: Try scanner users (dbo.sysuser) (dbo.sysuser)
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                string sql = "SELECT u.id, u.username, u.password, u.firstname, u.lastname, u.companyid, c.name AS companyname " +
                             "FROM dbo.sysuser u LEFT JOIN dbo.company c ON u.companyid = c.id " +
                             "WHERE u.username = @u";
                using (var cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.AddWithValue("@u", username.Trim());
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            string dbPwHash = r["password"] != DBNull.Value ? r["password"].ToString() : "";
                            if (VerifySysUserPassword(dbPwHash, password))
                            {
                                string uname = r["username"].ToString().Trim();
                                string fn = r["firstname"] != DBNull.Value ? r["firstname"].ToString().Trim() : "";
                                string ln = r["lastname"] != DBNull.Value ? r["lastname"].ToString().Trim() : "";
                                string dname = (!string.IsNullOrEmpty(fn) || !string.IsNullOrEmpty(ln)) ? (fn + " " + ln).Trim() : uname;
                                string cname = r["companyname"] != DBNull.Value ? r["companyname"].ToString().Trim() : "";

                                session["IsAdminAuthenticated"] = true;
                                session["IdashUserRole"] = "user";
                                session["IdashUsername"] = uname;
                                session["IdashDisplayName"] = dname;
                                session["IdashTileAccess"] = new List<string>() { "scan_inventory" };
                                var siteMap = new Dictionary<string, string>();
                                if (!string.IsNullOrEmpty(cname))
                                    siteMap.Add(cname, "full");
                                else
                                    siteMap.Add("*", "full");
                                session["IdashSiteAccess"] = siteMap;

                                try
                                {
                                    LoginAuditHelper.LogLogin(uname, HttpContext.Current.Request.UserHostAddress, true, "user");
                                }
                                catch { }

                                return GetSessionState();
                            }
                        }
                    }
                }
            }
        }
        catch { }

        return js.Serialize(new { success = false, error = "Invalid username or password, or account is disabled." });
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
    public static string GetOperators()
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        var operators = new List<string>();
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT DISTINCT username FROM v_sysuser WHERE username IS NOT NULL AND username <> '' ORDER BY username", cn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read()) operators.Add(r[0].ToString().Trim());
                }
            }
            return js.Serialize(new { success = true, operators = operators });
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

                string sql;
                if (siteId > 0 && locId.HasValue)
                {
                    sql = @"
                        SELECT a.id, 
                               a.name, 
                               ISNULL(a.rfidtag, '') as rfidtag, 
                               ISNULL(a.text1, '') as text1,
                               ISNULL(a.text2, '') as text2,
                               ISNULL(a.text3, '') as text3,
                               ISNULL(a.text4, '') as text4,
                               ISNULL(a.text5, '') as text5,
                               ISNULL(a.text6, '') as text6,
                               ISNULL(a.text7, '') as text7,
                               ISNULL(a.text8, '') as text8,
                               ISNULL(a.text9, '') as text9,
                               ISNULL(a.text10, '') as text10,
                               ISNULL(a.text11, '') as text11,
                               ISNULL(a.text12, '') as text12,
                               ISNULL(a.text13, '') as text13,
                               ISNULL(a.text14, '') as text14,
                               ISNULL(a.text15, '') as text15,
                               ISNULL(a.text16, '') as text16,
                               ISNULL(a.text17, '') as text17,
                               ISNULL(a.text18, '') as text18,
                               ISNULL(a.text19, '') as text19,
                               ISNULL(a.text20, '') as text20,
                               ISNULL(CONVERT(varchar(20), a.lastinventoried, 120), '') as lastinventoried,
                               ISNULL(a.text3, '') as serialnumber, 
                               ISNULL(a.text8, '') as cmr,
                               ISNULL(a.text19, '') as tagtype,
                               ISNULL(a.text6, @loc) as dblocation,
                               SUBSTRING(ISNULL(a.description, ''), 1, 100) as description
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
                               ISNULL(a.text1, '') as text1,
                               ISNULL(a.text2, '') as text2,
                               ISNULL(a.text3, '') as text3,
                               ISNULL(a.text4, '') as text4,
                               ISNULL(a.text5, '') as text5,
                               ISNULL(a.text6, '') as text6,
                               ISNULL(a.text7, '') as text7,
                               ISNULL(a.text8, '') as text8,
                               ISNULL(a.text9, '') as text9,
                               ISNULL(a.text10, '') as text10,
                               ISNULL(a.text11, '') as text11,
                               ISNULL(a.text12, '') as text12,
                               ISNULL(a.text13, '') as text13,
                               ISNULL(a.text14, '') as text14,
                               ISNULL(a.text15, '') as text15,
                               ISNULL(a.text16, '') as text16,
                               ISNULL(a.text17, '') as text17,
                               ISNULL(a.text18, '') as text18,
                               ISNULL(a.text19, '') as text19,
                               ISNULL(a.text20, '') as text20,
                               ISNULL(CONVERT(varchar(20), a.lastinventoried, 120), '') as lastinventoried,
                               ISNULL(a.text3, '') as serialnumber, 
                               ISNULL(a.text8, '') as cmr,
                               ISNULL(a.text19, '') as tagtype,
                               ISNULL(l.name, ISNULL(a.text6, @loc)) as dblocation,
                               SUBSTRING(ISNULL(a.description, ''), 1, 100) as description
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
                                description = r["description"].ToString().Trim(),
                                text1 = r["text1"].ToString().Trim(),
                                text2 = r["text2"].ToString().Trim(),
                                text3 = r["text3"].ToString().Trim(),
                                text4 = r["text4"].ToString().Trim(),
                                text5 = r["text5"].ToString().Trim(),
                                text6 = r["text6"].ToString().Trim(),
                                text7 = r["text7"].ToString().Trim(),
                                text8 = r["text8"].ToString().Trim(),
                                text9 = r["text9"].ToString().Trim(),
                                text10 = r["text10"].ToString().Trim(),
                                text11 = r["text11"].ToString().Trim(),
                                text12 = r["text12"].ToString().Trim(),
                                text13 = r["text13"].ToString().Trim(),
                                text14 = r["text14"].ToString().Trim(),
                                text15 = r["text15"].ToString().Trim(),
                                text16 = r["text16"].ToString().Trim(),
                                text17 = r["text17"].ToString().Trim(),
                                text18 = r["text18"].ToString().Trim(),
                                text19 = r["text19"].ToString().Trim(),
                                text20 = r["text20"].ToString().Trim(),
                                lastinventoried = r["lastinventoried"].ToString().Trim(),
                                serialnumber = r["text3"].ToString().Trim(),
                                cmr = r["text8"].ToString().Trim(),
                                tagtype = r["text19"].ToString().Trim(),
                                dblocation = r["dblocation"].ToString().Trim()
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

        if (clean.StartsWith("SP") && !clean.Contains("EE"))
        {
            return js.Serialize(new { 
                success = true, 
                isLocation = true, 
                locationName = clean 
            });
        }

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
                string sql = @"
                    SELECT TOP 1 
                        a.id, 
                        a.name, 
                        SUBSTRING(ISNULL(a.description, ''), 1, 50) as description, 
                        ISNULL(a.rfidtag, '') as rfidtag, 
                        ISNULL(a.text1, '') as text1,
                        ISNULL(a.text2, '') as text2,
                        ISNULL(a.text3, '') as text3,
                        ISNULL(a.text4, '') as text4,
                        ISNULL(a.text5, '') as text5,
                        ISNULL(a.text6, '') as text6,
                        ISNULL(a.text7, '') as text7,
                        ISNULL(a.text8, '') as text8,
                        ISNULL(a.text9, '') as text9,
                        ISNULL(a.text10, '') as text10,
                        ISNULL(a.text11, '') as text11,
                        ISNULL(a.text12, '') as text12,
                        ISNULL(a.text13, '') as text13,
                        ISNULL(a.text14, '') as text14,
                        ISNULL(a.text15, '') as text15,
                        ISNULL(a.text16, '') as text16,
                        ISNULL(a.text17, '') as text17,
                        ISNULL(a.text18, '') as text18,
                        ISNULL(a.text19, '') as text19,
                        ISNULL(a.text20, '') as text20,
                        ISNULL(CONVERT(varchar(20), a.lastinventoried, 120), '') as lastinventoried,
                        ISNULL(a.text3, '') as serialnumber, 
                        ISNULL(a.text8, '') as cmr,
                        ISNULL(a.text19, '') as tagtype,
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
                           OR a.text8 = @raw
                           OR a.text3 = @raw)";

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
                                text1 = r["text1"].ToString().Trim(),
                                text2 = r["text2"].ToString().Trim(),
                                text3 = r["text3"].ToString().Trim(),
                                text4 = r["text4"].ToString().Trim(),
                                text5 = r["text5"].ToString().Trim(),
                                text6 = r["text6"].ToString().Trim(),
                                text7 = r["text7"].ToString().Trim(),
                                text8 = r["text8"].ToString().Trim(),
                                text9 = r["text9"].ToString().Trim(),
                                text10 = r["text10"].ToString().Trim(),
                                text11 = r["text11"].ToString().Trim(),
                                text12 = r["text12"].ToString().Trim(),
                                text13 = r["text13"].ToString().Trim(),
                                text14 = r["text14"].ToString().Trim(),
                                text15 = r["text15"].ToString().Trim(),
                                text16 = r["text16"].ToString().Trim(),
                                text17 = r["text17"].ToString().Trim(),
                                text18 = r["text18"].ToString().Trim(),
                                text19 = r["text19"].ToString().Trim(),
                                text20 = r["text20"].ToString().Trim(),
                                lastinventoried = r["lastinventoried"].ToString().Trim(),
                                serialnumber = r["serialnumber"].ToString().Trim(),
                                cmr = r["cmr"].ToString().Trim(),
                                tagtype = r["tagtype"].ToString().Trim(),
                                dbLocation = dbLoc
                            };
                            return js.Serialize(asset);
                        }
                    }
                }
            }

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

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetPrintConfig()
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        try
        {
            var printTemplates = new List<object>();
            var availableClients = new List<string>();

            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                using (var cmd = new SqlCommand("SELECT id, name FROM template ORDER BY name", con))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        printTemplates.Add(new { id = Convert.ToInt64(r[0]), name = r[1].ToString() });
                    }
                }

                using (var cmdClients = new SqlCommand("SELECT username FROM printclient UNION SELECT username FROM mqttclient ORDER BY username", con))
                using (var rClient = cmdClients.ExecuteReader())
                {
                    while (rClient.Read())
                    {
                        availableClients.Add(rClient[0].ToString());
                    }
                }
            }

            return js.Serialize(new { success = true, printTemplates = printTemplates, availableClients = availableClients });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { success = false, error = ex.Message });
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetColumnConfig()
    {
        var js = new System.Web.Script.Serialization.JavaScriptSerializer();
        string path = HttpContext.Current.Server.MapPath("~/App_Data/scan_columns_config.json");
        if (System.IO.File.Exists(path))
        {
            try
            {
                string json = System.IO.File.ReadAllText(path);
                return json;
            }
            catch { }
        }

        return js.Serialize(new {
            va_inventory = new {
                hiddenIndices = new int[] { 6, 8 }
            }
        });
    }
}
