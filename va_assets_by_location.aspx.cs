using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Text;

public partial class va_assets_by_location : System.Web.UI.Page
{
    private string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return (cs == null) ? "" : cs.ConnectionString;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Merged into va_location_list.aspx — redirect old bookmarks
        Response.Redirect("va_location_list.aspx", true);
    }

    protected void Page_PreRender(object sender, EventArgs e)
    {
        if (GridAssetsByLocation.Rows.Count > 0)
        {
            GridAssetsByLocation.UseAccessibleHeader = true;
            GridAssetsByLocation.HeaderRow.TableSection = TableRowSection.TableHeader;
        }
        if (GridAssetFilterDetail.Rows.Count > 0)
        {
            GridAssetFilterDetail.UseAccessibleHeader = true;
            GridAssetFilterDetail.HeaderRow.TableSection = TableRowSection.TableHeader;
        }
        if (GridAssetsDetail.Rows.Count > 0)
        {
            GridAssetsDetail.UseAccessibleHeader = true;
            GridAssetsDetail.HeaderRow.TableSection = TableRowSection.TableHeader;
        }
    }

    private void LoadCompanies()
    {
        try
        {
            using (var con = new SqlConnection(ConnStr))
            {
                con.Open();
                using (var cmd = new SqlCommand("SELECT id, name FROM dbo.company ORDER BY name", con))
                using (var rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField  = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }
                DdlCompany.Items.Insert(0, new ListItem("All Sites", "0"));
            }
        }
        catch { }
    }

    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        LoadSummary();
    }

    private string GetCompanyFilter()
    {
        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
            return " AND a.companyid = " + DdlCompany.SelectedValue;
        return "";
    }

    private void LoadSummary()
    {
        // Reset state
        TxtLocationSearch.Text = "";
        PanelAssetsDetail.Visible = false;
        PanelAssetFilterDetail.Visible = false;
        LitSelectedLocation.Text = "";
        LitFilterRange.Text = "";

        string sql = @"
        WITH AssetAges AS (
            SELECT 
                a.locationname AS Location,
                a.name AS AssetName,
                a.description,
                a.lastinventoried,
                DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS DaysSince,
                CASE 
                    WHEN a.lastinventoried IS NULL THEN 'Unknown'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -3, GETDATE()) THEN '0-3 Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -6, GETDATE()) THEN '4-6 Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -9, GETDATE()) THEN '7-9 Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -12, GETDATE()) THEN '10-12 Months'
                    ELSE '13+ Months'
                END AS AgeBucket
            FROM dbo.v_asset a
            WHERE a.locationname IS NOT NULL" + GetCompanyFilter() + @"
        )
        , LocationSummary AS (
            SELECT 
                Location,
                COUNT(*) AS TotalAssets,
                SUM(CASE WHEN AgeBucket = '0-3 Months' THEN 1 ELSE 0 END) AS Count_0_3,
                SUM(CASE WHEN AgeBucket = '4-6 Months' THEN 1 ELSE 0 END) AS Count_4_6,
                SUM(CASE WHEN AgeBucket = '7-9 Months' THEN 1 ELSE 0 END) AS Count_7_9,
                SUM(CASE WHEN AgeBucket = '10-12 Months' THEN 1 ELSE 0 END) AS Count_10_12,
                SUM(CASE WHEN AgeBucket = '13+ Months' THEN 1 ELSE 0 END) AS Count_13plus
            FROM AssetAges
            GROUP BY Location
        )
        SELECT
            s.Location,
            s.TotalAssets,
            s.Count_0_3,
            s.Count_4_6,
            s.Count_7_9,
            s.Count_10_12,
            s.Count_13plus,
            CAST(100.0 * s.Count_0_3 / NULLIF(s.TotalAssets, 0) AS DECIMAL(5,1)) AS Pct_0_3,
            CAST(100.0 * (s.Count_0_3 + s.Count_4_6) / NULLIF(s.TotalAssets, 0) AS DECIMAL(5,1)) AS Pct_0_6,
            CAST(100.0 * (s.Count_0_3 + s.Count_4_6 + s.Count_7_9) / NULLIF(s.TotalAssets, 0) AS DECIMAL(5,1)) AS Pct_0_9,
            CAST(100.0 * (s.Count_0_3 + s.Count_4_6 + s.Count_7_9 + s.Count_10_12) / NULLIF(s.TotalAssets, 0) AS DECIMAL(5,1)) AS Pct_0_12
        FROM LocationSummary s
        ORDER BY s.Location ASC;";

        var dt = Run(sql, null);
        Bind(GridAssetsByLocation, dt, "Location ASC");

        LitAssetsByLocationTotal.Text = "";

        if (dt != null && dt.Rows.Count > 0)
        {
            int totalAssets = dt.AsEnumerable().Sum(r => r.Field<int>("TotalAssets"));
            int cnt03   = dt.AsEnumerable().Sum(r => r.Field<int>("Count_0_3"));
            int cnt46   = dt.AsEnumerable().Sum(r => r.Field<int>("Count_4_6"));
            int cnt79   = dt.AsEnumerable().Sum(r => r.Field<int>("Count_7_9"));
            int cnt1012 = dt.AsEnumerable().Sum(r => r.Field<int>("Count_10_12"));
            int cnt13   = dt.AsEnumerable().Sum(r => r.Field<int>("Count_13plus"));

            HdnTotalAssets.Value = totalAssets.ToString();
            HdnLocCount.Value    = dt.Rows.Count.ToString();
            HdnCnt03.Value       = cnt03.ToString();
            HdnCnt46.Value       = cnt46.ToString();
            HdnCnt79.Value       = cnt79.ToString();
            HdnCnt1012.Value     = cnt1012.ToString();
            HdnCnt13.Value       = cnt13.ToString();

            LitAssetsByLocationCount.Text = "";
        }
        else
        {
            LitAssetsByLocationCount.Text = "<div class='err-msg'>No location data found.</div>";
        }
    }

    protected void GridAssetsByLocation_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType == DataControlRowType.DataRow)
        {
            int count_0_3 = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "Count_0_3"));
            int count_4_6 = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "Count_4_6"));
            // unused fields removed for cleanliness
            int total = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "TotalAssets"));

            string bucket = "13+";
            double pctRecent = (total > 0) ? (count_0_3 + count_4_6) * 100.0 / total : 0;

            if (pctRecent >= 75) bucket = "0-3";
            else if (pctRecent >= 50) bucket = "4-6";
            else if (pctRecent >= 25) bucket = "7-9";
            else if (pctRecent > 0) bucket = "10-12";

            e.Row.Attributes["data-bucket"] = bucket;
        }
    }

    protected void GridAssetsByLocation_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "ViewAssets")
        {
            string location = Convert.ToString(e.CommandArgument);
            LitSelectedLocation.Text = location;
            // Also update filter range label to indicate location view
            LitFilterRange.Text = "Specific Location";

            string sql = @"
                SELECT 
                    a.name AS [Asset Name], 
                    a.listvalue1 AS [Disposal Status], 
                    a.text6 AS [Location],
                    DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS [Days Since],
                    a.description AS [Description],
                    a.text8 AS [EIL],
                    a.lastinventoried AS [Last Observed Time]
                FROM dbo.v_asset a
                WHERE (a.text6 = @loc OR a.lastobservedlocation = @loc OR a.locationname = @loc)" + GetCompanyFilter() + @"
                ORDER BY a.name ASC";

            var dt = Run(sql, new SqlParameter[] { new SqlParameter("@loc", location) });

            PanelAssetsDetail.Visible = true;
            PanelAssetFilterDetail.Visible = false; // mutually exclusive often
            Bind(GridAssetsDetail, dt, "[Asset Name] ASC");
        }
    }

    // ===========================
    // Search
    // ===========================
    protected void BtnSearchLocation_Click(object sender, EventArgs e)
    {
        string searchText = TxtLocationSearch.Text.Trim();
        if (string.IsNullOrEmpty(searchText))
        {
            LitAssetsByLocationCount.Text = "<div class='err'>Please enter a location to search.</div>";
            return;
        }

        string sql = @"
            SELECT
                a.name AS [Asset Name],
                a.listvalue1 AS [Disposal Status],
                a.text6 AS [Location],
                DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS [Days Since],
                a.description AS [Description],
                a.text8 AS [EIL],
                a.lastinventoried AS [Last Observed Time]
            FROM dbo.v_asset a
            WHERE a.locationname IS NOT NULL
              AND a.text6 LIKE @search" + GetCompanyFilter() + @"
            ORDER BY DATEDIFF(DAY, a.lastinventoried, GETDATE()) DESC;";

        var dt = Run(sql, new SqlParameter[] { new SqlParameter("@search", "%" + searchText + "%") });

        PanelAssetFilterDetail.Visible = true;
        GridAssetFilterDetail.Visible = true;
        Bind(GridAssetFilterDetail, dt, "[Days Since] DESC");

        LitAssetsByLocationCount.Text = string.Format("<div class='ok' style='color:var(--success); font-weight:700;'>Viewing {0:N0} of {1} Total Assets (matching “{2}”)</div>", dt.Rows.Count, HdnTotalAssets.Value, searchText);
        LitFilterRange.Text = "Location Search"; // reusing this literal for context
    }

    protected void BtnClearSearch_Click(object sender, EventArgs e)
    {
        LoadSummary();
    }

    // ===========================
    // Filters (Buckets)
    // ===========================
    protected void BtnFilter_Click(object sender, EventArgs e)
    {
        LinkButton btn = sender as LinkButton;
        string bucket = (btn != null) ? btn.CommandArgument : "";
        string sqlFilter = "";

        switch (bucket)
        {
            case "0-3": sqlFilter = "a.lastinventoried >= DATEADD(MONTH, -3, GETDATE())"; break;
            case "4-6": sqlFilter = "a.lastinventoried < DATEADD(MONTH, -3, GETDATE()) AND a.lastinventoried >= DATEADD(MONTH, -6, GETDATE())"; break;
            case "7-9": sqlFilter = "a.lastinventoried < DATEADD(MONTH, -6, GETDATE()) AND a.lastinventoried >= DATEADD(MONTH, -9, GETDATE())"; break;
            case "10-12": sqlFilter = "a.lastinventoried < DATEADD(MONTH, -9, GETDATE()) AND a.lastinventoried >= DATEADD(MONTH, -12, GETDATE())"; break;
            case "13+": sqlFilter = "a.lastinventoried < DATEADD(MONTH, -12, GETDATE())"; break;
            default: sqlFilter = "1=1"; break;
        }

        string sql = string.Format(@"
            SELECT 
                a.name AS [Asset Name],
                a.listvalue1 AS [Disposal Status],
                a.text6 AS [Location],
                DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS [Days Since],
                a.description AS [Description],
                a.text8 AS [EIL],
                a.lastinventoried AS [Last Observed Time]
            FROM dbo.v_asset a
            WHERE a.locationname IS NOT NULL
              AND {0}" + GetCompanyFilter() + @"
            ORDER BY DATEDIFF(DAY, a.lastinventoried, GETDATE()) DESC;", sqlFilter);

        var dt = Run(sql, null);

        PanelAssetFilterDetail.Visible = true;
        GridAssetFilterDetail.Visible = true;
        Bind(GridAssetFilterDetail, dt, "[Days Since] DESC");

        string labelText = (dt.Rows.Count > 0) 
            ? string.Format("<div class='ok' style='color:var(--success); font-weight:700;'>Viewing {0:N0} of {1} Total Assets ({2})</div>", dt.Rows.Count, HdnTotalAssets.Value, string.IsNullOrEmpty(bucket) ? "all time periods" : bucket + " months")
            : string.Format("<div class='err'>No assets found for {0}.</div>", string.IsNullOrEmpty(bucket) ? "this period" : bucket + " months");

        LitAssetsByLocationCount.Text = labelText;
        LitFilterRange.Text = string.IsNullOrEmpty(bucket) ? "All Time Periods" : bucket + " Months";
    }

    protected void BtnFilterReset_Click(object sender, EventArgs e)
    {
        LoadSummary();
        LitFilterRange.Text = "All Time Periods";
        LitAssetsByLocationCount.Text = "<div class='ok'>Showing all locations and assets.</div>";
    }

    // ===========================
    // Sorting
    // ===========================
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
        dv.Sort = GetSafeSort(dt, e.SortExpression + " " + dir);
        grid.DataSource = dv;
        grid.DataBind();
    }

    private string GetSafeSort(DataTable dt, string desired)
    {
        if (dt == null || dt.Columns.Count == 0) return "";
        if (string.IsNullOrWhiteSpace(desired)) return "[" + dt.Columns[0].ColumnName + "] ASC";

        // Basic sort parsing
        return desired; 
    }

    // ===========================
    // Export
    // ===========================
    protected void Export_Click(object sender, EventArgs e)
    {
        // Simple export of the main grid data
        // For now, let's export the LocationSummary
        DataTable dt = Session["GridAssetsByLocationDT"] as DataTable;
        if (dt != null)
        {
            string csv = GenerateCsvContent(dt, false);
            DownloadContent("AssetsByLocation.csv", csv, "text/csv");
        }
    }

    // ===========================
    // Helpers
    // ===========================
    private DataTable Run(string sql, SqlParameter[] pars)
    {
        DataTable dt = new DataTable();
        try
        {
            using (SqlConnection cn = new SqlConnection(ConnStr))
            using (SqlDataAdapter da = new SqlDataAdapter(sql, cn))
            {
                if (pars != null)
                {
                    foreach (SqlParameter p in pars)
                        da.SelectCommand.Parameters.AddWithValue(p.ParameterName, (p.Value == null ? "" : p.Value));
                }
                da.Fill(dt);
            }
        }
        catch (Exception ex)
        {
            LitAssetsByLocationCount.Text = "<div class='err'>" + Server.HtmlEncode(ex.Message) + "</div>";
        }
        return dt;
    }

    private void Bind(GridView grid, DataTable dt, string defaultSort)
    {
        Session[grid.ID + "DT"] = dt; // store for sorting/exporting
        DataView dv = new DataView(dt);
        dv.Sort = GetSafeSort(dt, defaultSort);
        grid.DataSource = dv;
        grid.DataBind();
    }

    private string GenerateCsvContent(DataTable dt, bool excelSafe)
    {
        if (dt == null || dt.Rows.Count == 0) return "";
        StringBuilder sb = new StringBuilder();
        
        // Headers
        sb.AppendLine(string.Join(",", dt.Columns.Cast<DataColumn>().Select(c => CsvEscape(c.ColumnName))));

        // Rows
        foreach (DataRow row in dt.Rows)
        {
            var fields = new List<string>();
            foreach (DataColumn col in dt.Columns)
            {
                string val = Convert.ToString(row[col]);
                fields.Add(CsvEscape(val));
            }
            sb.AppendLine(string.Join(",", fields));
        }
        return sb.ToString();
    }

    private static string CsvEscape(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        s = s.Replace("\"", "\"\"");
        bool mustQuote = (s.IndexOfAny(new char[] { ',', '\"', '\n', '\r' }) >= 0);
        return mustQuote ? "\"" + s + "\"" : s;
    }

    private void DownloadContent(string fileName, string content, string contentType)
    {
        Response.Clear();
        Response.ContentType = contentType;
        Response.AddHeader("Content-Disposition", "attachment;filename=" + fileName);
        Response.ContentEncoding = Encoding.UTF8;
        Response.Write(content);
        Response.End();
    }
}
