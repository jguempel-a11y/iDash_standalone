<%@ WebHandler Language="C#" Class="iDash.SupportSendHandler" %>

using System;
using System.Web;
using System.Web.Configuration;
using System.Web.SessionState;

namespace iDash
{
    /// <summary>
    /// Lightweight AJAX handler for Support Request emails.
    /// Called via fetch() from the modal — no postback, no ViewState, instant response.
    /// Uses EmailHelper.SendDirectEmail() — same proven SMTP path as ENNX reports.
    /// </summary>
    public class SupportSendHandler : IHttpHandler, IRequiresSessionState
    {
        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            // Only allow POST
            if (context.Request.HttpMethod != "POST")
            {
                context.Response.StatusCode = 405;
                context.Response.Write("{\"ok\":false,\"error\":\"Method not allowed\"}");
                return;
            }

            // Must be logged in
            if (context.Session["IdashSiteAccess"] == null)
            {
                context.Response.StatusCode = 401;
                context.Response.Write("{\"ok\":false,\"error\":\"Not authenticated\"}");
                return;
            }

            string name    = (context.Request.Form["name"]    ?? "").Trim();
            string email   = (context.Request.Form["email"]   ?? "").Trim();
            string phone   = (context.Request.Form["phone"]   ?? "").Trim();
            string message = (context.Request.Form["message"] ?? "").Trim();
            string subject = (context.Request.Form["subject"] ?? "").Trim();

            // Server-side validation
            if (string.IsNullOrEmpty(name) || string.IsNullOrEmpty(email) ||
                string.IsNullOrEmpty(phone) || string.IsNullOrEmpty(message))
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"ok\":false,\"error\":\"All fields are required\"}");
                return;
            }

            if (!email.Contains("@") || !email.Contains("."))
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"ok\":false,\"error\":\"Invalid email address\"}");
                return;
            }

            // Build HTML body — same format as the postback version
            string body =
                "<html><body style='font-family:Segoe UI,Arial,sans-serif;'>" +
                "<h2 style='color:#1e293b;'>iDash Support Request</h2>" +
                "<table style='border-collapse:collapse; width:100%; max-width:600px;'>" +
                "<tr><td style='padding:8px 12px; font-weight:bold; border-bottom:1px solid #e2e8f0; width:130px;'>Subject</td>" +
                    "<td style='padding:8px 12px; border-bottom:1px solid #e2e8f0;'>" + HttpUtility.HtmlEncode(subject) + "</td></tr>" +
                "<tr><td style='padding:8px 12px; font-weight:bold; border-bottom:1px solid #e2e8f0;'>Name</td>" +
                    "<td style='padding:8px 12px; border-bottom:1px solid #e2e8f0;'>" + HttpUtility.HtmlEncode(name) + "</td></tr>" +
                "<tr><td style='padding:8px 12px; font-weight:bold; border-bottom:1px solid #e2e8f0;'>Email</td>" +
                    "<td style='padding:8px 12px; border-bottom:1px solid #e2e8f0;'><a href='mailto:" + HttpUtility.HtmlEncode(email) + "'>" + HttpUtility.HtmlEncode(email) + "</a></td></tr>" +
                "<tr><td style='padding:8px 12px; font-weight:bold; border-bottom:1px solid #e2e8f0;'>Phone</td>" +
                    "<td style='padding:8px 12px; border-bottom:1px solid #e2e8f0;'>" + HttpUtility.HtmlEncode(phone) + "</td></tr>" +
                "</table>" +
                "<h3 style='color:#334155; margin-top:20px;'>Issue Description</h3>" +
                "<div style='background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:16px; white-space:pre-wrap;'>" +
                    HttpUtility.HtmlEncode(message) + "</div>" +
                "<p style='color:#94a3b8; font-size:12px; margin-top:24px;'>Sent from iDash on " +
                    Environment.MachineName + " &mdash; " + DateTime.Now.ToString("yyyy-MM-dd HH:mm") + "</p>" +
                "</body></html>";

            try
            {
                EmailHelper.SendDirectEmail(
                    toAddress:       "varfid_support@id-integration.com",
                    toName:          "ID Integration Support",
                    ccAddress:       email,
                    ccName:          name,
                    replyTo:         email,
                    replyToName:     name,
                    subject:         subject,
                    body:            body,
                    fromDisplayName: "iDash Support Request"
                );

                context.Response.Write("{\"ok\":true}");
            }
            catch (Exception ex)
            {
                string errMsg = ex.Message;
                if (ex.InnerException != null) errMsg += " -> " + ex.InnerException.Message;

                // Escape for JSON
                errMsg = errMsg.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", " ");

                string smtpHost = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "?";
                context.Response.StatusCode = 500;
                context.Response.Write("{\"ok\":false,\"error\":\"Failed to send via " +
                    smtpHost.Replace("\"", "\\\"") + ": " + errMsg + "\"}");
            }
        }
    }
}
