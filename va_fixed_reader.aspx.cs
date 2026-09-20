using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Text.RegularExpressions;
using System.Web.UI.WebControls;

namespace iDash
{
    public partial class va_fixed_reader : System.Web.UI.Page
    {
        private string ConnStr = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(Request.QueryString["api"]))
            {
                HandleApiRequest();
                return;
            }

            if (!IsPostBack)
            {
                LoadCompanies();
                LoadReaderSites();
            }
        }

        // ────────────────────────────────────────────────────────────
        //  COMPANY DROPDOWN
        // ────────────────────────────────────────────────────────────
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

                        // If user has no site restrictions (empty list), show all sites
                        // This handles: no session, no user mgmt configured, or no SiteAccess set
                        if (!isAdmin && !allowedSites.Contains("*") && allowedSites.Count > 0)
                        {
                            for (int i = dt.Rows.Count - 1; i >= 0; i--)
                            {
                                string siteName = dt.Rows[i]["name"].ToString();
                                if (!allowedSites.Contains(siteName))
                                    dt.Rows.RemoveAt(i);
                            }
                        }

                        DdlCompany.DataSource = dt;
                        DdlCompany.DataTextField = "name";
                        DdlCompany.DataValueField = "id";
                        DdlCompany.DataBind();
                    }
                    // Show "All Sites" option when user can see multiple sites
                    if (isAdmin || allowedSites.Contains("*") || allowedSites.Count != 1 || DdlCompany.Items.Count > 1)
                    {
                        DdlCompany.Items.Insert(0, new ListItem("All Sites", "0"));
                    }
                }
            }
            catch (Exception ex)
            {
                LitMsg.Text = "<div class='err-msg'>Error loading companies: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        // ────────────────────────────────────────────────────────────
        //  READER SITE DROPDOWN — filter by where the reader is physically located
        // ────────────────────────────────────────────────────────────
        private void LoadReaderSites()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    // Get companies that have locations (i.e., sites where readers could be)
                    string sql = @"SELECT DISTINCT c.id, c.name 
                                   FROM dbo.company c 
                                   INNER JOIN dbo.location l ON l.companyid = c.id 
                                   ORDER BY c.name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        var dt = new DataTable();
                        dt.Load(rdr);
                        DdlReaderSite.DataSource = dt;
                        DdlReaderSite.DataTextField = "name";
                        DdlReaderSite.DataValueField = "id";
                        DdlReaderSite.DataBind();
                    }
                    DdlReaderSite.Items.Insert(0, new System.Web.UI.WebControls.ListItem("All Reader Sites", "0"));
                }
            }
            catch { }
        }

        // ────────────────────────────────────────────────────────────
        //  API ROUTER
        // ────────────────────────────────────────────────────────────
        private void HandleApiRequest()
        {
            Response.Clear();
            Response.ContentType = "application/json";
            string action = Request.QueryString["api"] ?? "";

            try
            {
                switch (action)
                {
                    case "readers":
                        Response.Write(GetReaders());
                        break;
                    case "readerstats":
                        string companyId = Request.QueryString["companyid"] ?? "0";
                        Response.Write(GetReaderStats(companyId));
                        break;
                    case "intel_config":
                        Response.Write(GetIntelConfig());
                        break;
                    case "intel_save_config":
                        Response.Write(SaveIntelConfig());
                        break;
                    case "intel_mismatches":
                        string cid = Request.QueryString["companyid"] ?? "0";
                        string rsid2 = Request.QueryString["readersite"] ?? "0";
                        Response.Write(GetIntelMismatches(cid, rsid2));
                        break;
                    case "intel_reassign":
                        string assetId = Request.QueryString["assetid"] ?? "0";
                        Response.Write(DoReassignOne(assetId));
                        break;
                    case "intel_reassign_all":
                        string cidAll = Request.QueryString["companyid"] ?? "0";
                        string rsidAll = Request.QueryString["readersite"] ?? "0";
                        Response.Write(DoReassignAll(cidAll, rsidAll));
                        break;
                    case "reader_activity":
                        string actCid = Request.QueryString["companyid"] ?? "0";
                        string actDays = Request.QueryString["days"] ?? "30";
                        string actAllSites = Request.QueryString["allsites"] ?? "0";
                        Response.Write(GetReaderActivity(actCid, actDays, actAllSites == "1"));
                        break;
                    case "reader_events":
                        string evtDays = Request.QueryString["days"] ?? "30";
                        Response.Write(GetReaderEvents(evtDays));
                        break;
                    case "reader_events_csv":
                        string evtCsvDays = Request.QueryString["days"] ?? "30";
                        Response.ContentType = "text/csv";
                        Response.AddHeader("Content-Disposition",
                            "attachment; filename=\"FixedReaderEvents-" + DateTime.Now.ToString("MM-dd-yyyy") + ".csv\"");
                        Response.Write(GetReaderEventsCsv(evtCsvDays));
                        break;
                    case "reader_ennx":
                        string ennxCid = Request.QueryString["companyid"] ?? "0";
                        string ennxDays = Request.QueryString["days"] ?? "30";
                        string preview = Request.QueryString["preview"] ?? "0";
                        Response.ContentType = "text/plain";
                        if (preview != "1")
                            Response.AddHeader("Content-Disposition",
                                "attachment; filename=\"FixedReader-ENNX-" + DateTime.Now.ToString("MM-dd-yyyy") + ".txt\"");
                        Response.Write(GetReaderEnnx(ennxCid, ennxDays));
                        break;
                    case "location_history":
                        string lhCid = Request.QueryString["companyid"] ?? "0";
                        string lhDays = Request.QueryString["days"] ?? "90";
                        string lhAllSites = Request.QueryString["allsites"] ?? "0";
                        Response.Write(GetLocationHistory(lhCid, lhDays, lhAllSites == "1"));
                        break;
                    case "asset_history":
                        string ahAssetId = Request.QueryString["assetid"] ?? "0";
                        Response.Write(GetAssetLocationHistory(ahAssetId));
                        break;
                    case "location_history_csv":
                        string csvCid = Request.QueryString["companyid"] ?? "0";
                        string csvDays = Request.QueryString["days"] ?? "90";
                        string csvAllSites = Request.QueryString["allsites"] ?? "0";
                        Response.ContentType = "text/csv";
                        Response.AddHeader("Content-Disposition",
                            "attachment; filename=\"LocationHistory-" + DateTime.Now.ToString("MM-dd-yyyy") + ".csv\"");
                        Response.Write(GetLocationHistoryCsv(csvCid, csvDays, csvAllSites == "1"));
                        break;
                    case "missing_assets":
                        string maCid = Request.QueryString["companyid"] ?? "0";
                        string maDays = Request.QueryString["days"] ?? "90";
                        string maAllSites = Request.QueryString["allsites"] ?? "0";
                        Response.Write(GetMissingAssets(maCid, maDays, maAllSites == "1"));
                        break;
                    case "missing_assets_csv":
                        string macCid = Request.QueryString["companyid"] ?? "0";
                        string macDays = Request.QueryString["days"] ?? "90";
                        string macAllSites = Request.QueryString["allsites"] ?? "0";
                        Response.ContentType = "text/csv";
                        Response.AddHeader("Content-Disposition",
                            "attachment; filename=\"MissingAssets-" + DateTime.Now.ToString("MM-dd-yyyy") + ".csv\"");
                        Response.Write(GetMissingAssetsCsv(macCid, macDays, macAllSites == "1"));
                        break;
                    default:
                        Response.Write("{\"error\":\"Unknown API action\"}");
                        break;
                }
            }
            catch (System.Threading.ThreadAbortException) { }
            catch (Exception ex)
            {
                Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            }
            finally
            {
                try { Response.End(); } catch { }
            }
        }

        // ────────────────────────────────────────────────────────────
        //  GET READERS — proxy to iDash REST API
        // ────────────────────────────────────────────────────────────
        private string GetReaders()
        {
            object[] rawReaders = null;
            int antennaCount = 0;

            try
            {
                var dbReaders = new List<object>();
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    string sqlFallback = @"
                        SELECT r.id, r.name, r.readermodel, r.companyid, r.locationid, 
                               r.ipaddress, r.physicalid, r.devicesettings, r.lastseen, 
                               r.mqttcontroltopic, l.name AS locationName
                        FROM dbo.reader r
                        LEFT JOIN dbo.location l ON r.locationid = l.id
                        ORDER BY r.name";
                    using (var cmd = new SqlCommand(sqlFallback, conn))
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            var d = new Dictionary<string, object>();
                            d["id"] = rdr["id"] == DBNull.Value ? 0 : Convert.ToInt32(rdr["id"]);
                            d["name"] = rdr["name"] == DBNull.Value ? "" : rdr["name"].ToString();
                            d["locationName"] = rdr["locationName"] == DBNull.Value ? "" : rdr["locationName"].ToString();
                            d["locationID"] = rdr["locationid"] == DBNull.Value ? (object)null : Convert.ToInt32(rdr["locationid"]);
                            d["ipAddress"] = rdr["ipaddress"] == DBNull.Value ? "" : rdr["ipaddress"].ToString();
                            d["readerModel"] = rdr["readermodel"] == DBNull.Value ? "" : rdr["readermodel"].ToString();
                            d["physicalID"] = rdr["physicalid"] == DBNull.Value ? "" : rdr["physicalid"].ToString();
                            d["companyID"] = rdr["companyid"] == DBNull.Value ? 0 : Convert.ToInt32(rdr["companyid"]);
                            d["mqttControlTopic"] = rdr["mqttcontroltopic"] == DBNull.Value ? "" : rdr["mqttcontroltopic"].ToString();
                            d["lastSeen"] = rdr["lastseen"] == DBNull.Value ? "" : rdr["lastseen"].ToString();
                            dbReaders.Add(d);
                        }
                    }

                    try
                    {
                        using (var acmd = new SqlCommand("SELECT COUNT(*) FROM dbo.antenna", conn))
                        {
                            var o = acmd.ExecuteScalar();
                            if (o != null && o != DBNull.Value) antennaCount = Convert.ToInt32(o);
                        }
                    }
                    catch { }
                }
                rawReaders = dbReaders.ToArray();
            }
            catch (Exception ex)
            {
                return "{\"error\":\"Reader query failed: " + JsonSafe(ex.Message) + "\",\"readers\":[],\"summary\":{\"totalReaders\":0,\"online\":0,\"offline\":0,\"pctOnline\":0,\"pctOffline\":0,\"totalAntennas\":0}}";
            }

            // 11-minute threshold for Up/Down (matches dashboard logic)
            var cutoff = DateTimeOffset.UtcNow.AddMinutes(-11);
            int numUp = 0, numDown = 0;

            var sb = new StringBuilder();
            sb.Append("{\"readers\":[");

            bool first = true;
            int total = 0;
            foreach (Dictionary<string, object> r in rawReaders)
            {
                total++;
                string lastSeenStr = GetVal(r, "lastSeen");
                bool isUp = false;
                DateTimeOffset lastSeen;
                if (DateTimeOffset.TryParse(lastSeenStr, out lastSeen))
                    isUp = lastSeen > cutoff;

                if (isUp) numUp++; else numDown++;

                if (!first) sb.Append(",");
                sb.Append("{");
                sb.AppendFormat("\"name\":\"{0}\",",           JsonSafe(GetVal(r, "name")));
                sb.AppendFormat("\"locationName\":\"{0}\",",   JsonSafe(GetVal(r, "locationName")));
                sb.AppendFormat("\"ipAddress\":\"{0}\",",      JsonSafe(GetVal(r, "ipAddress")));
                sb.AppendFormat("\"status\":\"{0}\",",         isUp ? "Up" : "Down");
                sb.AppendFormat("\"lastSeen\":\"{0}\",",       JsonSafe(lastSeenStr));
                sb.AppendFormat("\"readerModel\":\"{0}\",",    JsonSafe(GetVal(r, "readerModel")));
                sb.AppendFormat("\"batchMode\":{0},",          GetBool(r, "batchMode") ? "true" : "false");
                sb.AppendFormat("\"updateLocation\":{0},",     GetBool(r, "updateLocation") ? "true" : "false");
                sb.AppendFormat("\"mqttControlTopic\":\"{0}\",", JsonSafe(GetVal(r, "mqttControlTopic")));
                sb.AppendFormat("\"id\":{0}",                  GetInt(r, "id"));
                sb.Append("}");
                first = false;
            }

            sb.Append("],\"summary\":{");
            sb.AppendFormat("\"totalReaders\":{0},", total);
            sb.AppendFormat("\"online\":{0},", numUp);
            sb.AppendFormat("\"offline\":{0},", numDown);
            sb.AppendFormat("\"pctOnline\":{0},", total > 0 ? Math.Round((double)numUp / total * 100, 1) : 0);
            sb.AppendFormat("\"pctOffline\":{0},", total > 0 ? Math.Round((double)numDown / total * 100, 1) : 0);
            sb.AppendFormat("\"totalAntennas\":{0}", antennaCount);
            sb.Append("}}");

            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  GET READER STATS — tag observations from SQL (v_asset)
        // ────────────────────────────────────────────────────────────
        private string GetReaderStats(string companyId)
        {
            string readerSiteId = Request.QueryString["readersite"] ?? "0";
            string siteWhere = BuildSiteWhere("a", companyId);

            // Reader site filter: filter by the companyid of the LOCATION where the reader is
            string readerSiteWhere = "";
            int rsid;
            if (int.TryParse(readerSiteId, out rsid) && rsid > 0)
            {
                readerSiteWhere = string.Format(
                    " AND a.lastobservedlocation IN (SELECT name FROM dbo.location WHERE companyid = {0})", rsid);
            }

            var sb = new StringBuilder("{");

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Tag reads by fixed readers — lastobservedtime tracks fixed reader reads
                string sql = @"
                    SELECT
                        SUM(CASE WHEN a.lastobservedtime >= DATEADD(day, -1, GETDATE()) THEN 1 ELSE 0 END) as ObsToday,
                        SUM(CASE WHEN a.lastobservedtime >= DATEADD(day, -7, GETDATE()) THEN 1 ELSE 0 END) as ObsWeek,
                        SUM(CASE WHEN a.lastobservedtime >= DATEADD(month, -1, GETDATE()) THEN 1 ELSE 0 END) as ObsMonth,
                        SUM(CASE WHEN a.lastobservedtime >= DATEADD(month, -3, GETDATE()) THEN 1 ELSE 0 END) as Obs3Month,
                        SUM(CASE WHEN a.lastobservedtime IS NOT NULL THEN 1 ELSE 0 END) as ObsTotal,
                        COUNT(*) as TotalAssets
                    FROM dbo.v_asset a
                    WHERE 1=1" + siteWhere + readerSiteWhere;

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 120;
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        sb.Append("\"tagReads\":{");
                        if (r.Read())
                        {
                            sb.AppendFormat("\"today\":{0},", DbInt(r["ObsToday"]));
                            sb.AppendFormat("\"week\":{0},", DbInt(r["ObsWeek"]));
                            sb.AppendFormat("\"month\":{0},", DbInt(r["ObsMonth"]));
                            sb.AppendFormat("\"quarter\":{0},", DbInt(r["Obs3Month"]));
                            sb.AppendFormat("\"total\":{0},", DbInt(r["ObsTotal"]));
                            sb.AppendFormat("\"assets\":{0}", DbInt(r["TotalAssets"]));
                        }
                        sb.Append("},");
                    }
                }

                // Top observed locations (last 30 days)
                string locSql = @"
                    SELECT TOP 10
                        ISNULL(a.lastobservedlocation, 'Unknown') as label,
                        COUNT(*) as count
                    FROM dbo.v_asset a
                    WHERE a.lastobservedtime >= DATEADD(month, -1, GETDATE())
                        AND a.lastobservedlocation IS NOT NULL
                        AND a.lastobservedlocation <> ''" + siteWhere + readerSiteWhere + @"
                    GROUP BY a.lastobservedlocation
                    ORDER BY COUNT(*) DESC";

                sb.Append("\"topLocations\":");
                sb.Append(QueryToLabelCount(locSql, conn));
                sb.Append(",");

                // Reads by device type: Fixed vs Mobile vs Not Read
                string devSql = @"
                    SELECT
                        SUM(CASE WHEN a.lastobservedtime IS NOT NULL AND a.lastinventoried IS NOT NULL THEN 1 ELSE 0 END) as Both,
                        SUM(CASE WHEN a.lastobservedtime IS NOT NULL AND (a.lastinventoried IS NULL) THEN 1 ELSE 0 END) as FixedOnly,
                        SUM(CASE WHEN (a.lastobservedtime IS NULL) AND a.lastinventoried IS NOT NULL THEN 1 ELSE 0 END) as MobileOnly,
                        SUM(CASE WHEN a.lastobservedtime IS NULL AND a.lastinventoried IS NULL THEN 1 ELSE 0 END) as NotRead,
                        COUNT(*) as Total
                    FROM dbo.v_asset a
                    WHERE 1=1" + siteWhere + readerSiteWhere;

                using (SqlCommand cmd3 = new SqlCommand(devSql, conn))
                {
                    cmd3.CommandTimeout = 120;
                    using (SqlDataReader r3 = cmd3.ExecuteReader())
                    {
                        sb.Append("\"deviceReads\":{");
                        if (r3.Read())
                        {
                            int both = DbInt(r3["Both"]);
                            int fixedOnly = DbInt(r3["FixedOnly"]);
                            int mobileOnly = DbInt(r3["MobileOnly"]);
                            int notRead = DbInt(r3["NotRead"]);
                            int total = DbInt(r3["Total"]);
                            int fixedTotal = both + fixedOnly;
                            int mobileTotal = both + mobileOnly;

                            sb.AppendFormat("\"fixed\":{0},", fixedTotal);
                            sb.AppendFormat("\"mobile\":{0},", mobileTotal);
                            sb.AppendFormat("\"notRead\":{0},", notRead);
                            sb.AppendFormat("\"total\":{0},", total);
                            sb.AppendFormat("\"pctFixed\":{0},", total > 0 ? Math.Round((double)fixedTotal / total * 100, 1) : 0);
                            sb.AppendFormat("\"pctMobile\":{0},", total > 0 ? Math.Round((double)mobileTotal / total * 100, 1) : 0);
                            sb.AppendFormat("\"pctNotRead\":{0}", total > 0 ? Math.Round((double)notRead / total * 100, 1) : 0);
                        }
                        sb.Append("}");
                    }
                }
            }

            sb.Append("}");
            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  HELPERS
        // ────────────────────────────────────────────────────────────
        private static string _cachedToken;
        private static DateTime _tokenExpiry = DateTime.MinValue;

        private string GetApiToken(string tokenUrl, string clientId, string clientSecret)
        {
            if (!string.IsNullOrEmpty(_cachedToken) && DateTime.UtcNow < _tokenExpiry)
                return _cachedToken;

            try
            {
                using (var wc = new WebClient())
                {
                    wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
                    string postData = "grant_type=client_credentials" +
                                     "&client_id=" + Uri.EscapeDataString(clientId ?? "") +
                                     "&client_secret=" + Uri.EscapeDataString(clientSecret ?? "");
                    string resp = wc.UploadString(tokenUrl, "POST", postData);
                    var jss = new JavaScriptSerializer();
                    var token = jss.Deserialize<Dictionary<string, object>>(resp);
                    if (token.ContainsKey("access_token"))
                    {
                        _cachedToken = token["access_token"].ToString();
                        int expiresIn = token.ContainsKey("expires_in") ? Convert.ToInt32(token["expires_in"]) : 3600;
                        _tokenExpiry = DateTime.UtcNow.AddSeconds(expiresIn - 60);
                        return _cachedToken;
                    }
                }
            }
            catch { }
            return null;
        }

        private string GetVal(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return "";
            return d[key].ToString();
        }

        private bool GetBool(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return false;
            if (d[key] is bool) return (bool)d[key];
            return d[key].ToString().Equals("true", StringComparison.OrdinalIgnoreCase);
        }

        private int GetInt(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return 0;
            int val;
            if (int.TryParse(d[key].ToString(), out val)) return val;
            return 0;
        }

        private int DbInt(object val) { return (val == null || val == DBNull.Value) ? 0 : Convert.ToInt32(val); }

        private string QueryToLabelCount(string sql, SqlConnection conn)
        {
            var sb = new StringBuilder("[");
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 60;
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    bool first = true;
                    while (r.Read())
                    {
                        if (!first) sb.Append(",");
                        sb.AppendFormat("{{\"label\":\"{0}\",\"count\":{1}}}",
                            JsonSafe(r["label"].ToString()), r["count"]);
                        first = false;
                    }
                }
            }
            sb.Append("]");
            return sb.ToString();
        }

        private string BuildSiteWhere(string alias, string companyId)
        {
            bool isAdmin = IsSessionAdmin();
            var allowedSites = GetAllowedSites();
            string col = string.IsNullOrEmpty(alias) ? "companyid" : alias + ".companyid";

            string baseFilter = "";
            if (!isAdmin && !allowedSites.Contains("*") && allowedSites.Count > 0)
            {
                var safeSites = new List<string>();
                foreach (string s in allowedSites)
                    safeSites.Add("'" + s.Replace("'", "''") + "'");
                baseFilter = string.Format(" AND {0} IN (SELECT id FROM dbo.company WHERE name IN ({1})) ", col, string.Join(",", safeSites));
            }

            if (companyId == "0" || string.IsNullOrEmpty(companyId)) return baseFilter;
            int cid;
            if (!int.TryParse(companyId, out cid)) return baseFilter;
            return baseFilter + " AND " + col + " = " + cid;
        }

        private bool IsSessionAdmin()
        {
            var user = UserManager.GetUser(Convert.ToString(Session["IdashUsername"]));
            if (user != null) return UserManager.CanAccessAdmin(user.Role);
            string role = Convert.ToString(Session["IdashUserRole"]);
            if (role == UserManager.ROLE_ADMIN) return true;
            object authFlag = Session["IsAdminAuthenticated"];
            return authFlag != null && (bool)authFlag;
        }

        private List<string> GetAllowedSites()
        {
            var user = UserManager.GetUser(Convert.ToString(Session["IdashUsername"]));
            if (user != null && user.SiteAccess != null)
                return user.SiteAccess.Keys.ToList();
            return new List<string>();
        }

        private string JsonSafe(string s)
        {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
        }

        // ────────────────────────────────────────────────────────────
        //  READER INTELLIGENCE API HANDLERS
        // ────────────────────────────────────────────────────────────

        private string GetIntelConfig()
        {
            var config = ReaderIntelligenceService.LoadConfig();
            var jss = new JavaScriptSerializer();
            return jss.Serialize(config);
        }

        private string SaveIntelConfig()
        {
            try
            {
                string body;
                using (var reader = new System.IO.StreamReader(Request.InputStream))
                {
                    body = reader.ReadToEnd();
                }
                var jss = new JavaScriptSerializer();
                var incoming = jss.Deserialize<Dictionary<string, object>>(body);

                var config = ReaderIntelligenceService.LoadConfig();
                if (incoming.ContainsKey("dwellTimeHours"))
                    config.dwellTimeHours = Convert.ToInt32(incoming["dwellTimeHours"]);
                if (incoming.ContainsKey("departureTimeoutMinutes"))
                    config.departureTimeoutMinutes = Convert.ToInt32(incoming["departureTimeoutMinutes"]);
                if (incoming.ContainsKey("autoReassignLocation"))
                    config.autoReassignLocation = Convert.ToBoolean(incoming["autoReassignLocation"]);
                if (incoming.ContainsKey("emailReport"))
                    config.emailReport = Convert.ToBoolean(incoming["emailReport"]);
                if (incoming.ContainsKey("emailRecipients"))
                    config.emailRecipients = incoming["emailRecipients"].ToString();
                if (incoming.ContainsKey("observationMismatchAlert"))
                    config.observationMismatchAlert = Convert.ToBoolean(incoming["observationMismatchAlert"]);
                if (incoming.ContainsKey("recentWindowDays"))
                    config.recentWindowDays = Convert.ToInt32(incoming["recentWindowDays"]);
                if (incoming.ContainsKey("readerIdentities"))
                {
                    var arr = incoming["readerIdentities"] as System.Collections.ArrayList;
                    if (arr != null)
                        config.readerIdentities = arr.Cast<object>().Select(o => o.ToString()).ToList();
                }

                ReaderIntelligenceService.SaveConfig(config);
                return "{\"success\":true}";
            }
            catch (Exception ex)
            {
                return "{\"success\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }

        private string GetIntelMismatches(string companyIdStr, string readerSiteStr)
        {
            int companyId = 0, readerSiteId = 0;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(readerSiteStr, out readerSiteId);

            var mismatches = ReaderIntelligenceService.GetMismatchedAssets(companyId, readerSiteId);
            var stats = ReaderIntelligenceService.GetStats(companyId, readerSiteId);

            var jss = new JavaScriptSerializer();
            jss.MaxJsonLength = int.MaxValue;

            var result = new Dictionary<string, object>();
            var mList = new List<Dictionary<string, object>>();
            foreach (var m in mismatches)
            {
                mList.Add(new Dictionary<string, object>
                {
                    {"AssetId", m.AssetId},
                    {"AssetName", m.AssetName},
                    {"ObservedLocation", m.ObservedLocation},
                    {"AssignedLocation", m.AssignedLocation},
                    {"LastObservedTime", m.LastObservedTime},
                    {"HoursAtLocation", m.HoursAtLocation},
                    {"ExceedsThreshold", m.ExceedsThreshold},
                    {"CompanyId", m.CompanyId},
                    {"CompanyName", m.CompanyName}
                });
            }
            result["mismatches"] = mList;
            result["stats"] = new Dictionary<string, object>
            {
                {"MismatchCount", stats.MismatchCount},
                {"DwellCandidates", stats.DwellCandidates},
                {"ReassignedToday", stats.ReassignedToday},
                {"DepartedToday", stats.DepartedToday},
                {"DwellThresholdHours", stats.DwellThresholdHours}
            };

            return jss.Serialize(result);
        }

        private string DoReassignOne(string assetIdStr)
        {
            long assetId;
            if (!long.TryParse(assetIdStr, out assetId))
                return "{\"success\":false,\"error\":\"Invalid asset ID\"}";

            var result = ReaderIntelligenceService.ReassignAsset(assetId);
            return "{\"success\":" + (result.Success ? "true" : "false") +
                   ",\"assetName\":\"" + JsonSafe(result.AssetName) + "\"" +
                   ",\"oldLocation\":\"" + JsonSafe(result.OldLocation) + "\"" +
                   ",\"newLocation\":\"" + JsonSafe(result.NewLocation) + "\"" +
                   (result.Error != null ? ",\"error\":\"" + JsonSafe(result.Error) + "\"" : "") +
                   "}";
        }

        private string DoReassignAll(string companyIdStr, string readerSiteStr)
        {
            int companyId = 0, readerSiteId = 0;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(readerSiteStr, out readerSiteId);

            var results = ReaderIntelligenceService.ReassignAllCandidates(companyId, readerSiteId);
            int success = 0;
            foreach (var r in results)
                if (r.Success) success++;

            return "{\"totalCount\":" + results.Count + ",\"successCount\":" + success + "}";
        }

        // ────────────────────────────────────────────────────────────
        //  READER ACTIVITY & ENNX EXPORT
        // ────────────────────────────────────────────────────────────

        private string GetReaderActivity(string companyIdStr, string daysStr, bool allSites = false)
        {
            int companyId = 0, days = 30;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(daysStr, out days);
            if (days < 1) days = 30;

            var config = ReaderIntelligenceService.LoadConfig();
            var identities = config.readerIdentities ?? new List<string> { "Web Server", "ReaderIntelligence" };
            if (identities.Count == 0) identities = new List<string> { "Web Server", "ReaderIntelligence" };

            // Build parameterized IN clause
            var inParts = new List<string>();
            var pars = new List<SqlParameter>();
            for (int i = 0; i < identities.Count; i++)
            {
                inParts.Add("@rid" + i);
                pars.Add(new SqlParameter("@rid" + i, identities[i]));
            }
            pars.Add(new SqlParameter("@days", days));

            string siteWhere = allSites ? "" : BuildSiteWhere("a", companyIdStr);

            string sql = @"
                SELECT a.id, a.name, a.description,
                       a.lastobservedlocation, l.name AS assignedLocation,
                       CONVERT(varchar, a.lastobservedtime, 120) AS lastObsStr,
                       CONVERT(varchar, a.lastmodified, 120) AS lastModStr,
                       a.lastmodifiedby,
                       c.name AS siteName, a.text8 AS cmr, a.listvalue1 AS status
                FROM dbo.asset a WITH (NOLOCK)
                LEFT JOIN dbo.location l ON l.id = a.locationid
                LEFT JOIN dbo.company c ON c.id = a.companyid
                WHERE a.lastmodifiedby IN (" + string.Join(",", inParts) + @")
                  AND a.lastobservedtime >= DATEADD(day, -@days, GETDATE())
                " + siteWhere + @"
                ORDER BY a.lastobservedtime DESC";

            var results = new List<Dictionary<string, object>>();
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 30;
                    foreach (var p in pars) cmd.Parameters.Add(p);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            results.Add(new Dictionary<string, object>
                            {
                                {"AssetId", rdr["id"]},
                                {"AssetName", rdr["name"].ToString()},
                                {"Description", rdr["description"].ToString()},
                                {"ObservedLocation", rdr["lastobservedlocation"].ToString()},
                                {"AssignedLocation", rdr["assignedLocation"] == DBNull.Value ? "" : rdr["assignedLocation"].ToString()},
                                {"LastObserved", rdr["lastObsStr"] == DBNull.Value ? "" : rdr["lastObsStr"].ToString()},
                                {"LastModified", rdr["lastModStr"] == DBNull.Value ? "" : rdr["lastModStr"].ToString()},
                                {"ModifiedBy", rdr["lastmodifiedby"].ToString()},
                                {"SiteName", rdr["siteName"] == DBNull.Value ? "" : rdr["siteName"].ToString()},
                                {"CMR", rdr["cmr"] == DBNull.Value ? "" : rdr["cmr"].ToString()},
                                {"Status", rdr["status"] == DBNull.Value ? "" : rdr["status"].ToString()}
                            });
                        }
                    }
                }
            }

            var jss = new JavaScriptSerializer();
            jss.MaxJsonLength = int.MaxValue;
            return jss.Serialize(new { assets = results, total = results.Count, identities = identities, allSites = allSites });
        }

        // ────────────────────────────────────────────────────────────
        //  LOCATION HISTORY — Movement Report
        // ────────────────────────────────────────────────────────────

        private string GetLocationHistory(string companyIdStr, string daysStr, bool allSites = false)
        {
            int companyId = 0, days = 90;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(daysStr, out days);
            if (days < 1) days = 90;

            string siteFilter = "";
            if (!allSites && companyId > 0)
                siteFilter = " AND lh.companyid = @cid";

            string sql = @"
                SELECT lh.id, lh.assetid,
                       CONVERT(varchar, lh.timeseen, 120) AS arrivalStr,
                       CASE WHEN lh.timeleft IS NOT NULL THEN CONVERT(varchar, lh.timeleft, 120) ELSE NULL END AS departureStr,
                       DATEDIFF(MINUTE, lh.timeseen, ISNULL(lh.timeleft, SYSDATETIMEOFFSET())) AS dwellMinutes,
                       a.name AS assetName, a.rfidtag,
                       l.name AS locationName,
                       c.name AS siteName,
                       a.lastmodifiedby
                FROM dbo.locationhistory lh WITH (NOLOCK)
                INNER JOIN dbo.asset a ON a.id = lh.assetid
                LEFT JOIN dbo.location l ON l.id = lh.locationid
                LEFT JOIN dbo.company c ON c.id = lh.companyid
                WHERE lh.timeseen >= DATEADD(day, -@days, GETDATE())" + siteFilter + @"
                ORDER BY lh.timeseen DESC";

            var results = new List<Dictionary<string, object>>();
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 30;
                    cmd.Parameters.AddWithValue("@days", days);
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            int dwellMin = rdr["dwellMinutes"] != DBNull.Value ? Convert.ToInt32(rdr["dwellMinutes"]) : 0;
                            string dwellStr = FormatDwell(dwellMin);
                            bool stillHere = rdr["departureStr"] == DBNull.Value || rdr["departureStr"] == null;

                            results.Add(new Dictionary<string, object>
                            {
                                {"Id", rdr["id"]},
                                {"AssetId", rdr["assetid"]},
                                {"AssetName", rdr["assetName"] == DBNull.Value ? "" : rdr["assetName"].ToString()},
                                {"Location", rdr["locationName"] == DBNull.Value ? "(unknown)" : rdr["locationName"].ToString()},
                                {"Arrival", rdr["arrivalStr"] == DBNull.Value ? "" : rdr["arrivalStr"].ToString()},
                                {"Departure", stillHere ? null : rdr["departureStr"].ToString()},
                                {"DwellMinutes", dwellMin},
                                {"DwellDisplay", dwellStr},
                                {"StillHere", stillHere},
                                {"Site", rdr["siteName"] == DBNull.Value ? "" : rdr["siteName"].ToString()},
                                {"ModifiedBy", rdr["lastmodifiedby"] == DBNull.Value ? "" : rdr["lastmodifiedby"].ToString()}
                            });
                        }
                    }
                }
            }

            var jss = new JavaScriptSerializer();
            jss.MaxJsonLength = int.MaxValue;
            return jss.Serialize(new { movements = results, total = results.Count });
        }

        private string GetAssetLocationHistory(string assetIdStr)
        {
            long assetId = 0;
            long.TryParse(assetIdStr, out assetId);

            string sql = @"
                SELECT lh.id,
                       CONVERT(varchar, lh.timeseen, 120) AS arrivalStr,
                       CASE WHEN lh.timeleft IS NOT NULL THEN CONVERT(varchar, lh.timeleft, 120) ELSE NULL END AS departureStr,
                       DATEDIFF(MINUTE, lh.timeseen, ISNULL(lh.timeleft, SYSDATETIMEOFFSET())) AS dwellMinutes,
                       l.name AS locationName,
                       c.name AS siteName
                FROM dbo.locationhistory lh WITH (NOLOCK)
                LEFT JOIN dbo.location l ON l.id = lh.locationid
                LEFT JOIN dbo.company c ON c.id = lh.companyid
                WHERE lh.assetid = @id
                ORDER BY lh.timeseen DESC";

            var results = new List<Dictionary<string, object>>();
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 15;
                    cmd.Parameters.AddWithValue("@id", assetId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            int dwellMin = rdr["dwellMinutes"] != DBNull.Value ? Convert.ToInt32(rdr["dwellMinutes"]) : 0;
                            bool stillHere = rdr["departureStr"] == DBNull.Value || rdr["departureStr"] == null;

                            results.Add(new Dictionary<string, object>
                            {
                                {"Location", rdr["locationName"] == DBNull.Value ? "(unknown)" : rdr["locationName"].ToString()},
                                {"Arrival", rdr["arrivalStr"] == DBNull.Value ? "" : rdr["arrivalStr"].ToString()},
                                {"Departure", stillHere ? null : rdr["departureStr"].ToString()},
                                {"DwellMinutes", dwellMin},
                                {"DwellDisplay", FormatDwell(dwellMin)},
                                {"StillHere", stillHere},
                                {"Site", rdr["siteName"] == DBNull.Value ? "" : rdr["siteName"].ToString()}
                            });
                        }
                    }
                }
            }

            var jss = new JavaScriptSerializer();
            return jss.Serialize(new { history = results, total = results.Count });
        }

        private string GetLocationHistoryCsv(string companyIdStr, string daysStr, bool allSites = false)
        {
            int companyId = 0, days = 90;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(daysStr, out days);
            if (days < 1) days = 90;

            string siteFilter = "";
            if (!allSites && companyId > 0)
                siteFilter = " AND lh.companyid = @cid";

            string sql = @"
                SELECT a.name AS assetName, l.name AS locationName,
                       CONVERT(varchar, lh.timeseen, 120) AS arrival,
                       CASE WHEN lh.timeleft IS NOT NULL THEN CONVERT(varchar, lh.timeleft, 120) ELSE 'Still Here' END AS departure,
                       DATEDIFF(MINUTE, lh.timeseen, ISNULL(lh.timeleft, SYSDATETIMEOFFSET())) AS dwellMinutes,
                       c.name AS siteName, a.lastmodifiedby
                FROM dbo.locationhistory lh WITH (NOLOCK)
                INNER JOIN dbo.asset a ON a.id = lh.assetid
                LEFT JOIN dbo.location l ON l.id = lh.locationid
                LEFT JOIN dbo.company c ON c.id = lh.companyid
                WHERE lh.timeseen >= DATEADD(day, -@days, GETDATE())" + siteFilter + @"
                ORDER BY lh.timeseen DESC";

            var sb = new StringBuilder();
            sb.AppendLine("Asset,Location,Arrival,Departure,Dwell,Site,Modified By");

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 30;
                    cmd.Parameters.AddWithValue("@days", days);
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            int mins = rdr["dwellMinutes"] != DBNull.Value ? Convert.ToInt32(rdr["dwellMinutes"]) : 0;
                            sb.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\",\"{5}\",\"{6}\"",
                                CsvSafe(rdr["assetName"]),
                                CsvSafe(rdr["locationName"]),
                                CsvSafe(rdr["arrival"]),
                                CsvSafe(rdr["departure"]),
                                FormatDwell(mins),
                                CsvSafe(rdr["siteName"]),
                                CsvSafe(rdr["lastmodifiedby"])));
                        }
                    }
                }
            }

            return sb.ToString();
        }

        private static string FormatDwell(int totalMinutes)
        {
            if (totalMinutes < 60) return totalMinutes + "m";
            int h = totalMinutes / 60;
            int m = totalMinutes % 60;
            if (h < 24) return h + "h " + m + "m";
            int d = h / 24;
            h = h % 24;
            return d + "d " + h + "h";
        }

        private static string CsvSafe(object val)
        {
            if (val == null || val == DBNull.Value) return "";
            return val.ToString().Replace("\"", "\"\"");
        }

        // ────────────────────────────────────────────────────────────
        //  READER EVENTS (from iDash event table)
        // ────────────────────────────────────────────────────────────

        /// <summary>
        /// Build a lookup of 3-digit site prefix -> company name.
        /// e.g. "512" -> "512 Baltimore", "613" -> "613 Martinsburg"
        /// </summary>
        private Dictionary<string, string> LoadSitePrefixMap(SqlConnection conn)
        {
            var map = new Dictionary<string, string>();
            using (var cmd = new SqlCommand("SELECT id, name FROM dbo.company", conn))
            {
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        string name = rdr["name"].ToString().Trim();
                        // Company names are like "512 Baltimore" — extract the 3-digit prefix
                        if (name.Length >= 3)
                        {
                            string prefix = name.Substring(0, 3);
                            int n;
                            if (int.TryParse(prefix, out n))
                                map[prefix] = name;
                        }
                    }
                }
            }
            return map;
        }

        private string GetReaderEvents(string daysStr)
        {
            int days = 30;
            int.TryParse(daysStr, out days);
            if (days < 1) days = 30;

            string sql = @"
                SELECT e.id, CONVERT(varchar, e.eventtime, 120) AS eventTimeStr,
                       e.rfidtag, e.readername, e.readerlocation, e.assetname,
                       e.assetdescription, e.eventtype, e.eventdetails,
                       e.antennanumber, e.rssi, e.locationname, c.name AS readerSiteName
                FROM dbo.event e WITH (NOLOCK)
                LEFT JOIN dbo.company c ON c.id = e.companyid
                WHERE e.eventtime >= DATEADD(day, -@days, GETDATE())
                ORDER BY e.eventtime DESC";

            var results = new List<Dictionary<string, object>>();
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                var sitePrefixMap = LoadSitePrefixMap(conn);

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 30;
                    cmd.Parameters.AddWithValue("@days", days);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            string rawTag = rdr["rfidtag"] == DBNull.Value ? "" : rdr["rfidtag"].ToString().Trim();

                            // Only show VA asset tags: 3-digit site + EE + digits
                            if (!Regex.IsMatch(rawTag, @"^\d{3}EE\w+", RegexOptions.IgnoreCase))
                                continue;

                            string decodedName = DecodeRfidTag(rawTag);

                            // Derive site from tag prefix, not from reader company
                            string tagPrefix = rawTag.Substring(0, 3);
                            string tagSite = "";
                            sitePrefixMap.TryGetValue(tagPrefix, out tagSite);
                            if (string.IsNullOrEmpty(tagSite)) tagSite = tagPrefix + " (Unknown)";

                            results.Add(new Dictionary<string, object>
                            {
                                {"EventId", rdr["id"]},
                                {"EventTime", rdr["eventTimeStr"] == DBNull.Value ? "" : rdr["eventTimeStr"].ToString()},
                                {"RfidTag", rawTag},
                                {"DecodedName", decodedName},
                                {"ReaderName", rdr["readername"] == DBNull.Value ? "" : rdr["readername"].ToString()},
                                {"ReaderLocation", rdr["readerlocation"] == DBNull.Value ? "" : rdr["readerlocation"].ToString()},
                                {"AssetName", rdr["assetname"] == DBNull.Value ? "" : rdr["assetname"].ToString()},
                                {"AssetDescription", rdr["assetdescription"] == DBNull.Value ? "" : rdr["assetdescription"].ToString()},
                                {"EventType", rdr["eventtype"] == DBNull.Value ? "" : rdr["eventtype"].ToString()},
                                {"EventDetails", rdr["eventdetails"] == DBNull.Value ? "" : rdr["eventdetails"].ToString()},
                                {"AntennaNumber", rdr["antennanumber"] == DBNull.Value ? "" : rdr["antennanumber"].ToString()},
                                {"RSSI", rdr["rssi"] == DBNull.Value ? "" : rdr["rssi"].ToString()},
                                {"LocationName", rdr["locationname"] == DBNull.Value ? "" : rdr["locationname"].ToString()},
                                {"SiteName", tagSite}
                            });
                        }
                    }
                }
            }

            var jss = new JavaScriptSerializer();
            jss.MaxJsonLength = int.MaxValue;
            return jss.Serialize(new { events = results, total = results.Count });
        }

        private string GetReaderEventsCsv(string daysStr)
        {
            int days = 30;
            int.TryParse(daysStr, out days);
            if (days < 1) days = 30;

            string sql = @"
                SELECT e.id, CONVERT(varchar, e.eventtime, 120) AS eventTimeStr,
                       e.rfidtag, e.readername, e.readerlocation,
                       e.eventtype, e.eventdetails, c.name AS readerSiteName
                FROM dbo.event e WITH (NOLOCK)
                LEFT JOIN dbo.company c ON c.id = e.companyid
                WHERE e.eventtime >= DATEADD(day, -@days, GETDATE())
                ORDER BY e.eventtime DESC";

            var sb = new System.Text.StringBuilder();
            sb.AppendLine("Time,RFID Tag,Decoded Name,Event Type,Details,Tag Site");

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                var sitePrefixMap = LoadSitePrefixMap(conn);

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 30;
                    cmd.Parameters.AddWithValue("@days", days);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            string rawTag = rdr["rfidtag"] == DBNull.Value ? "" : rdr["rfidtag"].ToString().Trim();
                            if (!Regex.IsMatch(rawTag, @"^\d{3}EE\w+", RegexOptions.IgnoreCase))
                                continue;

                            string decodedName = DecodeRfidTag(rawTag);
                            string tagPrefix = rawTag.Substring(0, 3);
                            string tagSite = "";
                            sitePrefixMap.TryGetValue(tagPrefix, out tagSite);
                            if (string.IsNullOrEmpty(tagSite)) tagSite = tagPrefix + " (Unknown)";

                            sb.AppendLine(string.Format("{0},{1},{2},{3},{4},{5}",
                                CsvSafe(rdr["eventTimeStr"]),
                                CsvSafe(rawTag),
                                CsvSafe(decodedName),
                                CsvSafe(rdr["eventtype"]),
                                CsvSafe(rdr["eventdetails"]),
                                CsvSafe(tagSite)
                            ));
                        }
                    }
                }
            }
            return sb.ToString();
        }

        /// <summary>
        /// Attempt to decode a raw RFID hex tag into a readable asset name.
        /// Pattern: "613EE12403FF" -> "613 EE12403"
        /// Strips trailing FF suffix and inserts space after site prefix.
        /// </summary>
        private string DecodeRfidTag(string tag)
        {
            if (string.IsNullOrEmpty(tag)) return "";
            tag = tag.Trim().ToUpper();

            // Strip trailing FF if present
            string clean = tag;
            if (clean.EndsWith("FF") && clean.Length > 4)
                clean = clean.Substring(0, clean.Length - 2);

            // Try to extract site prefix (3 digits) + space + rest
            if (clean.Length >= 4)
            {
                // Check if first 3 chars are digits (site code like 512, 613)
                string prefix = clean.Substring(0, 3);
                int siteNum;
                if (int.TryParse(prefix, out siteNum))
                {
                    string rest = clean.Substring(3);
                    return prefix + " " + rest;
                }
            }
            return tag; // Return raw if can't decode
        }

        private string GetReaderEnnx(string companyIdStr, string daysStr)
        {
            int companyId = 0, days = 30;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(daysStr, out days);
            if (days < 1) days = 30;

            var config = ReaderIntelligenceService.LoadConfig();
            var identities = config.readerIdentities ?? new List<string> { "Web Server", "ReaderIntelligence" };
            if (identities.Count == 0) identities = new List<string> { "Web Server", "ReaderIntelligence" };

            var inParts = new List<string>();
            var pars = new List<SqlParameter>();
            for (int i = 0; i < identities.Count; i++)
            {
                inParts.Add("@rid" + i);
                pars.Add(new SqlParameter("@rid" + i, identities[i]));
            }
            pars.Add(new SqlParameter("@days", days));

            string siteWhere = BuildSiteWhere("a", companyIdStr);

            string sql = @"
                SELECT a.name, a.lastobservedlocation, l.name AS assignedLocation
                FROM dbo.asset a WITH (NOLOCK)
                LEFT JOIN dbo.location l ON l.id = a.locationid
                WHERE a.lastmodifiedby IN (" + string.Join(",", inParts) + @")
                  AND a.lastobservedtime >= DATEADD(day, -@days, GETDATE())
                " + siteWhere + @"
                ORDER BY a.lastobservedlocation, a.name";

            // Build ENNX format grouped by observed location
            var sb = new StringBuilder();
            sb.AppendLine("ENNX");
            sb.AppendLine("ID");

            string currentLoc = null;
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 30;
                    foreach (var p in pars) cmd.Parameters.Add(p);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            string loc = rdr["lastobservedlocation"].ToString();
                            if (string.IsNullOrEmpty(loc)) loc = "UNKNOWN";

                            if (loc != currentLoc)
                            {
                                sb.AppendLine(loc);
                                currentLoc = loc;
                            }
                            string name = rdr["name"].ToString().Trim();
                            if (!string.IsNullOrWhiteSpace(name))
                                sb.AppendLine(name);
                        }
                    }
                }
            }

            // ---- FINAL END COUNT (MATCHES ENNX EXACTLY) ----
            // Remove trailing newline so we do not count a phantom line
            string body = sb.ToString().TrimEnd('\r', '\n');

            // Count lines exactly as ENNX will see them
            int finalLineCount = body.Split(new [] { "\r\n", "\n" }, StringSplitOptions.None).Length;

            // Rebuild output with correct END
            sb.Clear();
            sb.AppendLine(body);
            // ENNX spec: END count excludes the ENNX header line
            sb.AppendLine("***END***^" + (finalLineCount - 1));

            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  MISSING ASSET REPORT — Assets not observed by fixed readers
        // ────────────────────────────────────────────────────────────

        private string GetMissingAssets(string companyIdStr, string daysStr, bool allSites = false)
        {
            int companyId = 0, days = 90;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(daysStr, out days);
            if (days < 1) days = 90;

            string siteFilter = allSites ? "" : BuildSiteWhere("a", companyIdStr);

            // Get summary stats first
            string statsSql = @"
                SELECT
                    COUNT(*) AS totalAssets,
                    SUM(CASE WHEN a.lastobservedtime >= DATEADD(day, -@days, GETDATE()) THEN 1 ELSE 0 END) AS observedCount,
                    SUM(CASE WHEN a.lastobservedtime IS NULL OR a.lastobservedtime < DATEADD(day, -@days, GETDATE()) THEN 1 ELSE 0 END) AS missingCount
                FROM dbo.v_asset a
                WHERE a.listvalue1 = 'IN USE'" + siteFilter;

            // Get missing assets
            string sql = @"
                SELECT a.name, a.description, a.text8 AS cmr,
                       l.name AS assignedLocation,
                       CONVERT(varchar, a.lastobservedtime, 120) AS lastObsStr,
                       CASE WHEN a.lastobservedtime IS NOT NULL
                            THEN DATEDIFF(DAY, a.lastobservedtime, GETDATE())
                            ELSE NULL END AS daysSince,
                       c.name AS siteName
                FROM dbo.v_asset a
                LEFT JOIN dbo.location l ON l.id = a.locationid
                LEFT JOIN dbo.company c ON c.id = a.companyid
                WHERE a.listvalue1 = 'IN USE'
                  AND (a.lastobservedtime IS NULL OR a.lastobservedtime < DATEADD(day, -@days, GETDATE()))" + siteFilter + @"
                ORDER BY a.lastobservedtime ASC";

            int totalAssets = 0, observedCount = 0, missingCount = 0;
            var results = new List<Dictionary<string, object>>();

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Stats
                using (var cmd = new SqlCommand(statsSql, conn))
                {
                    cmd.CommandTimeout = 60;
                    cmd.Parameters.AddWithValue("@days", days);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            totalAssets = DbInt(rdr["totalAssets"]);
                            observedCount = DbInt(rdr["observedCount"]);
                            missingCount = DbInt(rdr["missingCount"]);
                        }
                    }
                }

                // Missing assets list
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 60;
                    cmd.Parameters.AddWithValue("@days", days);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            results.Add(new Dictionary<string, object>
                            {
                                {"Name", rdr["name"] == DBNull.Value ? "" : rdr["name"].ToString()},
                                {"Description", rdr["description"] == DBNull.Value ? "" : rdr["description"].ToString()},
                                {"CMR", rdr["cmr"] == DBNull.Value ? "" : rdr["cmr"].ToString()},
                                {"AssignedLocation", rdr["assignedLocation"] == DBNull.Value ? "" : rdr["assignedLocation"].ToString()},
                                {"LastObserved", rdr["lastObsStr"] == DBNull.Value ? null : rdr["lastObsStr"].ToString()},
                                {"DaysSince", rdr["daysSince"] == DBNull.Value ? (object)null : Convert.ToInt32(rdr["daysSince"])},
                                {"Site", rdr["siteName"] == DBNull.Value ? "" : rdr["siteName"].ToString()}
                            });
                        }
                    }
                }
            }

            double coveragePct = totalAssets > 0 ? Math.Round((double)observedCount / totalAssets * 100, 1) : 0;

            var jss = new JavaScriptSerializer();
            jss.MaxJsonLength = int.MaxValue;
            return jss.Serialize(new
            {
                assets = results,
                total = results.Count,
                stats = new
                {
                    totalAssets,
                    observedCount,
                    missingCount,
                    coveragePct
                }
            });
        }

        private string GetMissingAssetsCsv(string companyIdStr, string daysStr, bool allSites = false)
        {
            int companyId = 0, days = 90;
            int.TryParse(companyIdStr, out companyId);
            int.TryParse(daysStr, out days);
            if (days < 1) days = 90;

            string siteFilter = allSites ? "" : BuildSiteWhere("a", companyIdStr);

            string sql = @"
                SELECT a.name, a.description, a.text8 AS cmr,
                       l.name AS assignedLocation,
                       CONVERT(varchar, a.lastobservedtime, 120) AS lastObsStr,
                       CASE WHEN a.lastobservedtime IS NOT NULL
                            THEN DATEDIFF(DAY, a.lastobservedtime, GETDATE())
                            ELSE NULL END AS daysSince,
                       c.name AS siteName
                FROM dbo.v_asset a
                LEFT JOIN dbo.location l ON l.id = a.locationid
                LEFT JOIN dbo.company c ON c.id = a.companyid
                WHERE a.listvalue1 = 'IN USE'
                  AND (a.lastobservedtime IS NULL OR a.lastobservedtime < DATEADD(day, -@days, GETDATE()))" + siteFilter + @"
                ORDER BY a.lastobservedtime ASC";

            var sb = new StringBuilder();
            sb.AppendLine("Asset Name,Description,CMR,Assigned Location,Last Observed,Days Since,Site");

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 60;
                    cmd.Parameters.AddWithValue("@days", days);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            sb.AppendFormat("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\",{5},\"{6}\"\r\n",
                                CsvSafe(rdr["name"]),
                                CsvSafe(rdr["description"]),
                                CsvSafe(rdr["cmr"]),
                                CsvSafe(rdr["assignedLocation"]),
                                rdr["lastObsStr"] == DBNull.Value ? "Never" : rdr["lastObsStr"].ToString(),
                                rdr["daysSince"] == DBNull.Value ? "Never" : rdr["daysSince"].ToString(),
                                CsvSafe(rdr["siteName"]));
                        }
                    }
                }
            }

            return sb.ToString();
        }
    }
}
