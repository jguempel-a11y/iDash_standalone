using System;
using System.IO;
using System.Text;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Collections.Generic;
using System.Web.UI.WebControls;

public partial class va_autodbupdate : System.Web.UI.Page
{
    // ---------------------------------------------------------
    // DEFAULT PATHS (no expression-bodied members!)
    // ---------------------------------------------------------
    private string DefaultWatchFolder
    {
        get { return @"C:\VA_RFID\va_dbupdate\autoload"; }
    }

    private string DefaultSqlScriptPath
    {
        get { return @"C:\VA_RFID\va_dbupdate\data\va_dbupdate.sql"; }
    }

    // ---------------------------------------------------------
    // PAGE LOAD
    // ---------------------------------------------------------
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            TxtFolder.Text  = DefaultWatchFolder;
            TxtSqlPath.Text = DefaultSqlScriptPath;
            LitLastRun.Text = "Not run yet in this session.";
            LoadSqlContent();

            // ?auto=1 — scheduled task silent processing endpoint
            string auto = Request["auto"];
            if (auto != null && auto.ToLower() == "1")
            {
                string detail;
                bool ok = RunAutoDbUpdate(out detail);
                Response.Clear();
                Response.ContentType = "text/plain";
                Response.Write(ok ? "STATUS: OK\r\n" : "STATUS: ERROR\r\n");
                Response.Write(detail);
                Response.End();
                return;
            }

