using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Script.Serialization;
using System.Net;
using System.IO;
using System.Text;

public partial class va_tagteam_scan : System.Web.UI.Page
{
    // Simple state object for grid
    [Serializable]
    public class ScanItem
    {
        public string Guid { get; set; } // unique ID for grid row
        public int AssetId { get; set; } // Native integer ID
        public string Location { get; set; }
        public string Barcode { get; set; } // Name
        public string Description { get; set; } // Lookup
        public string TagType { get; set; } // text19
        public string Notes { get; set; } // text20
        public string EmplId { get; set; } // text13
        public bool Tagged { get; set; } // text18 (1/0)
        public string TagDate { get; set; } // text17
        public string LocTagged { get; set; } // text16
        public string DbLocation { get; set; } // text6 (current in DB)
        public string Cmr { get; set; } // text8 (CMR)
        public string SerialNumber { get; set; } // text3 (Serial #)
        public string Status { get; set; } // "Pending", "Saved", "Not Found"
        public string AssetStatus { get; set; } // listvalue1 (e.g. IN USE)
        public bool IsFlagged { get; set; } // True if wrong company
        public bool IsStatusFlagged { get; set; } // True if not IN USE
    }

    private List<ScanItem> ScanList
    {
        get
        {
            // Use 'as' to safely cast. If type version differs (due to recompile), it returns null.
            var list = Session["TagTeam_ScanList"] as List<ScanItem>;
            if (list == null)
            {
                list = new List<ScanItem>();
                Session["TagTeam_ScanList"] = list;
            }
            return list;
        }
        set { Session["TagTeam_ScanList"] = value; }
    }

    private string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    // Curated standard tag types for scanning
    private static readonly List<string> StandardTagTypes = new List<string>
    {
        "IQ350",
        "Large_Metal",
        "Small_Standard",
        "Small_Metal"
    };

