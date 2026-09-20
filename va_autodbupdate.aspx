<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_autodbupdate.aspx.cs" Inherits="va_autodbupdate" ResponseEncoding="utf-8" ValidateRequest="false" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta charset="utf-8" />
<title>iDash System Logs &amp; DB Automation &mdash; iDash</title>
<link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
<link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="0" />

<style>


body {
    background: var(--bg);
    color: var(--text);
    font-family: Segoe UI, Tahoma, Arial, sans-serif;
    margin: 0;
}

* { box-sizing: border-box; }


/* ============================================================
   LAYOUT: SIDEBAR + MAIN AREA
   ============================================================ */

.app {
    display: flex;
    min-height: 100vh;
}

.side {
    width: 270px;
    background: var(--chip);
    border-right: 1px solid var(--line);
    padding: 22px;
    color: var(--text);
    box-shadow: 4px 0 20px rgba(0,0,0,.25);
    flex-shrink: 0;
}

.side h1 {
    margin-top: 0;
    font-size: 18px;
    margin-bottom: 2px;
    font-weight: 700;
    color: var(--accent);
}

.subtitle {
    font-size: 12px;
    color: var(--muted);
    margin-bottom: 22px;
    line-height: 1.5;
}

.nav .group {
    margin-bottom: 22px;
}

.nav h3 {
    margin: 0 0 8px;
    font-size: 11px;
    letter-spacing: .07em;
    text-transform: uppercase;
    color: var(--muted);
}

.nav .item {
    width: 100%;
    background: var(--chip);
    color: var(--text);
    border: 1px solid var(--chip-br);
    padding: 10px 12px;
    border-radius: 8px;
    text-align: left;
    margin-bottom: 8px;
    cursor: pointer;
    font-size: 13px;
    font-weight: 600;
    transition: background 0.15s, color 0.15s;
}

.nav .item:hover {
    background: var(--accent);
    color: #fff;
    border-color: var(--accent);
}

.nav .item.active {
    background: color-mix(in srgb, var(--accent), transparent 85%);
    border-color: var(--accent);
    color: var(--accent);
}

.help {
    font-size: 11px;
    color: var(--muted);
    margin-top: -2px;
    margin-bottom: 6px;
    padding-left: 2px;
    line-height: 1.4;
}

.nav-link {
    display: block;
    color: var(--accent);
    text-decoration: none;
    font-size: 13px;
    font-weight: 600;
    padding: 8px 10px;
    border-radius: 6px;
    border: 1px solid var(--chip-br);
    background: var(--chip);
    margin-bottom: 6px;
    transition: 0.15s;
}

