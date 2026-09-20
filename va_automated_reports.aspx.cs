using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.Script.Serialization;
using System.Configuration;
using System.Web.Configuration;
using System.Web.UI;

public partial class va_automated_reports : Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            LoadConfig();
            LoadSiteConfig();
        }
    }

    private void LoadConfig()
    {
        try
        {
            var config = WebConfigurationManager.OpenWebConfiguration("~");
            var settings = config.AppSettings.Settings;

            // 1. Master Switch
            if (settings["SmsAlertsEnabled"] != null)
                CbMasterSwitch.Checked = settings["SmsAlertsEnabled"].Value.ToLower() == "true";
            else
                CbMasterSwitch.Checked = false; // Default off if radically missing

            // 2. Recipients
            if (settings["SmsRecipients"] != null)
            {
                var raw = settings["SmsRecipients"].Value;
                var lines = raw.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries)
                               .Select(x => x.Trim());
                TxtRecipients.Text = string.Join("\n", lines);
            }

            // 3. Triggers
            CbAlertDbFolderMissing.Checked = IsTriggerEnabled(settings, "Alert_DbFolderMissing");
            CbAlertDbCrash.Checked = IsTriggerEnabled(settings, "Alert_DbCrash");
            CbAlertPrintFailure.Checked = IsTriggerEnabled(settings, "Alert_PrintFailure");
            CbAlertTagAuditReport.Checked = IsTriggerEnabled(settings, "Alert_TagAuditReport");

            // 5. Automated Reports
            CbReportEnnx.Checked = IsTriggerEnabled(settings, "Report_Ennx");
            CbReportStats.Checked = IsTriggerEnabled(settings, "Report_Stats");

            // 6. Email Presentation Formatting
            TxtEmailFromAddress.Text = settings["SMTP_FromEmail"] != null ? settings["SMTP_FromEmail"].Value : "no-reply@idash.local";

            // ENNX Subject Template (from report_automation.json, not web.config)
            string ennxSubject = LoadEnnxSubjectTemplate();
            TxtEnnxSubject.Text   = ennxSubject;
            LitSubjectPreview.Text = Server.HtmlEncode(
                ennxSubject.Replace("{Site}", "613").Replace("{Date}", DateTime.Today.ToString("MM-dd-yyyy")));

            // 7. SMTP Server Settings
            TxtSmtpHost.Text = settings["SMTP_Host"] != null ? settings["SMTP_Host"].Value : "localhost";
            TxtSmtpPort.Text = settings["SMTP_Port"] != null ? settings["SMTP_Port"].Value : "25";
            TxtSmtpUser.Text = settings["SMTP_User"] != null ? settings["SMTP_User"].Value : "";
            // Password: never round-trip a stored password into a form field — show blank always
            TxtSmtpPassword.Text = "";
            CbSmtpSsl.Checked = settings["SMTP_SSL"] != null && settings["SMTP_SSL"].Value.ToLower() == "true";

            // 4. Custom Routing
            TxtRec_DbFolderMissing.Text = GetTriggerRecipients(settings, "Alert_DbFolderMissing");
            TxtRec_DbCrash.Text = GetTriggerRecipients(settings, "Alert_DbCrash");
            TxtRec_PrintFailure.Text = GetTriggerRecipients(settings, "Alert_PrintFailure");
            TxtRec_TagAuditReport.Text = GetTriggerRecipients(settings, "Alert_TagAuditReport");
            TxtRec_ReportEnnx.Text = GetTriggerRecipients(settings, "Report_Ennx");
            TxtRec_ReportStats.Text = GetTriggerRecipients(settings, "Report_Stats");
        }
        catch (Exception ex)
        {
            LitStatus.Text = "<div class='err'><strong>Error Loading Config:</strong> " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    private bool IsTriggerEnabled(KeyValueConfigurationCollection settings, string key)
    {
        if (settings[key] == null) return false;
        return settings[key].Value.ToLower() == "true";
    }

    private string GetTriggerRecipients(KeyValueConfigurationCollection settings, string key)
    {
        string fullKey = "SmsRecipients_" + key;
        if (settings[fullKey] != null && !string.IsNullOrWhiteSpace(settings[fullKey].Value))
        {
            var raw = settings[fullKey].Value;
            var lines = raw.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries).Select(x => x.Trim());
            return string.Join("; ", lines);
        }
        return "";
    }

    protected void BtnSave_Click(object sender, EventArgs e)
    {
        try
        {
            var config = WebConfigurationManager.OpenWebConfiguration("~");
            var settings = config.AppSettings.Settings;

            // 1. Save Master System Switch
            UpdateKey(settings, "SmsAlertsEnabled", CbMasterSwitch.Checked ? "true" : "false");

            // 2. Save Recipients strictly recombining lines back to semicolon-separated array
            var cleanedLines = TxtRecipients.Text
                .Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(x => x.Trim())
                .Where(x => !string.IsNullOrEmpty(x));
                
            string serializedRecipients = string.Join(";", cleanedLines);
            UpdateKey(settings, "SmsRecipients", serializedRecipients);

            // 3. Save Deep Triggers 
            UpdateKey(settings, "Alert_DbFolderMissing", CbAlertDbFolderMissing.Checked ? "true" : "false");
            UpdateKey(settings, "Alert_DbCrash", CbAlertDbCrash.Checked ? "true" : "false");
            UpdateKey(settings, "Alert_PrintFailure", CbAlertPrintFailure.Checked ? "true" : "false");
            UpdateKey(settings, "Alert_TagAuditReport", CbAlertTagAuditReport.Checked ? "true" : "false");

            UpdateKey(settings, "Report_Ennx", CbReportEnnx.Checked ? "true" : "false");
            UpdateKey(settings, "Report_Stats", CbReportStats.Checked ? "true" : "false");

            // Save Email Formatting Settings
            UpdateKey(settings, "SMTP_FromEmail", TxtEmailFromAddress.Text.Trim());

            // Save ENNX Subject Template to report_automation.json
            SaveEnnxSubjectTemplate(TxtEnnxSubject.Text.Trim());

            // Save SMTP Server Settings
            UpdateKey(settings, "SMTP_Host", TxtSmtpHost.Text.Trim());
            UpdateKey(settings, "SMTP_Port", TxtSmtpPort.Text.Trim());
            UpdateKey(settings, "SMTP_User", TxtSmtpUser.Text.Trim());
            UpdateKey(settings, "SMTP_SSL", CbSmtpSsl.Checked ? "true" : "false");
            // Only save password when the user typed a new one — blank = keep existing
            string newPass = TxtSmtpPassword.Text;
            if (!string.IsNullOrEmpty(newPass))
                UpdateKey(settings, "SMTP_Password", newPass);

            // 4. Save Custom Routings
            SaveTriggerRecipients(settings, "Alert_DbFolderMissing", TxtRec_DbFolderMissing.Text);
            SaveTriggerRecipients(settings, "Alert_DbCrash", TxtRec_DbCrash.Text);
            SaveTriggerRecipients(settings, "Alert_PrintFailure", TxtRec_PrintFailure.Text);
            SaveTriggerRecipients(settings, "Alert_TagAuditReport", TxtRec_TagAuditReport.Text);
            SaveTriggerRecipients(settings, "Report_Ennx", TxtRec_ReportEnnx.Text);
            SaveTriggerRecipients(settings, "Report_Stats", TxtRec_ReportStats.Text);

            config.Save();

            LitStatus.Text = "<div class='ok'><strong>Configuration Saved!</strong> Your alert trigger mappings have been updated natively into the system seamlessly.</div>";
        }
        catch (Exception ex)
        {
            LitStatus.Text = "<div class='err'><strong>Error Saving Config:</strong> " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    private void UpdateKey(KeyValueConfigurationCollection settings, string key, string value)
    {
        if (settings[key] == null)
            settings.Add(key, value);
        else
            settings[key].Value = value;
    }

    private void SaveTriggerRecipients(KeyValueConfigurationCollection settings, string key, string rawInput)
    {
        string fullKey = "SmsRecipients_" + key;
        if (string.IsNullOrWhiteSpace(rawInput))
        {
            UpdateKey(settings, fullKey, "");
            return;
        }
        var cleaned = rawInput.Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries)
                              .Select(x => x.Trim())
                              .Where(x => !string.IsNullOrEmpty(x));
        string serialized = string.Join(";", cleaned);
        UpdateKey(settings, fullKey, serialized);
    }

    private const string DEFAULT_ENNX_SUBJECT = "iDash ENNX Report | Site {Site} | {Date}";

    private string LoadEnnxSubjectTemplate()
    {
        try
        {
            string path = Server.MapPath("~/config/report_automation.json");
            if (!File.Exists(path)) return DEFAULT_ENNX_SUBJECT;
            var raw  = File.ReadAllText(path);
            var dict = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(raw);
            if (dict.ContainsKey("SubjectTitle") && dict["SubjectTitle"] != null)
                return dict["SubjectTitle"].ToString();
        }
        catch { }
        return DEFAULT_ENNX_SUBJECT;
    }

    private void SaveEnnxSubjectTemplate(string subjectTemplate)
    {
        if (string.IsNullOrWhiteSpace(subjectTemplate))
            subjectTemplate = DEFAULT_ENNX_SUBJECT;

        string path = Server.MapPath("~/config/report_automation.json");
        var js   = new JavaScriptSerializer();
        Dictionary<string, object> dict;

        if (File.Exists(path))
            dict = js.Deserialize<Dictionary<string, object>>(File.ReadAllText(path));
        else
            dict = new Dictionary<string, object>();

        dict["SubjectTitle"] = subjectTemplate;
        File.WriteAllText(path, js.Serialize(dict));
    }

    // ── Section 6: Per-Site Email Routing ──────────────────────────────────

    // Company row from DB
    private class CompanySite
    {
        public int    Id   { get; set; }
        public string Name { get; set; }  // e.g. "613 Martinsburg"

        // Extract the station number prefix (everything before the first space)
        public string StationKey
        {
            get
            {
                if (string.IsNullOrWhiteSpace(Name)) return Id.ToString();
                var parts = Name.Trim().Split(' ');
                return parts[0].Trim();
            }
        }
    }

    private void LoadSiteConfig()
    {
        try
        {
            var siteConfig    = SiteEmailConfigHelper.Load();
            var companySites  = GetCompanySites();

            if (companySites.Count == 0)
            {
                LitSiteConfig.Text = "<p style='color:var(--muted);font-size:13px;'>" +
                    "No sites found in the company table. Add sites in the iDash admin.</p>";
                return;
            }

            var sb = new StringBuilder();
            sb.Append("<div style='display:grid;gap:14px;'>");

            foreach (var company in companySites)
            {
                string key = company.StationKey;
                SiteEmailConfigHelper.SiteEmailEntry entry;
                siteConfig.TryGetValue(key, out entry);

                bool   enabled    = entry != null ? entry.Enabled : true;
                string dispName   = entry != null && !string.IsNullOrEmpty(entry.DisplayName)
                    ? Server.HtmlEncode(entry.DisplayName)
                    : Server.HtmlEncode(company.Name);
                string recipients = entry != null && entry.Recipients != null
                    ? Server.HtmlEncode(string.Join("; ", entry.Recipients))
                    : "";
                bool   hasSiteRcpt = entry != null && entry.Recipients != null && entry.Recipients.Count > 0;

                string enabledBg    = enabled ? "#10b981" : "#ef4444";
                string enabledLabel = enabled ? "&#10003; Enabled" : "&#10007; Disabled";
                string cardOpacity  = enabled ? "" : "opacity:0.55;";
                string checkedAttr  = enabled ? "checked" : "";

                sb.AppendFormat(
                    "<div style='background:var(--chip);border:1px solid var(--line);border-radius:12px;" +
                    "padding:16px 20px;{7}'>" +
                    // Header row
                    "<div style='display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;'>" +
                    "<div><strong style='font-size:15px;'>{0}</strong>" +
                    " <span style='font-size:12px;color:var(--muted);margin-left:8px;'>Station {1}</span></div>" +
                    // Toggle switch area
                    "<label style='display:flex;align-items:center;gap:8px;cursor:pointer;user-select:none;'>" +
                    "<span style='font-size:12px;color:var(--muted);'>Alerts/Email</span>" +
                    "<input type='hidden' name='site_enabled_{1}' value='0' />" +
                    "<input type='checkbox' name='site_enabled_{1}' value='1' {5}" +
                    "  onchange=\"this.closest('div[data-site]').querySelector('.site-badge').style.background=this.checked?'#10b981':'#ef4444';" +
                    "  this.closest('div[data-site]').querySelector('.site-badge').textContent=this.checked?'\\u2713 Enabled':'\\u2717 Disabled';" +
                    "  this.closest('div[data-site]').style.opacity=this.checked?'1':'0.55';\"" +
                    "  style='width:18px;height:18px;accent-color:#10b981;cursor:pointer;' />" +
                    "<span class='site-badge' style='font-size:11px;padding:3px 10px;border-radius:20px;" +
                    "font-weight:700;background:{4};color:#fff;white-space:nowrap;'>{6}</span>" +
                    "</label></div>" +
                    // Hidden company id
                    "<input type='hidden' name='site_cid_{1}' value='{8}' />" +
                    // Fields grid
                    "<div style='display:grid;grid-template-columns:1fr 2fr;gap:10px;'>" +
                    "<div><label style='font-size:12px;color:var(--muted);display:block;margin-bottom:4px;'>Display Name</label>" +
                    "<input type='text' name='site_name_{1}' value='{2}'" +
                    "  style='width:100%;padding:8px;border-radius:6px;background:var(--bg);" +
                    "  border:1px solid var(--line);color:var(--text);font-size:13px;box-sizing:border-box;' /></div>" +
                    "<div><label style='font-size:12px;color:var(--muted);display:block;margin-bottom:4px;'>" +
                    "Recipients <span style='font-weight:400;'>(semicolon/comma &mdash; blank&nbsp;=&nbsp;Global Recipients)</span></label>" +
                    "<input type='text' name='site_rcpt_{1}' value='{3}'" +
                    "  placeholder='e.g. supervisor@va.gov; 5551234567@vtext.com'" +
                    "  style='width:100%;padding:8px;border-radius:6px;background:var(--bg);" +
                    "  border:1px solid var(--line);color:var(--text);font-size:13px;box-sizing:border-box;' /></div>" +
                    "</div></div>",
                    dispName,           // {0} display name in header
                    key,                // {1} station key (used in input names)
                    dispName,           // {2} display name field value
                    recipients,         // {3} recipients field value
                    enabledBg,          // {4} badge background
                    checkedAttr,        // {5} checkbox checked attr
                    enabledLabel,       // {6} badge text
                    cardOpacity,        // {7} card opacity style
                    company.Id          // {8} company.id
                );
            }

            // Hidden field with comma list of all station keys for postback reading
            sb.AppendFormat("<input type='hidden' name='site_keys' value='{0}' />",
                string.Join(",", companySites.Select(c => c.StationKey)));

            sb.Append("</div>");
            LitSiteConfig.Text = sb.ToString();
        }
        catch (Exception ex)
        {
            LitSiteConfig.Text = "<div class='err'><strong>Error loading site config:</strong> " +
                Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnSaveSiteConfig_Click(object sender, EventArgs e)
    {
        try
        {
            string siteKeys = Request.Form["site_keys"] ?? "";
            var sites = siteKeys.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                                .Select(s => s.Trim())
                                .Where(s => !string.IsNullOrEmpty(s));

            var newConfig = new Dictionary<string, SiteEmailConfigHelper.SiteEmailEntry>(
                StringComparer.OrdinalIgnoreCase);

            foreach (string site in sites)
            {
                string displayName = (Request.Form["site_name_" + site] ?? "").Trim();
                string rcptRaw     = (Request.Form["site_rcpt_" + site] ?? "").Trim();
                // Checkbox: hidden=0 always present; checkbox=1 if checked
                // We read the last value — if checkbox is checked, form posts "0,1"; unchecked posts just "0"
                string[] enabledVals = Request.Form.GetValues("site_enabled_" + site);
                bool enabled = enabledVals != null && enabledVals.Contains("1");

                int companyId;
                int.TryParse(Request.Form["site_cid_" + site] ?? "0", out companyId);

                var recipients = rcptRaw
                    .Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(r => r.Trim())
                    .Where(r => !string.IsNullOrEmpty(r))
                    .ToList();

                newConfig[site] = new SiteEmailConfigHelper.SiteEmailEntry
                {
                    CompanyId   = companyId,
                    DisplayName = string.IsNullOrEmpty(displayName) ? site : displayName,
                    Enabled     = enabled,
                    Recipients  = recipients
                };
            }

            SiteEmailConfigHelper.Save(newConfig);

            int enabledCount  = newConfig.Values.Count(x => x.Enabled);
            int disabledCount = newConfig.Count - enabledCount;
            LitSiteConfigStatus.Text = "<div class='ok' style='margin-top:12px;'>" +
                "<strong>Per-Site Routing Saved!</strong> " +
                enabledCount + " site(s) enabled, " + disabledCount + " disabled.</div>";

            LoadSiteConfig();
        }
        catch (Exception ex)
        {
            LitSiteConfigStatus.Text = "<div class='err' style='margin-top:12px;'>" +
                "<strong>Error:</strong> " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // Returns all sites from the company table (canonical source of truth for sites)
    private List<CompanySite> GetCompanySites()
    {
        var sites = new List<CompanySite>();
        try
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            if (cs == null) return sites;

            string sql = "SELECT id, name FROM dbo.company WHERE name IS NOT NULL ORDER BY name";

            using (var cn = new SqlConnection(cs.ConnectionString))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                    while (rdr.Read())
                        sites.Add(new CompanySite
                        {
                            Id   = (int)rdr["id"],
                            Name = rdr["name"].ToString().Trim()
                        });
            }
        }
        catch { /* silently return whatever we have */ }
        return sites;
    }
}
