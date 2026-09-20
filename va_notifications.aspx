<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_notifications.aspx.cs" Inherits="va_notifications" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>iDash Notifications &amp; Asset Watch List</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
        :root {
            --green: #10b981;
            --amber: #f59e0b;
            --red: #ef4444;
            --blue: #3b82f6;
            --purple: #8b5cf6;
            --cyan: #06b6d4;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            padding: 0;
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            min-height: 100vh;
        }
        .dash {
            max-width: 1540px;
            margin: 0 auto;
            padding: 24px 28px;
        }

        /* Top Header */
        .page-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 20px;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--line);
        }
        .header-title-group h1 {
            margin: 0 0 4px;
            font-size: 26px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            color: var(--text);
        }
        .header-subtitle {
            font-size: 13px;
            color: var(--muted);
            margin: 0;
        }
        .hdr-right {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .nav-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 13px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.15s ease;
            border: 1px solid var(--line);
            color: var(--text);
            background: var(--card);
            line-height: 1.4;
        }
        .nav-pill:hover {
            border-color: var(--accent);
            color: var(--accent);
        }
        .nav-pill-primary {
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
        }
        .nav-pill-primary:hover {
            opacity: 0.9;
            color: #fff;
        }
        .nav-pill-success {
            background: color-mix(in srgb, var(--green) 15%, transparent);
            color: var(--green);
            border-color: var(--green);
        }
        .nav-pill-success:hover {
            background: color-mix(in srgb, var(--green) 25%, transparent);
        }
        .nav-pill-docs {
            border-color: var(--accent);
            color: var(--accent);
        }

        /* KPI Cards */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        .kpi-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 16px 18px;
            display: flex;
            flex-direction: column;
            box-shadow: 0 2px 6px rgba(0,0,0,0.04);
            cursor: pointer;
            transition: transform 0.15s, border-color 0.15s;
        }
        .kpi-card:hover {
            transform: translateY(-2px);
            border-color: var(--accent);
        }
        .kpi-card.active-filter {
            border-color: var(--accent);
            background: color-mix(in srgb, var(--accent) 5%, var(--card));
        }
        .kpi-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 6px;
        }
        .kpi-lbl {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--muted);
        }
        .kpi-val {
            font-size: 28px;
            font-weight: 800;
            line-height: 1.1;
        }
        .kpi-sub {
            font-size: 12px;
            color: var(--muted);
            margin-top: 4px;
        }

        /* Main 2-column Grid */
        .layout-grid {
            display: grid;
            grid-template-columns: 340px 1fr;
            gap: 24px;
            align-items: start;
        }
        @media (max-width: 1024px) {
            .layout-grid {
                grid-template-columns: 1fr;
            }
        }

        /* Sidebar Watch List Editor */
        .panel {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.04);
        }
        .panel-title {
            font-size: 15px;
            font-weight: 700;
            margin: 0 0 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            color: var(--text);
        }
        .watch-ta {
            width: 100%;
            height: 160px;
            background: var(--bg);
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 10px 12px;
            font-family: "JetBrains Mono", Consolas, monospace;
            font-size: 12px;
            color: var(--text);
            resize: vertical;
            line-height: 1.5;
            outline: none;
        }
        .watch-ta:focus {
            border-color: var(--accent);
            box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 15%, transparent);
        }
        .watch-ta::placeholder {
            color: var(--muted);
            opacity: 0.7;
        }
        .btn-group {
            display: flex;
            gap: 8px;
            margin-top: 10px;
            flex-wrap: wrap;
        }
        .btn {
            flex: 1;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            border: 1px solid;
            text-align: center;
            transition: all 0.15s ease;
            white-space: nowrap;
        }
        .btn-primary {
            background: color-mix(in srgb, var(--blue) 15%, transparent);
            border-color: var(--blue);
            color: var(--blue);
        }
        .btn-primary:hover {
            background: color-mix(in srgb, var(--blue) 25%, transparent);
        }
        .btn-ghost {
            background: transparent;
            border-color: var(--line);
            color: var(--muted);
        }
        .btn-ghost:hover {
            border-color: var(--muted);
            color: var(--text);
        }
        .quick-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-top: 14px;
            padding-top: 12px;
            border-top: 1px dashed var(--line);
        }
        .qchip {
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: 12px;
            font-size: 11px;
            padding: 3px 8px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            color: var(--text);
        }
        .qchip-del {
            cursor: pointer;
            color: var(--muted);
            font-weight: bold;
        }
        .qchip-del:hover {
            color: var(--red);
        }

        /* Results Toolbar */
        .results-hdr {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 16px;
        }
        .filter-tabs {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
        }
        .tab-btn {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            background: var(--bg);
            border: 1px solid var(--line);
            color: var(--muted);
            cursor: pointer;
            transition: all 0.15s;
        }
        .tab-btn:hover {
            color: var(--text);
            border-color: var(--accent);
        }
        .tab-btn.active {
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
        }

        .search-box {
            position: relative;
            min-width: 240px;
        }
        .search-input {
            width: 100%;
            background: var(--bg);
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 6px 12px 6px 30px;
            font-size: 12px;
            color: var(--text);
            outline: none;
        }
        .search-input:focus {
            border-color: var(--accent);
        }
        .search-icon {
            position: absolute;
            left: 10px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 12px;
            color: var(--muted);
        }

        /* Results Table */
        .table-wrap {
            overflow-x: auto;
            border: 1px solid var(--line);
            border-radius: 10px;
            background: var(--card);
        }
        table.wl-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
            text-align: left;
        }
        table.wl-table th {
            background: var(--bg);
            padding: 10px 14px;
            color: var(--muted);
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid var(--line);
            white-space: nowrap;
        }
        table.wl-table td {
            padding: 12px 14px;
            border-bottom: 1px solid var(--line);
            color: var(--text);
            vertical-align: middle;
        }
        table.wl-table tbody tr:hover {
            background: color-mix(in srgb, var(--accent) 3%, transparent);
        }
        table.wl-table tbody tr:last-child td {
            border-bottom: none;
        }

        /* Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 700;
            white-space: nowrap;
        }
        .b-high {
            background: color-mix(in srgb, var(--green) 15%, transparent);
            color: var(--green);
            border: 1px solid var(--green);
        }
        .b-mod {
            background: color-mix(in srgb, var(--amber) 15%, transparent);
            color: var(--amber);
            border: 1px solid var(--amber);
        }
        .b-low {
            background: color-mix(in srgb, #f97316 15%, transparent);
            color: #f97316;
            border: 1px solid #f97316;
        }
        .b-cold {
            background: color-mix(in srgb, var(--muted) 15%, transparent);
            color: var(--muted);
            border: 1px solid var(--line);
        }
        .b-mismatch {
            background: color-mix(in srgb, var(--red) 15%, transparent);
            color: var(--red);
            border: 1px solid var(--red);
            font-weight: 800;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }

        .asset-link {
            font-weight: 700;
            color: var(--text);
            text-decoration: none;
            cursor: pointer;
        }
        .asset-link:hover {
            color: var(--accent);
            text-decoration: underline;
        }
        .empty-state {
            text-align: center;
            padding: 50px 20px;
            color: var(--muted);
        }
        .empty-icon {
            font-size: 36px;
            margin-bottom: 10px;
            opacity: 0.6;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            display: inline-block;
        }
        .dot-green { background: var(--green); box-shadow: 0 0 6px var(--green); }
        .dot-amber { background: var(--amber); }
        .dot-red { background: var(--red); }
        .dot-gray { background: var(--muted); }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="dash">

            <!-- HEADER -->
            <div class="page-header">
                <div class="header-title-group">
                    <h1><span>🔔</span> iDash Notifications &amp; Watch List</h1>
                    <p class="header-subtitle">Real-time RFID detection tracking, background observations, and location mismatch alerts</p>
                </div>
                <div class="hdr-right">
                    <button type="button" class="nav-pill nav-pill-success" onclick="exportToCsv()" title="Export current results to Excel CSV">📥 Export to Excel</button>
                    <button type="button" class="nav-pill nav-pill-primary" onclick="openFoundInMaster()" title="Filter these watched assets in Asset Master">📋 Open in Asset Master</button>
                    <div style="width:1px;height:20px;background:var(--line);"></div>
                    <a href="va_asset_master.aspx" class="nav-pill">&#128203; Asset Master</a>
                    <a href="va_fixed_reader.aspx" class="nav-pill">&#128202; Fixed Readers</a>
                    <a href="va_fixed_reader_live.aspx" class="nav-pill" target="_blank">&#128225; Live Feed</a>
                    <div style="width:1px;height:20px;background:var(--line);"></div>
                    <button type="button" id="themeToggleBtn" class="nav-pill" onclick="toggleTheme()" title="Switch Light/Dark mode" style="font-size:15px;padding:6px 10px;">☀️</button>
                    <a href="documentation/va_idash_notifications.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
                    <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
                </div>
            </div>

            <!-- KPI SUMMARY CARDS -->
            <div class="kpi-row">
                <div class="kpi-card active-filter" id="cardTotal" onclick="filterByLevel('ALL')">
                    <div class="kpi-top">
                        <span class="kpi-lbl">Total Watched</span>
                        <span class="status-dot dot-gray"></span>
                    </div>
                    <div class="kpi-val" id="valTotal" style="color:var(--text);">0</div>
                    <div class="kpi-sub" id="subTotal">Assets monitored</div>
                </div>
                <div class="kpi-card" id="cardHigh" onclick="filterByLevel('HIGH')">
                    <div class="kpi-top">
                        <span class="kpi-lbl">High Detection</span>
                        <span class="status-dot dot-green"></span>
                    </div>
                    <div class="kpi-val" id="valHigh" style="color:var(--green);">0</div>
                    <div class="kpi-sub">Observed &lt; 24h</div>
                </div>
                <div class="kpi-card" id="cardMod" onclick="filterByLevel('MODERATE')">
                    <div class="kpi-top">
                        <span class="kpi-lbl">Moderate Detection</span>
                        <span class="status-dot dot-amber"></span>
                    </div>
                    <div class="kpi-val" id="valMod" style="color:var(--amber);">0</div>
                    <div class="kpi-sub">Observed in past 7d</div>
                </div>
                <div class="kpi-card" id="cardMismatch" onclick="filterByLevel('MISMATCH')">
                    <div class="kpi-top">
                        <span class="kpi-lbl">Location Mismatches</span>
                        <span class="status-dot dot-red"></span>
                    </div>
                    <div class="kpi-val" id="valMismatch" style="color:var(--red);">0</div>
                    <div class="kpi-sub">Observed &ne; Assigned</div>
                </div>
                <div class="kpi-card" id="cardCold" onclick="filterByLevel('COLD')">
                    <div class="kpi-top">
                        <span class="kpi-lbl">Cold / Undetected</span>
                        <span class="status-dot dot-gray"></span>
                    </div>
                    <div class="kpi-val" id="valCold" style="color:var(--muted);">0</div>
                    <div class="kpi-sub">No recent fixed reads</div>
                </div>
            </div>

            <!-- 2-COLUMN WORKSPACE -->
            <div class="layout-grid">

                <!-- LEFT: WATCH LIST EDITOR -->
                <div class="panel">
                    <div class="panel-title">
                        <span>🔍 Asset Watch List</span>
                        <span id="syncBadge" style="font-size:11px;font-weight:normal;color:var(--muted);">Live Feed Synced</span>
                    </div>
                    <textarea class="watch-ta" id="wInput" placeholder="Enter asset numbers to watch...&#10;One per line or comma-separated&#10;e.g. 613 EE12889, 512 EE17890"></textarea>
                    
                    <div class="btn-group">
                        <button type="button" class="btn btn-primary" onclick="checkWatchList(true)">🔍 Check Now</button>
                        <button type="button" class="btn btn-ghost" onclick="saveWatchListToServer()" title="Save list to your user account on server">💾 Save</button>
                        <button type="button" class="btn btn-ghost" onclick="clearWatchList()" style="flex:0.6;">✕ Clear</button>
                    </div>

                    <div style="margin-top:14px;font-size:11px;color:var(--muted);line-height:1.4;">
                        <strong>💡 How it works:</strong> Assets listed here are monitored against fixed reader background observations. Synced seamlessly with <a href="va_fixed_reader_live.aspx" target="_blank" style="color:var(--accent);">Fixed Reader Live</a>.
                    </div>

                    <div class="quick-chips" id="quickChips"></div>
                </div>

                <!-- RIGHT: OBSERVATION & DETECTION RESULTS -->
                <div class="panel" style="padding: 16px 20px;">
                    <div class="results-hdr">
                        <div class="filter-tabs">
                            <button type="button" class="tab-btn active" id="tabALL" onclick="filterByLevel('ALL')">All (<span id="cntAll">0</span>)</button>
                            <button type="button" class="tab-btn" id="tabHIGH" onclick="filterByLevel('HIGH')">🟢 High (<span id="cntHigh">0</span>)</button>
                            <button type="button" class="tab-btn" id="tabMODERATE" onclick="filterByLevel('MODERATE')">🟡 Moderate (<span id="cntMod">0</span>)</button>
                            <button type="button" class="tab-btn" id="tabMISMATCH" onclick="filterByLevel('MISMATCH')">⚠️ Mismatches (<span id="cntMismatch">0</span>)</button>
                            <button type="button" class="tab-btn" id="tabCOLD" onclick="filterByLevel('COLD')">⚪ Undetected (<span id="cntCold">0</span>)</button>
                        </div>

                        <div class="search-box">
                            <span class="search-icon">🔍</span>
                            <input type="text" id="txtFilterSearch" class="search-input" placeholder="Filter results..." oninput="renderTable()" />
                        </div>
                    </div>

                    <div class="table-wrap">
                        <table class="wl-table" id="tblWatch">
                            <thead>
                                <tr>
                                    <th>Detection Level</th>
                                    <th>Asset Number</th>
                                    <th>Description</th>
                                    <th>Facility / Site</th>
                                    <th>Observed Location</th>
                                    <th>Assigned Location</th>
                                    <th>Last Detected</th>
                                    <th style="text-align:right;">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="tblBody">
                                <tr><td colspan="8" class="empty-state">Loading watch list...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>

        </div>
    </form>

    <script>
        var rawAssetsData = [];
        var activeFilter = 'ALL';
        var autoPollTimer = null;

        // Theme Toggle
        function toggleTheme() {
            var html = document.documentElement;
            var isDark = html.getAttribute('data-theme') !== 'light';
            var next = isDark ? 'light' : 'dark';
            if (next === 'dark') { html.removeAttribute('data-theme'); }
            else { html.setAttribute('data-theme', next); }
            localStorage.setItem('idash_theme', next === 'dark' ? '' : 'light');
            updateThemeBtn();
        }
        function updateThemeBtn() {
            var btn = document.getElementById('themeToggleBtn');
            if (!btn) return;
            var isLight = document.documentElement.getAttribute('data-theme') === 'light';
            btn.textContent = isLight ? '🌙' : '☀️';
        }
        (function() { updateThemeBtn(); })();

        // Init Watch List
        window.addEventListener('DOMContentLoaded', function() {
            loadWatchList();
            // Start background poll every 30s
            autoPollTimer = setInterval(function() {
                if (document.visibilityState === 'visible') {
                    checkWatchList(false);
                }
            }, 30000);
        });

        function loadWatchList() {
            var saved = localStorage.getItem('idash-watch-list') || '';
            if (saved) {
                document.getElementById('wInput').value = saved;
                checkWatchList(true);
            } else {
                // Try loading from server
                fetch('va_watchlist_api.ashx?action=load&t=' + Date.now())
                    .then(function(r) { return r.json(); })
                    .then(function(d) {
                        if (d && d.items) {
                            document.getElementById('wInput').value = d.items;
                            localStorage.setItem('idash-watch-list', d.items);
                            checkWatchList(true);
                        } else {
                            renderEmpty('Enter asset numbers on the left to start monitoring RFID detections.');
                        }
                    })
                    .catch(function() {
                        renderEmpty('Enter asset numbers on the left to start monitoring RFID detections.');
                    });
            }
        }

        function checkWatchList(showLoading) {
            var raw = document.getElementById('wInput').value.trim();
            if (!raw) {
                rawAssetsData = [];
                updateSummary({ totalWatched: 0, high: 0, moderate: 0, low: 0, cold: 0, mismatch: 0 });
                renderTable();
                renderChips([]);
                return;
            }

            // Sync to localStorage
            try { localStorage.setItem('idash-watch-list', raw); } catch(e) {}

            if (showLoading) {
                document.getElementById('tblBody').innerHTML = '<tr><td colspan="8" style="text-align:center;padding:30px;color:var(--muted);">Checking background detections...</td></tr>';
            }

            var items = raw.split(/[\r\n,]+/).map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; });
            renderChips(items);

            fetch('va_watchlist_api.ashx?action=check&t=' + Date.now(), {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ items: items })
            })
            .then(function(r) { return r.json(); })
            .then(function(d) {
                if (d.error) {
                    document.getElementById('tblBody').innerHTML = '<tr><td colspan="8" style="text-align:center;color:var(--red);padding:20px;">' + esc(d.error) + '</td></tr>';
                    return;
                }
                rawAssetsData = d.assets || [];
                updateSummary(d.summary || {});
                renderTable();
            })
            .catch(function(err) {
                console.error('Watchlist check error:', err);
                document.getElementById('tblBody').innerHTML = '<tr><td colspan="8" style="text-align:center;color:var(--red);padding:20px;">Failed to evaluate watch list.</td></tr>';
            });
        }

        function saveWatchListToServer() {
            var raw = document.getElementById('wInput').value.trim();
            fetch('va_watchlist_api.ashx?action=save&t=' + Date.now(), {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ items: raw })
            })
            .then(function(r) { return r.json(); })
            .then(function(d) {
                if (d && d.success) {
                    alert('Watch list saved successfully to your server profile!');
                }
            })
            .catch(function(e) {
                alert('Could not save to server: ' + e.message);
            });
        }

        function clearWatchList() {
            if (!confirm('Clear the entire watch list?')) return;
            document.getElementById('wInput').value = '';
            try { localStorage.removeItem('idash-watch-list'); } catch(e) {}
            rawAssetsData = [];
            updateSummary({ totalWatched: 0, high: 0, moderate: 0, low: 0, cold: 0, mismatch: 0 });
            renderTable();
            renderChips([]);
        }

        function updateSummary(s) {
            document.getElementById('valTotal').textContent = s.totalWatched || 0;
            document.getElementById('valHigh').textContent = s.high || 0;
            document.getElementById('valMod').textContent = s.moderate || 0;
            document.getElementById('valMismatch').textContent = s.mismatch || 0;
            document.getElementById('valCold').textContent = (s.cold || 0) + (s.low || 0);

            document.getElementById('cntAll').textContent = s.totalWatched || 0;
            document.getElementById('cntHigh').textContent = s.high || 0;
            document.getElementById('cntMod').textContent = s.moderate || 0;
            document.getElementById('cntMismatch').textContent = s.mismatch || 0;
            document.getElementById('cntCold').textContent = (s.cold || 0) + (s.low || 0);
        }

        function filterByLevel(level) {
            activeFilter = level;
            document.querySelectorAll('.tab-btn').forEach(function(btn) { btn.classList.remove('active'); });
            var tab = document.getElementById('tab' + level);
            if (tab) tab.classList.add('active');

            document.querySelectorAll('.kpi-card').forEach(function(c) { c.classList.remove('active-filter'); });
            var map = { 'ALL': 'cardTotal', 'HIGH': 'cardHigh', 'MODERATE': 'cardMod', 'MISMATCH': 'cardMismatch', 'COLD': 'cardCold' };
            var card = document.getElementById(map[level]);
            if (card) card.classList.add('active-filter');

            renderTable();
        }

        function renderTable() {
            var tbody = document.getElementById('tblBody');
            var search = (document.getElementById('txtFilterSearch').value || '').trim().toLowerCase();

            var filtered = rawAssetsData.filter(function(a) {
                // Filter by level
                if (activeFilter === 'HIGH' && a.DetectionLevel !== 'HIGH') return false;
                if (activeFilter === 'MODERATE' && a.DetectionLevel !== 'MODERATE') return false;
                if (activeFilter === 'MISMATCH' && !a.LocationMismatch) return false;
                if (activeFilter === 'COLD' && a.DetectionLevel !== 'COLD' && a.DetectionLevel !== 'LOW') return false;

                // Search filter
                if (search) {
                    var str = ((a.AssetName||'') + ' ' + (a.Description||'') + ' ' + (a.ObservedLocation||'') + ' ' + (a.AssignedLocation||'') + ' ' + (a.SiteName||'')).toLowerCase();
                    if (str.indexOf(search) === -1) return false;
                }
                return true;
            });

            if (!filtered.length) {
                renderEmpty(rawAssetsData.length ? 'No assets matching filter.' : 'No assets in watch list.');
                return;
            }

            var html = '';
            filtered.forEach(function(a) {
                var badgeCls = 'b-cold';
                var badgeTxt = '⚪ Undetected';
                if (a.DetectionLevel === 'HIGH') { badgeCls = 'b-high'; badgeTxt = '🟢 High Detection'; }
                else if (a.DetectionLevel === 'MODERATE') { badgeCls = 'b-mod'; badgeTxt = '🟡 Moderate'; }
                else if (a.DetectionLevel === 'LOW') { badgeCls = 'b-low'; badgeTxt = '🟠 Low'; }

                var obsHtml = a.ObservedLocation
                    ? '<strong>' + esc(a.ObservedLocation) + '</strong>'
                    : '<span style="color:var(--muted);">None</span>';

                var asgHtml = esc(a.AssignedLocation || '(Unassigned)');
                if (a.LocationMismatch) {
                    asgHtml = '<span class="badge b-mismatch" title="' + esc(a.MismatchMessage) + '">⚠️ ' + asgHtml + '</span>';
                }

                var timeHtml = a.RelativeTime
                    ? '<span title="' + esc(a.LastObservedTime) + '">' + esc(a.RelativeTime) + '</span>'
                    : '<span style="color:var(--muted);">' + esc(a.LastInventoriedTime ? 'Inv: ' + a.LastInventoriedTime : 'Never') + '</span>';

                var readerExtra = '';
                if (a.RecentReader || a.RecentRssi) {
                    readerExtra = '<div style="font-size:10px;color:var(--muted);margin-top:2px;">' + esc(a.RecentReader) + (a.RecentRssi ? ' (' + esc(a.RecentRssi) + ')' : '') + '</div>';
                }

                html += '<tr>' +
                    '<td><span class="badge ' + badgeCls + '">' + badgeTxt + '</span></td>' +
                    '<td><a class="asset-link" onclick="openSingleInMaster(\'' + esc(a.AssetName) + '\', \'' + (a.CompanyId || '') + '\', \'' + esc(a.SiteName || '') + '\')">' + esc(a.AssetName) + '</a></td>' +
                    '<td><div style="font-weight:600;">' + esc(a.Description || '--') + '</div>' + (a.CMR ? '<span style="font-size:11px;color:var(--muted);">CMR: ' + esc(a.CMR) + '</span>' : '') + '</td>' +
                    '<td>' + esc(a.SiteName || '--') + '</td>' +
                    '<td>' + obsHtml + readerExtra + '</td>' +
                    '<td>' + asgHtml + '</td>' +
                    '<td>' + timeHtml + '</td>' +
                    '<td style="text-align:right;white-space:nowrap;">' +
                        '<button type="button" class="btn btn-ghost" style="padding:3px 8px;font-size:11px;margin-right:4px;" onclick="openSingleInMaster(\'' + esc(a.AssetName) + '\', \'' + (a.CompanyId || '') + '\', \'' + esc(a.SiteName || '') + '\')" title="Inspect in Asset Master">📋 Inspect</button>' +
                        '<button type="button" class="btn btn-ghost" style="padding:3px 8px;font-size:11px;color:var(--red);" onclick="removeAsset(\'' + esc(a.SearchKey) + '\')" title="Remove from watch list">✕</button>' +
                    '</td>' +
                '</tr>';
            });

            tbody.innerHTML = html;
        }

        function renderEmpty(msg) {
            document.getElementById('tblBody').innerHTML = '<tr><td colspan="8" class="empty-state"><div class="empty-icon">🔔</div><div>' + esc(msg) + '</div></td></tr>';
        }

        function renderChips(items) {
            var el = document.getElementById('quickChips');
            if (!items.length) { el.innerHTML = ''; return; }
            var html = '';
            items.slice(0, 15).forEach(function(it) {
                html += '<span class="qchip">' + esc(it) + ' <span class="qchip-del" onclick="removeAsset(\'' + esc(it) + '\')">&times;</span></span>';
            });
            if (items.length > 15) {
                html += '<span class="qchip" style="background:none;border:none;color:var(--muted);">+' + (items.length - 15) + ' more</span>';
            }
            el.innerHTML = html;
        }

        function removeAsset(key) {
            var raw = document.getElementById('wInput').value;
            var parts = raw.split(/[\r\n,]+/).map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0 && s.toUpperCase() !== key.toUpperCase(); });
            document.getElementById('wInput').value = parts.join('\n');
            checkWatchList(true);
        }

        // Export to Excel CSV
        function exportToCsv() {
            if (!rawAssetsData.length) { alert('No assets in watch list to export.'); return; }
            var rows = [['Asset Number', 'Description', 'Detection Level', 'Last Observed Time', 'Observed Location', 'Assigned Location', 'Location Mismatch', 'Facility Site', 'Status', 'CMR', 'Recent Reader', 'Signal RSSI']];
            rawAssetsData.forEach(function(a) {
                rows.push([
                    a.AssetName || a.SearchKey,
                    a.Description || '',
                    a.DetectionLevel || 'COLD',
                    a.LastObservedTime || (a.LastInventoriedTime ? 'Inventoried ' + a.LastInventoriedTime : 'Never'),
                    a.ObservedLocation || '',
                    a.AssignedLocation || '',
                    a.LocationMismatch ? 'YES' : 'NO',
                    a.SiteName || '',
                    a.Status || '',
                    a.CMR || '',
                    a.RecentReader || '',
                    a.RecentRssi || ''
                ]);
            });

            var csv = rows.map(function(r) {
                return r.map(function(c) { return '"' + String(c).replace(/"/g, '""') + '"'; }).join(',');
            }).join('\r\n');

            var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = 'iDash-WatchList-' + new Date().toISOString().slice(0,10) + '.csv';
            a.click();
            URL.revokeObjectURL(url);
        }

        // Open in Asset Master
        function openFoundInMaster() {
            if (!rawAssetsData.length) { alert('No assets in watch list.'); return; }
            var names = rawAssetsData.map(function(a) { return a.AssetName || a.SearchKey; });
            try { sessionStorage.setItem('idash-watch-filter', JSON.stringify(names)); } catch(e) {}

            var siteParam = '';
            var firstCompId = rawAssetsData[0].CompanyId;
            var firstPrefix = (names[0] || '').substring(0, 3);
            var allSameComp = firstCompId && rawAssetsData.every(function(a) { return a.CompanyId === firstCompId; });
            if (allSameComp) {
                siteParam = firstCompId;
            } else if (/^\d{3}$/.test(firstPrefix) && names.every(function(n) { return (n || '').substring(0, 3) === firstPrefix; })) {
                siteParam = firstPrefix;
            }

            var url = 'va_asset_master.aspx?watchFilter=1' + (siteParam ? '&site=' + encodeURIComponent(siteParam) : '');
            window.open(url, '_blank');
        }

        function openSingleInMaster(name, companyId, siteName) {
            try { sessionStorage.setItem('idash-watch-filter', JSON.stringify([name])); } catch(e) {}
            var siteParam = companyId || (name && name.length >= 3 && /^\d{3}/.test(name) ? name.substring(0, 3) : '');
            var url = 'va_asset_master.aspx?watchFilter=1' + (siteParam ? '&site=' + encodeURIComponent(siteParam) : '');
            window.open(url, '_blank');
        }

        function esc(s) {
            if (!s) return '';
            return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        }
    </script>
</body>
</html>
