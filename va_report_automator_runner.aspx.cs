using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;

namespace iDash
{
    public partial class va_report_automator_runner : System.Web.UI.Page
    {
        private string ConnStr
        {
            get
            {
                var cs = ConfigurationManager.ConnectionStrings["iDash"];
                return (cs == null) ? "" : cs.ConnectionString;
            }
        }

        // Suppress the WebForms page HTML entirely — this page is a raw text endpoint.
        // Without this override, the <form> + ViewState HTML is appended after Response.Write output.
        protected override void Render(System.Web.UI.HtmlTextWriter writer) { /* intentionally empty */ }

        // Helper: flush output without throwing ThreadAbortException
        private void Done()
        {
            Response.Flush();
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Clear();
            Response.ContentType = "text/plain";

            // ── Test support ────────────────────────────────────────────────
            // ?dates            → list recent dates that have scan data
            // ?date=2026-09-10  → run against a specific past date
            // ?preview=1        → show ENNX inline, skip sending email
            // ────────────────────────────────────────────────────────────
            if (Request.QueryString["dates"] != null)
            {
                Response.Write("Recent dates with scan data (use one for ?date=):\n");
                var recentDates = GetRecentScanDates(10);
                if (recentDates.Count == 0)
                    Response.Write("  (no scan dates found in database)\n");
                else
                    foreach (var d in recentDates)
                        Response.Write("  " + d.ToString("yyyy-MM-dd") + "  -->  ?date=" + d.ToString("yyyy-MM-dd") + "&preview=1\n");
                Done(); return;
            }

            DateTime runDate = DateTime.Today;
            string dateParam = Request.QueryString["date"];
            if (!string.IsNullOrEmpty(dateParam))
            {
                DateTime parsed;
                if (DateTime.TryParse(dateParam, out parsed))
                    runDate = parsed.Date;
                else
                {
                    Response.Write("ERROR: invalid ?date= value. Use format YYYY-MM-DD.\n");
                    Done(); return;
                }
            }

            bool previewOnly = Request.QueryString["preview"] == "1";

            Response.Write("iDash Report Runner — " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "\n");
            Response.Write("Run date : " + runDate.ToString("yyyy-MM-dd") + (runDate == DateTime.Today ? " (today)" : " [TEST DATE]") + "\n");
            Response.Write("Mode     : " + (previewOnly ? "PREVIEW (no email sent)" : "LIVE (will send email)") + "\n");
            Response.Write(new string('-', 60) + "\n");

            try
            {
                ReportConfig config = ReadConfig();
                if (!config.Enabled)
                {
                    Response.Write("Automation is disabled in configuration.\n");
                    Done(); return;
                }

                var recipients = EmailHelper.GetRecipients();
                if (recipients.Count == 0 && !previewOnly)
                {
                    Response.Write("No email recipients configured. Aborting.\n");
                    Response.Write("Tip: add recipients in System Automations, or use ?preview=1 to see output without sending.\n");
                    Done(); return;
                }

                List<string> sites = GetActiveSitesForDate(runDate);
                if (sites.Count == 0)
                {
                    Response.Write("No sites had scans on " + runDate.ToString("M/d/yyyy") + ".\n");
                    if (runDate == DateTime.Today)
                        Response.Write("Tip: use ?date=YYYY-MM-DD to test against a past date with data.\n");
                    Done(); return;
                }

                Response.Write("Sites with scans: " + string.Join(", ", sites) + "\n\n");

                // Load per-site email routing (site_email_config.json)
                var siteEmailConfig = SiteEmailConfigHelper.Load();

                int totalEmails = 0;

                foreach (string site in sites)
                {
                    DataTable dt = GetEnnxDataForSite(site, runDate);
                    if (dt == null || dt.Rows.Count == 0) continue;

                    // ── Check site enabled ─────────────────────────────────
                    if (!SiteEmailConfigHelper.GetSiteEnabled(site))
                    {
                        Response.Write("SKIP site: " + site + " — disabled in per-site config.\n");
                        continue;
                    }

                    // ── Resolve recipients ─────────────────────────────────
                    // Priority: site-specific list → global list
                    List<string> siteRecipients = SiteEmailConfigHelper.GetRecipientsForSite(site);
                    string recipientSource;
                    if (siteRecipients != null && siteRecipients.Count > 0)
                        recipientSource = "site-specific (" + siteRecipients.Count + " addr)";
                    else
                    {
                        siteRecipients = EmailHelper.GetRecipients();
                        recipientSource = "global list (" + siteRecipients.Count + " addr)";
                    }

                    if (siteRecipients.Count == 0)
                    {
                        Response.Write("SKIP site: " + site + " — no recipients configured (site or global).\n");
                        continue;
                    }

                    string dateStr = runDate.ToString("MM-dd-yyyy");
                    string subject = config.SubjectTitle
                        .Replace("{Site}", site)
                        .Replace("{Date}", dateStr);

                    string idPrefix = string.IsNullOrWhiteSpace(config.IdPrefix) ? "ID" : config.IdPrefix.Trim();
                    int rowCount = 0;
                    string ennxText = BuildEnnxText(dt, idPrefix, out rowCount);

                    if (previewOnly)
                    {
                        Response.Write("=== PREVIEW: " + site + " (" + dt.Rows.Count + " assets) | Recipients: " + recipientSource + " ===\n");
                        Response.Write("To: " + string.Join(", ", siteRecipients) + "\n");
                        Response.Write(ennxText);
                        Response.Write("\n");
                        continue;
                    }

                    // Filter DataTable for Excel based on configured columns
                    DataTable excelDt = FilterColumnsForExcel(dt, config.ExcelFields);
                    string excelHtml = GenerateExcelHtml(excelDt);

                    List<Attachment> atts = new List<Attachment>();
                    atts.Add(new Attachment(new MemoryStream(Encoding.UTF8.GetBytes(ennxText)), "ENNX-" + site + "-" + dateStr + ".txt"));
                    atts.Add(new Attachment(new MemoryStream(Encoding.UTF8.GetBytes(excelHtml)), "ENNX-Grid-" + site + "-" + dateStr + ".xls"));

                    // Save a copy locally just in case
                    SaveToDisk(site, dateStr, ennxText);

                    string body = string.Format("Automated Daily Report for Site: {0}<br/>Date: {1}<br/>Total Assets Scanned: {2}<br/><br/>Please find the ENNX and Excel reports attached.", site, dateStr, dt.Rows.Count);

                    EmailHelper.SendEmailTo(siteRecipients, subject, body, atts);
                    totalEmails++;
                    Response.Write("Sent [" + recipientSource + "] for site: " + site + " with " + dt.Rows.Count + " assets.\n");
                }

                if (previewOnly)
                    Response.Write(new string('-', 60) + "\nPREVIEW complete. No emails sent. Remove ?preview=1 to send live.\n");
                else
                    Response.Write("Automation completed successfully. Sent " + totalEmails + " reports.\n");
            }
            catch (Exception ex)
            {
                // ThreadAbortException is expected from CompleteRequest — do not log it
                if (ex is System.Threading.ThreadAbortException) return;
                Response.Write("ERROR: " + ex.ToString() + "\n");
            }

            Done();
        }

