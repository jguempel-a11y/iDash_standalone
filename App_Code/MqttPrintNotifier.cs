using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Security;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

/// <summary>
/// Lightweight MQTT publisher that notifies the iDash Print Service
/// when iDash creates print jobs. Uses raw TCP/TLS — no MQTTnet dependency.
/// </summary>
public static class MqttPrintNotifier
{
    private static readonly string MqttServer = "localhost";
    private static readonly int MqttPort = 8883;

    /// <summary>
    /// Notify the Print Server that new print jobs are available.
    /// Runs synchronously so caller knows if it succeeded.
    /// Throws on failure so the caller can handle it.
    /// </summary>
    public static void NotifyPrintServer(string printClientUsername, string message = "print")
    {
        if (string.IsNullOrEmpty(printClientUsername)) return;
        PublishRawMqtt(printClientUsername, message);
    }

    /// <summary>
    /// Sends a minimal MQTT CONNECT + PUBLISH + DISCONNECT using raw sockets.
    /// The MQTT protocol is simple enough to hand-craft for a single publish.
    /// </summary>
    private static void PublishRawMqtt(string printClientUsername, string payload)
    {
        string topic = "awrx/print/" + printClientUsername;
        string clientId = "iDash_" + Guid.NewGuid().ToString("N").Substring(0, 8);

        using (var tcp = new TcpClient())
        {
            // Connect with timeout
            var connectTask = tcp.ConnectAsync(MqttServer, MqttPort);
            if (!connectTask.Wait(5000))
                throw new TimeoutException("TCP connect to MQTT broker timed out");
            if (!tcp.Connected)
                throw new Exception("TCP connect to MQTT broker failed");

            // Wrap in TLS (port 8883 uses TLS)
            var ssl = new SslStream(tcp.GetStream(), false,
                (sender, cert, chain, errors) => true); // Accept self-signed certs
            ssl.AuthenticateAsClient(MqttServer);

            // === MQTT CONNECT packet ===
            // Authenticate with the MQTT broker credentials. The unique clientId
            // (iDash_XXXXXXXX) prevents collision with the Print Server's session.
            string mqttUser = GetConfigValue("PrintClientUsername", "MasterPrint");
            string mqttPass = GetConfigValue("PrintClientPassword", "V5MqttPrint2026!");

            var connectPayload = new MemoryStream();
            // Variable header
            WriteString(connectPayload, "MQTT");       // Protocol name
            connectPayload.WriteByte(4);                // Protocol level (4 = MQTT 3.1.1)
            connectPayload.WriteByte(0xC2);             // Connect flags: Clean Session + Username + Password
            WriteUInt16(connectPayload, 30);            // Keep alive: 30 seconds
            // Payload: ClientId, Username, Password
            WriteString(connectPayload, clientId);
            WriteString(connectPayload, mqttUser);
            WriteString(connectPayload, mqttPass);

            WritePacket(ssl, 0x10, connectPayload.ToArray()); // CONNECT = 0x10

            // Read CONNACK with timeout
            tcp.ReceiveTimeout = 5000;
            byte[] connack = new byte[4];
            int bytesRead = 0;
            while (bytesRead < 4)
            {
                int n = ssl.Read(connack, bytesRead, 4 - bytesRead);
                if (n == 0) throw new Exception("MQTT broker closed connection during CONNACK");
                bytesRead += n;
            }

            // Validate CONNACK: byte[0]=0x20 (CONNACK type), byte[3]=return code
            if (connack[0] != 0x20)
                throw new Exception("Expected CONNACK (0x20) but got 0x" + connack[0].ToString("X2"));
            if (connack[3] != 0x00)
                throw new Exception("MQTT CONNACK error code: " + connack[3] +
                    " (1=bad protocol, 2=id rejected, 4=bad credentials, 5=not authorized)");

            // Small delay to let the broker process the connection
            Thread.Sleep(100);

            // === MQTT PUBLISH packet ===
            var publishPayload = new MemoryStream();
            WriteString(publishPayload, topic);
            byte[] payloadBytes = Encoding.UTF8.GetBytes(payload);
            publishPayload.Write(payloadBytes, 0, payloadBytes.Length);

            WritePacket(ssl, 0x30, publishPayload.ToArray()); // PUBLISH QoS 0 = 0x30
            ssl.Flush();

            // Small delay to ensure the message is sent before disconnect
            Thread.Sleep(200);

            // === MQTT DISCONNECT packet ===
            ssl.WriteByte(0xE0); // DISCONNECT
            ssl.WriteByte(0x00); // Remaining length = 0
            ssl.Flush();
        }
    }

