using System;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.UI;

public partial class va_license_activation : Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            LoadHardwareIdentity();
            LoadCurrentLicenseStatus();

            string reason = Request.QueryString["reason"];
            if (!string.IsNullOrEmpty(reason) && !LicenseManager.IsLicensed())
            {
                ShowMsg("warn", "&#9888; Access Restricted: " + Server.HtmlEncode(reason));
            }
        }
    }

    private void LoadHardwareIdentity()
    {
        var hw = LicenseManager.GetHardwareIdentity();
        LitInstallationId.Text = hw.InstallationId;
        LitMachineName.Text    = hw.MachineName;
        LitPrimaryMac.Text      = hw.PrimaryMac;
    }

    private void LoadCurrentLicenseStatus()
    {
        var lic = LicenseManager.GetActiveLicense(true);

        if (lic.IsValid && lic.Payload != null)
        {
            LitStatusBadge.Text = "<span class=\"badge active\">&#10004; " + Server.HtmlEncode(lic.StatusDisplay) + "</span>";
            LitCustomer.Text    = Server.HtmlEncode(lic.Payload.Customer ?? "");
            LitSiteName.Text    = Server.HtmlEncode(lic.Payload.SiteName ?? "");
            LitStationNumber.Text = Server.HtmlEncode(lic.Payload.StationNumber ?? "");
            LitLicenseType.Text = Server.HtmlEncode(lic.Payload.LicenseType ?? "Perpetual");
            LitExpiration.Text  = lic.IsPerpetual
                ? "Never (Perpetual License)"
                : (lic.ExpirationUtc.HasValue ? lic.ExpirationUtc.Value.ToString("yyyy-MM-dd") + " (" + lic.DaysRemaining + " days left)" : "None");
            
            LnkEnterHub.Visible = true;
        }
        else
        {
            LitStatusBadge.Text = "<span class=\"badge unlicensed\">&#10060; " + Server.HtmlEncode(lic.StatusDisplay) + "</span>";
            LnkEnterHub.Visible = false;
        }
    }

    private void ShowMsg(string type, string msg)
    {
        LitStatusMessage.Text = string.Format("<div class=\"msg-box {0}\">{1}</div>", type, msg);
    }

    protected void BtnApplyOffline_Click(object sender, EventArgs e)
    {
        string key = "";

        // File upload takes precedence if provided
        if (FuLicenseFile.HasFile)
        {
            try
            {
                using (var reader = new StreamReader(FuLicenseFile.FileContent, Encoding.UTF8))
                {
                    key = reader.ReadToEnd().Trim();
                }
            }
            catch (Exception ex)
            {
                ShowMsg("err", "Error reading uploaded license file: " + Server.HtmlEncode(ex.Message));
                return;
            }
        }

        // If no file was uploaded, fallback to textarea input
        if (string.IsNullOrEmpty(key))
        {
            key = TxtLicenseString.Text.Trim();
        }

        if (string.IsNullOrEmpty(key))
        {
            ShowMsg("err", "Please paste a license key string or choose a .idashlic file to upload.");
            return;
        }

        // Check if user accidentally pasted an Installation ID instead of the actual license key
        if (key.StartsWith("IDASH-") && !key.StartsWith("IDASH-LIC-"))
        {
            ShowMsg("warn", "&#9888; <strong>Notice:</strong> <code>" + Server.HtmlEncode(key) + "</code> is an <strong>Installation ID</strong>, not a license key.<br/>Please choose your <code>.idashlic</code> file below or paste the cryptographic license key (beginning with <code>IDASH-LIC-v1-</code>). You can download it directly from <a href=\"va_license_manager.aspx#sec-carts\" style=\"color:var(--accent); font-weight:700;\">Mobile Carts &amp; Workstations Registry</a>.");
            return;
        }

        var result = LicenseManager.ApplyLicense(key);
        if (result.IsValid)
        {
            ShowMsg("ok", "&#9989; License applied and verified successfully! Your system is now fully activated.");
            TxtLicenseString.Text = key;
            LoadCurrentLicenseStatus();
        }
        else
        {
            ShowMsg("err", "&#10060; License activation failed: " + Server.HtmlEncode(result.StatusReason));
            LoadCurrentLicenseStatus();
        }
    }

    protected void BtnApplyOnline_Click(object sender, EventArgs e)
    {
        string productKey = TxtProductKey.Text.Trim();
        string serverUrl  = TxtServerUrl.Text.Trim();

        if (string.IsNullOrEmpty(productKey))
        {
            ShowMsg("err", "Please enter a valid Product Key.");
            return;
        }

        // Online activation stub
        try
        {
            var hw = LicenseManager.GetHardwareIdentity();
            string endpoint = serverUrl.TrimEnd('/') + "/api/v1/activate";

            using (var wc = new WebClient())
            {
                wc.Headers[HttpRequestHeader.ContentType] = "application/json";
                string jsonPayload = string.Format("{{\"ProductKey\":\"{0}\",\"HardwareId\":\"{1}\",\"MachineName\":\"{2}\"}}", productKey, hw.PrimaryMac, hw.MachineName);
                
                // Attempt connection
                string response = wc.UploadString(endpoint, jsonPayload);
                var result = LicenseManager.ApplyLicense(response.Trim());
                if (result.IsValid)
                {
                    ShowMsg("ok", "&#9989; Online activation successful! Your system is now activated.");
                    LoadCurrentLicenseStatus();
                    return;
                }
            }
        }
        catch (Exception ex)
        {
            ShowMsg("warn", "&#9888; Online activation could not connect to '" + Server.HtmlEncode(serverUrl) + "': " + Server.HtmlEncode(ex.Message) + "<br/>If this cart is offline or air-gapped, please use <strong>Option A (Offline Activation)</strong> above.");
        }
    }
}
