<%@ Page Language="C#" AutoEventWireup="true" CodeFile="deploy_idash.aspx.cs" Inherits="deploy_idash" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash Deployment &amp; System Wizard</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; background: var(--bg); color: var(--text); font-family: Segoe UI, system-ui, -apple-system, sans-serif; line-height: 1.5; }
        
        .deploy-container { max-width: 1200px; margin: 30px auto; padding: 0 24px; }
        
        /* Header Hero */
        .hero { display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--line); padding-bottom: 20px; margin-bottom: 28px; }
        .hero-left { display: flex; align-items: center; gap: 16px; }
        .hero-logo { width: 44px; height: 44px; border-radius: 10px; background: color-mix(in srgb, var(--accent), transparent 85%); display: flex; align-items: center; justify-content: center; border: 1px solid var(--accent); }
        .hero-title { font-size: 24px; font-weight: 700; margin: 0; letter-spacing: -0.5px; }
        .hero-subtitle { font-size: 13px; color: var(--muted); margin: 3px 0 0 0; }
        
        /* Stepper Navigation */
        .stepper { display: flex; gap: 8px; margin-bottom: 28px; overflow-x: auto; padding-bottom: 6px; }
        .step-pill { flex: 1; min-width: 180px; padding: 12px 16px; background: var(--card); border: 1px solid var(--line); border-radius: 10px; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; gap: 12px; }
        .step-pill:hover { border-color: var(--accent); }
        .step-pill.active { background: color-mix(in srgb, var(--accent), transparent 90%); border-color: var(--accent); }
        .step-pill.completed { border-color: var(--accent-2); }
        .step-num { width: 28px; height: 28px; border-radius: 50%; background: var(--chip); display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: var(--muted); flex-shrink: 0; }
        .step-pill.active .step-num { background: var(--accent); color: #fff; }
        .step-pill.completed .step-num { background: var(--accent-2); color: #000; }
        .step-info { display: flex; flex-direction: column; overflow: hidden; }
        .step-name { font-size: 13px; font-weight: 600; white-space: nowrap; text-overflow: ellipsis; }
        .step-status { font-size: 11px; color: var(--muted); }
        
        /* Cards & Panes */
        .wizard-card { background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 28px; box-shadow: 0 4px 20px rgba(0,0,0,0.15); margin-bottom: 24px; }
        .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--line); padding-bottom: 14px; }
        .card-title { font-size: 18px; font-weight: 700; margin: 0; display: flex; align-items: center; gap: 10px; color: var(--text); }
        .card-desc { font-size: 13px; color: var(--muted); margin: 6px 0 0 0; }
        
        /* Badges */
        .badge { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; }
        .badge-ok   { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: #10b981; border: 1px solid rgba(16,185,129,0.3); }
        .badge-err  { background: color-mix(in srgb, var(--danger), transparent 85%); color: #ef4444; border: 1px solid rgba(239,68,68,0.3); }
        .badge-warn { background: rgba(250,204,21,0.12); color: #eab308; border: 1px solid rgba(250,204,21,0.3); }
        .badge-info { background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--accent); border: 1px solid rgba(46,168,255,0.3); }
        
        /* Grid Lists */
        .item-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 14px; margin-bottom: 20px; }
        .item-box { background: var(--chip); border: 1px solid var(--line); border-radius: 10px; padding: 16px; display: flex; flex-direction: column; justify-content: space-between; }
        .item-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px; }
        .item-title { font-size: 13px; font-weight: 600; color: var(--muted); }
        .item-val { font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 4px; }
        .item-detail { font-size: 11px; color: var(--muted); word-break: break-all; }
        
        /* Buttons */
        .btn { display: inline-flex; align-items: center; gap: 8px; padding: 9px 18px; border-radius: 8px; border: none; font-weight: 600; font-size: 13px; cursor: pointer; transition: 0.15s; }
        .btn:hover { opacity: 0.88; transform: translateY(-1px); }
        .btn-primary { background: var(--accent); color: #fff; }
        .btn-green   { background: var(--accent-2); color: #000; }
        .btn-danger  { background: var(--danger); color: #fff; }
        .btn-ghost   { background: transparent; border: 1px solid var(--line); color: var(--text); }
        .btn-sm { padding: 6px 12px; font-size: 12px; border-radius: 6px; }
        
        /* Tables */
        table.wiz-table { width: 100%; border-collapse: collapse; font-size: 13px; margin-bottom: 16px; }
        table.wiz-table th { background: var(--chip); color: var(--muted); text-align: left; padding: 10px 14px; border-bottom: 2px solid var(--line); font-weight: 600; }
        table.wiz-table td { padding: 10px 14px; border-bottom: 1px solid var(--line); vertical-align: middle; }
        table.wiz-table tr:hover td { background: color-mix(in srgb, var(--accent), transparent 96%); }
        
        /* Input Form */
        .form-row { display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 16px; }
        .form-col { display: flex; flex-direction: column; gap: 6px; flex: 1; min-width: 220px; }
        .form-col label { font-size: 12px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: 0.4px; }
        .form-col input, .form-col select { background: var(--bg); border: 1px solid var(--line); color: var(--text); padding: 9px 12px; border-radius: 8px; font-size: 14px; outline: none; }
        .form-col input:focus, .form-col select:focus { border-color: var(--accent); }
        
        /* Diagnostic Console */
        .log-box { background: #070d17; border: 1px solid var(--line); border-radius: 10px; padding: 14px; font-family: Consolas, monospace; font-size: 12px; color: #a5b4fc; max-height: 220px; overflow-y: auto; margin-top: 14px; }
        .log-entry { margin-bottom: 4px; line-height: 1.4; }
        .log-entry.ok { color: #34d399; }
        .log-entry.err { color: #f87171; }
        .log-entry.warn { color: #fbbf24; }
        
        /* Certificate Banner */
        .cert-card { background: linear-gradient(135deg, color-mix(in srgb, var(--accent-2), transparent 92%), color-mix(in srgb, var(--accent), transparent 94%)); border: 2px solid var(--accent-2); border-radius: 14px; padding: 24px; text-align: center; margin-top: 20px; }
        .cert-title { font-size: 20px; font-weight: 800; color: var(--accent-2); margin-bottom: 6px; letter-spacing: 0.5px; }
        .cert-meta { font-size: 13px; color: var(--muted); margin-bottom: 16px; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="deploy-container">
            
            <!-- Hero Header -->
            <div class="hero">
                <div class="hero-left">
                    <div class="hero-logo">
                        <img src="Assets/branding/rfid.png" alt="iDash" style="height: 26px; width: auto;" />
                    </div>
                    <div>
                        <h1 class="hero-title">iDash Deployment &amp; System Wizard</h1>
                        <p class="hero-subtitle">Automated Install, Database Initializer, Multi-Site Config, and Production Validator</p>
                    </div>
                </div>
                <div>
                    <span class="badge badge-info" id="system-mode-badge">&#9679; iDash Autonomous Platform</span>
                </div>
            </div>

            <!-- Wizard Stepper Navigation -->
            <div class="stepper" id="stepper-nav">
                <div class="step-pill active" id="pill-step-1" onclick="switchStep(1)">
                    <div class="step-num">1</div>
                    <div class="step-info">
                        <div class="step-name">Environment</div>
                        <div class="step-status" id="step1-status">Prerequisites</div>
                    </div>
                </div>
                <div class="step-pill" id="pill-step-2" onclick="switchStep(2)">
                    <div class="step-num">2</div>
                    <div class="step-info">
                        <div class="step-name">Database Schema</div>
                        <div class="step-status" id="step2-status">Schema Engine</div>
                    </div>
                </div>
                <div class="step-pill" id="pill-step-3" onclick="switchStep(3)">
                    <div class="step-num">3</div>
                    <div class="step-info">
                        <div class="step-name">Facilities &amp; Sites</div>
                        <div class="step-status" id="step3-status">Multi-Site Isolation</div>
                    </div>
                </div>
                <div class="step-pill" id="pill-step-4" onclick="switchStep(4)">
                    <div class="step-num">4</div>
                    <div class="step-info">
                        <div class="step-name">Admin &amp; Security</div>
                        <div class="step-status" id="step4-status">idashadmin Setup</div>
                    </div>
                </div>
                <div class="step-pill" id="pill-step-5" onclick="switchStep(5)">
                    <div class="step-num">5</div>
                    <div class="step-info">
                        <div class="step-name">Validation Suite</div>
                        <div class="step-status" id="step5-status">Certification</div>
                    </div>
                </div>
            </div>

            <!-- STEP 1: Environment & Prerequisites -->
            <div class="wizard-pane" id="pane-step-1">
                <div class="wizard-card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">&#128640; Step 1: Host Environment &amp; Prerequisites</h2>
                            <p class="card-desc">Verifying server runtime, IIS environment, file write permissions, and SQL connectivity.</p>
                        </div>
                        <button type="button" class="btn btn-primary" id="btn-run-env" onclick="runEnvironmentCheck()">
                            &#8635; Run Environment Check
                        </button>
                    </div>

                    <div class="item-grid" id="env-grid">
                        <div class="item-box">
                            <div class="item-top">
                                <span class="item-title">Status</span>
                                <span class="badge badge-info">Initializing</span>
                            </div>
                            <div class="item-val">Waiting to execute check...</div>
                            <div class="item-detail">Click 'Run Environment Check' above</div>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: flex-end; gap: 12px; margin-top: 20px;">
                        <button type="button" class="btn btn-green" onclick="switchStep(2)">Proceed to Database Step &rarr;</button>
                    </div>
                </div>
            </div>

            <!-- STEP 2: Database Initialization & Schema Engine -->
            <div class="wizard-pane" id="pane-step-2" style="display: none;">
                <div class="wizard-card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">&#128451; Step 2: Database Initialization &amp; Schema Engine</h2>
                            <p class="card-desc">Inspect, deploy, or upgrade the clean iDash database schema with zero AssetWorx legacy artifacts.</p>
                        </div>
                        <div style="display:flex; gap:10px;">
                            <button type="button" class="btn btn-ghost" onclick="checkDatabaseStatus()">&#8635; Check Schema</button>
                            <button type="button" class="btn btn-primary" id="btn-deploy-schema" onclick="deploySchema()">&#9881; Deploy / Refresh Schema</button>
                        </div>
                    </div>

                    <div class="item-grid" id="db-summary-grid">
                        <div class="item-box">
                            <div class="item-top">
                                <span class="item-title">Database Status</span>
                                <span class="badge badge-info" id="db-status-badge">Checking...</span>
                            </div>
                            <div class="item-val" id="db-target-name">iDash on .\SQLEXPRESS</div>
                            <div class="item-detail" id="db-detail-text">Querying SQL Server...</div>
                        </div>
                        <div class="item-box">
                            <div class="item-top">
                                <span class="item-title">Schema Architecture</span>
                                <span class="badge badge-ok" id="schema-badge">26 Clean Tables</span>
                            </div>
                            <div class="item-val" id="db-table-count">-- Tables / -- Views</div>
                            <div class="item-detail">Zero AssetWorx legacy columns or tables</div>
                        </div>
                        <div class="item-box">
                            <div class="item-top">
                                <span class="item-title">Live Asset Count</span>
                                <span class="badge badge-ok" id="asset-count-badge">Loaded</span>
                            </div>
                            <div class="item-val" id="db-asset-count">-- Assets</div>
                            <div class="item-detail">Active unified VA inventory</div>
                        </div>
                    </div>

                    <div id="legacy-warning-box" style="display: none; padding: 14px; border-radius: 8px; background: color-mix(in srgb, var(--danger), transparent 85%); border: 1px solid var(--danger); color: var(--danger); margin-bottom: 16px;">
                        <strong>Legacy Artifact Notice:</strong> <span id="legacy-warning-text"></span>
                    </div>

                    <div class="log-box" id="db-log-box">
                        <div class="log-entry">[Ready] Ready to inspect or deploy clean iDash schema.</div>
                    </div>

                    <div style="display: flex; justify-content: space-between; gap: 12px; margin-top: 20px;">
                        <button type="button" class="btn btn-ghost" onclick="switchStep(1)">&larr; Back to Environment</button>
                        <button type="button" class="btn btn-green" onclick="switchStep(3)">Proceed to Facilities Step &rarr;</button>
                    </div>
                </div>
            </div>

            <!-- STEP 3: Facility / Multi-Site Provisioning -->
            <div class="wizard-pane" id="pane-step-3" style="display: none;">
                <div class="wizard-card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">&#127973; Step 3: Facility &amp; Multi-Site Provisioning</h2>
                            <p class="card-desc">Manage VA Medical Centers, Station numbers, isolated OAuth client keys, and MQTT topics.</p>
                        </div>
                        <button type="button" class="btn btn-ghost" onclick="loadFacilities()">&#8635; Refresh Facilities</button>
                    </div>

                    <!-- Facility Table -->
                    <div style="overflow-x: auto;">
                        <table class="wiz-table" id="facility-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Station / Facility Name</th>
                                    <th>Active Assets</th>
                                    <th>API Client Key (dbo.clientapp)</th>
                                    <th>MQTT Credentials</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody id="facility-tbody">
                                <tr><td colspan="6" style="text-align:center; color:var(--muted); padding:20px;">Loading registered facilities...</td></tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Add Facility Form -->
                    <div style="background: var(--chip); border: 1px solid var(--line); border-radius: 10px; padding: 20px; margin-top: 20px;">
                        <h3 style="margin: 0 0 14px 0; font-size: 15px; font-weight: 700; color: var(--accent);">+ Provision New VA Station / Facility</h3>
                        <div class="form-row">
                            <div class="form-col" style="max-width: 140px;">
                                <label for="txt-station">Station #</label>
                                <input type="text" id="txt-station" placeholder="e.g. 528" />
                            </div>
                            <div class="form-col">
                                <label for="txt-facility-name">Facility Name</label>
                                <input type="text" id="txt-facility-name" placeholder="e.g. Upstate New York" />
                            </div>
                            <div class="form-col" style="max-width: 180px; align-self: flex-end;">
                                <button type="button" class="btn btn-primary" style="width: 100%;" id="btn-add-facility" onclick="provisionFacility()">
                                    &#10010; Provision Station
                                </button>
                            </div>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: space-between; gap: 12px; margin-top: 24px;">
                        <button type="button" class="btn btn-ghost" onclick="switchStep(2)">&larr; Back to Database</button>
                        <button type="button" class="btn btn-green" onclick="switchStep(4)">Proceed to Admin Setup &rarr;</button>
                    </div>
                </div>
            </div>

            <!-- STEP 4: Administrator & Security Setup -->
            <div class="wizard-pane" id="pane-step-4" style="display: none;">
                <div class="wizard-card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">&#128272; Step 4: Administrator Account &amp; Access Control</h2>
                            <p class="card-desc">Manage primary <code>idashadmin</code> credentials with modern PBKDF2-SHA256 password security.</p>
                        </div>
                    </div>

                    <div style="max-width: 640px;">
                        <div class="form-row">
                            <div class="form-col">
                                <label>Username</label>
                                <input type="text" value="idashadmin" disabled="disabled" style="opacity: 0.7;" />
                            </div>
                            <div class="form-col">
                                <label for="txt-admin-email">Administrator Email</label>
                                <input type="email" id="txt-admin-email" value="admin@idash.local" />
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-col">
                                <label for="txt-admin-first">First Name</label>
                                <input type="text" id="txt-admin-first" value="iDash" />
                            </div>
                            <div class="form-col">
                                <label for="txt-admin-last">Last Name</label>
                                <input type="text" id="txt-admin-last" value="Administrator" />
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-col">
                                <label for="txt-admin-pass">New Password</label>
                                <input type="password" id="txt-admin-pass" placeholder="Leave blank to preserve current password" />
                            </div>
                            <div class="form-col">
                                <label for="txt-admin-pass-confirm">Confirm Password</label>
                                <input type="password" id="txt-admin-pass-confirm" placeholder="Confirm password" />
                            </div>
                        </div>

                        <div style="margin-top: 14px;">
                            <button type="button" class="btn btn-primary" id="btn-save-admin" onclick="saveAdminAccount()">
                                &#128190; Save Administrator Profile
                            </button>
                            <span id="admin-save-msg" style="margin-left: 12px; font-size: 13px;"></span>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: space-between; gap: 12px; margin-top: 28px;">
                        <button type="button" class="btn btn-ghost" onclick="switchStep(3)">&larr; Back to Facilities</button>
                        <button type="button" class="btn btn-green" onclick="switchStep(5)">Proceed to Validation &rarr;</button>
                    </div>
                </div>
            </div>

            <!-- STEP 5: Validation Suite & Certification -->
            <div class="wizard-pane" id="pane-step-5" style="display: none;">
                <div class="wizard-card">
                    <div class="card-header">
                        <div>
                            <h2 class="card-title">&#9989; Step 5: End-to-End System Validation Suite</h2>
                            <p class="card-desc">Execute automated probes against database reads, writes, unified views, scan API, and network sockets.</p>
                        </div>
                        <button type="button" class="btn btn-primary" id="btn-run-tests" onclick="runValidationSuite()">
                            &#9654; Run Automated Test Suite
                        </button>
                    </div>

                    <div id="test-results-container">
                        <div class="item-box" style="margin-bottom: 14px;">
                            <div class="item-top">
                                <span class="item-title">Automated Diagnostics</span>
                                <span class="badge badge-info">Pending Run</span>
                            </div>
                            <div class="item-val">Click 'Run Automated Test Suite' above to certify this deployment.</div>
                            <div class="item-detail">Simulates end-to-end CRUD operations, view resolution, and API responsiveness.</div>
                        </div>
                    </div>

                    <!-- Certification Card (Revealed upon 100% pass) -->
                    <div class="cert-card" id="cert-card" style="display: none;">
                        <div style="font-size: 36px; margin-bottom: 4px;">&#127881;</div>
                        <div class="cert-title">iDash Production Deployment Certified</div>
                        <div class="cert-meta" id="cert-meta-text">All systems verified operational with zero legacy AssetWorx dependencies.</div>
                        <div style="display: flex; justify-content: center; gap: 12px; margin-top: 14px;">
                            <a href="index.aspx" class="btn btn-green">&#127968; Go to iDash Hub</a>
                            <a href="va_asset_master.aspx" class="btn btn-primary">&#128451; Open Asset Master</a>
                            <a href="va_fixed_reader.aspx" class="btn btn-ghost">&#128225; Fixed Reader Portal</a>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: space-between; gap: 12px; margin-top: 24px;">
                        <button type="button" class="btn btn-ghost" onclick="switchStep(4)">&larr; Back to Admin Setup</button>
                    </div>
                </div>
            </div>

        </div>

        <idash:Footer ID="iDashFooterCtrl" runat="server" />
    </form>

    <script>
        let currentStep = 1;

        function switchStep(step) {
            currentStep = step;
            for (let i = 1; i <= 5; i++) {
                const pane = document.getElementById('pane-step-' + i);
                const pill = document.getElementById('pill-step-' + i);
                if (pane) pane.style.display = (i === step) ? 'block' : 'none';
                if (pill) {
                    if (i === step) {
                        pill.classList.add('active');
                    } else {
                        pill.classList.remove('active');
                    }
                }
            }

            if (step === 1) runEnvironmentCheck();
            if (step === 2) checkDatabaseStatus();
            if (step === 3) loadFacilities();
        }

        // --- Step 1: Environment Check ---
        function runEnvironmentCheck() {
            const btn = document.getElementById('btn-run-env');
            if (btn) btn.disabled = true;
            const grid = document.getElementById('env-grid');
            grid.innerHTML = '<div style="color:var(--muted); padding:20px;">Checking host environment, IIS, .NET runtime, and SQL Server...</div>';

            fetch('deploy_idash.aspx?action=check_env')
                .then(r => r.json())
                .then(data => {
                    if (btn) btn.disabled = false;
                    if (!data.success) {
                        grid.innerHTML = '<div class="item-box" style="border-color:var(--danger);"><div class="item-val" style="color:var(--danger);">Error: ' + data.error + '</div></div>';
                        return;
                    }

                    let html = '';
                    data.items.forEach(it => {
                        const badgeClass = (it.status === 'ok') ? 'badge-ok' : (it.status === 'warn' ? 'badge-warn' : 'badge-err');
                        const statusText = (it.status === 'ok') ? '&#10003; Healthy' : (it.status === 'warn' ? '&#9888; Warning' : '&#10007; Action Required');
                        html += `
                            <div class="item-box">
                                <div class="item-top">
                                    <span class="item-title">${it.title}</span>
                                    <span class="badge ${badgeClass}">${statusText}</span>
                                </div>
                                <div class="item-val">${it.value}</div>
                                <div class="item-detail">${it.detail}</div>
                            </div>
                        `;
                    });
                    grid.innerHTML = html;
                    
                    const pillStatus = document.getElementById('step1-status');
                    if (pillStatus) {
                        pillStatus.innerText = data.allHealthy ? 'Passed' : 'Needs Review';
                        pillStatus.style.color = data.allHealthy ? '#10b981' : '#f59e0b';
                    }
                    if (data.allHealthy) {
                        document.getElementById('pill-step-1').classList.add('completed');
                    }
                })
                .catch(err => {
                    if (btn) btn.disabled = false;
                    grid.innerHTML = '<div class="item-box" style="border-color:var(--danger);"><div class="item-val" style="color:var(--danger);">Request Failed: ' + err + '</div></div>';
                });
        }

        // --- Step 2: Database Status & Deploy ---
        function checkDatabaseStatus() {
            fetch('deploy_idash.aspx?action=check_db_status')
                .then(r => r.json())
                .then(data => {
                    const statusBadge = document.getElementById('db-status-badge');
                    const tableCountEl = document.getElementById('db-table-count');
                    const assetCountEl = document.getElementById('db-asset-count');
                    const detailEl = document.getElementById('db-detail-text');
                    const warnBox = document.getElementById('legacy-warning-box');
                    const warnText = document.getElementById('legacy-warning-text');
                    const pill = document.getElementById('pill-step-2');
                    const pillStatus = document.getElementById('step2-status');

                    if (data.dbExists) {
                        statusBadge.className = 'badge badge-ok';
                        statusBadge.innerHTML = '&#10003; Database Online';
                        detailEl.innerText = 'Connected and catalog verified';
                        tableCountEl.innerText = data.tableCount + ' Base Tables / ' + data.viewCount + ' Views';
                        assetCountEl.innerText = Number(data.assetCount).toLocaleString() + ' Assets';
                        
                        if (data.hasLegacyRemnants) {
                            warnBox.style.display = 'block';
                            warnText.innerText = data.legacyIssues.join('; ');
                            statusBadge.className = 'badge badge-warn';
                            statusBadge.innerHTML = '&#9888; Legacy Artifacts Found';
                        } else {
                            warnBox.style.display = 'none';
                        }

                        if (data.isReady) {
                            pill.classList.add('completed');
                            if (pillStatus) { pillStatus.innerText = 'Clean & Ready'; pillStatus.style.color = '#10b981'; }
                        }
                    } else {
                        statusBadge.className = 'badge badge-err';
                        statusBadge.innerHTML = '&#10007; Not Found';
                        detailEl.innerText = 'iDash database does not exist yet. Click Deploy below.';
                        tableCountEl.innerText = '0 Tables';
                        assetCountEl.innerText = '0 Assets';
                    }
                })
                .catch(err => console.error(err));
        }

        function deploySchema() {
            const btn = document.getElementById('btn-deploy-schema');
            const logBox = document.getElementById('db-log-box');
            if (btn) btn.disabled = true;
            logBox.innerHTML += `<div class="log-entry">[Deploy] Executing sql/idash_schema_setup.sql against iDash database...</div>`;

            fetch('deploy_idash.aspx?action=deploy_schema')
                .then(r => r.json())
                .then(data => {
                    if (btn) btn.disabled = false;
                    if (data.success) {
                        logBox.innerHTML += `<div class="log-entry ok">[Success] Executed ${data.batchesExecuted} schema batches with 0 errors!</div>`;
                    } else {
                        logBox.innerHTML += `<div class="log-entry err">[Notice] ${data.batchesExecuted} batches executed, ${data.batchesFailed} notices/errors.</div>`;
                        if (data.errors) {
                            data.errors.forEach(e => {
                                logBox.innerHTML += `<div class="log-entry err">&bull; ${e}</div>`;
                            });
                        }
                    }
                    logBox.scrollTop = logBox.scrollHeight;
                    checkDatabaseStatus();
                })
                .catch(err => {
                    if (btn) btn.disabled = false;
                    logBox.innerHTML += `<div class="log-entry err">[Error] ${err}</div>`;
                });
        }

        // --- Step 3: Facilities ---
        function loadFacilities() {
            const tbody = document.getElementById('facility-tbody');
            fetch('deploy_idash.aspx?action=get_facilities')
                .then(r => r.json())
                .then(data => {
                    if (!data.success) {
                        tbody.innerHTML = `<tr><td colspan="6" style="color:var(--danger); padding:16px;">Error: ${data.error}</td></tr>`;
                        return;
                    }

                    if (data.facilities.length === 0) {
                        tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:var(--muted); padding:16px;">No facilities registered yet.</td></tr>`;
                        return;
                    }

                    let html = '';
                    data.facilities.forEach(f => {
                        html += `
                            <tr>
                                <td><strong>#${f.id}</strong></td>
                                <td style="font-weight:600;">${f.name}</td>
                                <td><span class="badge badge-info">${Number(f.assetCount).toLocaleString()} assets</span></td>
                                <td><code>${f.clientId}</code></td>
                                <td><code>${f.mqttUser}</code></td>
                                <td><span class="badge badge-ok">&#10003; Active</span></td>
                            </tr>
                        `;
                    });
                    tbody.innerHTML = html;
                    document.getElementById('pill-step-3').classList.add('completed');
                    const pillStatus = document.getElementById('step3-status');
                    if (pillStatus) { pillStatus.innerText = data.facilities.length + ' Configured'; pillStatus.style.color = '#10b981'; }
                })
                .catch(err => console.error(err));
        }

        function provisionFacility() {
            const station = document.getElementById('txt-station').value.trim();
            const name = document.getElementById('txt-facility-name').value.trim();
            if (!station || !name) {
                alert('Please enter both Station Number (e.g. 528) and Facility Name (e.g. Upstate New York).');
                return;
            }

            const btn = document.getElementById('btn-add-facility');
            if (btn) btn.disabled = true;

            const url = `deploy_idash.aspx?action=provision_facility&station=${encodeURIComponent(station)}&name=${encodeURIComponent(name)}`;
            fetch(url)
                .then(r => r.json())
                .then(data => {
                    if (btn) btn.disabled = false;
                    if (data.success) {
                        document.getElementById('txt-station').value = '';
                        document.getElementById('txt-facility-name').value = '';
                        loadFacilities();
                    } else {
                        alert('Error: ' + data.error);
                    }
                })
                .catch(err => {
                    if (btn) btn.disabled = false;
                    alert('Request error: ' + err);
                });
        }

        // --- Step 4: Admin Account ---
        function saveAdminAccount() {
            const pass = document.getElementById('txt-admin-pass').value;
            const passConfirm = document.getElementById('txt-admin-pass-confirm').value;
            const email = document.getElementById('txt-admin-email').value;
            const first = document.getElementById('txt-admin-first').value;
            const last = document.getElementById('txt-admin-last').value;
            const msgEl = document.getElementById('admin-save-msg');

            if (pass && pass !== passConfirm) {
                msgEl.style.color = 'var(--danger)';
                msgEl.innerText = 'Passwords do not match.';
                return;
            }

            const btn = document.getElementById('btn-save-admin');
            if (btn) btn.disabled = true;
            msgEl.innerText = 'Saving...';

            const url = `deploy_idash.aspx?action=update_admin&password=${encodeURIComponent(pass)}&email=${encodeURIComponent(email)}&firstname=${encodeURIComponent(first)}&lastname=${encodeURIComponent(last)}`;
            fetch(url)
                .then(r => r.json())
                .then(data => {
                    if (btn) btn.disabled = false;
                    if (data.success) {
                        msgEl.style.color = '#10b981';
                        msgEl.innerHTML = '&#10003; ' + data.message;
                        document.getElementById('txt-admin-pass').value = '';
                        document.getElementById('txt-admin-pass-confirm').value = '';
                        document.getElementById('pill-step-4').classList.add('completed');
                        const pillStatus = document.getElementById('step4-status');
                        if (pillStatus) { pillStatus.innerText = 'Configured'; pillStatus.style.color = '#10b981'; }
                    } else {
                        msgEl.style.color = 'var(--danger)';
                        msgEl.innerText = 'Error: ' + data.error;
                    }
                })
                .catch(err => {
                    if (btn) btn.disabled = false;
                    msgEl.style.color = 'var(--danger)';
                    msgEl.innerText = 'Error: ' + err;
                });
        }

        // --- Step 5: Diagnostics & Certification ---
        function runValidationSuite() {
            const btn = document.getElementById('btn-run-tests');
            if (btn) btn.disabled = true;
            const container = document.getElementById('test-results-container');
            container.innerHTML = '<div style="color:var(--muted); padding:20px;">Executing diagnostic test suite across database, views, scan API, and network services...</div>';

            fetch('deploy_idash.aspx?action=run_tests')
                .then(r => r.json())
                .then(data => {
                    if (btn) btn.disabled = false;
                    if (!data.success) {
                        container.innerHTML = `<div class="item-box" style="border-color:var(--danger);"><div class="item-val" style="color:var(--danger);">Error: ${data.error}</div></div>`;
                        return;
                    }

                    let html = '<div class="item-grid">';
                    data.results.forEach(res => {
                        const badgeClass = res.passed ? 'badge-ok' : 'badge-err';
                        const badgeText = res.passed ? '&#10003; PASS' : '&#10007; FAIL';
                        const latencyStr = res.latencyMs >= 0 ? `${res.latencyMs}ms` : 'N/A';
                        html += `
                            <div class="item-box">
                                <div class="item-top">
                                    <span class="item-title">${res.name}</span>
                                    <span class="badge ${badgeClass}">${badgeText} (${latencyStr})</span>
                                </div>
                                <div class="item-val" style="font-size:13px; font-weight:600;">${res.message}</div>
                            </div>
                        `;
                    });
                    html += '</div>';
                    container.innerHTML = html;

                    if (data.allPassed) {
                        const cert = document.getElementById('cert-card');
                        cert.style.display = 'block';
                        document.getElementById('cert-meta-text').innerHTML = `Certified Host: <strong>${data.serverHost}</strong> &bull; Verified: <strong>${data.certifiedTimestamp}</strong> &bull; Zero Legacy Dependencies`;
                        document.getElementById('pill-step-5').classList.add('completed');
                        const pillStatus = document.getElementById('step5-status');
                        if (pillStatus) { pillStatus.innerText = '100% Certified'; pillStatus.style.color = '#10b981'; }
                    }
                })
                .catch(err => {
                    if (btn) btn.disabled = false;
                    container.innerHTML = `<div class="item-box" style="border-color:var(--danger);"><div class="item-val" style="color:var(--danger);">Diagnostic execution error: ${err}</div></div>`;
                });
        }

        // Initialize on load
        document.addEventListener('DOMContentLoaded', function() {
            runEnvironmentCheck();
        });
    </script>
</body>
</html>
