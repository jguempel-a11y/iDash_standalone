using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;

public partial class va_fixed_reader_live : System.Web.UI.Page
{
    protected string ReadersJson = "[]";
    protected string AllowedCompanyIdsJson = "[]";

    protected void Page_Load(object sender, EventArgs e)
    {
        AntennaLocationService.EnsureStarted();

        // API dispatch — respond with JSON and end the response
        string api = Request.QueryString["api"];
        if (!string.IsNullOrEmpty(api))
        {
            Response.ContentType = "application/json";
            Response.Cache.SetNoStore();
            var jss = new JavaScriptSerializer();

            if (api == "live")
            {
                // Live tag events (existing)
                long sinceSeq = 0;
                long.TryParse(Request.QueryString["seq"], out sinceSeq);
                int[] rIds = null;
                if (!string.IsNullOrEmpty(Request.QueryString["r"]))
                    rIds = Array.ConvertAll(Request.QueryString["r"].Split(','), int.Parse);
                int[] aPorts = null;
                if (!string.IsNullOrEmpty(Request.QueryString["a"]))
                    aPorts = Array.ConvertAll(Request.QueryString["a"].Split(','), int.Parse);
                string cs2 = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
                var cIds = UserManager.GetAllowedCompanyIds(Session, cs2);
                if (cIds != null && cIds.Count == 0) cIds = null;
                var evts = AntennaLocationService.GetLiveEvents(sinceSeq, rIds, aPorts,
                               cIds == null ? null : cIds.ToArray());
                Response.Write(jss.Serialize(new {
                    seq    = AntennaLocationService.GetLiveSeq(),
                    events = evts
                }));
                Response.End();
                return;
            }

            if (api == "mqttspy")
            {
                // Raw MQTT message spy — shows exactly what the broker is delivering to iDash
                // Useful for diagnosing topic mismatches and payload format issues
                var raw = AntennaLocationService.GetRawFeed();
                var topicSetting = System.Web.Configuration.WebConfigurationManager
                    .AppSettings["AntennaService_TopicFilter"] ?? "(not set)";
                Response.Write(jss.Serialize(new {
                    subscribedTopic = topicSetting,
                    messageCount    = raw.Count,
                    messages        = raw
                }));
                Response.End();
                return;
            }

            if (api == "status")
            {
                // Service and broker connection status
                Response.Write(jss.Serialize(new {
                    serviceRunning  = AntennaLocationService.IsRunning(),
                    messagesReceived = AntennaLocationService.MessagesReceived,
                    subscribedTopic = System.Web.Configuration.WebConfigurationManager
                        .AppSettings["AntennaService_TopicFilter"] ?? "(not set)",
                    liveSeq         = AntennaLocationService.GetLiveSeq(),
                    rawMessages     = AntennaLocationService.GetRawFeed().Count
                }));
                Response.End();
                return;
            }

            if (api == "testpublish")
            {
                // DIAGNOSTIC: Publish a test message to reader/test via the broker,
                // then check if the subscriber's spy buffer received it.
                // This tests broker routing independently of the FX9600.
                string testTopic = "reader/test";
                string testPayload = "{\"test\":true,\"ts\":\"" + DateTime.UtcNow.ToString("o") + "\"}";
                string result = "unknown";
                try
                {
                    // Connect to broker and publish using same raw TCP/TLS code
                    string server = System.Web.Configuration.WebConfigurationManager
                        .AppSettings["AntennaService_MqttServer"] ?? "127.0.0.1";
                    int port = int.Parse(System.Web.Configuration.WebConfigurationManager
                        .AppSettings["AntennaService_MqttPort"] ?? "8883");
                    string mqttUser = System.Web.Configuration.WebConfigurationManager
                        .AppSettings["AntennaService_MqttUsername"] ?? "MasterPrint";
                    string mqttPass = System.Web.Configuration.WebConfigurationManager
                        .AppSettings["AntennaService_MqttPassword"] ?? "V5MqttPrint2026!";

                    int spyCountBefore = AntennaLocationService.GetRawFeed().Count;

                    using (var tcp = new System.Net.Sockets.TcpClient())
                    {
                        tcp.ConnectAsync(server, port).Wait(5000);
                        var ssl = new System.Net.Security.SslStream(tcp.GetStream(), false,
                            (s, cert, chain, errs) => true);
                        ssl.AuthenticateAsClient(server);

                        // MQTT CONNECT
                        var connPayload = new System.Collections.Generic.List<byte>();
                        connPayload.AddRange(new byte[]{0,4,(byte)'M',(byte)'Q',(byte)'T',(byte)'T'}); // "MQTT"
                        connPayload.Add(0x04); // protocol level 3.1.1
                        connPayload.Add(0xC2); // clean session + user + pass
                        connPayload.Add(0x00); connPayload.Add(0x3C); // keepalive 60s
                        // ClientId
                        string cid = "iDashTest_" + Guid.NewGuid().ToString("N").Substring(0,6);
                        var cidBytes = System.Text.Encoding.UTF8.GetBytes(cid);
                        connPayload.Add((byte)(cidBytes.Length >> 8));
                        connPayload.Add((byte)(cidBytes.Length & 0xFF));
                        connPayload.AddRange(cidBytes);
                        // Username
                        var userBytes = System.Text.Encoding.UTF8.GetBytes(mqttUser);
                        connPayload.Add((byte)(userBytes.Length >> 8));
                        connPayload.Add((byte)(userBytes.Length & 0xFF));
                        connPayload.AddRange(userBytes);
                        // Password
                        var passBytes = System.Text.Encoding.UTF8.GetBytes(mqttPass);
                        connPayload.Add((byte)(passBytes.Length >> 8));
                        connPayload.Add((byte)(passBytes.Length & 0xFF));
                        connPayload.AddRange(passBytes);

                        // Write CONNECT packet
                        var connPkt = new System.Collections.Generic.List<byte>();
                        connPkt.Add(0x10); // CONNECT type
                        int cLen = connPayload.Count;
                        do { byte b2 = (byte)(cLen % 128); cLen /= 128; if (cLen > 0) b2 |= 0x80; connPkt.Add(b2); } while (cLen > 0);
                        connPkt.AddRange(connPayload);
                        ssl.Write(connPkt.ToArray());
                        ssl.Flush();

                        // Read CONNACK
                        byte[] connAck = new byte[4];
                        ssl.Read(connAck, 0, 4);
                        if (connAck[3] != 0x00) {
                            result = "CONNACK error code " + connAck[3];
                        } else {
                            // MQTT PUBLISH to reader/test (QoS 0)
                            var pubPayload = new System.Collections.Generic.List<byte>();
                            var topicBytes = System.Text.Encoding.UTF8.GetBytes(testTopic);
                            pubPayload.Add((byte)(topicBytes.Length >> 8));
                            pubPayload.Add((byte)(topicBytes.Length & 0xFF));
                            pubPayload.AddRange(topicBytes);
                            pubPayload.AddRange(System.Text.Encoding.UTF8.GetBytes(testPayload));

                            var pubPkt = new System.Collections.Generic.List<byte>();
                            pubPkt.Add(0x30); // PUBLISH QoS 0
                            int pLen = pubPayload.Count;
                            do { byte b3 = (byte)(pLen % 128); pLen /= 128; if (pLen > 0) b3 |= 0x80; pubPkt.Add(b3); } while (pLen > 0);
                            pubPkt.AddRange(pubPayload);
                            ssl.Write(pubPkt.ToArray());
                            ssl.Flush();

                            result = "published";

                            // Wait a moment for the subscriber to pick it up
                            System.Threading.Thread.Sleep(1000);
                            int spyCountAfter = AntennaLocationService.GetRawFeed().Count;
                            result = spyCountAfter > spyCountBefore
                                ? "ROUTED! spy went from " + spyCountBefore + " to " + spyCountAfter
                                : "NOT ROUTED. spy still at " + spyCountAfter;
                        }

                        // DISCONNECT
                        ssl.Write(new byte[]{0xE0, 0x00});
                        ssl.Flush();
                    }
                }
                catch (Exception ex) { result = "error: " + ex.Message; }

                Response.Write(jss.Serialize(new {
                    test = "publish to " + testTopic,
                    result = result,
                    payload = testPayload
                }));
                Response.End();
                return;
            }

            Response.Write("{\"error\":\"unknown api\"}");
            Response.End();
            return;
        }

        // Normal page render
        string cs = WebConfigurationManager.ConnectionStrings["iDash"].ConnectionString;
        var allowedIds = UserManager.GetAllowedCompanyIds(Session, cs);

        // If allowedIds is empty it means the company name lookup in UserManager
        // couldn't match session site-access keys to dbo.company rows.
        // Fall back to unrestricted (null) so the page always shows readers.
        if (allowedIds != null && allowedIds.Count == 0)
            allowedIds = null;

        AllowedCompanyIdsJson = allowedIds == null ? "null" :
            new JavaScriptSerializer().Serialize(allowedIds);
        ReadersJson = GetReadersJson(cs, allowedIds);
    }

