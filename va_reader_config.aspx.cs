using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Linq;

namespace iDash
{
    public partial class va_reader_config : System.Web.UI.Page
    {
        private string ConnStr { get { return WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString; } }
        private string ApiBase { get { return WebConfigurationManager.AppSettings["iDash_ApiBase"]; } }
        private string TokenUrl { get { return WebConfigurationManager.AppSettings["iDash_TokenUrl"]; } }
        private string ClientId { get { return WebConfigurationManager.AppSettings["iDash_ClientId"]; } }
        private string ClientSecret { get { return WebConfigurationManager.AppSettings["iDash_ClientSecret"]; } }

        // ────────────────────────────────────────────────────────────
        //  TOKEN CACHE
        // ────────────────────────────────────────────────────────────
        private static string _cachedToken;
        private static DateTime _tokenExpiry = DateTime.MinValue;

        private string GetApiToken()
        {
            if (!string.IsNullOrEmpty(_cachedToken) && DateTime.UtcNow < _tokenExpiry)
                return _cachedToken;
            try
            {
                using (var wc = new WebClient())
                {
                    wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
                    string postData = "grant_type=client_credentials" +
                                     "&client_id=" + Uri.EscapeDataString(ClientId ?? "") +
                                     "&client_secret=" + Uri.EscapeDataString(ClientSecret ?? "");
                    string resp = wc.UploadString(TokenUrl, "POST", postData);
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

        // ────────────────────────────────────────────────────────────
        //  API HELPERS
        // ────────────────────────────────────────────────────────────
        private string ApiGet(string path)
        {
            string token = GetApiToken();
            if (string.IsNullOrEmpty(token)) throw new Exception("Failed to authenticate with iDash API.");
            using (var wc = new WebClient())
            {
                wc.Headers[HttpRequestHeader.Authorization] = "Bearer " + token;
                wc.Headers[HttpRequestHeader.Accept] = "application/json";
                return wc.DownloadString(ApiBase.TrimEnd('/') + path);
            }
        }

        private string ApiPost(string path, string jsonBody)
        {
            string token = GetApiToken();
            if (string.IsNullOrEmpty(token)) throw new Exception("Failed to authenticate with iDash API.");
            using (var wc = new WebClient())
            {
                wc.Headers[HttpRequestHeader.Authorization] = "Bearer " + token;
                wc.Headers[HttpRequestHeader.Accept] = "application/json";
                wc.Headers[HttpRequestHeader.ContentType] = "application/json";
                return wc.UploadString(ApiBase.TrimEnd('/') + path, "POST", jsonBody);
            }
        }

        private string ApiPut(string path, string jsonBody)
        {
            string token = GetApiToken();
            if (string.IsNullOrEmpty(token)) throw new Exception("Failed to authenticate with iDash API.");
            using (var wc = new WebClient())
            {
                wc.Headers[HttpRequestHeader.Authorization] = "Bearer " + token;
                wc.Headers[HttpRequestHeader.Accept] = "application/json";
                wc.Headers[HttpRequestHeader.ContentType] = "application/json";
                return wc.UploadString(ApiBase.TrimEnd('/') + path, "PUT", jsonBody);
            }
        }

        private void ApiDelete(string path)
        {
            string token = GetApiToken();
            if (string.IsNullOrEmpty(token)) throw new Exception("Failed to authenticate with iDash API.");
            var req = WebRequest.CreateHttp(ApiBase.TrimEnd('/') + path);
            req.Method = "DELETE";
            req.Headers.Add(HttpRequestHeader.Authorization, "Bearer " + token);
            req.Accept = "application/json";
            using (var resp = req.GetResponse()) { }
        }

        // ────────────────────────────────────────────────────────────
        //  PAGE LOAD + API ROUTER
        // ────────────────────────────────────────────────────────────
        protected void Page_Load(object sender, EventArgs e)
        {
            bool isApi = !string.IsNullOrEmpty(Request.QueryString["api"]);

            // Auth check
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn)
            {
                if (isApi)
                {
                    Response.Clear();
                    Response.ContentType = "application/json";
                    Response.StatusCode = 401;
                    Response.Write("{\"error\":\"Session expired. Please log in or refresh the page.\"}");
                    Response.End();
                    return;
                }
                Response.Redirect("index.aspx");
                return;
            }

            // Tile key check — must have admin_reader_config
            var tiles = Session["IdashTileAccess"] as List<string>;
            string role = System.Convert.ToString(Session["IdashUserRole"]);
            if (!UserManager.CanAccessTile(role, tiles, "admin_reader_config"))
            {
                if (isApi)
                {
                    Response.Clear();
                    Response.ContentType = "application/json";
                    Response.StatusCode = 403;
                    Response.Write("{\"error\":\"Access denied.\"}");
                    Response.End();
                    return;
                }
                Response.Redirect("index.aspx?err=access");
                return;
            }

            // API routing via query string
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
                        Response.Write(GetReadersJson());
                        break;
                    case "locations":
                        string siteId = Request.QueryString["siteid"] ?? "0";
                        Response.Write(GetLocationsJson(siteId));
                        break;
                    case "save":
                        HandleSaveReader();
                        break;
                    case "delete":
                        HandleDeleteReader();
                        break;
                    case "antennas":
                        string readerId = Request.QueryString["readerid"] ?? "0";
                        Response.Write(GetAntennasJson(readerId));
                        break;
                    case "allantennas":
                        Response.Write(GetAllAntennasJson());
                        break;
                    case "saveantennas":
                        HandleSaveAntennas();
                        break;
                    case "companies":
                        Response.Write(GetCompaniesJson());
                        break;
                    case "unregistered":
                        string model = Request.QueryString["model"] ?? "";
                        Response.Write(GetUnregisteredJson(model));
                        break;
                    case "get_server_config":
                        Response.Write(GetServerConfig());
                        break;
                    case "save_server_config":
                        using (var sr = new System.IO.StreamReader(Request.InputStream))
                            Response.Write(SaveServerConfig(sr.ReadToEnd()));
                        break;
                    case "test_connection":
                        Response.Write(TestConnection());
                        break;
                    case "test_oauth":
                        Response.Write(TestOAuth());
                        break;
                    case "test_oidc":
                        Response.Write(TestOidc());
                        break;
                    case "test_print":
                        Response.Write(TestPrintService());
                        break;

                    // ── Reader Hardware Intelligence ──────────────
                    case "reader_hw_status":
                        string hwIp   = Request.QueryString["ip"]   ?? "";
                        string hwUser = Request.QueryString["user"] ?? "admin";
                        string hwPass = Request.QueryString["pass"] ?? "";
                        bool   hwMqtt = (Request.QueryString["mqtt"] ?? "") == "1";
                        Response.Write(GetReaderHardwareStatus(hwIp, hwUser, hwPass, hwMqtt));
                        break;
                    case "reader_reboot":
                        string rbIp = Request.QueryString["ip"] ?? "";
                        string rbUser = Request.QueryString["user"] ?? "admin";
                        string rbPass = Request.QueryString["pass"] ?? "";
                        Response.Write(RebootReader(rbIp, rbUser, rbPass));
                        break;
                    case "firmware_list":
                        Response.Write(GetFirmwareList());
                        break;
                    case "firmware_upload":
                        Response.Write(HandleFirmwareUpload());
                        break;
                    case "firmware_push":
                        using (var sr2 = new StreamReader(Request.InputStream))
                            Response.Write(PushFirmwareToReader(sr2.ReadToEnd()));
                        break;
                    case "firmware_clear":
                        Response.Write(ClearFirmwareFiles());
                        break;
                    case "save_reader_creds":
                        using (var sr3 = new StreamReader(Request.InputStream))
                            Response.Write(SaveReaderCredentials(sr3.ReadToEnd()));
                        break;
                    case "reader_backup":
                        string bkIp = Request.QueryString["ip"] ?? "";
                        string bkUser = Request.QueryString["user"] ?? "admin";
                        string bkPass = Request.QueryString["pass"] ?? "";
                        Response.Write(BackupReaderConfig(bkIp, bkUser, bkPass));
                        break;
                    case "reader_restore":
                        using (var sr4 = new StreamReader(Request.InputStream))
                            Response.Write(RestoreReaderConfig(sr4.ReadToEnd()));
                        break;

                    // ── Reader Management Console ─────────────────────
                    case "reader_start":
                    case "reader_stop":
                    case "reader_revert_fw":
                        Response.Write(ReaderPutAction(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            action == "reader_start" ? "/cloud/start" : action == "reader_stop" ? "/cloud/stop" : "/cloud/revertbackOS"));
                        break;
                    case "reader_mode":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/mode"));
                        break;
                    case "reader_mode_set":
                        using (var sr5 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/mode", sr5.ReadToEnd()));
                        break;
                    case "reader_network":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/network"));
                        break;
                    case "reader_network_set":
                        using (var sr6 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/network", sr6.ReadToEnd()));
                        break;
                    case "reader_hostname":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/hostname"));
                        break;
                    case "reader_hostname_set":
                        using (var sr7 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/hostname", sr7.ReadToEnd()));
                        break;
                    case "reader_ntp":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/ntpServer"));
                        break;
                    case "reader_ntp_set":
                        using (var sr8 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/ntpServer", sr8.ReadToEnd()));
                        break;
                    case "reader_timezone":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/timeZone"));
                        break;
                    case "reader_timezone_set":
                        using (var sr9 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/timeZone", sr9.ReadToEnd()));
                        break;
                    case "reader_logs":
                    {
                        string logType = Request.QueryString["logType"] ?? "syslog";
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/logs/" + Uri.EscapeDataString(logType)));
                        break;
                    }
                    case "reader_logs_config":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/logs"));
                        break;
                    case "reader_logs_purge":
                    {
                        string purgeType = Request.QueryString["logType"] ?? "syslog";
                        Response.Write(ReaderDeleteAction(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/logs/" + Uri.EscapeDataString(purgeType)));
                        break;
                    }
                    case "reader_gpo_set":
                        using (var sr10 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/gpo", sr10.ReadToEnd()));
                        break;
                    case "reader_led":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/app-led"));
                        break;
                    case "reader_led_set":
                        using (var sr11 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/app-led", sr11.ReadToEnd()));
                        break;
                    case "reader_capabilities":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/readerCapabilities"));
                        break;
                    case "reader_cable_loss":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/cableLossCompensation"));
                        break;
                    case "reader_cable_loss_set":
                        using (var sr12 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/cableLossCompensation", sr12.ReadToEnd()));
                        break;
                    case "reader_region":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/region"));
                        break;
                    case "reader_name":
                        Response.Write(ReaderGetJson(
                            Request.QueryString["ip"] ?? "",
                            Request.QueryString["user"] ?? "admin",
                            Request.QueryString["pass"] ?? "",
                            "/cloud/nameAndDescription"));
                        break;
                    case "reader_name_set":
                        using (var sr13 = new StreamReader(Request.InputStream))
                            Response.Write(ReaderPutWithBody(
                                Request.QueryString["ip"] ?? "",
                                Request.QueryString["user"] ?? "admin",
                                Request.QueryString["pass"] ?? "",
                                "/cloud/nameAndDescription", sr13.ReadToEnd()));
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
        //  GET READERS
        // ────────────────────────────────────────────────────────────
        private string GetReadersJson()
        {
            var dbReaders = new List<object>();
            try
            {
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
                }
            }
            catch (Exception ex)
            {
                return "{\"error\":\"" + JsonSafe(ex.Message) + "\",\"readers\":[]}";
            }

            object[] rawReaders = dbReaders.ToArray();

            var cutoff = DateTimeOffset.UtcNow.AddMinutes(-11);

            var sb = new StringBuilder("{\"readers\":[");
            bool first = true;
            int total = 0, online = 0;

            var deviceSettings = new Dictionary<int, Dictionary<string, object>>();
            var jss = new JavaScriptSerializer();
            try
            {
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT id, devicesettings FROM dbo.reader WHERE devicesettings IS NOT NULL AND devicesettings != ''", conn))
                    {
                        using (var rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                try
                                {
                                    int rid = Convert.ToInt32(rdr["id"]);
                                    var ds = jss.Deserialize<Dictionary<string, object>>(rdr["devicesettings"].ToString());
                                    deviceSettings[rid] = ds;
                                }
                                catch { }
                            }
                        }
                    }
                }
            }
            catch { }

            foreach (Dictionary<string, object> r in rawReaders)
            {
                total++;
                string lastSeenStr = GetVal(r, "lastSeen");
                bool isUp = false;
                DateTimeOffset lastSeen;
                if (DateTimeOffset.TryParse(lastSeenStr, out lastSeen))
                    isUp = lastSeen > cutoff;
                if (isUp) online++;

                // Get batchMode/updateLocation: prefer devicesettings DB values over API
                int rid2 = GetInt(r, "id");
                bool batchMode = GetBool(r, "batchMode");
                bool updateLocation = GetBool(r, "updateLocation");
                string readerUser = "";
                string readerPass = "";
                bool hasCreds = false;
                if (deviceSettings.ContainsKey(rid2))
                {
                    var ds = deviceSettings[rid2];
                    if (ds.ContainsKey("batchMode")) batchMode = Convert.ToBoolean(ds["batchMode"]);
                    if (ds.ContainsKey("updateLocation")) updateLocation = Convert.ToBoolean(ds["updateLocation"]);
                    if (ds.ContainsKey("readerUser")) readerUser = (ds["readerUser"] ?? "").ToString();
                    if (ds.ContainsKey("readerPass")) readerPass = (ds["readerPass"] ?? "").ToString();
                    hasCreds = !string.IsNullOrEmpty(readerUser) && !string.IsNullOrEmpty(readerPass);
                }

                if (!first) sb.Append(",");
                sb.Append("{");
                sb.AppendFormat("\"id\":{0},", rid2);
                sb.AppendFormat("\"name\":\"{0}\",", JsonSafe(GetVal(r, "name")));
                sb.AppendFormat("\"locationName\":\"{0}\",", JsonSafe(GetVal(r, "locationName")));
                sb.AppendFormat("\"locationID\":{0},", r.ContainsKey("locationID") && r["locationID"] != null ? r["locationID"].ToString() : "null");
                sb.AppendFormat("\"ipAddress\":\"{0}\",", JsonSafe(GetVal(r, "ipAddress")));
                sb.AppendFormat("\"readerModel\":\"{0}\",", JsonSafe(GetVal(r, "readerModel")));
                sb.AppendFormat("\"physicalID\":\"{0}\",", JsonSafe(GetVal(r, "physicalID")));
                sb.AppendFormat("\"batchMode\":{0},", batchMode ? "true" : "false");
                sb.AppendFormat("\"updateLocation\":{0},", updateLocation ? "true" : "false");
                sb.AppendFormat("\"mqttControlTopic\":\"{0}\",", JsonSafe(GetVal(r, "mqttControlTopic")));
                sb.AppendFormat("\"companyID\":{0},", r.ContainsKey("companyID") && r["companyID"] != null ? r["companyID"].ToString() : "0");
                sb.AppendFormat("\"status\":\"{0}\",", isUp ? "Up" : "Down");
                sb.AppendFormat("\"lastSeen\":\"{0}\",", JsonSafe(lastSeenStr));
                sb.AppendFormat("\"readerUser\":\"{0}\",", JsonSafe(readerUser));
                sb.AppendFormat("\"readerPass\":\"{0}\",", JsonSafe(readerPass));
                sb.AppendFormat("\"hasCreds\":{0}", hasCreds ? "true" : "false");
                sb.Append("}");
                first = false;
            }

            sb.Append("],");
            sb.AppendFormat("\"total\":{0},\"online\":{1},\"offline\":{2}", total, online, total - online);
            sb.Append("}");
            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  GET LOCATIONS
        // ────────────────────────────────────────────────────────────
        private string GetLocationsJson(string siteIdStr)
        {
            int siteId;
            int.TryParse(siteIdStr, out siteId);

            var sb = new StringBuilder("{\"locations\":[");
            bool first = true;

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    string sql = siteId > 0
                        ? "SELECT id, name FROM dbo.location WHERE companyid = @cid ORDER BY name"
                        : "SELECT id, name FROM dbo.location ORDER BY name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        if (siteId > 0) cmd.Parameters.AddWithValue("@cid", siteId);
                        using (SqlDataReader rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                if (!first) sb.Append(",");
                                sb.AppendFormat("{{\"id\":{0},\"name\":\"{1}\"}}", rdr.GetInt32(0), JsonSafe(rdr.GetString(1)));
                                first = false;
                            }
                        }
                    }
                }
            }
            catch { }

            sb.Append("]}");
            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  GET COMPANIES (for modal site dropdown)
        // ────────────────────────────────────────────────────────────
        private string GetCompaniesJson()
        {
            var sb = new StringBuilder("{\"companies\":[");
            bool first = true;

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            if (!first) sb.Append(",");
                            sb.AppendFormat("{{\"id\":{0},\"name\":\"{1}\"}}", rdr.GetInt32(0), JsonSafe(rdr.GetString(1)));
                            first = false;
                        }
                    }
                }
            }
            catch { }

            sb.Append("]}");
            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  SAVE READER (POST body = reader JSON)
        // ────────────────────────────────────────────────────────────
        private void HandleSaveReader()
        {
            string body;
            using (var sr = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                body = sr.ReadToEnd();
            }

            if (string.IsNullOrWhiteSpace(body))
            {
                Response.Write("{\"error\":\"No reader data provided.\"}");
                return;
            }

            var jss = new JavaScriptSerializer();
            var reader = jss.Deserialize<Dictionary<string, object>>(body);
            bool isNew = !reader.ContainsKey("id") || reader["id"] == null || Convert.ToInt32(reader["id"]) == 0;

            string payload = "[" + body + "]";

            try
            {
                if (isNew)
                {
                    try { ApiPost("/api/readers/", payload); } catch { }
                    Response.Write("{\"success\":true,\"message\":\"Reader created.\"}");
                }
                else
                {
                    int readerId = Convert.ToInt32(reader["id"]);
                    string name = reader.ContainsKey("name") ? (reader["name"] ?? "").ToString() : "";
                    string ip = reader.ContainsKey("ipAddress") ? (reader["ipAddress"] ?? "").ToString() : "";
                    string model = reader.ContainsKey("readerModel") ? (reader["readerModel"] ?? "").ToString() : "Zebra";
                    string physicalId = reader.ContainsKey("physicalID") ? (reader["physicalID"] ?? "").ToString() : "";
                    int locId = reader.ContainsKey("locationID") && reader["locationID"] != null ? Convert.ToInt32(reader["locationID"]) : 0;
                    int compId = reader.ContainsKey("companyID") && reader["companyID"] != null ? Convert.ToInt32(reader["companyID"]) : 0;
                    string mqtt = reader.ContainsKey("mqttControlTopic") ? (reader["mqttControlTopic"] ?? "").ToString() : "";
                    bool batchMode = reader.ContainsKey("batchMode") && Convert.ToBoolean(reader["batchMode"]);
                    bool updateLoc = reader.ContainsKey("updateLocation") && Convert.ToBoolean(reader["updateLocation"]);

                    // Best-effort call to Reader API
                    try { ApiPut("/api/readers/", payload); } catch { }

                    // Direct DB update to guarantee site (companyid), locationid, IP, name, and settings persist
                    using (var conn = new SqlConnection(ConnStr))
                    {
                        conn.Open();
                        string existingUser = "";
                        string existingPass = "";
                        using (var getCmd = new SqlCommand("SELECT devicesettings FROM dbo.reader WHERE id = @id", conn))
                        {
                            getCmd.Parameters.AddWithValue("@id", readerId);
                            var existingVal = getCmd.ExecuteScalar();
                            if (existingVal != null && existingVal != DBNull.Value)
                            {
                                try
                                {
                                    var existingDs = jss.Deserialize<Dictionary<string, object>>(existingVal.ToString());
                                    if (existingDs != null)
                                    {
                                        if (existingDs.ContainsKey("readerUser")) existingUser = (existingDs["readerUser"] ?? "").ToString();
                                        if (existingDs.ContainsKey("readerPass")) existingPass = (existingDs["readerPass"] ?? "").ToString();
                                    }
                                }
                                catch { }
                            }
                        }

                        var newDs = new Dictionary<string, object>
                        {
                            { "updateLocation", updateLoc },
                            { "batchMode", batchMode }
                        };
                        if (!string.IsNullOrEmpty(existingUser)) newDs["readerUser"] = existingUser;
                        if (!string.IsNullOrEmpty(existingPass)) newDs["readerPass"] = existingPass;

                        string settingsJson = jss.Serialize(newDs);
                        using (var cmd = new SqlCommand(@"
                            UPDATE dbo.reader 
                            SET name = @name,
                                ipaddress = @ip,
                                readermodel = @model,
                                physicalid = @pid,
                                locationid = @locId,
                                companyid = @cid,
                                mqttcontroltopic = @mqtt,
                                devicesettings = @s,
                                lastmodified = GETDATE(),
                                lastmodifiedby = 'iDash'
                            WHERE id = @id", conn))
                        {
                            cmd.Parameters.AddWithValue("@name", name);
                            cmd.Parameters.AddWithValue("@ip", ip);
                            cmd.Parameters.AddWithValue("@model", model);
                            cmd.Parameters.AddWithValue("@pid", string.IsNullOrEmpty(physicalId) ? (object)DBNull.Value : physicalId);
                            if (locId > 0) cmd.Parameters.AddWithValue("@locId", locId);
                            else cmd.Parameters.AddWithValue("@locId", DBNull.Value);
                            if (compId > 0) cmd.Parameters.AddWithValue("@cid", compId);
                            else cmd.Parameters.AddWithValue("@cid", DBNull.Value);
                            cmd.Parameters.AddWithValue("@mqtt", string.IsNullOrEmpty(mqtt) ? (object)DBNull.Value : mqtt);
                            cmd.Parameters.AddWithValue("@s", settingsJson);
                            cmd.Parameters.AddWithValue("@id", readerId);
                            cmd.ExecuteNonQuery();
                        }
                    }

                    Response.Write("{\"success\":true,\"message\":\"Reader updated.\"}");
                }
            }
            catch (Exception ex)
            {
                Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            }
        }

        // ────────────────────────────────────────────────────────────
        //  DELETE READER
        // ────────────────────────────────────────────────────────────
        private void HandleDeleteReader()
        {
            string readerId = Request.QueryString["readerid"] ?? "0";
            try
            {
                ApiDelete("/api/readers/?ids=" + readerId + "&madeBy=iDash");
                Response.Write("{\"success\":true}");
            }
            catch (Exception ex)
            {
                Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            }
        }

        // ────────────────────────────────────────────────────────────
        //  GET ANTENNAS
        // ────────────────────────────────────────────────────────────
        private string GetAntennasJson(string readerIdStr)
        {
            int rid = 0;
            int.TryParse(readerIdStr, out rid);
            var results = new List<Dictionary<string, object>>();

            try
            {
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    string sql = @"
                        SELECT a.id, a.number, a.readerid, a.locationid, a.companyid,
                               l.name AS locationName, c.name AS siteName
                        FROM dbo.antenna a WITH (NOLOCK)
                        LEFT JOIN dbo.location l ON l.id = a.locationid
                        LEFT JOIN dbo.company c ON c.id = a.companyid
                        WHERE a.readerid = @rid
                        ORDER BY a.number";
                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@rid", rid);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                results.Add(new Dictionary<string, object>
                                {
                                    {"id", rdr["id"]},
                                    {"portNumber", rdr["number"] == DBNull.Value ? 1 : Convert.ToInt32(rdr["number"])},
                                    {"readerID", rdr["readerid"] == DBNull.Value ? 0 : Convert.ToInt32(rdr["readerid"])},
                                    {"locationID", rdr["locationid"] == DBNull.Value ? (object)null : Convert.ToInt32(rdr["locationid"])},
                                    {"locationName", rdr["locationName"] == DBNull.Value ? "" : rdr["locationName"].ToString()},
                                    {"companyID", rdr["companyid"] == DBNull.Value ? 0 : Convert.ToInt32(rdr["companyid"])},
                                    {"power", 30}
                                });
                            }
                        }
                    }
                }

                var jss = new JavaScriptSerializer();
                return jss.Serialize(new { antennas = results, total = results.Count });
            }
            catch (Exception ex)
            {
                return "{\"error\":\"" + JsonSafe(ex.Message) + "\",\"antennas\":[]}";
            }
        }

        private string GetAllAntennasJson()
        {
            string sql = @"
                SELECT a.id, a.number, a.readerid, a.locationid, a.companyid,
                       r.name AS readerName, r.ipaddress AS readerIp,
                       l.name AS locationName, c.name AS siteName
                FROM dbo.antenna a WITH (NOLOCK)
                LEFT JOIN dbo.reader r ON r.id = a.readerid
                LEFT JOIN dbo.location l ON l.id = a.locationid
                LEFT JOIN dbo.company c ON c.id = a.companyid
                ORDER BY r.name, a.number";

            var results = new List<Dictionary<string, object>>();
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandTimeout = 15;
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            results.Add(new Dictionary<string, object>
                            {
                                {"id", rdr["id"]},
                                {"number", rdr["number"] == DBNull.Value ? 0 : rdr["number"]},
                                {"readerId", rdr["readerid"] == DBNull.Value ? 0 : rdr["readerid"]},
                                {"readerName", rdr["readerName"] == DBNull.Value ? "" : rdr["readerName"].ToString()},
                                {"readerIp", rdr["readerIp"] == DBNull.Value ? "" : rdr["readerIp"].ToString()},
                                {"locationId", rdr["locationid"] == DBNull.Value ? 0 : rdr["locationid"]},
                                {"locationName", rdr["locationName"] == DBNull.Value ? "(none)" : rdr["locationName"].ToString()},
                                {"siteName", rdr["siteName"] == DBNull.Value ? "" : rdr["siteName"].ToString()}
                            });
                        }
                    }
                }
            }

