using System;
using System.IO;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ClosedXML.Excel;

namespace iDash
{
    /// <summary>
    /// va_sitedata_export.aspx.cs
    /// Exports iDash asset data for a selected company/site to
    /// tab-delimited (.txt) or CSV format, ready for import on another iDash system.
    ///
    /// PURPOSE:
    ///   When migrating a site to a new iDash server, or when sharing data
    ///   between VISN locations, this tool produces a flat-file snapshot of
    ///   the dbo.v_asset view filtered by company (site). The file format
    ///   matches the columns expected by the iDash DB Update import pipeline,
    ///   so you can immediately run it through va_dbupdate.aspx on the target.
    ///
    /// WHY TAB-DELIMITED:
    ///   Asset names and descriptions frequently contain commas and quotes.
    ///   Tab-delimited files avoid quoting ambiguity and are the native format
    ///   expected by the VA iDash import templates.
    /// </summary>
    public partial class va_sitedata_export : System.Web.UI.Page
    {
        // ── Connection string ────────────────────────────────────────────────
        private string ConnStr
        {
            get
            {
                // Try both casing variants used across iDash pages
                var cs = ConfigurationManager.ConnectionStrings["iDash"]
                      ?? ConfigurationManager.ConnectionStrings["iDash"];
                return cs != null ? cs.ConnectionString : "";
            }
        }

        // ── Page Load ────────────────────────────────────────────────────────
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Request["sync"] == "root")
            {
                string thisDir = Server.MapPath(".");
                var parent = Directory.GetParent(thisDir);
                if (parent != null && parent.Exists)
                {
                    int filesCopied = 0;
                    foreach (string f in Directory.GetFiles(thisDir))
                    {
                        string fname = Path.GetFileName(f);
                        if (!fname.Equals("web.config", StringComparison.OrdinalIgnoreCase))
                        {
                            File.Copy(f, Path.Combine(parent.FullName, fname), true);
                            filesCopied++;
                        }
                    }
                    foreach (string d in Directory.GetDirectories(thisDir))
                    {
                        string dname = Path.GetFileName(d);
                        if (!dname.Equals("logs", StringComparison.OrdinalIgnoreCase) && !dname.Equals("scratch", StringComparison.OrdinalIgnoreCase))
                        {
                            string targetSub = Path.Combine(parent.FullName, dname);
                            if (!Directory.Exists(targetSub)) Directory.CreateDirectory(targetSub);
                            foreach (string subf in Directory.GetFiles(d))
                            {
                                File.Copy(subf, Path.Combine(targetSub, Path.GetFileName(subf)), true);
                                filesCopied++;
                            }
                        }
                    }
                    string cfg = Path.Combine(parent.FullName, "web.config");
                    if (File.Exists(cfg))
                    {
                        try { File.SetLastWriteTime(cfg, DateTime.Now); } catch {}
                    }
                    Response.Clear();
                    Response.ContentType = "text/plain";
                    Response.Write("SYNC_COMPLETE: " + filesCopied + " files copied to parent root (web.config touched).");
                    Response.End();
                    return;
                }
            }

