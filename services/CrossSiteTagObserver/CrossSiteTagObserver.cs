// ═══════════════════════════════════════════════════════════════════════
// CrossSiteTagObserver — Windows Service
// ═══════════════════════════════════════════════════════════════════════
//
// PURPOSE:  Subscribes to MQTT tag data from fixed RFID readers and
//           performs BOTH cross-company asset matching AND antenna-aware
//           location updates.
//
//           The system only matches tags within the reader's
//           own company and uses reader-level locations (ignoring antenna
//           locations).  This service fills BOTH gaps:
//
//           1. Cross-site:  Updates lastobservedtime/lastobservedlocation
//              for tags from OTHER companies.
//           2. Antenna-aware: When a reader has antennas with distinct
//              locations, uses the antenna's location instead of the
//              reader's location — enabling per-antenna precision.
//
// PATTERN:  Identical to the iDash Print Service:
//           MQTT listener → SQL lookup → conditional DB update.
//
// INSTALL:  sc create "CrossSiteTagObserver" binPath="..." start=auto
//
// LOG:      C:\Logs\CrossSiteObserver_log.txt (rolling daily)
//
// AUTHOR:   iDash Development Team
// DATE:     August 2026
// ═══════════════════════════════════════════════════════════════════════

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MQTTnet;
using MQTTnet.Client;
using Newtonsoft.Json.Linq;

namespace CrossSiteTagObserver
{
    // ─── PROGRAM ENTRY ─────────────────────────────────────────────────
    // We bypass the .NET Generic Host entirely. The Host's ConsoleLifetime
    // detects stdin EOF (from Start-Process redirect) and fires StopApplication(),
    // which cancels the CancellationToken, which throws in Task.Delay(),
    // which causes BackgroundServiceExceptionBehavior.StopHost to exit.
    //
    // Instead we build IConfiguration manually, create the service, and
    // run it directly with our own infinite-wait keep-alive.
    // ───────────────────────────────────────────────────────────────────
    public class Program
    {
        public static void Main(string[] args)
        {
            // Redirect Console.Out to NUL to prevent broken pipe crashes
            // when the parent process (Start-Process) closes stdout handles.
            try { Console.SetOut(System.IO.TextWriter.Null); } catch { }
            try { Console.SetError(System.IO.TextWriter.Null); } catch { }

            // Build configuration from appsettings.json
            var config = new ConfigurationBuilder()
                .SetBasePath(AppContext.BaseDirectory)
                .AddJsonFile("appsettings.json", optional: true)
                .Build();

            // Set up file-based logging (no Console logger — it crashes on broken pipe)
            string logPath = @"C:\Logs\CrossSiteObserver.log";
            try { System.IO.Directory.CreateDirectory(@"C:\Logs"); } catch { }
            using var loggerFactory = LoggerFactory.Create(builder =>
            {
                builder.SetMinimumLevel(LogLevel.Information);
                builder.AddProvider(new FileLoggerProvider(logPath));
            });
            var logger = loggerFactory.CreateLogger<TagObserverService>();

            logger.LogInformation("=== CrossSiteTagObserver starting (PID {Pid}) ===", Environment.ProcessId);

            // Create and start the service (pass a never-cancelled token)
            var cts = new CancellationTokenSource();
            var service = new TagObserverService(logger, config);

            // Start on a background thread
            var task = Task.Run(async () =>
            {
                while (true)
                {
                    try
                    {
                        await service.StartObserving(cts.Token);
                    }
                    catch (Exception ex)
                    {
                        logger.LogCritical(ex, "Service crashed — will restart in 10s");
                        await Task.Delay(10000);
                    }
                }
            });

            // Block the main thread forever
            Thread.Sleep(Timeout.Infinite);
        }
    }

    // ─── SIMPLE FILE LOGGER ───────────────────────────────────────────
    // Writes log lines to a file. No Console dependency.
    public class FileLoggerProvider : ILoggerProvider
    {
        private readonly string _path;
        private readonly object _lock = new();
        public FileLoggerProvider(string path) { _path = path; }
        public ILogger CreateLogger(string category) => new FileLogger(_path, category, _lock);
        public void Dispose() { }
    }

    public class FileLogger : ILogger
    {
        private readonly string _path, _category;
        private readonly object _lock;
        public FileLogger(string path, string category, object lockObj)
        { _path = path; _category = category; _lock = lockObj; }

