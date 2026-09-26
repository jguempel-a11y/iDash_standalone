<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_sql_upload.aspx.cs" Inherits="iDash.va_sql_upload" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <meta charset="utf-8" />
            <title>SQL Upload - iDash</title>
            <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <style>

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
                .header-title {
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 6px;
                }

                .header-sub {
                    font-size: 14px;
                    color: var(--muted);
                    margin-bottom: 32px;
                }

                .aw-header-brand {
                    margin-top: 8px;
                    margin-bottom: 14px;
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

                .card h2 {
                    margin: 0 0 12px 0;
                    font-size: 20px;
                    font-weight: 600;
                    color: var(--accent);
                }

                .caption {
                    font-size: 14px;
                    color: var(--muted);
                    margin-bottom: 20px;
                    max-width: 700px;
                    line-height: 1.5em;
                }

                /* CONTROLS */
                .row {
                    display: flex;
                    align-items: center;
                    gap: 12px;
                    margin-bottom: 16px;
                    flex-wrap: wrap;
                }

                .btn {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    color: var(--text);
                    padding: 8px 16px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 14px;
                    transition: 0.2s;
                }

                .btn:hover {
                    border-color: var(--accent);
                    background: var(--chip-br);
                }

                .btn-blue {
                    background: var(--accent);
                    color: #fff;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 14px;
                    font-weight: 600;
                }

                .btn-blue:hover {
                    opacity: 0.9;
                }

                .txt {
                    background: var(--chip);
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 8px 12px;
                    border-radius: 6px;
                    font-size: 14px;
                    outline: none;
                }

                .txt:focus {
                    border-color: var(--accent);
                }

                .pill {
                    background: var(--chip);
                    border: 1px solid var(--chip-br);
                    padding: 6px 14px;
                    border-radius: 20px;
                    font-size: 13px;
                    color: var(--muted);
                    display: inline-flex;
                    gap: 8px;
                    align-items: center;
                }

                .pill .count {
                    color: var(--text);
                    font-weight: 700;
                }

                /* GRID */
                .scrollGrid {
                    border: 1px solid var(--line);
                    border-radius: 8px;
                    overflow: auto;
                    max-height: 500px;
                    background: var(--bg);
                    margin-top: 15px;
                }

                .grid {
                    width: 100%;
                    border-collapse: collapse;
                    font-size: 13px;
                }

                .grid th {
                    background: var(--table-head);
                    color: var(--accent);
                    font-weight: 600;
                    text-align: left;
                    padding: 12px 16px;
                    position: sticky;
                    top: 0;
                    z-index: 10;
                }

                .grid td {
                    padding: 10px 16px;
                    border-bottom: 1px solid var(--line);
                    color: var(--text);
                }

                .grid tr:hover {
                    background: var(--table-row-hover);
                }

                /* BACK BUTTON */
                .back-link {
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                    color: var(--muted);
                    margin-bottom: 20px;
                    font-size: 14px;
                }

                .back-link:hover {
                    color: var(--accent);
                }

                .ok {
                    color: var(--ok-text);
                    font-weight: 600;
                    margin-bottom: 15px;
                }
                .err {
                    color: var(--err-text);
                    font-weight: 600;
                    margin-bottom: 15px;
                }
            </style>
        </head>

        <body>
            <form id="form1" runat="server">
                <div class="page">

                    <a href="documentation/va_sql_upload.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a> <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>

                    <div class="header-title">SQL Upload &amp; System Maintenance</div>
                    <div class="header-sub">Execute maintenance scripts, apply database hotfixes, or trigger over-the-air iDash replication.</div>

                    <div class="aw-header-brand">
                        <img src="<%= ResolveUrl("~/Assets/branding/assetworx.jpg") %>" class="aw-header-logo" />
                        <span class="aw-header-text">AssetWorx<span class="bang">!</span> <span
                                class="aw-header-copy">by InfinID Technologies</span></span>
                    </div>

                    <!-- USAGE GUIDE CARD -->
                    <div class="card" style="background: rgba(59, 130, 246, 0.05); border-left: 4px solid var(--accent); padding: 18px 22px; margin-bottom: 24px;">
                        <h3 style="margin: 0 0 8px 0; font-size: 15px; color: var(--accent); display: flex; align-items: center; gap: 8px;">
                            <span>💡</span> Common Use Cases for This Page
                        </h3>
                        <div style="font-size: 13px; color: var(--text); line-height: 1.6; margin-bottom: 12px;">
                            This administrative console executes SQL scripts and batch commands directly against the local SQL Server instance without requiring SQL Server Management Studio (SSMS) or Remote Desktop (RDP):
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 14px;">
                            <div style="background: var(--bg); border: 1px solid var(--line); border-radius: 8px; padding: 12px 14px;">
                                <div style="font-weight: 600; color: var(--accent); margin-bottom: 4px; font-size: 13px;">🚀 1. iDash System Updates &amp; Replication</div>
                                <div style="font-size: 12px; color: var(--muted); line-height: 1.5;">
                                    Synchronize field laptops or carts with the latest baseline. Upload or paste <code>run_migration.sql</code> to download and unpack the clean update package automatically. See <a href="documentation/va_system_migration_guide.html#sec-method-ota" target="_blank" style="color:var(--accent); text-decoration:underline;">Migration Playbook</a>.
                                </div>
                            </div>
                            <div style="background: var(--bg); border: 1px solid var(--line); border-radius: 8px; padding: 12px 14px;">
                                <div style="font-weight: 600; color: #10b981; margin-bottom: 4px; font-size: 13px;">🛠️ 2. Database Maintenance &amp; Bug Fixes</div>
                                <div style="font-size: 12px; color: var(--muted); line-height: 1.5;">
                                    Execute targeted SQL patches to repair tables, re-align mismatched foreign keys, rebuild indexes, or update facility configuration values across remote field environments.
                                </div>
                            </div>
                            <div style="background: var(--bg); border: 1px solid var(--line); border-radius: 8px; padding: 12px 14px;">
                                <div style="font-weight: 600; color: #f59e0b; margin-bottom: 4px; font-size: 13px;">🔒 3. Safe Gated Execution</div>
                                <div style="font-size: 12px; color: var(--muted); line-height: 1.5;">
                                    Potentially destructive commands (<code>DROP</code>, <code>ALTER</code>, <code>TRUNCATE</code>, <code>EXEC</code>) are blocked by default until you explicitly check <strong>Allow dangerous SQL</strong>.
                                </div>
                            </div>
                        </div>
                    </div>

                    <asp:Literal ID="LitErr" runat="server" />

                    <div class="card">
                        <h2>Upload &amp; Execute</h2>
                        <div class="caption">
                            Upload a .sql file or paste SQL commands directly into the box below.
                        </div>

                        <div class="row" style="margin-bottom: 10px;">
                            <asp:FileUpload ID="FileSqlUpload" runat="server" CssClass="btn" />
                            <asp:Button ID="BtnRunSql" runat="server" CssClass="btn-blue" Text="Run SQL"
                                OnClick="BtnRunSql_Click" />
                            <asp:LinkButton ID="BtnSqlExport" runat="server" CssClass="btn" Text="&#128196; Download Log (.txt)"
                                OnClick="BtnSqlExport_Click" />

                            <span class="pill"><span>Shown</span> <span class="count">
                                    <asp:Literal ID="LitSqlShown" runat="server" />
                                </span></span>
                            <span class="pill"><span>Total</span> <span class="count">
                                    <asp:Literal ID="LitSqlTotal" runat="server" />
                                </span></span>
                        </div>

                        <div class="row" style="margin-bottom: 14px;">
                            <asp:TextBox ID="TxtSqlDirect" runat="server" TextMode="MultiLine" Rows="6" CssClass="txt"
                                style="width: 100%; font-family:Consolas, monospace; font-size:12px;"
                                placeholder="-- Or paste your SQL script directly here instead of uploading a file..." />
                        </div>

                        <div class="row" style="margin-bottom: 8px;">
                            <asp:CheckBox ID="ChkAllowDangerous" runat="server"
                                Text="Allow dangerous SQL (DROP / ALTER / TRUNCATE)"
                                style="color:var(--muted); font-size:14px;" />
                        </div>

                        <div class="caption" style="margin-top:6px; color:var(--accent);">
                            <asp:Literal ID="LitSqlNote" runat="server" />
                        </div>
                        <asp:Literal ID="LitSqlResult" runat="server" />

                        <div class="scrollGrid">
                            <asp:GridView ID="GridSqlResults" runat="server" CssClass="grid" EnableViewState="false"
                                AutoGenerateColumns="True" OnRowDataBound="GridSqlResults_RowDataBound" />
                        </div>
                    </div>

                    <idash:Footer runat="server" />
                </div>
            </form>
        </body>

        </html>

