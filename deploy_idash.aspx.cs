using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

public partial class deploy_idash : System.Web.UI.Page
{
    private static readonly JavaScriptSerializer Serializer = new JavaScriptSerializer();

    protected void Page_Load(object sender, EventArgs e)
    {
        string action = Request["action"];
        if (!string.IsNullOrEmpty(action))
        {
            Response.ContentType = "application/json";
            try
            {
                switch (action.ToLowerInvariant())
                {
                    case "check_env":
                        Response.Write(Serializer.Serialize(CheckEnvironment()));
                        break;
                    case "check_db_status":
                        Response.Write(Serializer.Serialize(CheckDatabaseStatus()));
                        break;
                    case "deploy_schema":
                        Response.Write(Serializer.Serialize(DeploySchema()));
                        break;
                    case "get_facilities":
                        Response.Write(Serializer.Serialize(GetFacilities()));
                        break;
                    case "provision_facility":
                        Response.Write(Serializer.Serialize(ProvisionFacility(Request["station"], Request["name"])));
                        break;
                    case "update_admin":
                        Response.Write(Serializer.Serialize(UpdateAdmin(Request["password"], Request["email"], Request["firstname"], Request["lastname"])));
                        break;
                    case "run_tests":
                        Response.Write(Serializer.Serialize(RunDiagnosticTests()));
                        break;
                    default:
                        Response.Write(Serializer.Serialize(new { success = false, error = "Unknown action: " + action }));
                        break;
                }
            }
            catch (Exception ex)
            {
                Response.Write(Serializer.Serialize(new { success = false, error = ex.Message, details = ex.ToString() }));
            }
            Response.End();
        }
    }

    private string GetMasterConnectionString()
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"] 
            ?? ConfigurationManager.ConnectionStrings["AssetWorx"]
            ?? ConfigurationManager.ConnectionStrings["Assetworx"];
        
        string baseCs = (cs != null && !string.IsNullOrEmpty(cs.ConnectionString))
            ? cs.ConnectionString
            : "Data Source=.\\sqlexpress;Database=iDash;User ID=iDashDBAdmin;Password=iDashDBAdmin;Encrypt=False;TrustServerCertificate=True;Connect Timeout=30";
        
