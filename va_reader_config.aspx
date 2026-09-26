<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_reader_config.aspx.cs" Inherits="iDash.va_reader_config" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <title>Fixed Reader Configuration &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    :root { --green:#10B981; --red:#EF4444; --amber:#F59E0B; --purple:#8B5CF6; --cyan:#06B6D4; }
    *{box-sizing:border-box;}
    body{margin:0;padding:0;background:var(--bg);color:var(--text);font-family:'Inter','Segoe UI',sans-serif;
         background-image:radial-gradient(circle at top left,color-mix(in srgb,var(--accent),transparent 95%),transparent 40%),
                          radial-gradient(circle at bottom right,rgba(139,92,246,.06),transparent 40%);min-height:100vh;}
    .dash{max-width:1480px;margin:0 auto;padding:28px 24px;}

    /* HEADER */
    .page-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;border-bottom:1px solid var(--line);padding-bottom:16px;flex-wrap:wrap;gap:12px;}
    .page-header h1{margin:0;font-size:22px;font-weight:700;background:linear-gradient(90deg,#8B5CF6,#06B6D4);-webkit-background-clip:text;-webkit-text-fill-color:transparent;}
    .hdr-right{display:flex;gap:8px;align-items:center;flex-wrap:wrap;}
    .ctrl-select{background:var(--chip);color:var(--text);border:1px solid var(--line);padding:7px 12px;border-radius:8px;font-size:13px;outline:none;font-family:inherit;}
    .ctrl-select option{background:var(--card);color:var(--text);}

    .hdr-pill{display:inline-flex;align-items:center;gap:5px;padding:6px 12px;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;border:1px solid var(--line);background:transparent;color:var(--accent);text-decoration:none;transition:background .15s,border-color .15s;}
    .hdr-pill:hover{border-color:var(--accent);background:color-mix(in srgb,var(--accent),transparent 90%);}
    .hdr-pill.primary{background:color-mix(in srgb,var(--accent),transparent 85%);color:var(--accent);border-color:var(--accent);}
    .hdr-pill.primary:hover{background:color-mix(in srgb,var(--accent),transparent 75%);}
    .hdr-pill.danger{color:var(--red);border-color:var(--red);}
    .hdr-pill.danger:hover{background:color-mix(in srgb,var(--red),transparent 85%);}

    /* KPI */
    .kpi-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:20px;}
    @media(max-width:900px){.kpi-row{grid-template-columns:repeat(2,1fr);}}
    .kpi-card{text-align:center;padding:20px 14px;background:var(--card);border:1px solid var(--line);border-radius:14px;transition:all .2s;}
    .kpi-card:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(0,0,0,.2);}
    .kpi-val{font-size:32px;font-weight:700;line-height:1;margin-bottom:4px;}
    .kpi-lbl{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.7px;color:var(--muted);}

    /* PANELS */
    .panel{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:20px;margin-bottom:18px;transition:all .2s;}
    .panel:hover{box-shadow:0 8px 28px rgba(0,0,0,.15);}
    .panel-title{font-size:13px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.7px;border-bottom:1px solid var(--line);padding-bottom:10px;margin-bottom:14px;display:flex;justify-content:space-between;align-items:center;}

    /* TABLE */
    .tbl{width:100%;border-collapse:collapse;font-size:13px;}
    .tbl th{background:var(--chip);color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.5px;padding:9px 12px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap;position:sticky;top:0;z-index:1;}
    .tbl td{padding:9px 12px;border-bottom:1px solid var(--line);color:var(--text);vertical-align:middle;}
    .tbl tbody tr{cursor:pointer;transition:background .15s;}
    .tbl tbody tr:hover td{background:var(--chip);}
    .tbl-wrap{max-height:520px;overflow-y:auto;border-radius:10px;border:1px solid var(--line);}

    /* STATUS DOT */
    .dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:6px;}
    .dot-up{background:var(--green);box-shadow:0 0 6px rgba(16,185,129,.5);}
    .dot-down{background:var(--red);box-shadow:0 0 6px rgba(239,68,68,.5);}

    /* BADGES */
    .badge{display:inline-block;padding:3px 10px;border-radius:12px;font-size:11px;font-weight:600;}
    .badge-up{background:color-mix(in srgb,var(--green) 15%,transparent);color:var(--green);border:1px solid var(--green);}
    .badge-down{background:color-mix(in srgb,var(--red) 15%,transparent);color:var(--red);border:1px solid var(--red);}

    /* BTN */
    .btn{display:inline-flex;align-items:center;gap:5px;padding:7px 14px;border-radius:8px;font-size:12px;font-weight:600;cursor:pointer;border:1px solid;transition:all .2s;font-family:inherit;text-decoration:none;}
    .btn-sm{padding:4px 10px;font-size:11px;border-radius:6px;}
    .btn-primary{background:color-mix(in srgb,var(--accent),transparent 85%);color:var(--accent);border-color:var(--accent);}
    .btn-primary:hover{background:color-mix(in srgb,var(--accent),transparent 75%);}
    .btn-danger{background:color-mix(in srgb,var(--red),transparent 90%);color:var(--red);border-color:var(--red);}
    .btn-danger:hover{background:color-mix(in srgb,var(--red),transparent 80%);}
    .btn-ghost{background:transparent;color:var(--muted);border-color:var(--line);}
    .btn-ghost:hover{color:var(--text);border-color:var(--text);}
    .btn-green{background:color-mix(in srgb,var(--green),transparent 85%);color:var(--green);border-color:var(--green);}
    .btn-green:hover{background:color-mix(in srgb,var(--green),transparent 75%);}

    /* MODAL */
    .modal-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.6);backdrop-filter:blur(4px);z-index:1000;display:none;justify-content:center;align-items:flex-start;padding-top:60px;}
    .modal-overlay.active{display:flex;}
    .modal{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:28px;width:580px;max-width:95vw;max-height:80vh;overflow-y:auto;box-shadow:0 24px 48px rgba(0,0,0,.4);animation:slideUp .25s ease;}
    @keyframes slideUp{from{opacity:0;transform:translateY(20px);}to{opacity:1;transform:translateY(0);}}
    .modal h2{margin:0 0 20px 0;font-size:18px;font-weight:700;}
    .modal .form-group{margin-bottom:14px;}
    .modal label{display:block;font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px;}
    .modal input,.modal select{width:100%;padding:9px 12px;border:1px solid var(--line);border-radius:8px;background:var(--chip);color:var(--text);font-size:13px;font-family:inherit;outline:none;transition:border-color .2s;}
    .modal input:focus,.modal select:focus{border-color:var(--accent);}
    .modal .row{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
    .modal .actions{display:flex;gap:8px;justify-content:flex-end;margin-top:20px;padding-top:16px;border-top:1px solid var(--line);}
    .toggle-row{display:flex;align-items:center;gap:12px;padding:8px 0;}
    .toggle-row label{margin:0;text-transform:none;font-size:13px;color:var(--text);}
    .toggle{position:relative;width:40px;height:22px;flex-shrink:0;}
    .toggle input{opacity:0;width:0;height:0;}
    .toggle .slider{position:absolute;top:0;left:0;right:0;bottom:0;background:var(--line);border-radius:22px;cursor:pointer;transition:background .2s;}
    .toggle .slider::before{content:'';position:absolute;width:16px;height:16px;left:3px;bottom:3px;background:var(--text);border-radius:50%;transition:transform .2s;}
    .toggle input:checked+.slider{background:var(--accent);}
    .toggle input:checked+.slider::before{transform:translateX(18px);}

    /* ANTENNA SUB-TABLE */
    .ant-section{margin-top:8px;padding:12px;background:color-mix(in srgb,var(--accent),transparent 96%);border:1px solid color-mix(in srgb,var(--accent),transparent 80%);border-radius:10px;}
    .ant-section .panel-title{font-size:12px;margin-bottom:10px;padding-bottom:8px;}
    .ant-row{display:grid;grid-template-columns:60px 1fr 80px 40px;gap:8px;align-items:center;margin-bottom:6px;}
    .ant-row input,.ant-row select{padding:6px 8px;font-size:12px;border-radius:6px;border:1px solid var(--line);background:var(--chip);color:var(--text);font-family:inherit;}
    .ant-remove{cursor:pointer;color:var(--red);font-size:16px;text-align:center;}
    .ant-remove:hover{transform:scale(1.2);}

    /* SEARCH */
    .search-input{background:var(--chip);color:var(--text);border:1px solid var(--line);padding:8px 14px;border-radius:8px;font-size:13px;outline:none;width:220px;font-family:inherit;transition:border-color .2s;}
    .search-input:focus{border-color:var(--accent);}

    /* MSG */
    .msg{padding:10px 16px;border-radius:8px;font-size:13px;margin-bottom:14px;display:none;}
    .msg-ok{background:color-mix(in srgb,var(--green),transparent 88%);color:var(--green);border:1px solid var(--green);}
    .msg-err{background:color-mix(in srgb,var(--red),transparent 88%);color:var(--red);border:1px solid var(--red);}

    /* EMPTY STATE */
    .empty{text-align:center;padding:40px 20px;color:var(--muted);font-size:14px;}
    .empty-icon{font-size:48px;margin-bottom:10px;opacity:.6;}

    /* RESPONSIVE */
    @media(max-width:600px){
        .ant-row{grid-template-columns:1fr 1fr;} 
        .modal .row{grid-template-columns:1fr;}
    }

    /* HARDWARE INTELLIGENCE CARDS */
    .hw-card{background:var(--chip);border:1px solid var(--line);border-radius:12px;overflow:hidden;transition:all .2s;}
    .hw-card:hover{box-shadow:0 4px 16px rgba(0,0,0,.15);transform:translateY(-1px);}
    .hw-card-hdr{display:flex;justify-content:space-between;align-items:center;padding:10px 14px;
        border-bottom:1px solid var(--line);border-left:4px solid var(--muted);background:var(--card);transition:border-left-color .3s;}
    .hw-card-name{font-weight:700;font-size:13px;color:var(--text);}
    .hw-card-ip{font-size:11px;color:var(--muted);background:var(--chip);padding:2px 8px;border-radius:4px;}
    .hw-card-body{padding:10px 14px;}
    .hw-loading{text-align:center;padding:16px;color:var(--muted);font-size:12px;}
    .hw-error{padding:8px;}
    .hw-tbl{width:100%;font-size:12px;border-collapse:collapse;}
    .hw-tbl td{padding:3px 6px;border-bottom:1px solid color-mix(in srgb,var(--line),transparent 50%);}
    .hw-lbl{color:var(--muted);font-weight:500;width:100px;white-space:nowrap;}
    .hw-val{color:var(--text);font-weight:600;}
    .hw-val code{background:var(--card);padding:1px 6px;border-radius:4px;font-size:11px;}
    .hw-actions{display:flex;gap:4px;margin-top:8px;padding-top:8px;border-top:1px solid var(--line);}
    .hw-btn{background:var(--card);border:1px solid var(--line);color:var(--text);padding:4px 10px;border-radius:6px;
        font-size:12px;cursor:pointer;transition:all .15s;text-decoration:none;text-align:center;display:inline-block;}
    .hw-btn:hover{background:color-mix(in srgb,var(--accent),transparent 85%);border-color:var(--accent);}


    /* API / OAUTH SECTIONS */
    .oauth-section{border-bottom:1px solid var(--line);margin-bottom:20px;padding-bottom:20px;}
    .oauth-section-hdr{display:flex;align-items:flex-start;gap:14px;}
    .oauth-icon{font-size:28px;line-height:1;flex-shrink:0;margin-top:2px;}
    .oauth-section-title{font-size:14px;font-weight:700;color:var(--text);margin-bottom:5px;}
    .oauth-section-desc{font-size:12px;color:var(--muted);line-height:1.6;}
    .oauth-section-desc strong{color:var(--text);}
    .oauth-section-desc code{background:var(--chip);padding:1px 5px;border-radius:4px;font-size:11px;color:var(--accent);}

    /* ═══ READER MANAGEMENT CONSOLE ═══ */

    /* Tab navigation in HW cards */
    .mgmt-tabs{display:flex;gap:0;border-bottom:1px solid var(--line);background:var(--card);overflow-x:auto;}
    .mgmt-tab{padding:8px 14px;font-size:11px;font-weight:600;color:var(--muted);cursor:pointer;border:none;background:none;
        border-bottom:2px solid transparent;transition:all .15s;white-space:nowrap;font-family:inherit;text-transform:uppercase;letter-spacing:.4px;}
    .mgmt-tab:hover{color:var(--text);background:color-mix(in srgb,var(--accent),transparent 95%);}
    .mgmt-tab.active{color:var(--accent);border-bottom-color:var(--accent);background:color-mix(in srgb,var(--accent),transparent 93%);}
    .mgmt-pane{display:none;padding:14px;}
    .mgmt-pane.active{display:block;}

    /* Control panel */
    .ctrl-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;}
    .ctrl-item{display:flex;flex-direction:column;gap:4px;}
    .ctrl-label{font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;}
    .ctrl-value{font-size:13px;font-weight:600;color:var(--text);}
    .ctrl-row{display:flex;align-items:center;gap:8px;flex-wrap:wrap;}

    /* Mode badge */
    .mode-badge{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;}
    .mode-badge.reading{background:color-mix(in srgb,var(--green),transparent 85%);color:var(--green);border:1px solid var(--green);animation:pulse-border 2s infinite;}
    .mode-badge.stopped{background:color-mix(in srgb,var(--red),transparent 88%);color:var(--red);border:1px solid var(--red);}
    @keyframes pulse-border{0%,100%{box-shadow:0 0 0 0 color-mix(in srgb,var(--green),transparent 60%);}50%{box-shadow:0 0 0 4px transparent;}}

    /* Antenna power sliders */
    .power-row{display:flex;align-items:center;gap:8px;padding:4px 0;}
    .power-row label{font-size:12px;font-weight:600;min-width:32px;color:var(--purple);}
    .power-row input[type=range]{flex:1;accent-color:var(--accent);height:6px;}
    .power-row .power-val{font-size:11px;font-weight:700;font-family:'JetBrains Mono',monospace;min-width:55px;text-align:right;color:var(--text);}

    /* Log viewer */
    .log-viewer{background:#0d1117;color:#c9d1d9;border:1px solid var(--line);border-radius:8px;padding:12px;
        font-family:'JetBrains Mono','Consolas',monospace;font-size:11px;line-height:1.6;max-height:400px;overflow:auto;white-space:pre-wrap;word-break:break-all;}
    .log-toolbar{display:flex;gap:8px;align-items:center;margin-bottom:8px;flex-wrap:wrap;}
    .log-select{background:var(--chip);color:var(--text);border:1px solid var(--line);padding:5px 10px;border-radius:6px;font-size:12px;font-family:inherit;}

    /* GPIO grid */
    .gpio-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;}
    .gpio-item{text-align:center;padding:10px;border:1px solid var(--line);border-radius:10px;background:var(--card);transition:all .2s;}
    .gpio-label{font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;}
    .gpio-val{font-size:14px;font-weight:700;margin-top:4px;}
    .gpio-val.high{color:var(--green);}
    .gpio-val.low{color:var(--muted);}
    .gpio-toggle{margin-top:6px;}
    .gpio-toggle select{width:100%;padding:4px;border-radius:4px;border:1px solid var(--line);background:var(--chip);color:var(--text);font-size:11px;font-family:inherit;}

    /* LED control */
    .led-controls{display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;}
    .led-group{display:flex;flex-direction:column;gap:3px;}
    .led-group label{font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;}
    .led-group select,.led-group input{padding:6px 10px;border-radius:6px;border:1px solid var(--line);background:var(--chip);color:var(--text);font-size:12px;font-family:inherit;}

    /* Network config table */
    .net-tbl{width:100%;font-size:12px;border-collapse:collapse;}
    .net-tbl td{padding:6px 8px;border-bottom:1px solid color-mix(in srgb,var(--line),transparent 40%);}
    .net-tbl .net-lbl{color:var(--muted);font-weight:600;width:140px;white-space:nowrap;}
    .net-tbl .net-val{color:var(--text);font-weight:600;font-family:'JetBrains Mono',monospace;font-size:12px;}
    .net-tbl input{width:100%;padding:4px 8px;border:1px solid var(--line);border-radius:4px;background:var(--chip);color:var(--text);font-size:12px;font-family:'JetBrains Mono',monospace;}

    /* Mini status indicator */
    .status-chip{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;border-radius:10px;font-size:10px;font-weight:600;}
    .status-chip.ok{background:color-mix(in srgb,var(--green),transparent 88%);color:var(--green);}
    .status-chip.err{background:color-mix(in srgb,var(--red),transparent 88%);color:var(--red);}
    .status-chip.warn{background:color-mix(in srgb,var(--amber),transparent 88%);color:var(--amber);}

    /* Quick action buttons row */
    .qa-row{display:flex;gap:4px;flex-wrap:wrap;padding:6px 0;}
    .qa-btn{display:inline-flex;align-items:center;gap:3px;padding:3px 8px;border-radius:5px;font-size:10px;font-weight:600;
        cursor:pointer;border:1px solid var(--line);background:var(--card);color:var(--text);transition:all .15s;font-family:inherit;}
    .qa-btn:hover{border-color:var(--accent);color:var(--accent);background:color-mix(in srgb,var(--accent),transparent 92%);}
    .qa-btn.grn{border-color:var(--green);color:var(--green);}.qa-btn.grn:hover{background:color-mix(in srgb,var(--green),transparent 88%);}
    .qa-btn.red{border-color:var(--red);color:var(--red);}.qa-btn.red:hover{background:color-mix(in srgb,var(--red),transparent 88%);}
    .qa-btn.amb{border-color:var(--amber);color:var(--amber);}.qa-btn.amb:hover{background:color-mix(in srgb,var(--amber),transparent 88%);}
    .qa-btn.pur{border-color:var(--purple);color:var(--purple);}.qa-btn.pur:hover{background:color-mix(in srgb,var(--purple),transparent 88%);}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- HEADER -->
    <div class="page-header">
        <h1>&#128225; Fixed Readers</h1>
        <div class="hdr-right">
            <span style="font-size:12px;color:var(--muted);font-weight:600;">Site</span>
            <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select" ClientIDMode="Static" />
            <button type="button" class="nav-pill nav-pill-primary" onclick="openAddReader()">&#10010; Add Reader</button>
            <button type="button" class="nav-pill nav-pill-ghost" onclick="loadAll()">&#8635; Refresh</button>
            <div style="width:1px;height:20px;background:var(--line);"></div>
            <a href="va_asset_master.aspx" class="nav-pill nav-pill-ghost">&#128203; Asset Master</a>
            <a href="va_fixed_reader.aspx" class="nav-pill nav-pill-ghost">&#128202; Fixed Readers</a>
            <a href="va_fixed_reader_live.aspx" class="nav-pill nav-pill-ghost" target="_blank">&#128225; Live Feed</a>
            <div style="width:1px;height:20px;background:var(--line);"></div>
            <a href="documentation/va_reader_config.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <!-- MESSAGE BAR -->
    <div class="msg msg-ok" id="msgOk"></div>
    <div class="msg msg-err" id="msgErr"></div>

    <!-- KPI ROW -->
    <div class="kpi-row">
        <div class="kpi-card"><div class="kpi-val" id="kTotal" style="color:var(--accent);">--</div><div class="kpi-lbl">Total Readers</div></div>
        <div class="kpi-card"><div class="kpi-val" id="kOnline" style="color:var(--green);">--</div><div class="kpi-lbl">Online</div></div>
        <div class="kpi-card"><div class="kpi-val" id="kOffline" style="color:var(--red);">--</div><div class="kpi-lbl">Offline</div></div>
        <div class="kpi-card"><div class="kpi-val" id="kModels" style="color:var(--purple);">--</div><div class="kpi-lbl">Models</div></div>
    </div>

    <!-- SEARCH (type=search + form=noform to prevent browser username autofill) -->
    <div style="display:flex;gap:10px;align-items:center;margin-bottom:14px;">
        <input type="search" id="txtSearch" class="search-input" placeholder="Search readers..." autocomplete="off" form="noform" data-lpignore="true" data-1p-ignore="true" />
        <span id="searchCount" style="font-size:12px;color:var(--muted);"></span>
    </div>

    <!-- READER TABLE -->
    <div class="panel" style="padding:0;">
        <div class="panel-title" style="padding:16px 20px 10px 20px;margin:0;">
            Configured Readers
            <span id="readerCount" style="font-weight:400;font-size:12px;"></span>
        </div>
        <div class="tbl-wrap" style="border:none;border-radius:0 0 14px 14px;">
            <table class="tbl" id="readerTable">
                <thead>
                    <tr>
                        <th style="width:30px;"></th>
                        <th>Name</th>
                        <th>Location</th>
                        <th>IP Address</th>
                        <th>Model</th>
                        <th>Status</th>
                        <th>Last Seen</th>
                        <th>Batch</th>
                        <th>Update Loc</th>
                        <th style="width:120px;">Actions</th>
                    </tr>
                </thead>
                <tbody id="readerBody"></tbody>
            </table>
        </div>
    </div>

    <!-- CONFIGURED ANTENNAS -->
    <div class="panel" style="padding:0;">
        <div class="panel-title" style="padding:16px 20px 10px 20px;margin:0;">
            Configured Antennas
            <span id="antennaCount" style="font-weight:400;font-size:12px;"></span>
        </div>
        <div class="tbl-wrap" style="border:none;border-radius:0 0 14px 14px;">
            <table class="tbl" id="antennaTable">
                <thead>
                    <tr>
                        <th>Port</th>
                        <th>Reader</th>
                        <th>Reader IP</th>
                        <th>Location</th>
                        <th>Site</th>
                    </tr>
                </thead>
                <tbody id="antennaBody"></tbody>
            </table>
        </div>
    </div>

    <!-- READER HARDWARE INTELLIGENCE -->
    <div class="panel" id="hwPanel">
        <div class="panel-title" style="padding:0;margin-bottom:14px;">
            📡 Reader Hardware Intelligence
            <div style="display:flex;gap:6px;">
                <button type="button" class="btn btn-sm btn-primary" onclick="pollAllReaders()" id="btnPollAll">🔍 Poll All Readers</button>
            </div>
        </div>
        <div style="font-size:12px;color:var(--muted);margin-bottom:14px;">
            Live hardware status from Zebra FX9600 IoT Connector REST API. Set credentials for each reader to enable polling.
        </div>
        <div id="hwCards" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:14px;">
            <div style="padding:30px;text-align:center;color:var(--muted);font-size:13px;">
                Click <strong>Poll All Readers</strong> to query hardware status from each reader.
            </div>
        </div>
    </div>

    <!-- FIRMWARE MANAGEMENT -->
    <div class="panel" id="fwPanel">
        <div class="panel-title" style="padding:0;margin-bottom:14px;">
            🔧 Firmware & Configuration Management
            <div style="display:flex;gap:6px;">
                <button type="button" class="btn btn-sm" style="background:color-mix(in srgb,var(--green),transparent 85%);color:var(--green);border:1px solid var(--green);" onclick="backupReaderConfig()">📥 Backup Config</button>
                <label class="btn btn-sm" style="background:color-mix(in srgb,var(--amber),transparent 85%);color:var(--amber);border:1px solid var(--amber);cursor:pointer;">📤 Restore Config<input type="file" id="restoreFileInput" style="display:none;" onchange="restoreReaderConfig(this)" accept=".json" /></label>
                <button type="button" class="btn btn-sm btn-primary" onclick="loadFirmwareList()">↻ Refresh</button>
            </div>
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:18px;">
            <!-- Upload -->
            <div>
                <div style="font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">Upload Firmware Package</div>
                <div style="border:2px dashed var(--line);border-radius:10px;padding:24px;text-align:center;transition:border-color .2s;" id="fwDropZone"
                     ondragover="event.preventDefault();this.style.borderColor='var(--accent)'"
                     ondragleave="this.style.borderColor='var(--line)'"
                     ondrop="event.preventDefault();this.style.borderColor='var(--line)';handleFwDrop(event)">
                    <div style="font-size:28px;margin-bottom:6px;">📦</div>
                    <div style="font-size:13px;color:var(--muted);">Drag & drop <strong>all firmware files</strong> here</div>
                    <div style="font-size:11px;color:var(--muted);margin-top:4px;">.bin, .elf, .jffs2, .txt — select entire folder contents</div>
                    <div style="margin-top:8px;">
                        <label class="btn btn-sm btn-primary" style="cursor:pointer;">
                            Browse Files
                            <input type="file" id="fwFileInput" style="display:none;" onchange="handleFwSelect(this)" multiple />
                        </label>
                    </div>
                    <div id="fwUploadStatus" style="margin-top:8px;font-size:12px;"></div>
                </div>
            </div>
            <!-- Available Firmware -->
            <div>
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                    <div style="font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;">Firmware Files on Server</div>
                    <span id="fwTotalSize" style="font-size:11px;color:var(--muted);"></span>
                </div>
                <div id="fwFileList" style="max-height:220px;overflow-y:auto;border:1px solid var(--line);border-radius:10px;padding:4px;">
                    <div style="padding:16px;text-align:center;color:var(--muted);font-size:12px;">No firmware files uploaded yet.</div>
                </div>
                <button type="button" class="btn btn-sm" style="margin-top:6px;background:color-mix(in srgb,var(--red),transparent 90%);color:var(--red);border:1px solid color-mix(in srgb,var(--red),transparent 60%);font-size:11px;" onclick="clearFirmwareFiles()">🗑 Clear All Files</button>
            </div>
        </div>
        <!-- Push to Reader -->
        <div style="margin-top:14px;padding-top:14px;border-top:1px solid var(--line);">
            <div style="font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">Push Firmware to Reader</div>
            <div style="display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap;">
                <div class="form-group" style="margin:0;min-width:250px;">
                    <label style="font-size:11px;color:var(--muted);">Target Reader</label>
                    <select id="fwTargetReader" class="ctrl-select" style="width:100%;">
                        <option value="">-- Select Reader --</option>
                    </select>
                </div>
                <div class="form-group" style="margin:0;min-width:200px;">
                    <label style="font-size:11px;color:var(--muted);">Server Address <span style="font-weight:400;opacity:.6;">(optional)</span></label>
                    <input type="text" id="fwServerHost" class="ctrl-input" style="width:100%;" placeholder="auto-detect (e.g. 192.168.4.48 or server.va.gov)" />
                </div>
                <button type="button" class="btn btn-sm" style="background:color-mix(in srgb,var(--amber),transparent 85%);color:var(--amber);border:1px solid var(--amber);white-space:nowrap;" onclick="pushFirmware()">
                    ⚡ Push Firmware Update
                </button>
            </div>
            <div style="font-size:11px;color:var(--muted);margin-top:4px;">All firmware files on the server will be served to the reader. Leave Server Address blank to auto-detect, or enter IP/hostname/FQDN the reader can reach.</div>
            <div id="fwPushStatus" style="margin-top:8px;font-size:12px;"></div>
        </div>
    </div>

    <!-- READER CREDENTIALS MODAL -->
    <div class="modal-overlay" id="credsModal">
        <div class="modal" style="max-width:420px;">
            <h2>🔑 Reader Credentials</h2>
            <input type="hidden" id="credsReaderId" />
            <div style="font-size:12px;color:var(--muted);margin-bottom:12px;" id="credsReaderName"></div>
            <div class="form-group">
                <label>Username</label>
                <input type="text" id="credsUser" placeholder="admin" />
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" id="credsPass" placeholder="Reader web console password" />
            </div>
            <div style="font-size:11px;color:var(--muted);margin-bottom:12px;">
                These credentials are used to authenticate with the reader's HTTPS web console and IoT Connector REST API.
            </div>
            <div class="actions">
                <button type="button" class="btn btn-ghost" onclick="closeCredsModal()">Cancel</button>
                <button type="button" class="btn btn-primary" onclick="saveReaderCreds()">💾 Save Credentials</button>
            </div>
        </div>
    </div>

    <!-- UNREGISTERED READERS -->
    <div class="panel" id="unregPanel" style="display:none;">
        <div class="panel-title">
            Unregistered / Discovered Readers
            <button type="button" class="btn btn-sm btn-ghost" onclick="loadUnregistered()">&#8635; Scan</button>
        </div>
        <div id="unregBody"></div>
    </div>

