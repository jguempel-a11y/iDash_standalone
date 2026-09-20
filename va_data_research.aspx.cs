using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Web.Script.Services;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;
using System.Text;
using ClosedXML.Excel;
using System.Web.UI.WebControls;

public partial class va_data_research : System.Web.UI.Page
{
    private const string DEFAULT_VISIBLE =
        "name,description,lastobservedlocation,listvalue1," +
        "text1,text2,text3,text4,text7,text8,text9,text16,text19,text20," +
        "lastinventoried";

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "rpt_data_research"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            LoadCompanies();
            // Initial UI rendering, JavaScript handles loading the baseline 200 assets
        }
    }

    private void LoadCompanies()
    {
        try
        {
            var allowedIds = UserManager.GetAllowedCompanyIds(Session, ConnString);
            using (SqlConnection conn = new SqlConnection(ConnString))
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
        catch (Exception)
        {
            // Ignore for visual JS
        }
    }

    private string ConnString
    {
        get
        {
            return System.Web.Configuration.WebConfigurationManager
                .ConnectionStrings["iDash"].ConnectionString;
        }
    }

    /* ==============================================================
       EXCEL → DATATABLE LOADER  (NO INTERPOLATION)
       ============================================================== */
    protected void ButtonLoadData_Click(object sender, EventArgs e)
    {
        LabelStatus.Text = "";

        if (!FileUploadExcel.HasFile)
        {
            LabelStatus.Text = "Please select a file.";
            LabelStatus.ForeColor = System.Drawing.Color.Red;
            return;
        }

        if (Path.GetExtension(FileUploadExcel.FileName).ToLower() != ".xlsx")
        {
            LabelStatus.Text = "Invalid file type.";
            LabelStatus.ForeColor = System.Drawing.Color.Red;
            return;
        }

        try
        {
            using (Stream s = FileUploadExcel.FileContent)
            using (XLWorkbook wb = new XLWorkbook(s))
            {
                IXLWorksheet ws = wb.Worksheets.Count > 0 ? wb.Worksheet(1) : null;
                DataTable dt = ExcelToDataTable(ws);

                Session["MyData"] = dt;
                Session["MyData_Columns"] =
                    dt.Columns.Cast<DataColumn>()
                    .Select(c => c.ColumnName)
                    .ToList();

                LabelStatus.Text = "Loaded " + dt.Rows.Count + " rows.";
                LabelStatus.ForeColor = System.Drawing.Color.Green;
            }
        }
        catch (Exception ex)
        {
            LabelStatus.Text = "Error: " + ex.Message;
            LabelStatus.ForeColor = System.Drawing.Color.Red;
        }
    }

    private DataTable ExcelToDataTable(IXLWorksheet ws)
    {
        DataTable dt = new DataTable();
        if (ws == null) return dt;

        var rng = ws.RangeUsed();
        if (rng == null) return dt;

        int cols = rng.ColumnCount();
        int rows = rng.RowCount();

        for (int c = 1; c <= cols; c++)
        {
            string header = ws.Cell(1, c).GetString();
            if (string.IsNullOrWhiteSpace(header)) header = "Column" + c;
            dt.Columns.Add(header);
        }

        for (int r = 2; r <= rows; r++)
        {
            var row = dt.Rows.Add();
            for (int c = 1; c <= cols; c++)
                row[c - 1] = ws.Cell(r, c).GetString();
        }

        return dt;
    }

    /* ==============================================================
       DATATABLES AJAX WEB METHOD (NO INTERPOLATION)
       ============================================================== */
    [WebMethod]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetTableData(int draw, int start, int length,
        List<Dictionary<string, string>> searchCols, int sortCol, string sortDir)
    {
        JavaScriptSerializer json = new JavaScriptSerializer();
        DataTable dt = (DataTable)System.Web.HttpContext.Current.Session["MyData"];

        if (dt == null)
        {
            return json.Serialize(new
            {
                draw = draw,
                recordsTotal = 0,
                recordsFiltered = 0,
                data = new object[] { }
            });
        }

        IEnumerable<DataRow> rows = dt.AsEnumerable();

        for (int i = 0; i < searchCols.Count; i++)
        {
            string f = searchCols[i]["value"];
            if (!string.IsNullOrEmpty(f))
            {
                int col = i;
                rows = rows.Where(r =>
                    r.ItemArray.Length > col && r[col] != null && r[col].ToString().IndexOf(f, StringComparison.OrdinalIgnoreCase) >= 0);
            }
        }

        // Apply column sorting dynamically
        if (sortCol >= 0 && sortCol < dt.Columns.Count)
        {
            if (sortDir.ToLower() == "desc")
            {
                // Simple string sort; handles everything reliably gracefully
                rows = rows.OrderByDescending(r => r.ItemArray.Length > sortCol ? r[sortCol].ToString() : "");
            }
            else
            {
                rows = rows.OrderBy(r => r.ItemArray.Length > sortCol ? r[sortCol].ToString() : "");
            }
        }

        int filtered = rows.Count();

        var page = rows.Skip(start).Take(length).ToList();

        var output = page
            .Select(r => r.ItemArray.Select(x => x.ToString()).ToArray())
            .ToList();

        return json.Serialize(new
        {
            draw = draw,
            recordsTotal = dt.Rows.Count,
            recordsFiltered = filtered,
            data = output
        });
    }

    /* ==============================================================
       LIVE SQL SEARCH API (JSON)
       ============================================================== */

    [WebMethod]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string SearchSqlAssets(string search, int topN, string site)
    {
        var q = (search ?? "").Trim();
        var s = (site ?? "0").Trim();
        var list = new List<Dictionary<string, string>>();
        string connStr = System.Web.Configuration.WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        using (SqlConnection cn = new SqlConnection(connStr))
        {
            string siteFilter = "";
            if (s != "0" && !string.IsNullOrEmpty(s))
            {
                siteFilter = " AND companyid = @site";
            }
            string sql =
                "SELECT TOP (@top) " +
                "name,description,lastobservedlocation,listvalue1," +
                "text1,text2,text3,text4,text5,text6,text7,text8,text9,text10,text11,text12,text13,text14," +
                "text16,text17,text18,text19,text20,lastinventoried " +
                "FROM dbo.v_asset WITH(NOLOCK) " +
                "WHERE ( @q = '' " +
                "   OR name LIKE @like " +
                "   OR rfidtag LIKE @like " +
                "   OR text1 LIKE @like " +
                "   OR text2 LIKE @like " +
                "   OR text3 LIKE @like " +
                "   OR text6 LIKE @like " +
                "   OR text7 LIKE @like " +
                "   OR text8 LIKE @like " +
                "   OR text12 LIKE @like " +
                " ) " + siteFilter + 
                " ORDER BY name ASC";

            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@top", topN);
                cmd.Parameters.AddWithValue("@q", q);
                cmd.Parameters.AddWithValue("@like", "%" + q + "%");
                if (s != "0" && !string.IsNullOrEmpty(s)) cmd.Parameters.AddWithValue("@site", s);

                cn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    var cols = new List<string>();
                    for (int i = 0; i < reader.FieldCount; i++)
                        cols.Add(reader.GetName(i));

                    while (reader.Read())
                    {
                        var dict = new Dictionary<string, string>();
                        foreach (var col in cols)
                        {
                            var val = reader[col];
                            dict[col] = (val == null || val == DBNull.Value) ? "" : val.ToString();
                        }
                        list.Add(dict);
                    }
                }
            }
        }

        return new JavaScriptSerializer() { MaxJsonLength = 86753090 }.Serialize(list);
    }

    /* ==============================================================
       BACK TO DASHBOARD HUB
       ============================================================== */
    protected void BtnBack_Click(object sender, EventArgs e)
    {
        Response.Redirect("index.aspx", true);
    }
}
