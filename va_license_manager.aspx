<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_license_manager.aspx.cs" Inherits="va_license_manager" %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>License Manager — iDash</title>
<script src="theme-init.js"></script>
<link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
<link rel="stylesheet" href="theme.css" />
<style>
body { font-family:'Inter',sans-serif; background:var(--bg); color:var(--text); margin:0; }
.page { max-width:1100px; margin:0 auto; padding:24px; }
.header { display:flex; align-items:center; justify-content:space-between; margin-bottom:24px; }
.header h1 { font-size:22px; font-weight:800; margin:0; display:flex; align-items:center; gap:10px; }
.header-right { display:flex; gap:8px; align-items:center; }
.nav-pill { display:inline-flex; align-items:center; gap:5px; padding:6px 14px; border-radius:8px; font-size:12px; font-weight:600; text-decoration:none; border:1px solid var(--line); color:var(--muted); cursor:pointer; background:transparent; transition:all .15s; }
.nav-pill:hover { border-color:var(--accent); color:var(--accent); }

.section { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:20px; margin-bottom:20px; }
.section-title { font-size:15px; font-weight:700; margin:0 0 4px 0; display:flex; align-items:center; gap:8px; }
.section-desc { font-size:12px; color:var(--muted); margin:0 0 16px 0; }
.section-count { font-size:12px; font-weight:700; background:color-mix(in srgb, var(--accent) 15%, transparent); color:var(--accent); border-radius:12px; padding:2px 10px; }

