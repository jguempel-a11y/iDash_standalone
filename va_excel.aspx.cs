using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Spreadsheet;

/// <summary>
/// Code-behind for va_excel.aspx.
/// Handles the merging of multiple "Equipment.xlsx" files into a single "512Data" Excel template.
/// </summary>
public partial class va_excel : System.Web.UI.Page
{
    // Folder where the merged file is stored
    private const string OutputFolder = @"C:\VA_RFID\VA_EXCEL";
    // Name of the output merged file
    private const string OutputFileName = "512Data_Merged.xlsx";
    // The specific sheet name in the template to merge data into
    private const string TargetSheetName = "512Data";

    /// <summary>
    /// Page Load event handler.
    /// </summary>
    protected void Page_Load(object sender, EventArgs e)
    {
    }

    /// <summary>
    /// Handles the "Merge & Save" button click.
    /// Processes uploaded files and merges them into the template.
    /// </summary>
    protected void BtnMerge_Click(object sender, EventArgs e)
    {
        // Reset status labels
        LblStatus.Text = "";
        LblSummary.Text = "";
        LitPreview.Text = "";
        LblStatus.CssClass = "status";
        LblSummary.CssClass = "status";
        BtnDownloadMerged.Visible = false;

        try
        {
            // Validation: Check if template is uploaded
            if (!FuTemplate.HasFile)
            {
                SetStatus("Please upload 512Data Template v003.xlsx.", true);
                return;
            }

            // Validation: Count selected equipment files
            int fileCount = 0;
            System.Collections.IEnumerable filesEnum = FuEquipment.PostedFiles;
            foreach (object o in filesEnum)
            {
                HttpPostedFile f = o as HttpPostedFile;
                if (f != null && f.ContentLength > 0)
                    fileCount++;
            }

            if (fileCount == 0)
            {
                SetStatus("Please select at least one Equipment.xlsx file.", true);
                return;
            }

            if (fileCount > 5)
            {
                SetStatus("Please select no more than 5 Equipment.xlsx files.", true);
                return;
            }

            // Ensure output directory exists
            if (!Directory.Exists(OutputFolder))
                Directory.CreateDirectory(OutputFolder);

            string mergedPath = Path.Combine(OutputFolder, OutputFileName);

            // Save uploaded template to a temporary path
            string tempTemplatePath = Path.Combine(
                OutputFolder,
                "TemplateUpload_" + Guid.NewGuid().ToString("N") + ".xlsx");

            FuTemplate.SaveAs(tempTemplatePath);

            // If merged file doesn't exist, create it from the uploaded template
            if (!File.Exists(mergedPath))
                File.Copy(tempTemplatePath, mergedPath);

            int totalMergedRows = 0;
            int totalSkippedRows = 0;
            System.Text.StringBuilder perFileSummary = new System.Text.StringBuilder();

            // Process each uploaded equipment file
            filesEnum = FuEquipment.PostedFiles;
            foreach (object o in filesEnum)
            {
                HttpPostedFile file = o as HttpPostedFile;
                if (file == null || file.ContentLength == 0)
                    continue;

                string mismatchMessage = "";
                int mergedRowsThisFile = 0;
                int skippedRowsThisFile = 0;

                // Merge into the main file
                using (MemoryStream ms = new MemoryStream())
                {
                    file.InputStream.CopyTo(ms);
                    ms.Position = 0;

                    // Execute logic
                    mergedRowsThisFile = MergeEquipmentIntoTemplate(ms, mergedPath, out mismatchMessage, out skippedRowsThisFile);
                }

                totalMergedRows += mergedRowsThisFile;
                totalSkippedRows += skippedRowsThisFile;

                if (perFileSummary.Length > 0)
                    perFileSummary.Append("<br/>");

                string safeName = HttpUtility.HtmlEncode(Path.GetFileName(file.FileName));
                perFileSummary.Append(string.Format("{0}: {1} row(s) merged, {2} duplicate(s) skipped.", safeName, mergedRowsThisFile, skippedRowsThisFile));

                if (!string.IsNullOrEmpty(mismatchMessage))
                {
                    perFileSummary.Append(" (" + HttpUtility.HtmlEncode(mismatchMessage) + ")");
                }
            }

            // Cleanup temp template
            try { File.Delete(tempTemplatePath); } catch { }

            SetStatus("Merge completed successfully.", false);

            LblSummary.CssClass = "status ok";
            LblSummary.Text =
                string.Format("{0} file(s) processed. Total {1} row(s) merged. Total {2} duplicate(s) skipped.", fileCount, totalMergedRows, totalSkippedRows)
                + (perFileSummary.Length > 0 ? "<br/>" + perFileSummary.ToString() : "");

            BtnDownloadMerged.Visible = true;
        }
        catch (Exception ex)
        {
            SetStatus("Error during merge: " + ex.Message, true);
        }
    }

