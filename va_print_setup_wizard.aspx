<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_print_setup_wizard.aspx.cs" Inherits="va_print_setup_wizard" ResponseEncoding="utf-8" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Print Setup Wizard &mdash; iDash</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta charset="utf-8" />
<style>
    * { box-sizing: border-box; margin: 0; }
    body { background: var(--bg); color: var(--text); font-family: Segoe UI, Tahoma, Arial, sans-serif; padding: 0; }

    /* ── Layout ─────────────────────────────────── */
    .wizard-wrap { max-width: 1080px; margin: 0 auto; padding: 28px 32px; }
    .wizard-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 12px; }
    .wizard-header h1 { font-size: 24px; font-weight: 800; }
    .wizard-header h1 span { color: var(--accent); }
    .wizard-header .nav-links { display: flex; gap: 8px; }
    .wizard-header .nav-links a { font-size: 13px; color: var(--accent); text-decoration: none; padding: 7px 14px; border: 1px solid var(--line); border-radius: 8px; font-weight: 600; }
    .wizard-header .nav-links a:hover { background: color-mix(in srgb, var(--accent) 10%, transparent); }

    /* ── Summary Bar ────────────────────────────── */
    .summary-bar { display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 12px; margin-bottom: 24px; }
    .sum-card { background: var(--chip); border: 1px solid var(--line); border-radius: 12px; padding: 14px 16px; text-align: center; cursor: pointer; transition: all .2s; }
    .sum-card:hover { border-color: var(--accent); transform: translateY(-2px); }
    .sum-card.pass { border-left: 4px solid #10b981; }
    .sum-card.fail { border-left: 4px solid #ef4444; }
    .sum-card.warn { border-left: 4px solid #f59e0b; }
    .sum-card.pending { border-left: 4px solid var(--muted); }
    .sum-card .sc-icon { font-size: 22px; margin-bottom: 4px; }
    .sum-card .sc-label { font-size: 11px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); font-weight: 700; }

    /* ── Action Bar ──────────────────────────────── */
    .action-bar { display: flex; gap: 10px; margin-bottom: 28px; flex-wrap: wrap; }
    .btn { padding: 10px 22px; border-radius: 10px; border: 2px solid var(--accent); background: transparent; color: var(--accent); cursor: pointer; font-weight: 700; font-size: 13px; transition: all .2s; }
    .btn:hover { background: color-mix(in srgb, var(--accent) 10%, transparent); }
    .btn-fill { background: var(--accent); color: #fff; border-color: var(--accent); }
    .btn-fill:hover { opacity: .9; }
    .btn-success { border-color: #10b981; color: #10b981; }
    .btn-success:hover { background: color-mix(in srgb, #10b981 10%, transparent); }
    .btn-danger { border-color: #ef4444; color: #ef4444; }
    .btn-danger:hover { background: color-mix(in srgb, #ef4444 10%, transparent); }
    .btn-sm { padding: 6px 14px; font-size: 12px; }
    .btn:disabled { opacity: .5; cursor: not-allowed; }

    /* ── Step Panels ─────────────────────────────── */
    .step { background: var(--card); border: 1px solid var(--line); border-radius: 14px; margin-bottom: 18px; overflow: hidden; transition: all .3s; }
    .step.expanded .step-body { display: block; }
    .step-head { display: flex; align-items: center; gap: 14px; padding: 16px 20px; cursor: pointer; user-select: none; }
    .step-head:hover { background: color-mix(in srgb, var(--accent) 3%, transparent); }
    .step-num { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 15px; flex-shrink: 0; background: var(--chip); color: var(--muted); border: 2px solid var(--line); }
    .step.pass .step-num { background: color-mix(in srgb, #10b981 15%, transparent); color: #10b981; border-color: #10b981; }
    .step.fail .step-num { background: color-mix(in srgb, #ef4444 15%, transparent); color: #ef4444; border-color: #ef4444; }
    .step.warn .step-num { background: color-mix(in srgb, #f59e0b 15%, transparent); color: #f59e0b; border-color: #f59e0b; }
    .step-info { flex: 1; }
    .step-title { font-size: 15px; font-weight: 700; }
    .step-sub { font-size: 12px; color: var(--muted); margin-top: 2px; }
    .step-status { font-size: 22px; }
    .step-body { display: none; padding: 0 20px 20px; }

    /* ── Why Notes ───────────────────────────────── */
    .why-note { background: color-mix(in srgb, var(--accent) 6%, transparent); border: 1px solid color-mix(in srgb, var(--accent) 20%, transparent); border-radius: 10px; padding: 12px 16px; margin-bottom: 16px; font-size: 13px; line-height: 1.6; }
    .why-note strong { color: var(--accent); }

    /* ── Data Tables ─────────────────────────────── */
    .dtable { width: 100%; border-collapse: collapse; font-size: 13px; margin: 12px 0; }
    .dtable th { background: var(--chip); color: var(--accent); padding: 9px 12px; text-align: left; border-bottom: 2px solid var(--line); font-size: 11px; text-transform: uppercase; letter-spacing: .04em; }
    .dtable td { padding: 9px 12px; border-bottom: 1px solid var(--line); }
    .dtable tr:hover td { background: color-mix(in srgb, var(--accent) 4%, transparent); }

    /* ── Config Grid ─────────────────────────────── */
    .cfg-grid { display: grid; grid-template-columns: 220px 1fr 100px; gap: 8px 14px; align-items: center; margin: 12px 0; }
    .cfg-label { font-size: 13px; font-weight: 700; color: var(--muted); }
    .cfg-label small { display: block; font-weight: 400; font-size: 11px; opacity: .8; margin-top: 1px; }
    .cfg-value { font-size: 13px; font-family: Consolas, monospace; padding: 7px 10px; background: var(--chip); border: 1px solid var(--line); border-radius: 6px; word-break: break-all; }
    .cfg-value.ok { border-color: #10b981; }
    .cfg-value.bad { border-color: #ef4444; background: color-mix(in srgb, #ef4444 8%, transparent); }
    .cfg-status { font-size: 16px; text-align: center; }

    /* ── Issue List ──────────────────────────────── */
    .issue-list { margin: 12px 0; }
    .issue-item { display: flex; gap: 8px; align-items: flex-start; padding: 8px 12px; background: color-mix(in srgb, #ef4444 6%, transparent); border: 1px solid color-mix(in srgb, #ef4444 20%, transparent); border-radius: 8px; margin-bottom: 6px; font-size: 13px; line-height: 1.5; }
    .issue-item.warn { background: color-mix(in srgb, #f59e0b 6%, transparent); border-color: color-mix(in srgb, #f59e0b 20%, transparent); }
    .issue-icon { font-size: 16px; flex-shrink: 0; margin-top: 1px; }

    /* ── Badges ──────────────────────────────────── */
    .badge { display: inline-block; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; }
    .badge-ok { background: color-mix(in srgb, #10b981 15%, transparent); color: #10b981; }
    .badge-err { background: color-mix(in srgb, #ef4444 15%, transparent); color: #ef4444; }
    .badge-warn { background: color-mix(in srgb, #f59e0b 15%, transparent); color: #f59e0b; }
    .badge-info { background: color-mix(in srgb, var(--accent) 15%, transparent); color: var(--accent); }

    /* ── Test Result ─────────────────────────────── */
    .test-result { margin-top: 12px; padding: 16px; border-radius: 10px; }
    .test-result.success { background: color-mix(in srgb, #10b981 8%, transparent); border: 1px solid #10b981; }
    .test-result.failure { background: color-mix(in srgb, #ef4444 8%, transparent); border: 1px solid #ef4444; }
    .test-steps { margin-top: 10px; font-size: 13px; font-family: Consolas, monospace; line-height: 1.8; }

    /* ── Loading ─────────────────────────────────── */
    .spinner { display: inline-block; width: 16px; height: 16px; border: 2px solid var(--line); border-top-color: var(--accent); border-radius: 50%; animation: spin .6s linear infinite; vertical-align: middle; margin-right: 6px; }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* ── Overall Result Banner ───────────────────── */
    .result-banner { padding: 20px; border-radius: 14px; text-align: center; margin-bottom: 24px; font-size: 18px; font-weight: 800; display: none; }
    .result-banner.show { display: block; }
    .result-banner.all-pass { background: color-mix(in srgb, #10b981 10%, transparent); border: 2px solid #10b981; color: #10b981; }
    .result-banner.has-issues { background: color-mix(in srgb, #ef4444 10%, transparent); border: 2px solid #ef4444; color: #ef4444; }

    /* ── Mode Selector ──────────────────────────────── */
    .mode-selector { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px; }
    .mode-card { padding: 20px 24px; border-radius: 14px; border: 2px solid var(--line); background: var(--card); cursor: pointer; transition: all .25s; position: relative; overflow: hidden; }
    .mode-card:hover { border-color: var(--accent); transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,.08); }
    .mode-card.active { border-color: var(--accent); background: color-mix(in srgb, var(--accent) 6%, var(--card)); }
    .mode-card.active::after { content: '✅'; position: absolute; top: 12px; right: 16px; font-size: 20px; }
    .mode-card .mode-icon { font-size: 32px; margin-bottom: 8px; }
    .mode-card .mode-title { font-size: 16px; font-weight: 800; margin-bottom: 4px; }
    .mode-card .mode-desc { font-size: 13px; color: var(--muted); line-height: 1.5; }
    .mode-card .mode-tag { display: inline-block; margin-top: 10px; padding: 3px 10px; border-radius: 6px; font-size: 11px; font-weight: 700; }
    .mode-card .mode-tag.recommended { background: color-mix(in srgb, #10b981 15%, transparent); color: #10b981; }
    .mode-card .mode-tag.legacy { background: color-mix(in srgb, #f59e0b 15%, transparent); color: #f59e0b; }
    .mode-detecting { text-align: center; padding: 16px; font-size: 14px; color: var(--muted); }

    /* ── Hidden / N/A Steps ──────────────────────────── */
    .step.hidden-mode { display: none !important; }
    .sum-card.na { opacity: .4; pointer-events: none; }
    .sum-card.na .sc-icon { font-size: 11px; }

    /* ── Editable Config Fields ──────────────────── */
    .cfg-edit-group { margin-bottom: 20px; }
    .cfg-edit-group h4 { color: var(--accent); margin: 0 0 10px; font-size: 14px; }
    .cfg-edit-row { display: grid; grid-template-columns: 200px 1fr; gap: 8px; align-items: center; margin-bottom: 8px; }
    .cfg-edit-row label { font-size: 13px; font-weight: 600; }
    .cfg-edit-row label small { display: block; font-weight: 400; color: var(--muted); font-size: 11px; line-height: 1.3; margin-top: 2px; }
    .cfg-edit-row input, .cfg-edit-row select { padding: 8px 12px; border-radius: 8px; border: 1px solid var(--line); background: var(--bg); color: var(--text); font-size: 13px; font-family: Consolas, monospace; width: 100%; box-sizing: border-box; }
    .cfg-edit-row input:focus { border-color: var(--accent); outline: none; box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 15%, transparent); }
    .structure-check { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 6px; font-size: 12px; margin: 3px; }
    .structure-check.ok { background: color-mix(in srgb, #10b981 10%, transparent); color: #10b981; }
    .structure-check.bad { background: color-mix(in srgb, #ef4444 10%, transparent); color: #ef4444; }
    .rebuild-warning { padding: 14px 18px; border-radius: 10px; background: color-mix(in srgb, #ef4444 6%, transparent); border: 1px solid color-mix(in srgb, #ef4444 25%, transparent); font-size: 13px; line-height: 1.6; margin-top: 16px; }
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="wizard-wrap">

    <!-- Header -->
    <div class="wizard-header">
        <h1>🖨️ Print <span>Setup Wizard</span></h1>
        <div class="nav-links">
            <a href="va_print_admin.aspx">← Print Admin</a>
            <a href="va_site_config.aspx">System Config</a>
            <a href="index.aspx">Home</a>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  MODE SELECTOR                                                ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div id="modeSelector">
        <div class="mode-detecting" id="modeDetecting">
            <span class="spinner"></span> Auto-detecting deployment mode...
        </div>
        <div class="mode-selector" id="modeCards" style="display:none;">
            <div class="mode-card" id="modeAssetworx" onclick="selectMode('assetworx')">
                <div class="mode-icon">🏢</div>
                <div class="mode-title">AssetWorx Print Server</div>
                <div class="mode-desc">
                    Uses the legacy MQTT-based Print Server Windows service.
                    Templates need embedded SQL database connections.
                    Requires full 8-step configuration (OAuth, MQTT, service account, configs).
                </div>
                <span class="mode-tag legacy" id="tagAssetworx">LEGACY</span>
            </div>
            <div class="mode-card" id="modeStandalone" onclick="selectMode('standalone')">
                <div class="mode-icon">⚡</div>
                <div class="mode-title">iDash Standalone (Native API)</div>
                <div class="mode-desc">
                    Uses BarTender SDK directly from IIS — no Print Server needed.
                    Templates use Named Data Sources (<code>lblname</code>, <code>lblsn</code>, etc.).
                    Only needs BarTender, printers, and templates (3 steps).
                </div>
                <span class="mode-tag recommended" id="tagStandalone">MODERN</span>
            </div>
        </div>
        <div id="modeInfo" style="display:none; margin-bottom:20px; padding:12px 18px; border-radius:10px; font-size:13px; line-height:1.6;"></div>
    </div>

    <!-- Overall result banner -->
    <div id="resultBanner" class="result-banner"></div>

    <!-- Summary bar -->
    <div class="summary-bar" id="summaryBar">
        <div class="sum-card pending" data-step="1" onclick="scrollToStep(1)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">BarTender</div>
        </div>
        <div class="sum-card pending" data-step="2" onclick="scrollToStep(2)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">Printers</div>
        </div>
        <div class="sum-card pending" data-step="3" onclick="scrollToStep(3)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">Templates</div>
        </div>
        <div class="sum-card pending" data-step="4" onclick="scrollToStep(4)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">Database</div>
        </div>
        <div class="sum-card pending" data-step="5" onclick="scrollToStep(5)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">Print Server</div>
        </div>
        <div class="sum-card pending" data-step="6" onclick="scrollToStep(6)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">WebClient</div>
        </div>
        <div class="sum-card pending" data-step="7" onclick="scrollToStep(7)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">Service Acct</div>
        </div>
        <div class="sum-card pending" data-step="8" onclick="scrollToStep(8)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">Test Print</div>
        </div>
        <div class="sum-card pending" data-step="9" onclick="scrollToStep(9)">
            <div class="sc-icon">⏳</div>
            <div class="sc-label">web.config</div>
        </div>
    </div>

    <!-- Action bar -->
    <div class="action-bar">
        <button class="btn btn-fill" onclick="runFullScan(); return false;">🔍 Run Full Scan</button>
        <button class="btn btn-success" id="btnFixAll" onclick="fixAll(); return false;" disabled>🔧 Auto-Fix All Issues</button>
        <button class="btn" onclick="exportReport(); return false;">📋 Export Report</button>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  HERO: ONE-CLICK PRINT AUTO-SETUP & TEST                     ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="one-click-card" id="oneClickCard" style="background: linear-gradient(135deg, color-mix(in srgb, var(--accent) 12%, var(--card)), color-mix(in srgb, #10b981 10%, var(--card))); border: 2px solid var(--accent); border-radius: 16px; padding: 24px; margin-bottom: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.06);">
        <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:16px;">
            <div>
                <div style="display:flex; align-items:center; gap:10px;">
                    <span style="font-size:28px;">⚡</span>
                    <h2 style="font-size:20px; font-weight:800; margin:0;">One-Click Print Auto-Setup &amp; Test</h2>
                    <span class="badge badge-ok" style="font-size:12px;">RECOMMENDED</span>
                </div>
                <div style="font-size:13px; color:var(--text); margin-top:6px; line-height:1.6; max-width:680px;">
                    Automatically synchronizes database credentials, registers this station's computer name (clearing any antenna name corruption), configures <code>appsettings.json</code>, purges stuck print queues, verifies the MQTT broker connection, and dispatches a test print.
                </div>
            </div>
            <div style="display:flex; flex-direction:column; gap:8px; min-width:240px;">
                <button type="button" class="btn btn-fill" id="btnOneClickSetup" onclick="runOneClickAutoSetup(true); return false;" style="font-size:14px; padding:12px 20px; display:flex; align-items:center; justify-content:center; gap:8px;">
                    <span>⚡ Run 1-Click Setup &amp; Test</span>
                </button>
                <button type="button" class="btn btn-sm" id="btnOneClickNoPrint" onclick="runOneClickAutoSetup(false); return false;" style="font-size:11px; text-align:center;">
                    🔧 Configure Only (Skip Test Print)
                </button>
            </div>
        </div>
        
        <!-- Live Execution Log Container -->
        <div id="oneClickLog" style="display:none; margin-top:20px; border-top:1px solid var(--line); padding-top:16px;">
            <div style="font-weight:700; font-size:13px; margin-bottom:10px; display:flex; align-items:center; gap:8px;">
                <span class="spinner" id="oneClickSpinner"></span>
                <span id="oneClickStatusText">Running automated setup routine...</span>
            </div>
            <div id="oneClickStepsList" style="display:flex; flex-direction:column; gap:6px;"></div>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 0: Prerequisites Checklist                              ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step expanded" id="step0" data-step="0" style="border-left: 4px solid var(--accent); margin-bottom: 24px;">
        <div class="step-head" onclick="toggleStep(0)">
            <div class="step-num" style="background:color-mix(in srgb, var(--accent) 15%, transparent); color:var(--accent); border-color:var(--accent);">0</div>
            <div class="step-info">
                <div class="step-title">📋 Before You Start — Prerequisites Checklist</div>
                <div class="step-sub">These must be installed/configured <strong>outside of iDash</strong> before the wizard checks below will pass</div>
            </div>
            <div class="step-status" style="font-size:14px; color:var(--accent); font-weight:700;">READ ME</div>
        </div>
        <div class="step-body">
            <div class="why-note" style="border-color: #f59e0b; background: color-mix(in srgb, #f59e0b 8%, transparent);">
                <strong style="color:#f59e0b;">⚠️ This page can auto-fix JSON config files, but it CANNOT install software or create database records.</strong>
                Make sure the following are done first. Check each box as you confirm it.
            </div>

            <div style="font-size:14px; line-height:2.2;">

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>1. BarTender installed with Automation license</strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Run the BarTender installer. Activate with the Automation license key. All 5 services should start automatically.
                            <br>If not installed, Steps 1 and 3 will fail.
                        </div>
                    </div>
                </label>

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>2. AssetWorx Print Server installed</strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Run the <code>AssetWorx Print Server</code> MSI installer. This installs the Windows service at
                            <code>C:\Program Files (x86)\InfinID Technologies\AssetWorx Print Server\</code> and creates the <code>appsettings.json</code> file.
                            <br>If not installed, Steps 5 and 7 will show "Not Found".
                        </div>
                    </div>
                </label>

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>3. Zebra label printer(s) installed in Windows</strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Install the Zebra printer driver and add the printer via <code>Settings → Printers &amp; Scanners</code>.
                            The printer name must <strong>exactly match</strong> the name embedded in the <code>.btw</code> template files
                            (e.g., <code>Std_Small</code>, <code>AW_Metal_IQ350</code>).
                            <br><strong>⚡ IMPORTANT:</strong> Install the printer from an <strong>elevated admin session</strong> or from the same account the Print Server service runs as.
                            Printers installed per-user may not be visible to the service.
                        </div>
                    </div>
                </label>

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>4. Template <code>.btw</code> files copied to <code>C:\assetworx_prints\</code></strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Copy the BarTender template files (e.g., <code>AW_Std_Small.btw</code>, <code>AW_Metal_Large.btw</code>) to
                            <code>C:\assetworx_prints\</code>. These are the same on every system — copy from a working deployment.
                        </div>
                    </div>
                </label>

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>5. Print Client registered in AssetWorx Desktop</strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Open the <code>AssetWorx Desktop</code> application → go to <strong>Tools → Options → Print Clients</strong> tab.
                            <br>Create a print client with a username and password (these are the MQTT credentials).
                            The username/password you set here goes into the <code>printclient</code> database table and must match what's in the
                            Print Server and WebClient <code>appsettings.json</code> files. <strong>The wizard's Auto-Fix will sync these automatically.</strong>
                        </div>
                    </div>
                </label>

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>6. OAuth Client App registered in AssetWorx Desktop</strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Open the <code>AssetWorx Desktop</code> application → go to <strong>Tools → Options → Client Applications</strong> tab.
                            <br>Create a client app with an ID like <code>idash_517_Beckley</code> and grant it the <code>Client Credentials</code> flow.
                            This creates a record in the <code>clientapp</code> table. The Print Server uses these credentials to call the AssetWorx API.
                            <br><strong>The wizard's Auto-Fix will sync the ClientID and Secret from the database into the Print Server config automatically.</strong>
                        </div>
                    </div>
                </label>

                <label style="display:flex; align-items:flex-start; gap:10px; padding:8px 12px; border-radius:8px; cursor:pointer; border:1px solid var(--line); margin-bottom:8px; background:var(--card);">
                    <input type="checkbox" class="prereq-cb" style="margin-top:4px; width:18px; height:18px; accent-color: #10b981;" />
                    <div>
                        <strong>7. Template assignments and site mappings configured in iDash Print Admin</strong>
                        <div style="font-size:12px; color:var(--muted); line-height:1.4; margin-top:2px;">
                            Go to <a href="va_print_admin.aspx" style="color:var(--accent); font-weight:700;">Print Admin</a> → assign templates to sites and link print clients to companies.
                            This populates the <code>template</code> and <code>printclientcompany</code> tables.
                        </div>
                    </div>
                </label>

            </div>

            <div style="margin-top:14px; padding:12px 16px; border-radius:10px; background:color-mix(in srgb, #10b981 8%, transparent); border:1px solid color-mix(in srgb, #10b981 25%, transparent); font-size:13px; line-height:1.6;">
                <strong style="color:#10b981;">✅ Once the above are done:</strong>
                Click <strong>"Run Full Scan"</strong> above. The wizard will validate every configuration value, cross-check them against the database,
                and tell you exactly what's wrong. For JSON config mismatches, click <strong>"Auto-Fix"</strong> and the wizard will fix them and restart the Print Server automatically.
            </div>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 1: BarTender Services                                   ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step1" data-step="1">
        <div class="step-head" onclick="toggleStep(1)">
            <div class="step-num">1</div>
            <div class="step-info">
                <div class="step-title">BarTender Services</div>
                <div class="step-sub">Verify all BarTender Automation services are installed and running</div>
            </div>
            <div class="step-status" id="status1">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> The AssetWorx Print Server uses the BarTender SDK to open <code>.btw</code> templates and execute prints.
                The <strong>BarTender Print Scheduler</strong> service must be running — without it, every print job fails with
                <em>"Bartender Print Result Failure"</em> and no inner exception.
            </div>
            <div id="content1"><span class="spinner"></span> Checking...</div>
            <button class="btn btn-sm" onclick="checkStep('checkBarTenderServices', 1); return false;" style="margin-top:12px">🔄 Re-check</button>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 2: Windows Printers                                     ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step2" data-step="2">
        <div class="step-head" onclick="toggleStep(2)">
            <div class="step-num">2</div>
            <div class="step-info">
                <div class="step-title">Windows Printers</div>
                <div class="step-sub">Check that Zebra/label printers are installed and accessible</div>
            </div>
            <div class="step-status" id="status2">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> Each <code>.btw</code> template has a printer name embedded inside it (e.g., <code>Std_Small</code>).
                If that printer name doesn't <em>exactly match</em> an installed Windows printer, BarTender returns <code>Failure</code>.
                Also, the Print Server service runs as a specific Windows account — if the printer was installed per-user, the service may not see it.
            </div>
            <div id="content2"><span class="spinner"></span> Checking...</div>
            <button class="btn btn-sm" onclick="checkStep('checkPrinters', 2); return false;" style="margin-top:12px">🔄 Re-check</button>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 3: BarTender Templates                                  ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step3" data-step="3">
        <div class="step-head" onclick="toggleStep(3)">
            <div class="step-num">3</div>
            <div class="step-info">
                <div class="step-title">BarTender Template Files</div>
                <div class="step-sub">Verify .btw files exist and match installed printers</div>
            </div>
            <div class="step-status" id="status3">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> The <code>.btw</code> template files in <code>C:\assetworx_prints\</code> define the label layout,
                which printer to use, and a SQL query to fetch data from the database. If the template targets a printer that doesn't exist on this machine,
                prints will fail silently with <em>"Bartender Print Result Failure"</em>.
            </div>

            <!-- Troubleshooting: Example Data Printing -->
            <div style="margin:16px 0; padding:14px 18px; border-radius:10px; border:2px solid #ef4444; background:color-mix(in srgb, #ef4444 6%, transparent);">
                <div style="font-size:14px; font-weight:800; color:#ef4444; margin-bottom:8px;">🚨 Labels printing example/dummy data instead of real data?</div>
                <div style="font-size:13px; line-height:1.7;">
                    <strong>This is a template problem, not a print system problem.</strong> The fix depends on which print engine you're using.
                    There are two methods to get real data onto labels — read both below.
                </div>
            </div>

            <!-- ═══ METHOD A: Named Data Sources (Modern / Preferred) ═══ -->
            <div style="margin:16px 0; padding:14px 18px; border-radius:10px; border:2px solid #10b981; background:color-mix(in srgb, #10b981 5%, transparent);">
                <div style="font-size:14px; font-weight:800; color:#10b981; margin-bottom:8px;">✅ Method A: Named Data Sources (No SQL in template — Preferred)</div>
                <div style="font-size:13px; line-height:1.7;">
                    When printing via the <strong>iDash Native BarTender API</strong> (<code>BarTenderApiHelper.cs</code>) or the
                    <strong>Bypass Spooler</strong> (<code>Run_Bypass_Spooler.ps1</code>), the code directly injects asset data into
                    BarTender Named Data Sources (SubStrings) in memory. <strong>No SQL database connection is needed inside the template.</strong>
                    <br><br>
                    For this to work, each text field in your <code>.btw</code> template must be set to <strong>"Embedded Data"</strong> type
                    and use one of these <strong>exact</strong> SubString names:
                </div>

                <table class="dtable" style="margin-top:12px;">
                    <thead>
                        <tr>
                            <th>SubString Name</th>
                            <th>Maps To</th>
                            <th>Description</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td><code>lblname</code></td><td><code>asset.name</code></td><td>Asset name / EE number (also used for 2D barcode)</td></tr>
                        <tr><td><code>lbldescription</code></td><td><code>asset.description</code></td><td>Asset description line</td></tr>
                        <tr><td><code>lblsn</code></td><td><code>asset.text3</code></td><td>Serial number</td></tr>
                        <tr><td><code>lbleil</code></td><td><code>asset.text8</code></td><td>CMR / EIL number</td></tr>
                        <tr><td><code>lblrfidtag</code></td><td><code>asset.rfidtag</code></td><td>RFID tag EPC hex (for RFID encoding)</td></tr>
                    </tbody>
                </table>

                <div style="margin-top:12px; font-size:13px; line-height:1.7;">
                    <strong>How to set this up in BarTender Designer:</strong>
                    <ol style="padding-left:20px; margin:6px 0; line-height:2;">
                        <li>Open the <code>.btw</code> file in BarTender Designer</li>
                        <li>Double-click each text field on the label</li>
                        <li>Change the Data Source type to <strong>"Embedded Data"</strong></li>
                        <li>In the <strong>Name</strong> field, enter the exact SubString name (e.g., <code>lblname</code>)</li>
                        <li>The "Sample Data" value will appear on screen but will be <strong>replaced at print time</strong> by iDash</li>
                        <li>Make sure there is <strong>NO database connection</strong> configured in the template</li>
                        <li>Save the template to <code>C:\assetworx_prints\</code></li>
                    </ol>
                </div>

                <div style="font-size:12px; color:var(--muted); margin-top:8px; line-height:1.5; padding:8px 12px; background:color-mix(in srgb, #10b981 8%, transparent); border-radius:6px;">
                    <strong>Code reference:</strong> iDash calls <code>sub.Value = matchVal</code> in
                    <a href="file:///c:/inetpub/wwwroot/AssetWorx.WebClient/iDash/App_Code/BarTenderApiHelper.cs" style="color:var(--accent);">BarTenderApiHelper.cs:L189</a>
                    and the Bypass Spooler calls <code>$format.SubStrings.SetSubString("lblname", $job.name)</code> in
                    <a href="file:///c:/inetpub/wwwroot/AssetWorx.WebClient/iDash/printing/Run_Bypass_Spooler.ps1" style="color:var(--accent);">Run_Bypass_Spooler.ps1:L59</a>.
                    Both set <code>UseDatabase = false</code>.
                </div>
            </div>

            <!-- ═══ METHOD B: Embedded SQL Query (Legacy) ═══ -->
            <div style="margin:16px 0; padding:14px 18px; border-radius:10px; border:1px solid #f59e0b; background:color-mix(in srgb, #f59e0b 5%, transparent);">
                <div style="font-size:14px; font-weight:800; color:#f59e0b; margin-bottom:8px;">⚠️ Method B: Embedded SQL Query (Required for Legacy MQTT Print Server)</div>
                <div style="font-size:13px; line-height:1.7;">
                    The <strong>legacy AssetWorx Print Server</strong> (<code>AssetWorx.PrintServer.exe</code> Windows service) does <strong>NOT</strong>
                    call <code>SetSubString()</code>. It simply opens the template and prints it — SubStrings stay as their sample data.
                    <br><br>
                    <strong>When using the legacy Print Server, the template MUST have an embedded SQL database connection</strong> so BarTender
                    can fetch the real asset data itself.
                </div>

                <div style="position:relative; margin-top:12px;">
                    <pre style="background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:14px 16px; font-family:Consolas,monospace; font-size:13px; line-height:1.6; overflow-x:auto; white-space:pre-wrap; margin:0;" id="sqlQuery">SELECT a.name, a.description, a.text3, a.text8, a.rfidtag
FROM printjob p
INNER JOIN asset a ON p.recordid = a.id
WHERE p.completed = 0
ORDER BY p.id ASC</pre>
                    <button onclick="navigator.clipboard.writeText(document.getElementById('sqlQuery').textContent); this.textContent='✅ Copied!'; setTimeout(function(){document.querySelector('#sqlQuery+button').textContent='📋 Copy';},2000); return false;"
                        class="btn btn-sm" style="position:absolute; top:8px; right:8px; font-size:11px; padding:4px 10px;">📋 Copy</button>
                </div>

                <div style="font-size:12px; color:var(--muted); margin-top:10px; line-height:1.5;">
                    <strong>Column → Label mapping:</strong>
                    <code>a.name</code> → Asset name &nbsp;|&nbsp;
                    <code>a.description</code> → Description &nbsp;|&nbsp;
                    <code>a.text3</code> → Serial # &nbsp;|&nbsp;
                    <code>a.text8</code> → CMR/EIL &nbsp;|&nbsp;
                    <code>a.rfidtag</code> → RFID EPC
                </div>

                <!-- BarTender Setup Steps for Legacy -->
                <div style="margin-top:14px; font-size:13px; line-height:1.7;">
                    <strong>How to add the database connection in BarTender:</strong>
                    <ol style="padding-left:20px; margin:6px 0; line-height:2;">
                        <li>Open the <code>.btw</code> template in <strong>BarTender Designer</strong></li>
                        <li>Go to <strong>Database Connection Setup</strong> (<code>File → Database Connection Setup</code>)</li>
                        <li>Click <strong>Add Database Connection...</strong></li>
                        <li>Choose <strong>Microsoft OLE DB Provider for SQL Server</strong></li>
                        <li>Server: <code><strong>.\SQLEXPRESS</strong></code> &nbsp;|&nbsp; Database: <code><strong>AssetWorx</strong></code></li>
                        <li>Auth: <strong>SQL Server Authentication</strong> → <code>assetworxadmin</code> / <code>assetworxadmin</code></li>
                        <li>Click <strong>Test Connection</strong> to verify</li>
                        <li>In the <strong>Query</strong> tab, paste the SQL query above</li>
                        <li>Map each template field to the corresponding query column</li>
                        <li><strong>Save</strong> back to <code>C:\assetworx_prints\</code></li>
                    </ol>
                </div>
            </div>

            <!-- Race Condition Warning -->
            <div class="why-note" style="border-color: #f59e0b; background: color-mix(in srgb, #f59e0b 6%, transparent);">
                <strong style="color:#f59e0b;">⚠️ Known race condition with Method B (<code>WHERE completed=0</code>):</strong>
                <br>The legacy Print Server marks the job as <code>completed = 1</code> in its own processing. If it marks the job completed
                <em>before</em> BarTender runs its embedded query, the query returns zero rows and the label prints example data.
                <strong>This is intermittent</strong> — some labels print correctly, others don't, with no error message.
                <br><br>
                <strong>Method A (Named Data Sources) does not have this problem</strong> because the data is injected directly into memory
                before the print is executed — no database timing dependency.
            </div>

            <div id="content3"><span class="spinner"></span> Checking...</div>
            <button class="btn btn-sm" onclick="checkStep('checkTemplates', 3); return false;" style="margin-top:12px">🔄 Re-check</button>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 4: Database Records                                     ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step4" data-step="4">
        <div class="step-head" onclick="toggleStep(4)">
            <div class="step-num">4</div>
            <div class="step-info">
                <div class="step-title">Database Configuration</div>
                <div class="step-sub">Print clients, API keys, template assignments, site mappings</div>
            </div>
            <div class="step-status" id="status4">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> Four database tables must be in sync:
                <br>• <strong>printclient</strong> — MQTT credentials the Print Server uses to subscribe to print notifications
                <br>• <strong>clientapp</strong> — OAuth client (e.g., <code>idash_517_Beckley</code>) the Print Server uses to authenticate with the AssetWorx API
                <br>• <strong>template</strong> — maps sites to .btw files and print clients
                <br>• <strong>printclientcompany</strong> — links print clients to sites
                <br>If the print client username also exists in the <code>mqttclient</code> table, the MQTT broker will treat it as a generic client instead of a print client, silently blocking print job subscriptions.
            </div>
            <div id="content4"><span class="spinner"></span> Checking...</div>
            <button class="btn btn-sm" onclick="checkStep('checkDatabase', 4); return false;" style="margin-top:12px">🔄 Re-check</button>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 5: Print Server Config                                  ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step5" data-step="5">
        <div class="step-head" onclick="toggleStep(5)">
            <div class="step-num">5</div>
            <div class="step-info">
                <div class="step-title">Print Server appsettings.json</div>
                <div class="step-sub">Auth URLs, OAuth ClientID/Secret, MQTT creds, database connection</div>
            </div>
            <div class="step-status" id="status5">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> The Print Server's <code>appsettings.json</code> at
                <code>C:\Program Files (x86)\InfinID Technologies\AssetWorx Print Server\</code> controls how it authenticates and communicates.
                <br><br>
                <strong>Common failures:</strong>
                <br>• <strong>AuthServerUrl empty</strong> → Print Server can't get an OAuth token → can't call the API
                <br>• <strong>ClientID wrong</strong> (e.g., still set to <code>AlarmMonitoringService</code>) → authentication fails
                <br>• <strong>ClientSecret doesn't match</strong> the <code>clientapp</code> table → token rejected
                <br>• <strong>PrintClient creds don't match</strong> the <code>printclient</code> table → MQTT subscription fails
            </div>
            <div id="content5"><span class="spinner"></span> Checking...</div>
            <div style="margin-top:12px; display:flex; gap:8px;">
                <button class="btn btn-sm" onclick="checkStep('checkPrintServerConfig', 5); return false;">🔄 Re-check</button>
                <button class="btn btn-sm btn-success" id="btnFixPS" onclick="fixPrintServer(); return false;" style="display:none">🔧 Auto-Fix</button>
            </div>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 6: WebClient Config                                     ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step6" data-step="6">
        <div class="step-head" onclick="toggleStep(6)">
            <div class="step-num">6</div>
            <div class="step-info">
                <div class="step-title">WebClient appsettings.json</div>
                <div class="step-sub">UseForPrinting, MQTT server, print client credentials</div>
            </div>
            <div class="step-status" id="status6">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> The WebClient (iDash) uses its own <code>appsettings.json</code> to publish print notifications via MQTT.
                <br>• <strong>UseForPrinting = false</strong> → print buttons are hidden or non-functional
                <br>• <strong>PrintClient creds wrong</strong> → MQTT messages don't reach the Print Server
                <br>• <strong>MqttServer wrong</strong> → messages go to the wrong broker
            </div>
            <div id="content6"><span class="spinner"></span> Checking...</div>
            <div style="margin-top:12px; display:flex; gap:8px;">
                <button class="btn btn-sm" onclick="checkStep('checkWebClientConfig', 6); return false;">🔄 Re-check</button>
                <button class="btn btn-sm btn-success" id="btnFixWC" onclick="fixWebClient(); return false;" style="display:none">🔧 Auto-Fix</button>
            </div>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 7: Service Account                                      ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step7" data-step="7">
        <div class="step-head" onclick="toggleStep(7)">
            <div class="step-num">7</div>
            <div class="step-info">
                <div class="step-title">Print Server Service Account</div>
                <div class="step-sub">Check what Windows account the service runs under</div>
            </div>
            <div class="step-status" id="status7">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> The AssetWorx Print Server runs as a Windows service. If it runs as <code>LocalSystem</code>,
                it operates in a different security context than your logged-in user.
                <br><br>
                <strong>Impact:</strong> Printers installed from your user session may not be visible to <code>LocalSystem</code>.
                BarTender will return <em>"Print Result Failure"</em> because it literally can't find the printer.
                <br><br>
                <strong>Fix:</strong> Open <code>Services</code> → find <code>AssetWorx Print Server</code> → <code>Properties</code> → <code>Log On</code> tab
                → change to <strong>"This account"</strong> and enter your user credentials. Or, reinstall printers from an elevated admin session.
            </div>
            <div id="content7"><span class="spinner"></span> Checking...</div>
            <button class="btn btn-sm" onclick="checkStep('checkServiceAccount', 7); return false;" style="margin-top:12px">🔄 Re-check</button>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 8: Test Print                                           ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step8" data-step="8">
        <div class="step-head" onclick="toggleStep(8)">
            <div class="step-num">8</div>
            <div class="step-info">
                <div class="step-title">Clear Stale Jobs & Test Print</div>
                <div class="step-sub">End-to-end test: iDash → DB → Print Server → BarTender → Printer</div>
            </div>
            <div class="step-status" id="status8">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> This is the final proof. A test print exercises the <em>entire chain</em>:
                <br>1. iDash submits a print job to the <code>printjob</code> table
                <br>2. MQTT notification goes to the Print Server
                <br>3. Print Server authenticates via OAuth, fetches the job via API
                <br>4. Print Server opens the <code>.btw</code> template in BarTender
                <br>5. BarTender queries the database, applies data to the label, and sends to the printer
                <br><br>
                If there are stale <code>completed=0</code> jobs in the table, they can cause duplicate prints or interfere with new jobs.
                Clear them first.
            </div>
            <div id="content8"><span class="spinner"></span> Checking stale jobs...</div>
            <div style="margin-top:12px; display:flex; gap:8px; flex-wrap:wrap;">
                <button class="btn btn-sm btn-danger" id="btnClear" onclick="clearStaleJobs(); return false;">🧹 Clear Stale Jobs</button>
                <button class="btn btn-sm btn-fill" id="btnTest" onclick="testPrint(); return false;">🖨️ Send Test Print</button>
                <button class="btn btn-sm" onclick="checkStep('checkStaleJobs', 8); return false;">🔄 Re-check</button>
            </div>
            <div id="testResult"></div>
        </div>
    </div>

    <!-- ╔═══════════════════════════════════════════════════════════════╗ -->
    <!-- ║  STEP 9: web.config                                          ║ -->
    <!-- ╚═══════════════════════════════════════════════════════════════╝ -->
    <div class="step" id="step9" data-step="9">
        <div class="step-head" onclick="toggleStep(9)">
            <div class="step-num">9</div>
            <div class="step-info">
                <div class="step-title">web.config — View / Edit / Rebuild</div>
                <div class="step-sub">Database connection, OAuth, SMTP, structural integrity</div>
            </div>
            <div class="step-status" id="status9">⏳</div>
        </div>
        <div class="step-body">
            <div class="why-note">
                <strong>Why this matters:</strong> The <code>web.config</code> is the <em>master config file</em> for iDash.
                If someone corrupts it, the entire site crashes. If you copy iDash to a new system, you need
                to update the connection string and OAuth credentials.
                <br><br>
                <strong>This step lets you:</strong>
                <br>• <strong>View</strong> every setting with validation
                <br>• <strong>Edit</strong> system-specific values (DB, OAuth, SMTP) inline
                <br>• <strong>Rebuild from scratch</strong> if the file is corrupted — generates a known-good template with your values
                <br>• <strong>Auto-backup</strong> before any write (<code>web.config.bak.timestamp</code>)
            </div>
            <div id="content9"><span class="spinner"></span> Checking...</div>
            <div style="margin-top:12px; display:flex; gap:8px; flex-wrap:wrap;">
                <button class="btn btn-sm" onclick="checkStep('checkWebConfig', 9); return false;">🔄 Re-check</button>
                <button class="btn btn-sm btn-success" id="btnSaveWC" onclick="saveWebConfigChanges(); return false;" style="display:none">💾 Save Changes</button>
                <button class="btn btn-sm btn-danger" id="btnRebuildWC" onclick="rebuildWebConfig(); return false;">🔨 Rebuild from Template</button>
            </div>
        </div>
    </div>

</div>
</form>

<script>
// ===================================================================
// Mode state
// ===================================================================
window.wizardMode = null; // 'assetworx' or 'standalone'

// Steps that only apply to AssetWorx mode (hidden in standalone)
var ASSETWORX_ONLY_STEPS = [4, 5, 6, 7];

// Check for web.config save/rebuild log from before IIS recycle
(function() {
    // Also clean up localStorage flag if present
    try { localStorage.removeItem('idash_wc_action'); } catch(e) {}

    // Check server-side log after DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        fetch('va_print_setup_wizard.aspx?action=api&cmd=checkSaveLog')
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (!data.hasLog) return;

                var isSuccess = data.status === 'SUCCESS';
                var actionLabel = data.action === 'REBUILD' ? 'REBUILT' : 'SAVED';
                var banner = document.createElement('div');
                banner.id = 'saveLogBanner';
                banner.style.cssText = 'position:fixed; top:0; left:0; right:0; z-index:9999; padding:16px 24px; text-align:center; font-size:14px; font-weight:700; box-shadow:0 4px 20px rgba(0,0,0,.2); cursor:pointer;' +
                    (isSuccess ? 'background:linear-gradient(135deg, #10b981, #059669); color:#fff;' : 'background:linear-gradient(135deg, #ef4444, #dc2626); color:#fff;');

                var html = '<div style="max-width:800px; margin:0 auto;">';
                html += '<div style="font-size:16px; margin-bottom:6px;">' + (isSuccess ? '\u2705' : '\u274c') + ' web.config ' + actionLabel + ' ' + (isSuccess ? 'SUCCESSFULLY' : 'FAILED') + '</div>';
                html += '<div style="font-size:12px; opacity:0.9;">' + data.time;
                if (data.backup) html += ' \u2022 Backup: ' + data.backup;
                html += '</div>';

                if (data.details && data.details.length > 0) {
                    html += '<div style="font-size:12px; margin-top:6px; opacity:0.85;">';
                    data.details.forEach(function(d) { html += d + ' &nbsp; '; });
                    html += '</div>';
                }

                html += '<div style="font-size:11px; margin-top:8px; opacity:0.7;">Click to dismiss</div>';
                html += '</div>';
                banner.innerHTML = html;
                banner.onclick = function() { banner.style.transition = 'all 0.3s'; banner.style.transform = 'translateY(-100%)'; setTimeout(function() { banner.remove(); }, 300); };
                document.body.appendChild(banner);

                // Auto-dismiss after 15 seconds
                setTimeout(function() { if (document.getElementById('saveLogBanner')) banner.onclick(); }, 15000);
            })
            .catch(function() { /* ignore - no log or not logged in yet */ });
    });
})();

// ===================================================================
// API helper
// ===================================================================
function api(cmd, body) {
    var opts = { method: body ? 'POST' : 'GET', headers: { 'Content-Type': 'application/json' } };
    if (body) opts.body = JSON.stringify(body);
    return fetch('va_print_setup_wizard.aspx?action=api&cmd=' + cmd, opts).then(function(r) {
        var ct = r.headers.get('content-type') || '';
        if (ct.indexOf('application/json') >= 0) {
            return r.json();
        }
        // IIS returned HTML (login page or error page after app pool recycle)
        return r.text().then(function(html) {
            if (html.indexOf('TxtUserGate') > -1 || html.indexOf('Sign In') > -1) {
                // Session expired — page needs reload to re-authenticate
                throw new Error('SESSION_EXPIRED');
            }
            throw new Error('Server returned HTML instead of JSON (IIS may be restarting)');
        });
    });
}

// ===================================================================
// Mode selection
// ===================================================================
function selectMode(mode) {
    window.wizardMode = mode;

    // Update cards
    document.getElementById('modeAssetworx').className = 'mode-card' + (mode === 'assetworx' ? ' active' : '');
    document.getElementById('modeStandalone').className = 'mode-card' + (mode === 'standalone' ? ' active' : '');

    // Show info bar
    var info = document.getElementById('modeInfo');
    if (mode === 'assetworx') {
        info.style.display = 'block';
        info.style.background = 'color-mix(in srgb, #f59e0b 8%, transparent)';
        info.style.border = '1px solid color-mix(in srgb, #f59e0b 30%, transparent)';
        info.innerHTML = '<strong style="color:#f59e0b;">🏢 AssetWorx Mode</strong> — All 8 steps active. Templates need embedded SQL queries. Print Server, MQTT, OAuth, and service account will be validated.';
    } else {
        info.style.display = 'block';
        info.style.background = 'color-mix(in srgb, #10b981 8%, transparent)';
        info.style.border = '1px solid color-mix(in srgb, #10b981 30%, transparent)';
        info.innerHTML = '<strong style="color:#10b981;">⚡ Standalone Mode</strong> — Only 3 steps needed. Templates use Named Data Sources (<code>lblname</code>, <code>lblsn</code>, etc.). No Print Server, MQTT, or OAuth required.';
    }

    applyMode(mode);
    runFullScan();
}

function applyMode(mode) {
    // Show/hide steps
    ASSETWORX_ONLY_STEPS.forEach(function(n) {
        var stepEl = document.getElementById('step' + n);
        if (stepEl) {
            if (mode === 'standalone') {
                stepEl.classList.add('hidden-mode');
            } else {
                stepEl.classList.remove('hidden-mode');
            }
        }

        // Update summary card
        var cards = document.querySelectorAll('.sum-card[data-step="' + n + '"]');
        cards.forEach(function(c) {
            if (mode === 'standalone') {
                c.className = 'sum-card na';
                c.querySelector('.sc-icon').textContent = 'N/A';
                c.onclick = null;
            } else {
                c.className = 'sum-card pending';
                c.querySelector('.sc-icon').textContent = '⏳';
                c.onclick = function() { scrollToStep(n); };
            }
        });
    });

    // Adapt Step 0 prerequisites
    adaptPrerequisites(mode);

    // Adapt Step 8 description
    var step8Sub = document.querySelector('#step8 .step-sub');
    if (step8Sub) {
        step8Sub.textContent = mode === 'standalone'
            ? 'Test: iDash → BarTender API → Printer (native)'
            : 'End-to-end test: iDash → DB → Print Server → BarTender → Printer';
    }
}

function adaptPrerequisites(mode) {
    // Hide/show prerequisite items based on mode
    var prereqs = document.querySelectorAll('#step0 label');
    // Items 2 (Print Server), 5 (Print Client MQTT), 6 (OAuth Client) are AssetWorx-only
    var assetworxOnlyIndexes = [1, 4, 5]; // 0-indexed

    prereqs.forEach(function(label, idx) {
        if (assetworxOnlyIndexes.indexOf(idx) >= 0) {
            label.style.display = mode === 'standalone' ? 'none' : '';
        }
    });
}

// ===================================================================
// Step toggling
// ===================================================================
function toggleStep(n) {
    var el = document.getElementById('step' + n);
    el.classList.toggle('expanded');
}
function scrollToStep(n) {
    var el = document.getElementById('step' + n);
    el.classList.add('expanded');
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// ===================================================================
// Update summary card
// ===================================================================
function updateSummary(stepNum, status) {
    // Don't update N/A steps
    if (window.wizardMode === 'standalone' && ASSETWORX_ONLY_STEPS.indexOf(stepNum) >= 0) return;

    var cards = document.querySelectorAll('.sum-card[data-step="' + stepNum + '"]');
    cards.forEach(function(c) {
        c.className = 'sum-card ' + status;
        c.querySelector('.sc-icon').textContent = status === 'pass' ? '✅' : status === 'fail' ? '❌' : status === 'warn' ? '⚠️' : '⏳';
    });
    var stepEl = document.getElementById('step' + stepNum);
    stepEl.className = 'step ' + status + (stepEl.classList.contains('expanded') ? ' expanded' : '');
    document.getElementById('status' + stepNum).textContent = status === 'pass' ? '✅' : status === 'fail' ? '❌' : status === 'warn' ? '⚠️' : '⏳';
}

// ===================================================================
// Individual step checks
// ===================================================================
function checkStep(cmd, stepNum) {
    var el = document.getElementById('content' + stepNum);
    el.innerHTML = '<span class="spinner"></span> Checking...';

    api(cmd).then(function(data) {
        if (data.error) {
            updateSummary(stepNum, 'fail');
            el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>' + escHtml(data.error) + '</div>';
            return;
        }

        var status = data.pass ? 'pass' : (data.issues && data.issues.length > 0 ? 'fail' : 'warn');
        updateSummary(stepNum, status);

        switch (stepNum) {
            case 1: renderBarTenderServices(el, data); break;
            case 2: renderPrinters(el, data); break;
            case 3: renderTemplates(el, data); break;
            case 4: renderDatabase(el, data); break;
            case 5: renderPrintServerConfig(el, data); break;
            case 6: renderWebClientConfig(el, data); break;
            case 7: renderServiceAccount(el, data); break;
            case 8: renderStaleJobs(el, data); break;
            case 9: renderWebConfig(el, data); break;
        }
    }).catch(function(err) {
        updateSummary(stepNum, 'fail');
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>Request failed: ' + escHtml(err.message) + '</div>';
    });
}

// ===================================================================
// Renderers
// ===================================================================
function renderBarTenderServices(el, data) {
    var html = '<table class="dtable"><tr><th>Service</th><th>Status</th></tr>';
    (data.services || []).forEach(function(s) {
        html += '<tr><td>' + escHtml(s.name) + '</td><td>' +
            (s.running ? '<span class="badge badge-ok">Running</span>' :
             '<span class="badge badge-err">' + escHtml(s.status) + '</span>') + '</td></tr>';
    });
    html += '</table>';
    el.innerHTML = html;
}

function renderPrinters(el, data) {
    var html = '<table class="dtable"><tr><th>Printer</th><th>Port</th><th>Driver</th><th>Status</th><th>Label?</th></tr>';
    (data.printers || []).forEach(function(p) {
        html += '<tr><td><strong>' + escHtml(p.name) + '</strong></td><td>' + escHtml(p.port) + '</td><td>' + escHtml(p.driver) + '</td><td>' +
            escHtml(p.status) + '</td><td>' + (p.isLabelPrinter ? '<span class="badge badge-ok">Yes</span>' : '<span class="badge badge-info">No</span>') + '</td></tr>';
    });
    html += '</table>';
    if (!data.pass) html += '<div class="issue-item warn"><span class="issue-icon">⚠️</span>No Zebra/label printers detected. Make sure your printer drivers are installed.</div>';
    el.innerHTML = html;
}

function renderTemplates(el, data) {
    if (!data.folderExists) {
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>Folder <code>' + escHtml(data.folderPath) + '</code> does not exist. Create it and copy your .btw template files there.</div>';
        return;
    }
    if (data.templates.length === 0) {
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>No .btw files found in <code>' + escHtml(data.folderPath) + '</code>.</div>';
        return;
    }
    var html = '<table class="dtable"><tr><th>Template</th><th>Size</th><th>Embedded Printer</th><th>Printer Match?</th><th>Has DB Query?</th><th>Modified</th></tr>';
    (data.templates || []).forEach(function(t) {
        var printerClass = t.printerExists ? 'badge-ok' : (t.embeddedPrinter ? 'badge-err' : 'badge-warn');
        var printerText = t.printerExists ? '✅ Matched' : (t.embeddedPrinter ? '❌ Not Found' : '⚠️ Unknown');

        // Mode-aware DB query column
        var dbBadge;
        if (window.wizardMode === 'standalone') {
            // Standalone: DB connection = BAD (should not have one)
            dbBadge = t.hasDbConnection
                ? '<span class="badge badge-err">❌ Remove It</span>'
                : '<span class="badge badge-ok">✅ Clean</span>';
        } else {
            // AssetWorx: DB connection = expected
            dbBadge = t.hasDbConnection
                ? '<span class="badge badge-ok">✅ Yes</span>'
                : '<span class="badge badge-err">❌ Missing</span>';
        }

        html += '<tr><td><strong>' + escHtml(t.fileName) + '</strong></td><td>' + t.sizeKB + ' KB</td>' +
            '<td><code>' + escHtml(t.embeddedPrinter || '(unknown)') + '</code></td>' +
            '<td><span class="badge ' + printerClass + '">' + printerText + '</span></td>' +
            '<td>' + dbBadge + '</td>' +
            '<td>' + escHtml(t.lastModified) + '</td></tr>';
    });
    html += '</table>';

    // Mode-specific warnings
    var dbTemplates = data.templates.filter(function(t) { return t.hasDbConnection; });
    var noDbTemplates = data.templates.filter(function(t) { return !t.hasDbConnection; });

    if (window.wizardMode === 'standalone') {
        if (dbTemplates.length > 0) {
            html += '<div class="issue-item"><span class="issue-icon">❌</span><strong>Templates with embedded SQL detected — remove them!</strong> ' +
                'In Standalone mode, iDash injects data via Named Data Sources (SubStrings). ' +
                'Open each template in BarTender Designer, go to Database Connection Setup, and delete the SQL connection. ' +
                'Then ensure each field uses Embedded Data with the correct <code>lbl*</code> SubString name.</div>';
        }
        if (noDbTemplates.length > 0) {
            html += '<div class="issue-item pass" style="color:#10b981;"><span class="issue-icon">✅</span>' +
                '<strong>Templates are clean (no SQL)</strong> — make sure each field uses Named Data Sources: ' +
                '<code>lblname</code>, <code>lbldescription</code>, <code>lblsn</code>, <code>lbleil</code>, <code>lblrfidtag</code>.</div>';
        }
    } else {
        // AssetWorx mode
        if (noDbTemplates.length > 0) {
            html += '<div class="issue-item"><span class="issue-icon">❌</span><strong>Templates without SQL database connection:</strong> ' +
                noDbTemplates.map(function(t) { return '<code>' + escHtml(t.fileName) + '</code>'; }).join(', ') +
                ' — the legacy Print Server cannot inject SubStrings. These templates MUST have an embedded SQL query or labels will print example data. See Method B above.</div>';
        }
        if (dbTemplates.length > 0) {
            html += '<div class="issue-item pass" style="color:#10b981;"><span class="issue-icon">✅</span>' +
                '<strong>' + dbTemplates.length + ' template(s) have embedded SQL queries</strong> — correct for AssetWorx mode.</div>';
        }
    }

    var noMatch = data.templates.filter(function(t) { return t.embeddedPrinter && !t.printerExists; });
    if (noMatch.length > 0) {
        html += '<div class="issue-item"><span class="issue-icon">❌</span><strong>Printer mismatch:</strong> ' +
            noMatch.map(function(t) { return '<code>' + escHtml(t.fileName) + '</code> targets <code>' + escHtml(t.embeddedPrinter) + '</code>'; }).join(', ') +
            ' — these printers are not installed on this machine.</div>';
    }

    el.innerHTML = html;
}

function renderDatabase(el, data) {
    var html = '';

    // Print Clients
    html += '<h4 style="color:var(--accent); margin:8px 0">Print Clients (Printers)</h4>';
    if (data.printClients && data.printClients.length > 0) {
        html += '<table class="dtable"><tr><th>ID</th><th>Name</th><th>Username</th><th>Station Machine Name</th><th>Status</th></tr>';
        var hasMachineIssue = false;
        data.printClients.forEach(function(pc) {
            var machBadge = '';
            if (pc.isCorrupted) {
                machBadge = '<span class="badge badge-err">⚠️ Antenna ID (Corrupted)</span>';
                hasMachineIssue = true;
            } else if (pc.matchesLocal) {
                machBadge = '<span class="badge badge-ok">✅ Matches (' + escHtml(data.localMachineName) + ')</span>';
            } else {
                machBadge = '<span class="badge badge-warn">⚠️ Mismatch (This PC is ' + escHtml(data.localMachineName) + ')</span>';
                hasMachineIssue = true;
            }
            html += '<tr><td>' + pc.id + '</td><td>' + escHtml(pc.name) + '</td><td><code>' + escHtml(pc.username) + '</code></td><td><code>' + escHtml(pc.machineName || '(empty)') + '</code></td><td>' + machBadge + '</td></tr>';
        });
        html += '</table>';
        if (hasMachineIssue) {
            html += '<div style="margin:10px 0;"><button type="button" class="btn btn-sm btn-success" onclick="fixMachineName(); return false;">🔧 Set Machine Name to ' + escHtml(data.localMachineName) + ' (1-Click Fix)</button></div>';
        }
    } else {
        html += '<div class="issue-item"><span class="issue-icon">❌</span>No print clients in database.</div>';
    }

    // Client Apps
    html += '<h4 style="color:var(--accent); margin:12px 0 8px">API Clients (OAuth)</h4>';
    if (data.clientApps && data.clientApps.length > 0) {
        html += '<table class="dtable"><tr><th>ID</th><th>Client ID</th><th>Company ID</th></tr>';
        data.clientApps.forEach(function(ca) {
            html += '<tr><td>' + ca.id + '</td><td><code>' + escHtml(ca.clientId) + '</code></td><td>' + ca.companyId + '</td></tr>';
        });
        html += '</table>';
    } else {
        html += '<div class="issue-item"><span class="issue-icon">❌</span>No iDash API clients (clientapp) in database. The Print Server can\'t authenticate.</div>';
    }

    // Templates
    html += '<h4 style="color:var(--accent); margin:12px 0 8px">Template Assignments</h4>';
    if (data.templates && data.templates.length > 0) {
        html += '<table class="dtable"><tr><th>ID</th><th>Name</th><th>Site</th><th>File</th><th>Method</th></tr>';
        data.templates.forEach(function(t) {
            html += '<tr><td>' + t.id + '</td><td>' + escHtml(t.name) + '</td><td>' + escHtml(t.siteName) + '</td><td><code>' + escHtml(t.fileName) + '</code></td><td>' + escHtml(t.printMethod) + '</td></tr>';
        });
        html += '</table>';
    } else {
        html += '<div class="issue-item"><span class="issue-icon">❌</span>No print templates assigned to any sites.</div>';
    }

    // Site mappings
    html += '<h4 style="color:var(--accent); margin:12px 0 8px">Print Client → Site Mappings</h4>';
    if (data.printClientCompany && data.printClientCompany.length > 0) {
        html += '<table class="dtable"><tr><th>Print Client ID</th><th>Site</th></tr>';
        data.printClientCompany.forEach(function(m) {
            html += '<tr><td>' + m.printClientId + '</td><td>' + escHtml(m.siteName) + '</td></tr>';
        });
        html += '</table>';
    } else {
        html += '<div class="issue-item warn"><span class="issue-icon">⚠️</span>No print client → site mappings.</div>';
    }

    // Issues
    if (data.issues && data.issues.length > 0) {
        html += '<div class="issue-list">';
        data.issues.forEach(function(iss) {
            var cls = iss.indexOf('CRITICAL') >= 0 ? '' : 'warn';
            html += '<div class="issue-item ' + cls + '"><span class="issue-icon">' + (cls ? '⚠️' : '❌') + '</span>' + escHtml(iss) + '</div>';
        });
        html += '</div>';
    }

    el.innerHTML = html;
}

function renderPrintServerConfig(el, data) {
    if (!data.exists) {
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>Print Server appsettings.json not found at <code>' + escHtml(data.path) + '</code>. Is the Print Server installed?</div>';
        return;
    }

    var cfg = data.config || {};
    var html = '<div class="cfg-grid">';

    var fields = [
        { key: 'AuthServerUrl', label: 'Auth Server URL', hint: 'Must be http://localhost for local API', expected: 'http://localhost' },
        { key: 'AuthenticationServer', label: 'Authentication Server', hint: 'Same as AuthServerUrl', expected: 'http://localhost' },
        { key: 'BaseUrl', label: 'ServiceOptions.BaseUrl', hint: 'API base endpoint', expected: 'http://localhost' },
        { key: 'ClientID', label: 'ServiceOptions.ClientID', hint: 'Must match clientapp in DB' + (data.expectedClientID ? ' → ' + data.expectedClientID : '') },
        { key: 'ClientSecret_masked', label: 'ServiceOptions.ClientSecret', hint: 'Must match clientapp secret' },
        { key: 'PrintClientUsername', label: 'PrintClientUsername', hint: 'Must match printclient table' },
        { key: 'PrintClientPassword_masked', label: 'PrintClientPassword', hint: 'Must match printclient password' },
        { key: 'MqttServer', label: 'MQTT Server', hint: 'Usually localhost' },
        { key: 'MqttServerPort', label: 'MQTT Port', hint: 'Usually 8883' },
        { key: 'UseForPrinting', label: 'UseForPrinting', hint: 'Must be true', expected: true },
        { key: 'DbHostname', label: 'DB Hostname', hint: 'SQL Server instance' }
    ];

    fields.forEach(function(f) {
        var val = cfg[f.key];
        var display = val === true ? 'true' : val === false ? 'false' : (val || '(empty)');
        var isOk = true;
        if (f.expected !== undefined) isOk = (val === f.expected || String(val) === String(f.expected));
        else if (f.key === 'ClientID' && data.expectedClientID) isOk = (val === data.expectedClientID);
        else if (!val && val !== 0) isOk = false;

        html += '<div class="cfg-label">' + f.label + '<small>' + f.hint + '</small></div>';
        html += '<div class="cfg-value ' + (isOk ? 'ok' : 'bad') + '">' + escHtml(display) + '</div>';
        html += '<div class="cfg-status">' + (isOk ? '✅' : '❌') + '</div>';
    });
    html += '</div>';

    // Issues
    if (data.issues && data.issues.length > 0) {
        html += '<div class="issue-list">';
        data.issues.forEach(function(iss) {
            html += '<div class="issue-item"><span class="issue-icon">❌</span>' + escHtml(iss) + '</div>';
        });
        html += '</div>';
        document.getElementById('btnFixPS').style.display = '';
    } else {
        document.getElementById('btnFixPS').style.display = 'none';
    }

    el.innerHTML = html;
}

function renderWebClientConfig(el, data) {
    if (!data.exists) {
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>WebClient appsettings.json not found at <code>' + escHtml(data.path) + '</code>.</div>';
        return;
    }

    var cfg = data.config || {};
    var html = '<div class="cfg-grid">';

    var fields = [
        { key: 'UseForPrinting', label: 'UseForPrinting', hint: 'Must be true to enable printing', expected: true },
        { key: 'MqttServer', label: 'MQTT Server', hint: 'Broker hostname' },
        { key: 'MqttServerPort', label: 'MQTT Port', hint: 'Usually 8883' },
        { key: 'PrintClientUsername', label: 'PrintClientUsername', hint: 'Must match printclient in DB' },
        { key: 'PrintClientPassword_masked', label: 'PrintClientPassword', hint: 'Must match printclient password' }
    ];

    fields.forEach(function(f) {
        var val = cfg[f.key];
        var display = val === true ? 'true' : val === false ? 'false' : (val || '(empty)');
        var isOk = true;
        if (f.expected !== undefined) isOk = (val === f.expected || String(val) === String(f.expected));
        else if (!val && val !== 0) isOk = false;

        html += '<div class="cfg-label">' + f.label + '<small>' + f.hint + '</small></div>';
        html += '<div class="cfg-value ' + (isOk ? 'ok' : 'bad') + '">' + escHtml(display) + '</div>';
        html += '<div class="cfg-status">' + (isOk ? '✅' : '❌') + '</div>';
    });
    html += '</div>';

    if (data.issues && data.issues.length > 0) {
        html += '<div class="issue-list">';
        data.issues.forEach(function(iss) {
            html += '<div class="issue-item"><span class="issue-icon">❌</span>' + escHtml(iss) + '</div>';
        });
        html += '</div>';
        document.getElementById('btnFixWC').style.display = '';
    } else {
        document.getElementById('btnFixWC').style.display = 'none';
    }

    el.innerHTML = html;
}

function renderServiceAccount(el, data) {
    var html = '';
    if (data.serviceName) {
        html += '<table class="dtable"><tr><th>Property</th><th>Value</th></tr>';
        html += '<tr><td>Service Name</td><td><strong>' + escHtml(data.serviceName) + '</strong></td></tr>';
        html += '<tr><td>Log On As</td><td><code>' + escHtml(data.serviceAccount) + '</code></td></tr>';
        html += '<tr><td>State</td><td>' + (data.serviceState === 'Running' ? '<span class="badge badge-ok">Running</span>' : '<span class="badge badge-err">' + escHtml(data.serviceState) + '</span>') + '</td></tr>';
        html += '</table>';
    }
    if (data.issues && data.issues.length > 0) {
        html += '<div class="issue-list">';
        data.issues.forEach(function(iss) {
            var cls = iss.indexOf('LocalSystem') >= 0 ? 'warn' : '';
            html += '<div class="issue-item ' + cls + '"><span class="issue-icon">' + (cls ? '⚠️' : '❌') + '</span>' + escHtml(iss) + '</div>';
        });
        html += '</div>';
    }
    el.innerHTML = html;
}

function renderStaleJobs(el, data) {
    var html = '';
    if (data.staleCount > 0) {
        html = '<div class="issue-item warn"><span class="issue-icon">⚠️</span><strong>' + data.staleCount + '</strong> pending print job(s) with <code>completed=0</code>. ' +
            'These may be stale from failed print attempts. Clear them before testing.</div>';
    } else {
        html = '<div style="color:#10b981; font-weight:700; font-size:14px;">✅ No stale print jobs — queue is clean.</div>';
    }
    el.innerHTML = html;
}

function renderWebConfig(el, data) {
    if (!data.exists) {
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>web.config not found at <code>' + escHtml(data.path) + '</code>. Use "Rebuild from Template" to create one.</div>';
        document.getElementById('btnSaveWC').style.display = 'none';
        document.getElementById('btnRebuildWC').style.display = '';
        return;
    }

    if (data.xmlError) {
        el.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span><strong>CRITICAL: web.config is corrupt XML!</strong><br>' + escHtml(data.xmlError) + '<br><br>Use "Rebuild from Template" below to generate a new one.</div>';
        document.getElementById('btnSaveWC').style.display = 'none';
        document.getElementById('btnRebuildWC').style.display = '';
        return;
    }

    var html = '';

    // === Database Connection ===
    html += '<div class="cfg-edit-group">';
    html += '<h4>🗄️ Database Connection</h4>';
    html += '<div class="cfg-edit-row"><label>Server<small>SQL Server instance name</small></label><input type="text" id="wcDbServer" value="' + escHtml(data.dbServer) + '" /></div>';
    html += '<div class="cfg-edit-row"><label>Database<small>Database name</small></label><input type="text" id="wcDbName" value="' + escHtml(data.dbName) + '" /></div>';
    html += '<div class="cfg-edit-row"><label>User ID<small>SQL login username</small></label><input type="text" id="wcDbUser" value="' + escHtml(data.dbUser) + '" /></div>';
    html += '<div class="cfg-edit-row"><label>Password<small>SQL login password</small></label><input type="password" id="wcDbPass" value="' + escHtml(data.dbPass) + '" /></div>';
    html += '</div>';

    // === OAuth / API ===
    var s = data.appSettings || {};
    html += '<div class="cfg-edit-group">';
    html += '<h4>🔐 OAuth / API Settings</h4>';
    html += '<div class="cfg-edit-row"><label>API Base URL<small>Usually http://localhost</small></label><input type="text" id="wcApiBase" value="' + escHtml(s.AssetWorx_ApiBase || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>Token URL<small>OAuth token endpoint</small></label><input type="text" id="wcTokenUrl" value="' + escHtml(s.AssetWorx_TokenUrl || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>Client ID<small>Must match clientapp table</small></label><input type="text" id="wcClientId" value="' + escHtml(s.AssetWorx_ClientId || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>Client Secret<small>Must match clientapp secret</small></label><input type="password" id="wcClientSecret" value="' + escHtml(s.AssetWorx_ClientSecret || '') + '" /></div>';
    html += '</div>';

    // === SMTP / Email ===
    html += '<div class="cfg-edit-group">';
    html += '<h4>📧 SMTP / Email Settings</h4>';
    html += '<div class="cfg-edit-row"><label>SMTP Host<small>e.g. smtp.office365.com</small></label><input type="text" id="wcSmtpHost" value="' + escHtml(s.SMTP_Host || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>SMTP Port<small>Usually 587 or 465</small></label><input type="text" id="wcSmtpPort" value="' + escHtml(s.SMTP_Port || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>SMTP User<small>Login for mail server</small></label><input type="text" id="wcSmtpUser" value="' + escHtml(s.SMTP_User || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>SMTP Password<small>Password for mail server</small></label><input type="password" id="wcSmtpPassword" value="' + escHtml(s.SMTP_Password || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>From Email<small>Sender address</small></label><input type="text" id="wcSmtpFrom" value="' + escHtml(s.SMTP_FromEmail || '') + '" /></div>';
    html += '<div class="cfg-edit-row"><label>Email Recipients<small>Alert recipients (comma-separated)</small></label><input type="text" id="wcEmailRecipients" value="' + escHtml(s.EmailRecipients || '') + '" /></div>';
    html += '</div>';

    // === Structural Integrity ===
    html += '<div class="cfg-edit-group">';
    html += '<h4>🏗️ Structural Integrity</h4>';
    var struct = data.structure || {};
    var checks = [
        { key: 'httpRuntime', label: 'httpRuntime' },
        { key: 'compilation', label: 'compilation' },
        { key: 'globalization', label: 'globalization' },
        { key: 'webServer', label: 'system.webServer' },
        { key: 'handlers', label: 'handlers' },
        { key: 'aspNetCore', label: 'aspNetCore' }
    ];
    html += '<div style="display:flex; flex-wrap:wrap; gap:4px;">';
    checks.forEach(function(c) {
        var ok = struct[c.key];
        html += '<span class="structure-check ' + (ok ? 'ok' : 'bad') + '">' + (ok ? '✅' : '❌') + ' ' + c.label + '</span>';
    });
    html += '</div>';
    html += '<div style="margin-top:8px; font-size:12px; color:var(--muted);">Machine Key: ' + (data.hasMachineKey ? '✅ Present' : '⚠️ Missing') + '</div>';
    html += '</div>';

    // Issues
    if (data.issues && data.issues.length > 0) {
        html += '<div class="issue-list">';
        data.issues.forEach(function(iss) {
            html += '<div class="issue-item"><span class="issue-icon">❌</span>' + escHtml(iss) + '</div>';
        });
        html += '</div>';
    }

    // Show save button
    document.getElementById('btnSaveWC').style.display = '';

    el.innerHTML = html;
}

// ===================================================================
// Fix actions & One-Click Auto-Setup
// ===================================================================
function fixMachineName() {
    api('fixMachineName').then(function(res) {
        if (res.error) {
            alert('Error fixing machine name: ' + res.error);
        } else {
            alert('Machine name successfully updated to ' + res.machineName);
            checkStep('checkDatabase', 4);
        }
    }).catch(function(err) {
        alert('Request failed: ' + err.message);
    });
}

function runOneClickAutoSetup(doTestPrint) {
    var logBox = document.getElementById('oneClickLog');
    var statusText = document.getElementById('oneClickStatusText');
    var stepsList = document.getElementById('oneClickStepsList');
    var spinner = document.getElementById('oneClickSpinner');
    var btnMain = document.getElementById('btnOneClickSetup');
    var btnSec = document.getElementById('btnOneClickNoPrint');

    logBox.style.display = 'block';
    stepsList.innerHTML = '';
    spinner.style.display = 'inline-block';
    statusText.textContent = 'Running automated printer setup routine...';
    btnMain.disabled = true;
    btnSec.disabled = true;

    api('oneClickAutoSetup').then(function(res) {
        if (res.error) {
            statusText.textContent = 'Setup encountered an error';
            spinner.style.display = 'none';
            stepsList.innerHTML = '<div class="issue-item"><span class="issue-icon">❌</span>' + escHtml(res.error) + '</div>';
            btnMain.disabled = false;
            btnSec.disabled = false;
            return;
        }

        (res.steps || []).forEach(function(s) {
            var icon = s.status === 'ok' ? '✅' : s.status === 'warn' ? '⚠️' : s.status === 'info' ? 'ℹ️' : '❌';
            var cls = s.status === 'ok' ? 'pass' : s.status === 'warn' ? 'warn' : s.status === 'info' ? 'warn' : '';
            var bg = s.status === 'ok' ? 'background:color-mix(in srgb, #10b981 8%, transparent);border-color:#10b981;color:var(--text);' : '';
            stepsList.innerHTML += '<div class="issue-item ' + cls + '" style="' + bg + '"><span class="issue-icon">' + icon + '</span><div><strong>' + escHtml(s.step) + ':</strong> ' + escHtml(s.message) + '</div></div>';
        });

        if (doTestPrint) {
            statusText.textContent = 'Configuration applied! Now firing end-to-end test print...';
            stepsList.innerHTML += '<div class="issue-item" id="tpLiveStep" style="background:color-mix(in srgb, var(--accent) 8%, transparent);border-color:var(--accent);"><span class="spinner"></span><div><strong>Test Print:</strong> Submitting print job to AssetWorx Print Server...</div></div>';

            api('testPrint').then(function(tpRes) {
                spinner.style.display = 'none';
                btnMain.disabled = false;
                btnSec.disabled = false;
                var tpLive = document.getElementById('tpLiveStep');
                if (tpRes.success) {
                    statusText.textContent = '🎉 All systems green! Printer setup completed and test print confirmed.';
                    if (tpLive) {
                        tpLive.style.background = 'color-mix(in srgb, #10b981 12%, transparent)';
                        tpLive.style.borderColor = '#10b981';
                        tpLive.innerHTML = '<span class="issue-icon">✅</span><div><strong>Test Print:</strong> Completed successfully! Verified on physical printer.</div>';
                    }
                } else {
                    statusText.textContent = 'Configuration succeeded, but test print reported an issue.';
                    if (tpLive) {
                        tpLive.style.background = 'color-mix(in srgb, #ef4444 8%, transparent)';
                        tpLive.style.borderColor = '#ef4444';
                        tpLive.innerHTML = '<span class="issue-icon">❌</span><div><strong>Test Print:</strong> ' + escHtml(tpRes.error || 'Timed out waiting for print job.') + '</div>';
                    }
                }
                checkStep('checkDatabase', 4);
                checkStep('checkStaleJobs', 8);
            }).catch(function(tpErr) {
                spinner.style.display = 'none';
                btnMain.disabled = false;
                btnSec.disabled = false;
                statusText.textContent = 'Test print call failed: ' + tpErr.message;
            });
        } else {
            spinner.style.display = 'none';
            btnMain.disabled = false;
            btnSec.disabled = false;
            statusText.textContent = '🎉 Configuration completed successfully!';
            checkStep('checkDatabase', 4);
        }
    }).catch(function(err) {
        spinner.style.display = 'none';
        btnMain.disabled = false;
        btnSec.disabled = false;
        statusText.textContent = 'Setup failed: ' + err.message;
    });
}

function fixPrintServer() {
    if (!confirm('This will update the Print Server appsettings.json and restart the service. Continue?')) return;
    var el = document.getElementById('content5');
    el.innerHTML = '<span class="spinner"></span> Fixing...';
    api('fixPrintServerConfig').then(function(data) {
        if (data.error) { alert('Error: ' + data.error); checkStep('checkPrintServerConfig', 5); return; }
        var html = '<div style="margin:12px 0">';
        (data.changes || []).forEach(function(c) { html += '<div style="color:#10b981; font-size:13px; margin:4px 0;">✅ ' + escHtml(c) + '</div>'; });
        html += '</div>';
        el.innerHTML = html;
        setTimeout(function() { checkStep('checkPrintServerConfig', 5); }, 1500);
    });
}

function fixWebClient() {
    if (!confirm('This will update the WebClient appsettings.json. Continue?')) return;
    var el = document.getElementById('content6');
    el.innerHTML = '<span class="spinner"></span> Fixing...';
    api('fixWebClientConfig').then(function(data) {
        if (data.error) { alert('Error: ' + data.error); checkStep('checkWebClientConfig', 6); return; }
        var html = '<div style="margin:12px 0">';
        (data.changes || []).forEach(function(c) { html += '<div style="color:#10b981; font-size:13px; margin:4px 0;">✅ ' + escHtml(c) + '</div>'; });
        html += '</div>';
        el.innerHTML = html;
        setTimeout(function() { checkStep('checkWebClientConfig', 6); }, 1500);
    });
}

function clearStaleJobs() {
    api('clearStaleJobs').then(function(data) {
        if (data.error) { alert('Error: ' + data.error); return; }
        alert('Cleared ' + data.cleared + ' stale job(s).');
        checkStep('checkStaleJobs', 8);
    });
}

function saveWebConfigChanges() {
    if (!confirm('Save web.config? IIS will restart and you may need to sign in again.')) return;

    var payload = {
        dbServer: document.getElementById('wcDbServer').value,
        dbName: document.getElementById('wcDbName').value,
        dbUser: document.getElementById('wcDbUser').value,
        dbPass: document.getElementById('wcDbPass').value,
        appSettings: {
            AssetWorx_ApiBase: document.getElementById('wcApiBase').value,
            AssetWorx_TokenUrl: document.getElementById('wcTokenUrl').value,
            AssetWorx_ClientId: document.getElementById('wcClientId').value,
            AssetWorx_ClientSecret: document.getElementById('wcClientSecret').value,
            SMTP_Host: document.getElementById('wcSmtpHost').value,
            SMTP_Port: document.getElementById('wcSmtpPort').value,
            SMTP_User: document.getElementById('wcSmtpUser').value,
            SMTP_Password: document.getElementById('wcSmtpPassword').value,
            SMTP_FromEmail: document.getElementById('wcSmtpFrom').value,
            EmailRecipients: document.getElementById('wcEmailRecipients').value
        }
    };

    var el = document.getElementById('content9');
    el.innerHTML = '<div style="padding:20px; text-align:center;">' +
        '<div style="font-size:16px; font-weight:700; color:var(--accent); margin-bottom:12px;"><span class="spinner"></span> Saving web.config...</div>' +
        '<div style="font-size:13px; color:var(--muted);">A backup is being created. IIS will restart automatically.<br>You may need to sign in again after the page reloads.</div>' +
        '</div>';

    try { localStorage.setItem('idash_wc_action', 'saved'); } catch(e) {}

    api('saveWebConfig', payload).then(function(data) {
        if (data && data.error) {
            try { localStorage.removeItem('idash_wc_action'); } catch(e) {}
            alert('Error: ' + data.error);
            checkStep('checkWebConfig', 9);
            return;
        }
        // Success response arrived before recycle — reload to pick up changes
        setTimeout(function() { location.href = 'va_print_setup_wizard.aspx'; }, 1500);
    }).catch(function() {
        // IIS recycled before response — save succeeded, force reload
        setTimeout(function() { location.href = 'va_print_setup_wizard.aspx'; }, 3000);
    });
}

function rebuildWebConfig() {
    if (!confirm('REPLACE web.config with a fresh template?\n\nBackup created first. IIS will restart.\nYou may need to sign in again.')) return;

    var payload = {
        dbServer: (document.getElementById('wcDbServer') || {}).value || '.\\sqlexpress',
        dbName: (document.getElementById('wcDbName') || {}).value || 'AssetWorx',
        dbUser: (document.getElementById('wcDbUser') || {}).value || 'assetworxadmin',
        dbPass: (document.getElementById('wcDbPass') || {}).value || 'assetworxadmin',
        clientId: (document.getElementById('wcClientId') || {}).value || 'v512',
        clientSecret: (document.getElementById('wcClientSecret') || {}).value || '',
        emailRecipients: (document.getElementById('wcEmailRecipients') || {}).value || '',
        smtpHost: (document.getElementById('wcSmtpHost') || {}).value || 'smtp.office365.com',
        smtpPort: (document.getElementById('wcSmtpPort') || {}).value || '587',
        smtpUser: (document.getElementById('wcSmtpUser') || {}).value || '',
        smtpPassword: (document.getElementById('wcSmtpPassword') || {}).value || '',
        smtpFromEmail: (document.getElementById('wcSmtpFrom') || {}).value || ''
    };

    var el = document.getElementById('content9');
    el.innerHTML = '<div style="padding:20px; text-align:center;">' +
        '<div style="font-size:16px; font-weight:700; color:var(--accent); margin-bottom:12px;"><span class="spinner"></span> Rebuilding web.config...</div>' +
        '<div style="font-size:13px; color:var(--muted);">Generating from known-good template. IIS will restart.<br>You may need to sign in again after the page reloads.</div>' +
        '</div>';

    try { localStorage.setItem('idash_wc_action', 'rebuilt'); } catch(e) {}

    api('rebuildWebConfig', payload).then(function(data) {
        if (data && data.error) {
            try { localStorage.removeItem('idash_wc_action'); } catch(e) {}
            alert('Error: ' + data.error);
            checkStep('checkWebConfig', 9);
            return;
        }
        setTimeout(function() { location.href = 'va_print_setup_wizard.aspx'; }, 1500);
    }).catch(function() {
        setTimeout(function() { location.href = 'va_print_setup_wizard.aspx'; }, 3000);
    });
}

function testPrint() {
    var btn = document.getElementById('btnTest');
    btn.disabled = true;
    btn.textContent = '⏳ Printing...';
    var resultEl = document.getElementById('testResult');

    if (window.wizardMode === 'standalone') {
        // Standalone: use BarTender API handler for a preview test
        resultEl.innerHTML = '<div style="margin-top:12px"><span class="spinner"></span> Testing BarTender Native API (preview render)...</div>';

        var fields = { lblname: '517 EE99999', lbldescription: 'WIZARD TEST PRINT', lblsn: 'SN-TEST-001', lbleil: '138', lblrfidtag: 'E28011902000216503837493' };

        // Find first template file
        api('checkTemplates').then(function(tdata) {
            var templatePath = tdata.templates && tdata.templates.length > 0 ? tdata.templates[0].fullPath : null;
            if (!templatePath) {
                btn.disabled = false;
                btn.textContent = '🖨️ Send Test Print';
                resultEl.innerHTML = '<div class="test-result failure"><strong>❌ No templates found</strong> — copy .btw files to C:\\assetworx_prints\\</div>';
                return;
            }

            return fetch('api/BarTenderHandler.ashx?action=preview', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=utf-8' },
                body: JSON.stringify({ template: templatePath, fields: fields })
            }).then(function(r) { return r.json(); }).then(function(data) {
                btn.disabled = false;
                btn.textContent = '🖨️ Send Test Print';

                var html = '<div class="test-result ' + (data.Success ? 'success' : 'failure') + '">';
                html += '<strong>' + (data.Success ? '✅ BARTENDER API TEST PASSED!' : '❌ BARTENDER API TEST FAILED') + '</strong>';
                if (data.Success && data.ImageBase64) {
                    html += '<br><span style="font-size:13px">BarTender rendered a preview successfully. Native API is working.</span>';
                    html += '<br><img src="data:image/png;base64,' + data.ImageBase64 + '" style="max-width:400px; margin-top:12px; border-radius:8px; border:1px solid var(--line);" />';
                    if (data.DiscoveredFields && data.DiscoveredFields.length > 0) {
                        html += '<br><span style="font-size:12px; color:var(--muted);">Named Data Sources found: <code>' + data.DiscoveredFields.join('</code>, <code>') + '</code></span>';
                    }
                }
                if (data.ErrorMessage) html += '<br><span style="font-size:13px; color:#ef4444;">' + escHtml(data.ErrorMessage) + '</span>';
                html += '</div>';
                resultEl.innerHTML = html;

                updateSummary(8, data.Success ? 'pass' : 'fail');
                updateOverallBanner();
            });
        }).catch(function(err) {
            btn.disabled = false;
            btn.textContent = '🖨️ Send Test Print';
            resultEl.innerHTML = '<div class="test-result failure"><strong>❌ Request failed:</strong> ' + escHtml(err.message) + '</div>';
        });
    } else {
        // AssetWorx mode: use the MQTT print path
        resultEl.innerHTML = '<div style="margin-top:12px"><span class="spinner"></span> Submitting test print and waiting for Print Server response (up to 15 seconds)...</div>';

        api('testPrint').then(function(data) {
            btn.disabled = false;
            btn.textContent = '🖨️ Send Test Print';

            var html = '<div class="test-result ' + (data.success ? 'success' : 'failure') + '">';
            html += '<strong>' + (data.success ? '✅ TEST PRINT SUCCEEDED!' : '❌ TEST PRINT FAILED') + '</strong>';
            if (data.error) html += '<br><span style="font-size:13px">' + escHtml(data.error) + '</span>';
            if (data.steps) {
                html += '<div class="test-steps">';
                data.steps.forEach(function(s) { html += escHtml(s) + '<br>'; });
                html += '</div>';
            }
            html += '</div>';
            resultEl.innerHTML = html;

            updateSummary(8, data.success ? 'pass' : 'fail');
            updateOverallBanner();
        }).catch(function(err) {
            btn.disabled = false;
            btn.textContent = '🖨️ Send Test Print';
            resultEl.innerHTML = '<div class="test-result failure"><strong>❌ Request failed:</strong> ' + escHtml(err.message) + '</div>';
        });
    }
}

// ===================================================================
// Full Scan (mode-aware)
// ===================================================================
function runFullScan() {
    if (!window.wizardMode) return; // Don't scan until mode is selected

    var isStandalone = window.wizardMode === 'standalone';
    var activeSteps = isStandalone ? [1, 2, 3, 8, 9] : [1, 2, 3, 4, 5, 6, 7, 8, 9];

    // Reset active steps to pending
    activeSteps.forEach(function(i) {
        updateSummary(i, 'pending');
        var el = document.getElementById('content' + i);
        el.innerHTML = '<span class="spinner"></span> Checking...';
    });

    api('fullScan').then(function(data) {
        // Step 1 — BarTender Services
        var d1 = data.barTenderServices;
        updateSummary(1, d1.pass ? 'pass' : 'fail');
        renderBarTenderServices(document.getElementById('content1'), d1);

        // Step 2 — Printers
        var d2 = data.printers;
        updateSummary(2, d2.pass ? 'pass' : 'warn');
        renderPrinters(document.getElementById('content2'), d2);

        // Step 3 — Templates
        var d3 = data.templates;
        updateSummary(3, d3.pass ? 'pass' : 'fail');
        renderTemplates(document.getElementById('content3'), d3);

        if (!isStandalone) {
            // Step 4 — Database
            var d4 = data.database;
            updateSummary(4, d4.pass ? 'pass' : 'fail');
            renderDatabase(document.getElementById('content4'), d4);

            // Step 5 — Print Server Config
            var d5 = data.printServerConfig;
            updateSummary(5, d5.pass ? 'pass' : 'fail');
            renderPrintServerConfig(document.getElementById('content5'), d5);

            // Step 6 — WebClient Config
            var d6 = data.webClientConfig;
            updateSummary(6, d6.pass ? 'pass' : 'fail');
            renderWebClientConfig(document.getElementById('content6'), d6);

            // Step 7 — Service Account
            var d7 = data.serviceAccount;
            var s7 = d7.pass ? 'pass' : (d7.issues && d7.issues.some(function(i) { return i.indexOf('LocalSystem') >= 0; }) ? 'warn' : 'fail');
            updateSummary(7, s7);
            renderServiceAccount(document.getElementById('content7'), d7);
        }

        // Step 8 — Stale Jobs
        var d8 = data.staleJobs;
        updateSummary(8, d8.pass ? 'pass' : 'warn');
        renderStaleJobs(document.getElementById('content8'), d8);

        // Step 9 — web.config
        var d9 = data.webConfig;
        updateSummary(9, d9.pass ? 'pass' : 'fail');
        renderWebConfig(document.getElementById('content9'), d9);

        // Enable Fix All if there are issues (AssetWorx mode only)
        if (!isStandalone) {
            var hasIssues = !data.printServerConfig.pass || !data.webClientConfig.pass;
            document.getElementById('btnFixAll').disabled = !hasIssues;
        } else {
            document.getElementById('btnFixAll').disabled = true;
        }

        updateOverallBanner();
    }).catch(function(err) {
        alert('Scan failed: ' + err.message);
    });
}

function fixAll() {
    if (!confirm('This will auto-fix Print Server and WebClient configs, sync credentials from the database, and restart the Print Server service. Continue?')) return;

    api('fixPrintServerConfig').then(function() {
        return api('fixWebClientConfig');
    }).then(function() {
        alert('All auto-fixable issues resolved. Re-running scan...');
        runFullScan();
    }).catch(function(err) {
        alert('Fix error: ' + err.message);
        runFullScan();
    });
}

function updateOverallBanner() {
    var banner = document.getElementById('resultBanner');
    var cards = document.querySelectorAll('.sum-card');
    var allPass = true;
    var anyFail = false;
    var activeCount = 0;
    cards.forEach(function(c) {
        if (c.classList.contains('na')) return; // Skip N/A steps
        activeCount++;
        if (c.classList.contains('fail')) { allPass = false; anyFail = true; }
        if (c.classList.contains('warn') || c.classList.contains('pending')) allPass = false;
    });

    if (allPass && activeCount > 0) {
        var modeLabel = window.wizardMode === 'standalone' ? 'Standalone' : 'AssetWorx';
        banner.className = 'result-banner show all-pass';
        banner.textContent = '🎉 PRINTING IS FULLY CONFIGURED (' + modeLabel + ' Mode) — All checks passed!';
    } else if (anyFail) {
        var failCount = 0;
        document.querySelectorAll('.sum-card.fail').forEach(function() { failCount++; });
        banner.className = 'result-banner show has-issues';
        banner.textContent = '⚠️ ' + failCount + ' step(s) need attention — see details below';
    } else {
        banner.className = 'result-banner';
    }
}

// ===================================================================
// Export Report
// ===================================================================
function exportReport() {
    var modeLabel = window.wizardMode === 'standalone' ? 'Standalone (Native API)' : 'AssetWorx Print Server';
    var lines = ['=== iDash Print Setup Wizard Report ===', 'Mode: ' + modeLabel, 'Generated: ' + new Date().toLocaleString(), ''];
    var cards = document.querySelectorAll('.sum-card');
    cards.forEach(function(c) {
        var label = c.querySelector('.sc-label').textContent;
        var status = c.classList.contains('pass') ? 'PASS' : c.classList.contains('fail') ? 'FAIL' : c.classList.contains('warn') ? 'WARN' : c.classList.contains('na') ? 'N/A' : 'PENDING';
        lines.push('Step ' + c.dataset.step + ': ' + label + ' — ' + status);
    });
    lines.push('');
    lines.push('Run a Full Scan for detailed information.');

    var blob = new Blob([lines.join('\n')], { type: 'text/plain' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'print_setup_report_' + new Date().toISOString().slice(0,10) + '.txt';
    a.click();
}

// ===================================================================
// Util
// ===================================================================
function escHtml(s) { if (!s) return ''; var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

// ===================================================================
// Auto-detect mode on load
// ===================================================================
window.addEventListener('DOMContentLoaded', function() {
    api('detectMode').then(function(data) {
        document.getElementById('modeDetecting').style.display = 'none';
        document.getElementById('modeCards').style.display = '';

        // Show auto-detect recommendation
        if (data.printServerInstalled && data.serviceExists) {
            document.getElementById('tagAssetworx').textContent = '✅ DETECTED — RECOMMENDED';
            document.getElementById('tagAssetworx').className = 'mode-tag recommended';
        } else if (data.nativeApiAvailable && data.handlerAvailable) {
            document.getElementById('tagStandalone').textContent = '✅ DETECTED — RECOMMENDED';
        }

        // Auto-select recommended mode
        selectMode(data.recommendedMode);
    }).catch(function() {
        document.getElementById('modeDetecting').style.display = 'none';
        document.getElementById('modeCards').style.display = '';
        // Default to assetworx if detection fails
        selectMode('assetworx');
    });
});
</script>
</body>
</html>