</div>

<!-- ═══════════════════════════════════════ -->
<!-- ADD/EDIT READER MODAL                   -->
<!-- ═══════════════════════════════════════ -->
<div class="modal-overlay" id="readerModal">
    <div class="modal">
        <h2 id="modalTitle">Add Reader</h2>
        <input type="hidden" id="editId" />

        <div class="row">
            <div class="form-group">
                <label>Reader Name *</label>
                <input type="text" id="fName" placeholder="e.g. Hallway Reader 1" />
            </div>
            <div class="form-group">
                <label>IP Address *</label>
                <input type="text" id="fIp" placeholder="e.g. 10.0.1.50" />
            </div>
        </div>

        <div class="row">
            <div class="form-group">
                <label>Reader Model</label>
                <select id="fModel">
                    <option value="Convergent Systems Limited">CSL (Convergent Systems)</option>
                    <option value="Zebra">Zebra</option>
                    <option value="Impinj">Impinj</option>
                    <option value="Other">Other</option>
                </select>
            </div>
            <div class="form-group">
                <label>Physical ID / Serial</label>
                <input type="text" id="fPhysicalId" placeholder="Hardware serial number" />
            </div>
        </div>

        <div class="row">
            <div class="form-group">
                <label>Location</label>
                <select id="fLocation"><option value="">-- Select Location --</option></select>
            </div>
            <div class="form-group">
                <label>Site</label>
                <select id="fSite"></select>
            </div>
        </div>

        <div class="form-group">
            <label>MQTT Control Topic</label>
            <input type="text" id="fMqtt" placeholder="Optional - leave blank if not using MQTT" />
        </div>

        <div class="row">
            <div class="toggle-row">
                <label class="toggle"><input type="checkbox" id="fBatch" /><span class="slider"></span></label>
                <label>Batch Mode</label>
            </div>
            <div class="toggle-row">
                <label class="toggle"><input type="checkbox" id="fUpdateLoc" checked /><span class="slider"></span></label>
                <label>Update Location on Read</label>
            </div>
        </div>

        <!-- ANTENNA CONFIG -->
        <div class="ant-section" id="antennaSection">
            <div class="panel-title">
                Antennas
                <button type="button" class="btn btn-sm btn-primary" onclick="addAntennaRow()">&#10010; Add</button>
            </div>
            <div id="antennaRows"></div>
        </div>

        <div class="actions">
            <button type="button" class="btn btn-ghost" onclick="closeModal()">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="saveReader()" id="btnSave">&#10003; Save Reader</button>
        </div>
    </div>
