<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_location_list.aspx.cs" Inherits="va_location_list" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
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

    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--bg); color: var(--text);
            font-family: 'Segoe UI', Tahoma, sans-serif; font-size: 14px;
            min-height: 100vh;
        }

        /* -- HEADER BAR -- */
        .page-header {
            background: var(--card);
            border-bottom: 1px solid var(--line);
            padding: 12px 28px;
            display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0; z-index: 100;
        }
        .page-header h1 {
            margin: 0; font-size: 20px; font-weight: 700; color: var(--text);
        }
        .header-right { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }

        .dash { max-width: 1440px; margin: 0 auto; padding: 20px 24px; }

        /* -- KPI -- */
        .kpi-row { display: grid; grid-template-columns: repeat(5, 1fr); gap: 14px; margin-bottom: 18px; }
        @media(max-width:1100px) { .kpi-row { grid-template-columns: repeat(3, 1fr); } }
        @media(max-width:640px) { .kpi-row { grid-template-columns: repeat(2, 1fr); } }

        .kpi-card {
            background: var(--card); border: 1px solid var(--line);
            border-radius: 12px; padding: 20px 14px; text-align: center;
            transition: border-color .2s;
        }
        .kpi-card:hover { border-color: var(--accent); }
        .kpi-value { font-size: 32px; font-weight: 700; line-height: 1; margin-bottom: 4px; }
        .kpi-pct   { font-size: 13px; font-weight: 600; margin-bottom: 2px; }
        .kpi-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .6px; color: var(--muted); }

        /* -- GLASS CARD -- */
        .glass {
            background: var(--card); border: 1px solid var(--line);
            border-radius: 12px; padding: 20px 24px; margin-bottom: 18px;
        }
        .panel-title {
            font-size: 12px; font-weight: 600; color: var(--muted);
            text-transform: uppercase; letter-spacing: .7px;
            border-bottom: 1px solid var(--line);
            padding-bottom: 10px; margin-bottom: 14px;
            display: flex; justify-content: space-between; align-items: center;
        }

        /* -- AGE BAR -- */
        .age-bar { display: flex; height: 12px; border-radius: 6px; overflow: hidden; margin: 8px 0 12px; background: var(--chip); }
        .age-seg { height: 100%; transition: width .6s ease; }
        .bar-legend { display: flex; flex-wrap: wrap; gap: 8px; }
        .bar-chip {
            display: inline-flex; align-items: center; gap: 5px; font-size: 12px;
            background: var(--chip); border: 1px solid var(--line);
            padding: 4px 10px; border-radius: 20px;
        }
        .chip-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

        /* -- CONTROLS -- */
        .ctrl-bar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-bottom: 14px; }
        .ctrl-label { font-size: 13px; color: var(--muted); font-weight: 600; }
        .ctrl-select, .ctrl-input {
            background: var(--card); color: var(--text);
            border: 1px solid var(--line); padding: 7px 12px;
            border-radius: 6px; font-size: 13px; outline: none;
        }
        .ctrl-select option { background: var(--card); }
        .ctrl-input::placeholder { color: var(--muted); opacity: 0.5; }
        .ctrl-input:focus, .ctrl-select:focus { border-color: var(--accent); outline: 2px solid rgba(46, 168, 255, 0.15); outline-offset: -1px; }

        .sep { width: 1px; height: 24px; background: var(--line); }

        /* -- BUTTONS -- */
        .btn-action {
            background: var(--accent); color: #fff; border: none;
            padding: 7px 16px; border-radius: 6px; cursor: pointer;
            font-size: 13px; font-weight: 600; transition: opacity .2s;
        }
        .btn-action:hover { opacity: 0.9; }

        .btn-secondary {
            background: var(--chip); color: var(--text); border: 1px solid var(--line);
            padding: 7px 14px; border-radius: 6px; cursor: pointer;
            font-size: 13px; font-weight: 500; transition: .2s;
        }
        .btn-secondary:hover { border-color: var(--accent); }

        .age-btn {
            padding: 5px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;
            cursor: pointer; border: 1px solid transparent; transition: all .2s; text-decoration: none;
        }
        .age-btn:hover { opacity: .85; }

        /* -- TABLES -- */
        .tbl-wrap { overflow-x: auto; }
        .loc-tbl, .detail-tbl { width: 100%; border-collapse: collapse; font-size: 13px; }
        .loc-tbl th, .detail-tbl th {
            background: var(--chip); color: var(--muted);
            font-size: 11px; text-transform: uppercase; letter-spacing: .5px;
            padding: 10px 14px; text-align: left; border-bottom: 1px solid var(--line);
        }
        /* Sortable header cells */
        .loc-tbl thead tr:first-child th {
            cursor: pointer;
            user-select: none;
            white-space: nowrap;
        }
        .loc-tbl thead tr:first-child th .sh-si {
            display: inline-block; margin-left: 5px; font-size: 9px;
            opacity: 0.3; transition: opacity .15s;
        }
        .loc-tbl thead tr:first-child th.sort-asc  .sh-si,
        .loc-tbl thead tr:first-child th.sort-desc .sh-si { opacity: 1; color: var(--accent); }
        .loc-tbl thead tr:first-child th.sort-asc,
        .loc-tbl thead tr:first-child th.sort-desc { color: var(--accent); }
        .loc-tbl td, .detail-tbl td { padding: 9px 14px; border-bottom: 1px solid var(--line); }
        .loc-tbl tbody tr:hover td, .detail-tbl tbody tr:hover td { background: var(--table-row-hover); }

        div.dt-container { color: var(--text) !important; }
        .dt-info, .dt-length label, .dt-search label { color: var(--muted) !important; font-size: 12px !important; }
        .dt-length select { background: var(--chip); color: var(--text); border: 1px solid var(--line); border-radius: 4px; padding: 4px; }
        .dt-search input { background: var(--chip) !important; color: var(--text) !important; border: 1px solid var(--line) !important; border-radius: 6px !important; padding: 5px 10px !important; outline: none !important; }

        .col-search {
            width: 100%; background: var(--chip); color: var(--text);
            border: 1px solid var(--line); padding: 5px 8px;
            border-radius: 4px; font-size: 11px; margin-top: 4px;
        }
        .col-search::placeholder { color: var(--muted); opacity: 0.4; }

        .mini-bar { height: 6px; border-radius: 3px; background: var(--chip); overflow: hidden; margin-top: 4px; display: flex; }
        .mini-seg { height: 100%; }
        .pct-good { color: var(--accent-2); font-weight: 600; }
        .pct-warn { color: var(--warn); font-weight: 600; }
        .pct-bad  { color: var(--danger); font-weight: 600; }

        .loc-link { color: var(--accent); font-weight: 600; cursor: pointer; text-decoration: none; background: none; border: none; padding: 0; font-size: 13px; }
        .loc-link:hover { text-decoration: underline; }

        .detail-panel { margin-top: 0; }
        .detail-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; flex-wrap: wrap; gap: 10px; }
        .detail-title { font-size: 15px; font-weight: 600; color: var(--text); }

        .err-msg { background: color-mix(in srgb, var(--danger), transparent 88%); border: 1px solid color-mix(in srgb, var(--danger), transparent 60%); padding: 10px 14px; border-radius: 8px; color: var(--danger); }
        .ok-msg  { background: color-mix(in srgb, var(--accent-2), transparent 88%); border: 1px solid color-mix(in srgb, var(--accent-2), transparent 60%); padding: 10px 14px; border-radius: 8px; color: var(--accent-2); }
        .err { color: var(--danger); font-weight: 600; }
        .ok  { color: var(--accent-2); font-weight: 600; }

        /* === ASSET DETAIL SLIDE-OUT PANEL === */
        .asset-detail-panel {
            position: fixed; top: 0; right: 0; bottom: 0; width: 700px; max-width: 95vw;
            background: var(--card); border-left: 2px solid var(--line);
            z-index: 200; transform: translateX(100%); transition: transform .3s ease;
            display: flex; flex-direction: column; overflow: hidden;
            box-shadow: -8px 0 30px rgba(0,0,0,.25);
        }
        .asset-detail-panel.open { transform: translateX(0); }
        body.asset-detail-open .dash { margin-right: 710px; transition: margin-right .3s ease; }
        @media(max-width:1100px) { body.asset-detail-open .dash { margin-right: 0; } }

        .adp-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 16px 20px; border-bottom: 1px solid var(--line);
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 88%), var(--card));
            flex-shrink: 0;
        }
        .adp-header h2 { margin: 0; font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        .adp-header h2 .adp-icon {
            width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, var(--accent), #8B5CF6); font-size: 15px; color: #fff;
        }
        .adp-close {
            background: none; border: 1px solid var(--line); border-radius: 8px;
            color: var(--muted); width: 32px; height: 32px; font-size: 16px; cursor: pointer;
            transition: border-color .2s, color .2s;
        }
        .adp-close:hover { border-color: var(--danger); color: var(--danger); }

        .adp-actions {
            display: flex; gap: 6px; padding: 10px 20px; border-bottom: 1px solid var(--line);
            background: var(--bg); flex-shrink: 0; flex-wrap: wrap;
        }
        .adp-action-btn {
            display: inline-flex; align-items: center; gap: 5px; padding: 6px 14px;
            border-radius: 6px; font-size: 12px; font-weight: 600; text-decoration: none;
            border: 1px solid var(--line); background: var(--chip); color: var(--text);
            cursor: pointer; transition: .2s;
        }
        .adp-action-btn:hover { border-color: var(--accent); color: var(--accent); }

        .adp-tabs {
            display: flex; gap: 0; border-bottom: 2px solid var(--line);
            padding: 0 20px; background: var(--bg); flex-shrink: 0; overflow-x: auto;
        }
        .adp-tab {
            padding: 10px 16px; font-size: 12px; font-weight: 600; text-transform: uppercase;
            letter-spacing: .4px; color: var(--muted); cursor: pointer; border: none; background: none;
            border-bottom: 2px solid transparent; margin-bottom: -2px; transition: .2s; white-space: nowrap;
        }
        .adp-tab:hover { color: var(--text); }
        .adp-tab.active { color: var(--accent); border-bottom-color: var(--accent); }
        .adp-tab .tab-badge {
            display: inline-flex; align-items: center; justify-content: center;
            min-width: 18px; height: 18px; border-radius: 9px; font-size: 10px; font-weight: 700;
            background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--accent);
            margin-left: 5px; padding: 0 5px;
        }

        .adp-body { flex: 1; overflow-y: auto; padding: 20px; }
        .adp-tab-content { display: none; }
        .adp-tab-content.active { display: block; }

        .adp-field-group { margin-bottom: 18px; }
        .adp-field-group-title {
            font-size: 11px; font-weight: 700; color: var(--accent); text-transform: uppercase;
            letter-spacing: .5px; border-bottom: 1px solid var(--line); padding-bottom: 6px; margin-bottom: 10px;
        }
        .adp-fields { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
        .adp-fields.single { grid-template-columns: 1fr; }
        .adp-field label {
            display: block; font-size: 10px; font-weight: 600; color: var(--muted);
            text-transform: uppercase; letter-spacing: .3px; margin-bottom: 2px;
        }
        .adp-field .adp-val {
            font-size: 13px; color: var(--text); padding: 5px 8px;
            background: var(--bg); border: 1px solid var(--line); border-radius: 5px;
            min-height: 28px; word-break: break-word;
        }
        .adp-field .adp-val.empty { color: var(--muted); font-style: italic; opacity: .5; }

        .adp-history-table { width: 100%; border-collapse: collapse; font-size: 12px; }
        .adp-history-table th {
            background: var(--chip); color: var(--muted); font-size: 10px; text-transform: uppercase;
            letter-spacing: .4px; padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--line);
            position: sticky; top: 0;
        }
        .adp-history-table td { padding: 7px 10px; border-bottom: 1px solid var(--line); }
        .adp-history-table tbody tr:hover td { background: var(--table-row-hover); }

        .adp-empty {
            text-align: center; padding: 40px 20px; color: var(--muted);
            font-size: 13px; font-style: italic;
        }
        .adp-empty .adp-empty-icon { font-size: 36px; margin-bottom: 10px; opacity: .4; display: block; }
        .adp-loading { text-align: center; padding: 30px; color: var(--accent); font-weight: 600; font-size: 13px; }

        /* Highlight selected row in asset grids */
        .detail-tbl tbody tr.row-selected td {
            background: color-mix(in srgb, var(--accent), transparent 88%) !important;
            border-bottom-color: color-mix(in srgb, var(--accent), transparent 70%);
        }
        .detail-tbl tbody tr { cursor: pointer; }

        /* === LOCATION ASSET PRINTING CONTROLS === */
        .btn-loc-print {
            padding: 6px 14px; border-radius: 6px; font-size: 12px; font-weight: 600;
            background: var(--accent); color: #fff; border: none; cursor: pointer;
            display: inline-flex; align-items: center; gap: 6px; transition: opacity .2s;
        }
        .btn-loc-print:hover { opacity: .88; }
        .btn-loc-print:disabled { opacity: .4; cursor: not-allowed; }
        .loc-sel-badge {
            background: rgba(255,255,255,.25); padding: 1px 7px; border-radius: 10px; font-size: 11px; font-weight: 700;
        }

        /* === COLUMNS SELECTOR DROPDOWN FOR LOCATION DETAIL === */
        .btn-loc-cols {
            padding: 6px 13px; border-radius: 6px; font-size: 12px; font-weight: 600;
            background: var(--chip); color: var(--text); border: 1px solid var(--line);
            cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: all .2s ease;
        }
        .btn-loc-cols:hover { border-color: var(--accent); color: var(--accent); }
        .btn-loc-cols.open { background: color-mix(in srgb, var(--accent), transparent 85%); border-color: var(--accent); color: var(--accent); }
        .loc-cols-badge {
            background: color-mix(in srgb, var(--accent), transparent 75%); color: var(--accent);
            padding: 1px 6px; border-radius: 10px; font-size: 11px; font-weight: 700;
        }
        .loc-col-popover {
            position: absolute; right: 0; top: calc(100% + 6px); z-index: 1000;
            width: 320px; max-width: 90vw; background: var(--card); border: 1px solid var(--line);
            border-radius: 10px; padding: 12px 14px; box-shadow: 0 14px 36px rgba(0, 0, 0, 0.45);
            backdrop-filter: blur(12px); animation: colPopIn .18s ease-out;
        }
        @keyframes colPopIn {
            from { opacity: 0; transform: translateY(-6px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .lcp-header {
            display: flex; align-items: center; justify-content: space-between;
            padding-bottom: 8px; margin-bottom: 8px; border-bottom: 1px solid var(--line);
        }
        .lcp-title { font-size: 11px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .6px; }
        .lcp-btn-reset {
            background: none; border: 1px solid var(--line); border-radius: 4px;
            color: var(--muted); font-size: 11px; font-weight: 600; padding: 2px 7px; cursor: pointer; transition: .15s;
        }
        .lcp-btn-reset:hover { color: var(--accent); border-color: var(--accent); }
        .lcp-presets { display: flex; gap: 6px; margin-bottom: 10px; }
        .lcp-preset-btn {
            flex: 1; background: var(--chip); border: 1px solid var(--line); border-radius: 4px;
            padding: 4px 6px; font-size: 11px; font-weight: 600; color: var(--muted); cursor: pointer; text-align: center; transition: .15s;
        }
        .lcp-preset-btn:hover { color: var(--text); border-color: var(--accent); }
        .lcp-pills { display: flex; flex-wrap: wrap; gap: 6px; max-height: 240px; overflow-y: auto; padding-right: 2px; }
        .lcp-toggle {
            display: inline-flex; align-items: center; gap: 6px; font-size: 11.5px; font-weight: 500;
            padding: 4px 10px; border-radius: 16px; cursor: pointer; user-select: none;
            background: var(--chip); border: 1px solid var(--line); color: var(--muted); transition: all .15s ease; white-space: nowrap;
        }
        .lcp-toggle:hover { border-color: var(--accent); color: var(--text); }
        .lcp-toggle.active {
            background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--accent);
            border-color: color-mix(in srgb, var(--accent), transparent 55%); font-weight: 600;
        }
        .lcp-toggle.locked { opacity: 0.65; cursor: not-allowed; }
        .lcp-toggle input { display: none; }
        .detail-tbl td.col-desc { max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .detail-tbl td.col-model { max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .detail-tbl td.col-serial { max-width: 130px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .detail-tbl td.col-mfr { max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .detail-tbl td.col-rfid { font-family: monospace; font-size: 11.5px; max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

        .print-modal-overlay {
            position: fixed; inset: 0; background: rgba(0,0,0,.65); z-index: 1000;
            display: none; align-items: center; justify-content: center; backdrop-filter: blur(4px);
        }
        .print-modal-overlay.open { display: flex; }
        .print-modal-box {
            background: var(--card); border: 1px solid var(--line); border-radius: 14px;
            width: 720px; max-width: 95vw; max-height: 88vh; display: flex; flex-direction: column;
            overflow: hidden; box-shadow: 0 12px 40px rgba(0,0,0,.45); animation: pmodalIn .25s ease-out;
        }
        @keyframes pmodalIn { from { opacity: 0; transform: scale(.95); } to { opacity: 1; transform: scale(1); } }
        .pm-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 16px 20px; border-bottom: 1px solid var(--line);
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 85%), var(--card));
        }
        .pm-head h3 { margin: 0; font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 8px; }
        .pm-close-btn {
            background: none; border: 1px solid var(--line); border-radius: 6px;
            color: var(--muted); width: 30px; height: 30px; font-size: 16px; cursor: pointer;
        }
        .pm-close-btn:hover { border-color: var(--danger); color: var(--danger); }
        .pm-body { padding: 20px; overflow-y: auto; flex: 1; }
        .pm-row { display: flex; gap: 14px; margin-bottom: 16px; flex-wrap: wrap; }
        .pm-field { flex: 1; min-width: 200px; }
        .pm-field label { display: block; font-size: 11px; font-weight: 700; color: var(--muted); text-transform: uppercase; margin-bottom: 5px; }
        .pm-select { width: 100%; padding: 8px 10px; border-radius: 6px; border: 1px solid var(--line); background: var(--bg); color: var(--text); font-size: 13px; }
        .pm-preview-tbl { width: 100%; border-collapse: collapse; font-size: 12px; margin-top: 10px; }
        .pm-preview-tbl th { background: var(--chip); padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--line); font-size: 10px; text-transform: uppercase; color: var(--muted); }
        .pm-preview-tbl td { padding: 7px 10px; border-bottom: 1px solid var(--line); }
        .pm-footer {
            padding: 14px 20px; border-top: 1px solid var(--line); background: var(--bg);
            display: flex; align-items: center; justify-content: space-between; gap: 10px;
        }
        .pm-status { font-size: 13px; font-weight: 600; flex: 1; }
    </style>
</head>
<body>
<form id="form1" runat="server">

<!-- KPI hidden values from server -->
<asp:HiddenField ID="HdnTotalAssets"   runat="server" Value="0" />
<asp:HiddenField ID="HdnLocCount"      runat="server" Value="0" />
<asp:HiddenField ID="HdnWithCmr"       runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt03"         runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt46"         runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt79"         runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt1012"       runat="server" Value="0" />
<asp:HiddenField ID="HdnCnt13"         runat="server" Value="0" />

<asp:HiddenField ID="HdnSelectedLoc" runat="server" />

<!-- -- STICKY HEADER -- -->
<div class="page-header">
    <h1>&#128205; Assets by Location</h1>
    <div class="header-right">
        <asp:LinkButton ID="BtnExport" runat="server" CssClass="nav-pill nav-pill-primary"
            OnClick="Export_Click">&#128190; Export Excel</asp:LinkButton>
        <a href="va_asset_master.aspx" class="nav-pill nav-pill-ghost">&#128203; Asset Master</a>
        <a href="va_asset_stats.aspx" class="nav-pill nav-pill-ghost">&#128200; Statistics</a>
        <a href="documentation/va_location_list.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
        <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
    </div>
</div>

<div class="dash">
    <asp:Literal ID="LitMsg" runat="server" />

    <!-- -- CONTROLS ROW -- -->
    <div class="ctrl-bar">
        <span class="ctrl-label">Site</span>
        <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select" AutoPostBack="true"
            OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" />

        <div class="sep"></div>

        <span class="ctrl-label">Status</span>
        <asp:DropDownList ID="DdlStatus" runat="server" CssClass="ctrl-select" AutoPostBack="true"
            OnSelectedIndexChanged="DdlStatus_SelectedIndexChanged">
            <asp:ListItem Value="">All Statuses</asp:ListItem>
            <asp:ListItem Value="IN USE" Selected="True">IN USE</asp:ListItem>
            <asp:ListItem Value="TURNED IN">TURNED IN</asp:ListItem>
            <asp:ListItem Value="LOST OR STOLEN">LOST OR STOLEN</asp:ListItem>
            <asp:ListItem Value="OUT OF SERVICE">OUT OF SERVICE</asp:ListItem>
            <asp:ListItem Value="LOANED OUT">LOANED OUT</asp:ListItem>
        </asp:DropDownList>

        <div class="sep"></div>

        <span class="ctrl-label">CMR</span>
        <asp:TextBox ID="TxtCmr" runat="server" CssClass="ctrl-input" placeholder="Filter by CMR (text8)..." style="width:170px;" />

        <div class="sep"></div>

        <span class="ctrl-label">Location</span>
        <asp:TextBox ID="TxtLocationSearch" runat="server" CssClass="ctrl-input" placeholder="Location contains..." style="width:200px;" />

        <asp:Button ID="BtnSearch" runat="server" CssClass="btn-action" Text="Search" OnClick="BtnSearch_Click" />
        <asp:Button ID="BtnClearSearch" runat="server" CssClass="btn-secondary" Text="Clear" OnClick="BtnClearSearch_Click" />
    </div>

    <!-- -- KPI CARDS -- -->
    <div class="kpi-row">
        <div class="kpi-card">
            <div class="kpi-value" id="kv-total" style="color:var(--accent);">0</div>
            <div class="kpi-label">Total Assets</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-locs" style="color:#8B5CF6;">0</div>
            <div class="kpi-label">Locations</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-cmr" style="color:var(--accent-2);">0</div>
            <div class="kpi-pct" id="kp-cmr" style="color:var(--accent-2);">0%</div>
            <div class="kpi-label">With CMR</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-0-3" style="color:var(--accent-2);">0</div>
            <div class="kpi-pct" id="kp-0-3" style="color:var(--accent-2);">0%</div>
            <div class="kpi-label">Inv. 0&ndash;3 Months</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-over" style="color:var(--danger);">0</div>
            <div class="kpi-pct" id="kp-over" style="color:var(--danger);">0%</div>
            <div class="kpi-label">13+ Months / Never</div>
        </div>
    </div>

    <!-- -- AGE DISTRIBUTION BAR -- -->
    <div class="glass">
        <div class="panel-title">
            <span>Inventory Age Distribution</span>
            <span id="locCountLabel" style="font-size:12px;color:var(--muted);font-weight:400;text-transform:none;letter-spacing:0;"></span>
        </div>
        <div class="age-bar" id="ageBar"></div>
        <div class="bar-legend" id="ageLegend"></div>
    </div>

    <!-- -- LOCATION SUMMARY GRID -- -->
    <div class="glass">
        <div class="panel-title">
            <span>Location Summary</span>
        </div>

        <!-- Age-bucket filter buttons -->
        <div class="ctrl-bar" style="margin-bottom:16px;">
            <span class="ctrl-label">Filter by Age:</span>
            <asp:LinkButton ID="BtnFilter_0_3"   runat="server" CssClass="age-btn" style="background:color-mix(in srgb, var(--accent-2), transparent 85%);color:#10B981;border-color:#10B981;"  OnClick="BtnFilter_Click" CommandArgument="0-3">0&ndash;3 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_3_6"   runat="server" CssClass="age-btn" style="background:rgba(59,130,246,.15);color:#3B82F6;border-color:#3B82F6;"  OnClick="BtnFilter_Click" CommandArgument="4-6">4&ndash;6 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_6_9"   runat="server" CssClass="age-btn" style="background:rgba(245,158,11,.15);color:#F59E0B;border-color:#F59E0B;"  OnClick="BtnFilter_Click" CommandArgument="7-9">7&ndash;9 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_9_12"  runat="server" CssClass="age-btn" style="background:rgba(249,115,22,.15);color:#F97316;border-color:#F97316;"  OnClick="BtnFilter_Click" CommandArgument="10-12">10&ndash;12 mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilter_12plus" runat="server" CssClass="age-btn" style="background:color-mix(in srgb, var(--danger), transparent 85%);color:#EF4444;border-color:#EF4444;"  OnClick="BtnFilter_Click" CommandArgument="13+">13+ mo</asp:LinkButton>
            <asp:LinkButton ID="BtnFilterReset"  runat="server" CssClass="age-btn" style="background:var(--chip);color:var(--muted);border-color:var(--line);" OnClick="BtnFilterReset_Click">Show All</asp:LinkButton>
        </div>

        <asp:Literal ID="LitLocationListCount" runat="server" />

        <div class="tbl-wrap" style="margin-top:12px;">
            <!-- Hidden inputs to persist pager state across postbacks -->
            <input type="hidden" id="hdn-page-size" name="hdn-page-size" value="10" />
            <input type="hidden" id="hdn-page-num"  name="hdn-page-num"  value="1" />
            <input type="hidden" id="hdn-selected-loc" name="hdn-selected-loc" value="" />
            <!-- Pager toolbar -->
            <div id="loc-pager" style="display:flex; align-items:center; gap:10px; margin-bottom:8px; flex-wrap:wrap;">
                <span style="color:var(--muted); font-size:13px;">Show</span>
                <select id="loc-page-size" style="padding:4px 8px; border-radius:6px; border:1px solid var(--line); background:var(--chip); color:var(--text); font-size:13px; cursor:pointer;">
                    <option value="10">10</option>
                    <option value="20">20</option>
                    <option value="50">50</option>
                    <option value="100">100</option>
                </select>
                <span style="color:var(--muted); font-size:13px;">rows per page</span>
                <span id="loc-pager-info" style="margin-left:auto; color:var(--muted); font-size:12px;"></span>
                <button id="loc-prev" onclick="locPage(-1);return false;" style="padding:4px 12px; border-radius:6px; border:1px solid var(--line); background:var(--chip); color:var(--text); cursor:pointer; font-size:13px;">&#8592; Prev</button>
                <button id="loc-next" onclick="locPage(1);return false;"  style="padding:4px 12px; border-radius:6px; border:1px solid var(--line); background:var(--chip); color:var(--text); cursor:pointer; font-size:13px;">Next &#8594;</button>
            </div>
            <asp:GridView ID="GridLocationSummary" runat="server" AutoGenerateColumns="false"
                CssClass="loc-tbl" ClientIDMode="Static" EnableViewState="false"
                OnRowDataBound="GridLocationSummary_RowDataBound"
                OnRowCommand="GridLocationSummary_RowCommand"
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
                    <asp:BoundField DataField="UniqueCMR"    HeaderText="Unique CMR" />
                    <asp:BoundField DataField="Count_0_3"   HeaderText="0-3 mo" />
                    <asp:BoundField DataField="Count_4_6"   HeaderText="4-6 mo" />
                    <asp:BoundField DataField="Count_7_9"   HeaderText="7-9 mo" />
                    <asp:BoundField DataField="Count_10_12" HeaderText="10-12 mo" />
                    <asp:BoundField DataField="Count_13plus" HeaderText="13+ mo" />
                    <asp:BoundField DataField="Pct_0_3"   HeaderText="% 0-3" DataFormatString="{0:F1}" />
                    <asp:BoundField DataField="Pct_0_12"  HeaderText="% &lt;12m" DataFormatString="{0:F1}" />
                    <asp:BoundField DataField="LastInventoried" HeaderText="Last Inventoried" DataFormatString="{0:MM/dd/yyyy}" />
                </Columns>
            </asp:GridView>
        </div>
    </div>

    <!-- -- FILTER DETAIL PANEL (age-bucket drill-down) -- -->
    <asp:Panel ID="PanelAssetFilterDetail" runat="server" Visible="false" CssClass="glass detail-panel">
        <div class="detail-header" style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:10px;">
            <div class="detail-title">
                Assets filtered by age bucket:
                <strong style="color:var(--warn);"><asp:Literal ID="LitFilterRange" runat="server" /></strong>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
                <div class="loc-cols-dropdown" style="position:relative;">
                    <button type="button" class="btn-loc-cols" id="btnLocColsFilter" onclick="toggleLocColMenu('locColMenuFilter', event)" title="Choose visible columns">
                        &#9881; Columns <span class="loc-cols-badge" id="badgeLocColsFilter">8/12</span> &#9662;
                    </button>
                    <div id="locColMenuFilter" class="loc-col-popover" style="display:none;" onclick="event.stopPropagation();">
                        <div class="lcp-header">
                            <div class="lcp-title">&#9776; Table Columns</div>
                            <button type="button" class="lcp-btn-reset" onclick="resetLocCols()" title="Reset to default columns">&#8635; Reset</button>
                        </div>
                        <div class="lcp-presets">
                            <button type="button" class="lcp-preset-btn" onclick="applyLocPreset('default')">Default</button>
                            <button type="button" class="lcp-preset-btn" onclick="applyLocPreset('all')">Show All</button>
                            <button type="button" class="lcp-preset-btn" onclick="applyLocPreset('compact')">Compact</button>
                        </div>
                        <div class="lcp-pills" id="locColPillsFilter"></div>
                    </div>
                </div>
                <button type="button" class="btn-loc-print" onclick="openLocPrintModal('GridAssetFilterDetail')" title="Print selected assets">
                    &#128424; Print Labels <span class="loc-sel-badge" id="badgeGridAssetFilterDetail">0</span>
                </button>
                <button onclick="backToGrid();return false;"
                    style="padding:5px 14px; border-radius:6px; border:1px solid var(--line); background:var(--chip); color:var(--text); cursor:pointer; font-size:12px; font-weight:600; white-space:nowrap;">
                    &#8593; Back to Locations
                </button>
            </div>
        </div>
        <div class="tbl-wrap">
            <asp:GridView ID="GridAssetFilterDetail" runat="server" AutoGenerateColumns="false"
                CssClass="detail-tbl" ClientIDMode="Static" EnableViewState="false"
                GridLines="None" DataKeyNames="AssetId" OnRowDataBound="AssetGrid_RowDataBound">
                <Columns>
                    <asp:TemplateField ItemStyle-Width="38px" ItemStyle-HorizontalAlign="Center" HeaderStyle-Width="38px" HeaderStyle-HorizontalAlign="Center" HeaderStyle-CssClass="col-sel" ItemStyle-CssClass="col-sel">
                        <HeaderTemplate>
                            <input type="checkbox" class="chk-all-loc-assets" onclick="toggleAllLocAssets(this)" title="Select All" />
                        </HeaderTemplate>
                        <ItemTemplate>
                            <input type="checkbox" class="chk-loc-asset" value='<%# Eval("AssetId") %>' data-name='<%# Server.HtmlEncode(Convert.ToString(Eval("Asset ID"))) %>' onclick="event.stopPropagation();" onchange="updateLocSelectionCount();" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="Asset ID" HeaderText="Asset ID" HeaderStyle-CssClass="col-assetid" ItemStyle-CssClass="col-assetid" />
                    <asp:BoundField DataField="Description" HeaderText="Description" HeaderStyle-CssClass="col-desc" ItemStyle-CssClass="col-desc" />
                    <asp:BoundField DataField="Model" HeaderText="Model" HeaderStyle-CssClass="col-model" ItemStyle-CssClass="col-model" />
                    <asp:BoundField DataField="Serial Number" HeaderText="Serial #" HeaderStyle-CssClass="col-serial" ItemStyle-CssClass="col-serial" />
                    <asp:BoundField DataField="Manufacturer" HeaderText="Manufacturer" HeaderStyle-CssClass="col-mfr" ItemStyle-CssClass="col-mfr" />
                    <asp:BoundField DataField="Location" HeaderText="Location" HeaderStyle-CssClass="col-loc" ItemStyle-CssClass="col-loc" />
                    <asp:BoundField DataField="CMR" HeaderText="CMR" HeaderStyle-CssClass="col-cmr" ItemStyle-CssClass="col-cmr" />
                    <asp:BoundField DataField="Tag Type" HeaderText="Tag Type" HeaderStyle-CssClass="col-tagtype" ItemStyle-CssClass="col-tagtype" />
                    <asp:BoundField DataField="Status" HeaderText="Status" HeaderStyle-CssClass="col-status" ItemStyle-CssClass="col-status" />
                    <asp:BoundField DataField="RFID Tag" HeaderText="RFID Tag" HeaderStyle-CssClass="col-rfid" ItemStyle-CssClass="col-rfid" />
                    <asp:BoundField DataField="Days Since" HeaderText="Days Since" HeaderStyle-CssClass="col-days" ItemStyle-CssClass="col-days" />
                    <asp:BoundField DataField="Last Inventoried" HeaderText="Last Inventoried" DataFormatString="{0:MM/dd/yyyy}" HeaderStyle-CssClass="col-lastinv" ItemStyle-CssClass="col-lastinv" />
                </Columns>
            </asp:GridView>
        </div>
    </asp:Panel>

    <!-- -- LOCATION DETAIL PANEL (click a location row) -- -->
    <asp:Panel ID="PanelAssetsDetail" runat="server" Visible="false" CssClass="glass detail-panel">
        <div class="detail-header" style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:10px;">
            <div class="detail-title">
                Assets in:
                <strong style="color:var(--accent);"><asp:Literal ID="LitSelectedLocation" runat="server" /></strong>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
                <div class="loc-cols-dropdown" style="position:relative;">
                    <button type="button" class="btn-loc-cols" id="btnLocColsDetail" onclick="toggleLocColMenu('locColMenuDetail', event)" title="Choose visible columns">
                        &#9881; Columns <span class="loc-cols-badge" id="badgeLocColsDetail">8/12</span> &#9662;
                    </button>
                    <div id="locColMenuDetail" class="loc-col-popover" style="display:none;" onclick="event.stopPropagation();">
                        <div class="lcp-header">
                            <div class="lcp-title">&#9776; Table Columns</div>
                            <button type="button" class="lcp-btn-reset" onclick="resetLocCols()" title="Reset to default columns">&#8635; Reset</button>
                        </div>
                        <div class="lcp-presets">
                            <button type="button" class="lcp-preset-btn" onclick="applyLocPreset('default')">Default</button>
                            <button type="button" class="lcp-preset-btn" onclick="applyLocPreset('all')">Show All</button>
                            <button type="button" class="lcp-preset-btn" onclick="applyLocPreset('compact')">Compact</button>
                        </div>
                        <div class="lcp-pills" id="locColPillsDetail"></div>
                    </div>
                </div>
                <button type="button" class="btn-loc-print" onclick="openLocPrintModal('GridAssetsDetail')" title="Print selected assets in this location">
                    &#128424; Print Labels <span class="loc-sel-badge" id="badgeGridAssetsDetail">0</span>
                </button>
                <button onclick="backToGrid();return false;"
                    style="padding:5px 14px; border-radius:6px; border:1px solid var(--line); background:var(--chip); color:var(--text); cursor:pointer; font-size:12px; font-weight:600; white-space:nowrap;">
                    &#8593; Back to Locations
                </button>
            </div>
        </div>
        <div class="tbl-wrap">
            <asp:GridView ID="GridAssetsDetail" runat="server" AutoGenerateColumns="false"
                CssClass="detail-tbl" ClientIDMode="Static" EnableViewState="false"
                GridLines="None" DataKeyNames="AssetId" OnRowDataBound="AssetGrid_RowDataBound">
                <Columns>
                    <asp:TemplateField ItemStyle-Width="38px" ItemStyle-HorizontalAlign="Center" HeaderStyle-Width="38px" HeaderStyle-HorizontalAlign="Center" HeaderStyle-CssClass="col-sel" ItemStyle-CssClass="col-sel">
                        <HeaderTemplate>
                            <input type="checkbox" class="chk-all-loc-assets" onclick="toggleAllLocAssets(this)" title="Select All" />
                        </HeaderTemplate>
                        <ItemTemplate>
                            <input type="checkbox" class="chk-loc-asset" value='<%# Eval("AssetId") %>' data-name='<%# Server.HtmlEncode(Convert.ToString(Eval("Asset ID"))) %>' onclick="event.stopPropagation();" onchange="updateLocSelectionCount();" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="Asset ID" HeaderText="Asset ID" HeaderStyle-CssClass="col-assetid" ItemStyle-CssClass="col-assetid" />
                    <asp:BoundField DataField="Description" HeaderText="Description" HeaderStyle-CssClass="col-desc" ItemStyle-CssClass="col-desc" />
                    <asp:BoundField DataField="Model" HeaderText="Model" HeaderStyle-CssClass="col-model" ItemStyle-CssClass="col-model" />
                    <asp:BoundField DataField="Serial Number" HeaderText="Serial #" HeaderStyle-CssClass="col-serial" ItemStyle-CssClass="col-serial" />
                    <asp:BoundField DataField="Manufacturer" HeaderText="Manufacturer" HeaderStyle-CssClass="col-mfr" ItemStyle-CssClass="col-mfr" />
                    <asp:BoundField DataField="Location" HeaderText="Location" HeaderStyle-CssClass="col-loc" ItemStyle-CssClass="col-loc" />
                    <asp:BoundField DataField="CMR" HeaderText="CMR" HeaderStyle-CssClass="col-cmr" ItemStyle-CssClass="col-cmr" />
                    <asp:BoundField DataField="Tag Type" HeaderText="Tag Type" HeaderStyle-CssClass="col-tagtype" ItemStyle-CssClass="col-tagtype" />
                    <asp:BoundField DataField="Status" HeaderText="Status" HeaderStyle-CssClass="col-status" ItemStyle-CssClass="col-status" />
                    <asp:BoundField DataField="RFID Tag" HeaderText="RFID Tag" HeaderStyle-CssClass="col-rfid" ItemStyle-CssClass="col-rfid" />
                    <asp:BoundField DataField="Days Since" HeaderText="Days Since" HeaderStyle-CssClass="col-days" ItemStyle-CssClass="col-days" />
                    <asp:BoundField DataField="Last Inventoried" HeaderText="Last Inventoried" DataFormatString="{0:MM/dd/yyyy}" HeaderStyle-CssClass="col-lastinv" ItemStyle-CssClass="col-lastinv" />
                </Columns>
            </asp:GridView>
        </div>
    </asp:Panel>

</div><!-- /dash -->

<!-- ------------------ ASSET DETAIL SLIDE-OUT PANEL ------------------ -->
<div class="asset-detail-panel" id="assetDetailPanel">
    <div class="adp-header">
        <h2><span class="adp-icon">&#128203;</span> <span id="adpTitle">Asset Detail</span></h2>
        <button type="button" class="adp-close" onclick="closeAssetDetail()">&times;</button>
    </div>

    <div class="adp-actions">
        <button type="button" class="adp-action-btn" id="adpPrintBtn" onclick="printFromAssetDetail()" style="background:color-mix(in srgb, var(--accent), transparent 88%); color:var(--accent); border-color:color-mix(in srgb, var(--accent), transparent 50%); font-weight:700;">
            &#128424; Print Label
        </button>
        <a id="adpEditLink" href="#" target="_blank" class="adp-action-btn">&#8599; Open in iDash</a>
        <a id="adpMasterLink" href="#" class="adp-action-btn">&#128203; View in Asset Master</a>
    </div>

    <div class="adp-tabs">
        <button type="button" class="adp-tab active" data-tab="general" onclick="adpSwitchTab(this)">General</button>
        <button type="button" class="adp-tab" data-tab="lochistory" onclick="adpSwitchTab(this)">Location History <span class="tab-badge" id="adpBadgeLoc">&mdash;</span></button>
        <button type="button" class="adp-tab" data-tab="checkout" onclick="adpSwitchTab(this)">Checkout <span class="tab-badge" id="adpBadgeCO">&mdash;</span></button>
        <button type="button" class="adp-tab" data-tab="maintenance" onclick="adpSwitchTab(this)">Maintenance <span class="tab-badge" id="adpBadgeMnt">&mdash;</span></button>
        <button type="button" class="adp-tab" data-tab="children" onclick="adpSwitchTab(this)">Children <span class="tab-badge" id="adpBadgeChild">&mdash;</span></button>
    </div>

    <div class="adp-body">
        <div class="adp-tab-content active" id="adp-tab-general"></div>
        <div class="adp-tab-content" id="adp-tab-lochistory"></div>
        <div class="adp-tab-content" id="adp-tab-checkout"></div>
        <div class="adp-tab-content" id="adp-tab-maintenance"></div>
        <div class="adp-tab-content" id="adp-tab-children"></div>
    </div>
</div>

<!-- ------------------ PRINT MODAL DIALOG ------------------ -->
<div class="print-modal-overlay" id="locPrintOverlay" onclick="if(event.target===this) closeLocPrintModal()">
    <div class="print-modal-box">
        <div class="pm-head">
            <h3>&#128424; Print Asset Labels</h3>
            <button type="button" class="pm-close-btn" onclick="closeLocPrintModal()">&times;</button>
        </div>
        <div class="pm-body">
            <div class="pm-row">
                <div class="pm-field">
                    <label>Print Template</label>
                    <select id="locPrintTemplate" class="pm-select">
                        <option value="">Loading templates...</option>
                    </select>
                </div>
                <div class="pm-field">
                    <label>Selected Assets</label>
                    <div style="font-size:14px; font-weight:700; color:var(--text); padding:8px 0;" id="locPrintAssetSummary">
                        0 asset(s) ready to print
                    </div>
                </div>
            </div>

            <div style="max-height:240px; overflow-y:auto; border:1px solid var(--line); border-radius:6px;">
                <table class="pm-preview-tbl">
                    <thead>
                        <tr>
                            <th>Asset Name</th>
                            <th>Location</th>
                            <th>CMR</th>
                            <th>Tag Type</th>
                        </tr>
                    </thead>
                    <tbody id="locPrintPreviewBody">
                    </tbody>
                </table>
            </div>
        </div>
        <div class="pm-footer">
            <div class="pm-status" id="locPrintStatus"></div>
            <div style="display:flex; gap:8px;">
                <button type="button" class="adp-action-btn" onclick="closeLocPrintModal()">Cancel</button>
                <button type="button" class="btn-loc-print" id="btnExecuteLocPrint" onclick="executeLocPrint()">
                    &#128424; Send to Printer
                </button>
            </div>
        </div>
    </div>
</div>

<idash:Footer runat="server" />
</form>

<script type="text/javascript">
    var AGE_COLORS = ['#10B981','#3B82F6','#F59E0B','#F97316','#EF4444'];
    var AGE_LABELS = ['0-3 mo','4-6 mo','7-9 mo','10-12 mo','13+ mo'];

    function fmtN(n) { return new Intl.NumberFormat().format(n); }
    function pctStr(v, t) { return t > 0 ? (v / t * 100).toFixed(1) + '%' : '0%'; }

    function anim(id, n, dur) {
        var el = document.getElementById(id); if (!el) return;
        var t0 = null, fmt = new Intl.NumberFormat();
        function step(t) { if (!t0) t0 = t; var p = Math.min((t - t0) / (dur || 900), 1); el.textContent = fmt.format(Math.round(p * n)); if (p < 1) requestAnimationFrame(step); }
        requestAnimationFrame(step);
    }

    function initKpis() {
        var tot   = parseInt($('#<%= HdnTotalAssets.ClientID %>').val()) || 0;
        var locs  = parseInt($('#<%= HdnLocCount.ClientID %>').val()) || 0;
        var cmr   = parseInt($('#<%= HdnWithCmr.ClientID %>').val()) || 0;
        var c03   = parseInt($('#<%= HdnCnt03.ClientID %>').val()) || 0;
        var c46   = parseInt($('#<%= HdnCnt46.ClientID %>').val()) || 0;
        var c79   = parseInt($('#<%= HdnCnt79.ClientID %>').val()) || 0;
        var c1012 = parseInt($('#<%= HdnCnt1012.ClientID %>').val()) || 0;
        var c13   = parseInt($('#<%= HdnCnt13.ClientID %>').val()) || 0;

        anim('kv-total', tot, 900);
        anim('kv-locs', locs, 700);
        anim('kv-cmr', cmr, 700);
        anim('kv-0-3', c03, 700);
        anim('kv-over', c13, 700);

        document.getElementById('kp-cmr').textContent = pctStr(cmr, tot);
        document.getElementById('kp-0-3').textContent = pctStr(c03, tot);
        document.getElementById('kp-over').textContent = pctStr(c13, tot);

        var lbl = document.getElementById('locCountLabel');
        if (lbl) lbl.textContent = fmtN(locs) + ' location' + (locs !== 1 ? 's' : '') + ' \u00b7 ' + fmtN(tot) + ' assets';

        // Build age distribution bar
        var bar = document.getElementById('ageBar');
        var leg = document.getElementById('ageLegend');
        if (!bar || !leg) return;
        bar.innerHTML = ''; leg.innerHTML = '';
        var counts = [c03, c46, c79, c1012, c13];
        counts.forEach(function (cnt, i) {
            if (!cnt) return;
            var w = tot > 0 ? (cnt / tot * 100).toFixed(2) : 0;
            var seg = document.createElement('div');
            seg.className = 'age-seg';
            seg.style.cssText = 'width:' + w + '%;background:' + AGE_COLORS[i] + ';';
            seg.title = AGE_LABELS[i] + ': ' + fmtN(cnt) + ' (' + pctStr(cnt, tot) + ')';
            bar.appendChild(seg);

            var chip = document.createElement('div');
            chip.className = 'bar-chip';
            chip.innerHTML = '<span class="chip-dot" style="background:' + AGE_COLORS[i] + '"></span>'
                + '<span>' + AGE_LABELS[i] + '</span>'
                + '<strong style="margin-left:4px;">' + fmtN(cnt) + '</strong>'
                + '<span style="opacity:.55;font-size:11px;margin-left:4px;">(' + pctStr(cnt, tot) + ')</span>';
            leg.appendChild(chip);
        });
    }

    function applyMiniBar(tbl) {
        $(tbl).find('tbody tr').each(function () {
            var cells = $(this).find('td');
            if (cells.length < 9) return;
            var tot   = parseInt(cells.eq(1).text()) || 0; if (!tot) return;
            var c03   = parseInt(cells.eq(3).text()) || 0;
            var c46   = parseInt(cells.eq(4).text()) || 0;
            var c79   = parseInt(cells.eq(5).text()) || 0;
            var c1012 = parseInt(cells.eq(6).text()) || 0;
            var c13   = parseInt(cells.eq(7).text()) || 0;
            var segs = [c03, c46, c79, c1012, c13];
            var barHtml = '<div class="mini-bar">';
            segs.forEach(function (cnt, i) {
                if (!cnt) return;
                barHtml += '<div class="mini-seg" style="width:' + (cnt / tot * 100).toFixed(1) + '%;background:' + AGE_COLORS[i] + ';" title="' + AGE_LABELS[i] + ': ' + cnt + '"></div>';
            });
            barHtml += '</div>';
            cells.eq(1).html('<span>' + tot + '</span>' + barHtml);

            // colour the % <12m cell (index 9)
            var pct12 = parseFloat(cells.eq(9).text()) || 0;
            cells.eq(9).addClass(pct12 >= 80 ? 'pct-good' : pct12 >= 50 ? 'pct-warn' : 'pct-bad');
        });
    }

    // Native column filter + pagination + sort for summary grid
    // Keeps ASP.NET postback working (DataTables would intercept LinkButton clicks)
    var _locCurrentPage = 1;
    var _locPageSize = 50;
    var _locFilteredRows = [];
    var _locAllRows = [];
    var _locSortCol = -1;
    var _locSortAsc = true;
    // Columns that are numeric (0-indexed): Total=1, CMR=2, 0-3=3, 4-6=4, 7-9=5, 10-12=6, 13+=7, %0-3=8, %<12m=9
    var _locNumericCols = [1,2,3,4,5,6,7,8,9];
    // Column 10 = Last Inventoried (date)
    var _locDateCols = [10];

    function initSummaryFilter(id) {
        var tbl = document.getElementById(id);
        if (!tbl) return;
        var thead = tbl.querySelector('thead');
        if (!thead) return;

        // Build filter input row
        var origRow = thead.rows[0];
        var filterRow = origRow.cloneNode(false);
        filterRow.className = 'col-search-row';
        for (var i = 0; i < origRow.cells.length; i++) {
            var th = document.createElement('th');
            var inp = document.createElement('input');
            inp.type = 'text'; inp.placeholder = '...';
            inp.className = 'col-search';
            inp.setAttribute('data-col', i);
            th.appendChild(inp);
            filterRow.appendChild(th);
        }
        thead.appendChild(filterRow);

        // Add sort icons + click handlers to header cells
        Array.from(origRow.cells).forEach(function (th, ci) {
            var txt = th.innerText.trim();
            th.innerHTML = txt + ' <span class="sh-si">&#9650;&#9660;</span>';
            th.title = 'Click to sort';
            th.addEventListener('click', function () {
                if (_locSortCol === ci) {
                    _locSortAsc = !_locSortAsc;
                } else {
                    _locSortCol = ci;
                    // Default: numeric/date cols start descending (big?small first), text cols ascending
                    _locSortAsc = (_locNumericCols.indexOf(ci) === -1 && _locDateCols.indexOf(ci) === -1);
                }
                // Update header visual
                Array.from(origRow.cells).forEach(function (h) {
                    h.classList.remove('sort-asc', 'sort-desc');
                    var si = h.querySelector('.sh-si'); if (si) si.innerHTML = '&#9650;&#9660;';
                });
                th.classList.add(_locSortAsc ? 'sort-asc' : 'sort-desc');
                var si = th.querySelector('.sh-si');
                if (si) si.innerHTML = _locSortAsc ? '&#9650;' : '&#9660;';

                locApplySort();
                _locCurrentPage = 1;
                locRender();
            });
        });

        // Collect all data rows once
        var tbody = tbl.querySelector('tbody');
        if (!tbody) return;
        _locAllRows = Array.from(tbody.rows);
        _locFilteredRows = _locAllRows.slice();

        // Page size selector
        var sel = document.getElementById('loc-page-size');
        if (sel) {
            sel.addEventListener('change', function () {
                _locPageSize = parseInt(this.value);
                _locCurrentPage = 1;
                locRender();
            });
        }

        // Filter on keyup � resets to page 1
        filterRow.addEventListener('keyup', function () {
            var filters = [];
            filterRow.querySelectorAll('input').forEach(function (inp2) {
                filters.push({ col: parseInt(inp2.getAttribute('data-col')), val: inp2.value.toLowerCase() });
            });
            _locFilteredRows = _locAllRows.filter(function (row) {
                return filters.every(function (f) {
                    if (!f.val) return true;
                    var cell = row.cells[f.col];
                    var text = cell ? (cell.innerText || cell.textContent || '').toLowerCase() : '';
                    return text.indexOf(f.val) !== -1;
                });
            });
            locApplySort();
            _locCurrentPage = 1;
            locRender();
        });

        locRender();
    }

    function locApplySort() {
        if (_locSortCol < 0) return;
        var ci = _locSortCol;
        var isNum  = _locNumericCols.indexOf(ci) !== -1;
        var isDate = _locDateCols.indexOf(ci) !== -1;
        _locFilteredRows.sort(function (a, b) {
            var av = a.cells[ci] ? (a.cells[ci].innerText || a.cells[ci].textContent || '').trim() : '';
            var bv = b.cells[ci] ? (b.cells[ci].innerText || b.cells[ci].textContent || '').trim() : '';
            var r;
            if (isNum) {
                r = (parseFloat(av) || 0) - (parseFloat(bv) || 0);
            } else if (isDate) {
                var ad = Date.parse(av) || 0, bd = Date.parse(bv) || 0;
                r = ad - bd;
            } else {
                r = av.localeCompare(bv);
            }
            return _locSortAsc ? r : -r;
        });
    }

    function locRender() {
        var tbody = document.querySelector('#GridLocationSummary tbody');
        if (!tbody) return;
        var total = _locFilteredRows.length;
        var pages = Math.max(1, Math.ceil(total / _locPageSize));
        if (_locCurrentPage > pages) _locCurrentPage = pages;
        var start = (_locCurrentPage - 1) * _locPageSize;
        var end   = Math.min(start + _locPageSize, total);

        // Show/hide all rows
        Array.from(tbody.rows).forEach(function (r) { r.style.display = 'none'; });
        _locFilteredRows.forEach(function (r, i) {
            r.style.display = (i >= start && i < end) ? '' : 'none';
        });

        // Update info label
        var info = document.getElementById('loc-pager-info');
        if (info) {
            info.textContent = total === 0
                ? 'No locations'
                : 'Showing ' + (start + 1) + '\u2013' + end + ' of ' + total + ' locations  (page ' + _locCurrentPage + ' of ' + pages + ')';
        }

        // Save state whenever page or size changes
        function locSaveState() {
            try {
                localStorage.setItem('loc_page_size', _locPageSize);
                localStorage.setItem('loc_page_num',  _locCurrentPage);
            } catch(e) {}
        }

        // Persist page size and update hidden input
        var prev = document.getElementById('loc-prev');
        var next = document.getElementById('loc-next');
        if (prev) { prev.disabled = _locCurrentPage <= 1; prev.style.opacity = prev.disabled ? '.4' : '1'; }
        if (next) { next.disabled = _locCurrentPage >= pages; next.style.opacity = next.disabled ? '.4' : '1'; }
        locSaveState();
    }

    function locPage(dir) {
        var tbody = document.querySelector('#GridLocationSummary tbody');
        if (!tbody) return;
        var pages = Math.max(1, Math.ceil(_locFilteredRows.length / _locPageSize));
        _locCurrentPage = Math.max(1, Math.min(pages, _locCurrentPage + dir));
        locRender();
        document.getElementById('GridLocationSummary').scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    function backToGrid() {
        var grid = document.getElementById('GridLocationSummary');
        if (grid) grid.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    $(document).ready(function () {
        initKpis();
        applyMiniBar('GridLocationSummary');

        // Restore page size from localStorage (default 10)
        var savedSize = 10;
        var savedPage = 1;
        try {
            var s = parseInt(localStorage.getItem('loc_page_size'));
            var p = parseInt(localStorage.getItem('loc_page_num'));
            if (!isNaN(s) && s > 0) savedSize = s;
            if (!isNaN(p) && p > 0) savedPage = p;
        } catch(e) {}

        // Set page size dropdown to match saved value
        var sel = document.getElementById('loc-page-size');
        if (sel) {
            sel.value = savedSize;
            // Fallback: if saved value isn't an option, default to 10
            if (sel.value != savedSize) { sel.value = '10'; savedSize = 10; }
        }
        _locPageSize    = savedSize;
        _locCurrentPage = savedPage;

        // Summary grid: use native filter (NOT DataTables) to keep ASP.NET postback working
        initSummaryFilter('GridLocationSummary');

        // Detail grids: lightweight inline filter (no DataTables needed)
        initDetailFilter('GridAssetsDetail');
        initDetailFilter('GridAssetFilterDetail');

        // Initialize detail grid customizable columns
        loadLocColsState();
        buildLocColMenus();
        applyAllLocCols();

        // Highlight the previously selected location row
        try {
            var selLoc = (localStorage.getItem('loc_selected') || '').trim().toLowerCase();
            if (selLoc) {
                document.querySelectorAll('#GridLocationSummary tbody tr').forEach(function (row) {
                    var link = row.querySelector('a, span');
                    var txt  = link ? (link.innerText || link.textContent || '').trim().toLowerCase() : '';
                    if (txt === selLoc) {
                        row.style.background = 'color-mix(in srgb, var(--accent), transparent 90%)';
                        row.style.outline    = '1px solid color-mix(in srgb, var(--accent), transparent 60%)';
                    }
                });
            }
        } catch(e) {}

        // Store selected location when a loc-link is clicked (before postback)
        document.querySelectorAll('#GridLocationSummary .loc-link').forEach(function (btn) {
            btn.addEventListener('click', function () {
                try { localStorage.setItem('loc_selected', (btn.innerText || btn.textContent || '').trim()); } catch(e) {}
            });
        });

        // Auto-scroll to visible detail panel after postback
        var detail = document.getElementById('PanelAssetsDetail');
        var filterDetail = document.getElementById('PanelAssetFilterDetail');
        var activeDetail = null;
        if (detail      && detail.style.display      !== 'none' && detail.offsetParent      !== null) activeDetail = detail;
        if (filterDetail && filterDetail.style.display !== 'none' && filterDetail.offsetParent !== null) activeDetail = filterDetail;
        if (activeDetail) {
            setTimeout(function () {
                activeDetail.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }, 200);
        }
    });

    // -- Lightweight column filter for detail grids (no DataTables dependency) --
    function initDetailFilter(id) {
        var tbl = document.getElementById(id);
        if (!tbl) return;
        var thead = tbl.querySelector('thead');
        var tbody = tbl.querySelector('tbody');
        if (!thead || !tbody || !tbody.querySelector('tr')) return;
        var origRow = thead.rows[0];
        // Add sort icons to header
        Array.from(origRow.cells).forEach(function(th, ci) {
            if (ci === 0 && th.querySelector('input[type="checkbox"]')) return;
            var txt = th.innerText.trim();
            th.innerHTML = txt + ' <span class="sh-si">&#9650;&#9660;</span>';
            th.style.cursor = 'pointer';
            th.title = 'Click to sort';
            var sortAsc = true;
            th.addEventListener('click', function() {
                sortAsc = !sortAsc;
                Array.from(origRow.cells).forEach(function(h) { h.classList.remove('sort-asc','sort-desc'); var s=h.querySelector('.sh-si'); if(s) s.innerHTML='&#9650;&#9660;'; });
                th.classList.add(sortAsc ? 'sort-asc' : 'sort-desc');
                var si = th.querySelector('.sh-si'); if (si) si.innerHTML = sortAsc ? '&#9650;' : '&#9660;';
                var rows = Array.from(tbody.querySelectorAll('tr[style*="display: none"], tr:not([style*="display: none"])')).filter(function(r){ return r.cells.length > 0; });
                rows.sort(function(a, b) {
                    var av = (a.cells[ci] ? a.cells[ci].innerText : '').trim();
                    var bv = (b.cells[ci] ? b.cells[ci].innerText : '').trim();
                    var n = parseFloat(av) - parseFloat(bv);
                    var r = isNaN(n) ? av.localeCompare(bv) : n;
                    return sortAsc ? r : -r;
                });
                rows.forEach(function(r) { tbody.appendChild(r); });
            });
        });
        // Filter row
        var filterRow = document.createElement('tr');
        for (var i = 0; i < origRow.cells.length; i++) {
            var th = document.createElement('th');
            th.className = origRow.cells[i].className;
            if (i === 0 && origRow.cells[0].querySelector('input[type="checkbox"]')) {
                th.style.width = '38px';
                filterRow.appendChild(th);
                continue;
            }
            var inp = document.createElement('input');
            inp.type = 'text'; inp.placeholder = '...'; inp.className = 'col-search';
            inp.setAttribute('data-col', i);
            th.appendChild(inp);
            filterRow.appendChild(th);
        }
        thead.appendChild(filterRow);
        filterRow.addEventListener('keyup', function() {
            var filters = [];
            filterRow.querySelectorAll('input').forEach(function(inp2) {
                filters.push({ col: parseInt(inp2.getAttribute('data-col')), val: inp2.value.toLowerCase() });
            });
            Array.from(tbody.querySelectorAll('tr')).forEach(function(row) {
                var show = filters.every(function(f) {
                    if (!f.val) return true;
                    var cell = row.cells[f.col];
                    return (cell ? (cell.innerText || cell.textContent || '') : '').toLowerCase().indexOf(f.val) !== -1;
                });
                row.style.display = show ? '' : 'none';
            });
        });
    }

    // --------------------------------------------------------------------------
    // DETAIL GRID CUSTOMIZABLE COLUMNS LOGIC
    // --------------------------------------------------------------------------
    var LOC_DETAIL_COLS = [
        { key: 'col-assetid', label: 'Asset ID',       locked: true,  defaultVis: true  },
        { key: 'col-desc',    label: 'Description',    locked: false, defaultVis: true  },
        { key: 'col-model',   label: 'Model',          locked: false, defaultVis: true  },
        { key: 'col-serial',  label: 'Serial #',       locked: false, defaultVis: true  },
        { key: 'col-mfr',     label: 'Manufacturer',   locked: false, defaultVis: false },
        { key: 'col-loc',     label: 'Location',       locked: false, defaultVis: true  },
        { key: 'col-cmr',     label: 'CMR',            locked: false, defaultVis: true  },
        { key: 'col-tagtype', label: 'Tag Type',       locked: false, defaultVis: true  },
        { key: 'col-status',  label: 'Status',         locked: false, defaultVis: true  },
        { key: 'col-rfid',    label: 'RFID Tag',       locked: false, defaultVis: false },
        { key: 'col-days',    label: 'Days Since',     locked: false, defaultVis: false },
        { key: 'col-lastinv', label: 'Last Inv',       locked: false, defaultVis: true  }
    ];

    function loadLocColsState() {
        try {
            var raw = localStorage.getItem('iDash_LocAssets_Cols');
            if (raw) {
                var state = JSON.parse(raw);
                LOC_DETAIL_COLS.forEach(function(c) {
                    if (c.locked) { c.visible = true; }
                    else if (typeof state[c.key] === 'boolean') { c.visible = state[c.key]; }
                    else { c.visible = c.defaultVis; }
                });
                return;
            }
        } catch(e) {}
        LOC_DETAIL_COLS.forEach(function(c) { c.visible = c.defaultVis; });
    }

    function saveLocColsState() {
        try {
            var state = {};
            LOC_DETAIL_COLS.forEach(function(c) { state[c.key] = c.visible; });
            localStorage.setItem('iDash_LocAssets_Cols', JSON.stringify(state));
        } catch(e) {}
    }

    function applyLocColVisibility(colKey, isVisible) {
        var sel = '.' + colKey;
        document.querySelectorAll('#GridAssetsDetail ' + sel + ', #GridAssetFilterDetail ' + sel).forEach(function(el) {
            el.style.display = isVisible ? '' : 'none';
        });
        if (!isVisible) {
            document.querySelectorAll('#GridAssetsDetail th' + sel + ' input.col-search, #GridAssetFilterDetail th' + sel + ' input.col-search').forEach(function(inp) {
                if (inp.value) {
                    inp.value = '';
                    if (inp.parentElement && inp.parentElement.parentElement) {
                        inp.parentElement.parentElement.dispatchEvent(new Event('keyup'));
                    }
                }
            });
        }
    }

    function updateLocColBadges() {
        var visCount = LOC_DETAIL_COLS.filter(function(c) { return c.visible; }).length;
        var totalCount = LOC_DETAIL_COLS.length;
        var txt = visCount + '/' + totalCount;
        var b1 = document.getElementById('badgeLocColsDetail');
        if (b1) b1.textContent = txt;
        var b2 = document.getElementById('badgeLocColsFilter');
        if (b2) b2.textContent = txt;
    }

    function applyAllLocCols() {
        LOC_DETAIL_COLS.forEach(function(col) {
            applyLocColVisibility(col.key, col.visible);
        });
        updateLocColBadges();
    }

    function buildLocColMenus() {
        ['locColPillsDetail', 'locColPillsFilter'].forEach(function(cid) {
            var c = document.getElementById(cid);
            if (!c) return;
            c.innerHTML = '';
            LOC_DETAIL_COLS.forEach(function(col) {
                var lbl = document.createElement('label');
                lbl.className = 'lcp-toggle' + (col.visible ? ' active' : '') + (col.locked ? ' locked' : '');
                lbl.title = col.locked ? 'Always required' : 'Toggle column visibility';
                lbl.innerHTML = '<input type="checkbox"' + (col.visible ? ' checked' : '') + (col.locked ? ' disabled' : '') + '> ' + col.label;

                if (!col.locked) {
                    lbl.querySelector('input').addEventListener('change', function() {
                        col.visible = this.checked;
                        lbl.classList.toggle('active', this.checked);
                        saveLocColsState();
                        applyLocColVisibility(col.key, col.visible);
                        updateLocColBadges();
                        buildLocColMenus(); // keep both menus synchronized
                    });
                }
                c.appendChild(lbl);
            });
        });
        updateLocColBadges();
    }

    window.toggleLocColMenu = function(menuId, ev) {
        if (ev) ev.stopPropagation();
        var menu = document.getElementById(menuId);
        if (!menu) return;
        var isOpen = (menu.style.display !== 'none');
        window.closeAllLocColMenus();
        if (!isOpen) {
            menu.style.display = 'block';
            var btn = menu.parentElement.querySelector('.btn-loc-cols');
            if (btn) btn.classList.add('open');
        }
    };

    window.closeAllLocColMenus = function() {
        document.querySelectorAll('.loc-col-popover').forEach(function(m) { m.style.display = 'none'; });
        document.querySelectorAll('.btn-loc-cols').forEach(function(b) { b.classList.remove('open'); });
    };

    window.applyLocPreset = function(preset) {
        if (preset === 'default') {
            LOC_DETAIL_COLS.forEach(function(c) { c.visible = c.defaultVis; });
        } else if (preset === 'all') {
            LOC_DETAIL_COLS.forEach(function(c) { c.visible = true; });
        } else if (preset === 'compact') {
            LOC_DETAIL_COLS.forEach(function(c) {
                c.visible = (c.key === 'col-assetid' || c.key === 'col-desc' || c.key === 'col-loc' || c.key === 'col-status');
            });
        }
        saveLocColsState();
        applyAllLocCols();
        buildLocColMenus();
    };

    window.resetLocCols = function() {
        window.applyLocPreset('default');
    };

    document.addEventListener('click', function(e) {
        if (!e.target.closest('.loc-cols-dropdown')) {
            window.closeAllLocColMenus();
        }
    });

</script>

<script type="text/javascript">
// -- SITE PERSISTENCE (shared across Asset Master / Stats / Locations) --
(function () {
    var SITE_KEY = 'iDash_selectedSite';
    var ddl = document.getElementById('<%= DdlCompany.ClientID %>');
    if (!ddl) return;
    ddl.addEventListener('change', function () {
        try { localStorage.setItem(SITE_KEY, this.value); } catch (e) {}
    });
    if (ddl.value === '0' || ddl.value === '') {
        try {
            var saved = localStorage.getItem(SITE_KEY);
            if (saved && saved !== '0' && saved !== '') {
                ddl.value = saved;
                if (ddl.value === saved) {
                    __doPostBack('<%= DdlCompany.UniqueID %>', '');
                }
            }
        } catch (e) {}
    }
})();
</script>

<script type="text/javascript">
// ------------------------------------------------------------------------------
// ASSET DETAIL SLIDE-OUT PANEL (reuses va_asset_master.aspx API endpoints)
// ------------------------------------------------------------------------------
(function () {
    var _adpCurrentId = null;
    var _adpCache = {};

    // -- Date formatters --
    function fmtDate(val) {
        if (!val) return '';
        var match = String(val).match(/\/Date\((-?\d+)\)\//);
        var d = match ? new Date(parseInt(match[1])) : new Date(val);
        if (isNaN(d.getTime())) return String(val);
        var mm = ('0'+(d.getMonth()+1)).slice(-2);
        var dd = ('0'+d.getDate()).slice(-2);
        var hh = ('0'+d.getHours()).slice(-2);
        var mi = ('0'+d.getMinutes()).slice(-2);
        return mm+'/'+dd+'/'+d.getFullYear()+' '+hh+':'+mi;
    }
    function fmtDateShort(val) {
        if (!val) return '';
        var match = String(val).match(/\/Date\((-?\d+)\)\//);
        var d = match ? new Date(parseInt(match[1])) : new Date(val);
        if (isNaN(d.getTime())) return String(val);
        return ('0'+(d.getMonth()+1)).slice(-2)+'/'+('0'+d.getDate()).slice(-2)+'/'+d.getFullYear();
    }
    function dpVal(v) {
        if (v === null || v === undefined || v === '') return '<span class="empty">&#8212;</span>';
        return String(v).replace(/</g, '&lt;');
    }
    function adpField(label, value) {
        var cls = (value === null || value === undefined || value === '') ? 'adp-val empty' : 'adp-val';
        var display = (value === null || value === undefined || value === '') ? '&#8212;' : String(value).replace(/</g, '&lt;');
        return '<div class="adp-field"><label>' + label + '</label><div class="' + cls + '">' + display + '</div></div>';
    }

    // -- Open panel --
    window.openAssetDetail = function (assetId, assetName) {
        _adpCurrentId = assetId;
        _adpCache = {};

        document.getElementById('adpTitle').textContent = assetName || 'Asset Detail';
        document.getElementById('adpEditLink').href = '/#!/admin/editasset/' + assetId;
        document.getElementById('adpMasterLink').href = 'va_asset_master.aspx';

        // Reset badges
        ['adpBadgeLoc','adpBadgeCO','adpBadgeMnt','adpBadgeChild'].forEach(function(id) {
            document.getElementById(id).textContent = '--';
        });

        // Reset to General tab
        document.querySelectorAll('.adp-tab').forEach(function(t) { t.classList.remove('active'); });
        document.querySelector('.adp-tab[data-tab="general"]').classList.add('active');
        document.querySelectorAll('.adp-tab-content').forEach(function(c) { c.classList.remove('active'); });
        document.getElementById('adp-tab-general').classList.add('active');

        // Show panel
        document.getElementById('assetDetailPanel').classList.add('open');
        document.body.classList.add('asset-detail-open');

        // Load General tab
        adpLoadGeneral(assetId);
        // Prefetch tab counts
        adpLoadCounts(assetId);
    };

    // -- Close panel --
    window.closeAssetDetail = function () {
        document.getElementById('assetDetailPanel').classList.remove('open');
        document.body.classList.remove('asset-detail-open');
        document.querySelectorAll('.detail-tbl tbody tr').forEach(function(r) { r.classList.remove('row-selected'); });
        _adpCurrentId = null;
    };

    // -- Escape key closes panel --
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && _adpCurrentId) closeAssetDetail();
    });

    // -- Tab switching --
    window.adpSwitchTab = function (btn) {
        var tab = btn.getAttribute('data-tab');
        document.querySelectorAll('.adp-tab').forEach(function(t) { t.classList.remove('active'); });
        btn.classList.add('active');
        document.querySelectorAll('.adp-tab-content').forEach(function(c) { c.classList.remove('active'); });
        document.getElementById('adp-tab-' + tab).classList.add('active');
        if (!_adpCache[tab]) {
            switch(tab) {
                case 'general':     adpLoadGeneral(_adpCurrentId); break;
                case 'lochistory':  adpLoadLocHistory(_adpCurrentId); break;
                case 'checkout':    adpLoadCheckout(_adpCurrentId); break;
                case 'maintenance': adpLoadMaintenance(_adpCurrentId); break;
                case 'children':    adpLoadChildren(_adpCurrentId); break;
            }
        }
    };

    // -- General Tab --
    function adpLoadGeneral(assetId) {
        var el = document.getElementById('adp-tab-general');
        el.innerHTML = '<div class="adp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=detail&id=' + assetId, function(data) {
            if (data.error) { el.innerHTML = '<div class="adp-empty">' + data.error + '</div>'; return; }
            _adpCache.general = data.asset;
            renderGeneral(data.asset);
        }).fail(function() { el.innerHTML = '<div class="adp-empty">Failed to load asset details.</div>'; });
    }

    function renderGeneral(a) {
        var el = document.getElementById('adp-tab-general');
        var h = '';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Identity</div><div class="adp-fields">';
        h += adpField('Asset Name', a.name);
        h += adpField('Description', a.description);
        h += adpField('Asset Type', a.assettype);
        h += adpField('RFID Tag', a.rfidtag);
        h += adpField('CMR #', a.text8);
        h += adpField('Serial #', a.text3);
        h += '</div></div>';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Location</div><div class="adp-fields">';
        h += adpField('Current Location', a.locationname);
        h += adpField('Building', a.locationbuilding);
        h += adpField('Floor', a.locationfloor);
        h += adpField('Room', a.locationroom);
        h += adpField('Last Observed Location', a.lastobservedlocation);
        h += adpField('Last Observed Time', fmtDate(a.lastobservedtime));
        h += adpField('Nearest Fixed Reader', a.nearestfixedname);
        h += adpField('Department Code', a.departmentcode);
        h += '</div></div>';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Status &amp; Checkout</div><div class="adp-fields">';
        h += adpField('Status', a.listvalue1);
        h += adpField('Checkout Status', a.checkinstatus);
        h += adpField('Checked Out To', a.checkedoutto);
        h += adpField('Disposal Status', a.disposalstatus);
        h += '</div></div>';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Details</div><div class="adp-fields">';
        h += adpField('Category', a.text4);
        h += adpField('Manufacturer', a.text1);
        h += adpField('Model', a.text2);
        h += adpField('Service', a.text5);
        h += adpField('Room', a.text6);
        h += adpField('Station', a.text7);
        h += adpField('PO #', a.text9);
        h += adpField('Previous Location', a.text11);
        h += '</div></div>';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Maintenance</div><div class="adp-fields">';
        h += adpField('Last Maintenance', fmtDateShort(a.lastmaintenance));
        h += adpField('Next Maintenance', fmtDateShort(a.nextmaintenance));
        h += adpField('Maintenance Method', a.maintenancemethod);
        h += adpField('Interval (Months)', a.maintenanceintervalmonths);
        h += '</div></div>';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Fixed Reader Observation</div><div class="adp-fields">';
        h += adpField('Last Observed', a.lastobservedtime ? fmtDate(a.lastobservedtime) : null);
        h += adpField('Observed Location', a.lastobservedlocation || null);
        h += '</div></div>';
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Inventory &amp; Dates</div><div class="adp-fields">';
        h += adpField('Last Inventoried', fmtDateShort(a.lastinventoried));
        h += adpField('Created', fmtDate(a.created));
        h += adpField('Last Modified', fmtDate(a.lastmodified));
        h += adpField('Modified By', a.lastmodifiedby);
        h += '</div></div>';
        if (a.vtagid) {
            h += '<div class="adp-field-group"><div class="adp-field-group-title">V-Tag Sensor</div><div class="adp-fields">';
            h += adpField('V-Tag ID', a.vtagid);
            h += adpField('V-Tag Type', a.vtagtype);
            h += adpField('Battery Level', a.batterylevel ? a.batterylevel + '%' : null);
            h += '</div></div>';
        }
        h += '<div class="adp-field-group"><div class="adp-field-group-title">Additional Information</div>';
        h += '<div class="adp-fields single">' + adpField('Notes', a.additionalinformation) + '</div></div>';
        el.innerHTML = h;
    }

    // -- Prefetch tab counts --
    function adpLoadCounts(assetId) {
        $.getJSON('va_asset_master.aspx?api=locationhistory&id=' + assetId, function(d) {
            document.getElementById('adpBadgeLoc').textContent = d.total || 0;
            if (d.total > 0) _adpCache.lochistory_data = d.records;
        });
        $.getJSON('va_asset_master.aspx?api=checkouthistory&id=' + assetId, function(d) {
            document.getElementById('adpBadgeCO').textContent = d.total || 0;
            if (d.total > 0) _adpCache.checkout_data = d.records;
        });
        $.getJSON('va_asset_master.aspx?api=maintenance&id=' + assetId, function(d) {
            document.getElementById('adpBadgeMnt').textContent = d.total || 0;
            if (d.total > 0) _adpCache.maintenance_data = d.records;
        });
        $.getJSON('va_asset_master.aspx?api=children&id=' + assetId, function(d) {
            document.getElementById('adpBadgeChild').textContent = d.total || 0;
            if (d.total > 0) _adpCache.children_data = d.records;
        });
    }

    // -- Location History Tab --
    function adpLoadLocHistory(assetId) {
        var el = document.getElementById('adp-tab-lochistory');
        var records = _adpCache.lochistory_data;
        if (records) { renderLocHistory(el, records); _adpCache.lochistory = true; return; }
        el.innerHTML = '<div class="adp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=locationhistory&id=' + assetId, function(d) { renderLocHistory(el, d.records || []); _adpCache.lochistory = true; });
    }
    function renderLocHistory(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="adp-empty"><span class="adp-empty-icon">&#128205;</span>No location history records found.</div>'; return; }
        var html = '<table class="adp-history-table"><thead><tr><th>Location</th><th>Building</th><th>Time Seen</th><th>Time Left</th></tr></thead><tbody>';
        records.forEach(function(r) { html += '<tr><td><strong>' + dpVal(r.locationname) + '</strong></td><td>' + dpVal(r.building) + '</td><td>' + fmtDate(r.timeseen) + '</td><td>' + fmtDate(r.timeleft) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // -- Checkout History Tab --
    function adpLoadCheckout(assetId) {
        var el = document.getElementById('adp-tab-checkout');
        var records = _adpCache.checkout_data;
        if (records) { renderCheckout(el, records); _adpCache.checkout = true; return; }
        el.innerHTML = '<div class="adp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=checkouthistory&id=' + assetId, function(d) { renderCheckout(el, d.records || []); _adpCache.checkout = true; });
    }
    function renderCheckout(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="adp-empty"><span class="adp-empty-icon">&#128100;</span>No checkout history records found.</div>'; return; }
        var html = '<table class="adp-history-table"><thead><tr><th>Status</th><th>Individual</th><th>Location</th><th>Date</th></tr></thead><tbody>';
        records.forEach(function(r) { var cls = (r.checkinstatus === 'Checked Out') ? 'pct-warn' : 'pct-good'; html += '<tr><td><span class="' + cls + '">' + dpVal(r.checkinstatus) + '</span></td><td>' + dpVal(r.individual) + '</td><td>' + dpVal(r.locationname) + '</td><td>' + fmtDate(r.transactiontime) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // -- Maintenance History Tab --
    function adpLoadMaintenance(assetId) {
        var el = document.getElementById('adp-tab-maintenance');
        var records = _adpCache.maintenance_data;
        if (records) { renderMaintenance(el, records); _adpCache.maintenance = true; return; }
        el.innerHTML = '<div class="adp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=maintenance&id=' + assetId, function(d) { renderMaintenance(el, d.records || []); _adpCache.maintenance = true; });
    }
    function renderMaintenance(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="adp-empty"><span class="adp-empty-icon">&#128295;</span>No maintenance records found.</div>'; return; }
        var html = '<table class="adp-history-table"><thead><tr><th>Date</th><th>Action</th><th>Performed By</th><th>Notes</th></tr></thead><tbody>';
        records.forEach(function(r) { html += '<tr><td>' + fmtDate(r.whenperformed) + '</td><td><strong>' + dpVal(r.actionperformed) + '</strong></td><td>' + dpVal(r.performedby) + '</td><td>' + dpVal(r.notes) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // -- Children Tab --
    function adpLoadChildren(assetId) {
        var el = document.getElementById('adp-tab-children');
        var records = _adpCache.children_data;
        if (records) { renderChildren(el, records); _adpCache.children = true; return; }
        el.innerHTML = '<div class="adp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=children&id=' + assetId, function(d) { renderChildren(el, d.records || []); _adpCache.children = true; });
    }
    function renderChildren(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="adp-empty"><span class="adp-empty-icon">&#128279;</span>No child assets found.</div>'; return; }
        var html = '<table class="adp-history-table"><thead><tr><th>Name</th><th>Description</th><th>Location</th><th>Status</th></tr></thead><tbody>';
        records.forEach(function(r) { html += '<tr style="cursor:pointer;" onclick="openAssetDetail(' + r.id + ',\x27' + (r.name||'').replace(/'/g,"\\'") + '\x27)"><td><strong style="color:var(--accent);">' + dpVal(r.name) + '</strong></td><td>' + dpVal(r.description) + '</td><td>' + dpVal(r.locationname) + '</td><td>' + dpVal(r.listvalue1) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // --------------------------------------------------------------------------
    // LOCATION ASSET PRINTING LOGIC
    // --------------------------------------------------------------------------
    var _selectedPrintAssets = [];
    var _activeGridForPrint = 'GridAssetsDetail';

    window.toggleAllLocAssets = function (masterCb) {
        var tbl = masterCb.closest('table');
        if (!tbl) return;
        var isChecked = masterCb.checked;
        var boxes = tbl.querySelectorAll('tbody tr .chk-loc-asset');
        boxes.forEach(function (cb) {
            var tr = cb.closest('tr');
            if (!tr || tr.style.display === 'none') return;
            cb.checked = isChecked;
        });
        window.updateLocSelectionCount();
    };

    window.updateLocSelectionCount = function () {
        ['GridAssetsDetail', 'GridAssetFilterDetail'].forEach(function (gid) {
            var tbl = document.getElementById(gid);
            var badge = document.getElementById('badge' + gid);
            if (!tbl || !badge) return;
            var checked = tbl.querySelectorAll('tbody tr .chk-loc-asset:checked').length;
            badge.textContent = checked;
        });
    };

    function getSelectedSiteId() {
        var ddl = document.getElementById('<%= DdlCompany.ClientID %>');
        return ddl ? ddl.value : '0';
    }

    function loadPrintTemplates(selectedTplId, callback) {
        var siteId = getSelectedSiteId();
        var sel = document.getElementById('locPrintTemplate');
        if (!sel) return;
        sel.innerHTML = '<option value="">Loading templates...</option>';

        $.ajax({
            type: 'POST',
            url: 'va_location_list.aspx/GetPrintTemplates',
            data: JSON.stringify({ siteId: siteId }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (resp) {
                var data = typeof resp.d === 'string' ? JSON.parse(resp.d) : resp.d;
                sel.innerHTML = '';
                if (data.success && data.templates && data.templates.length > 0) {
                    data.templates.forEach(function (t) {
                        var opt = document.createElement('option');
                        opt.value = t.id;
                        opt.textContent = t.name + ' (Site ' + t.companyId + ')';
                        if (selectedTplId && String(t.id) === String(selectedTplId)) opt.selected = true;
                        sel.appendChild(opt);
                    });
                } else {
                    sel.innerHTML = '<option value="">No templates available</option>';
                }
                if (callback) callback();
            },
            error: function () {
                sel.innerHTML = '<option value="">Error loading templates</option>';
            }
        });
    }

    window.openLocPrintModal = function (gridId) {
        _activeGridForPrint = gridId || 'GridAssetsDetail';
        var tbl = document.getElementById(_activeGridForPrint);
        if (!tbl) return;

        _selectedPrintAssets = [];
        var checkedBoxes = tbl.querySelectorAll('tbody tr .chk-loc-asset:checked');

        if (checkedBoxes.length === 0) {
            var visibleBoxes = [];
            tbl.querySelectorAll('tbody tr .chk-loc-asset').forEach(function (cb) {
                var tr = cb.closest('tr');
                if (tr && tr.style.display !== 'none') visibleBoxes.push(cb);
            });

            if (visibleBoxes.length === 0) {
                alert('No assets found in this view to print.');
                return;
            }
            if (confirm('No assets were individually selected. Would you like to print all ' + visibleBoxes.length + ' assets in this location list?')) {
                visibleBoxes.forEach(function (cb) {
                    cb.checked = true;
                    collectAssetFromCheckbox(cb);
                });
                window.updateLocSelectionCount();
            } else {
                return;
            }
        } else {
            checkedBoxes.forEach(function (cb) {
                collectAssetFromCheckbox(cb);
            });
        }

        renderPrintModal();
    };

    function collectAssetFromCheckbox(cb) {
        var tr = cb.closest('tr');
        var id = cb.value;
        var name = cb.getAttribute('data-name') || '';
        var cells = tr.querySelectorAll('td');
        // cell 0: checkbox, cell 1: Name, cell 2: Location, cell 3: CMR, cell 4: Tag Type
        var loc = cells[2] ? (cells[2].innerText || '').trim() : '';
        var cmr = cells[3] ? (cells[3].innerText || '').trim() : '';
        var tag = cells[4] ? (cells[4].innerText || '').trim() : '';
        _selectedPrintAssets.push({ id: id, name: name, location: loc, cmr: cmr, tagType: tag });
    }

    window.printFromAssetDetail = function () {
        if (!_adpCurrentId) {
            alert('No asset currently loaded in the detail panel.');
            return;
        }
        var titleEl = document.getElementById('adpTitle');
        var name = titleEl ? titleEl.innerText : 'Asset #' + _adpCurrentId;
        _selectedPrintAssets = [{
            id: _adpCurrentId,
            name: name,
            location: '',
            cmr: '',
            tagType: ''
        }];
        renderPrintModal();
    };

    function renderPrintModal() {
        var overlay = document.getElementById('locPrintOverlay');
        var summary = document.getElementById('locPrintAssetSummary');
        var tbody = document.getElementById('locPrintPreviewBody');
        var status = document.getElementById('locPrintStatus');
        var btn = document.getElementById('btnExecuteLocPrint');

        if (!overlay || !summary || !tbody) return;

        summary.textContent = _selectedPrintAssets.length + ' asset(s) ready to print';
        tbody.innerHTML = '';
        status.innerHTML = '';
        status.className = 'pm-status';
        btn.disabled = false;
        btn.innerHTML = '&#128424; Send to Printer (' + _selectedPrintAssets.length + ')';

        _selectedPrintAssets.forEach(function (a) {
            var tr = document.createElement('tr');
            tr.innerHTML = '<td><strong style="color:var(--accent);">' + (a.name || 'ID: ' + a.id) + '</strong></td>'
                         + '<td>' + (a.location || '&mdash;') + '</td>'
                         + '<td>' + (a.cmr || '&mdash;') + '</td>'
                         + '<td>' + (a.tagType || '&mdash;') + '</td>';
            tbody.appendChild(tr);
        });

        loadPrintTemplates(null);
        overlay.classList.add('open');
    }

    window.closeLocPrintModal = function () {
        var overlay = document.getElementById('locPrintOverlay');
        if (overlay) overlay.classList.remove('open');
    };

    window.executeLocPrint = function () {
        if (_selectedPrintAssets.length === 0) {
            alert('No assets selected.');
            return;
        }
        var tplSel = document.getElementById('locPrintTemplate');
        var templateId = tplSel ? parseInt(tplSel.value) || 0 : 0;
        var siteId = getSelectedSiteId();
        var status = document.getElementById('locPrintStatus');
        var btn = document.getElementById('btnExecuteLocPrint');

        var assetIds = _selectedPrintAssets.map(function (a) { return String(a.id); });

        btn.disabled = true;
        btn.innerHTML = 'Printing...';
        status.innerHTML = '<span style="color:var(--accent);">&#9696; Sending ' + assetIds.length + ' label(s) to native Print Server...</span>';

        $.ajax({
            type: 'POST',
            url: 'va_location_list.aspx/SubmitPrintJobs',
            data: JSON.stringify({
                siteId: siteId,
                assetIdsJson: JSON.stringify(assetIds),
                templateId: templateId
            }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (resp) {
                var res = typeof resp.d === 'string' ? JSON.parse(resp.d) : resp.d;
                if (res.success) {
                    status.innerHTML = '<span style="color:var(--accent-2);">&#10004; Successfully sent ' + res.jobsCreated + ' label(s) to the Print Server!</span>';
                    btn.innerHTML = '&#10004; Printed!';
                    setTimeout(function () {
                        window.closeLocPrintModal();
                        document.querySelectorAll('.chk-loc-asset:checked').forEach(function (cb) { cb.checked = false; });
                        var mcb = document.querySelector('.chk-all-loc-assets');
                        if (mcb) mcb.checked = false;
                        window.updateLocSelectionCount();
                    }, 2000);
                } else {
                    status.innerHTML = '<span style="color:var(--danger);">&#10008; ' + (res.error || 'Print failed') + '</span>';
                    btn.disabled = false;
                    btn.innerHTML = '&#128424; Retry';
                }
            },
            error: function (xhr, statusText, err) {
                status.innerHTML = '<span style="color:var(--danger);">&#10008; Request failed: ' + (err || statusText) + '</span>';
                btn.disabled = false;
                btn.innerHTML = '&#128424; Retry';
            }
        });
    };

    // -- Wire up click handlers on asset grid rows --
    function wireAssetRows(gridId) {
        var tbl = document.getElementById(gridId);
        if (!tbl) return;
        var tbody = tbl.querySelector('tbody');
        if (!tbody) return;
        Array.from(tbody.rows).forEach(function(row) {
            var assetId = row.getAttribute('data-asset-id');
            if (!assetId) return;
            row.style.cursor = 'pointer';
            row.addEventListener('click', function(e) {
                // Don't intercept link or checkbox clicks
                if (e.target.tagName === 'A' || e.target.tagName === 'INPUT') return;
                // Clear previous selection
                document.querySelectorAll('.detail-tbl tbody tr').forEach(function(r) { r.classList.remove('row-selected'); });
                row.classList.add('row-selected');
                // Get asset name
                var name = row.getAttribute('data-asset-name') || '';
                if (!name) {
                    for (var i = 1; i < row.cells.length; i++) {
                        if (row.cells[i].style.display !== 'none') { name = (row.cells[i].innerText || row.cells[i].textContent || '').trim(); break; }
                    }
                }
                openAssetDetail(parseInt(assetId), name);
            });
        });
    }

    // Init: wire up both detail grids on page load
    wireAssetRows('GridAssetsDetail');
    wireAssetRows('GridAssetFilterDetail');
    window.updateLocSelectionCount();
})();
</script>
</body>
</html>


