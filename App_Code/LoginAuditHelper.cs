using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

/// <summary>
/// Persistent login audit trail for iDash.
/// Stores login events in a JSON Lines file with automatic size control.
/// 
/// File:    logs/login_audit.jsonl
/// Limits:  90-day rolling window  OR  5,000 entries max (whichever triggers first)
/// Format:  One JSON object per line — {"ts":"...","user":"...","ip":"...","ok":true,"role":"admin"}
/// </summary>
public static class LoginAuditHelper
{
    private const string RelativePath = "logs/login_audit.jsonl";
    private const int MaxEntries = 5000;
    private const int MaxAgeDays = 90;

    private static readonly object _lock = new object();

    // ─── Data model ──────────────────────────────────────────────────────

    public class LoginEntry
    {
        public DateTime Timestamp { get; set; }
        public string Username { get; set; }
        public string IP { get; set; }
        public bool Success { get; set; }
        public string Role { get; set; }
    }

    // ─── Write ───────────────────────────────────────────────────────────

    /// <summary>Record a login attempt (success or failure).</summary>
    public static void LogLogin(string username, string ip, bool success, string role = "")
    {
        try
        {
            string path = GetFilePath();
            string dir = Path.GetDirectoryName(path);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            // Build compact JSON line (no dependency on Newtonsoft)
            string ts = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss");
            string line = string.Format(
                "{{\"ts\":\"{0}\",\"user\":\"{1}\",\"ip\":\"{2}\",\"ok\":{3},\"role\":\"{4}\"}}",
                ts,
                EscapeJson(username ?? ""),
                EscapeJson(ip ?? ""),
                success ? "true" : "false",
                EscapeJson(role ?? "")
            );

            lock (_lock)
            {
                File.AppendAllText(path, line + Environment.NewLine);
                TrimIfNeeded(path);
            }
        }
        catch
        {
            // Audit logging should never crash the login flow
        }
    }

    /// <summary>Record a privileged administrative action (service restart, SQL execution, license modification, etc.).</summary>
    public static void LogAdminAction(string username, string ip, string action, string details = "")
    {
        try
        {
            string root = HttpContext.Current != null && HttpContext.Current.Server != null
                ? HttpContext.Current.Server.MapPath("~")
                : AppDomain.CurrentDomain.BaseDirectory;
            string dir = Path.Combine(root, "logs");
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            string path = Path.Combine(dir, "admin_audit.jsonl");

            string ts = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss");
            string line = string.Format(
                "{{\"ts\":\"{0}\",\"user\":\"{1}\",\"ip\":\"{2}\",\"action\":\"{3}\",\"details\":\"{4}\"}}",
                ts,
                EscapeJson(username ?? "unknown"),
                EscapeJson(ip ?? ""),
                EscapeJson(action ?? ""),
                EscapeJson(details ?? "")
            );

            lock (_lock)
            {
                File.AppendAllText(path, line + Environment.NewLine);
                TrimIfNeeded(path);
            }
        }
        catch
        {
            // Audit logging should never crash operations
        }
    }

    // ─── Read ────────────────────────────────────────────────────────────

    /// <summary>Returns the most recent N login entries (newest first).</summary>
    public static List<LoginEntry> GetRecentLogins(int count = 100)
    {
        var result = new List<LoginEntry>();
        try
        {
            string path = GetFilePath();
            if (!File.Exists(path)) return result;

            string[] lines;
            lock (_lock) { lines = File.ReadAllLines(path); }

            // Parse from end (newest last in file)
            for (int i = lines.Length - 1; i >= 0 && result.Count < count; i--)
            {
                var entry = ParseLine(lines[i]);
                if (entry != null) result.Add(entry);
            }
        }
        catch { }
        return result;
    }

