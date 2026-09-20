using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Text;
using System.Web;
using System.Web.UI.WebControls;

public partial class va_tag_audit_report : System.Web.UI.Page
{
    private string ConnStr
    {
        get
        {
            return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check — accepts both keys (hub shows rpt_activity; extended hub shows rpt_tag_audit)
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "rpt_tag_audit") &&
            !UserManager.CanAccessTile(role, tiles, "rpt_activity"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            LoadCompanies();

            // Default: current month (local)
            DateTime now = DateTime.Now;
            DateTime first = new DateTime(now.Year, now.Month, 1);
            DateTime last = first.AddMonths(1).AddDays(-1);

            TxtFrom.Text = first.ToString("yyyy-MM-dd");
            TxtTo.Text = last.ToString("yyyy-MM-dd");

            RunAndBind(false);
        }
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
            LitErr.Text = "<div class='err'>Error loading companies: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnRun_Click(object sender, EventArgs e)
    {
        RunAndBind(false);
    }

    protected void BtnExport_Click(object sender, EventArgs e)
    {
        RunAndBind(true);
    }

    private void RunAndBind(bool exportCsv)
    {
        LitErr.Text = "";

        DateTime fromLocal;
        DateTime toLocal;
        string err;

        if (!TryGetDateRange(out fromLocal, out toLocal, out err))
        {
            LitErr.Text = "<div class='err'>" + HttpUtility.HtmlEncode(err) + "</div>";
            return;
        }

        // Inclusive day range: [from 00:00 local] to [to+1 day 00:00 local)
        TimeZoneInfo localTz = TimeZoneInfo.Local;

        DateTime fromStartLocal = new DateTime(fromLocal.Year, fromLocal.Month, fromLocal.Day, 0, 0, 0, DateTimeKind.Unspecified);
        DateTime toExclusiveLocal = new DateTime(toLocal.Year, toLocal.Month, toLocal.Day, 0, 0, 0, DateTimeKind.Unspecified).AddDays(1);

        DateTime fromUtc = TimeZoneInfo.ConvertTimeToUtc(fromStartLocal, localTz);
        DateTime toUtcExclusive = TimeZoneInfo.ConvertTimeToUtc(toExclusiveLocal, localTz);

        DataTable dt = LoadReport(fromUtc, toUtcExclusive);

        LblCount.Text = dt.Rows.Count.ToString("N0");
        LblRange.Text = "Range: " + fromLocal.ToString("MM/dd/yyyy") + " - " + toLocal.ToString("MM/dd/yyyy") +
                        " (filtered via lastinventoried)";

        if (exportCsv)
        {
            string fileName = "VA_Tag_Audit_" + fromLocal.ToString("yyyyMMdd") + "_" + toLocal.ToString("yyyyMMdd") + ".csv";
            ExportDataTableToCsv(dt, fileName);
            return;
        }

        Grid.DataSource = dt;
        Grid.DataBind();

        if (Grid.Rows.Count > 0)
        {
            Grid.UseAccessibleHeader = true;
            Grid.HeaderRow.TableSection = TableRowSection.TableHeader;
        }

    }

    private bool TryGetDateRange(out DateTime from, out DateTime to, out string error)
    {
        error = null;
        from = DateTime.MinValue;
        to = DateTime.MinValue;

        // If blank, default current month
        if (string.IsNullOrWhiteSpace(TxtFrom.Text) || string.IsNullOrWhiteSpace(TxtTo.Text))
        {
            DateTime now = DateTime.Now;
            from = new DateTime(now.Year, now.Month, 1);
            to = from.AddMonths(1).AddDays(-1);
            return true;
        }

        if (!DateTime.TryParseExact(TxtFrom.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out from))
        {
            error = "Invalid From date. Use the date picker.";
            return false;
        }

        if (!DateTime.TryParseExact(TxtTo.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out to))
        {
            error = "Invalid To date. Use the date picker.";
            return false;
        }

        if (to < from)
        {
            error = "To date must be on or after From date.";
            return false;
        }

        return true;
    }

    private DataTable LoadReport(DateTime fromUtc, DateTime toUtcExclusive)
    {
        string companyFilter = "";
        if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
        {
            companyFilter = " AND a.companyid = @CompanyId";
        }

        string sql = @"
SELECT
    a.name            AS [NAME],
    a.description     AS [DESCRIPTION],
    a.listvalue1  AS [DISPOSAL_STATUS],
    a.lastinventoried AS [LAST_INVENTORIED],

    a.text1  AS [MANUFACTURER],
    a.text2  AS [MODEL],
    a.text3  AS [SERIAL_NUM],
    a.text4  AS [EQUIPMENT_CATEGORY],
    a.text5  AS [SERVICE_POINTER],
    a.text6  AS [LOCATION],
    a.text7  AS [STATION_NUMBER],
    a.text8  AS [CMR_EIL],
    a.text9  AS [PURCHASE_ORDER],

    a.text10 AS [PI_DATE_RAW],
    COALESCE(
        TRY_CONVERT(date, a.text10, 101),
        TRY_CONVERT(date, a.text10, 1),
        TRY_CONVERT(date, a.text10),
        TRY_CONVERT(date, LEFT(a.text10, 10), 101),
        TRY_CONVERT(date, REPLACE(a.text10, ',', '')),
        TRY_CONVERT(date, LEFT(REPLACE(a.text10, ',', ''), 11)),
        TRY_CONVERT(date, LEFT(REPLACE(a.text10, ',', ''), 12))
    ) AS [PI_DATE_PARSED],

    a.text11 AS [SP_PREV_LOCATION],
    a.text12 AS [ENTRY_NUMBER],
    a.text13 AS [EMPL_ID],
    a.text14 AS [SUBSTATION],
    a.text16 AS [LOCATION_TAGGED_FOUND],

    a.text17 AS [TAGGED_ON_RAW],
    COALESCE(
        TRY_CONVERT(date, a.text17, 101),
        TRY_CONVERT(date, a.text17, 1),
        TRY_CONVERT(date, a.text17),
        TRY_CONVERT(date, LEFT(a.text17, 10), 101),
        TRY_CONVERT(date, REPLACE(a.text17, ',', '')),
        TRY_CONVERT(date, LEFT(REPLACE(a.text17, ',', ''), 11)),
        TRY_CONVERT(date, LEFT(REPLACE(a.text17, ',', ''), 12))
    ) AS [TAGGED_ON_PARSED],

    a.text18 AS [TAGGED_RAW],
    CASE
        WHEN TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(a.text18)), '')) = 1 THEN 'Yes'
        ELSE 'No'
    END AS [TAGGED_YN],

    a.text19 AS [TAG_TYPE],
    a.text20 AS [NOTES]
