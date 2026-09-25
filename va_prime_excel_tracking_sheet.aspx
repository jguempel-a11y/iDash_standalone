<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_prime_excel_tracking_sheet.aspx.cs" Inherits="va_prime_excel_tracking_sheet" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Excel Tracking Compare &mdash; iDash</title>
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
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--bg); color: var(--text);
            font-family: 'Segoe UI', Tahoma, sans-serif; font-size: 14px;
            min-height: 100vh;
        }

        /* ── HEADER BAR ── */
        .page-header {
            background: var(--card);
            border-bottom: 1px solid var(--line);
            padding: 12px 28px;
            display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0; z-index: 100;
        }
        .page-header h1 { margin: 0; font-size: 20px; font-weight: 700; color: var(--accent); }
        .header-right { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }

        .dash { max-width: 1440px; margin: 0 auto; padding: 20px 24px; }

        /* ── GLASS CARD ── */
        .glass {
            background: var(--card); border: 1px solid var(--line);
            border-radius: 12px; padding: 20px 24px; margin-bottom: 18px;
        }
        .panel-title {
            font-size: 14px; font-weight: 600; color: var(--muted);
            text-transform: uppercase; letter-spacing: .7px;
            border-bottom: 1px solid var(--line);
            padding-bottom: 10px; margin-bottom: 14px;
        }

        /* ── CONTROLS ── */
        .ctrl-bar { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; margin-bottom: 14px; }
        .ctrl-label { font-size: 13px; color: var(--muted); font-weight: 600; }
        .ctrl-select, .ctrl-input {
            background: var(--card); color: var(--text);
            border: 1px solid var(--line); padding: 7px 12px;
            border-radius: 6px; font-size: 13px; outline: none;
        }
        .btn-action {
            background: var(--accent); color: #fff; border: none;
            padding: 8px 18px; border-radius: 6px; cursor: pointer;
            font-size: 13px; font-weight: 600; transition: opacity .2s;
        }
        .btn-action:hover { opacity: 0.9; }

        /* ── TABLES ── */
        .tbl-wrap { overflow-x: auto; margin-top: 15px; }
        .loc-tbl { width: 100%; border-collapse: collapse; font-size: 13px; }
        .loc-tbl th {
            background: var(--chip); color: var(--muted);
            font-size: 11px; text-transform: uppercase; letter-spacing: .5px;
            padding: 10px 14px; text-align: left; border-bottom: 1px solid var(--line);
        }
        .loc-tbl td { padding: 9px 14px; border-bottom: 1px solid var(--line); }
        .loc-tbl tbody tr:hover td { background: var(--table-row-hover); }

        div.dt-container { color: var(--text) !important; }
        .dt-info, .dt-length label, .dt-search label { color: var(--muted) !important; font-size: 12px !important; }
        .dt-length select { background: var(--chip); color: var(--text); border: 1px solid var(--line); border-radius: 4px; padding: 4px; }
        .dt-search input { background: var(--chip) !important; color: var(--text) !important; border: 1px solid var(--line) !important; border-radius: 6px !important; padding: 5px 10px !important; outline: none !important; }

        .err-msg { background: color-mix(in srgb, var(--danger), transparent 88%); border: 1px solid color-mix(in srgb, var(--danger), transparent 60%); padding: 10px 14px; border-radius: 8px; color: var(--danger); margin-bottom: 15px; }
        
        .val-good { color: var(--accent-2); font-weight: 700; }
        .val-warn { color: var(--warn); font-weight: 700; }
        .val-bad { color: var(--danger); font-weight: 700; }
        
        input[type="file"]::file-selector-button {
            border: 1px solid var(--line); padding: 5px 10px; border-radius: 4px;
            background: var(--chip); color: var(--text); cursor: pointer; font-weight: 600;
        }
    </style>
</head>
<body>
<form id="form1" runat="server" enctype="multipart/form-data">
    
<div class="page-header">
    <h1>&#128202; Excel Tracking Comparison</h1>
    <div class="header-right">
        <a href="va_asset_master.aspx" class="btn-action" style="text-decoration:none; background:var(--chip); color:var(--text); border:1px solid var(--line);">&#8592; Asset Master</a>
        <a href="index.aspx" class="btn-action" style="text-decoration:none; background:var(--chip); color:var(--text); border:1px solid var(--line);">&#8962; Hub</a>
    </div>
</div>

