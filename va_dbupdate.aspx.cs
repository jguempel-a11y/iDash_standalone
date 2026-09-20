using System;
using System.Linq;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.IO;
using ClosedXML.Excel;

public partial class va_dbupdate : System.Web.UI.Page
{
    private const string SummarySessionKey = "VA_DBUPDATE_SUMMARY";

    // The root directory where SQL scripts and data files live
    private string AppRoot { get { return Server.MapPath("~/"); } }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            BtnDownloadSummary.Enabled = false;
            PopulateFileDropdowns();
        }
    }

    private void PopulateFileDropdowns()
    {
        string root = AppRoot;

        // --- SQL Scripts ---
        DdlSqlScript.Items.Clear();
        DdlSqlScript.Items.Add(new ListItem("-- Select SQL Script --", ""));
        if (Directory.Exists(root))
        {
            var sqlFiles = Directory.GetFiles(root, "*.sql")
                .Select(f => Path.GetFileName(f))
                .OrderBy(f => f, StringComparer.OrdinalIgnoreCase);
            foreach (string f in sqlFiles)
                DdlSqlScript.Items.Add(new ListItem(f, f));
        }

        // --- Data Files (.xlsx and .txt) ---
        DdlDataFile.Items.Clear();
        DdlDataFile.Items.Add(new ListItem("-- Select Data File --", ""));
        if (Directory.Exists(root))
        {
            var dataFiles = Directory.GetFiles(root)
                .Where(f =>
                {
                    string ext = Path.GetExtension(f).ToLowerInvariant();
                    return ext == ".xlsx" || ext == ".txt";
                })
                .Select(f => Path.GetFileName(f))
                .OrderBy(f => f, StringComparer.OrdinalIgnoreCase);
            foreach (string f in dataFiles)
                DdlDataFile.Items.Add(new ListItem(f, f));
        }
    }

    protected void BtnRefreshFiles_Click(object sender, EventArgs e)
    {
        PopulateFileDropdowns();
    }

    protected void DdlDataFile_SelectedIndexChanged(object sender, EventArgs e)
    {
        // Quick row count when a data file is selected — sets the hidden field
        // so the progress panel can display rows + estimated time before Run
        HidRowCount.Value = "0";
        if (string.IsNullOrEmpty(DdlDataFile.SelectedValue)) return;

        string filePath = Path.Combine(AppRoot, DdlDataFile.SelectedValue);
        if (!File.Exists(filePath)) return;

        try
        {
            string ext = Path.GetExtension(filePath).ToLowerInvariant();
            int lineCount = 0;

            if (ext == ".xlsx")
            {
                // For XLSX, count worksheet rows via ClosedXML
                using (var pkg = new XLWorkbook(filePath))
                {
                    var ws = pkg.Worksheet(1);
                    var range = ws.RangeUsed();
                    lineCount = range != null ? range.RowCount() - 1 : 0; // minus header
                }
            }
            else
            {
                // For TXT, count lines
                lineCount = File.ReadAllLines(filePath).Length;
                if (lineCount > 0) lineCount--; // minus header
            }

            HidRowCount.Value = lineCount.ToString();

            // Show a quick summary beneath the dropdown
            string estimate = "Under 30 seconds";
            if (lineCount >= 5000) estimate = "30 seconds - 1 minute";
            if (lineCount >= 15000) estimate = "1 - 3 minutes";
            if (lineCount >= 30000) estimate = "3 - 5 minutes";
            if (lineCount >= 60000) estimate = "5 - 10 minutes";
            if (lineCount >= 100000) estimate = "10+ minutes";

            LitRowInfo.Text = "<div style='margin-top:8px; padding:8px 12px; border-radius:5px; font-size:13px; "
                + "background:color-mix(in srgb, var(--accent), transparent 90%); border:1px solid color-mix(in srgb, var(--accent), transparent 70%);'>"
                + "&#128202; <strong>" + lineCount.ToString("N0") + " data rows</strong> &mdash; estimated processing time: <strong>" + estimate + "</strong>"
                + "</div>";
        }
        catch { /* non-critical, keep HidRowCount at 0 */ }
    }

    protected void BtnRunSql_Click(object sender, EventArgs e)
    {
        ExecuteUpdate(false);
    }

    protected void BtnPreviewRun_Click(object sender, EventArgs e)
    {
        ExecuteUpdate(true);
    }
    
    private void ExecuteUpdate(bool isPreview)
    {
        // Allow up to 30 minutes for large imports (80K+ rows)
        // Default ASP.NET timeout is 110 seconds which silently kills the request
        Server.ScriptTimeout = 1800;

        LitSummary.Text = "";
        LitPreviewTable.Text = "";
        LitSqlResult.Text = "";
        LitSqlNote.Text = "";
        Session[SummarySessionKey] = null;
        BtnDownloadSummary.Enabled = false;

        // --- Resolve SQL script: manual upload takes priority, then dropdown ---
        byte[] sqlBytes = null;
        string sqlSourceName = "";

        if (FileSqlUpload.HasFile)
        {
            sqlBytes = FileSqlUpload.FileBytes;
            sqlSourceName = FileSqlUpload.FileName;
        }
        else if (!string.IsNullOrEmpty(DdlSqlScript.SelectedValue))
        {
            string sqlPath = Path.Combine(AppRoot, DdlSqlScript.SelectedValue);
            if (File.Exists(sqlPath))
            {
                sqlBytes = File.ReadAllBytes(sqlPath);
                sqlSourceName = DdlSqlScript.SelectedValue;
            }
            else
            {
                LitSqlResult.Text = "<div class='err'>SQL file not found on server: " + HttpUtility.HtmlEncode(DdlSqlScript.SelectedValue) + "</div>";
                return;
            }
        }
        else
        {
            LitSqlResult.Text = "<div class='err'>No SQL script selected. Choose a script from the dropdown or upload one manually.</div>";
            return;
        }

        // --- Resolve data file: manual upload takes priority, then dropdown ---
        byte[] dataBytes = null;
        string dataSourceName = "";

        if (FileDataUpload.HasFile)
        {
            dataBytes = FileDataUpload.FileBytes;
            dataSourceName = FileDataUpload.FileName;
        }
        else if (!string.IsNullOrEmpty(DdlDataFile.SelectedValue))
        {
            string dataPath = Path.Combine(AppRoot, DdlDataFile.SelectedValue);
            if (File.Exists(dataPath))
            {
                dataBytes = File.ReadAllBytes(dataPath);
                dataSourceName = DdlDataFile.SelectedValue;
            }
            else
            {
                LitSqlResult.Text = "<div class='err'>Data file not found on server: " + HttpUtility.HtmlEncode(DdlDataFile.SelectedValue) + "</div>";
                return;
            }
        }
        else
        {
            LitSqlResult.Text = "<div class='err'>No data file selected. Choose a data file from the dropdown or upload one manually.</div>";
            return;
        }

        // ? Read SQL text (preserve exactly, then sanitize)
        string sqlText = Encoding.UTF8.GetString(sqlBytes);

        // ? Strip BOM / zero-width chars that cause: Incorrect syntax near '?'
        sqlText = StripInvisible(sqlText);

        // Safety for DROP/TRUNCATE/ALTER
        if (!ChkAllowDangerous.Checked)
        {
            string lower = sqlText.ToLowerInvariant();
            if (lower.Contains("drop ") || lower.Contains("truncate ") || lower.Contains("alter "))
            {
                LitSqlResult.Text = "<div class='err'>Blocked unsafe SQL command.</div>";
                return;
            }
        }

        // Prepare data file path
        string tempDir = Server.MapPath("~/temp/");
        if (!Directory.Exists(tempDir))
            Directory.CreateDirectory(tempDir);

        string ext = Path.GetExtension(dataSourceName).ToLowerInvariant();
        string dataPath2 = Path.Combine(tempDir, "data_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt");

        try
        {
            if (ext == ".xlsx")
            {
                ConvertXlsxToTxt(dataBytes, dataPath2);
            }
            else
            {
                StandardizeTextFile(dataBytes, dataPath2);
            }
        }
        catch (Exception ex)
        {
            LitSqlResult.Text = "<div class='err'>Data file conversion failed: "
                                + HttpUtility.HtmlEncode(ex.Message) + "</div>";
            return;
        }

        // ? Count rows in the converted data file (subtract 1 for header)
        int rowCount = 0;
        try
        {
            rowCount = File.ReadAllLines(dataPath2).Length;
            if (rowCount > 0) rowCount--; // exclude header row
        }
        catch { /* non-critical */ }
        HidRowCount.Value = rowCount.ToString();

        // ? Replace token
        string safeDataPathForSql = dataPath2.Replace("'", "''");
        sqlText = sqlText.Replace("{{DATAFILE}}", safeDataPathForSql);

        // ? Safety: strip invisible again
        sqlText = StripInvisible(sqlText);

        // NOTE: you had "idash" here; leaving as-is
        string connString = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        DataTable stats = null;
        DataTable preview = null;
        StringBuilder summaryBuilder = new StringBuilder();

        try
        {
            using (SqlConnection conn = new SqlConnection(connString))
            {
                conn.Open();
                using (SqlTransaction tran = conn.BeginTransaction())
                {
                    try
                    {
                        stats = RunSqlBatches(sqlText, conn, tran, summaryBuilder, out preview);

                        if (isPreview)
                        {
                            tran.Rollback();
                        }
                        else
                        {
                            tran.Commit();
                        }
                    }
                    catch
                    {
                        tran.Rollback();
                        throw;
                    }
                }
            }

            // Build summary HTML
            StringBuilder sb = new StringBuilder();
            
            if (isPreview)
                sb.Append("<div class='warn'><b>&#9888; DB Preview Run Completed (Updates Rolled Back)</b><br/>");
            else
                sb.Append("<div class='ok'><b>DB Update Completed</b><br/>");

            if (stats != null && stats.Rows.Count > 0)
            {
                DataRow r = stats.Rows[0];

                // Support BOTH your aliased final SELECT and older raw columns
                sb.Append("Locations Inserted: " + SafeGetIntAny(r, "Locations Inserted", "LocInserted") + "<br/>");
                sb.Append("Assets Inserted: " + SafeGetIntAny(r, "Assets Inserted", "AssetInserted") + "<br/>");
                sb.Append("Assets Updated: " + SafeGetIntAny(r, "Assets Updated (total)", "AssetUpdated", "Assets Updated/Enriched") + "<br/>");
                sb.Append("Assets Skipped: " + SafeGetIntAny(r, "Assets Skipped (duplicates)", "AssetSkipped") + "<br/>");
                sb.Append("Errors: " + SafeGetIntAny(r, "Errors", "Errors") + "<br/>");
            }
            else
            {
                sb.Append("No ImportStats returned.<br/>");
            }

            sb.Append("</div>");
            LitSummary.Text = sb.ToString();

            // Build Preview Table HTML
            if (preview != null && preview.Rows.Count > 0)
            {
                StringBuilder pt = new StringBuilder();
                pt.Append("<div class='card' style='margin-top:20px; border-color:#1f2a44; padding:20px; border-radius:8px; background:#0e1729;'>");
                pt.Append("<h3 style='margin-top:0; margin-bottom:15px; color:#f59e0b;'>Selected Data Modifications (First 25)</h3>");
                pt.Append("<table style='width:100%; border-collapse:collapse; font-size:13px; text-align:left;'>");
                pt.Append("<tr style='border-bottom:1px solid #1f2a44; color:#8aa0c5;'><th style='padding:8px 8px 8px 0;'>Action</th><th style='padding:8px;'>Name</th><th style='padding:8px;'>RFID</th><th style='padding:8px;'>Description</th><th style='padding:8px;'>Location</th></tr>");
                foreach (DataRow pr in preview.Rows)
                {
                    pt.Append("<tr style='border-bottom:1px solid rgba(255,255,255,0.03);'>");
                    pt.Append("<td style='padding:8px 8px 8px 0;'><span class='chip' style='background:rgba(255,255,255,0.05); color:#a7f3d0; font-weight:600; font-size:11px;'>" + HttpUtility.HtmlEncode(pr["Action"]) + "</span></td>");
                    pt.Append("<td style='padding:8px; font-weight:bold; color:#fff;'>" + HttpUtility.HtmlEncode(pr["Name"]) + "</td>");
                    pt.Append("<td style='padding:8px; font-family:Consolas,monospace; color:#8aa0c5;'>" + HttpUtility.HtmlEncode(pr["RFID"]) + "</td>");
                    pt.Append("<td style='padding:8px;'>" + HttpUtility.HtmlEncode(pr["Description"]) + "</td>");
                    pt.Append("<td style='padding:8px;'>" + HttpUtility.HtmlEncode(pr["LastObservedLocation"]) + "</td>");
                    pt.Append("</tr>");
                }
                pt.Append("</table></div>");
                LitPreviewTable.Text = pt.ToString();
            }

            // Save downloadable summary
            StringBuilder dl = new StringBuilder();
            dl.AppendLine(isPreview ? "VA DB Preview Summary (DRY RUN) - " + DateTime.Now.ToString() : "VA DB Update Summary - " + DateTime.Now.ToString());
            dl.AppendLine("Data file: " + dataPath2);
            dl.AppendLine();
            dl.AppendLine(summaryBuilder.ToString());

            Session[SummarySessionKey] = dl.ToString();
            BtnDownloadSummary.Enabled = true;

            LitSqlResult.Text = "<div class='ok'>Script executed successfully.</div>";
        }
        catch (Exception ex)
        {
            LitSqlResult.Text = "<div class='err'>" + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnDownloadSummary_Click(object sender, EventArgs e)
    {
        string text = Session[SummarySessionKey] as string;
        if (string.IsNullOrEmpty(text))
        {
            LitSqlNote.Text = "<div class='err'>No summary available.</div>";
            return;
        }

        byte[] bytes = Encoding.UTF8.GetBytes(text);

        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition",
            "attachment; filename=VA_DBUpdate_Summary_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt");
        Response.BinaryWrite(bytes);

        // safer than Response.End() (avoids ThreadAbortException in logs)
        Response.Flush();
        HttpContext.Current.ApplicationInstance.CompleteRequest();
    }

    // ============================
    // Back to Dashboard Handler
    // ============================
    protected void BtnBackToReport_Click(object sender, EventArgs e)
    {
        Response.Redirect("index.aspx", true);
    }

    // ============================
    // XLSX ? TXT Conversion (ClosedXML - MIT License)
    // ============================
    private void ConvertXlsxToTxt(byte[] bytes, string outputPath)
    {
        using (var ms = new MemoryStream(bytes))
        using (var package = new XLWorkbook(ms))
        {
            var ws = package.Worksheet(1);
            var range = ws.RangeUsed();
            if (range == null) return;
            int rows = range.RowCount();
            int cols = range.ColumnCount();

            // ? UTF-8 without BOM for bulk insert friendliness
            using (StreamWriter w = new StreamWriter(outputPath, false, new UTF8Encoding(false)))
            {
                for (int r = 1; r <= rows; r++)
                {
                    string[] vals = new string[cols];
                    for (int c = 1; c <= cols; c++)
                    {
                        var cell = ws.Cell(r, c);
                        if (cell.IsEmpty())
                        {
                            vals[c - 1] = "";
                        }
                        else if (cell.DataType == XLDataType.Number)
                        {
                            double d = cell.GetDouble();
                            if (d == Math.Floor(d) && !double.IsInfinity(d) && !double.IsNaN(d))
                                vals[c - 1] = ((long)d).ToString();
                            else
                                vals[c - 1] = d.ToString("G");
                        }
                        else if (cell.DataType == XLDataType.DateTime)
                        {
                            vals[c - 1] = cell.GetDateTime().ToString("yyyy-MM-dd HH:mm:ss");
                        }
                        else
                        {
                            vals[c - 1] = cell.GetString().Trim();
                        }
                    }

                    w.WriteLine(string.Join("\t", vals));
                }
            }
        }
    }

    // ============================
    // TXT Standardization
    // ============================
    private void StandardizeTextFile(byte[] bytes, string outputPath)
    {
        // StreamReader auto-detects BOM (UTF-16, UTF-8-BOM, etc.)
        // We write back as UTF-8 without BOM with standard Windows CRLF (0x0d0a)
        // to match ROWTERMINATOR = '0x0d0a' in the SQL BULK INSERT.
        using (var sr = new StreamReader(new MemoryStream(bytes), true))
        {
            using (var sw = new StreamWriter(outputPath, false, new UTF8Encoding(false)))
            {
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    sw.WriteLine(line);
                }
            }
        }
    }

    // ============================
    // SQL Batch Executor (GO splitter)
    // ============================
    private DataTable RunSqlBatches(string sqlText, SqlConnection conn, SqlTransaction tran, StringBuilder summary, out DataTable previewLog)
    {
        DataTable stats = null;
        DataTable localPreview = null;

        // Normalize newlines and strip any invisible chars up front
        sqlText = StripInvisible(sqlText);
        string[] lines = sqlText.Replace("\r\n", "\n").Replace("\r", "\n").Split('\n');

        StringBuilder batch = new StringBuilder();
        int batchNo = 0;

        Action exec = delegate ()
        {
            string sql = StripInvisible(batch.ToString()).Trim();
            batch.Clear();

            if (sql.Length == 0)
                return;

            batchNo++;

            using (SqlCommand cmd = new SqlCommand(sql, conn, tran))
            {
                cmd.CommandTimeout = 0;

                // ? Detect Preview Log
                if (sql.IndexOf("FROM #PreviewLog", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        localPreview = dt;
                    }
                    int rc = 0;
                    if (localPreview != null) rc = localPreview.Rows.Count;
                    summary.AppendLine("Batch " + batchNo + ": PreviewLog returned (" + rc + " row(s)).");
                }
                // ? Detect final report SELECT (your script ends with "... FROM #ImportStats;")
                else if (sql.IndexOf("FROM #ImportStats", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        stats = dt;
                    }

                    // ? Older C# (no ?. operator)
                    int rc = 0;
                    if (stats != null) rc = stats.Rows.Count;
                    summary.AppendLine("Batch " + batchNo + ": ImportStats returned (" + rc + " row(s)).");
                }
                else
                {
                    int rows = cmd.ExecuteNonQuery();
                    summary.AppendLine("Batch " + batchNo + ": " + rows + " rows affected.");
                }
            }
        };

        foreach (string line in lines)
        {
            if (line.Trim().Equals("GO", StringComparison.OrdinalIgnoreCase))
                exec();
            else
                batch.AppendLine(line);
        }

        exec(); // run last batch

        previewLog = localPreview;
        return stats;
    }

    // ============================
    // Helpers
    // ============================
    private static string StripInvisible(string s)
    {
        if (string.IsNullOrEmpty(s)) return s;

        // U+FEFF BOM / zero-width no-break space -> causes "Incorrect syntax near '?'"
        return s
            .Replace("\uFEFF", "")
            .Replace("\u200B", "")
            .Replace("\u200C", "")
            .Replace("\u200D", "");
    }

    private int SafeGetIntAny(DataRow row, params string[] cols)
    {
        if (row == null || cols == null) return 0;

        foreach (string col in cols)
        {
            if (!string.IsNullOrEmpty(col) && row.Table.Columns.Contains(col))
            {
                object o = row[col];
                if (o == null || o == DBNull.Value) continue;

                int v;
                if (int.TryParse(o.ToString(), out v))
                    return v;
            }
        }

        return 0;
    }

    // (kept for compatibility if anything else calls it)
    private int SafeGetInt(DataRow row, string col)
    {
        if (row == null || !row.Table.Columns.Contains(col))
            return 0;

        if (row[col] == DBNull.Value)
            return 0;

        int v;
        if (int.TryParse(row[col].ToString(), out v))
            return v;

        return 0;
    }
}
