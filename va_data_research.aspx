<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_data_research.aspx.cs" Inherits="va_data_research" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <title>VA Tagging Team Data Research &mdash; iDash</title>
            <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>

            <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
            <link href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet" />
            <script src="https://cdn.datatables.net/2.0.8/js/dataTables.js"></script>

            <style>
                /* ============================================================
           GLOBAL THEME
           ============================================================ */
                :root {
                    --chip-br:  var(--line);
                    --table-head: var(--chip);
                    --table-row-hover: color-mix(in srgb, var(--accent), transparent 95%);
                }

                [data-theme="light"] {
                    --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
                }

                body {
                    margin: 0;
                    background: var(--bg);
                    color: var(--text);
                    font-family: Segoe UI, Tahoma, Arial, sans-serif;
                }

                * {
                    box-sizing: border-box;
                }

                a {
                    text-decoration: none;
                    color: inherit;
                }

                /* ============================================================
           LAYOUT
           ============================================================ */
                .page {
                    max-width: 1400px;
                    margin: 40px auto;
                    padding: 0 40px;
                }

                /* HEADER */
                .header-container {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    margin-bottom: 20px;
                }

                .header-title {
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 6px;
                    color: var(--text);
                }

                .header-sub {
                    font-size: 14px;
                    color: var(--muted);
                }

                .home-link {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    padding: 8px 16px;
                    border-radius: 8px;
                    color: var(--accent);
                    font-weight: 600;
                    transition: 0.2s;
                }

                .home-link:hover {
                    border-color: var(--accent);
                    background: var(--chip-br);
                }

                .aw-header-brand {
                    margin-top: 8px;
                    margin-bottom: 30px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    opacity: 0.95;
                }

                .aw-header-logo {
                    height: 26px;
                    width: auto;
                }

                .aw-header-text {
                    font-size: 14px;
                    font-weight: 600;
                    color: var(--accent);
                    letter-spacing: 0.4px;
                }

                .aw-header-text .bang {
                    color: var(--accent-2);
                }

                .aw-header-copy {
                    display: block;
                    font-size: 12px;
                    font-weight: 400;
                    color: var(--muted);
                    margin-top: 2px;
                }

                /* CARD */
                .card {
                    background: var(--card);
                    border: 1px solid var(--line);
                    border-radius: 14px;
                    padding: 24px;
                    margin-bottom: 24px;
                    box-shadow: var(--shadow);
                }

                .card h2 {
                    margin: 0 0 16px 0;
                    font-size: 20px;
                    font-weight: 600;
                    color: var(--accent);
                    border-bottom: 1px solid var(--line);
                    padding-bottom: 10px;
                }

                .card h3 {
                    font-size: 16px;
                    color: var(--muted);
                    margin: 20px 0 10px 0;
                }

                /* CONTROLS */
                .btn {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    color: var(--text);
                    padding: 8px 16px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 14px;
                    transition: 0.2s;
                }

                .btn:hover {
                    border-color: var(--accent);
                    background: var(--chip-br);
                }

                .btn-blue {
                    background: var(--accent);
                    color: #fff;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 14px;
                    font-weight: 600;
                }

                .btn-blue:hover {
                    opacity: 0.9;
                }

                .btn-secondary {
                    background: transparent;
                    border: 1px solid var(--muted);
                    color: var(--muted);
                }

                .btn-secondary:hover {
                    border-color: var(--text);
                    color: var(--text);
                }

                input[type="text"],
                input[type="file"] {
                    background: var(--bg);
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 8px 12px;
                    border-radius: 6px;
                    font-size: 14px;
                    outline: none;
                }

                input[type="text"]:focus {
                    border-color: var(--accent);
                }

                .file-upload {
                    margin: 10px 0 15px 0;
                    display: block;
                }

                /* COMPACT COLUMN CHOOSER DROPDOWN */
                .col-chooser-panel {
                    display: none;
                    position: absolute;
                    background: var(--card);
                    border: 1px solid var(--line);
                    padding: 15px;
                    border-radius: 8px;
                    box-shadow: 0 8px 24px rgba(0,0,0,0.35);
                    z-index: 100;
                    min-width: 240px;
                    max-height: 420px;
                    overflow-y: auto;
                }
                .col-chooser-panel .chooser-header {
                    font-weight: 600;
                    margin-bottom: 8px;
                    border-bottom: 1px solid var(--line);
                    padding-bottom: 6px;
                    color: var(--accent);
                    font-size: 13px;
                }
                .col-chooser-panel .chooser-actions {
                    display: flex;
                    gap: 6px;
                    margin-bottom: 8px;
                    flex-wrap: wrap;
                }
                .col-chooser-panel .chooser-actions button {
                    background: var(--chip);
                    border: 1px solid var(--line);
                    color: var(--muted);
                    padding: 3px 8px;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 11px;
                    transition: 0.15s;
                }
                .col-chooser-panel .chooser-actions button:hover {
                    border-color: var(--accent);
                    color: var(--text);
                }
                .col-chooser-panel .chooser-filter {
                    width: 100%;
                    background: var(--bg);
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 5px 8px;
                    border-radius: 4px;
                    font-size: 12px;
                    outline: none;
                    margin-bottom: 8px;
                    box-sizing: border-box;
                }
                .col-chooser-panel .chooser-filter:focus {
                    border-color: var(--accent);
                }
                .col-chooser-panel label {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    margin-bottom: 6px;
                    font-size: 13px;
                    cursor: pointer;
                    color: var(--text);
                    white-space: nowrap;
                }
                .col-chooser-panel input[type="checkbox"] {
                    margin: 0;
                    accent-color: var(--accent);
                }

                /* PILL */
                .pill {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    padding: 6px 14px;
                    border-radius: 20px;
                    font-size: 13px;
                    color: var(--muted);
                    display: inline-flex;
                    gap: 8px;
                    align-items: center;
                    margin-left: 10px;
                }

                .pill .count {
                    color: var(--text);
                    font-weight: 700;
                }

                /* GRID */
                .grid {
                    width: 100%;
                    border-collapse: collapse;
                    font-size: 13px;
                    margin-top: 15px;
                }

                .grid th {
                    background: var(--table-head);
                    color: var(--accent);
                    font-weight: 600;
                    text-align: left;
                    padding: 10px 14px;
                    border-bottom: 2px solid var(--line);
                }

                .grid td {
                    padding: 10px 14px;
                    border-bottom: 1px solid var(--line);
                    color: var(--text);
                }

                .grid tr:hover {
                    background: var(--table-row-hover);
                }

                /* DATATABLES OVERRIDES */
                .dataTables_wrapper .dataTables_length,
                .dataTables_wrapper .dataTables_filter,
                .dataTables_wrapper .dataTables_info,
                .dataTables_wrapper .dataTables_processing,
                .dataTables_wrapper .dataTables_paginate {
                    color: var(--muted) !important;
                    margin-bottom: 10px;
                }

                .dataTables_wrapper .dataTables_length select {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    color: var(--text);
                    padding: 4px;
                    border-radius: 4px;
                }

                .dataTables_wrapper .dataTables_filter input {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    color: var(--text);
                    padding: 4px;
                    border-radius: 4px;
                    margin-left: 6px;
                }

                table.dataTable tbody tr {
                    background-color: transparent !important;
                }

                table.dataTable.display tbody tr.odd {
                    background-color: transparent !important;
                }

                table.dataTable.display tbody tr.even {
                    background-color: transparent !important;
                }

                table.dataTable tbody tr:hover {
                    background-color: var(--table-row-hover) !important;
                }
            </style>
        </head>

        <body>
            <form id="form1" runat="server">
                <asp:ScriptManager ID="ScriptManager1" runat="server" />

                <div class="page">

                    <!-- Header -->
                    <div class="header-container">
                        <div>
                            <div class="header-title">VA Tagging Team Data Research</div>
                            <div class="header-sub">Advanced search and data reconciliation engines</div>
                        </div>
                        <a href="documentation/va_data_research.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a> <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    </div>

                    <div class="aw-header-brand" style="display:flex; align-items:center; gap:8px;">
                        <img src="<%= ResolveUrl("~/Assets/branding/IDIntegration.jpg") %>" style="height:20px; width:auto; border-radius:3px;" alt="ID Integration Inc." />
                        <span class="aw-header-text" style="font-weight:700; font-size:14px;">iDash<span class="bang" style="color:var(--accent);">.</span></span>
                        <span class="aw-header-copy" style="font-size:11px; color:var(--muted); font-style:italic;">by ID Integration Inc.</span>
                    </div>

                    <!-- ==========================================================
                 SECTION 1 -- EXCEL UPLOAD + DATATABLES
            ========================================================== -->
                    <div class="card">
                        <h2>VA Excel + iDash Data Research Tool</h2>

                        <div style="color:var(--muted); margin-bottom:8px;">Select Excel File to Load:</div>
                        <asp:FileUpload ID="FileUploadExcel" runat="server" CssClass="file-upload" />

                        <asp:Button ID="ButtonLoadData" runat="server" CssClass="btn-blue" Text="Load Data"
                            OnClick="ButtonLoadData_Click" />

                        <br />
                        <asp:Label ID="LabelStatus" runat="server" CssClass="message"
                            style="display:block; margin-top:10px; color:var(--accent-2);"></asp:Label>

                        <!-- DataTables dynamic table -->
                        <div style="display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:10px; margin-top:10px;">
                            <div></div>
                            <button type="button" class="btn" style="background:var(--btn-alt); border:1px solid var(--accent); color:var(--text); font-size:12px; padding:6px 12px; cursor:pointer; border-radius:6px;" onclick="$('#DTColToggleContainer').toggle()">&#9776; Columns</button>
                        </div>
                        <div id="DTColToggleContainer" style="background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:12px; margin-bottom:12px; display:none; flex-wrap:wrap; gap:10px; font-size:13px;"></div>

                        <table id="dataResearchTable" class="grid display">
                            <thead>
                                <tr class="header-row">
                                    <% var cols=Session["MyData_Columns"] as List<string>;
                                        if (cols != null)
                                        foreach (var c in cols)
                                        Response.Write("<th>" + Server.HtmlEncode(c) + "</th>");
                                        %>
                                </tr>
                            </thead>
                            <tbody></tbody>
                        </table>
                    </div>

                    <!-- ==========================================================
                 SECTION 2 -- SQL LIVE SEARCH PANEL
            ========================================================== -->
                    <div class="card">
                        <h2>Live DB Asset Research (dbo.v_asset)</h2>                        <style>
                        .grid-api{
                          border-collapse:collapse;
                          width:100%;
                          font-size:12px;
                        }
                        .grid-api th, .grid-api td{
                          border:1px solid var(--line);
                          padding:4px 6px;
                          white-space:nowrap;
                          vertical-align:top;
                        }
                        .grid-api th{
                          background:var(--chip);
                        }
                        .filter-input{
                          width:100%;
                          box-sizing:border-box;
                          background:var(--bg);
                          color:var(--text);
                          border:1px solid var(--line);
                          margin-top:4px;
                          padding:3px 6px;
                          border-radius:3px;
                        }
                        .hidden{ display:none !important; }
                        </style>
                        
                        <div class="toolbar" style="display:flex; gap:10px; align-items:center; margin-bottom:12px; flex-wrap:wrap; margin-top:20px;">
                            <label style="color:var(--muted); font-size:14px;">Site:</label>
                            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="form-control" style="width:200px; background:var(--bg); border:1px solid var(--line); color:var(--text); padding:8px 12px; border-radius:6px;" ClientIDMode="Static" onchange="doClear()" />

                            <input type="text" id="TxtAssetSearch" placeholder="Find asset (512 EE..., serial, SP1D118, EIL/CMR...)" style="width:320px;" class="form-control" onkeydown="if(event.keyCode==13){doSearch(); return false;}"/>

                            <button type="button" class="btn-blue" onclick="doSearch()">Search</button>
                            <button type="button" class="btn btn-secondary" onclick="doClear()">Clear</button>
                            <button type="button" id="btnColumns" class="btn" onclick="toggleColumnChooser(event)" style="position:relative;">&#9776; Columns</button>

                            <!-- COMPACT COLUMN CHOOSER DROPDOWN -->
                            <div id="colChooser" class="col-chooser-panel">
                                <div class="chooser-header">Toggle Columns</div>
                                <div class="chooser-actions">
                                    <button type="button" onclick="showAllCols()">Show all</button>
                                    <button type="button" onclick="hideAllCols()">Hide all</button>
                                    <button type="button" onclick="resetDefaultCols()">Reset default</button>
                                </div>
                                <input id="colFilter" type="text" class="chooser-filter" placeholder="Filter columns..." />
                                <div id="colList"></div>
                            </div>
                        </div>

                        <div id="statusDiv" style="margin-bottom:10px; opacity:0.8; font-size:12px;"></div>

                        <!-- GRID -->
                        <div id="tblGridContainer" style="overflow-x:auto; width:100%;">
                        </div>

                        <script type="text/javascript">
                        var TRUE_DEFAULT = "name,description,lastobservedlocation,listvalue1,text1,text2,text3,text4,text7,text8,text9,text16,text19,text20,lastinventoried".split(',');
                        var savedCols = localStorage.getItem('DataResearchCustomCols');
                        var DEFAULT_VISIBLE = savedCols ? JSON.parse(savedCols) : TRUE_DEFAULT;

                        function saveCustomColState() {
                            var checked = [];
                            var inputs = document.querySelectorAll('#colList input[type=checkbox]');
                            for(var i=0; i<inputs.length; i++) {
                                if(inputs[i].checked) checked.push(inputs[i].getAttribute('data-col'));
                            }
                            localStorage.setItem('DataResearchCustomCols', JSON.stringify(checked));
                        }
                        var filterTimers = {};
                        var allColumns = [];

                        function getNiceName(col) {
                            switch (col.toLowerCase()) {
                                case "name": return "EE / Name";
                                case "description": return "Description";
                                case "lastobservedlocation": return "Last Observed Location";
                                case "listvalue1": return "Disposal Status";
                                case "text1": return "MANUFACTURER";
                                case "text2": return "MODEL";
                                case "text3": return "SERIAL #";
                                case "text4": return "EQUIPMENT CATEGORY";
                                case "text5": return "SERVICE POINTER";
                                case "text6": return "SP + LOCATION";
                                case "text7": return "STATION NUMBER";
                                case "text8": return "CMR/EIL (from file)";
                                case "text9": return "PURCHASE ORDER #";
                                case "text10": return "PHYSICAL INVENTORY DATE (raw)";
                                case "text11": return "SP + PREVIOUS LOCATION";
                                case "text12": return "ENTRY NUMBER";
                                case "text13": return "EMPL_ID";
                                case "text14": return "SUBSTATION";
                                case "text16": return "LOCATION TAGGED (FOUND)";
                                case "text17": return "TAGGED ON DATE";
                                case "text18": return "TAGGED";
                                case "text19": return "TAG_TYPE";
                                case "text20": return "NOTES";
                                case "lastinventoried": return "Last Inventoried";
                                default: return col;
                            }
                        }

                        function safeCssClass(col) {
                            return col.replace(/[^a-zA-Z0-9_\-]/g, '');
                        }

                        function encodeHTML(str) {
                            if (!str) return "";
                            return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
                        }

                        var chooserBuilt = false;
                        function buildColumnChooser(cols) {
                            var list = document.getElementById('colList');
                            list.innerHTML = '';

                            for (var i = 0; i < cols.length; i++) {
                                var col = cols[i].toLowerCase();
                                var label = document.createElement('label');

                                var chk = document.createElement('input');
                                chk.type = 'checkbox';
                                chk.setAttribute('data-col', col);
                                chk.checked = (DEFAULT_VISIBLE.indexOf(col) >= 0);
                                chk.onchange = function () {
                                    toggleColumn(this.getAttribute('data-col'), this.checked);
                                    saveCustomColState();
                                };

                                label.appendChild(chk);
                                label.appendChild(document.createTextNode(' ' + getNiceName(col)));
                                list.appendChild(label);
                            }
                            chooserBuilt = true;
                            wireChooserFilter();
                        }

                        function toggleColumnChooser(e) {
                            var chooser = document.getElementById('colChooser');
                            if (chooser.style.display === 'block') {
                                chooser.style.display = 'none';
                            } else {
                                chooser.style.display = 'block';
                                var rect = e.target.getBoundingClientRect();
                                chooser.style.top = (rect.bottom + window.scrollY + 5) + 'px';
                                chooser.style.left = (rect.left + window.scrollX) + 'px';
                            }
                        }

                        document.addEventListener('click', function(e) {
                            var chooser = document.getElementById('colChooser');
                            if (chooser && chooser.style.display === 'block' &&
                                !e.target.closest('#colChooser') && !e.target.closest('#btnColumns')) {
                                chooser.style.display = 'none';
                            }
                        });

                        function doSearch() {
                            var q = document.getElementById('TxtAssetSearch').value || "";
                            loadAssets(q, 1000, q === "" ? "Loaded latest 1000 assets." : "Search: " + q);
                        }

                        function doClear() {
                            document.getElementById('TxtAssetSearch').value = "";
                            loadAssets("", 200, "Cleared search. Loaded latest 200 assets.");
                        }

                        function loadAssets(q, topN, msg) {
                            var status = document.getElementById('statusDiv');
                            status.innerHTML = '<span style="color:var(--accent)">Loading data...</span>';
                            document.getElementById('tblGridContainer').innerHTML = '';

                            var siteEl = document.getElementById('DdlCompany');
                            var siteStr = siteEl ? siteEl.value : "0";

                            $.ajax({
                                type: "POST",
                                url: "va_data_research.aspx/SearchSqlAssets",
                                data: JSON.stringify({ search: q, topN: topN, site: siteStr }),
                                contentType: "application/json; charset=utf-8",
                                dataType: "json",
                                success: function (response) {
                                    var data = JSON.parse(response.d);
                                    if (data.length === 0) {
                                        status.innerHTML = "<div style='color:#ef4444'>No rows returned.</div>";
                                    } else {
                                        status.innerHTML = msg + " &nbsp; <b>Rows:</b> " + data.length;
                                        renderGrid(data);
                                    }
                                },
                                error: function (err) {
                                    status.innerHTML = "<div style='color:#ef4444'>Error loading data: " + err.responseText + "</div>";
                                }
                            });
                        }

                        function renderGrid(data) {
                            allColumns = Object.keys(data[0]);
                            
                            var html = "<table class='grid-api'><thead><tr>";
                            for (var c = 0; c < allColumns.length; c++) {
                                var col = safeCssClass(allColumns[c]);
                                html += "<th class='" + col + "'>" + encodeHTML(getNiceName(col)) + "<br />";
                                html += "<input class='filter-input' placeholder='Filter...' onclick='event.stopPropagation();' onkeydown='if(event.keyCode==13){event.preventDefault();return false;}' onkeyup=\"queueFilter('" + col + "', this.value)\" /></th>";
                            }
                            html += "</tr></thead><tbody>";

                            for (var r = 0; r < data.length; r++) {
                                html += "<tr>";
                                for (var c = 0; c < allColumns.length; c++) {
                                    var col = safeCssClass(allColumns[c]);
                                    html += "<td class='" + col + "'>" + encodeHTML(data[r][allColumns[c]]) + "</td>";
                                }
                                html += "</tr>";
                            }
                            html += "</tbody></table>";

                            document.getElementById('tblGridContainer').innerHTML = html;

                            buildColumnChooser(allColumns);
                            applyDefaultVisibility();
                            wireChooserFilter();
                        }

                        function queueFilter(col, val) {
                            if (filterTimers[col]) clearTimeout(filterTimers[col]);
                            filterTimers[col] = setTimeout(function () { filterCol(col, val); }, 200);
                        }

                        function toggleColumn(col, show) {
                            var cells = document.querySelectorAll('.' + col);
                            for (var i = 0; i < cells.length; i++) {
                                if (show) cells[i].classList.remove('hidden');
                                else cells[i].classList.add('hidden');
                            }
                        }

                        function applyDefaultVisibility() {
                            var headers = document.querySelectorAll('#tblGridContainer .grid-api th');
                            for (var i = 0; i < headers.length; i++) {
                                var col = (headers[i].className || '').toLowerCase();
                                if (!col) continue;
                                toggleColumn(col, DEFAULT_VISIBLE.indexOf(col) >= 0);
                            }
                        }

                        function filterCol(col, val) {
                            val = (val || '').toLowerCase().trim();
                            var rows = document.querySelectorAll('.grid-api tbody tr');

                            let op = null;
                            let numVal = null;
                            let isDays = false;
                            
                            if (val.startsWith('>') || val.startsWith('<') || val.startsWith('=')) {
                                op = val[0];
                                let inner = val.substring(1).trim();
                                if (val.startsWith('>=') || val.startsWith('<=') || val.startsWith('<>')) {
                                    op = val.substring(0, 2);
                                    inner = val.substring(2).trim();
                                }
                                if (inner.endsWith('days') || inner.endsWith('day')) {
                                    isDays = true;
                                    inner = inner.replace('days', '').replace('day', '').trim();
                                }
                                let parsed = parseFloat(inner);
                                if (!isNaN(parsed)) numVal = parsed;
                            }

                            for (var i = 0; i < rows.length; i++) {
                                var cell = rows[i].querySelector('.' + col);
                                if (!cell) continue;

                                var text = (cell.innerText || '').toLowerCase().trim();
                                var match = true;

                                if (op && numVal !== null) {
                                    if (isDays) {
                                        let cellDate = new Date(text);
                                        if (!isNaN(cellDate)) {
                                            let diffTime = Math.abs(new Date() - cellDate);
                                            let diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                                            
                                            if (op === '<' && diffDays >= numVal) match = false;
                                            else if (op === '<=' && diffDays > numVal) match = false;
                                            else if (op === '>' && diffDays <= numVal) match = false;
                                            else if (op === '>=' && diffDays < numVal) match = false;
                                            else if (op === '=' && diffDays !== numVal) match = false;
                                        } else { match = false; }
                                    } else {
                                        let cellNum = parseFloat(text);
                                        if (!isNaN(cellNum)) {
                                            if (op === '<' && cellNum >= numVal) match = false;
                                            else if (op === '<=' && cellNum > numVal) match = false;
                                            else if (op === '>' && cellNum <= numVal) match = false;
                                            else if (op === '>=' && cellNum < numVal) match = false;
                                            else if (op === '=' && cellNum !== numVal) match = false;
                                        } else if (op === '=') {
                                            if (text !== val.substring(1).trim()) match = false;
                                        } else { match = false; }
                                    }
                                } else {
                                    var parts = val.split(' ');
                                    for (var p = 0; p < parts.length; p++) {
                                        if (parts[p] && text.indexOf(parts[p]) === -1) { match = false; break; }
                                    }
                                }
                                rows[i].style.display = match ? '' : 'none';
                            }
                        }

                        function showAllCols() {
                            var headers = document.querySelectorAll('.grid-api th');
                            for (var i = 0; i < headers.length; i++) {
                                var col = (headers[i].className || '').toLowerCase();
                                if (col) toggleColumn(col, true);
                            }
                            var inputs = document.querySelectorAll('#colList input[type=checkbox]');
                            for (var j = 0; j < inputs.length; j++) inputs[j].checked = true;
                            saveCustomColState();
                        }

                        function hideAllCols() {
                            var headers = document.querySelectorAll('.grid-api th');
                            for (var i = 0; i < headers.length; i++) {
                                var col = (headers[i].className || '').toLowerCase();
                                if (col) toggleColumn(col, false);
                            }
                            var inputs = document.querySelectorAll('#colList input[type=checkbox]');
                            for (var j = 0; j < inputs.length; j++) inputs[j].checked = false;
                            saveCustomColState();
                        }

                        function resetDefaultCols() {
                            var headers = document.querySelectorAll('.grid-api th');
                            for (var i = 0; i < headers.length; i++) {
                                var col = (headers[i].className || '').toLowerCase();
                                if (col) toggleColumn(col, TRUE_DEFAULT.indexOf(col) >= 0);
                            }
                            var inputs = document.querySelectorAll('#colList input[type=checkbox]');
                            for (var i = 0; i < inputs.length; i++) {
                                var col = (inputs[i].getAttribute('data-col') || '').toLowerCase();
                                inputs[i].checked = (TRUE_DEFAULT.indexOf(col) >= 0);
                            }
                            saveCustomColState();
                        }

                        function wireChooserFilter() {
                            var f = document.getElementById('colFilter');
                            if (!f) return;
                            f.onkeydown = function(e){
                                e = e || window.event;
                                if (e.keyCode == 13) { if (e.preventDefault) e.preventDefault(); e.returnValue = false; return false; }
                            };
                            f.onkeyup = function () {
                                var q = (this.value || '').toLowerCase();
                                var labels = document.querySelectorAll('#colList label');
                                for (var i = 0; i < labels.length; i++) {
                                    var t = (labels[i].innerText || '').toLowerCase();
                                    labels[i].style.display = (q === '' || t.indexOf(q) >= 0) ? 'flex' : 'none';
                                }
                            };
                        }

                        // Load initial assets safely!
                        $(document).ready(function() {
                            doClear(); 
                        });
                        </script>

                    </div>

                    <aw:Footer runat="server" />
                </div>
            </form>

            <script type="text/javascript">
                function initDT() {
                    if ($('#dataResearchTable thead tr.header-row th').length === 0) return;

                    $('#dataResearchTable').DataTable({
                        processing: true,
                        serverSide: true,
                        pageLength: 25,
                        destroy: true,
                        destroy: true,
                        dom: 'lrtip', 
                        stateSave: true,
                        stateLoadParams: function (settings, data) {
                            data.search.search = "";
                            if (data.columns) {
                                for (var i=0; i<data.columns.length; i++) {
                                    data.columns[i].search.search = "";
                                }
                            }
                        },
                        orderCellsTop: true, // Allow inputs in th
                        ajax: {
                            url: "va_data_research.aspx/GetTableData",
                            type: "POST",
                            contentType: "application/json; charset=utf-8",
                            dataType: "json",
                            data: function (d) {
                                var sc = [];
                                if (d.columns) {
                                    d.columns.forEach(function (c) { sc.push({ value: c.search.value }); });
                                }
                                var sCol = 0;
                                var sDir = 'asc';
                                if (d.order && d.order.length > 0) {
                                    sCol = d.order[0].column;
                                    sDir = d.order[0].dir;
                                }
                                return JSON.stringify({ 
                                    draw: d.draw, start: d.start, length: d.length, 
                                    searchCols: sc, sortCol: sCol, sortDir: sDir
                                });
                            },
                            dataSrc: function (json) { 
                                var parsed = JSON.parse(json.d);
                                json.draw = parsed.draw;
                                json.recordsTotal = parsed.recordsTotal;
                                json.recordsFiltered = parsed.recordsFiltered;
                                return parsed.data; 
                            }
                        },
                        initComplete: function () {
                            this.api().columns().every(function () {
                                var column = this;
                                var headerNode = $(column.header());
                                
                                // Clean up if input already exists (prevents duplicate inputs on PostBacks)
                                headerNode.find('input.dt-col-search').remove();
                                
                                // Create explicitly scoped column input
                                var input = $('<input type="text" placeholder="Search..." class="dt-col-search" style="width:100%; margin-top:6px; box-sizing:border-box; background:var(--chip); border:1px solid var(--line); color:#fff; padding:4px; font-weight:normal;" />')
                                    .appendTo(headerNode)
                                    .on('keyup change clear', function (e) {
                                        // Wait until return is pressed or field is cleared to minimize DB spamming
                                        if (e.type === 'keyup' && e.keyCode !== 13) return;
                                        if (column.search() !== this.value) {
                                            column.search(this.value).draw();
                                        }
                                    })
                                    .on('click', function(e) {
                                        // Stop DataTables from sorting the table when user is trying to click into the search box
                                        e.stopPropagation();
                                    });
                            });

                            // Custom Column visibility toggles
                            var container = $('#DTColToggleContainer');
                            container.html('<div style="width:100%; color:var(--muted); margin-bottom:4px; font-weight:600;">Check to display column:</div>');
                            this.api().columns().every(function () {
                                var column = this;
                                var headerText = $(column.header()).text().trim();
                                if(!headerText) return;

                                var label = $('<label style="display:flex; align-items:center; gap:6px; cursor:pointer; background:var(--chip); padding:6px 10px; border-radius:6px; border:1px solid var(--line); color:var(--text); font-weight:normal; margin:0;"></label>');
                                var cb = $('<input type="checkbox" style="margin:0;" />');
                                cb.prop('checked', column.visible());
                                
                                cb.on('change', function() {
                                    column.visible(this.checked);
                                });
                                
                                label.append(cb).append(document.createTextNode(' ' + headerText));
                                container.append(label);
                            });
                        }
                    });
                }

                $(document).ready(function () { initDT(); });
                Sys.Web.Forms.PageRequestManager.getInstance().add_endRequest(function () { initDT(); });
            </script>
        </body>
        </html>tml>
