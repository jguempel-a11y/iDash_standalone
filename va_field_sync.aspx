<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_field_sync.aspx.cs" Inherits="va_field_sync" ResponseEncoding="utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta charset="utf-8" />
<title>Field Sync &mdash; iDash</title>
<link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
<link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="0" />
<style>
        :root {
            --chip-br:  var(--line);
        }
        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
*{box-sizing:border-box;}
body{background:var(--bg);color:var(--text);font-family:Segoe UI,Tahoma,Arial,sans-serif;margin:0;}
.app{display:flex;min-height:100vh;}
.side{width:240px;background:var(--chip);border-right:1px solid var(--line);padding:20px 16px;flex-shrink:0;display:flex;flex-direction:column;}
.side h1{font-size:16px;margin:0 0 2px;color:var(--accent);display:flex;align-items:center;gap:6px;}
.side .sub{font-size:11px;color:var(--muted);margin-bottom:18px;padding-bottom:14px;border-bottom:1px solid var(--line);}
.nav-link{display:block;background:transparent;border:1px solid transparent;border-radius:8px;padding:8px 12px;color:var(--text);font-size:13px;font-weight:600;text-decoration:none;margin-bottom:4px;transition:all .15s ease;text-align:left;width:100%;cursor:pointer;}
.nav-link:hover{background:var(--accent);color:#011;border-color:var(--accent);}
.slabel{font-size:10px;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin:14px 0 6px;font-weight:700;}
.main{flex:1;padding:32px 42px;}
.main-topbar{display:flex;align-items:flex-start;justify-content:space-between;gap:14px;margin-bottom:22px;}
.main-topbar .nav-pills{display:flex;gap:8px;align-items:center;flex-shrink:0;}
.page-title{font-size:24px;font-weight:700;margin:0 0 4px;}
.page-sub{color:var(--muted);font-size:13px;margin-bottom:26px;}
.panel{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:22px 26px;margin-bottom:22px;}
.ptitle{font-size:16px;font-weight:700;margin:0 0 4px;color:var(--accent);}
.psub{font-size:13px;color:var(--muted);margin-bottom:16px;}
.btn{padding:10px 20px;background:var(--accent);color:var(--bg);border-radius:10px;border:1px solid var(--accent);cursor:pointer;font-weight:700;font-size:14px;margin-right:10px;}
.btn:hover{filter:brightness(1.12);}
.btn.green{background:var(--accent-2);border-color:var(--accent-2);color:var(--bg);}
.btn.purple{background:#a855f7;border-color:#a855f7;color:#fff;}
.btn.ghost{background:transparent;border-color:var(--accent);color:var(--accent);}
.stat-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:18px;}
.stat{background:var(--chip);border:1px solid var(--chip-br);border-radius:10px;padding:14px 16px;text-align:center;}
.stat-val{font-size:28px;font-weight:800;color:var(--accent);}
.stat-val.green{color:#10b981;}
.stat-val.yellow{color:#f59e0b;}
.stat-val.red{color:#ef4444;}
.stat-lbl{font-size:12px;color:var(--muted);margin-top:4px;}
.msg-ok {background:color-mix(in srgb, var(--accent-2), transparent 85%);border:1px solid var(--accent-2);color:var(--ok-text);padding:11px 15px;border-radius:8px;margin-bottom:14px;font-size:14px;}
.msg-err{background:color-mix(in srgb, var(--danger), transparent 85%);border:1px solid var(--danger);color:var(--err-text);padding:11px 15px;border-radius:8px;margin-bottom:14px;font-size:14px;}
.msg-info{background:var(--info-bg);border:1px solid var(--accent);color:var(--info-text);padding:11px 15px;border-radius:8px;margin-bottom:14px;font-size:14px;}
.file-row{display:flex;align-items:center;gap:10px;background:var(--chip);border:1px solid var(--chip-br);border-radius:8px;padding:10px 14px;margin-bottom:8px;font-size:13px;}
.file-row .fname{flex:1;color:var(--text);font-weight:600;}
.file-row .fdate{color:var(--muted);font-size:12px;}
.logbox{max-height:280px;overflow:auto;background:var(--chip);border:1px solid var(--chip-br);border-radius:10px;padding:10px;font-family:Consolas,monospace;font-size:12px;white-space:pre-wrap;color:var(--log-text);}
.status-dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:6px;}
.dot-green{background:#10b981;}
.dot-red{background:#ef4444;}
.dot-yellow{background:#f59e0b;}
input[type=text]{width:100%;padding:9px 11px;border-radius:8px;background:var(--chip);border:1px solid var(--chip-br);color:var(--text);font-size:13px;outline:none;}
input[type=text]:focus{border-color:var(--accent);}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="app">

<aside class="side">
    <h1>&#128257; Field Sync</h1>
    <div class="sub">BAK &rarr; Staging &rarr; Central</div>
    <div class="slabel">Actions</div>
    <asp:Button ID="BtnPreviewSide"  runat="server" CssClass="nav-link" Text="Preview Sync (Dry Run)"       OnClick="BtnPreview_Click" />
    <asp:Button ID="BtnFullSync"     runat="server" CssClass="nav-link" Text="Full Sync (Restore + Merge)"  OnClick="BtnFullSync_Click" />
    <asp:Button ID="BtnRestoreOnly"  runat="server" CssClass="nav-link" Text="Restore BAK to Staging"       OnClick="BtnRestoreOnly_Click" />
    <asp:Button ID="BtnMergeOnly"    runat="server" CssClass="nav-link" Text="Merge Staging to Central"     OnClick="BtnMergeOnly_Click" />
    <asp:Button ID="BtnRefresh"      runat="server" CssClass="nav-link" Text="Refresh Status"               OnClick="BtnRefresh_Click" />
    <div class="slabel">Automation</div>
    <a href="#schedulePanel" class="nav-link">&#128337; Schedule Task</a>
</aside>

<main class="main">
    <div class="main-topbar">
        <div>
            <div class="page-title">&#128257; Field Server Sync</div>
            <div class="page-sub">
                Restores a field server <code>.bak</code> to a staging database, then merges updated asset data
                into the central database for executive reporting. Designed for nightly automation.
            </div>
        </div>
        <div class="nav-pills">
            <a href="documentation/va_field_sync.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <asp:Literal ID="LitMsg" runat="server" />

    <!-- STATUS PANEL -->
    <div class="panel">
        <div class="ptitle">&#128268; System Status</div>
        <div class="stat-grid">
            <div class="stat">
                <div class="stat-val" id="statStaging"><asp:Literal ID="LitStagingStatus" runat="server" /></div>
                <div class="stat-lbl">Staging DB</div>
            </div>
            <div class="stat">
                <div class="stat-val green"><asp:Literal ID="LitLastSyncTime" runat="server" /></div>
                <div class="stat-lbl">Last Sync</div>
            </div>
            <div class="stat">
                <div class="stat-val yellow"><asp:Literal ID="LitBakCount" runat="server" /></div>
                <div class="stat-lbl">BAKs in Queue</div>
            </div>
            <div class="stat">
                <div class="stat-val green"><asp:Literal ID="LitLastResult" runat="server" /></div>
                <div class="stat-lbl">Last Run Result</div>
            </div>
        </div>
        <div style="font-size:13px; color:var(--muted);">
            Watch folder: <code><asp:Literal ID="LitWatchFolder" runat="server" /></code>
        </div>
    </div>

    <!-- SCHEDULE PANEL -->
    <div class="panel" id="schedulePanel">
        <div class="ptitle" style="color:#f59e0b;">&#128337; Automated Nightly Sync</div>
        <div class="psub">
            Schedule a Windows Task to automatically process any <code>.bak</code> file in the watch folder.
            This completes the pipeline: field server uploads at 5:30 PM &rarr; OneDrive pull at 6:00 PM &rarr; auto-process fires at the scheduled time below.
        </div>

        <div style="display:flex; gap:16px; align-items:flex-end; flex-wrap:wrap; margin-bottom:14px;">
            <div>
                <div style="font-size:12px; color:var(--muted); margin-bottom:4px;">Task Status</div>
                <div style="font-size:15px;"><asp:Literal ID="LitTaskStatus" runat="server" /></div>
            </div>
            <div>
                <div style="font-size:12px; color:var(--muted); margin-bottom:4px;">Daily Run Time (HH:MM)</div>
                <asp:TextBox ID="TxtScheduleTime" runat="server" Text="18:15" style="width:100px;" />
            </div>
            <asp:Button ID="BtnCreateTask" runat="server" CssClass="btn" Text="Create / Update Task" OnClick="BtnCreateTask_Click" style="background:#f59e0b; border-color:#f59e0b; color:var(--bg);" />
            <asp:Button ID="BtnRunNow" runat="server" CssClass="btn green" Text="Run Task Now" OnClick="BtnRunNow_Click" />
            <asp:Button ID="BtnDeleteTask" runat="server" CssClass="btn ghost" Text="Remove Task" OnClick="BtnDeleteTask_Click" style="border-color:#ef4444; color:#ef4444; padding:10px 16px;" />
        </div>

        <div class="msg-info" style="font-size:13px;">
            <strong>How it works:</strong> The scheduled task calls <code>va_field_sync.aspx?auto=1</code> which automatically runs a Full Sync (Restore + Merge) if any <code>.bak</code> files are in the watch folder. After processing, the file is moved to <code>processed/</code>. If no files are waiting, nothing happens.
        </div>
    </div>

    <!-- BAK FILE SELECTION -->
    <div class="panel">
        <div class="ptitle">&#128196; BAK File Selection</div>
        <div class="psub">Files detected in the watch folder. Select one to sync, or the latest will be used automatically.</div>
        <asp:Literal ID="LitBakFiles" runat="server" />
        <div style="margin-top:14px;">
            <div style="font-size:13px; color:var(--muted); margin-bottom:6px;">Or enter a full path manually:</div>
            <asp:TextBox ID="TxtBakPath" runat="server" placeholder="e.g. C:\VA_RFID\va_sync\incoming\idash_20260423.bak" />
            <asp:Button ID="BtnCopyToWatch" runat="server" Text="Copy to Watch Folder" OnClick="BtnCopyToWatch_Click"
                style="margin-top:6px; padding:6px 14px; background:rgba(59,130,246,0.12); border:1px solid rgba(59,130,246,0.3); border-radius:6px; color:#3b82f6; font-size:12px; font-weight:600; cursor:pointer;" />
            <div style="font-size:11px; color:var(--muted); margin-top:6px; line-height:1.6;">
                <strong>Note:</strong> OneDrive, network drives (\\server\share), and user profile paths are often not accessible to the IIS worker process.
                If a manual path fails, either: <br/>(a) Click <em>Copy to Watch Folder</em> above to copy it into the watch folder, or <br/>(b) Manually copy the .bak file to <code><asp:Literal runat="server" Text="C:\VA_RFID\va_sync\incoming" /></code>
            </div>
        </div>
    </div>

    <!-- STAGING DB SETTINGS -->
    <div class="panel">
        <div class="ptitle">&#9881; Staging Database Settings</div>
        <div class="psub">
            The <code>.bak</code> is restored to <code>idash_staging</code> on this server.
            SQL Server must have write access to the staging file path below.
        </div>
        <table style="width:100%; font-size:13px;">
            <tr>
                <td style="width:220px; color:var(--muted); padding:6px 0; font-weight:600;">Staging DB Name</td>
                <td><code>idash_staging</code> (fixed)</td>
            </tr>
            <tr>
                <td style="color:var(--muted); padding:6px 0; font-weight:600;">Staging MDF Path</td>
                <td>
                    <asp:TextBox ID="TxtStagingMdf" runat="server"
                        placeholder="C:\VA_RFID\va_sync\staging_db\idash_staging.mdf" />
                </td>
            </tr>
            <tr>
                <td style="color:var(--muted); padding:6px 0; font-weight:600;">Staging LDF Path</td>
                <td>
                    <asp:TextBox ID="TxtStagingLdf" runat="server"
                        placeholder="C:\VA_RFID\va_sync\staging_db\idash_staging_log.ldf" />
                </td>
            </tr>
        </table>
    </div>

    <!-- ACTIONS -->
    <div class="panel">
        <div class="ptitle">&#9654; Run Sync</div>
        <div class="psub">
            <strong>Step 1:</strong> Run <strong>Preview</strong> to see exactly what will change before touching any data.<br/>
            <strong>Step 2:</strong> Run <strong>Full Sync</strong> to commit. Restore + Merge runs in one click.
        </div>

        <!-- PREVIEW ROW -->
        <div style="margin-bottom:14px; padding:14px 16px; background:rgba(168,85,247,0.07); border:1px solid #a855f7; border-radius:10px;">
            <div style="font-weight:700; color:#a855f7; margin-bottom:8px;">&#128269; Preview (Dry Run &mdash; No Data Changed)</div>
            <div style="font-size:13px; color:var(--muted); margin-bottom:10px;">
                Shows how many assets and locations <em>would</em> be updated or inserted if you ran Full Sync now.
                Requires staging DB to already exist (run Restore Only first if needed).
            </div>
            <asp:Button ID="BtnPreviewMain" runat="server" CssClass="btn purple" Text="Preview Sync (Dry Run)" OnClick="BtnPreview_Click" />
        </div>

        <!-- COMMIT ROW -->
        <div style="padding:14px 16px; background:color-mix(in srgb, var(--accent-2), transparent 92%); border:1px solid #10b981; border-radius:10px;">
            <div style="font-weight:700; color:#10b981; margin-bottom:8px;">&#9654; Commit Sync (Writes to Database)</div>
            <div style="font-size:13px; color:var(--muted); margin-bottom:12px;">
                These buttons write to the database. Always run Preview first to verify what will change.
            </div>
            <div style="display:grid; grid-template-columns:repeat(3, 1fr); gap:14px;">
                <div style="text-align:center;">
                    <asp:Button ID="BtnFullSyncMain"    runat="server" CssClass="btn green"  Text="Full Sync (Restore + Merge)" OnClick="BtnFullSync_Click" style="width:100%;" />
                    <div style="font-size:11px; color:var(--muted); margin-top:6px; line-height:1.5;">
                        <strong>The one-click option.</strong> Restores the .bak to staging, then merges all changes into the live database. Use this for normal daily syncs.
                    </div>
                </div>
                <div style="text-align:center;">
                    <asp:Button ID="BtnRestoreOnlyMain" runat="server" CssClass="btn"        Text="Restore BAK Only"           OnClick="BtnRestoreOnly_Click" style="width:100%;" />
                    <div style="font-size:11px; color:var(--muted); margin-top:6px; line-height:1.5;">
                        <strong>Restore only &mdash; no data changes.</strong> Loads the .bak into <code>idash_staging</code> so you can inspect the data or run Preview before merging.
                    </div>
                </div>
                <div style="text-align:center;">
                    <asp:Button ID="BtnMergeOnlyMain"   runat="server" CssClass="btn purple" Text="Merge Only"                 OnClick="BtnMergeOnly_Click" style="width:100%;" />
                    <div style="font-size:11px; color:var(--muted); margin-top:6px; line-height:1.5;">
                        <strong>Merge only &mdash; uses existing staging DB.</strong> Skips restore and merges from the currently loaded staging database. Useful after a Restore-only + Preview workflow.
                    </div>
                </div>
            </div>
        </div>

        <div id="runningBox" style="display:none; margin-top:14px; padding:12px; background:var(--chip); border:1px solid var(--chip-br); border-radius:8px; font-family:Consolas,monospace; font-size:13px;">
            Running... this may take 1-3 minutes for large databases. Please wait.
        </div>
    </div>

    <!-- PREVIEW RESULTS -->
    <div class="panel" id="previewPanel">
        <div class="ptitle" style="color:#a855f7;">&#128269; Preview Results</div>
        <asp:Literal ID="LitPreview" runat="server">
            <div style="color:var(--muted); font-size:13px; font-style:italic;">Run Preview (Dry Run) to see what would change before committing.</div>
        </asp:Literal>
    </div>

    <!-- RESULTS -->
    <div class="panel">
        <div class="ptitle">&#128202; Last Sync Results</div>
        <asp:Literal ID="LitResults" runat="server">
            <div style="color:var(--muted); font-size:13px; font-style:italic;">No sync has been run this session.</div>
        </asp:Literal>
    </div>

    <!-- LOG -->
    <div class="panel">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
            <div class="ptitle" style="margin:0;">&#128221; Sync Log</div>
            <asp:Button ID="BtnClearLog" runat="server" CssClass="btn ghost" Text="Clear Log" OnClick="BtnClearLog_Click" style="padding:6px 14px; font-size:12px; margin:0;" />
        </div>
        <div class="logbox"><asp:Literal ID="LitLog" runat="server" /></div>
    </div>

    <aw:Footer runat="server" />
</main>
</div>
</form>
<script>
document.getElementById('<%= BtnFullSyncMain.ClientID %>').onclick    = function(){ document.getElementById('runningBox').style.display='block'; };
document.getElementById('<%= BtnRestoreOnlyMain.ClientID %>').onclick = function(){ document.getElementById('runningBox').style.display='block'; };
document.getElementById('<%= BtnMergeOnlyMain.ClientID %>').onclick   = function(){ document.getElementById('runningBox').style.display='block'; };
document.getElementById('<%= BtnPreviewMain.ClientID %>').onclick     = function(){ document.getElementById('runningBox').style.display='block'; };
</script>
</body>
</html>