            // ?view=logs — jump straight to Log Viewer tab (used by index.aspx tile)
            string view = Request["view"];
            if (view != null && view.ToLower() == "logs")
            {
                ShowTab("logs");
            }
            else
            {
                ShowTab("logs"); // default to log viewer
            }
        }
    }

    // ---------------------------------------------------------
    // TAB SWITCHING
    // ---------------------------------------------------------
    private void ShowTab(string tab)
    {
        bool isLogs = (tab == "logs");
        PnlLogViewer.Visible = isLogs;
        PnlDbUpdate.Visible  = !isLogs;
        BtnTabLogView.CssClass  = isLogs  ? "tab-btn tab-active" : "tab-btn";
        BtnTabDbUpdate.CssClass = !isLogs ? "tab-btn tab-active" : "tab-btn";
    }

    protected void BtnTabLogs_Click(object sender, EventArgs e)
    {
        ShowTab("logs");
    }

    protected void BtnTabDbUpdate_Click(object sender, EventArgs e)
    {
        ShowTab("db");
    }

    // ---------------------------------------------------------
    // RUN BUTTON CLICK
    // ---------------------------------------------------------
    protected void BtnRun_Click(object sender, EventArgs e)
    {
        ShowTab("db"); // switch to DB tab when running
        string detail;
        bool ok = RunAutoDbUpdate(out detail);
        string css = ok ? "ok" : "err";
        LitStatus.Text = "<div class='" + css + "'><div class='status'>" + Server.HtmlEncode(detail) + "</div></div>";
        LitStatusOutput2.Text = "<div class='logbox'>" + Server.HtmlEncode(detail) + "</div>";
        LitLastRun.Text = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
    }

    // ---------------------------------------------------------
    // SQL EDITOR
    // ---------------------------------------------------------
    private void LoadSqlContent()
    {
        LitSqlStatus.Text = "";
        string path = TxtSqlPath != null && TxtSqlPath.Text.Trim() != "" ? TxtSqlPath.Text.Trim() : DefaultSqlScriptPath;
        try
        {
            if (File.Exists(path))
            {
                TxtSqlEditor.Text = File.ReadAllText(path);
            }
            else
            {
                TxtSqlEditor.Text = "-- SQL file not found at " + path;
            }
        }
        catch (Exception ex)
        {
            LitSqlStatus.Text = "<div class='err'>Error loading SQL: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnLoadSql_Click(object sender, EventArgs e)
    {
        LoadSqlContent();
        LitSqlStatus.Text = "<div class='ok' style='padding:8px; margin-bottom:10px;'>Loaded directly from disk successfully.</div>";
    }

    protected void BtnSaveSql_Click(object sender, EventArgs e)
    {
        string path = TxtSqlPath != null && TxtSqlPath.Text.Trim() != "" ? TxtSqlPath.Text.Trim() : DefaultSqlScriptPath;
        try
        {
            File.WriteAllText(path, TxtSqlEditor.Text);
            LitSqlStatus.Text = "<div class='ok' style='padding:8px; margin-bottom:10px;'>Saved directly to disk successfully!</div>";
        }
        catch (Exception ex)
        {
            LitSqlStatus.Text = "<div class='err'>Error saving SQL: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ---------------------------------------------------------
    // MAIN UPDATE FUNCTION
    // ---------------------------------------------------------
    private bool RunAutoDbUpdate(out string detail)
    {
        StringBuilder sb = new StringBuilder();
        bool success = true;

        string folder = TxtFolder != null ? TxtFolder.Text.Trim() : "";
        if (folder == "")
            folder = DefaultWatchFolder;

        string sqlPath = TxtSqlPath != null && TxtSqlPath.Text.Trim() != ""
                         ? TxtSqlPath.Text.Trim()
                         : DefaultSqlScriptPath;

        sb.AppendLine("=== VA Auto DB Update ===");
        sb.AppendLine("Timestamp: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        sb.AppendLine("Watch folder: " + folder);
        sb.AppendLine("SQL script:   " + sqlPath);
        sb.AppendLine();

        if (!Directory.Exists(folder))
        {
            sb.AppendLine("ERROR: Watch folder does not exist.");
            detail = sb.ToString();
            success = false;
            SafeAppendLog(folder, detail);
            AlertingService.SendAdminSms("AWX ALARM: DB Update watch folder missing (" + folder + ")", "Alert_DbFolderMissing");
            return success;
        }

        // -----------------------------------------------------
        // FIND FILES
        // -----------------------------------------------------
        List<string> filesToProcess = new List<string>();

        string txtPath = Path.Combine(folder, "data.txt");
        string xlsxPath = Path.Combine(folder, "data.xlsx");
        
        string[] bakFiles = Directory.GetFiles(folder, "*.bak");

        // Prioritize processing the full DB Backup if a .bak was uploaded
        if (bakFiles.Length > 0) 
        {
            filesToProcess.Add(bakFiles[0]);
        }
        else 
        {
            if (File.Exists(txtPath)) filesToProcess.Add(txtPath);
            if (File.Exists(xlsxPath)) filesToProcess.Add(xlsxPath);
        }

        if (filesToProcess.Count == 0)
        {
            sb.AppendLine("No data.txt or data.xlsx found. Nothing to do.");
            detail = sb.ToString();
            SafeAppendLog(folder, detail);
            return true;
        }

        sb.AppendLine("Files detected:");
        foreach (string f in filesToProcess)
            sb.AppendLine("  - " + f);
        sb.AppendLine();

        string primaryDataFile = filesToProcess[0];
        sb.AppendLine("Primary data file for {{DATAFILE}}: " + primaryDataFile);
        sb.AppendLine();

        // -----------------------------------------------------
        // RUN SQL
        // -----------------------------------------------------
        try
        {
            sb.AppendLine("Running SQL script...");
            string sqlMsg;
            
            // If the primary file is a backup, securely route it to the specific .BAK merge script
            string activeSqlScript = sqlPath;
            if (Path.GetExtension(primaryDataFile).ToLower() == ".bak")
            {
                activeSqlScript = Path.Combine(Path.GetDirectoryName(sqlPath), "va_bak_merge.sql");
                sb.AppendLine("Detected .BAK database - Rerouting execution to va_bak_merge.sql for secure merge...");
            }
            
            int batchCount = ExecuteSqlScript(activeSqlScript, primaryDataFile, out sqlMsg);
            sb.AppendLine(sqlMsg);
            sb.AppendLine("SQL script complete. Batches executed: " + batchCount);
            sb.AppendLine();

            // -----------------------------------------------------
            // MOVE FILES INTO /loaded
            // -----------------------------------------------------
            foreach (string file in filesToProcess)
            {
                string loadedFolder = Path.Combine(folder, "loaded");
                Directory.CreateDirectory(loadedFolder);

                string baseName = Path.GetFileNameWithoutExtension(file);
                string ext = Path.GetExtension(file);
                string newName = baseName + "_" +
                                 DateTime.Now.ToString("yyyyMMdd_HHmmss") +
                                 ext;

                string dest = Path.Combine(loadedFolder, newName);
                File.Move(file, dest);

                sb.AppendLine("Moved file:");
                sb.AppendLine("  From: " + file);
                sb.AppendLine("  To:   " + dest);
                sb.AppendLine();
            }
        }
        catch (Exception ex)
        {
            success = false;
            sb.AppendLine("ERROR during processing:");
            sb.AppendLine(ex.Message);
            if (ex.InnerException != null)
                sb.AppendLine("Inner: " + ex.InnerException.Message);
            
            AlertingService.SendAdminSms("AWX CRITICAL ALARM: Auto DB Update failed. " + ex.Message, "Alert_DbCrash");
        }

        detail = sb.ToString();
        SafeAppendLog(folder, detail);
        return success;
    }

    // ---------------------------------------------------------
    // EXECUTE SQL SCRIPT WITH GO SPLITTING
    // ---------------------------------------------------------
   private int ExecuteSqlScript(string path, string dataFilePath, out string message)
{
    if (!File.Exists(path))
        throw new FileNotFoundException("SQL script not found.", path);

    string sqlText = File.ReadAllText(path);
    var allLines = sqlText.Replace("\r", "").Split('\n');

    var sbCmd = new StringBuilder();
    var commands = new List<string>();

    // Split into GO batches
    foreach (string raw in allLines)
    {
        string trimmed = raw.Trim();

        if (trimmed.StartsWith("--"))
            continue;

        if (string.Equals(trimmed, "GO", StringComparison.OrdinalIgnoreCase))
        {
            if (sbCmd.Length > 0)
            {
                commands.Add(sbCmd.ToString());
                sbCmd.Clear();
            }
        }
        else
        {
            sbCmd.AppendLine(raw);
        }
    }

    if (sbCmd.Length > 0)
        commands.Add(sbCmd.ToString());

    string connStr = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

    int batchCount = 0;
    int totalAffected = 0;
    string finalStats = "";

    using (var conn = new SqlConnection(connStr))
    {
        conn.Open();

        foreach (string rawCmd in commands)
        {
            string sql = rawCmd;

            // Replace {{DATAFILE}}
            if (!string.IsNullOrEmpty(dataFilePath))
                sql = sql.Replace("{{DATAFILE}}", dataFilePath);

            if (string.IsNullOrWhiteSpace(sql))
                continue;

            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 0;

                bool isSelect =
                    sql.TrimStart().StartsWith("SELECT", StringComparison.OrdinalIgnoreCase);

                if (isSelect)
                {
                    // CAPTURE FINAL STATS TABLE
                    using (var reader = cmd.ExecuteReader())
                    {
                        var sb = new StringBuilder();
                        sb.AppendLine("=== Import Stats ===");

                        while (reader.Read())
                        {
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                sb.Append(reader.GetName(i));
                                sb.Append(": ");
                                sb.Append(reader.IsDBNull(i) ? "(null)" : reader[i].ToString());
                                sb.Append("   ");
                            }
                            sb.AppendLine();
                        }

                        finalStats = sb.ToString();
                    }
                }
                else
                {
                    int affected = cmd.ExecuteNonQuery();
                    if (affected > 0)
                        totalAffected += affected;
                }
            }

            batchCount++;
        }
    }

    // Build final message (UI + LOG)
    var m = new StringBuilder();
    m.AppendLine("Executed " + batchCount + " SQL batch(es). Total rows affected (where reported): " + totalAffected + ".");
    m.AppendLine();

    if (!string.IsNullOrEmpty(finalStats))
        m.AppendLine(finalStats);

    message = m.ToString();
    return batchCount;
}

    // ---------------------------------------------------------
    // SAFE LOG APPEND
    // ---------------------------------------------------------
    private void SafeAppendLog(string folder, string content)
    {
        try
        {
            if (folder == null || folder.Trim() == "")
                folder = DefaultWatchFolder;

            Directory.CreateDirectory(folder);

            string logPath = Path.Combine(folder, "va_autodbupdate.log");

            string entry =
                "===== " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " =====\r\n" +
                content + "\r\n\r\n";

            File.AppendAllText(logPath, entry);
        }
        catch
        {
            // swallow
        }
    }

    // ---------------------------------------------------------
    // VIEW LOG
    // ---------------------------------------------------------
    // ---------------------------------------------------------
    // FIELD SYNC LOG VIEWER
    // ---------------------------------------------------------
    private static readonly string FieldSyncLogFile = @"C:\VA_RFID\va_sync\va_field_sync.log";

    protected void BtnViewFieldSyncLog_Click(object sender, EventArgs e)
    {
        ShowTab("logs");
        if (!File.Exists(FieldSyncLogFile))
        {
            LitFieldSyncOutput.Text = "<div class='logbox' style='color:var(--muted);'>" +
                "No Field Sync log file found at: " + Server.HtmlEncode(FieldSyncLogFile) +
                "<br/>The Field Server Sync has not run yet, or the log file path is different.</div>";
            return;
        }
        try
        {
            string[] all = File.ReadAllLines(FieldSyncLogFile);
            int take = Math.Min(all.Length, 120);
            string[] tail = new string[take];
            Array.Copy(all, all.Length - take, tail, 0, take);
            LitFieldSyncOutput.Text = "<div class='logbox'>" + Server.HtmlEncode(string.Join("\n", tail)) + "</div>";
        }
        catch (Exception ex)
        {
            LitFieldSyncOutput.Text = "<div class='logbox' style='color:var(--danger);'>Error reading log: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected void BtnClearFieldSyncLog_Click(object sender, EventArgs e)
    {
        ShowTab("logs");
        try
        {
            string entry = "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "] Log cleared manually via iDash System Logs.\r\n";
            File.WriteAllText(FieldSyncLogFile, entry);
            LitFieldSyncOutput.Text = "<div class='ok'>Field Sync log cleared successfully.</div>" +
                "<div class='logbox'>" + Server.HtmlEncode(entry.Trim()) + "</div>";
        }
        catch (Exception ex)
        {
            LitFieldSyncOutput.Text = "<div class='err'>Could not clear log: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ---------------------------------------------------------
    // DB UPDATE LOG VIEWER
    // ---------------------------------------------------------
    protected void BtnViewLog_Click(object sender, EventArgs e)
    {
        string folder = TxtFolder != null ? TxtFolder.Text.Trim() : "";
        if (folder == "") folder = DefaultWatchFolder;

        string logPath = Path.Combine(folder, "va_autodbupdate.log");

        ShowTab("logs");
        if (!File.Exists(logPath))
        {
            LitStatusOutput.Text =
                "<div class='logbox' style='color:var(--muted);'>No DB Update log file found at: " +
                Server.HtmlEncode(logPath) + "<br/>No updates have been processed yet, or the watch folder path is different.</div>";
            return;
        }

        try
        {
            string content = File.ReadAllText(logPath);

            string[] blocks = content.Split(new string[] { "=====" },
                                            StringSplitOptions.RemoveEmptyEntries);

            List<string> cleanBlocks = new List<string>();
            foreach (string b in blocks)
            {
                string t = b.Trim();
                if (t != "")
                    cleanBlocks.Add("===== " + t);
            }

            if (cleanBlocks.Count == 0)
            {
                LitStatusOutput.Text = "<div class='logbox'>Log file is empty.</div>";
                return;
            }

            int take = cleanBlocks.Count < 10 ? cleanBlocks.Count : 10;

            StringBuilder sb = new StringBuilder();
            for (int i = cleanBlocks.Count - 1; i >= cleanBlocks.Count - take; i--)
            {
                if (sb.Length > 0)
                {
                    sb.AppendLine();
                    sb.AppendLine("------------------------------------------------------------");
                    sb.AppendLine();
                }

                sb.AppendLine(cleanBlocks[i]);
            }

            LitStatusOutput.Text =
                "<div class='logbox'>" + Server.HtmlEncode(sb.ToString()) + "</div>";
        }
        catch (Exception ex)
        {
            LitStatusOutput.Text =
                "<div class='logbox'>Error reading log file:<br />" +
                Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ---------------------------------------------------------
    // CLEAR LOG
    // ---------------------------------------------------------
    protected void BtnClearLog_Click(object sender, EventArgs e)
    {
        ShowTab("logs");
        string folder = TxtFolder != null ? TxtFolder.Text.Trim() : "";
        if (folder == "") folder = DefaultWatchFolder;

        string logPath = Path.Combine(folder, "va_autodbupdate.log");

        try
        {
            Directory.CreateDirectory(folder);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("===== " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " =====");
            sb.AppendLine("Log file cleared manually.");
            sb.AppendLine();

            File.WriteAllText(logPath, sb.ToString());

            LitStatus.Text =
                "<div class='ok'><div class='status'>Log file cleared.</div></div>";

            LitStatusOutput.Text =
                "<div class='logbox'>" + Server.HtmlEncode(sb.ToString()) + "</div>";
        }
        catch (Exception ex)
        {
            LitStatus.Text =
                "<div class='err'><div class='status'>Failed to clear log file: " +
                Server.HtmlEncode(ex.Message) + "</div></div>";
        }
    }
}
