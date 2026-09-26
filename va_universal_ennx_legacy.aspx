<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_universal_ennx_legacy.aspx.cs" Inherits="va_universal_ennx_legacy" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="Universal ENNX Creator &mdash; generate ENNX inventory export files from any VA scanner or barcode device." />
    <title>Universal ENNX Creator | iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <script>
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('sw.js').then(function(reg) {
                if (reg.waiting) reg.waiting.postMessage({ type: 'SKIP_WAITING' });
            }).catch(function() {});
        }
    </script>

    <style>
        *{box-sizing:border-box;}
        body{margin:0;background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,sans-serif;}
        .status-bar{display:flex;justify-content:space-between;background:var(--chip);padding:8px 20px;font-size:13px;border-bottom:1px solid var(--line);}
        .wrap{max-width:1120px;margin:0 auto;padding:18px 20px;}
        .top-bar{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;margin-bottom:18px;}
        .page-title{font-size:22px;font-weight:800;}
        .page-sub{font-size:13px;color:var(--muted);margin-top:3px;}
        .row{display:flex;gap:14px;flex-wrap:wrap;}
        .panel{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px;box-shadow:var(--shadow);}
        .panel.flex{flex:1;min-width:300px;}
        .panel-title{font-size:14px;font-weight:700;color:var(--accent);margin-bottom:12px;display:flex;align-items:center;gap:8px;}
        .kpis{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px;}
        .kpi{background:var(--chip);border:1px solid var(--line);border-radius:12px;padding:10px 14px;min-width:130px;}
        .kpi .n{font-size:22px;font-weight:800;}
        .kpi .l{font-size:12px;color:var(--muted);margin-top:2px;}
        .btnbar{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px;}
        .btn{display:inline-flex;align-items:center;gap:6px;border:1px solid var(--line);background:var(--chip);color:var(--text);padding:9px 14px;border-radius:10px;cursor:pointer;font-weight:700;font-size:13px;transition:.15s;}
        .btn:hover{opacity:.85;transform:translateY(-1px);}
        .btn.accent{border-color:color-mix(in srgb, var(--accent), transparent 55%);box-shadow:0 0 0 2px color-mix(in srgb, var(--accent), transparent 92%) inset;}
        .btn.green{border-color:color-mix(in srgb, var(--accent-2), transparent 55%);box-shadow:0 0 0 2px color-mix(in srgb, var(--accent-2), transparent 92%) inset;}
        .btn.danger{border-color:color-mix(in srgb, var(--danger), transparent 55%);box-shadow:0 0 0 2px color-mix(in srgb, var(--danger), transparent 92%) inset;}
        .btn.back{text-decoration:none;font-size:13px;}
        .field{width:100%;padding:11px 13px;border-radius:10px;border:1px solid var(--line);background:var(--chip);color:var(--text);font-size:16px;outline:none;transition:.15s;}
        .field:focus{border-color:var(--accent);}
        .hint{color:var(--muted);font-size:12px;margin-top:7px;line-height:1.45;}
        .tag{display:inline-flex;align-items:center;gap:6px;background:var(--chip);border:1px solid var(--line);padding:5px 10px;border-radius:999px;font-size:12px;color:var(--muted);}
        .tag b{color:var(--text);}
        .log-table{width:100%;border-collapse:collapse;font-size:12px;margin-top:10px;}
        .log-table th{background:color-mix(in srgb, var(--text), transparent 95%);color:var(--muted);text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);font-weight:700;}
        .log-table td{padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top;}
        .log-table tr:last-child td{border-bottom:none;}
        .mono{font-family:Consolas,Menlo,monospace;}
        .ok{color:var(--accent-2);} .warn{color:var(--warn);} .err{color:var(--danger);}
        .ta{width:100%;min-height:300px;resize:vertical;padding:12px;border-radius:10px;border:1px solid var(--line);background:var(--chip);color:var(--text);font-size:13px;font-family:Consolas,Menlo,monospace;}
        .msg-ok{background:color-mix(in srgb, var(--accent-2), transparent 90%);border:1px solid var(--accent-2);border-left:4px solid var(--accent-2);color:var(--accent-2);padding:12px 16px;border-radius:8px;margin-bottom:14px;font-size:13px;}
        .msg-err{background:color-mix(in srgb, var(--danger), transparent 90%);border:1px solid var(--danger);border-left:4px solid var(--danger);color:var(--danger);padding:12px 16px;border-radius:8px;margin-bottom:14px;font-size:13px;}
        .info-box{background:color-mix(in srgb, var(--accent), transparent 94%);border:1px solid color-mix(in srgb, var(--accent), transparent 75%);border-left:4px solid var(--accent);border-radius:8px;padding:13px 16px;font-size:13px;color:var(--muted);line-height:1.6;margin-bottom:16px;}
        .info-box strong{color:var(--text);}
        .section-label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;}
        .manual-row{display:flex;gap:8px;margin-bottom:8px;}
        .manual-row input{flex:1;}
        hr.sep{border:none;border-top:1px solid var(--line);margin:14px 0;}
        @keyframes pulse-green{0%,100%{box-shadow:0 0 0 0 color-mix(in srgb, var(--accent-2), transparent 60%);}50%{box-shadow:0 0 0 6px transparent;}}
        .scanning .field{animation:pulse-green 1.8s infinite;border-color:var(--accent-2);}
        #connection-indicator{font-size:14px;font-weight:700;}

        /* WebSerial section */
        .serial-section{background:var(--chip);border:1px solid var(--line);border-radius:12px;padding:12px;margin-top:12px;}
        .serial-section summary{cursor:pointer;font-weight:700;font-size:13px;}
        .serial-section[open] summary{margin-bottom:8px;}

        /* Light mode refinements */
        [data-theme="light"] .panel{box-shadow:0 1px 3px rgb(0 0 0 / 0.04), 0 2px 8px rgb(0 0 0 / 0.03);}
        [data-theme="light"] .kpi{background:var(--chip);border-color:var(--line);}
        [data-theme="light"] .btn{border-color:var(--line);}
        [data-theme="light"] .field, [data-theme="light"] .ta{background:var(--card);border-color:var(--line);}
        [data-theme="light"] .field:focus, [data-theme="light"] .ta:focus{border-color:var(--accent);}
    </style>
