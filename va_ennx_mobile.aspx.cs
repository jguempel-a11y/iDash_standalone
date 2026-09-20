using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Net.Mail;

namespace iDash
{
    /// <summary>
    /// ENNX Mobile Export — identical to va_ennx but filters on lastmodified
    /// instead of lastinventoried, so mobile-app scans are included.
    /// </summary>
    public partial class va_ennx_mobile : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                TxtEnnxDate.Text = DateTime.Today.ToString("yyyy-MM-dd");
                LoadDropdowns();
            }
        }

        private string ConnStr
        {
            get
            {
                var cs = ConfigurationManager.ConnectionStrings["iDash"];
                return (cs == null) ? "" : cs.ConnectionString;
            }
        }

        // ─── Date Range ───────────────────────────────────────────────────────

        private void GetDateRange(out DateTime dFrom, out DateTime dTo)
        {
            dFrom = DateTime.Today;
            dTo   = DateTime.Today;

            if (!string.IsNullOrWhiteSpace(TxtEnnxDate.Text))
                DateTime.TryParse(TxtEnnxDate.Text.Trim(), out dFrom);

            if (!string.IsNullOrWhiteSpace(TxtEnnxDateTo.Text))
                DateTime.TryParse(TxtEnnxDateTo.Text.Trim(), out dTo);
            else
                dTo = dFrom;
        }

        // ─── Dropdowns ────────────────────────────────────────────────────────

        private void LoadDropdowns()
        {
            try
            {
                LoadSitesDropdown();
                LoadUsersDropdown();
                LoadEilDropdown(null);
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>Failed to load dropdowns: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        private void LoadSitesDropdown()
        {
            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);

            string prevSite = DDL_EnnxSite.SelectedValue;

            // *** KEY CHANGE: filter on lastmodified ***
            string sql = @"
                SELECT DISTINCT LTRIM(RTRIM(text7)) AS Site
                FROM dbo.v_asset
                WHERE text7 IS NOT NULL AND LTRIM(RTRIM(text7)) <> ''
                  AND lastmodified IS NOT NULL
                  AND CONVERT(date, lastmodified) >= @dFrom
                  AND CONVERT(date, lastmodified) <= @dTo
                ORDER BY Site";

            var pars = new[]
            {
                new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom },
                new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   }
            };

            DataTable dt = Run(sql, pars);
            DDL_EnnxSite.Items.Clear();
            DDL_EnnxSite.Items.Add(new ListItem("-- ALL SITES --", "ALL"));
            foreach (DataRow r in dt.Rows)
                DDL_EnnxSite.Items.Add(new ListItem(r["Site"].ToString(), r["Site"].ToString()));

            if (!string.IsNullOrEmpty(prevSite) && DDL_EnnxSite.Items.FindByValue(prevSite) != null)
                DDL_EnnxSite.SelectedValue = prevSite;
        }

        private void LoadUsersDropdown()
        {
            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);

            string site = DDL_EnnxSite.SelectedValue;
            var pars = new List<SqlParameter>();
            pars.Add(new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom });
            pars.Add(new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   });

            string siteWhere = "";
            if (!string.IsNullOrEmpty(site) && site != "ALL")
            {
                siteWhere = " AND LTRIM(RTRIM(text7)) = @site";
                pars.Add(new SqlParameter("@site", SqlDbType.VarChar) { Value = site });
            }

            // *** KEY CHANGE: filter on lastmodified ***
            string sql = @"
                SELECT DISTINCT LOWER(LTRIM(RTRIM(lastmodifiedby))) AS UserName
                FROM dbo.v_asset
                WHERE lastmodifiedby IS NOT NULL
                  AND lastmodified IS NOT NULL
                  AND CONVERT(date, lastmodified) >= @dFrom
                  AND CONVERT(date, lastmodified) <= @dTo"
                + siteWhere + @"
                ORDER BY UserName";

            string prevUser = DDL_EnnxUser.SelectedValue;

            DataTable dt = Run(sql, pars.ToArray());
            DDL_EnnxUser.Items.Clear();
            DDL_EnnxUser.Items.Add(new ListItem("-- ALL USERS --", "ALL_USERS"));
            foreach (DataRow r in dt.Rows)
            {
                string u = r["UserName"].ToString();
                DDL_EnnxUser.Items.Add(new ListItem(u, u));
            }

            string current = Convert.ToString(Session["UserName"]);
            if (!string.IsNullOrEmpty(prevUser) && DDL_EnnxUser.Items.FindByValue(prevUser.ToLower()) != null)
                DDL_EnnxUser.SelectedValue = prevUser.ToLower();
            else if (!string.IsNullOrEmpty(current) && DDL_EnnxUser.Items.FindByValue(current.ToLower()) != null)
                DDL_EnnxUser.SelectedValue = current.ToLower();
            else if (DDL_EnnxUser.Items.Count > 1)
                DDL_EnnxUser.SelectedIndex = 1;
        }

        private void LoadEilDropdown(DataTable fromData)
        {
            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);

            string prevEil = DDL_EnnxEil.SelectedValue;
            DDL_EnnxEil.Items.Clear();
            DDL_EnnxEil.Items.Add(new ListItem("-- All CMR/EILs --", ""));

            if (fromData != null && fromData.Rows.Count > 0)
            {
                // Populate from already-fetched dataset
                var eils = fromData.AsEnumerable()
                    .Select(r => r.Field<string>("EIL"))
                    .Where(s => !string.IsNullOrWhiteSpace(s))
                    .Select(s => s.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .OrderBy(s => s);

                foreach (string eil in eils)
                    DDL_EnnxEil.Items.Add(new ListItem(eil, eil));
            }
            else
            {
                // *** KEY CHANGE: filter on lastmodified ***
                string sql = @"
                    SELECT DISTINCT LTRIM(RTRIM(text8)) AS EIL
                    FROM dbo.v_asset
                    WHERE text8 IS NOT NULL AND LTRIM(RTRIM(text8)) <> ''
                      AND lastmodified IS NOT NULL
                      AND CONVERT(date, lastmodified) >= @dFrom
                      AND CONVERT(date, lastmodified) <= @dTo
                    ORDER BY EIL";

                var pars = new[]
                {
                    new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom },
                    new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   }
                };

                DataTable dt = Run(sql, pars);
                foreach (DataRow r in dt.Rows)
                    DDL_EnnxEil.Items.Add(new ListItem(r["EIL"].ToString(), r["EIL"].ToString()));
            }

            if (!string.IsNullOrEmpty(prevEil) && DDL_EnnxEil.Items.FindByValue(prevEil) != null)
                DDL_EnnxEil.SelectedValue = prevEil;
        }

        // ─── Event Handlers ───────────────────────────────────────────────────

        protected void DDL_EnnxSite_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadUsersDropdown();
        }

        protected void TxtDate_Changed(object sender, EventArgs e)
        {
            LoadSitesDropdown();
            LoadUsersDropdown();
        }

        protected void BtnRefreshData_Click(object sender, EventArgs e)
        {
            LoadDropdowns();
            LitErr.Text = "<div class='ok'>Application data refreshed (users &amp; EILs updated).</div>";
        }

        protected void BtnEnnxBuild_Click(object sender, EventArgs e)
        {
            Session.Remove("GridMobileDT");
            Session.Remove("MobileAll");
            Session.Remove("MobileAll_Unfiltered");
            LitErr.Text = "";

            DateTime d;
            DateTime? dTo;
            if (!TryGetSelectedDate(out d, out dTo))
            {
                LitErr.Text = "<div class='err'>Pick a From date.</div>";
                return;
            }

            if (string.IsNullOrWhiteSpace(DDL_EnnxUser.SelectedValue))
            {
                LitErr.Text = "<div class='err'>Select a user before building ENNX.</div>";
                return;
            }

            string user = DDL_EnnxUser.SelectedValue.Trim();
            string site = DDL_EnnxSite.SelectedValue.Trim();

            DataTable allUnfiltered = GetEnnxData(d, dTo, user, site, "");
            Session["MobileAll_Unfiltered"] = allUnfiltered;

            // Rebuild EIL dropdown from live data
            LoadEilDropdown(allUnfiltered);

            // Apply CMR filter
            DataTable all = ApplyEilFilter(allUnfiltered, DDL_EnnxEil.SelectedValue);

            DataTable dt = NormalizeTable(all);
            Session["GridMobileDT"] = dt;
            Session["MobileAll"]    = dt;

            LitEnnxTotal.Text     = dt.Rows.Count.ToString();
            LitEnnxAssets.Text    = dt.Rows.Count.ToString();
            LitEnnxLocations.Text = GetUniqueLocCount(dt).ToString();

            try   { Bind(GridMobile, dt, "Name ASC"); }
            catch (Exception ex) { LitErr.Text = "<div class='err'>Grid error: " + ex.Message + "</div>"; }

            string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
            int n;
            TxtEnnxOutput.Text = BuildEnnxText(dt, idPrefix, out n);
        }

        protected void DDL_EnnxEil_SelectedIndexChanged(object sender, EventArgs e)
        {
            DataTable allUnfiltered = Session["MobileAll_Unfiltered"] as DataTable;
            if (allUnfiltered == null) return;

            DataTable all = ApplyEilFilter(allUnfiltered, DDL_EnnxEil.SelectedValue);
            DataTable dt  = NormalizeTable(all);

            Session["GridMobileDT"] = dt;
            Session["MobileAll"]    = dt;

            LitEnnxTotal.Text     = dt.Rows.Count.ToString();
            LitEnnxAssets.Text    = dt.Rows.Count.ToString();
            LitEnnxLocations.Text = GetUniqueLocCount(dt).ToString();

            try   { Bind(GridMobile, dt, "Name ASC"); } catch { }

            string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
            int n;
            TxtEnnxOutput.Text = BuildEnnxText(dt, idPrefix, out n);
        }

        protected void BtnEnnxDownload_Click(object sender, EventArgs e)
        {
            LitErr.Text = "";

            DateTime d;
            DateTime? dTo;
            if (!TryGetSelectedDate(out d, out dTo))
            {
                LitErr.Text = "<div class='err'>Pick a From date.</div>";
                return;
            }

            if (string.IsNullOrWhiteSpace(DDL_EnnxUser.SelectedValue))
            {
                LitErr.Text = "<div class='err'>Select a user before downloading.</div>";
                return;
            }

            string user = DDL_EnnxUser.SelectedValue.Trim();
            string site = DDL_EnnxSite.SelectedValue.Trim();
            DataTable all = GetEnnxData(d, dTo, user, site, DDL_EnnxEil.SelectedValue);
            DataTable dt  = NormalizeTable(all);

            string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
            int nLines;
            string text = BuildEnnxText(dt, idPrefix, out nLines);

            string fname = "ENNX-Mobile-" + d.ToString("MM-dd-yyyy");
            if (dTo.HasValue) fname += "-to-" + dTo.Value.ToString("MM-dd-yyyy");
            fname += ".txt";

            Response.Clear();
            Response.ContentType = "text/plain";
            Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
            Response.Write(text);
            Response.End();
        }

        protected void BtnEnnxExportExcel_Click(object sender, EventArgs e)
        {
            DataTable dt = Session["GridMobileDT"] as DataTable;
            if (dt == null || dt.Rows.Count == 0)
            {
                LitErr.Text = "<div class='err'>No data to export. Run the report first.</div>";
                return;
            }
            string fileName = "ENNX-Mobile-" + DateTime.Now.ToString("MM-dd-yyyy") + ".xls";
            ExportToExcelHtml(dt, fileName);
        }

        protected void BtnEnnxEmail_Click(object sender, EventArgs e)
        {
            LitErr.Text = "";

            List<string> recipients = GetEmailRecipients();
            if (recipients.Count == 0)
            {
                LitErr.Text = "<div class='err'>No email recipients configured. Please manage recipients on the dashboard (index.aspx).</div>";
                return;
            }

            DataTable dt = Session["GridMobileDT"] as DataTable;
            if (dt == null || dt.Rows.Count == 0)
            {
                LitErr.Text = "<div class='err'>No data to email. Run the report first.</div>";
                return;
            }

            try
            {
                List<Attachment> atts = new List<Attachment>();

                string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
                int n;
                string ennxText = BuildEnnxText(dt, idPrefix, out n);

                string dateStr = DateTime.Now.ToString("MM-dd-yyyy");
                DateTime parsedDate;
                if (DateTime.TryParse(TxtEnnxDate.Text, out parsedDate))
                {
                    dateStr = parsedDate.ToString("MM-dd-yyyy");
                    DateTime parsedDateTo;
                    if (DateTime.TryParse(TxtEnnxDateTo.Text, out parsedDateTo))
                        dateStr += "-to-" + parsedDateTo.ToString("MM-dd-yyyy");
                }

                atts.Add(new Attachment(new System.IO.MemoryStream(Encoding.UTF8.GetBytes(ennxText)), "ENNX-Mobile-" + dateStr + ".txt"));
                string excelHtml = GenerateExcelHtml(dt);
                atts.Add(new Attachment(new System.IO.MemoryStream(Encoding.UTF8.GetBytes(excelHtml)), "ENNX-Mobile-Grid-" + dateStr + ".xls"));

                string subject = "ENNX Mobile Report - " + dateStr;
                string body = string.Format(
                    "Please find attached the ENNX Mobile report and Excel export for {0}.<br/><br/>" +
                    "User: {1}<br/>Assets: {2}<br/>Locations: {3}<br/><br/>" +
                    "<em>Note: This report was generated from lastmodified (mobile scans).</em>",
                    dateStr, DDL_EnnxUser.SelectedValue, LitEnnxAssets.Text, LitEnnxLocations.Text);

                SendEmailDirect(subject, body, atts, recipients);
                LitErr.Text = "<div class='ok'>Email sent successfully to " + recipients.Count + " recipients.</div>";
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>Error sending email: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        // Delegate to the shared EmailHelper which now reads from JSON file
        private List<string> GetEmailRecipients()
        {
            try
            {
                return EmailHelper.GetRecipients();
            }
            catch { return new List<string>(); }
        }

        private void SendEmailDirect(string subject, string body, List<Attachment> attachments, List<string> recipients)
        {
            string smtpHost = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "localhost";
            int smtpPort;
            if (!int.TryParse(WebConfigurationManager.AppSettings["SMTP_Port"], out smtpPort)) smtpPort = 25;
            string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
            string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];
            string smtpFrom = WebConfigurationManager.AppSettings["SMTP_FromEmail"] ?? "no-reply@idash.local";
            string smtpFromName = WebConfigurationManager.AppSettings["SMTP_FromName"] ?? "iDash Reports";

            using (SmtpClient client = new SmtpClient(smtpHost, smtpPort))
            using (MailMessage msg = new MailMessage())
            {
                if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
                {
                    client.EnableSsl = true;
                    client.Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass);
                }
                msg.From = new MailAddress(smtpFrom, smtpFromName);
                foreach (string r in recipients) msg.To.Add(r);
                msg.Subject    = subject;
                msg.Body       = body;
                msg.IsBodyHtml = true;
                if (attachments != null)
                    foreach (var att in attachments) msg.Attachments.Add(att);
                client.Send(msg);
            }
        }

        // ─── Data Query ───────────────────────────────────────────────────────

        private DataTable GetEnnxData(DateTime d, DateTime? dTo, string user, string site, string eilFilter)
        {
            var pars = new List<SqlParameter>();
            string sqlWhere = " WHERE 1=1";

            // *** KEY CHANGE: filter on lastmodified ***
            if (dTo.HasValue)
            {
                sqlWhere += " AND CONVERT(date, a.lastmodified) >= @d AND CONVERT(date, a.lastmodified) <= @dTo";
                pars.Add(new SqlParameter("@d",   SqlDbType.Date) { Value = d });
                pars.Add(new SqlParameter("@dTo", SqlDbType.Date) { Value = dTo.Value });
            }
            else
            {
                sqlWhere += " AND CONVERT(date, a.lastmodified) = @d";
                pars.Add(new SqlParameter("@d", SqlDbType.Date) { Value = d });
            }

            if (!string.IsNullOrEmpty(site) && site != "ALL")
            {
                sqlWhere += " AND LTRIM(RTRIM(a.text7)) = @site";
                pars.Add(new SqlParameter("@site", SqlDbType.VarChar) { Value = site });
            }

            if (user != "ALL_USERS")
            {
                sqlWhere += " AND LTRIM(RTRIM(LOWER(a.lastmodifiedby))) = LTRIM(RTRIM(LOWER(@u)))";
                pars.Add(new SqlParameter("@u", SqlDbType.VarChar) { Value = user });
            }

            if (ChkTaggedOnly.Checked)
                sqlWhere += " AND (a.text18 = '1' OR LOWER(a.text18) = 'true')";

            if (!string.IsNullOrWhiteSpace(eilFilter))
            {
                sqlWhere += " AND LTRIM(RTRIM(a.text8)) = @eil";
                pars.Add(new SqlParameter("@eil", SqlDbType.VarChar) { Value = eilFilter });
            }

            string sql = @"
                SELECT
                    a.name            AS [Name],
                    a.locationname    AS [Locationname],
                    a.text8           AS [EIL],
                    a.description     AS [Description],
                    a.text7           AS [Station_Number],
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
                    a.lastmodified    AS [LastModified],
                    a.lastinventoried AS [LastInventoried]
                FROM dbo.v_asset a WITH(NOLOCK)" + sqlWhere;

            return Run(sql, pars.ToArray());
        }

        // ─── Helpers ─────────────────────────────────────────────────────────

        private DataTable ApplyEilFilter(DataTable source, string eilValue)
        {
            if (string.IsNullOrWhiteSpace(eilValue) || source == null) return source ?? new DataTable();

            var filtered = source.AsEnumerable().Where(r =>
                r.Field<string>("EIL") != null &&
                r.Field<string>("EIL").Trim().Equals(eilValue, StringComparison.OrdinalIgnoreCase));

            return filtered.Any() ? filtered.CopyToDataTable() : source.Clone();
        }

        private DataTable NormalizeTable(DataTable dt)
        {
            return dt ?? new DataTable();
        }

        private int GetUniqueLocCount(DataTable dt)
        {
            if (dt == null || dt.Rows.Count == 0) return 0;
            return dt.AsEnumerable()
                .Select(r =>
                {
                    string tagged = r["LocationTagged"] as string;
                    string loc    = r["Locationname"]   as string;
                    string prev   = r["Previous_Location"] as string;
                    return !string.IsNullOrWhiteSpace(tagged) ? tagged.Trim() :
                           !string.IsNullOrWhiteSpace(loc)    ? loc.Trim()    :
                           !string.IsNullOrWhiteSpace(prev)   ? prev.Trim()   : "UNKNOWN";
                })
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Count();
        }

        private bool TryGetSelectedDate(out DateTime d, out DateTime? dTo)
        {
            d   = DateTime.MinValue;
            dTo = null;

            if (string.IsNullOrWhiteSpace(TxtEnnxDate.Text)) return false;
            if (!DateTime.TryParse(TxtEnnxDate.Text.Trim(), out d)) return false;

            if (!string.IsNullOrWhiteSpace(TxtEnnxDateTo.Text))
            {
                DateTime parsedTo;
                if (DateTime.TryParse(TxtEnnxDateTo.Text.Trim(), out parsedTo))
                    dTo = parsedTo;
            }
            return true;
        }

        private string CleanCell(object v)
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
                .GroupBy(r =>
                {
                    string tagged = dt.Columns.Contains("LocationTagged") ? CleanCell(r["LocationTagged"]) : "";
                    string locName = dt.Columns.Contains("Locationname")  ? CleanCell(r["Locationname"])   : "";
                    string prev    = dt.Columns.Contains("Previous_Location") ? CleanCell(r["Previous_Location"]) : "";

                    if (string.Equals(tagged, "MISSING",  StringComparison.OrdinalIgnoreCase)) tagged  = "";
                    if (string.Equals(locName, "MISSING", StringComparison.OrdinalIgnoreCase)) locName = "";
                    if (string.Equals(prev,    "MISSING", StringComparison.OrdinalIgnoreCase)) prev    = "";

                    return !string.IsNullOrEmpty(tagged)  ? tagged  :
                           !string.IsNullOrEmpty(locName) ? locName :
                           !string.IsNullOrEmpty(prev)    ? prev    : "UNKNOWN";
                }, StringComparer.OrdinalIgnoreCase)
                .OrderBy(g => g.Key, StringComparer.OrdinalIgnoreCase);

            foreach (var grp in groups)
            {
                sb.AppendLine(string.IsNullOrWhiteSpace(grp.Key) ? "UNKNOWN" : grp.Key);
                count++;
                foreach (DataRow row in grp)
                {
                    string name = CleanCell(row["Name"]);
                    if (name.Length > 0) { sb.AppendLine(name); count++; }
                }
            }

            sb.AppendLine("***END***^" + count);
            footerCount = count;
            return sb.ToString();
        }

        private void Bind(GridView grid, DataTable dt, string defaultSort)
        {
            Session[grid.ID + "DT"] = dt;
            DataView dv = new DataView(dt);
            grid.DataSource = dv;
            grid.DataBind();
        }

        protected void Grid_Sorting(object sender, GridViewSortEventArgs e)
        {
            GridView grid = (GridView)sender;
            DataTable dt  = Session[grid.ID + "DT"] as DataTable;
            if (dt == null) return;

            string key     = grid.ID + "_";
            string lastExp = ViewState[key + "SortExpr"] as string;
            string dir     = "ASC";

            if (!string.IsNullOrEmpty(lastExp) && lastExp == e.SortExpression)
                dir = (ViewState[key + "SortDir"] as string) == "ASC" ? "DESC" : "ASC";

            ViewState[key + "SortExpr"] = e.SortExpression;
            ViewState[key + "SortDir"]  = dir;

            grid.DataSource = new DataView(dt) { Sort = e.SortExpression + " " + dir };
            grid.DataBind();
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
                    sb.AppendFormat("<td>=\"{0}\"</td>", val.Replace("\"", "\"\""));
                }
                sb.AppendLine("</tr>");
            }
            sb.AppendLine("</table>");
            return sb.ToString();
        }

        private void ExportToExcelHtml(DataTable dt, string fileName)
        {
            string content = GenerateExcelHtml(dt);
            if (string.IsNullOrEmpty(content)) return;
            byte[] bytes = new UTF8Encoding(true).GetBytes(content);
            Response.Clear();
            Response.Buffer  = true;
            Response.Charset = "";
            Response.ContentType = "application/vnd.ms-excel";
            Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            Response.BinaryWrite(bytes);
            Response.End();
        }

        private DataTable Run(string sql, SqlParameter[] pars)
        {
            DataTable dt = new DataTable();
            try
            {
                using (SqlConnection cn = new SqlConnection(ConnStr))
                using (SqlDataAdapter da = new SqlDataAdapter(sql, cn))
                {
                    if (pars != null)
                        foreach (SqlParameter p in pars)
                            da.SelectCommand.Parameters.AddWithValue(p.ParameterName, p.Value ?? (object)DBNull.Value);
                    da.Fill(dt);
                }
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>" + Server.HtmlEncode(ex.Message) + "</div>";
            }
            return dt;
        }
    }
}
