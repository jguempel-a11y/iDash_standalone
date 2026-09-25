<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_rfid_locator_legacy.aspx.cs" Inherits="va_rfid_locator_legacy" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <title>RFID Asset Locator (Legacy / Archived) &mdash; iDash</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <style>
        body { margin:0; background:var(--bg); color:var(--text); font-family:Segoe UI,system-ui,Arial,sans-serif; }
        .wrap { padding:16px; max-width:1200px; margin:0 auto; }

        /* Header */
        .top { display:flex; gap:12px; align-items:flex-start; justify-content:space-between; flex-wrap:wrap; margin-bottom:16px; }
        .h1 { font-size:22px; font-weight:800; letter-spacing:.2px; }
        .sub { color:var(--muted); font-size:13px; margin-top:2px; }
        .nav-pill { display:inline-flex; align-items:center; gap:4px; padding:6px 14px; border-radius:20px; background:var(--chip); border:1px solid var(--line); color:var(--text); text-decoration:none; font-size:13px; font-weight:600; transition:all .15s; cursor:pointer; }
        .nav-pill:hover { border-color:var(--accent); background:color-mix(in srgb, var(--accent), transparent 90%); }

        /* Panels */
        .panel { background:var(--card); border:1px solid var(--line); border-radius:14px; padding:16px; box-shadow:var(--shadow); margin-bottom:16px; }
        .row2 { display:grid; grid-template-columns:340px 1fr; gap:16px; }
        @media(max-width:768px) { .row2 { grid-template-columns:1fr; } }

        /* KPIs */
        .kpis { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:14px; }
        .kpi { background:var(--chip); border:1px solid var(--line); border-radius:12px; padding:10px 14px; min-width:100px; text-align:center; }
        .kpi .n { font-size:22px; font-weight:800; }
        .kpi .l { font-size:11px; color:var(--muted); margin-top:2px; text-transform:uppercase; letter-spacing:.04em; }

        /* Target Input */
        .target-input { width:100%; min-height:140px; resize:vertical; background:var(--bg); color:var(--text); border:1px solid var(--line); border-radius:10px; padding:10px; font-family:Consolas,monospace; font-size:13px; }
        .target-input:focus { outline:none; border-color:var(--accent); box-shadow:0 0 0 3px color-mix(in srgb, var(--accent), transparent 80%); }

        /* Buttons */
        .btn { display:inline-flex; align-items:center; gap:6px; padding:8px 18px; border-radius:10px; border:1px solid var(--line); background:var(--chip); color:var(--text); font-size:13px; font-weight:700; cursor:pointer; transition:all .15s; }
        .btn:hover { border-color:var(--accent); background:color-mix(in srgb, var(--accent), transparent 88%); }
        .btn-primary { background:var(--accent); color:#fff; border-color:var(--accent); }
        .btn-primary:hover { filter:brightness(1.15); }
        .btn-danger { background:#ef4444; color:#fff; border-color:#ef4444; }
        .btn-danger:hover { filter:brightness(1.15); }
        .btn-success { background:#10b981; color:#fff; border-color:#10b981; }
        .btn-success:hover { filter:brightness(1.15); }
        .btn-sm { padding:5px 12px; font-size:12px; }
        .btn-group { display:flex; gap:8px; flex-wrap:wrap; margin-top:10px; }

        /* LED */
        .led { width:14px; height:14px; border-radius:50%; display:inline-block; vertical-align:middle; transition:background .15s; }
        .led-off { background:#444; box-shadow:0 0 4px rgba(68,68,68,.5); }
        .led-reading { background:#ef4444; box-shadow:0 0 8px rgba(239,68,68,.7); animation:pulse-led .4s infinite; }
        .led-match { background:#10b981; box-shadow:0 0 12px rgba(16,185,129,.8); }
        @keyframes pulse-led { 0%,100%{opacity:1;}50%{opacity:.4;} }

        /* Scan input (hidden but accessible) */
        .scan-capture { position:absolute; left:-9999px; width:1px; height:1px; opacity:0; }

        /* Asset Table */
        .asset-table { width:100%; border-collapse:separate; border-spacing:0; font-size:13px; }
        .asset-table th { background:var(--chip); padding:10px 12px; text-align:left; font-weight:700; font-size:11px; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); border-bottom:2px solid var(--line); position:sticky; top:0; z-index:1; }
        .asset-table td { padding:9px 12px; border-bottom:1px solid var(--line); transition:background .6s ease-out; }
        .asset-table tr:hover td { background:color-mix(in srgb, var(--accent), transparent 92%); }

        /* Found states */
        .row-found-flash { background:#059669 !important; color:#fff; transition:background .1s !important; }
        .row-found { background:color-mix(in srgb, #10b981, transparent 85%); }
        .row-not-resolved { opacity:.5; }

        /* Status badges */
        .badge { display:inline-flex; align-items:center; gap:4px; padding:3px 10px; border-radius:20px; font-size:11px; font-weight:700; letter-spacing:.02em; }
        .badge-searching { background:color-mix(in srgb, var(--accent), transparent 85%); color:var(--accent); }
        .badge-found { background:color-mix(in srgb, #10b981, transparent 80%); color:#10b981; }
        .badge-notfound { background:color-mix(in srgb, #ef4444, transparent 85%); color:#ef4444; }

        /* Proximity Meter */
        .prox-wrap { margin-top:16px; }
        .prox-label { font-size:12px; font-weight:700; color:var(--muted); margin-bottom:6px; text-transform:uppercase; letter-spacing:.04em; }
        .prox-bar-bg { height:28px; background:var(--chip); border:1px solid var(--line); border-radius:8px; overflow:hidden; position:relative; }
        .prox-bar { height:100%; border-radius:7px; transition:width .3s ease, background .3s ease; min-width:0; }
        .prox-text { position:absolute; right:12px; top:50%; transform:translateY(-50%); font-size:12px; font-weight:700; color:var(--text); }

        /* Audio toggle */
        .audio-row { display:flex; align-items:center; gap:10px; margin-top:12px; font-size:13px; }
        .toggle-switch { position:relative; width:40px; height:22px; }
        .toggle-switch input { opacity:0; width:0; height:0; }
        .toggle-slider { position:absolute; cursor:pointer; top:0; left:0; right:0; bottom:0; background:var(--line); border-radius:22px; transition:.3s; }
        .toggle-slider:before { position:absolute; content:""; height:16px; width:16px; left:3px; bottom:3px; background:#fff; border-radius:50%; transition:.3s; }
        .toggle-switch input:checked + .toggle-slider { background:#10b981; }
        .toggle-switch input:checked + .toggle-slider:before { transform:translateX(18px); }

        /* Scan mode banner */
        .scan-banner { display:none; align-items:center; gap:12px; padding:12px 18px; border-radius:12px; background:linear-gradient(135deg, rgba(16,185,129,.1), rgba(46,168,255,.08)); border:2px solid #10b981; margin-bottom:16px; animation:scan-pulse 2s infinite; }
        .scan-banner.active { display:flex; }
        @keyframes scan-pulse { 0%,100%{border-color:#10b981;}50%{border-color:var(--accent);} }
        .scan-banner-text { font-size:15px; font-weight:700; }
        .scan-banner-sub { font-size:12px; color:var(--muted); }

        /* WebSerial */
        .serial-section { margin-top:14px; padding-top:12px; border-top:1px solid var(--line); }
        .serial-status { font-size:12px; color:var(--muted); }
        .serial-connected { color:#10b981; font-weight:700; }

        /* Empty state */
        .empty-state { text-align:center; padding:40px 20px; color:var(--muted); }
        .empty-state .icon { font-size:48px; margin-bottom:12px; }
        .empty-state p { font-size:14px; max-width:400px; margin:0 auto; }

        /* Footer */
        .footer { text-align:center; color:var(--muted); font-size:11px; margin-top:40px; padding:16px; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="wrap">
    <!-- HEADER -->
    <div class="top">
        <div>
            <div class="h1">&#128225; RFID Asset Locator <span style="font-size:12px; color:#ef4444; border:1px solid rgba(239,68,68,0.4); background:rgba(239,68,68,0.12); padding:2px 8px; border-radius:999px; vertical-align:middle; font-weight:700;">Legacy / Archived</span></div>
            <div class="sub">Archived original WebSerial &amp; hidden-focus locator. Preserved for backward reference.</div>
        </div>
        <div style="display:flex; gap:8px; flex-wrap:wrap; align-items:center;">
            <a href="va_rfid_locator.aspx" class="nav-pill" style="background:#10b981; color:#fff; font-weight:700; border-color:#10b981;">&#9654; Switch to Current Version</a>
            <a href="documentation/va_rfid_locator.html" class="nav-pill">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
        </div>
    </div>

    <!-- SCAN MODE BANNER -->
    <div class="scan-banner" id="scanBanner">
        <span class="led led-off" id="mainLed"></span>
        <div>
            <div class="scan-banner-text">&#128225; Scanning Active &mdash; <span id="bannerCount">0</span> of <span id="bannerTotal">0</span> found</div>
            <div class="scan-banner-sub">Point your RFID reader at the area. Matching assets will turn green.</div>
        </div>
        <div style="margin-left:auto;">
            <button type="button" class="btn btn-danger" onclick="stopScanning()">&#9632; Stop</button>
        </div>
    </div>

    <!-- KPIS -->
    <div class="kpis">
        <div class="kpi"><div class="n" id="kTargets">0</div><div class="l">Targets</div></div>
        <div class="kpi"><div class="n" id="kFound" style="color:#10b981;">0</div><div class="l">Found</div></div>
        <div class="kpi"><div class="n" id="kRemaining" style="color:#ef4444;">0</div><div class="l">Remaining</div></div>
        <div class="kpi"><div class="n" id="kReads">0</div><div class="l">Total Reads</div></div>
    </div>

    <!-- MAIN LAYOUT -->
    <div class="row2">
        <!-- LEFT: TARGET INPUT -->
        <div class="panel">
            <div style="font-weight:700; margin-bottom:8px;">Target Assets</div>
            <textarea id="targetInput" class="target-input" placeholder="Enter asset numbers, one per line&#10;e.g.&#10;685 EE12345&#10;685 EE12346&#10;685 EE12347&#10;&#10;Or paste from Excel/CSV"></textarea>
            <div class="btn-group">
                <button type="button" class="btn btn-primary" onclick="loadTargets()">&#128269; Load &amp; Resolve</button>
                <button type="button" class="btn" onclick="document.getElementById('targetInput').value=''; clearAll();">&#128465; Clear</button>
            </div>
            <div style="margin-top:8px;">
                <label style="font-size:12px; color:var(--muted); display:flex; align-items:center; gap:6px; cursor:pointer;">
                    <input type="checkbox" id="chkDebug" onchange="toggleDebug()" /> Show Raw Read Log (debug)
                </label>
            </div>

            <!-- Scan Controls -->
            <div style="margin-top:16px; padding-top:14px; border-top:1px solid var(--line);">
                <div style="font-weight:700; margin-bottom:8px;">Scan Controls</div>
                <button type="button" class="btn btn-success" id="btnStart" onclick="startScanning()" disabled>&#9654; Start Scanning</button>
                <button type="button" class="btn btn-danger" id="btnStop" onclick="stopScanning()" style="display:none;">&#9632; Stop Scanning</button>
            </div>

            <!-- Audio -->
            <div class="audio-row">
                <label class="toggle-switch">
                    <input type="checkbox" id="chkAudio" />
                    <span class="toggle-slider"></span>
                </label>
                <span>&#128266; Audio Feedback</span>
            </div>

            <!-- WebSerial -->
            <div class="serial-section">
                <div style="font-weight:700; margin-bottom:6px; font-size:13px;">WebSerial USB</div>
                <div style="display:flex; gap:8px; align-items:center;">
                    <button type="button" class="btn btn-sm" id="btnSerial" onclick="serialToggle()">&#128268; Connect</button>
                    <span class="serial-status" id="serialStatus">Not connected</span>
                </div>
            </div>
        </div>

        <!-- RIGHT: RESULTS -->
        <div class="panel" style="overflow:auto; max-height:70vh;">
            <div id="emptyState" class="empty-state">
                <div class="icon">&#128225;</div>
                <p>Enter asset numbers on the left and click <strong>Load &amp; Resolve</strong> to fetch RFID tags from the database. Then start scanning to locate assets.</p>
            </div>

            <div id="resultsArea" style="display:none;">
                <table class="asset-table" id="assetGrid">
                    <thead>
                        <tr>
                            <th style="width:40px;">#</th>
                            <th>Asset</th>
                            <th>Description</th>
                            <th>RFID Tag</th>
                            <th>Location</th>
                            <th>EIL/CMR</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="assetBody"></tbody>
                </table>

                <!-- PROXIMITY METER -->
                <div class="prox-wrap" id="proxWrap" style="display:none;">
                    <div class="prox-label">&#128225; Proximity &mdash; <span id="proxAsset">&mdash;</span></div>
                    <div class="prox-bar-bg">
                        <div class="prox-bar" id="proxBar" style="width:0%; background:var(--line);"></div>
                        <span class="prox-text" id="proxText">&mdash;</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- DEBUG RAW READS LOG -->
    <div class="panel" id="debugPanel" style="display:none;">
        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:8px;">
            <div style="font-weight:700; font-size:13px;">&#128203; Raw Read Log <span style="font-weight:400; color:var(--muted); font-size:11px;">(last 20 scans &mdash; shows exactly what the reader output)</span></div>
            <button type="button" class="btn btn-sm" onclick="clearDebugLog()">Clear</button>
        </div>
        <div id="debugLog" style="font-family:Consolas,monospace; font-size:12px; max-height:200px; overflow-y:auto;"></div>
    </div>

    <!-- Hidden scan capture (DataWedge keystroke target) -->
    <textarea id="scanCapture" class="scan-capture"></textarea>

    <div class="footer">AssetWorx! by InfinID Technologies &mdash; iDash RFID Integration by ID Integration Inc. &copy; 2026</div>
</div>
</form>

<script>
(function() {
    // ═══════════════════════════════════════════════════════
    //  STATE
    // ═══════════════════════════════════════════════════════
    var targets = [];       // { input, assetId, name, rfidtag, serial, eil, barcode, location, site, found, foundAt, readCount }
    var scanning = false;
    var totalReads = 0;
    var readCounts = {};    // rfidtag -> reads-per-second tracking
    var readHistory = {};   // rfidtag -> [timestamps]
    var audioCtx = null;
    var serialPort = null;
    var serialReader = null;

    // ═══════════════════════════════════════════════════════
    //  LOAD & RESOLVE TARGETS
    // ═══════════════════════════════════════════════════════
    window.loadTargets = function() {
        var raw = document.getElementById('targetInput').value.trim();
        if (!raw) return;

        // Parse: split by newlines, commas, tabs
        var lines = raw.split(/[\n\r,\t]+/).map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; });
        if (lines.length === 0) return;

        // Call WebMethod
        fetch('va_rfid_locator.aspx/LookupAssets', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identifiers: lines })
        })
        .then(function(r) { return r.json(); })
        .then(function(resp) {
            var data = resp.d || {};
            targets = (data.assets || []).map(function(a) {
                a.found = false;
                a.foundAt = null;
                a.readCount = 0;
                return a;
            });
            renderGrid();
            updateKPIs();
            document.getElementById('emptyState').style.display = 'none';
            document.getElementById('resultsArea').style.display = '';
            document.getElementById('btnStart').disabled = targets.length === 0;
        })
        .catch(function(err) {
            alert('Error resolving assets: ' + err.message);
        });
    };

    // ═══════════════════════════════════════════════════════
    //  RENDER GRID
    // ═══════════════════════════════════════════════════════
    function renderGrid() {
        var tbody = document.getElementById('assetBody');
        var html = '';
        for (var i = 0; i < targets.length; i++) {
            var t = targets[i];
            var resolved = t.rfidtag && t.rfidtag.length > 0;
            var rowClass = '';
            var statusHtml = '';

            if (t.found) {
                var ago = t.foundAt ? timeSince(t.foundAt) : '';
                rowClass = 'row-found';
                statusHtml = '<span class="badge badge-found">&#9989; FOUND' + (ago ? ' (' + ago + ')' : '') + '</span>';
            } else if (!resolved) {
                rowClass = 'row-not-resolved';
                statusHtml = '<span class="badge badge-notfound">&#10060; No RFID tag</span>';
            } else if (scanning) {
                statusHtml = '<span class="badge badge-searching">&#128269; Searching...</span>';
            } else {
                statusHtml = '<span class="badge" style="background:var(--chip);color:var(--muted);">&#8212; Idle</span>';
            }

            html += '<tr id="row_' + i + '" class="' + rowClass + '">'
                + '<td style="color:var(--muted);">' + (i+1) + '</td>'
                + '<td style="font-weight:700;">' + esc(t.input || t.name) + '</td>'
                + '<td>' + esc(t.name || '-') + '</td>'
                + '<td style="font-family:Consolas,monospace;font-size:11px;word-break:break-all;">' + esc(t.rfidtag || '-') + '</td>'
                + '<td>' + esc(t.location || '-') + '</td>'
                + '<td>' + esc(t.eil || '-') + '</td>'
                + '<td>' + statusHtml + '</td>'
                + '</tr>';
        }
        tbody.innerHTML = html;
    }

    function esc(s) {
        var d = document.createElement('div');
        d.textContent = s;
        return d.innerHTML;
    }

    function timeSince(date) {
        var sec = Math.floor((Date.now() - date) / 1000);
        if (sec < 5) return 'just now';
        if (sec < 60) return sec + 's ago';
        if (sec < 3600) return Math.floor(sec/60) + 'm ago';
        return Math.floor(sec/3600) + 'h ago';
    }

    // ═══════════════════════════════════════════════════════
    //  KPI UPDATE
    // ═══════════════════════════════════════════════════════
    function updateKPIs() {
        var total = targets.length;
        var found = targets.filter(function(t){ return t.found; }).length;
        document.getElementById('kTargets').textContent = total;
        document.getElementById('kFound').textContent = found;
        document.getElementById('kRemaining').textContent = total - found;
        document.getElementById('kReads').textContent = totalReads;
        document.getElementById('bannerCount').textContent = found;
        document.getElementById('bannerTotal').textContent = total;
    }

    // ═══════════════════════════════════════════════════════
    //  SCAN START / STOP
    // ═══════════════════════════════════════════════════════
    window.startScanning = function() {
        if (targets.length === 0) return;
        scanning = true;
        totalReads = 0;
        readHistory = {};

        document.getElementById('btnStart').style.display = 'none';
        document.getElementById('btnStop').style.display = '';
        document.getElementById('scanBanner').classList.add('active');
        document.getElementById('proxWrap').style.display = '';

        renderGrid();
        updateKPIs();
        focusScanCapture();

        // Auto-refocus interval
        window._focusInterval = setInterval(function() {
            if (scanning) focusScanCapture();
        }, 500);

        // Proximity decay
        window._proxInterval = setInterval(updateProximity, 300);
    };

    window.stopScanning = function() {
        scanning = false;
        document.getElementById('btnStart').style.display = '';
        document.getElementById('btnStop').style.display = 'none';
        document.getElementById('scanBanner').classList.remove('active');
        document.getElementById('mainLed').className = 'led led-off';

        if (window._focusInterval) clearInterval(window._focusInterval);
        if (window._proxInterval) clearInterval(window._proxInterval);

        renderGrid();
    };

    window.clearAll = function() {
        targets = [];
        totalReads = 0;
        readHistory = {};
        scanning = false;
        document.getElementById('emptyState').style.display = '';
        document.getElementById('resultsArea').style.display = 'none';
        document.getElementById('scanBanner').classList.remove('active');
        document.getElementById('btnStart').style.display = '';
        document.getElementById('btnStart').disabled = true;
        document.getElementById('btnStop').style.display = 'none';
        if (window._focusInterval) clearInterval(window._focusInterval);
        if (window._proxInterval) clearInterval(window._proxInterval);
        updateKPIs();
    };

    // ═══════════════════════════════════════════════════════
    //  SCAN CAPTURE (DataWedge keystroke mode)
    // ═══════════════════════════════════════════════════════
    var scanCapture = document.getElementById('scanCapture');

    scanCapture.addEventListener('keydown', function() {
        document.getElementById('mainLed').className = 'led led-reading';
    });

    scanCapture.addEventListener('keyup', function(e) {
        if (e.key === 'Enter' || e.keyCode === 13) {
            var val = scanCapture.value.trim();
            scanCapture.value = '';
            if (val) processRead(val);
            document.getElementById('mainLed').className = 'led led-match';
            setTimeout(function() {
                if (scanning) document.getElementById('mainLed').className = 'led led-off';
            }, 600);
        }
    });

    function focusScanCapture() {
        scanCapture.focus();
    }

    // ═══════════════════════════════════════════════════════
    //  PROCESS A READ
    // ═══════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════
    //  EE TAG NORMALIZATION HELPERS
    // ═══════════════════════════════════════════════════════

    // Strip trailing F-padding added by AssetWorx encoding (e.g. 512EE17360FF -> 512EE17360)
    function stripFPadding(s) {
        return s.replace(/F+$/i, '');
    }

    // Extract the numeric EE portion from various formats:
    //   "512 EE17360", "512EE17360FFF", "EE17360" -> "17360"
    //   Returns null if not recognizable as an EE number.
    function extractEENumber(s) {
        var m = s.match(/EE\s*(\d+)/i);
        return m ? m[1] : null;
    }

    // Normalize rfidtag from DB or raw scan to a canonical form for comparison.
    // Strips F-padding, uppercases, trims whitespace.
    function normalizeTag(s) {
        if (!s) return '';
        return stripFPadding(s.toUpperCase().trim());
    }

    // ═══════════════════════════════════════════════════════
    //  DEBUG RAW READ LOG
    // ═══════════════════════════════════════════════════════
    var debugLog = [];

    window.toggleDebug = function() {
        var show = document.getElementById('chkDebug').checked;
        document.getElementById('debugPanel').style.display = show ? '' : 'none';
    };

    window.clearDebugLog = function() {
        debugLog = [];
        renderDebugLog();
    };

    function addDebugEntry(raw, normalized, matched) {
        var entry = {
            time: new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit',second:'2-digit'}),
            raw: raw,
            normalized: normalized,
            matched: matched
        };
        debugLog.unshift(entry);
        if (debugLog.length > 20) debugLog.pop();
        renderDebugLog();
    }

    function renderDebugLog() {
        var el = document.getElementById('debugLog');
        if (!el) return;
        if (debugLog.length === 0) {
            el.innerHTML = '<span style="color:var(--muted);">No reads yet. Start scanning and point reader at a tag.</span>';
            return;
        }
        var html = '';
        for (var i = 0; i < debugLog.length; i++) {
            var e = debugLog[i];
            var color = e.matched ? '#10b981' : '#ef4444';
            var icon = e.matched ? '\u2705' : '\u274c';
            html += '<div style="padding:3px 0; border-bottom:1px solid var(--line); display:flex; gap:10px; align-items:flex-start;">'
                + '<span style="color:var(--muted); min-width:70px;">' + esc(e.time) + '</span>'
                + '<span style="color:' + color + '; min-width:18px;">' + icon + '</span>'
                + '<span><b>Raw:</b> ' + esc(e.raw) + '</span>'
                + '<span style="color:var(--muted);">\u2192</span>'
                + '<span><b>Norm:</b> ' + esc(e.normalized) + '</span>'
                + '</div>';
        }
        el.innerHTML = html;
    }

    function processRead(tagValue) {
        if (!scanning) return;
        totalReads++;

        var rawTag = tagValue.trim();
        var tag = normalizeTag(rawTag);  // strip F-padding, uppercase
        var now = Date.now();
        var matched = false;
        var matchedIdx = -1;

        // Extract EE number from the scanned tag (for fuzzy matching)
        var tagEENumber = extractEENumber(tag);

        for (var i = 0; i < targets.length; i++) {
            var t = targets[i];
            if (!t.rfidtag) continue;

            // Normalize the DB rfidtag for comparison (strip F-padding)
            var rfid = normalizeTag(t.rfidtag);
            var rfidEENumber = extractEENumber(rfid);

            var isMatch = false;

            // 1) Exact match (after normalization)
            if (rfid === tag) isMatch = true;

            // 2) Substring match (one contains the other)
            if (!isMatch && tag.length > 4 && (tag.indexOf(rfid) !== -1 || rfid.indexOf(tag) !== -1)) isMatch = true;

            // 3) EE-number match: both have the same numeric EE portion
            if (!isMatch && tagEENumber && rfidEENumber && tagEENumber === rfidEENumber) isMatch = true;

            if (isMatch) {
                matched = true;
                matchedIdx = i;
                t.readCount++;

                // Track read history for proximity
                if (!readHistory[rfid]) readHistory[rfid] = [];
                readHistory[rfid].push(now);
                // Keep last 30 reads
                if (readHistory[rfid].length > 30) readHistory[rfid].shift();

                if (!t.found) {
                    t.found = true;
                    t.foundAt = now;
                    flashRow(i);
                    playFoundBeep();
                } else {
                    // Update proximity display
                    pulseRow(i);
                }

                updateProximityForTag(rfid, i);
            }
        }

        // Debug log entry
        if (document.getElementById('chkDebug') && document.getElementById('chkDebug').checked) {
            addDebugEntry(rawTag, tag, matched);
        }

        if (!matched && document.getElementById('chkAudio').checked) {
            // Short low beep for unmatched read
            beep(200, 100, 0.05);
        }

        updateKPIs();

        // Check if all found
        var allFound = targets.every(function(t){ return t.found || !t.rfidtag; });
        if (allFound && targets.length > 0) {
            playAllFoundChime();
        }
    }

    // ═══════════════════════════════════════════════════════
    //  ROW VISUAL EFFECTS
    // ═══════════════════════════════════════════════════════
    function flashRow(idx) {
        var row = document.getElementById('row_' + idx);
        if (!row) return;
        row.className = 'row-found-flash';
        // Update status cell
        var cells = row.querySelectorAll('td');
        if (cells.length >= 7) {
            cells[6].innerHTML = '<span class="badge badge-found">&#9989; FOUND (just now)</span>';
        }
        setTimeout(function() {
            row.className = 'row-found';
        }, 1500);
    }

    function pulseRow(idx) {
        var row = document.getElementById('row_' + idx);
        if (!row) return;
        row.className = 'row-found-flash';
        var t = targets[idx];
        var cells = row.querySelectorAll('td');
        if (cells.length >= 7 && t.foundAt) {
            cells[6].innerHTML = '<span class="badge badge-found">&#9989; FOUND (' + timeSince(t.foundAt) + ')</span>';
        }
        setTimeout(function() {
            row.className = 'row-found';
        }, 400);
    }

    // ═══════════════════════════════════════════════════════
    //  PROXIMITY METER
    // ═══════════════════════════════════════════════════════
    function updateProximityForTag(rfid, idx) {
        var wrap = document.getElementById('proxWrap');
        var bar = document.getElementById('proxBar');
        var text = document.getElementById('proxText');
        var label = document.getElementById('proxAsset');

        wrap.style.display = '';
        label.textContent = targets[idx].input || targets[idx].name || rfid;

        var history = readHistory[rfid] || [];
        var rps = calcReadsPerSecond(history);

        // Scale: 0-10 rps → 0-100%
        var pct = Math.min(100, Math.round((rps / 10) * 100));
        bar.style.width = pct + '%';

        // Color gradient: red → yellow → green
        if (pct < 30) {
            bar.style.background = '#ef4444';
            text.textContent = 'Far';
        } else if (pct < 60) {
            bar.style.background = '#f59e0b';
            text.textContent = 'Getting closer...';
        } else if (pct < 85) {
            bar.style.background = '#10b981';
            text.textContent = 'Close!';
        } else {
            bar.style.background = 'linear-gradient(90deg, #10b981, #2ea8ff)';
            text.textContent = 'Very close!';
        }

        // Audio proximity beep
        if (document.getElementById('chkAudio').checked && !targets[idx].found) {
            var freq = 300 + (pct * 8);   // 300Hz → 1100Hz
            var dur = 150 - pct;          // shorter beeps when closer
            beep(freq, Math.max(30, dur), 0.15);
        }
    }

    function updateProximity() {
        // Decay the proximity bar if no recent reads
        var bar = document.getElementById('proxBar');
        var text = document.getElementById('proxText');
        if (!bar) return;
        var w = parseFloat(bar.style.width) || 0;
        if (w > 0) {
            w = Math.max(0, w - 5);
            bar.style.width = w + '%';
            if (w < 5) {
                text.textContent = '-';
                bar.style.background = 'var(--line)';
            }
        }
    }

    function calcReadsPerSecond(timestamps) {
        if (timestamps.length < 2) return 0;
        var now = Date.now();
        // Count reads in last 3 seconds
        var recent = timestamps.filter(function(t){ return (now - t) < 3000; });
        return recent.length / 3;
    }

    // ═══════════════════════════════════════════════════════
    //  AUDIO (Web Audio API)
    // ═══════════════════════════════════════════════════════
    function getAudioCtx() {
        if (!audioCtx) {
            audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        }
        return audioCtx;
    }

    function beep(freq, durationMs, volume) {
        if (!document.getElementById('chkAudio').checked) return;
        try {
            var ctx = getAudioCtx();
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.frequency.value = freq;
            gain.gain.value = volume || 0.1;
            osc.start();
            osc.stop(ctx.currentTime + (durationMs / 1000));
        } catch(e) {}
    }

    function playFoundBeep() {
        if (!document.getElementById('chkAudio').checked) return;
        beep(880, 150, 0.2);
        setTimeout(function() { beep(1100, 200, 0.2); }, 180);
    }

    function playAllFoundChime() {
        if (!document.getElementById('chkAudio').checked) return;
        beep(660, 120, 0.2);
        setTimeout(function() { beep(880, 120, 0.2); }, 150);
        setTimeout(function() { beep(1100, 250, 0.25); }, 300);
    }

    // ═══════════════════════════════════════════════════════
    //  WEBSERIAL USB SUPPORT
    // ═══════════════════════════════════════════════════════
    window.serialToggle = async function() {
        if (serialPort) {
            // Close
            try {
                if (serialReader) { await serialReader.cancel(); serialReader = null; }
                await serialPort.close();
            } catch(e) {}
            serialPort = null;
            document.getElementById('serialStatus').textContent = 'Disconnected';
            document.getElementById('serialStatus').className = 'serial-status';
            document.getElementById('btnSerial').textContent = '🔌 Connect';
            return;
        }

        if (!('serial' in navigator)) {
            document.getElementById('serialStatus').textContent = 'WebSerial not available (requires HTTPS)';
            document.getElementById('serialStatus').className = 'serial-status';
            return;
        }

        try {
            serialPort = await navigator.serial.requestPort();
            await serialPort.open({ baudRate: 115200, dataBits: 8, stopBits: 1, parity: 'none', flowControl: 'hardware' });
            document.getElementById('serialStatus').textContent = 'Connected';
            document.getElementById('serialStatus').className = 'serial-status serial-connected';
            document.getElementById('btnSerial').textContent = '⏏ Disconnect';

            // Read loop
            var decoder = new TextDecoderStream();
            var inputDone = serialPort.readable.pipeTo(decoder.writable);
            serialReader = decoder.readable.getReader();
            var buffer = '';

            (async function readLoop() {
                try {
                    while (true) {
                        var result = await serialReader.read();
                        if (result.done) break;
                        buffer += result.value;
                        var lines = buffer.split('\n');
                        buffer = lines.pop(); // keep incomplete line in buffer
                        for (var i = 0; i < lines.length; i++) {
                            var line = lines[i].replace(/\r/g, '').trim();
                            if (line.length > 0) {
                                processRead(line);
                            }
                        }
                    }
                } catch(e) {
                    if (e.name !== 'TypeError') {
                        document.getElementById('serialStatus').textContent = 'Disconnected (' + e.message + ')';
                    }
                }
            })();
        } catch(e) {
            document.getElementById('serialStatus').textContent = 'Failed: ' + e.message;
            serialPort = null;
        }
    };

    // ═══════════════════════════════════════════════════════
    //  QUERY STRING PRE-LOAD
    // ═══════════════════════════════════════════════════════
    (function() {
        var params = new URLSearchParams(window.location.search);
        var assets = params.get('assets');
        if (assets) {
            document.getElementById('targetInput').value = assets.split(',').join('\n');
            // Auto-load after brief delay to let page render
            setTimeout(function() { window.loadTargets(); }, 300);
        }
    })();

    // Refresh found timestamps periodically
    setInterval(function() {
        if (!scanning) return;
        var cells = document.querySelectorAll('.badge-found');
        for (var i = 0; i < targets.length; i++) {
            if (targets[i].found && targets[i].foundAt) {
                var row = document.getElementById('row_' + i);
                if (row) {
                    var tds = row.querySelectorAll('td');
                    if (tds.length >= 7) {
                        tds[6].innerHTML = '<span class="badge badge-found">&#9989; FOUND (' + timeSince(targets[i].foundAt) + ')</span>';
                    }
                }
            }
        }
    }, 5000);

})();
</script>
</body>
</html>