        public IDisposable BeginScope<TState>(TState state) => null;
        public bool IsEnabled(LogLevel logLevel) => logLevel >= LogLevel.Information;
        public void Log<TState>(LogLevel level, EventId eventId, TState state,
            Exception exception, Func<TState, Exception, string> formatter)
        {
            if (!IsEnabled(level)) return;
            var line = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [{level}] {formatter(state, exception)}";
            if (exception != null) line += Environment.NewLine + exception;
            lock (_lock)
            {
                try { System.IO.File.AppendAllText(_path, line + Environment.NewLine); }
                catch { /* swallow I/O errors to prevent crash */ }
            }
        }
    }

    // ─── READER INFO (cached) ──────────────────────────────────────────
    public class ReaderInfo
    {
        public int ReaderId { get; set; }
        public string PhysicalId { get; set; }
        public int CompanyId { get; set; }
        public int LocationId { get; set; }
        public string LocationName { get; set; }
        public bool UpdateLocation { get; set; }
    }

    // ─── ANTENNA INFO (cached) ─────────────────────────────────────────
    public class AntennaInfo
    {
        public int AntennaId { get; set; }
        public int Port { get; set; }
        public int ReaderId { get; set; }
        public int LocationId { get; set; }
        public string LocationName { get; set; }
    }

    // ─── PARSED TAG READ ───────────────────────────────────────────────
    public class TagRead
    {
        public string Epc { get; set; }
        public int AntennaPort { get; set; }  // 0 = unknown
        public double Rssi { get; set; }
    }

    // ─── MAIN SERVICE ──────────────────────────────────────────────────
    public class TagObserverService
    {
        private readonly ILogger<TagObserverService> _log;
        private readonly IConfiguration _config;

        // Reader cache: physicalId → ReaderInfo
        private readonly ConcurrentDictionary<string, ReaderInfo> _readerCache = new();
        private DateTime _cacheExpiry = DateTime.MinValue;

        // Antenna cache: "readerId:port" → AntennaInfo
        private readonly ConcurrentDictionary<string, AntennaInfo> _antennaCache = new();

        // Debounce: "assetId:locationId" → last update time
        private readonly ConcurrentDictionary<string, DateTime> _lastUpdate = new();

        private IMqttClient _mqtt;

        public TagObserverService(ILogger<TagObserverService> log, IConfiguration config)
        {
            _log = log;
            _config = config;
        }

        // ────────────────────────────────────────────────────────────────
        //  SERVICE LIFECYCLE
        // ────────────────────────────────────────────────────────────────
        public async Task StartObserving(CancellationToken ct)
        {
            var section = _config.GetSection("CrossSiteObserver");
            bool enabled = section.GetValue("Enabled", true);
            if (!enabled)
            {
                _log.LogWarning("Cross-Site Tag Observer is DISABLED in config. Exiting.");
                return;
            }

            _log.LogInformation("Cross-Site Tag Observer starting (antenna-aware mode)...");

            // Load initial caches
            await RefreshReaderCache();
            await RefreshAntennaCache();

            // Connect MQTT
            string server   = section.GetValue("MqttServer", "localhost");
            int    port      = section.GetValue("MqttPort", 8883);
            string user      = section.GetValue("MqttUsername", "CrossSiteObserver");
            string pass      = section.GetValue("MqttPassword", "");
            bool   useTls    = section.GetValue("MqttUseTls", true);
            string topicFilt = section.GetValue("TopicFilter", "gateway/data/#");

            var factory = new MqttFactory();
            _mqtt = factory.CreateMqttClient();

            _mqtt.ApplicationMessageReceivedAsync += OnMessageReceived;
            _mqtt.DisconnectedAsync += async e =>
            {
                if (ct.IsCancellationRequested) return;
                _log.LogWarning("MQTT disconnected: {Reason}. Reconnecting in 5s...",
                    e.Exception?.Message ?? "unknown");
                try { await Task.Delay(5000); } catch { }
                try { await ConnectMqtt(server, port, user, pass, useTls, topicFilt); }
                catch (Exception ex) { _log.LogError(ex, "Reconnect failed"); }
            };

            await ConnectMqtt(server, port, user, pass, useTls, topicFilt);

            _log.LogInformation("Ready. Listening for tag reads on topic: {Topic} (antenna-aware)", topicFilt);

            // Periodic cache refresh — runs forever
            int cacheMinutes = section.GetValue("ReaderCacheMinutes", 5);
            while (!ct.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(TimeSpan.FromMinutes(cacheMinutes));
                    await RefreshReaderCache();
                    await RefreshAntennaCache();

                    // Prune stale debounce entries (older than 10 min)
                    var cutoff = DateTime.UtcNow.AddMinutes(-10);
                    foreach (var kv in _lastUpdate.Where(x => x.Value < cutoff).ToList())
                        _lastUpdate.TryRemove(kv.Key, out _);
                }
                catch (Exception ex)
                {
                    _log.LogError(ex, "Error in cache refresh loop, continuing...");
                    try { await Task.Delay(30000); } catch { }
                }
            }
        }

