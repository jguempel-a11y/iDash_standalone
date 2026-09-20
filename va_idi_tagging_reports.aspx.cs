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
    public partial class va_idi_tagging_reports : System.Web.UI.Page
    {
        private string ConnStr = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Auth check
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

            // Tile check
            var tiles = Session["IdashTileAccess"] as List<string>;
            string role = System.Convert.ToString(Session["IdashUserRole"]);
            if (!UserManager.CanAccessTile(role, tiles, "rpt_tagging_detail"))
            {
                Response.Redirect("index.aspx?err=access"); return;
            }

            if (!string.IsNullOrEmpty(Request.QueryString["api"]))
            {
                HandleApiRequest();
                return;
            }

            if (!IsPostBack)
            {
                LoadCompanies();
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
                        DdlSite.Items.Clear();
                        DdlSite.Items.Insert(0, new ListItem("-- No sites assigned --", "0"));
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
                        DdlSite.DataSource = rdr;
                        DdlSite.DataTextField = "name";
                        DdlSite.DataValueField = "id";
                        DdlSite.DataBind();
                    }
                    if (DdlSite.Items.Count > 1 || allowedIds == null)
                        DdlSite.Items.Insert(0, new ListItem("All Sites (Global)", "0"));
                    else if (DdlSite.Items.Count == 1)
                        DdlSite.SelectedIndex = 0;
                }
            }
            catch (Exception) { }
        }

        private void HandleApiRequest()
        {
            Response.Clear();
            Response.ContentType = "application/json";
            string action = Request.QueryString["api"];
            string range = Request.QueryString["range"] ?? "all";
            string siteId = Request.QueryString["siteid"] ?? "0";
            
            try 
            {
                if (action == "dashboardstats")
                {
                    Response.Write(GetDashboardStatsJson(range, siteId));
                }
            } 
            catch (Exception ex)
            {
                Response.Write("{\"error\": \"" + Server.HtmlEncode(ex.Message.Replace("\"", "'").Replace("\\", "\\\\")) + "\"}");
            }
            finally
            {
                Response.End();
            }
        }

        private string GetDashboardStatsJson(string range, string siteId)
        {
            string dateFilter = "";
            if (range == "today") dateFilter = " AND CONVERT(date, a.lastinventoried) = CONVERT(date, GETDATE()) ";
            else if (range == "week") dateFilter = " AND a.lastinventoried >= DATEADD(day, -7, GETDATE()) ";
            else if (range == "month") dateFilter = " AND a.lastinventoried >= DATEADD(month, -1, GETDATE()) ";
            
            string siteFilter = "";
            if (siteId != "0" && !string.IsNullOrEmpty(siteId)) {
                int cid;
                if (int.TryParse(siteId, out cid)) {
                    siteFilter = " AND a.companyid = " + cid + " ";
                }
            }

            StringBuilder json = new StringBuilder();
            json.Append("{");

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // 1. KPIs
                string kpiSql = @"
                    SELECT 
                        COUNT(*) as GrandTotalAssets,
                        SUM(CASE WHEN text18 = '1' THEN 1 ELSE 0 END) as TotalTagged,
                        SUM(CASE WHEN ISNULL(text18, '') <> '1' THEN 1 ELSE 0 END) as TotalUntagged,
                        SUM(CASE WHEN text18 = '1' AND ISNULL(listvalue1, '') NOT LIKE '%IN USE%' THEN 1 ELSE 0 END) as TaggedNotInUse,
                        COUNT(DISTINCT CASE WHEN text18 = '1' THEN text19 END) as TotalTagTypes,
                        COUNT(DISTINCT CASE WHEN text18 = '1' THEN text13 END) as TotalEmployees,
                        COUNT(DISTINCT CASE WHEN text18 = '1' THEN locationname END) as TotalLocations,
                        COUNT(DISTINCT CASE WHEN text18 = '1' THEN text8 END) as TotalCMRs
                    FROM dbo.v_asset a
                    WHERE 1=1 " + siteFilter + dateFilter;
                
                // For 'Total Assets' in site (unfiltered by date so they see true total vs Tagged in period)
                string totalSql = @"
                    SELECT 
                        COUNT(*) as AbsoluteTotal,
                        COUNT(DISTINCT locationname) as AbsoluteLocations,
                        COUNT(DISTINCT text8) as AbsoluteCMRs
                    FROM dbo.v_asset a
                    WHERE 1=1 " + siteFilter;

                string absoluteTotal = "0";
                string absoluteLocations = "0";
                string absoluteCMRs = "0";

                using (SqlCommand cmdTotal = new SqlCommand(totalSql, conn)) {
                    using (SqlDataReader rx = cmdTotal.ExecuteReader()) {
                        if (rx.Read()) {
                            absoluteTotal = rx["AbsoluteTotal"].ToString();
                            absoluteLocations = rx["AbsoluteLocations"].ToString();
                            absoluteCMRs = rx["AbsoluteCMRs"].ToString();
                        }
                    }
                }

                using (SqlCommand cmd = new SqlCommand(kpiSql, conn))
                {
                    cmd.CommandTimeout = 300;
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            json.Append("\"kpis\": {");
                            json.AppendFormat("\"TotalTagged\": {0},", rdr["TotalTagged"] == DBNull.Value ? "0" : rdr["TotalTagged"].ToString());
                            json.AppendFormat("\"TotalUntagged\": {0},", rdr["TotalUntagged"] == DBNull.Value ? "0" : rdr["TotalUntagged"].ToString());
                            json.AppendFormat("\"TaggedNotInUse\": {0},", rdr["TaggedNotInUse"] == DBNull.Value ? "0" : rdr["TaggedNotInUse"].ToString());
                            json.AppendFormat("\"GrandTotalAssets\": {0},", absoluteTotal);
                            json.AppendFormat("\"AbsoluteLocations\": {0},", absoluteLocations);
                            json.AppendFormat("\"AbsoluteCMRs\": {0},", absoluteCMRs);
                            json.AppendFormat("\"TotalCMRs\": {0},", rdr["TotalCMRs"] == DBNull.Value ? "0" : rdr["TotalCMRs"].ToString());
                            json.AppendFormat("\"TotalTagTypes\": {0},", rdr["TotalTagTypes"] == DBNull.Value ? "0" : rdr["TotalTagTypes"].ToString());
                            json.AppendFormat("\"TotalEmployees\": {0},", rdr["TotalEmployees"] == DBNull.Value ? "0" : rdr["TotalEmployees"].ToString());
                            json.AppendFormat("\"TotalLocations\": {0}", rdr["TotalLocations"] == DBNull.Value ? "0" : rdr["TotalLocations"].ToString());
                            json.Append("},");
                        }
                    }
                }

                // 2. Locations Bar Chart Data
                string locationsSql = @"
                    SELECT TOP 10 ISNULL(locationname, 'Unassigned') as Name, COUNT(*) as Value
                    FROM dbo.v_asset a
                    WHERE text18 = '1' " + siteFilter + dateFilter + @"
                    GROUP BY locationname
                    ORDER BY Value DESC";

                json.Append("\"locations\": ");
                json.Append(QueryToJsonArray(locationsSql, conn));
                json.Append(",");

                // 3. Tag Types Pie Chart Data
                string tagTypesSql = @"
                    SELECT TOP 10 ISNULL(text19, 'Unknown') as Name, COUNT(*) as Value
                    FROM dbo.v_asset a
                    WHERE text18 = '1' " + siteFilter + dateFilter + @"
                    GROUP BY text19
                    ORDER BY Value DESC";

                json.Append("\"tagTypes\": ");
                json.Append(QueryToJsonArray(tagTypesSql, conn));
                json.Append(",");

                // 4. Time Series Trend Data
                string trendSql = @"
                    SELECT TOP 10 CONVERT(varchar(10), a.lastinventoried, 120) as Name, COUNT(*) as Value
                    FROM dbo.v_asset a
                    WHERE text18 = '1' AND a.lastinventoried IS NOT NULL " + siteFilter + @"
                    GROUP BY CONVERT(varchar(10), a.lastinventoried, 120)
                    ORDER BY Name ASC";

                json.Append("\"trend\": ");
                json.Append(QueryToJsonArray(trendSql, conn));
                json.Append(",");

                // 5. Raw Drill-Down Data (Top 100)
                string rawSql = @"
                    SELECT TOP 100 
                        ISNULL(a.name, 'Unknown') as AssetName,
                        ISNULL(a.locationname, 'Unassigned') as Location,
                        ISNULL(a.text19, 'Unassigned') as TagType,
                        ISNULL(a.text13, 'Unknown User') as UserId,
                        CONVERT(varchar(20), a.lastinventoried, 120) as DateTagged
                    FROM dbo.v_asset a
                    WHERE text18 = '1' " + siteFilter + dateFilter + @"
                    ORDER BY a.lastinventoried DESC";

                json.Append("\"drilldown\": ");
                json.Append(QueryToComplexJsonArray(rawSql, conn));

            }

            json.Append("}");
            return json.ToString();
        }

        private string QueryToComplexJsonArray(string sql, SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("[");
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 300;
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    bool firstRow = true;
                    while (rdr.Read())
                    {
                        if (!firstRow) sb.Append(",");
                        sb.Append("{");
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            if (i > 0) sb.Append(",");
                            string colName = rdr.GetName(i);
                            string val = rdr[i] == DBNull.Value ? "" : rdr[i].ToString().Replace("\"", "\\\"").Replace("\\", "\\\\");
                            sb.AppendFormat("\"{0}\": \"{1}\"", colName, val);
                        }
                        sb.Append("}");
                        firstRow = false;
                    }
                }
            }
            sb.Append("]");
            return sb.ToString();
        }

        private string QueryToJsonArray(string sql, SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("[");
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 300;
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    bool firstRow = true;
                    while (rdr.Read())
                    {
                        if (!firstRow) sb.Append(",");
                        
                        string name = rdr["Name"] == DBNull.Value ? "Unknown" : rdr["Name"].ToString().Replace("\"", "\\\"").Replace("\\", "\\\\");
                        string val = rdr["Value"] == DBNull.Value ? "0" : rdr["Value"].ToString();

                        sb.Append("{");
                        sb.AppendFormat("\"label\": \"{0}\",", name);
                        sb.AppendFormat("\"count\": {0}", val);
                        sb.Append("}");

                        firstRow = false;
                    }
                }
            }
            sb.Append("]");
            return sb.ToString();
        }
    }
}