    private static void WritePacket(Stream stream, byte packetType, byte[] payload)
    {
        stream.WriteByte(packetType);
        WriteRemainingLength(stream, payload.Length);
        stream.Write(payload, 0, payload.Length);
        stream.Flush();
    }

    private static void WriteString(Stream stream, string value)
    {
        byte[] bytes = Encoding.UTF8.GetBytes(value);
        WriteUInt16(stream, (ushort)bytes.Length);
        stream.Write(bytes, 0, bytes.Length);
    }

    private static void WriteUInt16(Stream stream, ushort value)
    {
        stream.WriteByte((byte)(value >> 8));
        stream.WriteByte((byte)(value & 0xFF));
    }

    private static void WriteRemainingLength(Stream stream, int length)
    {
        do
        {
            byte b = (byte)(length & 0x7F);
            length >>= 7;
            if (length > 0) b |= 0x80;
            stream.WriteByte(b);
        } while (length > 0);
    }

    // ── Diagnostics ──────────────────────────────────────────────────────────

    /// <summary>
    /// Full MQTT connectivity test for the System Diagnostics page.
    /// Performs: TCP connect → TLS handshake → MQTT CONNECT → CONNACK → PUBLISH → DISCONNECT.
    /// Returns a structured result; never throws.
    /// </summary>
    public static MqttTestResult TestConnectivity()
    {
        var result = new MqttTestResult();
        var sw = System.Diagnostics.Stopwatch.StartNew();

        string diagTopic   = "awrx/print/iDashDiag";
        string diagPayload = "diagnostic_ping";
        string clientId    = "iDashDiag_" + Guid.NewGuid().ToString("N").Substring(0, 6);

        try
        {
            // ── 1. TCP connect ────────────────────────────────────────────
            using (var tcp = new TcpClient())
            {
                var connectTask = tcp.ConnectAsync(MqttServer, MqttPort);
                if (!connectTask.Wait(5000))
                    throw new TimeoutException(string.Format("TCP connect to {0}:{1} timed out after 5s", MqttServer, MqttPort));

                result.TcpConnected = true;
                result.BrokerAddress = string.Format("{0}:{1}", MqttServer, MqttPort);

                // ── 2. TLS handshake ──────────────────────────────────────
                var ssl = new SslStream(tcp.GetStream(), false,
                    (sender, cert, chain, errors) => true);
                ssl.AuthenticateAsClient(MqttServer);
                result.TlsHandshook = true;

                // ── 3. MQTT CONNECT ───────────────────────────────────────
                string mqttUser = GetConfigValue("PrintClientUsername", "MasterPrint");
                string mqttPass = GetConfigValue("PrintClientPassword", "V5MqttPrint2026!");

                var connectPayload = new MemoryStream();
                WriteString(connectPayload, "MQTT");
                connectPayload.WriteByte(4);     // MQTT 3.1.1
                connectPayload.WriteByte(0xC2);  // Clean Session + User + Pass
                WriteUInt16(connectPayload, 30);
                WriteString(connectPayload, clientId);
                WriteString(connectPayload, mqttUser);
                WriteString(connectPayload, mqttPass);
                WritePacket(ssl, 0x10, connectPayload.ToArray());

                // ── 4. CONNACK ────────────────────────────────────────────
                tcp.ReceiveTimeout = 5000;
                byte[] connack = new byte[4];
                int read = 0;
                while (read < 4) { int n = ssl.Read(connack, read, 4 - read); if (n == 0) break; read += n; }

                if (connack[0] != 0x20)
                    throw new Exception(string.Format("Expected CONNACK (0x20), got 0x{0}", connack[0].ToString("X2")));

                byte rc = connack[3];
                if (rc != 0x00)
                {
                    string[] rcMessages = new string[] {
                        "Accepted", "Unacceptable protocol", "Client ID rejected",
                        "Server unavailable", "Bad credentials", "Not authorized"
                    };
                    string rcMsg = rc < rcMessages.Length ? rcMessages[rc] : "Unknown";
                    throw new Exception(string.Format("MQTT CONNACK refused — code {0}: {1}", rc, rcMsg));
                }

                result.MqttConnected = true;
                result.ClientId = clientId;
                Thread.Sleep(80);

                // ── 5. PUBLISH test message ───────────────────────────────
                var publishPayload = new MemoryStream();
                WriteString(publishPayload, diagTopic);
                byte[] payloadBytes = Encoding.UTF8.GetBytes(diagPayload);
                publishPayload.Write(payloadBytes, 0, payloadBytes.Length);
                WritePacket(ssl, 0x30, publishPayload.ToArray());
                ssl.Flush();
                Thread.Sleep(150);

                result.Published = true;
                result.Topic = diagTopic;

                // ── 6. DISCONNECT ─────────────────────────────────────────
                ssl.WriteByte(0xE0);
                ssl.WriteByte(0x00);
                ssl.Flush();
            }

            sw.Stop();
            result.DurationMs = sw.ElapsedMilliseconds;
            result.Success = true;
            result.Message = string.Format(
                "TCP OK → TLS OK → MQTT CONNECT accepted → Published to {0}", diagTopic);
        }
        catch (Exception ex)
        {
            sw.Stop();
            result.DurationMs = sw.ElapsedMilliseconds;
            result.Success = false;
            result.Message = ex.Message;
        }

        return result;
    }

