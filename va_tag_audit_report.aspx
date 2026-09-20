<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_tag_audit_report.aspx.cs" Inherits="va_tag_audit_report" %>

    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">

    <head runat="server">
        <title>VA Tag Audit Report &mdash; iDash</title>
        <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
        <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />

        <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
        <link href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet" />
        <script src="https://cdn.datatables.net/2.0.8/js/dataTables.js"></script>

        <style>
            body {
                background: var(--bg);
                color: var(--text);
                font-family: Segoe UI, Arial;
            }

            .panel {
                background: var(--card);
                border: 1px solid var(--line);
                border-radius: 12px;
                padding: 16px;
                margin-bottom: 18px;
            }

            .bucket-row {
                display: flex;
                gap: 10px;
                flex-wrap: wrap;
                align-items: center;
            }

            .bucket-card {
                border: 2px solid var(--accent);
                padding: 10px 14px;
                border-radius: 10px;
                cursor: pointer;
                color: var(--accent);
                text-align: center;
                background: color-mix(in srgb, var(--accent) 6%, transparent);
                user-select: none;
            }

            .bucket-card:hover {
                background: color-mix(in srgb, var(--accent) 12%, transparent);
            }

            .filter {
                margin-right: 10px;
            }

            .filter label {
                display: block;
                font-size: 12px;
                opacity: 0.9;
                margin-bottom: 6px;
            }

            .filter input[type="date"],
            .filter select {
                background: var(--chip);
                border: 1px solid var(--line);
                color: var(--text);
                padding: 8px 10px;
                border-radius: 10px;
                outline: none;
            }

            .btn {
                border: 2px solid #2ea8ff;
                background: transparent;
                color: #2ea8ff;
                padding: 10px 14px;
                border-radius: 10px;
                cursor: pointer;
                font-weight: 600;
            }

            .btn:hover {
                background: color-mix(in srgb, var(--accent), transparent 85%);
            }

            .muted {
                color: #9fb0d8;
                font-size: 12px;
            }

            .err {
                color: #ff7b7b;
                margin: 8px 0;
            }

            .gridWrap {
                overflow: auto;
                border: 1px solid var(--line);
                border-radius: 12px;
            }

            .grid {
                width: 100%;
                border-collapse: collapse;
                margin-top: 10px;
            }

            .grid th {
                background: var(--chip);
                padding: 6px;
                position: sticky;
                top: 0;
                z-index: 2;
                text-align: left;
                white-space: nowrap;
                color: var(--accent);
                border-bottom: 2px solid var(--line);
            }

            .grid td {
                border-bottom: 1px solid var(--line);
                padding: 6px;
                white-space: nowrap;
            }

            /* DATATABLES OVERRIDES */
            .dataTables_wrapper {
                margin-top: 10px;
                font-size: 13px;
                color: var(--text);
            }
            .dataTables_wrapper .dataTables_length,
            .dataTables_wrapper .dataTables_info,
            .dataTables_wrapper .dataTables_processing,
            .dataTables_wrapper .dataTables_paginate {
                color: var(--muted) !important;
                margin-bottom: 10px;
            }
            .dataTables_wrapper .dataTables_length select {
                background: var(--chip);
                border: 1px solid var(--line);
                color: var(--text);
                padding: 4px;
                border-radius: 4px;
            }
            table.dataTable { border-collapse: collapse !important; }
            table.dataTable tbody tr { background-color: transparent !important; }
            table.dataTable.display tbody tr.odd { background-color: transparent !important; }
            table.dataTable.display tbody tr.even { background-color: transparent !important; }
            table.dataTable tbody tr:hover { background-color: #1c263a !important; }
        </style>
    </head>

    <body>
        <form id="form1" runat="server">

            <div class="panel">
                <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                    <div>
                        <div style="font-size:20px; font-weight:700; margin-bottom:6px;">VA Tag Audit Report</div>
                        <div class="muted">Date range filters by <b>lastinventoried</b>. Includes raw + parsed dates for text10/text17.</div>
                    </div>
                    <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                </div>

                <asp:Literal ID="LitErr" runat="server" />

                <div class="bucket-row" style="margin-top:14px;">
                    <div class="filter">
                        <label for="TxtFrom">From</label>
                        <asp:TextBox ID="TxtFrom" runat="server" TextMode="Date" />
                    </div>

                    <div class="filter">
                        <label for="TxtTo">To</label>
                        <asp:TextBox ID="TxtTo" runat="server" TextMode="Date" />
                    </div>

                    <div class="filter">
                        <label for="DdlCompany">Company</label>
                        <asp:DropDownList ID="DdlCompany" runat="server" />
                    </div>

                    <asp:Button ID="BtnRun" runat="server" CssClass="btn" Text="Run Report" OnClick="BtnRun_Click" />
                    <asp:Button ID="BtnExport" runat="server" CssClass="btn" Text="Export CSV"
                        OnClick="BtnExport_Click" />

                    <div style="flex:1;"></div>

                    <div class="bucket-card">
                        Rows<br />
                        <asp:Label ID="LblCount" runat="server" Text="0" />
                    </div>

                    <div class="bucket-card">
                        Range<br />
                        <asp:Label ID="LblRange" runat="server" Text="-" />
                    </div>
                </div>

                <div class="muted" style="margin-top:10px;">
                    Tip: Leave dates blank to default to the current month.
                </div>
            </div>

            <div class="panel">
                <div style="display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:10px;">
                    <div></div>
                    <button type="button" class="btn" style="background:var(--chip); border:1px solid #2ea8ff; color:var(--text); font-size:12px; padding:6px 12px; cursor:pointer;" onclick="$('#ColToggleContainer').toggle()">&#9776; Columns</button>
                </div>
                <div id="ColToggleContainer" style="background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:12px; margin-bottom:12px; display:none; flex-wrap:wrap; gap:10px; font-size:13px;"></div>
                <div class="gridWrap">
                    <asp:GridView ID="Grid" runat="server" CssClass="grid display" AutoGenerateColumns="false" GridLines="None" UseAccessibleHeader="true" ClientIDMode="Static">
                        <Columns>
                            <asp:BoundField DataField="NAME" HeaderText="NAME" />
                            <asp:BoundField DataField="DESCRIPTION" HeaderText="DESCRIPTION" />
                            <asp:BoundField DataField="DISPOSAL_STATUS" HeaderText="DISPOSAL STATUS" />
                            <asp:BoundField DataField="LAST_INVENTORIED" HeaderText="LAST INVENTORIED" />

                            <asp:BoundField DataField="MANUFACTURER" HeaderText="MANUFACTURER" />
                            <asp:BoundField DataField="MODEL" HeaderText="MODEL" />
                            <asp:BoundField DataField="SERIAL_NUM" HeaderText="SERIAL #" />
                            <asp:BoundField DataField="EQUIPMENT_CATEGORY" HeaderText="EQUIPMENT CATEGORY" />
                            <asp:BoundField DataField="SERVICE_POINTER" HeaderText="SERVICE POINTER" />
                            <asp:BoundField DataField="LOCATION" HeaderText="LOCATION" />
                            <asp:BoundField DataField="STATION_NUMBER" HeaderText="STATION NUMBER" />
                            <asp:BoundField DataField="CMR_EIL" HeaderText="CMR/EIL" />
                            <asp:BoundField DataField="PURCHASE_ORDER" HeaderText="PURCHASE ORDER #" />

                            <asp:BoundField DataField="PI_DATE_RAW" HeaderText="PHYSICAL INVENTORY DATE (raw)" />
                            <asp:BoundField DataField="PI_DATE_PARSED" HeaderText="PHYSICAL INVENTORY DATE (parsed)" />

                            <asp:BoundField DataField="SP_PREV_LOCATION" HeaderText="SP + PREVIOUS LOCATION" />
                            <asp:BoundField DataField="ENTRY_NUMBER" HeaderText="ENTRY NUMBER" />
                            <asp:BoundField DataField="EMPL_ID" HeaderText="EMPL_ID" />
                            <asp:BoundField DataField="SUBSTATION" HeaderText="SUBSTATION" />
                            <asp:BoundField DataField="LOCATION_TAGGED_FOUND" HeaderText="LOCATION TAGGED (FOUND)" />

                            <asp:BoundField DataField="TAGGED_ON_RAW" HeaderText="TAGGED ON DATE (raw)" />
                            <asp:BoundField DataField="TAGGED_ON_PARSED" HeaderText="TAGGED ON DATE (parsed)" />

                            <asp:BoundField DataField="TAGGED_RAW" HeaderText="TAGGED (raw)" />
                            <asp:BoundField DataField="TAGGED_YN" HeaderText="TAGGED (Yes/No)" />

                            <asp:BoundField DataField="TAG_TYPE" HeaderText="TAG_TYPE" />
                            <asp:BoundField DataField="NOTES" HeaderText="NOTES" />
                        </Columns>
                    </asp:GridView>
                </div>
            </div>

            <script>
                $(document).ready(function() {
                    var table = $('#Grid');
                    if (table.length && table.find('tbody tr').length > 0 && table.find('tbody tr td').length > 1) {
                        
                        // Setup explicit columns for search inputs
                        table.find('thead tr').clone(true).appendTo(table.find('thead')).addClass('search-row');
                        
                        table.find('thead tr.search-row th').each(function() {
                            $(this).removeClass('sorting').unbind();
                            $(this).html('<input type="text" placeholder="Search..." class="dt-col-search" style="width:100%; box-sizing:border-box; background:var(--chip); border:1px solid var(--line); color:#fff; padding:4px; font-weight:normal; margin-top:4px;" />');
                        });

                        var dt = table.DataTable({
                            dom: 'lrtip', // Hide global search
                            stateSave: true,
                            stateLoadParams: function (settings, data) {
                                data.search.search = "";
                                if (data.columns) {
                                    for (var i=0; i<data.columns.length; i++) {
                                        data.columns[i].search.search = "";
                                    }
                                }
                            },
                            orderCellsTop: true,
                            pageLength: 25,
                            ordering: true,
                            initComplete: function() {
                                var container = $('#ColToggleContainer');
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

                        // Wire up column search
                        table.find('thead tr.search-row input').on('keyup change clear', function(e) {
                            if (e.type === 'keyup' && e.keyCode !== 13) return; // Execute precisely on Enter to save client thread cycles
                            var index = $(this).parent().index();
                            var val = this.value;
                            
                            var headerText = $(table).find('thead tr:first th').eq(index).text().trim();
                            
                            if (val) {
                                // If the column is TAG_TYPE, enforce EXACT MATCH
                                if (headerText === 'TAG_TYPE') {
                                    var exactRegex = '^' + $.fn.dataTable.util.escapeRegex(val) + '$';
                                    dt.column(index).search(exactRegex, true, false).draw();
                                } else {
                                    // Otherwise standard partial smart search
                                    dt.column(index).search(val).draw();
                                }
                            } else {
                                // Clear filter
                                dt.column(index).search('').draw();
                            }
                        });

                        // Dynamically update the Row Count label whenever the table filters
                        dt.on('draw.dt', function () {
                            var info = dt.page.info();
                            $('#<%= LblCount.ClientID %>').text(info.recordsDisplay.toLocaleString());
                        });
                    }
                });
            </script>

        </form>
    </body>

    </html>
