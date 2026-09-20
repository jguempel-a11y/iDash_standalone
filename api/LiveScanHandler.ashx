<%@ WebHandler Language="C#" Class="LiveScanHandler" %>

using System;
using System.Web;
using System.IO;
using System.Web.Script.Serialization; // For JSON

public class LiveScanHandler : IHttpHandler, System.Web.SessionState.IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        
        // ── Security Check: Require authenticated session ──
        bool isLoggedIn = context.Session != null && (
            (context.Session["IsAdminAuthenticated"] != null && (bool)context.Session["IsAdminAuthenticated"]) ||
            context.Session["IdashUserRole"] != null ||
            (context.User != null && context.User.Identity != null && context.User.Identity.IsAuthenticated)
        );

        if (!isLoggedIn)
        {
            context.Response.StatusCode = 401;
            context.Response.Write(Json(new { success = false, error = "Authentication required." }));
            return;
        }

        string action = context.Request["action"];

        if (action == "save")
        {
            SaveSession(context);
        }
        else if (action == "whoami")
        {
            string u = context.User.Identity.Name;
            if (string.IsNullOrEmpty(u)) u = "Guest";
            context.Response.Write(Json(new { user = u }));
        }
        else
        {
            context.Response.Write(Json(new { success = false, message = "Unknown action" }));
        }
    }

    private void SaveSession(HttpContext context)
    {
        try
        {
            // Read JSON body
            string body;
            using (var reader = new StreamReader(context.Request.InputStream))
            {
                body = reader.ReadToEnd();
            }

            var serializer = new JavaScriptSerializer();
            // Create a DTO for the payload
            var payload = serializer.Deserialize<SessionPayload>(body);

            string user = context.User.Identity.Name ?? "MobileUser";

            var result = LiveScanService.SaveSession(
                payload.station,
                user,
                payload.startedUtc,
                payload.endedUtc,
                payload.summary,
                payload.json, // full json blob
                payload.ennx
            );

            context.Response.Write(Json(result));
        }
        catch (Exception ex)
        {
            context.Response.Write(Json(new { success = false, message = ex.Message }));
        }
    }

    private string Json(object data)
    {
        return new JavaScriptSerializer().Serialize(data);
    }

    public bool IsReusable
    {
        get { return false; }
    }

    // DTO for incoming JSON
    public class SessionPayload
    {
        public string station { get; set; }
        public string summary { get; set; }
        public string startedUtc { get; set; }
        public string endedUtc { get; set; }
        public string json { get; set; }
        public string ennx { get; set; }
    }
}
