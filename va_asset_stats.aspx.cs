using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Configuration;

namespace iDash
{
    public partial class va_asset_stats : System.Web.UI.Page
    {
        private string ConnStr = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
        private int _grandTotal = 0;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Auth check
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

            // Tile check
            var tiles = Session["IdashTileAccess"] as List<string>;
            string role = System.Convert.ToString(Session["IdashUserRole"]);
            if (!UserManager.CanAccessTile(role, tiles, "rpt_overview") &&
                !UserManager.CanAccessTile(role, tiles, "rpt_asset_master"))
            {
                Response.Redirect("index.aspx?err=access"); return;
            }

            // Handle JSON API requests from the new tab panels
            if (!string.IsNullOrEmpty(Request.QueryString["api"]))
            {
                HandleTabApiRequest();
                return;
            }

            if (!IsPostBack)
            {
                LoadCompanies();
                LoadStats();
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
                LitErr.Text = "<div class='err-msg'>Error loading companies: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        protected void DdlCompany_SelectedIndexChanged(object sender, EventArgs e) { LoadStats(); }

        protected void BtnExportExcel_Click(object sender, EventArgs e)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    string sql = @"SELECT 
                            name AS [Asset Name], description AS [Description],
                            text4 AS [Category], listvalue1 AS [Status],
                            locationname AS [Location], text8 AS [EIL/CMR],
                            text7 AS [Station Code], lastinventoried AS [Last Inventoried],
                            lastobservedtime AS [Last Observed], rfidtag AS [RFID Tag]
                        FROM dbo.v_asset" + GetWhereClause() + " ORDER BY name";

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        string attachment = "attachment; filename=AssetStats_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";
                        Response.ClearContent();
                        Response.AddHeader("content-disposition", attachment);
                        Response.ContentType = "text/csv";
                        StringBuilder sb = new StringBuilder();
                        for (int i = 0; i < dt.Columns.Count; i++)
                        {
                            sb.Append("\"" + dt.Columns[i].ColumnName + "\"");
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
                        Response.Write(sb.ToString());
                        Response.End();
                    }
                }
            }
            catch (System.Threading.ThreadAbortException) { }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err-msg'>Export error: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        private string GetWhereClause()
        {
            // Site the user picked from the dropdown
            string clause = "";
            if (DdlCompany.SelectedValue != "0" && !string.IsNullOrEmpty(DdlCompany.SelectedValue))
                clause = " WHERE companyid = " + DdlCompany.SelectedValue;

            // Enforce site-level access restriction
            string siteFilter = UserManager.BuildSiteFilter(Session, ConnStr);
            if (!string.IsNullOrEmpty(siteFilter))
            {
                if (string.IsNullOrEmpty(clause))
                    clause = " WHERE 1=1" + siteFilter;  // siteFilter starts with " AND ..."
                else
                    clause += siteFilter;
            }
            return clause;
        }

