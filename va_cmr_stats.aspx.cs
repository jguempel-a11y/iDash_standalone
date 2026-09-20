using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.UI.WebControls;
using System.Text;
using System.Collections.Generic;
using System.Net.Mail;

public partial class va_cmr_stats : System.Web.UI.Page
{
    private string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    // ─────────────────────────────────────────────────────────────
    // PAGE LOAD
    // ─────────────────────────────────────────────────────────────
    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "rpt_cmr"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (!IsPostBack)
        {
            HdnScanWindow.Value = "30";
            LoadCompanies();
            LoadAll();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────
    private DateTime GetScanFrom()
    {
        string w = HdnScanWindow.Value;
        if (w == "today") return DateTime.Today;
        if (w == "7")     return DateTime.Today.AddDays(-7);
        if (w == "30")    return DateTime.Today.AddDays(-30);
        return new DateTime(1900, 1, 1);
    }

    private string GetScanWindowLabel()
    {
        string w = HdnScanWindow.Value;
        if (w == "today") return "Today";
        if (w == "7")     return "Last 7 Days";
        if (w == "30")    return "Last 30 Days";
        return "All Time";
    }

    private int GetCompanyId()
    {
        int c;
        int.TryParse(DdlCompany.SelectedValue, out c);
        return c;
    }

    private string GetSearch() { return TxtCmrSearch.Text.Trim(); }

    /// <summary>
    /// Builds a SQL WHERE fragment for the CMR (text8) field.
    ///
    /// • Single value  → LIKE '%value%'   (partial / prefix match)
    /// • Comma list    → IN (@v0,@v1,...) (exact match on each, deduped, case-insensitive trim)
    ///
    /// Adds the necessary SqlParameters to cmd and returns the fragment string
    /// which is safe to inject because it never contains raw user text — only
    /// named parameter placeholders.
    /// </summary>
    private string GetCmrFilter(string search, SqlCommand cmd)
    {
        if (string.IsNullOrWhiteSpace(search))
            return "1=1";

        if (search.Contains(","))
        {
            // Multi-CMR exact IN() match
            string[] parts = search.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            List<string> paramNames = new List<string>();
            HashSet<string> seen    = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            int idx = 0;
            foreach (string part in parts)
            {
                string val = part.Trim();
                if (!string.IsNullOrEmpty(val) && seen.Add(val))
                {
                    string pName = "@CmrVal" + idx;
                    cmd.Parameters.AddWithValue(pName, val);
                    paramNames.Add(pName);
                    idx++;
                }
            }
            if (paramNames.Count == 0) return "1=1";
            return "LTRIM(RTRIM(a.text8)) IN (" + string.Join(", ", paramNames) + ")";
        }
        else
        {
            // Single partial LIKE match
            cmd.Parameters.AddWithValue("@CmrSearch", search);
            return "a.text8 LIKE '%' + @CmrSearch + '%'";
        }
    }

    private string StatusBadge(int scanned, int total)
    {
        if (total == 0)       return "<span class=\"badge-none\">&#8212;</span>";
        if (scanned == 0)     return "<span class=\"badge-none\">Not Started</span>";
        if (scanned >= total) return "<span class=\"badge-complete\">&#10003; Complete</span>";
        return "<span class=\"badge-progress\">In Progress</span>";
    }

    private string ProgressBar(int scanned, int total)
    {
        double pct = total > 0 ? (scanned * 100.0 / total) : 0;
        string color = pct >= 100 ? "var(--success)" : pct >= 50 ? "var(--highlight)" : pct > 0 ? "var(--warning)" : "var(--danger)";
        return "<div class=\"cmr-bar-bg\"><div class=\"cmr-bar-fill\" style=\"width:" + pct.ToString("0.0") + "%;background:" + color + ";\"></div></div>";
    }

    private string SafeStr(object val)
    {
        if (val == null || val == DBNull.Value) return "";
        return val.ToString().Trim();
    }

    // ─────────────────────────────────────────────────────────────
    // LOAD COMPANIES DROPDOWN
    // ─────────────────────────────────────────────────────────────
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
                    DdlCompany.DataSource   = rdr;
                    DdlCompany.DataTextField  = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }
                if (DdlCompany.Items.Count > 1 || allowedIds == null)
                    DdlCompany.Items.Insert(0, new ListItem("All Sites", "0"));
                else if (DdlCompany.Items.Count == 1)
                    DdlCompany.SelectedIndex = 0;
            }
        }
        catch (Exception) { }
    }

    // ─────────────────────────────────────────────────────────────
    // MASTER LOAD
    // ─────────────────────────────────────────────────────────────
    private void LoadAll()
    {
        LblScanWindowLabel.Text = GetScanWindowLabel();
        LoadKpis();
        LoadCmrSummary();
    }

    // ─────────────────────────────────────────────────────────────
    // KPI TOTALS
    // ─────────────────────────────────────────────────────────────
    private void LoadKpis()
    {
        DateTime scanFrom = GetScanFrom();
        int cid           = GetCompanyId();
        string search     = GetSearch();

        try
        {
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand())
                {
                    cmd.Connection     = conn;
                    cmd.CommandTimeout = 120;
                    string cmrFilter   = GetCmrFilter(search, cmd);

                    cmd.CommandText = @"
                        SELECT
                            COUNT(DISTINCT a.text8)                                                                      AS TotalCmrs,
                            COUNT(*)                                                                                      AS TotalAssets,
                            SUM(CASE WHEN CONVERT(date,a.lastinventoried) >= @ScanFrom THEN 1 ELSE 0 END)                AS ScannedCount,
                            COUNT(*) - SUM(CASE WHEN CONVERT(date,a.lastinventoried) >= @ScanFrom THEN 1 ELSE 0 END)     AS RemainingCount,
                            SUM(CASE WHEN a.lastinventoried IS NULL THEN 1 ELSE 0 END)                                   AS NeverScanned
                        FROM dbo.v_asset a
                        WHERE NULLIF(RTRIM(a.text8), '') IS NOT NULL
                          AND (@CId = 0 OR a.companyid = @CId)
                          AND (" + cmrFilter + ")";

                    cmd.Parameters.Add(new SqlParameter("@ScanFrom", SqlDbType.Date) { Value = scanFrom });
                    cmd.Parameters.AddWithValue("@CId", cid);

                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            int total     = rdr["TotalAssets"]    == DBNull.Value ? 0 : Convert.ToInt32(rdr["TotalAssets"]);
                            int scanned   = rdr["ScannedCount"]   == DBNull.Value ? 0 : Convert.ToInt32(rdr["ScannedCount"]);
                            int remaining = rdr["RemainingCount"] == DBNull.Value ? 0 : Convert.ToInt32(rdr["RemainingCount"]);
                            int never     = rdr["NeverScanned"]   == DBNull.Value ? 0 : Convert.ToInt32(rdr["NeverScanned"]);
                            int cmrs      = rdr["TotalCmrs"]      == DBNull.Value ? 0 : Convert.ToInt32(rdr["TotalCmrs"]);
                            double pct    = total > 0 ? (scanned * 100.0 / total) : 0;

                            HdnKpiTotal.Value   = total.ToString();
                            HdnKpiScanned.Value = scanned.ToString();
                            HdnKpiRemain.Value  = remaining.ToString();
                            HdnKpiNever.Value   = never.ToString();
                            HdnKpiCmrs.Value    = cmrs.ToString();
                            HdnKpiPct.Value     = pct.ToString("F1");
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            LitErr.Text = "<div class='err-msg'>KPI Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ─────────────────────────────────────────────────────────────
    // CMR SUMMARY TABLE (rendered as HTML Literal)
    // ─────────────────────────────────────────────────────────────
    private void LoadCmrSummary()
    {
        DateTime scanFrom  = GetScanFrom();
        int cid            = GetCompanyId();
        string search      = GetSearch();
        string windowLabel = GetScanWindowLabel();

        try
        {
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand())
                {
                    cmd.Connection     = conn;
                    cmd.CommandTimeout = 300;
                    string cmrFilter   = GetCmrFilter(search, cmd);

                    cmd.CommandText = @"
                        SELECT
                            a.text8                                                                                         AS CMR,
                            COUNT(*)                                                                                         AS TotalAssets,
                            SUM(CASE WHEN CONVERT(date,a.lastinventoried) >= @ScanFrom THEN 1 ELSE 0 END)                   AS ScannedCount,
                            COUNT(*) - SUM(CASE WHEN CONVERT(date,a.lastinventoried) >= @ScanFrom THEN 1 ELSE 0 END)        AS RemainingCount,
                            MAX(a.lastinventoried)                                                                           AS LastScanDate,
                            STUFF((SELECT DISTINCT ', ' + LOWER(LTRIM(RTRIM(v2.lastmodifiedby)))
                                   FROM dbo.v_asset v2
                                   WHERE v2.text8 = a.text8
                                     AND NULLIF(RTRIM(v2.lastmodifiedby), '') IS NOT NULL
                                     AND CONVERT(date, v2.lastinventoried) >= @ScanFrom
                                     AND (@CId = 0 OR v2.companyid = @CId)
                                   FOR XML PATH('')), 1, 2, '')                                                              AS Scanners,
                            (SELECT TOP 1 ISNULL(v2.locationname, '')
                             FROM dbo.v_asset v2
                             WHERE v2.text8 = a.text8
                               AND v2.lastinventoried IS NOT NULL
                               AND CONVERT(date, v2.lastinventoried) >= @ScanFrom
                               AND (@CId = 0 OR v2.companyid = @CId)
                             ORDER BY v2.lastinventoried DESC)                                                               AS LastLocation
                        FROM dbo.v_asset a
                        WHERE NULLIF(RTRIM(a.text8), '') IS NOT NULL
                          AND (@CId = 0 OR a.companyid = @CId)
                          AND (" + cmrFilter + @")
                        GROUP BY a.text8
                        ORDER BY
                            SUM(CASE WHEN CONVERT(date,a.lastinventoried) >= @ScanFrom THEN 1 ELSE 0 END) * 1.0 / COUNT(*) DESC,
                            SUM(CASE WHEN CONVERT(date,a.lastinventoried) >= @ScanFrom THEN 1 ELSE 0 END) DESC,
                            COUNT(*) DESC";

                    cmd.Parameters.Add(new SqlParameter("@ScanFrom", SqlDbType.Date) { Value = scanFrom });
                    cmd.Parameters.AddWithValue("@CId", cid);

                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        if (dt.Rows.Count == 0)
                        {
                            LitCmrSummary.Text = "<div class='no-data'>No CMR data found for the current filters.</div>";
                            return;
                        }

                        StringBuilder sb = new StringBuilder();
                        sb.Append("<div class='cmr-table-wrap'>");
                        sb.Append("<table id='CmrSummaryTable' class='cmr-table display'>");
                        sb.Append("<thead><tr>");
                        sb.Append("<th>CMR</th>");
                        sb.Append("<th class='num-col'>Total</th>");
                        sb.Append("<th class='num-col'>Found (" + Server.HtmlEncode(windowLabel) + ")</th>");
                        sb.Append("<th class='num-col'>Remaining</th>");
                        sb.Append("<th style='min-width:140px;'>Progress</th>");
                        sb.Append("<th class='num-col'>%</th>");
                        sb.Append("<th>Last Scan</th>");
                        sb.Append("<th>Scanners</th>");
                        sb.Append("<th>Last Location Found</th>");
                        sb.Append("<th>Status</th>");
                        sb.Append("</tr></thead><tbody>");

                        foreach (DataRow row in dt.Rows)
                        {
                            string cmr    = SafeStr(row["CMR"]);
                            int total     = Convert.ToInt32(row["TotalAssets"]);
                            int scanned   = Convert.ToInt32(row["ScannedCount"]);
                            int remaining = Convert.ToInt32(row["RemainingCount"]);

                            string lastScan;
                            if (row["LastScanDate"] == DBNull.Value)
                                lastScan = "Never";
                            else if (row["LastScanDate"] is DateTimeOffset)
                                lastScan = ((DateTimeOffset)row["LastScanDate"]).LocalDateTime.ToString("MM/dd/yyyy HH:mm");
                            else
                                lastScan = Convert.ToDateTime(row["LastScanDate"]).ToString("MM/dd/yyyy HH:mm");

                            string scanner  = SafeStr(row["Scanners"]);
                            string location = SafeStr(row["LastLocation"]);
                            double pct      = total > 0 ? (scanned * 100.0 / total) : 0;

                            if (string.IsNullOrEmpty(scanner))  scanner  = "<span style='color:#5a7090;font-size:12px;'>None in window</span>";
                            if (string.IsNullOrEmpty(location)) location = "<span style='color:#5a7090;font-size:12px;'>Not recorded</span>";

                            sb.Append("<tr>");
                            sb.Append("<td><strong style='color:var(--highlight);'>" + Server.HtmlEncode(cmr) + "</strong></td>");
                            sb.Append("<td class='num-col'>" + total + "</td>");
                            sb.Append("<td class='num-col'><strong style='color:var(--success);'>" + scanned + "</strong></td>");
                            sb.Append("<td class='num-col'><strong style='color:" + (remaining > 0 ? "var(--warning)" : "var(--success)") + ";'>" + remaining + "</strong></td>");
                            sb.Append("<td>" + ProgressBar(scanned, total) + "</td>");
                            sb.Append("<td class='num-col' data-order='" + pct.ToString("000.0") + "'><strong>" + pct.ToString("0.0") + "%</strong></td>");
                            sb.Append("<td style='font-size:12px;'>" + Server.HtmlEncode(lastScan) + "</td>");
                            sb.Append("<td style='font-size:12px;'>" + scanner + "</td>");
                            sb.Append("<td style='font-size:12px;'>" + location + "</td>");
                            sb.Append("<td>" + StatusBadge(scanned, total) + "</td>");
                            sb.Append("</tr>");
                        }

                        sb.Append("</tbody></table></div>");
                        LitCmrSummary.Text = sb.ToString();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            LitCmrSummary.Text = "<div class='err-msg'>Summary Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ─────────────────────────────────────────────────────────────
    // EVENT HANDLERS
    // ─────────────────────────────────────────────────────────────
    protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e) { LoadAll(); }
    protected void BtnSearch_Click(object sender, EventArgs e) { LoadAll(); }
    protected void BtnScanWindow_Click(object sender, EventArgs e)
    {
        HdnScanWindow.Value = ((LinkButton)sender).CommandArgument;
        LoadAll();
    }

    // ─────────────────────────────────────────────────────────────
    // EXPORT — CMR SUMMARY CSV
    // ─────────────────────────────────────────────────────────────
    protected void BtnExportSummary_Click(object sender, EventArgs e)
    {
        try
        {
            byte[] bytes = GetSummaryCsvBytes();
            if (bytes != null)
            {
                string fn = "CMR_Summary_" + GetScanWindowLabel().Replace(" ", "") + "_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";
                Response.ClearContent();
                Response.AddHeader("content-disposition", "attachment; filename=" + fn);
                Response.ContentType = "text/csv";
                Response.BinaryWrite(bytes);
                Response.End();
            }
        }
        catch (System.Threading.ThreadAbortException) { }
        catch (Exception ex) { LitErr.Text = "<div class='err-msg'>Export Error: " + Server.HtmlEncode(ex.Message) + "</div>"; }
    }

    // ─────────────────────────────────────────────────────────────
    // EXPORT — ASSET DETAIL CSV
    // ─────────────────────────────────────────────────────────────
    protected void BtnExportDetail_Click(object sender, EventArgs e)
    {
        try
        {
            byte[] bytes = GetDetailCsvBytes();
            if (bytes != null)
            {
                string fn = "CMR_AssetDetail_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";
                Response.ClearContent();
                Response.AddHeader("content-disposition", "attachment; filename=" + fn);
                Response.ContentType = "text/csv";
                Response.BinaryWrite(bytes);
                Response.End();
            }
        }
        catch (System.Threading.ThreadAbortException) { }
        catch (Exception ex) { LitErr.Text = "<div class='err-msg'>Export Error: " + Server.HtmlEncode(ex.Message) + "</div>"; }
    }

    // ─────────────────────────────────────────────────────────────
    // EMAIL
    // ─────────────────────────────────────────────────────────────
    protected void BtnEmail_Click(object sender, EventArgs e)
    {
        try
        {
            string window  = GetScanWindowLabel();
            string site    = DdlCompany.SelectedItem != null ? DdlCompany.SelectedItem.Text : "All Sites";
            string search  = GetSearch();
            string subject = "iDash CMR Progress Report — " + window + " — " + site;
            string body    = "<h3>CMR Progress Report</h3>";
            body += "<p>Generated: " + DateTime.Now.ToString("g") + " &nbsp;|&nbsp; Site: " + site + " &nbsp;|&nbsp; Scan Window: " + window;
            if (!string.IsNullOrEmpty(search)) body += " &nbsp;|&nbsp; CMR Filter: <strong>" + System.Web.HttpUtility.HtmlEncode(search) + "</strong>";
            body += "</p><p>Please review the attached CSV for the full CMR-by-CMR breakdown.</p>";

            byte[] csvBytes = GetSummaryCsvBytes();
            List<Attachment> attachments = null;
            if (csvBytes != null && csvBytes.Length > 0)
            {
                attachments = new List<Attachment>();
                System.IO.MemoryStream ms = new System.IO.MemoryStream(csvBytes);
                string fn = "CMR_Summary_" + window.Replace(" ", "") + "_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";
                attachments.Add(new Attachment(ms, fn, "text/csv"));
            }

            EmailHelper.SendEmail(subject, body, attachments);
            LitErr.Text = "<div class='ok-msg'>&#10003; Report emailed successfully.</div>";
        }
        catch (Exception ex)
        {
            LitErr.Text = "<div class='err-msg'>Email Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ─────────────────────────────────────────────────────────────
    // CSV BUILDERS
    // ─────────────────────────────────────────────────────────────
    private byte[] GetSummaryCsvBytes()
    {
        DateTime scanFrom  = GetScanFrom();
        int cid            = GetCompanyId();
        string search      = GetSearch();
        string windowLabel = GetScanWindowLabel();

        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            using (SqlCommand cmd = new SqlCommand())
            {
                cmd.Connection     = conn;
                cmd.CommandTimeout = 300;
                string cmrFilter   = GetCmrFilter(search, cmd);

                cmd.CommandText = (@"
                    SELECT
                        a.text8                                                                                               AS [CMR],
                        COUNT(*)                                                                                               AS [Total Assets],
                        SUM(CASE WHEN CONVERT(date,a.lastinventoried)>=@ScanFrom THEN 1 ELSE 0 END)                           AS [Found (WIN)],
                        COUNT(*)-SUM(CASE WHEN CONVERT(date,a.lastinventoried)>=@ScanFrom THEN 1 ELSE 0 END)                  AS [Remaining],
                        CAST(SUM(CASE WHEN CONVERT(date,a.lastinventoried)>=@ScanFrom THEN 1 ELSE 0 END)*100.0/NULLIF(COUNT(*),0) AS DECIMAL(5,1)) AS [% Complete],
                        MAX(a.lastinventoried)                                                                                 AS [Last Scan Date],
                        STUFF((SELECT DISTINCT ', '+LOWER(LTRIM(RTRIM(v2.lastmodifiedby)))
                               FROM dbo.v_asset v2
                               WHERE v2.text8=a.text8
                                 AND NULLIF(RTRIM(v2.lastmodifiedby),'') IS NOT NULL
                                 AND CONVERT(date,v2.lastinventoried)>=@ScanFrom
                                 AND (@CId=0 OR v2.companyid=@CId)
                               FOR XML PATH('')),1,2,'')                                                                       AS [Scanners],
                        (SELECT TOP 1 v2.locationname
                         FROM dbo.v_asset v2
                         WHERE v2.text8=a.text8
                           AND CONVERT(date,v2.lastinventoried)>=@ScanFrom
                           AND (@CId=0 OR v2.companyid=@CId)
                         ORDER BY v2.lastinventoried DESC)                                                                     AS [Last Location Found]
                    FROM dbo.v_asset a
                    WHERE NULLIF(RTRIM(a.text8),'') IS NOT NULL
                      AND (@CId=0 OR a.companyid=@CId)
                      AND (" + cmrFilter + @")
                    GROUP BY a.text8
                    ORDER BY [% Complete] DESC, [Total Assets] DESC")
                    .Replace("WIN", windowLabel);

                cmd.Parameters.Add(new SqlParameter("@ScanFrom", SqlDbType.Date) { Value = scanFrom });
                cmd.Parameters.AddWithValue("@CId", cid);

                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    return DataTableToCsv(dt);
                }
            }
        }
    }

    private byte[] GetDetailCsvBytes()
    {
        DateTime scanFrom  = GetScanFrom();
        int cid            = GetCompanyId();
        string search      = GetSearch();
        string windowLabel = GetScanWindowLabel();

        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            using (SqlCommand cmd = new SqlCommand())
            {
                cmd.Connection     = conn;
                cmd.CommandTimeout = 300;
                string cmrFilter   = GetCmrFilter(search, cmd);

                cmd.CommandText = (@"
                    SELECT
                        ISNULL(a.text8,'Unassigned')   AS [CMR],
                        ISNULL(a.name,'')              AS [Asset Number],
                        ISNULL(a.description,'')       AS [Description],
                        ISNULL(a.text3,'')             AS [Serial #],
                        ISNULL(a.text4,'')             AS [Category],
                        ISNULL(a.disposalstatus,'')    AS [Use Status],
                        ISNULL(a.locationname,'')      AS [Last Known Location],
                        CASE WHEN CONVERT(date,a.lastinventoried)>=@ScanFrom THEN 'Yes' ELSE 'No' END AS [Scanned (WIN)],
                        a.lastinventoried              AS [Last Inventoried Date],
                        ISNULL(a.lastmodifiedby,'')    AS [Last Modified By]
                    FROM dbo.v_asset a
                    WHERE NULLIF(RTRIM(a.text8),'') IS NOT NULL
                      AND (@CId=0 OR a.companyid=@CId)
                      AND (" + cmrFilter + @")
                    ORDER BY a.text8, a.lastinventoried DESC")
                    .Replace("WIN", windowLabel);

                cmd.Parameters.Add(new SqlParameter("@ScanFrom", SqlDbType.Date) { Value = scanFrom });
                cmd.Parameters.AddWithValue("@CId", cid);

                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    return DataTableToCsv(dt);
                }
            }
        }
    }

    private byte[] DataTableToCsv(DataTable dt)
    {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < dt.Columns.Count; i++)
        {
            sb.Append("\"" + dt.Columns[i].ColumnName.Replace("\"", "\"\"") + "\"");
            if (i < dt.Columns.Count - 1) sb.Append(",");
        }
        sb.AppendLine();
        foreach (DataRow dr in dt.Rows)
        {
            for (int i = 0; i < dt.Columns.Count; i++)
            {
                sb.Append("\"" + dr[i].ToString().Replace("\"", "\"\"") + "\"");
                if (i < dt.Columns.Count - 1) sb.Append(",");
            }
            sb.AppendLine();
        }
        return Encoding.UTF8.GetBytes(sb.ToString());
    }
}
