<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_tag_type.aspx.cs" Inherits="va_tag_type" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Tag Type Analysis &mdash; iDash</title>
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
            background: var(--bg-base); color: var(--text-main);
            font-family: 'Inter','Segoe UI',sans-serif; font-size:14px;
            background-image:
                radial-gradient(circle at top left,  color-mix(in srgb, var(--accent), transparent 95%), transparent 40%),
                radial-gradient(circle at bottom right, rgba(139,92,246,.06), transparent 40%);
            min-height: 100vh;
        }

        .dash { max-width:1440px; margin:0 auto; padding:30px 24px; }

        /* -- HEADER -- */
        .page-header {
            display:flex; justify-content:space-between; align-items:center;
            margin-bottom:28px; border-bottom:1px solid var(--panel-border);
            padding-bottom:20px; flex-wrap:wrap; gap:16px;
        }
        .page-header h1 {
            font-size:26px; font-weight:700;
            background: linear-gradient(90deg,#8B5CF6,#2EA8FF);
            -webkit-background-clip:text; background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .header-right { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }

        /* -- GLASS -- */
        .glass {
            background:var(--panel-bg);
            backdrop-filter:blur(14px); -webkit-backdrop-filter:blur(14px);
            border:1px solid var(--panel-border);
            border-radius:16px; padding:24px;
            box-shadow:var(--shadow);
            margin-bottom:22px;
        }
        .panel-title {
            font-size:12px; font-weight:600; color:var(--text-accent);
            text-transform:uppercase; letter-spacing:.8px;
            border-bottom:1px solid rgba(255,255,255,.05);
            padding-bottom:12px; margin-bottom:18px;
            display:flex; justify-content:space-between; align-items:center;
        }

        /* -- KPI CARDS -- */
        .kpi-row { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:22px; }
        @media(max-width:900px)  { .kpi-row{ grid-template-columns:repeat(2,1fr); } }
        @media(max-width:480px)  { .kpi-row{ grid-template-columns:1fr 1fr; } }

        .kpi-card {
            background:var(--panel-bg); border:1px solid var(--panel-border);
            border-radius:14px; padding:24px 16px; text-align:center;
            box-shadow:0 4px 20px rgba(0,0,0,.2); transition:box-shadow .2s;
        }
        .kpi-card:hover { box-shadow:0 6px 28px color-mix(in srgb, var(--accent), transparent 85%); }
        .kpi-value { font-size:38px; font-weight:700; line-height:1; margin-bottom:6px; }
        .kpi-sub   { font-size:12px; color:var(--text-accent); margin-bottom:4px; min-height:16px; }
        .kpi-label { font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.7px; color:var(--text-accent); }

        /* -- DISTRIBUTION BAR -- */
        .dist-bar { display:flex; height:12px; border-radius:6px; overflow:hidden; margin:10px 0 14px; background:rgba(255,255,255,.05); }
        .dist-seg { height:100%; }
        .bar-legend { display:flex; flex-wrap:wrap; gap:8px; }
        .bar-chip {
            display:inline-flex; align-items:center; gap:6px; font-size:12px;
            background:rgba(255,255,255,.04); border:1px solid rgba(255,255,255,.07);
            padding:4px 10px; border-radius:20px; cursor:pointer;
        }
        .bar-chip:hover { background:rgba(255,255,255,.09); }
        .chip-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }

        /* -- CONTROLS -- */
        .ctrl-bar { display:flex; align-items:center; gap:12px; flex-wrap:wrap; margin-bottom:18px; }
        .ctrl-label { font-size:13px; color:var(--text-accent); }

        .ctrl-select {
            background:var(--panel-bg); color:var(--text-main);
            border:1px solid var(--panel-border);
            padding:7px 12px; border-radius:8px; font-size:13px; outline:none;
        }
        .ctrl-select option { background:var(--panel-bg); color:var(--text-main); }

        .txt-search {
            background:var(--panel-bg); color:var(--text-main);
            border:1px solid var(--panel-border);
            padding:7px 14px; border-radius:8px; font-size:13px; outline:none; width:260px;
        }
        .txt-search::placeholder { color:rgba(255,255,255,.3); }

        /* -- BUTTONS -- */
        .btn-primary {
            background:color-mix(in srgb, var(--accent), transparent 85%); color:var(--highlight);
            border:1px solid var(--highlight);
            padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600;
            cursor:pointer; transition:all .2s;
        }
        .btn-primary:hover { background:color-mix(in srgb, var(--accent), transparent 85%); }

        .btn-success {
            background:color-mix(in srgb, var(--accent-2), transparent 85%); color:var(--success);
            border:1px solid var(--success);
            padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600;
            cursor:pointer; transition:all .2s;
        }
        .btn-success:hover { background:color-mix(in srgb, var(--accent-2), transparent 85%); }

        .btn-ghost {
            background: transparent; color: var(--accent);
            border: 1px solid var(--line);
            padding: 6px 12px; border-radius: 8px; font-size: 13px; font-weight: 600;
            cursor: pointer; text-decoration: none; transition: background .15s, border-color .15s;
        }
        .btn-ghost:hover { background: color-mix(in srgb, var(--accent), transparent 90%); border-color: var(--accent); }
        .nav-pill-ghost {
            display: inline-flex; align-items: center; gap: 5px;
            background: transparent; color: var(--accent);
            border: 1px solid var(--line);
            padding: 6px 12px; border-radius: 8px; font-size: 13px; font-weight: 600;
            cursor: pointer; text-decoration: none; transition: background .15s, border-color .15s;
        }
        .nav-pill-ghost:hover { background: color-mix(in srgb, var(--accent), transparent 90%); border-color: var(--accent); }

        /* -- DATATABLES DARK SKIN -- */
        .tbl-wrap { overflow-x:auto; }
        .glass table { width:100%; border-collapse:collapse; font-size:13px; }
        .glass table th {
            background:rgba(255,255,255,.04); color:var(--text-accent);
            font-size:11px; text-transform:uppercase; letter-spacing:.6px;
            padding:10px 14px; text-align:left; border-bottom:1px solid var(--line);
        }
        .glass table td { padding:9px 14px; border-bottom:1px solid rgba(255,255,255,.03); }
        .glass table tbody tr:hover td { background:rgba(255,255,255,.025); }

        div.dt-container { color:var(--text-main) !important; }
        .dt-info, .dt-length label, .dt-search label { color:var(--text-accent) !important; font-size:12px !important; }
        .dt-length select { background:var(--panel-bg); color:var(--text-main); border:1px solid var(--line); border-radius:4px; padding:4px; }
        .dt-length select option { background:var(--panel-bg); color:var(--text-main); }
        .dt-search input { background:var(--panel-bg) !important; color:var(--text-main) !important; border:1px solid var(--panel-border) !important; border-radius:6px !important; padding:5px 10px !important; outline:none !important; }

        .col-search {
            width:100%; background:var(--panel-bg); color:var(--text-main);
            border:1px solid var(--line); padding:5px 8px;
            border-radius:4px; font-size:11px; margin-top:4px;
        }
        .col-search::placeholder { color:var(--text-accent); opacity:0.5; }

        /* two-col layout for bottom section */
        .two-col { display:grid; grid-template-columns:1fr 340px; gap:22px; }
        @media(max-width:900px) { .two-col { grid-template-columns:1fr; } }

        /* text preview */
        .preview-box {
            background:rgba(0,0,0,.3); border:1px solid var(--line);
            border-radius:10px; padding:16px;
            font-family:'Courier New',monospace; font-size:12px;
            color:var(--text-accent); line-height:1.6;
            max-height:420px; overflow:auto;
            white-space:pre-wrap; word-break:break-all;
        }
        .preview-box-empty { color:rgba(255,255,255,.2); font-style:italic; }

        .msg-ok  { background:color-mix(in srgb, var(--accent-2), transparent 85%);  border:1px solid rgba(16,185,129,.3);  padding:10px 16px; border-radius:8px; color:var(--success); font-size:13px; margin-bottom:14px; }
        .msg-err { background:color-mix(in srgb, var(--danger), transparent 85%);   border:1px solid rgba(239,68,68,.3);   padding:10px 16px; border-radius:8px; color:var(--danger);  font-size:13px; margin-bottom:14px; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- -- HEADER -- -->
    <div class="page-header">
        <h1>Tag Type Analysis</h1>
        <div class="header-right">
            <span class="ctrl-label">Site:</span>
            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select"
                AutoPostBack="true" OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" />
            <asp:LinkButton ID="BtnExport" runat="server" CssClass="btn-success"
                Text="Export CSV" OnClick="Export_Click" />
            <a href="va_tag_stats.aspx" class="btn-ghost">Tag Stats</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <!-- -- KPI CARDS (JS-populated from counts grid) -- -->
    <div class="kpi-row">
        <div class="kpi-card">
            <div class="kpi-value" id="kv-types"  style="color:var(--accent);">0</div>
            <div class="kpi-label">Tag Types</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-total"  style="color:var(--highlight);">0</div>
            <div class="kpi-label">Total Tagged Assets</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-top-cnt" style="color:var(--success);">0</div>
            <div class="kpi-sub"   id="kv-top-pct" style="color:var(--success);">0% of total</div>
            <div class="kpi-label" id="kv-top-lbl">Top Type</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-avg"    style="color:var(--warning);">0</div>
            <div class="kpi-label">Avg Assets / Type</div>
        </div>
    </div>

    <!-- -- DISTRIBUTION BAR -- -->
    <div class="glass">
        <div class="panel-title"><span>Tag Type Distribution</span></div>
        <div class="dist-bar" id="distBar"></div>
        <div class="bar-legend" id="distLegend"></div>
    </div>

    <!-- -- COUNTS BY TAG TYPE -- -->
    <div class="glass">
        <div class="panel-title">
            <span>Counts by Tag Type</span>
            <asp:Literal ID="LitTagTypeCount" runat="server" />
        </div>

        <div class="tbl-wrap">
            <asp:GridView ID="GridTagTypeCounts" runat="server" AutoGenerateColumns="true"
                CssClass="display" ClientIDMode="Static"
                GridLines="None" AllowSorting="true" OnSorting="Grid_Sorting" />
        </div>
    </div>

    <!-- -- FILTERED PREVIEW -- -->
    <div class="glass">
        <div class="panel-title"><span>Filtered Asset Preview (Top 100)</span></div>

        <div class="ctrl-bar">
            <span class="ctrl-label">Tag Type contains:</span>
            <asp:TextBox ID="TxtTagType" runat="server" CssClass="txt-search"
                placeholder="Leave blank for all..." />
            <asp:Button ID="BtnTagTypePreview" runat="server" CssClass="btn-primary"
                Text="Preview" OnClick="BtnTagTypePreview_Click" />
            <asp:Button ID="BtnTagTypeCounts" runat="server" CssClass="btn-ghost"
                Text="Refresh Counts" OnClick="BtnTagTypeCounts_Click" />
        </div>

        <div class="two-col">
            <!-- Asset grid -->
            <div class="tbl-wrap">
                <asp:GridView ID="GridTagTypePreview" runat="server" AutoGenerateColumns="true"
                    CssClass="display" ClientIDMode="Static"
                    GridLines="None" AllowSorting="true" OnSorting="Grid_Sorting" />
            </div>

            <!-- Text preview panel -->
            <div>
                <div style="font-size:12px;color:var(--text-accent);font-weight:600;text-transform:uppercase;letter-spacing:.6px;margin-bottom:10px;">
                    Text Preview
                </div>
                <div class="preview-box" id="textPreviewBox">
                    <span class="preview-box-empty">Run a preview to populate this panel...</span>
                </div>
                <asp:TextBox ID="TxtTagTypePreview" runat="server" TextMode="MultiLine"
                    Style="display:none;" ReadOnly="true" />
            </div>
        </div>
    </div>

</div><!-- /dash -->
<idash:Footer runat="server" />
</form>

<script type="text/javascript">
    var PALETTE = ['#2EA8FF','#10B981','#8B5CF6','#F59E0B','#EF4444','#F97316','#06B6D4','#EC4899','#84CC16','#14B8A6','#A78BFA','#34D399'];

    function fmtN(n) { return new Intl.NumberFormat().format(n); }
    function pctStr(v,t) { return t>0?(v/t*100).toFixed(1)+'%':'0%'; }

    function anim(id, n) {
        var el=document.getElementById(id); if(!el||isNaN(n)) return;
        var t0=null,fmt=new Intl.NumberFormat();
        function step(t){if(!t0)t0=t;var p=Math.min((t-t0)/900,1);el.textContent=fmt.format(Math.round(p*n));if(p<1)requestAnimationFrame(step);}
        requestAnimationFrame(step);
    }

    function buildKpisFromCountsGrid() {
        var tbl = document.getElementById('GridTagTypeCounts');
        if (!tbl) return;
        var rows = tbl.querySelectorAll('tbody tr');
        if (!rows.length) return;

        var types = rows.length;
        var total = 0, topLabel='', topCnt=0;

        var items = [];
        rows.forEach(function(row) {
            var label = row.cells[0] ? row.cells[0].innerText.trim() : '';
            var cnt   = parseInt((row.cells[1] ? row.cells[1].innerText.trim() : '0').replace(/,/g,'')) || 0;
            total += cnt;
            items.push({label: label, cnt: cnt});
            if (cnt > topCnt) { topCnt=cnt; topLabel=label; }
        });

        var avg = types > 0 ? Math.round(total / types) : 0;

        anim('kv-types',   types);
        anim('kv-total',   total);
        anim('kv-top-cnt', topCnt);
        anim('kv-avg',     avg);

        var topPct = document.getElementById('kv-top-pct');
        if (topPct) topPct.textContent = pctStr(topCnt, total) + ' of total';
        var topLbl = document.getElementById('kv-top-lbl');
        if (topLbl) topLbl.textContent = topLabel || 'Top Type';

        buildDistBar(items, total);
    }

    function buildDistBar(items, total) {
        var bar = document.getElementById('distBar');
        var leg = document.getElementById('distLegend');
        if (!bar || !leg || !total) return;
        bar.innerHTML = ''; leg.innerHTML = '';

        // Sort descending for bar
        items.sort(function(a,b){ return b.cnt - a.cnt; });

        items.forEach(function(item, i) {
            var color = PALETTE[i % PALETTE.length];
            var w = (item.cnt/total*100).toFixed(2);
            var seg = document.createElement('div');
            seg.className='dist-seg';
            seg.style.cssText='width:'+w+'%;background:'+color+';';
            seg.title=item.label+': '+fmtN(item.cnt)+' ('+pctStr(item.cnt,total)+')';
            bar.appendChild(seg);

            var chip = document.createElement('div');
            chip.className='bar-chip';
            chip.innerHTML='<span class="chip-dot" style="background:'+color+'"></span>'
                +'<span>'+item.label+'</span>'
                +'<strong style="margin-left:4px;">'+fmtN(item.cnt)+'</strong>'
                +'<span style="opacity:.55;font-size:11px;margin-left:4px;">('+pctStr(item.cnt,total)+')</span>';
            // Click chip to filter preview
            chip.onclick = function() {
                var ttBox = document.getElementById('<%= TxtTagType.ClientID %>');
                if (ttBox) ttBox.value = item.label;
            };
            leg.appendChild(chip);
        });
    }

    function makeDataTable(id) {
        var tbl = $('#' + id);
        if (!tbl.length) return null;
        // Need at least a header and one data row to be useful
        if (tbl.find('tbody tr td').length < 2 && tbl.find('thead tr').length === 0 && tbl.find('tbody tr th').length === 0) return null;

        // Destroy any existing DataTable instance (happens on ASP.NET postback)
        if ($.fn.DataTable.isDataTable(tbl)) {
            tbl.DataTable().destroy();
        }

        // ASP.NET GridView loses <thead> on ViewState restore — reconstruct it
        var thead = tbl.find('thead');
        if (!thead.length || !thead.find('tr').length) {
            var firstRow = tbl.find('tbody tr').first();
            if (firstRow.find('th').length) {
                if (!thead.length) {
                    thead = $('<thead></thead>').prependTo(tbl);
                }
                firstRow.appendTo(thead);
            }
        }

        // Remove any stale search rows from previous init
        tbl.find('thead tr.col-search-row').remove();

        // Clone the FIRST header row only for per-col search row
        tbl.find('thead tr').first().clone(true).appendTo(tbl.find('thead')).addClass('col-search-row');
        tbl.find('thead tr.col-search-row th').each(function() {
            $(this).removeClass('sorting sorting_asc sorting_desc').off();
            $(this).html('<input class="col-search" type="text" placeholder="..." />');
        });

        var dt = tbl.DataTable({ dom:'lrtip', orderCellsTop:true, pageLength:25, stateSave:false });

        tbl.find('thead tr.col-search-row th').each(function() {
            var th = this;
            $('input', th).on('keyup change', function() {
                var col = dt.column(th);
                if (col.search() !== this.value) { col.search(this.value).draw(); }
            });
        });
        return dt;
    }

    function syncTextPreview() {
        var hidden = document.getElementById('<%= TxtTagTypePreview.ClientID %>');
        var box    = document.getElementById('textPreviewBox');
        if (!box) return;
        var txt = hidden ? hidden.value.trim() : '';
        if (txt) {
            box.textContent = txt;
            box.classList.remove('preview-box-empty');
        } else {
            box.innerHTML = '<span class="preview-box-empty">Run a preview to populate this panel...</span>';
        }
    }

    $(document).ready(function() {
        buildKpisFromCountsGrid();
        makeDataTable('GridTagTypeCounts');
        makeDataTable('GridTagTypePreview');
        syncTextPreview();
    });
</script>
</body>
</html>