        private ReportConfig ReadConfig()
        {
            string path = Server.MapPath("~/config/report_automation.json");
            if (!File.Exists(path)) return new ReportConfig();
            try
            {
                string json = File.ReadAllText(path);
                JavaScriptSerializer js = new JavaScriptSerializer();
                return js.Deserialize<ReportConfig>(json) ?? new ReportConfig();
            }
            catch
            {
                return new ReportConfig();
            }
        }

        private List<DateTime> GetRecentScanDates(int top)
        {
            var dates = new List<DateTime>();
            string sql = @"
                SELECT DISTINCT TOP (@top) CONVERT(date, lastinventoried) AS ScanDate
                FROM dbo.v_asset WITH(NOLOCK)
                WHERE lastinventoried IS NOT NULL
                ORDER BY ScanDate DESC
            ";
            using (SqlConnection cn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@top", top);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                    while (rdr.Read())
                        dates.Add(rdr.GetDateTime(0));
            }
            return dates;
        }

        private List<string> GetActiveSitesForDate(DateTime date)

        {
            List<string> sites = new List<string>();
            string sql = @"
                SELECT DISTINCT LTRIM(RTRIM(text7)) AS Site
                FROM dbo.v_asset WITH(NOLOCK)
                WHERE text7 IS NOT NULL AND LTRIM(RTRIM(text7)) <> ''
                  AND lastinventoried IS NOT NULL
                  AND CONVERT(date, lastinventoried) = CONVERT(date, @runDate)
            ";
            using (SqlConnection cn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@runDate", date);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        sites.Add(rdr["Site"].ToString());
                }
            }
            return sites;
        }

