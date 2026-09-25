<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_db_restore.aspx.cs" Inherits="iDash.va_db_restore" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <title>iDash &mdash; Database Restore</title>
            <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <style>
                

                body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    background: var(--bg);
                    margin: 0;
                    padding: 0;
                    color: var(--text);
                }

                .header {
                    background: var(--card);
                    padding: 15px 20px;
                    border-bottom: 1px solid var(--line);
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                }

                .header h1 {
                    margin: 0;
                    font-size: 20px;
                    color: var(--danger);
                    /* Red for danger zone */
                }

                .home-link {
                    text-decoration: none;
                    color: var(--accent);
                    font-weight: 600;
                    font-size: 14px;
                }

                .app-container {
                    max-width: 800px;
                    margin: 40px auto;
                    padding: 0 20px;
                }

                .panel {
                    background: var(--card);
                    padding: 30px;
                    border-radius: 8px;
                    border: 1px solid var(--line);
                    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
                }

                .warning-box {
                    background: color-mix(in srgb, var(--danger) 10%, transparent);
                    border: 1px solid var(--danger);
                    color: var(--danger);
                    padding: 15px;
                    border-radius: 6px;
                    margin-bottom: 25px;
                    font-size: 14px;
                    line-height: 1.5;
                }

                .form-group {
                    margin-bottom: 20px;
                }

                .form-label {
                    display: block;
                    margin-bottom: 8px;
                    color: var(--muted);
                    font-weight: 600;
                }

                .form-control {
                    width: 100%;
                    padding: 12px;
                    background: var(--chip, #0d1730);
                    border: 1px solid var(--line);
                    border-radius: 6px;
                    color: #fff;
                    font-size: 16px;
                }

                .btn-restore {
                    width: 100%;
                    padding: 15px;
                    background: var(--danger);
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-size: 16px;
                    font-weight: bold;
                    cursor: pointer;
                    transition: opacity 0.2s;
                }

                .btn-restore:hover {
                    opacity: 0.9;
                }

                .log-output {
                    margin-top: 30px;
                    background: var(--chip);
                    border: 1px solid var(--line);
                    padding: 15px;
                    border-radius: 6px;
                    font-family: 'Consolas', monospace;
                    font-size: 13px;
                    color: #ccc;
                    height: 300px;
                    overflow-y: auto;
                    white-space: pre-wrap;
                }

                .log-entry {
                    margin-bottom: 5px;
                    border-bottom: 1px dashed #222;
                    padding-bottom: 2px;
                }

                .log-info {
                    color:var(--muted);
                }

                .log-success {
                    color: #10b981;
                }

                .log-error {
                    color: #ef4444;
                }

                .log-warn {
                    color: #f97316;
                }
            </style>
        </head>

        <body>
            <form id="form1" runat="server">
                <div class="header">
                    <h1>Database Restore Tool</h1>
                    <div>
                        <a href="documentation/va_db_restore.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a> <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    </div>
                </div>

                <div class="app-container">

                    <div class="panel">
                        <div class="warning-box">
                            <strong>WARNING - DANGER ZONE:</strong>
                            This will overwritten the entire <u>iDash</u> database with the selected backup file.
                            All active connections will be dropped. This action cannot be undone.
                        </div>

                        <div class="form-group">
                            <label class="form-label">Backup Directory Path</label>
                            <div style="display: flex; gap: 10px;">
                                <asp:TextBox ID="TxtBackupPath" runat="server" CssClass="form-control" Text="c:\VA_RFID\va_dbupdate\backup" />
                                <asp:Button ID="BtnLoadBackups" runat="server" Text="Load" CssClass="btn-restore" style="flex: 0 0 auto; width: 100px; padding: 12px 20px; margin: 0;" OnClick="BtnLoadBackups_Click" />
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Select Backup File (.bak)</label>
                            <asp:DropDownList ID="DDLBackups" runat="server" CssClass="form-control">
                            </asp:DropDownList>
                        </div>

                        <div style="display: flex; gap: 12px; margin-top: 10px;">
                            <asp:Button ID="BtnRestore" runat="server" Text="RESTORE DATABASE" CssClass="btn-restore" style="flex: 1;"
                                OnClick="BtnRestore_Click"
                                OnClientClick="return confirm('ARE YOU SURE?\n\nThis will completely overwrite the iDash database with the selected backup.\n\nClick OK to proceed.');" />
                            <asp:Button ID="BtnRunFixes" runat="server" Text="&#9881; Run Schema &amp; Normalization Fixes" CssClass="btn-restore" style="flex: 1; background: #3b82f6;"
                                OnClick="BtnRunFixes_Click" />
                        </div>

                        <div class="log-output">
                            <asp:Literal ID="LitLog" runat="server" Text="Ready to restore..." />
                        </div>
                    </div>

                </div>

                <idash:Footer runat="server" />
            </form>
        </body>

        </html>


