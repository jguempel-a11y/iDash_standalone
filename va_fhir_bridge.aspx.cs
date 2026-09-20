using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;

public partial class va_fhir_bridge : System.Web.UI.Page
{
    // -- PATHS --------------------------------------------------
    private string FhirConfigDir
    {
        get { return Server.MapPath("~/iDash/config/fhir"); }
    }
    private string PrivateKeyPath { get { return Path.Combine(FhirConfigDir, "private.pem"); } }
    private string PublicKeyPath  { get { return Path.Combine(FhirConfigDir, "public.pem"); } }
    private string JwkPath        { get { return Path.Combine(FhirConfigDir, "public.jwk"); } }
    private string ConfigPath     { get { return Path.Combine(FhirConfigDir, "fhir_config.json"); } }
    private string LogPath        { get { return Path.Combine(FhirConfigDir, "fhir_push_log.json"); } }
    private string AemsConfigPath { get { return Path.Combine(FhirConfigDir, "aems_config.json"); } }

    private string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            if (cs == null) cs = ConfigurationManager.ConnectionStrings["iDash"];
            return cs == null ? "" : cs.ConnectionString;
        }
    }

    // -- PAGE LOAD ----------------------------------------------
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
        Response.Cache.SetNoStore();

        // ---- Authentication gate ----
        bool isAuthenticated = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        bool hasAccess = false;

        if (isAuthenticated)
        {
            string role = Convert.ToString(Session["IdashUserRole"]);
            if (role == UserManager.ROLE_ADMIN)
            {
                hasAccess = true;
            }
            else
            {
                var tiles = Session["IdashTileAccess"] as List<string>;
                hasAccess = UserManager.CanAccessTile(role, tiles, "admin_fhir_bridge")
                    || UserManager.CanAccessTile(role, tiles, "docs_arch");
            }
        }

        if (!hasAccess)
        {
            PnlAccessDenied.Visible = true;
            PnlMain.Visible = false;
            return;
        }

        PnlAccessDenied.Visible = false;
        PnlMain.Visible = true;

        if (!IsPostBack)
        {
            RefreshKeyStatus();
            LoadFhirConfig();
            LoadAemsConfig();
            LoadEnnxUsers();
            LoadCompanies();
            RefreshLog();
            UpdateModeBadge();
        }
    }

    // -- KEY STATUS ---------------------------------------------
    private void RefreshKeyStatus()
    {
        LitKeyStatus.Text = File.Exists(PrivateKeyPath)
            ? "<span class='badge-key exists'>&#10003; Found</span>"
            : "<span class='badge-key missing'>&#10007; Missing</span>";

        LitPubKeyStatus.Text = File.Exists(PublicKeyPath)
            ? "<span class='badge-key exists'>&#10003; Found</span>"
            : "<span class='badge-key missing'>&#10007; Missing</span>";

        LitJwkStatus.Text = File.Exists(JwkPath)
            ? "<span class='badge-key exists'>&#10003; Found</span>"
            : "<span class='badge-key missing'>&#10007; Missing</span>";

        // Load JWK content for display
        if (File.Exists(JwkPath))
        {
            try
            {
                string jwk = File.ReadAllText(JwkPath);
                LitJwkContent.Text = HttpUtility.HtmlEncode(jwk);
            }
            catch
            {
                LitJwkContent.Text = "(Error reading JWK file)";
            }
        }
        else
        {
            LitJwkContent.Text = "(No JWK file found. Click 'Generate RSA Key Pair' to create one.)";
        }
    }

    // -- GENERATE KEYS ------------------------------------------
    protected void BtnGenerateKeys_Click(object sender, EventArgs e)
    {
        try
        {
            // Ensure output directory exists
            if (!Directory.Exists(FhirConfigDir))
                Directory.CreateDirectory(FhirConfigDir);

            // Generate 2048-bit RSA key pair using .NET
            using (RSA rsa = RSA.Create(2048))
            {
                RSAParameters rsaParams = rsa.ExportParameters(true);

                // Export Private Key as XML (portable format for .NET Framework 4.8)
                string privateXml = rsa.ToXmlString(true);
                File.WriteAllText(PrivateKeyPath, privateXml, Encoding.UTF8);

                // Export Public Key as XML
                string publicXml = rsa.ToXmlString(false);
                File.WriteAllText(PublicKeyPath, publicXml, Encoding.UTF8);

                // Convert public key to JWK
                string jwk = BuildJwk(rsaParams);
                File.WriteAllText(JwkPath, jwk, Encoding.UTF8);
            }

            RefreshKeyStatus();
            AddLogEntry("KEYGEN", "SUCCESS", "RSA 2048-bit key pair generated. Private key, public key, and JWK created.");
            ShowMsg("RSA key pair generated successfully. JWK is ready to copy.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Key generation failed: " + HttpUtility.HtmlEncode(ex.Message), true);
            AddLogEntry("KEYGEN", "ERROR", ex.Message);
        }
    }

    private string FormatPem(byte[] keyBytes, string label)
    {
        string base64 = Convert.ToBase64String(keyBytes);
        var sb = new StringBuilder();
        sb.AppendLine("-----BEGIN " + label + "-----");
        for (int i = 0; i < base64.Length; i += 64)
        {
            int len = Math.Min(64, base64.Length - i);
            sb.AppendLine(base64.Substring(i, len));
        }
        sb.AppendLine("-----END " + label + "-----");
        return sb.ToString();
    }

    private string BuildJwk(RSAParameters rsaParams)
    {
        string n = Base64UrlEncode(rsaParams.Modulus);
        string exp = Base64UrlEncode(rsaParams.Exponent);

        // Generate a key ID from a hash of the modulus
        string kid;
        using (SHA256 sha = SHA256.Create())
        {
            byte[] hash = sha.ComputeHash(rsaParams.Modulus);
            kid = Base64UrlEncode(hash).Substring(0, 16);
        }

        var jwkObj = new Dictionary<string, object>
        {
            { "kty", "RSA" },
            { "n", n },
            { "e", exp },
            { "kid", kid },
            { "use", "sig" },
            { "alg", "RS256" }
        };

        var serializer = new JavaScriptSerializer();
        return serializer.Serialize(jwkObj);
    }

    private string Base64UrlEncode(byte[] bytes)
    {
        string b64 = Convert.ToBase64String(bytes);
        b64 = b64.TrimEnd('=');
        b64 = b64.Replace('+', '-').Replace('/', '_');
        return b64;
    }

    // -- FHIR CONFIG --------------------------------------------
    private void LoadFhirConfig()
    {
        if (!File.Exists(ConfigPath)) return;

        try
        {
            string json = File.ReadAllText(ConfigPath);
            var serializer = new JavaScriptSerializer();
            var config = serializer.Deserialize<Dictionary<string, object>>(json);

            if (config.ContainsKey("fhirBaseUrl") && config["fhirBaseUrl"] != null)
                TxtFhirBase.Text = config["fhirBaseUrl"].ToString();
            if (config.ContainsKey("tokenUrl") && config["tokenUrl"] != null)
                TxtTokenUrl.Text = config["tokenUrl"].ToString();
            if (config.ContainsKey("clientId") && config["clientId"] != null)
                TxtClientId.Text = config["clientId"].ToString();

            string mode = config.ContainsKey("mode") ? (config["mode"] ?? "").ToString() : "sandbox";
            RdoSandbox.Checked = (mode != "production");
            RdoProduction.Checked = (mode == "production");

            // Show last test result
            if (config.ContainsKey("lastTestUtc") && config["lastTestUtc"] != null)
            {
                string testTime = config["lastTestUtc"].ToString();
                string testResult = config.ContainsKey("lastTestResult") ? (config["lastTestResult"] ?? "").ToString() : "";
                string cls = testResult.StartsWith("OK") ? "ok" : "err";
                LitLastTest.Text = string.Format("<span class='{0}'>{1}</span> &mdash; <span class='mono'>{2}</span>",
                    cls, HttpUtility.HtmlEncode(testResult), HttpUtility.HtmlEncode(testTime));
            }
            else
            {
                LitLastTest.Text = "<span class='warn'>Not tested yet</span>";
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading FHIR config: " + HttpUtility.HtmlEncode(ex.Message), true);
        }
    }

    protected void BtnSaveConfig_Click(object sender, EventArgs e)
    {
        try
        {
            if (!Directory.Exists(FhirConfigDir))
                Directory.CreateDirectory(FhirConfigDir);

            var config = new Dictionary<string, object>
            {
                { "fhirBaseUrl", (TxtFhirBase.Text ?? "").Trim() },
                { "tokenUrl", (TxtTokenUrl.Text ?? "").Trim() },
                { "clientId", (TxtClientId.Text ?? "").Trim() },
                { "mode", RdoProduction.Checked ? "production" : "sandbox" },
                { "lastTestUtc", null },
                { "lastTestResult", null }
            };

            // Preserve existing test results if they exist
            if (File.Exists(ConfigPath))
            {
                var serializer2 = new JavaScriptSerializer();
                var existing = serializer2.Deserialize<Dictionary<string, object>>(File.ReadAllText(ConfigPath));
                if (existing.ContainsKey("lastTestUtc")) config["lastTestUtc"] = existing["lastTestUtc"];
                if (existing.ContainsKey("lastTestResult")) config["lastTestResult"] = existing["lastTestResult"];
            }

            var serializer = new JavaScriptSerializer();
            File.WriteAllText(ConfigPath, serializer.Serialize(config), Encoding.UTF8);

            UpdateModeBadge();
            AddLogEntry("CONFIG", "SAVED", "FHIR configuration saved.");
            ShowMsg("Configuration saved to config/fhir/fhir_config.json", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Save failed: " + HttpUtility.HtmlEncode(ex.Message), true);
        }
    }

    protected void BtnTestConnection_Click(object sender, EventArgs e)
    {
        string baseUrl = (TxtFhirBase.Text ?? "").Trim().TrimEnd('/');
        if (string.IsNullOrEmpty(baseUrl))
        {
            ShowMsg("Enter a FHIR Base URL before testing.", true);
            return;
        }

        string metadataUrl = baseUrl + "/metadata";
        string result = "";
        string capabilityJson = "";

        try
        {
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(metadataUrl);
            req.Method = "GET";
            req.Accept = "application/fhir+json";
            req.Timeout = 15000;

            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
            {
                capabilityJson = sr.ReadToEnd();
                result = "OK: " + (int)resp.StatusCode + " " + resp.StatusDescription;
                LitCapability.Text = HttpUtility.HtmlEncode(FormatJson(capabilityJson));
            }
        }
        catch (WebException wex)
        {
            if (wex.Response != null)
            {
                using (HttpWebResponse errResp = (HttpWebResponse)wex.Response)
                using (StreamReader sr = new StreamReader(errResp.GetResponseStream(), Encoding.UTF8))
                {
                    capabilityJson = sr.ReadToEnd();
                    result = "ERROR: " + (int)errResp.StatusCode + " " + errResp.StatusDescription;
                    LitCapability.Text = HttpUtility.HtmlEncode(capabilityJson);
                }
            }
            else
            {
                result = "ERROR: " + wex.Message;
                LitCapability.Text = HttpUtility.HtmlEncode(wex.ToString());
            }
        }
        catch (Exception ex)
        {
            result = "ERROR: " + ex.Message;
            LitCapability.Text = HttpUtility.HtmlEncode(ex.ToString());
        }

        // Save test result to config
        try
        {
            if (File.Exists(ConfigPath))
            {
                var serializer = new JavaScriptSerializer();
                var config = serializer.Deserialize<Dictionary<string, object>>(File.ReadAllText(ConfigPath));
                config["lastTestUtc"] = DateTime.UtcNow.ToString("o");
                config["lastTestResult"] = result;
                File.WriteAllText(ConfigPath, serializer.Serialize(config), Encoding.UTF8);
            }
        }
        catch { /* swallow config write errors during test */ }

        string cls = result.StartsWith("OK") ? "ok" : "err";
        LitLastTest.Text = string.Format("<span class='{0}'>{1}</span> &mdash; <span class='mono'>{2}</span>",
            cls, HttpUtility.HtmlEncode(result), DateTime.UtcNow.ToString("o"));

        AddLogEntry("TEST", result.StartsWith("OK") ? "SUCCESS" : "FAILED", result + " -> " + metadataUrl);
        ShowMsg("Connection test: " + result, !result.StartsWith("OK"));
    }

    private string FormatJson(string json)
    {
        // Basic JSON formatter (indentation) without adding dependencies
        try
        {
            var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            object obj = serializer.DeserializeObject(json);
            // Re-serialize won't indent, but at least it validates.
            // For display, just return the raw JSON truncated
            if (json.Length > 5000) return json.Substring(0, 5000) + "\n... (truncated)";
            return json;
        }
        catch
        {
            return json;
        }
    }

    // -- MODE BADGE ---------------------------------------------
    private void UpdateModeBadge()
    {
        bool isProd = RdoProduction.Checked;
        if (isProd)
            LitModeBadge.Text = "<span class='badge-key missing'>&#x1F3E2; PRODUCTION</span>";
        else
            LitModeBadge.Text = "<span class='badge-sandbox'>&#x1F3D6; SANDBOX</span>";
    }

    // -- COMPANY LOADER -----------------------------------------
    private void LoadCompanies()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr)) return;

            DataTable dtCompanies = new DataTable();
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    da.Fill(dtCompanies);
                }
            }

            DdlCompany.DataSource = dtCompanies;
            DdlCompany.DataTextField = "name";
            DdlCompany.DataValueField = "id";
            DdlCompany.DataBind();
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading companies: " + HttpUtility.HtmlEncode(ex.Message), true);
        }
    }

    // -- ASSET LOADER -------------------------------------------
    protected void BtnLoadAssets_Click(object sender, EventArgs e)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr))
            {
                ShowMsg("No database connection string configured.", true);
                return;
            }

            int companyId;
            if (!int.TryParse(DdlCompany.SelectedValue, out companyId))
            {
                ShowMsg("Select a valid site.", true);
                return;
            }

            DataTable dt = LoadAssetsFromSql(companyId, 200);
            RenderAssetGrid(dt);
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading assets: " + HttpUtility.HtmlEncode(ex.Message), true);
        }
    }

    private DataTable LoadAssetsFromSql(int companyId, int topN)
    {
        using (SqlConnection cn = new SqlConnection(ConnStr))
        {
            string sql = @"
                SELECT TOP (@top) 
                    a.id,
                    a.name,
                    a.description,
                    a.text3 AS serialNumber,
                    a.rfidtag,
                    a.lastobservedlocation,
                    a.text1 AS eil,
                    a.text8 AS eil_code,
                    a.lastinventoried,
                    a.disposalstatus,
                    c.name AS companyName,
                    LEFT(LTRIM(c.name), 3) AS station
                FROM dbo.asset a WITH (NOLOCK)
                LEFT JOIN dbo.company c ON a.companyid = c.id
                WHERE a.companyid = @cid
                ORDER BY a.id DESC";

            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.Add(new SqlParameter("@top", SqlDbType.Int) { Value = topN });
                cmd.Parameters.Add(new SqlParameter("@cid", SqlDbType.Int) { Value = companyId });

                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }
    }

    private void RenderAssetGrid(DataTable dt)
    {
        if (dt == null || dt.Rows.Count == 0)
        {
            LitAssetGrid.Text = "<div class='panel' style='color:var(--warn);font-weight:700;'>No assets found for this site.</div>";
            return;
        }

        StringBuilder sb = new StringBuilder();
        sb.Append("<table class='grid'>");
        sb.Append("<thead><tr>");
        sb.Append("<th class='chk-col'><input type='checkbox' class='select-all' onchange='toggleSelectAll(this)' /></th>");
        sb.Append("<th>Name</th><th>Description</th><th>Serial</th><th>Location</th><th>EIL</th><th>Last Inv.</th><th>Status</th>");
        sb.Append("</tr></thead><tbody>");

        foreach (DataRow r in dt.Rows)
        {
            string id = Safe(r, "id");
            string name = Safe(r, "name");
            string desc = Safe(r, "description");
            string serial = Safe(r, "serialNumber");
            string rfid = Safe(r, "rfidtag");
            string loc = Safe(r, "lastobservedlocation");
            string eil = Safe(r, "eil");
            string lastInv = Safe(r, "lastinventoried");
            string status = Safe(r, "disposalstatus");
            string station = Safe(r, "station");
            string locName = Safe(r, "lastobservedlocation");

            string statusDisplay = string.IsNullOrEmpty(status) ? "active" : status.ToLower();

            sb.AppendFormat("<tr>");
            sb.AppendFormat("<td class='chk-col'><input type='checkbox' class='asset-chk' value='{0}' " +
                "data-name='{1}' data-desc='{2}' data-serial='{3}' data-rfid='{4}' " +
                "data-loc='{5}' data-locname='{6}' data-lastinv='{7}' data-status='{8}' " +
                "data-station='{9}' data-model='' /></td>",
                HE(id), HE(name), HE(desc), HE(serial), HE(rfid),
                HE(loc), HE(locName), HE(lastInv), HE(statusDisplay),
                HE(station));
            sb.AppendFormat("<td class='mono'>{0}</td>", HE(name));
            sb.AppendFormat("<td>{0}</td>", HE(desc));
            sb.AppendFormat("<td class='mono'>{0}</td>", HE(serial));
            sb.AppendFormat("<td class='mono'>{0}</td>", HE(loc));
            sb.AppendFormat("<td>{0}</td>", HE(eil));
            sb.AppendFormat("<td class='mono'>{0}</td>", HE(lastInv));
            sb.AppendFormat("<td>{0}</td>", statusDisplay == "active"
                ? "<span class='ok'>Active</span>"
                : "<span class='warn'>" + HE(status) + "</span>");
            sb.Append("</tr>");
        }

        sb.Append("</tbody></table>");
        sb.AppendFormat("<div class='hint'>Showing {0} assets. Select rows to include in the FHIR Bundle.</div>", dt.Rows.Count);

        LitAssetGrid.Text = sb.ToString();
    }

    // -- FHIR BUNDLE GENERATION (SERVER-SIDE) -------------------
    protected void BtnGenerateBundle_Click(object sender, EventArgs e)
    {
        string selectedIds = (HidSelectedIds.Value ?? "").Trim();
        if (string.IsNullOrEmpty(selectedIds))
        {
            ShowMsg("No assets selected.", true);
            return;
        }

        try
        {
            string[] ids = selectedIds.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            DataTable dt = LoadAssetsByIds(ids);

            if (dt == null || dt.Rows.Count == 0)
            {
                ShowMsg("No matching assets found in database.", true);
                return;
            }

            string bundleJson = BuildFhirBundleJson(dt);
            HidFhirJson.Value = bundleJson;

            AddLogEntry("BUNDLE", "GENERATED",
                string.Format("FHIR Bundle created with {0} asset(s) from {1} selected IDs.", dt.Rows.Count, ids.Length));
            ShowMsg(string.Format("FHIR Bundle generated: {0} resources. Use 'Download JSON' to save.", dt.Rows.Count), false);
        }
        catch (Exception ex)
        {
            ShowMsg("Bundle generation failed: " + HttpUtility.HtmlEncode(ex.Message), true);
            AddLogEntry("BUNDLE", "ERROR", ex.Message);
        }
    }

    protected void BtnDownloadBundle_Click(object sender, EventArgs e)
    {
        string selectedIds = (HidSelectedIds.Value ?? "").Trim();
        if (string.IsNullOrEmpty(selectedIds))
        {
            ShowMsg("No assets selected.", true);
            return;
        }

        try
        {
            string[] ids = selectedIds.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            DataTable dt = LoadAssetsByIds(ids);

            if (dt == null || dt.Rows.Count == 0)
            {
                ShowMsg("No matching assets found.", true);
                return;
            }

            string bundleJson = BuildFhirBundleJson(dt);
            string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string fname = "fhir_bundle_" + stamp + ".json";

            Response.Clear();
            Response.ContentType = "application/fhir+json";
            Response.AddHeader("Content-Disposition", "attachment; filename=" + fname);
            Response.ContentEncoding = Encoding.UTF8;
            Response.Write(bundleJson);
            Response.End();
        }
        catch (Exception ex)
        {
            ShowMsg("Download failed: " + HttpUtility.HtmlEncode(ex.Message), true);
        }
    }

    private DataTable LoadAssetsByIds(string[] ids)
    {
        using (SqlConnection cn = new SqlConnection(ConnStr))
        {
            // Build parameterized IN clause
            StringBuilder sqlSb = new StringBuilder();
            sqlSb.Append(@"
                SELECT a.id, a.name, a.description, a.text3 AS serialNumber,
                       a.rfidtag, a.lastobservedlocation, a.text1 AS eil,
                       a.lastinventoried, a.disposalstatus,
                       c.name AS companyName, LEFT(LTRIM(c.name), 3) AS station
                FROM dbo.asset a WITH (NOLOCK)
                LEFT JOIN dbo.company c ON a.companyid = c.id
                WHERE a.id IN (");

            var paramList = new List<SqlParameter>();
            for (int i = 0; i < ids.Length; i++)
            {
                if (i > 0) sqlSb.Append(",");
                string pName = "@id" + i;
                sqlSb.Append(pName);

                int idVal;
                if (int.TryParse(ids[i].Trim(), out idVal))
                    paramList.Add(new SqlParameter(pName, SqlDbType.Int) { Value = idVal });
                else
                    paramList.Add(new SqlParameter(pName, SqlDbType.Int) { Value = 0 });
            }

            sqlSb.Append(") ORDER BY a.id");

            using (SqlCommand cmd = new SqlCommand(sqlSb.ToString(), cn))
            {
                foreach (var p in paramList) cmd.Parameters.Add(p);
                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }
    }

    private string BuildFhirBundleJson(DataTable dt)
    {
        var entries = new List<Dictionary<string, object>>();
        var locationSet = new Dictionary<string, Dictionary<string, string>>();

        foreach (DataRow r in dt.Rows)
        {
            string id = Safe(r, "id");
            string name = Safe(r, "name");
            string desc = Safe(r, "description");
            string serial = Safe(r, "serialNumber");
            string rfid = Safe(r, "rfidtag");
            string loc = Safe(r, "lastobservedlocation");
            string eil = Safe(r, "eil");
            string lastInv = Safe(r, "lastinventoried");
            string status = Safe(r, "disposalstatus");
            string station = Safe(r, "station");

            string fhirStatus = string.IsNullOrEmpty(status) || status.ToLower() == "active" ? "active" : "inactive";

            // Build Device resource
            var identifiers = new List<Dictionary<string, object>>
            {
                new Dictionary<string, object>
                {
                    { "system", "urn:oid:2.16.840.1.113883.4.349" },
                    { "value", name }
                }
            };

            // Add RFID identifier if present
            if (!string.IsNullOrEmpty(rfid))
            {
                identifiers.Add(new Dictionary<string, object>
                {
                    { "type", new Dictionary<string, object> {
                        { "coding", new[] { new Dictionary<string, object> {
                            { "system", "http://terminology.hl7.org/CodeSystem/v2-0203" },
                            { "code", "RFID" }
                        }}}
                    }},
                    { "value", rfid }
                });
            }

            var device = new Dictionary<string, object>
            {
                { "resourceType", "Device" },
                { "id", "idash-" + id },
                { "identifier", identifiers },
                { "status", fhirStatus },
                { "manufacturer", "iDash" },
                { "serialNumber", serial },
                { "deviceName", new[] { new Dictionary<string, object> {
                    { "name", string.IsNullOrEmpty(desc) ? name : desc },
                    { "type", "user-friendly-name" }
                }}},
                { "location", new Dictionary<string, object> {
                    { "reference", "Location/idash-loc-" + Uri.EscapeDataString(loc ?? "unknown") }
                }},
                { "meta", new Dictionary<string, object> {
                    { "lastUpdated", string.IsNullOrEmpty(lastInv) ? DateTime.UtcNow.ToString("o") : lastInv },
                    { "source", "iDash" }
                }}
            };

            entries.Add(new Dictionary<string, object>
            {
                { "fullUrl", "urn:uuid:device-" + id },
                { "resource", device },
                { "request", new Dictionary<string, object> {
                    { "method", "PUT" },
                    { "url", "Device/idash-" + id }
                }}
            });

            // Track unique locations
            if (!string.IsNullOrEmpty(loc) && !locationSet.ContainsKey(loc))
            {
                locationSet[loc] = new Dictionary<string, string>
                {
                    { "name", loc },
                    { "station", station }
                };
            }
        }

        // Build Location resources (prepend to entries)
        var locationEntries = new List<Dictionary<string, object>>();
        foreach (var kvp in locationSet)
        {
            string locKey = kvp.Key;
            var locInfo = kvp.Value;

            var location = new Dictionary<string, object>
            {
                { "resourceType", "Location" },
                { "id", "idash-loc-" + Uri.EscapeDataString(locKey) },
                { "identifier", new[] { new Dictionary<string, object> {
                    { "system", "urn:oid:2.16.840.1.113883.4.349" },
                    { "value", locKey }
                }}},
                { "name", locInfo["name"] },
                { "status", "active" },
                { "mode", "instance" },
                { "type", new[] { new Dictionary<string, object> {
                    { "coding", new[] { new Dictionary<string, object> {
                        { "system", "http://terminology.hl7.org/CodeSystem/v3-RoleCode" },
                        { "code", "HOSP" },
                        { "display", "Hospital" }
                    }}}
                }}},
                { "managingOrganization", new Dictionary<string, object> {
                    { "display", "VA Station " + locInfo["station"] }
                }},
                { "meta", new Dictionary<string, object> {
                    { "source", "iDash" }
                }}
            };

            locationEntries.Add(new Dictionary<string, object>
            {
                { "fullUrl", "urn:uuid:location-" + Uri.EscapeDataString(locKey) },
                { "resource", location },
                { "request", new Dictionary<string, object> {
                    { "method", "PUT" },
                    { "url", "Location/idash-loc-" + Uri.EscapeDataString(locKey) }
                }}
            });
        }

        // Combine: locations first, then devices
        locationEntries.AddRange(entries);

        var bundle = new Dictionary<string, object>
        {
            { "resourceType", "Bundle" },
            { "type", "transaction" },
            { "timestamp", DateTime.UtcNow.ToString("o") },
            { "meta", new Dictionary<string, object> {
                { "source", "iDash-FHIR-Bridge" }
            }},
            { "entry", locationEntries }
        };

        var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        return serializer.Serialize(bundle);
    }

    // -- LOG -----------------------------------------------------
    private void AddLogEntry(string category, string status, string message)
    {
        try
        {
            if (!Directory.Exists(FhirConfigDir))
                Directory.CreateDirectory(FhirConfigDir);

            var entries = new List<Dictionary<string, string>>();

            if (File.Exists(LogPath))
            {
                var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
                entries = serializer.Deserialize<List<Dictionary<string, string>>>(File.ReadAllText(LogPath))
                    ?? new List<Dictionary<string, string>>();
            }

            entries.Insert(0, new Dictionary<string, string>
            {
                { "timestamp", DateTime.UtcNow.ToString("o") },
                { "category", category },
                { "status", status },
                { "message", message }
            });

            // Keep only last 100 entries
            if (entries.Count > 100) entries.RemoveRange(100, entries.Count - 100);

            var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            File.WriteAllText(LogPath, ser.Serialize(entries), Encoding.UTF8);
        }
        catch { /* swallow log write errors */ }
    }

    protected void BtnRefreshLog_Click(object sender, EventArgs e)
    {
        RefreshLog();
        HidActiveTab.Value = "log";
    }

    protected void BtnClearLog_Click(object sender, EventArgs e)
    {
        try
        {
            if (File.Exists(LogPath))
                File.WriteAllText(LogPath, "[]", Encoding.UTF8);
            RefreshLog();
            ShowMsg("Transaction log cleared.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Error clearing log: " + HttpUtility.HtmlEncode(ex.Message), true);
        }
        HidActiveTab.Value = "log";
    }

    private void RefreshLog()
    {
        if (!File.Exists(LogPath))
        {
            LitLog.Text = "<div style='color:var(--muted)'>No log entries yet. Actions like key generation, config saves, and FHIR operations will appear here.</div>";
            return;
        }

        try
        {
            var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            var entries = serializer.Deserialize<List<Dictionary<string, string>>>(File.ReadAllText(LogPath));

            if (entries == null || entries.Count == 0)
            {
                LitLog.Text = "<div style='color:var(--muted)'>No log entries yet.</div>";
                return;
            }

            StringBuilder sb = new StringBuilder();
            foreach (var entry in entries)
            {
                string ts = entry.ContainsKey("timestamp") ? entry["timestamp"] : "";
                string cat = entry.ContainsKey("category") ? entry["category"] : "";
                string st = entry.ContainsKey("status") ? entry["status"] : "";
                string msg = entry.ContainsKey("message") ? entry["message"] : "";

                string statusCls = "ok";
                if (st.Contains("ERROR") || st.Contains("FAILED")) statusCls = "err";
                else if (st.Contains("WARN")) statusCls = "warn";

                sb.AppendFormat("<div class='log-entry'>");
                sb.AppendFormat("<span style='color:var(--muted);'>{0}</span> ", HE(ts));
                sb.AppendFormat("<span style='font-weight:700;'>[{0}]</span> ", HE(cat));
                sb.AppendFormat("<span class='{0}' style='font-weight:700;'>{1}</span> ", statusCls, HE(st));
                sb.AppendFormat("<span>{0}</span>", HE(msg));
                sb.Append("</div>");
            }

            LitLog.Text = sb.ToString();
        }
        catch (Exception ex)
        {
            LitLog.Text = "<div class='err'>Error reading log: " + HE(ex.Message) + "</div>";
        }
    }

    // -- HELPERS -------------------------------------------------
    private string Safe(DataRow r, string col)
    {
        if (!r.Table.Columns.Contains(col)) return "";
        object val = r[col];
        return (val == null || val == DBNull.Value) ? "" : val.ToString();
    }

    private string HE(string s)
    {
        return HttpUtility.HtmlEncode(s ?? "");
    }

    private void ShowMsg(string msg, bool isError)
    {
        string cls = isError ? "err" : "ok";
        LitMsg.Text = string.Format("<div class='panel' style='margin-bottom:10px;'><div class='{0}' style='font-weight:700'>{1}</div></div>", cls, msg);
    }

    // ================================================================
    // AEMS/MERS - ENNX -> VistA Push
    // ================================================================

    // -- Config Load/Save ------------------------------------------------

    private void LoadAemsConfig()
    {
        if (!File.Exists(AemsConfigPath)) return;
        try
        {
            string json = File.ReadAllText(AemsConfigPath);
            var ser = new JavaScriptSerializer();
            var config = ser.Deserialize<Dictionary<string, object>>(json);
            if (config == null) return;

            if (config.ContainsKey("vaSqlServer") && config["vaSqlServer"] != null)
                TxtVaSqlServer.Text = config["vaSqlServer"].ToString();
            if (config.ContainsKey("vaDbName") && config["vaDbName"] != null)
                TxtVaDbName.Text = config["vaDbName"].ToString();
            if (config.ContainsKey("vaDbUser") && config["vaDbUser"] != null)
                TxtVaDbUser.Text = config["vaDbUser"].ToString();
            if (config.ContainsKey("vaSharePath") && config["vaSharePath"] != null)
                TxtVaSharePath.Text = config["vaSharePath"].ToString();
        }
        catch { }
    }

    protected void BtnSaveAemsConfig_Click(object sender, EventArgs e)
    {
        try
        {
            if (!Directory.Exists(FhirConfigDir))
                Directory.CreateDirectory(FhirConfigDir);

            var config = new Dictionary<string, object>
            {
                { "vaSqlServer", (TxtVaSqlServer.Text ?? "").Trim() },
                { "vaDbName", (TxtVaDbName.Text ?? "").Trim() },
                { "vaDbUser", (TxtVaDbUser.Text ?? "").Trim() },
                { "vaSharePath", (TxtVaSharePath.Text ?? "").Trim() }
            };

            var ser = new JavaScriptSerializer();
            File.WriteAllText(AemsConfigPath, ser.Serialize(config), Encoding.UTF8);
            AddLogEntry("AEMS_CONFIG", "SAVED", "AEMS/MERS configuration saved.");
            ShowMsg("AEMS/MERS configuration saved.", false);
        }
        catch (Exception ex)
        {
            ShowMsg("Error saving AEMS config: " + HE(ex.Message), true);
        }
    }

    // -- ENNX Date / User Loaders (queries dbo.asset directly) -----------

    private void LoadEnnxUsers()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr)) return;

            using (SqlConnection cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (SqlCommand cmd = new SqlCommand(
                    @"SELECT DISTINCT ISNULL(lastmodifiedby, 'Unknown') AS UserName
                      FROM dbo.asset WITH (NOLOCK)
                      WHERE lastinventoried IS NOT NULL
                        AND lastmodifiedby IS NOT NULL
                        AND lastmodifiedby <> ''
                      ORDER BY UserName", cn))
                {
                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    DdlEnnxUser.Items.Clear();
                    DdlEnnxUser.Items.Add(new System.Web.UI.WebControls.ListItem("-- All Users --", ""));
                    foreach (DataRow row in dt.Rows)
                    {
                        string u = row["UserName"].ToString();
                        if (!string.IsNullOrWhiteSpace(u))
                            DdlEnnxUser.Items.Add(new System.Web.UI.WebControls.ListItem(u, u));
                    }
                }
            }
        }
        catch { }
    }

    protected void BtnLoadEnnxSessions_Click(object sender, EventArgs e)
    {
        LoadScanSessions();
    }

    protected void DdlEnnxUser_Changed(object sender, EventArgs e)
    {
        // Auto-load scan dates when scanner changes
        LoadScanSessions();
    }

    private void LoadScanSessions()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(ConnStr))
            {
                ShowMsg("No database connection string configured.", true);
                return;
            }

            // Date is now optional
            DateTime? filterDate = null;
            DateTime dtParsed;
            if (DateTime.TryParse(TxtEnnxDate.Text, out dtParsed))
                filterDate = dtParsed.Date;

            string selectedUser = DdlEnnxUser.SelectedValue;

            using (SqlConnection cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                // Query tagging days grouped by user, date optional
                StringBuilder sql = new StringBuilder(@"
                    SELECT TOP 50
                        CAST(lastinventoried AS date) AS TagDate,
                        ISNULL(lastmodifiedby, 'Unknown') AS Scanner,
                        COUNT(*) AS AssetCount,
                        MIN(lastinventoried) AS FirstScan,
                        MAX(lastinventoried) AS LastScan
                    FROM dbo.asset WITH (NOLOCK)
                    WHERE lastinventoried IS NOT NULL ");

                List<SqlParameter> parms = new List<SqlParameter>();

                if (filterDate.HasValue)
                {
                    sql.Append(" AND CAST(lastinventoried AS date) = @dt ");
                    parms.Add(new SqlParameter("@dt", filterDate.Value));
                }

                if (!string.IsNullOrEmpty(selectedUser))
                {
                    sql.Append(" AND lastmodifiedby = @user ");
                    parms.Add(new SqlParameter("@user", selectedUser));
                }

                sql.Append(@"
                    GROUP BY CAST(lastinventoried AS date), ISNULL(lastmodifiedby, 'Unknown')
                    ORDER BY TagDate DESC, Scanner");

                using (SqlCommand cmd = new SqlCommand(sql.ToString(), cn))
                {
                    cmd.Parameters.AddRange(parms.ToArray());
                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    GridEnnxSessions.DataSource = dt;
                    GridEnnxSessions.DataBind();

                    if (dt.Rows.Count == 0)
                    {
                        string label = string.IsNullOrEmpty(selectedUser) ? "all users" : selectedUser;
                        string dateLabel = filterDate.HasValue ? " on " + filterDate.Value.ToString("yyyy-MM-dd") : "";
                        ShowMsg("No scans found for " + label + dateLabel + ". Try a different selection.", true);
                    }
                    else
                    {
                        int totalAssets = 0;
                        foreach (DataRow r in dt.Rows) totalAssets += Convert.ToInt32(r["AssetCount"]);
                        string label = string.IsNullOrEmpty(selectedUser) ? "all users" : selectedUser;
                        ShowMsg("Found " + totalAssets + " asset(s) across " + dt.Rows.Count + " session(s) for " + label + ".", false);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading scan data: " + HE(ex.Message), true);
        }
    }

    protected void GridEnnxSessions_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
    {
        if (e.CommandName != "SelectSession") return;

        int rowIndex;
        if (!int.TryParse(e.CommandArgument.ToString(), out rowIndex)) return;

        System.Web.UI.WebControls.GridViewRow row = GridEnnxSessions.Rows[rowIndex];
        string tagDateStr = row.Cells[0].Text;
        string scanner = row.Cells[1].Text;

        DateTime tagDate;
        if (!DateTime.TryParse(tagDateStr, out tagDate)) return;

        try
        {
            using (SqlConnection cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                // Load all assets inventoried on that date by that scanner
                string sql = @"
                    SELECT
                        CAST(a.name AS nvarchar(100)) AS Name,
                        CAST(ISNULL(l.name, a.text16) AS nvarchar(100)) AS Locationname,
                        CAST(a.text6 AS nvarchar(100)) AS Previous_Location,
                        CAST(a.text16 AS nvarchar(100)) AS LocationTagged,
                        CAST(a.lastmodifiedby AS nvarchar(100)) AS Last_Modified_By,
                        CAST(a.lastinventoried AS datetime) AS LastInventoried,
                        a.id, a.rfidtag, a.description, a.assettype, a.companyid,
                        a.lastobservedlocation, a.lastobservedtime, a.checkinstatus,
                        a.text1, a.text2, a.text3, a.text4, a.text5,
                        a.text7, a.text8, a.text9, a.text10, a.text11, a.text12,
                        a.text19, a.text20, a.listvalue1
                    FROM dbo.asset a WITH (NOLOCK)
                    LEFT JOIN dbo.location l ON l.id = a.locationid
                    WHERE CAST(a.lastinventoried AS date) = @dt
                      AND ISNULL(a.lastmodifiedby, 'Unknown') = @scanner
                    ORDER BY
                        UPPER(LTRIM(RTRIM(COALESCE(a.text16, a.text6, l.name)))),
                        a.name";

                using (SqlCommand cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.Add(new SqlParameter("@dt", SqlDbType.Date) { Value = tagDate.Date });
                    cmd.Parameters.Add(new SqlParameter("@scanner", SqlDbType.NVarChar, 100) { Value = scanner });

                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    DataTable assets = new DataTable();
                    da.Fill(assets);

                    // Build ENNX text from asset data (same logic as ennx_batch)
                    string ennxText = BuildEnnxFromAssets(assets);

                    TxtEnnxPreview.Text = ennxText;
                    HidEnnxSessionId.Value = tagDate.ToString("yyyyMMdd") + "_" + scanner;

                    // Parse for stats
                    int assetCount = 0;
                    int locCount = 0;
                    ParseEnnxContent(ennxText, out assetCount, out locCount);

                    LitEnnxAssetCount.Text = assetCount.ToString();
                    LitEnnxLocCount.Text = locCount.ToString();
                    LitEnnxSessionDate.Text = tagDate.ToString("yyyy-MM-dd");

                    // Build summary bar below ENNX preview (like other ENNX pages)
                    // Extract the ^total from ***END***^N if present
                    string totalLines = "";
                    int caretIdx = ennxText.LastIndexOf("***END***^");
                    if (caretIdx >= 0)
                    {
                        string afterCaret = ennxText.Substring(caretIdx + 10).Trim();
                        int nl = afterCaret.IndexOfAny(new[] { '\r', '\n' });
                        totalLines = nl > 0 ? afterCaret.Substring(0, nl) : afterCaret;
                    }

                    LitEnnxSummaryBar.Text = string.Format(
                        "<span style='color:var(--accent);font-weight:700;'>&#x1F4CA; {0} assets</span> &nbsp;|&nbsp; " +
                        "<span style='font-weight:600;'>{1} locations</span> &nbsp;|&nbsp; " +
                        "<span>Total: <strong>^{4}</strong></span> &nbsp;|&nbsp; " +
                        "<span>Scanner: <strong>{2}</strong></span> &nbsp;|&nbsp; " +
                        "<span>Date: <strong>{3}</strong></span>",
                        assetCount, locCount, HttpUtility.HtmlEncode(scanner), tagDate.ToString("yyyy-MM-dd"),
                        string.IsNullOrEmpty(totalLines) ? (assetCount + locCount + 1).ToString() : totalLines);

                    // Store asset data in session for the push step
                    Session["EnnxPushAssets"] = assets;

                    ShowMsg("Loaded " + assetCount + " assets scanned on " + tagDate.ToString("yyyy-MM-dd") + " by " + scanner + ".", false);
                }
            }
        }
        catch (Exception ex)
        {
            ShowMsg("Error loading scan data: " + HE(ex.Message), true);
        }
    }

    /// <summary>
    /// Build ENNX text from asset DataTable (same logic as ennx_batch BuildEnnxText).
    /// Groups assets by location (text16 > text6 > location name).
    /// </summary>
    private string BuildEnnxFromAssets(DataTable dt)
    {
        DataView v = dt.DefaultView;
        v.Sort = "LocationTagged ASC, Previous_Location ASC, Locationname ASC, Name ASC";
        DataTable sorted = v.ToTable();

        StringBuilder sb = new StringBuilder();
        sb.AppendLine("ENNX");
        sb.AppendLine("ID");

        int count = 1; // Start at 1 for the ID line (matches va_ennx.aspx.cs)
        string currentLoc = "";

        foreach (DataRow r in sorted.Rows)
        {
            string loc = r["LocationTagged"] != DBNull.Value ? r["LocationTagged"].ToString().Trim() : "";
            if (string.IsNullOrWhiteSpace(loc))
                loc = r["Previous_Location"] != DBNull.Value ? r["Previous_Location"].ToString().Trim() : "";
            if (string.IsNullOrWhiteSpace(loc))
                loc = r["Locationname"] != DBNull.Value ? r["Locationname"].ToString().Trim() : "";
            if (string.IsNullOrWhiteSpace(loc))
                loc = "MISSING";

            if (!loc.Equals(currentLoc, StringComparison.OrdinalIgnoreCase))
            {
                sb.AppendLine(loc);
                currentLoc = loc;
                count++;
            }

            string name = r["Name"] != DBNull.Value ? r["Name"].ToString().Trim() : "";
            if (!string.IsNullOrEmpty(name))
            {
                sb.AppendLine(name);
                count++;
            }
        }

        sb.AppendLine("***END***^" + count);
        return sb.ToString();
    }

    // -- ENNX Parser -------------------------------------------------------

    /// <summary>
    /// Parse ENNX text to extract asset->location mappings.
    /// ENNX format: lines starting with "SP" are locations, lines with "512 EE" or "512EE" are assets.
    /// </summary>
    private Dictionary<string, string> ParseEnnxToMap(string ennxText)
    {
        var map = new Dictionary<string, string>(); // assetName -> location
        if (string.IsNullOrWhiteSpace(ennxText)) return map;

        string currentLoc = null;
        string[] lines = ennxText.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        foreach (string rawLine in lines)
        {
            string line = rawLine.Trim();
            if (string.IsNullOrEmpty(line)) continue;
            if (line == "ENNX" || line == "ID" || line.StartsWith("***END***")) continue;

            if (line.StartsWith("SP", StringComparison.OrdinalIgnoreCase))
            {
                currentLoc = line;
            }
            else if (IsAssetLine(line) && currentLoc != null)
            {
                // Store the full asset name line -> location
                if (!map.ContainsKey(line))
                    map[line] = currentLoc;
            }
        }

        return map;
    }

    private void ParseEnnxContent(string ennxText, out int assetCount, out int locCount)
    {
        assetCount = 0;
        locCount = 0;
        if (string.IsNullOrWhiteSpace(ennxText)) return;

        var locs = new HashSet<string>();
        string[] lines = ennxText.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        foreach (string rawLine in lines)
        {
            string line = rawLine.Trim();
            if (string.IsNullOrEmpty(line) || line == "ENNX" || line == "ID" || line.StartsWith("***END***")) continue;

            if (line.StartsWith("SP", StringComparison.OrdinalIgnoreCase))
            {
                locs.Add(line);
            }
            else if (IsAssetLine(line))
            {
                assetCount++;
            }
        }

        locCount = locs.Count;
    }

    /// <summary>
    /// Checks if a line is an asset line in ENNX format.
    /// Matches patterns: "NNN EE...", "NNNEE...", "NULL EE..." 
    /// Supports any VA station (512, 613, 648, etc.) and NULL prefix.
    /// Examples: "512 EE18193", "613 EE10857", "NULL EE516808"
    /// </summary>
    private bool IsAssetLine(string line)
    {
        if (string.IsNullOrEmpty(line) || line.Length < 5) return false;

        // Check for "NULL EE" prefix (assets with no station)
        if (line.StartsWith("NULL ", StringComparison.OrdinalIgnoreCase))
        {
            string afterNull = line.Substring(5).TrimStart();
            return afterNull.StartsWith("EE", StringComparison.OrdinalIgnoreCase);
        }

        // Check for digit-prefix pattern: 2-4 digits + optional space + "EE"
        int i = 0;
        while (i < line.Length && char.IsDigit(line[i])) i++;
        if (i < 2 || i > 4) return false;
        // Optional space
        if (i < line.Length && line[i] == ' ') i++;
        // Must have "EE"
        if (i + 1 >= line.Length) return false;
        return (line[i] == 'E' || line[i] == 'e') && (line[i + 1] == 'E' || line[i + 1] == 'e');
    }

    // -- Download ENNX File ------------------------------------------------

    protected void BtnAemsExportTsv_Click(object sender, EventArgs e)
    {
        string ennxText = (TxtEnnxPreview.Text ?? "").Trim();
        if (string.IsNullOrWhiteSpace(ennxText))
        {
            ShowMsg("No ENNX content loaded. Load a session first.", true);
            return;
        }

        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition", "attachment; filename=ennx_session_" + HidEnnxSessionId.Value + ".txt");
        Response.ContentEncoding = Encoding.UTF8;
        Response.Write(ennxText);
        Response.End();
    }

    // -- Push to VistA (Full Pipeline) ------------------------------------

    protected void BtnPushToVistaAems_Click(object sender, EventArgs e)
    {
        StringBuilder results = new StringBuilder();

        try
        {
            // Validate ENNX content is loaded
            string ennxText = (TxtEnnxPreview.Text ?? "").Trim();
            if (string.IsNullOrWhiteSpace(ennxText))
            {
                ShowMsg("No ENNX content loaded. Load a session first (Step 1).", true);
                return;
            }

            // Validate VA SQL connection
            string vaServer = (TxtVaSqlServer.Text ?? "").Trim();
            string vaDb = (TxtVaDbName.Text ?? "").Trim();
            string vaUser = (TxtVaDbUser.Text ?? "").Trim();
            string vaPass = (TxtVaDbPass.Text ?? "").Trim();

            if (string.IsNullOrEmpty(vaServer) || string.IsNullOrEmpty(vaDb) ||
                string.IsNullOrEmpty(vaUser) || string.IsNullOrEmpty(vaPass))
            {
                ShowMsg("Fill in all VA SQL connection fields (right panel) including password.", true);
                return;
            }

            // ── Step 1: Parse ENNX ──
            Dictionary<string, string> ennxMap = ParseEnnxToMap(ennxText);
            if (ennxMap.Count == 0)
            {
                ShowMsg("No assets found in ENNX content. Check the format.", true);
                return;
            }

            int locCount = new HashSet<string>(ennxMap.Values).Count;
            results.AppendFormat("<div class='step-ok'>&#x2705; Step 1: Parsed {0} assets across {1} locations from ENNX</div>", ennxMap.Count, locCount);
            AddLogEntry("AEMS_PUSH", "INFO", "Step 1: Parsed " + ennxMap.Count + " assets from ENNX session #" + HidEnnxSessionId.Value);

            // ── Step 2: Match assets in local iDash DB ──
            DateTime invStamp = DateTime.UtcNow;
            int matched = 0;
            int skipped = 0;

            // Build a list of the asset numbers for matching
            // ENNX lines like "512 EE12345" -> extract the number after "EE"
            var assetUpdates = new List<Dictionary<string, string>>();

            using (SqlConnection localCn = new SqlConnection(ConnStr))
            {
                localCn.Open();

                foreach (var kvp in ennxMap)
                {
                    string assetLine = kvp.Key;
                    string newLocation = kvp.Value;

                    // Extract asset number from line (e.g., "512 EE12345" -> "12345")
                    int eeIdx = assetLine.IndexOf("EE", StringComparison.OrdinalIgnoreCase);
                    if (eeIdx < 0) { skipped++; continue; }

                    string numPart = assetLine.Substring(eeIdx + 2).Trim().Replace(" ", "");
                    int assetNum;
                    if (!int.TryParse(numPart, out assetNum)) { skipped++; continue; }

                    // Find asset in local DB by matching name pattern
                    using (SqlCommand findCmd = new SqlCommand(@"
                        SELECT TOP 1 id, name, rfidtag, companyid,
                               lastobservedlocation, lastobservedtime, lastinventoried,
                               text1, text2, text3, text4, text5, text6, text7,
                               text8, text9, text10, text11, text12,
                               text19, text20, assettype, checkinstatus,
                               description, listvalue1
                        FROM dbo.asset WITH (NOLOCK)
                        WHERE name LIKE @pattern", localCn))
                    {
                        findCmd.Parameters.Add(new SqlParameter("@pattern", SqlDbType.NVarChar, 100) { Value = "%EE" + assetNum.ToString() });

                        using (SqlDataReader rdr = findCmd.ExecuteReader())
                        {
                            if (rdr.Read())
                            {
                                var row = new Dictionary<string, string>();
                                row["id"] = rdr["id"] != DBNull.Value ? rdr["id"].ToString() : "";
                                row["name"] = rdr["name"] != DBNull.Value ? rdr["name"].ToString() : "";
                                row["description"] = rdr["description"] != DBNull.Value ? rdr["description"].ToString() : "";
                                row["rfidtag"] = rdr["rfidtag"] != DBNull.Value ? rdr["rfidtag"].ToString() : "";
                                row["assettype"] = rdr["assettype"] != DBNull.Value ? rdr["assettype"].ToString() : "";
                                row["lastobservedlocation"] = newLocation; // from ENNX
                                row["lastobservedtime"] = invStamp.ToString("yyyy-MM-dd HH:mm:ss");
                                row["checkinstatus"] = rdr["checkinstatus"] != DBNull.Value ? rdr["checkinstatus"].ToString() : "";
                                row["companyid"] = rdr["companyid"] != DBNull.Value ? rdr["companyid"].ToString() : "";
                                row["lastinventoried"] = invStamp.ToString("yyyy-MM-dd HH:mm:ss");
                                row["lastmodified"] = invStamp.ToString("yyyy-MM-dd HH:mm:ss");
                                row["listvalue1"] = rdr["listvalue1"] != DBNull.Value ? rdr["listvalue1"].ToString() : "";
                                row["newLocation"] = newLocation;

                                // Copy text fields
                                for (int t = 1; t <= 12; t++)
                                {
                                    string col = "text" + t;
                                    row[col] = rdr[col] != DBNull.Value ? rdr[col].ToString() : "";
                                }
                                row["text19"] = rdr["text19"] != DBNull.Value ? rdr["text19"].ToString() : "";
                                row["text20"] = rdr["text20"] != DBNull.Value ? rdr["text20"].ToString() : "";

                                // Override text6 (location) and text17 (tag date) from ENNX
                                row["text6"] = newLocation;
                                row["text17"] = invStamp.ToString("yyyy-MM-dd HH:mm:ss");

                                assetUpdates.Add(row);
                                matched++;
                            }
                            else
                            {
                                skipped++;
                            }
                        }
                    }
                }

                // ── Step 3: Update local iDash DB ──
                int localUpdated = 0;
                foreach (var asset in assetUpdates)
                {
                    using (SqlCommand updCmd = new SqlCommand(@"
                        UPDATE dbo.asset SET
                            text6 = @loc,
                            lastobservedlocation = @loc,
                            text17 = @tagDate,
                            lastinventoried = @invStamp,
                            lastmodified = @invStamp,
                            lastmodifiedby = @modBy
                        WHERE id = @id", localCn))
                    {
                        updCmd.Parameters.Add(new SqlParameter("@loc", SqlDbType.NVarChar, 500) { Value = asset["newLocation"] });
                        updCmd.Parameters.Add(new SqlParameter("@tagDate", SqlDbType.NVarChar, 50) { Value = invStamp.ToString("yyyy-MM-dd HH:mm:ss") });
                        updCmd.Parameters.Add(new SqlParameter("@invStamp", SqlDbType.DateTime) { Value = invStamp });
                        updCmd.Parameters.Add(new SqlParameter("@modBy", SqlDbType.NVarChar, 100) { Value = "ENNX_VISTA_PUSH" });
                        updCmd.Parameters.Add(new SqlParameter("@id", SqlDbType.Int) { Value = int.Parse(asset["id"]) });
                        localUpdated += updCmd.ExecuteNonQuery();
                    }
                }

                results.AppendFormat("<div class='step-ok'>&#x2705; Step 2: Matched {0} assets in iDash ({1} not found)</div>", matched, skipped);
                results.AppendFormat("<div class='step-ok'>&#x2705; Step 3: Updated {0} assets in local iDash DB</div>", localUpdated);
                AddLogEntry("AEMS_PUSH", "INFO", "Steps 2-3: Matched " + matched + ", updated " + localUpdated + " local assets");
            }

            if (assetUpdates.Count == 0)
            {
                results.Append("<div class='step-warn'>&#x26A0; No assets matched. Nothing to push to VA.</div>");
                LitAemsResult.Text = results.ToString();
                return;
            }

            // ── Step 4: Push to VA SQL Server ──
            string vaConnStr = string.Format(
                "Data Source={0};Database={1};User ID={2};Password={3};Encrypt=False;TrustServerCertificate=True;Connect Timeout=30",
                vaServer, vaDb, vaUser, vaPass);

            // Build column definitions for staging
            string[] pushCols = new string[] {
                "id", "name", "description", "rfidtag", "assettype",
                "lastobservedlocation", "lastobservedtime", "checkinstatus",
                "text1", "text2", "text3", "text4", "text5", "text6", "text7",
                "text8", "text9", "text10", "text11", "text12",
                "text19", "text20", "companyid", "lastinventoried", "lastmodified", "listvalue1"
            };

            StringBuilder colDefs = new StringBuilder();
            StringBuilder colList = new StringBuilder();
            StringBuilder mergeUpdate = new StringBuilder();
            StringBuilder mergeInsertCols = new StringBuilder();
            StringBuilder mergeInsertVals = new StringBuilder();

            for (int i = 0; i < pushCols.Length; i++)
            {
                string col = "[" + pushCols[i] + "]";
                if (i > 0) { colDefs.Append(", "); colList.Append(", "); mergeUpdate.Append(", "); mergeInsertCols.Append(", "); mergeInsertVals.Append(", "); }
                colDefs.AppendFormat("{0} nvarchar(500) NULL", col);
                colList.Append(col);
                mergeUpdate.AppendFormat("tgt.{0} = src.{0}", col);
                mergeInsertCols.Append(col);
                mergeInsertVals.AppendFormat("src.{0}", col);
            }

            using (SqlConnection vaCn = new SqlConnection(vaConnStr))
            {
                vaCn.Open();
                results.Append("<div class='step-ok'>&#x2705; Step 4: Connected to VA SQL Server</div>");

                // Drop/create staging
                ExecVaSql(vaCn, "IF OBJECT_ID('dbo.AWPushStaging', 'U') IS NOT NULL DROP TABLE dbo.AWPushStaging;");
                ExecVaSql(vaCn, "CREATE TABLE dbo.AWPushStaging (" + colDefs + ");");

                // Insert matched assets into staging
                int inserted = 0;
                foreach (var asset in assetUpdates)
                {
                    StringBuilder insertSql = new StringBuilder("INSERT INTO dbo.AWPushStaging (");
                    insertSql.Append(colList);
                    insertSql.Append(") VALUES (");

                    using (SqlCommand insertCmd = new SqlCommand())
                    {
                        for (int c = 0; c < pushCols.Length; c++)
                        {
                            if (c > 0) insertSql.Append(", ");
                            string pName = "@p" + c;
                            insertSql.Append(pName);

                            string val = asset.ContainsKey(pushCols[c]) ? asset[pushCols[c]] : "";
                            insertCmd.Parameters.Add(new SqlParameter(pName, SqlDbType.NVarChar, 500)
                            {
                                Value = string.IsNullOrEmpty(val) ? (object)DBNull.Value : val
                            });
                        }

                        insertSql.Append(");");
                        insertCmd.CommandText = insertSql.ToString();
                        insertCmd.Connection = vaCn;
                        insertCmd.ExecuteNonQuery();
                        inserted++;
                    }
                }

                results.AppendFormat("<div class='step-ok'>&#x2705; Step 5: Inserted {0} rows into VA staging</div>", inserted);

                // Create target if not exists
                ExecVaSql(vaCn, "IF OBJECT_ID('dbo.AWAssetSync', 'U') IS NULL CREATE TABLE dbo.AWAssetSync (" + colDefs + ");");

                // MERGE
                string mergeSql = string.Format(
                    "MERGE dbo.AWAssetSync AS tgt USING dbo.AWPushStaging AS src ON tgt.[rfidtag] = src.[rfidtag] " +
                    "WHEN MATCHED THEN UPDATE SET {0} " +
                    "WHEN NOT MATCHED BY TARGET THEN INSERT ({1}) VALUES ({2});",
                    mergeUpdate, mergeInsertCols, mergeInsertVals);

                ExecVaSql(vaCn, mergeSql);
                results.Append("<div class='step-ok'>&#x2705; Step 6: MERGE completed (upsert on rfidtag)</div>");

                // Final count
                using (SqlCommand countCmd = new SqlCommand("SELECT COUNT(*) FROM dbo.AWAssetSync", vaCn))
                {
                    int totalRows = (int)countCmd.ExecuteScalar();
                    results.AppendFormat("<div class='step-ok'><strong>&#x2705; AWAssetSync total rows: {0}</strong></div>", totalRows);
                }

                // Cleanup
                ExecVaSql(vaCn, "IF OBJECT_ID('dbo.AWPushStaging', 'U') IS NOT NULL DROP TABLE dbo.AWPushStaging;");
                results.Append("<div class='step-ok'>&#x2705; Step 7: Staging table dropped</div>");
            }

            if (skipped > 0)
            {
                results.AppendFormat("<div class='step-warn'>&#x26A0; {0} ENNX asset(s) could not be matched in iDash (skipped)</div>", skipped);
            }

            AddLogEntry("AEMS_PUSH", "SUCCESS", "ENNX->VistA push complete: " + matched + " matched, " + skipped + " skipped. Session #" + HidEnnxSessionId.Value);
            ShowMsg("Push to VistA completed! " + matched + " assets synced from ENNX session #" + HidEnnxSessionId.Value, false);
            LitAemsResult.Text = results.ToString();
            LitEnnxAssetCount.Text = matched.ToString();
            RefreshLog();
        }
        catch (Exception ex)
        {
            results.AppendFormat("<div class='step-err'>&#x274C; Error: {0}</div>", HE(ex.Message));
            ShowMsg("Push failed: " + HE(ex.Message), true);
            AddLogEntry("AEMS_PUSH", "FAILED", ex.Message);
            LitAemsResult.Text = results.ToString();
        }
    }

    private void ExecVaSql(SqlConnection cn, string sql)
    {
        using (SqlCommand cmd = new SqlCommand(sql, cn))
        {
            cmd.CommandTimeout = 120;
            cmd.ExecuteNonQuery();
        }
    }


    // ================================================================
    // PHASE 2: OAuth 2.0 CCG Flow + FHIR Bundle Push
    // ================================================================

    /// <summary>
    /// Button handler: Acquire an OAuth token and POST the FHIR Bundle to VistA.
    /// </summary>
    protected void BtnPushToVista_Click(object sender, EventArgs e)
    {
        try
        {
            // 1. Validate prerequisites
            if (!File.Exists(PrivateKeyPath))
            {
                ShowMsg("Push failed: No RSA private key found. Generate keys first.", true);
                AddLogEntry("PUSH", "FAILED", "No RSA private key found.");
                return;
            }

            string configJson = File.Exists(ConfigPath) ? File.ReadAllText(ConfigPath) : "";
            var ser = new JavaScriptSerializer();
            var config = ser.Deserialize<Dictionary<string, object>>(configJson);

            string fhirBase = config != null && config.ContainsKey("fhirBaseUrl") ? Convert.ToString(config["fhirBaseUrl"]) : "";
            string tokenUrl = config != null && config.ContainsKey("tokenUrl") ? Convert.ToString(config["tokenUrl"]) : "";
            string clientId = config != null && config.ContainsKey("clientId") ? Convert.ToString(config["clientId"]) : "";

            if (string.IsNullOrEmpty(fhirBase) || string.IsNullOrEmpty(tokenUrl) || string.IsNullOrEmpty(clientId))
            {
                ShowMsg("Push failed: FHIR Base URL, Token URL, and Client ID must all be configured.", true);
                AddLogEntry("PUSH", "FAILED", "Missing FHIR configuration.");
                return;
            }

            // 2. Get the FHIR Bundle JSON (from hidden field, populated by Generate button)
            string[] selectedIds = (HidSelectedIds.Value ?? "").Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            if (selectedIds.Length == 0)
            {
                ShowMsg("Push failed: No assets selected. Select assets and click 'Generate FHIR Bundle' first.", true);
                return;
            }

            DataTable dt = LoadAssetsByIds(selectedIds);
            string bundleJson = BuildFhirBundleJson(dt);

            if (string.IsNullOrEmpty(bundleJson))
            {
                ShowMsg("Push failed: No FHIR Bundle to push. Generate a bundle first.", true);
                return;
            }

            // 3. Discover the Okta issuer from OpenID config
            //    VA proxies to Okta, but Okta validates the aud claim against its OWN
            //    token endpoint URL, not the VA proxy URL. We need to build the aud
            //    from the Okta issuer.
            string discoveryUrl = tokenUrl.Substring(0, tokenUrl.LastIndexOf("/token")) + "/.well-known/openid-configuration";
            string audUrl = tokenUrl; // fallback to configured URL
            try
            {
                HttpWebRequest discReq = (HttpWebRequest)WebRequest.Create(discoveryUrl);
                discReq.Method = "GET";
                discReq.Timeout = 15000;
                using (HttpWebResponse discResp = (HttpWebResponse)discReq.GetResponse())
                using (StreamReader discSr = new StreamReader(discResp.GetResponseStream(), Encoding.UTF8))
                {
                    string discJson = discSr.ReadToEnd();
                    var discSer = new JavaScriptSerializer();
                    var discConfig = discSer.Deserialize<Dictionary<string, object>>(discJson);
                    if (discConfig != null)
                    {
                        // Try the issuer's token endpoint first (Okta's actual URL)
                        if (discConfig.ContainsKey("issuer"))
                        {
                            string issuer = Convert.ToString(discConfig["issuer"]);
                            // Okta token endpoint = issuer + /v1/token
                            audUrl = issuer.TrimEnd('/') + "/v1/token";
                        }
                    }
                }
            }
            catch { /* use configured tokenUrl as fallback */ }

            // 4. Build JWT client assertion using Okta token URL as aud
            string jwt = BuildClientAssertion(clientId, audUrl);
            AddLogEntry("PUSH", "INFO", "JWT built. aud=" + audUrl + " | POST to " + tokenUrl + " | clientId=" + clientId);

            // 4. Acquire bearer token
            string accessToken;
            string tokenError;
            bool tokenOk = AcquireToken(tokenUrl, jwt, out accessToken, out tokenError);

            if (!tokenOk)
            {
                ShowMsg("Token acquisition failed: " + HE(tokenError), true);
                AddLogEntry("PUSH", "FAILED", "Token error: " + tokenError);
                LitPushResult.Text = "<div class='err'>Token Error: " + HE(tokenError) + "</div>";
                return;
            }

            AddLogEntry("PUSH", "INFO", "Bearer token acquired. Pushing bundle (" + selectedIds.Length + " assets)...");

            // 5. POST the bundle to the FHIR endpoint
            string pushResult;
            int statusCode;
            bool pushOk = PushBundleToFhir(fhirBase, accessToken, bundleJson, out pushResult, out statusCode);

            if (pushOk)
            {
                AddLogEntry("PUSH", "SUCCESS", "Bundle pushed. HTTP " + statusCode + ". " + selectedIds.Length + " assets submitted.");
                ShowMsg("Bundle pushed to VistA successfully! HTTP " + statusCode, false);
                LitPushResult.Text = "<div class='ok' style='font-weight:700;'>HTTP " + statusCode + " - Success</div>" +
                    "<pre style='max-height:300px; overflow:auto; font-size:11px; margin-top:8px; padding:8px; background:var(--chip); border-radius:6px; white-space:pre-wrap;'>" +
                    HE(FormatJson(pushResult)) + "</pre>";
            }
            else
            {
                AddLogEntry("PUSH", "FAILED", "HTTP " + statusCode + ": " + pushResult);
                ShowMsg("Push failed: HTTP " + statusCode, true);
                LitPushResult.Text = "<div class='err' style='font-weight:700;'>HTTP " + statusCode + " - Failed</div>" +
                    "<pre style='max-height:300px; overflow:auto; font-size:11px; margin-top:8px; padding:8px; background:var(--chip); border-radius:6px; white-space:pre-wrap;'>" +
                    HE(pushResult) + "</pre>";
            }

            RefreshLog();
        }
        catch (Exception ex)
        {
            ShowMsg("Push error: " + HE(ex.Message), true);
            AddLogEntry("PUSH", "ERROR", ex.Message);
            LitPushResult.Text = "<div class='err'>" + HE(ex.ToString()) + "</div>";
        }
    }

    /// <summary>
    /// Builds a signed JWT assertion for OAuth 2.0 Client Credentials Grant.
    /// Header: {"alg":"RS256","typ":"JWT","kid":"..."}
    /// Payload: {"iss":clientId,"sub":clientId,"aud":tokenUrl,"iat":now,"exp":now+300,"jti":guid}
    /// </summary>
    private string BuildClientAssertion(string clientId, string tokenUrl)
    {
        // Load the RSA private key (supports both PEM and XML formats)
        RSACryptoServiceProvider rsa = new RSACryptoServiceProvider();
        string keyData = File.ReadAllText(PrivateKeyPath).Trim();

        if (keyData.StartsWith("<"))
        {
            // XML format (generated by the C# Generate button)
            rsa.FromXmlString(keyData);
        }
        else if (keyData.Contains("BEGIN RSA PRIVATE KEY") || keyData.Contains("BEGIN PRIVATE KEY"))
        {
            // PEM format (generated by the PowerShell script)
            string b64 = keyData
                .Replace("-----BEGIN RSA PRIVATE KEY-----", "")
                .Replace("-----END RSA PRIVATE KEY-----", "")
                .Replace("-----BEGIN PRIVATE KEY-----", "")
                .Replace("-----END PRIVATE KEY-----", "")
                .Replace("\r", "").Replace("\n", "").Trim();

            byte[] derBytes = Convert.FromBase64String(b64);
            rsa = DecodeRsaPrivateKey(derBytes);
        }
        else
        {
            throw new Exception("Unrecognized private key format. Expected PEM or XML.");
        }

        // Get the kid from JWK if available
        string kid = "default";
        if (File.Exists(JwkPath))
        {
            try
            {
                var jwkSer = new JavaScriptSerializer();
                var jwk = jwkSer.Deserialize<Dictionary<string, object>>(File.ReadAllText(JwkPath));
                if (jwk != null && jwk.ContainsKey("kid")) kid = Convert.ToString(jwk["kid"]);
            }
            catch { }
        }

        // Build header
        var header = new Dictionary<string, string>
        {
            { "alg", "RS256" },
            { "typ", "JWT" },
            { "kid", kid }
        };

        // Build payload
        long iat = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalSeconds;
        long exp = iat + 300; // 5 minutes

        var payload = new Dictionary<string, object>
        {
            { "iss", clientId },
            { "sub", clientId },
            { "aud", tokenUrl },
            { "iat", iat },
            { "exp", exp },
            { "jti", Guid.NewGuid().ToString("N") }
        };

        var ser = new JavaScriptSerializer();
        string headerJson = ser.Serialize(header);
        string payloadJson = ser.Serialize(payload);

        string headerB64 = Base64UrlEncode(Encoding.UTF8.GetBytes(headerJson));
        string payloadB64 = Base64UrlEncode(Encoding.UTF8.GetBytes(payloadJson));

        string signingInput = headerB64 + "." + payloadB64;

        // Sign with RS256 (RSASSA-PKCS1-v1_5 with SHA-256)
        byte[] sigBytes;
        using (SHA256 sha256 = SHA256.Create())
        {
            byte[] inputBytes = Encoding.UTF8.GetBytes(signingInput);
            byte[] hashBytes = sha256.ComputeHash(inputBytes);

            RSAPKCS1SignatureFormatter formatter = new RSAPKCS1SignatureFormatter(rsa);
            formatter.SetHashAlgorithm("SHA256");
            sigBytes = formatter.CreateSignature(hashBytes);
        }

        string signatureB64 = Base64UrlEncode(sigBytes);

        return signingInput + "." + signatureB64;
    }

    /// <summary>
    /// Exchanges a JWT client assertion for a bearer token at the VA token endpoint.
    /// POST /oauth2/token with grant_type=client_credentials
    /// </summary>
    private bool AcquireToken(string tokenUrl, string jwt, out string accessToken, out string error)
    {
        accessToken = null;
        error = null;

        try
        {
            string postBody = "grant_type=client_credentials" +
                "&client_assertion_type=" + Uri.EscapeDataString("urn:ietf:params:oauth:client-assertion-type:jwt-bearer") +
                "&client_assertion=" + Uri.EscapeDataString(jwt) +
                "&scope=" + Uri.EscapeDataString("system/Device.read system/Device.write system/Location.read system/Location.write");

            byte[] postBytes = Encoding.UTF8.GetBytes(postBody);

            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(tokenUrl);
            req.Method = "POST";
            req.ContentType = "application/x-www-form-urlencoded";
            req.ContentLength = postBytes.Length;
            req.Timeout = 30000;

            using (Stream reqStream = req.GetRequestStream())
            {
                reqStream.Write(postBytes, 0, postBytes.Length);
            }

            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
            {
                string responseBody = sr.ReadToEnd();
                var ser = new JavaScriptSerializer();
                var tokenResp = ser.Deserialize<Dictionary<string, object>>(responseBody);

                if (tokenResp != null && tokenResp.ContainsKey("access_token"))
                {
                    accessToken = Convert.ToString(tokenResp["access_token"]);
                    return true;
                }
                else
                {
                    error = "Token response missing access_token: " + responseBody;
                    return false;
                }
            }
        }
        catch (WebException wex)
        {
            if (wex.Response != null)
            {
                using (StreamReader sr = new StreamReader(wex.Response.GetResponseStream(), Encoding.UTF8))
                {
                    error = "HTTP " + (int)((HttpWebResponse)wex.Response).StatusCode + ": " + sr.ReadToEnd();
                }
            }
            else
            {
                error = wex.Message;
            }
            return false;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    /// <summary>
    /// POSTs the FHIR Bundle JSON to the VA FHIR endpoint with a bearer token.
    /// </summary>
    private bool PushBundleToFhir(string fhirBaseUrl, string bearerToken, string bundleJson,
                                    out string responseBody, out int statusCode)
    {
        responseBody = "";
        statusCode = 0;

        try
        {
            string url = fhirBaseUrl.TrimEnd('/');

            byte[] bodyBytes = Encoding.UTF8.GetBytes(bundleJson);

            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
            req.Method = "POST";
            req.ContentType = "application/fhir+json";
            req.ContentLength = bodyBytes.Length;
            req.Accept = "application/fhir+json";
            req.Timeout = 60000;
            req.Headers.Add("Authorization", "Bearer " + bearerToken);

            using (Stream reqStream = req.GetRequestStream())
            {
                reqStream.Write(bodyBytes, 0, bodyBytes.Length);
            }

            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
            {
                statusCode = (int)resp.StatusCode;
                responseBody = sr.ReadToEnd();
                return statusCode >= 200 && statusCode < 300;
            }
        }
        catch (WebException wex)
        {
            if (wex.Response != null)
            {
                using (HttpWebResponse errResp = (HttpWebResponse)wex.Response)
                using (StreamReader sr = new StreamReader(errResp.GetResponseStream(), Encoding.UTF8))
                {
                    statusCode = (int)errResp.StatusCode;
                    responseBody = sr.ReadToEnd();
                }
            }
            else
            {
                responseBody = wex.Message;
            }
            return false;
        }
    }

    /// <summary>
    /// Decodes a PKCS#1 DER-encoded RSA private key into an RSACryptoServiceProvider.
    /// Compatible with .NET Framework 4.8 (no ImportRSAPrivateKey).
    /// </summary>
    private static RSACryptoServiceProvider DecodeRsaPrivateKey(byte[] pkcs1Bytes)
    {
        using (BinaryReader reader = new BinaryReader(new MemoryStream(pkcs1Bytes)))
        {
            // SEQUENCE tag
            byte bt = reader.ReadByte();
            if (bt != 0x30) throw new Exception("Expected SEQUENCE tag (0x30) at start of RSA key");

            int seqLen = ReadDerLength(reader);

            // Version (should be 0)
            ReadDerInteger(reader); // version

            // RSA parameters in order: n, e, d, p, q, dp, dq, iq
            byte[] modulus = ReadDerInteger(reader);
            byte[] exponent = ReadDerInteger(reader);
            byte[] d = ReadDerInteger(reader);
            byte[] p = ReadDerInteger(reader);
            byte[] q = ReadDerInteger(reader);
            byte[] dp = ReadDerInteger(reader);
            byte[] dq = ReadDerInteger(reader);
            byte[] iq = ReadDerInteger(reader);

            RSAParameters rsaParams = new RSAParameters
            {
                Modulus = modulus,
                Exponent = exponent,
                D = d,
                P = p,
                Q = q,
                DP = dp,
                DQ = dq,
                InverseQ = iq
            };

            RSACryptoServiceProvider rsa = new RSACryptoServiceProvider();
            rsa.ImportParameters(rsaParams);
            return rsa;
        }
    }

    private static int ReadDerLength(BinaryReader reader)
    {
        int length = reader.ReadByte();
        if ((length & 0x80) != 0)
        {
            int numBytes = length & 0x7F;
            length = 0;
            for (int i = 0; i < numBytes; i++)
                length = (length << 8) | reader.ReadByte();
        }
        return length;
    }

    private static byte[] ReadDerInteger(BinaryReader reader)
    {
        byte tag = reader.ReadByte();
        if (tag != 0x02) throw new Exception("Expected INTEGER tag (0x02) in RSA key");

        int length = ReadDerLength(reader);
        byte[] data = reader.ReadBytes(length);

        // Strip leading zero padding (ASN.1 adds a leading 0x00 for positive ints)
        if (data.Length > 1 && data[0] == 0x00)
        {
            byte[] trimmed = new byte[data.Length - 1];
            Array.Copy(data, 1, trimmed, 0, trimmed.Length);
            return trimmed;
        }
        return data;
    }
}
