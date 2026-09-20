<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_assets_by_location.aspx.cs" Inherits="va_assets_by_location" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Assets by Location &mdash; iDash</title>
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
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        :root {
            --bg-base:      var(--bg);
            --panel-bg:     var(--card);
            --panel-border: var(--line);
            --text-main:    var(--text);
            --text-accent:  var(--muted);
            --highlight:    var(--accent);
            --success:      var(--accent-2);
            --accent:       #8B5CF6;
            --warning:      var(--warn);

            /* age bucket colours */
            --b0:  var(--accent-2);
            --b1:  var(--accent);
            --b2:  var(--warn);
            --b3:  #F97316;
            --b4:  var(--danger);
        }

        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background: var(--bg-base); color: var(--text-main);
            font-family: 'Inter','Segoe UI',sans-serif; font-size:14px;
            background-image:
                radial-gradient(circle at top left,  color-mix(in srgb, var(--accent), transparent 95%), transparent 40%),
                radial-gradient(circle at bottom right, rgba(139,92,246,.06), transparent 40%);
            min-height:100vh;
        }

        .dash { max-width:1440px; margin:0 auto; padding:30px 24px; }

        /* ── HEADER ── */
        .page-header {
            display:flex; justify-content:space-between; align-items:center;
            margin-bottom:28px; border-bottom:1px solid var(--panel-border);
            padding-bottom:20px; flex-wrap:wrap; gap:16px;
        }
        .page-header h1 {
            font-size:26px; font-weight:700;
            background: linear-gradient(90deg,#10B981,#2EA8FF);
            -webkit-background-clip:text; background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .header-right { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }

        /* ── GLASS ── */
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
        }

        /* ── KPI CARDS ── */
        .kpi-row { display:grid; grid-template-columns:repeat(5,1fr); gap:16px; margin-bottom:22px; }
        @media(max-width:1100px){ .kpi-row{ grid-template-columns:repeat(3,1fr); } }
        @media(max-width:640px) { .kpi-row{ grid-template-columns:repeat(2,1fr); } }

        .kpi-card {
            background:var(--panel-bg); border:1px solid var(--panel-border);
            border-radius:14px; padding:24px 16px; text-align:center;
            box-shadow:0 4px 20px rgba(0,0,0,.2);
            transition:border-color .2s,box-shadow .2s;
        }
        .kpi-card:hover { box-shadow:0 6px 28px color-mix(in srgb, var(--accent), transparent 85%); }
        .kpi-value { font-size:36px; font-weight:700; line-height:1; margin-bottom:6px; }
        .kpi-pct   { font-size:13px; font-weight:600; margin-bottom:4px; }
        .kpi-label { font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.7px; color:var(--text-accent); }

        /* ── AGE DISTRIBUTION STACKED BAR ── */
        .age-bar { display:flex; height:14px; border-radius:7px; overflow:hidden; margin:10px 0 14px; background:rgba(255,255,255,.05); }
        .age-seg { height:100%; transition:width .6s ease; }
        .bar-legend { display:flex; flex-wrap:wrap; gap:10px; }
        .bar-chip {
            display:inline-flex; align-items:center; gap:6px; font-size:12px;
            background:rgba(255,255,255,.04); border:1px solid rgba(255,255,255,.07);
            padding:4px 12px; border-radius:20px; cursor:pointer;
            transition:background .15s;
        }
        .bar-chip:hover,.bar-chip.active { background:rgba(255,255,255,.10); }
        .chip-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }

        /* ── CONTROLS ── */
        .ctrl-bar { display:flex; align-items:center; gap:12px; flex-wrap:wrap; margin-bottom:18px; }
        .ctrl-label { font-size:13px; color:var(--text-accent); }

        .txt-search, .ctrl-select, .ctrl-input {
            background:var(--chip); color:var(--text-main);
            border:1px solid var(--panel-border);
            padding:7px 14px; border-radius:8px; font-size:13px; outline:none;
        }
        .txt-search { width:260px; }
        .txt-search::placeholder, .ctrl-input::placeholder { color:var(--muted); opacity:0.5; }
        .ctrl-select option { background:var(--card); }

        /* ── BUTTONS ── */
        .btn-primary {
            background:color-mix(in srgb, var(--accent), transparent 85%); color:var(--highlight);
            border:1px solid var(--highlight);
            padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600;
            cursor:pointer; text-decoration:none; transition:all .2s;
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
            background:rgba(255,255,255,.04); color:var(--text-accent);
            border:1px solid var(--line);
            padding:7px 14px; border-radius:8px; font-size:13px; font-weight:500;
            cursor:pointer; text-decoration:none; transition:all .2s;
        }
        .btn-ghost:hover { color:var(--text-main); border-color:var(--panel-border); }

        /* age filter chips (legend buttons) */
        .age-btn {
            padding:6px 14px; border-radius:20px; font-size:12px; font-weight:600;
            cursor:pointer; border:1px solid transparent; transition:all .2s;
            text-decoration:none;
        }
        .age-btn:hover { opacity:.85; }
        .age-btn.active { outline:2px solid #fff; }

        /* ── DATATABLES SKIN ── */
        .tbl-wrap { overflow-x:auto; }
        .loc-tbl,.detail-tbl { width:100%; border-collapse:collapse; font-size:13px; }
        .loc-tbl th,.detail-tbl th {
            background:rgba(255,255,255,.04); color:var(--text-accent);
            font-size:11px; text-transform:uppercase; letter-spacing:.6px;
            padding:10px 14px; text-align:left; border-bottom:1px solid var(--line);
        }
        .loc-tbl td,.detail-tbl td { padding:10px 14px; border-bottom:1px solid rgba(255,255,255,.03); }
        .loc-tbl tbody tr:hover td,.detail-tbl tbody tr:hover td { background:rgba(255,255,255,.025); }

        div.dt-container { color:var(--text-main) !important; }
        .dt-info, .dt-length label, .dt-search label { color:var(--text-accent) !important; font-size:12px !important; }
        .dt-length select { background:var(--chip); color:#fff; border:1px solid var(--line); border-radius:4px; padding:4px; }
        .dt-search input { background:rgba(0,0,0,.35) !important; color:var(--text-main) !important; border:1px solid var(--panel-border) !important; border-radius:6px !important; padding:5px 10px !important; outline:none !important; }

        .col-search {
            width:100%; background:rgba(0,0,0,.35); color:#fff;
            border:1px solid var(--line); padding:5px 8px;
            border-radius:4px; font-size:11px; margin-top:4px;
        }
        .col-search::placeholder { color:rgba(255,255,255,.25); }

        /* bucket bar cells */
        .bucket-bar-cell { min-width:100px; }
        .mini-bar { height:6px; border-radius:3px; background:rgba(255,255,255,.06); overflow:hidden; margin-top:4px; display:flex; }
        .mini-seg { height:100%; }

        /* percent cells */
        .pct-good { color:var(--success); font-weight:600; }
        .pct-warn { color:var(--warning); font-weight:600; }
        .pct-bad  { color:var(--danger);  font-weight:600; }

        /* drill-down link */
        .loc-link { color:var(--highlight); font-weight:600; cursor:pointer; text-decoration:none; background:none; border:none; padding:0; font-size:13px; }
        .loc-link:hover { text-decoration:underline; }

        /* detail panel */
        .detail-panel { margin-top:0; }
        .detail-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; flex-wrap:wrap; gap:10px; }
        .detail-title { font-size:16px; font-weight:600; color:var(--text-main); }

        .err-msg { background:color-mix(in srgb, var(--danger), transparent 85%); border:1px solid rgba(239,68,68,.3); padding:12px 16px; border-radius:8px; color:var(--danger); }
        .ok-msg  { background:color-mix(in srgb, var(--accent-2), transparent 85%); border:1px solid rgba(16,185,129,.3); padding:12px 16px; border-radius:8px; color:var(--success); }
    </style>
</head>
<body>
<form id="form1" runat="server">

<!-- KPI hidden values from server -->
<asp:HiddenField ID="HdnTotalAssets"   runat="server" Value="0" />
<asp:HiddenField ID="HdnLocCount"      runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt03"         runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt46"         runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt79"         runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt1012"       runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt13"         runat="server" Value="0" />

<div class="dash">

    <!-- ── HEADER ── -->
    <div class="page-header">
        <h1>Assets by Location</h1>
        <div class="header-right">
            <span style="font-size:13px;color:var(--text-accent);">Site:</span>
            <asp:DropDownList ID="DdlCompany" runat="server" AutoPostBack="true"
                OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" CssClass="ctrl-select" />
            <asp:LinkButton ID="BtnAssetsByLocationExport" runat="server" CssClass="btn-success"
                Text="Export CSV" OnClick="Export_Click"
                CommandArgument="GridAssetsByLocation|AssetsByLocationSummary" />
            <a href="va_asset_stats.aspx" class="btn-ghost">Asset Stats</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <!-- ── KPI CARDS ── -->
    <div class="kpi-row">
        <div class="kpi-card">
            <div class="kpi-value" id="kv-total"  style="color:var(--highlight);">0</div>
            <div class="kpi-label">Total Assets</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-locs"   style="color:var(--accent);">0</div>
            <div class="kpi-label">Locations</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-0-3"   style="color:var(--success);">0</div>
            <div class="kpi-pct"   id="kp-0-3"   style="color:var(--success);">0%</div>
            <div class="kpi-label">0&ndash;3 Months</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-4-6"   style="color:var(--highlight);">0</div>
            <div class="kpi-pct"   id="kp-4-6"   style="color:var(--highlight);">0%</div>
            <div class="kpi-label">4&ndash;12 Months</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-over"  style="color:var(--danger);">0</div>
            <div class="kpi-pct"   id="kp-over"  style="color:var(--danger);">0%</div>
            <div class="kpi-label">13+ Months / Unknown</div>
        </div>
    </div>

    <!-- ── AGE DISTRIBUTION BAR ── -->
    <div class="glass">
        <div class="panel-title">Inventory Age Distribution &mdash; All Locations</div>
        <div class="age-bar" id="ageBar"></div>
        <div class="bar-legend" id="ageLegend"></div>
    </div>

    <!-- ── MAIN LOCATION SUMMARY ── -->
    <div class="glass">
        <div class="panel-title" style="display:flex;justify-content:space-between;align-items:center;">
            <span>Location Summary</span>
            <span id="locCountLabel" style="font-size:12px;color:var(--text-accent);font-weight:400;text-transform:none;letter-spacing:0;"></span>
        </div>

        <!-- Age-bucket filter buttons -->
        <div class="ctrl-bar" style="margin-bottom:20px;">
            <span class="ctrl-label">Filter by Age:</span>
            <asp:LinkButton ID="BtnFilter_0_3"   runat="server" CssClass="age-btn" style="background:color-mix(in srgb, var(--accent-2), transparent 85%);color:#10B981;border-color:#10B981;"  OnClick="BtnFilter_Click" CommandArgument="0-3">0&ndash;3 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_3_6"   runat="server" CssClass="age-btn" style="background:rgba(59,130,246,.15);color:#3B82F6;border-color:#3B82F6;"  OnClick="BtnFilter_Click" CommandArgument="4-6">4&ndash;6 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_6_9"   runat="server" CssClass="age-btn" style="background:rgba(245,158,11,.15);color:#F59E0B;border-color:#F59E0B;"  OnClick="BtnFilter_Click" CommandArgument="7-9">7&ndash;9 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_9_12"  runat="server" CssClass="age-btn" style="background:rgba(249,115,22,.15);color:#F97316;border-color:#F97316;"  OnClick="BtnFilter_Click" CommandArgument="10-12">10&ndash;12 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_12plus" runat="server" CssClass="age-btn" style="background:color-mix(in srgb, var(--danger), transparent 85%);color:#EF4444;border-color:#EF4444;"  OnClick="BtnFilter_Click" CommandArgument="13+">13+ mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilterReset"  runat="server" CssClass="age-btn" style="background:rgba(255,255,255,.06);color:var(--text-accent);border-color:var(--line);" OnClick="BtnFilterReset_Click">Show All</asp:LinkButton>
        </div>

        <!-- Location search -->
        <div class="ctrl-bar">
            <span class="ctrl-label">Search Location:</span>
            <asp:TextBox ID="TxtLocationSearch" runat="server" CssClass="txt-search" placeholder="Type a location name..." />
            <asp:Button ID="BtnSearchLocation" runat="server" CssClass="btn-primary" Text="Search" OnClick="BtnSearchLocation_Click" />
            <asp:Button ID="BtnClearSearch"    runat="server" CssClass="btn-ghost"   Text="Clear"  OnClick="BtnClearSearch_Click" />
        </div>

        <asp:Literal ID="LitAssetsByLocationCount" runat="server" />

        <!-- Main location grid -->
        <div class="tbl-wrap" style="margin-top:16px;">
            <asp:GridView ID="GridAssetsByLocation" runat="server" AutoGenerateColumns="false"
                CssClass="loc-tbl" ClientIDMode="Static"
                OnRowDataBound="GridAssetsByLocation_RowDataBound"
                OnRowCommand="GridAssetsByLocation_RowCommand"
                GridLines="None" UseAccessibleHeader="true">
                <Columns>
                    <asp:TemplateField HeaderText="Location">
                        <ItemTemplate>
                            <asp:LinkButton ID="BtnViewAssets" runat="server"
                                Text='<%# Eval("Location") %>'
                                CommandName="ViewAssets"
                                CommandArgument='<%# Eval("Location") %>'
                                CssClass="loc-link" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="TotalAssets"  HeaderText="Total" />
                    <asp:BoundField DataField="Count_0_3"   HeaderText="0-3 mo" />
                    <asp:BoundField DataField="Count_4_6"   HeaderText="4-6 mo" />
                    <asp:BoundField DataField="Count_7_9"   HeaderText="7-9 mo" />
                    <asp:BoundField DataField="Count_10_12" HeaderText="10-12 mo" />
                    <asp:BoundField DataField="Count_13plus" HeaderText="13+ mo" />
                    <asp:BoundField DataField="Pct_0_3"   HeaderText="% 0-3"  DataFormatString="{0:F1}" />
                    <asp:BoundField DataField="Pct_0_6"   HeaderText="% &lt;6m" DataFormatString="{0:F1}" />
                    <asp:BoundField DataField="Pct_0_12"  HeaderText="% &lt;12m" DataFormatString="{0:F1}" />
                </Columns>
            </asp:GridView>
        </div>

        <asp:Literal ID="LitAssetsByLocationTotal" runat="server" />
    </div>

    <!-- ── FILTER DETAIL PANEL ── -->
    <asp:Panel ID="PanelAssetFilterDetail" runat="server" Visible="false" CssClass="glass detail-panel">
        <div class="detail-header">
            <div class="detail-title">
                Assets filtered by age bucket:
                <strong style="color:var(--warning);"><asp:Literal ID="LitFilterRange" runat="server" /></strong>
            </div>
        </div>
        <div class="tbl-wrap">
            <asp:GridView ID="GridAssetFilterDetail" runat="server" AutoGenerateColumns="true"
                CssClass="detail-tbl" ClientIDMode="Static"
                GridLines="None" AllowSorting="true" OnSorting="Grid_Sorting" />
        </div>
    </asp:Panel>

    <!-- ── LOCATION DETAIL PANEL ── -->
    <asp:Panel ID="PanelAssetsDetail" runat="server" Visible="false" CssClass="glass detail-panel">
        <div class="detail-header">
            <div class="detail-title">
                Assets in:
                <strong style="color:var(--highlight);"><asp:Literal ID="LitSelectedLocation" runat="server" /></strong>
            </div>
        </div>
        <div class="tbl-wrap">
            <asp:GridView ID="GridAssetsDetail" runat="server" AutoGenerateColumns="true"
                CssClass="detail-tbl" ClientIDMode="Static"
                GridLines="None" AllowSorting="true" OnSorting="Grid_Sorting" />
        </div>
    </asp:Panel>

</div><!-- /dash -->
<aw:Footer runat="server" />
</form>

<script type="text/javascript">
    var AGE_COLORS = ['#10B981','#3B82F6','#F59E0B','#F97316','#EF4444'];
    var AGE_LABELS = ['0-3 mo','4-6 mo','7-9 mo','10-12 mo','13+ mo'];

    function fmtN(n) { return new Intl.NumberFormat().format(n); }
    function pctStr(v,t) { return t>0 ? (v/t*100).toFixed(1)+'%' : '0%'; }

    function anim(id, n, dur) {
        var el = document.getElementById(id); if (!el) return;
        var t0=null, fmt=new Intl.NumberFormat();
        function step(t) { if(!t0) t0=t; var p=Math.min((t-t0)/(dur||900),1); el.textContent=fmt.format(Math.round(p*n)); if(p<1) requestAnimationFrame(step); }
        requestAnimationFrame(step);
    }

    function initKpis() {
        var tot  = parseInt($('#<%= HdnTotalAssets.ClientID %>').val())  || 0;
        var locs = parseInt($('#<%= HdnLocCount.ClientID %>').val())     || 0;
        var c03  = parseInt($('#<%= HdnCnt03.ClientID %>').val())        || 0;
        var c46  = parseInt($('#<%= HdnCnt46.ClientID %>').val())        || 0;
        var c79  = parseInt($('#<%= HdnCnt79.ClientID %>').val())        || 0;
        var c1012= parseInt($('#<%= HdnCnt1012.ClientID %>').val())      || 0;
        var c13  = parseInt($('#<%= HdnCnt13.ClientID %>').val())        || 0;

        anim('kv-total', tot,  900);
        anim('kv-locs',  locs, 700);
        anim('kv-0-3',   c03,  700);
        anim('kv-4-6',   c46+c79+c1012, 700);
        anim('kv-over',  c13,  700);

        document.getElementById('kp-0-3').textContent  = pctStr(c03, tot);
        document.getElementById('kp-4-6').textContent  = pctStr(c46+c79+c1012, tot);
        document.getElementById('kp-over').textContent = pctStr(c13, tot);

        var lbl = document.getElementById('locCountLabel');
        if (lbl) lbl.textContent = fmtN(locs) + ' location' + (locs!==1?'s':'');

        // Build age distribution bar
        var bar = document.getElementById('ageBar');
        var leg = document.getElementById('ageLegend');
        if (!bar || !leg) return;
        bar.innerHTML = ''; leg.innerHTML = '';
        var counts = [c03, c46, c79, c1012, c13];
        counts.forEach(function(cnt, i) {
            if (!cnt) return;
            var w = tot > 0 ? (cnt/tot*100).toFixed(2) : 0;
            var seg = document.createElement('div');
            seg.className='age-seg';
            seg.style.cssText = 'width:'+w+'%;background:'+AGE_COLORS[i]+';';
            seg.title = AGE_LABELS[i]+': '+fmtN(cnt)+' ('+pctStr(cnt,tot)+')';
            bar.appendChild(seg);

            var chip = document.createElement('div');
            chip.className='bar-chip';
            chip.innerHTML='<span class="chip-dot" style="background:'+AGE_COLORS[i]+'"></span>'
                +'<span>'+AGE_LABELS[i]+'</span>'
                +'<strong style="margin-left:4px;">'+fmtN(cnt)+'</strong>'
                +'<span style="opacity:.55;font-size:11px;margin-left:4px;">('+pctStr(cnt,tot)+')</span>';
            leg.appendChild(chip);
        });
    }

    function applyMiniBar(tbl) {
        // Add mini stacked bar inside each location row
        $(tbl).find('tbody tr').each(function() {
            var cells = $(this).find('td');
            if (cells.length < 7) return;
            var tot  = parseInt(cells.eq(1).text()) || 0; if (!tot) return;
            var c03  = parseInt(cells.eq(2).text()) || 0;
            var c46  = parseInt(cells.eq(3).text()) || 0;
            var c79  = parseInt(cells.eq(4).text()) || 0;
            var c1012= parseInt(cells.eq(5).text()) || 0;
            var c13  = parseInt(cells.eq(6).text()) || 0;
            var segs = [c03,c46,c79,c1012,c13];
            var barHtml = '<div class="mini-bar">';
            segs.forEach(function(cnt,i) {
                if (!cnt) return;
                barHtml += '<div class="mini-seg" style="width:'+(cnt/tot*100).toFixed(1)+'%;background:'+AGE_COLORS[i]+';" title="'+AGE_LABELS[i]+': '+cnt+'"></div>';
            });
            barHtml += '</div>';
            cells.eq(1).html('<span>'+tot+'</span>'+barHtml);

            // colour the % cells
            var pct12 = parseFloat(cells.eq(9).text()) || 0;
            var pctEl  = cells.eq(9);
            pctEl.addClass(pct12 >= 80 ? 'pct-good' : pct12 >= 50 ? 'pct-warn' : 'pct-bad');
        });
    }

    function makeDataTable(id) {
        var tbl = $('#'+id);
        if (!tbl.length || tbl.find('tbody tr td').length < 2) return;

        // Clone header for per-col search
        tbl.find('thead tr').clone(true).appendTo(tbl.find('thead')).addClass('col-search-row');
        tbl.find('thead tr.col-search-row th').each(function() {
            $(this).removeClass('sorting').off();
            $(this).html('<input class="col-search" type="text" placeholder="..." />');
        });

        var dt = tbl.DataTable({ dom:'lrtip', orderCellsTop:true, pageLength:25, stateSave:false });

        tbl.find('thead tr.col-search-row th').each(function(i) {
            $('input', this).on('keyup change', function() {
                if (dt.column(i).search() !== this.value) { dt.column(i).search(this.value).draw(); }
            });
        });
        return dt;
    }

    $(document).ready(function() {
        initKpis();
        applyMiniBar('GridAssetsByLocation');
        makeDataTable('GridAssetsByLocation');
        makeDataTable('GridAssetsDetail');
        makeDataTable('GridAssetFilterDetail');
    });
</script>
</body>
</html>

