<%@ Page Language="C#" CodeFile="va_system_diagnostics.aspx.cs" Inherits="va_system_diagnostics" %>
<%
    bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
    if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }
    string role = Convert.ToString(Session["IdashUserRole"]);
    var tiles = Session["IdashTileAccess"] as System.Collections.Generic.List<string>;
    bool canSee = (role == "admin") || (tiles != null && (tiles.Contains("*") || tiles.Contains("admin_diagnostics") || tiles.Contains("admin_users")));
    if (!canSee) { Response.Redirect("index.aspx"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>iDash — System Diagnostics</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        :root { --pass:#10b981; --fail:#ef4444; --warn:#f59e0b; --placeholder:#4b5563; --api:#3b82f6; --db:#8b5cf6; }
        body { font-family:'Segoe UI',system-ui,sans-serif; background:var(--bg); color:var(--text); margin:0; padding:0; }
        .page-wrap { max-width:1200px; margin:0 auto; padding:24px 20px 60px; }
        /* Header */
        .diag-header { display:flex; align-items:center; gap:16px; margin-bottom:32px; }
        .diag-header h1 { font-size:26px; font-weight:700; margin:0; }
        .diag-header .meta { color:var(--muted,#888); font-size:13px; margin-top:4px; }
        .health-badge { margin-left:auto; padding:8px 20px; border-radius:24px; font-weight:700; font-size:15px; }
        .health-ok   { background:color-mix(in srgb,var(--pass) 15%,transparent); border:1px solid var(--pass); color:var(--pass); }
        .health-fail { background:color-mix(in srgb,var(--fail) 15%,transparent); border:1px solid var(--fail); color:var(--fail); }
        /* Cards */
        .card { background:var(--card,#1a1d2e); border:1px solid var(--line,#2a2d3e); border-radius:14px; padding:24px; margin-bottom:20px; }
        .card h2 { font-size:16px; font-weight:700; margin:0 0 18px; display:flex; align-items:center; gap:10px; }
        /* Config grid */
        .cfg-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:16px; align-items:end; }
        .cfg-field label { display:block; font-size:12px; color:var(--muted,#888); font-weight:600; text-transform:uppercase; letter-spacing:.04em; margin-bottom:6px; }
        .cfg-field select, .cfg-field input[type=number] {
            width:100%; padding:10px 14px; border:1px solid var(--line,#2a2d3e);
            border-radius:8px; background:color-mix(in srgb,var(--text,#fff) 5%,transparent);
            color:var(--text,#e0e0e0); font-size:14px; font-family:inherit; outline:none; box-sizing:border-box;
        }
        .cfg-field select:focus, .cfg-field input:focus { border-color:#3b82f6; box-shadow:0 0 0 3px rgba(59,130,246,.2); }
        /* Run button */
        .btn-run { padding:11px 32px; border-radius:10px; font-size:15px; font-weight:700; cursor:pointer; border:none;
            background:linear-gradient(135deg,#3b82f6,#8b5cf6); color:#fff;
            transition:all .2s; display:inline-flex; align-items:center; gap:8px; }
        .btn-run:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(59,130,246,.4); }
        .btn-run:active { transform:translateY(0); }
        /* Summary bar */
        .summary-bar { display:grid; grid-template-columns:repeat(4,1fr); gap:14px; margin-bottom:24px; }
        .summary-stat { background:var(--card,#1a1d2e); border:1px solid var(--line,#2a2d3e); border-radius:10px; padding:14px 16px; text-align:center; }
        .summary-stat .val { font-size:28px; font-weight:800; }
        .summary-stat .lbl { font-size:11px; color:var(--muted,#888); font-weight:600; text-transform:uppercase; margin-top:4px; }
        /* Test results grid */
        .test-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(340px,1fr)); gap:14px; }
        .test-card {
            border-radius:12px; padding:18px 20px; border:1px solid var(--line,#2a2d3e);
            background:var(--card,#1a1d2e); transition:all .3s; position:relative; overflow:hidden;
            animation: fadeUp .4s ease both;
        }
        @keyframes fadeUp { from { opacity:0; transform:translateY(16px); } to { opacity:1; transform:translateY(0); } }
        .test-card:nth-child(1){animation-delay:.05s} .test-card:nth-child(2){animation-delay:.1s}
        .test-card:nth-child(3){animation-delay:.15s} .test-card:nth-child(4){animation-delay:.2s}
        .test-card:nth-child(5){animation-delay:.25s} .test-card:nth-child(6){animation-delay:.3s}
        .test-card.pass { border-color:color-mix(in srgb,var(--pass) 40%,transparent); }
        .test-card.fail { border-color:color-mix(in srgb,var(--fail) 50%,transparent); }
        .test-card.placeholder { opacity:.5; border-style:dashed; }
        .test-card::before { content:''; position:absolute; top:0; left:0; right:0; height:3px; }
        .test-card.pass::before { background:var(--pass); }
        .test-card.fail::before { background:var(--fail); }
        .test-card.placeholder::before { background:var(--placeholder); }
        .tc-header { display:flex; align-items:center; gap:10px; margin-bottom:10px; }
        .tc-icon { font-size:22px; }
        .tc-title { font-weight:700; font-size:15px; flex:1; }
        .tc-status { font-size:11px; font-weight:800; padding:3px 10px; border-radius:20px; letter-spacing:.04em; }
        .st-pass { background:color-mix(in srgb,var(--pass) 15%,transparent); color:var(--pass); border:1px solid color-mix(in srgb,var(--pass) 40%,transparent); }
        .st-fail { background:color-mix(in srgb,var(--fail) 15%,transparent); color:var(--fail); border:1px solid color-mix(in srgb,var(--fail) 40%,transparent); }
        .st-soon { background:color-mix(in srgb,var(--placeholder) 15%,transparent); color:var(--placeholder); border:1px solid var(--placeholder); }
        .tc-msg { font-size:13px; color:var(--muted,#888); margin-bottom:8px; }
        .tc-details { font-size:11px; color:var(--muted); border-top:1px solid var(--line); padding-top:8px; margin-top:4px; word-break:break-word; }
        .tc-dur { position:absolute; top:16px; right:16px; font-size:11px; color:var(--muted); font-family:monospace; }
        /* Section label */
        .section-label { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.08em; color:var(--muted,#888); margin:24px 0 10px; display:flex; align-items:center; gap:8px; }
        .section-label::after { content:''; flex:1; height:1px; background:var(--line,#2a2d3e); }
        /* Email bar */
        .email-bar { display:flex; align-items:center; gap:14px; margin-top:24px; flex-wrap:wrap; }
        .btn-email { padding:10px 24px; border-radius:8px; font-size:14px; font-weight:600; cursor:pointer;
            border:1px solid #3b82f6; background:transparent; color:#3b82f6; transition:all .2s; display:inline-flex; align-items:center; gap:6px; }
        .btn-email:hover { background:rgba(59,130,246,.1); }
        .email-ok  { color:var(--pass); font-size:13px; }
        .email-err { color:var(--fail); font-size:13px; }
        /* Progress bar */
        .prog-wrap { background:var(--line,#2a2d3e); border-radius:6px; height:8px; margin-top:4px; }
        .prog-bar  { height:8px; border-radius:6px; background:linear-gradient(90deg,#10b981,#3b82f6); transition:width .8s ease; }
        /* Loading overlay */
        #loadOverlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,.5); backdrop-filter:blur(4px); z-index:9999; align-items:center; justify-content:center; flex-direction:column; gap:16px; }
        .spinner { width:48px; height:48px; border:4px solid rgba(255,255,255,.1); border-top-color:#3b82f6; border-radius:50%; animation:spin 1s linear infinite; }
        @keyframes spin { to { transform:rotate(360deg); } }
        .spinner-txt { color:var(--text); font-size:14px; }
        /* Back link */
        .back { display:inline-flex; align-items:center; gap:6px; color:var(--muted,#888); font-size:13px; text-decoration:none; margin-bottom:20px; }
        .back:hover { color:var(--accent,#2ea8ff); }
    </style>
</head>
<body>
<div id="loadOverlay"><div class="spinner"></div><div class="spinner-txt">Running diagnostics...</div></div>

<!-- Breadcrumb nav — matches all other iDash pages -->
<div style="display:flex; gap:8px; padding:10px 24px; background:var(--card,#1a1d2e); border-bottom:1px solid var(--line,#2a2d3e); flex-wrap:wrap; font-size:13px; align-items:center;">
    <a href="index.aspx" style="color:var(--accent,#2ea8ff); text-decoration:none; font-weight:600;">&#8962; iDash Home</a>
    <span style="color:var(--muted,#888);">&bull;</span>
    <span style="color:var(--text,#e0e0e0); font-weight:600;">&#128202; System Diagnostics</span>
    <span style="color:var(--muted,#888);">&bull;</span>
    <a href="documentation/va_system_diagnostics.html" target="_blank" style="color:var(--accent,#2ea8ff); text-decoration:none; font-weight:600;">&#128196; Documentation</a>
    <span style="color:var(--muted,#888);">&bull;</span>
    <a href="documentation/index.aspx" style="color:var(--accent,#2ea8ff); text-decoration:none; font-weight:600;">&#128218; All Docs</a>
</div>

<div class="page-wrap">

    <div class="diag-header">
        <div>
            <h1>&#128202; System Diagnostics</h1>
            <div class="meta">Server: <b><%= ServerHost %></b>
                <% if (TestsRan) { %> &nbsp;|&nbsp; Last run: <b><%= RunAt %></b><% } %>
            </div>
        </div>
        <% if (TestsRan) {
               bool healthy = (PassCount == TotalCount);
           %>
        <div class="health-badge <%= healthy ? "health-ok" : "health-fail" %>">
            <%= healthy ? "&#10003; HEALTHY" : "&#9888; DEGRADED" %>
        </div>
        <% } %>
    </div>

    <form runat="server" id="diagForm">

    <!-- What this page does -->
    <div class="card" style="border-left:4px solid #3b82f6; margin-bottom:20px;">
        <h2 style="color:#3b82f6; margin-bottom:14px;">&#128270; What This Page Does &mdash; Simulation Overview</h2>
        <p style="margin:0 0 14px; font-size:14px; line-height:1.7; color:var(--text,#e0e0e0);">
            This page runs a <strong>live end-to-end simulation of the AssetWorx mobile app in batch (offline) mode</strong>.
            When a RFID scanner or mobile device operates without a network connection, it accumulates a queue of asset scans locally.
            When it reconnects, it uploads that queue by calling the AssetWorx API once per asset &mdash; this page replicates
            that exact sequence so you can verify the system is ready <em>before</em> deploying hardware.
        </p>
        <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:12px; margin-top:4px;">
            <div style="background:color-mix(in srgb,#128273 8%,transparent); border:1px solid color-mix(in srgb,#128273 30%,transparent); border-radius:10px; padding:14px 16px;">
                <div style="font-weight:700; font-size:13px; color:#128273; margin-bottom:6px;">&#128273; Step 1 &mdash; Authentication</div>
                <div style="font-size:12px; color:var(--muted,#888); line-height:1.6;">Requests an OAuth2 access token from the AssetWorx identity server using <code>client_credentials</code> &mdash; the same login flow the mobile app uses. Confirms the API is running and credentials are valid.</div>
            </div>
            <div style="background:color-mix(in srgb,#8b5cf6 8%,transparent); border:1px solid color-mix(in srgb,#8b5cf6 30%,transparent); border-radius:10px; padding:14px 16px;">
                <div style="font-weight:700; font-size:13px; color:#8b5cf6; margin-bottom:6px;">&#128451; Step 2 &mdash; Database &amp; License Check</div>
                <div style="font-size:12px; color:var(--muted,#888); line-height:1.6;">Queries <code>dbo.applicationsetting</code> to verify the license key is present and matches this server. Checks company and asset counts. A missing or mismatched license causes all batch uploads to fail with &ldquo;License limits exceeded.&rdquo;</div>
            </div>
            <div style="background:color-mix(in srgb,#3b82f6 8%,transparent); border:1px solid color-mix(in srgb,#3b82f6 30%,transparent); border-radius:10px; padding:14px 16px;">
                <div style="font-weight:700; font-size:13px; color:#3b82f6; margin-bottom:6px;">&#128268; Step 3 &mdash; Server Registration</div>
                <div style="font-size:12px; color:var(--muted,#888); line-height:1.6;">Checks <code>dbo.serverstatus</code> to confirm the Alarm Monitoring Service and Print Server are registered and recently active. After a DB restore, stale entries from the old server can inflate the &ldquo;server count&rdquo; and trigger the license limit.</div>
            </div>
            <div style="background:color-mix(in srgb,#f59e0b 8%,transparent); border:1px solid color-mix(in srgb,#f59e0b 30%,transparent); border-radius:10px; padding:14px 16px;">
                <div style="font-weight:700; font-size:13px; color:#f59e0b; margin-bottom:6px;">&#128229; Step 4 &mdash; Batch Read Test</div>
                <div style="font-size:12px; color:var(--muted,#888); line-height:1.6;">
                    Loads <em>N</em> asset IDs from the database (your &ldquo;Batch Size&rdquo; setting) and fetches each one via:
                    <code style="display:block; margin:6px 0; padding:4px 8px; background:rgba(0,0,0,.3); border-radius:4px; font-size:11px;">GET /api/asset/{id}</code>
                    This is a <strong>read-only test</strong> &mdash; it validates API authentication, authorization, and license limits without modifying any data. No asset records are changed.
                </div>
            </div>
            <div style="background:color-mix(in srgb,#ef4444 8%,transparent); border:1px solid color-mix(in srgb,#ef4444 30%,transparent); border-radius:10px; padding:14px 16px; grid-column:1/-1;">
                <div style="font-weight:700; font-size:13px; color:#ef4444; margin-bottom:6px;">&#128274; Step 5 &mdash; Security &amp; Stress Tests</div>
                <div style="font-size:12px; color:var(--muted,#888); line-height:1.6;">
                    Executes non-destructive vulnerability checks including: <strong>(1) Database Write Permissions</strong> (via a rolled-back SQL transaction), <strong>(2) File System Security</strong> (verifies IIS can write to <code>logs</code>), <strong>(3) DB Principle Check</strong> (ensures the account is not <code>db_owner</code> or <code>sysadmin</code>), <strong>(4) Dependency Validation</strong> (scans loaded DLLs), and <strong>(5) Web.config Hardening</strong>.
                </div>
            </div>
        </div>
        <div style="margin-top:14px; padding:10px 14px; background:rgba(0,0,0,.2); border-radius:8px; font-size:12px; color:var(--muted,#888);">
            &#128218; <a href="documentation/va_system_diagnostics.html" target="_blank" style="color:var(--accent,#2ea8ff);">Full documentation</a>
            &nbsp;&mdash;&nbsp; &#128196; API log: <code>C:\Logs\WebClient_log.txt</code>
            &nbsp;&mdash;&nbsp; &#128196; PowerShell equivalent: <code>C:\va_rfid\V5Data\tools\Invoke-BatchModeTest.ps1</code>
        </div>
    </div>

    <!-- Config -->
    <div class="card">
        <h2>&#9881;&#65039; Configuration</h2>
        <div class="cfg-grid">
            <div class="cfg-field">
                <label>Company / Site</label>
                <asp:DropDownList ID="DdlCompany" runat="server" />
            </div>
            <div class="cfg-field">
                <label>Batch Size (assets)</label>
                <asp:TextBox ID="TxtBatchSize" runat="server" TextMode="Number" Text="5" />
            </div>
            <div class="cfg-field" style="display:flex;align-items:flex-end;">
                <asp:Button ID="BtnRun" runat="server" Text="&#9654; Run Diagnostics"
                    CssClass="btn-run" OnClick="BtnRun_Click"
                    OnClientClick="showLoader(); return true;" />
            </div>
        </div>
    </div>

    <!-- Load & Stress Tools -->
    <div class="section-label">&#128200; Load &amp; Stress Tools</div>
    <div class="card" style="border-left:4px solid #3b82f6; margin-bottom:20px;">
        <h2 style="color:#3b82f6; margin-bottom:14px;">MQTT Broker Concurrency Test</h2>
        <p style="margin:0 0 14px; font-size:13px; line-height:1.6; color:var(--text,#e0e0e0);">
            Simulates a massive burst of IoT traffic by spawning multiple concurrent connections, simulating fixed readers streaming reads across multiple antennas simultaneously. Use this to determine if your environment requires a high-performance external broker (like RabbitMQ).
        </p>
        <div class="cfg-grid" style="grid-template-columns: 1fr 1fr 1fr 1fr 1fr auto; align-items: end; background:var(--bg,#0f1117); padding:16px; border-radius:8px;">
            <div class="cfg-field">
                <label style="color:#3b82f6;">Broker Server</label>
                <asp:TextBox ID="TxtStressServer" runat="server" Text="localhost" CssClass="txt" />
            </div>
            <div class="cfg-field">
                <label style="color:#3b82f6;">Port</label>
                <asp:TextBox ID="TxtStressPort" runat="server" Text="8883" CssClass="txt" />
            </div>
            <div class="cfg-field">
                <label style="color:#3b82f6;">Readers</label>
                <asp:TextBox ID="TxtStressReaders" runat="server" Text="40" CssClass="txt" />
            </div>
            <div class="cfg-field">
                <label style="color:#3b82f6;">Antennas</label>
                <asp:TextBox ID="TxtStressAntennas" runat="server" Text="8" CssClass="txt" />
            </div>
            <div class="cfg-field">
                <label style="color:#3b82f6;">Reads</label>
                <asp:TextBox ID="TxtStressReads" runat="server" Text="50" CssClass="txt" />
            </div>
            <div class="cfg-field">
                <asp:Button ID="BtnStressTest" runat="server" Text="Execute Load Simulation" CssClass="btn" style="background:#3b82f6; width:auto; padding:0 24px;" OnClick="BtnStressTest_Click" OnClientClick="showLoader();" />
            </div>
        </div>
        
        <asp:Panel ID="PnlStressResult" runat="server" Visible="false" style="margin-top:16px; padding:16px; border-radius:8px; background:#1a1d2e; border:1px solid #2a2d3e;">
            <h3 style="margin:0 0 10px; font-size:14px; color:#e0e0e0;">Stress Test Results</h3>
            <div style="display:flex; gap:20px; flex-wrap:wrap;">
                <div class="summary-stat" style="background:transparent; border:none; padding:0; min-width:auto;"><div class="val" style="color:#10b981;"><asp:Literal ID="LitStressTotal" runat="server" /></div><div class="lbl">Total Published</div></div>
                <div class="summary-stat" style="background:transparent; border:none; padding:0; min-width:auto;"><div class="val" style="color:#3b82f6;"><asp:Literal ID="LitStressTime" runat="server" /></div><div class="lbl">Duration (ms)</div></div>
                <div class="summary-stat" style="background:transparent; border:none; padding:0; min-width:auto;"><div class="val" style="color:#ef4444;"><asp:Literal ID="LitStressFailConn" runat="server" /></div><div class="lbl">Failed Connections</div></div>
                <div class="summary-stat" style="background:transparent; border:none; padding:0; min-width:auto;"><div class="val" style="color:#ef4444;"><asp:Literal ID="LitStressFailPub" runat="server" /></div><div class="lbl">Dropped Packets</div></div>
            </div>
        </asp:Panel>
    </div>

    <% if (TestsRan) { %>

    <!-- Summary Stats -->
    <div class="summary-bar">
        <div class="summary-stat">
            <div class="val" style="color:<%= PassCount==TotalCount ? "var(--pass)" : "var(--fail)" %>"><%= PassCount %>/<%= TotalCount %></div>
            <div class="lbl">Tests Passed</div>
            <div class="prog-wrap"><div class="prog-bar" style="width:<%= TotalCount > 0 ? (PassCount*100/TotalCount) : 0 %>%"></div></div>
        </div>
        <div class="summary-stat">
            <div class="val" style="color:#3b82f6;"><%= TotalMs %>ms</div>
            <div class="lbl">Total Runtime</div>
        </div>
        <div class="summary-stat">
            <div class="val" style="color:#8b5cf6;"><%= TestResults.Count(r => r.Category != "placeholder") %></div>
            <div class="lbl">Tests Run</div>
        </div>
        <div class="summary-stat">
            <div class="val" style="color:#f59e0b;"><%= TestResults.Count(r => r.Category == "placeholder") %></div>
            <div class="lbl">Coming Soon</div>
        </div>
    </div>

    <!-- API Tests -->
    <div class="section-label">&#128225; AssetWorx API Tests</div>
    <div class="test-grid">
    <% foreach (var r in TestResults.Where(x => x.Category == "api")) { %>
        <div class="test-card <%= r.Passed ? "pass" : "fail" %>">
            <% if (r.DurationMs > 0) { %><div class="tc-dur"><%= r.DurationMs %>ms</div><% } %>
            <div class="tc-header">
                <div class="tc-icon"><%= r.Icon %></div>
                <div class="tc-title"><%= r.TestName %></div>
                <span class="tc-status <%= r.Passed ? "st-pass" : "st-fail" %>"><%= r.Passed ? "PASS" : "FAIL" %></span>
            </div>
            <div class="tc-msg"><%= r.Message %></div>
            <% if (!string.IsNullOrEmpty(r.Details)) { %>
            <div class="tc-details"><%= r.Details %></div>
            <% } %>
        </div>
    <% } %>
    </div>

    <!-- DB Tests -->
    <div class="section-label">&#128451; Database & License Tests</div>
    <div class="test-grid">
    <% foreach (var r in TestResults.Where(x => x.Category == "db")) { %>
        <div class="test-card <%= r.Passed ? "pass" : "fail" %>">
            <% if (r.DurationMs > 0) { %><div class="tc-dur"><%= r.DurationMs %>ms</div><% } %>
            <div class="tc-header">
                <div class="tc-icon"><%= r.Icon %></div>
                <div class="tc-title"><%= r.TestName %></div>
                <span class="tc-status <%= r.Passed ? "st-pass" : "st-fail" %>"><%= r.Passed ? "PASS" : "FAIL" %></span>
            </div>
            <div class="tc-msg"><%= r.Message %></div>
            <% if (!string.IsNullOrEmpty(r.Details)) { %>
            <div class="tc-details"><%= r.Details %></div>
            <% } %>
        </div>
    <% } %>
    </div>

    <!-- MQTT -->
    <div class="section-label">&#128225; MQTT &amp; Print Tests</div>
    <div class="test-grid">
    <% foreach (var r in TestResults.Where(x => x.Category == "mqtt")) { %>
        <div class="test-card <%= r.Passed ? "pass" : "fail" %>">
            <% if (r.DurationMs > 0) { %><div class="tc-dur"><%= r.DurationMs %>ms</div><% } %>
            <div class="tc-header">
                <div class="tc-icon"><%= r.Icon %></div>
                <div class="tc-title"><%= r.TestName %></div>
                <span class="tc-status <%= r.Passed ? "st-pass" : "st-fail" %>"><%= r.Passed ? "PASS" : "FAIL" %></span>
            </div>
            <div class="tc-msg"><%= r.Message %></div>
            <% if (!string.IsNullOrEmpty(r.Details)) { %>
            <div class="tc-details"><%= r.Details %></div>
            <% } %>
        </div>
    <% } %>
    </div>

    <!-- Security & System Tests -->
    <div class="section-label">&#128274; Security &amp; System Hardening Tests</div>
    <div class="test-grid">
    <% foreach (var r in TestResults.Where(x => x.Category == "security" || x.Category == "system")) { %>
        <div class="test-card <%= r.Passed ? "pass" : "fail" %>">
            <% if (r.DurationMs > 0) { %><div class="tc-dur"><%= r.DurationMs %>ms</div><% } %>
            <div class="tc-header">
                <div class="tc-icon"><%= r.Icon %></div>
                <div class="tc-title"><%= r.TestName %></div>
                <span class="tc-status <%= r.Passed ? "st-pass" : "st-fail" %>"><%= r.Passed ? "PASS" : "FAIL" %></span>
            </div>
            <div class="tc-msg"><%= r.Message %></div>
            <% if (!string.IsNullOrEmpty(r.Details)) { %>
            <div class="tc-details"><%= r.Details %></div>
            <% } %>
        </div>
    <% } %>
    </div>


    <!-- Email report -->
    <div class="email-bar">
        <asp:Button ID="BtnDownload" runat="server" Text="&#128190; Download Log" CssClass="btn-email" OnClick="BtnDownload_Click" style="margin-right:8px;" />
        <asp:Button ID="BtnEmail" runat="server" Text="&#128231; Email Report" CssClass="btn-email" OnClick="BtnEmail_Click" />
        <asp:Label ID="LblEmailStatus" runat="server" Text="" />
    </div>

    <% } else { %>
    <div style="text-align:center; padding:60px 20px; color:var(--muted,#888);">
        <div style="font-size:48px; margin-bottom:16px;">&#128202;</div>
        <div style="font-size:16px;">Configure options above and click <b>Run Diagnostics</b> to begin.</div>
        <div style="font-size:13px; margin-top:8px;">Tests include: API auth &bull; License check &bull; Batch read test (read-only) &bull; Server registration &bull; MQTT broker &amp; print topic</div>
    </div>
    <% } %>

    </form>
</div>

<script>
function showLoader() {
    document.getElementById('loadOverlay').style.display = 'flex';
}
</script>
</body>
</html>
