<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_tag_stats.aspx.cs" Inherits="iDash.va_tag_stats" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <title>Tagging Dashboard &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        :root {
            --panel:   var(--card);
            --border:  var(--line);
            --hl:      var(--accent);
            --green:   var(--accent-2);
            --purple:  #8B5CF6;
            --amber:   var(--warn);
            --red:     var(--danger);
        }
        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        *{box-sizing:border-box;}
        body{margin:0;padding:0;background:var(--bg);color:var(--text);font-family:'Inter','Segoe UI',sans-serif;
             background-image:radial-gradient(circle at top left,color-mix(in srgb, var(--accent), transparent 95%),transparent 40%),radial-gradient(circle at bottom right,rgba(139,92,246,.06),transparent 40%);min-height:100vh;}
        .dash{max-width:1440px;margin:0 auto;padding:28px 24px;}

        /* HEADER */
        .page-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:28px;border-bottom:1px solid var(--border);padding-bottom:18px;flex-wrap:wrap;gap:12px;}
        .page-header h1{margin:0;font-size:24px;font-weight:700;background:linear-gradient(90deg,#2EA8FF,#8B5CF6);-webkit-background-clip:text;-webkit-text-fill-color:transparent;}
        .hdr-right{display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
        .ctrl-select{background:var(--chip);color:var(--text);border:1px solid var(--border);padding:7px 12px;border-radius:8px;font-size:13px;outline:none;}
        .ctrl-select option{background:var(--card);color:var(--text);}
        /* header action pills — see theme.css .hdr-pill */

        /* TABS */
        .tab-bar{display:flex;gap:4px;margin-bottom:24px;border-bottom:1px solid var(--line);padding-bottom:0;flex-wrap:wrap;}
        .tab-btn{padding:10px 20px;background:none;border:none;border-bottom:3px solid transparent;color:var(--muted);font-size:13px;font-weight:600;cursor:pointer;transition:all .2s;font-family:inherit;margin-bottom:-1px;}
        .tab-btn:hover{color:var(--text);}
        .tab-btn.active{color:var(--hl);border-bottom-color:var(--hl);}
        .tab-pane{display:none;} .tab-pane.active{display:block;}

        /* GLASS */
        .glass{background:var(--panel);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);border:1px solid var(--border);border-radius:16px;padding:22px;box-shadow:var(--shadow);margin-bottom:20px;transition:all 0.2s;}
        .glass:hover{box-shadow:0 12px 44px rgba(0,0,0,0.25);transform:translateY(-2px);}
        .panel-title{font-size:13px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.8px;border-bottom:1px solid var(--line);padding-bottom:10px;margin-bottom:18px;}

        /* KPI ROW */
        .kpi-row{display:grid;grid-template-columns:repeat(5,1fr);gap:16px;margin-bottom:20px;}
        @media(max-width:1100px){.kpi-row{grid-template-columns:repeat(3,1fr);}}
        @media(max-width:700px){.kpi-row{grid-template-columns:repeat(2,1fr);}}
        @media(max-width:400px){.kpi-row{grid-template-columns:1fr;}}
        .kpi-card{text-align:center;padding:24px 16px;}
        .kpi-val{font-size:36px;font-weight:700;line-height:1;margin-bottom:6px;}
        .kpi-lbl{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.8px;color:var(--muted);}
        .kpi-sub{font-size:12px;color:var(--muted);margin-top:4px;}

        /* CHART GRID */
        .chart-grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px;}
        @media(max-width:800px){.chart-grid{grid-template-columns:1fr;}}
        .chart-wrap{position:relative;height:280px;}

        /* DATA TABLE */
        .dt{width:100%;border-collapse:collapse;font-size:13px;}
        .dt th{background:var(--chip);color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.6px;padding:9px 13px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap;cursor:pointer;user-select:none;}
        .dt th:hover{color:var(--text);}
        .dt td{padding:10px 13px;border-bottom:1px solid var(--line);color:var(--text);}
        .dt tbody tr:hover td{background:var(--chip);opacity:0.8;}
        #tblTagType tbody tr{transition:background 0.2s;}
        .dt .num{text-align:right;font-variant-numeric:tabular-nums;}
        .tbl-wrap{overflow-x:auto;}

        /* FILTER ROW */
        .filter-row th{padding:5px 8px !important;background:var(--chip) !important;}
        .fi{width:100%;background:var(--chip);color:var(--text);border:1px solid var(--line);padding:5px 8px;border-radius:4px;font-size:11px;}
        .fi::placeholder{color:var(--muted);opacity:0.5;}

        /* BADGES */
        .badge{display:inline-flex;align-items:center;padding:3px 10px;border-radius:16px;font-size:11px;font-weight:700;}
        .b-green{background:color-mix(in srgb, var(--accent-2), transparent 85%);color:#10B981;border:1px solid rgba(16,185,129,.3);}
        .b-red  {background:color-mix(in srgb, var(--danger), transparent 85%); color:#EF4444;border:1px solid rgba(239,68,68,.3);}
        .b-blue {background:color-mix(in srgb, var(--accent), transparent 85%); color:#2EA8FF;border:1px solid rgba(46,168,255,.3);}
        .b-amber{background:rgba(245,158,11,.18); color:#F59E0B;border:1px solid rgba(245,158,11,.3);}
        .b-purple{background:rgba(139,92,246,.18);color:#8B5CF6;border:1px solid rgba(139,92,246,.3);}

        /* PROGRESS BAR */
        .prog-bar{height:8px;border-radius:4px;background:rgba(255,255,255,.06);overflow:hidden;width:120px;display:inline-block;vertical-align:middle;margin-left:8px;}
        .prog-fill{height:100%;border-radius:4px;transition:width .6s ease;}

        /* SEARCH ROW (tag type) */
        .search-row{display:flex;gap:10px;margin-bottom:16px;flex-wrap:wrap;align-items:center;}
        .txt-input{background:var(--chip);color:var(--text);border:1px solid var(--border);padding:7px 12px;border-radius:8px;font-size:13px;outline:none;flex:1;min-width:180px;}

        /* STATUS BAR */
        .status-bar{display:flex;height:18px;border-radius:5px;overflow:hidden;background:rgba(255,255,255,.04);margin-bottom:10px;}
        .sbar-seg{height:100%;transition:width .5s ease;}
        .legend-grid{display:flex;flex-wrap:wrap;gap:6px;}
        .legend-chip{display:inline-flex;align-items:center;gap:5px;font-size:11px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.06);padding:3px 8px;border-radius:16px;}
        .ldot{width:7px;height:7px;border-radius:50%;flex-shrink:0;}

        /* GRID 2-col */
        .two-col{display:grid;grid-template-columns:1fr 1fr;gap:20px;}
        @media(max-width:800px){.two-col{grid-template-columns:1fr;}}

        .err-msg{background:color-mix(in srgb, var(--danger), transparent 85%);border:1px solid rgba(239,68,68,.3);padding:10px 14px;border-radius:8px;margin-bottom:14px;color:#EF4444;font-size:13px;}
        .ok-msg {background:color-mix(in srgb, var(--accent-2), transparent 85%);border:1px solid rgba(16,185,129,.3);padding:10px 14px;border-radius:8px;margin-bottom:14px;color:#10B981;font-size:13px;}
        .loading{color:var(--muted);font-size:13px;padding:20px 0;text-align:center;}
        .section-gap{margin-bottom:20px;}

        /* COLUMN PILLS */
        .col-pills{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:14px;align-items:center;}
        .col-pills-label{font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;font-weight:600;margin-right:4px;}
        .col-pill{display:inline-flex;align-items:center;gap:4px;padding:5px 14px;border-radius:999px;font-size:12px;font-weight:500;cursor:pointer;border:1.5px solid var(--line);background:var(--chip);color:var(--text);transition:all .2s;user-select:none;}
        .col-pill:hover{border-color:var(--accent);}
        .col-pill.active{background:color-mix(in srgb, var(--accent), transparent 85%);border-color:var(--accent);color:var(--accent);}
        .col-pill.dragging{opacity:0.4;transform:scale(0.95);}
        .col-pill .pill-drag{cursor:grab;font-size:10px;color:var(--muted);margin-right:2px;}
        .col-pill .pill-check{font-size:11px;}

        /* SORT INDICATORS */
        .dt th .sort-arrow{font-size:9px;margin-left:3px;opacity:0.4;}
        .dt th.sort-active .sort-arrow{opacity:1;color:var(--accent);}
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- HEADER -->
    <div class="page-header">
        <h1>&#127991; Tagging Dashboard</h1>
        <div class="hdr-right">
            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select"
                AutoPostBack="false" ClientIDMode="Static" onchange="reloadAll()" />
            <button type="button" class="nav-pill nav-pill-primary" onclick="reloadAll()" title="Force Refresh">&#8635; Refresh</button>
            <button type="button" class="nav-pill nav-pill-primary" onclick="exportCsv()">&#8615; Export CSV</button>
            <a href="documentation/va_tag_stats.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <asp:Literal ID="LitMsg" runat="server" />

    <!-- TAB BAR -->
    <div class="tab-bar">
        <button type="button" class="tab-btn active" onclick="switchTab('exec',this)">&#128200; Executive Overview</button>
        <button type="button" class="tab-btn" onclick="switchTab('employee',this)">&#128100; Employee Activity</button>
        <button type="button" class="tab-btn" onclick="switchTab('tagtype',this)">&#127991; Tag Type Analysis</button>
        <button type="button" class="tab-btn" onclick="switchTab('detail',this)">&#128203; Site Detail</button>
    </div>

    <!-- ══════════════ TAB 1: EXECUTIVE ══════════════ -->
    <div id="tab-exec" class="tab-pane active">

        <!-- KPI Row -->
        <div class="kpi-row section-gap" id="kpiRow">
            <div class="glass kpi-card">
                <div class="kpi-val" id="kv-total" style="color:var(--hl);">--</div>
                <div class="kpi-lbl">Total Assets</div>
                <div class="kpi-sub" id="kv-site">All Sites</div>
            </div>
            <div class="glass kpi-card">
                <div class="kpi-val" id="kv-tagged" style="color:var(--green);">--</div>
                <div class="kpi-lbl">Tagged</div>
                <div class="kpi-sub" id="kv-tagged-pct">--</div>
            </div>
            <div class="glass kpi-card">
                <div class="kpi-val" id="kv-untagged" style="color:var(--red);">--</div>
                <div class="kpi-lbl">Untagged</div>
                <div class="kpi-sub" id="kv-untagged-pct">--</div>
            </div>
            <div class="glass kpi-card">
                <div class="kpi-val" id="kv-notinuse" style="color:var(--amber);">--</div>
                <div class="kpi-lbl">Tagged, Not In Use</div>
                <div class="kpi-sub">disposed or retired</div>
            </div>
            <div class="glass kpi-card">
                <div class="kpi-val" id="kv-oit" style="color:var(--purple);">--</div>
                <div class="kpi-lbl">OIT Assets</div>
                <div class="kpi-sub" id="kv-oit-sub">CMR starts with 78</div>
            </div>
        </div>

        <!-- Date Range Filter -->
        <div class="glass section-gap" style="padding:14px 22px;">
            <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;">
                <span style="color:var(--muted);font-size:13px;">Date Range:</span>
                <button type="button" class="btn btn-primary" id="btn-all"   onclick="setRange('all')"   style="padding:5px 12px;font-size:12px;">All Time</button>
                <button type="button" class="btn" id="btn-month" onclick="setRange('month')" style="padding:5px 12px;font-size:12px;color:var(--muted);border-color:var(--line);">This Month</button>
                <button type="button" class="btn" id="btn-week"  onclick="setRange('week')"  style="padding:5px 12px;font-size:12px;color:var(--muted);border-color:var(--line);">This Week</button>
                <button type="button" class="btn" id="btn-today" onclick="setRange('today')" style="padding:5px 12px;font-size:12px;color:var(--muted);border-color:var(--line);">Today</button>
                <span style="color:var(--muted);font-size:12px;margin-left:8px;" id="rangeLabel"></span>
            </div>
        </div>

        <!-- Charts Row -->
        <div class="chart-grid section-gap">
            <div class="glass">
                <div class="panel-title">Tagged vs Untagged by Site</div>
                <div class="chart-wrap"><canvas id="chartSites"></canvas></div>
            </div>
            <div class="glass">
                <div class="panel-title">Tag Types Distribution</div>
                <div class="chart-wrap"><canvas id="chartTagTypes"></canvas></div>
            </div>
        </div>

        <!-- Trend Chart -->
        <div class="glass section-gap">
            <div class="panel-title">Scan Activity Trend (12 Months)</div>
            <div style="position:relative;height:220px;"><canvas id="chartTrend"></canvas></div>
        </div>

        <!-- Top Locations -->
        <div class="glass">
            <div class="panel-title">Top Locations by Tagged Assets</div>
            <div class="tbl-wrap"><table class="dt" id="tblLocations">
                <thead><tr><th onclick="sortDt(this,0,'tblLocations')">Location</th><th onclick="sortDt(this,1,'tblLocations')">Tagged</th></tr></thead>
                <tbody id="tblLocBody"><tr><td colspan="2" class="loading">Loading...</td></tr></tbody>
            </table></div>
        </div>
    </div>

    <!-- ══════════════ TAB 2: EMPLOYEE ══════════════ -->
    <div id="tab-employee" class="tab-pane">
        <div class="glass">
            <div class="panel-title">Inventory Activity by Employee ID</div>
            <div class="tbl-wrap"><table class="dt" id="tblEmp">
                <thead>
                    <tr>
                        <th onclick="sortDt(this,0,'tblEmp')">Employee ID</th>
                        <th class="num" onclick="sortDt(this,1,'tblEmp')">Today</th>
                        <th class="num" onclick="sortDt(this,2,'tblEmp')">This Week</th>
                        <th class="num" onclick="sortDt(this,3,'tblEmp')">This Month</th>
                        <th class="num" onclick="sortDt(this,4,'tblEmp')">Total</th>
                    </tr>
                    <tr class="filter-row">
                        <th><input class="fi" placeholder="filter..." onkeyup="filterDt('tblEmp',this,0)"/></th>
                        <th></th><th></th><th></th><th></th>
                    </tr>
                </thead>
                <tbody id="tblEmpBody"><tr><td colspan="5" class="loading">Select a site and click Refresh.</td></tr></tbody>
            </table></div>
        </div>
    </div>

    <!-- ══════════════ TAB 3: TAG TYPE ══════════════ -->
    <div id="tab-tagtype" class="tab-pane">
        <div class="glass">
            <div class="panel-title">Tag Type Inventory</div>
            <div class="two-col">
                <div>
                    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
                        <span style="font-size:12px;color:var(--muted);">Tag Type Counts</span>
                        <input type="text" class="fi" id="txtTagSearch" placeholder="filter tag types..." oninput="filterDt('tblTagType',this,0)" style="width:160px;" />
                    </div>
                    <div class="tbl-wrap" style="max-height:480px;overflow-y:auto;"><table class="dt" id="tblTagType">
                        <thead>
                            <tr>
                                <th onclick="sortDt(this,0,'tblTagType')">Tag Type</th>
                                <th class="num" onclick="sortDt(this,1,'tblTagType')">Count</th>
                                <th>Share</th>
                            </tr>
                        </thead>
                        <tbody id="tblTagTypeBody"><tr><td colspan="3" class="loading">Loading...</td></tr></tbody>
                    </table></div>
                </div>
                <div>
                    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;flex-wrap:wrap;gap:6px;">
                        <span style="font-size:12px;color:var(--muted);" id="previewLabel">Click a tag type to preview assets</span>
                        <span id="previewSelectedBadge" style="display:none;" class="badge b-blue"></span>
                    </div>
                    <div class="col-pills" id="previewColPills">
                        <span class="col-pills-label">Columns</span>
                    </div>
                    <div class="tbl-wrap" id="tagPreviewWrap" style="max-height:480px;overflow-y:auto;"><table class="dt" id="tblTagPreview">
                        <thead id="tblTagPreviewHead"></thead>
                        <tbody id="tblTagPreviewBody"><tr><td colspan="4" class="loading">Click a tag type on the left to view assets.</td></tr></tbody>
                    </table></div>
                </div>
            </div>
        </div>
    </div>

    <!-- ══════════════ TAB 4: SITE DETAIL ══════════════ -->
    <div id="tab-detail" class="tab-pane">
        <div class="glass">
            <div class="panel-title">Tagging Detail by Site</div>
            <div class="col-pills" id="detailColPills">
                <span class="col-pills-label">Columns</span>
            </div>
            <div class="tbl-wrap"><table class="dt" id="tblDetail">
                <thead id="tblDetailHead">
                </thead>
                <tbody id="tblDetailBody"><tr><td colspan="7" class="loading">Loading...</td></tr></tbody>
            </table></div>
        </div>
    </div>

</div><!-- /dash -->
<aw:Footer runat="server" />
</form>

<script>
// -- State --------------------------------------------------------------------
var currentRange = 'all';
var currentSite  = '0';
var chartSites, chartTagTypes, chartTrend;
var fmt = new Intl.NumberFormat();
var tagTypeData = []; // cache for tag type export

// -- Tab switching -------------------------------------------------------------
function switchTab(name, btn) {
    document.querySelectorAll('.tab-pane').forEach(function(p){ p.classList.remove('active'); });
    document.querySelectorAll('.tab-btn') .forEach(function(b){ b.classList.remove('active'); });
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
    if (name === 'employee' && (document.getElementById('tblEmpBody').innerText.indexOf('Select') >= 0 || document.getElementById('tblEmpBody').innerText.indexOf('Loading') >= 0)) loadEmployeeData();
    if (name === 'tagtype'  && document.getElementById('tblTagTypeBody').innerText.indexOf('Loading') >= 0) loadTagTypeCounts();
    if (name === 'detail'   && document.getElementById('tblDetailBody').innerText.indexOf('Loading') >= 0) loadDetailData();
}

// -- Site / Range --------------------------------------------------------------
function getSite() { return document.getElementById('<%= DdlCompany.ClientID %>').value; }

function setRange(r) {
    currentRange = r;
    ['all','month','week','today'].forEach(function(x){
        var b = document.getElementById('btn-'+x);
        b.style.color = x===r ? 'var(--hl)' : 'var(--muted)';
        b.style.borderColor = x===r ? 'var(--hl)' : 'var(--line)';
        b.style.background = x===r ? 'color-mix(in srgb, var(--accent), transparent 85%)' : 'none';
    });
    var labels = {all:'All time',month:'This month',week:'Last 7 days',today:'Today only'};
    document.getElementById('rangeLabel').textContent = labels[r];
    loadExecData();
}

function reloadAll() {
    currentSite = getSite();
    loadExecData();
    
    if (document.getElementById('tab-employee').classList.contains('active')) loadEmployeeData();
    else document.getElementById('tblEmpBody').innerHTML = '<tr><td colspan="5" class="loading">Loading...</td></tr>';
    
    if (document.getElementById('tab-tagtype').classList.contains('active'))  loadTagTypeCounts();
    else document.getElementById('tblTagTypeBody').innerHTML = '<tr><td colspan="3" class="loading">Loading...</td></tr>';
    
    if (document.getElementById('tab-detail').classList.contains('active'))   loadDetailData();
    else document.getElementById('tblDetailBody').innerHTML = '<tr><td colspan="7" class="loading">Loading...</td></tr>';
}

// -- API fetch helper ----------------------------------------------------------
function apiFetch(params, cb) {
    var url = 'va_tag_stats.aspx?' + params + '&companyid=' + getSite() + '&t=' + Date.now();
    fetch(url).then(function(r){ return r.json(); }).then(cb).catch(function(e){ console.error(e); });
}

// -- EXEC DATA -----------------------------------------------------------------
function loadExecData() {
    apiFetch('api=execstats&range=' + currentRange, function(d) {
        // KPIs
        animVal('kv-total',   d.kpis.Total,    900);
        animVal('kv-tagged',  d.kpis.Tagged,   900);
        animVal('kv-untagged', d.kpis.Untagged, 900);
        animVal('kv-notinuse', d.kpis.TaggedNotInUse, 900);
        var taggedPct  = d.kpis.Total > 0 ? (d.kpis.Tagged  / d.kpis.Total * 100).toFixed(1) : '0.0';
        var untaggedPct = d.kpis.Total > 0 ? (d.kpis.Untagged / d.kpis.Total * 100).toFixed(1) : '0.0';
        document.getElementById('kv-tagged-pct').textContent  = taggedPct + '% of total';
        document.getElementById('kv-untagged-pct').textContent = untaggedPct + '% of total';
        var siteName = document.getElementById('<%= DdlCompany.ClientID %>');
        document.getElementById('kv-site').textContent = siteName.options[siteName.selectedIndex].text;

        // Asset Value KPI
        if (d.kpis.AssetValue != null) {
            animDollar('kv-assetval', d.kpis.AssetValue, 1200);
            var vc = document.getElementById('kv-assetval-count');
            if (vc) vc.textContent = fmt.format(d.kpis.AssetValueCount || 0) + ' tagged assets w/ value';
        }
        
        // Total Asset Value KPI
        if (d.kpis.TotalAssetValue != null) {
            animDollar('kv-totalassetval', d.kpis.TotalAssetValue, 1200);
            var tvc = document.getElementById('kv-totalassetval-count');
            if (tvc) tvc.textContent = fmt.format(d.kpis.TotalAssetValueCount || 0) + ' total assets w/ value';
        }

        // OIT Assets KPI
        if (d.kpis.OitTotal != null) {
            animVal('kv-oit', d.kpis.OitTotal, 900);
            var oitSub = document.getElementById('kv-oit-sub');
            if (oitSub) {
                var oitTaggedPct = d.kpis.OitTotal > 0 ? (d.kpis.OitTagged / d.kpis.OitTotal * 100).toFixed(1) : '0.0';
                oitSub.textContent = fmt.format(d.kpis.OitTagged || 0) + ' tagged (' + oitTaggedPct + '%)';
            }
        }

        // Sites bar chart
        buildSiteChart(d.sites);

        // Tag types pie
        buildTagTypeChart(d.tagTypes);

        // Trend
        buildTrendChart(d.trend);

        // Top locations table
        var tbody = document.getElementById('tblLocBody');
        tbody.innerHTML = '';
        (d.locations || []).forEach(function(r){
            var tr = document.createElement('tr');
            tr.innerHTML = '<td>' + esc(r.label) + '</td><td class="num"><span class="badge b-green">' + fmt.format(r.count) + '</span></td>';
            tbody.appendChild(tr);
        });
    });
}

// -- CHARTS --------------------------------------------------------------------
var PALETTE = ['#2EA8FF','#10B981','#8B5CF6','#F59E0B','#F97316','#EF4444','#EC4899','#06B6D4','#84CC16','#A78BFA'];

function buildSiteChart(sites) {
    var ctx = document.getElementById('chartSites').getContext('2d');
    if (chartSites) chartSites.destroy();
    if (!sites || !sites.length) return;
    chartSites = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: sites.map(function(s){ return s.label; }),
            datasets: [
                { label:'Tagged',   data: sites.map(function(s){ return s.tagged; }),   backgroundColor:'rgba(16,185,129,.7)' },
                { label:'Untagged', data: sites.map(function(s){ return s.untagged; }), backgroundColor:'rgba(239,68,68,.7)'  }
            ]
        },
        options: { responsive:true, maintainAspectRatio:false, indexAxis:'y',
            plugins:{legend:{labels:{color:'var(--muted)',font:{size:11}}}},
            scales:{x:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.05)'}},
                    y:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.03)'}}}}
    });
}

function buildTagTypeChart(types) {
    var ctx = document.getElementById('chartTagTypes').getContext('2d');
    if (chartTagTypes) chartTagTypes.destroy();
    if (!types || !types.length) return;
    chartTagTypes = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: types.map(function(t){ return t.label; }),
            datasets: [{ data: types.map(function(t){ return t.count; }),
                backgroundColor: PALETTE, borderWidth:2, borderColor:'#0B1221' }]
        },
        options: { responsive:true, maintainAspectRatio:false,
            plugins:{ legend:{ position:'right', labels:{ color:'var(--muted)', font:{size:11}, padding:8 } } } }
    });
}

function buildTrendChart(trend) {
    var ctx = document.getElementById('chartTrend').getContext('2d');
    if (chartTrend) chartTrend.destroy();
    if (!trend || !trend.length) return;
    chartTrend = new Chart(ctx, {
        type: 'line',
        data: {
            labels: trend.map(function(t){ return t.label; }),
            datasets: [{ label:'Scans', data: trend.map(function(t){ return t.count; }),
                borderColor:'#2EA8FF', backgroundColor:'color-mix(in srgb, var(--accent), transparent 92%)',
                fill:true, tension:.4, pointRadius:4, pointBackgroundColor:'#2EA8FF' }]
        },
        options: { responsive:true, maintainAspectRatio:false,
            plugins:{legend:{labels:{color:'var(--muted)'}}},
            scales:{x:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.04)'}},
                    y:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.04)'}}}}
    });
}

// -- EMPLOYEE ------------------------------------------------------------------
function loadEmployeeData() {
    document.getElementById('tblEmpBody').innerHTML = '<tr><td colspan="5" class="loading">Loading...</td></tr>';
    apiFetch('api=userstats', function(rows) {
        var tbody = document.getElementById('tblEmpBody');
        tbody.innerHTML = '';
        rows.forEach(function(r) {
            var tr = document.createElement('tr');
            tr.innerHTML = '<td>' + esc(r.UserId) + '</td>' +
                '<td class="num">' + badge(r.Today,'b-green') + '</td>' +
                '<td class="num">' + fmt.format(r.ThisWeek) + '</td>' +
                '<td class="num">' + fmt.format(r.ThisMonth) + '</td>' +
                '<td class="num"><strong>' + fmt.format(r.Total) + '</strong></td>';
            tbody.appendChild(tr);
        });
        if (!rows.length) tbody.innerHTML = '<tr><td colspan="5" class="loading">No data found for selected site.</td></tr>';
    });
}

// -- TAG TYPES -----------------------------------------------------------------
function loadTagTypeCounts() {
    document.getElementById('tblTagTypeBody').innerHTML = '<tr><td colspan="3" class="loading">Loading...</td></tr>';
    apiFetch('api=tagtypecounts', function(rows) {
        tagTypeData = rows;
        var total = rows.reduce(function(s,r){ return s + (r.Count||0); }, 0);
        var tbody = document.getElementById('tblTagTypeBody');
        tbody.innerHTML = '';
        rows.forEach(function(r) {
            var pct = total > 0 ? (r.Count / total * 100).toFixed(1) : '0.0';
            var tr = document.createElement('tr');
            tr.style.cursor = 'pointer';
            tr.setAttribute('data-tagtype', r.TagType || '');
            tr.onclick = function() { selectTagType(r.TagType, tr); };
            tr.innerHTML = '<td>' + esc(r.TagType) + '</td><td class="num"><strong>' + fmt.format(r.Count) + '</strong></td>' +
                '<td><div class="prog-bar"><div class="prog-fill" style="width:' + pct + '%;background:var(--hl);"></div></div>' +
                '<span style="color:var(--muted);font-size:11px;margin-left:6px;">' + pct + '%</span></td>';
            tbody.appendChild(tr);
        });
        if (!rows.length) tbody.innerHTML = '<tr><td colspan="3" class="loading">No tag types found.</td></tr>';
        // Auto-select first tag type
        if (rows.length > 0) {
            var firstRow = tbody.querySelector('tr');
            selectTagType(rows[0].TagType, firstRow);
        }
    });
}

var selectedTagType = '';
function selectTagType(tagType, rowEl) {
    selectedTagType = tagType;
    // Highlight selected row
    document.querySelectorAll('#tblTagTypeBody tr').forEach(function(r) {
        r.style.background = '';
    });
    if (rowEl) rowEl.style.background = 'color-mix(in srgb, var(--accent), transparent 88%)';
    // Update badge
    var badge = document.getElementById('previewSelectedBadge');
    badge.style.display = 'inline-flex';
    badge.textContent = tagType;
    document.getElementById('previewLabel').textContent = 'Assets with tag type:';
    // Load preview
    loadTagTypeDetail(tagType);
}

// -- Tag Type Preview columns -------------------------------------------------
var previewColumns = [
    { key: 'asset',    label: 'Asset Tag',     field: 'AssetName',    filterable: true,  numeric: false, visible: true },
    { key: 'tagtype',  label: 'Tag Type',      field: 'TagType',      filterable: true,  numeric: false, visible: true },
    { key: 'location', label: 'Location',       field: 'Location',     filterable: true,  numeric: false, visible: true },
    { key: 'observed', label: 'Last Observed',  field: 'LastObserved', filterable: false, numeric: false, visible: true }
];
var previewData = [];
var previewSortCol = null;
var previewSortDir = 'asc';

function buildPreviewPills() {
    var wrap = document.getElementById('previewColPills');
    wrap.innerHTML = '<span class="col-pills-label">Columns</span>';
    previewColumns.forEach(function(col, idx) {
        var pill = document.createElement('span');
        pill.className = 'col-pill' + (col.visible ? ' active' : '');
        pill.draggable = true;
        pill.setAttribute('data-col-idx', idx);
        pill.innerHTML = '<span class="pill-drag">&#x283F;</span><span class="pill-check">' + (col.visible ? '&#x2713;' : '&#x25CB;') + '</span> ' + col.label;
        pill.onclick = function(e) {
            if (e.target.classList.contains('pill-drag')) return;
            col.visible = !col.visible;
            buildPreviewPills();
            renderPreviewTable();
        };
        pill.ondragstart = function(e) { e.dataTransfer.setData('text/plain', idx); pill.classList.add('dragging'); };
        pill.ondragend = function() { pill.classList.remove('dragging'); };
        pill.ondragover = function(e) { e.preventDefault(); };
        pill.ondrop = function(e) {
            e.preventDefault();
            var fromIdx = parseInt(e.dataTransfer.getData('text/plain'));
            if (fromIdx === idx) return;
            var moved = previewColumns.splice(fromIdx, 1)[0];
            previewColumns.splice(idx, 0, moved);
            buildPreviewPills();
            renderPreviewTable();
        };
        wrap.appendChild(pill);
    });
}

function renderPreviewTable() {
    var thead = document.getElementById('tblTagPreviewHead');
    var tbody = document.getElementById('tblTagPreviewBody');
    var visCols = previewColumns.filter(function(c){ return c.visible; });

    // Header row
    var headerRow = '<tr>';
    visCols.forEach(function(col) {
        var cls = col.numeric ? ' class="num"' : '';
        var arrow = '';
        if (previewSortCol === col.key) {
            arrow = ' <span class="sort-arrow">' + (previewSortDir === 'asc' ? '&#x25B2;' : '&#x25BC;') + '</span>';
            cls = cls ? cls.replace('"', ' sort-active"') : ' class="sort-active"';
        } else {
            arrow = ' <span class="sort-arrow">&#x25B2;</span>';
        }
        headerRow += '<th' + cls + ' onclick="sortPreview(\'' + col.key + '\')" style="cursor:pointer;">' + col.label + arrow + '</th>';
    });
    headerRow += '</tr>';

    // Filter row
    var filterRow = '<tr class="filter-row">';
    visCols.forEach(function(col) {
        if (col.filterable) {
            filterRow += '<th><input class="fi" placeholder="filter..." data-filter-key="' + col.key + '" onkeyup="filterPreview()"/></th>';
        } else {
            filterRow += '<th></th>';
        }
    });
    filterRow += '</tr>';
    thead.innerHTML = headerRow + filterRow;

    // Data rows
    if (!previewData.length) {
        tbody.innerHTML = '<tr><td colspan="' + visCols.length + '" class="loading">No assets found.</td></tr>';
        return;
    }

    tbody.innerHTML = '';
    var filters = getPreviewFilters();
    previewData.forEach(function(r) {
        var show = true;
        Object.keys(filters).forEach(function(key) {
            var val = filters[key];
            if (!val) return;
            var col = previewColumns.find(function(c){ return c.key === key; });
            if (!col || !col.field) return;
            if ((r[col.field] || '').toString().toLowerCase().indexOf(val) < 0) show = false;
        });
        if (!show) return;

        var tr = document.createElement('tr');
        var html = '';
        visCols.forEach(function(col) {
            var val = r[col.field] || '';
            if (col.key === 'observed') {
                html += '<td style="color:var(--muted);font-size:12px;">' + esc(val) + '</td>';
            } else {
                html += '<td>' + esc(val) + '</td>';
            }
        });
        tr.innerHTML = html;
        tbody.appendChild(tr);
    });
}

function getPreviewFilters() {
    var filters = {};
    document.querySelectorAll('#tblTagPreviewHead .fi').forEach(function(inp) {
        var key = inp.getAttribute('data-filter-key');
        if (key) filters[key] = (inp.value || '').toLowerCase();
    });
    return filters;
}

function filterPreview() { renderPreviewTable(); }

function sortPreview(colKey) {
    if (previewSortCol === colKey) {
        previewSortDir = previewSortDir === 'asc' ? 'desc' : 'asc';
    } else {
        previewSortCol = colKey;
        previewSortDir = 'asc';
    }
    var col = previewColumns.find(function(c){ return c.key === colKey; });
    previewData.sort(function(a, b) {
        var va = (a[col.field] || '').toString();
        var vb = (b[col.field] || '').toString();
        return previewSortDir === 'asc' ? va.localeCompare(vb) : vb.localeCompare(va);
    });
    renderPreviewTable();
}

function loadTagTypeDetail(tagType) {
    var filter = tagType || selectedTagType || document.getElementById('txtTagSearch').value.trim();
    document.getElementById('tblTagPreviewBody').innerHTML = '<tr><td colspan="4" class="loading">Loading...</td></tr>';
    buildPreviewPills();
    apiFetch('api=tagtypepreview&tagtype=' + encodeURIComponent(filter), function(rows) {
        previewData = rows;
        previewSortCol = null;
        renderPreviewTable();
    });
}

// -- SITE DETAIL ---------------------------------------------------------------
// -- Column definitions for Site Detail tab -----------------------------------
var detailColumns = [
    { key: 'site',     label: 'Site',      field: 'Site',     filterable: true,  numeric: false, visible: true },
    { key: 'tagged',   label: 'Tagged',     field: 'Tagged',   filterable: false, numeric: true,  visible: true },
    { key: 'untagged', label: 'Untagged',   field: 'NotTagged',filterable: false, numeric: true,  visible: true },
    { key: 'total',    label: 'Total',      field: 'Total',    filterable: false, numeric: true,  visible: true },
    { key: 'pct',      label: '% Tagged',   field: null,       filterable: false, numeric: false, visible: true }
];
var detailData = []; // cached rows
var detailSortCol = null;
var detailSortDir = 'asc';

// Build column pills
function buildDetailPills() {
    var wrap = document.getElementById('detailColPills');
    wrap.innerHTML = '<span class="col-pills-label">Columns</span>';
    detailColumns.forEach(function(col, idx) {
        var pill = document.createElement('span');
        pill.className = 'col-pill' + (col.visible ? ' active' : '');
        pill.draggable = true;
        pill.setAttribute('data-col-idx', idx);
        pill.innerHTML = '<span class="pill-drag">&#x283F;</span><span class="pill-check">' + (col.visible ? '&#x2713;' : '&#x25CB;') + '</span> ' + col.label;
        pill.onclick = function(e) {
            if (e.target.classList.contains('pill-drag')) return;
            col.visible = !col.visible;
            buildDetailPills();
            renderDetailTable();
        };
        // Drag and drop reorder
        pill.ondragstart = function(e) { e.dataTransfer.setData('text/plain', idx); pill.classList.add('dragging'); };
        pill.ondragend = function() { pill.classList.remove('dragging'); };
        pill.ondragover = function(e) { e.preventDefault(); };
        pill.ondrop = function(e) {
            e.preventDefault();
            var fromIdx = parseInt(e.dataTransfer.getData('text/plain'));
            var toIdx = idx;
            if (fromIdx === toIdx) return;
            var moved = detailColumns.splice(fromIdx, 1)[0];
            detailColumns.splice(toIdx, 0, moved);
            buildDetailPills();
            renderDetailTable();
        };
        wrap.appendChild(pill);
    });
}

// Render the detail table based on current columns and data
function renderDetailTable() {
    var thead = document.getElementById('tblDetailHead');
    var tbody = document.getElementById('tblDetailBody');
    var visCols = detailColumns.filter(function(c){ return c.visible; });

    // Build header row
    var headerRow = '<tr>';
    visCols.forEach(function(col, ci) {
        var cls = col.numeric ? ' class="num"' : '';
        var arrow = '';
        if (detailSortCol === col.key) {
            arrow = ' <span class="sort-arrow">' + (detailSortDir === 'asc' ? '&#x25B2;' : '&#x25BC;') + '</span>';
            cls = cls ? cls.replace('"', ' sort-active"') : ' class="sort-active"';
        } else {
            arrow = ' <span class="sort-arrow">&#x25B2;</span>';
        }
        headerRow += '<th' + cls + ' onclick="sortDetail(\'' + col.key + '\')" style="cursor:pointer;">' + col.label + arrow + '</th>';
    });
    headerRow += '</tr>';

    // Build filter row
    var filterRow = '<tr class="filter-row">';
    visCols.forEach(function(col, ci) {
        if (col.filterable) {
            filterRow += '<th><input class="fi" placeholder="filter..." data-filter-key="' + col.key + '" onkeyup="filterDetailMulti()"/></th>';
        } else {
            filterRow += '<th></th>';
        }
    });
    filterRow += '</tr>';
    thead.innerHTML = headerRow + filterRow;

    // Build data rows
    if (!detailData.length) {
        tbody.innerHTML = '<tr><td colspan="' + visCols.length + '" class="loading">No data found.</td></tr>';
        return;
    }

    tbody.innerHTML = '';
    var filters = getDetailFilters();
    detailData.forEach(function(r) {
        // Apply filters
        var show = true;
        Object.keys(filters).forEach(function(key) {
            var val = filters[key];
            if (!val) return;
            var col = detailColumns.find(function(c){ return c.key === key; });
            if (!col || !col.field) return;
            var cellVal = (r[col.field] || '').toString().toLowerCase();
            if (cellVal.indexOf(val) < 0) show = false;
        });
        if (!show) return;

        var total  = r.Total || 0;
        var tagged = r.Tagged || 0;
        var pct    = total > 0 ? (tagged / total * 100).toFixed(1) : '0.0';
        var pctColor = pct >= 80 ? 'var(--green)' : pct >= 50 ? 'var(--amber)' : 'var(--red)';

        var tr = document.createElement('tr');
        var html = '';
        visCols.forEach(function(col) {
            switch (col.key) {
                case 'site':     html += '<td>' + esc(r.Site) + '</td>'; break;
                case 'cmr':      html += '<td>' + esc(r.Owner) + '</td>'; break;
                case 'location': html += '<td>' + esc(r.Location) + '</td>'; break;
                case 'tagged':   html += '<td class="num"><span class="badge b-green">' + fmt.format(tagged) + '</span></td>'; break;
                case 'untagged': html += '<td class="num"><span class="badge b-red">' + fmt.format(r.NotTagged||0) + '</span></td>'; break;
                case 'total':    html += '<td class="num">' + fmt.format(total) + '</td>'; break;
                case 'pct':      html += '<td><span style="color:' + pctColor + ';font-weight:700;">' + pct + '%</span>' +
                                         '<div class="prog-bar" style="width:80px;"><div class="prog-fill" style="width:' + pct + '%;background:' + pctColor + ';"></div></div></td>'; break;
            }
        });
        tr.innerHTML = html;
        tbody.appendChild(tr);
    });
}

function getDetailFilters() {
    var filters = {};
    document.querySelectorAll('#tblDetailHead .fi').forEach(function(inp) {
        var key = inp.getAttribute('data-filter-key');
        if (key) filters[key] = (inp.value || '').toLowerCase();
    });
    return filters;
}

function filterDetailMulti() {
    renderDetailTable();
}

function sortDetail(colKey) {
    if (detailSortCol === colKey) {
        detailSortDir = detailSortDir === 'asc' ? 'desc' : 'asc';
    } else {
        detailSortCol = colKey;
        detailSortDir = 'asc';
    }
    var col = detailColumns.find(function(c){ return c.key === colKey; });
    detailData.sort(function(a, b) {
        var va, vb;
        if (colKey === 'pct') {
            va = a.Total > 0 ? a.Tagged / a.Total : 0;
            vb = b.Total > 0 ? b.Tagged / b.Total : 0;
        } else if (col && col.field) {
            va = a[col.field]; vb = b[col.field];
        } else {
            return 0;
        }
        if (col && col.numeric) {
            va = parseFloat(va) || 0; vb = parseFloat(vb) || 0;
            return detailSortDir === 'asc' ? va - vb : vb - va;
        }
        va = (va || '').toString(); vb = (vb || '').toString();
        return detailSortDir === 'asc' ? va.localeCompare(vb) : vb.localeCompare(va);
    });
    renderDetailTable();
}

function loadDetailData() {
    document.getElementById('tblDetailBody').innerHTML = '<tr><td colspan="7" class="loading">Loading...</td></tr>';
    buildDetailPills();
    apiFetch('api=tagstats', function(rows) {
        detailData = rows;
        renderDetailTable();
    });
}

// -- EXPORT --------------------------------------------------------------------
function exportCsv() {
    window.location.href = 'va_tag_stats.aspx?api=exportcsv&companyid=' + getSite();
}

function exportAssetValue() {
    window.location.href = 'va_tag_stats.aspx?api=exportassetvalue&companyid=' + getSite();
}

// -- TABLE HELPERS -------------------------------------------------------------
function filterDt(tblId, inp, colIdx) {
    var v = (inp.value || '').toLowerCase();
    var rows = document.getElementById(tblId).querySelector('tbody').querySelectorAll('tr');
    rows.forEach(function(r) {
        var td = r.cells[colIdx];
        var match = !v || (td && (td.innerText||'').toLowerCase().indexOf(v) >= 0);
        r.style.display = match ? '' : 'none';
    });
}

var dtFilters = {};
function filterDtMulti(tblId, inp, colIdx) {
    dtFilters[tblId + '_' + colIdx] = (inp.value || '').toLowerCase();
    var rows = document.getElementById(tblId).querySelector('tbody').querySelectorAll('tr');
    rows.forEach(function(r) {
        var show = true;
        Object.keys(dtFilters).forEach(function(k) {
            if (k.indexOf(tblId) !== 0) return;
            var ci = parseInt(k.split('_').pop());
            var v = dtFilters[k];
            if (!v) return;
            var cell = r.cells[ci];
            if (cell && (cell.innerText||'').toLowerCase().indexOf(v) < 0) show = false;
        });
        r.style.display = show ? '' : 'none';
    });
}

var sortState = {};
function sortDt(th, colIdx, tblId) {
    var key = tblId + '_' + colIdx;
    var dir = sortState[key] === 'asc' ? 'desc' : 'asc';
    sortState[key] = dir;
    var tbody = document.getElementById(tblId).querySelector('tbody');
    var rows = Array.from(tbody.querySelectorAll('tr'));
    rows.sort(function(a,b) {
        var ta = a.cells[colIdx] ? a.cells[colIdx].innerText.trim() : '';
        var tb = b.cells[colIdx] ? b.cells[colIdx].innerText.trim() : '';
        var na = parseFloat(ta.replace(/,/g,'')), nb = parseFloat(tb.replace(/,/g,''));
        if (!isNaN(na) && !isNaN(nb)) return dir === 'asc' ? na-nb : nb-na;
        return dir === 'asc' ? ta.localeCompare(tb) : tb.localeCompare(ta);
    });
    rows.forEach(function(r){ tbody.appendChild(r); });
}

function animVal(id, target, dur) {
    var el = document.getElementById(id); if (!el || isNaN(target)) return;
    var t0 = null;
    (function step(t) {
        if (!t0) t0 = t;
        var p = Math.min((t-t0)/dur, 1);
        el.textContent = fmt.format(Math.round(p * target));
        if (p < 1) requestAnimationFrame(step);
    })(performance.now());
}

var fmtDollar = new Intl.NumberFormat('en-US', { style:'currency', currency:'USD', maximumFractionDigits:0 });
function animDollar(id, target, dur) {
    var el = document.getElementById(id); if (!el || isNaN(target)) return;
    var t0 = null;
    (function step(t) {
        if (!t0) t0 = t;
        var p = Math.min((t-t0)/dur, 1);
        el.textContent = fmtDollar.format(Math.round(p * target));
        if (p < 1) requestAnimationFrame(step);
    })(performance.now());
}

function esc(s) {
    if (!s) return '';
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function badge(n, cls) {
    var v = parseInt(n)||0;
    if (v === 0) return '<span style="color:var(--muted);">0</span>';
    return '<span class="badge ' + cls + '">' + fmt.format(v) + '</span>';
}

// -- INIT ----------------------------------------------------------------------
document.addEventListener('DOMContentLoaded', function() {
    setRange('all');
});
</script>
</body>
</html>

