<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_fixed_reader.aspx.cs" Inherits="iDash.va_fixed_reader" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <title>Fixed Reader Dashboard &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap');
        :root {
            --panel:   var(--card);
            --border:  var(--line);
            --hl:      var(--accent);
            --green:   #10B981;
            --purple:  #8B5CF6;
            --amber:   #F59E0B;
            --red:     #EF4444;
            --cyan:    #06B6D4;
        }
        [data-theme="light"] { --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1); }
        *{box-sizing:border-box;}
        body{margin:0;padding:0;background:var(--bg);color:var(--text);font-family:'Inter','Segoe UI',sans-serif;
             background-image:radial-gradient(circle at top left,color-mix(in srgb, var(--accent), transparent 95%),transparent 40%),radial-gradient(circle at bottom right,rgba(139,92,246,.06),transparent 40%);min-height:100vh;}
        .dash{max-width:1440px;margin:0 auto;padding:28px 24px;}

        /* HEADER */
        .page-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:28px;border-bottom:1px solid var(--border);padding-bottom:18px;flex-wrap:wrap;gap:12px;}
        .page-header h1{margin:0;font-size:20px;font-weight:600;color:var(--text);}
        .hdr-right{display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
        .ctrl-select{background:var(--chip);color:var(--text);border:1px solid var(--border);padding:7px 12px;border-radius:8px;font-size:13px;outline:none;}
        .ctrl-select option{background:var(--card);color:var(--text);}
        .btn{display:inline-flex;align-items:center;gap:6px;padding:7px 16px;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;border:1px solid;transition:all .2s;text-decoration:none;}
        .btn-primary{background:color-mix(in srgb, var(--accent), transparent 85%);color:var(--hl);border-color:var(--hl);}
        .btn-primary:hover{background:color-mix(in srgb, var(--accent), transparent 75%);}
        .nav-link{color:var(--muted);font-size:13px;text-decoration:none;padding:6px 12px;border-radius:6px;border:1px solid var(--line);transition:all .2s;}
        .nav-link:hover{color:var(--text);border-color:var(--border);}

        /* GLASS PANELS */
        .glass{background:var(--panel);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);border:1px solid var(--border);border-radius:16px;padding:22px;box-shadow:var(--shadow);margin-bottom:20px;transition:all 0.2s;}
        .glass:hover{box-shadow:0 8px 24px rgba(0,0,0,0.15);}
        .panel-title{font-size:13px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.8px;border-bottom:1px solid var(--line);padding-bottom:10px;margin-bottom:18px;}

        /* KPI ROW */
        .kpi-row{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:20px;}
        @media(max-width:1000px){.kpi-row{grid-template-columns:repeat(2,1fr);}}
        @media(max-width:400px){.kpi-row{grid-template-columns:1fr;}}
        .kpi-card{text-align:center;padding:24px 16px;}
        .kpi-val{font-size:28px;font-weight:600;line-height:1;margin-bottom:6px;}
        .kpi-lbl{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.8px;color:var(--muted);}
        .kpi-sub{font-size:12px;color:var(--muted);margin-top:4px;}

        /* STATUS BAR */
        .status-bar{display:flex;height:28px;border-radius:8px;overflow:hidden;background:rgba(255,255,255,.04);margin-bottom:14px;}
        .status-seg{height:100%;transition:width .6s ease;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:600;color:rgba(255,255,255,.9);}

        /* LEGEND */
        .legend-grid{display:flex;flex-direction:column;gap:2px;}
        .legend-chip{display:flex;align-items:center;gap:10px;font-size:13px;padding:8px 4px;border-radius:6px;}
        .legend-chip:hover{background:rgba(255,255,255,.03);}
        .legend-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0;}
        .legend-name{flex:1;font-weight:500;}
        .legend-pct{font-weight:600;font-variant-numeric:tabular-nums;min-width:60px;text-align:right;}
        .legend-pct-sub{font-size:11px;color:var(--muted);min-width:48px;text-align:right;}

        /* GRIDS */
        .two-col{display:grid;grid-template-columns:1fr 1fr;gap:20px;}
        @media(max-width:900px){.two-col{grid-template-columns:1fr;}}

        /* DATA TABLE */
        .dt{width:100%;border-collapse:collapse;font-size:13px;}
        .dt th{background:var(--chip);color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.6px;padding:9px 13px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap;cursor:pointer;user-select:none;}
        .dt th:hover{color:var(--text);}
        .dt td{padding:10px 13px;border-bottom:1px solid var(--line);color:var(--text);}
        .dt tbody tr:hover td{background:var(--chip);}
        .dt .num{text-align:right;font-variant-numeric:tabular-nums;}
        .tbl-wrap{overflow-x:auto;}

        /* FILTER */
        .filter-row th{padding:5px 8px !important;background:var(--chip) !important;}
        .fi{width:100%;background:var(--chip);color:var(--text);border:1px solid var(--line);padding:5px 8px;border-radius:4px;font-size:11px;}
        .fi::placeholder{color:var(--muted);opacity:0.5;}

        /* BADGES & DOTS */
        .badge{display:inline-flex;align-items:center;padding:3px 10px;border-radius:16px;font-size:11px;font-weight:600;}
        .b-green{background:color-mix(in srgb, #10B981, transparent 88%);color:#059669;border:1px solid rgba(16,185,129,.2);}
        .b-red{background:color-mix(in srgb, #EF4444, transparent 88%);color:#DC2626;border:1px solid rgba(239,68,68,.2);}
        .b-cyan{background:color-mix(in srgb, #6B7280, transparent 88%);color:#4B5563;border:1px solid rgba(107,114,128,.2);}
        .b-amber{background:rgba(245,158,11,.18);color:#F59E0B;border:1px solid rgba(245,158,11,.3);}
        .dot-up{width:8px;height:8px;border-radius:50%;background:#10B981;display:inline-block;margin-right:4px;animation:pulse-green 2s infinite;}
        .dot-down{width:8px;height:8px;border-radius:50%;background:#EF4444;display:inline-block;margin-right:4px;}
        @keyframes pulse-green{0%,100%{opacity:1;}50%{opacity:.4;}}

        /* TAG READ STATS */
        .stat-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;}
        @media(max-width:600px){.stat-grid{grid-template-columns:repeat(2,1fr);}}
        .stat-card{text-align:center;background:var(--chip);border-radius:10px;padding:16px 12px;}
        .stat-val{font-size:20px;font-weight:600;line-height:1;margin-bottom:4px;color:var(--accent);}
        .stat-lbl{font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);}

        .err-msg{background:color-mix(in srgb, var(--danger), transparent 85%);border:1px solid rgba(239,68,68,.3);padding:10px 14px;border-radius:8px;margin-bottom:14px;color:#EF4444;font-size:13px;}
        .loading{color:var(--muted);font-size:13px;padding:20px 0;text-align:center;}
        .spinner{display:inline-block;width:16px;height:16px;border:2px solid var(--line);border-top:2px solid var(--hl);border-radius:50%;animation:spin .8s linear infinite;margin-right:6px;vertical-align:middle;}
        @keyframes spin{to{transform:rotate(360deg);}}

        .hdr-pill{display:inline-flex;align-items:center;gap:5px;padding:6px 12px;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;border:1px solid var(--line);background:transparent;color:var(--accent);text-decoration:none;transition:background .15s,border-color .15s;font-family:inherit;}
        .hdr-pill:hover{border-color:var(--accent);background:color-mix(in srgb,var(--accent),transparent 90%);}
        .hdr-pill.primary{background:color-mix(in srgb,var(--accent),transparent 85%);color:var(--accent);border-color:var(--accent);}
        .hdr-pill.primary:hover{background:color-mix(in srgb,var(--accent),transparent 75%);}
        /* Clickable table rows */
        .row-link { cursor:pointer; transition:background 0.15s; }
        .row-link:hover { background:color-mix(in srgb, var(--accent), transparent 88%) !important; }
        .row-link td:first-child { text-decoration:underline; text-decoration-style:dotted; text-underline-offset:3px; color:var(--accent); }

        /* INTELLIGENCE PANELS */
        .intel-header{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;}
        .intel-header .panel-title{border:none;padding:0;margin:0;}
        .intel-actions{display:flex;gap:8px;align-items:center;}
        .btn-sm{display:inline-flex;align-items:center;gap:4px;padding:5px 12px;border-radius:6px;font-size:11px;font-weight:600;cursor:pointer;border:1px solid;transition:all .2s;font-family:inherit;}
        .btn-reassign{background:color-mix(in srgb,#8B5CF6,transparent 85%);color:#8B5CF6;border-color:#8B5CF6;}
        .btn-reassign:hover{background:color-mix(in srgb,#8B5CF6,transparent 70%);}
        .btn-save{background:color-mix(in srgb,#10B981,transparent 85%);color:#10B981;border-color:#10B981;}
        .btn-save:hover{background:color-mix(in srgb,#10B981,transparent 70%);}
        .settings-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px;margin-top:14px;}
        .setting-item{display:flex;flex-direction:column;gap:4px;}
        .setting-item label{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);}
        .setting-item input[type=number],.setting-item input[type=text],.setting-item select{background:var(--chip);color:var(--text);border:1px solid var(--line);padding:8px 12px;border-radius:8px;font-size:13px;font-family:inherit;}
        .toggle-wrap{display:flex;align-items:center;gap:10px;padding-top:4px;}
        .toggle{position:relative;width:44px;height:24px;}
        .toggle input{opacity:0;width:0;height:0;}
        .toggle-slider{position:absolute;cursor:pointer;inset:0;background:var(--line);border-radius:24px;transition:.3s;}
        .toggle-slider:before{position:absolute;content:"";height:18px;width:18px;left:3px;bottom:3px;background:var(--text);border-radius:50%;transition:.3s;}
        .toggle input:checked + .toggle-slider{background:#10B981;}
        .toggle input:checked + .toggle-slider:before{transform:translateX(20px);}
        .mismatch-badge{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;}
        .mb-warn{background:rgba(245,158,11,.1);color:#B45309;border:1px solid rgba(245,158,11,.2);}
        .mb-ready{background:rgba(59,130,246,.1);color:#2563EB;border:1px solid rgba(59,130,246,.2);}
        .mb-ok{background:rgba(16,185,129,.15);color:#10B981;border:1px solid rgba(16,185,129,.3);}
        .collapsible{overflow:hidden;transition:max-height .3s ease, opacity .3s ease;max-height:0;opacity:0;}
        .collapsible.open{max-height:600px;opacity:1;}
        .toast{position:fixed;bottom:24px;right:24px;background:#10B981;color:#fff;padding:12px 20px;border-radius:10px;font-size:13px;font-weight:600;z-index:9999;opacity:0;transition:opacity .3s;pointer-events:none;}
        .toast.show{opacity:1;}

        /* ASSET DETAIL PANEL */
        .detail-panel{position:fixed;top:0;right:0;bottom:0;width:700px;max-width:95vw;background:var(--card);border-left:2px solid var(--line);z-index:200;transform:translateX(100%);transition:transform .3s ease;display:flex;flex-direction:column;overflow:hidden;box-shadow:-8px 0 30px rgba(0,0,0,.25);}
        .detail-panel.open{transform:translateX(0);}
        body.detail-open .dash{margin-right:710px;transition:margin-right .3s ease;}
        @media(max-width:1100px){body.detail-open .dash{margin-right:0;}}
        .dp-header{display:flex;align-items:center;justify-content:space-between;padding:16px 20px;border-bottom:1px solid var(--line);background:linear-gradient(135deg,color-mix(in srgb,var(--accent),var(--card) 88%),var(--card));flex-shrink:0;}
        .dp-header h2{margin:0;font-size:16px;font-weight:600;display:flex;align-items:center;gap:10px;}
        .dp-header h2 .dp-icon{width:32px;height:32px;border-radius:8px;display:flex;align-items:center;justify-content:center;background:var(--accent);font-size:13px;color:#fff;}
        .dp-close{background:none;border:1px solid var(--line);border-radius:8px;color:var(--muted);width:32px;height:32px;font-size:16px;cursor:pointer;transition:border-color .2s,color .2s;}
        .dp-close:hover{border-color:#EF4444;color:#EF4444;}
        .dp-actions{display:flex;gap:6px;padding:10px 20px;border-bottom:1px solid var(--line);background:var(--bg);flex-shrink:0;flex-wrap:wrap;}
        .dp-action-btn{display:inline-flex;align-items:center;gap:5px;padding:6px 14px;border-radius:6px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid var(--line);background:var(--chip);color:var(--text);cursor:pointer;transition:.2s;font-family:inherit;}
        .dp-action-btn:hover{border-color:var(--accent);color:var(--accent);}
        .dp-body{flex:1;overflow-y:auto;padding:20px;}
        .dp-field-group{margin-bottom:18px;}
        .dp-field-group-title{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--line);padding-bottom:6px;margin-bottom:10px;}
        .dp-fields{display:grid;grid-template-columns:1fr 1fr;gap:8px 16px;}
        .dp-field label{display:block;font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.3px;margin-bottom:2px;}
        .dp-field .dp-val{font-size:13px;color:var(--text);padding:5px 8px;background:var(--bg);border:1px solid var(--line);border-radius:5px;min-height:28px;word-break:break-word;}
        .dp-field .dp-val.empty{color:var(--muted);font-style:italic;opacity:.5;}
        .dp-loading{text-align:center;padding:30px;color:var(--accent);font-weight:600;font-size:13px;}
        .dp-empty{text-align:center;padding:40px 20px;color:var(--muted);font-size:13px;font-style:italic;}
        .asset-link{cursor:pointer;text-decoration:underline;text-decoration-style:dotted;text-underline-offset:3px;color:var(--accent);}
        .asset-link:hover{color:var(--text);}
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- HEADER -->
    <div class="page-header">
        <h1>Fixed Readers</h1>
        <div class="hdr-right">
            <div style="display:flex;flex-direction:column;gap:2px;" title="Filter tag observation stats by the site that OWNS the tags (the company the assets belong to)">
                <span style="font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;">Show Tags Owned By</span>
                <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select"
                    AutoPostBack="false" ClientIDMode="Static" onchange="loadAll()" />
            </div>
            <div style="display:flex;flex-direction:column;gap:2px;" title="Filter by where the reader is physically installed (which facility/building)">
                <span style="font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;">Reader Installed At</span>
                <asp:DropDownList ID="DdlReaderSite" runat="server" CssClass="ctrl-select"
                    AutoPostBack="false" ClientIDMode="Static" onchange="loadAll()" />
            </div>
            <button type="button" class="nav-pill nav-pill-ghost" onclick="loadAll()" title="Refresh all data">&#8635; Refresh</button>
            <button type="button" id="themeToggleBtn" class="nav-pill nav-pill-ghost" onclick="toggleTheme()" title="Switch between light and dark mode" style="font-size:16px;padding:6px 10px;">??</button>
            <div style="width:1px;height:20px;background:var(--line);"></div>
            <a href="va_asset_master.aspx" class="nav-pill nav-pill-ghost">&#128203; Asset Master</a>
            <a href="va_fixed_reader.aspx" class="nav-pill nav-pill-primary nav-pill-primary--active">&#128202; Dashboard</a>
            <a href="va_fixed_reader_live.aspx" class="nav-pill nav-pill-ghost" target="_blank">&#128225; Live Feed</a>
            <div style="width:1px;height:20px;background:var(--line);"></div>
            <a href="documentation/va_fixed_reader.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <asp:Literal ID="LitMsg" runat="server" />

    <!-- FILTER CONTEXT HELPER -->
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px;padding:8px 14px;background:var(--chip);border:1px solid var(--line);border-radius:8px;font-size:12px;color:var(--muted);">
        <span><strong>Show Tags Owned By</strong> filters which site's assets appear in the stats below. <strong>Reader Installed At</strong> filters by the physical location of the reader hardware. Change either to auto-refresh.</span>
    </div>

    <!-- KPI ROW -->
    <div class="kpi-row" id="kpiRow" style="grid-template-columns:repeat(7,1fr);">
        <div class="glass kpi-card">
            <div class="kpi-val" id="kv-total" style="color:var(--hl);">--</div>
            <div class="kpi-lbl">Total Readers</div>
            <div class="kpi-sub" id="kv-total-sub">loading...</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-val" id="kv-online" style="color:#10B981;">--</div>
            <div class="kpi-lbl">Online</div>
            <div class="kpi-sub" id="kv-online-pct">--</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-val" id="kv-offline" style="color:#EF4444;">--</div>
            <div class="kpi-lbl">Offline</div>
            <div class="kpi-sub" id="kv-offline-pct">--</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-val" id="kv-antennas" style="color:#06B6D4;">--</div>
            <div class="kpi-lbl">Antennas</div>
            <div class="kpi-sub">total connected</div>
        </div>
        <div class="glass kpi-card" style="cursor:pointer;" onclick="document.getElementById('mismatchPanel').scrollIntoView({behavior:'smooth'})" title="Click to view mismatch details">
            <div class="kpi-val" id="kv-mismatch" style="color:#F59E0B;">--</div>
            <div class="kpi-lbl">Location Mismatches</div>
            <div class="kpi-sub" id="kv-mismatch-sub">observed &ne; assigned</div>
        </div>
        <div class="glass kpi-card" style="cursor:pointer;" onclick="document.getElementById('mismatchPanel').scrollIntoView({behavior:'smooth'})" title="Click to view dwell candidates">
            <div class="kpi-val" id="kv-dwell" style="color:#8B5CF6;">--</div>
            <div class="kpi-lbl">Dwell Candidates</div>
            <div class="kpi-sub" id="kv-dwell-sub">exceed threshold</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-val" id="kv-reassigned" style="color:#10B981;">--</div>
            <div class="kpi-lbl">Reassigned Today</div>
            <div class="kpi-sub">auto + manual</div>
        </div>
    </div>

    <div class="two-col">
        <!-- LEFT: Status Overview -->
        <div class="glass">
            <div class="panel-title">Reader Status Overview</div>
            <div class="status-bar" id="statusBar"></div>
            <div class="legend-grid" id="statusLegend">
                <div class="legend-chip">
                    <span class="legend-dot" style="background:#10B981;"></span>
                    <span class="legend-name">Online</span>
                    <span class="legend-pct" id="leg-online">--</span>
                    <span class="legend-pct-sub" id="leg-online-pct">--</span>
                </div>
                <div class="legend-chip">
                    <span class="legend-dot" style="background:#EF4444;"></span>
                    <span class="legend-name">Offline</span>
                    <span class="legend-pct" id="leg-offline">--</span>
                    <span class="legend-pct-sub" id="leg-offline-pct">--</span>
                </div>
            </div>

            <div style="margin-top:20px;">
                <div class="panel-title">Fixed Reader Tag Observations</div>
                <div class="stat-grid" id="tagStats">
                    <div class="stat-card"><div class="stat-val" id="ts-today">--</div><div class="stat-lbl">Today</div></div>
                    <div class="stat-card"><div class="stat-val" id="ts-week">--</div><div class="stat-lbl">This Week</div></div>
                    <div class="stat-card"><div class="stat-val" id="ts-month">--</div><div class="stat-lbl">This Month</div></div>
                    <div class="stat-card"><div class="stat-val" id="ts-quarter">--</div><div class="stat-lbl">3 Months</div></div>
                </div>

            </div>

            <div style="margin-top:20px;">
                <div class="panel-title">Inventory Reads by Device Type</div>
                <div class="status-bar" id="deviceBar"></div>
                <div class="legend-grid" id="deviceLegend">
                    <div class="legend-chip">
                        <span class="legend-dot" style="background:#10B981;"></span>
                        <span class="legend-name">Fixed Reader</span>
                        <span class="legend-pct" id="dev-fixed">--</span>
                        <span class="legend-pct-sub" id="dev-fixed-pct">--</span>
                    </div>
                    <div class="legend-chip">
                        <span class="legend-dot" style="background:#3B82F6;"></span>
                        <span class="legend-name">Mobile Reader</span>
                        <span class="legend-pct" id="dev-mobile">--</span>
                        <span class="legend-pct-sub" id="dev-mobile-pct">--</span>
                    </div>
                    <div class="legend-chip">
                        <span class="legend-dot" style="background:#F97316;"></span>
                        <span class="legend-name">Not Read</span>
                        <span class="legend-pct" id="dev-notread">--</span>
                        <span class="legend-pct-sub" id="dev-notread-pct">--</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- RIGHT: Top Observed Locations -->
        <div class="glass">
            <div class="panel-title">Top Observed Locations (30 Days)</div>
            <div class="tbl-wrap">
                <table class="dt" id="tblLocations">
                    <thead><tr>
                        <th>Location</th>
                        <th class="num">Assets Observed</th>
                    </tr></thead>
                    <tbody id="tblLocBody">
                        <tr><td colspan="2" class="loading"><span class="spinner"></span>Loading...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- LOCATION MISMATCH PANEL -->
    <div class="glass" id="mismatchPanel">
        <div class="intel-header">
            <div class="panel-title">&nearr; Location Mismatch &mdash; Observed &ne; Assigned</div>
            <div class="intel-actions">
                <button type="button" class="btn-sm btn-reassign" onclick="reassignAll()" id="btnReassignAll" style="display:none;" title="Reassign all assets that exceed the dwell time threshold">Reassign All Candidates</button>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--muted);border-color:var(--line);" onclick="toggleSettings()" id="btnSettings">Settings</button>
            </div>
        </div>

        <!-- SETTINGS (collapsible) -->
        <div class="collapsible" id="settingsPanel">
            <div style="background:var(--chip);border-radius:10px;padding:16px;margin-top:14px;border:1px solid var(--line);">
                <div style="font-size:12px;font-weight:600;color:var(--muted);margin-bottom:12px;">READER INTELLIGENCE SETTINGS</div>
                <div class="settings-grid">
                    <div class="setting-item">
                        <label>Dwell Time Threshold (hours)</label>
                        <input type="number" id="cfgDwellHours" min="1" max="720" value="24" />
                    </div>
                    <div class="setting-item">
                        <label>Departure Timeout (minutes)</label>
                        <input type="number" id="cfgDepartureMin" min="5" max="1440" value="60" />
                    </div>
                    <div class="setting-item">
                        <label>Recent Window (days)</label>
                        <input type="number" id="cfgRecentDays" min="1" max="365" value="7" title="Only show mismatches for assets observed within this many days. Older reads are ignored." />
                    </div>
                    <div class="setting-item">
                        <label>Auto-Reassign Location</label>
                        <div class="toggle-wrap">
                            <label class="toggle"><input type="checkbox" id="cfgAutoReassign" /><span class="toggle-slider"></span></label>
                            <span style="font-size:12px;color:var(--muted);" id="cfgAutoLabel">OFF</span>
                        </div>
                    </div>
                    <div class="setting-item">
                        <label>Email Report</label>
                        <div class="toggle-wrap">
                            <label class="toggle"><input type="checkbox" id="cfgEmailReport" /><span class="toggle-slider"></span></label>
                            <span style="font-size:12px;color:var(--muted);" id="cfgEmailLabel">OFF</span>
                        </div>
                    </div>
                    <div class="setting-item">
                        <label>Email Recipients</label>
                        <input type="text" id="cfgEmailRecipients" placeholder="email@example.com" />
                    </div>
                    <div class="setting-item">
                        <label>Show Mismatch Alerts</label>
                        <div class="toggle-wrap">
                            <label class="toggle"><input type="checkbox" id="cfgMismatchAlert" checked /><span class="toggle-slider"></span></label>
                            <span style="font-size:12px;color:var(--muted);">ON</span>
                        </div>
                    </div>
                    <div class="setting-item" style="grid-column:1/-1;">
                        <label>Reader Identities (comma-separated lastmodifiedby values)</label>
                        <input type="text" id="cfgReaderIdentities" placeholder="Web Server, ReaderIntelligence" style="width:100%;" title="These lastmodifiedby values identify assets updated by fixed readers. Used for the Activity Log and ENNX export." />
                    </div>
                </div>
                <div style="margin-top:14px;display:flex;gap:8px;align-items:center;">
                    <button type="button" class="btn-sm btn-save" onclick="saveSettings()">&#10003; Save Settings</button>
                    <span id="settingsSaved" style="font-size:12px;color:#10B981;display:none;">Settings saved!</span>
                </div>
            </div>
        </div>

        <!-- MISMATCH TABLE -->
        <div class="tbl-wrap" style="margin-top:14px;">
            <table class="dt" id="tblMismatch">
                <thead>
                    <tr>
                        <th>Asset Name</th>
                        <th>Observed Location</th>
                        <th>Assigned Location</th>
                        <th>Hours at Observed</th>
                        <th>Status</th>
                        <th>Site</th>
                        <th style="text-align:center;">Action</th>
                    </tr>
                    <tr class="filter-row">
                        <th><input class="fi" placeholder="filter..." oninput="filterMismatch(0,this.value)" /></th>
                        <th><input class="fi" placeholder="filter..." oninput="filterMismatch(1,this.value)" /></th>
                        <th><input class="fi" placeholder="filter..." oninput="filterMismatch(2,this.value)" /></th>
                        <th></th><th></th><th></th><th></th>
                    </tr>
                </thead>
                <tbody id="tblMismatchBody">
                    <tr><td colspan="7" class="loading"><span class="spinner"></span>Loading mismatch data...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- READER ACTIVITY PANEL -->
    <div class="glass" id="activityPanel">
        <div class="intel-header">
            <div class="panel-title">Fixed Reader Activity Log</div>
            <div class="intel-actions">
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:4px;">
                    Last <input type="number" id="activityDays" min="1" max="365" value="30" style="width:50px;background:var(--chip);color:var(--text);border:1px solid var(--line);padding:4px 6px;border-radius:4px;font-size:12px;text-align:center;" onchange="loadReaderActivity()" /> days
                </label>
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:6px;cursor:pointer;" title="Show assets from ALL sites, not just the selected site">
                    <input type="checkbox" id="chkAllSites" onchange="loadReaderActivity()" style="cursor:pointer;" /> All Sites
                </label>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="previewEnnx()" id="btnPreviewEnnx">Preview ENNX</button>
                <button type="button" class="btn-sm btn-save" onclick="exportEnnx()" id="btnExportEnnx">Export ENNX</button>
            </div>
        </div>
        <div style="font-size:12px;color:var(--muted);margin:10px 0 6px 0;" id="activityInfo">
            Showing assets where <strong>lastmodifiedby</strong> matches configured reader identities.
        </div>
        <div class="tbl-wrap">
            <table class="dt" id="tblActivity">
                <thead>
                    <tr>
                        <th>Asset Name</th>
                        <th>Observed Location</th>
                        <th>Assigned Location</th>
                        <th>Last Observed</th>
                        <th>Modified By</th>
                        <th>CMR</th>
                        <th>Status</th>
                        <th>Site</th>
                    </tr>
                </thead>
                <tbody id="tblActivityBody">
                    <tr><td colspan="8" class="loading"><span class="spinner"></span>Loading...</td></tr>
                </tbody>
            </table>
        </div>
        <div class="collapsible" id="ennxPreviewPanel">
            <div style="margin-top:14px;background:var(--chip);border:1px solid var(--line);border-radius:8px;padding:14px;">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                    <span style="font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;">ENNX Preview</span>
                    <span id="ennxLineCount" style="font-size:11px;color:var(--muted);"></span>
                </div>
                <textarea id="ennxPreviewText" readonly style="width:100%;height:300px;background:var(--bg);color:var(--text);border:1px solid var(--line);border-radius:6px;padding:10px;font-family:'Consolas','Courier New',monospace;font-size:12px;resize:vertical;white-space:pre;"></textarea>
            </div>
        </div>
    </div>

    <!-- LOCATION HISTORY / MOVEMENT REPORT -->
    <div class="glass" id="historyPanel">
        <div class="intel-header">
            <div class="panel-title">Location History -- Movement Report</div>
            <div class="intel-actions">
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:4px;">
                    Last <input type="number" id="histDays" min="1" max="365" value="90" style="width:50px;background:var(--chip);color:var(--text);border:1px solid var(--line);padding:4px 6px;border-radius:4px;font-size:12px;text-align:center;" onchange="loadLocationHistory()" /> days
                </label>
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:4px;">
                    <input type="checkbox" id="histAllSites" onchange="loadLocationHistory()" /> All Sites
                </label>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="exportLocationHistoryCsv()">Export CSV</button>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="loadLocationHistory()">Refresh</button>
            </div>
        </div>
        <div style="font-size:12px;color:var(--muted);margin:10px 0 6px 0;" id="histInfo">
            Loading movement data...
        </div>
        <div style="display:flex;gap:8px;margin-bottom:8px;">
            <input type="text" id="histFilterAsset" class="fi" placeholder="filter asset..." oninput="filterHistory()" style="width:160px;" />
            <input type="text" id="histFilterLoc" class="fi" placeholder="filter location..." oninput="filterHistory()" style="width:160px;" />
        </div>
        <div class="tbl-wrap">
            <table class="dt" id="tblHistory">
                <thead>
                    <tr>
                        <th>Asset</th>
                        <th>Location</th>
                        <th>Arrival</th>
                        <th>Departure</th>
                        <th>Dwell Time</th>
                        <th>Status</th>
                        <th>Site</th>
                    </tr>
                </thead>
                <tbody id="tblHistoryBody">
                    <tr><td colspan="7" class="loading"><span class="spinner"></span>Loading location history...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- FIXED READER EVENT LOG (collapsible) -->
    <div class="glass" id="eventLogPanel">
        <div class="intel-header" style="cursor:pointer;" onclick="toggleEventLog()">
            <div class="panel-title" style="display:flex;align-items:center;gap:8px;">
                <span id="eventLogChevron" style="display:inline-block;transition:transform .2s;transform:rotate(0deg);font-size:10px;">&#9654;</span>
                Fixed Reader Event Log
                <span id="eventLogCount" style="background:var(--chip);color:var(--muted);padding:2px 8px;border-radius:10px;font-size:11px;font-weight:500;display:none;"></span>
            </div>
            <div class="intel-actions" onclick="event.stopPropagation();">
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:4px;">
                    Last <input type="number" id="eventDays" min="1" max="365" value="30" style="width:50px;background:var(--chip);color:var(--text);border:1px solid var(--line);padding:4px 6px;border-radius:4px;font-size:12px;text-align:center;" onchange="loadReaderEvents()" /> days
                </label>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="exportEventsCsv()">Export CSV</button>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="loadReaderEvents()">Refresh</button>
            </div>
        </div>
        <div id="eventLogBody" style="overflow:hidden;max-height:0;opacity:0;transition:max-height .4s ease, opacity .3s ease;">
            <div style="font-size:12px;color:var(--muted);margin:10px 0 6px 0;" id="eventInfo">
                Tag read events from fixed readers only. Click header to expand/collapse.
            </div>
            <div id="eventFilterInfo" style="font-size:11px;color:var(--muted);margin:0 0 8px 0;display:none;"></div>
            <div class="tbl-wrap" style="max-height:600px;overflow-y:auto;">
                <table class="dt" id="tblEvents">
                    <thead>
                        <tr>
                            <th>Time</th>
                            <th>RFID Tag</th>
                            <th>Decoded Name</th>
                            <th>Event Type</th>
                            <th>Details</th>
                            <th>Tag Site</th>
                        </tr>
                        <tr id="eventFilterRow" style="background:var(--bg);">
                            <td style="padding:4px;"><input type="text" class="fi evtFilter" data-col="0" placeholder="filter..." oninput="filterEvents()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi evtFilter" data-col="1" placeholder="filter..." oninput="filterEvents()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi evtFilter" data-col="2" placeholder="filter..." oninput="filterEvents()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi evtFilter" data-col="3" placeholder="filter..." oninput="filterEvents()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi evtFilter" data-col="4" placeholder="filter..." oninput="filterEvents()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi evtFilter" data-col="5" placeholder="filter..." oninput="filterEvents()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                        </tr>
                    </thead>
                    <tbody id="tblEventsBody">
                        <tr><td colspan="6" class="loading"><span class="spinner"></span>Loading events...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- MISSING ASSET REPORT -->
    <div class="glass" id="missingPanel">
        <div class="intel-header" style="cursor:pointer;" onclick="toggleMissing()">
            <div class="panel-title" style="display:flex;align-items:center;gap:8px;">
                <span id="missingChevron" style="display:inline-block;transition:transform .2s;transform:rotate(0deg);font-size:10px;">&#9654;</span>
                Missing Asset Report
                <span id="missingCount" style="background:color-mix(in srgb, #ef4444 15%, transparent);color:#ef4444;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600;display:none;"></span>
            </div>
            <div class="intel-actions" onclick="event.stopPropagation();">
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:4px;">
                    Not seen in
                    <select id="missingDays" style="background:var(--chip);color:var(--text);border:1px solid var(--line);padding:4px 6px;border-radius:4px;font-size:12px;" onchange="loadMissingAssets()">
                        <option value="30">30 days</option>
                        <option value="60">60 days</option>
                        <option value="90" selected>90 days</option>
                        <option value="180">180 days</option>
                        <option value="365">1 year</option>
                    </select>
                </label>
                <label style="font-size:11px;color:var(--muted);display:flex;align-items:center;gap:4px;">
                    <input type="checkbox" id="missingAllSites" onchange="loadMissingAssets()" /> All Sites
                </label>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="exportMissingCsv()">Export CSV</button>
                <button type="button" class="btn-sm" style="background:var(--chip);color:var(--text);border-color:var(--line);" onclick="loadMissingAssets()">Refresh</button>
            </div>
        </div>
        <div id="missingBody" style="overflow:hidden;max-height:0;opacity:0;transition:max-height .4s ease, opacity .3s ease;">
            <!-- Coverage KPIs -->
            <div id="missingStats" style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin:12px 0;">
                <div class="kpi-card" style="text-align:center;padding:12px;">
                    <div id="msTotalAssets" style="font-size:22px;font-weight:700;color:var(--accent);">�</div>
                    <div style="font-size:11px;color:var(--muted);">Total Assets</div>
                </div>
                <div class="kpi-card" style="text-align:center;padding:12px;">
                    <div id="msObserved" style="font-size:22px;font-weight:700;color:#10b981;">�</div>
                    <div style="font-size:11px;color:var(--muted);">Observed (Covered)</div>
                </div>
                <div class="kpi-card" style="text-align:center;padding:12px;">
                    <div id="msMissing" style="font-size:22px;font-weight:700;color:#ef4444;">�</div>
                    <div style="font-size:11px;color:var(--muted);">Missing (Not Seen)</div>
                </div>
                <div class="kpi-card" style="text-align:center;padding:12px;">
                    <div id="msCoverage" style="font-size:22px;font-weight:700;color:#8B5CF6;">�</div>
                    <div style="font-size:11px;color:var(--muted);">Reader Coverage</div>
                </div>
            </div>
            <div style="font-size:12px;color:var(--muted);margin:10px 0 6px 0;" id="missingInfo">
                Assets not observed by any fixed reader within the selected time window. Expand to view.
            </div>
            <div class="tbl-wrap" style="max-height:600px;overflow-y:auto;">
                <table class="dt" id="tblMissing">
                    <thead>
                        <tr>
                            <th>Asset Name</th>
                            <th>Description</th>
                            <th>CMR</th>
                            <th>Assigned Location</th>
                            <th>Last Observed</th>
                            <th>Days Since</th>
                            <th>Site</th>
                        </tr>
                        <tr id="missingFilterRow" style="background:var(--bg);">
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="0" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="1" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="2" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="3" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="4" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="5" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                            <td style="padding:4px;"><input type="text" class="fi missingFilter" data-col="6" placeholder="filter..." oninput="filterMissing()" style="width:100%;font-size:11px;padding:4px 6px;" /></td>
                        </tr>
                    </thead>
                    <tbody id="tblMissingBody">
                        <tr><td colspan="7" class="loading"><span class="spinner"></span>Click header to load...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>


    <!-- READER TABLE -->
    <div class="glass">
        <div class="panel-title">Reader Inventory</div>
        <div class="tbl-wrap">
            <table class="dt" id="tblReaders">
                <thead>
                    <tr>
                        <th onclick="sortTbl(this,0)">Reader Name</th>
                        <th onclick="sortTbl(this,1)">Location</th>
                        <th onclick="sortTbl(this,2)">IP Address</th>
                        <th onclick="sortTbl(this,3)">Status</th>
                        <th onclick="sortTbl(this,4)">Model</th>
                        <th onclick="sortTbl(this,5)">Last Seen</th>
                        <th onclick="sortTbl(this,6)">Batch</th>
                        <th onclick="sortTbl(this,7)">Update Loc</th>
                    </tr>
                    <tr class="filter-row">
                        <th><input class="fi" placeholder="filter..." oninput="filterTbl(0,this.value)" /></th>
                        <th><input class="fi" placeholder="filter..." oninput="filterTbl(1,this.value)" /></th>
                        <th><input class="fi" placeholder="filter..." oninput="filterTbl(2,this.value)" /></th>
                        <th></th><th></th><th></th><th></th><th></th>
                    </tr>
                </thead>
                <tbody id="tblReaderBody">
                    <tr><td colspan="8" class="loading"><span class="spinner"></span>Loading reader data from iDash API...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

</div>
</form>

<!-- ASSET DETAIL PANEL -->
<div class="detail-panel" id="detailPanel">
    <div class="dp-header">
        <h2><span class="dp-icon">i</span> <span id="dpTitle">Asset Detail</span></h2>
        <button type="button" class="dp-close" onclick="closeDetail()">&times;</button>
    </div>
    <div class="dp-actions">
        <a id="dpMasterLink" href="#" class="dp-action-btn" title="Open full detail in Asset Master">Open in Asset Master</a>
    </div>
    <div class="dp-body" id="dpBody">
        <div class="dp-loading">Select an asset to view details</div>
    </div>
</div>

<div class="toast" id="toast"></div>
<script>
var fmt = new Intl.NumberFormat('en-US');
var readerData = [];
var mismatchData = [];
var intelConfig = {};

function loadAll() {
    loadReaders();
    loadTagStats();
    loadIntelligence();
    loadReaderActivity();
    // loadReaderEvents() � deferred until user expands the panel
    loadLocationHistory();
}

// -- Theme toggle ---------------------------------------------
function toggleTheme() {
    var html = document.documentElement;
    var isDark = html.getAttribute('data-theme') !== 'light';
    var next = isDark ? 'light' : 'dark';
    if (next === 'dark') {
        html.removeAttribute('data-theme');
    } else {
        html.setAttribute('data-theme', next);
    }
    localStorage.setItem('idash_theme', next === 'dark' ? '' : 'light');
    updateThemeBtn();
}

function updateThemeBtn() {
    var btn = document.getElementById('themeToggleBtn');
    if (!btn) return;
    var isLight = document.documentElement.getAttribute('data-theme') === 'light';
    btn.textContent = isLight ? '??' : '??';
    btn.title = isLight ? 'Switch to dark mode' : 'Switch to light mode';
}

// Init button icon on load
(function() { updateThemeBtn(); })();

// ── Animated KPI counter ──────────────────────────────────────
function animVal(id, target, ms) {
    var el = document.getElementById(id);
    if (!el) return;
    if (target === 0) { el.textContent = '0'; return; }
    var start = 0, startTime = null;
    function step(ts) {
        if (!startTime) startTime = ts;
        var progress = Math.min((ts - startTime) / ms, 1);
        var eased = 1 - Math.pow(1 - progress, 3);
        el.textContent = fmt.format(Math.round(start + (target - start) * eased));
        if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
}

// ── READER DATA (from iDash API via proxy) ────────────────
function loadReaders() {
    document.getElementById('tblReaderBody').innerHTML = '<tr><td colspan="8" class="loading"><span class="spinner"></span>Loading reader data from iDash API...</td></tr>';

    fetch('va_fixed_reader.aspx?api=readers&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            if (d.error) {
                document.getElementById('tblReaderBody').innerHTML = '<tr><td colspan="8" class="err-msg">' + esc(d.error) + '</td></tr>';
                return;
            }

            var s = d.summary;
            readerData = d.readers || [];

            // KPIs
            animVal('kv-total', s.totalReaders, 800);
            animVal('kv-online', s.online, 800);
            animVal('kv-offline', s.offline, 800);
            animVal('kv-antennas', s.totalAntennas, 800);

            document.getElementById('kv-total-sub').textContent = s.totalAntennas + ' antennas';
            document.getElementById('kv-online-pct').textContent = s.pctOnline + '% of readers';
            document.getElementById('kv-offline-pct').textContent = s.pctOffline + '% of readers';

            // Status bar
            var barHtml = '';
            if (s.pctOnline > 0)
                barHtml += '<div class="status-seg" style="width:' + s.pctOnline + '%;background:#10B981;" title="Online: ' + s.online + '">' + (s.pctOnline > 5 ? s.online + ' Online' : '') + '</div>';
            if (s.pctOffline > 0)
                barHtml += '<div class="status-seg" style="width:' + s.pctOffline + '%;background:#EF4444;" title="Offline: ' + s.offline + '">' + (s.pctOffline > 5 ? s.offline + ' Offline' : '') + '</div>';
            document.getElementById('statusBar').innerHTML = barHtml;

            // Legend
            document.getElementById('leg-online').textContent = fmt.format(s.online);
            document.getElementById('leg-online-pct').textContent = s.pctOnline + '%';
            document.getElementById('leg-offline').textContent = fmt.format(s.offline);
            document.getElementById('leg-offline-pct').textContent = s.pctOffline + '%';

            // Reader table
            renderReaderTable(readerData);
        })
        .catch(function(err) {
            console.error('Reader fetch error:', err);
            document.getElementById('tblReaderBody').innerHTML = '<tr><td colspan="8" class="err-msg">Failed to fetch reader data. Check API configuration in Site Config.</td></tr>';
        });
}

function renderReaderTable(readers) {
    var tbody = document.getElementById('tblReaderBody');
    if (!readers || !readers.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="loading">No readers found.</td></tr>';
        return;
    }
    var html = '';
    readers.forEach(function(r) {
        var isUp = r.status === 'Up';
        var statusBadge = isUp
            ? '<span class="dot-up"></span><span class="badge b-green">Online</span>'
            : '<span class="dot-down"></span><span class="badge b-red">Offline</span>';
        var lastSeen = r.lastSeen ? formatDate(r.lastSeen) : '--';
        html += '<tr>' +
            '<td><strong>' + esc(r.name) + '</strong></td>' +
            '<td>' + esc(r.locationName) + '</td>' +
            '<td style="font-family:monospace;font-size:12px;">' + esc(r.ipAddress) + '</td>' +
            '<td>' + statusBadge + '</td>' +
            '<td>' + esc(r.readerModel) + '</td>' +
            '<td style="font-size:12px;">' + lastSeen + '</td>' +
            '<td class="num">' + (r.batchMode ? '&#10003;' : '') + '</td>' +
            '<td class="num">' + (r.updateLocation ? '&#10003;' : '') + '</td>' +
            '</tr>';
    });
    tbody.innerHTML = html;
}

// ── TAG READ STATS (from SQL via proxy) ───────────────────────
function loadTagStats() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var readerSiteId = document.getElementById('<%= DdlReaderSite.ClientID %>').value;
    fetch('va_fixed_reader.aspx?api=readerstats&companyid=' + siteId + '&readersite=' + readerSiteId + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            if (d.error) return;

            var tr = d.tagReads || {};
            animVal('ts-today', tr.today || 0, 700);
            animVal('ts-week', tr.week || 0, 700);
            animVal('ts-month', tr.month || 0, 700);
            animVal('ts-quarter', tr.quarter || 0, 700);


            // Top locations — rows are clickable links to Asset Master
            var locBody = document.getElementById('tblLocBody');
            var locs = d.topLocations || [];
            if (!locs.length) {
                locBody.innerHTML = '<tr><td colspan="2" class="loading">No observed locations found.</td></tr>';
            } else {
            var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value || '0';
            var locHtml = '';
            locs.forEach(function(loc) {
                // Always use site=0 (All Sites) — reader locations can contain tags from any site
                var href = 'va_asset_master.aspx?loc=' + encodeURIComponent(loc.label) + '&site=0';
                locHtml += '<tr class="row-link" onclick="location.href=\'' + href + '\'" title="View assets at ' + esc(loc.label) + ' in Asset Master">' +
                    '<td>' + esc(loc.label) + '</td>' +
                    '<td class="num"><span class="badge b-cyan">' + fmt.format(loc.count) + '</span></td>' +
                    '</tr>';
            });
            locBody.innerHTML = locHtml;
            }

            // Device type breakdown
            var dr = d.deviceReads || {};
            var devBarHtml = '';
            if (dr.pctFixed > 0)
                devBarHtml += '<div class="status-seg" style="width:' + dr.pctFixed + '%;background:#10B981;" title="Fixed: ' + dr.fixed + '">' + (dr.pctFixed > 5 ? fmt.format(dr.fixed) : '') + '</div>';
            if (dr.pctMobile > 0)
                devBarHtml += '<div class="status-seg" style="width:' + dr.pctMobile + '%;background:#3B82F6;" title="Mobile: ' + dr.mobile + '">' + (dr.pctMobile > 5 ? fmt.format(dr.mobile) : '') + '</div>';
            if (dr.pctNotRead > 0)
                devBarHtml += '<div class="status-seg" style="width:' + dr.pctNotRead + '%;background:#F97316;" title="Not Read: ' + dr.notRead + '">' + (dr.pctNotRead > 5 ? fmt.format(dr.notRead) : '') + '</div>';
            document.getElementById('deviceBar').innerHTML = devBarHtml;

            document.getElementById('dev-fixed').textContent = fmt.format(dr.fixed || 0);
            document.getElementById('dev-fixed-pct').textContent = (dr.pctFixed || 0) + '%';
            document.getElementById('dev-mobile').textContent = fmt.format(dr.mobile || 0);
            document.getElementById('dev-mobile-pct').textContent = (dr.pctMobile || 0) + '%';
            document.getElementById('dev-notread').textContent = fmt.format(dr.notRead || 0);
            document.getElementById('dev-notread-pct').textContent = (dr.pctNotRead || 0) + '%';
        })
        .catch(function(err) { console.error('Tag stats error:', err); });
}

// ── TABLE SORT/FILTER ─────────────────────────────────────────
var sortDir = {};
function sortTbl(th, colIdx) {
    var key = 'col' + colIdx;
    sortDir[key] = !(sortDir[key]);
    var asc = sortDir[key];
    readerData.sort(function(a, b) {
        var fields = ['name', 'locationName', 'ipAddress', 'status', 'readerModel', 'lastSeen', 'batchMode', 'updateLocation'];
        var va = a[fields[colIdx]] || '', vb = b[fields[colIdx]] || '';
        if (typeof va === 'string') return asc ? va.localeCompare(vb) : vb.localeCompare(va);
        return asc ? va - vb : vb - va;
    });
    renderReaderTable(readerData);
}

function filterTbl(colIdx, val) {
    var fields = ['name', 'locationName', 'ipAddress'];
    if (colIdx >= fields.length) return;
    var field = fields[colIdx];
    var needle = val.toLowerCase();
    var filtered = readerData.filter(function(r) {
        return (r[field] || '').toLowerCase().indexOf(needle) >= 0;
    });
    renderReaderTable(filtered);
}

// ── HELPERS ───────────────────────────────────────────────────
function esc(s) { if (!s) return ''; var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

function formatDate(s) {
    try {
        var d = new Date(s);
        if (isNaN(d)) return s;
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) + ' ' +
               d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    } catch(e) { return s; }
}

// ── INTELLIGENCE PANEL ────────────────────────────────────────
function loadIntelligence() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var readerSiteId = document.getElementById('<%= DdlReaderSite.ClientID %>').value;

    // Load config
    fetch('va_fixed_reader.aspx?api=intel_config&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(cfg) {
            intelConfig = cfg;
            document.getElementById('cfgDwellHours').value = cfg.dwellTimeHours || 24;
            document.getElementById('cfgDepartureMin').value = cfg.departureTimeoutMinutes || 60;
            document.getElementById('cfgRecentDays').value = cfg.recentWindowDays || 7;
            document.getElementById('cfgAutoReassign').checked = !!cfg.autoReassignLocation;
            document.getElementById('cfgAutoLabel').textContent = cfg.autoReassignLocation ? 'ON' : 'OFF';
            document.getElementById('cfgEmailReport').checked = !!cfg.emailReport;
            document.getElementById('cfgEmailLabel').textContent = cfg.emailReport ? 'ON' : 'OFF';
            document.getElementById('cfgEmailRecipients').value = cfg.emailRecipients || '';
            document.getElementById('cfgMismatchAlert').checked = cfg.observationMismatchAlert !== false;
            var ids = cfg.readerIdentities || ['Web Server','ReaderIntelligence'];
            document.getElementById('cfgReaderIdentities').value = ids.join(', ');
        })
        .catch(function(e) { console.error('Config load error:', e); });

    // Load mismatch data + stats
    fetch('va_fixed_reader.aspx?api=intel_mismatches&companyid=' + siteId + '&readersite=' + readerSiteId + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            mismatchData = d.mismatches || [];
            var stats = d.stats || {};

            // KPIs
            animVal('kv-mismatch', stats.MismatchCount || 0, 700);
            animVal('kv-dwell', stats.DwellCandidates || 0, 700);
            animVal('kv-reassigned', stats.ReassignedToday || 0, 700);
            document.getElementById('kv-dwell-sub').textContent = '>' + (stats.DwellThresholdHours || 24) + 'h threshold';

            // Show reassign-all button if there are candidates
            document.getElementById('btnReassignAll').style.display = stats.DwellCandidates > 0 ? '' : 'none';

            renderMismatchTable(mismatchData);
        })
        .catch(function(e) { console.error('Intel load error:', e); });
}

function renderMismatchTable(data) {
    var tbody = document.getElementById('tblMismatchBody');
    if (!data || !data.length) {
        tbody.innerHTML = '<tr><td colspan="7" class="loading" style="color:#10B981;">&#10003; No location mismatches &mdash; all observed assets match their assigned locations.</td></tr>';
        return;
    }
    var html = '';
    data.forEach(function(m) {
        var statusBadge = m.ExceedsThreshold
            ? '<span class="mismatch-badge mb-ready">Ready to Reassign</span>'
            : '<span class="mismatch-badge mb-warn">Dwelling (' + m.HoursAtLocation + 'h)</span>';
        var actionBtn = m.ExceedsThreshold
            ? '<button class="btn-sm btn-reassign" onclick="event.stopPropagation();reassignOne(' + m.AssetId + ',this)">Reassign</button>'
            : '<span style="font-size:11px;color:var(--muted);">Below threshold</span>';
        html += '<tr>' +
            '<td><strong><a class="asset-link" onclick="openAssetDetail(' + m.AssetId + ',\'' + esc(m.AssetName).replace(/'/g, "\\'") + '\')"> ' + esc(m.AssetName) + '</a></strong></td>' +
            '<td><span class="badge b-cyan">' + esc(m.ObservedLocation) + '</span></td>' +
            '<td>' + esc(m.AssignedLocation) + '</td>' +
            '<td class="num">' + fmt.format(m.HoursAtLocation) + 'h</td>' +
            '<td>' + statusBadge + '</td>' +
            '<td style="font-size:12px;">' + esc(m.CompanyName) + '</td>' +
            '<td style="text-align:center;">' + actionBtn + '</td>' +
            '</tr>';
    });
    tbody.innerHTML = html;
}

function reassignOne(assetId, btn) {
    if (!confirm('Reassign this asset\'s location to its observed location?')) return;
    btn.disabled = true;
    btn.textContent = '...';
    fetch('va_fixed_reader.aspx?api=intel_reassign&assetid=' + assetId + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            if (d.success) {
                showToast('Reassigned: ' + d.assetName + ' -> ' + d.newLocation);
                loadIntelligence();
            } else {
                alert('Reassignment failed: ' + (d.error || 'Unknown error'));
                btn.disabled = false;
                btn.textContent = 'Reassign';
            }
        })
        .catch(function(e) { alert('Error: ' + e.message); btn.disabled = false; btn.textContent = 'Reassign'; });
}

function reassignAll() {
    var count = mismatchData.filter(function(m) { return m.ExceedsThreshold; }).length;
    if (!confirm('Reassign ' + count + ' asset(s) to their observed locations?')) return;
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var readerSiteId = document.getElementById('<%= DdlReaderSite.ClientID %>').value;
    fetch('va_fixed_reader.aspx?api=intel_reassign_all&companyid=' + siteId + '&readersite=' + readerSiteId + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            showToast('Reassigned ' + d.successCount + ' of ' + d.totalCount + ' assets');
            loadIntelligence();
        })
        .catch(function(e) { alert('Error: ' + e.message); });
}

function toggleSettings() {
    var panel = document.getElementById('settingsPanel');
    panel.classList.toggle('open');
}

function saveSettings() {
    var cfg = {
        dwellTimeHours: parseInt(document.getElementById('cfgDwellHours').value) || 24,
        departureTimeoutMinutes: parseInt(document.getElementById('cfgDepartureMin').value) || 60,
        recentWindowDays: parseInt(document.getElementById('cfgRecentDays').value) || 7,
        autoReassignLocation: document.getElementById('cfgAutoReassign').checked,
        emailReport: document.getElementById('cfgEmailReport').checked,
        emailRecipients: document.getElementById('cfgEmailRecipients').value,
        observationMismatchAlert: document.getElementById('cfgMismatchAlert').checked,
        readerIdentities: document.getElementById('cfgReaderIdentities').value.split(',').map(function(s){return s.trim();}).filter(function(s){return s.length > 0;})
    };
    fetch('va_fixed_reader.aspx?api=intel_save_config', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(cfg)
    })
    .then(function(r) { return r.json(); })
    .then(function(d) {
        if (d.success) {
            showToast('Settings saved');
            document.getElementById('cfgAutoLabel').textContent = cfg.autoReassignLocation ? 'ON' : 'OFF';
            document.getElementById('cfgEmailLabel').textContent = cfg.emailReport ? 'ON' : 'OFF';
            loadIntelligence();
            loadReaderActivity();
        } else {
            alert('Save failed: ' + (d.error || 'Unknown'));
        }
    })
    .catch(function(e) { alert('Error: ' + e.message); });
}

function filterMismatch(colIdx, val) {
    var fields = ['AssetName', 'ObservedLocation', 'AssignedLocation'];
    if (colIdx >= fields.length) return;
    var field = fields[colIdx];
    var needle = val.toLowerCase();
    var filtered = mismatchData.filter(function(m) {
        return (m[field] || '').toLowerCase().indexOf(needle) >= 0;
    });
    renderMismatchTable(filtered);
}

function showToast(msg) {
    var t = document.getElementById('toast');
    t.textContent = msg;
    t.classList.add('show');
    setTimeout(function() { t.classList.remove('show'); }, 3000);
}

// -- Location History / Movement Report ----------------------------------
var historyData = [];

function loadLocationHistory() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var days = parseInt(document.getElementById('histDays').value) || 90;
    var allSites = document.getElementById('histAllSites').checked ? '1' : '0';
    fetch('va_fixed_reader.aspx?api=location_history&companyid=' + siteId + '&days=' + days + '&allsites=' + allSites + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            historyData = d.movements || [];
            document.getElementById('histInfo').innerHTML = '<b>' + d.total + '</b> location movements in the last <b>' + days + '</b> days.';
            filterHistory();
        })
        .catch(function(err) {
            document.getElementById('histInfo').textContent = 'Failed to load: ' + err;
        });
}

function filterHistory() {
    var fa = (document.getElementById('histFilterAsset').value || '').toLowerCase();
    var fl = (document.getElementById('histFilterLoc').value || '').toLowerCase();
    var filtered = historyData.filter(function(m) {
        if (fa && (m.AssetName || '').toLowerCase().indexOf(fa) < 0) return false;
        if (fl && (m.Location || '').toLowerCase().indexOf(fl) < 0) return false;
        return true;
    });
    renderHistoryTable(filtered);
}

function renderHistoryTable(data) {
    var tbody = document.getElementById('tblHistoryBody');
    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="loading" style="color:var(--muted);">No location history records found.</td></tr>';
        return;
    }
    var html = '';
    data.forEach(function(m) {
        var statusBadge = m.StillHere
            ? '<span style="display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:rgba(16,185,129,.15);color:#10B981;border:1px solid #10B981;">Current</span>'
            : '<span style="display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:rgba(107,114,128,.12);color:var(--muted);border:1px solid var(--line);">Departed</span>';
        html += '<tr style="cursor:pointer;" onclick="showAssetHistory(' + m.AssetId + ', \'' + esc(m.AssetName).replace(/'/g,"\\'") + '\')">' +
            '<td style="font-weight:500;">' + esc(m.AssetName) + '</td>' +
            '<td>' + esc(m.Location) + '</td>' +
            '<td style="font-size:12px;">' + esc(m.Arrival) + '</td>' +
            '<td style="font-size:12px;">' + (m.Departure ? esc(m.Departure) : '--') + '</td>' +
            '<td style="font-weight:600;">' + esc(m.DwellDisplay) + '</td>' +
            '<td>' + statusBadge + '</td>' +
            '<td>' + esc(m.Site) + '</td>' +
            '</tr>';
    });
    tbody.innerHTML = html;
}

function showAssetHistory(assetId, assetName) {
    // Load per-asset history into the detail panel
    document.getElementById('dpTitle').textContent = assetName + ' - Location History';
    document.getElementById('dpBody').innerHTML = '<div style="text-align:center;padding:30px;"><span class="spinner"></span> Loading history...</div>';
    document.getElementById('detailPanel').classList.add('open');
    _dpCurrentId = assetId;

    fetch('va_fixed_reader.aspx?api=asset_history&assetid=' + assetId + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            var hist = d.history || [];
            var h = '<div style="padding:16px;">';
            h += '<div style="font-size:13px;color:var(--muted);margin-bottom:12px;">' + hist.length + ' location record(s) for <b>' + esc(assetName) + '</b></div>';

            if (hist.length === 0) {
                h += '<div style="text-align:center;padding:30px;color:var(--muted);">No location history found.</div>';
            } else {
                // Timeline visualization
                h += '<div style="position:relative;padding-left:24px;">';
                hist.forEach(function(entry, idx) {
                    var isCurrent = entry.StillHere;
                    var dotColor = isCurrent ? '#10B981' : 'var(--muted)';
                    var lineStyle = idx < hist.length - 1 ? 'border-left:2px solid var(--line);' : '';
                    h += '<div style="position:relative;padding-bottom:20px;margin-left:0;' + lineStyle + 'padding-left:20px;">';
                    h += '<div style="position:absolute;left:-6px;top:4px;width:12px;height:12px;border-radius:50%;background:' + dotColor + ';border:2px solid var(--card);"></div>';
                    h += '<div style="font-weight:600;font-size:14px;">' + esc(entry.Location) + '</div>';
                    h += '<div style="font-size:12px;color:var(--muted);margin-top:2px;">Arrived: ' + esc(entry.Arrival) + '</div>';
                    if (entry.Departure) {
                        h += '<div style="font-size:12px;color:var(--muted);">Departed: ' + esc(entry.Departure) + '</div>';
                    }
                    h += '<div style="font-size:12px;margin-top:2px;">';
                    if (isCurrent) {
                        h += '<span style="color:#10B981;font-weight:600;">Currently here</span> - ';
                    }
                    h += 'Dwell: <b>' + esc(entry.DwellDisplay) + '</b></div>';
                    h += '<div style="font-size:11px;color:var(--muted);">' + esc(entry.Site) + '</div>';
                    h += '</div>';
                });
                h += '</div>';
            }
            h += '</div>';
            document.getElementById('dpBody').innerHTML = h;
        })
        .catch(function(err) {
            document.getElementById('dpBody').innerHTML = '<div style="padding:20px;color:#EF4444;">Failed to load: ' + err + '</div>';
        });
}

function exportLocationHistoryCsv() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var days = parseInt(document.getElementById('histDays').value) || 90;
    var allSites = document.getElementById('histAllSites').checked ? '1' : '0';
    window.location.href = 'va_fixed_reader.aspx?api=location_history_csv&companyid=' + siteId + '&days=' + days + '&allsites=' + allSites;
}

// -- Reader Activity Log --------------------------------------
var activityData = [];

function loadReaderActivity() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var days = parseInt(document.getElementById('activityDays').value) || 30;
    var allSites = document.getElementById('chkAllSites').checked ? '1' : '0';
    var tbody = document.getElementById('tblActivityBody');
    tbody.innerHTML = '<tr><td colspan="8" class="loading"><span class="spinner"></span>Loading activity...</td></tr>';

    fetch('va_fixed_reader.aspx?api=reader_activity&companyid=' + siteId + '&days=' + days + '&allsites=' + allSites + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            activityData = d.assets || [];
            var info = document.getElementById('activityInfo');
            info.innerHTML = '<strong>' + activityData.length + '</strong> assets modified by ' +
                (d.identities || []).map(function(s){ return '"' + s + '"'; }).join(', ') +
                ' in the last <strong>' + days + '</strong> days.';
            renderActivityTable(activityData);
        })
        .catch(function(e) {
            tbody.innerHTML = '<tr><td colspan="8" class="err-msg">Error: ' + e.message + '</td></tr>';
        });
}

function renderActivityTable(data) {
    var tbody = document.getElementById('tblActivityBody');
    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="loading" style="color:var(--muted);">No fixed reader activity found in this period.</td></tr>';
        return;
    }
    var html = '';
    data.forEach(function(a) {
        var locMatch = a.ObservedLocation === a.AssignedLocation;
        var locBadge = locMatch
            ? '<span class="badge b-green">' + esc(a.ObservedLocation) + '</span>'
            : '<span class="badge b-amber">' + esc(a.ObservedLocation) + '</span>';
        html += '<tr class="row-link" onclick="openDetail(' + a.AssetId + ')">' +
            '<td class="asset-link">' + esc(a.AssetName) + '</td>' +
            '<td>' + locBadge + '</td>' +
            '<td>' + esc(a.AssignedLocation) + '</td>' +
            '<td>' + esc(a.LastObserved) + '</td>' +
            '<td>' + esc(a.ModifiedBy) + '</td>' +
            '<td>' + esc(a.CMR) + '</td>' +
            '<td>' + esc(a.Status) + '</td>' +
            '<td>' + esc(a.SiteName) + '</td>' +
            '</tr>';
    });
    tbody.innerHTML = html;
}

function exportEnnx() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var days = parseInt(document.getElementById('activityDays').value) || 30;
    window.location.href = 'va_fixed_reader.aspx?api=reader_ennx&companyid=' + siteId + '&days=' + days;
}

function previewEnnx() {
    var siteId = document.getElementById('<%= DdlCompany.ClientID %>').value;
    var days = parseInt(document.getElementById('activityDays').value) || 30;
    var panel = document.getElementById('ennxPreviewPanel');
    var textarea = document.getElementById('ennxPreviewText');
    var lineCountEl = document.getElementById('ennxLineCount');

    if (panel.classList.contains('open')) {
        panel.classList.remove('open');
        return;
    }

    textarea.value = 'Loading ENNX preview...';
    panel.classList.add('open');

    fetch('va_fixed_reader.aspx?api=reader_ennx&companyid=' + siteId + '&days=' + days + '&preview=1&t=' + Date.now())
        .then(function(r) { return r.text(); })
        .then(function(text) {
            textarea.value = text;
            var lines = text.split('\n').filter(function(l) { return l.trim().length > 0; });
            lineCountEl.textContent = lines.length + ' lines';
        })
        .catch(function(e) {
            textarea.value = 'Error loading preview: ' + e.message;
        });
}

// -- Fixed Reader Event Log (collapsible) -------------------------------
var eventData = [];
var eventLogOpen = false;
var eventLogLoaded = false;

function toggleEventLog() {
    var body = document.getElementById('eventLogBody');
    var chevron = document.getElementById('eventLogChevron');
    eventLogOpen = !eventLogOpen;
    if (eventLogOpen) {
        body.style.maxHeight = (body.scrollHeight + 800) + 'px';
        body.style.opacity = '1';
        chevron.style.transform = 'rotate(90deg)';
        if (!eventLogLoaded) loadReaderEvents();
    } else {
        body.style.maxHeight = '0';
        body.style.opacity = '0';
        chevron.style.transform = 'rotate(0deg)';
    }
}

function loadReaderEvents() {
    var days = parseInt(document.getElementById('eventDays').value) || 30;
    var tbody = document.getElementById('tblEventsBody');
    tbody.innerHTML = '<tr><td colspan="6" class="loading"><span class="spinner"></span>Loading events...</td></tr>';

    fetch('va_fixed_reader.aspx?api=reader_events&days=' + days + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            eventData = d.events || [];
            eventLogLoaded = true;
            var info = document.getElementById('eventInfo');
            info.innerHTML = '<strong>' + eventData.length + '</strong> fixed reader events in the last <strong>' + days + '</strong> days.';
            // Update count badge on header
            var badge = document.getElementById('eventLogCount');
            badge.textContent = eventData.length + ' events';
            badge.style.display = 'inline';
            renderEventsTable(eventData);
            // Re-expand to fit new content
            if (eventLogOpen) {
                var body = document.getElementById('eventLogBody');
                body.style.maxHeight = (body.scrollHeight + 800) + 'px';
            }
        })
        .catch(function(e) {
            tbody.innerHTML = '<tr><td colspan="6" class="err-msg">Error: ' + e.message + '</td></tr>';
        });
}

function renderEventsTable(data) {
    var tbody = document.getElementById('tblEventsBody');
    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="loading" style="color:var(--muted);">No reader events found.</td></tr>';
        return;
    }
    var html = '';
    data.forEach(function(ev) {
        var isUnprovisioned = ev.EventType === 'Tag Not Provisioned';
        var rowClass = isUnprovisioned ? 'style="background:rgba(245,158,11,0.06);"' : '';
        var typeBadge = isUnprovisioned
            ? '<span class="badge b-amber">Not Provisioned</span>'
            : '<span class="badge b-green">' + esc(ev.EventType) + '</span>';
        html += '<tr ' + rowClass + '>' +
            '<td style="white-space:nowrap;font-size:12px;">' + esc(ev.EventTime) + '</td>' +
            '<td style="font-family:monospace;font-size:11px;">' + esc(ev.RfidTag) + '</td>' +
            '<td>' + esc(ev.DecodedName) + '</td>' +
            '<td>' + typeBadge + '</td>' +
            '<td style="font-size:11px;max-width:300px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="' + esc(ev.EventDetails).replace(/"/g,'&quot;') + '">' + esc(ev.EventDetails) + '</td>' +
            '<td>' + esc(ev.SiteName) + '</td>' +
            '</tr>';
    });
    tbody.innerHTML = html;
}

function filterEvents() {
    var filters = document.querySelectorAll('.evtFilter');
    var filterVals = [];
    filters.forEach(function(f) { filterVals.push(f.value.toLowerCase().trim()); });
    var hasFilter = filterVals.some(function(v) { return v.length > 0; });

    var filtered = eventData.filter(function(ev) {
        var cols = [ev.EventTime, ev.RfidTag, ev.DecodedName, ev.EventType, ev.EventDetails, ev.SiteName];
        for (var i = 0; i < 6; i++) {
            if (filterVals[i] && (cols[i] || '').toLowerCase().indexOf(filterVals[i]) === -1) return false;
        }
        return true;
    });

    renderEventsTable(filtered);

    // Show filter info
    var filterInfo = document.getElementById('eventFilterInfo');
    if (hasFilter) {
        filterInfo.style.display = 'block';
        filterInfo.innerHTML = 'Showing <strong>' + filtered.length + '</strong> of <strong>' + eventData.length + '</strong> events (filtered)';
    } else {
        filterInfo.style.display = 'none';
    }

    // Store filtered for CSV export
    window._filteredEvents = hasFilter ? filtered : null;
}

function exportEventsCsv() {
    var dataToExport = window._filteredEvents || eventData;
    if (!dataToExport || dataToExport.length === 0) {
        // Fall back to server-side export
        var days = parseInt(document.getElementById('eventDays').value) || 30;
        window.location.href = 'va_fixed_reader.aspx?api=reader_events_csv&days=' + days;
        return;
    }
    // Client-side CSV from filtered data
    var csv = 'Time,RFID Tag,Decoded Name,Event Type,Details,Tag Site\n';
    dataToExport.forEach(function(ev) {
        csv += csvQuote(ev.EventTime) + ',' +
               csvQuote(ev.RfidTag) + ',' +
               csvQuote(ev.DecodedName) + ',' +
               csvQuote(ev.EventType) + ',' +
               csvQuote(ev.EventDetails) + ',' +
               csvQuote(ev.SiteName) + '\n';
    });
    var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    var link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    var suffix = window._filteredEvents ? '-filtered' : '';
    link.download = 'FixedReaderEvents' + suffix + '-' + new Date().toISOString().slice(0,10) + '.csv';
    link.click();
}

function csvQuote(val) {
    if (val == null) return '';
    var s = String(val);
    if (s.indexOf(',') >= 0 || s.indexOf('"') >= 0 || s.indexOf('\n') >= 0)
        return '"' + s.replace(/"/g, '""') + '"';
    return s;
}

// Toggle listeners
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('cfgAutoReassign').addEventListener('change', function() {
        document.getElementById('cfgAutoLabel').textContent = this.checked ? 'ON' : 'OFF';
    });
    document.getElementById('cfgEmailReport').addEventListener('change', function() {
        document.getElementById('cfgEmailLabel').textContent = this.checked ? 'ON' : 'OFF';
    });
});

// ── ASSET DETAIL PANEL ────────────────────────────────────────
var _dpCurrentId = null;

function openAssetDetail(assetId, assetName) {
    _dpCurrentId = assetId;
    document.getElementById('dpTitle').textContent = assetName || 'Asset Detail';
    document.getElementById('dpMasterLink').href = 'va_asset_master.aspx?search=' + encodeURIComponent(assetName);
    document.getElementById('dpBody').innerHTML = '<div class="dp-loading"><span class="spinner"></span> Loading asset details...</div>';
    document.getElementById('detailPanel').classList.add('open');
    document.body.classList.add('detail-open');

    fetch('va_asset_master.aspx?api=detail&id=' + assetId + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            if (d.error) {
                document.getElementById('dpBody').innerHTML = '<div class="dp-empty">' + esc(d.error) + '</div>';
                return;
            }
            renderAssetDetail(d.asset);
        })
        .catch(function(e) {
            document.getElementById('dpBody').innerHTML = '<div class="dp-empty">Failed to load: ' + esc(e.message) + '</div>';
        });
}

