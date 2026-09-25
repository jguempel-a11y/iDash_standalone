<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_system_update.aspx.cs" Inherits="va_system_update" ResponseEncoding="utf-8" %>
<%-- System Update v2.2 --%>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>System Update &amp; Deployment &mdash; iDash</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
<style>
    :root { --chip-br: var(--line); }
    *{box-sizing:border-box;}
    body{background:var(--bg);color:var(--text);font-family:Segoe UI,Tahoma,Arial,sans-serif;margin:0;}
    .app{display:flex;min-height:100vh;}
    .side{width:260px;background:var(--chip);border-right:1px solid var(--line);padding:22px 18px;flex-shrink:0;position:sticky;top:0;height:100vh;overflow-y:auto;}
    .side h1{font-size:17px;margin:0 0 4px;color:var(--accent);display:flex;align-items:center;gap:8px;}
    .side .sub{font-size:12px;color:var(--muted);margin-bottom:20px;}
    .nav-link{display:block;background:var(--chip);border:1px solid var(--chip-br);border-radius:8px;padding:9px 13px;color:var(--text);font-size:13px;font-weight:600;text-decoration:none;margin-bottom:7px;transition:all .15s ease;}
    .nav-link:hover{background:var(--accent);color:var(--bg);border-color:var(--accent);}
    .main{flex:1;padding:32px 42px;max-width:960px;}
    .page-title{font-size:24px;font-weight:700;margin:0 0 4px;display:flex;align-items:center;gap:10px;}
    .page-sub{color:var(--muted);font-size:13px;margin-bottom:26px;}
    .panel{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:24px 28px;margin-bottom:24px;box-shadow:0 4px 14px rgba(0,0,0,0.12);}
    .ptitle{font-size:16px;font-weight:700;margin:0 0 6px;color:var(--accent);display:flex;align-items:center;gap:8px;}
    .psub{font-size:13px;color:var(--muted);margin-bottom:18px;line-height:1.5;}
    .btn{padding:10px 22px;background:var(--accent);color:var(--bg);border-radius:10px;border:1px solid var(--accent);cursor:pointer;font-weight:700;font-size:14px;display:inline-flex;align-items:center;gap:8px;text-decoration:none;transition:filter .15s ease, transform .1s ease;}
    .btn:hover{filter:brightness(1.12);transform:translateY(-1px);}
    .btn.green{background:#10b981;border-color:#10b981;color:#fff;}
    .btn.blue{background:#3b82f6;border-color:#3b82f6;color:#fff;}
    .btn:disabled{opacity:0.6;cursor:not-allowed;transform:none;}
    .msg-ok{background:color-mix(in srgb, #10b981, transparent 88%);border:1px solid #10b981;color:#10b981;padding:12px 16px;border-radius:8px;margin-bottom:18px;font-size:14px;display:flex;align-items:center;gap:10px;}
    .msg-err{background:color-mix(in srgb, #ef4444, transparent 88%);border:1px solid #ef4444;color:#ef4444;padding:12px 16px;border-radius:8px;margin-bottom:18px;font-size:14px;display:flex;align-items:center;gap:10px;}

    /* Update Source Selector Cards */
    .source-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px;margin:16px 0;}
    .source-card{border:1px solid var(--line);border-radius:10px;padding:14px;cursor:pointer;transition:all .15s ease;background:var(--chip);}
    .source-card:hover{border-color:var(--accent);background:color-mix(in srgb, var(--accent), transparent 94%);}
    .source-card.active{border-color:var(--accent);background:color-mix(in srgb, var(--accent), transparent 90%);box-shadow:0 0 0 2px var(--accent);}
    .source-card input[type="radio"]{margin-right:8px;}
    .source-title{font-weight:700;font-size:13px;color:var(--text);margin-bottom:4px;}
    .source-desc{font-size:11px;color:var(--muted);line-height:1.4;}

    /* FULLSCREEN PROGRESS OVERLAY */
    #updateOverlay {
        position: fixed;
        inset: 0;
        z-index: 99999;
        background: rgba(8, 12, 22, 0.85);
        backdrop-filter: blur(14px);
        display: none;
        align-items: center;
        justify-content: center;
        padding: 20px;
    }
    .modal-box {
        width: 100%;
        max-width: 600px;
        background: #0f172a;
        border: 1px solid rgba(56, 189, 248, 0.35);
        border-radius: 18px;
        padding: 34px 38px;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7), 0 0 40px rgba(56, 189, 248, 0.15);
        color: #f8fafc;
        text-align: center;
    }
    .badge-icon {
        width: 68px;
        height: 68px;
        border-radius: 50%;
        background: linear-gradient(135deg, rgba(56, 189, 248, 0.2), rgba(16, 185, 129, 0.2));
        border: 2px solid #38bdf8;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 32px;
        margin-bottom: 18px;
        box-shadow: 0 0 24px rgba(56, 189, 248, 0.3);
        animation: pulseBadge 2s infinite ease-in-out;
    }
    @keyframes pulseBadge {
        0%, 100% { transform: scale(1); box-shadow: 0 0 20px rgba(56, 189, 248, 0.3); }
        50% { transform: scale(1.05); box-shadow: 0 0 35px rgba(56, 189, 248, 0.5); }
    }
    .modal-title { font-size: 22px; font-weight: 700; margin: 0 0 8px; color: #ffffff; }
    .modal-sub { font-size: 13px; color: #94a3b8; margin-bottom: 22px; }

    /* Progress bar */
    .progress-wrap {
        background: #1e293b;
        border-radius: 9999px;
        height: 18px;
        overflow: hidden;
        position: relative;
        margin: 18px 0 10px;
        border: 1px solid #334155;
    }
    .progress-bar-fill {
        height: 100%;
        width: 0%;
        background: linear-gradient(90deg, #38bdf8, #10b981);
        border-radius: 9999px;
        transition: width 0.3s ease;
        position: relative;
    }
    .progress-bar-fill::after {
        content: '';
        position: absolute;
        inset: 0;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent);
        animation: shimmer 1.5s infinite;
    }
    @keyframes shimmer {
        0% { transform: translateX(-100%); }
        100% { transform: translateX(100%); }
    }
    .progress-stats {
        display: flex;
        justify-content: space-between;
        font-size: 13px;
        font-weight: 600;
        color: #cbd5e1;
        margin-bottom: 18px;
        font-family: monospace;
    }
    .current-file {
        background: #1e293b;
        border: 1px solid #334155;
        border-radius: 8px;
        padding: 9px 12px;
        font-size: 12px;
        color: #38bdf8;
        font-family: monospace;
        text-align: left;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin-bottom: 18px;
    }

    /* Milestone Steps */
    .step-list {
        display: flex;
        justify-content: space-between;
        gap: 6px;
        margin: 20px 0;
        text-align: left;
    }
    .step-item {
        flex: 1;
        background: #1e293b;
        border: 1px solid #334155;
        border-radius: 8px;
        padding: 8px 6px;
        text-align: center;
        font-size: 11px;
        color: #64748b;
        font-weight: 600;
        transition: all .2s ease;
    }
    .step-item.active {
        border-color: #38bdf8;
        color: #38bdf8;
        background: rgba(56, 189, 248, 0.1);
    }
    .step-item.done {
        border-color: #10b981;
        color: #10b981;
        background: rgba(16, 185, 129, 0.1);
    }

    /* Warning Callout */
    .modal-warning {
        background: rgba(239, 68, 68, 0.12);
        border: 1px solid #ef4444;
        border-radius: 8px;
        padding: 10px 14px;
        font-size: 12px;
        color: #fca5a5;
        text-align: center;
        line-height: 1.4;
    }

    /* Finished / Success View */
    .complete-view { display: none; }
    .complete-icon { font-size: 48px; margin-bottom: 12px; }
</style>
</head>
<body>
<form id="form1" runat="server" enctype="multipart/form-data">
<div class="app">

    <!-- SIDEBAR -->
    <div class="side">
        <h1>
            <img src="/iDash/Assets/branding/rfid.png" alt="" style="width:20px;height:20px;" />
            Deployment Hub
        </h1>
        <div class="sub">System Update &amp; Maintenance</div>

        <a href="#sec-ota" class="nav-link">&#128640; 1-Click Update</a>
        <a href="#sec-upload" class="nav-link">&#128228; Web ZIP Updater</a>
        <a href="#sec-script" class="nav-link">&#128187; Tailscale Sync Script</a>
        <div style="height:24px;"></div>
        <a href="documentation/va_system_migration_guide.html" class="nav-link" style="border-color:#38bdf8; color:#38bdf8;">&#128214; Migration Playbook</a>
        <a href="index.aspx" class="nav-link" style="border-color:var(--line); margin-top:12px;">&#8962; Back to Hub</a>
    </div>

    <!-- MAIN CONTENT -->
    <div class="main">
        <h1 class="page-title">
            <img src="/iDash/Assets/branding/rfid.png" alt="" style="width:28px;height:28px;" />
            System Update &amp; Deployment
        </h1>
        <div class="page-sub">Effortless, zero-script web updater to synchronize remote laptops, mobile carts, and facility servers with the latest baseline.</div>

        <asp:Literal ID="LitMsg" runat="server" />

        <!-- SAFE BOUNDARY BADGE -->
        <div class="msg-ok" style="background: rgba(16, 185, 129, 0.08); border-color: #10b981; color: var(--text);">
            <strong style="font-size:16px;">&#128274; Safe Migration Boundary Active:</strong>
            <div style="font-size:12px; color:var(--muted); margin-top:4px; line-height:1.5;">
                Updating through this interface replaces application files, binaries, scripts, and documentation while strictly preserving all site-specific configuration:
                <strong>web.config</strong> (DB credentials, OAuth, SMTP, MQTT, machineKey) &bull;
                <strong>App_Data/</strong> (users, licenses, watchlists, scan columns) &bull;
                <strong>config/</strong> (email, FHIR keys, reader intelligence, report automation) &bull;
                <strong>printing/</strong> &amp; <strong>print_mapping_config.json</strong> (printer routing &amp; tag-type mapping) &bull;
                <strong>Assets/printserver_appsettings.json</strong> (print server MQTT config) &bull;
                <strong>services/</strong> (CrossSiteTagObserver) &bull;
                <strong>workbench_profiles/</strong> &bull; <strong>site_maps/</strong> &bull; <strong>logs/</strong>
        </div>

        <!-- REMOTE MACHINE BOOTSTRAP NOTICE -->
        <div class="panel" style="border: 2px solid #38bdf8; background: rgba(56, 189, 248, 0.05); margin-bottom: 24px;">
            <h2 class="ptitle" style="color: #38bdf8;">&#9889; Updating a Remote / Older Computer from this Master Node?</h2>
            <p class="psub" style="margin-bottom:12px;">
                <strong>Important note:</strong> Clicking &ldquo;Start System Update Now&rdquo; under Option 1 updates <em>the server hosting this page (<%= Request.Url.Host %>)</em>. If you opened this web page in a browser on your laptop, clicking the button updates the server hosting the site (Lingcod), not your laptop!
            </p>
            <div style="font-weight:600; font-size:13px; margin-bottom:10px; color:#e2e8f0;">
                To update that remote/older machine, run either of these <strong>on the remote machine</strong>:
            </div>
            
            <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:14px; margin-top:10px;">
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:16px;">
                    <div style="font-weight:700; color:#10b981; font-size:13px; margin-bottom:6px;">&#128229; Method 1: Download &amp; Run Batch File</div>
                    <div style="font-size:12px; color:var(--muted); margin-bottom:12px; line-height:1.4;">Download this batch file to the remote machine and double-click it. It connects to Lingcod, deploys all 972+ files, preserves <code>web.config</code>, and installs this update page locally!</div>
                    <a href="va_system_update.aspx?action=get_bat" class="btn green" style="width:100%; justify-content:center; padding:10px 0; font-size:13px;">
                        &#128229; Download update_this_machine.bat
                    </a>
                </div>
                
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:16px;">
                    <div style="font-weight:700; color:#38bdf8; font-size:13px; margin-bottom:6px;">&#128187; Method 2: 1-Line PowerShell Command</div>
                    <div style="font-size:12px; color:var(--muted); margin-bottom:8px; line-height:1.4;">Open PowerShell (Run as Administrator) on the remote machine and paste:</div>
                    <div style="background:#020617; border:1px solid #334155; border-radius:6px; padding:8px 10px; font-family:Consolas,monospace; font-size:11px; color:#38bdf8; word-break:break-all; user-select:all;">
                        iex (irm '<%= GetBootstrapUrl() %>')
                    </div>
                </div>
            </div>
        </div>

        <!-- OPTION 1: 1-CLICK OVER-THE-AIR UPDATE -->
        <div class="panel" id="sec-ota">
            <h2 class="ptitle">&#128640; Option 1: 1-Click Over-The-Air Update (Local System)</h2>
            <p class="psub">This server will directly download the clean baseline package from your master development node or GitHub repository, extract all application files, and refresh IIS &mdash; completely hands-free with real-time visual progress.</p>

            <div style="font-weight:600; font-size:13px; margin-bottom:6px;">Select Update Source:</div>
            
            <div class="source-grid">
                <div class="source-card active" onclick="selectSource('master', 'https://lingcod.tail585c9b.ts.net/iDash/downloads/idash_update.zip')">
                    <input type="radio" name="updateSourceRadio" id="srcMaster" checked="checked" />
                    <label for="srcMaster" class="source-title">&#128279; Master Node (LingCod Tailscale / Web)</label>
                    <div class="source-desc">Direct sync from LingCod master over Tailscale Funnel (works inside or outside Tailnet).</div>
                </div>

                <div class="source-card" onclick="selectSource('master-direct', 'http://100.90.225.121/iDash/downloads/idash_update.zip')">
                    <input type="radio" name="updateSourceRadio" id="srcMasterDirect" />
                    <label for="srcMasterDirect" class="source-title">&#128268; Master Node (Direct 100.90.225.121)</label>
                    <div class="source-desc">Direct high-speed P2P sync across Tailscale (when connected to tailnet).</div>
                </div>

                <div class="source-card" onclick="selectSource('github-branch', 'https://github.com/jguempel-a11y/iDash/archive/refs/heads/idash_update.zip')">
                    <input type="radio" name="updateSourceRadio" id="srcGhBranch" />
                    <label for="srcGhBranch" class="source-title">&#128025; GitHub Update Branch Zip</label>
                    <div class="source-desc">Direct snapshot of latest idash_update branch code from GitHub.</div>
                </div>

                <div class="source-card" onclick="selectSource('custom', '')">
                    <input type="radio" name="updateSourceRadio" id="srcCustom" />
                    <label for="srcCustom" class="source-title">&#9881;&#65039; Custom Package URL</label>
                    <div class="source-desc">Provide any custom HTTP/HTTPS update URL or staging host.</div>
                </div>
            </div>

            <div style="margin-top:14px;">
                <label style="display:block; font-size:12px; font-weight:600; margin-bottom:6px;">Target Package URL</label>
                <asp:TextBox ID="TxtMasterUrl" runat="server" ClientIDMode="Static" style="background:var(--chip);color:var(--text);border:1px solid var(--line);padding:10px 14px;border-radius:8px;width:100%;font-family:monospace;font-size:13px;" />
            </div>

            <div style="margin-top:20px;">
                <button type="button" id="btnStartOta" class="btn green" onclick="startOtaUpdate()">
                    &#128640; Start System Update Now
                </button>
            </div>
        </div>

        <!-- OPTION 2: LOCAL ZIP UPLOAD -->
        <div class="panel" id="sec-upload">
            <h2 class="ptitle">&#128228; Option 2: Upload Update Archive (.zip)</h2>
            <p class="psub">If the master server and internet are completely offline, you can upload <code>idash_full_site.zip</code> directly from your laptop or a USB flash drive:</p>

            <div style="margin-top:14px;">
                <asp:FileUpload ID="FileUp" runat="server" style="background:var(--chip);color:var(--text);border:1px solid var(--line);padding:10px;border-radius:8px;width:100%;max-width:500px;" />
            </div>

            <div style="margin-top:14px;">
                <asp:Button ID="BtnUpload" runat="server" Text="&#8673; Upload &amp; Install Update" CssClass="btn blue" OnClick="BtnUpload_Click" OnClientClick="showUploadOverlay();" />
            </div>
        </div>

        <!-- OPTION 3: TAILSCALE SCRIPT -->
        <div class="panel" id="sec-script">
            <h2 class="ptitle">&#128187; Option 3: Tailscale Deploy Script (For Direct PowerShell Sync)</h2>
            <p class="psub">Download a generated PowerShell script to run directly on the source machine if you prefer local robocopy deployment:</p>
            
            <div style="margin-top:12px;">
                <label style="display:block; font-size:12px; font-weight:600; margin-bottom:4px;">Source Directory</label>
                <asp:TextBox ID="TxtSourceDir" runat="server" Text="C:\inetpub\wwwroot\AssetWorx.WebClient\iDash" style="background:var(--chip);color:var(--text);border:1px solid var(--line);padding:8px;border-radius:6px;width:100%;max-width:600px;margin-bottom:10px;font-family:monospace;font-size:12px;" />
                
                <label style="display:block; font-size:12px; font-weight:600; margin-bottom:4px;">Target UNC Path</label>
                <asp:TextBox ID="TxtTargetDir" runat="server" Text="\\laptop-e74ckmo5.tail2fc4c5.ts.net\c$\inetpub\wwwroot\AssetWorx.WebClient\iDash" style="background:var(--chip);color:var(--text);border:1px solid var(--line);padding:8px;border-radius:6px;width:100%;max-width:600px;margin-bottom:12px;font-family:monospace;font-size:12px;" />
            </div>

            <asp:Button ID="BtnDownloadScript" runat="server" Text="&#128190; Download deploy_idash.ps1" CssClass="btn" style="background:var(--chip); border-color:var(--line); color:var(--text);" OnClick="BtnDownloadScript_Click" />
        </div>

    </div>

</div>

<!-- FULLSCREEN PROGRESS MODAL OVERLAY -->
<div id="updateOverlay">
    <div class="modal-box">
        
        <!-- IN-PROGRESS VIEW -->
        <div id="modalActiveView">
            <div class="badge-icon">&#128640;</div>
            <div class="modal-title">System Update In Progress</div>
            <div class="modal-sub" id="modalStatusMsg">Initializing update pipeline...</div>

            <!-- Milestone Steps -->
            <div class="step-list">
                <div class="step-item" id="step-download">1. Download</div>
                <div class="step-item" id="step-extract">2. Unpack</div>
                <div class="step-item" id="step-copy">3. Sync Files</div>
                <div class="step-item" id="step-recycle">4. Refresh IIS</div>
            </div>

            <!-- Progress Bar -->
            <div class="progress-wrap">
                <div class="progress-bar-fill" id="progressBarFill"></div>
            </div>
            
            <div class="progress-stats">
                <span id="statProgressPct">0%</span>
                <span id="statSpeed">Elapsed: 0s</span>
            </div>

            <!-- Current File Ticker -->
            <div class="current-file" id="currentFileTicker">
                Connecting to repository...
            </div>

            <!-- Live Update Console -->
            <div style="margin-top:14px; text-align:left;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
                    <span style="font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:0.05em; color:#94a3b8;">Live Update Console</span>
                    <div style="display:flex; align-items:center; gap:8px;">
                        <span id="logCountBadge" style="font-size:11px; color:#38bdf8; font-family:Consolas,monospace;">0 events</span>
                        <button type="button" onclick="copyConsoleLogs()" style="background:#1e293b; border:1px solid #334155; color:#38bdf8; border-radius:4px; padding:2px 8px; font-size:11px; cursor:pointer;">&#128203; Copy Logs</button>
                    </div>
                </div>
                <div id="logConsole" style="background:#020617; border:1px solid #334155; border-radius:8px; padding:10px 12px; font-family:Consolas,monospace; font-size:11px; color:#38bdf8; height:130px; overflow-y:auto; white-space:pre-wrap; line-height:1.45;">[Ready] Waiting to start update...</div>
            </div>

            <!-- Safety Notice -->
            <div class="modal-warning">
                &#9888;&#65039; <strong>DO NOT REFRESH OR CLOSE THIS WINDOW</strong><br />
                The system is replacing application binaries and restarting IIS. Navigating away will disrupt this view.
            </div>
        </div>

        <!-- COMPLETION VIEW -->
        <div id="modalCompleteView" class="complete-view">
            <div class="complete-icon">&#9989;</div>
            <div class="modal-title" style="color:#10b981;">Update Completed Successfully!</div>
            <div class="modal-sub" id="completeSummary" style="margin-bottom:24px; font-size:14px; color:#e2e8f0;">
                All application files have been synchronized. Local database credentials (web.config) and user records were preserved.
            </div>

            <div style="background:#1e293b; border-radius:10px; padding:14px; margin-bottom:20px; font-size:13px; color:#94a3b8;">
                Redirecting to iDash Hub in <strong id="redirectCountdown" style="color:#38bdf8;">5</strong> seconds...
            </div>

            <a href="index.aspx" class="btn green" style="width:100%; justify-content:center; padding:12px 0;">
                &#8962; Return to iDash Hub Now
            </a>
        </div>

        <!-- ERROR VIEW -->
        <div id="modalErrorView" class="complete-view">
            <div class="complete-icon" style="color:#ef4444;">&#10060;</div>
            <div class="modal-title" style="color:#ef4444;">Update Encountered An Error</div>
            <div class="modal-sub" id="errorSummary" style="margin-bottom:24px; font-size:14px; color:#fca5a5;">
                The update process could not be completed.
            </div>

            <div style="display:flex; gap:10px; justify-content:center;">
                <button type="button" class="btn" style="background:#0284c7; color:#fff; border-color:#38bdf8;" onclick="copyConsoleLogs()">
                    &#128203; Copy Error Logs
                </button>
                <button type="button" class="btn" style="background:#334155; color:#fff; border-color:#475569;" onclick="closeOverlay()">
                    Close
                </button>
            </div>
        </div>

    </div>
</div>

<idash:Footer runat="server" />
</form>

<script>
    var isUpdating = false;
    var pollTimer = null;
    var countdownTimer = null;

    // Window navigation protection during updates
    window.addEventListener('beforeunload', function (e) {
        if (isUpdating) {
            var confirmationMessage = 'System update is in progress. Refreshing may interrupt the installation.';
            (e || window.event).returnValue = confirmationMessage;
            return confirmationMessage;
        }
    });

    function copyConsoleLogs() {
        var el = document.getElementById('logConsole');
        var txt = el ? el.textContent : '';
        if (navigator.clipboard) {
            navigator.clipboard.writeText(txt).then(function() {
                alert('Update logs copied to clipboard!');
            }).catch(function() {
                alert(txt);
            });
        } else {
            alert(txt);
        }
    }

    function selectSource(type, url) {
        document.querySelectorAll('.source-card').forEach(function(c) { c.classList.remove('active'); });
        
        var radioId = 'srcMaster';
        if (type === 'master-direct') radioId = 'srcMasterDirect';
        else if (type === 'github-release') radioId = 'srcGhRel';
        else if (type === 'github-branch') radioId = 'srcGhBranch';
        else if (type === 'custom') radioId = 'srcCustom';
        
        var card = document.getElementById(radioId).closest('.source-card');
        if (card) card.classList.add('active');
        document.getElementById(radioId).checked = true;

        var txtUrl = document.getElementById('TxtMasterUrl');
        if (url) {
            txtUrl.value = url;
            txtUrl.readOnly = true;
            txtUrl.style.opacity = '0.85';
        } else {
            txtUrl.readOnly = false;
            txtUrl.style.opacity = '1.0';
            txtUrl.focus();
        }
    }

    function showOverlay() {
        document.getElementById('updateOverlay').style.display = 'flex';
        document.getElementById('modalActiveView').style.display = 'block';
        document.getElementById('modalCompleteView').style.display = 'none';
        document.getElementById('modalErrorView').style.display = 'none';
    }

    function closeOverlay() {
        document.getElementById('updateOverlay').style.display = 'none';
        isUpdating = false;
        if (pollTimer) clearInterval(pollTimer);
    }

    function showUploadOverlay() {
        showOverlay();
        document.getElementById('modalStatusMsg').textContent = 'Uploading update package archive...';
        document.getElementById('currentFileTicker').textContent = 'Transferring file to server and unpacking baseline...';
        document.getElementById('progressBarFill').style.width = '50%';
        document.getElementById('statProgressPct').textContent = '50%';
    }

    function startOtaUpdate() {
        var url = document.getElementById('TxtMasterUrl').value.trim();
        if (!url) {
            alert('Please select or specify a valid package URL.');
            return;
        }

        if (!confirm('Start System Update now?\n\nThis will download the latest application baseline and refresh IIS. Safe Migration Boundary will preserve your database credentials (web.config).')) {
            return;
        }

        isUpdating = true;
        showOverlay();
        document.getElementById('modalStatusMsg').textContent = 'Connecting to server update service...';
        document.getElementById('progressBarFill').style.width = '5%';
        document.getElementById('statProgressPct').textContent = '5%';
        document.getElementById('btnStartOta').disabled = true;

        // Trigger asynchronous update start
        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'va_system_update.aspx?action=start', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onload = function() {
            if (xhr.status === 200) {
                try {
                    var res = JSON.parse(xhr.responseText);
                    if (res.ok) {
                        startPolling();
                    } else {
                        showError(res.error || 'Failed to start update.');
                    }
                } catch(e) {
                    startPolling();
                }
            } else {
                startPolling(); // Even if 500/recycle, poll status file
            }
        };
        xhr.onerror = function() {
            startPolling();
        };
        xhr.send('url=' + encodeURIComponent(url));
    }

    function startPolling() {
        if (pollTimer) clearInterval(pollTimer);
        pollTimer = setInterval(checkStatus, 750);
        checkStatus();
    }

    function checkStatus() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'va_system_update.aspx?action=status&t=' + Date.now(), true);
        xhr.timeout = 3000;
        xhr.onload = function() {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    updateProgressUi(data);
                } catch(e) {
                    // Handler returned non-JSON (likely IIS recycling) — fallback to status file
                    checkStatusFallback();
                }
            } else {
                checkStatusFallback();
            }
        };
        xhr.onerror = function() { checkStatusFallback(); };
        xhr.ontimeout = function() { checkStatusFallback(); };
        xhr.send();
    }

    function checkStatusFallback() {
        var xhr2 = new XMLHttpRequest();
        xhr2.open('GET', 'scratch/update_status.json?t=' + Date.now(), true);
        xhr2.timeout = 3000;
        xhr2.onload = function() {
            if (xhr2.status === 200) {
                try {
                    var data = JSON.parse(xhr2.responseText);
                    updateProgressUi(data);
                } catch(e) { }
            }
        };
        xhr2.onerror = function() {
            var ticker = document.getElementById('currentFileTicker');
            if (ticker) ticker.textContent = 'Application pool restarting with updated files...';
        };
        xhr2.send();
    }

    function updateProgressUi(data) {
        if (!data) return;

        var pct = data.percent || 0;
        document.getElementById('progressBarFill').style.width = pct + '%';
        document.getElementById('statProgressPct').textContent = pct + '%';
        
        if (data.elapsedSeconds) {
            document.getElementById('statSpeed').textContent = 'Elapsed: ' + data.elapsedSeconds + 's';
        }

        if (data.message) {
            document.getElementById('modalStatusMsg').textContent = data.message;
        }

        if (data.currentFile) {
            document.getElementById('currentFileTicker').textContent = 'Deploying: ' + data.currentFile;
        } else if (data.message) {
            document.getElementById('currentFileTicker').textContent = data.message;
        }

        // Render Live Log Console
        if (data.recentLogs && data.recentLogs.length > 0) {
            var logEl = document.getElementById('logConsole');
            if (logEl) {
                logEl.textContent = data.recentLogs.join('\n');
                logEl.scrollTop = logEl.scrollHeight;
            }
            var badge = document.getElementById('logCountBadge');
            if (badge) badge.textContent = data.recentLogs.length + ' events';
        }

        // Highlight Milestone Steps
        var stepDown = document.getElementById('step-download');
        var stepExt = document.getElementById('step-extract');
        var stepCopy = document.getElementById('step-copy');
        var stepRec = document.getElementById('step-recycle');

        stepDown.className = 'step-item';
        stepExt.className = 'step-item';
        stepCopy.className = 'step-item';
        stepRec.className = 'step-item';

        if (data.stage === 'downloading') {
            stepDown.className = 'step-item active';
        } else if (data.stage === 'extracting') {
            stepDown.className = 'step-item done';
            stepExt.className = 'step-item active';
        } else if (data.stage === 'copying') {
            stepDown.className = 'step-item done';
            stepExt.className = 'step-item done';
            stepCopy.className = 'step-item active';
        } else if (data.stage === 'recycling') {
            stepDown.className = 'step-item done';
            stepExt.className = 'step-item done';
            stepCopy.className = 'step-item done';
            stepRec.className = 'step-item active';
        }

        if (data.stage === 'complete') {
            clearInterval(pollTimer);
            stepDown.className = 'step-item done';
            stepExt.className = 'step-item done';
            stepCopy.className = 'step-item done';
            stepRec.className = 'step-item done';
            showSuccess(data.message);
        } else if (data.stage === 'error') {
            clearInterval(pollTimer);
            showError(data.error || data.message || 'An error occurred during update.');
        }
    }

    function showSuccess(msg) {
        isUpdating = false;
        document.getElementById('modalActiveView').style.display = 'none';
        document.getElementById('modalCompleteView').style.display = 'block';
        if (msg) document.getElementById('completeSummary').textContent = msg;

        var seconds = 5;
        var countdownEl = document.getElementById('redirectCountdown');
        countdownEl.textContent = seconds;

        countdownTimer = setInterval(function() {
            seconds--;
            countdownEl.textContent = seconds;
            if (seconds <= 0) {
                clearInterval(countdownTimer);
                window.location.href = 'index.aspx';
            }
        }, 1000);
    }

    function showError(err) {
        isUpdating = false;
        document.getElementById('btnStartOta').disabled = false;
        document.getElementById('modalActiveView').style.display = 'none';
        document.getElementById('modalErrorView').style.display = 'block';
        document.getElementById('errorSummary').textContent = err;
    }

    // Auto-resume check on page load
    window.addEventListener('DOMContentLoaded', function() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'va_system_update.aspx?action=status&t=' + Date.now(), true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data.isRunning) {
                        isUpdating = true;
                        showOverlay();
                        startPolling();
                    }
                } catch(e) { }
            }
        };
        xhr.send();
    });
</script>
</body>
</html>

