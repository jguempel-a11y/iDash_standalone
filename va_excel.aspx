<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_excel.aspx.cs" Inherits="va_excel" ResponseEncoding="utf-8"
    %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>VA Tagging Team Excel File Merge Tool</title>
            <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
            <meta http-equiv="Pragma" content="no-cache" />
            <meta http-equiv="Expires" content="0" />

            <style>
                /* ============================================================
           GLOBAL THEME
           ============================================================ */
                :root {
                    --chip-br: var(--line);
                    --table-head: var(--chip);
                    --table-row-hover: rgba(0,0,0,0.02);
                }

                body {
                    margin: 0;
                    background: var(--bg);
                    color: var(--text);
                    font-family: Segoe UI, Tahoma, Arial, sans-serif;
                }

                * {
                    box-sizing: border-box;
                }

                a {
                    text-decoration: none;
                    color: inherit;
                }

                /* ============================================================
           LAYOUT
           ============================================================ */
                .page {
                    max-width: 1400px;
                    margin: 40px auto;
                    padding: 0 40px;
                }

                /* HEADER */
                .header-container {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    margin-bottom: 20px;
                }

                .header-title {
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 6px;
                    color: var(--text);
                }

                .header-sub {
                    font-size: 14px;
                    color: var(--muted);
                }

                .home-link {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    padding: 8px 16px;
                    border-radius: 8px;
                    color: var(--accent);
                    font-weight: 600;
                    transition: 0.2s;
                }

                .home-link:hover {
                    border-color: var(--accent);
                    background: var(--chip-br);
                }

                .aw-header-brand {
                    margin-top: 8px;
                    margin-bottom: 30px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    opacity: 0.95;
                }

                .aw-header-logo {
                    height: 26px;
                    width: auto;
                }

                .aw-header-text {
                    font-size: 14px;
                    font-weight: 600;
                    color: var(--accent);
                    letter-spacing: 0.4px;
                }

                .aw-header-text .bang {
                    color: var(--accent-2);
                }

                .aw-header-copy {
                    display: block;
                    font-size: 12px;
                    font-weight: 400;
                    color: var(--muted);
                    margin-top: 2px;
                }

                /* CARD */
                .card {
                    background: var(--card);
                    border: 1px solid var(--line);
                    border-radius: 14px;
                    padding: 24px;
                    margin-bottom: 24px;
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                }

                .card h1 {
                    margin: 0 0 20px 0;
                    font-size: 20px;
                    font-weight: 600;
                    color: var(--accent);
                    border-bottom: 1px solid var(--line);
                    padding-bottom: 10px;
                }

                /* CONTROLS */
                .label {
                    display: block;
                    color: var(--muted);
                    margin-bottom: 6px;
                    font-size: 14px;
                }

                .input-row {
                    margin-bottom: 20px;
                }

                .btn {
                    background: var(--accent);
                    color: #fff;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 14px;
                    font-weight: 600;
                    margin-right: 8px;
                    display: inline-block;
                }

                .btn:hover {
                    opacity: 0.9;
                }

                .btn.secondary {
                    background: transparent;
                    border: 1px solid var(--muted);
                    color: var(--muted);
                }

                .btn.secondary:hover {
                    border-color: var(--text);
                    color: var(--text);
                }

                .btn.folder {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    color: var(--accent);
                }

                .btn.folder:hover {
                    background: var(--chip-br);
                }

                .btn.reset {
                    background: var(--danger);
                }

                .btn.reset:hover {
                    opacity: 0.8;
                }

                .status {
                    margin-top: 10px;
                    font-size: 14px;
                    display: block;
                }

                .status.ok {
                    color: var(--accent-2);
                }

                .status.err {
                    color: var(--danger);
                }

                .file {
                    background: #0d121f;
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 8px;
                    border-radius: 6px;
                    width: 100%;
                    max-width: 500px;
                }

                .mapping {
                    margin-top: 30px;
                    font-size: 13px;
                    color: var(--muted);
                    line-height: 1.6;
                    background: var(--chip);
                    padding: 16px;
                    border-radius: 8px;
                    border: 1px solid var(--chip-br);
                }

                code {
                    background-color: var(--bg);
                    padding: 2px 5px;
                    border-radius: 4px;
                    color: var(--text);
                    font-family: monospace;
                }

                /* PREVIEW TABLE */
                .preview-table {
                    width: 100%;
                    border-collapse: collapse;
                    font-size: 12px;
                    margin-top: 10px;
                }

                .preview-table th {
                    background: var(--table-head);
                    color: var(--accent);
                    text-align: left;
                    padding: 8px;
                    border-bottom: 2px solid var(--line);
                }

                .preview-table td {
                    padding: 6px 8px;
                    border-bottom: 1px solid var(--line);
                    color: var(--text);
                }

                .preview-table tr:hover {
                    background: var(--table-row-hover);
                }

                /* LOADER */
                #loaderOverlay {
                    position: fixed;
                    inset: 0;
                    background-color: rgba(11, 18, 32, 0.85);
                    display: none;
                    align-items: center;
                    justify-content: center;
                    z-index: 9999;
                }

                #loaderBox {
                    background-color: var(--card);
                    padding: 24px 32px;
                    border-radius: 12px;
                    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
                    font-size: 16px;
                    color: var(--accent);
                    border: 1px solid var(--line);
                }
            </style>

            <script type="text/javascript">
                function showLoader() {
                    var overlay = document.getElementById('loaderOverlay');
                    if (overlay) {
                        overlay.style.display = 'flex';
                    }
                }
            </script>
        </head>

        <body>
            <form id="form1" runat="server">
                <div id="loaderOverlay">
                    <div id="loaderBox">
                        Merging Excel data&hellip; please wait.
                    </div>
                </div>

                <div class="page">

                    <!-- Header -->
                    <div class="header-container">
                        <div>
                            <div class="header-title">VA Tagging Team Excel File Merge Tool</div>
                            <div class="header-sub">Equipment.xlsx Merge &rarr; (SITE)Data Template Generation</div>
                        </div>
                        <a href="documentation/va_excel.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a> <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    </div>

                    <div class="aw-header-brand">
                        <img src="<%= ResolveUrl("~/Assets/branding/assetworx.jpg") %>" class="aw-header-logo" />
                        <span class="aw-header-text">AssetWorx<span class="bang">!</span> <span
                                class="aw-header-copy">by InfinID Technologies</span></span>
                    </div>

                    <div class="card">
                        <!-- Kept original h1 text but styled as h1 inside card -->
                        <h1>VA Excel Merge (Equipment.xlsx &rarr; (SITE)Data)</h1>

                        <asp:Label ID="LblStatus" runat="server" CssClass="status"></asp:Label>
                        <asp:Label ID="LblSummary" runat="server" CssClass="status"></asp:Label>

                        <div class="input-row">
                            <span class="label">Equipment.xlsx files (source, up to 5 files)</span>
                            <asp:FileUpload ID="FuEquipment" runat="server" CssClass="file" AllowMultiple="true" />
                        </div>

                        <div class="input-row">
                            <span class="label">512Data Template v003.xlsx</span>
                            <asp:FileUpload ID="FuTemplate" runat="server" CssClass="file" />
                        </div>

                        <div class="input-row">
                            <asp:Button ID="BtnPreview" runat="server" CssClass="btn"
                                Text="Preview First 10 Rows (Combined)" OnClick="BtnPreview_Click" />
                            <asp:Button ID="BtnMerge" runat="server" CssClass="btn" Text="Merge &amp; Save"
                                OnClick="BtnMerge_Click" OnClientClick="showLoader();" />
                            <asp:Button ID="BtnDownloadMerged" runat="server" CssClass="btn secondary"
                                Text="Download Merged File" Visible="false" OnClick="BtnDownloadMerged_Click" />
                            <asp:Button ID="BtnResetMerged" runat="server" CssClass="btn reset" Text="Reset Merged File"
                                 OnClick="BtnResetMerged_Click" />

                            <button type="button" class="btn folder" onclick="navigator.clipboard.writeText('C:\\VA_RFID\\VA_EXCEL'); alert('Excel folder path copied to clipboard:\nC:\\VA_RFID\\VA_EXCEL\n\nPress Win+R or open File Explorer to paste.');">Open Excel Folder</button>
                        </div>

                        <div class="preview">
                            <asp:Literal ID="LitPreview" runat="server" />
                        </div>

                        <div class="mapping">
                            <strong>Mapping Logic:</strong><br />
                            Entry Number &rarr; Barcode (as <code>512 EE####</code>)<br />
                            Manufacturer &rarr; MANUFACTURER<br />
                            MFGR. EQUIPMENT NAME &rarr; DESCRIPTION<br />
                            MODEL &rarr; MODEL<br />
                            SERIAL # &rarr; Serial<br />
                            EQUIPMENT CATEGORY &rarr; CATEGORY<br />
                            USE STATUS &rarr; STATUS<br />
                            SERVICE POINTER &rarr; SERVICE<br />
                            LOCATION &rarr; LOCATION<br />
                            PHYSICAL INVENTORY DATE &rarr; LOCATIONINVDATE<br />
                            PREVIOUS LOCATION &rarr; PREVIOUSLOCATION<br />
                            STATION NUMBER &rarr; SITE<br />
                            CATEGORY STOCK NUMBER &rarr; CSN<br />
                            CMR &rarr; EIL<br />
                            PURCHASE ORDER # &rarr; PO
                        </div>
                    </div>

                    <idash:Footer runat="server" />
                </div>
            </form>
        </body>

        </html>

