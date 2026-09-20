using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class va_site_config : Page
{
    // -- helpers ----------------------------------------------------------
    private string ConnStr
    {
        get
        {
            foreach (ConnectionStringSettings css in ConfigurationManager.ConnectionStrings)
                if (css.Name != "LocalSqlServer" && !string.IsNullOrEmpty(css.ConnectionString))
                    return css.ConnectionString;
            return "";
        }
    }

    private string AppKey(string k)
    {
        return ConfigurationManager.AppSettings[k] ?? "";
    }

    private void SetAppKey(Configuration cfg, string key, string value)
    {
        if (cfg.AppSettings.Settings[key] != null)
            cfg.AppSettings.Settings[key].Value = value;
        else
            cfg.AppSettings.Settings.Add(key, value);
    }

    private string GetConnPart(string connectionString, string partName)
    {
        foreach (string part in connectionString.Split(';'))
        {
            var kv = part.Split(new char[]{'='}, 2);
            if (kv.Length == 2 && kv[0].Trim().Equals(partName, StringComparison.OrdinalIgnoreCase))
                return kv[1].Trim();
        }
        return "";
    }

    private void ShowOk(string msg)
    {
        LitMsg.Text = "<div class=\"msg-ok\">&#9989; " + msg + "</div>";
    }

    private void ShowErr(string msg)
    {
        LitMsg.Text = "<div class=\"msg-err\">&#9888; " + msg + "</div>";
    }

    private void ShowRcptOk(string msg)
    {
        LitRcptMsg.Text = "<div class=\"msg-ok\">&#9989; " + msg + "</div>";
    }

    private void ShowRcptErr(string msg)
    {
        LitRcptMsg.Text = "<div class=\"msg-err\">&#9888; " + msg + "</div>";
    }

    // -- report config JSON path ------------------------------------------
    private string ReportConfigPath
    {
        get { return Server.MapPath("~/config/report_automation.json"); }
    }

    // -- server port & base URL helpers ------------------------------------
    private string GetConfiguredBaseUrl()
    {
        string baseUrl = AppKey("App_BaseUrl");
        if (!string.IsNullOrEmpty(baseUrl))
            return baseUrl.TrimEnd('/');

        string proto = AppKey("App_Protocol");
        string portStr = AppKey("App_Port");
        string host = AppKey("App_Host");
        string vpath = AppKey("App_VirtualPath");

        if (string.IsNullOrEmpty(proto)) proto = Request.Url.Scheme.ToLower();
        if (string.IsNullOrEmpty(host)) host = Request.Url.Host;

        int port;
        if (!int.TryParse(portStr, out port)) port = Request.Url.Port;

        if (string.IsNullOrEmpty(vpath) && ConfigurationManager.AppSettings["App_VirtualPath"] == null)
            vpath = Request.ApplicationPath != null && Request.ApplicationPath != "/" ? Request.ApplicationPath : "";
        vpath = (vpath ?? "").TrimEnd('/');

        bool isStandard = (proto.Equals("http", StringComparison.OrdinalIgnoreCase) && port == 80) ||
                          (proto.Equals("https", StringComparison.OrdinalIgnoreCase) && port == 443);

        string url = proto + "://" + host + (isStandard ? "" : ":" + port) + (string.IsNullOrEmpty(vpath) || vpath == "/" ? "" : vpath);
        return url.TrimEnd('/');
    }

    private void UpdateRunnerScriptPreview(string runnerUrl)
    {
        LitRunnerScriptPreview.Text =
            "# AutoReportRunner.ps1\r\n" +
            "$url = \"" + runnerUrl + "\"\r\n" +
            "$resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 300\r\n" +
            "Write-Host $resp.Content";
    }

    private void UpdateAutoReportRunnerScript(string runnerUrl)
    {
        string script =
@"# iDash Report Automation Runner
$url = """ + runnerUrl + @"""
try {
    Write-Host ""Triggering Auto Report Generation at $url""
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 300
    Write-Host ""Status: $($resp.StatusCode) $($resp.StatusDescription)""
    Write-Host $resp.Content
} catch {
    Write-Error ""Failed to execute automation: $_""
}
";
        string path = Server.MapPath("~/downloads/Scripts/AutoReportRunner.ps1");
        if (File.Exists(path))
        {
            File.WriteAllText(path, script, System.Text.Encoding.UTF8);
        }
    }

    private void UpdateRemoteDbUpdateScripts(string baseUrl)
    {
        string[] scriptPaths = new string[] {
            Server.MapPath("~/remote_db_update.ps1"),
            Server.MapPath("~/downloads/Scripts/remote_db_update.ps1")
        };

        foreach (string p in scriptPaths)
        {
            if (File.Exists(p))
            {
                string content = File.ReadAllText(p);
                string updated = Regex.Replace(
                    content,
                    @"(\[string\]\$ServerUrl\s*=\s*"")[^""]*("")",
                    "${1}" + baseUrl + "${2}"
                );
                File.WriteAllText(p, updated, System.Text.Encoding.UTF8);
            }
        }
    }

    private void UpdateReportAutomationJson(string baseUrl, string runnerUrl)
    {
        string path = Server.MapPath("~/config/report_automation.json");
        if (File.Exists(path))
        {
            string json = File.ReadAllText(path);
            var js = new JavaScriptSerializer();
            var dict = js.Deserialize<Dictionary<string, object>>(json);
            if (dict == null) dict = new Dictionary<string, object>();
            dict["ServerBaseUrl"] = baseUrl;
            dict["RunnerUrl"] = runnerUrl;
            File.WriteAllText(path, js.Serialize(dict), System.Text.Encoding.UTF8);
        }
    }

    private void UpdatePrintServerAppSettings(string baseUrl)
    {
        string path = Server.MapPath("~/Assets/printserver_appsettings.json");
        if (File.Exists(path))
        {
            string content = File.ReadAllText(path);
            content = Regex.Replace(
                content,
                @"(""AuthServerUrl""\s*:\s*"")[^""]*("")",
                "${1}" + baseUrl + "${2}"
            );
            content = Regex.Replace(
                content,
                @"(""AuthenticationServer""\s*:\s*"")[^""]*("")",
                "${1}" + baseUrl + "${2}"
            );
            File.WriteAllText(path, content, System.Text.Encoding.UTF8);
        }
    }

    private string BuildIisBindingScript(string proto, int port, string host, string baseUrl)
    {
        return
@"<#
.SYNOPSIS
    Configures IIS Web Site Bindings and Windows Firewall for iDash listening port and protocol.
.DESCRIPTION
    Generated by iDash Site Configuration (va_site_config.aspx).
    Configures IIS web bindings for port " + port + @" (" + proto + @"),
    adds Windows Firewall rule, and restarts the IIS web site.
    Must be executed with elevated Administrator privileges.
#>
[CmdletBinding()]
param(
    [int]$Port = " + port + @",
    [ValidateSet(""http"", ""https"")]
    [string]$Protocol = """ + proto + @""",
    [string]$SiteName = """",
    [string]$CertThumbprint = """"
)

# 1. Ensure Administrator Elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning ""Administrator elevation required. Relaunching in elevated window...""
    Start-Process powershell.exe -ArgumentList ""-NoProfile -ExecutionPolicy Bypass -File `""$PSCommandPath`"""" -Verb RunAs
    exit
}

Write-Host ""================================================================="" -ForegroundColor Cyan
Write-Host "" iDash Server Port & IIS Binding Rollout Script"" -ForegroundColor White
Write-Host "" Protocol: $Protocol | Port: $Port"" -ForegroundColor Yellow
Write-Host "" Target Base URL: " + baseUrl + @""" -ForegroundColor Cyan
Write-Host ""================================================================="" -ForegroundColor Cyan

# 2. Import IIS Administration Module
try {
    Import-Module WebAdministration -ErrorAction Stop
} catch {
    Write-Error ""Failed to import WebAdministration module. Please ensure IIS Management Scripts and Tools are installed.""
    Read-Host ""Press Enter to exit""
    exit 1
}

# 3. Detect IIS Site
if ([string]::IsNullOrWhiteSpace($SiteName)) {
    if (Get-Website | Where-Object { $_.Name -eq ""iDash"" }) {
        $SiteName = ""iDash""
    } elseif (Get-Website | Where-Object { $_.Name -eq ""Default Web Site"" }) {
        $SiteName = ""Default Web Site""
    } else {
        $firstSite = (Get-Website | Select-Object -First 1)
        if ($firstSite) {
            $SiteName = $firstSite.Name
        } else {
            Write-Error ""No IIS websites found on this server.""
            Read-Host ""Press Enter to exit""
            exit 1
        }
    }
}

Write-Host ""Target IIS Site: '$SiteName'"" -ForegroundColor Green

# 4. Check existing bindings
$existingBindings = Get-WebBinding -Name $SiteName
Write-Host ""`nCurrent Bindings for '$SiteName':"" -ForegroundColor Gray
$existingBindings | ForEach-Object {
    Write-Host ""  - $($_.protocol)://$($_.bindingInformation)"" -ForegroundColor DarkGray
}

$bindingMatch = $existingBindings | Where-Object {
    $_.protocol -eq $Protocol -and ($_.bindingInformation -like ""*:$Port:*"" -or $_.bindingInformation -like ""*:$Port"")
}

if ($bindingMatch) {
    Write-Host ""`n[OK] Binding already exists for $Protocol on port $Port."" -ForegroundColor Green
} else {
    Write-Host ""`n[ACTION] Adding new WebBinding: $Protocol on port $Port..."" -ForegroundColor Yellow
    New-WebBinding -Name $SiteName -IPAddress ""*"" -Port $Port -Protocol $Protocol -ErrorAction Stop
    Write-Host ""[OK] Binding added successfully."" -ForegroundColor Green
}

# 5. Handle SSL / HTTPS Certificate Binding if port 443 / https
if ($Protocol -eq ""https"") {
    Write-Host ""`n--- Configuring SSL / TLS Certificate for Port $Port ---"" -ForegroundColor Cyan
    $cert = $null
    if (-not [string]::IsNullOrWhiteSpace($CertThumbprint)) {
        $cert = Get-Item ""Cert:\LocalMachine\My\$CertThumbprint"" -ErrorAction SilentlyContinue
    }
    if (-not $cert) {
        $cert = Get-ChildItem ""Cert:\LocalMachine\My"" | Where-Object { $_.Subject -like ""*$env:COMPUTERNAME*"" -or $_.Subject -like ""*localhost*"" -or $_.Subject -like ""*iDash*"" } | Select-Object -First 1
    }

    if ($cert) {
        Write-Host ""Using SSL Certificate: $($cert.Subject) [Thumbprint: $($cert.Thumbprint)]"" -ForegroundColor Green
        try {
            $existingSsl = Get-ChildItem ""IIS:\SslBindings"" | Where-Object { $_.Port -eq $Port }
            if ($existingSsl) {
                Write-Host ""Replacing existing SSL binding on port $Port..."" -ForegroundColor Yellow
                $existingSsl | Remove-Item
            }
            Get-Item ""Cert:\LocalMachine\My\$($cert.Thumbprint)"" | New-Item ""IIS:\SslBindings\0.0.0.0!$Port"" -Force | Out-Null
            Write-Host ""[OK] SSL Certificate bound to 0.0.0.0:$Port."" -ForegroundColor Green
        } catch {
            Write-Warning ""Could not automatically bind SSL certificate via IIS:\SslBindings: $_""
            Write-Host ""You can assign the certificate manually in IIS Manager -> Bindings -> Edit port 443."" -ForegroundColor Yellow
        }
    } else {
        Write-Warning ""No SSL certificate found in Cert:\LocalMachine\My. Please assign your SSL certificate in IIS Manager -> Bindings -> Edit port $Port.""
    }
}

# 6. Windows Firewall Rule
Write-Host ""`n--- Configuring Windows Firewall ---"" -ForegroundColor Cyan
$ruleName = ""iDash Web Server ($Protocol Port $Port)""
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existingRule) {
    try {
        New-NetFirewallRule -DisplayName $ruleName -Name ""iDash_Port_$Port"" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow -Profile Any -ErrorAction Stop | Out-Null
        Write-Host ""[OK] Windows Firewall inbound rule created for TCP port $Port."" -ForegroundColor Green
    } catch {
        Write-Warning ""Could not add firewall rule automatically: $_""
    }
} else {
    Write-Host ""[OK] Windows Firewall inbound rule already active for Port $Port."" -ForegroundColor Green
}

# 7. Restart IIS Site
Write-Host ""`n--- Restarting IIS Site ---"" -ForegroundColor Cyan
try {
    Restart-WebItem ""IIS:\Sites\$SiteName"" -ErrorAction SilentlyContinue
    Write-Host ""[OK] IIS Site '$SiteName' restarted."" -ForegroundColor Green
} catch {
    Write-Warning ""Could not restart IIS site automatically: $_""
}

Write-Host ""`n================================================================="" -ForegroundColor Green
Write-Host "" Rollout Completed!"" -ForegroundColor White
Write-Host "" iDash is now listening on $Protocol://*:$Port/"" -ForegroundColor Yellow
Write-Host "" Test URL: $Protocol://localhost:$Port/"" -ForegroundColor White
Write-Host ""================================================================="" -ForegroundColor Green
";
    }

    // -- page load --------------------------------------------------------
    protected void Page_Load(object sender, EventArgs e)
    {
        // -- Authentication & RBAC Guard -----------------------------
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        string role = Convert.ToString(Session["IdashUserRole"]);
        var tiles = Session["IdashTileAccess"] as List<string>;
        bool hasAccess = isLoggedIn && (UserManager.CanAccessTile(role, tiles, "admin_site_config") || UserManager.CanAccessTile(role, tiles, "admin_license_manager"));

        string apiType = Request.QueryString["api"];
        string action = Request.QueryString["action"];
        bool isApi = !string.IsNullOrEmpty(apiType) || action == "api" || action == "downloadCart";

        if (isApi)
        {
            if (!isLoggedIn)
            {
                Response.StatusCode = 401;
                Response.ContentType = "application/json";
                Response.Write("{\"error\":\"Authentication required.\"}");
                Response.End();
                return;
            }
            if (!hasAccess)
            {
                Response.StatusCode = 403;
                Response.ContentType = "application/json";
                Response.Write("{\"error\":\"Access denied: Administrator privileges required.\"}");
                Response.End();
                return;
            }
        }
        else
        {
            if (!isLoggedIn)
            {
                Response.Redirect("index.aspx?err=auth");
                return;
            }
            if (!hasAccess)
            {
                Response.Redirect("index.aspx?err=access");
                return;
            }
        }

        // -- License Cart File Download ------------------------------
        if (action == "downloadCart" && !string.IsNullOrEmpty(Request.QueryString["id"]))
        {
            DownloadCartKey(Request.QueryString["id"]);
            return;
        }

        // -- Unified License Management API --------------------------
        if (action == "api")
        {
            Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            string cmd = Request.QueryString["cmd"] ?? "";

            // Enforce POST for state-changing operations
            if (cmd == "deleteReader" || cmd == "deleteServer" || cmd == "deleteUser" ||
                cmd == "deleteScanner" || cmd == "deleteMqtt" || cmd == "deleteCart" || cmd == "saveCart")
            {
                if (Request.HttpMethod != "POST")
                {
                    Response.StatusCode = 405;
                    Response.Write(js.Serialize(new { error = "POST method required for state-changing operations." }));
                    Response.End();
                    return;
                }
            }

            string result;

            switch (cmd)
            {
                case "getAll":        result = GetAllLicenses(); break;
                case "deleteReader":  result = DeleteLicenseItem("reader", "antenna", "readerid"); break;
                case "deleteServer":  result = DeleteLicenseItem("serverstatus", null, null); break;
                case "deleteUser":    result = DeleteLicenseItem("sysuser", null, null); break;
                case "deleteScanner": result = DeleteLicenseItem("scanner", null, null); break;
                case "deleteMqtt":    result = DeleteLicenseItem("mqttclient", null, null); break;
                case "getCarts":      result = GetCarts(); break;
                case "saveCart":      result = SaveCart(); break;
                case "deleteCart":    result = DeleteCart(); break;
                default: result = js.Serialize(new { error = "Unknown: " + cmd }); break;
            }

            Response.Write(result);
            Response.End();
            return;
        }

        // -- Service restart API --------------------------------------
        if (Request.QueryString["api"] == "svc")
        {
            Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            string cmd = Request.QueryString["cmd"] ?? "";
            var results = new List<Dictionary<string, object>>();

            // Enforce POST for state-changing service restart commands
            if (cmd == "restartAll" || cmd == "restart")
            {
                if (Request.HttpMethod != "POST")
                {
                    Response.StatusCode = 405;
                    Response.Write(js.Serialize(new { error = "POST method required for service restart operations." }));
                    Response.End();
                    return;
                }
            }

            try
            {
                string clientIp = Request.UserHostAddress;
                string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";

                switch (cmd)
                {
                    case "status":
                        results = GetServiceStatus();
                        break;
                    case "restartAll":
                        LoginAuditHelper.LogAdminAction(username, clientIp, "ServiceRestartAll", "Restarted all services");
                        results = RestartAllServices();
                        break;
                    case "restart":
                        string svc = Request.QueryString["svc"] ?? "";
                        LoginAuditHelper.LogAdminAction(username, clientIp, "ServiceRestart", "Service: " + svc);
                        results = RestartSingleService(svc);
                        break;
                    default:
                        Response.Write(js.Serialize(new { error = "Unknown cmd: " + cmd }));
                        Response.End();
                        return;
                }
            }
            catch (Exception ex)
            {
                Response.Write(js.Serialize(new { error = ex.Message }));
                Response.End();
                return;
            }

            Response.Write(js.Serialize(new { ok = true, results }));
            Response.End();
            return;
        }

        // Server-side proxy for RabbitMQ Management API (avoids CORS)
        if (Request.QueryString["api"] == "rmq")
        {
            string path = Request.QueryString["path"] ?? "overview";
            try
            {
                string rmqUser = ConfigurationManager.AppSettings["RabbitMQ_User"];
                string rmqPass = ConfigurationManager.AppSettings["RabbitMQ_Password"];
                if (string.IsNullOrEmpty(rmqUser)) rmqUser = "guest";
                if (rmqPass == null) rmqPass = "guest";

                using (var wc = new System.Net.WebClient())
                {
                    string creds = Convert.ToBase64String(System.Text.Encoding.ASCII.GetBytes(rmqUser + ":" + rmqPass));
                    wc.Headers["Authorization"] = "Basic " + creds;
                    string json = wc.DownloadString("http://localhost:15672/api/" + path);
                    Response.ContentType = "application/json";
                    Response.Write(json);
                }
            }
            catch (Exception ex)
            {
                Response.ContentType = "application/json";
                Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
            }
            Response.End();
            return;
        }

        if (!IsPostBack)
        {
            // Server Protocol & Port
            string cfgProto = AppKey("App_Protocol");
            string cfgPort  = AppKey("App_Port");
            string cfgHost  = AppKey("App_Host");
            string cfgVpath = AppKey("App_VirtualPath");

            if (string.IsNullOrEmpty(cfgProto)) cfgProto = Request.Url.Scheme.ToLower();
            if (string.IsNullOrEmpty(cfgPort))  cfgPort  = Request.Url.Port.ToString();
            if (string.IsNullOrEmpty(cfgHost))  cfgHost  = Request.Url.Host;
            if (string.IsNullOrEmpty(cfgVpath) && ConfigurationManager.AppSettings["App_VirtualPath"] == null)
                cfgVpath = Request.ApplicationPath != null && Request.ApplicationPath != "/" ? Request.ApplicationPath : "";

            if (DdlServerProtocol.Items.FindByValue(cfgProto) != null)
                DdlServerProtocol.SelectedValue = cfgProto;
            TxtServerPort.Text = cfgPort;
            TxtServerHost.Text = cfgHost;
            TxtServerVirtualPath.Text = cfgVpath;

            UpdateRunnerScriptPreview(GetConfiguredBaseUrl() + "/va_report_automator_runner.aspx");

            // Database
            var csEntry = ConfigurationManager.ConnectionStrings["iDash"]
                ?? ConfigurationManager.ConnectionStrings["iDash"];
            var cs = csEntry != null ? csEntry.ConnectionString : "";
            TxtDbServer.Text = GetConnPart(cs, "Data Source");
            TxtDbName.Text   = GetConnPart(cs, "Database");
            TxtDbUser.Text   = GetConnPart(cs, "User ID");

            // Fixed Reader / MQTT
            TxtMqttServer.Text = AppKey("AntennaService_MqttServer");
            TxtMqttPort.Text   = AppKey("AntennaService_MqttPort");
            TxtMqttUser.Text   = AppKey("AntennaService_MqttUsername");
            TxtMqttTopic.Text  = AppKey("AntennaService_TopicFilter");
            TxtDebounce.Text   = AppKey("AntennaService_DebounceSeconds");

            // Email / SMTP
            TxtSmtpHost.Text  = AppKey("SMTP_Host");
            TxtSmtpPort.Text  = AppKey("SMTP_Port");
            TxtSmtpUser.Text  = AppKey("SMTP_User");
            TxtFromEmail.Text = AppKey("SMTP_FromEmail");
            TxtFromName.Text  = AppKey("SMTP_FromName");

            // Notifications
            DdlReportEnnx.SelectedValue = AppKey("Report_Ennx").ToLower() == "true" ? "true" : "false";
            TxtEnnxRecipients.Text = AppKey("SmsRecipients_Report_Ennx");

            // Email recipients list
            LoadRecipients();

            // Report automation config
            LoadReportConfig();

            // Printer routing JSON
            string routingPath = @"C:\idash_prints\printer_routing.json";
            TxtPrintRouting.Text = System.IO.File.Exists(routingPath)
                ? System.IO.File.ReadAllText(routingPath)
                : "{\n  \"iDash_Metal_IQ350.btw\": \"Your Printer Name Here\"\n}";

            // Scanning pages column visibility config
            LoadScanColumnsConfig();
        }
    }

    // -- open config for writing ------------------------------------------
    private Configuration OpenWebConfig()
    {
        return WebConfigurationManager.OpenWebConfiguration("~/");
    }

    // -- detect current browser URL --------------------------------------
    protected void BtnDetectPort_Click(object sender, EventArgs e)
    {
        string proto = Request.Url.Scheme.ToLower();
        if (DdlServerProtocol.Items.FindByValue(proto) != null)
            DdlServerProtocol.SelectedValue = proto;

        TxtServerPort.Text = Request.Url.Port.ToString();
        TxtServerHost.Text = Request.Url.Host;
        TxtServerVirtualPath.Text = Request.ApplicationPath != null && Request.ApplicationPath != "/" ? Request.ApplicationPath : "";

        string detectedUrl = Request.Url.GetLeftPart(UriPartial.Authority) + (Request.ApplicationPath != "/" ? Request.ApplicationPath : "");
        ShowOk("Detected active server parameters from browser URL: <strong>" + Server.HtmlEncode(detectedUrl) + "</strong>. Click 'Save & Update All Endpoints' to synchronize this across all scripts and configuration files.");
    }

    // -- save server port & protocol settings -----------------------------
    protected void BtnSaveServerPort_Click(object sender, EventArgs e)
    {
        try
        {
            string proto = DdlServerProtocol.SelectedValue.Trim().ToLower();
            if (proto != "http" && proto != "https") proto = "http";

            string portStr = TxtServerPort.Text.Trim();
            int port;
            if (!int.TryParse(portStr, out port) || port < 1 || port > 65535)
            {
                ShowErr("Invalid listening port: '" + portStr + "'. Port must be a valid number between 1 and 65535.");
                return;
            }

            string host = TxtServerHost.Text.Trim();
            if (string.IsNullOrEmpty(host)) host = "localhost";

            string vpath = TxtServerVirtualPath.Text.Trim();
            if (vpath == "/") vpath = "";
            if (!string.IsNullOrEmpty(vpath) && !vpath.StartsWith("/")) vpath = "/" + vpath;
            vpath = vpath.TrimEnd('/');

            bool isStandard = (proto == "http" && port == 80) || (proto == "https" && port == 443);
            string authority = host + (isStandard ? "" : ":" + port);
            string baseUrl = proto + "://" + authority + vpath;
            string runnerUrl = baseUrl + "/va_report_automator_runner.aspx";
            string apiBase = baseUrl + "/api";
            string tokenUrl = baseUrl + "/connect/token";

            // 1. Update web.config
            var cfg = OpenWebConfig();
            SetAppKey(cfg, "App_Protocol", proto);
            SetAppKey(cfg, "App_Port", port.ToString());
            SetAppKey(cfg, "App_Host", host);
            SetAppKey(cfg, "App_VirtualPath", vpath);
            SetAppKey(cfg, "App_BaseUrl", baseUrl);
            SetAppKey(cfg, "AuthServerUrl", baseUrl);
            cfg.Save(ConfigurationSaveMode.Minimal);

            // 2. Update AutoReportRunner.ps1
            UpdateAutoReportRunnerScript(runnerUrl);

            // 3. Update remote_db_update.ps1
            UpdateRemoteDbUpdateScripts(baseUrl);

            // 4. Update report_automation.json
            UpdateReportAutomationJson(baseUrl, runnerUrl);

            // 5. Update printserver_appsettings.json
            UpdatePrintServerAppSettings(baseUrl);

            // 6. Generate elevated IIS & Firewall rollout script
            string iisScript = BuildIisBindingScript(proto, port, host, baseUrl);
            string scriptPath = Server.MapPath("~/downloads/Scripts/apply_server_port.ps1");
            File.WriteAllText(scriptPath, iisScript, System.Text.Encoding.UTF8);
            string rootScriptPath = Server.MapPath("~/apply_server_port.ps1");
            File.WriteAllText(rootScriptPath, iisScript, System.Text.Encoding.UTF8);

            // 7. Update on-screen controls & preview
            UpdateRunnerScriptPreview(runnerUrl);

            string linkHtml = "<a href=\"" + baseUrl + "/index.aspx\" target=\"_blank\" style=\"color:#10b981;font-weight:700;text-decoration:underline;\">" + baseUrl + "</a>";
            ShowOk("Listening port and server settings saved! All internal endpoints updated to: <strong>" + linkHtml + "</strong>.<br/>" +
                   "<small style=\"opacity:0.9;\">&#10003; Updated web.config &nbsp;|&nbsp; &#10003; AutoReportRunner.ps1 &nbsp;|&nbsp; &#10003; remote_db_update.ps1 &nbsp;|&nbsp; &#10003; report_automation.json &nbsp;|&nbsp; &#10003; printserver_appsettings.json &nbsp;|&nbsp; &#10003; apply_server_port.ps1</small><br/>" +
                   "<small style=\"margin-top:4px;display:inline-block;\"><strong>Next Step:</strong> Run <code>apply_server_port.ps1</code> in an elevated PowerShell prompt to bind port " + port + " in IIS and Windows Firewall.</small>");
        }
        catch (Exception ex)
        {
            ShowErr("Error saving server port settings: " + ex.Message);
        }
    }

    // -- download IIS binding script --------------------------------------
    protected void BtnDownloadIisScript_Click(object sender, EventArgs e)
    {
        string proto = DdlServerProtocol.SelectedValue.Trim().ToLower();
        int port;
        if (!int.TryParse(TxtServerPort.Text.Trim(), out port) || port < 1 || port > 65535) port = 8181;
        string host = TxtServerHost.Text.Trim();
        if (string.IsNullOrEmpty(host)) host = "localhost";
        string baseUrl = GetConfiguredBaseUrl();

        string script = BuildIisBindingScript(proto, port, host, baseUrl);
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition", "attachment; filename=\"apply_server_port.ps1\"");
        Response.Write(script);
        Response.End();
    }

    // -- save database ----------------------------------------------------
    protected void BtnSaveDb_Click(object sender, EventArgs e)
    {
        try
        {
            var cfg  = OpenWebConfig();
            var csEl = cfg.ConnectionStrings.ConnectionStrings["iDash"]
                ?? cfg.ConnectionStrings.ConnectionStrings["iDash"];
            if (csEl == null) { ShowErr("Connection string not found in web.config."); return; }

            var existing = csEl.ConnectionString;
            string server = TxtDbServer.Text.Trim();
            string db     = TxtDbName.Text.Trim();
            string user   = TxtDbUser.Text.Trim();
            string pass   = TxtDbPass.Text.Trim();

            if (string.IsNullOrEmpty(server)) server = GetConnPart(existing, "Data Source");
            if (string.IsNullOrEmpty(db))     db     = GetConnPart(existing, "Database");
            if (string.IsNullOrEmpty(user))   user   = GetConnPart(existing, "User ID");
            if (string.IsNullOrEmpty(pass))   pass   = GetConnPart(existing, "Password");

            string newCs =
                "Data Source=" + server + ";Database=" + db + ";User ID=" + user + ";Password=" + pass +
                ";Encrypt=False;TrustServerCertificate=True;Connect Timeout=30";

            string[] csNames = new string[] { "iDash", "iDashDB", "iDash", "iDashDB" };
            foreach (var name in csNames)
            {
                var el = cfg.ConnectionStrings.ConnectionStrings[name];
                if (el != null) el.ConnectionString = newCs;
                else cfg.ConnectionStrings.ConnectionStrings.Add(new System.Configuration.ConnectionStringSettings(name, newCs, "System.Data.SqlClient"));
            }

            cfg.Save(ConfigurationSaveMode.Minimal);
            ShowOk("Database connection settings saved successfully to web.config.");
        }
        catch (Exception ex) { ShowErr("Error saving database settings: " + ex.Message); }
    }

    // -- save MQTT / fixed reader -----------------------------------------
    protected void BtnSaveMqtt_Click(object sender, EventArgs e)
    {
        try
        {
            var cfg = OpenWebConfig();
            if (!string.IsNullOrWhiteSpace(TxtMqttServer.Text)) SetAppKey(cfg, "AntennaService_MqttServer",    TxtMqttServer.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtMqttPort.Text))   SetAppKey(cfg, "AntennaService_MqttPort",      TxtMqttPort.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtMqttUser.Text))   SetAppKey(cfg, "AntennaService_MqttUsername",  TxtMqttUser.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtMqttPass.Text))   SetAppKey(cfg, "AntennaService_MqttPassword",  TxtMqttPass.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtMqttTopic.Text))  SetAppKey(cfg, "AntennaService_TopicFilter",   TxtMqttTopic.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtDebounce.Text))   SetAppKey(cfg, "AntennaService_DebounceSeconds", TxtDebounce.Text.Trim());
            cfg.Save(ConfigurationSaveMode.Minimal);
            ShowOk("Fixed Reader / MQTT settings saved. The antenna service will reconnect on next startup.");
        }
        catch (Exception ex) { ShowErr("Error saving MQTT settings: " + ex.Message); }
    }

    // -- test MQTT broker TCP connectivity --------------------------------
    protected void BtnTestMqtt_Click(object sender, EventArgs e)
    {
        string host = !string.IsNullOrWhiteSpace(TxtMqttServer.Text)
            ? TxtMqttServer.Text.Trim()
            : AppKey("AntennaService_MqttServer");
        int port = 8883;
        int.TryParse(!string.IsNullOrWhiteSpace(TxtMqttPort.Text)
            ? TxtMqttPort.Text.Trim()
            : AppKey("AntennaService_MqttPort"), out port);
        if (port == 0) port = 8883;
        try
        {
            using (var tcp = new System.Net.Sockets.TcpClient())
            {
                tcp.Connect(host, port);
                ShowOk(string.Format("MQTT broker reachable at {0}:{1}. TCP connection successful.", host, port));
            }
        }
        catch (Exception ex)
        {
            ShowErr(string.Format("Cannot reach MQTT broker at {0}:{1} — {2}", host, port, ex.Message));
        }
    }

    // -- test antenna service (broker TCP + reader count) -----------------
    protected void BtnTestAntennaService_Click(object sender, EventArgs e)
    {
        string host = AppKey("AntennaService_MqttServer");
        int port = 8883;
        int.TryParse(AppKey("AntennaService_MqttPort"), out port);
        if (port == 0) port = 8883;

        // 1. TCP broker check
        bool brokerOk = false;
        string brokerMsg = "";
        try
        {
            using (var tcp = new System.Net.Sockets.TcpClient())
            {
                tcp.Connect(host, port);
                brokerOk = true;
                brokerMsg = string.Format("MQTT broker reachable at {0}:{1}", host, port);
            }
        }
        catch (Exception ex)
        {
            brokerMsg = string.Format("Cannot reach MQTT broker at {0}:{1} — {2}", host, port, ex.Message);
        }

        // 2. Reader count from DB
        int readerCount = 0;
        string readerMsg = "";
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
            using (var cn = new System.Data.SqlClient.SqlConnection(connStr))
            {
                cn.Open();
                using (var cmd = new System.Data.SqlClient.SqlCommand("SELECT COUNT(*) FROM dbo.reader", cn))
                    readerCount = (int)cmd.ExecuteScalar();
                readerMsg = readerCount + " reader(s) registered in database.";
            }
        }
        catch (Exception ex) { readerMsg = "Could not query readers: " + ex.Message; }

        if (brokerOk)
            ShowOk(string.Format("&#9989; Antenna Service: {0}. {1}", brokerMsg, readerMsg));
        else
            ShowErr(string.Format("&#9888; Antenna Service: {0}. {1}", brokerMsg, readerMsg));
    }

    protected void BtnSavePrintRouting_Click(object sender, EventArgs e)
    {
        try
        {
            string routingPath = @"C:\idash_prints\printer_routing.json";
            string dir = System.IO.Path.GetDirectoryName(routingPath);
            if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
            System.IO.File.WriteAllText(routingPath, TxtPrintRouting.Text);
            ShowOk("Printer routing table saved. The spooler will use the new routes on the next print job.");
        }
        catch (Exception ex) { ShowErr("Error saving printer routing: " + ex.Message); }
    }

    // -- save email SMTP --------------------------------------------------
    protected void BtnSaveEmail_Click(object sender, EventArgs e)
    {
        try
        {
            var cfg = OpenWebConfig();
            if (!string.IsNullOrWhiteSpace(TxtSmtpHost.Text))  SetAppKey(cfg, "SMTP_Host",      TxtSmtpHost.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtSmtpPort.Text))  SetAppKey(cfg, "SMTP_Port",      TxtSmtpPort.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtSmtpUser.Text))  SetAppKey(cfg, "SMTP_User",      TxtSmtpUser.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtSmtpPass.Text))  SetAppKey(cfg, "SMTP_Password",  TxtSmtpPass.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtFromEmail.Text)) SetAppKey(cfg, "SMTP_FromEmail", TxtFromEmail.Text.Trim());
            if (!string.IsNullOrWhiteSpace(TxtFromName.Text))  SetAppKey(cfg, "SMTP_FromName",  TxtFromName.Text.Trim());
            cfg.Save(ConfigurationSaveMode.Minimal);
            ShowOk("Email / SMTP settings saved successfully.");
        }
        catch (Exception ex) { ShowErr("Error saving email settings: " + ex.Message); }
    }

    // -- save notifications -----------------------------------------------
    protected void BtnSaveAlerts_Click(object sender, EventArgs e)
    {
        try
        {
            var cfg = OpenWebConfig();
            SetAppKey(cfg, "Report_Ennx",      DdlReportEnnx.SelectedValue);
            if (!string.IsNullOrWhiteSpace(TxtEnnxRecipients.Text)) SetAppKey(cfg, "SmsRecipients_Report_Ennx",  TxtEnnxRecipients.Text.Trim());
            cfg.Save(ConfigurationSaveMode.Minimal);
            ShowOk("Notification settings saved successfully.");
        }
        catch (Exception ex) { ShowErr("Error saving notification settings: " + ex.Message); }
    }

    // -- recipients -------------------------------------------------------
    private void LoadRecipients()
    {
        var emails = EmailHelper.GetRecipients();
        RptEmails.DataSource = emails;
        RptEmails.DataBind();
        PnlNoEmails.Visible = (emails.Count == 0);
    }

    protected void BtnAddEmail_Click(object sender, EventArgs e)
    {
        string email = TxtNewEmail.Text.Trim();
        if (string.IsNullOrWhiteSpace(email)) return;
        try
        {
            EmailHelper.AddRecipient(email);
            TxtNewEmail.Text = "";
            LoadRecipients();
            ShowRcptOk("Recipient added: " + Server.HtmlEncode(email));
        }
        catch (Exception ex)
        {
            ShowRcptErr("Failed to add recipient: " + ex.Message);
        }
    }

    protected void RptEmails_ItemCommand(object source, RepeaterCommandEventArgs e)
    {
        if (e.CommandName == "Remove")
        {
            string email = e.CommandArgument.ToString();
            try
            {
                EmailHelper.RemoveRecipient(email);
                LoadRecipients();
                ShowRcptOk("Recipient removed: " + Server.HtmlEncode(email));
            }
            catch (Exception ex)
            {
                ShowRcptErr("Failed to remove recipient: " + ex.Message);
            }
        }
    }

    // -- report automation config -----------------------------------------
    private ReportAutomationConfig ReadReportConfig()
    {
        if (!File.Exists(ReportConfigPath)) return new ReportAutomationConfig();
        try
        {
            string json = File.ReadAllText(ReportConfigPath);
            return new JavaScriptSerializer().Deserialize<ReportAutomationConfig>(json) ?? new ReportAutomationConfig();
        }
        catch { return new ReportAutomationConfig(); }
    }

    private void SaveReportConfig(ReportAutomationConfig config)
    {
        string dir = Path.GetDirectoryName(ReportConfigPath);
        if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
        File.WriteAllText(ReportConfigPath, new JavaScriptSerializer().Serialize(config));
    }

    private void LoadReportConfig()
    {
        var c = ReadReportConfig();
        ChkEnabled.Checked     = c.Enabled;
        TxtScheduleTime.Text   = c.ScheduledTime ?? "19:00";
        TxtSubject.Text        = c.SubjectTitle ?? "";

        foreach (ListItem item in CblFields.Items) item.Selected = false;
        if (c.ExcelFields != null)
        {
            foreach (string f in c.ExcelFields)
            {
                var li = CblFields.Items.FindByValue(f);
                if (li != null) li.Selected = true;
            }
        }
    }

    protected void BtnSaveReportConfig_Click(object sender, EventArgs e)
    {
        try
        {
            var c = ReadReportConfig();
            c.Enabled       = ChkEnabled.Checked;
            c.ScheduledTime = TxtScheduleTime.Text;
            c.SubjectTitle  = string.IsNullOrWhiteSpace(TxtSubject.Text)
                              ? "Automated ENNX Report - {Site} - {Date}"
                              : TxtSubject.Text.Trim();

            c.ExcelFields = new List<string>();
            foreach (ListItem item in CblFields.Items)
                if (item.Selected) c.ExcelFields.Add(item.Value);

            SaveReportConfig(c);
            ShowOk("Report automation settings saved successfully.");
        }
        catch (Exception ex) { ShowErr("Error saving report settings: " + ex.Message); }
    }

    protected void BtnDownloadScript_Click(object sender, EventArgs e)
    {
        string runnerUrl = GetConfiguredBaseUrl() + "/va_report_automator_runner.aspx";
        string script =
@"# iDash Report Automation Runner
$url = """ + runnerUrl + @"""
try {
    Write-Host ""Triggering Auto Report Generation at $url""
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 300
    Write-Host ""Status: $($resp.StatusCode) $($resp.StatusDescription)""
    Write-Host $resp.Content
} catch {
    Write-Error ""Failed to execute automation: $_""
}
";
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition", "attachment; filename=\"AutoReportRunner.ps1\"");
        Response.Write(script);
        Response.End();
    }

    // -- run one-time SQL -------------------------------------------------
    protected void BtnRunSql_Click(object sender, EventArgs e)
    {
        string station = TxtStationNum.Text.Trim();
        string site    = TxtSiteName.Text.Trim();

        if (string.IsNullOrEmpty(station) || string.IsNullOrEmpty(site))
        {
            LitSqlResult.Text = "<div class=\"msg-err\" style=\"margin-top:10px;\">&#9888; Please enter both Station Number and Site Name before executing.</div>";
            return;
        }

        if (!System.Text.RegularExpressions.Regex.IsMatch(station, @"^\d{3}$"))
        {
            LitSqlResult.Text = "<div class=\"msg-err\" style=\"margin-top:10px;\">&#9888; Station Number must be exactly 3 digits (e.g. 512, 649). The import pipeline uses a 3-character prefix match.</div>";
            return;
        }

        string companyName = station + " " + site;
        string sql =
            "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE SUBSTRING(name,1,3) = @station)\r\n" +
            "    INSERT INTO dbo.company (name) VALUES (@companyName);\r\n" +
            "SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.company WHERE SUBSTRING(name,1,3) = @station) THEN 1 ELSE 0 END AS CompanyExists;";

        try
        {
            string cs = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@station", station);
                    cmd.Parameters.AddWithValue("@companyName", companyName);
                    int exists = (int)cmd.ExecuteScalar();
                    LitSqlResult.Text = exists == 1
                        ? "<div class=\"msg-ok\" style=\"margin-top:10px;\">&#9989; Company <strong>" + Server.HtmlEncode(companyName) + "</strong> is confirmed in the database. All imports will now map to this company.</div>"
                        : "<div class=\"msg-err\" style=\"margin-top:10px;\">&#9888; SQL ran but company row was not found after insert. Check database permissions.</div>";
                }
            }
        }
        catch (Exception ex)
        {
            LitSqlResult.Text = "<div class=\"msg-err\" style=\"margin-top:10px;\">&#9888; SQL error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // -- test database connection -----------------------------------------
    protected void BtnTestConn_Click(object sender, EventArgs e)
    {
        try
        {
            var csEntry = ConfigurationManager.ConnectionStrings["iDash"]
                ?? ConfigurationManager.ConnectionStrings["iDash"];
            string cs = csEntry != null ? csEntry.ConnectionString : "";
            using (var conn = new SqlConnection(cs))
            {
                conn.Open();
                string sql = @"
                    SELECT
                        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'asset')   AS HasAsset,
                        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'company') AS HasCompany,
                        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sysuser') AS HasSysuser,
                        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'location') AS HasLocation,
                        (SELECT COUNT(*) FROM dbo.company) AS CompanyCount,
                        (SELECT COUNT(*) FROM dbo.asset)   AS AssetCount,
                        (SELECT COUNT(*) FROM dbo.sysuser) AS UserCount";
                using (var cmd = new SqlCommand(sql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        int companies = (int)rdr["CompanyCount"];
                        int assets    = (int)rdr["AssetCount"];
                        int users     = (int)rdr["UserCount"];
                        bool allTables = (int)rdr["HasAsset"] == 1 && (int)rdr["HasCompany"] == 1 &&
                                         (int)rdr["HasSysuser"] == 1 && (int)rdr["HasLocation"] == 1;

                        string status = allTables
                            ? "&#9989; <strong>Connection successful.</strong> Core tables verified (asset, company, sysuser, location)."
                            : "&#9888; Connected but some core tables are missing. Database may need initialization.";

                        LitMsg.Text = "<div class=\"msg-ok\">" + status +
                            "<br/><span style='font-size:12px;color:var(--muted);'>Companies: " + companies +
                            " &bull; Assets: " + assets.ToString("N0") +
                            " &bull; Users: " + users + "</span></div>";
                    }
                }
            }
        }
        catch (Exception ex)
        {
            LitMsg.Text = "<div class=\"msg-err\">&#9888; <strong>Connection failed:</strong> " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // -- Service control helpers (native Windows sc.exe — no System.ServiceProcess assembly dependency) --

    // Services we manage: display name, Windows service name
    private static readonly string[][] ManagedServices = new string[][] {
        new[] { "RabbitMQ",       "RabbitMQ" },
        new[] { "Print Server",   "iDashPrintService" },
        new[] { "IIS (W3SVC)",    "W3SVC" },
    };

    private static string RunScCommand(string args, int timeoutMs = 15000)
    {
        try
        {
            var psi = new System.Diagnostics.ProcessStartInfo("sc.exe", args)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };
            using (var proc = System.Diagnostics.Process.Start(psi))
            {
                if (proc.WaitForExit(timeoutMs))
                {
                    return proc.StandardOutput.ReadToEnd();
                }
                try { proc.Kill(); } catch { }
                return "Timeout";
            }
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    private static string GetWindowsServiceStatus(string serviceName)
    {
        string outText = RunScCommand("query \"" + serviceName + "\"");
        if (outText.IndexOf("RUNNING", StringComparison.OrdinalIgnoreCase) >= 0) return "Running";
        if (outText.IndexOf("STOPPED", StringComparison.OrdinalIgnoreCase) >= 0) return "Stopped";
        if (outText.IndexOf("START_PENDING", StringComparison.OrdinalIgnoreCase) >= 0) return "StartPending";
        if (outText.IndexOf("STOP_PENDING", StringComparison.OrdinalIgnoreCase) >= 0) return "StopPending";
        if (outText.IndexOf("PAUSED", StringComparison.OrdinalIgnoreCase) >= 0) return "Paused";
        if (outText.IndexOf("1060", StringComparison.OrdinalIgnoreCase) >= 0 || outText.IndexOf("does not exist", StringComparison.OrdinalIgnoreCase) >= 0) return "Not Installed";
        return "Unknown";
    }

    private static string ResolveServiceName(string serviceName)
    {
        if (serviceName.Equals("iDashPrintService", StringComparison.OrdinalIgnoreCase))
        {
            string st = GetWindowsServiceStatus("iDash Print Service");
            if (st != "Not Installed" && st != "Unknown")
                return "iDash Print Service";
        }
        else if (serviceName.Equals("iDash Print Service", StringComparison.OrdinalIgnoreCase))
        {
            string st = GetWindowsServiceStatus("iDashPrintService");
            if (st != "Not Installed" && st != "Unknown")
                return "iDashPrintService";
        }
        return serviceName;
    }

    private List<Dictionary<string, object>> GetServiceStatus()
    {
        var results = new List<Dictionary<string, object>>();
        foreach (var svc in ManagedServices)
        {
            var info = new Dictionary<string, object>();
            info["name"] = svc[0];
            var resolvedName = ResolveServiceName(svc[1]);
            info["service"] = resolvedName;
            try
            {
                info["status"] = GetWindowsServiceStatus(resolvedName);
            }
            catch (Exception ex)
            {
                info["status"] = "Error";
                info["error"] = ex.Message;
            }
            results.Add(info);
        }

        // AntennaLocationService (in-process, not a Windows service)
        var antenna = new Dictionary<string, object>();
        antenna["name"] = "Antenna Service";
        antenna["service"] = "AntennaLocationService";
        try
        {
            var statusObj = AntennaLocationService.GetStatus();
            var statusDict = new JavaScriptSerializer().Serialize(statusObj);
            var parsed = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(statusDict);
            antenna["status"] = (parsed.ContainsKey("Running") && (bool)parsed["Running"]) ? "Running" : "Stopped";
            antenna["uptime"] = parsed.ContainsKey("Uptime") ? parsed["Uptime"] : "";
        }
        catch
        {
            antenna["status"] = "Unknown";
        }
        results.Add(antenna);

        return results;
    }

    private List<Dictionary<string, object>> RestartAllServices()
    {
        var results = new List<Dictionary<string, object>>();

        // Restart in order: RabbitMQ first (reader depends on it), then IIS, then Print Server
        results.Add(RestartWindowsService("RabbitMQ", "RabbitMQ", 60));
        results.Add(RestartWindowsService("IIS (W3SVC)", "W3SVC", 30));
        // After W3SVC restart, give IIS a moment to come back
        System.Threading.Thread.Sleep(2000);
        results.Add(RestartWindowsService("Print Server", "iDashPrintService", 30));

        // AntennaLocationService auto-starts on next page request, just note it
        var antenna = new Dictionary<string, object>();
        antenna["name"] = "Antenna Service";
        antenna["status"] = "Will auto-start on next page request";
        antenna["ok"] = true;
        results.Add(antenna);

        return results;
    }

    private List<Dictionary<string, object>> RestartSingleService(string svcKey)
    {
        var results = new List<Dictionary<string, object>>();
        switch (svcKey)
        {
            case "RabbitMQ":
                results.Add(RestartWindowsService("RabbitMQ", "RabbitMQ", 60));
                break;
            case "PrintServer":
                results.Add(RestartWindowsService("Print Server", "iDashPrintService", 30));
                break;
            case "IIS":
                results.Add(RestartWindowsService("IIS (W3SVC)", "W3SVC", 30));
                break;
            case "Antenna":
                // Force restart by triggering dead-thread detection
                AntennaLocationService.EnsureStarted();
                var a = new Dictionary<string, object>();
                a["name"] = "Antenna Service";
                a["status"] = "Restarted";
                a["ok"] = true;
                results.Add(a);
                break;
            default:
                var err = new Dictionary<string, object>();
                err["name"] = svcKey;
                err["error"] = "Unknown service: " + svcKey;
                err["ok"] = false;
                results.Add(err);
                break;
        }
        return results;
    }

    private Dictionary<string, object> RestartWindowsService(string displayName, string serviceName, int timeoutSec)
    {
        var result = new Dictionary<string, object>();
        result["name"] = displayName;
        try
        {
            var resolvedName = ResolveServiceName(serviceName);
            result["service"] = resolvedName;

            // Stop service
            RunScCommand("stop \"" + resolvedName + "\"");
            int waited = 0;
            while (waited < timeoutSec * 1000)
            {
                string st = GetWindowsServiceStatus(resolvedName);
                if (st == "Stopped" || st == "Not Installed") break;
                System.Threading.Thread.Sleep(1000);
                waited += 1000;
            }

            // Start service
            RunScCommand("start \"" + resolvedName + "\"");
            waited = 0;
            while (waited < timeoutSec * 1000)
            {
                string st = GetWindowsServiceStatus(resolvedName);
                if (st == "Running") break;
                System.Threading.Thread.Sleep(1000);
                waited += 1000;
            }

            string finalStatus = GetWindowsServiceStatus(resolvedName);
            result["status"] = finalStatus;
            result["ok"] = (finalStatus == "Running");
            if (finalStatus != "Running")
                result["error"] = "Service status after restart: " + finalStatus;
        }
        catch (Exception ex)
        {
            result["status"] = "Error";
            result["error"] = ex.Message;
            result["ok"] = false;
        }
        return result;
    }

    // -- Scanning Pages Column Visibility Config --------------------------
    private string ScanColumnsConfigPath
    {
        get { return Server.MapPath("~/App_Data/scan_columns_config.json"); }
    }

    private void LoadScanColumnsConfig()
    {
        try
        {
            if (File.Exists(ScanColumnsConfigPath))
            {
                string json = File.ReadAllText(ScanColumnsConfigPath);
                var js = new JavaScriptSerializer();
                var data = js.Deserialize<Dictionary<string, object>>(json);
                if (data != null && data.ContainsKey("va_inventory"))
                {
                    var pageObj = data["va_inventory"] as Dictionary<string, object>;
                    if (pageObj != null && pageObj.ContainsKey("columns"))
                    {
                        var cols = pageObj["columns"] as System.Collections.ArrayList;
                        if (cols != null)
                        {
                            foreach (Dictionary<string, object> c in cols)
                            {
                                int idx = Convert.ToInt32(c["index"]);
                                bool vis = Convert.ToBoolean(c["visible"]);
                                switch (idx)
                                {
                                    case 0: ChkCol_0.Checked = vis; break;
                                    case 1: ChkCol_1.Checked = true; break;
                                    case 2: ChkCol_2.Checked = true; break;
                                    case 3: ChkCol_3.Checked = vis; break;
                                    case 4: ChkCol_4.Checked = vis; break;
                                    case 5: ChkCol_5.Checked = vis; break;
                                    case 6: ChkCol_6.Checked = vis; break;
                                    case 7: ChkCol_7.Checked = vis; break;
                                    case 8: ChkCol_8.Checked = vis; break;
                                    case 9: ChkCol_9.Checked = vis; break;
                                    case 10: ChkCol_10.Checked = vis; break;
                                    case 11: ChkCol_11.Checked = vis; break;
                                    case 12: ChkCol_12.Checked = vis; break;
                                    case 13: ChkCol_13.Checked = vis; break;
                                    case 14: ChkCol_14.Checked = vis; break;
                                    case 15: ChkCol_15.Checked = vis; break;
                                    case 16: ChkCol_16.Checked = vis; break;
                                    case 17: ChkCol_17.Checked = vis; break;
                                    case 18: ChkCol_18.Checked = vis; break;
                                    case 19: ChkCol_19.Checked = vis; break;
                                    case 20: ChkCol_20.Checked = vis; break;
                                    case 21: ChkCol_21.Checked = vis; break;
                                    case 22: ChkCol_22.Checked = vis; break;
                                    case 23: ChkCol_23.Checked = vis; break;
                                    case 24: ChkCol_24.Checked = vis; break;
                                    case 25: ChkCol_25.Checked = vis; break;
                                    case 26: ChkCol_26.Checked = vis; break;
                                    case 27: ChkCol_27.Checked = vis; break;
                                }
                            }
                            return;
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            LitColMsg.Text = "<div class=\"msg-err\">&#9888; Error loading columns config: " + ex.Message + "</div>";
        }

        // Defaults
        ChkCol_0.Checked = false;
        ChkCol_1.Checked = true;
        ChkCol_2.Checked = true;
        ChkCol_3.Checked = true;
        ChkCol_4.Checked = false;
        ChkCol_5.Checked = false;
        ChkCol_6.Checked = true;
        ChkCol_7.Checked = false;
        ChkCol_8.Checked = false;
        ChkCol_9.Checked = true;
        ChkCol_10.Checked = false;
        ChkCol_11.Checked = true;
        ChkCol_12.Checked = false;
        ChkCol_13.Checked = false;
        ChkCol_14.Checked = false;
        ChkCol_15.Checked = false;
        ChkCol_16.Checked = false;
        ChkCol_17.Checked = false;
        ChkCol_18.Checked = false;
        ChkCol_19.Checked = false;
        ChkCol_20.Checked = false;
        ChkCol_21.Checked = false;
        ChkCol_22.Checked = false;
        ChkCol_23.Checked = false;
        ChkCol_24.Checked = false;
        ChkCol_25.Checked = false;
        ChkCol_26.Checked = true;
        ChkCol_27.Checked = true;
    }

    protected void BtnSaveScanColumns_Click(object sender, EventArgs e)
    {
        try
        {
            var cols = new List<object>
            {
                new { index = 0, id = "chkCol_0", label = "Print Checkbox", field = "(system)", visible = ChkCol_0.Checked, locked = false, desc = "Batch server printing selection checkbox" },
                new { index = 1, id = "chkCol_1", label = "Status", field = "(system)", visible = true, locked = true, desc = "Found, Not Found, Move Here?, Unknown (Required)" },
                new { index = 2, id = "chkCol_2", label = "Asset Tag", field = "name", visible = true, locked = true, desc = "Primary asset barcode / RFID identifier (Required)" },
                new { index = 3, id = "chkCol_3", label = "Description", field = "description", visible = ChkCol_3.Checked, locked = false, desc = "Equipment description and item name" },
                new { index = 4, id = "chkCol_4", label = "Manufacturer", field = "text1", visible = ChkCol_4.Checked, locked = false, desc = "Equipment manufacturer / vendor" },
                new { index = 5, id = "chkCol_5", label = "Model", field = "text2", visible = ChkCol_5.Checked, locked = false, desc = "Equipment model identifier" },
                new { index = 6, id = "chkCol_6", label = "Serial #", field = "text3", visible = ChkCol_6.Checked, locked = false, desc = "Manufacturer equipment serial number" },
                new { index = 7, id = "chkCol_7", label = "Equipment Category", field = "text4", visible = ChkCol_7.Checked, locked = false, desc = "Equipment category / classification" },
                new { index = 8, id = "chkCol_8", label = "Service Pointer", field = "text5", visible = ChkCol_8.Checked, locked = false, desc = "VA Service pointer code" },
                new { index = 9, id = "chkCol_9", label = "SP + Location", field = "text6", visible = ChkCol_9.Checked, locked = false, desc = "Official room location (SP + Room) in database" },
                new { index = 10, id = "chkCol_10", label = "Station Number", field = "text7", visible = ChkCol_10.Checked, locked = false, desc = "VA station / facility number" },
                new { index = 11, id = "chkCol_11", label = "CMR / EIL", field = "text8", visible = ChkCol_11.Checked, locked = false, desc = "CMR / Equipment Inventory Listing code" },
                new { index = 12, id = "chkCol_12", label = "Purchase Order #", field = "text9", visible = ChkCol_12.Checked, locked = false, desc = "Procurement purchase order number" },
                new { index = 13, id = "chkCol_13", label = "Physical Inventory Date", field = "text10", visible = ChkCol_13.Checked, locked = false, desc = "Raw physical inventory date from legacy feed" },
                new { index = 14, id = "chkCol_14", label = "SP + Previous Location", field = "text11", visible = ChkCol_14.Checked, locked = false, desc = "Previous room assignment before relocation" },
                new { index = 15, id = "chkCol_15", label = "Entry Number", field = "text12", visible = ChkCol_15.Checked, locked = false, desc = "VistA/AEMS entry sequence number" },
                new { index = 16, id = "chkCol_16", label = "Empl_ID", field = "text13", visible = ChkCol_16.Checked, locked = false, desc = "Assigned custodian / employee ID" },
                new { index = 17, id = "chkCol_17", label = "Substation", field = "text14", visible = ChkCol_17.Checked, locked = false, desc = "VA division / substation code" },
                new { index = 18, id = "chkCol_18", label = "Asset Value", field = "text15", visible = ChkCol_18.Checked, locked = false, desc = "Acquisition or replacement asset value ($)" },
                new { index = 19, id = "chkCol_19", label = "Location Tagged (Found)", field = "text16", visible = ChkCol_19.Checked, locked = false, desc = "Room where asset tag was originally commissioned" },
                new { index = 20, id = "chkCol_20", label = "Tagged On Date", field = "text17", visible = ChkCol_20.Checked, locked = false, desc = "Commissioning date tag was applied to asset" },
                new { index = 21, id = "chkCol_21", label = "Tagged", field = "text18", visible = ChkCol_21.Checked, locked = false, desc = "Physical tag attachment status flag" },
                new { index = 22, id = "chkCol_22", label = "Tag Type", field = "text19", visible = ChkCol_22.Checked, locked = false, desc = "RFID tag hardware model (Alien, Confidex, etc)" },
                new { index = 23, id = "chkCol_23", label = "Notes", field = "text20", visible = ChkCol_23.Checked, locked = false, desc = "Technician notes and operational comments" },
                new { index = 24, id = "chkCol_24", label = "Last Inventoried", field = "lastinventoried", visible = ChkCol_24.Checked, locked = false, desc = "Last inventory observation timestamp" },
                new { index = 25, id = "chkCol_25", label = "Scanned Loc", field = "(session)", visible = ChkCol_25.Checked, locked = false, desc = "Physical room currently being swept" },
                new { index = 26, id = "chkCol_26", label = "Reads", field = "(session)", visible = ChkCol_26.Checked, locked = false, desc = "Total RFID read count counter during sweep" },
                new { index = 27, id = "chkCol_27", label = "Action (X)", field = "(session)", visible = ChkCol_27.Checked, locked = false, desc = "Button to remove stray items from session" }
            };

            var pageData = new Dictionary<string, object>();
            pageData.Add("columns", cols);
            var payload = new Dictionary<string, object>();
            payload.Add("va_inventory", pageData);

            var js = new JavaScriptSerializer();
            string json = js.Serialize(payload);

            string dir = Path.GetDirectoryName(ScanColumnsConfigPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            File.WriteAllText(ScanColumnsConfigPath, json);
            LitColMsg.Text = "<div class=\"msg-ok\" style=\"background:rgba(16,185,129,0.12); color:#10b981; border:1px solid rgba(16,185,129,0.3); padding:10px 14px; border-radius:8px; margin-bottom:14px; font-weight:700;\">&#10004; Scanning column visibility configuration saved successfully! All handheld devices will use this layout.</div>";
        }
        catch (Exception ex)
        {
            LitColMsg.Text = "<div class=\"msg-err\">&#9888; Failed to save column configuration: " + ex.Message + "</div>";
        }
    }

    // -- License Management Methods --------------------------------------
    private string GetAllLicenses()
    {
        var js = new JavaScriptSerializer();
        var readers = new List<object>();
        var servers = new List<object>();
        var users = new List<object>();
        var scanners = new List<object>();
        var mqttClients = new List<object>();

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();

            // Readers
            using (var cmd = new SqlCommand(
                @"SELECT r.id, r.name, r.readermodel, r.ipaddress, r.lastseen, r.companyid,
                         l.name as locationName, c.name as companyName
                  FROM reader r
                  LEFT JOIN location l ON r.locationid = l.id
                  LEFT JOIN company c ON r.companyid = c.id
                  ORDER BY r.name", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    readers.Add(new
                    {
                        id = rdr["id"],
                        name = Safe(rdr, "name"),
                        model = Safe(rdr, "readermodel"),
                        ip = Safe(rdr, "ipaddress"),
                        lastSeen = rdr["lastseen"] != DBNull.Value ? ((DateTimeOffset)rdr["lastseen"]).ToString("o") : null,
                        location = Safe(rdr, "locationName"),
                        site = Safe(rdr, "companyName")
                    });
                }
            }

            // Server status
            using (var cmd = new SqlCommand(
                "SELECT id, name, servertype, version, lastseen FROM serverstatus ORDER BY id", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    servers.Add(new
                    {
                        id = rdr["id"],
                        name = Safe(rdr, "name"),
                        serverType = Safe(rdr, "servertype"),
                        version = Safe(rdr, "version"),
                        lastSeen = rdr["lastseen"] != DBNull.Value ? ((DateTimeOffset)rdr["lastseen"]).ToString("o") : null
                    });
                }
            }

            // Scanner users (sysuser)
            using (var cmd = new SqlCommand(
                @"SELECT u.id, u.username, u.firstname, u.lastname, u.usertype, u.companyid,
                         c.name as companyName
                  FROM sysuser u
                  LEFT JOIN company c ON u.companyid = c.id
                  ORDER BY u.username", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    string fn = Safe(rdr, "firstname");
                    string ln = Safe(rdr, "lastname");
                    string full = ((fn + " " + ln).Trim());
                    users.Add(new
                    {
                        id = rdr["id"],
                        username = Safe(rdr, "username"),
                        fullName = string.IsNullOrEmpty(full) ? null : full,
                        userType = Safe(rdr, "usertype"),
                        site = Safe(rdr, "companyName")
                    });
                }
            }

            // Scanners (handheld devices)
            using (var cmd = new SqlCommand(
                "SELECT id, deviceid, companyname, inactive, description, lastseen FROM scanner ORDER BY id", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    scanners.Add(new
                    {
                        id = rdr["id"],
                        deviceId = Safe(rdr, "deviceid"),
                        site = Safe(rdr, "companyname"),
                        inactive = rdr["inactive"] != DBNull.Value && (bool)rdr["inactive"],
                        description = Safe(rdr, "description"),
                        lastSeen = rdr["lastseen"] != DBNull.Value ? ((DateTimeOffset)rdr["lastseen"]).ToString("o") : null
                    });
                }
            }

            // MQTT Clients
            using (var cmd = new SqlCommand(
                @"SELECT m.id, m.username, m.companyid, c.name as companyName
                  FROM mqttclient m
                  LEFT JOIN company c ON m.companyid = c.id
                  ORDER BY m.id", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    mqttClients.Add(new
                    {
                        id = rdr["id"],
                        username = Safe(rdr, "username"),
                        site = Safe(rdr, "companyName")
                    });
                }
            }
        }

        return js.Serialize(new { readers, servers, users, scanners, mqttClients });
    }

    private string DeleteLicenseItem(string table, string childTable, string childFk)
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);
        int id = Convert.ToInt32(data["id"]);

        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                // Delete children first (e.g. antennas for readers)
                if (!string.IsNullOrEmpty(childTable) && !string.IsNullOrEmpty(childFk))
                {
                    using (var cmd = new SqlCommand(
                        string.Format("DELETE FROM {0} WHERE {1} = @id", childTable, childFk), cn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.ExecuteNonQuery();
                    }
                }
                using (var cmd = new SqlCommand(
                    string.Format("DELETE FROM {0} WHERE id = @id", table), cn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    int rows = cmd.ExecuteNonQuery();

                    string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
                    string clientIp = Request.UserHostAddress;
                    LoginAuditHelper.LogAdminAction(username, clientIp, "LicenseItemDelete", "Table: " + table + ", ID: " + id + ", DeletedRows: " + rows);

                    return js.Serialize(new { success = true, deleted = rows });
                }
            }
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    private static string Safe(SqlDataReader rdr, string col)
    {
        try { return rdr[col] != DBNull.Value ? rdr[col].ToString() : ""; }
        catch { return ""; }
    }

    private string CartLicensesFilePath
    {
        get { return Server.MapPath("~/App_Data/cart_licenses.json"); }
    }

    private string GetCarts()
    {
        try
        {
            if (!File.Exists(CartLicensesFilePath))
                return "[]";
            return File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8);
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new { error = ex.Message });
        }
    }

    private string SaveCart()
    {
        var js = new JavaScriptSerializer();
        try
        {
            string body;
            using (var reader = new StreamReader(Request.InputStream))
                body = reader.ReadToEnd();

            var item = js.Deserialize<Dictionary<string, object>>(body);
            if (item == null) return js.Serialize(new { error = "Invalid payload" });

            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            if (File.Exists(CartLicensesFilePath))
            {
                string existingJson = File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8);
                list = js.Deserialize<List<Dictionary<string, object>>>(existingJson) ?? new List<Dictionary<string, object>>();
            }

            string id = item.ContainsKey("id") && item["id"] != null ? item["id"].ToString().Trim() : "";
            if (string.IsNullOrEmpty(id))
            {
                id = "cart-" + Guid.NewGuid().ToString("N").Substring(0, 8);
                item["id"] = id;
                list.Add(item);
            }
            else
            {
                int idx = list.FindIndex(x => x.ContainsKey("id") && x["id"] != null && x["id"].ToString() == id);
                if (idx >= 0)
                    list[idx] = item;
                else
                    list.Add(item);
            }

            string updatedJson = js.Serialize(list);
            File.WriteAllText(CartLicensesFilePath, updatedJson, System.Text.Encoding.UTF8);

            string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
            string clientIp = Request.UserHostAddress;
            LoginAuditHelper.LogAdminAction(username, clientIp, "CartLicenseSave", "ID: " + id);

            return js.Serialize(new { success = true, id = id });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    private string DeleteCart()
    {
        var js = new JavaScriptSerializer();
        try
        {
            string id = Request.QueryString["id"] ?? "";
            if (string.IsNullOrEmpty(id))
            {
                Request.InputStream.Position = 0;
                using (var sr = new StreamReader(Request.InputStream))
                {
                    string b = sr.ReadToEnd();
                    if (!string.IsNullOrEmpty(b))
                    {
                        var data = js.Deserialize<Dictionary<string, object>>(b);
                        if (data != null && data.ContainsKey("id") && data["id"] != null)
                            id = data["id"].ToString();
                    }
                }
            }
            if (string.IsNullOrEmpty(id)) return js.Serialize(new { error = "Missing cart ID" });

            if (!File.Exists(CartLicensesFilePath)) return js.Serialize(new { success = true });

            string existingJson = File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8);
            var list = js.Deserialize<List<Dictionary<string, object>>>(existingJson) ?? new List<Dictionary<string, object>>();
            list.RemoveAll(x => x.ContainsKey("id") && x["id"] != null && x["id"].ToString() == id);

            File.WriteAllText(CartLicensesFilePath, js.Serialize(list), System.Text.Encoding.UTF8);

            string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
            string clientIp = Request.UserHostAddress;
            LoginAuditHelper.LogAdminAction(username, clientIp, "CartLicenseDelete", "ID: " + id);

            return js.Serialize(new { success = true });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    private void DownloadCartKey(string id)
    {
        try
        {
            if (!File.Exists(CartLicensesFilePath)) return;
            var js = new JavaScriptSerializer();
            var list = js.Deserialize<List<Dictionary<string, object>>>(File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8));
            var cart = list.Find(x => x.ContainsKey("id") && x["id"] != null && x["id"].ToString() == id);
            if (cart != null && cart.ContainsKey("idashLicenseKey") && cart["idashLicenseKey"] != null)
            {
                string key = cart["idashLicenseKey"].ToString().Trim();
                string name = cart.ContainsKey("name") && cart["name"] != null ? cart["name"].ToString().Trim().ToLower().Replace(" ", "_") : "cart";
                string filename = name + ".idashlic";

                string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
                string clientIp = Request.UserHostAddress;
                LoginAuditHelper.LogAdminAction(username, clientIp, "CartLicenseDownload", "ID: " + id + ", File: " + filename);

                Response.Clear();
                Response.ContentType = "application/octet-stream";
                Response.AddHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
                Response.Write(key);
                Response.Flush();
                Response.End();
            }
        }
        catch { }
    }
}

// -- Report automation config model (mirrors ReportConfig in va_report_automation.aspx.cs) --
public class ReportAutomationConfig
{
    public bool Enabled { get; set; }
    public string ScheduledTime { get; set; }
    public string SubjectTitle { get; set; }
    public List<string> Recipients { get; set; }
    public List<string> ExcelFields { get; set; }
    public string IdPrefix { get; set; }

    public ReportAutomationConfig()
    {
        Enabled       = true;
        ScheduledTime = "19:00";
        SubjectTitle  = "Automated ENNX Report - {Site} - {Date}";
        Recipients    = new List<string>();
        ExcelFields   = new List<string> { "Name", "Description", "EIL", "Locationname", "Station_Number", "Tag_Date", "Last_Modified_By" };
        IdPrefix      = "ID";
    }
}