        private void LoadStats()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    LoadSummary(conn);
                    LoadMissingInfo(conn);
                    LoadInventoryAging(conn);
                    LoadUnseenAging(conn);
                    LoadMaintenance(conn);
                    LoadNewAssets(conn);
                    LoadLocationStats(conn);
                }
            }
            catch (Exception ex)
            {
                LitErr.Text = "<div class='err-msg'>Error loading statistics: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        private void LoadSummary(SqlConnection conn)
        {
            // Get status breakdown
            string sql = "SELECT listvalue1, COUNT(*) as Cnt FROM dbo.v_asset" + GetWhereClause() + " GROUP BY listvalue1 ORDER BY COUNT(*) DESC";
            DataTable dt = new DataTable();
            using (SqlDataAdapter da = new SqlDataAdapter(sql, conn))
                da.Fill(dt);

            string[] colors = { "#2EA8FF", "#10B981", "#8B5CF6", "#F59E0B", "#F97316", "#EF4444", "#EC4899", "#06B6D4" };

            // Merge rows that map to the same display name (e.g. NULL and '' both → "No Status Set")
            var merged = new List<KeyValuePair<string, int>>();
            foreach (DataRow dr in dt.Rows)
            {
                string raw = dr["listvalue1"].ToString();
                string status = (string.IsNullOrEmpty(raw) || raw.Equals("NULL", StringComparison.OrdinalIgnoreCase))
                    ? "No Status Set" : raw;
                int cnt = Convert.ToInt32(dr["Cnt"]);

                int existIdx = merged.FindIndex(kv => kv.Key.Equals(status, StringComparison.OrdinalIgnoreCase));
                if (existIdx >= 0)
                    merged[existIdx] = new KeyValuePair<string, int>(status, merged[existIdx].Value + cnt);
                else
                    merged.Add(new KeyValuePair<string, int>(status, cnt));
            }

            int total = merged.Sum(kv => kv.Value);
            _grandTotal = total;

            // Site sub-label
            LitSite.Text = DdlCompany.SelectedItem != null ? Server.HtmlEncode(DdlCompany.SelectedItem.Text) : "All Sites";

            int inUse = 0;
            int cIdx = 0;
            StringBuilder sbBar = new StringBuilder();
            StringBuilder sbLegend = new StringBuilder();

            foreach (var kv in merged)
            {
                string status = kv.Key;
                int cnt = kv.Value;
                if (status.Equals("In Use", StringComparison.OrdinalIgnoreCase) ||
                    status.Equals("IN USE", StringComparison.OrdinalIgnoreCase)) inUse += cnt;

                string color = colors[cIdx % colors.Length];
                double pct = total > 0 ? (double)cnt / total * 100.0 : 0;

                if (pct > 0)
                    sbBar.AppendFormat("<div class='status-bar-seg' style='width:{0:0.0}%;background:{1};' title='{2}: {3} ({4:0.0}%)'></div>", pct, color, Server.HtmlEncode(status), cnt.ToString("N0"), pct);

                sbLegend.AppendFormat(
                    "<div class='legend-chip'><span class='legend-dot' style='background:{0}'></span><span class='legend-name'>{1}</span><span class='legend-pct'>{2:N0}</span><span class='legend-pct-sub'>{3:0.0}%</span></div>",
                    color, Server.HtmlEncode(status), cnt, pct);
                cIdx++;
            }

            LitStatusBar.Text = sbBar.ToString();
            LitStatusLegend.Text = sbLegend.ToString();

            double inUsePctFinal = total > 0 ? (double)inUse / total * 100.0 : 0;

            // Inject KPI values as inline script so JS animator picks them up
            string kpiScript = string.Format(@"
<script>
document.addEventListener('DOMContentLoaded', function() {{
    animVal('kv-total',   {0}, 1000);
    animVal('kv-inuse',   {1}, 1000);
    document.getElementById('kv-inuse-pct').textContent  = '{2:0.0}%';
}});
</script>", total, inUse, inUsePctFinal);

            LitErr.Text += kpiScript;
        }

        private void LoadMissingInfo(SqlConnection conn)
        {
            string sql = @"SELECT 
                    SUM(CASE WHEN text8 IS NULL OR text8 = '' THEN 1 ELSE 0 END) as NoEIL,
                    SUM(CASE WHEN locationname IS NULL OR locationname = '' THEN 1 ELSE 0 END) as NoLoc,
                    SUM(CASE WHEN listvalue1 IS NULL OR listvalue1 = '' THEN 1 ELSE 0 END) as NoStatus,
                    SUM(CASE WHEN listvalue1 = 'Turned In' AND (text8 IS NULL OR LTRIM(RTRIM(text8)) = '') THEN 1 ELSE 0 END) as TurnedInNoCMR,
                    SUM(CASE WHEN text8 IS NOT NULL AND LEFT(LTRIM(text8), 2) = '78' THEN 1 ELSE 0 END) as OitAssets,
                    COUNT(*) as Total
                FROM dbo.v_asset" + GetWhereClause();

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                if (rdr.Read())
                {
                    int noEil         = GetInt(rdr["NoEIL"]);
                    int noLoc         = GetInt(rdr["NoLoc"]);
                    int noStatus      = GetInt(rdr["NoStatus"]);
                    int turnedInNoCmr = GetInt(rdr["TurnedInNoCMR"]);
                    int oitAssets     = GetInt(rdr["OitAssets"]);
                    int total         = GetInt(rdr["Total"]);

                    double eilPct        = total > 0 ? (double)noEil         / total * 100.0 : 0;
                    double locPct        = total > 0 ? (double)noLoc          / total * 100.0 : 0;
                    double tiNoCmrPct    = total > 0 ? (double)turnedInNoCmr  / total * 100.0 : 0;

                    LitMissingEIL.Text = string.Format(
                        "<span class='badge {0}'>{1:N0}</span><span style='color:var(--text-accent);font-size:12px;margin-left:6px'>{2:0.0}% of assets</span>",
                        noEil > 0 ? "b-yellow" : "b-green", noEil, eilPct);

                    LitMissingLoc.Text = string.Format(
                        "<span class='badge {0}'>{1:N0}</span><span style='color:var(--text-accent);font-size:12px;margin-left:6px'>{2:0.0}% of assets</span>",
                        noLoc > 0 ? "b-yellow" : "b-green", noLoc, locPct);

                    LitMissingStatus.Text = string.Format(
                        "<span class='badge {0}'>{1:N0}</span>",
                        noStatus > 0 ? "b-red" : "b-green", noStatus);

                    LitTurnedInNoCMR.Text = string.Format(
                        "<span class='badge {0}'>{1:N0}</span><span style='color:var(--text-accent);font-size:12px;margin-left:6px'>{2:0.0}% of assets</span>",
                        turnedInNoCmr > 0 ? "b-orange" : "b-green", turnedInNoCmr, tiNoCmrPct);

                    // OIT Assets (CMR starting with 78)
                    double oitPct = total > 0 ? (double)oitAssets / total * 100.0 : 0;
                    LitOitAssets.Text = string.Format(
                        "<span class='legend-pct'>{0:N0}</span><span class='legend-pct-sub'>{1:0.0}%</span>",
                        oitAssets, oitPct);

                    // Also inject missing EIL into KPI card + overdue placeholder (overdue filled by aging below)
                    string kpiScript2 = string.Format(@"<script>
document.addEventListener('DOMContentLoaded', function() {{
    animVal('kv-noeil', {0}, 1000);
    document.getElementById('kv-noeil-pct').textContent = '{1:0.0}% of assets';
}});
</script>", noEil, eilPct);
                    LitErr.Text += kpiScript2;
                }
            }
        }

        private void LoadInventoryAging(SqlConnection conn)
        {
            string sql = @"SELECT
                    SUM(CASE WHEN lastinventoried >= DATEADD(month,-1,  GETDATE()) THEN 1 ELSE 0 END) as M1,
                    SUM(CASE WHEN lastinventoried <  DATEADD(month,-1,  GETDATE()) AND lastinventoried >= DATEADD(month,-3, GETDATE()) THEN 1 ELSE 0 END) as M3,
                    SUM(CASE WHEN lastinventoried <  DATEADD(month,-3,  GETDATE()) AND lastinventoried >= DATEADD(month,-6, GETDATE()) THEN 1 ELSE 0 END) as M6,
                    SUM(CASE WHEN lastinventoried <  DATEADD(month,-6,  GETDATE()) AND lastinventoried >= DATEADD(month,-12,GETDATE()) THEN 1 ELSE 0 END) as M12,
                    SUM(CASE WHEN lastinventoried <  DATEADD(month,-12, GETDATE()) OR lastinventoried IS NULL THEN 1 ELSE 0 END) as Overdue,
                    COUNT(*) as Total
                FROM dbo.v_asset" + GetWhereClause();

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                if (rdr.Read())
                {
                    int ov = GetInt(rdr["Overdue"]);
                    int m1 = GetInt(rdr["M1"]);
                    int m3 = GetInt(rdr["M3"]);
                    int m6 = GetInt(rdr["M6"]);
                    int m12= GetInt(rdr["M12"]);
                    int total = GetInt(rdr["Total"]);

                    double ovPct = total > 0 ? (double)ov / total * 100.0 : 0;

                    LitInvM1.Text      = Pct("b-green",  m1,  total, "within 1 mo");
                    LitInvM3.Text      = Pct("b-blue",   m3,  total, "1-3 mo");
                    LitInvM6.Text      = Pct("b-orange",  m6,  total, "3-6 mo");
                    LitInvM12.Text     = Pct("b-yellow", m12, total, "6-12 mo");
                    LitInvOverdue.Text = Pct("b-red",    ov,  total, "overdue or never inventoried");

                    // KPI overdue card
                    string kpiScript3 = string.Format(@"<script>
document.addEventListener('DOMContentLoaded', function() {{
    animVal('kv-overdue', {0}, 1000);
    document.getElementById('kv-overdue-pct').textContent = '{1:0.0}% of assets';
}});
</script>", ov, ovPct);
                    LitErr.Text += kpiScript3;
                }
            }
        }

        private void LoadUnseenAging(SqlConnection conn)
        {
            string sql = @"SELECT
                    SUM(CASE WHEN lastobservedtime >= DATEADD(month,-1, GETDATE()) THEN 1 ELSE 0 END) as M1,
                    SUM(CASE WHEN lastobservedtime <  DATEADD(month,-1, GETDATE()) AND lastobservedtime >= DATEADD(month,-3, GETDATE()) THEN 1 ELSE 0 END) as M3,
                    SUM(CASE WHEN lastobservedtime <  DATEADD(month,-3, GETDATE()) AND lastobservedtime >= DATEADD(month,-6, GETDATE()) THEN 1 ELSE 0 END) as M6
                FROM dbo.v_asset" + GetWhereClause();

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                if (rdr.Read())
                {
                    LitUnseen1.Text = string.Format("<span class='badge b-green'>{0:N0}</span>", GetInt(rdr["M1"]));
                    LitUnseen3.Text = string.Format("<span class='badge b-yellow'>{0:N0}</span>", GetInt(rdr["M3"]));
                    LitUnseen6.Text = string.Format("<span class='badge b-orange'>{0:N0}</span>", GetInt(rdr["M6"]));
                }
            }
        }

        private void LoadMaintenance(SqlConnection conn)
        {
            string sql = @"SELECT 
                    SUM(CASE WHEN nextmaintenance < GETDATE() THEN 1 ELSE 0 END) as Overdue,
                    SUM(CASE WHEN nextmaintenance >= GETDATE() AND nextmaintenance < DATEADD(month,1,GETDATE()) THEN 1 ELSE 0 END) as NextMonth
                FROM dbo.v_asset" + GetWhereClause();

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                if (rdr.Read())
                {
                    int ov = GetInt(rdr["Overdue"]);
                    int nm = GetInt(rdr["NextMonth"]);
                    LitMaintOv.Text = string.Format("<span class='badge {0}'>{1:N0}</span>", ov > 0 ? "b-red" : "b-green", ov);
                    LitMaintNM.Text = string.Format("<span class='badge b-blue'>{0:N0}</span>", nm);
                }
            }
        }

        private void LoadNewAssets(SqlConnection conn)
        {
            string sql = @"SELECT 
                    SUM(CASE WHEN created >= DATEADD(day,  -7,  GETDATE()) THEN 1 ELSE 0 END) as W1,
                    SUM(CASE WHEN created >= DATEADD(month,-1,  GETDATE()) THEN 1 ELSE 0 END) as M1,
                    SUM(CASE WHEN created >= DATEADD(month,-3,  GETDATE()) THEN 1 ELSE 0 END) as M3,
                    SUM(CASE WHEN created >= DATEADD(year, -1,  GETDATE()) THEN 1 ELSE 0 END) as Y1
                FROM dbo.v_asset" + GetWhereClause();

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                if (rdr.Read())
                {
                    int m1 = GetInt(rdr["M1"]);
                    LitNewAssets.Text = string.Format(
                        "<span class='badge b-green'>Wk: {0:N0}</span>" +
                        "<span class='badge b-blue'>Mo: {1:N0}</span>" +
                        "<span class='badge b-yellow'>3Mo: {2:N0}</span>" +
                        "<span class='badge b-orange'>Yr: {3:N0}</span>",
                        GetInt(rdr["W1"]), m1, GetInt(rdr["M3"]), GetInt(rdr["Y1"]));

                    // KPI card for "Added This Month"
                    string kpiScript4 = string.Format(@"<script>
document.addEventListener('DOMContentLoaded', function() {{
    animVal('kv-new', {0}, 1000);
}});
</script>", m1);
                    LitErr.Text += kpiScript4;
                }
            }
        }


        // Helper: badge with count + percentage
        private string Pct(string cls, int count, int total, string label = "")
        {
            double pct = total > 0 ? (double)count / total * 100.0 : 0;
            string labelHtml = !string.IsNullOrEmpty(label)
                ? string.Format("<span style='color:var(--text-accent);font-size:11px;margin-left:4px;'>({0:0.0}% of total &mdash; {1})</span>", pct, label)
                : string.Format("<span style='color:var(--text-accent);font-size:12px;margin-left:6px'>{0:0.0}%</span>", pct);
            return string.Format("<span class='badge {0}'>{1:N0}</span>{2}", cls, count, labelHtml);
        }

        private int GetInt(object val)
        {
            if (val == DBNull.Value || val == null) return 0;
            return Convert.ToInt32(val);
        }

        // --------------------------------------------------------------------
        //  TAB API ROUTER
        // --------------------------------------------------------------------
        private void HandleTabApiRequest()
        {
            Response.Clear();
            Response.ContentType = "application/json";
            string action    = Request.QueryString["api"]    ?? "";
            string siteId    = Request.QueryString["siteid"] ?? "0";
            string drillType = Request.QueryString["type"]   ?? "";
            try
            {
                switch (action)
                {
                    case "dqstats":      Response.Write(GetDqStatsJson(siteId));            break;
                    case "dqdrill":      Response.Write(GetDqDrillJson(siteId, drillType));  break;
                    case "analytics":    Response.Write(GetAnalyticsJson(siteId));           break;
                    case "staleimport":  HandleStaleImport(siteId);                          break;
                    default:             Response.Write("{\"error\":\"unknown api\"}");   break;
                }
            }
            catch (Exception ex)
            {
                Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            }
            finally { Response.End(); }
        }

        private string BuildSiteFilter(string alias, string siteId)
        {
            string filter = "";
            // Specific site selected by user
            if (siteId != "0" && !string.IsNullOrEmpty(siteId))
            {
                int cid; if (!int.TryParse(siteId, out cid)) return "";
                string col = string.IsNullOrEmpty(alias) ? "companyid" : alias + ".companyid";
                filter = " AND " + col + " = " + cid;
            }
            // Enforce site-level access restriction
            string siteAccess = UserManager.BuildSiteFilter(Session, ConnStr, alias);
            if (!string.IsNullOrEmpty(siteAccess))
                filter += siteAccess;
            return filter;
        }

        // -- DATA QUALITY STATS ----------------------------------------------
        private string GetDqStatsJson(string siteId)
        {
            string sf = BuildSiteFilter("a", siteId);
            StringBuilder json = new StringBuilder("{");

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string totalSql   = "SELECT COUNT(*) FROM dbo.v_asset a WHERE 1=1" + sf;
                string noEilSql   = "SELECT COUNT(*) FROM dbo.v_asset a WHERE (a.text8 IS NULL OR LTRIM(RTRIM(a.text8))='')" + sf;
                string noLocSql   = "SELECT COUNT(*) FROM dbo.v_asset a WHERE a.locationid IS NULL" + sf;
                string staleSql   = "SELECT COUNT(*) FROM dbo.v_asset a WHERE a.created IS NULL AND a.lastobservedtime IS NULL" + sf;

                json.AppendFormat("\"Total\":{0},",  Scalar(totalSql, conn));
                json.AppendFormat("\"NoEIL\":{0},",  Scalar(noEilSql, conn));
                json.AppendFormat("\"NoLoc\":{0},",  Scalar(noLocSql, conn));
                json.AppendFormat("\"StaleImport\":{0},", Scalar(staleSql, conn));

                // Per-location quality score
                string locSql = @"
                    SELECT TOP 30
                        ISNULL(a.locationname,'No Location') as Location,
                        COUNT(*) as Total,
                        SUM(CASE WHEN a.text8 IS NOT NULL AND LTRIM(RTRIM(a.text8))<>'' THEN 1 ELSE 0 END) as HasEIL,
                        SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as Tagged,
                        SUM(CASE WHEN a.listvalue1='In Use' THEN 1 ELSE 0 END) as InUse,
                        CAST((
                            SUM(CASE WHEN a.text8 IS NOT NULL AND LTRIM(RTRIM(a.text8))<>'' THEN 1.0 ELSE 0 END)/COUNT(*)*33
                          + SUM(CASE WHEN a.text18='1' THEN 1.0 ELSE 0 END)/COUNT(*)*33
                          + SUM(CASE WHEN a.listvalue1='In Use' THEN 1.0 ELSE 0 END)/COUNT(*)*34
                        ) as int) as QualityScore
                    FROM dbo.v_asset a
                    WHERE 1=1" + sf + @"
                    GROUP BY a.locationname
                    HAVING COUNT(*) >= 5
                    ORDER BY QualityScore DESC";

                json.Append("\"LocQuality\":");
                json.Append(ReaderToJsonArr(locSql, conn));
            }
            json.Append("}");
            return json.ToString();
        }

        // -- DATA QUALITY DRILL ----------------------------------------------
        private string GetDqDrillJson(string siteId, string drillType)
        {
            string sf = BuildSiteFilter("a", siteId);
            string sql;
            if (drillType == "noeil")
                sql = @"SELECT TOP 50 a.name AS Name, a.text8 AS EIL, a.description AS Description,
                            a.locationname AS Location, a.lastinventoried AS LastInventoried
                        FROM dbo.v_asset a WHERE (a.text8 IS NULL OR LTRIM(RTRIM(a.text8))='')" + sf + " ORDER BY a.name";
            else
                sql = @"SELECT TOP 50 a.name AS Name, a.locationname AS Location, a.text8 AS EIL,
                            a.listvalue1 AS Status, a.description AS Description
                        FROM dbo.v_asset a WHERE a.locationid IS NULL" + sf + " ORDER BY a.name";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                using (SqlDataReader rdr = cmd.ExecuteReader())
                    return ReaderToJsonArr2(rdr);
            }
        }

        // -- STALE IMPORT ---------------------------------------------------
        private void HandleStaleImport(string siteId)
        {
            string sf      = BuildSiteFilter("a", siteId);
            string export  = Request.QueryString["export"] ?? "";
            int    page    = 1; int.TryParse(Request.QueryString["page"]  ?? "1", out page);
            int    ps      = 200; int.TryParse(Request.QueryString["ps"]  ?? "200", out ps);
            if (ps < 1 || ps > 500) ps = 200;
            if (page < 1) page = 1;

            string baseWhere = " WHERE a.created IS NULL AND a.lastobservedtime IS NULL" + sf;

            string selectCols = @"
                ISNULL(a.name,'(no tag)') AS AssetTag,
                ISNULL(a.description,'')  AS Description,
                ISNULL(a.listvalue1,'—')  AS Status,
                ISNULL(a.text8,'')        AS CMR,
                ISNULL(a.locationname,'') AS Location,
                CASE WHEN a.lastinventoried IS NULL THEN 'Never'
                     WHEN YEAR(a.lastinventoried) < 1990 THEN 'Unknown (<1990)'
                     ELSE FORMAT(a.lastinventoried,'yyyy-MM-dd') END AS LastInventoried,
                CASE WHEN a.name LIKE '512%' THEN '512 Import' ELSE 'Legacy EE Record' END AS NameType";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                if (export == "1")
                {
                    // Full CSV dump
                    string csvSql = "SELECT " + selectCols + " FROM dbo.v_asset a" + baseWhere + " ORDER BY a.listvalue1, a.name";
                    Response.ClearContent();
                    Response.AddHeader("content-disposition", "attachment; filename=StaleImportRecords_" + DateTime.Now.ToString("yyyyMMdd") + ".csv");
                    Response.ContentType = "text/csv";
                    StringBuilder sb = new StringBuilder();
                    sb.AppendLine("\"Asset Tag\",\"Description\",\"Status\",\"CMR/EIL\",\"Location\",\"Last Inventoried\",\"Origin\"");
                    using (SqlCommand cmd = new SqlCommand(csvSql, conn))
                    {
                        cmd.CommandTimeout = 180;
                        using (SqlDataReader rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                for (int i = 0; i < rdr.FieldCount; i++)
                                {
                                    if (i > 0) sb.Append(",");
                                    sb.Append("\"").Append(rdr[i].ToString().Replace("\"", "\"\"")).Append("\"");
                                }
                                sb.AppendLine();
                            }
                        }
                    }
                    Response.Write(sb.ToString());
                    return; // Response.End() called in finally
                }

                // Paginated JSON
                int total  = Scalar("SELECT COUNT(*) FROM dbo.v_asset a" + baseWhere, conn);
                int offset = (page - 1) * ps;
                string pageSql = "SELECT " + selectCols +
                    " FROM dbo.v_asset a" + baseWhere +
                    " ORDER BY a.listvalue1, a.name" +
                    " OFFSET " + offset + " ROWS FETCH NEXT " + ps + " ROWS ONLY";

                StringBuilder json = new StringBuilder();
                json.AppendFormat("{{\"Total\":{0},\"Page\":{1},\"PageSize\":{2},\"Rows\":", total, page, ps);
                json.Append(ReaderToJsonArr(pageSql, conn));
                json.Append("}");
                Response.Write(json.ToString());
            }
        }



        // -- ANALYTICS -------------------------------------------------------
        private string GetAnalyticsJson(string siteId)
        {
            string sf = BuildSiteFilter("a", siteId);
            StringBuilder json = new StringBuilder("{");

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Never inventoried
                int neverCount = Scalar("SELECT COUNT(*) FROM dbo.v_asset a WHERE a.lastinventoried IS NULL" + sf, conn);
                int totalCount = Scalar("SELECT COUNT(*) FROM dbo.v_asset a WHERE 1=1" + sf, conn);
                double neverPct = totalCount > 0 ? Math.Round((double)neverCount / totalCount * 100, 1) : 0;
                json.AppendFormat("\"NeverInventoried\":{0},", neverCount);
                json.AppendFormat("\"NeverPct\":\"{0}\",", neverPct);

                // Category breakdown (text4)
                string catSql = @"SELECT TOP 15 ISNULL(a.text4,'Uncategorized') as label, COUNT(*) as count
                    FROM dbo.v_asset a WHERE 1=1" + sf + " GROUP BY a.text4 ORDER BY COUNT(*) DESC";
                json.Append("\"Categories\":"); json.Append(ReaderToJsonArr(catSql, conn)); json.Append(",");

                // Scan velocity (last 12 months)
                string velSql = @"SELECT FORMAT(a.lastinventoried,'yyyy-MM') as label, COUNT(*) as count
                    FROM dbo.v_asset a WHERE a.lastinventoried >= DATEADD(month,-12,GETDATE())" + sf +
                    " GROUP BY FORMAT(a.lastinventoried,'yyyy-MM') ORDER BY label ASC";
                json.Append("\"Velocity\":"); json.Append(ReaderToJsonArr(velSql, conn)); json.Append(",");

                // Station code table
                string stSql = @"SELECT TOP 30 ISNULL(a.text7,'(No Station)') as Station,
                    COUNT(*) as Total,
                    SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as Tagged,
                    SUM(CASE WHEN ISNULL(a.text18,'')<>'1' THEN 1 ELSE 0 END) as Untagged
                FROM dbo.v_asset a WHERE a.text7 IS NOT NULL" + sf +
                    " GROUP BY a.text7 ORDER BY COUNT(*) DESC";
                json.Append("\"Stations\":"); json.Append(ReaderToJsonArr(stSql, conn)); json.Append(",");

                // Tag date vs inventory delta
                string deltaSql = @"SELECT
                    CASE
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) < 0  THEN 'Before tag date'
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) = 0  THEN 'Same day'
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) <= 30 THEN 'Within 30 days'
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) <= 90 THEN '30-90 days'
                        ELSE 'Over 90 days'
                    END as label,
                    COUNT(*) as count
                FROM dbo.v_asset a
                WHERE a.text18='1' AND a.text17 IS NOT NULL AND a.lastinventoried IS NOT NULL" + sf + @"
                GROUP BY CASE
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) < 0  THEN 'Before tag date'
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) = 0  THEN 'Same day'
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) <= 30 THEN 'Within 30 days'
                        WHEN DATEDIFF(day, TRY_CONVERT(date,a.text17), a.lastinventoried) <= 90 THEN '30-90 days'
                        ELSE 'Over 90 days'
                    END";
                json.Append("\"TagDelta\":"); json.Append(ReaderToJsonArr(deltaSql, conn)); json.Append(",");

                // Top locations by tagging completion
                string topLocSql = @"SELECT TOP 20
                    ISNULL(a.locationname,'Unassigned') as Location,
                    COUNT(*) as Total,
                    SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as Tagged
                FROM dbo.v_asset a WHERE 1=1" + sf +
                    " GROUP BY a.locationname HAVING COUNT(*) >= 5 ORDER BY SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END)*100/COUNT(*) DESC";
                json.Append("\"TopLocations\":"); json.Append(ReaderToJsonArr(topLocSql, conn));
            }
            json.Append("}");
            return json.ToString();
        }

        // -- JSON HELPERS -----------------------------------------------------
        private int Scalar(string sql, SqlConnection conn)
        {
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                object result = cmd.ExecuteScalar();
                return (result == null || result == DBNull.Value) ? 0 : Convert.ToInt32(result);
            }
        }

        private string ReaderToJsonArr(string sql, SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder("[");
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    bool first = true;
                    while (rdr.Read())
                    {
                        if (!first) sb.Append(",");
                        sb.Append("{");
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            if (i > 0) sb.Append(",");
                            sb.Append("\"").Append(rdr.GetName(i)).Append("\":");
                            object val = rdr.GetValue(i);
                            if (val == DBNull.Value) sb.Append("null");
                            else if (val is string) sb.Append("\"").Append(JsonSafe(val.ToString())).Append("\"");
                            else sb.Append(val.ToString());
                        }
                        sb.Append("}");
                        first = false;
                    }
                }
            }
            sb.Append("]");
            return sb.ToString();
        }

        private string ReaderToJsonArr2(SqlDataReader rdr)
        {
            StringBuilder sb = new StringBuilder("[");
            bool first = true;
            while (rdr.Read())
            {
                if (!first) sb.Append(",");
                sb.Append("{");
                for (int i = 0; i < rdr.FieldCount; i++)
                {
                    if (i > 0) sb.Append(",");
                    sb.Append("\"").Append(rdr.GetName(i)).Append("\":");
                    object val = rdr.GetValue(i);
                    if (val == DBNull.Value) sb.Append("null");
                    else if (val is string) sb.Append("\"").Append(JsonSafe(val.ToString())).Append("\"");
                    else sb.Append("\"").Append(JsonSafe(val.ToString())).Append("\"");
                }
                sb.Append("}");
                first = false;
            }
            sb.Append("]");
            return sb.ToString();
        }

        private void LoadLocationStats(SqlConnection conn)
        {
            string sql = @"SELECT TOP 200
                    locationname as Location,
                    COUNT(*) as Total,
                    SUM(CASE WHEN lastinventoried < DATEADD(month,-12,GETDATE()) THEN 1 ELSE 0 END) as Overdue,
                    SUM(CASE WHEN lastinventoried >= DATEADD(month,-1,GETDATE()) THEN 1 ELSE 0 END) as M1,
                    SUM(CASE WHEN lastinventoried < DATEADD(month,-1,GETDATE()) AND lastinventoried >= DATEADD(month,-3,GETDATE()) THEN 1 ELSE 0 END) as M3,
                    SUM(CASE WHEN lastinventoried < DATEADD(month,-3,GETDATE()) AND lastinventoried >= DATEADD(month,-6,GETDATE()) THEN 1 ELSE 0 END) as M6,
                    SUM(CASE WHEN lastinventoried < DATEADD(month,-6,GETDATE()) AND lastinventoried >= DATEADD(month,-12,GETDATE()) THEN 1 ELSE 0 END) as M12
                FROM dbo.v_asset" + GetWhereClause() + @"
                GROUP BY locationname
                ORDER BY COUNT(*) DESC";

            DataTable dt = new DataTable();
            using (SqlDataAdapter da = new SqlDataAdapter(sql, conn))
                da.Fill(dt);

            // Serialize to JSON for client-side rendering (filterable + clickable table)
            var sb = new System.Text.StringBuilder("<script>var LOC_STATS_DATA=[");
            bool first = true;
            foreach (DataRow row in dt.Rows)
            {
                if (!first) sb.Append(",");
                string loc = (row["Location"] != DBNull.Value ? row["Location"].ToString() : "").Replace("\\", "\\\\").Replace("\"", "\\\"");
                sb.AppendFormat("{{\"loc\":\"{0}\",\"total\":{1},\"overdue\":{2},\"m1\":{3},\"m3\":{4},\"m6\":{5},\"m12\":{6}}}",
                    loc,
                    row["Total"] != DBNull.Value ? row["Total"] : 0,
                    row["Overdue"] != DBNull.Value ? row["Overdue"] : 0,
                    row["M1"] != DBNull.Value ? row["M1"] : 0,
                    row["M3"] != DBNull.Value ? row["M3"] : 0,
                    row["M6"] != DBNull.Value ? row["M6"] : 0,
                    row["M12"] != DBNull.Value ? row["M12"] : 0);
                first = false;
            }
            sb.Append("];// data ready - renderLocStatsTable called from bottom script</script>");
            LitLocStatsJson.Text = sb.ToString();
        }

        private string JsonSafe(string s)
        {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
        }
    }
}
