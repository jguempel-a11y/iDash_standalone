<%@ Page Language="C#" ResponseEncoding="utf-8" AutoEventWireup="true" CodeFile="va_print_admin.aspx.cs" Inherits="va_print_admin" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Print Administration &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        body { background:var(--bg); color:var(--text); font-family:Segoe UI, Arial; padding:20px; margin:0; }
        .page-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; flex-wrap:wrap; gap:10px; }
        .page-header h1 { font-size:22px; margin:0; }
        .page-header .nav-links { display:flex; gap:8px; }
        .page-header .nav-links a { font-size:13px; color:var(--accent); text-decoration:none; padding:6px 12px; border:1px solid var(--line); border-radius:8px; }
        .page-header .nav-links a:hover { background:color-mix(in srgb, var(--accent) 10%, transparent); }

        /* Tabs */
        .tab-bar { display:flex; gap:0; border-bottom:2px solid var(--line); margin-bottom:20px; }
        .tab-btn { padding:12px 20px; cursor:pointer; font-size:14px; font-weight:600; color:var(--muted);
                   border:none; background:none; border-bottom:3px solid transparent; margin-bottom:-2px; transition:all .2s; }
        .tab-btn:hover { color:var(--text); }
        .tab-btn.active { color:var(--accent); border-bottom-color:var(--accent); }
        .tab-panel { display:none; }
        .tab-panel.active { display:block; }

        /* Cards & panels */
        .panel { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:18px; margin-bottom:18px; }
        .panel-title { font-size:16px; font-weight:700; margin-bottom:12px; display:flex; align-items:center; gap:8px; }
        .muted { color:var(--muted); font-size:13px; }

        /* Grid */
        .gridWrap { overflow-x:auto; border:1px solid var(--line); border-radius:12px; }
        .grid { width:100%; border-collapse:collapse; font-size:13px; }
        .grid th { background:var(--chip); color:var(--accent); padding:10px 12px; text-align:left; border-bottom:2px solid var(--line); white-space:nowrap; }
        .grid td { padding:10px 12px; border-bottom:1px solid var(--line); }
        .grid tr:hover td { background:color-mix(in srgb, var(--accent) 5%, transparent); }

        /* Status badges */
        .badge { display:inline-block; padding:3px 10px; border-radius:20px; font-size:11px; font-weight:700; }
        .badge-ok { background:color-mix(in srgb, #10b981 15%, transparent); color:#10b981; border:1px solid #10b981; }
        .badge-warn { background:color-mix(in srgb, #f59e0b 15%, transparent); color:#f59e0b; border:1px solid #f59e0b; }
        .badge-err { background:color-mix(in srgb, #ef4444 15%, transparent); color:#ef4444; border:1px solid #ef4444; }
        .badge-info { background:color-mix(in srgb, var(--accent) 15%, transparent); color:var(--accent); border:1px solid var(--accent); }

        /* Buttons */
        .btn { border:2px solid var(--accent); background:transparent; color:var(--accent); padding:8px 16px;
               border-radius:8px; cursor:pointer; font-weight:600; font-size:13px; transition:all .2s; }
        .btn:hover { background:color-mix(in srgb, var(--accent) 10%, transparent); }
        .btn-fill { background:var(--accent); color:var(--bg); border-color:var(--accent); }
        .btn-fill:hover { opacity:.9; }
        .btn-sm { padding:5px 10px; font-size:11px; }
        .btn-danger { border-color:var(--danger); color:var(--danger); }
        .btn-danger:hover { background:color-mix(in srgb, var(--danger) 10%, transparent); }
        .btn-success { border-color:#10b981; color:#10b981; }
        .btn-success:hover { background:color-mix(in srgb, #10b981 10%, transparent); }

        /* Forms */
        .form-row { display:flex; gap:12px; flex-wrap:wrap; margin-bottom:12px; }
        .form-group { display:flex; flex-direction:column; gap:4px; }
        .form-group label { font-size:11px; font-weight:700; text-transform:uppercase; color:var(--muted); letter-spacing:.5px; }
        .form-group input, .form-group select { background:var(--chip); border:1px solid var(--line); color:var(--text);
            padding:8px 12px; border-radius:8px; outline:none; font-size:13px; min-width:160px; }
        .form-group input:focus, .form-group select:focus { border-color:var(--accent); }

        /* Modal */
        .modal-overlay { position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,.5);
            display:none; justify-content:center; align-items:center; z-index:9999; }
        .modal-overlay.show { display:flex; }
        .modal { background:var(--card); border:1px solid var(--line); border-radius:16px; padding:24px;
            min-width:420px; max-width:600px; max-height:80vh; overflow-y:auto; }
        .modal h3 { margin:0 0 16px 0; font-size:18px; }

        /* Status cards */
        .status-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:14px; margin-bottom:20px; }
        .status-card { background:var(--chip); border:1px solid var(--line); border-radius:12px; padding:16px; }
        .status-card .sc-label { font-size:11px; text-transform:uppercase; color:var(--muted); letter-spacing:.5px; margin-bottom:6px; }
        .status-card .sc-value { font-size:22px; font-weight:700; }

        /* Log viewer */
        .log-box { background:#0d1117; color:#c9d1d9; font-family:'Cascadia Code', 'Fira Code', monospace;
            font-size:12px; padding:14px; border-radius:10px; white-space:pre-wrap; word-break:break-all;
            max-height:300px; overflow-y:auto; line-height:1.6; }

        /* Overview status row */
        .site-status { display:flex; align-items:center; gap:6px; }
    </style>
</head>
<body>
<form id="form1" runat="server">

<div class="page-header">
    <h1>&#128424; Print Administration</h1>
    <div class="nav-links">
        <a href="va_print_setup_wizard.aspx" style="background:#f59e0b; color:#000; font-weight:700; border-color:#f59e0b;">&#129668; Print Setup Wizard &rarr;</a>
        <a href="va_site_config.aspx" title="Site Configuration">&#9881; Site Config</a>
        <a href="index.aspx">&#8962; Hub</a>
        <a href="va_print_mapping.aspx">&#9881; Template Mapping</a>
        <a href="va_printer_routing.aspx">&#128424; Hardware Printers</a>
        <a href="documentation/va_print_admin.html">&#128196; Docs</a>
    </div>
</div>

<div class="tab-bar">
    <button type="button" class="tab-btn active" onclick="switchTab('overview')">&#127760; Site Overview</button>
    <button type="button" class="tab-btn" onclick="switchTab('templates')">&#128196; Templates</button>
    <button type="button" class="tab-btn" onclick="switchTab('printers')">&#128424; Print Clients</button>
    <button type="button" class="tab-btn" onclick="switchTab('status')">&#9889; Status &amp; Logs</button>
    <button type="button" class="tab-btn" onclick="switchTab('wizard')">&#128640; Setup Wizard</button>
</div>

<div id="tab-overview" class="tab-panel active">
    <div class="panel">
        <div class="panel-title">&#127760; Site Print Readiness</div>
        <div class="muted" style="margin-bottom:14px;">Shows each site's printing configuration. Sites missing setup can be configured with one click.</div>
        <div id="overviewGrid" class="gridWrap"><div class="muted" style="padding:20px;">Loading...</div></div>
    </div>

    <!-- Config Files Status Panel -->
    <div class="panel" id="configStatusPanel">
        <div class="panel-title" style="justify-content:space-between;">
            <span>&#128295; Config Files &amp; Credential Sync</span>
            <button type="button" class="btn btn-sm" onclick="loadConfigStatus()" style="font-size:12px;">&#8635; Refresh</button>
        </div>
        <div class="muted" style="margin-bottom:14px;">
            Printing requires matching credentials across three locations. Mismatches cause MQTT connection failures.
        </div>

        <div id="configStatusBody" style="padding:10px 0;">
            <div class="muted">Loading config status...</div>
        </div>

        <div id="configIssues" style="display:none;"></div>

        <div id="configFixRow" style="display:none; margin-top:14px; padding-top:14px; border-top:1px solid var(--line);">
            <button type="button" class="btn btn-fill" onclick="fixConfig()" style="background:var(--accent-2);border-color:var(--accent-2);">
                &#128295; Auto-Fix Config Issues
            </button>
            <span class="muted" style="margin-left:10px;font-size:12px;">Syncs credentials from DB &rarr; appsettings.json files. Fixes UseForPrinting. Removes mqttclient conflicts.</span>
        </div>
        <div id="fixResultBox" style="display:none; margin-top:14px;"></div>
    </div>
</div>


<!-- ======= TAB 2: TEMPLATES ======= -->
<div id="tab-templates" class="tab-panel">
    <div class="panel">
        <div class="panel-title" style="justify-content:space-between;">
            <span>&#128196; Print Templates</span>
            <button type="button" class="btn btn-fill btn-sm" onclick="openTemplateModal()">+ Add Template</button>
        </div>
        <div class="muted" style="margin-bottom:14px;">Each template maps a BarTender <code>.btw</code> file to a site and printer. One template per site is typical.</div>
        <div id="templateGrid" class="gridWrap"><div class="muted" style="padding:20px;">Loading...</div></div>
    </div>
</div>

<!-- ======= TAB 3: PRINT CLIENTS ======= -->
<div id="tab-printers" class="tab-panel">
    <div class="panel">
        <div class="panel-title" style="justify-content:space-between;">
            <span>&#128424; Print Clients (Printers)</span>
            <button type="button" class="btn btn-fill btn-sm" onclick="openPrinterModal()">+ Add Print Client</button>
        </div>
        <div class="muted" style="margin-bottom:14px;">Print clients are MQTT-connected services that receive print commands. Each has credentials and site assignments.</div>
        <div id="printerGrid" class="gridWrap"><div class="muted" style="padding:20px;">Loading...</div></div>
    </div>
</div>

<!-- ======= TAB 4: STATUS & LOGS ======= -->
<div id="tab-status" class="tab-panel">
    <div id="statusCards" class="status-grid"></div>
    <div class="panel">
        <div class="panel-title" style="justify-content:space-between;">
            <span>&#128203; Recent Print Jobs</span>
            <span style="display:flex; gap:8px;">
                <button type="button" class="btn btn-sm" onclick="clearJobs('completed')" style="font-size:11px; color:var(--warn);">Clear Completed</button>
                <button type="button" class="btn btn-sm" onclick="clearJobs('all')" style="font-size:11px; color:var(--danger,#ef4444);">Clear All</button>
                <button type="button" class="btn btn-sm" onclick="loadRecentJobs()">&#8635; Refresh</button>
            </span>
        </div>
        <div id="recentJobsGrid" class="gridWrap"><div class="muted" style="padding:20px;">Loading...</div></div>
    </div>
    <div class="panel">
        <div class="panel-title">&#128209; Print Server Log</div>
        <div id="logBox" class="log-box">Loading...</div>
    </div>
</div>
<!-- ======= TAB 5: SETUP WIZARD ======= -->
<div id="tab-wizard" class="tab-panel">
    <!-- Phase 1: Configuration Form -->
    <div id="wizPhase1">
        <div class="panel">
            <div style="margin-bottom:14px;">
                <div class="panel-title">&#128640; Print Setup Wizard</div>
                <div class="muted" style="font-size:13px;">Configure MQTT credentials, config files, database records, and site templates &mdash; all in one step. Fields are auto-detected from your current configuration.</div>
            </div>

            <div style="display:grid; grid-template-columns:46% 1fr; gap:28px;">
                <!-- Left column: MQTT + Credentials -->
                <div style="min-width:0;">
                    <div style="font-size:12px; font-weight:700; text-transform:uppercase; color:var(--muted); letter-spacing:.05em; margin-bottom:10px; display:flex; align-items:center; gap:6px;">&#128225; MQTT Settings</div>
                    <div class="form-row">
                        <div class="form-group" style="flex:1;">
                            <label>MQTT Server</label>
                            <input type="text" id="wizMqttServer" value="localhost" />
                        </div>
                        <div class="form-group" style="width:60px; flex:none;">
                            <label>Port</label>
                            <input type="number" id="wizMqttPort" value="8883" style="width:60px; padding:6px 4px;" />
                        </div>
                    </div>
                    <div class="form-group">
                        <label>PFX Certificate Path</label>
                        <input type="text" id="wizPfxPath" readonly style="opacity:0.7;" />
                    </div>

                    <div style="font-size:12px; font-weight:700; text-transform:uppercase; color:var(--muted); letter-spacing:.05em; margin:18px 0 10px; display:flex; align-items:center; gap:6px;">&#128274; Print Client Credentials</div>
                    <div class="form-group">
                        <label>Display Name</label>
                        <input type="text" id="wizClientName" value="Master Print Server" />
                    </div>
                    <div class="form-row">
                        <div class="form-group" style="flex:1;">
                            <label>MQTT Username</label>
                            <input type="text" id="wizUsername" value="MasterPrint" />
                        </div>
                        <div class="form-group" style="flex:1;">
                            <label>MQTT Password</label>
                            <input type="text" id="wizPassword" value="" />
                        </div>
                    </div>

                    <div style="font-size:12px; font-weight:700; text-transform:uppercase; color:var(--muted); letter-spacing:.05em; margin:18px 0 10px; display:flex; align-items:center; gap:6px;">&#128196; Default Template</div>
                    <div class="form-group">
                        <label>BarTender File Path (.btw)</label>
                        <input type="text" id="wizBtwPath" value="c:\assetworx_prints\AW_Std_Small.btw" />
                    </div>
                </div>

                <!-- Right column: Sites + Config status -->
                <div>
                    <div style="font-size:12px; font-weight:700; text-transform:uppercase; color:var(--muted); letter-spacing:.05em; margin-bottom:10px; display:flex; align-items:center; gap:6px;">&#127760; Sites to Configure</div>
                    <div id="wizSiteList" style="max-height:220px; overflow-y:auto; border:1px solid var(--line); border-radius:8px; padding:10px;">
                        <div class="muted">Loading sites...</div>
                    </div>

                    <div style="font-size:12px; font-weight:700; text-transform:uppercase; color:var(--muted); letter-spacing:.05em; margin:18px 0 10px; display:flex; align-items:center; gap:6px;">&#128196; Config Files Detected</div>
                    <div id="wizConfigStatus" style="font-size:12px; line-height:2;">
                        <div class="muted">Checking...</div>
                    </div>

                    <div style="margin-top:20px; padding:14px; border-radius:10px; background:color-mix(in srgb, #f59e0b 8%, transparent); border:1px solid color-mix(in srgb, #f59e0b 30%, transparent);">
                        <div style="font-weight:700; color:#f59e0b; font-size:13px; margin-bottom:6px;">&#9888;&#65039; What This Wizard Does</div>
                        <div style="font-size:11px; color:var(--text); line-height:1.6;">
                            1. Sets <code>UseForPrinting = true</code> in WebClient config<br>
                            2. Syncs MQTT credentials to <strong>both</strong> appsettings.json files<br>
                            3. Creates/updates the print client record in the database<br>
                            4. Removes mqttclient table conflicts<br>
                            5. Creates print templates for selected sites<br>
                            6. Creates API client app keys for selected sites<br>
                            <strong>7. Requires IIS restart after completion</strong>
                        </div>
                    </div>
                </div>
            </div>

            <div style="margin-top:20px; text-align:center; border-top:1px solid var(--line); padding-top:16px;">
                <button type="button" class="btn btn-fill" onclick="runWizard()" id="wizRunBtn" style="padding:8px 28px; font-size:13px;">&#9654; Run Setup</button>
            </div>
        </div>
    </div>

    <!-- Phase 2: Execution Log -->
    <div id="wizPhase2" style="display:none;">
        <div class="panel">
            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
                <div style="font-size:18px; font-weight:800;">&#9881;&#65039; Running Setup...</div>
                <div id="wizStepCounter" class="muted" style="font-size:13px;">Step 0 of 8</div>
            </div>
            <div style="background:var(--line); border-radius:6px; height:6px; margin-bottom:20px;">
                <div id="wizProgressBar" style="height:6px; border-radius:6px; background:linear-gradient(90deg,#3b82f6,#8b5cf6); width:0%; transition:width 0.5s ease;"></div>
            </div>
            <div id="wizStepLog"></div>
        </div>
    </div>

    <!-- Phase 3: Summary -->
    <div id="wizPhase3" style="display:none;">
        <div id="wizSummaryContent"></div>
    </div>
</div>

<!-- ======= TEMPLATE MODAL ======= -->
<div class="modal-overlay" id="templateModal" onclick="if(event.target===this) closeModal('templateModal')">
    <div class="modal">
        <h3 id="tplModalTitle">Add Template</h3>
        <input type="hidden" id="tplId" value="0" />
        <div style="margin-bottom:12px; display:flex; gap:6px; align-items:center; flex-wrap:wrap; background:var(--chip,#1e293b); padding:8px 10px; border-radius:8px; border:1px solid var(--line,#334155);">
            <span class="muted" style="font-size:11px; font-weight:700; color:var(--accent,#38bdf8);">&#127991;&#65039; Tag Team Presets:</span>
            <button type="button" class="btn btn-sm" onclick="setTplPreset('AW_Std_Small', 'c:\\assetworx_prints\\AW_Std_Small.btw')">Small Metal (AW_Std_Small)</button>
            <button type="button" class="btn btn-sm" onclick="setTplPreset('AW_Large_Metal', 'c:\\assetworx_prints\\AW_Large_Metal.btw')">Large Metal (AW_Large_Metal)</button>
            <button type="button" class="btn btn-sm" onclick="setTplPreset('AW_Metal_IQ350', 'c:\\assetworx_prints\\AW_Metal_IQ350.btw')">IQ350 (AW_Metal_IQ350)</button>
        </div>
        <div class="form-row">
            <div class="form-group" style="flex:1;">
                <label>Template Name</label>
                <input type="text" id="tplName" value="AW_Std_Small" />
            </div>
            <div class="form-group">
                <label>Type</label>
                <select id="tplType"><option value="Asset">Asset</option><option value="Location">Location</option><option value="Employee">Employee</option></select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group" style="flex:1;">
                <label>BarTender File (.btw)</label>
                <input type="text" id="tplFile" value="c:\assetworx_prints\AW_Std_Small.btw" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-group" style="flex:1;">
                <label>Site</label>
                <select id="tplCompany"></select>
            </div>
            <div class="form-group" style="flex:1;">
                <label>Print Client</label>
                <select id="tplPrinter"></select>
            </div>
        </div>
        <div style="display:flex; gap:10px; margin-top:16px; justify-content:flex-end;">
            <button type="button" class="btn" onclick="closeModal('templateModal')">Cancel</button>
            <button type="button" class="btn btn-fill" onclick="saveTemplate()">Save</button>
        </div>
    </div>
</div>

<!-- ======= BARTENDER PREVIEW MODAL ======= -->
<div class="modal-overlay" id="previewModal" onclick="if(event.target===this) closeModal('previewModal')">
    <div class="modal" style="max-width:640px;">
        <h3 id="pvModalTitle">&#128065; BarTender Label Preview</h3>
        <div id="pvLoading" style="display:none; padding:30px; text-align:center; color:var(--muted);">
            <div style="font-size:14px; font-weight:600;">Generating live preview from BarTender Print Engine...</div>
        </div>
        <div id="pvBody" style="text-align:center;">
            <img id="pvImage" src="" alt="Label Preview" style="max-width:100%; max-height:340px; border-radius:8px; border:1px solid var(--line); background:#fff; margin-bottom:12px;" />
            <div id="pvMeta" style="font-size:12px; text-align:left; background:var(--chip); padding:10px 14px; border-radius:8px; border:1px solid var(--line); line-height:1.6;"></div>
        </div>
        <div style="display:flex; gap:10px; margin-top:16px; justify-content:flex-end;">
            <button type="button" class="btn" onclick="closeModal('previewModal')">Close</button>
        </div>
    </div>
</div>

<!-- ======= PRINTER MODAL ======= -->
<div class="modal-overlay" id="printerModal" onclick="if(event.target===this) closeModal('printerModal')">
    <div class="modal">
        <h3 id="prtModalTitle">Add Print Client</h3>
        <input type="hidden" id="prtId" value="0" />
        <div class="form-row">
            <div class="form-group" style="flex:1;">
                <label>Friendly Name</label>
                <input type="text" id="prtName" placeholder="e.g. Master Print Server" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-group" style="flex:1;">
                <label>MQTT Username</label>
                <input type="text" id="prtUsername" placeholder="e.g. MasterPrint" />
            </div>
            <div class="form-group" style="flex:1;">
                <label>MQTT Password</label>
                <input type="text" id="prtPassword" placeholder="MQTT password" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-group" style="flex:1;">
                <label>Machine Name</label>
                <input type="text" id="prtMachine" placeholder="e.g. LINGCOD" />
            </div>
        </div>
        <div class="form-group" style="margin-top:8px;">
            <label>Assigned Sites</label>
            <div id="prtSites" style="display:flex; flex-wrap:wrap; gap:8px; margin-top:4px;"></div>
        </div>
        <div style="display:flex; gap:10px; margin-top:16px; justify-content:flex-end;">
            <button type="button" class="btn" onclick="closeModal('printerModal')">Cancel</button>
            <button type="button" class="btn btn-fill" onclick="savePrinter()">Save</button>
        </div>
    </div>
</div>

</form>

<script>
// ======= TAB SWITCHING =======
function switchTab(name) {
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    event.target.classList.add('active');
    if (name === 'overview') loadOverview();
    if (name === 'templates') loadTemplates();
    if (name === 'printers') loadPrinters();
    if (name === 'status') { loadStatus(); loadRecentJobs(); }
}

// ======= MODALS =======
function closeModal(id) { document.getElementById(id).classList.remove('show'); }

// ======= API HELPER =======
async function api(cmd, opts) {
    var url = 'va_print_admin.aspx?action=api&cmd=' + cmd;
    if (opts && opts.params) {
        for (var k in opts.params) url += '&' + k + '=' + encodeURIComponent(opts.params[k]);
    }
    var fetchOpts = { method: opts && opts.body ? 'POST' : 'GET' };
    if (opts && opts.body) {
        fetchOpts.headers = { 'Content-Type': 'application/json' };
        fetchOpts.body = JSON.stringify(opts.body);
    }
    var resp = await fetch(url, fetchOpts);
    return resp.json();
}

// ======= TAB 1: OVERVIEW =======
var overviewCompanies = [];
async function loadOverview() {
    var data = await api('getOverview');
    overviewCompanies = data.sites || [];
    var html = '<table class="grid"><thead><tr>' +
        '<th>Site</th><th>Template</th><th>BarTender File</th><th>File?</th><th>Printer</th><th>API Client</th><th>Status</th><th></th>' +
        '</tr></thead><tbody>';
    (data.sites || []).forEach(function(s) {
        var ready = s.templateId && s.btwFileExists && s.printerUsername && s.apiClientId;
        var status = ready ? '<span class="badge badge-ok">&#10003; Ready</span>' :
            '<span class="badge badge-err">&#10007; Incomplete</span>';
        var actions = '';
        if (!ready) actions = '<button type="button" class="btn btn-success btn-sm" onclick="quickSetup(' + s.companyId + ')">Quick Setup</button>';
        else actions = '<button type="button" class="btn btn-sm" onclick="testPrintSite(' + s.companyId + ',' + (s.templateId||0) + ')">Test Print</button>';
        html += '<tr>' +
            '<td><strong>' + s.siteName + '</strong></td>' +
            '<td>' + (s.templateName ? s.templateName + ' (' + s.templateId + ')' : '<span class="muted">&mdash;</span>') + '</td>' +
            '<td style="font-size:11px;max-width:200px;overflow:hidden;text-overflow:ellipsis;">' + (s.btwFile || '<span class="muted">&mdash;</span>') + '</td>' +
            '<td>' + (s.btwFile ? (s.btwFileExists ? '<span class="badge badge-ok">&#10003;</span>' : '<span class="badge badge-err">&#10007;</span>') : '') + '</td>' +
            '<td>' + (s.printerUsername || '<span class="muted">&mdash;</span>') + '</td>' +
            '<td>' + (s.apiClientId ? '<code style="font-size:11px;">' + s.apiClientId + '</code>' : '<span class="muted">&mdash;</span>') + '</td>' +
            '<td>' + status + '</td>' +
            '<td>' + actions + '</td>' +
            '</tr>';
    });
    html += '</tbody></table>';
    document.getElementById('overviewGrid').innerHTML = html;
}

async function quickSetup(companyId) {
    if (!confirm('Auto-configure printing for this site?\n\nThis will create:\n&bull; A template pointing to AW_Std_Small.btw\n&bull; MasterPrint site assignment\n&bull; API client credentials')) return;
    var data = await api('quickSetup', { body: { companyId: companyId } });
    if (data.error) alert('Error: ' + data.error);
    else alert(data.message);
    loadOverview();
}

async function testPrintSite(companyId, templateId) {
    // Show the asset search modal
    var modal = document.getElementById('testPrintModal');
    if (!modal) {
        // Create modal on first use
        var d = document.createElement('div');
        d.id = 'testPrintModal';
        d.style.cssText = 'display:none;position:fixed;inset:0;z-index:9999;background:rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;';
        d.innerHTML = '<div style="background:var(--card,#fff);border:1px solid var(--line,#ddd);border-radius:12px;padding:24px;width:500px;max-height:80vh;display:flex;flex-direction:column;box-shadow:0 20px 50px rgba(0,0,0,.3);">' +
            '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">' +
            '<h3 style="margin:0;font-size:16px;">&#128424; Test Print &mdash; Search Asset</h3>' +
            '<button type="button" onclick="closeTestPrintModal()" style="background:none;border:none;font-size:20px;cursor:pointer;color:var(--muted,#999);">&#10005;</button></div>' +
            '<input id="tpSearch" type="text" placeholder="Type asset name (e.g. 613 EE12889)..." ' +
            'style="width:100%;padding:10px 14px;border:1px solid var(--line,#ddd);border-radius:8px;font-size:14px;background:var(--bg,#f9f9f9);color:var(--text,#333);outline:none;box-sizing:border-box;" />' +
            '<div id="tpResults" style="margin-top:12px;max-height:350px;overflow-y:auto;"></div>' +
            '<div id="tpStatus" style="margin-top:8px;font-size:12px;color:var(--muted,#999);"></div>' +
            '</div>';
        document.body.appendChild(d);
        modal = d;
        // Debounced search
        var timer = null;
        document.getElementById('tpSearch').addEventListener('input', function() {
            clearTimeout(timer);
            timer = setTimeout(function() { searchAssets(); }, 300);
        });
    }
    modal.dataset.companyId = companyId;
    modal.dataset.templateId = templateId;
    modal.style.display = 'flex';
    var inp = document.getElementById('tpSearch');
    inp.value = '';
    document.getElementById('tpResults').innerHTML = '<div style="text-align:center;padding:30px;color:var(--muted,#999);font-size:13px;">Type at least 2 characters to search</div>';
    document.getElementById('tpStatus').textContent = '';
    setTimeout(function() { inp.focus(); }, 100);
}

function closeTestPrintModal() {
    var modal = document.getElementById('testPrintModal');
    if (modal) modal.style.display = 'none';
}

async function searchAssets() {
    var q = document.getElementById('tpSearch').value.trim();
    var container = document.getElementById('tpResults');
    var modal = document.getElementById('testPrintModal');
    if (q.length < 2) {
        container.innerHTML = '<div style="text-align:center;padding:30px;color:var(--muted,#999);font-size:13px;">Type at least 2 characters to search</div>';
        return;
    }
    container.innerHTML = '<div style="text-align:center;padding:20px;color:var(--muted,#999);">Searching...</div>';
    var data = await api('searchAssets', { qs: '&q=' + encodeURIComponent(q) + '&companyId=' + (modal.dataset.companyId||0) });
    var assets = data.assets || [];
    if (assets.length === 0) {
        container.innerHTML = '<div style="text-align:center;padding:20px;color:var(--muted,#999);">No assets found matching "' + q + '"</div>';
        return;
    }
    var html = '<table style="width:100%;border-collapse:collapse;font-size:13px;">' +
        '<tr style="border-bottom:2px solid var(--line,#ddd);"><th style="text-align:left;padding:6px 8px;color:var(--muted,#999);font-size:11px;">ID</th><th style="text-align:left;padding:6px 8px;color:var(--muted,#999);font-size:11px;">Asset Name</th><th style="text-align:left;padding:6px 8px;color:var(--muted,#999);font-size:11px;">Location</th><th style="padding:6px 8px;"></th></tr>';
    assets.forEach(function(a) {
        html += '<tr style="border-bottom:1px solid var(--line,#eee);cursor:pointer;" onmouseover="this.style.background=\'rgba(59,130,246,.08)\'" onmouseout="this.style.background=\'\'">' +
            '<td style="padding:8px;font-family:monospace;font-size:11px;color:var(--muted,#999);">' + a.id + '</td>' +
            '<td style="padding:8px;font-weight:600;">' + a.name + '</td>' +
            '<td style="padding:8px;font-size:12px;color:var(--muted,#666);">' + (a.location || '&mdash;') + '</td>' +
            '<td style="padding:8px;text-align:right;"><button type="button" class="btn btn-sm btn-success" onclick="submitTestPrint(' + a.id + ',\'' + a.name.replace(/'/g, "\\'") + '\')">Print</button></td>' +
            '</tr>';
    });
    html += '</table>';
    container.innerHTML = html;
}

async function submitTestPrint(recordId, assetName) {
    var modal = document.getElementById('testPrintModal');
    var templateId = parseInt(modal.dataset.templateId);
    document.getElementById('tpStatus').textContent = 'Sending print job for ' + assetName + '...';
    var data = await api('testPrint', { body: { templateId: templateId, recordId: recordId } });
    if (data.error) {
        document.getElementById('tpStatus').innerHTML = '<span style="color:#ef4444;">&#10060; ' + data.error + '</span>';
    } else {
        document.getElementById('tpStatus').innerHTML = '<span style="color:#10b981;">&#9989; Print sent! Job ID: ' + data.jobId + ' &mdash; Asset: ' + assetName + '</span>';
    }
}

// ======= TAB 2: TEMPLATES =======
var tplData = {};
async function loadTemplates() {
    tplData = await api('getTemplates');
    var html = '<table class="grid"><thead><tr>' +
        '<th>ID</th><th>Name</th><th>Site</th><th>Type</th><th>BarTender File</th><th>File?</th><th>Printer</th><th></th>' +
        '</tr></thead><tbody>';
    (tplData.templates || []).forEach(function(t) {
        var tagTeamBadge = '';
        var tNorm = (t.name || '').toLowerCase().replace(/[\s\-_]+/g, '');
        if (tNorm.includes('iq350')) {
            tagTeamBadge = ' <span class="badge" style="background:rgba(59,130,246,.15); color:#60a5fa; font-size:10px; margin-left:4px; padding:2px 6px; border-radius:4px;" title="Used on Tag Team Scan for IQ350">&#127991;&#65039; Tag: IQ350</span>';
        } else if (tNorm.includes('large')) {
            tagTeamBadge = ' <span class="badge" style="background:rgba(168,85,247,.15); color:#c084fc; font-size:10px; margin-left:4px; padding:2px 6px; border-radius:4px;" title="Used on Tag Team Scan for Large Metal">&#127991;&#65039; Tag: Large_Metal</span>';
        } else if (tNorm.includes('small') || tNorm.includes('std')) {
            tagTeamBadge = ' <span class="badge" style="background:rgba(16,185,129,.15); color:#34d399; font-size:10px; margin-left:4px; padding:2px 6px; border-radius:4px;" title="Used on Tag Team Scan for Small Metal & Small Standard">&#127991;&#65039; Tag: Small_Metal</span>';
        }

        html += '<tr>' +
            '<td>' + t.id + '</td>' +
            '<td><strong>' + t.name + '</strong>' + tagTeamBadge + '</td>' +
            '<td>' + (t.siteName || '&mdash;') + '</td>' +
            '<td>' + t.templateType + '</td>' +
            '<td style="font-size:11px;max-width:220px;overflow:hidden;text-overflow:ellipsis;">' + t.filename + '</td>' +
            '<td>' + (t.fileExists ? '<span class="badge badge-ok">&#10003;</span>' : '<span class="badge badge-err">&#10007;</span>') + '</td>' +
            '<td>' + (t.printerUsername || '&mdash;') + '</td>' +
            '<td style="display:flex;gap:4px;">' +
                '<button type="button" class="btn btn-sm btn-blue" onclick="testPreviewTemplate(\'' + encodeURIComponent(t.filename || '') + '\',\'' + encodeURIComponent(t.name || '') + '\')">&#128065; Preview</button>' +
                '<button type="button" class="btn btn-sm" onclick="editTemplate(' + t.id + ')">Edit</button>' +
                '<button type="button" class="btn btn-sm btn-danger" onclick="deleteTemplate(' + t.id + ')">Del</button>' +
            '</td></tr>';
    });
    html += '</tbody></table>';
    document.getElementById('templateGrid').innerHTML = html;
}

function setTplPreset(name, fn) {
    document.getElementById('tplName').value = name;
    document.getElementById('tplFile').value = fn;
}

async function testPreviewTemplate(encodedPath, encodedName) {
    var path = decodeURIComponent(encodedPath);
    var name = decodeURIComponent(encodedName);
    document.getElementById('pvModalTitle').textContent = '👁 BarTender Preview: ' + (name || path);
    document.getElementById('pvLoading').style.display = 'block';
    document.getElementById('pvBody').style.display = 'none';
    document.getElementById('previewModal').classList.add('show');

    try {
        var fields = {
            lblname: '517 EE99999',
            lbldescription: 'SAMPLE ASSET FOR PREVIEW',
            lblsn: 'SN-12345678',
            lbleil: '138',
            lblrfidtag: 'E28011902000216503837493'
        };
        var resp = await fetch('api/BarTenderHandler.ashx?action=preview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: JSON.stringify({ template: path, fields: fields })
        });
        var data = await resp.json();
        document.getElementById('pvLoading').style.display = 'none';
        document.getElementById('pvBody').style.display = 'block';

        if (data.Success && data.ImageBase64) {
            document.getElementById('pvImage').src = 'data:image/png;base64,' + data.ImageBase64;
            document.getElementById('pvMeta').innerHTML = 
                '<div><strong>Template Path:</strong> <code>' + path + '</code></div>' +
                '<div><strong>Discovered Named Fields (' + (data.DiscoveredFields ? data.DiscoveredFields.length : 0) + '):</strong> ' + 
                (data.DiscoveredFields && data.DiscoveredFields.length > 0 ? ('<code>' + data.DiscoveredFields.join('</code>, <code>') + '</code>') : '<em>None</em>') + '</div>';
        } else {
            document.getElementById('pvImage').src = '';
            document.getElementById('pvMeta').innerHTML = '<span style="color:#ef4444;font-weight:600;">&#9888; BarTender Engine Error: ' + (data.ErrorMessage || 'Could not render template') + '</span>';
        }
    } catch (e) {
        document.getElementById('pvLoading').style.display = 'none';
        document.getElementById('pvBody').style.display = 'block';
        document.getElementById('pvImage').src = '';
        document.getElementById('pvMeta').innerHTML = '<span style="color:#ef4444;font-weight:600;">&#9888; API Error: ' + e.message + '</span>';
    }
}

function openTemplateModal(t) {
    document.getElementById('tplModalTitle').textContent = t ? 'Edit Template' : 'Add Template';
    document.getElementById('tplId').value = t ? t.id : 0;
    document.getElementById('tplName').value = t ? t.name : 'AW_Std_Small';
    document.getElementById('tplType').value = t ? t.templateType : 'Asset';
    document.getElementById('tplFile').value = t ? t.filename : 'c:\\assetworx_prints\\AW_Std_Small.btw';

    // Populate company dropdown
    var ddlC = document.getElementById('tplCompany'); ddlC.innerHTML = '';
    (tplData.companies || []).forEach(function(c) {
        ddlC.innerHTML += '<option value="' + c.id + '"' + (t && t.companyId == c.id ? ' selected' : '') + '>' + c.name + '</option>';
    });
    // Populate printer dropdown
    var ddlP = document.getElementById('tplPrinter'); ddlP.innerHTML = '';
    (tplData.printers || []).forEach(function(p) {
        ddlP.innerHTML += '<option value="' + p.id + '"' + (t && t.printClientId == p.id ? ' selected' : '') + '>' + p.name + ' (' + p.username + ')</option>';
    });
    document.getElementById('templateModal').classList.add('show');
}

function editTemplate(id) {
    var t = (tplData.templates || []).find(function(x) { return x.id === id; });
    if (t) openTemplateModal(t);
}

async function saveTemplate() {
    var data = {
        id: parseInt(document.getElementById('tplId').value),
        name: document.getElementById('tplName').value,
        templateType: document.getElementById('tplType').value,
        filename: document.getElementById('tplFile').value,
        companyId: parseInt(document.getElementById('tplCompany').value),
        printClientId: parseInt(document.getElementById('tplPrinter').value)
    };
    var resp = await api('saveTemplate', { body: data });
    if (resp.error) alert('Error: ' + resp.error);
    else { closeModal('templateModal'); loadTemplates(); }
}

async function deleteTemplate(id) {
    if (!confirm('Delete this template?')) return;
    await api('deleteTemplate', { params: { id: id } });
    loadTemplates();
}

// ======= TAB 3: PRINT CLIENTS =======
var prtData = {};
async function loadPrinters() {
    prtData = await api('getPrintClients');
    var localMach = prtData.localMachineName || '';
    var html = '<table class="grid"><thead><tr>' +
        '<th>ID</th><th>Name</th><th>MQTT User</th><th>MQTT Pass</th><th>Station Machine Name</th><th>Last Seen</th><th>Sites</th><th></th>' +
        '</tr></thead><tbody>';
    (prtData.clients || []).forEach(function(c) {
        var machName = c.machineName || '';
        var isAntenna = machName.toLowerCase().indexOf('idashantenna') >= 0;
        var isMatch = localMach && machName.toLowerCase() === localMach.toLowerCase();
        var machHtml = '';

        if (!machName) {
            machHtml = '<span class="muted">(None)</span> ' + (localMach ? '<button type="button" class="btn btn-sm btn-success" style="font-size:10px;padding:2px 6px;margin-left:4px;" onclick="fixAdminMachineName(' + c.id + ')">Set to ' + localMach + '</button>' : '');
        } else if (isAntenna) {
            machHtml = '<span style="color:#ef4444;font-weight:700;">' + machName + '</span> <span class="badge badge-err" style="font-size:10px;padding:1px 6px;">⚠️ Antenna ID (Corrupted)</span> ' + (localMach ? '<button type="button" class="btn btn-sm btn-success" style="font-size:10px;padding:2px 6px;margin-left:4px;" onclick="fixAdminMachineName(' + c.id + ')">Set to ' + localMach + '</button>' : '');
        } else if (isMatch) {
            machHtml = '<strong>' + machName + '</strong> <span class="badge badge-ok" style="font-size:10px;padding:1px 6px;">✅ Matches this PC</span>';
        } else {
            machHtml = '<span>' + machName + '</span> <span class="badge badge-warn" style="font-size:10px;padding:1px 6px;">Different PC</span> ' + (localMach ? '<button type="button" class="btn btn-sm" style="font-size:10px;padding:2px 6px;margin-left:4px;" onclick="fixAdminMachineName(' + c.id + ')">Set to ' + localMach + '</button>' : '');
        }

        html += '<tr>' +
            '<td>' + c.id + '</td>' +
            '<td><strong>' + c.name + '</strong></td>' +
            '<td><code>' + c.username + '</code></td>' +
            '<td><code style="font-size:11px;">' + c.password + '</code></td>' +
            '<td>' + machHtml + '</td>' +
            '<td>' + (c.lastSeen || '<span class="muted">Never</span>') + '</td>' +
            '<td style="font-size:11px;">' + (c.assignedSites || '<span class="muted">None</span>') + '</td>' +
            '<td style="display:flex;gap:4px;">' +
                '<button type="button" class="btn btn-sm" onclick="editPrinter(' + c.id + ')">Edit</button>' +
                '<button type="button" class="btn btn-sm btn-danger" onclick="deletePrinter(' + c.id + ')">Del</button>' +
            '</td></tr>';
    });
    html += '</tbody></table>';
    document.getElementById('printerGrid').innerHTML = html;
}

async function fixAdminMachineName(id) {
    var targetMach = prtData.localMachineName || 'this PC';
    if (!confirm('Update this print client\'s machine name to "' + targetMach + '"?')) return;
    var resp = await api('fixMachineName', { qs: '&id=' + id });
    if (resp.error) alert('Error: ' + resp.error);
    else {
        alert('Machine name updated to ' + resp.machineName);
        loadPrinters();
    }
}

function openPrinterModal(c) {
    document.getElementById('prtModalTitle').textContent = c ? 'Edit Print Client' : 'Add Print Client';
    document.getElementById('prtId').value = c ? c.id : 0;
    document.getElementById('prtName').value = c ? c.name : '';
    document.getElementById('prtUsername').value = c ? c.username : '';
    document.getElementById('prtPassword').value = c ? c.password : '';
    document.getElementById('prtMachine').value = c ? c.machineName : '';

    // Site checkboxes
    var sitesDiv = document.getElementById('prtSites'); sitesDiv.innerHTML = '';
    var assigned = c ? (c.assignedSites || '').split(', ') : [];
    (prtData.companies || []).forEach(function(co) {
        var checked = assigned.indexOf(co.name) >= 0 ? 'checked' : '';
        sitesDiv.innerHTML += '<label style="display:flex;align-items:center;gap:4px;font-size:13px;cursor:pointer;">' +
            '<input type="checkbox" class="prt-site-chk" value="' + co.id + '" ' + checked + ' /> ' + co.name + '</label>';
    });
    document.getElementById('printerModal').classList.add('show');
}

function editPrinter(id) {
    var c = (prtData.clients || []).find(function(x) { return x.id === id; });
    if (c) openPrinterModal(c);
}

async function savePrinter() {
    var siteIds = [];
    document.querySelectorAll('.prt-site-chk:checked').forEach(function(cb) { siteIds.push(parseInt(cb.value)); });
    var data = {
        id: parseInt(document.getElementById('prtId').value),
        name: document.getElementById('prtName').value,
        username: document.getElementById('prtUsername').value,
        password: document.getElementById('prtPassword').value,
        machineName: document.getElementById('prtMachine').value,
        siteIds: siteIds
    };
    var resp = await api('savePrintClient', { body: data });
    if (resp.error) alert('Error: ' + resp.error);
    else { closeModal('printerModal'); loadPrinters(); }
}

async function deletePrinter(id) {
    if (!confirm('Delete this print client and all its site assignments?')) return;
    await api('deletePrintClient', { params: { id: id } });
    loadPrinters();
}

// ======= TAB 4: STATUS =======
async function loadStatus() {
    var data = await api('getStatus');
    var html = '';
    html += '<div class="status-card"><div class="sc-label">Print Server</div><div class="sc-value">' +
        (data.processRunning ? '<span style="color:#10b981;">&#9679; Running</span>' : '<span style="color:#ef4444;">&#9679; Stopped</span>') +
        '</div><div class="muted">PID: ' + (data.pid || '&mdash;') + ' &middot; ' + (data.memory || '') + '</div></div>';
    html += '<div class="status-card"><div class="sc-label">MQTT Broker</div><div class="sc-value">' +
        (data.mqttConnected ? '<span style="color:#10b981;">&#9679; Connected</span>' : '<span style="color:#f59e0b;">&#9679; No Connection</span>') +
        '</div><div class="muted">' + (data.mqttServer || 'localhost') + ':' + (data.mqttPort || 8883) + ' &middot; ' + (data.mqttConnections || 0) + ' active</div></div>';
    html += '<div class="status-card"><div class="sc-label">MQTT Credentials</div><div class="sc-value" style="font-size:14px;">' +
        '<code>' + (data.printClientUsername || '&mdash;') + '</code></div><div class="muted">From appsettings.json</div></div>';
    html += '<div class="status-card"><div class="sc-label">Log Updated</div><div class="sc-value" style="font-size:16px;">' +
        (data.logUpdated || '&mdash;') + '</div><div class="muted">' + (data.logFile || '') + '</div></div>';
    document.getElementById('statusCards').innerHTML = html;

    if (data.logTail) {
        document.getElementById('logBox').textContent = data.logTail;
    } else {
        document.getElementById('logBox').textContent = 'No log data available. Print Server may not be writing logs.';
    }
}

async function loadRecentJobs() {
    var data = await api('getRecentJobs');
    var html = '<table class="grid"><thead><tr>' +
        '<th>ID</th><th>Record</th><th>Template</th><th>Site</th><th>Created</th><th>Status</th><th>Message</th>' +
        '</tr></thead><tbody>';
    (data.jobs || []).forEach(function(j) {
        var statusBadge = j.completed ?
            '<span class="badge badge-ok">&#10003; Done</span>' :
            '<span class="badge badge-warn">&#9203; Pending</span>';
        html += '<tr>' +
            '<td>' + j.id + '</td>' +
            '<td>' + j.recordId + '</td>' +
            '<td>' + (j.templateName || j.templateId) + '</td>' +
            '<td>' + (j.siteName || '&mdash;') + '</td>' +
            '<td style="font-size:11px;">' + (j.created || '&mdash;') + '</td>' +
            '<td>' + statusBadge + '</td>' +
            '<td style="font-size:11px;">' + (j.message || '') + '</td>' +
            '</tr>';
    });
    html += '</tbody></table>';
    document.getElementById('recentJobsGrid').innerHTML = html;
}

async function clearJobs(mode) {
    var label = mode === 'all' ? 'ALL print jobs (including pending)' : 'completed print jobs';
    if (!confirm('Clear ' + label + '?\n\nThis permanently deletes job records from the database.')) return;
    var data = await api('clearJobs', { params: { mode: mode } });
    if (data.error) {
        alert('Error: ' + data.error);
    } else {
        alert(data.deleted + ' job(s) cleared.');
        loadRecentJobs();
    }
}

// ======= CONFIG STATUS =======
async function loadConfigStatus() {
    try {
        var data = await api('getConfigStatus');
        var wc = data.webClient || {};
        var ps = data.printServer || {};
        var dbClients = data.dbClients || [];
        var issues = data.issues || [];

        // Build comparison table
        var html = '<table class="grid" style="font-size:12px;">' +
            '<thead><tr>' +
            '<th style="width:160px;">Setting</th>' +
            '<th>WebClient <code style="font-size:10px;">appsettings.json</code></th>' +
            '<th>Print Server <code style="font-size:10px;">appsettings.json</code></th>' +
            '<th>DB <code style="font-size:10px;">printclient</code> table</th>' +
            '<th style="width:80px;">Status</th>' +
            '</tr></thead><tbody>';

        // File paths row
        html += '<tr style="color:var(--muted);font-size:11px;">' +
            '<td><strong>File Path</strong></td>' +
            '<td>' + (wc.path || '&mdash;') + (wc.exists ? '' : ' <span style="color:#ef4444;">(MISSING)</span>') + '</td>' +
            '<td>' + (ps.path || '&mdash;') + (ps.exists ? '' : ' <span style="color:#f59e0b;">(not found)</span>') + '</td>' +
            '<td>SQL table</td>' +
            '<td></td></tr>';

        // Username row
        var dbUser = dbClients.length > 0 ? dbClients[0].username : '&mdash;';
        var userMatch = wc.printClientUsername === dbUser && (!ps.exists || ps.printClientUsername === dbUser);
        html += '<tr><td><strong>MQTT Username</strong></td>' +
            '<td><code>' + (wc.printClientUsername || '&mdash;') + '</code></td>' +
            '<td><code>' + (ps.exists ? (ps.printClientUsername || '&mdash;') : '<span class="muted">N/A</span>') + '</code></td>' +
            '<td><code>' + dbUser + '</code></td>' +
            '<td>' + (userMatch ? '<span class="badge badge-ok">&#10003; Match</span>' : '<span class="badge badge-err">&#10007; Mismatch</span>') + '</td></tr>';

        // Password row
        var dbPass = dbClients.length > 0 ? dbClients[0].passwordMasked : '&mdash;';
        var passMatch = wc.printClientPasswordMasked === dbPass && (!ps.exists || ps.printClientPasswordMasked === dbPass);
        html += '<tr><td><strong>MQTT Password</strong></td>' +
            '<td><code>' + (wc.printClientPasswordMasked || '&mdash;') + '</code></td>' +
            '<td><code>' + (ps.exists ? (ps.printClientPasswordMasked || '&mdash;') : '<span class="muted">N/A</span>') + '</code></td>' +
            '<td><code>' + dbPass + '</code></td>' +
            '<td>' + (passMatch ? '<span class="badge badge-ok">&#10003; Match</span>' : '<span class="badge badge-err">&#10007; Mismatch</span>') + '</td></tr>';

        // UseForPrinting row
        var ufp = wc.useForPrinting;
        html += '<tr><td><strong>UseForPrinting</strong></td>' +
            '<td>' + (ufp ? '<span style="color:#10b981;">&#10003; true</span>' : '<span style="color:#ef4444;font-weight:700;">&#10007; false</span>') + '</td>' +
            '<td colspan="2" class="muted">Required to be <code>true</code> for MQTT broker to start</td>' +
            '<td>' + (ufp ? '<span class="badge badge-ok">&#10003; OK</span>' : '<span class="badge badge-err">&#10007; Off</span>') + '</td></tr>';

        // MQTT Server row
        html += '<tr><td><strong>MQTT Server</strong></td>' +
            '<td><code>' + (wc.mqttServer || '&mdash;') + ':' + (wc.mqttPort || '') + '</code></td>' +
            '<td><code>' + (ps.exists ? (ps.mqttServer || '&mdash;') + ':' + (ps.mqttPort || '') : '<span class="muted">N/A</span>') + '</code></td>' +
            '<td class="muted">&mdash;</td>' +
            '<td></td></tr>';

        html += '</tbody></table>';
        document.getElementById('configStatusBody').innerHTML = html;

        // Issues list
        var issEl = document.getElementById('configIssues');
        if (issues.length > 0) {
            var ih = '<div style="margin-top:12px; padding:12px 16px; border-radius:8px; border:1px solid ' +
                (data.mqttClientConflict ? '#ef4444' : '#f59e0b') + '; background:' +
                (data.mqttClientConflict ? 'color-mix(in srgb, #ef4444, transparent 90%)' : 'color-mix(in srgb, #f59e0b, transparent 90%)') + ';">';
            ih += '<div style="font-weight:700;margin-bottom:6px;color:' + (data.mqttClientConflict ? '#ef4444' : '#f59e0b') + ';">' +
                '&#9888; ' + issues.length + ' issue' + (issues.length > 1 ? 's' : '') + ' detected</div>';
            issues.forEach(function(iss) {
                var isCrit = iss.indexOf('CRITICAL') === 0;
                ih += '<div style="font-size:12px;margin:4px 0;color:' + (isCrit ? '#ef4444' : 'var(--text)') + ';">' +
                    (isCrit ? '&#128308; ' : '&#9888; ') + iss + '</div>';
            });
            ih += '</div>';
            issEl.innerHTML = ih;
            issEl.style.display = 'block';
            document.getElementById('configFixRow').style.display = 'flex';
        } else {
            issEl.innerHTML = '<div style="margin-top:10px; padding:10px 14px; border-radius:8px; border:1px solid #10b981; background:color-mix(in srgb, #10b981, transparent 90%); color:#10b981; font-weight:600; font-size:13px;">&#10003; All config files are in sync. Printing is enabled.</div>';
            issEl.style.display = 'block';
            document.getElementById('configFixRow').style.display = 'none';
        }
        document.getElementById('fixResultBox').style.display = 'none';
    } catch (ex) {
        document.getElementById('configStatusBody').innerHTML = '<div class="muted">Error loading config status: ' + ex.message + '</div>';
    }
}

async function fixConfig() {
    if (!confirm('Auto-fix config issues?\n\nThis will:\n&bull; Set UseForPrinting = true in WebClient appsettings.json\n&bull; Sync MQTT credentials from DB &rarr; appsettings.json files\n&bull; Remove print client username from mqttclient table (if present)\n\nYou will need to restart IIS (iisreset) and the AssetWorx Print Server service after.')) return;

    var data = await api('fixConfig');
    var box = document.getElementById('fixResultBox');

    if (data.error) {
        box.innerHTML = '<div style="padding:12px 16px; border-radius:8px; border:1px solid #ef4444; background:color-mix(in srgb, #ef4444, transparent 90%); color:#ef4444;">' +
            '<strong>Error:</strong> ' + data.error + '</div>';
    } else {
        var html = '<div style="padding:12px 16px; border-radius:8px; border:1px solid #10b981; background:color-mix(in srgb, #10b981, transparent 90%);">' +
            '<div style="font-weight:700;color:#10b981;margin-bottom:8px;">&#10003; Config Updated</div>';
        (data.changes || []).forEach(function(ch) {
            var isWarn = ch.indexOf('WARNING') === 0 || ch.indexOf('NOTICE') === 0;
            html += '<div style="font-size:12px;margin:3px 0;color:' + (isWarn ? '#f59e0b' : 'var(--text)') + ';">&bull; ' + ch + '</div>';
        });
        html += '<div style="margin-top:10px; padding-top:8px; border-top:1px solid var(--line); font-size:12px; color:var(--muted);">' +
            '&#9889; <strong>Restart required:</strong> Run <code>iisreset</code> and restart the AssetWorx Print Server service for changes to take effect.</div>';
        html += '</div>';
        box.innerHTML = html;
    }
    box.style.display = 'block';
    // Reload status to reflect changes
    setTimeout(function() { loadConfigStatus(); }, 500);
}

// ======= SETUP WIZARD =======
async function loadWizardDefaults() {
    try {
        var d = await api('getWizardDefaults');
        document.getElementById('wizMqttServer').value = d.mqttServer || 'localhost';
        document.getElementById('wizMqttPort').value = d.mqttPort || 8883;
        document.getElementById('wizPfxPath').value = d.pfxPath || '';
        document.getElementById('wizUsername').value = d.printClientUsername || 'MasterPrint';
        document.getElementById('wizPassword').value = d.printClientPassword || '';
        document.getElementById('wizClientName').value = d.printClientName || 'Master Print Server';
        document.getElementById('wizBtwPath').value = d.defaultBtwPath || '';

        // Sites checkboxes
        var html = '';
        (d.companies || []).forEach(function(c) {
            var checked = c.hasTemplate ? ' checked' : '';
            var badges = '';
            if (c.hasTemplate) badges += '<span class="badge badge-ok" style="font-size:9px; margin-left:6px;">Template &#10003;</span>';
            if (c.hasClientApp) badges += '<span class="badge badge-ok" style="font-size:9px; margin-left:4px;">API Key &#10003;</span>';
            html += '<label style="display:flex; align-items:center; gap:8px; padding:6px 4px; border-bottom:1px solid var(--line); cursor:pointer; font-size:13px;">' +
                '<input type="checkbox" class="wizSiteCheck" value="' + c.id + '"' + checked + ' style="width:16px; height:16px;" />' +
                '<span style="flex:1; font-weight:600;">' + c.name + '</span>' + badges +
                '</label>';
        });
        if (!html) html = '<div class="muted">No sites found in database.</div>';
        document.getElementById('wizSiteList').innerHTML = html;

        // Config status
        var cfgHtml = '';
        cfgHtml += '<div>' + (d.webClientConfigExists ? '&#9989;' : '&#10060;') + ' WebClient: <code style="font-size:10px;">' + (d.webClientConfigPath || '') + '</code></div>';
        cfgHtml += '<div>' + (d.printServerConfigExists ? '&#9989;' : '&#9888;') + ' Print Server: <code style="font-size:10px;">' + (d.printServerConfigPath || '') + '</code></div>';
        cfgHtml += '<div>' + (d.useForPrinting ? '&#9989;' : '&#10060;') + ' UseForPrinting: <strong>' + (d.useForPrinting ? 'true' : 'false') + '</strong></div>';
        document.getElementById('wizConfigStatus').innerHTML = cfgHtml;
    } catch (e) {
        console.error('Wizard defaults error:', e);
    }
}

async function runWizard() {
    // Validate
    var username = document.getElementById('wizUsername').value.trim();
    var password = document.getElementById('wizPassword').value.trim();
    if (!username) { alert('MQTT Username is required.'); return; }
    if (!password) { alert('MQTT Password is required.'); return; }

    // Collect selected site IDs
    var siteIds = [];
    document.querySelectorAll('.wizSiteCheck:checked').forEach(function(cb) {
        siteIds.push(parseInt(cb.value));
    });

    // Switch to Phase 2
    document.getElementById('wizPhase1').style.display = 'none';
    document.getElementById('wizPhase2').style.display = 'block';
    document.getElementById('wizPhase3').style.display = 'none';

    var stepLog = document.getElementById('wizStepLog');
    stepLog.innerHTML = '';

    // Show placeholder steps
    var stepNames = [
        'Read WebClient appsettings.json',
        'Set UseForPrinting = true',
        'Sync credentials to WebClient config',
        'Sync credentials to Print Server config',
        'Upsert printclient record in database',
        'Remove conflicting mqttclient entries',
        'Create templates for selected sites',
        'Create clientapp API keys'
    ];
    stepNames.forEach(function(name, i) {
        stepLog.innerHTML += '<div id="wizStep' + (i+1) + '" class="wiz-step" style="display:flex; align-items:flex-start; gap:10px; padding:10px 12px; margin-bottom:6px; border-radius:8px; border:1px solid var(--line); opacity:0.4;">' +
            '<span class="wiz-icon" style="font-size:16px; min-width:20px; text-align:center;">&#11036;</span>' +
            '<div style="flex:1;"><div style="font-weight:700; font-size:13px;">' + name + '</div>' +
            '<div class="wiz-detail muted" style="font-size:11px; margin-top:2px;"></div></div></div>';
    });

    // Call the API
    var payload = {
        mqttServer: document.getElementById('wizMqttServer').value,
        mqttPort: parseInt(document.getElementById('wizMqttPort').value),
        username: username,
        password: password,
        clientName: document.getElementById('wizClientName').value,
        btwPath: document.getElementById('wizBtwPath').value,
        siteIds: siteIds
    };

    try {
        var result = await api('runWizard', { body: payload });
        // Animate steps appearing
        var steps = result.steps || [];
        for (var i = 0; i < steps.length; i++) {
            await animateStep(steps[i], i);
        }
        // Show Phase 3
        setTimeout(function() {
            showWizardSummary(result);
        }, 600);
    } catch (e) {
        stepLog.innerHTML += '<div style="color:#ef4444; padding:12px; font-weight:700;">Error: ' + e.message + '</div>';
    }
}

function animateStep(step, index) {
    return new Promise(function(resolve) {
        setTimeout(function() {
            var el = document.getElementById('wizStep' + step.step);
            if (!el) { resolve(); return; }

            el.style.opacity = '1';
            var icon = el.querySelector('.wiz-icon');
            var detail = el.querySelector('.wiz-detail');

            if (step.status === 'pass') {
                icon.textContent = '&#9989;';
                el.style.borderColor = 'color-mix(in srgb, #10b981 40%, transparent)';
                el.style.background = 'color-mix(in srgb, #10b981 5%, transparent)';
            } else if (step.status === 'warn') {
                icon.textContent = '&#9888;';
                el.style.borderColor = 'color-mix(in srgb, #f59e0b 40%, transparent)';
                el.style.background = 'color-mix(in srgb, #f59e0b 5%, transparent)';
            } else {
                icon.textContent = '&#10060;';
                el.style.borderColor = 'color-mix(in srgb, #ef4444 40%, transparent)';
                el.style.background = 'color-mix(in srgb, #ef4444 5%, transparent)';
            }

            detail.textContent = step.detail || '';
            if (step.filePath) {
                detail.innerHTML += '<br><code style="font-size:10px; opacity:0.7;">' + step.filePath + '</code>';
            }

            // Update progress
            var pct = Math.round(((index + 1) / 8) * 100);
            document.getElementById('wizProgressBar').style.width = pct + '%';
            document.getElementById('wizStepCounter').textContent = 'Step ' + (index + 1) + ' of 8';

            resolve();
        }, 200 + (index * 300));
    });
}

function showWizardSummary(result) {
    document.getElementById('wizPhase2').style.display = 'none';
    document.getElementById('wizPhase3').style.display = 'block';

    var s = result.summary || {};
    var allOk = s.failed === 0;
    var headerColor = allOk ? '#10b981' : '#ef4444';
    var headerIcon = allOk ? '&#9989;' : '&#10060;';
    var headerText = allOk
        ? 'Setup Complete &mdash; ' + s.passed + '/' + s.total + ' steps passed' + (s.warned > 0 ? ' (' + s.warned + ' warnings)' : '')
        : 'Setup had ' + s.failed + ' failure(s) &mdash; ' + s.passed + ' passed, ' + s.warned + ' warnings';

    var html = '<div class="panel" style="border:2px solid color-mix(in srgb, ' + headerColor + ' 50%, transparent);">' +
        '<div style="font-size:20px; font-weight:800; color:' + headerColor + '; margin-bottom:18px;">' + headerIcon + ' ' + headerText + '</div>';

    // Step results table
    html += '<table class="grid"><thead><tr><th style="width:30px;">&#10003;</th><th>Step</th><th>Details</th></tr></thead><tbody>';
    (result.steps || []).forEach(function(st) {
        var icon = st.status === 'pass' ? '&#9989;' : st.status === 'warn' ? '&#9888;' : '&#10060;';
        html += '<tr><td>' + icon + '</td><td style="font-weight:600; font-size:13px;">' + st.name + '</td>' +
            '<td style="font-size:12px; color:var(--muted);">' + (st.detail || '') +
            (st.filePath ? '<br><code style="font-size:10px;">' + st.filePath + '</code>' : '') +
            '</td></tr>';
    });
    html += '</tbody></table>';

    // Restart section
    html += '<div style="margin-top:24px; padding:20px; border-radius:12px; background:color-mix(in srgb, #f59e0b 8%, transparent); border:2px solid color-mix(in srgb, #f59e0b 40%, transparent); text-align:center;">' +
        '<div style="font-size:16px; font-weight:800; color:#f59e0b; margin-bottom:8px;">&#9888; RESTART REQUIRED</div>' +
        '<div style="font-size:13px; color:var(--text); margin-bottom:16px;">Configuration changes will <strong>not take effect</strong> until IIS and the Print Server service are restarted.</div>' +
        '<div style="display:flex; gap:12px; justify-content:center; flex-wrap:wrap;">' +
        '<button type="button" class="btn btn-fill" onclick="doRestartIIS()" style="padding:8px 28px; font-size:13px;">' +
        '&#128260; Restart IIS Now</button>' +
        '</div>' +
        '<div style="margin-top:10px; font-size:11px; color:var(--muted);">&#9889; This will briefly disconnect all active users. The page will auto-reload after restart.</div>' +
        '</div>';

    // Action buttons
    html += '<div style="margin-top:18px; display:flex; gap:10px; justify-content:center;">' +
        '<button type="button" class="btn" onclick="switchTab(\'status\'); loadStatus();">&#9654; View Status &amp; Logs</button>' +
        '<button type="button" class="btn" onclick="resetWizard()">&#8635; Run Wizard Again</button>' +
        '</div>';

    html += '</div>';
    document.getElementById('wizSummaryContent').innerHTML = html;
}

function resetWizard() {
    document.getElementById('wizPhase1').style.display = 'block';
    document.getElementById('wizPhase2').style.display = 'none';
    document.getElementById('wizPhase3').style.display = 'none';
    loadWizardDefaults();
}

async function doRestartIIS() {
    if (!confirm('Restart IIS now?\n\nThis will briefly disconnect all active users. The page will auto-reload in 12 seconds.')) return;

    // Show overlay
    var overlay = document.createElement('div');
    overlay.id = 'iisRestartOverlay';
    overlay.style.cssText = 'position:fixed; inset:0; background:rgba(0,0,0,0.7); backdrop-filter:blur(8px); z-index:99999; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:16px;';
    overlay.innerHTML = '<div style="width:48px;height:48px;border:4px solid rgba(255,255,255,.1);border-top-color:#f59e0b;border-radius:50%;animation:spin 1s linear infinite;"></div>' +
        '<div style="color:#fff;font-size:18px;font-weight:700;">Restarting IIS...</div>' +
        '<div style="color:#ccc;font-size:13px;">Page will reload automatically in a few seconds.</div>';
    document.body.appendChild(overlay);

    try {
        await api('restartIIS');
    } catch(e) { /* expected &mdash; server will go down */ }

    // Auto-reload after delay
    setTimeout(function() {
        window.location.reload();
    }, 12000);
}

// ======= INIT =======
loadOverview();
loadConfigStatus();
loadWizardDefaults();
</script>
</body>
</html>
