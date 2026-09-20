using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Spreadsheet;

/// <summary>
/// va_excel_print.aspx.cs
/// Reads C:\va_rfid\excel_data\equipment.xlsx, lets user select rows,
/// upserts them into dbo.asset, and optionally prints via MQTT/BarTender.
///
/// Excel column -> dbo.asset mapping:
///   Col  1  ENTRY NUMBER          -> name  (formatted "STATION-ENTRY#")
///   Col  2  MANUFACTURER          -> text1
///   Col  3  MFGR. EQUIPMENT NAME  -> description
///   Col  4  MODEL                 -> text2
///   Col  5  SERIAL #              -> text3  (UPSERT key)
///   Col  6  EQUIPMENT CATEGORY    -> text4
///   Col  7  USE STATUS            -> listvalue1 / disposalstatus
///   Col  8  SERVICE POINTER       -> text5
///   Col  9  LOCATION              -> text6  (SP prefix normalised)
///   Col 10  PHYSICAL INVENTORY DATE -> text10
///   Col 11  PREVIOUS LOCATION     -> text11
///   Col 12  STATION NUMBER        -> text7  (used to resolve companyid)
///   Col 13  CATEGORY STOCK NUMBER -> text12
///   Col 14  CMR                   -> text8
///   Col 15  PURCHASE ORDER #      -> text9
/// </summary>
public partial class va_excel_print : System.Web.UI.Page
{
    private const string DefaultExcelPath = @"C:\va_rfid\excel_data\equipment.xlsx";
    private const string SESSION_UPLOAD_PATH = "ExcelPrint_UploadedFilePath";
    private const string SESSION_UPLOAD_NAME = "ExcelPrint_UploadedFileName";

    /// <summary>Returns the active file path — uploaded file if available, else default.</summary>
    private string ActiveExcelPath
    {
        get
        {
            string uploaded = Session[SESSION_UPLOAD_PATH] as string;
            if (!string.IsNullOrEmpty(uploaded) && File.Exists(uploaded))
                return uploaded;
            return DefaultExcelPath;
        }
    }

    private static string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    // ---------------------------------------------------------------
    // Represents one row parsed from the Excel file
    // ---------------------------------------------------------------
    private class EquipRow
    {
        public int     RowIndex   { get; set; }
        public string  EntryNum   { get; set; }   // Col 1
        public string  Mfr        { get; set; }   // Col 2  -> text1
        public string  EqName     { get; set; }   // Col 3  -> description
        public string  Model      { get; set; }   // Col 4  -> text2
        public string  Serial     { get; set; }   // Col 5  -> text3  (UPSERT key)
        public string  Category   { get; set; }   // Col 6  -> text4
        public string  UseStatus  { get; set; }   // Col 7  -> listvalue1
        public string  SvcPtr     { get; set; }   // Col 8  -> text5
        public string  Location   { get; set; }   // Col 9  -> text6
        public string  InvDate    { get; set; }   // Col 10 -> text10
        public string  PrevLoc    { get; set; }   // Col 11 -> text11
        public string  Station    { get; set; }   // Col 12 -> text7
        public string  CatStock   { get; set; }   // Col 13 -> text12
        public string  Cmr        { get; set; }   // Col 14 -> text8
        public string  Po         { get; set; }   // Col 15 -> text9
        public bool    ExistsInDb { get; set; }
    }

    private List<EquipRow> _rows;
    private Dictionary<int, string> _companyIdToName = new Dictionary<int, string>();

