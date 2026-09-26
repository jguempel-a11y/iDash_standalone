<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_asset_master.aspx.cs" Inherits="va_asset_master" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Asset Master &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet" />
    <script src="https://cdn.datatables.net/2.0.8/js/dataTables.js"></script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', Tahoma, sans-serif; font-size: 14px; }

         /* === HEADER === */
        .page-header {
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 88%) 0%, var(--card) 60%);
            border-bottom: 2px solid color-mix(in srgb, var(--accent), transparent 75%);
            padding: 16px 28px; display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0; z-index: 100;
            box-shadow: 0 1px 12px color-mix(in srgb, var(--accent), transparent 90%);
        }
        .header-brand { display: flex; align-items: center; gap: 14px; }
        .header-icon {
            width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, var(--accent), color-mix(in srgb, var(--accent), #8B5CF6 40%));
            font-size: 20px; color: #fff; box-shadow: 0 2px 8px color-mix(in srgb, var(--accent), transparent 60%);
        }
        .header-text h1 { margin: 0; font-size: 20px; font-weight: 700; color: var(--text); line-height: 1.2; }
        .header-text .subtitle { font-size: 12px; color: var(--muted); font-weight: 400; margin-top: 1px; }
        .header-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .header-divider { width: 1px; height: 26px; background: var(--line); margin: 0 2px; }
         /* === hdr-pill  see theme.css === */

        .dash { max-width: 1500px; margin: 0 auto; padding: 18px 24px; }

         /* === CONTROLS === */
        .ctrl-bar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-bottom: 14px; }
        .ctrl-label { font-size: 12px; color: var(--muted); font-weight: 600; text-transform: uppercase; letter-spacing: .4px; }
        .ctrl-select, .ctrl-input {
            background: var(--card); color: var(--text); border: 1px solid var(--line);
            padding: 7px 12px; border-radius: 6px; font-size: 13px; outline: none;
        }
        .ctrl-select option { background: var(--card); }
        .ctrl-input::placeholder { color: var(--muted); opacity: .5; }
        .ctrl-input:focus, .ctrl-select:focus { border-color: var(--accent); outline: 2px solid rgba(46,168,255,.15); outline-offset: -1px; }
        .sep { width: 1px; height: 24px; background: var(--line); }

        .btn-action {
            background: var(--accent); color: #fff; border: none; padding: 7px 16px;
            border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; transition: opacity .2s;
        }
        .btn-action:hover { opacity: .9; }
        .btn-secondary {
            background: var(--chip); color: var(--text); border: 1px solid var(--line);
            padding: 7px 14px; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 500; transition: .2s;
        }
        .btn-secondary:hover { border-color: var(--accent); }

         /* === KPI === */
        .kpi-row { display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; margin-bottom: 16px; }
        @media(max-width:1100px) { .kpi-row { grid-template-columns: repeat(3, 1fr); } }
        @media(max-width:640px) { .kpi-row { grid-template-columns: repeat(2, 1fr); } }
        .kpi-card {
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            padding: 16px 12px; text-align: center; transition: border-color .2s;
        }
        .kpi-card:hover { border-color: var(--accent); }
        .kpi-value { font-size: 28px; font-weight: 700; line-height: 1; margin-bottom: 3px; }
        .kpi-pct { font-size: 12px; font-weight: 600; margin-bottom: 2px; }
        .kpi-label { font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: .5px; color: var(--muted); }

         /* === COLUMN SELECTOR === */
        .col-selector {
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            padding: 0; margin-bottom: 14px; overflow: hidden;
        }
        .col-selector-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 8px 14px;
            border-bottom: 1px solid var(--line);
            background: var(--chip);
        }
        .col-selector-title {
            font-size: 11px; font-weight: 700; color: var(--muted);
            text-transform: uppercase; letter-spacing: .7px;
        }
        .col-selector-pills {
            display: flex; flex-wrap: wrap; gap: 6px; align-items: center;
            padding: 10px 14px;
        }
        .col-toggle {
            display: inline-flex; align-items: center; gap: 5px; font-size: 12px; font-weight: 500;
            padding: 4px 11px; border-radius: 20px; cursor: grab; user-select: none;
            background: var(--chip); border: 1px solid var(--line); color: var(--text);
            transition: background .15s, border-color .15s, transform .15s, opacity .15s, color .15s;
            white-space: nowrap;
        }
        .col-toggle:hover { border-color: var(--accent); color: var(--accent); }
        .col-toggle:active { cursor: grabbing; }
        .col-toggle.active {
            background: color-mix(in srgb, var(--accent), transparent 85%);
            color: var(--accent); border-color: color-mix(in srgb, var(--accent), transparent 55%);
            font-weight: 600;
        }
        .col-toggle.dragging { opacity: 0.35; transform: scale(0.93); }
        .col-toggle.drag-over { border-color: var(--accent); box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent), transparent 65%); transform: scale(1.04); }
        .col-toggle input { display: none; }

         /* === GLASS PANEL === */
        .glass {
            background: var(--card); border: 1px solid var(--line); border-radius: 10px;
            padding: 18px 20px; margin-bottom: 16px;
        }
        .panel-title {
            font-size: 12px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .6px;
            border-bottom: 1px solid var(--line); padding-bottom: 8px; margin-bottom: 14px;
            display: flex; justify-content: space-between; align-items: center;
        }

         /* === DATATABLES === */
        .tbl-wrap { overflow-x: auto; }
        #assetGrid { width: 100%; border-collapse: collapse; font-size: 13px; }
        #assetGrid th {
            background: var(--chip); color: var(--muted); font-size: 11px; text-transform: uppercase;
            letter-spacing: .4px; padding: 9px 12px; text-align: left; border-bottom: 1px solid var(--line);
            white-space: nowrap;
        }
        #assetGrid td { padding: 8px 12px; border-bottom: 1px solid var(--line); }
        #assetGrid tbody tr:hover td { background: var(--table-row-hover); }

        div.dt-container { color: var(--text) !important; }
        .dt-info, .dt-length label, .dt-search label { color: var(--muted) !important; font-size: 12px !important; }
        .dt-length select { background: var(--chip); color: var(--text); border: 1px solid var(--line); border-radius: 4px; padding: 4px; }
        .dt-search input { background: var(--chip) !important; color: var(--text) !important; border: 1px solid var(--line) !important; border-radius: 6px !important; padding: 5px 10px !important; outline: none !important; }
        .dt-paging button { background: var(--chip) !important; color: var(--text) !important; border: 1px solid var(--line) !important; border-radius: 4px !important; margin: 0 2px; }
        .dt-paging button.dt-paging-button.current { background: var(--accent) !important; color: #fff !important; border-color: var(--accent) !important; }

        .col-search {
            width: 100%; background: var(--chip); color: var(--text);
            border: 1px solid var(--line); padding: 4px 8px; border-radius: 4px;
            font-size: 11px; margin-top: 4px;
        }
        .col-search::placeholder { color: var(--muted); opacity: .4; }

        .pct-good { color: var(--accent-2); font-weight: 600; }
        .pct-warn { color: var(--warn); font-weight: 600; }
        .pct-bad  { color: var(--danger); font-weight: 600; }

        .status-pill {
            display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 600;
        }

         /* === LOADING === */
        .loading-overlay {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,.4);
            z-index: 9999; display: none; align-items: center; justify-content: center;
        }
        .loading-overlay.show { display: flex; }
        .loading-spinner {
            background: var(--card); padding: 24px 40px; border-radius: 12px; text-align: center;
            border: 1px solid var(--line); font-weight: 600; color: var(--accent);
        }

         /* === PRINT MODAL === */
        .print-overlay {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,.55); backdrop-filter: blur(4px);
            z-index: 10000; display: none; align-items: flex-start; justify-content: center;
            padding-top: 40px; overflow-y: auto;
        }
        .print-overlay.show { display: flex; }
        .print-modal {
            background: var(--card); border: 1px solid var(--line); border-radius: 14px;
            width: 95%; max-width: 1400px; padding: 24px 28px; margin-bottom: 40px;
            box-shadow: 0 12px 40px rgba(0,0,0,.35);
            animation: modalSlideIn .25s ease-out;
        }
        @keyframes modalSlideIn {
            from { opacity: 0; transform: translateY(-20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .print-modal-header {
            display: flex; align-items: center; justify-content: space-between;
            border-bottom: 1px solid var(--line); padding-bottom: 14px; margin-bottom: 18px;
        }
        .print-modal-header h2 {
            font-size: 18px; font-weight: 700; color: var(--text); margin: 0;
            display: flex; align-items: center; gap: 10px;
        }
        .print-modal-header h2 .pm-icon {
            width: 34px; height: 34px; border-radius: 8px; display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, var(--accent), color-mix(in srgb, var(--accent), #8B5CF6 40%));
            font-size: 17px; color: #fff;
        }
        .pm-close {
            background: none; border: 1px solid var(--line); border-radius: 8px;
            color: var(--muted); width: 34px; height: 34px; font-size: 18px; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            transition: border-color .2s, color .2s;
        }
        .pm-close:hover { border-color: var(--danger); color: var(--danger); }

        .pm-input-row {
            display: flex; align-items: flex-end; gap: 12px; flex-wrap: wrap; margin-bottom: 16px;
        }
        .pm-field { display: flex; flex-direction: column; gap: 4px; }
        .pm-field label {
            font-size: 11px; font-weight: 700; text-transform: uppercase;
            letter-spacing: .4px; color: var(--muted);
        }
        .pm-prefix {
            background: var(--chip); color: var(--accent); border: 1px solid color-mix(in srgb, var(--accent), transparent 70%);
            padding: 7px 14px; border-radius: 6px; font-size: 14px; font-weight: 700;
            min-width: 80px; text-align: center;
        }
        .pm-numbers {
            background: var(--card); color: var(--text); border: 1px solid var(--line);
            padding: 7px 12px; border-radius: 6px; font-size: 13px; outline: none; width: 320px;
        }
        .pm-numbers:focus { border-color: var(--accent); outline: 2px solid rgba(46,168,255,.15); outline-offset: -1px; }
        .pm-template-select {
            background: var(--card); color: var(--text); border: 1px solid var(--line);
            padding: 7px 12px; border-radius: 6px; font-size: 13px; outline: none;
        }
        .pm-template-select option { background: var(--card); }

        .pm-status {
            padding: 8px 14px; border-radius: 8px; font-size: 13px; margin-bottom: 14px;
            display: none;
        }
        .pm-status.info { display: block; background: color-mix(in srgb, var(--accent), transparent 88%); color: var(--accent); border: 1px solid color-mix(in srgb, var(--accent), transparent 70%); }
        .pm-status.success { display: block; background: color-mix(in srgb, var(--accent-2), transparent 88%); color: var(--accent-2); border: 1px solid color-mix(in srgb, var(--accent-2), transparent 70%); }
        .pm-status.error { display: block; background: color-mix(in srgb, var(--danger), transparent 88%); color: var(--danger); border: 1px solid color-mix(in srgb, var(--danger), transparent 70%); }
        .pm-status.warn { display: block; background: color-mix(in srgb, var(--warn), transparent 88%); color: var(--warn); border: 1px solid color-mix(in srgb, var(--warn), transparent 70%); }

        .pm-preview-header {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 10px;
        }
        .pm-preview-header .pm-count {
            font-size: 13px; color: var(--muted);
        }

        #printPreviewGrid { width: 100%; border-collapse: collapse; font-size: 13px; }
        #printPreviewGrid th {
            background: var(--chip); color: var(--muted); font-size: 11px; text-transform: uppercase;
            letter-spacing: .4px; padding: 9px 12px; text-align: left; border-bottom: 1px solid var(--line);
            white-space: nowrap;
        }
        #printPreviewGrid td { padding: 8px 12px; border-bottom: 1px solid var(--line); }
        #printPreviewGrid tbody tr:hover td { background: var(--table-row-hover); }

         /* === PRINT CHECKBOX COLUMN === */
        .chk-print-col { width: 36px; text-align: center; }
        .chk-print {
            width: 16px; height: 16px; cursor: pointer;
            accent-color: var(--accent);
        }
        #chkAllPrint {
            width: 16px; height: 16px; cursor: pointer;
            accent-color: var(--accent);
        }

         /* === PRINT SELECTION BAR === */
        #printSelectionBar {
            display: none;
            align-items: center; gap: 10px; flex-wrap: wrap;
            background: color-mix(in srgb, var(--accent), transparent 88%);
            border: 1px solid color-mix(in srgb, var(--accent), transparent 60%);
            border-radius: 8px; padding: 10px 16px; margin-top: 10px;
            animation: fadeIn .25s ease;
        }
        #printSelectionBar.show { display: flex; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: translateY(0); } }
        #printSelectionBar .ps-label {
            font-size: 12px; font-weight: 700; color: var(--accent);
            text-transform: uppercase; letter-spacing: .4px;
        }
        .ps-select {
            background: var(--card); color: var(--text); border: 1px solid var(--line);
            padding: 6px 10px; border-radius: 6px; font-size: 12px; outline: none;
            border-color: color-mix(in srgb, var(--accent), transparent 60%);
        }
        .ps-select option { background: var(--card); }
        .ps-btn {
            padding: 7px 16px; border-radius: 6px; border: none; cursor: pointer;
            font-size: 13px; font-weight: 600; transition: opacity .2s;
        }
        .ps-btn:hover { opacity: .88; }
        .ps-btn-server { background: var(--accent); color: #fff; }
        .ps-btn-native { background: #8b5cf6; color: #fff; }

         /* === DETAIL PANEL === */
        .detail-panel {
            position: fixed; top: 0; right: 0; bottom: 0; width: 700px; max-width: 95vw;
            background: var(--card); border-left: 2px solid var(--line);
            z-index: 200; transform: translateX(100%); transition: transform .3s ease;
            display: flex; flex-direction: column; overflow: hidden;
            box-shadow: -8px 0 30px rgba(0,0,0,.25);
        }
        .detail-panel.open { transform: translateX(0); }
        body.detail-open .dash { margin-right: 710px; transition: margin-right .3s ease; }
        @media(max-width:1100px) { body.detail-open .dash { margin-right: 0; } }

        .dp-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 16px 20px; border-bottom: 1px solid var(--line);
            background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 88%), var(--card));
            flex-shrink: 0;
        }
        .dp-header h2 { margin: 0; font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        .dp-header h2 .dp-icon {
            width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, var(--accent), #8B5CF6); font-size: 15px; color: #fff;
        }
        .dp-close {
            background: none; border: 1px solid var(--line); border-radius: 8px;
            color: var(--muted); width: 32px; height: 32px; font-size: 16px; cursor: pointer;
            transition: border-color .2s, color .2s;
        }
        .dp-close:hover { border-color: var(--danger); color: var(--danger); }

        .dp-actions {
            display: flex; gap: 6px; padding: 10px 20px; border-bottom: 1px solid var(--line);
            background: var(--bg); flex-shrink: 0; flex-wrap: wrap;
        }
        .dp-action-btn {
            display: inline-flex; align-items: center; gap: 5px; padding: 6px 14px;
            border-radius: 6px; font-size: 12px; font-weight: 600; text-decoration: none;
            border: 1px solid var(--line); background: var(--chip); color: var(--text);
            cursor: pointer; transition: .2s;
        }
        .dp-action-btn:hover { border-color: var(--accent); color: var(--accent); }
        .dp-action-btn.primary { background: var(--accent); color: #fff; border-color: var(--accent); }
        .dp-action-btn.primary:hover { opacity: .88; }

        .dp-tabs {
            display: flex; gap: 0; border-bottom: 2px solid var(--line);
            padding: 0 20px; background: var(--bg); flex-shrink: 0; overflow-x: auto;
        }
        .dp-tab {
            padding: 10px 16px; font-size: 12px; font-weight: 600; text-transform: uppercase;
            letter-spacing: .4px; color: var(--muted); cursor: pointer; border: none; background: none;
            border-bottom: 2px solid transparent; margin-bottom: -2px; transition: .2s; white-space: nowrap;
        }
        .dp-tab:hover { color: var(--text); }
        .dp-tab.active { color: var(--accent); border-bottom-color: var(--accent); }
        .dp-tab .tab-badge {
            display: inline-flex; align-items: center; justify-content: center;
            min-width: 18px; height: 18px; border-radius: 9px; font-size: 10px; font-weight: 700;
            background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--accent);
            margin-left: 5px; padding: 0 5px;
        }

        .dp-body { flex: 1; overflow-y: auto; padding: 20px; }
        .dp-tab-content { display: none; }
        .dp-tab-content.active { display: block; }

        .dp-field-group { margin-bottom: 18px; }
        .dp-field-group-title {
            font-size: 11px; font-weight: 700; color: var(--accent); text-transform: uppercase;
            letter-spacing: .5px; border-bottom: 1px solid var(--line); padding-bottom: 6px; margin-bottom: 10px;
        }
        .dp-fields { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
        .dp-fields.single { grid-template-columns: 1fr; }
        .dp-field label {
            display: block; font-size: 10px; font-weight: 600; color: var(--muted);
            text-transform: uppercase; letter-spacing: .3px; margin-bottom: 2px;
        }
        .dp-field .dp-val {
            font-size: 13px; color: var(--text); padding: 5px 8px;
            background: var(--bg); border: 1px solid var(--line); border-radius: 5px;
            min-height: 28px; word-break: break-word;
        }
        .dp-field .dp-val.empty { color: var(--muted); font-style: italic; opacity: .5; }

        .dp-history-table { width: 100%; border-collapse: collapse; font-size: 12px; }
        .dp-history-table th {
            background: var(--chip); color: var(--muted); font-size: 10px; text-transform: uppercase;
            letter-spacing: .4px; padding: 8px 10px; text-align: left; border-bottom: 1px solid var(--line);
            position: sticky; top: 0;
        }
        .dp-history-table td { padding: 7px 10px; border-bottom: 1px solid var(--line); }
        .dp-history-table tbody tr:hover td { background: var(--table-row-hover); }

        .dp-empty {
            text-align: center; padding: 40px 20px; color: var(--muted);
            font-size: 13px; font-style: italic;
        }
        .dp-empty .dp-empty-icon { font-size: 36px; margin-bottom: 10px; opacity: .4; display: block; }

        .dp-loading {
            text-align: center; padding: 30px; color: var(--accent); font-weight: 600; font-size: 13px;
        }

        /* Highlight selected row in main grid */
        #assetGrid tbody tr.row-selected td {
            background: color-mix(in srgb, var(--accent), transparent 88%) !important;
            border-bottom-color: color-mix(in srgb, var(--accent), transparent 70%);
        }
        #assetGrid tbody tr { cursor: pointer; }

         /* === INLINE EDIT === */
        .dp-edit-toggle {
            display: inline-flex; align-items: center; gap: 5px; padding: 6px 14px;
            border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; transition: .2s;
            border: 1px solid var(--line); background: var(--chip); color: var(--text);
        }
        .dp-edit-toggle:hover { border-color: var(--accent); color: var(--accent); }
        .dp-edit-toggle.editing { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--accent-2); border-color: var(--accent-2); }

        .dp-field .dp-input, .dp-field .dp-select, .dp-field .dp-textarea {
            width: 100%; font-size: 13px; color: var(--text); padding: 5px 8px;
            background: var(--bg); border: 1.5px solid color-mix(in srgb, var(--accent), transparent 60%);
            border-radius: 5px; outline: none; font-family: inherit; transition: border-color .2s;
        }
        .dp-field .dp-input:focus, .dp-field .dp-select:focus, .dp-field .dp-textarea:focus {
            border-color: var(--accent); box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent), transparent 80%);
        }
        .dp-field .dp-textarea { min-height: 60px; resize: vertical; }
        .dp-field .dp-select option { background: var(--card); }
        .dp-field.dirty .dp-input, .dp-field.dirty .dp-select, .dp-field.dirty .dp-textarea {
            border-color: var(--accent-2); background: color-mix(in srgb, var(--accent-2), transparent 92%);
        }

        .dp-save-bar {
            display: none; padding: 12px 20px; border-top: 2px solid var(--accent-2);
            background: color-mix(in srgb, var(--accent-2), var(--card) 92%);
            flex-shrink: 0; gap: 8px; align-items: center; justify-content: space-between;
        }
        .dp-save-bar.show { display: flex; }
        .dp-save-bar .dp-save-info { font-size: 12px; color: var(--accent-2); font-weight: 600; }
        .dp-save-bar .dp-save-btns { display: flex; gap: 8px; }
        .dp-save-btn {
            padding: 8px 20px; border-radius: 6px; border: none; cursor: pointer;
            font-size: 13px; font-weight: 600; transition: .2s;
        }
        .dp-save-btn.save { background: var(--accent-2); color: #fff; }
        .dp-save-btn.save:hover { opacity: .88; }
        .dp-save-btn.cancel { background: var(--chip); color: var(--text); border: 1px solid var(--line); }
        .dp-save-btn.cancel:hover { border-color: var(--danger); color: var(--danger); }

        .dp-save-toast {
            position: fixed; bottom: 24px; right: 24px; padding: 12px 24px;
            border-radius: 10px; font-size: 13px; font-weight: 600; z-index: 9999;
            animation: toastIn .3s ease-out; box-shadow: 0 4px 20px rgba(0,0,0,.3);
        }
        .dp-save-toast.success { background: var(--accent-2); color: #fff; }
        .dp-save-toast.error { background: var(--danger); color: #fff; }
        @keyframes toastIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    </style>
</head>
<body>
<form id="form1" runat="server">

<div class="loading-overlay" id="loadingOverlay">
    <div class="loading-spinner">Loading assets...</div>
</div>

<!-- â”€â”€ HEADER â”€â”€ -->
<div class="page-header">
    <div class="header-brand">
        <div class="header-icon">&#128203;</div>
        <div class="header-text">
            <h1>Asset Master</h1>
            <div class="subtitle">Search, filter &amp; export all asset data</div>
        </div>
    </div>
    <div class="header-right">
        <button type="button" class="nav-pill nav-pill-primary" onclick="openPrintModal()">&#128424; Print</button>
        <button type="button" id="btnExportTop" class="nav-pill nav-pill-primary" onclick="exportData('excel')">&#128190; Export Excel</button>
        <div class="header-divider"></div>
        <a href="va_fixed_reader.aspx" class="nav-pill nav-pill-ghost">&#128202; Fixed Readers</a>
        <a href="va_fixed_reader_live.aspx" class="nav-pill nav-pill-ghost" target="_blank">&#128225; Live Feed</a>
        <div style="position:relative;display:inline-block;">
            <button type="button" id="btnFixedReader" class="nav-pill nav-pill-ghost" onclick="toggleFixedReaderReport()">&#128225; Fixed Reader Report</button>
            <select id="ddlFrRange" style="display:none;position:absolute;top:100%;left:0;margin-top:4px;z-index:50;padding:5px 8px;border-radius:6px;border:1px solid var(--line);font-size:12px;background:var(--card);color:var(--fg);min-width:140px;"
                onchange="applyFixedReaderRange()">
                <option value="today">Today</option>
                <option value="week">This Week</option>
                <option value="month" selected>This Month</option>
                <option value="all">All Time</option>
            </select>
        </div>
        <a href="va_asset_stats.aspx" class="nav-pill nav-pill-ghost">&#128200; Statistics</a>
        <a href="va_location_list.aspx" class="nav-pill nav-pill-ghost">&#128205; Locations</a>
        <div class="header-divider"></div>
        <button type="button" id="themeToggleBtn" class="nav-pill nav-pill-ghost" onclick="toggleTheme()" title="Switch between light and dark mode" style="font-size:16px;padding:6px 10px;">☀️</button>
        <a href="documentation/va_asset_master.html" class="nav-pill nav-pill-docs">&#128214; Docs</a>
        <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
    </div>
</div>

<div class="dash">

    <!-- â”€â”€ CONTROLS â”€â”€ -->
    <div class="ctrl-bar">
        <span class="ctrl-label">Site</span>
        <asp:DropDownList ID="DdlCompany" runat="server" CssClass="ctrl-select" ClientIDMode="Static" />

        <div class="sep"></div>

        <span class="ctrl-label">Status</span>
        <select id="ddlStatus" class="ctrl-select">
            <option value="">All Statuses</option>
            <option value="IN USE" selected>IN USE</option>
            <option value="TURNED IN">TURNED IN</option>
            <option value="LOST OR STOLEN">LOST OR STOLEN</option>
            <option value="OUT OF SERVICE">OUT OF SERVICE</option>
            <option value="LOANED OUT">LOANED OUT</option>
        </select>

        <div class="sep"></div>

        <span class="ctrl-label">Search</span>
        <input type="text" id="txtSearch" class="ctrl-input" placeholder="Name, CMR, serial, location..." style="width:220px;" />

        <div class="sep"></div>

        <span class="ctrl-label">CMR</span>
        <input type="text" id="txtCmr" class="ctrl-input" placeholder="CMR..." style="width:120px;" />

        <span class="ctrl-label">Location</span>
        <input type="text" id="txtLocation" class="ctrl-input" placeholder="Location..." style="width:150px;" />

        <div class="sep"></div>

        <span class="ctrl-label" title="Show assets NOT inventoried in this many days or more. e.g. type 90 to see assets overdue 90+ days.">Days Since &#8805;</span>
        <input type="number" id="txtDays" class="ctrl-input" placeholder="e.g. 90" min="0" step="1" style="width:90px;" title="Show assets not inventoried in this many days or more" />

        <button type="button" class="btn-action" onclick="reloadGrid()">Search</button>
        <button type="button" class="btn-secondary" onclick="clearFilters()">Clear</button>
    </div>

    <!-- â”€â”€ KPI CARDS â”€â”€ -->
    <div class="kpi-row">
        <div class="kpi-card">
            <div class="kpi-value" id="kv-total" style="color:var(--accent);">â€”</div>
            <div class="kpi-label">Matching Assets</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-locs" style="color:#8B5CF6;">â€”</div>
            <div class="kpi-label">Locations</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-cmr" style="color:var(--accent-2);">â€”</div>
            <div class="kpi-pct" id="kp-cmr" style="color:var(--accent-2);"></div>
            <div class="kpi-label">With CMR</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-recent" style="color:var(--accent-2);">â€”</div>
            <div class="kpi-pct" id="kp-recent" style="color:var(--accent-2);"></div>
            <div class="kpi-label">Inv. &lt; 12 Months</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value" id="kv-overdue" style="color:var(--danger);">â€”</div>
            <div class="kpi-pct" id="kp-overdue" style="color:var(--danger);"></div>
            <div class="kpi-label">Overdue / Never</div>
        </div>
    </div>

    <!-- â”€â”€ COLUMN SELECTOR â”€â”€ -->
    <div id="colSelector" class="col-selector">
        <div class="col-selector-header">
            <span class="col-selector-title">&#9776; Columns</span>
            <button type="button" class="btn-secondary" style="padding:4px 10px; font-size:11px; font-weight:600;"
                onclick="localStorage.removeItem('AssetMasterCols'); localStorage.removeItem('AssetMasterSort'); window.location.reload();">
                &#8635; Reset View
            </button>
        </div>
        <div class="col-selector-pills" id="colSelectorPills">
            <!-- populated by JS -->
        </div>
    </div>

    <!-- â”€â”€ MAIN GRID â”€â”€ -->
    <div class="glass">
        <div class="panel-title">
            <span>Asset Data</span>
            <span id="gridInfo" style="font-size:12px;font-weight:400;text-transform:none;letter-spacing:0;color:var(--muted);"></span>
        </div>
        <div class="tbl-wrap">
            <table id="assetGrid" class="display" style="width:100%;">
                <thead>
                    <tr id="headerRow"></tr>
                    <tr id="searchRow"></tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

    <!-- ── PRINT SELECTION BAR ── -->
    <div id="printSelectionBar">
        <span class="ps-label">&#128424; Selected (<span id="psSelectedCount">0</span>):</span>
        <select id="DdlPrintTemplateAM" class="ps-select" style="display:none;">
            <option value="">-- Auto-Map Template --</option>
        </select>
        <select id="DdlPrintTargetAM" class="ps-select" style="display:none;">
            <option value="">-- Default Route --</option>
        </select>
        <button type="button" id="BtnPrintCheckedAM" class="ps-btn ps-btn-server" onclick="printCheckedTagsAM();">Server Print (0)</button>
        <button type="button" id="BtnExportExcelCheckedAM" class="ps-btn ps-btn-server" style="background:#16a34a;border-color:#15803d;color:#ffffff;margin-left:8px;" onclick="exportData('excel');">&#128190; Export Selected Excel (0)</button>
    </div>

</div>

<!-- â”€â”€ PRINT MODAL â”€â”€ -->
<div class="print-overlay" id="printOverlay" onclick="if(event.target===this) closePrintModal()">
    <div class="print-modal">
        <div class="print-modal-header">
            <h2><span class="pm-icon">&#128424;</span> Print Assets</h2>
            <button type="button" class="pm-close" onclick="closePrintModal()">&times;</button>
        </div>

        <div class="pm-input-row">
            <div class="pm-field">
                <label>Site Prefix</label>
                <div class="pm-prefix" id="pmPrefix">â€”</div>
            </div>
            <div class="pm-field">
                <label>Asset Numbers</label>
                <input type="text" id="pmNumbers" class="pm-numbers" placeholder="e.g. 1, 3-25, 42" />
            </div>
            <div class="pm-field">
                <label>Print Template</label>
                <select id="pmTemplate" class="pm-template-select">
                    <option value="">Loading...</option>
                </select>
            </div>
            <button type="button" class="btn-action" onclick="loadPrintPreview()">Load Preview</button>
            <button type="button" class="btn-action" id="btnSubmitPrint" onclick="submitPrintJobs()" style="background:var(--accent-2); display:none;">&#128424; Send to Printer</button>
        </div>

        <div class="pm-status" id="pmStatus"></div>

        <div class="pm-preview-header" id="pmPreviewHeader" style="display:none;">
            <span class="panel-title" style="border:none;padding:0;margin:0;">Print Preview</span>
            <span class="pm-count" id="pmCount"></span>
        </div>
        <div class="tbl-wrap" id="pmTableWrap" style="display:none;">
            <table id="printPreviewGrid">
                <thead><tr id="pmHeaderRow"></tr></thead>
                <tbody id="pmBody"></tbody>
            </table>
        </div>
    </div>
</div>

<idash:Footer runat="server" />
<asp:Literal ID="LitPrintConfig" runat="server" />

<!-- â”€â”€ ASSET DETAIL PANEL â”€â”€ -->
<div class="detail-panel" id="detailPanel">
    <div class="dp-header">
        <h2><span class="dp-icon">&#128203;</span> <span id="dpTitle">Asset Detail</span></h2>
        <button type="button" class="dp-close" onclick="closeDetail()">&times;</button>
    </div>

    <div class="dp-actions">
        <button type="button" id="dpEditToggle" class="dp-edit-toggle" onclick="toggleEditMode()">&#9998; Edit Mode</button>
        <a id="dpEditLink" href="#" target="_blank" class="dp-action-btn">&#8599; Open in AssetWorx</a>
        <button type="button" class="dp-action-btn" onclick="printFromDetail()">&#128424; Print Tag</button>
    </div>

    <div class="dp-tabs">
        <button type="button" class="dp-tab active" data-tab="general" onclick="switchTab(this)">General</button>
        <button type="button" class="dp-tab" data-tab="lochistory" onclick="switchTab(this)">Location History <span class="tab-badge" id="badgeLoc">â€”</span></button>
        <button type="button" class="dp-tab" data-tab="checkout" onclick="switchTab(this)">Checkout <span class="tab-badge" id="badgeCO">â€”</span></button>
        <button type="button" class="dp-tab" data-tab="maintenance" onclick="switchTab(this)">Maintenance <span class="tab-badge" id="badgeMnt">â€”</span></button>
        <button type="button" class="dp-tab" data-tab="children" onclick="switchTab(this)">Children <span class="tab-badge" id="badgeChild">â€”</span></button>
    </div>

    <div class="dp-body">
        <!-- GENERAL TAB -->
        <div class="dp-tab-content active" id="tab-general"></div>
        <!-- LOCATION HISTORY TAB -->
        <div class="dp-tab-content" id="tab-lochistory"></div>
        <!-- CHECKOUT TAB -->
        <div class="dp-tab-content" id="tab-checkout"></div>
        <!-- MAINTENANCE TAB -->
        <div class="dp-tab-content" id="tab-maintenance"></div>
        <!-- CHILDREN TAB -->
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

</form>

<script type="text/javascript">
    // ============================================== COLUMN DEFINITIONS ==============================================
    var ALL_COLS = [
        { key: 'name',              label: 'Asset Name',              visible: true  },
        { key: 'description',       label: 'Description',             visible: false },
        { key: 'locationname',      label: 'Current Location',        visible: true  },
        { key: 'text8',             label: 'CMR',                     visible: true  },
        { key: 'listvalue1',        label: 'Status',                  visible: true  },
        { key: 'text4',             label: 'Category',                visible: true  },
        { key: 'text1',             label: 'Manufacturer',            visible: true  },
        { key: 'text2',             label: 'Model',                   visible: false },
        { key: 'text3',             label: 'Serial #',                visible: false },
        { key: 'text5',             label: 'Service',                 visible: false },
        { key: 'text6',             label: 'Assigned Location',       visible: false },
        { key: 'text7',             label: 'Station',                 visible: true  },
        { key: 'text9',             label: 'PO #',                    visible: false },
        { key: 'text11',            label: 'Prev. Assigned Location', visible: false },
        { key: 'lastinventoried',   label: 'Last Inventoried',        visible: true  },
        { key: 'daysSince',         label: 'Days Since',              visible: false },
        { key: 'text18',            label: 'Tagged',                  visible: false },
        { key: 'lastobservedtime',  label: 'Reader Last Seen',        visible: false },
        { key: 'lastobservedlocation', label: 'Reader Location',      visible: false }
    ];

    try {
        var savedCols = localStorage.getItem('AssetMasterCols');
        if (savedCols) {
            var parsedCols = JSON.parse(savedCols);
            if (parsedCols.length === ALL_COLS.length) {
                // Merge saved visibility into current definitions (preserves updated labels)
                var keyMap = {};
                parsedCols.forEach(function(c) { keyMap[c.key] = c.visible; });
                ALL_COLS.forEach(function(c) {
                    if (keyMap.hasOwnProperty(c.key)) c.visible = keyMap[c.key];
                });
            }
        }
    } catch(e) {}

    function saveColsState() {
        try { localStorage.setItem('AssetMasterCols', JSON.stringify(ALL_COLS)); } catch(e) {}
    }


    var dt = null; // DataTable instance

    // ============================================================ INIT ============================================================
    var _filterTimer = null;
    $(document).ready(function () {
        buildColumnSelector();

    // == Restore last-used site from localStorage (persists across pages) ==
        try {
            var _savedSite = localStorage.getItem('iDash_selectedSite');
            if (_savedSite && _savedSite !== '0') { $('#DdlCompany').val(_savedSite); }
        } catch(e) {}

    function setSiteDropdown(valOrPrefix) {
        if (!valOrPrefix || valOrPrefix === '0') {
            $('#DdlCompany').val('0');
            return;
        }
        var targetStr = String(valOrPrefix).trim().toLowerCase();
        var matched = false;

        // Pass 1: Exact value match (e.g. company id "7")
        $('#DdlCompany option').each(function () {
            if (String(this.value).trim().toLowerCase() === targetStr) {
                $('#DdlCompany').val(this.value);
                matched = true;
                return false;
            }
        });
        if (matched) return;

        // Pass 2: Text starts with prefix (e.g. "613" matches "613 Martinsburg")
        $('#DdlCompany option').each(function () {
            var optTxt = String(this.text).trim().toLowerCase();
            if (optTxt.indexOf(targetStr) === 0) {
                $('#DdlCompany').val(this.value);
                matched = true;
                return false;
            }
        });
        if (matched) return;

        // Pass 3: Text contains (fallback)
        $('#DdlCompany option').each(function () {
            var optTxt = String(this.text).trim().toLowerCase();
            if (optTxt.indexOf(targetStr) !== -1) {
                $('#DdlCompany').val(this.value);
                return false;
            }
        });
    }

    // == Pre-fill filters from URL querystring (?loc=, ?location=, ?site=)  overrides localStorage ==
        var _qs = new URLSearchParams(window.location.search);
        var _qsLoc  = _qs.get('loc') || _qs.get('location');
        var _qsSite = _qs.get('site');
        if (_qsLoc)  { $('#txtLocation').val(decodeURIComponent(_qsLoc)); }
        if (_qsSite && _qsSite !== '0') { setSiteDropdown(_qsSite); }

        // == Pre-fill from Live Feed Watch List (?watchFilter=1) BEFORE initGrid ==
        (function () {
            try {
                if (_qs.get('watchFilter') === '1') {
                    var raw = sessionStorage.getItem('idash-watch-filter');
                    if (raw) {
                        var names = JSON.parse(raw);
                        if (names && names.length > 0) {
                            // Set search box to asset names (DataTable server search)
                            // For multi-asset, use pipe-delimited which the server treats as OR
                            $('#txtSearch').val(names.join('|'));

                            // Set status to All Statuses so watched asset is visible regardless of current status
                            $('#ddlStatus').val('');

                            // Automatically select the site being inspected (e.g. 613 Martinsburg)
                            if (_qsSite && _qsSite !== '0') {
                                setSiteDropdown(_qsSite);
                            } else {
                                // Check if all assets share the same 3-digit site prefix (e.g. 613 EE12889 -> '613')
                                var firstPrefix = (names[0] || '').substring(0, 3);
                                if (/^\d{3}$/.test(firstPrefix)) {
                                    var allSame = names.every(function(n) { return (n || '').substring(0, 3) === firstPrefix; });
                                    if (allSame) {
                                        setSiteDropdown(firstPrefix);
                                    } else {
                                        $('#DdlCompany').val('0'); // Multiple sites -> All Sites
                                    }
                                } else {
                                    $('#DdlCompany').val('0');
                                }
                            }

                            // Show a banner
                            var selSiteText = $('#DdlCompany option:selected').text();
                            var siteInfo = (selSiteText && $('#DdlCompany').val() !== '0') ? ' (Site: <strong>' + selSiteText + '</strong>)' : '';
                            var banner = document.createElement('div');
                            banner.id = 'watchFilterBanner';
                            banner.style.cssText = 'background:color-mix(in srgb,#10b981 12%,transparent);border:1px solid #10b981;border-radius:8px;padding:10px 16px;margin:0 0 12px 0;display:flex;align-items:center;justify-content:space-between;font-size:13px;color:#10b981;';
                            banner.innerHTML = '<span>📡 <strong>Fixed Reader Watch List</strong> — Showing <strong>' + names.length + '</strong> asset(s)' + siteInfo + '. <a href="javascript:history.back()" style="color:#10b981;text-decoration:underline;">Back</a></span>'
                                + '<button type="button" onclick="clearWatchFilter()" style="background:none;border:1px solid #10b981;color:#10b981;border-radius:4px;padding:3px 10px;cursor:pointer;font-size:12px;">✕ Clear Filter</button>';
                            var grid = document.getElementById('assetGrid');
                            if (grid && grid.parentElement) grid.parentElement.parentElement.insertBefore(banner, grid.parentElement);
                            // Clean up sessionStorage after reading
                            sessionStorage.removeItem('idash-watch-filter');
                        }
                    }
                }
            } catch (e) {}
        })();

        // == Initialize grid AFTER all filters and search values have been pre-filled ==
        initGrid();

    // == Live filtering  dropdowns reload instantly; save site to localStorage ==
        $('#DdlCompany, #ddlStatus').on('change', function () {
            if (this.id === 'DdlCompany') {
                try { localStorage.setItem('iDash_selectedSite', this.value); } catch(e) {}
            }
            reloadGrid();
        });

    // == Live filtering  text inputs debounce (400ms) to avoid excessive requests ==
        $('#txtSearch, #txtCmr, #txtLocation, #txtDays').on('input', function () {
            clearTimeout(_filterTimer);
            _filterTimer = setTimeout(function () { reloadGrid(); }, 400);
        });
    });

    // ================================ COLUMN SELECTOR WITH DRAG & DROP ================================
    var dragSrcIdx = null;

    function buildColumnSelector() {
        var container = document.getElementById('colSelectorPills');
        container.innerHTML = '';

        ALL_COLS.forEach(function (col, i) {
            var lbl = document.createElement('label');
            lbl.className = 'col-toggle' + (col.visible ? ' active' : '');
            lbl.draggable = true;
            lbl.setAttribute('data-col-idx', i);

            lbl.innerHTML = '<input type="checkbox"' + (col.visible ? ' checked' : '') + '> ' + col.label;

            // Toggle visibility on click
            lbl.querySelector('input').addEventListener('change', function (e) {
                e.stopPropagation();
                var idx = parseInt(lbl.getAttribute('data-col-idx'));
                ALL_COLS[idx].visible = this.checked;
                lbl.classList.toggle('active', this.checked);
                saveColsState();
                rebuildGrid();
            });

            // Prevent checkbox from interfering with drag
            lbl.querySelector('input').addEventListener('mousedown', function (e) {
                e.stopPropagation();
            });

    // ===================================================== Drag events =====================================================
            lbl.addEventListener('dragstart', function (e) {
                dragSrcIdx = parseInt(this.getAttribute('data-col-idx'));
                this.classList.add('dragging');
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/plain', dragSrcIdx);
            });

            lbl.addEventListener('dragend', function () {
                this.classList.remove('dragging');
                container.querySelectorAll('.col-toggle').forEach(function (el) {
                    el.classList.remove('drag-over');
                });
            });

            lbl.addEventListener('dragover', function (e) {
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                this.classList.add('drag-over');
            });

            lbl.addEventListener('dragleave', function () {
                this.classList.remove('drag-over');
            });

            lbl.addEventListener('drop', function (e) {
                e.preventDefault();
                this.classList.remove('drag-over');
                var dropIdx = parseInt(this.getAttribute('data-col-idx'));
                if (dragSrcIdx === null || dragSrcIdx === dropIdx) return;

                // Reorder ALL_COLS array
                var moved = ALL_COLS.splice(dragSrcIdx, 1)[0];
                ALL_COLS.splice(dropIdx, 0, moved);

                // Rebuild selector and grid
                saveColsState();
                buildColumnSelector();
                rebuildGrid();
                dragSrcIdx = null;
            });

            container.appendChild(lbl);
        });
    }

    function rebuildGrid() {
        // Save current page & search state
        var currentPage = dt ? dt.page() : 0;

        // Destroy existing DataTable
        if (dt) {
            dt.destroy();
            dt = null;
        }
        $('#assetGrid thead').empty().append('<tr id="headerRow"></tr><tr id="searchRow"></tr>');
        $('#assetGrid tbody').empty();

        initGrid();

        // Restore page
        if (currentPage > 0 && dt) {
            dt.page(currentPage).draw('page');
        }
    }

    function getVisibleKeys() {
        return ALL_COLS.filter(function (c) { return c.visible; }).map(function (c) { return c.key; });
    }

    // ========================================================= FILTERS =========================================================
    // ── Theme toggle ─────────────────────────────────────────────
    function toggleTheme() {
        var html = document.documentElement;
        var isDark = html.getAttribute('data-theme') !== 'light';
        var next = isDark ? 'light' : 'dark';
        if (next === 'dark') { html.removeAttribute('data-theme'); }
        else { html.setAttribute('data-theme', next); }
        localStorage.setItem('idash_theme', next === 'dark' ? '' : 'light');
        updateThemeBtn();
    }
    function updateThemeBtn() {
        var btn = document.getElementById('themeToggleBtn');
        if (!btn) return;
        var isLight = document.documentElement.getAttribute('data-theme') === 'light';
        btn.textContent = isLight ? '🌙' : '☀️';
        btn.title = isLight ? 'Switch to dark mode' : 'Switch to light mode';
    }
    (function() { updateThemeBtn(); })();

    var fixedReaderActive = false;

    function getFilters() {
        return {
            search:   $('#txtSearch').val().trim(),
            site:     $('#DdlCompany').val() || '0',
            status:   $('#ddlStatus').val(),
            cmr:      $('#txtCmr').val().trim(),
            location: $('#txtLocation').val().trim(),
            days:     $('#txtDays').val().trim(),
            fixedReader: fixedReaderActive ? ($('#ddlFrRange').val() || 'month') : ''
        };
    }

    function toggleFixedReaderReport() {
        fixedReaderActive = !fixedReaderActive;
        var btn = document.getElementById('btnFixedReader');
        var ddl = document.getElementById('ddlFrRange');
        if (fixedReaderActive) {
            btn.classList.add('nav-pill-primary--active');
            btn.innerHTML = '&#128225; Fixed Reader &#10003;';
            ddl.style.display = 'block';
            // Auto-enable observation columns
            ALL_COLS.forEach(function(c) {
                if (c.key === 'lastobservedtime' || c.key === 'lastobservedlocation') c.visible = true;
            });
            buildColumnSelector();
        } else {
            btn.classList.remove('nav-pill-primary--active');
            btn.innerHTML = '&#128225; Fixed Reader Report';
            ddl.style.display = 'none';
        }
        reloadGrid();
    }

    function applyFixedReaderRange() {
        if (fixedReaderActive) reloadGrid();
    }

    function clearFilters() {
        $('#txtSearch').val('');
        $('#DdlCompany').val('0');
        $('#ddlStatus').val('IN USE');
        $('#txtCmr').val('');
        $('#txtLocation').val('');
        $('#txtDays').val('');
        // Clear per-column search
        $('#searchRow input').val('');
        reloadGrid();
    }

    function clearWatchFilter() {
        var banner = document.getElementById('watchFilterBanner');
        if (banner) banner.remove();
        clearFilters();
        // Clean URL without reloading
        try { history.replaceState(null, '', 'va_asset_master.aspx'); } catch(e) {}
    }

    // ============================================================ GRID ============================================================
    function initGrid() {
    // ===================== Build header  prepend print checkbox column =====================
        var headerHtml = '<th class="chk-print-col"><input type="checkbox" id="chkAllPrint" onclick="toggleAllPrint(this);" title="Select All for Print" /></th>';
        var searchHtml = '<th class="chk-print-col"></th>';
        ALL_COLS.forEach(function (col) {
            headerHtml += '<th>' + col.label + '</th>';
            searchHtml += '<th><input class="col-search" type="text" placeholder="..." /></th>';
        });
        $('#headerRow').html(headerHtml);
        $('#searchRow').html(searchHtml);

        var initialOrder = [[1, 'asc']];
        try {
            var savedSort = localStorage.getItem('AssetMasterSort');
            if (savedSort) {
                var s = JSON.parse(savedSort);
                var idx = ALL_COLS.findIndex(function(c) { return c.key === s.key; });
                if (idx >= 0) {
                    initialOrder = [[idx + 1, s.dir]];
                }
            }
        } catch(e) {}

        dt = $('#assetGrid').DataTable({
            processing: true,
            serverSide: true,
            order: initialOrder,
            ajax: function (data, callback, settings) {
                showLoading(true);
                var filters = getFilters();

                // Gather per-column search values (offset by 1 for checkbox column)
                var colSearch = {};
                ALL_COLS.forEach(function (col, i) {
                    // data.columns[0] is the checkbox col; real cols start at index 1
                    var colData = data.columns[i + 1];
                    var val = colData ? colData.search.value : '';
                    if (val) colSearch[col.key] = val;
                });

                var sortCol = data.order && data.order.length > 0 ? data.order[0].column : 1;
                // Adjust sort col index: subtract 1 to skip checkbox column
                var sortColAdj = Math.max(0, sortCol - 1);
                var sortDir = data.order && data.order.length > 0 ? data.order[0].dir : 'asc';

                $.ajax({
                    type: 'POST',
                    url: 'va_asset_master.aspx/SearchAssets',
                    contentType: 'application/json; charset=utf-8',
                    data: JSON.stringify({
                        draw: data.draw,
                        start: data.start,
                        length: data.length,
                        search: filters.search,
                        site: filters.site,
                        status: filters.status,
                        cmr: filters.cmr,
                        location: filters.location,
                        days: filters.days,
                        fixedReader: filters.fixedReader,
                        sortCol: ALL_COLS[sortColAdj] ? ALL_COLS[sortColAdj].key : 'name',
                        sortDir: sortDir,
                        colSearch: colSearch
                    }),
                    success: function (resp) {
                        var result = JSON.parse(resp.d);
                        callback({
                            draw: result.draw,
                            recordsTotal: result.recordsTotal,
                            recordsFiltered: result.recordsFiltered,
                            data: result.data
                        });
                        showLoading(false);
                        updateKpis(result.kpis);
                        $('#gridInfo').text(fmtN(result.recordsFiltered) + ' of ' + fmtN(result.recordsTotal) + ' assets');
                        // Uncheck select-all when grid reloads
                        var chkAll = document.getElementById('chkAllPrint');
                        if (chkAll) chkAll.checked = false;
                        updatePrintBtnAM();
                    },
                    error: function (xhr) {
                        showLoading(false);
                        console.error('Search error:', xhr.responseText);
                        callback({ draw: data.draw, recordsTotal: 0, recordsFiltered: 0, data: [] });
                    }
                });
            },
            columns: [{
    // ==================== Checkbox column  not orderable or searchable ====================
                data: null,
                orderable: false,
                searchable: false,
                className: 'chk-print-col',
                render: function (data, type, row) {
                    var assetId = (row && row.id) ? row.id : 0;
                    var assetName = (row && row.name) ? row.name.replace(/'/g, "\\'") : '';
                    return '<input type="checkbox" class="chk-print" value="' + assetId + '" data-name="' + assetName + '" data-tagtype="" ' + (assetId === 0 ? 'disabled' : '') + ' />';
                }
            }].concat(ALL_COLS.map(function (col) {
                return {
                    data: col.key,
                    visible: col.visible,
                    render: function (data, type, row) {
                        if (data === null || data === undefined) return '';
                        if (col.key === 'listvalue1' && data) {
                            var cls = data === 'IN USE' ? 'pct-good' : (data === 'TURNED IN' ? 'pct-warn' : (data === 'LOST OR STOLEN' ? 'pct-bad' : ''));
                            return '<span class="' + cls + '">' + data + '</span>';
                        }
                        if ((col.key === 'lastinventoried' || col.key === 'lastobservedtime') && data) {
                            // Handle .NET /Date(timestamp)/ format
                            var match = String(data).match(/\/Date\((-?\d+)\)\//);
                            var d = match ? new Date(parseInt(match[1])) : new Date(data);
                            if (!isNaN(d.getTime())) {
                                var mm = ('0'+(d.getMonth()+1)).slice(-2);
                                var dd = ('0'+d.getDate()).slice(-2);
                                if (col.key === 'lastobservedtime') {
                                    var hh = d.getHours(); var ap = hh >= 12 ? 'PM' : 'AM';
                                    hh = hh % 12 || 12;
                                    var mn = ('0'+d.getMinutes()).slice(-2);
                                    return mm+'/'+dd+'/'+d.getFullYear()+' '+hh+':'+mn+' '+ap;
                                }
                                return mm+'/'+dd+'/'+d.getFullYear();
                            }
                        }
                        if (col.key === 'text18') {
                            var v = data ? String(data).trim().toLowerCase() : '';
                            if (v === '1' || v === 'true') {
                                return '<span style="color:var(--accent-2);font-weight:700;font-size:11px;">&#10003; Tagged</span>';
                            }
                            return '<span style="color:var(--muted);font-size:11px;">&#8211; Not Tagged</span>';
                        }
                        if (col.key === 'locationname' && data) {
                            return '<a href="#" onclick="filterByLocation(\'' + data.replace(/'/g, "\\'") + '\'); return false;" style="color:var(--accent);font-weight:600;">' + data + '</a>';
                        }

                        return data;
                    }
                };
            })),
            pageLength: 50,
            lengthMenu: [25, 50, 100, 200],
            dom: 'lrtip',
            orderCellsTop: true,
            deferRender: true,
            language: {
                processing: 'Loading...',
                emptyTable: 'No assets found matching your filters.',
                info: 'Showing _START_ to _END_ of _TOTAL_ assets',
                infoFiltered: '(filtered from _MAX_ total)',
                lengthMenu: '_MENU_ per page'
            }
        });

        // Save sort state when user sorts
        $('#assetGrid').on('order.dt', function () {
            if (dt) {
                var order = dt.order();
                if (order && order.length > 0) {
                    var colIdx = order[0][0] - 1; // subtract 1 for checkbox column
                    if (colIdx >= 0 && ALL_COLS[colIdx]) {
                        try {
                            localStorage.setItem('AssetMasterSort', JSON.stringify({
                                key: ALL_COLS[colIdx].key,
                                dir: order[0][1]
                            }));
                        } catch(e) {}
                    }
                }
            }
        });

        // Per-column search - use DT column-by-node to avoid index mismatch
        // when hidden columns shift the visible th index vs the DT internal index
        $('#searchRow th').each(function () {
            var th = this;
            $('input', th).on('keyup change', function () {
                var col = dt.column(th);
                if (col.search() !== this.value) {
                    col.search(this.value).draw();
                }
            });
        });

        // Delegate change events on chk-print checkboxes
        $('#assetGrid').on('change', '.chk-print', function () {
            updatePrintBtnAM();
        });
    }

    function reloadGrid() {
        if (dt) dt.ajax.reload();
    }

    function filterByLocation(loc) {
        $('#txtLocation').val(loc);
        reloadGrid();
    }

    // ====================================================== KPI UPDATE ======================================================
    function updateKpis(kpis) {
        if (!kpis) return;
        animTo('kv-total', kpis.total);
        animTo('kv-locs', kpis.locations);
        animTo('kv-cmr', kpis.withCmr);
        animTo('kv-recent', kpis.recent);
        animTo('kv-overdue', kpis.overdue);

        var t = kpis.total || 1;
        setText('kp-cmr', pctStr(kpis.withCmr, t));
        setText('kp-recent', pctStr(kpis.recent, t));
        setText('kp-overdue', pctStr(kpis.overdue, t));
    }

    function animTo(id, n) {
        var el = document.getElementById(id); if (!el) return;
        var t0 = null, fmt = new Intl.NumberFormat();
        function step(t) { if (!t0) t0 = t; var p = Math.min((t - t0) / 700, 1); el.textContent = fmt.format(Math.round(p * n)); if (p < 1) requestAnimationFrame(step); }
        requestAnimationFrame(step);
    }

    function setText(id, v) { var el = document.getElementById(id); if (el) el.textContent = v; }
    function fmtN(n) { return new Intl.NumberFormat().format(n); }
    function pctStr(v, t) { return t > 0 ? (v / t * 100).toFixed(1) + '%' : '0%'; }

    function exportData(fmt) {
        var checked = document.querySelectorAll('#assetGrid .chk-print:checked');
        var selectedIds = [];
        checked.forEach(function (cb) {
            if (cb.value && cb.value !== '0') selectedIds.push(cb.value);
        });

        var cols = getVisibleKeys().join(',');

        if (selectedIds.length > 0) {
            // Post via hidden form so there is no query string length limitation
            var form = document.createElement('form');
            form.method = 'POST';
            form.action = 'va_asset_master.aspx?export=1';

            var addHidden = function(name, val) {
                var input = document.createElement('input');
                input.type = 'hidden';
                input.name = name;
                input.value = val;
                form.appendChild(input);
            };

            addHidden('fmt', fmt);
            addHidden('ids', selectedIds.join(','));
            addHidden('cols', cols);

            document.body.appendChild(form);
            form.submit();
            document.body.removeChild(form);
            return;
        }

        var filters = getFilters();
        var params = new URLSearchParams({
            fmt: fmt,
            search: filters.search,
            site: filters.site,
            status: filters.status,
            cmr: filters.cmr,
            location: filters.location,
            days: filters.days,
            fixedReader: filters.fixedReader,
            cols: cols
        });
        window.location.href = 'va_asset_master.aspx?export=1&' + params.toString();
    }

    // ========================================================= LOADING =========================================================
    function showLoading(b) {
        document.getElementById('loadingOverlay').classList.toggle('show', b);
    }

    // ============================================================
    // ===================================================== PRINT MODAL =====================================================
    // ============================================================
    // PRINT MODAL LOGIC
    // ============================================================
    var printPrefix = '';
    var printPreviewData = [];
    var printTemplatesLoaded = false;
    var _cachedSitePrefix = {};
    var _currentModalSiteId = '0';
    var _explicitAssetNames = null;

    function openPrintModal(targetSiteId, onPrefixReady) {
        if (typeof targetSiteId === 'function') {
            onPrefixReady = targetSiteId;
            targetSiteId = null;
        }

        var overlay = document.getElementById('printOverlay');
        overlay.classList.add('show');
        document.body.style.overflow = 'hidden';
        setPmStatus('', '');
        document.getElementById('pmNumbers').value = '';
        document.getElementById('btnSubmitPrint').style.display = 'none';
        document.getElementById('pmPreviewHeader').style.display = 'none';
        document.getElementById('pmTableWrap').style.display = 'none';
        printPreviewData = [];
        _explicitAssetNames = null;

        _currentModalSiteId = targetSiteId || $('#DdlCompany').val() || '0';

        // Listen for manual number edits to clear explicit asset override
        var pmInput = document.getElementById('pmNumbers');
        if (pmInput) {
            pmInput.oninput = function () { _explicitAssetNames = null; };
        }

        // Load prefix for target site, then invoke callback if provided
        loadSitePrefix(_currentModalSiteId, onPrefixReady);

        // Load templates once
        if (!printTemplatesLoaded) loadPrintTemplates();
    }

    function closePrintModal() {
        document.getElementById('printOverlay').classList.remove('show');
        document.body.style.overflow = '';
        _explicitAssetNames = null;
    }

    function setPmStatus(msg, type) {
        var el = document.getElementById('pmStatus');
        el.className = 'pm-status' + (type ? ' ' + type : '');
        el.textContent = msg;
    }

    function loadSitePrefix(targetSiteId, callback) {
        if (typeof targetSiteId === 'function') {
            callback = targetSiteId;
            targetSiteId = null;
        }
        var siteId = targetSiteId || _currentModalSiteId || $('#DdlCompany').val() || '0';
        if (siteId === '0') {
            document.getElementById('pmPrefix').textContent = '(Select a site first)';
            printPrefix = '';
            if (typeof callback === 'function') callback(printPrefix);
            return;
        }

        if (_cachedSitePrefix[siteId] !== undefined) {
            printPrefix = _cachedSitePrefix[siteId];
            document.getElementById('pmPrefix').textContent = printPrefix || '(No prefix configured)';
            if (typeof callback === 'function') callback(printPrefix);
            return;
        }

        $.ajax({
            type: 'POST',
            url: 'va_asset_master.aspx/GetSitePrefix',
            contentType: 'application/json; charset=utf-8',
            data: JSON.stringify({ siteId: siteId }),
            success: function (resp) {
                var r = JSON.parse(resp.d);
                printPrefix = r.prefix || '';
                _cachedSitePrefix[siteId] = printPrefix;
                document.getElementById('pmPrefix').textContent = printPrefix || '(No prefix configured)';
                if (typeof callback === 'function') callback(printPrefix);
            },
            error: function () {
                document.getElementById('pmPrefix').textContent = '(Error loading prefix)';
                printPrefix = '';
                if (typeof callback === 'function') callback(printPrefix);
            }
        });
    }

    function loadPrintTemplates() {
        $.ajax({
            type: 'POST',
            url: 'va_asset_master.aspx/GetPrintTemplates',
            contentType: 'application/json; charset=utf-8',
            data: '{}',
            success: function (resp) {
                var r = JSON.parse(resp.d);
                var sel = document.getElementById('pmTemplate');
                sel.innerHTML = '';
                if (r.templates && r.templates.length > 0) {
                    r.templates.forEach(function (t) {
                        var opt = document.createElement('option');
                        opt.value = t.id;
                        opt.textContent = t.name;
                        sel.appendChild(opt);
                    });
                } else {
                    sel.innerHTML = '<option value="">No templates found</option>';
                }
                printTemplatesLoaded = true;
            },
            error: function () {
                document.getElementById('pmTemplate').innerHTML = '<option value="">Error loading</option>';
            }
        });
    }

    // == Parse input: supports single (5), range (1-25), comma-separated (1,3,5), and combos (1-5, 8, 12-15) ==
    function parsePrintInput(input) {
        if (!input || !input.trim()) return [];
        var numbers = [];
        var parts = input.split(',');
        for (var i = 0; i < parts.length; i++) {
            var part = parts[i].trim();
            if (!part) continue;
            var rangeParts = part.split('-');
            if (rangeParts.length === 2) {
                var from = parseInt(rangeParts[0].trim(), 10);
                var to = parseInt(rangeParts[1].trim(), 10);
                if (!isNaN(from) && !isNaN(to) && from <= to) {
                    if (to - from > 500) { to = from + 500; } // safety cap
                    for (var n = from; n <= to; n++) numbers.push(n);
                }
            } else {
                var num = parseInt(part, 10);
                if (!isNaN(num)) numbers.push(num);
            }
        }
        // Deduplicate and sort
        var unique = [];
        var seen = {};
        numbers.forEach(function (n) {
            if (!seen[n]) { unique.push(n); seen[n] = true; }
        });
        return unique.sort(function (a, b) { return a - b; });
    }

    function loadPrintPreview() {
        var input = document.getElementById('pmNumbers').value;
        var nums = parsePrintInput(input);

        if (nums.length === 0 && (!_explicitAssetNames || _explicitAssetNames.length === 0)) {
            setPmStatus('Enter at least one asset number (e.g. 1, 3-25, 42).', 'error');
            return;
        }
        if (!printPrefix && (!_explicitAssetNames || _explicitAssetNames.length === 0)) {
            setPmStatus('No site prefix available. Please select a site with a configured prefix.', 'error');
            return;
        }

        // Build full asset names
        var assetNames = (_explicitAssetNames && _explicitAssetNames.length > 0)
            ? _explicitAssetNames
            : nums.map(function (n) { return printPrefix + n; });

        setPmStatus('Loading ' + assetNames.length + ' assets...', 'info');
        document.getElementById('btnSubmitPrint').style.display = 'none';

        $.ajax({
            type: 'POST',
            url: 'va_asset_master.aspx/GetAssetsForPrint',
            contentType: 'application/json; charset=utf-8',
            data: JSON.stringify({
                siteId: _currentModalSiteId || $('#DdlCompany').val() || '0',
                assetNamesJson: JSON.stringify(assetNames)
            }),
            success: function (resp) {
                var r = JSON.parse(resp.d);
                if (r.error) {
                    setPmStatus('Error: ' + r.error, 'error');
                    return;
                }
                printPreviewData = r.data || [];
                var notFound = r.notFound || [];

                if (printPreviewData.length === 0) {
                    setPmStatus('No matching assets found for the entered numbers.', 'error');
                    document.getElementById('pmPreviewHeader').style.display = 'none';
                    document.getElementById('pmTableWrap').style.display = 'none';
                    return;
                }

                var msg = 'Found ' + printPreviewData.length + ' of ' + assetNames.length + ' assets.';
                if (notFound.length > 0) {
                    msg += ' Not found: ' + notFound.join(', ');
                    setPmStatus(msg, 'warn');
                } else {
                    setPmStatus(msg, 'success');
                }

                renderPrintPreview();
                document.getElementById('btnSubmitPrint').style.display = '';
            },
            error: function (xhr) {
                setPmStatus('Request failed: ' + (xhr.responseText || 'Unknown error'), 'error');
            }
        });
    }

    function renderPrintPreview() {
        // Use the same ALL_COLS visibility as main grid
        var visCols = ALL_COLS.filter(function (c) { return c.visible; });

        // Build header
        var hdr = '';
        visCols.forEach(function (col) { hdr += '<th>' + col.label + '</th>'; });
        document.getElementById('pmHeaderRow').innerHTML = hdr;

        // Build body
        var body = '';
        printPreviewData.forEach(function (row) {
            body += '<tr>';
            visCols.forEach(function (col) {
                var val = row[col.key];
                if (val === null || val === undefined) val = '';

                // Reuse rendering logic from main grid
                if (col.key === 'listvalue1' && val) {
                    var cls = val === 'IN USE' ? 'pct-good' : (val === 'TURNED IN' ? 'pct-warn' : (val === 'LOST OR STOLEN' ? 'pct-bad' : ''));
                    val = '<span class="' + cls + '">' + val + '</span>';
                } else if ((col.key === 'lastinventoried' || col.key === 'lastobservedtime') && val) {
                    var match = String(val).match(/\/Date\((-?\d+)\)\//);
                    var d = match ? new Date(parseInt(match[1])) : new Date(val);
                    if (!isNaN(d.getTime())) {
                        var mm = ('0'+(d.getMonth()+1)).slice(-2);
                        var dd = ('0'+d.getDate()).slice(-2);
                        val = mm+'/'+dd+'/'+d.getFullYear();
                    }
                }
                body += '<td>' + val + '</td>';
            });
            body += '</tr>';
        });
        document.getElementById('pmBody').innerHTML = body;

        document.getElementById('pmCount').textContent = printPreviewData.length + ' asset' + (printPreviewData.length !== 1 ? 's' : '');
        document.getElementById('pmPreviewHeader').style.display = 'flex';
        document.getElementById('pmTableWrap').style.display = '';
    }

    function submitPrintJobs() {
        if (printPreviewData.length === 0) {
            setPmStatus('No assets loaded. Load a preview first.', 'error');
            return;
        }
        var templateId = document.getElementById('pmTemplate').value;
        if (!templateId) {
            setPmStatus('Please select a print template.', 'error');
            return;
        }

        var assetNames = printPreviewData.map(function (r) { return r.name; });

        if (!confirm('Send ' + assetNames.length + ' asset(s) to the printer?')) return;

        setPmStatus('Submitting ' + assetNames.length + ' print job(s)...', 'info');
        document.getElementById('btnSubmitPrint').disabled = true;

        $.ajax({
            type: 'POST',
            url: 'va_asset_master.aspx/SubmitPrintJobs',
            contentType: 'application/json; charset=utf-8',
            data: JSON.stringify({
                siteId: $('#DdlCompany').val() || '0',
                assetNamesJson: JSON.stringify(assetNames),
                templateId: parseInt(templateId, 10)
            }),
            success: function (resp) {
                var r = JSON.parse(resp.d);
                document.getElementById('btnSubmitPrint').disabled = false;
                if (r.success) {
                    var msg = 'Successfully created ' + r.jobsCreated + ' print job(s).';
                    if (r.errors && r.errors.length > 0) {
                        msg += ' Errors: ' + r.errors.join('; ');
                        setPmStatus(msg, 'warn');
                    } else {
                        setPmStatus(msg, 'success');
                    }
                } else {
                    setPmStatus('Print submission failed: ' + (r.error || 'Unknown error'), 'error');
                }
            },
            error: function (xhr) {
                document.getElementById('btnSubmitPrint').disabled = false;
                setPmStatus('Request failed: ' + (xhr.responseText || 'Unknown error'), 'error');
            }
        });
    }

    // Re-load prefix when site dropdown changes (the existing change handler calls reloadGrid)
    var origDdlChange = null;
    $(document).ready(function () {
        $('#DdlCompany').on('change.print', function () {
            if (document.getElementById('printOverlay').classList.contains('show')) {
                loadSitePrefix();
            }
        });

        // Allow Enter key in the numbers input to trigger preview
        $('#pmNumbers').on('keydown', function (e) {
            if (e.key === 'Enter') { e.preventDefault(); loadPrintPreview(); }
        });

        // Init print templates for the grid selection bar
        initPrintTemplatesAM();
    });

    // ============================================================
    // ==== GRID PRINT CHECKBOX FUNCTIONS (mirrors TagTeam Scan pattern) ====
    // ============================================================

    function toggleAllPrint(source) {
        var checkboxes = document.querySelectorAll('#assetGrid .chk-print:not([disabled])');
        checkboxes.forEach(function (cb) { cb.checked = source.checked; });
        updatePrintBtnAM();
    }

    function updatePrintBtnAM() {
        var checked = document.querySelectorAll('#assetGrid .chk-print:checked');
        var bar    = document.getElementById('printSelectionBar');
        var btnSrv = document.getElementById('BtnPrintCheckedAM');
        var btnExp = document.getElementById('BtnExportExcelCheckedAM');
        var btnTop = document.getElementById('btnExportTop');
        var lblCnt = document.getElementById('psSelectedCount');
        var ddlTpl = document.getElementById('DdlPrintTemplateAM');
        var ddlTgt = document.getElementById('DdlPrintTargetAM');

        var n = checked.length;
        if (lblCnt) lblCnt.textContent = n;
        if (n > 0) {
            bar.classList.add('show');
            if (btnSrv) btnSrv.innerText = 'Server Print (' + n + ')';
            if (btnExp) btnExp.innerHTML = '&#128190; Export Selected Excel (' + n + ')';
            if (btnTop) btnTop.innerHTML = '&#128190; Export Excel (' + n + ' selected)';
            if (ddlTpl) ddlTpl.style.display = 'inline-block';
            if (ddlTgt) ddlTgt.style.display = 'inline-block';
        } else {
            bar.classList.remove('show');
            if (btnTop) btnTop.innerHTML = '&#128190; Export Excel';
            if (ddlTpl) ddlTpl.style.display = 'none';
            if (ddlTgt) ddlTgt.style.display = 'none';
        }
    }

    function initPrintTemplatesAM() {
        if (!window.awPrintConfigAM || !window.awPrintConfigAM.printTemplates) return;
        try {
            var ddlTpl = document.getElementById('DdlPrintTemplateAM');
            if (ddlTpl && ddlTpl.options.length <= 1) {
                window.awPrintConfigAM.printTemplates.forEach(function (t) {
                    ddlTpl.options.add(new Option(t.name + ' (ID: ' + t.id + ')', t.id));
                });
                var savedTpl = localStorage.getItem('aw_am_print_tpl');
                if (savedTpl) ddlTpl.value = savedTpl;
                ddlTpl.addEventListener('change', function () { localStorage.setItem('aw_am_print_tpl', this.value); });
            }
            var ddlTgt = document.getElementById('DdlPrintTargetAM');
            if (ddlTgt && ddlTgt.options.length <= 1 && window.awPrintConfigAM.availableClients) {
                window.awPrintConfigAM.availableClients.forEach(function (c) {
                    ddlTgt.options.add(new Option('Client: ' + c, c));
                });
                var savedTgt = localStorage.getItem('aw_am_print_tgt');
                if (savedTgt) ddlTgt.value = savedTgt;
                ddlTgt.addEventListener('change', function () { localStorage.setItem('aw_am_print_tgt', this.value); });
            }
        } catch (e) {
            console.error('[AssetMaster] Failed to setup print templates', e);
        }
    }

    async function printCheckedTagsAM() {
        var checked = document.querySelectorAll('#assetGrid .chk-print:checked');
        if (checked.length === 0) { alert('Please select at least one asset.'); return; }

        var cfg = window.awPrintConfigAM;
        if (!cfg || !cfg.printTemplates || cfg.printTemplates.length === 0) {
            alert('Print templates not loaded. Please refresh the page.');
            return;
        }

        var ddlTpl = document.getElementById('DdlPrintTemplateAM');
        var ddlTgt = document.getElementById('DdlPrintTargetAM');
        var forceTplId = ddlTpl && ddlTpl.value ? parseInt(ddlTpl.value, 10) : null;
        var forceTgt   = ddlTgt && ddlTgt.value ? ddlTgt.value : null;

        var payload = [];
        checked.forEach(function (cb) {
            var assetId = parseInt(cb.value, 10);
            var tagType = cb.getAttribute('data-tagtype') || '';

            var match = null;
            var targetType  = 'Default';
            var targetValue = '';

            if (forceTplId) {
                match = cfg.printTemplates.find(function (t) { return t.id === forceTplId; });
            } else {
                if (cfg.templateMappings && cfg.templateMappings[tagType]) {
                    var mapObj = cfg.templateMappings[tagType];
                    var mappedId = (typeof mapObj === 'object') ? mapObj.TemplateID : parseInt(mapObj, 10);
                    if (typeof mapObj === 'object') {
                        targetType  = mapObj.TargetType  || 'Default';
                        targetValue = mapObj.TargetValue || '';
                    }
                    match = cfg.printTemplates.find(function (t) { return t.id === mappedId; });
                }
                if (!match) match = cfg.printTemplates.find(function (t) { return t.name === tagType; });
                if (!match && cfg.printTemplates.length > 0) match = cfg.printTemplates[0];
            }

            if (match && !isNaN(assetId) && assetId > 0) {
                var routingService = (cfg.templateRoutes && cfg.templateRoutes[match.id]) ? cfg.templateRoutes[match.id] : (match.useWithService || 'print');
                if (targetType === 'Client' && targetValue.length > 0) routingService = targetValue;
                if (targetType === 'Service' && targetValue.length > 0) routingService = targetValue;
                if (forceTgt) routingService = forceTgt;

                payload.push({
                    recordID: assetId,
                    templateID: match.id,
                    tableName: 'Asset',
                    useWithService: routingService,
                    completed: false
                });
            } else {
                console.warn('[AssetMaster] Invalid print: assetId=' + assetId + ' tagType=' + tagType);
            }
        });

        if (payload.length === 0) {
            alert('Could not build valid print payload. Check template configuration.');
            return;
        }

        var btn = document.getElementById('BtnPrintCheckedAM');
        var origText = btn ? btn.innerText : '';
        if (btn) { btn.innerText = 'Printing...'; btn.disabled = true; }

        try {
            var resp = await fetch('va_asset_master.aspx?action=print', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=utf-8' },
                body: JSON.stringify(payload)
            });
            if (resp.ok) {
                alert('Sent ' + payload.length + ' tag(s) to print successfully.');
                checked.forEach(function (cb) { cb.checked = false; });
                var chkAll = document.getElementById('chkAllPrint');
                if (chkAll) chkAll.checked = false;
                updatePrintBtnAM();
            } else {
                alert('Print API returned an error: ' + resp.status);
            }
        } catch (e) {
            alert('Error calling print service: ' + e.message);
        }
        if (btn) { btn.innerText = origText; btn.disabled = false; }
    }


    // ============================================================
    // ASSET DETAIL PANEL
    // ============================================================
    var _dpCurrentId = null;
    var _dpCache = {}; // cache loaded tab data per asset

    // ========================================== Row click  open detail ==========================================
    $(document).on('click', '#assetGrid tbody tr', function (e) {
        // Don't trigger on checkbox click or link click
        if ($(e.target).is('input, a') || $(e.target).closest('a').length) return;

        var data = dt.row(this).data();
        if (!data || !data.id) return;

        // Highlight row
        $('#assetGrid tbody tr').removeClass('row-selected');
        $(this).addClass('row-selected');

        openDetail(data.id, data.name);
    });

    function openDetail(assetId, assetName) {
        _dpCurrentId = assetId;
        _dpCache = {};

        // Set title and edit link
        document.getElementById('dpTitle').textContent = assetName || 'Asset Detail';
        document.getElementById('dpEditLink').href = '/#!/admin/editasset/' + assetId;

        // Reset badges
        ['badgeLoc','badgeCO','badgeMnt','badgeChild'].forEach(function(id) {
            document.getElementById(id).textContent = '--';
        });

        // Reset to General tab
        document.querySelectorAll('.dp-tab').forEach(function(t) { t.classList.remove('active'); });
        document.querySelector('.dp-tab[data-tab="general"]').classList.add('active');
        document.querySelectorAll('.dp-tab-content').forEach(function(c) { c.classList.remove('active'); });
        document.getElementById('tab-general').classList.add('active');

        // Show panel
        document.getElementById('detailPanel').classList.add('open');
        document.body.classList.add('detail-open');

        // Load General tab
        loadGeneralTab(assetId);

        // Prefetch counts for other tabs
        loadTabCounts(assetId);
    }

    function closeDetail() {
        document.getElementById('detailPanel').classList.remove('open');
        document.body.classList.remove('detail-open');
        $('#assetGrid tbody tr').removeClass('row-selected');
        _dpCurrentId = null;
    }

    // ========================================= Escape key closes panel =========================================
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && _dpCurrentId) closeDetail();
    });


    // =================================================== Tab switching ===================================================
    function switchTab(btn) {
        var tab = btn.getAttribute('data-tab');
        document.querySelectorAll('.dp-tab').forEach(function(t) { t.classList.remove('active'); });
        btn.classList.add('active');
        document.querySelectorAll('.dp-tab-content').forEach(function(c) { c.classList.remove('active'); });
        document.getElementById('tab-' + tab).classList.add('active');
        if (!_dpCache[tab]) {
            switch(tab) {
                case 'general':     loadGeneralTab(_dpCurrentId); break;
                case 'lochistory':  loadLocationHistory(_dpCurrentId); break;
                case 'checkout':    loadCheckoutHistory(_dpCurrentId); break;
                case 'maintenance': loadMaintenanceHistory(_dpCurrentId); break;
                case 'children':    loadChildren(_dpCurrentId); break;
            }
        }
    }

    // ================================================= Date formatters =================================================
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

    // ========================================== Editable field helpers ==========================================
    var _dpEditMode = false;
    var _dpOriginal = {};
    var STATUS_OPTIONS = ['IN USE','TURNED IN','LOST OR STOLEN','OUT OF SERVICE','LOANED OUT','In Service'];
    var CHECKOUT_OPTIONS = ['Checked In','Checked Out'];

    function dpField(label, value, editKey) {
        var cls = (value === null || value === undefined || value === '') ? 'dp-val empty' : 'dp-val';
        var display = (value === null || value === undefined || value === '') ? '&#8212;' : String(value).replace(/</g, '&lt;');
        var safeVal = (value === null || value === undefined) ? '' : String(value).replace(/"/g, '&quot;');
        if (_dpEditMode && editKey) {
            _dpOriginal[editKey] = safeVal;
            if (editKey === 'listvalue1') {
                var opts = '<option value="">&#8212; None &#8212;</option>';
                STATUS_OPTIONS.forEach(function(s) { opts += '<option value="' + s + '"' + (s === safeVal ? ' selected' : '') + '>' + s + '</option>'; });
                return '<div class="dp-field" data-key="' + editKey + '"><label>' + label + '</label><select class="dp-select" data-key="' + editKey + '" onchange="markDirty(this)">' + opts + '</select></div>';
            }
            if (editKey === 'checkinstatus') {
                var opts = '<option value="">&#8212; None &#8212;</option>';
                CHECKOUT_OPTIONS.forEach(function(s) { opts += '<option value="' + s + '"' + (s === safeVal ? ' selected' : '') + '>' + s + '</option>'; });
                return '<div class="dp-field" data-key="' + editKey + '"><label>' + label + '</label><select class="dp-select" data-key="' + editKey + '" onchange="markDirty(this)">' + opts + '</select></div>';
            }
            if (editKey === 'additionalinformation') {
                return '<div class="dp-field" data-key="' + editKey + '"><label>' + label + '</label><textarea class="dp-textarea" data-key="' + editKey + '" oninput="markDirty(this)">' + safeVal + '</textarea></div>';
            }
            return '<div class="dp-field" data-key="' + editKey + '"><label>' + label + '</label><input class="dp-input" type="text" data-key="' + editKey + '" value="' + safeVal + '" oninput="markDirty(this)" /></div>';
        }
        return '<div class="dp-field"><label>' + label + '</label><div class="' + cls + '">' + display + '</div></div>';
    }

    function markDirty(el) {
        var key = el.getAttribute('data-key');
        var orig = _dpOriginal[key] || '';
        var field = el.closest('.dp-field');
        if (el.value !== orig) { field.classList.add('dirty'); } else { field.classList.remove('dirty'); }
        updateDirtyCount();
    }
    function updateDirtyCount() {
        var count = document.querySelectorAll('#tab-general .dp-field.dirty').length;
        document.getElementById('dpDirtyCount').textContent = count;
        document.getElementById('dpSaveBar').classList.toggle('show', count > 0);
    }

    // ===================================================== GENERAL TAB =====================================================
    function loadGeneralTab(assetId) {
        var el = document.getElementById('tab-general');
        el.innerHTML = '<div class="dp-loading">Loading...</div>';
        _dpOriginal = {};
        $.getJSON('va_asset_master.aspx?api=detail&id=' + assetId, function(data) {
            if (data.error) { el.innerHTML = '<div class="dp-empty">' + data.error + '</div>'; return; }
            _dpCache.general = data.asset;
            renderGeneralTab(data.asset);
        }).fail(function() { el.innerHTML = '<div class="dp-empty">Failed to load asset details.</div>'; });
    }

    function renderGeneralTab(a) {
        var el = document.getElementById('tab-general');
        _dpOriginal = {};
        var h = '';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Identity</div><div class="dp-fields">';
        h += dpField('Asset Name', a.name);
        h += dpField('Description', a.description, 'description');
        h += dpField('Asset Type', a.assettype);
        h += dpField('RFID Tag', a.rfidtag);
        h += dpField('CMR #', a.text8, 'text8');
        h += dpField('Serial #', a.text3, 'text3');
        h += '</div></div>';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Location</div><div class="dp-fields">';
        h += dpField('Current Location', a.locationname);
        h += dpField('Building', a.locationbuilding);
        h += dpField('Floor', a.locationfloor);
        h += dpField('Room', a.locationroom);
        h += dpField('Last Observed Location', a.lastobservedlocation);
        h += dpField('Last Observed Time', fmtDate(a.lastobservedtime));
        h += dpField('Nearest Fixed Reader', a.nearestfixedname);
        h += dpField('Department Code', a.departmentcode, 'departmentcode');
        h += '</div></div>';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Status &amp; Checkout</div><div class="dp-fields">';
        h += dpField('Status', a.listvalue1, 'listvalue1');
        h += dpField('Checkout Status', a.checkinstatus, 'checkinstatus');
        h += dpField('Checked Out To', a.checkedoutto, 'checkedoutto');
        h += dpField('Disposal Status', a.disposalstatus, 'disposalstatus');
        h += '</div></div>';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Details</div><div class="dp-fields">';
        h += dpField('Category', a.text4, 'text4');
        h += dpField('Manufacturer', a.text1, 'text1');
        h += dpField('Model', a.text2, 'text2');
        h += dpField('Service', a.text5, 'text5');
        h += dpField('Room', a.text6, 'text6');
        h += dpField('Station', a.text7, 'text7');
        h += dpField('PO #', a.text9, 'text9');
        h += dpField('Previous Location', a.text11, 'text11');
        h += '</div></div>';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Maintenance</div><div class="dp-fields">';
        h += dpField('Last Maintenance', fmtDateShort(a.lastmaintenance));
        h += dpField('Next Maintenance', fmtDateShort(a.nextmaintenance));
        h += dpField('Maintenance Method', a.maintenancemethod, 'maintenancemethod');
        h += dpField('Interval (Months)', a.maintenanceintervalmonths, 'maintenanceintervalmonths');
        h += '</div></div>';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Fixed Reader Observation</div><div class="dp-fields">';
        h += dpField('Last Observed', a.lastobservedtime ? fmtDate(a.lastobservedtime) : null);
        h += dpField('Observed Location', a.lastobservedlocation || null);
        h += '</div></div>';
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Inventory &amp; Dates</div><div class="dp-fields">';
        h += dpField('Last Inventoried', fmtDateShort(a.lastinventoried));
        h += dpField('Created', fmtDate(a.created));
        h += dpField('Last Modified', fmtDate(a.lastmodified));
        h += dpField('Modified By', a.lastmodifiedby);
        h += '</div></div>';
        if (a.vtagid) {
            h += '<div class="dp-field-group"><div class="dp-field-group-title">V-Tag Sensor</div><div class="dp-fields">';
            h += dpField('V-Tag ID', a.vtagid);
            h += dpField('V-Tag Type', a.vtagtype);
            h += dpField('Battery Level', a.batterylevel ? a.batterylevel + '%' : null);
            h += '</div></div>';
        }
        h += '<div class="dp-field-group"><div class="dp-field-group-title">Additional Information</div>';
        h += '<div class="dp-fields single">' + dpField('Notes', a.additionalinformation, 'additionalinformation') + '</div></div>';
        el.innerHTML = h;
        updateDirtyCount();
    }

    // ======================================================= EDIT MODE =======================================================
    function toggleEditMode() {
        _dpEditMode = !_dpEditMode;
        var btn = document.getElementById('dpEditToggle');
        btn.classList.toggle('editing', _dpEditMode);
        btn.innerHTML = _dpEditMode ? '&#10004; Editing' : '&#9998; Edit Mode';
        if (_dpCache.general) renderGeneralTab(_dpCache.general);
        if (!_dpEditMode) document.getElementById('dpSaveBar').classList.remove('show');
    }
    function cancelEdit() {
        _dpEditMode = false;
        document.getElementById('dpEditToggle').classList.remove('editing');
        document.getElementById('dpEditToggle').innerHTML = '&#9998; Edit Mode';
        document.getElementById('dpSaveBar').classList.remove('show');
        if (_dpCache.general) renderGeneralTab(_dpCache.general);
    }
    function saveAsset() {
        if (!_dpCurrentId) return;
        var dirtyFields = document.querySelectorAll('#tab-general .dp-field.dirty');
        if (dirtyFields.length === 0) return;
        var updates = {};
        dirtyFields.forEach(function(f) {
            var input = f.querySelector('.dp-input, .dp-select, .dp-textarea');
            if (input) updates[input.getAttribute('data-key')] = input.value;
        });
        var saveBtn = document.getElementById('dpSaveBtn');
        saveBtn.disabled = true; saveBtn.textContent = 'Saving...';
        $.ajax({
            type: 'POST', url: 'va_asset_master.aspx?api=update&id=' + _dpCurrentId,
            contentType: 'application/json', data: JSON.stringify(updates), dataType: 'json',
            success: function(resp) {
                if (resp.error) { showToast(resp.error, 'error'); }
                else {
                    showToast('Asset updated - ' + resp.updated + ' field(s) saved', 'success');
                    for (var k in updates) _dpCache.general[k] = updates[k];
                    _dpEditMode = false;
                    document.getElementById('dpEditToggle').classList.remove('editing');
                    document.getElementById('dpEditToggle').innerHTML = '&#9998; Edit Mode';
                    document.getElementById('dpSaveBar').classList.remove('show');
                    renderGeneralTab(_dpCache.general);
                    if (dt) dt.ajax.reload(null, false);
                }
                saveBtn.disabled = false; saveBtn.innerHTML = '&#128190; Save Changes';
            },
            error: function() {
                showToast('Network error - save failed', 'error');
                saveBtn.disabled = false; saveBtn.innerHTML = '&#128190; Save Changes';
            }
        });
    }
    function showToast(msg, type) {
        var t = document.createElement('div');
        t.className = 'dp-save-toast ' + (type || 'success');
        t.textContent = msg;
        document.body.appendChild(t);
        setTimeout(function() { t.remove(); }, 3000);
    }

    // ============================================= Prefetch tab counts =============================================
    function loadTabCounts(assetId) {
        $.getJSON('va_asset_master.aspx?api=locationhistory&id=' + assetId, function(d) {
            document.getElementById('badgeLoc').textContent = d.total || 0;
            if (d.total > 0) _dpCache.lochistory_data = d.records;
        });
        $.getJSON('va_asset_master.aspx?api=checkouthistory&id=' + assetId, function(d) {
            document.getElementById('badgeCO').textContent = d.total || 0;
            if (d.total > 0) _dpCache.checkout_data = d.records;
        });
        $.getJSON('va_asset_master.aspx?api=maintenance&id=' + assetId, function(d) {
            document.getElementById('badgeMnt').textContent = d.total || 0;
            if (d.total > 0) _dpCache.maintenance_data = d.records;
        });
        $.getJSON('va_asset_master.aspx?api=children&id=' + assetId, function(d) {
            document.getElementById('badgeChild').textContent = d.total || 0;
            if (d.total > 0) _dpCache.children_data = d.records;
        });
    }

    // ============================================ LOCATION HISTORY TAB ============================================
    function loadLocationHistory(assetId) {
        var el = document.getElementById('tab-lochistory');
        var records = _dpCache.lochistory_data;
        if (records) { renderLocationHistory(el, records); _dpCache.lochistory = true; return; }
        el.innerHTML = '<div class="dp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=locationhistory&id=' + assetId, function(d) { renderLocationHistory(el, d.records || []); _dpCache.lochistory = true; });
    }
    function renderLocationHistory(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="dp-empty"><span class="dp-empty-icon">&#128205;</span>No location history records found.</div>'; return; }
        var html = '<table class="dp-history-table"><thead><tr><th>Location</th><th>Building</th><th>Time Seen</th><th>Time Left</th></tr></thead><tbody>';
        records.forEach(function(r) { html += '<tr><td><strong>' + dpVal(r.locationname) + '</strong></td><td>' + dpVal(r.building) + '</td><td>' + fmtDate(r.timeseen) + '</td><td>' + fmtDate(r.timeleft) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // ============================================ CHECKOUT HISTORY TAB ============================================
    function loadCheckoutHistory(assetId) {
        var el = document.getElementById('tab-checkout');
        var records = _dpCache.checkout_data;
        if (records) { renderCheckoutHistory(el, records); _dpCache.checkout = true; return; }
        el.innerHTML = '<div class="dp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=checkouthistory&id=' + assetId, function(d) { renderCheckoutHistory(el, d.records || []); _dpCache.checkout = true; });
    }
    function renderCheckoutHistory(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="dp-empty"><span class="dp-empty-icon">&#128100;</span>No checkout history records found.</div>'; return; }
        var html = '<table class="dp-history-table"><thead><tr><th>Status</th><th>Individual</th><th>Location</th><th>Date</th></tr></thead><tbody>';
        records.forEach(function(r) { var cls = (r.checkinstatus === 'Checked Out') ? 'pct-warn' : 'pct-good'; html += '<tr><td><span class="' + cls + '">' + dpVal(r.checkinstatus) + '</span></td><td>' + dpVal(r.individual) + '</td><td>' + dpVal(r.locationname) + '</td><td>' + fmtDate(r.transactiontime) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // ========================================= MAINTENANCE HISTORY TAB =========================================
    function loadMaintenanceHistory(assetId) {
        var el = document.getElementById('tab-maintenance');
        var records = _dpCache.maintenance_data;
        if (records) { renderMaintenanceHistory(el, records); _dpCache.maintenance = true; return; }
        el.innerHTML = '<div class="dp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=maintenance&id=' + assetId, function(d) { renderMaintenanceHistory(el, d.records || []); _dpCache.maintenance = true; });
    }
    function renderMaintenanceHistory(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="dp-empty"><span class="dp-empty-icon">&#128295;</span>No maintenance records found.</div>'; return; }
        var html = '<table class="dp-history-table"><thead><tr><th>Date</th><th>Action</th><th>Performed By</th><th>Notes</th></tr></thead><tbody>';
        records.forEach(function(r) { html += '<tr><td>' + fmtDate(r.whenperformed) + '</td><td><strong>' + dpVal(r.actionperformed) + '</strong></td><td>' + dpVal(r.performedby) + '</td><td>' + dpVal(r.notes) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // ==================================================== CHILDREN TAB ====================================================
    function loadChildren(assetId) {
        var el = document.getElementById('tab-children');
        var records = _dpCache.children_data;
        if (records) { renderChildren(el, records); _dpCache.children = true; return; }
        el.innerHTML = '<div class="dp-loading">Loading...</div>';
        $.getJSON('va_asset_master.aspx?api=children&id=' + assetId, function(d) { renderChildren(el, d.records || []); _dpCache.children = true; });
    }
    function renderChildren(el, records) {
        if (!records || records.length === 0) { el.innerHTML = '<div class="dp-empty"><span class="dp-empty-icon">&#128279;</span>No child assets found.</div>'; return; }
        var html = '<table class="dp-history-table"><thead><tr><th>Name</th><th>Description</th><th>Location</th><th>Status</th></tr></thead><tbody>';
        records.forEach(function(r) { html += '<tr style="cursor:pointer;" onclick="openDetail(' + r.id + ',\x27' + (r.name||'').replace(/'/g,"\\'") + '\x27)"><td><strong style="color:var(--accent);">' + dpVal(r.name) + '</strong></td><td>' + dpVal(r.description) + '</td><td>' + dpVal(r.locationname) + '</td><td>' + dpVal(r.listvalue1) + '</td></tr>'; });
        el.innerHTML = html + '</tbody></table>';
    }

    // ========================================= Print from detail panel =========================================
    function printFromDetail() {
        if (!_dpCache.general) return;
        var a = _dpCache.general;
        var chk = document.querySelector('#assetGrid .chk-print[value="' + a.id + '"]');
        if (chk) { chk.checked = true; updatePrintBtnAM(); }

        var targetSiteId = a.companyid || $('#DdlCompany').val() || '0';

        // Indicate loading in the input box while prefix resolves
        openPrintModal(targetSiteId, function (prefix) {
            var assetName = a.name || '';
            var numPart = assetName;

            if (prefix && assetName.indexOf(prefix) === 0) {
                // Strip the exact site prefix and any separator
                numPart = assetName.substring(prefix.length).replace(/^[\s\-_]+/, '');
            } else if (prefix && prefix.indexOf(' ') > 0) {
                // If prefix has multiple tokens (e.g. "512 EE"), try regex matching
                var tokens = prefix.trim().split(/\s+/);
                var reg = new RegExp('^(?:' + tokens.join('[\\s\\-_]*') + ')[\\s\\-_]*', 'i');
                if (reg.test(assetName)) {
                    numPart = assetName.replace(reg, '');
                }
            } else {
                // Fallback: strip leading digits and optional EE pattern
                var m = assetName.match(/^(?:\d+\s*(?:EE)?)[\s\-_]+(.*)$/i);
                if (m && m[1]) numPart = m[1].trim();
            }

            document.getElementById('pmNumbers').value = numPart;
            if (assetName) {
                _explicitAssetNames = [assetName];
            }
            // Automatically trigger print preview on first open!
            setTimeout(function () { loadPrintPreview(); }, 200);
        });
    }

</script>
</body>
</html>

