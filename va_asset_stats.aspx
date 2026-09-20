<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_asset_stats.aspx.cs" Inherits="iDash.va_asset_stats" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Asset Statistics &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        :root {
            --bg-base:     var(--bg);
            --panel-bg:    var(--card);
            --panel-border:var(--line);
            --text-main:   var(--text);
            --text-accent: var(--muted);
            --highlight:   var(--accent);
            --success:     var(--accent-2);
            --warning:     var(--warn);
        }
        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }

        * { box-sizing: border-box; }

        body {
            margin: 0; padding: 0;
            background: var(--bg-base);
            color: var(--text-main);
            font-family: 'Inter', 'Segoe UI', sans-serif;
            background-image:
                radial-gradient(circle at top left, color-mix(in srgb, var(--accent), transparent 95%), transparent 40%),
                radial-gradient(circle at bottom right, rgba(139,92,246,0.06), transparent 40%);
            min-height: 100vh;
        }

        .dash { max-width: 1440px; margin: 0 auto; padding: 30px 24px; }

        /* -- HEADER ----------------------------------- */
        .page-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 36px;
            border-bottom: 1px solid var(--panel-border);
            padding-bottom: 20px;
            flex-wrap: wrap; gap: 16px;
        }
        .page-header h1 {
            margin: 0; font-size: 26px; font-weight: 700; color: var(--text);
        }
        .header-controls { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }

        .ctrl-select {
            background: var(--chip);
            color: var(--text-main);
            border: 1px solid var(--panel-border);
            padding: 8px 14px; border-radius: 8px; font-size: 14px; outline: none;
        }
        .ctrl-select option { background: var(--card); color: var(--text-main); }

        /* header action pills — see theme.css .hdr-pill */

        /* -- GLASS PANEL ------------------------------- */
        .glass {
            background: var(--panel-bg);
            backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
            border: 1px solid var(--panel-border);
            border-radius: 16px;
            padding: 24px;
            box-shadow: var(--shadow);
            transition: all 0.2s;
        }
        .glass:hover { box-shadow: 0 12px 44px rgba(0,0,0,0.25); transform: translateY(-2px); }

        .panel-title {
            font-size: 15px; font-weight: 600;
            color: var(--text-accent);
            text-transform: uppercase; letter-spacing: 0.8px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            padding-bottom: 12px; margin-bottom: 20px;
        }

        /* -- KPI ROW ----------------------------------- */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 18px; margin-bottom: 24px;
        }
        @media(max-width:1100px) { .kpi-row { grid-template-columns: repeat(3,1fr); } }
        @media(max-width:700px)  { .kpi-row { grid-template-columns: repeat(2,1fr); } }

        .kpi-card { text-align: center; padding: 28px 16px; }
        .kpi-value {
            font-size: 40px; font-weight: 700;
            color: var(--highlight); line-height: 1;
            margin-bottom: 8px;
        }
        .kpi-label {
            font-size: 12px; font-weight: 600;
            text-transform: uppercase; letter-spacing: 0.8px;
            color: var(--text-accent);
        }
        .kpi-sub { font-size: 12px; color: var(--text-accent); margin-top: 4px; }

        /* -- METRIC GRID (2col) ------------------------ */
        .metric-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px; margin-bottom: 24px;
        }
        @media(max-width:800px) { .metric-grid { grid-template-columns: 1fr; } }

        /* -- STATUS BAR -------------------------------- */
        .status-bar-wrap { margin-bottom: 14px; }
        .status-bar {
            display: flex; height: 28px; border-radius: 8px;
            overflow: hidden; background: rgba(255,255,255,0.04);
            margin-bottom: 16px;
        }
        .status-bar-seg { height: 100%; transition: width 0.5s ease; }
        .legend-grid {
            display: flex; flex-direction: column; gap: 0;
        }
        .legend-chip {
            display: flex; align-items: center; gap: 10px;
            font-size: 13px; color: var(--text-main);
            padding: 9px 4px;
            border-bottom: 1px solid rgba(255,255,255,0.04);
        }
        .legend-chip:last-child { border-bottom: none; }
        .legend-dot { width: 10px; height: 10px; border-radius: 3px; flex-shrink: 0; }
        .legend-name { flex: 1; font-weight: 500; }
        .legend-pct { font-weight: 700; color: var(--text-main); min-width: 60px; text-align: right; font-variant-numeric: tabular-nums; }
        .legend-pct-sub { font-size: 12px; color: var(--text-accent); min-width: 60px; text-align: right; font-variant-numeric: tabular-nums; }

        /* -- METRIC ROWS ------------------------------- */
        .metric-row {
            display: flex; align-items: center; justify-content: space-between;
            padding: 13px 0;
            border-bottom: 1px solid rgba(255,255,255,0.04);
        }
        .metric-row:last-child { border-bottom: none; }
        .metric-name {
            font-size: 13px; font-weight: 500; color: var(--text-accent);
        }
        .badge-row { display: flex; gap: 8px; flex-wrap: wrap; }
        .badge {
            display: inline-flex; align-items: center;
            padding: 4px 12px; border-radius: 20px;
            font-size: 12px; font-weight: 700;
        }
        .b-green  { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: #10B981; border: 1px solid rgba(16,185,129,0.3); }
        .b-red    { background: color-mix(in srgb, var(--danger), transparent 85%);  color: #EF4444; border: 1px solid rgba(239,68,68,0.3); }
        .b-yellow { background: rgba(245,158,11,0.18); color: #F59E0B; border: 1px solid rgba(245,158,11,0.3); }
        .b-blue   { background: color-mix(in srgb, var(--accent), transparent 85%); color: #2EA8FF; border: 1px solid rgba(46,168,255,0.3); }
        .b-orange { background: rgba(249,115,22,0.18); color: #F97316; border: 1px solid rgba(249,115,22,0.3); }
        .b-purple { background: rgba(139,92,246,0.18); color: #8B5CF6; border: 1px solid rgba(139,92,246,0.3); }
        .b-gray   { background: rgba(156,163,175,0.18);color: #9CA3AF; border: 1px solid rgba(156,163,175,0.3); }
        .b-label  { font-size: 10px; font-weight: 400; opacity: 0.75; margin-left: 2px; }

        /* -- LOCATION TABLE ---------------------------- */
        .loc-table-wrap { overflow-x: auto; }
        .loc-table {
            width: 100%; border-collapse: collapse; font-size: 13px;
        }
        .loc-table th {
            background: rgba(255,255,255,0.04);
            color: var(--text-accent);
            font-size: 11px; text-transform: uppercase; letter-spacing: 0.6px;
            padding: 10px 14px; text-align: left; cursor: pointer;
            white-space: nowrap; border-bottom: 1px solid var(--line);
            user-select: none;
        }
        .loc-table th:hover { color: var(--text-main); }
        /* Sort indicators — match va_location_list and va_asset_master */
        .loc-table th .sh-si { display:inline-block; margin-left:5px; font-size:9px; opacity:.3; transition:opacity .15s; }
        .loc-table th.sort-asc  .sh-si,
        .loc-table th.sort-desc .sh-si { opacity:1; color:var(--accent); }
        .loc-table th.sort-asc,
        .loc-table th.sort-desc { color:var(--accent); }
        /* Filter row th — no cursor/uppercase styling, just holds col-search input */
        .loc-table #locStatsFilterRow th,
        .loc-table #la-search-row th { cursor:default; text-transform:none; letter-spacing:0; padding:2px 4px !important; background:rgba(255,255,255,0.02); }
        .loc-table td {
            padding: 11px 14px;
            border-bottom: 1px solid rgba(255,255,255,0.03);
            color: var(--text-main);
        }
        .loc-table tbody tr:hover td { background: rgba(255,255,255,0.025); }
        .loc-table .td-num { text-align: left; font-variant-numeric: tabular-nums; }
        .td-overdue { color: var(--danger) !important; font-weight: 600; }
        .td-good    { color: var(--success) !important; }

        /* mini progress bar in table */
        .mini-bar { display: flex; height: 4px; border-radius: 2px; background: rgba(255,255,255,0.06); margin-top: 4px; width: 80px; overflow: hidden; }
        .mini-fill { height: 100%; border-radius: 2px; }

        /* -- FILTER ROW --------------------------------- */
        .filter-input {
            width: 100%; padding: 5px 8px; border-radius: 4px; font-size: 11px;
            background: var(--chip); color: var(--text-main);
            border: 1px solid var(--line); font-weight: 400;
        }
        .filter-input::placeholder { color: var(--text-accent); opacity: 0.5; }

        .section-gap { margin-bottom: 24px; }
        .err-msg { background: color-mix(in srgb, var(--danger), transparent 85%); border: 1px solid rgba(239,68,68,0.3); padding: 12px 16px; border-radius: 8px; margin-bottom: 16px; color: #EF4444; }

        /* -- STICKY NAV TABS ----------------------------- */
        .tab-nav {
            position: sticky;
            top: 0;
            z-index: 300;
            background: var(--bg-base);
            padding: 14px 0 20px;
            margin: 0 0 8px;
        }
        .tab-pill-row {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .tab-pill {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 18px;
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: 12px;
            cursor: pointer;
            transition: all .2s;
            font-family: inherit;
            color: var(--text-accent);
            text-align: left;
            flex: 1;
            min-width: 180px;
        }
        .tab-pill:hover {
            background: color-mix(in srgb, var(--accent), transparent 85%);
            border-color: var(--accent);
            color: var(--text-main);
        }
        .tab-pill.active {
            background: color-mix(in srgb, var(--accent), transparent 85%);
            border-color: var(--highlight);
            color: var(--highlight);
            box-shadow: var(--shadow);
        }
        .tab-pill-icon { font-size: 20px; flex-shrink: 0; }
        .tab-pill-text { display: flex; flex-direction: column; gap: 2px; }
        .tab-pill-name { font-size: 13px; font-weight: 700; line-height: 1.2; }
        .tab-pill-desc { font-size: 11px; opacity: .65; line-height: 1.3; }
        .tab-pane { display: none; }
        .tab-pane.active { display: block; }

        /* -- SECTION INTRO BANNER ------------------------ */
        .tab-intro {
            display: flex;
            align-items: flex-start;
            gap: 14px;
            padding: 14px 18px;
            background: color-mix(in srgb, var(--accent), transparent 95%);
            border: 1px solid color-mix(in srgb, var(--accent), transparent 85%);
            border-radius: 12px;
            margin-bottom: 20px;
        }
        .tab-intro-icon { font-size: 28px; flex-shrink: 0; line-height: 1; }
        .tab-intro-title { font-size: 14px; font-weight: 700; color: var(--text-main); margin: 0 0 3px; }
        .tab-intro-body  { font-size: 12px; color: var(--text-accent); margin: 0; line-height: 1.5; }

        /* -- LOADING SPINNER ----------------------------- */
        .spin-wrap { text-align: center; padding: 30px; color: var(--text-accent); font-size: 13px; }
        .spinner {
            width: 28px; height: 28px;
            border: 3px solid color-mix(in srgb, var(--accent), transparent 85%);
            border-top-color: var(--highlight);
            border-radius: 50%;
            animation: spin .8s linear infinite;
            margin: 0 auto 12px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* -- DRILL BUTTON -------------------------------- */
        .drill-btn {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background: color-mix(in srgb, var(--accent), transparent 85%);
            color: var(--highlight);
            border: 1px solid rgba(46,168,255,.3);
            padding: 4px 12px;
            border-radius: 6px;
            font-size: 12px;
            cursor: pointer;
            font-family: inherit;
            transition: all .2s;
            vertical-align: middle;
            margin-left: 10px;
        }
        .drill-btn:hover { background: color-mix(in srgb, var(--accent), transparent 85%); transform: translateY(-1px); }
        .drill-btn::before { content: ''; }
        .dq-empty { color: var(--text-accent); font-size: 12px; font-style: italic; padding: 10px 0; }

        /* -- DATA QUALITY LAYOUT ----------------------- */
        .dq-kpi-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px; margin-bottom: 20px;
        }
        @media(max-width:900px) { .dq-kpi-row { grid-template-columns: repeat(2,1fr); } }
        @media(max-width:500px) { .dq-kpi-row { grid-template-columns: 1fr; } }
        .dq-card { text-align: center; padding: 22px 12px; }
        .dq-val  { font-size: 36px; font-weight: 700; line-height: 1; margin-bottom: 6px; }
        .dq-lbl  { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .8px; color: var(--text-accent); }
        .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
        @media(max-width:800px) { .two-col { grid-template-columns: 1fr; } }
        .tbl-wrap { overflow-x: auto; }

        /* -- EXT TABLE (tabs) ------------------------- */
        .ext-tbl { width:100%; border-collapse:collapse; font-size:13px; }
        .ext-tbl th { background:rgba(0,0,0,0.05); color:var(--text-accent); font-size:11px;
            text-transform:uppercase; letter-spacing:.6px; padding:9px 12px; text-align:left;
            cursor:pointer; white-space:nowrap; border-bottom:1px solid var(--line); user-select:none; }
        .ext-tbl th:hover { color:var(--text-main); }
        .ext-tbl td { padding:10px 12px; border-bottom:1px solid var(--line); }
        .ext-tbl tbody tr:hover td { background:rgba(0,0,0,0.02); }
        .ext-tbl .num { text-align:right; font-variant-numeric:tabular-nums; }
        .filter-th { padding:4px 6px !important; background:rgba(0,0,0,0.05) !important; cursor:default !important; }
        .ext-fi { width:100%; padding:4px 7px; border-radius:4px; font-size:11px;
            background:var(--chip); color:var(--text-main); border:1px solid var(--line); }
        .ext-fi::placeholder { color:var(--text-accent); opacity:0.5; }
        .loading-cell { text-align:center; padding:20px; color:var(--text-accent); font-size:13px; }

        /* -- PROG BAR --------------------------------- */
        .prog-bar  { height:4px; border-radius:2px; background:rgba(255,255,255,.06); margin-top:5px; }
        .prog-fill { height:100%; border-radius:2px; }

        /* -- CHART BOX -------------------------------- */
        .chart-box { height:240px; position:relative; }
        .an-chart-grid { display:grid; grid-template-columns:1fr 1fr; gap:18px; margin-bottom:20px; }
        @media(max-width:800px) { .an-chart-grid { grid-template-columns:1fr; } }

        /* -- COL CHOOSER PILLS -- */
        .col-toggle { display:inline-flex; align-items:center; gap:5px; padding:5px 11px; border-radius:20px; font-size:11px; font-weight:600; cursor:pointer; border:1.5px solid var(--line); color:var(--muted); transition:.2s; user-select:none; }
        .col-toggle:hover { border-color:var(--accent); color:var(--accent); }
        .col-toggle.active { background:color-mix(in srgb,var(--accent),transparent 88%); color:var(--accent); border-color:var(--accent); }
        .col-toggle input { display:none; }
        /* -- DETAIL PANEL -- */
        .detail-panel { position:fixed; top:0; right:0; bottom:0; width:700px; max-width:95vw; background:var(--card); border-left:2px solid var(--line); z-index:200; transform:translateX(100%); transition:transform .3s ease; display:flex; flex-direction:column; overflow:hidden; box-shadow:-8px 0 30px rgba(0,0,0,.25); }
        .detail-panel.open { transform:translateX(0); }
        body.detail-open .dash { margin-right:710px; transition:margin-right .3s ease; }
        @media(max-width:1100px){ body.detail-open .dash { margin-right:0; } }
        .dp-header { display:flex; align-items:center; justify-content:space-between; padding:16px 20px; border-bottom:1px solid var(--line); background:linear-gradient(135deg,color-mix(in srgb,var(--accent),var(--card) 88%),var(--card)); flex-shrink:0; }
        .dp-header h2 { margin:0; font-size:16px; font-weight:700; display:flex; align-items:center; gap:10px; }
        .dp-header h2 .dp-icon { width:32px; height:32px; border-radius:8px; display:flex; align-items:center; justify-content:center; background:linear-gradient(135deg,var(--accent),#8B5CF6); font-size:15px; color:#fff; }
        .dp-close { background:none; border:1px solid var(--line); border-radius:8px; color:var(--muted); width:32px; height:32px; font-size:16px; cursor:pointer; transition:.2s; }
        .dp-close:hover { border-color:var(--danger); color:var(--danger); }
        .dp-actions { display:flex; gap:6px; padding:10px 20px; border-bottom:1px solid var(--line); background:var(--bg); flex-shrink:0; flex-wrap:wrap; }
        .dp-action-btn { display:inline-flex; align-items:center; gap:5px; padding:6px 14px; border-radius:6px; font-size:12px; font-weight:600; text-decoration:none; border:1px solid var(--line); background:var(--chip); color:var(--text); cursor:pointer; transition:.2s; }
        .dp-action-btn:hover { border-color:var(--accent); color:var(--accent); }
        .dp-tabs { display:flex; border-bottom:2px solid var(--line); padding:0 20px; background:var(--bg); flex-shrink:0; overflow-x:auto; }
        .dp-tab { padding:10px 16px; font-size:12px; font-weight:600; text-transform:uppercase; letter-spacing:.4px; color:var(--muted); cursor:pointer; border:none; background:none; border-bottom:2px solid transparent; margin-bottom:-2px; transition:.2s; white-space:nowrap; }
        .dp-tab:hover { color:var(--text); }
        .dp-tab.active { color:var(--accent); border-bottom-color:var(--accent); }
        .dp-tab .tab-badge { display:inline-flex; align-items:center; justify-content:center; min-width:18px; height:18px; border-radius:9px; font-size:10px; font-weight:700; background:color-mix(in srgb,var(--accent),transparent 85%); color:var(--accent); margin-left:5px; padding:0 5px; }
        .dp-body { flex:1; overflow-y:auto; padding:20px; }
        .dp-tab-content { display:none; }
        .dp-tab-content.active { display:block; }
        .dp-field-group { margin-bottom:18px; }
        .dp-field-group-title { font-size:11px; font-weight:700; color:var(--accent); text-transform:uppercase; letter-spacing:.5px; border-bottom:1px solid var(--line); padding-bottom:6px; margin-bottom:10px; }
        .dp-fields { display:grid; grid-template-columns:1fr 1fr; gap:8px 16px; }
        .dp-fields.single { grid-template-columns:1fr; }
        .dp-field label { display:block; font-size:10px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.3px; margin-bottom:2px; }
        .dp-field .dp-val { font-size:13px; color:var(--text); padding:5px 8px; background:var(--bg); border:1px solid var(--line); border-radius:5px; min-height:28px; word-break:break-word; }
        .dp-field .dp-val.empty { color:var(--muted); font-style:italic; opacity:.5; }
        .dp-history-table { width:100%; border-collapse:collapse; font-size:12px; }
        .dp-history-table th { background:var(--chip); color:var(--muted); font-size:10px; text-transform:uppercase; letter-spacing:.4px; padding:8px 10px; text-align:left; border-bottom:1px solid var(--line); position:sticky; top:0; }
        .dp-history-table td { padding:7px 10px; border-bottom:1px solid var(--line); }
        .dp-history-table tbody tr:hover td { background:var(--table-row-hover); }
        .dp-empty { text-align:center; padding:40px 20px; color:var(--muted); font-size:13px; font-style:italic; }
        .dp-empty .dp-empty-icon { font-size:36px; margin-bottom:10px; opacity:.4; display:block; }
        .dp-loading { text-align:center; padding:30px; color:var(--accent); font-weight:600; font-size:13px; }
        .dp-edit-toggle { display:inline-flex; align-items:center; gap:5px; padding:6px 14px; border-radius:6px; font-size:12px; font-weight:600; cursor:pointer; transition:.2s; border:1px solid var(--line); background:var(--chip); color:var(--text); }
        .dp-edit-toggle:hover { border-color:var(--accent); color:var(--accent); }
        .dp-edit-toggle.editing { background:color-mix(in srgb,var(--accent-2),transparent 85%); color:var(--accent-2); border-color:var(--accent-2); }
        .dp-field .dp-input,.dp-field .dp-select,.dp-field .dp-textarea { width:100%; font-size:13px; color:var(--text); padding:5px 8px; background:var(--bg); border:1.5px solid color-mix(in srgb,var(--accent),transparent 60%); border-radius:5px; outline:none; font-family:inherit; transition:border-color .2s; }
        .dp-field .dp-input:focus,.dp-field .dp-select:focus,.dp-field .dp-textarea:focus { border-color:var(--accent); box-shadow:0 0 0 2px color-mix(in srgb,var(--accent),transparent 80%); }
        .dp-field .dp-textarea { min-height:60px; resize:vertical; }
        .dp-field .dp-select option { background:var(--card); }
        .dp-field.dirty .dp-input,.dp-field.dirty .dp-select,.dp-field.dirty .dp-textarea { border-color:var(--accent-2); background:color-mix(in srgb,var(--accent-2),transparent 92%); }
        .dp-save-bar { display:none; padding:12px 20px; border-top:2px solid var(--accent-2); background:color-mix(in srgb,var(--accent-2),var(--card) 92%); flex-shrink:0; gap:8px; align-items:center; justify-content:space-between; }
        .dp-save-bar.show { display:flex; }
        .dp-save-bar .dp-save-info { font-size:12px; color:var(--accent-2); font-weight:600; }
        .dp-save-bar .dp-save-btns { display:flex; gap:8px; }
        .dp-save-btn { padding:8px 20px; border-radius:6px; border:none; cursor:pointer; font-size:13px; font-weight:600; transition:.2s; }
        .dp-save-btn.save { background:var(--accent-2); color:#fff; }
        .dp-save-btn.save:hover { opacity:.88; }
        .dp-save-btn.cancel { background:var(--chip); color:var(--text); border:1px solid var(--line); }
        .dp-save-btn.cancel:hover { border-color:var(--danger); color:var(--danger); }
        .dp-save-toast { position:fixed; bottom:24px; right:24px; padding:12px 24px; border-radius:10px; font-size:13px; font-weight:600; z-index:9999; animation:toastIn .3s ease-out; box-shadow:0 4px 20px rgba(0,0,0,.3); }
        .dp-save-toast.success { background:var(--accent-2); color:#fff; }
        .dp-save-toast.error { background:var(--danger); color:#fff; }
        @keyframes toastIn { from{opacity:0;transform:translateY(10px);} to{opacity:1;transform:translateY(0);} }
        /* -- LOC ASSET DRILL-DOWN TABLE -- */
        #locAssetTbl tbody tr { cursor:pointer; }
        #locAssetTbl tbody tr:hover td { background:var(--table-row-hover) !important; }
        #locAssetTbl tbody tr.la-selected td { background:color-mix(in srgb,var(--accent),transparent 88%) !important; }
        /* col-search inputs — matches Asset Master style exactly */
        .col-search { width:100%; background:var(--chip); color:var(--text); border:1px solid var(--line); padding:4px 8px; border-radius:4px; font-size:11px; outline:none; box-sizing:border-box; font-family:inherit; }
        .col-search::placeholder { color:var(--muted); opacity:.4; }
        #la-search-row th { padding:2px 4px !important; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- -- HEADER -- -->
    <div class="page-header">
        <h1>Asset Statistics</h1>
        <div class="header-controls">
            <asp:DropDownList ID="DdlCompany" runat="server" AutoPostBack="true"
                OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" CssClass="ctrl-select" />
            <asp:Button ID="BtnExportExcel" runat="server" Text="&#128190; Export Excel"
                CssClass="nav-pill nav-pill-primary" OnClick="BtnExportExcel_Click" />
            <a href="va_asset_master.aspx" class="nav-pill nav-pill-ghost">&#128203; Asset Master</a>
            <a href="va_location_list.aspx" class="nav-pill nav-pill-ghost">&#128205; Locations</a>
            <a href="documentation/va_asset_stats.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <asp:Literal ID="LitErr" runat="server" />

    <!-- STICKY PILL NAV -->
    <div class="tab-nav">
        <div class="tab-pill-row">

            <button type="button" class="tab-pill active" id="pill-overview" onclick="switchAsTab('overview',this)">
                <span class="tab-pill-icon">&#128200;</span>
                <span class="tab-pill-text">
                    <span class="tab-pill-name">Asset Overview</span>
                    <span class="tab-pill-desc">KPIs, status breakdown, inventory aging &amp; location table</span>
                </span>
            </button>

            <button type="button" class="tab-pill" id="pill-quality" onclick="switchAsTab('quality',this)">
                <span class="tab-pill-icon">&#9888;</span>
                <span class="tab-pill-text">
                    <span class="tab-pill-name">Data Quality</span>
                    <span class="tab-pill-desc">Identify assets missing EIL, location, or status</span>
                </span>
            </button>



            <button type="button" class="tab-pill" id="pill-analytics" onclick="switchAsTab('analytics',this)">
                <span class="tab-pill-icon">&#128202;</span>
                <span class="tab-pill-text">
                    <span class="tab-pill-name">Analytics</span>
                    <span class="tab-pill-desc">Category, station, scan velocity &amp; tagging trends</span>
                </span>
            </button>

        </div>
    </div>

    <!-- TAB PANES -->
    <div id="as-tab-overview" class="tab-pane active">

    <!-- -- TOP KPI CARDS -- -->
    <div class="kpi-row section-gap">
        <div class="glass kpi-card">
            <div class="kpi-value" id="kv-total" style="color:var(--highlight);">0</div>
            <div class="kpi-label">Total Assets</div>
            <div class="kpi-sub"><asp:Literal ID="LitSite" runat="server" /></div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-value" id="kv-inuse" style="color:var(--success);">0</div>
            <div class="kpi-label">In Use</div>
            <div class="kpi-sub" id="kv-inuse-pct" style="color:var(--success);">loading...</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-value" id="kv-noeil" style="color:var(--warning);">0</div>
            <div class="kpi-label">Missing EIL/CMR</div>
            <div class="kpi-sub" id="kv-noeil-pct">loading...</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-value" id="kv-overdue" style="color:var(--danger);">0</div>
            <div class="kpi-label">Inv. Overdue (&gt;12m)</div>
            <div class="kpi-sub" id="kv-overdue-pct">loading...</div>
        </div>
        <div class="glass kpi-card">
            <div class="kpi-value" id="kv-new" style="color:var(--accent);">0</div>
            <div class="kpi-label">Added This Month</div>
            <div class="kpi-sub">new assets</div>
        </div>
    </div>

    <!-- -- METRIC GRID (Status + Aging) -- -->
    <div class="metric-grid section-gap">

        <!-- Status Breakdown -->
        <div class="glass">
            <div class="panel-title">Asset Status Breakdown</div>
            <div class="status-bar-wrap">
                <div class="status-bar" id="statusBar">
                    <asp:Literal ID="LitStatusBar" runat="server" />
                </div>
                <div class="legend-grid" id="statusLegend">
                    <asp:Literal ID="LitStatusLegend" runat="server" />
                </div>
            </div>
            <div class="legend-chip" style="border-top:1px solid rgba(255,255,255,0.06); padding-top:12px; margin-top:4px;">
                <span class="legend-dot" style="background:#8B5CF6;"></span>
                <span class="legend-name">OIT Assets <span style="font-size:11px;opacity:.5;font-weight:400;">(CMR starts with 78)</span></span>
                <asp:Literal ID="LitOitAssets" runat="server" />
            </div>
        </div>

        <!-- Data Completeness -->
        <div class="glass">
            <div class="panel-title">Data Completeness</div>
            <div class="metric-row">
                <span class="metric-name">Missing EIL / CMR (text8)</span>
                <div class="badge-row"><asp:Literal ID="LitMissingEIL" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Missing Location</span>
                <div class="badge-row"><asp:Literal ID="LitMissingLoc" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Missing Status</span>
                <div class="badge-row"><asp:Literal ID="LitMissingStatus" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Turned In &mdash; No CMR</span>
                <div class="badge-row"><asp:Literal ID="LitTurnedInNoCMR" runat="server" /></div>
            </div>
        </div>

        <!-- Inventory Aging -->
        <div class="glass">
            <div class="panel-title">Inventory Aging (Last Inventoried)</div>
            <div class="metric-row">
                <span class="metric-name" style="color:var(--danger);">&#9632; Overdue (&gt;12 months or never inventoried)</span>
                <div class="badge-row"><asp:Literal ID="LitInvOverdue" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name" style="color:var(--warning);">&#9632; 6&ndash;12 Months</span>
                <div class="badge-row"><asp:Literal ID="LitInvM12" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name" style="color:var(--orange);">&#9632; 3&ndash;6 Months</span>
                <div class="badge-row"><asp:Literal ID="LitInvM6" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name" style="color:var(--highlight);">&#9632; 1&ndash;3 Months</span>
                <div class="badge-row"><asp:Literal ID="LitInvM3" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name" style="color:var(--success);">&#9632; Within 1 Month</span>
                <div class="badge-row"><asp:Literal ID="LitInvM1" runat="server" /></div>
            </div>
        </div>

        <!-- Unseen + Maintenance + New -->
        <div class="glass">
            <div class="panel-title">Unseen Assets / Maintenance / New</div>
            <div class="metric-row">
                <span class="metric-name">Unseen &lt;1 Month</span>
                <div class="badge-row"><asp:Literal ID="LitUnseen1" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Unseen 1-3 Months</span>
                <div class="badge-row"><asp:Literal ID="LitUnseen3" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Unseen 3-6 Months</span>
                <div class="badge-row"><asp:Literal ID="LitUnseen6" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Maintenance Overdue</span>
                <div class="badge-row"><asp:Literal ID="LitMaintOv" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">Maintenance Due Next Month</span>
                <div class="badge-row"><asp:Literal ID="LitMaintNM" runat="server" /></div>
            </div>
            <div class="metric-row">
                <span class="metric-name">New Assets: Week / Month / 3Mo / Year</span>
                <div class="badge-row"><asp:Literal ID="LitNewAssets" runat="server" /></div>
            </div>
        </div>

    </div>

    <!-- -- LOCATION TABLE -- -->
    <div class="glass section-gap">
        <div class="panel-title">Assets by Location &mdash; Top 50
            <span style="font-size:12px;font-weight:400;color:var(--text-accent);margin-left:8px;">Click a location name to view its assets below &bull; &#8599; opens in Asset Master</span>
        </div>
        <div class="loc-table-wrap">
            <table class="loc-table" id="locStatsTbl" width="100%">
                <thead>
                    <tr id="locStatsHeaderRow">
                        <th onclick="sortLocTable(0)">Location <span class="sh-si">&#9650;&#9660;</span></th>
                        <th class="td-num" onclick="sortLocTable(1)">Total <span class="sh-si">&#9650;&#9660;</span></th>
                        <th class="td-num" onclick="sortLocTable(2)">Overdue &gt;12m <span class="sh-si">&#9650;&#9660;</span></th>
                        <th class="td-num" onclick="sortLocTable(3)">&lt;1 Mo <span class="sh-si">&#9650;&#9660;</span></th>
                        <th class="td-num" onclick="sortLocTable(4)">1-3 Mo <span class="sh-si">&#9650;&#9660;</span></th>
                        <th class="td-num" onclick="sortLocTable(5)">3-6 Mo <span class="sh-si">&#9650;&#9660;</span></th>
                        <th class="td-num" onclick="sortLocTable(6)">6-12 Mo <span class="sh-si">&#9650;&#9660;</span></th>
                    </tr>
                    <tr id="locStatsFilterRow">
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="0" oninput="filterLocTable()" /></th>
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="1" oninput="filterLocTable()" /></th>
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="2" oninput="filterLocTable()" /></th>
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="3" oninput="filterLocTable()" /></th>
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="4" oninput="filterLocTable()" /></th>
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="5" oninput="filterLocTable()" /></th>
                        <th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="6" oninput="filterLocTable()" /></th>
                    </tr>
                </thead>
                <tbody id="locStatsTbody"><tr><td colspan="7" class="loading-cell">Loading...</td></tr></tbody>
            </table>
        </div>
        <asp:Literal ID="LitLocStatsJson" runat="server" />
    </div>

    <!-- -- LOCATION ASSET DRILL-DOWN PANEL -- -->
    <div id="locAssetPanel" class="glass section-gap" style="display:none;">
        <div class="panel-title" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
            <span>&#128203; <span id="locAssetTitle">Assets in Location</span></span>
            <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
                <a id="locAssetMasterLink" href="#" target="_blank" class="dp-action-btn">&#8599; Open in Asset Master</a>
                <button type="button" class="dp-action-btn" onclick="closeLocPanel()">&#10005; Close</button>
            </div>
        </div>
        <div style="margin-bottom:10px;">
            <div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Columns</div>
            <div id="locColPills" style="display:flex;flex-wrap:wrap;gap:6px;"></div>
        </div>
        <div id="locColFilters" style="display:none;"></div>
        <div id="locAssetStatus" style="font-size:12px;color:var(--muted);margin-bottom:8px;"></div>
        <div class="loc-table-wrap">
            <table class="loc-table" id="locAssetTbl" width="100%">
                <thead><tr id="locAssetThead"></tr></thead>
                <tbody id="locAssetTbody"><tr><td style="padding:20px;text-align:center;color:var(--muted);">Select a location above to view its assets.</td></tr></tbody>
            </table>
        </div>
    </div>


    </div><!-- /as-tab-overview -->

    <!-- TAB 2: DATA QUALITY -->
    <div id="as-tab-quality" class="tab-pane">

        <div class="tab-intro">
            <span class="tab-intro-icon">&#9888;</span>
            <div>
                <p class="tab-intro-title">Data Quality Report</p>
                <p class="tab-intro-body">Shows assets that are incomplete or missing key fields. Use the <strong>Load Records</strong> buttons below to drill into specific problem sets. The quality score table ranks locations from best to worst data completeness (EIL filled + Tagged + In Use = 100 pts).</p>
            </div>
        </div>

        <div class="dq-kpi-row">
            <div class="glass dq-card">
                <div class="dq-val" id="dq-total" style="color:var(--highlight);">--</div>
                <div class="dq-lbl">Total Assets</div>
            </div>
            <div class="glass dq-card">
                <div class="dq-val" id="dq-noeil" style="color:var(--warning);">--</div>
                <div class="dq-lbl">Missing EIL/CMR</div>
            </div>
            <div class="glass dq-card">
                <div class="dq-val" id="dq-noloc" style="color:var(--danger);">--</div>
                <div class="dq-lbl">Missing Location</div>
            </div>
            <div class="glass dq-card" style="cursor:pointer;" onclick="scrollToStalePanel()">
                <div class="dq-val" id="dq-stale" style="color:var(--orange);">--</div>
                <div class="dq-lbl">Stale Import Records</div>
            </div>
        </div>

        <div class="two-col" style="margin-bottom:20px;">
            <div class="glass">
                <div class="panel-title">No EIL/CMR Assigned
                    <button type="button" class="drill-btn" onclick="dqDrill('noeil')">&#8595; Load Records</button>
                </div>
                <p class="dq-empty">Click "Load Records" to preview the first 50 assets missing an EIL or CMR number.</p>
                <div class="tbl-wrap" id="dq-noeil-wrap"></div>
            </div>
            <div class="glass">
                <div class="panel-title">No Location Assigned
                    <button type="button" class="drill-btn" onclick="dqDrill('noloc')">&#8595; Load Records</button>
                </div>
                <p class="dq-empty">Click "Load Records" to preview the first 50 assets with no room/location on file.</p>
                <div class="tbl-wrap" id="dq-noloc-wrap"></div>
            </div>
        </div>

        <div class="glass">
            <div class="panel-title">Top Locations by Data Quality Score (EIL fill + Tagged + In-Use)</div>
            <div class="tbl-wrap">
                <table class="ext-tbl" id="dqLocTbl">
                    <thead>
                        <tr>
                            <th onclick="extSort(this,0,'dqLocTbl')">Location</th>
                            <th class="num" onclick="extSort(this,1,'dqLocTbl')">Total</th>
                            <th class="num" onclick="extSort(this,2,'dqLocTbl')">Has EIL</th>
                            <th class="num" onclick="extSort(this,3,'dqLocTbl')">Tagged</th>
                            <th class="num" onclick="extSort(this,4,'dqLocTbl')">In Use</th>
                            <th onclick="extSort(this,5,'dqLocTbl')">Quality Score</th>
                        </tr>
                    </thead>
                    <tbody id="dqLocBody"><tr><td colspan="6" class="loading-cell">Loading...</td></tr></tbody>
                </table>
            </div>
        </div>

        <!-- -- STALE IMPORT DRILL-DOWN -- -->
        <div class="glass" id="stale-import-panel" style="margin-top:20px;">
            <div class="panel-title" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;">
                <span>&#128465; Stale Import Records &mdash; Never Observed Since Import</span>
                <div style="display:flex;gap:10px;align-items:center;">
                    <span id="stale-count-badge" style="font-size:12px;font-weight:400;color:var(--text-accent);">Loading count...</span>
                    <button type="button" class="drill-btn" id="stale-load-btn" onclick="loadStaleRecords(1)">&#8595; Load Records</button>
                    <button type="button" class="drill-btn" id="stale-export-btn" onclick="exportStaleCSV()" style="background:color-mix(in srgb, var(--accent-2), transparent 85%);color:var(--success);border-color:color-mix(in srgb, var(--accent-2), transparent 55%);">&#128190; Export Excel</button>
                </div>
            </div>

            <!-- Warning banner -->
            <div style="display:flex;align-items:flex-start;gap:12px;padding:12px 16px;background:rgba(249,115,22,.08);border:1px solid rgba(249,115,22,.25);border-radius:10px;margin-bottom:18px;">
                <span style="font-size:22px;flex-shrink:0;">&#9888;</span>
                <div>
                    <div style="font-size:13px;font-weight:700;color:var(--text-main);margin-bottom:4px;">These records were bulk-imported from the VA legacy system and have never been physically scanned.</div>
                    <div style="font-size:12px;color:var(--text-accent);line-height:1.6;">
                        Identified by: <strong style="color:var(--orange);">created = NULL</strong> (no creation date in the system) 
                        + <strong style="color:var(--orange);">lastobservedtime = NULL</strong> (never seen by RFID reader).
                        These are candidates for archival or deletion after admin review.
                    </div>
                </div>
            </div>

            <!-- Pager controls -->
            <div id="stale-pager" style="display:none;margin-bottom:12px;display:flex;align-items:center;gap:12px;flex-wrap:wrap;">
                <button type="button" class="drill-btn" id="stale-prev" onclick="loadStaleRecords(_stalePage-1)" disabled>&#9664; Prev</button>
                <span id="stale-page-info" style="font-size:12px;color:var(--text-accent);"></span>
                <button type="button" class="drill-btn" id="stale-next" onclick="loadStaleRecords(_stalePage+1)">Next &#9654;</button>
                <input class="ext-fi" id="stale-search" placeholder="Filter all columns..." oninput="staleGlobalFilter(this.value)" style="min-width:200px;margin-left:auto;" />
            </div>

            <div class="tbl-wrap" id="stale-tbl-wrap">
                <p class="dq-empty">Click &ldquo;Load Records&rdquo; to review the stale import records. Use Export CSV to download the full list.</p>
            </div>
        </div>

    </div><!-- /quality -->



    <!-- TAB 4: ANALYTICS -->
    <div id="as-tab-analytics" class="tab-pane">

        <div class="tab-intro">
            <span class="tab-intro-icon">&#128202;</span>
            <div>
                <p class="tab-intro-title">Statistical Analytics</p>
                <p class="tab-intro-body">Deeper exploration of the asset population. Charts load automatically. The <strong>Never Inventoried</strong> counter shows assets added to the system but never physically scanned. The <strong>Tag Date vs Inventory Delta</strong> shows how long after tagging an asset gets its first scan. Click any column header in the tables to sort.</p>
            </div>
        </div>

        <!-- Row 1: Category + Scan Velocity -->
        <div class="an-chart-grid">
            <div class="glass">
                <div class="panel-title">Asset Category Breakdown (text4)</div>
                <div class="chart-box"><canvas id="anCatChart"></canvas></div>
            </div>
            <div class="glass">
                <div class="panel-title">Scan Velocity &mdash; Last 12 Months</div>
                <div class="chart-box"><canvas id="anVelChart"></canvas></div>
            </div>
        </div>

        <!-- Row 2: Station Code + Tag-Date Delta -->
        <div class="an-chart-grid">
            <div class="glass">
                <div class="panel-title">Station Code Summary (text7) &mdash; Tagged vs Untagged</div>
                <div class="tbl-wrap" style="max-height:300px;overflow-y:auto;">
                    <table class="ext-tbl" id="anStationTbl">
                        <thead><tr>
                            <th onclick="extSort(this,0,'anStationTbl')">Station</th>
                            <th class="num" onclick="extSort(this,1,'anStationTbl')">Total</th>
                            <th class="num" onclick="extSort(this,2,'anStationTbl')">Tagged</th>
                            <th class="num" onclick="extSort(this,3,'anStationTbl')">Untagged</th>
                            <th onclick="extSort(this,4,'anStationTbl')">% Tagged</th>
                        </tr></thead>
                        <tbody id="anStationBody"><tr><td colspan="5" class="loading-cell">Loading...</td></tr></tbody>
                    </table>
                </div>
            </div>
            <div class="glass">
                <div class="panel-title">Tag Date vs Last Inventory Delta</div>
                <div class="chart-box"><canvas id="anDeltaChart"></canvas></div>
            </div>
        </div>

        <!-- Row 3: Never Inventoried + Top Quality -->
        <div class="an-chart-grid">
            <div class="glass">
                <div class="panel-title">Never Inventoried Assets</div>
                <div style="padding:16px;">
                    <div style="font-size:48px;font-weight:700;color:var(--danger);" id="an-never">--</div>
                    <div style="font-size:12px;color:var(--text-accent);margin:6px 0;">assets have never been scanned since import</div>
                    <div style="font-size:22px;font-weight:600;color:var(--orange);" id="an-never-pct">--%</div>
                    <div style="font-size:12px;color:var(--text-accent);">of total asset population</div>
                </div>
            </div>
            <div class="glass">
                <div class="panel-title">Top Locations by Tagging Completion</div>
                <div class="tbl-wrap" style="max-height:280px;overflow-y:auto;">
                    <table class="ext-tbl" id="anTopLocTbl">
                        <thead><tr>
                            <th onclick="extSort(this,0,'anTopLocTbl')">Location</th>
                            <th class="num" onclick="extSort(this,1,'anTopLocTbl')">Total</th>
                            <th onclick="extSort(this,2,'anTopLocTbl')">% Tagged</th>
                        </tr></thead>
                        <tbody id="anTopLocBody"><tr><td colspan="3" class="loading-cell">Loading...</td></tr></tbody>
                    </table>
                </div>
            </div>
        </div>

    </div><!-- /analytics -->

</div><!-- /dash -->

<aw:Footer runat="server" />
</form>

<script>
// -- Animate KPI values ------------------------------
function animVal(id, target, duration) {
    var el = document.getElementById(id);
    if (!el || isNaN(target)) return;
    var start = 0, t0 = null;
    var fmt = new Intl.NumberFormat();
    function step(t) {
        if (!t0) t0 = t;
        var p = Math.min((t - t0) / duration, 1);
        el.textContent = fmt.format(Math.round(p * target));
        if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
}

document.addEventListener('DOMContentLoaded', function () {
    // Animate top KPIs - pull values from data attributes
    var kpis = document.querySelectorAll('[data-kpi]');
    kpis.forEach(function(el) {
        var v = parseInt(el.getAttribute('data-kpi'), 10);
        animVal(el.id, v, 900);
    });


    // Auto-prefetch all tab data in background after page renders
    // (staggered so they don't all hit the server simultaneously)
    setTimeout(function() {
        if (!window._dqLoaded)  { loadDataQuality();  window._dqLoaded  = true; }
    }, 600);
    setTimeout(function() {
        if (!window._niuLoaded) { loadNotInUse();     window._niuLoaded = true; }
    }, 1200);
    setTimeout(function() {
        if (!window._anLoaded)  { loadAnalytics();    window._anLoaded  = true; }
    }, 1800);
});
</script>

<script>
// --- TAB SYSTEM ---
function switchAsTab(name, btn) {
    document.querySelectorAll('.dash .tab-pane').forEach(function(p){ p.classList.remove('active'); });
    document.querySelectorAll('.tab-pill').forEach(function(b){ b.classList.remove('active'); });
    document.getElementById('as-tab-' + name).classList.add('active');
    btn.classList.add('active');
    if (name === 'quality'   && !window._dqLoaded)  { loadDataQuality();  window._dqLoaded  = true; }
    if (name === 'notinuse'  && !window._niuLoaded) { loadNotInUse();     window._niuLoaded = true; }
    if (name === 'analytics' && !window._anLoaded)  { loadAnalytics();    window._anLoaded  = true; }
}

var _fmt2 = new Intl.NumberFormat();
function getSiteCurrent() {
    var el = document.getElementById('<%= DdlCompany.ClientID %>');
    return el ? el.value : '0';
}
function apiFetchAs(params, cb) {
    var url = 'va_asset_stats.aspx?' + params + '&siteid=' + getSiteCurrent() + '&t=' + Date.now();
    fetch(url)
        .then(function(r) {
            if (!r.ok) throw new Error('HTTP ' + r.status);
            return r.json();
        })
        .then(cb)
        .catch(function(e) {
            console.error('apiFetchAs error:', e);
            // Surface error to any visible loading cells so page doesn't stay stuck
            document.querySelectorAll('.loading-cell').forEach(function(el) {
                if (el.textContent === 'Loading...') el.innerHTML = '<span style="color:#EF4444">Error loading data. See console.</span>';
            });
        });
}
function esc2(s) { return s==null?'':String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// --------------- DATA QUALITY ---------------
function loadDataQuality() {
    apiFetchAs('api=dqstats', function(d) {
        document.getElementById('dq-total').textContent = _fmt2.format(d.Total||0);
        document.getElementById('dq-noeil').textContent = _fmt2.format(d.NoEIL||0);
        document.getElementById('dq-noloc').textContent = _fmt2.format(d.NoLoc||0);
        // Stale import KPI card + badge
        var staleCount = d.StaleImport || 0;
        var staleEl = document.getElementById('dq-stale');
        if (staleEl) staleEl.textContent = _fmt2.format(staleCount);
        var staleBadge = document.getElementById('stale-count-badge');
        if (staleBadge) staleBadge.textContent = _fmt2.format(staleCount) + ' records identified';
        // Quality by location table
        var tbody = document.getElementById('dqLocBody');
        tbody.innerHTML = '';
        (d.LocQuality||[]).forEach(function(r){
            var qs = r.QualityScore || 0;
            var color = qs >= 70 ? 'var(--success)' : qs >= 40 ? 'var(--warning)' : 'var(--danger)';
            var tr = document.createElement('tr');
            tr.innerHTML = '<td>' + esc2(r.Location) + '</td>' +
                '<td class="num">' + _fmt2.format(r.Total) + '</td>' +
                '<td class="num">' + _fmt2.format(r.HasEIL) + '</td>' +
                '<td class="num">' + _fmt2.format(r.Tagged) + '</td>' +
                '<td class="num">' + _fmt2.format(r.InUse) + '</td>' +
                '<td><span style="color:' + color + ';font-weight:700;">' + qs + '</span>' +
                '<div class="prog-bar"><div class="prog-fill" style="width:' + qs + '%;background:' + color + ';"></div></div></td>';
            tbody.appendChild(tr);
        });
    });
}

function dqDrill(type) {
    var wrapId = 'dq-' + type + '-wrap';
    document.getElementById(wrapId).innerHTML = '<div class="loading-cell">Loading...</div>';
    apiFetchAs('api=dqdrill&type=' + type, function(rows) {
        var cols = rows.length > 0 ? Object.keys(rows[0]) : [];
        var html = '<table class="ext-tbl"><thead><tr>' + cols.map(function(c){ return '<th>' + esc2(c) + '</th>'; }).join('') + '</tr></thead><tbody>';
        rows.slice(0,50).forEach(function(r){
            html += '<tr>' + cols.map(function(c){ return '<td>' + esc2(r[c]) + '</td>'; }).join('') + '</tr>';
        });
        html += '</tbody></table>';
        document.getElementById(wrapId).innerHTML = html;
    });
}

// --------------- STALE IMPORT PANEL ---------------
var _stalePage = 1, _stalePageSize = 200, _staleTotal = 0, _staleAllRows = [];

function scrollToStalePanel() {
    switchAsTab('quality', document.getElementById('pill-quality'));
    setTimeout(function() {
        var el = document.getElementById('stale-import-panel');
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 100);
}

function loadStaleRecords(page) {
    _stalePage = page || 1;
    var wrap = document.getElementById('stale-tbl-wrap');
    wrap.innerHTML = '<div class="spin-wrap"><div class="spinner"></div>Loading records&hellip;</div>';

    apiFetchAs('api=staleimport&page=' + _stalePage + '&ps=' + _stalePageSize, function(d) {
        _staleTotal    = d.Total || 0;
        _staleAllRows  = d.Rows  || [];
        renderStaleTable(_staleAllRows);
        updateStalePager();
    });
}

function renderStaleTable(rows) {
    var wrap = document.getElementById('stale-tbl-wrap');
    if (!rows.length) {
        wrap.innerHTML = '<p class="dq-empty">No stale records found for this site.</p>';
        return;
    }

    var COLS = ['AssetTag','Description','Status','CMR','Location','LastInventoried','NameType'];
    var LABELS = ['Asset Tag','Description','Status','CMR / EIL','Location','Last Inventoried','Origin'];

    var html = '<table class="ext-tbl" id="staleTbl"><thead>' +
        '<tr>' + LABELS.map(function(l,i){
            return '<th onclick="extSort(this,' + i + ',\'staleTbl\')">' + l + '</th>';
        }).join('') + '</tr>' +
        '<tr>' + COLS.map(function(c,i){
            return '<th class="filter-th"><input class="ext-fi" placeholder="filter..." oninput="extFilter(\'staleTbl\',this,' + i + ')"/></th>';
        }).join('') + '</tr>' +
        '</thead><tbody>';

    rows.forEach(function(r) {
        var statusColor = r.Status === 'TURNED IN' ? 'var(--warning)' :
                          r.Status === 'IN USE'    ? 'var(--success)' :
                          r.Status === 'LOST OR STOLEN' ? 'var(--danger)' : 'var(--text-accent)';
        var typeColor   = r.NameType === '512 Import' ? 'var(--highlight)' : 'var(--orange)';

        html += '<tr>' +
            '<td style="font-family:monospace;font-size:12px;">' + esc2(r.AssetTag) + '</td>' +
            '<td>' + esc2(r.Description) + '</td>' +
            '<td><span style="color:' + statusColor + ';font-weight:600;">' + esc2(r.Status||'&mdash;') + '</span></td>' +
            '<td style="font-size:12px;">' + esc2(r.CMR||'&mdash;') + '</td>' +
            '<td style="font-size:12px;">' + esc2(r.Location||'&mdash;') + '</td>' +
            '<td style="font-size:11px;color:var(--text-accent);">' + esc2(r.LastInventoried||'Never') + '</td>' +
            '<td><span style="color:' + typeColor + ';font-size:11px;font-weight:600;">' + esc2(r.NameType) + '</span></td>' +
            '</tr>';
    });
    html += '</tbody></table>';
    wrap.innerHTML = html;
}

function updateStalePager() {
    var pager    = document.getElementById('stale-pager');
    var info     = document.getElementById('stale-page-info');
    var prevBtn  = document.getElementById('stale-prev');
    var nextBtn  = document.getElementById('stale-next');
    var totalPages = Math.ceil(_staleTotal / _stalePageSize);

    pager.style.display = 'flex';
    info.textContent    = 'Page ' + _stalePage + ' of ' + totalPages + '  (' + _fmt2.format(_staleTotal) + ' total records)';
    prevBtn.disabled    = (_stalePage <= 1);
    nextBtn.disabled    = (_stalePage >= totalPages);
}

function staleGlobalFilter(val) {
    var v = (val || '').toLowerCase();
    if (!v) { renderStaleTable(_staleAllRows); return; }
    var filtered = _staleAllRows.filter(function(r) {
        return Object.values(r).some(function(fv) {
            return fv && String(fv).toLowerCase().indexOf(v) >= 0;
        });
    });
    renderStaleTable(filtered);
}

function exportStaleCSV() {
    var site = getSiteCurrent();
    var url  = 'va_asset_stats.aspx?api=staleimport&export=1&siteid=' + site + '&t=' + Date.now();
    window.location.href = url;
}


// --------------- NOT IN USE ---------------
var niuChart;
function loadNotInUse() {
    apiFetchAs('api=niustats', function(d) {
        document.getElementById('niu-total').textContent    = _fmt2.format(d.Total||0);
        document.getElementById('niu-statuses').textContent = _fmt2.format(d.UniqueStatuses||0);
        document.getElementById('niu-nostatus').textContent = _fmt2.format(d.NoStatus||0);

        // Pie chart
        var ctx = document.getElementById('niuChart').getContext('2d');
        if (niuChart) niuChart.destroy();
        var pal = ['#F59E0B','#EF4444','#8B5CF6','#F97316','#2EA8FF','#10B981','#EC4899'];
        niuChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: (d.StatusBreakdown||[]).map(function(s){ return s.Status; }),
                datasets: [{ data: (d.StatusBreakdown||[]).map(function(s){ return s.Count; }),
                    backgroundColor: pal, borderWidth: 2, borderColor: '#0B1221' }]
            },
            options: { responsive:true, maintainAspectRatio:false,
                plugins:{ legend:{ position:'right', labels:{ color:'var(--muted)', font:{size:11} } } } }
        });

        // Grid
        var tbody = document.getElementById('niuBody');
        tbody.innerHTML = '';
        (d.Assets||[]).forEach(function(r) {
            var tr = document.createElement('tr');
            tr.innerHTML = '<td>' + esc2(r.AssetTag) + '</td><td>' + esc2(r.Description) + '</td><td>' + esc2(r.EIL_CMR) + '</td><td>' + esc2(r.Location) + '</td>' +
                '<td><span class="b-amber">' + esc2(r.Status||'(none)') + '</span></td><td style="color:var(--text-accent);font-size:12px;">' + esc2(r.Site) + '</td>';
            tbody.appendChild(tr);
        });
        if (!d.Assets||!d.Assets.length) tbody.innerHTML = '<tr><td colspan="6" class="loading-cell">No data found.</td></tr>';
    });
}

// --------------- ANALYTICS ---------------
var anCatChart, anVelChart, anDeltaChart;
var AN_PAL = ['#2EA8FF','#10B981','#8B5CF6','#F59E0B','#F97316','#EF4444','#EC4899','#06B6D4','#84CC16','#A78BFA'];

function loadAnalytics() {
    apiFetchAs('api=analytics', function(d) {
        // Never Inventoried
        document.getElementById('an-never').textContent     = _fmt2.format(d.NeverInventoried||0);
        document.getElementById('an-never-pct').textContent = (d.NeverPct||'0.0') + '%';

        // Category pie
        var ctx1 = document.getElementById('anCatChart').getContext('2d');
        if (anCatChart) anCatChart.destroy();
        anCatChart = new Chart(ctx1, {
            type: 'doughnut',
            data: { labels: (d.Categories||[]).map(function(c){return c.label;}),
                datasets:[{data:(d.Categories||[]).map(function(c){return c.count;}), backgroundColor:AN_PAL, borderWidth:2, borderColor:'#0B1221'}]},
            options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{position:'right',labels:{color:'var(--muted)',font:{size:11}}}}}
        });

        // Scan velocity line
        var ctx2 = document.getElementById('anVelChart').getContext('2d');
        if (anVelChart) anVelChart.destroy();
        anVelChart = new Chart(ctx2, {
            type:'line',
            data:{labels:(d.Velocity||[]).map(function(v){return v.label;}),
                datasets:[{label:'Scans',data:(d.Velocity||[]).map(function(v){return v.count;}),
                borderColor:'#2EA8FF',backgroundColor:'color-mix(in srgb, var(--accent), transparent 92%)',fill:true,tension:.4,pointRadius:4,pointBackgroundColor:'#2EA8FF'}]},
            options:{responsive:true,maintainAspectRatio:false,
                plugins:{legend:{labels:{color:'var(--muted)'}}},
                scales:{x:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.04)'}},y:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.04)'}}}}
        });

        // Tag-date delta donut
        var ctx3 = document.getElementById('anDeltaChart').getContext('2d');
        if (anDeltaChart) anDeltaChart.destroy();
        anDeltaChart = new Chart(ctx3, {
            type:'bar',
            data:{labels:(d.TagDelta||[]).map(function(t){return t.label;}),
                datasets:[{label:'Assets',data:(d.TagDelta||[]).map(function(t){return t.count;}),
                backgroundColor:['#10B981','#2EA8FF','#F59E0B','#F97316','#EF4444']}]},
            options:{responsive:true,maintainAspectRatio:false,indexAxis:'y',
                plugins:{legend:{labels:{color:'var(--muted)'}}},
                scales:{x:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.04)'}},y:{ticks:{color:'var(--muted)'},grid:{color:'rgba(255,255,255,.03)'}}}}
        });

        // Station code table
        var stBody = document.getElementById('anStationBody');
        stBody.innerHTML = '';
        (d.Stations||[]).forEach(function(r){
            var pct = r.Total > 0 ? (r.Tagged / r.Total * 100).toFixed(1) : '0.0';
            var color = pct >= 80 ? 'var(--success)' : pct >= 50 ? 'var(--warning)' : 'var(--danger)';
            var tr = document.createElement('tr');
            tr.innerHTML = '<td>' + esc2(r.Station) + '</td><td class="num">' + _fmt2.format(r.Total) + '</td>' +
                '<td class="num"><span class="b-green">' + _fmt2.format(r.Tagged) + '</span></td>' +
                '<td class="num"><span class="b-red">' + _fmt2.format(r.Untagged) + '</span></td>' +
                '<td><span style="color:' + color + ';font-weight:700;">' + pct + '%</span></td>';
            stBody.appendChild(tr);
        });

        // Top locations by completion
        var locBody = document.getElementById('anTopLocBody');
        locBody.innerHTML = '';
        (d.TopLocations||[]).forEach(function(r){
            var pct = r.Total > 0 ? (r.Tagged / r.Total * 100).toFixed(1) : '0.0';
            var color = pct >= 80 ? 'var(--success)' : pct >= 50 ? 'var(--warning)' : 'var(--danger)';
            var tr = document.createElement('tr');
            tr.innerHTML = '<td>' + esc2(r.Location) + '</td><td class="num">' + _fmt2.format(r.Total) + '</td>' +
                '<td><span style="color:' + color + ';font-weight:700;">' + pct + '%</span>' +
                '<div class="prog-bar"><div class="prog-fill" style="width:' + pct + '%;background:' + color + ';"></div></div></td>';
            locBody.appendChild(tr);
        });
    });
}

// --------------- TABLE HELPERS ---------------
var _extSortState = {};
function extSort(th, colIdx, tblId) {
    var key = tblId+'_'+colIdx;
    var dir = _extSortState[key]==='asc'?'desc':'asc';
    _extSortState[key] = dir;
    var tbody = document.getElementById(tblId).querySelector('tbody');
    var rows = Array.from(tbody.querySelectorAll('tr'));
    rows.sort(function(a,b){
        var ta=a.cells[colIdx]?a.cells[colIdx].innerText.trim():'';
        var tb=b.cells[colIdx]?b.cells[colIdx].innerText.trim():'';
        var na=parseFloat(ta.replace(/,/g,'')),nb=parseFloat(tb.replace(/,/g,''));
        if(!isNaN(na)&&!isNaN(nb)) return dir==='asc'?na-nb:nb-na;
        return dir==='asc'?ta.localeCompare(tb):tb.localeCompare(ta);
    });
    rows.forEach(function(r){tbody.appendChild(r);});
}

var _extFilters = {};
function extFilter(tblId, inp, colIdx) {
    _extFilters[tblId+'_'+colIdx] = (inp.value||'').toLowerCase();
    var rows = document.getElementById(tblId).querySelector('tbody').querySelectorAll('tr');
    rows.forEach(function(r){
        var show = true;
        Object.keys(_extFilters).forEach(function(k){
            if(k.indexOf(tblId)!==0) return;
            var ci=parseInt(k.split('_').pop()), v=_extFilters[k];
            if(!v) return;
            var cell=r.cells[ci];
            if(cell&&(cell.innerText||'').toLowerCase().indexOf(v)<0) show=false;
        });
        r.style.display=show?'':'none';
    });
}
</script>

<script>
// -- LOCATION STATS TABLE (render / filter / sort) --------------------------
var _locData = [];          // full dataset from server
var _locSortCol = 1;        // default sort: Total desc
var _locSortDir = 'desc';

function renderLocStatsTable() {
    _locData = typeof LOC_STATS_DATA !== 'undefined' ? LOC_STATS_DATA : [];
    _renderLocRows(_locData);
}

function _renderLocRows(data) {
    var tbody = document.getElementById('locStatsTbody');
    if (!tbody) return;
    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:20px;color:var(--text-accent);">No location data available.</td></tr>';
        return;
    }
    // Build rows
    var html = '';
    data.forEach(function(r) {
        var loc = r.loc || '';
        var locEnc = encodeURIComponent(loc);
        var locSafe = loc.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
        var href = 'va_asset_master.aspx?location=' + locEnc;
        var overdueCls = r.overdue > 0 ? ' style="color:var(--danger);font-weight:700;"' : '';
        html += '<tr>' +
            '<td>' +
              '<a href="#" onclick="loadLocAssets(\'' + locSafe + '\'); return false;" style="color:var(--accent);text-decoration:none;font-weight:500;" title="Click to view assets below">' + _escHtml(loc) + '</a>' +
              ' <a href="' + href + '" target="_blank" style="color:var(--muted);text-decoration:none;font-size:10px;" title="Open in Asset Master">&#8599;</a>' +
            '</td>' +
            '<td class="td-num">' + r.total + '</td>' +
            '<td class="td-num"' + overdueCls + '>' + r.overdue + '</td>' +
            '<td class="td-num td-good">' + r.m1 + '</td>' +
            '<td class="td-num">' + r.m3 + '</td>' +
            '<td class="td-num">' + r.m6 + '</td>' +
            '<td class="td-num">' + r.m12 + '</td>' +
            '</tr>';
    });
    tbody.innerHTML = html;
}

function _escHtml(s) {
    return (s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function filterLocTable() {
    _applyLocFiltersAndSort();
}

function sortLocTable(colIdx) {
    if (_locSortCol === colIdx) {
        _locSortDir = _locSortDir === 'asc' ? 'desc' : 'asc';
    } else {
        _locSortCol = colIdx;
        _locSortDir = colIdx === 0 ? 'asc' : 'desc'; // text col default asc, numeric desc
    }
    _applyLocFiltersAndSort();
}

// Single function that applies current filters AND current sort — always in sync
function _applyLocFiltersAndSort() {
    var keys = ['loc','total','overdue','m1','m3','m6','m12'];

    // 1. Read filter values from the col-search inputs in the thead filter row
    var filters = {};
    document.querySelectorAll('#locStatsFilterRow .col-search').forEach(function(inp) {
        var v = inp.value.trim().toLowerCase();
        if (v) filters[parseInt(inp.getAttribute('data-col'))] = v;
    });

    // 2. Filter
    var result = _locData.filter(function(r) {
        var vals = [r.loc, r.total, r.overdue, r.m1, r.m3, r.m6, r.m12];
        for (var ci in filters) {
            if (String(vals[ci] == null ? '' : vals[ci]).toLowerCase().indexOf(filters[ci]) < 0) return false;
        }
        return true;
    });

    // 3. Sort
    if (_locSortCol >= 0) {
        var key = keys[_locSortCol] || 'total';
        var dir = _locSortDir;
        result.sort(function(a, b) {
            var av = a[key], bv = b[key];
            if (typeof av === 'number' && typeof bv === 'number')
                return dir === 'asc' ? av - bv : bv - av;
            av = String(av || ''); bv = String(bv || '');
            return dir === 'asc' ? av.localeCompare(bv) : bv.localeCompare(av);
        });
    }

    _renderLocRows(result);
    _updateLocSortIndicators();
}

// Update the ?? indicators in the header row to show active sort column
function _updateLocSortIndicators() {
    var headerRow = document.getElementById('locStatsHeaderRow');
    if (!headerRow) return;
    Array.from(headerRow.cells).forEach(function(th, i) {
        th.classList.remove('sort-asc', 'sort-desc');
        var si = th.querySelector('.sh-si');
        if (si) si.innerHTML = '&#9650;&#9660;';
        if (i === _locSortCol) {
            th.classList.add(_locSortDir === 'asc' ? 'sort-asc' : 'sort-desc');
            if (si) si.innerHTML = _locSortDir === 'asc' ? '&#9650;' : '&#9660;';
        }
    });
}

// Trigger initial render now that all functions are defined
if (typeof LOC_STATS_DATA !== 'undefined') {
    renderLocStatsTable();
}

// ----------------------------------------------------------------------
// LOCATION ASSET DRILL-DOWN
// ----------------------------------------------------------------------
var LOC_ASSET_COLS = [
    { key: 'name',            label: 'Asset Name',       visible: true  },
    { key: 'description',     label: 'Description',      visible: false },
    { key: 'locationname',    label: 'Location',         visible: true  },
    { key: 'text8',           label: 'CMR',              visible: true  },
    { key: 'listvalue1',      label: 'Status',           visible: true  },
    { key: 'text4',           label: 'Category',         visible: true  },
    { key: 'text1',           label: 'Manufacturer',     visible: true  },
    { key: 'text2',           label: 'Model',            visible: false },
    { key: 'text3',           label: 'Serial #',         visible: false },
    { key: 'text5',           label: 'Service',          visible: false },
    { key: 'text6',           label: 'Room',             visible: false },
    { key: 'text7',           label: 'Station',          visible: false },
    { key: 'text9',           label: 'PO #',             visible: false },
    { key: 'text11',          label: 'Prev Location',    visible: false },
    { key: 'lastinventoried', label: 'Last Inventoried', visible: true  },
    { key: 'daysSince',       label: 'Days Since',       visible: false },
    { key: 'text18',          label: 'Tagged',           visible: false }
];
try { var _laSaved = localStorage.getItem('LocAssetCols'); if (_laSaved) { var _laParsed = JSON.parse(_laSaved); if (_laParsed.length === LOC_ASSET_COLS.length) LOC_ASSET_COLS = _laParsed; } } catch(e) {}

var _laData = [], _laFiltered = [], _laSortCol = null, _laSortDir = 'asc', _laFilterTimer = null, _laColFilters = {};

function saveLocAssetCols() { try { localStorage.setItem('LocAssetCols', JSON.stringify(LOC_ASSET_COLS)); } catch(e) {} }
function getLocVisibleCols() { return LOC_ASSET_COLS.filter(function(c){ return c.visible; }); }

function buildLocColChooser() {
    var c = document.getElementById('locColPills'); c.innerHTML = '';
    LOC_ASSET_COLS.forEach(function(col, i) {
        var lbl = document.createElement('label');
        lbl.className = 'col-toggle' + (col.visible ? ' active' : '');
        lbl.innerHTML = '<input type="checkbox"' + (col.visible ? ' checked' : '') + '> ' + col.label;
        lbl.querySelector('input').addEventListener('change', function() {
            LOC_ASSET_COLS[i].visible = this.checked;
            lbl.classList.toggle('active', this.checked);
            saveLocAssetCols();
            renderLocAssetRows(); // filter inputs rebuild inside thead
        });
        c.appendChild(lbl);
    });
}

// No-op kept for any residual callers
function buildLocColFilters() {}

function laColFilterInput(el) {
    var k = el.getAttribute('data-col');
    var v = el.value.trim();
    if (v) { _laColFilters[k] = v; } else { delete _laColFilters[k]; }
    clearTimeout(_laFilterTimer);
    _laFilterTimer = setTimeout(applyLocAssetFilter, 300);
}

function applyLocAssetFilter() {
    _laFiltered = _laData.filter(function(row) {
        for (var k in _laColFilters) {
            if (String(row[k] || '').toLowerCase().indexOf(_laColFilters[k].toLowerCase()) < 0) return false;
        }
        return true;
    });
    renderLocAssetRows(); // rebuilds thead + tbody, restoring filter values from _laColFilters
    var st = document.getElementById('locAssetStatus');
    if (st) st.textContent = _laFiltered.length + ' of ' + _laData.length + ' asset(s)';
}

function loadLocAssets(locName) {
    var panel = document.getElementById('locAssetPanel');
    var tbody = document.getElementById('locAssetTbody');
    var status = document.getElementById('locAssetStatus');
    var locEnc = encodeURIComponent(locName);
    document.getElementById('locAssetTitle').textContent = 'Assets in ' + locName;
    document.getElementById('locAssetMasterLink').href = 'va_asset_master.aspx?location=' + locEnc;
    panel.style.display = '';
    tbody.innerHTML = '<tr><td colspan="20" style="text-align:center;padding:20px;color:var(--accent);">&#8635; Loading assets...</td></tr>';
    status.textContent = '';
    panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
    $.ajax({
        type: 'POST', url: 'va_asset_master.aspx/SearchAssets',
        contentType: 'application/json; charset=utf-8',
        data: JSON.stringify({ draw:1, start:0, length:5000, search:'', site:'0', status:'', cmr:'', location:locName, days:'', fixedReader:'', sortCol:'name', sortDir:'asc', colSearch:{} }),
        success: function(resp) {
            var result = JSON.parse(resp.d);
            _laData = result.data || [];
            _laFiltered = _laData.slice();
            _laSortCol = null; _laSortDir = 'asc'; _laColFilters = {};
            buildLocColChooser();
            renderLocAssetRows();
            status.textContent = _laData.length + ' asset(s) in this location';
        },
        error: function() {
            tbody.innerHTML = '<tr><td colspan="20" style="text-align:center;padding:20px;color:var(--danger);">Failed to load assets.</td></tr>';
        }
    });
}

function sortLocAssets(colKey) {
    if (_laSortCol === colKey) { _laSortDir = _laSortDir === 'asc' ? 'desc' : 'asc'; }
    else { _laSortCol = colKey; _laSortDir = 'asc'; }
    renderLocAssetRows();
}

function renderLocAssetRows() {
    var thead = document.getElementById('locAssetThead');
    var tbody = document.getElementById('locAssetTbody');
    var vis = getLocVisibleCols();
    // -- Row 1: sortable column labels (same as Asset Master header row) --
    var hh = '';
    vis.forEach(function(col) {
        var ind = (_laSortCol === col.key) ? (_laSortDir === 'asc' ? ' &#8593;' : ' &#8595;') : ' <span style="opacity:.3;">&#8597;</span>';
        hh += '<th onclick="sortLocAssets(\'' + col.key + '\')" style="cursor:pointer;white-space:nowrap;">' + col.label + ind + '</th>';
    });
    // -- Row 2: per-column col-search inputs (matches Asset Master filter row) --
    var fh = '';
    vis.forEach(function(col) {
        var savedVal = (_laColFilters[col.key] || '').replace(/"/g, '&quot;');
        fh += '<th style="padding:2px 4px;"><input class="col-search" type="text" placeholder="..." data-col="' + col.key + '" value="' + savedVal + '" oninput="laColFilterInput(this)" /></th>';
    });
    thead.innerHTML = '<tr>' + hh + '</tr><tr id="la-search-row">' + fh + '</tr>';
    // -- Sort --
    var rows = _laFiltered.slice();
    if (_laSortCol) {
        var k = _laSortCol, d = _laSortDir;
        rows.sort(function(a,b) {
            var av = a[k]||'', bv = b[k]||'';
            if (typeof av==='number'&&typeof bv==='number') return d==='asc'?av-bv:bv-av;
            return d==='asc'?String(av).localeCompare(String(bv)):String(bv).localeCompare(String(av));
        });
    }
    if (!rows.length) { tbody.innerHTML = '<tr><td colspan="'+vis.length+'" style="text-align:center;padding:20px;color:var(--muted);">No assets found.</td></tr>'; return; }
    var html = '';
    rows.forEach(function(row) {
        var nm = (row.name||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");
        html += '<tr onclick="laSelectRow(this,' + (row.id||0) + ',\'' + nm + '\')">'; 
        vis.forEach(function(col) {
            var val = row[col.key];
            if (col.key === 'name') html += '<td><strong style="color:var(--accent);">' + _escHtml(String(val||'')) + '</strong></td>';
            else if ((col.key==='lastinventoried'||col.key==='date1')&&val) html += '<td>' + laFmtDateShort(val) + '</td>';
            else html += '<td>' + _escHtml(String(val||'')) + '</td>';
        });
        html += '</tr>';
    });
    tbody.innerHTML = html;
}

function laSelectRow(tr, id, name) {
    document.querySelectorAll('#locAssetTbody tr').forEach(function(r){ r.classList.remove('la-selected'); });
    tr.classList.add('la-selected');
    openDetail(id, name);
}

function laFmtDateShort(val) {
    if (!val) return '';
    var m = String(val).match(/\/Date\((-?\d+)\)\//);
    var d = m ? new Date(parseInt(m[1])) : new Date(val);
    if (isNaN(d.getTime())) return String(val);
    return ('0'+(d.getMonth()+1)).slice(-2)+'/'+('0'+d.getDate()).slice(-2)+'/'+d.getFullYear();
}

function closeLocPanel() {
    document.getElementById('locAssetPanel').style.display = 'none';
    _laData = []; _laFiltered = [];
    closeDetail();
}

// ----------------------------------------------------------------------
// ASSET DETAIL PANEL  (reuses va_asset_master.aspx GET endpoints)
// ----------------------------------------------------------------------
var _dpCurrentId = null, _dpCache = {}, _dpEditMode = false, _dpOriginal = {};
var STATUS_OPTIONS = ['IN USE','TURNED IN','LOST OR STOLEN','OUT OF SERVICE','LOANED OUT','In Service'];
var CHECKOUT_OPTIONS = ['Checked In','Checked Out'];

function openDetail(assetId, assetName) {
    _dpCurrentId = assetId; _dpCache = {};
    document.getElementById('dpTitle').textContent = assetName || 'Asset Detail';
    document.getElementById('dpEditLink').href = '/#!/admin/editasset/' + assetId;
    ['badgeLoc','badgeCO','badgeMnt','badgeChild'].forEach(function(id){ document.getElementById(id).textContent = '\u2014'; });
    document.querySelectorAll('.dp-tab').forEach(function(t){ t.classList.remove('active'); });
    document.querySelector('.dp-tab[data-tab="general"]').classList.add('active');
    document.querySelectorAll('.dp-tab-content').forEach(function(c){ c.classList.remove('active'); });
    document.getElementById('tab-general').classList.add('active');
    document.getElementById('detailPanel').classList.add('open');
    document.body.classList.add('detail-open');
    loadGeneralTab(assetId);
    loadTabCounts(assetId);
}
function closeDetail() {
    document.getElementById('detailPanel').classList.remove('open');
    document.body.classList.remove('detail-open');
    document.querySelectorAll('#locAssetTbody tr').forEach(function(r){ r.classList.remove('la-selected'); });
    _dpCurrentId = null;
}
document.addEventListener('keydown', function(e){ if(e.key==='Escape'&&_dpCurrentId) closeDetail(); });
function switchTab(btn) {
    var tab = btn.getAttribute('data-tab');
    document.querySelectorAll('.dp-tab').forEach(function(t){ t.classList.remove('active'); }); btn.classList.add('active');
    document.querySelectorAll('.dp-tab-content').forEach(function(c){ c.classList.remove('active'); }); document.getElementById('tab-'+tab).classList.add('active');
    if (!_dpCache[tab]) { switch(tab) { case 'general': loadGeneralTab(_dpCurrentId); break; case 'lochistory': loadLocationHistory(_dpCurrentId); break; case 'checkout': loadCheckoutHistory(_dpCurrentId); break; case 'maintenance': loadMaintenanceHistory(_dpCurrentId); break; case 'children': loadChildren(_dpCurrentId); break; } }
}
function fmtDate(val) { if(!val) return ''; var m=String(val).match(/\/Date\((-?\d+)\)\//);
    var d=m?new Date(parseInt(m[1])):new Date(val); if(isNaN(d.getTime())) return String(val);
    return ('0'+(d.getMonth()+1)).slice(-2)+'/'+('0'+d.getDate()).slice(-2)+'/'+d.getFullYear()+' '+('0'+d.getHours()).slice(-2)+':'+('0'+d.getMinutes()).slice(-2); }
function fmtDateShort(val) { if(!val) return ''; var m=String(val).match(/\/Date\((-?\d+)\)\//);
    var d=m?new Date(parseInt(m[1])):new Date(val); if(isNaN(d.getTime())) return String(val);
    return ('0'+(d.getMonth()+1)).slice(-2)+'/'+('0'+d.getDate()).slice(-2)+'/'+d.getFullYear(); }
function dpVal(v) { if(v===null||v===undefined||v==='') return '<span class="empty">\u2014</span>'; return String(v).replace(/</g,'&lt;'); }
var _dpEditMode2=false;
function dpField(label,value,editKey) {
    var cls=(value===null||value===undefined||value==='')?'dp-val empty':'dp-val';
    var display=(value===null||value===undefined||value==='')?'\u2014':String(value).replace(/</g,'&lt;');
    var safeVal=(value===null||value===undefined)?'':String(value).replace(/"/g,'&quot;');
    if(_dpEditMode&&editKey){
        _dpOriginal[editKey]=safeVal;
        if(editKey==='listvalue1'){ var opts='<option value="">\u2014 None \u2014</option>'; STATUS_OPTIONS.forEach(function(s){ opts+='<option value="'+s+'"'+(s===safeVal?' selected':'')+'>'+s+'</option>'; }); return '<div class="dp-field" data-key="'+editKey+'"><label>'+label+'</label><select class="dp-select" data-key="'+editKey+'" onchange="markDirty(this)">'+opts+'</select></div>'; }
        if(editKey==='checkinstatus'){ var opts='<option value="">\u2014 None \u2014</option>'; CHECKOUT_OPTIONS.forEach(function(s){ opts+='<option value="'+s+'"'+(s===safeVal?' selected':'')+'>'+s+'</option>'; }); return '<div class="dp-field" data-key="'+editKey+'"><label>'+label+'</label><select class="dp-select" data-key="'+editKey+'" onchange="markDirty(this)">'+opts+'</select></div>'; }
        if(editKey==='additionalinformation') return '<div class="dp-field" data-key="'+editKey+'"><label>'+label+'</label><textarea class="dp-textarea" data-key="'+editKey+'" oninput="markDirty(this)">'+safeVal+'</textarea></div>';
        return '<div class="dp-field" data-key="'+editKey+'"><label>'+label+'</label><input class="dp-input" type="text" data-key="'+editKey+'" value="'+safeVal+'" oninput="markDirty(this)" /></div>';
    }
    return '<div class="dp-field"><label>'+label+'</label><div class="'+cls+'">'+display+'</div></div>';
}
function markDirty(el) { var k=el.getAttribute('data-key'),orig=_dpOriginal[k]||'',f=el.closest('.dp-field'); f.classList.toggle('dirty',el.value!==orig); updateDirtyCount(); }
function updateDirtyCount() { var n=document.querySelectorAll('#tab-general .dp-field.dirty').length; document.getElementById('dpDirtyCount').textContent=n; document.getElementById('dpSaveBar').classList.toggle('show',n>0); }
function loadGeneralTab(assetId) {
    var el=document.getElementById('tab-general'); el.innerHTML='<div class="dp-loading">Loading...</div>'; _dpOriginal={};
    $.getJSON('va_asset_master.aspx?api=detail&id='+assetId,function(data){ if(data.error){el.innerHTML='<div class="dp-empty">'+data.error+'</div>';return;} _dpCache.general=data.asset; renderGeneralTab(data.asset); }).fail(function(){ el.innerHTML='<div class="dp-empty">Failed to load asset details.</div>'; });
}
function renderGeneralTab(a) {
    var el=document.getElementById('tab-general'); _dpOriginal={}; var h='';
    h+='<div class="dp-field-group"><div class="dp-field-group-title">Identity</div><div class="dp-fields">';
    h+=dpField('Asset Name',a.name)+dpField('Description',a.description,'description')+dpField('Asset Type',a.assettype)+dpField('RFID Tag',a.rfidtag)+dpField('CMR #',a.text8,'text8')+dpField('Serial #',a.text3,'text3');
    h+='</div></div>';
    h+='<div class="dp-field-group"><div class="dp-field-group-title">Location</div><div class="dp-fields">';
    h+=dpField('Current Location',a.locationname)+dpField('Building',a.locationbuilding)+dpField('Floor',a.locationfloor)+dpField('Room',a.locationroom)+dpField('Last Observed Location',a.lastobservedlocation)+dpField('Last Observed Time',fmtDate(a.lastobservedtime))+dpField('Nearest Fixed Reader',a.nearestfixedname)+dpField('Department Code',a.departmentcode,'departmentcode');
    h+='</div></div>';
    h+='<div class="dp-field-group"><div class="dp-field-group-title">Status &amp; Checkout</div><div class="dp-fields">';
    h+=dpField('Status',a.listvalue1,'listvalue1')+dpField('Checkout Status',a.checkinstatus,'checkinstatus')+dpField('Checked Out To',a.checkedoutto,'checkedoutto')+dpField('Disposal Status',a.disposalstatus,'disposalstatus');
    h+='</div></div>';
    h+='<div class="dp-field-group"><div class="dp-field-group-title">Details</div><div class="dp-fields">';
    h+=dpField('Category',a.text4,'text4')+dpField('Manufacturer',a.text1,'text1')+dpField('Model',a.text2,'text2')+dpField('Service',a.text5,'text5')+dpField('Room',a.text6,'text6')+dpField('Station',a.text7,'text7')+dpField('PO #',a.text9,'text9')+dpField('Previous Location',a.text11,'text11');
    h+='</div></div>';
    h+='<div class="dp-field-group"><div class="dp-field-group-title">Inventory &amp; Dates</div><div class="dp-fields">';
    h+=dpField('Last Inventoried',fmtDateShort(a.lastinventoried))+dpField('Created',fmtDate(a.created))+dpField('Last Modified',fmtDate(a.lastmodified))+dpField('Modified By',a.lastmodifiedby);
    h+='</div></div>';
    if(a.vtagid){h+='<div class="dp-field-group"><div class="dp-field-group-title">V-Tag Sensor</div><div class="dp-fields">'+dpField('V-Tag ID',a.vtagid)+dpField('V-Tag Type',a.vtagtype)+dpField('Battery Level',a.batterylevel?a.batterylevel+'%':null)+'</div></div>';}
    h+='<div class="dp-field-group"><div class="dp-field-group-title">Additional Information</div><div class="dp-fields single">'+dpField('Notes',a.additionalinformation,'additionalinformation')+'</div></div>';
    el.innerHTML=h; updateDirtyCount();
}
function toggleEditMode(){ _dpEditMode=!_dpEditMode; var btn=document.getElementById('dpEditToggle'); btn.classList.toggle('editing',_dpEditMode); btn.innerHTML=_dpEditMode?'&#10004; Editing':'&#9998; Edit Mode'; if(_dpCache.general) renderGeneralTab(_dpCache.general); if(!_dpEditMode) document.getElementById('dpSaveBar').classList.remove('show'); }
function cancelEdit(){ _dpEditMode=false; document.getElementById('dpEditToggle').classList.remove('editing'); document.getElementById('dpEditToggle').innerHTML='&#9998; Edit Mode'; document.getElementById('dpSaveBar').classList.remove('show'); if(_dpCache.general) renderGeneralTab(_dpCache.general); }
function saveAsset(){
    if(!_dpCurrentId) return;
    var dirty=document.querySelectorAll('#tab-general .dp-field.dirty'); if(!dirty.length) return;
    var updates={}; dirty.forEach(function(f){ var inp=f.querySelector('.dp-input,.dp-select,.dp-textarea'); if(inp) updates[inp.getAttribute('data-key')]=inp.value; });
    var btn=document.getElementById('dpSaveBtn'); btn.disabled=true; btn.textContent='Saving...';
    $.ajax({ type:'POST', url:'va_asset_master.aspx?api=update&id='+_dpCurrentId, contentType:'application/json', data:JSON.stringify(updates), dataType:'json',
        success:function(resp){ if(resp.error){showDpToast(resp.error,'error');}else{ showDpToast('Saved \u2014 '+resp.updated+' field(s) updated','success'); for(var k in updates) _dpCache.general[k]=updates[k]; _dpEditMode=false; document.getElementById('dpEditToggle').classList.remove('editing'); document.getElementById('dpEditToggle').innerHTML='&#9998; Edit Mode'; document.getElementById('dpSaveBar').classList.remove('show'); renderGeneralTab(_dpCache.general); } btn.disabled=false; btn.innerHTML='&#128190; Save Changes'; },
        error:function(){ showDpToast('Network error - save failed','error'); btn.disabled=false; btn.innerHTML='&#128190; Save Changes'; }
    });
}
function showDpToast(msg,type){ var t=document.createElement('div'); t.className='dp-save-toast '+(type||'success'); t.textContent=msg; document.body.appendChild(t); setTimeout(function(){t.remove();},3000); }
function loadTabCounts(assetId){
    $.getJSON('va_asset_master.aspx?api=locationhistory&id='+assetId,function(d){ document.getElementById('badgeLoc').textContent=d.total||0; if(d.total>0)_dpCache.lochistory_data=d.records; });
    $.getJSON('va_asset_master.aspx?api=checkouthistory&id='+assetId,function(d){ document.getElementById('badgeCO').textContent=d.total||0; if(d.total>0)_dpCache.checkout_data=d.records; });
    $.getJSON('va_asset_master.aspx?api=maintenance&id='+assetId,function(d){ document.getElementById('badgeMnt').textContent=d.total||0; if(d.total>0)_dpCache.maintenance_data=d.records; });
    $.getJSON('va_asset_master.aspx?api=children&id='+assetId,function(d){ document.getElementById('badgeChild').textContent=d.total||0; if(d.total>0)_dpCache.children_data=d.records; });
}
function loadLocationHistory(assetId){ var el=document.getElementById('tab-lochistory'),rec=_dpCache.lochistory_data; if(rec){renderLocationHistory(el,rec);_dpCache.lochistory=true;return;} el.innerHTML='<div class="dp-loading">Loading...</div>'; $.getJSON('va_asset_master.aspx?api=locationhistory&id='+assetId,function(d){renderLocationHistory(el,d.records||[]);_dpCache.lochistory=true;}); }
function renderLocationHistory(el,recs){ if(!recs||!recs.length){el.innerHTML='<div class="dp-empty"><span class="dp-empty-icon">&#128205;</span>No location history.</div>';return;} var h='<table class="dp-history-table"><thead><tr><th>Location</th><th>Building</th><th>Time Seen</th><th>Time Left</th></tr></thead><tbody>'; recs.forEach(function(r){h+='<tr><td><strong>'+dpVal(r.locationname)+'</strong></td><td>'+dpVal(r.building)+'</td><td>'+fmtDate(r.timeseen)+'</td><td>'+fmtDate(r.timeleft)+'</td></tr>';}); el.innerHTML=h+'</tbody></table>'; }
function loadCheckoutHistory(assetId){ var el=document.getElementById('tab-checkout'),rec=_dpCache.checkout_data; if(rec){renderCheckoutHistory(el,rec);_dpCache.checkout=true;return;} el.innerHTML='<div class="dp-loading">Loading...</div>'; $.getJSON('va_asset_master.aspx?api=checkouthistory&id='+assetId,function(d){renderCheckoutHistory(el,d.records||[]);_dpCache.checkout=true;}); }
function renderCheckoutHistory(el,recs){ if(!recs||!recs.length){el.innerHTML='<div class="dp-empty"><span class="dp-empty-icon">&#128100;</span>No checkout history.</div>';return;} var h='<table class="dp-history-table"><thead><tr><th>Status</th><th>Individual</th><th>Location</th><th>Date</th></tr></thead><tbody>'; recs.forEach(function(r){var cls=r.checkinstatus==='Checked Out'?'pct-warn':'pct-good';h+='<tr><td><span class="'+cls+'">'+dpVal(r.checkinstatus)+'</span></td><td>'+dpVal(r.individual)+'</td><td>'+dpVal(r.locationname)+'</td><td>'+fmtDate(r.transactiontime)+'</td></tr>';}); el.innerHTML=h+'</tbody></table>'; }
function loadMaintenanceHistory(assetId){ var el=document.getElementById('tab-maintenance'),rec=_dpCache.maintenance_data; if(rec){renderMaintenanceHistory(el,rec);_dpCache.maintenance=true;return;} el.innerHTML='<div class="dp-loading">Loading...</div>'; $.getJSON('va_asset_master.aspx?api=maintenance&id='+assetId,function(d){renderMaintenanceHistory(el,d.records||[]);_dpCache.maintenance=true;}); }
function renderMaintenanceHistory(el,recs){ if(!recs||!recs.length){el.innerHTML='<div class="dp-empty"><span class="dp-empty-icon">&#128295;</span>No maintenance records.</div>';return;} var h='<table class="dp-history-table"><thead><tr><th>Date</th><th>Action</th><th>Performed By</th><th>Notes</th></tr></thead><tbody>'; recs.forEach(function(r){h+='<tr><td>'+fmtDate(r.whenperformed)+'</td><td><strong>'+dpVal(r.actionperformed)+'</strong></td><td>'+dpVal(r.performedby)+'</td><td>'+dpVal(r.notes)+'</td></tr>';}); el.innerHTML=h+'</tbody></table>'; }
function loadChildren(assetId){ var el=document.getElementById('tab-children'),rec=_dpCache.children_data; if(rec){renderChildren(el,rec);_dpCache.children=true;return;} el.innerHTML='<div class="dp-loading">Loading...</div>'; $.getJSON('va_asset_master.aspx?api=children&id='+assetId,function(d){renderChildren(el,d.records||[]);_dpCache.children=true;}); }
function renderChildren(el,recs){ if(!recs||!recs.length){el.innerHTML='<div class="dp-empty"><span class="dp-empty-icon">&#128279;</span>No child assets.</div>';return;} var h='<table class="dp-history-table"><thead><tr><th>Name</th><th>Description</th><th>Location</th><th>Status</th></tr></thead><tbody>'; recs.forEach(function(r){h+='<tr style="cursor:pointer;" onclick="openDetail('+r.id+',\''+(r.name||'').replace(/\'/g,"\\'")+'\')" ><td><strong style="color:var(--accent);">'+dpVal(r.name)+'</strong></td><td>'+dpVal(r.description)+'</td><td>'+dpVal(r.locationname)+'</td><td>'+dpVal(r.listvalue1)+'</td></tr>';}); el.innerHTML=h+'</tbody></table>'; }
</script>

<!-- -- ASSET DETAIL PANEL (identical to Asset Master) -- -->
<div class="detail-panel" id="detailPanel">
    <div class="dp-header">
        <h2><span class="dp-icon">&#128203;</span> <span id="dpTitle">Asset Detail</span></h2>
        <button type="button" class="dp-close" onclick="closeDetail()">&times;</button>
    </div>
    <div class="dp-actions">
        <button type="button" id="dpEditToggle" class="dp-edit-toggle" onclick="toggleEditMode()">&#9998; Edit Mode</button>
        <a id="dpEditLink" href="#" target="_blank" class="dp-action-btn">&#8599; Open in iDash</a>
    </div>
    <div class="dp-tabs">
        <button type="button" class="dp-tab active" data-tab="general" onclick="switchTab(this)">General</button>
        <button type="button" class="dp-tab" data-tab="lochistory" onclick="switchTab(this)">Location History <span class="tab-badge" id="badgeLoc">&mdash;</span></button>
        <button type="button" class="dp-tab" data-tab="checkout" onclick="switchTab(this)">Checkout <span class="tab-badge" id="badgeCO">&mdash;</span></button>
        <button type="button" class="dp-tab" data-tab="maintenance" onclick="switchTab(this)">Maintenance <span class="tab-badge" id="badgeMnt">&mdash;</span></button>
        <button type="button" class="dp-tab" data-tab="children" onclick="switchTab(this)">Children <span class="tab-badge" id="badgeChild">&mdash;</span></button>
    </div>
    <div class="dp-body">
        <div class="dp-tab-content active" id="tab-general"></div>
        <div class="dp-tab-content" id="tab-lochistory"></div>
        <div class="dp-tab-content" id="tab-checkout"></div>
        <div class="dp-tab-content" id="tab-maintenance"></div>
        <div class="dp-tab-content" id="tab-children"></div>
    </div>
    <div class="dp-save-bar" id="dpSaveBar">
        <div class="dp-save-info"><span id="dpDirtyCount">0</span> field(s) changed</div>
        <div class="dp-save-btns">
            <button type="button" class="dp-save-btn cancel" onclick="cancelEdit()">Discard</button>
            <button type="button" class="dp-save-btn save" id="dpSaveBtn" onclick="saveAsset()">&#128190; Save Changes</button>
        </div>
    </div>
</div>

<script type="text/javascript">
// -- SITE PERSISTENCE (shared across Asset Master / Stats / Locations) --
(function () {
    var SITE_KEY = 'iDash_selectedSite';
    var ddl = document.getElementById('<%= DdlCompany.ClientID %>');
    if (!ddl) return;
    // Save immediately when user changes the site (before PostBack fires)
    ddl.addEventListener('change', function () {
        try { localStorage.setItem(SITE_KEY, this.value); } catch (e) {}
    });
    // On first page load: if server rendered "All Sites" but localStorage has a preference, restore it
    if (ddl.value === '0' || ddl.value === '') {
        try {
            var saved = localStorage.getItem(SITE_KEY);
            if (saved && saved !== '0' && saved !== '') {
                ddl.value = saved;
                if (ddl.value === saved) { // confirm the option actually exists in the list
                    __doPostBack('<%= DdlCompany.UniqueID %>', '');
                }
            }
        } catch (e) {}
    }
})();
</script>

</body>
</html>

