using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class va_aw_user_management : Page
{
    // ── Session keys ────────────────────────────────────────────────
    private const string SESSION_AUTH = "IsAdminAuthenticated";
    private const string SESSION_ROLE = "IdashUserRole";
    private const string SESSION_USER = "IdashUsername";

    // Session key for the user-supplied iDash DB connection string
    private const string SESSION_AWCONN = "AwUserMgmt_ConnStr";

    // ── ASP.NET Core Identity V3 password hasher (compatible) ─────
    // Produces the same binary format: 0x01 | prf(4 bytes) | iterCount(4 bytes) | saltLen(4 bytes) | salt | subkey
    // Defaults: HMACSHA256 (prf=1), 10000 iterations, 128-bit salt, 256-bit subkey
    private static string HashPasswordV3(string password)
    {
        const int SaltSize   = 16;   // 128-bit
        const int SubkeySize = 32;   // 256-bit
        const int Iterations = 10000;

        byte[] salt = new byte[SaltSize];
        using (var rng = RandomNumberGenerator.Create()) { rng.GetBytes(salt); }

        byte[] subkey;
        using (var kdf = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
        {
            subkey = kdf.GetBytes(SubkeySize);
        }

        // Build the output: marker(1) + prf(4) + iter(4) + saltLen(4) + salt + subkey
        byte[] output = new byte[1 + 4 + 4 + 4 + SaltSize + SubkeySize];
        output[0] = 0x01; // format marker V3

        // Write big-endian uint32 values using helper
        WriteNetworkByteOrder(output, 1, 1);           // PRF = HMACSHA256 = 1
        WriteNetworkByteOrder(output, 5, Iterations);  // iteration count
        WriteNetworkByteOrder(output, 9, SaltSize);    // salt length

        System.Buffer.BlockCopy(salt,   0, output, 13,               SaltSize);
        System.Buffer.BlockCopy(subkey, 0, output, 13 + SaltSize,     SubkeySize);

        return Convert.ToBase64String(output);
    }

    private static void WriteNetworkByteOrder(byte[] buffer, int offset, int value)
    {
        unchecked
        {
            buffer[offset]     = (byte)(((uint)value >> 24) & 0xFF);
            buffer[offset + 1] = (byte)(((uint)value >> 16) & 0xFF);
            buffer[offset + 2] = (byte)(((uint)value >> 8)  & 0xFF);
            buffer[offset + 3] = (byte)(((uint)value)       & 0xFF);
        }
    }

    // ── Page load ────────────────────────────────────────────────────
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
        Response.Cache.SetNoStore();

        // Gate: must be logged-in iDash admin
        bool hasTileAccess = false;
        var tiles = Session["IdashTileAccess"] as List<string>;
        if (tiles != null)
            hasTileAccess = UserManager.CanAccessTile((string)Session[SESSION_ROLE], tiles, "admin_users");

        bool isAdmin = Session[SESSION_AUTH] != null &&
                       (bool)Session[SESSION_AUTH] &&
                       (((string)Session[SESSION_ROLE] == UserManager.ROLE_ADMIN) || hasTileAccess);

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
            // Pre-populate with web.config connection if available
            var csEntry = ConfigurationManager.ConnectionStrings["iDash"];
            if (csEntry != null)
            {
                string cs = csEntry.ConnectionString;
                TxtServer.Text   = GetConnPart(cs, "Data Source");
                TxtDatabase.Text = GetConnPart(cs, "Database");
                TxtSqlUser.Text  = GetConnPart(cs, "User ID");
            }

            // If we already have a stored connection, auto-load
            if (Session[SESSION_AWCONN] != null)
            {
                LoadUsersAndCompanies();
                PnlConnected.Visible     = true;
                PnlNotConnected.Visible  = false;
                PnlCompanyMgmt.Visible   = true;
                connOk.Visible  = true;
                connOff.Visible = false;
            }
        }
    }

    // ── Connection helpers ───────────────────────────────────────────
    private string GetConnPart(string connectionString, string partName)
    {
        foreach (string part in connectionString.Split(';'))
        {
            var kv = part.Split(new char[] { '=' }, 2);
            if (kv.Length == 2 && kv[0].Trim().Equals(partName, StringComparison.OrdinalIgnoreCase))
                return kv[1].Trim();
        }
        return "";
    }

    private string BuildConnectionString()
    {
        return string.Format(
            "Data Source={0};Database={1};User ID={2};Password={3};Encrypt=False;TrustServerCertificate=True;Connect Timeout=15",
            TxtServer.Text.Trim(),
            TxtDatabase.Text.Trim(),
            TxtSqlUser.Text.Trim(),
            TxtSqlPassword.Text);
    }

    private string GetConnectionString()
    {
        return Session[SESSION_AWCONN] as string;
    }

    // ── Connect button ──────────────────────────────────────────────
    protected void BtnConnect_Click(object sender, EventArgs e)
    {
        string cs = BuildConnectionString();

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                // Verify sysuser table exists
                using (var cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sysuser'", conn))
                {
                    int cnt = (int)cmd.ExecuteScalar();
                    if (cnt == 0)
                    {
                        ShowMsg("Connected to the database, but table <strong>dbo.sysuser</strong> was not found. Is this an iDash database?", true);
                        return;
                    }
                }
            }

            Session[SESSION_AWCONN] = cs;
            LoadUsersAndCompanies();
            PnlConnected.Visible    = true;
            PnlNotConnected.Visible = false;
            PnlCompanyMgmt.Visible  = true;
            connOk.Visible  = true;
            connOff.Visible = false;
            ShowMsg("Connected successfully to <strong>" + Server.HtmlEncode(TxtDatabase.Text.Trim()) + "</strong> on <strong>" + Server.HtmlEncode(TxtServer.Text.Trim()) + "</strong>.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Connection failed: " + Server.HtmlEncode(ex.Message), true);
        }
    }

    // ── Disconnect ──────────────────────────────────────────────────
    protected void BtnDisconnect_Click(object sender, EventArgs e)
    {
        Session.Remove(SESSION_AWCONN);
        PnlConnected.Visible    = false;
        PnlNotConnected.Visible = true;
        connOk.Visible  = false;
        connOff.Visible = true;
        GridAwUsers.DataSource   = null;
        GridAwUsers.DataBind();
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
        catch { /* ignore */ }
    }

    // ── Load users + companies ──────────────────────────────────────
    private void LoadUsersAndCompanies()
    {
        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) return;

        try
        {
            var users = new List<AwUser>();
            var companies = new List<AwCompany>();

            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                EnsureAwUserColumns(conn);

                // Load users
                using (var cmd = new SqlCommand(@"
                    SELECT u.id, u.username, u.firstname, u.lastname, u.email, u.phone,
                           u.cardid, u.rfidtag, u.usertype, u.companyid,
                           u.hideadminpopups, u.inventorylimiteduser, u.restricteditmobile,
                           c.name AS companyname
                    FROM dbo.sysuser u
                    LEFT JOIN dbo.company c ON c.id = u.companyid
                    ORDER BY u.username", conn))
                {
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            users.Add(new AwUser
                            {
                                Id                   = Convert.ToInt32(rdr["id"]),
                                Username             = rdr["username"].ToString(),
                                FirstName            = rdr["firstname"] == DBNull.Value ? "" : rdr["firstname"].ToString(),
                                LastName             = rdr["lastname"]  == DBNull.Value ? "" : rdr["lastname"].ToString(),
                                Email                = rdr["email"]     == DBNull.Value ? "" : rdr["email"].ToString(),
                                Phone                = rdr["phone"]     == DBNull.Value ? "" : rdr["phone"].ToString(),
                                CardId               = rdr["cardid"]    == DBNull.Value ? "" : rdr["cardid"].ToString(),
                                RfidTag              = rdr["rfidtag"]   == DBNull.Value ? "" : rdr["rfidtag"].ToString(),
                                UserType             = rdr["usertype"]  == DBNull.Value ? "" : rdr["usertype"].ToString(),
                                CompanyId            = rdr["companyid"] == DBNull.Value ? (int?)null : Convert.ToInt32(rdr["companyid"]),
                                CompanyName          = rdr["companyname"] == DBNull.Value ? "" : rdr["companyname"].ToString(),
                                HideAdminPopups      = rdr["hideadminpopups"] != DBNull.Value && Convert.ToBoolean(rdr["hideadminpopups"]),
                                InventoryLimitedUser = rdr["inventorylimiteduser"] != DBNull.Value && Convert.ToBoolean(rdr["inventorylimiteduser"]),
                                RestrictEditMobile   = rdr["restricteditmobile"] != DBNull.Value && Convert.ToBoolean(rdr["restricteditmobile"])
                            });
                        }
                    }
                }

                // Load companies
                using (var cmd = new SqlCommand(
                    "SELECT id, name FROM dbo.company WHERE name IS NOT NULL ORDER BY name", conn))
                {
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            companies.Add(new AwCompany
                            {
                                Id   = Convert.ToInt32(rdr["id"]),
                                Name = rdr["name"].ToString()
                            });
                        }
                    }
                }
            }

            GridAwUsers.DataSource = users;
            GridAwUsers.DataBind();

            // Inject companies as JS variable
            var ser = new JavaScriptSerializer();
            LitCompanies.Text = "<script>window.awCompanies = " + ser.Serialize(companies) + ";</script>";
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading data: " + Server.HtmlEncode(ex.Message), true);
        }
    }

    // ── Add user ────────────────────────────────────────────────────
    protected void BtnAddAwUser_Click(object sender, EventArgs e)
    {
        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) { ShowMsg("Not connected to a database.", true); return; }

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
        bool   hidePopups     = HfAwAddHidePopups.Value == "true";
        bool   invLimited     = HfAwAddInvLimited.Value == "true";
        bool   restrictMobile = HfAwAddRestrictMobile.Value == "true";

        if (string.IsNullOrWhiteSpace(username))
        {
            ShowMsg("Username is required.", true);
            LoadUsersAndCompanies();
            return;
        }

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();

                // Check uniqueness
                using (var chk = new SqlCommand("SELECT COUNT(*) FROM dbo.sysuser WHERE username = @u", conn))
                {
                    chk.Parameters.AddWithValue("@u", username);
                    if ((int)chk.ExecuteScalar() > 0)
                    {
                        ShowMsg("Username <strong>" + Server.HtmlEncode(username) + "</strong> already exists.", true);
                        LoadUsersAndCompanies();
                        return;
                    }
                }

                // Hash password (or NULL if blank)
                string hashedPw = null;
                if (!string.IsNullOrEmpty(password))
                    hashedPw = HashPasswordV3(password);

                using (var cmd = new SqlCommand(@"
                    INSERT INTO dbo.sysuser
                        (username, password, firstname, lastname, email, phone, cardid, rfidtag,
                         usertype, companyid, hideadminpopups, inventorylimiteduser, restricteditmobile)
                    VALUES
                        (@username, @password, @firstname, @lastname, @email, @phone, @cardid, @rfidtag,
                         @usertype, @companyid, @hidePopups, @invLimited, @restrictMobile)", conn))
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

                    // Auto-assign first available company if none selected
                    // Prevents "Company: False" which breaks RFID access
                    if (string.IsNullOrEmpty(companyid))
                    {
                        using (var cCmd = new SqlCommand(
                            "SELECT TOP 1 id FROM dbo.company WHERE name IS NOT NULL ORDER BY id", conn))
                        {
                            object firstId = cCmd.ExecuteScalar();
                            if (firstId != null)
                                companyid = firstId.ToString();
                        }
                    }
                    cmd.Parameters.AddWithValue("@companyid", string.IsNullOrEmpty(companyid) ? (object)DBNull.Value : (object)int.Parse(companyid));
                    cmd.Parameters.AddWithValue("@hidePopups",     hidePopups);
                    cmd.Parameters.AddWithValue("@invLimited",     invLimited);
                    cmd.Parameters.AddWithValue("@restrictMobile", restrictMobile);

                    cmd.ExecuteNonQuery();
                }
            }
            string savedCompanyId = companyid;
            ShowMsg("User <strong>" + Server.HtmlEncode(username) + "</strong> created successfully." +
                (string.IsNullOrEmpty(savedCompanyId)
                    ? " <span style='color:#e74c3c;'>⚠ WARNING: No company assigned — user will show 'Company: False' in the scanner.</span>"
                    : " (CompanyID: " + savedCompanyId + ")"), 
                string.IsNullOrEmpty(savedCompanyId));
        }
        catch (Exception ex)
        {
            ShowMsg("Error creating user: " + Server.HtmlEncode(ex.Message), true);
        }

        ClearAddFields();
        LoadUsersAndCompanies();
    }

    // ── Edit user ───────────────────────────────────────────────────
    protected void BtnEditAwUser_Click(object sender, EventArgs e)
    {
        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) { ShowMsg("Not connected to a database.", true); return; }

        int    userId    = int.Parse(HfAwEditId.Value);
        string password  = HfAwEditPassword.Value;
        string firstname = HfAwEditFirstName.Value.Trim();
        string lastname  = HfAwEditLastName.Value.Trim();
        string email     = HfAwEditEmail.Value.Trim();
        string phone     = HfAwEditPhone.Value.Trim();
        string cardid    = HfAwEditCardId.Value.Trim();
        string rfidtag   = HfAwEditRfidTag.Value.Trim();
        string usertype  = HfAwEditUserType.Value.Trim();
        string companyid = HfAwEditCompanyId.Value.Trim();
        bool   hidePopups     = HfAwEditHidePopups.Value == "true";
        bool   invLimited     = HfAwEditInvLimited.Value == "true";
        bool   restrictMobile = HfAwEditRestrictMobile.Value == "true";

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();

                string sql;
                if (!string.IsNullOrEmpty(password))
                {
                    sql = @"UPDATE dbo.sysuser SET
                                password = @password,
                                firstname = @firstname, lastname = @lastname,
                                email = @email, phone = @phone,
                                cardid = @cardid, rfidtag = @rfidtag,
                                usertype = @usertype, companyid = @companyid,
                                hideadminpopups = @hidePopups,
                                inventorylimiteduser = @invLimited,
                                restricteditmobile = @restrictMobile
                            WHERE id = @id";
                }
                else
                {
                    sql = @"UPDATE dbo.sysuser SET
                                firstname = @firstname, lastname = @lastname,
                                email = @email, phone = @phone,
                                cardid = @cardid, rfidtag = @rfidtag,
                                usertype = @usertype, companyid = @companyid,
                                hideadminpopups = @hidePopups,
                                inventorylimiteduser = @invLimited,
                                restricteditmobile = @restrictMobile
                            WHERE id = @id";
                }

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);

                    if (!string.IsNullOrEmpty(password))
                        cmd.Parameters.AddWithValue("@password", HashPasswordV3(password));

                    cmd.Parameters.AddWithValue("@firstname", string.IsNullOrEmpty(firstname) ? (object)DBNull.Value : firstname);
                    cmd.Parameters.AddWithValue("@lastname",  string.IsNullOrEmpty(lastname)  ? (object)DBNull.Value : lastname);
                    cmd.Parameters.AddWithValue("@email",     string.IsNullOrEmpty(email)     ? (object)DBNull.Value : email);
                    cmd.Parameters.AddWithValue("@phone",     string.IsNullOrEmpty(phone)     ? (object)DBNull.Value : phone);
                    cmd.Parameters.AddWithValue("@cardid",    string.IsNullOrEmpty(cardid)    ? (object)DBNull.Value : cardid);
                    cmd.Parameters.AddWithValue("@rfidtag",   string.IsNullOrEmpty(rfidtag)   ? (object)DBNull.Value : rfidtag);
                    cmd.Parameters.AddWithValue("@usertype",  string.IsNullOrEmpty(usertype)  ? (object)DBNull.Value : usertype);

                    // Auto-assign first available company if none selected
                    // Prevents "Company: False" which breaks RFID access
                    if (string.IsNullOrEmpty(companyid))
                    {
                        using (var cCmd = new SqlCommand(
                            "SELECT TOP 1 id FROM dbo.company WHERE name IS NOT NULL ORDER BY id", conn))
                        {
                            object firstId = cCmd.ExecuteScalar();
                            if (firstId != null)
                                companyid = firstId.ToString();
                        }
                    }
                    cmd.Parameters.AddWithValue("@companyid", string.IsNullOrEmpty(companyid) ? (object)DBNull.Value : (object)int.Parse(companyid));
                    cmd.Parameters.AddWithValue("@hidePopups",     hidePopups);
                    cmd.Parameters.AddWithValue("@invLimited",     invLimited);
                    cmd.Parameters.AddWithValue("@restrictMobile", restrictMobile);

                    cmd.ExecuteNonQuery();
                }
            }

            ShowMsg("User updated successfully.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Error updating user: " + Server.HtmlEncode(ex.Message), true);
        }

        ClearEditFields();
        LoadUsersAndCompanies();
    }

    // ── Delete user ─────────────────────────────────────────────────
    protected void GridAwUsers_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName != "DeleteAwUser") return;

        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) { ShowMsg("Not connected.", true); return; }

        int userId = int.Parse(e.CommandArgument.ToString());

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand("DELETE FROM dbo.sysuser WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    cmd.ExecuteNonQuery();
                }
            }
            ShowMsg("User deleted successfully.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Error deleting user: " + Server.HtmlEncode(ex.Message), true);
        }

        LoadUsersAndCompanies();
    }

    // ── Build edit onclick ──────────────────────────────────────────
    protected string BuildAwEditOnClick(object dataItem)
    {
        var u = dataItem as AwUser;
        if (u == null) return "return false;";

        return string.Format(
            "openAwEditModal({0},'{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}',{10},{11},{12}); return false;",
            u.Id,
            EscJs(u.Username),
            EscJs(u.FirstName),
            EscJs(u.LastName),
            EscJs(u.Email),
            EscJs(u.Phone),
            EscJs(u.CardId),
            EscJs(u.RfidTag),
            EscJs(u.UserType),
            u.CompanyId.HasValue ? u.CompanyId.Value.ToString() : "",
            u.HideAdminPopups ? "true" : "false",
            u.InventoryLimitedUser ? "true" : "false",
            u.RestrictEditMobile ? "true" : "false");
    }

    private string EscJs(string s)
    {
        if (s == null) return "";
        return s.Replace("\\", "\\\\").Replace("'", "\\'").Replace("\"", "\\\"");
    }

    // ── Helpers ──────────────────────────────────────────────────────
    private void ShowMsg(string msg, bool isError)
    {
        string cls  = isError ? "alert-err" : "alert-ok";
        string icon = isError ? "&#9888;" : "&#10003;";
        LitMsg.Text = string.Format("<div class='alert {0}'>{1} {2}</div>", cls, icon, msg);
    }

    private void ClearAddFields()
    {
        HfAwAddUsername.Value = "";
        HfAwAddPassword.Value = "";
        HfAwAddFirstName.Value = "";
        HfAwAddLastName.Value = "";
        HfAwAddEmail.Value = "";
        HfAwAddPhone.Value = "";
        HfAwAddCardId.Value = "";
        HfAwAddRfidTag.Value = "";
        HfAwAddUserType.Value = "";
        HfAwAddCompanyId.Value = "";
        HfAwAddHidePopups.Value = "";
        HfAwAddInvLimited.Value = "";
        HfAwAddRestrictMobile.Value = "";
    }

    private void ClearEditFields()
    {
        HfAwEditId.Value = "";
        HfAwEditPassword.Value = "";
        HfAwEditFirstName.Value = "";
        HfAwEditLastName.Value = "";
        HfAwEditEmail.Value = "";
        HfAwEditPhone.Value = "";
        HfAwEditCardId.Value = "";
        HfAwEditRfidTag.Value = "";
        HfAwEditUserType.Value = "";
        HfAwEditCompanyId.Value = "";
        HfAwEditHidePopups.Value = "";
        HfAwEditInvLimited.Value = "";
        HfAwEditRestrictMobile.Value = "";
    }

    // ── Add company ─────────────────────────────────────────────────
    protected void BtnAddCompany_Click(object sender, EventArgs e)
    {
        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) { ShowMsg("Not connected to a database.", true); return; }

        string name = HfAddCompanyName.Value.Trim();
        if (string.IsNullOrEmpty(name)) { ShowMsg("Company name is required.", true); return; }

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "INSERT INTO dbo.company (name) VALUES (@name)", conn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    cmd.ExecuteNonQuery();
                }
            }
            ShowMsg("Company <strong>" + Server.HtmlEncode(name) + "</strong> added successfully.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Error adding company: " + Server.HtmlEncode(ex.Message), true);
        }

        HfAddCompanyName.Value = "";
        LoadUsersAndCompanies();
    }

    // ── Edit company ─────────────────────────────────────────────────
    protected void BtnEditCompany_Click(object sender, EventArgs e)
    {
        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) { ShowMsg("Not connected to a database.", true); return; }

        int companyId;
        if (!int.TryParse(HfEditCompanyId.Value, out companyId) || companyId <= 0)
        { ShowMsg("Invalid company ID.", true); return; }

        string name = HfEditCompanyName.Value.Trim();
        if (string.IsNullOrEmpty(name)) { ShowMsg("Company name is required.", true); return; }

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "UPDATE dbo.company SET name = @name WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    cmd.Parameters.AddWithValue("@id", companyId);
                    cmd.ExecuteNonQuery();
                }
            }
            ShowMsg("Company updated to <strong>" + Server.HtmlEncode(name) + "</strong>.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Error updating company: " + Server.HtmlEncode(ex.Message), true);
        }

        HfEditCompanyId.Value = "";
        HfEditCompanyName.Value = "";
        LoadUsersAndCompanies();
    }

    // ── Delete company ─────────────────────────────────────────────
    protected void BtnDeleteCompany_Click(object sender, EventArgs e)
    {
        string cs = GetConnectionString();
        if (string.IsNullOrEmpty(cs)) { ShowMsg("Not connected to a database.", true); return; }

        int companyId;
        if (!int.TryParse(HfDeleteCompanyId.Value, out companyId) || companyId <= 0)
        {
            ShowMsg("Invalid company ID.", true);
            return;
        }

        try
        {
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();

                // Get company name for the confirmation message
                string companyName = "(unknown)";
                using (var cmd = new SqlCommand(
                    "SELECT name FROM dbo.company WHERE id = @cid", conn))
                {
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    object result = cmd.ExecuteScalar();
                    if (result != null) companyName = result.ToString();
                }

                var details = new System.Text.StringBuilder();

                // Reassign users to next available company (never delete users)
                using (var cmd = new SqlCommand(
                    "UPDATE dbo.sysuser SET companyid = " +
                    "(SELECT MIN(id) FROM dbo.company WHERE id <> @cid AND name IS NOT NULL) " +
                    "WHERE companyid = @cid", conn))
                {
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    int moved = cmd.ExecuteNonQuery();
                    if (moved > 0)
                        details.AppendFormat("users reassigned: {0}, ", moved);
                }

                // ONLY delete pure data tables — nothing else
                // DO NOT touch: clientapp, reader, antenna, plugin, serverstatus,
                //               printclient, mqttclient, mapsite, template, sysuser, employee, etc.
                string[] cascadeTables = new[]
                {
                    "alarmack", "alarm",
                    "checkouthistory", "locationhistory", "employeelocationhistory",
                    "gpslocationhistory", "maintenancehistory", "sensorreading", "sensorstat",
                    "audit", "event", "queuedcommand", "printjob", "filedata",
                    "AWAssetSync", "assettemp", "locationtemp",
                    "location", "asset"
                };

                int totalDeleted = 0;

                foreach (string table in cascadeTables)
                {
                    try
                    {
                        using (var cmd = new SqlCommand(
                            "DELETE FROM dbo.[" + table + "] WHERE companyid = @cid", conn))
                        {
                            cmd.Parameters.AddWithValue("@cid", companyId);
                            cmd.CommandTimeout = 120;
                            int rows = cmd.ExecuteNonQuery();
                            if (rows > 0)
                            {
                                totalDeleted += rows;
                                details.AppendFormat("{0}: {1}, ", table, rows);
                            }
                        }
                    }
                    catch { /* table may not exist in this version — skip */ }
                }

                // Delete the company itself
                using (var cmd = new SqlCommand(
                    "DELETE FROM dbo.company WHERE id = @cid", conn))
                {
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    cmd.ExecuteNonQuery();
                }

                string detail = details.Length > 0
                    ? " (" + details.ToString().TrimEnd(',', ' ') + ")"
                    : "";
                ShowMsg(string.Format(
                    "Deleted company <strong>{0}</strong> and {1} related record(s).{2}",
                    Server.HtmlEncode(companyName), totalDeleted, detail), false);
            }

            LoadUsersAndCompanies();
        }
        catch (Exception ex)
        {
            ShowMsg("Error deleting company: " + Server.HtmlEncode(ex.Message), true);
        }
    }

    // ── Data models ─────────────────────────────────────────────────
    [Serializable]
    public class AwUser
    {
        public int      Id                   { get; set; }
        public string   Username             { get; set; }
        public string   FirstName            { get; set; }
        public string   LastName             { get; set; }
        public string   Email                { get; set; }
        public string   Phone                { get; set; }
        public string   CardId               { get; set; }
        public string   RfidTag              { get; set; }
        public string   UserType             { get; set; }
        public int?     CompanyId            { get; set; }
        public string   CompanyName          { get; set; }
        public bool     HideAdminPopups      { get; set; }
        public bool     InventoryLimitedUser { get; set; }
        public bool     RestrictEditMobile   { get; set; }
    }

    [Serializable]
    public class AwCompany
    {
        public int    Id   { get; set; }
        public string Name { get; set; }
    }
}