        // Keep original for backward compat with any other callers
        private List<string> GetActiveSitesToday() { return GetActiveSitesForDate(DateTime.Today); }

        private DataTable GetEnnxDataForSite(string site, DateTime date)
        {
            string sql = @"
                SELECT 
                    a.name            AS [Name],
                    a.locationname    AS [Locationname],
                    a.text8           AS [EIL],
                    a.description     AS [Description],
                    a.text7           As [Station_Number],
                    a.text14          AS [Sub_Station],
                    a.text19          AS [Tag_Type],
                    a.text13          AS [Empl_ID],
                    a.text10          AS [Previous_Inventory_Date],
                    a.text17          AS [Tag_Date],
                    a.text6           AS [Previous_Location],
                    a.text16          AS [LocationTagged],
                    a.listvalue1      AS [DisposalStatus],
                    a.text20          AS [Notes],
                    a.lastmodifiedby  AS [Last_Modified_By],
                    a.lastinventoried AS [LastInventoried]
                FROM dbo.v_asset a WITH(NOLOCK)
                WHERE CONVERT(date, a.lastinventoried) = CONVERT(date, @runDate)
                  AND LTRIM(RTRIM(a.text7)) = @site
            ";
            DataTable dt = new DataTable();
            using (SqlConnection cn = new SqlConnection(ConnStr))
            using (SqlDataAdapter da = new SqlDataAdapter(sql, cn))
            {
                da.SelectCommand.Parameters.AddWithValue("@runDate", date);
                da.SelectCommand.Parameters.AddWithValue("@site", site);
                da.Fill(dt);
            }
            return dt;
        }

        // Overload for backward compat
        private DataTable GetEnnxDataForSite(string site) { return GetEnnxDataForSite(site, DateTime.Today); }

        private DataTable FilterColumnsForExcel(DataTable src, List<string> requestedFields)
        {
            if (requestedFields == null || requestedFields.Count == 0) return src;

            DataTable dt = src.Copy();
            // Remove columns that are not in the requested fields list (case insensitive)
            for (int i = dt.Columns.Count - 1; i >= 0; i--)
            {
                string colName = dt.Columns[i].ColumnName;
                if (!requestedFields.Contains(colName, StringComparer.OrdinalIgnoreCase))
                {
                    dt.Columns.RemoveAt(i);
                }
            }
            return dt;
        }

        private string CleanEnnxCell(object v)
        {
            if (v == null || v == DBNull.Value) return "";
            string s = v.ToString().Trim();
            if (s == "&nbsp;" || s == "&#160;" || s == "&amp;nbsp;") return "";
            return s;
        }

