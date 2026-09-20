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

public partial class va_ennx_live_scan_legacy : System.Web.UI.Page
{
    // Change these to your preferred folders
    private string SaveFolderDisk
    {
        get { return @"C:\VA_RFID\ennx_live\saved"; }
    }

    private string DownloadFileNamePrefix
    {
        get { return "ennx_live_"; }
    }


    private string ConnStr
    {
        get
        {
            // Uses web.config connection string "iDash"
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return cs == null ? "" : cs.ConnectionString;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "scan_ennx"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            HidUser.Value = (Context != null && Context.User != null && Context.User.Identity != null)
                ? (Context.User.Identity.Name ?? "")
                : "";

            LoadCompanies();
            LoadEIL();
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

    private void LoadCompanies()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr)) return;

            // Restrict to user's allowed sites
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

                // Auto-select if exactly one site
                if (DdlCompany.Items.Count == 1)
                    DdlCompany.SelectedIndex = 0;
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading companies: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    protected void BtnSaveSession_Click(object sender, EventArgs e)
    {
        string json = (HidJson.Value ?? "").Trim();
        string ennx = (HidEnnx.Value ?? "").Trim();
        string station = (HidStation.Value ?? "").Trim();
        string summary = (HidSummary.Value ?? "").Trim();
        string startedUtc = (HidStartedUtc.Value ?? "").Trim();
        string endedUtc = (HidEndedUtc.Value ?? "").Trim();
        string user = (HidUser.Value ?? "").Trim();

        if (string.IsNullOrWhiteSpace(json) || string.IsNullOrWhiteSpace(ennx))
        {
            ShowMsg("Missing payload. Scan a location and assets first.", isError: true);
            return;
        }

        // Save to SQL if tables exist; otherwise just save to disk as fallback
        try
        {
            int sessionId = TryInsertSessionToSql(station, user, startedUtc, endedUtc, summary, json, ennx);

            if (sessionId > 0)
                ShowMsg(string.Format("Saved session to SQL (SessionId={0}).", sessionId), isError: false);
            else
                ShowMsg("SQL tables not found (or insert skipped). Use 'Save ENNX File (Disk)' to store output.", isError: true);
        }
        catch (Exception ex)
        {
            ShowMsg("Save session failed: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    protected void BtnSaveFile_Click(object sender, EventArgs e)
    {
        string ennx = (HidEnnx.Value ?? "").Trim();
        string station = (HidStation.Value ?? "").Trim();
        if (string.IsNullOrWhiteSpace(ennx))
        {
            ShowMsg("No ENNX to save yet.", isError: true);
            return;
        }

        try
        {
            Directory.CreateDirectory(SaveFolderDisk);

            string safeStation = string.IsNullOrWhiteSpace(station) ? "site" : station;
            string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string path = Path.Combine(SaveFolderDisk, string.Format("{0}{1}_{2}.ennx.txt", DownloadFileNamePrefix, safeStation, stamp));

            File.WriteAllText(path, ennx, Encoding.UTF8);

            ShowMsg("Saved ENNX file to: <span class='mono'>" + HttpUtility.HtmlEncode(path) + "</span>", isError: false);
        }
        catch (Exception ex)
        {
            ShowMsg("Disk save failed: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    protected void BtnDownload_Click(object sender, EventArgs e)
    {
        string ennx = (HidEnnx.Value ?? "").Trim();
        string station = (HidStation.Value ?? "").Trim();

        if (string.IsNullOrWhiteSpace(ennx))
        {
            ShowMsg("No ENNX to download yet.", isError: true);
            return;
        }

        string safeStation = string.IsNullOrWhiteSpace(station) ? "site" : station;
        string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        string fname = string.Format("{0}{1}_{2}.txt", DownloadFileNamePrefix, safeStation, stamp);

        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition", "attachment; filename=" + fname);
        Response.ContentEncoding = Encoding.UTF8;
        Response.Write(ennx);
        Response.End();
    }
    
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

        try {
            string safeStation = string.IsNullOrWhiteSpace(station) ? "site" : station;
            string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string fname = string.Format("{0}{1}_{2}.txt", DownloadFileNamePrefix, safeStation, stamp);
            
            // Create attachment from string
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
                ShowMsg(string.Format("Email sent successfully regarding {0}.", fname), isError: false);
            }
        }
        catch (Exception ex) {
             ShowMsg("Email send failed: " + HttpUtility.HtmlEncode(ex.Message), isError: true);
        }
    }

    // ---------------------------
    // SQL SAVE (Optional)
    // ---------------------------
    private int TryInsertSessionToSql(string station, string createdBy, string startedUtc, string endedUtc,
                                      string summary, string jsonPayload, string ennxText)
    {
        if (string.IsNullOrWhiteSpace(ConnStr))
            throw new Exception("Missing connection string 'iDash' in web.config.");

        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();

            // Check table exists
            if (!SqlTableExists(con, "EnnxLiveSession"))
                return 0;

            // Insert session row
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

                // keep as string if parse fails
                DateTime dtStart, dtEnd;
                object oStart = DateTime.TryParse(startedUtc, out dtStart) ? (object)dtStart : (object)startedUtc;
                object oEnd = DateTime.TryParse(endedUtc, out dtEnd) ? (object)dtEnd : (object)endedUtc;

                cmd.Parameters.AddWithValue("@StartedUtc", oStart);
                cmd.Parameters.AddWithValue("@EndedUtc", oEnd);

                cmd.Parameters.AddWithValue("@Summary", (object)summary ?? "");
                cmd.Parameters.AddWithValue("@JsonPayload", (object)jsonPayload ?? "");
                cmd.Parameters.AddWithValue("@EnnxText", (object)ennxText ?? "");

                object id = cmd.ExecuteScalar();
                int sessionId;
                // Clean int.TryParse for older C# 
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
        // matches your dark theme; keeps it simple
        string cls = isError ? "err" : "ok";
        LitMsg.Text = string.Format("<div class='panel'><div class='{0}' style='font-weight:800'>{1}</div></div>", cls, msg);
    }

    [WebMethod]
    public static string CheckAssetEIL(string assetName)
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"];
        string connStr = (cs != null) ? cs.ConnectionString : null;
        if (string.IsNullOrEmpty(connStr)) return "";

        try
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                    SELECT TOP 1 text8 
                    FROM dbo.asset WITH (NOLOCK) 
                    WHERE name = @name 
                       OR rfidtag = @name 
                       OR text12 = @name 
                       OR text3 = @name
                    ORDER BY CASE WHEN companyid > 0 THEN 0 ELSE 1 END, id DESC";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@name", assetName);
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
