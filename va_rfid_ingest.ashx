<%@ WebHandler Language="C#" Class="RfidIngestHandler" %>

using System;
using System.IO;
using System.Web;

/// <summary>
/// HTTP POST receiver for Zebra FX9600 IoT Connector tag data.
/// 
/// The FX9600 reader is configured with an HTTP POST endpoint pointing here.
/// Each POST contains a JSON payload with tag reads including antenna port.
/// This handler passes the payload directly to AntennaLocationService for processing.
///
/// URL: http://192.168.4.48/iDash/va_rfid_ingest.ashx
/// </summary>
public class RfidIngestHandler : IHttpHandler
{
    public bool IsReusable { get { return true; } }

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";

        try
        {
            if (!context.Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                context.Response.StatusCode = 405;
                context.Response.Write("{\"error\":\"Method Not Allowed\"}");
                return;
            }

            // Ensure the background MQTT listener is running.
            // This restarts it automatically after IIS app pool recycles,
            // since the reader POSTs here every 60s regardless of page visits.
            AntennaLocationService.EnsureStarted();

            // Read the raw JSON payload from the reader
            string payload;
            using (var reader = new StreamReader(context.Request.InputStream,
                System.Text.Encoding.UTF8))
            {
                payload = reader.ReadToEnd();
            }

            if (string.IsNullOrWhiteSpace(payload))
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\":\"Empty payload\"}");
                return;
            }

            // Log raw payload for debugging
            AntennaLocationService.LogHttpIngest(payload);

            // Process through the AntennaLocationService
            AntennaLocationService.ProcessHttpPayload(payload);

            context.Response.StatusCode = 200;
            context.Response.Write("{\"ok\":true}");
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            context.Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
        }
    }
}