    public class MqttStressResult
    {
        public bool Success { get; set; }
        public int TotalClients { get; set; }
        public int MessagesPerClient { get; set; }
        public int TotalPublished { get; set; }
        public int FailedConnections { get; set; }
        public int FailedPublishes { get; set; }
        public long DurationMs { get; set; }
    }

    public static MqttStressResult RunStressTest(int concurrentClients, int messagesPerClient)
    {
        var result = new MqttStressResult { TotalClients = concurrentClients, MessagesPerClient = messagesPerClient };
        var sw = System.Diagnostics.Stopwatch.StartNew();
        
        string mqttUser = GetConfigValue("PrintClientUsername", "MasterPrint");
        string mqttPass = GetConfigValue("PrintClientPassword", "V5MqttPrint2026!");
        string topic = "awrx/print/StressTest";

        int totalPublished = 0;
        int failedConnections = 0;
        int failedPublishes = 0;
        object lockObj = new object();

        Parallel.For(0, concurrentClients, new ParallelOptions { MaxDegreeOfParallelism = concurrentClients }, i =>
        {
            string clientId = "iDashStress_" + Guid.NewGuid().ToString("N").Substring(0, 6) + "_" + i;
            
            try
            {
                using (var tcp = new TcpClient())
                {
                    var connectTask = tcp.ConnectAsync(MqttServer, MqttPort);
                    if (!connectTask.Wait(10000))
                        throw new TimeoutException("TCP timeout");

                    var ssl = new SslStream(tcp.GetStream(), false, (s, c, ch, err) => true);
                    ssl.AuthenticateAsClient(MqttServer);

                    var connectPayload = new MemoryStream();
                    WriteString(connectPayload, "MQTT");
                    connectPayload.WriteByte(4);
                    connectPayload.WriteByte(0xC2);
                    WriteUInt16(connectPayload, 60);
                    WriteString(connectPayload, clientId);
                    WriteString(connectPayload, mqttUser);
                    WriteString(connectPayload, mqttPass);
                    WritePacket(ssl, 0x10, connectPayload.ToArray());

                    tcp.ReceiveTimeout = 10000;
                    byte[] connack = new byte[4];
                    int read = 0;
                    while (read < 4) { int n = ssl.Read(connack, read, 4 - read); if (n == 0) break; read += n; }
                    if (connack[0] != 0x20 || connack[3] != 0x00)
                        throw new Exception("CONNACK failed");

                    int publishedCount = 0;
                    for (int j = 0; j < messagesPerClient; j++)
                    {
                        try
                        {
                            var pub = new MemoryStream();
                            WriteString(pub, topic);
                            byte[] payload = Encoding.UTF8.GetBytes("StressTestMsg_" + j);
                            pub.Write(payload, 0, payload.Length);
                            WritePacket(ssl, 0x30, pub.ToArray());
                            publishedCount++;
                        }
                        catch
                        {
                            Interlocked.Increment(ref failedPublishes);
                            break; 
                        }
                    }

                    lock (lockObj) { totalPublished += publishedCount; }

                    try { ssl.WriteByte(0xE0); ssl.WriteByte(0x00); ssl.Flush(); } catch {}
                }
            }
            catch
            {
                Interlocked.Increment(ref failedConnections);
            }
        });

        sw.Stop();
        result.DurationMs = sw.ElapsedMilliseconds;
        result.TotalPublished = totalPublished;
        result.FailedConnections = failedConnections;
        result.FailedPublishes = failedPublishes;
        result.Success = (failedConnections == 0 && failedPublishes == 0 && totalPublished == (concurrentClients * messagesPerClient));
        
        return result;
    }

