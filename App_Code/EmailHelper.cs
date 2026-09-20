
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;

public static class EmailHelper
{
    // ── JSON file path for recipients ────────────────────────────────────
    // Stored outside web.config so edits don't trigger an app pool recycle
    // (which kills all sessions and forces users to re-login).
    private static string RecipientsFilePath
    {
        get { return HttpContext.Current.Server.MapPath("~/config/email_recipients.json"); }
    }

    /// <summary>
    /// Sends to the global recipient list. All existing callers use this.
    /// </summary>
    public static void SendEmail(string subject, string body, List<Attachment> attachments)
    {
        var recipients = GetRecipients();
        if (recipients.Count == 0) return;
        SendEmailTo(recipients, subject, body, attachments);
    }

    /// <summary>
    /// Sends to an explicit recipient list — used by per-site routing in the report runner.
    /// Uses the same SMTP settings as SendEmail() (from web.config).
    /// </summary>
    public static void SendEmailTo(List<string> recipients, string subject, string body, List<Attachment> attachments)
    {
        if (recipients == null || recipients.Count == 0) return;

        // Read SMTP settings from web.config
        string smtpHost = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "localhost";
        int smtpPort;
        if (!int.TryParse(WebConfigurationManager.AppSettings["SMTP_Port"], out smtpPort))
            smtpPort = 25;

        string smtpUser    = WebConfigurationManager.AppSettings["SMTP_User"];
        string smtpPass    = WebConfigurationManager.AppSettings["SMTP_Password"];
        string smtpFrom    = WebConfigurationManager.AppSettings["SMTP_FromEmail"] ?? "no-reply@idash.local";
        string smtpFromName = WebConfigurationManager.AppSettings["SMTP_FromName"] ?? "iDash Reports";
        string defaultSubject = WebConfigurationManager.AppSettings["Default_EmailSubject"];

        using (SmtpClient client = new SmtpClient(smtpHost, smtpPort))
        using (MailMessage msg = new MailMessage())
        {
            client.Timeout = 15000;

            // SSL: respect explicit SMTP_SSL key, or fall back to enabling when credentials are present
            bool sslEnabled = false;
            string sslSetting = WebConfigurationManager.AppSettings["SMTP_SSL"];
            if (!string.IsNullOrEmpty(sslSetting))
                bool.TryParse(sslSetting, out sslEnabled);
            else
                sslEnabled = !string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass);

            client.EnableSsl = sslEnabled;

            if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
                client.Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass);

            msg.From = new MailAddress(smtpFrom, smtpFromName);

            foreach (var email in recipients)
                msg.To.Add(email);

            msg.Subject = !string.IsNullOrWhiteSpace(defaultSubject) ? defaultSubject : subject;
            msg.Body = body;
            msg.IsBodyHtml = true;

            if (attachments != null)
                foreach (var att in attachments)
                    msg.Attachments.Add(att);

