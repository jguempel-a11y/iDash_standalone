using System;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Threading;
using System.Collections.Generic;

public partial class va_system_update : Page
{
    // In-memory state shared across the app domain
    private static readonly object _lock = new object();
    private static UpdateProgress _currentProgress = new UpdateProgress();

    public class UpdateProgress
    {
        public bool IsRunning { get; set; }
        public string Stage { get; set; }
        public int Percent { get; set; }
        public long BytesDownloaded { get; set; }
        public long TotalBytes { get; set; }
        public int FilesCopied { get; set; }
        public int TotalFiles { get; set; }
        public string CurrentFile { get; set; }
        public string Message { get; set; }
        public string Error { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }

        public UpdateProgress()
        {
            IsRunning = false;
            Stage = "idle";
            Percent = 0;
            BytesDownloaded = 0;
            TotalBytes = 0;
            FilesCopied = 0;
            TotalFiles = 0;
            CurrentFile = "";
            Message = "";
            Error = "";
            StartTime = DateTime.MinValue;
            EndTime = DateTime.MinValue;
        }

        public string ToJson()
        {
            var sb = new StringBuilder();
            sb.Append("{");
            sb.AppendFormat("\"isRunning\":{0},", IsRunning ? "true" : "false");
            sb.AppendFormat("\"stage\":\"{0}\",", EscapeJson(Stage));
            sb.AppendFormat("\"percent\":{0},", Percent);
            sb.AppendFormat("\"bytesDownloaded\":{0},", BytesDownloaded);
            sb.AppendFormat("\"totalBytes\":{0},", TotalBytes);
            sb.AppendFormat("\"filesCopied\":{0},", FilesCopied);
            sb.AppendFormat("\"totalFiles\":{0},", TotalFiles);
            sb.AppendFormat("\"currentFile\":\"{0}\",", EscapeJson(CurrentFile));
            sb.AppendFormat("\"message\":\"{0}\",", EscapeJson(Message));
            sb.AppendFormat("\"error\":\"{0}\",", EscapeJson(Error));
            long elapsed = StartTime > DateTime.MinValue ? (long)(DateTime.Now - StartTime).TotalSeconds : 0;
            sb.AppendFormat("\"elapsedSeconds\":{0}", elapsed);
            sb.Append("}");
            return sb.ToString();
        }

        private static string EscapeJson(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", " ");
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // Enforce Administrator Access
        string role = Convert.ToString(Session["IdashUserRole"]) ?? "";
        bool isAdminAuth = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        var tiles = Session["IdashTileAccess"] as List<string>;

        bool hasAccess = isAdminAuth ||
                         role.Equals("admin", StringComparison.OrdinalIgnoreCase) ||
                         role.Equals("superadmin", StringComparison.OrdinalIgnoreCase) ||
                         UserManager.CanAccessTile(role, tiles, "admin_system_update");

        // Handle AJAX status request
        string action = Request.QueryString["action"];
        if (!string.IsNullOrEmpty(action))
        {
            Response.Clear();
            Response.ContentType = "application/json; charset=utf-8";
            Response.Cache.SetCacheability(HttpCacheability.NoCache);

            if (!hasAccess)
            {
                Response.StatusCode = 403;
                Response.Write("{\"error\":\"Authentication required\"}");
                Response.End();
                return;
            }

            if (action.Equals("status", StringComparison.OrdinalIgnoreCase))
            {
                HandleStatusAction();
                return;
            }
            else if (action.Equals("start", StringComparison.OrdinalIgnoreCase))
            {
                HandleStartAction();
                return;
            }
        }

        if (!hasAccess)
        {
            Response.Redirect("index.aspx?err=auth");
            return;
        }

        if (!IsPostBack)
        {
            if (string.IsNullOrWhiteSpace(TxtMasterUrl.Text))
            {
                TxtMasterUrl.Text = "https://lingcod.tail585c9b.ts.net/iDash/downloads/idash_full_site.zip";
            }
        }
    }