    /// <summary>Structured result returned by TestConnectivity().</summary>
    public class MqttTestResult
    {
        public bool   Success       { get; set; }
        public string Message       { get; set; }
        public long   DurationMs    { get; set; }
        public bool   TcpConnected  { get; set; }
        public bool   TlsHandshook  { get; set; }
        public bool   MqttConnected { get; set; }
        public bool   Published     { get; set; }
        public string BrokerAddress { get; set; }
        public string ClientId      { get; set; }
        public string Topic         { get; set; }
    }

    // ── Config Reader ────────────────────────────────────────────────────

    private static readonly string AppSettingsPath = @"c:\inetpub\wwwroot\iDash\appsettings.json";
    private static Dictionary<string, string> _configCache;
    private static DateTime _configCacheTime;

    /// <summary>
    /// Reads a value from the WebClient appsettings.json ConfigSettings section.
    /// Caches for 60 seconds to avoid repeated disk reads during burst prints.
    /// Falls back to defaultValue if the file can't be read.
    /// </summary>
    private static string GetConfigValue(string key, string defaultValue)
    {
        try
        {
            if (_configCache != null && (DateTime.UtcNow - _configCacheTime).TotalSeconds < 60)
            {
                return _configCache.ContainsKey(key) ? _configCache[key] : defaultValue;
            }

            if (!File.Exists(AppSettingsPath)) return defaultValue;

            string json = File.ReadAllText(AppSettingsPath);
            var js = new JavaScriptSerializer();
            var root = js.Deserialize<Dictionary<string, object>>(json);
            Dictionary<string, object> cfg = null;
            if (root.ContainsKey("ConfigSettings"))
                cfg = root["ConfigSettings"] as Dictionary<string, object>;
            if (cfg == null) cfg = root;

            _configCache = new Dictionary<string, string>();
            foreach (var kv in cfg)
            {
                if (kv.Value != null)
                    _configCache[kv.Key] = kv.Value.ToString();
            }
            _configCacheTime = DateTime.UtcNow;

            return _configCache.ContainsKey(key) ? _configCache[key] : defaultValue;
        }
        catch
        {
            return defaultValue;
        }
    }
}
