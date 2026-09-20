using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;

public partial class va_print_admin : System.Web.UI.Page
{
    private static string ConnStr
    {
        get { return ConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Admin or admin_print tile access
        string role = Convert.ToString(Session["IdashUserRole"]);
        var tiles = Session["IdashTileAccess"] as List<string>;
        bool hasAccess = role == "admin" 
            || (tiles != null && (tiles.Contains("admin_print") || tiles.Contains("*")));
        if (!hasAccess)
        {
            Response.Redirect("index.aspx");
            return;
        }

        if (Request.QueryString["action"] == "api")
        {
            HandleApiRequest();
            return;
        }
    }

    // ===================================================================
    // AJAX API handler
    // ===================================================================
    private void HandleApiRequest()
    {
        Response.ContentType = "application/json";
        var js = new JavaScriptSerializer();
        string cmd = Request.QueryString["cmd"] ?? "";

        try
        {
            string result = "";
            switch (cmd)
            {
                case "getOverview": result = GetSiteOverview(); break;
                case "getTemplates": result = GetTemplates(); break;
                case "saveTemplate": result = SaveTemplate(); break;
                case "deleteTemplate": result = DeleteTemplate(); break;
                case "getPrintClients": result = GetPrintClients(); break;
                case "savePrintClient": result = SavePrintClient(); break;
                case "deletePrintClient": result = DeletePrintClient(); break;
                case "getStatus": result = GetPrintServerStatus(); break;
                case "getRecentJobs": result = GetRecentJobs(); break;
                case "searchAssets": result = SearchAssets(); break;
                case "testPrint": result = TestPrint(); break;
                case "quickSetup": result = QuickSetupSite(); break;
                case "getConfigStatus": result = GetConfigStatus(); break;
                case "fixConfig": result = FixConfig(); break;
                case "clearJobs": result = ClearPrintJobs(); break;
                case "getWizardDefaults": result = GetWizardDefaults(); break;
                case "runWizard": result = RunSetupWizard(); break;
                case "restartIIS": result = RestartIIS(); break;
                default: result = js.Serialize(new { error = "Unknown command: " + cmd }); break;
            }
            Response.Write(result);
        }
        catch (Exception ex)
        {
            Response.Write(js.Serialize(new { error = ex.Message }));
        }

        Response.Flush();
        Response.SuppressContent = true;
        HttpContext.Current.ApplicationInstance.CompleteRequest();
    }

    // ===================================================================
    // Tab 3: Site Overview Dashboard
    // ===================================================================
    private string GetSiteOverview()
    {
        var js = new JavaScriptSerializer();
        var sites = new List<Dictionary<string, object>>();

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(@"
                SELECT c.id, c.name,
                       t.id as templateId, t.name as templateName, t.filename as btwFile,
                       p.username as printerUsername, p.name as printerName,
                       ca.clientid as apiClientId,
                       p.lastseen as printerLastSeen
                FROM company c
                LEFT JOIN template t ON t.companyid = c.id AND t.printclientid > 0
                LEFT JOIN printclient p ON t.printclientid = p.id
                LEFT JOIN clientapp ca ON ca.companyid = c.id AND ca.clientid LIKE 'idash_%'
                ORDER BY c.name", cn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                {
                    string btwFile = r["btwFile"] == DBNull.Value ? "" : r["btwFile"].ToString();
                    bool fileExists = !string.IsNullOrEmpty(btwFile) && File.Exists(btwFile);

                    sites.Add(new Dictionary<string, object> {
                        { "companyId", r["id"] },
                        { "siteName", r["name"] },
                        { "templateId", r["templateId"] == DBNull.Value ? null : r["templateId"] },
                        { "templateName", r["templateName"] == DBNull.Value ? "" : r["templateName"] },
                        { "btwFile", btwFile },
                        { "btwFileExists", fileExists },
                        { "printerUsername", r["printerUsername"] == DBNull.Value ? "" : r["printerUsername"] },
                        { "printerName", r["printerName"] == DBNull.Value ? "" : r["printerName"] },
                        { "apiClientId", r["apiClientId"] == DBNull.Value ? "" : r["apiClientId"] },
                        { "printerLastSeen", r["printerLastSeen"] == DBNull.Value ? "" : 
                            ((DateTimeOffset)r["printerLastSeen"]).ToString("MMM d, h:mm tt") }
                    });
                }
            }
        }
        return js.Serialize(new { sites = sites });
    }

    // ===================================================================
    // Tab 1: Templates CRUD
    // ===================================================================
    private string GetTemplates()
    {
        var js = new JavaScriptSerializer();
        var templates = new List<Dictionary<string, object>>();
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(@"
                SELECT t.id, t.name, t.templatetype, t.filename, t.printmethod,
                       t.companyid, c.name as siteName, t.printclientid,
                       ISNULL(p.username, '') as printerUsername, t.usewithservice
                FROM template t
                LEFT JOIN company c ON t.companyid = c.id
                LEFT JOIN printclient p ON t.printclientid = p.id
                ORDER BY c.name, t.name", cn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                {
                    string fn = r["filename"] == DBNull.Value ? "" : r["filename"].ToString();
                    templates.Add(new Dictionary<string, object> {
                        { "id", r["id"] },
                        { "name", r["name"] },
                        { "templateType", r["templatetype"] == DBNull.Value ? "Asset" : r["templatetype"] },
                        { "filename", fn },
                        { "fileExists", !string.IsNullOrEmpty(fn) && File.Exists(fn) },
                        { "printMethod", r["printmethod"] == DBNull.Value ? "Bartender" : r["printmethod"] },
                        { "companyId", r["companyid"] },
                        { "siteName", r["siteName"] == DBNull.Value ? "" : r["siteName"] },
                        { "printClientId", r["printclientid"] == DBNull.Value ? 0 : r["printclientid"] },
                        { "printerUsername", r["printerUsername"] },
                        { "useWithService", r["usewithservice"] == DBNull.Value ? "" : r["usewithservice"] }
                    });
                }
            }
        }
        // Also get dropdowns data
        var companies = GetCompanyList();
        var printers = GetPrinterList();
        return js.Serialize(new { templates = templates, companies = companies, printers = printers });
    }

    private string SaveTemplate()
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);

        int id = Convert.ToInt32(data.ContainsKey("id") ? data["id"] : 0);
        string name = (data["name"] ?? "").ToString();
        string templateType = (data.ContainsKey("templateType") ? data["templateType"] : "Asset").ToString();
        string filename = (data["filename"] ?? "").ToString();
        string printMethod = (data.ContainsKey("printMethod") ? data["printMethod"] : "Bartender").ToString();
        int companyId = Convert.ToInt32(data["companyId"]);
        int printClientId = Convert.ToInt32(data["printClientId"]);

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            if (id > 0)
            {
                using (var cmd = new SqlCommand(@"UPDATE template SET 
                    name=@name, templatetype=@type, filename=@fn, printmethod=@pm,
                    companyid=@cid, printclientid=@pcid WHERE id=@id", cn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    cmd.Parameters.AddWithValue("@type", templateType);
                    cmd.Parameters.AddWithValue("@fn", filename);
                    cmd.Parameters.AddWithValue("@pm", printMethod);
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    cmd.Parameters.AddWithValue("@pcid", printClientId);
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
            else
            {
                using (var cmd = new SqlCommand(@"INSERT INTO template 
                    (name, templatetype, filename, printmethod, companyid, printclientid)
                    VALUES (@name, @type, @fn, @pm, @cid, @pcid);
                    
                    -- Auto-create idash client app if not exists
                    IF NOT EXISTS (SELECT 1 FROM clientapp WHERE companyid = @cid AND clientid LIKE 'idash_%')
                    BEGIN
                        DECLARE @siteName VARCHAR(50) = (SELECT name FROM company WHERE id = @cid);
                        DECLARE @clientId VARCHAR(50) = 'idash_' + REPLACE(@siteName, ' ', '_');
                        INSERT INTO clientapp (clientid, granttype, secret, companyid)
                        VALUES (@clientId, 'Client Credentials', 
                            'I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H', @cid);
                    END

                    -- Auto-create printclientcompany mapping if not exists
                    IF NOT EXISTS (SELECT 1 FROM printclientcompany WHERE printclientid = @pcid AND companyid = @cid)
                    BEGIN
                        INSERT INTO printclientcompany (printclientid, companyid) VALUES (@pcid, @cid);
                    END", cn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    cmd.Parameters.AddWithValue("@type", templateType);
                    cmd.Parameters.AddWithValue("@fn", filename);
                    cmd.Parameters.AddWithValue("@pm", printMethod);
                    cmd.Parameters.AddWithValue("@cid", companyId);
                    cmd.Parameters.AddWithValue("@pcid", printClientId);
                    cmd.ExecuteNonQuery();
                }
            }
        }
        return js.Serialize(new { success = true });
    }

    private string DeleteTemplate()
    {
        int id = int.Parse(Request.QueryString["id"] ?? "0");
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand("DELETE FROM template WHERE id=@id", cn))
            {
                cmd.Parameters.AddWithValue("@id", id);
                cmd.ExecuteNonQuery();
            }
        }
        return new JavaScriptSerializer().Serialize(new { success = true });
    }

    // ===================================================================
    // Tab 2: Print Clients CRUD
    // ===================================================================
    private string GetPrintClients()
    {
        var js = new JavaScriptSerializer();
        var clients = new List<Dictionary<string, object>>();
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(@"
                SELECT p.id, p.name, p.username, p.password, p.machinename, p.lastseen,
                    (SELECT STRING_AGG(c.name, ', ') FROM printclientcompany pcc 
                     JOIN company c ON pcc.companyid = c.id 
                     WHERE pcc.printclientid = p.id) as assignedSites
                FROM printclient p
                ORDER BY p.name", cn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                {
                    clients.Add(new Dictionary<string, object> {
                        { "id", r["id"] },
                        { "name", r["name"] == DBNull.Value ? "" : r["name"] },
                        { "username", r["username"] == DBNull.Value ? "" : r["username"] },
                        { "password", r["password"] == DBNull.Value ? "" : r["password"] },
                        { "machineName", r["machinename"] == DBNull.Value ? "" : r["machinename"] },
                        { "lastSeen", r["lastseen"] == DBNull.Value ? "" : 
                            ((DateTimeOffset)r["lastseen"]).ToString("MMM d, h:mm tt") },
                        { "assignedSites", r["assignedSites"] == DBNull.Value ? "" : r["assignedSites"] }
                    });
                }
            }
        }
        var companies = GetCompanyList();
        return js.Serialize(new { clients = clients, companies = companies });
    }

    private string SavePrintClient()
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);

        int id = Convert.ToInt32(data.ContainsKey("id") ? data["id"] : 0);
        string name = (data["name"] ?? "").ToString();
        string username = (data["username"] ?? "").ToString();
        string password = (data["password"] ?? "").ToString();
        string machineName = (data.ContainsKey("machineName") ? data["machineName"] : "").ToString();

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            if (id > 0)
            {
                using (var cmd = new SqlCommand(@"UPDATE printclient SET 
                    name=@name, username=@user, password=@pass, machinename=@machine WHERE id=@id", cn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    cmd.Parameters.AddWithValue("@user", username);
                    cmd.Parameters.AddWithValue("@pass", password);
                    cmd.Parameters.AddWithValue("@machine", machineName);
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
            else
            {
                using (var cmd = new SqlCommand(@"INSERT INTO printclient 
                    (name, username, password, machinename) 
                    OUTPUT INSERTED.id
                    VALUES (@name, @user, @pass, @machine)", cn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    cmd.Parameters.AddWithValue("@user", username);
                    cmd.Parameters.AddWithValue("@pass", password);
                    cmd.Parameters.AddWithValue("@machine", machineName);
                    id = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }

            // Update site assignments
            if (data.ContainsKey("siteIds"))
            {
                var siteIds = ((System.Collections.ArrayList)data["siteIds"]).Cast<object>()
                    .Select(x => Convert.ToInt32(x)).ToList();
                
                int pcId = id;

                using (var del = new SqlCommand("DELETE FROM printclientcompany WHERE printclientid=@id", cn))
                {
                    del.Parameters.AddWithValue("@id", pcId);
                    del.ExecuteNonQuery();
                }
                foreach (int sid in siteIds)
                {
                    using (var ins = new SqlCommand("INSERT INTO printclientcompany (printclientid, companyid) VALUES (@pid, @cid)", cn))
                    {
                        ins.Parameters.AddWithValue("@pid", pcId);
                        ins.Parameters.AddWithValue("@cid", sid);
                        ins.ExecuteNonQuery();
                    }
                }
            }
        }
        return js.Serialize(new { success = true });
    }

    private string DeletePrintClient()
    {
        int id = int.Parse(Request.QueryString["id"] ?? "0");
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            new SqlCommand("DELETE FROM printclientcompany WHERE printclientid=" + id, cn).ExecuteNonQuery();
            new SqlCommand("DELETE FROM printclient WHERE id=" + id, cn).ExecuteNonQuery();
        }
        return new JavaScriptSerializer().Serialize(new { success = true });
    }

    // ===================================================================
    // Tab 4: Status & Monitoring
    // ===================================================================
    private string GetPrintServerStatus()
    {
        var js = new JavaScriptSerializer();
        var status = new Dictionary<string, object>();

        // Print Server process
        try
        {
            var procs = Process.GetProcessesByName("iDash.PrintService");
            if (procs.Length > 0)
            {
                var p = procs[0];
                status["processRunning"] = true;
                status["pid"] = p.Id;
                status["memory"] = (p.WorkingSet64 / 1024 / 1024) + " MB";
            }
            else
            {
                status["processRunning"] = false;
            }
        }
        catch { status["processRunning"] = false; }

        // MQTT connections
        status["mqttConnected"] = false;
        try
        {
            var psi = new ProcessStartInfo("netstat", "-ano") { RedirectStandardOutput = true, UseShellExecute = false };
            var proc = Process.Start(psi);
            string output = proc.StandardOutput.ReadToEnd();
            proc.WaitForExit(5000);
            int mqttConns = output.Split('\n').Count(l => l.Contains(":8883") && l.Contains("ESTABLISHED"));
            status["mqttConnections"] = mqttConns;
            status["mqttConnected"] = mqttConns >= 2; // broker + print server
        }
        catch { }

        // Print server log tail  -  use FileShare.ReadWrite to handle locked files
        try
        {
            string[] logDirs = new[] { @"C:\Logs", @"c:\inetpub\wwwroot\iDash\Logs" };
            string logFile = null;
            foreach (var dir in logDirs)
            {
                if (!Directory.Exists(dir)) continue;
                var found = Directory.GetFiles(dir, "PrintServer_log*.txt")
                    .OrderByDescending(f => File.GetLastWriteTime(f)).FirstOrDefault();
                if (found != null) { logFile = found; break; }
            }
            if (logFile != null)
            {
                status["logFile"] = Path.GetFileName(logFile);
                status["logUpdated"] = File.GetLastWriteTime(logFile).ToString("h:mm:ss tt");
                // Read with FileShare.ReadWrite so we don't fail on locked files
                using (var fs = new FileStream(logFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                using (var sr = new StreamReader(fs))
                {
                    var allLines = new List<string>();
                    string line;
                    while ((line = sr.ReadLine()) != null) allLines.Add(line);
                    int skip = Math.Max(0, allLines.Count - 30);
                    status["logTail"] = string.Join("\n", allLines.Skip(skip));
                }
            }
            else
            {
                status["logTail"] = "No PrintServer log files found in: " + string.Join(", ", logDirs);
                status["logFile"] = " - ";
                status["logUpdated"] = " - ";
            }
        }
        catch (Exception ex)
        {
            status["logTail"] = "Error reading log: " + ex.Message;
        }

        // MQTT config from appsettings (read ConfigSettings section)
        try
        {
            string appSettings = @"c:\inetpub\wwwroot\iDash\appsettings.json";
            if (File.Exists(appSettings))
            {
                string json = File.ReadAllText(appSettings);
                var root = js.Deserialize<Dictionary<string, object>>(json);
                Dictionary<string, object> config = null;
                if (root.ContainsKey("ConfigSettings"))
                    config = root["ConfigSettings"] as Dictionary<string, object>;
                if (config == null) config = root;

                status["mqttServer"] = config.ContainsKey("MqttServer") ? config["MqttServer"] : "localhost";
                status["mqttPort"] = config.ContainsKey("MqttServerPort") ? config["MqttServerPort"] : 8883;
                status["printClientUsername"] = config.ContainsKey("PrintClientUsername") ? config["PrintClientUsername"] : "";
            }
        }
        catch { }

        return js.Serialize(status);
    }

    private string GetRecentJobs()
    {
        var js = new JavaScriptSerializer();
        var jobs = new List<Dictionary<string, object>>();
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(@"
                SELECT TOP 20 j.id, j.recordid, j.templateid, j.completed, j.message,
                       j.usewithservice, j.created, t.name as templateName,
                       c.name as siteName
                FROM printjob j
                LEFT JOIN template t ON j.templateid = t.id
                LEFT JOIN company comp ON t.companyid = comp.id
                OUTER APPLY (SELECT TOP 1 name FROM company WHERE id = t.companyid) c
                ORDER BY j.id DESC", cn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                {
                    jobs.Add(new Dictionary<string, object> {
                        { "id", r["id"] },
                        { "recordId", r["recordid"] },
                        { "templateId", r["templateid"] == DBNull.Value ? 0 : r["templateid"] },
                        { "completed", r["completed"] == DBNull.Value ? false : Convert.ToBoolean(r["completed"]) },
                        { "message", r["message"] == DBNull.Value ? "" : r["message"] },
                        { "templateName", r["templateName"] == DBNull.Value ? "" : r["templateName"] },
                        { "siteName", r["siteName"] == DBNull.Value ? "" : r["siteName"] },
                        { "created", r["created"] == DBNull.Value ? "" : 
                            ((DateTimeOffset)r["created"]).ToString("MMM d h:mm tt") }
                    });
                }
            }
        }
        return js.Serialize(new { jobs = jobs });
    }

    private string ClearPrintJobs()
    {
        var js = new JavaScriptSerializer();
        string mode = Request.QueryString["mode"] ?? "completed"; // "completed" or "all"
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                string sql = mode == "all"
                    ? "DELETE FROM printjob"
                    : "DELETE FROM printjob WHERE completed = 1";
                using (var cmd = new SqlCommand(sql, cn))
                {
                    int deleted = cmd.ExecuteNonQuery();
                    return js.Serialize(new { success = true, deleted = deleted, mode = mode });
                }
            }
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    // ===================================================================
    // Test Print & Quick Setup
    // ===================================================================

    private string SearchAssets()
    {
        var js = new JavaScriptSerializer();
        string q = (Request.QueryString["q"] ?? "").Trim();
        int companyId = 0;
        int.TryParse(Request.QueryString["companyId"] ?? "0", out companyId);

        if (q.Length < 2)
            return js.Serialize(new { assets = new object[0] });

        var results = new List<object>();
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            // Search by name (e.g. "613 EE12889") or partial match
            string sql = @"SELECT TOP 15 a.id, a.name, l.label as location
                           FROM asset a
                           LEFT JOIN location l ON a.locationid = l.id
                           WHERE a.name LIKE @q";
            if (companyId > 0) sql += " AND a.companyid = @cid";
            sql += " ORDER BY a.name";

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@q", "%" + q + "%");
                if (companyId > 0)
                    cmd.Parameters.AddWithValue("@cid", companyId);
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        results.Add(new
                        {
                            id = rdr["id"],
                            name = rdr["name"] != DBNull.Value ? rdr["name"].ToString() : "",
                            location = rdr["location"] != DBNull.Value ? rdr["location"].ToString() : ""
                        });
                    }
                }
            }
        }
        return js.Serialize(new { assets = results });
    }

    private string TestPrint()
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);

        int templateId = Convert.ToInt32(data["templateId"]);
        long recordId = Convert.ToInt64(data["recordId"]);

        try
        {
            // Use direct BarTender printing (no MQTT/Print Server dependency)
            var jobs = new List<Dictionary<string, object>> {
                new Dictionary<string, object> { { "recordID", recordId }, { "templateID", templateId } }
            };
            List<string> errors;
            int count = PrintApiHelper.PrintJobsDirect(jobs, out errors);
            if (count > 0)
                return js.Serialize(new { success = true, message = "Test print sent successfully." });
            else
                return js.Serialize(new { error = "Print failed: " + (errors.Count > 0 ? string.Join("; ", errors.ToArray()) : "Unknown error") });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = "Print failed: " + ex.Message });
        }
    }

    private string QuickSetupSite()
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);

        int companyId = Convert.ToInt32(data["companyId"]);
        string btwFile = (data.ContainsKey("btwFile") ? data["btwFile"] : @"c:\idash_prints\iDash_Std_Small.btw").ToString();
        int printClientId = data.ContainsKey("printClientId") ? Convert.ToInt32(data["printClientId"]) : 0;

        string siteName = "";
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            
            // Get company name for client ID
            using (var cmd = new SqlCommand("SELECT name FROM company WHERE id=@id", cn))
            {
                cmd.Parameters.AddWithValue("@id", companyId);
                var result = cmd.ExecuteScalar();
                siteName = result != null ? result.ToString() : "";
            }

            // If no printClientId provided, find the first available one
            if (printClientId <= 0)
            {
                using (var cmd = new SqlCommand("SELECT TOP 1 id FROM printclient ORDER BY id", cn))
                {
                    var result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        printClientId = Convert.ToInt32(result);
                }
            }

            if (printClientId <= 0)
                return js.Serialize(new { error = "No print clients configured. Please add a Print Client on the Print Clients tab first." });

            // Create template if not exists
            using (var cmd = new SqlCommand(@"
                IF NOT EXISTS (SELECT 1 FROM template WHERE companyid=@cid AND printclientid > 0)
                    INSERT INTO template (name, templatetype, filename, printmethod, companyid, printclientid)
                    VALUES ('iDash_Std_Small', 'Asset', @fn, 'Bartender', @cid, @pcid)", cn))
            {
                cmd.Parameters.AddWithValue("@cid", companyId);
                cmd.Parameters.AddWithValue("@fn", btwFile);
                cmd.Parameters.AddWithValue("@pcid", printClientId);
                cmd.ExecuteNonQuery();
            }

            // Create printclientcompany mapping
            using (var cmd = new SqlCommand(@"
                IF NOT EXISTS (SELECT 1 FROM printclientcompany WHERE printclientid=@pcid AND companyid=@cid)
                    INSERT INTO printclientcompany (printclientid, companyid) VALUES (@pcid, @cid)", cn))
            {
                cmd.Parameters.AddWithValue("@pcid", printClientId);
                cmd.Parameters.AddWithValue("@cid", companyId);
                cmd.ExecuteNonQuery();
            }

            // Create clientapp
            string clientId = "idash_" + siteName.Replace(" ", "_");
            using (var cmd = new SqlCommand(@"
                IF NOT EXISTS (SELECT 1 FROM clientapp WHERE companyid=@cid AND clientid LIKE 'idash_%')
                    INSERT INTO clientapp (clientid, granttype, secret, companyid)
                    VALUES (@clientId, 'Client Credentials', 
                        'I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H', @cid)", cn))
            {
                cmd.Parameters.AddWithValue("@cid", companyId);
                cmd.Parameters.AddWithValue("@clientId", clientId);
                cmd.ExecuteNonQuery();
            }
        }
        return js.Serialize(new { success = true, message = "Site '" + siteName + "' configured for printing." });
    }

    // ===================================================================
    // Config Status & Fix
    // ===================================================================
    private static readonly string WebClientAppSettingsPath = @"c:\inetpub\wwwroot\iDash\appsettings.json";
    private static readonly string PrintServerAppSettingsPath = @"C:\Program Files\ID Integration\iDash Print Service\appsettings.json";

    private Dictionary<string, object> ReadAppSettingsConfig(string path)
    {
        var js = new JavaScriptSerializer();
        var result = new Dictionary<string, object>();
        result["path"] = path;
        result["exists"] = File.Exists(path);
        if (!File.Exists(path)) return result;

        try
        {
            string json = File.ReadAllText(path);
            var root = js.Deserialize<Dictionary<string, object>>(json);
            Dictionary<string, object> cfg = null;
            if (root.ContainsKey("ConfigSettings"))
                cfg = root["ConfigSettings"] as Dictionary<string, object>;
            if (cfg == null) cfg = root; // flat structure fallback

            result["mqttServer"] = cfg.ContainsKey("MqttServer") ? cfg["MqttServer"] : "";
            result["mqttPort"] = cfg.ContainsKey("MqttServerPort") ? cfg["MqttServerPort"] : "";
            result["printClientUsername"] = cfg.ContainsKey("PrintClientUsername") ? cfg["PrintClientUsername"] : "";
            result["printClientPassword"] = cfg.ContainsKey("PrintClientPassword") ? cfg["PrintClientPassword"] : "";
            result["useForPrinting"] = cfg.ContainsKey("UseForPrinting") ? cfg["UseForPrinting"] : false;
            result["readable"] = true;
        }
        catch (Exception ex)
        {
            result["readable"] = false;
            result["error"] = ex.Message;
        }
        return result;
    }

    private string MaskPassword(object pwd)
    {
        if (pwd == null) return "";
        string p = pwd.ToString();
        if (p.Length <= 4) return new string('*', p.Length);
        return p.Substring(0, 2) + new string('*', p.Length - 4) + p.Substring(p.Length - 2);
    }

    private string GetConfigStatus()
    {
        var js = new JavaScriptSerializer();
        var status = new Dictionary<string, object>();

        // 1. WebClient appsettings.json
        var wcConfig = ReadAppSettingsConfig(WebClientAppSettingsPath);
        status["webClient"] = new Dictionary<string, object> {
            { "path", wcConfig["path"] },
            { "exists", wcConfig["exists"] },
            { "readable", wcConfig.ContainsKey("readable") ? wcConfig["readable"] : false },
            { "mqttServer", wcConfig.ContainsKey("mqttServer") ? wcConfig["mqttServer"] : "" },
            { "mqttPort", wcConfig.ContainsKey("mqttPort") ? wcConfig["mqttPort"] : "" },
            { "printClientUsername", wcConfig.ContainsKey("printClientUsername") ? wcConfig["printClientUsername"] : "" },
            { "printClientPasswordMasked", MaskPassword(wcConfig.ContainsKey("printClientPassword") ? wcConfig["printClientPassword"] : "") },
            { "useForPrinting", wcConfig.ContainsKey("useForPrinting") ? wcConfig["useForPrinting"] : false },
            { "error", wcConfig.ContainsKey("error") ? wcConfig["error"] : "" }
        };

        // 2. Print Server appsettings.json
        var psConfig = ReadAppSettingsConfig(PrintServerAppSettingsPath);
        status["printServer"] = new Dictionary<string, object> {
            { "path", psConfig["path"] },
            { "exists", psConfig["exists"] },
            { "readable", psConfig.ContainsKey("readable") ? psConfig["readable"] : false },
            { "mqttServer", psConfig.ContainsKey("mqttServer") ? psConfig["mqttServer"] : "" },
            { "mqttPort", psConfig.ContainsKey("mqttPort") ? psConfig["mqttPort"] : "" },
            { "printClientUsername", psConfig.ContainsKey("printClientUsername") ? psConfig["printClientUsername"] : "" },
            { "printClientPasswordMasked", MaskPassword(psConfig.ContainsKey("printClientPassword") ? psConfig["printClientPassword"] : "") },
            { "useForPrinting", psConfig.ContainsKey("useForPrinting") ? psConfig["useForPrinting"] : false },
            { "error", psConfig.ContainsKey("error") ? psConfig["error"] : "" }
        };

        // 3. DB printclient table
        var dbClients = new List<Dictionary<string, object>>();
        bool mqttClientConflict = false;
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT id, name, username, password FROM printclient ORDER BY id", cn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        dbClients.Add(new Dictionary<string, object> {
                            { "id", r["id"] },
                            { "name", r["name"].ToString().Trim() },
                            { "username", r["username"].ToString().Trim() },
                            { "passwordMasked", MaskPassword(r["password"].ToString().Trim()) },
                            { "passwordRaw", r["password"].ToString().Trim() }
                        });
                    }
                }
                // Check for mqttclient conflict
                foreach (var pc in dbClients)
                {
                    using (var cmd2 = new SqlCommand("SELECT COUNT(*) FROM mqttclient WHERE username=@u", cn))
                    {
                        cmd2.Parameters.AddWithValue("@u", pc["username"]);
                        int cnt = (int)cmd2.ExecuteScalar();
                        if (cnt > 0) mqttClientConflict = true;
                    }
                }
            }
        }
        catch { }
        status["dbClients"] = dbClients;
        status["mqttClientConflict"] = mqttClientConflict;

        // 4. Sync checks
        var issues = new List<string>();
        string wcUser = wcConfig.ContainsKey("printClientUsername") ? wcConfig["printClientUsername"].ToString() : "";
        string wcPass = wcConfig.ContainsKey("printClientPassword") ? wcConfig["printClientPassword"].ToString() : "";
        string psUser = psConfig.ContainsKey("printClientUsername") ? psConfig["printClientUsername"].ToString() : "";
        string psPass = psConfig.ContainsKey("printClientPassword") ? psConfig["printClientPassword"].ToString() : "";
        bool useForPrinting = wcConfig.ContainsKey("useForPrinting") && true.Equals(wcConfig["useForPrinting"]);

        if (!useForPrinting)
            issues.Add("UseForPrinting is FALSE in WebClient appsettings.json  -  printing is disabled.");

        if (dbClients.Count == 0)
            issues.Add("No print clients in database. Add one on the Print Clients tab.");

        foreach (var pc in dbClients)
        {
            string dbUser = pc["username"].ToString();
            string dbPass = pc["passwordRaw"].ToString();
            if (!string.IsNullOrEmpty(wcUser) && wcUser != dbUser)
                issues.Add("WebClient username '" + wcUser + "' doesn't match DB print client '" + dbUser + "'.");
            if (!string.IsNullOrEmpty(wcPass) && wcPass != dbPass)
                issues.Add("WebClient password doesn't match DB print client '" + dbUser + "' password (case-sensitive).");
            if (!string.IsNullOrEmpty(psUser) && psUser != dbUser)
                issues.Add("Print Server username '" + psUser + "' doesn't match DB print client '" + dbUser + "'.");
            if (!string.IsNullOrEmpty(psPass) && psPass != dbPass)
                issues.Add("Print Server password doesn't match DB print client '" + dbUser + "' password (case-sensitive).");
        }

        if (mqttClientConflict)
            issues.Add("CRITICAL: A print client username also exists in the mqttclient table. This causes the MQTT broker to treat it as a generic client instead of a print client, blocking print subscriptions. Remove it from mqttclient.");

        status["issues"] = issues;
        status["allGood"] = issues.Count == 0;

        // Remove raw passwords from output
        foreach (var pc in dbClients)
            pc.Remove("passwordRaw");

        return js.Serialize(status);
    }

    private string FixConfig()
    {
        var js = new JavaScriptSerializer();
        var changes = new List<string>();

        try
        {
            // Read current DB print client creds (source of truth)
            string dbUser = "", dbPass = "";
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT TOP 1 username, password FROM printclient ORDER BY id", cn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        dbUser = r["username"].ToString().Trim();
                        dbPass = r["password"].ToString().Trim();
                    }
                }

                // Fix mqttclient conflict
                if (!string.IsNullOrEmpty(dbUser))
                {
                    using (var cmd2 = new SqlCommand("DELETE FROM mqttclient WHERE username=@u", cn))
                    {
                        cmd2.Parameters.AddWithValue("@u", dbUser);
                        int deleted = cmd2.ExecuteNonQuery();
                        if (deleted > 0)
                            changes.Add("Removed '" + dbUser + "' from mqttclient table (" + deleted + " row" + (deleted > 1 ? "s" : "") + ")  -  was causing subscription rejection.");
                    }
                }
            }

            if (string.IsNullOrEmpty(dbUser))
                return js.Serialize(new { error = "No print clients in database. Add one first." });

            // Fix WebClient appsettings.json
            if (File.Exists(WebClientAppSettingsPath))
            {
                string json = File.ReadAllText(WebClientAppSettingsPath);
                var root = js.Deserialize<Dictionary<string, object>>(json);
                var cfg = root.ContainsKey("ConfigSettings") ? root["ConfigSettings"] as Dictionary<string, object> : root;

                bool changed = false;

                // Fix UseForPrinting
                if (!cfg.ContainsKey("UseForPrinting") || !true.Equals(cfg["UseForPrinting"]))
                {
                    cfg["UseForPrinting"] = true;
                    changed = true;
                    changes.Add("Set UseForPrinting = true in WebClient appsettings.json");
                }

                // Fix credentials
                string currentUser = cfg.ContainsKey("PrintClientUsername") ? cfg["PrintClientUsername"].ToString() : "";
                string currentPass = cfg.ContainsKey("PrintClientPassword") ? cfg["PrintClientPassword"].ToString() : "";

                if (currentUser != dbUser)
                {
                    cfg["PrintClientUsername"] = dbUser;
                    changed = true;
                    changes.Add("Updated PrintClientUsername from '" + currentUser + "' to '" + dbUser + "' in WebClient appsettings.json");
                }
                if (currentPass != dbPass)
                {
                    cfg["PrintClientPassword"] = dbPass;
                    changed = true;
                    changes.Add("Updated PrintClientPassword in WebClient appsettings.json to match DB");
                }

                if (changed)
                {
                    // Write back with indented formatting
                    string output = FormatJson(js.Serialize(root));
                    File.WriteAllText(WebClientAppSettingsPath, output);
                }
            }
            else
            {
                changes.Add("WARNING: WebClient appsettings.json not found at " + WebClientAppSettingsPath);
            }

            // Try to fix Print Server appsettings.json (may fail due to permissions)
            if (File.Exists(PrintServerAppSettingsPath))
            {
                try
                {
                    string json = File.ReadAllText(PrintServerAppSettingsPath);
                    var root = js.Deserialize<Dictionary<string, object>>(json);
                    var cfg = root.ContainsKey("ConfigSettings") ? root["ConfigSettings"] as Dictionary<string, object> : root;

                    bool changed = false;
                    string currentUser = cfg.ContainsKey("PrintClientUsername") ? cfg["PrintClientUsername"].ToString() : "";
                    string currentPass = cfg.ContainsKey("PrintClientPassword") ? cfg["PrintClientPassword"].ToString() : "";

                    if (currentUser != dbUser)
                    {
                        cfg["PrintClientUsername"] = dbUser;
                        changed = true;
                        changes.Add("Updated PrintClientUsername in Print Server appsettings.json");
                    }
                    if (currentPass != dbPass)
                    {
                        cfg["PrintClientPassword"] = dbPass;
                        changed = true;
                        changes.Add("Updated PrintClientPassword in Print Server appsettings.json to match DB");
                    }

                    if (changed)
                    {
                        string output = FormatJson(js.Serialize(root));
                        File.WriteAllText(PrintServerAppSettingsPath, output);
                    }
                }
                catch (UnauthorizedAccessException)
                {
                    changes.Add("NOTICE: Could not write to Print Server appsettings.json (access denied). Update manually at: " + PrintServerAppSettingsPath);
                }
            }
            else
            {
                changes.Add("Print Server appsettings.json not found at " + PrintServerAppSettingsPath + " (service may not be installed on this machine).");
            }

            if (changes.Count == 0)
                changes.Add("All config files are already in sync. No changes needed.");

            return js.Serialize(new { success = true, changes = changes });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = "Fix failed: " + ex.Message, changes = changes });
        }
    }

    /// <summary>Basic JSON pretty-printer since JavaScriptSerializer doesn't support indented output.</summary>
    private string FormatJson(string json)
    {
        int indent = 0;
        bool inString = false;
        var sb = new System.Text.StringBuilder();
        for (int i = 0; i < json.Length; i++)
        {
            char c = json[i];
            if (c == '"' && (i == 0 || json[i-1] != '\\')) inString = !inString;
            if (inString) { sb.Append(c); continue; }

            if (c == '{' || c == '[')
            {
                sb.Append(c);
                sb.AppendLine();
                indent++;
                sb.Append(new string(' ', indent * 2));
            }
            else if (c == '}' || c == ']')
            {
                sb.AppendLine();
                indent--;
                sb.Append(new string(' ', indent * 2));
                sb.Append(c);
            }
            else if (c == ',')
            {
                sb.Append(c);
                sb.AppendLine();
                sb.Append(new string(' ', indent * 2));
            }
            else if (c == ':')
            {
                sb.Append(": ");
            }
            else
            {
                sb.Append(c);
            }
        }
        return sb.ToString();
    }

    // ===================================================================
    // Setup Wizard
    // ===================================================================
    private string GetWizardDefaults()
    {
        var js = new JavaScriptSerializer();
        var defaults = new Dictionary<string, object>();

        // Read WebClient appsettings.json
        var wcConfig = ReadAppSettingsConfig(WebClientAppSettingsPath);
        defaults["mqttServer"] = wcConfig.ContainsKey("mqttServer") ? wcConfig["mqttServer"] : "localhost";
        defaults["mqttPort"] = wcConfig.ContainsKey("mqttPort") ? wcConfig["mqttPort"] : 8883;
        defaults["printClientUsername"] = wcConfig.ContainsKey("printClientUsername") ? wcConfig["printClientUsername"] : "MasterPrint";
        defaults["printClientPassword"] = wcConfig.ContainsKey("printClientPassword") ? wcConfig["printClientPassword"] : "";
        defaults["useForPrinting"] = wcConfig.ContainsKey("useForPrinting") ? wcConfig["useForPrinting"] : false;

        // PFX path
        try
        {
            string json = File.ReadAllText(WebClientAppSettingsPath);
            var root = js.Deserialize<Dictionary<string, object>>(json);
            var cfg = root.ContainsKey("ConfigSettings") ? root["ConfigSettings"] as Dictionary<string, object> : root;
            if (cfg == null) cfg = root;
            defaults["pfxPath"] = cfg.ContainsKey("AuthServerPfxPath") ? cfg["AuthServerPfxPath"] : "";
        }
        catch { defaults["pfxPath"] = ""; }

        // Existing print client from DB
        defaults["printClientName"] = "iDash Print Client";
        defaults["printClientId"] = 0;
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("SELECT TOP 1 id, name, username, password FROM printclient ORDER BY id", cn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        defaults["printClientId"] = r["id"];
                        defaults["printClientName"] = r["name"].ToString().Trim();
                        // If DB has creds, prefer those
                        string dbUser = r["username"].ToString().Trim();
                        string dbPass = r["password"].ToString().Trim();
                        if (!string.IsNullOrEmpty(dbUser)) defaults["printClientUsername"] = dbUser;
                        if (!string.IsNullOrEmpty(dbPass)) defaults["printClientPassword"] = dbPass;
                    }
                }
            }
        }
        catch { }

        // Companies / sites
        var companies = new List<Dictionary<string, object>>();
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand(@"
                    SELECT c.id, c.name,
                           CASE WHEN EXISTS(SELECT 1 FROM template t WHERE t.companyid=c.id AND t.printclientid > 0)
                                THEN 1 ELSE 0 END as hasTemplate,
                           CASE WHEN EXISTS(SELECT 1 FROM clientapp ca WHERE ca.companyid=c.id AND ca.clientid LIKE 'idash_%')
                                THEN 1 ELSE 0 END as hasClientApp
                    FROM company c ORDER BY c.name", cn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        companies.Add(new Dictionary<string, object> {
                            { "id", r["id"] },
                            { "name", r["name"] },
                            { "hasTemplate", Convert.ToInt32(r["hasTemplate"]) == 1 },
                            { "hasClientApp", Convert.ToInt32(r["hasClientApp"]) == 1 }
                        });
                    }
                }
            }
        }
        catch { }
        defaults["companies"] = companies;

        // Config file existence
        defaults["webClientConfigExists"] = File.Exists(WebClientAppSettingsPath);
        defaults["webClientConfigPath"] = WebClientAppSettingsPath;
        defaults["printServerConfigExists"] = File.Exists(PrintServerAppSettingsPath);
        defaults["printServerConfigPath"] = PrintServerAppSettingsPath;

        // Default BTW path
        defaults["defaultBtwPath"] = @"c:\idash_prints\iDash_Std_Small.btw";

        return js.Serialize(defaults);
    }

    private string RunSetupWizard()
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);

        // Extract form data
        string mqttServer = (data.ContainsKey("mqttServer") ? data["mqttServer"] : "localhost").ToString();
        int mqttPort = Convert.ToInt32(data.ContainsKey("mqttPort") ? data["mqttPort"] : 8883);
        string username = (data.ContainsKey("username") ? data["username"] : "").ToString();
        string password = (data.ContainsKey("password") ? data["password"] : "").ToString();
        string clientName = (data.ContainsKey("clientName") ? data["clientName"] : "iDash Print Client").ToString();
        string btwPath = (data.ContainsKey("btwPath") ? data["btwPath"] : @"c:\idash_prints\iDash_Std_Small.btw").ToString();

        // Parse selected site IDs
        var siteIds = new List<int>();
        if (data.ContainsKey("siteIds"))
        {
            var arr = data["siteIds"] as System.Collections.ArrayList;
            if (arr != null) foreach (var id in arr) siteIds.Add(Convert.ToInt32(id));
        }

        var steps = new List<Dictionary<string, object>>();
        int stepNum = 0;

        // --- Step 1: Read current config ---
        stepNum++;
        try
        {
            var wcConfig = ReadAppSettingsConfig(WebClientAppSettingsPath);
            string currentUser = wcConfig.ContainsKey("printClientUsername") ? wcConfig["printClientUsername"].ToString() : "(not set)";
            bool currentUfp = wcConfig.ContainsKey("useForPrinting") && true.Equals(wcConfig["useForPrinting"]);
            steps.Add(MakeStep(stepNum, "Read WebClient appsettings.json", "pass",
                "Found: MqttServer=" + (wcConfig.ContainsKey("mqttServer") ? wcConfig["mqttServer"] : "?") +
                ", Port=" + (wcConfig.ContainsKey("mqttPort") ? wcConfig["mqttPort"] : "?") +
                ", User=" + currentUser + ", UseForPrinting=" + currentUfp,
                WebClientAppSettingsPath));
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Read WebClient appsettings.json", "fail", "Error: " + ex.Message, WebClientAppSettingsPath));
        }

        // --- Step 2: Set UseForPrinting = true ---
        stepNum++;
        try
        {
            if (File.Exists(WebClientAppSettingsPath))
            {
                string json = File.ReadAllText(WebClientAppSettingsPath);
                var root = js.Deserialize<Dictionary<string, object>>(json);
                var cfg = root.ContainsKey("ConfigSettings") ? root["ConfigSettings"] as Dictionary<string, object> : root;
                if (cfg == null) cfg = root;

                bool oldVal = cfg.ContainsKey("UseForPrinting") && true.Equals(cfg["UseForPrinting"]);
                cfg["UseForPrinting"] = true;
                File.WriteAllText(WebClientAppSettingsPath, FormatJson(js.Serialize(root)));

                steps.Add(MakeStep(stepNum, "Set UseForPrinting = true", "pass",
                    oldVal ? "Already set to true (no change needed)" : "Changed: false  ->  true",
                    WebClientAppSettingsPath, oldVal.ToString(), "true"));
            }
            else
            {
                // Auto-create with defaults if missing
                var newCfg = new Dictionary<string, object>
                {
                    { "UseForPrinting", true },
                    { "MqttServer", mqttServer },
                    { "MqttServerPort", mqttPort },
                    { "PrintClientUsername", username },
                    { "PrintClientPassword", password }
                };
                File.WriteAllText(WebClientAppSettingsPath, FormatJson(js.Serialize(newCfg)));
                steps.Add(MakeStep(stepNum, "Set UseForPrinting = true", "pass",
                    "Created new appsettings.json with UseForPrinting = true", WebClientAppSettingsPath));
            }
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Set UseForPrinting = true", "fail", ex.Message));
        }

        // --- Step 3: Sync credentials to WebClient config ---
        stepNum++;
        try
        {
            if (File.Exists(WebClientAppSettingsPath))
            {
                string json = File.ReadAllText(WebClientAppSettingsPath);
                var root = js.Deserialize<Dictionary<string, object>>(json);
                var cfg = root.ContainsKey("ConfigSettings") ? root["ConfigSettings"] as Dictionary<string, object> : root;
                if (cfg == null) cfg = root;

                string oldUser = cfg.ContainsKey("PrintClientUsername") ? cfg["PrintClientUsername"].ToString() : "";
                string oldPass = cfg.ContainsKey("PrintClientPassword") ? cfg["PrintClientPassword"].ToString() : "";

                bool changed = false;
                var detail = new List<string>();

                if (oldUser != username)
                {
                    cfg["PrintClientUsername"] = username;
                    changed = true;
                    detail.Add("Username: " + oldUser + "  ->  " + username);
                }
                else { detail.Add("Username: " + username + " (unchanged)"); }

                if (oldPass != password)
                {
                    cfg["PrintClientPassword"] = password;
                    changed = true;
                    detail.Add("Password: updated");
                }
                else { detail.Add("Password: unchanged"); }

                // Also sync MQTT server/port
                cfg["MqttServer"] = mqttServer;
                cfg["MqttServerPort"] = mqttPort;

                if (changed || cfg.ContainsKey("MqttServer"))
                    File.WriteAllText(WebClientAppSettingsPath, FormatJson(js.Serialize(root)));

                steps.Add(MakeStep(stepNum, "Sync credentials to WebClient config", "pass",
                    string.Join("; ", detail), WebClientAppSettingsPath));
            }
            else
            {
                // Auto-create with credentials if missing
                var newCfg = new Dictionary<string, object>
                {
                    { "UseForPrinting", true },
                    { "MqttServer", mqttServer },
                    { "MqttServerPort", mqttPort },
                    { "PrintClientUsername", username },
                    { "PrintClientPassword", password }
                };
                File.WriteAllText(WebClientAppSettingsPath, FormatJson(js.Serialize(newCfg)));
                steps.Add(MakeStep(stepNum, "Sync credentials to WebClient config", "pass",
                    "Created new appsettings.json with credentials", WebClientAppSettingsPath));
            }
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Sync credentials to WebClient config", "fail", ex.Message));
        }

        // --- (Print Server config sync removed — not used by iDash) ---

        // --- Step 4: Upsert printclient record in database ---

        stepNum++;
        int printClientId = 0;
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                // Check if printclient exists with this username
                using (var cmd = new SqlCommand("SELECT id FROM printclient WHERE username=@u", cn))
                {
                    cmd.Parameters.AddWithValue("@u", username);
                    var existing = cmd.ExecuteScalar();
                    if (existing != null && existing != DBNull.Value)
                        printClientId = Convert.ToInt32(existing);
                }

                if (printClientId > 0)
                {
                    // Update existing
                    using (var cmd = new SqlCommand("UPDATE printclient SET name=@n, password=@p WHERE id=@id", cn))
                    {
                        cmd.Parameters.AddWithValue("@n", clientName);
                        cmd.Parameters.AddWithValue("@p", password);
                        cmd.Parameters.AddWithValue("@id", printClientId);
                        cmd.ExecuteNonQuery();
                    }
                    steps.Add(MakeStep(stepNum, "Upsert printclient record in database", "pass",
                        "Updated existing print client ID " + printClientId + " ('" + clientName + "')"));
                }
                else
                {
                    // Check if any printclient exists at all
                    using (var cmd = new SqlCommand("SELECT TOP 1 id FROM printclient ORDER BY id", cn))
                    {
                        var existingAny = cmd.ExecuteScalar();
                        if (existingAny != null && existingAny != DBNull.Value)
                        {
                            printClientId = Convert.ToInt32(existingAny);
                            // Update the first one to match
                            using (var cmd2 = new SqlCommand("UPDATE printclient SET name=@n, username=@u, password=@p WHERE id=@id", cn))
                            {
                                cmd2.Parameters.AddWithValue("@n", clientName);
                                cmd2.Parameters.AddWithValue("@u", username);
                                cmd2.Parameters.AddWithValue("@p", password);
                                cmd2.Parameters.AddWithValue("@id", printClientId);
                                cmd2.ExecuteNonQuery();
                            }
                            steps.Add(MakeStep(stepNum, "Upsert printclient record in database", "pass",
                                "Updated print client ID " + printClientId + " with new credentials"));
                        }
                        else
                        {
                            // Create new
                            using (var cmd2 = new SqlCommand(@"INSERT INTO printclient (name, username, password) 
                                VALUES (@n, @u, @p); SELECT SCOPE_IDENTITY();", cn))
                            {
                                cmd2.Parameters.AddWithValue("@n", clientName);
                                cmd2.Parameters.AddWithValue("@u", username);
                                cmd2.Parameters.AddWithValue("@p", password);
                                printClientId = Convert.ToInt32(cmd2.ExecuteScalar());
                            }
                            steps.Add(MakeStep(stepNum, "Upsert printclient record in database", "pass",
                                "Created new print client '" + clientName + "' (ID " + printClientId + ")"));
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Upsert printclient record in database", "fail", ex.Message));
        }

        // --- Step 6: Remove conflicting mqttclient entries ---
        stepNum++;
        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand("DELETE FROM mqttclient WHERE username=@u", cn))
                {
                    cmd.Parameters.AddWithValue("@u", username);
                    int deleted = cmd.ExecuteNonQuery();
                    if (deleted > 0)
                        steps.Add(MakeStep(stepNum, "Remove conflicting mqttclient entries", "pass",
                            "Removed " + deleted + " row(s) with username '" + username + "' from mqttclient table  -  these would block print subscriptions."));
                    else
                        steps.Add(MakeStep(stepNum, "Remove conflicting mqttclient entries", "pass",
                            "No conflicts found  -  mqttclient table is clean."));
                }
            }
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Remove conflicting mqttclient entries", "fail", ex.Message));
        }

        // --- Step 7: Create templates for selected sites ---
        stepNum++;
        try
        {
            if (siteIds.Count == 0)
            {
                steps.Add(MakeStep(stepNum, "Create templates for selected sites", "warn", "No sites selected  -  skipped."));
            }
            else if (printClientId <= 0)
            {
                steps.Add(MakeStep(stepNum, "Create templates for selected sites", "fail",
                    "Cannot create templates  -  no valid print client ID."));
            }
            else
            {
                var created = new List<string>();
                var existing = new List<string>();
                using (var cn = new SqlConnection(ConnStr))
                {
                    cn.Open();
                    foreach (int siteId in siteIds)
                    {
                        // Get site name
                        string siteName = "";
                        using (var cmd = new SqlCommand("SELECT name FROM company WHERE id=@id", cn))
                        {
                            cmd.Parameters.AddWithValue("@id", siteId);
                            var result = cmd.ExecuteScalar();
                            siteName = result != null ? result.ToString() : "Site " + siteId;
                        }

                        // Check if template already exists
                        bool exists = false;
                        using (var cmd = new SqlCommand("SELECT COUNT(*) FROM template WHERE companyid=@cid AND printclientid > 0", cn))
                        {
                            cmd.Parameters.AddWithValue("@cid", siteId);
                            exists = (int)cmd.ExecuteScalar() > 0;
                        }

                        if (!exists)
                        {
                            using (var cmd = new SqlCommand(@"INSERT INTO template (name, templatetype, filename, printmethod, companyid, printclientid)
                                VALUES ('iDash_Std_Small', 'Asset', @fn, 'Bartender', @cid, @pcid)", cn))
                            {
                                cmd.Parameters.AddWithValue("@fn", btwPath);
                                cmd.Parameters.AddWithValue("@cid", siteId);
                                cmd.Parameters.AddWithValue("@pcid", printClientId);
                                cmd.ExecuteNonQuery();
                            }
                            created.Add(siteName);
                        }
                        else
                        {
                            existing.Add(siteName);
                        }

                        // Ensure printclientcompany mapping
                        using (var cmd = new SqlCommand(@"IF NOT EXISTS (SELECT 1 FROM printclientcompany WHERE printclientid=@pcid AND companyid=@cid)
                            INSERT INTO printclientcompany (printclientid, companyid) VALUES (@pcid, @cid)", cn))
                        {
                            cmd.Parameters.AddWithValue("@pcid", printClientId);
                            cmd.Parameters.AddWithValue("@cid", siteId);
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
                var detail = new List<string>();
                if (created.Count > 0) detail.Add("Created: " + string.Join(", ", created));
                if (existing.Count > 0) detail.Add("Already had templates: " + string.Join(", ", existing));
                steps.Add(MakeStep(stepNum, "Create templates for selected sites", "pass",
                    string.Join("; ", detail)));
            }
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Create templates for selected sites", "fail", ex.Message));
        }

        // --- Step 8: Create clientapp API keys for sites ---
        stepNum++;
        try
        {
            if (siteIds.Count == 0)
            {
                steps.Add(MakeStep(stepNum, "Create clientapp API keys", "warn", "No sites selected  -  skipped."));
            }
            else
            {
                var created = new List<string>();
                var existing = new List<string>();
                using (var cn = new SqlConnection(ConnStr))
                {
                    cn.Open();
                    foreach (int siteId in siteIds)
                    {
                        string siteName = "";
                        using (var cmd = new SqlCommand("SELECT name FROM company WHERE id=@id", cn))
                        {
                            cmd.Parameters.AddWithValue("@id", siteId);
                            var result = cmd.ExecuteScalar();
                            siteName = result != null ? result.ToString() : "Site " + siteId;
                        }

                        string clientId = "idash_" + siteName.Replace(" ", "_");
                        bool exists = false;
                        using (var cmd = new SqlCommand("SELECT COUNT(*) FROM clientapp WHERE companyid=@cid AND clientid LIKE 'idash_%'", cn))
                        {
                            cmd.Parameters.AddWithValue("@cid", siteId);
                            exists = (int)cmd.ExecuteScalar() > 0;
                        }

                        if (!exists)
                        {
                            using (var cmd = new SqlCommand(@"INSERT INTO clientapp (clientid, granttype, secret, companyid)
                                VALUES (@clientId, 'Client Credentials', 'I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H', @cid)", cn))
                            {
                                cmd.Parameters.AddWithValue("@clientId", clientId);
                                cmd.Parameters.AddWithValue("@cid", siteId);
                                cmd.ExecuteNonQuery();
                            }
                            created.Add(siteName + " (" + clientId + ")");
                        }
                        else
                        {
                            existing.Add(siteName);
                        }
                    }
                }
                var detail = new List<string>();
                if (created.Count > 0) detail.Add("Created: " + string.Join(", ", created));
                if (existing.Count > 0) detail.Add("Already had API keys: " + string.Join(", ", existing));
                steps.Add(MakeStep(stepNum, "Create clientapp API keys", "pass",
                    string.Join("; ", detail)));
            }
        }
        catch (Exception ex)
        {
            steps.Add(MakeStep(stepNum, "Create clientapp API keys", "fail", ex.Message));
        }

        // Build summary
        int passed = steps.Count(s => "pass".Equals(s["status"]));
        int warned = steps.Count(s => "warn".Equals(s["status"]));
        int failed = steps.Count(s => "fail".Equals(s["status"]));

        return js.Serialize(new {
            success = failed == 0,
            steps = steps,
            summary = new {
                total = steps.Count,
                passed = passed,
                warned = warned,
                failed = failed
            }
        });
    }

    private Dictionary<string, object> MakeStep(int num, string name, string status, string detail, string filePath = null, string oldVal = null, string newVal = null)
    {
        var step = new Dictionary<string, object> {
            { "step", num },
            { "name", name },
            { "status", status },
            { "detail", detail }
        };
        if (filePath != null) step["filePath"] = filePath;
        if (oldVal != null) step["oldValue"] = oldVal;
        if (newVal != null) step["newValue"] = newVal;
        return step;
    }

    private string RestartIIS()
    {
        var js = new JavaScriptSerializer();
        try
        {
            var psi = new ProcessStartInfo("iisreset", "/restart")
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            Process.Start(psi);
            return js.Serialize(new { success = true, message = "IIS restart initiated. The page will reload momentarily." });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = "Failed to restart IIS: " + ex.Message + ". Run 'iisreset' manually from an elevated command prompt." });
        }
    }

    // ===================================================================
    // Helpers
    // ===================================================================
    private List<Dictionary<string, object>> GetCompanyList()
    {
        var list = new List<Dictionary<string, object>>();
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand("SELECT id, name FROM company ORDER BY name", cn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                    list.Add(new Dictionary<string, object> { { "id", r["id"] }, { "name", r["name"] } });
            }
        }
        return list;
    }

    private List<Dictionary<string, object>> GetPrinterList()
    {
        var list = new List<Dictionary<string, object>>();
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand("SELECT id, name, username FROM printclient ORDER BY name", cn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                    list.Add(new Dictionary<string, object> { 
                        { "id", r["id"] }, { "name", r["name"] }, { "username", r["username"] } });
            }
        }
        return list;
    }
}
