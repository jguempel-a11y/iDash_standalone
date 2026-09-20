using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net.Security;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

/// <summary>
/// AntennaLocationService -- Embedded MQTT listener for antenna-aware location updates.
///
/// Runs inside IIS (w3wp.exe) as a background thread. No separate process needed.
/// Auto-starts on first page request and survives app pool recycles.
///
/// Architecture:
///   1. Subscribes to MQTT topic "gateway/data/#" using raw TCP/TLS (same as MqttPrintNotifier)
///   2. Parses tag reads with antenna port from JSON payload
///   3. Maps antenna port -> location using dbo.antenna cache
///   4. Updates dbo.asset.locationid + dbo.locationhistory directly
///
/// Configuration: web.config appSettings:
///   AntennaService_Enabled = true/false (default: true)
///   AntennaService_MqttServer = 127.0.0.1
///   AntennaService_MqttPort = 8883
///   AntennaService_TopicFilter = gateway/data/#
///   AntennaService_DebounceSeconds = 60
///   AntennaService_CacheMinutes = 5
/// </summary>
public static class AntennaLocationService
{
    // --- STATE --------------------------------------------------------
    private static Thread _listenerThread;
    private static volatile bool _running;
    private static readonly object _startLock = new object();
    private static DateTime _startedUtc = DateTime.MinValue;

    // Reader cache: physicalId -> ReaderInfo
    private static readonly ConcurrentDictionary<string, ReaderCacheEntry> _readerCache = new ConcurrentDictionary<string, ReaderCacheEntry>(StringComparer.OrdinalIgnoreCase);
    // Antenna cache: "readerId:port" -> AntennaCacheEntry
    private static readonly ConcurrentDictionary<string, AntennaCacheEntry> _antennaCache = new ConcurrentDictionary<string, AntennaCacheEntry>();
    // Debounce: "assetId:locationId" -> last update time
    private static readonly ConcurrentDictionary<string, DateTime> _debounce = new ConcurrentDictionary<string, DateTime>();

    private static DateTime _lastCacheRefresh = DateTime.MinValue;

    // Stats
    private static long _messagesReceived;
    private static long _locationUpdates;
    private static long _crossSiteMoves;
    private static string _lastError = "";
    private static DateTime _lastErrorTime = DateTime.MinValue;

    // Unique 8-char suffix per app pool startup — prevents two overlapping IIS
    // instances (old + new during graceful recycle) from kicking each other off
    // the MQTT broker when they share the same base ClientId.
    private static readonly string _instanceId =
        Guid.NewGuid().ToString("N").Substring(0, 8);

    // --- LIVE FEED BUFFER --------------------------------------------
    // Ring buffer of the last 500 tag read events for real-time streaming.
    // Separate 2-second debounce prevents the same tag+antenna flooding the feed.

    /// <summary>One tag read event pushed to live-feed subscribers.</summary>
    public class LiveTagEvent
    {
        public long   Seq           { get; set; }   // Monotonically increasing
        public string Ts            { get; set; }   // ISO-8601 UTC
        public string Epc           { get; set; }
        public long   AssetId       { get; set; }
        public string AssetName     { get; set; }
        public string Description   { get; set; }
        public int    ReaderId      { get; set; }
        public string ReaderName    { get; set; }
        public int    CompanyId     { get; set; }   // Reader's company — used for filtering
        public int    AntennaPort   { get; set; }
        public string AntennaName   { get; set; }   // Location name for this antenna
        public bool   LocationChanged { get; set; }
        public bool   IsCrossSite    { get; set; }   // True = asset belongs to a different site than the reader
        public string AssetSiteName  { get; set; }   // Name of the asset's home site (for cross-site display)
        public string AssignedLocation { get; set; } // Asset's current assigned location name
    }

    private static readonly ConcurrentQueue<LiveTagEvent> _liveFeed = new ConcurrentQueue<LiveTagEvent>();
    private const int LiveFeedMaxSize = 500;
    private static long _liveSeq = 0;
    // Live-feed debounce: "epc:readerId:antennaPort" -> last enqueue time (2s window)
    private static readonly ConcurrentDictionary<string, DateTime> _liveDebouce =
        new ConcurrentDictionary<string, DateTime>();

    // --- RAW MQTT SPY BUFFER ------------------------------------------
    // Captures the last 50 raw MQTT messages regardless of topic or parse result.
    // Used by the diagnostic API to show exactly what the FX9600 is sending.
    public class RawMqttMessage
    {
        public string Ts      { get; set; }   // ISO-8601 UTC receive time
        public string Topic   { get; set; }
        public string Payload { get; set; }   // First 1000 chars (may be truncated)
        public int    Bytes   { get; set; }   // Full payload byte count
        public bool   Parsed  { get; set; }   // True if ProcessPublish succeeded
    }
    private static readonly ConcurrentQueue<RawMqttMessage> _rawFeed = new ConcurrentQueue<RawMqttMessage>();
    private const int RawFeedMaxSize = 50;

    /// <summary>Returns all captured raw MQTT messages (newest last).</summary>
    public static List<RawMqttMessage> GetRawFeed()
    {
        return _rawFeed.ToArray().ToList();
    }

    /// <summary>Returns true if the background listener thread is alive.</summary>
    public static bool IsRunning() { return _running && _listenerThread != null && _listenerThread.IsAlive; }

    /// <summary>Total MQTT messages received since service start.</summary>
    public static long MessagesReceived { get { return System.Threading.Interlocked.Read(ref _messagesReceived); } }

    /// <summary>
    /// Returns live events with Seq > sinceSeq, optionally filtered by reader/antenna/company.
    /// readerIds = null means all readers. antennaPorts = null means all antennas.
    /// companyIds = null means all companies (admin). Empty list = no access.
    /// </summary>
    public static List<LiveTagEvent> GetLiveEvents(long sinceSeq, int[] readerIds, int[] antennaPorts, int[] companyIds)
    {
        var all = _liveFeed.ToArray();
        var result = new List<LiveTagEvent>();
        foreach (var e in all)
        {
            if (e.Seq <= sinceSeq) continue;
            if (readerIds  != null && readerIds.Length  > 0 && Array.IndexOf(readerIds,  e.ReaderId)    < 0) continue;
            if (antennaPorts != null && antennaPorts.Length > 0 && Array.IndexOf(antennaPorts, e.AntennaPort) < 0) continue;
            if (companyIds != null && companyIds.Length > 0 && Array.IndexOf(companyIds, e.CompanyId)   < 0) continue;
            result.Add(e);
        }
        return result;
    }

    /// <summary>Returns the current highest sequence number (for client init).</summary>
    public static long GetLiveSeq() { return System.Threading.Interlocked.Read(ref _liveSeq); }

