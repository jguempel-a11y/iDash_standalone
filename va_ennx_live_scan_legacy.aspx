<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_ennx_live_scan_legacy.aspx.cs" Inherits="va_ennx_live_scan_legacy" %>

    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">

    <head runat="server">
        <title>ENNX Live Scan</title>
            <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />
        <script>
            if ('serviceWorker' in navigator) {
                navigator.serviceWorker.register('sw.js').then(function(reg) {
                    if (reg.waiting) reg.waiting.postMessage({ type: 'SKIP_WAITING' });
                }).catch(function() {});
            }
        </script>

        <style>
            

            body {
                margin: 0;
                background: var(--bg);
                color: var(--text);
                font-family: Segoe UI, system-ui, Arial, sans-serif;
            }

            .wrap {
                padding: 16px;
                max-width: 1100px;
                margin: 0 auto;
            }

            .top {
                display: flex;
                gap: 12px;
                align-items: flex-start;
                justify-content: space-between;
                flex-wrap: wrap;
                margin-bottom: 12px;
            }

            .h1 {
                font-size: 20px;
                font-weight: 800;
                letter-spacing: .2px
            }

            .sub {
                color: var(--muted);
                font-size: 13px;
                margin-top: 2px
            }

            .row {
                display: flex;
                gap: 12px;
                flex-wrap: wrap
            }

            .panel {
                background: var(--card);
                border: 1px solid var(--line);
                border-radius: 14px;
                padding: 14px;
                box-shadow:var(--shadow);
            }

            .panel.flex {
                flex: 1;
                min-width: 320px
            }

            .kpis {
                display: flex;
                gap: 10px;
                flex-wrap: wrap
            }

            .kpi {
                background: var(--chip);
                border: 1px solid var(--line);
                border-radius: 12px;
                padding: 10px 12px;
                min-width: 140px;
            }

            .kpi .n {
                font-size: 18px;
                font-weight: 800
            }

            .kpi .l {
                font-size: 12px;
                color: var(--muted);
                margin-top: 2px
            }

            .btnbar {
                display: flex;
                gap: 8px;
                flex-wrap: wrap
            }

            .btn {
                border: 1px solid var(--line);
                background: var(--chip);
                color: var(--text);
                padding: 10px 12px;
                border-radius: 12px;
                cursor: pointer;
                font-weight: 700;
                font-size: 13px;
            }

            .btn.primary {
                border-color:color-mix(in srgb, var(--accent), transparent 55%);
                box-shadow:0 0 0 2px color-mix(in srgb, var(--accent), transparent 92%) inset
            }

            .btn.good {
                border-color:color-mix(in srgb, var(--accent-2), transparent 55%);
                box-shadow:0 0 0 2px color-mix(in srgb, var(--accent-2), transparent 92%) inset
            }

            .btn.bad {
                border-color:color-mix(in srgb, var(--danger), transparent 55%);
                box-shadow:0 0 0 2px color-mix(in srgb, var(--danger), transparent 92%) inset
            }

            .btn:active {
                transform: translateY(1px)
            }

            .field {
                width: 100%;
                padding: 12px 12px;
                border-radius: 12px;
                border: 1px solid var(--line);
                background: var(--chip);
                color: var(--text);
                font-size: 16px;
                outline: none;
            }

            .hint {
                color: var(--muted);
                font-size: 12px;
                margin-top: 8px;
                line-height: 1.35
            }

            .tag {
                display: inline-flex;
                align-items: center;
                gap: 8px;
                background: var(--chip);
                border: 1px solid var(--line);
                padding: 6px 10px;
                border-radius: 999px;
                font-size: 12px;
                color: var(--muted);
            }

            .tag b {
                color: var(--text)
            }

            .grid {
                width: 100%;
                border-collapse: collapse;
                font-size: 13px;
                margin-top: 10px;
                border: 1px solid var(--line);
                border-radius: 12px;
                overflow: hidden;
            }

            .grid th,
            .grid td {
                padding: 10px;
                border-bottom: 1px solid var(--line);
                vertical-align: top
            }

            .grid th {
                background: var(--chip);
                text-align: left;
                color: var(--muted);
                font-weight: 800
            }

            .grid tr:last-child td {
                border-bottom: none
            }

            .mono {
                font-family: Consolas, Menlo, monospace
            }

            .warn {
                color:var(--warn)
            }

            .err {
                color:var(--danger)
            }

            .ok {
                color:var(--accent-2)
            }

            .ta {
                width: 100%;
                min-height: 320px;
                resize: vertical;
                padding: 12px;
                border-radius: 12px;
                border: 1px solid var(--line);
                background: var(--chip);
                color: var(--text);
                font-size: 13px;
            }

            .small {
                font-size: 12px;
                color: var(--muted)
            }

            .footer {
                margin-top: 14px;
                color: var(--muted);
                font-size: 12px;
                text-align: center
            }

            .company-select {
                background: var(--card);
                color: var(--text);
                border: 1px solid var(--line);
                padding: 6px 10px;
                border-radius: 4px;
                font-size: 14px;
            }

            .status-bar {
                display: flex;
                justify-content: space-between;
                background: var(--chip);
                padding: 8px 20px;
                font-size: 13px;
                border-bottom: 1px solid var(--line);
            }

            #connection-indicator {
                font-size: 14px;
                font-weight: 700;
            }

            /* WebSerial section */
            .serial-section {
                background: var(--chip);
                border: 1px solid var(--line);
                border-radius: 12px;
                padding: 12px;
                margin-top: 12px;
            }

            .serial-section summary {
                cursor: pointer;
                font-weight: 700;
                font-size: 13px;
            }

            .serial-section[open] summary {
                margin-bottom: 8px;
            }
        </style>
    </head>

    <body>
        <form id="form1" runat="server">
            <div class="status-bar">
                <span>AssetWorx ENNX Live Scan &mdash; SERVER: <%= System.Environment.MachineName %> (<%= Request.ServerVariables["LOCAL_ADDR"] %>)</span>
                <span id="connection-indicator">Checking Connection...</span>
            </div>
            <div class="wrap">

                <div class="top">
                    <div style="flex:1;">
                        <div class="h1" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px;">
                            <span>ENNX Live Scan <span style="font-size:12px; color:#ef4444; border:1px solid rgba(239,68,68,0.4); background:rgba(239,68,68,0.12); padding:2px 8px; border-radius:999px; vertical-align:middle; font-weight:700;">Legacy / Archived</span></span>
                            <div style="display:flex; align-items:center; gap:8px;">
                                <a href="va_ennx_live_scan.aspx" class="btn" style="background:#10b981; color:#fff; font-weight:700; border:1px solid #10b981; text-decoration:none; padding:6px 12px; border-radius:8px; font-size:12px;">&#9654; Switch to Current Version</a>
                                <a href="documentation/va_ennx_live_scan_legacy.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; Legacy Docs</a>
                                <a href="index.aspx" class="nav-pill nav-pill-ghost" style="text-decoration:none; font-size:12px;">&#8962; Hub</a>
                            </div>
                        </div>
                        <div class="sub">Archived original postback ENNX live scanner with WebSerial. Preserved for backward reference.</div>
                    </div>
                </div>
                        <div style="margin-top: 10px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="company-select"
                                onchange="updateStation(this.value)">
                            </asp:DropDownList>

                            <label class="tag" style="cursor:pointer; margin-left: 10px;">
                                <input id="chkScanByEil" type="checkbox" style="transform:scale(1.1)" />
                                <span><b>Scan by EIL</b></span>
                            </label>
                            <asp:DropDownList ID="DdlEIL" runat="server" CssClass="company-select" style="min-width: 100px;" onchange="setTimeout(function(){document.getElementById('scanBox').focus();},50);">
                            </asp:DropDownList>
                        </div>
                    </div>

                    <div class="kpis">
                        <div class="kpi">
                            <div class="n" id="kLocations">0</div>
                            <div class="l">Locations</div>
                        </div>
                        <div class="kpi">
                            <div class="n" id="kAssets">0</div>
                            <div class="l">Assets</div>
                        </div>
                        <div class="kpi">
                            <div class="n" id="kDupes">0</div>
                            <div class="l">Duplicates (skipped)</div>
                        </div>
                    </div>
                </div>

                <asp:Literal ID="LitMsg" runat="server" />

                <div class="row">

                    <!-- SCAN INPUT + CONTROLS -->
                    <div class="panel flex">
                        <div class="btnbar">
                            <button type="button" class="btn primary" onclick="forceNextLocation()">Force Next =
                                Location</button>
                            <button type="button" class="btn" onclick="undoLast()">Undo Last</button>
                            <button type="button" class="btn bad" onclick="clearAll()">Clear All</button>
                            <span class="tag"><b>Station:</b> <span id="tStation"></span></span>
                            <span class="tag"><b>Mode:</b> <span id="tMode"></span></span>
                            <span class="tag"><b>Current:</b> <span id="tLoc" class="mono"></span></span>
                        </div>

                        <div style="margin-top:10px">
                            <input id="scanBox" class="field" autocomplete="off" autocapitalize="off" spellcheck="false"
                                placeholder="Tap here once then scan (ENTER suffix recommended)" />
                            <div class="hint">
                                <b>Detection:</b> If it looks like a location (starts with <span
                                    class="mono">SP</span>), it starts a new block.
                                Otherwise it is treated as an asset under the current location. Use &quot;Force Next =
                                Location&quot; if needed.
                            </div>
                        </div>

                        <div style="margin-top:12px">
                            <label class="tag" style="cursor:pointer">
                                <input id="chkDedup" type="checkbox" checked="checked" style="transform:scale(1.1)" />
                                <span><b>De-dupe assets per location</b></span>
                            </label>
                            <label class="tag" style="cursor:pointer">
                                <input id="chkAutoLocSwitch" type="checkbox" checked="checked"
                                    style="transform:scale(1.1)" />
                                <span><b>Auto switch when scan looks like location</b></span>
                            </label>
                            <label class="tag" style="cursor:pointer">
                                <input id="chkAllowRfidLoc" type="checkbox" style="transform:scale(1.1)" />
                                <span><b>Allow Location via RFID</b></span>
                            </label>
                        </div>

                        <table class="grid" id="tblLog">
                            <thead>
                                <tr>
                                    <th style="width:130px">Time</th>
                                    <th style="width:110px">Type</th>
                                    <th>Value</th>
                                    <th style="width:220px">Note</th>
                                </tr>
                            </thead>
                            <tbody></tbody>
                        </table>

                        <!-- Hidden fields posted to server -->
                        <asp:HiddenField ID="HidJson" runat="server" />
                        <asp:HiddenField ID="HidEnnx" runat="server" />
                        <asp:HiddenField ID="HidStation" runat="server" />
                        <asp:HiddenField ID="HidSummary" runat="server" />
                        <asp:HiddenField ID="HidStartedUtc" runat="server" />
                        <asp:HiddenField ID="HidEndedUtc" runat="server" />
                        <asp:HiddenField ID="HidUser" runat="server" />

                        <div class="btnbar" style="margin-top:12px">
                            <asp:Button ID="BtnDownload" runat="server" CssClass="btn primary" Text="Download ENNX"
                                OnClick="BtnDownload_Click" OnClientClick="return preparePost('download');" />

                            <asp:Button ID="BtnEmail" runat="server" CssClass="btn" Text="Email ENNX"
                                OnClick="BtnEmail_Click" OnClientClick="return preparePost('email');" />

                            <asp:Button ID="BtnSaveSession" runat="server" CssClass="btn good" Text="Save Session (SQL)"
                                OnClick="BtnSaveSession_Click" OnClientClick="return preparePost('save');" />

                            <asp:Button ID="BtnSaveFile" runat="server" CssClass="btn"
                                Text="Save ENNX File (Disk)" OnClick="BtnSaveFile_Click"
                                OnClientClick="return preparePost('file');" />

                            <span class="small" id="postNote"></span>
                        </div>

                        <div class="hint" style="background:rgba(255,255,255,0.02); border:1px solid var(--line); padding:10px; border-radius:8px; margin-top:14px;">
                            <div style="margin-bottom:6px;"><b>Export Options Documentation:</b></div>
                            <ul style="margin:0; padding-left:20px;">
                                <li style="margin-bottom:4px;"><b>Download ENNX:</b> Instantly downloads the compiled .txt file directly to your computer.</li>
                                <li style="margin-bottom:4px;"><b>Email ENNX:</b> Generates and emails the file to the configured system recipients.</li>
                                <li style="margin-bottom:4px;"><b>Save Session (SQL):</b> Stores the raw scan data, ENNX output, user, and timestamps to the <code>EnnxLiveSession</code> database table for historical auditing.</li>
                                <li><b>Save ENNX File (Disk):</b> Automatically saves the file onto the server's hard drive at <code>C:\VA_RFID\ennx_live\saved\</code> for backend processing.</li>
                            </ul>
                        </div>

                        <!-- WebSerial: Connect USB RFID Reader -->
                        <details class="serial-section" id="serialSection">
                            <summary>&#9658; WebSerial &mdash; Connect USB RFID Reader</summary>
                            <div class="btnbar">
                                <button type="button" class="btn primary" id="btnSerialOpen"
                                    onclick="serialOpenClose()">Select/Open Serial Port</button>
                                <button type="button" class="btn bad" id="btnSerialClose" style="display:none"
                                    onclick="serialClose()">Close Port</button>
                                <span class="tag" id="serialStatus"><b>Status:</b> Disconnected</span>
                            </div>
                            <div class="hint" id="serialHint" style="margin-top:6px">
                                WebSerial requires Chrome or Edge served over HTTPS (or localhost).
                                Data arriving on the serial port is processed exactly like keyboard scans.
                            </div>
                        </details>
                    </div>

                    <!-- ENNX PREVIEW -->
                    <div class="panel flex">
                        <div class="btnbar" style="justify-content:space-between">
                            <span class="tag"><b>ENNX Preview</b> <span class="small">(updates live)</span></span>
                            <span class="tag"><b>Last:</b> <span id="tLast" class="mono"></span></span>
                        </div>

                        <textarea id="ennxPreview" class="ta mono" readonly="readonly"></textarea>
                        <div class="hint">
                            Format produced:
                            <div class="mono">ENNX<br />ID<br />SP...<br />512 EE...<br />512 EE...<br />***END***^N
                            </div>
                        </div>
                    </div>
                </div>

                <div class="footer">AssetWorx! by InfinID Technologies &mdash; iDash RFID Integration by ID Integration Inc. &copy; 2026</div>
            </div>

            <script>
                (function () {
                    // --- CONFIG ---
                    const ddl = document.getElementById("<%= DdlCompany.ClientID %>");
                    const SAVED_STATION_KEY   = 'EnnxLive_SelectedStation';
                    const SESSION_STORAGE_KEY = 'EnnxLive_SessionBlocks';

                    // --- STATE ---
                    let station = ddl ? ddl.value : "512";
                    let startedUtc = new Date().toISOString();
                    let currentLocation = "";
                    let forceLoc = true;          // start expecting location
                    let totalLocations = 0;
                    let totalAssets = 0;
                    let dupes = 0;
                    let _isOnline = navigator.onLine;
                    let _probeInFlight = false;

                    // session model:
                    // blocks: [{ location:"SP...", assets:[ "512 EE123", ...], assetSet:{...} }]
                    let blocks = [];
                    let log = []; // [{t,type,val,note}]

                    // --- DOM ---
                    const scanBox = document.getElementById("scanBox");
                    const tblBody = document.querySelector("#tblLog tbody");
                    const ennxPreview = document.getElementById("ennxPreview");
                    const chkDedup = document.getElementById("chkDedup");
                    const chkAutoLocSwitch = document.getElementById("chkAutoLocSwitch");

                    const kLocations = document.getElementById("kLocations");
                    const kAssets = document.getElementById("kAssets");
                    const kDupes = document.getElementById("kDupes");
                    const tStation = document.getElementById("tStation");
                    const tMode = document.getElementById("tMode");
                    const tLoc = document.getElementById("tLoc");
                    const tLast = document.getElementById("tLast");

                    // server hidden fields
                    const HidJson = document.getElementById("<%= HidJson.ClientID %>");
                    const HidEnnx = document.getElementById("<%= HidEnnx.ClientID %>");
                    const HidStation = document.getElementById("<%= HidStation.ClientID %>");
                    const HidSummary = document.getElementById("<%= HidSummary.ClientID %>");
                    const HidStartedUtc = document.getElementById("<%= HidStartedUtc.ClientID %>");
                    const HidEndedUtc = document.getElementById("<%= HidEndedUtc.ClientID %>");

                    // --- PERSISTENCE ---
                    function persistSession() {
                        try {
                            const data = {
                                blocks: blocks.map(function(b) {
                                    return { location: b.location, assets: b.assets.slice(0) };
                                }),
                                station: station,
                                startedUtc: startedUtc,
                                currentLocation: currentLocation,
                                totalLocations: totalLocations,
                                totalAssets: totalAssets,
                                dupes: dupes
                            };
                            localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(data));
                        } catch (e) {}
                    }

                    function restoreSessionIfPresent() {
                        try {
                            const raw = localStorage.getItem(SESSION_STORAGE_KEY);
                            if (!raw) return false;
                            const data = JSON.parse(raw);
                            if (data && data.blocks && data.blocks.length > 0) {
                                blocks = data.blocks;
                                for (let i = 0; i < blocks.length; i++) {
                                    blocks[i].assetSet = {};
                                    for (let j = 0; j < blocks[i].assets.length; j++) {
                                        blocks[i].assetSet[blocks[i].assets[j]] = true;
                                    }
                                }
                                if (data.station) {
                                    station = data.station;
                                    if (ddl) ddl.value = station;
                                }
                                startedUtc = data.startedUtc || new Date().toISOString();
                                currentLocation = data.currentLocation || (blocks.length ? blocks[blocks.length - 1].location : "");
                                totalLocations = data.totalLocations || blocks.length;
                                totalAssets = data.totalAssets || 0;
                                dupes = data.dupes || 0;
                                forceLoc = !currentLocation;
                                addLog("Session", "(restored)", "OK: Restored " + totalLocations + " location(s), " + totalAssets + " asset(s) from local cache");
                                rebuildPreview();
                                return true;
                            }
                        } catch (e) {}
                        return false;
                    }

                    function restoreStation() {
                        const saved = localStorage.getItem(SAVED_STATION_KEY);
                        if (saved && ddl) {
                            for (let i = 0; i < ddl.options.length; i++) {
                                if (ddl.options[i].value === saved) {
                                    ddl.selectedIndex = i;
                                    station = saved;
                                    break;
                                }
                            }
                        }
                    }

                    // --- ACTIVE DUAL-LAYER CONNECTIVITY PROBE ---
                    function probeConnectivity() {
                        if (_probeInFlight) return Promise.resolve(_isOnline);
                        _probeInFlight = true;
                        return new Promise(function(resolve) {
                            var xhr = new XMLHttpRequest();
                            xhr.timeout = 3000;
                            xhr.open('HEAD', 'va_ennx_live_scan.aspx?_nocache=' + Date.now(), true);
                            xhr.onload = function() {
                                _probeInFlight = false;
                                resolve(xhr.status >= 200 && xhr.status < 400);
                            };
                            xhr.onerror = function() { _probeInFlight = false; resolve(false); };
                            xhr.ontimeout = function() { _probeInFlight = false; resolve(false); };
                            try { xhr.send(); } catch(e) { _probeInFlight = false; resolve(false); }
                        });
                    }

                    function updateIndicator(online) {
                        _isOnline = online;
                        const indicator = document.getElementById('connection-indicator');
                        if (!indicator) return;
                        if (online) {
                            indicator.innerHTML = '&bull; CONNECTED';
                            indicator.style.color = '#10b981';
                        } else {
                            indicator.innerHTML = '&bull; OFFLINE &mdash; Operating Locally (Direct Download Available)';
                            indicator.style.color = '#ef4444';
                        }
                    }

                    function checkConnectivity() {
                        probeConnectivity().then(function(online) {
                            updateIndicator(online);
                        });
                    }

                    window.addEventListener('online', checkConnectivity);
                    window.addEventListener('offline', function() { updateIndicator(false); });
                    checkConnectivity();
                    setInterval(checkConnectivity, 4000);

                    // --- HELPERS ---
                    function nowLocal() {
                        const d = new Date();
                        return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
                    }
                    function clean(s) {
                        return (s || "").trim().replace(/\s+/g, " ");
                    }
                    function upper(s) { return clean(s).toUpperCase(); }

                    function looksLikeLocation(raw) {
                        const s = upper(raw);
                        if (s.startsWith("SP") && !s.includes("EE")) return true;
                        return false;
                    }

                    function normalizeLocation(raw) {
                        return upper(raw).replace(/F+$/, "");
                    }

                    // Detect EPC-ish reads and ignore them silently
                    function isEpcLike(raw) {
                        const s = upper(raw).replace(/F+$/, "");

                        // If it already looks like a valid EE asset line, it's not EPC-like
                        if (/^(\d{3})\s*EE\s*\w+$/i.test(s)) return false;
                        if (/^(\d{3})EE\w+$/i.test(s)) return false;
                        if (/^EE\s*\w+$/i.test(s)) return false;

                        // Hex-only, likely EPC. Allow slightly shorter too (first-read truncations)
                        if (/^[0-9A-F]+$/.test(s) && s.length >= 12) return true;

                        return false;
                    }

                    function normalizeAssetLine(raw) {
                        let s = upper(raw);

                        // 1) Strip trailing EPC padding F's ONLY
                        s = s.replace(/F+$/, "");

                        // 2) If it still looks like raw EPC hex, ignore
                        if (/^[0-9A-F]{12,64}$/.test(s)) {
                            return null;
                        }

                        // 3) Normalize valid EE asset formats (including alphanumeric suffixes e.g. 512 EE12345A)

                        // "512 EE18193" or "512 EE 18193" or "512 EE12345A"
                        let m = s.match(/^(\d{3})\s*EE\s*(\w+)$/i);
                        if (m) return `${m[1]} EE${m[2].toUpperCase()}`;

                        // "EE18193" or "EE 18193" or "EE12345A"
                        m = s.match(/^EE\s*(\w+)$/i);
                        if (m) return `${station} EE${m[1].toUpperCase()}`;

                        // "512EE18193" or "512EE12345A"
                        m = s.match(/^(\d{3})EE(\w+)$/i);
                        if (m) return `${m[1]} EE${m[2].toUpperCase()}`;

                        return null;
                    }

                    function currentBlock() {
                        if (!blocks.length) return null;
                        return blocks[blocks.length - 1];
                    }

                    function addLog(type, val, note) {
                        const item = { t: nowLocal(), type, val, note: note || "" };
                        log.unshift(item);
                        if (log.length > 25) log.pop();
                        renderLog();
                    }

                    function renderLog() {
                        tblBody.innerHTML = "";
                        for (const r of log) {
                            const tr = document.createElement("tr");
                            tr.innerHTML = `
                <td class="mono">${escapeHtml(r.t)}</td>
                <td><span class="tag"><b>${escapeHtml(r.type)}</b></span></td>
                <td class="mono">${escapeHtml(r.val)}</td>
                <td>${formatNote(r.note)}</td>
            `;
                            tblBody.appendChild(tr);
                        }
                    }

                    function formatNote(note) {
                        if (!note) return "";
                        const s = String(note);
                        if (s.startsWith("ERR:")) return `<span class="err">${escapeHtml(s)}</span>`;
                        if (s.startsWith("WARN:")) return `<span class="warn">${escapeHtml(s)}</span>`;
                        if (s.startsWith("OK:")) return `<span class="ok">${escapeHtml(s)}</span>`;
                        return escapeHtml(s);
                    }

                    function escapeHtml(s) {
                        return String(s)
                            .replaceAll("&", "&amp;")
                            .replaceAll("<", "&lt;")
                            .replaceAll(">", "&gt;")
                            .replaceAll('"', "&quot;")
                            .replaceAll("'", "&#39;");
                    }

                    // Build ENNX text exactly once (used by preview + post)
                    function buildEnnxText() {
                        let lines = ["ENNX", "ID"];

                        for (const b of blocks) {
                            lines.push(b.location);
                            for (const a of b.assets) {
                                lines.push(a);
                            }
                        }

                        const count = lines.length - 2;
                        lines.push(`***END***^${count}`);

                        return lines.join("\r\n");
                    }

                    function rebuildPreview() {
                        ennxPreview.value = buildEnnxText();

                        kLocations.textContent = totalLocations;
                        kAssets.textContent = totalAssets;
                        kDupes.textContent = dupes;

                        tStation.textContent = station;
                        tMode.textContent = forceLoc ? "Need Location" : "Scanning Assets";
                        tLoc.textContent = currentLocation || "(none)";
                    }

                    function setLocation(raw) {
                        const s = upper(raw);
                        if (s.includes("EE")) {
                            addLog("Location", raw, "ERR: Location barcode cannot contain 'EE' (equipment tag)");
                            return;
                        }
                        const loc = normalizeLocation(raw);
                        if (!loc) {
                            addLog("Location", raw, "ERR: Empty location");
                            return;
                        }

                        currentLocation = loc;
                        forceLoc = false;

                        blocks.push({ location: loc, assets: [], assetSet: {} });
                        totalLocations++;

                        addLog("Location", loc, "OK: Started new block");
                        tLast.textContent = loc;
                        persistSession();
                        rebuildPreview();
                    }

                    function addAsset(raw) {
                        if (!currentLocation) {
                            addLog("Asset", raw, "WARN: No location set. Scan a location first.");
                            forceLoc = true;
                            rebuildPreview();
                            return;
                        }

                        const line = normalizeAssetLine(raw);

                        // SILENT IGNORE: EPC-ish or unrecognized first-read junk
                        if (!line) {
                            if (isEpcLike(raw)) return;   // do nothing at all
                            addLog("Asset", raw, "ERR: Unrecognized asset format.");
                            return;
                        }

                        const b = currentBlock();
                        if (!b) {
                            addLog("Asset", raw, "ERR: Internal: missing block");
                            return;
                        }

                        const chkEil = document.getElementById("chkScanByEil");
                        const ddlEIL = document.getElementById("<%= DdlEIL.ClientID %>");
                        const isEilFilterActive = chkEil && chkEil.checked && ddlEIL && ddlEIL.value !== "All";

                        if (isEilFilterActive) {
                            const expectedEil = ddlEIL.value;
                            
                            fetch('va_ennx_live_scan.aspx/CheckAssetEIL', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ assetName: line })
                            })
                            .then(res => res.json())
                            .then(data => {
                                const actualEil = data.d;
                                if (actualEil === expectedEil) {
                                    finalizeAddAsset(line, b);
                                } else {
                                    addLog("Asset", line, "WARN: Skipped. EIL mismatch (" + (actualEil || "none") + ")");
                                }
                            })
                            .catch(err => {
                                addLog("Asset", line, "ERR: Check EIL failed");
                            });
                        } else {
                            finalizeAddAsset(line, b);
                        }
                    }

                    function finalizeAddAsset(line, b) {
                        const key = line; // already normalized
                        if (chkDedup.checked && b.assetSet[key]) {
                            dupes++;
                            addLog("Asset", line, "WARN: Duplicate (skipped)");
                            rebuildPreview();
                            return;
                        }

                        b.assets.push(line);
                        b.assetSet[key] = true;
                        totalAssets++;

                        // Station prefix mismatch warning
                        const scanPrefix = line.length >= 3 ? line.substring(0, 3) : "";
                        if (/^\d{3}$/.test(scanPrefix) && scanPrefix !== station) {
                            addLog("Asset", line, "WARN: Station prefix mismatch (asset " + scanPrefix + " vs selected " + station + ")");
                        } else {
                            addLog("Asset", line, "OK: Added");
                        }
                        tLast.textContent = line;
                        persistSession();
                        rebuildPreview();
                    }

                    function handleScan(raw) {
                        const s = clean(raw);
                        if (!s) return;

                        const isRfid = (/F{2,}$/.test(upper(raw)) || isEpcLike(s));
                        const allowRfidLoc = document.getElementById("chkAllowRfidLoc") ? document.getElementById("chkAllowRfidLoc").checked : false;

                        if (forceLoc) {
                            if (isRfid && !allowRfidLoc) {
                                if (looksLikeLocation(s)) {
                                    addLog("Location", s, "WARN: Location must be barcode. Ignored RFID.");
                                }
                                return;
                            }
                            setLocation(s);
                            return;
                        }

                        if (chkAutoLocSwitch.checked && looksLikeLocation(s)) {
                            if (isRfid && !allowRfidLoc) {
                                return; // Silent ignore accidental RFID read of location tag
                            }
                            setLocation(s);
                            return;
                        }

                        // âœ&hellip; SILENT IGNORE: EPC-ish scans (first RFID read)
                        if (isEpcLike(s)) {
                            return; // absolutely nothing added/logged
                        }

                        addAsset(s);
                    }

                    // --- PUBLIC BUTTONS ---
                    window.updateStation = function (val) {
                        station = val;
                        tStation.textContent = station;
                        try { localStorage.setItem(SAVED_STATION_KEY, val); } catch (e) {}
                        persistSession();
                        addLog("Station", val, "OK: Station changed");
                        rebuildPreview();
                        reloadEILDropdown(val);
                        focusScanBox();
                    };

                    function reloadEILDropdown(stationCode) {
                        var ddlEIL = document.getElementById("<%= DdlEIL.ClientID %>");
                        if (!ddlEIL) return;
                        fetch('va_ennx_live_scan.aspx/GetEILByStation', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ stationCode: stationCode })
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(data) {
                            var items = data.d || [];
                            var html = '<option value="All">All</option>';
                            items.forEach(function(v) {
                                html += '<option value="' + v.replace(/"/g, '&quot;') + '">' + v + '</option>';
                            });
                            ddlEIL.innerHTML = html;
                        })
                        .catch(function() {});
                    }

                    window.forceNextLocation = function () {
                        forceLoc = true;
                        addLog("Mode", "(force)", "OK: Next scan will be location");
                        rebuildPreview();
                        focusScanBox();
                    }

                    window.undoLast = function () {
                        if (!log.length) {
                            addLog("Undo", "(none)", "WARN: Nothing to undo");
                            return;
                        }

                        const lastOk = log.find(x => (x.note || "").startsWith("OK:"));
                        if (!lastOk) {
                            addLog("Undo", "(none)", "WARN: Nothing to undo");
                            return;
                        }

                        if (lastOk.type === "Asset") {
                            const b = currentBlock();
                            if (b && b.assets.length) {
                                const removed = b.assets.pop();
                                delete b.assetSet[removed];
                                totalAssets = Math.max(0, totalAssets - 1);
                                addLog("Undo", removed, "OK: Removed last asset");
                            } else {
                                addLog("Undo", "(asset)", "WARN: No asset to remove");
                            }
                        }
                        else if (lastOk.type === "Location") {
                            if (blocks.length) {
                                const removedBlock = blocks.pop();
                                totalLocations = Math.max(0, totalLocations - 1);
                                totalAssets = Math.max(0, totalAssets - (removedBlock.assets ? removedBlock.assets.length : 0));
                                currentLocation = blocks.length ? blocks[blocks.length - 1].location : "";
                                forceLoc = !currentLocation;
                                addLog("Undo", removedBlock.location, "OK: Removed last location block");
                            } else {
                                addLog("Undo", "(location)", "WARN: No location block to remove");
                            }
                        } else {
                            addLog("Undo", "(skip)", "WARN: Last actionable item not found");
                        }

                        persistSession();
                        rebuildPreview();
                        focusScanBox();
                    }

                    window.clearAll = function () {
                        if (!confirm("Clear everything for this session?")) return;
                        blocks = [];
                        log = [];
                        currentLocation = "";
                        forceLoc = true;
                        totalLocations = 0;
                        totalAssets = 0;
                        dupes = 0;
                        startedUtc = new Date().toISOString();
                        try { localStorage.removeItem(SESSION_STORAGE_KEY); } catch (e) {}
                        addLog("Clear", "(all)", "OK: Cleared session");
                        rebuildPreview();
                        focusScanBox();
                    }

                    function focusScanBox() {
                        try { scanBox.focus(); } catch (e) { }
                    }

                    // --- INPUT CAPTURE ---
                    scanBox.addEventListener("keydown", function (ev) {
                        if (ev.key === "Enter") {
                            ev.preventDefault();
                            const val = scanBox.value;
                            scanBox.value = "";
                            handleScan(val);
                        }
                    });

                    // Keep focus (field use)
                    document.addEventListener("click", function (ev) {
                        const tg = ev.target;
                        if (tg && (tg.tagName === "SELECT" || tg.tagName === "OPTION"
                            || tg.tagName === "SUMMARY" || tg.tagName === "BUTTON")) {
                            return; // allow user to interact with dropdowns, serial section, buttons
                        }
                        setTimeout(focusScanBox, 50);
                    });
                    
                    setInterval(function () {
                        const ae = document.activeElement;
                        let stealingAllowed = true;
                        if (ae && (ae.tagName === "SELECT" || ae.tagName === "SUMMARY")) {
                            stealingAllowed = false; // Don't steal if they are looking at a dropdown or serial section
                        }
                        if (document.activeElement !== scanBox && stealingAllowed) {
                            focusScanBox();
                        }
                    }, 1200);

                    // --- POST PREP ---
                    window.preparePost = function (kind) {
                        // Direct Client Download (Works 100% offline with zero server dependency)
                        if (kind === 'download') {
                            const ennx = buildEnnxText();
                            if (totalLocations === 0 || !ennx) {
                                alert("No locations scanned yet.");
                                return false;
                            }
                            const safeStation = station || "site";
                            const d = new Date();
                            const stamp = d.getFullYear() +
                                String(d.getMonth() + 1).padStart(2, '0') +
                                String(d.getDate()).padStart(2, '0') + "_" +
                                String(d.getHours()).padStart(2, '0') +
                                String(d.getMinutes()).padStart(2, '0') +
                                String(d.getSeconds()).padStart(2, '0');
                            const fname = "ennx_live_" + safeStation + "_" + stamp + ".txt";
                            const blob = new Blob([ennx], { type: "text/plain;charset=utf-8" });
                            const url = URL.createObjectURL(blob);
                            const a = document.createElement("a");
                            a.href = url;
                            a.download = fname;
                            document.body.appendChild(a);
                            a.click();
                            document.body.removeChild(a);
                            URL.revokeObjectURL(url);
                            addLog("Download", fname, "OK: Downloaded file locally to device");
                            return false; // Crucial: prevents server postback so it never fails offline!
                        }

                        // Offline guards for server-dependent actions
                        if (!_isOnline || !navigator.onLine) {
                            alert("You are currently OFFLINE.\n\n" +
                                (kind === 'email' ? "Emailing" : "Saving to the server/SQL") +
                                " requires an active network connection to the server.\n\n" +
                                "Please use 'Download ENNX' to save your file directly to your device, or wait until network connection is restored.");
                            return false;
                        }

                        const endedUtc = new Date().toISOString();

                        const payload = {
                            station: station,
                            startedUtc: startedUtc,
                            endedUtc: endedUtc,
                            locations: blocks.map(b => ({
                                location: b.location,
                                assets: b.assets.slice(0)
                            })),
                            totals: {
                                locations: totalLocations,
                                assets: totalAssets,
                                dupesSkipped: dupes
                            }
                        };

                        const ennx = buildEnnxText();

                        HidJson.value = JSON.stringify(payload);
                        HidEnnx.value = ennx;
                        HidStation.value = station;
                        HidStartedUtc.value = startedUtc;
                        HidEndedUtc.value = endedUtc;
                        HidSummary.value = `Locations=${totalLocations}; Assets=${totalAssets}; DupesSkipped=${dupes}`;

                        if (totalLocations === 0) {
                            alert("No locations scanned yet.");
                            return false;
                        }
                        return true;
                    }

                    // --- WEBSERIAL: USB RFID READER SUPPORT ---
                    let serialPort = null;
                    let serialReader = null;
                    let serialKeepReading = false;
                    let serialBuffer = '';

                    window.serialOpenClose = async function () {
                        if (!('serial' in navigator)) {
                            document.getElementById('serialStatus').innerHTML = '<b>Status:</b> <span class="err">Not Available</span>';
                            document.getElementById('serialHint').innerHTML = '<span class="err"><b>WebSerial not available.</b> Requires Chrome or Edge, served over HTTPS (or localhost). Keyboard/DataWedge input still works normally.</span>';
                            return;
                        }

                        try {
                            serialPort = await navigator.serial.requestPort();
                            await serialPort.open({
                                baudRate: 115200,
                                bufferSize: 1024,
                                dataBits: 8,
                                flowControl: 'hardware',
                                parity: 'none',
                                stopBits: 1
                            });

                            serialKeepReading = true;
                            document.getElementById('btnSerialOpen').style.display = 'none';
                            document.getElementById('btnSerialClose').style.display = '';
                            document.getElementById('serialStatus').innerHTML = '<b>Status:</b> <span class="ok">Connected</span>';
                            addLog('Serial', 'Port', 'OK: Serial port opened');

                            const textDecoder = new TextDecoderStream();
                            const readableStreamClosed = serialPort.readable.pipeTo(textDecoder.writable);
                            serialReader = textDecoder.readable.getReader();

                            try {
                                while (serialKeepReading) {
                                    const { value, done } = await serialReader.read();
                                    if (done) break;
                                    // Buffer serial data and process on newlines
                                    serialBuffer += value;
                                    let lines = serialBuffer.split('\n');
                                    serialBuffer = lines.pop(); // keep incomplete line in buffer
                                    for (const line of lines) {
                                        const trimmed = line.replace(/\r/g, '').trim();
                                        if (trimmed) handleScan(trimmed);
                                    }
                                }
                            } catch (err) {
                                addLog('Serial', 'Read', 'ERR: ' + err.message);
                            } finally {
                                serialReader.releaseLock();
                                await readableStreamClosed.catch(function () { });
                            }

                            await serialPort.close();
                            serialPort = null;
                            document.getElementById('btnSerialOpen').style.display = '';
                            document.getElementById('btnSerialClose').style.display = 'none';
                            document.getElementById('serialStatus').innerHTML = '<b>Status:</b> Disconnected';
                            addLog('Serial', 'Port', 'OK: Serial port closed');

                        } catch (err) {
                            addLog('Serial', 'Port', 'ERR: ' + err.message);
                        }
                    };

                    window.serialClose = async function () {
                        serialKeepReading = false;
                        if (serialReader) {
                            try { await serialReader.cancel(); } catch (e) { }
                        }
                    };

                    // init
                    restoreStation();
                    if (!restoreSessionIfPresent()) {
                        rebuildPreview();
                    }
                    focusScanBox();
                })();
            </script>

        </form>
    </body>

    </html>