    // ---------------------------------------------------------------
    // Page Load
    // ---------------------------------------------------------------
    protected void Page_Load(object sender, EventArgs e)
    {
        // Access guard
        string role  = Convert.ToString(Session["IdashUserRole"]);
        var tiles    = Session["IdashTileAccess"] as List<string>;
        bool hasAccess = UserManager.CanAccessTile(role, tiles, "excel_print")
            || UserManager.CanAccessTile(role, tiles, "admin_print")
            || UserManager.CanAccessTile(role, tiles, "admin_users");
        if (!hasAccess) { Response.Redirect("index.aspx?err=access"); return; }

        // Show file source status
        bool defaultExists = File.Exists(DefaultExcelPath);
        string uploadedName = Session[SESSION_UPLOAD_NAME] as string;
        bool usingUpload = !string.IsNullOrEmpty(Session[SESSION_UPLOAD_PATH] as string)
                        && File.Exists(Session[SESSION_UPLOAD_PATH] as string);

        if (defaultExists)
            LitAutoStatus.Text = "<div style='font-size:11px;color:#10b981;margin-top:2px;'>&#9679; File found</div>";
        else
            LitAutoStatus.Text = "<div style='font-size:11px;color:#ef4444;margin-top:2px;'>&#9675; File not found</div>";

        if (usingUpload)
            LitUploadStatus.Text = "<div style='font-size:11px;color:#10b981;margin-top:6px;'>&#9679; Using: <strong>" + HttpUtility.HtmlEncode(uploadedName) + "</strong></div>";

        // Highlight active source
        ClientScript.RegisterStartupScript(GetType(), "srcHighlight",
            "<script>document.getElementById('" + (usingUpload ? "srcUpload" : "srcAuto") + "').classList.add('active');</script>");

        try
        {
            _rows = ReadExcel();
            if (!IsPostBack)
            {
                LoadTemplates();
                RenderGrid();
            }
            PnlMain.Visible = true;
            LitConnStatus.Text = "<span style='color:#10b981;'>&#9679; CONNECTED</span>";
        }
        catch (FileNotFoundException)
        {
            PnlFileError.Visible  = true;
            LitFileError.Text     = "File not found: <code>" + HttpUtility.HtmlEncode(ActiveExcelPath) + "</code>.<br/>"
                                  + "Drop <strong>equipment.xlsx</strong> into <code>C:\\va_rfid\\excel_data\\</code> or use <strong>Browse File</strong> above.";
            LitConnStatus.Text    = "<span style='color:#ef4444;'>&#9675; FILE MISSING</span>";
        }
        catch (Exception ex)
        {
            PnlFileError.Visible  = true;
            LitFileError.Text     = HttpUtility.HtmlEncode(ex.Message);
            LitConnStatus.Text    = "<span style='color:#ef4444;'>&#9675; ERROR</span>";
        }
    }