table.grid { width:100%; border-collapse:collapse; font-size:13px; }
table.grid th { text-align:left; padding:8px 10px; font-size:11px; font-weight:700; color:var(--muted); text-transform:uppercase; letter-spacing:.5px; border-bottom:2px solid var(--line); }
table.grid td { padding:8px 10px; border-bottom:1px solid var(--line); }
table.grid tr:hover { background:color-mix(in srgb, var(--accent) 5%, transparent); }
.mono { font-family:'JetBrains Mono',monospace; font-size:11px; }
.muted { color:var(--muted); }
.badge { display:inline-block; padding:2px 8px; border-radius:6px; font-size:11px; font-weight:600; }
.badge-ok { background:color-mix(in srgb,#10b981 15%,transparent); color:#10b981; }
.badge-warn { background:color-mix(in srgb,#f59e0b 15%,transparent); color:#f59e0b; }

.btn-del { background:color-mix(in srgb,#ef4444 12%,transparent); color:#ef4444; border:1px solid color-mix(in srgb,#ef4444 30%,transparent); padding:4px 12px; border-radius:6px; font-size:11px; font-weight:600; cursor:pointer; transition:all .15s; }
.btn-del:hover { background:#ef4444; color:#fff; }

.toast { position:fixed; bottom:20px; right:20px; padding:12px 20px; border-radius:10px; font-size:13px; font-weight:600; z-index:9999; transform:translateY(80px); opacity:0; transition:all .3s; }
.toast.show { transform:translateY(0); opacity:1; }
.toast-ok { background:#10b981; color:#fff; }
.toast-err { background:#ef4444; color:#fff; }

.summary-row { display:flex; gap:16px; margin-bottom:20px; }
.summary-card { flex:1; background:var(--card); border:1px solid var(--line); border-radius:10px; padding:16px; text-align:center; }
.summary-val { font-size:28px; font-weight:800; font-family:'JetBrains Mono',monospace; }
.summary-lbl { font-size:11px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.5px; margin-top:4px; }

/* Tabs */
.tabs-bar { display:flex; gap:8px; margin-bottom:24px; border-bottom:1px solid var(--line); padding-bottom:12px; }
.tab-btn { display:inline-flex; align-items:center; gap:8px; padding:9px 18px; border-radius:8px; font-size:13px; font-weight:700; border:1px solid var(--line); background:var(--card); color:var(--muted); cursor:pointer; transition:all .15s; }
.tab-btn:hover { color:var(--text); border-color:var(--accent); }
.tab-btn.active { background:var(--accent); color:var(--bg); border-color:var(--accent); }

pre.code-block { background:#0f172a; color:#e2e8f0; padding:12px 14px; border-radius:8px; font-size:11px; font-family:'JetBrains Mono',monospace; word-break:break-all; white-space:pre-wrap; margin:8px 0; border:1px solid var(--line); max-height:160px; overflow-y:auto; }
.cart-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:12px; flex-wrap:wrap; gap:10px; }
.copy-chip { background:color-mix(in srgb, var(--accent) 15%, transparent); color:var(--accent); border:1px solid color-mix(in srgb, var(--accent) 30%, transparent); padding:4px 10px; border-radius:6px; font-size:11px; font-weight:700; cursor:pointer; transition:all .15s; display:inline-flex; align-items:center; gap:4px; }
.copy-chip:hover { background:var(--accent); color:#fff; }

.btn-primary { background:var(--accent); color:var(--bg); border:none; font-weight:700; padding:8px 16px; border-radius:8px; cursor:pointer; font-size:12px; display:inline-flex; align-items:center; gap:6px; transition:opacity .15s; }
.btn-primary:hover { opacity:0.9; }
.btn-secondary { background:var(--card); color:var(--text); border:1px solid var(--line); font-weight:600; padding:8px 14px; border-radius:8px; cursor:pointer; font-size:12px; display:inline-flex; align-items:center; gap:6px; }
.btn-secondary:hover { border-color:var(--accent); color:var(--accent); }
.btn-outline-danger { background:transparent; color:#ef4444; border:1px solid color-mix(in srgb,#ef4444 40%,transparent); font-weight:600; padding:4px 10px; border-radius:6px; cursor:pointer; font-size:11px; }
.btn-outline-danger:hover { background:#ef4444; color:#fff; }

.cart-card { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:20px; margin-bottom:20px; transition:border-color .15s; }
.cart-card:hover { border-color:color-mix(in srgb,var(--accent) 50%,var(--line)); }
.cart-meta-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(170px, 1fr)); gap:12px; background:color-mix(in srgb, var(--accent) 4%, transparent); border:1px solid var(--line); border-radius:8px; padding:12px 16px; margin:12px 0 16px 0; }
.cart-meta-item { display:flex; flex-direction:column; }
.cart-meta-lbl { font-size:11px; color:var(--muted); text-transform:uppercase; letter-spacing:.5px; font-weight:700; margin-bottom:2px; }
.cart-meta-val { font-size:13px; font-weight:600; }

.toolbar { display:flex; justify-content:space-between; align-items:center; gap:12px; margin-bottom:20px; flex-wrap:wrap; }
.search-box { flex:1; min-width:240px; background:var(--card); border:1px solid var(--line); border-radius:8px; padding:9px 14px; color:var(--text); font-size:13px; outline:none; }
.search-box:focus { border-color:var(--accent); }

/* Modal */
.modal-backdrop { position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.65); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; z-index:9999; padding:20px; }
.modal-backdrop.show { display:flex; }
.modal-dialog { background:var(--card); border:1px solid var(--line); border-radius:14px; width:100%; max-width:680px; max-height:90vh; overflow-y:auto; box-shadow:0 20px 40px rgba(0,0,0,0.4); }
.modal-header { display:flex; justify-content:space-between; align-items:center; padding:18px 24px; border-bottom:1px solid var(--line); }
.modal-header h3 { margin:0; font-size:17px; font-weight:800; display:flex; align-items:center; gap:8px; }
.modal-close { background:transparent; border:none; font-size:22px; color:var(--muted); cursor:pointer; line-height:1; }
.modal-close:hover { color:var(--text); }
.modal-body { padding:24px; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; padding:16px 24px; border-top:1px solid var(--line); }
.form-group { margin-bottom:16px; }
.form-group label { display:block; font-size:12px; font-weight:700; text-transform:uppercase; letter-spacing:.5px; color:var(--muted); margin-bottom:6px; }
.form-input, .form-textarea, .form-select { width:100%; box-sizing:border-box; background:color-mix(in srgb,var(--accent) 3%,var(--bg)); border:1px solid var(--line); border-radius:8px; padding:9px 12px; font-size:13px; color:var(--text); font-family:inherit; }
.form-input:focus, .form-textarea:focus, .form-select:focus { outline:none; border-color:var(--accent); }
.form-row { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
@media(max-width:600px) { .form-row { grid-template-columns:1fr; } }
</style>
</head>
<body>
<div class="page">
    <div class="header">
        <h1>&#128273; License Manager</h1>
        <div class="header-right">
            <button class="nav-pill" onclick="location.reload()">&#8635; Refresh</button>
            <button class="nav-pill" id="themeBtn" onclick="toggleTheme()" title="Toggle light/dark">☀️</button>
            <a href="documentation/va_software_agreement.html" target="_blank" class="nav-pill">&#128220; Usage Agreement</a>
            <a href="va_license_activation.aspx" class="nav-pill">&#128273; Local Activation</a>
            <a href="va_site_config.aspx" class="nav-pill">&#9881; Site Config</a>
            <a href="documentation/va_license_manager.html" target="_blank" class="nav-pill">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
        </div>
    </div>

    <!-- Mode Tabs -->
    <div class="tabs-bar">
        <button type="button" class="tab-btn active" id="tabLiveBtn" onclick="switchTab('live')">&#128225; Active Readers &amp; Device Licenses</button>
        <button type="button" class="tab-btn" id="tabCartsBtn" onclick="switchTab('carts')">&#128722; Mobile Carts &amp; Workstations Registry</button>
        <a href="va_license_activation.aspx" class="tab-btn" style="text-decoration:none;">&#128273; Local iDash Activation</a>
    </div>

    <!-- TAB 1: LIVE DATABASE LICENSES -->
    <div id="viewLive">
        <div class="summary-row" id="summaryRow"></div>

        <div class="section">
            <h2 class="section-title">&#128225; Registered Readers <span class="section-count" id="readerCount"></span></h2>
            <p class="section-desc">Fixed RFID readers in the database. Each consumes a reader license slot.</p>
            <div id="readerGrid">Loading...</div>
        </div>

        <div class="section">
            <h2 class="section-title">&#128421; Server Registrations <span class="section-count" id="serverCount"></span></h2>
            <p class="section-desc">Registered services (AMS, print servers). Re-register automatically if still running.</p>
            <div id="serverGrid">Loading...</div>
        </div>

        <div class="section">
            <h2 class="section-title">&#128241; Scanner Users <span class="section-count" id="userCount"></span></h2>
            <p class="section-desc">Mobile/handheld scanner user accounts. Each consumes a user license slot.</p>
            <div id="userGrid">Loading...</div>
        </div>

        <div class="section">
            <h2 class="section-title">&#128241; Scanners (Handheld Devices) <span class="section-count" id="scannerCount"></span></h2>
            <p class="section-desc">Registered handheld RFID scanners. Same list as <a href="http://localhost/#!/admin/scanners" target="_blank" style="color:var(--accent);">AssetWorx Admin &rarr; Scanners</a>. Each consumes a device license slot.</p>
            <div id="scannerGrid">Loading...</div>
        </div>

        <div class="section">
            <h2 class="section-title">&#128268; MQTT Clients <span class="section-count" id="mqttCount"></span></h2>
            <p class="section-desc">MQTT client registrations for data subscriptions.</p>
            <div id="mqttGrid">Loading...</div>
        </div>
    </div>

    <!-- TAB 2: MOBILE CARTS & WORKSTATIONS REGISTRY -->
    <div id="viewCarts" style="display:none;">
        <div class="section" style="border-left:4px solid #38bdf8; background:color-mix(in srgb, #38bdf8 8%, var(--card));">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:12px;">
                <div>
                    <h2 class="section-title" style="color:#38bdf8;">&#128722; Mobile Carts &amp; Workstations Registry</h2>
                    <p class="section-desc" style="margin-bottom:0;">
                        Central tracking repository for all mobile carts and field workstations across VA facilities. 
                        Maintains both the <strong>modern cryptographic iDash portal license</strong> (RSA-2048) and the <strong>legacy AssetWorx core database license</strong>.
                    </p>
                </div>
                <div style="display:flex; gap:8px;">
                    <a href="va_license_activation.aspx" class="btn-secondary" style="text-decoration:none;">&#128273; Activate Local Machine</a>
                    <button type="button" class="btn-primary" onclick="openAddCartModal()">&#10010; Register New Cart</button>
                </div>
            </div>
        </div>

        <!-- Toolbar -->
        <div class="toolbar">
            <input type="text" id="cartSearchInput" class="search-box" placeholder="Search carts by name, site, station number, hardware ID..." oninput="filterCarts()" />
            <div style="display:flex; gap:8px; align-items:center;">
                <span class="muted" style="font-size:12px;" id="cartCountBadge">0 registered</span>
            </div>
        </div>

        <!-- Dynamic Cart Cards Container -->
        <div id="cartListContainer">
            <div class="muted" style="text-align:center; padding:40px;">Loading registered carts...</div>
        </div>

        <!-- Troubleshooting Reference -->
        <div class="section" style="border-left:4px solid #f59e0b; margin-top:30px;">
            <h2 class="section-title" style="color:#f59e0b;">&#9888; Standalone Cart Licensing &amp; Deployment Guide</h2>
            <div style="margin-top:12px;">
                <p style="font-size:13px; font-weight:700; margin:0 0 4px 0;">1. Understanding the Two License Layers:</p>
                <p style="font-size:12px; color:var(--muted); margin:0 0 10px 0;">
                    &bull; <strong>iDash Portal License (Modern RSA-2048)</strong>: Activated on each cart via <a href="va_license_activation.aspx" style="color:var(--accent);">va_license_activation.aspx</a> using the <code>.idashlic</code> file or key string. Locks web portal modules and sync tools to the cart's Installation ID.<br />
                    &bull; <strong>AssetWorx Core License (Legacy SQL Engine)</strong>: Stored in <code>dbo.applicationsetting.licensekey</code>. Locks backend SQL database, fixed readers (max 5), and scanner users to the motherboard Ethernet MAC.
                </p>

                <p style="font-size:13px; font-weight:700; margin:0 0 4px 0;">2. How to License a New Mobile Cart:</p>
                <p style="font-size:12px; color:var(--muted); margin:0 0 10px 0;">
                    Step 1: On the cart, browse to <code>http://localhost/idash/va_license_activation.aspx</code> and copy its <strong>Installation ID</strong> (e.g. <code>IDASH-80E4-5E4F-033F</code>).<br />
                    Step 2: On your admin PC, run <code>.\New-IdashLicense.ps1 -InstallationId "IDASH-..." -Customer "..." -SiteName "..." -Perpetual -OutputFile "cart.idashlic"</code>.<br />
                    Step 3: Click <strong>Register New Cart</strong> above to save it here in the central registry, then download or copy the key right onto the cart!
                </p>

                <p style="font-size:13px; font-weight:700; margin:0 0 4px 0;">3. Blank Screen / HTTP 500 After Login on Cart:</p>
                <p style="font-size:12px; color:var(--muted); margin:0 0 10px 0;">Check <code>C:\inetpub\wwwroot\AssetWorx.WebClient\appsettings.json</code>. Ensure: <code>"AuthServerUrl": "http://localhost"</code>. If it points to a computer name, internal token validation fails with timeout error IDX20803.</p>

                <p style="font-size:13px; font-weight:700; margin:0 0 4px 0;">4. Site Data Synchronization:</p>
                <p style="font-size:12px; color:var(--muted); margin:0;">Once licensed, use the <a href="va_sitedata_export.aspx" style="color:var(--accent); font-weight:700;">Cart Data &amp; Sync Hub</a> to clone or Smart Merge canonical master records onto the cart with 1 click.</p>
            </div>
        </div>
    </div>
</div>

<!-- CART MODAL -->
<div id="cartModal" class="modal-backdrop">
    <div class="modal-dialog">
        <div class="modal-header">
            <h3 id="modalCartTitle">&#128722; Register Cart / Workstation</h3>
            <button type="button" class="modal-close" onclick="closeCartModal()">&times;</button>
        </div>
        <div class="modal-body">
            <input type="hidden" id="modalCartId" />
            <div class="form-row">
                <div class="form-group">
                    <label>Cart / Workstation Name *</label>
                    <input type="text" id="modalCartName" class="form-input" placeholder="e.g. ID Integration Tagging Cart 1" />
                </div>
                <div class="form-group">
                    <label>Facility / Site *</label>
                    <input type="text" id="modalCartSite" class="form-input" placeholder="e.g. VAMC Facility or Traveling cart" />
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>Station Number</label>
                    <input type="text" id="modalCartStation" class="form-input" placeholder="e.g. Station Number, or ALL" />
                </div>
                <div class="form-group">
                    <label>Status</label>
                    <select id="modalCartStatus" class="form-select">
                        <option value="Active">Active</option>
                        <option value="Standby">Standby</option>
                        <option value="Provisioning">Provisioning</option>
                        <option value="Retired">Retired</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>Installation ID (iDash Hardware ID)</label>
                    <input type="text" id="modalCartInstallId" class="form-input mono" placeholder="e.g. IDASH-80E4-5E4F-033F" />
                </div>
                <div class="form-group">
                    <label>Primary Ethernet MAC Address (AssetWorx Hardware)</label>
                    <input type="text" id="modalCartMac" class="form-input mono" placeholder="e.g. 04:64:FA:FE:7F:A8" />
                </div>
            </div>
            <div class="form-group">
                <label>iDash Cryptographic License Key (RSA-2048)</label>
                <textarea id="modalCartIdashKey" class="form-textarea mono" rows="3" placeholder="IDASH-LIC-v1-... (Paste cryptographic key here)"></textarea>
            </div>
            <div class="form-group">
                <label>AssetWorx Core SQL Engine License Key</label>
                <textarea id="modalCartAwKey" class="form-textarea mono" rows="3" placeholder="ew0KICAiTGljZW5zZUtleSI6... (Base64 SQL license string)"></textarea>
            </div>
            <div class="form-group">
                <label>Deployment Notes / Description</label>
                <textarea id="modalCartNotes" class="form-textarea" rows="2" placeholder="e.g. Assigned to logistics for annual inventory sweep..."></textarea>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-secondary" onclick="closeCartModal()">Cancel</button>
            <button type="button" class="btn-primary" onclick="saveCartModal()">&#128190; Save Cart Record</button>
        </div>
    </div>
</div>

<div id="toast" class="toast"></div>

<script>
var cartsData = [];
var allCartsLoaded = false;

function api(cmd) {
    return fetch('va_license_manager.aspx?action=api&cmd=' + cmd).then(function(r) { return r.json(); });
}
function apiPost(cmd, body) {
    return fetch('va_license_manager.aspx?action=api&cmd=' + cmd, {
        method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)
    }).then(function(r) { return r.json(); });
}
function toast(msg, ok) {
    var t = document.getElementById('toast');
    t.className = 'toast ' + (ok ? 'toast-ok' : 'toast-err');
    t.textContent = msg;
    t.classList.add('show');
    setTimeout(function() { t.classList.remove('show'); }, 3000);
}
function esc(s) { return (s||'').replace(/'/g, "\\'").replace(/"/g, '&quot;'); }
function timeSince(dt) {
    if (!dt) return 'Never';
    var diff = Date.now() - new Date(dt).getTime();
    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return Math.floor(diff/60000) + 'm ago';
    if (diff < 86400000) return Math.floor(diff/3600000) + 'h ago';
    return Math.floor(diff/86400000) + 'd ago';
}

async function loadAll() {
    var data = await api('getAll');
    if (data.error) { toast(data.error, false); return; }

    var totalReaders = data.readers.length + data.scanners.length;
    var readerLimit = 5; // License: Readers=5
    var readerColor = totalReaders >= readerLimit ? '#ef4444' : '#10b981';

    document.getElementById('summaryRow').innerHTML =
        '<div class="summary-card" style="border-color:' + readerColor + '"><div class="summary-val" style="color:' + readerColor + '">' + totalReaders + ' / ' + readerLimit + '</div><div class="summary-lbl">Reader License Slots</div><div style="font-size:10px;color:var(--muted);margin-top:4px;">' + data.readers.length + ' fixed + ' + data.scanners.length + ' handhelds</div></div>' +
        '<div class="summary-card"><div class="summary-val">' + data.servers.length + '</div><div class="summary-lbl">Servers</div></div>' +
        '<div class="summary-card"><div class="summary-val">' + data.users.length + '</div><div class="summary-lbl">Scanner Users</div></div>' +
        '<div class="summary-card"><div class="summary-val">' + data.mqttClients.length + '</div><div class="summary-lbl">MQTT Clients</div></div>';

    renderReaders(data.readers);
    renderServers(data.servers);
    renderUsers(data.users);
    renderScanners(data.scanners);
    renderMqtt(data.mqttClients);
}

function renderReaders(list) {
    document.getElementById('readerCount').textContent = list.length;
    if (!list.length) { document.getElementById('readerGrid').innerHTML = '<div class="muted" style="padding:12px;">No readers.</div>'; return; }
    var h = '<table class="grid"><thead><tr><th>ID</th><th>Name</th><th>Model</th><th>IP</th><th>Location</th><th>Last Seen</th><th>Status</th><th></th></tr></thead><tbody>';
    list.forEach(function(r) {
        var stale = !r.lastSeen || (Date.now()-new Date(r.lastSeen).getTime()) > 86400000;
        h += '<tr><td class="mono">'+r.id+'</td><td><strong>'+r.name+'</strong></td><td>'+(r.model||'—')+'</td><td class="mono">'+(r.ip||'—')+'</td><td>'+(r.location||'—')+'</td><td class="mono">'+timeSince(r.lastSeen)+'</td><td>'+(stale?'<span class="badge badge-warn">Stale</span>':'<span class="badge badge-ok">Active</span>')+'</td><td><button class="btn-del" onclick="del(\'reader\','+r.id+',\''+esc(r.name)+'\')">Delete</button></td></tr>';
    });
    document.getElementById('readerGrid').innerHTML = h + '</tbody></table>';
}
function renderServers(list) {
    document.getElementById('serverCount').textContent = list.length;
    if (!list.length) { document.getElementById('serverGrid').innerHTML = '<div class="muted" style="padding:12px;">No servers.</div>'; return; }
    var h = '<table class="grid"><thead><tr><th>ID</th><th>Name</th><th>Type</th><th>Version</th><th>Last Seen</th><th></th></tr></thead><tbody>';
    list.forEach(function(s) {
        h += '<tr><td class="mono">'+s.id+'</td><td><strong>'+s.name+'</strong></td><td>'+(s.serverType||'—')+'</td><td class="mono">'+(s.version||'—')+'</td><td class="mono">'+timeSince(s.lastSeen)+'</td><td><button class="btn-del" onclick="del(\'server\','+s.id+',\''+esc(s.name)+'\')">Delete</button></td></tr>';
    });
    document.getElementById('serverGrid').innerHTML = h + '</tbody></table>';
}
function renderUsers(list) {
    document.getElementById('userCount').textContent = list.length;
    if (!list.length) { document.getElementById('userGrid').innerHTML = '<div class="muted" style="padding:12px;">No scanner users.</div>'; return; }
    var h = '<table class="grid"><thead><tr><th>ID</th><th>Username</th><th>Name</th><th>Site</th><th>Type</th><th></th></tr></thead><tbody>';
    list.forEach(function(u) {
        h += '<tr><td class="mono">'+u.id+'</td><td><strong>'+u.username+'</strong></td><td>'+(u.fullName||'—')+'</td><td>'+(u.site||'—')+'</td><td>'+(u.userType||'—')+'</td><td><button class="btn-del" onclick="del(\'user\','+u.id+',\''+esc(u.username)+'\')">Delete</button></td></tr>';
    });
    document.getElementById('userGrid').innerHTML = h + '</tbody></table>';
}
function renderScanners(list) {
    document.getElementById('scannerCount').textContent = list.length;
    if (!list.length) { document.getElementById('scannerGrid').innerHTML = '<div class="muted" style="padding:12px;">No scanners registered.</div>'; return; }
    var h = '<table class="grid"><thead><tr><th>ID</th><th>Device ID</th><th>Site</th><th>Last Seen</th><th>Status</th><th></th></tr></thead><tbody>';
    list.forEach(function(s) {
        var stale = !s.lastSeen || (Date.now()-new Date(s.lastSeen).getTime()) > 86400000*30; // 30 days
        var badge = s.inactive ? '<span class="badge badge-err">Inactive</span>' : (stale ? '<span class="badge badge-warn">Stale</span>' : '<span class="badge badge-ok">Active</span>');
        h += '<tr><td class="mono">'+s.id+'</td><td><strong class="mono">'+s.deviceId+'</strong></td><td>'+(s.site||'—')+'</td><td class="mono">'+timeSince(s.lastSeen)+'</td><td>'+badge+'</td><td><button class="btn-del" onclick="del(\'scanner\','+s.id+',\''+esc(s.deviceId)+'\')">Delete</button></td></tr>';
    });
    document.getElementById('scannerGrid').innerHTML = h + '</tbody></table>';
}
function renderMqtt(list) {
    document.getElementById('mqttCount').textContent = list.length;
    if (!list.length) { document.getElementById('mqttGrid').innerHTML = '<div class="muted" style="padding:12px;">No MQTT clients.</div>'; return; }
    var h = '<table class="grid"><thead><tr><th>ID</th><th>Username</th><th>Site</th><th></th></tr></thead><tbody>';
    list.forEach(function(m) {
        h += '<tr><td class="mono">'+m.id+'</td><td><strong>'+m.username+'</strong></td><td>'+(m.site||'—')+'</td><td><button class="btn-del" onclick="del(\'mqtt\','+m.id+',\''+esc(m.username)+'\')">Delete</button></td></tr>';
    });
    document.getElementById('mqttGrid').innerHTML = h + '</tbody></table>';
}

async function del(type, id, name) {
    var labels = {reader:'reader',server:'server registration',user:'scanner user',scanner:'scanner (handheld)',mqtt:'MQTT client'};
    if (!confirm('Delete '+labels[type]+' "'+name+'" (ID '+id+')?\n\nThis frees the license slot.')) return;
    var cmds = {reader:'deleteReader',server:'deleteServer',user:'deleteUser',scanner:'deleteScanner',mqtt:'deleteMqtt'};
    var data = await apiPost(cmds[type], {id:id});
    if (data.error) toast('Error: '+data.error, false);
    else { toast('"'+name+'" deleted', true); loadAll(); }
}

/* ========================================================
   CARTS & WORKSTATIONS REGISTRY
   ======================================================== */
async function loadCarts() {
    try {
        var data = await api('getCarts');
        if (Array.isArray(data)) {
            cartsData = data;
            allCartsLoaded = true;
            renderCarts(cartsData);
        } else if (data.error) {
            toast('Failed to load carts: ' + data.error, false);
        }
    } catch(e) {
        toast('Error loading cart registry: ' + e.message, false);
    }
}

function filterCarts() {
    var q = (document.getElementById('cartSearchInput').value || '').trim().toLowerCase();
    if (!q) {
        renderCarts(cartsData);
        return;
    }
    var filtered = cartsData.filter(function(c) {
        return (c.name || '').toLowerCase().includes(q) ||
               (c.site || '').toLowerCase().includes(q) ||
               (c.stationNumber || '').toLowerCase().includes(q) ||
               (c.installationId || '').toLowerCase().includes(q) ||
               (c.hardwareId || '').toLowerCase().includes(q) ||
               (c.notes || '').toLowerCase().includes(q);
    });
    renderCarts(filtered);
}

function renderCarts(list) {
    var container = document.getElementById('cartListContainer');
    document.getElementById('cartCountBadge').textContent = (list.length) + ' of ' + cartsData.length + ' registered';

    if (!list || !list.length) {
        container.innerHTML = '<div class="section" style="text-align:center; padding:32px; color:var(--muted);"><p style="font-size:14px; margin-bottom:12px;">No matching carts found in the registry.</p><button type="button" class="btn-primary" onclick="openAddCartModal()">&#10010; Register First Cart</button></div>';
        return;
    }

    var html = '';
    list.forEach(function(cart) {
        var isOnline = (cart.status || '').toLowerCase() === 'active';
        var statusBadge = isOnline ? '<span class="badge badge-ok">Active</span>' : '<span class="badge badge-warn">' + (cart.status || 'Provisioning') + '</span>';

        // Powershell script generation
        var psScript = '';
        if (cart.awLicenseKey) {
            psScript = '$lic = "' + cart.awLicenseKey.replace(/"/g, '`"') + '"\r\n' +
                '$conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\\sqlexpress;Database=assetworx;User Id=assetworxadmin;Password=assetworxadmin;")\r\n' +
                '$conn.Open()\r\n' +
                '$cmd = $conn.CreateCommand()\r\n' +
                '$cmd.CommandText = "UPDATE applicationsetting SET licensekey = @lic"\r\n' +
                '$cmd.Parameters.AddWithValue("@lic", $lic) | Out-Null\r\n' +
                '$cmd.ExecuteNonQuery() | Out-Null\r\n' +
                '$conn.Close()\r\n' +
                'iisreset';
        }

        html += '<div class="cart-card" id="card-' + cart.id + '">' +
            '<div class="cart-header">' +
                '<div>' +
                    '<h2 class="section-title" style="color:var(--accent); font-size:16px;">' +
                        '&#128722; ' + (cart.name || 'Unnamed Cart') + ' ' + statusBadge +
                    '</h2>' +
                    '<span class="muted" style="font-size:12px;">' + (cart.site || 'VA Facility') + (cart.stationNumber ? ' &bull; Station ' + cart.stationNumber : '') + '</span>' +
                '</div>' +
                '<div style="display:flex; gap:6px; align-items:center;">' +
                    '<button type="button" class="copy-chip" onclick="openEditCartModal(\'' + cart.id + '\')">&#9998; Edit</button>' +
                    '<button type="button" class="btn-outline-danger" onclick="deleteCartItem(\'' + cart.id + '\', \'' + esc(cart.name) + '\')">&#128465;</button>' +
                '</div>' +
            '</div>';

        // Meta Grid
        html += '<div class="cart-meta-grid">' +
            '<div class="cart-meta-item"><span class="cart-meta-lbl">Installation ID</span><span class="cart-meta-val mono" style="color:var(--accent);">' + (cart.installationId || '&mdash;') + '</span></div>' +
            '<div class="cart-meta-item"><span class="cart-meta-lbl">Ethernet MAC</span><span class="cart-meta-val mono">' + (cart.hardwareId || '&mdash;') + '</span></div>' +
            '<div class="cart-meta-item"><span class="cart-meta-lbl">License Tier</span><span class="cart-meta-val">' + (cart.licenseType || 'Perpetual') + '</span></div>' +
            '<div class="cart-meta-item"><span class="cart-meta-lbl">Deployment Notes</span><span class="cart-meta-val muted" style="font-size:12px;">' + (cart.notes || 'None recorded') + '</span></div>' +
        '</div>';

        // iDash Cryptographic License Key Section
        html += '<div style="margin-top:14px; padding-top:14px; border-top:1px solid var(--line);">' +
            '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">' +
                '<span style="font-size:12px; font-weight:700; color:var(--text); display:flex; align-items:center; gap:6px;">' +
                    '&#128273; Modern iDash Portal License (RSA-2048):' +
                '</span>' +
                '<div style="display:flex; gap:6px;">';
        if (cart.idashLicenseKey) {
            html += '<a href="va_license_manager.aspx?action=downloadCart&id=' + cart.id + '" class="copy-chip" style="text-decoration:none;">&#128190; Download .idashlic</a>' +
                    '<button type="button" class="copy-chip" onclick="copyRawText(\'' + esc(cart.idashLicenseKey) + '\', \'iDash License Key copied!\')">&#128203; Copy Key</button>';
        } else {
            html += '<span class="muted" style="font-size:11px;">Not yet issued</span>';
        }
        html += '</div></div>';

        if (cart.idashLicenseKey) {
            html += '<pre class="code-block" id="idashKey-' + cart.id + '">' + cart.idashLicenseKey + '</pre>';
        } else {
            html += '<div class="muted" style="font-size:12px; font-style:italic; padding:8px 0;">No cryptographic iDash portal license registered for this cart yet. Generate via New-IdashLicense.ps1 and click Edit to paste.</div>';
        }
        html += '</div>';

        // AssetWorx Core Engine License Section
        if (cart.awLicenseKey) {
            html += '<div style="margin-top:14px; padding-top:14px; border-top:1px dashed var(--line);">' +
                '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">' +
                    '<span style="font-size:12px; font-weight:700; color:var(--text); display:flex; align-items:center; gap:6px;">' +
                        '&#9881; Legacy AssetWorx Core SQL License:' +
                    '</span>' +
                    '<div style="display:flex; gap:6px;">' +
                        '<button type="button" class="copy-chip" onclick="copyRawText(\'' + esc(cart.awLicenseKey) + '\', \'AssetWorx SQL Key copied!\')">&#128203; Copy SQL Key</button>' +
                        '<button type="button" class="copy-chip" onclick="copyRawText(\'' + esc(psScript) + '\', \'PowerShell SQL script copied!\')">&#128203; Copy PS Script</button>' +
                    '</div>' +
                '</div>' +
                '<pre class="code-block">' + cart.awLicenseKey + '</pre>' +
            '</div>';
        }

        html += '</div>';
    });

    container.innerHTML = html;
}

/* ========================================================
   MODAL DIALOG OPERATIONS
   ======================================================== */
function openAddCartModal() {
    document.getElementById('modalCartTitle').innerHTML = '&#128722; Register New Cart / Workstation';
    document.getElementById('modalCartId').value = '';
    document.getElementById('modalCartName').value = '';
    document.getElementById('modalCartSite').value = '';
    document.getElementById('modalCartStation').value = '';
    document.getElementById('modalCartStatus').value = 'Active';
    document.getElementById('modalCartInstallId').value = '';
    document.getElementById('modalCartMac').value = '';
    document.getElementById('modalCartIdashKey').value = '';
    document.getElementById('modalCartAwKey').value = '';
    document.getElementById('modalCartNotes').value = '';
    document.getElementById('cartModal').classList.add('show');
}

function openEditCartModal(id) {
    var cart = cartsData.find(function(c) { return c.id === id; });
    if (!cart) return;

    document.getElementById('modalCartTitle').innerHTML = '&#9998; Edit Cart &mdash; ' + esc(cart.name);
    document.getElementById('modalCartId').value = cart.id || '';
    document.getElementById('modalCartName').value = cart.name || '';
    document.getElementById('modalCartSite').value = cart.site || '';
    document.getElementById('modalCartStation').value = cart.stationNumber || '';
    document.getElementById('modalCartStatus').value = cart.status || 'Active';
    document.getElementById('modalCartInstallId').value = cart.installationId || '';
    document.getElementById('modalCartMac').value = cart.hardwareId || '';
    document.getElementById('modalCartIdashKey').value = cart.idashLicenseKey || '';
    document.getElementById('modalCartAwKey').value = cart.awLicenseKey || '';
    document.getElementById('modalCartNotes').value = cart.notes || '';
    document.getElementById('cartModal').classList.add('show');
}

function closeCartModal() {
    document.getElementById('cartModal').classList.remove('show');
}

async function saveCartModal() {
    var name = (document.getElementById('modalCartName').value || '').trim();
    var site = (document.getElementById('modalCartSite').value || '').trim();
    if (!name || !site) {
        toast('Cart name and facility/site are required.', false);
        return;
    }

    var payload = {
        id: document.getElementById('modalCartId').value || '',
        name: name,
        site: site,
        stationNumber: (document.getElementById('modalCartStation').value || '').trim(),
        status: document.getElementById('modalCartStatus').value,
        installationId: (document.getElementById('modalCartInstallId').value || '').trim(),
        hardwareId: (document.getElementById('modalCartMac').value || '').trim(),
        idashLicenseKey: (document.getElementById('modalCartIdashKey').value || '').trim(),
        awLicenseKey: (document.getElementById('modalCartAwKey').value || '').trim(),
        licenseType: 'Perpetual',
        notes: (document.getElementById('modalCartNotes').value || '').trim()
    };

    var res = await apiPost('saveCart', payload);
    if (res.error) {
        toast('Failed to save cart: ' + res.error, false);
    } else {
        toast('Cart "' + name + '" saved successfully!', true);
        closeCartModal();
        loadCarts();
    }
}

async function deleteCartItem(id, name) {
    if (!confirm('Are you sure you want to remove "' + name + '" from the cart license registry?')) return;
    var res = await apiPost('deleteCart', { id: id });
    if (res.error) {
        toast('Failed to delete cart: ' + res.error, false);
    } else {
        toast('Cart "' + name + '" removed', true);
        loadCarts();
    }
}

function copyRawText(txt, msg) {
    if (!txt) return;
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(txt).then(function() {
            toast(msg || 'Copied to clipboard!', true);
        }).catch(function() {
            fallbackCopy(txt, msg);
        });
    } else {
        fallbackCopy(txt, msg);
    }
}

function toggleTheme() {
    var html = document.documentElement;
    var isDark = html.getAttribute('data-theme') !== 'light';
    var next = isDark ? 'light' : 'dark';
    if (next === 'dark') html.removeAttribute('data-theme');
    else html.setAttribute('data-theme', next);
    localStorage.setItem('idash_theme', next === 'dark' ? '' : next);
    updateThemeBtn();
}
function updateThemeBtn() {
    var btn = document.getElementById('themeBtn');
    if (!btn) return;
    var isLight = document.documentElement.getAttribute('data-theme') === 'light';
    btn.textContent = isLight ? '🌙' : '☀️';
}
updateThemeBtn();

function switchTab(tab) {
    var isLive = (tab === 'live');
    var liveEl = document.getElementById('viewLive');
    var cartsEl = document.getElementById('viewCarts');
    var liveBtn = document.getElementById('tabLiveBtn');
    var cartsBtn = document.getElementById('tabCartsBtn');
    if (liveEl) liveEl.style.display = isLive ? 'block' : 'none';
    if (cartsEl) {
        cartsEl.style.display = isLive ? 'none' : 'block';
        if (!isLive && !allCartsLoaded) loadCarts();
    }
    if (liveBtn) liveBtn.className = 'tab-btn' + (isLive ? ' active' : '');
    if (cartsBtn) cartsBtn.className = 'tab-btn' + (!isLive ? ' active' : '');
    if (history.replaceState) {
        history.replaceState(null, '', isLive ? '#sec-live' : '#sec-carts');
    }
}

function copyText(id, msg) {
    var el = document.getElementById(id);
    if (!el) return;
    var txt = (el.innerText || el.textContent || '').trim();
    copyRawText(txt, msg);
}

function fallbackCopy(txt, msg) {
    var ta = document.createElement('textarea');
    ta.value = txt;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try {
        document.execCommand('copy');
        toast(msg || 'Copied to clipboard!', true);
    } catch(e) {
        toast('Failed to copy', false);
    }
    document.body.removeChild(ta);
}

if (location.hash === '#sec-carts' || location.hash === '#carts') {
    switchTab('carts');
} else {
    loadAll();
}

window.addEventListener('hashchange', function() {
    if (location.hash === '#sec-carts' || location.hash === '#carts') {
        switchTab('carts');
    } else {
        switchTab('live');
    }
});
</script>
</body>
</html>
