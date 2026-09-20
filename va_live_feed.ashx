<%@ WebHandler Language="C#" Class="LiveFeedHandler" %>
using System;
using System.Linq;
using System.Threading;
using System.Web;

/// <summary>
/// SSE (Server-Sent Events) endpoint for the Fixed Reader Live Feed.
/// GET /iDash/va_live_feed.ashx?seq=0&readers=1,2&antennas=1,2
///
/// Keeps the HTTP connection open and streams tag-read events as they happen.
/// The browser EventSource API auto-reconnects on disconnect.
/// Times out after 5 minutes (browser reconnects immediately with last seq).
/// </summary>
public class LiveFeedHandler : IHttpHandler
{
    public bool IsReusable { get { return false; } }

    public void ProcessRequest(HttpContext ctx)
    {
        var req  = ctx.Request;
        var resp = ctx.Response;

        // -- Parse query params --
        long sinceSeq = 0;
        long.TryParse(req.QueryString["seq"] ?? "0", out sinceSeq);

        int[] readerIds    = ParseInts(req.QueryString["readers"]);
        int[] antennaPorts = ParseInts(req.QueryString["antennas"]);
        // companies=null in query means admin (unrestricted); companies= empty means no access
        int[] companyIds   = req.QueryString["companies"] == null
                                ? null                         // param absent = admin = all
                                : ParseInts(req.QueryString["companies"]) ?? new int[0];

        // -- SSE headers --
        resp.ContentType    = "text/event-stream";
        resp.CacheControl   = "no-cache";
        resp.AddHeader("X-Accel-Buffering", "no");  // nginx passthrough
        resp.Buffer         = false;

        // -- Send initial sequence comment so client knows where we are --
        long currentSeq = AntennaLocationService.GetLiveSeq();
        if (sinceSeq == 0) sinceSeq = currentSeq;  // New connection: start from now
        WriteComment(resp, "iDash Live Feed connected. seq=" + sinceSeq);
        resp.Flush();

        // -- Stream loop: 5 minute max, 500ms poll --
        DateTime deadline = DateTime.UtcNow.AddMinutes(5);
        long lastSeq = sinceSeq;

        while (DateTime.UtcNow < deadline)
        {
            if (!resp.IsClientConnected) break;

            var events = AntennaLocationService.GetLiveEvents(lastSeq, readerIds, antennaPorts, companyIds);
            foreach (var e in events)
            {
                if (!resp.IsClientConnected) break;
                WriteEvent(resp, e);
                if (e.Seq > lastSeq) lastSeq = e.Seq;
            }

            if (events.Count > 0) resp.Flush();

            // Heartbeat every 15 seconds to keep connection alive
            if ((DateTime.UtcNow.Second % 15) == 0)
            {
                WriteComment(resp, "hb " + DateTime.UtcNow.ToString("HH:mm:ss"));
                resp.Flush();
            }

            Thread.Sleep(500);
        }

        // Tell client to reconnect with updated seq
        resp.Write("retry: 100\n");
        resp.Write("data: {\"reconnect\":true,\"seq\":" + lastSeq + "}\n\n");
        resp.Flush();
    }

    private static void WriteEvent(HttpResponse resp, AntennaLocationService.LiveTagEvent e)
    {
        // Simple manual JSON -- avoids JavaScriptSerializer overhead per event
        string data = string.Format(
            "{{\"seq\":{0},\"ts\":\"{1}\",\"epc\":\"{2}\",\"assetId\":{3}," +
            "\"assetName\":\"{4}\",\"description\":\"{5}\"," +
            "\"readerId\":{6},\"readerName\":\"{7}\"," +
            "\"antennaPort\":{8},\"antennaName\":\"{9}\",\"locationChanged\":{10}," +
            "\"isCrossSite\":{11},\"assetSiteName\":\"{12}\",\"assignedLocation\":\"{13}\"}}",
            e.Seq,
            Esc(e.Ts),
            Esc(e.Epc),
            e.AssetId,
            Esc(e.AssetName),
            Esc(e.Description),
            e.ReaderId,
            Esc(e.ReaderName),
            e.AntennaPort,
            Esc(e.AntennaName),
            e.LocationChanged ? "true" : "false",
            e.IsCrossSite ? "true" : "false",
            Esc(e.AssetSiteName ?? ""),
            Esc(e.AssignedLocation ?? "")
        );
        resp.Write("data: " + data + "\n\n");
    }

    private static void WriteComment(HttpResponse resp, string msg)
    {
        resp.Write(": " + msg + "\n\n");
    }

    private static string Esc(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", " ");
    }

    private static int[] ParseInts(string csv)
    {
        if (string.IsNullOrWhiteSpace(csv)) return null;
        var parts = csv.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        var result = new System.Collections.Generic.List<int>();
        foreach (var p in parts)
        {
            int v;
            if (int.TryParse(p.Trim(), out v)) result.Add(v);
        }
        return result.Count > 0 ? result.ToArray() : null;
    }
}
