<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_sitedata_export.aspx.cs" Inherits="iDash.va_sitedata_export" ResponseEncoding="utf-8" %>
<%-- Smart Merge v2.1 --%>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Cart Data &amp; Synchronization Hub &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="description" content="Unified cross-cart data synchronization, cloning, and export hub for iDash carts." />
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font-family: Segoe UI, Tahoma, Arial, sans-serif;
        }
        a { text-decoration: none; color: inherit; }

        /* ============================================================
           LAYOUT
           ============================================================ */
        .app { display: flex; min-height: 100vh; }

        /* SIDEBAR */
        .side {
            width: 270px;
            background: var(--chip);
            border-right: 1px solid var(--line);
            padding: 24px 18px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            gap: 0;
        }
        .side-logo {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 4px;
        }
        .side-logo img { height: 22px; }
        .side h1 { font-size: 17px; margin: 0 0 3px; color: var(--accent); font-weight: 700; }
        .side .sub { font-size: 12px; color: var(--muted); margin-bottom: 22px; }
        .slabel {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: .07em;
            color: var(--muted);
            margin: 16px 0 7px;
        }
        .nav-link {
            display: block;
            background: transparent;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 9px 13px;
            color: var(--text);
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            margin-bottom: 6px;
            transition: 0.15s;
        }
        .nav-link:hover { background: var(--accent); color: var(--bg); border-color: var(--accent); }
        .nav-link.active { background: var(--accent); color: var(--bg); border-color: var(--accent); }

        /* MAIN */
        .main { flex: 1; padding: 36px 44px; max-width: 1020px; }
        .header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:28px; gap:20px; }
        .header-right { display:flex; gap:8px; align-items:center; flex-shrink:0; margin-top:2px; }
        .nav-pill { display:inline-flex; align-items:center; gap:6px; padding:7px 14px; border-radius:8px; font-size:12px; font-weight:600; text-decoration:none; border:1px solid var(--line); color:var(--text); cursor:pointer; background:var(--card); transition:all .15s; }
        .nav-pill:hover { border-color:var(--accent); color:var(--accent); background:color-mix(in srgb, var(--accent) 8%, transparent); }
        .page-title { font-size: 26px; font-weight: 700; margin: 0 0 6px; }
        .page-sub { color: var(--muted); font-size: 14px; line-height: 1.6; }

        /* PANEL */
        .panel {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 24px 28px;
            margin-bottom: 22px;
            box-shadow: var(--shadow);
        }
        .ptitle {
            font-size: 16px;
            font-weight: 700;
            margin: 0 0 4px;
            color: var(--accent);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .psub { font-size: 13px; color: var(--muted); margin-bottom: 18px; line-height: 1.5; }

        /* FORM GRID */
        .fg { display: grid; grid-template-columns: 200px 1fr; gap: 10px 16px; align-items: center; }
        .fl { font-size: 13px; font-weight: 600; color: var(--muted); }
        .fl span { display: block; font-size: 11px; font-weight: 400; color: var(--muted); margin-top: 1px; opacity: 0.8; }
        .sep { grid-column: 1/-1; border: none; border-top: 1px solid var(--line); margin: 6px 0; }

        select, input[type="text"] {
            width: 100%;
            padding: 9px 12px;
            border-radius: 8px;
            background: var(--bg);
            border: 1px solid var(--line);
            color: var(--text);
            font-size: 13px;
            outline: none;
        }
        select:focus, input[type="text"]:focus { border-color: var(--accent); }

        /* BUTTONS */
        .btn {
            padding: 10px 22px;
            background: var(--accent);
            color: var(--bg);
            border-radius: 10px;
            border: 1px solid var(--accent);
            cursor: pointer;
            font-weight: 700;
            font-size: 14px;
            margin-top: 18px;
            transition: 0.15s;
            display: inline-block;
        }
        .btn:hover { filter: brightness(1.12); }
        .btn.green { background: var(--accent-2); border-color: var(--accent-2); }
        .btn.neutral {
            background: var(--chip);
            border-color: var(--line);
            color: var(--text);
            margin-left: 10px;
        }
        .btn.neutral:hover { border-color: var(--accent); }
        .btn-row { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-top: 18px; }

        /* MESSAGES */
        .msg-ok {
            background: color-mix(in srgb, var(--accent-2), transparent 85%);
            border: 1px solid var(--accent-2);
            color: var(--accent-2);
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 14px;
            font-size: 14px;
        }
        .msg-err {
            background: color-mix(in srgb, var(--danger), transparent 85%);
            border: 1px solid var(--danger);
            color: var(--danger);
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 14px;
            font-size: 14px;
        }
        .msg-info {
            background: var(--info-bg);
            border: 1px solid color-mix(in srgb, var(--accent), transparent 60%);
            color: var(--info-text);
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 14px;
            font-size: 14px;
        }

        /* RESULTS / LOG */
        .log-box {
            background: var(--chip);
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 16px;
            font-size: 13px;
            font-family: Consolas, 'Courier New', monospace;
            color: var(--log-text);
            white-space: pre-wrap;
            word-break: break-all;
            max-height: 340px;
            overflow-y: auto;
            margin-top: 14px;
        }

        /* RESULTS TABLE */
        .results-scroll {
            border: 1px solid var(--line);
            border-radius: 10px;
            overflow: auto;
            max-height: 420px;
            background: var(--bg);
            margin-top: 16px;
        }
        .results-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .results-table th {
            background: var(--table-head);
            color: var(--accent);
            font-weight: 600;
            text-align: left;
            padding: 11px 14px;
            position: sticky;
            top: 0;
            z-index: 5;
        }
        .results-table td {
            padding: 9px 14px;
            border-bottom: 1px solid var(--line);
            color: var(--text);
        }
        .results-table tr:hover td { background: var(--table-row-hover); }

        /* STATS PILLS */
        .pill-row { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 14px; }
        .pill {
            background: var(--chip);
            border: 1px solid var(--chip-br);
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 13px;
            color: var(--muted);
            display: inline-flex;
            gap: 6px;
            align-items: center;
        }
        .pill .count { color: var(--text); font-weight: 700; }

        /* COLUMN CHECKLIST */
        .col-checks {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 6px 16px;
            margin-top: 8px;
        }
        .col-checks label {
            display: flex;
            align-items: center;
            gap: 7px;
            font-size: 13px;
            color: var(--text);
            cursor: pointer;
            padding: 4px 0;
        }
        .col-checks input[type="checkbox"] { accent-color: var(--accent); width: 15px; height: 15px; cursor: pointer; }
        .check-all-row { display: flex; gap: 14px; margin-bottom: 8px; }
        .check-all-row a {
            font-size: 12px;
            color: var(--accent);
            cursor: pointer;
            text-decoration: underline;
        }

        /* BADGE */
        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
        }
        .badge-green { background: color-mix(in srgb, var(--accent-2), transparent 80%); color: var(--accent-2); }
        .badge-blue  { background: color-mix(in srgb, var(--accent), transparent 80%); color: var(--accent); }

        /* BACK LINK */
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            color: var(--muted);
            margin-bottom: 20px;
            font-size: 14px;
            transition: 0.15s;
        }
        .back-link:hover { color: var(--accent); }

        /* ============================================================
           IMPORT LOADING OVERLAY
           ============================================================ */
        #import-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.65);
            z-index: 9000;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            gap: 20px;
            backdrop-filter: blur(3px);
        }
        #import-overlay.active {
            display: flex;
        }
        .spinner {
            width: 56px;
            height: 56px;
            border: 6px solid rgba(255,255,255,0.15);
            border-top-color: var(--accent-2);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        .overlay-msg {
            color: #fff;
            font-size: 16px;
            font-weight: 700;
            text-align: center;
            line-height: 1.5;
        }
        .overlay-sub {
            color: rgba(255,255,255,0.65);
            font-size: 13px;
            text-align: center;
        }
    </style>
</head>
<body>

<%-- Loading overlay — shown while import postback is in flight --%>
<div id="import-overlay" role="status" aria-live="polite">
    <div class="spinner"></div>
    <div class="overlay-msg" id="overlay-msg-text">Processing Import&hellip;</div>
    <div class="overlay-sub">Please wait &mdash; this may take a moment for large files.</div>
</div>
<form id="form1" runat="server">
<div class="app">

    <!-- ====================================================
         SIDEBAR
         ==================================================== -->
    <aside class="side">
        <div class="side-logo" style="display:flex; align-items:center; gap:8px; margin-bottom:12px;">
            <img src="<%= ResolveUrl("~/Assets/branding/IDIntegration.jpg") %>" alt="ID Integration Inc." style="height:24px; width:auto; border-radius:3px;" />
            <span style="font-weight:700; font-size:16px; color:var(--text);">iDash</span>
        </div>
        <h1>&#128257; Cart Data &amp; Sync</h1>
        <div class="sub">Unified cross-cart data synchronization &amp; export hub</div>

        <div class="slabel">Sections</div>
        <a href="#sec-options" class="nav-link">&#9881; Export Options</a>
        <a href="#sec-columns" class="nav-link">&#9776; Column Selection</a>
        <a href="#sec-results" class="nav-link">&#128202; Export Results</a>
        <a href="#sec-import" class="nav-link">&#128229; Ingest &amp; Sync File</a>
        <a href="#sec-import-results" class="nav-link">&#128203; Sync Results</a>
    </aside>

    <!-- ====================================================
         MAIN CONTENT
         ==================================================== -->
    <main class="main">
        <div class="header">
            <div>
                <div class="page-title">&#128257; Cart Data &amp; Synchronization Hub</div>
                <div class="page-sub">
                    Export and synchronize site and cart asset data across <strong>Excel (.xlsx)</strong>,
                    <strong>tab-delimited (.txt)</strong>, and <strong>CSV</strong> formats &mdash; ready to clone, update, or synchronize between carts and servers. Features universal Smart Merge, live scan protection, and automatic location provisioning.
                </div>
            </div>
            <div class="header-right">
                <button type="button" class="nav-pill" id="themeBtn" onclick="toggleTheme()" title="Toggle light/dark">☀️</button>
                <a href="documentation/va_sitedata_export.html" class="nav-pill">&#128214; View Docs</a>
                <a href="index.aspx" class="nav-pill">&#8962; Hub</a>
            </div>
        </div>

        <asp:Literal ID="LitMsg" runat="server" />

        <!-- ====================================================
             PANEL: EXPORT OPTIONS
             ==================================================== -->
        <div class="panel" id="sec-options">
            <div class="ptitle">&#9881; Export Options</div>
            <div class="psub">
                Choose the site to export. Optionally filter by asset status.
                Leave <strong>All Sites</strong> selected to export every asset across all companies.
            </div>

            <div class="fg">
                <div class="fl">Company / Site
                    <span>Populated from dbo.company</span>
                </div>
                <asp:DropDownList ID="DdlCompany" runat="server" AutoPostBack="false" />

                <div class="fl">Asset Status Filter
                    <span>Leave blank to export all statuses</span>
                </div>
                <asp:DropDownList ID="DdlStatus" runat="server">
                    <asp:ListItem Value="">-- All Statuses --</asp:ListItem>
                    <asp:ListItem Value="In Use">In Use</asp:ListItem>
                    <asp:ListItem Value="Not In Use">Not In Use</asp:ListItem>
                    <asp:ListItem Value="Turned In">Turned In</asp:ListItem>
                    <asp:ListItem Value="Disposed">Disposed</asp:ListItem>
                </asp:DropDownList>

                <hr class="sep" />

                <div class="fl">Export Format
                    <span>Choose output file type</span>
                </div>
                <asp:DropDownList ID="DdlFormat" runat="server">
                    <asp:ListItem Value="xlsx" Selected="True">Excel Workbook (.xlsx) &mdash; Formatted spreadsheet</asp:ListItem>
                    <asp:ListItem Value="tsv">Tab-Delimited (.txt) &mdash; Recommended for cart cloning / iDash migration</asp:ListItem>
                    <asp:ListItem Value="csv">CSV (.csv) &mdash; Generic tabular format</asp:ListItem>
                </asp:DropDownList>

                <div class="fl">Include Header Row
                    <span>First row = column names</span>
                </div>
                <div>
                    <asp:CheckBox ID="ChkHeader" runat="server" Checked="true"
                        Text="Yes &mdash; include header row"
                        style="font-size:13px; color:var(--text);" />
                </div>
            </div>
        </div>

        <!-- ====================================================
             PANEL: COLUMN SELECTION
             ==================================================== -->
        <div class="panel" id="sec-columns">
            <div class="ptitle">&#9776; Column Selection</div>
            <div class="psub">
                Choose which asset fields to include in the export.
                All columns are selected by default &mdash; deselect any you don&#8217;t need.
                Columns map directly to the <code>dbo.v_asset</code> view.
            </div>

            <div class="check-all-row">
                <a onclick="setAllCols(true)">&#9745; Select All</a>
                <a onclick="setAllCols(false)">&#9744; Clear All</a>
            </div>

            <div class="col-checks">
                <label><asp:CheckBox ID="ChkName"            runat="server" Checked="true" />Asset Tag / Name</label>
                <label><asp:CheckBox ID="ChkDescription"     runat="server" Checked="true" />Description</label>
                <label><asp:CheckBox ID="ChkManufacturer"    runat="server" Checked="true" />Manufacturer (text1)</label>
                <label><asp:CheckBox ID="ChkModel"           runat="server" Checked="true" />Model (text2)</label>
                <label><asp:CheckBox ID="ChkSerial"          runat="server" Checked="true" />Serial Number (text3)</label>
                <label><asp:CheckBox ID="ChkCompany"         runat="server" Checked="true" />Company / Site Name</label>
                <label><asp:CheckBox ID="ChkLocation"        runat="server" Checked="true" />Location</label>
                <label><asp:CheckBox ID="ChkStatus"          runat="server" Checked="true" />Status (listvalue1)</label>
                <label><asp:CheckBox ID="ChkServicePointer"  runat="server" Checked="true" />Service Pointer (text5)</label>
                <label><asp:CheckBox ID="ChkEIL"             runat="server" Checked="true" />EIL / CMR (text8)</label>
                <label><asp:CheckBox ID="ChkPO"              runat="server" Checked="true" />Purchase Order (text9)</label>
                <label><asp:CheckBox ID="ChkStationNum"      runat="server" Checked="true" />Station Number (text7)</label>
                <label><asp:CheckBox ID="ChkSubStation"      runat="server" Checked="true" />Sub-Station (text14)</label>
                <label><asp:CheckBox ID="ChkCategory"        runat="server" Checked="true" />Category (text4)</label>
                <label><asp:CheckBox ID="ChkAssetType"       runat="server" Checked="true" />Asset Type / FSC</label>
                <label><asp:CheckBox ID="ChkCost"            runat="server" Checked="true" />Cost / Acquisition (text15)</label>
                <label><asp:CheckBox ID="ChkAcqDate"         runat="server" Checked="true" />Acquisition Date (date1)</label>
                <label><asp:CheckBox ID="ChkInServiceDate"   runat="server" Checked="true" />In-Service Date (date2)</label>
                <label><asp:CheckBox ID="ChkTagType"         runat="server" Checked="true" />Tag Type (text19)</label>
                <label><asp:CheckBox ID="ChkTagDate"         runat="server" Checked="true" />Tag Date (text17)</label>
                <label><asp:CheckBox ID="ChkTagged"          runat="server" Checked="true" />Tagged Flag (text18)</label>
                <label><asp:CheckBox ID="ChkRfidTag"         runat="server" Checked="true" />RFID Tag</label>
                <label><asp:CheckBox ID="ChkLastInventoried" runat="server" Checked="true" />Last Inventoried</label>
                <label><asp:CheckBox ID="ChkLastObserved"    runat="server" Checked="true" />Last Observed</label>
                <label><asp:CheckBox ID="ChkLastModifiedBy"  runat="server" Checked="true" />Last Modified By</label>
                <label><asp:CheckBox ID="ChkPrevLocation"    runat="server" Checked="true" />Previous Location (text6)</label>
                <label><asp:CheckBox ID="ChkPrevLocation2"   runat="server" Checked="true" />Previous Location 2 (text11)</label>
                <label><asp:CheckBox ID="ChkPrevInvDate"     runat="server" Checked="true" />Previous Inv. Date (text10)</label>
                <label><asp:CheckBox ID="ChkLocTagged"       runat="server" Checked="true" />Location Tagged (text16)</label>
                <label><asp:CheckBox ID="ChkEntryNum"        runat="server" Checked="true" />Entry Number (text12)</label>
                <label><asp:CheckBox ID="ChkEmpId"           runat="server" Checked="true" />Employee ID (text13)</label>
                <label><asp:CheckBox ID="ChkDisposalStatus"  runat="server" Checked="true" />Disposal Status</label>
                <label><asp:CheckBox ID="ChkNotes"           runat="server" Checked="true" />Notes (text20)</label>
                <label><asp:CheckBox ID="ChkCreated"         runat="server" Checked="true" />Created Date</label>
                <label><asp:CheckBox ID="ChkNextMaint"       runat="server" Checked="true" />Next Maintenance</label>
            </div>
        </div>

        <!-- ====================================================
             ACTIONS
             ==================================================== -->
        <div class="btn-row">
            <asp:Button ID="BtnPreview" runat="server" CssClass="btn neutral"
                Text="&#128202; Preview (50 rows)" OnClick="BtnPreview_Click" />
            <asp:Button ID="BtnExport" runat="server" CssClass="btn"
                Text="&#128228; Export &amp; Download" OnClick="BtnExport_Click" />
            <asp:Button ID="BtnExportLocations" runat="server" CssClass="btn neutral"
                Text="&#127970; Export Locations Only" OnClick="BtnExportLocations_Click" />
        </div>

        <!-- ====================================================
             PANEL: RESULTS & LOG
             ==================================================== -->
        <div class="panel" id="sec-results" style="margin-top:28px;">
            <div class="ptitle">&#128202; Results &amp; Export Log</div>
            <div class="psub">
                Preview your data before downloading. The log shows timing, row count, company filter, and any
                warnings or errors encountered during export.
            </div>

            <div class="pill-row">
                <span class="pill"><span>Rows</span><span class="count"><asp:Literal ID="LitRowCount" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill"><span>Columns</span><span class="count"><asp:Literal ID="LitColCount" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill"><span>Site</span><span class="count"><asp:Literal ID="LitSiteLabel" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill"><span>Format</span><span class="count"><asp:Literal ID="LitFormatLabel" runat="server">&mdash;</asp:Literal></span></span>
            </div>

            <!-- LOG BOX -->
            <asp:Literal ID="LitLog" runat="server" />

            <!-- PREVIEW GRID -->
            <asp:Panel ID="PnlPreview" runat="server" Visible="false" CssClass="results-scroll">
                <asp:GridView ID="GridPreview" runat="server" CssClass="results-table"
                    EnableViewState="false" AutoGenerateColumns="true" />
            </asp:Panel>
        </div>

        <!-- ====================================================
             PANEL: IMPORT FILE
             ==================================================== -->
        <div class="panel" id="sec-import" style="margin-top:28px; border-color: color-mix(in srgb, var(--accent-2), transparent 50%);">
            <div class="ptitle" style="color:var(--accent-2);">&#128229; Ingest &amp; Synchronize Data File</div>
            <div class="psub">
                Upload an <strong>Excel (.xlsx)</strong>, <strong>tab-delimited (.txt)</strong>, or <strong>CSV</strong> file to synchronize or clone records into this iDash database.
                Use <strong>Dry Run</strong> to preview what would change without writing anything.
                <strong>Smart Merge</strong> preserves recent cart scans and timestamps, fills missing attributes (Manufacturer, Model, PO, Service), auto-provisions missing locations, and inserts new records without overwriting with blanks.
            </div>

            <div class="fg">
                <div class="fl">Upload File
                    <span>.xlsx (Excel), .txt (tab-delimited), or .csv</span>
                </div>
                <asp:FileUpload ID="FuImport" runat="server" accept=".xlsx,.txt,.csv"
                    style="background:var(--bg); border:1px solid var(--line); border-radius:8px; padding:8px 12px; color:var(--text); font-size:13px; width:100%;" />

                <div class="fl">Target Company
                    <span>Assign imported records to this company</span>
                </div>
                <asp:DropDownList ID="DdlImportCompany" runat="server" />

                <div class="fl">Workflow Profile
                    <span>Select synchronization behavior</span>
                </div>
                <asp:DropDownList ID="DdlConflict" runat="server">
                    <asp:ListItem Value="merge" Selected="True">&#128260; Smart Merge &mdash; Fill missing &amp; update if file dates/scans are newer (Recommended)</asp:ListItem>
                    <asp:ListItem Value="provision">&#127970; Fresh Cart Provisioning &mdash; Smart Merge + Auto-provision &amp; link missing locations</asp:ListItem>
                    <asp:ListItem Value="update">&#9888; Full Overwrite &mdash; Overwrite all columns with file values</asp:ListItem>
                    <asp:ListItem Value="skip">&#10134; Skip Existing &mdash; Insert new records only</asp:ListItem>
                </asp:DropDownList>
            </div>

            <div class="btn-row">
                <asp:Button ID="BtnDryRun" runat="server" CssClass="btn neutral"
                    Text="&#128203; Dry Run (no changes)" OnClick="BtnDryRun_Click"
                    OnClientClick="return showImportLoader('Dry Run in Progress&hellip;', 'Analysing file &mdash; no changes will be written.');" />
                <asp:Button ID="BtnImport" runat="server" CssClass="btn green"
                    Text="&#128229; Import to Database" OnClick="BtnImport_Click"
                    OnClientClick="return confirmAndLoad();" />
                <asp:Button ID="BtnRepairLocations" runat="server" CssClass="btn neutral"
                    Text="&#128279; Auto-Provision &amp; Link Locations" OnClick="BtnRepairLocations_Click"
                    OnClientClick="return confirm('This will scan existing assets for the selected company, auto-create any missing locations in dbo.location, and link locationid. Continue?');" />
            </div>
        </div>

        <!-- ====================================================
             PANEL: IMPORT RESULTS & LOG
             ==================================================== -->
        <div class="panel" id="sec-import-results">
            <div class="ptitle" style="color:var(--accent-2);">&#128203; Import Results &amp; Log</div>
            <div class="psub">
                Row-by-row results from the last import or dry run. Check the log for per-row detail and any errors.
            </div>

            <asp:Literal ID="LitImportMsg" runat="server" />

            <div class="pill-row">
                <span class="pill"><span>Rows Read</span><span class="count"><asp:Literal ID="LitImpTotal" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill" style="border-color:var(--accent-2);"><span>Inserted</span><span class="count" style="color:var(--accent-2);"><asp:Literal ID="LitImpInserted" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill" style="border-color:var(--accent);"><span>Updated</span><span class="count" style="color:var(--accent);"><asp:Literal ID="LitImpUpdated" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill"><span>Skipped</span><span class="count"><asp:Literal ID="LitImpSkipped" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill" style="border-color:var(--danger);"><span>Errors</span><span class="count" style="color:var(--danger);"><asp:Literal ID="LitImpErrors" runat="server">&mdash;</asp:Literal></span></span>
                <span class="pill"><span>Mode</span><span class="count"><asp:Literal ID="LitImpMode" runat="server">&mdash;</asp:Literal></span></span>
            </div>

            <asp:Literal ID="LitImportLog" runat="server" />
        </div>

        <div style="text-align:center; color:var(--muted); font-size:12px; margin-top:14px; padding-bottom:40px;">
            Intelligent Distributed Asset Scanning Hub &mdash; Site Data Export / Import &copy; 2026
        </div>
        <idash:Footer runat="server" />
    </main>
</div>
</form>

<script>
function setAllCols(val) {
    var boxes = document.querySelectorAll('.col-checks input[type="checkbox"]');
    for (var i = 0; i < boxes.length; i++) boxes[i].checked = val;
}

// ── Import loading overlay ────────────────────────────────────────────────────
function showImportLoader(title, sub) {
    // Validate: must have a file selected
    var fu = document.getElementById('<%= FuImport.ClientID %>');
    if (!fu || !fu.value || fu.value === '') {
        alert('Please choose a file to import first.');
        return false; // cancel the postback
    }

    var overlay = document.getElementById('import-overlay');
    var msgEl   = document.getElementById('overlay-msg-text');
    var subEl   = overlay ? overlay.querySelector('.overlay-sub') : null;

    if (msgEl)  msgEl.innerHTML  = title || 'Processing Import\u2026';
    if (subEl)  subEl.innerHTML  = sub   || 'Please wait \u2014 this may take a moment for large files.';
    if (overlay) overlay.classList.add('active');

    // Disable both import buttons to prevent double-submit (deferred to allow submission event to complete)
    setTimeout(function() {
        var btns = document.querySelectorAll('#BtnDryRun, #BtnImport');
        btns.forEach(function(b) { b.disabled = true; });
    }, 50);

    return true; // allow the postback to proceed
}

function confirmAndLoad() {
    if (!confirm('Import will write to the database. Continue?')) return false;
    return showImportLoader('Importing to Database\u2026', 'Writing records \u2014 please do not close this tab.');
}

// Hide overlay as soon as the new page content arrives (postback complete)
document.addEventListener('DOMContentLoaded', function() {
    var overlay = document.getElementById('import-overlay');
    if (overlay) overlay.classList.remove('active');
});

// Smooth scroll for sidebar anchors
document.querySelectorAll('.side .nav-link[href^="#"]').forEach(function(a) {
    a.addEventListener('click', function(e) {
        e.preventDefault();
        var tgt = document.querySelector(this.getAttribute('href'));
        if (tgt) tgt.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
});
</script>
</body>
</html>

