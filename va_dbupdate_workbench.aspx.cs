using System;
using System.Collections.Generic;
using System.Linq;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.IO;
using ClosedXML.Excel;

public partial class va_dbupdate_workbench : System.Web.UI.Page
{
    private const string SummarySessionKey = "VA_WB_SUMMARY";
    private const string ModifiedSqlKey    = "VA_WB_MODIFIED_SQL";
    private const string DataFilePathKey   = "VA_WB_DATAFILE_PATH";
    private const string HeadersKey        = "VA_WB_HEADERS";
    private const string MappingKey        = "VA_WB_MAPPING";

    private string AppRoot { get { return Server.MapPath("~/"); } }
    private string ProfileDir { get { return Path.Combine(AppRoot, "workbench_profiles"); } }

    // The 16 canonical AssetFileRaw column names that the VA SQL scripts expect
    private static readonly string[] CanonicalColumns = new string[]
    {
        "ENTRY NUMBER",
        "MANUFACTURER",
        "MFGR. EQUIPMENT NAME",
        "MODEL",
        "SERIAL #",
        "EQUIPMENT CATEGORY",
        "USE STATUS",
        "SERVICE POINTER",
        "LOCATION",
        "PHYSICAL INVENTORY DATE",
        "PREVIOUS LOCATION",
        "STATION NUMBER",
        "CATEGORY STOCK NUMBER",
        "CMR",
        "PURCHASE ORDER #",
        "SUB STATION"
    };