    // =========================================================================
    // AJAX ACTIONS
    // =========================================================================
    private void HandleStatusAction()
    {
        string json = "";
        lock (_lock)
        {
            if (_currentProgress.IsRunning || _currentProgress.Stage != "idle")
            {
                json = _currentProgress.ToJson();
            }
        }

        // If not in memory, check scratch/update_status.json
        if (string.IsNullOrEmpty(json))
        {
            string statusFile = Server.MapPath("~/scratch/update_status.json");
            if (File.Exists(statusFile))
            {
                try
                {
                    json = File.ReadAllText(statusFile);
                }
                catch { }
            }
        }

        if (string.IsNullOrEmpty(json))
        {
            json = "{\"isRunning\":false,\"stage\":\"idle\",\"percent\":0,\"bytesDownloaded\":0,\"totalBytes\":0,\"filesCopied\":0,\"totalFiles\":0,\"currentFile\":\"\",\"message\":\"\",\"error\":\"\",\"elapsedSeconds\":0}";
        }

        Response.Write(json);
        Response.End();
    }

    private void HandleStartAction()
    {
        string url = Request.Form["url"];
        if (string.IsNullOrWhiteSpace(url))
        {
            url = Request.QueryString["url"];
        }

        if (string.IsNullOrWhiteSpace(url))
        {
            Response.Write("{\"ok\":false,\"error\":\"No update package URL provided.\"}");
            Response.End();
            return;
        }

        lock (_lock)
        {
            if (_currentProgress.IsRunning)
            {
                Response.Write("{\"ok\":false,\"error\":\"An update is already in progress.\"}");
                Response.End();
                return;
            }

            _currentProgress = new UpdateProgress
            {
                IsRunning = true,
                Stage = "downloading",
                Percent = 5,
                StartTime = DateTime.Now,
                Message = "Starting update download from " + url
            };
            SaveStatusToFile(_currentProgress);
        }

        // Capture server paths before launching background thread
        string appRoot = Server.MapPath("~/");
        string currentDir = Server.MapPath(".");
        string scratchDir = Server.MapPath("~/scratch");

        ThreadPool.QueueUserWorkItem(state =>
        {
            ExecuteBackgroundUpdate(url, appRoot, currentDir, scratchDir);
        });

        Response.Write("{\"ok\":true,\"message\":\"Update task started.\"}");
        Response.End();
    }

    private void SaveStatusToFile(UpdateProgress prog)
    {
        try
        {
            string scratchDir = Server.MapPath("~/scratch");
            if (!Directory.Exists(scratchDir))
                Directory.CreateDirectory(scratchDir);

            string file = Path.Combine(scratchDir, "update_status.json");
            File.WriteAllText(file, prog.ToJson());
        }
        catch { }
    }

    private static void SaveStatusToPath(UpdateProgress prog, string scratchDir)
    {
        try
        {
            if (!Directory.Exists(scratchDir))
                Directory.CreateDirectory(scratchDir);

            string file = Path.Combine(scratchDir, "update_status.json");
            File.WriteAllText(file, prog.ToJson());
        }
        catch { }
    }