<div class="dash">
    <div class="glass">
        <div class="panel-title">Upload Excel Sheet</div>
        <div class="ctrl-bar">
            <span class="ctrl-label">Site (Filter Database)</span>
            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select" />
            
            <span class="ctrl-label" style="margin-left:15px;">Excel File (.xlsx)</span>
            <asp:FileUpload ID="FileUploadExcel" runat="server" accept=".xlsx" CssClass="ctrl-input" />
            
            <asp:Button ID="BtnUpload" runat="server" Text="Upload & Compare" CssClass="btn-action" OnClick="BtnUpload_Click" style="margin-left: 10px;" />
        </div>
        <div class="ctrl-bar" style="margin-top:10px;">
            <span class="ctrl-label" style="white-space:nowrap;">— or enter server path —</span>
            <asp:TextBox ID="TxtServerPath" runat="server" CssClass="ctrl-input" placeholder="C:\Users\john\OneDrive - ID Integration Inc\Documents\Walk Through Master List.xlsx" style="width:550px;" />
        </div>
        <p style="font-size:12px; color:var(--muted); margin-top:10px;">
            The file must contain a worksheet named exactly <strong>Master List</strong> and have columns titled <strong>Name</strong> and <strong>Location</strong> in the first row.
        </p>
    </div>

    <asp:Literal ID="LitMsg" runat="server" />

    <asp:Panel ID="PanelResults" runat="server" Visible="false" CssClass="glass">
        <div class="panel-title" style="display:flex; justify-content:space-between; align-items:center;">
            <span>Comparison Results by Location</span>
            <button type="button" onclick="exportToExcel()" class="btn-action" style="font-size:12px; padding:6px 14px;">
                &#128196; Export for Prime
            </button>
        </div>
        <div class="tbl-wrap">
            <table id="resultsTable" class="loc-tbl display">
                <thead>
                    <tr>
                        <th>Location</th>
                        <th>Assets (Excel)</th>
                        <th>Assets (DB)</th>
                        <th>Matched</th>
                        <th>Missing in DB</th>
                        <th>Missing in Excel</th>
                        <th>Untagged &#x26A0;</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- Populated by DataTables -->
                </tbody>
            </table>
        </div>
    </asp:Panel>
</div>

<idash:Footer runat="server" />
</form>

<script>
    function initGrid() {
        if (!window.CompareData || !window.CompareData.length) return;

        if ($.fn.DataTable.isDataTable('#resultsTable')) {
            $('#resultsTable').DataTable().destroy();
        }

        $('#resultsTable').DataTable({
            data: window.CompareData,
            columns: [
                { 
                    data: 'Location',
                    render: function(data) {
                        return '<strong style="color:var(--text)">' + data + '</strong>';
                    }
                },
                { data: 'ExcelCount' },
                { data: 'DbCount' },
                { 
                    data: 'MatchingCount',
                    render: function(data) {
                        return '<span class="val-good">' + data + '</span>';
                    }
                },
                { 
                    data: 'ExcelOnly',
                    render: function(data) {
                        return data > 0 ? '<span class="val-bad">' + data + '</span>' : data;
                    }
                },
                { 
                    data: 'DbOnly',
                    render: function(data) {
                        return data > 0 ? '<span class="val-warn">' + data + '</span>' : data;
                    }
                },
                {
                    data: 'UntaggedCount',
                    render: function(data, type, row) {
                        if (type === 'sort' || type === 'type') return data;
                        if (data === 0) return '<span class="val-good">&#10003; All Tagged</span>';
                        return '<span class="val-bad" style="font-size:13px;font-weight:700;">&#9888; ' + data + ' not tagged</span>';
                    }
                }
            ],
            pageLength: 50,
            lengthMenu: [25, 50, 100, -1],
            order: [[6, 'desc']],
            language: {
                emptyTable: "No data available."
            }
        });
    }

    function exportToExcel() {
        if (!window.CompareData || !window.CompareData.length) {
            alert('No comparison data to export. Run a comparison first.');
            return;
        }

        // Sort by Untagged descending, then by Location ascending
        var sorted = window.CompareData.slice().sort(function(a, b) {
            if (b.UntaggedCount !== a.UntaggedCount) return b.UntaggedCount - a.UntaggedCount;
            return a.Location.localeCompare(b.Location);
        });

        var headers = ['Location', 'Assets (Excel)', 'Assets (DB)', 'Matched', 'Missing in DB', 'Missing in Excel', 'Untagged', 'Tagging Status'];
        var rows = [headers.join(',')];

        sorted.forEach(function(r) {
            var status = r.UntaggedCount === 0 ? 'All Tagged' :
                         r.UntaggedCount === r.ExcelCount ? 'None Tagged' : 'Partial';
            var row = [
                '"' + r.Location + '"',
                r.ExcelCount,
                r.DbCount,
                r.MatchingCount,
                r.ExcelOnly,
                r.DbOnly,
                r.UntaggedCount,
                '"' + status + '"'
            ];
            rows.push(row.join(','));
        });

        var csv = rows.join('\r\n');
        var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        var today = new Date();
        var dateStr = (today.getMonth()+1) + '-' + today.getDate() + '-' + today.getFullYear();
        a.href = url;
        a.download = 'Martinsburg_Tagging_Priority_' + dateStr + '.csv';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }
</script>

<asp:Literal ID="LitResultJson" runat="server" />
</body>
</html>