    public static string NormalizeTagType(string tagType)
    {
        if (string.IsNullOrWhiteSpace(tagType)) return "";
        string t = tagType.Trim();
        if (string.Equals(t, "IQ350", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "AW_Metal_IQ350", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "Metal_IQ350", StringComparison.OrdinalIgnoreCase))
            return "IQ350";
        if (string.Equals(t, "Large_Metal", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "Metal_Large", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "AW_Large_Metal", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "AW_Metal_Large", StringComparison.OrdinalIgnoreCase))
            return "Large_Metal";
        if (string.Equals(t, "Small_Standard", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "Std_Small", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "AW_Std_Small", StringComparison.OrdinalIgnoreCase))
            return "Small_Standard";
        if (string.Equals(t, "Small_Metal", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(t, "Metal_Small", StringComparison.OrdinalIgnoreCase))
            return "Small_Metal";
        return t;
    }

    public string GetSafeTagType(object tagType)
    {
        string s = NormalizeTagType((tagType ?? "").ToString());
        if (StandardTagTypes.Contains(s)) return s;
        return "";
    }

    private void BindTagTypes()
    {
        // 1. Read directly from Request.Form because browser sends selected value on every postback
        string postVal = Request.Form[DdlDefaultTagType.UniqueID] 
                      ?? Request.Form["DdlDefaultTagType"]
                      ?? Request.Form[DdlDefaultTagType.ClientID];

        string currentVal = !string.IsNullOrEmpty(postVal) 
                            ? postVal 
                            : (string.IsNullOrEmpty(DdlDefaultTagType.SelectedValue) ? (Session["TagTeam_DefaultTagType"] as string) : DdlDefaultTagType.SelectedValue);

        string norm = NormalizeTagType(currentVal);

        DdlDefaultTagType.Items.Clear();
        foreach (string name in StandardTagTypes)
        {
            DdlDefaultTagType.Items.Add(new ListItem(name, name));
        }

        if (!string.IsNullOrEmpty(norm) && DdlDefaultTagType.Items.FindByValue(norm) != null)
        {
            DdlDefaultTagType.SelectedValue = norm;
            Session["TagTeam_DefaultTagType"] = norm;
        }
        else if (DdlDefaultTagType.Items.Count > 0)
        {
            string sessVal = Session["TagTeam_DefaultTagType"] as string;
            if (!string.IsNullOrEmpty(sessVal) && DdlDefaultTagType.Items.FindByValue(sessVal) != null)
                DdlDefaultTagType.SelectedValue = sessVal;
            else
                DdlDefaultTagType.SelectedIndex = 0;
        }
    }

    protected void DdlTagTypeEdit_Init(object sender, EventArgs e)
    {
        var ddl = (DropDownList)sender;
        // "-- None --" is in markup; append standard tag types
        foreach (string name in StandardTagTypes)
        {
            if (ddl.Items.FindByValue(name) == null)
                ddl.Items.Add(new ListItem(name, name));
        }
    }

    private void SafeFocus(System.Web.UI.WebControls.WebControl ctl)
    {
        string ua = (Request.UserAgent ?? "").ToLower();
        if (ua.Contains("mobi") || ua.Contains("android") || ua.Contains("iphone") || ua.Contains("ipad"))
        {
            // Skip focus on mobile devices to prevent screen jump and keyboard thrashing on postback
            return;
        }
        ctl.Focus();
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Request.QueryString["action"] == "sync")
        {
            HandleSyncRequest();
            return;
        }
        if (Request.QueryString["action"] == "print")
        {
            HandlePrintRequest();
            return;
        }

        // Always enforce clean standard tag types on every request and postback
        BindTagTypes();

        if (!IsPostBack)
        {
            // Init
            BindUsers(); // Populate dropdown
            
            // Set default if matches logged in user
            string current = (User != null && User.Identity != null) ? User.Identity.Name : "";
            if (!string.IsNullOrEmpty(current) && DdlEmpl.Items.FindByValue(current) != null)
                DdlEmpl.SelectedValue = current;

            LoadCompanies();
            TxtCurrentDate.Text = DateTime.Now.ToString("yyyy-MM-dd");

            BindGrid();
            SafeFocus(TxtLocationScan);
        }

        // Always inject print scripts on every lifecycle to prevent configuration loss on full postbacks
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
            
            try {
                using (var con = new System.Data.SqlClient.SqlConnection(ConnStr)) {
                    con.Open();
                    using (var cmd = new System.Data.SqlClient.SqlCommand(@"
                        SELECT t.id, 
                               t.name,
                               t.filename,
                               t.companyid,
                               ISNULL(NULLIF(t.usewithservice, ''), p.username) as finalRouting
                        FROM template t
                        LEFT JOIN printclient p ON t.printclientid = p.id
                        ORDER BY t.name", con))
                    using (var r = cmd.ExecuteReader()) {
                        while (r.Read()) {
                            string idStr = Convert.ToInt64(r["id"]).ToString();
                            string name = r["name"].ToString();
                            string filename = r["filename"] == DBNull.Value ? "" : r["filename"].ToString();
                            long companyId = r["companyid"] == DBNull.Value ? 0 : Convert.ToInt64(r["companyid"]);
                            string routing = r["finalRouting"] == DBNull.Value ? "" : r["finalRouting"].ToString();
                            
                            if (!string.IsNullOrEmpty(routing)) 
                                templateRoutes[idStr] = routing;

                            printTemplates.Add(new {
                                id = Convert.ToInt64(r["id"]),
                                name = name,
                                filename = filename,
                                companyId = companyId
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
            } catch { }
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
            LitPrintConfig.Text = jsConfig;

            LitPrintScript.Text = @"
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
                const savedTpl = localStorage.getItem('aw_tagteam_print_tpl');
                if (savedTpl) ddlTpl.value = savedTpl;
                ddlTpl.addEventListener('change', function() { localStorage.setItem('aw_tagteam_print_tpl', this.value); });
            }
            const ddlTgt = document.getElementById('DdlPrintTarget');
            if (ddlTgt && ddlTgt.options.length <= 1 && window.awPrintConfig.availableClients) {
                window.awPrintConfig.availableClients.forEach(c => {
                    ddlTgt.options.add(new Option('Client: ' + c, c));
                });
                const savedTgt = localStorage.getItem('aw_tagteam_print_tgt');
                if (savedTgt) ddlTgt.value = savedTgt;
                ddlTgt.addEventListener('change', function() { localStorage.setItem('aw_tagteam_print_tgt', this.value); });
            }
        } catch (e) {
            console.error('Failed to setup print templates', e);
        }
    }

    function toggleAllPrint(source) {
        const checkboxes = document.querySelectorAll('.chk-print:not([disabled])');
        checkboxes.forEach(cb => {
            cb.checked = source.checked;
        });
        updatePrintBtn();
    }

    document.addEventListener('change', function(e) {
        if(e.target && e.target.classList.contains('chk-print')) {
            updatePrintBtn();
        }
    });

    function updatePrintBtn() {
        const checked = document.querySelectorAll('.chk-print:checked');
        const btn = document.getElementById('BtnPrintChecked');
        const ddlTpl = document.getElementById('DdlPrintTemplate');
        const ddlTgt = document.getElementById('DdlPrintTarget');
        const btnMarkSel = document.getElementById('BtnMarkSelectedTagged');
        const hdnGuids = document.getElementById('HdnMarkedGuids');

        // Always sync selected GUIDs into the hidden field so postback can read them
        if (hdnGuids) {
            hdnGuids.value = Array.from(checked)
                .map(cb => cb.getAttribute('data-guid') || '')
                .filter(g => g)
                .join(',');
        }

        if(btn) {
            if(checked.length > 0) {
                btn.style.display = 'inline-block';
                btn.innerText = 'Server Print (' + checked.length + ')';
                if(ddlTpl) ddlTpl.style.display = 'inline-block';
                if(ddlTgt) ddlTgt.style.display = 'inline-block';
                if(btnMarkSel) {
                    btnMarkSel.style.display = 'inline-block';
                    btnMarkSel.value = '\u2713 Mark Selected (' + checked.length + ') as Tagged';
                }
            } else {
                btn.style.display = 'none';
                if(ddlTpl) ddlTpl.style.display = 'none';
                if(ddlTgt) ddlTgt.style.display = 'none';
                if(btnMarkSel) btnMarkSel.style.display = 'none';
            }
        }
    }

    // Called by OnClientClick of BtnMarkSelectedTagged to ensure GUIDs are flushed before postback
    function syncTagGuids() {
        const checked = document.querySelectorAll('.chk-print:checked');
        const hdnGuids = document.getElementById('HdnMarkedGuids');
        if (hdnGuids) {
            hdnGuids.value = Array.from(checked)
                .map(cb => cb.getAttribute('data-guid') || '')
                .filter(g => g)
                .join(',');
        }
        return true;
    }

    // Smart Tag Type to Print Template matcher (by name, alias, and site)
    window.findTemplateForTag = function(tagType, searchPool, allTemplates) {
        const all = allTemplates || (window.awPrintConfig && window.awPrintConfig.printTemplates) || [];
        const pool = (searchPool && searchPool.length > 0) ? searchPool : all;
        if (!pool || pool.length === 0) return null;
        if (!tagType) return pool[0];

        const raw = (tagType || '').trim();
        const norm = raw.toLowerCase().replace(/[\s\-_]+/g, '');

        // 1. Check print_mapping_config.json
        if (window.awPrintConfig && window.awPrintConfig.templateMappings) {
            const tm = window.awPrintConfig.templateMappings;
            const mapObj = tm[raw] || tm[raw.toLowerCase()] || tm[norm];
            if (mapObj) {
                const mappedId = typeof mapObj === 'object' ? mapObj.TemplateID : parseInt(mapObj, 10);
                const mappedName = all.find(t => t.id === mappedId);
                if (mappedName) {
                    const siteMatch = pool.find(t => t.name === mappedName.name);
                    if (siteMatch) return siteMatch;
                }
                const found = pool.find(t => t.id === mappedId) || all.find(t => t.id === mappedId);
                if (found) return found;
            }
        }

        // 2. Exact match on template name in current site pool (case-insensitive)
        let match = pool.find(t => (t.name || '').toLowerCase() === raw.toLowerCase());
        if (match) return match;

        // 3. Normalized stripped name match (e.g. large_metal vs largemetal)
        match = pool.find(t => (t.name || '').toLowerCase().replace(/[\s\-_]+/g, '') === norm);
        if (match) return match;

        // 4. Tag Team standard name resolution:
        //    a) IQ350 -> AW_Metal_IQ350, Metal_IQ350, IQ350
        //    b) Large_Metal / Metal_Large -> AW_Large_Metal, AW_Metal_Large, Large_Metal, Metal_Large
        //    c) Small_Metal / Small_Standard -> AW_Std_Small, Std_Small, Small_Standard, Small_Metal
        const isIQ350 = norm.includes('iq350');
        const isLargeMetal = (norm.includes('large') && norm.includes('metal')) || norm === 'largemetal' || norm === 'metallarge';
        const isSmall = (norm.includes('small') || norm.includes('std')) && !isLargeMetal && !isIQ350;

        if (isIQ350) {
            match = pool.find(t => {
                const tn = (t.name || '').toLowerCase();
                const fn = (t.filename || '').toLowerCase();
                return tn.includes('iq350') || fn.includes('iq350');
            });
            if (match) return match;
        } else if (isLargeMetal) {
            match = pool.find(t => {
                const tn = (t.name || '').toLowerCase();
                const fn = (t.filename || '').toLowerCase();
                return (tn.includes('large') && tn.includes('metal')) || (fn.includes('large') && fn.includes('metal')) || tn.includes('large');
            });
            if (match) return match;
        } else if (isSmall) {
            match = pool.find(t => {
                const tn = (t.name || '').toLowerCase();
                const fn = (t.filename || '').toLowerCase();
                return (tn.includes('small') || tn.includes('std')) && !tn.includes('large') && !tn.includes('iq350');
            });
            if (match) return match;
        }

        // 5. Broad substring match in pool
        match = pool.find(t => {
            const tn = (t.name || '').toLowerCase().replace(/[\s\-_]+/g, '');
            return tn.includes(norm) || norm.includes(tn);
        });
        if (match) return match;

        // 6. Cross-site search across all templates if pool didn't have it
        if (all.length > 0 && all !== pool) {
            if (isIQ350) match = all.find(t => (t.name || '').toLowerCase().includes('iq350') || (t.filename || '').toLowerCase().includes('iq350'));
            else if (isLargeMetal) match = all.find(t => ((t.name || '').toLowerCase().includes('large') && (t.name || '').toLowerCase().includes('metal')) || (t.name || '').toLowerCase().includes('large'));
            else if (isSmall) match = all.find(t => (t.name || '').toLowerCase().includes('small') || (t.name || '').toLowerCase().includes('std'));
            if (match) return match;
        }

        // 7. Fallback to first available template in pool
        return pool[0] || all[0] || null;
    };

    async function printCheckedTags() {
        const checked = document.querySelectorAll('.chk-print:checked');
        if (checked.length === 0) return;

        const ddlTpl = document.getElementById('DdlPrintTemplate');
        const ddlTgt = document.getElementById('DdlPrintTarget');
        const forceTplId = ddlTpl && ddlTpl.value ? parseInt(ddlTpl.value, 10) : null;
        const forceTgt = ddlTgt && ddlTgt.value ? ddlTgt.value : null;

        // Get the currently selected site companyId for site-aware routing
        const ddlCompany = document.getElementById('DdlCompany');
        const selectedCompanyId = ddlCompany && ddlCompany.value ? parseInt(ddlCompany.value, 10) : 0;
        const allTemplates = window.awPrintConfig.printTemplates || [];
        // Filter templates to the current site; fall back to all if none match
        const siteTemplates = selectedCompanyId > 0
            ? allTemplates.filter(t => t.companyId === selectedCompanyId || t.companyId === 0)
            : allTemplates;
        const searchPool = siteTemplates.length > 0 ? siteTemplates : allTemplates;

        const payload = [];
        checked.forEach(cb => {
            const assetId = parseInt(cb.value, 10);
            const tagType = cb.getAttribute('data-tagtype');
            
            let match = null;
            let targetType = 'Default';
            let targetValue = '';

            if (forceTplId) {
                // Manual override â€” use the exact template selected in dropdown
                match = allTemplates.find(item => item.id === forceTplId);
            } else {
                // Auto-match template by tag type name & site
                match = window.findTemplateForTag(tagType, searchPool, allTemplates);
                
                if (window.awPrintConfig && window.awPrintConfig.templateMappings) {
                    const norm = (tagType || '').trim().toLowerCase().replace(/[\s\-_]+/g, '');
                    const mapObj = window.awPrintConfig.templateMappings[tagType] ||
                                   window.awPrintConfig.templateMappings[(tagType || '').trim()] ||
                                   window.awPrintConfig.templateMappings[norm];
                    if (mapObj && typeof mapObj === 'object') {
                        targetType = mapObj.TargetType || 'Default';
                        targetValue = mapObj.TargetValue || '';
                    }
                }
            }

            if (match && !isNaN(assetId) && assetId > 0) {
                let routingService = window.awPrintConfig.templateRoutes ? window.awPrintConfig.templateRoutes[match.id] : null;
                if (!routingService) routingService = match.useWithService || 'print';

                if (targetType === 'Client' && targetValue.length > 0) routingService = targetValue;
                if (targetType === 'Service' && targetValue.length > 0) routingService = targetValue;
                
                if (forceTgt) {
                    routingService = forceTgt;
                }

                payload.push({
                    recordID: assetId,
                    templateID: match.id,
                    tableName: 'Asset',
                    useWithService: routingService,
                    completed: false
                });
            } else {
                console.warn('Invalid Print Template or Asset ID:', tagType, assetId, match);
            }
        });

        if (payload.length === 0) {
            let parsedIds = Array.from(checked).map(cb => parseInt(cb.value, 10));
            alert('Could not find valid Asset IDs or templates.\nTemplates Loaded: ' + (window.awPrintConfig.printTemplates ? window.awPrintConfig.printTemplates.length : 'NULL') + '\nAsset IDs selected: ' + parsedIds.join(', '));
            return;
        }

        try {
            const btn = document.getElementById('BtnPrintChecked');
            const originalText = btn.innerText;
            btn.innerText = 'Printing...';
            btn.disabled = true;

            const resp = await fetch('va_tagteam_scan.aspx?action=print', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=utf-8'
                },
                body: JSON.stringify(payload)
            });

            if (resp.ok) {
                alert('Sent ' + payload.length + ' tags to print successfully.');
                // uncheck them
                checked.forEach(cb => cb.checked = false);
                const checkAll = document.getElementById('chkAllPrint');
                if(checkAll) checkAll.checked = false;
                updatePrintBtn();
            } else {
                alert('Print API returned an error: ' + resp.status);
            }

            btn.innerText = originalText;
            btn.disabled = false;

        } catch (e) {
            alert('Error calling print service: ' + e.message);
            document.getElementById('BtnPrintChecked').disabled = false;
        }
    }

    async function printSingleTag(assetId, tagType) {
        if (!window.awPrintConfig) {
            console.error('AutoPrint: Missing print config');
            return;
        }
        const allTemplates = window.awPrintConfig.printTemplates || [];
        if (allTemplates.length === 0) {
            console.warn('AutoPrint: No templates available in awPrintConfig');
            return;
        }

        const ddlTpl = document.getElementById('DdlPrintTemplate');
        const ddlTgt = document.getElementById('DdlPrintTarget');
        const forceTplId = ddlTpl && ddlTpl.value ? parseInt(ddlTpl.value, 10) : null;
        const forceTgt = ddlTgt && ddlTgt.value ? ddlTgt.value : null;

        const ddlCompany = document.getElementById('DdlCompany');
        const selectedCompanyId = ddlCompany && ddlCompany.value ? parseInt(ddlCompany.value, 10) : 0;
        const siteTemplates = selectedCompanyId > 0
            ? allTemplates.filter(t => t.companyId === selectedCompanyId || t.companyId === 0)
            : allTemplates;
        const searchPool = siteTemplates.length > 0 ? siteTemplates : allTemplates;

        let match = null;
        let targetType = 'Default';
        let targetValue = '';

        if (forceTplId) {
            match = allTemplates.find(item => item.id === forceTplId);
            console.log('AutoPrint: Using forced template ID:', forceTplId, match);
        } else {
            match = window.findTemplateForTag ? window.findTemplateForTag(tagType, searchPool, allTemplates) : searchPool[0];
            if (window.awPrintConfig && window.awPrintConfig.templateMappings) {
                const norm = (tagType || '').trim().toLowerCase().replace(/[\s\-_]+/g, '');
                const mapObj = window.awPrintConfig.templateMappings[tagType] ||
                               window.awPrintConfig.templateMappings[(tagType || '').trim()] ||
                               window.awPrintConfig.templateMappings[norm];
                if (mapObj && typeof mapObj === 'object') {
                    targetType = mapObj.TargetType || 'Default';
                    targetValue = mapObj.TargetValue || '';
                }
            }
            console.log('AutoPrint: Resolved template for tagType ' + tagType + ' ->', match);
        }

        if (match && !isNaN(assetId) && assetId > 0) {
            let routingService = window.awPrintConfig.templateRoutes ? window.awPrintConfig.templateRoutes[match.id] : null;
            if (!routingService) routingService = match.useWithService || 'print';
            if (targetType === 'Client' && targetValue.length > 0) routingService = targetValue;
            if (targetType === 'Service' && targetValue.length > 0) routingService = targetValue;
            if (forceTgt) routingService = forceTgt;

            const payload = [{
                recordID: assetId,
                templateID: match.id,
                tableName: 'Asset',
                useWithService: routingService,
                completed: false
            }];

            try {
                console.log('AutoPrint: Posting payload for asset ' + assetId + ' to template ' + match.name + ' (ID ' + match.id + ')...');
                const resp = await fetch('va_tagteam_scan.aspx?action=print', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=utf-8' },
                    body: JSON.stringify(payload)
                });
                if (resp.ok) {
                    console.log('Auto-printed asset ' + assetId + ' successfully using template ' + match.name);
                } else {
                    console.error('Print API error: ' + resp.status, await resp.text());
                }
            } catch (e) {
                console.error('Error in auto-print:', e.message);
            }
        } else {
            console.warn('Auto-print skipped: invalid asset or template. AssetID=' + assetId + ', TagType=' + tagType + ', Match=', match);
        }
    }

</script>";
        }
        catch (Exception ex)
        {
            LitPrintConfig.Text = "<!-- Print JS Error: " + ex.Message + "-->";
        }
    }

