<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_rfid_locator.aspx.cs" Inherits="va_rfid_locator" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <title>RFID Asset Locator &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <script>
        /* Apply saved theme or default to light BEFORE paint to prevent flash */
        (function() {
            var saved = localStorage.getItem('idash_theme') || localStorage.getItem('aw_theme_preference');
            if (saved === 'dark') {
                document.documentElement.removeAttribute('data-theme');
            } else {
                document.documentElement.setAttribute('data-theme', 'light');
            }
        })();
    </script>
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <style>
        :root {
            --bg: #090d16;
            --card: #0f172a;
            --chip: #1e293b;
            --line: #334155;
            --text: #f8fafc;
            --muted: #94a3b8;
            --accent: #0284c7;
            --accent-2: #10b981;
            --danger: #ef4444;
            --warn: #f59e0b;
        }

        [data-theme="light"] {
            --bg: #f8fafc;
            --card: #ffffff;
            --chip: #f1f5f9;
            --line: #cbd5e1;
            --text: #0f172a;
            --muted: #64748b;
            --accent: #0284c7;
            --accent-2: #059669;
            --danger: #dc2626;
            --warn: #d97706;
        }

        * { box-sizing: border-box; }
        body { margin: 0; background: var(--bg); color: var(--text); font-family: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; }

        /* TOP STATUS BAR */
        .status-bar {
            display: flex; justify-content: space-between; align-items: center;
            background: var(--card); border-bottom: 1px solid var(--line);
            padding: 8px 16px; font-size: 13px; font-weight: 700;
        }
        #connection-indicator { font-size: 11px; font-weight: 800; color: var(--accent-2); display: inline-flex; align-items: center; gap: 4px; }

        .wrap { max-width: 1440px; margin: 8px auto; padding: 0 12px; }

        /* BUTTONS */
        .btn {
            padding: 8px 14px; border-radius: 8px; border: 1px solid var(--line);
            background: var(--chip); color: var(--text); font-size: 12px; font-weight: 700;
            cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            transition: all 0.15s ease; text-decoration: none; user-select: none;
        }
        .btn:hover { background: var(--line); transform: translateY(-1px); }
        .btn-sm { padding: 5px 10px; font-size: 11px; border-radius: 8px; }
        .btn-blue { background: var(--accent); color: #fff; border-color: var(--accent); }
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
            padding: 14px 16px; margin-bottom: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }
        .card-header {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;
        }
        .card-title {
            font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--accent); display: flex; align-items: center; gap: 8px;
        }

        /* HIGH-SPEED SCANNER CARD */
        .scan-card {
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 92%) 0%, var(--card) 100%);
            border: 2px solid var(--accent); border-radius: 12px; padding: 12px 16px; margin-bottom: 12px;
            box-shadow: 0 4px 16px color-mix(in srgb, var(--accent), transparent 88%);
        }
        .pulse-dot { width: 9px; height: 9px; border-radius: 50%; background: #10b981; animation: pulse-anim 1.5s infinite; }
        @keyframes pulse-anim { 0% { box-shadow: 0 0 0 0 rgba(16,185,129,0.7); } 70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); } 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); } }
        
        #raw {
            width: 100%; padding: 12px 14px; font-size: 16px; font-weight: 700; font-family: "Consolas", monospace;
            background: var(--bg); color: var(--text); border: 1.5px solid var(--line); border-radius: 8px; outline: none;
            transition: border-color 0.15s;
        }
        #raw:focus { border-color: var(--accent); }
        #raw.blurred { border-color: #f97316; background: rgba(249,115,22,0.05); }

        .status-pill { display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: 11px; font-weight: 700; border: 1px solid; }
        .s-ready    { color: var(--muted); border-color: var(--line); }
        .s-scanning { color: #38bdf8; border-color: #38bdf8; background: rgba(56,189,248,0.12); }
        .s-found    { color: #10b981; border-color: #10b981; background: rgba(16,185,129,0.12); }

        /* SINGLE-ROW COUNTS & FILTERS TOOLBAR */
        .filter-bar {
            display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;
            background: var(--card); border: 1px solid var(--line); border-radius: 8px; padding: 8px 12px; margin-bottom: 12px;
        }
        .filter-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .filter-right { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }

        .status-tabs { display: inline-flex; background: var(--chip); padding: 3px; border-radius: 8px; border: 1px solid var(--line); }
        .status-tab {
            padding: 5px 12px; font-size: 11px; font-weight: 700; border-radius: 6px; cursor: pointer;
            color: var(--muted); border: none; background: transparent; transition: all 0.15s;
        }
        .status-tab:hover { color: var(--text); }
        .status-tab.active { background: var(--card); color: var(--text); box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
        .status-tab .cnt-badge { font-size: 10px; padding: 1px 5px; border-radius: 10px; margin-left: 4px; background: var(--line); color: var(--text); }

        /* GEIGER PROXIMITY METER */
        .prox-card {
            background: var(--card); border: 1.5px solid var(--line); border-radius: 12px;
            padding: 12px 16px; margin-bottom: 12px; transition: border-color 0.2s;
        }
        .prox-card.active-target {
            border-color: #10b981;
            box-shadow: 0 0 16px rgba(16,185,129,0.15);
        }
        .prox-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
        .prox-title { font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; color: var(--muted); }
        .prox-target-name { font-size: 14px; font-weight: 800; color: var(--accent); }
        .prox-bar-track {
            height: 24px; background: var(--bg); border: 1.5px solid var(--line); border-radius: 8px;
            overflow: hidden; position: relative;
        }
        .prox-bar-fill {
            height: 100%; border-radius: 6px; transition: width 0.25s ease, background 0.25s ease;
            width: 0%; min-width: 0; background: var(--line);
        }
        .prox-meta {
            position: absolute; right: 10px; top: 50%; transform: translateY(-50%);
            font-size: 11px; font-weight: 800; color: var(--text); text-shadow: 0 1px 2px rgba(0,0,0,0.6);
        }

        /* WORKSPACE TWO-PANEL GRID */
        .workspace-grid { display: flex; gap: 14px; align-items: stretch; flex-wrap: wrap; }
        .workspace-left { flex: 0.9; min-width: 310px; display: flex; flex-direction: column; gap: 12px; }
        .workspace-right { flex: 1.3; min-width: 340px; display: flex; flex-direction: column; gap: 12px; }

        /* TARGET ENTRY PANEL */
        .target-box {
            width: 100%; min-height: 120px; resize: vertical; padding: 10px 12px;
            font-family: "Consolas", monospace; font-size: 13px; font-weight: 600;
            background: var(--bg); color: var(--text); border: 1.5px solid var(--line); border-radius: 8px;
            outline: none; transition: border-color 0.15s; line-height: 1.4;
        }
        .target-box:focus { border-color: var(--accent); }
        .target-actions { display: flex; gap: 8px; margin-top: 8px; justify-content: flex-start; }

        .collapsible-header {
            cursor: pointer; display: flex; justify-content: space-between; align-items: center;
            user-select: none;
        }

        /* RESULTS TABLE */
        .grid-wrap {
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            overflow-x: auto; overflow-y: auto; -webkit-overflow-scrolling: touch;
            max-height: 52vh; position: relative;
        }
        .grid { width: 100%; border-collapse: collapse; font-size: 12px; }
        .grid th {
            background: var(--chip); text-align: left; padding: 9px 10px; color: var(--muted);
            font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px;
            border-bottom: 2px solid var(--line); position: sticky; top: 0; z-index: 5;
        }
        .grid td { padding: 8px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; }
        
        .grid tr.row-found { background: rgba(16,185,129,0.06); border-left: 5px solid #10b981; }
        .grid tr.row-searching { background: transparent; border-left: 5px solid var(--line); }
        .grid tr.row-unresolved { background: rgba(239,68,68,0.04); border-left: 5px solid #ef4444; opacity: 0.85; }
        .grid tr.row-flash { background: rgba(16,185,129,0.2) !important; transition: background 0.15s; }

        /* BADGES */
        .badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 999px; font-size: 10px; font-weight: 700; }
        .b-found { background: rgba(16,185,129,0.15); color: #10b981; border: 1px solid rgba(16,185,129,0.3); }
        .b-search { background: rgba(2,132,199,0.15); color: #0284c7; border: 1px solid rgba(2,132,199,0.3); }
        .b-unres { background: rgba(239,68,68,0.15); color: #ef4444; border: 1px solid rgba(239,68,68,0.3); }

        /* LIGHT MODE HIGH-CONTRAST OVERRIDES */
        [data-theme="light"] .status-bar { background: #ffffff; border-bottom: 1px solid #cbd5e1; color: #0f172a; }
        [data-theme="light"] .status-bar .btn-outline { color: #1e293b; border-color: #cbd5e1; background: #f8fafc; font-weight: 700; }
        [data-theme="light"] .status-bar .btn-outline:hover { background: #e2e8f0; }

        [data-theme="light"] #raw { background: #ffffff; color: #0f172a; border-color: #cbd5e1; }
        [data-theme="light"] .scan-card { background: #f8fafc; border-color: #0284c7; }
        [data-theme="light"] .target-box { background: #ffffff; color: #0f172a; border-color: #cbd5e1; }
        [data-theme="light"] .filter-bar { background: #ffffff; border-color: #cbd5e1; }
        [data-theme="light"] .status-tabs { background: #e2e8f0; border: 1px solid #cbd5e1; }
        [data-theme="light"] .status-tab { color: #334155; font-weight: 800; }
        [data-theme="light"] .status-tab:hover { color: #0f172a; }
        [data-theme="light"] .status-tab.active { background: #ffffff; color: #0f172a; font-weight: 900; box-shadow: 0 1px 4px rgba(0,0,0,0.12); }
        [data-theme="light"] .status-tab .cnt-badge { background: #cbd5e1; color: #0f172a; font-weight: 800; }
        [data-theme="light"] .status-tab.active .cnt-badge { background: #e2e8f0; color: #0f172a; }

        [data-theme="light"] .grid th { background: #f1f5f9; color: #334155; border-bottom: 2px solid #cbd5e1; }
        [data-theme="light"] .grid td { color: #0f172a; border-bottom: 1px solid #e2e8f0; }
        [data-theme="light"] .grid tr.row-found { background: #ecfdf5; border-left-color: #059669; }
        [data-theme="light"] .grid tr.row-found td { color: #065f46; font-weight: 600; }
        [data-theme="light"] .grid tr.row-searching td { color: #0f172a; }
        [data-theme="light"] .grid tr.row-unresolved { background: #fef2f2; border-left-color: #dc2626; }
        [data-theme="light"] .grid tr.row-unresolved td { color: #991b1b; }

        [data-theme="light"] .b-found { background: #059669; color: #ffffff; border-color: #059669; }
        [data-theme="light"] .b-search { background: #0284c7; color: #ffffff; border-color: #0284c7; }
        [data-theme="light"] .b-unres { background: #dc2626; color: #ffffff; border-color: #dc2626; }

        [data-theme="light"] .prox-card { background: #ffffff; border-color: #cbd5e1; }
        [data-theme="light"] .prox-bar-track { background: #f1f5f9; border-color: #cbd5e1; }

        /* RESPONSIVE DESIGN (MOBILE & TABLET) */
        @media (max-width: 800px) {
            .wrap { margin: 4px auto; padding: 0 6px; }
            .workspace-grid { flex-direction: column; }
            .workspace-left { flex: none; width: 100%; min-width: 0; }
            .workspace-right { flex: none; width: 100%; min-width: 0; }
            .grid-wrap { max-height: 46vh; }
            .status-bar { padding: 5px 8px; gap: 6px; flex-wrap: nowrap; }
            .app-title { max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px !important; }
            #connection-indicator { display: none; }
            .status-bar-actions { gap: 3px !important; flex-shrink: 0; }
            .status-bar-actions .btn-sm { padding: 3px 6px !important; font-size: 11px !important; }
            .btn-lbl { display: none; }
            .status-tabs { overflow-x: auto; -webkit-overflow-scrolling: touch; max-width: 100%; white-space: nowrap; padding: 2px; }
            .status-tab { padding: 5px 8px; font-size: 11px; flex-shrink: 0; }
        }
    </style>
</head>
<body onload="initApp();">
<form id="form1" runat="server">

    <!-- RESPONSIVE TOP STATUS BAR -->
    <div class="status-bar">
        <div style="display:flex; align-items:center; gap:8px; min-width:0;">
            <span class="app-title" style="font-weight:800; font-size:12px; letter-spacing:0.3px; white-space:nowrap;">iDash RFID Asset Locator</span>
            <span id="connection-indicator">&bull; CONNECTED</span>
        </div>
        <div class="status-bar-actions" style="display:flex; align-items:center; gap:6px; flex-shrink:0;">
            <button type="button" class="btn btn-sm btn-outline" id="btnToggleTheme" style="padding:3px 8px; font-size:10px;" onmousedown="event.preventDefault();" onclick="toggleTheme();" title="Toggle Light/Dark Mode">&#9681; <span class="btn-lbl">Theme</span></button>
            <a href="documentation/va_rfid_locator.html" target="_blank" class="btn btn-sm btn-outline" id="btnDocs" style="padding:3px 8px; font-size:10px;" title="RFID Asset Locator Documentation & Guide">&#128214; <span class="btn-lbl">Docs</span></a>
            <a href="index.aspx" class="btn btn-sm btn-outline" id="btnHub" style="padding:3px 8px; font-size:10px;" title="Back to Hub">&#8962; <span class="btn-lbl">Hub</span></a>
        </div>
    </div>

    <div class="wrap">
        
        <!-- 1. HIGH-SPEED SCANNER CARD -->
        <div class="scan-card">
            <div class="card-header" style="margin-bottom:8px;">
                <div class="card-title">
                    <div class="pulse-dot" id="pulseDot"></div>
                    <span>Pull RFID Trigger or Scan Barcode</span>
                    <span class="status-pill s-ready" id="statusPill">&#9711; READY</span>
                </div>
                <div style="display:flex; gap:6px;">
                    <button type="button" class="btn btn-sm btn-outline" id="btnAudioToggle" onclick="toggleAudio();" title="Toggle Geiger Tone">&#128266; <span class="btn-lbl">Audio ON</span></button>
                    <button type="button" class="btn btn-sm" onclick="focusScan();">&#8635; Focus Trigger</button>
                </div>
            </div>
            <input id="raw" type="text" autocomplete="off" autocorrect="off"
                   spellcheck="false" autocapitalize="off"
                   placeholder="Aim reader at tags or pull RFID trigger to locate assets..." />
        </div>

        <!-- 2. GEIGER PROXIMITY METER -->
        <div class="prox-card" id="proxCard">
            <div class="prox-top">
                <div class="prox-title">&#128225; Proximity Radar &mdash; <span id="proxStatus">No Target Acquired</span></div>
                <div class="prox-target-name" id="proxTarget">&mdash;</div>
            </div>
            <div class="prox-bar-track">
                <div class="prox-bar-fill" id="proxBarFill"></div>
                <div class="prox-meta" id="proxMeta">0 reads/sec &bull; Idle</div>
            </div>
        </div>

        <!-- 3. REVIEW, FILTERS & COUNTS TOOLBAR (SINGLE ROW MATCHING VA_INVENTORY) -->
        <div class="filter-bar">
            <div class="filter-left">
                <!-- STATUS TABS -->
                <div class="status-tabs" id="statusTabs">
                    <button type="button" class="status-tab active" data-status="All" onclick="filterGrid('All');">
                        All Targets <span class="cnt-badge" id="badgeAll">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Found" onclick="filterGrid('Found');">
                        Found <span class="cnt-badge" id="badgeFound" style="color:#10b981;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Remaining" onclick="filterGrid('Remaining');">
                        Remaining <span class="cnt-badge" id="badgeRemaining" style="color:#ef4444;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Unresolved" onclick="filterGrid('Unresolved');">
                        Unresolved <span class="cnt-badge" id="badgeUnresolved" style="color:#f59e0b;">0</span>
                    </button>
                </div>
                <span style="font-size:11px; font-weight:700; color:var(--muted); margin-left:6px; display:inline-flex; align-items:center; gap:4px;">
                    Total Reads: <strong style="color:var(--accent);" id="kReads">0</strong>
                </span>
            </div>
            <div class="filter-right">
                <button type="button" class="btn btn-sm btn-outline" onclick="resetFoundStatus();" title="Reset found status and re-search">&#8634; Reset Found</button>
                <button type="button" class="btn btn-sm btn-red" onclick="clearAll();" title="Clear all targets and start over">&#128465; Clear All</button>
            </div>
        </div>

        <!-- 4. MAIN WORKSPACE: TARGET ENTRY vs LOCATED ASSETS -->
        <div class="workspace-grid">
            
            <!-- LEFT PANEL: TARGET ASSET ENTRY -->
            <div class="workspace-left">
                <div class="card" id="targetCard" style="margin-bottom:0;">
                    <div class="collapsible-header" onclick="toggleTargetDrawer();">
                        <div class="card-title">&#127919; Target Asset List <span id="targetSummaryBadge" style="display:none; font-size:11px; text-transform:none; background:var(--chip); padding:2px 8px; border-radius:10px; color:var(--text); border:1px solid var(--line);">0 loaded</span></div>
                        <span id="drawerArrow" style="font-size:12px; color:var(--muted);">&#9650;</span>
                    </div>
                    <div id="targetDrawerBody" style="margin-top:10px;">
                        <p style="font-size:11px; color:var(--muted); margin:0 0 8px 0;">Enter asset numbers, barcodes, or serial numbers (one per line):</p>
                        <textarea id="targetInput" class="target-box" placeholder="685 EE12345&#10;685 EE12346&#10;685 EE12347&#10;&#10;Or paste from Excel / Clipboard..."></textarea>
                        <div class="target-actions">
                            <button type="button" class="btn btn-sm btn-blue" onclick="loadTargets();">&#128269; Load &amp; Resolve</button>
                            <button type="button" class="btn btn-sm btn-outline" onclick="document.getElementById('targetInput').value=''; focusScan();">&#128465; Clear</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- RIGHT PANEL: TARGET ASSETS & RADAR LIST -->
            <div class="workspace-right">
                <div class="card" style="margin-bottom:0; flex:1; display:flex; flex-direction:column;">
                    <div class="card-header">
                        <div class="card-title">&#128203; Search Targets &amp; Resolution</div>
                        <span style="font-size:11px; font-weight:700; color:var(--muted);" id="subStatus">Load target assets on the left to begin proximity search.</span>
                    </div>

                    <!-- ASSET GRID -->
                    <div class="grid-wrap">
                        <table class="grid" id="tblAssets">
                            <thead>
                                <tr>
                                    <th style="width:40px;">#</th>
                                    <th>Asset Tag</th>
                                    <th>Description / Model</th>
                                    <th>RFID Tag</th>
                                    <th>Location</th>
                                    <th>EIL / CMR</th>
                                    <th style="width:120px; text-align:center;">Status</th>
                                </tr>
                            </thead>
                            <tbody id="bodyAssets">
                                <tr>
                                    <td colspan="7" style="text-align:center; padding:32px 14px; color:var(--muted);">
                                        Enter or paste target asset numbers above, then click <strong>Load &amp; Resolve</strong>.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</form>

<script>
    (function () {
        // ═══════════════════════════════════════════════════════
        //  STATE & INITIALIZATION
        // ═══════════════════════════════════════════════════════
        let _targets = [];             // { input, assetId, name, rfidtag, serial, eil, barcode, location, site, found, foundAt, readCount }
        let _targetLookupMap = {};     // normalizedTag -> index in _targets
        let _targetEENumberMap = {};   // numericEE -> index in _targets
        let _currentFilter = 'All';
        let _totalReads = 0;
        let _audioEnabled = true;
        let _audioCtx = null;
        let _activeTargetRfid = null;
        let _activeTargetIndex = -1;
        let _readTimestamps = [];
        let _lastReadTime = 0;
        let _scanResetTimer = null;

        const rawInput = document.getElementById("raw");
        const statusPill = document.getElementById("statusPill");
        const pulseDot = document.getElementById("pulseDot");
        const proxCard = document.getElementById("proxCard");
        const proxBarFill = document.getElementById("proxBarFill");
        const proxMeta = document.getElementById("proxMeta");
        const proxTarget = document.getElementById("proxTarget");
        const proxStatus = document.getElementById("proxStatus");
        const btnAudio = document.getElementById("btnAudioToggle");

        window.initApp = function () {
            // Restore theme: keep existing light mode or honor saved theme (default to light)
            const savedTheme = localStorage.getItem("idash_theme") || localStorage.getItem("aw_theme_preference");
            if (savedTheme === "dark") {
                document.documentElement.removeAttribute("data-theme");
            } else {
                document.documentElement.setAttribute("data-theme", "light");
            }

            // Restore audio pref
            const savedAudio = localStorage.getItem("aw_locator_audio");
            if (savedAudio !== null) {
                _audioEnabled = (savedAudio === "true");
                updateAudioUI();
            }

            // Check URL parameters for pre-loaded assets
            const params = new URLSearchParams(window.location.search);
            const assetsParam = params.get("assets");
            if (assetsParam) {
                document.getElementById("targetInput").value = assetsParam.split(",").join("\n");
                setTimeout(window.loadTargets, 250);
            }

            // Start proximity decay loop
            setInterval(decayProximityMeter, 300);

            // Periodically refresh relative time stamps
            setInterval(refreshTimeStamps, 5000);

            focusScan();
        };

        window.toggleTheme = function () {
            var html = document.documentElement;
            var isLight = html.getAttribute('data-theme') === 'light';
            if (isLight) {
                html.removeAttribute('data-theme');
                localStorage.setItem('idash_theme', 'dark');
                localStorage.setItem('aw_theme_preference', 'dark');
            } else {
                html.setAttribute('data-theme', 'light');
                localStorage.setItem('idash_theme', 'light');
                localStorage.setItem('aw_theme_preference', 'light');
            }
            focusScan();
        };

        window.toggleAudio = function () {
            _audioEnabled = !_audioEnabled;
            localStorage.setItem("aw_locator_audio", String(_audioEnabled));
            updateAudioUI();
        };

        function updateAudioUI() {
            if (_audioEnabled) {
                btnAudio.innerHTML = '&#128266; <span class="btn-lbl">Audio ON</span>';
                btnAudio.style.borderColor = 'var(--line)';
            } else {
                btnAudio.innerHTML = '&#128263; <span class="btn-lbl">Audio OFF</span>';
                btnAudio.style.borderColor = 'var(--danger)';
            }
        }

        window.focusScan = function () {
            try { rawInput.focus(); } catch (e) {}
        };

        // ═══════════════════════════════════════════════════════
        //  TARGET ASSET RESOLUTION (WEBMETHOD)
        // ═══════════════════════════════════════════════════════
        window.loadTargets = function () {
            const raw = document.getElementById("targetInput").value.trim();
            if (!raw) {
                alert("Please enter or paste at least one target asset identifier.");
                return;
            }

            const lines = raw.split(/[\n\r,\t]+/)
                .map(s => s.trim())
                .filter(s => s.length > 0);

            if (lines.length === 0) return;

            document.getElementById("subStatus").textContent = "Resolving " + lines.length + " target(s) against database...";

            fetch("va_rfid_locator.aspx/LookupAssets", {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=utf-8" },
                body: JSON.stringify({ identifiers: lines })
            })
            .then(r => r.json())
            .then(resp => {
                const data = resp.d || {};
                _targets = (data.assets || []).map((a, idx) => {
                    a.id = idx;
                    a.found = false;
                    a.foundAt = null;
                    a.readCount = 0;
                    return a;
                });

                buildLookupIndexes();
                renderGrid();
                updateToolbars();

                // On mobile, collapse target drawer automatically to grant full height to radar
                if (window.innerWidth <= 800 && _targets.length > 0) {
                    collapseTargetDrawer(true);
                }

                focusScan();
            })
            .catch(err => {
                alert("Error resolving target assets: " + err.message);
                document.getElementById("subStatus").textContent = "Error resolving assets.";
            });
        };

        function buildLookupIndexes() {
            _targetLookupMap = {};
            _targetEENumberMap = {};

            _targets.forEach((t, idx) => {
                if (t.rfidtag) {
                    const norm = normalizeTag(t.rfidtag);
                    if (norm) _targetLookupMap[norm] = idx;
                    const ee = extractEENumber(norm);
                    if (ee) _targetEENumberMap[ee] = idx;
                }
                if (t.input) {
                    const normIn = normalizeTag(t.input);
                    if (normIn) _targetLookupMap[normIn] = idx;
                    const eeIn = extractEENumber(normIn);
                    if (eeIn) _targetEENumberMap[eeIn] = idx;
                }
                if (t.name) {
                    const normNm = normalizeTag(t.name);
                    if (normNm) _targetLookupMap[normNm] = idx;
                    const eeNm = extractEENumber(normNm);
                    if (eeNm) _targetEENumberMap[eeNm] = idx;
                }
                if (t.barcode) {
                    const normBc = normalizeTag(t.barcode);
                    if (normBc) _targetLookupMap[normBc] = idx;
                }
            });
        }

        // ═══════════════════════════════════════════════════════
        //  HIGH-SPEED SCAN INGESTION ENGINE
        // ═══════════════════════════════════════════════════════
        rawInput.addEventListener("keydown", function (e) {
            if (e.key === "Enter" || e.keyCode === 13) {
                e.preventDefault();
                const val = rawInput.value.trim();
                rawInput.value = "";
                if (val) processRead(val);
            }
        });

        rawInput.addEventListener("focus", function () { rawInput.classList.remove("blurred"); });
        rawInput.addEventListener("blur", function () { rawInput.classList.add("blurred"); });

        document.addEventListener("click", function (e) {
            if (e.target && (e.target.tagName === "INPUT" || e.target.tagName === "BUTTON" || e.target.tagName === "TEXTAREA" || e.target.tagName === "A")) return;
            setTimeout(window.focusScan, 50);
        });

        function processRead(rawVal) {
            _totalReads++;
            const now = Date.now();
            _lastReadTime = now;
            _readTimestamps.push(now);
            if (_readTimestamps.length > 40) _readTimestamps.shift();

            // Set scanning status
            setScannerStatus("scanning");
            clearTimeout(_scanResetTimer);
            _scanResetTimer = setTimeout(() => setScannerStatus("ready"), 1200);

            const rawTag = rawVal.trim();
            const normTag = normalizeTag(rawTag);
            const tagEE = extractEENumber(normTag);

            // Check match via $O(1)$ index
            let matchIdx = -1;
            if (_targetLookupMap[normTag] !== undefined) {
                matchIdx = _targetLookupMap[normTag];
            } else if (tagEE && _targetEENumberMap[tagEE] !== undefined) {
                matchIdx = _targetEENumberMap[tagEE];
            } else {
                // Substring fallback
                for (let i = 0; i < _targets.length; i++) {
                    const t = _targets[i];
                    if (!t.rfidtag) continue;
                    const rfid = normalizeTag(t.rfidtag);
                    if (normTag.length > 5 && (rfid.includes(normTag) || normTag.includes(rfid))) {
                        matchIdx = i;
                        break;
                    }
                }
            }

            if (matchIdx >= 0) {
                handleMatchFound(matchIdx, normTag, now);
            } else {
                // Unmatched background read: audio pulse if enabled
                playUnmatchedClick();
            }

            document.getElementById("kReads").textContent = _totalReads;
        }

        function handleMatchFound(idx, tag, now) {
            const target = _targets[idx];
            target.readCount++;
            _activeTargetIndex = idx;
            _activeTargetRfid = tag;

            const isFirstDiscovery = !target.found;
            if (isFirstDiscovery) {
                target.found = true;
                target.foundAt = now;
                setScannerStatus("found");
                playFoundChime();
            }

            // Visual row effects
            flashRow(idx);

            // Update Geiger Proximity radar
            updateProximityRadar(idx, target);

            // Check if all targets are found
            updateToolbars();

            const allResolvedFound = _targets.every(t => t.found || !t.rfidtag);
            if (allResolvedFound && _targets.length > 0 && isFirstDiscovery) {
                playAllFoundFanfare();
            }
        }

        // ═══════════════════════════════════════════════════════
        //  GEIGER RADAR & AUDIO SYNTHESIZER
        // ═══════════════════════════════════════════════════════
        function updateProximityRadar(idx, target) {
            proxCard.classList.add("active-target");
            proxTarget.textContent = (target.name ? target.name + (target.description ? ' - ' + target.description : '') : (target.input || target.rfidtag));
            proxStatus.textContent = "SIGNAL DETECTED!";
            proxStatus.style.color = "#10b981";

            const rps = calculateReadsPerSecond();
            // Scale: 0 to 12 rps -> 0 to 100%
            const pct = Math.min(100, Math.round((rps / 12) * 100));
            proxBarFill.style.width = pct + "%";

            let strengthText = "Moderate Signal";
            if (pct < 30) {
                proxBarFill.style.background = "#ef4444";
                strengthText = "Faint Signal (Far)";
            } else if (pct < 60) {
                proxBarFill.style.background = "#f59e0b";
                strengthText = "Approaching...";
            } else if (pct < 85) {
                proxBarFill.style.background = "#10b981";
                strengthText = "Close! High Signal";
            } else {
                proxBarFill.style.background = "linear-gradient(90deg, #10b981, #0284c7)";
                strengthText = "Target Acquired! Right Here";
            }

            proxMeta.textContent = rps.toFixed(1) + " reads/sec \u2022 " + strengthText;

            // Variable pitch Geiger audio tone
            playGeigerBeep(pct);
        }

        function decayProximityMeter() {
            const now = Date.now();
            if (now - _lastReadTime > 2500) {
                proxCard.classList.remove("active-target");
                proxStatus.textContent = "Searching...";
                proxStatus.style.color = "var(--muted)";
                proxBarFill.style.width = "0%";
                proxBarFill.style.background = "var(--line)";
                proxMeta.textContent = "0.0 reads/sec \u2022 Idle";
            } else {
                // Smooth decay
                const curW = parseFloat(proxBarFill.style.width) || 0;
                if (curW > 0) {
                    proxBarFill.style.width = Math.max(0, curW - 8) + "%";
                }
            }
        }

        function calculateReadsPerSecond() {
            const now = Date.now();
            const recent = _readTimestamps.filter(t => (now - t) < 2500);
            return recent.length / 2.5;
        }

        function getAudioContext() {
            if (!_audioCtx) {
                const AudioClass = window.AudioContext || window.webkitAudioContext;
                if (AudioClass) _audioCtx = new AudioClass();
            }
            if (_audioCtx && _audioCtx.state === "suspended") {
                _audioCtx.resume();
            }
            return _audioCtx;
        }

        function playGeigerBeep(pct) {
            if (!_audioEnabled) return;
            try {
                const ctx = getAudioContext();
                if (!ctx) return;
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.connect(gain);
                gain.connect(ctx.destination);

                // Frequency ramps 320Hz -> 1180Hz as proximity increases
                const freq = 320 + (pct * 8.6);
                const dur = Math.max(30, 140 - pct);

                osc.frequency.value = freq;
                gain.gain.value = 0.12;
                osc.start();
                osc.stop(ctx.currentTime + (dur / 1000));
            } catch (e) {}
        }

        function playUnmatchedClick() {
            if (!_audioEnabled) return;
            try {
                const ctx = getAudioContext();
                if (!ctx) return;
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.frequency.value = 180;
                gain.gain.value = 0.04;
                osc.start();
                osc.stop(ctx.currentTime + 0.03);
            } catch (e) {}
        }

        function playFoundChime() {
            if (!_audioEnabled) return;
            try {
                const ctx = getAudioContext();
                if (!ctx) return;
                const osc1 = ctx.createOscillator();
                const gain1 = ctx.createGain();
                osc1.connect(gain1);
                gain1.connect(ctx.destination);
                osc1.frequency.value = 880; // A5
                gain1.gain.value = 0.25;
                osc1.start();
                osc1.stop(ctx.currentTime + 0.14);

                setTimeout(() => {
                    const osc2 = ctx.createOscillator();
                    const gain2 = ctx.createGain();
                    osc2.connect(gain2);
                    gain2.connect(ctx.destination);
                    osc2.frequency.value = 1174.66; // D6
                    gain2.gain.value = 0.28;
                    osc2.start();
                    osc2.stop(ctx.currentTime + 0.22);
                }, 140);
            } catch (e) {}
        }

        function playAllFoundFanfare() {
            if (!_audioEnabled) return;
            try {
                const ctx = getAudioContext();
                if (!ctx) return;
                const notes = [659.25, 830.61, 987.77, 1318.51];
                notes.forEach((freq, idx) => {
                    setTimeout(() => {
                        const osc = ctx.createOscillator();
                        const gain = ctx.createGain();
                        osc.connect(gain);
                        gain.connect(ctx.destination);
                        osc.frequency.value = freq;
                        gain.gain.value = 0.25;
                        osc.start();
                        osc.stop(ctx.currentTime + 0.2);
                    }, idx * 120);
                });
            } catch (e) {}
        }

        // ═══════════════════════════════════════════════════════
        //  GRID & TOOLBAR RENDERING
        // ═══════════════════════════════════════════════════════
        window.filterGrid = function (status) {
            _currentFilter = status;
            document.querySelectorAll("#statusTabs .status-tab").forEach(tab => {
                tab.classList.toggle("active", tab.getAttribute("data-status") === status);
            });
            renderGrid();
            focusScan();
        };

        function renderGrid() {
            const tbody = document.getElementById("bodyAssets");
            if (!_targets.length) {
                tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:32px 14px; color:var(--muted);">
                    Enter or paste target asset numbers above, then click <strong>Load &amp; Resolve</strong>.
                </td></tr>`;
                return;
            }

            let filtered = _targets;
            if (_currentFilter === "Found") {
                filtered = _targets.filter(t => t.found);
            } else if (_currentFilter === "Remaining") {
                filtered = _targets.filter(t => !t.found && t.rfidtag);
            } else if (_currentFilter === "Unresolved") {
                filtered = _targets.filter(t => !t.rfidtag);
            }

            if (!filtered.length) {
                tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:24px 14px; color:var(--muted);">
                    No target assets matching filter '<b>${escHtml(_currentFilter)}</b>'.
                </td></tr>`;
                return;
            }

            tbody.innerHTML = "";
            filtered.forEach((t, i) => {
                const tr = document.createElement("tr");
                tr.id = "row_" + t.id;

                let rowCls = "row-searching";
                let statusBadge = `<span class="badge b-search">&#9711; SEARCHING</span>`;

                if (t.found) {
                    rowCls = "row-found";
                    const ago = t.foundAt ? timeSince(t.foundAt) : "just now";
                    statusBadge = `<span class="badge b-found">&#10004; FOUND (${ago})</span>`;
                } else if (!t.rfidtag) {
                    rowCls = "row-unresolved";
                    statusBadge = `<span class="badge b-unres">&#9888; NO RFID TAG</span>`;
                }

                tr.className = rowCls;
                tr.innerHTML = `
                    <td style="color:var(--muted);">${i + 1}</td>
                    <td style="font-weight:700; font-family:Consolas,monospace;">${escHtml(t.input || t.name)}</td>
                    <td style="font-weight:600;">${escHtml(t.description || t.name || '--')}</td>
                    <td style="font-family:Consolas,monospace; font-size:11px;">${escHtml(t.rfidtag || '--')}</td>
                    <td style="color:var(--muted);">${escHtml(t.location || '--')}</td>
                    <td style="color:var(--muted);">${escHtml(t.eil || '--')}</td>
                    <td style="text-align:center;">${statusBadge}</td>
                `;
                tbody.appendChild(tr);
            });
        }

        function flashRow(idx) {
            const row = document.getElementById("row_" + idx);
            if (!row) return;
            row.classList.add("row-flash");
            const t = _targets[idx];
            const cells = row.querySelectorAll("td");
            if (cells.length >= 7) {
                cells[6].innerHTML = `<span class="badge b-found">&#10004; FOUND (just now)</span>`;
            }
            setTimeout(() => {
                if (row) row.classList.remove("row-flash");
            }, 600);
        }

        function refreshTimeStamps() {
            _targets.forEach(t => {
                if (t.found && t.foundAt) {
                    const row = document.getElementById("row_" + t.id);
                    if (row) {
                        const cells = row.querySelectorAll("td");
                        if (cells.length >= 7) {
                            cells[6].innerHTML = `<span class="badge b-found">&#10004; FOUND (${timeSince(t.foundAt)})</span>`;
                        }
                    }
                }
            });
        }

        function updateToolbars() {
            const total = _targets.length;
            const found = _targets.filter(t => t.found).length;
            const unres = _targets.filter(t => !t.rfidtag).length;
            const remaining = total - found - unres;

            document.getElementById("badgeAll").textContent = total;
            document.getElementById("badgeFound").textContent = found;
            document.getElementById("badgeRemaining").textContent = Math.max(0, remaining);
            document.getElementById("badgeUnresolved").textContent = unres;

            document.getElementById("targetSummaryBadge").textContent = total + " loaded";
            document.getElementById("targetSummaryBadge").style.display = total > 0 ? "inline-block" : "none";

            document.getElementById("subStatus").textContent = total > 0
                ? `${found} of ${total} targets located (${Math.max(0, remaining)} remaining)`
                : "Load target assets on the left to begin proximity search.";
        }

        window.resetFoundStatus = function () {
            if (!_targets.length) return;
            if (!confirm("Reset found status for all targets and begin a new search sweep?")) return;
            _targets.forEach(t => {
                t.found = false;
                t.foundAt = null;
                t.readCount = 0;
            });
            _totalReads = 0;
            document.getElementById("kReads").textContent = "0";
            renderGrid();
            updateToolbars();
            focusScan();
        };

        window.clearAll = function () {
            if (_targets.length > 0 && !confirm("Clear all targets and start over?")) return;
            _targets = [];
            _targetLookupMap = {};
            _targetEENumberMap = {};
            _totalReads = 0;
            document.getElementById("targetInput").value = "";
            document.getElementById("kReads").textContent = "0";
            collapseTargetDrawer(false);
            renderGrid();
            updateToolbars();
            focusScan();
        };

        window.toggleTargetDrawer = function () {
            const body = document.getElementById("targetDrawerBody");
            const arrow = document.getElementById("drawerArrow");
            const isHidden = body.style.display === "none";
            body.style.display = isHidden ? "block" : "none";
            arrow.innerHTML = isHidden ? "&#9650;" : "&#9660;";
        };

        function collapseTargetDrawer(collapse) {
            const body = document.getElementById("targetDrawerBody");
            const arrow = document.getElementById("drawerArrow");
            body.style.display = collapse ? "none" : "block";
            arrow.innerHTML = collapse ? "&#9660;" : "&#9650;";
        }

        function setScannerStatus(s) {
            if (s === "scanning") {
                statusPill.className = "status-pill s-scanning";
                statusPill.innerHTML = "&#9654; LOCATING...";
                pulseDot.style.background = "#38bdf8";
            } else if (s === "found") {
                statusPill.className = "status-pill s-found";
                statusPill.innerHTML = "&#10004; MATCH FOUND";
                pulseDot.style.background = "#10b981";
            } else {
                statusPill.className = "status-pill s-ready";
                statusPill.innerHTML = "&#9711; READY";
                pulseDot.style.background = "#10b981";
            }
        }

        // ═══════════════════════════════════════════════════════
        //  NORMALIZATION & UTILITY HELPERS
        // ═══════════════════════════════════════════════════════
        function stripFPadding(s) {
            return (s || "").replace(/F+$/i, "");
        }

        function extractEENumber(s) {
            const m = (s || "").match(/EE\s*(\d+)/i);
            return m ? m[1] : null;
        }

        function normalizeTag(s) {
            if (!s) return "";
            return stripFPadding(s.toUpperCase().replace(/\s+/g, "").trim());
        }

        function timeSince(date) {
            const sec = Math.floor((Date.now() - date) / 1000);
            if (sec < 4) return "just now";
            if (sec < 60) return sec + "s ago";
            if (sec < 3600) return Math.floor(sec / 60) + "m ago";
            return Math.floor(sec / 3600) + "h ago";
        }

        function escHtml(s) {
            if (!s) return "";
            return String(s)
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#039;");
        }
    })();
</script>
</body>
</html>