            client.Send(msg);
        }
    }

    // ── Direct send to a specific address — used by Support Request and similar one-off emails.
    //    Uses the EXACT same SmtpClient setup as SendEmail() so it benefits from the same
    //    proven-working SMTP configuration that sends ENNX reports.
    public static void SendDirectEmail(
        string toAddress,   string toName,
        string ccAddress,   string ccName,
        string replyTo,     string replyToName,
        string subject,     string body,
        string fromDisplayName = "iDash")
    {
        string smtpHost = WebConfigurationManager.AppSettings["SMTP_Host"] ?? "localhost";
        int smtpPort;
        if (!int.TryParse(WebConfigurationManager.AppSettings["SMTP_Port"], out smtpPort))
            smtpPort = 25;

        string smtpUser     = WebConfigurationManager.AppSettings["SMTP_User"]      ?? "";
        string smtpPass     = WebConfigurationManager.AppSettings["SMTP_Password"]  ?? "";
        string smtpFrom     = WebConfigurationManager.AppSettings["SMTP_FromEmail"] ?? "no-reply@idash.local";

        using (SmtpClient client = new SmtpClient(smtpHost, smtpPort))
        using (MailMessage msg   = new MailMessage())
        {
            client.Timeout = 15000;  // 15-second limit — prevents hang when firewall silently drops TCP

            // Identical setup to SendEmail()
            if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
            {
                client.EnableSsl  = true;
                client.Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass);
            }

            msg.From    = new MailAddress(smtpFrom, fromDisplayName);
            msg.Subject = subject;
            msg.Body    = body;
            msg.IsBodyHtml = true;

            msg.To.Add(new MailAddress(toAddress, toName));

            if (!string.IsNullOrEmpty(ccAddress))
                msg.CC.Add(new MailAddress(ccAddress, ccName));

            if (!string.IsNullOrEmpty(replyTo))
                msg.ReplyToList.Add(new MailAddress(replyTo, replyToName));

            client.Send(msg);
        }
    }

    // ── Recipient list — reads from JSON file, falls back to web.config ─
    public static List<string> GetRecipients()
    {
        // Primary: read from JSON file
        if (File.Exists(RecipientsFilePath))
        {
            try
            {
                string json = File.ReadAllText(RecipientsFilePath);
                var js = new JavaScriptSerializer();
                var list = js.Deserialize<List<string>>(json);
                if (list != null) return list;
            }
            catch { /* fall through to web.config */ }
        }

        // Fallback: read from web.config (legacy / first run migration)
        var fallback = new List<string>();
        string raw = WebConfigurationManager.AppSettings["EmailRecipients"];
        if (!string.IsNullOrEmpty(raw))
        {
            fallback = raw.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries)
                          .Select(x => x.Trim())
                          .Where(x => !string.IsNullOrEmpty(x))
                          .ToList();

            // Auto-migrate: persist to JSON so future reads skip web.config
            SaveRecipientsToFile(fallback);
        }
        return fallback;
    }

    public static void AddRecipient(string email)
    {
        var list = GetRecipients();
        if (!list.Contains(email, StringComparer.OrdinalIgnoreCase))
        {
            list.Add(email);
            SaveRecipientsToFile(list);
        }
    }

    public static void RemoveRecipient(string email)
    {
        var list = GetRecipients();
        list.RemoveAll(x => x.Equals(email, StringComparison.OrdinalIgnoreCase));
        SaveRecipientsToFile(list);
    }

    // Writes to a standalone JSON file — does NOT touch web.config
    private static void SaveRecipientsToFile(List<string> list)
    {
        string dir = Path.GetDirectoryName(RecipientsFilePath);
        if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

        var js = new JavaScriptSerializer();
        string json = js.Serialize(list);
        File.WriteAllText(RecipientsFilePath, json);
    }

    public static string GetFromName()
    {
        return WebConfigurationManager.AppSettings["SMTP_FromName"] ?? "iDash Reports";
    }

    public static string GetFromEmailAddress()
    {
        return WebConfigurationManager.AppSettings["SMTP_FromEmail"] ?? "no-reply@idash.local";
    }

    public static string GetDefaultSubject()
    {
        return WebConfigurationManager.AppSettings["Default_EmailSubject"] ?? "";
    }

    public static void SaveEmailConfig(string fromName, string fromEmail, string defaultSubject)
    {
        var config = WebConfigurationManager.OpenWebConfiguration("~");
        var appSettings = config.AppSettings.Settings;

        if (appSettings["SMTP_FromName"] == null) appSettings.Add("SMTP_FromName", fromName);
        else appSettings["SMTP_FromName"].Value = fromName;

        if (appSettings["SMTP_FromEmail"] == null) appSettings.Add("SMTP_FromEmail", fromEmail);
        else appSettings["SMTP_FromEmail"].Value = fromEmail;

        if (appSettings["Default_EmailSubject"] == null) appSettings.Add("Default_EmailSubject", defaultSubject);
        else appSettings["Default_EmailSubject"].Value = defaultSubject;

        config.Save();
    }
}
