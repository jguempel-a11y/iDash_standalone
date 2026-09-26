<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_report_inventoried.aspx.cs" Inherits="va_report_inventoried" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Inventory Report &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
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
            --orange:       #F97316;
            /* bucket colours */
            --b0: var(--accent-2); --b1: var(--accent); --b2: var(--warn); --b3: #F97316; --b4: var(--danger);
        }

        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        * { box-sizing: border-box; margin:0; padding:0; }
        body {
            background: var(--bg-base); color: var(--text-main);
            font-family:'Inter','Segoe UI',sans-serif; font-size:14px;
            background-image:
                radial-gradient(circle at top left,  color-mix(in srgb, var(--accent), transparent 95%),transparent 40%),
                radial-gradient(circle at bottom right, rgba(139,92,246,.06),transparent 40%);
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
            background:linear-gradient(90deg,#10B981,#2EA8FF);
            -webkit-background-clip:text; background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .header-right { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }

        /* ── GLASS ── */
        .glass {
            background:var(--panel-bg);
            backdrop-filter:blur(14px); -webkit-backdrop-filter:blur(14px);
            border:1px solid var(--panel-border); border-radius:16px; padding:24px;
            box-shadow:var(--shadow); margin-bottom:22px;
        }
        .panel-title {
            font-size:12px; font-weight:600; color:var(--text-accent);
            text-transform:uppercase; letter-spacing:.8px;
            border-bottom:1px solid rgba(255,255,255,.05);
            padding-bottom:12px; margin-bottom:18px;
        }

        /* ── BUCKET CARDS ── */
        .bucket-row { display:flex; gap:14px; flex-wrap:wrap; margin-bottom:8px; }
        .bucket-card {
            flex:1; min-width:130px; padding:20px 16px; border-radius:14px;
            text-align:center; cursor:pointer; transition:all .2s;
            border:2px solid transparent; text-decoration:none;
            display:block; font-family:'Inter',sans-serif;
        }
        .bc-0 { background:color-mix(in srgb, var(--accent-2), transparent 85%);  border-color:#10B981; color:#10B981; }
        .bc-1 { background:rgba(59,130,246,.12);  border-color:#3B82F6; color:#3B82F6; }
        .bc-2 { background:rgba(245,158,11,.12);  border-color:#F59E0B; color:#F59E0B; }
        .bc-3 { background:rgba(249,115,22,.12);  border-color:#F97316; color:#F97316; }
        .bc-4 { background:color-mix(in srgb, var(--danger), transparent 85%);   border-color:#EF4444; color:#EF4444; }
        .bucket-card:hover { transform:translateY(-2px); box-shadow:0 6px 22px rgba(0,0,0,.3); }
        .bucket-card.active { box-shadow:0 0 0 3px rgba(255,255,255,.2); }
        .bc-label { font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.7px; opacity:.8; }
        .bc-value { font-size:32px; font-weight:700; line-height:1.1; margin:6px 0 4px; }
        .bc-pct   { font-size:12px; opacity:.75; }

        /* ── QUALITY BAR ── */
        .quality-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:14px; }
        @media(max-width:800px){ .quality-grid{ grid-template-columns:repeat(2,1fr); } }
        .q-card {
            background:var(--chip); border:1px solid var(--line);
            border-radius:12px; padding:16px; text-align:center;
        }
        .q-pct  { font-size:28px; font-weight:700; margin-bottom:4px; }
        .q-bar  { height:6px; border-radius:3px; background:rgba(255,255,255,.08); margin:8px 0 6px; overflow:hidden; }
        .q-fill { height:100%; border-radius:3px; }
        .q-label{ font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.7px; color:var(--text-accent); }

        /* ── ACTIVITY GRIDS ── */
        .two-col { display:grid; grid-template-columns:1fr 1fr; gap:22px; }
        @media(max-width:800px){ .two-col{ grid-template-columns:1fr; } }
        .activity-label { font-size:12px; font-weight:600; color:var(--text-accent); text-transform:uppercase; letter-spacing:.6px; margin-bottom:10px; }

        /* ── FILTER ROW ── */
        .filter-bar { display:flex; align-items:center; gap:14px; flex-wrap:wrap; margin-bottom:16px; padding:14px 16px; background:rgba(0,0,0,.2); border-radius:10px; border:1px solid var(--line); }
        .filter-label { font-size:12px; color:var(--text-accent); white-space:nowrap; }
        .filter-input {
            background:rgba(0,0,0,.35); color:var(--text-main);
            border:1px solid var(--panel-border); padding:6px 12px;
            border-radius:7px; font-size:13px; outline:none;
        }
        .filter-input::placeholder { color:rgba(255,255,255,.3); }
        .filter-check { accent-color:var(--highlight); width:16px; height:16px; cursor:pointer; }

        /* ── COLUMN TOGGLE ── */
        .col-toggle-bar {
            display:none; flex-wrap:wrap; gap:8px; padding:14px;
            background:rgba(0,0,0,.25); border:1px solid var(--line);
            border-radius:10px; margin-bottom:14px; font-size:12px;
        }
        .col-toggle-bar label {
            display:flex; align-items:center; gap:6px;
            background:rgba(255,255,255,.04); border:1px solid rgba(255,255,255,.08);
            padding:4px 10px; border-radius:16px; cursor:pointer; color:var(--text-accent);
        }
        .col-toggle-bar label:hover { background:rgba(255,255,255,.08); color:var(--text-main); }

        /* ── BUTTONS ── */
        .btn-primary {
            background:color-mix(in srgb, var(--accent), transparent 85%); color:var(--highlight);
            border:1px solid var(--highlight);
            padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600;
            cursor:pointer; transition:all .2s;
        }
        .btn-primary:hover { background:color-mix(in srgb, var(--accent), transparent 85%); }

        .btn-ghost {
            background:rgba(255,255,255,.04); color:var(--text-accent);
            border:1px solid var(--line);
            padding:7px 14px; border-radius:8px; font-size:13px; font-weight:500;
            cursor:pointer; text-decoration:none; transition:all .2s;
        }
        .btn-ghost:hover { color:var(--text-main); border-color:var(--panel-border); }

        .ctrl-select {
            background:var(--chip); color:var(--text-main);
            border:1px solid var(--panel-border);
            padding:7px 12px; border-radius:8px; font-size:13px; outline:none;
        }
        .ctrl-select option { background:var(--card); }

        /* ── DATATABLES SKIN ── */
        .tbl-wrap { overflow-x:auto; }
        .glass table { width:100%; border-collapse:collapse; font-size:13px; }
        .glass table th {
            background:rgba(255,255,255,.04); color:var(--text-accent);
            font-size:11px; text-transform:uppercase; letter-spacing:.5px;
            padding:9px 12px; text-align:left; border-bottom:1px solid var(--line);
        }
        .glass table td { padding:8px 12px; border-bottom:1px solid rgba(255,255,255,.03); }
        .glass table tbody tr:hover td { background:rgba(255,255,255,.025); }
        div.dt-container { color:var(--text-main)!important; }
        .dt-info,.dt-length label,.dt-search label { color:var(--text-accent)!important; font-size:12px!important; }
        .dt-length select { background:var(--chip); color:#fff; border:1px solid var(--line); border-radius:4px; padding:4px; }
        .dt-search input { background:rgba(0,0,0,.35)!important; color:var(--text-main)!important; border:1px solid var(--panel-border)!important; border-radius:6px!important; padding:5px 10px!important; outline:none!important; }
        .col-search {
            width:100%; background:rgba(0,0,0,.35); color:#fff;
            border:1px solid var(--line); padding:4px 8px;
            border-radius:4px; font-size:11px; margin-top:4px;
        }
        .col-search::placeholder { color:rgba(255,255,255,.25); }

        .bucket-active-label {
            display:inline-flex; align-items:center; gap:8px;
            font-size:14px; font-weight:600; color:var(--text-main);
        }
        .bucket-pill {
            padding:3px 12px; border-radius:20px; font-size:12px; font-weight:700;
        }
        .bc-sub   { font-size:11px; opacity:.65; margin-top:3px; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- ── HEADER ── -->
    <div class="page-header">
        <h1>Inventory Age Report</h1>
        <div class="header-right">
            <span style="font-size:13px;color:var(--text-accent);">Site:</span>
            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select"
                AutoPostBack="true" OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" />
            <a href="va_assets_by_location.aspx" class="btn-ghost">By Location</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <asp:Literal ID="LitErr" runat="server" />

<!-- Hidden bucket count values from server -->
<asp:HiddenField ID="HdnTotal" runat="server" Value="0" />
<asp:HiddenField ID="HdnB03"   runat="server" Value="0" />
<asp:HiddenField ID="HdnB46"   runat="server" Value="0" />
<asp:HiddenField ID="HdnB79"   runat="server" Value="0" />
<asp:HiddenField ID="HdnB1012" runat="server" Value="0" />
<asp:HiddenField ID="HdnB13"   runat="server" Value="0" />
<asp:HiddenField ID="HdnBNull" runat="server" Value="0" />

    <!-- ── AGE BUCKET CARDS ── -->
    <div class="glass">
        <div class="panel-title" style="display:flex;justify-content:space-between;align-items:center;">
            <span>Filter by Inventory Age &mdash; Click a bucket to drill down</span>
            <span id="totalBadge" style="font-size:12px;color:var(--text-accent);font-weight:400;text-transform:none;letter-spacing:0;"></span>
        </div>
        <div class="bucket-row">
            <asp:LinkButton runat="server" CssClass="bucket-card bc-0"
                CommandArgument="0-3" OnClick="BtnFilterInventoried_Click">
                <div class="bc-label">0 &ndash; 3 Months</div>
                <div class="bc-value" id="bv-03">0</div>
                <div class="bc-pct"  id="bp-03">0%</div>
                <div class="bc-sub">Recently Inventoried</div>
            </asp:LinkButton>
            <asp:LinkButton runat="server" CssClass="bucket-card bc-1"
                CommandArgument="4-6" OnClick="BtnFilterInventoried_Click">
                <div class="bc-label">4 &ndash; 6 Months</div>
                <div class="bc-value" id="bv-46">0</div>
                <div class="bc-pct"  id="bp-46">0%</div>
                <div class="bc-sub">Acceptable</div>
            </asp:LinkButton>
            <asp:LinkButton runat="server" CssClass="bucket-card bc-2"
                CommandArgument="7-9" OnClick="BtnFilterInventoried_Click">
                <div class="bc-label">7 &ndash; 9 Months</div>
                <div class="bc-value" id="bv-79">0</div>
                <div class="bc-pct"  id="bp-79">0%</div>
                <div class="bc-sub">Getting Stale</div>
            </asp:LinkButton>
            <asp:LinkButton runat="server" CssClass="bucket-card bc-3"
                CommandArgument="10-12" OnClick="BtnFilterInventoried_Click">
                <div class="bc-label">10 &ndash; 12 Months</div>
                <div class="bc-value" id="bv-1012">0</div>
                <div class="bc-pct"  id="bp-1012">0%</div>
                <div class="bc-sub">Needs Attention</div>
            </asp:LinkButton>
            <asp:LinkButton runat="server" CssClass="bucket-card bc-4"
                CommandArgument="12+" OnClick="BtnFilterInventoried_Click">
                <div class="bc-label">13+ Months</div>
                <div class="bc-value" id="bv-13">0</div>
                <div class="bc-pct"  id="bp-13">0%</div>
                <div class="bc-sub">Overdue</div>
            </asp:LinkButton>
        </div>

        <!-- stacked age bar -->
        <div style="margin-top:18px;">
            <div style="display:flex;height:10px;border-radius:5px;overflow:hidden;background:rgba(255,255,255,.05);" id="ageStackBar"></div>
            <div style="display:flex;flex-wrap:wrap;gap:10px;margin-top:10px;align-items:center;" id="ageLegendRow">
                <span id="nullChip" style="display:none;font-size:12px;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.1);padding:3px 10px;border-radius:20px;color:var(--text-accent);">
                    Never Inventoried: <strong id="nullCount">0</strong> (<span id="nullPct">0%</span>)
                </span>
            </div>
        </div>
    </div>


    <!-- ── DATA QUALITY COVERAGE CARDS ── -->
    <div class="glass">
        <div class="panel-title">Data Quality Coverage &mdash; Inventoried Assets</div>
        <div class="quality-grid">
            <div class="q-card">
                <div class="q-pct" id="qv-tagtype" style="color:var(--accent);">
                    <asp:Literal ID="LitPctTagType" runat="server" Text="0%" />
                </div>
                <div class="q-bar"><div class="q-fill" id="qb-tagtype" style="background:var(--accent);width:0;"></div></div>
                <div class="q-label">Tag Type Present</div>
            </div>
            <div class="q-card">
                <div class="q-pct" id="qv-emp" style="color:var(--highlight);">
                    <asp:Literal ID="LitPctEmp" runat="server" Text="0%" />
                </div>
                <div class="q-bar"><div class="q-fill" id="qb-emp" style="background:var(--highlight);width:0;"></div></div>
                <div class="q-label">Employee ID Present</div>
            </div>
            <div class="q-card">
                <div class="q-pct" id="qv-loc" style="color:var(--success);">
                    <asp:Literal ID="LitPctLoc" runat="server" Text="0%" />
                </div>
                <div class="q-bar"><div class="q-fill" id="qb-loc" style="background:var(--success);width:0;"></div></div>
                <div class="q-label">Location Tagged</div>
            </div>
            <div class="q-card">
                <div class="q-pct" id="qv-disp" style="color:var(--warning);">
                    <asp:Literal ID="LitPctDisp" runat="server" Text="0%" />
                </div>
                <div class="q-bar"><div class="q-fill" id="qb-disp" style="background:var(--warning);width:0;"></div></div>
                <div class="q-label">Status Present</div>
            </div>
        </div>
    </div>

    <!-- ── INVENTORY ACTIVITY ── -->
    <div class="glass">
        <div class="panel-title">Inventory Activity</div>
        <div class="two-col">
            <div>
                <div class="activity-label">&#128100; Human Inventory (Employee ID)</div>
                <div class="tbl-wrap">
                    <asp:GridView ID="GridHuman" runat="server" CssClass="display" ClientIDMode="Static"
                        GridLines="None" AutoGenerateColumns="true" UseAccessibleHeader="true" />
                </div>
            </div>
            <div>
                <div class="activity-label">&#128268; RFID / System Inventory (lastmodifiedby)</div>
                <div class="tbl-wrap">
                    <asp:GridView ID="GridSystem" runat="server" CssClass="display" ClientIDMode="Static"
                        GridLines="None" AutoGenerateColumns="true" UseAccessibleHeader="true" />
                </div>
            </div>
        </div>
    </div>

    <!-- ── DETAIL GRID ── -->
    <asp:Panel ID="PanelDetail" runat="server" CssClass="glass" Visible="false">
        <div class="panel-title" style="display:flex;justify-content:space-between;align-items:center;border:none;padding:0;margin-bottom:16px;">
            <span class="bucket-active-label">
                Assets in Bucket:
                <span class="bucket-pill" style="background:color-mix(in srgb, var(--accent), transparent 85%);color:var(--highlight);border:1px solid var(--highlight);">
                    <asp:Literal ID="LitBucket" runat="server" />
                </span>
            </span>
            <button type="button" class="btn-ghost" onclick="$('#ColToggleBar').toggle()" style="font-size:12px;">
                &#9776; Columns
            </button>
        </div>

        <!-- Column toggle -->
        <div id="ColToggleContainer">
            <div id="ColToggleBar" class="col-toggle-bar"></div>
        </div>

        <!-- Inline filters -->
        <div class="filter-bar">
            <span class="filter-label">NULL rows only:</span>
            <asp:CheckBox ID="ChkNullOnly" runat="server" AutoPostBack="true"
                OnCheckedChanged="FilterChanged" CssClass="filter-check" />
            <span class="filter-label">Description contains:</span>
            <asp:TextBox ID="TxtDesc" runat="server" CssClass="filter-input" Width="200px"
                AutoPostBack="true" OnTextChanged="FilterChanged" placeholder="Search desc..." />
            <span class="filter-label">Max days since:</span>
            <asp:TextBox ID="TxtDays" runat="server" CssClass="filter-input" Width="80px"
                AutoPostBack="true" OnTextChanged="FilterChanged" placeholder="e.g. 365" />
        </div>

        <div class="tbl-wrap">
            <asp:GridView ID="GridDetail" runat="server" CssClass="display"
                UseAccessibleHeader="true" ClientIDMode="Static"
                AutoGenerateColumns="true" GridLines="None" />
        </div>
    </asp:Panel>

</div><!-- /dash -->
<idash:Footer runat="server" />
</form>

<script type="text/javascript">
    // ── Animate quality bar fills ────────────────────────
    function animQualBars() {
        var pairs = [
            ['qv-tagtype','qb-tagtype'],
            ['qv-emp',    'qb-emp'],
            ['qv-loc',    'qb-loc'],
            ['qv-disp',   'qb-disp']
        ];
        pairs.forEach(function(pair) {
            var valEl = document.getElementById(pair[0]);
            var barEl = document.getElementById(pair[1]);
            if (!valEl || !barEl) return;
            var txt = valEl.textContent.trim();  // e.g. "73.4 %"
            var num = parseFloat(txt.replace(/[^0-9.]/g,'')) || 0;
            setTimeout(function() {
                barEl.style.transition = 'width 1s ease';
                barEl.style.width = Math.min(num, 100) + '%';
            }, 150);
        });
    }

    // ── DataTable helper ─────────────────────────────────
    function makeDataTable(id, opts) {
        var tbl = $('#' + id);
        if (!tbl.length || tbl.find('tbody tr td').length < 2) return null;
        if (!tbl.find('thead').length || !tbl.find('tbody').length) return null;

        if (opts && opts.colSearch) {
            tbl.find('thead tr').clone(true).appendTo(tbl.find('thead')).addClass('col-search-row');
            tbl.find('thead tr.col-search-row th').each(function() {
                $(this).removeClass('sorting').off();
                $(this).html('<input class="col-search" type="text" placeholder="..." />');
            });
        }

        var dtOpts = { dom: 'lrtip', orderCellsTop: true, pageLength: 25, stateSave: false };
        if (opts && opts.extra) $.extend(dtOpts, opts.extra);

        var dt = tbl.DataTable(dtOpts);

        if (opts && opts.colSearch) {
            tbl.find('thead tr.col-search-row th').each(function(i) {
                $('input', this).on('keyup change', function() {
                    if (dt.column(i).search() !== this.value) { dt.column(i).search(this.value).draw(); }
                });
            });
        }

        // Column toggle panel
        if (opts && opts.toggleId) {
            var container = $('#' + opts.toggleId);
            if (container.length) {
                container.html('<div style="width:100%;color:var(--text-accent);margin-bottom:6px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.6px;">Show / Hide Columns</div>');
                dt.columns().every(function() {
                    var col = this;
                    var hdr = $(col.header()).text().trim();
                    if (!hdr) return;
                    var lbl = $('<label></label>');
                    var cb  = $('<input type="checkbox" style="margin:0;" />');
                    cb.prop('checked', col.visible());
                    cb.on('change', function() { col.visible(this.checked); });
                    lbl.append(cb).append(' ' + hdr);
                    container.append(lbl);
                });
            }
        }
        return dt;
    }

    // ── Bucket counts from server hidden fields ──────────
    function animBuckets() {
        var tot   = parseInt($('#<%= HdnTotal.ClientID %>').val())  || 0;
        var b03   = parseInt($('#<%= HdnB03.ClientID %>').val())    || 0;
        var b46   = parseInt($('#<%= HdnB46.ClientID %>').val())    || 0;
        var b79   = parseInt($('#<%= HdnB79.ClientID %>').val())    || 0;
        var b1012 = parseInt($('#<%= HdnB1012.ClientID %>').val())  || 0;
        var b13   = parseInt($('#<%= HdnB13.ClientID %>').val())    || 0;
        var bNull = parseInt($('#<%= HdnBNull.ClientID %>').val())  || 0;
        var fmt   = new Intl.NumberFormat();

        // Total badge
        var badge = document.getElementById('totalBadge');
        if (badge && tot) badge.textContent = fmt.format(tot) + ' total assets';

        // Animate each card
        var buckets = [
            { valId:'bv-03',   pctId:'bp-03',   cnt: b03   },
            { valId:'bv-46',   pctId:'bp-46',   cnt: b46   },
            { valId:'bv-79',   pctId:'bp-79',   cnt: b79   },
            { valId:'bv-1012', pctId:'bp-1012', cnt: b1012 },
            { valId:'bv-13',   pctId:'bp-13',   cnt: b13   }
        ];

        buckets.forEach(function(b) {
            var vEl = document.getElementById(b.valId);
            var pEl = document.getElementById(b.pctId);
            if (!vEl) return;
            // animate count-up
            var t0 = null;
            (function step(ts) {
                if (!t0) t0 = ts;
                var p = Math.min((ts - t0) / 800, 1);
                vEl.textContent = fmt.format(Math.round(p * b.cnt));
                if (p < 1) requestAnimationFrame(step);
            })(0);
            requestAnimationFrame(function(ts) {});
            if (pEl && tot > 0) pEl.textContent = (b.cnt / tot * 100).toFixed(1) + '%';
        });

        // Stacked bar
        var bar = document.getElementById('ageStackBar');
        var leg = document.getElementById('ageLegendRow');
        if (bar && tot > 0) {
            var segs = [
                { cnt: b03,   color: '#10B981', label: '0-3 mo'   },
                { cnt: b46,   color: '#3B82F6', label: '4-6 mo'   },
                { cnt: b79,   color: '#F59E0B', label: '7-9 mo'   },
                { cnt: b1012, color: '#F97316', label: '10-12 mo' },
                { cnt: b13,   color: '#EF4444', label: '13+ mo'   }
            ];
            bar.innerHTML = '';
            segs.forEach(function(s) {
                if (!s.cnt) return;
                var w = (s.cnt / tot * 100).toFixed(2);
                var seg = document.createElement('div');
                seg.style.cssText = 'height:100%;width:' + w + '%;background:' + s.color + ';';
                seg.title = s.label + ': ' + fmt.format(s.cnt) + ' (' + (s.cnt/tot*100).toFixed(1) + '%)';
                bar.appendChild(seg);
                // legend chip
                var chip = document.createElement('span');
                chip.style.cssText = 'display:inline-flex;align-items:center;gap:5px;font-size:11px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);padding:3px 10px;border-radius:20px;color:var(--text-accent);';
                chip.innerHTML = '<span style="width:7px;height:7px;border-radius:50%;background:' + s.color + ';display:inline-block;"></span>'
                    + s.label + ' <strong style="margin-left:3px;color:var(--text-main);">' + fmt.format(s.cnt) + '</strong>'
                    + '<span style="opacity:.55;margin-left:3px;">(' + (s.cnt/tot*100).toFixed(1) + '%)</span>';
                leg.appendChild(chip);
            });
        }

        // "Never inventoried" chip
        if (bNull > 0 && tot > 0) {
            var nc = document.getElementById('nullChip');
            if (nc) {
                document.getElementById('nullCount').textContent = fmt.format(bNull);
                document.getElementById('nullPct').textContent   = (bNull/tot*100).toFixed(1) + '%';
                nc.style.display = 'inline-flex';
            }
        }
    }

    $(document).ready(function() {
        animBuckets();
        animQualBars();
        makeDataTable('GridHuman',  {});
        makeDataTable('GridSystem', {});
        makeDataTable('GridDetail', { colSearch: true, toggleId: 'ColToggleBar', extra: { pageLength: 25 } });
    });
</script>
</body>
</html>

