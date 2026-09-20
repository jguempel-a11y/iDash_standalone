<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_inventory.aspx.cs" Inherits="va_inventory" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <title>VA Site Inventory &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; font-size: 13px; min-height: 100vh; }

        /* SKINNY TOP STATUS BAR (TC530e OPTIMIZED) */
        .status-bar {
            display: flex; justify-content: space-between; align-items: center;
            background: var(--chip); padding: 5px 12px; font-size: 11px; font-weight: 600;
            border-bottom: 1px solid var(--line); position: sticky; top: 0; z-index: 100;
        }
        #connection-indicator {
            display: inline-flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 700; color: var(--accent-2, #10b981);
        }

        .wrap { max-width: 1440px; margin: 6px auto; padding: 0 10px; }

        /* BUTTONS */
        .btn {
            padding: 8px 14px; border-radius: 8px; border: 1px solid var(--line);
            background: var(--chip); color: var(--text); font-size: 12px; font-weight: 600;
            cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: all 0.15s;
            text-decoration: none; user-select: none;
        }
        .btn:hover { background: var(--line); }
        .btn-sm { padding: 5px 10px; font-size: 11px; border-radius: 6px; }
        .btn-blue { background: var(--accent, #0284c7); color: #fff; border-color: var(--accent, #0284c7); }
        .btn-blue:hover { filter: brightness(1.1); }
        .btn-green { background: #10b981; color: #fff; border-color: #10b981; }
        .btn-green:hover { filter: brightness(1.1); }
        .btn-red { background: #ef4444; color: #fff; border-color: #ef4444; }
        .btn-red:hover { filter: brightness(1.1); }
        .btn-purple { background: #8b5cf6; color: #fff; border-color: #8b5cf6; }
        .btn-outline { background: transparent; border: 1px solid var(--line); color: var(--muted); }
        .btn-pill { border-radius: 999px; padding: 6px 14px; }
        .btn:disabled { opacity: 0.45; cursor: not-allowed; }

        /* CARDS */
        .card { background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 16px; margin-bottom: 14px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }

        /* CONFIG ROW */
        .cfg-row { display: flex; gap: 14px; align-items: flex-start; flex-wrap: wrap; }
        .cfg-col { display: flex; flex-direction: column; gap: 5px; min-width: 140px; }
        .lbl { font-size: 11px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px; }
        .txt {
            background: var(--bg); border: 1px solid var(--line); color: var(--text);
            padding: 8px 12px; border-radius: 8px; font-size: 13px; outline: none; transition: border-color 0.15s;
        }
        .txt:focus { border-color: var(--accent, #0284c7); }
        .current-loc-val { font-size: 24px; font-weight: 800; color: var(--accent-2, #10b981); line-height: 1.1; }
        .loc-badge { display: inline-block; background: rgba(56,189,248,0.1); color: #38bdf8; border: 1px solid rgba(56,189,248,0.3); border-radius: 6px; padding: 2px 8px; font-size: 11px; font-weight: 700; margin-top: 4px; }
        .site-locked-pill { display: inline-flex; align-items: center; gap: 6px; padding: 7px 12px; background: rgba(99,102,241,0.12); color: #6366f1; border: 1px solid rgba(99,102,241,0.3); border-radius: 8px; font-size: 13px; font-weight: 700; }

        /* SCAN BAR */
        .scan-card {
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent, #0284c7), var(--card) 92%) 0%, var(--card) 100%);
            border: 2px solid var(--accent, #0284c7); border-radius: 12px; padding: 12px 16px; margin-bottom: 14px;
            box-shadow: 0 4px 16px color-mix(in srgb, var(--accent, #0284c7), transparent 88%);
        }
        .scan-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
        .scan-title { font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.6px; color: var(--accent, #0284c7); display: flex; align-items: center; gap: 8px; }
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

        /* FILTER BAR */
        .filter-bar {
            display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;
            background: var(--card); border: 1px solid var(--line); border-radius: 8px; padding: 8px 12px; margin-bottom: 10px;
        }
        .filter-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .filter-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }

        /* STATUS FILTER TABS */
        .status-tabs { display: inline-flex; background: var(--chip); padding: 3px; border-radius: 8px; border: 1px solid var(--line); }
        .status-tab {
            padding: 5px 12px; font-size: 11px; font-weight: 700; border-radius: 6px; cursor: pointer;
            color: var(--muted); border: none; background: transparent; transition: all 0.15s;
        }
        .status-tab:hover { color: var(--text); }
        .status-tab.active { background: var(--card); color: var(--text); box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
        .status-tab .cnt-badge { font-size: 10px; padding: 1px 5px; border-radius: 10px; margin-left: 4px; background: var(--line); color: var(--text); }

        /* SEARCH INPUT */
        .search-wrap { position: relative; min-width: 260px; }
        .search-wrap input { width: 100%; padding: 7px 10px 7px 30px; font-size: 12px; border-radius: 6px; background: var(--bg); border: 1px solid var(--line); color: var(--text); outline: none; }
        .search-wrap input:focus { border-color: var(--accent, #0284c7); }
        .search-icon { position: absolute; left: 9px; top: 50%; transform: translateY(-50%); font-size: 13px; color: var(--muted); pointer-events: none; }

        /* COLUMN TOGGLE MENU */
        #ColToggleContainer {
            background: var(--chip); border: 1px solid var(--line); border-radius: 8px; padding: 12px;
            margin-bottom: 12px; display: none; flex-wrap: wrap; gap: 8px; font-size: 12px;
        }

        /* GRID / TABLE - HORIZONTAL SLIDE & SCROLL ENABLED FOR HANDHELD SCREENS */
        .grid-wrap {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            overflow-x: auto;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
            touch-action: pan-x pan-y;
            overscroll-behavior-x: contain;
            max-height: 52vh;
            position: relative;
        }
        .grid-wrap::-webkit-scrollbar {
            height: 6px;
            width: 6px;
        }
        .grid-wrap::-webkit-scrollbar-thumb {
            background: var(--line);
            border-radius: 4px;
        }
        .grid-wrap::-webkit-scrollbar-track {
            background: transparent;
        }
        .grid {
            width: 100%;
            min-width: 960px; /* Allows smooth horizontal swipe across all 11 columns on handheld TC53 / mobile screens */
            border-collapse: collapse;
            font-size: 12px;
        }
        .grid th {
            background: var(--chip); text-align: left; padding: 10px 10px; color: var(--muted);
            font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px;
            border-bottom: 2px solid var(--line); position: sticky; top: 0; z-index: 10; cursor: pointer; user-select: none;
            white-space: nowrap;
        }
        .grid th:hover { color: var(--text); }
        .grid th.sort-asc::after { content: " ▲"; font-size: 9px; }
        .grid th.sort-desc::after { content: " ▼"; font-size: 9px; }
        .grid td { padding: 9px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; transition: background 0.15s; white-space: nowrap; }
        .grid td:nth-child(4) { white-space: normal; min-width: 180px; max-width: 280px; }
        .grid tr:last-child td { border-bottom: none; }

        /* ============================================================
           ROW STATUS TINTS & HIGH-CONTRAST ACCENT BORDERS (DARK MODE DEFAULT)
           ============================================================ */
        /* FOUND: GREEN */
        .grid tr.row-found {
            background: rgba(16, 185, 129, 0.16) !important;
            border-left: 5px solid #10b981 !important;
        }
        .grid tr.row-found td {
            color: #f1f5f9 !important;
        }
        .grid tr.row-found .row-tag-name {
            color: #34d399 !important;
        }
        .grid tr.row-found .row-desc {
            color: #f8fafc !important;
        }
        .grid tr.row-found:hover td {
            background: rgba(16, 185, 129, 0.24) !important;
        }

        @keyframes row-pop-found {
            0% { transform: scale(1.02); box-shadow: 0 0 14px rgba(16, 185, 129, 0.6); }
            100% { transform: scale(1); box-shadow: none; }
        }
        .row-just-found {
            animation: row-pop-found 0.7s ease-out;
        }

        /* NOT FOUND: ORANGE (INITIAL COLOR FOR EXPECTED ASSETS) */
        .grid tr.row-notfound {
            background: transparent;
            border-left: 5px solid #f97316 !important;
        }
        .grid tr.row-notfound td {
            color: #cbd5e1 !important;
        }
        .grid tr.row-notfound .row-tag-name {
            color: #f1f5f9 !important;
        }

        /* MOVE HERE?: BLUE (FOUND BUT NOT EXPECTED IN THIS LOCATION) */
        .grid tr.row-moved {
            background: rgba(2, 132, 199, 0.18) !important;
            border-left: 5px solid #0284c7 !important;
        }
        .grid tr.row-moved td {
            color: #f1f5f9 !important;
        }
        .grid tr.row-moved .row-tag-name {
            color: #38bdf8 !important;
        }
        .grid tr.row-moved:hover td {
            background: rgba(2, 132, 199, 0.26) !important;
        }

        /* UNKNOWN: PINK (STRANGE TAGS, SHIPPING LABELS ETC) */
        .grid tr.row-unknown {
            background: rgba(236, 72, 153, 0.16) !important;
            border-left: 5px solid #ec4899 !important;
        }
        .grid tr.row-unknown td {
            color: #fdf2f8 !important;
        }
        .grid tr.row-unknown .row-tag-name {
            color: #f472b6 !important;
        }
        .grid tr.row-unknown:hover td {
            background: rgba(236, 72, 153, 0.24) !important;
        }

        /* BADGES (DARK MODE DEFAULT) */
        .badge { display: inline-block; padding: 4px 9px; border-radius: 6px; font-size: 11px; font-weight: 800; text-align: center; letter-spacing: 0.3px; }
        .badge-saved    { background: #10b981; color: #000; font-weight: 900; box-shadow: 0 0 10px rgba(16,185,129,0.35); }
        .badge-notfound { background: rgba(249, 115, 22, 0.2); color: #fb923c; border: 1px solid #f97316; font-weight: 800; }
        .badge-404      { background: #ef4444; color: #fff; }
        .badge-moved    { background: #0284c7; color: #fff; font-weight: 800; box-shadow: 0 0 10px rgba(2,132,199,0.35); }
        .badge-unk      { background: #ec4899; color: #fff; font-weight: 800; box-shadow: 0 0 10px rgba(236,72,153,0.35); }
        .badge-pending  { background: #0284c7; color: #fff; }
        .badge-flagged  { background: #facc15; color: #713f12; }

        .reads-pill { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 700; background: var(--chip); color: var(--muted); }
        .reads-pill.has-reads { background: rgba(16,185,129,0.2); color: #10b981; border: 1px solid rgba(16,185,129,0.4); font-weight: 800; }

        /* ============================================================
           LIGHT MODE OVERRIDES ([data-theme="light"]) - HIGH CONTRAST & LEGIBILITY
           ============================================================ */
        [data-theme="light"] body {
            background: #f8fafc;
            color: #0f172a;
        }

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

        [data-theme="light"] .status-tabs {
            background: #e2e8f0;
            border: 1px solid #cbd5e1;
        }
        [data-theme="light"] .status-tab {
            color: #334155;
            font-weight: 800;
        }
        [data-theme="light"] .status-tab:hover {
            color: #0f172a;
        }
        [data-theme="light"] .status-tab.active {
            background: #ffffff;
            color: #0f172a;
            font-weight: 900;
            box-shadow: 0 1px 4px rgba(0,0,0,0.12);
        }
        [data-theme="light"] .status-tab .cnt-badge {
            background: #cbd5e1;
            color: #0f172a;
            font-weight: 800;
        }
        [data-theme="light"] .status-tab.active .cnt-badge {
            background: #e2e8f0;
            color: #0f172a;
        }

        [data-theme="light"] .grid-wrap {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            box-shadow: 0 1px 4px rgba(0,0,0,0.05);
        }
        [data-theme="light"] .grid th {
            background: #f1f5f9;
            color: #1e293b;
            font-weight: 800;
            border-bottom: 2px solid #cbd5e1;
        }
        [data-theme="light"] .grid td {
            border-bottom: 1px solid #e2e8f0;
        }

        /* FOUND ROW IN LIGHT MODE: Crisp Mint Tint with Dark Bold Text */
        [data-theme="light"] .grid tr.row-found {
            background: #ecfdf5 !important;
            border-left: 5px solid #059669 !important;
        }
        [data-theme="light"] .grid tr.row-found td {
            color: #064e3b !important; /* Deep dark forest green */
            font-weight: 600;
        }
        [data-theme="light"] .grid tr.row-found .row-tag-name {
            color: #047857 !important; /* Bold vivid emerald */
            font-weight: 900 !important;
        }
        [data-theme="light"] .grid tr.row-found .row-desc {
            color: #0f172a !important; /* Crisp dark charcoal */
            font-weight: 700 !important;
        }
        [data-theme="light"] .grid tr.row-found:hover td {
            background: #d1fae5 !important;
        }

        /* NOT FOUND ROW IN LIGHT MODE (ORANGE): White background with Orange Accent */
        [data-theme="light"] .grid tr.row-notfound {
            background: #ffffff !important;
            border-left: 5px solid #ea580c !important;
        }
        [data-theme="light"] .grid tr.row-notfound td {
            color: #1e293b !important; /* Crisp dark charcoal */
            font-weight: 500;
        }
        [data-theme="light"] .grid tr.row-notfound .row-tag-name {
            color: #0f172a !important;
            font-weight: 800 !important;
        }
        [data-theme="light"] .grid tr.row-notfound .row-desc {
            color: #334155 !important;
            font-weight: 600 !important;
        }
        [data-theme="light"] .grid tr.row-notfound:hover td {
            background: #fff7ed !important;
        }

        /* MOVE HERE? ROW IN LIGHT MODE (BLUE): Soft Sky Tint with Dark Blue Text */
        [data-theme="light"] .grid tr.row-moved {
            background: #f0f9ff !important;
            border-left: 5px solid #0284c7 !important;
        }
        [data-theme="light"] .grid tr.row-moved td {
            color: #0c4a6e !important;
            font-weight: 600;
        }
        [data-theme="light"] .grid tr.row-moved .row-tag-name {
            color: #0369a1 !important;
            font-weight: 900 !important;
        }
        [data-theme="light"] .grid tr.row-moved .row-desc {
            color: #0f172a !important;
            font-weight: 700 !important;
        }
        [data-theme="light"] .grid tr.row-moved:hover td {
            background: #e0f2fe !important;
        }

        /* UNKNOWN ROW IN LIGHT MODE (PINK): Soft Rose Tint with Dark Pink Text */
        [data-theme="light"] .grid tr.row-unknown {
            background: #fdf2f8 !important;
            border-left: 5px solid #db2777 !important;
        }
        [data-theme="light"] .grid tr.row-unknown td {
            color: #831843 !important;
            font-weight: 600;
        }
        [data-theme="light"] .grid tr.row-unknown .row-tag-name {
            color: #be185d !important;
            font-weight: 900 !important;
        }
        [data-theme="light"] .grid tr.row-unknown .row-desc {
            color: #0f172a !important;
            font-weight: 700 !important;
        }
        [data-theme="light"] .grid tr.row-unknown:hover td {
            background: #fce7f3 !important;
        }

        /* BADGES IN LIGHT MODE */
        [data-theme="light"] .badge-saved {
            background: #059669 !important;
            color: #ffffff !important;
            font-weight: 900;
            box-shadow: 0 1px 3px rgba(5,150,105,0.3);
        }
        [data-theme="light"] .badge-notfound {
            background: #ffedd5 !important;
            color: #c2410c !important;
            border: 1px solid #ea580c !important;
            font-weight: 800;
        }
        [data-theme="light"] .badge-moved {
            background: #0284c7 !important;
            color: #ffffff !important;
            font-weight: 800;
            box-shadow: 0 1px 3px rgba(2,132,199,0.3);
        }
        [data-theme="light"] .badge-unk {
            background: #db2777 !important;
            color: #ffffff !important;
            font-weight: 800;
            box-shadow: 0 1px 3px rgba(219,39,119,0.3);
        }
        [data-theme="light"] .reads-pill {
            background: #e2e8f0;
            color: #334155;
            font-weight: 700;
        }
        [data-theme="light"] .reads-pill.has-reads {
            background: #d1fae5 !important;
            color: #065f46 !important;
            border: 1px solid #6ee7b7 !important;
            font-weight: 900;
        }

        /* CARDS & INPUTS IN LIGHT MODE */
        [data-theme="light"] .card {
            background: #ffffff;
            border-color: #cbd5e1;
            box-shadow: 0 1px 4px rgba(0,0,0,0.05);
        }
        [data-theme="light"] .lbl {
            color: #475569;
            font-weight: 800;
        }
        [data-theme="light"] .txt {
            background: #ffffff;
            border-color: #cbd5e1;
            color: #0f172a;
            font-weight: 600;
        }
        [data-theme="light"] .txt:focus {
            border-color: #0284c7;
        }
        [data-theme="light"] .filter-bar {
            background: #ffffff;
            border-color: #cbd5e1;
        }
        [data-theme="light"] .scan-card {
            background: #f0f9ff;
            border-color: #0284c7;
        }
        [data-theme="light"] #raw {
            background: #ffffff;
            color: #0f172a;
            border-color: #94a3b8;
        }

        /* BOTTOM ACTIONS */
        .action-row { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; margin-top: 14px; }
        .action-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .action-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }

        /* PREVIEW ENNX */
        #ennxPreviewCard { margin-top: 14px; display: none; }

        /* LOGIN MODAL */
        .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.65); backdrop-filter: blur(3px); display: flex; align-items: center; justify-content: center; z-index: 1000; padding: 16px; }
        .modal-box { background: var(--card); border: 1px solid var(--line); border-radius: 12px; width: 100%; max-width: 400px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.4); }
        .modal-hdr { padding: 14px 18px; border-bottom: 1px solid var(--line); background: var(--chip); display: flex; align-items: center; justify-content: space-between; font-weight: 700; font-size: 14px; }
        .modal-body { padding: 18px; }
        .modal-close { background: transparent; border: none; font-size: 20px; color: var(--muted); cursor: pointer; line-height: 1; }
        .login-err { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: #ef4444; padding: 8px 12px; border-radius: 8px; font-size: 12px; margin-bottom: 12px; }

        /* LOG PANEL */
        #panelLog { display: none; margin-top: 14px; }
        .log-box { background: #090d16; color: #a5b4fc; font-family: "Consolas", monospace; font-size: 11px; padding: 10px 14px; max-height: 140px; overflow-y: auto; border-radius: 8px; line-height: 1.6; }
        .log-line { display: flex; gap: 8px; }
        .log-ts { color: #64748b; min-width: 52px; }
        .log-msg { color: #e2e8f0; word-break: break-all; }

        /* EMPTY STATE */
        .empty-state { text-align: center; padding: 36px 16px; color: var(--muted); font-size: 13px; }

        /* ============================================================
           RESPONSIVE OPTIMIZATIONS (LARGE DESKTOP MONITORS vs MOBILE)
           ============================================================ */

        /* 1. LARGE COMPUTER MONITORS (1200px+ & 1600px+) */
        @media (min-width: 1200px) {
            .wrap {
                max-width: 96vw;
                width: 96%;
                margin: 10px auto;
                padding: 0 16px;
            }
            .grid-wrap {
                max-height: calc(100vh - 350px);
                min-height: 520px;
            }
            .status-bar {
                padding: 6px 18px;
                font-size: 12px;
            }
            .status-bar .btn-sm {
                padding: 4px 10px;
                font-size: 11px;
            }
            .filter-bar {
                padding: 10px 16px;
            }
            .status-tab {
                padding: 6px 16px;
                font-size: 12px;
            }
            .grid th, .grid td {
                padding: 11px 12px;
            }
        }

        @media (min-width: 1600px) {
            .wrap {
                max-width: 95vw;
                width: 95%;
            }
            .grid-wrap {
                max-height: calc(100vh - 330px);
                min-height: 600px;
            }
            .grid th, .grid td {
                font-size: 13px;
                padding: 12px 14px;
            }
            .current-loc-val {
                font-size: 28px;
            }
        }

        /* 2. TABLET & MEDIUM SCREENS (<= 1024px) */
        @media (max-width: 1024px) {
            .wrap {
                max-width: 100%;
                padding: 0 8px;
            }
            .cfg-row {
                gap: 10px;
            }
        }

        /* 3. MOBILE BROWSERS & ZEBRA TC53 HANDHELDS (<= 768px) */
        @media (max-width: 768px) {
            .wrap {
                margin: 4px auto;
                padding: 0 6px;
            }
            .card {
                padding: 12px;
                border-radius: 10px;
                margin-bottom: 8px;
            }
            .scan-card {
                padding: 10px 12px;
                margin-bottom: 8px;
            }
            #raw {
                padding: 10px 12px;
                font-size: 15px;
            }
            .cfg-col {
                min-width: 100%;
            }
            .search-wrap {
                min-width: 100%;
            }
            .filter-bar {
                padding: 6px 8px;
            }
            .status-tabs {
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
                max-width: 100%;
                white-space: nowrap;
                padding: 2px;
            }
            .status-tab {
                padding: 5px 9px;
                font-size: 11px;
                flex-shrink: 0;
            }
            .grid-wrap {
                max-height: 52vh;
                border-radius: 8px;
            }
            .action-row {
                flex-direction: column;
                align-items: stretch;
                gap: 8px;
            }
            .action-left, .action-right {
                justify-content: stretch;
                width: 100%;
            }
            .action-left .btn, .action-right .btn {
                flex: 1;
                justify-content: center;
                padding: 10px;
            }
        }

        /* 4. MOBILE / HANDHELD SCREENS (<= 680px, e.g. Zebra TC53 412px, Phones & Small Viewports) */
        @media (max-width: 680px) {
            .status-bar {
                padding: 5px 8px;
                gap: 6px;
                flex-wrap: nowrap;
            }
            .app-title {
                max-width: 130px;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
                font-size: 11px !important;
            }
            #connection-indicator {
                display: none; /* Status is prominently displayed in the scanner card pulse dot & pill */
            }
            .status-bar-actions {
                gap: 3px !important;
                flex-shrink: 0;
            }
            .status-bar-actions .btn-sm {
                padding: 3px 6px !important;
                font-size: 11px !important;
            }
            .btn-lbl {
                display: none; /* Icon-only buttons on handhelds prevent top bar wrapping and overlap */
            }
        }
    </style>
</head>
<body onload="init();">

    <!-- RESPONSIVE TOP STATUS BAR -->
    <div class="status-bar">
        <div style="display:flex; align-items:center; gap:8px; min-width:0;">
            <span class="app-title" style="font-weight:800; font-size:12px; letter-spacing:0.3px; white-space:nowrap;">iDash VA Site Inventory</span>
            <span id="connection-indicator">&bull; CONNECTED</span>
        </div>
        <div class="status-bar-actions" style="display:flex; align-items:center; gap:6px; flex-shrink:0;">
            <div id="userBadge" style="display:none; align-items:center; gap:5px;">
                <span class="user-pill" id="userPill" style="padding:2px 8px; font-size:10px; font-weight:700;"></span>
                <button class="btn btn-sm btn-outline" style="padding:2px 6px; font-size:10px;" onclick="logout(); return false;">Sign Out</button>
            </div>
            <button class="btn btn-sm btn-blue" id="btnShowLogin" style="padding:3px 8px; font-size:10px;" onclick="openLoginModal(); return false;">Sign In</button>
            <button type="button" class="btn btn-sm btn-outline" id="btnToggleTheme" style="padding:3px 8px; font-size:10px;" onmousedown="event.preventDefault();" onclick="toggleTheme();" title="Toggle Light/Dark Mode">&#9681; <span class="btn-lbl">Theme</span></button>
            <button type="button" class="btn btn-sm btn-outline" id="btnToggleConfig" style="padding:3px 8px; font-size:10px;" onclick="toggleConfigPanel();" title="Room & Scanner Setup">&#9881; <span class="btn-lbl">Config</span></button>
            <a href="documentation/va_inventory.html" target="_blank" class="btn btn-sm btn-outline" id="btnDocs" style="padding:3px 8px; font-size:10px;" title="VA Site Inventory Documentation & Navigation Guide">&#128214; <span class="btn-lbl">Docs</span></a>
            <a href="index.aspx" class="btn btn-sm btn-outline" style="padding:3px 8px; font-size:10px;" title="Back to Hub">&#8962; <span class="btn-lbl">Hub</span></a>
        </div>
    </div>

    <div class="wrap">

        <!-- CONFIGURATION PANEL (HIDEABLE) -->
        <div id="locationConfigPanel" class="card">
            <div class="cfg-row">
                <!-- 1. OPERATOR -->
                <div class="cfg-col" style="min-width:160px;">
                    <span class="lbl">Operator</span>
                    <select id="ddlOperator" class="txt" onchange="onOperatorChange();">
                        <option value="">-- Select Operator --</option>
                    </select>
                </div>

                <!-- 3. SCAN LOCATION -->
                <div class="cfg-col" style="flex:1.2; min-width:220px;">
                    <span class="lbl">1. Scan Location Barcode</span>
                    <div style="display:flex; gap:6px;">
                        <input type="text" id="txtLocation" class="txt" style="flex:1;"
                               placeholder="Type or scan location barcode (e.g. SP...)"
                               autocomplete="off" autocapitalize="characters" />
                        <button type="button" class="btn btn-blue" onclick="loadRoom(); return false;">Load Room</button>
                    </div>
                </div>

                <!-- 4. CURRENT LOCATION MODE -->
                <div class="cfg-col" style="flex:1.4; min-width:200px;">
                    <span class="lbl">Current Location Mode</span>
                    <div class="current-loc-val" id="lblCurrentLocation">(None Set)</div>
                    <span class="loc-badge" id="lblLocationTotal" style="display:none;">0 Assets Assigned</span>
                </div>

                <!-- 5. SWEEP DATE -->
                <div class="cfg-col" style="min-width:130px;">
                    <span class="lbl">Sweep Date</span>
                    <input type="date" id="txtSweepDate" class="txt" />
                </div>

                <!-- 6. QUEUE MISPLACED SCANS -->
                <div class="cfg-col" style="justify-content:center; padding-top:14px; min-width:160px;">
                    <label style="display:flex; align-items:center; gap:6px; font-size:12px; cursor:pointer; font-weight:600;">
                        <input type="checkbox" id="chkQueueMode" />
                        Queue Misplaced Scans
                    </label>
                </div>
            </div>
        </div>

        <!-- 2. HIGH-SPEED SCANNER BAR -->
        <div class="scan-card">
            <div class="scan-header">
                <div class="scan-title">
                    <div class="pulse-dot" id="pulseDot"></div>
                    <span>2. Pull RFID Trigger or Barcode Scan</span>
                    <span class="status-pill s-ready" id="statusPill">&#9711; READY</span>
                </div>
                <div style="display:flex; align-items:center; gap:8px;">
                    <button type="button" class="btn btn-sm btn-outline" onclick="toggleLog();">&#9776; Event Log</button>
                    <button type="button" class="btn btn-sm" onclick="focusScanner();">&#8635; Focus Trigger</button>
                </div>
            </div>
            <input id="raw" type="text" autocomplete="off" autocorrect="off"
                   spellcheck="false" autocapitalize="off"
                   placeholder="Pull RFID trigger to scan..." />
        </div>

        <!-- 3. REVIEW, FILTERS & DISPLAY CONTROLS TOOLBAR -->
        <div class="filter-bar">
            <div class="filter-left">
                <!-- STATUS TABS -->
                <div class="status-tabs" id="statusTabs">
                    <button type="button" class="status-tab active" data-status="All" onclick="filterByStatus('All');">
                        All <span class="cnt-badge" id="badgeAll">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Found" onclick="filterByStatus('Found');">
                        Found <span class="cnt-badge" id="badgeFound" style="color:#10b981;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Not Found" onclick="filterByStatus('Not Found');">
                        Not Found <span class="cnt-badge" id="badgeNotFound" style="color:#f97316;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Move Here?" onclick="filterByStatus('Move Here?');">
                        Move Here? <span class="cnt-badge" id="badgeMoved" style="color:#0284c7;">0</span>
                    </button>
                    <button type="button" class="status-tab" data-status="Unknown" onclick="filterByStatus('Unknown');">
                        Unknown <span class="cnt-badge" id="badgeUnknown" style="color:#ec4899;">0</span>
                    </button>
                </div>
                <span style="font-size:11px; font-weight:700; color:var(--muted); margin-left:4px; display:inline-flex; align-items:center; gap:4px;">
                    Reads: <strong style="color:var(--accent, #0284c7);" id="cntTotalReads">0</strong>
                </span>

                <!-- CMR FILTER DROPDOWN -->
                <select id="ddlCmrFilter" class="txt" style="padding:5px 10px; font-size:12px; font-weight:600; min-width:130px;" onchange="applyFilters();">
                    <option value="">All CMRs</option>
                </select>
            </div>

            <div class="filter-right">
                <button type="button" class="btn btn-outline" id="btnIgnoreMisplaced" style="display:none; font-size:11px; padding:4px 8px; color:var(--muted);" onclick="ignoreOtherScans();" title="Remove misplaced or unknown scans">&#10005; Clear Misplaced</button>
            </div>
        </div>

        <!-- 5. UNIFIED MAIN INVENTORY GRID -->
        <div class="grid-wrap">
            <table class="grid" id="tblInventory">
                <thead>
                    <tr id="tblHeaderRow">
                        <th style="width:36px; text-align:center;" data-col="0" data-notsort="true">
                            <input type="checkbox" id="chkSelectAll" onclick="toggleSelectAll(this);" title="Select All for Print" />
                        </th>
                        <th style="width:105px;" data-col="1" onclick="sortTable('status');">Status</th>
                        <th style="width:140px;" data-col="2" onclick="sortTable('name');">Asset Tag</th>
                        <th style="min-width:160px;" data-col="3" onclick="sortTable('description');">Description</th>
                        <th style="width:130px;" data-col="4" onclick="sortTable('text1');">Manufacturer</th>
                        <th style="width:120px;" data-col="5" onclick="sortTable('text2');">Model</th>
                        <th style="width:120px;" data-col="6" onclick="sortTable('text3');">Serial #</th>
                        <th style="width:130px;" data-col="7" onclick="sortTable('text4');">Category</th>
                        <th style="width:110px;" data-col="8" onclick="sortTable('text5');">Service Pointer</th>
                        <th style="width:130px;" data-col="9" onclick="sortTable('text6');">SP + Location</th>
                        <th style="width:100px;" data-col="10" onclick="sortTable('text7');">Station #</th>
                        <th style="width:90px;" data-col="11" onclick="sortTable('text8');">CMR / EIL</th>
                        <th style="width:110px;" data-col="12" onclick="sortTable('text9');">PO #</th>
                        <th style="width:130px;" data-col="13" onclick="sortTable('text10');">Phys Inv Date</th>
                        <th style="width:130px;" data-col="14" onclick="sortTable('text11');">Prev Location</th>
                        <th style="width:100px;" data-col="15" onclick="sortTable('text12');">Entry #</th>
                        <th style="width:100px;" data-col="16" onclick="sortTable('text13');">Empl_ID</th>
                        <th style="width:100px;" data-col="17" onclick="sortTable('text14');">Substation</th>
                        <th style="width:100px;" data-col="18" onclick="sortTable('text15');">Asset Value</th>
                        <th style="width:130px;" data-col="19" onclick="sortTable('text16');">Location Tagged</th>
                        <th style="width:120px;" data-col="20" onclick="sortTable('text17');">Tagged On Date</th>
                        <th style="width:80px;" data-col="21" onclick="sortTable('text18');">Tagged</th>
                        <th style="width:100px;" data-col="22" onclick="sortTable('text19');">Tag Type</th>
                        <th style="width:150px;" data-col="23" onclick="sortTable('text20');">Notes</th>
                        <th style="width:140px;" data-col="24" onclick="sortTable('lastinventoried');">Last Inventoried</th>
                        <th style="width:120px;" data-col="25" onclick="sortTable('scannedlocation');">Scanned Loc</th>
                        <th style="width:70px; text-align:center;" data-col="26" onclick="sortTable('reads');">Reads</th>
                        <th style="width:70px; text-align:center;" data-col="27" data-notsort="true">Action</th>
                    </tr>
                </thead>
                <tbody id="bodyInventory">
                    <tr>
                        <td colspan="28" class="empty-state">
                            Scan a location barcode (or type above and click "Load Room") to load assets.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- 6. BOTTOM ACTION BUTTONS -->
        <div class="action-row">
            <div class="action-left">
                <button type="button" class="btn btn-red" onclick="resetInventoryScan();">&#128465; Clear / New Scan</button>
                
                <!-- SERVER PRINT CONTROLS -->
                <select id="ddlPrintTemplate" class="txt" style="display:none; padding:6px 10px; font-size:12px; min-width:150px;">
                    <option value="">-- Print Template --</option>
                </select>
                <select id="ddlPrintTarget" class="txt" style="display:none; padding:6px 10px; font-size:12px; min-width:130px;">
                    <option value="">-- Default Route --</option>
                </select>
                <button type="button" id="btnPrintChecked" class="btn btn-blue" onclick="printSelectedTags();" style="display:none;">
                    Server Print (0)
                </button>

                <button type="button" class="btn btn-green" id="btnCommit" onclick="commitInventory();" disabled>
                    &#10004; Commit Scans
                </button>
            </div>

            <div class="action-right">
                <button type="button" class="btn" onclick="focusScanner();">&#8635; Re-Arm Scanner</button>
            </div>
        </div>

        <!-- EVENT LOG PANEL -->
        <div id="panelLog" class="card">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
                <span class="lbl">Live Scanner Diagnostics &amp; Event Log</span>
                <button type="button" class="btn btn-sm btn-outline" onclick="clearLog();">Clear Log</button>
            </div>
            <div class="log-box" id="logBox"></div>
        </div>

    </div>

    <!-- SIGN IN MODAL -->
    <div id="loginModal" class="modal-overlay" style="display:none;">
        <div class="modal-box">
            <div class="modal-hdr">
                <span>Technician Sign In</span>
                <button class="modal-close" onclick="closeLoginModal(); return false;">&times;</button>
            </div>
            <div class="modal-body">
                <p style="font-size:12px; color:var(--muted); margin-bottom:12px;">Sign in to automatically lock to your assigned site, populate your operator profile, and accelerate scanning.</p>
                <div id="loginErr" class="login-err" style="display:none;"></div>
                <div style="margin-bottom:10px;">
                    <label class="lbl">Username</label>
                    <input type="text" id="txtUsername" class="txt" style="width:100%; margin-top:4px;" placeholder="e.g. gary or 517a" autocomplete="username" autocapitalize="none" onkeydown="if(event.key==='Enter') doLogin();" />
                </div>
                <div style="margin-bottom:16px;">
                    <label class="lbl">Password</label>
                    <input type="password" id="txtPassword" class="txt" style="width:100%; margin-top:4px;" placeholder="Password" autocomplete="current-password" onkeydown="if(event.key==='Enter') doLogin();" />
                </div>
                <button type="button" id="btnLoginSubmit" class="btn btn-blue" style="width:100%; padding:10px; justify-content:center; font-size:13px;" onclick="doLogin();">Sign In</button>
                <div style="text-align:center; margin-top:12px;">
                    <a href="#" onclick="closeLoginModal(); return false;" style="font-size:11px; color:var(--muted); text-decoration:none;">Cancel / Continue Unrestricted</a>
                </div>
            </div>
        </div>
    </div>

    <!-- COMMIT CHOICE MODAL (FOR HANDLING MISPLACED ASSETS) -->
    <div id="commitModal" class="modal-overlay" style="display:none;">
        <div class="modal-box" style="max-width:440px;">
            <div class="modal-hdr">
                <span>Commit Room Inventory</span>
                <button type="button" class="modal-close" onclick="closeCommitModal();">&times;</button>
            </div>
            <div class="modal-body">
                <div style="font-size:13px; line-height:1.5; margin-bottom:12px;">
                    Location: <strong id="commitLocationName" style="color:var(--accent,#0284c7);"></strong>
                </div>
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:10px 14px; margin-bottom:14px; font-size:12px;">
                    <div style="display:flex; justify-content:space-between; margin-bottom:6px;">
                        <span>&#10004; Verified In-Place (Expected):</span>
                        <strong style="color:#10b981;" id="commitFoundCount">0</strong>
                    </div>
                    <div style="display:flex; justify-content:space-between;">
                        <span>&#9888; Misplaced (Belongs elsewhere):</span>
                        <strong style="color:#0284c7;" id="commitMovedCount">0</strong>
                    </div>
                </div>
                <div style="font-size:11px; color:var(--muted); margin-bottom:14px; line-height:1.4;">
                    Choose how to handle the misplaced assets found in this room:
                </div>
                <div style="display:flex; flex-direction:column; gap:10px;">
                    <button type="button" class="btn btn-blue" style="padding:10px; justify-content:center; font-size:12px; font-weight:700;" onclick="commitExpectedOnly();">
                        &#10004; Commit Expected Only (Ignore Misplaced)
                    </button>
                    <button type="button" class="btn" style="padding:10px; justify-content:center; font-size:12px; font-weight:700; background:#0284c7; color:#fff;" onclick="commitAllAndMove();">
                        &#8635; Commit All &amp; Move Misplaced to this Room
                    </button>
                    <button type="button" class="btn btn-outline" style="padding:8px; justify-content:center; font-size:11px;" onclick="closeCommitModal();">
                        Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>

<script>
    // ============================================================
    // APPLICATION STATE
    // ============================================================
    var _siteId          = 0;
    var _siteName        = '';
    var _operator        = '';
    var _location        = '';
    var _currentUser     = null;
    
    // Master Asset Collection (unified list of Expected, Moved, and Unknown items)
    var _assets          = []; 
    var _assetKeyMap     = {}; // Fast O(1) dictionary lookup by normalized Barcode / RFID / Serial / EIL
    var _tagReadsMap     = {}; // Track total read counts per raw tag
    var _unknownList     = []; // Explicit array of unknown tags for fast review & reporting
    var _movedList       = []; // Explicit array of moved-here assets
    
    // UI Filters & Sort State
    var _activeStatusFilter = 'All';
    var _activeCmrFilter    = '';
    var _searchQuery        = '';
    var _sortField          = 'status';
    var _sortAsc            = true;
    
    // Scanner Session Engine State
    var _sessionTimer    = null;
    var _sessionOpen     = false;
    var _manifestReady   = false;
    var _totalScanReads  = 0;
    var IDLE_MS          = 1000; // Trigger idle release timeout

    // Print Config
    window.awPrintConfig = null;

    // ============================================================
    // INIT
    // ============================================================
    function init() {
        log('Initializing VA Site Inventory engine...');
        
        // Default sweep date to today
        var dt = new Date().toISOString().split('T')[0];
        document.getElementById('txtSweepDate').value = dt;

        // Restore config hidden preference
        if (localStorage.getItem('aw_inventory_config_hidden') === 'true') {
            var panel = document.getElementById('locationConfigPanel');
            if (panel) panel.style.display = 'none';
            var btn = document.getElementById('btnToggleConfig');
            if (btn) btn.innerHTML = '&#9881; Show Config';
        }

        // Setup Location Input enter/tab key handlers
        var txtLoc = document.getElementById('txtLocation');
        txtLoc.addEventListener('keyup', function(e) {
            if (e.key === 'Enter' || e.key === 'Tab') {
                var val = txtLoc.value.trim();
                if (val.length >= 2) loadRoom();
            }
        });

        // Setup RFID Trigger Input (#raw) - PURE CLIENT ENGINE, ZERO FORMS
        var raw = document.getElementById('raw');
        raw.addEventListener('focus', function() {
            raw.classList.remove('blurred');
            raw.placeholder = 'Pull RFID trigger to scan...';
            if (!_sessionOpen) setStatus('ready');
        });
        raw.addEventListener('blur', function() {
            raw.classList.add('blurred');
            raw.placeholder = 'TAP HERE to re-arm scanner';
            setStatus('paused');
        });
        raw.addEventListener('keyup', function(e) {
            if (e.key !== 'Enter' && e.key !== 'Tab') return;
            var val = raw.value.trim().replace(/[\r\n]+$/, '').trim();
            raw.value = '';
            if (!val || val.length < 2) return;
            processTag(val);
        });

        // Check authentication & load sites / operators
        checkSession();
        loadPrintConfig();

        // Initialize column visibility from centralized Site Config
        loadColumnConfig();

        // Setup Login Enter Key handlers
        var txtU = document.getElementById('txtUsername');
        var txtP = document.getElementById('txtPassword');
        if (txtU) txtU.addEventListener('keydown', function(e) { if (e.key === 'Enter') doLogin(); });
        if (txtP) txtP.addEventListener('keydown', function(e) { if (e.key === 'Enter') doLogin(); });

        // Initial focus to location input
        setTimeout(function() {
            txtLoc.focus();
        }, 120);
    }

    function focusScanner() {
        var raw = document.getElementById('raw');
        raw.placeholder = 'Pull RFID trigger to scan...';
        raw.focus();
    }

    function toggleConfigPanel() {
        var panel = document.getElementById('locationConfigPanel');
        var btn   = document.getElementById('btnToggleConfig');
        if (!panel) return;
        if (panel.style.display === 'none') {
            panel.style.display = 'block';
            if (btn) btn.innerHTML = '&#9881; Hide Config';
            localStorage.setItem('aw_inventory_config_hidden', 'false');
        } else {
            panel.style.display = 'none';
            if (btn) btn.innerHTML = '&#9881; Show Config';
            localStorage.setItem('aw_inventory_config_hidden', 'true');
        }
    }

    function toggleTheme() {
        var html = document.documentElement;
        var current = html.getAttribute('data-theme');
        if (current === 'light') {
            html.removeAttribute('data-theme');
            localStorage.removeItem('idash_theme');
            localStorage.setItem('aw_theme_preference', 'dark');
            log('[THEME] Switched to Dark Mode');
        } else {
            html.setAttribute('data-theme', 'light');
            localStorage.setItem('idash_theme', 'light');
            localStorage.setItem('aw_theme_preference', 'light');
            log('[THEME] Switched to Light Mode');
        }
        var raw = document.getElementById('raw');
        if (raw) { try { raw.focus(); } catch (e) {} }
    }

    function toggleLog() {
        var p = document.getElementById('panelLog');
        p.style.display = p.style.display === 'none' ? 'block' : 'none';
    }

    // ============================================================
    // AUTH & SESSION STATE
    // ============================================================
    function checkSession() {
        fetch('va_inventory.aspx/GetSessionState', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (d && d.success && d.isLoggedIn) {
                applyUserSession(d);
            } else {
                _currentUser = null;
                document.getElementById('userBadge').style.display = 'none';
                document.getElementById('btnShowLogin').style.display = 'inline-flex';
                loadSites();
                loadOperators();
            }
        }).catch(function() {
            loadSites();
            loadOperators();
        });
    }

    function applyUserSession(data) {
        _currentUser = data;
        document.getElementById('userBadge').style.display = 'inline-flex';
        document.getElementById('btnShowLogin').style.display = 'none';
        document.getElementById('userPill').innerText = '👤 ' + (data.displayName || data.username);

        var sites = data.sites || [];
        if (sites.length > 0) {
            _siteId   = sites[0].id;
            _siteName = sites[0].name;
            log('[AUTH] Signed in as ' + data.displayName + ' -- Default Site: ' + _siteName);
            loadLocations(_siteId);
        } else {
            _siteId   = 0;
            _siteName = '';
            log('[AUTH] Signed in as ' + data.displayName);
            loadSites();
        }

        loadOperators(data.username);
    }

    function openLoginModal() {
        document.getElementById('loginErr').style.display = 'none';
        document.getElementById('txtPassword').value = '';
        document.getElementById('loginModal').style.display = 'flex';
        setTimeout(function(){ document.getElementById('txtUsername').focus(); }, 100);
    }

    function closeLoginModal() {
        document.getElementById('loginModal').style.display = 'none';
        document.getElementById('txtLocation').focus();
    }

    function doLogin() {
        var u = document.getElementById('txtUsername').value.trim();
        var p = document.getElementById('txtPassword').value;
        if (!u || !p) {
            showLoginError('Enter both username and password.');
            return;
        }

        var btn = document.getElementById('btnLoginSubmit');
        if (btn) { btn.disabled = true; btn.innerText = 'Signing In...'; }
        document.getElementById('loginErr').style.display = 'none';

        fetch('va_inventory.aspx/Login', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: u, password: p })
        }).then(function(r){ return r.json(); }).then(function(res) {
            if (btn) { btn.disabled = false; btn.innerText = 'Sign In'; }
            var d = parse(res);
            if (d && d.success && d.isLoggedIn) {
                closeLoginModal();
                applyUserSession(d);
            } else {
                showLoginError(d ? d.error : 'Login failed');
            }
        }).catch(function(err) {
            if (btn) { btn.disabled = false; btn.innerText = 'Sign In'; }
            showLoginError('Connection error: ' + err.message);
        });
    }

    function showLoginError(msg) {
        var el = document.getElementById('loginErr');
        el.innerText = msg;
        el.style.display = 'block';
    }

    function logout() {
        fetch('va_inventory.aspx/Logout', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(){
            _currentUser = null;
            document.getElementById('userBadge').style.display = 'none';
            document.getElementById('btnShowLogin').style.display = 'inline-flex';
            _siteId   = 0;
            _siteName = '';
            log('[AUTH] Signed out');
            loadSites();
            loadOperators();
            document.getElementById('txtLocation').focus();
        }).catch(function(){});
    }

    // ============================================================
    // SITES & OPERATORS
    // ============================================================
    function loadSites() {
        fetch('va_inventory.aspx/GetSites', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) return;
            var sites = d.sites || [];
            if (sites.length > 0 && !_siteId) {
                _siteId   = sites[0].id;
                _siteName = sites[0].name;
                loadLocations(_siteId);
            }
        }).catch(function(){});
    }

    function loadOperators(defaultUser) {
        fetch('va_inventory.aspx/GetOperators', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) return;
            var sel = document.getElementById('ddlOperator');
            sel.innerHTML = '<option value="">-- Select Operator --</option>';
            var matched = false;
            d.operators.forEach(function(op) {
                var o = document.createElement('option');
                o.value = op; o.text = op;
                if (defaultUser && op.toLowerCase() === defaultUser.toLowerCase()) {
                    o.selected = true;
                    _operator = op;
                    matched = true;
                }
                sel.appendChild(o);
            });
            if (defaultUser && !matched) {
                var o = document.createElement('option');
                o.value = defaultUser; o.text = defaultUser;
                o.selected = true;
                sel.appendChild(o);
                _operator = defaultUser;
            }
            if (!_operator && sel.options.length > 1) {
                sel.selectedIndex = 1;
                _operator = sel.value;
            }
        }).catch(function(){});
    }

    function onOperatorChange() {
        _operator = document.getElementById('ddlOperator').value;
    }

    function loadLocations(siteId) {
        fetch('va_inventory.aspx/GetLocations', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ siteId: siteId })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) return;
            var dl = document.getElementById('locDatalist');
            if (!dl) { dl = document.createElement('datalist'); dl.id = 'locDatalist'; document.body.appendChild(dl); }
            dl.innerHTML = '';
            d.locations.forEach(function(l) {
                var o = document.createElement('option'); o.value = l; dl.appendChild(o);
            });
            document.getElementById('txtLocation').setAttribute('list', 'locDatalist');
            log('[LOCATIONS] Loaded ' + d.locations.length + ' location suggestions');
        }).catch(function(){});
    }

    // ============================================================
    // LOCATION TAG DETECTION
    // Checks the loaded datalist (exact match) then falls back to SP prefix.
    // ============================================================
    function isLocationTag(tok) {
        if (!tok) return false;
        tok = tok.trim().toUpperCase();

        // 1. Exact match against known locations from the datalist
        var dl = document.getElementById('locDatalist');
        if (dl && dl.options) {
            for (var i = 0; i < dl.options.length; i++) {
                if (dl.options[i].value.toUpperCase() === tok) return true;
            }
        }

        // 2. Heuristic: starts with "SP" (standard location prefix)
        if (tok.startsWith('SP')) return true;

        return false;
    }

    // ============================================================
    // LOAD ROOM MANIFEST
    // ============================================================
    function loadRoom() {
        // Auto-close active scanner session so we can switch rooms mid-scan
        if (_sessionOpen) { closeSession(); }
        var loc = document.getElementById('txtLocation').value.trim().toUpperCase();
        if (!loc) { alert('Type or scan a location first.'); return; }

        _location      = loc;
        _manifestReady = false;
        log('[ROOM] Loading manifest for ' + loc + '...');
        document.getElementById('lblCurrentLocation').innerText = loc;

        // Pass siteId 0 so backend resolves the location across all sites
        fetch('va_inventory.aspx/LoadLocationAssets', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ locationName: loc, siteId: 0 })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) { log('[ERROR] ' + (d ? d.error : 'Load failed')); return; }

            _assets          = [];
            _assetKeyMap     = {};
            _tagReadsMap     = {};
            _unknownList     = [];
            _movedList       = [];
            _totalScanReads  = 0;

            d.assets.forEach(function(a) {
                var item = {
                    id: a.id,
                    name: a.name,
                    description: a.description,
                    rfidtag: a.rfidtag,
                    text1: a.text1 || '',
                    text2: a.text2 || '',
                    text3: a.text3 || '',
                    text4: a.text4 || '',
                    text5: a.text5 || '',
                    text6: a.text6 || '',
                    text7: a.text7 || '',
                    text8: a.text8 || '',
                    text9: a.text9 || '',
                    text10: a.text10 || '',
                    text11: a.text11 || '',
                    text12: a.text12 || '',
                    text13: a.text13 || '',
                    text14: a.text14 || '',
                    text15: a.text15 || '',
                    text16: a.text16 || '',
                    text17: a.text17 || '',
                    text18: a.text18 || '',
                    text19: a.text19 || '',
                    text20: a.text20 || '',
                    lastinventoried: a.lastinventoried || '',
                    serialnumber: a.text3 || a.serialnumber || '',
                    cmr: a.text8 || a.cmr || 'UNASSIGNED',
                    tagtype: a.text19 || a.tagtype || '',
                    dblocation: a.text6 || a.dblocation || loc,
                    scannedlocation: loc,
                    status: 'Not Found',
                    reads: 0,
                    isExpected: true
                };
                _assets.push(item);

                // Index keys in _assetKeyMap for O(1) synchronous matching
                var nameKey = (a.name || '').toUpperCase().replace(/ /g, '');
                var rfidKey = (a.rfidtag || '').toUpperCase().replace(/ /g, '');
                var serKey  = (a.text3 || a.serialnumber || '').toUpperCase().trim();
                if (nameKey) _assetKeyMap[nameKey] = item;
                if (rfidKey) _assetKeyMap[rfidKey] = item;
                if (serKey)  _assetKeyMap[serKey]  = item;
            });

            _manifestReady = true;

            // Populate CMR Filter dropdown dynamically
            populateCmrFilter();

            // Refresh UI
            filterByStatus('All');
            renderInventoryTable();
            updateStatsAndBadges();

            var totalBadge = document.getElementById('lblLocationTotal');
            totalBadge.innerText = _assets.length + ' Assigned to Room';
            totalBadge.style.display = 'inline-block';
            document.getElementById('btnCommit').disabled = false;
            log('[ROOM] Loaded ' + _assets.length + ' assets assigned to ' + loc);

            // AUTO-FOCUS ON TRIGGER INPUT IMMEDIATELY
            setTimeout(function() {
                focusScanner();
            }, 50);

        }).catch(function(err) {
            log('[ERROR] ' + err.message);
        });
    }

    function populateCmrFilter() {
        var ddl = document.getElementById('ddlCmrFilter');
        var prevVal = ddl.value;
        ddl.innerHTML = '<option value="">All CMRs</option>';

        var cmrCounts = {};
        _assets.forEach(function(a) {
            var c = a.cmr || 'UNASSIGNED';
            cmrCounts[c] = (cmrCounts[c] || 0) + 1;
        });

        var sortedCmrs = Object.keys(cmrCounts).sort();
        sortedCmrs.forEach(function(c) {
            var o = document.createElement('option');
            o.value = c;
            o.text = c + ' (' + cmrCounts[c] + ' assets)';
            ddl.appendChild(o);
        });

        if (prevVal && cmrCounts[prevVal]) ddl.value = prevVal;
    }

    // ============================================================
    // HIGH-PERFORMANCE SCAN PROCESSING ENGINE
    // Synchronous in-memory lookup at 30-50 tags/sec.
    // Zero layout reflows during active trigger hold.
    // ============================================================
    function processTag(rawVal) {
        var tok = (rawVal || '').trim().toUpperCase();
        if (!tok || tok.length < 2) return;

        // Location barcode detection: check against loaded datalist first, then SP prefix
        if (isLocationTag(tok)) {
            document.getElementById('txtLocation').value = tok;
            loadRoom();
            return;
        }

        var now = Date.now();
        _totalScanReads++;

        // Open or extend active trigger session
        if (!_sessionOpen) {
            _sessionOpen = true;
            setStatus('scanning');
            log('[SCAN] Trigger active');
        }
        clearTimeout(_sessionTimer);
        _sessionTimer = setTimeout(closeSession, IDLE_MS);

        var norm = normalizeTag(tok);

        // 1. Check if it's an expected room asset (Instant O(1) in-memory match)
        if (_manifestReady) {
            var tokNS  = tok.replace(/ /g, '');
            var normNS = norm.replace(/ /g, '');
            var match  = _assetKeyMap[tokNS] || _assetKeyMap[normNS] || _assetKeyMap[tok];

            if (match) {
                var wasNew = match.status !== 'Found';
                match.status = 'Found';
                match.reads = (match.reads || 0) + 1;

                // Move found item to the top of _assets array so it stays at the top
                var idx = _assets.indexOf(match);
                if (idx > -1) {
                    _assets.splice(idx, 1);
                    _assets.unshift(match);
                }

                // If currently on "Not Found" tab, automatically switch to "All" so the scanned item is never hidden!
                if (_activeStatusFilter === 'Not Found') {
                    filterByStatus('All');
                }

                // Move DOM row to the VERY TOP of tbody immediately with row-found styling
                var row = document.getElementById('row-' + match.id);
                var tbody = document.getElementById('bodyInventory');
                if (row && tbody) {
                    var empty = tbody.querySelector('.empty-state');
                    if (empty && empty.parentElement) empty.parentElement.remove();

                    row.setAttribute('data-status', 'Found');
                    row.className = 'row-found row-just-found';
                    if (tbody.firstElementChild !== row) {
                        tbody.insertBefore(row, tbody.firstElementChild);
                    }
                    setTimeout(function(){ row.classList.remove('row-just-found'); }, 800);
                }

                // Targeted in-place DOM update (0ms, no innerHTML rebuild!)
                var bEl = document.getElementById('badge-' + match.id);
                if (bEl && wasNew) {
                    bEl.className = 'badge badge-saved';
                    bEl.innerHTML = '✔ Found';
                    log('[FOUND] ' + match.name + ' (' + match.description + ')');
                }
                var tagEl = document.getElementById('tag-' + match.id);
                if (tagEl) {
                    tagEl.innerHTML = '<span style="color:#10b981; font-weight:900; margin-right:5px;">✔</span>' + esc(match.name);
                }
                var rEl = document.getElementById('reads-' + match.id);
                if (rEl) {
                    rEl.innerText = match.reads + 'x';
                    rEl.className = 'reads-pill has-reads';
                }

                updateStatsAndBadges();
                applyFilters();
                return;
            }
        }

        // 2. Check if already recorded as Move Here? or Unknown in current session
        if (_tagReadsMap.hasOwnProperty(tok)) {
            var existingItem = _tagReadsMap[tok];
            existingItem.reads++;
            var exReadsEl = document.getElementById('reads-' + existingItem.id);
            if (exReadsEl) exReadsEl.innerText = existingItem.reads + 'x';
            updateStatsAndBadges();
            return;
        }

        // 3. New unseen tag! Register immediately as Unknown in memory
        var tempId = 'scanned-' + (_assets.length + 1);
        var newItem = {
            id: tempId,
            name: norm,
            description: '<span style="color:var(--muted);font-style:italic;">Looking up tag...</span>',
            rfidtag: tok,
            serialnumber: '--',
            cmr: '--',
            tagtype: '--',
            dblocation: '(Pending)',
            scannedlocation: _location || '(Unknown)',
            status: 'Unknown',
            reads: 1,
            isExpected: false
        };

        // Insert after all Green Found items in _assets so Found items stay at the top
        var foundCount = _assets.filter(function(x){ return x.status === 'Found'; }).length;
        _assets.splice(foundCount, 0, newItem);
        _assetKeyMap[tok.replace(/ /g, '')] = newItem;
        _tagReadsMap[tok] = newItem;
        _unknownList.push(newItem);

        // Insert single row to table after any Found items
        insertRowInOrder(newItem);
        updateStatsAndBadges();
        log('[SCAN] Unrecognized tag ' + tok + ' &mdash; resolving against database...');

        // 4. Background AJAX lookup to identify if it belongs to another room (Move Here?) or truly Unknown
        resolveUnmatchedTag(newItem, tok);
    }

    function resolveUnmatchedTag(item, rawTag) {
        fetch('va_inventory.aspx/ProcessScan', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ scanData: rawTag, currentLocation: _location, siteId: _siteId })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (d && d.success && d.found) {
                // Asset exists in database! It's a "Move Here?" asset!
                item.status          = 'Move Here?';
                item.name            = d.name;
                item.description     = d.description;
                item.serialnumber    = d.serialnumber || d.text3 || '--';
                item.cmr             = d.cmr || d.text8 || 'UNASSIGNED';
                item.tagtype         = d.tagtype || d.text19 || '--';
                item.dblocation      = d.dbLocation || d.text6 || '(Unassigned)';
                item.dbAssetId       = d.id;
                item.text1           = d.text1 || '';
                item.text2           = d.text2 || '';
                item.text3           = d.text3 || '';
                item.text4           = d.text4 || '';
                item.text5           = d.text5 || '';
                item.text6           = d.text6 || '';
                item.text7           = d.text7 || '';
                item.text8           = d.text8 || '';
                item.text9           = d.text9 || '';
                item.text10          = d.text10 || '';
                item.text11          = d.text11 || '';
                item.text12          = d.text12 || '';
                item.text13          = d.text13 || '';
                item.text14          = d.text14 || '';
                item.text15          = d.text15 || '';
                item.text16          = d.text16 || '';
                item.text17          = d.text17 || '';
                item.text18          = d.text18 || '';
                item.text19          = d.text19 || '';
                item.text20          = d.text20 || '';
                item.lastinventoried = d.lastinventoried || '';

                // Remove from unknown list and add to moved list
                _unknownList = _unknownList.filter(function(x){ return x !== item; });
                _movedList.push(item);

                // In-place DOM update of this row
                var row = document.getElementById('row-' + item.id);
                if (row) {
                    row.outerHTML = generateRowHtml(item);
                    applyColumnVisibility();
                }

                log('[MOVE HERE?] ' + d.name + ' (Assigned to ' + d.dbLocation + ', found here)');
            } else {
                // Truly Unknown Tag (not in database)
                item.status = 'Unknown';
                item.description = '<span style="color:var(--muted);font-style:italic;">Tag not registered in database</span>';
                item.dblocation  = '<span style="color:var(--danger);">(Not in DB)</span>';
                
                var row = document.getElementById('row-' + item.id);
                if (row) {
                    row.outerHTML = generateRowHtml(item);
                    applyColumnVisibility();
                }
                log('[UNKNOWN] Tag ' + rawTag + ' is not in database');
            }
            updateStatsAndBadges();
        }).catch(function(err) {
            log('[ERROR] Tag resolution failed: ' + err.message);
        });
    }

    function normalizeTag(tok) {
        var m = tok.match(/^(\d{3})EE([A-Z0-9]+)$/);
        if (m) {
            var core = m[2];
            if (core.length > 2 && core.slice(-2) === 'FF') core = core.slice(0, -2);
            return m[1] + ' EE' + core;
        }
        return tok;
    }

    // ============================================================
    // TRIGGER SESSION CLOSE (FIRES 1s AFTER RELEASING TRIGGER)
    // ============================================================
    function closeSession() {
        _sessionOpen = false;
        setStatus('ready');
        var found = _assets.filter(function(a){ return a.status === 'Found'; }).length;
        log('[DONE] Trigger released &mdash; ' + found + ' found out of ' + _assets.length + ' assets');

        // Only sort table when trigger is completely released
        renderInventoryTable();
    }

    function setStatus(s) {
        var pill = document.getElementById('statusPill');
        var dot  = document.getElementById('pulseDot');
        if (s === 'scanning') {
            pill.className = 'status-pill s-scanning'; pill.innerHTML = '&#9654; SCANNING';
            dot.style.background = '#38bdf8';
        } else if (s === 'paused') {
            pill.className = 'status-pill s-paused'; pill.innerHTML = '&#9646;&#9646; PAUSED';
            dot.style.background = '#f97316';
        } else {
            pill.className = 'status-pill s-ready'; pill.innerHTML = '&#9711; READY';
            dot.style.background = '#10b981';
        }
    }

    // ============================================================
    // FILTERING, SEARCH & SORTING
    // ============================================================
    function filterByStatus(status) {
        _activeStatusFilter = status;

        // Update status tabs UI
        var tabs = document.querySelectorAll('#statusTabs .status-tab');
        tabs.forEach(function(t) {
            if (t.getAttribute('data-status') === status) t.classList.add('active');
            else t.classList.remove('active');
        });

        applyFilters();
    }

    function applyFilters() {
        var ddlCmr = document.getElementById('ddlCmrFilter');
        _activeCmrFilter = ddlCmr ? ddlCmr.value : '';

        var rows = document.querySelectorAll('#bodyInventory tr[data-asset-id]');
        var visibleCount = 0;
        rows.forEach(function(row) {
            var st  = row.getAttribute('data-status');
            var cmr = row.getAttribute('data-cmr');

            var matchStatus = (_activeStatusFilter === 'All') || (st === _activeStatusFilter);
            var matchCmr    = (!_activeCmrFilter) || (cmr === _activeCmrFilter);

            if (matchStatus && matchCmr) {
                row.style.display = '';
                visibleCount++;
            } else {
                row.style.display = 'none';
            }
        });

        // Informative empty state if all items are filtered out
        var emptyMsgRow = document.getElementById('filterEmptyMsgRow');
        if (rows.length > 0 && visibleCount === 0) {
            if (!emptyMsgRow) {
                emptyMsgRow = document.createElement('tr');
                emptyMsgRow.id = 'filterEmptyMsgRow';
                document.getElementById('bodyInventory').appendChild(emptyMsgRow);
            }
            var msg = 'No assets match the "' + _activeStatusFilter + '" filter.';
            if (_activeStatusFilter === 'Not Found') {
                msg = '🎉 All room assets have been Found! Tap "All" or "Found" tab above to view them.';
            } else if (_activeStatusFilter === 'Found') {
                msg = 'No assets scanned yet. Pull RFID trigger to begin finding assets.';
            }
            emptyMsgRow.innerHTML = '<td colspan="28" class="empty-state" style="padding:24px; color:var(--text); font-weight:700;">' + msg + '</td>';
            emptyMsgRow.style.display = '';
        } else if (emptyMsgRow) {
            emptyMsgRow.style.display = 'none';
        }
    }

    function sortTable(field) {
        if (_sortField === field) {
            _sortAsc = !_sortAsc;
        } else {
            _sortField = field;
            _sortAsc = true;
        }

        // Update header indicator
        var ths = document.querySelectorAll('#tblHeaderRow th');
        ths.forEach(function(th) {
            th.classList.remove('sort-asc', 'sort-desc');
        });
        var activeTh = document.querySelector('#tblHeaderRow th[onclick*="' + field + '"]');
        if (activeTh) activeTh.classList.add(_sortAsc ? 'sort-asc' : 'sort-desc');

        renderInventoryTable();
    }

    // ============================================================
    // RENDER TABLE & PREPEND ROW
    // ============================================================
    function renderInventoryTable() {
        var tbody = document.getElementById('bodyInventory');
        if (!_assets.length) {
            tbody.innerHTML = '<tr><td colspan="28" class="empty-state">Scan a location barcode to load assets.</td></tr>';
            return;
        }

        // Sort items: Found (Green) items ALWAYS pinned at the very top!
        var sorted = _assets.slice().sort(function(a, b) {
            // Found items ALWAYS come before non-found items
            if (a.status === 'Found' && b.status !== 'Found') return -1;
            if (b.status === 'Found' && a.status !== 'Found') return 1;

            var valA = a[_sortField] || '';
            var valB = b[_sortField] || '';

            if (_sortField === 'status') {
                // Priority: Found -> Move Here? -> Unknown -> Not Found
                var order = { 'Found': 1, 'Move Here?': 2, 'Unknown': 3, 'Not Found': 4 };
                valA = order[a.status] || 99;
                valB = order[b.status] || 99;
                return _sortAsc ? (valA - valB) : (valB - valA);
            }

            if (_sortField === 'reads') {
                return _sortAsc ? (a.reads - b.reads) : (b.reads - a.reads);
            }

            return _sortAsc 
                ? String(valA).localeCompare(String(valB))
                : String(valB).localeCompare(String(valA));
        });

        var html = '';
        sorted.forEach(function(a) {
            html += generateRowHtml(a);
        });
        tbody.innerHTML = html;

        applyFilters();
        applyColumnVisibility();
    }

    function insertRowInOrder(a) {
        var tbody = document.getElementById('bodyInventory');
        var empty = tbody.querySelector('.empty-state');
        if (empty && empty.parentElement) empty.parentElement.remove();

        var tempDiv = document.createElement('tbody');
        tempDiv.innerHTML = generateRowHtml(a);
        var row = tempDiv.firstElementChild;

        if (a.status === 'Found') {
            // Green Found items ALWAYS go to the very top
            tbody.insertBefore(row, tbody.firstElementChild);
        } else {
            // Non-found items (Move Here?, Unknown) must be inserted AFTER all Green Found items
            var foundRows = tbody.querySelectorAll('tr.row-found');
            if (foundRows.length > 0) {
                var lastFoundRow = foundRows[foundRows.length - 1];
                if (lastFoundRow.nextElementSibling) {
                    tbody.insertBefore(row, lastFoundRow.nextElementSibling);
                } else {
                    tbody.appendChild(row);
                }
            } else {
                tbody.insertBefore(row, tbody.firstElementChild);
            }
        }

        applyFilters();
        applyColumnVisibility();
    }

    function generateRowHtml(a) {
        var rowClass = 'row-notfound';
        var badgeClass = 'badge-notfound';
        var badgeText = '○ ' + esc(a.status);
        var tagPrefix = '';

        if (a.status === 'Found') {
            rowClass = 'row-found';
            badgeClass = 'badge-saved';
            badgeText = '✔ Found';
            tagPrefix = '<span style="color:#10b981; font-weight:900; margin-right:5px;">✔</span>';
        } else if (a.status === 'Move Here?') {
            rowClass = 'row-moved';
            badgeClass = 'badge-moved';
            badgeText = '↷ Move Here?';
            tagPrefix = '<span style="color:#0284c7; font-weight:900; margin-right:5px;">↷</span>';
        } else if (a.status === 'Unknown') {
            rowClass = 'row-unknown';
            badgeClass = 'badge-unk';
            badgeText = '? Unknown';
            tagPrefix = '<span style="color:#ec4899; font-weight:900; margin-right:5px;">?</span>';
        }

        var searchIndex = [
            a.name, a.description,
            a.text1, a.text2, a.text3, a.text4, a.text5, a.text6, a.text7, a.text8, a.text9, a.text10,
            a.text11, a.text12, a.text13, a.text14, a.text15, a.text16, a.text17, a.text18, a.text19, a.text20,
            a.lastinventoried, a.serialnumber, a.cmr, a.dblocation, a.status, a.tagtype
        ].join(' ').toLowerCase();

        return '<tr id="row-' + a.id + '" class="' + rowClass + '" data-asset-id="' + a.id + '" data-status="' + esc(a.status) + '" data-cmr="' + esc(a.cmr) + '" data-search-text="' + esc(searchIndex) + '">' +
            '<td style="text-align:center;"><input type="checkbox" class="chk-item" value="' + a.id + '" data-tagtype="' + esc(a.tagtype || a.text19) + '" onchange="updatePrintBtn();" /></td>' +
            '<td><span class="badge ' + badgeClass + '" id="badge-' + a.id + '">' + badgeText + '</span></td>' +
            '<td><div id="tag-' + a.id + '" class="row-tag-name" style="font-weight:800;font-size:13px;font-family:Consolas,monospace;">' + tagPrefix + esc(a.name) + '</div></td>' +
            '<td><div id="desc-' + a.id + '" class="row-desc">' + (a.description || '--') + '</div></td>' +
            '<td><div id="t1-' + a.id + '">' + esc(a.text1 || '--') + '</div></td>' +
            '<td><div id="t2-' + a.id + '">' + esc(a.text2 || '--') + '</div></td>' +
            '<td><div id="sn-' + a.id + '">' + esc(a.text3 || a.serialnumber || '--') + '</div></td>' +
            '<td><div id="t4-' + a.id + '">' + esc(a.text4 || '--') + '</div></td>' +
            '<td><div id="t5-' + a.id + '">' + esc(a.text5 || '--') + '</div></td>' +
            '<td><div id="dbloc-' + a.id + '">' + (a.text6 || a.dblocation || '--') + '</div></td>' +
            '<td><div id="t7-' + a.id + '">' + esc(a.text7 || '--') + '</div></td>' +
            '<td><div id="cmr-' + a.id + '">' + esc(a.text8 || a.cmr || '--') + '</div></td>' +
            '<td><div id="t9-' + a.id + '">' + esc(a.text9 || '--') + '</div></td>' +
            '<td><div id="t10-' + a.id + '">' + esc(a.text10 || '--') + '</div></td>' +
            '<td><div id="t11-' + a.id + '">' + esc(a.text11 || '--') + '</div></td>' +
            '<td><div id="t12-' + a.id + '">' + esc(a.text12 || '--') + '</div></td>' +
            '<td><div id="t13-' + a.id + '">' + esc(a.text13 || '--') + '</div></td>' +
            '<td><div id="t14-' + a.id + '">' + esc(a.text14 || '--') + '</div></td>' +
            '<td><div id="t15-' + a.id + '">' + esc(a.text15 || '--') + '</div></td>' +
            '<td><div id="t16-' + a.id + '">' + esc(a.text16 || '--') + '</div></td>' +
            '<td><div id="t17-' + a.id + '">' + esc(a.text17 || '--') + '</div></td>' +
            '<td><div id="t18-' + a.id + '">' + esc(a.text18 || '--') + '</div></td>' +
            '<td><div>' + esc(a.text19 || a.tagtype || '--') + '</div></td>' +
            '<td><div id="t20-' + a.id + '">' + esc(a.text20 || '--') + '</div></td>' +
            '<td><div id="li-' + a.id + '">' + esc(a.lastinventoried || '--') + '</div></td>' +
            '<td><div>' + esc(a.scannedlocation || '--') + '</div></td>' +
            '<td style="text-align:center;"><span class="reads-pill ' + (a.reads ? 'has-reads' : '') + '" id="reads-' + a.id + '">' + (a.reads ? a.reads + 'x' : '--') + '</span></td>' +
            '<td style="text-align:center;"><button type="button" class="btn btn-sm btn-red" onclick="removeAssetItem(\'' + a.id + '\');" style="padding:2px 6px; font-size:10px;">X</button></td>' +
        '</tr>';
    }

    function removeAssetItem(id) {
        _assets = _assets.filter(function(a){ return String(a.id) !== String(id); });
        _unknownList = _unknownList.filter(function(a){ return String(a.id) !== String(id); });
        _movedList = _movedList.filter(function(a){ return String(a.id) !== String(id); });

        var row = document.getElementById('row-' + id);
        if (row) row.remove();

        updateStatsAndBadges();
        log('[REMOVE] Removed item ' + id);
    }

    function updateStatsAndBadges() {
        var found    = _assets.filter(function(a){ return a.status === 'Found'; }).length;
        var notFound = _assets.filter(function(a){ return a.status === 'Not Found'; }).length;
        var moved    = _assets.filter(function(a){ return a.status === 'Move Here?'; }).length;
        var unk      = _assets.filter(function(a){ return a.status === 'Unknown'; }).length;
        var total    = _assets.length;

        var readsEl = document.getElementById('cntTotalReads');
        if (readsEl) readsEl.innerText = _totalScanReads;

        var bAll = document.getElementById('badgeAll');
        if (bAll) bAll.innerText = total;
        var bFound = document.getElementById('badgeFound');
        if (bFound) bFound.innerText = found;
        var bNotFound = document.getElementById('badgeNotFound');
        if (bNotFound) bNotFound.innerText = notFound;
        var bMoved = document.getElementById('badgeMoved');
        if (bMoved) bMoved.innerText = moved;
        var bUnk = document.getElementById('badgeUnknown');
        if (bUnk) bUnk.innerText = unk;

        var btnIgnore = document.getElementById('btnIgnoreMisplaced');
        if (btnIgnore) {
            btnIgnore.style.display = (moved > 0 || unk > 0) ? 'inline-flex' : 'none';
        }
    }

    // ============================================================
    // CENTRALIZED COLUMN VISIBILITY (CONFIGURED VIA SITE CONFIG)
    // ============================================================
    function loadColumnConfig() {
        fetch('va_inventory.aspx/GetColumnConfig', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d) return;

            var hiddenCols = [];
            if (d.va_inventory && d.va_inventory.columns) {
                d.va_inventory.columns.forEach(function(col) {
                    if (col.visible === false) hiddenCols.push(col.index);
                });
            } else if (d.va_inventory && d.va_inventory.hiddenIndices) {
                hiddenCols = d.va_inventory.hiddenIndices;
            }

            localStorage.setItem('aw_inventory_hidden_cols', JSON.stringify(hiddenCols));
            applyColumnVisibility();
            log('[COLUMNS] Loaded site column configuration (' + hiddenCols.length + ' hidden columns)');
        }).catch(function() {
            applyColumnVisibility();
        });
    }

    function applyColumnVisibility() {
        var styleTag = document.getElementById('GridColStyles');
        if (!styleTag) {
            styleTag = document.createElement('style');
            styleTag.id = 'GridColStyles';
            document.head.appendChild(styleTag);
        }
        var hiddenCols = JSON.parse(localStorage.getItem('aw_inventory_hidden_cols') || '[]');
        var css = '';
        hiddenCols.forEach(function(index) {
            // nth-child is 1-based index
            css += '#tblInventory th:nth-child(' + (index + 1) + '), #tblInventory td:nth-child(' + (index + 1) + ') { display: none !important; }\n';
        });
        styleTag.innerHTML = css;
    }

    // ============================================================
    // COMMIT SCANS & NEXT ROOM WORKFLOW
    // ============================================================
    function commitInventory() {
        var foundItems = _assets.filter(function(a){ return a.status === 'Found'; });
        var movedItems = _assets.filter(function(a){ return a.status === 'Move Here?'; });

        if (!foundItems.length && !movedItems.length) {
            alert('No scanned assets marked Found or Move Here? yet.');
            return;
        }
        if (!_location) {
            alert('No room loaded.');
            return;
        }

        if (movedItems.length > 0) {
            // Display modal choice to move them or commit expected only
            document.getElementById('commitLocationName').innerText = _location;
            document.getElementById('commitFoundCount').innerText = foundItems.length;
            document.getElementById('commitMovedCount').innerText = movedItems.length;
            document.getElementById('commitModal').style.display = 'flex';
        } else {
            // Only expected found items
            if (!confirm('Commit ' + foundItems.length + ' Found assets to ' + _location + '?')) return;
            executeCommit(foundItems, 'Expected Room Assets Only');
        }
    }

    function closeCommitModal() {
        var m = document.getElementById('commitModal');
        if (m) m.style.display = 'none';
    }

    function commitExpectedOnly() {
        var foundItems = _assets.filter(function(a){ return a.status === 'Found'; });
        executeCommit(foundItems, 'Expected Room Assets Only');
    }

    function commitAllAndMove() {
        var committable = _assets.filter(function(a){ return a.status === 'Found' || a.status === 'Move Here?'; });
        executeCommit(committable, 'All Scans (Moved Misplaced Assets Here)');
    }

    function executeCommit(itemsToCommit, modeDesc) {
        closeCommitModal();
        if (!itemsToCommit.length) {
            alert('No assets to commit.');
            return;
        }

        var username = _operator || (_currentUser ? _currentUser.username : '');
        var btn = document.getElementById('btnCommit');
        btn.disabled = true;
        btn.innerText = 'Committing...';

        var payload = itemsToCommit.map(function(a){
            return { id: a.dbAssetId || a.id, name: a.name };
        });

        fetch('va_inventory.aspx/CommitInventory', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                locationName: _location,
                scanDataJson: JSON.stringify(payload),
                siteId: _siteId,
                username: username
            })
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (d && d.success) {
                alert('Successfully committed ' + d.committed + ' assets to ' + _location + '!\n\nReady for next room.');
                log('[COMMIT] ' + d.committed + ' assets committed by ' + username + ' to ' + _location + ' (' + modeDesc + ')');
                prepareNextRoom();
            } else {
                alert('Commit failed: ' + (d ? d.error : 'Unknown error'));
            }
            btn.disabled = false;
            btn.innerText = '✔ Commit Scans';
        }).catch(function(err){
            alert('Error committing scans: ' + err.message);
            btn.disabled = false;
            btn.innerText = '✔ Commit Scans';
        });
    }

    function prepareNextRoom() {
        _assets          = [];
        _assetKeyMap     = {};
        _tagReadsMap     = {};
        _unknownList     = [];
        _movedList       = [];
        _location        = '';
        _manifestReady   = false;
        _totalScanReads  = 0;

        document.getElementById('lblCurrentLocation').innerText = '(None Set)';
        var totBadge = document.getElementById('lblLocationTotal');
        if (totBadge) totBadge.style.display = 'none';

        var txtLoc = document.getElementById('txtLocation');
        if (txtLoc) {
            txtLoc.value = '';
            txtLoc.placeholder = 'Type or scan NEXT room barcode (e.g. SP...)';
            setTimeout(function(){ txtLoc.focus(); }, 120);
        }

        document.getElementById('btnCommit').disabled = true;
        renderInventoryTable();
        updateStatsAndBadges();
        filterByStatus('All');
        setStatus('ready');
        log('[NEXT ROOM] Ready for next location. Scan room barcode to begin.');
    }

    function ignoreOtherScans() {
        if (!confirm('Clear all misplaced and unknown items from this sweep?')) return;
        _assets = _assets.filter(function(a){ return a.isExpected; });
        _unknownList = [];
        _movedList = [];
        _tagReadsMap = {};

        renderInventoryTable();
        updateStatsAndBadges();
        log('[IGNORE] Discarded misplaced/unknown scans. Only expected room assets retained.');
    }

    function resetInventoryScan() {
        if (!confirm('Start a new scan? This will reset all counters for this room.')) return;
        clearTimeout(_sessionTimer);
        _sessionOpen   = false;
        _totalScanReads= 0;
        _unknownList   = [];
        _movedList     = [];
        _assets = _assets.filter(function(a){ return a.isExpected; });
        _assets.forEach(function(a){ a.status = 'Not Found'; a.reads = 0; });

        renderInventoryTable();
        updateStatsAndBadges();
        setStatus('ready');
        log('[RESET] Inventory reset. Pull RFID trigger to begin new sweep.');
        focusScanner();
    }

    // ============================================================
    // SERVER PRINTING ENGINE (LEGACY FEATURE INTEGRATED)
    // ============================================================
    function loadPrintConfig() {
        fetch('va_inventory.aspx/GetPrintConfig', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}'
        }).then(function(r){ return r.json(); }).then(function(res) {
            var d = parse(res);
            if (!d || !d.success) return;
            window.awPrintConfig = d;

            var ddlTpl = document.getElementById('ddlPrintTemplate');
            if (ddlTpl && d.printTemplates) {
                d.printTemplates.forEach(function(t) {
                    var o = document.createElement('option');
                    o.value = t.id; o.text = t.name + ' (ID: ' + t.id + ')';
                    ddlTpl.appendChild(o);
                });
            }

            var ddlTgt = document.getElementById('ddlPrintTarget');
            if (ddlTgt && d.availableClients) {
                d.availableClients.forEach(function(c) {
                    var o = document.createElement('option');
                    o.value = c; o.text = 'Client: ' + c;
                    ddlTgt.appendChild(o);
                });
            }
        }).catch(function(){});
    }

    function toggleSelectAll(src) {
        var chks = document.querySelectorAll('.chk-item');
        chks.forEach(function(c){ c.checked = src.checked; });
        updatePrintBtn();
    }

    function updatePrintBtn() {
        var checked = document.querySelectorAll('.chk-item:checked');
        var btn = document.getElementById('btnPrintChecked');
        var ddlTpl = document.getElementById('ddlPrintTemplate');
        var ddlTgt = document.getElementById('ddlPrintTarget');

        if (checked.length > 0) {
            btn.style.display = 'inline-flex';
            btn.innerText = 'Server Print (' + checked.length + ')';
            if (ddlTpl) ddlTpl.style.display = 'inline-block';
            if (ddlTgt) ddlTgt.style.display = 'inline-block';
        } else {
            btn.style.display = 'none';
            if (ddlTpl) ddlTpl.style.display = 'none';
            if (ddlTgt) ddlTgt.style.display = 'none';
        }
    }

    function printSelectedTags() {
        var checked = document.querySelectorAll('.chk-item:checked');
        if (!checked.length) return;

        var ddlTpl = document.getElementById('ddlPrintTemplate');
        var ddlTgt = document.getElementById('ddlPrintTarget');
        var tplId = ddlTpl && ddlTpl.value ? parseInt(ddlTpl.value, 10) : 0;
        var tgt = ddlTgt ? ddlTgt.value : '';

        var payload = [];
        checked.forEach(function(cb) {
            var val = cb.value;
            var matchItem = _assets.find(function(a){ return String(a.id) === String(val); });
            var recordId = matchItem ? (matchItem.dbAssetId || (parseInt(matchItem.id, 10) || 0)) : 0;
            if (recordId > 0) {
                payload.push({
                    recordID: recordId,
                    templateID: tplId || 1,
                    tableName: 'Asset',
                    useWithService: tgt || 'print',
                    completed: false
                });
            }
        });

        if (!payload.length) {
            alert('No valid database records selected for server printing.');
            return;
        }

        var btn = document.getElementById('btnPrintChecked');
        btn.disabled = true;
        btn.innerText = 'Printing...';

        fetch('va_tagteam_scan.aspx?action=print', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=utf-8' },
            body: JSON.stringify(payload)
        }).then(function(resp) {
            if (resp.ok) {
                alert('Sent ' + payload.length + ' tags to server print service successfully.');
                checked.forEach(function(c){ c.checked = false; });
                document.getElementById('chkSelectAll').checked = false;
                updatePrintBtn();
            } else {
                alert('Server print returned error: ' + resp.status);
            }
            btn.disabled = false;
            btn.innerText = 'Server Print (' + checked.length + ')';
        }).catch(function(err) {
            alert('Print error: ' + err.message);
            btn.disabled = false;
        });
    }

    // ============================================================
    // LOG & UTILITY FUNCTIONS
    // ============================================================
    function log(msg) {
        var box  = document.getElementById('logBox');
        if (!box) return;
        var line = document.createElement('div');
        line.className = 'log-line';
        line.innerHTML = '<span class="log-ts">' + timeStr() + '</span>' +
                         '<span class="log-msg">' + msg + '</span>';
        box.appendChild(line);
        box.scrollTop = box.scrollHeight;
    }

    function clearLog() {
        var box = document.getElementById('logBox');
        if (box) box.innerHTML = '';
    }

    function parse(res) {
        if (!res) return null;
        return typeof res.d === 'string' ? JSON.parse(res.d) : res.d;
    }

    function timeStr() { return new Date().toTimeString().split(' ')[0]; }
    function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
</script>

</body>
</html>

