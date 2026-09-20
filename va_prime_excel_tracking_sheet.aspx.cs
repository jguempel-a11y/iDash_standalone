using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using ClosedXML.Excel;

public partial class va_prime_excel_tracking_sheet : System.Web.UI.Page
{
        private string ConnStr = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        public class ExcelAssetRow
        {
            public string Name     { get; set; }  // = Entry number from Excel
            public string Location { get; set; }
            public string Eil      { get; set; }
            public string Bldg     { get; set; }
            public string Descr    { get; set; }
            public string Comment  { get; set; }
            public string Tagged   { get; set; }
        }

        public class DbAssetRow
        {
            public string Name     { get; set; }  // Full DB name e.g. "613 EE72787"
            public string Location { get; set; }
            public string EilNum   { get; set; }  // Just the numeric suffix e.g. "72787"
        }

        public class LocationComparison
        {
            public string Location     { get; set; }
            public int ExcelCount      { get; set; }
            public int DbCount         { get; set; }
            public int MatchingCount   { get; set; }
            public int ExcelOnly       { get; set; }
            public int DbOnly          { get; set; }
            public int UntaggedCount   { get; set; }  // Assets in Excel with no tag recorded
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

            // Access check — only require session to be authenticated (portable across iDash versions)
            // If you want tile-based restriction, add it here

            if (!IsPostBack)
            {
                try { LoadCompanyDropdown(); } catch { }
            }
        }