</div>

<idash:Footer runat="server" />
</form>

<script type="text/javascript">
    var allReaders = [];
    var allLocations = [];
    var currentAntennas = [];

    function esc(s) { if (!s) return ''; var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

    // Track whether user has intentionally typed in search
    var userTypedSearch = false;

    document.addEventListener('DOMContentLoaded', function() {
        var searchBox = document.getElementById('txtSearch');

        // Aggressively clear autofill — browsers fill AFTER DOMContentLoaded
        searchBox.value = '';
        setTimeout(function(){ if (!userTypedSearch) { searchBox.value = ''; renderTable(); } }, 100);
        setTimeout(function(){ if (!userTypedSearch) { searchBox.value = ''; renderTable(); } }, 500);
        setTimeout(function(){ if (!userTypedSearch) { searchBox.value = ''; renderTable(); } }, 1500);

        loadAll();
        document.getElementById('DdlCompany').addEventListener('change', loadAll);

        // Only treat as user input if they actually typed (not autofill)
        searchBox.addEventListener('keydown', function() { userTypedSearch = true; });
        searchBox.addEventListener('input', function() {
            if (!userTypedSearch && searchBox.value.length > 0) {
                // This is autofill, not user typing — clear it
                searchBox.value = '';
            }
            renderTable();
        });
        // Allow clearing via X button on type=search
        searchBox.addEventListener('search', function() { userTypedSearch = true; renderTable(); });

        document.getElementById('readerModal').addEventListener('click', function(e) { if (e.target === this) closeModal(); });
        document.getElementById('credsModal').addEventListener('click', function(e) { if (e.target === this) closeCredsModal(); });
    });

    function loadAll() { loadReaders(); loadAntennas(); }

    // ── LOAD READERS ──
    function loadReaders() {
        fetch('va_reader_config.aspx?api=readers&t=' + Date.now())
            .then(function(r) { return r.json(); })
            .then(function(d) {
                if (d.error) { showErr(d.error); return; }
                allReaders = d.readers || [];
                updateKpis(d);
                renderTable();
                try { populateFwReaderDropdown(); } catch(e){}
            })
            .catch(function(err) { showErr('Failed to load readers: ' + err); });
    }

    // ── LOAD ALL ANTENNAS ──
    function loadAntennas() {
        fetch('va_reader_config.aspx?api=allantennas&t=' + Date.now())
            .then(function(r) { return r.json(); })
            .then(function(d) {
                if (d.error) { showErr(d.error); return; }
                var antennas = d.antennas || [];
                document.getElementById('antennaCount').textContent = '(' + antennas.length + ')';
                renderAntennaTable(antennas);
            })
            .catch(function(err) { showErr('Failed to load antennas: ' + err); });
    }

    function renderAntennaTable(data) {
        var tbody = document.getElementById('antennaBody');
        if (!data || data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:30px;color:var(--muted);">No antennas configured. Edit a reader to add antennas.</td></tr>';
            return;
        }
        var html = '';
        data.forEach(function(a) {
            html += '<tr>' +
                '<td style="font-weight:600;">Port ' + (a.number || '?') + '</td>' +
                '<td>' + esc(a.readerName) + '</td>' +
                '<td style="font-family:monospace;font-size:12px;">' + esc(a.readerIp) + '</td>' +
                '<td>' + esc(a.locationName) + '</td>' +
                '<td>' + esc(a.siteName) + '</td>' +
                '</tr>';
        });
        tbody.innerHTML = html;
    }

    // ── KPIs ──
    function updateKpis(d) {
        var siteId = parseInt(document.getElementById('DdlCompany').value) || 0;
        var filtered = siteId > 0 ? allReaders.filter(function(r){ return r.companyID == siteId; }) : allReaders;
        var online = filtered.filter(function(r){ return r.status === 'Up'; }).length;
        var models = {};
        filtered.forEach(function(r){ if(r.readerModel) models[r.readerModel] = true; });
        document.getElementById('kTotal').textContent = filtered.length;
        document.getElementById('kOnline').textContent = online;
        document.getElementById('kOffline').textContent = filtered.length - online;
        document.getElementById('kModels').textContent = Object.keys(models).length;
    }

    // ── RENDER TABLE ──
    function renderTable() {
        var siteId = parseInt(document.getElementById('DdlCompany').value) || 0;
        var search = (document.getElementById('txtSearch').value || '').toLowerCase();
        var filtered = allReaders;
        if (siteId > 0) filtered = filtered.filter(function(r){ return r.companyID == siteId; });
        if (search) {
            filtered = filtered.filter(function(r){
                return (r.name||'').toLowerCase().indexOf(search) >= 0 ||
                       (r.locationName||'').toLowerCase().indexOf(search) >= 0 ||
                       (r.ipAddress||'').toLowerCase().indexOf(search) >= 0 ||
                       (r.readerModel||'').toLowerCase().indexOf(search) >= 0;
            });
        }

        var html = '';
        if (filtered.length === 0) {
            html = '<tr><td colspan="10"><div class="empty"><div class="empty-icon">&#128225;</div>No readers found. Click "Add Reader" to configure one.</div></td></tr>';
        } else {
            filtered.forEach(function(r){
                var isUp = r.status === 'Up';
                var lastSeen = r.lastSeen ? formatDate(r.lastSeen) : '<span style="color:var(--muted);">Never</span>';
                html += '<tr data-id="' + r.id + '">' +
                    '<td><span class="dot ' + (isUp ? 'dot-up' : 'dot-down') + '"></span></td>' +
                    '<td style="font-weight:600;">' + esc(r.name) + '</td>' +
                    '<td>' + esc(r.locationName || '') + '</td>' +
                    '<td><code style="font-size:12px;">' + esc(r.ipAddress || '') + '</code></td>' +
                    '<td>' + esc(r.readerModel || '') + '</td>' +
                    '<td><span class="badge ' + (isUp ? 'badge-up' : 'badge-down') + '">' + (isUp ? 'Online' : 'Offline') + '</span></td>' +
                    '<td style="font-size:12px;">' + lastSeen + '</td>' +
                    '<td>' + boolBadge(r.batchMode) + '</td>' +
                    '<td>' + boolBadge(r.updateLocation) + '</td>' +
                    '<td style="white-space:nowrap;">' +
                        '<button type="button" class="btn btn-sm btn-primary" onclick="editReader(' + r.id + ')" title="Edit">&#9998;</button> ' +
                        '<button type="button" class="btn btn-sm btn-danger" onclick="deleteReader(' + r.id + ',\'' + esc(r.name || '').replace(/'/g,'') + '\')" title="Delete">&#128465;</button>' +
                    '</td>' +
                '</tr>';
            });
        }
        document.getElementById('readerBody').innerHTML = html;
        document.getElementById('readerCount').textContent = filtered.length + ' reader' + (filtered.length !== 1 ? 's' : '');
        document.getElementById('searchCount').textContent = search ? filtered.length + ' match' + (filtered.length !== 1 ? 'es' : '') : '';
    }

    function boolBadge(val) {
        if (val) return '<span style="color:var(--green);font-weight:600;font-size:12px;">&#10003;</span>';
        return '<span style="color:var(--muted);font-size:12px;">&mdash;</span>';
    }

    // ── ADD READER ──
    function openAddReader() {
        document.getElementById('modalTitle').textContent = 'Add Reader';
        document.getElementById('editId').value = '';
        document.getElementById('fName').value = '';
        document.getElementById('fIp').value = '';
        document.getElementById('fModel').value = 'Convergent Systems Limited';
        document.getElementById('fPhysicalId').value = '';
        document.getElementById('fMqtt').value = '';
        document.getElementById('fBatch').checked = false;
        document.getElementById('fUpdateLoc').checked = true;
        currentAntennas = [];
        renderAntennaRows();
        loadSitesForModal(function() {
            loadLocationsForModal();
        });
        document.getElementById('readerModal').classList.add('active');
    }

    // ── EDIT READER ──
    function editReader(id) {
        var reader = allReaders.find(function(r){ return r.id == id; });
        if (!reader) { showErr('Reader not found.'); return; }

        document.getElementById('modalTitle').textContent = 'Edit Reader: ' + (reader.name || '');
        document.getElementById('editId').value = id;
        document.getElementById('fName').value = reader.name || '';
        document.getElementById('fIp').value = reader.ipAddress || '';
        document.getElementById('fModel').value = reader.readerModel || 'Convergent Systems Limited';
        document.getElementById('fPhysicalId').value = reader.physicalID || '';
        document.getElementById('fMqtt').value = reader.mqttControlTopic || '';
        document.getElementById('fBatch').checked = !!reader.batchMode;
        document.getElementById('fUpdateLoc').checked = reader.updateLocation !== false;

        loadSitesForModal(function() {
            document.getElementById('fSite').value = reader.companyID || '';
            loadLocationsForModal(function() {
                document.getElementById('fLocation').value = reader.locationID || '';
                // Load antennas after locations are populated so dropdowns are available
                fetch('va_reader_config.aspx?api=antennas&readerid=' + id + '&t=' + Date.now())
                    .then(function(r) { return r.json(); })
                    .then(function(d) {
                        currentAntennas = d.antennas || [];
                        renderAntennaRows();
                    })
                    .catch(function() {
                        currentAntennas = [];
                        renderAntennaRows();
                    });
            });
        });

        document.getElementById('readerModal').classList.add('active');
    }

    // ── LOAD LOCATIONS DROPDOWN (filtered by modal site) ──
    function loadLocationsForModal(callback) {
        var siteId = parseInt(document.getElementById('fSite').value) || 0;
        fetch('va_reader_config.aspx?api=locations&siteid=' + siteId + '&t=' + Date.now())
            .then(function(r) { return r.json(); })
            .then(function(d) {
                allLocations = d.locations || [];
                var html = '<option value="">-- Select Location --</option>';
                allLocations.forEach(function(l){ html += '<option value="' + l.id + '">' + esc(l.name) + '</option>'; });
                document.getElementById('fLocation').innerHTML = html;
                if (callback) callback();
            });
    }

    // ── LOAD SITES DROPDOWN ──
    function loadSitesForModal(callback) {
        fetch('va_reader_config.aspx?api=companies&t=' + Date.now())
            .then(function(r) { return r.json(); })
            .then(function(d) {
                var companies = d.companies || [];
                var html = '';
                companies.forEach(function(c){ html += '<option value="' + c.id + '">' + esc(c.name) + '</option>'; });
                document.getElementById('fSite').innerHTML = html;
                var sel = document.getElementById('DdlCompany');
                if (sel.value && sel.value != '0') document.getElementById('fSite').value = sel.value;
                // Reload locations and refresh antenna dropdowns when site changes
                document.getElementById('fSite').onchange = function() {
                    loadLocationsForModal(function() {
                        currentAntennas = collectAntennas();
                        renderAntennaRows();
                    });
                };
                if (callback) callback();
            });
    }

    // ── ANTENNA ROWS ──
    function renderAntennaRows() {
        var html = '';
        if (currentAntennas.length === 0) {
            html = '<div style="font-size:12px;color:var(--muted);padding:4px 0;">No antennas configured. Click "Add" to add one.</div>';
        } else {
            html += '<div class="ant-row" style="font-weight:600;font-size:11px;color:var(--muted);text-transform:uppercase;">' +
                    '<div>Port</div><div>Location</div><div>Power</div><div></div></div>';
            currentAntennas.forEach(function(a, i){
                html += '<div class="ant-row" data-idx="' + i + '">' +
                    '<input type="number" value="' + (a.portNumber || a.port || i+1) + '" class="ant-port" min="1" max="16" />' +
                    '<select class="ant-loc"><option value="">-- Location --</option>' + locationOpts(a.locationID || a.locationId || '') + '</select>' +
                    '<input type="number" value="' + (a.power || a.txPower || 30) + '" class="ant-power" min="0" max="33" />' +
                    '<span class="ant-remove" onclick="removeAntenna(' + i + ')">&#10005;</span>' +
                '</div>';
            });
        }
        document.getElementById('antennaRows').innerHTML = html;
    }

    function locationOpts(selectedId) {
        var h = '';
        allLocations.forEach(function(l){
            h += '<option value="' + l.id + '"' + (l.id == selectedId ? ' selected' : '') + '>' + esc(l.name) + '</option>';
        });
        return h;
    }

    function addAntennaRow() {
        currentAntennas.push({ portNumber: currentAntennas.length + 1, locationID: null, power: 30 });
        renderAntennaRows();
    }

    function removeAntenna(idx) {
        currentAntennas.splice(idx, 1);
        renderAntennaRows();
    }

    function collectAntennas() {
        var rows = [];
        var els = document.querySelectorAll('#antennaRows .ant-row');
        for (var i = 0; i < els.length; i++) {
            var port = els[i].querySelector('.ant-port');
            if (!port) continue;
            rows.push({
                portNumber: parseInt(port.value) || (i+1),
                locationID: parseInt(els[i].querySelector('.ant-loc').value) || null,
                power: parseInt(els[i].querySelector('.ant-power').value) || 30
            });
        }
        return rows;
    }

    // ── SAVE READER ──
    function saveReader() {
        var name = (document.getElementById('fName').value || '').trim();
        var ip = (document.getElementById('fIp').value || '').trim();
        if (!name) { alert('Reader name is required.'); return; }
        if (!ip) { alert('IP address is required.'); return; }

        var editId = document.getElementById('editId').value;
        var isNew = !editId;
        var reader = {
            name: name,
            ipAddress: ip,
            readerModel: document.getElementById('fModel').value,
            physicalID: document.getElementById('fPhysicalId').value,
            locationID: parseInt(document.getElementById('fLocation').value) || null,
            companyID: parseInt(document.getElementById('fSite').value) || 0,
            mqttControlTopic: document.getElementById('fMqtt').value,
            batchMode: document.getElementById('fBatch').checked,
            updateLocation: document.getElementById('fUpdateLoc').checked
        };

        if (!isNew) reader.id = parseInt(editId);

        var antennas = collectAntennas();
        var btn = document.getElementById('btnSave');
        btn.disabled = true;
        btn.textContent = 'Saving...';

        fetch('va_reader_config.aspx?api=save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(reader)
        })
        .then(function(r) { return r.json(); })
        .then(function(d) {
            btn.disabled = false;
            btn.innerHTML = '&#10003; Save Reader';
            if (d.error) { showErr(d.error); return; }

            // Save antennas if editing
            if (!isNew && antennas.length > 0) {
                antennas.forEach(function(a){ a.readerID = parseInt(editId); });
                fetch('va_reader_config.aspx?api=saveantennas&readerid=' + editId, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(antennas)
                }).then(function(r) { return r.json(); })
                  .then(function(d2) {
                      if (d2.error) showErr('Reader saved but antennas failed: ' + d2.error);
                      closeModal();
                      showOk('Reader and antennas updated successfully.');
                      loadReaders();
                      loadAntennas();
                  })
                  .catch(function() {
                      closeModal();
                      showOk('Reader updated successfully.');
                      loadReaders();
                      loadAntennas();
                  });
            } else {
                closeModal();
                showOk(isNew ? 'Reader created successfully.' : 'Reader updated successfully.');
                loadReaders();
                loadAntennas();
            }
        })
        .catch(function(err) {
            btn.disabled = false;
            btn.innerHTML = '&#10003; Save Reader';
            showErr('Save failed: ' + err);
        });
    }

    // ── DELETE READER ──
    function deleteReader(id, name) {
        if (!confirm('Delete reader "' + name + '"?\n\nThis cannot be undone.')) return;
        fetch('va_reader_config.aspx?api=delete&readerid=' + id + '&t=' + Date.now())
            .then(function(r) { return r.json(); })
            .then(function(d) {
                if (d.error) { showErr(d.error); return; }
                showOk('Reader "' + name + '" deleted.');
                loadReaders();
            })
            .catch(function(err) { showErr('Delete failed: ' + err); });
    }

    // ── UNREGISTERED ──
    function loadUnregistered() {
        document.getElementById('unregPanel').style.display = 'block';
        document.getElementById('unregBody').innerHTML = '<div style="padding:14px;color:var(--muted);font-size:13px;">Scanning for unregistered readers...</div>';
        var models = ['Convergent Systems Limited', 'Zebra'];
        var allUnreg = [];
        var done = 0;
        models.forEach(function(model){
            fetch('va_reader_config.aspx?api=unregistered&model=' + encodeURIComponent(model) + '&t=' + Date.now())
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    if (d.readers) allUnreg = allUnreg.concat(d.readers);
                })
                .catch(function(){})
                .then(function() {
                    done++;
                    if (done >= models.length) renderUnregistered(allUnreg);
                });
        });
    }

    function renderUnregistered(readers) {
        if (readers.length === 0) {
            document.getElementById('unregBody').innerHTML = '<div class="empty"><div class="empty-icon">&#10003;</div>No unregistered readers found.</div>';
            return;
        }
        var html = '<table class="tbl"><thead><tr><th>Name</th><th>IP</th><th>Model</th><th>Physical ID</th><th>Action</th></tr></thead><tbody>';
        readers.forEach(function(r){
            html += '<tr>' +
                '<td>' + esc(r.name || '') + '</td>' +
                '<td><code>' + esc(r.ipAddress || '') + '</code></td>' +
                '<td>' + esc(r.readerModel || '') + '</td>' +
                '<td>' + esc(r.physicalID || '') + '</td>' +
                '<td><button type="button" class="btn btn-sm btn-green" onclick="prefillRegister(\'' + escAttr(r.name||'') + '\',\'' + escAttr(r.ipAddress||'') + '\',\'' + escAttr(r.readerModel||'') + '\',\'' + escAttr(r.physicalID||'') + '\')">&#10003; Register</button></td>' +
            '</tr>';
        });
        html += '</tbody></table>';
        document.getElementById('unregBody').innerHTML = html;
    }

    function prefillRegister(name, ip, model, pid) {
        openAddReader();
        setTimeout(function(){
            document.getElementById('fName').value = name;
            document.getElementById('fIp').value = ip;
            if (model) document.getElementById('fModel').value = model;
            document.getElementById('fPhysicalId').value = pid;
        }, 50);
    }

    // ── MODAL CONTROL ──
    function closeModal() {
        document.getElementById('readerModal').classList.remove('active');
    }

    // ── HELPERS ──
    function formatDate(s) {
        if (!s) return '';
        var d = new Date(s);
        if (isNaN(d.getTime())) return s;
        var diff = Math.floor((new Date() - d) / 60000);
        if (diff < 1) return '<span style="color:var(--green);font-weight:600;">Just now</span>';
        if (diff < 60) return diff + 'm ago';
        if (diff < 1440) return Math.floor(diff/60) + 'h ago';
        return d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'});
    }

    function esc(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
    function escAttr(s) { return (s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'"); }

    function showOk(msg) {
        var el = document.getElementById('msgOk');
        document.getElementById('msgErr').style.display = 'none';
        el.textContent = msg; el.style.display = 'block';
        setTimeout(function(){ el.style.display = 'none'; }, 5000);
    }
    function showErr(msg) {
        var el = document.getElementById('msgErr');
        document.getElementById('msgOk').style.display = 'none';
        el.textContent = msg; el.style.display = 'block';
        setTimeout(function(){ el.style.display = 'none'; }, 8000);
    }

    // ═══════════════════════════════════════════════════════
    // READER HARDWARE INTELLIGENCE
    // ═══════════════════════════════════════════════════════

    var hwData = {}; // readerId -> hw status

    function pollAllReaders() {
        var readers = allReaders.filter(function(r){ return r.ipAddress; });
        if (readers.length === 0) { showErr('No readers with IP addresses found.'); return; }

        var container = document.getElementById('hwCards');
        container.innerHTML = '';
        var btn = document.getElementById('btnPollAll');
        btn.disabled = true; btn.textContent = '⏳ Polling...';

        var pending = readers.length;
        readers.forEach(function(r) {
            var card = document.createElement('div');
            card.className = 'hw-card';
            card.id = 'hwc-' + r.id;
            card.innerHTML = '<div class="hw-card-hdr"><span class="hw-card-name">' + esc(r.name) + '</span>' +
                '<code class="hw-card-ip">' + esc(r.ipAddress) + '</code></div>' +
                '<div class="hw-card-body"><div class="hw-loading">⏳ Querying reader...</div></div>';
            container.appendChild(card);

            var user  = r.readerUser || 'admin';
            var pass  = r.readerPass || '';
            var isMqtt = r.mqttControlTopic ? 1 : 0;
            fetch('va_reader_config.aspx?api=reader_hw_status&ip=' + encodeURIComponent(r.ipAddress) +
                '&user=' + encodeURIComponent(user) + '&pass=' + encodeURIComponent(pass) +
                '&mqtt=' + isMqtt + '&t=' + Date.now())
                .then(function(resp){ return resp.json(); })
                .then(function(d){
                    hwData[r.id] = d;
                    renderHwCard(r, d);
                })
                .catch(function(err){
                    renderHwCard(r, {ok:false, error: err.toString()});
                })
                .finally(function(){
                    pending--;
                    if (pending <= 0) { btn.disabled = false; btn.textContent = '🔍 Poll All Readers'; }
                });
        });
    }

    function pollSingleReader(readerId) {
        var r = allReaders.find(function(x){ return x.id == readerId; });
        if (!r || !r.ipAddress) return;
        var card = document.getElementById('hwc-' + r.id);
        if (card) {
            card.querySelector('.hw-card-body').innerHTML = '<div class="hw-loading">⏳ Querying...</div>';
        }
        var user   = r.readerUser || 'admin';
        var pass   = r.readerPass || '';
        var isMqtt = r.mqttControlTopic ? 1 : 0;
        fetch('va_reader_config.aspx?api=reader_hw_status&ip=' + encodeURIComponent(r.ipAddress) +
            '&user=' + encodeURIComponent(user) + '&pass=' + encodeURIComponent(pass) +
            '&mqtt=' + isMqtt + '&t=' + Date.now())
            .then(function(resp){ return resp.json(); })
            .then(function(d){ hwData[r.id] = d; renderHwCard(r, d); })
            .catch(function(err){ renderHwCard(r, {ok:false, error: err.toString()}); });
    }

    function renderHwCard(reader, d) {
        var card = document.getElementById('hwc-' + reader.id);
        if (!card) return;

        var body = card.querySelector('.hw-card-body');
        var hdr  = card.querySelector('.hw-card-hdr');

        // ── MQTT-mode reader (FX9600 etc.) that fell back to DB heartbeat ──
        if (d.mqttMode && d.source !== 'iot_connector') {
            var online   = d.online === true;
            var lastSeen = d.lastSeen ? new Date(d.lastSeen).toLocaleString() : 'Never';
            var reason   = d.fallbackReason || 'MQTT mode';
            hdr.style.borderLeftColor = online ? 'var(--green)' : 'var(--red)';
            body.innerHTML =
                '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px 12px;font-size:12px;">' +
                '<div style="color:var(--muted)">Mode</div><div>MQTT / LLRP</div>' +
                '<div style="color:var(--muted)">Status</div>' +
                '<div style="font-weight:700;color:' + (online ? 'var(--green)' : 'var(--red)') + '">' +
                (online ? '● Online' : '○ Offline') + '</div>' +
                '<div style="color:var(--muted)">Last Seen</div><div>' + esc(lastSeen) + '</div>' +
                '<div style="color:var(--muted)">IP</div><div style="font-family:monospace">' + esc(reader.ipAddress) + '</div>' +
                '</div>' +
                '<div style="margin-top:8px;font-size:10px;color:var(--muted);">DB heartbeat &mdash; ' + esc(reason) + '</div>' +
                '<div class="hw-actions" style="margin-top:8px;">' +
                '<button class="hw-btn" onclick="pollSingleReader(' + reader.id + ')" title="Refresh">🔄</button>' +
                '<button class="hw-btn" onclick="openCredsModal(' + reader.id + ')" title="Set Credentials">🔑</button>' +
                '<a class="hw-btn" href="https://' + esc(reader.ipAddress) + '/readerindex.html" target="_blank" title="Open Reader Console">🌐</a>' +
                '</div>';
            return;
        }

        if (!d.ok) {
            var needsCreds = (d.error || '').indexOf('401') >= 0 || !reader.hasCreds;
            body.innerHTML = '<div class="hw-error">' +
                '<div style="color:var(--red);font-weight:600;font-size:12px;margin-bottom:6px;">⚠ ' + esc(d.error || 'Connection failed') + '</div>' +
                (needsCreds ? '<button class="btn btn-sm btn-primary" onclick="openCredsModal(' + reader.id + ')" style="font-size:11px;">🔑 Set Credentials</button>' : '') +
                '</div>';
            hdr.style.borderLeftColor = 'var(--red)';
            return;
        }

        hdr.style.borderLeftColor = 'var(--green)';
        var v = d.version || {};
        var s = d.status || {};
        var uid = 'mgmt-' + reader.id;

        // ── Overview Tab Content ──
        var rows = '';
        if (v.model) rows += '<tr><td class="hw-lbl">Model</td><td class="hw-val"><strong>' + esc(v.model) + '</strong></td></tr>';
        if (v.serialNumber) rows += '<tr><td class="hw-lbl">Serial #</td><td class="hw-val"><code>' + esc(v.serialNumber) + '</code></td></tr>';

        var fwFields = [
            ['Reader App', v.readerApplication],
            ['Radio FW', v.radioFirmware],
            ['Radio Control', v.radioControlApplication],
            ['Cloud Agent', v.cloudAgentApplication]
        ];
        fwFields.forEach(function(f) {
            if (f[1]) rows += '<tr><td class="hw-lbl">' + f[0] + '</td><td class="hw-val"><code>' + esc(f[1]) + '</code></td></tr>';
        });

        if (v.revertBackFirmware && v.revertBackFirmware.readerApplication) {
            rows += '<tr><td class="hw-lbl">Revert App</td><td class="hw-val" style="color:var(--muted);"><code>' + esc(v.revertBackFirmware.readerApplication) + '</code></td></tr>';
        }

        var statusRows = '';
        if (s.uptime) statusRows += '<tr><td class="hw-lbl">Uptime</td><td class="hw-val">⏱ ' + esc(s.uptime) + '</td></tr>';
        if (s.temperature !== undefined) statusRows += '<tr><td class="hw-lbl">Temperature</td><td class="hw-val">🌡 ' + s.temperature + '°C</td></tr>';
        if (s.powerSource) statusRows += '<tr><td class="hw-lbl">Power</td><td class="hw-val">⚡ ' + esc(s.powerSource) + '</td></tr>';
        if (s.radioActivity) statusRows += '<tr><td class="hw-lbl">Radio</td><td class="hw-val">' + (s.radioActivity === 'active' ? '🟢' : '⚪') + ' ' + esc(s.radioActivity) + '</td></tr>';

        if (s.antennas) {
            var antStr = '';
            for (var port in s.antennas) {
                antStr += '<span style="margin-right:6px;" title="Port ' + port + '">' +
                    (s.antennas[port] === 'connected' ? '🟢' : '🔴') + ' P' + port + '</span>';
            }
            statusRows += '<tr><td class="hw-lbl">Antennas</td><td class="hw-val">' + antStr + '</td></tr>';
        }

        if (s.ram) {
            var usedMB = (s.ram.used / 1048576).toFixed(0);
            var totalMB = (s.ram.total / 1048576).toFixed(0);
            var pct = ((s.ram.used / s.ram.total) * 100).toFixed(0);
            statusRows += '<tr><td class="hw-lbl">Memory</td><td class="hw-val">' + usedMB + '/' + totalMB + ' MB (' + pct + '%)</td></tr>';
        }

        var overviewTab = '<table class="hw-tbl"><tbody>' + rows + statusRows + '</tbody></table>' +
            '<div class="hw-actions">' +
                '<button class="hw-btn" onclick="pollSingleReader(' + reader.id + ')" title="Refresh">🔄</button>' +
                '<button class="hw-btn" onclick="rebootReader(' + reader.id + ')" title="Reboot">🔁</button>' +
                '<button class="hw-btn" onclick="openCredsModal(' + reader.id + ')" title="Credentials">🔑</button>' +
                '<a class="hw-btn" href="https://' + esc(reader.ipAddress) + '/readerindex.html" target="_blank" title="Open Console">🌐</a>' +
            '</div>';

        // ── Control Tab Content (loaded lazily) ──
        var controlTab = '<div id="' + uid + '-ctrl-content">' +
            '<div style="text-align:center;padding:20px;color:var(--muted);font-size:12px;">Click to load reader control status...</div>' +
            '<button class="btn btn-sm btn-primary" onclick="loadReaderControl(' + reader.id + ')" style="display:block;margin:0 auto;">🎮 Load Control Panel</button>' +
            '</div>';

        // ── Network Tab Content ──
        var networkTab = '<div id="' + uid + '-net-content">' +
            '<div style="text-align:center;padding:20px;color:var(--muted);font-size:12px;">Click to load network configuration...</div>' +
            '<button class="btn btn-sm btn-primary" onclick="loadReaderNetwork(' + reader.id + ')" style="display:block;margin:0 auto;">🌐 Load Network Config</button>' +
            '</div>';

        // ── Logs Tab Content ──
        var logsTab = '<div id="' + uid + '-log-content">' +
            '<div class="log-toolbar">' +
                '<select class="log-select" id="' + uid + '-logtype">' +
                    '<option value="syslog">System Log</option>' +
                    '<option value="radioPacketLog">Radio Packet Log</option>' +
                    '<option value="RgErrorLog">RG Error Log</option>' +
                    '<option value="RgWarningLog">RG Warning Log</option>' +
                    '<option value="RcLog">RC Log</option>' +
                '</select>' +
                '<button class="qa-btn" onclick="fetchReaderLog(' + reader.id + ')">📥 Fetch</button>' +
                '<button class="qa-btn amb" onclick="purgeReaderLog(' + reader.id + ')">🗑 Purge</button>' +
                '<button class="qa-btn pur" onclick="downloadReaderLog(' + reader.id + ')">💾 Download</button>' +
            '</div>' +
            '<div class="log-viewer" id="' + uid + '-logviewer">Select a log type and click Fetch to view reader logs.</div>' +
            '</div>';

        // ── GPIO / LED Tab Content ──
        var gpioTab = '<div id="' + uid + '-gpio-content">' +
            '<div style="margin-bottom:12px;">' +
                '<div class="ctrl-label" style="margin-bottom:6px;">📥 GPI Status (Read-Only)</div>' +
                '<div class="gpio-grid" id="' + uid + '-gpi-grid">';
        if (d.gpi) {
            for (var gp in d.gpi) {
                gpioTab += '<div class="gpio-item"><div class="gpio-label">GPI ' + gp + '</div>' +
                    '<div class="gpio-val ' + (d.gpi[gp] === 'HIGH' ? 'high' : 'low') + '">' + d.gpi[gp] + '</div></div>';
            }
        } else {
            gpioTab += '<div style="grid-column:1/-1;text-align:center;padding:8px;color:var(--muted);font-size:11px;">Poll to load GPI status</div>';
        }
        gpioTab += '</div></div>' +
            '<div style="margin-bottom:12px;">' +
                '<div class="ctrl-label" style="margin-bottom:6px;">📤 GPO Control</div>' +
                '<div class="gpio-grid" id="' + uid + '-gpo-grid">';
        if (d.gpo) {
            for (var go in d.gpo) {
                gpioTab += '<div class="gpio-item"><div class="gpio-label">GPO ' + go + '</div>' +
                    '<div class="gpio-val ' + (d.gpo[go] === 'HIGH' ? 'high' : 'low') + '">' + d.gpo[go] + '</div>' +
                    '<div class="gpio-toggle"><select onchange="setGpo(' + reader.id + ',' + go + ',this.value)">' +
                    '<option value="LOW"' + (d.gpo[go] === 'LOW' ? ' selected' : '') + '>LOW</option>' +
                    '<option value="HIGH"' + (d.gpo[go] === 'HIGH' ? ' selected' : '') + '>HIGH</option>' +
                    '</select></div></div>';
            }
        } else {
            gpioTab += '<div style="grid-column:1/-1;text-align:center;padding:8px;color:var(--muted);font-size:11px;">Poll to load GPO status</div>';
        }
        gpioTab += '</div></div>' +
            '<div>' +
                '<div class="ctrl-label" style="margin-bottom:6px;">💡 Application LED</div>' +
                '<div class="led-controls">' +
                    '<div class="led-group"><label>Color</label>' +
                        '<select id="' + uid + '-led-color"><option value="green">Green</option><option value="red">Red</option>' +
                        '<option value="amber">Amber</option><option value="off">Off</option></select></div>' +
                    '<div class="led-group"><label>Duration (sec)</label>' +
                        '<input type="number" id="' + uid + '-led-dur" value="5" min="1" max="300" style="width:70px;" /></div>' +
                    '<div class="led-group"><label>Flash</label>' +
                        '<select id="' + uid + '-led-flash"><option value="true">Yes</option><option value="false">No</option></select></div>' +
                    '<button class="qa-btn grn" onclick="setReaderLed(' + reader.id + ')" style="align-self:flex-end;">💡 Set LED</button>' +
                '</div>' +
            '</div>';

        // ── Firmware Tab Content ──
        var fwTab = '<div id="' + uid + '-fw-content">' +
            '<div class="ctrl-grid" style="margin-bottom:14px;">';
        fwFields.forEach(function(f) {
            if (f[1]) fwTab += '<div class="ctrl-item"><div class="ctrl-label">' + f[0] + '</div><div class="ctrl-value"><code>' + esc(f[1]) + '</code></div></div>';
        });
        fwTab += '</div>';
        if (v.revertBackFirmware && v.revertBackFirmware.readerApplication) {
            fwTab += '<div style="padding:10px;border:1px solid var(--line);border-radius:8px;margin-bottom:10px;background:color-mix(in srgb,var(--amber),transparent 95%);">' +
                '<div style="font-size:11px;color:var(--amber);font-weight:600;margin-bottom:4px;">⏪ Rollback Available</div>' +
                '<div style="font-size:12px;color:var(--text);">Previous firmware: <code>' + esc(v.revertBackFirmware.readerApplication) + '</code></div>' +
                '<button class="qa-btn amb" onclick="revertFirmware(' + reader.id + ')" style="margin-top:6px;">⏪ Rollback to Previous Firmware</button>' +
                '</div>';
        }
        if (v.availableOsUpgrades && Object.keys(v.availableOsUpgrades).length > 0) {
            fwTab += '<div style="padding:10px;border:1px solid var(--green);border-radius:8px;background:color-mix(in srgb,var(--green),transparent 95%);">' +
                '<div style="font-size:11px;color:var(--green);font-weight:600;">🆕 Upgrades Available</div>' +
                '<pre style="font-size:11px;color:var(--text);margin:4px 0 0;">' + esc(JSON.stringify(v.availableOsUpgrades, null, 2)) + '</pre>' +
                '</div>';
        } else {
            fwTab += '<div style="font-size:11px;color:var(--muted);">✓ No pending OS upgrades.</div>';
        }
        fwTab += '</div>';

        // ── Assemble Tabbed Interface ──
        body.innerHTML = '' +
            '<div class="mgmt-tabs">' +
                '<button type="button" class="mgmt-tab active" onclick="switchMgmtTab(this,\'' + uid + '\',\'overview\')">📊 Overview</button>' +
                '<button type="button" class="mgmt-tab" onclick="switchMgmtTab(this,\'' + uid + '\',\'control\')">🎮 Control</button>' +
                '<button type="button" class="mgmt-tab" onclick="switchMgmtTab(this,\'' + uid + '\',\'network\')">🌐 Network</button>' +
                '<button type="button" class="mgmt-tab" onclick="switchMgmtTab(this,\'' + uid + '\',\'logs\')">📋 Logs</button>' +
                '<button type="button" class="mgmt-tab" onclick="switchMgmtTab(this,\'' + uid + '\',\'gpio\')">💡 GPIO/LED</button>' +
                '<button type="button" class="mgmt-tab" onclick="switchMgmtTab(this,\'' + uid + '\',\'firmware\')">🔧 Firmware</button>' +
            '</div>' +
            '<div class="mgmt-pane active" id="' + uid + '-overview">' + overviewTab + '</div>' +
            '<div class="mgmt-pane" id="' + uid + '-control">' + controlTab + '</div>' +
            '<div class="mgmt-pane" id="' + uid + '-network">' + networkTab + '</div>' +
            '<div class="mgmt-pane" id="' + uid + '-logs">' + logsTab + '</div>' +
            '<div class="mgmt-pane" id="' + uid + '-gpio">' + gpioTab + '</div>' +
            '<div class="mgmt-pane" id="' + uid + '-firmware">' + fwTab + '</div>';
    }

    // ── Tab Switching ──
    function switchMgmtTab(btn, uid, tab) {
        var tabs = btn.parentNode;
        tabs.querySelectorAll('.mgmt-tab').forEach(function(t){ t.classList.remove('active'); });
        btn.classList.add('active');
        var card = tabs.parentNode;
        card.querySelectorAll('.mgmt-pane').forEach(function(p){ p.classList.remove('active'); });
        var pane = document.getElementById(uid + '-' + tab);
        if (pane) pane.classList.add('active');
    }

    // ── Reader Creds Helper ──
    function getReaderCreds(readerId) {
        var r = allReaders.find(function(x){ return x.id == readerId; });
        if (!r) return null;
        return { ip: r.ipAddress, user: r.readerUser || 'admin', pass: r.readerPass || '', name: r.name, id: r.id };
    }
    function readerApiUrl(action, creds, extra) {
        var url = 'va_reader_config.aspx?api=' + action + '&ip=' + encodeURIComponent(creds.ip) +
            '&user=' + encodeURIComponent(creds.user) + '&pass=' + encodeURIComponent(creds.pass);
        if (extra) url += extra;
        return url;
    }

    // ══════════════════════════════════════════════════
    // READER CONTROL (Start / Stop / Mode)
    // ══════════════════════════════════════════════════
    function loadReaderControl(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var uid = 'mgmt-' + readerId;
        var el = document.getElementById(uid + '-ctrl-content');
        el.innerHTML = '<div style="text-align:center;padding:20px;color:var(--muted);font-size:12px;">⏳ Loading control panel...</div>';

        fetch(readerApiUrl('reader_mode', c))
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (!d.ok) { el.innerHTML = '<div style="color:var(--red);font-size:12px;padding:10px;">❌ ' + esc(d.error) + '</div>'; return; }
                var mode = d.data || {};
                var currentMode = mode.type || 'UNKNOWN';

                var html = '<div style="margin-bottom:14px;">' +
                    '<div class="ctrl-row" style="margin-bottom:10px;">' +
                        '<span class="mode-badge ' + (currentMode !== 'UNKNOWN' ? 'reading' : 'stopped') + '">' + esc(currentMode) + '</span>' +
                        '<button class="qa-btn grn" onclick="readerStart(' + readerId + ')">▶ Start Reading</button>' +
                        '<button class="qa-btn red" onclick="readerStop(' + readerId + ')">⏹ Stop Reading</button>' +
                        '<button class="qa-btn" onclick="loadReaderControl(' + readerId + ')">🔄 Refresh</button>' +
                    '</div></div>';

                // Operating Mode selector
                html += '<div style="margin-bottom:14px;">' +
                    '<div class="ctrl-label" style="margin-bottom:6px;">Operating Mode</div>' +
                    '<div class="ctrl-row">' +
                        '<select id="' + uid + '-mode-sel" class="log-select">' +
                            '<option' + (currentMode === 'SIMPLE' ? ' selected' : '') + '>SIMPLE</option>' +
                            '<option' + (currentMode === 'INVENTORY' ? ' selected' : '') + '>INVENTORY</option>' +
                            '<option' + (currentMode === 'PORTAL' ? ' selected' : '') + '>PORTAL</option>' +
                            '<option' + (currentMode === 'CONVEYOR' ? ' selected' : '') + '>CONVEYOR</option>' +
                            '<option' + (currentMode === 'CUSTOM' ? ' selected' : '') + '>CUSTOM</option>' +
                            '<option' + (currentMode === 'DIRECTIONALITY' ? ' selected' : '') + '>DIRECTIONALITY</option>' +
                        '</select>' +
                        '<button class="qa-btn pur" onclick="setReaderMode(' + readerId + ')">Apply Mode</button>' +
                    '</div></div>';

                // Antenna power (if mode data includes antennas)
                if (mode.antennaConfig || mode.antennas) {
                    var antennas = mode.antennaConfig || mode.antennas || [];
                    html += '<div class="ctrl-label" style="margin-bottom:6px;">Antenna Transmit Power</div>';
                    if (Array.isArray(antennas)) {
                        antennas.forEach(function(ant, i) {
                            var power = ant.transmitPowerIndex || ant.power || 300;
                            var powerDbm = (power / 10).toFixed(1);
                            html += '<div class="power-row"><label>P' + (ant.antennaId || (i+1)) + '</label>' +
                                '<input type="range" min="50" max="325" step="5" value="' + power + '" ' +
                                'oninput="this.nextElementSibling.textContent=((this.value/10).toFixed(1))+\' dBm\'" />' +
                                '<span class="power-val">' + powerDbm + ' dBm</span></div>';
                        });
                    }
                }

                // Display full mode config as expandable JSON
                html += '<details style="margin-top:10px;"><summary style="font-size:11px;color:var(--muted);cursor:pointer;">View raw mode config</summary>' +
                    '<pre style="font-size:10px;background:#0d1117;color:#c9d1d9;padding:8px;border-radius:6px;max-height:200px;overflow:auto;">' +
                    esc(JSON.stringify(mode, null, 2)) + '</pre></details>';

                el.innerHTML = html;
            })
            .catch(function(err){
                el.innerHTML = '<div style="color:var(--red);font-size:12px;padding:10px;">❌ ' + err.toString() + '</div>';
            });
    }

    function readerStart(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        fetch(readerApiUrl('reader_start', c))
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (d.ok) { showOk('▶ Reader ' + c.name + ' started reading.'); loadReaderControl(readerId); }
                else showErr(d.error || 'Start failed');
            })
            .catch(function(err){ showErr('Start failed: ' + err); });
    }

    function readerStop(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        fetch(readerApiUrl('reader_stop', c))
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (d.ok) { showOk('⏹ Reader ' + c.name + ' stopped reading.'); loadReaderControl(readerId); }
                else showErr(d.error || 'Stop failed');
            })
            .catch(function(err){ showErr('Stop failed: ' + err); });
    }

    function setReaderMode(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var uid = 'mgmt-' + readerId;
        var modeSel = document.getElementById(uid + '-mode-sel');
        var mode = modeSel ? modeSel.value : 'INVENTORY';
        if (!confirm('Change reader mode to ' + mode + '?\n\nThis will reconfigure the radio chain on ' + c.name + '.')) return;
        fetch(readerApiUrl('reader_mode_set', c), {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({type: mode})
        })
        .then(function(r){ return r.json(); })
        .then(function(d){
            if (d.ok) { showOk('Mode set to ' + mode + ' on ' + c.name); loadReaderControl(readerId); }
            else showErr(d.error || 'Mode change failed');
        })
        .catch(function(err){ showErr('Mode change failed: ' + err); });
    }

    // ══════════════════════════════════════════════════
    // NETWORK MANAGEMENT
    // ══════════════════════════════════════════════════
    function loadReaderNetwork(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var uid = 'mgmt-' + readerId;
        var el = document.getElementById(uid + '-net-content');
        el.innerHTML = '<div style="text-align:center;padding:20px;color:var(--muted);font-size:12px;">⏳ Loading network config...</div>';

        // Fetch network, hostname, NTP, timezone in parallel
        Promise.all([
            fetch(readerApiUrl('reader_network', c)).then(function(r){ return r.json(); }),
            fetch(readerApiUrl('reader_hostname', c)).then(function(r){ return r.json(); }),
            fetch(readerApiUrl('reader_ntp', c)).then(function(r){ return r.json(); }),
            fetch(readerApiUrl('reader_timezone', c)).then(function(r){ return r.json(); })
        ]).then(function(results) {
            var net = results[0].ok ? results[0].data : {};
            var host = results[1].ok ? results[1].data : {};
            var ntp = results[2].ok ? results[2].data : {};
            var tz = results[3].ok ? results[3].data : {};

            var hostname = typeof host === 'string' ? host : (host.hostname || host.hostName || '');
            var ntpServer = typeof ntp === 'string' ? ntp : (ntp.ntpServer || ntp.server || '');
            var timezone = typeof tz === 'string' ? tz : (tz.timeZone || tz.timezone || '');

            var html = '<table class="net-tbl">' +
                '<tr><td class="net-lbl">🏠 Hostname</td><td class="net-val">' + esc(hostname) + '</td></tr>' +
                '<tr><td class="net-lbl">🌐 IP Address</td><td class="net-val">' + esc(net.ipAddress || c.ip) + '</td></tr>' +
                '<tr><td class="net-lbl">🔗 Subnet Mask</td><td class="net-val">' + esc(net.subnetMask || net.subnet || '') + '</td></tr>' +
                '<tr><td class="net-lbl">🚪 Gateway</td><td class="net-val">' + esc(net.gatewayAddress || net.gateway || '') + '</td></tr>' +
                '<tr><td class="net-lbl">📡 DNS</td><td class="net-val">' + esc(net.dnsAddress || net.dns || '') + '</td></tr>' +
                '<tr><td class="net-lbl">📶 DHCP</td><td class="net-val">' + (net.dhcp ? '✅ Enabled' : '❌ Static') + '</td></tr>' +
                '<tr><td class="net-lbl">🕐 NTP Server</td><td class="net-val">' + esc(ntpServer || 'Not configured') + '</td></tr>' +
                '<tr><td class="net-lbl">🌍 Timezone</td><td class="net-val">' + esc(timezone || 'Not set') + '</td></tr>' +
                '</table>' +
                '<div style="margin-top:10px;display:flex;gap:6px;flex-wrap:wrap;">' +
                    '<button class="qa-btn" onclick="loadReaderNetwork(' + readerId + ')">🔄 Refresh</button>' +
                    '<button class="qa-btn pur" onclick="editHostname(' + readerId + ')">✏️ Edit Hostname</button>' +
                    '<button class="qa-btn pur" onclick="editNtp(' + readerId + ')">✏️ Edit NTP</button>' +
                '</div>' +
                '<details style="margin-top:10px;"><summary style="font-size:11px;color:var(--muted);cursor:pointer;">View raw network config</summary>' +
                '<pre style="font-size:10px;background:#0d1117;color:#c9d1d9;padding:8px;border-radius:6px;max-height:200px;overflow:auto;">' +
                esc(JSON.stringify({network: net, hostname: hostname, ntp: ntpServer, timezone: timezone}, null, 2)) + '</pre></details>';

            el.innerHTML = html;
        }).catch(function(err){
            el.innerHTML = '<div style="color:var(--red);font-size:12px;padding:10px;">❌ ' + err.toString() + '</div>';
        });
    }

    function editHostname(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var newName = prompt('Enter new hostname for ' + c.name + ':');
        if (!newName || !newName.trim()) return;
        fetch(readerApiUrl('reader_hostname_set', c), {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({hostname: newName.trim()})
        })
        .then(function(r){ return r.json(); })
        .then(function(d){
            if (d.ok) { showOk('Hostname updated to ' + newName.trim()); loadReaderNetwork(readerId); }
            else showErr(d.error || 'Hostname update failed');
        })
        .catch(function(err){ showErr('Failed: ' + err); });
    }

    function editNtp(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var newNtp = prompt('Enter NTP server for ' + c.name + ':', 'pool.ntp.org');
        if (!newNtp || !newNtp.trim()) return;
        fetch(readerApiUrl('reader_ntp_set', c), {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ntpServer: newNtp.trim()})
        })
        .then(function(r){ return r.json(); })
        .then(function(d){
            if (d.ok) { showOk('NTP server set to ' + newNtp.trim()); loadReaderNetwork(readerId); }
            else showErr(d.error || 'NTP update failed');
        })
        .catch(function(err){ showErr('Failed: ' + err); });
    }

    // ══════════════════════════════════════════════════
    // LOG VIEWER
    // ══════════════════════════════════════════════════
    function fetchReaderLog(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var uid = 'mgmt-' + readerId;
        var logType = document.getElementById(uid + '-logtype').value;
        var viewer = document.getElementById(uid + '-logviewer');
        viewer.textContent = '⏳ Fetching ' + logType + ' from ' + c.ip + '...';

        fetch(readerApiUrl('reader_logs', c, '&logType=' + encodeURIComponent(logType)))
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (!d.ok) { viewer.textContent = '❌ ' + (d.error || 'Failed to fetch log'); return; }
                var logData = d.data;
                if (typeof logData === 'object') logData = JSON.stringify(logData, null, 2);
                viewer.textContent = logData || '(empty log)';
                viewer.scrollTop = viewer.scrollHeight;
            })
            .catch(function(err){ viewer.textContent = '❌ ' + err.toString(); });
    }

    function purgeReaderLog(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var uid = 'mgmt-' + readerId;
        var logType = document.getElementById(uid + '-logtype').value;
        if (!confirm('Purge ' + logType + ' on ' + c.name + '? This cannot be undone.')) return;

        fetch(readerApiUrl('reader_logs_purge', c, '&logType=' + encodeURIComponent(logType)))
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (d.ok) { showOk('Log purged: ' + logType); document.getElementById(uid + '-logviewer').textContent = '(log purged)'; }
                else showErr(d.error || 'Purge failed');
            })
            .catch(function(err){ showErr('Purge failed: ' + err); });
    }

    function downloadReaderLog(readerId) {
        var uid = 'mgmt-' + readerId;
        var logType = document.getElementById(uid + '-logtype').value;
        var viewer = document.getElementById(uid + '-logviewer');
        var content = viewer.textContent;
        if (!content || content.startsWith('⏳') || content.startsWith('Select')) { alert('Fetch the log first before downloading.'); return; }
        var blob = new Blob([content], {type: 'text/plain'});
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'reader_' + readerId + '_' + logType + '_' + new Date().toISOString().slice(0,10) + '.log';
        a.click();
    }

    // ══════════════════════════════════════════════════
    // GPIO / LED CONTROL
    // ══════════════════════════════════════════════════
    function setGpo(readerId, port, value) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var body = {};
        body[String(port)] = value;
        fetch(readerApiUrl('reader_gpo_set', c), {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(body)
        })
        .then(function(r){ return r.json(); })
        .then(function(d){
            if (d.ok) showOk('GPO ' + port + ' set to ' + value + ' on ' + c.name);
            else showErr(d.error || 'GPO set failed');
        })
        .catch(function(err){ showErr('GPO set failed: ' + err); });
    }

    function setReaderLed(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var uid = 'mgmt-' + readerId;
        var color = document.getElementById(uid + '-led-color').value;
        var dur = parseInt(document.getElementById(uid + '-led-dur').value) || 5;
        var flash = document.getElementById(uid + '-led-flash').value === 'true';

        fetch(readerApiUrl('reader_led_set', c), {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({color: color, duration: dur, flash: flash})
        })
        .then(function(r){ return r.json(); })
        .then(function(d){
            if (d.ok) showOk('💡 LED set to ' + color + (flash ? ' (flashing)' : '') + ' for ' + dur + 's on ' + c.name);
            else showErr(d.error || 'LED set failed');
        })
        .catch(function(err){ showErr('LED set failed: ' + err); });
    }

    // ══════════════════════════════════════════════════
    // FIRMWARE ROLLBACK
    // ══════════════════════════════════════════════════
    function revertFirmware(readerId) {
        var c = getReaderCreds(readerId);
        if (!c) return;
        var hw = hwData[readerId];
        var revertVer = (hw && hw.version && hw.version.revertBackFirmware) ? hw.version.revertBackFirmware.readerApplication : 'unknown';
        if (!confirm('⚠️ FIRMWARE ROLLBACK ⚠️\n\n' +
            'Reader: ' + c.name + ' (' + c.ip + ')\n' +
            'Current: ' + ((hw && hw.version) ? hw.version.readerApplication : 'unknown') + '\n' +
            'Rollback to: ' + revertVer + '\n\n' +
            'The reader will reboot and run the previous firmware.\n' +
            'This operation cannot be interrupted once started.\n\n' +
            'Are you absolutely sure?')) return;

        fetch(readerApiUrl('reader_revert_fw', c))
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (d.ok) showOk('⏪ Firmware rollback initiated on ' + c.name + '. Reader will reboot shortly.');
                else showErr(d.error || 'Rollback failed');
            })
            .catch(function(err){ showErr('Rollback failed: ' + err); });
    }

    function rebootReader(readerId) {
        var r = allReaders.find(function(x){ return x.id == readerId; });
        if (!r) return;
        if (!confirm('Reboot reader "' + r.name + '" at ' + r.ipAddress + '?\n\nThe reader will be offline for ~30 seconds.')) return;
        var user = r.readerUser || 'admin';
        var pass = r.readerPass || '';
        fetch('va_reader_config.aspx?api=reader_reboot&ip=' + encodeURIComponent(r.ipAddress) +
            '&user=' + encodeURIComponent(user) + '&pass=' + encodeURIComponent(pass))
            .then(function(resp){ return resp.json(); })
            .then(function(d){
                if (d.ok) showOk(d.msg);
                else showErr(d.error || 'Reboot failed');
            })
            .catch(function(err){ showErr('Reboot failed: ' + err); });
    }

    // ── Credentials Modal ──
    function openCredsModal(readerId) {
        var r = allReaders.find(function(x){ return x.id == readerId; });
        if (!r) return;
        document.getElementById('credsReaderId').value = readerId;
        document.getElementById('credsReaderName').textContent = r.name + ' — ' + (r.ipAddress || 'No IP');
        document.getElementById('credsUser').value = r.readerUser || 'admin';
        document.getElementById('credsPass').value = r.readerPass || '';
        document.getElementById('credsModal').classList.add('active');
    }
    function closeCredsModal() { document.getElementById('credsModal').classList.remove('active'); }

    function saveReaderCreds() {
        var readerId = parseInt(document.getElementById('credsReaderId').value);
        var readerUser = document.getElementById('credsUser').value.trim();
        var readerPass = document.getElementById('credsPass').value;
        if (!readerUser) { alert('Username is required.'); return; }

        fetch('va_reader_config.aspx?api=save_reader_creds', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({readerId: readerId, readerUser: readerUser, readerPass: readerPass})
        })
        .then(function(resp){ return resp.json(); })
        .then(function(d){
            if (d.ok) {
                showOk(d.msg);
                closeCredsModal();
                // Update local data
                var r = allReaders.find(function(x){ return x.id == readerId; });
                if (r) { r.readerUser = readerUser; r.readerPass = readerPass; r.hasCreds = true; }
                // Re-poll this reader
                pollSingleReader(readerId);
            } else showErr(d.error);
        })
        .catch(function(err){ showErr('Save failed: ' + err); });
    }

    // ── Firmware Management ──
    function loadFirmwareList() {
        fetch('va_reader_config.aspx?api=firmware_list&t=' + Date.now())
            .then(function(r){ return r.json(); })
            .then(function(d){
                var files = (d.files || []).filter(function(f){
                    var n = f.name.toLowerCase();
                    return n !== 'web.config' && n !== 'index.ashx';
                });
                var el = document.getElementById('fwFileList');

                if (files.length === 0) {
                    el.innerHTML = '<div style="padding:16px;text-align:center;color:var(--muted);font-size:12px;">No firmware files on server. Upload a firmware package above.</div>';
                    document.getElementById('fwTotalSize').textContent = '';
                    return;
                }

                var totalBytes = 0;
                var html = '';
                files.forEach(function(f){
                    totalBytes += f.size;
                    var size = f.size < 1048576 ? (f.size/1024).toFixed(1) + ' KB' : (f.size/1048576).toFixed(1) + ' MB';
                    html += '<div style="display:flex;justify-content:space-between;align-items:center;padding:5px 10px;border-bottom:1px solid var(--line);font-size:12px;">' +
                        '<span style="font-weight:500;">📄 ' + esc(f.name) + '</span>' +
                        '<span style="color:var(--muted);font-size:11px;">' + size + '</span></div>';
                });
                el.innerHTML = html;
                var totalSize = totalBytes < 1048576 ? (totalBytes/1024).toFixed(0) + ' KB' : (totalBytes/1048576).toFixed(1) + ' MB';
                document.getElementById('fwTotalSize').textContent = files.length + ' files — ' + totalSize + ' total';

                // Populate reader dropdown
                populateFwReaderDropdown();
            });
    }

    function populateFwReaderDropdown() {
        var sel = document.getElementById('fwTargetReader');
        sel.innerHTML = '<option value="">-- Select Reader --</option>';
        allReaders.forEach(function(r){
            if (r.ipAddress && r.hasCreds) {
                sel.innerHTML += '<option value="' + r.id + '">' + esc(r.name) + ' (' + esc(r.ipAddress) + ')</option>';
            }
        });
    }

    // Multi-file upload support
    function handleFwDrop(e) {
        var files = e.dataTransfer.files;
        if (files.length > 0) uploadFirmwareFiles(Array.from(files));
    }
    function handleFwSelect(input) {
        if (input.files.length > 0) uploadFirmwareFiles(Array.from(input.files));
        input.value = ''; // reset so same files can be re-selected
    }

    function uploadFirmwareFiles(files) {
        var status = document.getElementById('fwUploadStatus');
        var total = files.length;
        var done = 0;
        var errors = [];
        status.innerHTML = '<span style="color:var(--amber);">⏳ Uploading ' + total + ' file(s)...</span>';

        files.forEach(function(file) {
            var formData = new FormData();
            formData.append('file', file);

            fetch('va_reader_config.aspx?api=firmware_upload', { method: 'POST', body: formData })
                .then(function(r){ return r.json(); })
                .then(function(d){
                    done++;
                    if (!d.ok) errors.push(file.name + ': ' + d.error);
                    status.innerHTML = '<span style="color:var(--amber);">⏳ Uploaded ' + done + ' / ' + total + '...</span>';
                    if (done === total) {
                        if (errors.length === 0) {
                            status.innerHTML = '<span style="color:var(--green);">✅ All ' + total + ' files uploaded successfully.</span>';
                        } else {
                            status.innerHTML = '<span style="color:var(--red);">⚠️ ' + errors.length + ' error(s): ' + esc(errors.join('; ')) + '</span>';
                        }
                        loadFirmwareList();
                    }
                })
                .catch(function(err){
                    done++;
                    errors.push(file.name + ': ' + err.toString());
                    if (done === total) {
                        status.innerHTML = '<span style="color:var(--red);">⚠️ ' + errors.length + ' error(s)</span>';
                        loadFirmwareList();
                    }
                });
        });
    }

    function clearFirmwareFiles() {
        if (!confirm('Delete all firmware files from the server?')) return;
        fetch('va_reader_config.aspx?api=firmware_clear', { method: 'POST' })
            .then(function(r){ return r.json(); })
            .then(function(d){
                if (d.ok) { showOk(d.msg); loadFirmwareList(); }
                else showErr(d.error);
            });
    }

    function pushFirmware() {
        var readerId = parseInt(document.getElementById('fwTargetReader').value);
        var r = allReaders.find(function(x){ return x.id == readerId; });
        var serverHostOverride = (document.getElementById('fwServerHost').value || '').trim();

        if (!r) { showErr('Select a target reader.'); return; }

        var hostNote = serverHostOverride ? ' via ' + serverHostOverride : ' (auto-detect server)';
        if (!confirm('Push firmware update to reader "' + r.name + '" (' + r.ipAddress + ')?' + hostNote + '\n\n' +
            'The reader will download ALL firmware files from the iDash server and install them. ' +
            'This may take several minutes and the reader will reboot automatically.\n\n' +
            'Proceed?')) return;

        var status = document.getElementById('fwPushStatus');
        status.innerHTML = '<span style="color:var(--amber);">⏳ Sending firmware update command to ' + esc(r.ipAddress) + '...</span>';

        fetch('va_reader_config.aspx?api=firmware_push', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({
                ip: r.ipAddress,
                user: r.readerUser || 'admin',
                pass: r.readerPass || '',
                fileName: 'all',
                serverHost: serverHostOverride
            })
        })
        .then(function(resp){ return resp.json(); })
        .then(function(d){
            if (d.ok) {
                status.innerHTML = '<span style="color:var(--green);">✅ ' + esc(d.msg) + '</span>';
                showOk(d.msg);
            } else {
                status.innerHTML = '<span style="color:var(--red);">❌ ' + esc(d.error) + '</span>';
                showErr(d.error);
            }
        })
        .catch(function(err){
            status.innerHTML = '<span style="color:var(--red);">❌ Push failed: ' + esc(err.toString()) + '</span>';
        });
    }

    // Auto-load firmware list on page load
    document.addEventListener('DOMContentLoaded', function() { loadFirmwareList(); });

    // ═══════════════════════════════════════════════════════
    // READER CONFIG BACKUP / RESTORE
    // ═══════════════════════════════════════════════════════

    function backupReaderConfig() {
        var readers = allReaders.filter(function(r){ return r.ipAddress && r.hasCreds; });
        if (readers.length === 0) {
            showErr('No readers with credentials found. Set credentials for a reader first.');
            return;
        }

        showOk('⏳ Backing up configuration from ' + readers.length + ' reader(s)...');

        var pending = readers.length;
        var backupData = { timestamp: new Date().toISOString(), readers: [] };

        readers.forEach(function(r) {
            fetch('va_reader_config.aspx?api=reader_backup&ip=' + encodeURIComponent(r.ipAddress) +
                '&user=' + encodeURIComponent(r.readerUser || 'admin') +
                '&pass=' + encodeURIComponent(r.readerPass || '') + '&t=' + Date.now())
                .then(function(resp){ return resp.json(); })
                .then(function(d){
                    backupData.readers.push({
                        id: r.id,
                        name: r.name,
                        ip: r.ipAddress,
                        config: d.ok ? d.config : null,
                        version: d.ok ? d.version : null,
                        error: d.ok ? null : d.error
                    });
                })
                .catch(function(err){
                    backupData.readers.push({ id: r.id, name: r.name, ip: r.ipAddress, error: err.toString() });
                })
                .finally(function(){
                    pending--;
                    if (pending <= 0) downloadBackup(backupData);
                });
        });
    }

    function downloadBackup(data) {
        var json = JSON.stringify(data, null, 2);
        var blob = new Blob([json], {type: 'application/json'});
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        var date = new Date().toISOString().split('T')[0];
        a.download = 'reader_config_backup_' + date + '.json';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        var successCount = data.readers.filter(function(r){ return !r.error; }).length;
        var failCount = data.readers.filter(function(r){ return !!r.error; }).length;
        showOk('✅ Backup downloaded! ' + successCount + ' reader(s) backed up' +
            (failCount > 0 ? ', ' + failCount + ' failed' : '') + '.');
    }

    function restoreReaderConfig(input) {
        if (!input.files || input.files.length === 0) return;
        var file = input.files[0];
        var reader = new FileReader();
        reader.onload = function(e) {
            try {
                var data = JSON.parse(e.target.result);
                if (!data.readers || !Array.isArray(data.readers)) {
                    showErr('Invalid backup file format.');
                    return;
                }

                var validReaders = data.readers.filter(function(r){ return r.config && !r.error; });
                if (validReaders.length === 0) {
                    showErr('No valid reader configurations found in backup file.');
                    return;
                }

                var msg = 'Restore configuration to ' + validReaders.length + ' reader(s)?\n\n';
                validReaders.forEach(function(r){ msg += '• ' + r.name + ' (' + r.ip + ')\n'; });
                msg += '\nThis will overwrite the current configuration. The backup was created on ' + (data.timestamp || 'unknown date') + '.';

                if (!confirm(msg)) return;

                showOk('⏳ Restoring configuration to ' + validReaders.length + ' reader(s)...');

                var pending = validReaders.length;
                var results = [];
                validReaders.forEach(function(r){
                    // Find the current reader in allReaders to get credentials
                    var currentReader = allReaders.find(function(cr){ return cr.ipAddress === r.ip; });
                    if (!currentReader || !currentReader.hasCreds) {
                        results.push({name: r.name, ok: false, error: 'No credentials configured'});
                        pending--;
                        if (pending <= 0) showRestoreResults(results);
                        return;
                    }

                    fetch('va_reader_config.aspx?api=reader_restore', {
                        method: 'POST',
                        headers: {'Content-Type':'application/json'},
                        body: JSON.stringify({
                            ip: r.ip,
                            user: currentReader.readerUser || 'admin',
                            pass: currentReader.readerPass || '',
                            config: r.config
                        })
                    })
                    .then(function(resp){ return resp.json(); })
                    .then(function(d){ results.push({name: r.name, ok: d.ok, error: d.error, msg: d.msg}); })
                    .catch(function(err){ results.push({name: r.name, ok: false, error: err.toString()}); })
                    .finally(function(){
                        pending--;
                        if (pending <= 0) showRestoreResults(results);
                    });
                });
            } catch(ex) {
                showErr('Failed to parse backup file: ' + ex.message);
            }
        };
        reader.readAsText(file);
        input.value = ''; // reset so the same file can be selected again
    }

    function showRestoreResults(results) {
        var ok = results.filter(function(r){ return r.ok; }).length;
        var fail = results.filter(function(r){ return !r.ok; }).length;
        if (fail === 0) {
            showOk('✅ Configuration restored to ' + ok + ' reader(s) successfully.');
        } else {
            showErr('⚠ Restored ' + ok + ' reader(s), ' + fail + ' failed. Check reader connectivity.');
        }
    }

