<%@ Page Language="C#" AutoEventWireup="true" CodeFile="index.aspx.cs" Inherits="index" ResponseEncoding="utf-8" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>


        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <script>/* Apply saved theme BEFORE paint to prevent flash */
        (function(){var t=localStorage.getItem('idash_theme');if(t)document.documentElement.setAttribute('data-theme',t);})();
        </script>

        <head runat="server">
            <meta charset="utf-8" />
            <title>VA Asset Intelligence Hub</title>
            <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
            <meta http-equiv="Pragma" content="no-cache" />
            <meta http-equiv="Expires" content="0" />

            <style>
                /* ---------- AssetWorx Global Header ---------- */
                .aw-header-brand {
                    margin-top: 8px;
                    margin-bottom: 14px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    opacity: 0.95;
                }

                .aw-header-logo {
                    height: 26px;
                    width: auto;
                }

                .aw-header-text {
                    font-size: 14px;
                    font-weight: 600;
                    color: var(--accent);
                    letter-spacing: 0.4px;
                }

                .aw-header-text .bang {
                    color: var(--accent-2);
                }

                .aw-header-copy {
                    display: block;
                    font-size: 12px;
                    font-weight: 400;
                    color: var(--muted);
                    margin-top: 2px;
                }

                /* ---------- AssetWorx Global Footer ---------- */
                .aw-footer {
                    margin-top: 28px;
                    padding: 12px 16px;
                    border-top: 1px solid var(--line);
                    font-size: 20px;
                    color: var(--muted);
                    opacity: 0.9;
                }

                .aw-footer-inner {
                    max-width: 1400px;
                    margin: 0 auto;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    gap: 16px;
                }

                .aw-left,
                .aw-right {
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }

                .aw-logo {
                    height: 20px;
                    width: auto;
                }

                .aw-name {
                    font-weight: 600;
                    color: var(--accent);
                    letter-spacing: 0.4px;
                }

                .aw-name .bang {
                    color: var(--accent-2);
                }

                .copy {
                    white-space: nowrap;
                }

                .id-logo {
                    height: 16px;
                    width: auto;
                    opacity: 0.85;
                }


                /* ============================================================
   GLOBAL THEME (Matches dbupdate & autodbupdate)
   ============================================================ */

                :root {
                    --chip-br:  var(--line);
                }

                [data-theme="light"] {
                    --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
                }

                :root {
                    --shadow: 0 10px 15px -3px rgb(0 0 0 / 0.4);
                }


                body {
                    margin: 0;
                    background: var(--bg);
                    color: var(--text);
                    font-family: Segoe UI, Tahoma, Arial, sans-serif;
                }

                * {
                    box-sizing: border-box;
                }

                /* ============================================================
   PAGE LAYOUT
   ============================================================ */

                .page {
                    max-width: 1300px;
                    margin: 40px auto;
                    padding: 0 40px;
                }

                /* ============================================================
   HEADER
   ============================================================ */
                .aw-header-brand {
                    margin-top: 8px;
                    margin-bottom: 14px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    opacity: 0.95;
                }

                .aw-header-logo {
                    height: 26px;
                    width: auto;
                }

                .aw-header-text {
                    font-size: 14px;
                    font-weight: 600;
                    color: var(--accent);
                    letter-spacing: 0.4px;
                }

                .aw-header-text .bang {
                    color: var(--accent-2);
                }

                .aw-header-copy {
                    display: block;
                    font-size: 12px;
                    font-weight: 400;
                    color: var(--muted);
                    margin-top: 2px;
                }

                .header-title {
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 6px;
                }

                .header-sub {
                    font-size: 14px;
                    color: var(--muted);
                    margin-bottom: 32px;
                }

                /* ============================================================
   SECTION HEADINGS
   ============================================================ */

                .section-title {
                    margin-top: 36px;
                    margin-bottom: 14px;
                    font-size: 20px;
                    font-weight: 600;
                    color: var(--accent);
                }

                /* ============================================================
   DASHBOARD TILE GRID
   ============================================================ */

                .tile-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
                    gap: 24px;
                    margin-bottom: 12px;
                }

                /* ============================================================
   TILE STYLING
   ============================================================ */

                .card {
                    background: var(--card);
                    border: 1px solid var(--line);
                    border-radius: 12px;
                    padding: 24px;
                    box-shadow: var(--shadow);
                    transition: transform 0.2s, box-shadow 0.2s;
                }

                .tile {
                    background: var(--card);
                    border: 1px solid var(--line);
                    border-radius: 14px;
                    padding: 22px;
                    cursor: pointer;
                    transition: 0.15s ease;
                    box-shadow: var(--shadow);
                }

                .tile:hover {
                    transform: translateY(-4px);
                    box-shadow: 0 12px 28px rgba(0, 0, 0, .4);
                    border-color: var(--accent);
                }

                .tile-title {
                    font-size: 18px;
                    font-weight: 600;
                    margin-bottom: 6px;
                }

                .tile-desc {
                    font-size: 13px;
                    color: var(--muted);
                    line-height: 1.4em;
                }

                /* ============================================================
   FOOTER
   ============================================================ */

                .footer {
                    margin-top: 50px;
                    font-size: 12px;
                    color: var(--muted);
                    text-align: center;
                }

                .status-bar {
                    display: flex;
                    justify-content: space-between;
                    background: #1a243a;
                    padding: 8px 20px;
                    font-size: 13px;
                    border-bottom: 1px solid var(--line);
                }
                
                #connection-indicator {
                    font-size: 14px;
                    font-weight: 700;
                    color: #10b981;
                }

                .fav-star:hover {
                    color: #facc15 !important;
                    transform: scale(1.1);
                }

                .nav-tab {
                    color: var(--text);
                    text-decoration: none;
                    padding: 8px 16px;
                    background: var(--card);
                    border: 1px solid var(--line);
                    border-radius: 30px;
                    font-size: 13px;
                    font-weight: 600;
                    transition: 0.2s;
                }

                .nav-tab:hover {
                    background: var(--accent) !important;
                    color: #fff !important;
                    border-color: var(--accent) !important;
                }
                /* ---------- Support Request Modal ---------- */
                .sr-overlay {
                    display:none;
                    position:fixed;
                    inset:0;
                    background:rgba(0,0,0,0.72);
                    z-index:9000;
                    align-items:center;
                    justify-content:center;
                }
                .sr-overlay.active { display:flex; }
                .sr-modal {
                    background:var(--card);
                    border:1px solid var(--line);
                    border-radius:16px;
                    padding:32px 36px;
                    width:540px;
                    max-width:94vw;
                    max-height:90vh;
                    overflow-y:auto;
                    box-shadow:0 24px 64px rgba(0,0,0,0.5);
                    position:relative;
                }
                .sr-modal h2 {
                    margin:0 0 6px;
                    font-size:20px;
                    color:var(--accent);
                }
                .sr-modal .sr-sub {
                    color:var(--muted);
                    font-size:13px;
                    margin-bottom:22px;
                    line-height:1.5;
                }
                .sr-field { margin-bottom:16px; }
                .sr-label {
                    display:block;
                    font-size:12px;
                    font-weight:700;
                    text-transform:uppercase;
                    letter-spacing:.05em;
                    color:var(--muted);
                    margin-bottom:6px;
                }
                .sr-input {
                    width:100%;
                    box-sizing:border-box;
                    padding:10px 13px;
                    border-radius:9px;
                    border:1px solid var(--line);
                    background:var(--bg);
                    color:var(--text);
                    font-size:14px;
                    font-family:inherit;
                    outline:none;
                    transition:border-color .15s;
                }
                .sr-input:focus { border-color:var(--accent); }
                .sr-input.invalid { border-color:var(--danger) !important; }
                .sr-row { display:grid; grid-template-columns:1fr 1fr; gap:14px; }
                .sr-textarea { min-height:110px; resize:vertical; }
                .sr-subject-display {
                    padding:10px 13px;
                    border-radius:9px;
                    border:1px solid var(--line);
                    background:var(--chip);
                    color:var(--muted);
                    font-size:13px;
                }
                .sr-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:22px; }
                .sr-send {
                    padding:10px 26px;
                    background:var(--accent);
                    color:#fff;
                    border:none;
                    border-radius:10px;
                    font-weight:700;
                    font-size:14px;
                    cursor:pointer;
                    transition:filter .15s;
                }
                .sr-send:hover { filter:brightness(1.12); }
                .sr-cancel {
                    padding:10px 20px;
                    background:transparent;
                    color:var(--muted);
                    border:1px solid var(--line);
                    border-radius:10px;
                    font-size:14px;
                    cursor:pointer;
                }
                .sr-cancel:hover { border-color:var(--accent); color:var(--accent); }
                .sr-msg-ok  { background:color-mix(in srgb,#10b981 15%,transparent); border:1px solid #10b981; color:#10b981; padding:10px 14px; border-radius:8px; margin-bottom:14px; font-size:14px; }
                .sr-msg-err { background:color-mix(in srgb,var(--danger) 15%,transparent); border:1px solid var(--danger); color:var(--danger); padding:10px 14px; border-radius:8px; margin-bottom:14px; font-size:14px; }
                .sr-pill {
                    display:inline-flex;
                    align-items:center;
                    gap:5px;
                    padding:4px 13px;
                    border-radius:20px;
                    border:1px solid var(--accent);
                    background:color-mix(in srgb,var(--accent) 12%,transparent);
                    color:var(--accent);
                    font-size:12px;
                    font-weight:700;
                    cursor:pointer;
                    text-decoration:none;
                    transition:background .15s, color .15s;
                }
                .sr-pill:hover {
                    background:var(--accent);
                    color:#fff;
                }
            </style>

        </head>

        <body>

            <form id="form1" runat="server">
                <div class="status-bar">
                    <span>VA Asset Intelligence Hub &mdash; SERVER: <%= System.Environment.MachineName %> (<%= Request.ServerVariables["LOCAL_ADDR"] %>)</span>
                    <span id="connection-indicator">&bull; CONNECTED</span>
                </div>
                <% if (IsLoggedIn) { %>
                <div style="display:flex; justify-content:space-between; align-items:center; background:var(--card); padding:8px 20px; font-size:13px; border-bottom:1px solid var(--line);">
                    <span style="color:var(--accent-2);">&#128100; Signed in as <strong style="color:var(--text);"><%= Server.HtmlEncode(Convert.ToString(Session["IdashUsername"])) %></strong></span>
                    <span style="display:flex; align-items:center; gap:14px;">
                        <a href="#" class="sr-pill" onclick="openSupportModal(); return false;"><img src="/iDash/Assets/branding/rfid.png" style="height:13px;width:auto;vertical-align:middle;margin-right:4px;" alt="RFID" />Support Request</a>
                        <button type="button" id="themeToggleBtn" onclick="toggleIdashTheme()" title="Toggle Light/Dark Mode" style="background:none; border:1px solid var(--line); border-radius:8px; padding:4px 10px; cursor:pointer; font-size:14px; color:var(--text); transition:all 0.2s; display:inline-flex; align-items:center; gap:5px;"><span id="themeIcon">&#127769;</span><span id="themeLabel" style="font-size:12px; font-weight:600;">Dark</span></button>
                        <asp:LinkButton ID="BtnUserLogout" runat="server" OnClick="BtnLogout_Click" style="color:var(--muted); font-size:12px; text-decoration:underline;">Sign Out</asp:LinkButton>
                    </span>
                </div>
                <% } %>
                <div class="page">
                    <% if (!IsLoggedIn) { %>
                    <!-- LOGIN-REQUIRED GATE -->
                    <div style="max-width:420px; margin:80px auto; text-align:center;">
                        <div class="header-title" style="font-size:28px;">VA Asset Intelligence Hub</div>
                        <div class="aw-header-brand" style="justify-content:center; margin-bottom:30px;">
                            <img src="<%= ResolveUrl("~/Assets/branding/assetworx.jpg") %>" class="aw-header-logo" />
                            <span class="aw-header-text">AssetWorx<span class="bang">!</span></span>
                        </div>
                        <div style="background:var(--card); border:1px solid var(--line); border-radius:12px; padding:28px;">
                            <div style="font-size:16px; font-weight:700; color:var(--text); margin-bottom:6px;">&#128274; Sign In Required</div>
                            <div style="font-size:13px; color:var(--muted); margin-bottom:20px;">Enter your iDash credentials to access the portal.</div>
                            <asp:TextBox ID="TxtUserGate" runat="server" Placeholder="Username" style="width:100%; box-sizing:border-box; background:var(--chip); color:var(--text); border:1px solid var(--line); padding:10px 12px; border-radius:6px; margin-bottom:10px; font-size:14px;" />
                            <asp:TextBox ID="TxtPassGate" runat="server" TextMode="Password" Placeholder="Password" style="width:100%; box-sizing:border-box; background:var(--chip); color:var(--text); border:1px solid var(--line); padding:10px 12px; border-radius:6px; margin-bottom:14px; font-size:14px;" />
                            <div style="margin-bottom:14px; text-align:left; font-size:12px; color:var(--muted); line-height:1.45; background:var(--bg); border:1px solid var(--line); border-radius:8px; padding:10px 12px;">
                                <label style="display:flex; align-items:flex-start; gap:8px; cursor:pointer; color:var(--text);">
                                    <asp:CheckBox ID="ChkAgreementGate" runat="server" style="margin-top:2px;" />
                                    <span>I agree to the <a href="documentation/va_software_agreement.html" target="_blank" style="color:var(--accent); font-weight:600; text-decoration:underline;">Software Usage &amp; Non-Duplication Agreement</a> (<a href="javascript:void(0)" onclick="openAgreementModal(); return false;" style="color:var(--accent); text-decoration:underline;">preview</a>).</span>
                                </label>
                            </div>
                            <asp:Button ID="BtnLoginGate" runat="server" Text="Sign In" OnClick="BtnLoginGate_Click" style="width:100%; background:var(--accent); color:var(--bg); border:none; padding:11px; border-radius:6px; font-weight:700; font-size:14px; cursor:pointer; letter-spacing:0.3px;" />
                            <asp:Label ID="LblLoginGateError" runat="server" ForeColor="#ef4444" style="display:block; margin-top:10px; font-size:13px;"></asp:Label>
                        </div>
                        <div style="font-size:11px; color:var(--muted); margin-top:16px;">Contact your administrator if you need an account.</div>
                    </div>
                    <% } else { %>

                    <!-- ======================================================
         HEADER
         ====================================================== -->
                    <div class="header-title">VA Asset Intelligence Hub</div>
                    <div class="header-sub">View reports, search for assets, download files, and manage RFID inventory &mdash; everything your team needs, in one place.</div>
                    <div class="aw-header-brand">
                        <img src="<%= ResolveUrl("~/Assets/branding/assetworx.jpg") %>" class="aw-header-logo" />
                        <span class="aw-header-text">
                            AssetWorx<span class="bang">!</span>
                            <span class="aw-header-copy">by InfinID Technologies</span>
                        </span>
                    </div>

                    <!-- TAB BAR -->
                    <div style="display:flex; flex-wrap:wrap; gap:10px; margin-top:25px; margin-bottom:10px; border-bottom:1px solid var(--line); padding-bottom:15px;" id="nav-tabs">
                        <a href="#favoritesSection" class="nav-tab">&#11088; Favorites</a>
                        
                        <% if (CanSeeSection("downloads","docs")) { %><a href="#sec-docs" class="nav-tab">&#128218; Guides &amp; Downloads</a><% } %>
                        <% if (CanSeeSection("scan_", "print_", "excel_print")) { %><a href="#sec-scanning" class="nav-tab">&#128241; Scanning &amp; Tools</a><% } %>
                        <% if (CanSeeSection("rpt_")) { %><a href="#sec-reports" class="nav-tab">&#128202; Reports</a><% } %>
                        <% if (!IsLoggedIn) { %>
                        <a href="#sec-admin" class="nav-tab" style="border-color:#10b981; color:#10b981;" onclick="setTimeout(function(){ var e=document.getElementById('TxtUser'); if(e) e.focus(); }, 400);">&#128100; Sign In</a>
                        <% } %>
                        <% if (IsLoggedIn && Convert.ToString(Session["IdashUserRole"]) == "admin") { %>
                        <a href="#sec-admin" class="nav-tab" style="border-color:#ef4444; color:#ef4444;">&#128274; Admin Tools</a>
                        <% } %>
                    </div>
                    <div style="font-size:12px; color:var(--muted); margin-bottom:18px; padding-left:2px;">
                        &#11088; <strong>Tip:</strong> Click the <strong style="color:#facc15;">&#9733;</strong> star on any tile to save it to your Favorites for quick access.
                    </div>



                    <!-- ======================================================
         WELCOME CARD (first-time users only)
         ====================================================== -->
                    <div id="welcomeCard" style="display:none; background:linear-gradient(135deg,var(--card),var(--chip)); border:1px solid #2ea8ff44; border-left:4px solid #2ea8ff; border-radius:12px; padding:20px 24px; margin-bottom:28px; position:relative;">
                        <div style="font-size:18px; font-weight:700; color:var(--text); margin-bottom:8px;">&#128075; Welcome to the VA Asset Intelligence Hub</div>
                        <div style="font-size:13px; color:var(--muted); line-height:1.7; margin-bottom:14px;">
                            This site helps you track, search, and report on RFID-tagged VA equipment.<br>
                            &bull; <strong style="color:var(--text);">Search Assets</strong> &mdash; find any asset or see where it was last scanned<br>
                            &bull; <strong style="color:var(--text);">Reports</strong> &mdash; view inventory progress, tagging activity, and export data<br>
                            &bull; <strong style="color:var(--text);">Guides &amp; Downloads</strong> &mdash; step-by-step procedures and approved software<br>
                            &bull; <strong style="color:#facc15;">&#9733; Favorites</strong> &mdash; click the star on any tile to pin it for fast access<br>
                            &bull; The <strong style="color:#ef4444;">&#128274; Admin Tools</strong> section requires a login &mdash; most users will not need it.
                        </div>
                        <button onclick="dismissWelcome()" style="background:#2ea8ff; color:var(--bg); border:none; padding:8px 20px; border-radius:6px; font-weight:700; cursor:pointer; font-size:13px;">Got it &mdash; don&rsquo;t show this again</button>
                    </div>
                    <!-- ======================================================
         FAVORITES
         ====================================================== -->
                    <div id="favoritesSection" style="display:none;">
                        <div class="section-title" style="color: #facc15;">&#11088; Favorites</div>
                        <div class="tile-grid" id="favoritesGrid"></div>
                    </div>


                    <!-- ======================================================
         DOCUMENTATION & PROCEDURES
         ====================================================== -->
                    <% if (CanSeeSection("downloads","docs")) { %>
                    <div class="section-title" id="sec-docs">&#128218; Guides &amp; Downloads
                        <span style="display:block; font-size:13px; font-weight:400; color:var(--muted); margin-top:4px;">Step-by-step procedures, reference documents, approved software downloads, and file uploads.</span>
                    </div>

                    <div class="tile-grid">
                    
                        <!-- Secure Downloads Hub -->
                        <% if (CanSeeTile("downloads")) { %>
                        <div class="tile" onclick="location.href='va_downloads.aspx'" style="border-left: 4px solid #f59e0b; background: rgba(245, 158, 11, 0.05);">
                            <div class="tile-title" style="color: #f59e0b;">&#128230; Downloads &amp; Uploads</div>
                            <div class="tile-desc" style="color:var(--text);">
                                Download approved software, printer templates, drivers, and licenses. Customers and employees can also upload files directly to the iDash team.
                            </div>
                        </div><% } %>

                        <!-- Main App Documentation Hub locked behind admin panel -->
                        

                        <!-- Real App Documentation (visible when logged in) -->
                        
                            <% if (CanSeeTile("docs")) { %>
                            <div class="tile" onclick="location.href='documentation/index.aspx'" style="border-left: 4px solid #2ea8ff; background: color-mix(in srgb, var(--accent), transparent 95%);">
                                <div class="tile-title" style="color:#2ea8ff;">&#128214; iDash App Documentation</div>
                                <div class="tile-desc">
                                    Central registry and technical reference for all iDash modules, pages, APIs, scan filters, procedures, and architecture rationale.
                                </div>
                            </div><% } %>
                            <% if (CanSeeTile("docs_arch")) { %>
                            <div class="tile" onclick="location.href='documentation/idash_architecture_rationale.html'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, var(--accent-2), transparent 92%);">
                                <div class="tile-title" style="color:#10b981;">&#128336; Architecture &amp; Rationale</div>
                                <div class="tile-desc">
                                    Design decisions, module relationships, session state patterns, and security model documentation.
                                </div>
                            </div><% } %>



                        <!-- IDI Mobile Connectivity Cookbook -->
                        <% if (CanSeeTile("docs_cookbook")) { %>
                        <div class="tile" onclick="location.href='documentation/idi_mobile_connectivity_cookbook.html'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, #10b981, transparent 94%);">
                            <div class="tile-title" style="color:#10b981;">&#128241; IDI Mobile Connectivity Cookbook</div>
                            <div class="tile-desc">
                                Field guide for VA OIT &amp; deployment teams &mdash; WiFi onboarding, scanner setup, firewall rules, printer configuration, and end-to-end troubleshooting for AssetWorx! by InfinID Technologies.
                            </div>
                        </div>
                        <% } %>

                    </div>

                    <% } /* end guides */ %>

                    <!-- ======================================================
         REPORTS
         ====================================================== -->
                    <% if (CanSeeSection("rpt_")) { %>
                    <div class="section-title" id="sec-reports">&#128202; Reports
                        <span style="display:block; font-size:13px; font-weight:400; color:var(--muted); margin-top:4px;">Browse dashboards and download inventory data for your site.</span>
                    </div>

                    <div class="tile-grid">

                        <% if (CanSeeTile("rpt_notifications")) { %><div class="tile" id="tileNotifications" onclick="location.href='va_notifications.aspx'" style="border-left: 4px solid #3b82f6; background: color-mix(in srgb, #3b82f6, transparent 94%);">
                            <div class="tile-title" style="color:#3b82f6; display:flex; align-items:center; justify-content:space-between;">
                                <span>🔔 iDash Notifications</span>
                                <span id="tileWatchBadge" style="font-size:11px; padding:2px 8px; border-radius:12px; background:color-mix(in srgb, #3b82f6 20%, transparent); color:#3b82f6; font-weight:700; display:none;">0 Watched</span>
                            </div>
                            <div class="tile-desc">
                                Asset watch list &amp; background reader detection monitor. Track high-priority assets, see detection levels &amp; location mismatches, export to Excel, and inspect in Asset Master.
                            </div>
                        </div><% } %>

                        <%-- REMOVED: rpt_overview — accessible via Asset Master Stats pill link (08/02) --%>

                        <% if (CanSeeTile("rpt_asset_master")) { %><div class="tile" onclick="location.href='va_asset_master.aspx'" style="border-left: 4px solid var(--accent-2); background: color-mix(in srgb, var(--accent-2), transparent 95%);">
                            <div class="tile-title" style="color:var(--accent-2);">&#128203; Asset Master &mdash; Unified Portal</div>
                            <div class="tile-desc">
                                One-stop asset reporting with server-side pagination, 7+ search filters, toggleable columns, KPI dashboard, CSV/Excel export, per-row print, and <strong>Asset Detail Panel</strong> (slide-out with inline editing, location history, checkout history, maintenance history, and children). <em>Consolidates: Data Research, Location List, CMR Stats, Asset History, and Asset Explorer.</em>
                            </div>
                        </div><% } %>

                        <% if (CanSeeTile("rpt_tagging")) { %><div class="tile" onclick="location.href='va_tag_stats.aspx'" style="border-left: 4px solid #8b5cf6; background: rgba(139,92,246,0.05);">
                            <div class="tile-title" style="color:#8b5cf6;">&#127991; Tagging Dashboards &amp; Activity</div>
                            <div class="tile-desc">
                                Comprehensive tagging portal. See progress by site and employee, detailed activity logs, tag type breakdowns, and full audit trails. <br><em style="color:var(--muted); font-size:11px; margin-top:6px; display:block;">Consolidates: Tag Statistics, Tag Audit Report, Tagging Activity, and IDI Tagging.</em>
                            </div>
                        </div><% } %>


                        <%-- REMOVED: rpt_activity — consolidated into Tagging Dashboards & Activity (08/17) --%>


                        <% if (CanSeeTile("rpt_ennx") || CanSeeTile("rpt_sessions")) { %><div class="tile" onclick="location.href='va_ennx.aspx'">
                            <div class="tile-title">&#128228; ENNX Export &amp; History</div>
                            <div class="tile-desc">
                                Generate ENNX inventory export files for submission, or review and download past scan sessions by user and date.
                            </div>
                        </div><% } %>

                        <% if (CanSeeTile("rpt_automation")) { %><div class="tile" onclick="location.href='va_site_config.aspx#sec-reports'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, var(--accent-2), transparent 92%);">
                            <div class="tile-title" style="color:#10b981;">&#128197; Report Automation</div>
                            <div class="tile-desc">Configure automated daily ENNX &amp; Excel reports, manage email recipients, and download the Task Scheduler script.</div>
                        </div><% } %>


                        <% if (CanSeeTile("rpt_fixed_reader")) { %><div class="tile" onclick="location.href='va_fixed_reader.aspx'" style="border-left: 4px solid #06B6D4; background: color-mix(in srgb, #06B6D4, transparent 94%);">
                            <div class="tile-title" style="color:#06B6D4;">&#128225; Fixed Readers</div>
                            <div class="tile-desc">
                                Monitor RFID readers (online/offline, tag observations, reads by device) and configure readers &mdash; add, edit, delete, assign antennas &amp; locations, discover unregistered readers.
                            </div>
                        </div><% } %>

                        <% if (CanSeeTile("rpt_fixed_reader")) { %><div class="tile" onclick="location.href='va_fixed_reader_live.aspx'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, #10b981, transparent 94%);">
                            <div class="tile-title" style="color:#10b981; display:flex; align-items:center; justify-content:space-between;">
                                <span>&#128225; Fixed Reader Live Feed</span>
                                <span style="font-size:10px; font-weight:800; background:color-mix(in srgb, #10b981 20%, transparent); color:#10b981; border:1px solid #10b981; border-radius:12px; padding:2px 8px;">LIVE</span>
                            </div>
                            <div class="tile-desc">
                                Real-time antenna-level tag read stream. Watch assets passing in front of specific fixed reader antennas as it happens with live counter, sound alerts, and asset watch list.
                            </div>
                        </div><% } %>

                        <%-- REMOVED: rpt_data_research — consolidated into Asset Master (07/31) --%>

                        <%-- REMOVED: rpt_tag_audit — consolidated into Tagging Progress & Activity (08/17) --%>

                        <% if (CanSeeTile("rpt_data_quality")) { %><div class="tile" onclick="location.href='va_data_quality.aspx'" style="border-left: 4px solid #ef4444; background: color-mix(in srgb, #ef4444, transparent 95%);">
                            <div class="tile-title" style="color:#ef4444;">&#9989; Data Quality Command Center</div>
                            <div class="tile-desc">Live health score (0&ndash;100), missing EIL/CMR detection, unassigned locations, malformed EE numbers, interactive AJAX drill-down, and Excel export.</div>
                        </div><% } %>

                        <%-- REMOVED: rpt_cmr — consolidated into Asset Master CMR filter + KPI (07/31) --%>

                        <%-- REMOVED: rpt_tag_stats — consolidated into Tagging Progress & Activity (08/17) --%>

                        <%-- REMOVED: rpt_tagging_detail — consolidated into Tagging Dashboards & Activity (08/17) --%>

                        <%-- REMOVED: rpt_location_list — consolidated into Asset Master location column + detail panel (07/31) --%>

                        <%-- REMOVED: search_history, search_asset, search_location — all consolidated into Asset Master detail panel (07/31) --%>

                    </div>

                    <% } /* end reports */ %>

                    <!-- ======================================================
         SCANNING & TOOLS
         ====================================================== -->
                    <% if (CanSeeSection("scan_", "print_", "excel_print")) { %>
                    <div class="section-title" id="sec-scanning">&#128241; Scanning &amp; Tools
                        <span style="display:block; font-size:13px; font-weight:400; color:var(--muted); margin-top:4px;">Live scanning dashboards, inventory tools, and print mapping.</span>
                    </div>
                    <div class="tile-grid">

                            <% if (CanSeeTile("scan_maps")) { %><div class="tile" onclick="location.href='va_site_maps.aspx'" style="border-left: 4px solid #3b82f6; background: rgba(59, 130, 246, 0.05);">
                                <div class="tile-title" style="color:#3b82f6;">&#x1f5fa;&#xfe0f; Site Maps &amp; Tagging</div>
                                <div class="tile-desc">Interactive tagging command center. Select a site, view floor plans, track tagged vs remaining assets with green/red indicators, import ENNX reports, and export Excel reports.</div>
                            </div><% } %>

                            <% if (CanSeeTile("scan_tagteam")) { %><div class="tile" onclick="location.href='va_tagteam_scan.aspx'">
                                <div class="tile-title">Tag Team Scan</div>
                                <div class="tile-desc">Team scanning dashboard with ENNX integration and custom template printing.</div>
                            </div><% } %>

                            <% if (CanSeeTile("scan_inventory")) { %><div class="tile" onclick="location.href='va_inventory.aspx'" style="border-left: 4px solid var(--accent-2);">
                                <div class="tile-title" style="color:var(--accent-2);">VA Site Inventory</div>
                                <div class="tile-desc">Rapid location sweep interface. Pre-loads room assets, verifies found items, tracks misplaced assets in memory, and allows optional database commit.</div>
                            </div><% } %>

                            <% if (CanSeeTile("scan_locator")) { %><div class="tile" onclick="location.href='va_rfid_locator.aspx'" style="border-left: 4px solid #8B5CF6; background:rgba(139,92,246,0.05);">
                                <div class="tile-title" style="color:#8B5CF6;">&#128225; RFID Asset Locator</div>
                                <div class="tile-desc">Locate specific missing assets using RFID proximity scanning. Geiger counter-style proximity meter, audio feedback, and DataWedge/WebSerial USB support.</div>
                            </div><% } %>

                            <% if (CanSeeTile("scan_ennx")) { %><div class="tile" data-href="va_ennx_live_scan.aspx" onclick="location.href='va_ennx_live_scan.aspx?v=<%= DateTime.Now.Ticks %>'">
                                <div class="tile-title">ENNX Live Scan</div>
                                <div class="tile-desc">Live asset scanning tool. Requires site selection and database connection.</div>
                            </div><% } %>

                            <% if (CanSeeTile("scan_universal_ennx")) { %><div class="tile" onclick="location.href='va_universal_ennx.aspx'" style="border-left:4px solid #10b981; background:color-mix(in srgb, var(--accent-2), transparent 92%);">
                                <div class="tile-title" style="color:#10b981;">&#128228; Universal ENNX Creator</div>
                                <div class="tile-desc">Build and download an ENNX file from any scanner &mdash; barcode, RFID, or both. No site selection or database required.</div>
                            </div><% } %>

                            <% if (CanSeeTile("scan_eil")) { %><div class="tile" data-href="va_eil_live_scan.aspx" onclick="location.href='va_eil_live_scan.aspx?v=<%= DateTime.Now.Ticks %>'">
                                <div class="tile-title">EIL Live Scan &amp; Reconciliation</div>
                                <div class="tile-desc">Load EIL parts list and reconcile. Live scanning for TC53/RFD40.</div>
                            </div><% } %>


                            <!-- Excel Equipment Import & Print -->
                            <% if (CanSeeTile("excel_print")) { %><div class="tile" onclick="location.href='va_excel_print.aspx'" style="border-left:4px solid #10b981; background:rgba(16,185,129,0.05);">
                                <div class="tile-title" style="color:#10b981;">&#128218; Excel Equipment Import &amp; Print</div>
                                <div class="tile-desc">Load <code>equipment.xlsx</code> from <code>C:\va_rfid\excel_data\</code>, preview all rows, select assets, and <strong>import into AssetWorx</strong> and/or <strong>print labels immediately</strong> via MQTT/BarTender &mdash; no need to be in AssetWorx first.</div>
                            </div><% } %>
                            <!-- Print Setup Wizard -->
                            <% if (CanSeeTile("excel_print") || CanSeeTile("print_mapping") || CanSeeTile("admin_site_config") || CanSeeTile("admin_printer_routing")) { %>
                            <div class="tile" onclick="location.href='va_print_setup_wizard.aspx'" style="border-left:4px solid #f59e0b; background:rgba(245,158,11,0.05);">
                                <div class="tile-title" style="color:#f59e0b;">&#129668; Print Setup Wizard</div>
                                <div class="tile-desc">Diagnostic &amp; configuration wizard for BarTender, Zebra label printers, template validation, and test printing.</div>
                            </div><% } %>



                    </div>
                    <% } /* end scanning */ %>

                    <!-- ======================================================
         RESTRICTED ADMIN & DATABASE WRITE TOOLS
         ====================================================== -->
                    <div class="section-title" id="sec-admin" style="cursor:pointer; user-select:none;" onclick="toggleAdmin()">
                        &#128274; Admin &amp; Database Tools
                        <span id="adminToggleIcon" style="font-size:13px; font-weight:400; color:var(--muted); margin-left:10px;">&#9660; click to expand</span>
                        <span style="display:block; font-size:13px; font-weight:400; color:var(--muted); margin-top:4px;">Restricted &mdash; requires login. Most users will not need this section.</span>
                    </div>
                    <div id="adminSection" style="display:none;">

                    <asp:Panel ID="PnlLogin" runat="server" CssClass="tile-grid" DefaultButton="BtnLogin">
                        <div class="tile" style="border-left: 4px solid var(--danger); background: color-mix(in srgb, var(--danger), transparent 92%);">
                            <div class="tile-title" style="color:var(--danger);">&#128274; Authentication Required</div>
                            <div class="tile-desc" style="margin-bottom: 12px;">
                                Please log in with the AssetWorx SQL Administrator account to access tools that write database changes, including System Administration.
                            </div>
                            <asp:TextBox ID="TxtUser" runat="server" Placeholder="Username" style="width:100%; box-sizing:border-box; background:var(--bg); color:var(--text); border:1px solid var(--line); padding:8px; border-radius:4px; margin-bottom:8px;" />
                            <asp:TextBox ID="TxtPass" runat="server" TextMode="Password" Placeholder="Password" style="width:100%; box-sizing:border-box; background:var(--bg); color:var(--text); border:1px solid var(--line); padding:8px; border-radius:4px; margin-bottom:8px;" />
                            <asp:Button ID="BtnLogin" runat="server" Text="Log In" OnClick="BtnLogin_Click" style="background:#ef4444; color:white; border:none; padding:8px 16px; border-radius:4px; font-weight:600; cursor:pointer;" />
                            <asp:Label ID="LblLoginError" runat="server" ForeColor="#ef4444" style="display:block; margin-top:8px; font-size:13px;"></asp:Label>
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="PnlProtected" runat="server" Visible="false">
                        <div style="margin-bottom: 16px; text-align:right;">
                            <asp:LinkButton ID="BtnLogout" runat="server" OnClick="BtnLogout_Click" style="color: var(--muted); font-size: 13px; text-decoration: underline;">[Log out of Admin Tools]</asp:LinkButton>
                        </div>


                        <div style="font-weight:600; margin-bottom:10px; margin-top:20px; color:var(--muted); font-size:14px; text-transform:uppercase;">Admin Tools</div>
                        <div class="tile-grid">
                            <% if (CanSeeTile("admin_system_update")) { %>
                            <div class="tile" onclick="location.href='va_system_update.aspx'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, #10b981, transparent 95%);">
                                <div class="tile-title" style="color:#10b981;">&#128640; System Update &amp; Deploy (1-Click OTA)</div>
                                <div class="tile-desc">1-Click Over-The-Air code updater. Synchronize this server or remote laptops from Master Node (Tailscale) or GitHub with live progress, zero scripts, and safe boundary protection. <a href="documentation/va_system_migration_guide.html" style="color:#38bdf8; text-decoration:underline;" onclick="event.stopPropagation();">View Playbook &rarr;</a></div>
                            </div><% } %>
                            <% if (CanSeeTile("admin_training")) { %><div class="tile" onclick="location.href='va_training_hub.aspx'" style="border-left: 4px solid #8b5cf6; background: linear-gradient(135deg, rgba(139,92,246,0.08) 0%, rgba(59,130,246,0.05) 100%); grid-column: span 2;">
                                <div class="tile-title" style="color:#8b5cf6;">&#127891; AssetWorx Training &amp; Setup Hub</div>
                                <div class="tile-desc">One-stop guide to deploy, configure, and operate AssetWorx with iDash. Links to every tool and its documentation &mdash; setup wizards, RFID scanner user management, data imports, scanning workflows, reports, and administration. Start here if you're new.</div>
                            </div><% } %>


                            <!-- Cart Data & Sync Hub (Primary Unified Data Tool) -->
                            <% if (CanSeeTile("admin_sitedata") || CanSeeTile("admin_sql")) { %><div class="tile" onclick="location.href='va_sitedata_export.aspx'" style="border-left: 4px solid #2ea8ff; background: color-mix(in srgb, var(--accent), transparent 93%); grid-column: span 2;">
                                <div class="tile-title" style="color:#2ea8ff;">&#128257; Cart Data &amp; Sync Hub (All-in-One Ingest &amp; Export)</div>
                                <div class="tile-desc">The primary data management tool. Ingests <strong>Excel (.xlsx)</strong>, <strong>tab-delimited (.txt)</strong>, and <strong>CSV</strong> with intelligent Smart Merge, scan preservation, automated location creation, and multi-format cross-cart export. Replaces standalone import tools.</div>
                            </div><% } %>

                            <% if (CanSeeTile("admin_autodb")) { %><div class="tile" onclick="location.href='va_autodbupdate.aspx'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, #10b981, transparent 95%);">
                                <div class="tile-title" style="color:#10b981;">&#9654; Auto DB Update &amp; Watcher</div>
                                <div class="tile-desc">Folder watcher and scheduled database update processor. Monitors the autoload folder for incoming data files and runs automated SQL updates automatically.</div>
                            </div><% } %>

                            <% if (CanSeeTile("admin_autodb") || CanSeeTile("admin_site_config") || CanSeeTile("rpt_automation")) { %><div class="tile" onclick="location.href='va_automated_reports.aspx'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, #10b981, transparent 95%);">
                                <div class="tile-title" style="color:#10b981;">&#128227; System Automations &amp; Alerts</div>
                                <div class="tile-desc">Configure automated hardware failure triggers (SQL crash, missing autoload folder, print drops), global alert master switch, and daily report triggers.</div>
                            </div><% } %>

                            <% if (CanSeeTile("admin_field_sync")) { %><div class="tile" onclick="location.href='va_field_sync.aspx'" style="border-left: 4px solid #a855f7; background: rgba(168,85,247,0.05);">
                                <div class="tile-title" style="color:#a855f7;">&#128257; Field Server Sync (.BAK Restore)</div>
                                <div class="tile-desc">Restore a field server .bak to staging, then merge updated asset data into the central database for executive reporting. Supports nightly automation.</div>
                            </div><% } %>

                            <% if (CanSeeTile("admin_workbench") || CanSeeTile("admin_manualdb")) { %><div class="tile" onclick="location.href='va_dbupdate_workbench.aspx'" style="border-left: 4px solid #f59e0b; background: rgba(245,158,11,0.05);">
                                <div class="tile-title" style="color:#f59e0b;">&#128295; DB Update Workbench &amp; SQL Staging</div>
                                <div class="tile-desc">Advanced staging workbench. Test custom separators, preview SQL staging scripts with rollback, or apply manual database updates.</div>
                            </div><% } %>

                            <% if (CanSeeTile("admin_sql")) { %><div class="tile" onclick="location.href='va_sql_upload.aspx'">
                                <div class="tile-title">SQL Upload</div>
                                <div class="tile-desc">Upload and execute SQL scripts (with safety protection).</div>
                            </div><% } %>
                            <% if (CanSeeTile("admin_bcp")) { %><div class="tile" onclick="location.href='documentation/va_bcp_query.html'">
                                <div class="tile-title">VA On Network Queries (Pull)</div>
                                <div class="tile-desc">Interactive BCP extraction and SQLCMD batch generation utility â€” pulls CDW/VistA data into AssetWorx.</div>
                            </div><% } %>
                            <% if (CanSeeTile("admin_bcp")) { %><div class="tile" onclick="location.href='documentation/va_bcp_awpush_query.html'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, #10b981, transparent 94%);">
                                <div class="tile-title" style="color:#10b981;">&#128228; AW Push to VA SQL (Push)</div>
                                <div class="tile-desc">Reverse pipeline â€” generate BCP OUT and SQLCMD MERGE scripts to export AssetWorx data to a remote VA SQL server.</div>
                            </div><% } %>
                            <% if (CanSeeTile("admin_excel")) { %><div class="tile" onclick="location.href='va_excel.aspx'">
                                <div class="tile-title">Excel Merge Tool</div>
                                <div class="tile-desc">Merge equipment files with site master sheets.</div>
                            </div><% } %>

                            <!-- System Logs -->
                            <% if (CanSeeTile("admin_logs")) { %><div class="tile" onclick="location.href='va_autodbupdate.aspx?view=logs'" style="border-left: 4px solid #a78bfa; background: rgba(167,139,250,0.04);">
                                <div class="tile-title" style="color:#a78bfa;">&#128221; System Logs &amp; Automation History</div>
                                <div class="tile-desc">View the DB update log, Field Sync log, and links to the full IIS &amp; App log analyzer &mdash; all in one place.</div>
                            </div><% } %>
                            <!-- IIS & App Log Analyzer -->
                            <% if (CanSeeTile("admin_loganalyzer")) { %><div class="tile" onclick="location.href='va_log_viewer.aspx'" style="border-left: 4px solid #10b981; background: color-mix(in srgb, var(--accent-2), transparent 92%);">
                                <div class="tile-title" style="color:#10b981;">&#128270; IIS &amp; App Log Analyzer</div>
                                <div class="tile-desc">Advanced web server log analysis &mdash; filter by IP, URI, and status code. Auto-diagnoses common AssetWorx service errors from Serilog app logs. Includes login audit trail.</div>
                            </div><% } %>
                            <!-- Database Restore -->
                            <% if (CanSeeTile("admin_restore")) { %><div class="tile"
                                onclick="if(confirm('Warning: This is a dangerous administrative action.\nAre you sure you want to proceed to Database Restore?')) location.href='va_db_restore.aspx';"
                                style="border-left: 4px solid #ef4444;">
                                <div class="tile-title" style="color:#ef4444;">&#128293; Database Restore</div>
                                <div class="tile-desc">Restore the AssetWorx database from a backup file. &#9888; DANGER ZONE &mdash; this overwrites the live production database.</div>
                            </div><% } %>

                            <!-- VA FHIR Bridge -->
                            <% if (CanSeeTile("admin_fhir_bridge")) { %><div class="tile" onclick="location.href='va_fhir_bridge.aspx'" style="border-left: 4px solid #e87722; background: rgba(232,119,34,0.05);">
                                <div class="tile-title" style="color:#e87722;">&#127973; Supply Chain Bridge - AssetWorx to VistA</div>
                                <div class="tile-desc">Push supply chain data (assets &amp; locations) from AssetWorx to VA VistA via AEMS/MERS SQL sync. No patient data &mdash; supply chain inventory only.</div>
                            </div><% } %>
                            <!-- User Management (Consolidated) -->
                            <% if (CanSeeTile("admin_users")) { %><div class="tile" onclick="location.href='va_user_management.aspx'" style="border-left: 4px solid #a855f7; background: rgba(168,85,247,0.05);">
                                <div class="tile-title" style="color:#a855f7;">&#128100; User Management (Consolidated)</div>
                                <div class="tile-desc">One page for all user &amp; site administration. <strong>iDash Portal Users:</strong> roles, tile access, site permissions, login history. <strong>AssetWorx &amp; RFID Users:</strong> create/edit/delete scanner accounts (dbo.sysuser). <strong>Companies / Sites:</strong> add, rename, delete sites (dbo.company) with cascade cleanup.</div>
                            </div><% } %>
                            <!-- System Diagnostics -->
                            <% if (CanSeeTile("admin_diagnostics") || CanSeeTile("admin_users")) { %>
                            <div class="tile" onclick="location.href='va_system_diagnostics.aspx'" style="border-left:4px solid #f59e0b; background:rgba(245,158,11,0.05);">
                                <div class="tile-title" style="color:#f59e0b;">&#128202; System Diagnostics</div>
                                <div class="tile-desc">Run live health checks: API auth, license validation, server registrations, and batch update simulation. Send HTML report by email. MQTT &amp; reader tests coming soon.</div>
                            </div>
                            <% } %>
                            <!-- Print Setup Wizard -->
                            <% if (CanSeeTile("excel_print") || CanSeeTile("print_mapping") || CanSeeTile("admin_site_config") || CanSeeTile("admin_printer_routing") || CanSeeTile("admin_users")) { %>
                            <div class="tile" onclick="location.href='va_print_setup_wizard.aspx'" style="border-left:4px solid #f59e0b; background:rgba(245,158,11,0.05);">
                                <div class="tile-title" style="color:#f59e0b;">&#129668; Print Setup Wizard</div>
                                <div class="tile-desc">Diagnostic &amp; configuration wizard for BarTender, Zebra label printers, template validation, and test printing.</div>
                            </div>
                            <% } %>
                            <!-- License Manager (Consolidated: Live Readers + Standalone Cart Keys) -->
                            <% if (CanSeeTile("admin_license_manager") || CanSeeTile("admin_diagnostics") || CanSeeTile("admin_users") || CanSeeTile("admin_site_config")) { %>
                            <div class="tile" onclick="location.href='va_license_manager.aspx'" style="border-left:4px solid #ef4444; background:rgba(239,68,68,0.05);">
                                <div class="tile-title" style="color:#ef4444;">&#128273; iDash License and Setup</div>
                                <div class="tile-desc">Unified license management. View active reader &amp; handheld slots, delete stale scanners to free licenses, manage server registrations, and access mobile cart keys with 1-click apply scripts.</div>
                            </div>
                            <% } %>
                            <!-- System Configuration (DB, API, RabbitMQ, SMTP, Services, Mobile Columns) -->
                            <% if (CanSeeTile("admin_site_config") || CanSeeTile("admin_mqtt") || CanSeeTile("admin_printer_routing") || CanSeeTile("print_mapping")) { %>
                            <div class="tile" onclick="location.href='va_site_config.aspx'" style="border-left: 4px solid #8B5CF6; background: rgba(139,92,246,0.05);">
                                <div class="tile-title" style="color:#8B5CF6;">&#9881; System Configuration</div>
                                <div class="tile-desc">All system &amp; facility configuration &mdash; Database connections, API / OAuth credentials, RabbitMQ broker, Email / SMTP, Windows Services, and mobile scanning columns.</div>
                            </div>
                            <% } %>
                            <!-- Fixed Reader Configuration (Zebra FX9600 / FX7500 reader registrations) -->
                            <% if (CanSeeTile("admin_reader_config") || CanSeeTile("admin_site_config")) { %>
                            <div class="tile" onclick="location.href='va_reader_config.aspx'" style="border-left: 4px solid #06b6d4; background: rgba(6,182,212,0.05);">
                                <div class="tile-title" style="color:#06b6d4;">&#128225; Fixed Reader Configuration</div>
                                <div class="tile-desc">Manage fixed RFID reader registrations, antenna port mappings, power levels, network discovery, and live online/offline status.</div>
                            </div>
                            <% } %>
                            <!-- Tag Types — tagging team analysis page -->
                            <% if (CanSeeTile("admin_tag_type")) { %>
                            <div class="tile" onclick="location.href='va_tag_type.aspx'" style="border-left: 4px solid #10b981; background: rgba(16,185,129,0.05);">
                                <div class="tile-title" style="color:#10b981;">&#127991; Tag Type Analysis</div>
                                <div class="tile-desc">View tag type distribution across all sites, filter assets by type, and analyze type-to-template mappings. Tagging team analysis tool.</div>
                            </div>
                            <% } %>
                        </div>
                    </asp:Panel>
                    </div><!-- /adminSection -->

                </div>
                <idash:Footer runat="server" />

                <script>
                    // -- Theme toggle --
                    function toggleIdashTheme() {
                        var html = document.documentElement;
                        var current = html.getAttribute('data-theme');
                        if (current === 'light') {
                            html.removeAttribute('data-theme');
                            localStorage.removeItem('idash_theme');
                        } else {
                            html.setAttribute('data-theme', 'light');
                            localStorage.setItem('idash_theme', 'light');
                        }
                        updateThemeIcon();
                    }
                    function updateThemeIcon() {
                        var isLight = document.documentElement.getAttribute('data-theme') === 'light';
                        var iconEl = document.getElementById('themeIcon');
                        var labelEl = document.getElementById('themeLabel');
                        var btn = document.getElementById('themeToggleBtn');
                        if (iconEl) iconEl.innerHTML = isLight ? '&#9728;' : '&#127769;';
                        if (labelEl) labelEl.textContent = isLight ? 'Light' : 'Dark';
                        if (btn) btn.title = isLight ? 'Switch to Dark Mode' : 'Switch to Light Mode';
                    }
                    document.addEventListener('DOMContentLoaded', updateThemeIcon);

                    // -- Welcome card --
                    function dismissWelcome() {
                        localStorage.setItem('aw_welcomed', '1');
                        var card = document.getElementById('welcomeCard');
                        if (card) { card.style.transition = 'opacity 0.4s'; card.style.opacity = '0'; setTimeout(function(){ card.style.display='none'; }, 400); }
                    }

                    // -- Admin section toggle --
                    function toggleAdmin() {
                        var sec = document.getElementById('adminSection');
                        var ico = document.getElementById('adminToggleIcon');
                        if (!sec) return;
                        if (sec.style.display === 'none') {
                            sec.style.display = 'block';
                            if (ico) ico.textContent = '\u25B2 click to collapse';
                        } else {
                            sec.style.display = 'none';
                            if (ico) ico.textContent = '\u25BC click to expand';
                        }
                    }

                    document.addEventListener('DOMContentLoaded', function() {
                        // -- Welcome card --
                        if (!localStorage.getItem('aw_welcomed')) {
                            var card = document.getElementById('welcomeCard');
                            if (card) card.style.display = 'block';
                        }
                        
                        // 1. Ensure all tile grids have an ID for layout saving
                        var allGrids = document.querySelectorAll('.page .tile-grid');
                        allGrids.forEach(function(g, i) {
                            if (!g.id) g.id = 'tileGrid_' + i;
                        });

                        // 2. Pre-process all tiles to assign data-href based on their onclick handlers
                        var allTiles = document.querySelectorAll('.page .tile-grid .tile');
                        allTiles.forEach(function(tile) {
                            var currentDataHref = tile.getAttribute('data-href');
                            if (!currentDataHref) {
                                var onclickAttr = tile.getAttribute('onclick');
                                if (onclickAttr) {
                                    var match = onclickAttr.match(/'([^']+)'/);
                                    if (match) {
                                        var href = match[1];
                                        if (href.indexOf('?') > -1) href = href.split('?')[0];
                                        if (onclickAttr.indexOf('va_db_restore.aspx') > -1) href = 'va_db_restore.aspx';
                                        tile.setAttribute('data-href', href);
                                    }
                                }
                            } else if (currentDataHref.indexOf('?') > -1) {
                                tile.setAttribute('data-href', currentDataHref.split('?')[0]);
                            }
                        });

                        // 3. Setup Favorites system elements (Stars)
                        var favs = JSON.parse(localStorage.getItem('aw_idash_favorites') || '[]');
                        var allOriginalTiles = document.querySelectorAll('.page .tile-grid:not(#favoritesGrid) .tile');
                        
                        allOriginalTiles.forEach(function(tile) {
                            var href = tile.getAttribute('data-href');
                            if (!href) return;
                            
                            var titleDiv = tile.querySelector('.tile-title');
                            if (titleDiv && !titleDiv.querySelector('.fav-star')) {
                                var star = document.createElement('span');
                                star.className = 'fav-star';
                                star.innerHTML = '&#9733;';
                                star.style.cssText = 'float:right; font-size:18px; color:var(--line); cursor:pointer; transition: 0.2s all;';
                                star.title = "Toggle Favorite";
                                
                                star.addEventListener('click', function(e) {
                                    e.stopPropagation();
                                    toggleFav(href);
                                });
                                
                                titleDiv.appendChild(star);
                            }
                        });
                        
                        // ==========================================
                        // GLOBAL DRAG & DROP FOR MAIN DASHBOARD
                        // ==========================================
                        // Layout version guard -- bump this if tile structure changes to auto-clear stale layouts
                        var LAYOUT_VERSION = 'v3';
                        var savedVersion = localStorage.getItem('aw_idash_layout_ver');
                        if (savedVersion !== LAYOUT_VERSION) {
                            localStorage.removeItem('aw_idash_layout');
                            localStorage.setItem('aw_idash_layout_ver', LAYOUT_VERSION);
                        }

                        var savedLayout = JSON.parse(localStorage.getItem('aw_idash_layout') || 'null');
                        if (savedLayout) {
                            // Restore layout: only reorder tiles WITHIN their own grid -- never move cross-grid
                            allGrids.forEach(function(grid) {
                                if (grid.id === 'favoritesGrid') return;
                                var order = savedLayout[grid.id];
                                if (!order || !Array.isArray(order)) return;
                                // Build a map of tiles that actually belong to THIS grid
                                var ownTiles = {};
                                grid.querySelectorAll(':scope > .tile').forEach(function(t) {
                                    var h = t.getAttribute('data-href');
                                    if (h) {
                                        var cleanH = h.split('?')[0];
                                        ownTiles[h] = t;
                                        ownTiles[cleanH] = t;
                                    }
                                });
                                // Append in saved order, but ONLY for tiles that live in this grid
                                order.forEach(function(href) {
                                    var cleanHref = href.split('?')[0];
                                    if (ownTiles[cleanHref]) grid.appendChild(ownTiles[cleanHref]);
                                    else if (ownTiles[href]) grid.appendChild(ownTiles[href]);
                                });
                            });
                        }

                        function saveGlobalLayout() {
                            var layout = {};
                            document.querySelectorAll('.page .tile-grid:not(#favoritesGrid)').forEach(function(grid) {
                                var hrefs = [];
                                grid.querySelectorAll(':scope > .tile').forEach(function(c) {
                                    var h = c.getAttribute('data-href');
                                    if(h) hrefs.push(h.split('?')[0]);
                                });
                                layout[grid.id] = hrefs;
                            });
                            localStorage.setItem('aw_idash_layout', JSON.stringify(layout));
                        }

                        allOriginalTiles.forEach(function(tile) {
                            tile.setAttribute('draggable', 'true');
                            
                            tile.addEventListener('dragstart', function(e) {
                                e.stopPropagation();
                                e.dataTransfer.effectAllowed = 'move';
                                e.dataTransfer.setData('source-href', tile.getAttribute('data-href'));
                                setTimeout(function() { tile.style.opacity = '0.4'; }, 0);
                            });
                            
                            tile.addEventListener('dragend', function(e) {
                                tile.style.opacity = '1';
                                saveGlobalLayout();
                            });
                            
                            tile.addEventListener('dragover', function(e) {
                                e.preventDefault();
                                e.dataTransfer.dropEffect = 'move';
                                return false;
                            });
                            
                            tile.addEventListener('dragenter', function(e) {
                                // Only react if the dragged item is a main tile
                                if(e.dataTransfer.types.includes('source-href')) {
                                    e.stopPropagation();
                                    tile.style.transform = 'scale(0.96)';
                                    tile.style.boxShadow = '0 0 0 2px var(--accent) inset';
                                }
                            });
                            
                            tile.addEventListener('dragleave', function(e) {
                                e.stopPropagation();
                                tile.style.transform = '';
                                tile.style.boxShadow = '';
                            });
                            
                            tile.addEventListener('drop', function(e) {
                                e.stopPropagation();
                                e.preventDefault();
                                tile.style.transform = '';
                                tile.style.boxShadow = '';
                                
                                var draggedHref = e.dataTransfer.getData('source-href');
                                if (draggedHref && draggedHref !== tile.getAttribute('data-href')) {
                                    var draggedTile = document.querySelector('.page .tile-grid:not(#favoritesGrid) .tile[data-href="' + draggedHref + '"]');
                                    if (draggedTile && draggedTile !== tile) {
                                        tile.parentNode.insertBefore(draggedTile, tile);
                                        saveGlobalLayout();
                                    }
                                }
                            });
                        });

                        allGrids.forEach(function(grid) {
                            if (grid.id === 'favoritesGrid') return;
                            grid.addEventListener('dragover', function(e) {
                                e.preventDefault();
                                return false;
                            });
                            grid.addEventListener('drop', function(e) {
                                e.preventDefault();
                                var draggedHref = e.dataTransfer.getData('source-href');
                                if (draggedHref && e.target === grid) {
                                    var draggedTile = document.querySelector('.page .tile-grid:not(#favoritesGrid) .tile[data-href="' + draggedHref + '"]');
                                    if (draggedTile) {
                                        grid.appendChild(draggedTile);
                                        saveGlobalLayout();
                                    }
                                }
                            });
                        });
                        
                        
                        // ==========================================
                        // FAVORITES RENDER & LOGIC
                        // ==========================================
                        renderFavorites();
                        
                        function toggleFav(href) {
                            if (!href) return;
                            var cleanHref = href.split('?')[0];
                            var rawFavs = JSON.parse(localStorage.getItem('aw_idash_favorites') || '[]');
                            var currentFavs = [];
                            rawFavs.forEach(function(item) {
                                if (!item) return;
                                var c = item.split('?')[0];
                                if (currentFavs.indexOf(c) === -1) currentFavs.push(c);
                            });
                            var idx = currentFavs.indexOf(cleanHref);
                            if (idx > -1) {
                                currentFavs.splice(idx, 1);
                            } else {
                                currentFavs.push(cleanHref);
                            }
                            localStorage.setItem('aw_idash_favorites', JSON.stringify(currentFavs));
                            renderFavorites();
                        }
                        
                        function renderFavorites() {
                            var rawFavs = JSON.parse(localStorage.getItem('aw_idash_favorites') || '[]');
                            var currentFavs = [];
                            var needsResave = false;
                            rawFavs.forEach(function(item) {
                                if (!item) return;
                                var clean = item.split('?')[0];
                                if (currentFavs.indexOf(clean) === -1) {
                                    currentFavs.push(clean);
                                }
                                if (clean !== item) needsResave = true;
                            });
                            if (needsResave) {
                                localStorage.setItem('aw_idash_favorites', JSON.stringify(currentFavs));
                            }
                            
                            var favSection = document.getElementById('favoritesSection');
                            var favGrid = document.getElementById('favoritesGrid');
                            
                            favGrid.innerHTML = '';
                            
                            if (currentFavs.length > 0) {
                                favSection.style.display = 'block';
                            } else {
                                favSection.style.display = 'none';
                            }
                            
                            var originals = document.querySelectorAll('.page .tile-grid:not(#favoritesGrid) .tile');
                            
                            // 1. Reset all original tiles
                            originals.forEach(function(tile) {
                                var star = tile.querySelector('.fav-star');
                                if(star) star.style.color = 'var(--line)';
                                tile.style.display = '';
                            });

                            // 2. Render favorites exactly in the saved array order
                            currentFavs.forEach(function(href) {
                                var cleanHref = href.split('?')[0];
                                var original = Array.from(originals).find(function(t) { 
                                    var th = t.getAttribute('data-href');
                                    return th === cleanHref || (th && th.split('?')[0] === cleanHref); 
                                });
                                if (!original) return;

                                // Hide the original and mark its star
                                var star = original.querySelector('.fav-star');
                                if (star) star.style.color = '#facc15';
                                original.style.display = 'none';
                                
                                // Create draggable clone for the favorites section
                                var clone = original.cloneNode(true);
                                clone.style.display = '';
                                
                                // Favorites dragging logic isolated using "fav-href" payload
                                clone.setAttribute('draggable', 'true');
                                clone.addEventListener('dragstart', function(e) {
                                    e.stopPropagation();
                                    e.dataTransfer.effectAllowed = 'move';
                                    e.dataTransfer.setData('fav-href', cleanHref);
                                    setTimeout(function() { clone.style.opacity = '0.4'; }, 0);
                                });
                                clone.addEventListener('dragend', function(e) {
                                    clone.style.opacity = '1';
                                });
                                clone.addEventListener('dragover', function(e) {
                                    e.preventDefault();
                                    e.dataTransfer.dropEffect = 'move';
                                    return false;
                                });
                                clone.addEventListener('dragenter', function(e) {
                                    if(e.dataTransfer.types.includes('fav-href')) {
                                        clone.style.transform = 'scale(0.96)';
                                        clone.style.boxShadow = '0 0 0 2px #facc15 inset';
                                    }
                                });
                                clone.addEventListener('dragleave', function(e) {
                                    clone.style.transform = '';
                                    clone.style.boxShadow = '';
                                });
                                clone.addEventListener('drop', function(e) {
                                    e.stopPropagation();
                                    e.preventDefault();
                                    clone.style.transform = '';
                                    clone.style.boxShadow = '';
                                    
                                    var draggedHref = e.dataTransfer.getData('fav-href');
                                    if (draggedHref && draggedHref !== cleanHref) {
                                         // Reorder items in Local Storage
                                         var favList = JSON.parse(localStorage.getItem('aw_idash_favorites') || '[]');
                                         favList = favList.map(function(item) { return item ? item.split('?')[0] : ''; }).filter(Boolean);
                                         favList = favList.filter(function(item) { return item !== draggedHref; });
                                         var targetIdx = favList.indexOf(cleanHref);
                                         if (targetIdx !== -1) {
                                             favList.splice(targetIdx, 0, draggedHref);
                                         } else {
                                             favList.push(draggedHref);
                                         }
                                         localStorage.setItem('aw_idash_favorites', JSON.stringify(favList));
                                         renderFavorites();
                                    }
                                });

                                // Wire up the removal star on the clone
                                var cloneStar = clone.querySelector('.fav-star');
                                if (cloneStar) {
                                    cloneStar.addEventListener('click', function(e) {
                                        e.stopPropagation();
                                        toggleFav(cleanHref);
                                    });
                                }
                                favGrid.appendChild(clone);
                            });
                        }
                    });
                </script>
<% } /* end login gate */ %>
<!-- Manage Recipients UI relocated to Admin Tools -->

                <!-- ======================================================
                     SUPPORT REQUEST MODAL
                     ====================================================== -->
                <div id="srOverlay" class="sr-overlay" onclick="if(event.target===this)closeSupportModal()">
                    <div class="sr-modal" onclick="event.stopPropagation()">
                        <h2><img src="/iDash/Assets/branding/rfid.png" style="height:22px;width:auto;vertical-align:middle;margin-right:8px;" alt="RFID" />Support Request</h2>
                        <p class="sr-sub">
                            Your request will be sent to <strong>ID Integration Support</strong> at
                            <em>varfid_support@id-integration.com</em> and a copy will go to the email you provide.
                            All fields are required.
                        </p>

                        <div id="srResultMsg"></div>

                        <!-- Subject (read-only, auto-populated) -->
                        <div class="sr-field">
                            <span class="sr-label">Subject</span>
                            <div class="sr-subject-display" id="srSubjectDisplay">Support Request from <%= Server.HtmlEncode(GetSiteLabel()) %></div>
                        </div>

                        <!-- Name -->
                        <div class="sr-field">
                            <label class="sr-label" for="srName">Your Name <span style="color:var(--danger)">*</span></label>
                            <input type="text" id="srName" class="sr-input" placeholder="First and Last Name" />
                        </div>

                        <!-- Email + Phone row -->
                        <div class="sr-row">
                            <div class="sr-field">
                                <label class="sr-label" for="srEmail">Email Address <span style="color:var(--danger)">*</span></label>
                                <input type="email" id="srEmail" class="sr-input" placeholder="you@example.com" />
                            </div>
                            <div class="sr-field">
                                <label class="sr-label" for="srPhone">Phone Number <span style="color:var(--danger)">*</span></label>
                                <input type="text" id="srPhone" class="sr-input" placeholder="(555) 867-5309" />
                            </div>
                        </div>

                        <!-- Message -->
                        <div class="sr-field">
                            <label class="sr-label" for="srMessage">Describe the Issue <span style="color:var(--danger)">*</span></label>
                            <textarea id="srMessage" class="sr-input sr-textarea"
                                placeholder="Please describe the problem or question in as much detail as possible."></textarea>
                        </div>

                        <div class="sr-footer">
                            <button type="button" class="sr-cancel" onclick="closeSupportModal()">Cancel</button>
                            <button type="button" id="btnSrSend" class="sr-send" onclick="sendSupportRequest(this)">&#9993; Send Request</button>
                        </div>
                    </div>
                </div>

                <script>
                    /* â”€â”€ Support Request Modal (AJAX â€” no postback) â”€â”€ */
                    function openSupportModal() {
                        var ov = document.getElementById('srOverlay');
                        ov.classList.add('active');
                        // Reset validation highlights and hide any prior messages
                        ov.querySelectorAll('.sr-input').forEach(function(i){ i.classList.remove('invalid'); });
                        var msg = document.getElementById('srResultMsg');
                        if (msg) msg.innerHTML = '';
                        // Re-enable send button
                        var btn = document.getElementById('btnSrSend');
                        if (btn) { btn.disabled = false; btn.innerHTML = '\u2709 Send Request'; btn.style.opacity = '1'; }
                    }

                    function closeSupportModal() {
                        document.getElementById('srOverlay').classList.remove('active');
                    }

                    function sendSupportRequest(btn) {
                        var name    = document.getElementById('srName');
                        var email   = document.getElementById('srEmail');
                        var phone   = document.getElementById('srPhone');
                        var message = document.getElementById('srMessage');
                        var valid   = true;

                        [name, email, phone, message].forEach(function(f){
                            f.classList.remove('invalid');
                            if (!f.value.trim()) { f.classList.add('invalid'); valid = false; }
                        });
                        if (email.value.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim())) {
                            email.classList.add('invalid');
                            valid = false;
                        }
                        if (!valid) return;

                        // Loading state
                        btn.disabled = true;
                        btn.innerHTML = '\u23F3 Sending\u2026';
                        btn.style.opacity = '0.75';

                        var subject = document.getElementById('srSubjectDisplay').textContent;
                        var formData = new FormData();
                        formData.append('name',    name.value.trim());
                        formData.append('email',   email.value.trim());
                        formData.append('phone',   phone.value.trim());
                        formData.append('message', message.value.trim());
                        formData.append('subject', subject);

                        fetch('support_send.ashx', { method: 'POST', body: formData })
                            .then(function(r) { return r.json(); })
                            .then(function(data) {
                                var msgEl = document.getElementById('srResultMsg');
                                if (data.ok) {
                                    name.value = ''; email.value = ''; phone.value = ''; message.value = '';
                                    msgEl.innerHTML = '<div class="sr-msg-ok">\u2705 Your support request has been sent! ' +
                                        'A copy was sent to <strong>' + escHtml(email.value || formData.get('email')) + '</strong>.</div>';
                                    setTimeout(function(){ closeSupportModal(); }, 4000);
                                } else {
                                    msgEl.innerHTML = '<div class="sr-msg-err">\u26A0 ' + escHtml(data.error) + '</div>';
                                    btn.disabled = false;
                                    btn.innerHTML = '\u2709 Send Request';
                                    btn.style.opacity = '1';
                                }
                            })
                            .catch(function(err) {
                                var msgEl = document.getElementById('srResultMsg');
                                msgEl.innerHTML = '<div class="sr-msg-err">\u26A0 Network error: ' + escHtml(err.message) + '</div>';
                                btn.disabled = false;
                                btn.innerHTML = '\u2709 Send Request';
                                btn.style.opacity = '1';
                            });
                    }

                    function escHtml(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

                    // =========================================================
                    //  IDASH NOTIFICATIONS TILE BADGE (SILENT HUB BACKGROUND CHECK)
                    // =========================================================
                    (function() {
                        var saved = localStorage.getItem('idash-watch-list');
                        if (saved) {
                            var items = saved.split(/[\r\n,]+/).map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; });
                            if (items.length > 0) {
                                fetch('va_watchlist_api.ashx?action=check&t=' + Date.now(), {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/json' },
                                    body: JSON.stringify({ items: items })
                                })
                                .then(function(r) { return r.json(); })
                                .then(function(d) {
                                    if (d && d.summary) {
                                        var badge = document.getElementById('tileWatchBadge');
                                        if (badge && d.summary.totalWatched > 0) {
                                            var txt = d.summary.totalWatched + ' Watched';
                                            if (d.summary.high > 0) txt += ' • ' + d.summary.high + ' High';
                                            if (d.summary.mismatch > 0) txt += ' • ⚠️ ' + d.summary.mismatch;
                                            badge.textContent = txt;
                                            badge.style.display = 'inline-block';
                                        }
                                    }
                                })
                                .catch(function() {});
                            }
                        }
                    })();

                    // =========================================================
                    //  AGREEMENT MODAL HANDLERS
                    // =========================================================
                    function openAgreementModal() {
                        var m = document.getElementById('agreementModalOverlay');
                        if (m) m.style.display = 'flex';
                    }
                    function closeAgreementModal() {
                        var m = document.getElementById('agreementModalOverlay');
                        if (m) m.style.display = 'none';
                    }
                    function acceptAgreementFromModal() {
                        var chk = document.querySelector('input[id*="ChkAgreementGate"]');
                        if (chk) chk.checked = true;
                        closeAgreementModal();
                    }
                </script>

                <!-- ========================================================= -->
                <!-- SOFTWARE USAGE & NON-DUPLICATION AGREEMENT MODAL OVERLAY  -->
                <!-- ========================================================= -->
                <div id="agreementModalOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.75); backdrop-filter:blur(4px); z-index:99999; justify-content:center; align-items:center; padding:20px; box-sizing:border-box;">
                    <div style="background:var(--card, #131f3d); border:1px solid var(--line, #223668); border-radius:14px; width:100%; max-width:880px; max-height:90vh; display:flex; flex-direction:column; box-shadow:0 12px 36px rgba(0,0,0,0.5); overflow:hidden;">
                        <!-- Modal Header -->
                        <div style="padding:16px 22px; border-bottom:1px solid var(--line, #223668); display:flex; justify-content:space-between; align-items:center; background:color-mix(in srgb, var(--chip, #18274d) 60%, transparent);">
                            <div style="font-size:16px; font-weight:700; color:var(--text, #e2e8f0); display:flex; align-items:center; gap:8px;">
                                <span>&#128220;</span> Software Usage, Non-Duplication &amp; Proprietary Rights Agreement
                            </div>
                            <button type="button" onclick="closeAgreementModal()" style="background:transparent; border:none; color:var(--muted, #8aa0c5); font-size:20px; font-weight:bold; cursor:pointer; line-height:1;">&times;</button>
                        </div>
                        <!-- Modal Body (Iframe) -->
                        <div style="flex:1; overflow:hidden; position:relative; min-height:480px;">
                            <iframe src="documentation/va_software_agreement.html" style="width:100%; height:100%; border:none; background:transparent;"></iframe>
                        </div>
                        <!-- Modal Footer -->
                        <div style="padding:14px 22px; border-top:1px solid var(--line, #223668); display:flex; justify-content:space-between; align-items:center; background:color-mix(in srgb, var(--chip, #18274d) 40%, transparent); flex-wrap:wrap; gap:10px;">
                            <a href="documentation/va_software_agreement.html" target="_blank" style="font-size:12px; color:var(--accent, #2ea8ff); text-decoration:underline;">&#8599; Open Full Agreement in New Window</a>
                            <div style="display:flex; gap:10px;">
                                <button type="button" onclick="closeAgreementModal()" style="background:var(--chip, #18274d); color:var(--text, #e2e8f0); border:1px solid var(--line, #223668); padding:8px 16px; border-radius:6px; font-weight:600; font-size:13px; cursor:pointer;">Close</button>
                                <button type="button" onclick="acceptAgreementFromModal()" style="background:var(--accent, #2ea8ff); color:#fff; border:none; padding:8px 18px; border-radius:6px; font-weight:700; font-size:13px; cursor:pointer;">&#10003; I Agree &amp; Check Box</button>
                            </div>
                        </div>
                    </div>
                </div>

            </form>

        </body>

        </html>

