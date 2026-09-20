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
using System.Net.Mail;

namespace iDash
{
    public partial class va_tag_stats : System.Web.UI.Page
    {
        private string ConnStr = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Auth check
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

            // Tile check — accepts both keys (hub shows rpt_tagging; extended hub shows rpt_tag_stats)
            var tiles = Session["IdashTileAccess"] as List<string>;
            string role = System.Convert.ToString(Session["IdashUserRole"]);
            if (!UserManager.CanAccessTile(role, tiles, "rpt_tag_stats") &&
                !UserManager.CanAccessTile(role, tiles, "rpt_tagging"))
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

        // --------------------------------------------------------------------
        //  COMPANY DROPDOWN
        // --------------------------------------------------------------------
        private void LoadCompanies()
        {
            bool isAdmin = IsSessionAdmin();
            var allowedSites = GetAllowedSites();

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        var dt = new DataTable();
                        dt.Load(rdr);

                        // Filter by SiteAccess if not admin
                        if (!isAdmin && !allowedSites.Contains("*"))
                        {
                            for (int i = dt.Rows.Count - 1; i >= 0; i--)
                            {
                                string siteName = dt.Rows[i]["name"].ToString();
                                if (!allowedSites.Contains(siteName))
                                {
                                    dt.Rows.RemoveAt(i);
                                }
                            }
                        }

                        DdlCompany.DataSource = dt;
                        DdlCompany.DataTextField = "name";
                        DdlCompany.DataValueField = "id";
                        DdlCompany.DataBind();
                    }
                    if (isAdmin || allowedSites.Contains("*") || allowedSites.Count > 1)
                    {
                        DdlCompany.Items.Insert(0, new ListItem("All Allowed Sites", "0"));
                    }
                }
            }
            catch (Exception ex)
            {
                LitMsg.Text = "<div class='err-msg'>Error loading companies: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        // --------------------------------------------------------------------
        //  API ROUTER
        // --------------------------------------------------------------------
        private void HandleApiRequest()
        {
            Response.Clear();
            Response.ContentType = "application/json";
            string action    = Request.QueryString["api"]      ?? "";
            string companyId = Request.QueryString["companyid"] ?? "0";
            string range     = Request.QueryString["range"]     ?? "all";
            string tagType   = Request.QueryString["tagtype"]   ?? "";

            try
            {
                switch (action)
                {
                    case "execstats":
                        Response.Write(GetExecStatsJson(companyId, range));
                        break;
                    case "tagstats":
                        Response.Write(GetTagStatsJson(companyId));
                        break;
                    case "userstats":
                        Response.Write(GetUserStatsJson(companyId));
                        break;
                    case "tagtypecounts":
                        Response.Write(GetTagTypeCountsJson(companyId));
                        break;
                    case "tagtypepreview":
                        Response.Write(GetTagTypePreviewJson(companyId, tagType));
                        break;
                    case "exportcsv":
                        ExportCsv(companyId);
                        return;
                    case "exportassetvalue":
                        ExportAssetValueExcel(companyId);
                        return;
                    default:
                        Response.Write("{\"error\":\"Unknown API action\"}");
                        break;
                }
            }
            catch (System.Threading.ThreadAbortException)
            {
                // Expected when Response.End() / Response.Close() is called inside an export — ignore
            }
            catch (Exception ex)
            {
                Response.Write("{\"error\": \"" + JsonSafe(ex.Message) + "\"}");
            }
            finally
            {
                try { Response.End(); } catch { }
            }
        }

        // --------------------------------------------------------------------
        //  EXEC STATS - KPIs + Sites bar + Tag Types pie + Trend + Locations
        // --------------------------------------------------------------------
        private string GetExecStatsJson(string companyId, string range)
        {
            string siteWhere = BuildSiteWhere("a", companyId);
            string dateClause = BuildDateClause(range);

            StringBuilder json = new StringBuilder();
            json.Append("{");

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // KPIs
                string kpiSql = @"
                    SELECT
                        COUNT(*) as Total,
                        SUM(CASE WHEN text18 = '1' THEN 1 ELSE 0 END) as Tagged,
                        SUM(CASE WHEN ISNULL(text18,'') <> '1' THEN 1 ELSE 0 END) as Untagged,
                        SUM(CASE WHEN text18 = '1' AND ISNULL(listvalue1,'') NOT LIKE '%In Use%' THEN 1 ELSE 0 END) as TaggedNotInUse,
                        ISNULL(SUM(CASE WHEN text18 = '1' AND ISNULL(listvalue1,'') NOT LIKE '%In Use%'
                                         AND text15 IS NOT NULL AND text15 <> '' AND ISNUMERIC(text15)=1
                                        THEN CAST(text15 AS decimal(18,2)) ELSE 0 END), 0) as AssetValue,
                        SUM(CASE WHEN text18 = '1' AND ISNULL(listvalue1,'') NOT LIKE '%In Use%'
                                  AND text15 IS NOT NULL AND text15 <> '' AND ISNUMERIC(text15)=1
                                 THEN 1 ELSE 0 END) as AssetValueCount,
                        ISNULL(SUM(CASE WHEN ISNULL(listvalue1,'') NOT LIKE '%In Use%'
                                         AND text15 IS NOT NULL AND text15 <> '' AND ISNUMERIC(text15)=1
                                        THEN CAST(text15 AS decimal(18,2)) ELSE 0 END), 0) as TotalAssetValue,
                        SUM(CASE WHEN ISNULL(listvalue1,'') NOT LIKE '%In Use%'
                                  AND text15 IS NOT NULL AND text15 <> '' AND ISNUMERIC(text15)=1
                                 THEN 1 ELSE 0 END) as TotalAssetValueCount,
                        SUM(CASE WHEN text8 IS NOT NULL AND LEFT(LTRIM(text8), 2) = '78' THEN 1 ELSE 0 END) as OitTotal,
                        SUM(CASE WHEN text8 IS NOT NULL AND LEFT(LTRIM(text8), 2) = '78' AND text18 = '1' THEN 1 ELSE 0 END) as OitTagged
                    FROM dbo.v_asset a
                    WHERE 1=1" + siteWhere + dateClause;

                using (SqlCommand cmd = new SqlCommand(kpiSql, conn))
                {
                    cmd.CommandTimeout = 120;
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        json.Append("\"kpis\":{");
                        if (r.Read())
                        {
                            json.AppendFormat("\"Total\":{0},",               DbInt(r["Total"]));
                            json.AppendFormat("\"Tagged\":{0},",              DbInt(r["Tagged"]));
                            json.AppendFormat("\"Untagged\":{0},",            DbInt(r["Untagged"]));
                            json.AppendFormat("\"TaggedNotInUse\":{0},",      DbInt(r["TaggedNotInUse"]));
                            json.AppendFormat("\"AssetValue\":{0},",          DbDec(r["AssetValue"]));
                            json.AppendFormat("\"AssetValueCount\":{0},",     DbInt(r["AssetValueCount"]));
                            json.AppendFormat("\"TotalAssetValue\":{0},",     DbDec(r["TotalAssetValue"]));
                            json.AppendFormat("\"TotalAssetValueCount\":{0},", DbInt(r["TotalAssetValueCount"]));
                            json.AppendFormat("\"OitTotal\":{0},",            DbInt(r["OitTotal"]));
                            json.AppendFormat("\"OitTagged\":{0}",            DbInt(r["OitTagged"]));
                        }
                        json.Append("},");
                    }
                }

                // Sites bar
                string sitesSql = @"
                    SELECT TOP 15
                        ISNULL(c.name,'Unknown') as label,
                        SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as tagged,
                        SUM(CASE WHEN ISNULL(a.text18,'')<>'1' THEN 1 ELSE 0 END) as untagged
                    FROM dbo.v_asset a
                    LEFT JOIN dbo.company c ON a.companyid = c.id
                    WHERE 1=1" + siteWhere + dateClause + @"
                    GROUP BY c.name
                    ORDER BY COUNT(*) DESC";
                json.Append("\"sites\":");
                json.Append(ReaderToSiteJson(sitesSql, conn));
                json.Append(",");

                // Tag Types pie
                string typesSql = @"
                    SELECT TOP 12
                        ISNULL(a.text19,'Unknown') as label,
                        COUNT(*) as count
                    FROM dbo.v_asset a
                    WHERE a.text18 = '1'" + siteWhere + dateClause + @"
                    GROUP BY a.text19
                    ORDER BY COUNT(*) DESC";
                json.Append("\"tagTypes\":");
                json.Append(ReaderToLabelCount(typesSql, conn));
                json.Append(",");

                // Trend (last 12 months, regardless of range filter)
                string trendSql = @"
                    SELECT TOP 12
                        FORMAT(a.lastinventoried,'yyyy-MM') as label,
                        COUNT(*) as count
                    FROM dbo.v_asset a
                    WHERE a.lastinventoried >= DATEADD(month,-12,GETDATE())" + siteWhere + @"
                    GROUP BY FORMAT(a.lastinventoried,'yyyy-MM')
                    ORDER BY label ASC";
                json.Append("\"trend\":");
                json.Append(ReaderToLabelCount(trendSql, conn));
                json.Append(",");

                // Top Locations
                string locSql = @"
                    SELECT TOP 10
                        ISNULL(a.locationname,'Unassigned') as label,
                        COUNT(*) as count
                    FROM dbo.v_asset a
                    WHERE a.text18 = '1'" + siteWhere + dateClause + @"
                    GROUP BY a.locationname
                    ORDER BY COUNT(*) DESC";
                json.Append("\"locations\":");
                json.Append(ReaderToLabelCount(locSql, conn));
            }

            json.Append("}");
            return json.ToString();
        }

        // --------------------------------------------------------------------
        //  TAG STATS - detail by site/CMR/location
        // --------------------------------------------------------------------
        private string GetTagStatsJson(string companyId)
        {
            string siteWhere = BuildSiteWhere("a", companyId);
            bool allSites = (companyId == "0" || string.IsNullOrEmpty(companyId));
            string sql;

            if (allSites)
            {
                sql = @"
                    SELECT
                        ISNULL(c.name,'Unknown Site') as Site,
                        '' as Owner,
                        '' as Location,
                        SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as Tagged,
                        SUM(CASE WHEN ISNULL(a.text18,'')<>'1' THEN 1 ELSE 0 END) as NotTagged,
                        COUNT(*) as Total
                    FROM dbo.v_asset a
                    LEFT JOIN dbo.company c ON a.companyid = c.id
                    GROUP BY c.name
                    ORDER BY COUNT(*) DESC";
            }
            else
            {
                sql = @"
                    SELECT
                        ISNULL(c.name,'Unknown Site') as Site,
                        '' as Owner,
                        '' as Location,
                        SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as Tagged,
                        SUM(CASE WHEN ISNULL(a.text18,'')<>'1' THEN 1 ELSE 0 END) as NotTagged,
                        COUNT(*) as Total
                    FROM dbo.v_asset a
                    LEFT JOIN dbo.company c ON a.companyid = c.id
                    WHERE 1=1" + siteWhere + @"
                    GROUP BY c.name
                    ORDER BY c.name";
            }

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 300;
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                        return DataReaderToJson(rdr);
                }
            }
        }

        // --------------------------------------------------------------------
        //  USER STATS
        // --------------------------------------------------------------------
        private string GetUserStatsJson(string companyId)
        {
            string siteWhere = BuildSiteWhere("", companyId).Replace("a.companyid","companyid");
            string sql = @"
                SELECT TOP 100
                    ISNULL(text13,'Unknown') as UserId,
                    SUM(CASE WHEN CONVERT(date,lastinventoried) = CONVERT(date,GETDATE()) THEN 1 ELSE 0 END) as Today,
                    SUM(CASE WHEN lastinventoried >= DATEADD(day,-7,GETDATE())   THEN 1 ELSE 0 END) as ThisWeek,
                    SUM(CASE WHEN lastinventoried >= DATEADD(month,-1,GETDATE()) THEN 1 ELSE 0 END) as ThisMonth,
                    COUNT(*) as Total
                FROM dbo.v_asset
                WHERE 1=1" + siteWhere + @"
                GROUP BY text13
                ORDER BY Today DESC, ThisWeek DESC, ThisMonth DESC, Total DESC";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 120;
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                        return DataReaderToJson(rdr);
                }
            }
        }

        // --------------------------------------------------------------------
        //  TAG TYPE COUNTS
        // --------------------------------------------------------------------
        private string GetTagTypeCountsJson(string companyId)
        {
            string siteWhere = BuildSiteWhere("a", companyId);
            string sql = @"
                SELECT
                    ISNULL(a.text19,'(No Type)') as TagType,
                    COUNT(*) as Count
                FROM dbo.v_asset a
                WHERE a.text19 IS NOT NULL" + siteWhere + @"
                GROUP BY a.text19
                ORDER BY COUNT(*) DESC";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 120;
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                        return DataReaderToJson(rdr);
                }
            }
        }

        // --------------------------------------------------------------------
        //  TAG TYPE PREVIEW
        // --------------------------------------------------------------------
        private string GetTagTypePreviewJson(string companyId, string tagType)
        {
            string siteWhere = BuildSiteWhere("a", companyId);
            string typeFilter = !string.IsNullOrWhiteSpace(tagType)
                ? " AND a.text19 LIKE @tt"
                : "";

            string sql = @"
                SELECT TOP 100
                    ISNULL(a.name,'Unknown') as AssetName,
                    ISNULL(a.text19,'(No Type)') as TagType,
                    ISNULL(a.locationname,'Unassigned') as Location,
                    CONVERT(varchar(20), a.lastinventoried, 120) as LastObserved
                FROM dbo.v_asset a
                WHERE 1=1" + siteWhere + typeFilter + @"
                ORDER BY a.text19 ASC, a.name ASC";

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 120;
                    if (!string.IsNullOrWhiteSpace(tagType))
                        cmd.Parameters.AddWithValue("@tt", "%" + tagType + "%");
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                        return DataReaderToJson(rdr);
                }
            }
        }

        // --------------------------------------------------------------------
        //  ASSET VALUE EXPORT (Excel-compatible CSV)
        // --------------------------------------------------------------------
        private void ExportAssetValueExcel(string companyId)
        {
            string siteWhere = BuildSiteWhere("a", companyId);
            string sql = @"
                SELECT
                    ISNULL(c.name,'Unknown') as [Site],
                    ISNULL(a.name,'') as [Asset Tag],
                    ISNULL(a.listvalue1,'') as [Status],
                    ISNULL(a.text1,'') as [MANUFACTURER],
                    ISNULL(a.text2,'') as [MODEL],
                    ISNULL(a.text3,'') as [SERIAL #],
                    ISNULL(a.text4,'') as [EQUIPMENT CATEGORY],
                    ISNULL(a.text5,'') as [SERVICE POINTER],
                    ISNULL(a.text6,'') as [SP + LOCATION],
                    ISNULL(a.text7,'') as [STATION NUMBER],
                    ISNULL(a.text8,'') as [CMR/EIL],
                    ISNULL(a.text9,'') as [PURCHASE ORDER #],
                    ISNULL(a.text10,'') as [PHYSICAL INVENTORY DATE (raw)],
                    ISNULL(a.text11,'') as [SP + PREVIOUS LOCATION],
                    ISNULL(a.text12,'') as [ENTRY NUMBER],
                    ISNULL(a.text13,'') as [EMPL_ID],
                    ISNULL(a.text14,'') as [SUBSTATION],
                    CAST(CAST(a.text15 AS decimal(18,2)) AS varchar(30)) as [ASSET VALUE],
                    ISNULL(a.text16,'') as [LOCATION TAGGED (FOUND)],
                    ISNULL(a.text17,'') as [TAGGED ON DATE],
                    ISNULL(a.text18,'') as [TAGGED],
                    ISNULL(a.text19,'') as [TAG_TYPE],
                    ISNULL(a.text20,'') as [NOTES]
                FROM dbo.v_asset a
                LEFT JOIN dbo.company c ON a.companyid = c.id
                WHERE ISNULL(a.listvalue1,'') NOT LIKE '%In Use%'
                  AND a.text15 IS NOT NULL
                  AND a.text15 <> ''
                  AND ISNUMERIC(a.text15) = 1" + siteWhere + @"
                ORDER BY c.name, CAST(a.text15 AS decimal(18,2)) DESC";

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                using (SqlDataAdapter da = new SqlDataAdapter(sql, conn))
                {
                    da.SelectCommand.CommandTimeout = 300;
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    // Build CSV with BOM so Excel opens with correct encoding
                    StringBuilder sb = new StringBuilder();
                    // Header
                    for (int i = 0; i < dt.Columns.Count; i++)
                    {
                        if (i > 0) sb.Append(",");
                        sb.Append("\"" + dt.Columns[i].ColumnName + "\"");
                    }
                    sb.AppendLine();
                    // Grand total row placeholder (calculated client-side, but we add it as a footer)
                    decimal grandTotal = 0m;
                    int rowCount = 0;
                    foreach (DataRow row in dt.Rows)
                    {
                        for (int i = 0; i < dt.Columns.Count; i++)
                        {
                            if (i > 0) sb.Append(",");
                            sb.Append("\"" + row[i].ToString().Replace("\"", "\"\"") + "\"");
                        }
                        sb.AppendLine();
                        decimal v;
                        if (decimal.TryParse(row["ASSET VALUE"].ToString(), out v))
                        { grandTotal += v; rowCount++; }
                    }
                    // Summary rows at the bottom
                    sb.AppendLine();
                    
                    int assetValColIdx = dt.Columns.IndexOf("ASSET VALUE");
                    string emptyCols = "";
                    for (int i=0; i < assetValColIdx - 1; i++) emptyCols += "\"\",";
                    
                    sb.AppendLine(emptyCols + "\"Total Assets with Value:\",\"" + rowCount + "\"");
                    sb.AppendLine(emptyCols + "\"GRAND TOTAL:\",\"" + grandTotal.ToString("F2") + "\"");

                    string siteName = companyId == "0" || string.IsNullOrEmpty(companyId) ? "AllSites" : companyId;
                    string fname = "AssetValue_" + siteName + "_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";

                    Response.ClearContent();
                    Response.AddHeader("content-disposition", "attachment; filename=" + fname);
                    Response.ContentType = "application/vnd.ms-excel";
                    // UTF-8 BOM so Excel opens it correctly
                    Response.BinaryWrite(new byte[] { 0xEF, 0xBB, 0xBF });
                    Response.BinaryWrite(Encoding.UTF8.GetBytes(sb.ToString()));
                    Response.Flush();
                    Response.Close();
                }
            }
            catch (System.Threading.ThreadAbortException) { }
        }

        // --------------------------------------------------------------------
        //  CSV EXPORT
        // --------------------------------------------------------------------
        private void ExportCsv(string companyId)
        {
            string siteWhere = BuildSiteWhere("a", companyId);
            bool allSites = (companyId == "0" || string.IsNullOrEmpty(companyId));
            string sql;

            if (allSites)
            {
                sql = @"
                    SELECT
                        ISNULL(c.name,'Unknown Site') as [Site],
                        SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as [Tagged],
                        SUM(CASE WHEN ISNULL(a.text18,'')<>'1' THEN 1 ELSE 0 END) as [Not Tagged],
                        COUNT(*) as [Total]
                    FROM dbo.v_asset a
                    LEFT JOIN dbo.company c ON a.companyid = c.id
                    GROUP BY c.name ORDER BY c.name";
            }
            else
            {
                sql = @"
                    SELECT
                        ISNULL(c.name,'Unknown') as [Site],
                        ISNULL(a.text8,'Unassigned') as [EIL/CMR],
                        ISNULL(a.locationname,'Unassigned') as [Location],
                        SUM(CASE WHEN a.text18='1' THEN 1 ELSE 0 END) as [Tagged],
                        SUM(CASE WHEN ISNULL(a.text18,'')<>'1' THEN 1 ELSE 0 END) as [Not Tagged],
                        COUNT(*) as [Total]
                    FROM dbo.v_asset a
                    LEFT JOIN dbo.company c ON a.companyid = c.id
                    WHERE 1=1" + siteWhere + @"
                    GROUP BY c.name, a.text8, a.locationname
                    ORDER BY c.name, a.locationname, a.text8";
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                using (SqlDataAdapter da = new SqlDataAdapter(sql, conn))
                {
                    da.SelectCommand.CommandTimeout = 300;
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    StringBuilder sb = new StringBuilder();
                    for (int i = 0; i < dt.Columns.Count; i++)
                    {
                        sb.Append("\"" + dt.Columns[i].ColumnName + "\"");
                        if (i < dt.Columns.Count - 1) sb.Append(",");
                    }
                    sb.AppendLine();
                    foreach (DataRow row in dt.Rows)
                    {
                        for (int i = 0; i < dt.Columns.Count; i++)
                        {
                            sb.Append("\"" + row[i].ToString().Replace("\"", "\"\"") + "\"");
                            if (i < dt.Columns.Count - 1) sb.Append(",");
                        }
                        sb.AppendLine();
                    }

                    string fname = "TaggingStats_" + DateTime.Now.ToString("yyyyMMdd") + ".csv";
                    Response.ClearContent();
                    Response.AddHeader("content-disposition", "attachment; filename=" + fname);
                    Response.ContentType = "text/csv";
                    Response.BinaryWrite(Encoding.UTF8.GetBytes(sb.ToString()));
                    Response.Flush();
                    Response.Close();
                }
            }
            catch (System.Threading.ThreadAbortException) { }
        }

        // --------------------------------------------------------------------
        //  HELPERS
        // --------------------------------------------------------------------
        // --------------------------------------------------------------------
        //  SESSION HELPERS
        // --------------------------------------------------------------------

        /// <summary>
        /// Returns true if the current session is an authenticated admin.
        /// Falls back to checking IdashUserRole so the page works whether the
        /// user logged in through the iDash user-account system OR through the
        /// SQL admin panel on index.aspx (which may not populate IdashUsername).
        /// </summary>
        private bool IsSessionAdmin()
        {
            // Primary check: full iDash user record
            var user = UserManager.GetUser(Convert.ToString(Session["IdashUsername"]));
            if (user != null) return UserManager.CanAccessAdmin(user.Role);

            // Fallback: session role set by index.aspx login (SQL admin path)
            string role = Convert.ToString(Session["IdashUserRole"]);
            if (role == UserManager.ROLE_ADMIN) return true;

            // Fallback: IsAdminAuthenticated flag (admin panel session)
            object authFlag = Session["IsAdminAuthenticated"];
            return authFlag != null && (bool)authFlag;
        }

        /// <summary>
        /// Returns the list of site names this session user is allowed to see.
        /// Returns an empty list if the user record cannot be resolved (caller
        /// should treat empty + isAdmin=false as no-access, but isAdmin=true
        /// as all-access — so always check IsSessionAdmin() first).
        /// </summary>
        private List<string> GetAllowedSites()
        {
            var user = UserManager.GetUser(Convert.ToString(Session["IdashUsername"]));
            if (user != null && user.SiteAccess != null)
                return user.SiteAccess.Keys.ToList();
            return new List<string>();
        }

        private string BuildSiteWhere(string alias, string companyId)
        {
            bool isAdmin = IsSessionAdmin();
            var allowedSites = GetAllowedSites();
            string col = string.IsNullOrEmpty(alias) ? "companyid" : alias + ".companyid";

            string baseFilter = "";
            if (!isAdmin && !allowedSites.Contains("*"))
            {
                if (allowedSites.Count == 0) return " AND 1=0 "; // No access

                List<string> safeSites = new List<string>();
                foreach (string s in allowedSites)
                {
                    safeSites.Add("'" + s.Replace("'", "''") + "'");
                }
                baseFilter = string.Format(" AND {0} IN (SELECT id FROM dbo.company WHERE name IN ({1})) ", col, string.Join(",", safeSites));
            }

            if (companyId == "0" || string.IsNullOrEmpty(companyId)) return baseFilter;
            
            int cid;
            if (!int.TryParse(companyId, out cid)) return baseFilter;

            return baseFilter + " AND " + col + " = " + cid;
        }

        private string BuildDateClause(string range)
        {
            switch (range)
            {
                case "today":  return " AND CONVERT(date,a.lastinventoried) = CONVERT(date,GETDATE()) ";
                case "week":   return " AND a.lastinventoried >= DATEADD(day,-7,GETDATE()) ";
                case "month":  return " AND a.lastinventoried >= DATEADD(month,-1,GETDATE()) ";
                default:       return "";
            }
        }

        private string ReaderToLabelCount(string sql, SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder("[");
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    bool first = true;
                    while (r.Read())
                    {
                        if (!first) sb.Append(",");
                        sb.AppendFormat("{{\"label\":\"{0}\",\"count\":{1}}}",
                            JsonSafe(r["label"].ToString()),
                            r["count"]);
                        first = false;
                    }
                }
            }
            sb.Append("]");
            return sb.ToString();
        }

        private string ReaderToSiteJson(string sql, SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder("[");
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    bool first = true;
                    while (r.Read())
                    {
                        if (!first) sb.Append(",");
                        sb.AppendFormat("{{\"label\":\"{0}\",\"tagged\":{1},\"untagged\":{2}}}",
                            JsonSafe(r["label"].ToString()),
                            r["tagged"],
                            r["untagged"]);
                        first = false;
                    }
                }
            }
            sb.Append("]");
            return sb.ToString();
        }

        private string DataReaderToJson(SqlDataReader rdr)
        {
            StringBuilder sb = new StringBuilder("[");
            bool firstRow = true;
            while (rdr.Read())
            {
                if (!firstRow) sb.Append(",");
                sb.Append("{");
                for (int i = 0; i < rdr.FieldCount; i++)
                {
                    if (i > 0) sb.Append(",");
                    sb.Append("\"").Append(rdr.GetName(i)).Append("\":");
                    object val = rdr.GetValue(i);
                    if (val == DBNull.Value) { sb.Append("null"); }
                    else if (val is string) { sb.Append("\"").Append(JsonSafe(val.ToString())).Append("\""); }
                    else { sb.Append(val.ToString()); }
                }
                sb.Append("}");
                firstRow = false;
            }
            sb.Append("]");
            return sb.ToString();
        }

        // Null-safe helpers for JSON numeric output
        private int DbInt(object val) { return (val == null || val == DBNull.Value) ? 0 : Convert.ToInt32(val); }
        private decimal DbDec(object val) { return (val == null || val == DBNull.Value) ? 0m : Convert.ToDecimal(val); }

        private string JsonSafe(string s)
        {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
        }
    }
}
