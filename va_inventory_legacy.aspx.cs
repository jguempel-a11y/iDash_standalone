using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class va_inventory_legacy : System.Web.UI.Page
{
    [Serializable]
    public class ScanItem
    {
        public string Guid { get; set; }
        public int AssetId { get; set; }
        public string Barcode { get; set; }
        public string Description { get; set; }
        public string SerialNumber { get; set; }
        public string CMR { get; set; }
        public string DbLocation { get; set; }
        public string CurrentLocation { get; set; }
        public string TagType { get; set; } // Added for auto-print mapping
        public string Status { get; set; } // "Found", "Moved Here", "Not Found"
    }

    private List<ScanItem> ScanList
    {
        get
        {
            var list = Session["Inventory_ScanList"] as List<ScanItem>;
            if (list == null)
            {
                list = new List<ScanItem>();
                Session["Inventory_ScanList"] = list;
            }
            return list;
        }
        set { Session["Inventory_ScanList"] = value; }
    }

    private string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    private void SafeFocus(System.Web.UI.WebControls.WebControl ctl)
    {
        // Always focus — mobile soft keyboard is suppressed via inputmode="none" on the inputs
        ctl.Focus();
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Request.QueryString["action"] == "sync")
        {
            HandleSyncRequest();
            return;
        }

        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "scan_inventory"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            BindUsers();
            string current = (User != null && User.Identity != null) ? User.Identity.Name : "";
            if (!string.IsNullOrEmpty(current) && DdlEmpl.Items.FindByValue(current) != null)
                DdlEmpl.SelectedValue = current;

            LoadCompanies();
            TxtCurrentDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
            BindGrid();
            SafeFocus(TxtLocationScan);
        }

        // Suppress soft keyboard on Android/mobile — DataWedge injects keystrokes directly
        // so the on-screen keyboard must not appear when these fields receive focus
        TxtLocationScan.Attributes["inputmode"] = "none";
        TxtAssetScan.Attributes["inputmode"] = "none";
        InjectPrintScript();
    }

    private void InjectPrintScript()
    {
        try
        {
            string apiBase = Request.Url.GetLeftPart(UriPartial.Authority) + "/api";
            string tmJson = "{}";
            try {
                string path = Server.MapPath("print_mapping_config.json");
                if (System.IO.File.Exists(path)) {
                    tmJson = System.IO.File.ReadAllText(path);
                }
            } catch { }

            var templateRoutes = new System.Collections.Generic.Dictionary<string, string>();
            var availableClients = new System.Collections.Generic.List<string>();
            var printTemplates = new System.Collections.Generic.List<object>();
            
            using (var con = new System.Data.SqlClient.SqlConnection(ConnStr)) {
                con.Open();
                using (var cmd = new System.Data.SqlClient.SqlCommand(@"
                    SELECT t.id, 
                           t.name,
                           ISNULL(NULLIF(t.usewithservice, ''), p.username) as finalRouting
                    FROM template t
                    LEFT JOIN printclient p ON t.printclientid = p.id
                    ORDER BY t.name", con))
                using (var r = cmd.ExecuteReader()) {
                    while (r.Read()) {
                        string idStr = Convert.ToInt64(r[0]).ToString();
                        string name = r[1].ToString();
                        string routing = r[2] == DBNull.Value ? "" : r[2].ToString();
                        
                        if (!string.IsNullOrEmpty(routing)) 
                            templateRoutes[idStr] = routing;

                        printTemplates.Add(new {
                            id = Convert.ToInt64(r[0]),
                            name = name
                        });
                    }
                }

                using (var cmdClients = new System.Data.SqlClient.SqlCommand("SELECT username FROM printclient UNION SELECT username FROM mqttclient ORDER BY username", con))
                using (var rClient = cmdClients.ExecuteReader()) {
                    while (rClient.Read()) {
                        availableClients.Add(rClient[0].ToString());
                    }
                }
            }

            string trJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(templateRoutes);
            string clJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(availableClients);
            string ptJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(printTemplates);

            string jsConfig = string.Format(@"
<script>
    window.awPrintConfig = {{
        apiBase: '{0}',
        templateMappings: {1},
        templateRoutes: {2},
        availableClients: {3},
        printTemplates: {4}
    }};
</script>", apiBase, tmJson, trJson, clJson, ptJson);
            
            Literal LitConf = (Literal)FindControl("LitPrintConfig");
            if (LitConf != null) LitConf.Text = jsConfig;

            Literal LitScrip = (Literal)FindControl("LitPrintScript");
            if (LitScrip != null) LitScrip.Text = @"
<script>
    document.addEventListener('DOMContentLoaded', setupPrintTemplates);
    function setupPrintTemplates() {
        if (!window.awPrintConfig || !window.awPrintConfig.printTemplates) return;
        try {
            const ddlTpl = document.getElementById('DdlPrintTemplate');
            if (ddlTpl && ddlTpl.options.length <= 1) {
                window.awPrintConfig.printTemplates.forEach(t => {
                    ddlTpl.options.add(new Option(t.name + ' (ID: ' + t.id + ')', t.id));
                });
            }
            const ddlTgt = document.getElementById('DdlPrintTarget');
            if (ddlTgt && ddlTgt.options.length <= 1 && window.awPrintConfig.availableClients) {
                window.awPrintConfig.availableClients.forEach(c => {
                    ddlTgt.options.add(new Option('Client: ' + c, c));
                });
            }
        } catch (e) { console.error('Failed to setup print templates', e); }
    }
</script>";
        } catch (Exception ex) {
            Literal LitConf = (Literal)FindControl("LitPrintConfig");
            if (LitConf != null) LitConf.Text = "<!-- Error loading API scripts: " + ex.Message + " -->";
        }
    }

    private void LoadCompanies()
    {
        try
        {
            // Restrict to user's allowed sites
            var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                SqlCommand cmd;

                if (allowedIds == null)
                {
                    // Admin / wildcard — show all
                    cmd = new SqlCommand("SELECT id, name FROM dbo.company ORDER BY name", conn);
                }
                else if (allowedIds.Count == 0)
                {
                    DdlCompany.Items.Clear();
                    DdlCompany.Items.Insert(0, new ListItem("-- No sites assigned --", ""));
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
                    cmd.CommandText = "SELECT id, name FROM dbo.company WHERE id IN (" + string.Join(",", parms) + ") ORDER BY name";
                }

                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }

                // Auto-select if user has exactly one site
                if (DdlCompany.Items.Count == 1)
                {
                    DdlCompany.SelectedIndex = 0;
                }
                else
                {
                    DdlCompany.Items.Insert(0, new ListItem("-- Select Site --", ""));
                }
            }
        }
        catch { }
    }

    /// <summary>
    /// Returns true if the current session user is allowed to access the given companyId.
    /// Writes an error to LitMsg and returns false if access is denied.
    /// </summary>
    private bool EnforceSiteAccess(int companyId)
    {
        var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);
        if (allowedIds == null) return true; // admin / wildcard
        if (companyId == 0 || !allowedIds.Contains(companyId))
        {
            LitMsg.Text = "<div class='err'>&#9888; Access denied: you do not have access to this site.</div>";
            return false;
        }
        return true;
    }

    private int GetSelectedCompanyId()
    {
        string val = DdlCompany.SelectedValue;
        if (string.IsNullOrWhiteSpace(val)) return 0;

        int cid = 0;
        try {
            using (var con = new SqlConnection(ConnStr)) {
                con.Open();
                using (var cmd = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE CAST(id AS varchar) = @val OR LEFT(LTRIM(name), 3) = @val", con)) {
                    cmd.Parameters.AddWithValue("@val", val);
                    var res = cmd.ExecuteScalar();
                    if (res != null && res != DBNull.Value) cid = Convert.ToInt32(res);
                }
            }
        } catch { }
        return cid;
    }

    private void BindUsers()
    {
        try {
            using (var con = new SqlConnection(ConnStr)) {
                con.Open();
                string sql = "SELECT DISTINCT username FROM v_sysuser ORDER BY username";
                using (var cmd = new SqlCommand(sql, con))
                using (var r = cmd.ExecuteReader()) {
                    DdlEmpl.DataSource = r;
                    DdlEmpl.DataTextField = "username";
                    DdlEmpl.DataValueField = "username";
                    DdlEmpl.DataBind();
                }
            }
            DdlEmpl.Items.Insert(0, new ListItem("-- Select User --", ""));
        } catch {
            DdlEmpl.Items.Add(new ListItem("Admin", "Admin"));
        }
    }

    private void BindGrid()
    {
        try {
            var list = ScanList;
            
            string activeCmr = DdlCmrFilter.SelectedValue;
            if (!string.IsNullOrEmpty(activeCmr))
            {
                list = list.Where(x => (string.IsNullOrEmpty(x.CMR) ? "UNASSIGNED" : x.CMR) == activeCmr).ToList();
            }

            // Apply column sorting if active
            string sortExpr = ViewState["SortExpr"] as string;
            string sortDir = ViewState["SortDir"] as string ?? "ASC";
            if (!string.IsNullOrEmpty(sortExpr))
            {
                Func<ScanItem, object> key = null;
                switch (sortExpr)
                {
                    case "Status": key = x => x.Status ?? ""; break;
                    case "Barcode": key = x => x.Barcode ?? ""; break;
                    case "Description": key = x => x.Description ?? ""; break;
                    case "SerialNumber": key = x => x.SerialNumber ?? ""; break;
                    case "CMR": key = x => x.CMR ?? ""; break;
                    case "DbLocation": key = x => x.DbLocation ?? ""; break;
                    case "CurrentLocation": key = x => x.CurrentLocation ?? ""; break;
                }
                if (key != null)
                    list = (sortDir == "DESC" ? list.OrderByDescending(key) : list.OrderBy(key)).ToList();
            }

            GridScans.DataSource = list;
            GridScans.DataBind();
            // Check full ScanList for pending items (not filtered view)
            BtnCommitMoves.Visible = ScanList.Any(x => x.Status != null && x.Status.Contains("Pending"));
        } catch (Exception ex) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>BindGrid Error: " + ex.Message + "</div>";
        }
    }

    private void PopulateCmrFilter()
    {
        try {
            string prevSelection = "";
            try { prevSelection = DdlCmrFilter.SelectedValue; } catch {}

            DdlCmrFilter.Items.Clear();
            DdlCmrFilter.Items.Add(new ListItem("All CMRs", ""));
            
            var list = ScanList;
            if (list == null || list.Count == 0) 
            {
                DdlCmrFilter.Visible = false;
                return;
            }

            var cmrGroups = list.GroupBy(x => string.IsNullOrEmpty(x.CMR) ? "UNASSIGNED" : x.CMR).OrderBy(x => x.Key);
            
            foreach (var grp in cmrGroups)
            {
                DdlCmrFilter.Items.Add(new ListItem(grp.Key + " (" + grp.Count() + " assets)", grp.Key));
            }

            if (!string.IsNullOrEmpty(prevSelection) && DdlCmrFilter.Items.FindByValue(prevSelection) != null)
                DdlCmrFilter.SelectedValue = prevSelection;
            
            DdlCmrFilter.Visible = true;
        } catch (Exception ex) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text += "<div class='err'>Populate Error: " + ex.Message + "</div>";
        }
    }

    protected void DdlCmrFilter_SelectedIndexChanged(object sender, EventArgs e)
    {
        BindGrid();
    }

    protected void BtnSetLocation_Click(object sender, EventArgs e)
    {
        string loc = TxtLocationScan.Text.Trim().ToUpper();
        if (string.IsNullOrWhiteSpace(loc)) return;

        if (string.IsNullOrWhiteSpace(DdlEmpl.SelectedValue))
        {
            LitMsg.Text = "<div class='err'>&#9888; You must select an Operator before scanning a location!</div>";
            TxtLocationScan.Text = "";
            LblLocationTotal.Style["display"] = "none";
            DdlEmpl.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(DdlCompany.SelectedValue))
        {
            LitMsg.Text = "<div class='err'>&#9888; You must select a Site before scanning a location!</div>";
            TxtLocationScan.Text = "";
            LblLocationTotal.Style["display"] = "none";
            DdlCompany.Focus();
            return;
        }

        if (!loc.StartsWith("SP") || loc.Contains("EE")) 
        {
            LitMsg.Text = "<div class='err'>Invalid Location. You MUST barcode scan a valid Location (starts with SP) before scanning!</div>";
            TxtLocationScan.Text = "";
            TxtLocationScan.Focus();
            LblLocationTotal.Style["display"] = "none";
            return;
        }

        int companyId = GetSelectedCompanyId();
        string siteName = DdlCompany.SelectedItem != null ? DdlCompany.SelectedItem.Text : DdlCompany.SelectedValue;

        // Server-side traverse prevention
        if (!EnforceSiteAccess(companyId)) { TxtLocationScan.Text = ""; return; }

        try {
            using (var con = new SqlConnection(ConnStr)) {
                con.Open();

                // Check if this location barcode exists at all in the location table for this company
                string checkSql = @"
                    SELECT COUNT(*) FROM dbo.location
                    WHERE UPPER(LTRIM(RTRIM(name))) = @Loc
                      AND companyid = @CompanyId";

                int locExists;
                using (var cmdC = new SqlCommand(checkSql, con))
                {
                    cmdC.Parameters.AddWithValue("@Loc", loc);
                    cmdC.Parameters.AddWithValue("@CompanyId", companyId);
                    locExists = Convert.ToInt32(cmdC.ExecuteScalar());
                }

                if (locExists == 0)
                {
                    int otherSiteCount;
                    using (var cmd2 = new SqlCommand("SELECT COUNT(*) FROM dbo.location WHERE UPPER(LTRIM(RTRIM(name))) = @Loc", con))
                    {
                        cmd2.Parameters.AddWithValue("@Loc", loc);
                        otherSiteCount = Convert.ToInt32(cmd2.ExecuteScalar());
                    }

                    string errDetail = otherSiteCount > 0
                        ? string.Format("Location <strong>{0}</strong> exists in the database but belongs to a different site &mdash; not <strong>{1}</strong>.",
                            HttpUtility.HtmlEncode(loc), HttpUtility.HtmlEncode(siteName))
                        : string.Format("Location <strong>{0}</strong> was not found in the database at all.",
                            HttpUtility.HtmlEncode(loc));

                    LitMsg.Text = string.Format(
                        "<div class='err'>&#9888; Invalid Location &mdash; scan rejected! {0} " +
                        "Please scan a valid location barcode for <strong>{1}</strong>, or change the Site Filter.</div>",
                        errDetail, HttpUtility.HtmlEncode(siteName));
                    TxtLocationScan.Text = "";
                    TxtLocationScan.Focus();
                    LblLocationTotal.Style["display"] = "none";
                    return;
                }
            } // end using con
        } catch (Exception ex) {
            LitMsg.Text = "<div class='err'>Error validating location: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
            TxtLocationScan.Text = "";
            LblLocationTotal.Style["display"] = "none";
            return;
        }

        LblCurrentLocation.Text = loc;
        TxtLocationScan.Text = "";
        
        try {
            using (var con = new SqlConnection(ConnStr)) {
                con.Open();
                string sql = @"
                    SELECT id, name, description, text3, text8, text19, text6 
                    FROM dbo.asset 
                    WHERE (text6 = @Loc OR lastobservedlocation = @Loc) 
                      AND (companyid = @CompanyId OR @CompanyId = 0) 
                    ORDER BY name";
                var list = new List<ScanItem>();
                using (var cmd = new SqlCommand(sql, con)) {
                    cmd.Parameters.AddWithValue("@Loc", loc);
                    cmd.Parameters.AddWithValue("@CompanyId", companyId);
                    using (var r = cmd.ExecuteReader()) {
                        while (r.Read()) {
                            list.Add(new ScanItem {
                                Guid = Guid.NewGuid().ToString(),
                                AssetId = Convert.ToInt32(r["id"]),
                                Barcode = r["name"].ToString(),
                                Description = r["description"] != DBNull.Value ? r["description"].ToString() : "",
                                SerialNumber = r["text3"] != DBNull.Value ? r["text3"].ToString() : "",
                                CMR = r["text8"] != DBNull.Value ? r["text8"].ToString() : "",
                                TagType = r["text19"] != DBNull.Value ? r["text19"].ToString() : "",
                                DbLocation = (r["text6"] != DBNull.Value && !string.IsNullOrEmpty(r["text6"].ToString())) ? r["text6"].ToString() : loc,
                                CurrentLocation = loc,
                                Status = "Not Found"
                            });
                        }
                    }
                }
                ScanList = list;
                PopulateCmrFilter();
                BindGrid();
                LblLocationTotal.Text = list.Count + " Assets Assigned";
                LblLocationTotal.Style["display"] = "block";
                LitMsg.Text = "";
            }
        } catch (Exception ex) {
            LitMsg.Text = "<div class='err'>Error loading location: " + ex.Message + "</div>";
            LblLocationTotal.Style["display"] = "none";
        }
        
        SafeFocus(TxtAssetScan);
    }

    private enum ScanResult { Found, Added, NotInDb, WrongSite, InvalidFormat, Empty }

    /// <summary>
    /// Core scan processing shared by single-scan and batch modes.
    /// Returns a ScanResult indicating what happened.
    /// </summary>
    private ScanResult ProcessBarcode(string rawBarcode)
    {
        string barcode = (rawBarcode ?? "").Trim().ToUpper();
        if (string.IsNullOrWhiteSpace(barcode)) return ScanResult.Empty;

        // Extract EE asset tag from raw RFID EPC data if needed (e.g. 512EE12345 -> 512 EE12345)
        var eeMatch = System.Text.RegularExpressions.Regex.Match(barcode, @"^(\d{3})EE(\w+)$", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (eeMatch.Success)
            barcode = eeMatch.Groups[1].Value + " EE" + eeMatch.Groups[2].Value;

        // Validate 3-digit station format
        if (!System.Text.RegularExpressions.Regex.IsMatch(barcode, @"^\d{3} EE\w+$", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
            return ScanResult.InvalidFormat;

        string curLoc = LblCurrentLocation.Text;
        var list = ScanList;

        // 1. Already in the grid — mark as found
        var existing = list.FirstOrDefault(x => string.Equals(x.Barcode, barcode, StringComparison.OrdinalIgnoreCase));
        if (existing != null)
        {
            existing.Status = "Found (Pending)";
            list.Remove(existing);
            list.Insert(0, existing);
            ScanList = list;
            return ScanResult.Found;
        }

        // 2. Look up in DB
        var info = LookupAssetInventoryDetails(barcode);
        if (info == null || info.Id == 0) return ScanResult.NotInDb;

        // 3. Cross-site check
        int currCompanyId = 0;
        if (int.TryParse(DdlCompany.SelectedValue, out currCompanyId) && currCompanyId > 0 && info.CompanyId != currCompanyId && info.CompanyId > 0)
            return ScanResult.WrongSite;

        // 4. Add new item
        bool queueMode = ChkQueueMode.Checked;
        var item = new ScanItem
        {
            Guid = Guid.NewGuid().ToString(),
            AssetId = info.Id,
            Barcode = barcode,
            Description = info.Description ?? "",
            SerialNumber = info.SerialNumber ?? "",
            CMR = info.CMR ?? "",
            TagType = info.TagType ?? "",
            DbLocation = info.DbLocation ?? "(New)",
            CurrentLocation = curLoc,
            Status = queueMode ? "Pending Move" : "Moved Here (Pending)"
        };

        list.Insert(0, item);
        ScanList = list;
        return ScanResult.Added;
    }

    protected void BtnAddAsset_Click(object sender, EventArgs e)
    {
        try {
            if (string.IsNullOrWhiteSpace(DdlEmpl.SelectedValue))
            {
                LitMsg.Text = "<div class='err'>&#9888; You must select an Operator before scanning assets!</div>";
                TxtAssetScan.Text = "";
                DdlEmpl.Focus();
                return;
            }

            if (LblCurrentLocation.Text == "(None Set)") {
                LitMsg.Text = "<div class='err'>You must scan a Location first before scanning assets!</div>";
                TxtAssetScan.Text = "";
                SafeFocus(TxtLocationScan);
                return;
            }

            string barcode = TxtAssetScan.Text.Trim();
            if (string.IsNullOrWhiteSpace(barcode)) return;

            var result = ProcessBarcode(barcode);

            switch (result)
            {
                case ScanResult.InvalidFormat:
                    LitMsg.Text = "<div class='err'><strong>Invalid barcode format:</strong> \"" + HttpUtility.HtmlEncode(barcode) + "\". Expected 3-digit station prefix + space + EE (e.g. \"613 EE123456\").</div>";
                    break;
                case ScanResult.NotInDb:
                    LitMsg.Text = "<div class='err'>Asset " + HttpUtility.HtmlEncode(barcode) + " does not exist in the database! Ignoring scan.</div>";
                    break;
                case ScanResult.WrongSite:
                    LitMsg.Text = "<div class='err'>Asset " + HttpUtility.HtmlEncode(barcode) + " belongs to a different site! You cannot scan cross-site assets.</div>";
                    break;
                default:
                    LitMsg.Text = "";
                    break;
            }

            // Prefix-to-site mismatch warning
            if (result == ScanResult.Found || result == ScanResult.Added)
            {
                if (DdlCompany.SelectedItem != null && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
                {
                    string siteName = DdlCompany.SelectedItem.Text;
                    string sitePrefix = siteName.Length >= 3 ? siteName.Substring(0, 3) : "";
                    string scanPrefix = barcode.Length >= 3 ? barcode.Substring(0, 3) : "";
                    if (System.Text.RegularExpressions.Regex.IsMatch(sitePrefix, @"^\d{3}$") && sitePrefix != scanPrefix)
                    {
                        LitMsg.Text = "<div class='err' style='border-color:#f59e0b; background:rgba(245,158,11,0.1); color:#f59e0b;'>"
                            + "<strong>WARNING: Prefix mismatch!</strong> Scanned prefix \"" + HttpUtility.HtmlEncode(scanPrefix)
                            + "\" does not match selected site \"" + HttpUtility.HtmlEncode(siteName)
                            + "\" (expected prefix " + HttpUtility.HtmlEncode(sitePrefix) + ").</div>";
                    }
                }
            }

            PopulateCmrFilter();
            BindGrid();
            TxtAssetScan.Text = "";
            SafeFocus(TxtAssetScan);

        } catch (Exception ex) {
            LitMsg.Text = "<div class='err'>Error scanning asset: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnSubmitBatch_Click(object sender, EventArgs e)
    {
        try {
            if (string.IsNullOrWhiteSpace(DdlEmpl.SelectedValue))
            {
                LitMsg.Text = "<div class='err'>&#9888; You must select an Operator before scanning assets!</div>";
                return;
            }
            if (LblCurrentLocation.Text == "(None Set)") {
                LitMsg.Text = "<div class='err'>You must scan a Location first before scanning assets!</div>";
                return;
            }

            HiddenField hid = (HiddenField)FindControl("HidBatchData");
            if (hid == null || string.IsNullOrWhiteSpace(hid.Value)) return;

            string[] barcodes;
            try {
                var js = new System.Web.Script.Serialization.JavaScriptSerializer();
                barcodes = js.Deserialize<string[]>(hid.Value);
            } catch {
                LitMsg.Text = "<div class='err'>Invalid batch data.</div>";
                return;
            }

            int found = 0, added = 0, notInDb = 0, wrongSite = 0;
            foreach (string bc in barcodes)
            {
                switch (ProcessBarcode(bc))
                {
                    case ScanResult.Found: found++; break;
                    case ScanResult.Added: added++; break;
                    case ScanResult.NotInDb: notInDb++; break;
                    case ScanResult.WrongSite: wrongSite++; break;
                }
            }

            PopulateCmrFilter();
            BindGrid();
            hid.Value = "";

            var msg = new System.Text.StringBuilder();
            msg.Append("<div class='ok'>Batch complete: ");
            msg.Append((found + added) + " processed");
            if (found > 0) msg.Append(", " + found + " found in-place");
            if (added > 0) msg.Append(", " + added + " new/moved");
            if (notInDb > 0) msg.Append(", <span style='color:var(--danger);'>" + notInDb + " not in DB</span>");
            if (wrongSite > 0) msg.Append(", <span style='color:var(--danger);'>" + wrongSite + " wrong site</span>");
            msg.Append("</div>");
            LitMsg.Text = msg.ToString();
            SafeFocus(TxtAssetScan);

        } catch (Exception ex) {
            LitMsg.Text = "<div class='err'>Batch error: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnCommitMoves_Click(object sender, EventArgs e)
    {
        try {
            string curLoc = LblCurrentLocation.Text;
            if (curLoc == "(None Set)") return;

            var list = ScanList;
            int count = 0;
            foreach (var item in list)
            {
                if (item.Status != null && item.Status.Contains("Pending"))
                {
                    UpdateAssetLocation(item.AssetId, curLoc);
                    if (item.Status.StartsWith("Found")) item.Status = "Found";
                    if (item.Status.StartsWith("Moved")) item.Status = "Moved Here";
                    if (item.Status == "Pending Move") item.Status = "Moved Here";
                    count++;
                }
            }

            if (count > 0)
            {
                ScanList = list;
                BindGrid();
                LitMsg.Text = "<div class='ok'>Successfully committed " + count + " scanned assets to the database.</div>";
            }
        } catch (Exception ex) {
            LitMsg.Text += "<div class='err'>Commit Error: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    public class AssetInventoryDetails {
        public int Id { get; set; }
        public int CompanyId { get; set; }
        public string Description { get; set; }
        public string SerialNumber { get; set; }
        public string CMR { get; set; }
        public string TagType { get; set; }
        public string DbLocation { get; set; }
    }

    private AssetInventoryDetails LookupAssetInventoryDetails(string barcode)
    {
        try {
            using (var con = new SqlConnection(ConnStr)) {
                con.Open();
                string sql = "SELECT TOP 1 id, companyid, description, text3, text8, text19, text6 FROM asset WHERE name = @Name ORDER BY CASE WHEN companyid > 0 THEN 0 ELSE 1 END, id DESC";
                using (var cmd = new SqlCommand(sql, con)) {
                    cmd.Parameters.AddWithValue("@Name", barcode);
                    using (var r = cmd.ExecuteReader()) {
                        if (r.Read()) {
                            return new AssetInventoryDetails {
                                Id = Convert.ToInt32(r["id"]),
                                CompanyId = r["companyid"] == DBNull.Value ? 0 : Convert.ToInt32(r["companyid"]),
                                Description = r["description"].ToString(),
                                SerialNumber = r["text3"].ToString(),
                                CMR = r["text8"].ToString(),
                                TagType = r["text19"].ToString(),
                                DbLocation = r["text6"].ToString()
                            };
                        }
                    }
                }
            }
        } catch { }
        return null;
    }

    private void UpdateAssetLocation(int assetId, string loc) {
        using(var con = new SqlConnection(ConnStr)) {
            con.Open();
            string sql = "UPDATE asset SET text6 = @Loc, text16 = @Loc, lastinventoried = SYSDATETIMEOFFSET(), lastmodifiedby = @Emp WHERE id = @Id";
            using(var cmd = new SqlCommand(sql, con)) {
                cmd.Parameters.AddWithValue("@Loc", loc);
                cmd.Parameters.AddWithValue("@Emp", DdlEmpl.SelectedValue);
                cmd.Parameters.AddWithValue("@Id", assetId);
                cmd.ExecuteNonQuery();
            }
        }
    }

    protected void GridScans_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "Remove")
        {
            string guid = e.CommandArgument.ToString();
            var list = ScanList;
            list.RemoveAll(x => x.Guid == guid);
            ScanList = list;
            PopulateCmrFilter();
            BindGrid();
        }
    }
    
    // Stub methods to prevent ASP.NET crashing on unused UI buttons in copied Template
    protected void BtnRefreshData_Click(object sender, EventArgs e) 
    {
        DdlEmpl.Items.Clear();
        DdlCompany.Items.Clear();
        
        BindUsers();
        LoadCompanies();
        
        string currentUser = (User != null && User.Identity != null) ? User.Identity.Name : "";
        if (!string.IsNullOrEmpty(currentUser) && DdlEmpl.Items.FindByValue(currentUser) != null)
            DdlEmpl.SelectedValue = currentUser;

        Literal LitMsg = (Literal)FindControl("LitMsg");
        if (LitMsg != null) LitMsg.Text = "<div class='ok'>Application data successfully refreshed (Operators & Sites updated).</div>";
    }
    protected void BtnLoadHistory_Click(object sender, EventArgs e) {}
    protected void GridScans_Sorting(object sender, GridViewSortEventArgs e)
    {
        string sortExpr = e.SortExpression;
        string currentDir = ViewState["SortDir"] as string ?? "ASC";
        string newDir = (ViewState["SortExpr"] as string == sortExpr && currentDir == "ASC") ? "DESC" : "ASC";
        ViewState["SortExpr"] = sortExpr;
        ViewState["SortDir"] = newDir;
        BindGrid();
    }
    protected void ChkShowFlagged_CheckedChanged(object sender, EventArgs e) {}
    protected void BtnClear_Click(object sender, EventArgs e) { ScanList.Clear(); PopulateCmrFilter(); BindGrid(); }

    private bool HasUncommittedScans()
    {
        var list = ScanList;
        return list != null && list.Any(x => x.Status.Contains("Pending"));
    }

    private string GetEnnxString()
    {
        var validItems = ScanList.Where(x => x.Status != "Not Found").ToList(); 
        if (!validItems.Any()) return null;

        var dedupedItems = validItems
            .GroupBy(x => x.Barcode, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First())
            .ToList();

        var groups = dedupedItems
            .GroupBy(x => string.IsNullOrWhiteSpace(x.CurrentLocation) ? "UNKNOWN" : x.CurrentLocation, StringComparer.OrdinalIgnoreCase)
            .OrderBy(g => g.Key, StringComparer.OrdinalIgnoreCase);

        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        sb.AppendLine("ENNX");
        sb.AppendLine("ID");
        
        int lineCount = 0;
        foreach (var grp in groups)
        {
            sb.AppendLine(grp.Key);
            lineCount++;
            
            foreach (var item in grp)
            {
                sb.AppendLine(item.Barcode);
                lineCount++;
            }
        }
        
        sb.Append("***END***^" + lineCount);
        return sb.ToString();
    }

    protected void BtnPreviewEnnx_Click(object sender, EventArgs e) 
    {
        if (HasUncommittedScans()) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>You must click 'Commit Scans' to commit your work to the database before exporting.</div>";
            return;
        }

        string ennx = GetEnnxString();
        
        if (string.IsNullOrEmpty(ennx))
        {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>No items in the list to build ENNX for.</div>";
            return;
        }

        TextBox txtPreview = (TextBox)FindControl("TxtPreview");
        if(txtPreview != null) txtPreview.Text = ennx;
    }

    private byte[] GetCsvBytes()
    {
        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        sb.AppendLine("Asset Tag,Description,Serial Number,CMR,Current Loc (DB),Scanned Loc,Status");

        var validItems = ScanList.Where(x => x.Status != "Not Found").ToList();
        foreach (var item in validItems)
        {
            string safeSn = (item.SerialNumber ?? "").Replace("\"", "\"\"");
            if (!string.IsNullOrEmpty(safeSn)) safeSn = "=\"" + safeSn + "\""; else safeSn = "\"\"";

            sb.AppendLine(string.Format("\"{0}\",\"{1}\",{2},\"{3}\",\"{4}\",\"{5}\",\"{6}\"",
                item.Barcode,
                (item.Description ?? "").Replace("\"", "\"\""),
                safeSn,
                (item.CMR ?? "").Replace("\"", "\"\""),
                item.DbLocation,
                item.CurrentLocation,
                item.Status
            ));
        }
        return System.Text.Encoding.UTF8.GetBytes(sb.ToString());
    }

    protected void BtnExportExcel_Click(object sender, EventArgs e)
    {
        if (HasUncommittedScans()) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>You must click 'Commit Scans' to commit your work to the database before exporting to Excel.</div>";
            return;
        }
        
        if (ScanList == null || !ScanList.Any(x => x.Status != "Not Found")) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>You haven't scanned any valid assets yet. There is nothing to export.</div>";
            return;
        }

        try
        {
            byte[] csvBytes = GetCsvBytes();
            if (csvBytes != null)
            {
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                string attachment = "attachment; filename=VA_Site_Inventory_" + timestamp + ".csv";
                Response.ClearContent();
                Response.AddHeader("content-disposition", attachment);
                Response.ContentType = "text/csv";
                Response.BinaryWrite(csvBytes);
                Response.End();
            }
        }
        catch (System.Threading.ThreadAbortException) { }
        catch (Exception ex)
        {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div style='color:red;'>Export Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnEmail_Click(object sender, EventArgs e)
    {
        if (HasUncommittedScans()) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>You must click 'Commit Scans' to commit your work to the database before emailing results.</div>";
            return;
        }
        
        if (ScanList == null || !ScanList.Any(x => x.Status != "Not Found")) {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>You haven't scanned any valid assets yet. There is nothing to email.</div>";
            return;
        }

        try
        {
            string subject = "iDash VA Site Inventory Output";
            string body = "<h3>VA Site Inventory Sweep completed</h3>";
            string currentLoc = ((Label)FindControl("LblCurrentLocation")).Text;
            body += "<p>Location: " + currentLoc + "</p>";
            body += "<p>Generated on: " + DateTime.Now.ToString("g") + "</p>";
            body += "<p>See attached CSV containing the full exported scan data and the ENNX file for direct data loading if needed.</p>";

            System.Collections.Generic.List<System.Net.Mail.Attachment> attachments = new System.Collections.Generic.List<System.Net.Mail.Attachment>();
            string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");

            // Attach CSV
            byte[] csvBytes = GetCsvBytes();
            if (csvBytes != null && csvBytes.Length > 0)
            {
                System.IO.MemoryStream msCsv = new System.IO.MemoryStream(csvBytes);
                System.Net.Mail.Attachment attCsv = new System.Net.Mail.Attachment(msCsv, "VA_Site_Inventory_" + timestamp + ".csv", "text/csv");
                attachments.Add(attCsv);
            }

            // Attach ENNX (as .txt per user request)
            string ennxString = GetEnnxString();
            if (!string.IsNullOrEmpty(ennxString))
            {
                byte[] ennxBytes = System.Text.Encoding.UTF8.GetBytes(ennxString);
                System.IO.MemoryStream msEnnx = new System.IO.MemoryStream(ennxBytes);
                System.Net.Mail.Attachment attEnnx = new System.Net.Mail.Attachment(msEnnx, "VA_Site_Inventory_" + timestamp + ".txt", "text/plain");
                attachments.Add(attEnnx);
            }

            if (attachments.Count == 0)
            {
                Literal LitMsgNone = (Literal)FindControl("LitMsg");
                if (LitMsgNone != null) LitMsgNone.Text = "<div class='err'>No data exists to email.</div>";
                return;
            }

            EmailHelper.SendEmail(subject, body, attachments);
            
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='ok'>Sweep data and ENNX files emailed successfully.</div>";
        }
        catch (Exception ex)
        {
            Literal LitMsg = (Literal)FindControl("LitMsg");
            if (LitMsg != null) LitMsg.Text = "<div class='err'>Email Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    private void HandleSyncRequest()
    {
        Response.ContentType = "application/json";
        try
        {
            string json;
            using (var reader = new System.IO.StreamReader(Request.InputStream))
                json = reader.ReadToEnd();

            var js = new System.Web.Script.Serialization.JavaScriptSerializer();
            var items = js.Deserialize<List<InventoryOfflineItem>>(json);
            if (items == null || items.Count == 0)
            {
                Response.Write("{\"success\":true,\"count\":0,\"message\":\"Empty queue\"}");
                Response.Flush();
                Response.SuppressContent = true;
                HttpContext.Current.ApplicationInstance.CompleteRequest();
                return;
            }

            var list = ScanList;
            int committed = 0;
            int errors = 0;
            string curLoc = LblCurrentLocation.Text;

            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                foreach (var item in items)
                {
                    string bc = (item.Barcode ?? "").Trim().ToUpper();
                    // Validate 3-digit station format
                    if (!System.Text.RegularExpressions.Regex.IsMatch(bc, @"^\d{3} EE\w+$", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                    {
                        errors++;
                        continue;
                    }

                    string locToUse = !string.IsNullOrWhiteSpace(item.Location) ? item.Location : curLoc;
                    string empToUse = !string.IsNullOrWhiteSpace(item.EmplId) ? item.EmplId : (DdlEmpl != null ? DdlEmpl.SelectedValue : "");
                    if (string.IsNullOrWhiteSpace(empToUse) && User != null && User.Identity != null)
                        empToUse = User.Identity.Name;

                    // 1. Check if already in active in-memory list
                    var existing = list.FirstOrDefault(x => string.Equals(x.Barcode, bc, StringComparison.OrdinalIgnoreCase));
                    if (existing != null)
                    {
                        existing.Status = "Found";
                        existing.CurrentLocation = locToUse;
                        if (existing.AssetId > 0 && !string.IsNullOrWhiteSpace(locToUse) && locToUse != "(None Set)")
                        {
                            using (var cmd = new SqlCommand("UPDATE asset SET text6 = @Loc, text16 = @Loc, lastinventoried = SYSDATETIMEOFFSET(), lastmodifiedby = @Emp WHERE id = @Id", con))
                            {
                                cmd.Parameters.AddWithValue("@Loc", locToUse);
                                cmd.Parameters.AddWithValue("@Emp", empToUse ?? "");
                                cmd.Parameters.AddWithValue("@Id", existing.AssetId);
                                cmd.ExecuteNonQuery();
                            }
                            committed++;
                        }
                    }
                    else
                    {
                        // 2. Lookup in DB
                        var info = LookupAssetInventoryDetails(bc);
                        if (info != null && info.Id > 0)
                        {
                            var newItem = new ScanItem
                            {
                                Guid = Guid.NewGuid().ToString(),
                                AssetId = info.Id,
                                Barcode = bc,
                                Description = info.Description ?? "",
                                SerialNumber = info.SerialNumber ?? "",
                                CMR = info.CMR ?? "",
                                TagType = info.TagType ?? "",
                                DbLocation = info.DbLocation ?? "(New)",
                                CurrentLocation = locToUse,
                                Status = (info.DbLocation == locToUse) ? "Found" : "Moved Here"
                            };
                            list.Insert(0, newItem);

                            if (!string.IsNullOrWhiteSpace(locToUse) && locToUse != "(None Set)")
                            {
                                using (var cmd = new SqlCommand("UPDATE asset SET text6 = @Loc, text16 = @Loc, lastinventoried = SYSDATETIMEOFFSET(), lastmodifiedby = @Emp WHERE id = @Id", con))
                                {
                                    cmd.Parameters.AddWithValue("@Loc", locToUse);
                                    cmd.Parameters.AddWithValue("@Emp", empToUse ?? "");
                                    cmd.Parameters.AddWithValue("@Id", info.Id);
                                    cmd.ExecuteNonQuery();
                                }
                                committed++;
                            }
                        }
                        else
                        {
                            errors++;
                        }
                    }
                }
            }

            ScanList = list;
            Response.Write(string.Format("{{\"success\":true,\"count\":{0},\"errors\":{1}}}", committed, errors));
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Thread abort from CompleteRequest - safe to ignore
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write(string.Format("{{\"success\":false,\"error\":{0}}}", (new System.Web.Script.Serialization.JavaScriptSerializer()).Serialize(ex.Message)));
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }

    public class InventoryOfflineItem
    {
        public string Barcode { get; set; }
        public string Location { get; set; }
        public string CompanyId { get; set; }
        public string EmplId { get; set; }
        public string TagDate { get; set; }
    }
}
