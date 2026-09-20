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

public partial class va_tag_type : System.Web.UI.Page
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
        if (!IsPostBack)
        {
            LoadCompanies();
            // Optional: Auto-load counts?
            BtnTagTypeCounts_Click(null, null);
        }
    }

    // ASP.NET GridView loses TableSection=TableHeader on ViewState restore.
    // Force it on every render so DataTables always sees a proper <thead>.
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        if (GridTagTypeCounts != null && GridTagTypeCounts.HeaderRow != null)
            GridTagTypeCounts.HeaderRow.TableSection = TableRowSection.TableHeader;
        if (GridTagTypePreview != null && GridTagTypePreview.HeaderRow != null)
            GridTagTypePreview.HeaderRow.TableSection = TableRowSection.TableHeader;
    }

    private void LoadCompanies()
    {
        try
        {
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }
                DdlCompany.Items.Insert(0, new ListItem("All Sites", "0"));
            }
        }
        catch (Exception ex)
        {
            LitTagTypeCount.Text = "<div class='err'>Error loading sites: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        BtnTagTypeCounts_Click(null, null);
    }

    protected void BtnTagTypeCounts_Click(object sender, EventArgs e)
    {
        string compFilter = "";
        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            compFilter = " AND a.companyid = " + DdlCompany.SelectedValue;
        }

        string sql = @"
            SELECT 
                a.text19 AS [Tag Type], 
                COUNT(*) AS [Count]
            FROM dbo.v_asset a
            where a.text19 is not null" + compFilter + @"
            GROUP BY a.text19
            ORDER BY a.text19 ASC";

        var dt = Run(sql, null);
        Bind(GridTagTypeCounts, dt, "[Tag Type] ASC");
        
        if (dt.Rows.Count > 0)
            LitTagTypeCount.Text = string.Format("<div class='ok'>{0:N0} types found.</div>", dt.Rows.Count);
        else
            LitTagTypeCount.Text = "<div class='err'>No tag types found.</div>";
    }

    protected void BtnTagTypePreview_Click(object sender, EventArgs e)
    {
        string filter = TxtTagType.Text.Trim();
        string where = "WHERE 1=1";
        SqlParameter[] p = null;

        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            where += " AND a.companyid = " + DdlCompany.SelectedValue;
        }

        if (!string.IsNullOrEmpty(filter))
        {
            where += " AND a.text19 LIKE @tt";
            p = new SqlParameter[] { new SqlParameter("@tt", "%" + filter + "%") };
        }

        string sql = @"
            SELECT TOP(100)
                a.name AS [Asset Name],
                a.text19 AS [Tag Type],
                a.text16 AS [Location Found],
                a.lastinventoried AS [Last Observed]
            FROM dbo.v_asset a
            " + where + @"
            ORDER BY a.text19 ASC, a.name ASC";

        var dt = Run(sql, p);

        Bind(GridTagTypePreview, dt, "[Tag Type] ASC, [Asset Name] ASC");
        FillTextPreview(TxtTagTypePreview, dt, "Tag Type", "Location Found", "Asset Name");
        
        if (dt.Rows.Count > 0)
        {
            LitTagTypeCount.Text = string.Format("<div class='ok'>Previewing top {0} assets matching '{1}'.</div>", dt.Rows.Count, Server.HtmlEncode(filter));
        }
        else
        {
            LitTagTypeCount.Text = "<div class='err'>No assets found matching tag type '" + Server.HtmlEncode(filter) + "'.</div>";
        }
    }

    protected void Export_Click(object sender, EventArgs e)
    {
        // Export matching the current filter (upto a limit? or all?)
        // The UI says "Export Excel (Preview)" but traditionally we want to export all matches.
        
        string filter = TxtTagType.Text.Trim();
        string where = "WHERE 1=1";
        SqlParameter[] p = null;

        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            where += " AND a.companyid = " + DdlCompany.SelectedValue;
        }

        if (!string.IsNullOrEmpty(filter))
        {
            where += " AND a.text19 LIKE @tt";
            p = new SqlParameter[] { new SqlParameter("@tt", "%" + filter + "%") };
        }
        
        // No TOP limit for export
        string sql = @"
            SELECT
                a.name AS [Asset Name],
                a.text19 AS [Tag Type],
                a.text16 AS [Location Found],
                a.lastinventoried AS [Last Observed]
            FROM dbo.v_asset a
            " + where + @"
            ORDER BY a.text19 ASC, a.name ASC";

        var dt = Run(sql, p);
        if (dt != null && dt.Rows.Count > 0)
        {
            string csv = GenerateCsvContent(dt, false);
            DownloadContent("TagTypes.csv", csv, "text/csv");
        }
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
            LitTagTypeCount.Text = "<div class='err'>" + Server.HtmlEncode(ex.Message) + "</div>";
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
        if (grid.HeaderRow != null) grid.HeaderRow.TableSection = TableRowSection.TableHeader;
    }

    private string GetSafeSort(DataTable dt, string desired)
    {
        if (dt == null || dt.Columns.Count == 0) return "";
        if (string.IsNullOrWhiteSpace(desired)) return "[" + dt.Columns[0].ColumnName + "] ASC";
        return desired; 
    }

    private void FillTextPreview(TextBox outputBox, DataTable dt, params string[] cols)
    {
        StringBuilder sb = new StringBuilder();
        foreach (DataRow r in dt.Rows)
        {
            var parts = new List<string>();
            foreach (string c in cols)
            {
                if (dt.Columns.Contains(c)) parts.Add(Convert.ToString(r[c]));
            }
            if (parts.Count > 0) sb.AppendLine(string.Join(" | ", parts));
        }
        outputBox.Text = sb.ToString();
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