.nav-link:hover { background: var(--accent); color: #fff; border-color: var(--accent); }

.main {
    flex: 1;
    padding: 32px 40px;
    max-width: 1200px;
}


/* ============================================================
   PANELS
   ============================================================ */

.panel {
    background: var(--card);
    border: 1px solid var(--line);
    border-radius: 14px;
    padding: 22px 26px;
    margin-bottom: 26px;
    box-shadow:var(--shadow);
}

.panel-title {
    font-size: 16px;
    font-weight: 700;
    color: var(--accent);
    margin: 0 0 4px;
}

.panel-sub {
    color: var(--muted);
    font-size: 13px;
    margin-bottom: 18px;
    line-height: 1.5;
}

h2 {
    margin-top: 0;
    margin-bottom: 4px;
    font-size: 22px;
}

.page-sub {
    color: var(--muted);
    font-size: 13px;
    margin-bottom: 26px;
    line-height: 1.6;
}


/* ============================================================
   FORM ROWS + INPUTS
   ============================================================ */

.form-row {
    display: flex;
    align-items: center;
    margin: 14px 0;
    gap: 12px;
}

.form-label {
    width: 220px;
    color: var(--muted);
    font-weight: 600;
    font-size: 13px;
    flex-shrink: 0;
}

.txt {
    flex: 1;
    padding: 10px 12px;
    border-radius: 8px;
    background: var(--chip);
    border: 1px solid var(--chip-br);
    color: var(--text);
    font-size: 13px;
}

.txt:focus { outline: none; border-color: var(--accent); }


/* ============================================================
   TABS
   ============================================================ */

.tab-bar {
    display: flex;
    gap: 8px;
    margin-bottom: 22px;
    border-bottom: 2px solid var(--line);
    padding-bottom: 0;
}

.tab-btn {
    background: transparent;
    border: none;
    border-bottom: 3px solid transparent;
    color: var(--muted);
    padding: 10px 20px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    border-radius: 0;
    margin-bottom: -2px;
    transition: color 0.2s, border-color 0.2s;
}

.tab-btn:hover { color: var(--text); }
.tab-btn.tab-active { color: var(--accent); border-bottom-color: var(--accent); }


/* ============================================================
   BUTTONS
   ============================================================ */

.btn {
    padding: 10px 18px;
    background: var(--accent);
    color: #fff;
    border-radius: 10px;
    border: 1px solid var(--accent);
    cursor: pointer;
    font-weight: 700;
    font-size: 13px;
    margin-right: 8px;
    transition: filter 0.15s;
}

.btn:hover { filter: brightness(1.15); }

.btn.green { background: var(--accent-2); border-color: var(--accent-2); }
.btn.warn  { background: var(--warn); border-color: var(--warn); color:var(--bg); }
.btn.ghost { background: transparent; border-color: var(--accent); color: var(--accent); }
.btn.danger { background: var(--danger); border-color: var(--danger); color: #fff; }


/* ============================================================
   STATUS / MESSAGES
   ============================================================ */

.ok {
    color: var(--ok-text);
    background: color-mix(in srgb, var(--accent-2), transparent 85%);
    border: 1px solid var(--accent-2);
    padding: 12px 16px;
    border-radius: 10px;
    margin: 10px 0;
    font-size: 14px;
}

.err {
    color: var(--err-text);
    background: color-mix(in srgb, var(--danger), transparent 85%);
    border: 1px solid var(--danger);
    padding: 12px 16px;
    border-radius: 10px;
    margin: 10px 0;
    font-size: 14px;
}

.info-box {
    color: var(--info-text);
    background: var(--info-bg);
    border: 1px solid var(--accent);
    padding: 12px 16px;
    border-radius: 10px;
    margin: 10px 0;
    font-size: 13px;
    line-height: 1.6;
}

.status { white-space: pre-wrap; font-family: Consolas, monospace; font-size: 13px; }

#runningBox {
    display: none;
    margin-top: 16px;
    padding: 14px;
    background: var(--chip);
    border: 1px solid var(--chip-br);
    border-radius: 10px;
    font-family: Consolas, monospace;
    color: var(--warn);
    font-size: 13px;
}


/* ============================================================
   LOG BOXES
   ============================================================ */

.logbox {
    max-height: 400px;
    overflow: auto;
    background: var(--chip);
    border: 1px solid var(--chip-br);
    border-radius: 10px;
    padding: 12px 14px;
    font-family: Consolas, monospace;
    font-size: 12px;
    white-space: pre-wrap;
    color: var(--log-text);
    line-height: 1.5;
}

.log-source-card {
    background: var(--chip);
    border: 1px solid var(--chip-br);
    border-radius: 10px;
    padding: 16px 20px;
    margin-bottom: 14px;
    display: flex;
    align-items: center;
    gap: 16px;
    cursor: pointer;
    transition: border-color 0.2s, background 0.2s;
    text-decoration: none;
}

.log-source-card:hover {
    border-color: var(--accent);
    background: color-mix(in srgb, var(--accent), transparent 95%);
}

.log-source-icon { font-size: 28px; flex-shrink: 0; }

.log-source-title {
    font-size: 15px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 3px;
}

.log-source-desc {
    font-size: 12px;
    color: var(--muted);
    line-height: 1.4;
}

/* KPI stat boxes */
.stat-row { display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.stat-box { background: var(--chip); border: 1px solid var(--chip-br); border-radius: 10px; padding: 12px 18px; flex: 1; min-width: 100px; }
.stat-val  { font-size: 22px; font-weight: 800; color: var(--accent); }
.stat-val.green { color: var(--accent-2); }
.stat-val.warn  { color: var(--warn); }
.stat-val.red   { color: var(--danger); }
.stat-lbl  { font-size: 11px; color: var(--muted); margin-top: 3px; text-transform: uppercase; letter-spacing: .04em; }

</style>
</head>


<body>

<form id="form1" runat="server">
<div class="app">

    <!-- ===================== SIDEBAR ======================= -->
    <aside class="side">

        <h1>&#128221; System Logs &amp; DB Automation</h1>
        <div class="subtitle">iDash central log viewer, DB update processor, and automation scheduler.</div>

        <asp:Literal ID="LitErr" runat="server" />

        <div class="nav">

            <div class="group">
                <h3>Log Viewer</h3>

                <asp:Button runat="server" CssClass="item" ID="BtnTabLogs"
                    Text="&#128196; System Log Viewer"
                    OnClick="BtnTabLogs_Click" />
                <div class="help">View DB update, Field Sync, and system logs in one place.</div>
            </div>

            <div class="group">
                <h3>DB Automation</h3>

                <asp:Button runat="server" CssClass="item"
                    Text="&#9654; Run DB Update"
                    ID="BtnRunSidebar"
                    OnClick="BtnRun_Click" />
                <div class="help">Scan watch folder and run the SQL update script immediately.</div>

                <asp:Button runat="server" CssClass="item"
                    ID="BtnViewLog"
                    Text="&#128336; View DB Update Log"
                    OnClick="BtnViewLog_Click" />
                <div class="help">Show recent entries from va_autodbupdate.log.</div>

                <asp:Button runat="server" CssClass="item"
                    ID="BtnClearLog"
                    Text="&#128465; Clear DB Update Log"
                    OnClick="BtnClearLog_Click" />
                <div class="help">Truncate the DB update log file. A timestamp marker will be added.</div>
            </div>

            <div class="group">
                <h3>Navigation</h3>
                <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                <a href="documentation/va_autodbupdate.html" class="nav-link">&#128214; View Docs</a>
                <a href="va_log_viewer.aspx" class="nav-link">&#128270; IIS &amp; App Log Analyzer</a>
                <a href="va_field_sync.aspx" class="nav-link">&#128257; Field Server Sync</a>
            </div>

        </div>

    </aside>


    <!-- ====================== MAIN CONTENT ======================== -->
    <main class="main">

        <h2>&#128221; iDash System Logs &amp; DB Automation</h2>
        <div class="page-sub">
            This page is the central operations hub for monitoring iDash system activity and running automated database updates.
            Use the <strong>System Log Viewer</strong> to inspect what happened and when. Use the <strong>DB Automation</strong>
            tools to manually trigger updates, view the processing log, or edit the SQL script that runs on each cycle.
        </div>

        <!-- Status for last operation (run / clear / errors) -->
        <asp:Literal ID="LitStatus" runat="server" />

        <!-- ═══════════════════════════════════════════════════
             TAB BAR &mdash; switches between Log Viewer and DB Update tabs
             ═══════════════════════════════════════════════════ -->
        <div class="tab-bar">
            <asp:Button ID="BtnTabLogView"  runat="server" Text="&#128196; System Log Viewer" CssClass="tab-btn tab-active" OnClick="BtnTabLogs_Click" />
            <asp:Button ID="BtnTabDbUpdate" runat="server" Text="&#9654; DB Automation"       CssClass="tab-btn" OnClick="BtnTabDbUpdate_Click" />
        </div>


        <!-- ═══════════════════════════════════════════════════
             TAB 1: SYSTEM LOG VIEWER
             ═══════════════════════════════════════════════════ -->
        <asp:Panel ID="PnlLogViewer" runat="server">

            <div class="info-box">
                <strong>&#128270; What is the System Log Viewer?</strong><br />
                This tab lets you view logs produced by iDash automation processes &mdash; all in one place.
                Each log source below is a different system component. Click <strong>View Log</strong> to load
                the most recent entries. Use the <strong>IIS &amp; App Log Analyzer</strong> link for more
                advanced filtering, charting, and error diagnosis of the full IIS web server logs.
            </div>

            <!-- DB Update Log -->
            <div class="panel">
                <div class="panel-title">&#128451; Database Update Log &nbsp;<code style="font-size:11px; font-weight:400; color:var(--muted);">va_autodbupdate.log</code></div>
                <div class="panel-sub">
                    Records every run of the <strong>Auto DB Update</strong> processor &mdash; including which files were found,
                    how many SQL batches executed, rows affected, and whether the run succeeded or errored.
                    Written to <code>C:\VA_RFID\va_dbupdate\autoload\va_autodbupdate.log</code>.
                </div>

                <div style="margin-bottom:12px;">
                    <asp:Button ID="BtnViewDbLog"   runat="server" CssClass="btn" Text="&#128196; Load DB Update Log" OnClick="BtnViewLog_Click" />
                    <asp:Button ID="BtnClearDbLog"  runat="server" CssClass="btn ghost" Text="Clear Log" OnClick="BtnClearLog_Click" />
                </div>

                <asp:Literal ID="LitStatusOutput" runat="server">
                    <div class="logbox" style="color:var(--muted); font-style:italic;">Click "Load DB Update Log" to view recent processing history.</div>
                </asp:Literal>
            </div>

            <!-- Field Sync Log -->
            <div class="panel">
                <div class="panel-title">&#128257; Field Server Sync Log &nbsp;<code style="font-size:11px; font-weight:400; color:var(--muted);">va_field_sync.log</code></div>
                <div class="panel-sub">
                    Records each run of the nightly <strong>Field Server Sync</strong> (.bak restore + merge) process.
                    Includes timestamps, restore status, merge counts (assets updated / inserted), and any errors.
                    Written to <code>C:\VA_RFID\va_sync\va_field_sync.log</code>.
                </div>

                <div style="margin-bottom:12px;">
                    <asp:Button ID="BtnViewFieldSyncLog"  runat="server" CssClass="btn green" Text="&#128257; Load Field Sync Log" OnClick="BtnViewFieldSyncLog_Click" />
                    <asp:Button ID="BtnClearFieldSyncLog" runat="server" CssClass="btn ghost" Text="Clear Log" OnClick="BtnClearFieldSyncLog_Click" />
                </div>

                <asp:Literal ID="LitFieldSyncOutput" runat="server">
                    <div class="logbox" style="color:var(--muted); font-style:italic;">Click "Load Field Sync Log" to view the nightly sync history.</div>
                </asp:Literal>
            </div>

            <!-- IIS / App Logs Link -->
            <div class="panel">
                <div class="panel-title">&#127760; IIS Web Server &amp; Application Logs</div>
                <div class="panel-sub">
                    The full IIS and .NET application logs are analyzed in the dedicated <strong>IIS &amp; App Log Analyzer</strong> tool.
                    It provides KPI dashboards, filterable tables, top-error charts, auto-diagnosis banners, and CSV export.
                </div>

                <a href="va_log_viewer.aspx" class="log-source-card">
                    <div class="log-source-icon">&#128270;</div>
                    <div>
                        <div class="log-source-title">Open IIS &amp; App Log Analyzer &#8594;</div>
                        <div class="log-source-desc">
                            View IIS W3C access logs, filter by URI / IP / status code, export CSV.<br />
                            View Serilog application logs with error-level badges, stack traces, and auto-diagnosis of known failure patterns.
                        </div>
                    </div>
                </a>
            </div>

        </asp:Panel><!-- /PnlLogViewer -->


        <!-- ═══════════════════════════════════════════════════
             TAB 2: DB AUTOMATION
             ═══════════════════════════════════════════════════ -->
        <asp:Panel ID="PnlDbUpdate" runat="server" Visible="false">

            <!-- SETTINGS PANEL -->
            <div class="panel">
                <div class="panel-title">&#9881; Configuration</div>
                <div class="panel-sub">
                    The DB Update processor watches a folder for a <code>data.txt</code> or <code>data.xlsx</code> file,
                    runs the SQL update script against it, then moves the processed file into a <code>loaded/</code> subfolder.
                    This can run on a schedule via Windows Task Scheduler using <code>?auto=1</code>.
                </div>

                <div class="form-row">
                    <div class="form-label">Watch Folder:</div>
                    <asp:TextBox ID="TxtFolder" runat="server" CssClass="txt" />
                </div>
                <div style="font-size:12px; color:var(--muted); margin: -8px 0 16px 232px;">
                    Default: <code>C:\VA_RFID\va_dbupdate\autoload</code> &mdash;
                    place a <code>data.txt</code> or <code>data.xlsx</code> here to be processed.
                </div>

                <div class="form-row">
                    <div class="form-label">SQL Script Path:</div>
                    <asp:TextBox ID="TxtSqlPath" runat="server" CssClass="txt" ReadOnly="true" />
                </div>

                <div class="form-row">
                    <div class="form-label">Last Run This Session:</div>
                    <asp:Literal ID="LitLastRun" runat="server" />
                </div>
            </div>

            <!-- SQL SCRIPT EDITOR PANEL -->
            <div class="panel">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                    <div>
                        <div class="panel-title">&#128190; Edit SQL Update Script</div>
                        <div class="panel-sub" style="margin:0;">
                            Review and edit the SQL script that runs against the database on each update cycle.
                            The token <code>{{DATAFILE}}</code> is automatically replaced with the full path of the
                            detected data file before execution &mdash; so you do not need to hard-code the file path.
                        </div>
                    </div>
                    <div style="flex-shrink:0; margin-left:14px;">
                        <asp:Button ID="BtnLoadSql" runat="server" CssClass="btn ghost" Text="Reload SQL" OnClick="BtnLoadSql_Click" style="padding:7px 14px; font-size:12px; margin-right:6px;" />
                        <asp:Button ID="BtnSaveSql" runat="server" CssClass="btn" Text="Save SQL" OnClick="BtnSaveSql_Click" style="padding:7px 14px; font-size:12px; margin-right:0;" />
                    </div>
                </div>

                <asp:Literal ID="LitSqlStatus" runat="server" />
                <asp:TextBox ID="TxtSqlEditor" runat="server" ValidateRequestMode="Disabled" TextMode="MultiLine" Rows="24"
                    style="width:100%; background:var(--preview-bg); border:1px solid var(--line); color:var(--preview-text); padding:12px; border-radius:10px;
                           font-family:Consolas, monospace; font-size:13px; line-height:1.4; resize:vertical; outline:none;
                           white-space:pre; tab-size:4;" />
            </div>


            <!-- ACTIONS PANEL -->
            <div class="panel">
                <div class="panel-title">&#9654; Run &amp; Actions</div>
                <div class="panel-sub">
                    Clicking <strong>Check Folder &amp; Run Now</strong> immediately scans the watch folder and
                    processes any file found there &mdash; exactly as if the scheduled task had fired.
                    Results appear in the <em>Run Output &amp; Logs</em> panel below.
                </div>
                <asp:Button ID="BtnRunMain" runat="server"
                    CssClass="btn green"
                    Text="&#9654; Check Folder &amp; Run Now"
                    OnClick="BtnRun_Click" />

                <asp:Button runat="server"
                    CssClass="btn ghost"
                    Text="&#8592; Back to Hub"
                    OnClientClick="window.location.href='index.aspx'; return false;" />

                <div id="runningBox">&#9203; Processing... please wait. This may take 30&ndash;90 seconds for large files.</div>
            </div>


            <!-- RESULTS / LOG PANEL -->
            <div class="panel">
                <div class="panel-title">&#128221; Run Output &amp; Logs</div>
                <asp:Literal ID="LitStatusOutput2" runat="server">
                    <div class="logbox" style="color:var(--muted); font-style:italic;">No run has been executed this session. Click "Run Now" or "View DB Update Log" to see output here.</div>
                </asp:Literal>
            </div>

        </asp:Panel><!-- /PnlDbUpdate -->

    </main>

</div>
</form>

<script>
document.getElementById('<%= BtnRunMain.ClientID %>').addEventListener('click', function () {
    document.getElementById('runningBox').style.display = 'block';
});

// Highlight active tab button
(function(){
    var tabLog = document.getElementById('<%= BtnTabLogView.ClientID %>');
    var tabDb  = document.getElementById('<%= BtnTabDbUpdate.ClientID %>');
    // Server sets the active class; JS re-applies on click for immediate feedback
    if (tabLog) tabLog.addEventListener('click', function(){
        tabLog.classList.add('tab-active'); tabDb.classList.remove('tab-active');
    });
    if (tabDb) tabDb.addEventListener('click', function(){
        tabDb.classList.add('tab-active'); tabLog.classList.remove('tab-active');
    });
})();
</script>

</body>
</html>
