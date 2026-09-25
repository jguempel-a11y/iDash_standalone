<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_cmr_stats.aspx.cs" Inherits="va_cmr_stats" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>CMR Progress Report -- AssetWorx</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="CMR accountability and turnover progress tracking for AssetWorx asset inventories." />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link  href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet" />
    <script src="https://cdn.datatables.net/2.0.8/js/dataTables.js"></script>
    <style>
        

        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        *, *::before, *::after { box-sizing: border-box; }

        body {
            margin: 0; padding: 0;
            background: var(--bg);
            color: var(--text);
            font-family: 'Inter', 'Segoe UI', sans-serif;
            min-height: 100vh;
            background-image:
                radial-gradient(ellipse at 10% 0%,   color-mix(in srgb, var(--accent), transparent 92%) 0%, transparent 50%),
                radial-gradient(ellipse at 90% 100%, rgba(139,92,246,0.07) 0%, transparent 50%);
        }

        .dash { max-width: 1480px; margin: 0 auto; padding: 28px 22px; }

        /* ── HEADER ─────────────────────────────────── */
        .page-header {
            display: flex; justify-content: space-between; align-items: center;
            gap: 16px; flex-wrap: wrap;
            margin-bottom: 26px;
            border-bottom: 1px solid var(--border);
            padding-bottom: 20px;
        }
        .page-header h1 {
            margin: 0; font-size: 28px; font-weight: 800;
            background: linear-gradient(110deg, #2EA8FF 0%, #8B5CF6 100%);
            -webkit-background-clip: text; background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .page-header .subtitle {
            font-size: 13px; color: var(--muted); margin-top: 3px;
        }
        .nav-pills { display: flex; gap: 8px; flex-wrap: wrap; }
        .nav-pill {
            padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 500;
            border: 1px solid var(--line); color: var(--muted);
            background: transparent; text-decoration: none;
            cursor: pointer; transition: all 0.2s;
        }
        .nav-pill:hover { border-color: var(--blue); color: var(--blue); }

        /* ── GLASS PANEL ─────────────────────────────── */
        .glass {
            background: var(--panel);
            backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: 18px;
            padding: 24px;
            box-shadow: var(--shadow);
            margin-bottom: 20px;
            transition: all 0.2s;
        }
        .glass:hover { transform: translateY(-2px); box-shadow: 0 12px 44px rgba(0,0,0,0.25); }
        .panel-label {
            font-size: 11px; font-weight: 700; text-transform: uppercase;
            letter-spacing: 1px; color: var(--muted);
            margin-bottom: 16px; padding-bottom: 12px;
            border-bottom: 1px solid rgba(255,255,255,0.04);
        }

        /* ── SCAN WINDOW TABS ────────────────────────── */
        .window-tabs {
            display: flex; gap: 6px; align-items: center; flex-wrap: wrap;
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 6px;
            margin-bottom: 20px;
        }
        .window-tab {
            padding: 7px 18px; border-radius: 8px;
            font-size: 13px; font-weight: 600;
            border: none; background: transparent;
            color: var(--muted); cursor: pointer;
            transition: all 0.2s;
        }
        .window-tab:hover { color: var(--text); background: rgba(255,255,255,0.06); }
        .window-tab.active {
            background: color-mix(in srgb, var(--accent), transparent 85%);
            color: var(--blue);
            box-shadow: 0 0 0 1px color-mix(in srgb, var(--accent), transparent 55%);
        }
        .window-label-text {
            font-size: 12px; color: var(--muted); margin-left: 8px;
        }

        /* ── KPI CARDS ───────────────────────────────── */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 14px; margin-bottom: 20px;
        }
        @media(max-width:1200px){ .kpi-row { grid-template-columns: repeat(3,1fr); } }
        @media(max-width:640px) { .kpi-row { grid-template-columns: repeat(2,1fr); } }

        .kpi-card {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px 16px;
            text-align: center;
            box-shadow: var(--shadow);
            position: relative;
            overflow: hidden;
            transition: border-color 0.2s, transform 0.15s;
        }
        .kpi-card::before {
            content: ''; position: absolute;
            top: -30px; left: 50%; transform: translateX(-50%);
            width: 80px; height: 80px; border-radius: 50%;
            filter: blur(24px); opacity: 0.35;
        }
        .kpi-card:hover { border-color:color-mix(in srgb, var(--accent), transparent 55%); transform: translateY(-2px); }
        .kpi-value { font-size: 32px; font-weight: 800; line-height: 1; margin-bottom: 4px; }
        .kpi-sub   { font-size: 12px; font-weight: 600; margin-bottom: 4px; }
        .kpi-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.7px; color: var(--muted); }

        .k-blue   { color: var(--blue);   } .k-blue::before   { background: var(--blue);   }
        .k-green  { color: var(--green);  } .k-green::before  { background: var(--green);  }
        .k-yellow { color: var(--yellow); } .k-yellow::before { background: var(--yellow); }
        .k-red    { color: var(--red);    } .k-red::before    { background: var(--red);    }
        .k-purple { color: var(--purple); } .k-purple::before { background: var(--purple); }
        .k-orange { color: var(--orange); } .k-orange::before { background: var(--orange); }

        /* ── CONTROLS BAR ────────────────────────────── */
        .ctrl-bar {
            display: flex; align-items: center; gap: 12px;
            flex-wrap: wrap; margin-bottom: 16px;
        }
        .ctrl-label { font-size: 13px; color: var(--muted); white-space: nowrap; }
        .ctrl-select, .ctrl-input {
            background: var(--chip);
            color: var(--text);
            border: 1px solid var(--border);
            padding: 7px 12px; border-radius: 8px; font-size: 13px; outline: none;
        }
        .ctrl-select option { background: var(--card); color: var(--text); }
        .ctrl-input::placeholder { color: var(--muted); opacity: 0.5; }

        /* ── BUTTONS ─────────────────────────────────── */
        .btn { display: inline-flex; align-items: center; gap: 6px; padding: 7px 16px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; border: 1px solid; text-decoration: none; }
        .btn-blue   { background: color-mix(in srgb, var(--accent), transparent 85%);  color: var(--blue);   border-color: var(--blue);   }
        .btn-green  { background: color-mix(in srgb, var(--accent-2), transparent 85%);  color: var(--green);  border-color: var(--green);  }
        .btn-yellow { background: rgba(245,158,11,0.14);  color: var(--yellow); border-color: var(--yellow); }
        .btn-ghost  { background: rgba(255,255,255,0.04); color: var(--muted);  border-color: var(--line);   }
        .btn-blue:hover   { background: color-mix(in srgb, var(--accent), transparent 85%); }
        .btn-green:hover  { background: color-mix(in srgb, var(--accent-2), transparent 85%); }
        .btn-yellow:hover { background: rgba(245,158,11,0.28); }
        .btn-ghost:hover  { color: var(--text); border-color: var(--border); }

        /* ── CMR SUMMARY TABLE ───────────────────────── */
        .cmr-table-wrap { overflow-x: auto; }
        .cmr-table {
            width: 100%; border-collapse: collapse;
            font-size: 13px; min-width: 900px;
        }
        .cmr-table thead th {
            background: rgba(255,255,255,0.03);
            color: var(--muted);
            font-size: 11px; text-transform: uppercase; letter-spacing: 0.6px;
            padding: 10px 12px; text-align: left;
            border-bottom: 1px solid var(--line);
            cursor: pointer; user-select: none; white-space: nowrap;
        }
        .cmr-table tbody td {
            padding: 10px 12px;
            border-bottom: 1px solid rgba(255,255,255,0.03);
            vertical-align: middle;
        }
        .cmr-table tbody tr:hover td { background: rgba(255,255,255,0.03); }
        .num-col { text-align: right; }

        .cmr-bar-bg {
            height: 8px; background: rgba(255,255,255,0.07);
            border-radius: 4px; overflow: hidden; min-width: 100px;
        }
        .cmr-bar-fill {
            height: 100%; border-radius: 4px;
            transition: width 0.6s ease;
        }

        /* Status badges */
        .badge-complete { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--green);  border: 1px solid color-mix(in srgb, var(--accent-2), transparent 60%); padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap; }
        .badge-progress { background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--blue);   border: 1px solid color-mix(in srgb, var(--accent), transparent 55%); padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap; }
        .badge-none     { background: color-mix(in srgb, var(--danger), transparent 85%);  color: var(--red);    border: 1px solid rgba(239,68,68,0.35); padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap; }

        /* DataTables dark overrides */
        div.dt-container { color: var(--text) !important; }
        .dt-info, .dt-length label, .dt-search label { color: var(--muted) !important; font-size: 12px; }
        .dt-paging-button { color: var(--text) !important; }
        .dt-paging-button.current { background: var(--chip) !important; border-color: var(--border) !important; color:var(--text) !important; }
        .dt-length select { background: var(--chip); color:var(--text); border:1px solid var(--border); border-radius:4px; padding:4px; }
        .dt-search input { background: var(--chip); border: 1px solid var(--line); color: var(--text); padding: 6px 10px; border-radius: 6px; font-size: 12px; outline: none; }

        /* ── MESSAGES ─────────────────────────────────── */
        .err-msg  { background: color-mix(in srgb, var(--danger), transparent 85%);  border: 1px solid rgba(239,68,68,0.3);  padding: 12px 16px; border-radius: 8px; margin-bottom: 14px; color: var(--red);   }
        .ok-msg   { background: color-mix(in srgb, var(--accent-2), transparent 85%); border: 1px solid rgba(16,185,129,0.3); padding: 12px 16px; border-radius: 8px; margin-bottom: 14px; color: var(--green); }
        .no-data  { color: var(--muted); padding: 32px; text-align: center; font-size: 14px; }

        /* ── COMPLETION RING (overall %) ─────────────── */
        .ring-wrap { display: flex; align-items: center; gap: 20px; margin-bottom: 6px; }
        .ring-svg  { flex-shrink: 0; }
        .ring-track { fill: none; stroke: rgba(255,255,255,0.07); stroke-width: 8; }
        .ring-fill  { fill: none; stroke-width: 8; stroke-linecap: round;
                      transform: rotate(-90deg); transform-origin: 50% 50%;
                      transition: stroke-dasharray 1s ease; }
        .ring-text  { font-size: 13px; font-weight: 700; fill: var(--text); dominant-baseline: middle; text-anchor: middle; }
        .ring-info  { flex: 1; }
        .ring-info strong { font-size: 22px; font-weight: 800; }
        .ring-info span   { font-size: 12px; color: var(--muted); display: block; margin-top: 2px; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- ── HEADER ── -->
    <div class="page-header">
        <div>
            <h1>&#128203; CMR Progress Report</h1>
            <div class="subtitle">
                CMR accountability &amp; turnover tracking &mdash; Scan Window:
                <strong style="color:var(--blue);"><asp:Label ID="LblScanWindowLabel" runat="server" Text="30 Days" /></strong>
            </div>
        </div>
        <div class="nav-pills">
            <a href="va_asset_stats.aspx" class="nav-pill">Asset Stats</a>
            <a href="va_ennx.aspx" class="nav-pill">ENNX Report</a>
            <a href="documentation/va_cmr_stats.html" class="nav-pill">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <!-- ── SCAN WINDOW TABS ── -->
    <div class="window-tabs">
        <span class="ctrl-label" style="padding:0 6px;">Scan Window:</span>
        <asp:LinkButton ID="BtnWinToday" runat="server" CssClass="window-tab" CommandArgument="today" OnClick="BtnScanWindow_Click">Today</asp:LinkButton>
        <asp:LinkButton ID="BtnWin7"     runat="server" CssClass="window-tab" CommandArgument="7"     OnClick="BtnScanWindow_Click">Last 7 Days</asp:LinkButton>
        <asp:LinkButton ID="BtnWin30"    runat="server" CssClass="window-tab active" CommandArgument="30"    OnClick="BtnScanWindow_Click">Last 30 Days</asp:LinkButton>
        <asp:LinkButton ID="BtnWinAll"   runat="server" CssClass="window-tab" CommandArgument="all"   OnClick="BtnScanWindow_Click">All Time</asp:LinkButton>
        <span class="window-label-text">Click a window to see how many CMR assets were found in that period</span>
    </div>

    <!-- ── HIDDEN FIELDS ── -->
    <asp:HiddenField ID="HdnScanWindow"  runat="server" Value="30" />
    <asp:HiddenField ID="HdnKpiTotal"    runat="server" Value="0" />
    <asp:HiddenField ID="HdnKpiScanned"  runat="server" Value="0" />
    <asp:HiddenField ID="HdnKpiRemain"   runat="server" Value="0" />
    <asp:HiddenField ID="HdnKpiNever"    runat="server" Value="0" />
    <asp:HiddenField ID="HdnKpiCmrs"     runat="server" Value="0" />
    <asp:HiddenField ID="HdnKpiPct"      runat="server" Value="0" />

    <!-- ── KPI CARDS ── -->
    <div class="kpi-row">
        <div class="kpi-card">
            <div class="kpi-value k-purple" id="kv-cmrs">0</div>
            <div class="kpi-sub" style="color:var(--muted);">CMR Groups</div>
            <div class="kpi-label">Total CMRs</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value k-blue" id="kv-total">0</div>
            <div class="kpi-sub" style="color:var(--muted);">Assets in CMR</div>
            <div class="kpi-label">Total Assets</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value k-green" id="kv-scanned">0</div>
            <div class="kpi-sub k-green" id="kp-scanned">0%</div>
            <div class="kpi-label" id="kpi-found-label">Found (30 Days)</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value k-yellow" id="kv-remain">0</div>
            <div class="kpi-sub k-yellow" id="kp-remain">0%</div>
            <div class="kpi-label">Still Remaining</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value k-red" id="kv-never">0</div>
            <div class="kpi-sub" style="color:var(--muted);">Never Inventoried</div>
            <div class="kpi-label">Never Scanned</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value k-orange" id="kv-pct">0%</div>
            <div class="kpi-sub" style="color:var(--muted);">of All CMR Assets</div>
            <div class="kpi-label">Overall Progress</div>
        </div>
    </div>

    <!-- ── CMR SUMMARY PANEL ── -->
    <div class="glass">
        <div class="panel-label">CMR-by-CMR Breakdown &mdash; Found vs. Remaining</div>

        <!-- Controls -->
        <div class="ctrl-bar">
            <span class="ctrl-label">Site:</span>
            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select"
                AutoPostBack="true" OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" />

            <span class="ctrl-label">Search CMR:</span>
            <asp:TextBox ID="TxtCmrSearch" runat="server" CssClass="ctrl-input"
                placeholder="e.g. 040  or  040, 041, 042" style="width:220px;" />
            <asp:Button ID="BtnSearch" runat="server" Text="Search" CssClass="btn btn-blue" OnClick="BtnSearch_Click" />
            <span style="font-size:11px;color:#5a7090;margin-left:8px;">Separate multiple CMRs with commas</span>
        </div>

        <!-- Export / Email -->
        <div class="ctrl-bar" style="margin-bottom:18px;">
            <asp:Button ID="BtnExportSummary" runat="server" Text="&#128202; Export CMR Summary" CssClass="btn btn-green" OnClick="BtnExportSummary_Click" />
            <asp:Button ID="BtnExportDetail"  runat="server" Text="&#128196; Export Asset Detail" CssClass="btn btn-ghost"  OnClick="BtnExportDetail_Click" />
            <asp:Button ID="BtnEmail"         runat="server" Text="&#9993; Email Report"          CssClass="btn btn-yellow"
                OnClick="BtnEmail_Click"
                OnClientClick="return confirm('Email the CMR summary report to configured recipients?');" />
        </div>

        <asp:Literal ID="LitErr" runat="server" />

        <!-- CMR Summary Table (rendered from C#) -->
        <asp:Literal ID="LitCmrSummary" runat="server" />
    </div>

</div><!-- /dash -->
<idash:Footer runat="server" />
</form>

<script type="text/javascript">
    // ── Animated counter ──────────────────────────────────────────
    function animVal(id, target, dur, fmt, isSuffix) {
        var el = document.getElementById(id);
        if (!el || isNaN(target)) return;
        var nf = new Intl.NumberFormat();
        var t0 = null;
        function step(t) {
            if (!t0) t0 = t;
            var p = Math.min((t - t0) / dur, 1);
            var v = Math.round(p * target);
            el.textContent = fmt ? (nf.format(v)) : (isSuffix ? v + '%' : nf.format(v));
            if (p < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
    }

    function pctStr(val, total) {
        if (!total) return '0.0%';
        return (val / total * 100).toFixed(1) + '%';
    }

    // ── Init KPIs ─────────────────────────────────────────────────
    function initKpis() {
        var total   = parseInt(document.getElementById('<%= HdnKpiTotal.ClientID %>').value)   || 0;
        var scanned = parseInt(document.getElementById('<%= HdnKpiScanned.ClientID %>').value) || 0;
        var remain  = parseInt(document.getElementById('<%= HdnKpiRemain.ClientID %>').value)  || 0;
        var never   = parseInt(document.getElementById('<%= HdnKpiNever.ClientID %>').value)   || 0;
        var cmrs    = parseInt(document.getElementById('<%= HdnKpiCmrs.ClientID %>').value)    || 0;
        var pct     = parseFloat(document.getElementById('<%= HdnKpiPct.ClientID %>').value)   || 0;
        var win     = document.getElementById('<%= HdnScanWindow.ClientID %>').value;

        var winLabels = { today: 'Today', '7': '7 Days', '30': '30 Days', 'all': 'All Time' };
        var lbl = winLabels[win] || '30 Days';
        var lbEl = document.getElementById('kpi-found-label');
        if (lbEl) lbEl.textContent = 'Found (' + lbl + ')';

        animVal('kv-cmrs',    cmrs,    900, true,  false);
        animVal('kv-total',   total,   900, true,  false);
        animVal('kv-scanned', scanned, 800, true,  false);
        animVal('kv-remain',  remain,  800, true,  false);
        animVal('kv-never',   never,   800, true,  false);

        // % card
        var pctEl = document.getElementById('kv-pct');
        if (pctEl) {
            var t0 = null;
            (function step(t) {
                if (!t0) t0 = t;
                var p = Math.min((t - t0) / 900, 1);
                pctEl.textContent = (p * pct).toFixed(1) + '%';
                if (p < 1) requestAnimationFrame(step);
            })(performance.now());
        }

        var kpSc = document.getElementById('kp-scanned');
        var kpRe = document.getElementById('kp-remain');
        if (kpSc) kpSc.textContent = pctStr(scanned, total);
        if (kpRe) kpRe.textContent = pctStr(remain,  total);

        // Active window tab
        var tabMap = { today: 'BtnWinToday', '7': 'BtnWin7', '30': 'BtnWin30', all: 'BtnWinAll' };
        Object.keys(tabMap).forEach(function(k) {
            var el = document.getElementById(tabMap[k]);
            if (el) el.classList.toggle('active', k === win);
        });
    }

    // ── DataTable on CMR Summary ──────────────────────────────────
    $(document).ready(function() {
        initKpis();

        var tbl = $('#CmrSummaryTable');
        if (tbl.length && tbl.find('tbody tr').length > 0) {
            tbl.DataTable({
                pageLength: 25,
                ordering: true,
                order: [[5, 'desc']], // sort by % complete desc
                dom: '<"ctrl-bar" l f> rt ip',
                language: {
                    search: 'Filter:',
                    lengthMenu: 'Show _MENU_ CMRs'
                },
                columnDefs: [
                    { orderable: false, targets: [4] }  // progress bar col
                ]
            });
        }
    });
</script>
</body>
</html>