    /// <summary>
    /// Handles the "Download Merged File" button click.
    /// Allows the user to download the current state of the merged Excel file.
    /// </summary>
    protected void BtnDownloadMerged_Click(object sender, EventArgs e)
    {
        string mergedPath = Path.Combine(OutputFolder, OutputFileName);
        if (!File.Exists(mergedPath))
        {
            SetStatus("Merged file not found.", true);
            BtnDownloadMerged.Visible = false;
            return;
        }

        Response.Clear();
        Response.ContentType =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        Response.AddHeader("Content-Disposition", "attachment; filename=" + OutputFileName);
        Response.WriteFile(mergedPath);
        Response.End();
    }

    /// <summary>
    /// Handles the "Reset Merged File" button click.
    /// Deletes the existing merged file so the next merge starts fresh.
    /// </summary>
    protected void BtnResetMerged_Click(object sender, EventArgs e)
    {
        LblStatus.Text = "";
        LblSummary.Text = "";
        LitPreview.Text = "";
        LblStatus.CssClass = "status";
        LblSummary.CssClass = "status";

        try
        {
            string mergedPath = Path.Combine(OutputFolder, OutputFileName);
            if (File.Exists(mergedPath))
            {
                File.Delete(mergedPath);
                SetStatus("Merged file reset. It will be recreated on next merge.", false);
            }
            else
            {
                SetStatus("No merged file found to reset.", false);
            }

            BtnDownloadMerged.Visible = false;
        }
        catch (Exception ex)
        {
            SetStatus("Error resetting merged file: " + ex.Message, true);
        }
    }

    /// <summary>
    /// Handles the "Preview" button click.
    /// Shows the first few rows of the uploaded files combined.
    /// </summary>
    protected void BtnPreview_Click(object sender, EventArgs e)
    {
        LblStatus.Text = "";
        LblSummary.Text = "";
        LblStatus.CssClass = "status";
        LblSummary.CssClass = "status";
        LitPreview.Text = "";

        try
        {
            // Collect equipment files (same logic as merge)
            System.Collections.IEnumerable filesEnum = FuEquipment.PostedFiles;
            List<MemoryStream> streams = new List<MemoryStream>();

            foreach (object o in filesEnum)
            {
                HttpPostedFile f = o as HttpPostedFile;
                if (f == null || f.ContentLength == 0)
                    continue;

                MemoryStream ms = new MemoryStream();
                f.InputStream.CopyTo(ms);
                ms.Position = 0;
                streams.Add(ms);
            }

            if (streams.Count == 0)
            {
                SetStatus("Please select at least one Equipment.xlsx file to preview.", true);
                return;
            }

            string html = BuildCombinedPreviewHtml(streams);
            if (html == "")
            {
                SetStatus("No data rows found for preview.", false);
            }
            else
            {
                LitPreview.Text = html;
                SetStatus("Combined preview loaded (up to first 10 rows across selected files).", false);
            }
        }
        catch (Exception ex)
        {
            SetStatus("Error generating preview: " + ex.Message, true);
        }
    }

    // ======================================================
    // MERGE LOGIC (single file) + SORT BY BARCODE
    // ======================================================