    private static void EnqueueLiveEvent(string epc, long assetId, string assetName,
        string description, ReaderCacheEntry reader, int antennaPort, string antennaName,
        bool locationChanged, bool isCrossSite = false, string assetSiteName = "", string assignedLocation = "")
    {
        // 2-second live-feed debounce per tag+antenna combo
        string key = epc + ":" + reader.ReaderId + ":" + antennaPort;
        DateTime last;
        if (_liveDebouce.TryGetValue(key, out last) && (DateTime.UtcNow - last).TotalSeconds < 2)
            return;
        _liveDebouce[key] = DateTime.UtcNow;

        long seq = System.Threading.Interlocked.Increment(ref _liveSeq);
        _liveFeed.Enqueue(new LiveTagEvent
        {
            Seq           = seq,
            Ts            = DateTime.UtcNow.ToString("o"),
            Epc           = epc,
            AssetId       = assetId,
            AssetName     = assetName,
            Description   = description,
            ReaderId      = reader.ReaderId,
            ReaderName    = reader.PhysicalId,
            CompanyId     = reader.CompanyId,
            AntennaPort   = antennaPort,
            AntennaName   = antennaName,
            LocationChanged = locationChanged,
            IsCrossSite   = isCrossSite,
            AssetSiteName = assetSiteName,
            AssignedLocation = assignedLocation
        });

        // Trim ring buffer
        while (_liveFeed.Count > LiveFeedMaxSize)
        {
            LiveTagEvent discarded;
            _liveFeed.TryDequeue(out discarded);
        }

        // Periodically clean live debounce (every 60s)
        if (seq % 200 == 0)
        {
            var cutoff = DateTime.UtcNow.AddSeconds(-10);
            foreach (var kv in _liveDebouce.Where(x => x.Value < cutoff).ToList())
            {
                DateTime removed;
                _liveDebouce.TryRemove(kv.Key, out removed);
            }
        }
    }

    // --- CACHE TYPES --------------------------------------------------
    public class ReaderCacheEntry
    {
        public int ReaderId;
        public string PhysicalId;
        public int CompanyId;
        public int LocationId;
        public string LocationName;
        public bool UpdateLocation;
    }

    public class AntennaCacheEntry
    {
        public int AntennaId;
        public int Port;
        public int ReaderId;
        public int LocationId;
        public string LocationName;
    }

    private class TagRead
    {
        public string Epc;
        public int AntennaPort;
    }

