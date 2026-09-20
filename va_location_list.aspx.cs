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
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.Script.Serialization;

public partial class va_location_list : System.Web.UI.Page
{
    private static string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"] 
                  ?? ConfigurationManager.ConnectionStrings["iDash"] 
                  ?? ConfigurationManager.ConnectionStrings["iDash"];
            if (cs != null && !string.IsNullOrEmpty(cs.ConnectionString)) return cs.ConnectionString;
            foreach (ConnectionStringSettings c in ConfigurationManager.ConnectionStrings)
            {
                if (c.Name != "LocalSqlServer" && !string.IsNullOrEmpty(c.ConnectionString))
                    return c.ConnectionString;
            }
            return "";
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "rpt_location_list") &&
            !UserManager.CanAccessTile(role, tiles, "rpt_asset_master"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            LoadCompanies();
            LoadSummary();
        }
        else
        {
            // Reload companies list if it got reset (e.g. session expired edge case)
            if (DdlCompany.Items.Count == 0) LoadCompanies();

            // Re-bind GridLocationSummary from Session cache instead of ViewState
            // (avoids sending 50-100KB of encoded GridView state on every postback)
            var sumDt = Session["GridLocationSummaryDT"] as DataTable;
            if (sumDt != null) Bind(GridLocationSummary, sumDt, "Location ASC");

            // Re-bind detail panels from Session cache (EnableViewState=false on these grids)
            if (PanelAssetsDetail.Visible)
            {
                var dt = Session["GridAssetsDetailDT"] as DataTable;
                if (dt != null) Bind(GridAssetsDetail, dt, "[Asset ID] ASC");
            }
            if (PanelAssetFilterDetail.Visible)
            {
                var dt = Session["GridAssetFilterDetailDT"] as DataTable;
                if (dt != null) Bind(GridAssetFilterDetail, dt, "[Days Since] DESC");
            }
        }
    }

    protected void Page_PreRender(object sender, EventArgs e)
    {
        SetTableHeader(GridLocationSummary);
        SetTableHeader(GridAssetFilterDetail);
        SetTableHeader(GridAssetsDetail);
    }

    private void SetTableHeader(GridView g)
    {
        if (g.Rows.Count > 0)
        {
            g.UseAccessibleHeader = true;
            g.HeaderRow.TableSection = TableRowSection.TableHeader;
        }
    }

    private void LoadCompanies()
    {
        try
        {
            UserManager.FilterCompanyDropdown(DdlCompany, Session, ConnStr);
        }
        catch (Exception ex)
        {
            LitMsg.Text = "<div class='err-msg'>Error loading sites: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ===========================
    // Filter helpers
    // ===========================
    private string GetBaseFilter()
    {
        string where = "WHERE a.locationname IS NOT NULL";

        var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);
        int compId = 0;
        int.TryParse(DdlCompany.SelectedValue, out compId);

        if (compId > 0)
        {
            if (allowedIds == null || allowedIds.Contains(compId))
                where += " AND a.companyid = @comp";
            else
                where += " AND 1=0";
        }
        else
        {
            if (allowedIds != null)
            {
                if (allowedIds.Count == 0)
                    where += " AND 1=0";
                else
                    where += " AND a.companyid IN (" + string.Join(",", allowedIds) + ")";
            }
        }

        if (!string.IsNullOrEmpty(DdlStatus.SelectedValue))
            where += " AND a.listvalue1 = @status";

        string cmr = TxtCmr.Text.Trim();
        if (!string.IsNullOrEmpty(cmr))
            where += " AND a.text8 LIKE @cmr";

        string loc = TxtLocationSearch.Text.Trim();
        if (!string.IsNullOrEmpty(loc))
            where += " AND a.locationname LIKE @loc";

        return where;
    }

    private SqlParameter[] GetBaseParams()
    {
        var pars = new List<SqlParameter>();

        var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);
        int compId = 0;
        int.TryParse(DdlCompany.SelectedValue, out compId);

        if (compId > 0 && (allowedIds == null || allowedIds.Contains(compId)))
            pars.Add(new SqlParameter("@comp", compId));

        if (!string.IsNullOrEmpty(DdlStatus.SelectedValue))
            pars.Add(new SqlParameter("@status", DdlStatus.SelectedValue));

        string cmr = TxtCmr.Text.Trim();
        if (!string.IsNullOrEmpty(cmr))
            pars.Add(new SqlParameter("@cmr", "%" + cmr + "%"));

        string loc = TxtLocationSearch.Text.Trim();
        if (!string.IsNullOrEmpty(loc))
            pars.Add(new SqlParameter("@loc", "%" + loc + "%"));

        return pars.ToArray();
    }

    // ===========================
    // Load summary
    // ===========================
    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        LoadSummary();
    }

    protected void DdlStatus_SelectedIndexChanged(object sender, EventArgs e)
    {
        LoadSummary();
    }

    private void LoadSummary()
    {
        PanelAssetsDetail.Visible = false;
        PanelAssetFilterDetail.Visible = false;

        string where = GetBaseFilter();

        string sql = @"
        WITH AssetAges AS (
            SELECT 
                a.locationname AS Location,
                a.text8,
                a.lastinventoried,
                CASE 
                    WHEN a.lastinventoried IS NULL THEN '13+ Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -3, GETDATE()) THEN '0-3 Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -6, GETDATE()) THEN '4-6 Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -9, GETDATE()) THEN '7-9 Months'
                    WHEN a.lastinventoried >= DATEADD(MONTH, -12, GETDATE()) THEN '10-12 Months'
                    ELSE '13+ Months'
                END AS AgeBucket
            FROM dbo.v_asset a
            " + where + @"
        ),
        UniqueCMRs AS (
            SELECT Location,
                COUNT(DISTINCT CASE
                    WHEN NULLIF(LTRIM(RTRIM(text8)), '') IS NULL THEN NULL
                    WHEN UPPER(LTRIM(RTRIM(text8))) IN ('NULL','UNKNOWN','N/A','NA','NONE','TBD','?') THEN NULL
                    ELSE LTRIM(RTRIM(text8))
                END) AS UniqueCMR
            FROM AssetAges
            GROUP BY Location
        )
        SELECT
            a.Location,
            COUNT(*) AS TotalAssets,
            ISNULL(u.UniqueCMR, 0) AS UniqueCMR,
            SUM(CASE WHEN a.AgeBucket = '0-3 Months' THEN 1 ELSE 0 END) AS Count_0_3,
            SUM(CASE WHEN a.AgeBucket = '4-6 Months' THEN 1 ELSE 0 END) AS Count_4_6,
            SUM(CASE WHEN a.AgeBucket = '7-9 Months' THEN 1 ELSE 0 END) AS Count_7_9,
            SUM(CASE WHEN a.AgeBucket = '10-12 Months' THEN 1 ELSE 0 END) AS Count_10_12,
            SUM(CASE WHEN a.AgeBucket = '13+ Months' THEN 1 ELSE 0 END) AS Count_13plus,
            CAST(100.0 * SUM(CASE WHEN a.AgeBucket = '0-3 Months' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,1)) AS Pct_0_3,
            CAST(100.0 * (SUM(CASE WHEN a.AgeBucket IN ('0-3 Months','4-6 Months','7-9 Months','10-12 Months') THEN 1 ELSE 0 END)) / NULLIF(COUNT(*), 0) AS DECIMAL(5,1)) AS Pct_0_12,
            MAX(a.lastinventoried) AS LastInventoried
        FROM AssetAges a
        LEFT JOIN UniqueCMRs u ON u.Location = a.Location
        GROUP BY a.Location, u.UniqueCMR
        ORDER BY a.Location ASC;";

        var dt = Run(sql, GetBaseParams());
        Bind(GridLocationSummary, dt, "Location ASC");

        if (dt != null && dt.Rows.Count > 0)
        {
            int totalAssets = dt.AsEnumerable().Sum(r => r.Field<int>("TotalAssets"));
            int withCmr     = dt.AsEnumerable().Sum(r => r.Field<int>("UniqueCMR"));
            int cnt03       = dt.AsEnumerable().Sum(r => r.Field<int>("Count_0_3"));
            int cnt46       = dt.AsEnumerable().Sum(r => r.Field<int>("Count_4_6"));
            int cnt79       = dt.AsEnumerable().Sum(r => r.Field<int>("Count_7_9"));
            int cnt1012     = dt.AsEnumerable().Sum(r => r.Field<int>("Count_10_12"));
            int cnt13       = dt.AsEnumerable().Sum(r => r.Field<int>("Count_13plus"));

            HdnTotalAssets.Value = totalAssets.ToString();
            HdnLocCount.Value    = dt.Rows.Count.ToString();
            HdnWithCmr.Value     = withCmr.ToString();
            HdnCnt03.Value       = cnt03.ToString();
            HdnCnt46.Value       = cnt46.ToString();
            HdnCnt79.Value       = cnt79.ToString();
            HdnCnt1012.Value     = cnt1012.ToString();
            HdnCnt13.Value       = cnt13.ToString();

            LitLocationListCount.Text = "";
        }
        else
        {
            LitLocationListCount.Text = "<div class='err-msg'>No location data found.</div>";
        }
    }

    // ===========================
    // Row events
    // ===========================
    protected void GridLocationSummary_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType == DataControlRowType.DataRow)
        {
            int count_0_3 = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "Count_0_3"));
            int count_4_6 = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "Count_4_6"));
            int total = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "TotalAssets"));

            double pctRecent = (total > 0) ? (count_0_3 + count_4_6) * 100.0 / total : 0;
            string bucket = "13+";
            if (pctRecent >= 75) bucket = "0-3";
            else if (pctRecent >= 50) bucket = "4-6";
            else if (pctRecent >= 25) bucket = "7-9";
            else if (pctRecent > 0) bucket = "10-12";

            e.Row.Attributes["data-bucket"] = bucket;
        }
    }

    // Shared handler for asset detail grids — sets data-asset-id and data-asset-name for slideout drawer
    protected void AssetGrid_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType == DataControlRowType.DataRow)
        {
            GridView gv = (GridView)sender;
            string assetId = "";
            if (gv.DataKeys != null && gv.DataKeys.Count > e.Row.RowIndex && gv.DataKeys[e.Row.RowIndex] != null)
            {
                var keyVal = gv.DataKeys[e.Row.RowIndex].Value;
                if (keyVal != null) assetId = keyVal.ToString();
            }

            string assetName = "";
            try {
                assetName = Convert.ToString(DataBinder.Eval(e.Row.DataItem, "Asset ID"));
            } catch {}

            e.Row.Attributes["data-asset-id"] = assetId;
            e.Row.Attributes["data-asset-name"] = assetName;
        }
    }

    // ===================================================================
    // AJAX WebMethods for Location Printing
    // ===================================================================
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetPrintTemplates(string siteId)
    {
        var json = new JavaScriptSerializer();
        try
        {
            var session = HttpContext.Current != null ? HttpContext.Current.Session : null;
            var allowedIds = UserManager.GetAllowedCompanyIds(session, ConnStr);

            int companyId = 0;
            int.TryParse(siteId, out companyId);

            if (allowedIds != null)
            {
                if (companyId > 0 && !allowedIds.Contains(companyId))
                    return json.Serialize(new { success = false, error = "Access denied to requested site." });
                if (companyId <= 0 && allowedIds.Count == 0)
                    return json.Serialize(new { success = true, templates = new List<object>() });
            }

            var templates = new List<object>();
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                string whereClause = "1=1";
                if (companyId > 0)
                    whereClause = "companyid = @cid";
                else if (allowedIds != null && allowedIds.Count > 0)
                    whereClause = "companyid IN (" + string.Join(",", allowedIds) + ")";

                string sql = @"
                    SELECT id, name, companyid 
                    FROM dbo.template 
                    WHERE " + whereClause + @"
                    ORDER BY name";
                using (var cmd = new SqlCommand(sql, cn))
                {
                    if (companyId > 0) cmd.Parameters.AddWithValue("@cid", companyId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            templates.Add(new {
                                id = Convert.ToInt64(rdr["id"]),
                                name = Convert.ToString(rdr["name"]),
                                companyId = Convert.ToInt32(rdr["companyid"])
                            });
                        }
                    }
                }
            }
            return json.Serialize(new { success = true, templates = templates });
        }
        catch (Exception ex)
        {
            return json.Serialize(new { success = false, error = ex.Message });
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string SubmitPrintJobs(string siteId, string assetIdsJson, long templateId)
    {
        var json = new JavaScriptSerializer();
        try
        {
            var rawIds = json.Deserialize<List<string>>(assetIdsJson);
            if (rawIds == null || rawIds.Count == 0)
                return json.Serialize(new { success = false, error = "No assets selected." });

            int companyId = 0;
            int.TryParse(siteId, out companyId);

            if (companyId <= 0 && templateId > 0)
                companyId = PrintApiHelper.GetCompanyIdForTemplate(templateId);

            if (templateId <= 0 && companyId > 0)
                templateId = PrintApiHelper.GetTemplateIdForCompany(companyId);

            if (templateId <= 0)
                return json.Serialize(new { success = false, error = "No valid print template found for this site." });

            var session = HttpContext.Current != null ? HttpContext.Current.Session : null;
            var allowedIds = UserManager.GetAllowedCompanyIds(session, ConnStr);
            if (allowedIds != null)
            {
                if (companyId > 0 && !allowedIds.Contains(companyId))
                    return json.Serialize(new { success = false, error = "Access denied for printing at this site." });
                if (companyId <= 0 && allowedIds.Count == 0)
                    return json.Serialize(new { success = false, error = "No sites assigned for printing." });
            }

            var assetIds = new List<long>();
            foreach (var s in rawIds)
            {
                long aid;
                if (long.TryParse(s, out aid) && aid > 0)
                    assetIds.Add(aid);
            }

            if (assetIds.Count == 0)
                return json.Serialize(new { success = false, error = "No valid asset IDs provided." });

            // Direct BarTender printing — no iDash Print Service / MQTT
            List<string> printErrors;
            int jobsCreated = PrintApiHelper.PrintAssetsDirect(assetIds, templateId, out printErrors);

            return json.Serialize(new {
                success = true,
                jobsCreated = jobsCreated,
                errors = printErrors ?? new List<string>()
            });
        }
        catch (Exception ex)
        {
            return json.Serialize(new { success = false, error = ex.Message });
        }
    }

    protected void GridLocationSummary_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "ViewAssets")
        {
            string location = Convert.ToString(e.CommandArgument);
            LitSelectedLocation.Text = Server.HtmlEncode(location);
            HdnSelectedLoc.Value = location; // persisted for export

            string where = GetBaseFilter();
            where += " AND a.locationname = @exactLoc";

            var basePars = new List<SqlParameter>(GetBaseParams());
            basePars.Add(new SqlParameter("@exactLoc", location));

            string sql = @"
                SELECT 
                    a.id AS [AssetId],
                    a.name AS [Asset ID], 
                    a.description AS [Description],
                    a.text2 AS [Model],
                    a.text3 AS [Serial Number],
                    a.text1 AS [Manufacturer],
                    a.locationname AS [Location],
                    a.text8 AS [CMR],
                    a.text19 AS [Tag Type],
                    a.listvalue1 AS [Status],
                    a.rfidtag AS [RFID Tag],
                    DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS [Days Since],
                    a.lastinventoried AS [Last Inventoried]
                FROM dbo.v_asset a
                " + where + @"
                ORDER BY a.name ASC";

            var dt = Run(sql, basePars.ToArray());

            PanelAssetsDetail.Visible = true;
            PanelAssetFilterDetail.Visible = false;
            Bind(GridAssetsDetail, dt, "[Asset ID] ASC");
        }
    }

    // ===========================
    // Search
    // ===========================
    protected void BtnSearch_Click(object sender, EventArgs e)
    {
        LoadSummary();
    }

    protected void BtnClearSearch_Click(object sender, EventArgs e)
    {
        TxtCmr.Text = "";
        TxtLocationSearch.Text = "";
        DdlStatus.SelectedValue = "IN USE";
        LoadSummary();
    }

    // ===========================
    // Age Bucket Filters
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
            case "13+": sqlFilter = "(a.lastinventoried < DATEADD(MONTH, -12, GETDATE()) OR a.lastinventoried IS NULL)"; break;
            default: sqlFilter = "1=1"; break;
        }

        string where = GetBaseFilter();
        where += " AND " + sqlFilter;

        string sql = @"
            SELECT 
                a.id AS [AssetId],
                a.name AS [Asset ID],
                a.description AS [Description],
                a.text2 AS [Model],
                a.text3 AS [Serial Number],
                a.text1 AS [Manufacturer],
                a.locationname AS [Location],
                a.text8 AS [CMR],
                a.text19 AS [Tag Type],
                a.listvalue1 AS [Status],
                a.rfidtag AS [RFID Tag],
                DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS [Days Since],
                a.lastinventoried AS [Last Inventoried]
            FROM dbo.v_asset a
            " + where + @"
            ORDER BY DATEDIFF(DAY, a.lastinventoried, GETDATE()) DESC";

        var dt = Run(sql, GetBaseParams());

        PanelAssetFilterDetail.Visible = true;
        PanelAssetsDetail.Visible = false;
        Bind(GridAssetFilterDetail, dt, "[Days Since] DESC");

        string labelText = (dt.Rows.Count > 0)
            ? string.Format("<div class='ok' style='font-weight:700;'>Showing {0:N0} assets ({1})</div>",
                dt.Rows.Count, string.IsNullOrEmpty(bucket) ? "all" : bucket + " months")
            : string.Format("<div class='err'>No assets found for {0}.</div>",
                string.IsNullOrEmpty(bucket) ? "this period" : bucket + " months");

        LitLocationListCount.Text = labelText;
        LitFilterRange.Text = string.IsNullOrEmpty(bucket) ? "All Time Periods" : bucket + " Months";
    }

    protected void BtnFilterReset_Click(object sender, EventArgs e)
    {
        LoadSummary();
    }

    // ===========================
    // Export
    // ===========================
    protected void Export_Click(object sender, EventArgs e)
    {
        DataTable dt = null;
        string fileName;

        if (PanelAssetsDetail.Visible)
        {
            // Export only the currently viewed location's assets (already cached in Session)
            dt = Session["GridAssetsDetailDT"] as DataTable;
            string loc = (HdnSelectedLoc.Value ?? "").Trim();
            fileName = string.IsNullOrEmpty(loc)
                ? "Location_Assets.csv"
                : "Assets_" + System.Text.RegularExpressions.Regex.Replace(loc, @"[^\w\-]", "_") + ".csv";
        }
        else if (PanelAssetFilterDetail.Visible)
        {
            // Export the age-bucket drill-down
            dt = Session["GridAssetFilterDetailDT"] as DataTable;
            fileName = "Assets_Age_Filter.csv";
        }
        else
        {
            // Export the location summary grid
            dt = Session["GridLocationSummaryDT"] as DataTable;
            fileName = "Location_Summary.csv";
        }

        if (dt != null && dt.Rows.Count > 0)
        {
            string csv = GenerateCsvContent(dt, false);
            DownloadContent(fileName, csv, "text/csv");
        }
        else
        {
            LitMsg.Text = "<div class='err-msg'>No data available to export.</div>";
        }
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

    // ===========================
    // Helpers
    // ===========================
    private DataTable Run(string sql, SqlParameter[] pars)
    {
        DataTable dt = new DataTable();
        try
        {
            using (SqlConnection cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                // Read uncommitted: avoids lock waits on this reporting/read-only page
                using (var unlockCmd = new SqlCommand("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED", cn))
                    unlockCmd.ExecuteNonQuery();
                using (SqlDataAdapter da = new SqlDataAdapter(sql, cn))
                {
                    if (pars != null)
                        foreach (SqlParameter p in pars)
                            da.SelectCommand.Parameters.AddWithValue(p.ParameterName, p.Value ?? "");
                    da.Fill(dt);
                }
            }
        }
        catch (Exception ex)
        {
            LitLocationListCount.Text = "<div class='err-msg'>" + Server.HtmlEncode(ex.Message) + "</div>";
        }
        return dt;
    }

    private void Bind(GridView grid, DataTable dt, string defaultSort)
    {
        Session[grid.ID + "DT"] = dt;
        DataView dv = new DataView(dt);
        dv.Sort = GetSafeSort(dt, defaultSort);
        grid.DataSource = dv;
        grid.DataBind();
    }

    private string GetSafeSort(DataTable dt, string desired)
    {
        if (dt == null || dt.Columns.Count == 0) return "";
        if (string.IsNullOrWhiteSpace(desired)) return "[" + dt.Columns[0].ColumnName + "] ASC";
        return desired;
    }

    private string GenerateCsvContent(DataTable dt, bool excelSafe)
    {
        if (dt == null || dt.Rows.Count == 0) return "";
        StringBuilder sb = new StringBuilder();
        sb.AppendLine(string.Join(",", dt.Columns.Cast<DataColumn>().Select(c => CsvEscape(c.ColumnName))));
        foreach (DataRow row in dt.Rows)
        {
            var fields = new List<string>();
            foreach (DataColumn col in dt.Columns)
                fields.Add(CsvEscape(Convert.ToString(row[col])));
            sb.AppendLine(string.Join(",", fields));
        }
        return sb.ToString();
    }

    private static string CsvEscape(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        s = s.Replace("\"", "\"\"");
        bool mustQuote = (s.IndexOfAny(new char[] { ',', '"', '\n', '\r' }) >= 0);
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