FROM dbo.asset a
WHERE
    a.lastinventoried >= @FromUtc
    AND a.lastinventoried <  @ToUtcExclusive" + companyFilter + @"
ORDER BY
    a.lastinventoried ASC, a.name ASC;
";

        DataTable dt = new DataTable();

        using (SqlConnection con = new SqlConnection(ConnStr))
        using (SqlCommand cmd = new SqlCommand(sql, con))
        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
        {
            cmd.CommandTimeout = 180;

            cmd.Parameters.Add("@FromUtc", SqlDbType.DateTime2).Value = fromUtc;
            cmd.Parameters.Add("@ToUtcExclusive", SqlDbType.DateTime2).Value = toUtcExclusive;

            if (!string.IsNullOrEmpty(companyFilter))
            {
                cmd.Parameters.Add("@CompanyId", SqlDbType.Int).Value = int.Parse(DdlCompany.SelectedValue);
            }

            con.Open();
            da.Fill(dt);
        }

        return dt;
    }

    private void ExportDataTableToCsv(DataTable dt, string fileName)
    {
        Response.Clear();
        Response.Buffer = true;
        Response.Charset = "";
        Response.ContentType = "text/csv";
        Response.AddHeader("Content-Disposition", "attachment;filename=" + fileName);

        StringBuilder sb = new StringBuilder();

        // Header
        for (int i = 0; i < dt.Columns.Count; i++)
        {
            if (i > 0) sb.Append(",");
            sb.Append(CsvEscape(dt.Columns[i].ColumnName));
        }
        sb.AppendLine();

        // Rows
        for (int r = 0; r < dt.Rows.Count; r++)
        {
            DataRow row = dt.Rows[r];
            for (int c = 0; c < dt.Columns.Count; c++)
            {
                if (c > 0) sb.Append(",");
                sb.Append(CsvEscape(Convert.ToString(row[c])));
            }
            sb.AppendLine();
        }

        Response.Write(sb.ToString());
        Response.Flush();
        Response.End();
    }

    private string CsvEscape(string s)
    {
        if (s == null) return "";

        s = s.Replace("\r", " ").Replace("\n", " ");
        bool mustQuote = (s.IndexOf(",") >= 0) || (s.IndexOf("\"") >= 0);

        if (s.IndexOf("\"") >= 0)
            s = s.Replace("\"", "\"\"");

        if (mustQuote)
            return "\"" + s + "\"";

        return s;
    }
}