    // --- CONNECTION STRING --------------------------------------------
    private static string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return cs != null ? cs.ConnectionString : "";
        }
    }

    private static string Setting(string key, string defaultVal = "")
    {
        return ConfigurationManager.AppSettings[key] ?? defaultVal;
    }

    // --- PUBLIC API ---------------------------------------------------

    /// <summary>
    /// Called by va_rfid_ingest.ashx to log and process a raw HTTP POST payload
    /// from the FX9600 IoT Connector's HTTP POST endpoint.
    /// This is an alternative to MQTT when the broker doesn't route reader topics.
    /// </summary>
    public static void LogHttpIngest(string rawPayload)
    {
        LogDebug("HTTP ingest payload ({0} bytes): {1}", rawPayload.Length,
            rawPayload.Length > 500 ? rawPayload.Substring(0, 500) + "..." : rawPayload);
    }

    /// <summary>
    /// Processes a raw JSON payload from the reader (same format as MQTT PUBLISH body).
    /// Runs on the calling thread (ASP.NET request thread) -- no MQTT needed.
    /// </summary>
    public static void ProcessHttpPayload(string json)
    {
        try
        {
            // Ensure caches are loaded
            if (_readerCache.Count == 0 || _antennaCache.Count == 0)
                RefreshCaches();

            Interlocked.Increment(ref _messagesReceived);

            // Parse the JSON payload -- the FX9600 Local_HTTP_POST sends a root-level
            // JSON array: [{"data":{"idHex":"...","antennaPort":1},...},...]
            // Normalize: if it's an array, wrap it in a synthetic object for uniform processing.
            var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            serializer.MaxJsonLength = 1048576; // 1MB

            // Detect array vs object root
            string trimmed = json.TrimStart();
            Dictionary<string, object> jsonObj;
            if (trimmed.StartsWith("["))
            {
                // Root array -- parse as array then process directly
                var arr = serializer.Deserialize<object[]>(trimmed);
                var tags = ParseTagReadsFromArray(arr);
                if (tags == null || tags.Count == 0) return;

                // For array format: reader name comes from the first element's "hostname"
                // or we fall back to any reader in cache that matches the IP
                ReaderCacheEntry reader = null;
                // Try hostname from first element
                if (arr.Length > 0 && arr[0] is Dictionary<string, object>)
                {
                    var first = (Dictionary<string, object>)arr[0];
                    string hn = GetStr(first, "hostname") ?? GetStr(first, "readerName");
                    if (!string.IsNullOrEmpty(hn))
                        _readerCache.TryGetValue(hn, out reader);
                }
                // If not found by hostname, use the only reader in cache (common single-reader setup)
                if (reader == null && _readerCache.Count == 1)
                    reader = _readerCache.Values.First();

                if (reader == null)
                {
                    Log("HTTP array ingest: could not identify reader (no hostname in payload, {0} readers in cache)",
                        _readerCache.Count);
                    return;
                }

                LogDebug("HTTP array ingest: processing {0} tag(s) from reader {1}", tags.Count, reader.PhysicalId);
                int debounceSeconds2 = int.Parse(Setting("AntennaService_DebounceSeconds", "60"));
                using (var conn2 = new System.Data.SqlClient.SqlConnection(ConnStr))
                {
                    conn2.Open();

                    // Update reader's lastseen so iDash shows it as Online
                    try
                    {
                        using (var upd = new System.Data.SqlClient.SqlCommand(
                            "UPDATE dbo.reader SET lastseen=SYSDATETIMEOFFSET() WHERE id=@rid", conn2))
                        {
                            upd.Parameters.AddWithValue("@rid", reader.ReaderId);
                            upd.ExecuteNonQuery();
                        }
                    }
                    catch { /* non-critical */ }

                    foreach (var tag in tags)
                    {
                        int loc = reader.LocationId;
                        string locName = reader.LocationName;
                        if (tag.AntennaPort > 0)
                        {
                            string antKey = reader.ReaderId + ":" + tag.AntennaPort;
                            AntennaCacheEntry ant;
                            if (_antennaCache.TryGetValue(antKey, out ant))
                            { loc = ant.LocationId; locName = ant.LocationName; }
                        }
                        LogTagRead(tag.Epc, tag.AntennaPort, locName);
                        ProcessTag(conn2, tag.Epc, reader, loc, locName, tag.AntennaPort, debounceSeconds2);
                    }
                }
                return;
            }
            else
            {
                jsonObj = serializer.Deserialize<Dictionary<string, object>>(trimmed);
            }
            if (jsonObj == null) return;

            // Extract reader name from payload fields
            string readerName = GetStr(jsonObj, "hostname")
                             ?? GetStr(jsonObj, "readerName")
                             ?? GetStr(jsonObj, "reader")
                             ?? GetStr(jsonObj, "deviceName")
                             ?? GetStr(jsonObj, "physicalId");

            if (string.IsNullOrEmpty(readerName) && jsonObj.ContainsKey("data")
                && jsonObj["data"] is Dictionary<string, object>)
            {
                var data = (Dictionary<string, object>)jsonObj["data"];
                readerName = GetStr(data, "hostname") ?? GetStr(data, "readerName");

                // Zebra FX9600 "component:RG" heartbeat — hostname lives inside data.reader_gateway
                if (string.IsNullOrEmpty(readerName)
                    && data.ContainsKey("reader_gateway")
                    && data["reader_gateway"] is Dictionary<string, object>)
                {
                    var rg = (Dictionary<string, object>)data["reader_gateway"];
                    readerName = GetStr(rg, "hostname") ?? GetStr(rg, "readerName");
                }
            }

            // If still no reader name but only one reader in cache and this looks like
            // a Zebra RG heartbeat (component=RG), touch lastseen for that reader
            if (string.IsNullOrEmpty(readerName))
            {
                string component = GetStr(jsonObj, "component");
                if ((component == "RG" || component == "rg") && _readerCache.Count == 1)
                {
                    // Single-reader setup: attribute this heartbeat to the only known reader
                    var sole = _readerCache.Values.First();
                    try
                    {
                        using (var conn_rg1 = new System.Data.SqlClient.SqlConnection(ConnStr))
                        {
                            conn_rg1.Open();
                            using (var cmd = new System.Data.SqlClient.SqlCommand(
                                "UPDATE dbo.reader SET lastseen=SYSDATETIMEOFFSET() WHERE id=@rid", conn_rg1))
                            {
                                cmd.Parameters.AddWithValue("@rid", sole.ReaderId);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        LogDebug("RG heartbeat: touched lastseen for reader {0}", sole.PhysicalId);
                    }
                    catch { /* non-critical */ }
                    return; // No tag data in RG heartbeats
                }

                Log("HTTP ingest: could not determine reader name from payload");
                return;
            }

            // If this is a component:RG heartbeat with a resolved reader name — just touch lastseen, no tags
            if (!string.IsNullOrEmpty(GetStr(jsonObj, "component")))
            {
                string comp = GetStr(jsonObj, "component").ToUpperInvariant();
                if (comp == "RG")
                {
                    ReaderCacheEntry rgReader;
                    if (_readerCache.TryGetValue(readerName, out rgReader))
                    {
                        try
                        {
                            using (var conn_rg2 = new System.Data.SqlClient.SqlConnection(ConnStr))
                            {
                                conn_rg2.Open();
                                using (var cmd = new System.Data.SqlClient.SqlCommand(
                                    "UPDATE dbo.reader SET lastseen=SYSDATETIMEOFFSET() WHERE id=@rid", conn_rg2))
                                {
                                    cmd.Parameters.AddWithValue("@rid", rgReader.ReaderId);
                                    cmd.ExecuteNonQuery();
                                }
                            }
                            LogDebug("RG heartbeat: touched lastseen for reader {0}", readerName);
                        }
                        catch { /* non-critical */ }
                    }
                    return; // No tag data in RG heartbeats
                }
            }

            ReaderCacheEntry readerObj;
            if (!_readerCache.TryGetValue(readerName, out readerObj))
            {
                RefreshCaches();
                if (!_readerCache.TryGetValue(readerName, out readerObj))
                {
                    Log("HTTP ingest: unknown reader '{0}'", readerName);
                    return;
                }
            }

            var tagList = ParseTagReads(json);
            if (tagList == null || tagList.Count == 0) return;

            LogDebug("HTTP ingest: processing {0} tag(s) from reader {1}", tagList.Count, readerName);

            int debounceSeconds = int.Parse(Setting("AntennaService_DebounceSeconds", "60"));

            using (var conn = new System.Data.SqlClient.SqlConnection(ConnStr))
            {
                conn.Open();
                foreach (var tag in tagList)
                {
                    int effectiveLocationId = readerObj.LocationId;
                    string effectiveLocationName = readerObj.LocationName;

                    if (tag.AntennaPort > 0)
                    {
                        string antKey = readerObj.ReaderId + ":" + tag.AntennaPort;
                        AntennaCacheEntry antenna;
                        if (_antennaCache.TryGetValue(antKey, out antenna))
                        {
                            effectiveLocationId = antenna.LocationId;
                            effectiveLocationName = antenna.LocationName;
                            LogTagRead(tag.Epc, tag.AntennaPort, effectiveLocationName);
                        }
                    }

                    ProcessTag(conn, tag.Epc, readerObj, effectiveLocationId,
                               effectiveLocationName, tag.AntennaPort, debounceSeconds);
                }
            }
        }
        catch (Exception ex)
        {
            LogError("HTTP ingest processing error", ex);
        }
    }

    /// <summary>
    /// Starts the background MQTT listener. Safe to call multiple times.
    /// Also detects and restarts the thread if it died (e.g. IIS app pool recycle
    /// sends ThreadAbortException, leaving _running=true but thread dead).
    /// </summary>
    public static void EnsureStarted()
    {
        // Fast path: running AND thread is alive
        if (_running && _listenerThread != null && _listenerThread.IsAlive) return;
        lock (_startLock)
        {
            // Re-check under lock
            if (_running && _listenerThread != null && _listenerThread.IsAlive) return;

            // Thread died (e.g. ThreadAbortException from IIS recycle) — reset flag
            if (_running && (_listenerThread == null || !_listenerThread.IsAlive))
            {
                Log("AntennaLocationService thread died — restarting");
                _running = false;
            }

            bool enabled = Setting("AntennaService_Enabled", "true")
                .Equals("true", StringComparison.OrdinalIgnoreCase);
            if (!enabled)
            {
                Log("AntennaLocationService is DISABLED (AntennaService_Enabled=false)");
                return;
            }

            _running = true;
            _startedUtc = DateTime.UtcNow;

            _listenerThread = new Thread(ListenerLoop)
            {
                IsBackground = true,   // dies with w3wp.exe
                Name = "AntennaLocationService",
                Priority = ThreadPriority.BelowNormal
            };
            _listenerThread.Start();
            Log("AntennaLocationService started (background thread)");
        }
    }

    /// <summary>
    /// Returns service status for display in iDash admin panels.
    /// </summary>
    public static object GetStatus()
    {
        return new
        {
            Running = _running,
            StartedUtc = _startedUtc,
            Uptime = _running ? (DateTime.UtcNow - _startedUtc).ToString(@"d\.hh\:mm\:ss") : "stopped",
            ReadersInCache = _readerCache.Count,
            AntennasInCache = _antennaCache.Count,
            MessagesReceived = _messagesReceived,
            LocationUpdates = _locationUpdates,
            CrossSiteMoves = _crossSiteMoves,
            LastError = _lastError,
            LastErrorTime = _lastErrorTime
        };
    }

    // --- MAIN LISTENER LOOP ------------------------------------------
    private static void ListenerLoop()
    {
        string server = Setting("AntennaService_MqttServer", "127.0.0.1");
        int port = int.Parse(Setting("AntennaService_MqttPort", "8883"));
        // UseTls defaults based on port: 8883=TLS, 1883=plain TCP
        bool useTls = Setting("AntennaService_UseTls", port == 8883 ? "true" : "false")
            .Equals("true", StringComparison.OrdinalIgnoreCase);
        string topic = Setting("AntennaService_TopicFilter", "gateway/data/#");
        int cacheMinutes = int.Parse(Setting("AntennaService_CacheMinutes", "5"));
        string mqttUser = Setting("AntennaService_MqttUsername", "MasterPrint");
        string mqttPass = Setting("AntennaService_MqttPassword", "V5MqttPrint2026!");

        Log("Loading reader/antenna caches...");
        RefreshCaches();

        while (_running)
        {
            TcpClient tcp = null;
            try
            {
                // Connect to MQTT broker using raw TCP/TLS (same as MqttPrintNotifier)
                tcp = new TcpClient();
                tcp.ConnectAsync(server, port).Wait(5000);
                if (!tcp.Connected)
                {
                    Log("MQTT connect failed to {0}:{1} -- retrying in 10s", server, port);
                    Thread.Sleep(10000);
                    continue;
                }

                Stream ssl;
                if (useTls)
                {
                    var sslStream = new SslStream(tcp.GetStream(), false,
                        (sender, cert, chain, errors) => true);  // Accept self-signed
                    sslStream.AuthenticateAsClient(server);
                    ssl = sslStream;
                }
                else
                {
                    ssl = tcp.GetStream();  // Plain TCP for RabbitMQ on port 1883
                }

                // MQTT CONNECT packet (with credentials -- broker requires auth)
                // Append unique per-startup suffix so overlapping IIS app pool
                // instances don't kick each other off the broker.
                string clientId = "iDashAntenna_" + Environment.MachineName + "_" + _instanceId;
                SendMqttConnect(ssl, clientId, mqttUser, mqttPass);
                ReadMqttConnAck(ssl);
                Log("MQTT connected to {0}:{1}", server, port);

                // MQTT SUBSCRIBE to topic
                SendMqttSubscribe(ssl, topic, 1);
                ReadMqttSubAck(ssl);
                Log("Subscribed to {0} -- ready for tag reads ({1} readers, {2} antennas)",
                    topic, _readerCache.Count, _antennaCache.Count);

                // Read loop -- process incoming PUBLISH messages
                DateTime lastCacheRefresh = DateTime.UtcNow;
                DateTime lastDebounceClean = DateTime.UtcNow;
                DateTime lastPingReq = DateTime.UtcNow;

                while (_running && tcp.Connected)
                {
                    // Non-blocking check for data (100ms timeout)
                    if (tcp.Available > 0 || ssl.CanRead)
                    {
                        try
                        {
                            byte[] packet = ReadMqttPacket(ssl, tcp);
                            if (packet != null && packet.Length > 0)
                            {
                                int packetType = (packet[0] >> 4) & 0x0F;
                                if (packetType == 3) // PUBLISH
                                {
                                    ProcessPublish(packet);
                                }
                                else if (packetType == 13) // PINGRESP
                                {
                                    // Expected response to our PINGREQ
                                }
                            }
                        }
                        catch (IOException) { break; } // Connection lost
                        catch (Exception ex)
                        {
                            LogError("Error reading MQTT packet", ex);
                        }
                    }
                    else
                    {
                        Thread.Sleep(100); // No data available, brief wait
                    }

                    // Periodic PINGREQ to keep connection alive (every 30s)
                    if ((DateTime.UtcNow - lastPingReq).TotalSeconds >= 30)
                    {
                        try { SendMqttPingReq(ssl); } catch { break; }
                        lastPingReq = DateTime.UtcNow;
                    }

                    // Periodic cache refresh
                    if ((DateTime.UtcNow - lastCacheRefresh).TotalMinutes >= cacheMinutes)
                    {
                        RefreshCaches();
                        lastCacheRefresh = DateTime.UtcNow;
                    }

                    // Periodic debounce cleanup (every 5 min)
                    if ((DateTime.UtcNow - lastDebounceClean).TotalMinutes >= 5)
                    {
                        var cutoff = DateTime.UtcNow.AddMinutes(-10);
                        foreach (var kv in _debounce.Where(x => x.Value < cutoff).ToList())
                        {
                            DateTime removed;
                            _debounce.TryRemove(kv.Key, out removed);
                        }
                        lastDebounceClean = DateTime.UtcNow;
                    }
                }

                Log("MQTT connection closed, reconnecting...");
            }
            catch (Exception ex)
            {
                LogError("MQTT connection error", ex);
            }
            finally
            {
                try { if (tcp != null) tcp.Close(); } catch { }
            }

            // Wait before reconnecting
            Thread.Sleep(5000);
        }
    }

    // --- MQTT PROTOCOL (raw packets) ---------------------------------
    // Minimal MQTT 3.1.1 implementation -- CONNECT, SUBSCRIBE, read PUBLISH

    private static void SendMqttConnect(Stream ssl, string clientId, string username, string password)
    {
        var payload = new List<byte>();

        // Variable header: Protocol name + level + flags + keepalive
        payload.AddRange(MqttString("MQTT"));    // Protocol name
        payload.Add(0x04);                        // Protocol level (3.1.1)
        payload.Add(0xC2);                        // Connect flags: Clean Session + Username + Password
        payload.Add(0x00); payload.Add(0x3C);    // Keepalive: 60 seconds

        // Payload: Client ID, Username, Password
        payload.AddRange(MqttString(clientId));
        payload.AddRange(MqttString(username));
        payload.AddRange(MqttString(password));

        WriteMqttPacket(ssl, 0x10, payload.ToArray()); // CONNECT = 0x10
    }

    private static void ReadMqttConnAck(Stream ssl)
    {
        byte[] resp = new byte[4];
        int read = ssl.Read(resp, 0, 4);
        if (read < 4 || resp[0] != 0x20)
            throw new Exception("MQTT CONNACK failed");
        if (resp[3] != 0x00)
            throw new Exception("MQTT CONNACK returned error code: " + resp[3]);
    }

    private static void SendMqttSubscribe(Stream ssl, string topic, ushort packetId)
    {
        var payload = new List<byte>();
        payload.Add((byte)(packetId >> 8));
        payload.Add((byte)(packetId & 0xFF));
        payload.AddRange(MqttString(topic));
        payload.Add(0x00); // QoS 0

        WriteMqttPacket(ssl, 0x82, payload.ToArray()); // SUBSCRIBE = 0x82
    }

    /// <summary>MQTT PINGREQ (0xC0 0x00) -- keeps the broker from closing idle connections.</summary>
    private static void SendMqttPingReq(Stream ssl)
    {
        byte[] ping = new byte[] { 0xC0, 0x00 };
        ssl.Write(ping, 0, ping.Length);
        ssl.Flush();
    }

    private static void ReadMqttSubAck(Stream ssl)
    {
        byte[] header = new byte[2];
        ssl.Read(header, 0, 2);
        if (header[0] != 0x90) return; // Not SUBACK

        int remLen = header[1];
        byte[] rest = new byte[remLen];
        ssl.Read(rest, 0, remLen);
    }

    private static byte[] ReadMqttPacket(Stream ssl, TcpClient tcp)
    {
        // Set read timeout
        ssl.ReadTimeout = 200;

        try
        {
            // Read fixed header (1 byte type + variable length)
            byte[] typeByte = new byte[1];
            int read = ssl.Read(typeByte, 0, 1);
            if (read == 0) return null;

            // Decode remaining length (variable-length encoding)
            int multiplier = 1;
            int remainingLength = 0;
            byte encoded;
            do
            {
                byte[] b = new byte[1];
                ssl.Read(b, 0, 1);
                encoded = b[0];
                remainingLength += (encoded & 127) * multiplier;
                multiplier *= 128;
            } while ((encoded & 128) != 0);

            // Read the remaining payload
            byte[] body = new byte[remainingLength];
            int totalRead = 0;
            while (totalRead < remainingLength)
            {
                int n = ssl.Read(body, totalRead, remainingLength - totalRead);
                if (n == 0) break;
                totalRead += n;
            }

            // Combine into full packet
            var packet = new byte[1 + remainingLength];
            packet[0] = typeByte[0];
            Array.Copy(body, 0, packet, 1, totalRead);
            return packet;
        }
        catch (IOException)
        {
            return null; // Timeout -- no data available
        }
    }

    private static void WriteMqttPacket(Stream ssl, byte packetType, byte[] payload)
    {
        var packet = new List<byte>();
        packet.Add(packetType);

        // Encode remaining length
        int length = payload.Length;
        do
        {
            byte b = (byte)(length % 128);
            length = length / 128;
            if (length > 0) b |= 0x80;
            packet.Add(b);
        } while (length > 0);

        packet.AddRange(payload);
        var data = packet.ToArray();
        ssl.Write(data, 0, data.Length);
        ssl.Flush();
    }

    private static byte[] MqttString(string s)
    {
        byte[] utf8 = Encoding.UTF8.GetBytes(s);
        var result = new List<byte>();
        result.Add((byte)(utf8.Length >> 8));
        result.Add((byte)(utf8.Length & 0xFF));
        result.AddRange(utf8);
        return result.ToArray();
    }

    // --- PUBLISH HANDLER ---------------------------------------------
    private static void ProcessPublish(byte[] packet)
    {
        try
        {
            Interlocked.Increment(ref _messagesReceived);

            // Parse PUBLISH packet: fixed header already in packet[0]
            int idx = 1;

            // Topic length (MSB + LSB)
            int topicLen = (packet[1] << 8) | packet[2];
            string topic = Encoding.UTF8.GetString(packet, 3, topicLen);

            // Payload starts after topic (no packet ID for QoS 0)
            int payloadStart = 3 + topicLen;
            string payload = Encoding.UTF8.GetString(packet, payloadStart, packet.Length - payloadStart);

            LogDebug("MQTT message on topic: {0} ({1} bytes payload)", topic, payload.Length);

            // Capture raw message for diagnostic spy buffer (before any parsing)
            bool parsedOk = false;
            _rawFeed.Enqueue(new RawMqttMessage
            {
                Ts      = DateTime.UtcNow.ToString("o"),
                Topic   = topic,
                Payload = payload.Length > 1000 ? payload.Substring(0, 1000) + "..." : payload,
                Bytes   = payload.Length,
                Parsed  = false  // updated below if parsing succeeds
            });
            while (_rawFeed.Count > RawFeedMaxSize)
            {
                RawMqttMessage discard;
                _rawFeed.TryDequeue(out discard);
            }

            // Parse the JSON payload
            var serializer = new JavaScriptSerializer();
            var jsonObj = serializer.Deserialize<Dictionary<string, object>>(payload);
            if (jsonObj == null) return;

            // Extract reader name: try topic first (gateway/data/READER_NAME),
            // then fall back to JSON payload fields (reader/tagobservation format)
            string readerName = null;

            // Method 1: from topic path (last segment of gateway/data/READER_NAME)
            var parts = topic.Split('/');
            if (parts.Length >= 3 && parts[0].Equals("gateway", StringComparison.OrdinalIgnoreCase))
            {
                readerName = parts[parts.Length - 1];
            }

            // Method 2: from JSON payload (Zebra IoT Connector format)
            if (string.IsNullOrEmpty(readerName) || !_readerCache.ContainsKey(readerName))
            {
                // Try common fields: hostname, hostName, readerName, reader, deviceName, physicalId
                readerName = GetStr(jsonObj, "hostname")
                          ?? GetStr(jsonObj, "hostName")
                          ?? GetStr(jsonObj, "readerName")
                          ?? GetStr(jsonObj, "reader")
                          ?? GetStr(jsonObj, "deviceName")
                          ?? GetStr(jsonObj, "physicalId");

                // Also check nested: data.hostName, data.hostname, data.readerName
                if (string.IsNullOrEmpty(readerName) && jsonObj.ContainsKey("data") && jsonObj["data"] is Dictionary<string, object>)
                {
                    Dictionary<string, object> data = (Dictionary<string, object>)jsonObj["data"];
                    readerName = GetStr(data, "hostName")
                              ?? GetStr(data, "hostname")
                              ?? GetStr(data, "readerName")
                              ?? GetStr(data, "reader");
                }
            }

            if (string.IsNullOrEmpty(readerName))
            {
                Log("Could not determine reader name from topic '{0}' or payload", topic);
                return;
            }

            // Look up reader
            ReaderCacheEntry reader;
            if (!_readerCache.TryGetValue(readerName, out reader))
            {
                RefreshCaches();
                if (!_readerCache.TryGetValue(readerName, out reader))
                {
                    // Fuzzy match: MQTT sends "FX9600F78C85" but DB stores "FX9600_F78C85"
                    string stripped = System.Text.RegularExpressions.Regex.Replace(readerName, "[_\\-]", "");
                    foreach (var kvp in _readerCache)
                    {
                        string dbStripped = System.Text.RegularExpressions.Regex.Replace(kvp.Key, "[_\\-]", "");
                        if (string.Equals(stripped, dbStripped, StringComparison.OrdinalIgnoreCase))
                        {
                            reader = kvp.Value;
                            LogDebug("Fuzzy matched reader: MQTT '{0}' -> DB '{1}'", readerName, kvp.Key);
                            break;
                        }
                    }
                    if (reader == null)
                    {
                        Log("Unknown reader: {0} (not in dbo.reader)", readerName);
                        return;
                    }
                }
            }

            // Parse tags from JSON
            var tags = ParseTagReads(payload);
            if (tags == null || tags.Count == 0) return;

            LogDebug("Processing {0} tag(s) from reader {1}", tags.Count, readerName);

            int debounceSeconds = int.Parse(Setting("AntennaService_DebounceSeconds", "60"));

            // Process each tag
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Update reader's lastseen so iDash shows it as Online
                // (mirrors the same pattern in the HTTP ingest path)
                try
                {
                    using (var upd = new SqlCommand(
                        "UPDATE dbo.reader SET lastseen=SYSDATETIMEOFFSET() WHERE id=@rid", conn))
                    {
                        upd.Parameters.AddWithValue("@rid", reader.ReaderId);
                        upd.ExecuteNonQuery();
                    }
                }
                catch { /* non-critical */ }

                foreach (var tag in tags)
                {
                    int effectiveLocationId = reader.LocationId;
                    string effectiveLocationName = reader.LocationName;

                    // Antenna-aware: look up antenna location
                    if (tag.AntennaPort > 0)
                    {
                        string antKey = reader.ReaderId + ":" + tag.AntennaPort;
                        AntennaCacheEntry antenna;
                        if (_antennaCache.TryGetValue(antKey, out antenna))
                        {
                            effectiveLocationId = antenna.LocationId;
                            effectiveLocationName = antenna.LocationName;
                            LogTagRead(tag.Epc, tag.AntennaPort, effectiveLocationName);
                        }
                    }

                    ProcessTag(conn, tag.Epc, reader, effectiveLocationId,
                               effectiveLocationName, tag.AntennaPort, debounceSeconds);
                }
            }
        }
        catch (Exception ex)
        {
            LogError("Error processing PUBLISH", ex);
        }
    }

    // --- TAG PROCESSING ----------------------------------------------
    private static void ProcessTag(SqlConnection conn, string tagHex,
        ReaderCacheEntry reader, int locationId, string locationName,
        int antennaPort, int debounceSeconds)
    {
        try
        {
            // Look up asset by RFID tag
            long assetId = 0;
            string assetName = "";
            int assetCompany = 0;
            int currentLocationId = 0;
            string assignedLocationName = "";
            bool provisioned = false;

            using (var cmd = new SqlCommand(
                @"SELECT a.id, a.name, a.companyid, a.locationid, l.name AS locationname
                  FROM dbo.asset a
                  LEFT JOIN dbo.location l ON l.id = a.locationid
                  WHERE a.rfidtag = @tag", conn))
            {
                cmd.Parameters.AddWithValue("@tag", tagHex);
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.HasRows && rdr.Read())
                    {
                        provisioned = true;
                        assetId = Convert.ToInt64(rdr["id"]);
                        assetName = rdr["name"].ToString();
                        assetCompany = Convert.ToInt32(rdr["companyid"]);
                        currentLocationId = rdr["locationid"] != DBNull.Value ? Convert.ToInt32(rdr["locationid"]) : 0;
                        assignedLocationName = rdr["locationname"] != DBNull.Value ? rdr["locationname"].ToString() : "";
                    }
                }
            }

            // --- Always enqueue to live feed regardless of provisioning status ---
            // Unprovisioned tags show as "Unknown Tag" — useful for troubleshooting
            EnqueueLiveEvent(tagHex, assetId,
                provisioned ? assetName : "Unknown Tag",
                provisioned ? "" : "Not provisioned — EPC: " + tagHex,
                reader, antennaPort, locationName,
                false /* locationChanged determined below for provisioned tags */,
                false, "", provisioned ? assignedLocationName : "");

            if (!provisioned) return; // No DB changes for unknown tags

            // Debounce (applies equally to cross-site and same-site)
            string debounceKey = assetId + ":" + locationId;
            DateTime lastTime;
            if (_debounce.TryGetValue(debounceKey, out lastTime)
                && (DateTime.UtcNow - lastTime).TotalSeconds < debounceSeconds)
            {
                return;
            }

            // ───────────────────────────────────────────────────────────
            // Determine cross-site status BEFORE touching the database.
            // Cross-site = asset belongs to a different company than the reader.
            // ───────────────────────────────────────────────────────────
            bool isCrossSite = assetCompany != reader.CompanyId;
            bool locationChanged = currentLocationId != locationId && locationId > 0;
            bool shouldUpdate = !isCrossSite && reader.UpdateLocation;

            if (isCrossSite)
            {
                // Cross-site: ONLY stamp the observation time — never touch
                // lastobservedlocation, locationid, or readerid.
                // This keeps site data completely separated.
                using (var cmd = new SqlCommand(
                    "UPDATE dbo.asset SET lastobservedtime = SYSDATETIMEOFFSET() WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", assetId);
                    cmd.ExecuteNonQuery();
                }

                _debounce[debounceKey] = DateTime.UtcNow;

                // Look up the asset's home site name for logging / live feed
                string assetSiteName = "";
                try
                {
                    using (var sc = new SqlCommand(
                        "SELECT name FROM dbo.company WHERE id=@cid", conn))
                    {
                        sc.Parameters.AddWithValue("@cid", assetCompany);
                        var sn = sc.ExecuteScalar();
                        assetSiteName = sn != null ? sn.ToString() : "Site " + assetCompany;
                    }
                }
                catch { assetSiteName = "Site " + assetCompany; }

                LogDebug("Cross-site observation (no DB write): {0} owns '{1}' - detected at {2} (antenna {3})",
                    assetSiteName, assetName, locationName, antennaPort);

                // Show in live feed as a visitor — no location change
                EnqueueLiveEvent(tagHex, assetId, assetName,
                    "Visitor from " + assetSiteName + " — read-only, location NOT changed",
                    reader, antennaPort, locationName,
                    false /* locationChanged */, true /* isCrossSite */, assetSiteName, assignedLocationName);
                return;
            }

            // ───────────────────────────────────────────────────────────
            // Same-site asset: update lastobservedtime + lastobservedlocation
            // ───────────────────────────────────────────────────────────
            using (var cmd = new SqlCommand(@"UPDATE dbo.asset
                SET lastobservedtime = SYSDATETIMEOFFSET(),
                    lastobservedlocation = @loc,
                    readerid = @readerId
                WHERE id = @id", conn))
            {
                cmd.Parameters.AddWithValue("@loc", locationName);
                cmd.Parameters.AddWithValue("@readerId", reader.ReaderId);
                cmd.Parameters.AddWithValue("@id", assetId);
                cmd.ExecuteNonQuery();
            }

            _debounce[debounceKey] = DateTime.UtcNow;

            if (locationChanged && shouldUpdate)
            {
                // Close old location history
                using (var cmd = new SqlCommand(@"UPDATE dbo.locationhistory
                    SET timeleft = SYSDATETIMEOFFSET()
                    WHERE assetid = @assetId AND timeleft IS NULL", conn))
                {
                    cmd.Parameters.AddWithValue("@assetId", assetId);
                    cmd.ExecuteNonQuery();
                }

                // Insert new location history entry — use asset's companyId for consistency
                using (var cmd = new SqlCommand(@"INSERT INTO dbo.locationhistory
                    (assetid, locationid, companyid, timeseen)
                    VALUES (@assetId, @locId, @companyId, SYSDATETIMEOFFSET())", conn))
                {
                    cmd.Parameters.AddWithValue("@assetId", assetId);
                    cmd.Parameters.AddWithValue("@locId", locationId);
                    cmd.Parameters.AddWithValue("@companyId", assetCompany);
                    cmd.ExecuteNonQuery();
                }

                // Update the asset's assigned location
                using (var cmd = new SqlCommand(@"UPDATE dbo.asset
                    SET locationid = @locId,
                        lastmodified = SYSDATETIMEOFFSET(),
                        lastmodifiedby = 'iDashAntenna'
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@locId", locationId);
                    cmd.Parameters.AddWithValue("@id", assetId);
                    cmd.ExecuteNonQuery();
                }

                Interlocked.Increment(ref _locationUpdates);

                Log("Antenna-aware move: {0} -> {1} via antenna {2} (reader {3})",
                    assetName, locationName, antennaPort, reader.PhysicalId);
            }

            // Enqueue same-site live feed event
            EnqueueLiveEvent(tagHex, assetId, assetName, "", reader,
                antennaPort, locationName, locationChanged && shouldUpdate,
                false /* isCrossSite */, "", assignedLocationName);
        }
        catch (Exception ex)
        {
            LogError("Error processing tag " + tagHex, ex);
        }
    }

    /// <summary>
    /// Parse tag reads from the FX9600 Local_HTTP_POST array format:
    /// [{"data":{"idHex":"EPC","antennaPort":1,"format":"epc"},"timestamp":"...","type":"SIMPLE"},...]
    /// </summary>
    private static List<TagRead> ParseTagReadsFromArray(object[] arr)
    {
        var tags = new List<TagRead>();
        if (arr == null) return tags;
        foreach (var item in arr)
        {
            if (!(item is Dictionary<string, object>)) continue;
            var element = (Dictionary<string, object>)item;

            // Each element has a "data" object with the tag info
            Dictionary<string, object> data = null;
            if (element.ContainsKey("data") && element["data"] is Dictionary<string, object>)
                data = (Dictionary<string, object>)element["data"];

            if (data == null) continue;

            // EPC from idHex, epcHex, epc, or tagId
            string epc = GetStr(data, "idHex") ?? GetStr(data, "epcHex")
                      ?? GetStr(data, "epc") ?? GetStr(data, "tagId");
            if (string.IsNullOrEmpty(epc)) continue;

            // Antenna port -- try multiple field names
            int ant = GetInt(data, "antennaPort", GetInt(data, "antenna",
                       GetInt(data, "antennaId", GetInt(data, "portNumber", 0))));

            // Also check top-level element for antenna
            if (ant == 0)
                ant = GetInt(element, "antennaPort", GetInt(element, "antenna", 0));

            tags.Add(new TagRead { Epc = epc.ToUpperInvariant(), AntennaPort = ant });
        }
        return tags;
    }

    private static List<TagRead> ParseTagReads(string json)
    {
        var tags = new List<TagRead>();
        try
        {
            var serializer = new JavaScriptSerializer();
            var obj = serializer.Deserialize<Dictionary<string, object>>(json);
            if (obj == null) return tags;

            // Format 1: { "tagReads": [{ "epc": "HEX", "antenna": 1 }] }
            if (obj.ContainsKey("tagReads") && obj["tagReads"] is object[])
            {
                object[] reads = (object[])obj["tagReads"];
                foreach (var r in reads)
                {
                    if (r is Dictionary<string, object>)
                    {
                        Dictionary<string, object> d = (Dictionary<string, object>)r;
                        string epc = d.ContainsKey("epc") && d["epc"] != null ? d["epc"].ToString() : null;
                        if (string.IsNullOrEmpty(epc)) continue;
                        int ant = GetInt(d, "antenna", GetInt(d, "antennaPort", 0));
                        tags.Add(new TagRead { Epc = epc, AntennaPort = ant });
                    }
                }
            }
            // Format 2: { "data": { "inventoryData": [...] } }
            else if (obj.ContainsKey("data") && obj["data"] is Dictionary<string, object>)
            {
                Dictionary<string, object> data = (Dictionary<string, object>)obj["data"];
                if (data.ContainsKey("inventoryData") && data["inventoryData"] is object[])
                {
                    object[] inv = (object[])data["inventoryData"];
                    foreach (var item in inv)
                    {
                        if (item is Dictionary<string, object>)
                        {
                            Dictionary<string, object> d = (Dictionary<string, object>)item;
                            string epc = GetStr(d, "epcHex") ?? GetStr(d, "epc") ?? GetStr(d, "tagId");
                            if (string.IsNullOrEmpty(epc)) continue;
                            int ant = GetInt(d, "antennaPort", GetInt(d, "antenna", 0));
                            tags.Add(new TagRead { Epc = epc, AntennaPort = ant });
                        }
                    }
                }
                // Format 4: FX9600 MQTT single-tag: { "data": { "idHex": "EPC", "antenna": 1 }, "type": "INVENTORY" }
                else
                {
                    string epc = GetStr(data, "idHex") ?? GetStr(data, "epcHex")
                              ?? GetStr(data, "epc") ?? GetStr(data, "tagId");
                    if (!string.IsNullOrEmpty(epc))
                    {
                        int ant = GetInt(data, "antenna", GetInt(data, "antennaPort", 0));
                        tags.Add(new TagRead { Epc = epc.ToUpperInvariant(), AntennaPort = ant });
                    }
                }
            }
            // Format 3: { "epc": "HEX", "antenna": 1 } (single tag)
            else if (obj.ContainsKey("epc"))
            {
                string epc = obj["epc"] != null ? obj["epc"].ToString() : null;
                if (!string.IsNullOrEmpty(epc))
                {
                    int ant = GetInt(obj, "antenna", GetInt(obj, "antennaPort", 0));
                    tags.Add(new TagRead { Epc = epc, AntennaPort = ant });
                }
            }
        }
        catch (Exception ex)
        {
            LogError("Failed to parse tag JSON", ex);
        }
        return tags;
    }

    private static string GetStr(Dictionary<string, object> d, string key)
    {
        object val;
        return d.TryGetValue(key, out val) && val != null ? val.ToString() : null;
    }

    private static int GetInt(Dictionary<string, object> d, string key, int defaultVal)
    {
        object val;
        if (!d.TryGetValue(key, out val) || val == null) return defaultVal;
        int result;
        return int.TryParse(val.ToString(), out result) ? result : defaultVal;
    }

    // --- CACHE MANAGEMENT --------------------------------------------
    private static void RefreshCaches()
    {
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Readers
                using (var cmd = new SqlCommand(@"SELECT r.id, r.physicalid, r.companyid, r.locationid,
                    r.devicesettings, l.name AS locationName
                    FROM dbo.reader r
                    INNER JOIN dbo.location l ON r.locationid = l.id
                    WHERE r.physicalid IS NOT NULL AND r.physicalid <> ''", conn))
                {
                    using (var rdr = cmd.ExecuteReader())
                    {
                        int count = 0;
                        while (rdr.Read())
                        {
                            string pid = rdr["physicalid"].ToString();
                            bool updateLoc = false;
                            string ds = rdr["devicesettings"] != DBNull.Value ? rdr["devicesettings"].ToString() : "";
                            if (!string.IsNullOrEmpty(ds))
                            {
                                try
                                {
                                    var ser = new JavaScriptSerializer();
                                    var dsObj = ser.Deserialize<Dictionary<string, object>>(ds);
                                    if (dsObj != null && dsObj.ContainsKey("updateLocation"))
                                    {
                                        bool.TryParse(dsObj["updateLocation"].ToString(), out updateLoc);
                                    }
                                }
                                catch { }
                            }

                            _readerCache[pid] = new ReaderCacheEntry
                            {
                                ReaderId = Convert.ToInt32(rdr["id"]),
                                PhysicalId = pid,
                                CompanyId = Convert.ToInt32(rdr["companyid"]),
                                LocationId = Convert.ToInt32(rdr["locationid"]),
                                LocationName = rdr["locationName"].ToString(),
                                UpdateLocation = updateLoc
                            };
                            count++;
                        }
                        LogDebug("Loaded {0} reader(s) into cache", count);
                    }
                }

                // Antennas
                using (var cmd = new SqlCommand(@"SELECT a.id, a.number, a.readerid, a.locationid,
                    l.name AS locationName
                    FROM dbo.antenna a
                    INNER JOIN dbo.location l ON a.locationid = l.id
                    WHERE a.locationid IS NOT NULL", conn))
                {
                    using (var rdr = cmd.ExecuteReader())
                    {
                        _antennaCache.Clear();
                        int count = 0;
                        while (rdr.Read())
                        {
                            int readerId = Convert.ToInt32(rdr["readerid"]);
                            int portNum = Convert.ToInt32(rdr["number"]);
                            string key = readerId + ":" + portNum;
                            _antennaCache[key] = new AntennaCacheEntry
                            {
                                AntennaId = Convert.ToInt32(rdr["id"]),
                                Port = portNum,
                                ReaderId = readerId,
                                LocationId = Convert.ToInt32(rdr["locationid"]),
                                LocationName = rdr["locationName"].ToString()
                            };
                            count++;
                        }
                        LogDebug("Loaded {0} antenna(s) into cache", count);
                    }
                }
            }
            _lastCacheRefresh = DateTime.UtcNow;
        }
        catch (Exception ex)
        {
            LogError("Failed to refresh caches", ex);
        }
    }

    // --- LOGGING (with rotation & levels) ---------------------------------

    private static readonly string LogPath = @"C:\Logs\iDash_AntennaService.log";
    private const long MaxLogSize = 5 * 1024 * 1024;  // 5 MB per file
    private const int MaxRotatedFiles = 3;              // keep .1, .2, .3

    // Log levels: 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG
    private static int _logLevel = 2; // default INFO
    private static DateTime _logLevelLastRead = DateTime.MinValue;

    // Buffered write — flush every 5 seconds instead of per-line
    private static readonly object _logLock = new object();
    private static System.Text.StringBuilder _logBuffer = new System.Text.StringBuilder();
    private static DateTime _lastFlush = DateTime.UtcNow;
    private const int FlushIntervalMs = 5000;

    // Rate-limit tag logging at DEBUG level: only log unique tag+antenna once per 60s
    private static readonly Dictionary<string, DateTime> _tagLogThrottle = new Dictionary<string, DateTime>();
    private static DateTime _lastThrottleClean = DateTime.UtcNow;

    private static int GetLogLevel()
    {
        // Re-read from web.config every 60 seconds
        if ((DateTime.UtcNow - _logLevelLastRead).TotalSeconds > 60)
        {
            _logLevelLastRead = DateTime.UtcNow;
            string val = Setting("AntennaService_LogLevel", "INFO").ToUpper();
            switch (val)
            {
                case "ERROR": _logLevel = 0; break;
                case "WARN":  _logLevel = 1; break;
                case "INFO":  _logLevel = 2; break;
                case "DEBUG": _logLevel = 3; break;
                default:      _logLevel = 2; break;
            }
        }
        return _logLevel;
    }

    private static void Log(string format, params object[] args)
    {
        LogAtLevel(2, "INFO", format, args); // default = INFO
    }

    private static void LogDebug(string format, params object[] args)
    {
        LogAtLevel(3, "DEBUG", format, args);
    }

    private static void LogWarn(string format, params object[] args)
    {
        LogAtLevel(1, "WARN", format, args);
    }

    private static void LogError(string context, Exception ex)
    {
        _lastError = context + ": " + ex.Message;
        _lastErrorTime = DateTime.UtcNow;
        LogAtLevel(0, "ERROR", "{0}: {1}", context, ex.Message);
    }

    /// <summary>Log a tag read, but throttle to once per tag+antenna per 60s at DEBUG level.</summary>
    private static void LogTagRead(string epc, int antennaPort, string location)
    {
        if (GetLogLevel() < 3) return; // DEBUG only

        string key = epc + ":" + antennaPort;
        lock (_tagLogThrottle)
        {
            DateTime lastLog;
            if (_tagLogThrottle.TryGetValue(key, out lastLog) && (DateTime.UtcNow - lastLog).TotalSeconds < 60)
                return; // throttled
            _tagLogThrottle[key] = DateTime.UtcNow;

            // Clean throttle cache every 5 minutes
            if ((DateTime.UtcNow - _lastThrottleClean).TotalMinutes > 5)
            {
                _lastThrottleClean = DateTime.UtcNow;
                var stale = new List<string>();
                foreach (var kv in _tagLogThrottle)
                    if ((DateTime.UtcNow - kv.Value).TotalMinutes > 5) stale.Add(kv.Key);
                foreach (var s in stale) _tagLogThrottle.Remove(s);
            }
        }
        LogAtLevel(3, "DEBUG", "Tag {0} ant {1} -> {2}", epc, antennaPort, location);
    }

    private static void LogAtLevel(int level, string label, string format, params object[] args)
    {
        if (GetLogLevel() < level) return;

        string msg;
        try { msg = string.Format(format, args); }
        catch { msg = format; }

        string line = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " [" + label + "] " + msg;

        lock (_logLock)
        {
            _logBuffer.AppendLine(line);

            // Flush if buffer is large or interval elapsed
            if (_logBuffer.Length > 8192 || (DateTime.UtcNow - _lastFlush).TotalMilliseconds > FlushIntervalMs)
                FlushLog();
        }
    }

    private static void FlushLog()
    {
        // Must be called under _logLock
        if (_logBuffer.Length == 0) return;

        string text = _logBuffer.ToString();
        _logBuffer.Clear();
        _lastFlush = DateTime.UtcNow;

        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(LogPath));

            // Rotate if over size limit
            if (File.Exists(LogPath))
            {
                var fi = new FileInfo(LogPath);
                if (fi.Length > MaxLogSize)
                    RotateLog();
            }

            File.AppendAllText(LogPath, text);
        }
        catch { }
    }

    private static void RotateLog()
    {
        try
        {
            // Delete oldest
            string oldest = LogPath + "." + MaxRotatedFiles;
            if (File.Exists(oldest)) File.Delete(oldest);

            // Shift existing .1 -> .2, .2 -> .3, etc.
            for (int i = MaxRotatedFiles - 1; i >= 1; i--)
            {
                string src = LogPath + "." + i;
                string dst = LogPath + "." + (i + 1);
                if (File.Exists(src)) File.Move(src, dst);
            }

            // Move current to .1
            if (File.Exists(LogPath)) File.Move(LogPath, LogPath + ".1");
        }
        catch { }
    }
}
