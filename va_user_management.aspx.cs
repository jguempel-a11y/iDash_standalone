using System;
using System.IO;
using System.Web;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Text;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;

public partial class va_user_management : System.Web.UI.Page
{
    private const string SESSION_AUTH = "IsAdminAuthenticated";
    private const string SESSION_ROLE = "IdashUserRole";
    private const string SESSION_USER = "IdashUsername";

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
        Response.Cache.SetNoStore();

        bool hasTileAccess = false;
        var tiles = Session["IdashTileAccess"] as List<string>;
        if (tiles != null) hasTileAccess = UserManager.CanAccessTile((string)Session[SESSION_ROLE], tiles, "admin_users");

        bool isAdmin = Session[SESSION_AUTH] != null &&
                       (bool)Session[SESSION_AUTH] &&
                       ( ((string)Session[SESSION_ROLE] == UserManager.ROLE_ADMIN) || hasTileAccess );

        if (!isAdmin)
        {
            PnlAccessDenied.Visible = true;
            PnlMain.Visible         = false;
            return;
        }

        PnlMain.Visible         = true;
        PnlAccessDenied.Visible = false;

        if (!IsPostBack)
        {
            InjectMetadataJson();
            BindGrid();
            BindLoginHistory();
            BindAwGrid();
        }
        else
        {
            InjectMetadataJson();
        }
    }

    // Load site list from DB and inject as JS variable
    private void InjectMetadataJson()
    {
        var ser = new JavaScriptSerializer();
        var sites = LoadSitesFromDb();
        string sitesJson = ser.Serialize(sites);
        string tilesJson = ser.Serialize(UserManager.TILE_GROUPS);
        string templatesJson = LoadTemplatesJson();
        LitSiteJson.Text = string.Format("<script>window.idashSites = {0}; window.idashTileGroups = {1}; window.userTemplates = {2};</script>",
            sitesJson, tilesJson, templatesJson);
    }

    private string LoadTemplatesJson()
    {
        try
        {
            string path = Server.MapPath("~/App_Data/user_templates.json");
            if (File.Exists(path))
                return File.ReadAllText(path, System.Text.Encoding.UTF8);
        }
        catch { }
        return "[]";
    }

    private List<object> LoadSitesFromDb()
    {
        var result = new List<object>();
        try
        {
            var csEntry = ConfigurationManager.ConnectionStrings["iDash"];
            if (csEntry == null) return result;
            string cs = csEntry.ConnectionString;
            if (string.IsNullOrWhiteSpace(cs)) return result;

            using (var conn = new SqlConnection(cs))
            using (var cmd  = new SqlCommand(
                "SELECT id, name FROM dbo.company WHERE name IS NOT NULL ORDER BY name", conn))
            {
                conn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        result.Add(new
                        {
                            id   = rdr["id"].ToString(),
                            name = rdr["name"].ToString()
                        });
                    }
                }
            }
        }
        catch { /* return empty list on DB error */ }
        return result;
    }

    // Grid binding
    private void BindGrid()
    {
        GridUsers.DataSource = UserManager.LoadUsers();
        GridUsers.DataBind();
    }

    // Login audit history
    private void BindLoginHistory()
    {
        try
        {
            var stats = LoginAuditHelper.GetLoginStats();
            LitLoginsToday.Text   = stats.LoginsToday.ToString();
            LitFailuresToday.Text = stats.FailuresToday.ToString();
            LitUniqueUsers.Text   = stats.UniqueUsersThisWeek.ToString();
            LitTotalEntries.Text  = stats.TotalEntries.ToString();

            var entries = LoginAuditHelper.GetRecentLogins(50);
            if (entries.Count == 0)
            {
                LitLoginHistory.Text = "<div style='padding:20px; text-align:center; color:var(--muted);'>No login history recorded yet.</div>";
                return;
            }

            var sb = new StringBuilder();
            sb.Append("<table class='ug'>");
            sb.Append("<tr><th>Time</th><th>Username</th><th>IP Address</th><th>Role</th><th>Result</th></tr>");
            foreach (var entry in entries)
            {
                string badge = entry.Success
                    ? "<span class='badge badge-on'>&#10003; OK</span>"
                    : "<span class='badge badge-off'>&#10007; FAILED</span>";
                string roleLabel = string.IsNullOrEmpty(entry.Role) ? "<span style='color:var(--muted);'>—</span>" : Server.HtmlEncode(entry.Role);
                sb.AppendFormat("<tr><td style='white-space:nowrap;'>{0}</td><td style='font-weight:600;'>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td></tr>",
                    entry.Timestamp.ToString("MM/dd/yyyy hh:mm:ss tt"),
                    Server.HtmlEncode(entry.Username),
                    Server.HtmlEncode(entry.IP),
                    roleLabel,
                    badge);
            }
            sb.Append("</table>");
            LitLoginHistory.Text = sb.ToString();
        }
        catch (Exception ex)
        {
            LitLoginHistory.Text = "<div style='color:#ef4444; padding:12px;'>Error loading login history: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected string GetSiteAccessJson(object dataItem)
    {
        var user = dataItem as UserManager.IdashUser;
        if (user == null || user.SiteAccess == null) return "{}";
        var ser = new JavaScriptSerializer();
        return Server.HtmlEncode(ser.Serialize(user.SiteAccess));
    }

    protected string GetTileAccessJson(object dataItem)
    {
        var user = dataItem as UserManager.IdashUser;
        if (user == null || user.TileAccess == null) return "[]";
        var ser = new JavaScriptSerializer();
        return Server.HtmlEncode(ser.Serialize(user.TileAccess));
    }

    /// <summary>
    /// Builds the onclick attribute for the Edit button in the grid.
    /// Retained for backwards compatibility.
    /// </summary>
    protected string BuildEditOnClick(object dataItem)
    {
        var user = dataItem as UserManager.IdashUser;
        if (user == null) return "return false;";

        var ser = new JavaScriptSerializer();

        Dictionary<string, string> siteDict = user.SiteAccess;
        if (siteDict == null) siteDict = new Dictionary<string, string>();
        string saJson = ser.Serialize(siteDict);

        List<string> tileList = user.TileAccess;
        if (tileList == null) tileList = new List<string>();
        string taJson = ser.Serialize(tileList);

        return string.Format(
            "openEditModal('{0}','{1}','{2}',{3},'{4}','{5}','{6}');",
            EscJs(user.Username),
            EscJs(user.DisplayName),
            EscJs(user.Role),
            user.Enabled ? "true" : "false",
            EscJs(user.Notes),
            EscJs(saJson),
            EscJs(taJson));
    }

    /// <summary>Builds onclick for cloning an iDash user.</summary>
    protected string BuildCloneOnClick(object dataItem)
    {
        var user = dataItem as UserManager.IdashUser;
        if (user == null) return "return false;";
        var ser = new JavaScriptSerializer();
        string saJson = ser.Serialize(user.SiteAccess ?? new Dictionary<string, string>());
        string taJson = ser.Serialize(user.TileAccess ?? new List<string>());
        return string.Format(
            "cloneIdashUser('{0}','{1}','{2}','{3}');",
            EscJs(user.Role),
            EscJs(user.DisplayName),
            EscJs(saJson),
            EscJs(taJson));
    }

    /// <summary>Builds onclick for cloning an AW user.</summary>
    protected string BuildAwCloneOnClick(object dataItem)
    {
        var u = dataItem as AwUser;
        if (u == null) return "return false;";
        return string.Format(
            "cloneAwUser('{0}','{1}','{2}','{3}','{4}');",
            EscJs(u.UserType),
            u.CompanyId.HasValue ? u.CompanyId.Value.ToString() : "",
            EscJs(u.Email), EscJs(u.Phone), EscJs(u.CardId));
    }

    // Parse site access JSON from hidden field
    private Dictionary<string, string> ParseSiteAccess(string json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new Dictionary<string, string>();
        try
        {
            var ser    = new JavaScriptSerializer();
            var result = ser.Deserialize<Dictionary<string, string>>(json);
            return result != null ? result : new Dictionary<string, string>();
        }
        catch
        {
            return new Dictionary<string, string>();
        }
    }

    // Parse tile access JSON from hidden field
    private List<string> ParseTileAccess(string json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new List<string>();
        try
        {
            var ser = new JavaScriptSerializer();
            var result = ser.Deserialize<List<string>>(json);
            return result != null ? result : new List<string>();
        }
        catch
        {
            return new List<string>();
        }
    }

    // Add user
    protected void BtnAddSubmit_Click(object sender, EventArgs e)
    {
        InjectMetadataJson();

        string username    = HfAddUsername.Value.Trim();
        string password    = HfAddPassword.Value;
        string role        = HfAddRole.Value.Trim();
        string displayName = HfAddDisplayName.Value.Trim();
        string notes       = HfAddNotes.Value.Trim();
        var    siteAccess  = ParseSiteAccess(HfAddSiteAccess.Value);
        var    tileAccess  = ParseTileAccess(HfAddTileAccess.Value);

        string err = UserManager.AddUser(username, password, role, displayName, notes, siteAccess, tileAccess);

        if (err != null)
        {
            ShowMsg(err, true);
        }
        else
        {
            string msg = "User <strong>" + Server.HtmlEncode(username) + "</strong> created successfully.";

            // Also create scanner account in dbo.sysuser if flagged
            bool alsoAw = HfAddAlsoCreateAw.Value == "1";
            if (alsoAw && !string.IsNullOrEmpty(password))
            {
                string awErr = CreateAwUserInternal(username, password,
                    HfAddAwUserType.Value.Trim(), HfAddAwCompanyId.Value.Trim(),
                    displayName, "", "", "", "", "");
                if (awErr == null)
                    msg += " <strong>Scanner account</strong> also created.";
                else
                    msg += " <span style='color:var(--danger);'>DB: " + Server.HtmlEncode(awErr) + "</span>";
            }

            ShowMsg(msg, false);
        }

        bool didCreateAw = HfAddAlsoCreateAw.Value == "1";

        HfAddUsername.Value = "";
        HfAddPassword.Value = "";
        HfAddRole.Value     = "";
        HfAddDisplayName.Value = "";
        HfAddNotes.Value    = "";
        HfAddSiteAccess.Value  = "";
        HfAddTileAccess.Value  = "";
        HfAddAlsoCreateAw.Value  = "";
        HfAddAwUserType.Value    = "";
        HfAddAwCompanyId.Value   = "";

        BindGrid();
        if (didCreateAw)
            BindAwGrid();
    }

    // Edit user
    protected void BtnEditSubmit_Click(object sender, EventArgs e)
    {
        InjectMetadataJson();

        string username = HfEditUsername.Value.Trim();
        if (string.IsNullOrWhiteSpace(username))
        {
            BindGrid();
            return;
        }

        string password    = HfEditPassword.Value;
        string role        = HfEditRole.Value.Trim();
        string displayName = HfEditDisplayName.Value.Trim();
        string notes       = HfEditNotes.Value.Trim();
        bool   enabled     = HfEditEnabled.Value == "true" || HfEditEnabled.Value == "True";
        var    siteAccess  = ParseSiteAccess(HfEditSiteAccess.Value);
        var    tileAccess  = ParseTileAccess(HfEditTileAccess.Value);

        string currentUser = Convert.ToString(Session[SESSION_USER]);
        if (username.Equals(currentUser, StringComparison.OrdinalIgnoreCase) && !enabled)
        {
            ShowMsg("You cannot disable your own account while logged in.", true);
            BindGrid();
            return;
        }

        string err = UserManager.UpdateUser(username, password, role, displayName, notes, enabled, siteAccess, tileAccess);

        if (err != null)
            ShowMsg(err, true);
        else
            ShowMsg("User <strong>" + Server.HtmlEncode(username) + "</strong> updated successfully.", false);

        HfEditUsername.Value    = "";
        HfEditPassword.Value    = "";
        HfEditRole.Value        = "";
        HfEditDisplayName.Value = "";
        HfEditNotes.Value       = "";
        HfEditEnabled.Value     = "";
        HfEditSiteAccess.Value  = "";
        HfEditTileAccess.Value  = "";

        BindGrid();
    }

    // Delete via grid row command
    protected void GridUsers_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName != "DeleteUser") return;

        InjectMetadataJson();
        string username = e.CommandArgument != null ? e.CommandArgument.ToString().Trim() : "";
        if (string.IsNullOrWhiteSpace(username))
        {
            BindGrid();
            return;
        }

        string currentUser = Convert.ToString(Session[SESSION_USER]);

        if (username.Equals(currentUser, StringComparison.OrdinalIgnoreCase))
        {
            ShowMsg("You cannot delete your own account.", true);
            BindGrid();
            return;
        }

        string err = UserManager.DeleteUser(username);

        if (err != null)
            ShowMsg(err, true);
        else
            ShowMsg("User <strong>" + Server.HtmlEncode(username) + "</strong> has been deleted.", false);

        BindGrid();
    }

    // Flash message helper
    private void ShowMsg(string msg, bool isError)
    {
        string cls  = isError ? "alert-err" : "alert-ok";
        string icon = isError ? "&#9888;" : "&#10003;";
        LitMsg.Text = string.Format("<div class='alert {0}'>{1} {2}</div>", cls, icon, msg);
    }

    // ====================================================================
    // SCANNER USERS (dbo.sysuser)
    // ====================================================================
    private static string AwConnStr
    {
        get
        {
            var e = ConfigurationManager.ConnectionStrings["iDash"];
            return e != null ? e.ConnectionString : null;
        }
    }

    // Models
    [Serializable]
    public class AwUser
    {
        public int    Id          { get; set; }
        public string Username    { get; set; }
        public string FirstName   { get; set; }
        public string LastName    { get; set; }
        public string Email       { get; set; }
        public string Phone       { get; set; }
        public string CardId      { get; set; }
        public string RfidTag     { get; set; }
        public string UserType    { get; set; }
        public int?   CompanyId   { get; set; }
        public string CompanyName { get; set; }
        public bool   HideAdminPopups      { get; set; }
        public bool   InventoryLimitedUser { get; set; }
        public bool   RestrictEditMobile   { get; set; }
    }

    private static bool _awUserColsChecked = false;
    private static void EnsureAwUserColumns(SqlConnection conn)
    {
        if (_awUserColsChecked) return;
        try
        {
            using (var cmd = new SqlCommand(@"
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'hideadminpopups')
                    ALTER TABLE dbo.sysuser ADD hideadminpopups BIT NOT NULL DEFAULT 0;
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'inventorylimiteduser')
                    ALTER TABLE dbo.sysuser ADD inventorylimiteduser BIT NOT NULL DEFAULT 0;
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'restricteditmobile')
                    ALTER TABLE dbo.sysuser ADD restricteditmobile BIT NOT NULL DEFAULT 0;
            ", conn))
            {
                cmd.ExecuteNonQuery();
            }
            _awUserColsChecked = true;
        }
        catch { /* ignore if permissions don't allow ALTER */ }
    }

    private void BindAwGrid()
    {
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) { LitAwMsg.Text = "<div class='alert alert-err'>&#9888; Database connection string not configured.</div>"; return; }
        
        for (int attempt = 0; attempt < 2; attempt++)
        {
            try
            {
                var users = new List<AwUser>();
                using (var conn = new SqlConnection(cs))
                {
                    conn.Open();
                    EnsureAwUserColumns(conn);
                    using (var cmd = new SqlCommand(@"
                        SELECT u.id, u.username, u.firstname, u.lastname, u.email, u.phone,
                               u.cardid, u.rfidtag, u.usertype, u.companyid,
                               u.hideadminpopups, u.inventorylimiteduser, u.restricteditmobile,
                               c.name AS companyname
                        FROM dbo.sysuser u
                        LEFT JOIN dbo.company c ON c.id = u.companyid
                        ORDER BY u.username", conn))
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                            users.Add(new AwUser
                            {
                                Id          = Convert.ToInt32(rdr["id"]),
                                Username    = rdr["username"].ToString(),
                                FirstName   = rdr["firstname"] == DBNull.Value ? "" : rdr["firstname"].ToString(),
                                LastName    = rdr["lastname"]  == DBNull.Value ? "" : rdr["lastname"].ToString(),
                                Email       = rdr["email"]     == DBNull.Value ? "" : rdr["email"].ToString(),
                                Phone       = rdr["phone"]     == DBNull.Value ? "" : rdr["phone"].ToString(),
                                CardId      = rdr["cardid"]    == DBNull.Value ? "" : rdr["cardid"].ToString(),
                                RfidTag     = rdr["rfidtag"]   == DBNull.Value ? "" : rdr["rfidtag"].ToString(),
                                UserType    = rdr["usertype"]  == DBNull.Value ? "" : rdr["usertype"].ToString(),
                                CompanyId   = rdr["companyid"] == DBNull.Value ? (int?)null : Convert.ToInt32(rdr["companyid"]),
                                CompanyName = rdr["companyname"] == DBNull.Value ? "" : rdr["companyname"].ToString(),
                                HideAdminPopups      = rdr["hideadminpopups"]      != DBNull.Value && Convert.ToBoolean(rdr["hideadminpopups"]),
                                InventoryLimitedUser = rdr["inventorylimiteduser"] != DBNull.Value && Convert.ToBoolean(rdr["inventorylimiteduser"]),
                                RestrictEditMobile   = rdr["restricteditmobile"]   != DBNull.Value && Convert.ToBoolean(rdr["restricteditmobile"])
                            });
                    }
                }
                GridAwUsers.DataSource = users;
                GridAwUsers.DataBind();
                break; // success
            }
            catch (Exception ex)
            {
                if (attempt == 0 && (ex.Message.Contains("Invalid column name") || ex.Message.Contains("restricteditmobile")))
                {
                    _awUserColsChecked = false;
                    try
                    {
                        using (var conn = new SqlConnection(cs))
                        {
                            conn.Open();
                            EnsureAwUserColumns(conn);
                        }
                    }
                    catch { }
                    continue; // retry
                }
                LitAwMsg.Text = "<div class='alert alert-err'>&#9888; Error loading scanner users: " + Server.HtmlEncode(ex.Message) + "</div>";
                break;
            }
        }
    }

    protected string BuildAwEditOnClick(object dataItem)
    {
        var u = dataItem as AwUser;
        if (u == null) return "return false;";
        return string.Format(
            "openAwEditModal({0},'{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}');",
            u.Id, EscJs(u.Username), EscJs(u.FirstName), EscJs(u.LastName),
            EscJs(u.Email), EscJs(u.Phone), EscJs(u.CardId), EscJs(u.RfidTag),
            EscJs(u.UserType),
            u.CompanyId.HasValue ? u.CompanyId.Value.ToString() : "");
    }

    private string EscJs(string s)
    {
        if (s == null) return "";
        return s.Replace("\\", "\\\\").Replace("'", "\\'").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
    }

    /// <summary>Injects a JS snippet to switch to the AW tab after postback.</summary>
    private void SwitchToAwTab()
    {
        ClientScript.RegisterStartupScript(GetType(), "switchAw",
            "<script>document.addEventListener('DOMContentLoaded',function(){if(typeof switchSystem==='function')switchSystem('aw');});</script>");
    }

    // ASP.NET Core Identity V3 password hasher
    private static string HashPasswordV3(string password)
    {
        const int SaltSize = 16, SubkeySize = 32, Iterations = 10000;
        byte[] salt = new byte[SaltSize];
        using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create()) rng.GetBytes(salt);
        byte[] subkey;
        using (var kdf = new System.Security.Cryptography.Rfc2898DeriveBytes(password, salt, Iterations, System.Security.Cryptography.HashAlgorithmName.SHA256))
            subkey = kdf.GetBytes(SubkeySize);
        byte[] output = new byte[1 + 4 + 4 + 4 + SaltSize + SubkeySize];
        output[0] = 0x01;
        WriteNBO(output, 1, 1); WriteNBO(output, 5, Iterations); WriteNBO(output, 9, SaltSize);
        System.Buffer.BlockCopy(salt, 0, output, 13, SaltSize);
        System.Buffer.BlockCopy(subkey, 0, output, 13 + SaltSize, SubkeySize);
        return Convert.ToBase64String(output);
    }
    private static void WriteNBO(byte[] buf, int offset, int value)
    {
        unchecked {
            buf[offset]   = (byte)(((uint)value >> 24) & 0xFF);
            buf[offset+1] = (byte)(((uint)value >> 16) & 0xFF);
            buf[offset+2] = (byte)(((uint)value >> 8)  & 0xFF);
            buf[offset+3] = (byte)(((uint)value)       & 0xFF);
        }
    }

    /// <summary>
    /// Creates a scanner user in dbo.sysuser. Returns null on success, error string on failure.
    /// Shared by both the AW add handler and the iDash cross-platform checkbox.
    /// </summary>
    private string CreateAwUserInternal(string username, string password,
        string usertype, string companyid,
        string firstname, string lastname, string email, string phone,
        string cardid, string rfidtag)
    {
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) return "Database not configured.";

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                EnsureAwUserColumns(conn);
                using (var chk = new SqlCommand("SELECT COUNT(*) FROM dbo.sysuser WHERE username = @u", conn))
                {
                    chk.Parameters.AddWithValue("@u", username);
                    if ((int)chk.ExecuteScalar() > 0)
                        return "Username '" + username + "' already exists in the database.";
                }

                if (string.IsNullOrEmpty(companyid))
                {
                    using (var cCmd = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE name IS NOT NULL ORDER BY id", conn))
                    { object r = cCmd.ExecuteScalar(); if (r != null) companyid = r.ToString(); }
                }

                string hashedPw = string.IsNullOrEmpty(password) ? null : HashPasswordV3(password);
                using (var cmd = new SqlCommand(@"INSERT INTO dbo.sysuser
                    (username,password,firstname,lastname,email,phone,cardid,rfidtag,usertype,companyid,hideadminpopups,inventorylimiteduser,restricteditmobile)
                    VALUES(@username,@password,@firstname,@lastname,@email,@phone,@cardid,@rfidtag,@usertype,@companyid,0,0,0)", conn))
                {
                    cmd.Parameters.AddWithValue("@username",  username);
                    cmd.Parameters.AddWithValue("@password",  (object)hashedPw ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@firstname", string.IsNullOrEmpty(firstname) ? (object)DBNull.Value : firstname);
                    cmd.Parameters.AddWithValue("@lastname",  string.IsNullOrEmpty(lastname)  ? (object)DBNull.Value : lastname);
                    cmd.Parameters.AddWithValue("@email",     string.IsNullOrEmpty(email)     ? (object)DBNull.Value : email);
                    cmd.Parameters.AddWithValue("@phone",     string.IsNullOrEmpty(phone)     ? (object)DBNull.Value : phone);
                    cmd.Parameters.AddWithValue("@cardid",    string.IsNullOrEmpty(cardid)    ? (object)DBNull.Value : cardid);
                    cmd.Parameters.AddWithValue("@rfidtag",   string.IsNullOrEmpty(rfidtag)   ? (object)DBNull.Value : rfidtag);
                    cmd.Parameters.AddWithValue("@usertype",  string.IsNullOrEmpty(usertype)  ? (object)DBNull.Value : usertype);
                    cmd.Parameters.AddWithValue("@companyid", string.IsNullOrEmpty(companyid) ? (object)DBNull.Value : (object)int.Parse(companyid));
                    cmd.ExecuteNonQuery();
                }
            }
            return null; // success
        }
        catch (Exception ex) { return ex.Message; }
    }

    protected void BtnAddAwUser_Click(object sender, EventArgs e)
    {
        string username  = HfAwAddUsername.Value.Trim();
        string password  = HfAwAddPassword.Value;
        string firstname = HfAwAddFirstName.Value.Trim();
        string lastname  = HfAwAddLastName.Value.Trim();
        string email     = HfAwAddEmail.Value.Trim();
        string phone     = HfAwAddPhone.Value.Trim();
        string cardid    = HfAwAddCardId.Value.Trim();
        string rfidtag   = HfAwAddRfidTag.Value.Trim();
        string usertype  = HfAwAddUserType.Value.Trim();
        string companyid = HfAwAddCompanyId.Value.Trim();

        if (string.IsNullOrWhiteSpace(username)) { LitAwMsg.Text = "<div class='alert alert-err'>&#9888; Username is required.</div>"; BindAwGrid(); return; }

        string awErr = CreateAwUserInternal(username, password, usertype, companyid,
            firstname, lastname, email, phone, cardid, rfidtag);

        if (awErr != null)
        {
            LitAwMsg.Text = "<div class='alert alert-err'>&#9888; " + Server.HtmlEncode(awErr) + "</div>";
        }
        else
        {
            string msg = "&#10003; User <strong>" + Server.HtmlEncode(username) + "</strong> created in the database.";

            // Cross-platform: also create iDash portal account if flagged
            bool alsoIdash = HfAwAddAlsoCreateIdash.Value == "1";
            if (alsoIdash && !string.IsNullOrEmpty(password))
            {
                string idashRole    = HfAwAddIdashRole.Value.Trim();
                string displayName  = (firstname + " " + lastname).Trim();
                if (string.IsNullOrEmpty(displayName)) displayName = username;
                if (string.IsNullOrEmpty(idashRole)) idashRole = "user";

                var siteAccess = ParseSiteAccess(HfAwAddIdashSiteAccess.Value);
                var tileAccess = ParseTileAccess(HfAwAddIdashTileAccess.Value);

                string idashErr = UserManager.AddUser(username, password, idashRole, displayName, "", siteAccess, tileAccess);
                if (idashErr == null)
                    msg += " <strong>iDash portal account</strong> also created.";
                else
                    msg += " <span style='color:var(--danger);'>iDash: " + Server.HtmlEncode(idashErr) + "</span>";
            }

            LitAwMsg.Text = "<div class='alert alert-ok'>" + msg + "</div>";
            InjectMetadataJson();
        }

        bool didCreateIdash = HfAwAddAlsoCreateIdash.Value == "1";

        HfAwAddUsername.Value = ""; HfAwAddPassword.Value = ""; HfAwAddFirstName.Value = "";
        HfAwAddLastName.Value = ""; HfAwAddEmail.Value = ""; HfAwAddPhone.Value = "";
        HfAwAddCardId.Value = ""; HfAwAddRfidTag.Value = ""; HfAwAddUserType.Value = "";
        HfAwAddCompanyId.Value = "";
        HfAwAddAlsoCreateIdash.Value = ""; HfAwAddIdashRole.Value = "";
        HfAwAddIdashSiteAccess.Value = ""; HfAwAddIdashTileAccess.Value = "";
        BindAwGrid();
        if (didCreateIdash)
            BindGrid();
        SwitchToAwTab();
    }

    protected void BtnEditAwUser_Click(object sender, EventArgs e)
    {
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) { LitAwMsg.Text = "<div class='alert alert-err'>&#9888; DB not configured.</div>"; return; }

        int    userId    = 0; int.TryParse(HfAwEditId.Value, out userId);
        string password  = HfAwEditPassword.Value;
        string firstname = HfAwEditFirstName.Value.Trim();
        string lastname  = HfAwEditLastName.Value.Trim();
        string email     = HfAwEditEmail.Value.Trim();
        string phone     = HfAwEditPhone.Value.Trim();
        string cardid    = HfAwEditCardId.Value.Trim();
        string rfidtag   = HfAwEditRfidTag.Value.Trim();
        string usertype  = HfAwEditUserType.Value.Trim();
        string companyid = HfAwEditCompanyId.Value.Trim();

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                if (string.IsNullOrEmpty(companyid))
                {
                    using (var cCmd = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE name IS NOT NULL ORDER BY id", conn))
                    { object r = cCmd.ExecuteScalar(); if (r != null) companyid = r.ToString(); }
                }

                bool chgPw = !string.IsNullOrEmpty(password);
                string sql = chgPw
                    ? "UPDATE dbo.sysuser SET password=@pw,firstname=@fn,lastname=@ln,email=@em,phone=@ph,cardid=@ci,rfidtag=@rt,usertype=@ut,companyid=@co WHERE id=@id"
                    : "UPDATE dbo.sysuser SET firstname=@fn,lastname=@ln,email=@em,phone=@ph,cardid=@ci,rfidtag=@rt,usertype=@ut,companyid=@co WHERE id=@id";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    if (chgPw) cmd.Parameters.AddWithValue("@pw", HashPasswordV3(password));
                    cmd.Parameters.AddWithValue("@fn", string.IsNullOrEmpty(firstname) ? (object)DBNull.Value : firstname);
                    cmd.Parameters.AddWithValue("@ln", string.IsNullOrEmpty(lastname)  ? (object)DBNull.Value : lastname);
                    cmd.Parameters.AddWithValue("@em", string.IsNullOrEmpty(email)     ? (object)DBNull.Value : email);
                    cmd.Parameters.AddWithValue("@ph", string.IsNullOrEmpty(phone)     ? (object)DBNull.Value : phone);
                    cmd.Parameters.AddWithValue("@ci", string.IsNullOrEmpty(cardid)    ? (object)DBNull.Value : cardid);
                    cmd.Parameters.AddWithValue("@rt", string.IsNullOrEmpty(rfidtag)   ? (object)DBNull.Value : rfidtag);
                    cmd.Parameters.AddWithValue("@ut", string.IsNullOrEmpty(usertype)  ? (object)DBNull.Value : usertype);
                    cmd.Parameters.AddWithValue("@co", string.IsNullOrEmpty(companyid) ? (object)DBNull.Value : (object)int.Parse(companyid));
                    cmd.ExecuteNonQuery();
                }
            }
            LitAwMsg.Text = "<div class='alert alert-ok'>&#10003; User updated successfully.</div>";
        }
        catch (Exception ex) { LitAwMsg.Text = "<div class='alert alert-err'>&#9888; " + Server.HtmlEncode(ex.Message) + "</div>"; }

        HfAwEditId.Value = ""; HfAwEditPassword.Value = "";
        BindAwGrid();
        SwitchToAwTab();
    }

    protected void GridAwUsers_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName != "DeleteAwUser") return;
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) return;
        int userId = 0; int.TryParse(e.CommandArgument.ToString(), out userId);
        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand("DELETE FROM dbo.sysuser WHERE id = @id", conn))
                { cmd.Parameters.AddWithValue("@id", userId); cmd.ExecuteNonQuery(); }
            }
            LitAwMsg.Text = "<div class='alert alert-ok'>&#10003; User deleted.</div>";
        }
        catch (Exception ex) { LitAwMsg.Text = "<div class='alert alert-err'>&#9888; " + Server.HtmlEncode(ex.Message) + "</div>"; }
        BindAwGrid();
        SwitchToAwTab();
    }

    // ====================================================================
    // COMPANIES
    // ====================================================================
    protected void BtnAddCompany_Click(object sender, EventArgs e)
    {
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; DB not configured.</div>"; return; }
        string name = HfAddCompanyName.Value.Trim();
        if (string.IsNullOrEmpty(name)) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; Company name is required.</div>"; return; }
        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand("INSERT INTO dbo.company (name) VALUES (@name)", conn))
                { cmd.Parameters.AddWithValue("@name", name); cmd.ExecuteNonQuery(); }
            }
            LitCoMsg.Text = "<div class='alert alert-ok'>&#10003; Company <strong>" + Server.HtmlEncode(name) + "</strong> added.</div>";
            InjectMetadataJson(); // refresh JS idashSites list
        }
        catch (Exception ex) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; " + Server.HtmlEncode(ex.Message) + "</div>"; }
        HfAddCompanyName.Value = "";
    }

    protected void BtnEditCompany_Click(object sender, EventArgs e)
    {
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; DB not configured.</div>"; return; }
        int companyId = 0;
        if (!int.TryParse(HfEditCompanyId.Value, out companyId) || companyId <= 0) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; Invalid company ID.</div>"; return; }
        string name = HfEditCompanyName.Value.Trim();
        if (string.IsNullOrEmpty(name)) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; Company name is required.</div>"; return; }
        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand("UPDATE dbo.company SET name = @name WHERE id = @id", conn))
                { cmd.Parameters.AddWithValue("@name", name); cmd.Parameters.AddWithValue("@id", companyId); cmd.ExecuteNonQuery(); }
            }
            LitCoMsg.Text = "<div class='alert alert-ok'>&#10003; Company renamed to <strong>" + Server.HtmlEncode(name) + "</strong>.</div>";
            InjectMetadataJson();
        }
        catch (Exception ex) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; " + Server.HtmlEncode(ex.Message) + "</div>"; }
        HfEditCompanyId.Value = ""; HfEditCompanyName.Value = "";
    }

    protected void BtnDeleteCompany_Click(object sender, EventArgs e)
    {
        string cs = AwConnStr;
        if (string.IsNullOrEmpty(cs)) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; DB not configured.</div>"; return; }
        int companyId = 0;
        if (!int.TryParse(HfDeleteCompanyId.Value, out companyId) || companyId <= 0) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; Invalid company ID.</div>"; return; }
        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                string companyName = "(unknown)";
                using (var cmd = new SqlCommand("SELECT name FROM dbo.company WHERE id = @cid", conn))
                { cmd.Parameters.AddWithValue("@cid", companyId); object r = cmd.ExecuteScalar(); if (r != null) companyName = r.ToString(); }

                // Reassign users
                using (var cmd = new SqlCommand(
                    "UPDATE dbo.sysuser SET companyid = (SELECT MIN(id) FROM dbo.company WHERE id <> @cid AND name IS NOT NULL) WHERE companyid = @cid", conn))
                { cmd.Parameters.AddWithValue("@cid", companyId); cmd.ExecuteNonQuery(); }

                // Cascade delete data
                string[] tables = { "alarmack","alarm","checkouthistory","locationhistory","employeelocationhistory",
                    "gpslocationhistory","maintenancehistory","sensorreading","sensorstat","audit","event",
                    "queuedcommand","printjob","filedata","AWAssetSync","assettemp","locationtemp","location","asset" };
                foreach (string tbl in tables)
                {
                    try {
                        using (var cmd = new SqlCommand("DELETE FROM dbo.[" + tbl + "] WHERE companyid = @cid", conn))
                        { cmd.Parameters.AddWithValue("@cid", companyId); cmd.CommandTimeout = 120; cmd.ExecuteNonQuery(); }
                    } catch { }
                }

                using (var cmd = new SqlCommand("DELETE FROM dbo.company WHERE id = @cid", conn))
                { cmd.Parameters.AddWithValue("@cid", companyId); cmd.ExecuteNonQuery(); }

                LitCoMsg.Text = "<div class='alert alert-ok'>&#10003; Company <strong>" + Server.HtmlEncode(companyName) + "</strong> deleted.</div>";
                InjectMetadataJson();
            }
        }
        catch (Exception ex) { LitCoMsg.Text = "<div class='alert alert-err'>&#9888; " + Server.HtmlEncode(ex.Message) + "</div>"; }
        HfDeleteCompanyId.Value = "";
    }
}
