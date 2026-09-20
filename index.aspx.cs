using System;
using System.Net.Mail;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web.Configuration;

// Session key constants (shared with va_user_management.aspx.cs)
// SESSION_AUTH  = "IsAdminAuthenticated"  (bool  — true when logged in)
// SESSION_ROLE  = "IdashUserRole"          (string — admin | user | readonly)
// SESSION_USER  = "IdashUsername"          (string — the logged-in username)
// SESSION_TILES = "IdashTileAccess"        (List<string> — tile section keys)
// SESSION_SITES = "IdashSiteAccess"        (Dictionary<string,string> — site access map)

public partial class index : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
        Response.Cache.SetNoStore();

        if (!IsPostBack)
        {
            CheckLoginState();
        }
    }

    private void CheckLoginState()
    {
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        string role = Convert.ToString(Session["IdashUserRole"]);

        PnlLogin.Visible     = !isLoggedIn;
        // Only admins or users with specific granular admin access see the protected panel
        PnlProtected.Visible = isLoggedIn && (UserManager.CanAccessAdmin(role) || CanSeeSection("admin_"));

        // Documentation access removed (handled inline via CanSeeTile logic)
    }

    protected void BtnLogin_Click(object sender, EventArgs e)
    {
        string username = TxtUser.Text.Trim();
        string password = TxtPass.Text;   // Do NOT trim passwords — alters the hash

        var user = UserManager.Authenticate(username, password);

        if (user != null)
        {
            if (!UserManager.HasAcceptedAgreement(user.Username))
            {
                UserManager.RecordAgreementAccepted(user.Username);
            }

            Session["IsAdminAuthenticated"] = true;
            Session["IdashUserRole"]         = user.Role;
            Session["IdashUsername"]          = user.Username;
            Session["IdashTileAccess"]        = user.TileAccess;
            Session["IdashSiteAccess"]        = user.SiteAccess;
            LblLoginError.Text = "";
            LoginAuditHelper.LogLogin(username, Request.UserHostAddress, true, user.Role);

            string target = GetSafeReturnUrl();
            if (!UserManager.CanAccessAdmin(user.Role))
            {
                // Non-admin users: show a brief welcome then redirect
                LblLoginError.ForeColor = System.Drawing.Color.FromArgb(0x10, 0xb9, 0x81);
                LblLoginError.Text = "Welcome, " + Server.HtmlEncode(user.DisplayName) + ". Redirecting...";
                Response.AddHeader("Refresh", "1;url=" + target);
            }
            else if (!target.Equals("index.aspx", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect(target);
                return;
            }
        }
        else
        {
            LblLoginError.Text = "Invalid username or password, or account is disabled.";
            LoginAuditHelper.LogLogin(username, Request.UserHostAddress, false);
        }

        CheckLoginState();
    }

    private string GetSafeReturnUrl()
    {
        string raw = Request.QueryString["returnUrl"];
        if (string.IsNullOrWhiteSpace(raw)) return "index.aspx";

        string decoded = Server.UrlDecode(raw).Trim();

        // Prevent open redirect vulnerabilities
        if (decoded.StartsWith("http:", StringComparison.OrdinalIgnoreCase) ||
            decoded.StartsWith("https:", StringComparison.OrdinalIgnoreCase) ||
            decoded.StartsWith("//", StringComparison.Ordinal) ||
            decoded.StartsWith("\\", StringComparison.Ordinal))
        {
            return "index.aspx";
        }

        return decoded;
    }

    protected void BtnLoginGate_Click(object sender, EventArgs e)
    {
        string username = TxtUserGate.Text.Trim();
        string password = TxtPassGate.Text;

        if (string.IsNullOrEmpty(username))
        {
            LblLoginGateError.Text = "Please enter your username.";
            return;
        }

        var user = UserManager.Authenticate(username, password);

        if (user == null)
        {
            LblLoginGateError.Text = "Invalid username or password, or account is disabled.";
            LoginAuditHelper.LogLogin(username, Request.UserHostAddress, false);
            return;
        }

        // Check if user has accepted the Software Usage & Non-Duplication Agreement
        bool hasAccepted = UserManager.HasAcceptedAgreement(user.Username);

        if (!hasAccepted)
        {
            if (!ChkAgreementGate.Checked)
            {
                LblLoginGateError.Text = "Agreement Required: You must review and check the agreement box before your first sign-in.";
                return;
            }

            // Record initial acceptance
            UserManager.RecordAgreementAccepted(user.Username);
        }
        else if (ChkAgreementGate.Checked)
        {
            // Refresh timestamp if re-checked
            UserManager.RecordAgreementAccepted(user.Username);
        }

        // Successfully authenticated and agreement satisfied
        Session["IsAdminAuthenticated"] = true;
        Session["IdashUserRole"]         = user.Role;
        Session["IdashUsername"]          = user.Username;
        Session["IdashTileAccess"]        = user.TileAccess;
        Session["IdashSiteAccess"]        = user.SiteAccess;
        LblLoginGateError.Text = "";
        LblLoginError.Text = "";
        LoginAuditHelper.LogLogin(username, Request.UserHostAddress, true, user.Role);

        string target = GetSafeReturnUrl();
        Response.Redirect(target);
    }

    protected void BtnLogout_Click(object sender, EventArgs e)
    {
        Session["IsAdminAuthenticated"] = false;
        Session.Remove("IsAdminAuthenticated");
        Session.Remove("IdashUserRole");
        Session.Remove("IdashUsername");
        Session.Remove("IdashTileAccess");
        Session.Remove("IdashSiteAccess");
        TxtUser.Text = "";
        TxtPass.Text = "";
        CheckLoginState();
    }

    /// <summary>True if user is currently authenticated.</summary>
    protected bool IsLoggedIn
    {
        get { return Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"]; }
    }

    /// <summary>Used by index.aspx to conditionally show/hide individual tiles.</summary>
    protected bool CanSeeTile(string tileKey)
    {
        if (!IsLoggedIn) return false;  // Login required for all tiles
        string role = Convert.ToString(Session["IdashUserRole"]);
        if (role == UserManager.ROLE_ADMIN) return true;
        var tiles = Session["IdashTileAccess"] as List<string>;
        return UserManager.CanAccessTile(role, tiles, tileKey);
    }

    /// <summary>Returns true if user has ANY tile starting with the given prefix(es). Used for section headers.</summary>
    protected bool CanSeeSection(params string[] prefixes)
    {
        if (!IsLoggedIn) return false;
        string role = Convert.ToString(Session["IdashUserRole"]);
        if (role == UserManager.ROLE_ADMIN) return true;
        var tiles = Session["IdashTileAccess"] as List<string>;
        if (tiles == null || tiles.Count == 0) return false;
        if (tiles.Contains("*")) return true;
        foreach (var prefix in prefixes)
            foreach (var t in tiles)
                if (t.StartsWith(prefix) || t == prefix) return true;
        return false;
    }

    /// <summary>Returns a display label for the current user's site, used in the support email subject.</summary>
    protected string GetSiteLabel()
    {
        if (!IsLoggedIn) return System.Environment.MachineName;
        var siteAccess = Session["IdashSiteAccess"] as Dictionary<string, string>;
        if (siteAccess == null || siteAccess.Count == 0)
            return System.Environment.MachineName;
        // Wildcard (*) means admin/unrestricted — fall back to machine name
        if (siteAccess.ContainsKey("*"))
            return System.Environment.MachineName;
        // Keys are site names exactly as in dbo.company.name (e.g. "613 Martinsburg")
        return string.Join(", ", siteAccess.Keys.Where(k => !string.IsNullOrWhiteSpace(k)).OrderBy(k => k));
    }

    // Support Request email is now handled by support_send.ashx (AJAX handler).
    // No postback needed — the modal uses fetch() to call the handler directly.
}
