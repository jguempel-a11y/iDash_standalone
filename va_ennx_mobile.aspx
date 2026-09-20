<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_ennx_mobile.aspx.cs" Inherits="iDash.va_ennx_mobile" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <title>iDash &mdash; ENNX Mobile Export</title>
            <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <style>
                

                body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    background: var(--bg);
                    margin: 0;
                    padding: 0;
                    color: var(--text);
                }

                .header {
                    background:var(--card);
                    padding: 15px 20px;
                    border-bottom: 1px solid var(--line);
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                }

                .header h1 { margin: 0; font-size: 20px; color: var(--accent); }

                .home-link {
                    text-decoration: none;
                    color: var(--accent);
                    font-weight: 600;
                    font-size: 14px;
                }

                .notice {
                    background:var(--chip);
                    border:1px solid var(--line);
                    border-left: 4px solid var(--accent);
                    border-radius: 6px;
                    padding: 10px 16px;
                    margin-bottom: 18px;
                    font-size: 13px;
                    color:var(--accent);
                }
                .notice strong { color:var(--accent); }

                .app-container {
                    max-width: 1400px;
                    margin: 20px auto;
                    padding: 0 20px;
                }

                .panel {
                    background: var(--card);
                    padding: 25px;
                    border-radius: 8px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.3);
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

                .caption { color: var(--muted); margin-bottom: 15px; font-size: 14px; }

                .btn {
                    padding: 8px 16px;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 14px;
                    background: var(--accent);
                    color:var(--bg);
                    transition: background 0.2s;
                    font-weight: 600;
                }
                .btn:hover { opacity: 0.9; }

                .btn.secondary {
                    background: transparent;
                    border: 1px solid var(--accent);
                    color: var(--accent);
                }
                .btn.secondary:hover { background: color-mix(in srgb, var(--accent), transparent 85%); }

                .btn-blue {
                    color: var(--accent);
                    text-decoration: none;
                    font-size: 14px;
                    margin-left: 10px;
                    cursor: pointer;
                }
                .btn-blue:hover { text-decoration: underline; }

                .txt {
                    padding: 8px;
                    border: 1px solid var(--line);
                    border-radius: 4px;
                    font-size: 14px;
                    background:var(--chip);
                    color: var(--text);
                }

                .grid { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
                .grid th {
                    background:var(--chip);
                    text-align: left;
                    padding: 10px;
                    border-bottom:2px solid var(--line);
                    color: #fff;
                }
                .grid th a { color: #fff; text-decoration: none; display: block; }
                .grid th a:hover { color: var(--accent); text-decoration: underline; }
                .grid td { padding: 10px; border-bottom:1px solid var(--line); color: var(--text); }
                .grid tr:hover td { background-color:color-mix(in srgb, var(--text), transparent 95%); }

                .preview {
                    width: 100%;
                    height: 400px;
                    font-family: Consolas, monospace;
                    font-size: 13px;
                    padding: 10px;
                    border: 1px solid var(--line);
                    border-radius: 4px;
                    background:var(--chip);
                    color:var(--text);
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
                .pill .count { font-weight: bold; color:var(--text); margin-left: 4px; }

                .err {
                    color:var(--danger);
                    background:color-mix(in srgb, var(--danger), transparent 85%);
                    border:1px solid var(--danger);
                    padding: 10px;
                    border-radius: 4px;
                    margin-bottom: 15px;
                }
                .ok {
                    color:var(--accent-2);
                    background:color-mix(in srgb, var(--accent-2), transparent 85%);
                    border:1px solid var(--accent-2);
                    padding: 10px;
                    border-radius: 4px;
                    margin-bottom: 15px;
                }

                .scrollGrid {
                    max-height: 500px;
                    overflow-y: auto;
                    border: 1px solid var(--line);
                    background:var(--chip);
                }

                .calbtn {
                    background: none;
                    border: none;
                    font-size: 18px;
                    cursor: pointer;
                    padding: 0 5px;
                    color: var(--accent);
                }

                .twoCol {
                    display: grid;
                    grid-template-columns: 1fr;
                    gap: 20px;
                    margin-top: 20px;
                }
                @media (min-width: 1000px) { .twoCol { grid-template-columns: 1fr 1fr; } }

                .aw-footer { margin-top: 28px; padding: 12px 16px; border-top: 1px solid var(--line); font-size: 12px; color: var(--muted); }
            </style>
            <script>
                function applyColumnCSS() {
                    let styleId = 'Style_GridMobile';
                    let styleTag = document.getElementById(styleId);
                    if (!styleTag) {
                        styleTag = document.createElement('style');
                        styleTag.id = styleId;
                        document.head.appendChild(styleTag);
                    }
                    let key = 'aw_ennx_mobile_cols';
                    let hiddenCols = JSON.parse(localStorage.getItem(key) || '[]');
                    let css = '';
                    hiddenCols.forEach(function(index) {
                        css += '#GridMobile th:nth-child(' + (index+1) + '), #GridMobile td:nth-child(' + (index+1) + ') { display: none !important; }\n';
                    });
                    styleTag.innerHTML = css;
                }

                function initColumnToggle() {
                    let grid = document.getElementById('GridMobile');
                    let container = document.getElementById('ColToggleContainer');
                    if (!grid || !container) return;
                    let headersTr = grid.querySelector('tr');
                    if (!headersTr) return;
                    let headers = headersTr.querySelectorAll('th');
                    if (headers.length === 0) return;

                    let key = 'aw_ennx_mobile_cols';
                    let hiddenCols = JSON.parse(localStorage.getItem(key) || '[]');
                    container.innerHTML = '<div style="width:100%;color:var(--muted);margin-bottom:4px;font-weight:600;">Check to display column:</div>';

                    headers.forEach(function(th, index) {
                        let headerText = th.innerText.trim();
                        if (!headerText) return;
                        let label = document.createElement('label');
                        label.style.cssText = 'display:flex;align-items:center;gap:6px;cursor:pointer;background:var(--chip);padding:6px 10px;border-radius:6px;border:1px solid var(--line);color:var(--text);font-weight:normal;margin:0;font-size:13px;';
                        let cb = document.createElement('input');
                        cb.type = 'checkbox';
                        cb.style.margin = '0';
                        cb.checked = !hiddenCols.includes(index);
                        cb.addEventListener('change', function() {
                            let cur = JSON.parse(localStorage.getItem(key) || '[]');
                            if (this.checked) { cur = cur.filter(function(i){ return i !== index; }); }
                            else { if (!cur.includes(index)) cur.push(index); }
                            localStorage.setItem(key, JSON.stringify(cur));
                            applyColumnCSS();
                        });
                        label.appendChild(cb);
                        label.appendChild(document.createTextNode(' ' + headerText));
                        container.appendChild(label);
                    });
                }

                function initGridFilters() {
                    let grid = document.getElementById('GridMobile');
                    if (!grid || grid.querySelector('.col-filter')) return;
                    let headers = grid.querySelectorAll('th');
                    headers.forEach(function(th, index) {
                        let input = document.createElement('input');
                        input.type = 'text';
                        input.className = 'col-filter txt';
                        input.style.width = '100%';
                        input.style.marginTop = '6px';
                        input.style.boxSizing = 'border-box';
                        input.style.padding = '4px 6px';
                        input.style.fontSize = '11px';
                        input.style.borderColor = 'var(--line)';
                        input.style.background = '#0a101d';
                        input.placeholder = 'Filter...';
                        input.setAttribute('data-col', index);
                        input.addEventListener('keyup', filterGrid);
                        input.addEventListener('click', function(e){ e.stopPropagation(); });
                        th.appendChild(input);
                    });
                }

                function filterGrid() {
                    let grid = document.getElementById('GridMobile');
                    if (!grid) return;
                    let inputs = Array.prototype.slice.call(grid.querySelectorAll('.col-filter'));
                    let rows   = grid.querySelectorAll('tr:not(:first-child)');
                    let filters = inputs.map(function(inp){
                        return { index: parseInt(inp.getAttribute('data-col')), text: inp.value.toLowerCase().trim() };
                    }).filter(function(f){ return f.text !== ''; });

                    rows.forEach(function(row) {
                        let cells = row.querySelectorAll('td');
                        let match = true;
                        for (let i = 0; i < filters.length; i++) {
                            let f = filters[i];
                            if (cells[f.index] && cells[f.index].innerText.toLowerCase().indexOf(f.text) === -1) {
                                match = false; break;
                            }
                        }
                        row.style.display = match ? '' : 'none';
                    });
                }

                document.addEventListener('DOMContentLoaded', function() {
                    applyColumnCSS();
                    initColumnToggle();
                    initGridFilters();
                });
            </script>
        </head>

        <body>
            <form id="form1" runat="server">
                <div class="header">
                    <h1>ENNX Export &mdash; Mobile Scan (lastmodified)</h1>
                    <div>
                        <a href="va_ennx.aspx" class="home-link">Standard ENNX</a>
                        <span style="margin:0 10px;color:#ccc;">|</span>
                        <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                        <span style="margin:0 10px;color:#ccc;">|</span>
                        <asp:LinkButton ID="BtnRefreshData" runat="server" OnClick="BtnRefreshData_Click"
                            CssClass="btn" style="background:var(--chip);color:var(--accent);border:1px solid var(--line);font-size:12px;font-weight:600;padding:4px 8px;text-decoration:none;"
                            UseSubmitBehavior="false">Refresh App Data</asp:LinkButton>
                    </div>
                </div>

                <div class="app-container">
                    <div class="notice">
                        <strong>&#9432; Mobile Scan Mode</strong> &mdash;
                        This report filters on <strong>lastmodified</strong> instead of <em>lastinventoried</em>,
                        capturing assets scanned from the mobile app that do not yet update <em>lastinventoried</em>.
                    </div>

                    <asp:Literal ID="LitErr" runat="server" />

                    <asp:Panel ID="PnlMain" runat="server" CssClass="panel">
                        <div class="caption">
                            Select date range, site, and user &mdash; then click <strong>Build ENNX</strong> to generate the report.
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
                                onclick="var el=document.getElementById('TxtEnnxDate');if(el){if(el.showPicker)el.showPicker();else el.focus();}">&#128197;</button>

                            <label style="margin-left:8px;margin-right:8px;">To Date (Optional)</label>
                            <asp:TextBox ID="TxtEnnxDateTo" runat="server" CssClass="txt" ClientIDMode="Static"
                                TextMode="Date" AutoPostBack="true" OnTextChanged="TxtDate_Changed" />
                            <button type="button" class="calbtn" title="Pick date"
                                onclick="var el=document.getElementById('TxtEnnxDateTo');if(el){if(el.showPicker)el.showPicker();else el.focus();}">&#128197;</button>

                            <label style="margin-left:15px;margin-right:6px;">Site</label>
                            <asp:DropDownList ID="DDL_EnnxSite" runat="server" AutoPostBack="True"
                                OnSelectedIndexChanged="DDL_EnnxSite_SelectedIndexChanged" CssClass="txt" Width="110px" />

                            <label style="margin-left:15px;margin-right:6px;">User</label>
                            <asp:DropDownList ID="DDL_EnnxUser" runat="server" CssClass="txt" Width="200px" />
                        </div>

                        <div class="row" style="margin-top:10px;">
                            <label style="color:var(--muted);font-size:14px;display:flex;gap:6px;align-items:center;cursor:pointer;margin-right:15px;">
                                <asp:CheckBox ID="ChkTaggedOnly" runat="server" />
                                Tagged Items Only
                            </label>

                            <label style="margin-right:6px;font-size:14px;color:var(--muted);">CMR/EIL</label>
                            <asp:DropDownList ID="DDL_EnnxEil" runat="server" AutoPostBack="true"
                                OnSelectedIndexChanged="DDL_EnnxEil_SelectedIndexChanged" CssClass="txt" Width="200px">
                                <asp:ListItem Text="-- All CMR/EILs --" Value="" />
                            </asp:DropDownList>
                        </div>

                        <div class="row">
                            <asp:Button ID="BtnEnnxBuild" runat="server" CssClass="btn" Text="Build ENNX"
                                OnClick="BtnEnnxBuild_Click" />
                            <asp:Button ID="BtnEnnxDownload" runat="server" CssClass="btn secondary"
                                Text="Download ENNX Text" OnClick="BtnEnnxDownload_Click" />
                            <asp:LinkButton ID="BtnEnnxExportExcel" runat="server" CssClass="btn-blue"
                                Text="Export All to Excel (.xls)" OnClick="BtnEnnxExportExcel_Click" />
                            <asp:LinkButton ID="BtnEnnxEmail" runat="server" CssClass="btn-blue"
                                Text="Email ENNX + Excel" OnClick="BtnEnnxEmail_Click" />

                            <span class="pill"><span>Total</span> <span class="count"><asp:Literal ID="LitEnnxTotal" runat="server" /></span></span>
                            <span class="pill"><span>Assets</span> <span class="count"><asp:Literal ID="LitEnnxAssets" runat="server" /></span></span>
                            <span class="pill"><span>Locations</span> <span class="count"><asp:Literal ID="LitEnnxLocations" runat="server" /></span></span>
                        </div>

                        <!-- ENNX Text Preview -->
                        <div style="margin-top:20px;">
                            <h3 style="margin-bottom:8px;font-size:16px;color:var(--accent);">ENNX Text Preview</h3>
                            <asp:TextBox ID="TxtEnnxOutput" runat="server" TextMode="MultiLine"
                                CssClass="preview" ReadOnly="true" />
                        </div>

                        <!-- Grid -->
                        <div style="margin-top:30px;">
                            <div style="display:flex;justify-content:space-between;align-items:flex-end;">
                                <div>
                                    <h3 style="margin-bottom:8px;font-size:16px;color:var(--muted);display:inline-block;">Data Details</h3>
                                    <span style="color:var(--muted);font-size:12px;margin-left:10px;">(Click header to sort. Type in boxes to filter rows.)</span>
                                </div>
                                <button type="button" class="btn"
                                    style="background:var(--chip);border:1px solid #2ea8ff;color:var(--text);font-size:12px;padding:6px 12px;cursor:pointer;border-radius:6px;"
                                    onclick="var c=document.getElementById('ColToggleContainer');c.style.display=c.style.display==='none'?'flex':'none';">&#9776; Columns</button>
                            </div>
                            <div id="ColToggleContainer"
                                style="display:none;background:var(--bg);border:1px solid var(--line);padding:15px;border-radius:8px;margin:10px 0;flex-wrap:wrap;gap:10px;align-items:center;">
                            </div>
                            <div class="scrollGrid" style="margin-top:10px;">
                                <asp:GridView ID="GridMobile" runat="server" ClientIDMode="Static"
                                    AutoGenerateColumns="True" AllowSorting="True" OnSorting="Grid_Sorting"
                                    CssClass="grid" />
                            </div>
                        </div>
                    </asp:Panel>
                </div>

                <aw:Footer runat="server" />
                <asp:HiddenField ID="HidUser" runat="server" />
            </form>
        </body>
        </html>

