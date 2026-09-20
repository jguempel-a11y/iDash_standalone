using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Net.Mail;

namespace iDash
{
    public partial class va_ennx : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Set default date to today
                TxtEnnxDate.Text = DateTime.Today.ToString("yyyy-MM-dd");
                
                // Load users and EILs into DDL
                LoadDropdowns();
            }
        }

        private string ConnStr
        {
            get
            {
                var cs = ConfigurationManager.ConnectionStrings["iDash"]
                      ?? ConfigurationManager.ConnectionStrings["iDash"]
                      ?? ConfigurationManager.ConnectionStrings["iDash"];
                return (cs == null) ? "" : cs.ConnectionString;
            }
        }


        protected void DDL_EnnxSite_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadUsersDropdown();
        }

        protected void TxtDate_Changed(object sender, EventArgs e)
        {
            // Refresh site and user dropdowns to match new date range
            LoadSitesDropdown();
            LoadUsersDropdown();
        }

        // Returns the date range for filtering dropdowns (based on what the user has typed)
        private void GetDateRange(out DateTime dFrom, out DateTime dTo)
        {
            dFrom = DateTime.Today;
            dTo   = DateTime.Today;

            if (!string.IsNullOrWhiteSpace(TxtEnnxDate.Text))
                DateTime.TryParse(TxtEnnxDate.Text.Trim(), out dFrom);

            if (!string.IsNullOrWhiteSpace(TxtEnnxDateTo.Text))
                DateTime.TryParse(TxtEnnxDateTo.Text.Trim(), out dTo);
            else
                dTo = dFrom; // single-day mode
        }

        private void LoadSitesDropdown()
        {
            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);

            string prevSite = DDL_EnnxSite.SelectedValue;

            string sqlSites = @"
                SELECT DISTINCT LTRIM(RTRIM(text7)) AS Site
                FROM dbo.asset
                WHERE text7 IS NOT NULL AND LTRIM(RTRIM(text7)) <> ''
                  AND lastinventoried IS NOT NULL
                  AND CONVERT(date, lastinventoried) >= @dFrom
                  AND CONVERT(date, lastinventoried) <= @dTo
                ORDER BY Site";

            var pars = new[] {
                new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom },
                new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   }
            };

            DataTable dtS = Run(sqlSites, pars);
            DDL_EnnxSite.Items.Clear();
            DDL_EnnxSite.Items.Add(new ListItem("-- ALL SITES --", "ALL"));
            foreach (DataRow r in dtS.Rows)
                DDL_EnnxSite.Items.Add(new ListItem(r["Site"].ToString(), r["Site"].ToString()));

            // Restore previous selection if still valid
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

            string sqlUsers = @"
                SELECT DISTINCT LOWER(LTRIM(RTRIM(lastmodifiedby))) AS UserName
                FROM dbo.asset
                WHERE lastmodifiedby IS NOT NULL
                  AND lastinventoried IS NOT NULL
                  AND CONVERT(date, lastinventoried) >= @dFrom
                  AND CONVERT(date, lastinventoried) <= @dTo"
                + siteWhere + @"
                ORDER BY UserName";

            string prevUser = DDL_EnnxUser.SelectedValue;

            DataTable dtU = Run(sqlUsers, pars.ToArray());
            DDL_EnnxUser.Items.Clear();
            DDL_EnnxUser.Items.Add(new ListItem("-- ALL USERS --", "ALL_USERS"));
            foreach (DataRow r in dtU.Rows)
            {
                string u = r["UserName"].ToString();
                DDL_EnnxUser.Items.Add(new ListItem(u, u));
            }

            // Restore previous or session user
            string current = Convert.ToString(Session["UserName"]);
            if (!string.IsNullOrEmpty(prevUser) && DDL_EnnxUser.Items.FindByValue(prevUser.ToLower()) != null)
                DDL_EnnxUser.SelectedValue = prevUser.ToLower();
            else if (!string.IsNullOrEmpty(current) && DDL_EnnxUser.Items.FindByValue(current.ToLower()) != null)
                DDL_EnnxUser.SelectedValue = current.ToLower();
            else if (DDL_EnnxUser.Items.Count > 1)
                DDL_EnnxUser.SelectedIndex = 1;
        }

        private void LoadDropdowns()
        {
            if (string.IsNullOrEmpty(ConnStr))
            {
                LitErr.Text = "<div class='err'>Database connection string not found. Check web.config for 'iDash' connection string.</div>";
                return;
            }

            try
            {
                LoadSitesDropdown();
                LoadUsersDropdown();

                // CMR/EIL dropdown
                DateTime dFrom, dTo;
                GetDateRange(out dFrom, out dTo);

                string sqlEil = @"
                    SELECT DISTINCT LTRIM(RTRIM(text8)) AS EIL
                    FROM dbo.asset
                    WHERE text8 IS NOT NULL AND LTRIM(RTRIM(text8)) <> ''
                      AND lastinventoried IS NOT NULL
                      AND CONVERT(date, lastinventoried) >= @dFrom
                      AND CONVERT(date, lastinventoried) <= @dTo
                    ORDER BY EIL";

                var eilPars = new[] {
                    new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom },
                    new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   }
                };

                string prevEil = DDL_EnnxEil.SelectedValue;
                DataTable dtE = Run(sqlEil, eilPars);
                DDL_EnnxEil.Items.Clear();
                DDL_EnnxEil.Items.Add(new ListItem("-- All CMR/EILs --", ""));
                foreach (DataRow r in dtE.Rows)
                    DDL_EnnxEil.Items.Add(new ListItem(r["EIL"].ToString(), r["EIL"].ToString()));

                if (!string.IsNullOrEmpty(prevEil) && DDL_EnnxEil.Items.FindByValue(prevEil) != null)
                    DDL_EnnxEil.SelectedValue = prevEil;
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>Failed to load dropdowns: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        protected void BtnRefreshData_Click(object sender, EventArgs e)
        {
            LoadDropdowns();
            LitErr.Text = "<div class='ok'>Application data successfully refreshed (Users & EILs updated).</div>";
        }

        private DataTable GetEnnxData(DateTime d, DateTime? dTo, string user, string site, string eilFilter)
        {
            string sqlWhere = @"
                WHERE 1=1 ";

            var pars = new List<SqlParameter>();

            if (dTo.HasValue)
            {
                sqlWhere += " AND CONVERT(date, a.lastinventoried) >= @d AND CONVERT(date, a.lastinventoried) <= @dTo";
                pars.Add(new SqlParameter("@d", SqlDbType.Date){ Value = d });
                pars.Add(new SqlParameter("@dTo", SqlDbType.Date){ Value = dTo.Value });
            }
            else
            {
                sqlWhere += " AND CONVERT(date, a.lastinventoried) = @d";
                pars.Add(new SqlParameter("@d", SqlDbType.Date){ Value = d });
            }

            if (!string.IsNullOrEmpty(site) && site != "ALL")
            {
                sqlWhere += " AND LTRIM(RTRIM(a.text7)) = @site";
                pars.Add(new SqlParameter("@site", SqlDbType.VarChar){ Value = site });
            }

            if (user != "ALL_USERS")
            {
                sqlWhere += " AND LTRIM(RTRIM(LOWER(a.lastmodifiedby))) = LTRIM(RTRIM(LOWER(@u)))";
                pars.Add(new SqlParameter("@u", SqlDbType.VarChar){ Value = user });
            }

            if (ChkTaggedOnly.Checked)
            {
                sqlWhere += " AND (a.text18 = '1' OR LOWER(a.text18) = 'true')";
            }

            if (!string.IsNullOrWhiteSpace(eilFilter))
            {
                sqlWhere += " AND LTRIM(RTRIM(a.text8)) = @eil";
                pars.Add(new SqlParameter("@eil", SqlDbType.VarChar){ Value = eilFilter });
            }

            string sql = @"
                SELECT 
                    a.name            AS [Name],
                    l.name            AS [Locationname],
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
                FROM dbo.asset a
                LEFT JOIN dbo.location l ON a.locationid = l.id " + sqlWhere;

            return Run(sql, pars.ToArray());
        }

        protected void BtnEnnxBuild_Click(object sender, EventArgs e)
        {
            // Reset ENNX session state
            Session.Remove("GridEnnx");
            Session.Remove("GridEnnxDT");
            Session.Remove("EnnxAll");
            Session.Remove("EnnxPreview");
            
            LitErr.Text = "";

            // Validate selected date
            DateTime d;
            DateTime? dTo;
            if (!TryGetSelectedDate(out d, out dTo))
            {
                LitErr.Text = "<div class='err'>Pick a from date for ENNX.</div>";
                return;
            }

            // Validate user
            if (string.IsNullOrWhiteSpace(DDL_EnnxUser.SelectedValue))
            {
                LitErr.Text = "<div class='err'>Select a user before building ENNX.</div>";
                return;
            }

            string user = DDL_EnnxUser.SelectedValue.Trim();
            string site = DDL_EnnxSite.SelectedValue.Trim();

            // ENNX DATA QUERY (Fetch Unfiltered to Determine CMRs)
            DataTable allUnfiltered = GetEnnxData(d, dTo, user, site, "");

            // Diagnostic: show what was queried and how many rows returned
            if (allUnfiltered == null || allUnfiltered.Rows.Count == 0)
            {
                string dateRange = dTo.HasValue ? d.ToString("yyyy-MM-dd") + " to " + dTo.Value.ToString("yyyy-MM-dd") : d.ToString("yyyy-MM-dd");
                LitErr.Text = "<div class='err'>No data found for: Date = " + dateRange 
                    + ", Site = " + Server.HtmlEncode(site) 
                    + ", User = " + Server.HtmlEncode(user)
                    + ". Verify the date matches when assets were last inventoried (scanned), not modified.</div>";
                TxtEnnxOutput.Text = "";
                LitEnnxTotal.Text = "0";
                LitEnnxAssets.Text = "0";
                LitEnnxLocations.Text = "0";
                GridEnnx.DataSource = null;
                GridEnnx.DataBind();
                return;
            }

            Session["EnnxAll_Unfiltered"] = allUnfiltered;

            // Update CMR dropdown based exactly on what is in this ENNX dataset
            string prevEil = DDL_EnnxEil.SelectedValue;
            DDL_EnnxEil.Items.Clear();
            DDL_EnnxEil.Items.Add(new ListItem("-- All CMR/EILs --", ""));
            
            if (allUnfiltered != null && allUnfiltered.Rows.Count > 0)
            {
                var uniqueEils = allUnfiltered.AsEnumerable()
                                    .Select(r => r.Field<string>("EIL"))
                                    .Where(s => !string.IsNullOrWhiteSpace(s))
                                    .Select(s => s.Trim())
                                    .Distinct(StringComparer.OrdinalIgnoreCase)
                                    .OrderBy(s => s);

                foreach (string eil in uniqueEils) {
                    DDL_EnnxEil.Items.Add(new ListItem(eil, eil));
                }
            }

            if (!string.IsNullOrEmpty(prevEil) && DDL_EnnxEil.Items.FindByValue(prevEil) != null) {
                DDL_EnnxEil.SelectedValue = prevEil;
            }

            // Apply selected CMR filter to generate the final bounded set
            DataTable all = allUnfiltered;
            if (!string.IsNullOrWhiteSpace(DDL_EnnxEil.SelectedValue))
            {
                var filteredRows = allUnfiltered.AsEnumerable().Where(r => 
                    r.Field<string>("EIL") != null && 
                    r.Field<string>("EIL").Trim().Equals(DDL_EnnxEil.SelectedValue, StringComparison.OrdinalIgnoreCase));
                
                if (filteredRows.Any()) {
                    all = filteredRows.CopyToDataTable();
                } else {
                    all = allUnfiltered.Clone();
                }
            }

            // Normalize ENNX locations
            DataTable dt = NormalizeEnnxTable(all);

            // Store CLEAN dataset for grid + Excel + email
            Session["GridEnnxDT"] = dt;
            Session["EnnxAll"] = dt;
            
            LitEnnxTotal.Text = dt.Rows.Count.ToString();
            
            // Calculate Assets and Locations counts (approximate based on rows/groups)
            LitEnnxAssets.Text = dt.Rows.Count.ToString(); // Assuming 1 row per asset
            
            // Count unique locations (headers)
            var uniqueLocs = dt.AsEnumerable()
                .Select(r => 
                    !string.IsNullOrEmpty(r["LocationTagged"] as string) ? r["LocationTagged"].ToString() :
                    !string.IsNullOrEmpty(r["Locationname"] as string) ? r["Locationname"].ToString() :
                    !string.IsNullOrEmpty(r["Previous_Location"] as string) ? r["Previous_Location"].ToString() : "UNKNOWN"
                ).Distinct().Count();
            LitEnnxLocations.Text = uniqueLocs.ToString();


            // Bind grid
            try 
            {
                Bind(GridEnnx, dt, "Name ASC");
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>Grid bind failed: " + ex.Message + "</div>";
            }

            // Build ENNX text output
            int n;
            string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
            TxtEnnxOutput.Text = BuildEnnxText(dt, idPrefix, out n);
        }

        protected void DDL_EnnxEil_SelectedIndexChanged(object sender, EventArgs e)
        {
            DataTable allUnfiltered = Session["EnnxAll_Unfiltered"] as DataTable;
            if (allUnfiltered == null) return; // Build untouched

            // Apply selected CMR filter
            DataTable all = allUnfiltered;
            if (!string.IsNullOrWhiteSpace(DDL_EnnxEil.SelectedValue))
            {
                var filteredRows = allUnfiltered.AsEnumerable().Where(r => 
                    r.Field<string>("EIL") != null && 
                    r.Field<string>("EIL").Trim().Equals(DDL_EnnxEil.SelectedValue, StringComparison.OrdinalIgnoreCase));
                
                if (filteredRows.Any()) {
                    all = filteredRows.CopyToDataTable();
                } else {
                    all = allUnfiltered.Clone();
                }
            }

            // Normalize ENNX locations
            DataTable dt = NormalizeEnnxTable(all);

            // Store CLEAN dataset for grid + Excel + email
            Session["GridEnnxDT"] = dt;
            Session["EnnxAll"] = dt;
            
            LitEnnxTotal.Text = dt.Rows.Count.ToString();
            LitEnnxAssets.Text = dt.Rows.Count.ToString(); 
            
            var uniqueLocs = dt.AsEnumerable()
                .Select(r => 
                    !string.IsNullOrEmpty(r["LocationTagged"] as string) ? r["LocationTagged"].ToString() :
                    !string.IsNullOrEmpty(r["Locationname"] as string) ? r["Locationname"].ToString() :
                    !string.IsNullOrEmpty(r["Previous_Location"] as string) ? r["Previous_Location"].ToString() : "UNKNOWN"
                ).Distinct().Count();
            LitEnnxLocations.Text = uniqueLocs.ToString();

            try { Bind(GridEnnx, dt, "Name ASC"); } catch { }

            int n;
            string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
            TxtEnnxOutput.Text = BuildEnnxText(dt, idPrefix, out n);
        }

        protected void BtnEnnxDownload_Click(object sender, EventArgs e)
        {
            LitErr.Text = "";
            
            DateTime d;
            DateTime? dTo;
            if (!TryGetSelectedDate(out d, out dTo))
            {
                LitErr.Text = "<div class='err'>Pick a from date for ENNX.</div>";
                return;
            }

            if (string.IsNullOrWhiteSpace(DDL_EnnxUser.SelectedValue))
            {
                LitErr.Text = "<div class='err'>Select a user before downloading ENNX.</div>";
                return;
            }
            
            // Re-run execution logic with the explicit EIL filter applied
            string user = DDL_EnnxUser.SelectedValue.Trim();
            string site = DDL_EnnxSite.SelectedValue.Trim();
            DataTable all = GetEnnxData(d, dTo, user, site, DDL_EnnxEil.SelectedValue);

            DataTable dt = NormalizeEnnxTable(all);
            
            int nLines;
            string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
            string text = BuildEnnxText(dt, idPrefix, out nLines);

            string fname = "ENNX-" + d.ToString("MM-dd-yyyy");
            if (dTo.HasValue) 
                fname += "-to-" + dTo.Value.ToString("MM-dd-yyyy");
            fname += ".txt";

            Response.Clear();
            Response.ContentType = "text/plain";
            Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
            Response.Write(text);
            Response.End();
        }

        protected void BtnEnnxExportExcel_Click(object sender, EventArgs e)
        {
            DataTable dt = Session["GridEnnxDT"] as DataTable;
            if (dt == null || dt.Rows.Count == 0)
            {
                LitErr.Text = "<div class='err'>No data to export. Run the report first.</div>";
                return;
            }

            string content = GenerateExcelHtml(dt);

            // Append OIT + No-Data sections if checkbox is checked
            if (ChkIncludeOitNoData.Checked)
            {
                content += GetOitNoDataExcelHtml();
            }

            string fileName = "ENNX-Grid-" + DateTime.Now.ToString("MM-dd-yyyy") + ".xls";
            DownloadContent(fileName, content, "application/vnd.ms-excel");
        }

        protected void BtnShowOit_Click(object sender, EventArgs e)
        {
            // Toggle: if already visible, hide and return
            if (TxtOitPreview.Style["display"] == "block")
            {
                TxtOitPreview.Style["display"] = "none";
                return;
            }

            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);
            string site = DDL_EnnxSite.SelectedValue;

            DataTable dtOit = GetOitData(dFrom, dTo, site);

            if (dtOit == null || dtOit.Rows.Count == 0)
            {
                TxtOitPreview.Text = "No OIT (Office of Information Technology) assets found for the selected date range.";
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("=== OIT ASSETS SCANNED (" + dtOit.Rows.Count + ") ===");
                sb.AppendLine("These assets belong to the VA Office of Information Technology (CMR starts with 78). We do not tag OIT equipment; this report tracks scanned OIT assets for notification.");
                sb.AppendLine();
                foreach (DataRow row in dtOit.Rows)
                {
                    string name = row["Asset Name"] == DBNull.Value ? "" : row["Asset Name"].ToString();
                    string desc = row["Description"] == DBNull.Value ? "" : row["Description"].ToString();
                    string cmr  = row["CMR/EIL"] == DBNull.Value ? "" : row["CMR/EIL"].ToString();
                    string loc  = row["Location Tagged"] == DBNull.Value ? "" : row["Location Tagged"].ToString();
                    string dt2  = row["Tag Date"] == DBNull.Value ? "" : row["Tag Date"].ToString();
                    string user = row["Last Modified By"] == DBNull.Value ? "" : row["Last Modified By"].ToString();

                    sb.AppendLine(string.Format("{0}  --  {1}  |  CMR: {2}  |  Loc: {3}  |  Tagged: {4}  |  By: {5}",
                        name,
                        string.IsNullOrWhiteSpace(desc) ? "(no description)" : desc,
                        string.IsNullOrWhiteSpace(cmr) ? "(none)" : cmr,
                        string.IsNullOrWhiteSpace(loc) ? "(none)" : loc,
                        string.IsNullOrWhiteSpace(dt2) ? "(no date)" : dt2,
                        string.IsNullOrWhiteSpace(user) ? "(unknown)" : user));
                }
                TxtOitPreview.Text = sb.ToString();
            }

            // Show the preview textbox
            TxtOitPreview.Style["display"] = "block";
        }

        protected void BtnShowNoData_Click(object sender, EventArgs e)
        {
            // Toggle: if already visible, hide and return
            if (TxtNoDataPreview.Style["display"] == "block")
            {
                TxtNoDataPreview.Style["display"] = "none";
                return;
            }

            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);
            string site = DDL_EnnxSite.SelectedValue;

            DataTable dtNoData = GetNoDataItems(dFrom, dTo, site);

            if (dtNoData == null || dtNoData.Rows.Count == 0)
            {
                TxtNoDataPreview.Text = "No 'No Data' assets found for the selected date range.";
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("=== NO DATA ASSETS (" + dtNoData.Rows.Count + ") ===");
                sb.AppendLine("These assets were not found in the database when scanned and are excluded from ENNX.");
                sb.AppendLine();
                foreach (DataRow row in dtNoData.Rows)
                {
                    string name = row["Asset Name"] == DBNull.Value ? "" : row["Asset Name"].ToString();
                    string desc = row["Description"] == DBNull.Value ? "" : row["Description"].ToString();
                    string loc  = row["Location Tagged"] == DBNull.Value ? "" : row["Location Tagged"].ToString();
                    string dt2  = row["Tag Date"] == DBNull.Value ? "" : row["Tag Date"].ToString();
                    string user = row["Last Modified By"] == DBNull.Value ? "" : row["Last Modified By"].ToString();

                    sb.AppendLine(string.Format("{0}  --  {1}  |  Loc: {2}  |  Tagged: {3}  |  By: {4}",
                        name,
                        string.IsNullOrWhiteSpace(desc) ? "(no description)" : desc,
                        string.IsNullOrWhiteSpace(loc) ? "(none)" : loc,
                        string.IsNullOrWhiteSpace(dt2) ? "(no date)" : dt2,
                        string.IsNullOrWhiteSpace(user) ? "(unknown)" : user));
                }
                TxtNoDataPreview.Text = sb.ToString();
            }

            // Show the preview textbox
            TxtNoDataPreview.Style["display"] = "block";
        }

        protected void BtnEnnxEmail_Click(object sender, EventArgs e)
        {
            LitErr.Text = "";

            // Check recipients
            var recipients = EmailHelper.GetRecipients();
            if (recipients.Count == 0)
            {
                LitErr.Text = "<div class='err'>No email recipients configured. Please manage recipients on the dashboard (index.aspx).</div>";
                return;
            }

            // Check data
            DataTable dt = Session["GridEnnxDT"] as DataTable;
            if (dt == null || dt.Rows.Count == 0)
            {
                LitErr.Text = "<div class='err'>No data to email. Run the report first.</div>";
                return;
            }

            try
            {
                List<Attachment> atts = new List<Attachment>();

                // 1. Generate ENNX TXT
                int n;
                string idPrefix = string.IsNullOrWhiteSpace(TxtEnnxPrefix.Text) ? "ID" : TxtEnnxPrefix.Text.Trim();
                string ennxText = BuildEnnxText(dt, idPrefix, out n);

                string dateStr = DateTime.Now.ToString("MM-dd-yyyy");
                DateTime parsedDate;
                if (DateTime.TryParse(TxtEnnxDate.Text, out parsedDate))
                {
                    dateStr = parsedDate.ToString("MM-dd-yyyy");
                    DateTime parsedDateTo;
                    if (DateTime.TryParse(TxtEnnxDateTo.Text, out parsedDateTo))
                    {
                        dateStr += "-to-" + parsedDateTo.ToString("MM-dd-yyyy");
                    }
                }

                atts.Add(new Attachment(new System.IO.MemoryStream(Encoding.UTF8.GetBytes(ennxText)), "ENNX-" + dateStr + ".txt"));

                // 2. Generate Excel (with OIT + No-Data if checked)
                string excelHtml = GenerateExcelHtml(dt);
                if (ChkIncludeOitNoData.Checked)
                {
                    excelHtml += GetOitNoDataExcelHtml();
                }
                atts.Add(new Attachment(new System.IO.MemoryStream(Encoding.UTF8.GetBytes(excelHtml)), "ENNX-Grid-" + dateStr + ".xls"));

                // 3. Send
                string subject = "ENNX Report - " + dateStr;
                string body = string.Format("Please find attached the ENNX report and Excel export for {0}.<br/><br/>" +
                              "User: {1}<br/>" +
                              "Assets: {2}<br/>" +
                              "Locations: {3}", 
                              dateStr, 
                              DDL_EnnxUser.SelectedValue, 
                              LitEnnxAssets.Text, 
                              LitEnnxLocations.Text);

                EmailHelper.SendEmail(subject, body, atts);
                LitErr.Text = "<div class='ok'>Email sent successfully to " + recipients.Count + " recipients.</div>";
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>Error sending email: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        // --- Helpers ---

        private bool TryGetSelectedDate(out DateTime d, out DateTime? dTo)
        {
            d = DateTime.MinValue;
            dTo = null;

            if (string.IsNullOrWhiteSpace(TxtEnnxDate.Text)) return false;
            if (!DateTime.TryParse(TxtEnnxDate.Text.Trim(), out d)) return false;

            if (!string.IsNullOrWhiteSpace(TxtEnnxDateTo.Text))
            {
                DateTime parsedTo;
                if (DateTime.TryParse(TxtEnnxDateTo.Text.Trim(), out parsedTo))
                {
                    dTo = parsedTo;
                }
            }

            return true;
        }

        private DataTable Run(string sql, SqlParameter[] pars)
        {
            DataTable dt = new DataTable();
            try {
                using (SqlConnection cn = new SqlConnection(ConnStr))
                using (SqlDataAdapter da = new SqlDataAdapter(sql, cn))
                {
                    if (pars != null)
                    {
                        foreach (SqlParameter p in pars)
                        {
                            // Clone the parameter to avoid "already associated" errors
                            // when the same array is reused across calls
                            SqlParameter clone = new SqlParameter(p.ParameterName, p.SqlDbType);
                            clone.Value = p.Value ?? DBNull.Value;
                            da.SelectCommand.Parameters.Add(clone);
                        }
                    }
                    da.Fill(dt);
                }
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err'>" + Server.HtmlEncode(ex.Message) + "</div>";
            }
            return dt;
        }

        private DataTable NormalizeEnnxTable(DataTable dt)
        {
             if (dt == null) return new DataTable();
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

        private void Bind(GridView grid, DataTable dt, string defaultSort)
        {
            Session[grid.ID + "DT"] = dt;
            DataView dv = new DataView(dt);
            // dv.Sort = defaultSort; // Basic sort
            grid.DataSource = dv;
            grid.DataBind();
        }

        protected void Grid_Sorting(object sender, GridViewSortEventArgs e)
        {
            GridView grid = (GridView)sender;
            DataTable dt = Session[grid.ID + "DT"] as DataTable;
            if (dt == null) return;

            string key = grid.ID + "_";
            string lastExpr = ViewState[key + "SortExpr"] as string;
            string dir = "ASC";

            if (!string.IsNullOrEmpty(lastExpr) && lastExpr == e.SortExpression)
            {
                string lastDir = ViewState[key + "SortDir"] as string;
                dir = (lastDir == "ASC") ? "DESC" : "ASC";
            }

            ViewState[key + "SortExpr"] = e.SortExpression;
            ViewState[key + "SortDir"] = dir;

            DataView dv = new DataView(dt);
            dv.Sort = e.SortExpression + " " + dir;
            grid.DataSource = dv;
            grid.DataBind();
        }

        private string GenerateExcelHtml(DataTable dt)
        {
            if (dt == null || dt.Rows.Count == 0) return "";

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("<table border='1'>");

            // Header
            sb.AppendLine("<tr>");
            foreach (DataColumn col in dt.Columns)
                sb.AppendFormat("<th>{0}</th>", col.ColumnName);
            sb.AppendLine("</tr>");

            // Rows
            foreach (DataRow row in dt.Rows)
            {
                sb.AppendLine("<tr>");
                foreach (DataColumn col in dt.Columns)
                {
                    string val = (row[col.ColumnName] == DBNull.Value) ? "" : row[col.ColumnName].ToString();
                    val = val.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;");
                    // Excel safe
                    string escaped = val.Replace("\"", "\"\"");
                    string excelText = "=\"" + escaped + "\"";
                    sb.AppendFormat("<td>{0}</td>", excelText);
                }
                sb.AppendLine("</tr>");
            }
            sb.AppendLine("</table>");
            return sb.ToString();
        }

        /// <summary>
        /// Generates Excel HTML sections for OIT (CMR starts with 78) and No-Data assets.
        /// Returns HTML that gets appended after the main ENNX grid in the Excel file.
        /// </summary>
        private string GetOitNoDataExcelHtml()
        {
            DateTime dFrom, dTo;
            GetDateRange(out dFrom, out dTo);

            string site = DDL_EnnxSite.SelectedValue;

            StringBuilder sb = new StringBuilder();

            // ── OIT Section: Assets with CMR/EIL (text8) starting with '78' ──
            DataTable dtOit = GetOitData(dFrom, dTo, site);
            if (dtOit != null && dtOit.Rows.Count > 0)
            {
                sb.AppendLine("<br/><br/>");
                sb.AppendLine("<table border='1' cellpadding='4' cellspacing='0' style='border-collapse:collapse; font-family:Calibri,sans-serif; font-size:11pt;'>");
                sb.AppendLine("<tr style='background:#FFF3CD; font-weight:bold;'><td colspan='" + dtOit.Columns.Count + "' style='font-size:14pt; color:#856404; padding:8px;'>&#9888; OIT Items Scanned (" + dtOit.Rows.Count + ") &mdash; Office of Information Technology (CMR starts with 78)</td></tr>");
                // Header row
                sb.Append("<tr style='background:#FFEEBA; font-weight:bold;'>");
                foreach (DataColumn col in dtOit.Columns)
                    sb.AppendFormat("<td>{0}</td>", col.ColumnName);
                sb.AppendLine("</tr>");
                // Data rows
                foreach (DataRow row in dtOit.Rows)
                {
                    sb.Append("<tr>");
                    foreach (DataColumn col in dtOit.Columns)
                    {
                        string val = (row[col.ColumnName] == DBNull.Value) ? "" : row[col.ColumnName].ToString();
                        val = val.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;");
                        string escaped = val.Replace("\"", "\"\"");
                        sb.AppendFormat("<td>=\"{0}\"</td>", escaped);
                    }
                    sb.AppendLine("</tr>");
                }
                sb.AppendLine("</table>");
            }

            // ── No-Data Section: Assets scanned but not found in DB ──
            DataTable dtNoData = GetNoDataItems(dFrom, dTo, site);
            if (dtNoData != null && dtNoData.Rows.Count > 0)
            {
                sb.AppendLine("<br/><br/>");
                sb.AppendLine("<table border='1' cellpadding='4' cellspacing='0' style='border-collapse:collapse; font-family:Calibri,sans-serif; font-size:11pt;'>");
                sb.AppendLine("<tr style='background:#F8D7DA; font-weight:bold;'><td colspan='" + dtNoData.Columns.Count + "' style='font-size:14pt; color:#721C24; padding:8px;'>&#10006; No Data Items (" + dtNoData.Rows.Count + ") &mdash; Not found in database</td></tr>");
                // Header row
                sb.Append("<tr style='background:#F5C6CB; font-weight:bold;'>");
                foreach (DataColumn col in dtNoData.Columns)
                    sb.AppendFormat("<td>{0}</td>", col.ColumnName);
                sb.AppendLine("</tr>");
                // Data rows
                foreach (DataRow row in dtNoData.Rows)
                {
                    sb.Append("<tr>");
                    foreach (DataColumn col in dtNoData.Columns)
                    {
                        string val = (row[col.ColumnName] == DBNull.Value) ? "" : row[col.ColumnName].ToString();
                        val = val.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;");
                        string escaped = val.Replace("\"", "\"\"");
                        sb.AppendFormat("<td>=\"{0}\"</td>", escaped);
                    }
                    sb.AppendLine("</tr>");
                }
                sb.AppendLine("</table>");
            }

            return sb.ToString();
        }

        /// <summary>
        /// Query OIT items: assets inventoried in the date range with CMR (text8) starting with '78'.
        /// These belong to a different VA installation and are excluded from the main ENNX but
        /// need to be tracked for reporting.
        /// </summary>
        private DataTable GetOitData(DateTime dFrom, DateTime dTo, string site)
        {
            var pars = new List<SqlParameter>();
            pars.Add(new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom });
            pars.Add(new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   });

            string siteWhere = "";
            if (!string.IsNullOrEmpty(site) && site != "ALL")
            {
                siteWhere = " AND LTRIM(RTRIM(a.text7)) = @site";
                pars.Add(new SqlParameter("@site", SqlDbType.VarChar) { Value = site });
            }

            string sql = @"
                SELECT 
                    a.name             AS [Asset Name],
                    a.description      AS [Description],
                    a.text8            AS [CMR/EIL],
                    a.text7            AS [Station Number],
                    a.text16           AS [Location Tagged],
                    a.text6            AS [Previous Location],
                    a.text17           AS [Tag Date],
                    a.text19           AS [Tag Type],
                    a.text13           AS [Empl ID],
                    a.lastmodifiedby   AS [Last Modified By],
                    a.lastinventoried  AS [Last Inventoried]
                FROM dbo.asset a
                WHERE a.text8 IS NOT NULL AND a.text8 LIKE '78%'
                  AND a.lastinventoried IS NOT NULL
                  AND CONVERT(date, a.lastinventoried) >= @dFrom
                  AND CONVERT(date, a.lastinventoried) <= @dTo" + siteWhere + @"
                ORDER BY a.text8, a.name";

            return Run(sql, pars.ToArray());
        }

        /// <summary>
        /// Query No-Data items: assets inventoried in the date range whose description indicates
        /// they were not found in the database when scanned (created as stubs by TagTeam Scan).
        /// </summary>
        private DataTable GetNoDataItems(DateTime dFrom, DateTime dTo, string site)
        {
            var pars = new List<SqlParameter>();
            pars.Add(new SqlParameter("@dFrom", SqlDbType.Date) { Value = dFrom });
            pars.Add(new SqlParameter("@dTo",   SqlDbType.Date) { Value = dTo   });

            string siteWhere = "";
            if (!string.IsNullOrEmpty(site) && site != "ALL")
            {
                siteWhere = " AND LTRIM(RTRIM(a.text7)) = @site";
                pars.Add(new SqlParameter("@site", SqlDbType.VarChar) { Value = site });
            }

            string sql = @"
                SELECT 
                    a.name             AS [Asset Name],
                    a.description      AS [Description],
                    a.text7            AS [Station Number],
                    a.text16           AS [Location Tagged],
                    a.text6            AS [Previous Location],
                    a.text17           AS [Tag Date],
                    a.text19           AS [Tag Type],
                    a.text13           AS [Empl ID],
                    a.lastmodifiedby   AS [Last Modified By],
                    a.lastinventoried  AS [Last Inventoried]
                FROM dbo.asset a
                WHERE (a.description = '(Not Found in DB)' 
                    OR a.description = 'New Asset Found (Offline Sync)'
                    OR a.description LIKE '%(Not Found)%')
                  AND a.lastinventoried IS NOT NULL
                  AND CONVERT(date, a.lastinventoried) >= @dFrom
                  AND CONVERT(date, a.lastinventoried) <= @dTo" + siteWhere + @"
                ORDER BY a.name";

            return Run(sql, pars.ToArray());
        }

        private void ExportToExcelHtml(DataTable dt, string fileName)
        {
             string content = GenerateExcelHtml(dt);
             if (string.IsNullOrEmpty(content)) return;

             DownloadContent(fileName, content, "application/vnd.ms-excel");
        }

        private void DownloadContent(string fileName, string content, string contentType)
        {
            byte[] bytes = new UTF8Encoding(true).GetBytes(content);
            Response.Clear();
            Response.Buffer = true;
            Response.Charset = "";
            Response.ContentType = contentType;
            Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            Response.BinaryWrite(bytes);
            Response.End();
        }
    }
}
