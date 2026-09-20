using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Web;
using System.Text;
using System.IO;
using System.Web.Configuration;

public static class AlertingService
{
    public static void SendAdminSms(string message, string triggerKey = null)
    {
        var config = WebConfigurationManager.OpenWebConfiguration("~");
        var appSettings = config.AppSettings.Settings;

        // Global flag kill-switch
        if (appSettings["SmsAlertsEnabled"] == null || appSettings["SmsAlertsEnabled"].Value.ToLower() != "true")
            return;

        // Granular flag checks
        if (!string.IsNullOrEmpty(triggerKey))
        {
            if (appSettings[triggerKey] == null || appSettings[triggerKey].Value.ToLower() != "true")
                return;
        }

        var recipients = new List<string>();
        bool usedCustom = false;
        
        // Priority 1: Trigger Specific Routing Override
        if (!string.IsNullOrEmpty(triggerKey))
        {
            string customKey = "SmsRecipients_" + triggerKey;
            if (appSettings[customKey] != null && !string.IsNullOrWhiteSpace(appSettings[customKey].Value))
            {
                recipients = appSettings[customKey].Value
                    .Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(x => x.Trim())
                    .Where(x => !string.IsNullOrEmpty(x))
                    .ToList();
                usedCustom = true;
            }
        }

        // Priority 2: Global System Routing Fallback
        if (!usedCustom && appSettings["SmsRecipients"] != null)
        {
             recipients = appSettings["SmsRecipients"].Value
                .Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(x => x.Trim())
                .Where(x => !string.IsNullOrEmpty(x))
                .ToList();
        }

        if (recipients.Count == 0) return;

        // Strip HTML / linebreaks for clean delivery
        string body = message.Replace("\r", " ").Replace("\n", " ");

        // Send via SMTP email
        string smtpHost = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "localhost";
        int smtpPort;
        if (!int.TryParse(WebConfigurationManager.AppSettings["SMTP_Port"], out smtpPort)) {
            smtpPort = 25;
        }
        string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
        string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];
        string smtpFrom = WebConfigurationManager.AppSettings["SMTP_FromEmail"] ?? "no-reply@idash.local";

        string smtpFromName = WebConfigurationManager.AppSettings["SMTP_FromName"] ?? "iDash System";

        using (SmtpClient client = new SmtpClient(smtpHost, smtpPort))
        using (MailMessage msg = new MailMessage())
        {
            if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
            {
                client.EnableSsl = true;
                client.Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass);
            }

            msg.From = new MailAddress(smtpFrom, smtpFromName);
            
            foreach (var phoneEmail in recipients)
            {
                msg.To.Add(phoneEmail);
            }
            
            msg.Subject = "AWX";
            msg.Body = body;
            msg.IsBodyHtml = false;

            try 
            {
                client.Send(msg);
            }
            catch (Exception ex)
            {
                // We MUST bubble up raw exceptions when testing diagnostic triggers so users can see SMTP blockages on the UI.
                if (triggerKey == "Alert_TagAuditReport") throw new Exception("SMTP Drop: " + ex.Message, ex);
            }
        }
    }

    public static void SendSystemEmail(string subject, string bodyHtml, string triggerKey, List<Attachment> attachments = null)
    {
        var config = WebConfigurationManager.OpenWebConfiguration("~");
        var appSettings = config.AppSettings.Settings;

        // Global flag kill-switch
        if (appSettings["SmsAlertsEnabled"] == null || appSettings["SmsAlertsEnabled"].Value.ToLower() != "true")
            return;

        // Granular flag checks
        if (!string.IsNullOrEmpty(triggerKey))
        {
            if (appSettings[triggerKey] == null || appSettings[triggerKey].Value.ToLower() != "true")
                return;
        }

        var recipients = new List<string>();
        bool usedCustom = false;
        
        // Priority 1: Trigger Specific Routing Override
        if (!string.IsNullOrEmpty(triggerKey))
        {
            string customKey = "SmsRecipients_" + triggerKey;
            if (appSettings[customKey] != null && !string.IsNullOrWhiteSpace(appSettings[customKey].Value))
            {
                recipients = appSettings[customKey].Value
                    .Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(x => x.Trim())
                    .Where(x => !string.IsNullOrEmpty(x))
                    .ToList();
                usedCustom = true;
            }
        }

        // Priority 2: Global System Routing Fallback
        if (!usedCustom && appSettings["SmsRecipients"] != null)
        {
             recipients = appSettings["SmsRecipients"].Value
                .Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(x => x.Trim())
                .Where(x => !string.IsNullOrEmpty(x))
                .ToList();
        }

        if (recipients.Count == 0) return;

        string smtpHost = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "localhost";
        int smtpPort;
        if (!int.TryParse(WebConfigurationManager.AppSettings["SMTP_Port"], out smtpPort)) {
            smtpPort = 25;
        }
        string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
        string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];
        string smtpFrom = WebConfigurationManager.AppSettings["SMTP_FromEmail"] ?? "no-reply@idash.local";

        string smtpFromName = WebConfigurationManager.AppSettings["SMTP_FromName"] ?? "iDash System";

        using (SmtpClient client = new SmtpClient(smtpHost, smtpPort))
        using (MailMessage msg = new MailMessage())
        {
            if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
            {
                client.EnableSsl = true;
                client.Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass);
            }

            msg.From = new MailAddress(smtpFrom, smtpFromName);
            
            foreach (var email in recipients)
            {
                msg.To.Add(email);
            }
            
            msg.Subject = subject;
            msg.Body = bodyHtml;
            msg.IsBodyHtml = true;

            if (attachments != null)
            {
                foreach (var att in attachments)
                {
                    msg.Attachments.Add(att);
                }
            }

            try 
            {
                client.Send(msg);
            }
            catch (Exception ex)
            {
                if (triggerKey == "Alert_TagAuditReport" || triggerKey == "Report_Ennx" || triggerKey == "Report_Stats") 
                    throw new Exception("SMTP Drop: " + ex.Message, ex);
            }
        }
    }
}
