<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_training_hub.aspx.cs" Inherits="va_training_hub" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash — AssetWorx Training & Setup Hub</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        body { margin:0; background:var(--bg); color:var(--text); font-family:'Segoe UI',system-ui,Arial,sans-serif; }
        .wrap { max-width:1200px; margin:0 auto; padding:24px 32px 64px; }

        /* Header */
        .hero { background:linear-gradient(135deg, var(--card) 0%, color-mix(in srgb, var(--accent), transparent 85%) 100%);
                border:1px solid var(--line); border-radius:16px; padding:36px 40px; margin-bottom:32px; }
        .hero h1 { margin:0 0 8px; font-size:28px; font-weight:800; }
        .hero h1 span { color:var(--accent); }
        .hero p { margin:0; color:var(--muted); font-size:14px; line-height:1.6; max-width:800px; }
        .hero-badges { display:flex; gap:8px; margin-top:14px; flex-wrap:wrap; }
        .hero-badges span { display:inline-flex; align-items:center; gap:4px; padding:4px 10px; border-radius:20px;
                           font-size:11px; font-weight:600; border:1px solid var(--line); background:var(--card); }
        .back-link { color:var(--accent); text-decoration:none; font-size:13px; font-weight:600; }
        .back-link:hover { text-decoration:underline; }

        /* Category sections */
        .cat { margin-bottom:36px; }
        .cat-header { display:flex; align-items:center; gap:12px; margin-bottom:16px; padding-bottom:10px; border-bottom:2px solid var(--line); }
        .cat-icon { font-size:28px; line-height:1; }
        .cat-title { font-size:20px; font-weight:700; }
        .cat-num { font-size:20px; font-weight:700; color:var(--muted); margin-left:4px; }
        .cat-sub { font-size:13px; color:var(--muted); margin-top:2px; }
        .cat-badge { font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:.5px; padding:3px 8px;
                    border-radius:4px; color:#fff; }

        /* Tool cards */
        .tools-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(340px, 1fr)); gap:14px; }
        .tool { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:18px 20px;
                transition:all .15s ease; position:relative; overflow:hidden; }
        .tool:hover { border-color:var(--accent); box-shadow:0 4px 20px rgba(0,0,0,.08); transform:translateY(-1px); }
        .tool-head { display:flex; align-items:flex-start; justify-content:space-between; gap:8px; margin-bottom:8px; }
        .tool-name { font-size:14px; font-weight:700; line-height:1.3; }
        .tool-desc { font-size:12px; color:var(--muted); line-height:1.5; margin-bottom:12px; }
        .tool-links { display:flex; gap:6px; flex-wrap:wrap; }
        .tool-links a { display:inline-flex; align-items:center; gap:4px; padding:4px 10px; border-radius:6px;
                       font-size:11px; font-weight:600; text-decoration:none; border:1px solid var(--line);
                       color:var(--text); background:var(--bg); transition:all .12s ease; }
        .tool-links a:hover { border-color:var(--accent); color:var(--accent); }
        .tool-links a.primary { background:var(--accent); color:#fff; border-color:var(--accent); }
        .tool-links a.primary:hover { opacity:.85; }
        .tool-step { position:absolute; top:12px; right:14px; font-size:20px; font-weight:800; color:var(--line); }

        /* Step sequence badges */
        .step-badge { display:inline-flex; align-items:center; justify-content:center; width:22px; height:22px;
                     border-radius:50%; background:var(--accent); color:#fff; font-size:11px; font-weight:700;
                     flex-shrink:0; margin-right:6px; }

        /* Checklist */
        .quick-start { background:color-mix(in srgb, var(--accent-2), transparent 92%); border:1px solid var(--accent-2);
                       border-radius:12px; padding:20px 24px; margin-bottom:32px; }
        .quick-start h3 { margin:0 0 12px; font-size:16px; font-weight:700; color:var(--accent-2); }
        .qs-steps { display:grid; grid-template-columns:repeat(auto-fill, minmax(280px, 1fr)); gap:8px; }
        .qs-step { display:flex; align-items:flex-start; gap:8px; font-size:13px; line-height:1.5; padding:8px 12px;
                  background:var(--card); border-radius:8px; border:1px solid var(--line); }
        .qs-step strong { white-space:nowrap; }
        .qs-step a { color:var(--accent); text-decoration:none; font-weight:600; }
        .qs-step a:hover { text-decoration:underline; }

        /* Upload slot */
        .upload-slot { background:var(--card); border:2px dashed var(--line); border-radius:12px; padding:24px;
                      text-align:center; margin-top:16px; }
        .upload-slot .icon { font-size:32px; margin-bottom:8px; }
        .upload-slot p { margin:0; color:var(--muted); font-size:13px; }
        .upload-slot strong { color:var(--text); }

        /* Status bar */
        .status-bar { display:flex; justify-content:space-between; align-items:center; padding:8px 32px;
                     background:var(--card); border-bottom:1px solid var(--line); font-size:12px; color:var(--muted); }
        .status-bar a { color:var(--accent); text-decoration:none; font-weight:600; }
        .status-bar a:hover { text-decoration:underline; }

        @media(max-width:768px) {
            .wrap { padding:16px; }
            .hero { padding:24px; }
            .hero h1 { font-size:22px; }
            .tools-grid { grid-template-columns:1fr; }
            .qs-steps { grid-template-columns:1fr; }
        }
    </style>
</head>
<body>
<form id="form1" runat="server">

    <div class="status-bar">
        <span>iDash &mdash; AssetWorx Training &amp; Setup Hub</span>
        <span>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
            &nbsp;&bull;&nbsp;
            <a href="documentation/index.aspx">Documentation Portal</a>
        </span>
    </div>

    <div class="wrap">

        <!-- HERO -->
        <div class="hero">
            <div style="display:flex; align-items:flex-start; justify-content:space-between; flex-wrap:wrap; gap:16px;">
                <div>
                    <h1>&#127891; AssetWorx <span>Training &amp; Setup Hub</span></h1>
                    <p>Your one-stop guide to setting up, configuring, and operating AssetWorx with iDash.
                       Every tool is linked to its page and its documentation &mdash; follow the numbered workflow
                       to deploy a new site, or jump to any section for day-to-day operations.</p>
                    <div class="hero-badges">
                        <span>&#128187; Web UI</span>
                        <span>&#128241; RFID Scanners</span>
                        <span>&#128200; Reports</span>
                        <span>&#128295; Database Tools</span>
                        <span>&#128274; User Management</span>
                        <span>&#128218; Full Documentation</span>
                    </div>
                </div>
                <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
            </div>
        </div>

        <!-- QUICK START CHECKLIST -->
        <div class="quick-start">
            <h3>&#9889; New Deployment Quick Start (Follow in Order)</h3>
            <div class="qs-steps">
                <div class="qs-step">
                    <span class="step-badge">1</span>
                    <div><strong>Install AssetWorx</strong><br/>Install the AssetWorx server application. <em style="color:var(--muted);">(Upload guide coming soon)</em></div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">2</span>
                    <div><strong>Configure iDash</strong><br/><a href="va_site_config.aspx">Site Config</a> &mdash; set DB connection, API keys, email</div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">3</span>
                    <div><strong>Create Company</strong><br/><a href="va_site_config.aspx#sec-sql">Company Setup SQL</a> &mdash; register station in DB</div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">4</span>
                    <div><strong>Create Scanner &amp; Portal Users</strong><br/><a href="va_user_management.aspx">User Mgmt (Consolidated)</a> &mdash; RFID &amp; web accounts</div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">5</span>
                    <div><strong>Import &amp; Sync Data</strong><br/><a href="va_sitedata_export.aspx">Cart Data &amp; Sync Hub</a> &mdash; Excel, tab, CSV Smart Merge</div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">6</span>
                    <div><strong>Manage Licenses &amp; Carts</strong><br/><a href="va_license_manager.aspx">License Manager</a> &mdash; reader slots &amp; cart keys</div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">7</span>
                    <div><strong>Configure Reports</strong><br/><a href="va_automated_reports.aspx">Report Automation</a> &mdash; daily ENNX &amp; email</div>
                </div>
                <div class="qs-step">
                    <span class="step-badge">8</span>
                    <div><strong>Verify &amp; Go Live</strong><br/><a href="index.aspx">iDash Hub</a> &mdash; check connection status &amp; tiles</div>
                </div>
            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 1. INITIAL SETUP & INSTALLATION -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128295;</span>
                <div>
                    <div class="cat-title">Initial Setup &amp; Installation <span class="cat-num">#1</span></div>
                    <div class="cat-sub">Server installation, database creation, site configuration, and first-time setup</div>
                </div>
                <span class="cat-badge" style="background:#3b82f6;">START HERE</span>
            </div>
            <div class="tools-grid">

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#127759; New Site Deployment Configuration</div>
                    </div>
                    <div class="tool-desc">
                        Update database connection, API/OAuth credentials, SMTP email, and execute the one-time company setup SQL.
                        <strong>This is the first thing you do</strong> after installing iDash on a new VISN server.
                    </div>
                    <div class="tool-links">
                        <a href="va_site_config.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_site_config.html">&#128196; Docs</a>
                    </div>
                    <div class="tool-step">1</div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128293; Database Restore</div>
                    </div>
                    <div class="tool-desc">
                        Restore the AssetWorx database from a <code>.bak</code> backup file.
                        Use when setting up a new server from an existing site's backup or recovering from failure.
                    </div>
                    <div class="tool-links">
                        <a href="va_db_restore.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_db_restore.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128218; iDash Deployment Guide</div>
                    </div>
                    <div class="tool-desc">
                        Complete step-by-step guide for deploying iDash on a new Windows Server:
                        IIS setup, file copy, web.config, SQL permissions, and verification checklist.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/idash_deployment_guide.html" class="primary">&#128196; Read Guide</a>
                        <a href="documentation/idi_deployment_guide.html">&#128196; IDI Guide</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128268; System Architecture</div>
                    </div>
                    <div class="tool-desc">
                        Technical overview of how AssetWorx, iDash, IIS, SQL Server, and the API layer connect.
                        Read this to understand the full stack before making changes.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_system_architecture.html" class="primary">&#128196; Read Guide</a>
                        <a href="documentation/idash_architecture_rationale.html">&#128196; Architecture Deep Dive</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; Network &amp; Connectivity</div>
                    </div>
                    <div class="tool-desc">
                        Firewall rules, port requirements (80, 443, 587, 1433), and VA network-specific configuration.
                        Includes scanner Wi-Fi setup and VPN considerations.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_network_guidelines.html" class="primary">&#128196; Network Guide</a>
                        <a href="documentation/va_network_server_install.html">&#128196; Server Install</a>
                    </div>
                </div>

                <div class="upload-slot" id="installGuideSlot">
                    <div class="icon">&#128229;</div>
                    <p><strong>AssetWorx Installation Guide</strong><br/>
                    Upload the official AssetWorx install document here when ready.<br/>
                    It will be linked into this training module automatically.</p>
                </div>
            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 2. USER & ACCESS MANAGEMENT -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128101;</span>
                <div>
                    <div class="cat-title">User &amp; Access Management <span class="cat-num">#2</span></div>
                    <div class="cat-sub">Create accounts for RFID scanner operators, web users, and portal administrators</div>
                </div>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid #a855f7;">
                    <div class="tool-head">
                        <div class="tool-name">&#128100; User Management (Consolidated)</div>
                    </div>
                    <div class="tool-desc">
                        One page for all user and site administration. Manage <strong>iDash Portal Users</strong> (roles, per-tile access, site permissions),
                        <strong>AssetWorx &amp; RFID Scanner Users</strong> (dbo.sysuser passwords, RFID IDs, mobile handheld access),
                        and <strong>Companies / Sites</strong> (add, rename, and cascade cleanup).<br/>
                        <span style="color:var(--warn); font-weight:600;">&#9888; Sign in with <code>assetworxadmin</code> for full administrative access.</span>
                    </div>
                    <div class="tool-links">
                        <a href="va_user_management.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_user_management.html">&#128196; Docs</a>
                    </div>
                    <div class="tool-step">4</div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128274; Scanner Security &amp; Authentication</div>
                    </div>
                    <div class="tool-desc">
                        Security model for RFID scanner authentication: how passwords are hashed (PBKDF2-SHA256),
                        session management, and scanner-to-API authentication flow.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/scan_security_notes.html" class="primary">&#128196; Security Guide</a>
                        <a href="documentation/va_aw_user_management.html">&#128196; User Mgmt Docs</a>
                    </div>
                </div>

            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 3. DATA IMPORT & DATABASE MANAGEMENT -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128190;</span>
                <div>
                    <div class="cat-title">Data Import &amp; Database Management <span class="cat-num">#3</span></div>
                    <div class="cat-sub">Import VA data, manage SQL scripts, automate updates, and maintain the database</div>
                </div>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid var(--accent); background:color-mix(in srgb, var(--accent), transparent 96%);">
                    <div class="tool-head">
                        <div class="tool-name">&#128257; Cart Data &amp; Sync Hub (All-in-One Data Ingest &amp; Export)</div>
                    </div>
                    <div class="tool-desc">
                        The primary all-in-one data management and cross-cart synchronization tool. Ingests <strong>Excel (.xlsx)</strong>, <strong>tab-delimited (.txt)</strong>, and <strong>CSV</strong> with intelligent Smart Merge (preserves live cart scans while updating metadata), automated location provisioning, and multi-format export. Replaces standalone import tools.
                    </div>
                    <div class="tool-links">
                        <a href="va_sitedata_export.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_sitedata_export.html">&#128196; Docs</a>
                    </div>
                    <div class="tool-step">5</div>
                </div>

                <div class="tool" style="border-left:4px solid #10b981;">
                    <div class="tool-head">
                        <div class="tool-name">&#9654; Auto DB Update &amp; Watcher</div>
                    </div>
                    <div class="tool-desc">
                        Background folder watcher and scheduled database update processor. Monitors the autoload folder for incoming data files and runs automated SQL updates automatically.
                    </div>
                    <div class="tool-links">
                        <a href="va_autodbupdate.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_autodbupdate.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool" style="border-left:4px solid #a855f7;">
                    <div class="tool-head">
                        <div class="tool-name">&#128257; Field Server Sync (.BAK Restore)</div>
                    </div>
                    <div class="tool-desc">
                        Restore a field server <code>.bak</code> backup into staging, then merge updated asset and scan data into the central database for executive reporting.
                    </div>
                    <div class="tool-links">
                        <a href="va_field_sync.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_field_sync.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool" style="border-left:4px solid #f59e0b;">
                    <div class="tool-head">
                        <div class="tool-name">&#128295; DB Update Workbench &amp; SQL Staging</div>
                    </div>
                    <div class="tool-desc">
                        Advanced staging workbench. Test custom separators (tab, pipe, comma), preview SQL staging scripts with rollback, or apply manual database updates. Includes legacy manual DB update tools.
                    </div>
                    <div class="tool-links">
                        <a href="va_dbupdate_workbench.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_dbupdate_workbench.html">&#128196; Docs</a>
                        <a href="va_dbupdate.aspx">&#128190; Manual DB</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; Remote DB Update (PowerShell)</div>
                    </div>
                    <div class="tool-desc">
                        Run database imports from any workstation on the network using a PowerShell script.
                        Uses SqlBulkCopy instead of BULK INSERT &mdash; works when IIS and SQL Server are on separate machines.
                        Download the script, point it at your data file and server URL, and run.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_remote_import.html" class="primary">&#128196; How-To Guide</a>
                        <a href="downloads/Scripts/remote_db_update.ps1" download>&#128229; Download Script</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128190; SQL Upload &amp; Execute</div>
                    </div>
                    <div class="tool-desc">
                        Upload and execute raw SQL scripts directly against the database.
                        Use for one-off maintenance scripts, cleanup queries, and custom operations.
                    </div>
                    <div class="tool-links">
                        <a href="va_sql_upload.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_sql_upload.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128196; Excel Merge Tool</div>
                    </div>
                    <div class="tool-desc">
                        Merge equipment files from Excel spreadsheets with the site master data.
                        For non-standard data sources that don't follow the CDW/VistA export format.
                    </div>
                    <div class="tool-links">
                        <a href="va_excel.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_excel.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128268; VA Network BCP Queries (Pull)</div>
                    </div>
                    <div class="tool-desc">
                        Generate BCP extraction and SQLCMD batch scripts for pulling data
                        from VA network SQL servers into the local AssetWorx database.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_bcp_query.html" class="primary">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128228; AW Push to VA SQL (Push)</div>
                    </div>
                    <div class="tool-desc">
                        Reverse pipeline &mdash; generate BCP OUT and SQLCMD MERGE scripts
                        for pushing AssetWorx data back to VA SQL servers.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_bcp_awpush_query.html" class="primary">&#128196; Docs</a>
                    </div>
                </div>

            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 4. RFID SCANNING & TAGGING -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128225;</span>
                <div>
                    <div class="cat-title">RFID Scanning &amp; Tagging <span class="cat-num">#4</span></div>
                    <div class="cat-sub">Handheld scanner tools, team scanning, inventory sweeps, and ENNX generation</div>
                </div>
                <span class="cat-badge" style="background:#10b981;">DAILY OPS</span>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid #10b981;">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; Tag Team Scan</div>
                    </div>
                    <div class="tool-desc">
                        Multi-user team scanning dashboard with live ENNX generation.
                        Operators sign in with their RFID scanner accounts, scan rooms, and the system
                        builds an ENNX file in real-time.
                    </div>
                    <div class="tool-links">
                        <a href="va_tagteam_scan.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_tagteam_scan.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool" style="border-left:4px solid var(--accent-2);">
                    <div class="tool-head">
                        <div class="tool-name">&#128270; VA Site Inventory</div>
                    </div>
                    <div class="tool-desc">
                        Rapid location sweep interface. Pre-loads room assignments from the database,
                        then marks assets as found/moved as the operator scans through the building.
                    </div>
                    <div class="tool-links">
                        <a href="va_inventory.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_inventory.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; RFID Asset Locator</div>
                    </div>
                    <div class="tool-desc">
                        Locate specific missing assets using RFID proximity scanning. Geiger counter-style
                        proximity meter with audio feedback. DataWedge and WebSerial USB support.
                    </div>
                    <div class="tool-links">
                        <a href="va_rfid_locator.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_rfid_locator.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; ENNX Live Scan</div>
                    </div>
                    <div class="tool-desc">
                        Live asset scanning with immediate ENNX file generation.
                        Select a site, scan assets, and the ENNX output is built as you go.
                    </div>
                    <div class="tool-links">
                        <a href="va_ennx_live_scan.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_ennx_live_scan.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128270; EIL Live Scan &amp; Reconciliation</div>
                    </div>
                    <div class="tool-desc">
                        Load EIL parts list and reconcile against scanned assets in real-time.
                        Identifies missing equipment and location discrepancies.
                    </div>
                    <div class="tool-links">
                        <a href="va_eil_live_scan.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_eil_live_scan.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128228; Universal ENNX Creator</div>
                    </div>
                    <div class="tool-desc">
                        Build and download an ENNX file from any scanner data, regardless of source format.
                        Works with direct scan output, CSV uploads, and manual entry.
                    </div>
                    <div class="tool-links">
                        <a href="va_universal_ennx.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_universal_ennx.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128218; Mobile Connectivity Cookbook</div>
                    </div>
                    <div class="tool-desc">
                        Complete guide for setting up RFID handheld scanners (Zebra/TSL) to connect to the AssetWorx server.
                        Covers Wi-Fi, app install, API endpoint config, and troubleshooting.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/idi_mobile_connectivity_cookbook.html" class="primary">&#128196; Read Guide</a>
                        <a href="documentation/va_label_sop.html">&#128196; Label SOP</a>
                    </div>
                </div>

            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 5. PRINTING -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128424;</span>
                <div>
                    <div class="cat-title">Printing <span class="cat-num">#5</span></div>
                    <div class="cat-sub">Label templates, printer configuration, MQTT print routing, and multi-site print setup</div>
                </div>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid #10b981;">
                    <div class="tool-head">
                        <div class="tool-name">&#128424; Print Administration</div>
                    </div>
                    <div class="tool-desc">
                        Manage print templates, print clients (MQTT credentials), site readiness, and multi-site print configuration.
                        Quick Setup creates all required components for a new site in one click. Test print and live status monitoring.
                    </div>
                    <div class="tool-links">
                        <a href="va_print_admin.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_print_admin.html">&#128196; Master Guide</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128424; Printer Administration</div>
                    </div>
                    <div class="tool-desc">
                        All-in-one print management: templates, print clients, MQTT credentials, site readiness, config file sync, and template mapping configuration.
                    </div>
                    <div class="tool-links">
                        <a href="va_print_admin.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_print_admin.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128424; Printing Asset Labels (User Guide)</div>
                    </div>
                    <div class="tool-desc">
                        Step-by-step end-user guide for printing RFID labels from Asset Master.
                        Covers single, range, and comma-separated EE number input.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_printing_guide.html" class="primary">&#128196; Read Guide</a>
                        <a href="documentation/va_print_admin.html#routing">&#128196; Printer Routing</a>
                        <a href="documentation/va_print_admin.html#comparison">&#128196; Method Comparison</a>
                    </div>
                </div>

            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 6. MQTT & FIXED READERS -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128225;</span>
                <div>
                    <div class="cat-title">MQTT &amp; Fixed Readers <span class="cat-num">#6</span></div>
                    <div class="cat-sub">MQTT broker configuration, Zebra FX9600 fixed readers, RabbitMQ, and real-time location tracking</div>
                </div>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid #8B5CF6;">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; MQTT Fixed Reader Architecture</div>
                    </div>
                    <div class="tool-desc">
                        Complete architecture reference for Zebra FX9600 fixed RFID reader deployment.
                        Covers RabbitMQ (TRM-approved), MQTTnet embedded broker, database schemas,
                        location tracking pipeline, and deduplication strategies.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_mqtt_architecture.html" class="primary">&#128196; Architecture Guide</a>
                    </div>
                </div>

                <div class="tool" style="border-left:4px solid #06B6D4;">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; MQTT Configuration &amp; Print Server</div>
                    </div>
                    <div class="tool-desc">
                        MQTT broker settings, multi-site print client management, Print Server installation,
                        and the MasterPrint architecture. Covers <code>applicationsetting</code> fields,
                        <code>printclient</code> vs <code>mqttclient</code> tables, and BarTender integration.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_mqtt_config.html" class="primary">&#128196; Config Guide</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128225; Fixed Reader Configuration</div>
                    </div>
                    <div class="tool-desc">
                        Manage fixed RFID reader registrations, antenna port/power mappings, and live
                        online/offline status. Add, edit, delete readers and discover unregistered hardware.
                    </div>
                    <div class="tool-links">
                        <a href="va_reader_config.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_reader_config.html">&#128196; Docs</a>
                    </div>
                </div>

            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 7. REPORTS & ANALYTICS -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#128202;</span>
                <div>
                    <div class="cat-title">Reports &amp; Analytics <span class="cat-num">#7</span></div>
                    <div class="cat-sub">Asset statistics, CMR dashboards, inventory reports, ENNX exports, and data quality</div>
                </div>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid #10b981;">
                    <div class="tool-head">
                        <div class="tool-name">&#128203; Asset Master &mdash; Unified Reporting</div>
                    </div>
                    <div class="tool-desc">
                        One-stop asset reporting: server-side pagination (600K+ rows), 7 filter criteria,
                        toggleable columns, KPI cards, CSV/Excel export, print jobs, Asset Detail Panel
                        (5 tabbed views), and inline editing. Consolidates 6 legacy tiles.
                    </div>
                    <div class="tool-links">
                        <a href="va_asset_master.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_asset_master.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128202; Asset Overview &amp; Statistics</div>
                    </div>
                    <div class="tool-desc">
                        Dashboard showing total assets, assets by site, tag coverage rates,
                        and inventory status across all stations.
                    </div>
                    <div class="tool-links">
                        <a href="va_asset_stats.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_asset_stats.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128202; CMR Dashboard</div>
                    </div>
                    <div class="tool-desc">
                        CMR (Capital/Minor Repair) analytics &mdash; coverage rates, missing CMR values,
                        and tracking of tagged vs. untagged equipment by site and category.
                    </div>
                    <div class="tool-links">
                        <a href="va_cmr_stats.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_cmr_stats.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#127991; Tag Statistics</div>
                    </div>
                    <div class="tool-desc">
                        Tag type distribution, RFID read rates, and tagging progress by site.
                        Shows which assets have been physically tagged vs. database-only.
                    </div>
                    <div class="tool-links">
                        <a href="va_tag_stats.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_tag_stats.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#9989; Inventoried Report</div>
                    </div>
                    <div class="tool-desc">
                        Shows which assets have been scanned/inventoried and when.
                        Identifies overdue equipment and generates compliance summaries.
                    </div>
                    <div class="tool-links">
                        <a href="va_report_inventoried.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_report_inventoried.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128228; ENNX Batch Export</div>
                    </div>
                    <div class="tool-desc">
                        Generate and download ENNX files for submission to VistA.
                        Select site, date range, and format options for batch export.
                    </div>
                    <div class="tool-links">
                        <a href="va_ennx.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_ennx.html">&#128196; Docs</a>
                        <a href="documentation/ennxhistory.html">&#128196; ENNX History</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128200; Data Quality Inspector</div>
                    </div>
                    <div class="tool-desc">
                        Analyze data completeness, identify missing fields, orphaned records, and
                        data quality issues across the asset database.
                    </div>
                    <div class="tool-links">
                        <a href="va_data_quality.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_data_quality.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128269; Data Research &amp; Search</div>
                    </div>
                    <div class="tool-desc">
                        Search and explore asset data across all fields. Advanced filtering, location lookup,
                        and cross-reference tools for troubleshooting and research.
                    </div>
                    <div class="tool-links">
                        <a href="va_data_research.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_data_research.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128202; Tagging Activity Reports</div>
                    </div>
                    <div class="tool-desc">
                        Detailed tagging activity summaries showing operator productivity,
                        rooms completed, and daily scan counts.
                    </div>
                    <div class="tool-links">
                        <a href="va_idi_tagging_reports.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_idi_tagging_reports.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128197; Report Automation</div>
                    </div>
                    <div class="tool-desc">
                        Configure automated daily ENNX and stats report emails.
                        Set delivery schedule, recipients, and which reports to include.
                    </div>
                    <div class="tool-links">
                        <a href="va_automated_reports.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/report.html">&#128196; Docs</a>
                    </div>
                </div>

            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- 8. ADMINISTRATION & MONITORING -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="cat">
            <div class="cat-header">
                <span class="cat-icon">&#9881;</span>
                <div>
                    <div class="cat-title">Administration &amp; Monitoring <span class="cat-num">#8</span></div>
                    <div class="cat-sub">System logs, API reference, email/SMS, VA integrations, and documentation</div>
                </div>
            </div>
            <div class="tools-grid">

                <div class="tool" style="border-left:4px solid #ef4444;">
                    <div class="tool-head">
                        <div class="tool-name">&#128273; License Manager &amp; Cart Licenses</div>
                    </div>
                    <div class="tool-desc">
                        Unified license management. View active reader and handheld slots, delete stale scanners to free licenses, manage server registrations, and access VISN 5 mobile cart keys (Beckley Cart 1 &amp; 2) with 1-click apply scripts.
                    </div>
                    <div class="tool-links">
                        <a href="va_license_manager.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_license_manager.html">&#128196; Docs</a>
                        <a href="documentation/va_cart_licenses.html">&#128196; Cart Reference</a>
                    </div>
                </div>

                <div class="tool" style="border-left:4px solid #f59e0b;">
                    <div class="tool-head">
                        <div class="tool-name">&#128202; System Diagnostics &amp; Health Monitor</div>
                    </div>
                    <div class="tool-desc">
                        Run live platform health checks: API authentication, license validation, server registrations, and batch update simulation. Send HTML diagnostic reports via email.
                    </div>
                    <div class="tool-links">
                        <a href="va_system_diagnostics.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_system_diagnostics.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool" style="border-left:4px solid #ef4444;">
                    <div class="tool-head">
                        <div class="tool-name">&#128640; System Update &amp; Deploy</div>
                    </div>
                    <div class="tool-desc">
                        Deploy code updates to this server via ZIP upload or generate deployment scripts to sync code changes to mobile cart endpoints across Tailscale.
                    </div>
                    <div class="tool-links">
                        <a href="va_system_update.aspx" class="primary">&#9654; Open Tool</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128221; System Logs &amp; Diagnostics</div>
                    </div>
                    <div class="tool-desc">
                        View DB update logs, Field Sync logs, and links to IIS application logs.
                        First place to check when something goes wrong.
                    </div>
                    <div class="tool-links">
                        <a href="va_log_viewer.aspx" class="primary">&#9654; Open Tool</a>
                        <a href="documentation/va_log_viewer.html">&#128196; Docs</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#9993; Email &amp; Notifications</div>
                    </div>
                    <div class="tool-desc">
                        Configure email recipients, SMTP settings, and automated report notifications.
                        Manage who receives automated ENNX reports and system alerts.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_email_recipient_storage.html" class="primary">&#128196; Email Config</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128268; Asset API Reference</div>
                    </div>
                    <div class="tool-desc">
                        Technical reference for the AssetWorx REST API endpoints.
                        Covers authentication, token flow, and available endpoints for asset operations.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_asset_api.html" class="primary">&#128196; API Docs</a>
                        <a href="documentation/aw_scan_api.html">&#128196; Scan API</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#127973; VA Integration &amp; ENNX Push</div>
                    </div>
                    <div class="tool-desc">
                        Push ENNX data to AEMS/MERS, VALIP integration architecture, and FHIR Bridge
                        (deprecated &mdash; supply chain only). Covers all VA enterprise integration paths.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/va_ennx_vista_push.html" class="primary">&#128196; ENNX Push</a>
                        <a href="documentation/va_valip_integration.html">&#128196; VALIP</a>
                        <a href="va_fhir_bridge.aspx">&#9654; FHIR Bridge</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128196; All Documentation</div>
                    </div>
                    <div class="tool-desc">
                        Complete documentation portal with every guide organized by category:
                        Scanning, Printing, MQTT, Reporting, Database, Security, VA Integration, and Architecture.
                    </div>
                    <div class="tool-links">
                        <a href="documentation/index.aspx" class="primary">&#128196; Open Docs Portal</a>
                    </div>
                </div>

                <div class="tool">
                    <div class="tool-head">
                        <div class="tool-name">&#128736; Script Downloads</div>
                    </div>
                    <div class="tool-desc">
                        Download all SQL scripts, setup files, and deployment resources.
                        Includes the full script library for manual database operations.
                    </div>
                    <div class="tool-links">
                        <a href="va_downloads.aspx" class="primary">&#9654; Downloads</a>
                    </div>
                </div>

            </div>
        </div>

    </div>

</form>
</body>
</html>
