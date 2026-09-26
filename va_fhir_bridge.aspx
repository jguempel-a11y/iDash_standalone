<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_fhir_bridge.aspx.cs" Inherits="va_fhir_bridge" MaintainScrollPositionOnPostBack="true" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">

<head runat="server">
    <title>Supply Chain Bridge &mdash; iDash &rarr; VistA</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />

    <style>
        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font-family: Segoe UI, system-ui, Arial, sans-serif;
        }

        /* Skip-nav: hidden off-screen, visible only on keyboard focus (Section 508) */
        .skip-nav {
            position: absolute; left: -9999px; top: auto;
            width: 1px; height: 1px; overflow: hidden;
            z-index: 9999;
            background: var(--accent); color: #fff;
            padding: 10px 18px; border-radius: 0 0 8px 0;
            font-weight: 700; font-size: 14px; text-decoration: none;
        }
        .skip-nav:focus {
            left: 0; top: 0; width: auto; height: auto;
            overflow: visible;
        }

        .wrap {
            padding: 16px;
            max-width: 1200px;
            margin: 0 auto;
        }

        .top {
            display: flex;
            gap: 12px;
            align-items: flex-start;
            justify-content: space-between;
            flex-wrap: wrap;
            margin-bottom: 14px;
        }

        .h1 {
            font-size: 22px;
            font-weight: 800;
            letter-spacing: .2px;
        }

        .sub {
            color: var(--muted);
            font-size: 13px;
            margin-top: 4px;
        }

        .status-bar {
            display: flex;
            justify-content: space-between;
            background: var(--chip);
            padding: 8px 20px;
            font-size: 13px;
            border-bottom: 1px solid var(--line);
        }

        .panel {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 18px;
            margin-bottom: 14px;
            box-shadow: var(--shadow);
        }

        .panel-title {
            font-size: 15px;
            font-weight: 800;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .panel-title .icon {
            font-size: 18px;
        }

        .row {
            display: flex;
            gap: 14px;
            flex-wrap: wrap;
        }

        .row > .panel {
            flex: 1;
            min-width: 340px;
        }

        .btnbar {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            margin-top: 10px;
        }

        .btn {
            border: 1px solid var(--line);
            background: var(--chip);
            color: var(--text);
            padding: 10px 14px;
            border-radius: 12px;
            cursor: pointer;
            font-weight: 700;
            font-size: 13px;
            transition: transform 0.1s, background 0.15s, box-shadow 0.15s;
        }

        .btn:hover {
            background: color-mix(in srgb, var(--accent), transparent 85%);
            border-color: color-mix(in srgb, var(--accent), transparent 55%);
        }

        .btn:active {
            transform: translateY(1px);
        }

        .btn.primary {
            background: color-mix(in srgb, var(--accent), transparent 80%);
            border-color: color-mix(in srgb, var(--accent), transparent 45%);
            color: var(--accent);
        }

        .btn.good {
            background: color-mix(in srgb, var(--accent-2), transparent 80%);
            border-color: color-mix(in srgb, var(--accent-2), transparent 45%);
            color: var(--accent-2);
        }

        .btn.bad {
            background: color-mix(in srgb, var(--danger), transparent 80%);
            border-color: color-mix(in srgb, var(--danger), transparent 45%);
            color: var(--danger);
        }

        .btn.fhir {
            background: color-mix(in srgb, #e87722, transparent 80%);
            border-color: color-mix(in srgb, #e87722, transparent 45%);
            color: #e87722;
        }

        .tag {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: var(--chip);
            border: 1px solid var(--line);
            padding: 5px 10px;
            border-radius: 999px;
            font-size: 12px;
            color: var(--muted);
        }

        .tag b {
            color: var(--text);
        }

        .field {
            width: 100%;
            padding: 10px 12px;
            border-radius: 10px;
            border: 1px solid var(--line);
            background: var(--chip);
            color: var(--text);
            font-size: 14px;
            outline: none;
            box-sizing: border-box;
        }

        .field:focus {
            border-color: var(--accent);
            box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent), transparent 85%);
        }

        .field-group {
            margin-bottom: 12px;
        }

        .field-label {
            font-size: 12px;
            font-weight: 700;
            color: var(--muted);
            margin-bottom: 4px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }

        .ta {
            width: 100%;
            min-height: 200px;
            resize: vertical;
            padding: 12px;
            border-radius: 12px;
            border: 1px solid var(--line);
            background: var(--chip);
            color: var(--text);
            font-family: Consolas, Menlo, monospace;
            font-size: 12px;
            box-sizing: border-box;
        }

        .jwk-box {
            background: var(--preview-bg);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 14px;
            font-family: Consolas, Menlo, monospace;
            font-size: 12px;
            color: var(--preview-text);
            max-height: 160px;
            overflow: auto;
            white-space: pre-wrap;
            word-break: break-all;
        }

        .kpi-bar {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-bottom: 12px;
        }

        .kpi {
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 8px 12px;
            min-width: 100px;
        }

        .kpi .n {
            font-size: 18px;
            font-weight: 800;
        }

        .kpi .l {
            font-size: 11px;
            color: var(--muted);
            margin-top: 2px;
        }

        .grid {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
            margin-top: 8px;
            border: 1px solid var(--line);
            border-radius: 12px;
            overflow: hidden;
        }

        .grid th, .grid td {
            padding: 8px 10px;
            border-bottom: 1px solid var(--line);
            vertical-align: top;
        }

        .grid th {
            background: var(--table-head);
            text-align: left;
            color: var(--muted);
            font-weight: 800;
            font-size: 11px;
            text-transform: uppercase;
        }

        .grid tr:last-child td {
            border-bottom: none;
        }

        .grid tr:hover td {
            background: var(--table-row-hover);
        }

        .mono {
            font-family: Consolas, Menlo, monospace;
        }

        .ok {
            color: var(--ok-text);
        }

        .err {
            color: var(--err-text);
        }

        .warn {
            color: var(--warn-text);
        }

        .hint {
            color: var(--muted);
            font-size: 12px;
            margin-top: 6px;
            line-height: 1.4;
        }

        .log-box {
            background: var(--preview-bg);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px;
            max-height: 300px;
            overflow-y: auto;
            font-family: Consolas, Menlo, monospace;
            font-size: 11px;
            color: var(--log-text);
        }

        .log-entry {
            margin-bottom: 6px;
            padding: 4px 0;
            border-bottom: 1px solid color-mix(in srgb, var(--line), transparent 70%);
        }

        .log-entry:last-child {
            border-bottom: none;
        }

        .company-select {
            background: var(--card);
            color: var(--text);
            border: 1px solid var(--line);
            padding: 6px 10px;
            border-radius: 8px;
            font-size: 14px;
        }

        .badge-fhir {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            color: #fff;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.3px;
        }

        .badge-sandbox {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: color-mix(in srgb, var(--warn), transparent 88%);
            color: var(--warn);
            border: 1px solid color-mix(in srgb, var(--warn), transparent 65%);
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
        }

        .badge-key {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
        }

        .badge-key.exists {
            background: color-mix(in srgb, var(--accent-2), transparent 88%);
            color: var(--accent-2);
            border: 1px solid color-mix(in srgb, var(--accent-2), transparent 65%);
        }

        .badge-key.missing {
            background: color-mix(in srgb, var(--danger), transparent 88%);
            color: var(--danger);
            border: 1px solid color-mix(in srgb, var(--danger), transparent 65%);
        }

        .footer {
            margin-top: 14px;
            color: var(--muted);
            font-size: 12px;
            text-align: center;
        }

        .mode-toggle {
            display: flex;
            border: 1px solid var(--line);
            border-radius: 10px;
            overflow: hidden;
            margin-top: 8px;
        }

        .mode-toggle label {
            flex: 1;
            padding: 8px 14px;
            text-align: center;
            cursor: pointer;
            font-size: 13px;
            font-weight: 700;
            background: var(--chip);
            color: var(--muted);
            transition: all 0.2s;
        }

        .mode-toggle input[type="radio"] {
            display: none;
        }

        .mode-toggle input[type="radio"]:checked + label {
            background: color-mix(in srgb, var(--accent), transparent 85%);
            color: var(--accent);
        }

        .tab-bar {
            display: flex;
            gap: 2px;
            margin-bottom: 14px;
            border-bottom: 2px solid var(--line);
        }

        .tab-bar button {
            background: none;
            border: none;
            color: var(--muted);
            padding: 10px 16px;
            font-weight: 700;
            font-size: 13px;
            cursor: pointer;
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            transition: 0.15s;
        }

        .tab-bar button.active {
            color: var(--accent);
            border-bottom-color: var(--accent);
        }

        .tab-bar button:hover {
            color: var(--text);
        }

        .tab-content {
            display: none;
        }

        .tab-content.active {
            display: block;
        }

        /* Selection checkbox column */
        .chk-col {
            width: 30px;
            text-align: center;
        }

        .select-all {
            cursor: pointer;
        }

        /* GridView styles */
        .grid { width:100%; border-collapse:collapse; font-size:13px; }
        .grid-head th { background:var(--card2); color:var(--muted); font-weight:600; text-align:left; padding:8px 10px; border-bottom:2px solid var(--line); font-size:11px; text-transform:uppercase; letter-spacing:.5px; }
        .grid-row td, .grid-row-alt td { padding:8px 10px; border-bottom:1px solid var(--line); }
        .grid-row-alt td { background: rgba(255,255,255,0.02); }
        .grid-row:hover td, .grid-row-alt:hover td { background: rgba(99,102,241,0.08); }
        .grid td .btn { padding:4px 10px; font-size:11px; }

        /* step result styles */
        .step-ok { color:#22c55e; padding:3px 0; font-size:13px; }
        .step-warn { color:#f59e0b; padding:3px 0; font-size:13px; }
        .step-err { color:#ef4444; padding:3px 0; font-size:13px; }

        /* Dark mode calendar / date input fix */
        input[type="date"] {
            color-scheme: dark;
        }
        [data-theme="light"] input[type="date"] {
            color-scheme: light;
        }

        /* Theme toggle in status bar */
        .theme-switch {
            display: inline-flex; align-items: center; gap: 6px;
            background: rgba(0,0,0,0.2); border-radius: 20px; padding: 3px;
            margin-left: 10px;
        }
        .theme-switch button {
            background: none; border: none; color: var(--muted);
            padding: 4px 10px; border-radius: 16px; cursor: pointer;
            font-size: 12px; font-weight: 600; transition: 0.15s;
        }
        .theme-switch button.active {
            background: var(--accent); color: #fff;
        }
        .theme-switch button:hover:not(.active) {
            color: var(--text);
        }

        /* Footer */
        .page-footer {
            margin-top: 40px; padding: 20px; border-top: 1px solid var(--line);
            font-size: 12px; color: var(--muted);
            display: flex; justify-content: space-between; align-items: center;
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <!-- ACCESS DENIED -->
        <asp:Panel ID="PnlAccessDenied" runat="server" Visible="false">
            <div class="wrap" style="text-align:center; padding-top:80px;">
                <div style="font-size:64px; margin-bottom:16px;">&#128274;</div>
                <h2 style="color:#ef4444; margin-bottom:12px;">Access Denied</h2>
                <p style="color:var(--muted); max-width:480px; margin:0 auto 24px;">
                    You must be logged in with the appropriate permissions to access the FHIR Bridge.
                    Please return to the iDash home page and authenticate.
                </p>
                <a href="index.aspx" class="nav-pill nav-pill-primary" style="font-size:15px; padding:10px 24px;">&#8962; Hub</a>
            </div>
        </asp:Panel>

        <!-- MAIN CONTENT (requires authentication) -->
        <asp:Panel ID="PnlMain" runat="server">
        <a class="skip-nav" href="#main-content">Skip to main content</a>

        <!-- STATUS BAR -->
        <div class="status-bar">
            <span>AssetWorx Supply Chain Bridge &mdash; SERVER: <%= System.Environment.MachineName %> (<%= Request.ServerVariables["LOCAL_ADDR"] %>)</span>
            <span style="display:flex; align-items:center; gap:8px;">
                <span class="badge-fhir" style="background:#e87722;">&#x1F4E6; AEMS/MERS</span>
                <span class="badge-fhir" style="background:#10b981;">&#x1F6E1; Supply Chain Only</span>
                <asp:Literal ID="LitModeBadge" runat="server" />
                <span class="theme-switch">
                    <button type="button" id="btnThemeDark" onclick="setTheme('dark')" class="active">&#x1F319; Dark</button>
                    <button type="button" id="btnThemeLight" onclick="setTheme('light')">&#x2600; Light</button>
                </span>
            </span>
        </div>

        <main id="main-content" role="main">
        <div class="wrap">

            <!-- HEADER -->
            <div class="top">
                <div style="flex:1;">
                    <div class="h1" style="display:flex; justify-content:space-between; align-items:center;">
                        <span>&#x1F3E5; Supply Chain Bridge &mdash; AssetWorx &rarr; VistA</span>
                        <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    </div>
                    <div class="sub">
                        Push supply chain data (assets &amp; locations) from AssetWorx to VA VistA
                        via AEMS/MERS SQL sync. No patient data &mdash; supply chain inventory only.
                    </div>
                </div>
            </div>

            <!-- TAB BAR -->
            <nav aria-label="Page sections">
            <div class="tab-bar" id="tabBar" role="tablist" aria-label="Supply Chain Bridge sections">
                <button type="button" role="tab" class="active" aria-selected="true" aria-controls="tab-aems" id="btn-tab-aems" onclick="switchTab('aems')"><span aria-hidden="true">&#x1F4E6;</span> AEMS/MERS Push</button>
                <button type="button" role="tab" aria-selected="false" aria-controls="tab-log" id="btn-tab-log" onclick="switchTab('log')"><span aria-hidden="true">&#x1F4CB;</span> Transaction Log</button>
            </div>
            </nav>

            <!-- SERVER-SIDE MESSAGES -->
            <asp:Literal ID="LitMsg" runat="server" />

            <!-- Hidden field to preserve active tab across postbacks -->
            <asp:HiddenField ID="HidActiveTab" runat="server" Value="aems" />

            <!-- =============================================== -->
            <!-- TAB 1: AEMS/MERS SQL PUSH                        -->
            <!-- =============================================== -->
            <div class="tab-content active" id="tab-aems" role="tabpanel" aria-labelledby="btn-tab-aems">

                <!-- STEP 1: SELECT ENNX SESSION -->
                <div class="row">
                    <div class="panel" style="flex:2;">
                        <div class="panel-title"><span class="icon">&#x1F4E1;</span> Step 1: Browse Scan History</div>
                        <div class="hint" style="margin-top:0; margin-bottom:14px;">
                            Select a scanner to view all scan dates, or leave on &ldquo;All Users&rdquo; to see everything. Optionally filter by date.
                        </div>

                        <div class="row" style="gap:12px; align-items:flex-end;">
                            <div class="field-group" style="flex:1;">
                                <div class="field-label">Scanner</div>
                                <asp:DropDownList ID="DdlEnnxUser" runat="server" CssClass="field"
                                    AutoPostBack="true" OnSelectedIndexChanged="DdlEnnxUser_Changed" />
                            </div>
                            <div class="field-group" style="flex:1;">
                                <div class="field-label">Date Filter (Optional)</div>
                                <asp:TextBox ID="TxtEnnxDate" runat="server" CssClass="field"
                                    TextMode="Date" />
                            </div>
                            <div style="padding-bottom:2px;">
                                <asp:Button ID="BtnLoadEnnxSessions" runat="server" CssClass="btn primary"
                                    Text="&#x1F50D; Load Scans" OnClick="BtnLoadEnnxSessions_Click" />
                            </div>
                        </div>

                        <!-- Session Grid -->
                        <div style="margin-top:12px;">
                            <asp:GridView ID="GridEnnxSessions" runat="server" AutoGenerateColumns="false"
                                CssClass="grid" GridLines="None" CellPadding="6"
                                OnRowCommand="GridEnnxSessions_RowCommand"
                                EmptyDataText="No scans found. Select a scanner or date and click Load Scans.">
                                <HeaderStyle CssClass="grid-head" />
                                <RowStyle CssClass="grid-row" />
                                <AlternatingRowStyle CssClass="grid-row-alt" />
                                <Columns>
                                    <asp:BoundField DataField="TagDate" HeaderText="Date" DataFormatString="{0:yyyy-MM-dd}" />
                                    <asp:BoundField DataField="Scanner" HeaderText="Scanner" />
                                    <asp:BoundField DataField="AssetCount" HeaderText="Assets" />
                                    <asp:BoundField DataField="FirstScan" HeaderText="First Scan" DataFormatString="{0:HH:mm}" />
                                    <asp:BoundField DataField="LastScan" HeaderText="Last Scan" DataFormatString="{0:HH:mm}" />
                                    <asp:ButtonField ButtonType="Button" CommandName="SelectSession"
                                        Text="&#x1F4C4; Load" ControlStyle-CssClass="btn" />
                                </Columns>
                            </asp:GridView>
                        </div>
                    </div>

                    <!-- KPI Panel -->
                    <div class="panel" style="flex:1;">
                        <div class="panel-title"><span class="icon">&#x1F4CA;</span> Session Info</div>
                        <div class="kpi-bar" style="flex-direction:column; gap:6px;">
                            <div class="kpi">
                                <div class="n"><asp:Literal ID="LitEnnxAssetCount" runat="server">&mdash;</asp:Literal></div>
                                <div class="l">Assets in ENNX</div>
                            </div>
                            <div class="kpi">
                                <div class="n"><asp:Literal ID="LitEnnxLocCount" runat="server">&mdash;</asp:Literal></div>
                                <div class="l">Locations</div>
                            </div>
                            <div class="kpi">
                                <div class="n"><asp:Literal ID="LitEnnxSessionDate" runat="server">&mdash;</asp:Literal></div>
                                <div class="l">Scan Date</div>
                            </div>
                        </div>

                        <div class="hint" style="margin-top:16px; padding:10px; background:var(--chip); border:1px solid var(--line); border-radius:8px;">
                            <strong>&#x2139; How it works:</strong><br />
                            1. Pick a scanner (or All Users)<br />
                            2. Browse scan dates &rarr; click <strong>Load</strong><br />
                            3. Review the ENNX preview below<br />
                            4. Click <strong>&#x1F680; Push to VistA</strong> to sync
                        </div>
                    </div>
                </div>

                <!-- STEP 2: ENNX PREVIEW -->
                <div class="panel">
                    <div class="panel-title"><span class="icon">&#x1F4C4;</span> Step 2: ENNX Preview</div>
                    <asp:TextBox ID="TxtEnnxPreview" runat="server" TextMode="MultiLine" ReadOnly="true"
                        CssClass="ta" Rows="12" style="font-family:Consolas,monospace; font-size:12px; min-height:200px;" />
                    <asp:HiddenField ID="HidEnnxSessionId" runat="server" />
                    <div style="margin-top:8px; display:flex; gap:16px; font-size:13px; color:var(--muted);">
                        <asp:Literal ID="LitEnnxSummaryBar" runat="server" />
                    </div>
                </div>

                <!-- STEP 3: PUSH TO VISTA -->
                <div class="row">
                    <div class="panel" style="flex:2;">
                        <div class="panel-title"><span class="icon">&#x1F680;</span> Step 3: Push to VistA</div>

                        <div class="btnbar">
                            <asp:Button ID="BtnAemsExportTsv" runat="server" CssClass="btn"
                                Text="&#x1F4C4; Download ENNX File" OnClick="BtnAemsExportTsv_Click" />
                            <asp:Button ID="BtnPushToVistaAems" runat="server" CssClass="btn"
                                Text="&#x1F680; Push to VistA" OnClick="BtnPushToVistaAems_Click"
                                OnClientClick="return confirm('This will parse the ENNX file, update local AssetWorx, and MERGE changes into the VA database. Continue?');"
                                style="background:linear-gradient(135deg, #e87722, #c75b10); font-weight:700;" />
                        </div>

                        <div style="margin-top:12px;">
                            <asp:Literal ID="LitAemsResult" runat="server" />
                        </div>
                    </div>

                    <!-- VA SQL Config (collapsed by default) -->
                    <div class="panel" style="flex:1;">
                        <div class="panel-title"><span class="icon">&#x2699;</span> VA SQL Connection</div>
                        <div class="field-group">
                            <div class="field-label">VA SQL Server</div>
                            <asp:TextBox ID="TxtVaSqlServer" runat="server" CssClass="field"
                                placeholder="OITPORSQL016.R01.MED.VA.GOV" style="font-size:11px;" />
                        </div>
                        <div class="field-group">
                            <div class="field-label">Database</div>
                            <asp:TextBox ID="TxtVaDbName" runat="server" CssClass="field"
                                placeholder="VAAssetSync" style="font-size:11px;" />
                        </div>
                        <div class="field-group">
                            <div class="field-label">Username</div>
                            <asp:TextBox ID="TxtVaDbUser" runat="server" CssClass="field"
                                placeholder="vadbuser" style="font-size:11px;" />
                        </div>
                        <div class="field-group">
                            <div class="field-label">Password</div>
                            <asp:TextBox ID="TxtVaDbPass" runat="server" CssClass="field"
                                TextMode="Password" placeholder="&#x2022;&#x2022;&#x2022;&#x2022;" style="font-size:11px;" />
                        </div>
                        <div class="field-group">
                            <div class="field-label">File Share Path</div>
                            <asp:TextBox ID="TxtVaSharePath" runat="server" CssClass="field"
                                placeholder="\\vhavanapprfidp\..." style="font-size:11px;" />
                        </div>
                        <div class="btnbar" style="margin-top:4px;">
                            <asp:Button ID="BtnSaveAemsConfig" runat="server" CssClass="btn primary"
                                Text="&#x1F4BE; Save" OnClick="BtnSaveAemsConfig_Click" style="font-size:11px; padding:6px 10px;" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- =============================================== -->
            <!-- TAB 2: RSA KEY MANAGEMENT & SANDBOX              -->
            <!-- =============================================== -->
            <div class="tab-content" id="tab-keys" role="tabpanel" aria-labelledby="btn-tab-keys">
                <div class="row">
                    <!-- KEY STATUS -->
                    <div class="panel">
                        <div class="panel-title"><span class="icon">&#x1F511;</span> RSA Key Status</div>

                        <div class="kpi-bar">
                            <div class="kpi">
                                <div class="n"><asp:Literal ID="LitKeyStatus" runat="server" /></div>
                                <div class="l">Private Key</div>
                            </div>
                            <div class="kpi">
                                <div class="n"><asp:Literal ID="LitPubKeyStatus" runat="server" /></div>
                                <div class="l">Public Key</div>
                            </div>
                            <div class="kpi">
                                <div class="n"><asp:Literal ID="LitJwkStatus" runat="server" /></div>
                                <div class="l">JWK File</div>
                            </div>
                        </div>

                        <div class="btnbar">
                            <asp:Button ID="BtnGenerateKeys" runat="server" CssClass="btn primary"
                                Text="&#x1F504; Generate RSA Key Pair" OnClick="BtnGenerateKeys_Click" />
                        </div>

                        <div class="hint">
                            <strong>How it works:</strong> Generates a 2048-bit RSA key pair using .NET cryptography
                            (equivalent to <code>openssl genrsa -out private.pem 2048</code>). The public key is 
                            exported in JWK format for pasting into the 
                            <a href="https://developer.va.gov" target="_blank">VA Lighthouse developer portal</a>.
                        </div>
                    </div>

                    <!-- JWK PREVIEW -->
                    <div class="panel">
                        <div class="panel-title"><span class="icon">&#x1F4CB;</span> Public Key (JWK)</div>
                        <div class="hint" style="margin-top:0; margin-bottom:8px;">
                            Copy this JSON Web Key and paste it into the VA Lighthouse sandbox registration form.
                        </div>
                        <div class="jwk-box" id="jwkContent"><asp:Literal ID="LitJwkContent" runat="server" /></div>
                        <div class="btnbar">
                            <button type="button" class="btn" onclick="copyJwk()">&#x1F4CB; Copy JWK to Clipboard</button>
                            <a href="https://developer.va.gov" target="_blank" class="btn fhir" style="text-decoration:none;">
                                &#x2197; Open VA Developer Portal
                            </a>
                        </div>
                    </div>
                </div>

                <!-- REGISTRATION GUIDE -->
                <div class="panel">
                    <div class="panel-title"><span class="icon">&#x1F4D6;</span> VA Sandbox Registration Steps</div>
                    <table class="grid">
                        <thead>
                            <tr>
                                <th style="width:40px;">#</th>
                                <th>Step</th>
                                <th>Details</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td><strong>1</strong></td>
                                <td><strong>Generate RSA Keys</strong></td>
                                <td>Click "Generate RSA Key Pair" above. This creates <code>private.pem</code>, <code>public.pem</code>, and <code>public.jwk</code> in <code>config/fhir/</code>.</td>
                            </tr>
                            <tr>
                                <td><strong>2</strong></td>
                                <td><strong>Copy JWK</strong></td>
                                <td>Copy the JWK JSON from the preview box above.</td>
                            </tr>
                            <tr>
                                <td><strong>3</strong></td>
                                <td><strong>Register at VA</strong></td>
                                <td>Go to <a href="https://developer.va.gov" target="_blank">developer.va.gov</a>, sign up, and request sandbox access for the FHIR API. Paste your JWK when prompted.</td>
                            </tr>
                            <tr>
                                <td><strong>4</strong></td>
                                <td><strong>Configure Client ID</strong></td>
                                <td>After approval, VA will provide a Client ID. Enter it in the Configuration tab.</td>
                            </tr>
                            <tr>
                                <td><strong>5</strong></td>
                                <td><strong>Test Connection</strong></td>
                                <td>Use the "Test Connection" button to verify connectivity with the sandbox <code>/metadata</code> endpoint.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- =============================================== -->
            <!-- TAB 2: CONFIGURATION                           -->
            <!-- =============================================== -->
            <div class="tab-content" id="tab-config" role="tabpanel" aria-labelledby="btn-tab-config">
                <div class="row">
                    <div class="panel">
                        <div class="panel-title"><span class="icon">&#x2699;</span> FHIR Endpoint Configuration</div>

                        <div class="field-group">
                            <div class="field-label">FHIR Base URL</div>
                            <asp:TextBox ID="TxtFhirBase" runat="server" CssClass="field"
                                placeholder="https://sandbox-api.va.gov/services/fhir/v0/r4" />
                        </div>

                        <div class="field-group">
                            <div class="field-label">OAuth Token URL</div>
                            <asp:TextBox ID="TxtTokenUrl" runat="server" CssClass="field"
                                placeholder="https://sandbox-api.va.gov/oauth2/token" />
                        </div>

                        <div class="field-group">
                            <div class="field-label">Client ID (from VA registration)</div>
                            <asp:TextBox ID="TxtClientId" runat="server" CssClass="field"
                                placeholder="Enter the Client ID assigned by VA Lighthouse" />
                        </div>

                        <div class="field-group">
                            <div class="field-label">Mode</div>
                            <div class="mode-toggle">
                                <asp:RadioButton ID="RdoSandbox" runat="server" GroupName="mode" Text="" />
                                <label for="<%= RdoSandbox.ClientID %>">&#x1F3D6; Sandbox</label>
                                <asp:RadioButton ID="RdoProduction" runat="server" GroupName="mode" Text="" />
                                <label for="<%= RdoProduction.ClientID %>">&#x1F3E2; Production</label>
                            </div>
                        </div>

                        <div class="btnbar">
                            <asp:Button ID="BtnSaveConfig" runat="server" CssClass="btn primary"
                                Text="&#x1F4BE; Save Configuration" OnClick="BtnSaveConfig_Click" />
                            <asp:Button ID="BtnTestConnection" runat="server" CssClass="btn good"
                                Text="&#x1F50D; Test Connection" OnClick="BtnTestConnection_Click" />
                        </div>
                    </div>

                    <div class="panel">
                        <div class="panel-title"><span class="icon">&#x1F4CA;</span> Connection Status</div>
                        <div class="field-group">
                            <div class="field-label">Last Test</div>
                            <div><asp:Literal ID="LitLastTest" runat="server" /></div>
                        </div>
                        <div class="field-group">
                            <div class="field-label">Capability Statement</div>
                            <textarea id="taCapability" class="ta" readonly="readonly" style="min-height:300px;"><asp:Literal ID="LitCapability" runat="server" /></textarea>
                        </div>
                    </div>
                </div>
            </div>

            <!-- =============================================== -->
            <!-- TAB 3: ASSET MAPPER                            -->
            <!-- =============================================== -->
            <div class="tab-content" id="tab-mapper" role="tabpanel" aria-labelledby="btn-tab-mapper">
                <div class="panel">
                    <div class="panel-title"><span class="icon">&#x1F504;</span> Select Assets to Map as FHIR Resources</div>

                    <div style="display:flex; gap:12px; align-items:center; flex-wrap:wrap; margin-bottom:12px;">
                        <asp:DropDownList ID="DdlCompany" runat="server" CssClass="company-select" />
                        <asp:Button ID="BtnLoadAssets" runat="server" CssClass="btn primary"
                            Text="&#x1F50D; Load Assets" OnClick="BtnLoadAssets_Click" />
                        <span class="tag"><b>FHIR Mapping:</b> Device + Location</span>
                    </div>

                    <asp:Literal ID="LitAssetGrid" runat="server" />

                    <div class="hint">
                        <strong>FHIR Resource Mapping:</strong> Each selected asset becomes a <code>Device</code> resource.
                        Unique locations are extracted and become <code>Location</code> resources. All are bundled into
                        a FHIR <code>Bundle</code> (type: transaction).
                    </div>
                </div>

                <div class="row">
                    <div class="panel">
                        <div class="panel-title"><span class="icon">&#x1F441;</span> FHIR Bundle Preview</div>
                        <div class="btnbar" style="margin-top:0; margin-bottom:10px;">
                            <button type="button" class="btn fhir" onclick="generatePreview()">&#x1F504; Generate FHIR Preview</button>
                            <button type="button" class="btn" onclick="copyFhirJson()">&#x1F4CB; Copy JSON</button>
                            <span class="tag" id="previewStats"><b>Resources:</b> <span id="resourceCount">0</span></span>
                        </div>
                        <textarea id="fhirPreview" class="ta mono" readonly="readonly"
                            style="min-height:400px; color:var(--preview-text); background:var(--preview-bg);"
                            placeholder="Click 'Generate FHIR Preview' to build the FHIR Bundle JSON from selected assets..."></textarea>
                    </div>

                    <div class="panel" style="max-width:400px;">
                        <div class="panel-title"><span class="icon">&#x1F4E6;</span> Push to VistA</div>
                        <div class="hint" style="margin-top:0;">
                            Generates the FHIR Bundle JSON and prepares it for submission to the configured endpoint.
                            In sandbox mode, this validates the payload against the FHIR R4 schema.
                        </div>

                        <div class="kpi-bar" style="margin-top:12px;">
                            <div class="kpi">
                                <div class="n" id="kSelectedAssets">0</div>
                                <div class="l">Selected Assets</div>
                            </div>
                            <div class="kpi">
                                <div class="n" id="kLocations">0</div>
                                <div class="l">Unique Locations</div>
                            </div>
                        </div>

                        <!-- Hidden fields for postback -->
                        <asp:HiddenField ID="HidSelectedIds" runat="server" />
                        <asp:HiddenField ID="HidFhirJson" runat="server" />

                        <div class="btnbar">
                            <asp:Button ID="BtnGenerateBundle" runat="server" CssClass="btn fhir"
                                Text="&#x1F4E6; Generate FHIR Bundle" OnClick="BtnGenerateBundle_Click"
                                OnClientClick="return prepareSelectedIds();" />
                            <asp:Button ID="BtnDownloadBundle" runat="server" CssClass="btn"
                                Text="&#x2B07; Download JSON" OnClick="BtnDownloadBundle_Click"
                                OnClientClick="return prepareSelectedIds();" />
                        </div>

                        <hr style="border:none; border-top:1px solid var(--line); margin:16px 0;" />

                        <div class="panel-title" style="font-size:14px; margin-bottom:8px;">
                            <span class="icon">&#x1F680;</span> Push to VA Lighthouse
                        </div>
                        <div class="hint" style="margin-top:0; margin-bottom:10px;">
                            Authenticates via OAuth 2.0 CCG (JWT signed with your RSA private key),
                            acquires a bearer token, and POSTs the FHIR Bundle to the configured endpoint.
                        </div>
                        <div class="btnbar" style="margin-top:0;">
                            <asp:Button ID="BtnPushToVista" runat="server" CssClass="btn"
                                Text="&#x1F680; Push Bundle to VistA" OnClick="BtnPushToVista_Click"
                                OnClientClick="return prepareSelectedIds();"
                                style="background:linear-gradient(135deg, #e87722, #c75b10); font-weight:700;" />
                        </div>

                        <div id="pushResultArea" style="margin-top:12px;">
                            <asp:Literal ID="LitPushResult" runat="server" />
                        </div>

                        <div class="hint" style="margin-top:12px; padding:10px; background:var(--chip); border:1px solid var(--line); border-radius:8px;">
                            <strong>&#x2139; Flow:</strong> Select assets &rarr; Generate FHIR Bundle &rarr; Push to VistA.
                            The transaction log below records every push attempt with status and timestamp.
                        </div>
                    </div>
                </div>
            </div>

            <!-- =============================================== -->
            <!-- TAB 4: TRANSACTION LOG                         -->
            <!-- =============================================== -->
            <div class="tab-content" id="tab-log" role="tabpanel" aria-labelledby="btn-tab-log">
                <div class="panel">
                    <div class="panel-title"><span class="icon">&#x1F4CB;</span> Transaction Log</div>
                    <div class="btnbar" style="margin-top:0; margin-bottom:10px;">
                        <asp:Button ID="BtnRefreshLog" runat="server" CssClass="btn primary"
                            Text="&#x1F504; Refresh Log" OnClick="BtnRefreshLog_Click" />
                        <asp:Button ID="BtnClearLog" runat="server" CssClass="btn bad"
                            Text="&#x1F5D1; Clear Log" OnClick="BtnClearLog_Click"
                            OnClientClick="return confirm('Clear all FHIR transaction logs?');" />
                    </div>
                    <div class="log-box" id="logBox">
                        <asp:Literal ID="LitLog" runat="server" />
                    </div>
                </div>
            </div>

            <footer class="page-footer">
                <div style="display:flex; align-items:center; gap:8px;">
                    <img src="<%= ResolveUrl("~/Assets/branding/assetworx.jpg") %>" alt="AssetWorx" style="height:16px;" />
                    <span style="font-weight:600; font-size:14px; color:var(--text);">AssetWorx<span style="color:#2ea8ff;">!</span></span>
                    <span style="color:var(--muted); font-size:11px;">by InfinID Technologies</span>
                </div>
                <div style="display:flex; align-items:center; gap:12px;">
                    <span>&copy; 2026 ID Integration Inc. &mdash; iDash</span>
                    <img src="/idash/assets/branding/idintegration.jpg" alt="ID Integration Inc." style="height:14px; opacity:0.9;" />
                </div>
            </footer>
        </div>
        </main>

        <!-- =================================================== -->
        <!-- CLIENT-SIDE JAVASCRIPT                              -->
        <!-- =================================================== -->
        <script>
            // --- THEME TOGGLE ---
            function setTheme(theme) {
                document.documentElement.setAttribute('data-theme', theme);
                localStorage.setItem('idash_theme', theme);
                document.getElementById('btnThemeDark').className = (theme === 'dark') ? 'active' : '';
                document.getElementById('btnThemeLight').className = (theme === 'light') ? 'active' : '';
            }
            // Init active state on load
            (function () {
                var t = localStorage.getItem('idash_theme') || 'dark';
                var bd = document.getElementById('btnThemeDark');
                var bl = document.getElementById('btnThemeLight');
                if (bd && bl) {
                    bd.className = (t === 'dark') ? 'active' : '';
                    bl.className = (t === 'light') ? 'active' : '';
                }
            })();

            // --- TAB SWITCHING (Section 508: manages aria-selected) ---
            function switchTab(tabId) {
                // hide all tabs
                var tabs = document.querySelectorAll('.tab-content');
                for (var i = 0; i < tabs.length; i++) {
                    tabs[i].classList.remove('active');
                }
                // deactivate all tab buttons + clear aria-selected
                var btns = document.querySelectorAll('.tab-bar button[role="tab"]');
                for (var i = 0; i < btns.length; i++) {
                    btns[i].classList.remove('active');
                    btns[i].setAttribute('aria-selected', 'false');
                }
                // show selected tab
                var target = document.getElementById('tab-' + tabId);
                if (target) target.classList.add('active');
                // activate button + set aria-selected
                var btn = document.getElementById('btn-tab-' + tabId);
                if (btn) {
                    btn.classList.add('active');
                    btn.setAttribute('aria-selected', 'true');
                }
                // Persist active tab in hidden field so it survives postback
                var hid = document.getElementById('<%= HidActiveTab.ClientID %>');
                if (hid) hid.value = tabId;
            }

            // Restore active tab after postback
            (function () {
                var hid = document.getElementById('<%= HidActiveTab.ClientID %>');
                if (hid && hid.value && hid.value !== 'aems') {
                    switchTab(hid.value);
                }
            })();

            // --- COPY JWK ---
            function copyJwk() {
                var el = document.getElementById('jwkContent');
                if (!el) return;
                var text = el.innerText || el.textContent;
                navigator.clipboard.writeText(text).then(function () {
                    alert('JWK copied to clipboard!');
                });
            }

            // --- COPY FHIR JSON ---
            function copyFhirJson() {
                var ta = document.getElementById('fhirPreview');
                if (!ta || !ta.value) { alert('No FHIR JSON to copy. Generate a preview first.'); return; }
                navigator.clipboard.writeText(ta.value).then(function () {
                    alert('FHIR JSON copied to clipboard!');
                });
            }

            // --- SELECT ALL CHECKBOXES ---
            function toggleSelectAll(src) {
                var checkboxes = document.querySelectorAll('.asset-chk');
                for (var i = 0; i < checkboxes.length; i++) {
                    checkboxes[i].checked = src.checked;
                }
                updateSelectionCount();
            }

            function updateSelectionCount() {
                var checkboxes = document.querySelectorAll('.asset-chk:checked');
                var el = document.getElementById('kSelectedAssets');
                if (el) el.textContent = checkboxes.length;

                // count unique locations
                var locs = {};
                for (var i = 0; i < checkboxes.length; i++) {
                    var loc = checkboxes[i].getAttribute('data-loc');
                    if (loc) locs[loc] = true;
                }
                var locEl = document.getElementById('kLocations');
                if (locEl) locEl.textContent = Object.keys(locs).length;
            }

            // --- PREPARE SELECTED IDS FOR POSTBACK ---
            function prepareSelectedIds() {
                var checkboxes = document.querySelectorAll('.asset-chk:checked');
                var ids = [];
                for (var i = 0; i < checkboxes.length; i++) {
                    ids.push(checkboxes[i].value);
                }
                if (ids.length === 0) {
                    alert('No assets selected. Select at least one asset to generate a FHIR Bundle.');
                    return false;
                }
                document.getElementById('<%= HidSelectedIds.ClientID %>').value = ids.join(',');
                return true;
            }

            // --- GENERATE PREVIEW (CLIENT-SIDE FHIR BUNDLE BUILDER) ---
            function generatePreview() {
                var checkboxes = document.querySelectorAll('.asset-chk:checked');
                if (checkboxes.length === 0) {
                    alert('No assets selected. Check at least one asset row.');
                    return;
                }

                var entries = [];
                var locationSet = {};

                for (var i = 0; i < checkboxes.length; i++) {
                    var cb = checkboxes[i];
                    var device = {
                        resourceType: "Device",
                        id: "assetworx-" + cb.value,
                        identifier: [{
                            system: "urn:oid:2.16.840.1.113883.4.349",
                            value: cb.getAttribute('data-name') || ''
                        }],
                        status: (cb.getAttribute('data-status') || 'active') === 'active' ? 'active' : 'inactive',
                        manufacturer: "AssetWorx",
                        modelNumber: cb.getAttribute('data-model') || '',
                        serialNumber: cb.getAttribute('data-serial') || '',
                        deviceName: [{
                            name: cb.getAttribute('data-desc') || cb.getAttribute('data-name') || '',
                            type: "user-friendly-name"
                        }],
                        location: {
                            reference: "Location/assetworx-loc-" + encodeURIComponent(cb.getAttribute('data-loc') || 'unknown')
                        },
                        meta: {
                            lastUpdated: cb.getAttribute('data-lastinv') || new Date().toISOString(),
                            source: "AssetWorx-iDash"
                        }
                    };

                    // Add RFID identifier if present
                    var rfid = cb.getAttribute('data-rfid');
                    if (rfid) {
                        device.identifier.push({
                            type: { coding: [{ system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: "RFID" }] },
                            value: rfid
                        });
                    }

                    entries.push({
                        fullUrl: "urn:uuid:device-" + cb.value,
                        resource: device,
                        request: {
                            method: "PUT",
                            url: "Device/assetworx-" + cb.value
                        }
                    });

                    // Track unique locations
                    var locCode = cb.getAttribute('data-loc') || '';
                    if (locCode && !locationSet[locCode]) {
                        locationSet[locCode] = {
                            name: cb.getAttribute('data-locname') || locCode,
                            station: cb.getAttribute('data-station') || ''
                        };
                    }
                }

                // Build Location resources
                for (var locKey in locationSet) {
                    var locInfo = locationSet[locKey];
                    var location = {
                        resourceType: "Location",
                        id: "assetworx-loc-" + encodeURIComponent(locKey),
                        identifier: [{
                            system: "urn:oid:2.16.840.1.113883.4.349",
                            value: locKey
                        }],
                        name: locInfo.name,
                        status: "active",
                        mode: "instance",
                        type: [{
                            coding: [{
                                system: "http://terminology.hl7.org/CodeSystem/v3-RoleCode",
                                code: "HOSP",
                                display: "Hospital"
                            }]
                        }],
                        managingOrganization: {
                            display: "VA Station " + locInfo.station
                        },
                        meta: {
                            source: "AssetWorx-iDash"
                        }
                    };

                    entries.unshift({
                        fullUrl: "urn:uuid:location-" + encodeURIComponent(locKey),
                        resource: location,
                        request: {
                            method: "PUT",
                            url: "Location/assetworx-loc-" + encodeURIComponent(locKey)
                        }
                    });
                }

                var bundle = {
                    resourceType: "Bundle",
                    type: "transaction",
                    timestamp: new Date().toISOString(),
                    meta: {
                        source: "AssetWorx-iDash-FHIR-Bridge"
                    },
                    entry: entries
                };

                var json = JSON.stringify(bundle, null, 2);

                document.getElementById('fhirPreview').value = json;
                document.getElementById('resourceCount').textContent = entries.length;
            }

            // Wire checkbox change events (delegated)
            document.addEventListener('change', function (e) {
                if (e.target && e.target.classList.contains('asset-chk')) {
                    updateSelectionCount();
                }
            });
        </script>

        </asp:Panel><!-- /PnlMain -->

    </form>
</body>

</html>
