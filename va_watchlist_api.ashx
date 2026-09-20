<%@ WebHandler Language="C#" Class="iDash.WatchListApiHandler" %>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.SessionState;

namespace iDash
{
    /// <summary>
    /// Lightweight API handler for iDash Notifications & Asset Watch List.
    /// Provides background detection checks, recency analysis, location mismatch tracking,
    /// and server-side watch list persistence.
    /// </summary>
    public class WatchListApiHandler : IHttpHandler, IRequiresSessionState
    {
        public bool IsReusable { get { return false; } }

        private string ConnStr
        {
            get { return WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString; }
        }

        public void ProcessRequest(HttpContext ctx)
        {
            ctx.Response.ContentType = "application/json";
            ctx.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            ctx.Response.Cache.SetNoStore();

            string action = (ctx.Request.QueryString["action"] ?? "check").ToLowerInvariant();

            try
            {
                switch (action)
                {
                    case "check":
                        HandleCheck(ctx);
                        break;
                    case "save":
                        HandleSave(ctx);
                        break;
                    case "load":
                        HandleLoad(ctx);
                        break;
                    default:
                        ctx.Response.StatusCode = 400;
                        ctx.Response.Write("{\"error\":\"Unknown action\"}");
                        break;
                }
            }
            catch (Exception ex)
            {
                ctx.Response.StatusCode = 500;
                ctx.Response.Write("{\"error\":\"" + JsonSafe(ex.Message) + "\"}");
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        //  ACTION: CHECK WATCH LIST
        // ══════════════════════════════════════════════════════════════════════
        private void HandleCheck(HttpContext ctx)
        {
            List<string> items = new List<string>();

            if (ctx.Request.HttpMethod == "POST")
            {
                using (var reader = new StreamReader(ctx.Request.InputStream))
                {
                    string body = reader.ReadToEnd();
                    if (!string.IsNullOrWhiteSpace(body))
                    {
                        var jss = new JavaScriptSerializer();
                        try
                        {
                            var parsed = jss.Deserialize<Dictionary<string, object>>(body);
                            if (parsed != null && parsed.ContainsKey("items"))
                            {
                                var arr = parsed["items"] as System.Collections.ArrayList;
                                if (arr != null)
                                {
                                    foreach (var obj in arr)
                                    {
                                        string s = (obj ?? "").ToString().Trim();
                                        if (!string.IsNullOrEmpty(s)) items.Add(s);
                                    }
                                }
                                else if (parsed["items"] is string)
                                {
                                    items = ParseItems(parsed["items"].ToString());
                                }
                            }
                        }
                        catch
                        {
                            items = ParseItems(body);
                        }
                    }
                }
            }

            if (items.Count == 0)
            {
                string queryItems = ctx.Request.QueryString["items"] ?? "";
                items = ParseItems(queryItems);
            }

            // Deduplicate items preserving order
            var distinctItems = new List<string>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var it in items)
            {
                if (!seen.Contains(it))
                {
                    seen.Add(it);
                    distinctItems.Add(it);
                }
            }

            if (distinctItems.Count == 0)
            {
                ctx.Response.Write("{\"total\":0,\"summary\":{\"totalWatched\":0,\"high\":0,\"moderate\":0,\"low\":0,\"cold\":0,\"mismatch\":0},\"assets\":[]}");
                return;
            }

            var results = EvaluateWatchList(distinctItems);

            var jssOut = new JavaScriptSerializer();
            jssOut.MaxJsonLength = int.MaxValue;
            ctx.Response.Write(jssOut.Serialize(results));
        }

        private List<string> ParseItems(string raw)
        {
            var list = new List<string>();
            if (string.IsNullOrWhiteSpace(raw)) return list;

            var parts = raw.Split(new[] { '\r', '\n', ',', '|', '\t' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var p in parts)
            {
                string s = p.Trim();
                if (!string.IsNullOrEmpty(s)) list.Add(s);
            }
            return list;
        }

        private object EvaluateWatchList(List<string> rawItems)
        {
            var watchedMap = new Dictionary<string, WatchedAssetResult>(StringComparer.OrdinalIgnoreCase);
            foreach (var item in rawItems)
            {
                watchedMap[item] = new WatchedAssetResult
                {
                    SearchKey = item,
                    AssetName = item,
                    DetectionLevel = "COLD",
                    DetectionBadge = "⚪ Undetected",
                    DetectionDetails = "No fixed reader reads recorded"
                };
            }

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // 1. Fetch assets matching either exact name or RFID tag
                var inParams = new List<string>();
                var cmd = new SqlCommand();
                cmd.Connection = conn;
                cmd.CommandTimeout = 60;

                for (int i = 0; i < rawItems.Count; i++)
                {
                    string pName = "@p" + i;
                    inParams.Add(pName);
                    cmd.Parameters.AddWithValue(pName, rawItems[i]);
                }

                cmd.CommandText = @"
                    SELECT 
                        a.id AS AssetId,
                        a.name AS AssetName,
                        a.description AS Description,
                        a.rfidtag AS RfidTag,
                        c.name AS SiteName,
                        a.companyid AS CompanyId,
                        ISNULL(l.name, '(Unassigned)') AS AssignedLocation,
                        ISNULL(a.lastobservedlocation, '') AS ObservedLocation,
                        a.lastobservedtime AS LastObservedTime,
                        a.lastinventoried AS LastInventoriedTime,
                        ISNULL(a.listvalue1, '') AS Status,
                        ISNULL(a.text8, '') AS CMR,
                        DATEDIFF(MINUTE, a.lastobservedtime, SYSDATETIMEOFFSET()) AS MinsAgo,
                        DATEDIFF(HOUR, a.lastobservedtime, SYSDATETIMEOFFSET()) AS HoursAgo,
                        DATEDIFF(DAY, a.lastobservedtime, SYSDATETIMEOFFSET()) AS DaysAgo
                    FROM dbo.asset a WITH (NOLOCK)
                    LEFT JOIN dbo.location l WITH (NOLOCK) ON a.locationid = l.id
                    LEFT JOIN dbo.company c WITH (NOLOCK) ON a.companyid = c.id
                    WHERE a.name IN (" + string.Join(",", inParams) + @")
                       OR a.rfidtag IN (" + string.Join(",", inParams) + @")";

                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        string name = rdr["AssetName"].ToString();
                        string tag = rdr["RfidTag"] == DBNull.Value ? "" : rdr["RfidTag"].ToString();

                        string matchedKey = null;
                        foreach (var key in rawItems)
                        {
                            if (string.Equals(key, name, StringComparison.OrdinalIgnoreCase) ||
                                (tag != "" && string.Equals(key, tag, StringComparison.OrdinalIgnoreCase)) ||
                                name.EndsWith(key, StringComparison.OrdinalIgnoreCase) ||
                                name.IndexOf(key, StringComparison.OrdinalIgnoreCase) >= 0)
                            {
                                matchedKey = key;
                                break;
                            }
                        }

                        if (matchedKey != null && watchedMap.ContainsKey(matchedKey))
                        {
                            PopulateResult(watchedMap[matchedKey], rdr);
                        }
                    }
                }

                // Suffix / Partial matching for items still without an AssetId (e.g. user typed "EE12889")
                var unmatched = rawItems.Where(k => watchedMap[k].AssetId == 0).Take(40).ToList();
                foreach (var unkey in unmatched)
                {
                    using (var cmdLike = new SqlCommand(@"
                        SELECT TOP 1
                            a.id AS AssetId,
                            a.name AS AssetName,
                            a.description AS Description,
                            a.rfidtag AS RfidTag,
                            c.name AS SiteName,
                            a.companyid AS CompanyId,
                            ISNULL(l.name, '(Unassigned)') AS AssignedLocation,
                            ISNULL(a.lastobservedlocation, '') AS ObservedLocation,
                            a.lastobservedtime AS LastObservedTime,
                            a.lastinventoried AS LastInventoriedTime,
                            ISNULL(a.listvalue1, '') AS Status,
                            ISNULL(a.text8, '') AS CMR,
                            DATEDIFF(MINUTE, a.lastobservedtime, SYSDATETIMEOFFSET()) AS MinsAgo,
                            DATEDIFF(HOUR, a.lastobservedtime, SYSDATETIMEOFFSET()) AS HoursAgo,
                            DATEDIFF(DAY, a.lastobservedtime, SYSDATETIMEOFFSET()) AS DaysAgo
                        FROM dbo.asset a WITH (NOLOCK)
                        LEFT JOIN dbo.location l WITH (NOLOCK) ON a.locationid = l.id
                        LEFT JOIN dbo.company c WITH (NOLOCK) ON a.companyid = c.id
                        WHERE a.name LIKE '%' + @term
                        ORDER BY a.lastobservedtime DESC", conn))
                    {
                        cmdLike.Parameters.AddWithValue("@term", unkey);
                        using (var rdrLike = cmdLike.ExecuteReader())
                        {
                            if (rdrLike.Read())
                            {
                                PopulateResult(watchedMap[unkey], rdrLike);
                            }
                        }
                    }
                }

                // 2. Query dbo.event for recent RFID reads/RSSI for matched assets
                var matchedAssetNames = watchedMap.Values
                    .Where(w => w.AssetId > 0)
                    .Select(w => w.AssetName)
                    .Distinct()
                    .ToList();

                if (matchedAssetNames.Count > 0)
                {
                    var evParams = new List<string>();
                    var cmdEv = new SqlCommand();
                    cmdEv.Connection = conn;
                    cmdEv.CommandTimeout = 30;

                    for (int i = 0; i < matchedAssetNames.Count; i++)
                    {
                        string p = "@en" + i;
                        evParams.Add(p);
                        cmdEv.Parameters.AddWithValue(p, matchedAssetNames[i]);
                    }

                    cmdEv.CommandText = @"
                        SELECT e.assetname, e.readername, e.antennanumber, e.rssi, e.eventtime
                        FROM dbo.event e WITH (NOLOCK)
                        WHERE e.assetname IN (" + string.Join(",", evParams) + @")
                          AND e.eventtime >= DATEADD(day, -30, GETDATE())
                        ORDER BY e.eventtime DESC";

                    using (var rdrEv = cmdEv.ExecuteReader())
                    {
                        while (rdrEv.Read())
                        {
                            string aName = rdrEv["assetname"].ToString();
                            foreach (var res in watchedMap.Values)
                            {
                                if (string.Equals(res.AssetName, aName, StringComparison.OrdinalIgnoreCase) && string.IsNullOrEmpty(res.RecentReader))
                                {
                                    res.RecentReader = rdrEv["readername"] == DBNull.Value ? "" : rdrEv["readername"].ToString();
                                    res.RecentAntenna = rdrEv["antennanumber"] == DBNull.Value ? "" : rdrEv["antennanumber"].ToString();
                                    res.RecentRssi = rdrEv["rssi"] == DBNull.Value ? "" : (rdrEv["rssi"].ToString() + " dBm");
                                    res.RecentEventTime = rdrEv["eventtime"] == DBNull.Value ? "" : Convert.ToString(rdrEv["eventtime"]);
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            // Counters
            int highCount = 0;
            int moderateCount = 0;
            int lowCount = 0;
            int coldCount = 0;
            int mismatchCount = 0;

            var listOut = new List<WatchedAssetResult>();
            foreach (var key in rawItems)
            {
                var r = watchedMap[key];
                listOut.Add(r);

                if (r.DetectionLevel == "HIGH") highCount++;
                else if (r.DetectionLevel == "MODERATE") moderateCount++;
                else if (r.DetectionLevel == "LOW") lowCount++;
                else coldCount++;

                if (r.LocationMismatch) mismatchCount++;
            }

            return new
            {
                total = listOut.Count,
                summary = new
                {
                    totalWatched = listOut.Count,
                    high = highCount,
                    moderate = moderateCount,
                    low = lowCount,
                    cold = coldCount,
                    mismatch = mismatchCount
                },
                assets = listOut
            };
        }

        private void PopulateResult(WatchedAssetResult res, SqlDataReader rdr)
        {
            res.AssetId = Convert.ToInt64(rdr["AssetId"]);
            res.AssetName = rdr["AssetName"].ToString();
            res.Description = rdr["Description"] == DBNull.Value ? "" : rdr["Description"].ToString();
            res.RfidTag = rdr["RfidTag"] == DBNull.Value ? "" : rdr["RfidTag"].ToString();
            res.SiteName = rdr["SiteName"] == DBNull.Value ? "" : rdr["SiteName"].ToString();
            res.CompanyId = rdr["CompanyId"] == DBNull.Value ? 0 : Convert.ToInt32(rdr["CompanyId"]);
            res.AssignedLocation = rdr["AssignedLocation"].ToString();
            res.ObservedLocation = rdr["ObservedLocation"].ToString();
            res.Status = rdr["Status"].ToString();
            res.CMR = rdr["CMR"].ToString();

            if (rdr["LastObservedTime"] != DBNull.Value)
            {
                object rawObs = rdr["LastObservedTime"];
                DateTimeOffset obsUtc;
                if (rawObs is DateTimeOffset) obsUtc = (DateTimeOffset)rawObs;
                else if (rawObs is DateTime) obsUtc = new DateTimeOffset((DateTime)rawObs);
                else DateTimeOffset.TryParse(rawObs.ToString(), out obsUtc);

                res.LastObservedTime = obsUtc.ToString("yyyy-MM-dd HH:mm:ss");

                int minsAgo = rdr["MinsAgo"] != DBNull.Value ? Convert.ToInt32(rdr["MinsAgo"]) : 99999;
                int hoursAgo = rdr["HoursAgo"] != DBNull.Value ? Convert.ToInt32(rdr["HoursAgo"]) : 9999;
                int daysAgo = rdr["DaysAgo"] != DBNull.Value ? Convert.ToInt32(rdr["DaysAgo"]) : 999;

                res.MinsAgo = minsAgo;
                res.HoursAgo = hoursAgo;
                res.DaysAgo = daysAgo;

                if (minsAgo < 60)
                    res.RelativeTime = minsAgo <= 1 ? "Just now" : (minsAgo + "m ago");
                else if (hoursAgo < 24)
                    res.RelativeTime = hoursAgo + "h ago";
                else if (daysAgo == 1)
                    res.RelativeTime = "Yesterday";
                else
                    res.RelativeTime = daysAgo + "d ago";

                if (hoursAgo < 24)
                {
                    res.DetectionLevel = "HIGH";
                    res.DetectionBadge = "🟢 High Detection";
                    res.DetectionDetails = "Observed " + res.RelativeTime + " at " + (string.IsNullOrEmpty(res.ObservedLocation) ? "Fixed Reader" : res.ObservedLocation);
                }
                else if (daysAgo <= 7)
                {
                    res.DetectionLevel = "MODERATE";
                    res.DetectionBadge = "🟡 Moderate";
                    res.DetectionDetails = "Observed " + res.RelativeTime + " at " + (string.IsNullOrEmpty(res.ObservedLocation) ? "Fixed Reader" : res.ObservedLocation);
                }
                else if (daysAgo <= 30)
                {
                    res.DetectionLevel = "LOW";
                    res.DetectionBadge = "🟠 Low";
                    res.DetectionDetails = "Last observed " + res.RelativeTime;
                }
                else
                {
                    res.DetectionLevel = "COLD";
                    res.DetectionBadge = "⚪ Cold";
                    res.DetectionDetails = "Last observed " + daysAgo + " days ago";
                }
            }
            else
            {
                res.DetectionLevel = "COLD";
                res.DetectionBadge = "⚪ Undetected";
                if (rdr["LastInventoriedTime"] != DBNull.Value)
                {
                    object rawInv = rdr["LastInventoriedTime"];
                    DateTimeOffset inv;
                    if (rawInv is DateTimeOffset) inv = (DateTimeOffset)rawInv;
                    else if (rawInv is DateTime) inv = new DateTimeOffset((DateTime)rawInv);
                    else DateTimeOffset.TryParse(rawInv.ToString(), out inv);

                    res.LastInventoriedTime = inv.ToString("yyyy-MM-dd");
                    res.DetectionDetails = "Mobile inventory: " + inv.ToString("MM/dd/yyyy");
                }
                else
                {
                    res.DetectionDetails = "No fixed reader reads recorded";
                }
            }

            if (!string.IsNullOrEmpty(res.ObservedLocation) &&
                !string.IsNullOrEmpty(res.AssignedLocation) &&
                !string.Equals(res.AssignedLocation, "(Unassigned)", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(res.ObservedLocation, res.AssignedLocation, StringComparison.OrdinalIgnoreCase))
            {
                res.LocationMismatch = true;
                res.MismatchMessage = "Observed at " + res.ObservedLocation + " (Assigned: " + res.AssignedLocation + ")";
            }
        }

        private void HandleSave(HttpContext ctx)
        {
            string username = Convert.ToString(ctx.Session["IdashUsername"] ?? "default").Trim();
            if (string.IsNullOrEmpty(username)) username = "default";

            string body;
            using (var rdr = new StreamReader(ctx.Request.InputStream))
            {
                body = rdr.ReadToEnd();
            }

            string dir = GetStorageDir();
            string path = Path.Combine(dir, "watchlist_" + SafeFilename(username) + ".json");
            File.WriteAllText(path, body, System.Text.Encoding.UTF8);

            ctx.Response.Write("{\"success\":true,\"saved\":true,\"user\":\"" + JsonSafe(username) + "\"}");
        }

        private void HandleLoad(HttpContext ctx)
        {
            string username = Convert.ToString(ctx.Session["IdashUsername"] ?? "default").Trim();
            if (string.IsNullOrEmpty(username)) username = "default";

            string dir = GetStorageDir();
            string path = Path.Combine(dir, "watchlist_" + SafeFilename(username) + ".json");

            if (File.Exists(path))
            {
                string json = File.ReadAllText(path, System.Text.Encoding.UTF8);
                ctx.Response.Write(json);
            }
            else
            {
                ctx.Response.Write("{\"items\":\"\"}");
            }
        }

        private string GetStorageDir()
        {
            string dir = HttpContext.Current.Server.MapPath("~/App_Data/watchlists");
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            return dir;
        }

        private string SafeFilename(string s)
        {
            return Regex.Replace(s ?? "default", @"[^a-zA-Z0-9_\-]", "_");
        }

        private string JsonSafe(string s)
        {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
        }

        public class WatchedAssetResult
        {
            public string SearchKey           { get; set; }
            public long   AssetId             { get; set; }
            public string AssetName           { get; set; }
            public string Description         { get; set; }
            public string RfidTag             { get; set; }
            public string SiteName            { get; set; }
            public int    CompanyId           { get; set; }
            public string AssignedLocation    { get; set; }
            public string ObservedLocation    { get; set; }
            public string LastObservedTime    { get; set; }
            public string LastInventoriedTime { get; set; }
            public string RelativeTime        { get; set; }
            public int    MinsAgo             { get; set; }
            public int    HoursAgo            { get; set; }
            public int    DaysAgo             { get; set; }
            public string Status              { get; set; }
            public string CMR                 { get; set; }
            public string DetectionLevel      { get; set; }
            public string DetectionBadge      { get; set; }
            public string DetectionDetails    { get; set; }
            public bool   LocationMismatch    { get; set; }
            public string MismatchMessage     { get; set; }
            public string RecentReader        { get; set; }
            public string RecentAntenna       { get; set; }
            public string RecentRssi          { get; set; }
            public string RecentEventTime     { get; set; }
        }
    }
}
