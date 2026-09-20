using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;

/// <summary>
/// Manages iDash portal user accounts.
/// Users are stored as JSON at App_Data\idash_users.json.
///
/// ROLES (portal-level):
///   admin    - full access: all tools, admin panel, documentation, user management
///   user     - standard access: scanning/tagging tools, reports, research, documentation
///   readonly - view-only: reports and documentation, no scanning or admin tools
///
/// SITE PERMISSIONS (per site, stored in SiteAccess dict):
///   Key   = site name exactly as stored in dbo.company.name  (or "*" = all sites)
///   Value = "full"  -> can move assets, commit scans, run all inventory operations
///           "ennx"  -> can generate ENNX reports and view data only; cannot move assets
///
/// Admin accounts always have full access to all sites regardless of SiteAccess.
/// For non-admin users with an empty/null SiteAccess dict, no site access is assumed.
/// </summary>
public static class UserManager
{
    // Permission value constants
    public const string PERM_FULL = "full";
    public const string PERM_ENNX = "ennx";

    // Role constants
    public const string ROLE_ADMIN    = "admin";
    public const string ROLE_USER     = "user";
    public const string ROLE_READONLY = "readonly";

    // -------------------------------------------------------------------
    // Data model
    // -------------------------------------------------------------------
    [Serializable]
    public class IdashUser
    {
        public string Username      { get; set; }
        public string PasswordHash  { get; set; }   // SHA-256 hex, lowercase
        public string Role          { get; set; }   // admin | user | readonly
        public string DisplayName   { get; set; }
        public string Notes         { get; set; }
        public bool   Enabled       { get; set; }
        public string CreatedDate   { get; set; }
        public string LastLogin     { get; set; }
        public string AgreementAcceptedDate { get; set; }

        /// <summary>
        /// Per-site permission map.
        /// Key   = site name (matches dbo.company.name exactly)
        /// Value = "full" or "ennx"
        /// Null / empty -> no site access (unless role is admin).
        /// Special key "*" = all sites at the specified permission level.
        /// </summary>
        public Dictionary<string, string> SiteAccess { get; set; }

        /// <summary>
        /// List of tile section keys this user can see on the hub.
        /// Null or containing "*" = all sections visible.
        /// Valid keys: reports, guides, search
        /// Admin role always sees everything regardless.
        /// </summary>
        public List<string> TileAccess { get; set; }
    }

    // -------------------------------------------------------------------
    // Storage path
    // -------------------------------------------------------------------
    private static string DataFilePath
    {
        get
        {
            string appDataPath = HttpContext.Current.Server.MapPath("~/App_Data");
            if (!Directory.Exists(appDataPath))
                Directory.CreateDirectory(appDataPath);
            return Path.Combine(appDataPath, "idash_users.json");
        }
    }