</script>

<!-- ═══════════════════════════════════════════════════════════
     SERVER MIGRATION CONFIGURATION PANEL
════════════════════════════════════════════════════════════ -->
<style>
.smc-wrap{margin:28px 0 0;}
.smc-hdr{display:flex;align-items:center;gap:12px;margin-bottom:18px;}
.smc-hdr h2{font-size:16px;font-weight:700;color:var(--text);margin:0;}
.smc-badge{background:rgba(139,92,246,.18);color:#a78bfa;border:1px solid rgba(139,92,246,.3);border-radius:20px;font-size:10px;font-weight:700;letter-spacing:.6px;text-transform:uppercase;padding:3px 10px;}
.smc-tabs{display:flex;gap:4px;border-bottom:1px solid var(--border);margin-bottom:20px;}
.smc-tab{padding:8px 16px;font-size:12px;font-weight:600;color:var(--muted);cursor:pointer;border-bottom:2px solid transparent;transition:all .2s;text-transform:uppercase;letter-spacing:.5px;}
.smc-tab.active{color:var(--accent);border-bottom-color:var(--accent);}
.smc-tab:hover:not(.active){color:var(--text);}
.smc-panel{display:none;animation:fadeIn .25s ease;}
.smc-panel.active{display:block;}
.smc-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:14px;}
.smc-field{display:flex;flex-direction:column;gap:5px;}
.smc-field label{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;}
.smc-field input{background:var(--chip);border:1px solid var(--border);color:var(--text);border-radius:8px;padding:8px 10px;font-size:13px;font-family:monospace;width:100%;box-sizing:border-box;transition:border-color .15s;}
.smc-field input:focus{outline:none;border-color:var(--accent);}
.smc-field.wide{grid-column:1/-1;}
.smc-field .hint{font-size:10px;color:var(--muted);margin-top:2px;}
.smc-row-btns{display:flex;align-items:center;gap:10px;margin-top:16px;flex-wrap:wrap;}
.btn-test{background:rgba(16,185,129,.12);border:1px solid rgba(16,185,129,.3);color:#10b981;border-radius:8px;padding:7px 14px;font-size:12px;font-weight:600;cursor:pointer;transition:all .15s;}
.btn-test:hover{background:rgba(16,185,129,.22);}
.btn-save-smc{background:var(--accent);color:#fff;border:none;border-radius:8px;padding:8px 20px;font-size:13px;font-weight:600;cursor:pointer;transition:opacity .15s;}
.btn-save-smc:hover{opacity:.85;}
.smc-status{font-size:12px;padding:5px 12px;border-radius:6px;display:none;font-weight:500;}
.smc-status.ok{background:rgba(16,185,129,.12);color:#10b981;border:1px solid rgba(16,185,129,.3);}
.smc-status.err{background:rgba(239,68,68,.12);color:#f87171;border:1px solid rgba(239,68,68,.3);}
.pw-wrap{position:relative;}
.pw-wrap input{padding-right:36px;}
.pw-eye{position:absolute;right:10px;top:50%;transform:translateY(-50%);cursor:pointer;color:var(--muted);font-size:14px;user-select:none;}
.pw-eye:hover{color:var(--text);}
.smc-divider{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin:18px 0 10px;padding-bottom:6px;border-bottom:1px solid var(--border);}
@keyframes fadeIn{from{opacity:0;transform:translateY(4px);}to{opacity:1;transform:translateY(0);}}
</style>

<div class="smc-wrap" id="srvConfigWrap">
  <div class="smc-hdr">
    <h2>⚙ Server Migration Configuration</h2>
    <span class="smc-badge">Admin Only</span>
  </div>
  <p style="font-size:12px;color:var(--muted);margin:0 0 16px;">Edit all configuration files from one place. Changes write directly to <code>web.config</code> (iDash) and <code>appsettings.json</code> (AssetWorx backend). <strong>Saving restarts the app pool.</strong></p>

  <div class="smc-tabs">
    <div class="smc-tab active" onclick="smcTab(this,'tab-api')">AssetWorx API</div>
    <div class="smc-tab" onclick="smcTab(this,'tab-mqtt')">MQTT / Antenna</div>
    <div class="smc-tab" onclick="smcTab(this,'tab-smtp')">SMTP / Alerts</div>
    <div class="smc-tab" onclick="smcTab(this,'tab-backend')">Backend DB</div>
  </div>


  <!-- TAB: API / OAuth -->
  <div class="smc-panel active" id="tab-api">

    <!-- ═══ SECTION 1: iDash → AssetWorx REST API ═══════════════ -->
    <div class="oauth-section">
      <div class="oauth-section-hdr">
        <span class="oauth-icon">🔗</span>
        <div>
          <div class="oauth-section-title">iDash Web App → AssetWorx REST API</div>
          <div class="oauth-section-desc">
            <strong>Used by:</strong> iDash pages (Asset Master, Fixed Reader, Location reports, etc.)<br>
            iDash uses these client credentials to get a JWT token and call the AssetWorx REST API. If <code>AuthServerUsesJwt</code> is <strong>false</strong> in appsettings.json the API accepts calls without token validation — in that case leave Client ID/Secret as-is and just verify the API Base URL is correct.
          </div>
        </div>
      </div>
      <div class="smc-grid" style="margin-top:12px;">
        <div class="smc-field wide">
          <label>AssetWorx API Base URL</label>
          <input id="sc_ApiBase" placeholder="http://localhost" />
          <span class="hint">Root URL where the AssetWorx REST API is hosted. Use <strong>http://localhost</strong> when co-hosted on the same server.</span>
        </div>
        <div class="smc-field wide">
          <label>OAuth2 Token URL</label>
          <input id="sc_TokenUrl" placeholder="http://localhost/connect/token" />
          <span class="hint">Endpoint that issues JWT bearer tokens. Usually <code>{API Base URL}/connect/token</code>.</span>
        </div>
        <div class="smc-field">
          <label>Client ID</label>
          <input id="sc_ClientId" placeholder="e.g. fx9600_f78c85" />
          <span class="hint">The OAuth2 client registered for this iDash instance.</span>
        </div>
        <div class="smc-field">
          <label>Client Secret</label>
          <div class="pw-wrap">
            <input id="sc_ClientSecret" type="password" placeholder="••••••••" />
            <span class="pw-eye" onclick="togglePw('sc_ClientSecret',this)">👁</span>
          </div>
          <span class="hint">Secret for the Client ID above. Stored in web.config.</span>
        </div>
      </div>
      <div class="smc-row-btns" style="margin-top:10px;">
        <button class="btn-test" onclick="testOAuth()">▶ Test OAuth + API Access</button>
        <span class="smc-status" id="sc_oauthStatus"></span>
      </div>
    </div>

    <!-- ═══ SECTION 2: OIDC Authority ═══════════════════════════ -->
    <div class="oauth-section">
      <div class="oauth-section-hdr">
        <span class="oauth-icon">🔐</span>
        <div>
          <div class="oauth-section-title">AssetWorx OAuth2 / OIDC Authority</div>
          <div class="oauth-section-desc">
            <strong>Used by:</strong> AssetWorx backend (.NET Core API) — not by iDash directly.<br>
            The AssetWorx API validates every incoming JWT token against this URL's OpenID Connect discovery document. If the Auth Server URL is wrong or unreachable, the AssetWorx API will return 401 Unauthorized on all calls. Set to <strong>http://localhost</strong> when HTTPS is not configured.
          </div>
        </div>
      </div>
      <div class="smc-grid" style="margin-top:12px;">
        <div class="smc-field wide">
          <label>Auth Server URL (OIDC Issuer)</label>
          <input id="sc_AuthServerUrl" placeholder="http://localhost" />
          <span class="hint">Must serve a valid discovery document at <code>{URL}/.well-known/openid-configuration</code>. Stored in <code>appsettings.json</code>.</span>
        </div>
      </div>
      <div class="smc-row-btns" style="margin-top:10px;">
        <button class="btn-test" onclick="testOidc()">▶ Test OIDC Discovery</button>
        <span class="smc-status" id="sc_oidcStatus"></span>
      </div>
    </div>

    <!-- ═══ SECTION 3: Label Printing Service ═══════════════════ -->
    <div class="oauth-section">
      <div class="oauth-section-hdr">
        <span class="oauth-icon">🖨️</span>
        <div>
          <div class="oauth-section-title">RFID Label Printing — MQTT Credentials</div>
          <div class="oauth-section-desc">
            <strong>Used by:</strong> The RFIDPrinting service to connect to the MQTT broker and receive print jobs.<br>
            Printing works the same way as fixed readers — over MQTT. When a print job is triggered, a message is published to the MQTT broker. The RFIDPrinting service subscribes using these credentials to pick up the job. If these are wrong, the print service cannot receive jobs. Stored in <code>appsettings.json</code>.
          </div>
        </div>
      </div>
      <div class="smc-grid" style="margin-top:12px;">
        <div class="smc-field">
          <label>MQTT Username (Print Client)</label>
          <input id="sc_PrintUser" placeholder="MasterPrint" />
        </div>
        <div class="smc-field">
          <label>MQTT Password (Print Client)</label>
          <div class="pw-wrap">
            <input id="sc_PrintPass" type="password" placeholder="••••••••" />
            <span class="pw-eye" onclick="togglePw('sc_PrintPass',this)">👁</span>
          </div>
        </div>
      </div>
      <div class="smc-row-btns" style="margin-top:10px;">
        <button class="btn-test" onclick="testConn('mqtt','sc_printStatus')">▶ Test MQTT Broker (print credentials)</button>
        <span class="smc-status" id="sc_printStatus"></span>
      </div>
    </div>

    <!-- ═══ SECTION 4: iDash SQL Database ═══════════════════════ -->
    <div class="oauth-section" style="border-bottom:none;margin-bottom:0;padding-bottom:0;">
      <div class="oauth-section-hdr">
        <span class="oauth-icon">🗄️</span>
        <div>
          <div class="oauth-section-title">iDash Direct SQL Database</div>
          <div class="oauth-section-desc">
            <strong>Used by:</strong> iDash pages that query the AssetWorx SQL database directly (reports, exports, DBUpdate Workbench).<br>
            This is a direct ADO.NET connection string — separate from the REST API. If incorrect, SQL-backed pages will fail. The database <em>server</em> and credentials are also configured in <code>appsettings.json</code> for the AssetWorx API.
          </div>
        </div>
      </div>
      <div class="smc-grid" style="margin-top:12px;">
        <div class="smc-field wide">
          <label>iDash SQL Connection String</label>
          <input id="sc_ConnStr" placeholder="Data Source=SERVER\SQLEXPRESS;Database=AssetWorx;User Id=...;Password=..." />
          <span class="hint">Stored in <code>web.config</code> ConnectionStrings. Change server name here when migrating to a new SQL host.</span>
        </div>
      </div>
      <div class="smc-row-btns" style="margin-top:10px;">
        <button class="btn-test" onclick="testConn('db','sc_dbConnStatus')">▶ Test SQL Connection</button>
        <span class="smc-status" id="sc_dbConnStatus"></span>
      </div>
    </div>

  </div>

  <!-- TAB: MQTT / Antenna -->
  <div class="smc-panel" id="tab-mqtt">
    <div class="smc-divider">iDash MQTT Subscriber (web.config)</div>
    <div class="smc-grid">
      <div class="smc-field">
        <label>MQTT Broker Host</label>
        <input id="sc_MqttServer_iDash" placeholder="127.0.0.1" />
      </div>
      <div class="smc-field">
        <label>MQTT Port</label>
        <input id="sc_MqttPort_iDash" placeholder="8883" />
      </div>
      <div class="smc-field">
        <label>MQTT Username</label>
        <input id="sc_MqttUser_iDash" placeholder="idash_antenna" />
      </div>
      <div class="smc-field">
        <label>MQTT Password</label>
        <div class="pw-wrap">
          <input id="sc_MqttPass_iDash" type="password" placeholder="••••••••" />
          <span class="pw-eye" onclick="togglePw('sc_MqttPass_iDash',this)">👁</span>
        </div>
      </div>
      <div class="smc-field wide">
        <label>Tag Observation Topic</label>
        <input id="sc_MqttTopic" placeholder="awrx/7/tagobservation" />
        <span class="hint">Topic filter for incoming RFID tag reads. The site company ID is embedded (e.g. <code>awrx/7/tagobservation</code> for site 7).</span>
      </div>
      <div class="smc-field">
        <label>Tag Debounce (seconds)</label>
        <input id="sc_Debounce" placeholder="5" />
        <span class="hint">Minimum seconds between repeat tag reads counted as a new event.</span>
      </div>
      <div class="smc-field">
        <label>Reader Cache (minutes)</label>
        <input id="sc_CacheMin" placeholder="5" />
      </div>
    </div>
    <div class="smc-row-btns">
      <button class="btn-test" onclick="testConn('mqtt','sc_mqttStatus')">▶ Test MQTT Broker</button>
      <span class="smc-status" id="sc_mqttStatus"></span>
    </div>
    <div class="smc-divider">AssetWorx Backend MQTT (appsettings.json)</div>
    <div class="smc-grid">
      <div class="smc-field">
        <label>MQTT Server</label>
        <input id="sc_MqttServer_aw" placeholder="localhost" />
      </div>
      <div class="smc-field">
        <label>MQTT Port</label>
        <input id="sc_MqttPort_aw" placeholder="8883" />
      </div>
    </div>
  </div>

  <!-- TAB: SMTP / Alerts -->
  <div class="smc-panel" id="tab-smtp">
    <div class="smc-divider">Email / SMTP (web.config)</div>
    <div class="smc-grid">
      <div class="smc-field">
        <label>SMTP Host</label>
        <input id="sc_SmtpHost" placeholder="smtp.office365.com" />
      </div>
      <div class="smc-field">
        <label>SMTP Port</label>
        <input id="sc_SmtpPort" placeholder="587" />
      </div>
      <div class="smc-field">
        <label>SMTP Username</label>
        <input id="sc_SmtpUser" placeholder="you@domain.com" />
      </div>
      <div class="smc-field">
        <label>SMTP Password</label>
        <div class="pw-wrap">
          <input id="sc_SmtpPass" type="password" placeholder="••••••••" />
          <span class="pw-eye" onclick="togglePw('sc_SmtpPass',this)">👁</span>
        </div>
      </div>
      <div class="smc-field">
        <label>From Email</label>
        <input id="sc_SmtpFrom" placeholder="noreply@domain.com" />
      </div>
      <div class="smc-field">
        <label>Email Recipients</label>
        <input id="sc_EmailRecip" placeholder="user@domain.com" />
        <span class="hint">Comma-separated list for report/alert emails.</span>
      </div>
    </div>
    <div class="smc-row-btns">
      <button class="btn-test" onclick="testConn('smtp','sc_smtpStatus')">▶ Test SMTP (sends test email)</button>
      <span class="smc-status" id="sc_smtpStatus"></span>
    </div>
  </div>

  <!-- TAB: Backend DB -->
  <div class="smc-panel" id="tab-backend">
    <div class="smc-divider">AssetWorx SQL Database (appsettings.json)</div>
    <div class="smc-grid">
      <div class="smc-field">
        <label>SQL Server Hostname</label>
        <input id="sc_DbHostname" placeholder="SERVERNAME\\SQLEXPRESS" />
        <span class="hint">Server\Instance format e.g. <code>LingCod\SQLEXPRESS</code></span>
      </div>
      <div class="smc-field">
        <label>Database Name</label>
        <input id="sc_DbName" placeholder="assetworx" />
      </div>
      <div class="smc-field">
        <label>DB Username</label>
        <input id="sc_DbUsername" placeholder="assetworxadmin" />
      </div>
      <div class="smc-field">
        <label>DB Password</label>
        <div class="pw-wrap">
          <input id="sc_DbPassword" type="password" placeholder="••••••••" />
          <span class="pw-eye" onclick="togglePw('sc_DbPassword',this)">👁</span>
        </div>
      </div>
    </div>
    <div class="smc-divider">AssetWorx Print Client (appsettings.json)</div>
    <div class="smc-grid">
      <div class="smc-field">
        <label>Print Client Username</label>
        <input id="sc_PrintUser" placeholder="MasterPrint" />
      </div>
      <div class="smc-field">
        <label>Print Client Password</label>
        <div class="pw-wrap">
          <input id="sc_PrintPass" type="password" placeholder="••••••••" />
          <span class="pw-eye" onclick="togglePw('sc_PrintPass',this)">👁</span>
        </div>
      </div>
    </div>
    <div class="smc-row-btns">
      <button class="btn-test" onclick="testConn('db','sc_dbStatus')">▶ Test iDash DB Connection</button>
      <span class="smc-status" id="sc_dbStatus"></span>
    </div>
  </div>

  <!-- Save Footer -->
  <div style="display:flex;align-items:center;gap:14px;margin-top:22px;padding-top:18px;border-top:1px solid var(--border);">
    <button class="btn-save-smc" onclick="saveServerConfig()">💾 Save All Configuration</button>
    <span class="smc-status" id="sc_saveStatus" style="display:none;"></span>
    <span style="font-size:11px;color:var(--muted);">Saving will recycle the IIS app pool and reconnect MQTT.</span>
  </div>
</div>

<script>
// ── Server Migration Config ──
(function(){
    function pageUrl(api){ return location.pathname + '?api=' + api; }

    // Load all settings on page load
    fetch(pageUrl('get_server_config'))
        .then(r => r.json())
        .then(d => {
            var w = d.webconfig || {}, a = d.appsettings || {};
            setValue('sc_ApiBase',          w.ApiBase);
            setValue('sc_TokenUrl',         w.TokenUrl);
            setValue('sc_ClientId',         w.ClientId);
            setValue('sc_ClientSecret',     w.ClientSecret);
            setValue('sc_ConnStr',          w.ConnStr);
            setValue('sc_MqttServer_iDash', w.MqttServer);
            setValue('sc_MqttPort_iDash',   w.MqttPort);
            setValue('sc_MqttUser_iDash',   w.MqttUser);
            setValue('sc_MqttPass_iDash',   w.MqttPass);
            setValue('sc_MqttTopic',        w.MqttTopic);
            setValue('sc_Debounce',         w.Debounce);
            setValue('sc_CacheMin',         w.CacheMin);
            setValue('sc_SmtpHost',         w.SmtpHost);
            setValue('sc_SmtpPort',         w.SmtpPort);
            setValue('sc_SmtpUser',         w.SmtpUser);
            setValue('sc_SmtpPass',         w.SmtpPass);
            setValue('sc_SmtpFrom',         w.SmtpFrom);
            setValue('sc_EmailRecip',       w.EmailRecip);
            setValue('sc_AuthServerUrl',    a.AuthServerUrl);
            setValue('sc_MqttServer_aw',    a.MqttServer);
            setValue('sc_MqttPort_aw',      a.MqttPort);
            setValue('sc_DbHostname',       a.DbHostname);
            setValue('sc_DbName',           a.DbName);
            setValue('sc_DbUsername',       a.DbUsername);
            setValue('sc_DbPassword',       a.DbPassword);
            setValue('sc_PrintUser',        a.PrintUser);
            setValue('sc_PrintPass',        a.PrintPass);
        })
        .catch(function(e){ console.warn('Server config load error', e); });

    function setValue(id, val){
        var el = document.getElementById(id);
        if (el && val !== undefined && val !== null) el.value = val;
    }

    window.smcTab = function(tab, panelId) {
        document.querySelectorAll('.smc-tab').forEach(function(t){ t.classList.remove('active'); });
        document.querySelectorAll('.smc-panel').forEach(function(p){ p.classList.remove('active'); });
        tab.classList.add('active');
        document.getElementById(panelId).classList.add('active');
    };

    window.togglePw = function(id, eye) {
        var inp = document.getElementById(id);
        if (inp.type === 'password') { inp.type = 'text'; eye.textContent = '🙈'; }
        else { inp.type = 'password'; eye.textContent = '👁'; }
    };

    window.testConn = function(type, statusId) {
        var el = document.getElementById(statusId);
        el.className = 'smc-status'; el.textContent = 'Testing…'; el.style.display = 'inline-block';
        fetch(pageUrl('test_connection') + '&type=' + type)
            .then(r => r.json())
            .then(d => {
                el.className = 'smc-status ' + (d.ok ? 'ok' : 'err');
                el.textContent = d.msg || (d.ok ? 'OK' : 'Failed');
                el.style.display = 'inline-block';
            })
            .catch(function(e){ el.className='smc-status err'; el.textContent='Request failed: '+e; el.style.display='inline-block'; });
    };

    // Test OAuth with live form values (doesn't use saved config — tests what you just typed)
    window.testOAuth = function() {
        var el = document.getElementById('sc_oauthStatus');
        el.className = 'smc-status'; el.textContent = 'Testing OAuth…'; el.style.display = 'inline-block';
        var params = '&tokenUrl=' + encodeURIComponent(gv('sc_TokenUrl')) +
                     '&clientId=' + encodeURIComponent(gv('sc_ClientId')) +
                     '&clientSecret=' + encodeURIComponent(gv('sc_ClientSecret')) +
                     '&apiBase=' + encodeURIComponent(gv('sc_ApiBase'));
        fetch(pageUrl('test_oauth') + params)
            .then(r => r.json())
            .then(d => {
                el.className = 'smc-status ' + (d.ok ? 'ok' : 'err');
                el.textContent = d.msg || (d.ok ? 'OK' : 'Failed');
                el.style.display = 'inline-block';
            })
            .catch(function(e){ el.className='smc-status err'; el.textContent='Request failed: '+e; el.style.display='inline-block'; });
    };

    // Test OIDC discovery endpoint
    window.testOidc = function() {
        var el = document.getElementById('sc_oidcStatus');
        el.className = 'smc-status'; el.textContent = 'Testing OIDC…'; el.style.display = 'inline-block';
        var params = '&authUrl=' + encodeURIComponent(gv('sc_AuthServerUrl'));
        fetch(pageUrl('test_oidc') + params)
            .then(r => r.json())
            .then(d => {
                el.className = 'smc-status ' + (d.ok ? 'ok' : 'err');
                el.textContent = d.msg || (d.ok ? 'OK' : 'Failed');
                el.style.display = 'inline-block';
            })
            .catch(function(e){ el.className='smc-status err'; el.textContent='Request failed: '+e; el.style.display='inline-block'; });
    };

    // Test print service with live credentials
    window.testPrint = function() {
        var el = document.getElementById('sc_printStatus');
        el.className = 'smc-status'; el.textContent = 'Testing print service…'; el.style.display = 'inline-block';
        var params = '&printUser=' + encodeURIComponent(gv('sc_PrintUser')) +
                     '&printPass=' + encodeURIComponent(gv('sc_PrintPass'));
        fetch(pageUrl('test_print') + params)
            .then(r => r.json())
            .then(d => {
                el.className = 'smc-status ' + (d.ok ? 'ok' : 'err');
                el.textContent = d.msg || (d.ok ? 'OK' : 'Failed');
                el.style.display = 'inline-block';
            })
            .catch(function(e){ el.className='smc-status err'; el.textContent='Request failed: '+e; el.style.display='inline-block'; });
    };

    window.saveServerConfig = function() {
        var el = document.getElementById('sc_saveStatus');
        el.className = 'smc-status'; el.textContent = 'Saving…'; el.style.display = 'inline-block';

        var payload = {
            ApiBase:          gv('sc_ApiBase'),
            TokenUrl:         gv('sc_TokenUrl'),
            ClientId:         gv('sc_ClientId'),
            ClientSecret:     gv('sc_ClientSecret'),
            ConnStr:          gv('sc_ConnStr'),
            MqttServer_iDash: gv('sc_MqttServer_iDash'),
            MqttPort_iDash:   gv('sc_MqttPort_iDash'),
            MqttUser_iDash:   gv('sc_MqttUser_iDash'),
            MqttPass_iDash:   gv('sc_MqttPass_iDash'),
            MqttTopic:        gv('sc_MqttTopic'),
            Debounce:         gv('sc_Debounce'),
            CacheMin:         gv('sc_CacheMin'),
            SmtpHost:         gv('sc_SmtpHost'),
            SmtpPort:         gv('sc_SmtpPort'),
            SmtpUser:         gv('sc_SmtpUser'),
            SmtpPass:         gv('sc_SmtpPass'),
            SmtpFrom:         gv('sc_SmtpFrom'),
            EmailRecip:       gv('sc_EmailRecip'),
            AuthServerUrl:    gv('sc_AuthServerUrl'),
            MqttServer_aw:    gv('sc_MqttServer_aw'),
            MqttPort_aw:      gv('sc_MqttPort_aw'),
            DbHostname:       gv('sc_DbHostname'),
            DbName:           gv('sc_DbName'),
            DbUsername:       gv('sc_DbUsername'),
            DbPassword:       gv('sc_DbPassword'),
            PrintUser:        gv('sc_PrintUser'),
            PrintPass:        gv('sc_PrintPass')
        };

        fetch(pageUrl('save_server_config'), {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        })
        .then(r => r.json())
        .then(d => {
            el.className = 'smc-status ' + (d.ok ? 'ok' : 'err');
            el.textContent = d.ok ? (d.msg || 'Saved!') : (d.error || 'Error');
            el.style.display = 'inline-block';
            if (d.ok) showOk(d.msg || 'Configuration saved.');
            else showErr(d.error || 'Save failed.');
        })
        .catch(function(e){ el.className='smc-status err'; el.textContent='Request failed'; el.style.display='inline-block'; showErr('Save request failed: '+e); });
    };

    function gv(id){ var el=document.getElementById(id); return el ? el.value : ''; }
})();
</script>
</body>
</html>


