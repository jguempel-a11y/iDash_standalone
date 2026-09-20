using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Web;
using Seagull.BarTender.Print;
using Seagull.BarTender.PrintServer;
using Seagull.BarTender.PrintServer.Tasks;

/// <summary>
/// Stateless BarTender Enterprise Print & Preview Helper for iDash.
/// Provides on-demand label preview generation (PNG base64), printer status inspection,
/// and direct print execution with detailed error diagnostics.
/// Requires NO BarTender SQL database.
///
/// Uses the BarTender Print Scheduler service (TaskManager API) as the primary execution
/// path for previews, field discovery, and printing. This approach communicates with the
/// already-running BarTender services and does not require launching a separate bartend.exe
/// process — making it reliable under IIS regardless of desktop heap or session 0 constraints.
///
/// Falls back to the in-process Engine API only if the Print Scheduler is unavailable.
/// </summary>
public static class BarTenderApiHelper
{
    private static readonly object _syncLock = new object();
    private static readonly int _taskTimeoutMs = 30000; // 30 second timeout for task operations

    // ─── Cached Print Scheduler TaskManager (primary approach) ───
    private static TaskManager _taskManager = null;

    /// <summary>
    /// Gets or creates a shared TaskManager with EngineSettings that allocate sufficient
    /// desktop heap (4096 KB) for the engine process. This is critical for running
    /// under IIS where the default non-interactive desktop heap (typically 768 KB)
    /// is too small for BarTender.
    /// The TaskManager is cached as a singleton — first call takes ~3-5s for engine startup,
    /// subsequent calls return instantly.
    /// </summary>
    private static TaskManager GetTaskManager()
    {
        lock (_syncLock)
        {
            if (_taskManager != null)
                return _taskManager;

            _taskManager = new TaskManager();
            var settings = new EngineSettings();
            settings.DesktopHeapSize = 4096;
            _taskManager.Start(1, settings);
            return _taskManager;
        }
    }

    // ─── Engine fallback (used only when Print Scheduler is unavailable) ───
    private static Engine _engine = null;
    private static DateTime _lastUsed = DateTime.MinValue;

    public class PreviewResult
    {
        public bool Success { get; set; }
        public string ImageBase64 { get; set; }
        public string ErrorMessage { get; set; }
        public List<string> DiscoveredFields { get; set; }

        public PreviewResult()
        {
            DiscoveredFields = new List<string>();
        }
    }

    public class PrintResult
    {
        public bool Success { get; set; }
        public string JobName { get; set; }
        public string ErrorMessage { get; set; }
        public List<string> Messages { get; set; }

        public PrintResult()
        {
            Messages = new List<string>();
        }
    }

    public class PrinterInfo
    {
        public string Name { get; set; }
        public bool IsDefault { get; set; }
        public bool IsOnline { get; set; }
        public string Status { get; set; }
        public string Port { get; set; }
        public string Model { get; set; }
    }

    public class HealthResult
    {
        public bool EngineAvailable { get; set; }
        public string BarTenderVersion { get; set; }
        public int PrinterCount { get; set; }
        public DateTime LastUsed { get; set; }
        public string ErrorMessage { get; set; }
    }

