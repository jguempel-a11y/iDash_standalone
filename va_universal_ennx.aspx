<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_universal_ennx.aspx.cs" Inherits="va_universal_ennx" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <meta name="description" content="Universal ENNX Creator &mdash; high-performance RFID and barcode inventory export builder for Zebra handhelds and web clients." />
    <title>Universal ENNX Creator &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />

    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--bg); color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            font-size: 13px; min-height: 100vh;
        }

        /* SKINNY TOP STATUS BAR (TC530e OPTIMIZED - MATCHING VA_INVENTORY) */
        .status-bar {
            display: flex; justify-content: space-between; align-items: center;
            background: var(--chip); padding: 5px 12px; font-size: 11px; font-weight: 600;
            border-bottom: 1px solid var(--line); position: sticky; top: 0; z-index: 100;
        }
        #connection-indicator {
            display: inline-flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 700; color: var(--accent-2, #10b981);
        }

        /* MAIN CONTAINER */
        .wrap { max-width: 1440px; margin: 6px auto; padding: 0 10px; }

        /* BUTTONS */
        .btn {
            padding: 8px 14px; border-radius: 8px; border: 1px solid var(--line);
            background: var(--chip); color: var(--text); font-size: 12px; font-weight: 700;
            cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            transition: all 0.15s ease; text-decoration: none; user-select: none;
        }
        .btn:hover { background: var(--line); transform: translateY(-1px); }
        .btn-sm { padding: 5px 10px; font-size: 11px; border-radius: 6px; }
        .btn-blue { background: var(--accent, #0284c7); color: #fff; border-color: var(--accent, #0284c7); }
        .btn-blue:hover { filter: brightness(1.1); }
        .btn-green { background: #10b981; color: #fff; border-color: #10b981; }
        .btn-green:hover { filter: brightness(1.1); }
        .btn-red { background: #ef4444; color: #fff; border-color: #ef4444; }
        .btn-red:hover { filter: brightness(1.1); }
        .btn-amber { background: #f59e0b; color: #fff; border-color: #f59e0b; }
        .btn-outline { background: transparent; border: 1px solid var(--line); color: var(--muted); }
        .status-bar .btn-outline { color: var(--muted); border-color: var(--line); background: transparent; }
        .status-bar .btn-outline:hover { background: var(--line); color: var(--text); }
        .btn:disabled { opacity: 0.45; cursor: not-allowed; transform: none; }

        /* CARDS & PANELS */
        .card {
            background: var(--card); border: 1px solid var(--line); border-radius: 12px;
            padding: 16px; margin-bottom: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }
        .card-header {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;
        }
        .card-title {
            font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--accent, #0284c7); display: flex; align-items: center; gap: 8px;
        }

        /* SCANNER CARD */
        .scan-card {
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent, #0284c7), var(--card) 92%) 0%, var(--card) 100%);
            border: 2px solid var(--accent, #0284c7); border-radius: 12px; padding: 12px 16px; margin-bottom: 12px;
            box-shadow: 0 4px 16px color-mix(in srgb, var(--accent, #0284c7), transparent 88%);
        }
        .pulse-dot { width: 9px; height: 9px; border-radius: 50%; background: #10b981; animation: pulse-anim 1.5s infinite; }
        @keyframes pulse-anim { 0% { box-shadow: 0 0 0 0 rgba(16,185,129,0.7); } 70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); } 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); } }
        
        #raw {
            width: 100%; padding: 12px 14px; font-size: 16px; font-weight: 700; font-family: "Consolas", monospace;
            background: var(--bg); color: var(--text); border: 1.5px solid var(--line); border-radius: 8px; outline: none;
        }
        #raw:focus { border-color: var(--accent, #0284c7); }
        #raw.blurred { border-color: #f97316; background: rgba(249,115,22,0.05); }
        
        .status-pill { display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: 11px; font-weight: 700; border: 1px solid; }
        .s-ready    { color: var(--muted); border-color: var(--line); }
        .s-scanning { color: #38bdf8; border-color: #38bdf8; background: rgba(56,189,248,0.12); }
        .s-paused   { color: #f97316; border-color: #f97316; background: rgba(249,115,22,0.12); }

        /* FILTER BAR & SINGLE ROW COUNTS (MATCHING VA_INVENTORY) */
        .filter-bar {
            display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;
            background: var(--card); border: 1px solid var(--line); border-radius: 8px; padding: 8px 12px; margin-bottom: 12px;
        }
        .filter-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .filter-right { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }

        /* STATUS FILTER TABS */
        .status-tabs { display: inline-flex; background: var(--chip); padding: 3px; border-radius: 8px; border: 1px solid var(--line); }
        .status-tab {
            padding: 5px 12px; font-size: 11px; font-weight: 700; border-radius: 6px; cursor: pointer;
            color: var(--muted); border: none; background: transparent; transition: all 0.15s;
        }
        .status-tab:hover { color: var(--text); }
        .status-tab.active { background: var(--card); color: var(--text); box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
        .status-tab .cnt-badge { font-size: 10px; padding: 1px 5px; border-radius: 10px; margin-left: 4px; background: var(--line); color: var(--text); }

        /* TWO-PANEL WORKSPACE */
        .workspace-grid { display: flex; gap: 14px; align-items: stretch; flex-wrap: wrap; }
        .workspace-left { flex: 1.2; min-width: 320px; display: flex; flex-direction: column; gap: 12px; }
        .workspace-right { flex: 0.95; min-width: 300px; display: flex; flex-direction: column; gap: 12px; }

        /* LIVE STREAM TABLE */
        .grid-wrap {
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            overflow-x: auto; overflow-y: auto; -webkit-overflow-scrolling: touch;
            max-height: 48vh; position: relative;
        }
        .grid { width: 100%; border-collapse: collapse; font-size: 12px; }
        .grid th {
            background: var(--chip); text-align: left; padding: 9px 10px; color: var(--muted);
            font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px;
            border-bottom: 2px solid var(--line); position: sticky; top: 0; z-index: 5;
        }
        .grid td { padding: 8px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; }
        .grid tr.row-loc { background: rgba(2,132,199,0.06); border-left: 4px solid #0284c7; }
        .grid tr.row-asset { background: rgba(16,185,129,0.04); border-left: 4px solid #10b981; }
        .grid tr.row-dupe { background: rgba(249,115,22,0.06); border-left: 4px solid #f97316; }
        .grid tr.row-ignored { background: rgba(236,72,153,0.05); border-left: 4px solid #ec4899; }
        
        .badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 999px; font-size: 10px; font-weight: 700; }
        .b-loc { background: rgba(2,132,199,0.15); color: #0284c7; border: 1px solid rgba(2,132,199,0.3); }
        .b-asset { background: rgba(16,185,129,0.15); color: #10b981; border: 1px solid rgba(16,185,129,0.3); }
        .b-dupe { background: rgba(249,115,22,0.15); color: #f97316; border: 1px solid rgba(249,115,22,0.3); }
        .b-unk { background: rgba(236,72,153,0.15); color: #ec4899; border: 1px solid rgba(236,72,153,0.3); }

        /* PREVIEW TEXTAREA */
        .preview-box {
            width: 100%; height: 100%; min-height: 420px; resize: vertical;
            padding: 12px 14px; font-family: "Consolas", monospace; font-size: 13px; font-weight: 600;
            background: var(--bg); color: var(--text); border: 1px solid var(--line); border-radius: 8px;
            outline: none; line-height: 1.5;
        }

        /* MANUAL INPUT & CONTROLS */
        .stream-ctrl-row {
            display: flex; justify-content: flex-start; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 12px;
        }
        .stream-chk-wrap {
            display: flex; align-items: center; gap: 14px; flex-wrap: wrap;
        }
        .manual-input-wrap {
            display: flex; align-items: center; gap: 6px; justify-content: flex-start;
        }
        .txt {
            background: var(--bg); border: 1.5px solid var(--line); color: var(--text);
            padding: 7px 12px; border-radius: 8px; font-size: 13px; font-weight: 600; outline: none; transition: border-color 0.15s;
        }
        .txt:focus { border-color: var(--accent, #0284c7); }
        .manual-input-wrap .txt {
            width: 240px; max-width: 100%; border-radius: 8px;
        }
        .manual-input-wrap .btn {
            border-radius: 8px; padding: 7px 14px; font-size: 12px;
        }

        /* SERVER MESSAGES */
        .msg-ok { background: rgba(16,185,129,0.1); border: 1px solid #10b981; border-left: 4px solid #10b981; color: #10b981; padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-weight: 600; }
        .msg-err { background: rgba(239,68,68,0.1); border: 1px solid #ef4444; border-left: 4px solid #ef4444; color: #ef4444; padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-weight: 600; }

        /* LIGHT MODE HIGH-CONTRAST OVERRIDES */
        [data-theme="light"] .status-bar {
            background: #ffffff;
            border-bottom: 1px solid #cbd5e1;
            color: #0f172a;
        }
        [data-theme="light"] .status-bar .btn-outline {
            color: #1e293b;
            border-color: #cbd5e1;
            background: #f8fafc;
            font-weight: 700;
        }
        [data-theme="light"] .status-bar .btn-outline:hover {
            background: #e2e8f0;
        }

        [data-theme="light"] .grid th { background: #f1f5f9; color: #334155; border-bottom: 2px solid #cbd5e1; }
        [data-theme="light"] .grid td { color: #0f172a; border-bottom: 1px solid #e2e8f0; }
        [data-theme="light"] .grid tr.row-loc { background: #f0f9ff; border-left-color: #0284c7; }
        [data-theme="light"] .grid tr.row-loc td { color: #0369a1; font-weight: 700; }
        [data-theme="light"] .grid tr.row-asset { background: #ecfdf5; border-left-color: #059669; }
        [data-theme="light"] .grid tr.row-asset td { color: #065f46; font-weight: 600; }
        [data-theme="light"] .grid tr.row-dupe { background: #fff7ed; border-left-color: #ea580c; }
        [data-theme="light"] .grid tr.row-dupe td { color: #9a3412; font-weight: 600; }
        [data-theme="light"] .grid tr.row-ignored { background: #fdf2f8; border-left-color: #db2777; }
        [data-theme="light"] .grid tr.row-ignored td { color: #9d174d; font-weight: 600; }

        [data-theme="light"] .b-loc { background: #0284c7; color: #ffffff; border-color: #0284c7; }
        [data-theme="light"] .b-asset { background: #059669; color: #ffffff; border-color: #059669; }
        [data-theme="light"] .b-dupe { background: #ea580c; color: #ffffff; border-color: #ea580c; }
        [data-theme="light"] .b-unk { background: #db2777; color: #ffffff; border-color: #db2777; }

        [data-theme="light"] .preview-box { background: #f8fafc; color: #0f172a; border-color: #cbd5e1; }
        [data-theme="light"] #raw { background: #ffffff; color: #0f172a; border-color: #cbd5e1; }
        [data-theme="light"] .scan-card { background: #f8fafc; border-color: #0284c7; }
        [data-theme="light"] .filter-bar { background: #ffffff; border-color: #cbd5e1; }
        [data-theme="light"] .status-tabs { background: #e2e8f0; border: 1px solid #cbd5e1; }
        [data-theme="light"] .status-tab { color: #334155; font-weight: 800; }
        [data-theme="light"] .status-tab:hover { color: #0f172a; }
        [data-theme="light"] .status-tab.active { background: #ffffff; color: #0f172a; font-weight: 900; box-shadow: 0 1px 4px rgba(0,0,0,0.12); }
        [data-theme="light"] .status-tab .cnt-badge { background: #cbd5e1; color: #0f172a; font-weight: 800; }
        [data-theme="light"] .status-tab.active .cnt-badge { background: #e2e8f0; color: #0f172a; }
        [data-theme="light"] .txt {
            background: #ffffff;
            border-color: #cbd5e1;
            color: #0f172a;
            font-weight: 600;
        }
        [data-theme="light"] .txt:focus {
            border-color: #0284c7;
        }

        /* RESPONSIVE DESIGN (LARGE MONITORS vs MOBILE) */
        @media (min-width: 1200px) {
            .wrap { max-width: 96vw; width: 96%; margin: 10px auto; padding: 0 16px; }
            .grid-wrap { max-height: calc(100vh - 350px); min-height: 480px; }
            .preview-box { min-height: 520px; }
            .status-bar { padding: 6px 18px; font-size: 12px; }
            .status-bar .btn-sm { padding: 4px 10px; font-size: 11px; }
        }

        @media (min-width: 1600px) {
            .wrap { max-width: 95vw; width: 95%; }
            .grid-wrap { max-height: calc(100vh - 330px); min-height: 560px; }
            .preview-box { min-height: 600px; }
        }

        @media (max-width: 768px) {
            .wrap { margin: 4px auto; padding: 0 6px; }
            .workspace-grid { flex-direction: column; }
            .preview-box { min-height: 260px; }
            .grid-wrap { max-height: 42vh; }
        }

        @media (max-width: 680px) {
            .status-bar { padding: 5px 8px; gap: 6px; flex-wrap: nowrap; }
            .app-title { max-width: 130px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px !important; }
            #connection-indicator { display: none; }
            .status-bar-actions { gap: 3px !important; flex-shrink: 0; }
            .status-bar-actions .btn-sm { padding: 3px 6px !important; font-size: 11px !important; }
            .btn-lbl { display: none; /* Icon-only buttons on handhelds prevent wrapping */ }
            .filter-bar { padding: 6px 8px; }
            .status-tabs { overflow-x: auto; -webkit-overflow-scrolling: touch; max-width: 100%; white-space: nowrap; padding: 2px; }
            .status-tab { padding: 5px 8px; font-size: 11px; flex-shrink: 0; }
            .stream-ctrl-row { flex-direction: column; align-items: stretch; gap: 10px; }
            .manual-input-wrap { width: 100%; justify-content: flex-start; }
            .manual-input-wrap .txt { flex: 1; width: auto; max-width: none; border-radius: 8px; }
            .manual-input-wrap .btn { border-radius: 8px; flex-shrink: 0; }
        }
    </style>
</head>
<body onload="initApp();">
<form id="form1" runat="server">

    <!-- RESPONSIVE TOP STATUS BAR -->
    <div class="status-bar">
        <div style="display:flex; align-items:center; gap:8px; min-width:0;">
            <span class="app-title" style="font-weight:800; font-size:12px; letter-spacing:0.3px; white-space:nowrap;">iDash Universal ENNX Creator</span>
            <span id="connection-indicator">&bull; CONNECTED</span>
        </div>
        <div class="status-bar-actions" style="display:flex; align-items:center; gap:6px; flex-shrink:0;">
            <button type="button" class="btn btn-sm btn-outline" id="btnToggleTheme" style="padding:3px 8px; font-size:10px;" onmousedown="event.preventDefault();" onclick="toggleTheme();" title="Toggle Light/Dark Mode">&#9681; <span class="btn-lbl">Theme</span></button>
            <a href="documentation/va_universal_ennx.html" target="_blank" class="btn btn-sm btn-outline" id="btnDocs" style="padding:3px 8px; font-size:10px;" title="Universal ENNX Documentation & Navigation Guide">&#128214; <span class="btn-lbl">Docs</span></a>
            <a href="index.aspx" class="btn btn-sm btn-outline" id="btnHub" style="padding:3px 8px; font-size:10px;" title="Back to Hub">&#8962; <span class="btn-lbl">Hub</span></a>
        </div>
    </div>

    <div class="wrap">
        <asp:Literal ID="LitMsg" runat="server" />

        <!-- 1. HIGH-SPEED SCANNER CARD -->
        <div class="scan-card">
            <div class="card-header" style="margin-bottom:8px;">
                <div class="card-title">
                    <div class="pulse-dot" id="pulseDot"></div>
                    <span>Pull RFID Trigger or Scan Barcode</span>
                    <span class="status-pill s-ready" id="statusPill">&#9711; READY</span>
                </div>
                <div style="display:flex; gap:6px;">
                    <button type="button" class="btn btn-sm btn-outline" onclick="forceNextLocation();">&#8614; Force Location</button>
                    <button type="button" class="btn btn-sm" onclick="focusScan();">&#8635; Focus Trigger</button>
                </div>
            </div>
            <input id="raw" type="text" autocomplete="off" autocorrect="off"
                   spellcheck="false" autocapitalize="off"
                   placeholder="Scan room barcode (SP...) or pull trigger for asset tags..." />
        </div>

        <!-- 2. REVIEW, FILTERS & COUNTS TOOLBAR (SINGLE ROW, MATCHING VA_INVENTORY) -->
        <div class="filter-bar">
            <div class="filter-left">
                <!-- STATUS TABS -->
                <div class="status-tabs" id="statusTabs">
                    <button type="button" class="status-tab active" data-status="All" onclick="filterStream('All');">
                        All <span class="cnt-badge" id="badgeAll">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Location" onclick="filterStream('Location');">
                        Locations <span class="cnt-badge" id="badgeLoc" style="color:#0284c7;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Asset" onclick="filterStream('Asset');">
                        Assets <span class="cnt-badge" id="badgeAssets" style="color:#10b981;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Duplicate" onclick="filterStream('Duplicate');">
                        Duplicates <span class="cnt-badge" id="badgeDupes" style="color:#f97316;">0</span>
                    </button>
                </div>
                <span style="font-size:11px; font-weight:700; color:var(--muted); margin-left:4px; display:inline-flex; align-items:center; gap:4px;">
                    Total Scans: <strong style="color:var(--accent, #0284c7);" id="kReads">0</strong>
                </span>
                <span style="font-size:11px; font-weight:700; color:var(--muted); margin-left:8px; display:inline-flex; align-items:center; gap:4px;">
                    Active Loc: <strong style="color:var(--text); font-family:Consolas,monospace; font-size:12px;" id="tLoc">(none)</strong>
                </span>
            </div>
            <div class="filter-right">
                <button type="button" class="btn btn-sm btn-outline" onclick="undoLast();" title="Undo last scan">&#8617; Undo</button>
                <button type="button" class="btn btn-sm btn-red" onclick="clearAll();" title="Clear all session scans">&#128465; Clear All</button>
            </div>
        </div>

        <!-- 3. MAIN WORKSPACE: STREAM TABLE vs LIVE PREVIEW -->
        <div class="workspace-grid">
            
            <!-- LEFT PANEL: SCAN STREAM & CONTROLS -->
            <div class="workspace-left">
                <div class="card" style="margin-bottom:0; flex:1; display:flex; flex-direction:column;">
                    <div class="card-header">
                        <div class="card-title">&#128225; Scan Stream &amp; Reconciliation</div>
                    </div>

                    <!-- OPTIONS & MANUAL INPUT ROW -->
                    <div class="stream-ctrl-row">
                        <div class="stream-chk-wrap">
                            <label style="display:flex; align-items:center; gap:6px; font-size:11px; font-weight:700; cursor:pointer;">
                                <input id="chkDedup" type="checkbox" checked="checked" /> De-duplicate Assets
                            </label>
                            <label style="display:flex; align-items:center; gap:6px; font-size:11px; font-weight:700; cursor:pointer;">
                                <input id="chkAutoLoc" type="checkbox" checked="checked" /> Auto-Switch on 'SP'
                            </label>
                        </div>
                        <div class="manual-input-wrap">
                            <input type="text" id="manualInput" class="txt" placeholder="Manual tag or room..." />
                            <button type="button" class="btn btn-sm btn-green" onclick="submitManual();">+ Add</button>
                        </div>
                    </div>

                    <!-- STREAM GRID -->
                    <div class="grid-wrap">
                        <table class="grid" id="tblStream">
                            <thead>
                                <tr>
                                    <th style="width:70px;">Time</th>
                                    <th style="width:90px;">Type</th>
                                    <th>Tag / Barcode</th>
                                    <th style="width:120px;">Location</th>
                                    <th style="width:60px; text-align:center;">Action</th>
                                </tr>
                            </thead>
                            <tbody id="bodyStream">
                                <tr>
                                    <td colspan="5" style="text-align:center; padding:32px 14px; color:var(--muted);">
                                        Scan a location barcode (starts with <strong>SP</strong>) or pull RFID trigger to begin session.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- RIGHT PANEL: LIVE ENNX PREVIEW & EXPORT -->
            <div class="workspace-right">
                <div class="card" style="margin-bottom:0; flex:1; display:flex; flex-direction:column;">
                    <div class="card-header">
                        <div class="card-title">&#128196; Live ENNX File Output</div>
                        <div style="display:flex; gap:6px;">
                            <button type="button" class="btn btn-sm btn-outline" onclick="copyEnnx();">&#128203; Copy</button>
                        </div>
                    </div>

                    <textarea id="ennxPreview" class="preview-box" readonly="readonly"></textarea>

                    <!-- HIDDEN POSTBACK FIELDS -->
                    <asp:HiddenField ID="HidEnnx" runat="server" />
                    <asp:HiddenField ID="HidSummary" runat="server" />
                    <asp:HiddenField ID="HidUser" runat="server" />

                    <!-- EXPORT ACTION BUTTON -->
                    <div style="margin-top:12px;">
                        <asp:Button ID="BtnEmail" runat="server" CssClass="btn btn-green" style="width:100%; padding:10px; font-size:12px; font-weight:700;"
                            Text="&#9993; Email ENNX File" OnClick="BtnEmail_Click"
                            OnClientClick="return preparePost();" />
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- CLIENT SCRIPT: HIGH-PERFORMANCE ENGINE -->
    <script>
    (function () {
        const STORAGE_KEY = 'UniversalEnnx_SessionBlocks_v2';
        const IDLE_MS = 1000;

        let _blocks = [];       // [{ location: string, assets: string[], assetSet: {} }]
        let _stream = [];       // [{ time, type, val, loc }]
        let _currentLoc = "";
        let _forceLoc = true;
        let _totalAssets = 0;
        let _totalDupes = 0;
        let _totalReads = 0;
        
        let _sessionOpen = false;
        let _sessionTimer = null;
        let _isOnline = navigator.onLine;

        // DOM References
        const rawInput    = document.getElementById("raw");
        const manualInput = document.getElementById("manualInput");
        const ennxPreview = document.getElementById("ennxPreview");
        const chkDedup    = document.getElementById("chkDedup");
        const chkAutoLoc  = document.getElementById("chkAutoLoc");
        const bodyStream  = document.getElementById("bodyStream");

        // --- SESSION PERSISTENCE ---
        function saveSession() {
            try {
                const payload = {
                    blocks: _blocks.map(b => ({ location: b.location, assets: b.assets.slice(0) })),
                    stream: _stream.slice(0, 50),
                    currentLoc: _currentLoc,
                    totalAssets: _totalAssets,
                    totalDupes: _totalDupes,
                    totalReads: _totalReads
                };
                localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
            } catch (e) {}
        }

        function restoreSession() {
            try {
                const raw = localStorage.getItem(STORAGE_KEY);
                if (!raw) return;
                const d = JSON.parse(raw);
                if (d && d.blocks && d.blocks.length > 0) {
                    _blocks = d.blocks;
                    _blocks.forEach(b => {
                        b.assetSet = {};
                        b.assets.forEach(a => b.assetSet[a] = true);
                    });
                    _stream = d.stream || [];
                    _currentLoc = d.currentLoc || _blocks[_blocks.length - 1].location;
                    _totalAssets = d.totalAssets || 0;
                    _totalDupes = d.totalDupes || 0;
                    _totalReads = d.totalReads || 0;
                    _forceLoc = !_currentLoc;

                    renderStreamTable();
                    refreshUI();
                }
            } catch (e) {}
        }

        // --- STRING NORMALIZATION ---
        function cleanStr(s) { return (s || "").trim().replace(/\s+/g, " "); }
        function upperStr(s) { return cleanStr(s).toUpperCase(); }
        function escHtml(s)  {
            return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
        }
        function getTimeStr() {
            return new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
        }

        function isLocationBarcode(s) {
            const u = upperStr(s);
            return u.startsWith("SP") && !u.includes("EE");
        }

        function normalizeAssetTag(raw) {
            const s = upperStr(raw).replace(/F+$/, "");
            if (/^[0-9A-F]{12,}$/.test(s)) return null; // Ignore raw hex EPCs

            let m;
            m = s.match(/^(\d{3})\s*EE\s*(\w+)$/i); if (m) return m[1] + " EE" + m[2].toUpperCase();
            m = s.match(/^EE\s*(\w+)$/i);           if (m) return "EE" + m[1].toUpperCase();
            m = s.match(/^(\d{3})EE(\w+)$/i);       if (m) return m[1] + " EE" + m[2].toUpperCase();
            return s.length >= 2 ? s : null;
        }

        // --- ENNX BUILDER ---
        function generateEnnxText() {
            const lines = ["ENNX", "ID"];
            _blocks.forEach(b => {
                lines.push(b.location);
                b.assets.forEach(a => lines.push(a));
            });
            lines.push("***END***^" + (lines.length - 2));
            return lines.join("\r\n");
        }

        // --- REFRESH METRICS & PREVIEW ---
        function refreshUI() {
            const bAll = document.getElementById("badgeAll");
            const bLoc = document.getElementById("badgeLoc");
            const bAssets = document.getElementById("badgeAssets");
            const bDupes = document.getElementById("badgeDupes");
            const kReads = document.getElementById("kReads");
            const tLoc = document.getElementById("tLoc");

            if (bAll) bAll.textContent = _stream.length;
            if (bLoc) bLoc.textContent = _blocks.length;
            if (bAssets) bAssets.textContent = _totalAssets;
            if (bDupes) bDupes.textContent = _totalDupes;
            if (kReads) kReads.textContent = _totalReads;
            if (tLoc) tLoc.textContent = _currentLoc || "(none)";

            ennxPreview.value = generateEnnxText();
        }

        // --- FILTERING ---
        let _currentFilter = 'All';

        window.filterStream = function(status) {
            _currentFilter = status;
            document.querySelectorAll('#statusTabs .status-tab').forEach(tab => {
                tab.classList.toggle('active', tab.getAttribute('data-status') === status);
            });
            renderStreamTable();
            focusScan();
        };

        // --- SCAN PROCESSING ENGINE (30-50 TAGS/SEC) ---
        function processIncomingTag(rawVal) {
            const s = cleanStr(rawVal);
            if (!s) return;

            _totalReads++;

            // Manage trigger session state
            if (!_sessionOpen) {
                _sessionOpen = true;
                setStatus('scanning');
            }
            clearTimeout(_sessionTimer);
            _sessionTimer = setTimeout(closeTriggerSession, IDLE_MS);

            // Determine if location or asset
            if (_forceLoc || (chkAutoLoc.checked && isLocationBarcode(s))) {
                handleLocationScan(s);
            } else {
                handleAssetScan(s);
            }
        }

        function handleLocationScan(raw) {
            const loc = upperStr(raw).replace(/F+$/, "");
            if (loc.includes("EE")) {
                addStreamEntry("Ignored", raw, _currentLoc, "Location cannot contain 'EE'");
                return;
            }
            _currentLoc = loc;
            _forceLoc = false;

            // Check if already last block, if not append
            const cur = _blocks.length ? _blocks[_blocks.length - 1] : null;
            if (!cur || cur.location !== loc) {
                _blocks.push({ location: loc, assets: [], assetSet: {} });
            }

            addStreamEntry("Location", loc, loc, "New room block active");
            saveSession();
            refreshUI();
        }

        function handleAssetScan(raw) {
            if (!_currentLoc) {
                _forceLoc = true;
                addStreamEntry("Ignored", raw, "(none)", "Scan room location first");
                refreshUI();
                return;
            }

            const tag = normalizeAssetTag(raw);
            if (!tag) {
                addStreamEntry("Ignored", raw, _currentLoc, "Invalid format or pure EPC");
                return;
            }

            const curBlock = _blocks[_blocks.length - 1];
            if (chkDedup.checked && curBlock.assetSet[tag]) {
                _totalDupes++;
                addStreamEntry("Duplicate", tag, _currentLoc, "Already in room");
                refreshUI();
                return;
            }

            curBlock.assets.push(tag);
            curBlock.assetSet[tag] = true;
            _totalAssets++;

            addStreamEntry("Asset", tag, _currentLoc, "Added to room");
            saveSession();
            refreshUI();
        }

        function closeTriggerSession() {
            _sessionOpen = false;
            setStatus('ready');
            refreshUI();
            saveSession();
        }

        function setStatus(s) {
            const pill = document.getElementById("statusPill");
            const dot = document.getElementById("pulseDot");
            if (s === 'scanning') {
                pill.className = 'status-pill s-scanning'; pill.innerHTML = '&#9654; SCANNING';
                dot.style.background = '#38bdf8';
            } else {
                pill.className = 'status-pill s-ready'; pill.innerHTML = '&#9711; READY';
                dot.style.background = '#10b981';
            }
        }

        // --- STREAM TABLE RENDERING ---
        function addStreamEntry(type, val, loc, note) {
            const entry = { id: Date.now() + Math.random(), time: getTimeStr(), type, val, loc, note };
            _stream.unshift(entry);
            if (_stream.length > 50) _stream.pop();

            if (_currentFilter === 'All' || _currentFilter === type) {
                renderStreamTable();
            }
        }

        function renderStreamTable() {
            const tbody = document.getElementById("bodyStream");
            let filtered = _stream;
            if (_currentFilter !== 'All') {
                filtered = _stream.filter(x => x.type === _currentFilter);
            }
            if (!filtered.length) {
                const msg = _stream.length 
                    ? `No scans matching filter '<b>${escHtml(_currentFilter)}</b>'.`
                    : `Scan a location barcode (starts with <strong>SP</strong>) or pull RFID trigger to begin session.`;
                tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:24px 14px; color:var(--muted);">${msg}</td></tr>`;
                return;
            }
            tbody.innerHTML = "";
            filtered.forEach(entry => {
                let rowCls = "row-asset";
                let badgeCls = "b-asset";
                if (entry.type === "Location") { rowCls = "row-loc"; badgeCls = "b-loc"; }
                else if (entry.type === "Duplicate") { rowCls = "row-dupe"; badgeCls = "b-dupe"; }
                else if (entry.type === "Ignored") { rowCls = "row-ignored"; badgeCls = "b-unk"; }

                const tr = document.createElement("tr");
                tr.className = rowCls;
                tr.innerHTML = `
                    <td style="font-family:Consolas,monospace; color:var(--muted);">${escHtml(entry.time)}</td>
                    <td><span class="badge ${badgeCls}">${escHtml(entry.type)}</span></td>
                    <td style="font-weight:700; font-family:Consolas,monospace;">${escHtml(entry.val)}</td>
                    <td style="color:var(--muted);">${escHtml(entry.loc || '--')}</td>
                    <td style="text-align:center;"><button type="button" class="btn btn-sm btn-red" onclick="window.removeStreamItem('${entry.id}', '${escHtml(entry.type)}', '${escHtml(entry.val)}', '${escHtml(entry.loc)}');" style="padding:2px 6px; font-size:10px;">X</button></td>
                `;
                tbody.appendChild(tr);
            });
        }

        // --- PUBLIC ACTIONS ---
        window.forceNextLocation = function () {
            _forceLoc = true;
            rawInput.placeholder = "Next scan will be set as ROOM LOCATION...";
            focusScan();
        };

        window.undoLast = function () {
            if (!_blocks.length) return;
            const cur = _blocks[_blocks.length - 1];
            if (cur.assets.length) {
                const popped = cur.assets.pop();
                delete cur.assetSet[popped];
                _totalAssets = Math.max(0, _totalAssets - 1);
            } else {
                _blocks.pop();
                _currentLoc = _blocks.length ? _blocks[_blocks.length - 1].location : "";
                _forceLoc = !_currentLoc;
            }
            saveSession();
            refreshUI();
            focusScan();
        };

        window.removeStreamItem = function (id, type, val, loc) {
            _stream = _stream.filter(x => String(x.id) !== String(id));
            if (type === "Asset") {
                _blocks.forEach(b => {
                    if (b.location === loc) {
                        const idx = b.assets.indexOf(val);
                        if (idx > -1) {
                            b.assets.splice(idx, 1);
                            delete b.assetSet[val];
                            _totalAssets = Math.max(0, _totalAssets - 1);
                        }
                    }
                });
            } else if (type === "Location") {
                _blocks = _blocks.filter(b => b.location !== val);
                if (_currentLoc === val) {
                    _currentLoc = _blocks.length ? _blocks[_blocks.length - 1].location : "";
                    _forceLoc = !_currentLoc;
                }
            }
            renderStreamTable();
            saveSession();
            refreshUI();
            focusScan();
        };

        window.clearAll = function () {
            if (!confirm("Clear active session and reset all ENNX data?")) return;
            _blocks = []; _stream = []; _currentLoc = ""; _forceLoc = true;
            _totalAssets = 0; _totalDupes = 0; _totalReads = 0;
            try { localStorage.removeItem(STORAGE_KEY); } catch (e) {}
            renderStreamTable();
            refreshUI();
            focusScan();
        };

        window.submitManual = function () {
            const v = manualInput.value;
            manualInput.value = "";
            processIncomingTag(v);
            focusScan();
        };

        window.copyEnnx = function () {
            const txt = ennxPreview.value;
            if (!txt) return;
            navigator.clipboard.writeText(txt).then(() => {
                alert("ENNX text copied to clipboard!");
            }).catch(() => {
                ennxPreview.select();
                document.execCommand("copy");
                alert("ENNX text copied to clipboard!");
            });
        };

        // --- SCAN INPUT KEY LISTENERS ---
        function focusScan() {
            try { rawInput.focus(); } catch(e){}
        }

        rawInput.addEventListener("keydown", function(ev) {
            if (ev.key === "Enter") {
                ev.preventDefault();
                const val = rawInput.value;
                rawInput.value = "";
                processIncomingTag(val);
            }
        });
        rawInput.addEventListener("focus", function() { rawInput.classList.remove("blurred"); });
        rawInput.addEventListener("blur", function() { rawInput.classList.add("blurred"); });

        manualInput.addEventListener("keydown", function(ev) {
            if (ev.key === "Enter") {
                ev.preventDefault();
                window.submitManual();
            }
        });

        // Click outside re-focuses scanner
        document.addEventListener("click", function(ev) {
            if (ev.target && (ev.target.tagName === "INPUT" || ev.target.tagName === "BUTTON" || ev.target.tagName === "TEXTAREA" || ev.target.tagName === "A" || ev.target.tagName === "SUMMARY")) return;
            setTimeout(focusScan, 50);
        });

        // --- EXPORT PREPARATION (EMAIL) ---
        window.preparePost = function() {
            if (!_blocks.length || !_totalAssets) {
                alert("Scan at least one room location and equipment asset first.");
                return false;
            }

            const ennxText = generateEnnxText();

            // Email submission (requires online connectivity)
            if (!_isOnline || !navigator.onLine) {
                alert("You are currently offline.\n\nEmail requires an active network connection.");
                return false;
            }

            document.getElementById("<%= HidEnnx.ClientID %>").value = ennxText;
            document.getElementById("<%= HidSummary.ClientID %>").value = "Locations=" + _blocks.length + "; Assets=" + _totalAssets + "; Dupes=" + _totalDupes;
            return true;
        };

        // --- ACTIVE NETWORK PROBE ---
        function probeNetwork() {
            const xhr = new XMLHttpRequest();
            xhr.timeout = 3000;
            xhr.open('HEAD', 'va_universal_ennx.aspx?_t=' + Date.now(), true);
            xhr.onload = function() {
                _isOnline = (xhr.status >= 200 && xhr.status < 400);
                updateConnBadge(_isOnline);
            };
            xhr.onerror = function() { _isOnline = false; updateConnBadge(false); };
            xhr.ontimeout = function() { _isOnline = false; updateConnBadge(false); };
            try { xhr.send(); } catch(e){ _isOnline = false; updateConnBadge(false); }
        }

        function updateConnBadge(online) {
            const ind = document.getElementById("connection-indicator");
            if (!ind) return;
            ind.innerHTML = online ? "&bull; CONNECTED" : "&bull; OFFLINE (Direct Download Ready)";
            ind.style.color = online ? "var(--accent-2, #10b981)" : "var(--danger, #ef4444)";
        }

        window.addEventListener("online", () => updateConnBadge(true));
        window.addEventListener("offline", () => updateConnBadge(false));
        setInterval(probeNetwork, 5000);

        // --- THEME TOGGLE ---
        window.toggleTheme = function() {
            var html = document.documentElement;
            var current = html.getAttribute('data-theme');
            if (current === 'light') {
                html.removeAttribute('data-theme');
                localStorage.removeItem('idash_theme');
                localStorage.setItem('aw_theme_preference', 'dark');
            } else {
                html.setAttribute('data-theme', 'light');
                localStorage.setItem('idash_theme', 'light');
                localStorage.setItem('aw_theme_preference', 'light');
            }
            focusScan();
        };

        // --- INIT ---
        window.initApp = function() {
            restoreSession();
            probeNetwork();
            focusScan();
        };

    })();
    </script>
</form>
</body>
</html>

