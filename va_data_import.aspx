<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_data_import.aspx.cs" Inherits="iDash.va_data_import" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Data File Import &mdash; iDash</title>
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <style>
        body { margin:0; background:var(--bg); color:var(--text); font-family:Segoe UI,Tahoma,Arial,sans-serif; }
        * { box-sizing:border-box; }
        a { text-decoration:none; color:inherit; }
        .page { max-width:1100px; margin:40px auto; padding:0 40px; }

        .header-title { font-size:32px; font-weight:700; margin-bottom:6px; }
        .header-sub { font-size:14px; color:var(--muted); margin-bottom:28px; }
        .aw-header-brand { margin-top:8px; margin-bottom:14px; display:flex; align-items:center; gap:10px; opacity:0.95; }
        .aw-header-logo { height:26px; width:auto; }
        .aw-header-text { font-size:14px; font-weight:600; color:var(--accent); letter-spacing:0.4px; }
        .aw-header-text .bang { color:var(--accent-2); }

        /* Cards */
        .card { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:28px 32px; margin-bottom:24px; }
        .card h2 { margin:0 0 6px; font-size:20px; font-weight:700; }
        .card .caption { font-size:13px; color:var(--muted); margin-bottom:16px; }

        /* Mode Selector */
        .mode-row { display:flex; gap:16px; margin-bottom:20px; flex-wrap:wrap; }
        .mode-option { display:flex; align-items:center; gap:8px; padding:14px 20px; border:2px solid var(--line);
                       border-radius:10px; cursor:pointer; transition:all .2s; min-width:200px; }
        .mode-option:hover { border-color:var(--accent); }
        .mode-option.active { border-color:var(--accent); background:color-mix(in srgb, var(--accent), transparent 92%); }
        .mode-option input[type=radio] { accent-color:var(--accent); width:18px; height:18px; }
        .mode-label { font-weight:600; font-size:15px; }
        .mode-desc { font-size:12px; color:var(--muted); margin-top:2px; }

        /* Site input */
        .site-row { display:flex; align-items:center; gap:12px; margin-bottom:18px; padding:12px 16px;
                    border:1px dashed var(--accent); border-radius:8px; background:color-mix(in srgb, var(--accent), transparent 95%); }
        .site-row label { font-weight:600; font-size:14px; white-space:nowrap; }
        .site-row input[type=text] { width:120px; padding:8px 12px; border:1px solid var(--line); border-radius:6px;
                                     background:var(--bg); color:var(--text); font-size:16px; font-weight:700; text-align:center; }
        .site-row .site-hint { font-size:12px; color:var(--muted); }

        /* Buttons */
        .btn-row { display:flex; gap:12px; align-items:center; flex-wrap:wrap; margin-bottom:16px; }
        .btn-import { padding:10px 28px; border:none; border-radius:8px; font-size:15px; font-weight:700;
                      cursor:pointer; transition:all .2s; }
        .btn-preview { background:var(--card); border:2px solid var(--accent); color:var(--accent); padding:10px 24px;
                       border-radius:8px; font-size:14px; font-weight:600; cursor:pointer; transition:all .15s; }
        .btn-preview:hover { background:color-mix(in srgb, var(--accent), transparent 88%); }
        .btn-go { background:linear-gradient(135deg, #10b981, #059669); color:#fff; }
        .btn-go:hover { filter:brightness(1.1); transform:translateY(-1px); }

        /* File upload */
        .file-zone { border:2px dashed var(--line); border-radius:10px; padding:20px; text-align:center;
                     margin-bottom:16px; transition:border-color .2s; }
        .file-zone:hover { border-color:var(--accent); }

        /* Status log */
        .step { padding:6px 12px; margin:4px 0; border-radius:6px; font-size:13px; font-family:Consolas,monospace; }
        .step-ok { background:color-mix(in srgb, #10b981, transparent 90%); color:#10b981; border-left:3px solid #10b981; }
        .step-run { background:color-mix(in srgb, #2ea8ff, transparent 90%); color:#2ea8ff; border-left:3px solid #2ea8ff; }
        .step-err { background:color-mix(in srgb, #ef4444, transparent 90%); color:#ef4444; border-left:3px solid #ef4444; }

        .msg { padding:12px 16px; border-radius:8px; margin-bottom:16px; font-size:14px; }
        .msg-ok { background:color-mix(in srgb, #10b981, transparent 88%); color:#10b981; border:1px solid #10b981; }
        .msg-err { background:color-mix(in srgb, #ef4444, transparent 88%); color:#ef4444; border:1px solid #ef4444; }

        /* Results summary */
        .results-grid { display:grid; grid-template-columns:repeat(3, 1fr); gap:14px; margin-top:16px; }
        .result-card { background:var(--bg); border:1px solid var(--line); border-radius:10px; padding:18px; text-align:center; }
        .result-value { font-size:28px; font-weight:800; }
        .result-label { font-size:12px; color:var(--muted); margin-top:4px; text-transform:uppercase; letter-spacing:0.5px; }
        .rc-green .result-value { color:#10b981; }
        .rc-blue .result-value { color:#2ea8ff; }
        .rc-gray .result-value { color:var(--muted); }
        .rc-red .result-value { color:#ef4444; }

        /* Preview grid */
        .scroll-grid { overflow-x:auto; margin-top:16px; }
        .scroll-grid table { width:100%; border-collapse:collapse; font-size:12px; }
        .scroll-grid th { background:var(--accent); color:#fff; padding:8px 10px; text-align:left; white-space:nowrap; font-size:11px; }
        .scroll-grid td { padding:6px 10px; border-bottom:1px solid var(--line); white-space:nowrap; max-width:200px; overflow:hidden; text-overflow:ellipsis; }
        .scroll-grid tr:hover td { background:color-mix(in srgb, var(--accent), transparent 92%); }

        .back-link { font-size:13px; color:var(--muted); margin-left:12px; }
        .back-link:hover { color:var(--accent); }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="page">

    <a href="documentation/va_data_import.html" class="btn-preview" style="text-decoration:none; font-size:12px; padding:6px 14px;">&#128214; View Docs</a>
    <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>

    <div class="header-title">&#128229; Data File Import</div>
    <div class="header-sub">Upload a tab-delimited data file and import directly into iDash. No SSMS, no file shares, no copy-paste.</div>

    <!-- Recommendation card for Cart Data & Sync Hub -->
    <div style="background: color-mix(in srgb, var(--accent), transparent 90%); border: 1px solid var(--accent); border-radius: 12px; padding: 16px 20px; margin-bottom: 24px; display: flex; align-items: center; justify-content: space-between; gap: 16px; flex-wrap: wrap;">
        <div>
            <strong style="color:var(--accent); font-size: 15px;">&#128257; Recommended: Use the Unified Cart Data &amp; Sync Hub</strong>
            <div style="font-size: 13px; color: var(--muted); margin-top: 4px;">
                Direct Excel (.xlsx), tab-delimited, and CSV support with intelligent Smart Merge, scan preservation, and automated location provisioning has been consolidated into the unified Sync Hub.
            </div>
        </div>
        <a href="va_sitedata_export.aspx#sec-import" class="btn-preview" style="white-space: nowrap; text-decoration: none; padding: 8px 18px; font-weight:700;">Open Sync Hub &rarr;</a>
    </div>

    <div class="aw-header-brand" style="display:flex; align-items:center; gap:8px;">
        <img src="<%= ResolveUrl("~/Assets/branding/IDIntegration.jpg") %>" style="height:20px; width:auto; border-radius:3px;" alt="ID Integration Inc." />
        <span class="aw-header-text" style="font-weight:700; font-size:14px;">iDash<span class="bang" style="color:var(--accent);">.</span></span>
        <span class="aw-header-copy" style="font-size:11px; color:var(--muted); font-style:italic;">by ID Integration Inc.</span>
    </div>

    <!-- Mode Selection -->
    <div class="card">
        <h2>Import Mode</h2>
        <div class="caption">Choose how station numbers are handled in the data file.</div>

        <div class="mode-row">
            <label class="mode-option" id="modeForce" onclick="setMode('force')">
                <asp:RadioButton ID="RdoForceSite" runat="server" GroupName="ImportMode" Checked="true" />
                <div>
                    <div class="mode-label">&#127970; Force Site Number</div>
                    <div class="mode-desc">All rows get the same station number (e.g., single-site file like Prescott 649)</div>
                </div>
            </label>
            <label class="mode-option" id="modeAuto" onclick="setMode('auto')">
                <asp:RadioButton ID="RdoAutoDetect" runat="server" GroupName="ImportMode" />
                <div>
                    <div class="mode-label">&#128269; Auto-detect from File</div>
                    <div class="mode-desc">Uses the STATION NUMBER column from each row (multi-site files)</div>
                </div>
            </label>
        </div>

        <div class="site-row" id="siteRow">
            <label>Station Number:</label>
            <asp:TextBox ID="TxtSiteNumber" runat="server" MaxLength="10" placeholder="649" />
            <span class="site-hint">Enter the 3-digit VA station number (e.g., 649 for Prescott)</span>
        </div>
    </div>

    <!-- File Upload -->
    <div class="card">
        <h2>Data File</h2>
        <div class="caption">Tab-delimited .txt file with header row. Expected columns: ENTRY NUMBER, MANUFACTURER, MFGR. EQUIPMENT NAME, MODEL, SERIAL #, EQUIPMENT CATEGORY, USE STATUS, SERVICE POINTER, LOCATION, PHYSICAL INVENTORY DATE, PREVIOUS LOCATION, STATION NUMBER, CATEGORY STOCK NUMBER, CMR, PURCHASE ORDER #</div>

        <div class="file-zone">
            <asp:FileUpload ID="FileUploadData" runat="server" CssClass="btn-preview" style="border:none;" />
        </div>

        <div class="btn-row">
            <asp:Button ID="BtnPreview" runat="server" CssClass="btn-preview" Text="&#128270; Preview First 20 Rows" OnClick="BtnPreview_Click" />
            <asp:Button ID="BtnImport" runat="server" CssClass="btn-import btn-go" Text="&#9654; Import Data" OnClick="BtnImport_Click"
                OnClientClick="return confirm('This will import all rows into iDash. Continue?');" />
        </div>
    </div>

    <!-- Status / Log -->
    <asp:Literal ID="LitStatus" runat="server" />

    <!-- Preview Grid -->
    <asp:Panel ID="PanelPreview" runat="server" Visible="false">
        <div class="card">
            <h2>File Preview (First 20 Rows)</h2>
            <div class="scroll-grid">
                <asp:GridView ID="GridPreview" runat="server" CssClass="grid" EnableViewState="false" AutoGenerateColumns="True" />
            </div>
        </div>
    </asp:Panel>

    <!-- Results Summary -->
    <asp:Panel ID="PanelResults" runat="server" Visible="false">
        <div class="card" style="border-left:4px solid #10b981;">
            <h2 style="color:#10b981;">&#9989; Import Results</h2>
            <div class="results-grid">
                <div class="result-card rc-green">
                    <div class="result-value"><asp:Literal ID="LitAssetsInserted" runat="server" /></div>
                    <div class="result-label">Assets Inserted</div>
                </div>
                <div class="result-card rc-blue">
                    <div class="result-value"><asp:Literal ID="LitLocInserted" runat="server" /></div>
                    <div class="result-label">Locations Created</div>
                </div>
                <div class="result-card rc-blue">
                    <div class="result-value"><asp:Literal ID="LitAssetsUpdated" runat="server" /></div>
                    <div class="result-label">Assets Updated</div>
                </div>
                <div class="result-card rc-gray">
                    <div class="result-value"><asp:Literal ID="LitAssetsSkipped" runat="server" /></div>
                    <div class="result-label">Dupes Skipped</div>
                </div>
                <div class="result-card rc-red">
                    <div class="result-value"><asp:Literal ID="LitErrors" runat="server" /></div>
                    <div class="result-label">Errors</div>
                </div>
                <div class="result-card">
                    <div class="result-value" style="color:var(--text);"><asp:Literal ID="LitTotalAssets" runat="server" /></div>
                    <div class="result-label">Total Assets Now</div>
                </div>
            </div>
        </div>
    </asp:Panel>

    <idash:Footer runat="server" />
</div>
</form>

<script>
function setMode(mode) {
    var siteRow = document.getElementById('siteRow');
    var forceEl = document.getElementById('modeForce');
    var autoEl  = document.getElementById('modeAuto');
    if (mode === 'force') {
        siteRow.style.display = 'flex';
        forceEl.classList.add('active');
        autoEl.classList.remove('active');
    } else {
        siteRow.style.display = 'none';
        forceEl.classList.remove('active');
        autoEl.classList.add('active');
    }
}
// Init on load
document.addEventListener('DOMContentLoaded', function() {
    var forceRadio = document.getElementById('<%= RdoForceSite.ClientID %>');
    if (forceRadio && forceRadio.checked) {
        setMode('force');
    } else {
        setMode('auto');
    }
});
</script>
</body>
</html>

