<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_license_activation.aspx.cs" Inherits="va_license_activation" ResponseEncoding="utf-8" EnableEventValidation="false" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash Software Activation &mdash; VA Asset Intelligence Hub</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
<style>
    :root {
        --accent: #2ea8ff;
        --accent-2: #10b981;
        --bg: #0b1329;
        --card: #131f3d;
        --chip: #18274d;
        --line: #223668;
        --text: #e2e8f0;
        --muted: #8aa0c5;
        --danger: #ef4444;
        --warn: #f59e0b;
        --success: #10b981;
    }
    [data-theme="light"] {
        --bg: #f8fafc;
        --card: #ffffff;
        --chip: #f1f5f9;
        --line: #cbd5e1;
        --text: #0f172a;
        --muted: #64748b;
    }
    * { box-sizing: border-box; }
    body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', -apple-system, sans-serif; margin: 0; padding: 24px; min-height: 100vh; }
    .container { max-width: 960px; margin: 0 auto; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--line); padding-bottom: 18px; margin-bottom: 24px; }
    .title-group h1 { margin: 0 0 6px; font-size: 24px; color: var(--text); display: flex; align-items: center; gap: 10px; }
    .title-group p { margin: 0; font-size: 14px; color: var(--muted); }
    .header-actions { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
    .nav-pill { display: inline-flex; align-items: center; gap: 5px; padding: 6px 14px; border-radius: 8px; font-size: 12px; font-weight: 600; text-decoration: none; border: 1px solid var(--line); color: var(--muted); cursor: pointer; background: transparent; transition: all .15s; }
    .nav-pill:hover { border-color: var(--accent); color: var(--accent); }
    .btn { display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; border-radius: 8px; font-weight: 600; font-size: 13px; text-decoration: none; border: 1px solid transparent; cursor: pointer; transition: all 0.15s; }
    .btn.primary { background: var(--accent); color: #fff; }
    .btn.primary:hover { opacity: 0.9; }
    .btn.success { background: var(--success); color: #fff; }
    .btn.success:hover { opacity: 0.9; }
    .btn.secondary { background: var(--chip); color: var(--text); border-color: var(--line); }
    .btn.secondary:hover { background: var(--card); }
    
    .panel { background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 22px; margin-bottom: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    .panel-title { font-size: 16px; font-weight: 700; margin: 0 0 14px; display: flex; align-items: center; justify-content: space-between; }
    
    .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 700; }
    .badge.active { background: rgba(16, 185, 129, 0.15); color: #10b981; border: 1px solid #10b981; }
    .badge.unlicensed { background: rgba(239, 68, 68, 0.15); color: #ef4444; border: 1px solid #ef4444; }
    .badge.expired { background: rgba(245, 158, 11, 0.15); color: #f59e0b; border: 1px solid #f59e0b; }
    
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    @media(max-width: 768px) { .grid-2 { grid-template-columns: 1fr; } }
    
    .id-box { background: var(--chip); border: 1px dashed var(--line); border-radius: 8px; padding: 14px; font-family: Consolas, monospace; font-size: 13px; word-break: break-all; margin: 10px 0; display: flex; justify-content: space-between; align-items: center; }
    .id-box code { color: var(--accent); font-weight: 700; font-size: 15px; }
    
    .tabs { display: flex; gap: 8px; margin-bottom: 16px; border-bottom: 1px solid var(--line); padding-bottom: 8px; }
    .tab-btn { background: transparent; color: var(--muted); border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; }
    .tab-btn.active { background: var(--chip); color: var(--accent); }
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    
    .msg-box { padding: 12px 16px; border-radius: 8px; font-size: 13px; margin-bottom: 18px; line-height: 1.5; }
    .msg-box.ok { background: rgba(16,185,129,0.15); border: 1px solid var(--success); color: #10b981; }
    .msg-box.err { background: rgba(239,68,68,0.15); border: 1px solid var(--danger); color: #ef4444; }
    .msg-box.warn { background: rgba(245,158,11,0.15); border: 1px solid var(--warn); color: #f59e0b; }
    
    textarea, input[type="text"] { width: 100%; background: var(--chip); color: var(--text); border: 1px solid var(--line); border-radius: 8px; padding: 10px; font-family: Consolas, monospace; font-size: 13px; }
    textarea:focus, input[type="text"]:focus { outline: none; border-color: var(--accent); }

    /* Unified Top License Navigation Tabs */
    .tabs-bar { display: flex; gap: 8px; margin-bottom: 24px; border-bottom: 1px solid var(--line); padding-bottom: 12px; flex-wrap: wrap; }
    .main-tab-btn { display: inline-flex; align-items: center; gap: 8px; padding: 9px 18px; border-radius: 8px; font-size: 13px; font-weight: 700; border: 1px solid var(--line); background: var(--card); color: var(--muted); cursor: pointer; text-decoration: none; transition: all .15s; }
    .main-tab-btn:hover { color: var(--text); border-color: var(--accent); }
    .main-tab-btn.active { background: var(--accent); color: var(--bg); border-color: var(--accent); }
</style>
</head>
<body>
<form id="form1" runat="server" enctype="multipart/form-data">
<div class="container">

    <!-- HEADER -->
    <div class="header">
        <div class="title-group">
            <h1>&#128273; iDash Software Activation</h1>
            <p>Cryptographic License Management for VA Asset Intelligence Hub</p>
        </div>
        <div class="header-actions">
            <button type="button" class="nav-pill" onclick="location.reload()">&#8635; Refresh</button>
            <button type="button" class="nav-pill" id="themeBtn" onclick="toggleTheme()" title="Toggle light/dark">☀️</button>
            <a href="documentation/va_software_agreement.html" target="_blank" class="nav-pill">&#128220; Agreement</a>
            <a href="va_license_manager.aspx#sec-carts" class="nav-pill">&#128722; Carts Registry</a>
            <a href="va_license_manager.aspx#sec-live" class="nav-pill">&#128225; Device Licenses</a>
            <a href="documentation/va_license_manager.html" target="_blank" class="nav-pill">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
        </div>
    </div>

    <!-- UNIFIED LICENSE NAVIGATION TABS -->
    <div class="tabs-bar">
        <a href="va_license_manager.aspx#sec-live" class="main-tab-btn">&#128225; Active Readers &amp; Device Licenses</a>
        <a href="va_license_manager.aspx#sec-carts" class="main-tab-btn">&#128722; Mobile Carts &amp; Workstations Registry</a>
        <span class="main-tab-btn active">&#128273; Local iDash Activation</span>
    </div>

    <asp:Literal ID="LitStatusMessage" runat="server" />

    <!-- SYSTEM IDENTITY & LICENSE STATUS -->
    <div class="grid-2">
        <!-- HARDWARE IDENTIFIER -->
        <div class="panel">
            <div class="panel-title">
                <span>&#128187; System Hardware Identity</span>
                <span style="font-size:11px; color:var(--muted); font-weight:normal;">Node-Locked</span>
            </div>
            <p style="font-size:13px; color:var(--muted); margin:0 0 10px;">
                Use this Installation ID to request an offline cryptographic license key for this cart or server:
            </p>
            <div class="id-box">
                <code id="lblInstallationId"><asp:Literal ID="LitInstallationId" runat="server" /></code>
                <button type="button" class="btn secondary" onclick="copyId()" style="padding:4px 10px; font-size:11px;">&#128203; Copy ID</button>
            </div>
            <div style="font-size:12px; color:var(--muted); display:flex; justify-content:space-between; margin-top:12px;">
                <span>Server: <strong><asp:Literal ID="LitMachineName" runat="server" /></strong></span>
                <span>Primary MAC: <strong><asp:Literal ID="LitPrimaryMac" runat="server" /></strong></span>
            </div>
        </div>

        <!-- CURRENT STATUS -->
        <div class="panel">
            <div class="panel-title">
                <span>&#128737;&#65039; Active License Status</span>
                <asp:Literal ID="LitStatusBadge" runat="server" />
            </div>
            <div style="font-size:13px; line-height:1.7;">
                <div>Customer: <strong><asp:Literal ID="LitCustomer" runat="server" Text="&mdash;" /></strong></div>
                <div>Facility / Site: <strong><asp:Literal ID="LitSiteName" runat="server" Text="&mdash;" /></strong> (<asp:Literal ID="LitStationNumber" runat="server" Text="&mdash;" />)</div>
                <div>License Type: <strong><asp:Literal ID="LitLicenseType" runat="server" Text="&mdash;" /></strong></div>
                <div>Expiration: <strong><asp:Literal ID="LitExpiration" runat="server" Text="&mdash;" /></strong></div>
                <div style="margin-top:10px;">
                    <asp:HyperLink ID="LnkEnterHub" runat="server" NavigateUrl="index.aspx" CssClass="btn success" Visible="false">&#8679; Launch iDash Hub</asp:HyperLink>
                </div>
            </div>
        </div>
    </div>

    <!-- ACTIVATION WAYS -->
    <div class="panel">
        <div class="tabs">
            <button type="button" class="tab-btn active" onclick="showTab('offline')">&#128225; Option A: Offline / Air-Gapped Activation (Recommended)</button>
            <button type="button" class="tab-btn" onclick="showTab('online')">&#127760; Option B: Online Product Key</button>
        </div>

        <!-- TAB A: OFFLINE ACTIVATION -->
        <div id="tab-offline" class="tab-content active">
            <p style="font-size:13px; color:var(--muted); margin:0 0 14px;">
                Ideal for air-gapped hospital subnets and standalone mobile carts. Paste your cryptographic license key (beginning with <code>IDASH-LIC-v1-</code>) or upload a <code>.idashlic</code> file generated by your license administrator.
            </p>

            <label style="font-size:12px; font-weight:700; display:block; margin-bottom:6px;">Paste License Key String:</label>
            <asp:TextBox ID="TxtLicenseString" runat="server" TextMode="MultiLine" Rows="4" placeholder="IDASH-LIC-v1-eyJWZXJzaW9uIjoxLCJBbGdvcml0aG0iOiJSU0EyMDQ4LV..." />

            <div style="margin: 14px 0; display:flex; align-items:center; gap:12px;">
                <span style="font-size:12px; color:var(--muted); font-weight:700;">OR Upload .idashlic File:</span>
                <asp:FileUpload ID="FuLicenseFile" runat="server" style="font-size:12px;" />
            </div>

            <asp:Button ID="BtnApplyOffline" runat="server" Text="&#10004; Apply &amp; Validate License" CssClass="btn primary" OnClick="BtnApplyOffline_Click" />
        </div>

        <!-- TAB B: ONLINE CLOUD ACTIVATION -->
        <div id="tab-online" class="tab-content">
            <p style="font-size:13px; color:var(--muted); margin:0 0 14px;">
                If this cart or server has outbound internet or VA intranet access to the licensing server, enter your 16-character Product Key for automatic 1-click activation.
            </p>

            <div style="max-width:500px;">
                <label style="font-size:12px; font-weight:700; display:block; margin-bottom:6px;">Product Key:</label>
                <asp:TextBox ID="TxtProductKey" runat="server" placeholder="IDASH-XXXX-XXXX-XXXX-XXXX" style="margin-bottom:12px;" />

                <label style="font-size:12px; font-weight:700; display:block; margin-bottom:6px;">Licensing Server URL (Optional Override):</label>
                <asp:TextBox ID="TxtServerUrl" runat="server" Text="https://licensing.assetworx-idash.com" style="margin-bottom:16px;" />

                <asp:Button ID="BtnApplyOnline" runat="server" Text="&#127760; Connect &amp; Activate Online" CssClass="btn primary" OnClick="BtnApplyOnline_Click" />
            </div>
        </div>
    </div>

</div>
<idash:Footer runat="server" />
</form>

<script>
function copyId() {
    var text = document.getElementById('lblInstallationId').innerText;
    navigator.clipboard.writeText(text).then(function() {
        alert('Installation ID copied to clipboard: ' + text);
    });
}
function showTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
    document.querySelectorAll('.tab-content').forEach(function(c) { c.classList.remove('active'); });
    if (tab === 'offline') {
        document.querySelectorAll('.tab-btn')[0].classList.add('active');
        document.getElementById('tab-offline').classList.add('active');
    } else {
        document.querySelectorAll('.tab-btn')[1].classList.add('active');
        document.getElementById('tab-online').classList.add('active');
    }
}

function toggleTheme() {
    var html = document.documentElement;
    var isDark = html.getAttribute('data-theme') !== 'light';
    var next = isDark ? 'light' : 'dark';
    if (next === 'dark') html.removeAttribute('data-theme');
    else html.setAttribute('data-theme', next);
    localStorage.setItem('idash_theme', next === 'dark' ? '' : next);
    updateThemeBtn();
}
function updateThemeBtn() {
    var btn = document.getElementById('themeBtn');
    if (!btn) return;
    var isLight = document.documentElement.getAttribute('data-theme') === 'light';
    btn.textContent = isLight ? '🌙' : '☀️';
}
updateThemeBtn();

// Auto-populate textarea when .idashlic file is selected
(function() {
    var fu = document.getElementById('<%= FuLicenseFile.ClientID %>');
    if (fu) {
        fu.addEventListener('change', function() {
            if (this.files && this.files[0]) {
                var reader = new FileReader();
                reader.onload = function(e) {
                    var txt = document.getElementById('<%= TxtLicenseString.ClientID %>');
                    if (txt) {
                        txt.value = (e.target.result || '').trim();
                    }
                };
                reader.readAsText(this.files[0]);
            }
        });
    }
})();
</script>
</body>
</html>

