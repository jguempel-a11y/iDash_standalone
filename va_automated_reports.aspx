<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_automated_reports.aspx.cs" Inherits="va_automated_reports" MaintainScrollPositionOnPostback="true" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>System Automations</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <style>
        :root {
            --chip-br: var(--line);
            --success: var(--accent-2);
        }

        body {
            background: var(--bg);
            color: var(--text);
            font-family: Segoe UI, Tahoma, Arial, sans-serif;
            margin: 0;
            padding: 40px;
        }

        * { box-sizing: border-box; }

        .wrap { max-width: 900px; margin: auto; }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }

        h1 { margin: 0; font-size: 28px; }

        .panel {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 24px 30px;
            margin-bottom: 25px;
            box-shadow:var(--shadow);
        }

        .panel h2 {
            margin-top: 0;
            font-size: 18px;
            border-bottom: 1px solid var(--line);
            padding-bottom: 10px;
            margin-bottom: 20px;
            color: var(--accent);
        }

        .form-row { margin-bottom: 20px; }

        .form-label {
            display: block;
            margin-bottom: 6px;
            font-weight: 600;
            color: var(--muted);
            font-size: 14px;
        }

        .txt {
            width: 100%;
            padding: 12px;
            border-radius: 8px;
            background: var(--chip);
            border: 1px solid var(--chip-br);
            color: var(--text);
            font-family: Consolas, monospace;
            resize: vertical;
        }

        .btn {
            padding: 10px 20px;
            background: var(--accent);
            color: var(--bg);
            border-radius: 8px;
            border: 1px solid var(--accent);
            cursor: pointer;
            font-weight: 600;
            font-size: 15px;
            transition: 0.2s;
        }

        .btn:hover { filter: brightness(1.15); }
        .btn.secondary { background: transparent; color: var(--accent); }

        .toggle-row {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
            padding: 12px;
            background: var(--chip);
            border: 1px solid var(--chip-br);
            border-radius: 8px;
        }

        .toggle-row input[type="checkbox"] {
            width: 20px;
            height: 20px;
            margin-right: 15px;
            cursor: pointer;
        }

        .toggle-text strong {
            display: block;
            font-size: 15px;
            margin-bottom: 2px;
        }

        .toggle-text span {
            font-size: 13px;
            color: var(--muted);
        }

        .ok {
            background: color-mix(in srgb, var(--success) 10%, transparent);
            color: var(--success);
            padding: 14px;
            border-radius: 8px;
            border: 1px solid var(--success);
            margin-bottom: 20px;
        }

        .err {
            background: color-mix(in srgb, var(--danger) 10%, transparent);
            color: var(--danger);
            padding: 14px;
            border-radius: 8px;
            border: 1px solid var(--danger);
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="wrap">
            <div class="header">
                <div>
                    <h1>&#128227; System Automations</h1>
                    <div style="color:var(--muted); margin-top:4px;">Configure automated daily reports, email routing, and hardware alerts.</div>
                </div>
                <div>
                    <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    <asp:Button ID="BtnSaveTop" runat="server" CssClass="btn" Text="Save Configuration" OnClick="BtnSave_Click" style="margin-left:10px;" />
                </div>
            </div>

            <asp:Literal ID="LitStatus" runat="server" />

            <!-- SECTION 1: MASTER SWITCH -->
            <div class="panel" style="border-left: 5px solid var(--accent);">
                <h2>1. Global Master Switch</h2>
                <div class="toggle-row" style="border:none; background:transparent; padding:0;">
                    <asp:CheckBox ID="CbMasterSwitch" runat="server" />
                    <div class="toggle-text">
                        <strong>Enable SMS/Email Alerting Globally</strong>
                        <span>Unchecking this explicitly silences all outbound administrative texts instantly. Overrides all specific triggers below.</span>
                    </div>
                </div>
            </div>

            <!-- SECTION 2: RECIPIENTS -->
            <div class="panel">
                <h2>2. SMS Alert Recipients</h2>
                <div class="form-row">
                    <span class="form-label">Phone Numbers (Carrier Domain format, 1 per line):</span>
                    <asp:TextBox ID="TxtRecipients" runat="server" TextMode="MultiLine" Rows="5" CssClass="txt" placeholder="e.g. 5551234567@vtext.com&#10;5559876543@mms.att.net" />
                    <div style="font-size:12px; color:var(--muted); margin-top:8px;">
                        Standard domains: <strong>Verizon</strong> (@vtext.com) | <strong>AT&T</strong> (@mms.att.net) | <strong>T-Mobile</strong> (@tmomail.net)
                    </div>
                </div>
            </div>

            <!-- SECTION 3: TRIGGERS -->
            <div class="panel">
                <h2>3. Automated Event Triggers</h2>
                
                <div class="toggle-row" style="flex-wrap:wrap; display:block;">
                    <div style="display:flex; align-items:center; width:100%;">
                        <asp:CheckBox ID="CbAlertDbFolderMissing" runat="server" />
                        <div class="toggle-text">
                            <strong>Auto DB Update: Missing Folder</strong>
                            <span>Alerts you if the scheduled <code>va_autodbupdate.aspx</code> processor executes but cannot locate the \autoload ingest directory.</span>
                        </div>
                    </div>
                    <div style="margin-left:35px; margin-top:12px; padding-top:10px; border-top:1px dashed var(--chip-br);">
                        <span class="form-label" style="font-size:12px; color:var(--muted); margin-bottom:4px;">Custom Routing (Comma or Semicolon separated. Leave empty to use Global <strong>System Recipients</strong> from Section 2):</span>
                        <asp:TextBox ID="TxtRec_DbFolderMissing" runat="server" CssClass="txt" style="padding:8px; font-size:12px; height:auto;" placeholder="e.g. 5551234567@vtext.com" />
                    </div>
                </div>

                <div class="toggle-row" style="flex-wrap:wrap; display:block;">
                    <div style="display:flex; align-items:center; width:100%;">
                        <asp:CheckBox ID="CbAlertDbCrash" runat="server" />
                        <div class="toggle-text">
                            <strong>Auto DB Update: SQL Exceptions</strong>
                            <span>Alerts you if an active SQL Database transaction structurally crashes or aborts during the file ingestion phase.</span>
                        </div>
                    </div>
                    <div style="margin-left:35px; margin-top:12px; padding-top:10px; border-top:1px dashed var(--chip-br);">
                        <span class="form-label" style="font-size:12px; color:var(--muted); margin-bottom:4px;">Custom Routing (Comma or Semicolon separated. Leave empty to use Global <strong>System Recipients</strong> from Section 2):</span>
                        <asp:TextBox ID="TxtRec_DbCrash" runat="server" CssClass="txt" style="padding:8px; font-size:12px; height:auto;" placeholder="e.g. 5551234567@vtext.com" />
                    </div>
                </div>

                <div class="toggle-row" style="flex-wrap:wrap; display:block;">
                    <div style="display:flex; align-items:center; width:100%;">
                        <asp:CheckBox ID="CbAlertPrintFailure" runat="server" />
                        <div class="toggle-text">
                            <strong>Print Server: API Disruption</strong>
                            <span>Alerts you if the `Tag Team Scan` MQTT API spools a print job that throws an HTTP 500 fatal Internal Server Error.</span>
                        </div>
                    </div>
                    <div style="margin-left:35px; margin-top:12px; padding-top:10px; border-top:1px dashed var(--chip-br);">
                        <span class="form-label" style="font-size:12px; color:var(--muted); margin-bottom:4px;">Custom Routing (Comma or Semicolon separated. Leave empty to use Global <strong>System Recipients</strong> from Section 2):</span>
                        <asp:TextBox ID="TxtRec_PrintFailure" runat="server" CssClass="txt" style="padding:8px; font-size:12px; height:auto;" placeholder="e.g. 5551234567@vtext.com" />
                    </div>
                </div>

                <div class="toggle-row" style="flex-wrap:wrap; display:block;">
                    <div style="display:flex; align-items:center; width:100%;">
                        <asp:CheckBox ID="CbAlertTagAuditReport" runat="server" />
                        <div class="toggle-text">
                            <strong>Diagnostic Test: Tag Audit Report</strong>
                            <span>Alerts you seamlessly whenever any user actively generates or exports a `va_tag_audit_report.aspx` query. Useful for safely testing SMS carrier routing.</span>
                        </div>
                    </div>
                    <div style="margin-left:35px; margin-top:12px; padding-top:10px; border-top:1px dashed var(--chip-br);">
                        <span class="form-label" style="font-size:12px; color:var(--muted); margin-bottom:4px;">Custom Routing (Comma or Semicolon separated. Leave empty to use Global <strong>System Recipients</strong> from Section 2):</span>
                        <asp:TextBox ID="TxtRec_TagAuditReport" runat="server" CssClass="txt" style="padding:8px; font-size:12px; height:auto;" placeholder="e.g. 5551234567@vtext.com" />
                    </div>
                </div>

            </div>

            <!-- SECTION 4: EMAIL DELIVERY & SMTP SETTINGS -->
            <div class="panel">
                <h2>4. Email Delivery &amp; SMTP Settings</h2>
                <p style="font-size:13px;color:var(--muted);margin-bottom:20px;">
                    These settings control <em>all</em> outgoing email from iDash &mdash; ENNX reports, alert notifications, Tag Audit,
                    and automated daily reports all share the same <code>EmailHelper</code>.
                    Changes here write directly to <code>web.config</code> and take effect immediately for the next send.
                </p>

                <!-- SMTP Server -->
                <h3 style="font-size:14px;color:var(--accent);margin:0 0 14px;border-bottom:1px dashed var(--line);padding-bottom:8px;">SMTP Server Connection</h3>
                <div style="display:grid;grid-template-columns:1fr auto auto;gap:12px;margin-bottom:18px;align-items:end;">
                    <div class="form-row" style="margin:0;">
                        <span class="form-label">SMTP Host / Relay Server:</span>
                        <asp:TextBox ID="TxtSmtpHost" runat="server" CssClass="txt" style="height:auto;font-family:inherit;" placeholder="e.g. smtp.office365.com or localhost" />
                    </div>
                    <div class="form-row" style="margin:0;min-width:100px;">
                        <span class="form-label">Port:</span>
                        <asp:TextBox ID="TxtSmtpPort" runat="server" CssClass="txt" style="height:auto;font-family:inherit;" placeholder="25 or 587" />
                    </div>
                    <div class="form-row" style="margin:0;white-space:nowrap;">
                        <span class="form-label">&nbsp;</span>
                        <label style="display:flex;align-items:center;gap:8px;padding-top:6px;">
                            <asp:CheckBox ID="CbSmtpSsl" runat="server" />
                            <span style="font-size:13px;">Enable SSL / TLS</span>
                        </label>
                    </div>
                </div>

                <!-- SMTP Auth -->
                <h3 style="font-size:14px;color:var(--accent);margin:18px 0 14px;border-bottom:1px dashed var(--line);padding-bottom:8px;">SMTP Authentication (leave blank for anonymous / relay)</h3>
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:18px;">
                    <div class="form-row" style="margin:0;">
                        <span class="form-label">SMTP Username:</span>
                        <asp:TextBox ID="TxtSmtpUser" runat="server" CssClass="txt" style="height:auto;font-family:inherit;" placeholder="e.g. reports@yourdomain.com" />
                    </div>
                    <div class="form-row" style="margin:0;">
                        <span class="form-label">SMTP Password <span style="font-weight:400;color:var(--muted);">(leave blank to keep current)</span>:</span>
                        <asp:TextBox ID="TxtSmtpPassword" runat="server" CssClass="txt" TextMode="Password" style="height:auto;font-family:inherit;" placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;" />
                    </div>
                </div>
                <div style="background:color-mix(in srgb,#f59e0b 10%,transparent);border:1px solid color-mix(in srgb,#f59e0b 40%,transparent);border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;padding:10px 14px;font-size:12px;margin-bottom:20px;">
                    &#9888;&nbsp;<strong>Security:</strong> The SMTP password is stored in <code>web.config</code> in plain text (inherited from ASP.NET configuration).
                    Restrict file-system access to the web root via NTFS ACLs. For high-security environments, use a relay server that authenticates by IP rather than by username/password.
                </div>

                <!-- From Presentation -->
                <h3 style="font-size:14px;color:var(--accent);margin:18px 0 14px;border-bottom:1px dashed var(--line);padding-bottom:8px;">From Address &amp; Presentation</h3>
                <div style="background:color-mix(in srgb,var(--accent) 8%,transparent);border:1px solid color-mix(in srgb,var(--accent) 30%,transparent);border-radius:8px;padding:10px 14px;font-size:12px;margin-bottom:14px;display:flex;gap:10px;align-items:flex-start;">
                    <span style="flex-shrink:0;background:var(--accent);color:#fff;border-radius:50%;width:18px;height:18px;display:inline-flex;align-items:center;justify-content:center;font-weight:900;font-size:11px;">i</span>
                    <span><strong>Used by all iDash email:</strong> The From Address below applies to every email iDash sends &mdash;
                    ENNX exports, Tag Audit reports, system diagnostics, and automated daily reports all share the same sender.
                    There is no per-feature override; changing this affects everything.
                    <strong>Note:</strong> If using Office 365, the mailbox display name shown to recipients is controlled by M365 Admin, not this field.</span>
                </div>
                <div class="form-row" style="margin-top:0;">
                    <span class="form-label">"From" Email Address:</span>
                    <asp:TextBox ID="TxtEmailFromAddress" runat="server" CssClass="txt" style="height:auto;font-family:inherit;" placeholder="e.g. no-reply@example.com" />
                </div>

                <!-- ENNX Subject Template -->
                <h3 style="font-size:14px;color:var(--accent);margin:20px 0 12px;border-bottom:1px dashed var(--line);padding-bottom:8px;">ENNX Report Email Subject</h3>
                <div style="font-size:12px;color:var(--muted);margin-bottom:10px;">
                    This is the subject line used on each automated ENNX report email. Use <code style="background:var(--chip);padding:1px 5px;border-radius:4px;">{Site}</code> for the station number
                    and <code style="background:var(--chip);padding:1px 5px;border-radius:4px;">{Date}</code> for the report date &mdash; they are replaced automatically for each site when the report runs.
                </div>
                <div class="form-row" style="margin-top:0;">
                    <span class="form-label">Subject Template:</span>
                    <asp:TextBox ID="TxtEnnxSubject" runat="server" CssClass="txt"
                        style="height:auto;font-family:inherit;"
                        placeholder="e.g. iDash ENNX Report | Site {Site} | {Date}"
                        oninput="updateSubjectPreview(this.value);" />
                </div>
                <div style="margin-top:6px;font-size:12px;color:var(--muted);">
                    Preview: <span id="subjectPreview" style="color:var(--text);font-style:italic;">
                        <asp:Literal ID="LitSubjectPreview" runat="server" />
                    </span>
                </div>
                <script type="text/javascript">
                    function updateSubjectPreview(val) {
                        var el = document.getElementById('subjectPreview');
                        if (!el) return;
                        var today = new Date();
                        var mm = String(today.getMonth() + 1).padStart(2, '0');
                        var dd = String(today.getDate()).padStart(2, '0');
                        var yyyy = today.getFullYear();
                        var dateStr = mm + '-' + dd + '-' + yyyy;
                        el.textContent = (val || '').replace(/\{Site\}/g, '613').replace(/\{Date\}/g, dateStr);
                    }
                </script>

            </div>



            <!-- SECTION 5: AUTOMATED DAILY REPORTS -->
            <div class="panel" style="border-left: 5px solid #10b981;">
                <h2 style="color:#10b981;">5. Automated Daily Reports</h2>
                <div style="font-size:13px; color:var(--muted); margin-bottom:20px;">
                    These automated emails are triggered dynamically when the configured Windows Scheduled Task pings the backend <code>va_cron_daily.aspx</code> engine. 
                </div>

                <div class="toggle-row" style="flex-wrap:wrap; display:block;">
                    <div style="display:flex; align-items:center; width:100%;">
                        <asp:CheckBox ID="CbReportEnnx" runat="server" />
                        <div class="toggle-text">
                            <strong>Daily ENNX Extract Report</strong>
                            <span>Executes a system-wide lookup of all `EnnxLiveSession` blocks generated over the last 24 hours, bundles them into a master ENNX .txt format, and physically attaches it via Email.</span>
                        </div>
                    </div>
                    <div style="margin-left:35px; margin-top:12px; padding-top:10px; border-top:1px dashed var(--chip-br);">
                        <span class="form-label" style="font-size:12px; color:var(--muted); margin-bottom:4px;">PM Email Routing (Comma or Semicolon separated. Leave empty to forcefully use Global <strong>System Recipients</strong>):</span>
                        <asp:TextBox ID="TxtRec_ReportEnnx" runat="server" CssClass="txt" style="padding:8px; font-size:12px; height:auto;" placeholder="e.g. pm@company.com, supervisor@company.com" />
                    </div>
                </div>

                <div class="toggle-row" style="flex-wrap:wrap; display:block;">
                    <div style="display:flex; align-items:center; width:100%;">
                        <asp:CheckBox ID="CbReportStats" runat="server" />
                        <div class="toggle-text">
                            <strong>Daily Asset Statistics (All Sites CSV)</strong>
                            <span>Calculates a universal site-by-site rollup matching `va_asset_stats.aspx`, exposing total physical items strictly Tagged vs Untagged into an Excel .csv spreadsheet emailed natively.</span>
                        </div>
                    </div>
                    <div style="margin-left:35px; margin-top:12px; padding-top:10px; border-top:1px dashed var(--chip-br);">
                        <span class="form-label" style="font-size:12px; color:var(--muted); margin-bottom:4px;">PM Email Routing (Comma or Semicolon separated. Leave empty to forcefully use Global <strong>System Recipients</strong>):</span>
                        <asp:TextBox ID="TxtRec_ReportStats" runat="server" CssClass="txt" style="padding:8px; font-size:12px; height:auto;" placeholder="e.g. pm@company.com, supervisor@company.com" />
                    </div>
                </div>

            </div>

            <!-- SECTION 6: PER-SITE EMAIL ROUTING -->
            <div class="panel" style="border-left: 5px solid #a855f7;">
                <h2 style="color:#a855f7;">6. Per-Site Email Routing</h2>
                <div style="font-size:13px; color:var(--muted); margin-bottom:20px;">
                    Configure a separate recipient list for each site's daily ENNX report. When set, the report runner sends
                    each site's report <em>only</em> to that site's list, using the central SMTP account above.
                    Leave a site blank to fall back to <strong>Global System Recipients (Section 2)</strong>.
                </div>
                <div style="background:color-mix(in srgb,#a855f7 10%,transparent);border:1px solid color-mix(in srgb,#a855f7 40%,transparent);
                    border-radius:8px;padding:10px 16px;font-size:12px;margin-bottom:20px;">
                    &#8505;&nbsp;<strong>Multi-VISN deployment:</strong> One central SMTP account authenticates for all sites.
                    Each site station number can have its own supervisor/recipient list.
                    New sites are auto-discovered from the database when this page loads.
                </div>

                <asp:Literal ID="LitSiteConfig" runat="server" />

                <div style="margin-top:20px;">
                    <asp:Button ID="BtnSaveSiteConfig" runat="server" Text="Save Per-Site Routing"
                        OnClick="BtnSaveSiteConfig_Click"
                        style="background:#a855f7;color:#fff;border:none;border-radius:8px;
                        padding:11px 28px;font-size:14px;font-weight:700;cursor:pointer;" />
                </div>
                <asp:Literal ID="LitSiteConfigStatus" runat="server" />
            </div>

            <!-- SAVE ALL -->
            <div style="margin-top:10px; padding:20px 0; border-top:1px solid var(--line);">
                <!-- LitStatus and BtnSave already defined in page header area -->
            </div>

        </div>
    </form>
</body>
</html>