    private void LoadCompanies()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr)) return;

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                // Use company id as value so we can do proper companyid-based DB lookups
                string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }
            }
            DdlCompany.Items.Insert(0, new ListItem("-- Select Site --", ""));
        }
        catch (Exception ex)
        {
            LitMsg.Text += "<div class='err'>Error loading companies: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    private void BindUsers()
    {
        try
        {
            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                // Pull users from v_sysuser AND any distinct lastmodifiedby from asset table.
                // This ensures scanner accounts like 'TagTeam' that exist in asset data
                // but not in v_sysuser still appear in the dropdown.
                string sql = @"
                    SELECT username FROM (
                        SELECT DISTINCT username FROM v_sysuser WHERE username IS NOT NULL AND username <> ''
                        UNION
                        SELECT DISTINCT lastmodifiedby FROM dbo.asset WITH (NOLOCK)
                            WHERE lastmodifiedby IS NOT NULL AND lastmodifiedby <> ''
                    ) AS AllUsers
                    ORDER BY username";
                using (var cmd = new SqlCommand(sql, con))
                {
                    using (var r = cmd.ExecuteReader())
                    {
                        DdlEmpl.DataSource = r;
                        DdlEmpl.DataTextField = "username";
                        DdlEmpl.DataValueField = "username";
                        DdlEmpl.DataBind();
                    }
                }
            }
            DdlEmpl.Items.Insert(0, new ListItem("-- Select User --", ""));
        }
        catch (Exception ex)
        {
             // Show error to user to debug
             LitMsg.Text += "<div class='err'>Error loading users: " + ex.Message + "</div>";
             DdlEmpl.Items.Add(new ListItem("Admin", "Admin"));
        }
    }

    private int GetSelectedCompanyId()
    {
        string val = DdlCompany.SelectedValue;
        if (string.IsNullOrWhiteSpace(val)) return 0;

        int cid = 0;
        try {
            using (var con = new SqlConnection(ConnStr)) {
                con.Open();
                // Match by either actual ID or by the 3-digit station prefix
                using (var cmd = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE CAST(id AS varchar) = @val OR LEFT(LTRIM(name), 3) = @val", con)) {
                    cmd.Parameters.AddWithValue("@val", val);
                    var res = cmd.ExecuteScalar();
                    if (res != null && res != DBNull.Value) cid = Convert.ToInt32(res);
                }
            }
        } catch { }
        return cid;
    }

    protected void BtnSetLocation_Click(object sender, EventArgs e)
    {
        string loc = TxtLocationScan.Text.Trim().ToUpper();
        if (string.IsNullOrWhiteSpace(loc)) return;

        // --- GUARD: require a user to be selected first ---
        if (string.IsNullOrWhiteSpace(DdlEmpl.SelectedValue))
        {
            LitMsg.Text = "<div class='err'>You must select a Default User before scanning a location!</div>";
            TxtLocationScan.Text = "";
            LblLocationTotal.Style["display"] = "none";
            DdlEmpl.Focus();
            return;
        }

        // --- GUARD: require a site to be selected ---
        if (string.IsNullOrWhiteSpace(DdlCompany.SelectedValue))
        {
            LitMsg.Text = "<div class='err'>You must select a Site before scanning a location!</div>";
            TxtLocationScan.Text = "";
            LblLocationTotal.Style["display"] = "none";
            DdlCompany.Focus();
            return;
        }

        // Force exactly a location barcode, do not accept asset tags
        if (!loc.StartsWith("SP") || loc.Contains("EE")) 
        {
            LitMsg.Text = "<div class='err'>Invalid Location. You MUST barcode scan a valid Location (starts with SP) before scanning!</div>";
            TxtLocationScan.Text = "";
            TxtLocationScan.Focus();
            LblLocationTotal.Style["display"] = "none";
            return;
        }

        // --- GUARD: validate location exists in dbo.location for the selected site companyid ---
        int companyId = GetSelectedCompanyId();
        string siteName = DdlCompany.SelectedItem != null ? DdlCompany.SelectedItem.Text : DdlCompany.SelectedValue;

        try
        {
            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();

                // Check if this location barcode exists at all in the location table for this company
                string checkSql = @"
                    SELECT COUNT(*) FROM dbo.location
                    WHERE UPPER(LTRIM(RTRIM(name))) = @Loc
                      AND companyid = @CompanyId";

                int locExists;
                using (var cmd = new SqlCommand(checkSql, con))
                {
                    cmd.Parameters.AddWithValue("@Loc", loc);
                    cmd.Parameters.AddWithValue("@CompanyId", companyId);
                    locExists = Convert.ToInt32(cmd.ExecuteScalar());
                }

                if (locExists == 0)
                {
                    // Also check if it exists at a DIFFERENT site (to give a better error message)
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
                        "<div class='err'>Invalid Location -- scan rejected! {0} " +
                        "Please scan a valid location barcode for <strong>{1}</strong>, or change the Site Filter.</div>",
                        errDetail, HttpUtility.HtmlEncode(siteName));
                    TxtLocationScan.Text = "";
                    TxtLocationScan.Focus();
                    LblLocationTotal.Style["display"] = "none";
                    return;
                }

                // Location is valid — set it and show asset count
                LblCurrentLocation.Text = loc;
                TxtLocationScan.Text = "";
                LitMsg.Text = ""; // Clear any previous warnings

                using (var cmd3 = new SqlCommand("SELECT COUNT(id) FROM dbo.asset WHERE (text6 = @Loc OR lastobservedlocation = @Loc) AND (companyid = @CompanyId OR @CompanyId = 0)", con))
                {
                    cmd3.Parameters.AddWithValue("@Loc", loc);
                    cmd3.Parameters.AddWithValue("@CompanyId", companyId);
                    int count = Convert.ToInt32(cmd3.ExecuteScalar());
                    LblLocationTotal.Text = count + " Assets Assigned";
                    LblLocationTotal.Style["display"] = "block";
                }
            }
        }
        catch (Exception ex)
        {
            LitMsg.Text = "<div class='err'>Error validating location: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
            TxtLocationScan.Text = "";
            LblLocationTotal.Style["display"] = "none";
            return;
        }
        
        SafeFocus(TxtAssetScan);
    }

    protected void BtnRefreshData_Click(object sender, EventArgs e)
    {
        // Preserve current selections before clearing
        string prevSite = DdlCompany.SelectedValue;
        string prevUser = DdlEmpl.SelectedValue;

        DdlEmpl.Items.Clear();
        DdlCompany.Items.Clear();
        
        BindUsers();
        LoadCompanies();
        
        // Restore previous Site selection if it still exists in the refreshed list
        if (!string.IsNullOrEmpty(prevSite) && DdlCompany.Items.FindByValue(prevSite) != null)
            DdlCompany.SelectedValue = prevSite;

        // Restore previous Operator selection if it still exists in the refreshed list
        if (!string.IsNullOrEmpty(prevUser) && DdlEmpl.Items.FindByValue(prevUser) != null)
            DdlEmpl.SelectedValue = prevUser;
        else
        {
            // Fallback: try Windows identity
            string currentUser = (User != null && User.Identity != null) ? User.Identity.Name : "";
            if (!string.IsNullOrEmpty(currentUser) && DdlEmpl.Items.FindByValue(currentUser) != null)
                DdlEmpl.SelectedValue = currentUser;
        }

        LitMsg.Text = @"<div class='ok'>
            Application data refreshed (Users &amp; Sites updated).<br/>
            <strong id='offlineStatus' style='color:var(--accent);'>Checking offline readiness...</strong>
        </div>
        <script>
        (function() {
            var statusEl = document.getElementById('offlineStatus');
            var readyMsg = 'READY FOR OFFLINE -- You can now safely disconnect. Scans will queue locally and sync when you reconnect.';
            
            // Try to cache the page using the Cache API (requires HTTPS)
            if (typeof caches !== 'undefined' && caches && caches.open) {
                caches.open('idash-scanners-v12').then(function(cache) {
                    return cache.put(
                        new Request('va_tagteam_scan.aspx'),
                        new Response(document.documentElement.outerHTML, {
                            headers: { 'Content-Type': 'text/html' }
                        })
                    );
                }).then(function() {
                    if (statusEl) { statusEl.innerHTML = readyMsg; statusEl.style.color = 'var(--accent-2)'; statusEl.style.fontSize = '15px'; }
                }).catch(function() {
                    // Cache API failed but offline scanning still works via form.submit interception
                    if (statusEl) { statusEl.innerHTML = readyMsg; statusEl.style.color = 'var(--accent-2)'; statusEl.style.fontSize = '15px'; }
                });
            } else {
                // No Cache API (HTTP site) â€” offline scanning still works because we
                // intercept form.submit() and __doPostBack directly in the page JS.
                // The scans queue to localStorage which doesn't require HTTPS.
                if (statusEl) { statusEl.innerHTML = readyMsg; statusEl.style.color = 'var(--accent-2)'; statusEl.style.fontSize = '15px'; }
            }
        })();
        </script>";
    }

    protected void BtnAddAsset_Click(object sender, EventArgs e)
    {
        // Clear previous scan message
        LitMsg.Text = "";

        // --- GUARD: require a user to be selected first ---
        if (string.IsNullOrWhiteSpace(DdlEmpl.SelectedValue))
        {
            LitMsg.Text = "<div class='err'>You must select a Default User before scanning assets!</div>";
            TxtAssetScan.Text = "";
            DdlEmpl.Focus();
            return;
        }

        if (LblCurrentLocation.Text == "(None Set)")
        {
            LitMsg.Text = "<div class='err'>You must scan a Location first before scanning assets!</div>";
            TxtAssetScan.Text = "";
            SafeFocus(TxtLocationScan);
            return;
        }

        string barcode = TxtAssetScan.Text.Trim().ToUpper();
        if (string.IsNullOrWhiteSpace(barcode)) return;

        // --- GUARD: warn if tag date is stale (not today) ---
        DateTime tagDateParsed;
        if (DateTime.TryParse(TxtCurrentDate.Text, out tagDateParsed))
        {
            if (tagDateParsed.Date < DateTime.Today)
            {
                LitMsg.Text = "<div class='err'><strong>Warning:</strong> Tag Date is set to <strong>"
                    + tagDateParsed.ToString("yyyy-MM-dd") + "</strong> which is in the past (today is "
                    + DateTime.Today.ToString("yyyy-MM-dd") + "). The scan was saved with this date. "
                    + "Please update the Tag Date if this was not intentional.</div>";
            }
        }

        // --- BARCODE FORMAT VALIDATION ---
        // Expected format: 3-digit station prefix + space + EE + identifier
        // Reject malformed scans immediately — do NOT save to DB or add to scan list
        if (!System.Text.RegularExpressions.Regex.IsMatch(barcode, @"^\d{3} EE\w+$", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
        {
            LitMsg.Text = "<div class='err'><strong>Invalid barcode format:</strong> \"" 
                + Server.HtmlEncode(barcode) 
                + "\"<br/>Expected format: <strong>3-digit station prefix + space + EE + asset ID</strong> (e.g. \"613 EE123456\" or \"512 EE789012\").<br/>"
                + "Please re-scan or correct the barcode and try again.</div>";
            TxtAssetScan.Text = "";
            SafeFocus(TxtAssetScan);
            return;
        }
        // --- PREFIX-TO-SITE MISMATCH WARNING ---
        // Warn if the 3-digit barcode prefix doesn't match the selected site
        if (DdlCompany.SelectedItem != null && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            string siteName = DdlCompany.SelectedItem.Text;
            string sitePrefix = siteName.Length >= 3 ? siteName.Substring(0, 3) : "";
            string scanPrefix = barcode.Length >= 3 ? barcode.Substring(0, 3) : "";
            int dummy;
            if (int.TryParse(sitePrefix, out dummy) && sitePrefix != scanPrefix)
            {
                LitMsg.Text += "<div class='err'><strong>Prefix Mismatch:</strong> Scanned prefix <strong>\""
                    + Server.HtmlEncode(scanPrefix) + "\"</strong> does not match selected site <strong>\""
                    + Server.HtmlEncode(siteName) + "\"</strong> (expected prefix " + Server.HtmlEncode(sitePrefix) 
                    + "). Verify you are scanning the correct site's assets.</div>";
            }
        }

        // Lookup DB
        var info = LookupAssetInfo(barcode);
        
        string curLoc = LblCurrentLocation.Text;
        if (string.IsNullOrWhiteSpace(curLoc)) curLoc = "SPZZUNKNOWN";

        string notes = TxtDefaultNotes.Text.Trim();
        if (string.IsNullOrWhiteSpace(notes)) notes = "";

        // Flag asset if its companyid doesn't match the selected site
        // We check this via a DB join since companyid is the authoritative link
        int selectedCid = GetSelectedCompanyId();
        bool isFlagged = false;
        if (selectedCid > 0 && info != null && info.Id > 0)
        {
            try
            {
                using (var conFlag = new SqlConnection(ConnStr))
                {
                    conFlag.Open();
                    using (var cmdFlag = new SqlCommand("SELECT COUNT(*) FROM dbo.asset WHERE id = @Id AND companyid = @Cid", conFlag))
                    {
                        cmdFlag.Parameters.AddWithValue("@Id", info.Id);
                        cmdFlag.Parameters.AddWithValue("@Cid", selectedCid);
                        isFlagged = Convert.ToInt32(cmdFlag.ExecuteScalar()) == 0;
                    }
                }
            }
            catch { isFlagged = false; }
        }

        string rawTagType = Request.Form[DdlDefaultTagType.UniqueID] 
                         ?? Request.Form["DdlDefaultTagType"] 
                         ?? DdlDefaultTagType.SelectedValue;
        string resolvedTagType = NormalizeTagType(rawTagType);
        if (string.IsNullOrEmpty(resolvedTagType)) resolvedTagType = DdlDefaultTagType.SelectedValue;
        if (string.IsNullOrEmpty(resolvedTagType)) resolvedTagType = Session["TagTeam_DefaultTagType"] as string;
        if (string.IsNullOrEmpty(resolvedTagType)) resolvedTagType = "IQ350";

        if (DdlDefaultTagType.Items.FindByValue(resolvedTagType) != null)
        {
            DdlDefaultTagType.SelectedValue = resolvedTagType;
            Session["TagTeam_DefaultTagType"] = resolvedTagType;
        }

        var item = new ScanItem
        {
            Guid = Guid.NewGuid().ToString(),
            AssetId = info != null ? info.Id : 0,
            Location = curLoc,
            Barcode = barcode,
            Description = (info != null && info.Description != null) ? info.Description : "(Not Found in DB)",
            DbLocation = (info != null && info.DbLocation != null) ? info.DbLocation : "(New)",
            Cmr = (info != null && info.Cmr != null) ? info.Cmr : "",
            SerialNumber = (info != null && info.SerialNumber != null) ? info.SerialNumber : "",
            TagType = resolvedTagType, 
            Notes = notes,
            EmplId = DdlEmpl.SelectedValue,
            Tagged = (info != null && info.IsTagged),
            TagDate = TxtCurrentDate.Text, 
            LocTagged = curLoc, 
            Status = (info == null) ? "Not Found" : "Pending",
            AssetStatus = (info != null) ? info.AssetStatus : "",
            IsFlagged = isFlagged,
            IsStatusFlagged = (info != null && !string.Equals(info.AssetStatus, "IN USE", StringComparison.OrdinalIgnoreCase))
        };

        // Always save to DB immediately to prevent data loss
        // But skip if "Ignore 78 EIL/CMR" is checked and CMR starts with 78
        bool skip78 = ChkIgnore78Cmr.Checked && !string.IsNullOrEmpty(item.Cmr) && item.Cmr.StartsWith("78");
        string currentUser = DdlEmpl.SelectedValue;
        if (skip78)
        {
            item.Status = "Saved";
            LitMsg.Text += "<div class='ok'>&#128316; Skipped DB update for <strong>" + HttpUtility.HtmlEncode(item.Barcode) + "</strong> &mdash; CMR/EIL starts with 78 (ignored).</div>";
        }
        else
        {
        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();
            string errMsg = SaveScanToDb(item, currentUser, con);
            if (string.IsNullOrEmpty(errMsg)) 
            {
                item.Status = "Saved";
                
                // Still handle auto-print if checked
                if (ChkAutoPrint.Checked && item.AssetId > 0) 
                {
                    string js = string.Format("setTimeout(function() {{ if(typeof printSingleTag === 'function') printSingleTag({0}, '{1}'); }}, 250);", item.AssetId, item.TagType);
                    ClientScript.RegisterStartupScript(GetType(), "AutoPrint_" + Guid.NewGuid().ToString("N"), js, true);
                }
            }
            else
            {
                LitMsg.Text += "<div class='err'>Database Save Failed: " + HttpUtility.HtmlEncode(errMsg) + "</div>";
            }
        }
        }

        var list = ScanList;
        list.RemoveAll(x => string.Equals(x.Barcode, barcode, StringComparison.OrdinalIgnoreCase)); // Dedupe!
        list.Insert(0, item);
        ScanList = list;
        BindGrid();

        TxtAssetScan.Text = "";
        SafeFocus(TxtAssetScan);
    }

    protected void BtnLoadHistory_Click(object sender, EventArgs e)
    {
        string emp = DdlEmpl.SelectedValue; // Use dropdown value
        if (string.IsNullOrWhiteSpace(emp))
        {
            LitMsg.Text = "<div class='err'>Please select a User to load history.</div>";
            LblUserScanTotal.Style["display"] = "none";
            return;
        }

        var history = new List<ScanItem>();
        // Parse date range filter upfront (method-level scope so accessible after using block)
        DateTime dateFrom = DateTime.MinValue, dateTo = DateTime.MinValue;
        bool hasFrom = false, hasTo = false;

        // HTML date inputs send yyyy-MM-dd; parse explicitly
        if (!string.IsNullOrWhiteSpace(TxtDateFrom.Text))
            hasFrom = DateTime.TryParseExact(TxtDateFrom.Text.Trim(), new[] { "yyyy-MM-dd", "MM/dd/yyyy", "M/d/yyyy" },
                System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out dateFrom);
        if (!string.IsNullOrWhiteSpace(TxtDateTo.Text))
            hasTo = DateTime.TryParseExact(TxtDateTo.Text.Trim(), new[] { "yyyy-MM-dd", "MM/dd/yyyy", "M/d/yyyy" },
                System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out dateTo);

        // Single date selected: if only From is set, treat it as a single-day filter
        if (hasFrom && !hasTo)
        {
            hasTo = true;
            dateTo = dateFrom; // Will add +1 day below to cover full day
        }
        // If only To is set, also treat as single-day filter
        if (hasTo && !hasFrom)
        {
            hasFrom = true;
            dateFrom = dateTo;
        }

        // Expand To date to include the full end day (up to midnight of the next day)
        if (hasTo)
        {
            dateTo = dateTo.Date.AddDays(1);
        }
        if (hasFrom)
        {
            dateFrom = dateFrom.Date; // Ensure it starts at midnight
        }

        try
        {
            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                string sql = @"
SELECT TOP 250 
    id, name, description, text19, text20, text13, text18, text17, text16, text6, lastmodifiedby, text8, text3
FROM asset 
WHERE (text13 = @Emp OR lastmodifiedby = @Emp) ";

                int siteId = GetSelectedCompanyId();
                bool hasSite = siteId > 0;
                if (hasSite)
                {
                    sql += " AND companyid = @SiteId ";
                }

                if (ChkUntaggedOnly.Checked)
                {
                    sql = @"
SELECT TOP 250 
    id, name, description, text19, text20, text13, text18, text17, text16, text6, lastmodifiedby, listvalue1, text8, text3
FROM asset 
WHERE (text13 = @Emp OR lastmodifiedby = @Emp) ";
                    if (hasSite) sql += " AND companyid = @SiteId ";
                    sql += " AND (text18 IS NULL OR text18 = '0' OR text18 = 'false' OR text18 = '') ";
                }
                else
                {
                     sql = @"
SELECT TOP 250 
    id, name, description, text19, text20, text13, text18, text17, text16, text6, lastmodifiedby, listvalue1, text8, text3
FROM asset 
WHERE (text13 = @Emp OR lastmodifiedby = @Emp) ";
                    if (hasSite) sql += " AND companyid = @SiteId ";
                }

                // Apply date range filter before ORDER BY
                // Filter on text17 (tagged date) â€” it's a string, so use TRY_CONVERT to safely compare as DATE
                if (hasFrom)
                {
                    sql += " AND TRY_CONVERT(DATE, text17) >= @DateFrom ";
                }
                if (hasTo)
                {
                    sql += " AND TRY_CONVERT(DATE, text17) < @DateTo ";
                }

                sql += " ORDER BY lastinventoried DESC";

                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@Emp", emp);
                    if (hasSite) cmd.Parameters.AddWithValue("@SiteId", siteId);
                    if (hasFrom) cmd.Parameters.AddWithValue("@DateFrom", dateFrom);
                    if (hasTo) cmd.Parameters.AddWithValue("@DateTo", dateTo);
                    
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                                string rawTagDate = r["text17"].ToString();
                                DateTime parsedTagDate;
                                if (DateTime.TryParse(rawTagDate, out parsedTagDate))
                                {
                                    rawTagDate = parsedTagDate.ToString("yyyy-MM-dd");
                                }

                                string rawBarcode = r["name"].ToString();

                                // Skip invalid barcode formats (must be 3 digits + space + identifier)
                                if (!System.Text.RegularExpressions.Regex.IsMatch(rawBarcode, @"^\d{3} \S"))
                                    continue;

                                // IsFlagged is not meaningful in Load History context â€” all loaded records already belong to this user
                                bool isFlagged = false;

                                history.Add(new ScanItem
                                {
                                    Guid = Guid.NewGuid().ToString(),
                                    AssetId = Convert.ToInt32(r["id"]),
                                    Barcode = rawBarcode,
                                    Description = r["description"].ToString(),
                                    TagType = r["text19"].ToString(),
                                    Notes = r["text20"].ToString(),
                                    EmplId = r["lastmodifiedby"].ToString(), // Show who modified it
                                    Tagged = (r["text18"].ToString() == "1" || r["text18"].ToString().ToLower() == "true"),
                                    TagDate = rawTagDate,
                                    LocTagged = r["text16"].ToString(),
                                    DbLocation = r["text6"].ToString(),
                                    Status = "Saved",
                                    AssetStatus = r["listvalue1"].ToString(),
                                    IsFlagged = isFlagged,
                                    IsStatusFlagged = !string.Equals(r["listvalue1"].ToString(), "IN USE", StringComparison.OrdinalIgnoreCase),
                                    Cmr = r["text8"] == DBNull.Value ? "" : r["text8"].ToString(),
                                    SerialNumber = r["text3"] == DBNull.Value ? "" : r["text3"].ToString()
                                });
                        }
                    }
                }
            }
            
            ScanList = history;
            BindGrid();

            string dateRangeMsg = "";
            if (hasFrom || hasTo)
            {
                DateTime displayTo = dateTo.AddDays(-1); // Undo the +1 day for display
                if (dateFrom.Date == displayTo.Date)
                    dateRangeMsg = " (Date: " + dateFrom.ToString("MM/dd/yyyy") + ")";
                else
                    dateRangeMsg = " (Date range: " + dateFrom.ToString("MM/dd/yyyy") + " to " + displayTo.ToString("MM/dd/yyyy") + ")";
            }

            LitMsg.Text = string.Format("<div class='ok'>Loaded {0} recent records for {1}.{2}</div>", history.Count, emp, dateRangeMsg);
            
            LblUserScanTotal.Text = "<span style='color:#10b981; font-weight:bold;'>" + history.Count + "</span> Scans";
            LblUserScanTotal.Style["display"] = "inline-block";
        }
        catch (Exception ex)
        {
            LitMsg.Text = "<div class='err'>Error loading history: " + ex.Message + "</div>";
        }
    }

    public class AssetInfoResult {
        public int Id { get; set; }
        public int CompanyId { get; set; }
        public string Description { get; set; }
        public string DbLocation { get; set; }
        public string AssetStatus { get; set; }
        public bool IsTagged { get; set; }
        public string Cmr { get; set; }
        public string SerialNumber { get; set; }
    }

    private AssetInfoResult LookupAssetInfo(string barcode)
    {
        try
        {
            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                string sql = "SELECT TOP 1 id, companyid, description, text6, text18, listvalue1, text8, text3 FROM asset WHERE name = @Name ORDER BY CASE WHEN companyid > 0 THEN 0 ELSE 1 END, id DESC";
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@Name", barcode);
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            return new AssetInfoResult {
                                Id = Convert.ToInt32(r["id"]),
                                CompanyId = r["companyid"] == DBNull.Value ? 0 : Convert.ToInt32(r["companyid"]),
                                Description = r["description"] == DBNull.Value ? "" : r["description"].ToString(),
                                DbLocation = r["text6"] == DBNull.Value ? "" : r["text6"].ToString(),
                                AssetStatus = r["listvalue1"] == DBNull.Value ? "" : r["listvalue1"].ToString(),
                                IsTagged = (r["text18"] != DBNull.Value && r["text18"].ToString() == "1"),
                                Cmr = r["text8"] == DBNull.Value ? "" : r["text8"].ToString(),
                                SerialNumber = r["text3"] == DBNull.Value ? "" : r["text3"].ToString()
                            };
                        }
                    }
                }
            }
        }
        catch { }
        return null;
    }

    protected void GridScans_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "Remove")
        {
            string guid = e.CommandArgument.ToString();
            var list = ScanList;
            var removed = list.FirstOrDefault(x => x.Guid == guid);

            // Clear the scan fields in the database only if the item was actually scanned/saved
            if (removed != null && removed.AssetId > 0 && removed.Status != "Not Found")
            {
                try
                {
                    using (var con = new SqlConnection(ConnStr))
                    {
                        con.Open();
                        using (var cmd = new SqlCommand(@"
                            UPDATE asset 
                            SET text13 = '', text16 = '', text17 = '', text18 = '', text19 = '', text20 = '',
                                lastmodifiedby = @User
                            WHERE id = @Id", con))
                        {
                            cmd.Parameters.AddWithValue("@Id", removed.AssetId);
                            cmd.Parameters.AddWithValue("@User", DdlEmpl.SelectedValue ?? "TagTeam");
                            cmd.ExecuteNonQuery();
                        }
                    }
                    LitMsg.Text = "<div class='ok'>Removed <strong>" + Server.HtmlEncode(removed.Barcode) + "</strong> and cleared scan data from database.</div>";
                }
                catch (Exception ex)
                {
                    LitMsg.Text = "<div class='err'>Removed from list but failed to clear DB: " + Server.HtmlEncode(ex.Message) + "</div>";
                }
            }

            list.RemoveAll(x => x.Guid == guid);
            ScanList = list;
            BindGrid();
        }
    }

    protected void GridScans_RowEditing(object sender, GridViewEditEventArgs e)
    {
        string guid = GridScans.DataKeys[e.NewEditIndex].Value.ToString();
        var item = ScanList.FirstOrDefault(x => x.Guid == guid);
        if (item != null && string.IsNullOrWhiteSpace(item.TagDate))
        {
            item.TagDate = DateTime.Now.ToString("yyyy-MM-dd");
        }

        GridScans.EditIndex = e.NewEditIndex;
        BindGrid();
    }

    protected void GridScans_RowCancelingEdit(object sender, GridViewCancelEditEventArgs e)
    {
        GridScans.EditIndex = -1;
        BindGrid();
    }

    protected void GridScans_RowUpdating(object sender, GridViewUpdateEventArgs e)
    {
        string guid = GridScans.DataKeys[e.RowIndex].Value.ToString();
        var item = ScanList.FirstOrDefault(x => x.Guid == guid);
        if (item != null)
        {
            var row = GridScans.Rows[e.RowIndex];
            var isTagged = ((CheckBox)row.FindControl("ChkTagged")).Checked;
            var tagDate = ((TextBox)row.FindControl("TxtTagDate")).Text;

            if (isTagged && string.IsNullOrWhiteSpace(tagDate))
            {
                LitMsg.Text = "<div class='err'>Update Failed: Tag Date is required when 'Tagged' is checked.</div>";
                return; // Prevent update and leave in edit mode
            }

            var ddlType = (DropDownList)row.FindControl("DdlTagTypeEdit");
            if (ddlType != null) item.TagType = ddlType.SelectedValue;
            
            var txtDesc = (TextBox)row.FindControl("TxtDescriptionEdit");
            if (txtDesc != null) item.Description = txtDesc.Text;

            var txtBarcode = (TextBox)row.FindControl("TxtBarcodeEdit");
            if (txtBarcode != null && !string.IsNullOrWhiteSpace(txtBarcode.Text))
                item.Barcode = txtBarcode.Text.Trim().ToUpper();
            
            item.Notes = ((TextBox)row.FindControl("TxtNotes")).Text;
            item.LocTagged = ((TextBox)row.FindControl("TxtLocTagged")).Text;
            item.EmplId = ((TextBox)row.FindControl("TxtEmplIdEdit")).Text;
            item.Tagged = isTagged;
            item.TagDate = tagDate;
            
            // Autocommit edit to DB
            string currentUser = DdlEmpl.SelectedValue;
            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                string errMsg = SaveScanToDb(item, currentUser, con, updateInventoryDate: false);
                if (string.IsNullOrEmpty(errMsg))
                {
                    item.Status = "Saved";
                    LitMsg.Text = "<div class='ok'>Changes saved to database.</div>";
                }
                else
                {
                    item.Status = "Error";
                    LitMsg.Text = "<div class='err'>Failed to save edit: " + HttpUtility.HtmlEncode(errMsg) + "</div>";
                }
            }
            
            ScanList = ScanList; 
        }

        GridScans.EditIndex = -1;
        BindGrid();
    }

    protected void BtnCommit_Click(object sender, EventArgs e)
    {
        var pending = ScanList.Where(x => x.Status != "Saved").ToList();
        if (!pending.Any())
        {
            LitMsg.Text = "<div class='ok'>No pending items to save.</div>";
            return;
        }

        // Validate: If NOT Tagged, then LocTagged is required
        var invalid = pending.Where(x => !x.Tagged && string.IsNullOrWhiteSpace(x.LocTagged)).ToList();
        if (invalid.Any())
        {
             string tags = string.Join(", ", invalid.Select(x => x.Barcode));
             LitMsg.Text = string.Format("<div class='err'>Commit Failed: The following untagged assets require Location: {0}</div>", tags);
             return;
        }

        // Validate: If Tagged, TagDate is required
        var missingDate = pending.Where(x => x.Tagged && string.IsNullOrWhiteSpace(x.TagDate)).ToList();
        if (missingDate.Any())
        {
             string tags = string.Join(", ", missingDate.Select(x => x.Barcode));
             LitMsg.Text = string.Format("<div class='err'>Commit Failed: The following tagged assets require a Tag Date: {0}</div>", tags);
             return;
        }


        int count = 0;
        int errs = 0;
        int skipped78 = 0;
        string currentUser = DdlEmpl.SelectedValue; // Use selected user for lastmodifiedby
        var errMsgs = new List<string>();
        bool ignore78 = ChkIgnore78Cmr.Checked;

        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();
            foreach (var item in pending)
            {
                // Skip 78-CMR items when checkbox is checked
                if (ignore78 && !string.IsNullOrEmpty(item.Cmr) && item.Cmr.StartsWith("78"))
                {
                    skipped78++;
                    continue;
                }

                string errMsg = SaveScanToDb(item, currentUser, con);
                if (string.IsNullOrEmpty(errMsg))
                {
                    item.Status = "Saved";
                    count++;
                }
                else
                {
                    errs++;
                    errMsgs.Add(item.Barcode + ": " + errMsg);
                }
            }
        }

        BindGrid();
        string msg78 = skipped78 > 0 ? string.Format(" ({0} items with 78 CMR skipped)", skipped78) : "";
        if (errs > 0)
        {
            string errDetails = string.Join("<br/>", errMsgs);
            LitMsg.Text = string.Format("<div class='err'>Committed {0} items, but {1} failed:{3}<br/>{2}</div>", count, errs, errDetails, msg78);
        }
        else
        {
            LitMsg.Text = string.Format("<div class='ok'>Successfully committed {0} items as user '{1}'.{2}</div>", count, currentUser, msg78);
        }
    }

    private void HandleSyncRequest()
    {
        try
        {
            string json;
            using (var reader = new System.IO.StreamReader(Request.InputStream))
                json = reader.ReadToEnd();

            var js = new JavaScriptSerializer();
            var items = js.Deserialize<List<ScanItem>>(json);
            if (items == null) return;

            var list = ScanList;

            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                foreach (var item in items)
                {
                    if (string.IsNullOrEmpty(item.Guid))
                        item.Guid = Guid.NewGuid().ToString();

                    // --- BARCODE FORMAT VALIDATION ---
                    // Must be: 3-digit station prefix + space + EE + identifier
                    // Examples: 613 EE12345 | 512 EE80938 | 540 EE9999 | 517 EE100
                    // This rejects: scan errors (613 EE80G52), location labels (SP102-519),
                    //               merged barcodes, wrong prefixes (ES/EW), single-E (613 E72190)
                    string bc = (item.Barcode ?? "").Trim().ToUpper();
                    if (!System.Text.RegularExpressions.Regex.IsMatch(bc, @"^\d{3} EE\w+$", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                    {
                        // Invalid format — do NOT save to DB, mark as error so user sees it
                        item.Status = "Error";
                        item.Description = "INVALID FORMAT -- expected 3-digit station prefix + space + EE (e.g. 613 EE...)";
                        list.RemoveAll(x => string.Equals(x.Barcode, bc, StringComparison.OrdinalIgnoreCase));
                        list.Insert(0, item);
                        continue; // skip DB lookup and save entirely
                    }

                    // Lookup existing asset details in DB to load description and check mismatch
                    var info = LookupAssetInfo(item.Barcode);
                    bool isFlagged = false;

                    if (info != null)
                    {
                        item.AssetId = info.Id;
                        item.Description = info.Description;
                        item.DbLocation = info.DbLocation;
                        item.Cmr = info.Cmr;
                        item.SerialNumber = info.SerialNumber;
                        item.AssetStatus = info.AssetStatus;
                        item.IsStatusFlagged = !string.Equals(info.AssetStatus, "IN USE", StringComparison.OrdinalIgnoreCase);

                        // Check if wrong site (isFlagged)
                        if (info.Id > 0 && !string.IsNullOrEmpty(item.Location))
                        {
                            try
                            {
                                int locCompanyId = 0;
                                using (var cmdLoc = new SqlCommand("SELECT TOP 1 companyid FROM dbo.location WHERE UPPER(LTRIM(RTRIM(name))) = @Loc", con))
                                {
                                    cmdLoc.Parameters.AddWithValue("@Loc", item.Location.Trim().ToUpper());
                                    var res = cmdLoc.ExecuteScalar();
                                    if (res != null && res != DBNull.Value)
                                        locCompanyId = Convert.ToInt32(res);
                                }

                                if (locCompanyId > 0)
                                {
                                    isFlagged = (info.CompanyId != locCompanyId);
                                }
                            }
                            catch { }
                        }
                    }
                    else
                    {
                        item.Description = "New Asset Found (Offline Sync)";
                        item.DbLocation = "(New)";
                    }

                    item.IsFlagged = isFlagged;
                    item.Tagged = false; // Default for offline

                    string errMsg = SaveScanToDb(item, item.EmplId, con);
                    if (string.IsNullOrEmpty(errMsg))
                    {
                        item.Status = "Saved";
                    }
                    else
                    {
                        item.Status = "Error";
                    }

                    // Dedupe and prepend to the session list so they are displayed after page reload
                    list.RemoveAll(x => string.Equals(x.Barcode, item.Barcode, StringComparison.OrdinalIgnoreCase));
                    list.Insert(0, item);
                }
            }

            ScanList = list;

            Response.ContentType = "application/json";
            Response.Write("{\"success\":true}");
            Response.Flush();
            Response.SuppressContent = true;
            System.Web.HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write("{\"error\": \"" + ex.Message.Replace("\"", "'") + "\"}");
            Response.Flush();
            Response.SuppressContent = true;
            System.Web.HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }

    private void HandlePrintRequest()
    {
        try
        {
            Request.InputStream.Position = 0;
            string json;
            using (var reader = new System.IO.StreamReader(Request.InputStream))
                json = reader.ReadToEnd();

            var js = new System.Web.Script.Serialization.JavaScriptSerializer();
            var items = js.Deserialize<System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>>(json);

            if (items == null || items.Count == 0) return;

            // Direct BarTender printing â€” no iDash Print Service / MQTT
            // The API handles the full lifecycle: DB insert â†’ build print payload â†’ MQTT publish.
            // Direct DB inserts don't work because the Print Server only processes
            // print commands received via MQTT with full JSON payloads from the core API.
            var errors = new System.Collections.Generic.List<string>();
            int count = PrintApiHelper.PrintJobsDirect(items, out errors);

            Response.ContentType = "application/json";
            if (errors.Count > 0)
                Response.Write("{\"success\":true, \"count\":" + count + ", \"warnings\":\"" + 
                    string.Join("; ", errors).Replace("\"", "'") + "\"}");
            else
                Response.Write("{\"success\":true, \"count\":" + count + "}");
            Response.Flush();
            Response.SuppressContent = true;
            System.Web.HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write("{\"error\": \"" + ex.Message.Replace("\"", "'") + "\"}");
            Response.Flush();
            Response.SuppressContent = true;
            
            AlertingService.SendAdminSms("AWX Print Server API CRASH on TagTeam Scan: " + ex.Message, "Alert_PrintFailure");

            System.Web.HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }

    private string SaveScanToDb(ScanItem item, string user, SqlConnection con, bool updateInventoryDate = true)
    {
        try
        {
            // UPSERT Logic: Try Update, if 0 rows, Insert
            // IMPROVEMENT: text11 = text6 (Previous Location), text6 = new, text16 = new
            // updateInventoryDate: true for scan commits (asset was physically seen),
            //                     false for metadata edits (fixing description, tag type, etc.)
            string sqlUpdate;
            string inventoryClause = updateInventoryDate ? "lastinventoried = SYSDATETIMEOFFSET(), " : "";
            bool useIdLookup = item.AssetId > 0;
            if (useIdLookup)
            {
                sqlUpdate = @"
UPDATE asset 
SET name = @Name, description = ISNULL(NULLIF(@Desc, ''), description), text19 = @TagType, text20 = @Notes, text13 = @EmplId, text18 = @Tagged, 
    text17 = @TagDate, text16 = @LocTagged, text6 = @LocTagged, text11 = text6,
    " + inventoryClause + @"
    lastmodifiedby = @User
OUTPUT INSERTED.id
WHERE id = @Id";
            }
            else
            {
                sqlUpdate = @"
UPDATE asset 
SET description = ISNULL(NULLIF(@Desc, ''), description), text19 = @TagType, text20 = @Notes, text13 = @EmplId, text18 = @Tagged, 
    text17 = @TagDate, text16 = @LocTagged, text6 = @LocTagged, text11 = text6,
    " + inventoryClause + @"
    lastmodifiedby = @User
OUTPUT INSERTED.id
WHERE name = @Name";
            }

            string safeDate = item.TagDate;
            DateTime pd;
            if (DateTime.TryParse(safeDate, out pd))
            {
                safeDate = pd.ToString("MM/dd/yyyy");
            }

            using (var cmd = new SqlCommand(sqlUpdate, con))
            {
                cmd.Parameters.AddWithValue("@Desc", string.IsNullOrWhiteSpace(item.Description) ? "" : item.Description);
                cmd.Parameters.AddWithValue("@TagType", string.IsNullOrWhiteSpace(item.TagType) ? "" : item.TagType);
                cmd.Parameters.AddWithValue("@Notes", string.IsNullOrWhiteSpace(item.Notes) ? "" : item.Notes);
                cmd.Parameters.AddWithValue("@EmplId", string.IsNullOrWhiteSpace(item.EmplId) ? "" : item.EmplId);
                cmd.Parameters.AddWithValue("@Tagged", item.Tagged ? "1" : "");
                cmd.Parameters.AddWithValue("@TagDate", string.IsNullOrWhiteSpace(safeDate) ? "" : safeDate);
                cmd.Parameters.AddWithValue("@LocTagged", string.IsNullOrWhiteSpace(item.LocTagged) ? "" : item.LocTagged);
                cmd.Parameters.AddWithValue("@User", string.IsNullOrWhiteSpace(user) ? "TagTeam" : user);
                cmd.Parameters.AddWithValue("@Name", item.Barcode);
                if (useIdLookup)
                    cmd.Parameters.AddWithValue("@Id", item.AssetId);

                object res = cmd.ExecuteScalar();
                if (res != null) {
                    item.AssetId = Convert.ToInt32(res);
                    return null; // Success
                }
            }

            // Resolve companyid from scanned location to satisfy NOT NULL DB constraint
            int companyId = 0;
            try
            {
                string locForCid = !string.IsNullOrEmpty(item.LocTagged) ? item.LocTagged : item.Location;
                if (!string.IsNullOrEmpty(locForCid))
                {
                    using (var cmdC = new SqlCommand("SELECT TOP 1 companyid FROM dbo.location WHERE UPPER(LTRIM(RTRIM(name))) = @Loc", con))
                    {
                        cmdC.Parameters.AddWithValue("@Loc", locForCid.Trim().ToUpper());
                        var res = cmdC.ExecuteScalar();
                        if (res != null && res != DBNull.Value)
                            companyId = Convert.ToInt32(res);
                    }
                }
            }
            catch { }

            // If location didn't resolve companyid, resolve from the barcode station prefix (e.g. 613, 512, 540, 517, 581)
            if (companyId <= 0 && !string.IsNullOrEmpty(item.Barcode) && item.Barcode.Length >= 3)
            {
                try
                {
                    string pfx = item.Barcode.Substring(0, 3);
                    using (var cmdPfx = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE name LIKE @Pfx + '%'", con))
                    {
                        cmdPfx.Parameters.AddWithValue("@Pfx", pfx);
                        var resPfx = cmdPfx.ExecuteScalar();
                        if (resPfx != null && resPfx != DBNull.Value)
                            companyId = Convert.ToInt32(resPfx);
                    }
                }
                catch { }
            }
            if (companyId <= 0) companyId = 7; // Default to Martinsburg if all else fails

            // If we reach here, UPDATE did not match (asset not in DB).
            // --- SAFETY CHECK: Does a record with this name already exist under ANY companyid?
            // This happens when:
            //   (a) A prior offline sync created a stub with a different companyid, OR
            //   (b) The VistA import enriched the record but companyid changed
            // In either case: UPDATE the existing record rather than creating a duplicate.
            try
            {
                string sqlExistsByName = @"
UPDATE TOP (1) asset
SET text19 = @TagType, text20 = @Notes, text13 = @EmplId,
    text17 = @TagDate, text16 = @LocTagged, text6 = @LocTagged,
    lastinventoried = SYSDATETIMEOFFSET(), lastmodifiedby = @User
OUTPUT INSERTED.id
WHERE name = @Name";
                using (var cmdCheck = new SqlCommand(sqlExistsByName, con))
                {
                    cmdCheck.Parameters.AddWithValue("@Name", item.Barcode);
                    cmdCheck.Parameters.AddWithValue("@TagType", string.IsNullOrWhiteSpace(item.TagType) ? "" : item.TagType);
                    cmdCheck.Parameters.AddWithValue("@Notes", string.IsNullOrWhiteSpace(item.Notes) ? "" : item.Notes);
                    cmdCheck.Parameters.AddWithValue("@EmplId", string.IsNullOrWhiteSpace(item.EmplId) ? "" : item.EmplId);
                    cmdCheck.Parameters.AddWithValue("@TagDate", string.IsNullOrWhiteSpace(safeDate) ? "" : safeDate);
                    cmdCheck.Parameters.AddWithValue("@LocTagged", string.IsNullOrWhiteSpace(item.LocTagged) ? "" : item.LocTagged);
                    cmdCheck.Parameters.AddWithValue("@User", string.IsNullOrWhiteSpace(user) ? "TagTeam" : user);

                    object existsRes = cmdCheck.ExecuteScalar();
                    if (existsRes != null)
                    {
                        item.AssetId = Convert.ToInt32(existsRes);
                        return null; // Updated existing record â€” no duplicate created
                    }
                }
            }
            catch { }

            // Truly new asset â€” resolve companyid from scanned location
            string sqlInsert = @"
INSERT INTO asset (name, description, companyid, text19, text20, text13, text18, text17, text16, text6, lastinventoried, lastmodifiedby)
OUTPUT INSERTED.id
VALUES (@Name, @Desc, @CompanyId, @TagType, @Notes, @EmplId, @Tagged, @TagDate, @LocTagged, @LocTagged, SYSDATETIMEOFFSET(), @User)";

            using (var cmd = new SqlCommand(sqlInsert, con))
            {
                cmd.Parameters.AddWithValue("@Name", item.Barcode);
                cmd.Parameters.AddWithValue("@Desc", string.IsNullOrWhiteSpace(item.Description) ? "New Asset Found (Offline Sync)" : item.Description);
                cmd.Parameters.AddWithValue("@CompanyId", companyId);
                cmd.Parameters.AddWithValue("@TagType", string.IsNullOrWhiteSpace(item.TagType) ? "" : item.TagType);
                cmd.Parameters.AddWithValue("@Notes", string.IsNullOrWhiteSpace(item.Notes) ? "" : item.Notes);
                cmd.Parameters.AddWithValue("@EmplId", string.IsNullOrWhiteSpace(item.EmplId) ? "" : item.EmplId);
                cmd.Parameters.AddWithValue("@Tagged", item.Tagged ? "1" : "");
                cmd.Parameters.AddWithValue("@TagDate", string.IsNullOrWhiteSpace(safeDate) ? "" : safeDate);
                cmd.Parameters.AddWithValue("@LocTagged", string.IsNullOrWhiteSpace(item.LocTagged) ? "" : item.LocTagged);
                cmd.Parameters.AddWithValue("@User", string.IsNullOrWhiteSpace(user) ? "TagTeam" : user);

                object res = cmd.ExecuteScalar();
                if (res != null) {
                    item.AssetId = Convert.ToInt32(res);
                    return null; // Success
                }
                return "Failed to insert record.";
            }
        }
        catch (Exception ex)
        { 
            return ex.Message; 
        }
    }

    protected void BtnClear_Click(object sender, EventArgs e)
    {
        ScanList = new List<ScanItem>();
        BindGrid();
        LitMsg.Text = "";
    }

    protected void BtnPreviewEnnx_Click(object sender, EventArgs e)
    {
        bool ignore78 = ChkIgnore78Cmr.Checked;

        // Exclude flagged items, no-data items, and optionally 78-CMR items from ENNX
        var validItems = ScanList.Where(x => !x.IsFlagged 
            && !IsNoDataAsset(x)
            && !(ignore78 && !string.IsNullOrEmpty(x.Cmr) && x.Cmr.StartsWith("78"))
        ).ToList(); 
        if (!validItems.Any())
        {
            TxtPreview.Text = "No valid items to preview.";
            return;
        }

        // Dedupe valid items by Barcode, keeping the most recent scan (which appears earliest in ScanList)
        var dedupedItems = validItems
            .GroupBy(x => x.Barcode, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First())
            .ToList();

        // Generate ENNX file format - Group logically by Location matching va_ennx behavior
        var groups = dedupedItems
            .GroupBy(x => string.IsNullOrWhiteSpace(x.LocTagged) ? "UNKNOWN" : x.LocTagged, StringComparer.OrdinalIgnoreCase)
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

        // Count excluded items for info
        int excluded78 = ignore78 ? ScanList.Count(x => !x.IsFlagged && !string.IsNullOrEmpty(x.Cmr) && x.Cmr.StartsWith("78")) : 0;
        int excludedNoData = ScanList.Count(x => !x.IsFlagged && IsNoDataAsset(x));
        string excludeMsg = "";
        if (excluded78 > 0 || excludedNoData > 0)
        {
            var parts = new List<string>();
            if (excluded78 > 0) parts.Add(excluded78 + " with 78 CMR");
            if (excludedNoData > 0) parts.Add(excludedNoData + " with no DB data");
            excludeMsg = "\n\n--- Excluded: " + string.Join(", ", parts) + " ---";
        }

        TxtPreview.Text = sb.ToString() + excludeMsg;
    }

    /// <summary>
    /// Returns true if this scan item represents an asset not found in the database.
    /// </summary>
    private bool IsNoDataAsset(ScanItem item)
    {
        if (item.AssetId == 0) return true;
        if (item.Status == "Not Found") return true;
        string desc = (item.Description ?? "").Trim();
        return desc == "(Not Found in DB)" || desc == "New Asset Found (Offline Sync)";
    }

    protected void BtnShowNoData_Click(object sender, EventArgs e)
    {
        var noDataItems = ScanList.Where(x => IsNoDataAsset(x)).ToList();

        if (!noDataItems.Any())
        {
            TxtNoDataPreview.Text = "No 'No Data' assets found in the current scan list.";
        }
        else
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("=== NO DATA ASSETS (" + noDataItems.Count + ") ===");
            sb.AppendLine("These assets were not found in the database and are excluded from ENNX.");
            sb.AppendLine();
            foreach (var item in noDataItems)
            {
                sb.AppendLine(string.Format("{0}  --  {1}  |  Loc: {2}  |  Scanned: {3}",
                    item.Barcode, 
                    item.Description,
                    string.IsNullOrWhiteSpace(item.LocTagged) ? "(none)" : item.LocTagged,
                    string.IsNullOrWhiteSpace(item.TagDate) ? "(no date)" : item.TagDate));
            }
            TxtNoDataPreview.Text = sb.ToString();
        }

        // Show the no-data preview textbox
        TxtNoDataPreview.Style["display"] = "block";
    }

    protected void BtnShowOit_Click(object sender, EventArgs e)
    {
        // OIT = assets with CMR/EIL (text8) starting with "78"
        var oitItems = ScanList.Where(x => !string.IsNullOrEmpty(x.Cmr) && x.Cmr.StartsWith("78")).ToList();

        if (!oitItems.Any())
        {
            TxtOitPreview.Text = "No OIT (Office of Information Technology) assets found in the current scan list.";
        }
        else
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("=== OIT ASSETS SCANNED (" + oitItems.Count + ") ===");
            sb.AppendLine("These assets belong to the VA Office of Information Technology (CMR starts with 78). We do not tag OIT equipment; this report tracks scanned OIT assets for notification.");
            sb.AppendLine();
            foreach (var item in oitItems)
            {
                sb.AppendLine(string.Format("{0}  --  {1}  |  Loc: {2}  |  CMR: {3}  |  Scanned: {4}",
                    item.Barcode,
                    string.IsNullOrWhiteSpace(item.Description) ? "(no description)" : item.Description,
                    string.IsNullOrWhiteSpace(item.LocTagged) ? "(none)" : item.LocTagged,
                    string.IsNullOrWhiteSpace(item.Cmr) ? "(none)" : item.Cmr,
                    string.IsNullOrWhiteSpace(item.TagDate) ? "(no date)" : item.TagDate));
            }
            TxtOitPreview.Text = sb.ToString();
        }

        // Show the OIT preview textbox
        TxtOitPreview.Style["display"] = "block";
    }

    protected void ChkShowFlagged_CheckedChanged(object sender, EventArgs e)
    {
        BindGrid();
    }

    protected void GridScans_Sorting(object sender, GridViewSortEventArgs e)
    {
        string sortExp = e.SortExpression;
        string dir = "ASC";
        if (ViewState["SortExp"] != null && ViewState["SortExp"].ToString() == sortExp)
        {
            dir = ViewState["SortDir"] != null && ViewState["SortDir"].ToString() == "ASC" ? "DESC" : "ASC";
        }
        ViewState["SortExp"] = sortExp;
        ViewState["SortDir"] = dir;

        BindGrid();
    }

    private void BindGrid()
    {
        var dataSource = (IEnumerable<ScanItem>)ScanList;
        if (!ChkShowFlagged.Checked)
        {
            dataSource = dataSource.Where(x => !x.IsFlagged);
        }

        if (ViewState["SortExp"] != null)
        {
            string exp = ViewState["SortExp"].ToString();
            string dir = ViewState["SortDir"] != null ? ViewState["SortDir"].ToString() : "ASC";

            if (dir == "ASC")
            {
                dataSource = dataSource.OrderBy(x => GetPropertyValue(x, exp));
            }
            else
            {
                dataSource = dataSource.OrderByDescending(x => GetPropertyValue(x, exp));
            }
        }
        
        GridScans.DataSource = dataSource.ToList();
        GridScans.DataBind();
    }

    private object GetPropertyValue(object obj, string propertyName)
    {
        var prop = obj.GetType().GetProperty(propertyName);
        if (prop != null)
        {
            var val = prop.GetValue(obj, null);
            return val != null ? val : "";
        }
        return "";
    }
    protected void BtnMarkSelectedTagged_Click(object sender, EventArgs e)
    {
        string raw = HdnMarkedGuids.Value.Trim();
        if (string.IsNullOrEmpty(raw)) return;

        var guids = new HashSet<string>(raw.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries));
        var list = ScanList;
        string currentUser = DdlEmpl.SelectedValue;
        string today = DateTime.Today.ToString("yyyy-MM-dd");
        int count = 0;
        int errCount = 0;
        int skipped78 = 0;
        bool ignore78 = ChkIgnore78Cmr.Checked;
        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();
            foreach (var item in list)
            {
                if (guids.Contains(item.Guid))
                {
                    // Skip 78-CMR items when checkbox is checked
                    if (ignore78 && !string.IsNullOrEmpty(item.Cmr) && item.Cmr.StartsWith("78"))
                    {
                        skipped78++;
                        continue;
                    }

                    item.Tagged = true;
                    if (string.IsNullOrWhiteSpace(item.TagDate))
                        item.TagDate = today;

                    string errMsg = SaveScanToDb(item, currentUser, con);
                    if (string.IsNullOrEmpty(errMsg))
                    {
                        item.Status = "Saved";
                        count++;
                    }
                    else
                    {
                        item.Status = "Error";
                        errCount++;
                    }
                }
            }
        }

        ScanList = list;
        HdnMarkedGuids.Value = "";
        BindGrid();
        
        string msg78 = skipped78 > 0 ? string.Format(" ({0} items with 78 CMR skipped)", skipped78) : "";
        if (errCount > 0)
            LitMsg.Text = string.Format("<div class='err'>Marked {0} items as Tagged, but {1} failed to save to database.{2}</div>", count, errCount, msg78);
        else
            LitMsg.Text = string.Format("<div class='ok'>Marked and saved {0} item(s) as Tagged.{1}</div>", count, msg78);
            
        SafeFocus(TxtAssetScan);
    }

    protected void BtnMarkAllTagged_Click(object sender, EventArgs e)
    {
        var list = ScanList;
        string currentUser = DdlEmpl.SelectedValue;
        string today = DateTime.Today.ToString("yyyy-MM-dd");
        int count = 0;
        int errCount = 0;
        int skipped78 = 0;
        bool ignore78 = ChkIgnore78Cmr.Checked;
        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();
            foreach (var item in list)
            {
                // Skip 78-CMR items when checkbox is checked
                if (ignore78 && !string.IsNullOrEmpty(item.Cmr) && item.Cmr.StartsWith("78"))
                {
                    skipped78++;
                    continue;
                }

                item.Tagged = true;
                if (string.IsNullOrWhiteSpace(item.TagDate))
                    item.TagDate = today;

                string errMsg = SaveScanToDb(item, currentUser, con);
                if (string.IsNullOrEmpty(errMsg))
                {
                    item.Status = "Saved";
                    count++;
                }
                else
                {
                    item.Status = "Error";
                    errCount++;
                }
            }
        }

        ScanList = list;
        BindGrid();
        
        string msg78 = skipped78 > 0 ? string.Format(" ({0} items with 78 CMR skipped)", skipped78) : "";
        if (errCount > 0)
            LitMsg.Text = string.Format("<div class='err'>Marked {0} items as Tagged, but {1} failed to save to database.{2}</div>", count, errCount, msg78);
        else
            LitMsg.Text = string.Format("<div class='ok'>Marked and saved all {0} item(s) as Tagged.{1}</div>", count, msg78);
            
        SafeFocus(TxtAssetScan);
    }

}