        private async Task ConnectMqtt(string server, int port, string user, string pass,
                                        bool useTls, string topicFilter)
        {
            var optBuilder = new MqttClientOptionsBuilder()
                .WithTcpServer(server, port)
                .WithCredentials(user, pass)
                .WithClientId("CrossSiteObserver_" + Environment.MachineName);

            if (useTls)
            {
                optBuilder.WithTlsOptions(o =>
                {
                    // Accept self-signed certs (same as Print Server)
                    o.WithCertificateValidationHandler(_ => true);
                });
            }

            await _mqtt.ConnectAsync(optBuilder.Build());
            _log.LogInformation("MQTT connected to {Server}:{Port}", server, port);

            // Subscribe to tag data topic
            await _mqtt.SubscribeAsync(new MqttTopicFilterBuilder()
                .WithTopic(topicFilter)
                .Build());
            _log.LogInformation("Subscribed to {Topic}", topicFilter);
        }

        // ────────────────────────────────────────────────────────────────
        //  MESSAGE HANDLER
        // ────────────────────────────────────────────────────────────────
        private async Task OnMessageReceived(MqttApplicationMessageReceivedEventArgs e)
        {
            try
            {
                string topic = e.ApplicationMessage.Topic;
                string payload = Encoding.UTF8.GetString(e.ApplicationMessage.PayloadSegment);

                _log.LogDebug("MQTT message on topic: {Topic} ({Len} bytes)", topic, payload.Length);

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
                    try
                    {
                        var json = JToken.Parse(payload);
                        readerName = (string)(json["hostname"] ?? json["readerName"] ?? json["reader"]
                                           ?? json["deviceName"] ?? json["physicalId"]);
                        // Also check nested: data.hostname, data.readerName
                        if (string.IsNullOrEmpty(readerName) && json["data"] != null)
                        {
                            readerName = (string)(json["data"]["hostname"] ?? json["data"]["readerName"]
                                               ?? json["data"]["reader"]);
                        }
                    }
                    catch { }
                }

                if (string.IsNullOrEmpty(readerName))
                {
                    _log.LogDebug("Could not determine reader name from topic '{Topic}' or payload", topic);
                    return;
                }

                // Look up reader's info
                if (!_readerCache.TryGetValue(readerName, out var reader))
                {
                    // Unknown reader — might be new. Refresh cache once.
                    await RefreshReaderCache();
                    await RefreshAntennaCache();
                    if (!_readerCache.TryGetValue(readerName, out reader))
                    {
                        _log.LogDebug("Unknown reader: {Reader}", readerName);
                        return;
                    }
                }

                // Parse tag list from JSON (now with antenna info)
                var tagReads = ParseTagReads(payload);
                if (tagReads == null || tagReads.Count == 0) return;

                int debounce = _config.GetSection("CrossSiteObserver")
                                      .GetValue("DebounceSeconds", 60);
                string connStr = _config.GetConnectionString("iDash");

                using var conn = new SqlConnection(connStr);
                await conn.OpenAsync();

                foreach (var tagRead in tagReads)
                {
                    // Determine the effective location based on antenna
                    int effectiveLocationId = reader.LocationId;
                    string effectiveLocationName = reader.LocationName;

                    if (tagRead.AntennaPort > 0)
                    {
                        string antKey = $"{reader.ReaderId}:{tagRead.AntennaPort}";
                        if (_antennaCache.TryGetValue(antKey, out var antenna))
                        {
                            effectiveLocationId = antenna.LocationId;
                            effectiveLocationName = antenna.LocationName;
                            _log.LogDebug("Antenna {Port} → location {Loc} (reader {Reader})",
                                tagRead.AntennaPort, effectiveLocationName, readerName);
                        }
                    }

                    await ProcessTagRead(conn, tagRead.Epc, reader,
                        effectiveLocationId, effectiveLocationName,
                        tagRead.AntennaPort, debounce);
                }
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "Error processing MQTT message");
            }
        }

        // ────────────────────────────────────────────────────────────────
        //  TAG PROCESSING — Antenna-Aware
        // ────────────────────────────────────────────────────────────────
        private async Task ProcessTagRead(SqlConnection conn, string tagHex,
                                           ReaderInfo reader, int locationId,
                                           string locationName, int antennaPort,
                                           int debounce)
        {
            // Look up asset by RFID tag — check ALL companies
            string sql = @"SELECT id, name, companyid, locationid, lastobservedlocation
                           FROM dbo.asset
                           WHERE rfidtag = @tag";

            using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@tag", tagHex);

            long assetId = 0;
            string assetName = "";
            int assetCompany = 0;
            int currentLocationId = 0;
            string currentObsLoc = "";

            using (var rdr = await cmd.ExecuteReaderAsync())
            {
                if (!rdr.HasRows) return; // Unknown tag — system handles "Not Provisioned" events
                if (!await rdr.ReadAsync()) return;

                assetId = Convert.ToInt64(rdr["id"]);
                assetName = rdr["name"].ToString();
                assetCompany = Convert.ToInt32(rdr["companyid"]);
                currentLocationId = rdr["locationid"] != DBNull.Value ? Convert.ToInt32(rdr["locationid"]) : 0;
                currentObsLoc = rdr["lastobservedlocation"] != DBNull.Value ? rdr["lastobservedlocation"].ToString() : "";
            }

            // Debounce check — keyed by assetId + locationId to allow fast updates on moves
            string debounceKey = $"{assetId}:{locationId}";
            if (_lastUpdate.TryGetValue(debounceKey, out var lastTime)
                && (DateTime.UtcNow - lastTime).TotalSeconds < debounce)
            {
                return; // Recently processed this asset at this location
            }

            // ───────────────────────────────────────────────────────────
            // Determine cross-site status BEFORE touching the database.
            // Cross-site = asset belongs to a different company than the reader.
            // ───────────────────────────────────────────────────────────
            bool locationChanged = currentLocationId != locationId && locationId > 0;
            bool isCrossSite = assetCompany != reader.CompanyId;

            if (isCrossSite)
            {
                // Cross-site: ONLY stamp the observation time — never touch
                // lastobservedlocation, locationid, readerid, or locationhistory.
                // This keeps site data completely separated. The asset stays in
                // its home site but is visible in the live feed as a visitor.
                string xsiteSql = @"UPDATE dbo.asset
                                     SET lastobservedtime = SYSDATETIMEOFFSET()
                                     WHERE id = @id";
                using (var upd = new SqlCommand(xsiteSql, conn))
                {
                    upd.Parameters.AddWithValue("@id", assetId);
                    await upd.ExecuteNonQueryAsync();
                }

                _lastUpdate[debounceKey] = DateTime.UtcNow;

                _log.LogInformation(
                    "Cross-site observation (no DB write): co {AssetCo} owns '{Asset}' — detected at {Location} via antenna {Ant} (reader {Reader}, co {ReaderCo})",
                    assetCompany, assetName, locationName, antennaPort, reader.PhysicalId, reader.CompanyId);
                return;
            }

            // ───────────────────────────────────────────────────────────
            // Same-site asset: update lastobservedtime + lastobservedlocation
            // ───────────────────────────────────────────────────────────
            string updateSql = @"UPDATE dbo.asset
                                 SET lastobservedtime = SYSDATETIMEOFFSET(),
                                     lastobservedlocation = @loc,
                                     readerid = @readerId
                                 WHERE id = @id";

            using (var upd = new SqlCommand(updateSql, conn))
            {
                upd.Parameters.AddWithValue("@loc", locationName);
                upd.Parameters.AddWithValue("@readerId", reader.ReaderId);
                upd.Parameters.AddWithValue("@id", assetId);
                await upd.ExecuteNonQueryAsync();
            }

            _lastUpdate[debounceKey] = DateTime.UtcNow;

            bool shouldUpdateLocation = reader.UpdateLocation;

            if (locationChanged && shouldUpdateLocation)
            {
                // Close old location history entry
                string closeHistSql = @"UPDATE dbo.locationhistory
                                        SET timeleft = SYSDATETIMEOFFSET()
                                        WHERE assetid = @assetId
                                          AND timeleft IS NULL";
                using (var closeCmd = new SqlCommand(closeHistSql, conn))
                {
                    closeCmd.Parameters.AddWithValue("@assetId", assetId);
                    await closeCmd.ExecuteNonQueryAsync();
                }

                // Insert new location history entry — use ASSET's companyId, not reader's
                string insertHistSql = @"INSERT INTO dbo.locationhistory
                                         (assetid, locationid, companyid, timeseen)
                                         VALUES (@assetId, @locId, @companyId, SYSDATETIMEOFFSET())";
                using (var insertCmd = new SqlCommand(insertHistSql, conn))
                {
                    insertCmd.Parameters.AddWithValue("@assetId", assetId);
                    insertCmd.Parameters.AddWithValue("@locId", locationId);
                    insertCmd.Parameters.AddWithValue("@companyId", assetCompany);
                    await insertCmd.ExecuteNonQueryAsync();
                }

                // Update asset's assigned location
                string moveAssetSql = @"UPDATE dbo.asset
                                        SET locationid = @locId,
                                            lastmodified = SYSDATETIMEOFFSET(),
                                            lastmodifiedby = 'ReaderIntelligence'
                                        WHERE id = @id";
                using (var moveCmd = new SqlCommand(moveAssetSql, conn))
                {
                    moveCmd.Parameters.AddWithValue("@locId", locationId);
                    moveCmd.Parameters.AddWithValue("@id", assetId);
                    await moveCmd.ExecuteNonQueryAsync();
                }

                _log.LogInformation(
                    "Antenna-aware move: {Asset} (co {AssetCo}) → {Location} via antenna {Ant} (reader {Reader}, co {ReaderCo})",
                    assetName, assetCompany, locationName, antennaPort, reader.PhysicalId, reader.CompanyId);
            }
            else if (!locationChanged)
            {
                _log.LogDebug("Tag {Tag} at {Asset} still at {Location}", tagHex, assetName, locationName);
            }
        }

        // ────────────────────────────────────────────────────────────────
        //  TAG PARSING — Now extracts antenna port
        // ────────────────────────────────────────────────────────────────
        /// <summary>
        /// Parses RFID tag hex values AND antenna port from the MQTT JSON payload.
        /// Handles multiple payload formats from different reader types.
        /// </summary>
        private List<TagRead> ParseTagReads(string json)
        {
            var tags = new List<TagRead>();
            try
            {
                var obj = JToken.Parse(json);

                // Format 1: { "tagReads": [{ "epc": "HEX", "antenna": 1 }] }
                if (obj["tagReads"] is JArray reads)
                {
                    foreach (var r in reads)
                    {
                        string epc = r["epc"]?.ToString();
                        if (string.IsNullOrEmpty(epc)) continue;

                        int ant = r["antenna"]?.Value<int>() ?? r["antennaPort"]?.Value<int>() ?? 0;
                        double rssi = r["rssi"]?.Value<double>() ?? r["peakRssi"]?.Value<double>() ?? 0;

                        tags.Add(new TagRead { Epc = epc, AntennaPort = ant, Rssi = rssi });
                    }
                }
                // Format 2: { "data": { "inventoryData": [{ "epcHex": "HEX", "antennaPort": 1 }] } }
                else if (obj["data"]?["inventoryData"] is JArray inv)
                {
                    foreach (var item in inv)
                    {
                        string epc = (item["epcHex"] ?? item["epc"] ?? item["tagId"])?.ToString();
                        if (string.IsNullOrEmpty(epc)) continue;

                        int ant = item["antennaPort"]?.Value<int>() ?? item["antenna"]?.Value<int>() ?? 0;
                        double rssi = item["rssi"]?.Value<double>() ?? item["peakRssi"]?.Value<double>() ?? 0;

                        tags.Add(new TagRead { Epc = epc, AntennaPort = ant, Rssi = rssi });
                    }
                }
                // Format 3: { "epc": "HEX", "antenna": 1 } (single tag)
                else if (obj["epc"] != null)
                {
                    int ant = obj["antenna"]?.Value<int>() ?? obj["antennaPort"]?.Value<int>() ?? 0;
                    tags.Add(new TagRead
                    {
                        Epc = obj["epc"].ToString(),
                        AntennaPort = ant,
                        Rssi = obj["rssi"]?.Value<double>() ?? 0
                    });
                }
                // Format 4: Array of tag objects
                else if (obj is JArray arr)
                {
                    foreach (var item in arr)
                    {
                        string epc = (item["epc"] ?? item["epcHex"])?.ToString();
                        if (string.IsNullOrEmpty(epc)) continue;

                        int ant = item["antenna"]?.Value<int>() ?? item["antennaPort"]?.Value<int>() ?? 0;
                        tags.Add(new TagRead { Epc = epc, AntennaPort = ant });
                    }
                }
            }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "Failed to parse tag payload");
            }
            return tags;
        }

        // ────────────────────────────────────────────────────────────────
        //  READER CACHE
        // ────────────────────────────────────────────────────────────────
        private async Task RefreshReaderCache()
        {
            try
            {
                string connStr = _config.GetConnectionString("iDash");
                using var conn = new SqlConnection(connStr);
                await conn.OpenAsync();

                string sql = @"SELECT r.id, r.physicalid, r.companyid, r.locationid,
                                      r.devicesettings, l.name AS locationName
                               FROM dbo.reader r
                               INNER JOIN dbo.location l ON r.locationid = l.id
                               WHERE r.physicalid IS NOT NULL AND r.physicalid <> ''";

                using var cmd = new SqlCommand(sql, conn);
                using var rdr = await cmd.ExecuteReaderAsync();

                var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                int count = 0;

                while (await rdr.ReadAsync())
                {
                    string pid = rdr["physicalid"].ToString();
                    if (seen.Contains(pid)) continue;
                    seen.Add(pid);

                    // Parse updateLocation from devicesettings JSON
                    bool updateLoc = false;
                    string ds = rdr["devicesettings"] != DBNull.Value ? rdr["devicesettings"].ToString() : "";
                    if (!string.IsNullOrEmpty(ds))
                    {
                        try
                        {
                            var dsObj = JObject.Parse(ds);
                            updateLoc = dsObj["updateLocation"]?.Value<bool>() ?? false;
                        }
                        catch { }
                    }

                    var info = new ReaderInfo
                    {
                        ReaderId = Convert.ToInt32(rdr["id"]),
                        PhysicalId = pid,
                        CompanyId = Convert.ToInt32(rdr["companyid"]),
                        LocationId = Convert.ToInt32(rdr["locationid"]),
                        LocationName = rdr["locationName"].ToString(),
                        UpdateLocation = updateLoc
                    };
                    _readerCache[pid] = info;
                    count++;
                }

                _cacheExpiry = DateTime.UtcNow.AddMinutes(5);
                _log.LogInformation("Loaded {Count} reader(s) into cache", count);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "Failed to refresh reader cache");
            }
        }

        // ────────────────────────────────────────────────────────────────
        //  ANTENNA CACHE
        // ────────────────────────────────────────────────────────────────
        private async Task RefreshAntennaCache()
        {
            try
            {
                string connStr = _config.GetConnectionString("iDash");
                using var conn = new SqlConnection(connStr);
                await conn.OpenAsync();

                string sql = @"SELECT a.id, a.number, a.readerid, a.locationid, l.name AS locationName
                               FROM dbo.antenna a
                               INNER JOIN dbo.location l ON a.locationid = l.id
                               WHERE a.locationid IS NOT NULL";

                using var cmd = new SqlCommand(sql, conn);
                using var rdr = await cmd.ExecuteReaderAsync();

                _antennaCache.Clear();
                int count = 0;

                while (await rdr.ReadAsync())
                {
                    int readerId = Convert.ToInt32(rdr["readerid"]);
                    int port = Convert.ToInt32(rdr["number"]);
                    string key = $"{readerId}:{port}";

                    _antennaCache[key] = new AntennaInfo
                    {
                        AntennaId = Convert.ToInt32(rdr["id"]),
                        Port = port,
                        ReaderId = readerId,
                        LocationId = Convert.ToInt32(rdr["locationid"]),
                        LocationName = rdr["locationName"].ToString()
                    };
                    count++;
                }

                _log.LogInformation("Loaded {Count} antenna(s) into cache", count);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "Failed to refresh antenna cache");
            }
        }
    }
}