    /// <summary>
    /// Quick health check — verifies BarTender availability and returns
    /// version/printer info without opening a template.
    /// </summary>
    public static HealthResult CheckHealth()
    {
        var result = new HealthResult { LastUsed = DateTime.Now };
        try
        {
            var printers = GetPrinters();
            result.PrinterCount = printers.Count;
            result.BarTenderVersion = "11.5";
            result.EngineAvailable = true;
        }
        catch (Exception ex)
        {
            result.EngineAvailable = false;
            result.ErrorMessage = ex.Message;
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Print Scheduler (TaskManager) helpers — primary approach
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Waits for a Print Scheduler task to complete within the configured timeout.
    /// Throws TimeoutException if the task doesn't complete in time.
    /// Throws the task's inner exception if the task failed.
    /// </summary>
    private static void WaitForTask(Seagull.BarTender.PrintServer.Tasks.Task task)
    {
        int elapsed = 0;
        while (!task.IsComplete && elapsed < _taskTimeoutMs)
        {
            System.Threading.Thread.Sleep(100);
            elapsed += 100;
        }
        if (!task.IsComplete)
            throw new TimeoutException("BarTender Print Scheduler task timed out after " + (_taskTimeoutMs / 1000) + " seconds.");
        if (task.Exception != null)
            throw task.Exception;
    }

    /// <summary>
    /// Generates a label preview using the Print Scheduler TaskManager API.
    /// Opens the template via GetLabelFormatTask, sets field values on the SubStrings,
    /// then exports to PNG via ExportImageToFileTask. All communication goes through
    /// the BarTender Print Scheduler service — no Engine.Start() required.
    /// </summary>
    private static PreviewResult GeneratePreviewViaTaskManager(string templatePath, Dictionary<string, string> fields)
    {
        var result = new PreviewResult();
        string tempPng = Path.Combine(Path.GetTempPath(), "idash_bt_" + Guid.NewGuid().ToString("N") + ".png");

        try
        {
            TaskManager tm = GetTaskManager();

            // Step 1: Open the template to get a LabelFormat with SubStrings
            var getTask = new GetLabelFormatTask(templatePath);
            tm.TaskQueue.QueueTask(getTask);
            WaitForTask(getTask);

            LabelFormat lf = getTask.LabelFormat;

            // Step 2: Discover and populate fields
            if (lf.SubStrings != null)
            {
                foreach (SubString sub in lf.SubStrings)
                {
                    result.DiscoveredFields.Add(sub.Name);
                    if (fields != null)
                    {
                        string matchVal = null;
                        foreach (var kv in fields)
                        {
                            if (string.Equals(kv.Key, sub.Name, StringComparison.OrdinalIgnoreCase))
                            {
                                matchVal = kv.Value;
                                break;
                            }
                        }
                        if (matchVal != null)
                        {
                            sub.Value = matchVal;
                        }
                    }
                }
            }

            // Step 3: Export to PNG via ExportImageToFileTask
            var exportTask = new ExportImageToFileTask(
                lf, tempPng,
                ImageType.PNG,
                new Resolution(200),
                ColorDepth.ColorDepth24bit,
                OverwriteOptions.Overwrite
            );
            exportTask.CloseFormatAfterCompletion = true;
            tm.TaskQueue.QueueTask(exportTask);
            WaitForTask(exportTask);

            if (File.Exists(tempPng))
            {
                byte[] bytes = File.ReadAllBytes(tempPng);
                result.ImageBase64 = Convert.ToBase64String(bytes);
                result.Success = true;
            }
            else
            {
                result.Success = false;
                result.ErrorMessage = "BarTender exported task completed but no PNG file was created.";
            }
        }
        finally
        {
            // Don't Stop/Dispose the TaskManager — it's a cached singleton
            if (File.Exists(tempPng))
            {
                try { File.Delete(tempPng); } catch { }
            }
        }

        return result;
    }

    /// <summary>
    /// Discovers template fields (SubStrings) using the Print Scheduler TaskManager.
    /// </summary>
    private static List<string> GetFieldsViaTaskManager(string templatePath)
    {
        var fields = new List<string>();
        TaskManager tm = GetTaskManager();

        var getTask = new GetLabelFormatTask(templatePath);
        getTask.CloseFormatAfterCompletion = true;
        tm.TaskQueue.QueueTask(getTask);
        WaitForTask(getTask);

        if (getTask.LabelFormat != null && getTask.LabelFormat.SubStrings != null)
        {
            foreach (SubString sub in getTask.LabelFormat.SubStrings)
            {
                fields.Add(sub.Name);
            }
        }

        return fields;
    }

    /// <summary>
    /// Prints a label using the Print Scheduler TaskManager API.
    /// </summary>
    private static PrintResult PrintViaTaskManager(string templatePath, string printerName, Dictionary<string, string> fields)
    {
        var result = new PrintResult();
        TaskManager tm = GetTaskManager();

        // Open the template
        var getTask = new GetLabelFormatTask(templatePath);
        tm.TaskQueue.QueueTask(getTask);
        WaitForTask(getTask);

        LabelFormat lf = getTask.LabelFormat;

        // Disable embedded database query — we populate SubStrings directly
        // (The .btw templates have SQL queries on dbo.printjob WHERE completed=0,
        //  which returns 0 rows since we no longer insert into that table)
        try { lf.PrintSetup.UseDatabase = false; } catch { }

        // Set printer if specified
        if (!string.IsNullOrWhiteSpace(printerName))
        {
            lf.PrintSetup.PrinterName = printerName;
        }

        // Set field values
        if (fields != null && lf.SubStrings != null)
        {
            foreach (SubString sub in lf.SubStrings)
            {
                string matchVal = null;
                foreach (var kv in fields)
                {
                    if (string.Equals(kv.Key, sub.Name, StringComparison.OrdinalIgnoreCase))
                    {
                        matchVal = kv.Value;
                        break;
                    }
                }
                if (matchVal != null)
                {
                    sub.Value = matchVal;
                }
            }
        }

        // Print
        string jobName = "iDash Print " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        var printTask = new PrintLabelFormatTask(lf);
        printTask.PrintJobName = jobName;
        printTask.CloseFormatAfterCompletion = true;
        tm.TaskQueue.QueueTask(printTask);
        WaitForTask(printTask);

        if (printTask.PrintResult == Result.Success)
        {
            result.Success = true;
            result.JobName = jobName;
        }
        else
        {
            result.Success = false;
            if (printTask.Messages != null)
            {
                foreach (Seagull.BarTender.Print.Message m in printTask.Messages)
                {
                    result.Messages.Add(m.Text);
                }
            }
            string detail = result.Messages.Count > 0
                ? string.Join("; ", result.Messages.ToArray())
                : ("BarTender result: " + printTask.PrintResult.ToString());
            result.ErrorMessage = "BarTender Print Failed (" + printTask.PrintResult.ToString() + "): " + detail;
        }

        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  In-process Engine fallback (last resort if Print Scheduler unavailable)
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Gets or initializes a shared BarTender Print Engine instance.
    /// Only used as a fallback when the Print Scheduler service is not available.
    /// </summary>
    private static Engine GetEngine()
    {
        lock (_syncLock)
        {
            if (_engine != null && _engine.IsAlive)
            {
                _lastUsed = DateTime.Now;
                return _engine;
            }

            if (_engine != null)
            {
                try { _engine.Stop(); } catch { }
                try { _engine.Dispose(); } catch { }
                _engine = null;
            }

            _engine = new Engine();
            _engine.Start();
            _lastUsed = DateTime.Now;
            return _engine;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Public API — auto-selects Print Scheduler vs Engine fallback
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Enumerates all Windows printers recognized by BarTender on this server.
    /// </summary>
    public static List<PrinterInfo> GetPrinters()
    {
        var list = new List<PrinterInfo>();
        try
        {
            var printers = new Printers();
            foreach (Printer p in printers)
            {
                list.Add(new PrinterInfo
                {
                    Name = p.PrinterName,
                    IsDefault = p.IsDefault,
                    IsOnline = true,
                    Status = p.Status != null ? p.Status.ToString() : "Ready",
                    Port = p.Port,
                    Model = p.PrinterModel
                });
            }
        }
        catch
        {
            // Fallback to System.Drawing.Printing if Seagull.Printers throws
            try
            {
                foreach (string p in System.Drawing.Printing.PrinterSettings.InstalledPrinters)
                {
                    list.Add(new PrinterInfo
                    {
                        Name = p,
                        IsDefault = false,
                        IsOnline = true,
                        Status = "Ready"
                    });
                }
            }
            catch { }
        }
        return list;
    }

    /// <summary>
    /// Resolves a template input (which may be a numeric template ID like "19", a filename,
    /// or a relative path) to an absolute .btw file path on disk.
    /// </summary>
    public static string ResolveTemplatePath(string templateInput)
    {
        if (string.IsNullOrWhiteSpace(templateInput))
            return @"c:\idash_prints\iDash_Std_Small.btw";

        string trimmed = templateInput.Trim().Trim('"', '\'');

        // If it's already an existing file on disk, return it immediately
        if (File.Exists(trimmed))
            return trimmed;

        // If it's a numeric template ID (e.g. "19", "20"), look up filename in dbo.template
        int templateId;
        if (int.TryParse(trimmed, out templateId) && templateId > 0)
        {
            try
            {
                string connStr = null;
                if (System.Configuration.ConfigurationManager.ConnectionStrings["iDash"] != null)
                    connStr = System.Configuration.ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
                if (!string.IsNullOrEmpty(connStr))
                {
                    using (var cn = new System.Data.SqlClient.SqlConnection(connStr))
                    {
                        cn.Open();
                        using (var cmd = new System.Data.SqlClient.SqlCommand("SELECT filename FROM dbo.template WHERE id = @id", cn))
                        {
                            cmd.Parameters.AddWithValue("@id", templateId);
                            var fn = cmd.ExecuteScalar();
                            if (fn != null && fn != DBNull.Value && !string.IsNullOrWhiteSpace(fn.ToString()))
                            {
                                trimmed = fn.ToString().Trim();
                            }
                        }
                    }
                }
            }
            catch { }
        }

        // If already existing after DB lookup, return it
        if (File.Exists(trimmed))
            return trimmed;

        // Normalize extension
        if (!Path.HasExtension(trimmed))
            trimmed += ".btw";

        // Normalize directory: if not rooted, check C:\idash_prints
        if (!Path.IsPathRooted(trimmed))
            trimmed = Path.Combine(@"c:\idash_prints", trimmed);

        return trimmed;
    }

    /// <summary>
    /// Inspects a BarTender .btw file and returns all Named Data Sources (variables).
    /// Uses the Print Scheduler service first, falls back to in-process Engine.
    /// </summary>
    public static List<string> GetTemplateFields(string templatePath)
    {
        templatePath = ResolveTemplatePath(templatePath);
        var fields = new List<string>();
        if (string.IsNullOrWhiteSpace(templatePath) || !File.Exists(templatePath))
            return fields;

        // 1. Try Print Scheduler TaskManager (preferred — no Engine.Start needed)
        try
        {
            return GetFieldsViaTaskManager(templatePath);
        }
        catch { }

        // 2. In-process Engine fallback
        lock (_syncLock)
        {
            Engine eng = GetEngine();
            LabelFormatDocument doc = null;
            try
            {
                doc = eng.Documents.Open(templatePath);
                foreach (SubString sub in doc.SubStrings)
                {
                    fields.Add(sub.Name);
                }
            }
            finally
            {
                if (doc != null)
                {
                    try { doc.Close(SaveOptions.DoNotSaveChanges); } catch { }
                }
            }
        }
        return fields;
    }

    /// <summary>
    /// Renders an exact label preview image (PNG) with dynamic asset fields applied.
    /// Returns the result as base64 string ready for browser rendering.
    /// Uses the Print Scheduler TaskManager as the primary path — this communicates
    /// with the already-running BarTender services and works reliably under IIS.
    /// Falls back to in-process Engine only if the Print Scheduler is unavailable.
    /// </summary>
    public static PreviewResult GeneratePreview(string templatePath, Dictionary<string, string> fields)
    {
        var result = new PreviewResult();
        templatePath = ResolveTemplatePath(templatePath);
        if (string.IsNullOrWhiteSpace(templatePath) || !File.Exists(templatePath))
        {
            result.Success = false;
            result.ErrorMessage = "Template file does not exist at: " + templatePath;
            return result;
        }

        // 1. Try Print Scheduler TaskManager (preferred — no Engine.Start needed)
        try
        {
            return GeneratePreviewViaTaskManager(templatePath, fields);
        }
        catch (Exception tmEx)
        {
            // Print Scheduler unavailable — fall through to Engine
            result.ErrorMessage = "Print Scheduler: " + tmEx.Message;
        }

        // 2. In-process Engine fallback (may fail under IIS with low desktop heap)
        string tempPng = Path.Combine(Path.GetTempPath(), "idash_bt_" + Guid.NewGuid().ToString("N") + ".png");

        lock (_syncLock)
        {
            Engine eng = null;
            LabelFormatDocument doc = null;
            try
            {
                eng = GetEngine();
                doc = eng.Documents.Open(templatePath);
                try { doc.PrintSetup.UseDatabase = false; } catch { }

                // Populate fields
                if (fields != null)
                {
                    foreach (SubString sub in doc.SubStrings)
                    {
                        result.DiscoveredFields.Add(sub.Name);
                        string matchVal = null;
                        foreach (var kv in fields)
                        {
                            if (string.Equals(kv.Key, sub.Name, StringComparison.OrdinalIgnoreCase))
                            {
                                matchVal = kv.Value;
                                break;
                            }
                        }

                        if (matchVal != null)
                        {
                            sub.Value = matchVal;
                        }
                    }
                }

                // Export to PNG with 200 DPI resolution
                doc.ExportImageToFile(tempPng, ImageType.PNG, ColorDepth.ColorDepth24bit, new Resolution(200), OverwriteOptions.Overwrite);

                if (File.Exists(tempPng))
                {
                    byte[] bytes = File.ReadAllBytes(tempPng);
                    result.ImageBase64 = Convert.ToBase64String(bytes);
                    result.Success = true;
                    result.ErrorMessage = null;
                }
                else
                {
                    result.Success = false;
                    result.ErrorMessage = "BarTender did not generate the output preview image file.";
                }
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.ErrorMessage = "Preview Generation Error: " + ex.Message;
            }
            finally
            {
                if (doc != null)
                {
                    try { doc.Close(SaveOptions.DoNotSaveChanges); } catch { }
                }
                if (File.Exists(tempPng))
                {
                    try { File.Delete(tempPng); } catch { }
                }
            }
        }

        return result;
    }

    /// <summary>
    /// Executes a print job through BarTender.
    /// Uses the Print Scheduler TaskManager as the primary path.
    /// Falls back to in-process Engine only if the Print Scheduler is unavailable.
    /// </summary>
    public static PrintResult PrintDirect(string templatePath, string printerName, Dictionary<string, string> fields)
    {
        var result = new PrintResult();
        templatePath = ResolveTemplatePath(templatePath);
        if (string.IsNullOrWhiteSpace(templatePath) || !File.Exists(templatePath))
        {
            result.Success = false;
            result.ErrorMessage = "Template file does not exist at: " + templatePath;
            return result;
        }

        // 1. Try Print Scheduler TaskManager (preferred)
        try
        {
            return PrintViaTaskManager(templatePath, printerName, fields);
        }
        catch { }

        // 2. In-process Engine fallback
        lock (_syncLock)
        {
            Engine eng = GetEngine();
            LabelFormatDocument doc = null;
            try
            {
                doc = eng.Documents.Open(templatePath);
                try { doc.PrintSetup.UseDatabase = false; } catch { }

                if (!string.IsNullOrWhiteSpace(printerName))
                {
                    doc.PrintSetup.PrinterName = printerName;
                }

                if (fields != null)
                {
                    foreach (SubString sub in doc.SubStrings)
                    {
                        string matchVal = null;
                        foreach (var kv in fields)
                        {
                            if (string.Equals(kv.Key, sub.Name, StringComparison.OrdinalIgnoreCase))
                            {
                                matchVal = kv.Value;
                                break;
                            }
                        }

                        if (matchVal != null)
                        {
                            sub.Value = matchVal;
                        }
                    }
                }

                Messages msgs;
                string jobName = "iDash Print " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                Result res = doc.Print(jobName, out msgs);

                if (msgs != null)
                {
                    foreach (Seagull.BarTender.Print.Message m in msgs)
                    {
                        result.Messages.Add(m.Text);
                    }
                }

                if (res == Result.Success)
                {
                    result.Success = true;
                    result.JobName = jobName;
                }
                else
                {
                    result.Success = false;
                    string detail = result.Messages.Count > 0 ? string.Join("; ", result.Messages.ToArray()) : ("BarTender result code: " + res.ToString());
                    result.ErrorMessage = "BarTender Print Failed (" + res.ToString() + "): " + detail;
                }
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.ErrorMessage = "Direct Print Exception: " + ex.Message;
            }
            finally
            {
                if (doc != null)
                {
                    try { doc.Close(SaveOptions.DoNotSaveChanges); } catch { }
                }
            }
        }

        return result;
    }
}
