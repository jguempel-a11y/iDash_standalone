using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Collections.Generic;
using System.Net.Mail;
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.Script.Serialization;
using System.Linq;

public partial class va_ennx_live_scan : System.Web.UI.Page
{
    private static string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return cs == null ? "" : cs.ConnectionString;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn)
        {
            Response.Redirect("index.aspx?returnUrl=" + Server.UrlEncode(Request.RawUrl));
            return;
        }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "scan_ennx"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            string sessionUser = Convert.ToString(Session["IdashDisplayName"] ?? Session["IdashUsername"]);
            if (string.IsNullOrWhiteSpace(sessionUser) && Context != null && Context.User != null && Context.User.Identity != null)
            {
                sessionUser = Context.User.Identity.Name ?? "";
            }
            HidUser.Value = sessionUser;

            LoadCompanies();
            LoadEIL();
        }
    }

    private void LoadCompanies()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr)) return;

            var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                SqlCommand cmd;

                if (allowedIds == null)
                {
                    // Admin / wildcard - show all
                    cmd = new SqlCommand(
                        "SELECT id, name, LEFT(LTRIM(name), 3) AS station_code FROM dbo.company ORDER BY name", conn);
                }
                else if (allowedIds.Count == 0)
                {
                    ShowMsg("No sites are assigned to your account. Contact an administrator.", isError: true);
                    return;
                }
                else
                {
                    var parms = new List<string>();
                    cmd = new SqlCommand();
                    cmd.Connection = conn;
                    for (int i = 0; i < allowedIds.Count; i++)
                    {
                        parms.Add("@id" + i);
                        cmd.Parameters.AddWithValue("@id" + i, allowedIds[i]);
                    }
                    cmd.CommandText = "SELECT id, name, LEFT(LTRIM(name), 3) AS station_code FROM dbo.company WHERE id IN (" + string.Join(",", parms) + ") ORDER BY name";
                }

                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField = "name";
                    DdlCompany.DataValueField = "station_code";
                    DdlCompany.DataBind();
                }

                // Auto-select if exactly one site or single assigned site
                if (DdlCompany.Items.Count >= 1)
                {
                    if (allowedIds != null && allowedIds.Count == 1)
                    {
                        DdlCompany.SelectedIndex = 0;
                    }
                    else if (DdlCompany.Items.Count == 1)
                    {
                        DdlCompany.SelectedIndex = 0;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading companies: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    private void LoadEIL()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr)) return;

            string stationCode = DdlCompany.SelectedValue ?? "";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = @"
                    SELECT DISTINCT a.text8
                    FROM dbo.asset a WITH (NOLOCK)
                    INNER JOIN dbo.company c ON a.companyid = c.id
                    WHERE a.text8 IS NOT NULL AND a.text8 <> ''
                      AND LEFT(LTRIM(c.name), 3) = @station
                    ORDER BY a.text8";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@station", stationCode);
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        DdlEIL.DataSource = rdr;
                        DdlEIL.DataTextField = "text8";
                        DdlEIL.DataValueField = "text8";
                        DdlEIL.DataBind();
                    }
                }
                DdlEIL.Items.Insert(0, new System.Web.UI.WebControls.ListItem("All", "All"));
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading EIL list: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    // -------------------------------------------------------------
    // COMMIT SCANS TO DATABASE
    // Updates dbo.asset text6, lastinventoried, lastmodifiedby & audits to dbo.EnnxLiveSession
    // -------------------------------------------------------------
    protected void BtnCommitScans_Click(object sender, EventArgs e)
    {
        string json = (HidJson.Value ?? "").Trim();
        string ennx = (HidEnnx.Value ?? "").Trim();
        string station = (HidStation.Value ?? "").Trim();
        string summary = (HidSummary.Value ?? "").Trim();
        string startedUtc = (HidStartedUtc.Value ?? "").Trim();
        string endedUtc = (HidEndedUtc.Value ?? "").Trim();
        string user = (HidUser.Value ?? "").Trim();
        if (string.IsNullOrWhiteSpace(user)) user = Convert.ToString(Session["IdashUsername"] ?? "Operator");

        if (string.IsNullOrWhiteSpace(json) || string.IsNullOrWhiteSpace(ennx))
        {
            ShowMsg("Missing scan data. Scan a location and at least one asset first.", isError: true);
            return;
        }

        try
        {
            var js = new JavaScriptSerializer();
            var payload = js.Deserialize<Dictionary<string, object>>(json);
            if (payload == null || !payload.ContainsKey("locations"))
            {
                ShowMsg("Invalid session payload structure.", isError: true);
                return;
            }

            var locList = payload["locations"] as System.Collections.ArrayList;
            if (locList == null || locList.Count == 0)
            {
                ShowMsg("No locations or assets found to commit.", isError: true);
                return;
            }

            int totalUpdatedAssets = 0;
            int totalLocationsCount = 0;

            // Resolve company id for the selected station
            int companyId = 0;
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmdC = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE LEFT(LTRIM(name), 3) = @station", cn))
                {
                    cmdC.Parameters.AddWithValue("@station", station);
                    var o = cmdC.ExecuteScalar();
                    if (o != null && o != DBNull.Value) companyId = Convert.ToInt32(o);
                }

                // If user only allowed 1 site, override/verify
                var allowed = UserManager.GetAllowedCompanyIds(Session, ConnStr);
                if (allowed != null && allowed.Count == 1)
                {
                    companyId = allowed[0];
                }

                // Iterate each location block
                foreach (Dictionary<string, object> block in locList)
                {
                    string locName = block.ContainsKey("location") ? Convert.ToString(block["location"]).Trim().ToUpper() : "";
                    if (string.IsNullOrWhiteSpace(locName)) continue;

                    totalLocationsCount++;

                    // Resolve location ID if exists in dbo.location
                    int locId = 0;
                    string locSql = "SELECT TOP 1 id FROM dbo.location WHERE UPPER(LTRIM(RTRIM(name))) = @loc";
                    if (companyId > 0) locSql += " AND companyid = @cid";

                    using (var cmdLoc = new SqlCommand(locSql, cn))
                    {
                        cmdLoc.Parameters.AddWithValue("@loc", locName);
                        if (companyId > 0) cmdLoc.Parameters.AddWithValue("@cid", companyId);
                        var resLoc = cmdLoc.ExecuteScalar();
                        if (resLoc != null && resLoc != DBNull.Value) locId = Convert.ToInt32(resLoc);
                    }

                    var assets = block.ContainsKey("assets") ? block["assets"] as System.Collections.ArrayList : null;
                    if (assets == null || assets.Count == 0) continue;

                    foreach (var assetObj in assets)
                    {
                        string tag = Convert.ToString(assetObj).Trim();
                        if (string.IsNullOrWhiteSpace(tag)) continue;

                        // Normalize tag variations
                        string cleanNoSpace = tag.Replace(" ", "");

                        string updateSql = @"
                            UPDATE dbo.asset
                            SET text6 = @locName,
                                text16 = @locName,
                                lastinventoried = SYSDATETIMEOFFSET(),
                                lastmodifiedby = @user,
                                lastmodified = SYSDATETIMEOFFSET()";

                        if (locId > 0)
                        {
                            updateSql += ", locationid = @locId";
                        }

                        updateSql += @"
                            WHERE (name = @tag 
                                   OR rfidtag = @tag 
                                   OR name = @cleanNoSpace 
                                   OR rfidtag = @cleanNoSpace 
                                   OR text3 = @tag 
                                   OR text8 = @tag)";

                        if (companyId > 0)
                        {
                            updateSql += " AND companyid = @cid";
                        }

                        using (var cmdUp = new SqlCommand(updateSql, cn))
                        {
                            cmdUp.Parameters.AddWithValue("@locName", locName);
                            cmdUp.Parameters.AddWithValue("@user", user);
                            cmdUp.Parameters.AddWithValue("@tag", tag);
                            cmdUp.Parameters.AddWithValue("@cleanNoSpace", cleanNoSpace);
                            if (locId > 0) cmdUp.Parameters.AddWithValue("@locId", locId);
                            if (companyId > 0) cmdUp.Parameters.AddWithValue("@cid", companyId);

                            int rows = cmdUp.ExecuteNonQuery();
                            if (rows > 0) totalUpdatedAssets += rows;
                        }
                    }
                }
            }

            // Insert audit record into dbo.EnnxLiveSession
            int auditSessionId = 0;
            try
            {
                auditSessionId = TryInsertSessionToSql(station, user, startedUtc, endedUtc, summary, json, ennx);
            }
            catch { }

            string auditNote = auditSessionId > 0 ? string.Format(" (Audit Session #{0})", auditSessionId) : "";
            ShowMsg(string.Format("&#10004; Commit Successful: Updated {0} asset(s) across {1} location(s) in the database{2}.", 
                totalUpdatedAssets, totalLocationsCount, auditNote), isError: false);
        }
        catch (Exception ex)
        {
            ShowMsg("Commit scans failed: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    // -------------------------------------------------------------
    // EMAIL ENNX FILE
    // -------------------------------------------------------------
    protected void BtnEmail_Click(object sender, EventArgs e)
    {
        string ennx = (HidEnnx.Value ?? "").Trim();
        string station = (HidStation.Value ?? "").Trim();
        string summary = (HidSummary.Value ?? "").Trim();

        if (string.IsNullOrWhiteSpace(ennx))
        {
            ShowMsg("No ENNX data to email.", isError: true);
            return;
        }

        try
        {
            string safeStation = string.IsNullOrWhiteSpace(station) ? "site" : station;
            string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string fname = string.Format("ennx_live_{0}_{1}.txt", safeStation, stamp);

            byte[] bytes = Encoding.UTF8.GetBytes(ennx);
            using (var stream = new MemoryStream(bytes))
            {
                var attachment = new Attachment(stream, fname, "text/plain");
                var attachments = new List<Attachment>();
                attachments.Add(attachment);

                string subject = string.Format("ENNX Live Scan - {0} - {1}", safeStation, DateTime.Now.ToShortDateString());
                string body = string.Format(@"
                    <h3>ENNX Live Scan Export</h3>
                    <p><b>Date:</b> {0}</p>
                    <p><b>Summary:</b> {1}</p>
                    <p>See attached file for ENNX data.</p>
                    <hr/>
                    <p><small>Sent from iDash Live Scan.</small></p>
                ", DateTime.Now, summary);

                EmailHelper.SendEmail(subject, body, attachments);
                ShowMsg(string.Format("&#9993; Email sent successfully with attachment {0}.", fname), isError: false);
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Email send failed: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    // -------------------------------------------------------------
    // SQL AUDIT SESSION INSERT
    // -------------------------------------------------------------
    private int TryInsertSessionToSql(string station, string createdBy, string startedUtc, string endedUtc,
                                      string summary, string jsonPayload, string ennxText)
    {
        if (string.IsNullOrWhiteSpace(ConnStr)) return 0;

        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();

            if (!SqlTableExists(con, "EnnxLiveSession"))
                return 0;

            using (var cmd = new SqlCommand(@"
                INSERT INTO dbo.EnnxLiveSession
                (
                    Station,
                    CreatedBy,
                    StartedUtc,
                    EndedUtc,
                    Summary,
                    JsonPayload,
                    EnnxText,
                    CreatedLocal
                )
                OUTPUT INSERTED.SessionId
                VALUES
                (
                    @Station,
                    @CreatedBy,
                    @StartedUtc,
                    @EndedUtc,
                    @Summary,
                    @JsonPayload,
                    @EnnxText,
                    GETDATE()
                );", con))
            {
                cmd.Parameters.AddWithValue("@Station", (object)station ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@CreatedBy", (object)createdBy ?? DBNull.Value);

                DateTime dtStart, dtEnd;
                object oStart = DateTime.TryParse(startedUtc, out dtStart) ? (object)dtStart : (object)startedUtc;
                object oEnd = DateTime.TryParse(endedUtc, out dtEnd) ? (object)dtEnd : (object)endedUtc;

                cmd.Parameters.AddWithValue("@StartedUtc", oStart ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@EndedUtc", oEnd ?? DBNull.Value);

                cmd.Parameters.AddWithValue("@Summary", (object)summary ?? "");
                cmd.Parameters.AddWithValue("@JsonPayload", (object)jsonPayload ?? "");
                cmd.Parameters.AddWithValue("@EnnxText", (object)ennxText ?? "");

                object id = cmd.ExecuteScalar();
                int sessionId;
                if (id != null && int.TryParse(id.ToString(), out sessionId))
                    return sessionId;
            }
        }

        return 0;
    }

    private bool SqlTableExists(SqlConnection con, string tableName)
    {
        using (var cmd = new SqlCommand(@"
            SELECT CASE WHEN EXISTS(
                SELECT 1
                FROM sys.tables t
                WHERE t.name = @Name
            ) THEN 1 ELSE 0 END;", con))
        {
            cmd.Parameters.AddWithValue("@Name", tableName);
            return Convert.ToInt32(cmd.ExecuteScalar()) == 1;
        }
    }

    private void ShowMsg(string msg, bool isError)
    {
        string cls = isError ? "msg-err" : "msg-ok";
        LitMsg.Text = string.Format("<div class='{0}'>{1}</div>", cls, msg);
    }

    // -------------------------------------------------------------
    // WEBMETHODS FOR AUTHENTICATION & LOOKUPS
    // -------------------------------------------------------------
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetSessionState()
    {
        var js = new JavaScriptSerializer();
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
                string sql = "SELECT id, name, LEFT(LTRIM(name), 3) AS station_code FROM dbo.company";
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
                        sites.Add(new { 
                            id = Convert.ToInt32(r["id"]), 
                            name = r["name"].ToString().Trim(),
                            station = r["station_code"].ToString().Trim()
                        });
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
        var js = new JavaScriptSerializer();
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            return js.Serialize(new { success = false, error = "Username and password are required." });

        var session = HttpContext.Current.Session;

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

        return js.Serialize(new { success = false, error = "Invalid credentials." });
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string Logout()
    {
        var js = new JavaScriptSerializer();
        var session = HttpContext.Current.Session;
        if (session != null)
        {
            session.Abandon();
        }
        return js.Serialize(new { success = true });
    }

    [WebMethod]
    public static string CheckAssetEIL(string assetName)
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"];
        string connStr = (cs != null) ? cs.ConnectionString : null;
        if (string.IsNullOrEmpty(connStr)) return "";

        try
        {
            string cleanNoSpace = assetName.Replace(" ", "");
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                    SELECT TOP 1 text8 
                    FROM dbo.asset WITH (NOLOCK) 
                    WHERE name = @name 
                       OR rfidtag = @name 
                       OR name = @nameClean
                       OR rfidtag = @nameClean
                       OR text12 = @name 
                       OR text3 = @name
                    ORDER BY CASE WHEN companyid > 0 THEN 0 ELSE 1 END, id DESC";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@name", assetName);
                    cmd.Parameters.AddWithValue("@nameClean", cleanNoSpace);
                    object res = cmd.ExecuteScalar();
                    return res != null ? res.ToString() : "";
                }
            }
        }
        catch
        {
            return "";
        }
    }

    [WebMethod]
    public static string[] GetEILByStation(string stationCode)
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"];
        string connStr = (cs != null) ? cs.ConnectionString : null;
        if (string.IsNullOrEmpty(connStr)) return new string[0];

        var results = new List<string>();
        try
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                    SELECT DISTINCT a.text8
                    FROM dbo.asset a WITH (NOLOCK)
                    INNER JOIN dbo.company c ON a.companyid = c.id
                    WHERE a.text8 IS NOT NULL AND a.text8 <> ''
                      AND LEFT(LTRIM(c.name), 3) = @station
                    ORDER BY a.text8";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@station", stationCode ?? "");
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                            results.Add(rdr.GetString(0));
                    }
                }
            }
        }
        catch { }
        return results.ToArray();
    }
}