    // -------------------------------------------------------------------
    // Password hashing (SHA-256)
    // -------------------------------------------------------------------
    public static string HashPassword(string password)
    {
        using (var sha = SHA256.Create())
        {
            byte[] bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(password ?? ""));
            return BitConverter.ToString(bytes).Replace("-", "").ToLowerInvariant();
        }
    }

    // -------------------------------------------------------------------
    // Load / Save
    // -------------------------------------------------------------------
    public static List<IdashUser> LoadUsers()
    {
        if (!File.Exists(DataFilePath))
        {
            // Seed default admin on first run
            var seed = new List<IdashUser>
            {
                new IdashUser
                {
                    Username     = "idashadmin",
                    PasswordHash = HashPassword("idashadmin"),
                    Role         = ROLE_ADMIN,
                    DisplayName  = "iDash Administrator",
                    Notes        = "Default built-in administrator.",
                    Enabled      = true,
                    CreatedDate  = DateTime.Now.ToString("yyyy-MM-dd HH:mm"),
                    LastLogin    = "",
                    SiteAccess   = new Dictionary<string, string> { { "*", PERM_FULL } },
                    TileAccess   = new List<string> { "*" }
                }
            };
            SaveUsers(seed);
            return seed;
        }

        try
        {
            string json = File.ReadAllText(DataFilePath, Encoding.UTF8);
            var ser  = new JavaScriptSerializer();
            var list = ser.Deserialize<List<IdashUser>>(json) ?? new List<IdashUser>();

            // Back-compat: older records without SiteAccess get an empty dict
            foreach (var u in list)
            {
                if (u.SiteAccess == null)
                    u.SiteAccess = new Dictionary<string, string>();
                // Back-compat: older records without TileAccess get wildcard (all tiles)
                if (u.TileAccess == null)
                    u.TileAccess = new List<string> { "*" };
            }

            return list;
        }
        catch
        {
            return new List<IdashUser>();
        }
    }

    public static void SaveUsers(List<IdashUser> users)
    {
        var ser = new JavaScriptSerializer();
        File.WriteAllText(DataFilePath, ser.Serialize(users), Encoding.UTF8);
    }

    // -------------------------------------------------------------------
    // Authentication
    // -------------------------------------------------------------------
    public static IdashUser Authenticate(string username, string password)
    {
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            return null;

        var users = LoadUsers();
        string hash = HashPassword(password);

        IdashUser match = null;
        foreach (var u in users)
        {
            if (u.Username.Equals(username.Trim(), StringComparison.OrdinalIgnoreCase)
                && u.PasswordHash == hash
                && u.Enabled)
            {
                match = u;
                break;
            }
        }

        if (match != null)
        {
            match.LastLogin = DateTime.Now.ToString("yyyy-MM-dd HH:mm");
            SaveUsers(users);
        }

        return match;
    }

    // -------------------------------------------------------------------
    // Role helpers
    // -------------------------------------------------------------------

    /// <summary>
    /// Looks up a user record by username (case-insensitive).
    /// Returns null if not found or username is blank.
    /// Use this to retrieve the current user's role and site/tile access
    /// after they have already been authenticated via session.
    /// </summary>
    public static IdashUser GetUser(string username)
    {
        if (string.IsNullOrWhiteSpace(username)) return null;
        foreach (var u in LoadUsers())
        {
            if (u.Username.Equals(username.Trim(), StringComparison.OrdinalIgnoreCase))
                return u;
        }
        return null;
    }

    /// <summary>
    /// Records the exact timestamp when a user accepts the Software Usage & Non-Duplication Agreement.
    /// </summary>
    public static void RecordAgreementAccepted(string username)
    {
        if (string.IsNullOrWhiteSpace(username)) return;
        var users = LoadUsers();
        foreach (var u in users)
        {
            if (u.Username.Equals(username.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                u.AgreementAcceptedDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                SaveUsers(users);
                break;
            }
        }
    }

    /// <summary>
    /// Checks whether a user has already reviewed and accepted the Software Usage Agreement.
    /// </summary>
    public static bool HasAcceptedAgreement(string username)
    {
        var u = GetUser(username);
        return u != null && !string.IsNullOrEmpty(u.AgreementAcceptedDate);
    }

    public static bool CanAccessAdmin(string role)
    {
        return role == ROLE_ADMIN;
    }

    public static bool CanAccessDocs(string role)
    {
        return role == ROLE_ADMIN || role == ROLE_USER || role == ROLE_READONLY;
    }

    public static bool CanAccessTools(string role)
    {
        return role == ROLE_ADMIN || role == ROLE_USER;
    }

    public static string RoleLabel(string role)
    {
        switch (role)
        {
            case ROLE_ADMIN:    return "Administrator";
            case ROLE_USER:     return "Standard User";
            case ROLE_READONLY: return "Read-Only";
            default:            return role ?? "";
        }
    }

    public static string PermLabel(string perm)
    {
        switch (perm)
        {
            case PERM_FULL: return "Full Access";
            case PERM_ENNX: return "ENNX / Report Only";
            default:        return perm ?? "None";
        }
    }

    // -------------------------------------------------------------------
    // Tile access helpers  (per-tile granularity)
    // -------------------------------------------------------------------

    /// <summary>All valid per-tile keys for the hub page.</summary>
    public static readonly string[] TILE_KEYS = {
        // Guides & Downloads
        "downloads", "docs", "guides", "docs_arch", "docs_label_sop", "docs_cookbook",
        // Reports
        "rpt_overview", "rpt_asset_master", "rpt_tagging", "rpt_eil",
        "rpt_room", "rpt_roomdir", "rpt_activity", "rpt_ennx", "rpt_sessions",
        "rpt_automation", "rpt_fixed_reader", "rpt_notifications",
        // Reports — Extended
        "rpt_data_research", "rpt_tag_audit", "rpt_data_quality",
        "rpt_cmr", "rpt_tag_stats", "rpt_tagging_detail", "rpt_location_list",
        // Search
        "search_history", "search_asset", "search_location",
        // Scanning & Tools
        "scan_maps", "scan_tagteam", "scan_inventory", "scan_ennx", "scan_eil",
        "scan_universal_ennx", "print_mapping", "scan_locator",
        // Admin
        "admin_sitedata", "admin_autodb", "admin_field_sync", "admin_workbench", "admin_manualdb",
        "admin_sql", "admin_bcp", "admin_excel", "admin_logs",
        "admin_loganalyzer", "admin_restore", "admin_email", "admin_users",
        // Admin — Extended
        "admin_training", "admin_site_config", "admin_license_manager", "admin_diagnostics",
        "admin_system_update", "admin_fhir_bridge", "admin_reader_config",
        "admin_printer_routing", "admin_tag_type", "admin_mqtt"
    };

    /// <summary>Grouped tile keys for the user management checkbox UI.</summary>
    public static readonly string[][] TILE_GROUPS = {
        new[] { "Guides & Downloads",   "downloads", "docs", "guides", "docs_arch", "docs_cookbook" },
        new[] { "Reports",              "rpt_notifications", "rpt_asset_master", "rpt_tagging", "rpt_data_quality",
                                        "rpt_ennx", "rpt_sessions", "rpt_automation", "rpt_fixed_reader" },
        new[] { "Scanning & Tools",     "scan_maps", "scan_tagteam", "scan_inventory", "scan_ennx", "scan_eil",
                                        "scan_universal_ennx", "scan_locator" },
        new[] { "Printing",             "print_mapping", "admin_printer_routing", "excel_print" },
        new[] { "Admin Panel",          "admin_sitedata", "admin_autodb", "admin_field_sync", "admin_workbench",
                                        "admin_sql", "admin_bcp", "admin_excel",
                                        "admin_logs", "admin_loganalyzer", "admin_restore", "admin_users" },
        new[] { "Admin — Extended",     "admin_training", "admin_site_config", "admin_license_manager",
                                        "admin_diagnostics", "admin_system_update", "admin_fhir_bridge",
                                        "admin_reader_config", "admin_tag_type", "admin_mqtt" }
    };

    /// <summary>Human-readable labels for tile keys.</summary>
    public static string TileLabel(string key)
    {
        switch (key)
        {
            // Guides
            case "downloads":     return "Secure Downloads";
            case "docs":          return "iDash Documentation Hub";
            case "guides":        return "User Guides & Walkthroughs";
            case "docs_arch":     return "Architecture & Rationale";
            case "docs_cookbook": return "IDI Mobile Connectivity Cookbook";
            // Reports
            case "rpt_notifications": return "iDash Notifications & Watch List";
            case "rpt_asset_master": return "Asset Master";
            case "rpt_tagging":   return "Tagging Dashboards & Activity";
            case "rpt_data_quality": return "Data Quality Report";
            case "rpt_ennx":      return "ENNX Export Files";
            case "rpt_sessions":  return "Past Inventory Sessions";
            case "rpt_automation":return "Daily Report Automation";
            case "rpt_fixed_reader": return "Fixed Reader Dashboard";
            // Scanning
            case "scan_maps":          return "Site Location Maps & Tagging";
            case "scan_tagteam":       return "Tag Team Scan";
            case "scan_inventory":     return "VA Site Inventory";
            case "scan_ennx":          return "ENNX Live Scan";
            case "scan_eil":           return "EIL Live Scan";
            case "scan_universal_ennx": return "Universal ENNX Creator";
            case "scan_locator":       return "RFID Asset Locator";
            // Printing
            case "print_mapping":      return "Printer Administration";
            case "admin_printer_routing": return "Printer Routing Config";
            case "excel_print":        return "Excel Equipment Import & Print";
            // Admin Panel
            case "admin_sitedata":     return "Cart Data & Sync Hub (All-in-One)";
            case "admin_autodb":       return "Auto DB Update & Watcher";
            case "admin_field_sync":   return "Field Server Sync (.BAK Restore)";
            case "admin_workbench":    return "DB Update Workbench & SQL Staging";
            case "admin_manualdb":     return "Manual DB Update (Legacy)";
            case "admin_sql":          return "SQL Upload";
            case "admin_bcp":          return "VA On Network Queries";
            case "admin_excel":        return "Excel Merge Tool";
            case "admin_logs":         return "System Logs & Automation History";
            case "admin_loganalyzer":  return "IIS & App Log Analyzer";
            case "admin_restore":      return "Database Restore";
            case "admin_users":        return "User Management (Consolidated)";
            // Admin — Extended
            case "admin_training":     return "Training & Setup Hub";
            case "admin_site_config":  return "System Configuration";
            case "admin_license_manager": return "License Manager & Cart Keys";
            case "admin_diagnostics":  return "System Diagnostics & Health Monitor";
            case "admin_system_update":return "System Update & Deploy";
            case "admin_fhir_bridge":  return "FHIR Bridge Sync";
            case "admin_reader_config":return "Fixed Reader Configuration";
            case "admin_tag_type":     return "Tag Type Management";
            case "admin_mqtt":         return "MQTT / RabbitMQ Broker";
            // Special
            case "*":             return "All Tiles";
            default:              return key ?? "";
        }
    }

    /// <summary>Returns true if the user can see the given tile.</summary>
    public static bool CanAccessTile(string role, List<string> tileAccess, string tileKey)
    {
        if (role == ROLE_ADMIN) return true;
        if (tileAccess == null || tileAccess.Count == 0) return false;
        if (tileAccess.Contains("*")) return true;
        return tileAccess.Contains(tileKey);
    }

    /// <summary>Returns true if the user has ANY tile in the given group prefix (e.g. "rpt_", "docs").</summary>
    public static bool HasAnyTileInGroup(string role, List<string> tileAccess, string prefix)
    {
        if (role == ROLE_ADMIN) return true;
        if (tileAccess == null || tileAccess.Count == 0) return false;
        if (tileAccess.Contains("*")) return true;
        foreach (var t in tileAccess)
            if (t.StartsWith(prefix)) return true;
        return false;
    }

    /// <summary>Builds a human-readable summary of tile access.</summary>
    public static string TileAccessSummary(IdashUser user)
    {
        if (user == null) return "None";
        if (user.Role == ROLE_ADMIN) return "All Tiles (Admin)";
        if (user.TileAccess == null || user.TileAccess.Count == 0) return "No Tiles";
        if (user.TileAccess.Contains("*")) return "All Tiles";
        if (user.TileAccess.Count <= 4)
        {
            var labels = new List<string>();
            foreach (var k in user.TileAccess) labels.Add(TileLabel(k));
            return string.Join(", ", labels.ToArray());
        }
        return user.TileAccess.Count + " tiles assigned";
    }

    // -------------------------------------------------------------------
    // Site-permission helpers
    // -------------------------------------------------------------------

    /// <summary>
    /// Returns the permission string for a given site name, or null if no access.
    /// Admins always return PERM_FULL regardless of SiteAccess.
    /// Wildcard key "*" matches any site.
    /// </summary>
    public static string GetSitePermission(IdashUser user, string siteName)
    {
        if (user == null) return null;
        if (user.Role == ROLE_ADMIN) return PERM_FULL;

        if (user.SiteAccess == null || user.SiteAccess.Count == 0) return null;

        string perm;
        if (user.SiteAccess.TryGetValue(siteName, out perm)) return perm;

        string wildPerm;
        if (user.SiteAccess.TryGetValue("*", out wildPerm)) return wildPerm;

        return null;
    }

    /// <summary>Returns true if the user can see data for the given site.</summary>
    public static bool CanAccessSite(IdashUser user, string siteName)
    {
        return GetSitePermission(user, siteName) != null;
    }

    /// <summary>Returns true if the user can perform write operations (move assets, commit) for this site.</summary>
    public static bool CanWriteSite(IdashUser user, string siteName)
    {
        return GetSitePermission(user, siteName) == PERM_FULL;
    }

    /// <summary>Returns true if the user can generate ENNX / reports for this site.</summary>
    public static bool CanReportSite(IdashUser user, string siteName)
    {
        string p = GetSitePermission(user, siteName);
        return p == PERM_FULL || p == PERM_ENNX;
    }

    /// <summary>Builds a human-readable summary of a user's site access.</summary>
    public static string SiteAccessSummary(IdashUser user)
    {
        if (user == null) return "None";
        if (user.Role == ROLE_ADMIN) return "All Sites - Full Access";
        if (user.SiteAccess == null || user.SiteAccess.Count == 0) return "No Sites";

        string wildPerm;
        if (user.SiteAccess.TryGetValue("*", out wildPerm))
            return "All Sites - " + PermLabel(wildPerm);

        var parts = new List<string>();
        foreach (var kv in user.SiteAccess.OrderBy(x => x.Key))
            parts.Add(kv.Key + " [" + PermLabel(kv.Value) + "]");

        return string.Join(", ", parts.ToArray());
    }

    // -------------------------------------------------------------------
    // CRUD
    // -------------------------------------------------------------------

    /// <summary>
    /// Creates a new user.
    /// siteAccess: key = site name (or "*"), value = "full" | "ennx".
    /// Returns null on success, error string on failure.
    /// </summary>
    public static string AddUser(string username, string password, string role,
                                 string displayName, string notes,
                                 Dictionary<string, string> siteAccess, List<string> tileAccess)
    {
        if (string.IsNullOrWhiteSpace(username)) return "Username is required.";
        if (string.IsNullOrWhiteSpace(password)) return "Password is required.";
        if (password.Length < 6)                 return "Password must be at least 6 characters.";

        string[] validRoles = { ROLE_ADMIN, ROLE_USER, ROLE_READONLY };
        if (!validRoles.Contains(role)) return "Invalid role selected.";

        var users = LoadUsers();
        foreach (var u in users)
        {
            if (u.Username.Equals(username.Trim(), StringComparison.OrdinalIgnoreCase))
                return "A user with that username already exists.";
        }

        var cleanAccess = new Dictionary<string, string>();
        if (siteAccess != null)
        {
            foreach (var kv in siteAccess)
            {
                string v = (kv.Value == PERM_FULL || kv.Value == PERM_ENNX) ? kv.Value : PERM_ENNX;
                cleanAccess[kv.Key.Trim()] = v;
            }
        }

        var cleanTiles = tileAccess != null ? new List<string>(tileAccess) : new List<string>();

        users.Add(new IdashUser
        {
            Username     = username.Trim().ToLower(),
            PasswordHash = HashPassword(password),
            Role         = role,
            DisplayName  = !string.IsNullOrWhiteSpace(displayName) ? displayName.Trim() : username.Trim(),
            Notes        = notes != null ? notes.Trim() : "",
            Enabled      = true,
            CreatedDate  = DateTime.Now.ToString("yyyy-MM-dd HH:mm"),
            LastLogin    = "",
            SiteAccess   = cleanAccess,
            TileAccess   = cleanTiles
        });

        SaveUsers(users);
        return null; // null = success
    }

    /// <summary>
    /// Updates an existing user. Pass null/empty newPassword to leave it unchanged.
    /// Returns null on success, error string on failure.
    /// </summary>
    public static string UpdateUser(string username, string newPassword, string newRole,
                                    string newDisplayName, string newNotes, bool enabled,
                                    Dictionary<string, string> siteAccess, List<string> tileAccess)
    {
        var users = LoadUsers();
        IdashUser user = null;
        foreach (var u in users)
        {
            if (u.Username.Equals(username, StringComparison.OrdinalIgnoreCase))
            {
                user = u;
                break;
            }
        }
        if (user == null) return "User not found.";

        string[] validRoles = { ROLE_ADMIN, ROLE_USER, ROLE_READONLY };
        if (!validRoles.Contains(newRole)) return "Invalid role selected.";

        if (!string.IsNullOrWhiteSpace(newPassword))
        {
            if (newPassword.Length < 6) return "Password must be at least 6 characters.";
            user.PasswordHash = HashPassword(newPassword);
        }

        user.Role        = newRole;
        user.DisplayName = !string.IsNullOrWhiteSpace(newDisplayName) ? newDisplayName.Trim() : user.DisplayName;
        user.Notes       = newNotes != null ? newNotes.Trim() : "";
        user.Enabled     = enabled;

        var cleanAccess = new Dictionary<string, string>();
        if (siteAccess != null)
        {
            foreach (var kv in siteAccess)
            {
                string v = (kv.Value == PERM_FULL || kv.Value == PERM_ENNX) ? kv.Value : PERM_ENNX;
                cleanAccess[kv.Key.Trim()] = v;
            }
        }
        user.SiteAccess = cleanAccess;

        user.TileAccess = tileAccess != null ? new List<string>(tileAccess) : new List<string>();

        SaveUsers(users);
        return null;
    }

    /// <summary>Returns null on success, or an error string.</summary>
    public static string DeleteUser(string username)
    {
        var users   = LoadUsers();
        int before  = users.Count;
        users.RemoveAll(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase));
        if (users.Count == before) return "User not found.";
        SaveUsers(users);
        return null;
    }
    // -------------------------------------------------------------------
    // Site-filtering helpers  (centralized for all pages)
    // -------------------------------------------------------------------

    /// <summary>
    /// Returns the list of company IDs the current session user is allowed to see.
    /// Returns null if user is unrestricted (admin or wildcard "*" access).
    /// Returns empty list if no SiteAccess is set (no data visible).
    /// </summary>
    public static List<int> GetAllowedCompanyIds(System.Web.SessionState.HttpSessionState session, string connStr)
    {
        string role = Convert.ToString(session["IdashUserRole"]);
        if (role == ROLE_ADMIN) return null; // Admins see everything

        var siteAccess = session["IdashSiteAccess"] as Dictionary<string, string>;
        if (siteAccess == null || siteAccess.Count == 0) return new List<int>(); // No access
        if (siteAccess.ContainsKey("*")) return null; // Wildcard = unrestricted

        var siteKeys = siteAccess.Keys.ToList();
        var ids = new HashSet<int>();

        using (var conn = new SqlConnection(connStr))
        {
            conn.Open();
            using (var cmd = new SqlCommand("SELECT id, name FROM dbo.company", conn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    int cid = rdr.GetInt32(0);
                    string cname = (rdr["name"] as string ?? "").Trim();

                    foreach (var s in siteKeys)
                    {
                        if (string.IsNullOrWhiteSpace(s)) continue;
                        string key = s.Trim();

                        // 1. Exact match
                        if (cname.Equals(key, StringComparison.OrdinalIgnoreCase))
                        {
                            ids.Add(cid);
                            break;
                        }

                        // 2. Direct ID match (e.g. key is "4")
                        int parsedId;
                        if (int.TryParse(key, out parsedId) && parsedId == cid)
                        {
                            ids.Add(cid);
                            break;
                        }

                        // 3. Station prefix match (e.g. key is "517", cname is "517 Beckley")
                        if (cname.StartsWith(key + " ", StringComparison.OrdinalIgnoreCase) ||
                            key.StartsWith(cname + " ", StringComparison.OrdinalIgnoreCase))
                        {
                            ids.Add(cid);
                            break;
                        }

                        // 4. Substring match (e.g. key is "Beckley", cname is "517 Beckley")
                        if (cname.IndexOf(key, StringComparison.OrdinalIgnoreCase) >= 0 ||
                            key.IndexOf(cname, StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            ids.Add(cid);
                            break;
                        }
                    }
                }
            }
        }
        return ids.ToList();
    }

    /// <summary>
    /// Builds a SQL fragment to restrict queries to the user's allowed sites.
    /// Returns "" for unrestricted users, or " AND companyid IN (1,5,12)" for restricted users.
    /// If alias is provided, uses "alias.companyid" instead of "companyid".
    /// If useWhere=true, returns " WHERE companyid IN (...)" instead of " AND ...".
    /// </summary>
    public static string BuildSiteFilter(System.Web.SessionState.HttpSessionState session, string connStr, string alias = null, bool useWhere = false)
    {
        var ids = GetAllowedCompanyIds(session, connStr);
        if (ids == null) return ""; // Unrestricted
        if (ids.Count == 0) return (useWhere ? " WHERE 1=0" : " AND 1=0"); // No access
        string col = string.IsNullOrEmpty(alias) ? "companyid" : alias + ".companyid";
        string inClause = col + " IN (" + string.Join(",", ids) + ")";
        return useWhere ? (" WHERE " + inClause) : (" AND " + inClause);
    }

    /// <summary>
    /// Filters a company DropDownList to only show sites the user can access.
    /// Adds "All Sites" option if multiple sites are allowed.
    /// Auto-selects if only one site is allowed.
    /// </summary>
    public static void FilterCompanyDropdown(DropDownList ddl, System.Web.SessionState.HttpSessionState session, string connStr)
    {
        var ids = GetAllowedCompanyIds(session, connStr);
        using (var conn = new SqlConnection(connStr))
        {
            conn.Open();
            string sql;
            SqlCommand cmd;
            if (ids == null)
            {
                // Unrestricted — show all
                sql = "SELECT id, name FROM dbo.company ORDER BY name";
                cmd = new SqlCommand(sql, conn);
            }
            else if (ids.Count == 0)
            {
                // No access — empty dropdown
                ddl.Items.Clear();
                ddl.Items.Add(new ListItem("No Sites Available", "0"));
                return;
            }
            else
            {
                // Restricted — only allowed sites
                var paramNames = new List<string>();
                cmd = new SqlCommand();
                for (int i = 0; i < ids.Count; i++)
                {
                    paramNames.Add("@id" + i);
                    cmd.Parameters.AddWithValue("@id" + i, ids[i]);
                }
                sql = "SELECT id, name FROM dbo.company WHERE id IN (" + string.Join(",", paramNames) + ") ORDER BY name";
                cmd.CommandText = sql;
            }
            cmd.Connection = conn;
            using (var rdr = cmd.ExecuteReader())
            {
                ddl.DataSource = rdr;
                ddl.DataTextField = "name";
                ddl.DataValueField = "id";
                ddl.DataBind();
            }
        }
        // "All Sites" only for unrestricted or multi-site users
        if (ids == null || ids.Count > 1)
            ddl.Items.Insert(0, new ListItem("All Sites", "0"));
        else if (ids.Count == 1 && ddl.Items.Count > 0)
            ddl.SelectedIndex = 0;
    }
}
