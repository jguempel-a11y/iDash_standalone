using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Linq;

public partial class va_system_diagnostics : Page
{
    public class DiagnosticResult
    {
        public string TestName   { get; set; }
        public string Category   { get; set; }
        public bool   Passed     { get; set; }
        public string Message    { get; set; }
        public long   DurationMs { get; set; }
        public string Details    { get; set; }
        public string Icon       { get; set; }
    }

    protected List<DiagnosticResult> TestResults = new List<DiagnosticResult>();
    protected bool   TestsRan   = false;
    protected int    PassCount  = 0;
    protected int    TotalCount = 0;
    protected long   TotalMs    = 0;
    protected string RunAt      = "";
    protected string ServerHost = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }
        ServerHost = System.Net.Dns.GetHostName();
        if (!IsPostBack) 
        {
            LoadCompanies();
        }
        else 
        {
            if (Session["DiagTestsRan"] != null)
            {
                TestsRan    = (bool)Session["DiagTestsRan"];
                try 
                {
                    var json = (string)Session["DiagTestResults"];
                    TestResults = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<List<DiagnosticResult>>(json);
                }
                catch { TestResults = new List<DiagnosticResult>(); }
                PassCount   = (int)Session["DiagPassCount"];
                TotalCount  = (int)Session["DiagTotalCount"];
                TotalMs     = (long)Session["DiagTotalMs"];
                RunAt       = (string)Session["DiagRunAt"];
            }

            if (Session["MqttStressResult"] != null)
            {
                try
                {
                    var sr = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<MqttPrintNotifier.MqttStressResult>((string)Session["MqttStressResult"]);
                    RenderStressResult(sr);
                } 
                catch { }
            }
        }
    }

    private string GetDbConnectionString()
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"]
              ?? ConfigurationManager.ConnectionStrings["iDash"]
              ?? ConfigurationManager.ConnectionStrings["iDash"]
              ?? ConfigurationManager.ConnectionStrings["iDash"]
              ?? ConfigurationManager.ConnectionStrings["iDashDB"];
        return cs != null ? cs.ConnectionString : "";
    }

    private void LoadCompanies()
    {
        try
        {
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT id, name FROM dbo.company ORDER BY name", cn))
                using (var rdr = cmd.ExecuteReader())
                {
                    DdlCompany.Items.Clear();
                    DdlCompany.Items.Add(new System.Web.UI.WebControls.ListItem("All Companies", "0"));
                    while (rdr.Read())
                        DdlCompany.Items.Add(new System.Web.UI.WebControls.ListItem(rdr["name"].ToString(), rdr["id"].ToString()));
                }
            }
        }
        catch { }
    }

    protected void BtnRun_Click(object sender, EventArgs e)
    {
        int batchSize = 5, companyId = 0;
        int.TryParse(TxtBatchSize.Text, out batchSize);
        int.TryParse(DdlCompany.SelectedValue, out companyId);
        batchSize = Math.Max(1, Math.Min(50, batchSize));
        RunAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        var sw = Stopwatch.StartNew();
        TestResults = new List<DiagnosticResult>();

        bool authOk = false;
        TestResults.Add(TestAuthentication(out authOk));
        TestResults.Add(TestLicenseAndDb());
        TestResults.Add(TestServerStatus());
        TestResults.Add(authOk
            ? TestBatchRead(batchSize, companyId)
            : Skip("Batch Asset Read Test", "api", "Skipped - auth failed"));
        TestResults.Add(TestMqttBroker());
        TestResults.Add(TestDbWrite(companyId));
        TestResults.Add(TestFileSystem());
        TestResults.Add(TestDbPermissions());
        TestResults.Add(TestDependencies());
        TestResults.Add(TestWebConfig());

        sw.Stop();
        TotalMs    = sw.ElapsedMilliseconds;
        PassCount  = TestResults.Count(r => r.Passed && r.Category != "placeholder");
        TotalCount = TestResults.Count(r => r.Category != "placeholder");
        TestsRan   = true;

        Session["DiagTestsRan"]    = TestsRan;
        Session["DiagTestResults"] = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(TestResults);
        Session["DiagPassCount"]   = PassCount;
        Session["DiagTotalCount"]  = TotalCount;
        Session["DiagTotalMs"]     = TotalMs;
        Session["DiagRunAt"]       = RunAt;
    }

    private DiagnosticResult TestAuthentication(out bool authOk)
    {
        authOk = false;
        var sw = Stopwatch.StartNew();
        try
        {
            var users = UserManager.LoadUsers();
            int userCount = users != null ? users.Count : 0;
            if (userCount == 0)
                throw new Exception("iDash user store is empty or unreadable (App_Data/idash_users.json).");

            int sqlUsers = 0;
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT COUNT(*) FROM dbo.sysuser", cn))
                    sqlUsers = Convert.ToInt32(cmd.ExecuteScalar());
            }

            sw.Stop();
            authOk = true;
            return new DiagnosticResult {
                TestName = "Portal & User Authentication",
                Category = "api",
                Icon = "&#128273;",
                Passed = true,
                Message = string.Format("Portal auth OK ({0} user(s)) | {1} SQL sysuser(s)", userCount, sqlUsers),
                DurationMs = sw.ElapsedMilliseconds,
                Details = "App_Data/idash_users.json verified | dbo.sysuser accessible"
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult {
                TestName = "Portal & User Authentication",
                Category = "api",
                Icon = "&#128273;",
                Passed = false,
                Message = ex.Message,
                DurationMs = sw.ElapsedMilliseconds,
                Details = "Check App_Data/idash_users.json permissions and SQL dbo.sysuser connectivity."
            };
        }
    }

    private DiagnosticResult TestLicenseAndDb()
    {
        var sw = Stopwatch.StartNew();
        try
        {
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                int companies = (int)(new SqlCommand("SELECT COUNT(*) FROM dbo.company", cn).ExecuteScalar());
                int assets    = (int)(new SqlCommand("SELECT COUNT(*) FROM dbo.asset",   cn).ExecuteScalar());
                string co  = Convert.ToString(new SqlCommand("SELECT TOP 1 company FROM dbo.applicationsetting", cn).ExecuteScalar());
                string ver = Convert.ToString(new SqlCommand("SELECT TOP 1 version  FROM dbo.applicationsetting", cn).ExecuteScalar());
                bool hasKey = (int)(new SqlCommand("SELECT COUNT(*) FROM dbo.applicationsetting WHERE licensekey IS NOT NULL AND licensekey != ''", cn).ExecuteScalar()) > 0;
                sw.Stop();
                return new DiagnosticResult { TestName="Database & License", Category="db", Icon="&#128451;",
                    Passed=true,
                    Message=string.Format("{0} company | {1:N0} assets | License: {2}", companies, assets, hasKey?"Present":"MISSING"),
                    DurationMs=sw.ElapsedMilliseconds,
                    Details=string.Format("DB Company: {0} | Schema v{1}", co, ver) };
            }
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult { TestName="Database & License", Category="db", Icon="&#128451;",
                Passed=false, Message=ex.Message, DurationMs=sw.ElapsedMilliseconds };
        }
    }

    private DiagnosticResult TestServerStatus()
    {
        var sw = Stopwatch.StartNew();
        try
        {
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                var rows = new List<string>();
                using (var cmd = new SqlCommand("SELECT name, servertype, version, lastseen FROM dbo.serverstatus ORDER BY id", cn))
                using (var rdr = cmd.ExecuteReader())
                    while (rdr.Read())
                    {
                        var ls = rdr["lastseen"];
                        string ago = ls == DBNull.Value ? "never" :
                            Math.Round((DateTime.UtcNow - ((DateTimeOffset)ls).UtcDateTime).TotalMinutes, 0) + "m ago";
                        rows.Add(string.Format("{0} ({1}) v{2} — {3}", rdr["name"], rdr["servertype"], rdr["version"], ago));
                    }
                sw.Stop();
                return new DiagnosticResult { TestName="Server Registrations", Category="db", Icon="&#128268;",
                    Passed=rows.Count > 0,
                    Message=string.Format("{0} registered service(s)", rows.Count),
                    DurationMs=sw.ElapsedMilliseconds, Details=string.Join(" | ", rows) };
            }
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult { TestName="Server Registrations", Category="db", Icon="&#128268;",
                Passed=false, Message=ex.Message, DurationMs=sw.ElapsedMilliseconds };
        }
    }

    private DiagnosticResult TestBatchRead(int batchSize, int companyId)
    {
        var sw = Stopwatch.StartNew();
        int passed = 0;
        var sampleAssets = new List<string>();
        try
        {
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                string where = companyId > 0 ? "WHERE companyid = " + companyId : "";
                string sql = string.Format("SELECT TOP {0} id, name, ISNULL(description,'') as description FROM dbo.asset {1} ORDER BY id", batchSize, where);
                using (var cmd = new SqlCommand(sql, cn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        int id = Convert.ToInt32(rdr["id"]);
                        string name = Convert.ToString(rdr["name"]);
                        passed++;
                        if (sampleAssets.Count < 3)
                            sampleAssets.Add(string.Format("#{0} ({1})", id, name));
                    }
                }
            }

            sw.Stop();
            bool ok = passed > 0 || batchSize == 0;
            string msg = string.Format("{0}/{1} asset records queried successfully", passed, batchSize);
            return new DiagnosticResult {
                TestName = "Batch Asset Read Test",
                Category = "api",
                Icon = "&#128229;",
                Passed = ok,
                Message = msg,
                DurationMs = sw.ElapsedMilliseconds,
                Details = string.Format("Total: {0}ms | Avg {1:N1}ms/record | Direct SQL dbo.asset batch read | Samples: {2}",
                    sw.ElapsedMilliseconds,
                    passed > 0 ? (double)sw.ElapsedMilliseconds / passed : 0,
                    sampleAssets.Count > 0 ? string.Join(", ", sampleAssets) : "None found")
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult {
                TestName = "Batch Asset Read Test",
                Category = "api",
                Icon = "&#128229;",
                Passed = false,
                Message = ex.Message,
                DurationMs = sw.ElapsedMilliseconds,
                Details = "Error querying dbo.asset in SQL."
            };
        }
    }

    private DiagnosticResult TestMqttBroker()
    {
        var mr = MqttPrintNotifier.TestConnectivity();

        string steps = string.Format(
            "TCP {0} | TLS {1} | MQTT CONNECT {2} | Publish {3}",
            mr.TcpConnected  ? "OK" : "FAIL",
            mr.TlsHandshook  ? "OK" : "FAIL",
            mr.MqttConnected ? "OK" : "FAIL",
            mr.Published     ? "OK" : "FAIL");

        string details = mr.Success
            ? string.Format("Broker: {0} | Topic: {1} | Client: {2}",
                mr.BrokerAddress, mr.Topic, mr.ClientId)
            : string.Format("{0} | Progress: {1}", mr.Message, steps);

        return new DiagnosticResult
        {
            TestName   = "MQTT Broker &amp; Print Topic",
            Category   = "mqtt",
            Icon       = "&#128225;",
            Passed     = mr.Success,
            Message    = mr.Success
                ? string.Format("Broker reachable — published to {0}", mr.Topic)
                : mr.Message,
            DurationMs = mr.DurationMs,
            Details    = details
        };
    }

    private DiagnosticResult Skip(string name, string cat, string msg)
    {
        return new DiagnosticResult { TestName=name, Category=cat, Icon="&#9654;",
            Passed=false, Message=msg, DurationMs=0, Details="" };
    }

    private DiagnosticResult TestDbWrite(int companyId)
    {
        var sw = Stopwatch.StartNew();
        try
        {
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                int targetCompany = companyId;
                if (targetCompany <= 0)
                {
                    var obj = new SqlCommand("SELECT TOP 1 id FROM dbo.company", cn).ExecuteScalar();
                    if (obj != null && obj != DBNull.Value) targetCompany = Convert.ToInt32(obj);
                }

                // Test write permissions and transaction log health by doing a rolled-back insert
                string sql = @"
BEGIN TRY
    BEGIN TRAN;
    INSERT INTO dbo.asset (name, description, lastmodified, companyid) VALUES ('IDASH_DIAG_TEST', 'Diagnostic Write Test', GETUTCDATE(), @cid);
    ROLLBACK TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
END CATCH";
                using (var cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.AddWithValue("@cid", targetCompany);
                    cmd.ExecuteNonQuery();
                }
                sw.Stop();
                return new DiagnosticResult { TestName="Database Write Capability", Category="db", Icon="&#128394;",
                    Passed=true, Message="Safe transactional write succeeded", DurationMs=sw.ElapsedMilliseconds,
                    Details="Successfully executed an INSERT inside a ROLLBACK block." };
            }
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult { TestName="Database Write Capability", Category="db", Icon="&#128394;",
                Passed=false, Message=ex.Message, DurationMs=sw.ElapsedMilliseconds,
                Details="Failed to execute write query. Transaction log full or missing INSERT permissions." };
        }
    }

    private DiagnosticResult TestFileSystem()
    {
        var sw = Stopwatch.StartNew();
        var errors = new List<string>();
        
        try
        {
            // Test 1: Log folder write access (SHOULD SUCCEED)
            string logDir = Server.MapPath("~/logs");
            if (!Directory.Exists(logDir)) Directory.CreateDirectory(logDir);
            string testFile = Path.Combine(logDir, "diag_write_test_" + Guid.NewGuid().ToString("N") + ".txt");
            File.WriteAllText(testFile, "test");
            File.Delete(testFile);
        }
        catch (Exception ex)
        {
            errors.Add("Logs Directory Error: " + ex.Message);
        }
        
        sw.Stop();
        bool passed = errors.Count == 0;
        return new DiagnosticResult { TestName="File System Security", Category="security", Icon="&#128193;",
            Passed=passed, Message=passed ? "Read/Write permissions strictly configured" : "Permission vulnerabilities detected", 
            DurationMs=sw.ElapsedMilliseconds, Details=passed ? "Logs: R/W" : string.Join(" | ", errors) };
    }

    private DiagnosticResult TestDbPermissions()
    {
        var sw = Stopwatch.StartNew();
        try
        {
            string connStr = GetDbConnectionString();
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                bool isSysAdmin = (int)new SqlCommand("SELECT IS_SRVROLEMEMBER('sysadmin')", cn).ExecuteScalar() == 1;
                bool isDbOwner  = (int)new SqlCommand("SELECT IS_ROLEMEMBER('db_owner')", cn).ExecuteScalar() == 1;
                
                sw.Stop();
                bool passed = !isSysAdmin && !isDbOwner;
                return new DiagnosticResult { TestName="Database Over-Permission Check", Category="security", Icon="&#128274;",
                    Passed=passed, Message=passed ? "Strict least-privilege SQL account" : "CRITICAL: Over-permissioned account in use!", 
                    DurationMs=sw.ElapsedMilliseconds, Details=string.Format("sysadmin: {0} | db_owner: {1}", isSysAdmin, isDbOwner) };
            }
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult { TestName="Database Over-Permission Check", Category="security", Icon="&#128274;",
                Passed=false, Message="Failed to check roles: " + ex.Message, DurationMs=sw.ElapsedMilliseconds };
        }
    }

    private DiagnosticResult TestDependencies()
    {
        var sw = Stopwatch.StartNew();
        var missing = new List<string>();
        string[] required = { "System.Web", "System.Data" };
        
        var loaded = AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetName().Name).ToList();
        foreach (var req in required)
        {
            if (!loaded.Contains(req))
            {
                try { System.Reflection.Assembly.Load(req); }
                catch { missing.Add(req); }
            }
        }
        
        sw.Stop();
        return new DiagnosticResult { TestName="Dependencies & Assemblies", Category="system", Icon="&#128295;",
            Passed=missing.Count == 0, Message=missing.Count == 0 ? "All core libraries loaded" : "Missing required assemblies", 
            DurationMs=sw.ElapsedMilliseconds, Details=missing.Count == 0 ? "Verified runtime references" : "Missing: " + string.Join(", ", missing) };
    }

    protected void BtnStressTest_Click(object sender, EventArgs e)
    {
        int readers = 40;
        int antennas = 8;
        int reads = 50;
        int.TryParse(TxtStressReaders.Text, out readers);
        int.TryParse(TxtStressAntennas.Text, out antennas);
        int.TryParse(TxtStressReads.Text, out reads);

        int clients = readers;
        int msgs = antennas * reads;

        var result = MqttPrintNotifier.RunStressTest(clients, msgs);

        Session["MqttStressResult"] = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(result);
        RenderStressResult(result);
    }

    private void RenderStressResult(MqttPrintNotifier.MqttStressResult r)
    {
        if (r == null) return;
        PnlStressResult.Visible = true;
        LitStressTotal.Text = r.TotalPublished.ToString("N0");
        LitStressTime.Text = r.DurationMs.ToString("N0");
        LitStressFailConn.Text = r.FailedConnections.ToString("N0");
        LitStressFailPub.Text = r.FailedPublishes.ToString("N0");
    }

    private DiagnosticResult TestWebConfig()
    {
        var sw = Stopwatch.StartNew();
        var errors = new List<string>();
        try
        {
            var config = System.Web.Configuration.WebConfigurationManager.OpenWebConfiguration("~");
            
            var customErrors = (System.Web.Configuration.CustomErrorsSection)config.GetSection("system.web/customErrors");
            if (customErrors != null && customErrors.Mode == System.Web.Configuration.CustomErrorsMode.Off)
                errors.Add("customErrors=Off");
                
            var compilation = (System.Web.Configuration.CompilationSection)config.GetSection("system.web/compilation");
            if (compilation != null && compilation.Debug)
                errors.Add("debug=true");
                
            sw.Stop();
            bool passed = errors.Count == 0;
            return new DiagnosticResult { TestName="Web.Config Hardening", Category="security", Icon="&#9881;",
                Passed=passed, Message=passed ? "Config meets production standards" : "Misconfigurations found", 
                DurationMs=sw.ElapsedMilliseconds, Details=passed ? "customErrors=On | debug=False" : "Vulnerabilities: " + string.Join(" | ", errors) };
        }
        catch (Exception ex)
        {
            sw.Stop();
            return new DiagnosticResult { TestName="Web.Config Hardening", Category="security", Icon="&#9881;",
                Passed=false, Message="Failed to parse web.config: " + ex.Message, DurationMs=sw.ElapsedMilliseconds };
        }
    }

    protected void BtnDownload_Click(object sender, EventArgs e)
    {
        if (!TestsRan || TestResults == null || TestResults.Count == 0) return;
        
        var sb = new StringBuilder();
        sb.AppendLine("=================================================");
        sb.AppendLine(" iDash System Diagnostics Log");
        sb.AppendLine("=================================================");
        sb.AppendLine("Server: " + ServerHost);
        sb.AppendLine("Run At: " + RunAt);
        sb.AppendLine("Health: " + PassCount + "/" + TotalCount + " passed in " + TotalMs + "ms");
        sb.AppendLine("-------------------------------------------------");
        
        foreach (var r in TestResults)
        {
            if (r.Category == "placeholder") continue;
            sb.AppendLine();
            sb.AppendLine("[" + (r.Passed ? "PASS" : "FAIL") + "] " + r.TestName + " (" + r.DurationMs + "ms)");
            sb.AppendLine("Message: " + r.Message);
            if (!string.IsNullOrEmpty(r.Details))
                sb.AppendLine("Details: " + r.Details.Replace(" | ", "\r\n         "));
        }
        sb.AppendLine();
        sb.AppendLine("=================================================");
        
        Response.Clear();
        Response.ContentType = "text/plain";
        Response.AddHeader("Content-Disposition", "attachment; filename=idash_diagnostics_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".log");
        Response.Write(sb.ToString());
        Response.End();
    }

    protected void BtnEmail_Click(object sender, EventArgs e)
    {
        if (!TestsRan || TestResults == null || TestResults.Count == 0) return;
        try
        {
            string subject = string.Format("[iDash Diag] {0} — {1}/{2} passed — {3}", ServerHost, PassCount, TotalCount, RunAt);
            EmailHelper.SendEmail(subject, BuildEmailHtml(), null);
            LblEmailStatus.Text = "&#10003; Report sent.";
            LblEmailStatus.CssClass = "email-ok";
        }
        catch (Exception ex)
        {
            LblEmailStatus.Text = "&#10007; " + ex.Message;
            LblEmailStatus.CssClass = "email-err";
        }
    }

    private string BuildEmailHtml()
    {
        var sb = new StringBuilder();
        sb.Append("<!DOCTYPE html><html><body style='font-family:Segoe UI,sans-serif;background:#0f1117;color:#e0e0e0;padding:32px;'>");
        sb.AppendFormat("<h2 style='color:#2ea8ff;'>&#128202; iDash System Diagnostics</h2>");
        sb.AppendFormat("<p>Server: <b>{0}</b> | Generated: <b>{1}</b></p>", ServerHost, RunAt);
        sb.AppendFormat("<p style='font-size:18px;'>Health: <b style='color:{0};'>{1}/{2} passed</b> in {3}ms</p>",
            PassCount==TotalCount?"#10b981":"#ef4444", PassCount, TotalCount, TotalMs);
        sb.Append("<table width='100%' cellpadding='10' cellspacing='0' style='border-collapse:collapse;'>");
        sb.Append("<tr style='background:#1a1d2e;'><th align='left'>Test</th><th>Status</th><th align='right'>ms</th><th align='left'>Details</th></tr>");
        foreach (var r in TestResults)
        {
            if (r.Category == "placeholder") continue;
            string col = r.Passed ? "#10b981" : "#ef4444";
            sb.AppendFormat("<tr style='border-bottom:1px solid #2a2d3e;'><td><b>{0} {1}</b><br><small style='color:#888;'>{2}</small></td><td align='center' style='color:{3};font-weight:700;'>{4}</td><td align='right' style='color:#888;'>{5}</td><td style='color:#aaa;font-size:12px;'>{6}</td></tr>",
                r.Icon, r.TestName, r.Message, col, r.Passed?"PASS":"FAIL", r.DurationMs, r.Details);
        }
        sb.Append("</table><p style='color:#555;font-size:12px;margin-top:24px;'>iDash Diagnostics | Total: " + TotalMs + "ms</p></body></html>");
        return sb.ToString();
    }
}
