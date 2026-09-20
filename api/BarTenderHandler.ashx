<%@ WebHandler Language="C#" Class="BarTenderHandler" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;

public class BarTenderHandler : IHttpHandler, System.Web.SessionState.IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

        // Security check: Must be authenticated in iDash or local
        bool isLoggedIn = (context.Session != null && (
            (context.Session["IsAdminAuthenticated"] != null && (bool)context.Session["IsAdminAuthenticated"]) ||
            context.Session["IdashUsername"] != null ||
            context.Session["UserName"] != null
        )) || context.Request.IsLocal;

        if (!isLoggedIn)
        {
            context.Response.StatusCode = 401;
            context.Response.Write("{\"success\":false,\"error\":\"Authentication required.\"}");
            return;
        }

        string action = context.Request.QueryString["action"] ?? context.Request.Form["action"] ?? "";
        action = action.Trim().ToLowerInvariant();

        // Read request body once
        string requestBody = "";
        using (var reader = new StreamReader(context.Request.InputStream))
        {
            requestBody = reader.ReadToEnd();
        }

        var ser = new JavaScriptSerializer();
        ser.MaxJsonLength = 10485760; // 10MB for base64 image data

        switch (action)
        {
            case "health":
                HandleHealth(context, ser);
                break;

            case "printers":
                HandleGetPrinters(context, ser);
                break;

            case "fields":
                HandleGetFields(context, ser);
                break;

            case "preview":
                HandlePreview(context, ser, requestBody);
                break;

            case "print":
                HandlePrint(context, ser, requestBody);
                break;

            default:
                context.Response.Write("{\"success\":false,\"error\":\"Unknown action: " + HttpUtility.JavaScriptStringEncode(action) + "\"}");
                break;
        }
    }

    private void HandleHealth(HttpContext context, JavaScriptSerializer ser)
    {
        try
        {
            var health = BarTenderApiHelper.CheckHealth();
            context.Response.Write(ser.Serialize(new
            {
                success = true,
                engineAvailable = health.EngineAvailable,
                barTenderVersion = health.BarTenderVersion,
                printerCount = health.PrinterCount,
                lastUsed = health.LastUsed.ToString("yyyy-MM-dd HH:mm:ss"),
                error = health.ErrorMessage
            }));
        }
        catch (Exception ex)
        {
            context.Response.Write("{\"success\":false,\"error\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
        }
    }

    private void HandleGetPrinters(HttpContext context, JavaScriptSerializer ser)
    {
        try
        {
            var printers = BarTenderApiHelper.GetPrinters();
            context.Response.Write(ser.Serialize(new { success = true, printers = printers }));
        }
        catch (Exception ex)
        {
            context.Response.Write("{\"success\":false,\"error\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
        }
    }

    private void HandleGetFields(HttpContext context, JavaScriptSerializer ser)
    {
        string tpl = context.Request["template"] ?? "";
        if (string.IsNullOrWhiteSpace(tpl))
        {
            context.Response.Write("{\"success\":false,\"error\":\"Missing template path.\"}");
            return;
        }

        try
        {
            var fields = BarTenderApiHelper.GetTemplateFields(tpl);
            context.Response.Write(ser.Serialize(new { success = true, template = tpl, fields = fields }));
        }
        catch (Exception ex)
        {
            context.Response.Write("{\"success\":false,\"error\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
        }
    }

    private void HandlePreview(HttpContext context, JavaScriptSerializer ser, string requestBody)
    {
        string templatePath = "";
        Dictionary<string, string> fields = new Dictionary<string, string>();

        if (!string.IsNullOrWhiteSpace(requestBody))
        {
            try
            {
                var payload = ser.Deserialize<Dictionary<string, object>>(requestBody);
                if (payload.ContainsKey("template"))
                    templatePath = Convert.ToString(payload["template"]);

                if (payload.ContainsKey("fields") && payload["fields"] is Dictionary<string, object>)
                {
                    var fDict = (Dictionary<string, object>)payload["fields"];
                    foreach (var kv in fDict)
                    {
                        fields[kv.Key] = kv.Value != null ? kv.Value.ToString() : "";
                    }
                }
            }
            catch { }
        }

        if (string.IsNullOrWhiteSpace(templatePath))
        {
            templatePath = context.Request["template"] ?? @"c:\idash_prints\iDash_Std_Small.btw";
        }

        try
        {
            var result = BarTenderApiHelper.GeneratePreview(templatePath, fields);
            context.Response.Write(ser.Serialize(result));
        }
        catch (Exception ex)
        {
            context.Response.Write("{\"success\":false,\"error\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
        }
    }

    private void HandlePrint(HttpContext context, JavaScriptSerializer ser, string requestBody)
    {
        string templatePath = "";
        string printerName = "";
        Dictionary<string, string> fields = new Dictionary<string, string>();

        if (!string.IsNullOrWhiteSpace(requestBody))
        {
            try
            {
                var payload = ser.Deserialize<Dictionary<string, object>>(requestBody);
                if (payload.ContainsKey("template"))
                    templatePath = Convert.ToString(payload["template"]);

                if (payload.ContainsKey("printer"))
                    printerName = Convert.ToString(payload["printer"]);

                if (payload.ContainsKey("fields") && payload["fields"] is Dictionary<string, object>)
                {
                    var fDict = (Dictionary<string, object>)payload["fields"];
                    foreach (var kv in fDict)
                    {
                        fields[kv.Key] = kv.Value != null ? kv.Value.ToString() : "";
                    }
                }
            }
            catch { }
        }

        if (string.IsNullOrWhiteSpace(templatePath))
        {
            templatePath = context.Request["template"] ?? @"c:\idash_prints\iDash_Std_Small.btw";
        }

        try
        {
            var result = BarTenderApiHelper.PrintDirect(templatePath, printerName, fields);
            context.Response.Write(ser.Serialize(result));
        }
        catch (Exception ex)
        {
            context.Response.Write("{\"success\":false,\"error\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
        }
    }

    public bool IsReusable { get { return false; } }
}