    private string GetReadersJson(string cs, List<int> allowedIds)
    {
        try
        {
            // Build company filter for readers (null = all, non-empty list = restrict)
            string companyFilter = (allowedIds != null && allowedIds.Count > 0)
                ? " AND r.companyid IN (" + string.Join(",", allowedIds) + ")"
                : "";

            var readers = new List<object>();

            using (var cn = new SqlConnection(cs))
            {
                cn.Open();
                string sql = @"
                    SELECT r.id, r.physicalid, r.name, r.companyid,
                           ISNULL(c.name,'') AS companyname,
                           ISNULL(r.lastseen, '2000-01-01') AS lastseen,
                           CASE WHEN r.lastseen >= DATEADD(MINUTE,-5,GETDATE()) THEN 1 ELSE 0 END AS online
                    FROM dbo.reader r
                    LEFT JOIN dbo.company c ON r.companyid = c.id
                    WHERE r.physicalid IS NOT NULL AND r.physicalid <> ''" + companyFilter + @"
                    ORDER BY c.name, r.name";
                using (var cmd = new SqlCommand(sql, cn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        int rid = Convert.ToInt32(rdr["id"]);
                        int cid = rdr["companyid"] != DBNull.Value ? Convert.ToInt32(rdr["companyid"]) : 0;
                        var antennas = new List<object>();

                        using (var cn2 = new SqlConnection(cs))
                        {
                            cn2.Open();
                            string antSql = @"
                                SELECT a.id, a.number,
                                       ISNULL(l.name,'Port '+CAST(a.number AS varchar)) AS locationname
                                FROM dbo.antenna a
                                LEFT JOIN dbo.location l ON a.locationid = l.id
                                WHERE a.readerid = @rid
                                ORDER BY a.number";
                            using (var acmd = new SqlCommand(antSql, cn2))
                            {
                                acmd.Parameters.AddWithValue("@rid", rid);
                                using (var ardr = acmd.ExecuteReader())
                                {
                                    while (ardr.Read())
                                    {
                                        antennas.Add(new {
                                            id       = Convert.ToInt32(ardr["id"]),
                                            port     = Convert.ToInt32(ardr["number"]),
                                            location = ardr["locationname"].ToString()
                                        });
                                    }
                                }
                            }
                        }

                        readers.Add(new {
                            id          = rid,
                            physicalId  = rdr["physicalid"].ToString(),
                            name        = rdr["name"] != DBNull.Value && rdr["name"].ToString() != ""
                                            ? rdr["name"].ToString()
                                            : rdr["physicalid"].ToString(),
                            companyId   = cid,
                            companyName = rdr["companyname"].ToString(),
                            online      = Convert.ToInt32(rdr["online"]) == 1,
                            lastseen    = rdr["lastseen"].ToString(),
                            antennas    = antennas
                        });
                    }
                }
            }

            var jss = new JavaScriptSerializer();
            return jss.Serialize(readers);
        }
        catch
        {
            return "[]";
        }
    }
}
