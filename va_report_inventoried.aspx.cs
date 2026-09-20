using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Linq;
using System.Web.UI.WebControls;

public partial class va_report_inventoried : System.Web.UI.Page
{
    private string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "rpt_overview"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            LoadCompanies();
            LoadBucketCounts();
            LoadActivity();
            LoadQuality();
        }
    }

    private void LoadBucketCounts()
    {
        string compExt = GetCompanyFilter();
        try
        {
            DataRow r = Run(@"
                SELECT
                    COUNT(*) AS Total,
                    SUM(CASE WHEN DATEDIFF(month,lastinventoried,GETDATE()) <= 3  THEN 1 ELSE 0 END) AS B03,
                    SUM(CASE WHEN DATEDIFF(month,lastinventoried,GETDATE()) BETWEEN 4  AND 6  THEN 1 ELSE 0 END) AS B46,
                    SUM(CASE WHEN DATEDIFF(month,lastinventoried,GETDATE()) BETWEEN 7  AND 9  THEN 1 ELSE 0 END) AS B79,
                    SUM(CASE WHEN DATEDIFF(month,lastinventoried,GETDATE()) BETWEEN 10 AND 12 THEN 1 ELSE 0 END) AS B1012,
                    SUM(CASE WHEN DATEDIFF(month,lastinventoried,GETDATE()) >= 13 THEN 1 ELSE 0 END) AS B13plus,
                    SUM(CASE WHEN lastinventoried IS NULL THEN 1 ELSE 0 END) AS BNull
                FROM v_asset
                WHERE 1=1" + compExt).Rows[0];

            int tot = Convert.ToInt32(r["Total"]);
            HdnTotal.Value   = tot.ToString();
            HdnB03.Value     = r["B03"].ToString();
            HdnB46.Value     = r["B46"].ToString();
            HdnB79.Value     = r["B79"].ToString();
            HdnB1012.Value   = r["B1012"].ToString();
            HdnB13.Value     = r["B13plus"].ToString();
            HdnBNull.Value   = r["BNull"].ToString();
        }
        catch { }
    }

    private void LoadCompanies()
    {
        try
        {
            var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnStr);
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                SqlCommand cmd;
                if (allowedIds == null)
                    cmd = new SqlCommand("SELECT id, name FROM dbo.company ORDER BY name", conn);
                else if (allowedIds.Count == 0)
                {
                    DdlCompany.Items.Clear();
                    DdlCompany.Items.Insert(0, new System.Web.UI.WebControls.ListItem("-- No sites assigned --", "0"));
                    return;
                }
                else
                {
                    var parms = new List<string>();
                    cmd = new SqlCommand(); cmd.Connection = conn;
                    for (int i = 0; i < allowedIds.Count; i++) { parms.Add("@id" + i); cmd.Parameters.AddWithValue("@id" + i, allowedIds[i]); }
                    cmd.CommandText = "SELECT id, name FROM dbo.company WHERE id IN (" + string.Join(",", parms) + ") ORDER BY name";
                }
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }
                if (DdlCompany.Items.Count > 1 || allowedIds == null)
                    DdlCompany.Items.Insert(0, new System.Web.UI.WebControls.ListItem("All Sites", "0"));
                else if (DdlCompany.Items.Count == 1)
                    DdlCompany.SelectedIndex = 0;
            }
        }
        catch (Exception) { }
    }

    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        LoadBucketCounts();
        LoadActivity();
        LoadQuality();
        if (PanelDetail.Visible && Session["BucketFilter"] != null)
        {
            LoadDetail();
        }
    }

    private string GetCompanyFilter()
    {
        string c = DdlCompany.SelectedValue;
        if (c != "0" && !string.IsNullOrEmpty(c))
        {
            return " AND companyid = '" + c.Replace("'", "''") + "'";
        }
        return "";
    }

    // ---------------- BUCKET CLICK ----------------
    protected void BtnFilterInventoried_Click(object sender, EventArgs e)
    {
        string arg = ((System.Web.UI.WebControls.LinkButton)sender).CommandArgument;
        string filter = "";

        if (arg == "0-3") filter = "DATEDIFF(month,lastinventoried,GETDATE())<=3";
        else if (arg == "4-6") filter = "DATEDIFF(month,lastinventoried,GETDATE()) BETWEEN 4 AND 6";
        else if (arg == "7-9") filter = "DATEDIFF(month,lastinventoried,GETDATE()) BETWEEN 7 AND 9";
        else if (arg == "10-12") filter = "DATEDIFF(month,lastinventoried,GETDATE()) BETWEEN 10 AND 12";
        else filter = "DATEDIFF(month,lastinventoried,GETDATE())>=13";

        LitBucket.Text = arg + " Months";
        Session["BucketFilter"] = filter;

        LoadDetail();
    }

    // ---------------- DETAIL GRID ----------------
    private void LoadDetail()
    {
        string sql = @"
        SELECT name, text8 AS CMR_EIL, description, text6 AS Location,
               text16 AS LocationTagged, text2 AS Model, text3 AS Serial,
               listvalue1, lastinventoried,
               DATEDIFF(day,lastinventoried,GETDATE()) AS [Days Since]
        FROM v_asset
        WHERE lastinventoried IS NOT NULL
          AND " + Session["BucketFilter"] + GetCompanyFilter();

        DataTable dt = Run(sql);
        Session["DetailDT"] = dt;

        ApplyFilters();
        PanelDetail.Visible = true;
    }

    protected void FilterChanged(object sender, EventArgs e)
    {
        ApplyFilters();
    }

    private void ApplyFilters()
    {
        DataTable dt = Session["DetailDT"] as DataTable;
        if (dt == null) return;

        var rows = dt.AsEnumerable();

        if (ChkNullOnly.Checked)
            rows = rows.Where(r => r.ItemArray.Any(v => v == DBNull.Value));

        if (!string.IsNullOrWhiteSpace(TxtDesc.Text))
            rows = rows.Where(r => r["description"].ToString()
                .IndexOf(TxtDesc.Text, StringComparison.OrdinalIgnoreCase) >= 0);

        int d;
        if (int.TryParse(TxtDays.Text, out d))
            rows = rows.Where(r => Convert.ToInt32(r["Days Since"]) <= d);

        GridDetail.DataSource = rows.Any() ? rows.CopyToDataTable() : null;
        GridDetail.DataBind();

        if (GridDetail.Rows.Count > 0)
        {
            GridDetail.UseAccessibleHeader = true;
            GridDetail.HeaderRow.TableSection = TableRowSection.TableHeader;
        }
    }

    // ---------------- ACTIVITY ----------------
    private void LoadActivity()
    {
        string compExt = GetCompanyFilter();

        GridHuman.DataSource = Run(@"
            SELECT text13 AS EmployeeID, COUNT(*) AS ScanCount
            FROM v_asset
            WHERE lastinventoried IS NOT NULL AND text13 IS NOT NULL " + compExt + @"
            GROUP BY text13 ORDER BY ScanCount DESC");

        GridHuman.DataBind();

        GridSystem.DataSource = Run(@"
            SELECT lastmodifiedby, COUNT(*) AS ScanCount
            FROM v_asset
            WHERE lastinventoried IS NOT NULL AND lastmodifiedby IS NOT NULL " + compExt + @"
            GROUP BY lastmodifiedby ORDER BY ScanCount DESC");

        GridSystem.DataBind();
    }

    // ---------------- QUALITY ----------------
    private void LoadQuality()
    {
        string compExt = GetCompanyFilter();

        DataRow r = Run(@"
            SELECT COUNT(*) T,
            SUM(CASE WHEN text19 IS NOT NULL THEN 1 ELSE 0 END) A,
            SUM(CASE WHEN text13 IS NOT NULL THEN 1 ELSE 0 END) B,
            SUM(CASE WHEN text16 IS NOT NULL THEN 1 ELSE 0 END) C,
            SUM(CASE WHEN listvalue1 IS NOT NULL THEN 1 ELSE 0 END) D
            FROM v_asset WHERE lastinventoried IS NOT NULL" + compExt).Rows[0];

        int t = Convert.ToInt32(r["T"]);
        LitPctTagType.Text = P(r["A"], t);
        LitPctEmp.Text = P(r["B"], t);
        LitPctLoc.Text = P(r["C"], t);
        LitPctDisp.Text = P(r["D"], t);
    }

    // ---------------- HELPERS ----------------
    private DataTable Run(string sql)
    {
        using (SqlDataAdapter da = new SqlDataAdapter(sql, ConnStr))
        {
            DataTable dt = new DataTable();
            da.Fill(dt);
            return dt;
        }
    }

    private string P(object a, int t)
    {
        return t == 0 ? "0%" :
            ((double)Convert.ToInt32(a) / t).ToString("P1");
    }
}
