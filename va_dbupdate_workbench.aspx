<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_dbupdate_workbench.aspx.cs" Inherits="va_dbupdate_workbench"
    ResponseEncoding="utf-8" Async="true" %>

    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">

    <head runat="server">
        <meta charset="utf-8" />
        <title>VA Import Workbench &mdash; Separator &amp; Header Configuration</title>
        <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
        <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />

        <style>
            /* ============================================================
   GLOBAL &mdash; Matches va_dbupdate + iDash system
   ============================================================ */

            :root {
                --chip-br:  var(--line);
                --wb-purple: #a855f7;
                --wb-teal:   #14b8a6;
                --wb-amber:  #f59e0b;
                --wb-green:  #10b981;
                --wb-blue:   #2ea8ff;
            }

            [data-theme="light"] {
                --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
                --ok-text: #166534;
                --ok-bg: rgba(34,197,94,0.12);
                --ok-border: rgba(34,197,94,0.3);
                --err-text: #991b1b;
                --err-bg: rgba(239,68,68,0.1);
                --err-border: rgba(239,68,68,0.3);
                --warn-text: #92400e;
                --warn-bg: rgba(245,158,11,0.12);
                --warn-border: rgba(217,119,6,0.4);
            }

            body {
                background: var(--bg);
                color: var(--text);
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                margin: 0;
                font-size: 14px;
            }

            * {
                box-sizing: border-box;
            }


            /* ============================================================
   LAYOUT: SIDEBAR + MAIN
   ============================================================ */

            .app {
                display: flex;
                min-height: 100vh;
            }

            .side {
                width: 260px;
                background: var(--chip);
                border-right: 1px solid var(--line);
                padding: 24px;
                color: var(--text);
                display: flex;
                flex-direction: column;
            }

            .side h1 {
                margin-top: 0;
                font-size: 18px;
                margin-bottom: 4px;
                font-weight: 600;
                color: var(--wb-purple);
            }

            .subtitle {
                font-size: 12px;
                color: var(--muted);
                margin-bottom: 30px;
            }

            .nav .group {
                margin-bottom: 24px;
            }

            .nav h3 {
                margin: 0 0 10px;
                font-size: 11px;
                text-transform: uppercase;
                letter-spacing: .08em;
                color: var(--muted);
                opacity: 0.7;
            }

            .nav .item {
                width: 100%;
                background: transparent;
                color: var(--text);
                border: 1px solid transparent;
                padding: 10px 12px;
                border-radius: 6px;
                text-align: left;
                margin-bottom: 4px;
                cursor: pointer;
                font-size: 14px;
                font-weight: 500;
                transition: all 0.2s ease;
            }

            .nav .item:hover {
                background: rgba(255, 255, 255, 0.05);
                color: #fff;
            }

            .nav .item.wb-primary {
                background: var(--wb-purple);
                color: #fff;
                font-weight: 600;
            }

            .nav .item.wb-primary:hover {
                filter: brightness(1.15);
            }

            .help {
                font-size: 11px;
                color: var(--muted);
                margin-top: 6px;
                margin-left: 12px;
                line-height: 1.4;
                opacity: 0.7;
            }

            .main {
                flex: 1;
                padding: 36px 50px;
                max-width: 1400px;
            }

            .header {
                display: flex;
                justify-content: space-between;
                align-items: flex-start;
                margin-bottom: 28px;
                gap: 20px;
            }

            .header-right {
                display: flex;
                gap: 8px;
                align-items: center;
                flex-shrink: 0;
                margin-top: 2px;
            }

            .nav-pill {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                padding: 7px 14px;
                border-radius: 8px;
                font-size: 12px;
                font-weight: 600;
                text-decoration: none;
                border: 1px solid var(--line);
                color: var(--text);
                cursor: pointer;
                background: var(--card);
                transition: all .15s;
            }

            .nav-pill:hover {
                border-color: var(--accent);
                color: var(--accent);
                background: color-mix(in srgb, var(--accent) 8%, transparent);
            }

            .page-title {
                font-size: 26px;
                font-weight: 700;
                margin: 0 0 6px;
                color: var(--text);
            }

            .page-sub {
                color: var(--muted);
                font-size: 13px;
                line-height: 1.5;
            }


            /* ============================================================
   PANELS, FIELDSETS, LEGEND
   ============================================================ */

            .panel,
            fieldset {
                background: var(--card);
                border: 1px solid var(--line);
                border-radius: 8px;
                padding: 24px;
                margin-bottom: 30px;
            }

            legend {
                padding: 0 10px;
                color: var(--wb-purple);
                font-size: 13px;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            h2 {
                margin: 0 0 24px 0;
                font-weight: 300;
                font-size: 28px;
                color: var(--text);
            }

            h3.section-title {
                margin: 0 0 16px;
                font-weight: 600;
                font-size: 15px;
                color: var(--wb-purple);
            }


            /* ============================================================
   FORM ROWS
   ============================================================ */

            .row {
                margin-bottom: 24px;
                display: flex;
                align-items: flex-start;
                gap: 30px;
                border-bottom: 1px solid rgba(255, 255, 255, 0.03);
                padding-bottom: 24px;
            }

            .row:last-child {
                border-bottom: none;
                margin-bottom: 0;
                padding-bottom: 0;
            }

            .label-group {
                width: 260px;
                flex-shrink: 0;
            }

            .label-text {
                display: block;
                font-weight: 600;
                color: var(--text);
                margin-bottom: 6px;
                font-size: 14px;
            }

            .label-sub {
                display: block;
                font-size: 12px;
                color: var(--muted);
                line-height: 1.4;
                font-family: Consolas, "Courier New", monospace;
                opacity: 0.8;
            }

            .input-group {
                flex: 1;
                display: flex;
                align-items: center;
                flex-wrap: wrap;
                gap: 12px;
            }

            input[type="file"] {
                font-family: inherit;
                font-size: 13px;
                color: var(--text);
                padding: 8px;
                background: var(--chip);
                border-radius: 4px;
                border: 1px solid var(--line);
                width: 100%;
            }


            /* ============================================================
   BUTTONS
   ============================================================ */

            .btn {
                padding: 10px 24px;
                background: var(--wb-purple);
                color: #fff;
                border-radius: 6px;
                border: 1px solid var(--wb-purple);
                cursor: pointer;
                font-weight: 600;
                font-size: 14px;
                transition: all 0.2s;
            }

            .btn:hover {
                filter: brightness(1.15);
                box-shadow: 0 0 15px rgba(168, 85, 247, 0.3);
            }

            .btn.secondary {
                background: var(--btn-alt);
                border-color: var(--line);
                color: var(--text);
            }

            .btn.secondary:hover {
                border-color: var(--wb-purple);
                color: var(--wb-purple);
            }

            .btn.test {
                background: var(--wb-amber);
                border-color: #d97706;
            }

            .btn.test:hover {
                filter: brightness(1.1);
                box-shadow: 0 0 15px rgba(245, 158, 11, 0.3);
            }

            .btn.commit {
                background: var(--wb-green);
                border-color: #059669;
            }

            .btn.commit:hover {
                filter: brightness(1.1);
                box-shadow: 0 0 15px rgba(16, 185, 129, 0.3);
            }

            .btn[disabled] {
                opacity: 0.5;
                cursor: not-allowed;
                filter: grayscale(1);
            }

            .ddl {
                width: 100%;
                padding: 10px 12px;
                background: var(--chip);
                color: var(--text);
                border: 1px solid var(--line);
                border-radius: 6px;
                font-size: 14px;
                font-family: Consolas, 'Courier New', monospace;
                cursor: pointer;
            }

            .ddl:focus {
                border-color: var(--wb-purple);
                outline: none;
                box-shadow: 0 0 0 2px rgba(168, 85, 247, 0.2);
            }

            .small {
                font-size: 12px;
                color: var(--muted);
                margin-top: 8px;
                font-style: italic;
            }


            /* ============================================================
   SEPARATOR RADIO BUTTONS
   ============================================================ */

            .sep-group {
                display: flex;
                gap: 20px;
                align-items: center;
                flex-wrap: wrap;
            }

            .sep-group label {
                display: flex;
                align-items: center;
                gap: 6px;
                cursor: pointer;
                padding: 8px 14px;
                border: 1px solid var(--line);
                border-radius: 6px;
                transition: all 0.2s;
                font-weight: 500;
            }

            .sep-group label:hover {
                border-color: var(--wb-purple);
            }

            .sep-group input[type="radio"] {
                accent-color: var(--wb-purple);
            }

            .sep-group input[type="radio"]:checked + span {
                color: var(--wb-purple);
                font-weight: 600;
            }

            .custom-sep-input {
                width: 50px;
                padding: 6px 10px;
                text-align: center;
                background: var(--chip);
                color: var(--text);
                border: 1px solid var(--line);
                border-radius: 4px;
                font-family: Consolas, 'Courier New', monospace;
                font-size: 16px;
                font-weight: 700;
            }

            .custom-sep-input:focus {
                border-color: var(--wb-purple);
                outline: none;
            }


            /* ============================================================
   STATUS BOXES
   ============================================================ */

            .ok {
                color:var(--ok-text, var(--accent-2));
                background: var(--ok-bg, color-mix(in srgb, var(--accent-2), transparent 85%));
                border: 1px solid var(--ok-border, color-mix(in srgb, var(--accent-2), transparent 85%));
                padding: 16px;
                border-radius: 6px;
                margin: 20px 0;
                line-height: 1.6;
            }

            .err {
                color: var(--err-text, #fecaca);
                background: var(--err-bg, color-mix(in srgb, var(--danger), transparent 85%));
                border: 1px solid var(--err-border, color-mix(in srgb, var(--danger), transparent 85%));
                padding: 16px;
                border-radius: 6px;
                margin: 20px 0;
            }

            .warn {
                color: var(--warn-text, #fde68a);
                background: var(--warn-bg, rgba(245,158,11,0.1));
                border: 1px solid var(--warn-border, #d97706);
                padding: 16px;
                border-radius: 6px;
                margin: 20px 0;
                line-height: 1.6;
            }


            /* ============================================================
   PREVIEW GRID
   ============================================================ */

            .preview-wrap {
                overflow-x: auto;
                margin-top: 16px;
                border: 1px solid var(--line);
                border-radius: 8px;
            }

            .preview-table {
                width: 100%;
                border-collapse: collapse;
                font-size: 12px;
                font-family: Consolas, 'Courier New', monospace;
                white-space: nowrap;
            }

            .preview-table th {
                background: color-mix(in srgb, var(--wb-purple), transparent 85%);
                color: var(--wb-purple);
                padding: 10px 12px;
                text-align: left;
                font-weight: 700;
                border-bottom: 2px solid var(--wb-purple);
                position: sticky;
                top: 0;
                z-index: 1;
            }

            .preview-table td {
                padding: 8px 12px;
                border-bottom: 1px solid rgba(255,255,255,0.03);
                max-width: 250px;
                overflow: hidden;
                text-overflow: ellipsis;
            }

            .preview-table tr:hover td {
                background: rgba(168, 85, 247, 0.05);
            }

            .preview-table .row-num {
                color: var(--muted);
                font-size: 11px;
                width: 40px;
                text-align: right;
                opacity: 0.5;
            }


            /* ============================================================
   HEADER MAPPING GRID
   ============================================================ */

            .map-grid {
                display: grid;
                grid-template-columns: 1fr 30px 1fr;
                gap: 8px;
                align-items: center;
                max-width: 700px;
            }

            .map-grid .map-header {
                font-weight: 700;
                font-size: 11px;
                text-transform: uppercase;
                letter-spacing: 0.06em;
                color: var(--muted);
                padding-bottom: 8px;
                border-bottom: 1px solid var(--line);
            }

            .map-grid .file-col {
                padding: 8px 12px;
                background: var(--chip);
                border: 1px solid var(--line);
                border-radius: 4px;
                font-family: Consolas, 'Courier New', monospace;
                font-size: 13px;
                font-weight: 600;
            }

            .map-grid .arrow {
                text-align: center;
                color: var(--wb-purple);
                font-size: 16px;
            }

            .map-grid .ddl-map {
                padding: 8px 10px;
                background: var(--chip);
                color: var(--text);
                border: 1px solid var(--line);
                border-radius: 4px;
                font-size: 13px;
                font-family: Consolas, 'Courier New', monospace;
            }

            .map-grid .ddl-map:focus {
                border-color: var(--wb-purple);
                outline: none;
            }

            .map-grid .ddl-map.mapped {
                border-color: var(--wb-green);
                color: var(--wb-green);
            }

            .map-grid .ddl-map.unmapped {
                border-color: var(--wb-amber);
                color: var(--wb-amber);
            }


            /* ============================================================
   SQL VIEWER
   ============================================================ */

            .sql-viewer {
                background: #0d1117;
                color: #c9d1d9;
                border: 1px solid var(--line);
                border-radius: 8px;
                padding: 16px 20px;
                font-family: Consolas, 'Courier New', monospace;
                font-size: 12px;
                line-height: 1.6;
                max-height: 400px;
                overflow: auto;
                white-space: pre-wrap;
                word-break: break-all;
                margin-top: 12px;
            }


            /* ============================================================
   DIFF TABLE
   ============================================================ */

            .diff-table {
                width: 100%;
                border-collapse: collapse;
                font-size: 12px;
                margin-top: 12px;
            }

            .diff-table th {
                background: var(--chip);
                color: var(--muted);
                padding: 8px 12px;
                text-align: left;
                border-bottom: 1px solid var(--line);
                font-size: 11px;
                text-transform: uppercase;
                letter-spacing: 0.05em;
            }

            .diff-table td {
                padding: 8px 12px;
                border-bottom: 1px solid rgba(255,255,255,0.03);
            }

            .diff-add {
                background: rgba(16, 185, 129, 0.08) !important;
                color: var(--wb-green);
            }

            .diff-del {
                background: rgba(239, 68, 68, 0.08) !important;
                color: #ef4444;
                text-decoration: line-through;
            }

            .diff-unchanged {
                color: var(--muted);
                opacity: 0.6;
            }

            .chip {
                display: inline-block;
                padding: 2px 8px;
                border-radius: 4px;
                font-size: 11px;
                font-weight: 600;
            }

            .chip-insert {
                background: rgba(16, 185, 129, 0.15);
                color: var(--wb-green);
            }

            .chip-update {
                background: rgba(46, 168, 255, 0.15);
                color: var(--wb-blue);
            }

            .chip-skip {
                background: rgba(255,255,255,0.05);
                color: var(--muted);
            }


            /* ============================================================
   PROFILE PANEL
   ============================================================ */

            .profile-bar {
                display: flex;
                align-items: center;
                gap: 12px;
                padding: 12px 16px;
                background: color-mix(in srgb, var(--wb-teal), transparent 92%);
                border: 1px solid color-mix(in srgb, var(--wb-teal), transparent 70%);
                border-radius: 6px;
                margin-bottom: 20px;
            }

            .profile-bar .profile-label {
                font-size: 12px;
                color: var(--wb-teal);
                font-weight: 600;
                white-space: nowrap;
            }


            /* ============================================================
   RUNNING BOX (same as va_dbupdate)
   ============================================================ */

            #runningBox {
                display: none;
                background: var(--chip);
                border: 1px solid var(--wb-purple);
                color: var(--text);
                padding: 20px 24px;
                border-radius: 8px;
                margin: 20px 0;
                line-height: 1.7;
            }

            #runningBox .run-header {
                display: flex;
                align-items: center;
                font-size: 16px;
                font-weight: 600;
                margin-bottom: 12px;
            }

            #runningBox .run-spinner {
                width: 20px;
                height: 20px;
                border: 3px solid var(--line);
                border-top: 3px solid var(--wb-purple);
                border-radius: 50%;
                animation: spin 0.8s linear infinite;
                margin-right: 12px;
                flex-shrink: 0;
            }

            @keyframes spin {
                to { transform: rotate(360deg); }
            }

            #runningBox .run-timer {
                font-size: 28px;
                font-family: Consolas, 'Courier New', monospace;
                font-weight: 700;
                color: var(--wb-purple);
                margin-top: 12px;
                letter-spacing: 1px;
            }

            #runningBox .run-tip {
                font-size: 12px;
                color: var(--muted);
                font-style: italic;
                margin-top: 10px;
            }


            /* ============================================================
   STEP INDICATOR
   ============================================================ */

            .steps-bar {
                display: flex;
                gap: 0;
                margin-bottom: 30px;
            }

            .step-pill {
                flex: 1;
                padding: 12px 16px;
                text-align: center;
                font-size: 12px;
                font-weight: 600;
                color: var(--muted);
                background: var(--chip);
                border: 1px solid var(--line);
                transition: all 0.3s;
                position: relative;
            }

            .step-pill:first-child {
                border-radius: 8px 0 0 8px;
            }

            .step-pill:last-child {
                border-radius: 0 8px 8px 0;
            }

            .step-pill.active {
                background: color-mix(in srgb, var(--wb-purple), transparent 85%);
                color: var(--wb-purple);
                border-color: var(--wb-purple);
            }

            .step-pill.done {
                background: color-mix(in srgb, var(--wb-green), transparent 90%);
                color: var(--wb-green);
                border-color: color-mix(in srgb, var(--wb-green), transparent 60%);
            }

            .step-num {
                display: inline-block;
                width: 20px;
                height: 20px;
                line-height: 20px;
                text-align: center;
                border-radius: 50%;
                background: var(--line);
                color: var(--text);
                font-size: 11px;
                font-weight: 700;
                margin-right: 6px;
            }

            .step-pill.active .step-num {
                background: var(--wb-purple);
                color: #fff;
            }

            .step-pill.done .step-num {
                background: var(--wb-green);
                color: #fff;
            }
        </style>
    </head>


    <body>
        <form id="form1" runat="server" enctype="multipart/form-data">

            <div class="app">

                <!-- ====================== SIDEBAR ====================== -->
                <aside class="side">

                    <h1>&#128295; Import Workbench</h1>
                    <div class="subtitle">Separator &amp; Header Config Tool</div>

                    <div class="nav">

                        <div class="group">
                            <h3>Workbench</h3>

                            <asp:Button runat="server" CssClass="item wb-primary" Text="Parse and Preview"
                                OnClick="BtnParse_Click" />
                            <div class="help">Read file with chosen separator and preview data.</div>
                        </div>

                        <div class="group">
                            <h3>Actions</h3>

                            <asp:Button runat="server" CssClass="item" Text="Test Run (Dry Run)"
                                OnClick="BtnTestRun_Click" />
                            <div class="help">Execute SQL with rollback. Zero risk preview.</div>

                            <asp:Button runat="server" CssClass="item" Text="Commit Import"
                                OnClick="BtnCommitImport_Click"
                                OnClientClick="return confirm('This will permanently write data to the database. Are you sure?');" />
                            <div class="help">Execute SQL for real. Permanent changes.</div>
                        </div>

                        <div class="group">
                            <h3>Related Tools</h3>

                            <asp:Button runat="server" CssClass="item" Text="&#8592; Manual DB Update"
                                OnClientClick="window.location.href='va_dbupdate.aspx'; return false;" />
                            <div class="help">Classic manual database upload page.</div>
                        </div>

                    </div>

                </aside>


                <!-- ====================== MAIN CONTENT ====================== -->
                <main class="main">

                    <div class="header">
                        <div>
                            <div class="page-title">&#128295; DB Update Workbench &amp; SQL Staging</div>
                            <div class="page-sub">Separator detection, column mapping, dry-run SQL preview, and database staging.</div>
                        </div>
                        <div class="header-right">
                            <button type="button" class="nav-pill" id="themeBtn" onclick="toggleTheme()" title="Toggle light/dark">☀️</button>
                            <a href="documentation/va_dbupdate_workbench.html" class="nav-pill">&#128214; View Docs</a>
                            <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
                        </div>
                    </div>

                    <!-- STEP INDICATOR -->
                    <div class="steps-bar">
                        <div class="step-pill" id="stepPill1" runat="server">
                            <span class="step-num">1</span> Configure &amp; Parse
                        </div>
                        <div class="step-pill" id="stepPill2" runat="server">
                            <span class="step-num">2</span> Map Headers
                        </div>
                        <div class="step-pill" id="stepPill3" runat="server">
                            <span class="step-num">3</span> Test SQL
                        </div>
                        <div class="step-pill" id="stepPill4" runat="server">
                            <span class="step-num">4</span> Results
                        </div>
                    </div>

                    <!-- Status messages -->
                    <asp:Literal ID="LitStatus" runat="server" EnableViewState="false" />
                    <asp:Literal ID="LitSummary" runat="server" EnableViewState="false" />
                    <asp:Literal ID="LitPreviewTable" runat="server" EnableViewState="false" />

                    <asp:HiddenField ID="HidCurrentStep" runat="server" Value="1" />
                    <asp:HiddenField ID="HidRowCount" runat="server" Value="0" />

                    <!-- Running box -->
                    <div id="runningBox">
                        <div class="run-header">
                            <div class="run-spinner"></div>
                            Processing...
                        </div>
                        <div class="run-timer" id="runTimer">00:00</div>
                        <div class="run-tip">&#128161; This page will automatically refresh when processing completes. Do not close or navigate away.</div>
                    </div>


                    <!-- ========== STEP 1: CONFIGURE & PARSE ========== -->
                    <fieldset>
                        <legend>1. Configure &amp; Parse</legend>

                        <!-- Profile loader -->
                        <div class="profile-bar">
                            <span class="profile-label">&#128190; Load Profile:</span>
                            <asp:DropDownList ID="DdlProfile" runat="server" CssClass="ddl" style="flex:1; max-width:300px;" />
                            <asp:Button ID="BtnLoadProfile" runat="server" CssClass="btn secondary" style="font-size:12px; padding:6px 14px;"
                                Text="Load" OnClick="BtnLoadProfile_Click" />
                        </div>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">Field Separator</span>
                                <span class="label-sub">How columns are separated in your data file. The VA currently uses Tab but is moving to Pipe.</span>
                            </div>
                            <div class="input-group">
                                <div class="sep-group">
                                    <label style="border-color:var(--wb-green);">
                                        <asp:RadioButton ID="RbAutoDetect" runat="server" GroupName="Sep" Checked="true" />
                                        <span style="color:var(--wb-green);">Auto-detect</span>
                                    </label>
                                    <label>
                                        <asp:RadioButton ID="RbTab" runat="server" GroupName="Sep" />
                                        <span>Tab <code>\t</code></span>
                                    </label>
                                    <label>
                                        <asp:RadioButton ID="RbPipe" runat="server" GroupName="Sep" />
                                        <span>Pipe <code>|</code></span>
                                    </label>
                                    <label>
                                        <asp:RadioButton ID="RbComma" runat="server" GroupName="Sep" />
                                        <span>Comma <code>,</code></span>
                                    </label>
                                    <label>
                                        <asp:RadioButton ID="RbCustom" runat="server" GroupName="Sep" />
                                        <span>Custom:</span>
                                    </label>
                                    <asp:TextBox ID="TxtCustomSep" runat="server" CssClass="custom-sep-input" MaxLength="1" />
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">Skip Rows</span>
                                <span class="label-sub">Number of non-data rows to skip at the top of the file (e.g., report headers)</span>
                            </div>
                            <div class="input-group">
                                <asp:TextBox ID="TxtSkipRows" runat="server" CssClass="custom-sep-input" Text="0"
                                    style="width:60px; text-align:center;" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">File Headers</span>
                                <span class="label-sub">Uncheck if the file has no header row &mdash; columns will be auto-numbered and matched by position to the SQL script</span>
                            </div>
                            <div class="input-group">
                                <label style="display:flex; align-items:center; gap:8px; cursor:pointer;">
                                    <asp:CheckBox ID="ChkHasHeaders" runat="server" Checked="true" />
                                    <span>First data row contains column headers</span>
                                </label>
                            </div>
                        </div>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">Data File</span>
                                <span class="label-sub">Select from server (.xlsx, .txt, .csv)<br />
                                    <a href="#" onclick="document.getElementById('pnlUploadFallback').style.display = document.getElementById('pnlUploadFallback').style.display === 'none' ? 'block' : 'none'; return false;" style="font-size:11px;">or upload manually &darr;</a></span>
                            </div>
                            <div class="input-group">
                                <asp:DropDownList ID="DdlDataFile" runat="server" CssClass="ddl" />
                                <asp:Literal ID="LitRowInfo" runat="server" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">SQL Script</span>
                                <span class="label-sub">Select from server (.sql)</span>
                            </div>
                            <div class="input-group">
                                <asp:DropDownList ID="DdlSqlScript" runat="server" CssClass="ddl" />
                            </div>
                        </div>

                        <!-- Collapsible upload fallback -->
                        <div id="pnlUploadFallback" style="display:none; border-top:1px solid var(--line); margin-top:16px; padding-top:16px;">
                            <div style="font-size:12px; color:var(--muted); margin-bottom:12px; font-style:italic;">Manual upload (overrides dropdown selection above):</div>
                            <div class="row">
                                <div class="label-group">
                                    <span class="label-text">Upload Data File</span>
                                    <span class="label-sub">.xlsx, .txt, or .csv</span>
                                </div>
                                <div class="input-group">
                                    <asp:FileUpload ID="FileDataUpload" runat="server" />
                                </div>
                            </div>
                        </div>

                        <div style="margin-top:16px; display:flex; gap:12px; align-items:center;">
                            <asp:Button ID="BtnParse" runat="server" CssClass="btn" Text="Parse and Preview"
                                OnClick="BtnParse_Click" />
                            <asp:Button ID="BtnRefreshFiles" runat="server" CssClass="btn secondary" style="font-size:12px; padding:8px 14px;"
                                Text="Refresh File Lists" OnClick="BtnRefreshFiles_Click" />
                        </div>

                        <div class="small">* .xlsx files will be converted to delimited text (UTF-8) using the selected separator before processing.</div>
                    </fieldset>

                    <!-- PARSE PREVIEW OUTPUT -->
                    <asp:Literal ID="LitParsePreview" runat="server" EnableViewState="false" />


                    <!-- ========== STEP 2: HEADER MAPPING ========== -->
                    <asp:Panel ID="PnlHeaderMapping" runat="server" Visible="false">
                        <fieldset>
                            <legend>2. Header Mapping</legend>
                            <p style="color:var(--muted); font-size:13px; margin-top:0;">
                                Map each file column to the corresponding <code>AssetFileRaw</code> database column.
                                Columns with exact name matches are auto-mapped. Use <strong>-- Skip --</strong> for columns you don't want to import.
                            </p>

                            <asp:Literal ID="LitHeaderMap" runat="server" />

                            <!-- Dynamic mapping dropdowns are generated server-side -->
                            <asp:PlaceHolder ID="PhMappingControls" runat="server" />

                            <div style="margin-top:20px; display:flex; gap:12px; align-items:center;">
                                <asp:Button ID="BtnApplyMapping" runat="server" CssClass="btn" Text="Apply Mapping and Generate SQL"
                                    OnClick="BtnApplyMapping_Click" />
                            </div>
                        </fieldset>
                    </asp:Panel>


                    <!-- ========== STEP 3: GENERATED SQL & TEST ========== -->
                    <asp:Panel ID="PnlSqlPreview" runat="server" Visible="false">
                        <fieldset>
                            <legend>3. Generated SQL &amp; Test</legend>

                            <h3 class="section-title">Modified SQL Script</h3>
                            <p style="color:var(--muted); font-size:13px; margin-top:0;">
                                This is the SQL that will be executed. The <code>FIELDTERMINATOR</code> and <code>AssetFileRaw</code> columns
                                have been automatically rewritten to match your separator and header mapping.
                            </p>

                            <asp:Literal ID="LitSqlViewer" runat="server" />

                            <div style="margin-top:20px; display:flex; gap:12px; align-items:center; flex-wrap:wrap;">
                                <asp:Button ID="BtnTestRun" runat="server" CssClass="btn test" Text="Test Run (Dry Run)"
                                    OnClick="BtnTestRun_Click" />
                                <asp:Button ID="BtnCommitImport" runat="server" CssClass="btn commit" Text="Commit Import"
                                    OnClick="BtnCommitImport_Click"
                                    OnClientClick="return confirm('This will permanently write data to the database. Continue?');" />
                                <asp:Button ID="BtnSaveProfile" runat="server" CssClass="btn secondary" style="font-size:12px; padding:8px 14px;"
                                    Text="Save Configuration Profile" OnClick="BtnSaveProfile_Click" />
                                <asp:Button ID="BtnDownloadSummary" runat="server" CssClass="btn secondary" style="font-size:12px; padding:8px 14px;"
                                    Text="Download Summary" Enabled="false" OnClick="BtnDownloadSummary_Click" />
                            </div>
                        </fieldset>
                    </asp:Panel>


                    <!-- ========== PROCESS OVERVIEW ========== -->
                    <fieldset>
                        <legend>Process Overview</legend>
                        <div style="color: var(--muted); font-size: 14px; line-height: 1.6;">
                            <p><strong>What is this page?</strong> The Import Workbench lets you configure VA data imports
                                with different separators (tab, pipe, comma) and remap column headers &mdash; then preview and test
                                the import before committing anything to the database.</p>
                            <p><strong>1. Configure:</strong> Choose your field separator and select a data file + SQL script.</p>
                            <p><strong>2. Parse &amp; Preview:</strong> The file is read with your chosen separator. You'll see
                                the first 25 rows in a grid to visually confirm columns are aligned correctly.</p>
                            <p><strong>3. Map Headers:</strong> If the file's column names don't exactly match the expected
                                <code>AssetFileRaw</code> columns, map them here. Auto-mapping handles exact matches.</p>
                            <p><strong>4. Test Run:</strong> The modified SQL is executed inside a transaction that is
                                immediately rolled back. You see import stats and affected records with zero database impact.</p>
                            <p><strong>5. Commit:</strong> When you're confident, click Commit to run the import for real.</p>
                            <p><strong>6. Save Profile:</strong> Save your separator + mapping as a profile so you can
                                one-click reload it next time the VA sends files in the same format.</p>
                        </div>
                    </fieldset>

                </main>

            </div>
        </form>


        <script>
            var _timerInterval = null;
            var _startTime = null;

            function formatTime(seconds) {
                var m = Math.floor(seconds / 60);
                var s = seconds % 60;
                return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
            }

            function showRunning() {
                var box = document.getElementById('runningBox');
                if (!box) return;
                box.style.display = 'block';

                _startTime = new Date();
                var timerEl = document.getElementById('runTimer');
                if (_timerInterval) clearInterval(_timerInterval);
                _timerInterval = setInterval(function() {
                    var elapsed = Math.floor((new Date() - _startTime) / 1000);
                    timerEl.innerText = formatTime(elapsed);
                }, 1000);
            }

            // Attach spinner to ALL postback buttons that may take time
            function attachSpinner(clientId) {
                var btn = document.getElementById(clientId);
                if (!btn) return;
                var origClick = btn.onclick;
                btn.onclick = function(e) {
                    showRunning();
                    if (origClick) return origClick.call(this, e);
                    return true;
                };
            }

            attachSpinner('<%= BtnParse.ClientID %>');
            attachSpinner('<%= BtnTestRun.ClientID %>');
            attachSpinner('<%= BtnCommitImport.ClientID %>');

            // Highlight the custom separator input when the Custom radio is selected
            var rbCustom = document.getElementById('<%= RbCustom.ClientID %>');
            var txtCustom = document.getElementById('<%= TxtCustomSep.ClientID %>');
            if (rbCustom && txtCustom) {
                rbCustom.onclick = function() { txtCustom.focus(); };
            }

            // Theme toggle
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
        </script>

    </body>

    </html>