function closeDetail() {
    document.getElementById('detailPanel').classList.remove('open');
    document.body.classList.remove('detail-open');
    _dpCurrentId = null;
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && _dpCurrentId) closeDetail();
});

function dpVal(v) {
    if (v === null || v === undefined || v === '') return '<span class="empty">&#8212;</span>';
    return String(v).replace(/</g, '&lt;');
}

function dpField(label, value) {
    var cls = (value === null || value === undefined || value === '') ? 'dp-val empty' : 'dp-val';
    var display = (value === null || value === undefined || value === '') ? '&#8212;' : String(value).replace(/</g, '&lt;');
    return '<div class="dp-field"><label>' + label + '</label><div class="' + cls + '">' + display + '</div></div>';
}

function dpDate(val) {
    if (!val) return '';
    var match = String(val).match(/\/Date\((-?\d+)\)\//);
    var d = match ? new Date(parseInt(match[1])) : new Date(val);
    if (isNaN(d.getTime())) return String(val);
    return d.toLocaleDateString('en-US', {month:'short',day:'numeric',year:'numeric'}) + ' ' +
           d.toLocaleTimeString('en-US', {hour:'2-digit',minute:'2-digit'});
}

function renderAssetDetail(a) {
    var h = '';
    h += '<div class="dp-field-group"><div class="dp-field-group-title">Identity</div><div class="dp-fields">';
    h += dpField('Asset Name', a.name);
    h += dpField('Description', a.description);
    h += dpField('Asset Type', a.assettype);
    h += dpField('RFID Tag', a.rfidtag);
    h += dpField('CMR #', a.text8);
    h += dpField('Serial #', a.text3);
    h += '</div></div>';

    h += '<div class="dp-field-group"><div class="dp-field-group-title">Location</div><div class="dp-fields">';
    h += dpField('Assigned Location', a.locationname);
    h += dpField('Building', a.locationbuilding);
    h += dpField('Floor', a.locationfloor);
    h += dpField('Room', a.locationroom);
    h += dpField('Dept. Code', a.departmentcode);
    h += '</div></div>';

    h += '<div class="dp-field-group"><div class="dp-field-group-title">Fixed Reader Observation</div><div class="dp-fields">';
    h += dpField('Last Observed', a.lastobservedtime ? dpDate(a.lastobservedtime) : null);
    h += dpField('Observed Location', a.lastobservedlocation);
    if (a.locationname && a.lastobservedlocation && a.locationname !== a.lastobservedlocation) {
        h += '<div class="dp-field" style="grid-column:1/-1;"><label>Mismatch</label><div class="dp-val" style="background:rgba(245,158,11,.08);border-color:rgba(245,158,11,.2);color:#92400E;">Observed at <strong>' + esc(a.lastobservedlocation) + '</strong> but assigned to <strong>' + esc(a.locationname) + '</strong></div></div>';
    }
    h += '</div></div>';

    h += '<div class="dp-field-group"><div class="dp-field-group-title">Status & Checkout</div><div class="dp-fields">';
    h += dpField('Status', a.listvalue1);
    h += dpField('Checkout Status', a.checkinstatus);
    h += dpField('Checked Out To', a.checkedoutto);
    h += dpField('Disposal Status', a.disposalstatus);
    h += '</div></div>';

    h += '<div class="dp-field-group"><div class="dp-field-group-title">Details</div><div class="dp-fields">';
    h += dpField('Category', a.text4);
    h += dpField('Manufacturer', a.text1);
    h += dpField('Model', a.text2);
    h += dpField('Service', a.text5);
    h += dpField('Station', a.text7);
    h += dpField('PO #', a.text9);
    h += '</div></div>';

    h += '<div class="dp-field-group"><div class="dp-field-group-title">Inventory & Dates</div><div class="dp-fields">';
    h += dpField('Last Inventoried', dpDate(a.lastinventoried));
    h += dpField('Created', dpDate(a.created));
    h += dpField('Last Modified', dpDate(a.lastmodified));
    h += dpField('Modified By', a.lastmodifiedby);
    h += '</div></div>';

    if (a.additionalinformation) {
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Notes</div>';
        h += '<div style="font-size:13px;color:var(--text);padding:8px;background:var(--bg);border:1px solid var(--line);border-radius:5px;white-space:pre-wrap;">' + esc(a.additionalinformation) + '</div></div>';
    }

    document.getElementById('dpBody').innerHTML = h;
}

// ── INIT ──────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function() {
    loadAll();
});