    /// <summary>Returns summary statistics for dashboard display.</summary>
    public static LoginStats GetLoginStats()
    {
        var stats = new LoginStats();
        try
        {
            string path = GetFilePath();
            if (!File.Exists(path)) return stats;

            string[] lines;
            lock (_lock) { lines = File.ReadAllLines(path); }

            var now = DateTime.Now;
            var todayStart = now.Date;
            var weekStart = now.Date.AddDays(-7);
            var uniqueThisWeek = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            stats.TotalEntries = 0;

            for (int i = lines.Length - 1; i >= 0; i--)
            {
                var entry = ParseLine(lines[i]);
                if (entry == null) continue;

                stats.TotalEntries++;

                if (entry.Timestamp >= todayStart)
                {
                    if (entry.Success) stats.LoginsToday++;
                    else stats.FailuresToday++;
                }

                if (entry.Timestamp >= weekStart && entry.Success)
                {
                    uniqueThisWeek.Add(entry.Username);
                }

                if (!entry.Success && stats.LastFailedLogin == null)
                {
                    stats.LastFailedLogin = entry;
                }
            }

            stats.UniqueUsersThisWeek = uniqueThisWeek.Count;
        }
        catch { }
        return stats;
    }

    public class LoginStats
    {
        public int LoginsToday { get; set; }
        public int FailuresToday { get; set; }
        public int UniqueUsersThisWeek { get; set; }
        public int TotalEntries { get; set; }
        public LoginEntry LastFailedLogin { get; set; }
    }

    // ─── Trim (size control) ─────────────────────────────────────────────

    private static void TrimIfNeeded(string path)
    {
        try
        {
            var lines = File.ReadAllLines(path);
            if (lines.Length <= MaxEntries)
            {
                // Check if we even need age trimming
                bool needsAgeTrim = false;
                if (lines.Length > 0)
                {
                    var oldest = ParseLine(lines[0]);
                    if (oldest != null && oldest.Timestamp < DateTime.Now.AddDays(-MaxAgeDays))
                        needsAgeTrim = true;
                }
                if (!needsAgeTrim) return;
            }

            var cutoff = DateTime.Now.AddDays(-MaxAgeDays);
            var kept = new List<string>();

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                var entry = ParseLine(line);
                if (entry != null && entry.Timestamp >= cutoff)
                    kept.Add(line);
            }

            // Enforce max entry cap (keep newest)
            if (kept.Count > MaxEntries)
                kept = kept.Skip(kept.Count - MaxEntries).ToList();

            File.WriteAllLines(path, kept);
        }
        catch { }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────

    private static string GetFilePath()
    {
        return Path.Combine(HttpContext.Current.Server.MapPath("~"), RelativePath.Replace("/", "\\"));
    }

    private static string EscapeJson(string s)
    {
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"");
    }

    /// <summary>Minimal JSON line parser — no external dependencies.</summary>
    private static LoginEntry ParseLine(string line)
    {
        if (string.IsNullOrWhiteSpace(line)) return null;
        try
        {
            var entry = new LoginEntry();
            entry.Timestamp = DateTime.Parse(ExtractValue(line, "ts"));
            entry.Username = ExtractValue(line, "user");
            entry.IP = ExtractValue(line, "ip");
            entry.Role = ExtractValue(line, "role");

            string okVal = ExtractValue(line, "ok");
            entry.Success = okVal == "true";

            return entry;
        }
        catch { return null; }
    }

    /// <summary>Extract a value from a simple flat JSON object by key name.</summary>
    private static string ExtractValue(string json, string key)
    {
        string search = "\"" + key + "\":";
        int idx = json.IndexOf(search);
        if (idx < 0) return "";
        int start = idx + search.Length;

        // Skip whitespace
        while (start < json.Length && json[start] == ' ') start++;

        if (start >= json.Length) return "";

        if (json[start] == '"')
        {
            // String value
            int end = json.IndexOf('"', start + 1);
            return end > start ? json.Substring(start + 1, end - start - 1) : "";
        }
        else
        {
            // Boolean/number value
            int end = start;
            while (end < json.Length && json[end] != ',' && json[end] != '}') end++;
            return json.Substring(start, end - start).Trim();
        }
    }
}
