<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_not_in_use.aspx.cs" Inherits="va_not_in_use" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Assets Not In Use &mdash; iDash</title>
            <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet" />
    <script src="https://cdn.datatables.net/2.0.8/js/dataTables.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background: var(--bg-base);
            color: var(--text-main);
            font-family: 'Inter', 'Segoe UI', sans-serif;
            font-size: 14px;
            background-image:
                radial-gradient(circle at top left,  color-mix(in srgb, var(--accent), transparent 95%), transparent 40%),
                radial-gradient(circle at bottom right, rgba(139,92,246,0.06), transparent 40%);
            min-height: 100vh;
        }

        .dash { max-width: 1440px; margin: 0 auto; padding: 30px 24px; }

        /* -- HEADER -- */
        .page-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 28px;
            border-bottom: 1px solid var(--panel-border);
            padding-bottom: 20px;
            flex-wrap: wrap; gap: 16px;
        }
        .page-header h1 {
            font-size: 26px; font-weight: 700;
            background: linear-gradient(90deg, #F59E0B, #EF4444);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .header-right { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }

        /* -- GLASS -- */
        .glass {
            background: var(--panel-bg);
            backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
            border: 1px solid var(--panel-border);
            border-radius: 16px; padding: 24px;
            box-shadow:var(--shadow);
            margin-bottom: 22px;
        }
        .panel-title {
            font-size: 12px; font-weight: 600; color: var(--text-accent);
            text-transform: uppercase; letter-spacing: 0.8px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            padding-bottom: 12px; margin-bottom: 18px;
            display: flex; justify-content: space-between; align-items: center;
        }

        /* -- KPI CARDS -- */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px; margin-bottom: 22px;
        }
        @media(max-width:900px)  { .kpi-row { grid-template-columns: repeat(2,1fr); } }
        @media(max-width:480px)  { .kpi-row { grid-template-columns: 1fr 1fr; } }

        .kpi-card {
            background: var(--panel-bg);
            border: 1px solid var(--panel-border);
            border-radius: 14px; padding: 24px 16px;
            text-align: center;
            box-shadow: 0 4px 20px rgba(0,0,0,0.2);
            transition: border-color .2s, box-shadow .2s;
        }
        .kpi-card:hover { box-shadow: 0 6px 28px color-mix(in srgb, var(--accent), transparent 85%); }
        .kpi-value { font-size: 38px; font-weight: 700; line-height: 1; margin-bottom: 6px; }
        .kpi-pct   { font-size: 13px; font-weight: 600; margin-bottom: 4px; }
        .kpi-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .7px; color: var(--text-accent); }

        /* -- STATUS BAR -- */
        .status-bar-wrap { margin-bottom: 22px; }
        .sbar { display: flex; height: 12px; border-radius: 6px; overflow: hidden; margin: 10px 0 14px; background: rgba(255,255,255,0.05); }
        .sbar-seg { height: 100%; transition: width .6s ease; }
        .bar-legend { display: flex; flex-wrap: wrap; gap: 10px; }
        .bar-chip {
            display: inline-flex; align-items: center; gap: 6px; font-size: 12px;
            background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.07);
            padding: 4px 12px; border-radius: 20px;
        }
        .chip-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

        /* -- BUTTONS -- */
        .btn-success {
            background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--success);
            border: 1px solid var(--success);
            padding: 7px 16px; border-radius: 8px; font-size: 13px; font-weight: 600;
            cursor: pointer; transition: all .2s;
        }
        .btn-success:hover { background: color-mix(in srgb, var(--accent-2), transparent 85%); }

        .btn-ghost {
            background: rgba(255,255,255,0.04); color: var(--text-accent);
            border: 1px solid var(--line);
            padding: 7px 14px; border-radius: 8px; font-size: 13px; font-weight: 500;
            cursor: pointer; text-decoration: none; transition: all .2s;
        }
        .btn-ghost:hover { color: var(--text-main); border-color: var(--panel-border); }

        .ctrl-select {
            background: rgba(0,0,0,0.35); color: var(--text-main);
            border: 1px solid var(--panel-border);
            padding: 7px 12px; border-radius: 8px; font-size: 13px; outline: none;
        }
        .ctrl-select option { background: #0d1829; }

        /* -- DATATABLES DARK SKIN -- */
        #GridData { width: 100%; border-collapse: collapse; font-size: 13px; }
        #GridData th {
            background: rgba(255,255,255,0.04); color: var(--text-accent);
            font-size: 11px; text-transform: uppercase; letter-spacing: .6px;
            padding: 10px 14px; text-align: left;
            border-bottom: 1px solid var(--line);
        }
        #GridData td { padding: 10px 14px; border-bottom: 1px solid rgba(255,255,255,0.03); color: var(--text-main); }
        #GridData tbody tr:hover td { background: rgba(255,255,255,0.025); }

        div.dt-container { color: var(--text-main) !important; }
        .dt-info, .dt-length label, .dt-search label { color: var(--text-accent) !important; font-size: 12px !important; }
        .dt-paging-button { color: var(--text-main) !important; }
        .dt-paging-button.current { background: var(--line) !important; border-color: #2b3858 !important; color:#fff !important; }
        .dt-length select { background:var(--chip); color:#fff; border:1px solid var(--line); border-radius: 4px; padding: 4px; }
        .dt-search input { background: rgba(0,0,0,0.35) !important; color: var(--text-main) !important; border: 1px solid var(--panel-border) !important; border-radius: 6px !important; padding: 5px 10px !important; outline: none !important; }

        .col-search {
            width: 100%; background: rgba(0,0,0,0.35); color: #fff;
            border: 1px solid var(--line); padding: 5px 8px;
            border-radius: 4px; font-size: 11px; margin-top: 4px;
        }
        .col-search::placeholder { color: rgba(255,255,255,0.25); }

        /* status pills */
        .sp {
            display: inline-block; padding: 3px 10px; border-radius: 20px;
            font-size: 11px; font-weight: 700; text-transform: uppercase; white-space: nowrap;
        }

        .table-wrap { overflow-x: auto; }

        .empty-state { text-align: center; padding: 60px 20px; color: var(--text-accent); font-size: 15px; }
    </style>
</head>
<body>
<form id="form1" runat="server">

<!-- Hidden server values -->
<asp:HiddenField ID="HdnTotal"           runat="server" Value="0" />
<asp:HiddenField ID="HdnNoStatus"        runat="server" Value="0" />
<asp:HiddenField ID="HdnUniqueStatus"    runat="server" Value="0" />
<asp:HiddenField ID="HdnStatusBreakdown" runat="server" Value="" />

<div class="dash">

    <!-- -- HEADER -- -->
    <div class="page-header">
        <h1>Tagged Assets &mdash; Not In Use</h1>
        <div class="header-right">
            <span style="font-size:13px;color:var(--text-accent);">Site:</span>
            <asp:DropDownList ID="DdlCompany" runat="server" AutoPostBack="true"
                OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" CssClass="ctrl-select" />
            <asp:Button ID="BtnExport" runat="server" Text="Export CSV"
                OnClick="BtnExport_Click" CssClass="btn-success" />
            <a href="va_data_quality.aspx" class="btn-ghost">Data Quality</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <!-- -- KPI CARDS -- -->
    <div class="kpi-row">
        <div class="kpi-card">
            <div class="kpi-value" id="kv-total" style="color:var(--warning);">0</div>
            <div class="kpi-label">Tagged Not In Use</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-statuses" style="color:var(--accent);">0</div>
            <div class="kpi-label">Distinct Statuses</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-nostatus" style="color:var(--danger);">0</div>
            <div class="kpi-pct"   id="kp-nostatus" style="color:var(--danger);">0%</div>
            <div class="kpi-label">No Status Set</div>
        </div>
        <div class="kpi-card" id="kv-top-card">
            <div class="kpi-value" id="kv-top" style="color:var(--highlight);">0</div>
            <div class="kpi-pct"   id="kp-top" style="color:var(--highlight);">0%</div>
            <div class="kpi-label" id="kl-top">Top Status</div>
        </div>
    </div>

    <!-- -- STATUS DISTRIBUTION -- -->
    <div class="glass">
        <div class="panel-title"><span>Status Distribution</span></div>
        <div class="sbar" id="statusBar"></div>
        <div class="bar-legend" id="barLegend"></div>
    </div>

    <!-- -- GRID -- -->
    <div class="glass">
        <div class="panel-title">
            <span>Asset Detail &mdash; RFID Tagged, Status &ne; In Use</span>
        </div>

        <p style="font-size:12px;color:var(--text-accent);margin-bottom:16px;">
            All assets with an RFID tag (text18=1) whose current status (listvalue1) is not "In Use".
            Use the column filters below to drill into specific statuses or locations.
        </p>

        <div class="table-wrap">
            <asp:GridView ID="GridData" runat="server" AutoGenerateColumns="false"
                CssClass="display" ClientIDMode="Static"
                GridLines="None" UseAccessibleHeader="true">
                <Columns>
                    <asp:BoundField DataField="AssetTag"       HeaderText="Asset Tag" />
                    <asp:BoundField DataField="Description"    HeaderText="Description" />
                    <asp:BoundField DataField="EIL_CMR"        HeaderText="EIL / CMR" />
                    <asp:BoundField DataField="Location"       HeaderText="Location" />
                    <asp:BoundField DataField="Status"         HeaderText="Status" />
                    <asp:BoundField DataField="Site"           HeaderText="Site" />
                    <asp:BoundField DataField="LastInventoried" HeaderText="Last Inventoried" />
                </Columns>
                <EmptyDataTemplate>
                    <div class="empty-state">
                        All tagged assets at this site are currently marked "In Use" &mdash; no issues found.
                    </div>
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>

</div><!-- /dash -->
<aw:Footer runat="server" />
</form>

<script type="text/javascript">
    // -- Animated counter ------------------------------
    function animVal(el, target, dur) {
        if (!el || isNaN(target)) return;
        var t0 = null, fmt = new Intl.NumberFormat();
        (function step(t) {
            if (!t0) t0 = t;
            var p = Math.min((t - t0) / dur, 1);
            el.textContent = fmt.format(Math.round(p * target));
            if (p < 1) requestAnimationFrame(step);
        })(0);
        requestAnimationFrame(function(t) {});
    }

    function pctStr(v, t) { return t > 0 ? (v / t * 100).toFixed(1) + '%' : '0%'; }
    function fmtN(n) { return new Intl.NumberFormat().format(n); }

    // Colour palette for status bars and pills
    var PALETTE = ['#2EA8FF','#10B981','#8B5CF6','#F59E0B','#EF4444','#F97316','#06B6D4','#EC4899','#84CC16','#14B8A6'];

    function initPage() {
        var total    = parseInt($('#<%= HdnTotal.ClientID %>').val())           || 0;
        var noSts    = parseInt($('#<%= HdnNoStatus.ClientID %>').val())        || 0;
        var uniq     = parseInt($('#<%= HdnUniqueStatus.ClientID %>').val())    || 0;
        var brkRaw   = $('#<%= HdnStatusBreakdown.ClientID %>').val() || '';

        // Parse pipe~tilde encoded breakdown: "Status~Count|Status~Count"
        var items = [];
        if (brkRaw) {
            brkRaw.split('|').forEach(function(chunk) {
                var parts = chunk.split('~');
                if (parts.length === 2) {
                    items.push({ label: parts[0], cnt: parseInt(parts[1]) || 0 });
                }
            });
        }

        // Animate KPIs
        (function animCountUp(el, n) {
            if (!el) return;
            var t0 = null, fmt = new Intl.NumberFormat();
            function step(t) {
                if (!t0) t0 = t;
                var p = Math.min((t - t0) / 900, 1);
                el.textContent = fmt.format(Math.round(p * n));
                if (p < 1) requestAnimationFrame(step);
            }
            requestAnimationFrame(step);
        });

        var anim = function(id, n) {
            var el = document.getElementById(id); if (!el) return;
            var t0 = null, fmt = new Intl.NumberFormat();
            function step(t) { if (!t0) t0=t; var p=Math.min((t-t0)/900,1); el.textContent=fmt.format(Math.round(p*n)); if(p<1) requestAnimationFrame(step); }
            requestAnimationFrame(step);
        };

        anim('kv-total',    total);
        anim('kv-statuses', uniq);
        anim('kv-nostatus', noSts);

        var nostPctEl = document.getElementById('kp-nostatus');
        if (nostPctEl) nostPctEl.textContent = pctStr(noSts, total);

        // Top status KPI
        if (items.length > 0) {
            var top = items[0];
            anim('kv-top', top.cnt);
            var topPct = document.getElementById('kp-top');
            if (topPct) topPct.textContent = pctStr(top.cnt, total);
            var topLbl = document.getElementById('kl-top');
            if (topLbl) topLbl.textContent = top.label;
        }

        // Build status bar + legend
        var bar    = document.getElementById('statusBar');
        var legend = document.getElementById('barLegend');
        if (bar && legend && total > 0) {
            bar.innerHTML = ''; legend.innerHTML = '';
            items.forEach(function(item, i) {
                var color = PALETTE[i % PALETTE.length];
                var w = (item.cnt / total * 100).toFixed(2);
                // bar segment
                var seg = document.createElement('div');
                seg.className = 'sbar-seg';
                seg.style.cssText = 'width:' + w + '%;background:' + color + ';';
                seg.title = item.label + ': ' + fmtN(item.cnt) + ' (' + pctStr(item.cnt, total) + ')';
                bar.appendChild(seg);
                // legend chip
                var chip = document.createElement('div');
                chip.className = 'bar-chip';
                chip.innerHTML = '<span class="chip-dot" style="background:' + color + '"></span>'
                    + '<span>' + item.label + '</span>'
                    + '<strong style="margin-left:4px;">' + fmtN(item.cnt) + '</strong>'
                    + '<span style="opacity:.55;margin-left:4px;font-size:11px;">(' + pctStr(item.cnt, total) + ')</span>';
                legend.appendChild(chip);

                // colour the matching cells in the grid
                colorStatusCells(item.label, color);
            });
        }
    }

    // Apply colour pills to the Status column (col index 4)
    function colorStatusCells(label, color) {
        $('#GridData tbody tr').each(function() {
            var cell = $(this).find('td').eq(4);
            if (cell.text().trim() === label) {
                cell.html('<span class="sp" style="background:' + hexAlpha(color, 0.15) + ';color:' + color + ';border:1px solid ' + hexAlpha(color, 0.35) + ';">' + label + '</span>');
            }
        });
    }

    function hexAlpha(hex, a) {
        // Convert #RRGGBB to rgba()
        var r = parseInt(hex.slice(1,3),16), g = parseInt(hex.slice(3,5),16), b = parseInt(hex.slice(5,7),16);
        return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')';
    }

    $(document).ready(function() {
        initPage();

        var table = $('#GridData');
        if (table.length && table.find('tbody tr').length > 0 && table.find('tbody tr td').length > 1) {

            // Add per-column search row
            table.find('thead tr')
                .clone(true).appendTo(table.find('thead'))
                .addClass('col-search-row');

            table.find('thead tr.col-search-row th').each(function() {
                $(this).removeClass('sorting').off();
                var inp = $('<input type="text" class="col-search" placeholder="Search..." />');
                $(this).html('').append(inp);
            });

            var dt = table.DataTable({
                dom: 'lrtip',
                orderCellsTop: true,
                pageLength: 25,
                stateSave: false,
                initComplete: function() {}
            });

            // Wire per-column search
            table.find('thead tr.col-search-row th').each(function(i) {
                $('input', this).on('keyup change clear', function() {
                    if (dt.column(i).search() !== this.value) {
                        dt.column(i).search(this.value).draw();
                    }
                });
            });
        }
    });
</script>
</body>
</html>