// -- Missing Asset Report ----------------------------------
var missingOpen = false;
var missingLoaded = false;
var missingData = [];

function toggleMissing() {
    missingOpen = !missingOpen;
    var body = document.getElementById('missingBody');
    var chev = document.getElementById('missingChevron');
    if (missingOpen) {
        body.style.maxHeight = '2000px';
        body.style.opacity = '1';
        chev.style.transform = 'rotate(90deg)';
        if (!missingLoaded) loadMissingAssets();
    } else {
        body.style.maxHeight = '0';
        body.style.opacity = '0';
        chev.style.transform = 'rotate(0deg)';
    }
}

function loadMissingAssets() {
    missingLoaded = true;
    var siteId = document.getElementById('DdlCompany').value || '0';
    var days = document.getElementById('missingDays').value || '90';
    var allSites = document.getElementById('missingAllSites').checked ? '1' : '0';

    var tbody = document.getElementById('tblMissingBody');
    tbody.innerHTML = '<tr><td colspan="7" class="loading"><span class="spinner"></span>Loading missing assets...</td></tr>';

    fetch('va_fixed_reader.aspx?api=missing_assets&companyid=' + siteId + '&days=' + days + '&allsites=' + allSites + '&t=' + Date.now())
        .then(function(r) { return r.json(); })
        .then(function(d) {
            missingData = d.assets || [];
            if (d.stats) {
                document.getElementById('msTotalAssets').textContent = fmt.format(d.stats.totalAssets);
                document.getElementById('msObserved').textContent = fmt.format(d.stats.observedCount);
                document.getElementById('msMissing').textContent = fmt.format(d.stats.missingCount);
                document.getElementById('msCoverage').textContent = d.stats.coveragePct + '%';
            }
            var cnt = document.getElementById('missingCount');
            if (d.total > 0) {
                cnt.textContent = fmt.format(d.total);
                cnt.style.display = '';
            } else {
                cnt.style.display = 'none';
            }
            document.getElementById('missingInfo').innerHTML = '<b>' + fmt.format(d.total) + '</b> assets not observed by a fixed reader in the last <b>' + days + '</b> days.';
            renderMissing(missingData);
        })
        .catch(function(e) {
            tbody.innerHTML = '<tr><td colspan="7" class="loading" style="color:var(--muted);">Error loading data: ' + e.message + '</td></tr>';
        });
}

