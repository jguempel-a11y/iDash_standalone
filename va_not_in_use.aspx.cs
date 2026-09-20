using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Text;
using System.Web.UI.WebControls;

public partial class va_not_in_use : System.Web.UI.Page
{
    private string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            LoadCompanies();
            LoadData();
        }
    }

    private void LoadCompanies()
    {
        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();
            using (var cmd = new SqlCommand("SELECT id, name FROM company ORDER BY name", con))
            using (var r = cmd.ExecuteReader())
            {
                DdlCompany.DataSource = r;
                DdlCompany.DataTextField  = "name";
                DdlCompany.DataValueField = "id";
                DdlCompany.DataBind();
            }
            DdlCompany.Items.Insert(0, new ListItem("All Sites", "0"));
        }
    }

    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        LoadData();
    }

    private string GetFilter()
    {
        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
            return " AND a.companyid = " + DdlCompany.SelectedValue.Replace("'", "''");
        return "";
    }

    private void LoadData()
    {
        string filter = GetFilter();

        // ── KPI: total + breakdown by listvalue1 ──────────────────
        string kpiSql = @"
            SELECT
                COUNT(*)                                                          AS Total,
                SUM(CASE WHEN listvalue1 IS NULL OR listvalue1 = '' THEN 1 ELSE 0 END) AS NoStatus,
                COUNT(DISTINCT listvalue1)                                        AS UniqueStatuses
            FROM dbo.v_asset a
            WHERE a.text18 = '1'
              AND (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + filter;

        string statusSql = @"
            SELECT
                ISNULL(listvalue1, '(No Status)') AS StatusVal,
                COUNT(*) AS Cnt
            FROM dbo.v_asset a
            WHERE a.text18 = '1'
              AND (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + filter + @"
            GROUP BY listvalue1
            ORDER BY COUNT(*) DESC";

        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();

            // Main totals
            using (var cmd = new SqlCommand(kpiSql, con))
            using (var rdr = cmd.ExecuteReader())
            {
                if (rdr.Read())
                {
                    HdnTotal.Value       = rdr["Total"].ToString();
                    HdnNoStatus.Value    = rdr["NoStatus"].ToString();
                    HdnUniqueStatus.Value= rdr["UniqueStatuses"].ToString();
                }
            }

            // Status breakdown for bar chart
            var sbStatus = new StringBuilder();
            using (var cmd2 = new SqlCommand(statusSql, con))
            using (var rdr2 = cmd2.ExecuteReader())
            {
                while (rdr2.Read())
                {
                    if (sbStatus.Length > 0) sbStatus.Append("|");
                    sbStatus.Append(rdr2["StatusVal"].ToString().Replace("|", " ").Replace("~", " "));
                    sbStatus.Append("~");
                    sbStatus.Append(rdr2["Cnt"].ToString());
                }
            }
            HdnStatusBreakdown.Value = sbStatus.ToString();
        }

        // ── Main grid query ───────────────────────────────────────
        string sql = @"
            SELECT TOP 10000
                a.name            AS AssetTag,
                a.description     AS Description,
                a.text8           AS EIL_CMR,
                a.locationname    AS Location,
                a.listvalue1      AS Status,
                ISNULL(c.name, 'Unknown') AS Site,
                a.lastinventoried AS LastInventoried
            FROM dbo.v_asset a
            LEFT JOIN dbo.company c ON a.companyid = c.id
            WHERE a.text18 = '1'
              AND (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + filter + @"
            ORDER BY a.listvalue1, a.name";

        using (var da = new SqlDataAdapter(sql, ConnStr))
        {
            var dt = new DataTable();
            da.Fill(dt);
            GridData.DataSource = dt;
            GridData.DataBind();
            if (GridData.HeaderRow != null)
                GridData.HeaderRow.TableSection = System.Web.UI.WebControls.TableRowSection.TableHeader;
        }
    }

    protected void BtnExport_Click(object sender, EventArgs e)
    {
        string filter = GetFilter();
        string sql = @"
            SELECT
                a.name            AS [Asset Tag],
                a.description     AS [Description],
                a.text8           AS [EIL / CMR],
                a.locationname    AS [Location],
                a.listvalue1      AS [Status],
                ISNULL(c.name, 'Unknown') AS [Site],
                a.text7           AS [Station Code],
                a.lastinventoried AS [Last Inventoried],
                a.lastmodifiedby  AS [Last Modified By]
            FROM dbo.v_asset a
            LEFT JOIN dbo.company c ON a.companyid = c.id
            WHERE a.text18 = '1'
              AND (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + filter + @"
            ORDER BY a.listvalue1, a.name";

        try
        {
            using (var da = new SqlDataAdapter(sql, ConnStr))
            {
                var dt = new DataTable();
                da.Fill(dt);

                var sb = new StringBuilder();
                // Header
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    sb.Append("\"" + dt.Columns[i].ColumnName + "\"");
                    if (i < dt.Columns.Count - 1) sb.Append(",");
                }
                sb.AppendLine();
                // Rows
                foreach (DataRow row in dt.Rows)
                {
                    for (int i = 0; i < dt.Columns.Count; i++)
                    {
                        sb.Append("\"" + row[i].ToString().Replace("\"", "\"\"") + "\"");
                        if (i < dt.Columns.Count - 1) sb.Append(",");
                    }
                    sb.AppendLine();
                }

                Response.ClearContent();
                Response.AddHeader("content-disposition",
                    "attachment; filename=NotInUse_" + DateTime.Now.ToString("yyyyMMdd") + ".csv");
                Response.ContentType = "text/csv";
                Response.BinaryWrite(Encoding.UTF8.GetBytes(sb.ToString()));
                Response.End();
            }
        }
        catch (System.Threading.ThreadAbortException) { }
        catch (Exception ex)
        {
            // Surface error if needed
            System.Diagnostics.Debug.WriteLine("Export error: " + ex.Message);
        }
    }
}
