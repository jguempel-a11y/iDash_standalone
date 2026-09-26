<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_previous_location.aspx.cs" Inherits="va_previous_location" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">
    <meta charset="utf-8" />
    <title>Previous Location Lookup - iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        /* ============================================================
           GLOBAL THEME
           ============================================================ */
        :root {
            --chip-br: var(--line);
            --table-head: var(--chip);
            --table-row-hover: rgba(0,0,0,0.02);
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

        /* LAYOUT */
        .page {
            max-width: 1400px;
            margin: 40px auto;
            padding: 0 40px;
        }

        /* HEADER */
        .header-title {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 6px;
        }

        .header-sub {
            font-size: 14px;
            color: var(--muted);
            margin-bottom: 32px;
        }

        .aw-header-brand {
            margin-top: 8px;
            margin-bottom: 14px;
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
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
        }

        .card h2 {
            margin: 0 0 12px 0;
            font-size: 20px;
            font-weight: 600;
            color: var(--accent);
        }

        .caption {
            font-size: 14px;
            color: var(--muted);
            margin-bottom: 20px;
            max-width: 700px;
            line-height: 1.5em;
        }

        /* CONTROLS */
        .row {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }

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

        .txt {
            background: var(--chip);
            border: 1px solid var(--line);
            color: var(--text);
            padding: 10px 14px;
            border-radius: 6px;
            font-size: 15px;
            outline: none;
            width: 320px;
        }

        .txt:focus {
            border-color: var(--accent);
        }

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
        }

        .pill .count {
            color: var(--text);
            font-weight: 700;
        }

        /* GRID */
        .scrollGrid {
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: auto;
            max-height: 600px;
            background: var(--bg);
            margin-top: 20px;
        }

        .grid {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }

        .grid th {
            background: var(--table-head);
            color: var(--accent);
            font-weight: 600;
            text-align: left;
            padding: 12px 16px;
            position: sticky;
            top: 0;
            z-index: 10;
            white-space: nowrap;
        }

        .grid td {
            padding: 10px 16px;
            border-bottom: 1px solid var(--line);
            color: var(--text);
            vertical-align: top;
        }

        .grid tr:hover {
            background: var(--table-row-hover);
        }

        /* BACK BUTTON */
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            color: var(--muted);
            margin-bottom: 20px;
            font-size: 14px;
        }

        .back-link:hover {
            color: var(--accent);
        }

        .status-msg {
            margin-top: 10px;
            font-size: 14px;
        }
        .status-msg.err {
            color: var(--danger);
        }
        .status-msg.ok {
            color: var(--accent-2);
        }

        .filter {
            width: 100%;
            box-sizing: border-box;
            background: var(--chip);
            color: var(--text);
            border: 1px solid var(--line);
            margin-top: 6px;
            padding: 4px 6px;
            border-radius: 4px;
            font-size: 12px;
            outline: none;
        }
        .filter:focus {
            border-color: var(--accent);
        }
        .sort-header {
            cursor: pointer;
            user-select: none;
        }
        .sort-header:hover {
            color: #fff;
        }

        .calbtn {
            background: none;
            border: none;
            font-size: 18px;
            cursor: pointer;
            padding: 0 5px;
            color: var(--accent);
        }

        .col-chooser-panel {
            display: none;
            position: absolute;
            background: var(--card);
            border: 1px solid var(--line);
            padding: 15px;
            border-radius: 8px;
            box-shadow:var(--shadow);
            z-index: 100;
            min-width: 200px;
        }
        .col-chooser-panel label {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 8px;
            font-size: 13px;
            cursor: pointer;
            color: var(--text);
        }
        .col-chooser-panel input[type="checkbox"] {
            margin: 0;
            accent-color: var(--accent);
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">
        <div class="page">

            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>

            <div class="header-title">Location &amp; Scan History</div>
            <div class="header-sub">Instantly explore the scanned location history for any asset or EIL group.</div>

            <div class="aw-header-brand">
                <img src="<%= ResolveUrl("~/Assets/branding/assetworx.jpg") %>" class="aw-header-logo" />
                <span class="aw-header-text">AssetWorx<span class="bang">!</span> <span
                        class="aw-header-copy">by InfinID Technologies</span></span>
            </div>

            <div class="card">
                <h2>Asset Search</h2>

                <div class="row">
                    <label style="color:var(--muted); font-size:14px; margin-right:4px;">Site:</label>
                    <asp:DropDownList ID="DdlCompany" runat="server" CssClass="txt" Width="200px" ClientIDMode="Static" onchange="doSearch()" />

                    <label style="color:var(--muted); font-size:14px; margin-left:12px; margin-right:4px;">From Date:</label>
                    <input type="date" id="TxtFrom" class="txt" style="width:150px;" onchange="doSearch()" />
                    <button type="button" class="calbtn" title="Pick date" onclick="var el=document.getElementById('TxtFrom'); if(el){ if (el.showPicker) el.showPicker(); else el.focus(); }">&#128197;</button>

                    <label style="color:var(--muted); font-size:14px; margin-left:12px; margin-right:4px;">To Date:</label>
                    <input type="date" id="TxtTo" class="txt" style="width:150px;" onchange="doSearch()" />
                    <button type="button" class="calbtn" title="Pick date" onclick="var el=document.getElementById('TxtTo'); if(el){ if (el.showPicker) el.showPicker(); else el.focus(); }">&#128197;</button>
                </div>
                
                <div class="row">
                    <input type="text" id="TxtSearch" class="txt" placeholder="Enter Asset, Serial, or EIL..." 
                        onkeydown="if(event.keyCode==13){ doSearch(); return false; }" style="width:400px;" />
                    
                    <button type="button" class="btn-blue" onclick="doSearch()">Search History</button>
                    <button type="button" class="btn" onclick="clearSearch()">Clear</button>
                    <button type="button" id="btnColumns" class="btn" onclick="toggleColumnChooser(event)">Columns</button>

                    <div id="colChooser" class="col-chooser-panel">
                        <div style="font-weight:600; margin-bottom:10px; border-bottom:1px solid var(--line); padding-bottom:6px; color:var(--accent);">Toggle Columns</div>
                        <div id="colChooserList"></div>
                    </div>

                    <span class="pill">
                        <span>Total Records</span>
                        <span class="count" id="LitCount">0</span>
                    </span>
                </div>

                <div id="statusDiv" class="status-msg"></div>

                <div class="scrollGrid" id="gridContainer" style="display:none;">
                    <table class="grid" id="historyTable">
                        <thead>
                            <tr>
                                <th>
                                    <div class="sort-header" onclick="sortTable(0)">Asset # &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="0" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(1)">Description &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="1" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(2)">EIL &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="2" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(3)">Serial &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="3" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(4)">Location Scanned &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="4" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(5)">Scan Date (UTC) &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="5" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(6)">Previous Loc (text11) &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="6" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(7)">Last Observed Loc &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="7" onkeyup="filterTable()" placeholder="..." />
                                </th>
                                <th>
                                    <div class="sort-header" onclick="sortTable(8)">Current Loc (text6) &#9650;&#9660;</div>
                                    <input type="text" class="filter" data-col="8" onkeyup="filterTable()" placeholder="..." />
                                </th>
                            </tr>
                        </thead>
                        <tbody id="historyBody">
                        </tbody>
                    </table>
                </div>

            </div>

            <idash:Footer runat="server" />
        </div>
    </form>

    <script type="text/javascript">
        document.addEventListener('DOMContentLoaded', () => {
            initColumnChooser();
        });

        function initColumnChooser() {
            const list = document.getElementById('colChooserList');
            const ths = document.querySelectorAll('#historyTable th > .sort-header');
            
            ths.forEach((th, index) => {
                let name = th.innerText.replace(' â&ndash;²â&ndash;¼', '').replace(' \u25B2\u25BC', '').trim();
                
                const label = document.createElement('label');
                const cb = document.createElement('input');
                cb.type = 'checkbox';
                cb.checked = true;
                cb.onchange = (e) => toggleColumn(index, e.target.checked);
                
                label.appendChild(cb);
                label.appendChild(document.createTextNode(' ' + name));
                list.appendChild(label);
            });
            
            document.addEventListener('click', (e) => {
                const chooser = document.getElementById('colChooser');
                if (chooser && chooser.style.display === 'block' && !e.target.closest('#colChooser') && !e.target.closest('#btnColumns')) {
                    chooser.style.display = 'none';
                }
            });
        }

        function toggleColumnChooser(e) {
            const chooser = document.getElementById('colChooser');
            if (chooser.style.display === 'block') {
                chooser.style.display = 'none';
            } else {
                chooser.style.display = 'block';
                const rect = e.target.getBoundingClientRect();
                chooser.style.top = (rect.bottom + window.scrollY + 5) + 'px';
                chooser.style.left = (rect.left + window.scrollX) + 'px';
            }
        }

        let hiddenCols = new Set();
        function toggleColumn(colIndex, show) {
            if (show) hiddenCols.delete(colIndex);
            else hiddenCols.add(colIndex);
            
            let styleEl = document.getElementById('colVisibilityStyle');
            if (!styleEl) {
                styleEl = document.createElement('style');
                styleEl.id = 'colVisibilityStyle';
                document.head.appendChild(styleEl);
            }
            
            let css = '';
            hiddenCols.forEach(idx => {
                let n = idx + 1; // nth-child is 1-indexed
                css += `#historyTable th:nth-child(${n}), #historyTable td:nth-child(${n}) { display: none !important; }\n`;
            });
            styleEl.textContent = css;
        }

        async function doSearch() {
            const q = document.getElementById('TxtSearch').value.trim();
            const statusDiv = document.getElementById('statusDiv');
            const gridContainer = document.getElementById('gridContainer');
            const tbody = document.getElementById('historyBody');
            const countLabel = document.getElementById('LitCount');

            if (!q) {
                statusDiv.className = 'status-msg err';
                statusDiv.innerText = 'Please enter an asset, serial, or EIL to search.';
                return;
            }

            statusDiv.className = 'status-msg';
            statusDiv.innerText = 'Searching history...';
            gridContainer.style.display = 'none';
            tbody.innerHTML = '';
            countLabel.innerText = '0';

            try {
                const siteEl = document.getElementById('DdlCompany');
                const site = siteEl ? siteEl.value : "0";
                
                const fromEl = document.getElementById('TxtFrom');
                const fromDate = fromEl ? fromEl.value : "";
                
                const toEl = document.getElementById('TxtTo');
                const toDate = toEl ? toEl.value : "";

                const response = await fetch('va_previous_location.aspx?api=search&q=' + encodeURIComponent(q) + '&site=' + encodeURIComponent(site) + '&from=' + encodeURIComponent(fromDate) + '&to=' + encodeURIComponent(toDate));
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const result = await response.json();

                if (result.success) {
                    countLabel.innerText = result.count;
                    if (result.count === 0) {
                        statusDiv.className = 'status-msg';
                        statusDiv.innerText = 'No history records found for: ' + q;
                    } else {
                        statusDiv.innerText = '';
                        gridContainer.style.display = 'block';

                        let html = '';
                        for (let i = 0; i < result.data.length; i++) {
                            const row = result.data[i];
                            html += `<tr>
                                <td>${escapeHtml(row.Asset)}</td>
                                <td>${escapeHtml(row.Description)}</td>
                                <td>${escapeHtml(row.EIL)}</td>
                                <td>${escapeHtml(row.Serial)}</td>
                                <td style="color:var(--accent); font-weight:600;">${escapeHtml(row.Location)}</td>
                                <td>${escapeHtml(row.Date)}</td>
                                <td>${escapeHtml(row.PreviousLocation)}</td>
                                <td>${escapeHtml(row.LastObservedLocation)}</td>
                                <td>${escapeHtml(row.CurrentLocation)}</td>
                            </tr>`;
                        }
                        tbody.innerHTML = html;
                        filterTable(); // Run filters immediately in case they were left filled
                    }
                } else {
                    statusDiv.className = 'status-msg err';
                    statusDiv.innerText = 'API Error: ' + result.error;
                }
            } catch (error) {
                statusDiv.className = 'status-msg err';
                statusDiv.innerText = 'Fetch error: ' + error.message;
            }
        }

        function clearSearch() {
            document.getElementById('TxtSearch').value = '';
            if (document.getElementById('TxtFrom')) document.getElementById('TxtFrom').value = '';
            if (document.getElementById('TxtTo')) document.getElementById('TxtTo').value = '';
            document.getElementById('statusDiv').innerText = '';
            document.getElementById('historyBody').innerHTML = '';
            document.getElementById('gridContainer').style.display = 'none';
            document.getElementById('LitCount').innerText = '0';
            const filters = document.querySelectorAll('.filter');
            for(let i=0; i<filters.length; i++) filters[i].value = '';
        }

        function filterTable() {
            const inputs = document.querySelectorAll('.filter');
            const tbody = document.getElementById('historyBody');
            const rows = tbody.getElementsByTagName('tr');
            let visibleCount = 0;
            
            for (let i = 0; i < rows.length; i++) {
                let show = true;
                const cells = rows[i].getElementsByTagName('td');
                for (let j = 0; j < inputs.length; j++) {
                    const filterVal = inputs[j].value.toLowerCase();
                    if (filterVal && cells[j]) {
                        const cellText = cells[j].innerText.toLowerCase();
                        if (cellText.indexOf(filterVal) === -1) {
                            show = false;
                            break;
                        }
                    }
                }
                rows[i].style.display = show ? '' : 'none';
                if (show) visibleCount++;
            }
            document.getElementById('LitCount').innerText = visibleCount;
        }

        let sortDir = {};
        function sortTable(colIndex) {
            const tbody = document.getElementById('historyBody');
            if(!tbody.rows || tbody.rows.length === 0) return;
            const rows = Array.from(tbody.rows);
            
            let dir = sortDir[colIndex] === 'asc' ? 'desc' : 'asc';
            sortDir[colIndex] = dir;
            
            rows.sort((a, b) => {
                let textA = a.cells[colIndex].innerText.trim();
                let textB = b.cells[colIndex].innerText.trim();
                
                let numA = parseFloat(textA);
                let numB = parseFloat(textB);
                
                if (!isNaN(numA) && !isNaN(numB) && textA.length > 0 && textB.length > 0) {
                    return dir === 'asc' ? numA - numB : numB - numA;
                }
                
                return dir === 'asc' 
                    ? textA.localeCompare(textB) 
                    : textB.localeCompare(textA);
            });
            
            tbody.innerHTML = '';
            rows.forEach(r => tbody.appendChild(r));
        }

        function escapeHtml(unsafe) {
            if (!unsafe) return '';
            return unsafe
                 .replace(/&/g, "&amp;")
                 .replace(/</g, "&lt;")
                 .replace(/>/g, "&gt;")
                 .replace(/"/g, "&quot;")
                 .replace(/'/g, "&#039;");
        }
    </script>
</body>
</html>

