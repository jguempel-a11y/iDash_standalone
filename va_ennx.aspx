<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_ennx.aspx.cs" Inherits="iDash.va_ennx" EnableEventValidation="false" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <title>iDash &mdash; ENNX Export</title>
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

                body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    background: var(--bg);
                    margin: 0;
                    padding: 0;
                    color: var(--text);
                }

                .page-header {
                    background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 88%) 0%, var(--card) 60%);
                    border-bottom: 2px solid color-mix(in srgb, var(--accent), transparent 75%);
                    padding: 14px 28px;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    position: sticky;
                    top: 0;
                    z-index: 100;
                    box-shadow: 0 1px 12px color-mix(in srgb, var(--accent), transparent 90%);
                }

                .ph-brand { display: flex; align-items: center; gap: 12px; }
                .ph-icon {
                    width: 38px; height: 38px; border-radius: 10px;
                    display: flex; align-items: center; justify-content: center;
                    background: linear-gradient(135deg, var(--accent), color-mix(in srgb, var(--accent), #8B5CF6 40%));
                    font-size: 18px; color: #fff;
                    box-shadow: 0 2px 8px color-mix(in srgb, var(--accent), transparent 60%);
                    flex-shrink: 0;
                }
                .ph-title { font-size: 18px; font-weight: 700; color: var(--text); line-height: 1.2; margin: 0; }
                .ph-sub   { font-size: 11px; color: var(--muted); margin-top: 1px; }

                .ph-nav { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
                .ph-div { width: 1px; height: 22px; background: var(--line); margin: 0 2px; }

                .nav-pill {
                    display: inline-flex; align-items: center; gap: 5px;
                    padding: 6px 14px; border-radius: 20px;
                    font-size: 12px; font-weight: 600;
                    text-decoration: none; cursor: pointer;
                    border: 1.5px solid var(--line);
                    background: var(--chip); color: var(--text);
                    transition: border-color .2s, background .2s, box-shadow .15s, transform .12s;
                    line-height: 1;
                    white-space: nowrap;
                }
                .nav-pill:hover {
                    border-color: var(--accent);
                    transform: translateY(-1px);
                    box-shadow: 0 2px 8px color-mix(in srgb, var(--accent), transparent 80%);
                }
                .nav-pill-primary {
                    background: color-mix(in srgb, var(--accent), transparent 88%);
                    color: var(--accent);
                    border-color: color-mix(in srgb, var(--accent), transparent 60%);
                }
                .nav-pill-primary:hover { background: color-mix(in srgb, var(--accent), transparent 78%); border-color: var(--accent); }
                .nav-pill-docs {
                    background: color-mix(in srgb, #8B5CF6, transparent 88%);
                    color: #8B5CF6;
                    border-color: color-mix(in srgb, #8B5CF6, transparent 60%);
                }
                .nav-pill-docs:hover { background: color-mix(in srgb, #8B5CF6, transparent 78%); border-color: #8B5CF6; }
                .nav-pill-ghost { }


                .app-container {
                    max-width: 1400px;
                    margin: 20px auto;
                    padding: 0 20px;
                }

                .panel {
                    background: var(--card);
                    padding: 25px;
                    border-radius: 8px;
                    box-shadow: var(--shadow);
                    margin-bottom: 20px;
                    border: 1px solid var(--line);
                }

                .row {
                    margin-bottom: 15px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    flex-wrap: wrap;
                }

                .caption {
                    color: var(--muted);
                    margin-bottom: 15px;
                    font-size: 14px;
                }

                .btn {
                    padding: 8px 16px;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 14px;
                    background: var(--accent);
                    color: #001425;
                    transition: background 0.2s;
                    font-weight: 600;
                }

                .btn:hover {
                    opacity: 0.9;
                }

                .btn.secondary {
                    background: transparent;
                    border: 1px solid var(--accent);
                    color: var(--accent);
                }

                .btn.secondary:hover {
                    background: color-mix(in srgb, var(--accent), transparent 85%);
                }

                .btn-blue {
                    color: var(--accent);
                    text-decoration: none;
                    font-size: 14px;
                    margin-left: 10px;
                    cursor: pointer;
                }

                .btn-blue:hover {
                    text-decoration: underline;
                }

                .txt {
                    padding: 8px;
                    border: 1px solid var(--line);
                    border-radius: 4px;
                    font-size: 14px;
                    background: var(--chip);
                    color: var(--text);
                }

                .grid {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 10px;
                    font-size: 13px;
                }

                .grid th {
                    background: var(--chip);
                    text-align: left;
                    padding: 10px;
                    border-bottom: 2px solid var(--line);
                    color: var(--text);
                }

                .grid th a {
                    color: var(--text);
                    text-decoration: none;
                    display: block;
                }
                
                .grid th a:hover {
                    color: var(--accent);
                    text-decoration: underline;
                }

                .grid td {
                    padding: 10px;
                    border-bottom: 1px solid var(--line);
                    color: var(--text);
                }

                .grid tr:hover td {
                    background-color: color-mix(in srgb, var(--accent), transparent 95%);
                }

                .preview {
                    width: 100%;
                    height: 400px;
                    font-family: Consolas, monospace;
                    font-size: 13px;
                    padding: 10px;
                    border: 1px solid var(--line);
                    border-radius: 4px;
                    background: var(--preview-bg);
                    color: var(--preview-text);
                    resize: vertical;
                    box-sizing: border-box;
                    white-space: pre;
                    overflow: auto;
                }

                .pill {
                    background: var(--chip);
                    padding: 4px 10px;
                    border-radius: 12px;
                    font-size: 12px;
                    color: var(--muted);
                    margin-left: 10px;
                    border: 1px solid var(--chip-br);
                }

                .pill .count {
                    font-weight: bold;
                    color: #dbeafe;
                    margin-left: 4px;
                }

                .err {
                    color: var(--danger);
                    background: color-mix(in srgb, var(--danger), transparent 85%);
                    border: 1px solid var(--danger);
                    padding: 10px;
                    border-radius: 4px;
                    margin-bottom: 15px;
                }

                .ok {
                    color: var(--accent-2);
                    background: color-mix(in srgb, var(--accent-2), transparent 85%);
                    border: 1px solid var(--accent-2);
                    padding: 10px;
                    border-radius: 4px;
                    margin-bottom: 15px;
                }

                .twoCol {
                    display: grid;
                    grid-template-columns: 1fr;
                    gap: 20px;
                    margin-top: 20px;
                }

                @media (min-width: 1000px) {
                    .twoCol {
                        grid-template-columns: 1fr 1fr;
                    }
                }

                .scrollGrid {
                    max-height: 500px;
                    overflow-y: auto;
                    border: 1px solid var(--line);
                    background: var(--bg);
                }

                .calbtn {
                    background: none;
                    border: none;
                    font-size: 18px;
                    cursor: pointer;
                    padding: 0 5px;
                    color: var(--accent);
                }

                /* iDash Footer */
                .aw-footer {
                    margin-top: 28px;
                    padding: 12px 16px;
                    border-top: 1px solid var(--line);
                    font-size: 12px;
                    color: var(--muted);
                    opacity: 0.9;
                }

                .aw-footer-inner {
                    max-width: 1400px;
                    margin: 0 auto;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    gap: 16px;
                }

                .aw-left,
                .aw-right {
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }

                .aw-logo {
                    height: 20px;
                    width: auto;
                }

                .aw-name {
                    font-weight: 600;
                    color: var(--accent);
                    letter-spacing: 0.4px;
                }

                .aw-name .bang {
                    color: var(--accent-2);
                }

                .copy {
                    white-space: nowrap;
                }

                .id-logo {
                    height: 16px;
                    width: auto;
                    opacity: 0.85;
                }
            </style>
            <script>
                function selectEnnxDate(dateStr) {
                    var el = document.getElementById('TxtEnnxDate');
                    if (el) {
                        el.value = new Date(dateStr).toISOString().substring(0, 10);
                        var btn = document.getElementById('<%= BtnEnnxBuild.ClientID %>');
                        if (btn) btn.click();
                    }
                }

                function applyColumnCSS() {
                    let styleId = 'Style_GridEnnx';
                    let styleTag = document.getElementById(styleId);
                    if (!styleTag) {
                        styleTag = document.createElement('style');
                        styleTag.id = styleId;
                        document.head.appendChild(styleTag);
                    }
                    let key = 'aw_ennx_cols';
                    let hiddenCols = JSON.parse(localStorage.getItem(key) || '[]');
                    let css = '';
                    hiddenCols.forEach(index => {
                        css += `#GridEnnx th:nth-child(${index + 1}), #GridEnnx td:nth-child(${index + 1}) { display: none !important; }\n`;
                    });
                    styleTag.innerHTML = css;
                }

                function initColumnToggle() {
                    let grid = document.getElementById('GridEnnx');
                    let container = document.getElementById('ColToggleContainer');
                    if(!grid || !container) return;
                    
                    let headersTr = grid.querySelector('tr');
                    if(!headersTr) return;
                    let headers = headersTr.querySelectorAll('th');
                    if(headers.length === 0) return;

                    let key = 'aw_ennx_cols';
                    let hiddenCols = JSON.parse(localStorage.getItem(key) || '[]');

                    container.innerHTML = '<div style="width:100%; color:var(--muted); margin-bottom:4px; font-weight:600;">Check to display column:</div>';
                    
                    headers.forEach((th, index) => {
                        let headerText = th.innerText.trim();
                        if(!headerText) return; 

                        let label = document.createElement('label');
                        label.style.cssText = 'display:flex; align-items:center; gap:6px; cursor:pointer; background:var(--chip); padding:6px 10px; border-radius:6px; border:1px solid var(--line); color:var(--text); font-weight:normal; margin:0; font-size:13px;';
                        
                        let cb = document.createElement('input');
                        cb.type = 'checkbox';
                        cb.style.margin = '0';
                        cb.checked = !hiddenCols.includes(index);
                        
                        cb.addEventListener('change', function() {
                            let currentHidden = JSON.parse(localStorage.getItem(key) || '[]');
                            if(this.checked) {
                                currentHidden = currentHidden.filter(i => i !== index);
                            } else {
                                if(!currentHidden.includes(index)) currentHidden.push(index);
                            }
                            localStorage.setItem(key, JSON.stringify(currentHidden));
                            applyColumnCSS();
                        });
                        
                        label.appendChild(cb);
                        label.appendChild(document.createTextNode(' ' + headerText));
                        container.appendChild(label);
                    });
                }

                document.addEventListener('DOMContentLoaded', () => {
                    applyColumnCSS();
                    initColumnToggle();
                    initGridFilters();
                });

                function initGridFilters() {
                    const grid = document.getElementById('GridEnnx');
                    if (!grid) return;

                    const headers = grid.querySelectorAll('th');
                    if (headers.length === 0) return;
                    
                    if (grid.querySelector('.col-filter')) return;

                    headers.forEach((th, index) => {
                        const input = document.createElement('input');
                        input.type = 'text';
                        input.className = 'col-filter txt';
                        input.style.width = '100%';
                        input.style.marginTop = '6px';
                        input.style.boxSizing = 'border-box';
                        input.style.padding = '4px 6px';
                        input.style.fontSize = '11px';
                        input.style.borderColor = 'var(--line)';
                        input.style.background = 'var(--bg)';
                        input.style.color = 'var(--text)';
                        input.placeholder = 'Filter...';
                        input.setAttribute('data-col', index);
                        
                        input.addEventListener('keyup', filterGrid);
                        input.addEventListener('click', e => e.stopPropagation());
                        
                        th.appendChild(input);
                    });
                }

                function filterGrid() {
                    const grid = document.getElementById('GridEnnx');
                    if (!grid) return;
                    
                    const inputs = Array.from(grid.querySelectorAll('.col-filter'));
                    const rows = grid.querySelectorAll('tr:not(:first-child)');

                    const filters = inputs.map(input => ({
                        index: parseInt(input.getAttribute('data-col')),
                        text: input.value.toLowerCase().trim()
                    })).filter(f => f.text !== '');

                    rows.forEach(row => {
                        const cells = row.querySelectorAll('td');
                        let match = true;
                        
                        for (const filter of filters) {
                            if (cells[filter.index]) {
                                const cellText = cells[filter.index].innerText.toLowerCase();
                                if (cellText.indexOf(filter.text) === -1) {
                                    match = false;
                                    break;
                                }
                            }
                        }
                        
                        row.style.display = match ? '' : 'none';
                    });
                }
            </script>
        </head>

        <body>
            <form id="form1" runat="server">
                <div class="page-header">
                    <div class="ph-brand">
                        <div class="ph-icon">&#128228;</div>
                        <div>
                            <div class="ph-title">ENNX Export</div>
                            <div class="ph-sub">Build and export VA asset inventory files</div>
                        </div>
                    </div>
                    <div class="ph-nav">
                        <a href="ennxhistory.aspx" class="nav-pill nav-pill-primary">&#128197; Past Sessions</a>
                        <a href="documentation/va_ennx.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
                        <div class="ph-div"></div>
                        <asp:LinkButton ID="BtnRefreshData" runat="server" OnClick="BtnRefreshData_Click" CssClass="nav-pill nav-pill-ghost" UseSubmitBehavior="false">&#8635; Refresh</asp:LinkButton>
                        <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    </div>
                </div>

                <div class="app-container">
                    <asp:Literal ID="LitErr" runat="server" />

                    <!-- ENNX Panel -->
                    <asp:Panel ID="PnlEnnx" runat="server" CssClass="panel">
                        <div class="caption">
                            Select date, optional ID line, and (optionally) a time period window to build or export ENNX
                            text here.
                        </div>

                        <div class="row">
                            <asp:TextBox ID="TxtEnnxPrefix" runat="server" CssClass="txt"
                                placeholder="Header line 2 (default 'ID')" Width="250px" />
                        </div>

                        <div class="row">
                            <label style="margin-right:8px;">From Date</label>
                            <asp:TextBox ID="TxtEnnxDate" runat="server" CssClass="txt" ClientIDMode="Static"
                                TextMode="Date" AutoPostBack="true" OnTextChanged="TxtDate_Changed" />
                            <button type="button" class="calbtn" title="Pick date"
                                onclick="var el=document.getElementById('TxtEnnxDate'); if(el){ if (el.showPicker) el.showPicker(); else el.focus(); }">&#128197;</button>

                            <label style="margin-left:8px; margin-right:8px;">To Date (Optional)</label>
                            <asp:TextBox ID="TxtEnnxDateTo" runat="server" CssClass="txt" ClientIDMode="Static"
                                TextMode="Date" AutoPostBack="true" OnTextChanged="TxtDate_Changed" />
                            <button type="button" class="calbtn" title="Pick date"
                                onclick="var el=document.getElementById('TxtEnnxDateTo'); if(el){ if (el.showPicker) el.showPicker(); else el.focus(); }">&#128197;</button>

                            <!-- Time Period selector -->
                            <label style="margin-left:12px; margin-right:6px;">Time Period</label>
                            <asp:DropDownList ID="DDL_EnnxHours" runat="server" CssClass="txt" Width="180px"
                                AutoPostBack="true" OnSelectedIndexChanged="DDL_EnnxHours_SelectedIndexChanged">
                                <asp:ListItem Text="All day" Value="0" Selected="True"></asp:ListItem>
                                <asp:ListItem Text="Morning (12 AM - 12 PM)" Value="morning"></asp:ListItem>
                                <asp:ListItem Text="Afternoon (12 PM - 5 PM)" Value="afternoon"></asp:ListItem>
                                <asp:ListItem Text="Evening (5 PM - 12 AM)" Value="evening"></asp:ListItem>
                                <asp:ListItem Text="Last 1 hour" Value="1"></asp:ListItem>
                                <asp:ListItem Text="Last 2 hours" Value="2"></asp:ListItem>
                                <asp:ListItem Text="Last 3 hours" Value="3"></asp:ListItem>
                                <asp:ListItem Text="Last 6 hours" Value="6"></asp:ListItem>
                                <asp:ListItem Text="Last 12 hours" Value="12"></asp:ListItem>
                                <asp:ListItem Text="Last 24 hours" Value="24"></asp:ListItem>
                                <asp:ListItem Text="Custom Time Window" Value="custom"></asp:ListItem>
                            </asp:DropDownList>

                            <asp:Panel ID="PnlCustomTime" runat="server" Style="display:inline-flex; align-items:center; gap:6px; margin-left:6px;">
                                <asp:TextBox ID="TxtEnnxTimeFrom" runat="server" CssClass="txt" TextMode="Time" Width="105px" placeholder="From" />
                                <span style="color:var(--muted); font-size:12px;">to</span>
                                <asp:TextBox ID="TxtEnnxTimeTo" runat="server" CssClass="txt" TextMode="Time" Width="105px" placeholder="To" />
                            </asp:Panel>

                            <!-- Site selector -->
                            <label style="margin-left:15px; margin-right:6px;">Site</label>
                            <asp:DropDownList ID="DDL_EnnxSite" runat="server" AutoPostBack="True" OnSelectedIndexChanged="DDL_EnnxSite_SelectedIndexChanged" CssClass="txt" Width="100px" />

                            <!-- User selector -->
                            <label style="margin-left:15px; margin-right:6px;">User</label>
                            <asp:DropDownList ID="DDL_EnnxUser" runat="server" CssClass="txt" Width="200px" />
                        </div>

                        <div class="row" style="margin-top:10px;">
                            <label style="color:var(--muted); font-size:14px; display:flex; gap:6px; align-items:center; cursor:pointer; margin-right:15px;">
                                <asp:CheckBox ID="ChkTaggedOnly" runat="server" />
                                Tagged Items Only
                            </label>

                            <label style="color:var(--muted); font-size:14px; display:flex; gap:6px; align-items:center; cursor:pointer; margin-right:15px;">
                                <asp:CheckBox ID="ChkIncludeOitNoData" runat="server" Checked="true" />
                                Include OIT &amp; No-Data in Excel
                            </label>

                            <label style="margin-right:6px; font-size:14px; color:var(--muted);">CMR/EIL</label>
                            <asp:DropDownList ID="DDL_EnnxEil" runat="server" AutoPostBack="true" OnSelectedIndexChanged="DDL_EnnxEil_SelectedIndexChanged" CssClass="txt" Width="200px">
                                <asp:ListItem Text="-- All CMR/EILs --" Value="" />
                            </asp:DropDownList>
                        </div>

                        <!-- Buttons -->
                        <div class="row">
                            <asp:Button ID="BtnEnnxBuild" runat="server" CssClass="btn" Text="Build ENNX"
                                OnClick="BtnEnnxBuild_Click" />
                            <asp:Button ID="BtnEnnxDownload" runat="server" CssClass="btn secondary"
                                Text="Download ENNX Text" OnClick="BtnEnnxDownload_Click" />
                            <asp:LinkButton ID="BtnEnnxExportExcel" runat="server" CssClass="btn-blue"
                                Text="Export All to Excel (.xls)" OnClick="BtnEnnxExportExcel_Click" />
                            <asp:LinkButton ID="BtnEnnxEmail" runat="server" CssClass="btn-blue"
                                Text="Email ENNX + Excel" OnClick="BtnEnnxEmail_Click" />

                            <span class="pill"><span>Total</span> <span class="count">
                                    <asp:Literal ID="LitEnnxTotal" runat="server" />
                                </span></span>
                            <span class="pill"><span>Total Assets</span> <span class="count">
                                    <asp:Literal ID="LitEnnxAssets" runat="server" />
                                </span></span>
                            <span class="pill"><span>Total Locations</span> <span class="count">
                                    <asp:Literal ID="LitEnnxLocations" runat="server" />
                                </span></span>
                            <asp:PlaceHolder ID="PhTimePeriodBadge" runat="server" Visible="false">
                                <span class="pill" style="border-color:var(--accent); color:var(--accent); background:color-mix(in srgb, var(--accent) 12%, transparent);">
                                    <span>&#9201; Period:</span> <span class="count" style="color:var(--accent);"><asp:Literal ID="LitTimePeriodBadge" runat="server" /></span>
                                </span>
                            </asp:PlaceHolder>
                        </div>

                        <!-- OIT & No-Data Preview Buttons -->
                        <div style="margin-top:12px; display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
                            <asp:Button ID="BtnShowOit" runat="server" Text="Show OIT Assets"
                                OnClick="BtnShowOit_Click" CssClass="btn"
                                Style="background:var(--btn-alt); border:1px solid #f59e0b; color:#f59e0b; font-size:13px;" />
                            <asp:Button ID="BtnShowNoData" runat="server" Text="Show No Data Assets"
                                OnClick="BtnShowNoData_Click" CssClass="btn"
                                Style="background:var(--btn-alt); border:1px solid var(--danger, #ef4444); color:var(--danger, #ef4444); font-size:13px;" />
                            <span style="color:var(--muted); font-size:12px; margin-left:6px;">Preview before exporting to Excel</span>
                        </div>
                        <!-- OIT Preview -->
                        <div style="margin-top:10px;">
                            <asp:TextBox ID="TxtOitPreview" runat="server" TextMode="MultiLine" Rows="8"
                                Style="width:100%; background:var(--chip); color:#f59e0b; border:1px solid #f59e0b; font-family:monospace; font-size:12px; display:none; border-radius:6px; padding:10px;"
                                ReadOnly="true" />
                        </div>
                        <!-- No-Data Preview -->
                        <div style="margin-top:10px;">
                            <asp:TextBox ID="TxtNoDataPreview" runat="server" TextMode="MultiLine" Rows="8"
                                Style="width:100%; background:var(--chip); color:#f87171; border:1px solid var(--danger, #ef4444); font-family:monospace; font-size:12px; display:none; border-radius:6px; padding:10px;"
                                ReadOnly="true" />
                        </div>

                        <!-- 1. Text Preview (Most Important) -->
                        <div style="margin-top:20px;">
                            <h3 style="margin-bottom:8px; font-size:16px; color:var(--accent);">ENNX Text Preview</h3>
                            <asp:TextBox ID="TxtEnnxOutput" runat="server" TextMode="MultiLine" CssClass="preview"
                                ReadOnly="true" />
                        </div>

                        <!-- 2. Grid Data -->
                        <div style="margin-top:30px;">
                            <div style="display:flex; justify-content:space-between; align-items:flex-end;">
                                <div>
                                    <h3 style="margin-bottom:8px; font-size:16px; color:var(--muted); display:inline-block;">Data Details</h3>
                                    <span style="color:var(--muted); font-size:12px; margin-left:10px;">(Click header to sort. Type in boxes below headers to instantly filter rows.)</span>
                                </div>
                                <button type="button" class="btn" style="background:var(--btn-alt); border:1px solid var(--line); color:var(--text); font-size:12px; padding:6px 12px; cursor:pointer; border-radius:6px;" onclick="var c = document.getElementById('ColToggleContainer'); c.style.display = c.style.display === 'none' ? 'flex' : 'none';">&#9776; Columns</button>
                            </div>
                            
                            <div id="ColToggleContainer" style="display:none; background:var(--card); border:1px solid var(--line); padding:15px; border-radius:8px; margin:10px 0; flex-wrap:wrap; gap:10px; align-items:center; box-shadow:var(--shadow);">
                            </div>

                            <!-- Full Grid -->
                            <div class="scrollGrid" style="margin-top:10px;">
                                <asp:GridView ID="GridEnnx" runat="server" ClientIDMode="Static"
                                    AutoGenerateColumns="True" AllowSorting="True" OnSorting="Grid_Sorting"
                                    CssClass="grid" />
                            </div>
                        </div>

                    </asp:Panel>
                </div>

                <idash:Footer runat="server" />

                <!-- Hidden field for user preference if needed -->
                <asp:HiddenField ID="HidUser" runat="server" />
            </form>
        </body>

        </html>