    // =========================================================================
    // ASYNC BACKGROUND UPDATE PIPELINE
    // =========================================================================
    private static void ExecuteBackgroundUpdate(string url, string appRoot, string currentDir, string scratchDir)
    {
        string tempDir = Path.Combine(scratchDir, "ota_update_" + DateTime.Now.Ticks);
        string zipPath = Path.Combine(tempDir, "idash_update.zip");

        try
        {
            if (!Directory.Exists(tempDir))
                Directory.CreateDirectory(tempDir);

            // Step 1: Download with live progress
            lock (_lock)
            {
                _currentProgress.Stage = "downloading";
                _currentProgress.Percent = 10;
                _currentProgress.Message = "Connecting to master repository...";
            }
            SaveStatusToPath(_currentProgress, scratchDir);

            ServicePointManager.ServerCertificateValidationCallback = (srvPoint, cert, chain, errors) => true;
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            var req = (HttpWebRequest)WebRequest.Create(url);
            req.Timeout = 300000; // 5 minutes
            req.UserAgent = "iDash-SystemUpdate/2.1";

            using (var resp = req.GetResponse())
            {
                long totalBytes = resp.ContentLength;
                lock (_lock)
                {
                    _currentProgress.TotalBytes = totalBytes;
                    _currentProgress.BytesDownloaded = 0;
                    _currentProgress.Message = "Downloading update package (" + FormatBytes(totalBytes) + ")...";
                }
                SaveStatusToPath(_currentProgress, scratchDir);

                using (var src = resp.GetResponseStream())
                using (var dst = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None, 65536))
                {
                    byte[] buffer = new byte[65536];
                    int read;
                    long downloaded = 0;
                    DateTime lastSave = DateTime.Now;

                    while ((read = src.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        dst.Write(buffer, 0, read);
                        downloaded += read;

                        int pct = 10;
                        if (totalBytes > 0)
                        {
                            pct = 10 + (int)((downloaded * 40) / totalBytes); // 10% to 50%
                        }

                        lock (_lock)
                        {
                            _currentProgress.BytesDownloaded = downloaded;
                            _currentProgress.Percent = pct;
                            _currentProgress.Message = string.Format("Downloading: {0} / {1} ({2}%)",
                                FormatBytes(downloaded), FormatBytes(totalBytes), pct);
                        }

                        if ((DateTime.Now - lastSave).TotalMilliseconds > 500)
                        {
                            SaveStatusToPath(_currentProgress, scratchDir);
                            lastSave = DateTime.Now;
                        }
                    }
                }
            }

            if (!File.Exists(zipPath) || new FileInfo(zipPath).Length < 1000)
            {
                throw new Exception("Downloaded archive is missing or corrupted (size < 1KB).");
            }

            // Step 2: Extracting
            lock (_lock)
            {
                _currentProgress.Stage = "extracting";
                _currentProgress.Percent = 55;
                _currentProgress.Message = "Verifying and unpacking update archive...";
            }
            SaveStatusToPath(_currentProgress, scratchDir);

            string extractDir = Path.Combine(tempDir, "extracted");
            ExtractZipSafe(zipPath, extractDir);

            // Step 3: Copying files safe boundary
            lock (_lock)
            {
                _currentProgress.Stage = "copying";
                _currentProgress.Percent = 65;
                _currentProgress.Message = "Scanning application files for deployment...";
            }
            SaveStatusToPath(_currentProgress, scratchDir);

            // Scan total eligible files
            var eligibleFiles = new List<string>();
            ScanEligibleFiles(extractDir, extractDir, eligibleFiles);

            int totalFiles = eligibleFiles.Count;
            int copied = 0;

            lock (_lock)
            {
                _currentProgress.TotalFiles = totalFiles;
                _currentProgress.FilesCopied = 0;
            }

            DateTime lastFileSave = DateTime.Now;
            foreach (string relPath in eligibleFiles)
            {
                string srcFile = Path.Combine(extractDir, relPath);
                string dstFile = Path.Combine(currentDir, relPath);

                string dstDir = Path.GetDirectoryName(dstFile);
                if (!Directory.Exists(dstDir))
                    Directory.CreateDirectory(dstDir);

                File.Copy(srcFile, dstFile, true);
                copied++;

                int pct = 65;
                if (totalFiles > 0)
                {
                    pct = 65 + (int)((copied * 30.0) / totalFiles); // 65% to 95%
                }

                lock (_lock)
                {
                    _currentProgress.FilesCopied = copied;
                    _currentProgress.CurrentFile = relPath;
                    _currentProgress.Percent = pct;
                    _currentProgress.Message = string.Format("Deploying: {0} ({1} of {2})", Path.GetFileName(relPath), copied, totalFiles);
                }

                if ((DateTime.Now - lastFileSave).TotalMilliseconds > 300)
                {
                    SaveStatusToPath(_currentProgress, scratchDir);
                    lastFileSave = DateTime.Now;
                }
            }

            // Also synchronize root if currentDir is subdirectory
            if (!string.Equals(currentDir.TrimEnd('\\'), appRoot.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase))
            {
                foreach (string relPath in eligibleFiles)
                {
                    string srcFile = Path.Combine(extractDir, relPath);
                    string dstFile = Path.Combine(appRoot, relPath);
                    string dstDir = Path.GetDirectoryName(dstFile);
                    if (!Directory.Exists(dstDir))
                        Directory.CreateDirectory(dstDir);
                    File.Copy(srcFile, dstFile, true);
                }
            }

            // Step 4: Finalize & AppPool recycle
            lock (_lock)
            {
                _currentProgress.Stage = "recycling";
                _currentProgress.Percent = 98;
                _currentProgress.Message = "Restarting IIS Application Pool to load updated assemblies...";
            }
            SaveStatusToPath(_currentProgress, scratchDir);

            // Touch web.config to trigger IIS AppPool Recycle
            try
            {
                string webConfigPath = Path.Combine(currentDir, "web.config");
                if (File.Exists(webConfigPath))
                {
                    File.SetLastWriteTime(webConfigPath, DateTime.Now);
                }
            }
            catch { }

            Thread.Sleep(1000); // Allow brief settling

            lock (_lock)
            {
                _currentProgress.IsRunning = false;
                _currentProgress.Stage = "complete";
                _currentProgress.Percent = 100;
                _currentProgress.EndTime = DateTime.Now;
                _currentProgress.Message = string.Format("System Update Complete! Successfully updated {0} files. Database credentials and settings preserved.", copied);
            }
            SaveStatusToPath(_currentProgress, scratchDir);
        }
        catch (Exception ex)
        {
            lock (_lock)
            {
                _currentProgress.IsRunning = false;
                _currentProgress.Stage = "error";
                _currentProgress.Error = ex.Message;
                _currentProgress.EndTime = DateTime.Now;
                _currentProgress.Message = "Update aborted: " + ex.Message;
            }
            SaveStatusToPath(_currentProgress, scratchDir);
        }
        finally
        {
            try
            {
                if (Directory.Exists(tempDir))
                    Directory.Delete(tempDir, true);
            }
            catch { }
        }
    }

