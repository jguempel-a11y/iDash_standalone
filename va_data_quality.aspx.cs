using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System.Web;

public partial class va_data_quality : System.Web.UI.Page
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
        // ── AJAX preview endpoint (GET, no session write needed) ──────────
        if (Request.QueryString["api"] == "preview")
        {
            HandlePreviewApi();
            return;
        }

        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "rpt_data_quality"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            LoadCompanies();
            RefreshCounts();
        }
        else if (DdlCompany.Items.Count == 0)
        {
            // Safety net: if ViewState somehow lost the company list, re-bind it
            LoadCompanies();
        }
    }

    // ── AJAX preview handler — returns JSON {cols:[...], rows:[[...],...]}
    private void HandlePreviewApi()
    {
        Response.Clear();
        Response.ContentType = "application/json";
        try
        {
            // Auth — read session even in ReadOnly mode
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn) { Response.Write("{\"error\":\"auth\"}"); Response.End(); return; }

            string type   = (Request.QueryString["type"]   ?? "").ToLower();
            string siteId = Request.QueryString["siteid"] ?? "0";

            // Build site filter — whitelist numeric site id to prevent injection
            string siteFilter = "";
            int sid;
            if (int.TryParse(siteId, out sid) && sid > 0)
                siteFilter = " AND a.companyid = " + sid;

            // Also apply access restriction
            string accessFilter = UserManager.BuildSiteFilter(Session, ConnStr, "a");
            siteFilter += accessFilter;

            string sql;
            switch (type)
            {
                case "noeil":
                    sql = @"SELECT TOP 50
                            a.name AS [Name], a.text8 AS [EIL], a.description AS [Description],
                            a.locationname AS [Location], a.text19 AS [Tag_Type],
                            a.lastinventoried AS [Last_Inventoried]
                        FROM dbo.v_asset a WITH(NOLOCK)
                        WHERE (a.text8 IS NULL OR LTRIM(RTRIM(a.text8)) = '')" + siteFilter + " ORDER BY a.name ASC";
                    break;
                case "noloc":
                    sql = @"SELECT TOP 50
                            a.name AS [Name], a.locationname AS [Location], a.text8 AS [EIL],
                            a.listvalue1 AS [Status], a.description AS [Description]
                        FROM dbo.v_asset a WITH(NOLOCK)
                        WHERE a.locationid IS NULL" + siteFilter + " ORDER BY a.name ASC";
                    break;
                case "statusother":
                    sql = @"SELECT TOP 50
                            a.name AS [Name], a.locationname AS [Location], a.text8 AS [EIL],
                            a.listvalue1 AS [Status], a.description AS [Description]
                        FROM dbo.v_asset a WITH(NOLOCK)
                        WHERE (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + siteFilter + " ORDER BY a.listvalue1 ASC, a.name ASC";
                    break;
                case "malformedee":
                    sql = @"SELECT TOP 50
                            a.name AS [Asset_Name],
                            c.name AS [Site],
                            a.description AS [Description],
                            a.locationname AS [Location],
                            a.text8 AS [EIL],
                            a.listvalue1 AS [Status]
                        FROM dbo.v_asset a WITH(NOLOCK)
                        JOIN dbo.company c WITH(NOLOCK) ON a.companyid = c.id
                        WHERE (
                            a.name NOT LIKE LEFT(c.name, 3) + '% EE[0-9]%'
                            OR a.name LIKE '% % EE%'
                            OR a.name LIKE '% EE%[^0-9]%'
                        )" + siteFilter + " ORDER BY a.name ASC";
                    break;
                default:
                    Response.Write("{\"error\":\"unknown type\"}");
                    Response.End(); return;
            }

            using (var cn = new SqlConnection(ConnStr))
            using (var cmd = new SqlCommand(sql, cn))
            {
                cn.Open();
                cmd.CommandTimeout = 30;
                using (var rdr = cmd.ExecuteReader())
                {
                    var sb = new StringBuilder("{\"cols\":");
                    // Columns
                    var cols = new List<string>();
                    for (int i = 0; i < rdr.FieldCount; i++) cols.Add(rdr.GetName(i));
                    sb.Append("[");
                    for (int i = 0; i < cols.Count; i++)
                    {
                        if (i > 0) sb.Append(",");
                        sb.Append("\"").Append(cols[i].Replace("\"", "\\\"")).Append("\"");
                    }
                    sb.Append("],\"rows\":");
                    // Rows
                    sb.Append("[");
                    bool firstRow = true;
                    while (rdr.Read())
                    {
                        if (!firstRow) sb.Append(",");
                        firstRow = false;
                        sb.Append("[");
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            if (i > 0) sb.Append(",");
                            if (rdr.IsDBNull(i)) { sb.Append("null"); }
                            else {
                                var v = rdr.GetValue(i);
                                sb.Append("\"").Append(Convert.ToString(v).Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", " ").Replace("\r", "")).Append("\"");
                            }
                        }
                        sb.Append("]");
                    }
                    sb.Append("]}");
                    Response.Write(sb.ToString());
                }
            }
        }
        catch (System.Threading.ThreadAbortException) { }
        catch (Exception ex)
        {
            Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
        }
        finally { Response.End(); }
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
                    DdlCompany.Items.Insert(0, new ListItem("-- No sites assigned --", "0"));
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
                    DdlCompany.Items.Insert(0, new ListItem("All Companies", "0"));
                else if (DdlCompany.Items.Count == 1)
                    DdlCompany.SelectedIndex = 0;
            }
        }
        catch (Exception ex)
        {
            LitErr.Text = "<div class='err'>Error loading companies: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        RefreshCounts();
    }

    private string GetCompanyFilter()
    {
        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            return " AND a.companyid = " + DdlCompany.SelectedValue;
        }
        return "";
    }

    private string GetGlobalWhereClause()
    {
        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            return " WHERE companyid = " + DdlCompany.SelectedValue;
        }
        return "";
    }

    protected void BtnRefresh_Click(object sender, EventArgs e)
    {
        RefreshCounts();
    }

    private void RefreshCounts()
    {
        try
        {
            // Total assets (denominator for percentages)
            var dt0 = Run("SELECT COUNT(*) FROM dbo.v_asset a WITH(NOLOCK)" +
                (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue)
                    ? " WHERE a.companyid = " + DdlCompany.SelectedValue : ""), null);
            LitTotalCount.Text = (dt0 != null && dt0.Rows.Count > 0) ? dt0.Rows[0][0].ToString() : "0";

            // 1. No EIL
            var dt1 = Run("SELECT COUNT(*) FROM dbo.v_asset a WITH(NOLOCK) WHERE (a.text8 IS NULL OR LTRIM(RTRIM(a.text8)) = '')" + GetCompanyFilter(), null);
            LitNoEILCount.Text = (dt1 != null && dt1.Rows.Count > 0) ? dt1.Rows[0][0].ToString() : "0";

            // 2. No Location
            var dt2 = Run("SELECT COUNT(*) FROM dbo.v_asset a WITH(NOLOCK) WHERE a.locationid IS NULL" + GetCompanyFilter(), null);
            LitNoLocCount.Text = (dt2 != null && dt2.Rows.Count > 0) ? dt2.Rows[0][0].ToString() : "0";

            // 3. Status Other
            var dt3 = Run("SELECT COUNT(*) FROM dbo.v_asset a WITH(NOLOCK) WHERE (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + GetCompanyFilter(), null);
            LitStatusOtherCount.Text = (dt3 != null && dt3.Rows.Count > 0) ? dt3.Rows[0][0].ToString() : "0";

            // 4. Malformed / Non-Conforming EE Asset Number (anything other than site + space + EE + entry number)
            string sqlMalformed = @"
                SELECT COUNT(*) 
                FROM dbo.v_asset a WITH(NOLOCK) 
                JOIN dbo.company c WITH(NOLOCK) ON a.companyid = c.id
                WHERE (
                    a.name NOT LIKE LEFT(c.name, 3) + '% EE[0-9]%'
                    OR a.name LIKE '% % EE%'
                    OR a.name LIKE '% EE%[^0-9]%'
                )" + GetCompanyFilter();
            var dt4 = Run(sqlMalformed, null);
            LitMalformedEECount.Text = (dt4 != null && dt4.Rows.Count > 0) ? dt4.Rows[0][0].ToString() : "0";
        }
        catch (Exception ex)
        {
            LitErr.Text = "<div class='err-msg'>Error calculating totals: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }


    // ==========================================================================================
    // EXPORT HANDLER
    // ==========================================================================================
    protected void Export_Click(object sender, EventArgs e)
    {
        try 
        {
            var btn = (LinkButton)sender;
            var arg = (btn.CommandArgument ?? "").ToString();
            var parts = arg.Split('|');
            if (parts.Length < 1) return;

            string key = parts[0];     // e.g. "GridNoEIL"
            string fileName = (parts.Length > 1 ? parts[1] : key) + ".csv";

            string sql = "";

            // Re-run the FULL query (not Top 50) for export
            switch(key)
            {
                case "GridNoEIL":
                     sql = @"
                        SELECT
                            a.name            AS [Name],
                            a.text8           AS [EIL],
                            a.description     AS [Description],
                            a.locationname    AS [Location],
                            a.text7           AS [Station_Number],
                            a.text14          AS [Sub_Station],
                            a.text19          AS [Tag_Type],
                            a.text13          AS [Empl_ID],
                            a.text10          AS [Previous_Inventory_Date],
                            a.text17          AS [Tag_Date],
                            a.text6           AS [Previous_Location],
                            a.text16          AS [LocationTagged],
                            a.listvalue1      AS [DisposalStatus],
                            a.text20          AS [Notes],
                            a.lastmodifiedby  AS [Last_Modified_By],
                            a.lastinventoried AS [LastInventoried]
                        FROM dbo.v_asset a WITH(NOLOCK)
                        WHERE (a.text8 IS NULL OR LTRIM(RTRIM(a.text8)) = '')" + GetCompanyFilter() + @"
                        ORDER BY a.name ASC;";
                    break;

                case "GridNoLoc":
                    sql = "SELECT a.name, a.locationname AS Location, a.text8 AS EIL, " +
                          "a.listvalue1 AS DisposalStatus " +
                          "FROM dbo.v_asset a WITH(NOLOCK) WHERE a.locationid IS NULL" + GetCompanyFilter() + " ORDER BY a.name ASC;";
                    break;

                case "GridStatusOther":
                    sql = "SELECT a.name, a.locationname AS Location, a.text8 AS EIL, a.listvalue1 AS DisposalStatus " +
                          "FROM dbo.v_asset a WITH(NOLOCK) " +
                          "WHERE (a.listvalue1 <> 'In Use' OR a.listvalue1 IS NULL)" + GetCompanyFilter() + " " +
                          "ORDER BY DisposalStatus ASC, a.name ASC;";
                    break;

                case "GridMalformedEE":
                    sql = @"
                        SELECT
                            a.name            AS [Asset_Name],
                            c.name            AS [Site],
                            a.description     AS [Description],
                            a.locationname    AS [Location],
                            a.text8           AS [EIL],
                            a.text7           AS [Station_Number],
                            a.listvalue1      AS [Status],
                            a.lastinventoried AS [Last_Inventoried]
                        FROM dbo.v_asset a WITH(NOLOCK)
                        JOIN dbo.company c WITH(NOLOCK) ON a.companyid = c.id
                        WHERE (
                            a.name NOT LIKE LEFT(c.name, 3) + '% EE[0-9]%'
                            OR a.name LIKE '% % EE%'
                            OR a.name LIKE '% EE%[^0-9]%'
                        )" + GetCompanyFilter() + @"
                        ORDER BY a.name ASC;";
                    break;
            }

            if (string.IsNullOrEmpty(sql))
            {
                LitErr.Text = "<div class='err-msg'>Unknown export target.</div>";
                return;
            }

            var dt = Run(sql, null);
            if (dt == null || dt.Rows.Count == 0) {
                LitErr.Text = "<div class='err-msg'>No data found to export.</div>";
                return;
            }

            string csv = GenerateCsvContent(dt, true);
            DownloadContent(fileName, csv, "text/csv");
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Normal — thrown by Response.End() inside DownloadContent()
        }
        catch (Exception ex)
        {
             LitErr.Text = "<div class='err-msg'>Export failed: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnExportExcel_Click(object sender, EventArgs e)
    {
        try
        {
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = @"
                    SELECT 
                        name AS [Asset Name],
                        description AS [Description],
                        text4 AS [Category],
                        listvalue1 AS [Status],
                        locationname AS [Location],
                        text8 AS [EIL],
                        text7 AS [Station Code],
                        lastinventoried AS [Last Inventoried],
                        lastobservedtime AS [Last Observed],
                        rfidtag AS [RFID Tag]
                    FROM dbo.v_asset" + GetGlobalWhereClause() + " ORDER BY name";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    string csv = GenerateCsvContent(dt, true);
                    DownloadContent("AssetStats_Export_" + DateTime.Now.ToString("yyyyMMdd") + ".csv", csv, "text/csv");
                }
            }
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Normal when calling Response.End()
        }
        catch (Exception ex)
        {
            LitErr.Text = "<div class='err'>Error exporting to excel: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }


    // ==========================================================================================
    // HELPERS
    // ==========================================================================================
    private DataTable Run(string sql, SqlParameter[] pars)
    {
        DataTable dt = new DataTable();
        try {
            using (SqlConnection cn = new SqlConnection(ConnStr))
            using (SqlDataAdapter da = new SqlDataAdapter(sql, cn))
            {
                if (pars != null) {
                    foreach (SqlParameter p in pars)
                        da.SelectCommand.Parameters.AddWithValue(p.ParameterName, (p.Value == null ? "" : p.Value));
                }
                da.Fill(dt);
            }
        }
        catch (Exception ex)
        {
            LitErr.Text = "<div class='err-msg'>" + Server.HtmlEncode(ex.Message) + "</div>";
        }
        return dt;
    }


    private string BuildAssetStatusExpr()
    {
        var present = new List<string>();
        try {
            using(var cn = new SqlConnection(ConnStr))
            using (var cmd = new SqlCommand(
                "SELECT c.name FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.v_asset') " +
                "AND c.name IN ('status','statuscode','state','condition') ORDER BY " +
                "CASE c.name WHEN 'status' THEN 1 WHEN 'statuscode' THEN 2 WHEN 'state' THEN 3 WHEN 'condition' THEN 4 ELSE 5 END", cn))
            {
                cn.Open();
                using(var r = cmd.ExecuteReader())
                    while (r.Read()) present.Add("a." + r.GetString(0));
            }
        } catch { }
        if (present.Count == 0) return "NULL";
        if (present.Count == 1) return present[0];
        return "COALESCE(" + string.Join(", ", present) + ")";
    }

    private string GenerateCsvContent(DataTable dt, bool excelSafe)
    {
        if (dt == null || dt.Rows.Count == 0) return "";
        StringBuilder sb = new StringBuilder();

        // Headers
        var cols = dt.Columns.Cast<DataColumn>().ToList();
        sb.AppendLine(string.Join(",", cols.Select(c => CsvEscape(c.ColumnName))));

        // Rows
        foreach(DataRow row in dt.Rows)
        {
            var fields = new List<string>();
            foreach(var col in cols)
            {
                string val = Convert.ToString(row[col]);
                if (excelSafe) {
                    string escaped = val.Replace("\"", "\"\"");
                    fields.Add("\"=\"\"" + escaped + "\"\"\"");
                } else {
                    fields.Add(CsvEscape(val));
                }
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
        byte[] bytes = new UTF8Encoding(true).GetBytes(content);
        Response.Clear();
        Response.Buffer = true;
        Response.Charset = "";
        Response.ContentType = contentType;
        Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
        Response.BinaryWrite(bytes);
        Response.End();
    }
}