    /// <summary>
    /// Merges a single Equipment Excel stream into the target Template file.
    /// Includes validation, duplicate checking, mapping, and sorting.
    /// </summary>
    /// <param name="equipmentStream">Stream of the uploaded equipment file</param>
    /// <param name="mergedTemplatePath">Path to the target master file</param>
    /// <param name="mismatchMessage">Output parameter for column mismatch warnings</param>
    /// <param name="skippedRows">Output parameter for count of skipped duplicate rows</param>
    /// <returns>Number of rows successfully merged (added)</returns>
    private int MergeEquipmentIntoTemplate(
        Stream equipmentStream,
        string mergedTemplatePath,
        out string mismatchMessage,
        out int skippedRows)
    {
        mismatchMessage = "";
        skippedRows = 0;
        int mergeCount = 0;

        // Definition of Source Logic Header -> Target File Header
        Dictionary<string, string> headerMap =
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "ENTRY NUMBER",            "BARCODE" },
            { "MANUFACTURER",            "MANUFACTURER" },
            { "MFGR. EQUIPMENT NAME",    "DESCRIPTION" },
            { "MODEL",                   "MODEL" },
            { "SERIAL #",                "Serial" },  // fixed mapping
            { "EQUIPMENT CATEGORY",      "CATEGORY" },
            { "USE STATUS",              "STATUS" },
            { "SERVICE POINTER",         "SERVICE" },
            { "LOCATION",                "LOCATION" },
            { "PHYSICAL INVENTORY DATE", "LOCATIONINVDATE" },
            { "PREVIOUS LOCATION",       "PREVIOUSLOCATION" },
            { "STATION NUMBER",          "SITE" },
            { "CATEGORY STOCK NUMBER",   "CSN" },
            { "CMR",                     "EIL" },
            { "PURCHASE ORDER #",        "PO" }
        };

        // Open both documents
        using (SpreadsheetDocument equipDoc = SpreadsheetDocument.Open(equipmentStream, false))
        using (SpreadsheetDocument templateDoc = SpreadsheetDocument.Open(mergedTemplatePath, true))
        {
            // 1. Read Source (Equipment) Data
            WorksheetPart equipSheet = GetFirstWorksheetPart(equipDoc);
            if (equipSheet == null)
                throw new Exception("No worksheet in Equipment.xlsx.");

            SheetData equipData = equipSheet.Worksheet.GetFirstChild<SheetData>();
            List<Row> equipRows = equipData.Elements<Row>().ToList();
            if (equipRows.Count < 2) return 0; // Only header or empty

            // Identify Source Headers
            Row equipHeaderRow = equipRows[0];
            Dictionary<int, string> equipHeaders = new Dictionary<int, string>();

            foreach (Cell c in equipHeaderRow.Elements<Cell>())
            {
                int colIdx = GetColumnIndexFromCellReference(c.CellReference);
                string header = GetCellValue(equipDoc, c).Trim();
                if (header != "")
                    equipHeaders[colIdx] = header;
            }

            // 2. Validate Columns (compare expected vs present)
            HashSet<string> presentCols =
                new HashSet<string>(
                    equipHeaders.Values.Select(x => x.ToUpperInvariant()),
                    StringComparer.OrdinalIgnoreCase);

            HashSet<string> expectedCols =
                new HashSet<string>(
                    headerMap.Keys.Select(x => x.ToUpperInvariant()),
                    StringComparer.OrdinalIgnoreCase);

            List<string> missing =
                expectedCols.Where(x => !presentCols.Contains(x)).ToList();

            List<string> extra =
                presentCols.Where(x => !expectedCols.Contains(x)).ToList();

            if (missing.Count > 0 || extra.Count > 0)
            {
                System.Text.StringBuilder mm = new System.Text.StringBuilder();
                if (missing.Count > 0)
                    mm.Append("Missing: " + string.Join(", ", missing.ToArray()) + ".");
                if (extra.Count > 0)
                {
                    if (mm.Length > 0) mm.Append(" ");
                    mm.Append("Extra: " + string.Join(", ", extra.ToArray()) + ".");
                }
                mismatchMessage = mm.ToString();
            }

            // 3. Extract mapped data from source
            List<Dictionary<string, string>> dataRows =
                new List<Dictionary<string, string>>();

            foreach (Row r in equipRows.Skip(1))
            {
                Dictionary<string, string> rowdata =
                    new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                bool any = false;

                foreach (Cell c in r.Elements<Cell>())
                {
                    int colIdx = GetColumnIndexFromCellReference(c.CellReference);
                    string header;
                    if (!equipHeaders.TryGetValue(colIdx, out header))
                        continue;

                    string val = GetCellValue(equipDoc, c).Trim();
                    if (val != "") any = true;

                    rowdata[header.ToUpperInvariant()] = val;
                }

                if (any) dataRows.Add(rowdata);
            }

            if (dataRows.Count == 0) return 0;

            // 4. Prepare Target (Template) for appending
            WorksheetPart targetSheet = GetWorksheetPartByName(templateDoc, TargetSheetName);
            if (targetSheet == null)
                throw new Exception("Template sheet '" + TargetSheetName + "' not found.");

            SheetData targetData = targetSheet.Worksheet.GetFirstChild<SheetData>();
            List<Row> templateRows = targetData.Elements<Row>().ToList();

            if (templateRows.Count == 0)
                throw new Exception("Template sheet has no header row.");

            Row templateHeaderRow = templateRows[0];

            // Map Target Headers to Column Index
            List<string> headerOrder = new List<string>();
            Dictionary<string, int> headerToIndex =
                new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

            foreach (Cell c in templateHeaderRow.Elements<Cell>())
            {
                string head = GetCellValue(templateDoc, c).Trim();
                if (head == "") continue;

                int colIdx = GetColumnIndexFromCellReference(c.CellReference);
                string norm = head.ToUpperInvariant();

                if (!headerToIndex.ContainsKey(norm))
                {
                    headerToIndex[norm] = colIdx;
                    headerOrder.Add(head);
                }
            }

            // Find Barcode Column Index in Target
            int barcodeColIndex = -1;
            if (headerToIndex.ContainsKey("BARCODE"))
                barcodeColIndex = headerToIndex["BARCODE"];
            
            // Build set of existing barcodes to prevent duplicates
            HashSet<string> existingBarcodes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (barcodeColIndex != -1)
            {
                foreach (Row r in templateRows.Skip(1)) // Skip header
                {
                    foreach (Cell c in r.Elements<Cell>())
                    {
                        if (GetColumnIndexFromCellReference(c.CellReference) == barcodeColIndex)
                        {
                            string code = GetCellValue(templateDoc, c).Trim();
                            if (!string.IsNullOrEmpty(code))
                                existingBarcodes.Add(code);
                            break; // Optimization: found the barcode cell for this row
                        }
                    }
                }
            }

            // Determine next available row index
            uint lastRow =
                templateRows
                .Where(x => x.RowIndex != null)
                .Select(x => x.RowIndex.Value)
                .DefaultIfEmpty(1U)
                .Max();

            // 5. Append new rows (with duplicate check)
            foreach (Dictionary<string, string> row in dataRows)
            {
                string entry;
                row.TryGetValue("ENTRY NUMBER", out entry);
                entry = (entry ?? "").Trim();
                if (entry == "") continue;

                // Construct generated barcode
                // Format seems to be "512 EE" + [Entry Number]
                string generatedBarcode = "512 EE" + entry;

                // Check for duplicate
                if (existingBarcodes.Contains(generatedBarcode))
                {
                    skippedRows++;
                    continue; // Skip this row
                }

                // Add to set so we don't add it again within this same batch
                existingBarcodes.Add(generatedBarcode);

                Dictionary<string, string> targetValues =
                    new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

                targetValues["BARCODE"] = generatedBarcode;

                foreach (KeyValuePair<string, string> kv in headerMap)
                {
                    string srcHeader = kv.Key.ToUpperInvariant();
                    string destHeader = kv.Value.ToUpperInvariant();

                    if (srcHeader == "ENTRY NUMBER") continue;

                    string v;
                    row.TryGetValue(srcHeader, out v);
                    targetValues[destHeader] = (v ?? "").Trim();
                }

                lastRow++;
                Row newRow = new Row();
                newRow.RowIndex = lastRow;

                foreach (string h in headerOrder)
                {
                    string norm = h.ToUpperInvariant();
                    string v;
                    if (!targetValues.TryGetValue(norm, out v)) continue;
                    if (v == "") continue;

                    int colIdx;
                    if (!headerToIndex.TryGetValue(norm, out colIdx)) continue;

                    string colName = GetColumnNameFromIndex(colIdx);
                    string cellRef = colName + lastRow;

                    Cell cell = new Cell();
                    cell.CellReference = cellRef;
                    cell.DataType = CellValues.String;
                    cell.CellValue = new CellValue(v);

                    newRow.Append(cell);
                }

                targetData.Append(newRow);
                mergeCount++;
            }

            // 6. Sort by Barcode (if barcode column exists)
            if (barcodeColIndex != -1)
            {
                // Refresh list of rows from DOM (since we appended some)
                List<Row> allRows = targetData.Elements<Row>().ToList();
                Row headerRow = templateHeaderRow;

                List<Row> dataOnly =
                    allRows.Where(r => r.RowIndex != null &&
                                       r.RowIndex.Value > headerRow.RowIndex.Value).ToList();

                List<Row> sortedRows = dataOnly
                    .OrderBy(r =>
                    {
                        string barcode = "";
                        foreach (Cell c in r.Elements<Cell>())
                        {
                            int colIdx = GetColumnIndexFromCellReference(c.CellReference);
                            if (colIdx == barcodeColIndex)
                            {
                                barcode = GetCellValue(templateDoc, c);
                                break;
                            }
                        }
                        return barcode;
                    })
                    .ToList();

                // Remove logic: must detach all data rows first
                foreach (Row r in dataOnly)
                    targetData.RemoveChild(r);

                // Re-append in sorted order, updating row indices & cell refs
                uint currentRowIndex = headerRow.RowIndex != null ? headerRow.RowIndex.Value : 1U;

                foreach (Row r in sortedRows)
                {
                    currentRowIndex++;
                    r.RowIndex = currentRowIndex;

                    foreach (Cell c in r.Elements<Cell>())
                    {
                        // Update column letter portion of ref
                        string colLetters = "";
                        if (!string.IsNullOrEmpty(c.CellReference))
                        {
                            colLetters = new string(
                                c.CellReference.ToString().Where(Char.IsLetter).ToArray());
                        }

                        int colIdx;
                        if (colLetters != "")
                            colIdx = GetColumnIndexFromName(colLetters);
                        else
                            colIdx = GetColumnIndexFromCellReference(c.CellReference);

                        string colName = GetColumnNameFromIndex(colIdx);
                        c.CellReference = colName + currentRowIndex;
                    }

                    targetData.Append(r);
                }
            }

            // Save changes
            targetSheet.Worksheet.Save();
            templateDoc.WorkbookPart.Workbook.Save();
        }

        return mergeCount;
    }

    // ======================================================
    // COMBINED PREVIEW (FIRST 10 ROWS ACROSS FILES)
    // ======================================================

    /// <summary>
    /// Generates an HTML table previewing the first 10 rows of the selected files.
    /// </summary>
    private string BuildCombinedPreviewHtml(List<MemoryStream> streams)
    {
        if (streams == null || streams.Count == 0)
            return "";

        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        List<string> headerCells = null;
        List<List<string>> dataRows = new List<List<string>>();
        int totalDataRows = 0;

        foreach (MemoryStream ms in streams)
        {
            ms.Position = 0;
            using (SpreadsheetDocument doc = SpreadsheetDocument.Open(ms, false))
            {
                WorksheetPart sheet = GetFirstWorksheetPart(doc);
                if (sheet == null)
                    continue;

                SheetData data = sheet.Worksheet.GetFirstChild<SheetData>();
                List<Row> rows = data.Elements<Row>().ToList();
                if (rows.Count == 0)
                    continue;

                // Header
                Row headerRow = rows[0];
                Dictionary<int, string> headerVals = new Dictionary<int, string>();
                foreach (Cell c in headerRow.Elements<Cell>())
                {
                    int colIdx = GetColumnIndexFromCellReference(c.CellReference);
                    headerVals[colIdx] = GetCellValue(doc, c);
                }

                int maxCol = headerVals.Keys.Count > 0 ? headerVals.Keys.Max() : 0;
                if (maxCol == 0) continue;

                if (headerCells == null)
                {
                    headerCells = new List<string>();
                    for (int i = 1; i <= maxCol; i++)
                    {
                        string val;
                        headerVals.TryGetValue(i, out val);
                        headerCells.Add(val ?? "");
                    }
                }

                // Data rows
                for (int rIndex = 1; rIndex < rows.Count && totalDataRows < 10; rIndex++)
                {
                    Row r = rows[rIndex];
                    Dictionary<int, string> cellVals = new Dictionary<int, string>();
                    foreach (Cell c in r.Elements<Cell>())
                    {
                        int colIdx = GetColumnIndexFromCellReference(c.CellReference);
                        cellVals[colIdx] = GetCellValue(doc, c);
                    }

                    List<string> rowCells = new List<string>();
                    for (int i = 1; i <= headerCells.Count; i++)
                    {
                        string val;
                        cellVals.TryGetValue(i, out val);
                        rowCells.Add(val ?? "");
                    }

                    dataRows.Add(rowCells);
                    totalDataRows++;
                }

                if (totalDataRows >= 10)
                    break;
            }
        }

        if (headerCells == null || dataRows.Count == 0)
            return "";

        sb.Append("<h2>Combined Preview (first 10 rows)</h2>");
        sb.Append("<table class='preview-table'>");
        sb.Append("<tr>");
        foreach (string h in headerCells)
        {
            string safe = (h ?? "").Replace("<", "&lt;").Replace(">", "&gt;");
            sb.Append("<th>" + safe + "</th>");
        }
        sb.Append("</tr>");

        foreach (List<string> row in dataRows)
        {
            sb.Append("<tr>");
            foreach (string cell in row)
            {
                string safe = (cell ?? "").Replace("<", "&lt;").Replace(">", "&gt;");
                sb.Append("<td>" + safe + "</td>");
            }
            sb.Append("</tr>");
        }

        sb.Append("</table>");
        return sb.ToString();
    }

    // ======================================================
    // HELPERS
    // ======================================================

    /// <summary>
    /// Updates the status label on the UI.
    /// </summary>
    /// <param name="msg">Message to display</param>
    /// <param name="error">True for error (red), False for success/info (green)</param>
    private void SetStatus(string msg, bool error)
    {
        LblStatus.Text = msg;
        LblStatus.CssClass = error ? "status err" : "status ok";
    }

    /// <summary>
    /// OpenXML Helper: Gets the first worksheet part from a document.
    /// </summary>
    private WorksheetPart GetFirstWorksheetPart(SpreadsheetDocument doc)
    {
        WorkbookPart wb = doc.WorkbookPart;
        Sheet s = wb.Workbook.Sheets.Elements<Sheet>().FirstOrDefault();
        if (s == null) return null;
        return (WorksheetPart)wb.GetPartById(s.Id);
    }

    /// <summary>
    /// OpenXML Helper: Gets a worksheet part by its visible sheet name.
    /// </summary>
    private WorksheetPart GetWorksheetPartByName(SpreadsheetDocument doc, string name)
    {
        WorkbookPart wb = doc.WorkbookPart;
        Sheet s = wb.Workbook.Sheets.Elements<Sheet>()
            .FirstOrDefault(x => x.Name != null &&
                                 x.Name.Value.Equals(name, StringComparison.OrdinalIgnoreCase));
        if (s == null) return null;
        return (WorksheetPart)wb.GetPartById(s.Id);
    }

    /// <summary>
    /// OpenXML Helper: Gets the text value of a cell, resolving shared strings if needed.
    /// </summary>
    private string GetCellValue(SpreadsheetDocument doc, Cell cell)
    {
        if (cell == null || cell.CellValue == null)
            return "";

        string value = cell.CellValue.InnerText;

        if (cell.DataType != null && cell.DataType.Value == CellValues.SharedString)
        {
            SharedStringTablePart sst = doc.WorkbookPart.SharedStringTablePart;
            if (sst != null)
            {
                int idx;
                if (int.TryParse(value, out idx))
                {
                    SharedStringItem item = sst.SharedStringTable.Elements<SharedStringItem>()
                        .ElementAtOrDefault(idx);
                    if (item != null)
                        return item.InnerText ?? "";
                }
            }
        }

        return value;
    }

    /// <summary>
    /// OpenXML Helper: Calculates column index (1-based) from a cell reference (e.g., "A1" -> 1, "B2" -> 2).
    /// </summary>
    private int GetColumnIndexFromCellReference(string cellRef)
    {
        if (string.IsNullOrEmpty(cellRef))
            return 0;

        string col = new string(cellRef.Where(Char.IsLetter).ToArray());
        return GetColumnIndexFromName(col);
    }

    /// <summary>
    /// OpenXML Helper: Calculates column index (1-based) from a column name (e.g., "A" -> 1, "AA" -> 27).
    /// </summary>
    private int GetColumnIndexFromName(string col)
    {
        if (string.IsNullOrEmpty(col))
            return 0;

        int sum = 0;
        foreach (char c in col.ToUpperInvariant())
        {
            if (c < 'A' || c > 'Z') continue;
            sum = (sum * 26) + (c - 'A' + 1);
        }
        return sum;
    }

    /// <summary>
    /// OpenXML Helper: Calculates column name from an index (e.g., 1 -> "A").
    /// </summary>
    private string GetColumnNameFromIndex(int i)
    {
        string result = "";
        while (i > 0)
        {
            int mod = (i - 1) % 26;
            result = Convert.ToChar('A' + mod) + result;
            i = (i - 1) / 26;
        }
        return result;
    }
}