    // ---------------------------------------------------------------
    // File Upload Handler
    // ---------------------------------------------------------------
    protected void BtnLoadFile_Click(object sender, EventArgs e)
    {
        if (!FileUpload1.HasFile)
        {
            LitMsg.Text = "<div class='alert alert-err'>&#9888; No file selected. Use the Browse button to choose an .xlsx file.</div>";
            return;
        }

        string ext = Path.GetExtension(FileUpload1.FileName).ToLowerInvariant();
        if (ext != ".xlsx" && ext != ".xls")
        {
            LitMsg.Text = "<div class='alert alert-err'>&#9888; Invalid file type. Please select an Excel file (.xlsx or .xls).</div>";
            return;
        }

        try
        {
            string uploadDir = Server.MapPath("~/App_Data/uploads");
            if (!Directory.Exists(uploadDir)) Directory.CreateDirectory(uploadDir);

            // Clean up previous upload
            string prevPath = Session[SESSION_UPLOAD_PATH] as string;
            if (!string.IsNullOrEmpty(prevPath) && File.Exists(prevPath))
            {
                try { File.Delete(prevPath); } catch { }
            }

            string safeName = Path.GetFileNameWithoutExtension(FileUpload1.FileName)
                            + "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ext;
            string savePath = Path.Combine(uploadDir, safeName);
            FileUpload1.SaveAs(savePath);

            Session[SESSION_UPLOAD_PATH] = savePath;
            Session[SESSION_UPLOAD_NAME] = FileUpload1.FileName;

            LitMsg.Text = "<div class='alert alert-ok'>&#10003; Loaded <strong>" + HttpUtility.HtmlEncode(FileUpload1.FileName)
                        + "</strong> — " + (FileUpload1.FileBytes.Length / 1024) + " KB</div>";

            // Re-read and render with new file
            _rows = ReadExcel();
            LoadTemplates();
            RenderGrid();
            PnlMain.Visible = true;
        }
        catch (Exception ex)
        {
            LitMsg.Text = "<div class='alert alert-err'>&#9888; Error loading file: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ---------------------------------------------------------------
    // Read Excel using OpenXml (already in bin via va_excel.aspx.cs)
    // ---------------------------------------------------------------
    private List<EquipRow> ReadExcel()
    {
        string filePath = ActiveExcelPath;
        var list = new List<EquipRow>();
        if (!File.Exists(filePath))
            throw new FileNotFoundException("Excel file not found", filePath);

        using (var doc = SpreadsheetDocument.Open(filePath, false))
        {
            var wbPart = doc.WorkbookPart;
            var sheet  = wbPart.Workbook.Descendants<Sheet>().First();
            var wsPart = (WorksheetPart)wbPart.GetPartById(sheet.Id);
            var sst    = wbPart.SharedStringTablePart != null ? wbPart.SharedStringTablePart.SharedStringTable : null;

            var rows = wsPart.Worksheet.Descendants<Row>().ToList();
            // Row index 0 = header, skip it
            for (int i = 1; i < rows.Count; i++)
            {
                var cells = GetCells(rows[i], sst);
                if (cells.Count == 0) continue;

                var r = new EquipRow { RowIndex = i };
                r.EntryNum  = Col(cells, 0);
                r.Mfr       = Col(cells, 1);
                r.EqName    = Col(cells, 2);
                r.Model     = Col(cells, 3);
                r.Serial    = Col(cells, 4);
                r.Category  = Col(cells, 5);
                r.UseStatus = Col(cells, 6);
                r.SvcPtr    = Col(cells, 7);
                r.Location  = Col(cells, 8);
                string rawDate = Col(cells, 9);
                double oaDate;
                if (double.TryParse(rawDate, out oaDate) && oaDate > 30000 && oaDate < 2958465)
                {
                    try { r.InvDate = DateTime.FromOADate(oaDate).ToString("yyyy-MM-dd"); }
                    catch { r.InvDate = rawDate; }
                }
                else
                {
                    r.InvDate = rawDate;
                }
                r.PrevLoc   = Col(cells, 10);
                r.Station   = Col(cells, 11);
                r.CatStock  = Col(cells, 12);
                r.Cmr       = Col(cells, 13);
                r.Po        = Col(cells, 14);

                if (string.IsNullOrWhiteSpace(r.EntryNum) && string.IsNullOrWhiteSpace(r.Serial)) continue;
                list.Add(r);
            }
        }

        // Mark rows that already exist in iDash
        if (list.Count > 0)
        {
            try
            {
                var serials = list
                    .Where(r => !string.IsNullOrWhiteSpace(r.Serial))
                    .Select(r => r.Serial.Trim())
                    .Distinct()
                    .ToList();

                if (serials.Count > 0)
                {
                    using (var conn = new SqlConnection(ConnStr))
                    {
                        conn.Open();
                        // Build parameterised IN list
                        var parms = string.Join(",", serials.Select((s, idx) => "@s" + idx));
                        var cmd = new SqlCommand(
                            "SELECT text3 FROM dbo.asset WHERE text3 IN (" + parms + ")", conn);
                        for (int idx = 0; idx < serials.Count; idx++)
                            cmd.Parameters.AddWithValue("@s" + idx, serials[idx]);

                        var existing = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                        using (var rd = cmd.ExecuteReader())
                            while (rd.Read()) existing.Add(rd.GetString(0));

                        foreach (var r in list)
                            r.ExistsInDb = !string.IsNullOrWhiteSpace(r.Serial)
                                        && existing.Contains(r.Serial.Trim());
                    }
                }
            }
            catch { /* non-fatal — just won't show badge */ }
        }

        return list;
    }

    private List<string> GetCells(Row row, SharedStringTable sst)
    {
        var result = new List<string>();
        foreach (var cell in row.Elements<Cell>())
        {
            string val = "";
            if (cell.CellValue != null)
            {
                val = cell.CellValue.Text;
                if (cell.DataType != null && cell.DataType == CellValues.SharedString && sst != null)
                {
                    int idx;
                    if (int.TryParse(val, out idx) && idx < sst.ChildElements.Count)
                        val = sst.ChildElements[idx].InnerText;
                }
            }
            // Determine column index from cell reference (A=0, B=1, ...)
            string colRef = new string(cell.CellReference.Value.TakeWhile(char.IsLetter).ToArray());
            int colIdx = 0;
            foreach (char c in colRef) colIdx = colIdx * 26 + (char.ToUpper(c) - 'A' + 1);
            colIdx--; // 0-based

            while (result.Count <= colIdx) result.Add("");
            result[colIdx] = val != null ? val.Trim() : "";
        }
        return result;
    }

    private string Col(List<string> cells, int idx)
    {
        return idx < cells.Count ? (cells[idx] ?? "").Trim() : "";
    }

    // ---------------------------------------------------------------
    // Render grid rows as HTML
    // ---------------------------------------------------------------
    private void RenderGrid()
    {
        // Ensure company names are available (may be empty on postback before LoadTemplates)
        if (_companyIdToName.Count == 0) LoadSiteOverride();

        int currentOverrideId = GetSiteOverride();
        string overrideName = currentOverrideId > 0 && _companyIdToName.ContainsKey(currentOverrideId)
            ? _companyIdToName[currentOverrideId] : null;

        LitTotal.Text = _rows.Count.ToString();
        var sb = new StringBuilder();   // main grid
        var pv = new StringBuilder();   // preview tab

        // Emit company names as JS for client-side live update
        var jsb = new StringBuilder("var companyNames={");
        bool jsFirst = true;
        foreach (var kv in _companyIdToName)
        {
            if (!jsFirst) jsb.Append(",");
            jsb.AppendFormat("\"{0}\":\"{1}\"", kv.Key,
                (kv.Value ?? "").Replace("\\", "\\\\").Replace("\"", "\\\""));
            jsFirst = false;
        }
        jsb.Append("};");
        LitCompanyJs.Text = jsb.ToString();

        foreach (var r in _rows)
        {
            string badge = r.ExistsInDb
                ? "<span class='badge badge-update' title='Already in iDash \u2014 will update'>UPDATE</span>"
                : "<span class='badge badge-new' title='New asset \u2014 will be inserted'>NEW</span>";

            string computedName = BuildAssetName(r, overrideName, TxtNamePrefix.Text);

            // Main grid: checkbox | # | Status | Computed Name | Entry# | ... all columns
            sb.AppendFormat(
                "<tr data-entry='{0}' data-station='{1}'>" +
                "<td><input type='checkbox' class='row-chk' value='{2}' /></td>" +
                "<td>{2}</td>" +
                "<td>{3}</td>" +
                "<td class='name-preview' style='font-weight:600;color:var(--accent);white-space:nowrap;'>{4}</td>" +
                "<td>{5}</td>" +
                "<td>{6}</td>" +
                "<td>{7}</td>" +
                "<td>{8}</td>" +
                "<td style='font-family:monospace;'>{9}</td>" +
                "<td>{10}</td>" +
                "<td>{11}</td>" +
                "<td>{12}</td>" +
                "<td>{13}</td>" +
                "<td>{14}</td>" +
                "<td>{15}</td>" +
                "<td>{16}</td>" +
                "<td>{17}</td>" +
                "<td>{18}</td>" +
                "<td>{19}</td>" +
                "</tr>",
                H(r.EntryNum), H(r.Station),   // {0},{1} data-attrs
                r.RowIndex,                    // {2}
                badge,                         // {3}
                H(computedName),               // {4} computed name cell
                H(r.EntryNum),                 // {5}
                H(r.Mfr),                      // {6}
                H(r.EqName),                   // {7}
                H(r.Model),                    // {8}
                H(r.Serial),                   // {9}
                H(r.Category),                 // {10}
                H(r.UseStatus),                // {11}
                H(r.Location),                 // {12}
                H(r.Station),                  // {13}
                H(r.Cmr),                      // {14}
                H(r.Po),                       // {15}
                H(r.CatStock),                 // {16}
                H(r.SvcPtr),                   // {17}
                H(r.InvDate),                  // {18}
                H(r.PrevLoc));                 // {19}

            // Preview tab: Computed Name | Entry# | Station | Serial# | Status
            pv.AppendFormat(
                "<tr data-entry='{0}' data-station='{1}'>" +
                "<td class='name-preview' style='font-weight:700;color:var(--accent);white-space:nowrap;'>{2}</td>" +
                "<td>{0}</td><td>{1}</td>" +
                "<td style='font-family:monospace;'>{3}</td>" +
                "<td>{4}</td>" +
                "</tr>",
                H(r.EntryNum), H(r.Station), H(computedName), H(r.Serial), badge);
        }
        LitRows.Text        = sb.ToString();
        LitPreviewRows.Text = pv.ToString();
    }

    private string H(string s)
    {
        return HttpUtility.HtmlEncode(s ?? "");
    }

    // ---------------------------------------------------------------
    // Load BarTender templates from dbo.template
    // ---------------------------------------------------------------
    private void LoadTemplates()
    {
        DdlTemplate.Items.Clear();
        DdlTemplate.Items.Add(new ListItem("-- Select label template --", ""));
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT DISTINCT t.id, t.name, c.name AS cname " +
                    "FROM dbo.template t LEFT JOIN dbo.company c ON c.id = t.companyid " +
                    "WHERE t.templatetype = 'Asset' OR t.templatetype IS NULL " +
                    "ORDER BY t.name, cname", conn))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        string tname = rd["name"].ToString();
                        string cname = rd["cname"] == DBNull.Value ? "" : " [" + rd["cname"] + "]";
                        DdlTemplate.Items.Add(new ListItem(tname + cname, rd["id"].ToString()));
                    }
                }
            }
        }
        catch (Exception ex)
        {
            DdlTemplate.Items.Add(new ListItem("Error loading templates: " + ex.Message, ""));
        }

        LoadSiteOverride();
    }

    private void LoadSiteOverride()
    {
        _companyIdToName.Clear();
        DdlSiteOverride.Items.Clear();
        DdlSiteOverride.Items.Add(new ListItem("Auto (from Station # column)", "0"));
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT id, name FROM dbo.company WHERE name IS NOT NULL ORDER BY name", conn))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        int    id   = rd.GetInt32(0);
                        string name = rd.GetString(1);
                        DdlSiteOverride.Items.Add(new ListItem(name, id.ToString()));
                        _companyIdToName[id] = name;
                    }
                }
            }
        }
        catch { /* non-fatal */ }
    }

    // ---------------------------------------------------------------
    // Import Only
    // ---------------------------------------------------------------
    protected void BtnImportOnly_Click(object sender, EventArgs e)
    {
        var rows   = GetSelectedRows();
        if (rows == null) return;
        int overrideCompanyId = GetSiteOverride();
        List<string> errors;
        var result = UpsertAssets(rows, overrideCompanyId, out errors);
        ShowResult(result.Count, 0, errors, false);
        RebindAfterPostback();
    }

    // ---------------------------------------------------------------
    // Import & Print
    // ---------------------------------------------------------------
    protected void BtnImportPrint_Click(object sender, EventArgs e)
    {
        if (string.IsNullOrEmpty(DdlTemplate.SelectedValue))
        {
            ShowMsg("Please select a label template before printing.", true);
            RebindAfterPostback();
            return;
        }

        int templateId;
        if (!int.TryParse(DdlTemplate.SelectedValue, out templateId))
        {
            ShowMsg("Invalid template selection.", true);
            RebindAfterPostback();
            return;
        }

        var rows    = GetSelectedRows();
        if (rows == null) return;
        int overrideCompanyId = GetSiteOverride();
        List<string> upsertErrors;
        var upserted = UpsertAssets(rows, overrideCompanyId, out upsertErrors);

        // ── Direct BarTender printing (no iDash Print Service / MQTT) ──
        // Resolve the .btw template path from the numeric template ID
        string templatePath = BarTenderApiHelper.ResolveTemplatePath(templateId.ToString());

        List<string> printErrors = new List<string>();
        int printed = 0;

        foreach (var kv in upserted)
        {
            try
            {
                var asset = kv.Value;
                var fields = new Dictionary<string, string>
                {
                    { "lblname",        asset.AssetName ?? "" },
                    { "lbldescription", asset.Description ?? "" },
                    { "lblsn",          asset.Serial ?? "" },
                    { "lbleil",         asset.Cmr ?? "" },
                    { "lblrfidtag",     asset.RfidTag ?? "" }
                };

                var result = BarTenderApiHelper.PrintDirect(templatePath, "", fields);
                if (result.Success)
                {
                    printed++;
                }
                else
                {
                    printErrors.Add("Print failed for " + asset.AssetName + ": " + result.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                printErrors.Add("Print error for " + kv.Value.AssetName + ": " + ex.Message);
            }
        }

        var allErrors = upsertErrors.Concat(printErrors).ToList();
        ShowResult(upserted.Count, printed, allErrors, true);
        RebindAfterPostback();
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------
    private List<EquipRow> GetSelectedRows()
    {
        var raw = HfSelectedRows.Value;
        if (string.IsNullOrWhiteSpace(raw))
        {
            ShowMsg("No rows selected.", true);
            return null;
        }
        var indicesList = raw.Split(',')
                         .Select(s => { int v; return int.TryParse(s.Trim(), out v) ? v : -1; })
                         .Where(v => v >= 0);
        var indices = new HashSet<int>(indicesList);

        if (_rows == null) _rows = ReadExcel();
        return _rows.Where(r => indices.Contains(r.RowIndex)).ToList();
    }

    private int GetSiteOverride()
    {
        int v;
        if (DdlSiteOverride != null && int.TryParse(DdlSiteOverride.SelectedValue, out v) && v > 0)
            return v;
        return 0;
    }

    /// <summary>
    /// Upsert rows into dbo.asset. Returns dict of serial# -> UpsertResult.
    /// MERGE on text3 (serial#). If serial is blank, falls back to INSERT with no unique key.
    /// overrideCompanyId > 0 forces all rows to that company; 0 = auto-resolve from Station #.
    /// </summary>
    private class UpsertResult
    {
        public long AssetId    { get; set; }
        public int  CompanyId  { get; set; }
        // Carry label field data for direct BarTender printing (no MQTT/Print Server)
        public string AssetName   { get; set; }
        public string Description { get; set; }
        public string Serial      { get; set; }
        public string Cmr         { get; set; }
        public string RfidTag     { get; set; }
    }

    private Dictionary<string, UpsertResult> UpsertAssets(
        List<EquipRow> rows, int overrideCompanyId, out List<string> errors)
    {
        errors = new List<string>();
        var result = new Dictionary<string, UpsertResult>(StringComparer.OrdinalIgnoreCase);

        // Pre-resolve station -> companyId
        var stationMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT name, id FROM dbo.company WHERE name IS NOT NULL", conn))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        string cname = rd.GetString(0);
                        int    cid   = rd.GetInt32(1);
                        // Map by station prefix (first 3 chars if numeric)
                        if (cname.Length >= 3 && cname.Substring(0, 3).All(char.IsDigit))
                            stationMap[cname.Substring(0, 3)] = cid;
                        stationMap[cname] = cid; // also full name
                    }
                }
            }
        }
        catch (Exception ex) { errors.Add("Could not load company list: " + ex.Message); }

        // Resolve override company name for asset naming (space-separated prefix)
        string overrideName = GetSiteOverrideName(overrideCompanyId);

        using (var conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            foreach (var r in rows)
            {
                try
                {
                    // Resolve company — override beats station auto-detect
                    int companyId = overrideCompanyId;
                    if (companyId <= 0 && !string.IsNullOrWhiteSpace(r.Station))
                    {
                        string prefix = r.Station.Length >= 3 ? r.Station.Substring(0, 3) : r.Station;
                        if (!stationMap.TryGetValue(prefix, out companyId))
                            stationMap.TryGetValue(r.Station, out companyId);
                    }
                    if (companyId <= 0 && stationMap.Count > 0)
                        companyId = stationMap.Values.Min(); // fallback to lowest

                    // Build asset name: "SITE ENTRY#" using override company name or Excel Station column
                    string assetName = BuildAssetName(r, overrideName, TxtNamePrefix.Text);
                    string rfidTag = GenerateRfidTag(r, overrideName, TxtNamePrefix.Text);

                    // Normalise location with SP prefix
                    string loc = NormaliseLoc(r.Location);
                    string prevLoc = NormaliseLoc(r.PrevLoc);

                    string serial = r.Serial != null ? r.Serial.Trim() : "";

                    long assetId;

                    // Resolve locationid
                    object dbLocId = DBNull.Value;
                    using (var cmdLoc = new SqlCommand(@"
IF NOT EXISTS (SELECT 1 FROM dbo.location WHERE name = @loc AND companyid = ISNULL(@cid, 0))
BEGIN
    INSERT INTO dbo.location (name, companyid) VALUES (@loc, ISNULL(@cid, 0));
END
SELECT id FROM dbo.location WHERE name = @loc AND companyid = ISNULL(@cid, 0);", conn))
                    {
                        cmdLoc.Parameters.AddWithValue("@loc", loc);
                        cmdLoc.Parameters.AddWithValue("@cid", companyId > 0 ? (object)companyId : DBNull.Value);
                        var obj = cmdLoc.ExecuteScalar();
                        if (obj != null && obj != DBNull.Value) dbLocId = Convert.ToInt32(obj);
                    }

                    // MERGE on name + companyid — matches the unique index index_asset_name_companyid.
                    // If an asset with this computed name already exists for this company → UPDATE all
                    // other fields. If it doesn't exist → INSERT. Serial# is synced but not the key.
                    var merge = new SqlCommand(@"
MERGE dbo.asset AS tgt
USING (SELECT @name AS n, @companyid AS cid) AS src
    ON tgt.name = src.n AND ISNULL(tgt.companyid, -1) = ISNULL(src.cid, ISNULL(tgt.companyid, -1))
WHEN MATCHED THEN
    UPDATE SET
        description           = @desc,
        text1                 = @text1,
        text2                 = @text2,
        text3                 = @serial,
        text4                 = @text4,
        text5                 = @text5,
        text6                 = @text6,
        text7                 = @text7,
        text8                 = @text8,
        text9                 = @text9,
        text10                = @text10,
        text11                = @text11,
        text12                = @text12,
        listvalue1            = @listvalue1,
        disposalstatus        = @useStatus,
        lastobservedlocation  = @loc,
        locationid            = @locId,
        rfidtag               = @rfidtag,
        assettype             = @assettype,
        lastinventoried       = @invDateObj,
        date1                 = @invDateObj,
        date2                 = @invDateObj,
        lastmodified          = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (name, description, text1, text2, text3, text4, text5, text6,
            text7, text8, text9, text10, text11, text12,
            listvalue1, disposalstatus, lastobservedlocation, locationid, rfidtag,
            assettype, lastinventoried, date1, date2,
            companyid, created, lastmodified)
    VALUES (@name, @desc, @text1, @text2, @serial, @text4, @text5, @text6,
            @text7, @text8, @text9, @text10, @text11, @text12,
            @listvalue1, @useStatus, @loc, @locId, @rfidtag,
            @assettype, @invDateObj, @invDateObj, @invDateObj,
            @companyid, GETDATE(), GETDATE())
OUTPUT inserted.id;", conn);

                    AddParms(merge, assetName, r, serial, loc, prevLoc, companyId, dbLocId, rfidTag);
                    assetId = (long)(int)merge.ExecuteScalar();

                    // Key the result dict by name (always unique per company) for print job dispatch
                    string dictKey = assetName + "|" + companyId;
                    var res = new UpsertResult
                    {
                        AssetId     = assetId,
                        CompanyId   = companyId,
                        AssetName   = assetName,
                        Description = (r.EqName ?? "").Trim(),
                        Serial      = serial,
                        Cmr         = (r.Cmr ?? "").Trim(),
                        RfidTag     = rfidTag
                    };
                    result[dictKey] = res;
                }
                catch (Exception ex)
                {
                    errors.Add("Row " + r.RowIndex + " (" + r.EntryNum + "): " + ex.Message);
                }
            }
        }
        return result;
    }

    private string GenerateRfidTag(EquipRow r, string overrideName, string namePrefix)
    {
        string sitePfx = !string.IsNullOrWhiteSpace(overrideName)
            ? overrideName.Trim()
            : (!string.IsNullOrWhiteSpace(r.Station) ? r.Station.Trim() : "");

        string rawNum = !string.IsNullOrWhiteSpace(r.EntryNum)
            ? r.EntryNum.Trim()
            : (!string.IsNullOrWhiteSpace(r.Serial) ? r.Serial.Trim() : "");

        namePrefix = namePrefix != null ? namePrefix.Trim() : "";

        string baseTag = sitePfx + namePrefix + rawNum;
        int padCount = 4 - (baseTag.Length % 4);
        return baseTag + new string('F', padCount);
    }

    private void AddParms(SqlCommand cmd, string assetName, EquipRow r,
        string serial, string loc, string prevLoc, int companyId, object dbLocId, string rfidTag)
    {
        string useStatus = string.IsNullOrWhiteSpace(r.UseStatus) ? "IN USE" : r.UseStatus.Trim().ToUpper();
        string text10Val = string.IsNullOrWhiteSpace(r.InvDate) ? "01/01/1900" : r.InvDate;
        
        object invDateObj = "1900-01-01 17:00:00.0000000 +00:00";
        DateTime parsedDate;
        if (DateTime.TryParse(r.InvDate, out parsedDate))
        {
            invDateObj = parsedDate.ToString("yyyy-MM-dd") + " 17:00:00.0000000 +00:00";
        }

        cmd.Parameters.AddWithValue("@name",       N(assetName));
        cmd.Parameters.AddWithValue("@desc",       N(r.EqName));
        cmd.Parameters.AddWithValue("@text1",      N(r.Mfr));
        cmd.Parameters.AddWithValue("@text2",      N(r.Model));
        cmd.Parameters.AddWithValue("@serial",     N(serial));
        cmd.Parameters.AddWithValue("@text4",      N(r.Category));
        cmd.Parameters.AddWithValue("@text5",      N(r.SvcPtr));
        cmd.Parameters.AddWithValue("@text6",      N(loc));
        cmd.Parameters.AddWithValue("@text7",      N(r.Station));
        cmd.Parameters.AddWithValue("@text8",      N(r.Cmr));
        cmd.Parameters.AddWithValue("@text9",      N(r.Po));
        cmd.Parameters.AddWithValue("@text10",     N(text10Val));
        cmd.Parameters.AddWithValue("@text11",     N(prevLoc));
        cmd.Parameters.AddWithValue("@text12",     N(r.CatStock));
        cmd.Parameters.AddWithValue("@assettype",  N(r.CatStock));
        cmd.Parameters.AddWithValue("@listvalue1", N(useStatus));
        cmd.Parameters.AddWithValue("@useStatus",  N(useStatus));
        cmd.Parameters.AddWithValue("@loc",        N(loc));
        cmd.Parameters.AddWithValue("@locId",      dbLocId);
        cmd.Parameters.AddWithValue("@rfidtag",    N(rfidTag));
        cmd.Parameters.AddWithValue("@invDateObj", invDateObj);
        cmd.Parameters.AddWithValue("@companyid",  companyId > 0 ? (object)companyId : DBNull.Value);
    }

    private object N(string s)
    {
        return string.IsNullOrWhiteSpace(s) ? (object)DBNull.Value : s.Trim();
    }

    private string NormaliseLoc(string loc)
    {
        if (string.IsNullOrWhiteSpace(loc)) return "SPZZUNKNOWN";
        loc = loc.Trim();
        if (loc.StartsWith("SP", StringComparison.OrdinalIgnoreCase))
            return "SP" + loc.Substring(2).TrimStart();
        return "SP" + loc;
    }

    /// <summary>
    /// Builds the asset name as "PREFIX ENTRY#". PREFIX is the override company name
    /// when Site Override is selected, otherwise the Excel Station # column value.
    /// Uses a space separator so "613" + "EE81294" → "613 EE81294".
    /// </summary>
    private string BuildAssetName(EquipRow r, string overrideName, string namePrefix)
    {
        string sitePfx = !string.IsNullOrWhiteSpace(overrideName)
            ? overrideName.Trim()
            : (r.Station ?? "").Trim();
        string np    = (namePrefix ?? "").Trim();
        string entry = np + (r.EntryNum ?? "").Trim();  // e.g. "EE" + "81294" = "EE81294"
        return string.IsNullOrWhiteSpace(sitePfx) ? entry : sitePfx + " " + entry;
    }

    /// <summary>
    /// Returns the company name for the given ID, using the cached _companyIdToName
    /// dict first, then falling back to a DB lookup (and caching the result).
    /// Returns null if id &lt;= 0 or not found.
    /// </summary>
    private string GetSiteOverrideName(int overrideId)
    {
        if (overrideId <= 0) return null;
        string cached;
        if (_companyIdToName.TryGetValue(overrideId, out cached)) return cached;
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT name FROM dbo.company WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", overrideId);
                    var res = cmd.ExecuteScalar();
                    if (res != null)
                    {
                        string name = res.ToString().Trim();
                        _companyIdToName[overrideId] = name;
                        return name;
                    }
                }
            }
        }
        catch { }
        return null;
    }

    private void ShowResult(int imported, int printed, List<string> errors, bool showPrint)
    {
        var sb = new StringBuilder();
        bool hasErrors = errors != null && errors.Count > 0;

        if (showPrint)
            sb.AppendFormat("<div class='alert alert-ok'>&#10003; <strong>{0}</strong> asset(s) imported, <strong>{1}</strong> label(s) sent to printer.</div>",
                imported, printed);
        else
            sb.AppendFormat("<div class='alert alert-ok'>&#10003; <strong>{0}</strong> asset(s) imported into iDash.</div>", imported);

        if (hasErrors)
        {
            sb.Append("<div class='alert alert-err'><strong>&#9888; Errors:</strong><ul style='margin:6px 0 0; padding-left:20px;'>");
            foreach (var err in errors)
                sb.AppendFormat("<li>{0}</li>", HttpUtility.HtmlEncode(err));
            sb.Append("</ul></div>");
        }
        LitMsg.Text = sb.ToString();
    }

    private void ShowMsg(string msg, bool isError)
    {
        string cls = isError ? "alert-err" : "alert-ok";
        LitMsg.Text = "<div class='alert " + cls + "'>" + HttpUtility.HtmlEncode(msg) + "</div>";
    }

    private void RebindAfterPostback()
    {
        if (_rows == null) { try { _rows = ReadExcel(); } catch { return; } }
        // Load templates/site list FIRST so _companyIdToName is populated for RenderGrid
        string prevTemplate = DdlTemplate.SelectedValue;
        string prevSite     = DdlSiteOverride.SelectedValue;
        LoadTemplates();
        // Restore selections lost when dropdowns were repopulated
        var tItem = DdlTemplate.Items.FindByValue(prevTemplate);
        if (tItem != null) tItem.Selected = true;
        var sItem = DdlSiteOverride.Items.FindByValue(prevSite);
        if (sItem != null) sItem.Selected = true;
        RenderGrid();
    }
}