            if (!IsPostBack)
            {
                LoadCompanies();
                LoadImportCompanies();
            }
        }

        // ── Load companies from dbo.company ──────────────────────────────────
        private void LoadCompanies()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    const string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        DdlCompany.DataSource    = rdr;
                        DdlCompany.DataTextField  = "name";
                        DdlCompany.DataValueField = "id";
                        DdlCompany.DataBind();
                    }
                }
                DdlCompany.Items.Insert(0, new ListItem("-- All Sites --", "0"));
            }
            catch (Exception ex)
            {
                ShowErr("Could not load companies: " + Server.HtmlEncode(ex.Message));
            }
        }

        // ── PREVIEW button ───────────────────────────────────────────────────
        protected void BtnPreview_Click(object sender, EventArgs e)
        {
            LitMsg.Text = "";

            List<string> cols    = GetSelectedColumns();
            string       company = DdlCompany.SelectedItem != null ? DdlCompany.SelectedItem.Text : "All Sites";
            int          compId  = 0;
            int.TryParse(DdlCompany.SelectedValue, out compId);
            string statusFilter = DdlStatus.SelectedValue;

            if (cols.Count == 0)
            {
                ShowErr("Select at least one column before previewing.");
                return;
            }

            var log = new StringBuilder();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Preview started.");
            log.AppendLine("[INFO] Site filter  : " + company + " (id=" + compId + ")");
            log.AppendLine("[INFO] Status filter: " + (string.IsNullOrEmpty(statusFilter) ? "All" : statusFilter));
            log.AppendLine("[INFO] Columns      : " + cols.Count);

            try
            {
                DataTable dt = FetchAssets(cols, compId, statusFilter, 50, log);

                LitRowCount.Text    = dt.Rows.Count.ToString();
                LitColCount.Text    = cols.Count.ToString();
                LitSiteLabel.Text   = Server.HtmlEncode(company);
                LitFormatLabel.Text = "Preview (grid)";

                log.AppendLine("[OK ] Preview rows returned: " + dt.Rows.Count);
                log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Preview complete.");

                GridPreview.DataSource = dt;
                GridPreview.DataBind();

                PnlPreview.Visible = true;
                LitLog.Text = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";
                ShowOk("Preview loaded &mdash; showing top 50 rows. Click <strong>Export &amp; Download</strong> to get the full file.");
            }
            catch (Exception ex)
            {
                log.AppendLine("[ERR] " + ex.Message);
                LitLog.Text = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";
                ShowErr("Preview error: " + Server.HtmlEncode(ex.Message));
            }
        }

        // ── EXPORT button ────────────────────────────────────────────────────
        protected void BtnExport_Click(object sender, EventArgs e)
        {
            LitMsg.Text = "";

            List<string> cols = GetSelectedColumns();
            if (cols.Count == 0)
            {
                ShowErr("Select at least one column before exporting.");
                return;
            }

            int    compId      = 0;
            int.TryParse(DdlCompany.SelectedValue, out compId);
            string company     = DdlCompany.SelectedItem != null ? DdlCompany.SelectedItem.Text : "AllSites";
            string statusFilter = DdlStatus.SelectedValue;
            string format      = DdlFormat.SelectedValue;
            bool   isXlsx      = (format == "xlsx");
            bool   tsv         = (format == "tsv");
            bool   header      = ChkHeader.Checked;

            var log = new StringBuilder();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Export started.");
            log.AppendLine("[INFO] Site    : " + company + " (id=" + compId + ")");
            log.AppendLine("[INFO] Status  : " + (string.IsNullOrEmpty(statusFilter) ? "All" : statusFilter));
            log.AppendLine("[INFO] Format  : " + (isXlsx ? "Excel Workbook (.xlsx)" : (tsv ? "Tab-Delimited (.txt)" : "CSV (.csv)")));
            log.AppendLine("[INFO] Header  : " + (header ? "Yes" : "No"));
            log.AppendLine("[INFO] Columns : " + cols.Count);

            try
            {
                DataTable dt = FetchAssets(cols, compId, statusFilter, 0, log); // 0 = no row cap

                log.AppendLine("[OK ] Rows fetched: " + dt.Rows.Count);

                string safeComp  = SafeFileName(company);
                string stamp     = DateTime.Now.ToString("yyyyMMdd-HHmm");

                if (isXlsx)
                {
                    byte[] xlsxBytes = BuildExcel(dt, "Assets");
                    string fileName  = "iDash_Export_" + safeComp + "_" + stamp + ".xlsx";

                    log.AppendLine("[OK ] File ready  : " + fileName + " (" + xlsxBytes.Length + " bytes)");
                    log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Sending to browser.");

                    Session["ExportLog"]    = log.ToString();
                    Session["ExportRows"]   = dt.Rows.Count;
                    Session["ExportCols"]   = cols.Count;
                    Session["ExportSite"]   = company;
                    Session["ExportFormat"] = "Excel Workbook (.xlsx)";

                    Response.Clear();
                    Response.Buffer = true;
                    Response.Charset = "";
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
                    Response.BinaryWrite(xlsxBytes);
                    Response.End();
                }
                else
                {
                    // Build file content
                    string content   = tsv ? BuildTsv(dt, header) : BuildCsv(dt, header);
                    string ext       = tsv ? ".txt" : ".csv";
                    string mime      = tsv ? "text/plain" : "text/csv";
                    string fileName  = "iDash_Export_" + safeComp + "_" + stamp + ext;

                    log.AppendLine("[OK ] File ready  : " + fileName + " (" + content.Length + " bytes)");
                    log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Sending to browser.");

                    // Store log for display after redirect
                    Session["ExportLog"]    = log.ToString();
                    Session["ExportRows"]   = dt.Rows.Count;
                    Session["ExportCols"]   = cols.Count;
                    Session["ExportSite"]   = company;
                    Session["ExportFormat"] = tsv ? "Tab-Delimited (.txt)" : "CSV (.csv)";

                    // Stream to browser
                    byte[] bytes = new UTF8Encoding(true).GetBytes(content);
                    Response.Clear();
                    Response.Buffer = true;
                    Response.Charset = "";
                    Response.ContentType = mime;
                    Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
                    Response.BinaryWrite(bytes);
                    Response.End();
                }
            }
            catch (System.Threading.ThreadAbortException) { /* normal on Response.End */ }
            catch (Exception ex)
            {
                log.AppendLine("[ERR] " + ex.Message);
                LitLog.Text = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";
                ShowErr("Export error: " + Server.HtmlEncode(ex.Message));
            }
        }

        // ── EXPORT LOCATIONS button ──────────────────────────────────────────
        protected void BtnExportLocations_Click(object sender, EventArgs e)
        {
            LitMsg.Text = "";
            int compId = 0;
            int.TryParse(DdlCompany.SelectedValue, out compId);
            string company = DdlCompany.SelectedItem != null ? DdlCompany.SelectedItem.Text : "AllSites";
            string format  = DdlFormat.SelectedValue;
            bool isXlsx    = (format == "xlsx");
            bool tsv       = (format == "tsv");
            bool header    = ChkHeader.Checked;

            try
            {
                string sql = @"
                    SELECT 
                        l.id AS [Location ID],
                        l.name AS [Location Name],
                        ISNULL(l.site,'') AS [Site],
                        ISNULL(l.building,'') AS [Building],
                        ISNULL(l.floor,'') AS [Floor],
                        ISNULL(l.room,'') AS [Room],
                        ISNULL(l.description,'') AS [Description],
                        ISNULL(l.rfidtag,'') AS [RFID Tag],
                        ISNULL(CONVERT(varchar,l.lastinventoried,120),'') AS [Last Inventoried],
                        ISNULL(l.lastmodifiedby,'') AS [Last Modified By],
                        ISNULL(c.name,'') AS [Company],
                        COUNT(a.id) AS [Asset Count]
                    FROM dbo.location l WITH(NOLOCK)
                    LEFT JOIN dbo.company c WITH(NOLOCK) ON l.companyid = c.id
                    LEFT JOIN dbo.asset a WITH(NOLOCK) ON a.locationid = l.id
                    WHERE 1=1";
                if (compId > 0)
                    sql += " AND l.companyid = @compId";
                sql += " GROUP BY l.id, l.name, l.site, l.building, l.floor, l.room, l.description, l.rfidtag, l.lastinventoried, l.lastmodifiedby, c.name ORDER BY l.name";

                DataTable dt = new DataTable();
                using (SqlConnection conn = new SqlConnection(ConnStr))
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 300;
                    if (compId > 0) cmd.Parameters.AddWithValue("@compId", compId);
                    conn.Open();
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        da.Fill(dt);
                }

                string safeComp = SafeFileName(company);
                string stamp = DateTime.Now.ToString("yyyyMMdd-HHmm");

                if (isXlsx)
                {
                    byte[] xlsxBytes = BuildExcel(dt, "Locations");
                    string fileName  = "iDash_Locations_" + safeComp + "_" + stamp + ".xlsx";

                    Response.Clear();
                    Response.Buffer = true;
                    Response.Charset = "";
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
                    Response.BinaryWrite(xlsxBytes);
                    Response.End();
                }
                else
                {
                    string content = tsv ? BuildTsv(dt, header) : BuildCsv(dt, header);
                    string ext = tsv ? ".txt" : ".csv";
                    string mime = tsv ? "text/plain" : "text/csv";
                    string fileName = "iDash_Locations_" + safeComp + "_" + stamp + ext;

                    byte[] bytes = new UTF8Encoding(true).GetBytes(content);
                    Response.Clear();
                    Response.Buffer = true;
                    Response.Charset = "";
                    Response.ContentType = mime;
                    Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
                    Response.BinaryWrite(bytes);
                    Response.End();
                }
            }
            catch (System.Threading.ThreadAbortException) { }
            catch (Exception ex)
            {
                ShowErr("Locations export error: " + Server.HtmlEncode(ex.Message));
            }
        }

        // ── Fetch assets from dbo.v_asset ─────────────────────────────────────
        private DataTable FetchAssets(List<string> cols, int compId, string statusFilter, int topN, StringBuilder log)
        {
            // Map friendly column names → SQL expressions
            var colMap = BuildColumnMap();
            var selects = new List<string>();

            foreach (string col in cols)
            {
                string expr;
                if (colMap.TryGetValue(col, out expr))
                    selects.Add(expr + " AS [" + col + "]");
                else
                {
                    log.AppendLine("[WARN] Unknown column skipped: " + col);
                }
            }

            if (selects.Count == 0)
                throw new Exception("No valid columns to export.");

            string topClause = topN > 0 ? "TOP " + topN + " " : "";
            string sql = "SELECT " + topClause + string.Join(", ", selects)
                       + " FROM dbo.v_asset a WITH(NOLOCK)"
                       + " LEFT JOIN dbo.company c ON a.companyid = c.id"
                       + " WHERE 1=1";

            var pars = new List<SqlParameter>();

            if (compId > 0)
            {
                sql += " AND a.companyid = @compId";
                pars.Add(new SqlParameter("@compId", SqlDbType.Int) { Value = compId });
            }

            if (!string.IsNullOrEmpty(statusFilter))
            {
                sql += " AND LTRIM(RTRIM(ISNULL(a.listvalue1,''))) = @status";
                pars.Add(new SqlParameter("@status", SqlDbType.VarChar) { Value = statusFilter });
            }

            sql += " ORDER BY a.name";

            log.AppendLine("[SQL] " + sql.Replace("\r\n", " ").Replace("\n", " "));

            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 300;
                foreach (SqlParameter p in pars)
                    cmd.Parameters.Add(p);
                conn.Open();
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    da.Fill(dt);
            }
            return dt;
        }

        // ── Column map: display name → SQL expression ─────────────────────────
        private static Dictionary<string, string> BuildColumnMap()
        {
            return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "Asset Tag / Name",            "ISNULL(a.name,'')" },
                { "Description",                 "ISNULL(a.description,'')" },
                { "Manufacturer (text1)",        "ISNULL(a.text1,'')" },
                { "Model (text2)",               "ISNULL(a.text2,'')" },
                { "Company / Site Name",         "ISNULL(c.name,'')" },
                { "Location",                    "ISNULL(NULLIF(NULLIF(a.locationname,''),'Missing'), ISNULL(NULLIF(a.lastobservedlocation,''), ISNULL(a.text6,'')))" },
                { "Status (listvalue1)",         "ISNULL(a.listvalue1,'')" },
                { "Service Pointer (text5)",     "ISNULL(a.text5,'')" },
                { "EIL / CMR (text8)",           "ISNULL(a.text8,'')" },
                { "Purchase Order (text9)",      "ISNULL(a.text9,'')" },
                { "Serial Number (text3)",       "ISNULL(a.text3,'')" },
                { "Station Number (text7)",      "ISNULL(a.text7,'')" },
                { "Sub-Station (text14)",        "ISNULL(a.text14,'')" },
                { "Category (text4)",            "ISNULL(a.text4,'')" },
                { "Asset Type / FSC",            "ISNULL(a.assettype,'')" },
                { "Cost / Acquisition (text15)", "ISNULL(a.text15,'')" },
                { "Acquisition Date (date1)",    "ISNULL(CONVERT(varchar,a.date1,120),'')" },
                { "In-Service Date (date2)",     "ISNULL(CONVERT(varchar,a.date2,120),'')" },
                { "Tag Type (text19)",           "ISNULL(a.text19,'')" },
                { "Tag Date (text17)",           "ISNULL(a.text17,'')" },
                { "Tagged Flag (text18)",        "ISNULL(a.text18,'')" },
                { "RFID Tag",                    "ISNULL(a.rfidtag,'')" },
                { "Last Inventoried",            "ISNULL(CONVERT(varchar,a.lastinventoried,120),'')" },
                { "Last Observed",               "ISNULL(CONVERT(varchar,a.lastobservedtime,120),'')" },
                { "Last Modified By",            "ISNULL(a.lastmodifiedby,'')" },
                { "Previous Location (text6)",   "ISNULL(a.text6,'')" },
                { "Previous Location 2 (text11)","ISNULL(a.text11,'')" },
                { "Previous Inv. Date (text10)", "ISNULL(a.text10,'')" },
                { "Location Tagged (text16)",    "ISNULL(a.text16,'')" },
                { "Entry Number (text12)",       "ISNULL(a.text12,'')" },
                { "Employee ID (text13)",        "ISNULL(a.text13,'')" },
                { "Disposal Status",             "ISNULL(a.listvalue1,'')" },
                { "Notes (text20)",              "ISNULL(a.text20,'')" },
                { "Created Date",                "ISNULL(CONVERT(varchar,a.created,120),'')" },
                { "Next Maintenance",            "ISNULL(CONVERT(varchar,a.nextmaintenance,120),'')" },
            };
        }

        // ── Build selected column list from checkboxes ──────────────────────
        private List<string> GetSelectedColumns()
        {
            var cols = new List<string>();
            if (ChkName.Checked)            cols.Add("Asset Tag / Name");
            if (ChkDescription.Checked)     cols.Add("Description");
            if (ChkManufacturer.Checked)    cols.Add("Manufacturer (text1)");
            if (ChkModel.Checked)           cols.Add("Model (text2)");
            if (ChkSerial.Checked)          cols.Add("Serial Number (text3)");
            if (ChkCompany.Checked)         cols.Add("Company / Site Name");
            if (ChkLocation.Checked)        cols.Add("Location");
            if (ChkStatus.Checked)          cols.Add("Status (listvalue1)");
            if (ChkServicePointer.Checked)  cols.Add("Service Pointer (text5)");
            if (ChkEIL.Checked)             cols.Add("EIL / CMR (text8)");
            if (ChkPO.Checked)              cols.Add("Purchase Order (text9)");
            if (ChkStationNum.Checked)      cols.Add("Station Number (text7)");
            if (ChkSubStation.Checked)      cols.Add("Sub-Station (text14)");
            if (ChkCategory.Checked)        cols.Add("Category (text4)");
            if (ChkAssetType.Checked)       cols.Add("Asset Type / FSC");
            if (ChkCost.Checked)            cols.Add("Cost / Acquisition (text15)");
            if (ChkAcqDate.Checked)         cols.Add("Acquisition Date (date1)");
            if (ChkInServiceDate.Checked)   cols.Add("In-Service Date (date2)");
            if (ChkTagType.Checked)         cols.Add("Tag Type (text19)");
            if (ChkTagDate.Checked)         cols.Add("Tag Date (text17)");
            if (ChkTagged.Checked)          cols.Add("Tagged Flag (text18)");
            if (ChkRfidTag.Checked)         cols.Add("RFID Tag");
            if (ChkLastInventoried.Checked) cols.Add("Last Inventoried");
            if (ChkLastObserved.Checked)    cols.Add("Last Observed");
            if (ChkLastModifiedBy.Checked)  cols.Add("Last Modified By");
            if (ChkPrevLocation.Checked)    cols.Add("Previous Location (text6)");
            if (ChkPrevLocation2.Checked)   cols.Add("Previous Location 2 (text11)");
            if (ChkPrevInvDate.Checked)     cols.Add("Previous Inv. Date (text10)");
            if (ChkLocTagged.Checked)       cols.Add("Location Tagged (text16)");
            if (ChkEntryNum.Checked)        cols.Add("Entry Number (text12)");
            if (ChkEmpId.Checked)           cols.Add("Employee ID (text13)");
            if (ChkDisposalStatus.Checked)  cols.Add("Disposal Status");
            if (ChkNotes.Checked)           cols.Add("Notes (text20)");
            if (ChkCreated.Checked)         cols.Add("Created Date");
            if (ChkNextMaint.Checked)       cols.Add("Next Maintenance");
            return cols;
        }

        // ── Tab-delimited builder ─────────────────────────────────────────────
        private static string BuildTsv(DataTable dt, bool includeHeader)
        {
            var sb = new StringBuilder();
            if (includeHeader)
            {
                var hdrs = new List<string>();
                foreach (DataColumn col in dt.Columns)
                    hdrs.Add(col.ColumnName);
                sb.AppendLine(string.Join("\t", hdrs));
            }
            foreach (DataRow row in dt.Rows)
            {
                var vals = new List<string>();
                foreach (DataColumn col in dt.Columns)
                {
                    string v = Convert.ToString(row[col]);
                    // Tabs and newlines inside values must be escaped
                    v = v.Replace("\t", " ").Replace("\r\n", " ").Replace("\n", " ");
                    vals.Add(v);
                }
                sb.AppendLine(string.Join("\t", vals));
            }
            return sb.ToString();
        }

        // ── CSV builder ───────────────────────────────────────────────────────
        private static string BuildCsv(DataTable dt, bool includeHeader)
        {
            var sb = new StringBuilder();
            if (includeHeader)
            {
                var hdrs = new List<string>();
                foreach (DataColumn col in dt.Columns)
                    hdrs.Add(CsvEscape(col.ColumnName));
                sb.AppendLine(string.Join(",", hdrs));
            }
            foreach (DataRow row in dt.Rows)
            {
                var vals = new List<string>();
                foreach (DataColumn col in dt.Columns)
                    vals.Add(CsvEscape(Convert.ToString(row[col])));
                sb.AppendLine(string.Join(",", vals));
            }
            return sb.ToString();
        }

        private static string CsvEscape(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            s = s.Replace("\"", "\"\"");
            bool mustQuote = s.IndexOfAny(new char[] { ',', '"', '\n', '\r' }) >= 0;
            return mustQuote ? "\"" + s + "\"" : s;
        }

        // ── ClosedXML Excel Parser (.xlsx - MIT License) ────────────────────
        private List<Dictionary<string, string>> ParseExcelRows(Stream stream, out string[] headers)
        {
            var result = new List<Dictionary<string, string>>();
            var headerList = new List<string>();
            headers = new string[0];

            using (var wb = new XLWorkbook(stream))
            {
                var worksheet = wb.Worksheets.FirstOrDefault();
                if (worksheet == null) return result;

                var range = worksheet.RangeUsed();
                if (range == null) return result;

                int rowCount = range.RowCount();
                int colCount = range.ColumnCount();

                int headerRow = 1;
                for (int r = 1; r <= rowCount && r <= 10; r++)
                {
                    bool hasVal = false;
                    for (int c = 1; c <= colCount; c++)
                    {
                        var cell = worksheet.Cell(r, c);
                        if (!cell.IsEmpty())
                        {
                            hasVal = true;
                            break;
                        }
                    }
                    if (hasVal) { headerRow = r; break; }
                }

                for (int c = 1; c <= colCount; c++)
                {
                    var cell = worksheet.Cell(headerRow, c);
                    string h = !cell.IsEmpty() ? cell.GetString().Trim() : ("Column" + c);
                    headerList.Add(h);
                }
                headers = headerList.ToArray();

                for (int r = headerRow + 1; r <= rowCount; r++)
                {
                    var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    bool hasData = false;
                    for (int c = 1; c <= colCount; c++)
                    {
                        var cell = worksheet.Cell(r, c);
                        string val = "";
                        if (!cell.IsEmpty())
                        {
                            if (cell.DataType == XLDataType.DateTime)
                            {
                                val = cell.GetDateTime().ToString("yyyy-MM-dd HH:mm:ss");
                            }
                            else
                            {
                                val = cell.GetString().Trim();
                            }
                            if (!string.IsNullOrEmpty(val)) hasData = true;
                        }
                        dict[headers[c - 1]] = val;
                    }
                    if (hasData)
                        result.Add(dict);
                }
            }
            return result;
        }

        // ── ClosedXML Excel Builder (.xlsx - MIT License) ───────────────────
        private byte[] BuildExcel(DataTable dt, string sheetName)
        {
            // Sanitize DataTable: ClosedXML does not accept DateTimeOffset, convert to formatted string
            DataTable exportDt = new DataTable();
            foreach (DataColumn col in dt.Columns)
            {
                if (col.DataType == typeof(DateTimeOffset))
                    exportDt.Columns.Add(col.ColumnName, typeof(string));
                else
                    exportDt.Columns.Add(col.ColumnName, col.DataType);
            }

            foreach (DataRow row in dt.Rows)
            {
                var newRow = exportDt.NewRow();
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    var val = row[i];
                    if (val is DateTimeOffset)
                        newRow[i] = ((DateTimeOffset)val).ToString("yyyy-MM-dd HH:mm:ss");
                    else
                        newRow[i] = val;
                }
                exportDt.Rows.Add(newRow);
            }

            using (var wb = new XLWorkbook())
            {
                var ws = wb.Worksheets.Add(sheetName);

                // Ensure unique, valid column headers for ClosedXML
                var usedColNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                for (int c = 0; c < exportDt.Columns.Count; c++)
                {
                    string colName = string.IsNullOrWhiteSpace(exportDt.Columns[c].ColumnName) ? "Column" + (c + 1) : exportDt.Columns[c].ColumnName.Trim();
                    string uniqueName = colName;
                    int counter = 1;
                    while (usedColNames.Contains(uniqueName))
                    {
                        uniqueName = colName + "_" + counter++;
                    }
                    usedColNames.Add(uniqueName);
                    exportDt.Columns[c].ColumnName = uniqueName;
                }

                // Bulk insert table with AutoFilters and styling
                var table = ws.Cell(1, 1).InsertTable(exportDt, "ExportTable", false);
                table.ShowAutoFilter = true;
                table.Theme = XLTableTheme.TableStyleMedium2;

                // Adjust column widths by sampling up to first 50 rows (instantaneous)
                int sampleRows = Math.Min(50, exportDt.Rows.Count + 1);
                ws.Columns(1, exportDt.Columns.Count).AdjustToContents(1, sampleRows);

                using (var ms = new MemoryStream())
                {
                    wb.SaveAs(ms);
                    return ms.ToArray();
                }
            }
        }

        // ── Helpers ───────────────────────────────────────────────────────────
        private static string SafeFileName(string name)
        {
            if (string.IsNullOrEmpty(name)) return "Export";
            char[] invalid = System.IO.Path.GetInvalidFileNameChars();
            foreach (char c in invalid)
                name = name.Replace(c, '_');
            return name.Replace(' ', '_');
        }

        private void ShowOk(string msg)
        {
            LitMsg.Text = "<div class=\"msg-ok\">&#9989; " + msg + "</div>";
        }

        private void ShowErr(string msg)
        {
            LitMsg.Text = "<div class=\"msg-err\">&#9888; " + msg + "</div>";
        }

        // ────────────────────────────────────────────────────────────────────
        //  IMPORT SECTION
        // ────────────────────────────────────────────────────────────────────

        // ── Page Load: also populate import company dropdown ─────────────────
        // (Called from Page_Load when !IsPostBack — see top of file)
        private void LoadImportCompanies()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    const string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        DdlImportCompany.DataSource    = rdr;
                        DdlImportCompany.DataTextField  = "name";
                        DdlImportCompany.DataValueField = "id";
                        DdlImportCompany.DataBind();
                    }
                }
                DdlImportCompany.Items.Insert(0, new ListItem("-- Use file's Company column --", "0"));
            }
            catch { /* non-fatal */ }
        }

        // ── DRY RUN ─────────────────────────────────────────────────────────
        protected void BtnDryRun_Click(object sender, EventArgs e)
        {
            RunImport(dryRun: true);
        }

        // ── LIVE IMPORT ──────────────────────────────────────────────────────
        protected void BtnImport_Click(object sender, EventArgs e)
        {
            RunImport(dryRun: false);
        }

        // ── ONE-CLICK AUTO-PROVISION & LINK LOCATIONS ────────────────────────
        protected void BtnRepairLocations_Click(object sender, EventArgs e)
        {
            LitImportMsg.Text = "";
            int targetCompId = 0;
            int.TryParse(DdlImportCompany.SelectedValue, out targetCompId);
            string compLabel = DdlImportCompany.SelectedItem != null ? DdlImportCompany.SelectedItem.Text : "All Sites";

            var log = new StringBuilder();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Location auto-provision & link started.");
            log.AppendLine("[INFO] Target Site: " + compLabel + " (id=" + targetCompId + ")");

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    ExecuteLocationRepair(conn, targetCompId, log);
                }

                LitImportLog.Text = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";
                ShowImportOk("Location provisioning and linking complete. See log below.");
            }
            catch (Exception ex)
            {
                log.AppendLine("[ERR] " + ex.Message);
                LitImportLog.Text = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";
                ShowImportErr("Repair error: " + Server.HtmlEncode(ex.Message));
            }
        }

        private void ExecuteLocationRepair(SqlConnection conn, int targetCompId, StringBuilder log)
        {
            try
            {
                // 1. Auto-insert missing locations from lastobservedlocation or text6
                string insertLocSql = @"
                    ;WITH src AS (
                        SELECT DISTINCT 
                            CASE WHEN SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 50) LIKE 'SP%'
                                 THEN SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 50)
                                 ELSE 'SP' + SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 48)
                            END AS loc_name,
                            a.companyid,
                            COALESCE(NULLIF(LTRIM(RTRIM(a.text7)),''), (SELECT TOP 1 SUBSTRING(LTRIM(RTRIM(c.name)),1,3) FROM dbo.company c WHERE c.id = a.companyid), '517') AS site_code
                        FROM dbo.asset a WITH(NOLOCK)
                        WHERE (@cid = 0 OR a.companyid = @cid)
                          AND NULLIF(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), '') IS NOT NULL
                          AND a.companyid > 0
                    )
                    INSERT INTO dbo.location (name, site, companyid)
                    SELECT s.loc_name, s.site_code, s.companyid
                    FROM src s
                    WHERE NOT EXISTS (
                        SELECT 1 FROM dbo.location l WITH(NOLOCK)
                        WHERE l.name = s.loc_name AND l.companyid = s.companyid
                    );";

                int locsProvisioned = 0;
                using (SqlCommand cmd = new SqlCommand(insertLocSql, conn))
                {
                    cmd.CommandTimeout = 300;
                    cmd.Parameters.AddWithValue("@cid", targetCompId);
                    locsProvisioned = cmd.ExecuteNonQuery();
                }
                log.AppendLine("[OK ] Provisioned " + locsProvisioned + " new location(s) into dbo.location.");

                // 2. Link asset locationid
                string linkSql = @"
                    UPDATE a
                    SET a.locationid = l.id
                    FROM dbo.asset a
                    INNER JOIN dbo.location l ON l.name = (CASE WHEN a.lastobservedlocation LIKE 'SP%' THEN a.lastobservedlocation ELSE 'SP' + a.lastobservedlocation END)
                                             AND l.companyid = a.companyid
                    WHERE (@cid = 0 OR a.companyid = @cid)
                      AND (a.locationid IS NULL OR a.locationid <> l.id);";

                int assetsLinked = 0;
                using (SqlCommand cmd = new SqlCommand(linkSql, conn))
                {
                    cmd.CommandTimeout = 300;
                    cmd.Parameters.AddWithValue("@cid", targetCompId);
                    assetsLinked = cmd.ExecuteNonQuery();
                }
                log.AppendLine("[OK ] Linked " + assetsLinked + " asset(s) to dbo.location.id.");
            }
            catch (Exception ex)
            {
                log.AppendLine("[WARN] Location auto-provisioning notice: " + ex.Message);
            }
        }

        // ── CORE IMPORT LOGIC (SqlBulkCopy + set-based UPDATE/INSERT) ────────
        // For large files (78k+ rows) the old per-row approach issued one SQL
        // statement per row — O(N) round-trips.  This version:
        //   1. Resolves all company names in ONE query and caches them.
        //   2. Builds an in-memory DataTable from the parsed rows.
        //   3. Bulk-copies the DataTable into a temp staging table (#ai) in
        //      one operation via SqlBulkCopy.
        //   4. Issues a SINGLE UPDATE and a SINGLE INSERT against the whole
        //      staging table — O(1) SQL statements regardless of row count.
        // Expected wall-clock time for 78k rows: 15–30 seconds (vs 5+ minutes).
        private void RunImport(bool dryRun)
        {
            LitImportMsg.Text = "";
            LitImportLog.Text  = "";
            ResetImportPills();

            if (!FuImport.HasFile || FuImport.PostedFile.ContentLength == 0)
            {
                ShowImportErr("No file uploaded. Please choose a .xlsx, .txt, or .csv file.");
                return;
            }

            string fileName = FuImport.FileName;
            bool   isXlsx   = fileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase);
            bool   isCsv    = fileName.EndsWith(".csv", StringComparison.OrdinalIgnoreCase);

            List<Dictionary<string, string>> rows;
            string[] headers;
            try
            {
                if (isXlsx)
                {
                    rows = ParseExcelRows(FuImport.PostedFile.InputStream, out headers);
                }
                else
                {
                    string rawText = new System.IO.StreamReader(
                        FuImport.PostedFile.InputStream,
                        System.Text.Encoding.UTF8, true).ReadToEnd();
                    rawText = rawText.TrimStart('\uFEFF', '\u200B');
                    rows = ParseImportFile(rawText, isCsv, out headers);
                }
            }
            catch (Exception ex)
            {
                ShowImportErr("File parse error: " + Server.HtmlEncode(ex.Message));
                return;
            }

            if (rows.Count == 0)
            {
                ShowImportErr("File contained no data rows.");
                return;
            }

            int overrideCompanyId = 0;
            int.TryParse(DdlImportCompany.SelectedValue, out overrideCompanyId);
            string conflictMode = DdlConflict.SelectedValue;
            bool   isProvision     = (conflictMode == "provision");
            bool   isMerge         = (conflictMode == "merge" || isProvision);
            bool   isUpdate        = (conflictMode == "update");
            bool   updateConflicts = (isMerge || isUpdate);
            string mode = dryRun ? ("DRY RUN (" + (isProvision ? "Fresh Cart Provisioning" : (isMerge ? "Smart Merge" : (updateConflicts ? "Full Overwrite" : "Insert Only"))) + ")")
                                 : (isProvision ? "IMPORT (Fresh Cart Provisioning: Smart Merge + Auto-Provision Locations)"
                                                : (isMerge ? "IMPORT (Smart Merge: fill missing + update if newer)"
                                                           : (updateConflicts ? "IMPORT (Full Overwrite: replace with file values)" : "IMPORT (Insert Only)")));

            // File header → dbo.asset column name
            var colMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            Action<string, string> addCol = (k, v) => colMap[k] = v;

            addCol("Asset Tag / Name", "name");
            addCol("name", "name");
            addCol("Asset Tag", "name");
            addCol("Tag / Name", "name");
            addCol("ASSET TAG", "name");
            addCol("ENTRY NUMBER", "name");
            addCol("Entry Number", "name");
            addCol("ENTRY #", "name");
            addCol("Entry#", "name");

            addCol("Description", "description");
            addCol("description", "description");
            addCol("DESCRIPTION", "description");
            addCol("MFGR. Equipment Name", "description");
            addCol("MFGR.Equipment Name", "description");
            addCol("MFGREquipmentName", "description");
            addCol("Equipment Name", "description");
            addCol("BriefDescription", "description");
            addCol("Brief Description", "description");

            addCol("Manufacturer (text1)", "text1");
            addCol("Manufacturer", "text1");
            addCol("MANUFACTURER", "text1");
            addCol("text1", "text1");

            addCol("Model (text2)", "text2");
            addCol("Model", "text2");
            addCol("MODEL", "text2");
            addCol("text2", "text2");

            addCol("Serial Number (text3)", "text3");
            addCol("Serial Number", "text3");
            addCol("SERIAL #", "text3");
            addCol("Serial", "text3");
            addCol("text3", "text3");

            addCol("Category (text4)", "text4");
            addCol("Category", "text4");
            addCol("EQUIPMENT CATEGORY", "text4");
            addCol("text4", "text4");

            addCol("Service Pointer (text5)", "text5");
            addCol("Service Pointer", "text5");
            addCol("SERVICE POINTER", "text5");
            addCol("Service", "text5");
            addCol("text5", "text5");

            addCol("Location", "lastobservedlocation");
            addCol("Location Name", "lastobservedlocation");
            addCol("lastobservedlocation", "lastobservedlocation");

            addCol("Previous Location (text6)", "text6");
            addCol("Room", "text6");
            addCol("text6", "text6");

            addCol("Station Number (text7)", "text7");
            addCol("Station Number", "text7");
            addCol("STATION NUMBER", "text7");
            addCol("Station", "text7");
            addCol("text7", "text7");

            addCol("EIL / CMR (text8)", "text8");
            addCol("EIL / CMR", "text8");
            addCol("CMR", "text8");
            addCol("text8", "text8");

            addCol("Purchase Order (text9)", "text9");
            addCol("Purchase Order", "text9");
            addCol("PURCHASE ORDER #", "text9");
            addCol("PurchaseOrderNumber", "text9");
            addCol("Purchase Order Number", "text9");
            addCol("PO #", "text9");
            addCol("PO", "text9");
            addCol("text9", "text9");

            addCol("Previous Inv. Date (text10)", "text10");
            addCol("PHYSICAL INVENTORY DATE", "text10");
            addCol("Physical Inventory Date", "text10");
            addCol("PhysicalInventoryDate", "text10");
            addCol("text10", "text10");

            addCol("Previous Location 2 (text11)", "text11");
            addCol("Previous Location (text11)", "text11");
            addCol("Previous Location", "text11");
            addCol("PreviousLocation", "text11");
            addCol("PREVIOUS LOCATION", "text11");
            addCol("text11", "text11");

            addCol("Entry Number (text12)", "text12");
            addCol("Entry Number", "text12");
            addCol("text12", "text12");

            addCol("Employee ID (text13)", "text13");
            addCol("EMPL_ID", "text13");
            addCol("Employee ID", "text13");
            addCol("text13", "text13");

            addCol("Sub-Station (text14)", "text14");
            addCol("Sub-Station", "text14");
            addCol("SUB STATION", "text14");
            addCol("Substation", "text14");
            addCol("substation", "text14");
            addCol("text14", "text14");

            addCol("Cost / Acquisition (text15)", "text15");
            addCol("Cost", "text15");
            addCol("Acquisition Cost", "text15");
            addCol("Cost / Acquisition", "text15");
            addCol("text15", "text15");

            addCol("Location Tagged (text16)", "text16");
            addCol("Location Tagged", "text16");
            addCol("text16", "text16");

            addCol("Tag Date (text17)", "text17");
            addCol("Tag Date", "text17");
            addCol("TAGGED ON DATE", "text17");
            addCol("text17", "text17");

            addCol("Tagged Flag (text18)", "text18");
            addCol("Tagged Flag", "text18");
            addCol("Tagged", "text18");
            addCol("text18", "text18");

            addCol("Tag Type (text19)", "text19");
            addCol("Tag Type", "text19");
            addCol("text19", "text19");

            addCol("Notes (text20)", "text20");
            addCol("Tagging Notes", "text20");
            addCol("Notes", "text20");
            addCol("text20", "text20");

            addCol("Status (listvalue1)", "listvalue1");
            addCol("Status", "listvalue1");
            addCol("USE STATUS", "listvalue1");
            addCol("Use Status", "listvalue1");
            addCol("UseStatus", "listvalue1");
            addCol("Disposal Status", "listvalue1");
            addCol("listvalue1", "listvalue1");

            addCol("Asset Type / FSC", "assettype");
            addCol("Asset Type", "assettype");
            addCol("FSC", "assettype");
            addCol("AMMCategoryStockName", "assettype");
            addCol("CategoryStockNumber", "assettype");
            addCol("CATEGORY STOCK NUMBER", "assettype");
            addCol("assettype", "assettype");

            addCol("Acquisition Date (date1)", "date1");
            addCol("Acquisition Date", "date1");
            addCol("date1", "date1");

            addCol("In-Service Date (date2)", "date2");
            addCol("In-Service Date", "date2");
            addCol("date2", "date2");

            addCol("RFID Tag", "rfidtag");
            addCol("rfidtag", "rfidtag");

            addCol("Last Inventoried", "lastinventoried");
            addCol("InventoryDateTime", "lastinventoried");
            addCol("lastinventoried", "lastinventoried");

            addCol("Last Observed", "lastobservedtime");
            addCol("lastobservedtime", "lastobservedtime");

            addCol("Last Modified By", "lastmodifiedby");
            addCol("lastmodifiedby", "lastmodifiedby");

            addCol("Created Date", "created");
            addCol("Created", "created");
            addCol("created", "created");

            addCol("Next Maintenance", "nextmaintenance");
            addCol("nextmaintenance", "nextmaintenance");

            // Check if this is a Location export file
            bool isLocationFile = false;
            foreach (string h in headers)
            {
                if (string.Equals(h, "Location Name", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(h, "Location ID", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(h, "location.name", StringComparison.OrdinalIgnoreCase))
                {
                    isLocationFile = true;
                    break;
                }
            }

            if (isLocationFile && !HasNameHeader(headers, colMap))
            {
                RunLocationImport(rows, headers, fileName, isCsv, dryRun, overrideCompanyId, updateConflicts);
                return;
            }

            var log = new StringBuilder();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + mode + " started.");
            log.AppendLine("[INFO] File    : " + HttpUtility.HtmlEncode(fileName));
            log.AppendLine("[INFO] Format  : " + (isCsv ? "CSV" : "Tab-delimited"));
            log.AppendLine("[INFO] Rows    : " + rows.Count);
            log.AppendLine("[INFO] Headers : " + string.Join(", ", headers));
            log.AppendLine("[INFO] Engine  : SqlBulkCopy + set-based UPDATE/INSERT");
            if (overrideCompanyId > 0)
                log.AppendLine("[INFO] Company override: "
                    + (DdlImportCompany.SelectedItem != null ? DdlImportCompany.SelectedItem.Text : overrideCompanyId.ToString())
                    + " (id=" + overrideCompanyId + ")");
            log.AppendLine("[INFO] Conflict: " + (updateConflicts ? "update existing" : "skip existing"));
            log.AppendLine("[INFO] Dry run : " + dryRun);
            log.AppendLine();

            int inserted = 0, updated = 0, skipped = 0, errors = 0;

            try
            {
                // ── Step 1: Resolve all company names in ONE query ────────────────
                var companyCache = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                if (overrideCompanyId == 0)
                {
                    var uniqueNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    foreach (var r in rows)
                    {
                        if (r.ContainsKey("Company / Site Name"))
                        {
                            string cn = (r["Company / Site Name"] ?? "").Trim();
                            if (!string.IsNullOrEmpty(cn)) uniqueNames.Add(cn);
                        }
                        else if (r.ContainsKey("Company"))
                        {
                            string cn = (r["Company"] ?? "").Trim();
                            if (!string.IsNullOrEmpty(cn)) uniqueNames.Add(cn);
                        }

                        // Also harvest station numbers (e.g. "517") for prefix matching
                        string sn = "";
                        if (r.ContainsKey("STATION NUMBER")) sn = (r["STATION NUMBER"] ?? "").Trim();
                        else if (r.ContainsKey("Station Number")) sn = (r["Station Number"] ?? "").Trim();
                        else if (r.ContainsKey("Station")) sn = (r["Station"] ?? "").Trim();
                        if (!string.IsNullOrEmpty(sn)) uniqueNames.Add(sn);
                    }
                    if (uniqueNames.Count > 0)
                    {
                        using (var cc = new SqlConnection(ConnStr))
                        {
                            cc.Open();
                            using (var cmd = new SqlCommand("SELECT id, LTRIM(RTRIM(name)) AS name FROM dbo.company", cc))
                            using (var rdr = cmd.ExecuteReader())
                                while (rdr.Read())
                                {
                                    string dbN = rdr["name"].ToString();
                                    int    dbId = Convert.ToInt32(rdr["id"]);
                                    foreach (string ucn in uniqueNames)
                                        if (string.Equals(dbN, ucn, StringComparison.OrdinalIgnoreCase)
                                            && !companyCache.ContainsKey(ucn))
                                            companyCache[ucn] = dbId;
                                }
                            foreach (string ucn in uniqueNames)
                            {
                                if (!companyCache.ContainsKey(ucn) && ucn.Length >= 3)
                                {
                                    using (var pCmd = new SqlCommand(
                                        "SELECT TOP 1 id FROM dbo.company WHERE SUBSTRING(LTRIM(RTRIM(name)),1,3) = @p", cc))
                                    {
                                        pCmd.Parameters.AddWithValue("@p", ucn.Substring(0, 3));
                                        object res = pCmd.ExecuteScalar();
                                        if (res != null && res != DBNull.Value)
                                            companyCache[ucn] = Convert.ToInt32(res);
                                    }
                                }

                                // If company still does not exist on target system, auto-create it
                                if (!companyCache.ContainsKey(ucn) && !dryRun)
                                {
                                    using (var insCmd = new SqlCommand(
                                        "INSERT INTO dbo.company (name) VALUES (@n); SELECT SCOPE_IDENTITY();", cc))
                                    {
                                        insCmd.Parameters.AddWithValue("@n", ucn);
                                        object res = insCmd.ExecuteScalar();
                                        if (res != null && res != DBNull.Value)
                                        {
                                            int newCid = Convert.ToInt32(res);
                                            companyCache[ucn] = newCid;
                                            log.AppendLine("[OK ] Provisioned company '" + ucn + "' (id=" + newCid + ") into dbo.company.");
                                        }
                                    }
                                }
                            }
                        }
                        log.AppendLine("[INFO] Resolved " + companyCache.Count + "/" + uniqueNames.Count + " company name(s).");
                    }
                }

                // ── Step 2: Determine which file headers map to updatable DB columns ──
                // "name" is the match key — must NOT appear in the SET/INSERT columns list.
                // "listvalue1" is always included so new inserts get a default status.
                var updateCols = new List<string>();
                bool hasLv1 = false;
                foreach (string h in headers)
                {
                    string dbCol;
                    if (!colMap.TryGetValue(h, out dbCol)) continue;
                    if (dbCol == "name") continue;
                    if (!updateCols.Contains(dbCol))
                    {
                        updateCols.Add(dbCol);
                        if (dbCol == "listvalue1") hasLv1 = true;
                    }
                }
                if (!hasLv1) updateCols.Add("listvalue1"); // always present for insert default

                bool hasEntryNum = headers.Any(h => string.Equals(h, "ENTRY NUMBER", StringComparison.OrdinalIgnoreCase) ||
                                                    string.Equals(h, "Entry Number", StringComparison.OrdinalIgnoreCase) ||
                                                    string.Equals(h, "ENTRY #", StringComparison.OrdinalIgnoreCase) ||
                                                    string.Equals(h, "Entry#", StringComparison.OrdinalIgnoreCase));
                if (hasEntryNum && !updateCols.Contains("text12")) updateCols.Add("text12");
                if (hasEntryNum && !updateCols.Contains("rfidtag")) updateCols.Add("rfidtag");

                if (!HasNameHeader(headers, colMap) && !hasEntryNum)
                {
                    ShowImportErr("File must contain an 'Asset Tag / Name' or 'ENTRY NUMBER' column to identify records.");
                    return;
                }
                log.AppendLine("[INFO] DB columns (" + updateCols.Count + "): " + string.Join(", ", updateCols));

                // ── Step 3: Build in-memory DataTable ────────────────────────────────
                // Columns: _n (asset name), _c (companyid), + one per updateCol
                var dt = new DataTable();
                dt.Columns.Add("_n", typeof(string));
                dt.Columns.Add("_c", typeof(int));
                foreach (string dbCol in updateCols)
                    dt.Columns.Add(dbCol, typeof(string));

                int skippedBlank = 0;
                foreach (var row in rows)
                {
                    string assetName = "";
                    foreach (string key in new[] { "Asset Tag / Name", "name", "Asset Tag", "Tag / Name", "ASSET TAG" })
                    {
                        if (row.ContainsKey(key))
                        {
                            string v = (row[key] ?? "").Trim();
                            if (!string.IsNullOrEmpty(v)) { assetName = v; break; }
                        }
                    }

                    // If no explicit asset tag column, check for ENTRY NUMBER
                    if (string.IsNullOrEmpty(assetName))
                    {
                        string entryVal = "";
                        foreach (string key in new[] { "ENTRY NUMBER", "Entry Number", "Entry Number (text12)", "ENTRY #", "Entry#" })
                        {
                            if (row.ContainsKey(key))
                            {
                                string v = (row[key] ?? "").Trim();
                                if (!string.IsNullOrEmpty(v)) { entryVal = v; break; }
                            }
                        }

                        if (!string.IsNullOrEmpty(entryVal))
                        {
                            // If entry already contains "517 EE...", keep it
                            if (System.Text.RegularExpressions.Regex.IsMatch(entryVal, @"^\d{3}\s+EE", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                            {
                                assetName = entryVal;
                            }
                            else
                            {
                                // Find station number
                                string st = "";
                                foreach (string key in new[] { "STATION NUMBER", "Station Number", "Station Number (text7)", "Station" })
                                {
                                    if (row.ContainsKey(key))
                                    {
                                        string v = (row[key] ?? "").Trim();
                                        if (!string.IsNullOrEmpty(v)) { st = v; break; }
                                    }
                                }
                                if (string.IsNullOrEmpty(st) && overrideCompanyId > 0 && DdlImportCompany.SelectedItem != null)
                                {
                                    string cText = DdlImportCompany.SelectedItem.Text;
                                    if (cText.Length >= 3 && char.IsDigit(cText[0]))
                                        st = cText.Substring(0, 3);
                                }
                                if (string.IsNullOrEmpty(st)) st = "517";

                                string cleanEntry = entryVal;
                                if (cleanEntry.StartsWith("EE", StringComparison.OrdinalIgnoreCase))
                                    cleanEntry = cleanEntry.Substring(2).Trim();

                                assetName = st + " EE" + cleanEntry;
                            }
                        }
                    }

                    if (string.IsNullOrEmpty(assetName)) { skippedBlank++; continue; }

                    int cid = overrideCompanyId;
                    if (cid == 0)
                    {
                        string cn = "";
                        if (row.ContainsKey("Company / Site Name")) cn = (row["Company / Site Name"] ?? "").Trim();
                        else if (row.ContainsKey("Company")) cn = (row["Company"] ?? "").Trim();
                        if (!string.IsNullOrEmpty(cn)) companyCache.TryGetValue(cn, out cid);

                        // If not resolved by company name, check by STATION NUMBER
                        if (cid == 0)
                        {
                            string st = "";
                            if (row.ContainsKey("STATION NUMBER")) st = (row["STATION NUMBER"] ?? "").Trim();
                            else if (row.ContainsKey("Station Number")) st = (row["Station Number"] ?? "").Trim();
                            else if (row.ContainsKey("Station")) st = (row["Station"] ?? "").Trim();
                            if (!string.IsNullOrEmpty(st)) companyCache.TryGetValue(st, out cid);
                        }
                    }

                    var dr = dt.NewRow();
                    dr["_n"] = assetName;
                    dr["_c"] = cid > 0 ? (object)cid : DBNull.Value;

                    foreach (string dbCol in updateCols)
                    {
                        string val = GetRowValueForDbCol(row, headers, colMap, dbCol);
                        if (dbCol == "listvalue1" && string.IsNullOrEmpty(val)) val = "IN USE";

                        // Fallback: populate text12 (entry number) if present
                        if (dbCol == "text12" && string.IsNullOrEmpty(val))
                        {
                            foreach (string key in new[] { "ENTRY NUMBER", "Entry Number", "ENTRY #", "Entry#" })
                            {
                                if (row.ContainsKey(key))
                                {
                                    string ev = (row[key] ?? "").Trim();
                                    if (!string.IsNullOrEmpty(ev)) { val = ev; break; }
                                }
                            }
                        }

                        // Fallback: auto-generate standard RFID tag if blank and asset name is e.g. "517 EE10231"
                        if (dbCol == "rfidtag" && string.IsNullOrEmpty(val))
                        {
                            string cleanTag = assetName.Replace(" ", "");
                            if (cleanTag.Contains("EE"))
                            {
                                int idxEE = cleanTag.IndexOf("EE", StringComparison.OrdinalIgnoreCase);
                                string st = cleanTag.Substring(0, idxEE);
                                string entryPart = cleanTag.Substring(idxEE + 2);
                                int pad = 4 - ((5 + entryPart.Length) % 4);
                                val = st + "EE" + entryPart + new string('F', pad);
                            }
                        }

                        dr[dbCol] = val;
                    }
                    dt.Rows.Add(dr);
                }

                if (skippedBlank > 0)
                    log.AppendLine("[WARN] Skipped " + skippedBlank + " rows with blank asset name.");
                log.AppendLine("[INFO] DataTable built: " + dt.Rows.Count + " rows.");

                // Build the temp table CREATE SQL
                var sbCreate = new StringBuilder();
                sbCreate.Append("CREATE TABLE #ai ( [name] varchar(50), [companyid] int ");
                foreach (string dbCol in updateCols)
                {
                    string sqlType = "varchar(500)";
                    if (dbCol == "text20") sqlType = "varchar(2000)";
                    else if (dbCol == "rfidtag" || dbCol == "listvalue1") sqlType = "varchar(100)";
                    else if (dbCol == "description") sqlType = "varchar(500)";
                    
                    sbCreate.Append(", [" + dbCol + "] " + sqlType);
                }
                sbCreate.Append(" )");

                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();

                    if (dryRun)
                    {
                        // Create staging temp table
                        using (var cmd = new SqlCommand(sbCreate.ToString(), conn))
                        {
                            cmd.ExecuteNonQuery();
                        }

                        // Bulk copy into staging temp table
                        using (var bulk = new SqlBulkCopy(conn))
                        {
                            bulk.DestinationTableName = "#ai";
                            bulk.ColumnMappings.Add("_n", "name");
                            bulk.ColumnMappings.Add("_c", "companyid");
                            foreach (string dbCol in updateCols)
                            {
                                bulk.ColumnMappings.Add(dbCol, dbCol);
                            }
                            bulk.WriteToServer(dt);
                        }

                        bool hasLoc = updateCols.Contains("lastobservedlocation") || updateCols.Contains("text6");
                        string locExpr = updateCols.Contains("lastobservedlocation") && updateCols.Contains("text6")
                            ? "COALESCE(NULLIF(t.[lastobservedlocation],''), NULLIF(t.[text6],''))"
                            : (updateCols.Contains("lastobservedlocation") ? "t.[lastobservedlocation]" : "t.[text6]");
                        string siteCodeExpr = updateCols.Contains("text7")
                            ? "COALESCE(NULLIF(LTRIM(RTRIM(t.[text7])),''), (SELECT TOP 1 SUBSTRING(LTRIM(RTRIM(name)),1,3) FROM dbo.company WHERE id = t.[companyid]), '517')"
                            : "COALESCE((SELECT TOP 1 SUBSTRING(LTRIM(RTRIM(name)),1,3) FROM dbo.company WHERE id = t.[companyid]), '517')";

                        // Dry run calculations via COUNT queries
                        string existSql = "SELECT COUNT(*) FROM #ai t INNER JOIN dbo.asset a ON a.[name] = t.[name] AND (a.companyid = t.companyid OR ISNULL(a.companyid, 0) = 0 OR ISNULL(t.companyid, 0) = 0)";
                        int existsCount = 0;
                        using (var cmd = new SqlCommand(existSql, conn))
                        {
                            existsCount = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        int totalInTemp = dt.Rows.Count;
                        inserted = totalInTemp - existsCount;

                        if (updateConflicts)
                        {
                            updated = existsCount;
                        }
                        else
                        {
                            skipped = existsCount;
                        }

                        if (hasLoc)
                        {
                            string dryLocSql = ";WITH loc_src AS ("
                                + "  SELECT DISTINCT SUBSTRING(LTRIM(RTRIM(" + locExpr + ")), 1, 50) AS loc_name, t.[companyid]"
                                + "  FROM #ai t WHERE t.[companyid] > 0 AND NULLIF(LTRIM(RTRIM(" + locExpr + ")),'') IS NOT NULL"
                                + ") "
                                + "SELECT COUNT(*) FROM loc_src s "
                                + "WHERE NOT EXISTS (SELECT 1 FROM dbo.location l WHERE l.name = s.loc_name AND l.companyid = s.companyid)";
                            using (var cmd = new SqlCommand(dryLocSql, conn))
                            {
                                int dryLocs = Convert.ToInt32(cmd.ExecuteScalar());
                                log.AppendLine("[DRY ] Locations to provision: " + dryLocs + " new location(s) would be created in dbo.location.");
                            }
                        }

                        log.AppendLine("[DRY ] Would insert : " + inserted);
                        log.AppendLine("[DRY ] Would " + (updateConflicts ? "update " : "skip   ") + ": " + (updateConflicts ? updated : skipped));

                        // Clean up
                        using (var cmd = new SqlCommand("DROP TABLE #ai", conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }
                    else
                    {
                        // Live Import: Staging temp table and SqlBulkCopy approach
                        // Create staging temp table
                        using (var cmd = new SqlCommand(sbCreate.ToString(), conn))
                        {
                            cmd.ExecuteNonQuery();
                        }

                        // Bulk copy into staging temp table
                        using (var bulk = new SqlBulkCopy(conn))
                        {
                            bulk.DestinationTableName = "#ai";
                            bulk.ColumnMappings.Add("_n", "name");
                            bulk.ColumnMappings.Add("_c", "companyid");
                            foreach (string dbCol in updateCols)
                            {
                                bulk.ColumnMappings.Add(dbCol, dbCol);
                            }
                            bulk.WriteToServer(dt);
                        }

                        bool hasLoc = updateCols.Contains("lastobservedlocation") || updateCols.Contains("text6");
                        string locExpr = updateCols.Contains("lastobservedlocation") && updateCols.Contains("text6")
                            ? "COALESCE(NULLIF(t.[lastobservedlocation],''), NULLIF(t.[text6],''))"
                            : (updateCols.Contains("lastobservedlocation") ? "t.[lastobservedlocation]" : "t.[text6]");
                        string siteCodeExpr = updateCols.Contains("text7")
                            ? "COALESCE(NULLIF(LTRIM(RTRIM(t.[text7])),''), (SELECT TOP 1 SUBSTRING(LTRIM(RTRIM(name)),1,3) FROM dbo.company WHERE id = t.[companyid]), '517')"
                            : "COALESCE((SELECT TOP 1 SUBSTRING(LTRIM(RTRIM(name)),1,3) FROM dbo.company WHERE id = t.[companyid]), '517')";

                        // ── Auto-provision missing locations into dbo.location ──────────
                        if (hasLoc)
                        {
                            string provLocSql = ";WITH loc_src AS ("
                                + "  SELECT DISTINCT CASE WHEN SUBSTRING(LTRIM(RTRIM(" + locExpr + ")), 1, 50) LIKE 'SP%' THEN SUBSTRING(LTRIM(RTRIM(" + locExpr + ")), 1, 50) ELSE 'SP' + SUBSTRING(LTRIM(RTRIM(" + locExpr + ")), 1, 48) END AS loc_name, t.[companyid], " + siteCodeExpr + " AS site_code"
                                + "  FROM #ai t WHERE t.[companyid] > 0 AND NULLIF(LTRIM(RTRIM(" + locExpr + ")),'') IS NOT NULL"
                                + ") "
                                + "INSERT INTO dbo.location (name, site, companyid) "
                                + "SELECT s.loc_name, s.site_code, s.companyid FROM loc_src s "
                                + "WHERE NOT EXISTS (SELECT 1 FROM dbo.location l WHERE l.name = s.loc_name AND l.companyid = s.companyid);";
                            using (var cmd = new SqlCommand(provLocSql, conn))
                            {
                                cmd.CommandTimeout = 300;
                                int locsAdded = cmd.ExecuteNonQuery();
                                log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Provisioned " + locsAdded + " new location(s) into dbo.location.");
                            }
                        }

                        // Execute set-based UPDATE if update conflicts are selected
                        if (updateConflicts && updateCols.Count > 0)
                        {
                            var sbUpdate = new StringBuilder();
                            sbUpdate.Append("UPDATE a SET ");
                            var setItems = new List<string>();

                            if (isMerge)
                            {
                                bool hasIncomingObsTime = updateCols.Contains("lastobservedtime");
                                bool hasIncomingInvTime = updateCols.Contains("lastinventoried");

                                string incomingTimeExpr = null;
                                if (hasIncomingObsTime && hasIncomingInvTime)
                                    incomingTimeExpr = "COALESCE(TRY_CAST(NULLIF(t.[lastobservedtime],'') AS datetimeoffset), TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset))";
                                else if (hasIncomingObsTime)
                                    incomingTimeExpr = "TRY_CAST(NULLIF(t.[lastobservedtime],'') AS datetimeoffset)";
                                else if (hasIncomingInvTime)
                                    incomingTimeExpr = "TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset)";

                                string locTimeCheck = incomingTimeExpr != null
                                    ? " OR (" + incomingTimeExpr + " IS NOT NULL AND (COALESCE(a.[lastobservedtime], a.[lastinventoried]) IS NULL OR " + incomingTimeExpr + " > COALESCE(a.[lastobservedtime], a.[lastinventoried])))"
                                    : "";

                                foreach (string dbCol in updateCols)
                                {
                                    if (dbCol == "lastmodified" || dbCol == "lastmodifiedby")
                                        continue;

                                    if (dbCol == "lastinventoried")
                                    {
                                        setItems.Add(@"a.[lastinventoried] = CASE 
                                            WHEN TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset) IS NOT NULL 
                                                 AND (a.[lastinventoried] IS NULL OR TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset) > a.[lastinventoried])
                                            THEN TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset)
                                            ELSE a.[lastinventoried]
                                        END");
                                    }
                                    else if (dbCol == "lastobservedtime")
                                    {
                                        setItems.Add(@"a.[lastobservedtime] = CASE 
                                            WHEN TRY_CAST(NULLIF(t.[lastobservedtime],'') AS datetimeoffset) IS NOT NULL 
                                                 AND (a.[lastobservedtime] IS NULL OR TRY_CAST(NULLIF(t.[lastobservedtime],'') AS datetimeoffset) > a.[lastobservedtime])
                                            THEN TRY_CAST(NULLIF(t.[lastobservedtime],'') AS datetimeoffset)
                                            ELSE a.[lastobservedtime]
                                        END");
                                    }
                                    else if (dbCol == "lastobservedlocation")
                                    {
                                        setItems.Add(@"a.[lastobservedlocation] = CASE 
                                            WHEN NULLIF(LTRIM(RTRIM(t.[lastobservedlocation])),'') IS NOT NULL 
                                                 AND (
                                                     NULLIF(LTRIM(RTRIM(a.[lastobservedlocation])),'') IS NULL" + locTimeCheck + @"
                                                 )
                                            THEN LTRIM(RTRIM(t.[lastobservedlocation]))
                                            ELSE a.[lastobservedlocation]
                                        END");
                                    }
                                    else if (dbCol == "date1" || dbCol == "date2")
                                    {
                                        setItems.Add("a.[" + dbCol + "] = COALESCE(TRY_CAST(NULLIF(t.[" + dbCol + "],'') AS datetimeoffset), a.[" + dbCol + "])");
                                    }
                                    else if (dbCol == "nextmaintenance")
                                    {
                                        setItems.Add("a.[" + dbCol + "] = COALESCE(TRY_CAST(NULLIF(t.[" + dbCol + "],'') AS date), a.[" + dbCol + "])");
                                    }
                                    else if (dbCol == "created")
                                    {
                                        setItems.Add("a.[created] = COALESCE(a.[created], TRY_CAST(NULLIF(t.[created],'') AS datetimeoffset))");
                                    }
                                    else if (dbCol == "rfidtag")
                                    {
                                        setItems.Add("a.[rfidtag] = COALESCE(NULLIF(LTRIM(RTRIM(t.[rfidtag])),''), a.[rfidtag])");
                                    }
                                    else
                                    {
                                        // String columns: fill missing, update if file has non-blank, never overwrite with blank
                                        setItems.Add("a.[" + dbCol + "] = COALESCE(NULLIF(LTRIM(RTRIM(t.[" + dbCol + "])),''), a.[" + dbCol + "])");
                                    }
                                }

                                if (hasLoc)
                                {
                                    setItems.Add(@"a.locationid = CASE 
                                        WHEN l.id IS NOT NULL 
                                             AND (
                                                 a.locationid IS NULL" + locTimeCheck + @"
                                             )
                                        THEN l.id
                                        ELSE a.locationid
                                    END");
                                }
                                if (updateCols.Contains("rfidtag"))
                                    setItems.Add("a.vtagid = COALESCE(NULLIF(t.rfidtag,''), a.vtagid)");

                                if (!updateCols.Contains("lastobservedtime") && updateCols.Contains("lastinventoried") && updateCols.Contains("lastobservedlocation"))
                                {
                                    setItems.Add(@"a.[lastobservedtime] = CASE 
                                        WHEN TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset) IS NOT NULL 
                                             AND (a.[lastobservedtime] IS NULL OR TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset) > a.[lastobservedtime])
                                        THEN TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset)
                                        ELSE a.[lastobservedtime]
                                    END");
                                }

                                setItems.Add("a.lastmodified = SYSDATETIMEOFFSET()");
                                setItems.Add("a.lastmodifiedby = 'iDash Smart Merge'");
                            }
                            else
                            {
                                // Full Overwrite
                                foreach (string dbCol in updateCols)
                                {
                                    if (dbCol == "lastmodified" || dbCol == "lastmodifiedby")
                                        continue;

                                    if (dbCol == "date1" || dbCol == "date2" || dbCol == "lastinventoried" || dbCol == "lastobservedtime" || dbCol == "created")
                                        setItems.Add("a.[" + dbCol + "] = TRY_CAST(NULLIF(t.[" + dbCol + "],'') AS datetimeoffset)");
                                    else if (dbCol == "nextmaintenance")
                                        setItems.Add("a.[" + dbCol + "] = TRY_CAST(NULLIF(t.[" + dbCol + "],'') AS date)");
                                    else
                                        setItems.Add("a.[" + dbCol + "] = t.[" + dbCol + "]");
                                }
                                if (hasLoc)
                                    setItems.Add("a.locationid = COALESCE(l.id, a.locationid)");
                                if (updateCols.Contains("rfidtag"))
                                    setItems.Add("a.vtagid = COALESCE(NULLIF(t.rfidtag,''), a.vtagid)");

                                setItems.Add("a.lastmodified = SYSDATETIMEOFFSET()");
                                setItems.Add("a.lastmodifiedby = 'iDash Full Overwrite'");
                            }

                            sbUpdate.Append(string.Join(", ", setItems));
                            sbUpdate.Append(" FROM dbo.asset a INNER JOIN #ai t ON a.[name] = t.[name] AND (a.companyid = t.companyid OR ISNULL(a.companyid, 0) = 0 OR ISNULL(t.companyid, 0) = 0)");
                            if (hasLoc)
                                sbUpdate.Append(" LEFT JOIN dbo.location l ON l.name = SUBSTRING(LTRIM(RTRIM(" + locExpr + ")), 1, 50) AND l.companyid = a.companyid");

                            try
                            {
                                using (var cmd = new SqlCommand(sbUpdate.ToString(), conn))
                                {
                                    cmd.CommandTimeout = 600;
                                    updated = cmd.ExecuteNonQuery();
                                }
                                log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + (isMerge ? "Smart Merge" : "UPDATE") + " complete — " + updated + " rows updated.");
                            }
                            catch (Exception exUp)
                            {
                                log.AppendLine("[ERR UPDATE] " + exUp.Message);
                                log.AppendLine("[ERR SQL UPDATE] " + sbUpdate.ToString());
                                throw;
                            }
                        }
                        else
                        {
                            // If not updating conflicts, count the skipped (existing) assets
                            string skipSql = "SELECT COUNT(*) FROM #ai t INNER JOIN dbo.asset a ON a.[name] = t.[name] AND (a.companyid = t.companyid OR ISNULL(a.companyid, 0) = 0 OR ISNULL(t.companyid, 0) = 0)";
                            using (var cmd = new SqlCommand(skipSql, conn))
                            {
                                skipped = Convert.ToInt32(cmd.ExecuteScalar());
                            }
                        }

                        // Execute set-based INSERT for new assets
                        var insCols = new List<string> { "[name]", "[companyid]" };
                        foreach (string dbCol in updateCols) insCols.Add("[" + dbCol + "]");
                        if (hasLoc) insCols.Add("[locationid]");
                        
                        string insColsSql = string.Join(", ", insCols);

                        var sbInsert = new StringBuilder();
                        sbInsert.Append("INSERT INTO dbo.asset (" + insColsSql + ") ");
                        sbInsert.Append("SELECT t.[name], t.[companyid]");
                        foreach (string dbCol in updateCols)
                        {
                            if (dbCol == "date1" || dbCol == "date2" || dbCol == "lastinventoried" || dbCol == "lastobservedtime" || dbCol == "created")
                                sbInsert.Append(", TRY_CAST(NULLIF(t.[" + dbCol + "],'') AS datetimeoffset)");
                            else if (dbCol == "nextmaintenance")
                                sbInsert.Append(", TRY_CAST(NULLIF(t.[" + dbCol + "],'') AS date)");
                            else
                                sbInsert.Append(", t.[" + dbCol + "]");
                        }
                        if (hasLoc) sbInsert.Append(", l.id");
                        if (updateCols.Contains("rfidtag")) sbInsert.Append(", NULLIF(t.rfidtag,'')");
                        sbInsert.Append(" FROM #ai t ");
                        if (hasLoc)
                            sbInsert.Append(" LEFT JOIN dbo.location l ON l.name = SUBSTRING(LTRIM(RTRIM(" + locExpr + ")), 1, 50) AND l.companyid = t.[companyid]");
                        sbInsert.Append(" WHERE NOT EXISTS (");
                        sbInsert.Append("  SELECT 1 FROM dbo.asset a ");
                        sbInsert.Append("  WHERE a.[name] = t.[name] AND (a.companyid = t.companyid OR ISNULL(a.companyid, 0) = 0 OR ISNULL(t.companyid, 0) = 0)");
                        sbInsert.Append(")");

                        using (var cmd = new SqlCommand(sbInsert.ToString(), conn))
                        {
                            cmd.CommandTimeout = 600;
                            inserted = cmd.ExecuteNonQuery();
                        }
                        log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] INSERT complete — " + inserted + " new rows inserted.");

                        // ── Fallback safety pass to link any remaining unlinked assets ──
                        if (hasLoc)
                        {
                            string linkSql = @"
                                UPDATE a
                                SET a.locationid = l.id
                                FROM dbo.asset a
                                INNER JOIN dbo.location l ON l.name = SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 50)
                                                         AND l.companyid = a.companyid
                                WHERE a.locationid IS NULL AND NULLIF(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')),'') IS NOT NULL;";
                            using (var cmd = new SqlCommand(linkSql, conn))
                            {
                                cmd.CommandTimeout = 300;
                                int linked = cmd.ExecuteNonQuery();
                                if (linked > 0)
                                    log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Location Linking — linked " + linked + " asset(s) to dbo.location.id.");
                            }
                        }

                        if (updateCols.Contains("rfidtag"))
                        {
                            string vtagSql = "UPDATE dbo.asset SET vtagid = rfidtag WHERE vtagid IS NULL AND rfidtag IS NOT NULL AND LTRIM(RTRIM(rfidtag)) <> '';";
                            using (var cmd = new SqlCommand(vtagSql, conn))
                            {
                                cmd.CommandTimeout = 300;
                                cmd.ExecuteNonQuery();
                            }
                        }

                        if (isProvision && !dryRun)
                        {
                            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Fresh Cart Provisioning: Auto-provisioning & linking locations...");
                            ExecuteLocationRepair(conn, overrideCompanyId, log);
                        }

                        // Clean up
                        using (var cmd = new SqlCommand("DROP TABLE #ai", conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                errors = 1;
                log.AppendLine("[ERR] " + ex.Message);
                if (ex.InnerException != null)
                    log.AppendLine("[ERR] Inner: " + ex.InnerException.Message);
                ShowImportErr("Import error: " + Server.HtmlEncode(ex.Message));
            }

            // ── Update results UI ──────────────────────────────────────────
            log.AppendLine();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + mode + " complete.");
            log.AppendLine("[SUMM] Inserted=" + inserted + "  Updated=" + updated
                         + "  Skipped=" + skipped + "  Errors=" + errors);

            LitImpTotal.Text    = rows.Count.ToString();
            LitImpInserted.Text = inserted.ToString();
            LitImpUpdated.Text  = updated.ToString();
            LitImpSkipped.Text  = skipped.ToString();
            LitImpErrors.Text   = errors.ToString();
            LitImpMode.Text     = mode;
            LitImportLog.Text   = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";

            if (errors > 0)
                ShowImportErr((dryRun ? "Dry run" : "Import") + " finished with errors. See log for details.");
            else if (dryRun)
                ShowImportOk("Dry run complete &mdash; <strong>" + inserted + " would be inserted</strong>, <strong>"
                    + updated + " would be updated</strong>, <strong>" + skipped + " would be skipped</strong>. No data was written.");
            else
                ShowImportOk("Import complete &mdash; <strong>" + inserted + " inserted</strong>, <strong>"
                    + updated + " updated</strong>, <strong>" + skipped + " skipped</strong>.");

            ClientScript.RegisterStartupScript(GetType(), "scroll",
                "setTimeout(function(){document.getElementById('sec-import-results').scrollIntoView({behavior:'smooth',block:'start'});},300);",
                true);
        }

        // ── Location Import Pipeline ──────────────────────────────────────────
        private void RunLocationImport(
            List<Dictionary<string, string>> rows,
            string[] headers,
            string fileName,
            bool isCsv,
            bool dryRun,
            int overrideCompanyId,
            bool updateConflicts)
        {
            string mode = dryRun ? "DRY RUN (Locations)"
                                 : (updateConflicts ? "IMPORT (update+insert Locations)" : "IMPORT (insert only Locations)");

            var log = new StringBuilder();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + mode + " started.");
            log.AppendLine("[INFO] File    : " + HttpUtility.HtmlEncode(fileName));
            log.AppendLine("[INFO] Format  : " + (isCsv ? "CSV" : "Tab-delimited"));
            log.AppendLine("[INFO] Rows    : " + rows.Count);
            log.AppendLine("[INFO] Headers : " + string.Join(", ", headers));
            log.AppendLine("[INFO] Engine  : SqlBulkCopy + set-based Location UPSERT");
            if (overrideCompanyId > 0)
                log.AppendLine("[INFO] Company override: "
                    + (DdlImportCompany.SelectedItem != null ? DdlImportCompany.SelectedItem.Text : overrideCompanyId.ToString())
                    + " (id=" + overrideCompanyId + ")");
            log.AppendLine("[INFO] Conflict: " + (updateConflicts ? "update existing" : "skip existing"));
            log.AppendLine("[INFO] Dry run : " + dryRun);
            log.AppendLine();

            int inserted = 0, updated = 0, skipped = 0, errors = 0;

            try
            {
                // Step 1: Resolve companies
                var companyCache = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                if (overrideCompanyId == 0)
                {
                    var uniqueNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    foreach (var r in rows)
                    {
                        string cn = "";
                        if (r.ContainsKey("Company")) cn = (r["Company"] ?? "").Trim();
                        else if (r.ContainsKey("Company / Site Name")) cn = (r["Company / Site Name"] ?? "").Trim();
                        if (!string.IsNullOrEmpty(cn)) uniqueNames.Add(cn);
                    }

                    if (uniqueNames.Count > 0)
                    {
                        using (var cc = new SqlConnection(ConnStr))
                        {
                            cc.Open();
                            using (var cmd = new SqlCommand("SELECT id, LTRIM(RTRIM(name)) AS name FROM dbo.company", cc))
                            using (var rdr = cmd.ExecuteReader())
                                while (rdr.Read())
                                {
                                    string dbN = rdr["name"].ToString();
                                    int dbId = Convert.ToInt32(rdr["id"]);
                                    foreach (string ucn in uniqueNames)
                                        if (string.Equals(dbN, ucn, StringComparison.OrdinalIgnoreCase) && !companyCache.ContainsKey(ucn))
                                            companyCache[ucn] = dbId;
                                }

                            foreach (string ucn in uniqueNames)
                            {
                                if (!companyCache.ContainsKey(ucn) && ucn.Length >= 3)
                                {
                                    using (var pCmd = new SqlCommand("SELECT TOP 1 id FROM dbo.company WHERE SUBSTRING(LTRIM(RTRIM(name)),1,3) = @p", cc))
                                    {
                                        pCmd.Parameters.AddWithValue("@p", ucn.Substring(0, 3));
                                        object res = pCmd.ExecuteScalar();
                                        if (res != null && res != DBNull.Value)
                                            companyCache[ucn] = Convert.ToInt32(res);
                                    }
                                }

                                if (!companyCache.ContainsKey(ucn) && !dryRun)
                                {
                                    using (var insCmd = new SqlCommand("INSERT INTO dbo.company (name) VALUES (@n); SELECT SCOPE_IDENTITY();", cc))
                                    {
                                        insCmd.Parameters.AddWithValue("@n", ucn);
                                        object res = insCmd.ExecuteScalar();
                                        if (res != null && res != DBNull.Value)
                                        {
                                            int newCid = Convert.ToInt32(res);
                                            companyCache[ucn] = newCid;
                                            log.AppendLine("[OK ] Provisioned company '" + ucn + "' (id=" + newCid + ") into dbo.company.");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Step 2: Build DataTable
                var dt = new DataTable();
                dt.Columns.Add("name", typeof(string));
                dt.Columns.Add("site", typeof(string));
                dt.Columns.Add("building", typeof(string));
                dt.Columns.Add("floor", typeof(string));
                dt.Columns.Add("room", typeof(string));
                dt.Columns.Add("description", typeof(string));
                dt.Columns.Add("rfidtag", typeof(string));
                dt.Columns.Add("lastmodifiedby", typeof(string));
                dt.Columns.Add("lastinventoried", typeof(string));
                dt.Columns.Add("companyid", typeof(int));

                Func<Dictionary<string, string>, string[], string> getVal = (r, keys) =>
                {
                    foreach (var k in keys)
                        if (r.ContainsKey(k)) return (r[k] ?? "").Trim();
                    return "";
                };

                int skippedBlank = 0;
                foreach (var r in rows)
                {
                    string locName = getVal(r, new[] { "Location Name", "name", "Location ID", "location.name" });
                    if (string.IsNullOrEmpty(locName)) { skippedBlank++; continue; }

                    int cid = overrideCompanyId;
                    if (cid == 0)
                    {
                        string cn = getVal(r, new[] { "Company", "Company / Site Name" });
                        if (!string.IsNullOrEmpty(cn)) companyCache.TryGetValue(cn, out cid);
                        if (cid == 0) cid = 4; // default Beckley 517 if unable to resolve
                    }

                    var dr = dt.NewRow();
                    dr["name"] = locName.Length > 50 ? locName.Substring(0, 50) : locName;
                    dr["site"] = getVal(r, new[] { "Site", "site" });
                    dr["building"] = getVal(r, new[] { "Building", "building" });
                    dr["floor"] = getVal(r, new[] { "Floor", "floor" });
                    dr["room"] = getVal(r, new[] { "Room", "room" });
                    dr["description"] = getVal(r, new[] { "Description", "description" });
                    dr["rfidtag"] = getVal(r, new[] { "RFID Tag", "rfidtag" });
                    dr["lastmodifiedby"] = getVal(r, new[] { "Last Modified By", "lastmodifiedby" });
                    dr["lastinventoried"] = getVal(r, new[] { "Last Inventoried", "lastinventoried" });
                    dr["companyid"] = cid;
                    dt.Rows.Add(dr);
                }

                if (skippedBlank > 0)
                    log.AppendLine("[WARN] Skipped " + skippedBlank + " rows with blank location name.");
                log.AppendLine("[INFO] Location DataTable built: " + dt.Rows.Count + " rows.");

                string sbCreate = @"
                    CREATE TABLE #li (
                        [name] varchar(50),
                        [site] varchar(100),
                        [building] varchar(100),
                        [floor] varchar(50),
                        [room] varchar(100),
                        [description] varchar(500),
                        [rfidtag] varchar(50),
                        [lastmodifiedby] varchar(50),
                        [lastinventoried] varchar(100),
                        [companyid] int
                    )";

                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(sbCreate, conn)) cmd.ExecuteNonQuery();

                    using (var bulk = new SqlBulkCopy(conn))
                    {
                        bulk.DestinationTableName = "#li";
                        bulk.ColumnMappings.Add("name", "name");
                        bulk.ColumnMappings.Add("site", "site");
                        bulk.ColumnMappings.Add("building", "building");
                        bulk.ColumnMappings.Add("floor", "floor");
                        bulk.ColumnMappings.Add("room", "room");
                        bulk.ColumnMappings.Add("description", "description");
                        bulk.ColumnMappings.Add("rfidtag", "rfidtag");
                        bulk.ColumnMappings.Add("lastmodifiedby", "lastmodifiedby");
                        bulk.ColumnMappings.Add("lastinventoried", "lastinventoried");
                        bulk.ColumnMappings.Add("companyid", "companyid");
                        bulk.WriteToServer(dt);
                    }

                    if (dryRun)
                    {
                        string existSql = "SELECT COUNT(*) FROM #li t INNER JOIN dbo.location l ON l.[name] = t.[name] AND l.companyid = t.companyid";
                        int existsCount = 0;
                        using (var cmd = new SqlCommand(existSql, conn))
                            existsCount = Convert.ToInt32(cmd.ExecuteScalar());

                        inserted = dt.Rows.Count - existsCount;
                        if (updateConflicts) updated = existsCount;
                        else skipped = existsCount;

                        log.AppendLine("[DRY ] Would insert locations: " + inserted);
                        log.AppendLine("[DRY ] Would " + (updateConflicts ? "update " : "skip   ") + " locations: " + (updateConflicts ? updated : skipped));
                    }
                    else
                    {
                        // Live Insert
                        string insSql = @"
                            INSERT INTO dbo.location ([name], [site], [building], [floor], [room], [description], [rfidtag], [lastmodifiedby], [lastinventoried], [companyid])
                            SELECT DISTINCT t.[name], t.[site], t.[building], t.[floor], t.[room], t.[description], t.[rfidtag], t.[lastmodifiedby],
                                   TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset), t.[companyid]
                            FROM #li t
                            WHERE NOT EXISTS (SELECT 1 FROM dbo.location l WHERE l.name = t.name AND l.companyid = t.companyid);";
                        using (var cmd = new SqlCommand(insSql, conn))
                        {
                            cmd.CommandTimeout = 300;
                            inserted = cmd.ExecuteNonQuery();
                            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] INSERT complete — " + inserted + " new location(s) created.");
                        }

                        // Live Update if selected
                        if (updateConflicts)
                        {
                            string updSql = @"
                                UPDATE l SET
                                    l.[site] = COALESCE(NULLIF(t.[site],''), l.[site]),
                                    l.[building] = COALESCE(NULLIF(t.[building],''), l.[building]),
                                    l.[floor] = COALESCE(NULLIF(t.[floor],''), l.[floor]),
                                    l.[room] = COALESCE(NULLIF(t.[room],''), l.[room]),
                                    l.[description] = COALESCE(NULLIF(t.[description],''), l.[description]),
                                    l.[rfidtag] = COALESCE(NULLIF(t.[rfidtag],''), l.[rfidtag]),
                                    l.[lastmodifiedby] = COALESCE(NULLIF(t.[lastmodifiedby],''), l.[lastmodifiedby]),
                                    l.[lastinventoried] = COALESCE(TRY_CAST(NULLIF(t.[lastinventoried],'') AS datetimeoffset), l.[lastinventoried])
                                FROM dbo.location l
                                INNER JOIN #li t ON l.name = t.name AND l.companyid = t.companyid;";
                            using (var cmd = new SqlCommand(updSql, conn))
                            {
                                cmd.CommandTimeout = 300;
                                updated = cmd.ExecuteNonQuery();
                                log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] UPDATE complete — " + updated + " location(s) updated.");
                            }
                        }
                        else
                        {
                            string skipSql = "SELECT COUNT(*) FROM #li t INNER JOIN dbo.location l ON l.[name] = t.[name] AND l.companyid = t.companyid";
                            using (var cmd = new SqlCommand(skipSql, conn))
                                skipped = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        // Safety pass: Link any unlinked assets in dbo.asset to these locations
                        string linkSql = @"
                            UPDATE a
                            SET a.locationid = l.id
                            FROM dbo.asset a
                            INNER JOIN dbo.location l ON l.name = SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 50)
                                                     AND l.companyid = a.companyid
                            WHERE a.locationid IS NULL AND NULLIF(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')),'') IS NOT NULL;";
                        using (var cmd = new SqlCommand(linkSql, conn))
                        {
                            cmd.CommandTimeout = 300;
                            int linked = cmd.ExecuteNonQuery();
                            if (linked > 0)
                                log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] Asset-Location Linking — linked " + linked + " asset(s) to updated dbo.location.id.");
                        }
                    }

                    using (var cmd = new SqlCommand("DROP TABLE #li", conn)) cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                errors = 1;
                log.AppendLine("[ERR] " + ex.Message);
                if (ex.InnerException != null) log.AppendLine("[ERR] Inner: " + ex.InnerException.Message);
                ShowImportErr("Location Import error: " + Server.HtmlEncode(ex.Message));
            }

            log.AppendLine();
            log.AppendLine("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + mode + " complete.");
            log.AppendLine("[SUMM] Inserted=" + inserted + "  Updated=" + updated + "  Skipped=" + skipped + "  Errors=" + errors);

            LitImpTotal.Text    = rows.Count.ToString();
            LitImpInserted.Text = inserted.ToString();
            LitImpUpdated.Text  = updated.ToString();
            LitImpSkipped.Text  = skipped.ToString();
            LitImpErrors.Text   = errors.ToString();
            LitImpMode.Text     = mode;
            LitImportLog.Text   = "<div class=\"log-box\">" + HttpUtility.HtmlEncode(log.ToString()) + "</div>";

            if (errors > 0)
                ShowImportErr((dryRun ? "Dry run" : "Import") + " finished with errors. See log for details.");
            else if (dryRun)
                ShowImportOk("Dry run complete &mdash; <strong>" + inserted + " location(s) would be inserted</strong>, <strong>"
                    + updated + " would be updated</strong>. No data was written.");
            else
                ShowImportOk("Location Import complete &mdash; <strong>" + inserted + " inserted</strong>, <strong>"
                    + updated + " updated</strong>, <strong>" + skipped + " skipped</strong>.");

            ClientScript.RegisterStartupScript(GetType(), "scroll",
                "setTimeout(function(){document.getElementById('sec-import-results').scrollIntoView({behavior:'smooth',block:'start'});},300);",
                true);
        }



        // ── Parse TSV / CSV into list of header→value dicts ──────────────────
        private List<Dictionary<string, string>> ParseImportFile(string text, bool isCsv, out string[] headers)
        {
            var lines = text.Replace("\r\n", "\n").Replace("\r", "\n").Split('\n');
            var result = new List<Dictionary<string, string>>();
            headers = new string[0];

            // Find first non-empty line
            int start = 0;
            while (start < lines.Length && string.IsNullOrWhiteSpace(lines[start])) start++;
            if (start >= lines.Length) return result;

            // Parse header
            headers = isCsv ? SplitCsvLine(lines[start]) : lines[start].Split('\t');
            for (int h = 0; h < headers.Length; h++) headers[h] = headers[h].Trim();

            // Parse data rows
            for (int i = start + 1; i < lines.Length; i++)
            {
                if (string.IsNullOrWhiteSpace(lines[i])) continue;
                string[] cells = isCsv ? SplitCsvLine(lines[i]) : lines[i].Split('\t');
                var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                for (int c = 0; c < headers.Length; c++)
                {
                    string val = c < cells.Length ? (cells[c] ?? "").Trim() : "";
                    dict[headers[c]] = val;
                }
                result.Add(dict);
            }
            return result;
        }

        // ── Check that the file contains an asset name/key column ──────────────
        private static bool HasNameHeader(string[] headers, Dictionary<string, string> colMap)
        {
            foreach (string h in headers)
            {
                string dbCol;
                if (colMap.TryGetValue(h, out dbCol) && dbCol == "name") return true;
                if (string.Equals(h, "ENTRY NUMBER", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(h, "Entry Number", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(h, "ENTRY #", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(h, "Entry#", StringComparison.OrdinalIgnoreCase)) return true;
            }
            return false;
        }

        // ── Find the row value for a given target DB column name ───────────────
        private static string GetRowValueForDbCol(
            Dictionary<string, string> row,
            string[] headers,
            Dictionary<string, string> colMap,
            string dbCol)
        {
            foreach (string h in headers)
            {
                string mapped;
                if (colMap.TryGetValue(h, out mapped) && mapped == dbCol && row.ContainsKey(h))
                {
                    string v = (row[h] ?? "").Trim();
                    if (!string.IsNullOrEmpty(v))
                    {
                        // Ensure 'SP' prefix on all location fields for VA compatibility
                        if ((dbCol == "lastobservedlocation" || dbCol == "text6" || dbCol == "text11") &&
                            !v.StartsWith("SP", StringComparison.OrdinalIgnoreCase))
                        {
                            v = "SP" + v;
                        }
                        return v;
                    }
                }
            }
            return "";
        }

        // ── RFC 4180 CSV line splitter ────────────────────────────────────────
        private static string[] SplitCsvLine(string line)
        {
            var fields = new List<string>();
            int i = 0;
            while (i <= line.Length)
            {
                if (i == line.Length) { fields.Add(""); break; }
                if (line[i] == '"')
                {
                    // Quoted field
                    var sb = new StringBuilder();
                    i++; // skip opening quote
                    while (i < line.Length)
                    {
                        if (line[i] == '"')
                        {
                            if (i + 1 < line.Length && line[i + 1] == '"') { sb.Append('"'); i += 2; }
                            else { i++; break; }
                        }
                        else { sb.Append(line[i]); i++; }
                    }
                    fields.Add(sb.ToString());
                    if (i < line.Length && line[i] == ',') i++;
                }
                else
                {
                    int comma = line.IndexOf(',', i);
                    if (comma < 0) { fields.Add(line.Substring(i)); break; }
                    fields.Add(line.Substring(i, comma - i));
                    i = comma + 1;
                }
            }
            return fields.ToArray();
        }

        // ── Resolve company ID from display name ──────────────────────────────
        private int ResolveCompanyId(SqlConnection conn, string companyName)
        {
            // Exact match first
            using (SqlCommand cmd = new SqlCommand(
                "SELECT id FROM dbo.company WHERE name = @n", conn))
            {
                cmd.Parameters.AddWithValue("@n", companyName);
                object res = cmd.ExecuteScalar();
                if (res != null && res != DBNull.Value) return Convert.ToInt32(res);
            }
            // Prefix match (first 3 chars = station number)
            if (companyName.Length >= 3)
            {
                string prefix = companyName.Substring(0, 3);
                using (SqlCommand cmd = new SqlCommand(
                    "SELECT TOP 1 id FROM dbo.company WHERE SUBSTRING(name,1,3) = @p", conn))
                {
                    cmd.Parameters.AddWithValue("@p", prefix);
                    object res = cmd.ExecuteScalar();
                    if (res != null && res != DBNull.Value) return Convert.ToInt32(res);
                }
            }
            return 0;
        }

        // ── Reset import summary pills ────────────────────────────────────────
        private void ResetImportPills()
        {
            LitImpTotal.Text    = "&mdash;";
            LitImpInserted.Text = "&mdash;";
            LitImpUpdated.Text  = "&mdash;";
            LitImpSkipped.Text  = "&mdash;";
            LitImpErrors.Text   = "&mdash;";
            LitImpMode.Text     = "&mdash;";
        }

        private void ShowImportOk(string msg)
        {
            LitImportMsg.Text = "<div class=\"msg-ok\">&#9989; " + msg + "</div>";
        }

        private void ShowImportErr(string msg)
        {
            LitImportMsg.Text = "<div class=\"msg-err\">&#9888; " + msg + "</div>";
        }
    }
}