</head>
<body>
<form id="form1" runat="server">
    <div class="status-bar">
        <span>iDash &mdash; Universal ENNX Creator</span>
        <span id="connection-indicator">Checking&hellip;</span>
    </div>

    <div class="wrap">
        <div class="top-bar">
            <div>
                <div class="page-title">&#128228; Universal ENNX Creator <span style="font-size:12px; color:#ef4444; border:1px solid rgba(239,68,68,0.4); background:rgba(239,68,68,0.12); padding:2px 8px; border-radius:999px; vertical-align:middle; font-weight:700;">Legacy / Archived</span></div>
                <div class="page-sub">Archived original postback &amp; tile-based ENNX generator. Preserved for backward reference.</div>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
                <a href="va_universal_ennx.aspx" class="nav-pill" style="background:#10b981; color:#fff; font-weight:700; border:1px solid #10b981; text-decoration:none; padding:6px 12px; border-radius:8px; font-size:12px;">&#9654; Switch to Current Version</a>
                <a href="documentation/va_universal_ennx_legacy.html" class="nav-pill nav-pill-docs">&#128214; Legacy Docs</a>
                <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
            </div>
        </div>

        <asp:Literal ID="LitMsg" runat="server" />

        <div class="info-box">
            <strong>&#128276; How it works:</strong> Tap the scan input box, then scan or type each item. 
            If a scan starts with <code>SP</code> it is treated as a <strong>location</strong>; everything else is an <strong>asset</strong>.
            Use <em>Force Next = Location</em> to manually flag the next scan as a location anytime.
            When done, click <strong>Download ENNX</strong> or <strong>Email ENNX</strong> &mdash; no site selection, no database required.
        </div>

        <div class="kpis">
            <div class="kpi"><div class="n" id="kLoc">0</div><div class="l">Locations</div></div>
            <div class="kpi"><div class="n" id="kAssets">0</div><div class="l">Assets</div></div>
            <div class="kpi"><div class="n" id="kDupes">0</div><div class="l">Duplicates skipped</div></div>
            <div class="kpi"><div class="n ok" id="kMode">&#8203;</div><div class="l">Mode</div></div>
        </div>

        <div class="row">
            <!-- LEFT: scan input + log -->
            <div class="panel flex">
                <div class="panel-title">&#128247; Scan Input</div>

                <div class="btnbar">
                    <button type="button" class="btn accent" onclick="forceNextLocation()">&#8614; Force Next = Location</button>
                    <button type="button" class="btn" onclick="undoLast()">&#8617; Undo Last</button>
                    <button type="button" class="btn danger" onclick="clearAll()">&#128465; Clear All</button>
                </div>

                <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px;">
                    <span class="tag"><b>Current loc:</b> <span id="tLoc" class="mono">(none)</span></span>
                    <span class="tag"><b>Last scan:</b> <span id="tLast" class="mono">&mdash;</span></span>
                </div>

                <div id="scanWrap">
                    <input id="scanBox" class="field" autocomplete="off" autocapitalize="off"
                           spellcheck="false" placeholder="Tap here, then scan (ENTER suffix required)" />
                </div>
                <div class="hint">
                    <b>Location detection:</b> any scan starting with <code>SP</code> auto-switches to a new location block.<br />
                    <b>Asset formats accepted:</b> <code>512 EE12345</code> &nbsp;|&nbsp; <code>EE12345</code> &nbsp;|&nbsp; <code>512EE12345</code> &nbsp;|&nbsp; raw barcode values.<br />
                    <b>All scanners supported</b> &mdash; barcode, RFID, or combined.
                </div>

                <hr class="sep" />
                <div class="section-label">Manual entry</div>
                <div class="manual-row">
                    <input type="text" id="manualInput" class="field" style="font-size:14px;"
                           placeholder="Type asset or location, press Enter or click Add" />
                    <button type="button" class="btn green" onclick="submitManual()">+ Add</button>
                </div>

                <hr class="sep" />
                <div class="section-label">Options</div>
                <div style="display:flex;gap:12px;flex-wrap:wrap;margin-bottom:10px;">
                    <label class="tag" style="cursor:pointer;">
                        <input id="chkDedup" type="checkbox" checked="checked" style="transform:scale(1.1);" />
                        <span><b>De-duplicate assets per location</b></span>
                    </label>
                    <label class="tag" style="cursor:pointer;">
                        <input id="chkAutoLoc" type="checkbox" checked="checked" style="transform:scale(1.1);" />
                        <span><b>Auto-switch on SP location scan</b></span>
                    </label>
                </div>

                <table class="log-table" id="tblLog">
                    <thead><tr><th style="width:90px;">Time</th><th style="width:90px;">Type</th><th>Value</th><th>Note</th></tr></thead>
                    <tbody></tbody>
                </table>

                <!-- hidden postback fields -->
                <asp:HiddenField ID="HidEnnx"    runat="server" />
                <asp:HiddenField ID="HidSummary" runat="server" />
                <asp:HiddenField ID="HidUser"    runat="server" />

                <div class="btnbar" style="margin-top:14px;">
                    <asp:Button ID="BtnDownload" runat="server" CssClass="btn accent"
                        Text="&#11015; Download ENNX" OnClick="BtnDownload_Click"
                        OnClientClick="return preparePost('download');" />
                    <asp:Button ID="BtnEmail" runat="server" CssClass="btn green"
                        Text="&#9993; Email ENNX" OnClick="BtnEmail_Click"
                        OnClientClick="return preparePost('email');" />
                </div>
                <div class="hint" style="margin-top:8px;">
                    <b>Download:</b> saves the .txt file directly to your computer.<br />
                    <b>Email:</b> sends to configured system recipients (set in Admin &rsaquo; Email Config).
                </div>

                <!-- WebSerial: Connect USB RFID Reader -->
                <details class="serial-section" id="serialSection">
                    <summary>&#9658; WebSerial &mdash; Connect USB RFID Reader</summary>
                    <div class="btnbar">
                        <button type="button" class="btn accent" id="btnSerialOpen"
                            onclick="serialOpenClose()">Select/Open Serial Port</button>
                        <button type="button" class="btn danger" id="btnSerialClose" style="display:none"
                            onclick="serialClose()">Close Port</button>
                        <span class="tag" id="serialStatus"><b>Status:</b> Disconnected</span>
                    </div>
                    <div class="hint" id="serialHint" style="margin-top:6px">
                        WebSerial requires Chrome or Edge served over HTTPS (or localhost).
                        Data arriving on the serial port is processed exactly like keyboard scans.
                    </div>
                </details>
            </div>

            <!-- RIGHT: live ENNX preview -->
            <div class="panel flex">
                <div class="panel-title">&#128196; ENNX Preview <span style="font-size:11px;font-weight:400;color:var(--muted);">(live)</span></div>
                <textarea id="ennxPreview" class="ta mono" readonly="readonly"></textarea>
                <div class="hint" style="margin-top:8px;">
                    Format:<br />
                    <span class="mono" style="font-size:12px;">ENNX<br />ID<br />SP-ROOM-101<br />512 EE18193<br />512 EE18194<br />***END***^N</span>
                </div>
            </div>
        </div>

        <div style="margin-top:20px;color:var(--muted);font-size:12px;text-align:center;">
            AssetWorx! by InfinID Technologies &mdash; iDash by ID Integration Inc. &copy; 2026
        </div>
    </div>

    <script>
    (function () {
        // --- state ---
        const SESSION_STORAGE_KEY = 'UniversalEnnx_SessionBlocks';
        let blocks = [];         // [{location, assets[], assetSet{}}]
        let log    = [];
        let forceLoc      = true;
        let currentLoc    = "";
        let totalLoc      = 0;
        let totalAssets   = 0;
        let dupes         = 0;
        let _isOnline     = navigator.onLine;
        let _probeInFlight = false;

        // --- DOM ---
        const scanBox     = document.getElementById("scanBox");
        const scanWrap    = document.getElementById("scanWrap");
        const manualInput = document.getElementById("manualInput");
        const tblBody     = document.querySelector("#tblLog tbody");
        const preview     = document.getElementById("ennxPreview");
        const chkDedup    = document.getElementById("chkDedup");
        const chkAutoLoc  = document.getElementById("chkAutoLoc");
        const HidEnnx     = document.getElementById("<%= HidEnnx.ClientID %>");
        const HidSummary  = document.getElementById("<%= HidSummary.ClientID %>");

        // --- persistence ---
        function persistSession() {
            try {
                const data = {
                    blocks: blocks.map(function(b) {
                        return { location: b.location, assets: b.assets.slice(0) };
                    }),
                    currentLoc: currentLoc,
                    totalLoc: totalLoc,
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
                    currentLoc = data.currentLoc || (blocks.length ? blocks[blocks.length - 1].location : "");
                    totalLoc = data.totalLoc || blocks.length;
                    totalAssets = data.totalAssets || 0;
                    dupes = data.dupes || 0;
                    forceLoc = !currentLoc;
                    addLog("Session", "(restored)", "OK: Restored " + totalLoc + " location(s), " + totalAssets + " asset(s) from local cache");
                    refresh();
                    return true;
                }
            } catch (e) {}
            return false;
        }

        // --- active connectivity probe ---
        const indicator = document.getElementById("connection-indicator");
        function probeConnectivity() {
            if (_probeInFlight) return Promise.resolve(_isOnline);
            _probeInFlight = true;
            return new Promise(function(resolve) {
                var xhr = new XMLHttpRequest();
                xhr.timeout = 3000;
                xhr.open('HEAD', 'va_universal_ennx.aspx?_nocache=' + Date.now(), true);
                xhr.onload = function() {
                    _probeInFlight = false;
                    resolve(xhr.status >= 200 && xhr.status < 400);
                };
                xhr.onerror = function() { _probeInFlight = false; resolve(false); };
                xhr.ontimeout = function() { _probeInFlight = false; resolve(false); };
                try { xhr.send(); } catch(e) { _probeInFlight = false; resolve(false); }
            });
        }

        function checkConn() {
            probeConnectivity().then(function(online) {
                _isOnline = online;
                if (!indicator) return;
                indicator.textContent = online ? "\u25cf CONNECTED" : "\u25cf OFFLINE (Direct Download Available)";
                indicator.style.color = online ? 'var(--accent-2)' : 'var(--danger)';
            });
        }
        window.addEventListener("online", checkConn);
        window.addEventListener("offline", function() {
            _isOnline = false;
            if (indicator) {
                indicator.textContent = "\u25cf OFFLINE (Direct Download Available)";
                indicator.style.color = 'var(--danger)';
            }
        });
        checkConn();
        setInterval(checkConn, 4000);

        // --- helpers ---
        function now() {
            return new Date().toLocaleTimeString([], {hour:"2-digit",minute:"2-digit",second:"2-digit"});
        }
        function clean(s) { return (s||"").trim().replace(/\s+/g," "); }
        function upper(s) { return clean(s).toUpperCase(); }
        function esc(s)   {
            return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;")
                            .replace(/>/g,"&gt;").replace(/"/g,"&quot;");
        }

        function looksLikeLoc(s) {
            const u = upper(s);
            return u.startsWith("SP") && !u.includes("EE");
        }

        // Normalize asset: accepts 512 EE1234, EE1234, 512EE1234, with alphanumeric suffixes e.g. 512 EE12345A
        function normalizeAsset(raw) {
            const s = upper(raw).replace(/F+$/, "");

            // Pure EPC hex — silently ignore
            if (/^[0-9A-F]{12,}$/.test(s)) return null;

            let m;
            m = s.match(/^(\d{3})\s*EE\s*(\w+)$/i); if (m) return m[1] + " EE" + m[2].toUpperCase();
            m = s.match(/^EE\s*(\w+)$/i);           if (m) return "EE" + m[1].toUpperCase();
            m = s.match(/^(\d{3})EE(\w+)$/i);       if (m) return m[1] + " EE" + m[2].toUpperCase();

            // Accept any non-empty raw value (barcode-only scanners, non-EE assets)
            return s.length >= 2 ? s : null;
        }

        function curBlock() { return blocks.length ? blocks[blocks.length-1] : null; }

        // --- log ---
        function addLog(type, val, note) {
            log.unshift({t:now(), type, val, note:note||""});
            if (log.length > 30) log.pop();
            renderLog();
        }
        function noteClass(n) {
            if (!n) return "";
            if (n.startsWith("ERR:"))  return "err";
            if (n.startsWith("WARN:")) return "warn";
            if (n.startsWith("OK:"))   return "ok";
            return "";
        }
        function renderLog() {
            tblBody.innerHTML = "";
            for (const r of log) {
                const cls = noteClass(r.note);
                const tr = document.createElement("tr");
                tr.innerHTML =
                    `<td class="mono">${esc(r.t)}</td>` +
                    `<td><span class="tag"><b>${esc(r.type)}</b></span></td>` +
                    `<td class="mono">${esc(r.val)}</td>` +
                    `<td class="${cls}">${esc(r.note)}</td>`;
                tblBody.appendChild(tr);
            }
        }

        // --- ENNX build ---
        function buildEnnx() {
            const lines = ["ENNX","ID"];
            for (const b of blocks) {
                lines.push(b.location);
                for (const a of b.assets) lines.push(a);
            }
            lines.push("***END***^" + (lines.length - 2));
            return lines.join("\r\n");
        }

        function refresh() {
            preview.value = buildEnnx();
            document.getElementById("kLoc").textContent    = totalLoc;
            document.getElementById("kAssets").textContent = totalAssets;
            document.getElementById("kDupes").textContent  = dupes;
            document.getElementById("kMode").textContent   = forceLoc ? "Need Location" : "Scanning Assets";
            document.getElementById("tLoc").textContent    = currentLoc || "(none)";
            scanWrap.className = forceLoc ? "" : "scanning";
        }

        // --- set location ---
        function setLocation(raw) {
            const s = upper(raw);
            if (s.includes("EE")) {
                addLog("Location", raw, "ERR: Location barcode cannot contain 'EE' (equipment tag)");
                return;
            }
            const loc = s.replace(/F+$/,"");
            if (!loc) { addLog("Location", raw, "ERR: Empty"); return; }
            currentLoc = loc;
            forceLoc   = false;
            blocks.push({location:loc, assets:[], assetSet:{}});
            totalLoc++;
            document.getElementById("tLast").textContent = loc;
            addLog("Location", loc, "OK: New block started");
            persistSession();
            refresh();
        }

        // --- add asset ---
        function addAsset(raw) {
            if (!currentLoc) {
                addLog("Asset", raw, "WARN: No location set &mdash; scan a location first");
                forceLoc = true; refresh(); return;
            }
            const line = normalizeAsset(raw);
            if (!line) { addLog("Asset", raw, "ERR: Unrecognized / EPC ignored"); return; }
            const b = curBlock();
            if (chkDedup.checked && b.assetSet[line]) {
                dupes++;
                addLog("Asset", line, "WARN: Duplicate skipped");
                refresh(); return;
            }
            b.assets.push(line);
            b.assetSet[line] = true;
            totalAssets++;
            document.getElementById("tLast").textContent = line;
            addLog("Asset", line, "OK: Added");
            persistSession();
            refresh();
        }

        // --- handle scan ---
        function handle(raw) {
            const s = clean(raw);
            if (!s) return;
            if (forceLoc || (chkAutoLoc.checked && looksLikeLoc(s))) {
                setLocation(s);
            } else {
                addAsset(s);
            }
        }

        // --- public buttons ---
        window.forceNextLocation = function () {
            forceLoc = true;
            addLog("Mode","(manual)","OK: Next scan = location");
            refresh(); focusScan();
        };
        window.undoLast = function () {
            const last = log.find(x => (x.note||"").startsWith("OK:"));
            if (!last) { addLog("Undo","(none)","WARN: Nothing to undo"); return; }
            if (last.type === "Asset") {
                const b = curBlock();
                if (b && b.assets.length) {
                    const r = b.assets.pop();
                    delete b.assetSet[r];
                    totalAssets = Math.max(0, totalAssets-1);
                    addLog("Undo", r, "OK: Removed");
                }
            } else if (last.type === "Location") {
                if (blocks.length) {
                    const rb = blocks.pop();
                    totalLoc    = Math.max(0, totalLoc-1);
                    totalAssets = Math.max(0, totalAssets - (rb.assets||[]).length);
                    currentLoc  = blocks.length ? blocks[blocks.length-1].location : "";
                    forceLoc    = !currentLoc;
                    addLog("Undo", rb.location, "OK: Block removed");
                }
            }
            persistSession();
            refresh(); focusScan();
        };
        window.clearAll = function () {
            if (!confirm("Clear the entire session?")) return;
            blocks=[]; log=[]; currentLoc=""; forceLoc=true;
            totalLoc=0; totalAssets=0; dupes=0;
            try { localStorage.removeItem(SESSION_STORAGE_KEY); } catch (e) {}
            addLog("Clear","(all)","OK: Session cleared");
            refresh(); focusScan();
        };
        window.submitManual = function () {
            const v = manualInput.value;
            manualInput.value = "";
            handle(v);
            focusScan();
        };

        // --- scan box ---
        function focusScan() { try { scanBox.focus(); } catch(e){} }

        scanBox.addEventListener("keydown", function(ev) {
            if (ev.key === "Enter") {
                ev.preventDefault();
                const v = scanBox.value;
                scanBox.value = "";
                handle(v);
            }
        });
        manualInput.addEventListener("keydown", function(ev) {
            if (ev.key === "Enter") { ev.preventDefault(); window.submitManual(); }
        });
        document.addEventListener("click", function(ev) {
            if (ev.target && (ev.target.tagName === "INPUT" && ev.target !== scanBox)) return;
            if (ev.target && (ev.target.tagName === "SUMMARY" || ev.target.tagName === "BUTTON")) return;
            setTimeout(focusScan, 50);
        });
        setInterval(function() {
            const ae = document.activeElement;
            if (ae && ae.tagName === "SUMMARY") return;
            if (document.activeElement !== scanBox &&
                document.activeElement !== manualInput) focusScan();
        }, 1500);

        // --- post prep ---
        window.preparePost = function (kind) {
            if (totalLoc === 0) { alert("Scan at least one location first."); return false; }

            // Direct client Blob download (zero server dependency, works 100% offline)
            if (kind === 'download') {
                const ennx = buildEnnx();
                const d = new Date();
                const stamp = d.getFullYear() +
                    String(d.getMonth() + 1).padStart(2, '0') +
                    String(d.getDate()).padStart(2, '0') + "_" +
                    String(d.getHours()).padStart(2, '0') +
                    String(d.getMinutes()).padStart(2, '0') +
                    String(d.getSeconds()).padStart(2, '0');
                const fname = "ennx_universal_" + stamp + ".txt";
                const blob = new Blob([ennx], { type: "text/plain;charset=utf-8" });
                const url = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = url;
                a.download = fname;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                addLog("Download", fname, "OK: Downloaded locally to device");
                return false; // Prevent server postback!
            }

            // Offline guard for Email
            if (!_isOnline || !navigator.onLine) {
                alert("You are currently OFFLINE.\n\nEmailing requires an active network connection to the server.\nPlease use 'Download ENNX' to save your file directly to your device.");
                return false;
            }

            HidEnnx.value    = buildEnnx();
            HidSummary.value = "Locations=" + totalLoc + "; Assets=" + totalAssets + "; Dupes=" + dupes;
            return true;
        };

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
                            if (trimmed) handle(trimmed);
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

        refresh();
        focusScan();
    })();
    </script>
</form>
</body>
</html>
