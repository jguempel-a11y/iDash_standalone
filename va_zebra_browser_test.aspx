<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_zebra_browser_test.aspx.cs" Inherits="va_zebra_browser_test" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <title>VA Site Inventory -- iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: var(--bg); color: var(--text); font-family: "Segoe UI", system-ui, sans-serif; font-size: 14px; min-height: 100vh; }

        .page-header { background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 85%) 0%, var(--card) 60%); border-bottom: 2px solid color-mix(in srgb, var(--accent), transparent 75%); padding: 12px 18px; display: flex; align-items: center; gap: 12px; position: sticky; top: 0; z-index: 100; box-shadow: 0 2px 12px color-mix(in srgb, var(--accent), transparent 90%); }
        .header-icon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #0284c7, #6366f1); font-size: 20px; color: #fff; flex-shrink: 0; }
        .header-title { font-size: 17px; font-weight: 700; }
        .header-sub { font-size: 11px; color: var(--muted); }
        .header-auth { margin-left: auto; display: flex; align-items: center; gap: 8px; }
        .user-pill { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; background: rgba(14,165,233,0.12); color: #0284c7; border: 1px solid rgba(14,165,233,0.3); border-radius: 20px; font-size: 11px; font-weight: 700; }

        .container { max-width: 960px; margin: 14px auto; padding: 0 14px; }

        /* SCAN BAR */
        .scan-bar { background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 92%) 0%, var(--card) 100%); border: 2px solid var(--accent); border-radius: 14px; padding: 14px 16px; margin-bottom: 14px; box-shadow: 0 4px 20px color-mix(in srgb, var(--accent), transparent 85%); }
        .scan-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: var(--accent); margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
        .pulse { width: 9px; height: 9px; border-radius: 50%; background: #10b981; animation: pulse-anim 1.5s infinite; }
        @keyframes pulse-anim { 0% { box-shadow: 0 0 0 0 rgba(16,185,129,0.7); } 70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); } 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); } }
        #raw { width: 100%; padding: 13px 15px; font-size: 16px; font-weight: 700; font-family: "Consolas", monospace; background: var(--bg); color: var(--text); border: 1px solid var(--line); border-radius: 10px; outline: none; }
        #raw:focus { border-color: var(--accent); }
        #raw.blurred { border-color: #f97316; background: rgba(249,115,22,0.06); }

        /* LOCATION ROW */
        .loc-row { display: flex; gap: 8px; margin-bottom: 14px; flex-wrap: wrap; align-items: center; }
        .loc-row select, .loc-row input[type=text] { background: var(--bg); color: var(--text); border: 1px solid var(--line); border-radius: 8px; padding: 8px 12px; font-size: 13px; outline: none; }
        .loc-row select:focus, .loc-row input[type=text]:focus { border-color: var(--accent); }
        .loc-row select { min-width: 160px; }
        .loc-row input[type=text] { flex: 1; min-width: 180px; }
        .loc-badge { background: rgba(16,185,129,0.12); color: #10b981; border: 1px solid #10b981; border-radius: 8px; padding: 6px 12px; font-size: 13px; font-weight: 700; display: none; }
        .site-locked-badge { display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; background: rgba(99,102,241,0.12); color: #6366f1; border: 1px solid rgba(99,102,241,0.3); border-radius: 8px; font-size: 13px; font-weight: 700; }

        /* STATS */
        .stats-row { display: flex; gap: 10px; margin-bottom: 14px; flex-wrap: wrap; }
        .stat { background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 10px 16px; flex: 1; min-width: 90px; text-align: center; }
        .stat-val { font-size: 26px; font-weight: 800; }
        .stat-lbl { font-size: 10px; color: var(--muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; margin-top: 3px; }
        .stat-found   .stat-val { color: #10b981; }
        .stat-missing .stat-val { color: #f97316; }
        .stat-unexp   .stat-val { color: #a78bfa; }
        .stat-unk     .stat-val { color: var(--muted); }

        /* TOOLBAR */
        .toolbar { display: flex; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; align-items: center; }
        .btn { background: var(--chip); color: var(--text); border: 1px solid var(--line); padding: 8px 14px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.15s; display: inline-flex; align-items: center; gap: 6px; }
        .btn:hover { background: var(--line); }
        .btn-sm { padding: 5px 10px; font-size: 11px; border-radius: 6px; }
        .btn-outline { background: transparent; }
        .btn-primary { background: var(--accent); color: #fff; border-color: var(--accent); }
        .btn-success { background: #10b981; color: #fff; border-color: #10b981; }
        .btn-danger  { background: #ef4444; color: #fff; border-color: #ef4444; }
        .btn:disabled { opacity: 0.4; cursor: not-allowed; }

        /* TABLES */
        .card { background: var(--card); border: 1px solid var(--line); border-radius: 12px; overflow: hidden; margin-bottom: 12px; }
        .card-hdr { padding: 10px 14px; border-bottom: 1px solid var(--line); font-size: 12px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.4px; background: var(--chip); display: flex; align-items: center; justify-content: space-between; }
        .tbl { width: 100%; border-collapse: collapse; font-size: 12px; }
        .tbl th { padding: 8px 10px; text-align: left; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; color: var(--muted); border-bottom: 1px solid var(--line); background: var(--chip); }
        .tbl td { padding: 8px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; }
        .tbl tr:last-child td { border-bottom: none; }
        .tbl-wrap { max-height: 44vh; overflow-y: auto; }
        .flash-row { animation: flash-in 1.2s ease; }
        @keyframes flash-in { 0% { background: rgba(16,185,129,0.35); } 100% { background: transparent; } }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 10px; font-weight: 700; text-align: center; }
        .badge-found   { background: rgba(16,185,129,0.15); color: #10b981; border: 1px solid rgba(16,185,129,0.3); }
        .badge-missing { background: rgba(249,115,22,0.15); color: #f97316; border: 1px solid rgba(249,115,22,0.3); }
        .badge-unexp   { background: rgba(167,139,250,0.15); color: #a78bfa; border: 1px solid rgba(167,139,250,0.3); }
        .badge-unk     { background: rgba(100,116,139,0.15); color: #64748b; border: 1px solid rgba(100,116,139,0.3); }
        .reads-pill { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 700; background: var(--chip); color: var(--muted); }
        .reads-pill.has-reads { background: rgba(16,185,129,0.15); color: #10b981; }
        .empty-msg { padding: 30px; text-align: center; color: var(--muted); font-size: 12px; }

        /* LOG */
        .log-box { background: #090d16; color: #a5b4fc; font-family: "Consolas", monospace; font-size: 11px; padding: 8px 12px; max-height: 120px; overflow-y: auto; line-height: 1.6; }
        .log-line { display: flex; gap: 8px; }
        .log-ts  { color: #64748b; min-width: 52px; flex-shrink: 0; }
        .log-msg { color: #e2e8f0; word-break: break-all; }

        .status-pill { display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: 11px; font-weight: 700; border: 1px solid; transition: all 0.2s; }
        .s-ready    { color: var(--muted); border-color: var(--line); }
        .s-scanning { color: #38bdf8; border-color: #38bdf8; background: rgba(56,189,248,0.1); }
        .s-paused   { color: #f97316; border-color: #f97316; background: rgba(249,115,22,0.1); }

        .section-tabs { display: flex; gap: 0; margin-bottom: 0; }
        .tab { padding: 8px 16px; font-size: 12px; font-weight: 700; cursor: pointer; border: 1px solid var(--line); border-bottom: none; border-radius: 8px 8px 0 0; background: var(--chip); color: var(--muted); transition: all 0.15s; }
        .tab.active { background: var(--card); color: var(--text); }
        
        /* LOGIN MODAL */
        .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.65); backdrop-filter: blur(3px); display: flex; align-items: center; justify-content: center; z-index: 1000; padding: 16px; }
        .modal-box { background: var(--card); border: 1px solid var(--line); border-radius: 14px; width: 100%; max-width: 380px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.4); animation: modal-in 0.2s ease; }
        @keyframes modal-in { 0% { opacity: 0; transform: scale(0.95); } 100% { opacity: 1; transform: scale(1); } }
        .modal-hdr { padding: 14px 18px; border-bottom: 1px solid var(--line); background: var(--chip); display: flex; align-items: center; justify-content: space-between; }
        .modal-body { padding: 18px; }
        .modal-close { background: transparent; border: none; font-size: 20px; color: var(--muted); cursor: pointer; line-height: 1; }
        .login-input { width: 100%; background: var(--bg); color: var(--text); border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; font-size: 14px; outline: none; margin-bottom: 12px; }
        .login-input:focus { border-color: var(--accent); }
        .login-err { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: #ef4444; padding: 8px 12px; border-radius: 8px; font-size: 12px; margin-bottom: 12px; }

        /* Allow standard pull-to-refresh */
        html, body { overscroll-behavior-y: auto; }
    </style>
</head>
<body onload="init();">

    <div class="page-header">
        <div class="header-icon">&#9678;</div>
        <div style="flex:1;">
            <div class="header-title">VA Site Inventory</div>
            <div class="header-sub">RFD40 + TC53e -- iDash Inventory System</div>
        </div>
        <div class="header-auth" id="headerAuth">
            <div id="userBadge" style="display:none; align-items:center; gap:8px;">
                <span class="user-pill" id="userPill"></span>
                <button class="btn btn-sm btn-outline" onclick="logout(); return false;" title="Sign out / switch user">Sign Out</button>
            </div>
            <button class="btn btn-sm btn-primary" id="btnShowLogin" onclick="openLoginModal(); return false;">Sign In</button>
        </div>
    </div>

    <div class="container">

        <!-- LOCATION SELECTOR -->
        <div class="loc-row">
            <div id="siteSelectWrap" style="display:inline-flex; align-items:center;">
                <select id="ddlSite" onchange="onSiteChange()">
                    <option value="0">-- All Sites --</option>
                </select>
            </div>
            <span class="site-locked-badge" id="siteLockedBadge" style="display:none;"></span>
            <input type="text" id="txtLocation" placeholder="Type or scan location barcode..." autocomplete="off" autocapitalize="characters" />
            <button class="btn btn-primary" onclick="loadRoom(); return false;">Load Room</button>
            <span class="loc-badge" id="locBadge"></span>
        </div>

        <!-- SCAN BAR -->
        <div class="scan-bar">
            <div class="scan-label">
                <div class="pulse" id="pulseDot"></div>
                <span>Scanner Input</span>
                <span class="status-pill s-ready" id="statusPill">&#9711; READY</span>
            </div>
            <input id="raw" type="text" autocomplete="off" autocorrect="off"
                   spellcheck="false" autocapitalize="off"
                   placeholder="Pull RFID trigger to scan..." />
        </div>

        <!-- STATS -->
        <div class="stats-row">
            <div class="stat stat-found">  <div class="stat-val" id="cntFound">0</div>   <div class="stat-lbl">Found</div></div>
            <div class="stat stat-missing"><div class="stat-val" id="cntMissing">0</div> <div class="stat-lbl">Missing</div></div>
            <div class="stat stat-unexp">  <div class="stat-val" id="cntUnexp">0</div>   <div class="stat-lbl">Unexpected</div></div>
            <div class="stat stat-unk">    <div class="stat-val" id="cntUnknown">0</div> <div class="stat-lbl">Unknown</div></div>
        </div>

        <!-- TOOLBAR -->
        <div class="toolbar">
            <button class="btn btn-success" id="btnCommit" onclick="commitInventory(); return false;" disabled>Commit Inventory</button>
            <button class="btn btn-danger"  onclick="resetScan(); return false;">New Scan</button>
            <button class="btn" onclick="focusScanner(); return false;">Re-Arm Scanner</button>
        </div>

        <!-- TABS -->
        <div class="section-tabs">
            <div class="tab active" id="tabManifest"    onclick="showTab('manifest')">Room Manifest</div>
            <div class="tab"        id="tabUnexpected"  onclick="showTab('unexpected')">Unexpected</div>
            <div class="tab"        id="tabUnknown"     onclick="showTab('unknown')">Unknown Tags</div>
            <div class="tab"        id="tabLog"         onclick="showTab('log')">Log</div>
        </div>

        <!-- ROOM MANIFEST TABLE (4 Columns for Mobile Readability) -->
        <div class="card" id="panelManifest">
            <div class="card-hdr">
                <span>Expected Assets in Room</span>
                <span id="manifestRoomLabel" style="font-weight:400;font-size:11px;"></span>
            </div>
            <div class="tbl-wrap">
                <table class="tbl" id="tblManifest">
                    <thead><tr>
                        <th style="width:75px;">Status</th>
                        <th>Asset &amp; Description</th>
                        <th>Tag &amp; EIL / SN</th>
                        <th style="width:65px;text-align:center;">Reads</th>
                    </tr></thead>
                    <tbody id="bodyManifest">
                        <tr><td colspan="4" class="empty-msg">Scan or type a location to load manifest.</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- UNEXPECTED TABLE -->
        <div class="card" id="panelUnexpected" style="display:none;">
            <div class="card-hdr"><span>Unexpected Assets (from other rooms)</span></div>
            <div class="tbl-wrap">
                <table class="tbl">
                    <thead><tr>
                        <th>Asset &amp; Description</th>
                        <th>Recorded At</th>
                        <th style="width:65px;text-align:center;">Reads</th>
                    </tr></thead>
                    <tbody id="bodyUnexpected">
                        <tr><td colspan="3" class="empty-msg">None yet.</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- UNKNOWN TAGS TABLE -->
        <div class="card" id="panelUnknown" style="display:none;">
            <div class="card-hdr"><span>Unknown Tags (not in database)</span></div>
            <div class="tbl-wrap">
                <table class="tbl">
                    <thead><tr>
                        <th>Raw Tag ID</th>
                        <th>First Seen</th>
                        <th style="width:65px;text-align:center;">Reads</th>
                    </tr></thead>
                    <tbody id="bodyUnknown">
                        <tr><td colspan="3" class="empty-msg">None yet.</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- LOG -->
        <div class="card" id="panelLog" style="display:none;">
            <div class="card-hdr"><span>Event Log</span></div>
            <div class="log-box" id="logBox"></div>
        </div>

    </div>

    <!-- SIGN IN MODAL -->
    <div id="loginModal" class="modal-overlay" style="display:none;">
        <div class="modal-box">
            <div class="modal-hdr">
                <span style="font-weight:700;font-size:14px;">Technician Sign In</span>
                <button class="modal-close" onclick="closeLoginModal(); return false;">&times;</button>
            </div>
            <div class="modal-body">
                <p style="font-size:12px;color:var(--muted);margin-bottom:12px;">Sign in with your iDash account to automatically lock to your assigned site and accelerate scans.</p>
                <div id="loginErr" class="login-err" style="display:none;"></div>
                <div style="margin-bottom:8px;">
                    <label style="display:block;font-size:11px;font-weight:700;text-transform:uppercase;color:var(--muted);margin-bottom:4px;">Username</label>
                    <input type="text" id="txtUsername" class="login-input" placeholder="e.g. 517a or gary" autocomplete="username" autocapitalize="none" />
                </div>
                <div style="margin-bottom:14px;">
                    <label style="display:block;font-size:11px;font-weight:700;text-transform:uppercase;color:var(--muted);margin-bottom:4px;">Password</label>
                    <input type="password" id="txtPassword" class="login-input" placeholder="Password" autocomplete="current-password" />
                </div>
                <button class="btn btn-primary" style="width:100%;padding:10px;font-size:13px;justify-content:center;" onclick="doLogin(); return false;">Sign In</button>
                <div style="text-align:center;margin-top:12px;">
                    <a href="#" onclick="closeLoginModal(); return false;" style="font-size:11px;color:var(--muted);text-decoration:none;">Cancel / Continue Unrestricted</a>
                </div>
            </div>
        </div>
    </div>

<script>
    // ============================================================
    // STATE
    // ============================================================
    var _siteId        = 0;
    var _siteName      = '';
    var _location      = '';
    var _currentUser   = null;
    var _manifest      = [];      // { id, name, rfidtag, serialnumber, eil, description, status, reads }
    var _manifestMap   = {};      // quick lookup: norm -> manifest asset
    var _tagMap        = {};      // dedup: tok -> index/count (never reset mid-session)
    var _unknown       = [];      // { tok, firstSeen, reads }
    var _unexpected    = [];      // { id, name, description, dbLocation, reads }
    var _sessionTimer  = null;
    var _sessionOpen   = false;
    var _manifestReady = false;   // true once LoadLocationAssets returns
    var _scanStart     = null;
    var IDLE_MS        = 1000;

    // ============================================================
    // INIT
    // ============================================================
    function init() {
        log('Page ready. Checking session...');
        checkSession();

        // 1. LOCATION INPUT BEHAVIOR
        var txtLoc = document.getElementById('txtLocation');
        txtLoc.addEventListener('keyup', function(e) {
            if (e.key !== 'Enter' && e.key !== 'Tab') return;
            var val = txtLoc.value.trim();
            if (!val || val.length < 2) return;
            loadRoom();
        });

        // 2. SCANNER INPUT BEHAVIOR (EXACT IDENTICAL PATTERN TO TEST_2)
        // No <form> element on the page, pure keyup + Enter
        // Zero DOM rebuilds during active scan ensures hardware trigger has full control
        var raw = document.getElementById('raw');

        raw.addEventListener('focus', function() {
            raw.classList.remove('blurred');
            raw.placeholder = 'Pull RFID trigger to scan...';
            if (!_sessionOpen) setStatus('ready');
        });
        raw.addEventListener('blur', function() {
            raw.classList.add('blurred');
            raw.placeholder = 'TAP HERE to re-arm scanner';
            setStatus('paused');
        });

        raw.addEventListener('keyup', function(e) {
            if (e.key !== 'Enter' && e.key !== 'Tab') return;
            var val = raw.value.trim().replace(/[\r\n]+$/, '').trim();
            raw.value = '';
            if (!val || val.length < 3) return;
            processTag(val);
        });

        // Focus on location input initially so barcode or typing can happen immediately
        setTimeout(function() {
            txtLoc.focus();
        }, 100);
    }

    function focusScanner() {
        var raw = document.getElementById('raw');
        raw.placeholder = 'Pull RFID trigger to scan...';
        raw.focus();
    }

    // ============================================================
    // AUTH & SESSION STATE
    // ============================================================
    function checkSession() {
        fetch('va_zebra_browser_test.aspx/GetSessionState', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (d && d.success && d.isLoggedIn) {
                applyUserSession(d);
            } else {
                _currentUser = null;
                document.getElementById('userBadge').style.display = 'none';
                document.getElementById('btnShowLogin').style.display = 'inline-flex';
                loadSites();
            }
        }).catch(function() {
            loadSites();
        });
    }

    function applyUserSession(data) {
        _currentUser = data;
        document.getElementById('userBadge').style.display = 'inline-flex';
        document.getElementById('btnShowLogin').style.display = 'none';
        document.getElementById('userPill').innerText = '👤 ' + (data.displayName || data.username);

        var sites = data.sites || [];
        populateSites(sites);

        if (sites.length === 1) {
            // User assigned to exactly ONE site (90% real-world case)
            _siteId   = sites[0].id;
            _siteName = sites[0].name;

            // Lock site UI -- hide dropdown, display locked badge
            document.getElementById('siteSelectWrap').style.display = 'none';
            var locked = document.getElementById('siteLockedBadge');
            locked.innerText = '📍 ' + _siteName;
            locked.style.display = 'inline-flex';

            log('[AUTH] Signed in as ' + data.displayName + ' -- Site: ' + _siteName);
            loadLocations(_siteId);
        } else if (sites.length > 1) {
            document.getElementById('siteSelectWrap').style.display = 'inline-flex';
            document.getElementById('siteLockedBadge').style.display = 'none';
            log('[AUTH] Signed in as ' + data.displayName + ' (' + sites.length + ' assigned sites)');
        } else {
            // Unrestricted admin
            document.getElementById('siteSelectWrap').style.display = 'inline-flex';
            document.getElementById('siteLockedBadge').style.display = 'none';
            log('[AUTH] Signed in as ' + data.displayName + ' (Admin / All Sites)');
            loadSites();
        }

        // Auto focus on location input after login
        setTimeout(function() {
            var txtLoc = document.getElementById('txtLocation');
            if (txtLoc) txtLoc.focus();
        }, 150);
    }

    function openLoginModal() {
        document.getElementById('loginErr').style.display = 'none';
        document.getElementById('txtPassword').value = '';
        document.getElementById('loginModal').style.display = 'flex';
        setTimeout(function(){ document.getElementById('txtUsername').focus(); }, 100);
    }

    function closeLoginModal() {
        document.getElementById('loginModal').style.display = 'none';
        document.getElementById('txtLocation').focus();
    }

    function doLogin() {
        var u = document.getElementById('txtUsername').value.trim();
        var p = document.getElementById('txtPassword').value;
        if (!u || !p) {
            showLoginError('Enter both username and password.');
            return;
        }

        fetch('va_zebra_browser_test.aspx/Login', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: u, password: p })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (d && d.success && d.isLoggedIn) {
                closeLoginModal();
                applyUserSession(d);
            } else {
                showLoginError(d ? d.error : 'Login failed');
            }
        }).catch(function(err) {
            showLoginError('Connection error: ' + err.message);
        });
    }

    function showLoginError(msg) {
        var el = document.getElementById('loginErr');
        el.innerText = msg;
        el.style.display = 'block';
    }

    function logout() {
        fetch('va_zebra_browser_test.aspx/Logout', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(){
            _currentUser = null;
            document.getElementById('userBadge').style.display = 'none';
            document.getElementById('btnShowLogin').style.display = 'inline-flex';
            document.getElementById('siteSelectWrap').style.display = 'inline-flex';
            document.getElementById('siteLockedBadge').style.display = 'none';
            _siteId = 0;
            _siteName = '';
            log('[AUTH] Signed out');
            loadSites();
            document.getElementById('txtLocation').focus();
        }).catch(function(){});
    }

    // ============================================================
    // SITES + LOCATIONS
    // ============================================================
    function populateSites(sites) {
        var sel = document.getElementById('ddlSite');
        sel.innerHTML = '<option value="0">-- All Sites --</option>';
        sites.forEach(function(s) {
            var o = document.createElement('option');
            o.value = s.id; o.text = s.name; sel.appendChild(o);
        });
    }

    function loadSites() {
        fetch('va_zebra_browser_test.aspx/GetSites', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) return;
            populateSites(d.sites || []);
        }).catch(function(){});
    }

    function onSiteChange() {
        _siteId = parseInt(document.getElementById('ddlSite').value) || 0;
        document.getElementById('txtLocation').value = '';
        loadLocations(_siteId);
    }

    function loadLocations(siteId) {
        fetch('va_zebra_browser_test.aspx/GetLocations', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ siteId: siteId })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) return;
            var dl = document.getElementById('locDatalist');
            if (!dl) { dl = document.createElement('datalist'); dl.id = 'locDatalist'; document.body.appendChild(dl); }
            dl.innerHTML = '';
            d.locations.forEach(function(l) {
                var o = document.createElement('option'); o.value = l; dl.appendChild(o);
            });
            document.getElementById('txtLocation').setAttribute('list', 'locDatalist');
            log('[LOCATIONS] Loaded ' + d.locations.length + ' locations for site');
        }).catch(function(){});
    }

    function loadRoom() {
        if (_sessionOpen) { log('[WARN] Cannot load room while trigger is active.'); return; }
        var loc = document.getElementById('txtLocation').value.trim().toUpperCase();
        if (!loc) { alert('Enter or scan a location first.'); return; }
        _location      = loc;
        _manifestReady = false;
        log('[ROOM] Loading manifest for ' + loc + '...');
        document.getElementById('manifestRoomLabel').innerText = loc;

        fetch('va_zebra_browser_test.aspx/LoadLocationAssets', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ locationName: loc, siteId: _siteId })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) { log('[ERROR] ' + (d ? d.error : 'Load failed')); return; }

            _manifest = [];
            _manifestMap = {};
            d.assets.forEach(function(a) {
                var item = { id: a.id, name: a.name, description: a.description,
                             rfidtag: a.rfidtag, serialnumber: a.serialnumber, eil: a.eil,
                             status: 'Missing', reads: 0 };
                _manifest.push(item);
                // Index keys in _manifestMap for instantaneous O(1) matching during trigger hold
                var nameKey = (a.name || '').toUpperCase().replace(/ /g, '');
                var rfidKey = (a.rfidtag || '').toUpperCase().replace(/ /g, '');
                var serKey  = (a.serialnumber || '').toUpperCase().trim();
                if (nameKey) _manifestMap[nameKey] = item;
                if (rfidKey) _manifestMap[rfidKey] = item;
                if (serKey)  _manifestMap[serKey]  = item;
            });

            _tagMap        = {};
            _unknown       = [];
            _unexpected    = [];
            _manifestReady = true;

            renderManifest();
            renderUnexpected();
            renderUnknown();
            updateStats();

            var badge = document.getElementById('locBadge');
            badge.innerText = loc + ' -- ' + _manifest.length + ' assets';
            badge.style.display = 'inline-block';
            document.getElementById('btnCommit').disabled = false;
            log('[ROOM] Loaded ' + _manifest.length + ' assets for ' + loc);

            // AUTO FOCUS ON PULL RFID TRIGGER INPUT
            setTimeout(function() {
                focusScanner();
            }, 50);
        }).catch(function(err) { log('[ERROR] ' + err.message); });
    }

    // ============================================================
    // SCAN PROCESSING -- PURE SYNCHRONOUS IN-MEMORY EXECUTION
    // Operates with 0ms latency identical to test_2 so the RFD40 trigger
    // can be held down smoothly without dropping keystrokes or pausing.
    // ============================================================
    function processTag(rawVal) {
        var tok = rawVal.toUpperCase();

        // If user scanned a location barcode (starts with SP) into the trigger input, auto-load room
        if (tok.startsWith('SP') && !tok.includes('EE')) {
            document.getElementById('txtLocation').value = tok;
            loadRoom();
            return;
        }

        var now = Date.now();

        // Start / extend trigger session
        if (!_sessionOpen) {
            _sessionOpen = true;
            _scanStart   = now;
            setStatus('scanning');
            log('[SCAN] Session started -- trigger active');
        }
        clearTimeout(_sessionTimer);
        _sessionTimer = setTimeout(closeSession, IDLE_MS);

        var norm = normalizeTag(tok);

        // Instant O(1) Manifest Match
        if (_manifestReady) {
            var tokNS  = tok.replace(/ /g, '');
            var normNS = norm.replace(/ /g, '');
            var match  = _manifestMap[tokNS] || _manifestMap[normNS] || _manifestMap[tok];

            if (match) {
                var wasNew = match.status !== 'Found';
                match.status = 'Found';
                match.reads = (match.reads || 0) + 1;

                // Targeted in-place DOM update (0ms latency, NO innerHTML re-render during scan)
                var bEl = document.getElementById('badge-' + match.id);
                if (bEl && wasNew) {
                    bEl.className = 'badge badge-found';
                    bEl.innerText = 'Found';
                    log('[FOUND] ' + match.name);
                }
                var rEl = document.getElementById('reads-' + match.id);
                if (rEl) {
                    rEl.innerText = match.reads + 'x';
                    rEl.className = 'reads-pill has-reads';
                }
                updateStats();
                return;
            }
        }

        // Check if already captured in Unknown tags
        if (_tagMap.hasOwnProperty(tok)) {
            var uIdx = _tagMap[tok];
            if (_unknown[uIdx]) {
                _unknown[uIdx].reads++;
                var uEl = document.getElementById('unk-reads-' + uIdx);
                if (uEl) uEl.innerText = _unknown[uIdx].reads + 'x';
            }
            updateStats();
            return;
        }

        // New unmatched tag
        var idx = _unknown.length;
        _tagMap[tok] = idx;
        _unknown.push({ tok: tok, firstSeen: timeStr(), reads: 1 });

        // Append a single row without disturbing the rest of the DOM
        var tbody = document.getElementById('bodyUnknown');
        var empty = tbody.querySelector('.empty-msg');
        if (empty && empty.parentElement) empty.parentElement.remove();

        var row = document.createElement('tr');
        row.innerHTML = '<td style="font-family:Consolas,monospace;font-weight:600;">' + esc(tok) + '</td>' +
                        '<td>' + timeStr() + '</td>' +
                        '<td style="text-align:center;"><span class="reads-pill has-reads" id="unk-reads-' + idx + '">1x</span></td>';
        tbody.appendChild(row);

        updateStats();
        log('[UNKNOWN] ' + tok);
    }

    function normalizeTag(tok) {
        var m = tok.match(/^(\d{3})EE([A-Z0-9]+)$/);
        if (m) {
            var core = m[2];
            if (core.length > 2 && core.slice(-2) === 'FF') core = core.slice(0, -2);
            return m[1] + ' EE' + core;
        }
        return tok;
    }

    // ============================================================
    // SESSION CLOSE -- FIRES 1s AFTER TRIGGER IS RELEASED
    // ============================================================
    function closeSession() {
        _sessionOpen = false;
        setStatus('ready');
        var found = _manifest.filter(function(a){ return a.status === 'Found'; }).length;
        log('[DONE] Trigger idle -- ' + found + ' found out of ' + _manifest.length);

        // Re-sort table once trigger is released so Found items float to the top
        renderManifest();
    }

    function resetScan() {
        if (!confirm('Start a new scan for ' + (_location || 'this room') + '? Counters will be cleared.')) return;
        clearTimeout(_sessionTimer);
        _sessionOpen   = false;
        _tagMap        = {};
        _unknown       = [];
        _unexpected    = [];
        if (_manifest.length) {
            _manifest.forEach(function(a){ a.status = 'Missing'; a.reads = 0; });
        }
        renderManifest();
        renderUnexpected();
        renderUnknown();
        updateStats();
        setStatus('ready');
        log('[RESET] Scan cleared. Pull RFID trigger to begin.');
        focusScanner();
    }

    // ============================================================
    // COMMIT INVENTORY
    // ============================================================
    function commitInventory() {
        var found = _manifest.filter(function(a){ return a.status === 'Found'; });
        if (!found.length) { alert('No assets marked Found yet.'); return; }
        if (!_location) { alert('No room loaded.'); return; }
        if (!confirm('Commit ' + found.length + ' found assets to ' + _location + '?')) return;

        var payload = found.map(function(a){ return { id: a.id }; });
        var username = _currentUser ? _currentUser.username : '';

        fetch('va_zebra_browser_test.aspx/CommitInventory', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ locationName: _location, scanDataJson: JSON.stringify(payload),
                                   siteId: _siteId, username: username })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (d && d.success) {
                alert('Committed ' + d.committed + ' assets to ' + _location);
                log('[COMMIT] ' + d.committed + ' assets successfully committed to ' + _location);
            } else {
                alert('Commit failed: ' + (d ? d.error : 'Unknown'));
            }
        }).catch(function(err){ alert('Error: ' + err.message); });
    }

    // ============================================================
    // RENDER (4-COLUMN COMPACT MOBILE LAYOUT)
    // ============================================================
    function renderManifest() {
        var tbody = document.getElementById('bodyManifest');
        if (!_manifest.length) {
            tbody.innerHTML = '<tr><td colspan="4" class="empty-msg">Scan or type a location to load manifest.</td></tr>';
            return;
        }
        var html = '';
        var sorted = _manifest.slice().sort(function(a, b) {
            if (a.status !== b.status) return a.status === 'Found' ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        sorted.forEach(function(a) {
            var badge = a.status === 'Found'
                ? '<span class="badge badge-found" id="badge-' + a.id + '">Found</span>'
                : '<span class="badge badge-missing" id="badge-' + a.id + '">Missing</span>';

            var subDesc = a.description ? esc(a.description) : '<span style="opacity:0.4;">--</span>';
            var tagSub = a.eil ? ('EIL: ' + esc(a.eil)) : (a.serialnumber ? ('SN: ' + esc(a.serialnumber)) : '');

            html += '<tr id="row-manifest-' + a.id + '">' +
                    '<td>' + badge + '</td>' +
                    '<td><div style="font-weight:700;font-size:13px;">' + esc(a.name) + '</div>' +
                        '<div style="color:var(--muted);font-size:11px;">' + subDesc + '</div></td>' +
                    '<td><div style="font-family:Consolas,monospace;font-size:12px;font-weight:600;">' + esc(a.rfidtag || '--') + '</div>' +
                        '<div style="color:var(--muted);font-size:11px;">' + tagSub + '</div></td>' +
                    '<td style="text-align:center;"><span class="reads-pill ' + (a.reads ? 'has-reads' : '') + '" id="reads-' + a.id + '">' + (a.reads ? a.reads + 'x' : '--') + '</span></td></tr>';
        });
        tbody.innerHTML = html;
    }

    function renderUnexpected() {
        var tbody = document.getElementById('bodyUnexpected');
        if (!_unexpected.length) { tbody.innerHTML = '<tr><td colspan="3" class="empty-msg">None.</td></tr>'; return; }
        var html = '';
        _unexpected.forEach(function(a) {
            html += '<tr>' +
                    '<td><div style="font-weight:700;">' + esc(a.name) + '</div><div style="color:var(--muted);font-size:11px;">' + esc(a.description) + '</div></td>' +
                    '<td>' + esc(a.dbLocation) + '</td>' +
                    '<td style="text-align:center;"><span class="reads-pill has-reads">' + a.reads + 'x</span></td></tr>';
        });
        tbody.innerHTML = html;
    }

    function renderUnknown() {
        var tbody = document.getElementById('bodyUnknown');
        if (!_unknown.length) { tbody.innerHTML = '<tr><td colspan="3" class="empty-msg">None yet.</td></tr>'; return; }
        var html = '';
        _unknown.forEach(function(u, idx) {
            html += '<tr><td style="font-family:Consolas,monospace;font-weight:600;">' + esc(u.tok) + '</td>' +
                    '<td>' + esc(u.firstSeen) + '</td>' +
                    '<td style="text-align:center;"><span class="reads-pill has-reads" id="unk-reads-' + idx + '">' + u.reads + 'x</span></td></tr>';
        });
        tbody.innerHTML = html;
    }

    function updateStats() {
        var found   = _manifest.filter(function(a){ return a.status === 'Found'; }).length;
        var missing = _manifest.filter(function(a){ return a.status === 'Missing'; }).length;
        document.getElementById('cntFound').innerText   = found;
        document.getElementById('cntMissing').innerText = missing;
        document.getElementById('cntUnexp').innerText   = _unexpected.length;
        document.getElementById('cntUnknown').innerText = _unknown.length;
    }

    // ============================================================
    // UI HELPERS
    // ============================================================
    function showTab(name) {
        ['manifest','unexpected','unknown','log'].forEach(function(t) {
            var p = t.charAt(0).toUpperCase() + t.slice(1);
            document.getElementById('panel' + p).style.display = t === name ? '' : 'none';
            document.getElementById('tab'   + p).className = 'tab' + (t === name ? ' active' : '');
        });
    }

    function setStatus(s) {
        var pill = document.getElementById('statusPill');
        var dot  = document.getElementById('pulseDot');
        if (s === 'scanning') {
            pill.className = 'status-pill s-scanning'; pill.innerHTML = '&#9654; SCANNING';
            dot.style.background = '#38bdf8';
        } else if (s === 'paused') {
            pill.className = 'status-pill s-paused'; pill.innerHTML = '&#9646;&#9646; PAUSED';
            dot.style.background = '#f97316';
        } else {
            pill.className = 'status-pill s-ready'; pill.innerHTML = '&#9711; READY';
            dot.style.background = '#10b981';
        }
    }

    function log(msg) {
        var box  = document.getElementById('logBox');
        var line = document.createElement('div');
        line.className = 'log-line';
        line.innerHTML = '<span class="log-ts">' + timeStr() + '</span>' +
                         '<span class="log-msg">' + esc(msg) + '</span>';
        box.appendChild(line);
        box.scrollTop = box.scrollHeight;
    }

    function parse(res) {
        if (!res) return null;
        return typeof res.d === 'string' ? JSON.parse(res.d) : res.d;
    }

    function timeStr() { return new Date().toTimeString().split(' ')[0]; }
    function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
</script>

</body>
</html>