<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_excel_print.aspx.cs" Inherits="va_excel_print" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash &mdash; Excel Equipment Import &amp; Print</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        * { box-sizing: border-box; }
        body { margin:0; background:var(--bg); color:var(--text); font-family:Segoe UI,sans-serif; }
        .status-bar { display:flex; justify-content:space-between; background:var(--chip); padding:8px 20px; font-size:13px; border-bottom:1px solid var(--line); }
        .wrap { max-width:1600px; margin:30px auto; padding:0 24px; }
        .page-title { font-size:26px; font-weight:700; margin-bottom:4px; }
        .page-sub   { color:var(--muted); font-size:13px; margin-bottom:24px; }
        .card { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:24px; margin-bottom:20px; }
        .card-title { font-size:17px; font-weight:700; margin:0 0 16px; color:var(--accent); }
        .toolbar { display:flex; align-items:center; flex-wrap:wrap; gap:12px; margin-bottom:16px; }
        .lbl { font-size:12px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.4px; margin-right:4px; }
        select.pick { background:var(--bg); border:1px solid var(--line); color:var(--text); padding:8px 12px; border-radius:8px; font-size:13px; }
        select.pick:focus { border-color:var(--accent); outline:none; }
        .btn { display:inline-flex; align-items:center; gap:6px; padding:9px 18px; border-radius:8px; border:none; font-weight:600; font-size:13px; cursor:pointer; transition:.15s; }
        .btn-primary { background:var(--accent); color:#fff; }
        .btn-green   { background:var(--accent-2); color:#000; }
        .btn-ghost   { background:transparent; border:1px solid var(--line); color:var(--text); }
        .btn:hover   { opacity:.85; transform:translateY(-1px); }
        .grid-wrap { overflow-x:auto; max-height:540px; overflow-y:auto; border:1px solid var(--line); border-radius:8px; }
        table.eq { width:100%; border-collapse:collapse; font-size:12px; }
        table.eq th { background:var(--chip); color:var(--muted); text-align:left; padding:8px 10px; border-bottom:2px solid var(--line); font-weight:600; white-space:nowrap; position:sticky; top:0; z-index:2; }
        table.eq td { padding:7px 10px; border-bottom:1px solid var(--line); vertical-align:middle; white-space:nowrap; }
        table.eq tr:last-child td { border-bottom:none; }
        table.eq tr:hover td { background:color-mix(in srgb, var(--accent), transparent 95%); }
        input[type=checkbox] { width:16px; height:16px; accent-color:var(--accent); cursor:pointer; }
        .alert { padding:12px 16px; border-radius:8px; margin-bottom:14px; border-left:4px solid; font-size:13px; line-height:1.6; }
        .alert-ok   { background:color-mix(in srgb,var(--accent-2),transparent 85%); border-color:var(--accent-2); color:var(--accent-2); }
        .alert-err  { background:color-mix(in srgb,var(--danger),transparent 85%);  border-color:var(--danger);   color:var(--danger); }
        .alert-info { background:color-mix(in srgb,var(--accent),transparent 85%);  border-color:var(--accent);   color:var(--accent); }
        .counter { font-size:13px; color:var(--muted); }
        .counter strong { color:var(--text); }
        .badge { display:inline-block; padding:2px 8px; border-radius:10px; font-size:10px; font-weight:700; }
        .badge-new    { background:rgba(16,185,129,.15); color:#10b981; border:1px solid rgba(16,185,129,.3); }
        .badge-update { background:rgba(245,158,11,.15); color:#f59e0b; border:1px solid rgba(245,158,11,.3); }
        /* File source card */
        .source-card { display:flex; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom:20px; padding:18px 24px; background:var(--card); border:1px solid var(--line); border-radius:12px; }
        .source-card .source-option { display:flex; align-items:center; gap:10px; padding:10px 16px; border-radius:10px; border:1px dashed var(--line); flex:1; min-width:260px; }
        .source-card .source-option.active { border-color:var(--accent); background:color-mix(in srgb,var(--accent),transparent 92%); }
        .source-card .source-label { font-size:12px; font-weight:700; text-transform:uppercase; letter-spacing:.4px; color:var(--muted); margin-bottom:2px; }
        .source-card .source-file  { font-size:13px; color:var(--text); word-break:break-all; }
        .source-or { font-size:12px; font-weight:700; color:var(--muted); text-transform:uppercase; }
        /* Tabs */
        .tab-bar { display:flex; gap:0; border-bottom:2px solid var(--line); margin-bottom:0; }
        .tab-btn { padding:10px 20px; border:none; background:none; color:var(--muted); font-size:13px; font-weight:600; cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-2px; transition:.15s; }
        .tab-btn:hover { color:var(--text); }
        .tab-btn.active { color:var(--accent); border-bottom-color:var(--accent); background:color-mix(in srgb,var(--accent),transparent 94%); }
        .tab-pane { padding-top:14px; }
    </style>
</head>
<body>
<form id="form1" runat="server" enctype="multipart/form-data">
    <div class="status-bar">
        <span>iDash &mdash; Excel Equipment Import &amp; Print</span>
        <span><asp:Literal ID="LitConnStatus" runat="server" /></span>
    </div>
    <div class="wrap">
        <div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-bottom:6px;">
            <div>
                <div class="page-title">&#128218; Excel Equipment Import &amp; Print</div>
                <div class="page-sub">Auto-detects <code>C:\va_rfid\excel_data\equipment.xlsx</code> or browse to any <code>.xlsx</code> file &mdash; select rows, pick a label template, then import into iDash and/or print.</div>
            </div>
            <a href="index.aspx" class="btn btn-ghost" style="font-size:12px;">&#8962; Hub</a>
        </div>

        <asp:Literal ID="LitMsg" runat="server" />

        <!-- ===== FILE SOURCE SELECTOR ===== -->
        <div class="source-card">
            <div class="source-option" id="srcAuto">
                <div>
                    <div class="source-label">&#128193; Auto-Detect (Default)</div>
                    <div class="source-file"><code>C:\va_rfid\excel_data\equipment.xlsx</code></div>
                    <asp:Literal ID="LitAutoStatus" runat="server" />
                </div>
            </div>
            <div class="source-or">&mdash; OR &mdash;</div>
            <div class="source-option" id="srcUpload">
                <div style="width:100%;">
                    <div class="source-label">&#128194; Browse File</div>
                    <div style="display:flex; align-items:center; gap:10px; margin-top:4px;">
                        <asp:FileUpload ID="FileUpload1" runat="server" CssClass="pick" style="font-size:12px; flex:1;" accept=".xlsx,.xls" />
                        <asp:Button ID="BtnLoadFile" runat="server" Text="&#128196; Load File" CssClass="btn btn-primary" style="font-size:12px;" OnClick="BtnLoadFile_Click" />
                    </div>
                    <asp:Literal ID="LitUploadStatus" runat="server" />
                </div>
            </div>
        </div>

        <asp:Panel ID="PnlFileError" runat="server" Visible="false">
        <div class="alert alert-err">
            <strong>&#9888; Cannot read equipment.xlsx</strong><br />
            <asp:Literal ID="LitFileError" runat="server" />
        </div>
        </asp:Panel>

        <asp:Panel ID="PnlMain" runat="server" Visible="false">
        <div class="card">
            <div class="toolbar">
                <div>
                    <span class="lbl">Template</span>
                    <asp:DropDownList ID="DdlTemplate" runat="server" CssClass="pick" style="min-width:260px;" />
                </div>
                <div>
                    <span class="lbl">Site Override</span>
                    <asp:DropDownList ID="DdlSiteOverride" runat="server" CssClass="pick" style="min-width:220px;"
                        onchange="updatePreviewNames()" />
                </div>
                <div>
                    <span class="lbl">Name Prefix</span>
                    <asp:TextBox ID="TxtNamePrefix" runat="server" CssClass="pick"
                        style="width:70px;" MaxLength="10" placeholder="e.g. EE" Text="EE"
                        oninput="updatePreviewNames()" />
                    <span style="font-size:11px;color:var(--muted);margin-left:4px;">inserted before entry&nbsp;#</span>
                </div>
                <div style="display:flex; align-items:center; gap:8px; margin-left:auto;">
                    <span class="counter"><strong id="selCount">0</strong> of <strong><asp:Literal ID="LitTotal" runat="server" /></strong> rows selected</span>
                    <button type="button" class="btn btn-ghost" style="font-size:12px;" onclick="selectAll(true)">Select All</button>
                    <button type="button" class="btn btn-ghost" style="font-size:12px;" onclick="selectAll(false)">Clear</button>
                    <button type="button" class="btn" style="background:#0284c7; color:#fff; font-size:12px;" onclick="previewSelectedExcelRow()">&#128065; Preview Label</button>
                    <asp:Button ID="BtnImportOnly"  runat="server" CssClass="btn btn-ghost" Text="Import Only"        OnClick="BtnImportOnly_Click"  OnClientClick="return confirmAction('import')" />
                    <asp:Button ID="BtnImportPrint" runat="server" CssClass="btn btn-green" Text="Import &amp; Print" OnClick="BtnImportPrint_Click" OnClientClick="return confirmAction('print')"  />
                </div>
            </div>
            <div class="alert alert-info" style="margin:0; font-size:12px;">
                <strong>Site Override</strong> &mdash; forces all selected rows to the chosen company regardless of Station # column.
                Leave on <em>Auto</em> to use the Station # column to resolve site.&nbsp;&nbsp;
                <strong>Import Only</strong> &mdash; adds/updates assets without printing.&nbsp;&nbsp;
                <strong>Import &amp; Print</strong> &mdash; imports then fires labels via MQTT/BarTender.
                <div style="margin-top:6px; padding-top:6px; border-top:1px solid color-mix(in srgb,var(--accent),transparent 75%);">
                    <strong>&#9888; Batch Size Limits:</strong> To prevent timeouts, limit <em>Import Only</em> to ~500 rows at a time, and <em>Import &amp; Print</em> to ~100 rows at a time.
                </div>
            </div>
        </div>

        <div class="card" style="padding:0 24px 0;">
            <!-- Tab bar -->
            <div class="tab-bar">
                <button type="button" class="tab-btn active" onclick="showTab('data',this)">&#128203; Equipment Data</button>
                <button type="button" class="tab-btn"        onclick="showTab('preview',this)">&#128269; Preview Names</button>
            </div>

            <!-- Tab: Equipment Data (full grid) -->
            <div id="tab-data" class="tab-pane">
                <div class="grid-wrap">
                    <table class="eq" id="eqTable">
                        <thead>
                            <tr>
                                <th><input type="checkbox" id="chkAll" onchange="selectAll(this.checked)" title="Select all" /></th>
                                <th>#</th>
                                <th>Status</th>
                                <th style="color:var(--accent);">&#10003; Name</th>
                                <th>Entry #</th>
                                <th>Manufacturer</th>
                                <th>Equipment Name</th>
                                <th>Model</th>
                                <th>Serial #</th>
                                <th>Category</th>
                                <th>Use Status</th>
                                <th>Location</th>
                                <th>Station</th>
                                <th>CMR</th>
                                <th>PO #</th>
                                <th>Cat Stock #</th>
                                <th>Service Ptr</th>
                                <th>Inv Date</th>
                                <th>Prev Location</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Literal ID="LitRows" runat="server" />
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Tab: Preview Names -->
            <div id="tab-preview" class="tab-pane" style="display:none;">
                <div class="alert alert-info" style="font-size:12px;margin-bottom:12px;">
                    Shows the <strong>exact asset name</strong> that will be saved for each row
                    based on the current <strong>Site Override</strong> selection.
                    Change Site Override above &mdash; names update instantly.
                </div>
                <div class="grid-wrap">
                    <table class="eq" id="previewTable">
                        <thead>
                            <tr>
                                <th style="color:var(--accent);">&#10003; Computed Name</th>
                                <th>Entry #</th>
                                <th>Station</th>
                                <th>Serial #</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Literal ID="LitPreviewRows" runat="server" />
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        </asp:Panel>

        <asp:HiddenField ID="HfSelectedRows" runat="server" />
        <asp:HiddenField ID="HfAction"       runat="server" />
    </div>
    <script><asp:Literal ID="LitCompanyJs" runat="server" /></script>
</form>
<script>
function showTab(id, btn) {
    document.querySelectorAll('.tab-pane').forEach(function(p){ p.style.display='none'; });
    document.querySelectorAll('.tab-btn').forEach(function(b){ b.classList.remove('active'); });
    document.getElementById('tab-' + id).style.display = '';
    if (btn) btn.classList.add('active');
}
function updatePreviewNames() {
    var sel = document.getElementById('<%= DdlSiteOverride.ClientID %>');
    var pfx = document.getElementById('<%= TxtNamePrefix.ClientID %>');
    var overrideId  = sel ? sel.value : '0';
    var namePrefix  = pfx ? pfx.value.trim() : '';
    var overrideName = (parseInt(overrideId) > 0 && typeof companyNames !== 'undefined')
        ? (companyNames[overrideId] || null) : null;
    document.querySelectorAll('tr[data-entry]').forEach(function(row) {
        var entry   = row.getAttribute('data-entry')  || '';
        var station = row.getAttribute('data-station') || '';
        var sitePfx = overrideName || station;
        var fullEntry = namePrefix ? namePrefix + entry : entry;
        var name    = sitePfx ? sitePfx + ' ' + fullEntry : fullEntry;
        row.querySelectorAll('.name-preview').forEach(function(c){ c.textContent = name; });
    });
}
function updateCount() {
    var checked = document.querySelectorAll('input.row-chk:checked').length;
    document.getElementById('selCount').textContent = checked;
    var all = document.querySelectorAll('input.row-chk').length;
    var ca = document.getElementById('chkAll');
    ca.indeterminate = false;
    if (checked === 0) ca.checked = false;
    else if (checked === all) ca.checked = true;
    else ca.indeterminate = true;
}
function selectAll(checked) {
    document.querySelectorAll('input.row-chk').forEach(function(c){ c.checked = checked; });
    updateCount();
}
document.addEventListener('change', function(e){
    if (e.target && e.target.classList.contains('row-chk')) updateCount();
});
function confirmAction(type) {
    var checked = document.querySelectorAll('input.row-chk:checked');
    if (checked.length === 0) { alert('Please select at least one row.'); return false; }
    var indices = [];
    checked.forEach(function(c){ indices.push(c.value); });
    document.getElementById('<%= HfSelectedRows.ClientID %>').value = indices.join(',');
    document.getElementById('<%= HfAction.ClientID %>').value = type;
    var label = type === 'print' ? 'Import & Print' : 'Import Only';
    var ans = confirm(label + ' ' + checked.length + ' row(s)?');
    if (ans) {
        var actionText = type === 'print' ? 'Importing & Printing...' : 'Importing... Please wait.';
        
        var overlay = document.createElement('div');
        overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:var(--bg);opacity:0.85;z-index:9998;transition:opacity 0.3s;';
        
        var modal = document.createElement('div');
        modal.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%, -50%);background:var(--card);border:1px solid var(--line);border-radius:12px;padding:32px 48px;box-shadow:0 20px 40px rgba(0,0,0,0.2);z-index:9999;display:flex;flex-direction:column;align-items:center;text-align:center;max-width:400px;';
        
        modal.innerHTML = 
            '<style>@keyframes spinner { to { transform: rotate(360deg); } }</style>' +
            '<div style="width:36px;height:36px;border:3px solid var(--line);border-top-color:var(--accent);border-radius:50%;animation:spinner .8s linear infinite;margin-bottom:20px;"></div>' +
            '<div style="font-size:18px;font-weight:600;color:var(--text);margin-bottom:8px;">' + actionText + '</div>' +
            '<div style="font-size:13px;color:var(--muted);line-height:1.5;">Processing your records. This may take a few minutes for large batches. Please leave this page open.</div>';
            
        document.body.appendChild(overlay);
        document.body.appendChild(modal);
    }
    return ans;
}
window.addEventListener('DOMContentLoaded', function(){ updateCount(); updatePreviewNames(); });

function previewSelectedExcelRow() {
    var checked = document.querySelectorAll('input.row-chk:checked');
    var row = checked.length > 0 ? checked[0].closest('tr') : document.querySelector('#eqTable tbody tr');
    if (!row) { alert('No equipment rows loaded to preview.'); return; }

    var cells = row.querySelectorAll('td');
    if (cells.length < 14) return;

    var nameCell = row.querySelector('.name-preview');
    var assetName = nameCell ? nameCell.textContent.trim() : '';
    var mfr = cells[5] ? cells[5].textContent.trim() : '';
    var eqName = cells[6] ? cells[6].textContent.trim() : '';
    var model = cells[7] ? cells[7].textContent.trim() : '';
    var serial = cells[8] ? cells[8].textContent.trim() : '';
    var cmr = cells[13] ? cells[13].textContent.trim() : '';

    var ddlTpl = document.getElementById('<%= DdlTemplate.ClientID %>');
    var tplPath = ddlTpl && ddlTpl.value ? ddlTpl.value : 'c:\\idash_prints\\iDash_Std_Small.btw';

    openExcelPreviewModal(assetName, eqName || (mfr + ' ' + model), serial, cmr, tplPath);
}

async function openExcelPreviewModal(name, desc, sn, cmr, tpl) {
    var modal = document.getElementById('btExcelPreviewModal');
    var loader = document.getElementById('btXlLoading');
    var body = document.getElementById('btXlBody');
    var img = document.getElementById('btXlImg');
    var meta = document.getElementById('btXlMeta');

    if (!modal) return;
    modal.style.display = 'flex';
    loader.style.display = 'block';
    body.style.display = 'none';

    var fields = {
        lblname: name || '517 EE99999',
        lbldescription: desc || 'EQUIPMENT ASSET',
        lblsn: sn || 'SN-00000',
        lbleil: cmr || '138',
        lblrfidtag: (name ? 'E28011902000' + name.replace(/\s+/g, '') : 'E28011902000216503837493')
    };

    try {
        var resp = await fetch('api/BarTenderHandler.ashx?action=preview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: JSON.stringify({ template: tpl, fields: fields })
        });
        var data = await resp.json();
        loader.style.display = 'none';
        body.style.display = 'block';

        if ((data.Success || data.success) && (data.ImageBase64 || data.imageBase64)) {
            img.src = 'data:image/png;base64,' + (data.ImageBase64 || data.imageBase64);
            meta.innerHTML = 
                '<div><strong>Template:</strong> ' + tpl + '</div>' +
                '<div><strong>Asset:</strong> ' + (name || 'N/A') + ' &bull; <strong>S/N:</strong> ' + (sn || 'N/A') + ' &bull; <strong>CMR:</strong> ' + (cmr || 'N/A') + '</div>' +
                '<div><strong>Discovered Fields:</strong> ' + ((data.DiscoveredFields || data.discoveredFields || []).join(', ') || 'None') + '</div>';
        } else {
            img.src = '';
            meta.innerHTML = '<span style="color:var(--danger);font-weight:600;">&#9888; BarTender Engine Error: ' + (data.error || data.ErrorMessage || 'Could not render preview') + '</span>';
        }
    } catch (err) {
        loader.style.display = 'none';
        body.style.display = 'block';
        img.src = '';
        meta.innerHTML = '<span style="color:var(--danger);font-weight:600;">&#9888; API Error: ' + err.message + '</span>';
    }
}

function closeExcelPreviewModal() {
    var modal = document.getElementById('btExcelPreviewModal');
    if (modal) modal.style.display = 'none';
}
</script>

<!-- BarTender Excel Preview Modal -->
<div id="btExcelPreviewModal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; overflow:auto; background-color:rgba(0,0,0,0.65); backdrop-filter:blur(4px); align-items:center; justify-content:center;">
    <div style="background:var(--card); border:1px solid var(--line); border-radius:16px; width:90%; max-width:620px; box-shadow:0 25px 50px -12px rgba(0,0,0,0.5); overflow:hidden;">
        <div style="display:flex; justify-content:space-between; align-items:center; padding:16px 20px; border-bottom:1px solid var(--line); background:var(--chip);">
            <div style="display:flex; align-items:center; gap:8px;">
                <span style="font-size:18px;">&#127991;&#65039;</span>
                <span style="font-weight:700; font-size:16px; color:var(--text);">Excel Row BarTender Preview</span>
            </div>
            <button type="button" onclick="closeExcelPreviewModal()" style="background:none; border:none; color:var(--muted); font-size:24px; cursor:pointer; line-height:1; padding:0 4px;">&times;</button>
        </div>
        <div style="padding:20px; text-align:center;">
            <div id="btXlLoading" style="display:none; padding:40px; color:var(--muted);">
                <div style="display:inline-block; width:32px; height:32px; border:3px solid var(--line); border-top-color:var(--accent); border-radius:50%; animation:spinner 0.8s linear infinite; margin-bottom:12px;"></div>
                <div style="font-size:13px; font-weight:600;">Rendering live BarTender label preview...</div>
            </div>
            <div id="btXlBody">
                <img id="btXlImg" src="" alt="Label Preview" style="max-width:100%; max-height:360px; border-radius:8px; border:1px solid var(--line); box-shadow:0 4px 12px rgba(0,0,0,0.15); background:#fff; margin-bottom:12px;" />
                <div id="btXlMeta" style="display:flex; flex-direction:column; gap:4px; font-size:12px; color:var(--muted); text-align:left; background:var(--chip); padding:10px 14px; border-radius:8px; border:1px solid var(--line);"></div>
            </div>
        </div>
        <div style="display:flex; justify-content:flex-end; gap:10px; padding:14px 20px; border-top:1px solid var(--line); background:var(--chip);">
            <button type="button" class="btn btn-ghost" onclick="closeExcelPreviewModal()">Close</button>
        </div>
    </div>
</div>
<aw:Footer runat="server" />
</body>
</html>
