<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_eil_live_scan_legacy.aspx.cs" Inherits="va_eil_live_scan_legacy" %>

    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">

    <head runat="server">
        <meta charset="utf-8" />
        <title>EIL Live Scan &amp; Reconciliation</title>
            <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />
        <script>
            if ('serviceWorker' in navigator) {
                navigator.serviceWorker.register('sw.js');
            }
        </script>

        <style>
            body {
                margin: 0;
                background: var(--bg);
                color: var(--text);
                font-family: 'Segoe UI', system-ui, Arial, sans-serif;
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
                box-shadow: var(--shadow);
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
                border-color: color-mix(in srgb, var(--accent), transparent 55%);
                box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent), transparent 92%) inset
            }

            .btn.good {
                border-color: color-mix(in srgb, var(--accent-2), transparent 55%);
                box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent-2), transparent 92%) inset
            }

            .btn.bad {
                border-color: color-mix(in srgb, var(--danger), transparent 55%);
                box-shadow: 0 0 0 2px color-mix(in srgb, var(--danger), transparent 92%) inset
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
                color: var(--warn)
            }

            .err {
                color: var(--danger)
            }

            .ok {
                color: var(--accent-2)
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

            /* Light mode refinements */
            [data-theme="light"] .panel{box-shadow:0 1px 3px rgb(0 0 0 / 0.04), 0 2px 8px rgb(0 0 0 / 0.03);}
            [data-theme="light"] .kpi{background:var(--chip);border-color:var(--line);}
            [data-theme="light"] .btn{border-color:var(--line);}
            [data-theme="light"] .field, [data-theme="light"] .ta{background:var(--card);border-color:var(--line);}
            [data-theme="light"] .field:focus{border-color:var(--accent);}
            [data-theme="light"] .company-select{background:var(--card);border-color:var(--line);}
            [data-theme="light"] .grid th{background:var(--chip);}
        </style>
    </head>

    <body>
        <form id="form1" runat="server">
            <div class="status-bar">
                <span>AssetWorx EIL Live Scan &mdash; SERVER: <%= System.Environment.MachineName %> (<%= Request.ServerVariables["LOCAL_ADDR"] %>)</span>
                <span id="connection-indicator">Checking Connection...</span>
            </div>
            <div class="wrap">

                <div class="top">
                    <div>
                        <div class="h1" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px;">
                            <span>EIL Live Scan &amp; Reconciliation <span style="font-size:12px; color:#ef4444; border:1px solid rgba(239,68,68,0.4); background:rgba(239,68,68,0.12); padding:2px 8px; border-radius:999px; vertical-align:middle; font-weight:700;">Legacy / Archived</span></span>
                            <div style="display:flex; align-items:center; gap:8px;">
                                <a href="va_eil_live_scan.aspx" class="btn" style="background:#10b981; color:#fff; font-weight:700; border:1px solid #10b981; text-decoration:none; padding:6px 12px; border-radius:8px; font-size:12px;">&#9654; Switch to Current Version</a>
                                <a href="documentation/va_eil_live_scan_legacy.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; Legacy Docs</a>
                                <a href="index.aspx" class="nav-pill nav-pill-ghost" style="text-decoration:none; font-size:12px;">&#8962; Hub</a>
                            </div>
                        </div>
                        <div class="sub">Archived original postback EIL scanner with WebSerial. Preserved for backward reference.</div>
                        <div style="margin-top: 10px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="company-select"
                                onchange="updateStation(this.value)">
                            </asp:DropDownList>

                            <input list="eilDataList" id="eilSearch" class="company-select" placeholder="Type EIL... (Search)" style="min-width: 160px;" autocomplete="off" />
                            <datalist id="eilDataList"></datalist>
                            <asp:DropDownList ID="DdlEIL" runat="server" style="display:none;"></asp:DropDownList>
                            <button type="button" id="btnLoadEil" class="btn primary" onclick="fetchEilAssets(); setTimeout(function(){document.getElementById('scanBox').focus();},50);" style="padding: 6px 12px; min-width: 130px;">Load EIL Assets</button>
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
                                placeholder="1. Barcode scan location before scanning" />
                            <div class="hint">
                                <b>Detection:</b> If it looks like a location (starts with <span
                                    class="mono">SP</span>), it starts a new block.
                                Otherwise it&rsquo;s treated as an asset under the current location. Use &ldquo;Force Next =
                                Location&rdquo; if needed.
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

                            </tbody>
                        </table>

                        <!-- Hidden fields posted to server -->
                        <asp:HiddenField ID="HidJson" runat="server" />
                        <asp:HiddenField ID="HidEnnx" runat="server" />
                        <asp:HiddenField ID="HidStation" runat="server" />
                        <asp:HiddenField ID="HidSummary" runat="server" />
                        <asp:HiddenField ID="HidStartedUtc" runat="server" />
                        <asp:HiddenField ID="HidEndedUtc" runat="server" />
                        <asp:HiddenField ID="HidGridJson" runat="server" /> <!-- Custom for EIL -->
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
                    <div class="panel flex" style="min-width: 320px;">
                        <div class="btnbar" style="justify-content:space-between">
                            <span class="tag"><b>ENNX Preview</b></span>
                        </div>
                        <textarea id="ennxPreview" class="ta mono" readonly="readonly" style="min-height:220px;"></textarea>
                    </div>

                    <!-- EIL ASSETS CHECKLIST -->
                    <div class="panel" style="flex: 100%; min-width: 100%;">
                        <div class="btnbar" style="margin-bottom: 10px; justify-content:space-between">
                            <span class="tag"><b>EIL Assets</b> <span id="kPending">0</span> pending / <span id="kScanned">0</span> scanned</span>
                        </div>
                        <div style="overflow-x:auto;">
                            <table class="grid" id="tblEilAssets">
                                <thead>
                                    <tr>
                                        <th>EE Number</th>
                                        <th>Asset Name</th>
                                        <th>Previous Location</th>
                                        <th>Current System Location</th>
                                        <th>New Location</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="footer">AssetWorx! by InfinID Technologies &mdash; iDash RFID Integration by ID Integration Inc. &copy; 2026</div>
            </div>

            <script>
                (function () {
                    // --- INIT SEARCH UI ---
                    window.addEventListener('DOMContentLoaded', function() {
                        var ddl = document.getElementById("<%= DdlEIL.ClientID %>");
                        var list = document.getElementById("eilDataList");
                        if (ddl && list) {
                            for(var i=0; i<ddl.options.length; i++) {
                                var opt = document.createElement('option');
                                opt.value = ddl.options[i].value;
                                list.appendChild(opt);
                            }
                        }
                    });

                    // --- CONFIG ---
                    const ddl = document.getElementById("<%= DdlCompany.ClientID %>");

                    // --- STATE ---
                    let station = ddl ? ddl.value : "512";
                    let startedUtc = new Date().toISOString();
                    let currentLocation = "";
                    let forceLoc = true;          // start expecting location
                    let totalLocations = 0;
                    let totalAssets = 0;
                    let dupes = 0;

                    // session model:
                    // blocks: [{ location:"SP...", assets:[ "512 EE123", ...], assetSet:{...} }]
                    let blocks = [];
                    let log = []; // [{t,type,val,note}]
                    let eilGridData = []; // [{EENumber, Name, LastLocation, CurrentLocation, NewLocation, Status}]

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
                    const HidGridJson = document.getElementById("<%= HidGridJson.ClientID %>");

                    // --- STATUS BAR ---
                    function checkConnectivity() {
                        const indicator = document.getElementById('connection-indicator');
                        if (!indicator) return;
                        const online = navigator.onLine;
                        if (online) {
                            indicator.innerHTML = '&bull; CONNECTED';
                            indicator.style.color = '#10b981';
                        } else {
                            indicator.innerHTML = '&bull; OFFLINE (Operating from loaded EIL cache)';
                            indicator.style.color = '#ef4444';
                        }
                    }

                    window.addEventListener('online', checkConnectivity);
                    window.addEventListener('offline', checkConnectivity);
                    checkConnectivity();

                    // --- HELPERS ---
                    window.fetchEilAssets = function() {
                        const eil = document.getElementById("eilSearch").value || "All";
                        const btn = document.getElementById("btnLoadEil");

                        if (!eil || eil === 'All') {
                            eilGridData = [];
                            renderEilGrid();
                            if (btn) { btn.innerHTML = "Load EIL Assets"; btn.classList.remove("good", "bad"); btn.classList.add("primary"); }
                            return;
                        }

                        if (btn) { btn.innerHTML = "Loading..."; btn.classList.remove("good", "bad"); btn.classList.add("primary"); }

                        fetch('va_eil_live_scan.aspx/LoadEilAssets', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ 
                                eil: eil, 
                                stationCode: station 
                            })
                        })
                        .then(r => r.json())
                        .then(res => {
                            eilGridData = res.d || [];
                            renderEilGrid();
                            addLog("Load", eil, "OK: Loaded " + eilGridData.length + " assets for EIL");
                            if (btn) { btn.innerHTML = "&#10003; Loaded " + eilGridData.length; btn.classList.remove("primary", "bad"); btn.classList.add("good"); }
                        })
                        .catch(err => {
                            addLog("Load", eil, "ERR: Failed to load parts list");
                            if (btn) { btn.innerHTML = "Error Loading"; btn.classList.remove("primary", "good"); btn.classList.add("bad"); }
                        });
                    }

                    function renderEilGrid() {
                        const tbody = document.querySelector("#tblEilAssets tbody");
                        tbody.innerHTML = "";
                        let scannedCount = 0;
                        for (let r of eilGridData) {
                            if (r.Status === "Scanned") scannedCount++;
                            let tr = document.createElement("tr");
                            tr.innerHTML = `
                                <td>${escapeHtml(r.EENumber)}</td>
                                <td>${escapeHtml(r.Name)}</td>
                                <td>${escapeHtml(r.LastLocation)}</td>
                                <td>${escapeHtml(r.CurrentLocation)}</td>
                                <td>${escapeHtml(r.NewLocation)}</td>
                                <td><span class="tag ${r.Status === 'Scanned' ? 'good' : ''}"><b>${escapeHtml(r.Status)}</b></span></td>
                            `;
                            tbody.appendChild(tr);
                        }
                        document.getElementById("kScanned").textContent = scannedCount;
                        document.getElementById("kPending").textContent = Math.max(0, eilGridData.length - scannedCount);
                        HidGridJson.value = JSON.stringify(eilGridData);
                    }

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
                        if (s.startsWith("SP")) return true;
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

                        // 3) Normalize valid EE asset formats ONLY

                        // "512 EE18193" or "512 EE 18193" or "512 EE18193A"
                        let m = s.match(/^(\d{3})\s*EE\s*(\w+)$/);
                        if (m) {
                            if (m[1] !== station) {
                                addLog("Asset", raw, "WARN: Scanned prefix (" + m[1] + ") does not match site " + station);
                            }
                            return `${m[1]} EE${m[2]}`;
                        }

                        // "EE18193" or "EE 18193"
                        m = s.match(/^EE\s*(\w+)$/);
                        if (m) return `${station} EE${m[1]}`;

                        // "512EE18193"
                        m = s.match(/^(\d{3})EE(\w+)$/);
                        if (m) {
                            if (m[1] !== station) {
                                addLog("Asset", raw, "WARN: Scanned prefix (" + m[1] + ") does not match site " + station);
                            }
                            return `${m[1]} EE${m[2]}`;
                        }

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
                            let validAssets = [];
                            for (const a of b.assets) {
                                if (eilGridData.length > 0) {
                                    // IF EIL is populated, ONLY export items that match the EIL!
                                    let found = false;
                                    for (let i = 0; i < eilGridData.length; i++) {
                                        if (eilGridData[i].EENumber === a || eilGridData[i].Name === a || a.endsWith(" " + eilGridData[i].EENumber) || ("512 " + eilGridData[i].EENumber) === a) {
                                            found = true; 
                                            break;
                                        }
                                    }
                                    if (found) validAssets.push(a);
                                } else {
                                    validAssets.push(a);
                                }
                            }
                            
                            // Only include location if we actually have valid assets inside it
                            if (validAssets.length > 0) {
                                lines.push(b.location);
                                for (const va of validAssets) lines.push(va);
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
                        const loc = normalizeLocation(raw);
                        if (!loc || !looksLikeLocation(loc) || /EE/.test(loc)) {
                            addLog("Location", raw, "ERR: Invalid Location. Must barcode scan an SP location.");
                            return;
                        }

                        currentLocation = loc;
                        forceLoc = false;

                        blocks.push({ location: loc, assets: [], assetSet: {} });
                        totalLocations++;

                        addLog("Location", loc, "OK: Started new block");
                        tLast.textContent = loc;
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

                        // If false, it's explicitly rejected (e.g. cross-site) and already logged
                        if (line === false) return;

                        // âœ&hellip; SILENT IGNORE: EPC-ish or unrecognized first-read junk
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

                        let matchFound = false;
                        if (eilGridData.length > 0) {
                            for (let i = 0; i < eilGridData.length; i++) {
                                // Extract the EE/number part simply or exact match
                                if (eilGridData[i].EENumber === line || eilGridData[i].Name === line || line.endsWith(" " + eilGridData[i].EENumber) || ("512 " + eilGridData[i].EENumber) === line) {
                                    if (eilGridData[i].Status !== "Scanned") {
                                        eilGridData[i].Status = "Scanned";
                                        eilGridData[i].NewLocation = currentLocation;
                                    }
                                    matchFound = true;
                                    break;
                                }
                            }
                            renderEilGrid();
                        }

                        if (eilGridData.length > 0 && !matchFound) {
                            addLog("Asset", line, "WARN: Scanned asset not in EIL list!");
                        }

                        finalizeAddAsset(line, b);
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

                        addLog("Asset", line, "OK: Added");
                        if (document.getElementById("tLast")) document.getElementById("tLast").textContent = line;
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

                        // SILENT IGNORE: EPC-ish scans (first RFID read)
                        if (isEpcLike(s)) {
                            return; // absolutely nothing added/logged
                        }

                        addAsset(s);
                    }

                    // --- PUBLIC BUTTONS ---
                    window.updateStation = function (val) {
                        station = val;
                        tStation.textContent = station;
                        addLog("Station", val, "OK: Station changed");
                        rebuildPreview();
                        focusScanBox();

                        // Sync new EIL array seamlessly over JSON directly from SQL securely
                        const searchBox = document.getElementById("eilSearch");
                        const list = document.getElementById("eilDataList");
                        if(searchBox) searchBox.value = "";
                        if(list) list.innerHTML = "";
                        
                        fetch('va_eil_live_scan.aspx/GetEilsForStation', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ stationCode: val })
                        })
                        .then(r => r.json())
                        .then(res => {
                            const eils = res.d || [];
                            if (list) {
                                for(let i=0; i<eils.length; i++) {
                                    let opt = document.createElement('option');
                                    opt.value = eils[i];
                                    list.appendChild(opt);
                                }
                            }
                        })
                        .catch(err => console.error("EIL Array Sync Failed", err));
                    };

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

                        rebuildPreview();
                        focusScanBox();
                    }

                    window.clearAll = function () {
                        if (!confirm("Clear everything for this session?")) return;
                        blocks = [];
                        log = [];
                        eilGridData = [];
                        currentLocation = "";
                        forceLoc = true;
                        totalLocations = 0;
                        totalAssets = 0;
                        dupes = 0;
                        startedUtc = new Date().toISOString();
                        addLog("Clear", "(all)", "OK: Cleared session");
                        renderEilGrid();
                        rebuildPreview();
                        focusScanBox();
                        const btn = document.getElementById("btnLoadEil");
                        if (btn) { btn.innerHTML = "Load EIL Assets"; btn.classList.remove("good", "bad"); btn.classList.add("primary"); }
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
                        if (tg && (tg.tagName === "SELECT" || tg.tagName === "OPTION" || tg.id === "eilSearch"
                            || tg.tagName === "SUMMARY" || tg.tagName === "BUTTON")) {
                            return; // allow user to interact with dropdowns, search inputs, serial section, buttons
                        }
                        setTimeout(focusScanBox, 50);
                    });
                    
                    setInterval(function () {
                        const ae = document.activeElement;
                        let stealingAllowed = true;
                        if (ae && (ae.tagName === "SELECT" || ae.id === "eilSearch" || ae.tagName === "SUMMARY")) {
                            stealingAllowed = false; // Don't steal if they are looking at a dropdown, search box, or serial section
                        }
                        if (document.activeElement !== scanBox && stealingAllowed) {
                            focusScanBox();
                        }
                    }, 1200);

                    // --- POST PREP ---
                    window.preparePost = function (kind) {
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

                        // Client-side Blob download (zero server dependency & offline-safe)
                        if (kind === 'download') {
                            const blob = new Blob([ennx], { type: "text/plain;charset=utf-8" });
                            const link = document.createElement("a");
                            link.href = URL.createObjectURL(blob);
                            link.download = "ENNX_" + (station || "VA") + "_" + (new Date().toISOString().replace(/[:.]/g, "-")) + ".txt";
                            document.body.appendChild(link);
                            link.click();
                            document.body.removeChild(link);
                            addLog("Export", "Download", "OK: ENNX file downloaded directly to browser (offline safe)");
                            return false; // Prevent server postback
                        }

                        if (!navigator.onLine) {
                            alert("You are currently OFFLINE. Cannot " + (kind === 'save' ? "save session to SQL" : kind === 'email' ? "email ENNX" : "save to server disk") + " while disconnected. Please use 'Download ENNX' to save your file locally.");
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
                                    serialBuffer += value;
                                    let lines = serialBuffer.split('\n');
                                    serialBuffer = lines.pop();
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
                    rebuildPreview();
                    focusScanBox();
                })();
            </script>

        </form>
    </body>

    </html>