function renderMissing(data) {
    var tbody = document.getElementById('tblMissingBody');
    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="loading" style="color:var(--muted);">?? All assets have been observed by a fixed reader within this period!</td></tr>';
        return;
    }
    var MAX_ROWS = 500;
    var capped = data.length > MAX_ROWS;
    var html = '';
    var limit = Math.min(data.length, MAX_ROWS);
    for (var i = 0; i < limit; i++) {
        var a = data[i];
        var daysTxt = a.DaysSince !== null && a.DaysSince !== undefined ? a.DaysSince + 'd' : 'Never';
        var daysColor = a.DaysSince === null || a.DaysSince === undefined ? '#ef4444' : (a.DaysSince > 180 ? '#ef4444' : (a.DaysSince > 90 ? '#f59e0b' : 'var(--muted)'));
        html += '<tr>';
        html += '<td><strong>' + esc(a.Name) + '</strong></td>';
        html += '<td>' + esc(a.Description) + '</td>';
        html += '<td>' + esc(a.CMR) + '</td>';
        html += '<td>' + esc(a.AssignedLocation) + '</td>';
        html += '<td>' + (a.LastObserved || '<span style="color:#ef4444;">Never</span>') + '</td>';
        html += '<td style="color:' + daysColor + ';font-weight:600;">' + daysTxt + '</td>';
        html += '<td>' + esc(a.Site) + '</td>';
        html += '</tr>';
    }
    if (capped) {
        html += '<tr><td colspan="7" style="text-align:center;padding:12px;color:var(--muted);font-style:italic;">Showing ' + MAX_ROWS + ' of ' + fmt.format(data.length) + ' missing assets. Use <strong>Export CSV</strong> for the full list.</td></tr>';
    }
    tbody.innerHTML = html;
}

function filterMissing() {
    var filters = document.querySelectorAll('.missingFilter');
    var vals = [];
    filters.forEach(function(f) { vals[parseInt(f.getAttribute('data-col'))] = f.value.toLowerCase(); });
    var rows = document.querySelectorAll('#tblMissingBody tr');
    rows.forEach(function(row) {
        var cells = row.querySelectorAll('td');
        if (cells.length < 7) return;
        var show = true;
        for (var i = 0; i < vals.length; i++) {
            if (vals[i] && cells[i] && cells[i].textContent.toLowerCase().indexOf(vals[i]) === -1) {
                show = false; break;
            }
        }
        row.style.display = show ? '' : 'none';
    });
}

function exportMissingCsv() {
    var siteId = document.getElementById('DdlCompany').value || '0';
    var days = document.getElementById('missingDays').value || '90';
    var allSites = document.getElementById('missingAllSites').checked ? '1' : '0';
    window.location.href = 'va_fixed_reader.aspx?api=missing_assets_csv&companyid=' + siteId + '&days=' + days + '&allsites=' + allSites;
}

</script>
</body>
</html>