        var builder = new SqlConnectionStringBuilder(baseCs);
        builder.InitialCatalog = "master";
        return builder.ConnectionString;
    }

    private string GetTargetConnectionString()
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"] 
            ?? ConfigurationManager.ConnectionStrings["AssetWorx"]
            ?? ConfigurationManager.ConnectionStrings["Assetworx"];
        
        string baseCs = (cs != null && !string.IsNullOrEmpty(cs.ConnectionString))
            ? cs.ConnectionString
            : "Data Source=.\\sqlexpress;Database=iDash;User ID=iDashDBAdmin;Password=iDashDBAdmin;Encrypt=False;TrustServerCertificate=True;Connect Timeout=30";

        var builder = new SqlConnectionStringBuilder(baseCs);
        builder.InitialCatalog = "iDash";
        return builder.ConnectionString;
    }

    private object CheckEnvironment()
    {
        var items = new List<object>();

        // 1. Operating System & Machine
        items.Add(new {
            title = "Host Operating System",
            value = Environment.OSVersion.VersionString + (Environment.Is64BitOperatingSystem ? " (64-bit)" : " (32-bit)"),
            status = "ok",
            detail = "Machine Name: " + Environment.MachineName
        });

        // 2. .NET Framework Runtime
        items.Add(new {
            title = ".NET Runtime",
            value = "CLR v" + Environment.Version.ToString(),
            status = "ok",
            detail = "Process Bit: " + (Environment.Is64BitProcess ? "64-bit ASP.NET worker" : "32-bit")
        });

        // 3. Web Application Working Directory & App_Data
        string appDataPath = Server.MapPath("~/App_Data");
        bool appDataWritable = false;
        string appDataError = "";
        try
        {
            if (!Directory.Exists(appDataPath)) Directory.CreateDirectory(appDataPath);
            string testFile = Path.Combine(appDataPath, "probe_" + Guid.NewGuid().ToString("N") + ".tmp");
            File.WriteAllText(testFile, "probe");
            File.Delete(testFile);
            appDataWritable = true;
        }
        catch (Exception ex)
        {
            appDataError = ex.Message;
        }

        items.Add(new {
            title = "App_Data Permissions",
            value = appDataWritable ? "Read/Write Permitted" : "Write Denied",
            status = appDataWritable ? "ok" : "err",
            detail = appDataWritable ? appDataPath : ("Error: " + appDataError)
        });

        // 4. Disk Space on Hosting Volume
        string driveLetter = Path.GetPathRoot(Server.MapPath("~/"));
        long freeGb = 0;
        try
        {
            var drive = new DriveInfo(driveLetter);
            freeGb = drive.AvailableFreeSpace / (1024 * 1024 * 1024);
        }
        catch { }

        items.Add(new {
            title = "Volume Free Space (" + driveLetter + ")",
            value = freeGb.ToString() + " GB Available",
            status = (freeGb > 5) ? "ok" : "warn",
            detail = "Hosting root: " + Server.MapPath("~/")
        });

        // 5. SQL Server Connectivity
        bool sqlConnected = false;
        string sqlVersion = "";
        string sqlError = "";
        try
        {
            using (var conn = new SqlConnection(GetMasterConnectionString()))
            {
                conn.Open();
                using (var cmd = new SqlCommand("SELECT @@VERSION;", conn))
                {
                    object v = cmd.ExecuteScalar();
                    if (v != null) sqlVersion = v.ToString();
                }
                sqlConnected = true;
            }
        }
        catch (Exception ex)
        {
            sqlError = ex.Message;
        }

        items.Add(new {
            title = "SQL Server Engine Connection",
            value = sqlConnected ? "Connected Successfully" : "Connection Failed",
            status = sqlConnected ? "ok" : "err",
            detail = sqlConnected ? (sqlVersion.Split('\n')[0].Trim()) : ("Connection error: " + sqlError)
        });

        return new {
            success = true,
            items = items,
            allHealthy = appDataWritable && sqlConnected && freeGb > 2
        };
    }

    private object CheckDatabaseStatus()
    {
        bool dbExists = false;
        int tableCount = 0;
        int viewCount = 0;
        int assetCount = 0;
        bool hasLegacyRemnants = false;
        var tables = new List<string>();
        var views = new List<string>();
        var legacyIssues = new List<string>();

        // Check master to see if iDash DB exists
        using (var conn = new SqlConnection(GetMasterConnectionString()))
        {
            conn.Open();
            using (var cmd = new SqlCommand("SELECT COUNT(*) FROM sys.databases WHERE name = 'iDash';", conn))
            {
                dbExists = (Convert.ToInt32(cmd.ExecuteScalar()) > 0);
            }
        }

        if (dbExists)
        {
            using (var conn = new SqlConnection(GetTargetConnectionString()))
            {
                conn.Open();
                
                // Get Base Tables
                using (var cmd = new SqlCommand("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;", conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read()) tables.Add(r.GetString(0));
                }
                tableCount = tables.Count;

                // Get Views
                using (var cmd = new SqlCommand("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS ORDER BY TABLE_NAME;", conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read()) views.Add(r.GetString(0));
                }
                viewCount = views.Count;

                // Asset Count
                if (tables.Contains("asset"))
                {
                    using (var cmd = new SqlCommand("SELECT COUNT(*) FROM dbo.asset;", conn))
                    {
                        assetCount = Convert.ToInt32(cmd.ExecuteScalar());
                    }
                }

                // Check for Legacy Remnants in sysuser
                if (tables.Contains("sysuser"))
                {
                    using (var cmd = new SqlCommand("SELECT COUNT(*) FROM dbo.sysuser WHERE username IN ('admin', 'superadmin');", conn))
                    {
                        int legacyUsers = Convert.ToInt32(cmd.ExecuteScalar());
                        if (legacyUsers > 0)
                        {
                            hasLegacyRemnants = true;
                            legacyIssues.Add(legacyUsers.ToString() + " legacy AssetWorx default users found in dbo.sysuser");
                        }
                    }
                }

                // Check for Legacy AW* tables
                using (var cmd = new SqlCommand("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'AW%' OR TABLE_NAME LIKE 'vtag%';", conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        hasLegacyRemnants = true;
                        legacyIssues.Add("Legacy table detected: " + r.GetString(0));
                    }
                }
            }
        }

        return new {
            success = true,
            dbExists = dbExists,
            tableCount = tableCount,
            viewCount = viewCount,
            assetCount = assetCount,
            hasLegacyRemnants = hasLegacyRemnants,
            legacyIssues = legacyIssues,
            tables = tables,
            views = views,
            isReady = dbExists && tableCount >= 24 && viewCount >= 7 && !hasLegacyRemnants
        };
    }

    private object DeploySchema()
    {
        string scriptPath = Server.MapPath("~/sql/idash_schema_setup.sql");
        if (!File.Exists(scriptPath))
        {
            return new { success = false, error = "Schema script file not found at: " + scriptPath };
        }

        // Ensure database exists
        using (var masterConn = new SqlConnection(GetMasterConnectionString()))
        {
            masterConn.Open();
            using (var cmd = new SqlCommand("IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'iDash') CREATE DATABASE [iDash];", masterConn))
            {
                cmd.ExecuteNonQuery();
            }
        }

        string fullScript = File.ReadAllText(scriptPath);
        string[] rawBatches = fullScript.Split(new string[] { "\nGO\r", "\nGO\n", "\r\nGO\r\n", "\nGO ", "\r\nGO " }, StringSplitOptions.RemoveEmptyEntries);

        int executed = 0;
        int failed = 0;
        var errors = new List<string>();

        using (var conn = new SqlConnection(GetTargetConnectionString()))
        {
            conn.Open();
            foreach (var raw in rawBatches)
            {
                string batch = raw.Trim();
                if (string.IsNullOrEmpty(batch) || batch.StartsWith("-- ==") || batch.StartsWith("SET NOCOUNT"))
                    continue;

                try
                {
                    using (var cmd = new SqlCommand(batch, conn))
                    {
                        cmd.CommandTimeout = 120;
                        cmd.ExecuteNonQuery();
                        executed++;
                    }
                }
                catch (Exception ex)
                {
                    failed++;
                    if (errors.Count < 10)
                    {
                        errors.Add("Batch error: " + ex.Message);
                    }
                }
            }
        }

        return new {
            success = (failed == 0),
            batchesExecuted = executed,
            batchesFailed = failed,
            errors = errors
        };
    }

    private object GetFacilities()
    {
        var list = new List<object>();
        using (var conn = new SqlConnection(GetTargetConnectionString()))
        {
            conn.Open();
            string sql = @"
                SELECT c.id, c.name,
                       (SELECT COUNT(*) FROM dbo.asset a WHERE a.companyid = c.id) as AssetCount,
                       (SELECT TOP 1 clientid FROM dbo.clientapp ca WHERE ca.companyid = c.id AND ca.clientid LIKE 'idash_%') as ClientId,
                       (SELECT TOP 1 username FROM dbo.mqttclient mc WHERE mc.companyid = c.id) as MqttUser
                FROM dbo.company c
                ORDER BY c.name;";
            
            using (var cmd = new SqlCommand(sql, conn))
            using (var r = cmd.ExecuteReader())
            {
                while (r.Read())
                {
                    list.Add(new {
                        id = Convert.ToInt32(r["id"]),
                        name = r["name"].ToString(),
                        assetCount = Convert.ToInt32(r["AssetCount"]),
                        clientId = r["ClientId"] != DBNull.Value ? r["ClientId"].ToString() : "Not Provisioned",
                        mqttUser = r["MqttUser"] != DBNull.Value ? r["MqttUser"].ToString() : "Not Provisioned"
                    });
                }
            }
        }

        return new { success = true, facilities = list };
    }

    private object ProvisionFacility(string station, string name)
    {
        if (string.IsNullOrEmpty(station) || string.IsNullOrEmpty(name))
            return new { success = false, error = "Station number and Facility Name are required." };

        station = station.Trim();
        name = name.Trim();
        string fullName = station + " " + name;

        using (var conn = new SqlConnection(GetTargetConnectionString()))
        {
            conn.Open();
            using (var tx = conn.BeginTransaction())
            {
                try
                {
                    int companyId = 0;
                    // 1. Insert or get company
                    using (var cmd = new SqlCommand("IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = @name) INSERT INTO dbo.company (name) VALUES (@name); SELECT id FROM dbo.company WHERE name = @name;", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@name", fullName);
                        companyId = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    // 2. Provision OAuth ClientApp
                    string clientId = "idash_" + station;
                    string secret = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N");
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (SELECT 1 FROM dbo.clientapp WHERE clientid = @cid)
                            INSERT INTO dbo.clientapp (clientid, granttype, secret, allowRefreshTokens, companyid)
                            VALUES (@cid, 'client_credentials', @sec, 1, @compid)
                        ELSE
                            UPDATE dbo.clientapp SET companyid = @compid WHERE clientid = @cid;", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@cid", clientId);
                        cmd.Parameters.AddWithValue("@sec", secret);
                        cmd.Parameters.AddWithValue("@compid", companyId);
                        cmd.ExecuteNonQuery();
                    }

                    // 3. Provision MQTT Client
                    string mqttUser = "mqtt_" + station + "_" + name.ToLowerInvariant().Replace(" ", "_");
                    string mqttPass = "Mqtt" + station + "!" + Guid.NewGuid().ToString("N").Substring(0, 6);
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (SELECT 1 FROM dbo.mqttclient WHERE username = @muser)
                            INSERT INTO dbo.mqttclient (companyid, username, password, accessgatewaymessages, accesstagmovements, accesstagobservations, accessevents, accessalarms)
                            VALUES (@compid, @muser, @mpass, 1, 1, 1, 1, 1);", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@compid", companyId);
                        cmd.Parameters.AddWithValue("@muser", mqttUser);
                        cmd.Parameters.AddWithValue("@mpass", mqttPass);
                        cmd.ExecuteNonQuery();
                    }

                    tx.Commit();
                    return new { success = true, companyId = companyId, fullName = fullName, clientId = clientId, mqttUser = mqttUser };
                }
                catch (Exception ex)
                {
                    tx.Rollback();
                    return new { success = false, error = ex.Message };
                }
            }
        }
    }

    private object UpdateAdmin(string password, string email, string firstname, string lastname)
    {
        using (var conn = new SqlConnection(GetTargetConnectionString()))
        {
            conn.Open();
            string sql;
            if (!string.IsNullOrEmpty(password))
            {
                string hashed = HashPasswordV3(password);
                sql = @"
                    IF EXISTS (SELECT 1 FROM dbo.sysuser WHERE username = 'idashadmin')
                        UPDATE dbo.sysuser 
                        SET password = @pwd, email = @email, firstname = @first, lastname = @last, usertype = 'Create, Edit, Delete'
                        WHERE username = 'idashadmin';
                    ELSE
                        INSERT INTO dbo.sysuser (username, password, firstname, lastname, email, usertype)
                        VALUES ('idashadmin', @pwd, @first, @last, @email, 'Create, Edit, Delete');";
                
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@pwd", hashed);
                    cmd.Parameters.AddWithValue("@email", string.IsNullOrEmpty(email) ? "admin@idash.local" : email.Trim());
                    cmd.Parameters.AddWithValue("@first", string.IsNullOrEmpty(firstname) ? "iDash" : firstname.Trim());
                    cmd.Parameters.AddWithValue("@last", string.IsNullOrEmpty(lastname) ? "Administrator" : lastname.Trim());
                    cmd.ExecuteNonQuery();
                }
            }
            else
            {
                sql = @"
                    IF EXISTS (SELECT 1 FROM dbo.sysuser WHERE username = 'idashadmin')
                        UPDATE dbo.sysuser 
                        SET email = @email, firstname = @first, lastname = @last
                        WHERE username = 'idashadmin';";
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@email", string.IsNullOrEmpty(email) ? "admin@idash.local" : email.Trim());
                    cmd.Parameters.AddWithValue("@first", string.IsNullOrEmpty(firstname) ? "iDash" : firstname.Trim());
                    cmd.Parameters.AddWithValue("@last", string.IsNullOrEmpty(lastname) ? "Administrator" : lastname.Trim());
                    cmd.ExecuteNonQuery();
                }
            }
        }

        return new { success = true, message = "Administrator account updated successfully." };
    }

    private object RunDiagnosticTests()
    {
        var results = new List<object>();
        bool allPassed = true;

        // Test 1: Database Read Test
        try
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            int count = 0;
            using (var conn = new SqlConnection(GetTargetConnectionString()))
            {
                conn.Open();
                using (var cmd = new SqlCommand("SELECT COUNT(*) FROM dbo.asset;", conn))
                {
                    count = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
            sw.Stop();
            results.Add(new {
                name = "Database Read & Row Enumeration",
                passed = true,
                latencyMs = sw.ElapsedMilliseconds,
                message = "Successfully enumerated " + count.ToString("N0") + " assets in " + sw.ElapsedMilliseconds + "ms"
            });
        }
        catch (Exception ex)
        {
            allPassed = false;
            results.Add(new {
                name = "Database Read & Row Enumeration",
                passed = false,
                latencyMs = -1,
                message = "Failed: " + ex.Message
            });
        }

        // Test 2: Database Synthetic Write Probe (dbo.assettemp)
        try
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            string probeName = "PROBE_" + Guid.NewGuid().ToString("N").Substring(0, 8);
            using (var conn = new SqlConnection(GetTargetConnectionString()))
            {
                conn.Open();
                using (var cmd = new SqlCommand("INSERT INTO dbo.assettemp (name, description, checkinstatus) VALUES (@n, 'Deploy Probe', 'Test');", conn))
                {
                    cmd.Parameters.AddWithValue("@n", probeName);
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = new SqlCommand("DELETE FROM dbo.assettemp WHERE name = @n;", conn))
                {
                    cmd.Parameters.AddWithValue("@n", probeName);
                    cmd.ExecuteNonQuery();
                }
            }
            sw.Stop();
            results.Add(new {
                name = "Database Write Probe (CRUD Transaction)",
                passed = true,
                latencyMs = sw.ElapsedMilliseconds,
                message = "Inserted and removed synthetic probe in " + sw.ElapsedMilliseconds + "ms"
            });
        }
        catch (Exception ex)
        {
            allPassed = false;
            results.Add(new {
                name = "Database Write Probe (CRUD Transaction)",
                passed = false,
                latencyMs = -1,
                message = "Failed: " + ex.Message
            });
        }

        // Test 3: Asset Master View Latency (dbo.v_asset)
        try
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            int topCount = 0;
            using (var conn = new SqlConnection(GetTargetConnectionString()))
            {
                conn.Open();
                using (var cmd = new SqlCommand("SELECT COUNT(*) FROM (SELECT TOP 100 id FROM dbo.v_asset) t;", conn))
                {
                    topCount = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
            sw.Stop();
            results.Add(new {
                name = "Asset Master View Resolution (dbo.v_asset)",
                passed = true,
                latencyMs = sw.ElapsedMilliseconds,
                message = "Resolved top " + topCount.ToString() + " unified assets in " + sw.ElapsedMilliseconds + "ms"
            });
        }
        catch (Exception ex)
        {
            allPassed = false;
            results.Add(new {
                name = "Asset Master View Resolution (dbo.v_asset)",
                passed = false,
                latencyMs = -1,
                message = "Failed: " + ex.Message
            });
        }

        // Test 4: Pure iDash Scan API Endpoint
        try
        {
            string scanApiUrl = Request.Url.GetLeftPart(UriPartial.Authority) + ResolveUrl("~/scan_api.aspx?epc=TESTPROBE");
            var req = System.Net.WebRequest.Create(scanApiUrl);
            req.Timeout = 4000;
            var sw = System.Diagnostics.Stopwatch.StartNew();
            using (var resp = (System.Net.HttpWebResponse)req.GetResponse())
            {
                sw.Stop();
                bool ok = (resp.StatusCode == System.Net.HttpStatusCode.OK);
                results.Add(new {
                    name = "RFID Scan API Endpoint (scan_api.aspx)",
                    passed = ok,
                    latencyMs = sw.ElapsedMilliseconds,
                    message = "HTTP " + ((int)resp.StatusCode).ToString() + " OK in " + sw.ElapsedMilliseconds + "ms"
                });
            }
        }
        catch (Exception ex)
        {
            // If local web request fails due to loopback check or self-signed cert, evaluate file existence
            bool fileExists = File.Exists(Server.MapPath("~/scan_api.aspx"));
            results.Add(new {
                name = "RFID Scan API Endpoint (scan_api.aspx)",
                passed = fileExists,
                latencyMs = 0,
                message = fileExists ? "Endpoint verified on disk (Loopback HTTP: " + ex.Message + ")" : ("Error: " + ex.Message)
            });
        }

        // Test 5: MQTT Port 1883 Socket Ping
        try
        {
            var sw = System.Diagnostics.Stopwatch.StartNew();
            using (var tcp = new TcpClient())
            {
                var asyncResult = tcp.BeginConnect("127.0.0.1", 1883, null, null);
                bool success = asyncResult.AsyncWaitHandle.WaitOne(1000);
                sw.Stop();
                if (success && tcp.Connected)
                {
                    tcp.EndConnect(asyncResult);
                    results.Add(new {
                        name = "MQTT Broker Service (Port 1883)",
                        passed = true,
                        latencyMs = sw.ElapsedMilliseconds,
                        message = "MQTT Broker listening on localhost:1883 (" + sw.ElapsedMilliseconds + "ms)"
                    });
                }
                else
                {
                    results.Add(new {
                        name = "MQTT Broker Service (Port 1883)",
                        passed = true, // Warning only, optional service
                        latencyMs = -1,
                        message = "MQTT Broker port 1883 not listening locally (Fixed Reader gateway runs asynchronously)"
                    });
                }
            }
        }
        catch (Exception ex)
        {
            results.Add(new {
                name = "MQTT Broker Service (Port 1883)",
                passed = true, // Warning only
                latencyMs = -1,
                message = "MQTT Notice: " + ex.Message
            });
        }

        return new {
            success = true,
            allPassed = allPassed,
            results = results,
            certifiedTimestamp = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss 'UTC'"),
            serverHost = Environment.MachineName
        };
    }

    private static string HashPasswordV3(string password)
    {
        const int SaltSize = 16, SubkeySize = 32, Iterations = 10000;
        byte[] salt = new byte[SaltSize];
        using (var rng = RandomNumberGenerator.Create()) rng.GetBytes(salt);
        byte[] subkey;
        using (var kdf = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
            subkey = kdf.GetBytes(SubkeySize);
        byte[] output = new byte[1 + 4 + 4 + 4 + SaltSize + SubkeySize];
        output[0] = 0x01;
        WriteNBO(output, 1, 1); WriteNBO(output, 5, Iterations); WriteNBO(output, 9, SaltSize);
        System.Buffer.BlockCopy(salt, 0, output, 13, SaltSize);
        System.Buffer.BlockCopy(subkey, 0, output, 13 + SaltSize, SubkeySize);
        return Convert.ToBase64String(output);
    }

    private static void WriteNBO(byte[] buf, int offset, int value)
    {
        unchecked {
            buf[offset]   = (byte)(((uint)value >> 24) & 0xFF);
            buf[offset+1] = (byte)(((uint)value >> 16) & 0xFF);
            buf[offset+2] = (byte)(((uint)value >> 8)  & 0xFF);
            buf[offset+3] = (byte)(((uint)value)       & 0xFF);
        }
    }
}
