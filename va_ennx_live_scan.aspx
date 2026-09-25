<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_ennx_live_scan.aspx.cs" Inherits="va_ennx_live_scan" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <meta name="description" content="ENNX Live Scan &mdash; mobile RFID and barcode inventory live scanner with automated database commitment for Zebra handhelds and web clients." />
    <title>ENNX Live Scan &mdash; AssetWorx</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />

    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--bg); color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            font-size: 13px; min-height: 100vh;
        }

        /* SKINNY TOP STATUS BAR (MATCHING VA_INVENTORY) */
        .status-bar {
            display: flex; justify-content: space-between; align-items: center;
            background: var(--chip); padding: 5px 12px; font-size: 11px; font-weight: 600;
            border-bottom: 1px solid var(--line); position: sticky; top: 0; z-index: 100;
        }
        #connection-indicator {
            display: inline-flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 700; color: var(--accent-2, #10b981);
        }

        /* MAIN CONTAINER */
        .wrap { max-width: 1440px; margin: 6px auto; padding: 0 10px; }

        /* BUTTONS */
        .btn {
            padding: 8px 14px; border-radius: 8px; border: 1px solid var(--line);
            background: var(--chip); color: var(--text); font-size: 12px; font-weight: 700;
            cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            transition: all 0.15s ease; text-decoration: none; user-select: none;
        }
        .btn:hover { background: var(--line); transform: translateY(-1px); }
        .btn-sm { padding: 5px 10px; font-size: 11px; border-radius: 6px; }
        .btn-blue { background: var(--accent, #0284c7); color: #fff; border-color: var(--accent, #0284c7); }
        .btn-blue:hover { filter: brightness(1.1); }
        .btn-green { background: #10b981; color: #fff; border-color: #10b981; }
        .btn-green:hover { filter: brightness(1.1); }
        .btn-red { background: #ef4444; color: #fff; border-color: #ef4444; }
        .btn-red:hover { filter: brightness(1.1); }
        .btn-amber { background: #f59e0b; color: #fff; border-color: #f59e0b; }
        .btn-outline { background: transparent; border: 1px solid var(--line); color: var(--muted); }
        .status-bar .btn-outline { color: var(--muted); border-color: var(--line); background: transparent; }
        .status-bar .btn-outline:hover { background: var(--line); color: var(--text); }
        .btn:disabled { opacity: 0.45; cursor: not-allowed; transform: none; }

        /* CARDS & PANELS */
        .card {
            background: var(--card); border: 1px solid var(--line); border-radius: 12px;
            padding: 16px; margin-bottom: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }
        .card-header {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;
        }
        .card-title {
            font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--accent, #0284c7); display: flex; align-items: center; gap: 8px;
        }

        /* SITE & CONFIG BAR (MOBILE OPTIMIZED) */
        .site-bar {
            display: flex; flex-direction: column; gap: 8px;
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            padding: 10px 12px; margin-bottom: 12px;
        }
        .site-row-top {
            display: flex; align-items: center; justify-content: space-between; gap: 8px; width: 100%;
        }
        .site-field-group {
            display: flex; align-items: center; gap: 8px; flex: 1; min-width: 0;
        }
        .site-label {
            font-weight: 800; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--muted); white-space: nowrap; flex-shrink: 0;
        }
        .site-select {
            background: var(--bg); color: var(--text); border: 1.5px solid var(--line);
            padding: 6px 10px; border-radius: 8px; font-size: 13px; font-weight: 700; outline: none;
            max-width: 100%; min-width: 0; flex: 1; transition: border-color 0.15s;
        }
        .site-select:focus { border-color: var(--accent, #0284c7); }
        .site-select:disabled { opacity: 0.5; cursor: not-allowed; background: var(--chip); }
        .site-locked-pill {
            display: inline-flex; align-items: center; gap: 5px; padding: 5px 9px;
            background: rgba(99,102,241,0.12); color: #6366f1; border: 1px solid rgba(99,102,241,0.3);
            border-radius: 8px; font-size: 11px; font-weight: 700; white-space: nowrap; flex-shrink: 0;
        }

        /* EIL STREAM PANEL AT TOP OF SCAN STREAM & RECONCILIATION */
        .eil-stream-panel {
            background: var(--chip); border: 1.5px solid var(--line); border-radius: 8px;
            padding: 8px 10px; margin-bottom: 12px; display: flex; flex-direction: column; gap: 6px;
        }
        .eil-stream-top {
            display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px;
        }
        .eil-toggle-label {
            display: inline-flex; align-items: center; gap: 6px; font-size: 12px; cursor: pointer;
            font-weight: 700; white-space: nowrap; flex-shrink: 0; color: var(--text); user-select: none;
        }
        .eil-toggle-label input[type="checkbox"] {
            transform: scale(1.15); cursor: pointer; accent-color: var(--accent, #0284c7);
        }
        .eil-title-text {
            font-size: 11px; font-weight: 800; color: var(--accent, #0284c7); text-transform: uppercase; letter-spacing: 0.3px;
        }
        .eil-controls-wrap {
            display: flex; align-items: center; gap: 6px; flex-wrap: wrap; flex: 1; min-width: 240px; justify-content: flex-end;
        }
        .eil-collected-select {
            flex: 1; min-width: 170px; max-width: 260px; padding: 4px 8px; font-size: 11px; font-weight: 700; height: 30px; border-radius: 6px;
        }
        .eil-search-wrap {
            position: relative; display: inline-flex; align-items: center;
        }
        .eil-search-wrap .txt {
            width: 140px; padding: 4px 22px 4px 8px; font-size: 11px; font-weight: 700; height: 30px; border-radius: 6px; text-transform: uppercase; font-family: Consolas, monospace;
        }
        .btn-clear-eil {
            position: absolute; right: 3px; padding: 0 5px; font-size: 12px; line-height: 18px; border: none; background: transparent; color: var(--muted); cursor: pointer;
        }
        .btn-clear-eil:hover { color: var(--danger, #ef4444); }
        .eil-chips-row {
            display: flex; align-items: center; gap: 6px; flex-wrap: wrap; font-size: 11px; padding-top: 2px;
        }
        .eil-chips-label {
            font-size: 10px; font-weight: 800; color: var(--muted); text-transform: uppercase; letter-spacing: 0.3px; flex-shrink: 0;
        }
        .eil-chips-list {
            display: flex; align-items: center; gap: 5px; flex-wrap: wrap;
        }
        .eil-chip {
            display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 12px;
            font-size: 10px; font-weight: 700; font-family: Consolas, monospace;
            background: var(--card); color: var(--text); border: 1px solid var(--line);
            cursor: pointer; transition: all 0.15s; user-select: none;
        }
        .eil-chip:hover {
            border-color: var(--accent, #0284c7); color: var(--accent, #0284c7);
        }
        .eil-chip.active {
            background: #0284c7; color: #ffffff; border-color: #0284c7; box-shadow: 0 1px 4px rgba(2,132,199,0.3);
        }
        .eil-empty-hint {
            color: var(--muted); font-style: italic; font-size: 10px;
        }

        /* SCANNER CARD */
        .scan-card {
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent, #0284c7), var(--card) 92%) 0%, var(--card) 100%);
            border: 2px solid var(--accent, #0284c7); border-radius: 12px; padding: 12px 16px; margin-bottom: 12px;
            box-shadow: 0 4px 16px color-mix(in srgb, var(--accent, #0284c7), transparent 88%);
        }
        .pulse-dot { width: 9px; height: 9px; border-radius: 50%; background: #10b981; animation: pulse-anim 1.5s infinite; }
        @keyframes pulse-anim { 0% { box-shadow: 0 0 0 0 rgba(16,185,129,0.7); } 70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); } 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); } }
        
        #raw {
            width: 100%; padding: 12px 14px; font-size: 16px; font-weight: 700; font-family: "Consolas", monospace;
            background: var(--bg); color: var(--text); border: 1.5px solid var(--line); border-radius: 8px; outline: none;
        }
        #raw:focus { border-color: var(--accent, #0284c7); }
        #raw.blurred { border-color: #f97316; background: rgba(249,115,22,0.05); }
        
        .status-pill { display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: 11px; font-weight: 700; border: 1px solid; }
        .s-ready    { color: var(--muted); border-color: var(--line); }
        .s-scanning { color: #38bdf8; border-color: #38bdf8; background: rgba(56,189,248,0.12); }
        .s-paused   { color: #f97316; border-color: #f97316; background: rgba(249,115,22,0.12); }

        /* FILTER BAR & SINGLE ROW COUNTS (MATCHING VA_INVENTORY) */
        .filter-bar {
            display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;
            background: var(--card); border: 1px solid var(--line); border-radius: 8px; padding: 8px 12px; margin-bottom: 12px;
        }
        .filter-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .filter-right { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }

        /* STATUS FILTER TABS */
        .status-tabs { display: inline-flex; background: var(--chip); padding: 3px; border-radius: 8px; border: 1px solid var(--line); }
        .status-tab {
            padding: 5px 12px; font-size: 11px; font-weight: 700; border-radius: 6px; cursor: pointer;
            color: var(--muted); border: none; background: transparent; transition: all 0.15s;
        }
        .status-tab:hover { color: var(--text); }
        .status-tab.active { background: var(--card); color: var(--text); box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
        .status-tab .cnt-badge { font-size: 10px; padding: 1px 5px; border-radius: 10px; margin-left: 4px; background: var(--line); color: var(--text); }

        /* TWO-PANEL WORKSPACE */
        .workspace-grid { display: flex; gap: 14px; align-items: stretch; flex-wrap: wrap; }
        .workspace-left { flex: 1.2; min-width: 320px; display: flex; flex-direction: column; gap: 12px; }
        .workspace-right { flex: 0.95; min-width: 300px; display: flex; flex-direction: column; gap: 12px; }

        /* LIVE STREAM TABLE */
        .grid-wrap {
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            overflow-x: auto; overflow-y: auto; -webkit-overflow-scrolling: touch;
            max-height: 48vh; position: relative;
        }
        .grid { width: 100%; border-collapse: collapse; font-size: 12px; }
        .grid th {
            background: var(--chip); text-align: left; padding: 9px 10px; color: var(--muted);
            font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px;
            border-bottom: 2px solid var(--line); position: sticky; top: 0; z-index: 5;
        }
        .grid td { padding: 8px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; }
        .grid tr.row-loc { background: rgba(2,132,199,0.06); border-left: 4px solid #0284c7; }
        .grid tr.row-asset { background: rgba(16,185,129,0.04); border-left: 4px solid #10b981; }
        .grid tr.row-dupe { background: rgba(249,115,22,0.06); border-left: 4px solid #f97316; }
        .grid tr.row-ignored { background: rgba(236,72,153,0.05); border-left: 4px solid #ec4899; }
        
        .badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 999px; font-size: 10px; font-weight: 700; }
        .b-loc { background: rgba(2,132,199,0.15); color: #0284c7; border: 1px solid rgba(2,132,199,0.3); }
        .b-asset { background: rgba(16,185,129,0.15); color: #10b981; border: 1px solid rgba(16,185,129,0.3); }
        .b-dupe { background: rgba(249,115,22,0.15); color: #f97316; border: 1px solid rgba(249,115,22,0.3); }
        .b-unk { background: rgba(236,72,153,0.15); color: #ec4899; border: 1px solid rgba(236,72,153,0.3); }

        /* PREVIEW TEXTAREA */
        .preview-box {
            width: 100%; height: 100%; min-height: 420px; resize: vertical;
            padding: 12px 14px; font-family: "Consolas", monospace; font-size: 13px; font-weight: 600;
            background: var(--bg); color: var(--text); border: 1px solid var(--line); border-radius: 8px;
            outline: none; line-height: 1.5;
        }

        /* MANUAL INPUT & CONTROLS */
        .stream-ctrl-row {
            display: flex; justify-content: flex-start; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 12px;
        }
        .stream-chk-wrap {
            display: flex; align-items: center; gap: 14px; flex-wrap: wrap;
        }
        .manual-input-wrap {
            display: flex; align-items: center; gap: 6px; justify-content: flex-start;
        }
        .txt {
            background: var(--bg); border: 1.5px solid var(--line); color: var(--text);
            padding: 7px 12px; border-radius: 8px; font-size: 13px; font-weight: 600; outline: none; transition: border-color 0.15s;
        }
        .txt:focus { border-color: var(--accent, #0284c7); }
        .manual-input-wrap .txt {
            width: 240px; max-width: 100%; border-radius: 8px;
        }
        .manual-input-wrap .btn {
            border-radius: 8px; padding: 7px 14px; font-size: 12px;
        }

        /* SERVER MESSAGES */
        .msg-ok { background: rgba(16,185,129,0.1); border: 1px solid #10b981; border-left: 4px solid #10b981; color: #10b981; padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-weight: 700; }
        .msg-err { background: rgba(239,68,68,0.1); border: 1px solid #ef4444; border-left: 4px solid #ef4444; color: #ef4444; padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-weight: 700; }

        /* LIGHT MODE HIGH-CONTRAST OVERRIDES */
        [data-theme="light"] .status-bar {
            background: #ffffff;
            border-bottom: 1px solid #cbd5e1;
            color: #0f172a;
        }
        [data-theme="light"] .status-bar .btn-outline {
            color: #1e293b;
            border-color: #cbd5e1;
            background: #f8fafc;
            font-weight: 700;
        }
        [data-theme="light"] .status-bar .btn-outline:hover {
            background: #e2e8f0;
        }

        [data-theme="light"] .grid th { background: #f1f5f9; color: #334155; border-bottom: 2px solid #cbd5e1; }
        [data-theme="light"] .grid td { color: #0f172a; border-bottom: 1px solid #e2e8f0; }
        [data-theme="light"] .grid tr.row-loc { background: #f0f9ff; border-left-color: #0284c7; }
        [data-theme="light"] .grid tr.row-loc td { color: #0369a1; font-weight: 700; }
        [data-theme="light"] .grid tr.row-asset { background: #ecfdf5; border-left-color: #059669; }
        [data-theme="light"] .grid tr.row-asset td { color: #065f46; font-weight: 600; }
        [data-theme="light"] .grid tr.row-dupe { background: #fff7ed; border-left-color: #ea580c; }
        [data-theme="light"] .grid tr.row-dupe td { color: #9a3412; font-weight: 600; }
        [data-theme="light"] .grid tr.row-ignored { background: #fdf2f8; border-left-color: #db2777; }
        [data-theme="light"] .grid tr.row-ignored td { color: #9d174d; font-weight: 600; }

        [data-theme="light"] .b-loc { background: #0284c7; color: #ffffff; border-color: #0284c7; }
        [data-theme="light"] .b-asset { background: #059669; color: #ffffff; border-color: #059669; }
        [data-theme="light"] .b-dupe { background: #ea580c; color: #ffffff; border-color: #ea580c; }
        [data-theme="light"] .b-unk { background: #db2777; color: #ffffff; border-color: #db2777; }

        [data-theme="light"] .preview-box { background: #f8fafc; color: #0f172a; border-color: #cbd5e1; }
        [data-theme="light"] #raw { background: #ffffff; color: #0f172a; border-color: #cbd5e1; }
        [data-theme="light"] .scan-card { background: #f8fafc; border-color: #0284c7; }
        [data-theme="light"] .site-bar { background: #ffffff; border-color: #cbd5e1; }
        [data-theme="light"] .filter-bar { background: #ffffff; border-color: #cbd5e1; }
        [data-theme="light"] .status-tabs { background: #e2e8f0; border: 1px solid #cbd5e1; }
        [data-theme="light"] .status-tab { color: #334155; font-weight: 800; }
        [data-theme="light"] .status-tab:hover { color: #0f172a; }
        [data-theme="light"] .status-tab.active { background: #ffffff; color: #0f172a; font-weight: 900; box-shadow: 0 1px 4px rgba(0,0,0,0.12); }
        [data-theme="light"] .status-tab .cnt-badge { background: #cbd5e1; color: #0f172a; font-weight: 800; }
        [data-theme="light"] .status-tab.active .cnt-badge { background: #e2e8f0; color: #0f172a; }
        [data-theme="light"] .txt, [data-theme="light"] .site-select {
            background: #ffffff;
            border-color: #cbd5e1;
            color: #0f172a;
            font-weight: 600;
        }

        /* MODAL STYLES */
        .modal-overlay {
            display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7);
            backdrop-filter: blur(3px); z-index: 999; justify-content: center; align-items: center;
        }
        .modal-card {
            background: var(--card); border: 1px solid var(--line); border-radius: 12px;
            padding: 24px; max-width: 420px; width: 90%; box-shadow: 0 10px 30px rgba(0,0,0,0.5);
        }

        /* RESPONSIVE DESIGN (LARGE MONITORS vs MOBILE) */
        @media (min-width: 1200px) {
            .wrap { max-width: 96vw; width: 96%; margin: 10px auto; padding: 0 16px; }
            .grid-wrap { max-height: calc(100vh - 380px); min-height: 480px; }
            .preview-box { min-height: 520px; }
            .status-bar { padding: 6px 18px; font-size: 12px; }
            .status-bar .btn-sm { padding: 4px 10px; font-size: 11px; }
        }

        @media (max-width: 768px) {
            .wrap { margin: 4px auto; padding: 0 6px; }
            .workspace-grid { flex-direction: column; }
            .preview-box { min-height: 260px; }
            .grid-wrap { max-height: 42vh; }
        }

        @media (max-width: 680px) {
            .status-bar { padding: 5px 8px; gap: 6px; flex-wrap: nowrap; }
            .app-title { max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11px !important; }
            #connection-indicator { display: none; }
            .status-bar-actions { gap: 3px !important; flex-shrink: 0; }
            .status-bar-actions .btn-sm { padding: 3px 6px !important; font-size: 11px !important; }
            .btn-lbl { display: none; }
            .filter-bar { padding: 6px 8px; }
            .status-tabs { overflow-x: auto; -webkit-overflow-scrolling: touch; max-width: 100%; white-space: nowrap; padding: 2px; }
            .status-tab { padding: 5px 8px; font-size: 11px; flex-shrink: 0; }
            .stream-ctrl-row { flex-direction: column; align-items: stretch; gap: 10px; }
            .manual-input-wrap { width: 100%; justify-content: flex-start; }
            .manual-input-wrap .txt { flex: 1; width: auto; max-width: none; border-radius: 8px; }
            .manual-input-wrap .btn { border-radius: 8px; flex-shrink: 0; }
        }
    </style>
</head>
<body onload="initApp();">
<form id="form1" runat="server">

    <!-- RESPONSIVE TOP STATUS BAR (MATCHING VA_INVENTORY) -->
    <div class="status-bar">
        <div style="display:flex; align-items:center; gap:8px; min-width:0;">
            <span class="app-title" style="font-weight:800; font-size:12px; letter-spacing:0.3px; white-space:nowrap;">iDash ENNX Live Scan</span>
            <span id="connection-indicator">&bull; CONNECTED</span>
        </div>
        <div class="status-bar-actions" style="display:flex; align-items:center; gap:6px; flex-shrink:0;">
            <button type="button" class="btn btn-sm btn-outline" id="btnUser" onclick="openLoginModal();" title="Operator Sign-In"><span id="userBadge">&#128100; Operator</span></button>
            <button type="button" class="btn btn-sm btn-outline" id="btnToggleTheme" style="padding:3px 8px; font-size:10px;" onmousedown="event.preventDefault();" onclick="toggleTheme();" title="Toggle Light/Dark Mode">&#9681; <span class="btn-lbl">Theme</span></button>
            <a href="documentation/va_ennx_live_scan.html" target="_blank" class="btn btn-sm btn-outline" id="btnDocs" style="padding:3px 8px; font-size:10px;" title="ENNX Documentation &amp; Navigation Guide">&#128214; <span class="btn-lbl">Docs</span></a>
            <a href="index.aspx" class="btn btn-sm btn-outline" id="btnHub" style="padding:3px 8px; font-size:10px;" title="Back to Hub">&#8962; <span class="btn-lbl">Hub</span></a>
        </div>
    </div>

    <div class="wrap">
        <asp:Literal ID="LitMsg" runat="server" />

        <!-- SITE & FILTER BAR (MOBILE OPTIMIZED) -->
        <div class="site-bar">
            <!-- ROW 1: DEFAULT SITE & STATION SIDE-BY-SIDE -->
            <div class="site-row-top">
                <div class="site-field-group">
                    <span class="site-label">Default Site:</span>
                    <asp:DropDownList ID="DdlCompany" runat="server" CssClass="site-select" onchange="onSiteChanged(this.value)">
                    </asp:DropDownList>
                </div>
                <span class="site-locked-pill" id="siteLockedBadge">&#128274; Station: <strong id="tStation">517</strong></span>
            </div>
        </div>

        <!-- 1. HIGH-SPEED SCANNER CARD -->
        <div class="scan-card">
            <div class="card-header" style="margin-bottom:8px;">
                <div class="card-title">
                    <div class="pulse-dot" id="pulseDot"></div>
                    <span>Mobile RFID &amp; Barcode Scanner</span>
                    <span class="status-pill s-ready" id="statusPill">&#9711; READY</span>
                </div>
                <div style="display:flex; gap:6px;">
                    <button type="button" class="btn btn-sm btn-blue" id="btnForceLoc" onclick="forceNextLocation();">&#128205; Change Location</button>
                    <button type="button" class="btn btn-sm" onclick="focusScan();">&#8635; Focus Trigger</button>
                </div>
            </div>
            <input id="raw" type="text" autocomplete="off" autocorrect="off"
                   spellcheck="false" autocapitalize="off"
                   placeholder="Scan location barcode (SP...) or pull trigger for asset tags..." />
        </div>

        <!-- 2. REVIEW, FILTERS & COUNTS TOOLBAR (SINGLE ROW MATCHING VA_INVENTORY) -->
        <div class="filter-bar">
            <div class="filter-left">
                <!-- STATUS TABS -->
                <div class="status-tabs" id="statusTabs">
                    <button type="button" class="status-tab active" data-status="All" onclick="filterStream('All');">
                        All <span class="cnt-badge" id="badgeAll">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Location" onclick="filterStream('Location');">
                        Locations <span class="cnt-badge" id="badgeLoc" style="color:#0284c7;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Asset" onclick="filterStream('Asset');">
                        Assets <span class="cnt-badge" id="badgeAssets" style="color:#10b981;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Duplicate" onclick="filterStream('Duplicate');">
                        Duplicates <span class="cnt-badge" id="badgeDupes" style="color:#f97316;">0</span>
                    </button>
                </div>
                <span style="font-size:11px; font-weight:700; color:var(--muted); margin-left:4px; display:inline-flex; align-items:center; gap:4px;">
                    Total Scans: <strong style="color:var(--accent, #0284c7);" id="kReads">0</strong>
                </span>
                <span style="font-size:11px; font-weight:700; color:var(--muted); margin-left:8px; display:inline-flex; align-items:center; gap:4px;">
                    Active Loc: <strong style="color:var(--text); font-family:Consolas,monospace; font-size:12px;" id="tLoc">(none)</strong>
                    <button type="button" class="btn btn-sm btn-outline" id="btnChangeLoc" onclick="forceNextLocation();" style="padding:2px 8px; font-size:11px; margin-left:4px;" title="Click to scan or enter a new room location">&#128205; Change Room</button>
                </span>
            </div>
            <div class="filter-right">
                <button type="button" class="btn btn-sm btn-outline" onclick="undoLast();" title="Undo last scan">&#8617; Undo</button>
                <button type="button" class="btn btn-sm btn-red" onclick="clearAll();" title="Clear all session scans">&#128465; Clear All</button>
            </div>
        </div>

        <!-- 3. MAIN WORKSPACE: STREAM TABLE vs LIVE PREVIEW -->
        <div class="workspace-grid">
            
            <!-- LEFT PANEL: SCAN STREAM & CONTROLS -->
            <div class="workspace-left">
                <div class="card" style="margin-bottom:0; flex:1; display:flex; flex-direction:column;">
                    <div class="card-header">
                        <div class="card-title">&#128225; Scan Stream &amp; Reconciliation</div>
                    </div>

                    <!-- EIL FILTER BAR (MOVED TO TOP OF SCAN STREAM & RECONCILIATION) -->
                    <div class="eil-stream-panel" id="eilStreamPanel">
                        <div class="eil-stream-top">
                            <label class="eil-toggle-label" for="chkScanByEil" title="Toggle EIL filtering for scanning and reconciliation">
                                <input id="chkScanByEil" type="checkbox" onchange="onEilToggle();" />
                                <span class="eil-title-text">&#128203; Filter by EIL:</span>
                            </label>

                            <!-- Dual-Mode Box: Choose from Collected EILs + Instant Search/Type Input -->
                            <div class="eil-controls-wrap">
                                <!-- 1. Box / Dropdown to choose from EILs collected with scan -->
                                <select id="ddlCollectedEil" class="site-select eil-collected-select" onchange="onCollectedEilSelected(this.value);" title="Choose from EILs detected among your scanned items">
                                    <option value="All">All Scanned EILs (All Items)</option>
                                </select>

                                <!-- 2. Search box with autocomplete for all 4,300+ station EILs -->
                                <div class="eil-search-wrap">
                                    <input type="text" id="txtEilSearch" class="txt" list="eilStationDataList" placeholder="Search / Type EIL..." autocomplete="off" oninput="onEilSearchInput(this.value);" title="Search or type any station EIL" />
                                    <button type="button" id="btnClearEil" class="btn btn-sm btn-outline btn-clear-eil" onclick="clearEilFilter();" title="Clear EIL filter" style="display:none;">&times;</button>
                                </div>
                                <datalist id="eilStationDataList"></datalist>

                                <!-- Hidden original server dropdown so ASP.NET doesn't complain -->
                                <asp:DropDownList ID="DdlEIL" runat="server" style="display:none;"></asp:DropDownList>
                            </div>
                        </div>

                        <!-- 3. Quick-Pick Chips of Collected EILs -->
                        <div class="eil-chips-row" id="eilChipsRow">
                            <span class="eil-chips-label">Detected EILs:</span>
                            <div class="eil-chips-list" id="eilChipsList">
                                <span class="eil-empty-hint">(Scan assets to detect EILs)</span>
                            </div>
                        </div>
                    </div>

                    <!-- OPTIONS & MANUAL INPUT ROW (ROUNDED CORNERS & LEFT JUSTIFIED) -->
                    <div class="stream-ctrl-row">
                        <div class="stream-chk-wrap">
                            <label style="display:flex; align-items:center; gap:6px; font-size:11px; font-weight:700; cursor:pointer;">
                                <input id="chkDedup" type="checkbox" checked="checked" /> De-duplicate Assets
                            </label>
                            <label style="display:flex; align-items:center; gap:6px; font-size:11px; font-weight:700; cursor:pointer;" title="When checked, scanning a verified barcode location automatically switches room without clicking Change Location.">
                                <input id="chkAutoLoc" type="checkbox" /> Auto-Switch Loc (Barcode)
                            </label>
                            <label style="display:flex; align-items:center; gap:6px; font-size:11px; font-weight:700; cursor:pointer;" title="Only allow RFID signals to set location if explicitly checked.">
                                <input id="chkAllowRfidLoc" type="checkbox" /> Allow RFID Loc
                            </label>
                        </div>
                        <div class="manual-input-wrap">
                            <input type="text" id="manualInput" class="txt" placeholder="Manual tag or room..." />
                            <button type="button" class="btn btn-sm btn-green" onclick="submitManual();">+ Add</button>
                        </div>
                    </div>

                    <!-- STREAM GRID -->
                    <div class="grid-wrap">
                        <table class="grid" id="tblStream">
                            <thead>
                                <tr>
                                    <th style="width:70px;">Time</th>
                                    <th style="width:90px;">Type</th>
                                    <th>Tag / Barcode</th>
                                    <th style="width:130px;">Location</th>
                                    <th style="width:60px; text-align:center;">Action</th>
                                </tr>
                            </thead>
                            <tbody id="bodyStream">
                                <tr>
                                    <td colspan="5" style="text-align:center; padding:32px 14px; color:var(--muted);">
                                        Scan a location barcode (starts with <strong>SP</strong>) or pull RFID trigger to begin session.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- RIGHT PANEL: LIVE ENNX PREVIEW & EXPORT / COMMIT -->
            <div class="workspace-right">
                <div class="card" style="margin-bottom:0; flex:1; display:flex; flex-direction:column;">
                    <div class="card-header">
                        <div class="card-title">&#128196; Live ENNX File Output</div>
                        <div style="display:flex; gap:6px;">
                            <button type="button" class="btn btn-sm btn-outline" onclick="copyEnnx();">&#128203; Copy</button>
                        </div>
                    </div>

                    <textarea id="ennxPreview" class="preview-box" readonly="readonly"></textarea>

                    <!-- HIDDEN POSTBACK FIELDS -->
                    <asp:HiddenField ID="HidJson" runat="server" />
                    <asp:HiddenField ID="HidEnnx" runat="server" />
                    <asp:HiddenField ID="HidStation" runat="server" />
                    <asp:HiddenField ID="HidSummary" runat="server" />
                    <asp:HiddenField ID="HidStartedUtc" runat="server" />
                    <asp:HiddenField ID="HidEndedUtc" runat="server" />
                    <asp:HiddenField ID="HidUser" runat="server" />

                    <!-- PRIMARY COMMIT & EMAIL ACTION BUTTONS -->
                    <div style="margin-top:12px; display:flex; flex-direction:column; gap:8px;">
                        <asp:Button ID="BtnCommitScans" runat="server" CssClass="btn btn-green" style="width:100%; padding:11px; font-size:13px; font-weight:800;"
                            Text="&#128190; Commit Scans to Database" OnClick="BtnCommitScans_Click"
                            OnClientClick="return preparePost('commit');" />

                        <asp:Button ID="BtnEmail" runat="server" CssClass="btn btn-blue" style="width:100%; padding:9px; font-size:12px; font-weight:700;"
                            Text="&#9993; Email ENNX File" OnClick="BtnEmail_Click"
                            OnClientClick="return preparePost('email');" />
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- TECHNICIAN SIGN-IN MODAL (MATCHING VA_INVENTORY) -->
    <div class="modal-overlay" id="loginModal">
        <div class="modal-card">
            <h3 style="margin-bottom:6px; font-size:16px;">&#128100; Technician Sign-In</h3>
            <p style="color:var(--muted); font-size:12px; margin-bottom:16px;">Sign in to assign your technician name to committed inventory scans.</p>
            <div id="loginError" style="display:none; padding:8px 12px; background:rgba(239,68,68,0.12); color:#ef4444; border-radius:6px; font-size:12px; margin-bottom:12px; font-weight:600;"></div>
            <div style="display:flex; flex-direction:column; gap:12px; margin-bottom:16px;">
                <div>
                    <label class="lbl" style="display:block; margin-bottom:4px; font-size:11px; font-weight:700; color:var(--muted); text-transform:uppercase;">Username</label>
                    <input type="text" id="txtLoginUser" class="txt" style="width:100%;" placeholder="e.g. gary or assetworxadmin" autocomplete="username" />
                </div>
                <div>
                    <label class="lbl" style="display:block; margin-bottom:4px; font-size:11px; font-weight:700; color:var(--muted); text-transform:uppercase;">Password</label>
                    <input type="password" id="txtLoginPass" class="txt" style="width:100%;" placeholder="Enter password" autocomplete="current-password" />
                </div>
            </div>
            <div style="display:flex; justify-content:flex-end; gap:8px;">
                <button type="button" class="btn btn-outline" onclick="closeLoginModal();">Cancel</button>
                <button type="button" class="btn btn-blue" id="btnLoginSubmit" onclick="submitLogin();">Sign In</button>
            </div>
        </div>
    </div>

</form>

<script>
    // --- SESSION STATE & CONSTANTS ---
    const STORAGE_KEY = 'idash_ennx_live_v2';
    let blocks = []; // [{ location: '...', assets: ['...'], assetSet: {} }]
    let logEntries = []; // [{ id, time, type: 'Location'|'Asset'|'Duplicate'|'Ignored', tag, location, note }]
    let currentLocation = '';
    let forceLoc = false;
    let totalLocations = 0;
    let totalAssets = 0;
    let dupes = 0;
    let totalScans = 0;
    let startedUtc = new Date().toISOString();
    let currentFilter = 'All';
    let activeStation = '517';
    let _selectedEil = 'All';
    let _assetEilCache = {}; // { tag: eil }
    let _collectedEils = {}; // { eil: count }
    let _stationEilList = []; // [eil1, eil2, ...]

    // Elements
    const scanBox = document.getElementById('raw');
    const statusPill = document.getElementById('statusPill');
    const pulseDot = document.getElementById('pulseDot');
    const ennxPreview = document.getElementById('ennxPreview');
    const tLoc = document.getElementById('tLoc');
    const kReads = document.getElementById('kReads');
    const badgeAll = document.getElementById('badgeAll');
    const badgeLoc = document.getElementById('badgeLoc');
    const badgeAssets = document.getElementById('badgeAssets');
    const badgeDupes = document.getElementById('badgeDupes');
    const bodyStream = document.getElementById('bodyStream');
    const chkDedup = document.getElementById('chkDedup');
    const chkAutoLoc = document.getElementById('chkAutoLoc');
    const chkAllowRfidLoc = document.getElementById('chkAllowRfidLoc');
    const manualInput = document.getElementById('manualInput');
    const ddlCompany = document.getElementById('<%= DdlCompany.ClientID %>');
    const ddlEIL = document.getElementById('<%= DdlEIL.ClientID %>');
    const chkScanByEil = document.getElementById('chkScanByEil');
    const ddlCollectedEil = document.getElementById('ddlCollectedEil');
    const txtEilSearch = document.getElementById('txtEilSearch');
    const btnClearEil = document.getElementById('btnClearEil');
    const eilStationDataList = document.getElementById('eilStationDataList');
    const eilChipsList = document.getElementById('eilChipsList');
    const tStation = document.getElementById('tStation');

    // Server Hidden Fields
    const HidJson = document.getElementById('<%= HidJson.ClientID %>');
    const HidEnnx = document.getElementById('<%= HidEnnx.ClientID %>');
    const HidStation = document.getElementById('<%= HidStation.ClientID %>');
    const HidSummary = document.getElementById('<%= HidSummary.ClientID %>');
    const HidStartedUtc = document.getElementById('<%= HidStartedUtc.ClientID %>');
    const HidEndedUtc = document.getElementById('<%= HidEndedUtc.ClientID %>');
    const HidUser = document.getElementById('<%= HidUser.ClientID %>');

    function initApp() {
        if (ddlCompany && ddlCompany.value) {
            activeStation = ddlCompany.value.substring(0, 3);
            if (tStation) tStation.textContent = activeStation;
        }

        // Restore saved session if present
        restoreSession();

        // Restore / sync user session state
        syncUserSession();
        onEilToggle();

        // Populate station datalist from existing ddlEIL options if present
        if (eilStationDataList && ddlEIL && ddlEIL.options && ddlEIL.options.length > 1) {
            let dlHtml = '';
            for (let i = 0; i < ddlEIL.options.length; i++) {
                const v = ddlEIL.options[i].value;
                if (v && v !== 'All') {
                    dlHtml += '<option value="' + escapeHtml(v) + '">';
                }
            }
            eilStationDataList.innerHTML = dlHtml;
        }

        // Setup scanner listeners
        scanBox.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                processScanInput(scanBox.value);
                scanBox.value = '';
            }
        });

        // Enter key in manual input
        manualInput.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                submitManual();
            }
        });

        // Mobile / Scanner focus watchdog
        document.addEventListener('click', function (e) {
            const tag = e.target.tagName;
            if (tag === 'INPUT' || tag === 'BUTTON' || tag === 'SELECT' || tag === 'A' || tag === 'TEXTAREA') return;
            if (e.target.closest && (e.target.closest('#eilStreamPanel') || e.target.closest('button') || e.target.closest('select') || e.target.closest('input'))) return;
            focusScan();
        });

        scanBox.addEventListener('focus', function () {
            statusPill.textContent = '● READY';
            statusPill.className = 'status-pill s-ready';
            scanBox.classList.remove('blurred');
        });

        scanBox.addEventListener('blur', function () {
            statusPill.textContent = '○ PAUSED';
            statusPill.className = 'status-pill s-paused';
            scanBox.classList.add('blurred');
        });

        focusScan();
    }

    function focusScan() {
        const active = document.activeElement;
        if (active && (active.id === 'txtEilSearch' || active.id === 'manualInput' || active.id === 'ddlCollectedEil')) return;
        try { scanBox.focus({ preventScroll: true }); } catch (e) {}
    }

    function onSiteChanged(val) {
        if (!val) return;
        activeStation = val.length >= 3 ? val.substring(0, 3) : val;
        if (tStation) tStation.textContent = activeStation;
        reloadEIL(activeStation);
        rebuildPreview();
    }

    // --- EIL FILTER ENGINE (COLLECTED EILS & STATION SEARCH) ---
    function resolveAssetEILs(tags, callback) {
        if (!tags || tags.length === 0) {
            if (callback) callback('');
            return;
        }
        const needed = [];
        tags.forEach(t => {
            if (!t) return;
            if (_assetEilCache[t] === undefined) needed.push(t);
        });

        if (needed.length === 0) {
            updateCollectedEilsCounts();
            if (callback) callback(_assetEilCache[tags[0]] || '');
            return;
        }

        fetch('va_ennx_live_scan.aspx/GetEilsForTags', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: JSON.stringify({ tags: needed })
        })
        .then(res => res.json())
        .then(data => {
            const map = data.d || {};
            needed.forEach(t => {
                const clean = t.replace(/\s+/g, '');
                const val = map[t] || map[clean] || '';
                _assetEilCache[t] = val;
            });
            updateCollectedEilsCounts();
            if (callback) callback(_assetEilCache[tags[0]] || '');
        })
        .catch(() => {
            needed.forEach(t => { if (_assetEilCache[t] === undefined) _assetEilCache[t] = ''; });
            updateCollectedEilsCounts();
            if (callback) callback(_assetEilCache[tags[0]] || '');
        });
    }

    function updateCollectedEilsCounts() {
        _collectedEils = {};
        blocks.forEach(b => {
            b.assets.forEach(tag => {
                const eil = _assetEilCache[tag];
                if (eil) {
                    _collectedEils[eil] = (_collectedEils[eil] || 0) + 1;
                }
            });
        });
        renderCollectedEilsUI();
    }

    function renderCollectedEilsUI() {
        const ddl = document.getElementById('ddlCollectedEil');
        const chipsList = document.getElementById('eilChipsList');
        if (!ddl || !chipsList) return;

        const keys = Object.keys(_collectedEils).sort();

        // 1. Rebuild collected dropdown
        let ddlHtml = '<option value="All">All Scanned EILs (' + totalAssets + ' assets)</option>';
        keys.forEach(k => {
            const count = _collectedEils[k];
            const sel = (_selectedEil === k) ? ' selected="selected"' : '';
            ddlHtml += `<option value="${escapeHtml(k)}"${sel}>${escapeHtml(k)} (${count} assets)</option>`;
        });
        ddl.innerHTML = ddlHtml;
        if (_selectedEil && _selectedEil !== 'All') {
            ddl.value = _selectedEil;
        }

        // 2. Rebuild chips
        if (keys.length === 0) {
            chipsList.innerHTML = '<span class="eil-empty-hint">(Scan assets to detect EILs)</span>';
            return;
        }

        let chipsHtml = `<span class="eil-chip ${(_selectedEil === 'All' || !_selectedEil) ? 'active' : ''}" onclick="selectEil('All');">All (${totalAssets})</span>`;
        keys.forEach(k => {
            const count = _collectedEils[k];
            const act = (_selectedEil === k) ? 'active' : '';
            chipsHtml += `<span class="eil-chip ${act}" onclick="selectEil('${escapeHtml(k)}');" title="Filter by ${escapeHtml(k)}">${escapeHtml(k)} <strong style="opacity:0.85;">(${count})</strong></span>`;
        });
        chipsList.innerHTML = chipsHtml;
    }

    window.selectEil = function(eil) {
        _selectedEil = eil || 'All';
        const chk = document.getElementById('chkScanByEil');
        const txtSearch = document.getElementById('txtEilSearch');
        const btnClear = document.getElementById('btnClearEil');
        const ddl = document.getElementById('ddlCollectedEil');

        if (_selectedEil === 'All') {
            if (chk) chk.checked = false;
            if (txtSearch) txtSearch.value = '';
            if (btnClear) btnClear.style.display = 'none';
            if (ddl) ddl.value = 'All';
        } else {
            if (chk) chk.checked = true;
            if (txtSearch) txtSearch.value = _selectedEil;
            if (btnClear) btnClear.style.display = 'inline-block';
            if (ddl) ddl.value = _selectedEil;
        }

        renderCollectedEilsUI();
        renderStream();
        rebuildPreview();
    };

    window.onCollectedEilSelected = function(val) {
        selectEil(val);
    };

    window.onEilSearchInput = function(val) {
        val = (val || '').trim().toUpperCase();
        const btnClear = document.getElementById('btnClearEil');
        if (btnClear) btnClear.style.display = val ? 'inline-block' : 'none';
        if (!val) {
            selectEil('All');
        } else {
            selectEil(val);
        }
    };

    window.clearEilFilter = function() {
        selectEil('All');
    };

    window.onEilToggle = function() {
        const chk = document.getElementById('chkScanByEil');
        if (chk && !chk.checked) {
            selectEil('All');
        } else if (chk && chk.checked && _selectedEil === 'All') {
            const keys = Object.keys(_collectedEils);
            if (keys.length > 0) {
                selectEil(keys[0]);
            }
        }
    };

    function reloadEIL(stationCode) {
        fetch('va_ennx_live_scan.aspx/GetEILByStation', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: JSON.stringify({ stationCode: stationCode })
        })
        .then(res => res.json())
        .then(data => {
            const list = data.d || [];
            _stationEilList = list;
            const dl = document.getElementById('eilStationDataList');
            if (dl) {
                let dlHtml = '';
                list.forEach(item => {
                    dlHtml += '<option value="' + escapeHtml(item) + '">';
                });
                dl.innerHTML = dlHtml;
            }
            if (ddlEIL) {
                let html = '<option value="All">All</option>';
                list.forEach(item => {
                    html += '<option value="' + escapeHtml(item) + '">' + escapeHtml(item) + '</option>';
                });
                ddlEIL.innerHTML = html;
            }
        })
        .catch(() => {});
    }

    // --- SCAN PROCESSING ENGINE ---
    function processScanInput(raw) {
        if (!raw) return;
        raw = raw.trim();
        if (!raw) return;

        totalScans++;
        kReads.textContent = totalScans;

        // Visual flash
        statusPill.textContent = '⚡ SCANNING';
        statusPill.className = 'status-pill s-scanning';
        setTimeout(() => {
            if (forceLoc) {
                statusPill.textContent = '📍 SCAN LOCATION';
                statusPill.className = 'status-pill s-scanning';
            } else {
                statusPill.textContent = '● READY';
                statusPill.className = 'status-pill s-ready';
            }
        }, 350);

        const upperRaw = raw.toUpperCase();
        const hasBarcodeId = /^(\]C1|\]E0|\]D2|\]A0|\]B0|%|\\)/i.test(raw);
        const isRfid = (/F{2,}$/.test(upperRaw) || isEpcLike(raw));
        const allowRfidLoc = chkAllowRfidLoc && chkAllowRfidLoc.checked;
        const isLoc = looksLikeLocation(raw);

        // Case 1: Technician explicitly clicked "Change Location" or "Force Location"
        if (forceLoc) {
            if (upperRaw.includes('EE')) {
                addStreamRow('Ignored', raw, currentLocation, 'Awaiting room location barcode (ignored asset tag ' + raw + ')');
                return;
            }
            if (isRfid && !allowRfidLoc) {
                addStreamRow('Ignored', raw, currentLocation, 'Location must be barcode (ignored RFID tag)');
                return;
            }
            setLocation(raw);
            return;
        }

        // Case 2: No location set yet - initial room scan required
        if (!currentLocation) {
            if (isLoc || hasBarcodeId || (!upperRaw.includes('EE') && !isRfid)) {
                if (isRfid && !allowRfidLoc) {
                    addStreamRow('Ignored', raw, '(none)', 'Location must be barcode (ignored RFID tag)');
                    return;
                }
                setLocation(raw);
                return;
            }
            addStreamRow('Ignored', raw, '(none)', 'WARN: No location set. Scan location barcode first.');
            return;
        }

        // Case 3: Location is ALREADY ACTIVE (currentLocation !== '')
        // A scan that looks like a location (e.g. SP020-BD. 8A) arrives:
        if (isLoc) {
            // Only switch automatically if user explicitly checked chkAutoLoc AND scan has verified barcode prefix
            if (chkAutoLoc && chkAutoLoc.checked && hasBarcodeId) {
                setLocation(raw);
                return;
            }
            // LOCK ACTIVE LOCATION! Ambient RFID signals must NEVER switch active room!
            addStreamRow('Ignored', raw, currentLocation, 'Ignored stray location tag ' + raw + ' (Active room locked to ' + currentLocation + '. Click Change Room to switch)');
            return;
        }

        // Silent ignore for unencoded 24-hex EPC tag headers
        if (isEpcLike(raw)) {
            return;
        }

        // Add as asset to currently active room
        addAsset(raw);
    }

    function looksLikeLocation(s) {
        if (!s) return false;
        let u = s.trim().toUpperCase();
        if (u.startsWith(']C1') || u.startsWith(']E0') || u.startsWith(']D2') || u.startsWith(']A0') || u.startsWith(']B0')) {
            u = u.substring(3).trim();
        }
        if (u.startsWith('%') || u.startsWith('\\')) {
            u = u.substring(1).trim();
        }
        if (u.includes('EE')) return false;
        if (u.startsWith('SP') || u.startsWith('LOC-') || u.startsWith('ROOM-') || u.startsWith('RM-') || u.startsWith('BLDG')) return true;
        return false;
    }

    function isEpcLike(s) {
        const clean = s.replace(/\s+/g, '');
        return /^[0-9A-Fa-f]{24}$/.test(clean);
    }

    function getActiveStation() {
        if (ddlCompany && ddlCompany.value) {
            const v = ddlCompany.value.trim();
            if (v.length >= 3) return v.substring(0, 3);
            return v;
        }
        return activeStation || '517';
    }

    function normalizeLocation(raw) {
        let s = raw.trim();
        if (s.startsWith(']C1') || s.startsWith(']e0') || s.startsWith(']d2')) s = s.substring(3);
        if (s.startsWith('%') || s.startsWith('\\')) s = s.substring(1);
        return s.trim().toUpperCase();
    }

    function normalizeAsset(raw) {
        if (!raw) return null;
        let s = raw.trim();
        // Remove barcode preamble identifiers if present
        if (s.startsWith(']C1') || s.startsWith(']e0') || s.startsWith(']d2')) s = s.substring(3);
        if (s.startsWith('%') || s.startsWith('\\')) s = s.substring(1);
        s = s.trim().toUpperCase();

        // 1. Strip all trailing hex F padding (e.g. 517EE31883FF -> 517EE31883, EE31883F -> EE31883)
        s = s.replace(/F+$/, '');

        // 2. Reject raw hex EPC tags that aren't decoded (e.g. 24 hex chars with no EE)
        if (/^[0-9A-F]{18,64}$/.test(s) && !s.includes('EE')) {
            return null;
        }

        // 2b. Reject blank / unencoded or bare EE strings (e.g. "EE", "517EE", "517 EE" with no asset digits)
        if (/^(\d{3}\s*)?EE$/i.test(s) || s === 'EE') {
            return { tag: null, error: 'BLANK_TAG' };
        }

        const currentStation = getActiveStation();

        // 3. Format: Station prefix + EE (e.g. "517EE31883", "517 EE31883", "517 EE 31883", "687EE12345")
        let m = s.match(/^(\d{3})\s*EE\s*([A-Z0-9]+)$/i);
        if (m) {
            const tagStation = m[1];
            const core = m[2].toUpperCase();

            // SITE ISOLATION GATE: Reject tags belonging to other stations (e.g. 687EE invading 517 scans)
            if (currentStation && tagStation !== currentStation) {
                return { tag: null, error: 'STATION_MISMATCH', scannedStation: tagStation };
            }

            // Always format as standard iDash: "517 EE31883"
            return { tag: tagStation + ' EE' + core, error: null };
        }

        // 4. Format: EE without Station prefix (e.g. "EE31883", "EE 31883")
        m = s.match(/^EE\s*([A-Z0-9]+)$/i);
        if (m) {
            const core = m[1].toUpperCase();
            // Prepend current active station to ensure uniform iDash format: "517 EE31883"
            return { tag: currentStation + ' EE' + core, error: null };
        }

        // 5. Standard alphanumeric barcode (non-EE)
        if (s.length >= 3 && !s.includes('EE')) {
            // If barcode starts with 3 digits, ensure it doesn't belong to a different site
            if (/^\d{3}/.test(s) && currentStation && s.substring(0, 3) !== currentStation) {
                return { tag: null, error: 'STATION_MISMATCH', scannedStation: s.substring(0, 3) };
            }
            return { tag: s, error: null };
        }

        return null;
    }

    function setLocation(raw) {
        const loc = normalizeLocation(raw);
        if (!loc) {
            addStreamRow('Ignored', raw, '', 'ERR: Empty location');
            return;
        }

        forceLoc = false;
        if (scanBox) scanBox.placeholder = 'Scan location barcode (SP...) or pull trigger for asset tags...';
        if (statusPill) {
            statusPill.textContent = '● READY';
            statusPill.className = 'status-pill s-ready';
        }

        // Reaffirm location without duplicating empty blocks if scanned again
        if (currentLocation === loc && blocks.length > 0 && blocks[blocks.length - 1].location === loc) {
            addStreamRow('Location', loc, loc, 'Location reaffirmed: ' + loc);
            persistSession();
            return;
        }

        currentLocation = loc;
        totalLocations++;

        const newBlock = { location: loc, assets: [], assetSet: {} };
        blocks.push(newBlock);

        if (tLoc) tLoc.innerHTML = escapeHtml(loc) + ' <span style="font-size:10px; color:var(--accent-2, #10b981);" title="Room Locked">&#128274;</span>';
        addStreamRow('Location', loc, loc, 'Started room: ' + loc);
        persistSession();
        rebuildPreview();
    }

    function addAsset(raw) {
        if (!currentLocation) {
            addStreamRow('Ignored', raw, '(none)', 'WARN: No location set. Scan location first.');
            forceLoc = true;
            return;
        }

        const res = normalizeAsset(raw);
        if (!res || !res.tag) {
            if (res && res.error === 'STATION_MISMATCH') {
                const currentStation = getActiveStation();
                addStreamRow('Ignored', raw, currentLocation, 'Skipped: Site mismatch (' + res.scannedStation + 'EE vs ' + currentStation + ')');
            } else if (res && res.error === 'BLANK_TAG') {
                addStreamRow('Ignored', raw, currentLocation, 'Skipped: Blank/unprogrammed tag (no asset number)');
            } else {
                addStreamRow('Ignored', raw, currentLocation, 'ERR: Unrecognized tag');
            }
            return;
        }

        const tag = res.tag;
        const currentBlk = blocks[blocks.length - 1];
        if (!currentBlk) return;

        // Resolve EIL for tag (fetches and caches EIL from database)
        resolveAssetEILs([tag], function(actualEil) {
            const chkScanEil = document.getElementById('chkScanByEil');
            const isEilFilterActive = (chkScanEil && chkScanEil.checked && _selectedEil && _selectedEil !== 'All');

            if (isEilFilterActive) {
                if (actualEil === _selectedEil) {
                    commitAssetRecord(tag, currentBlk, actualEil);
                } else {
                    addStreamRow('Ignored', tag, currentLocation, 'Skipped: EIL mismatch (' + (actualEil || 'none') + ' vs ' + _selectedEil + ')', actualEil);
                }
            } else {
                commitAssetRecord(tag, currentBlk, actualEil);
            }
        });
    }

    function commitAssetRecord(tag, block, eil) {
        // De-duplication check
        if (chkDedup.checked && block.assetSet[tag]) {
            dupes++;
            addStreamRow('Duplicate', tag, currentLocation, 'Duplicate tag in current room (skipped)', eil);
            rebuildPreview();
            return;
        }

        block.assets.push(tag);
        block.assetSet[tag] = true;
        totalAssets++;

        if (eil) _assetEilCache[tag] = eil;
        updateCollectedEilsCounts();

        addStreamRow('Asset', tag, currentLocation, 'Added to ' + currentLocation, eil);
        persistSession();
        rebuildPreview();
    }

    function submitManual() {
        const val = manualInput.value.trim();
        if (!val) return;
        manualInput.value = '';
        if (looksLikeLocation(val) || forceLoc) {
            setLocation(val);
        } else {
            processScanInput(val);
        }
        focusScan();
    }

    function forceNextLocation() {
        forceLoc = true;
        statusPill.textContent = '📍 SCAN LOCATION';
        statusPill.className = 'status-pill s-scanning';
        scanBox.placeholder = 'Scan new location barcode (SP...) or enter room...';
        focusScan();
    }

    // --- STREAM TABLE & 4-COLOR VISUAL FEED ---
    function addStreamRow(type, tag, location, note, eil) {
        const now = new Date();
        const timeStr = now.toTimeString().substring(0, 8);
        const id = 'scan_' + Date.now() + '_' + Math.floor(Math.random() * 1000);
        const entryEil = eil || _assetEilCache[tag] || '';

        const entry = { id, time: timeStr, type, tag, location, note, eil: entryEil };
        logEntries.unshift(entry);

        renderStream();
    }

    function renderStream() {
        // Update badges
        let cntLoc = 0, cntAsset = 0, cntDupe = 0;
        logEntries.forEach(e => {
            if (e.type === 'Location') cntLoc++;
            else if (e.type === 'Asset') cntAsset++;
            else if (e.type === 'Duplicate') cntDupe++;
        });

        badgeAll.textContent = logEntries.length;
        badgeLoc.textContent = cntLoc;
        badgeAssets.textContent = cntAsset;
        badgeDupes.textContent = cntDupe;

        const filtered = logEntries.filter(e => {
            if (currentFilter !== 'All' && e.type !== currentFilter) return false;
            // If EIL filter is active, only show asset/dupe/ignored rows belonging to that EIL (or location rows)
            if (_selectedEil && _selectedEil !== 'All') {
                if (e.type === 'Asset' || e.type === 'Duplicate') {
                    const rowEil = e.eil || _assetEilCache[e.tag] || '';
                    if (rowEil !== _selectedEil) return false;
                }
            }
            return true;
        });

        if (filtered.length === 0) {
            const filterHint = (_selectedEil && _selectedEil !== 'All') ? ` and EIL "${_selectedEil}"` : '';
            bodyStream.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:32px 14px; color:var(--muted);">No scans matching filter "${currentFilter}"${filterHint}.</td></tr>`;
            return;
        }

        let html = '';
        filtered.forEach(e => {
            let rowCls = '';
            let badgeCls = '';
            let typeIcon = '';

            if (e.type === 'Location') {
                rowCls = 'row-loc'; badgeCls = 'b-loc'; typeIcon = '📍';
            } else if (e.type === 'Asset') {
                rowCls = 'row-asset'; badgeCls = 'b-asset'; typeIcon = '🏷️';
            } else if (e.type === 'Duplicate') {
                rowCls = 'row-dupe'; badgeCls = 'b-dupe'; typeIcon = '⚠️';
            } else {
                rowCls = 'row-ignored'; badgeCls = 'b-unk'; typeIcon = '⛔';
            }

            const rowEil = e.eil || _assetEilCache[e.tag] || '';
            const eilBadge = rowEil ? `<span class="badge" style="background:rgba(59,130,246,0.18); color:#60a5fa; font-size:10px; padding:2px 6px; border-radius:4px; font-weight:600; margin-left:6px;" title="EIL: ${escapeHtml(rowEil)}">EIL: ${escapeHtml(rowEil)}</span>` : '';

            html += `
                <tr class="${rowCls}">
                    <td style="font-family:Consolas,monospace; font-size:11px; color:var(--muted);">${e.time}</td>
                    <td><span class="badge ${badgeCls}">${typeIcon} ${e.type}</span></td>
                    <td style="font-family:Consolas,monospace; font-weight:700;">${escapeHtml(e.tag)}${eilBadge}</td>
                    <td style="font-size:11px; color:var(--text); font-weight:600;">${escapeHtml(e.location || '')}</td>
                    <td style="text-align:center;">
                        <button type="button" class="btn btn-sm btn-outline" style="padding:2px 6px; font-size:10px;" onclick="removeEntry('${e.id}');" title="Remove Entry">&times;</button>
                    </td>
                </tr>
            `;
        });

        bodyStream.innerHTML = html;
    }

    function filterStream(type) {
        currentFilter = type;
        const tabs = document.querySelectorAll('#statusTabs .status-tab');
        tabs.forEach(tab => {
            if (tab.getAttribute('data-status') === type) tab.classList.add('active');
            else tab.classList.remove('active');
        });
        renderStream();
    }

    function removeEntry(id) {
        const idx = logEntries.findIndex(e => e.id === id);
        if (idx >= 0) {
            const entry = logEntries[idx];
            logEntries.splice(idx, 1);

            // If removed asset, remove from block
            if (entry.type === 'Asset') {
                for (let b of blocks) {
                    const aIdx = b.assets.indexOf(entry.tag);
                    if (aIdx >= 0) {
                        b.assets.splice(aIdx, 1);
                        delete b.assetSet[entry.tag];
                        totalAssets = Math.max(0, totalAssets - 1);
                        break;
                    }
                }
                updateCollectedEilsCounts();
            } else if (entry.type === 'Location') {
                const bIdx = blocks.findIndex(b => b.location === entry.location);
                if (bIdx >= 0) {
                    const remBlock = blocks[bIdx];
                    // If removed block has assets, merge them into previous block so they aren't lost
                    if (bIdx > 0 && remBlock.assets && remBlock.assets.length > 0) {
                        const prevBlock = blocks[bIdx - 1];
                        remBlock.assets.forEach(a => {
                            if (!prevBlock.assetSet[a]) {
                                prevBlock.assets.push(a);
                                prevBlock.assetSet[a] = true;
                            }
                        });
                    }
                    blocks.splice(bIdx, 1);
                    totalLocations = Math.max(0, totalLocations - 1);
                    if (blocks.length > 0) {
                        currentLocation = blocks[blocks.length - 1].location;
                        if (tLoc) tLoc.innerHTML = escapeHtml(currentLocation) + ' <span style="font-size:10px; color:var(--accent-2, #10b981);" title="Room Locked">&#128274;</span>';
                    } else {
                        currentLocation = '';
                        if (tLoc) tLoc.textContent = '(none)';
                    }
                }
            }
            persistSession();
            rebuildPreview();
            renderStream();
        }
    }

    function undoLast() {
        if (!logEntries.length) return;
        const last = logEntries[0];
        removeEntry(last.id);
        focusScan();
    }

    function clearAll() {
        if (!confirm('Clear all scans and reset session?')) return;
        blocks = [];
        logEntries = [];
        currentLocation = '';
        forceLoc = false;
        totalLocations = 0;
        totalAssets = 0;
        dupes = 0;
        totalScans = 0;
        startedUtc = new Date().toISOString();
        tLoc.textContent = '(none)';
        kReads.textContent = '0';
        _assetEilCache = {};
        _collectedEils = {};
        _selectedEil = 'All';
        renderCollectedEilsUI();
        try { localStorage.removeItem(STORAGE_KEY); } catch (e) {}
        rebuildPreview();
        renderStream();
        focusScan();
    }

    // --- ENNX BUILDER & LIVE PREVIEW ---
    function buildEnnxText() {
        let lines = ['ENNX', 'ID'];
        const isEilFiltered = (_selectedEil && _selectedEil !== 'All');
        for (const b of blocks) {
            let matchedAssets = b.assets;
            if (isEilFiltered) {
                matchedAssets = b.assets.filter(a => (_assetEilCache[a] || '') === _selectedEil);
            }
            if (matchedAssets.length > 0 || !isEilFiltered) {
                lines.push(b.location);
                for (const a of matchedAssets) {
                    lines.push(a);
                }
            }
        }
        const count = lines.length - 2;
        lines.push('***END***^' + count);
        return lines.join('\r\n');
    }

    function rebuildPreview() {
        const ennx = buildEnnxText();
        ennxPreview.value = ennx;

        const isEilFiltered = (_selectedEil && _selectedEil !== 'All');
        let dispAssets = totalAssets;
        if (isEilFiltered) {
            dispAssets = _collectedEils[_selectedEil] || 0;
        }

        badgeLoc.textContent = totalLocations;
        badgeAssets.textContent = dispAssets + (isEilFiltered ? ' (filtered)' : '');
        badgeDupes.textContent = dupes;
    }

    function copyEnnx() {
        if (!ennxPreview.value) return;
        navigator.clipboard.writeText(ennxPreview.value).then(() => {
            alert('ENNX output copied to clipboard!');
        }).catch(() => {
            ennxPreview.select();
            document.execCommand('copy');
            alert('ENNX output copied!');
        });
    }

    // --- SESSION PERSISTENCE ---
    function persistSession() {
        try {
            const data = {
                blocks: blocks.map(b => ({ location: b.location, assets: b.assets.slice(0) })),
                logEntries: logEntries.slice(0, 100),
                currentLocation,
                totalLocations,
                totalAssets,
                dupes,
                totalScans,
                startedUtc,
                activeStation,
                selectedEil: _selectedEil
            };
            localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
        } catch (e) {}
    }

    function restoreSession() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) return;
            const data = JSON.parse(raw);
            if (data && data.blocks && data.blocks.length > 0) {
                blocks = data.blocks;
                for (let b of blocks) {
                    b.assetSet = {};
                    for (let a of b.assets) b.assetSet[a] = true;
                }
                logEntries = data.logEntries || [];
                currentLocation = data.currentLocation || (blocks.length ? blocks[blocks.length - 1].location : '');
                totalLocations = data.totalLocations || blocks.length;
                totalAssets = data.totalAssets || 0;
                dupes = data.dupes || 0;
                totalScans = data.totalScans || totalAssets;
                startedUtc = data.startedUtc || new Date().toISOString();
                activeStation = data.activeStation || activeStation;
                if (data.selectedEil) _selectedEil = data.selectedEil;

                if (tLoc) tLoc.innerHTML = currentLocation ? escapeHtml(currentLocation) + ' <span style="font-size:10px; color:var(--accent-2, #10b981);" title="Room Locked">&#128274;</span>' : '(none)';
                kReads.textContent = totalScans;

                // Collect all scanned tags to resolve their EILs in one fast batch
                const allTags = [];
                for (let b of blocks) {
                    for (let a of b.assets) allTags.push(a);
                }
                if (allTags.length > 0) {
                    resolveAssetEILs(allTags, function() {
                        updateCollectedEilsCounts();
                        renderStream();
                        rebuildPreview();
                    });
                } else {
                    rebuildPreview();
                    renderStream();
                }
            }
        } catch (e) {}
    }

    // --- PREPARE POSTBACK FOR COMMIT / EMAIL ---
    function preparePost(kind) {
        const ennx = buildEnnxText();
        if (totalLocations === 0 || totalAssets === 0 || !ennx) {
            alert('Please scan at least one location and asset before proceeding.');
            return false;
        }

        if (kind === 'commit') {
            if (!confirm(`Commit ${totalAssets} scanned asset(s) across ${totalLocations} location(s) to the AssetWorx database?`)) {
                return false;
            }
        }

        const endedUtc = new Date().toISOString();
        const payload = {
            station: activeStation,
            startedUtc: startedUtc,
            endedUtc: endedUtc,
            locations: blocks.map(b => ({
                location: b.location,
                assets: b.assets.slice(0)
            })),
            totals: {
                locations: totalLocations,
                assets: totalAssets,
                dupes: dupes
            }
        };

        HidJson.value = JSON.stringify(payload);
        HidEnnx.value = ennx;
        HidStation.value = activeStation;
        HidStartedUtc.value = startedUtc;
        HidEndedUtc.value = endedUtc;
        HidSummary.value = `${activeStation} | Locs: ${totalLocations} | Assets: ${totalAssets} | Dupes: ${dupes}`;

        return true;
    }

    // --- TECHNICIAN AUTH & MODAL (MATCHING VA_INVENTORY) ---
    function syncUserSession() {
        fetch('va_ennx_live_scan.aspx/GetSessionState', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: '{}'
        })
        .then(res => res.json())
        .then(data => {
            const s = JSON.parse(data.d);
            if (s && s.isLoggedIn) {
                const name = s.displayName || s.username || 'Gary Moe';
                document.getElementById('userBadge').textContent = '👤 ' + name;
                HidUser.value = name;
            }
        })
        .catch(() => {});
    }

    function openLoginModal() {
        document.getElementById('loginError').style.display = 'none';
        document.getElementById('txtLoginUser').value = '';
        document.getElementById('txtLoginPass').value = '';
        document.getElementById('loginModal').style.display = 'flex';
        setTimeout(() => document.getElementById('txtLoginUser').focus(), 100);
    }

    function closeLoginModal() {
        document.getElementById('loginModal').style.display = 'none';
        focusScan();
    }

    function submitLogin() {
        const u = document.getElementById('txtLoginUser').value.trim();
        const p = document.getElementById('txtLoginPass').value;
        const errDiv = document.getElementById('loginError');

        if (!u || !p) {
            errDiv.textContent = 'Username and password are required.';
            errDiv.style.display = 'block';
            return;
        }

        fetch('va_ennx_live_scan.aspx/Login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: JSON.stringify({ username: u, password: p })
        })
        .then(res => res.json())
        .then(data => {
            const s = JSON.parse(data.d);
            if (s && s.isLoggedIn) {
                const name = s.displayName || s.username;
                document.getElementById('userBadge').textContent = '👤 ' + name;
                HidUser.value = name;
                closeLoginModal();
            } else {
                errDiv.textContent = (s && s.error) || 'Invalid credentials.';
                errDiv.style.display = 'block';
            }
        })
        .catch(err => {
            errDiv.textContent = 'Login error: ' + err.message;
            errDiv.style.display = 'block';
        });
    }

    function toggleTheme() {
        var html = document.documentElement;
        var isLight = html.getAttribute('data-theme') === 'light';
        if (isLight) {
            html.removeAttribute('data-theme');
            localStorage.removeItem('idash_theme');
            localStorage.setItem('aw_theme_preference', 'dark');
        } else {
            html.setAttribute('data-theme', 'light');
            localStorage.setItem('idash_theme', 'light');
            localStorage.setItem('aw_theme_preference', 'light');
        }
        focusScan();
    }

    function escapeHtml(s) {
        return String(s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }
</script>

</body>
</html>
