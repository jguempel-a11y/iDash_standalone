using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.IO;
using System.Text;

namespace iDash
{
    public partial class va_db_restore : System.Web.UI.Page
    {
        private string BackupPath 
        { 
            get { return string.IsNullOrWhiteSpace(TxtBackupPath.Text) ? @"c:\VA_RFID\va_dbupdate\backup" : TxtBackupPath.Text.Trim(); } 
        }
        private StringBuilder _log = new StringBuilder();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadBackups();
            }
        }

        protected void BtnLoadBackups_Click(object sender, EventArgs e)
        {
            LoadBackups();
        }

        private void LoadBackups()
        {
            try
            {
                DDLBackups.Items.Clear();
                BtnRestore.Enabled = true;

                var candidateDirs = new List<string>();
                if (!string.IsNullOrWhiteSpace(BackupPath)) candidateDirs.Add(BackupPath);
                candidateDirs.Add(@"c:\VA_RFID\va_dbupdate\backup");
                candidateDirs.Add(@"c:\VA_RFID\backup");
                candidateDirs.Add(@"c:\backups");
                try { candidateDirs.Add(Server.MapPath("~/App_Data/backup")); } catch { }

                var foundFiles = new List<ListItem>();
                string primaryDir = null;

                foreach (var dir in candidateDirs.Distinct(StringComparer.OrdinalIgnoreCase))
                {
                    try
                    {
                        if (Directory.Exists(dir))
                        {
                            var files = Directory.GetFiles(dir, "*.bak")
                                                 .Select(f => new ListItem(Path.GetFileName(f) + " [" + dir + "]", f))
                                                 .OrderByDescending(i => i.Text)
                                                 .ToList();
                            if (files.Count > 0)
                            {
                                foundFiles.AddRange(files);
                                if (primaryDir == null) primaryDir = dir;
                            }
                        }
                    }
                    catch { }
                }

                if (foundFiles.Count > 0)
                {
                    DDLBackups.Items.AddRange(foundFiles.ToArray());
                    if (primaryDir != null && string.IsNullOrWhiteSpace(TxtBackupPath.Text))
                        TxtBackupPath.Text = primaryDir;
                    Log("Ready. Found " + foundFiles.Count + " backup file(s).", "info");
                }
                else
                {
                    Log("No .bak files found in " + BackupPath + " or standard backup paths.", "warn");
                    BtnRestore.Enabled = false;
                }
            }
            catch (Exception ex)
            {
                Log("Error listing backups: " + ex.Message, "error");
            }
        }

        protected void BtnRestore_Click(object sender, EventArgs e)
        {
            string backupFile = DDLBackups.SelectedValue;
            if (string.IsNullOrEmpty(backupFile)) return;

            _log.Clear();
            Log("Starting restore process for: " + Path.GetFileName(backupFile), "info");

            string connStr = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
            SqlConnectionStringBuilder csb = new SqlConnectionStringBuilder(connStr);
            csb.InitialCatalog = "master"; 
            string masterConnStr = csb.ToString();

            try
            {
                using (SqlConnection conn = new SqlConnection(masterConnStr))
                {
                    conn.Open();
                    Log("Connected to SQL Server (master).", "success");

                    // 1. Kill Connections
                    Log("Setting database to SINGLE_USER...", "info");
                    ExecuteSql(conn, "ALTER DATABASE [idash] SET SINGLE_USER WITH ROLLBACK IMMEDIATE");
                    Log("Active connections dropped.", "success");

                    // 2. Restore
                    Log("Restoring database... (this may take a moment)", "info");
                    string restoreSql = string.Format("RESTORE DATABASE [idash] FROM DISK = '{0}' WITH REPLACE", backupFile);
                    ExecuteSql(conn, restoreSql);
                    Log("Database restore complete.", "success");

                    // 3. Multi User
                    Log("Setting database to MULTI_USER...", "info");
                    ExecuteSql(conn, "ALTER DATABASE [idash] SET MULTI_USER");

                    // 4. Run Normalizations & Fixes
                    RunPostRestoreNormalizations(conn, csb);

                    Log("=============================", "info");
                    Log("RESTORE & NORMALIZATION SUCCESSFUL!", "success");
                    Log("=============================", "info");
                }
            }
            catch (Exception ex)
            {
                Log("CRITICAL ERROR: " + ex.Message, "error");
                try {
                    using (SqlConnection conn = new SqlConnection(masterConnStr)) {
                        conn.Open();
                        ExecuteSql(conn, "ALTER DATABASE [idash] SET MULTI_USER");
                    }
                } catch { }
            }
        }

        protected void BtnRunFixes_Click(object sender, EventArgs e)
        {
            _log.Clear();
            Log("Running schema migration and data normalization on existing database...", "info");

            string connStr = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
            SqlConnectionStringBuilder csb = new SqlConnectionStringBuilder(connStr);
            csb.InitialCatalog = "master";
            string masterConnStr = csb.ToString();

            try
            {
                using (SqlConnection conn = new SqlConnection(masterConnStr))
                {
                    conn.Open();
                    Log("Connected to SQL Server (master).", "success");
                    RunPostRestoreNormalizations(conn, csb);
                    Log("=============================", "info");
                    Log("ALL FIXES & NORMALIZATIONS COMPLETE!", "success");
                    Log("=============================", "info");
                }
            }
            catch (Exception ex)
            {
                Log("Error during normalization: " + ex.Message, "error");
            }
        }

        private void RunPostRestoreNormalizations(SqlConnection conn, SqlConnectionStringBuilder csb)
        {
            // Step 1: Ensure master login 'idashadmin' exists
            try
            {
                ExecuteSql(conn, @"
                    USE [master];
                    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'idashadmin')
                    BEGIN
                        CREATE LOGIN [idashadmin] WITH PASSWORD = 'idashadmin', DEFAULT_DATABASE = [idash], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;
                    END");
                Log("SQL login 'idashadmin' verified.", "success");
            }
            catch (Exception ex)
            {
                Log("Could not verify server login 'idashadmin': " + ex.Message, "warn");
            }

            // Step 2: Fix orphaned user 'idashadmin'
            Log("Fixing orphaned user 'idashadmin'...", "info");
            bool userFixed = false;

            // Method A: ALTER AUTHORIZATION
            try
            {
                ExecuteSql(conn, "ALTER AUTHORIZATION ON DATABASE::[idash] TO [idashadmin]");
                Log("Database ownership set to idashadmin.", "success");
                userFixed = true;
            }
            catch (Exception ex)
            {
                Log("Method A (ALTER AUTHORIZATION) warning: " + ex.Message, "warn");
            }

            // Method B: Windows / direct auth connection
            if (!userFixed)
            {
                try
                {
                    SqlConnectionStringBuilder fixBuilder = new SqlConnectionStringBuilder();
                    fixBuilder.DataSource         = csb.DataSource;
                    fixBuilder.InitialCatalog     = "iDash";
                    fixBuilder.IntegratedSecurity = true;

                    using (SqlConnection fixConn = new SqlConnection(fixBuilder.ToString()))
                    {
                        fixConn.Open();
                        ExecuteSql(fixConn,
                            "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'idashadmin') " +
                            "    ALTER USER [idashadmin] WITH LOGIN = [idashadmin]; " +
                            "ELSE IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'idashadmin') " +
                            "    CREATE USER [idashadmin] FOR LOGIN [idashadmin];");
                        try { ExecuteSql(fixConn, "ALTER ROLE [db_owner] ADD MEMBER [idashadmin]"); } catch { }
                        userFixed = true;
                        Log("User re-linked via Windows auth.", "success");
                    }
                }
                catch (Exception ex)
                {
                    Log("Method B (Windows auth) failed: " + ex.Message, "warn");
                }
            }

            // Method C: sp_change_users_login
            if (!userFixed)
            {
                try
                {
                    ExecuteSql(conn, "USE [idash]; EXEC sp_change_users_login 'Auto_Fix', 'idashadmin'");
                    userFixed = true;
                    Log("User re-linked via sp_change_users_login.", "success");
                }
                catch (Exception ex)
                {
                    Log("Method C (sp_change_users_login) failed: " + ex.Message, "warn");
                }
            }

            // Step 3: Server role bulkadmin
            try
            {
                ExecuteSql(conn, "USE [master]; " +
                    "IF NOT EXISTS (" +
                    "  SELECT 1 FROM sys.server_role_members rm " +
                    "  JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id " +
                    "  JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id " +
                    "  WHERE r.name = 'bulkadmin' AND m.name = 'idashadmin') " +
                    "ALTER SERVER ROLE [bulkadmin] ADD MEMBER [idashadmin]");
                Log("Bulkadmin role verified.", "success");
            }
            catch (Exception ex)
            {
                Log("Could not verify bulkadmin: " + ex.Message, "warn");
            }

            // Step 4: Schema migration & data normalization
            try
            {
                ExecuteSql(conn, "USE [idash]");

                // 4a. sysuser columns
                Log("Running sysuser column migration...", "info");
                string[] columnPatches = new[]
                {
                    "IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'hideadminpopups') " +
                        "ALTER TABLE dbo.sysuser ADD hideadminpopups BIT NOT NULL DEFAULT 0",
                    "IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'inventorylimiteduser') " +
                        "ALTER TABLE dbo.sysuser ADD inventorylimiteduser BIT NOT NULL DEFAULT 0",
                    "IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'restricteditmobile') " +
                        "ALTER TABLE dbo.sysuser ADD restricteditmobile BIT NOT NULL DEFAULT 0"
                };
                foreach (string patch in columnPatches)
                    ExecuteSql(conn, patch);
                Log("Sysuser columns verified.", "success");

                // 4b. v_sysuser view fix
                Log("Verifying v_sysuser view...", "info");
                try
                {
                    ExecuteSql(conn, @"
                        ALTER VIEW dbo.v_sysuser AS
                        SELECT s.*,
                           COALESCE(c.name, '') AS companyname
                        FROM sysuser s
                        LEFT JOIN company c ON c.id = s.companyid");
                    Log("v_sysuser view updated.", "success");
                }
                catch (Exception vEx) { Log("v_sysuser warning: " + vEx.Message, "warn"); }

                // 4c. Provision / sync API OAuth credentials in dbo.clientapp
                Log("Syncing API OAuth credentials in dbo.clientapp...", "info");
                try
                {
                    string cfgClientId = ConfigurationManager.AppSettings["iDash_ClientId"];
                    string cfgClientSecret = ConfigurationManager.AppSettings["iDash_ClientSecret"];
                    if (string.IsNullOrWhiteSpace(cfgClientId)) cfgClientId = "v512";
                    if (string.IsNullOrWhiteSpace(cfgClientSecret)) cfgClientSecret = "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H";

                    var clientsToSync = new List<string[]>
                    {
                        new[] { cfgClientId, cfgClientSecret },
                        new[] { "v512", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" },
                        new[] { "idash_540", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" },
                        new[] { "idash_517", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" },
                        new[] { "idash_581", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" },
                        new[] { "idash_512", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" },
                        new[] { "idash_613", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" },
                        new[] { "idash_688", "I9GOuR6krMTDT4C8LaIlKyEzTgWa6ZOnBWSpHW8WO2scoHZH2H" }
                    };

                    ExecuteSql(conn, @"
                        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'clientapp')
                        BEGIN
                            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.clientapp') AND name = 'allowRefreshTokens')
                                ALTER TABLE dbo.clientapp ADD allowRefreshTokens BIT NOT NULL DEFAULT 1;
                        END");

                    foreach (var c in clientsToSync)
                    {
                        string cSql = string.Format(@"
                            IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'clientapp')
                            BEGIN
                                IF NOT EXISTS (SELECT 1 FROM dbo.clientapp WHERE clientid = '{0}')
                                    INSERT INTO dbo.clientapp (clientid, granttype, secret, allowRefreshTokens, companyid)
                                    VALUES ('{0}', 'Client Credentials', '{1}', 1, 1);
                                ELSE
                                    UPDATE dbo.clientapp SET secret = '{1}' WHERE clientid = '{0}';
                            END", c[0].Replace("'", "''"), c[1].Replace("'", "''"));
                        ExecuteSql(conn, cSql);
                    }
                    Log("API OAuth clientapp credentials synced.", "success");
                }
                catch (Exception caEx)
                {
                    Log("clientapp sync warning: " + caEx.Message, "warn");
                }

                // 4d. Data normalization patches
                Log("Running data normalization patches...", "info");
                string[] dataNormPatches = new[]
                {
                    // Rename short company names
                    "UPDATE dbo.company SET name = '540 Clarksburg'    WHERE name = '540'",
                    "UPDATE dbo.company SET name = '517 Beckley'       WHERE name = '517'",
                    "UPDATE dbo.company SET name = '581 Huntington'    WHERE name = '581'",
                    "UPDATE dbo.company SET name = '512 Baltimore'     WHERE name = '512'",
                    "UPDATE dbo.company SET name = '613 Martinsburg'   WHERE name = '613'",
                    "UPDATE dbo.company SET name = '688 Washington DC' WHERE name = '688'",

                    // Provision VISN 5 companies if missing
                    "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name LIKE '540%') INSERT INTO dbo.company (name) VALUES ('540 Clarksburg')",
                    "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name LIKE '517%') INSERT INTO dbo.company (name) VALUES ('517 Beckley')",
                    "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name LIKE '581%') INSERT INTO dbo.company (name) VALUES ('581 Huntington')",
                    "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name LIKE '512%') INSERT INTO dbo.company (name) VALUES ('512 Baltimore')",
                    "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name LIKE '613%') INSERT INTO dbo.company (name) VALUES ('613 Martinsburg')",
                    "IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name LIKE '688%') INSERT INTO dbo.company (name) VALUES ('688 Washington DC')",

                    // Delete duplicate empty companies
                    "DELETE FROM dbo.company WHERE id NOT IN (" +
                        "SELECT MIN(id) FROM dbo.company " +
                        "WHERE LEFT(name, 3) IN ('540','517','581','512','613','688') " +
                        "GROUP BY LEFT(name, 3)) " +
                    "AND LEFT(name, 3) IN ('540','517','581','512','613','688') " +
                    "AND NOT EXISTS (SELECT 1 FROM dbo.asset WHERE companyid = dbo.company.id) " +
                    "AND NOT EXISTS (SELECT 1 FROM dbo.sysuser WHERE companyid = dbo.company.id)",

                    // Fix companyid on assets based on station number (text7)
                    "UPDATE a SET a.companyid = " +
                        "CASE a.text7 " +
                            "WHEN '517' THEN (SELECT MIN(id) FROM dbo.company WHERE name LIKE '517%') " +
                            "WHEN '581' THEN (SELECT MIN(id) FROM dbo.company WHERE name LIKE '581%') " +
                            "WHEN '540' THEN (SELECT MIN(id) FROM dbo.company WHERE name LIKE '540%') " +
                            "WHEN '512' THEN (SELECT MIN(id) FROM dbo.company WHERE name LIKE '512%') " +
                            "WHEN '613' THEN (SELECT MIN(id) FROM dbo.company WHERE name LIKE '613%') " +
                            "WHEN '688' THEN (SELECT MIN(id) FROM dbo.company WHERE name LIKE '688%') " +
                        "END " +
                    "FROM dbo.asset a " +
                    "WHERE a.text7 IN ('517','581','540','512','613','688') " +
                      "AND (a.companyid = 0 OR a.companyid IS NULL " +
                           "OR NOT EXISTS (SELECT 1 FROM dbo.company WHERE id = a.companyid))",

                    // Enforce SP prefix on location fields
                    "UPDATE a SET " +
                        "a.text6 = CASE " +
                            "WHEN a.text6 IS NULL OR LTRIM(RTRIM(a.text6)) = '' THEN 'SPZZUNKNOWN' " +
                            "WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text6),3,500)) " +
                            "ELSE 'SP' + LTRIM(a.text6) END, " +
                        "a.text11 = CASE " +
                            "WHEN a.text11 IS NULL OR LTRIM(RTRIM(a.text11)) = '' THEN 'SPZZUNKNOWN' " +
                            "WHEN LEFT(LTRIM(a.text11),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text11),3,500)) " +
                            "ELSE 'SP' + LTRIM(a.text11) END, " +
                        "a.lastobservedlocation = CASE " +
                            "WHEN a.lastobservedlocation IS NULL OR LTRIM(RTRIM(a.lastobservedlocation)) = '' THEN 'SPZZUNKNOWN' " +
                            "WHEN LEFT(LTRIM(a.lastobservedlocation),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.lastobservedlocation),3,500)) " +
                            "ELSE 'SP' + LTRIM(a.lastobservedlocation) END " +
                    "FROM dbo.asset a " +
                    "WHERE (a.text6 IS NULL OR LEFT(LTRIM(a.text6),2) <> 'SP' OR LTRIM(a.text6) LIKE 'SP %') " +
                       "OR (a.text11 IS NULL OR LEFT(LTRIM(a.text11),2) <> 'SP' OR LTRIM(a.text11) LIKE 'SP %') " +
                       "OR (a.lastobservedlocation IS NULL OR LEFT(LTRIM(a.lastobservedlocation),2) <> 'SP' " +
                           "OR LTRIM(a.lastobservedlocation) LIKE 'SP %')",

                    // Ensure SPZZUNKNOWN location exists in dbo.location for all companies
                    @"IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'location')
                      BEGIN
                          INSERT INTO dbo.location (name, companyid)
                          SELECT 'SPZZUNKNOWN', c.id
                          FROM dbo.company c
                          WHERE NOT EXISTS (
                              SELECT 1 FROM dbo.location l WHERE l.name = 'SPZZUNKNOWN' AND l.companyid = c.id
                          );
                      END",

                    // Normalize all locations in dbo.location to start with 'SP' and link asset locationid
                    @"IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'location')
                      BEGIN
                          UPDATE dbo.location
                          SET name = 'SP' + name
                          WHERE name NOT LIKE 'SP%'
                            AND name IS NOT NULL
                            AND LTRIM(RTRIM(name)) <> '';

                          UPDATE a
                          SET a.locationid = l.id
                          FROM dbo.asset a
                          INNER JOIN dbo.location l ON l.name = a.lastobservedlocation AND l.companyid = a.companyid
                          WHERE (a.locationid IS NULL OR a.locationid <> l.id)
                            AND a.lastobservedlocation IS NOT NULL;
                      END",

                    // Seed listvalue1 dropdown options
                    "IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'IN USE') " +
                        "INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'IN USE', 0)",
                    "IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'LOST OR STOLEN') " +
                        "INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'LOST OR STOLEN', 1)",
                    "IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'LOANED OUT') " +
                        "INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'LOANED OUT', 2)",
                    "IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'TURNED IN') " +
                        "INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'TURNED IN', 3)",
                    "IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'OUT OF SERVICE') " +
                        "INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'OUT OF SERVICE', 4)",

                    // Fix nameless company
                    "UPDATE dbo.company SET name = 'Company' " +
                    "WHERE (name IS NULL OR LTRIM(RTRIM(name)) = '') " +
                      "AND NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = 'Company')"
                };

                int normOk = 0, normFail = 0;
                foreach (string patch in dataNormPatches)
                {
                    try { ExecuteSql(conn, patch); normOk++; }
                    catch (Exception normEx) { normFail++; Log("  Norm warning: " + normEx.Message, "warn"); }
                }
                Log(string.Format("Data normalization complete — {0} patches applied, {1} warnings.", normOk, normFail),
                    normFail == 0 ? "success" : "warn");
            }
            catch (Exception ex)
            {
                Log("Normalization error: " + ex.Message, "warn");
            }
        }

        private void ExecuteSql(SqlConnection conn, string sql)
        {
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 300; // 5 minutes for restore
                cmd.ExecuteNonQuery();
            }
        }

        private void Log(string msg, string type)
        {
            string colorClass = "log-info";
            if (type == "error") colorClass = "log-error";
            else if (type == "success") colorClass = "log-success";
            else if (type == "warn") colorClass = "log-warn";

            string entry = string.Format("<div class='{0}'>[{1}] {2}</div>", 
                colorClass, DateTime.Now.ToString("HH:mm:ss"), Server.HtmlEncode(msg));
            
            _log.AppendLine(entry);
            LitLog.Text = _log.ToString();
        }
    }
}