        private string BuildEnnxText(DataTable dt, string idLine, out int footerCount)
        {
            string id = string.IsNullOrWhiteSpace(idLine) ? "ID" : idLine.Trim();

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("ENNX");
            sb.AppendLine(id);

            int count = 1;

            var groups = dt.AsEnumerable()
                .GroupBy(r => {
                    string tagged = dt.Columns.Contains("LocationTagged") ? CleanEnnxCell(r["LocationTagged"]) : "";
                    string locName = dt.Columns.Contains("Locationname") ? CleanEnnxCell(r["Locationname"]) : "";
                    string prev = dt.Columns.Contains("Previous_Location") ? CleanEnnxCell(r["Previous_Location"]) : "";

                    if (string.Equals(tagged, "MISSING", StringComparison.OrdinalIgnoreCase)) tagged = "";
                    if (string.Equals(locName, "MISSING", StringComparison.OrdinalIgnoreCase)) locName = "";
                    if (string.Equals(prev, "MISSING", StringComparison.OrdinalIgnoreCase)) prev = "";

                    string effective = (!string.IsNullOrEmpty(tagged)) ? tagged :
                                       (!string.IsNullOrEmpty(locName)) ? locName :
                                       (!string.IsNullOrEmpty(prev)) ? prev : "UNKNOWN";
                    return effective;
                }, StringComparer.OrdinalIgnoreCase)
                .OrderBy(g => g.Key, StringComparer.OrdinalIgnoreCase);

            foreach (var grp in groups)
            {
                string header = string.IsNullOrWhiteSpace(grp.Key) ? "UNKNOWN" : grp.Key;
                sb.AppendLine(header);
                count++;

                foreach (DataRow row in grp)
                {
                    string name = CleanEnnxCell(row["Name"]);
                    if (name.Length > 0)
                    {
                        sb.AppendLine(name);
                        count++;
                    }
                }
            }

            sb.AppendLine("***END***^" + count);
            footerCount = count;
            return sb.ToString();
        }

        private string GenerateExcelHtml(DataTable dt)
        {
            if (dt == null || dt.Rows.Count == 0) return "";

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("<table border='1'>");

            sb.AppendLine("<tr>");
            foreach (DataColumn col in dt.Columns)
                sb.AppendFormat("<th>{0}</th>", col.ColumnName);
            sb.AppendLine("</tr>");

            foreach (DataRow row in dt.Rows)
            {
                sb.AppendLine("<tr>");
                foreach (DataColumn col in dt.Columns)
                {
                    string val = (row[col.ColumnName] == DBNull.Value) ? "" : row[col.ColumnName].ToString();
                    val = val.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;");
                    string escaped = val.Replace("\"", "\"\"");
                    string excelText = "=\"" + escaped + "\"";
                    sb.AppendFormat("<td>{0}</td>", excelText);
                }
                sb.AppendLine("</tr>");
            }
            sb.AppendLine("</table>");
            return sb.ToString();
        }

        private void SaveToDisk(string site, string dateStr, string ennxText)
        {
            try
            {
                string dir = @"C:\VA_RFID\ennx_live\saved\auto\";
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                string path = Path.Combine(dir, "auto_ennx_" + site + "_" + dateStr + ".txt");
                File.WriteAllText(path, ennxText, Encoding.UTF8);
            }
            catch { }
        }
    }

    public class ReportConfig
    {
        public bool Enabled { get; set; }
        public string ScheduledTime { get; set; }
        public string SubjectTitle { get; set; }
        public List<string> Recipients { get; set; }
        public List<string> ExcelFields { get; set; }
        public string IdPrefix { get; set; }

        public ReportConfig()
        {
            Enabled = true;
            ScheduledTime = "19:00";
            SubjectTitle = "Automated ENNX Report - {Site} - {Date}";
            Recipients = new List<string>();
            ExcelFields = new List<string> { "Name", "Description", "EIL", "Locationname", "Station_Number", "Tag_Date", "Last_Modified_By" };
            IdPrefix = "ID";
        }
    }
}