    // ============================
    // PAGE LOAD
    // ============================
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            PopulateFileDropdowns();
            PopulateProfileDropdown();
            SetStepIndicator(1);
        }
    }


    // ============================
    // FILE DROPDOWNS
    // ============================
    private void PopulateFileDropdowns()
    {
        string root = AppRoot;

        // SQL Scripts - scan root and known subdirectories
        DdlSqlScript.Items.Clear();
        DdlSqlScript.Items.Add(new ListItem("-- Select SQL Script --", ""));
        if (Directory.Exists(root))
        {
            var sqlFiles = Directory.GetFiles(root, "*.sql", SearchOption.AllDirectories)
                .Where(f => f.IndexOf(@"\.vs\", StringComparison.OrdinalIgnoreCase) < 0
                          && f.IndexOf(@"\obj\", StringComparison.OrdinalIgnoreCase) < 0
                          && f.IndexOf(@"\bin\", StringComparison.OrdinalIgnoreCase) < 0)
                .Select(f => f.Substring(root.Length).TrimStart(Path.DirectorySeparatorChar))
                .OrderBy(f => f, StringComparer.OrdinalIgnoreCase);
            foreach (string f in sqlFiles)
                DdlSqlScript.Items.Add(new ListItem(f, f));
        }

        // Data Files (.xlsx, .txt, .csv)
        DdlDataFile.Items.Clear();
        DdlDataFile.Items.Add(new ListItem("-- Select Data File --", ""));
        if (Directory.Exists(root))
        {
            var dataFiles = Directory.GetFiles(root)
                .Where(f =>
                {
                    string ext = Path.GetExtension(f).ToLowerInvariant();
                    return ext == ".xlsx" || ext == ".txt" || ext == ".csv";
                })
                .Select(f => Path.GetFileName(f))
                .OrderBy(f => f, StringComparer.OrdinalIgnoreCase);
            foreach (string f in dataFiles)
                DdlDataFile.Items.Add(new ListItem(f, f));
        }
    }

    private void PopulateProfileDropdown()
    {
        DdlProfile.Items.Clear();
        DdlProfile.Items.Add(new ListItem("-- Select Profile --", ""));

        if (!Directory.Exists(ProfileDir)) return;

        var profiles = Directory.GetFiles(ProfileDir, "*.json")
            .Select(f => Path.GetFileNameWithoutExtension(f))
            .OrderBy(f => f, StringComparer.OrdinalIgnoreCase);
        foreach (string p in profiles)
            DdlProfile.Items.Add(new ListItem(p, p));
    }

    protected void BtnRefreshFiles_Click(object sender, EventArgs e)
    {
        PopulateFileDropdowns();
        PopulateProfileDropdown();
        ShowStatus("ok", "&#8635; File lists refreshed.");
    }


    // ============================
    // SEPARATOR HELPERS
    // ============================
    private char GetSelectedSeparator()
    {
        if (RbPipe.Checked) return '|';
        if (RbComma.Checked) return ',';
        if (RbCustom.Checked && !string.IsNullOrEmpty(TxtCustomSep.Text))
            return TxtCustomSep.Text[0];
        if (RbTab.Checked) return '\t';
        // Auto-detect is checked (or nothing specific) — will be resolved in BtnParse_Click
        return '\0'; // sentinel for "needs auto-detection"
    }

    /// <summary>
    /// Sniffs the first data line of a file to auto-detect the field separator.
    /// Counts occurrences of common delimiters and picks the winner.
    /// </summary>
    private char AutoDetectSeparator(string firstLine)
    {
        if (string.IsNullOrEmpty(firstLine)) return '\t';

        int pipes  = firstLine.Split('|').Length - 1;
        int tabs   = firstLine.Split('\t').Length - 1;
        int commas = firstLine.Split(',').Length - 1;
        int semis  = firstLine.Split(';').Length - 1;

        // Pick the delimiter with the most occurrences (must have at least 1)
        int max = Math.Max(Math.Max(pipes, tabs), Math.Max(commas, semis));

        if (max == 0) return '\t'; // no delimiter found, default tab

        if (pipes == max)  return '|';
        if (tabs == max)   return '\t';
        if (commas == max) return ',';
        if (semis == max)  return ';';

        return '\t';
    }

    private string GetSeparatorDisplayName(char sep)
    {
        switch (sep)
        {
            case '\t': return "Tab (\\t)";
            case '|': return "Pipe (|)";
            case ',': return "Comma (,)";
            case ';': return "Semicolon (;)";
            default: return "Custom: " + sep;
        }
    }

    private string GetSqlFieldTerminator(char sep)
    {
        switch (sep)
        {
            case '\t': return "\\t";
            case '|': return "|";
            case ',': return ",";
            default: return sep.ToString();
        }
    }

    private void SetSeparatorRadio(char sep)
    {
        RbAutoDetect.Checked = false;
        RbTab.Checked = false;
        RbPipe.Checked = false;
        RbComma.Checked = false;
        RbCustom.Checked = false;
        TxtCustomSep.Text = "";

        switch (sep)
        {
            case '\t': RbTab.Checked = true; break;
            case '|': RbPipe.Checked = true; break;
            case ',': RbComma.Checked = true; break;
            default:
                RbCustom.Checked = true;
                TxtCustomSep.Text = sep.ToString();
                break;
        }
    }


    // ============================
    // STEP 1: PARSE & PREVIEW
    // ============================
    protected void BtnParse_Click(object sender, EventArgs e)
    {
        LitParsePreview.Text = "";
        LitStatus.Text = "";

        // Resolve data file
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
                ShowStatus("err", "Data file not found: " + HttpUtility.HtmlEncode(DdlDataFile.SelectedValue));
                return;
            }
        }
        else
        {
            ShowStatus("err", "No data file selected.");
            return;
        }

        char sep = GetSelectedSeparator();
        bool wasAutoDetected = (sep == '\0');

        try
        {
            string ext = Path.GetExtension(dataSourceName).ToLowerInvariant();

            // Prepare temp file path
            string tempDir = Server.MapPath("~/temp/");
            if (!Directory.Exists(tempDir))
                Directory.CreateDirectory(tempDir);
            string dataPath2 = Path.Combine(tempDir, "wb_data_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt");

            string[] headers = null;
            int totalDataRows = 0;
            List<string[]> previewRows = new List<string[]>(); // first 25 data rows only
            const int MAX_PREVIEW = 25;

            if (ext == ".xlsx")
            {
                // For XLSX, auto-detect doesn't apply (binary format) - default to tab
                if (wasAutoDetected) sep = '\t';
                string sepStr = sep.ToString();

                // Stream XLSX directly to temp file, only buffer preview rows
                using (var wb = new XLWorkbook(new MemoryStream(dataBytes)))
                using (var sw = new StreamWriter(dataPath2, false, new UTF8Encoding(false)))
                {
                    var ws = wb.Worksheets.Count > 0 ? wb.Worksheet(1) : null;
                    var rng = ws != null ? ws.RangeUsed() : null;
                    if (ws == null || rng == null)
                    {
                        ShowStatus("err", "File is empty.");
                        return;
                    }

                    int rows = rng.RowCount();
                    int cols = rng.ColumnCount();

                    if (rows == 0)
                    {
                        ShowStatus("err", "File is empty.");
                        return;
                    }

                    // Read headers from first row
                    headers = new string[cols];
                    for (int c = 1; c <= cols; c++)
                        headers[c - 1] = (ws.Cell(1, c).GetString() ?? "").Trim();

                    // Write header line
                    sw.WriteLine(string.Join(sepStr, headers));

                    // Stream data rows
                    for (int r = 2; r <= rows; r++)
                    {
                        string[] vals = new string[cols];
                        for (int c = 1; c <= cols; c++)
                        {
                            var cell = ws.Cell(r, c);
                            if (cell.DataType == XLDataType.Number)
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
                                vals[c - 1] = (cell.GetString() ?? "").Trim();
                            }
                        }

                        sw.WriteLine(string.Join(sepStr, vals));
                        totalDataRows++;
                        if (totalDataRows <= MAX_PREVIEW)
                            previewRows.Add(vals);
                    }
                }
            }
            else
            {
                // Parse options
                int skipRows = 0;
                int.TryParse(TxtSkipRows.Text.Trim(), out skipRows);
                bool hasHeaders = ChkHasHeaders.Checked;

                // Text file: stream line-by-line to temp file, buffer preview rows only
                using (var sr = new StreamReader(new MemoryStream(dataBytes), true))
                {
                    // Skip explicit skip rows first
                    int skippedCount = 0;
                    for (int s = 0; s < skipRows; s++)
                    {
                        if (sr.ReadLine() == null) break;
                        skippedCount++;
                    }

                    string firstDataLine = null;

                    if (!hasHeaders)
                    {
                        // Smart auto-skip: for headerless files, also skip lines that
                        // don't look like delimited data (report titles, dashes, blanks).
                        // We need to find the separator first, then find the first line that has it.
                        char detectSep = wasAutoDetected ? '|' : sep; // default guess for detection
                        if (!wasAutoDetected) detectSep = sep;

                        // Read lines until we find one with multiple delimited fields
                        int maxProbe = 20; // don't probe forever
                        for (int probe = 0; probe < maxProbe; probe++)
                        {
                            string probeLine = sr.ReadLine();
                            if (probeLine == null) break;

                            // Skip blank lines and lines of dashes/equals
                            string trimmed = probeLine.Trim();
                            if (string.IsNullOrEmpty(trimmed)) { skippedCount++; continue; }
                            if (trimmed.Length > 5 && (trimmed.Replace("-", "").Length == 0 || trimmed.Replace("=", "").Length == 0))
                            { skippedCount++; continue; }

                            // Try to detect separator from this line
                            if (wasAutoDetected)
                                detectSep = AutoDetectSeparator(probeLine);

                            // Check if this line has multiple fields when split
                            int fields = probeLine.Split(detectSep).Length;
                            if (fields >= 3) // real data has at least 3 fields
                            {
                                firstDataLine = probeLine;
                                sep = detectSep;
                                break;
                            }

                            // Doesn't look like data, skip it
                            skippedCount++;
                        }

                        // Update the skip rows display to show what we auto-skipped
                        if (skippedCount > skipRows)
                            TxtSkipRows.Text = skippedCount.ToString();
                    }
                    else
                    {
                        // Headers mode: just read the first line as header
                        firstDataLine = sr.ReadLine();
                        if (wasAutoDetected && firstDataLine != null)
                            sep = AutoDetectSeparator(firstDataLine);
                    }

                    if (firstDataLine == null)
                    {
                        ShowStatus("err", "No data found in file (skipped " + skippedCount + " non-data rows). Check the file format.");
                        return;
                    }

                    if (hasHeaders)
                    {
                        // First data line IS the header
                        headers = firstDataLine.Split(sep);
                        for (int i = 0; i < headers.Length; i++)
                            headers[i] = headers[i].Trim().Trim('"');
                    }
                    else
                    {
                        // No headers - generate positional names from CanonicalColumns
                        int fieldCount = firstDataLine.Split(sep).Length;
                        headers = new string[fieldCount];
                        for (int i = 0; i < fieldCount; i++)
                        {
                            if (i < CanonicalColumns.Length)
                                headers[i] = CanonicalColumns[i];
                            else
                                headers[i] = "Column " + (i + 1);
                        }
                    }

                    using (var sw = new StreamWriter(dataPath2, false, new UTF8Encoding(false)))
                    {
                        // Write generated header row
                        sw.WriteLine(string.Join(sep.ToString(), headers));

                        // If no headers, the first data line IS data - write it
                        if (!hasHeaders)
                        {
                            sw.WriteLine(firstDataLine);
                            totalDataRows++;
                            if (totalDataRows <= MAX_PREVIEW)
                                previewRows.Add(firstDataLine.Split(sep));
                        }

                        string line;
                        while ((line = sr.ReadLine()) != null)
                        {
                            // Skip blank lines and dash-only lines
                            if (string.IsNullOrWhiteSpace(line)) continue;
                            string lt = line.Trim();
                            if (lt.Length > 5 && (lt.Replace("-", "").Length == 0 || lt.Replace("=", "").Length == 0)) continue;
                            sw.WriteLine(line);
                            totalDataRows++;
                            if (totalDataRows <= MAX_PREVIEW)
                                previewRows.Add(line.Split(sep));
                        }
                    }
                }
            }

            // Store in session for later steps
            Session[HeadersKey] = headers;
            Session[DataFilePathKey] = dataPath2;
            HidRowCount.Value = totalDataRows.ToString();

            // Build parse preview HTML
            StringBuilder sb = new StringBuilder();
            sb.Append("<div style='margin-top:20px;'>");
            sb.Append("<h3 class='section-title'>&#128269; Parse Preview &mdash; " + HttpUtility.HtmlEncode(dataSourceName) + "</h3>");
            sb.Append("<div style='display:flex; gap:20px; margin-bottom:12px; flex-wrap:wrap;'>");
            sb.Append("<span style='padding:6px 12px; background:color-mix(in srgb, var(--wb-purple), transparent 88%); border:1px solid var(--wb-purple); border-radius:5px; font-size:13px;'>");
            sb.Append("<strong>Separator:</strong> " + HttpUtility.HtmlEncode(GetSeparatorDisplayName(sep)) + "</span>");
            sb.Append("<span style='padding:6px 12px; background:color-mix(in srgb, var(--wb-teal), transparent 88%); border:1px solid var(--wb-teal); border-radius:5px; font-size:13px;'>");
            sb.Append("<strong>Columns:</strong> " + headers.Length + "</span>");
            sb.Append("<span style='padding:6px 12px; background:color-mix(in srgb, var(--wb-green), transparent 88%); border:1px solid var(--wb-green); border-radius:5px; font-size:13px;'>");
            sb.Append("<strong>Data Rows:</strong> " + totalDataRows.ToString("N0") + "</span>");
            sb.Append("</div>");

            // Preview table (first 25 data rows)
            sb.Append("<div class='preview-wrap' style='max-height:500px; overflow:auto;'>");
            sb.Append("<table class='preview-table'><thead><tr><th class='row-num'>#</th>");
            foreach (string h in headers)
                sb.Append("<th>" + HttpUtility.HtmlEncode(h) + "</th>");
            sb.Append("</tr></thead><tbody>");

            for (int r = 0; r < previewRows.Count; r++)
            {
                string[] cells = previewRows[r];
                sb.Append("<tr><td class='row-num'>" + (r + 1) + "</td>");
                for (int c = 0; c < headers.Length; c++)
                {
                    string val = c < cells.Length ? cells[c].Trim() : "";
                    sb.Append("<td>" + HttpUtility.HtmlEncode(val) + "</td>");
                }
                sb.Append("</tr>");
            }

            sb.Append("</tbody></table></div></div>");

            LitParsePreview.Text = sb.ToString();

            // Build header mapping UI
            BuildHeaderMappingUI(headers);
            PnlHeaderMapping.Visible = true;

            // If auto-detected, update the radio to show the detected separator
            if (wasAutoDetected)
                SetSeparatorRadio(sep);

            SetStepIndicator(2);
            string autoNote = wasAutoDetected ? " <strong>Auto-detected separator: <code>" + HttpUtility.HtmlEncode(GetSeparatorDisplayName(sep)) + "</code></strong>." : "";
            ShowStatus("ok", "&#10004; File parsed successfully. " + totalDataRows.ToString("N0") + " data rows detected with " + headers.Length + " columns." + autoNote + " Review the preview grid below and map headers.");
        }
        catch (Exception ex)
        {
            ShowStatus("err", "Parse error: " + HttpUtility.HtmlEncode(ex.Message));
        }
    }

    private void BuildHeaderMappingUI(string[] fileHeaders)
    {
        StringBuilder sb = new StringBuilder();
        sb.Append("<div class='map-grid'>");
        sb.Append("<div class='map-header'>File Column</div>");
        sb.Append("<div class='map-header'>&nbsp;</div>");
        sb.Append("<div class='map-header'>Maps To (AssetFileRaw)</div>");

        // Check if there's a saved mapping from session
        Dictionary<string, string> savedMapping = Session[MappingKey] as Dictionary<string, string>;
        HashSet<string> alreadyMatched = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (int i = 0; i < fileHeaders.Length; i++)
        {
            string fh = fileHeaders[i].Trim();
            sb.Append("<div class='file-col'>" + HttpUtility.HtmlEncode(fh) + "</div>");
            sb.Append("<div class='arrow'>&#10142;</div>");

            // Build dropdown
            string ddlId = "ddlMap_" + i;
            string autoMatch = FindAutoMatch(fh, savedMapping, alreadyMatched);
            string cssClass = !string.IsNullOrEmpty(autoMatch) && autoMatch != "__SKIP__" ? "ddl-map mapped" : "ddl-map unmapped";

            sb.Append("<select name='" + ddlId + "' class='" + cssClass + "'>");
            sb.Append("<option value='__SKIP__'" + (autoMatch == "__SKIP__" ? " selected" : "") + ">&mdash; Skip &mdash;</option>");
            foreach (string col in CanonicalColumns)
            {
                string sel = (autoMatch == col) ? " selected" : "";
                sb.Append("<option value='" + HttpUtility.HtmlEncode(col) + "'" + sel + ">" + HttpUtility.HtmlEncode(col) + "</option>");
            }
            sb.Append("</select>");
        }

        sb.Append("</div>");
        LitHeaderMap.Text = sb.ToString();
    }

    // Common VA column name aliases -> canonical column name
    // NOTE: Keys here must NOT match any CanonicalColumns entry (case-insensitive),
    //       because exact matches are handled first in FindAutoMatch.
    private static readonly Dictionary<string, string> ColumnAliases = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        { "BriefDescription",       "MFGR. EQUIPMENT NAME" },
        { "Brief Description",      "MFGR. EQUIPMENT NAME" },
        { "MFGR.Equipment Name",    "MFGR. EQUIPMENT NAME" },
        { "MFGREquipmentName",      "MFGR. EQUIPMENT NAME" },
        { "Equipment Name",         "MFGR. EQUIPMENT NAME" },
        { "UseStatus",              "USE STATUS" },
        { "Service",                "SERVICE POINTER" },
        { "ServicePointer",         "SERVICE POINTER" },
        { "PhysicalInventoryDate",  "PHYSICAL INVENTORY DATE" },
        { "PreviousLocation",       "PREVIOUS LOCATION" },
        { "AMMCategoryStockName",   "CATEGORY STOCK NUMBER" },
        { "CategoryStockNumber",    "CATEGORY STOCK NUMBER" },
        { "PurchaseOrderNumber",    "PURCHASE ORDER #" },
        { "Purchase Order Number",  "PURCHASE ORDER #" },
        { "Purchase Order",         "PURCHASE ORDER #" },
        { "substation",             "SUB STATION" },
        { "StationNumber",          "STATION NUMBER" },
        { "EntryNumber",            "ENTRY NUMBER" },
        { "Serial",                 "SERIAL #" },
        { "SerialNumber",           "SERIAL #" },
        { "Serial Number",          "SERIAL #" },
        { "EquipmentCategory",      "EQUIPMENT CATEGORY" },
    };

    private string FindAutoMatch(string fileHeader, Dictionary<string, string> savedMapping, HashSet<string> alreadyMatched)
    {
        // If there's a saved mapping, use it
        if (savedMapping != null && savedMapping.ContainsKey(fileHeader))
            return savedMapping[fileHeader];

        // 1. Exact case-insensitive match against canonical columns
        foreach (string col in CanonicalColumns)
        {
            if (string.Equals(fileHeader, col, StringComparison.OrdinalIgnoreCase))
            {
                if (alreadyMatched != null && alreadyMatched.Contains(col))
                    return "__SKIP__";  // Already matched by another column
                if (alreadyMatched != null) alreadyMatched.Add(col);
                return col;
            }
        }

        // 2. Fuzzy alias lookup
        string aliasMatch;
        if (ColumnAliases.TryGetValue(fileHeader.Trim(), out aliasMatch))
        {
            if (alreadyMatched != null && alreadyMatched.Contains(aliasMatch))
                return "__SKIP__";  // Already matched by another column
            if (alreadyMatched != null) alreadyMatched.Add(aliasMatch);
            return aliasMatch;
        }

        // 3. Normalized comparison (strip spaces, dots, underscores, case-insensitive)
        string normalized = Regex.Replace(fileHeader, @"[\s._#]+", "").ToUpperInvariant();
        foreach (string col in CanonicalColumns)
        {
            string normalizedCol = Regex.Replace(col, @"[\s._#]+", "").ToUpperInvariant();
            if (normalized == normalizedCol)
            {
                if (alreadyMatched != null && alreadyMatched.Contains(col))
                    return "__SKIP__";
                if (alreadyMatched != null) alreadyMatched.Add(col);
                return col;
            }
        }

        return "__SKIP__";
    }


    // ============================
    // STEP 2: APPLY MAPPING & GENERATE SQL
    // ============================
    protected void BtnApplyMapping_Click(object sender, EventArgs e)
    {
        string[] fileHeaders = Session[HeadersKey] as string[];
        if (fileHeaders == null)
        {
            ShowStatus("err", "Session expired. Please re-parse the file.");
            return;
        }

        // Read mapping from form
        Dictionary<string, string> mapping = new Dictionary<string, string>();
        List<string> mappedColumns = new List<string>();

        for (int i = 0; i < fileHeaders.Length; i++)
        {
            string val = Request.Form["ddlMap_" + i];
            if (string.IsNullOrEmpty(val)) val = "__SKIP__";
            mapping[fileHeaders[i]] = val;
            if (val != "__SKIP__")
                mappedColumns.Add(val);
        }

        // Store mapping in session
        Session[MappingKey] = mapping;

        // Validate: check for duplicate column mappings
        var duplicates = mappedColumns.GroupBy(c => c, StringComparer.OrdinalIgnoreCase)
            .Where(g => g.Count() > 1)
            .Select(g => g.Key)
            .ToList();
        if (duplicates.Count > 0)
        {
            ShowStatus("err", "Duplicate column mapping detected: <strong>" + HttpUtility.HtmlEncode(string.Join(", ", duplicates))
                + "</strong>. Each database column can only be mapped once. Change one of the duplicates to <em>&mdash; Skip &mdash;</em> or a different column.");
            BuildHeaderMappingUI(fileHeaders);
            PnlHeaderMapping.Visible = true;
            return;
        }

        // Validate: at least 1 column mapped
        if (mappedColumns.Count == 0)
        {
            ShowStatus("err", "No columns mapped. Map at least one file column to a database column.");
            return;
        }

        // Load and modify the SQL script
        string sqlText = LoadSqlScript();
        if (sqlText == null) return;

        char sep = GetSelectedSeparator();
        string modifiedSql = RewriteSql(sqlText, sep, mapping, fileHeaders);

        // Store the modified SQL for execution
        Session[ModifiedSqlKey] = modifiedSql;

        // Show SQL viewer
        LitSqlViewer.Text = "<div class='sql-viewer'>" + HttpUtility.HtmlEncode(modifiedSql) + "</div>";

        PnlSqlPreview.Visible = true;
        PnlHeaderMapping.Visible = true; // keep visible

        // Rebuild header mapping UI to maintain state
        BuildHeaderMappingUI(fileHeaders);

        SetStepIndicator(3);

        int mappedCount = mappedColumns.Count;
        int skippedCount = fileHeaders.Length - mappedCount;
        ShowStatus("ok", "&#10004; SQL generated. <strong>" + mappedCount + "</strong> columns mapped, <strong>" + skippedCount + "</strong> skipped. "
            + "Separator set to <code>" + HttpUtility.HtmlEncode(GetSeparatorDisplayName(sep)) + "</code>. Review the SQL below, then Test or Commit.");
    }


    // ============================
    // SQL REWRITING ENGINE
    // ============================
    private string RewriteSql(string sqlText, char sep, Dictionary<string, string> mapping, string[] fileHeaders)
    {
        // 1) Replace FIELDTERMINATOR — handles both styles:
        //    - Original: FIELDTERMINATOR = '\t'  (regex replacement)
        //    - v2 token: FIELDTERMINATOR = '{{FIELDTERMINATOR}}'  (string replacement)
        string newTerminator = GetSqlFieldTerminator(sep);
        sqlText = Regex.Replace(
            sqlText,
            @"FIELDTERMINATOR\s*=\s*'[^']*'",
            "FIELDTERMINATOR = '" + newTerminator + "'",
            RegexOptions.IgnoreCase
        );
        sqlText = sqlText.Replace("{{FIELDTERMINATOR}}", newTerminator);

        // 2) Rewrite the CREATE TABLE dbo.AssetFileRaw block
        // Strategy: find the CREATE TABLE dbo.AssetFileRaw block and replace the column definitions
        // with only the mapped columns in file order

        // Build the new column list based on the mapping (in file order)
        StringBuilder newCols = new StringBuilder();
        List<string> orderedDbColumns = new List<string>();

        for (int i = 0; i < fileHeaders.Length; i++)
        {
            string dbCol;
            if (mapping.ContainsKey(fileHeaders[i]))
                dbCol = mapping[fileHeaders[i]];
            else
                dbCol = "__SKIP__";

            if (dbCol == "__SKIP__")
            {
                // Create a dummy column for skipped fields — BULK INSERT requires
                // a column for every field in the file even if we don't use it
                string dummyName = "_skip_" + (i + 1);
                newCols.AppendLine("    [" + dummyName + "]" + new string(' ', Math.Max(1, 30 - dummyName.Length - 2)) + "nvarchar(500) NULL,");
                orderedDbColumns.Add(dummyName);
            }
            else
            {
                newCols.AppendLine("    [" + dbCol + "]" + new string(' ', Math.Max(1, 30 - dbCol.Length - 2)) + "nvarchar(500) NULL,");
                orderedDbColumns.Add(dbCol);
            }
        }

        // Remove trailing comma
        string colBlock = newCols.ToString().TrimEnd();
        if (colBlock.EndsWith(","))
            colBlock = colBlock.Substring(0, colBlock.Length - 1);

        // Replace the CREATE TABLE block
        // Match pattern: CREATE TABLE dbo.AssetFileRaw ( ... );
        string createPattern = @"CREATE\s+TABLE\s+dbo\.AssetFileRaw\s*\([^;]+?\);";
        string replacement = "CREATE TABLE dbo.AssetFileRaw (\n" + colBlock + "\n);";

        sqlText = Regex.Replace(sqlText, createPattern, replacement, RegexOptions.IgnoreCase | RegexOptions.Singleline);

        // 3) Add a comment header noting the modification
        string header = "/* ================================================================\n"
            + "   MODIFIED BY IMPORT WORKBENCH - " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "\n"
            + "   Separator: " + GetSeparatorDisplayName(sep) + "\n"
            + "   Mapped Columns: " + string.Join(", ", orderedDbColumns.Where(c => !c.StartsWith("_skip_"))) + "\n"
            + "   ================================================================ */\n\n";

        sqlText = header + sqlText;

        return sqlText;
    }


    // ============================
    // STEP 3: TEST RUN (DRY RUN)
    // ============================
    protected void BtnTestRun_Click(object sender, EventArgs e)
    {
        ExecuteWorkbenchImport(true);
    }

    protected void BtnCommitImport_Click(object sender, EventArgs e)
    {
        ExecuteWorkbenchImport(false);
    }

    private void ExecuteWorkbenchImport(bool isPreview)
    {
        Server.ScriptTimeout = 1800;

        LitSummary.Text = "";
        LitPreviewTable.Text = "";
        LitStatus.Text = "";
        Session[SummarySessionKey] = null;
        BtnDownloadSummary.Enabled = false;

        string modifiedSql = Session[ModifiedSqlKey] as string;
        string dataFilePath = Session[DataFilePathKey] as string;

        if (string.IsNullOrEmpty(modifiedSql))
        {
            ShowStatus("err", "No generated SQL found. Please re-parse and map headers first.");
            return;
        }

        if (string.IsNullOrEmpty(dataFilePath) || !File.Exists(dataFilePath))
        {
            ShowStatus("err", "Data file not found. Please re-parse the file.");
            return;
        }

        // Replace runtime tokens
        string sqlText = modifiedSql.Replace("{{DATAFILE}}", dataFilePath.Replace("'", "''"));
        // Safety net: {{FIELDTERMINATOR}} should already be resolved by RewriteSql,
        // but replace again in case the user is running a v2 script raw
        char sep = GetSelectedSeparator();
        if (sep == '\0') sep = '\t'; // fallback if auto-detect sentinel leaked
        sqlText = sqlText.Replace("{{FIELDTERMINATOR}}", GetSqlFieldTerminator(sep));
        sqlText = StripInvisible(sqlText);

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
                sb.Append("<div class='warn'><b>&#9888; Test Run Completed (All Changes Rolled Back)</b><br/>");
            else
                sb.Append("<div class='ok'><b>&#9989; Import Committed Successfully</b><br/>");

            if (stats != null && stats.Rows.Count > 0)
            {
                DataRow r = stats.Rows[0];

                sb.Append("Locations Inserted: " + SafeGetIntAny(r, "Locations Inserted", "LocInserted") + "<br/>");
                sb.Append("Assets Inserted: " + SafeGetIntAny(r, "Assets Inserted", "AssetInserted") + "<br/>");
                sb.Append("Assets Updated: " + SafeGetIntAny(r, "Assets Updated (total)", "AssetUpdated", "Assets Updated/Enriched") + "<br/>");
                sb.Append("Assets Skipped: " + SafeGetIntAny(r, "Assets Skipped (duplicates)", "AssetSkipped") + "<br/>");
                sb.Append("Errors: " + SafeGetIntAny(r, "Errors", "Errors") + "<br/>");
            }
            else
            {
                sb.Append("No ImportStats returned. The script may not include a #ImportStats table.<br/>");
            }

            sb.Append("</div>");
            LitSummary.Text = sb.ToString();

            // Build Preview Table HTML (diff-style)
            if (preview != null && preview.Rows.Count > 0)
            {
                StringBuilder pt = new StringBuilder();
                pt.Append("<div style='margin-top:20px; border:1px solid var(--line); border-radius:8px; padding:20px; background:var(--card);'>");
                pt.Append("<h3 class='section-title'>&#128203; Affected Records Preview (First 25)</h3>");

                pt.Append("<table class='diff-table'>");
                pt.Append("<tr><th>Action</th><th>Name</th><th>RFID</th><th>Description</th><th>Location</th></tr>");

                foreach (DataRow pr in preview.Rows)
                {
                    string action = pr.Table.Columns.Contains("Action") ? (pr["Action"] ?? "").ToString() : "—";
                    string chipClass = action.Contains("INSERT") ? "chip-insert" : action.Contains("UPDATE") || action.Contains("ENRICH") ? "chip-update" : "chip-skip";

                    pt.Append("<tr>");
                    pt.Append("<td><span class='chip " + chipClass + "'>" + HttpUtility.HtmlEncode(action) + "</span></td>");
                    pt.Append("<td style='font-weight:600;'>" + SafeHtmlCol(pr, "Name") + "</td>");
                    pt.Append("<td style='font-family:Consolas,monospace; color:var(--muted);'>" + SafeHtmlCol(pr, "RFID") + "</td>");
                    pt.Append("<td>" + SafeHtmlCol(pr, "Description") + "</td>");
                    pt.Append("<td>" + SafeHtmlCol(pr, "LastObservedLocation") + "</td>");
                    pt.Append("</tr>");
                }

                pt.Append("</table></div>");
                LitPreviewTable.Text = pt.ToString();
            }

            // Save downloadable summary
            StringBuilder dl = new StringBuilder();
            dl.AppendLine(isPreview ? "VA Import Workbench — TEST RUN (DRY RUN) — " + DateTime.Now.ToString() : "VA Import Workbench — COMMITTED — " + DateTime.Now.ToString());
            dl.AppendLine("Separator: " + GetSeparatorDisplayName(GetSelectedSeparator()));
            dl.AppendLine("Data file: " + (dataFilePath ?? "unknown"));
            dl.AppendLine();
            dl.AppendLine(summaryBuilder.ToString());

            Session[SummarySessionKey] = dl.ToString();
            BtnDownloadSummary.Enabled = true;

            // Keep panels visible
            PnlSqlPreview.Visible = true;
            PnlHeaderMapping.Visible = true;

            // Rebuild the mapping UI
            string[] fileHeaders = Session[HeadersKey] as string[];
            if (fileHeaders != null)
                BuildHeaderMappingUI(fileHeaders);

            // Re-show the SQL viewer
            LitSqlViewer.Text = "<div class='sql-viewer'>" + HttpUtility.HtmlEncode(modifiedSql) + "</div>";

            SetStepIndicator(4);
        }
        catch (Exception ex)
        {
            ShowStatus("err", "SQL execution error: " + HttpUtility.HtmlEncode(ex.Message));

            // Keep panels visible for debugging
            PnlSqlPreview.Visible = true;
            PnlHeaderMapping.Visible = true;
            string[] fh = Session[HeadersKey] as string[];
            if (fh != null) BuildHeaderMappingUI(fh);
            if (!string.IsNullOrEmpty(modifiedSql))
                LitSqlViewer.Text = "<div class='sql-viewer'>" + HttpUtility.HtmlEncode(modifiedSql) + "</div>";
        }
    }


    // ============================
    // PROFILE SAVE / LOAD
    // ============================
    protected void BtnSaveProfile_Click(object sender, EventArgs e)
    {
        string[] fileHeaders = Session[HeadersKey] as string[];
        Dictionary<string, string> mapping = Session[MappingKey] as Dictionary<string, string>;

        if (fileHeaders == null || mapping == null)
        {
            ShowStatus("err", "No mapping to save. Parse a file and apply a mapping first.");
            return;
        }

        if (!Directory.Exists(ProfileDir))
            Directory.CreateDirectory(ProfileDir);

        char sep = GetSelectedSeparator();
        string profileName = "profile_" + GetSqlFieldTerminator(sep).Replace("\\", "").Replace("/", "") + "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss");

        // Build a simple JSON manually (no external JSON library dependency)
        StringBuilder json = new StringBuilder();
        json.AppendLine("{");
        json.AppendLine("  \"separator\": \"" + EscapeJsonString(sep.ToString()) + "\",");
        json.AppendLine("  \"separatorDisplay\": \"" + EscapeJsonString(GetSeparatorDisplayName(sep)) + "\",");
        json.AppendLine("  \"created\": \"" + DateTime.Now.ToString("o") + "\",");
        json.AppendLine("  \"mapping\": {");

        int idx = 0;
        foreach (var kvp in mapping)
        {
            json.Append("    \"" + EscapeJsonString(kvp.Key) + "\": \"" + EscapeJsonString(kvp.Value) + "\"");
            if (idx < mapping.Count - 1) json.Append(",");
            json.AppendLine();
            idx++;
        }

        json.AppendLine("  }");
        json.AppendLine("}");

        string profilePath = Path.Combine(ProfileDir, profileName + ".json");
        File.WriteAllText(profilePath, json.ToString(), new UTF8Encoding(false));

        PopulateProfileDropdown();

        // Keep panels visible
        PnlSqlPreview.Visible = true;
        PnlHeaderMapping.Visible = true;
        if (fileHeaders != null) BuildHeaderMappingUI(fileHeaders);
        string modSql = Session[ModifiedSqlKey] as string;
        if (!string.IsNullOrEmpty(modSql))
            LitSqlViewer.Text = "<div class='sql-viewer'>" + HttpUtility.HtmlEncode(modSql) + "</div>";

        ShowStatus("ok", "&#128190; Profile saved as <code>" + HttpUtility.HtmlEncode(profileName) + "</code>. You can reload it from the profile dropdown.");
    }

    protected void BtnLoadProfile_Click(object sender, EventArgs e)
    {
        if (string.IsNullOrEmpty(DdlProfile.SelectedValue))
        {
            ShowStatus("warn", "No profile selected.");
            return;
        }

        string profilePath = Path.Combine(ProfileDir, DdlProfile.SelectedValue + ".json");
        if (!File.Exists(profilePath))
        {
            ShowStatus("err", "Profile file not found.");
            return;
        }

        try
        {
            string jsonText = File.ReadAllText(profilePath);

            // Simple JSON parsing (no dependency on System.Web.Script.Serialization which may not be available)
            // Parse separator
            Match sepMatch = Regex.Match(jsonText, "\"separator\"\\s*:\\s*\"([^\"]*?)\"");
            if (sepMatch.Success)
            {
                string sepVal = UnescapeJsonString(sepMatch.Groups[1].Value);
                char sep = sepVal.Length > 0 ? sepVal[0] : '\t';
                SetSeparatorRadio(sep);
            }

            // Parse mapping
            Match mappingBlock = Regex.Match(jsonText, "\"mapping\"\\s*:\\s*\\{([^}]*)\\}", RegexOptions.Singleline);
            if (mappingBlock.Success)
            {
                Dictionary<string, string> mapping = new Dictionary<string, string>();
                MatchCollection pairs = Regex.Matches(mappingBlock.Groups[1].Value, "\"([^\"]*?)\"\\s*:\\s*\"([^\"]*?)\"");
                foreach (Match pair in pairs)
                {
                    mapping[UnescapeJsonString(pair.Groups[1].Value)] = UnescapeJsonString(pair.Groups[2].Value);
                }
                Session[MappingKey] = mapping;
            }

            ShowStatus("ok", "&#128190; Profile <code>" + HttpUtility.HtmlEncode(DdlProfile.SelectedValue) + "</code> loaded. Select a data file and click <strong>Parse &amp; Preview</strong> to apply the mapping.");
        }
        catch (Exception ex)
        {
            ShowStatus("err", "Error loading profile: " + HttpUtility.HtmlEncode(ex.Message));
        }
    }


    // ============================
    // DOWNLOAD SUMMARY
    // ============================
    protected void BtnDownloadSummary_Click(object sender, EventArgs e)
    {
        string text = Session[SummarySessionKey] as string;
        if (string.IsNullOrEmpty(text))
        {
            ShowStatus("err", "No summary available.");
            return;
        }

        byte[] bytes = Encoding.UTF8.GetBytes(text);

        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition",
            "attachment; filename=VA_Workbench_Summary_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt");
        Response.BinaryWrite(bytes);
        Response.Flush();
        HttpContext.Current.ApplicationInstance.CompleteRequest();
    }


    // ============================
    // SQL HELPERS (same patterns as va_dbupdate.aspx.cs)
    // ============================
    private string LoadSqlScript()
    {
        byte[] sqlBytes = null;

        if (!string.IsNullOrEmpty(DdlSqlScript.SelectedValue))
        {
            string sqlPath = Path.Combine(AppRoot, DdlSqlScript.SelectedValue);
            if (File.Exists(sqlPath))
            {
                sqlBytes = File.ReadAllBytes(sqlPath);
            }
            else
            {
                ShowStatus("err", "SQL file not found: " + HttpUtility.HtmlEncode(DdlSqlScript.SelectedValue));
                return null;
            }
        }
        else
        {
            ShowStatus("err", "No SQL script selected.");
            return null;
        }

        string sqlText = Encoding.UTF8.GetString(sqlBytes);
        sqlText = StripInvisible(sqlText);
        return sqlText;
    }

    private DataTable RunSqlBatches(string sqlText, SqlConnection conn, SqlTransaction tran, StringBuilder summary, out DataTable previewLog)
    {
        DataTable stats = null;
        DataTable localPreview = null;

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
                else if (sql.IndexOf("FROM #ImportStats", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        stats = dt;
                    }

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
    // XLSX CONVERSION
    // ============================
    private string[] ConvertXlsxToLines(byte[] bytes, char sep)
    {
        var result = new List<string>();
        using (var wb = new XLWorkbook(new MemoryStream(bytes)))
        {
            var ws = wb.Worksheets.Count > 0 ? wb.Worksheet(1) : null;
            var rng = ws != null ? ws.RangeUsed() : null;
            if (ws == null || rng == null) return result.ToArray();

            int rows = rng.RowCount();
            int cols = rng.ColumnCount();

            for (int r = 1; r <= rows; r++)
            {
                string[] vals = new string[cols];
                for (int c = 1; c <= cols; c++)
                {
                    var cell = ws.Cell(r, c);
                    if (cell.DataType == XLDataType.Number)
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
                        vals[c - 1] = (cell.GetString() ?? "").Trim();
                    }
                }

                result.Add(string.Join(sep.ToString(), vals));
            }
        }
        return result.ToArray();
    }


    // ============================
    // UTILITY HELPERS
    // ============================
    private static string StripInvisible(string s)
    {
        if (string.IsNullOrEmpty(s)) return s;
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

    private string SafeHtmlCol(DataRow row, string col)
    {
        if (row == null || !row.Table.Columns.Contains(col))
            return "—";
        object o = row[col];
        if (o == null || o == DBNull.Value) return "—";
        return HttpUtility.HtmlEncode(o.ToString());
    }

    private void ShowStatus(string cssClass, string html)
    {
        LitStatus.Text = "<div class='" + cssClass + "'>" + html + "</div>";
    }

    private void SetStepIndicator(int activeStep)
    {
        HidCurrentStep.Value = activeStep.ToString();

        stepPill1.Attributes["class"] = activeStep == 1 ? "step-pill active" : (activeStep > 1 ? "step-pill done" : "step-pill");
        stepPill2.Attributes["class"] = activeStep == 2 ? "step-pill active" : (activeStep > 2 ? "step-pill done" : "step-pill");
        stepPill3.Attributes["class"] = activeStep == 3 ? "step-pill active" : (activeStep > 3 ? "step-pill done" : "step-pill");
        stepPill4.Attributes["class"] = activeStep == 4 ? "step-pill active" : "step-pill";
    }

    private static string EscapeJsonString(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r").Replace("\t", "\\t");
    }

    private static string UnescapeJsonString(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\t", "\t").Replace("\\n", "\n").Replace("\\r", "\r").Replace("\\\"", "\"").Replace("\\\\", "\\");
    }
}
