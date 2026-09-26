<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_dbupdate.aspx.cs" Inherits="va_dbupdate"
    ResponseEncoding="utf-8" Async="true" %>

    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">

    <head runat="server">
        <meta charset="utf-8" />
        <title>VA iDash DB Update</title>
        <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
        <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />

        <style>
            /* ============================================================
   GLOBAL COLOR SYSTEM &mdash; MATCHES va_autodbupdate + report.aspx
   ============================================================ */

            :root {
                --chip-br:  var(--line);
            }

            [data-theme="light"] {
                --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
                --ok-text: #166534;         /* green-800 */
                --ok-bg: rgba(34,197,94,0.12);
                --ok-border: rgba(34,197,94,0.3);
                --err-text: #991b1b;        /* red-800 */
                --err-bg: rgba(239,68,68,0.1);
                --err-border: rgba(239,68,68,0.3);
                --warn-text: #92400e;       /* amber-800 */
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
                font-size: 20px;
                margin-bottom: 4px;
                font-weight: 600;
                color: var(--accent);
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
                /* var(--chip-br); */
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

            .nav .item.primary {
                background: var(--accent);
                color: #000;
                font-weight: 600;
            }

            .nav .item.primary:hover {
                filter: brightness(1.1);
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
                max-width: 1200px;
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
   PANELS & FIELDSETS
   ============================================================ */

            .panel,
            fieldset {
                background: var(--card);
                border: 1px solid var(--line);
                border-radius: 8px;
                padding: 24px;
                margin-bottom: 30px;
                /* box-shadow: 0 4px 6px rgba(0,0,0,0.1); */
            }

            legend {
                padding: 0 10px;
                color: var(--accent);
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
                width: 280px;
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
            }

            /* Custom file input styling tweak */
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

            .small {
                font-size: 12px;
                color: var(--muted);
                margin-top: 8px;
                font-style: italic;
            }


            /* ============================================================
   BUTTONS
   ============================================================ */

            .btn {
                padding: 10px 24px;
                background: var(--accent);
                color: #fff;
                border-radius: 6px;
                border: 1px solid var(--accent);
                cursor: pointer;
                font-weight: 600;
                font-size: 14px;
                transition: all 0.2s;
            }

            .btn:hover {
                background: #50b6ff;
                border-color: #50b6ff;
                box-shadow: 0 0 15px rgba(46, 168, 255, 0.3);
            }

            .btn.secondary {
                background: var(--btn-alt);
                border-color: var(--line);
                color: var(--text);
            }

            .btn.secondary:hover {
                border-color: var(--accent);
                color: var(--accent);
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
                border-color: var(--accent);
                outline: none;
                box-shadow: 0 0 0 2px rgba(46, 168, 255, 0.2);
            }

            .btn[disabled] {
                opacity: 0.5;
                cursor: not-allowed;
                filter: grayscale(1);
            }


            /* ============================================================
   STATUS BOXES
   ============================================================ */

            .ok {
                color:var(--ok-text, var(--accent-2));
                /* green-200 dark / green-800 light */
                background: var(--ok-bg, color-mix(in srgb, var(--accent-2), transparent 85%));
                border: 1px solid var(--ok-border, color-mix(in srgb, var(--accent-2), transparent 85%));
                padding: 16px;
                border-radius: 6px;
                margin: 20px 0;
                line-height: 1.6;
            }

            .err {
                color: var(--err-text, #fecaca);
                /* red-200 dark / red-800 light */
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

            /* Running box */
            #runningBox {
                display: none;
                background: var(--chip);
                border: 1px solid var(--accent);
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
                border-top: 3px solid var(--accent);
                border-radius: 50%;
                animation: spin 0.8s linear infinite;
                margin-right: 12px;
                flex-shrink: 0;
            }

            @keyframes spin {
                to { transform: rotate(360deg); }
            }

            #runningBox .run-stats {
                display: grid;
                grid-template-columns: auto 1fr;
                gap: 4px 16px;
                font-size: 14px;
                color: var(--muted);
            }

            #runningBox .run-stats .label {
                font-weight: 600;
                color: var(--text);
            }

            #runningBox .run-timer {
                font-size: 28px;
                font-family: Consolas, 'Courier New', monospace;
                font-weight: 700;
                color: var(--accent);
                margin-top: 12px;
                letter-spacing: 1px;
            }

            #runningBox .run-tip {
                font-size: 12px;
                color: var(--muted);
                font-style: italic;
                margin-top: 10px;
            }
        </style>
    </head>


    <body>
        <form id="form1" runat="server" enctype="multipart/form-data">

            <div class="app">

                <!-- ====================== SIDEBAR ====================== -->
                <aside class="side">

                    <h1>VA DB Update</h1>
                    <div class="subtitle">Manual Upload / Script Runner</div>

                    <div class="nav">

                        <div class="group">
                            <h3>Admin</h3>

                            <asp:Button runat="server" CssClass="item primary" Text="Run DB Update Script"
                                OnClick="BtnRunSql_Click" />

                            <div class="help">Execute SQL update script with a data file.</div>
                        </div>

                        <div class="group">
                            <h3>Automation</h3>

                            <asp:Button runat="server" CssClass="item" Text="Auto DB Update"
                                OnClientClick="window.location.href='va_autodbupdate.aspx'; return false;" />

                            <div class="help">Configure folder watcher and scheduled updates.</div>
                        </div>

                        <div class="group">
                            <h3>Related Tools</h3>

                            <asp:Button runat="server" CssClass="item" Text="&#8594; DB Update Workbench"
                                OnClientClick="window.location.href='va_dbupdate_workbench.aspx'; return false;" />
                            <div class="help">Custom separator &amp; header mapping workbench.</div>
                        </div>

                    </div>

                </aside>


                <!-- ====================== MAIN CONTENT ====================== -->
                <main class="main">

                    <div class="header">
                        <div>
                            <div class="page-title">&#128451; Manual Database Update &amp; SQL Runner</div>
                            <div class="page-sub">Manual data file staging, bulk upload, and custom SQL update script execution.</div>
                        </div>
                        <div class="header-right">
                            <button type="button" class="nav-pill" id="themeBtn" onclick="toggleTheme()" title="Toggle light/dark">☀️</button>
                            <a href="documentation/va_dbupdate.html" class="nav-pill">&#128214; View Docs</a>
                            <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
                        </div>
                    </div>

                    <asp:Literal ID="LitSummary" runat="server" EnableViewState="false" />
                    <asp:Literal ID="LitPreviewTable" runat="server" EnableViewState="false" />
                    <asp:Literal ID="LitSqlResult" runat="server" EnableViewState="false" />
                    <asp:Literal ID="LitSqlNote" runat="server" EnableViewState="false" />

                    <asp:HiddenField ID="HidRowCount" runat="server" Value="0" />

                    <div id="runningBox">
                        <div class="run-header">
                            <div class="run-spinner"></div>
                            Processing Database Update...
                        </div>
                        <div class="run-stats">
                            <span class="label">Data File:</span>
                            <span id="runFileName">—</span>
                            <span class="label">SQL Script:</span>
                            <span id="runScriptName">—</span>
                            <span class="label">Rows:</span>
                            <span id="runRowCount">—</span>
                            <span class="label">Estimated Time:</span>
                            <span id="runEstimate">—</span>
                        </div>
                        <div class="run-timer" id="runTimer">00:00</div>
                        <div class="run-tip">&#128161; This page will automatically refresh when processing completes. Do not close or navigate away.</div>
                    </div>


                    <!-- STEP 1 -->
                    <fieldset>
                        <legend>1. Select Files & Options</legend>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">Data File</span>
                                <span class="label-sub">Select from server (.xlsx, .txt)<br />
                                    <a href="#" onclick="document.getElementById('pnlUploadFallback').style.display = document.getElementById('pnlUploadFallback').style.display === 'none' ? 'block' : 'none'; return false;" style="font-size:11px;">or upload manually &darr;</a></span>
                            </div>
                            <div class="input-group">
                                <asp:DropDownList ID="DdlDataFile" runat="server" CssClass="ddl" 
                                    AutoPostBack="true" OnSelectedIndexChanged="DdlDataFile_SelectedIndexChanged" />
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

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">Safety Options</span>
                                <span class="label-sub">Check to allow destructive commands (DROP, TRUNCATE,
                                    ALTER).</span>
                            </div>
                            <div class="input-group">
                                <asp:CheckBox ID="ChkAllowDangerous" runat="server" Text=" Allow dangerous SQL commands"
                                    style="color:var(--text); cursor:pointer;" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="label-group">
                                <span class="label-text">&nbsp;</span>
                            </div>
                            <div class="input-group">
                                <asp:Button ID="BtnRefreshFiles" runat="server" CssClass="btn secondary" style="font-size:12px; padding:6px 12px;"
                                    Text="&#8635; Refresh File Lists" OnClick="BtnRefreshFiles_Click" />
                            </div>
                        </div>

                        <!-- Collapsible upload fallback for manual file uploads -->
                        <div id="pnlUploadFallback" style="display:none; border-top:1px solid var(--line); margin-top:16px; padding-top:16px;">
                            <div style="font-size:12px; color:var(--muted); margin-bottom:12px; font-style:italic;">Manual upload (overrides dropdown selection above):</div>
                            <div class="row">
                                <div class="label-group">
                                    <span class="label-text">Upload Data File</span>
                                    <span class="label-sub">.xlsx or .txt</span>
                                </div>
                                <div class="input-group">
                                    <asp:FileUpload ID="FileDataUpload" runat="server" />
                                </div>
                            </div>
                            <div class="row">
                                <div class="label-group">
                                    <span class="label-text">Upload SQL Script</span>
                                    <span class="label-sub">.sql file</span>
                                </div>
                                <div class="input-group">
                                    <asp:FileUpload ID="FileSqlUpload" runat="server" />
                                </div>
                            </div>
                        </div>

                        <div class="small">* .xlsx files will be automatically converted to tab-delimited .txt (utf-8)
                            before processing. Files are read from the iDash application root.</div>
                    </fieldset>


                    <!-- STEP 2 -->
                    <fieldset>
                        <legend>2. Run & Summary</legend>

                        <asp:Button ID="BtnRunSql" runat="server" CssClass="btn" Text="Run DB Update Script"
                            OnClick="BtnRunSql_Click" />

                        <asp:Button ID="BtnPreviewRun" runat="server" CssClass="btn" 
                            style="background:#f59e0b; border-color:#d97706; margin-left:15px; margin-right:15px;" 
                            Text="Preview Run (Dry Run)"
                            OnClick="BtnPreviewRun_Click" />

                        <asp:Button ID="BtnDownloadSummary" runat="server" CssClass="btn secondary"
                            Text="Download Summary" Enabled="false" OnClick="BtnDownloadSummary_Click" />
                    </fieldset>

                    <!-- PROCESS OVERVIEW -->
                    <fieldset>
                        <legend>Process Overview</legend>
                        <div style="color: var(--muted); font-size: 14px; line-height: 1.6;">
                            <p><strong>1. File Selection & Conversion:</strong> Select a Data file and SQL Script from the 
                                server dropdowns (files are read from the iDash root). XLSX files are
                                automatically converted to tab-delimited format. Manual uploads override dropdown selections.</p>
                            <p><strong>2. Staging:</strong> Data is bulk-loaded into a raw staging table
                                (<code>dbo.AssetFileRaw</code>).</p>
                            <p><strong>3. Normalization:</strong> Data is mapped to temporary tables, generating RFID
                                tags (EPC) and normalizing dates and fields.</p>
                            <p><strong>4. Location Sync:</strong> New locations are identified from the data and
                                inserted into <code>dbo.location</code>. Duplicates are ignored.</p>
                            <p><strong>5. Asset Sync:</strong> New assets are inserted into <code>dbo.asset</code>.
                                Assets with existing RFID tags or duplicate Name/CompanyID combinations are skipped to
                                prevent duplicates.</p>
                            <p><strong>6. Cleanup & Linking:</strong> Legacy data (e.g., fields missing "SP" prefix) is
                                standardized, and assets are linked to their corresponding Location IDs.</p>
                            <p><strong>7. Reporting:</strong> A summary of inserted locations, assets, and skipped
                                duplicates is displayed and available for download.</p>
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

            function estimateTime(rows) {
                // Rough estimates based on observed performance
                if (rows <= 0) return 'Calculating...';
                if (rows < 5000) return 'Under 30 seconds';
                if (rows < 15000) return '30 seconds - 1 minute';
                if (rows < 30000) return '1 - 3 minutes';
                if (rows < 60000) return '3 - 5 minutes';
                if (rows < 100000) return '5 - 10 minutes';
                return '10+ minutes';
            }

            function showRunning() {
                var box = document.getElementById('runningBox');
                if (!box) return;

                // Read file names from dropdowns
                var ddlData = document.getElementById('<%= DdlDataFile.ClientID %>');
                var ddlSql = document.getElementById('<%= DdlSqlScript.ClientID %>');
                var fileData = document.getElementById('<%= FileDataUpload.ClientID %>');
                var fileSql = document.getElementById('<%= FileSqlUpload.ClientID %>');

                var dataName = (fileData && fileData.value) ? fileData.value.split('\\').pop() : (ddlData ? ddlData.options[ddlData.selectedIndex].text : '—');
                var sqlName = (fileSql && fileSql.value) ? fileSql.value.split('\\').pop() : (ddlSql ? ddlSql.options[ddlSql.selectedIndex].text : '—');

                document.getElementById('runFileName').innerText = dataName;
                document.getElementById('runScriptName').innerText = sqlName;

                // Row count from hidden field (set by server on previous postback, or 0)
                var hidRow = document.getElementById('<%= HidRowCount.ClientID %>');
                var rows = hidRow ? parseInt(hidRow.value, 10) || 0 : 0;
                document.getElementById('runRowCount').innerText = rows > 0 ? rows.toLocaleString() + ' rows' : 'Counting on server...';
                document.getElementById('runEstimate').innerText = rows > 0 ? estimateTime(rows) : 'Will display after file is read';

                box.style.display = 'block';

                // Start live timer
                _startTime = new Date();
                var timerEl = document.getElementById('runTimer');
                if (_timerInterval) clearInterval(_timerInterval);
                _timerInterval = setInterval(function() {
                    var elapsed = Math.floor((new Date() - _startTime) / 1000);
                    timerEl.innerText = formatTime(elapsed);
                }, 1000);
            }

            // Attach to both Run and Preview buttons
            var btn1 = document.getElementById('<%= BtnRunSql.ClientID %>');
            if (btn1) btn1.onclick = function() { showRunning(); return true; };

            var btn2 = document.getElementById('<%= BtnPreviewRun.ClientID %>');
            if (btn2) btn2.onclick = function() { showRunning(); return true; };

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

