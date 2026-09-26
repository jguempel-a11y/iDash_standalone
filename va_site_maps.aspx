<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_site_maps.aspx.cs" Inherits="va_site_maps" ResponseEncoding="utf-8" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VA Site Maps &mdash; Tagging Command Center</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        /* ============================================================
           ROOT & RESET — Theme-aware variables
           ============================================================ */
        :root {
            --sm-green:  #10b981;
            --sm-red:    #ef4444;
            --sm-amber:  #f59e0b;
            --sm-blue:   #3b82f6;
            --sm-purple: #8b5cf6;
            --sm-teal:   #14b8a6;
            --sm-radius: 12px;
            --sm-transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

            /* Theme-adaptive overlays (dark defaults) */
            --sm-hover: rgba(255,255,255,0.06);
            --sm-hover-strong: rgba(255,255,255,0.08);
            --sm-hover-subtle: rgba(255,255,255,0.03);
            --sm-scrollbar: rgba(255,255,255,0.1);
            --sm-border-subtle: rgba(255,255,255,0.03);
            --sm-border-hover: rgba(255,255,255,0.15);
            --sm-shadow-lg: 0 8px 20px rgba(0,0,0,0.25);
            --sm-shadow-sidebar: 4px 0 24px rgba(0,0,0,0.15);
            --sm-overlay: rgba(0,0,0,0.5);
            --sm-spinner-track: rgba(255,255,255,0.2);
            --sm-viewer-bg: #111;
            --sm-dot-border: rgba(0,0,0,0.2);
            --sm-editor-shadow: 0 8px 24px rgba(0,0,0,0.4);
            --sm-badge-bg: rgba(255,255,255,0.08);
            --sm-grad-blue: rgba(59, 130, 246, 0.12);
            --sm-grad-green: rgba(16, 185, 129, 0.08);
        }

        [data-theme="light"] {
            --sm-hover: rgba(0,0,0,0.04);
            --sm-hover-strong: rgba(0,0,0,0.06);
            --sm-hover-subtle: rgba(0,0,0,0.02);
            --sm-scrollbar: rgba(0,0,0,0.12);
            --sm-border-subtle: rgba(0,0,0,0.04);
            --sm-border-hover: rgba(0,0,0,0.12);
            --sm-shadow-lg: 0 4px 12px rgba(0,0,0,0.08);
            --sm-shadow-sidebar: 2px 0 12px rgba(0,0,0,0.06);
            --sm-overlay: rgba(255,255,255,0.7);
            --sm-spinner-track: rgba(0,0,0,0.12);
            --sm-viewer-bg: #f5f3f0;
            --sm-dot-border: rgba(255,255,255,0.5);
            --sm-editor-shadow: 0 4px 16px rgba(0,0,0,0.12);
            --sm-badge-bg: rgba(0,0,0,0.06);
            --sm-grad-blue: rgba(59, 130, 246, 0.06);
            --sm-grad-green: rgba(16, 185, 129, 0.04);

            /* Adjust accent colors for light mode readability */
            --sm-green:  #059669;
            --sm-red:    #dc2626;
            --sm-amber:  #d97706;
            --sm-blue:   #2563eb;
            --sm-purple: #7c3aed;
            --sm-teal:   #0d9488;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', 'Segoe UI', sans-serif;
            background: var(--bg);
            color: var(--text);
            display: flex;
            height: 100vh;
            overflow: hidden;
            background-image:
                radial-gradient(at 0% 0%, var(--sm-grad-blue) 0px, transparent 50%),
                radial-gradient(at 100% 100%, var(--sm-grad-green) 0px, transparent 50%);
        }


        /* ============================================================
           SIDEBAR
           ============================================================ */
        .sidebar {
            width: 300px;
            min-width: 300px;
            background: var(--card);
            border-right: 1px solid var(--line);
            display: flex;
            flex-direction: column;
            z-index: 10;
            box-shadow: var(--sm-shadow-sidebar);
        }

        .sidebar-header {
            padding: 24px 20px 20px;
            border-bottom: 1px solid var(--line);
        }

        .sidebar-header .logo {
            font-size: 18px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 6px;
        }

        .sidebar-header .logo-icon {
            width: 32px; height: 32px;
            background: linear-gradient(135deg, var(--sm-blue), var(--sm-green));
            border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 4px 12px rgba(59,130,246,0.25);
        }

        .sidebar-header p {
            color: var(--muted);
            font-size: 12px;
            line-height: 1.5;
        }

        /* Site Selector */
        .site-selector {
            padding: 16px 20px;
            border-bottom: 1px solid var(--line);
        }

        .site-selector label {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
            display: block;
            margin-bottom: 8px;
        }

        .site-selector select {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: var(--chip);
            color: var(--text);
            font-size: 13px;
            font-family: inherit;
            cursor: pointer;
        }

        .site-selector select:focus {
            outline: none;
            border-color: var(--sm-blue);
        }

        /* KPI Bar in sidebar */
        .kpi-bar {
            padding: 16px 20px;
            border-bottom: 1px solid var(--line);
            display: flex;
            gap: 8px;
        }

        .kpi-chip {
            flex: 1;
            text-align: center;
            padding: 10px 6px;
            border-radius: 8px;
            border: 1px solid var(--line);
            background: var(--chip);
        }

        .kpi-chip .kpi-val {
            font-size: 18px;
            font-weight: 800;
            display: block;
            line-height: 1.2;
        }

        .kpi-chip .kpi-label {
            font-size: 10px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .kpi-chip.green .kpi-val { color: var(--sm-green); }
        .kpi-chip.red .kpi-val { color: var(--sm-red); }
        .kpi-chip.blue .kpi-val { color: var(--sm-blue); }

        /* View Toggle */
        .view-toggle {
            padding: 12px 20px;
            border-bottom: 1px solid var(--line);
        }

        .view-toggle label {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
            display: block;
            margin-bottom: 8px;
        }

        .toggle-group {
            display: flex;
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: hidden;
        }

        .toggle-btn {
            flex: 1;
            padding: 8px 4px;
            text-align: center;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            background: var(--chip);
            color: var(--muted);
            border: none;
            border-right: 1px solid var(--line);
            transition: var(--sm-transition);
        }

        .toggle-btn:last-child { border-right: none; }

        .toggle-btn:hover { background: var(--sm-hover); color: var(--text); }

        .toggle-btn.active {
            background: rgba(59,130,246,0.15);
            color: var(--sm-blue);
        }

        .toggle-btn.active.green-active {
            background: rgba(16,185,129,0.15);
            color: var(--sm-green);
        }

        .toggle-btn.active.red-active {
            background: rgba(239,68,68,0.12);
            color: var(--sm-red);
        }

        /* Sidebar Directory List */
        .dir-list {
            flex: 1;
            overflow-y: auto;
            padding: 12px;
        }

        .dir-list::-webkit-scrollbar { width: 5px; }
        .dir-list::-webkit-scrollbar-thumb { background: var(--sm-scrollbar); border-radius: 3px; }

        .dir-item {
            padding: 10px 14px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            color: var(--muted);
            transition: var(--sm-transition);
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 2px;
        }

        .dir-item:hover { background: var(--sm-hover-subtle); color: var(--text); }
        .dir-item.active { background: rgba(59,130,246,0.1); color: var(--sm-blue); }

        .dir-badge {
            margin-left: auto;
            font-size: 10px;
            background: var(--sm-badge-bg);
            padding: 2px 7px;
            border-radius: 10px;
        }

        /* Sidebar Actions */
        .sidebar-actions {
            padding: 12px 20px;
            border-top: 1px solid var(--line);
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .sidebar-actions .s-btn {
            padding: 8px 14px;
            border-radius: 8px;
            border: 1px solid var(--line);
            background: var(--chip);
            color: var(--text);
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            text-align: left;
            transition: var(--sm-transition);
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .sidebar-actions .s-btn:hover { background: var(--sm-hover); }
        .sidebar-actions .s-btn.primary { background: rgba(59,130,246,0.12); color: var(--sm-blue); border-color: rgba(59,130,246,0.3); }
        .sidebar-actions .s-btn.green { background: rgba(16,185,129,0.1); color: var(--sm-green); border-color: rgba(16,185,129,0.3); }


        /* ============================================================
           MAIN CONTENT
           ============================================================ */
        .main {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .main-header {
            padding: 20px 36px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--line);
            background: color-mix(in srgb, var(--card), transparent 30%);
            backdrop-filter: blur(12px);
            z-index: 5;
            flex-shrink: 0;
        }

        .main-header h1 { font-size: 22px; font-weight: 700; }

        .main-header-actions { display: flex; gap: 10px; }

        .btn {
            background: var(--chip);
            border: 1px solid var(--line);
            color: var(--text);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: var(--sm-transition);
            display: flex;
            align-items: center;
            gap: 6px;
            text-decoration: none;
        }

        .btn:hover { background: var(--sm-hover-strong); }

        .btn-blue { background: rgba(59,130,246,0.12); color: var(--sm-blue); border-color: rgba(59,130,246,0.3); }
        .btn-green { background: rgba(16,185,129,0.1); color: var(--sm-green); border-color: rgba(16,185,129,0.3); }

        /* Progress bar in header */
        .progress-bar-wrap {
            flex: 1;
            max-width: 300px;
            margin: 0 24px;
        }

        .progress-track {
            height: 8px;
            background: var(--sm-hover);
            border-radius: 4px;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            border-radius: 4px;
            background: linear-gradient(90deg, var(--sm-blue), var(--sm-green));
            transition: width 0.8s ease-out;
        }

        .progress-label {
            font-size: 11px;
            color: var(--muted);
            margin-top: 4px;
            text-align: center;
        }

        /* Content Area */
        .content-scroll {
            flex: 1;
            overflow-y: auto;
            padding: 24px 36px;
        }

        .content-scroll::-webkit-scrollbar { width: 8px; }
        .content-scroll::-webkit-scrollbar-thumb { background: var(--sm-scrollbar); border-radius: 4px; }


        /* ============================================================
           MAP CARDS GRID
           ============================================================ */
        .maps-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }

        .map-card {
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: var(--sm-radius);
            padding: 18px;
            cursor: pointer;
            transition: var(--sm-transition);
            position: relative;
            overflow: hidden;
        }

        .map-card:hover {
            transform: translateY(-3px);
            border-color: var(--sm-border-hover);
            box-shadow: var(--sm-shadow-lg);
        }

        .map-card.selected {
            border-color: var(--sm-blue);
            box-shadow: 0 0 0 2px rgba(59,130,246,0.2), var(--sm-shadow-lg);
        }

        .map-card .card-top {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 12px;
        }

        .map-card .format-icon {
            width: 36px; height: 36px;
            border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            font-size: 13px; font-weight: 800;
        }

        .format-icon.pdf { color: #ef4444; background: rgba(239,68,68,0.1); }
        .format-icon.png { color: #8b5cf6; background: rgba(139,92,246,0.1); }
        .format-icon.jpg { color: #3b82f6; background: rgba(59,130,246,0.1); }

        .card-tag-status {
            display: flex;
            gap: 6px;
        }

        .card-tag-status .badge {
            font-size: 10px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
        }

        .badge-green { background: rgba(16,185,129,0.15); color: var(--sm-green); }
        .badge-red { background: rgba(239,68,68,0.1); color: var(--sm-red); }

        .card-title {
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 10px;
            line-height: 1.4;
            overflow-wrap: break-word;
        }

        .card-progress {
            height: 6px;
            background: var(--sm-hover);
            border-radius: 3px;
            overflow: hidden;
            margin-bottom: 6px;
        }

        .card-progress-fill {
            height: 100%;
            border-radius: 3px;
            transition: width 0.6s ease-out;
        }

        .card-progress-fill.green { background: var(--sm-green); }
        .card-progress-fill.amber { background: var(--sm-amber); }
        .card-progress-fill.red { background: var(--sm-red); }

        .card-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .card-footer .pct {
            font-size: 12px;
            font-weight: 700;
        }

        .card-footer .pct.green { color: var(--sm-green); }
        .card-footer .pct.amber { color: var(--sm-amber); }

        .card-footer .view-link {
            font-size: 12px;
            color: var(--sm-blue);
            text-decoration: none;
            font-weight: 600;
        }


        /* ============================================================
           DETAIL PANEL
           ============================================================ */
        .detail-panel {
            display: none;
            border: 1px solid var(--line);
            border-radius: var(--sm-radius);
            background: var(--card);
            margin-bottom: 24px;
            overflow: hidden;
        }

        .detail-panel.show { display: block; }

        .detail-header {
            padding: 16px 24px;
            border-bottom: 1px solid var(--line);
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: var(--chip);
        }

        .detail-header h2 { font-size: 16px; font-weight: 700; }

        .detail-close {
            background: none;
            border: 1px solid var(--line);
            color: var(--muted);
            width: 28px; height: 28px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            display: flex; align-items: center; justify-content: center;
        }

        .detail-close:hover { color: var(--text); background: var(--sm-hover); }

        .detail-viewer {
            height: 500px;
            border-bottom: 1px solid var(--line);
        }

        .detail-viewer iframe,
        .detail-viewer img {
            width: 100%;
            height: 100%;
            border: none;
            object-fit: contain;
            background: var(--sm-viewer-bg);
        }

        .detail-actions {
            padding: 12px 24px;
            display: flex;
            gap: 10px;
            border-bottom: 1px solid var(--line);
            flex-wrap: wrap;
            align-items: center;
        }


        /* ============================================================
           ASSET DATA TABLE
           ============================================================ */
        .asset-table-wrap {
            max-height: 500px;
            overflow: auto;
        }

        .asset-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
        }

        .asset-table th {
            position: sticky;
            top: 0;
            background: var(--chip);
            color: var(--muted);
            padding: 10px 14px;
            text-align: left;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            border-bottom: 1px solid var(--line);
            z-index: 2;
            white-space: nowrap;
        }

        .asset-table td {
            padding: 8px 14px;
            border-bottom: 1px solid var(--sm-border-subtle);
            white-space: nowrap;
            max-width: 200px;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .asset-table tr:hover td { background: rgba(59,130,246,0.04); }

        /* Sortable headers */
        .asset-table th.sortable { cursor: pointer; user-select: none; }
        .asset-table th.sortable:hover { background: rgba(59,130,246,0.12); }
        .sort-arrow { font-size: 9px; margin-left: 3px; opacity: 0.35; }
        .asset-table th.sort-asc .sort-arrow { opacity: 1; }
        .asset-table th.sort-desc .sort-arrow { opacity: 1; }

        /* Filter row */
        .asset-table .filter-row th { padding: 4px 6px !important; background: var(--chip) !important; border-bottom: 2px solid var(--line) !important; }
        .asset-table .filter-row input {
            width: 100%; box-sizing: border-box;
            background: var(--bg); color: var(--text);
            border: 1px solid var(--line); padding: 4px 6px;
            border-radius: 4px; font-size: 11px;
        }
        .asset-table .filter-row input:focus { border-color: var(--accent, #3b82f6); outline: none; }

        /* Status dot */
        .dot {
            display: inline-block;
            width: 10px; height: 10px;
            border-radius: 50%;
            margin-right: 4px;
            vertical-align: middle;
        }

        .dot-green { background: var(--sm-green); box-shadow: 0 0 6px rgba(16,185,129,0.4); }
        .dot-red { background: var(--sm-red); box-shadow: 0 0 6px rgba(239,68,68,0.3); }
        .dot-amber { background: var(--sm-amber); }


        /* ============================================================
           ENNX IMPORT PANEL
           ============================================================ */
        .ennx-panel {
            display: none;
            border: 1px solid var(--line);
            border-radius: var(--sm-radius);
            background: var(--card);
            margin-bottom: 24px;
            overflow: hidden;
        }

        .ennx-panel.show { display: block; }

        .ennx-panel .panel-header {
            padding: 16px 24px;
            border-bottom: 1px solid var(--line);
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: var(--chip);
        }

        .ennx-panel .panel-header h2 { font-size: 16px; font-weight: 700; }

        .ennx-body {
            padding: 20px 24px;
        }

        .ennx-dropzone {
            border: 2px dashed var(--line);
            border-radius: 10px;
            padding: 40px;
            text-align: center;
            cursor: pointer;
            transition: var(--sm-transition);
            margin-bottom: 16px;
        }

        .ennx-dropzone:hover,
        .ennx-dropzone.dragover {
            border-color: var(--sm-green);
            background: rgba(16,185,129,0.05);
        }

        .ennx-dropzone .drop-icon { font-size: 32px; margin-bottom: 8px; opacity: 0.5; }
        .ennx-dropzone h3 { font-size: 14px; margin-bottom: 4px; }
        .ennx-dropzone p { font-size: 12px; color: var(--muted); }

        .ennx-results { margin-top: 16px; }

        .ennx-stats {
            display: flex;
            gap: 12px;
            margin-bottom: 16px;
        }

        .ennx-stat {
            padding: 12px 16px;
            border-radius: 8px;
            border: 1px solid var(--line);
            background: var(--chip);
            text-align: center;
            flex: 1;
        }

        .ennx-stat .val { font-size: 24px; font-weight: 800; display: block; }
        .ennx-stat .lbl { font-size: 10px; color: var(--muted); text-transform: uppercase; }

        .ennx-stat.green .val { color: var(--sm-green); }
        .ennx-stat.red .val { color: var(--sm-red); }
        .ennx-stat.blue .val { color: var(--sm-blue); }

        /* Loading spinner */
        .spinner {
            display: inline-block;
            width: 16px; height: 16px;
            border: 2px solid var(--sm-spinner-track);
            border-top-color: var(--sm-blue);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin { 100% { transform: rotate(360deg); } }

        .loading-overlay {
            display: none;
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: var(--sm-overlay);
            z-index: 20;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            gap: 12px;
            color: var(--text);
            font-size: 14px;
        }

        .loading-overlay.show { display: flex; }

        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--muted);
            grid-column: 1 / -1;
        }

        .empty-state .empty-icon { font-size: 48px; margin-bottom: 12px; opacity: 0.4; }
        .empty-state h3 { font-size: 16px; color: var(--text); margin-bottom: 6px; }

        /* ============================================================
           STATUS DOTS on map cards
           ============================================================ */
        .card-status-dot {
            width: 14px; height: 14px;
            border-radius: 50%;
            position: absolute;
            top: 14px; right: 14px;
            border: 2px solid var(--sm-dot-border);
            transition: var(--sm-transition);
        }
        .card-status-dot.status-red { background: var(--sm-red); box-shadow: 0 0 8px rgba(239,68,68,0.5); }
        .card-status-dot.status-purple { background: var(--sm-purple); box-shadow: 0 0 8px rgba(139,92,246,0.5); }
        .card-status-dot.status-amber { background: var(--sm-amber); box-shadow: 0 0 8px rgba(245,158,11,0.5); }
        .card-status-dot.status-green { background: var(--sm-green); box-shadow: 0 0 8px rgba(16,185,129,0.5); }
        .card-status-dot.status-grey { background: #6b7280; box-shadow: none; }

        .card-status-label {
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.02em;
            padding: 2px 8px;
            border-radius: 6px;
        }
        .card-status-label.status-red { background: rgba(239,68,68,0.12); color: var(--sm-red); }
        .card-status-label.status-purple { background: rgba(139,92,246,0.12); color: var(--sm-purple); }
        .card-status-label.status-amber { background: rgba(245,158,11,0.12); color: var(--sm-amber); }
        .card-status-label.status-green { background: rgba(16,185,129,0.12); color: var(--sm-green); }
        .card-status-label.status-grey { background: rgba(107,114,128,0.12); color: #9ca3af; }

        .card-progress {
            height: 6px;
            background: var(--sm-hover);
            border-radius: 3px;
            overflow: hidden;
            margin: 8px 0 6px;
        }

        .card-progress-fill {
            height: 100%;
            border-radius: 3px;
            transition: width 0.6s ease-out;
        }

        /* ============================================================
           NOTES EDITOR (modal dialog)
           ============================================================ */
        .note-cell {
            position: relative;
            cursor: pointer;
            min-width: 120px;
        }
        .note-cell:hover {
            background: rgba(59,130,246,0.08) !important;
        }
        .note-cell .note-placeholder {
            color: var(--muted);
            font-style: italic;
            font-size: 11px;
            opacity: 0.5;
        }
        .note-cell .note-text {
            max-width: 180px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            display: inline-block;
        }

        /* Modal backdrop */
        .note-modal-backdrop {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: var(--sm-overlay);
            z-index: 9000;
            align-items: center;
            justify-content: center;
            animation: fadeIn 0.15s ease;
        }
        .note-modal-backdrop.show { display: flex; }

        @keyframes noteSlideIn {
            from { opacity: 0; transform: translateY(-20px) scale(0.95); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }

        /* Modal panel */
        .note-modal {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 14px;
            box-shadow: var(--sm-editor-shadow);
            width: 480px;
            max-width: 90vw;
            max-height: 80vh;
            display: flex;
            flex-direction: column;
            animation: noteSlideIn 0.2s ease;
        }

        .note-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid var(--line);
        }
        .note-modal-header h3 {
            font-size: 15px;
            font-weight: 700;
            color: var(--text);
            margin: 0;
        }
        .note-modal-header .note-asset-name {
            font-size: 12px;
            color: var(--sm-blue);
            font-weight: 600;
            margin-top: 2px;
        }
        .note-modal-header .note-close {
            width: 32px; height: 32px;
            border: none;
            background: var(--sm-hover);
            color: var(--muted);
            border-radius: 8px;
            font-size: 18px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: var(--sm-transition);
        }
        .note-modal-header .note-close:hover {
            background: var(--sm-hover-strong);
            color: var(--text);
        }

        .note-modal-body {
            padding: 16px 20px;
            flex: 1;
        }
        .note-modal-body textarea {
            width: 100%;
            min-height: 140px;
            max-height: 300px;
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: 8px;
            color: var(--text);
            font-family: inherit;
            font-size: 14px;
            padding: 12px 14px;
            resize: vertical;
            line-height: 1.6;
            transition: border-color 0.2s;
        }
        .note-modal-body textarea:focus {
            outline: none;
            border-color: var(--sm-blue);
            box-shadow: 0 0 0 3px rgba(59,130,246,0.1);
        }
        .note-modal-body textarea::placeholder {
            color: var(--muted);
            opacity: 0.6;
        }
        .note-char-count {
            text-align: right;
            font-size: 11px;
            color: var(--muted);
            margin-top: 6px;
        }

        .note-modal-footer {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 10px;
            padding: 12px 20px 16px;
            border-top: 1px solid var(--line);
        }
        .note-modal-footer .note-hint {
            font-size: 11px;
            color: var(--muted);
            margin-right: auto;
        }
        .note-modal-footer .note-cancel {
            background: var(--sm-hover);
            color: var(--text);
            border: 1px solid var(--line);
            border-radius: 8px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            padding: 8px 18px;
            transition: var(--sm-transition);
        }
        .note-modal-footer .note-cancel:hover {
            background: var(--sm-hover-strong);
        }
        .note-modal-footer .note-save {
            background: var(--sm-blue);
            color: #fff;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 700;
            padding: 8px 24px;
            transition: var(--sm-transition);
        }
        .note-modal-footer .note-save:hover {
            opacity: 0.9;
            box-shadow: 0 4px 12px rgba(59,130,246,0.3);
        }
        .note-modal-footer .note-save:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        /* Column Chooser */
        .col-chooser-wrap { position: relative; display: inline-block; }
        .col-chooser-panel {
            display: none;
            position: absolute;
            top: 100%;
            right: 0;
            margin-top: 6px;
            background: var(--card);
            border: 1px solid var(--line);
            padding: 14px 16px;
            border-radius: 10px;
            box-shadow: var(--sm-editor-shadow);
            z-index: 200;
            min-width: 200px;
            max-height: 400px;
            overflow-y: auto;
        }
        .col-chooser-panel .cc-title {
            font-weight: 700;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--muted);
            margin-bottom: 10px;
            padding-bottom: 6px;
            border-bottom: 1px solid var(--line);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .col-chooser-panel .cc-title a {
            font-size: 11px;
            text-transform: none;
            letter-spacing: normal;
            color: var(--sm-blue);
            cursor: pointer;
            text-decoration: none;
        }
        .col-chooser-panel .cc-title a:hover { text-decoration: underline; }
        .col-chooser-panel label {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 6px;
            font-size: 13px;
            cursor: pointer;
            color: var(--text);
            padding: 3px 4px;
            border-radius: 4px;
            transition: background 0.15s;
        }
        .col-chooser-panel label:hover { background: var(--sm-hover); }
        .col-chooser-panel input[type="checkbox"] {
            margin: 0;
            accent-color: var(--sm-blue);
            width: 15px;
            height: 15px;
        }


        /* ============================================================
           VERSION HISTORY PANEL
           ============================================================ */
        .version-panel {
            padding: 12px 24px;
            border-bottom: 1px solid var(--line);
            display: none;
        }
        .version-panel.show { display: block; }
        .version-panel h3 {
            font-size: 13px; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.04em;
            color: var(--muted); margin-bottom: 10px;
        }
        .version-entry {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 8px 12px;
            border-radius: 6px;
            border: 1px solid var(--line);
            background: var(--chip);
            margin-bottom: 6px;
            font-size: 12px;
        }
        .version-entry .v-date {
            color: var(--sm-blue);
            font-weight: 600;
            white-space: nowrap;
            min-width: 130px;
        }
        .version-entry .v-action {
            flex: 1;
            color: var(--muted);
        }
        .version-entry .v-user {
            color: var(--sm-purple);
            font-weight: 600;
        }

        /* Active state for detail filter buttons */
        .detail-actions .btn.filter-active {
            box-shadow: 0 0 0 2px rgba(59,130,246,0.3);
            transform: translateY(-1px);
        }
    </style>
</head>
<body>

    <!-- ====================== SIDEBAR ====================== -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <div class="logo-icon">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"></polygon>
                        <line x1="8" y1="2" x2="8" y2="18"></line>
                        <line x1="16" y1="6" x2="16" y2="22"></line>
                    </svg>
                </div>
                Site Maps
            </div>
            <p>Tagging progress dashboard. Select a site, view maps, track what's tagged and what's remaining.</p>
        </div>

        <!-- Site Selector -->
        <div class="site-selector">
            <label>Select Site</label>
            <select id="ddlSite" onchange="onSiteChange()">
                <option value="0">-- All Sites --</option>
            </select>
        </div>

        <!-- KPI Bar -->
        <div class="kpi-bar">
            <div class="kpi-chip green">
                <span class="kpi-val" id="kpiTagged">—</span>
                <span class="kpi-label">Tagged</span>
            </div>
            <div class="kpi-chip red">
                <span class="kpi-val" id="kpiRemaining">—</span>
                <span class="kpi-label">Remaining</span>
            </div>
            <div class="kpi-chip blue">
                <span class="kpi-val" id="kpiPct">—</span>
                <span class="kpi-label">Complete</span>
            </div>
        </div>

        <!-- View Toggle (filters map cards by completion status) -->
        <div class="view-toggle">
            <label>Map Status</label>
            <div class="toggle-group">
                <button class="toggle-btn active" data-view="all" onclick="setView('all', this)">All</button>
                <button class="toggle-btn" data-view="done" onclick="setView('done', this)">Done</button>
                <button class="toggle-btn" data-view="pending" onclick="setView('pending', this)">Pending</button>
            </div>
        </div>

        <!-- Directory List -->
        <div class="dir-list" id="dirList"></div>

        <!-- Actions -->
        <div class="sidebar-actions">
            <button class="s-btn primary" onclick="toggleEnnxPanel()">Import ENNX Report</button>
            <a class="s-btn" href="va_tag_stats.aspx" target="_blank">Tag Statistics</a>
            <a class="s-btn" href="va_tag_audit_report.aspx" target="_blank">Tag Audit Report</a>
            <a class="s-btn" href="documentation/va_site_maps.html" target="_blank" style="color:var(--sm-purple);">&#128214; How-To Guide</a>
        </div>
    </aside>

    <!-- ====================== MAIN ====================== -->
    <main class="main" style="position:relative;">

        <div class="loading-overlay" id="loadingOverlay">
            <div class="spinner" style="width:32px;height:32px;border-width:3px;"></div>
            <span>Loading site data...</span>
        </div>

        <div class="main-header">
            <h1 id="mainTitle">Site Maps</h1>
            <div class="progress-bar-wrap" id="progressBarWrap" style="display:none;">
                <div class="progress-track">
                    <div class="progress-fill" id="progressFill" style="width:0%"></div>
                </div>
                <div class="progress-label" id="progressLabel">0% Complete</div>
            </div>
            <div class="main-header-actions">
                <button class="btn btn-green" onclick="exportCsv('tagged')">Export Tagged</button>
                <button class="btn" style="color:var(--sm-red);" onclick="exportCsv('remaining')">Export Remaining</button>
                <button class="btn btn-blue" onclick="exportCsv('all')">Export All</button>
                <a href="index.aspx" class="nav-pill nav-pill-ghost" style="text-decoration:none; padding:7px 18px; border-radius:999px; border:1.5px solid var(--line); color:var(--muted); font-size:14px; font-weight:500; transition:all 0.2s;">&#8962; Hub</a>
            </div>
        </div>

        <div class="content-scroll" id="contentScroll">

            <!-- ENNX Import Panel -->
            <div class="ennx-panel" id="ennxPanel">
                <div class="panel-header">
                    <h2>ENNX Report Import</h2>
                    <button class="detail-close" onclick="toggleEnnxPanel()">&times;</button>
                </div>
                <div class="ennx-body">
                    <div class="ennx-dropzone" id="ennxDropzone"
                         ondragover="event.preventDefault(); this.classList.add('dragover');"
                         ondragleave="this.classList.remove('dragover');"
                         ondrop="handleEnnxDrop(event);">
                        <div class="drop-icon">&#128196;</div>
                        <h3>Drop ENNX file here or click to browse</h3>
                        <p>.ennx.txt or any text file with RFID tags / asset identifiers</p>
                        <input type="file" id="ennxFileInput" style="display:none" accept=".txt,.ennx,.csv"
                               onchange="handleEnnxFile(this.files[0])">
                    </div>
                    <div class="ennx-results" id="ennxResults" style="display:none;">
                        <div class="ennx-stats" id="ennxStats"></div>
                        <div class="asset-table-wrap" style="max-height:300px;">
                            <table class="asset-table" id="ennxTable">
                                <thead><tr><th>Asset Name</th><th>RFID</th><th>Status</th><th>Location</th></tr></thead>
                                <tbody id="ennxTableBody"></tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Detail Panel (map viewer + asset table) -->
            <div class="detail-panel" id="detailPanel">
                <div class="detail-header">
                    <h2 id="detailTitle">Map Detail</h2>
                    <button class="detail-close" onclick="closeDetail()">&times;</button>
                </div>
                <div class="detail-viewer" id="detailViewer"></div>
                <div class="detail-actions">
                    <button class="btn btn-green" id="btnFilterTagged" onclick="loadDetailAssets('tagged')">
                        <span class="dot dot-green"></span> Show Tagged
                    </button>
                    <button class="btn" id="btnFilterRemaining" style="color:var(--sm-red);" onclick="loadDetailAssets('remaining')">
                        <span class="dot dot-red"></span> Show Remaining
                    </button>
                    <button class="btn btn-blue" id="btnFilterAll" onclick="loadDetailAssets('all')">Show All</button>
                    <a class="btn" id="detailOpenLink" href="#" target="_blank">Open Map File</a>
                    <button class="btn" onclick="toggleVersionPanel()" style="color:var(--sm-purple);">&#128337; History</button>
                    <button class="btn" id="detailMarkDone" onclick="toggleMapComplete()" style="margin-left:8px;">Mark Complete</button>
                    <div class="col-chooser-wrap" style="margin-left:8px;">
                        <button class="btn" id="btnColumns" onclick="toggleColumnChooser(event)">&#9776; Columns</button>
                        <div class="col-chooser-panel" id="colChooser">
                            <div class="cc-title">Toggle Columns <a onclick="resetColumns()">Reset</a></div>
                            <div id="colChooserList"></div>
                        </div>
                    </div>
                    <span style="margin-left:auto; font-size:12px; color:var(--muted);" id="detailAssetCount"></span>
                </div>

                <!-- Location Summary Grid -->
                <div id="locationSummary" style="padding:16px 24px; border-bottom:1px solid var(--line); display:none;">
                    <h3 style="font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:0.04em; color:var(--muted); margin-bottom:12px;">
                        Location Breakdown
                    </h3>
                    <div id="locationSummaryGrid" style="display:grid; grid-template-columns:repeat(auto-fill, minmax(220px, 1fr)); gap:10px; max-height:300px; overflow-y:auto;"></div>
                </div>

                <!-- Version History Panel -->
                <div class="version-panel" id="versionPanel">
                    <h3>Version History</h3>
                    <div id="versionList"></div>
                </div>

                <div class="asset-table-wrap">
                    <table class="asset-table" id="detailTable">
                        <thead>
                            <tr>
                                <th>Status</th>
                                <th>Asset Tag</th>
                                <th>Description</th>
                                <th>Manufacturer</th>
                                <th>Model</th>
                                <th>Serial #</th>
                                <th>Location</th>
                                <th>Use Status</th>
                                <th>Tag Type</th>
                                <th>Tagged Date</th>
                                <th>Employee</th>
                                <th>CMR</th>
                                <th>Notes</th>
                            </tr>
                        </thead>
                        <tbody id="detailTableBody"></tbody>
                    </table>
                </div>
            </div>

            <!-- Map Cards Grid -->
            <div class="maps-grid" id="mapsGrid"></div>

        </div>
    </main>

    <script>
        // ================================================================
        //  DATA FROM SERVER
        // ================================================================
        const mapsData = <%= MapsJson %>;
        const companiesData = <%= CompaniesJson %>;

        // ================================================================
        //  STATE
        // ================================================================
        let currentSiteId = '0';
        let currentView = 'all';     // 'all', 'done', 'pending'
        let currentDir = 'All';
        let siteStats = null;
        let locationStats = [];
        let buildingStats = {};      // { "500": { total, tagged, remaining }, ... }
        let selectedMapPath = null;
        let selectedMapObj = null;   // The full map object for the open detail
        let completedMaps = JSON.parse(localStorage.getItem('idash_map_progress') || '[]');
        let currentDetailFilter = 'all';

        // ================================================================
        //  INIT
        // ================================================================
        document.addEventListener('DOMContentLoaded', function() {
            populateSiteDropdown();
            renderDirectories();
            renderMaps();
        });

        // ================================================================
        //  SITE DROPDOWN
        // ================================================================
        function populateSiteDropdown() {
            const ddl = document.getElementById('ddlSite');
            companiesData.forEach(function(c) {
                var opt = document.createElement('option');
                opt.value = c.id;
                opt.textContent = c.name;
                // Pre-select 613 Martinsburg if available
                if (c.station === '613') {
                    opt.selected = true;
                    currentSiteId = c.id.toString();
                }
                ddl.appendChild(opt);
            });

            // Auto-load if a site is pre-selected
            if (currentSiteId !== '0') {
                loadSiteData();
            }
        }

        function onSiteChange() {
            currentSiteId = document.getElementById('ddlSite').value;
            closeDetail();
            loadSiteData();
        }

        // ================================================================
        //  LOAD SITE DATA (stats + location breakdown + building stats)
        // ================================================================
        function loadSiteData() {
            if (currentSiteId === '0') {
                siteStats = null;
                locationStats = [];
                buildingStats = {};
                updateKPIs();
                renderMaps();
                return;
            }

            showLoading(true);

            Promise.all([
                fetch('va_site_maps.aspx?api=sitestats&site=' + currentSiteId).then(r => r.json()),
                fetch('va_site_maps.aspx?api=locationstats&site=' + currentSiteId).then(r => r.json()),
                fetch('va_site_maps.aspx?api=buildingstats&site=' + currentSiteId).then(r => r.json())
            ])
            .then(function(results) {
                siteStats = results[0];
                locationStats = results[1];
                // Index building stats by building number
                buildingStats = {};
                results[2].forEach(function(bs) {
                    buildingStats[bs.building] = bs;
                });
                updateKPIs();
                renderMaps();
                showLoading(false);
            })
            .catch(function(err) {
                console.error('Failed to load site data:', err);
                showLoading(false);
            });
        }

        function showLoading(show) {
            document.getElementById('loadingOverlay').classList.toggle('show', show);
        }

        // ================================================================
        //  UPDATE KPIs
        // ================================================================
        function updateKPIs() {
            var tagged = siteStats ? siteStats.tagged : 0;
            var remaining = siteStats ? siteStats.remaining : 0;
            var total = siteStats ? siteStats.total : 0;
            var pct = total > 0 ? Math.round((tagged / total) * 100) : 0;

            document.getElementById('kpiTagged').textContent = tagged.toLocaleString();
            document.getElementById('kpiRemaining').textContent = remaining.toLocaleString();
            document.getElementById('kpiPct').textContent = pct + '%';

            // Progress bar
            var wrap = document.getElementById('progressBarWrap');
            wrap.style.display = siteStats ? 'block' : 'none';
            document.getElementById('progressFill').style.width = pct + '%';
            document.getElementById('progressLabel').textContent =
                pct + '% Complete (' + tagged.toLocaleString() + ' / ' + total.toLocaleString() + ')';

            // Main title
            var ddl = document.getElementById('ddlSite');
            var siteName = ddl.options[ddl.selectedIndex].text;
            document.getElementById('mainTitle').textContent =
                currentSiteId === '0' ? 'Site Maps' : siteName;
        }

        // ================================================================
        //  VIEW TOGGLE (filters map cards by Done/Pending completion)
        // ================================================================
        function setView(view, btn) {
            currentView = view;
            document.querySelectorAll('.toggle-btn').forEach(function(b) {
                b.classList.remove('active', 'green-active', 'red-active');
            });
            btn.classList.add('active');
            if (view === 'done') btn.classList.add('green-active');
            if (view === 'pending') btn.classList.add('red-active');
            renderMaps();
        }

        // ================================================================
        //  DIRECTORIES
        // ================================================================
        function getDirectories() {
            var siteMapDirs = getFilteredMaps().map(function(m) { return m.Dir; });
            var dirs = new Set(siteMapDirs.filter(function(d) { return d && d !== 'Root'; }));
            return ['All'].concat(Array.from(dirs).sort());
        }

        function getFilteredMaps() {
            // Filter maps to show only those matching the current site's folder structure
            if (currentSiteId === '0') return mapsData;

            var ddl = document.getElementById('ddlSite');
            var siteName = ddl.options[ddl.selectedIndex].text;
            // Extract station number (first 3 chars of company name)
            var station = siteName.substring(0, 3).trim();

            return mapsData.filter(function(m) {
                // Match maps whose directory path contains the station number
                return m.Dir.indexOf(station) > -1 || m.Path.indexOf(station) > -1;
            });
        }

        function renderDirectories() {
            var dirs = getDirectories();
            var dirList = document.getElementById('dirList');
            dirList.innerHTML = '';

            dirs.forEach(function(dir) {
                var maps = dir === 'All'
                    ? getFilteredMaps()
                    : getFilteredMaps().filter(function(m) { return m.Dir === dir; });

                var item = document.createElement('div');
                item.className = 'dir-item' + (dir === currentDir ? ' active' : '');

                var icon = dir === 'All'
                    ? '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M4 6h16v12H4z" opacity=".3"/><path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2z"/></svg>'
                    : '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M10 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z"/></svg>';

                item.innerHTML =
                    icon +
                    '<span style="flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">' + dir + '</span>' +
                    '<span class="dir-badge">' + maps.length + '</span>';

                item.onclick = function() {
                    currentDir = dir;
                    renderDirectories();
                    renderMaps();
                };

                dirList.appendChild(item);
            });
        }

        // ================================================================
        //  BUILDING STATUS HELPERS
        // ================================================================
        function getBuildingStatus(building) {
            // Returns { pct, statusClass, statusLabel } for a building number
            var bs = buildingStats[building];
            if (!bs || bs.total === 0) return { pct: -1, statusClass: 'status-grey', statusLabel: 'No Data' };

            var pct = Math.round((bs.tagged / bs.total) * 100);
            if (pct === 0) return { pct: 0, statusClass: 'status-red', statusLabel: '0%' };
            if (pct < 50) return { pct: pct, statusClass: 'status-purple', statusLabel: pct + '%' };
            if (pct < 90) return { pct: pct, statusClass: 'status-amber', statusLabel: pct + '%' };
            return { pct: pct, statusClass: 'status-green', statusLabel: pct + '%' };
        }

        // ================================================================
        //  RENDER MAP CARDS (with status dots)
        // ================================================================
        function renderMaps() {
            renderDirectories();
            var grid = document.getElementById('mapsGrid');
            grid.innerHTML = '';

            // BUG FIX: was referencing undefined 'dir' — use only currentDir
            var maps = currentDir === 'All'
                ? getFilteredMaps()
                : getFilteredMaps().filter(function(m) { return m.Dir === currentDir; });

            // Apply Done/Pending filter
            if (currentView === 'done') {
                maps = maps.filter(function(m) { return completedMaps.includes(m.Path); });
            } else if (currentView === 'pending') {
                maps = maps.filter(function(m) { return !completedMaps.includes(m.Path); });
            }

            if (maps.length === 0) {
                grid.innerHTML =
                    '<div class="empty-state">' +
                    '<div class="empty-icon">&#128506;</div>' +
                    '<h3>No maps found</h3>' +
                    '<p>No map files match the current filters.</p>' +
                    '</div>';
                return;
            }

            maps.forEach(function(map) {
                var card = createMapCard(map);
                grid.appendChild(card);
            });
        }

        function createMapCard(map) {
            var card = document.createElement('div');
            card.className = 'map-card' + (selectedMapPath === map.Path ? ' selected' : '');

            var isPdf = map.Ext.indexOf('pdf') > -1;
            var isPng = map.Ext.indexOf('png') > -1;
            var formatText = map.Ext.replace('.', '').toUpperCase();
            var formatClass = isPdf ? 'pdf' : (isPng ? 'png' : 'jpg');

            var isCompleted = completedMaps.includes(map.Path);

            // Clean display name: remove extension
            var displayName = map.Name.replace(/\.[^/.]+$/, '');

            // Building status dot
            var bldg = map.Building || '';
            var bStatus = getBuildingStatus(bldg);
            var statusDotHtml = bldg
                ? '<div class="card-status-dot ' + bStatus.statusClass + '" title="Building ' + escHtml(bldg) + ': ' + bStatus.statusLabel + ' tagged"></div>'
                : '';

            var statusLabelHtml = bldg && bStatus.pct >= 0
                ? '<span class="card-status-label ' + bStatus.statusClass + '">' + bStatus.statusLabel + '</span>'
                : '';

            // Progress bar for building
            var progressHtml = '';
            if (bldg && bStatus.pct >= 0) {
                var fillColor = bStatus.statusClass.replace('status-', '');
                progressHtml =
                    '<div class="card-progress">' +
                    '<div class="card-progress-fill" style="width:' + bStatus.pct + '%; background:var(--sm-' + fillColor + ');"></div>' +
                    '</div>';
            }

            card.innerHTML =
                statusDotHtml +
                '<div class="card-top">' +
                '  <div class="format-icon ' + formatClass + '">' + formatText.substring(0, 3) + '</div>' +
                '  <div style="display:flex;align-items:center;gap:6px;">' +
                statusLabelHtml +
                (isCompleted ? '<span class="badge badge-green" style="font-size:10px;">Done</span>' : '') +
                '  </div>' +
                '</div>' +
                '<div class="card-title" title="' + escHtml(map.Name) + '">' + escHtml(displayName) + '</div>' +
                progressHtml +
                '<div class="card-footer">' +
                '  <span style="font-size:11px;color:var(--muted);">' + escHtml(map.Dir.split('/').pop()) + '</span>' +
                '  <span class="view-link">View Details &rarr;</span>' +
                '</div>';

            card.onclick = function() { openDetail(map); };

            return card;
        }


        // ================================================================
        //  DETAIL PANEL
        // ================================================================
        function openDetail(map) {
            selectedMapPath = map.Path;
            selectedMapObj = map;
            renderMaps(); // re-render to show selected state

            var panel = document.getElementById('detailPanel');
            var viewer = document.getElementById('detailViewer');
            var title = document.getElementById('detailTitle');
            var link = document.getElementById('detailOpenLink');

            // Show building info in title
            var bldg = map.Building || '';
            var bStatus = getBuildingStatus(bldg);
            var titleText = map.Name.replace(/\.[^/.]+$/, '');
            if (bldg && buildingStats[bldg]) {
                var bs = buildingStats[bldg];
                titleText += ' \u2014 Bldg ' + bldg + ' (' + bs.tagged.toLocaleString() + ' / ' + bs.total.toLocaleString() + ' tagged)';
            }
            title.textContent = titleText;
            link.href = 'site_maps/' + map.Path;

            // Update Mark Complete button
            updateMarkCompleteBtn();

            var isPdf = map.Ext.indexOf('pdf') > -1;
            if (isPdf) {
                viewer.innerHTML = '<iframe src="site_maps/' + encodeURI(map.Path) + '"></iframe>';
            } else {
                viewer.innerHTML = '<img src="site_maps/' + encodeURI(map.Path) + '" alt="' + escHtml(map.Name) + '">';
            }

            panel.classList.add('show');
            panel.scrollIntoView({ behavior: 'smooth', block: 'start' });

            // Hide version panel on new open
            document.getElementById('versionPanel').classList.remove('show');

            // Render building-scoped location summary
            renderLocationSummary(bldg);

            // Load assets scoped to this building
            loadDetailAssets('all');

            // Init column chooser (applies saved hidden columns)
            smColChooserBuilt = false;
            document.getElementById('colChooser').style.display = 'none';
            initColumnChooser();
        }

        function updateMarkCompleteBtn() {
            var btn = document.getElementById('detailMarkDone');
            var isDone = completedMaps.includes(selectedMapPath);
            btn.textContent = isDone ? '\u2713 Completed' : 'Mark Complete';
            btn.style.color = isDone ? 'var(--sm-green)' : '';
            btn.style.borderColor = isDone ? 'rgba(16,185,129,0.3)' : '';
            btn.style.background = isDone ? 'rgba(16,185,129,0.1)' : '';
        }

        function toggleMapComplete() {
            if (!selectedMapPath) return;
            var idx = completedMaps.indexOf(selectedMapPath);
            if (idx > -1) {
                completedMaps.splice(idx, 1);
            } else {
                completedMaps.push(selectedMapPath);
            }
            localStorage.setItem('idash_map_progress', JSON.stringify(completedMaps));
            updateMarkCompleteBtn();
            renderMaps();
        }

        // BUG FIX: Filter location summary by building number
        function renderLocationSummary(building) {
            var container = document.getElementById('locationSummary');
            var grid = document.getElementById('locationSummaryGrid');

            if (!locationStats || locationStats.length === 0) {
                container.style.display = 'none';
                return;
            }

            // Filter locations to the selected building
            var filtered = locationStats;
            if (building) {
                filtered = locationStats.filter(function(ls) {
                    // Location names are like "SP4C141-500" where 500 is the building
                    // text6 stored as SP{area}{room}-{building}
                    var loc = ls.location || '';
                    // Check if location ends with -Building pattern
                    var dashIdx = loc.lastIndexOf('-');
                    if (dashIdx > -1) {
                        var suffix = loc.substring(dashIdx + 1);
                        return suffix === building;
                    }
                    return loc.indexOf(building) > -1;
                });
            }

            if (filtered.length === 0) {
                container.style.display = 'none';
                return;
            }

            container.style.display = 'block';
            grid.innerHTML = '';

            // Update heading with building info
            var heading = container.querySelector('h3');
            if (heading) {
                heading.textContent = building
                    ? 'Location Breakdown \u2014 Building ' + building + ' (' + filtered.length + ' rooms)'
                    : 'Location Breakdown (' + filtered.length + ' locations)';
            }

            // Sort by total descending
            var sorted = filtered.slice().sort(function(a, b) { return b.total - a.total; });

            // Show top 50 locations
            sorted.slice(0, 50).forEach(function(ls) {
                var pct = ls.total > 0 ? Math.round((ls.tagged / ls.total) * 100) : 0;
                var pctColor = pct >= 80 ? 'var(--sm-green)' : (pct >= 40 ? 'var(--sm-amber)' : 'var(--sm-red)');

                var card = document.createElement('div');
                card.style.cssText = 'padding:10px 12px; border:1px solid var(--line); border-radius:8px; background:var(--chip); cursor:pointer;';
                card.innerHTML =
                    '<div style="font-size:12px; font-weight:600; margin-bottom:6px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;" title="' + escHtml(ls.location) + '">' + escHtml(ls.location) + '</div>' +
                    '<div style="display:flex; justify-content:space-between; font-size:11px; margin-bottom:4px;">' +
                    '  <span><span class="dot dot-green"></span>' + ls.tagged + '</span>' +
                    '  <span><span class="dot dot-red"></span>' + ls.remaining + '</span>' +
                    '  <span style="color:' + pctColor + '; font-weight:700;">' + pct + '%</span>' +
                    '</div>' +
                    '<div style="height:4px; background:var(--sm-hover); border-radius:2px; overflow:hidden;">' +
                    '  <div style="height:100%; width:' + pct + '%; background:' + pctColor + '; border-radius:2px;"></div>' +
                    '</div>';

                card.onclick = function(e) {
                    e.stopPropagation();
                    // Load assets for this specific location
                    loadDetailAssetsForLocation(ls.location);
                };

                grid.appendChild(card);
            });
        }

        function loadDetailAssetsForLocation(locName) {
            var url = 'va_site_maps.aspx?api=assets&site=' + currentSiteId +
                      '&location=' + encodeURIComponent(locName) + '&filter=all';
            document.getElementById('detailAssetCount').textContent = 'Loading ' + locName + '...';
            fetch(url)
            .then(function(r) { return r.json(); })
            .then(function(assets) {
                renderDetailTable(assets);
                document.getElementById('detailAssetCount').textContent =
                    assets.length + ' assets in ' + locName;
            });
        }

        function closeDetail() {
            selectedMapPath = null;
            selectedMapObj = null;
            document.getElementById('detailPanel').classList.remove('show');
            document.getElementById('detailTableBody').innerHTML = '';
            document.getElementById('versionPanel').classList.remove('show');
            renderMaps();
        }

        // BUG FIX: Scope to building + add active button states
        function loadDetailAssets(filter) {
            if (!selectedMapPath || currentSiteId === '0') return;

            currentDetailFilter = filter;

            // Update active button states
            ['btnFilterTagged', 'btnFilterRemaining', 'btnFilterAll'].forEach(function(id) {
                document.getElementById(id).classList.remove('filter-active');
            });
            if (filter === 'tagged') document.getElementById('btnFilterTagged').classList.add('filter-active');
            else if (filter === 'remaining') document.getElementById('btnFilterRemaining').classList.add('filter-active');
            else document.getElementById('btnFilterAll').classList.add('filter-active');

            // BUG FIX: Scope query to building using location wildcard
            var building = selectedMapObj ? (selectedMapObj.Building || '') : '';
            var locQuery = building ? '%-' + building : 'all';

            var url = 'va_site_maps.aspx?api=assets&site=' + currentSiteId +
                      '&location=' + encodeURIComponent(locQuery) + '&filter=' + filter;

            document.getElementById('detailAssetCount').textContent = 'Loading...';

            fetch(url)
            .then(function(r) { return r.json(); })
            .then(function(assets) {
                renderDetailTable(assets);
                var label = building ? ' in Bldg ' + building : '';
                document.getElementById('detailAssetCount').textContent =
                    assets.length + ' assets' + label +
                    (assets.length >= 500 ? ' (limited to 500)' : '');
            })
            .catch(function(err) {
                document.getElementById('detailAssetCount').textContent = 'Error loading assets';
                console.error(err);
            });
        }

        // Enhanced detail table with Notes column
        function renderDetailTable(assets) {
            var tbody = document.getElementById('detailTableBody');
            tbody.innerHTML = '';

            assets.forEach(function(a) {
                var isTagged = a.tagged === '1' || a.tagged === 'true';
                var dotClass = isTagged ? 'dot-green' : 'dot-red';
                var statusText = isTagged ? 'Tagged' : 'Not Tagged';

                var tr = document.createElement('tr');
                tr.innerHTML =
                    '<td><span class="dot ' + dotClass + '"></span>' + statusText + '</td>' +
                    '<td title="' + escHtml(a.tag) + '">' + escHtml(a.tag) + '</td>' +
                    '<td title="' + escHtml(a.desc) + '">' + escHtml(a.desc) + '</td>' +
                    '<td>' + escHtml(a.mfg) + '</td>' +
                    '<td>' + escHtml(a.model) + '</td>' +
                    '<td>' + escHtml(a.serial) + '</td>' +
                    '<td title="' + escHtml(a.locName) + '">' + escHtml(a.locName) + '</td>' +
                    '<td>' + escHtml(a.status) + '</td>' +
                    '<td>' + escHtml(a.tagType) + '</td>' +
                    '<td>' + escHtml(a.tagDate) + '</td>' +
                    '<td>' + escHtml(a.emplId) + '</td>' +
                    '<td>' + escHtml(a.cmr) + '</td>' +
                    '<td class="note-cell" onclick="openNoteEditor(this, \'' + escHtml(a.tag).replace(/'/g, "\\'") + '\')" title="Click to edit note">' +
                    (a.notes ? '<span class="note-text" title="' + escHtml(a.notes) + '">' + escHtml(a.notes) + '</span>' : '<span class="note-placeholder">+ note</span>') +
                    '</td>';
                // Store the current note value as data attribute
                tr.querySelector('.note-cell').setAttribute('data-note', a.notes || '');
                tr.querySelector('.note-cell').setAttribute('data-asset', a.tag);
                tbody.appendChild(tr);
            });

            // Wire up sort & filter after populating rows
            initDetailTableSortFilter();
        }

        // ================================================================
        //  COLUMN SORT & FILTER (matches iDash standard pattern)
        // ================================================================
        var smSortDir = {};

        function initDetailTableSortFilter() {
            var table = document.getElementById('detailTable');
            if (!table) return;
            var thead = table.querySelector('thead');
            if (!thead) return;

            // Remove any existing filter row from previous render
            var oldFilter = thead.querySelector('.filter-row');
            if (oldFilter) oldFilter.remove();

            // Get the header row (first row in thead)
            var headerRow = thead.rows[0];
            if (!headerRow) return;

            var ths = headerRow.querySelectorAll('th');

            // Add sort arrows + click handlers to each header
            ths.forEach(function(th, index) {
                // Skip Notes column (it has click handler for editing)
                if (th.textContent.trim() === 'Notes') return;

                th.classList.add('sortable');

                // Only add arrows if not already present
                if (!th.querySelector('.sort-arrow')) {
                    th.innerHTML = th.innerHTML + ' <span class="sort-arrow">&#9650;&#9660;</span>';
                }

                th.onclick = function() { sortDetailTable(index); };
            });

            // Build filter row
            var filterRow = document.createElement('tr');
            filterRow.className = 'filter-row';

            ths.forEach(function(th, index) {
                var filterTh = document.createElement('th');
                var inp = document.createElement('input');
                inp.type = 'text';
                inp.placeholder = '...';
                inp.setAttribute('data-col', index);
                inp.onkeyup = function() { filterDetailTable(); };
                filterTh.appendChild(inp);
                filterRow.appendChild(filterTh);
            });

            thead.appendChild(filterRow);
        }

        function sortDetailTable(colIndex) {
            var table = document.getElementById('detailTable');
            var tbody = table.querySelector('tbody');
            if (!tbody || tbody.rows.length === 0) return;

            var dirKey = 'detail-' + colIndex;
            var dir = smSortDir[dirKey] === 'asc' ? 'desc' : 'asc';
            smSortDir[dirKey] = dir;

            // Update header classes for visual feedback
            var ths = table.querySelector('thead').rows[0].querySelectorAll('th');
            ths.forEach(function(th) { th.classList.remove('sort-asc', 'sort-desc'); });
            if (ths[colIndex]) ths[colIndex].classList.add('sort-' + dir);

            var rows = Array.from(tbody.querySelectorAll('tr'));

            rows.sort(function(a, b) {
                var textA = a.cells[colIndex] ? a.cells[colIndex].innerText.trim() : '';
                var textB = b.cells[colIndex] ? b.cells[colIndex].innerText.trim() : '';

                // Try numeric sort first
                var numA = parseFloat(textA.replace(/[^0-9.\-]/g, ''));
                var numB = parseFloat(textB.replace(/[^0-9.\-]/g, ''));

                if (!isNaN(numA) && !isNaN(numB) && textA.match(/\d/) && textB.match(/\d/)) {
                    return dir === 'asc' ? numA - numB : numB - numA;
                }

                // Date sort (yyyy-mm-dd or mm/dd/yyyy patterns)
                var dateA = Date.parse(textA);
                var dateB = Date.parse(textB);
                if (!isNaN(dateA) && !isNaN(dateB)) {
                    return dir === 'asc' ? dateA - dateB : dateB - dateA;
                }

                // Text sort (empty values go to bottom)
                if (!textA && textB) return 1;
                if (textA && !textB) return -1;
                return dir === 'asc' ? textA.localeCompare(textB) : textB.localeCompare(textA);
            });

            tbody.innerHTML = '';
            rows.forEach(function(r) { tbody.appendChild(r); });
        }

        function filterDetailTable() {
            var table = document.getElementById('detailTable');
            var tbody = table.querySelector('tbody');
            if (!tbody) return;

            var inputs = Array.from(table.querySelectorAll('.filter-row input'));
            var rows = tbody.querySelectorAll('tr');

            rows.forEach(function(row) {
                var show = true;
                inputs.forEach(function(input) {
                    var val = input.value.toLowerCase();
                    if (!val) return;
                    var colIndex = parseInt(input.getAttribute('data-col'), 10);
                    var cellText = row.cells[colIndex] ? row.cells[colIndex].innerText.toLowerCase() : '';
                    if (cellText.indexOf(val) === -1) show = false;
                });
                row.style.display = show ? '' : 'none';
            });
        }

        // ================================================================
        //  NOTES EDITOR (Modal Dialog)
        // ================================================================
        var noteModalCell = null;
        var noteModalAsset = '';

        function openNoteEditor(cell, assetName) {
            noteModalCell = cell;
            noteModalAsset = assetName;

            var currentNote = cell.getAttribute('data-note') || '';

            // Populate modal
            document.getElementById('noteModalAssetName').textContent = assetName;
            var textarea = document.getElementById('noteModalTextarea');
            textarea.value = currentNote;
            document.getElementById('noteCharCount').textContent = currentNote.length;

            // Reset save button
            var saveBtn = document.getElementById('noteModalSaveBtn');
            saveBtn.textContent = 'Save Note';
            saveBtn.disabled = false;

            // Show modal
            document.getElementById('noteModalBackdrop').classList.add('show');

            // Focus textarea at end
            setTimeout(function() {
                textarea.focus();
                textarea.setSelectionRange(textarea.value.length, textarea.value.length);
            }, 50);
        }

        function closeNoteModal() {
            document.getElementById('noteModalBackdrop').classList.remove('show');
            noteModalCell = null;
            noteModalAsset = '';
        }

        function saveNoteFromModal() {
            if (!noteModalCell || !noteModalAsset) return;

            var textarea = document.getElementById('noteModalTextarea');
            var newNote = textarea.value.trim();
            var saveBtn = document.getElementById('noteModalSaveBtn');
            saveBtn.textContent = 'Saving...';
            saveBtn.disabled = true;

            var formData = new FormData();
            formData.append('save_note', '1');
            formData.append('asset_name', noteModalAsset);
            formData.append('note_text', newNote);
            formData.append('site_id', currentSiteId);

            var cell = noteModalCell;

            fetch('va_site_maps.aspx', { method: 'POST', body: formData })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.success) {
                    cell.setAttribute('data-note', newNote);
                    cell.innerHTML = newNote
                        ? '<span class="note-text" title="' + escHtml(newNote) + '">' + escHtml(newNote) + '</span>'
                        : '<span class="note-placeholder">+ note</span>';
                    closeNoteModal();
                } else {
                    saveBtn.textContent = 'Save Note';
                    saveBtn.disabled = false;
                    alert('Save failed: ' + (data.error || 'Unknown error'));
                }
            })
            .catch(function(err) {
                saveBtn.textContent = 'Save Note';
                saveBtn.disabled = false;
                alert('Save error: ' + err);
            });
        }

        // Character count + keyboard shortcuts for note modal
        document.addEventListener('DOMContentLoaded', function() {
            var textarea = document.getElementById('noteModalTextarea');
            if (textarea) {
                textarea.addEventListener('input', function() {
                    document.getElementById('noteCharCount').textContent = this.value.length;
                });
                textarea.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && e.ctrlKey) {
                        e.preventDefault();
                        saveNoteFromModal();
                    }
                    if (e.key === 'Escape') {
                        closeNoteModal();
                    }
                });
            }
        });


        // ================================================================
        //  VERSION HISTORY
        // ================================================================
        function toggleVersionPanel() {
            var panel = document.getElementById('versionPanel');
            panel.classList.toggle('show');

            if (panel.classList.contains('show') && selectedMapPath) {
                loadVersionHistory();
            }
        }

        function loadVersionHistory() {
            var list = document.getElementById('versionList');
            list.innerHTML = '<div style="color:var(--muted);font-size:12px;">Loading history...</div>';

            fetch('va_site_maps.aspx?api=versionhistory&map=' + encodeURIComponent(selectedMapPath))
            .then(function(r) { return r.json(); })
            .then(function(entries) {
                list.innerHTML = '';
                if (entries.length === 0) {
                    list.innerHTML = '<div style="color:var(--muted);font-size:12px;padding:8px 0;">No version history recorded for this map. History tracking starts when maps are uploaded through the UI.</div>';
                    return;
                }
                // Show newest first
                entries.reverse().forEach(function(entry) {
                    var div = document.createElement('div');
                    div.className = 'version-entry';
                    div.innerHTML =
                        '<span class="v-date">' + escHtml(entry.date) + '</span>' +
                        '<span class="v-action">' + escHtml(entry.action) + '</span>' +
                        '<span class="v-user">' + escHtml(entry.user) + '</span>';
                    list.appendChild(div);
                });
            })
            .catch(function(err) {
                list.innerHTML = '<div style="color:var(--sm-red);font-size:12px;">Error loading history: ' + escHtml(err.toString()) + '</div>';
            });
        }


        // ================================================================
        //  ENNX IMPORT
        // ================================================================
        function toggleEnnxPanel() {
            document.getElementById('ennxPanel').classList.toggle('show');
        }

        document.getElementById('ennxDropzone').addEventListener('click', function() {
            document.getElementById('ennxFileInput').click();
        });

        function handleEnnxDrop(e) {
            e.preventDefault();
            e.target.closest('.ennx-dropzone').classList.remove('dragover');
            if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
                handleEnnxFile(e.dataTransfer.files[0]);
            }
        }

        function handleEnnxFile(file) {
            if (!file) return;

            var formData = new FormData();
            formData.append('ennx_import', '1');
            formData.append('site_id', currentSiteId);
            formData.append('file', file);

            document.getElementById('ennxResults').style.display = 'none';
            document.getElementById('ennxDropzone').innerHTML =
                '<div class="spinner" style="width:24px;height:24px;border-width:3px;margin:0 auto 12px;"></div>' +
                '<h3>Processing ' + escHtml(file.name) + '...</h3>';

            fetch('va_site_maps.aspx', { method: 'POST', body: formData })
            .then(function(r) { return r.json(); })
            .then(function(data) {
                // Restore dropzone
                document.getElementById('ennxDropzone').innerHTML =
                    '<div class="drop-icon">&#128196;</div>' +
                    '<h3>Drop ENNX file here or click to browse</h3>' +
                    '<p>.ennx.txt or any text file with RFID tags / asset identifiers</p>';

                if (data.error) {
                    alert('ENNX Import Error: ' + data.error);
                    return;
                }

                // Show results
                var results = document.getElementById('ennxResults');
                results.style.display = 'block';

                var matchedTagged = data.matchedAssets ? data.matchedAssets.filter(function(a) { return a.tagged === '1'; }).length : 0;

                document.getElementById('ennxStats').innerHTML =
                    '<div class="ennx-stat blue"><span class="val">' + data.totalLines + '</span><span class="lbl">Lines Parsed</span></div>' +
                    '<div class="ennx-stat green"><span class="val">' + data.matched + '</span><span class="lbl">Matched</span></div>' +
                    '<div class="ennx-stat"><span class="val" style="color:var(--sm-green);">' + matchedTagged + '</span><span class="lbl">Already Tagged</span></div>' +
                    '<div class="ennx-stat red"><span class="val">' + data.unmatched + '</span><span class="lbl">Unmatched</span></div>';

                // Render matched assets table
                var tbody = document.getElementById('ennxTableBody');
                tbody.innerHTML = '';

                if (data.matchedAssets) {
                    data.matchedAssets.forEach(function(a) {
                        var isTagged = a.tagged === '1';
                        var tr = document.createElement('tr');
                        tr.innerHTML =
                            '<td>' + escHtml(a.name) + '</td>' +
                            '<td style="font-family:monospace;font-size:11px;">' + escHtml(a.rfid) + '</td>' +
                            '<td><span class="dot ' + (isTagged ? 'dot-green' : 'dot-red') + '"></span>' + (isTagged ? 'Tagged' : 'Not Tagged') + '</td>' +
                            '<td>' + escHtml(a.loc || a.spLoc) + '</td>';
                        tbody.appendChild(tr);
                    });
                }

                // Show unmatched lines if any
                if (data.unmatchedLines && data.unmatchedLines.length > 0) {
                    data.unmatchedLines.slice(0, 10).forEach(function(line) {
                        var tr = document.createElement('tr');
                        tr.innerHTML =
                            '<td colspan="2" style="color:var(--sm-amber);">' + escHtml(line) + '</td>' +
                            '<td><span class="dot dot-amber"></span>No Match</td>' +
                            '<td>—</td>';
                        tbody.appendChild(tr);
                    });
                }
            })
            .catch(function(err) {
                alert('ENNX Import Error: ' + err);
                document.getElementById('ennxDropzone').innerHTML =
                    '<div class="drop-icon">&#128196;</div>' +
                    '<h3>Drop ENNX file here or click to browse</h3>' +
                    '<p>.ennx.txt or any text file with RFID tags / asset identifiers</p>';
            });
        }


        // ================================================================
        //  EXPORT
        // ================================================================
        function exportCsv(type) {
            if (currentSiteId === '0') {
                alert('Please select a site first.');
                return;
            }
            window.open('va_site_maps.aspx?api=export' + type + '&site=' + currentSiteId, '_blank');
        }


        // ================================================================
        //  MAP FILE UPLOAD (existing feature — preserved)
        // ================================================================
        function uploadFile(file, mapPath) {
            var formData = new FormData();
            formData.append('replace_path', mapPath);
            formData.append('file', file);

            fetch('va_site_maps.aspx', { method: 'POST', body: formData })
            .then(function(res) {
                if (res.ok) {
                    if (!completedMaps.includes(mapPath)) {
                        completedMaps.push(mapPath);
                        localStorage.setItem('idash_map_progress', JSON.stringify(completedMaps));
                    }
                    renderMaps();
                } else {
                    alert('Error: Server rejected the file upload.');
                }
            })
            .catch(function(err) { alert('Upload error: ' + err); });
        }


        // ================================================================
        //  HELPERS
        // ================================================================
        function escHtml(str) {
            if (!str) return '';
            return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }


        // ================================================================
        //  COLUMN CHOOSER
        // ================================================================
        var smHiddenCols = new Set();
        var smColChooserBuilt = false;

        function initColumnChooser() {
            var list = document.getElementById('colChooserList');
            list.innerHTML = '';
            var ths = document.querySelectorAll('#detailTable thead th');

            // Load saved state from localStorage
            var savedKey = 'idash_sm_hidden_cols_' + (currentSiteId || '');
            var saved = localStorage.getItem(savedKey);
            if (saved) {
                try { smHiddenCols = new Set(JSON.parse(saved)); } catch(e) { smHiddenCols = new Set(); }
            }

            ths.forEach(function(th, index) {
                var name = th.textContent.trim();
                var label = document.createElement('label');
                var cb = document.createElement('input');
                cb.type = 'checkbox';
                cb.checked = !smHiddenCols.has(index);
                cb.setAttribute('data-col', index);
                cb.onchange = function() {
                    toggleColumn(index, this.checked);
                };
                label.appendChild(cb);
                label.appendChild(document.createTextNode(' ' + name));
                list.appendChild(label);
            });

            // Apply saved hidden columns
            applyColumnVisibility();
            smColChooserBuilt = true;
        }

        function toggleColumnChooser(e) {
            e.stopPropagation();
            var chooser = document.getElementById('colChooser');
            if (chooser.style.display === 'block') {
                chooser.style.display = 'none';
            } else {
                if (!smColChooserBuilt) initColumnChooser();
                chooser.style.display = 'block';
            }
        }

        function toggleColumn(colIndex, show) {
            if (show) smHiddenCols.delete(colIndex);
            else smHiddenCols.add(colIndex);
            applyColumnVisibility();
            // Save to localStorage
            var savedKey = 'idash_sm_hidden_cols_' + (currentSiteId || '');
            localStorage.setItem(savedKey, JSON.stringify(Array.from(smHiddenCols)));
        }

        function applyColumnVisibility() {
            var styleEl = document.getElementById('smColVisStyle');
            if (!styleEl) {
                styleEl = document.createElement('style');
                styleEl.id = 'smColVisStyle';
                document.head.appendChild(styleEl);
            }
            var css = '';
            smHiddenCols.forEach(function(idx) {
                var n = idx + 1;
                css += '#detailTable th:nth-child(' + n + '), #detailTable td:nth-child(' + n + ') { display: none !important; }\n';
            });
            styleEl.textContent = css;
        }

        function resetColumns() {
            smHiddenCols = new Set();
            applyColumnVisibility();
            var savedKey = 'idash_sm_hidden_cols_' + (currentSiteId || '');
            localStorage.removeItem(savedKey);
            // Re-check all checkboxes
            var cbs = document.querySelectorAll('#colChooserList input[type="checkbox"]');
            cbs.forEach(function(cb) { cb.checked = true; });
        }

        // Close column chooser when clicking outside
        document.addEventListener('click', function(e) {
            var chooser = document.getElementById('colChooser');
            if (chooser && chooser.style.display === 'block' &&
                !e.target.closest('#colChooser') && !e.target.closest('#btnColumns')) {
                chooser.style.display = 'none';
            }
        });
    </script>

    <!-- Note Editor Modal -->
    <div class="note-modal-backdrop" id="noteModalBackdrop" onclick="closeNoteModal()">
        <div class="note-modal" onclick="event.stopPropagation()">
            <div class="note-modal-header">
                <div>
                    <h3>Edit Note</h3>
                    <div class="note-asset-name" id="noteModalAssetName"></div>
                </div>
                <button class="note-close" onclick="closeNoteModal()" title="Close">&times;</button>
            </div>
            <div class="note-modal-body">
                <textarea id="noteModalTextarea" placeholder="Type your note here..."></textarea>
                <div class="note-char-count"><span id="noteCharCount">0</span> characters</div>
            </div>
            <div class="note-modal-footer">
                <span class="note-hint">Ctrl+Enter to save &middot; Esc to cancel</span>
                <button class="note-cancel" onclick="closeNoteModal()">Cancel</button>
                <button class="note-save" id="noteModalSaveBtn" onclick="saveNoteFromModal()">Save Note</button>
            </div>
        </div>
    </div>

</body>
</html>