        protected void BtnUpload_Click(object sender, EventArgs e)
        {
            Stream fileStream = null;

            // Option 1: Server-side file path (for admin convenience when file is on the server)
            string serverPath = (TxtServerPath.Text ?? "").Trim();
            if (!string.IsNullOrEmpty(serverPath))
            {
                if (!File.Exists(serverPath))
                {
                    ShowError("Server-side file not found at: " + serverPath);
                    return;
                }
                string extSp = Path.GetExtension(serverPath).ToLower();
                if (extSp != ".xlsx")
                {
                    ShowError("Only .xlsx files are supported.");
                    return;
                }
                fileStream = new FileStream(serverPath, FileMode.Open, FileAccess.Read);
            }
            else
            {
                // Option 2: Browser file upload
                bool hasFile = FileUploadExcel.HasFile ||
                               (FileUploadExcel.PostedFile != null && FileUploadExcel.PostedFile.ContentLength > 0);

                if (!hasFile)
                {
                    ShowError("No file received. Either select a file to upload, or enter the full server path to the Excel file.");
                    return;
                }

                string ext = Path.GetExtension(FileUploadExcel.FileName).ToLower();
                if (ext != ".xlsx")
                {
                    ShowError("Only .xlsx files are supported. Received: " + FileUploadExcel.FileName);
                    return;
                }
                fileStream = FileUploadExcel.PostedFile.InputStream;
            }


            try
            {
                var excelAssets = new List<ExcelAssetRow>();

                using (var workbook = new XLWorkbook(fileStream))
                {
                    // Find sheet called 'master list'
                    var sheet = workbook.Worksheets.FirstOrDefault(s => s.Name.Equals("master list", StringComparison.OrdinalIgnoreCase));
                    if (sheet == null)
                    {
                        // Report available sheet names to help debug
                        var names = string.Join(", ", workbook.Worksheets.Select(s => "'" + s.Name + "'"));
                        ShowError("Could not find a worksheet named 'Master List'. Found: " + names);
                        return;
                    }

                    var range = sheet.RangeUsed();
                    if (range == null)
                    {
                        ShowError("The 'Master List' worksheet is empty.");
                        return;
                    }

                    int rowCount = range.RowCount();
                    int colCount = range.ColumnCount();

                    // Map column headers — trim spaces, case-insensitive
                    int entryCol = -1, nameCol = -1, eilCol = -1, bldgCol = -1,
                        locCol = -1, commentsCol = -1, taggedCol = -1;

                    for (int c = 1; c <= colCount; c++)
                    {
                        string header = sheet.Cell(1, c).GetString().Trim().ToLower();
                        if (header == "entry")    entryCol    = c;
                        if (header == "name")     nameCol     = c;
                        if (header == "eil")      eilCol      = c;
                        if (header == "bldg")     bldgCol     = c;
                        if (header == "location") locCol      = c;
                        if (header == "comments") commentsCol = c;
                        if (header == "tagged")   taggedCol   = c;
                    }

                    // Entry is the EIL number used to build the iDash asset name
                    if (entryCol == -1)
                    {
                        ShowError("Could not find 'Entry' column in the Master List sheet. Headers found: " +
                            string.Join(", ", Enumerable.Range(1, colCount).Select(c => sheet.Cell(1, c).GetString().Trim())));
                        return;
                    }

                    for (int r = 2; r <= rowCount; r++)
                    {
                        string entry = sheet.Cell(r, entryCol).GetString().Trim();
                        if (string.IsNullOrEmpty(entry)) continue;

                        string loc     = locCol      != -1 ? sheet.Cell(r, locCol).GetString().Trim() : "Unknown";
                        string eil     = eilCol      != -1 ? sheet.Cell(r, eilCol).GetString().Trim() : "";
                        string bldg    = bldgCol     != -1 ? sheet.Cell(r, bldgCol).GetString().Trim() : "";
                        string descr   = nameCol     != -1 ? sheet.Cell(r, nameCol).GetString().Trim() : "";
                        string comment = commentsCol != -1 ? sheet.Cell(r, commentsCol).GetString().Trim() : "";
                        string tagged  = taggedCol   != -1 ? sheet.Cell(r, taggedCol).GetString().Trim() : "";

                        if (string.IsNullOrEmpty(loc)) loc = "Unknown";

                        excelAssets.Add(new ExcelAssetRow
                        {
                            Name     = entry,   // Entry number is the EIL used to match in DB
                            Location = loc,
                            Eil      = eil,
                            Bldg     = bldg,
                            Descr    = descr,
                            Comment  = comment,
                            Tagged   = tagged
                        });
                    }
                }


                if (excelAssets.Count == 0)
                {
                    ShowError("No valid assets found in the Excel sheet.");
                    return;
                }

                // Load DB Assets for the selected site
                int siteId = 0;
                if (!string.IsNullOrEmpty(DdlCompany.SelectedValue)) int.TryParse(DdlCompany.SelectedValue, out siteId);

                var dbAssets = new List<DbAssetRow>();
                using (var cn = new SqlConnection(ConnStr))
                {
                    cn.Open();
                    string sql = "SELECT a.name, a.locationname FROM dbo.v_asset a WHERE 1=1";

                    // Site filter — use the dropdown selection (no UserManager dependency)
                    if (siteId > 0)
                    {
                        sql += " AND a.companyid = @siteId";
                    }

                    using (var cmd = new SqlCommand(sql, cn))
                    {
                        if (siteId > 0) cmd.Parameters.AddWithValue("@siteId", siteId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                string name = rdr.IsDBNull(0) ? "" : rdr.GetString(0).Trim();
                                string loc = rdr.IsDBNull(1) ? "Unknown" : rdr.GetString(1).Trim();
                                if (!string.IsNullOrEmpty(name))
                                {
                                    // Extract trailing numeric portion (the EIL number) from names like "613 EE72787"
                                    string eilNum = System.Text.RegularExpressions.Regex.Match(name, @"(\d+)\s*$").Value.Trim();
                                    dbAssets.Add(new DbAssetRow { Name = name, Location = loc, EilNum = eilNum });
                                }
                            }
                        }
                    }
                }

                // Process comparison logic
                var comparisonDict = new Dictionary<string, LocationComparison>(StringComparer.OrdinalIgnoreCase);

                // Group by Excel Locations (already clean, no SP prefix)
                foreach (var ex in excelAssets)
                {
                    string loc = string.IsNullOrEmpty(ex.Location) ? "Unknown" : ex.Location;
                    if (!comparisonDict.ContainsKey(loc))
                        comparisonDict[loc] = new LocationComparison { Location = loc };
                    comparisonDict[loc].ExcelCount++;

                    // Determine if this asset is tagged:
                    // Tagged = has a value in the Tagged column, OR Comments contains "TAGGED"
                    bool isTagged = !string.IsNullOrEmpty(ex.Tagged) ||
                                   (ex.Comment ?? "").IndexOf("TAGGED", StringComparison.OrdinalIgnoreCase) >= 0;
                    if (!isTagged)
                        comparisonDict[loc].UntaggedCount++;
                }

                // Group by DB Locations — DB has "SP " prefix, Excel doesn't. Strip it for grouping.
                foreach (var db in dbAssets)
                {
                    string loc = NormalizeLoc(db.Location);
                    if (!comparisonDict.ContainsKey(loc))
                        comparisonDict[loc] = new LocationComparison { Location = loc };
                    comparisonDict[loc].DbCount++;
                }

                // Build lookup dictionaries keyed by EIL number (the trailing numeric in asset name)
                // Excel Entry column = "72787", DB name = "613 EE72787" => EilNum = "72787"
                var dbByEil = new Dictionary<string, DbAssetRow>(StringComparer.OrdinalIgnoreCase);
                foreach (var a in dbAssets) { if (!string.IsNullOrEmpty(a.EilNum)) dbByEil[a.EilNum] = a; }

                var exByEntry = new Dictionary<string, ExcelAssetRow>(StringComparer.OrdinalIgnoreCase);
                foreach (var a in excelAssets) { exByEntry[a.Name] = a; }

                // Reset detailed counts
                foreach (var v in comparisonDict.Values)
                {
                    v.MatchingCount = 0;
                    v.ExcelOnly = 0;
                    v.DbOnly = 0;
                }

                foreach (var ex in excelAssets)
                {
                    string exLoc = string.IsNullOrEmpty(ex.Location) ? "Unknown" : ex.Location;
                    if (dbByEil.ContainsKey(ex.Name))
                    {
                        comparisonDict[exLoc].MatchingCount++;
                    }
                    else
                    {
                        comparisonDict[exLoc].ExcelOnly++;

                    }
                }

                foreach (var db in dbAssets)
                {
                    // Normalize DB location (strip "SP " prefix) to match Excel location keys
                    string dbLoc = NormalizeLoc(db.Location);
                    // Only add to DbOnly if this DB location exists in our comparison dict (from Excel)
                    if (!exByEntry.ContainsKey(db.EilNum) && comparisonDict.ContainsKey(dbLoc))
                    {
                        // In DB, but completely missing from Excel
                        comparisonDict[dbLoc].DbOnly++;
                    }
                }

                var results = comparisonDict.Values.OrderBy(v => v.Location).ToList();
                
                var js = new JavaScriptSerializer { MaxJsonLength = 50000000 };
                string jsonResult = js.Serialize(results);
                
                LitResultJson.Text = "<script>window.CompareData = " + jsonResult + "; initGrid();</script>";
                PanelResults.Visible = true;
                LitMsg.Text = "";
            }
            catch (Exception ex)
            {
                ShowError("Error processing file: " + ex.Message);
            }
        }

        // Self-contained company dropdown loader — no UserManager dependency
        private void LoadCompanyDropdown()
        {
            DdlCompany.Items.Clear();
            DdlCompany.Items.Add(new System.Web.UI.WebControls.ListItem("All Sites", "0"));
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT id, name FROM dbo.company ORDER BY name", cn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        string id   = rdr.GetInt32(0).ToString();
                        string name = rdr.IsDBNull(1) ? id : rdr.GetString(1);
                        DdlCompany.Items.Add(new System.Web.UI.WebControls.ListItem(name, id));
                    }
                }
            }
        }

        // Normalize a DB location by stripping leading "SP " prefix so it matches Excel locations

        // e.g. "SP 100-501B" => "100-501B"
        private static string NormalizeLoc(string loc)
        {
            if (string.IsNullOrEmpty(loc)) return "Unknown";
            loc = loc.Trim();
            // Strip leading "SP " (case-insensitive)
            if (loc.StartsWith("SP ", StringComparison.OrdinalIgnoreCase))
                loc = loc.Substring(3).Trim();
            return string.IsNullOrEmpty(loc) ? "Unknown" : loc;
        }

        private void ShowError(string msg)
        {
            LitMsg.Text = "<div class='err-msg'>" + msg + "</div>";
            PanelResults.Visible = false;
        }
}