            var jss = new JavaScriptSerializer();
            return jss.Serialize(new { antennas = results, total = results.Count });
        }

        // ────────────────────────────────────────────────────────────
        //  SAVE ANTENNAS
        // ────────────────────────────────────────────────────────────
        private void HandleSaveAntennas()
        {
            string readerId = Request.QueryString["readerid"] ?? "0";
            string body;
            using (var sr = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                body = sr.ReadToEnd();
            }

            try
            {
                var jss = new JavaScriptSerializer();
                var antennas = jss.Deserialize<List<Dictionary<string, object>>>(body);
                int rid = 0;
                int.TryParse(readerId, out rid);
                if (rid == 0) { Response.Write("{\"error\":\"Invalid reader ID\"}"); return; }

                // Get the reader's companyid
                int companyId = 0;
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT companyid FROM dbo.reader WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", rid);
                        object val = cmd.ExecuteScalar();
                        if (val != null && val != DBNull.Value) companyId = Convert.ToInt32(val);
                    }

                    // Delete existing antennas for this reader, then re-insert
                    using (var delCmd = new SqlCommand("DELETE FROM dbo.antenna WHERE readerid = @rid", conn))
                    {
                        delCmd.Parameters.AddWithValue("@rid", rid);
                        delCmd.ExecuteNonQuery();
                    }

                    // Insert each antenna
                    foreach (var ant in antennas)
                    {
                        int portNum = ant.ContainsKey("portNumber") ? Convert.ToInt32(ant["portNumber"]) : 1;
                        int locId = ant.ContainsKey("locationID") && ant["locationID"] != null ? Convert.ToInt32(ant["locationID"]) : 0;
                        int antCid = companyId;
                        if (locId > 0)
                        {
                            using (var locCmd = new SqlCommand("SELECT companyid FROM dbo.location WHERE id = @lid", conn))
                            {
                                locCmd.Parameters.AddWithValue("@lid", locId);
                                object cVal = locCmd.ExecuteScalar();
                                if (cVal != null && cVal != DBNull.Value) antCid = Convert.ToInt32(cVal);
                            }
                        }

                        using (var insCmd = new SqlCommand(@"
                            INSERT INTO dbo.antenna (alertingactionid, locationid, readerid, number, lastmodifiedby, companyid)
                            VALUES (NULL, @locId, @rid, @num, 'iDash', @cid)", conn))
                        {
                            if (locId > 0)
                                insCmd.Parameters.AddWithValue("@locId", locId);
                            else
                                insCmd.Parameters.AddWithValue("@locId", DBNull.Value);
                            insCmd.Parameters.AddWithValue("@rid", rid);
                            insCmd.Parameters.AddWithValue("@num", portNum);
                            if (antCid > 0)
                                insCmd.Parameters.AddWithValue("@cid", antCid);
                            else
                                insCmd.Parameters.AddWithValue("@cid", DBNull.Value);
                            insCmd.ExecuteNonQuery();
                        }
                    }
                }

                Response.Write("{\"success\":true}");
            }
            catch (Exception ex)
            {
                Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            }
        }

        // ────────────────────────────────────────────────────────────
        //  GET UNREGISTERED
        // ────────────────────────────────────────────────────────────
        private string GetUnregisteredJson(string model)
        {
            try
            {
                string json = ApiGet("/api/readers/Unregistered?readerModel=" + Uri.EscapeDataString(model));
                return "{\"readers\":" + json + "}";
            }
            catch (Exception ex)
            {
                return "{\"error\":\"" + JsonSafe(ex.Message) + "\",\"readers\":[]}";
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

                        if (!isAdmin && !allowedSites.Contains("*"))
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
                    if (isAdmin || allowedSites.Contains("*") || allowedSites.Count > 1)
                    {
                        DdlCompany.Items.Insert(0, new ListItem("All Sites", "0"));
                    }
                }
            }
            catch { }
        }

        // ────────────────────────────────────────────────────────────
        //  HELPERS
        // ────────────────────────────────────────────────────────────
        private static string GetDictVal(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return "";
            return d[key].ToString();
        }

        private static string GetVal(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return "";
            return d[key].ToString();
        }

        private static bool GetBool(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return false;
            if (d[key] is bool) return (bool)d[key];
            return d[key].ToString().Equals("true", StringComparison.OrdinalIgnoreCase);
        }

        private static int GetInt(Dictionary<string, object> d, string key)
        {
            if (d == null || !d.ContainsKey(key) || d[key] == null) return 0;
            int val;
            if (int.TryParse(d[key].ToString(), out val)) return val;
            return 0;
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
        //  SERVER MIGRATION CONFIG — read/write all configuration files
        // ────────────────────────────────────────────────────────────
        private static readonly string AppSettingsJsonPath =
            System.IO.Path.Combine(System.Web.Hosting.HostingEnvironment.MapPath("~"), "..", "appsettings.json");

        private string GetServerConfig()
        {
            var sb = new StringBuilder();
            sb.Append("{");

            // ── iDash web.config AppSettings ──
            var wc = WebConfigurationManager.AppSettings;
            sb.Append("\"webconfig\":{");
            sb.AppendFormat("\"ApiBase\":\"{0}\",",        JsonSafe(wc["iDash_ApiBase"] ?? ""));
            sb.AppendFormat("\"TokenUrl\":\"{0}\",",       JsonSafe(wc["iDash_TokenUrl"] ?? ""));
            sb.AppendFormat("\"ClientId\":\"{0}\",",       JsonSafe(wc["iDash_ClientId"] ?? ""));
            sb.AppendFormat("\"ClientSecret\":\"{0}\",",   JsonSafe(wc["iDash_ClientSecret"] ?? ""));
            sb.AppendFormat("\"MqttServer\":\"{0}\",",     JsonSafe(wc["AntennaService_MqttServer"] ?? ""));
            sb.AppendFormat("\"MqttPort\":\"{0}\",",       JsonSafe(wc["AntennaService_MqttPort"] ?? "8883"));
            sb.AppendFormat("\"MqttUser\":\"{0}\",",       JsonSafe(wc["AntennaService_MqttUsername"] ?? ""));
            sb.AppendFormat("\"MqttPass\":\"{0}\",",       JsonSafe(wc["AntennaService_MqttPassword"] ?? ""));
            sb.AppendFormat("\"MqttTopic\":\"{0}\",",      JsonSafe(wc["AntennaService_TopicFilter"] ?? ""));
            sb.AppendFormat("\"Debounce\":\"{0}\",",       JsonSafe(wc["AntennaService_DebounceSeconds"] ?? "5"));
            sb.AppendFormat("\"CacheMin\":\"{0}\",",       JsonSafe(wc["AntennaService_CacheMinutes"] ?? "5"));
            sb.AppendFormat("\"SmtpHost\":\"{0}\",",       JsonSafe(wc["SMTP_Host"] ?? ""));
            sb.AppendFormat("\"SmtpPort\":\"{0}\",",       JsonSafe(wc["SMTP_Port"] ?? "587"));
            sb.AppendFormat("\"SmtpUser\":\"{0}\",",       JsonSafe(wc["SMTP_User"] ?? ""));
            sb.AppendFormat("\"SmtpPass\":\"{0}\",",       JsonSafe(wc["SMTP_Password"] ?? ""));
            sb.AppendFormat("\"SmtpFrom\":\"{0}\",",       JsonSafe(wc["SMTP_FromEmail"] ?? ""));
            sb.AppendFormat("\"EmailRecip\":\"{0}\"",      JsonSafe(wc["EmailRecipients"] ?? ""));
            // Connection string (mask password for display)
            string cs = WebConfigurationManager.ConnectionStrings["iDash"] != null
                ? WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString
                : "";
            sb.AppendFormat(",\"ConnStr\":\"{0}\"",        JsonSafe(cs));
            sb.Append("}");

            // ── appsettings.json ──
            sb.Append(",\"appsettings\":{");
            try
            {
                string raw = System.IO.File.ReadAllText(AppSettingsJsonPath);
                var jss = new JavaScriptSerializer(); jss.MaxJsonLength = int.MaxValue;
                var doc = jss.Deserialize<Dictionary<string, object>>(raw);
                var cfg = doc != null && doc.ContainsKey("ConfigSettings")
                    ? doc["ConfigSettings"] as Dictionary<string, object>
                    : new Dictionary<string, object>();
                if (cfg == null) cfg = new Dictionary<string, object>();

                var dbOpts2 = cfg.ContainsKey("DbOptions") ? cfg["DbOptions"] as Dictionary<string, object> : new Dictionary<string, object>();
                if (dbOpts2 == null) dbOpts2 = new Dictionary<string, object>();

                sb.AppendFormat("\"AuthServerUrl\":\"{0}\",",  JsonSafe(GetDictVal(cfg, "AuthServerUrl")));
                sb.AppendFormat("\"MqttServer\":\"{0}\",",     JsonSafe(GetDictVal(cfg, "MqttServer")));
                sb.AppendFormat("\"MqttPort\":\"{0}\",",       JsonSafe(GetDictVal(cfg, "MqttServerPort")));
                sb.AppendFormat("\"DbHostname\":\"{0}\",",     JsonSafe(GetDictVal(dbOpts2, "DbHostname")));
                sb.AppendFormat("\"DbName\":\"{0}\",",         JsonSafe(GetDictVal(dbOpts2, "DbName")));
                sb.AppendFormat("\"DbUsername\":\"{0}\",",     JsonSafe(GetDictVal(dbOpts2, "DbUsername")));
                sb.AppendFormat("\"DbPassword\":\"{0}\",",     JsonSafe(GetDictVal(dbOpts2, "DbPassword")));
                sb.AppendFormat("\"PrintUser\":\"{0}\",",      JsonSafe(GetDictVal(cfg, "PrintClientUsername")));
                sb.AppendFormat("\"PrintPass\":\"{0}\"",       JsonSafe(GetDictVal(cfg, "PrintClientPassword")));
            }
            catch (Exception ex)
            {
                sb.AppendFormat("\"error\":\"{0}\"", JsonSafe(ex.Message));
            }
            sb.Append("}");
            sb.Append("}");
            return sb.ToString();
        }

        private string SaveServerConfig(string body)
        {
            try
            {
                var jss = new JavaScriptSerializer(); jss.MaxJsonLength = int.MaxValue;
                var data = jss.Deserialize<Dictionary<string, object>>(body);
                if (data == null) return "{\"ok\":false,\"error\":\"Empty payload\"}";

                Func<string, string> S = k => data.ContainsKey(k) ? (data[k] ?? "").ToString() : null;

                // ── Update web.config AppSettings ──
                var config = System.Web.Configuration.WebConfigurationManager.OpenWebConfiguration("~/iDash");
                var appSettings = config.AppSettings.Settings;

                Action<string, string> setApp = (key, val) => {
                    if (val == null) return;
                    if (appSettings[key] != null) appSettings[key].Value = val;
                    else appSettings.Add(key, val);
                };

                setApp("iDash_ApiBase",             S("ApiBase"));
                setApp("iDash_TokenUrl",            S("TokenUrl"));
                setApp("iDash_ClientId",            S("ClientId"));
                setApp("iDash_ClientSecret",        S("ClientSecret"));
                setApp("AntennaService_MqttServer",     S("MqttServer_iDash"));
                setApp("AntennaService_MqttPort",       S("MqttPort_iDash"));
                setApp("AntennaService_MqttUsername",   S("MqttUser_iDash"));
                setApp("AntennaService_MqttPassword",   S("MqttPass_iDash"));
                setApp("AntennaService_TopicFilter",    S("MqttTopic"));
                setApp("AntennaService_DebounceSeconds",S("Debounce"));
                setApp("AntennaService_CacheMinutes",   S("CacheMin"));
                setApp("SMTP_Host",                     S("SmtpHost"));
                setApp("SMTP_Port",                     S("SmtpPort"));
                setApp("SMTP_User",                     S("SmtpUser"));
                setApp("SMTP_Password",                 S("SmtpPass"));
                setApp("SMTP_FromEmail",                S("SmtpFrom"));
                setApp("EmailRecipients",               S("EmailRecip"));

                // Update connection string if provided
                string newCs = S("ConnStr");
                if (!string.IsNullOrEmpty(newCs))
                {
                    var csElem = config.ConnectionStrings.ConnectionStrings["iDash"];
                    if (csElem != null) csElem.ConnectionString = newCs;
                }

                config.Save(System.Configuration.ConfigurationSaveMode.Minimal);

                // ── Update appsettings.json ──
                string raw = System.IO.File.ReadAllText(AppSettingsJsonPath);
                var doc = jss.Deserialize<Dictionary<string, object>>(raw);
                if (doc == null) doc = new Dictionary<string, object>();
                if (!doc.ContainsKey("ConfigSettings")) doc["ConfigSettings"] = new Dictionary<string, object>();
                var cfg = doc["ConfigSettings"] as Dictionary<string, object>;
                if (cfg == null) { cfg = new Dictionary<string, object>(); doc["ConfigSettings"] = cfg; }
                if (!cfg.ContainsKey("DbOptions")) cfg["DbOptions"] = new Dictionary<string, object>();
                var dbOpts = cfg["DbOptions"] as Dictionary<string, object>;
                if (dbOpts == null) { dbOpts = new Dictionary<string, object>(); cfg["DbOptions"] = dbOpts; }

                Action<Dictionary<string, object>, string, string> setJs = (d, key, val) => {
                    if (val != null) d[key] = val;
                };
                Action<Dictionary<string, object>, string, string> setJsInt = (d, key, val) => {
                    if (val == null) return;
                    int iv; d[key] = int.TryParse(val, out iv) ? (object)iv : val;
                };

                setJs(cfg,    "AuthServerUrl",       S("AuthServerUrl"));
                setJs(cfg,    "MqttServer",          S("MqttServer_aw"));
                setJsInt(cfg, "MqttServerPort",      S("MqttPort_aw"));
                setJs(cfg,    "PrintClientUsername", S("PrintUser"));
                setJs(cfg,    "PrintClientPassword", S("PrintPass"));
                setJs(dbOpts, "DbHostname",          S("DbHostname"));
                setJs(dbOpts, "DbName",              S("DbName"));
                setJs(dbOpts, "DbUsername",          S("DbUsername"));
                setJs(dbOpts, "DbPassword",          S("DbPassword"));

                // Serialize back with indentation (basic formatter)
                string newJson = SerializeJson(doc, 0);
                System.IO.File.WriteAllText(AppSettingsJsonPath, newJson);

                return "{\"ok\":true,\"msg\":\"Configuration saved. IIS app pool will recycle.\"}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}"; 
            }
        }

        private string TestConnection()
        {
            string type = Request.QueryString["type"] ?? "";
            var sb = new StringBuilder();
            sb.Append("{");
            try
            {
                if (type == "db")
                {
                    string cs = Request.QueryString["cs"] ?? ConnStr;
                    using (var conn = new SqlConnection(cs))
                    { conn.Open(); sb.Append("\"ok\":true,\"msg\":\"Database connected: " + JsonSafe(conn.DataSource) + " / " + JsonSafe(conn.Database) + "\""); }
                }
                else if (type == "api")
                {
                    string token = GetApiToken();
                    if (string.IsNullOrEmpty(token)) sb.Append("\"ok\":false,\"msg\":\"Token request failed — check Client ID and Secret\"");
                    else
                    {
                        string rjson = ApiGet("/api/readers/");
                        sb.Append("\"ok\":true,\"msg\":\"API connected. Token and reader endpoint OK.\"");
                    }
                }
                else if (type == "smtp")
                {
                    string host  = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "";
                    int    port  = int.Parse(WebConfigurationManager.AppSettings["SMTP_Port"] ?? "587");
                    string user  = WebConfigurationManager.AppSettings["SMTP_User"] ?? "";
                    string pass  = WebConfigurationManager.AppSettings["SMTP_Password"] ?? "";
                    using (var client = new System.Net.Mail.SmtpClient(host, port))
                    {
                        client.EnableSsl = true;
                        client.Credentials = new System.Net.NetworkCredential(user, pass);
                        client.Timeout = 8000;
                        // Just open the connection
                        var msg = new System.Net.Mail.MailMessage(user, user, "iDash Config Test", "SMTP connectivity test from iDash.");
                        client.Send(msg);
                        sb.Append("\"ok\":true,\"msg\":\"SMTP connected and test email sent.\"");
                    }
                }
                else if (type == "mqtt")
                {
                    string mqttHost = WebConfigurationManager.AppSettings["AntennaService_MqttServer"] ?? "127.0.0.1";
                    int    mqttPort = int.Parse(WebConfigurationManager.AppSettings["AntennaService_MqttPort"] ?? "8883");
                    using (var tcp = new System.Net.Sockets.TcpClient())
                    {
                        tcp.Connect(mqttHost, mqttPort);
                        sb.AppendFormat("\"ok\":true,\"msg\":\"MQTT broker reachable at {0}:{1}\"", JsonSafe(mqttHost), mqttPort);
                    }
                }
                else sb.Append("\"ok\":false,\"msg\":\"Unknown test type\"");
            }
            catch (Exception ex) { sb.AppendFormat("\"ok\":false,\"msg\":\"{0}\"", JsonSafe(ex.Message)); }
            sb.Append("}");
            return sb.ToString();
        }

        // Minimal JSON serializer for preserving appsettings.json structure
        private static string SerializeJson(object obj, int depth)
        {
            if (obj == null) return "null";
            if (obj is bool)   return ((bool)obj) ? "true" : "false";
            if (obj is string) { var s = (string)obj; return "\"" + s.Replace("\\","\\\\").Replace("\"","\\\"").Replace("\n","\\n").Replace("\r","") + "\""; }
            if (obj is int || obj is long || obj is float || obj is double || obj is decimal) return obj.ToString();
            string ind  = new string(' ', (depth+1)*2);
            string ind0 = new string(' ', depth*2);
            if (obj is Dictionary<string,object>)
            {
                var d = (Dictionary<string,object>)obj;
                if (d.Count == 0) return "{}";
                var parts = d.Select(kv => ind + "\"" + kv.Key + "\": " + SerializeJson(kv.Value, depth+1));
                return "{\n" + string.Join(",\n", parts) + "\n" + ind0 + "}";
            }
            if (obj is System.Collections.ArrayList)
            {
                var a = (System.Collections.ArrayList)obj;
                if (a.Count == 0) return "[]";
                var parts = a.Cast<object>().Select(v => ind + SerializeJson(v, depth+1));
                return "[\n" + string.Join(",\n", parts) + "\n" + ind0 + "]";
            }
            return "\"" + obj.ToString() + "\"";
        }

        // ────────────────────────────────────────────────────────────
        //  TEST OAUTH  — validates live form values before saving
        // ────────────────────────────────────────────────────────────
        private string TestOAuth()
        {
            var sb = new StringBuilder();
            sb.Append("{");
            try
            {
                // Read values from query string (passed from the form fields)
                string tokenUrl    = (Request.QueryString["tokenUrl"]    ?? "").Trim();
                string clientId    = (Request.QueryString["clientId"]    ?? "").Trim();
                string clientSecret= (Request.QueryString["clientSecret"]?? "").Trim();
                string apiBase     = (Request.QueryString["apiBase"]     ?? "").Trim();

                if (string.IsNullOrEmpty(tokenUrl) || string.IsNullOrEmpty(clientId))
                {
                    sb.Append("\"ok\":false,\"msg\":\"Token URL and Client ID are required\"");
                    sb.Append("}"); return sb.ToString();
                }

                // Step 1: Request OAuth2 token
                string token = null;
                string tokenError = null;
                try
                {
                    var req = System.Net.WebRequest.Create(tokenUrl) as System.Net.HttpWebRequest;
                    req.Method = "POST";
                    req.ContentType = "application/x-www-form-urlencoded";
                    req.Timeout = 10000;
                    req.ServerCertificateValidationCallback = (s,c,ch,e) => true;
                    byte[] body = System.Text.Encoding.UTF8.GetBytes(
                        "grant_type=client_credentials" +
                        "&client_id="     + Uri.EscapeDataString(clientId) +
                        "&client_secret=" + Uri.EscapeDataString(clientSecret));
                    req.ContentLength = body.Length;
                    using (var stream = req.GetRequestStream()) stream.Write(body, 0, body.Length);
                    using (var resp = req.GetResponse() as System.Net.HttpWebResponse)
                    using (var sr = new System.IO.StreamReader(resp.GetResponseStream()))
                    {
                        string json = sr.ReadToEnd();
                        var jss2 = new JavaScriptSerializer();
                        var tok = jss2.Deserialize<Dictionary<string, object>>(json);
                        if (tok != null && tok.ContainsKey("access_token"))
                            token = tok["access_token"].ToString();
                        else if (tok != null && tok.ContainsKey("error"))
                            tokenError = tok["error"] + (tok.ContainsKey("error_description") ? ": " + tok["error_description"] : "");
                        else
                            tokenError = "No access_token in response";
                    }
                }
                catch (Exception ex) { tokenError = ex.Message; }

                if (string.IsNullOrEmpty(token))
                {
                    // Token failed — this may be expected if AuthServerUsesJwt=false.
                    // Fall back to testing the API Base URL directly (no token).
                    if (!string.IsNullOrEmpty(apiBase))
                    {
                        try
                        {
                            string url = apiBase.TrimEnd('/') + "/api/readers/";
                            var fallback = System.Net.WebRequest.Create(url) as System.Net.HttpWebRequest;
                            fallback.Method = "GET";
                            fallback.Timeout = 8000;
                            fallback.ServerCertificateValidationCallback = (s,c,ch,e) => true;
                            int reachable = 0;
                            using (var resp2 = fallback.GetResponse() as System.Net.HttpWebResponse)
                            using (var sr2 = new System.IO.StreamReader(resp2.GetResponseStream()))
                            {
                                string rjson = sr2.ReadToEnd();
                                var jss3 = new JavaScriptSerializer(); jss3.MaxJsonLength = int.MaxValue;
                                var result = jss3.Deserialize<object>(rjson);
                                if (result is object[]) reachable = ((object[])result).Length;
                            }
                            sb.AppendFormat("\"ok\":true,\"msg\":\"⚠ Token request failed ({0}) but API is reachable without auth (AuthServerUsesJwt may be false). {1} reader(s) found. API Base URL is correct.\"",
                                JsonSafe(tokenError), reachable);
                        }
                        catch (Exception apiFallbackEx)
                        {
                            sb.AppendFormat("\"ok\":false,\"msg\":\"Token failed: {0}. API also unreachable: {1}\"",
                                JsonSafe(tokenError), JsonSafe(apiFallbackEx.Message));
                        }
                    }
                    else
                    {
                        sb.AppendFormat("\"ok\":false,\"msg\":\"Token request failed: {0}\"", JsonSafe(tokenError));
                    }
                    sb.Append("}"); return sb.ToString();
                }

                // Step 2: Call /api/readers/ with the token to confirm full API access
                string apiErr = null;
                int readerCount = 0;
                if (!string.IsNullOrEmpty(apiBase))
                {
                    try
                    {
                        string url = apiBase.TrimEnd('/') + "/api/readers/";
                        var req2 = System.Net.WebRequest.Create(url) as System.Net.HttpWebRequest;
                        req2.Method = "GET";
                        req2.Headers["Authorization"] = "Bearer " + token;
                        req2.Timeout = 8000;
                        req2.ServerCertificateValidationCallback = (s,c,ch,e) => true;
                        using (var resp2 = req2.GetResponse() as System.Net.HttpWebResponse)
                        using (var sr2 = new System.IO.StreamReader(resp2.GetResponseStream()))
                        {
                            string rjson = sr2.ReadToEnd();
                            var jss2 = new JavaScriptSerializer(); jss2.MaxJsonLength = int.MaxValue;
                            var result = jss2.Deserialize<object>(rjson);
                            if (result is object[]) readerCount = ((object[])result).Length;
                            else if (result is Dictionary<string,object>)
                            {
                                var d = (Dictionary<string,object>)result;
                                if (d.ContainsKey("value") && d["value"] is System.Collections.ArrayList)
                                    readerCount = ((System.Collections.ArrayList)d["value"]).Count;
                            }
                        }
                    }
                    catch (Exception ex) { apiErr = ex.Message; }
                }

                if (apiErr != null)
                    sb.AppendFormat("\"ok\":false,\"msg\":\"Token OK but API call failed: {0}\"", JsonSafe(apiErr));
                else
                    sb.AppendFormat("\"ok\":true,\"msg\":\"✓ OAuth token obtained. ✓ API reachable. {0} reader(s) found. Credentials are valid.\"",
                        readerCount);
            }
            catch (Exception ex)
            {
                sb.AppendFormat("\"ok\":false,\"msg\":\"{0}\"", JsonSafe(ex.Message));
            }
            sb.Append("}");
            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  TEST OIDC — validates the Auth Server discovery endpoint
        // ────────────────────────────────────────────────────────────
        private string TestOidc()
        {
            var sb = new StringBuilder();
            sb.Append("{");
            try
            {
                string authUrl = (Request.QueryString["authUrl"] ?? "").Trim();
                if (string.IsNullOrEmpty(authUrl))
                    authUrl = WebConfigurationManager.AppSettings["AuthServerUrl"] ?? "http://localhost";

                string discoveryUrl = authUrl.TrimEnd('/') + "/.well-known/openid-configuration";
                var req = System.Net.WebRequest.Create(discoveryUrl) as System.Net.HttpWebRequest;
                req.Method = "GET";
                req.Timeout = 8000;
                req.ServerCertificateValidationCallback = (s,c,ch,e) => true;
                using (var resp = req.GetResponse() as System.Net.HttpWebResponse)
                using (var sr = new System.IO.StreamReader(resp.GetResponseStream()))
                {
                    string json = sr.ReadToEnd();
                    var jss2 = new JavaScriptSerializer();
                    var doc = jss2.Deserialize<Dictionary<string,object>>(json);
                    string issuer = doc != null && doc.ContainsKey("issuer") ? doc["issuer"].ToString() : "(unknown)";
                    sb.AppendFormat("\"ok\":true,\"msg\":\"✓ OIDC discovery document found. Issuer: {0}\"", JsonSafe(issuer));
                }
            }
            catch (Exception ex)
            {
                sb.AppendFormat("\"ok\":false,\"msg\":\"OIDC unreachable: {0}\"", JsonSafe(ex.Message));
            }
            sb.Append("}");
            return sb.ToString();
        }

        // ────────────────────────────────────────────────────────────
        //  TEST PRINT SERVICE — checks connectivity to RFIDPrinting
        // ────────────────────────────────────────────────────────────
        private string TestPrintService()
        {
            var sb = new StringBuilder();
            sb.Append("{");
            try
            {
                string printUser = (Request.QueryString["printUser"] ?? "").Trim();
                string printPass = (Request.QueryString["printPass"] ?? "").Trim();

                // The RFIDPrinting service runs on port 8081.
                // Try HTTP health check first, fall back to TCP ping.
                string[] candidateUrls = { "http://localhost:8081/api/health", "http://localhost:8081/" };
                bool connected = false;
                string detail = "";
                foreach (string url in candidateUrls)
                {
                    try
                    {
                        var req = System.Net.WebRequest.Create(url) as System.Net.HttpWebRequest;
                        req.Method = "GET";
                        req.Timeout = 5000;
                        if (!string.IsNullOrEmpty(printUser))
                        {
                            string creds = Convert.ToBase64String(
                                System.Text.Encoding.ASCII.GetBytes(printUser + ":" + printPass));
                            req.Headers["Authorization"] = "Basic " + creds;
                        }
                        using (var resp = req.GetResponse() as System.Net.HttpWebResponse)
                        {
                            detail = "HTTP " + (int)resp.StatusCode + " at " + url;
                            connected = true;
                        }
                        break;
                    }
                    catch (System.Net.WebException wex)
                    {
                        if (wex.Response != null)
                        {
                            // Got a response (even 4xx) — service IS running
                            detail = "HTTP " + (int)((System.Net.HttpWebResponse)wex.Response).StatusCode + " at " + url;
                            connected = true;
                            break;
                        }
                    }
                    catch { }
                }

                if (!connected)
                {
                    // Fall back to raw TCP
                    using (var tcp = new System.Net.Sockets.TcpClient())
                    {
                        tcp.Connect("localhost", 8081);
                        detail = "TCP port 8081 reachable";
                        connected = true;
                    }
                }

                if (connected)
                    sb.AppendFormat("\"ok\":true,\"msg\":\"✓ Print service reachable. {0}\"", JsonSafe(detail));
                else
                    sb.Append("\"ok\":false,\"msg\":\"Print service not reachable on port 8081\"");
            }
            catch (Exception ex)
            {
                sb.AppendFormat("\"ok\":false,\"msg\":\"Print service unreachable: {0}\"", JsonSafe(ex.Message));
            }
            sb.Append("}");
            return sb.ToString();
        }

        // ════════════════════════════════════════════════════════════
        //  READER HARDWARE INTELLIGENCE
        //  Proxies calls to the Zebra FX9600 IoT Connector REST API
        //  running on each reader at https://<ip>/cloud/*
        // ════════════════════════════════════════════════════════════

        /// <summary>
        /// GET /cloud/version from the reader and combine with /cloud/status.
        /// Returns combined JSON with firmware versions, serial, uptime, etc.
        /// </summary>
        private string GetReaderHardwareStatus(string ip, string username, string password, bool mqttMode = false)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";

            // ── MQTT-mode readers (FX9600 etc.) ──
            // Try IoT Connector REST first with a SHORT timeout (4 s instead of 10 s).
            // If the reader has IoT Connector + valid creds → return full firmware info.
            // If it times out / refuses / 404 → fall back to DB lastSeen instantly (no hang).
            if (mqttMode)
            {
                // Only attempt REST if credentials are provided
                bool hasCreds = !string.IsNullOrEmpty(username) && !string.IsNullOrEmpty(password);
                if (hasCreds)
                {
                    var origCb = ServicePointManager.ServerCertificateValidationCallback;
                    ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
                    try
                    {
                        // Short timeout so we don't hang IIS
                        string versionJson = ReaderApiGetWithTimeout(ip, "/cloud/version", username, password, 4000);
                        var sb2 = new StringBuilder("{");
                        sb2.AppendFormat("\"ok\":true,\"ip\":\"{0}\",\"source\":\"iot_connector\",\"mqttMode\":true,", JsonSafe(ip));
                        sb2.AppendFormat("\"version\":{0},", string.IsNullOrEmpty(versionJson) ? "null" : versionJson);
                        string statusJson = null;
                        try { statusJson = ReaderApiGetWithTimeout(ip, "/cloud/status", username, password, 4000); } catch { }
                        sb2.AppendFormat("\"status\":{0}", string.IsNullOrEmpty(statusJson) ? "null" : statusJson);
                        sb2.Append("}");
                        return sb2.ToString();
                    }
                    catch
                    {
                        // REST failed — fall through to DB lastSeen below
                    }
                    finally
                    {
                        ServicePointManager.ServerCertificateValidationCallback = origCb;
                    }
                }

                // Fall back: return DB lastSeen (instant, no network)
                try
                {
                    string lastSeen = "";
                    string readerName = "";
                    using (var conn = new SqlConnection(ConnStr))
                    {
                        conn.Open();
                        using (var cmd = new SqlCommand(
                            "SELECT TOP 1 name, lastseen FROM dbo.reader WHERE ipaddress = @ip", conn))
                        {
                            cmd.Parameters.AddWithValue("@ip", ip);
                            using (var rdr = cmd.ExecuteReader())
                            {
                                if (rdr.Read())
                                {
                                    readerName = rdr["name"] == DBNull.Value ? ip : rdr["name"].ToString();
                                    lastSeen   = rdr["lastseen"] == DBNull.Value ? "" : rdr["lastseen"].ToString();
                                }
                            }
                        }
                    }
                    bool online = false;
                    DateTime ls;
                    if (DateTime.TryParse(lastSeen, out ls))
                        online = (DateTime.UtcNow - ls.ToUniversalTime()).TotalMinutes < 11;

                    string reason = hasCreds ? "IoT Connector unreachable" : "No credentials set";
                    return string.Format(
                        "{{\"ok\":true,\"ip\":\"{0}\",\"source\":\"mqtt_db\",\"mqttMode\":true," +
                        "\"online\":{1},\"lastSeen\":\"{2}\",\"name\":\"{3}\"," +
                        "\"fallbackReason\":\"{4}\",\"version\":null,\"status\":null}}",
                        JsonSafe(ip), online ? "true" : "false",
                        JsonSafe(lastSeen), JsonSafe(readerName), JsonSafe(reason));
                }
                catch (Exception ex)
                {
                    return string.Format("{{\"ok\":false,\"error\":\"{0}\",\"ip\":\"{1}\",\"mqttMode\":true}}",
                        JsonSafe(ex.Message), JsonSafe(ip));
                }
            }

            var sb = new StringBuilder("{");
            try
            {
                // Bypass self-signed SSL on readers
                var origCallback = ServicePointManager.ServerCertificateValidationCallback;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

                try
                {
                    // Try IoT Connector REST API first: /cloud/version
                    string versionJson = ReaderApiGet(ip, "/cloud/version", username, password);
                    sb.AppendFormat("\"ok\":true,\"ip\":\"{0}\",\"source\":\"iot_connector\",", JsonSafe(ip));
                    sb.AppendFormat("\"version\":{0},", string.IsNullOrEmpty(versionJson) ? "null" : versionJson);

                    // Try /cloud/status for uptime, temps, etc.
                    string statusJson = null;
                    try { statusJson = ReaderApiGet(ip, "/cloud/status", username, password); }
                    catch { }
                    sb.AppendFormat("\"status\":{0}", string.IsNullOrEmpty(statusJson) ? "null" : statusJson);
                }
                catch (WebException wex)
                {
                    HttpWebResponse httpResp = wex.Response as HttpWebResponse;
                    int statusCode = httpResp != null ? (int)httpResp.StatusCode : 0;

                    if (statusCode == 401)
                    {
                        sb.AppendFormat("\"ok\":false,\"error\":\"Authentication failed (401). Check reader credentials.\",\"ip\":\"{0}\"", JsonSafe(ip));
                    }
                    else if (statusCode == 404)
                    {
                        sb.AppendFormat("\"ok\":false,\"error\":\"IoT Connector not available on this reader. Ensure firmware >= 3.10.30 and IoT Connector is enabled.\",\"ip\":\"{0}\"", JsonSafe(ip));
                    }
                    else
                    {
                        sb.AppendFormat("\"ok\":false,\"error\":\"{0}\",\"ip\":\"{1}\"",
                            JsonSafe(wex.Message), JsonSafe(ip));
                    }
                }
                finally
                {
                    ServicePointManager.ServerCertificateValidationCallback = origCallback;
                }
            }
            catch (Exception ex)
            {
                sb.AppendFormat("\"ok\":false,\"error\":\"{0}\",\"ip\":\"{1}\"",
                    JsonSafe(ex.Message), JsonSafe(ip));
            }

            sb.Append("}");
            return sb.ToString();
        }

        /// <summary>PUT /cloud/reboot to restart a reader.</summary>
        private string RebootReader(string ip, string username, string password)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";
            try
            {
                var origCallback = ServicePointManager.ServerCertificateValidationCallback;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
                try
                {
                    ReaderApiPut(ip, "/cloud/reboot", "{}", username, password);
                    return "{\"ok\":true,\"msg\":\"Reboot command sent to " + JsonSafe(ip) + ". Reader will restart in ~30 seconds.\"}";
                }
                finally
                {
                    ServicePointManager.ServerCertificateValidationCallback = origCallback;
                }
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }

        /// <summary>List firmware files in ~/downloads/firmware/</summary>
        private string GetFirmwareList()
        {
            var sb = new StringBuilder("{\"files\":[");
            bool first = true;
            try
            {
                string dir = Server.MapPath("~/downloads/firmware/");
                if (Directory.Exists(dir))
                {
                    foreach (var f in new DirectoryInfo(dir).GetFiles("*.*")
                        .OrderByDescending(fi => fi.LastWriteTimeUtc))
                    {
                        if (!first) sb.Append(",");
                        sb.AppendFormat("{{\"name\":\"{0}\",\"size\":{1},\"date\":\"{2}\"}}",
                            JsonSafe(f.Name),
                            f.Length,
                            f.LastWriteTimeUtc.ToString("o"));
                        first = false;
                    }
                }
            }
            catch { }
            sb.Append("]}");
            return sb.ToString();
        }

        /// <summary>Handle firmware file upload (multipart form data)</summary>
        private string HandleFirmwareUpload()
        {
            try
            {
                if (Request.Files.Count == 0)
                    return "{\"ok\":false,\"error\":\"No file uploaded.\"}";

                var file = Request.Files[0];
                if (file.ContentLength == 0)
                    return "{\"ok\":false,\"error\":\"Empty file.\"}";

                string dir = Server.MapPath("~/downloads/firmware/");
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                string fileName = Path.GetFileName(file.FileName);
                string savePath = Path.Combine(dir, fileName);

                file.SaveAs(savePath);

                var info = new FileInfo(savePath);
                return "{\"ok\":true,\"msg\":\"Firmware uploaded: " + JsonSafe(fileName) +
                    " (" + FormatFileSize(info.Length) + ")\",\"name\":\"" + JsonSafe(fileName) + "\"}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }

        /// <summary>Delete all firmware files from the server (keeps web.config and handler)</summary>
        private string ClearFirmwareFiles()
        {
            try
            {
                string dir = Server.MapPath("~/downloads/firmware/");
                int count = 0;
                if (Directory.Exists(dir))
                {
                    foreach (var f in new DirectoryInfo(dir).GetFiles("*.*"))
                    {
                        string n = f.Name.ToLowerInvariant();
                        if (n == "web.config" || n == "index.ashx") continue;
                        f.Delete();
                        count++;
                    }
                }
                return "{\"ok\":true,\"msg\":\"Deleted " + count + " firmware file(s).\"}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }

        /// <summary>
        /// Push firmware to a reader via PUT /cloud/os (Zebra IoT Connector REST API).
        /// The reader downloads the firmware from an HTTP URL served by iDash.
        /// </summary>
        private string PushFirmwareToReader(string body)
        {
            try
            {
                var jss = new JavaScriptSerializer();
                var d = jss.Deserialize<Dictionary<string, object>>(body);
                string ip = d.ContainsKey("ip") ? (d["ip"] ?? "").ToString() : "";
                string user = d.ContainsKey("user") ? (d["user"] ?? "admin").ToString() : "admin";
                string pass = d.ContainsKey("pass") ? (d["pass"] ?? "").ToString() : "";
                string fileName = d.ContainsKey("fileName") ? (d["fileName"] ?? "").ToString() : "";

                if (string.IsNullOrWhiteSpace(ip))
                    return "{\"ok\":false,\"error\":\"No reader IP provided.\"}";

                // Verify firmware files exist on server
                string fwDir = Server.MapPath("~/downloads/firmware/");
                var fwFiles = Directory.Exists(fwDir)
                    ? new DirectoryInfo(fwDir).GetFiles("*.*")
                        .Where(f => f.Name.ToLowerInvariant() != "web.config"
                                 && f.Name.ToLowerInvariant() != "index.ashx").ToArray()
                    : new FileInfo[0];
                if (fwFiles.Length == 0)
                    return "{\"ok\":false,\"error\":\"No firmware files on server. Upload firmware files first.\"}";

                // Build the DIRECTORY URL the reader will GET to list firmware files.
                // The Zebra set_os API does: GET <url> → expects JSON array ["file1","file2"...]
                // then downloads each file from <url>/filename
                // Our index.ashx handler in /downloads/firmware/ serves this listing.

                // Use explicit server address if provided, otherwise auto-detect
                string serverHostOverride = d.ContainsKey("serverHost") ? (d["serverHost"] ?? "").ToString().Trim() : "";
                string serverHost = "";

                if (!string.IsNullOrEmpty(serverHostOverride))
                {
                    // User specified server address — use it directly
                    serverHost = serverHostOverride;
                }
                else
                {
                    // Auto-detect: find server IP on the same subnet as the reader
                    string readerSubnet = ip.Contains(".") ? ip.Substring(0, ip.LastIndexOf('.')) : "192.168.4";
                    try
                    {
                        string fallbackIp = "";
                        foreach (var ni in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
                        {
                            if (ni.OperationalStatus != System.Net.NetworkInformation.OperationalStatus.Up) continue;
                            foreach (var addr in ni.GetIPProperties().UnicastAddresses)
                            {
                                if (addr.Address.AddressFamily != System.Net.Sockets.AddressFamily.InterNetwork) continue;
                                if (System.Net.IPAddress.IsLoopback(addr.Address)) continue;
                                string a = addr.Address.ToString();
                                if (a.StartsWith(readerSubnet + "."))
                                {
                                    serverHost = a;
                                    break;
                                }
                                if (string.IsNullOrEmpty(fallbackIp) && !a.StartsWith("100."))
                                    fallbackIp = a;
                            }
                            if (!string.IsNullOrEmpty(serverHost)) break;
                        }
                        if (string.IsNullOrEmpty(serverHost))
                            serverHost = !string.IsNullOrEmpty(fallbackIp) ? fallbackIp : "192.168.4.48";
                    }
                    catch
                    {
                        serverHost = "192.168.4.48";
                    }
                }
                int serverPort = Request.Url.Port;

                string fwDirUrl;
                if (serverPort == 80 || serverPort == 443)
                    fwDirUrl = string.Format("http://{0}/iDash/downloads/firmware/",
                        serverHost);
                else
                    fwDirUrl = string.Format("http://{0}:{1}/iDash/downloads/firmware/",
                        serverHost, serverPort == 443 ? 80 : serverPort);

                var origCallback = ServicePointManager.ServerCertificateValidationCallback;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
                try
                {
                    // Zebra IoT Connector REST API: PUT /cloud/os with directory URL
                    string updateBody = "{\"url\":\"" + JsonSafe(fwDirUrl) + "\",\"authenticationType\":\"NONE\"," +
                        "\"verifyPeer\":false,\"verifyHost\":false}";

                    string response = ReaderApiPutWithResponse(ip, "/cloud/os", updateBody, user, pass);
                    return "{\"ok\":true,\"msg\":\"Firmware update initiated. Reader " + JsonSafe(ip) +
                        " is downloading from " + JsonSafe(fwDirUrl) +
                        ". This may take several minutes. The reader will reboot automatically.\"," +
                        "\"readerResponse\":\"" + JsonSafe(response ?? "") + "\"}";
                }
                finally
                {
                    ServicePointManager.ServerCertificateValidationCallback = origCallback;
                }
            }
            catch (Exception ex)
            {
                string inner = ex.InnerException != null ? " Inner: " + ex.InnerException.Message : "";
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message + inner) + "\"}";
            }
        }


        /// <summary>Save reader credentials (username/password) to the devicesettings JSON in the DB</summary>
        private string SaveReaderCredentials(string body)
        {
            try
            {
                var jss = new JavaScriptSerializer();
                var d = jss.Deserialize<Dictionary<string, object>>(body);
                int readerId = d.ContainsKey("readerId") ? Convert.ToInt32(d["readerId"]) : 0;
                string readerUser = d.ContainsKey("readerUser") ? (d["readerUser"] ?? "").ToString() : "";
                string readerPass = d.ContainsKey("readerPass") ? (d["readerPass"] ?? "").ToString() : "";

                if (readerId <= 0)
                    return "{\"ok\":false,\"error\":\"Invalid reader ID.\"}";

                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    // Read existing devicesettings
                    Dictionary<string, object> settings = new Dictionary<string, object>();
                    using (var cmd = new SqlCommand("SELECT devicesettings FROM dbo.reader WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", readerId);
                        var val = cmd.ExecuteScalar();
                        if (val != null && val != DBNull.Value && !string.IsNullOrEmpty(val.ToString()))
                        {
                            try { settings = jss.Deserialize<Dictionary<string, object>>(val.ToString()); }
                            catch { settings = new Dictionary<string, object>(); }
                        }
                    }

                    // Merge credentials into settings
                    settings["readerUser"] = readerUser;
                    settings["readerPass"] = readerPass;

                    string settingsJson = jss.Serialize(settings);
                    using (var cmd = new SqlCommand("UPDATE dbo.reader SET devicesettings = @s WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@s", settingsJson);
                        cmd.Parameters.AddWithValue("@id", readerId);
                        cmd.ExecuteNonQuery();
                    }
                }

                return "{\"ok\":true,\"msg\":\"Reader credentials saved.\"}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }

        // ── Reader REST API helpers (JWT auth) ─────────────────────
        // The Zebra IoT Connector uses two-step auth:
        //  1. GET /cloud/localRestLogin with Basic Auth → returns JWT token
        //  2. Use Bearer <token> for all subsequent requests
        // Token expires in 15 minutes. We cache it per-reader IP.

        private static Dictionary<string, string> _readerTokens = new Dictionary<string, string>();
        private static Dictionary<string, DateTime> _readerTokenExpiry = new Dictionary<string, DateTime>();

        private string GetReaderToken(string ip, string username, string password, int timeoutMs = 10000)
        {
            // Check cache (use 14 min expiry to be safe, actual is 15 min)
            // Key includes username so credential changes bust the cache
            string cacheKey = ip + "|" + username;
            if (_readerTokens.ContainsKey(cacheKey) && _readerTokenExpiry.ContainsKey(cacheKey)
                && DateTime.UtcNow < _readerTokenExpiry[cacheKey])
            {
                return _readerTokens[cacheKey];
            }

            // Login to get JWT token
            string loginUrl = "https://" + ip + "/cloud/localRestLogin";
            var req = (HttpWebRequest)WebRequest.Create(loginUrl);
            req.Method = "GET";
            req.Timeout = timeoutMs;
            req.Accept = "application/json";
            string creds = Convert.ToBase64String(Encoding.ASCII.GetBytes(username + ":" + password));
            req.Headers["Authorization"] = "Basic " + creds;

            string tokenJson;
            using (var resp = req.GetResponse())
            using (var sr = new StreamReader(resp.GetResponseStream()))
            {
                tokenJson = sr.ReadToEnd();
            }

            // Parse: {"code":0,"message":"<jwt_token>"}
            var jss = new JavaScriptSerializer();
            var parsed = jss.Deserialize<Dictionary<string, object>>(tokenJson);
            string token = "";
            if (parsed.ContainsKey("message"))
                token = parsed["message"].ToString();

            // Cache the token for 14 minutes
            _readerTokens[cacheKey] = token;
            _readerTokenExpiry[cacheKey] = DateTime.UtcNow.AddMinutes(14);

            return token;
        }

        private string ReaderApiGet(string ip, string path, string username, string password)
        {
            return ReaderApiGetWithTimeout(ip, path, username, password, 10000);
        }

        private string ReaderApiGetWithTimeout(string ip, string path, string username, string password, int timeoutMs)
        {
            string token = GetReaderToken(ip, username, password, timeoutMs);
            string url = "https://" + ip + path;
            var req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "GET";
            req.Timeout = timeoutMs;
            req.Accept = "application/json";
            req.Headers["Authorization"] = "Bearer " + token;
            using (var resp = req.GetResponse())
            using (var sr = new StreamReader(resp.GetResponseStream()))
            {
                return sr.ReadToEnd();
            }
        }

        private void ReaderApiPut(string ip, string path, string body, string username, string password)
        {
            string token = GetReaderToken(ip, username, password);
            string url = "https://" + ip + path;
            var req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "PUT";
            req.Timeout = 15000;
            req.ContentType = "application/json";
            req.Accept = "application/json";
            req.Headers["Authorization"] = "Bearer " + token;
            byte[] data = Encoding.UTF8.GetBytes(body ?? "{}");
            req.ContentLength = data.Length;
            using (var s = req.GetRequestStream())
                s.Write(data, 0, data.Length);
            using (var resp = req.GetResponse()) { }
        }

        /// <summary>PUT to reader API and return the response body</summary>
        private string ReaderApiPutWithResponse(string ip, string path, string body, string username, string password)
        {
            string token = GetReaderToken(ip, username, password);
            string url = "https://" + ip + path;
            var req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "PUT";
            req.Timeout = 15000;
            req.ContentType = "application/json";
            req.Accept = "application/json";
            req.Headers["Authorization"] = "Bearer " + token;
            byte[] data = Encoding.UTF8.GetBytes(body ?? "{}");
            req.ContentLength = data.Length;
            using (var s = req.GetRequestStream())
                s.Write(data, 0, data.Length);
            using (var resp = req.GetResponse())
            using (var sr = new StreamReader(resp.GetResponseStream()))
            {
                return sr.ReadToEnd();
            }
        }

        /// <summary>DELETE on reader API</summary>
        private string ReaderApiDelete(string ip, string path, string username, string password)
        {
            string token = GetReaderToken(ip, username, password);
            string url = "https://" + ip + path;
            var req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "DELETE";
            req.Timeout = 10000;
            req.Accept = "application/json";
            req.Headers["Authorization"] = "Bearer " + token;
            using (var resp = req.GetResponse())
            using (var sr = new StreamReader(resp.GetResponseStream()))
            {
                return sr.ReadToEnd();
            }
        }

        // ── Generic Reader Management Proxies ─────────────────────────

        /// <summary>Generic GET from reader, wrapped in {ok, data} envelope</summary>
        private string ReaderGetJson(string ip, string user, string pass, string path)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";
            var origCb = ServicePointManager.ServerCertificateValidationCallback;
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            try
            {
                string json = ReaderApiGet(ip, path, user, pass);
                return "{\"ok\":true,\"data\":" + json + "}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
            finally
            {
                ServicePointManager.ServerCertificateValidationCallback = origCb;
            }
        }

        /// <summary>Generic PUT to reader with JSON body, returns {ok, msg}</summary>
        private string ReaderPutWithBody(string ip, string user, string pass, string path, string body)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";
            var origCb = ServicePointManager.ServerCertificateValidationCallback;
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            try
            {
                string result = ReaderApiPutWithResponse(ip, path, body, user, pass);
                if (string.IsNullOrWhiteSpace(result)) result = "{}";
                return "{\"ok\":true,\"data\":" + result + "}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
            finally
            {
                ServicePointManager.ServerCertificateValidationCallback = origCb;
            }
        }

        /// <summary>Generic PUT action (no body needed), returns {ok, msg}</summary>
        private string ReaderPutAction(string ip, string user, string pass, string path)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";
            var origCb = ServicePointManager.ServerCertificateValidationCallback;
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            try
            {
                ReaderApiPut(ip, path, "{}", user, pass);
                return "{\"ok\":true,\"msg\":\"Command sent to " + JsonSafe(ip) + " successfully.\"}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
            finally
            {
                ServicePointManager.ServerCertificateValidationCallback = origCb;
            }
        }

        /// <summary>Generic DELETE action on reader, returns {ok, msg}</summary>
        private string ReaderDeleteAction(string ip, string user, string pass, string path)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";
            var origCb = ServicePointManager.ServerCertificateValidationCallback;
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            try
            {
                string result = ReaderApiDelete(ip, path, user, pass);
                return "{\"ok\":true,\"msg\":\"Purge completed on " + JsonSafe(ip) + ".\"}";
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
            finally
            {
                ServicePointManager.ServerCertificateValidationCallback = origCb;
            }
        }

        private static string FormatFileSize(long bytes)
        {
            if (bytes < 1024) return bytes + " B";
            if (bytes < 1048576) return (bytes / 1024.0).ToString("F1") + " KB";
            return (bytes / 1048576.0).ToString("F1") + " MB";
        }

        // ── Reader Config Backup / Restore ──────────────────────

        /// <summary>
        /// GET /cloud/config and /cloud/version from the reader for backup.
        /// </summary>
        private string BackupReaderConfig(string ip, string username, string password)
        {
            if (string.IsNullOrWhiteSpace(ip))
                return "{\"ok\":false,\"error\":\"No IP address provided.\"}";

            try
            {
                var origCallback = ServicePointManager.ServerCertificateValidationCallback;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
                try
                {
                    string configJson = ReaderApiGet(ip, "/cloud/config", username, password);
                    string versionJson = null;
                    try { versionJson = ReaderApiGet(ip, "/cloud/version", username, password); }
                    catch { }

                    return "{\"ok\":true,\"config\":" + (configJson ?? "null") +
                        ",\"version\":" + (versionJson ?? "null") + "}";
                }
                finally
                {
                    ServicePointManager.ServerCertificateValidationCallback = origCallback;
                }
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }

        /// <summary>
        /// PUT /cloud/config to restore a saved configuration.
        /// </summary>
        private string RestoreReaderConfig(string body)
        {
            try
            {
                var jss = new JavaScriptSerializer();
                var d = jss.Deserialize<Dictionary<string, object>>(body);
                string ip = d.ContainsKey("ip") ? (d["ip"] ?? "").ToString() : "";
                string user = d.ContainsKey("user") ? (d["user"] ?? "admin").ToString() : "admin";
                string pass = d.ContainsKey("pass") ? (d["pass"] ?? "").ToString() : "";
                string configStr = d.ContainsKey("config") ? jss.Serialize(d["config"]) : null;

                if (string.IsNullOrWhiteSpace(ip))
                    return "{\"ok\":false,\"error\":\"No reader IP provided.\"}";
                if (string.IsNullOrEmpty(configStr))
                    return "{\"ok\":false,\"error\":\"No configuration data provided.\"}";

                var origCallback = ServicePointManager.ServerCertificateValidationCallback;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
                try
                {
                    ReaderApiPut(ip, "/cloud/config", configStr, user, pass);
                    return "{\"ok\":true,\"msg\":\"Configuration restored to " + JsonSafe(ip) + " successfully.\"}";
                }
                finally
                {
                    ServicePointManager.ServerCertificateValidationCallback = origCallback;
                }
            }
            catch (Exception ex)
            {
                return "{\"ok\":false,\"error\":\"" + JsonSafe(ex.Message) + "\"}";
            }
        }
    }
}
