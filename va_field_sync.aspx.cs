using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Web.UI;

public partial class va_field_sync : Page
{
    private static readonly string WatchFolder  = @"C:\VA_RFID\va_sync\incoming";
    private static readonly string ProcessedFolder = @"C:\VA_RFID\va_sync\processed";
    private static readonly string LogFile      = @"C:\VA_RFID\va_sync\va_field_sync.log";
    private static readonly string StagingDb    = "idash_staging";

    // ===================== Connection to master (for RESTORE commands) =====================
    private string MasterConnStr()
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
        var b  = new SqlConnectionStringBuilder(cs);
        b.InitialCatalog = "master";
        b.ConnectTimeout = 10;
        return b.ConnectionString;
    }

    // ============================ Long-timeout connection to iDash ============================
    private string AppConnStr(int timeout)
    {
        var cs = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
        var b  = new SqlConnectionStringBuilder(cs);
        b.ConnectTimeout = timeout;
        return b.ConnectionString;
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        EnsureFolders();
        if (!IsPostBack)
        {
            RefreshStatus();
            CheckScheduledTask();

            // Auto-process: if ?auto=1, run full sync automatically
            if (Request.QueryString["auto"] == "1" && GetBakFiles().Count > 0)
            {
                AppendLog("=== AUTO-SYNC TRIGGERED (scheduled task) ===");
                BtnFullSync_Click(sender, e);
            }
        }
    }

    // =================================== Refresh all status indicators ===================================
    private void RefreshStatus()
    {
        LitWatchFolder.Text = WatchFolder;

        // Staging DB status
        bool stagingExists = StagingDbExists();
        LitStagingStatus.Text = stagingExists ? "&#9679; Ready" : "&#9679; Missing";

        // BAK files in queue
        var baks = GetBakFiles();
        LitBakCount.Text = baks.Count.ToString();

        // Last sync time from log
        string lastLine = ReadLastLogLine();
        LitLastSyncTime.Text = string.IsNullOrEmpty(lastLine) ? "Never" : "See log";
        LitLastResult.Text   = string.IsNullOrEmpty(lastLine) ? "--"    : "OK";

        // Render BAK file list
        var sb = new StringBuilder();
        if (baks.Count == 0)
        {
            sb.Append("<div style=\"color:var(--muted); font-size:13px; font-style:italic;\">No .bak files found in watch folder.</div>");
        }
        else
        {
            foreach (var f in baks)
            {
                var fi = new FileInfo(f);
                sb.Append("<div class=\"file-row\">");
                sb.Append("<span class=\"fname\">&#128196; " + fi.Name + "</span>");
                sb.Append("<span class=\"fdate\">" + fi.LastWriteTime.ToString("yyyy-MM-dd HH:mm") + "</span>");
                sb.Append("<span style=\"color:#10b981; font-size:12px;\">" + FormatBytes(fi.Length) + "</span>");
                sb.Append("</div>");
            }
        }
        LitBakFiles.Text = sb.ToString();

        // Default staging paths
        if (!IsPostBack)
        {
            TxtStagingMdf.Text = @"C:\VA_RFID\va_sync\staging_db\idash_staging.mdf";
            TxtStagingLdf.Text = @"C:\VA_RFID\va_sync\staging_db\idash_staging_log.ldf";
        }

        // Load log tail
        LitLog.Text = ReadLogTail(60);
    }

    // ===================================== FULL SYNC (Restore + Merge) =====================================
    protected void BtnFullSync_Click(object sender, EventArgs e)
    {
        ClearMessages();
        string bakPath = ResolveBakPath();
        if (bakPath == null) { ShowErr("No .bak file found. Place a .bak in " + WatchFolder + " or enter a path manually."); return; }

        AppendLog("=== FULL SYNC STARTED: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        AppendLog("BAK file: " + bakPath);

        string restoreErr = DoRestore(bakPath);
        if (restoreErr != null) { ShowErr("Restore failed: " + restoreErr); AppendLog("RESTORE ERROR: " + restoreErr); RefreshStatus(); return; }

        AppendLog("Restore complete. Starting merge...");
        int locs, updated, inserted, errors;
        string mergeErr = DoMerge(out locs, out updated, out inserted, out errors);
        if (mergeErr != null) { ShowErr("Merge failed: " + mergeErr); AppendLog("MERGE ERROR: " + mergeErr); RefreshStatus(); return; }

        AppendLog("Merge complete. Locations: " + locs + " | Updated: " + updated + " | Inserted: " + inserted + " | Errors: " + errors);
        AppendLog("=== FULL SYNC COMPLETE: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");

        MoveToProcessed(bakPath);
        ShowResults(locs, updated, inserted, errors);
        ShowOk("Full sync completed successfully. " + updated + " assets updated, " + inserted + " inserted.");
        RefreshStatus();
    }

    // ==================================================== RESTORE ONLY ====================================================
    protected void BtnRestoreOnly_Click(object sender, EventArgs e)
    {
        ClearMessages();
        string bakPath = ResolveBakPath();
        if (bakPath == null) { ShowErr("No .bak file found."); return; }

        AppendLog("=== RESTORE ONLY: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        AppendLog("BAK: " + bakPath);

        string err = DoRestore(bakPath);
        if (err != null) { ShowErr("Restore failed: " + err); AppendLog("ERROR: " + err); }
        else             { ShowOk("Restore to idash_staging completed. Run Merge to apply changes."); AppendLog("Restore OK."); }

        RefreshStatus();
    }

    // ====================================================== MERGE ONLY ======================================================
    protected void BtnMergeOnly_Click(object sender, EventArgs e)
    {
        ClearMessages();
        if (!StagingDbExists()) { ShowErr("idash_staging does not exist. Run Restore first."); return; }

        AppendLog("=== MERGE ONLY: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        int locs, updated, inserted, errors;
        string err = DoMerge(out locs, out updated, out inserted, out errors);
        if (err != null) { ShowErr("Merge failed: " + err); AppendLog("ERROR: " + err); }
        else             { ShowResults(locs, updated, inserted, errors); ShowOk("Merge complete."); AppendLog("Merge OK. Locs:" + locs + " Upd:" + updated + " Ins:" + inserted + " Err:" + errors); }

        RefreshStatus();
    }

    protected void BtnCopyToWatch_Click(object sender, EventArgs e)
    {
        ClearMessages();
        string srcPath = TxtBakPath.Text.Trim().Trim('"', '\'');
        if (string.IsNullOrWhiteSpace(srcPath))
        {
            ShowErr("Enter a path to a .bak file first.");
            return;
        }

        try
        {
            string destPath = Path.Combine(WatchFolder, Path.GetFileName(srcPath));
            if (!Directory.Exists(WatchFolder)) Directory.CreateDirectory(WatchFolder);

            File.Copy(srcPath, destPath, true);
            AppendLog("Copied BAK from '" + srcPath + "' to '" + destPath + "'");
            TxtBakPath.Text = destPath;
            ShowOk("File copied successfully to <code>" + destPath + "</code>. It's now ready for sync.");
        }
        catch (Exception ex)
        {
            string hint = "";
            if (srcPath.Contains("OneDrive"))
                hint = "<br/>OneDrive paths are often not accessible to IIS. Try copying the file manually using File Explorer.";
            else if (srcPath.StartsWith(@"\\"))
                hint = "<br/>Network paths require that the IIS app pool identity has read access to the share.";

            ShowErr("Cannot copy file: " + Server.HtmlEncode(ex.Message) + hint +
                "<br/><strong>Workaround:</strong> Copy the .bak file into <code>" + WatchFolder + "</code> using File Explorer.");
        }
        RefreshStatus();
    }

    protected void BtnRefresh_Click(object sender, EventArgs e) { RefreshStatus(); }

    // ==================================== PREVIEW (dry run, no writes) ====================================
    protected void BtnPreview_Click(object sender, EventArgs e)
    {
        ClearMessages();
        if (!StagingDbExists())
        {
            LitPreview.Text = "<div class=\"msg-err\">&#9888; idash_staging does not exist. Run Restore BAK Only first, then Preview.</div>";
            return;
        }

        AppendLog("=== PREVIEW RUN: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        int locsNew, assetsUpd, assetsIns, errors;
        string err = DoPreview(out locsNew, out assetsUpd, out assetsIns, out errors);
        if (err != null)
        {
            LitPreview.Text = "<div class=\"msg-err\">&#9888; Preview error: " + Server.HtmlEncode(err) + "</div>";
            AppendLog("PREVIEW ERROR: " + err);
            return;
        }

        AppendLog("Preview: Locs=" + locsNew + " Upd=" + assetsUpd + " Ins=" + assetsIns + " Err=" + errors);

        string commitWarning = (assetsUpd + assetsIns) > 0
            ? "<div style=\"margin-top:12px; padding:10px 14px; background:rgba(16,185,129,0.08); border:1px solid #10b981; border-radius:8px; font-size:13px; color:#d1fae5;\">" +
              "&#9989; Review the counts above. If they look correct, click <strong>Full Sync (Restore + Merge)</strong> in the Commit section to apply these changes.</div>"
            : "<div style=\"margin-top:12px; padding:10px 14px; background:rgba(46,168,255,0.08); border:1px solid #2ea8ff; border-radius:8px; font-size:13px; color:#bde0ff;\">" +
              "&#8505; No changes detected. The central database is already up-to-date with the staged data.</div>";

        LitPreview.Text =
            "<div class=\"stat-grid\">" +
            "<div class=\"stat\"><div class=\"stat-val green\">" + locsNew    + "</div><div class=\"stat-lbl\">Locations to Add</div></div>" +
            "<div class=\"stat\"><div class=\"stat-val\">"       + assetsUpd  + "</div><div class=\"stat-lbl\">Assets to Update</div></div>" +
            "<div class=\"stat\"><div class=\"stat-val green\">" + assetsIns  + "</div><div class=\"stat-lbl\">Assets to Insert</div></div>" +
            "<div class=\"stat\"><div class=\"stat-val " + (errors > 0 ? "red" : "green") + "\">" + errors + "</div><div class=\"stat-lbl\">Errors</div></div>" +
            "</div>" + commitWarning;
    }

    protected void BtnClearLog_Click(object sender, EventArgs e)
    {
        try { File.WriteAllText(LogFile, "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "] Log cleared.\r\n"); }
        catch { }
        RefreshStatus();
    }

    // =================================================== SCHEDULE TASK ===================================================
    private static readonly string TaskName = "iDash Field Sync Auto-Process";

    private void CheckScheduledTask()
    {
        try
        {
            var psi = new ProcessStartInfo("schtasks", "/query /tn \"" + TaskName + "\"")
            { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
            var p = Process.Start(psi);
            string output = p.StandardOutput.ReadToEnd();
            p.WaitForExit(5000);
            if (p.ExitCode == 0 && output.Contains(TaskName))
            {
                LitTaskStatus.Text = "<span style='color:#10b981; font-weight:700;'>&#9679; Scheduled</span>";
                return;
            }
        }
        catch { }

        // Fallback: check if script file exists (task may exist but IIS can't query it)
        if (File.Exists(@"C:\VA_RFID\va_sync\run_field_sync.ps1"))
            LitTaskStatus.Text = "<span style='color:#10b981; font-weight:700;'>&#9679; Script Ready</span> <span style='font-size:11px; color:var(--muted);'>(verify in Task Scheduler)</span>";
        else
            LitTaskStatus.Text = "<span style='color:#f59e0b; font-weight:700;'>&#9679; Not Configured</span>";
    }

    protected void BtnCreateTask_Click(object sender, EventArgs e)
    {
        try
        {
            string time = TxtScheduleTime.Text.Trim();
            if (string.IsNullOrEmpty(time)) time = "18:15";

            // Dynamically resolve baseUrl from App_BaseUrl or Request URL
            string baseUrl = ConfigurationManager.AppSettings["App_BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                string vpath = Request.ApplicationPath != null && Request.ApplicationPath != "/" ? Request.ApplicationPath.TrimEnd('/') : "";
                baseUrl = Request.Url.GetLeftPart(UriPartial.Authority) + vpath;
            }
            string url = baseUrl.TrimEnd('/') + "/va_field_sync.aspx?auto=1";

            string scriptDir = @"C:\VA_RFID\va_sync";
            if (!Directory.Exists(scriptDir)) Directory.CreateDirectory(scriptDir);
            string scriptPath = Path.Combine(scriptDir, "run_field_sync.ps1");

            var scriptSb = new StringBuilder();
            scriptSb.AppendLine("# Auto-generated by iDash Field Sync scheduler");
            scriptSb.AppendLine("# Last updated: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            scriptSb.AppendLine("$ErrorActionPreference = 'Stop'");
            scriptSb.AppendLine("$logFile = 'C:\\VA_RFID\\va_sync\\autosync_error.log'");
            scriptSb.AppendLine("try {");
            scriptSb.AppendLine("    $result = Invoke-WebRequest -Uri '" + url + "' -UseBasicParsing -TimeoutSec 900");
            scriptSb.AppendLine("    \"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] OK: Status $($result.StatusCode)\" | Out-File $logFile -Append");
            scriptSb.AppendLine("} catch {");
            scriptSb.AppendLine("    \"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $_\" | Out-File $logFile -Append");
            scriptSb.AppendLine("}");
            File.WriteAllText(scriptPath, scriptSb.ToString(), Encoding.UTF8);

            // Build the schtasks command
    // == /ru SYSTEM   runs as LocalSystem, so it fires even when no user is logged in. ==
    // ============= /rl HIGHEST  run with highest available privileges. =============
            string schtasksCmd = "schtasks /create /tn \"" + TaskName + "\" /tr \"powershell.exe -NoProfile -ExecutionPolicy Bypass -File " + scriptPath + "\" /sc daily /st " + time + " /ru SYSTEM /rl HIGHEST /f";

            // Try to create the task directly from IIS (works if app pool has admin rights)
            string directResult = null;
            try
            {
                var psi = new ProcessStartInfo("schtasks", "/create /tn \"" + TaskName + "\" /tr \"powershell.exe -NoProfile -ExecutionPolicy Bypass -File " + scriptPath + "\" /sc daily /st " + time + " /ru SYSTEM /rl HIGHEST /f")
                { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
                var p = Process.Start(psi);
                string stdout = p.StandardOutput.ReadToEnd();
                string stderr = p.StandardError.ReadToEnd();
                p.WaitForExit(10000);
                if (p.ExitCode == 0)
                {
                    directResult = "SUCCESS";
                    AppendLog("Scheduled task created/updated directly: " + TaskName + " at " + time + " as SYSTEM");
                }
                else
                {
                    directResult = "FAILED: " + (stderr.Length > 0 ? stderr : stdout);
                    AppendLog("Direct schtasks failed: " + directResult);
                }
            }
            catch (Exception ex2) { directResult = "EXCEPTION: " + ex2.Message; }

            // Also write the setup batch as a fallback
            string setupPath = Path.Combine(scriptDir, "setup_field_sync_task.cmd");
            File.WriteAllText(setupPath, "@echo off\r\necho Creating scheduled task (runs as SYSTEM, no login required): " + TaskName + "\r\necho Must be run from an elevated (Administrator) Command Prompt.\r\n" + schtasksCmd + "\r\necho.\r\npause\r\n", Encoding.ASCII);

            AppendLog("Wrote sync script: " + scriptPath);
            AppendLog("Wrote setup batch: " + setupPath);

            if (directResult == "SUCCESS")
            {
                ShowOk("Scheduled task created successfully as <strong>SYSTEM</strong> at <strong>" + time + "</strong> daily." +
                    "<br/>Script: <code>" + Server.HtmlEncode(scriptPath) + "</code>" +
                    "<br/>The task will call <code>va_field_sync.aspx?auto=1</code> via HTTP loopback.");
            }
            else
            {
                ShowOk("Automation files created. <span style='color:var(--sm-amber);'>Could not register task directly</span> (IIS may lack admin rights)." +
                    "<br/><strong>Run this from an elevated Command Prompt:</strong>" +
                    "<code style=\"display:block; margin-top:8px; padding:10px; background:#0b1220; border:1px solid var(--line); border-radius:6px; word-break:break-all;\">" +
                    Server.HtmlEncode(schtasksCmd) + "</code>" +
                    "<br/>Or double-click as Administrator: <code>" + Server.HtmlEncode(setupPath) + "</code>");
            }
        }
        catch (Exception ex) { ShowErr("Error: " + ex.Message); }
        RefreshStatus();
        CheckScheduledTask();
    }

    protected void BtnDeleteTask_Click(object sender, EventArgs e)
    {
        try
        {
            var psi = new ProcessStartInfo("schtasks", "/delete /tn \"" + TaskName + "\" /f")
            { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
            var p = Process.Start(psi);
            p.WaitForExit(5000);
            ShowOk("Scheduled task removed.");
            AppendLog("Scheduled task deleted: " + TaskName);
        }
        catch (Exception ex) { ShowErr("Could not remove task: " + ex.Message); }
        RefreshStatus();
        CheckScheduledTask();
    }

    protected void BtnRunNow_Click(object sender, EventArgs e)
    {
        try
        {
            var psi = new ProcessStartInfo("schtasks", "/run /tn \"" + TaskName + "\"")
            { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
            var p = Process.Start(psi);
            p.WaitForExit(5000);
            if (p.ExitCode == 0)
            {
                ShowOk("Scheduled task triggered. Processing will run in the background.");
                AppendLog("Manual trigger of scheduled task.");
            }
            else
            {
                ShowErr("Could not trigger task. It may not be scheduled yet.");
            }
        }
        catch (Exception ex) { ShowErr("Run error: " + ex.Message); }
        RefreshStatus();
    }

    // =================================================== RESTORE LOGIC ===================================================
    private string DoRestore(string bakPath)
    {
        try
        {
            string mdfPath = TxtStagingMdf.Text.Trim();
            string ldfPath = TxtStagingLdf.Text.Trim();
            if (string.IsNullOrEmpty(mdfPath)) mdfPath = @"C:\VA_RFID\va_sync\staging_db\idash_staging.mdf";
            if (string.IsNullOrEmpty(ldfPath)) ldfPath = @"C:\VA_RFID\va_sync\staging_db\idash_staging_log.ldf";

            // Ensure staging dir exists
            string dir = Path.GetDirectoryName(mdfPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            // Get logical file names from .bak
            string dataLogical = "idash";
            string logLogical  = "idash_log";
            string fileListSql = "RESTORE FILELISTONLY FROM DISK = '" + bakPath.Replace("'","''") + "'";

            using (var conn = new SqlConnection(MasterConnStr()))
            {
                conn.Open();
                using (var cmd = new SqlCommand(fileListSql, conn))
                {
                    cmd.CommandTimeout = 120;
                    using (var dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            string logName  = dr["LogicalName"].ToString();
                            string fileType = dr["Type"].ToString().ToUpper();
                            if (fileType == "D") dataLogical = logName;
                            if (fileType == "L") logLogical  = logName;
                        }
                    }
                }

                // Set staging to single user if it exists
                if (StagingDbExistsOnConn(conn))
                {
                    var suCmd = new SqlCommand("ALTER DATABASE [" + StagingDb + "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE", conn);
                    suCmd.CommandTimeout = 30;
                    try { suCmd.ExecuteNonQuery(); } catch { }
                }

                // Build and run RESTORE command
                string restoreSql =
                    "RESTORE DATABASE [" + StagingDb + "] FROM DISK = '" + bakPath.Replace("'","''") + "' " +
                    "WITH MOVE '" + dataLogical + "' TO '" + mdfPath + "', " +
                    "MOVE '" + logLogical + "' TO '" + ldfPath + "', " +
                    "REPLACE, NOUNLOAD, RECOVERY, STATS = 10";

                using (var cmd = new SqlCommand(restoreSql, conn))
                {
                    cmd.CommandTimeout = 600; // 10 min for large databases
                    cmd.ExecuteNonQuery();
                }
            }
            return null; // success
        }
        catch (Exception ex) { return ex.Message; }
    }

    // ===================================================== MERGE LOGIC =====================================================
    private string DoMerge(out int locs, out int updated, out int inserted, out int errors)
    {
        locs = updated = inserted = errors = 0;
        return RunSyncSql(false, out locs, out updated, out inserted, out errors);
    }

    // ========================== PREVIEW LOGIC (SELECT only, no writes) ==========================
    private string DoPreview(out int locs, out int updated, out int inserted, out int errors)
    {
        locs = updated = inserted = errors = 0;
        return RunSyncSql(true, out locs, out updated, out inserted, out errors);
    }

    // ====================================== SHARED SYNC/PREVIEW RUNNER ======================================
    private string RunSyncSql(bool previewOnly, out int locs, out int updated, out int inserted, out int errors)
    {
        locs = updated = inserted = errors = 0;
        try
        {
            if (!StagingDbExists()) return "idash_staging database not found.";

            // Preview uses SELECT COUNT(*) queries; merge uses the full SQL file
            if (previewOnly)
            {
                // Company-mapping CTE used in all queries
                string companyCte =
                    "WITH CompanyMap AS ( " +
                    "  SELECT mc.id AS central_id, sc.id AS staging_id " +
                    "  FROM dbo.company mc " +
                    "  JOIN idash_staging.dbo.company sc " +
                    "    ON SUBSTRING(mc.name,1,3) = SUBSTRING(sc.name,1,3) " +
                    ") ";

                string previewSql =
                    "USE [idash]; " +
                    companyCte +
                    // Locations that would be inserted
                    "SELECT COUNT(*) FROM idash_staging.dbo.location s " +
                    "JOIN CompanyMap cm ON s.companyid = cm.staging_id " +
                    "WHERE NOT EXISTS (SELECT 1 FROM dbo.location l " +
                    "  WHERE l.name = s.name AND l.companyid = cm.central_id)";

                // Compare all the tagging-relevant fields, not just lastmodified
                // The field server does NOT update lastmodified, so we must compare actual data
                string updateSql =
                    "USE [idash]; " +
                    companyCte +
                    "SELECT COUNT(*) FROM dbo.asset m " +
                    "JOIN idash_staging.dbo.asset s ON m.name = s.name " +
                    "JOIN CompanyMap cm ON m.companyid = cm.central_id AND s.companyid = cm.staging_id " +
                    "WHERE " +
                    // Tag status fields
                    "  COALESCE(m.text6,'')  <> COALESCE(s.text6,'') " +
                    "  OR COALESCE(m.text7,'')  <> COALESCE(s.text7,'') " +
                    "  OR COALESCE(m.text8,'')  <> COALESCE(s.text8,'') " +
                    "  OR COALESCE(m.text13,'') <> COALESCE(s.text13,'') " +
                    "  OR COALESCE(m.text16,'') <> COALESCE(s.text16,'') " +
                    "  OR COALESCE(m.text17,'') <> COALESCE(s.text17,'') " +
                    "  OR COALESCE(m.text18,'') <> COALESCE(s.text18,'') " +
                    "  OR COALESCE(m.text19,'') <> COALESCE(s.text19,'') " +
                    "  OR COALESCE(m.text20,'') <> COALESCE(s.text20,'') " +
                    // Core asset data
                    "  OR COALESCE(m.description,'') <> COALESCE(s.description,'') " +
                    "  OR COALESCE(m.rfidtag,'') <> COALESCE(s.rfidtag,'') " +
                    "  OR COALESCE(m.listvalue1,'') <> COALESCE(s.listvalue1,'') " +
                    // Timestamp-based changes (if they do exist)
                    "  OR (s.lastinventoried IS NOT NULL AND (m.lastinventoried IS NULL OR s.lastinventoried > m.lastinventoried)) " +
                    "  OR (s.lastmodified IS NOT NULL AND m.lastmodified IS NOT NULL AND s.lastmodified > m.lastmodified)";

                string insertSql =
                    "USE [idash]; " +
                    companyCte +
                    "SELECT COUNT(*) FROM idash_staging.dbo.asset s " +
                    "JOIN CompanyMap cm ON s.companyid = cm.staging_id " +
                    "WHERE NOT EXISTS (SELECT 1 FROM dbo.asset m " +
                    "  WHERE m.name = s.name AND m.companyid = cm.central_id) " +
                    "AND (NULLIF(RTRIM(s.rfidtag),'') IS NULL OR NOT EXISTS (" +
                    "  SELECT 1 FROM dbo.asset m WHERE m.rfidtag = s.rfidtag))";

                using (var conn = new SqlConnection(AppConnStr(120)))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(previewSql, conn)) { cmd.CommandTimeout = 120; locs    = (int)cmd.ExecuteScalar(); }
                    using (var cmd = new SqlCommand(updateSql,  conn)) { cmd.CommandTimeout = 120; updated  = (int)cmd.ExecuteScalar(); }
                    using (var cmd = new SqlCommand(insertSql,  conn)) { cmd.CommandTimeout = 120; inserted = (int)cmd.ExecuteScalar(); }
                }
                return null;
            }

    // ==================================== Full merge  run the SQL file ====================================
            string sqlPath = Server.MapPath("~/va_field_sync_merge.sql");
            if (!File.Exists(sqlPath)) return "va_field_sync_merge.sql not found in iDash root.";

            string fullSql = File.ReadAllText(sqlPath, Encoding.UTF8);
            var batches    = new List<string>();
            var lines      = fullSql.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            var batch      = new StringBuilder();
            foreach (var line in lines)
            {
                if (line.Trim().Equals("GO", StringComparison.OrdinalIgnoreCase))
                { if (batch.Length > 0) { batches.Add(batch.ToString()); batch.Clear(); } }
                else { batch.AppendLine(line); }
            }
            if (batch.Length > 0) batches.Add(batch.ToString());

            using (var conn = new SqlConnection(AppConnStr(600)))
            {
                conn.Open();
                DataTable resultTable = null;
                foreach (var b in batches)
                {
                    if (string.IsNullOrWhiteSpace(b)) continue;
                    using (var cmd = new SqlCommand(b, conn))
                    {
                        cmd.CommandTimeout = 600;
                        using (var adapter = new SqlDataAdapter(cmd))
                        {
                            var ds = new DataSet();
                            adapter.Fill(ds);
                            if (ds.Tables.Count > 0 && ds.Tables[0].Columns.Contains("AssetsUpdated"))
                                resultTable = ds.Tables[0];
                        }
                    }
                }
                if (resultTable != null && resultTable.Rows.Count > 0)
                {
                    var row  = resultTable.Rows[0];
                    locs     = Convert.ToInt32(row["LocationsInserted"]);
                    updated  = Convert.ToInt32(row["AssetsUpdated"]);
                    inserted = Convert.ToInt32(row["AssetsInserted"]);
                    errors   = Convert.ToInt32(row["Errors"]);
                }
            }
            return null;
        }
        catch (Exception ex) { return ex.Message; }
    }

    // ====================================================== UI HELPERS ======================================================
    private void ShowOk(string msg)
    {
        LitMsg.Text = "<div class=\"msg-ok\">&#9989; " + msg + "</div>";
    }
    private void ShowErr(string msg)
    {
        LitMsg.Text = "<div class=\"msg-err\">&#9888; " + msg + "</div>";
    }

    private void ClearMessages()
    {
        LitMsg.Text     = "";
        LitPreview.Text = "<div style=\"color:var(--muted); font-size:13px; font-style:italic;\">Run Preview (Dry Run) to see what would change before committing.</div>";
        LitResults.Text = "<div style=\"color:var(--muted); font-size:13px; font-style:italic;\">No sync has been run this session.</div>";
    }

    private void ShowResults(int locs, int updated, int inserted, int errors)
    {
        LitResults.Text =
            "<div class=\"stat-grid\">" +
            "<div class=\"stat\"><div class=\"stat-val green\">" + locs     + "</div><div class=\"stat-lbl\">Locations Added</div></div>" +
            "<div class=\"stat\"><div class=\"stat-val\">"       + updated  + "</div><div class=\"stat-lbl\">Assets Updated</div></div>" +
            "<div class=\"stat\"><div class=\"stat-val green\">" + inserted + "</div><div class=\"stat-lbl\">Assets Inserted</div></div>" +
            "<div class=\"stat\"><div class=\"stat-val " + (errors > 0 ? "red" : "green") + "\">" + errors + "</div><div class=\"stat-lbl\">Errors</div></div>" +
            "</div>";
    }

    // ========================================================= UTILITY =========================================================
    private string ResolveBakPath()
    {
        // Manual path takes priority
        string manualPath = TxtBakPath.Text.Trim();
        if (!string.IsNullOrWhiteSpace(manualPath))
        {
            // Clean up path: remove surrounding quotes if present
            manualPath = manualPath.Trim('"', '\'');

            // First, try the file directly
            if (File.Exists(manualPath))
                return manualPath;

            // If the file doesn't exist or IIS can't access it, try to copy it to the watch folder
            // This handles OneDrive, network shares, and user-profile paths that IIS_IUSRS can't read
            try
            {
                string destPath = Path.Combine(WatchFolder, Path.GetFileName(manualPath));
                if (File.Exists(destPath))
                    return destPath; // Already copied

                File.Copy(manualPath, destPath, true);
                AppendLog("Copied manual BAK from '" + manualPath + "' to watch folder.");
                return destPath;
            }
            catch (Exception ex)
            {
                // Show a helpful error message about the specific path issue
                string hint = "";
                if (manualPath.Contains("OneDrive"))
                    hint = " The file is in OneDrive  --  try copying it to " + WatchFolder + " manually, or use a local path.";
                else if (manualPath.StartsWith(@"\\") || manualPath.Contains("$"))
                    hint = " Network/UNC paths may not be accessible to the IIS worker process. Copy the file to " + WatchFolder + " first.";

                ShowErr("Cannot access manual BAK path: " + manualPath + "<br/>" +
                    "<small>Error: " + Server.HtmlEncode(ex.Message) + hint + "</small><br/>" +
                    "<strong>Tip:</strong> Copy the .bak file into <code>" + WatchFolder + "</code> and it will be detected automatically.");
                return null;
            }
        }

        // Otherwise latest file in watch folder
        var baks = GetBakFiles();
        return baks.Count > 0 ? baks[0] : null;
    }

    private List<string> GetBakFiles()
    {
        var list = new List<string>();
        if (!Directory.Exists(WatchFolder)) return list;
        var files = Directory.GetFiles(WatchFolder, "*.bak");
        Array.Sort(files, (a, b2) => File.GetLastWriteTime(b2).CompareTo(File.GetLastWriteTime(a)));
        list.AddRange(files);
        return list;
    }

    private bool StagingDbExists()
    {
        try
        {
            using (var conn = new SqlConnection(MasterConnStr()))
            {
                conn.Open();
                return StagingDbExistsOnConn(conn);
            }
        }
        catch { return false; }
    }

    private bool StagingDbExistsOnConn(SqlConnection conn)
    {
        using (var cmd = new SqlCommand("SELECT DB_ID('" + StagingDb + "')", conn))
        {
            var result = cmd.ExecuteScalar();
            return result != null && result != DBNull.Value;
        }
    }

    private void MoveToProcessed(string bakPath)
    {
        try
        {
            if (!Directory.Exists(ProcessedFolder)) Directory.CreateDirectory(ProcessedFolder);
            string dest = Path.Combine(ProcessedFolder, Path.GetFileNameWithoutExtension(bakPath) + "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".bak");
            File.Move(bakPath, dest);
        }
        catch { }
    }

    private void EnsureFolders()
    {
        try
        {
            if (!Directory.Exists(WatchFolder)) Directory.CreateDirectory(WatchFolder);
            if (!Directory.Exists(ProcessedFolder)) Directory.CreateDirectory(ProcessedFolder);
        }
        catch { }
    }

    private void AppendLog(string msg)
    {
        try
        {
            File.AppendAllText(LogFile, "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "] " + msg + "\r\n");
        }
        catch { }
    }

    private string ReadLogTail(int lines)
    {
        try
        {
            if (!File.Exists(LogFile)) return "(no log yet)";
            var all  = File.ReadAllLines(LogFile);
            int skip = Math.Max(0, all.Length - lines);
            return string.Join("\n", all, skip, all.Length - skip);
        }
        catch { return "(could not read log)"; }
    }

    private string ReadLastLogLine()
    {
        try
        {
            if (!File.Exists(LogFile)) return null;
            var all = File.ReadAllLines(LogFile);
            for (int i = all.Length - 1; i >= 0; i--)
                if (!string.IsNullOrWhiteSpace(all[i])) return all[i];
            return null;
        }
        catch { return null; }
    }

    private string FormatBytes(long bytes)
    {
        if (bytes > 1073741824) return (bytes / 1073741824.0).ToString("0.0") + " GB";
        if (bytes > 1048576)    return (bytes / 1048576.0).ToString("0.0") + " MB";
        return (bytes / 1024.0).ToString("0.0") + " KB";
    }
}
