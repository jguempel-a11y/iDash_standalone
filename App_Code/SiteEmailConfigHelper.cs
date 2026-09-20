using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;

/// <summary>
/// Manages per-site email routing stored in ~/config/site_email_config.json.
/// Each site is keyed by its Station Number (text7 field, e.g. "613").
/// Stored outside web.config so edits don't trigger an IIS app pool recycle.
/// </summary>
public static class SiteEmailConfigHelper
{
    private static string FilePath
    {
        get { return HttpContext.Current.Server.MapPath("~/config/site_email_config.json"); }
    }

    // ── Data model ──────────────────────────────────────────────────────────
    public class SiteEmailEntry
    {
        public int    CompanyId   { get; set; }  // company.id (for reference)
        public string DisplayName { get; set; }  // e.g. "613 Martinsburg"
        public bool   Enabled     { get; set; }  // false = skip this site entirely
        public List<string> Recipients { get; set; }

        public SiteEmailEntry()
        {
            CompanyId   = 0;
            DisplayName = "";
            Enabled     = true;  // default ON
            Recipients  = new List<string>();
        }
    }

    // ── Read ────────────────────────────────────────────────────────────────
    public static Dictionary<string, SiteEmailEntry> Load()
    {
        if (!File.Exists(FilePath))
            return new Dictionary<string, SiteEmailEntry>(StringComparer.OrdinalIgnoreCase);

        try
        {
            string json = File.ReadAllText(FilePath);
            var js = new JavaScriptSerializer();
            var raw = js.Deserialize<Dictionary<string, SiteEmailEntry>>(json);
            return raw ?? new Dictionary<string, SiteEmailEntry>(StringComparer.OrdinalIgnoreCase);
        }
        catch
        {
            return new Dictionary<string, SiteEmailEntry>(StringComparer.OrdinalIgnoreCase);
        }
    }

    /// <summary>
    /// Returns the recipient list for a specific site, or null if not configured or disabled.
    /// Null signals the caller to fall back to the global recipient list.
    /// </summary>
    public static List<string> GetRecipientsForSite(string stationNumber)
    {
        var config = Load();
        SiteEmailEntry entry;
        if (!config.TryGetValue(stationNumber.Trim(), out entry)) return null;
        if (!entry.Enabled) return null;  // disabled = skip (null = use global)
        if (entry.Recipients == null || entry.Recipients.Count == 0) return null;
        return entry.Recipients
            .Where(r => !string.IsNullOrWhiteSpace(r))
            .Select(r => r.Trim())
            .ToList();
    }

    /// <summary>
    /// Returns false if this site has been explicitly disabled in site_email_config.json.
    /// Returns true if not configured (default: enabled) or explicitly enabled.
    /// </summary>
    public static bool GetSiteEnabled(string stationNumber)
    {
        var config = Load();
        SiteEmailEntry entry;
        if (!config.TryGetValue(stationNumber.Trim(), out entry)) return true; // default ON
        return entry.Enabled;
    }

    // ── Write ───────────────────────────────────────────────────────────────
    public static void Save(Dictionary<string, SiteEmailEntry> config)
    {
        string dir = Path.GetDirectoryName(FilePath);
        if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

        var js = new JavaScriptSerializer();
        File.WriteAllText(FilePath, js.Serialize(config));
    }

    /// <summary>
    /// Upserts a single site entry. Pass empty recipients list to remove custom routing.
    /// </summary>
    public static void SaveSite(string stationNumber, string displayName, bool enabled, List<string> recipients, int companyId = 0)
    {
        var config = Load();
        config[stationNumber.Trim()] = new SiteEmailEntry
        {
            CompanyId   = companyId,
            DisplayName = displayName ?? stationNumber,
            Enabled     = enabled,
            Recipients  = (recipients ?? new List<string>())
                .Where(r => !string.IsNullOrWhiteSpace(r))
                .Select(r => r.Trim())
                .ToList()
        };
        Save(config);
    }

    /// <summary>
    /// Removes a site entry entirely (will fall back to global recipients).
    /// </summary>
    public static void RemoveSite(string stationNumber)
    {
        var config = Load();
        config.Remove(stationNumber.Trim());
        Save(config);
    }
}