    private static void ScanEligibleFiles(string root, string current, List<string> list)
    {
        foreach (string file in Directory.GetFiles(current))
        {
            string fileName = Path.GetFileName(file);
            if (string.Equals(fileName, "web.config", StringComparison.OrdinalIgnoreCase) ||
                fileName.EndsWith(".log", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            string rel = file.Substring(root.Length).TrimStart('\\', '/');
            list.Add(rel);
        }

        foreach (string dir in Directory.GetDirectories(current))
        {
            string dirName = Path.GetFileName(dir);
            if (string.Equals(dirName, "App_Data", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(dirName, "logs", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(dirName, "uploads", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(dirName, "downloads", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(dirName, "scratch", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            ScanEligibleFiles(root, dir, list);
        }
    }

    private static void ExtractZipSafe(string zipPath, string extractDir)
    {
        if (Directory.Exists(extractDir))
            Directory.Delete(extractDir, true);
        Directory.CreateDirectory(extractDir);

        bool extracted = false;
        try
        {
            var asm = System.Reflection.Assembly.Load("System.IO.Compression.FileSystem, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089");
            if (asm != null)
            {
                var zipType = asm.GetType("System.IO.Compression.ZipFile");
                if (zipType != null)
                {
                    var m = zipType.GetMethod("ExtractToDirectory", new Type[] { typeof(string), typeof(string) });
                    if (m != null)
                    {
                        m.Invoke(null, new object[] { zipPath, extractDir });
                        extracted = true;
                    }
                }
            }
        }
        catch { }

        if (!extracted)
        {
            var psi = new System.Diagnostics.ProcessStartInfo("powershell.exe",
                string.Format("-NoProfile -ExecutionPolicy Bypass -Command \"Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('{0}', '{1}')\"",
                zipPath.Replace("'", "''"), extractDir.Replace("'", "''")))
            {
                CreateNoWindow = true,
                UseShellExecute = false
            };
            using (var proc = System.Diagnostics.Process.Start(psi))
            {
                proc.WaitForExit();
            }
        }
    }

    private static string FormatBytes(long bytes)
    {
        if (bytes <= 0) return "0 MB";
        double mb = bytes / (1024.0 * 1024.0);
        return mb.ToString("F1") + " MB";
    }

    // =========================================================================
    // OPTION 2: LOCAL ZIP UPLOAD (FALLBACK)
    // =========================================================================
    protected void BtnUpload_Click(object sender, EventArgs e)
    {
        LitMsg.Text = "";
        if (!FileUp.HasFile)
        {
            ShowErr("Please select a ZIP file to upload.");
            return;
        }

        if (Path.GetExtension(FileUp.FileName).ToLower() != ".zip")
        {
            ShowErr("Invalid file type. Only .zip files are allowed.");
            return;
        }

        string tempDir = Server.MapPath("~/scratch/zip_update_" + DateTime.Now.Ticks + "/");
        string zipPath = Path.Combine(tempDir, "uploaded_update.zip");

        try
        {
            if (!Directory.Exists(tempDir))
                Directory.CreateDirectory(tempDir);

            FileUp.SaveAs(zipPath);

            string extractDir = Path.Combine(tempDir, "extracted");
            ExtractZipSafe(zipPath, extractDir);

            var eligible = new List<string>();
            ScanEligibleFiles(extractDir, extractDir, eligible);

            string currentDir = Server.MapPath(".");
            int copied = 0;
            foreach (string rel in eligible)
            {
                string src = Path.Combine(extractDir, rel);
                string dst = Path.Combine(currentDir, rel);
                string dir = Path.GetDirectoryName(dst);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.Copy(src, dst, true);
                copied++;
            }

            try
            {
                string webConfigPath = Path.Combine(currentDir, "web.config");
                if (File.Exists(webConfigPath))
                    File.SetLastWriteTime(webConfigPath, DateTime.Now);
            }
            catch { }

            ShowOk(string.Format("Update Applied Successfully! Synchronized {0} files. Database credentials (web.config) preserved.", copied));
        }
        catch (Exception ex)
        {
            ShowErr("Update failed: " + ex.Message);
        }
        finally
        {
            try
            {
                if (Directory.Exists(tempDir))
                    Directory.Delete(tempDir, true);
            }
            catch { }
        }
    }

    private void ShowOk(string msg)
    {
        LitMsg.Text = "<div class=\"msg-ok\">&#9989; " + msg + "</div>";
    }

    private void ShowErr(string msg)
    {
        LitMsg.Text = "<div class=\"msg-err\">&#10060; " + msg + "</div>";
    }

    // =========================================================================
    // OPTION 3: TAILSCALE DEPLOY SCRIPT GENERATOR
    // =========================================================================
    protected void BtnDownloadScript_Click(object sender, EventArgs e)
    {
        string srcDir = TxtSourceDir.Text.Trim();
        string tgtDir = TxtTargetDir.Text.Trim();

        string template = @"# iDash Tailscale Deployment Script
$sourcePath = ""{0}""
$endpoints = @(""{1}"")
Write-Host ""Starting iDash Deployment..."" -ForegroundColor Cyan
foreach ($target in $endpoints) {{
    Write-Host ""Deploying to $target..."" -ForegroundColor Yellow
    robocopy $sourcePath $target /E /FFT /Z /XA:H /W:5 /R:1 /XD ""logs"" ""scratch"" ""App_Data"" ""Assets"" ""fonts"" /XF ""web.config"" ""*.log""
    Write-Host ""Finished deploying to $target`n"" -ForegroundColor Green
}}
Write-Host ""Deployment complete!"" -ForegroundColor Cyan
";
        string scriptContent = string.Format(template, srcDir, tgtDir);
        Response.Clear();
        Response.ContentType = "application/octet-stream";
        Response.AddHeader("Content-Disposition", "attachment; filename=deploy_idash.ps1");
        Response.Write(scriptContent);
        Response.End();
    }
}
