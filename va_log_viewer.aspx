<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_log_viewer.aspx.cs" Inherits="iDash.va_log_viewer" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash &mdash; Log Viewer</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
    <style>
            --accent2:  var(--accent-2);
        }
        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        *{box-sizing:border-box;}
        body{font-family:'Segoe UI',Arial,sans-serif;background:var(--bg);margin:0;padding:0;color:var(--text);}

        .header{background:var(--chip);padding:14px 24px;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;}
        .header h1{margin:0;font-size:20px;color:var(--accent);display:flex;align-items:center;gap:10px;}
        .pulsedot{width:8px;height:8px;border-radius:50%;background:var(--accent2);display:inline-block;box-shadow:0 0 6px var(--accent2);animation:pulse 2s infinite;}
        @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
        .home-link{text-decoration:none;color:var(--accent);font-weight:600;font-size:14px;}
        .logout-btn{background:none;border:1px solid #3b4a6b;color:var(--muted);padding:5px 14px;border-radius:5px;cursor:pointer;font-size:12px;}
        .logout-btn:hover{border-color:var(--danger);color:var(--danger);}

        .app{max-width:1600px;margin:0 auto;padding:20px 24px;}

        /* Login */
        .login-wrap{display:flex;justify-content:center;align-items:center;min-height:72vh;}
        .login-card{background:var(--card);border:1px solid var(--border);border-radius:14px;padding:44px 52px;width:380px;text-align:center;box-shadow:var(--shadow);}
        .login-card h2{color:var(--accent);margin:0 0 6px;font-size:22px;}
        .login-card p{color:var(--muted);font-size:13px;margin:0 0 24px;}
        .inp{width:100%;background:var(--chip);border:1px solid var(--line);color:var(--text);padding:10px 12px;border-radius:6px;font-size:14px;margin-bottom:12px;}
        .inp:focus{outline:none;border-color:var(--accent);}
        .btn{display:inline-block;padding:10px 22px;border:none;border-radius:6px;cursor:pointer;font-size:14px;font-weight:600;background:var(--accent);color:#001425;transition:opacity .2s;}
        .btn:hover{opacity:.88;}
        .btn.sec{background:transparent;border:1px solid var(--accent);color:var(--accent);}
        .err-msg{color:var(--danger);font-size:13px;margin-top:8px;}

        /* KPI */
        .kpi-row{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:18px;}
        .kpi{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 20px;min-width:130px;flex:1;box-shadow:var(--shadow);}
        .kpi-val{font-size:26px;font-weight:700;color:var(--accent);}
        .kpi-lbl{font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.8px;margin-top:2px;}
        .kpi.green .kpi-val{color:var(--accent2);}
        .kpi.red .kpi-val{color:var(--danger);}
        .kpi.warn .kpi-val{color:#f59e0b;}

        /* Charts */
        .charts-row{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;margin-bottom:18px;}
        @media(max-width:900px){.charts-row{grid-template-columns:1fr;}}
        .chart-card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px 20px;box-shadow:var(--shadow);}
        .chart-card h3{margin:0 0 14px;font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.8px;}
        .bar-list{display:flex;flex-direction:column;gap:8px;}
        .bar-item{display:flex;align-items:center;gap:8px;font-size:12px;}
        .bar-lbl{width:120px;text-overflow:ellipsis;overflow:hidden;white-space:nowrap;color:var(--text);flex-shrink:0;}
        .bar-track{flex:1;background:var(--bg);border-radius:4px;height:9px;}
        .bar-fill{height:9px;border-radius:4px;background:var(--accent);transition:width .5s;}
        .bar-num{width:48px;text-align:right;color:var(--muted);flex-shrink:0;}

        /* Filter */
        .filter-bar{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px 20px;margin-bottom:18px;display:flex;flex-wrap:wrap;gap:14px;align-items:flex-end;box-shadow:var(--shadow);}
        .fg{display:flex;flex-direction:column;}
        .fg label{font-size:11px;color:var(--muted);margin-bottom:4px;text-transform:uppercase;letter-spacing:.4px;}
        .fg .inp{margin-bottom:0;}

        /* Table */
        .table-wrap{background:var(--card);border:1px solid var(--line);border-radius:10px;overflow:hidden;}
        .table-header{padding:14px 20px;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;}
        .table-header h2{margin:0;font-size:15px;color:var(--muted);font-weight:600;}
        .scroll-x{overflow-x:auto;}
        table.log{width:100%;border-collapse:collapse;font-size:12px;}
        table.log th{background:var(--chip);color:var(--accent);text-align:left;padding:9px 12px;border-bottom:2px solid var(--line);white-space:nowrap;font-size:11px;text-transform:uppercase;letter-spacing:.5px;}
        table.log td{padding:7px 12px;border-bottom:1px solid var(--line);white-space:nowrap;}
        table.log tr:hover td{background:color-mix(in srgb, var(--accent), transparent 95%);}
        .s2{color:var(--accent2);}
        .s3{color:#f59e0b;}
        .s4{color:var(--danger);}
        .s5{color:#f87171;font-weight:700;}
        .mGET{color:var(--accent2);}
        .mPOST{color:#a78bfa;}
        .mHEAD{color:var(--muted);}
        .ip-pill{background:var(--chip);border:1px solid var(--line);border-radius:10px;padding:2px 8px;font-size:11px;font-family:Consolas,monospace;}
        .no-data{text-align:center;padding:40px;color:var(--muted);font-size:14px;}
        .page-info{font-size:12px;color:var(--muted);}
        .pager{display:flex;gap:8px;align-items:center;}
        .pgbtn{background:transparent;border:1px solid var(--line);color:var(--accent);padding:5px 12px;border-radius:5px;cursor:pointer;font-size:12px;}
        .pgbtn:hover{border-color:var(--accent);background:color-mix(in srgb, var(--accent), transparent 92%);}
        .tag-live{display:inline-block;padding:2px 8px;border-radius:10px;font-size:10px;font-weight:600;background:color-mix(in srgb, var(--accent-2), transparent 85%);color:var(--accent2);border:1px solid var(--accent2);margin-left:6px;}

        /* Tabs */
        .tab-bar{display:flex;gap:8px;margin-bottom:18px;border-bottom:2px solid var(--line);padding-bottom:0;}
        .tab-btn{background:transparent;border:none;border-bottom:3px solid transparent;color:var(--muted);padding:10px 22px;cursor:pointer;font-size:14px;font-weight:600;border-radius:0;margin-bottom:-2px;transition:color .2s,border-color .2s;}
        .tab-btn:hover{color:var(--text);}
        .tab-btn.tab-active{color:var(--accent);border-bottom-color:var(--accent);}

        /* App log level badges */
        .lvl-err{display:inline-block;padding:2px 7px;border-radius:4px;font-size:11px;font-weight:700;background:color-mix(in srgb, var(--danger), transparent 85%);color:var(--err-text);border:1px solid var(--danger);}
        .lvl-wrn{display:inline-block;padding:2px 7px;border-radius:4px;font-size:11px;font-weight:700;background:rgba(245,158,11,0.15);color:var(--warn-text);border:1px solid var(--warn);}
        .lvl-inf{display:inline-block;padding:2px 7px;border-radius:4px;font-size:11px;font-weight:700;background:color-mix(in srgb, var(--accent-2), transparent 85%);color:var(--ok-text);border:1px solid var(--accent2);}
        .lvl-dbg{display:inline-block;padding:2px 7px;border-radius:4px;font-size:11px;font-weight:700;background:color-mix(in srgb, var(--accent), transparent 85%);color:var(--accent);border:1px solid var(--accent);}
        .app-msg{white-space:pre-wrap;word-break:break-word;max-width:700px;font-size:12px;}
        .app-stack{white-space:pre-wrap;word-break:break-all;font-size:10px;color:var(--muted);max-width:700px;}
        .diag-banner{background:var(--info-bg);border:1px solid var(--accent);border-radius:10px;padding:16px 20px;margin-bottom:18px;}
        .diag-banner h3{margin:0 0 8px;color:var(--accent);font-size:14px;}
        .diag-banner ul{margin:0;padding-left:20px;color:var(--text);font-size:13px;line-height:1.8;}
        .diag-banner code{background:var(--chip);padding:2px 6px;border-radius:4px;font-family:Consolas,monospace;}
    </style>
</head>
<body>
<form id="form1" runat="server">

    <div class="header">
        <h1>
            <span class="pulsedot"></span>
            Log Viewer
            <span class="tag-live">LIVE</span>
        </h1>
        <div style="display:flex;gap:14px;align-items:center;">
            <a href="documentation/va_log_viewer.html" class="home-link">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
            <asp:Button ID="BtnLogout" runat="server" Text="Logout" CssClass="logout-btn" OnClick="BtnLogout_Click" />
        </div>
    </div>

    <div class="app">
        <asp:Literal ID="LitMsg" runat="server" />

        <!-- LOGIN -->
        <asp:Panel ID="PnlLogin" runat="server">
            <div class="login-wrap">
                <div class="login-card">
                    <h2>&#128274; Admin Access</h2>
                    <p>IIS Log Viewer &mdash; administrator only</p>
                    <asp:TextBox ID="TxtUser" runat="server" CssClass="inp" placeholder="Username" />
                    <asp:TextBox ID="TxtPass" runat="server" TextMode="Password" CssClass="inp" placeholder="Password" />
                    <asp:Button ID="BtnLogin" runat="server" Text="Sign In" CssClass="btn" OnClick="BtnLogin_Click" style="width:100%;" />
                    <asp:Literal ID="LitLoginErr" runat="server" />
                </div>
            </div>
        </asp:Panel>

        <!-- MAIN DASHBOARD -->
        <asp:Panel ID="PnlMain" runat="server" Visible="false">

            <!-- Tab switcher -->
            <div class="tab-bar">
                <asp:Button ID="BtnTabIIS" runat="server" Text="&#128196; IIS Web Logs" CssClass="tab-btn tab-active" OnClick="BtnTabIIS_Click" />
                <asp:Button ID="BtnTabApp" runat="server" Text="&#9881; App Service Logs" CssClass="tab-btn" OnClick="BtnTabApp_Click" />
                <asp:Button ID="BtnTabConn" runat="server" Text="&#128423; User Connections" CssClass="tab-btn" OnClick="BtnTabConn_Click" />
                <asp:Button ID="BtnTabAudit" runat="server" Text="&#128221; Login Audit" CssClass="tab-btn" OnClick="BtnTabAudit_Click" />
            </div>

            <!-- ══ IIS PANEL ══ -->
            <asp:Panel ID="PnlIIS" runat="server">

                <!-- KPIs -->
                <div class="kpi-row">
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitTotalReqs" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Total Requests</div></div>
                    <div class="kpi green"><div class="kpi-val"><asp:Literal ID="LitOkReqs" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">2xx Success</div></div>
                    <div class="kpi warn"><div class="kpi-val"><asp:Literal ID="LitRedReqs" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">3xx Redirect</div></div>
                    <div class="kpi red"><div class="kpi-val"><asp:Literal ID="LitErrReqs" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">4xx / 5xx Errors</div></div>
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitUniqIPs" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Unique IPs</div></div>
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitAvgTime" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Avg Response ms</div></div>
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitTotalBytes" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Total Sent MB</div></div>
                </div>

                <!-- Charts -->
                <div class="charts-row">
                    <div class="chart-card"><h3>&#128200; Top Pages</h3><div class="bar-list"><asp:Literal ID="LitTopPages" runat="server" /></div></div>
                    <div class="chart-card"><h3>&#127760; Top Client IPs</h3><div class="bar-list"><asp:Literal ID="LitTopIPs" runat="server" /></div></div>
                    <div class="chart-card"><h3>&#127381; Status Breakdown</h3><div class="bar-list"><asp:Literal ID="LitStatusBreak" runat="server" /></div></div>
                </div>

                <!-- IIS Filter bar -->
                <div class="filter-bar">
                    <div class="fg">
                        <label>Log File</label>
                        <asp:DropDownList ID="DdlLogFile" runat="server" CssClass="inp" AutoPostBack="true"
                            OnSelectedIndexChanged="DdlLogFile_Changed" style="min-width:190px;" />
                    </div>
                    <div class="fg">
                        <label>Filter URI (contains)</label>
                        <asp:TextBox ID="TxtUriFilter" runat="server" CssClass="inp" placeholder="e.g. idash  ennx" style="width:200px;" />
                    </div>
                    <div class="fg">
                        <label>Client IP</label>
                        <asp:TextBox ID="TxtIpFilter" runat="server" CssClass="inp" placeholder="e.g. 192.168" style="width:150px;" />
                    </div>
                    <div class="fg">
                        <label>Method</label>
                        <asp:DropDownList ID="DdlMethod" runat="server" CssClass="inp" style="width:110px;">
                            <asp:ListItem Text="All" Value="" /><asp:ListItem Text="GET" Value="GET" />
                            <asp:ListItem Text="POST" Value="POST" /><asp:ListItem Text="HEAD" Value="HEAD" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg">
                        <label>Status</label>
                        <asp:DropDownList ID="DdlStatus" runat="server" CssClass="inp" style="width:130px;">
                            <asp:ListItem Text="All" Value="" /><asp:ListItem Text="2xx Success" Value="2" />
                            <asp:ListItem Text="3xx Redirect" Value="3" /><asp:ListItem Text="4xx Client Error" Value="4" />
                            <asp:ListItem Text="5xx Server Error" Value="5" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg">
                        <label>Rows / Page</label>
                        <asp:DropDownList ID="DdlPageSize" runat="server" CssClass="inp" style="width:90px;">
                            <asp:ListItem Text="50" Value="50" /><asp:ListItem Text="100" Value="100" Selected="True" />
                            <asp:ListItem Text="250" Value="250" /><asp:ListItem Text="500" Value="500" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg" style="justify-content:flex-end;">
                        <label>&nbsp;</label>
                        <asp:Button ID="BtnApply" runat="server" Text="Apply" CssClass="btn" OnClick="BtnApply_Click" />
                    </div>
                    <div class="fg" style="justify-content:flex-end;">
                        <label>&nbsp;</label>
                        <asp:Button ID="BtnExport" runat="server" Text="Export CSV" CssClass="btn sec" OnClick="BtnExport_Click" />
                    </div>
                </div>

                <!-- IIS Log Table -->
                <div class="table-wrap">
                    <div class="table-header">
                        <h2>&#128196; IIS Entries &nbsp;<span class="page-info"><asp:Literal ID="LitPageInfo" runat="server" /></span></h2>
                        <div class="pager">
                            <asp:Button ID="BtnPrev" runat="server" Text="&#8592; Prev" CssClass="pgbtn" OnClick="BtnPrev_Click" />
                            <asp:Button ID="BtnNext" runat="server" Text="Next &#8594;" CssClass="pgbtn" OnClick="BtnNext_Click" />
                        </div>
                    </div>
                    <div class="scroll-x">
                        <asp:Literal ID="LitTable" runat="server" />
                    </div>
                </div>

            </asp:Panel><!-- /PnlIIS -->

            <!-- ══ APP LOGS PANEL ══ -->
            <asp:Panel ID="PnlApp" runat="server" Visible="false">

                <!-- App KPIs -->
                <div class="kpi-row">
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitAppTotal" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Total Entries</div></div>
                    <div class="kpi red"><div class="kpi-val"><asp:Literal ID="LitAppErr" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Errors [ERR]</div></div>
                    <div class="kpi warn"><div class="kpi-val"><asp:Literal ID="LitAppWrn" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Warnings [WRN]</div></div>
                    <div class="kpi green"><div class="kpi-val"><asp:Literal ID="LitAppInf" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Info [INF]</div></div>
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitAppUniq" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Unique Messages</div></div>
                    <div class="kpi red"><div class="kpi-val"><asp:Literal ID="LitAppSpam" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Top Error Repeat&#215;</div></div>
                </div>

                <!-- App diagnosis banner -->
                <asp:Literal ID="LitAppDiag" runat="server" />

                <!-- App charts -->
                <div class="charts-row">
                    <div class="chart-card" style="grid-column:span 2;"><h3>&#128290; Top Recurring Errors</h3><div class="bar-list"><asp:Literal ID="LitAppTopErr" runat="server" /></div></div>
                    <div class="chart-card"><h3>&#127381; Level Breakdown</h3><div class="bar-list"><asp:Literal ID="LitAppLevels" runat="server" /></div></div>
                </div>

                <!-- App filter bar -->
                <div class="filter-bar">
                    <div class="fg">
                        <label>Log File</label>
                        <asp:DropDownList ID="DdlAppFile" runat="server" CssClass="inp" AutoPostBack="true"
                            OnSelectedIndexChanged="DdlAppFile_Changed" style="min-width:220px;" />
                    </div>
                    <div class="fg">
                        <label>Level</label>
                        <asp:DropDownList ID="DdlAppLevel" runat="server" CssClass="inp" style="width:120px;">
                            <asp:ListItem Text="All Levels" Value="" />
                            <asp:ListItem Text="&#9888; ERR only" Value="ERR" />
                            <asp:ListItem Text="&#9888; WRN only" Value="WRN" />
                            <asp:ListItem Text="&#8505; INF only" Value="INF" />
                            <asp:ListItem Text="&#128269; DBG only" Value="DBG" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg">
                        <label>Keyword (contains)</label>
                        <asp:TextBox ID="TxtAppKeyword" runat="server" CssClass="inp" placeholder="e.g. token  authentication  PopulateData" style="width:240px;" />
                    </div>
                    <div class="fg">
                        <label>Hide Stack Traces</label>
                        <asp:DropDownList ID="DdlAppStack" runat="server" CssClass="inp" style="width:130px;">
                            <asp:ListItem Text="Show All" Value="show" />
                            <asp:ListItem Text="Header Only" Value="hide" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg">
                        <label>Deduplicate</label>
                        <asp:DropDownList ID="DdlAppDedup" runat="server" CssClass="inp" style="width:130px;">
                            <asp:ListItem Text="All Rows" Value="" />
                            <asp:ListItem Text="Unique Only" Value="1" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg">
                        <label>Rows / Page</label>
                        <asp:DropDownList ID="DdlAppPageSize" runat="server" CssClass="inp" style="width:90px;">
                            <asp:ListItem Text="25" Value="25" />
                            <asp:ListItem Text="50" Value="50" Selected="True" />
                            <asp:ListItem Text="100" Value="100" />
                            <asp:ListItem Text="200" Value="200" />
                        </asp:DropDownList>
                    </div>
                    <div class="fg" style="justify-content:flex-end;">
                        <label>&nbsp;</label>
                        <asp:Button ID="BtnAppApply" runat="server" Text="Apply" CssClass="btn" OnClick="BtnAppApply_Click" />
                    </div>
                </div>

                <!-- App Log Table -->
                <div class="table-wrap">
                    <div class="table-header">
                        <h2>&#9881; App Entries &nbsp;<span class="page-info"><asp:Literal ID="LitAppPageInfo" runat="server" /></span></h2>
                        <div class="pager">
                            <asp:Button ID="BtnAppPrev" runat="server" Text="&#8592; Prev" CssClass="pgbtn" OnClick="BtnAppPrev_Click" />
                            <asp:Button ID="BtnAppNext" runat="server" Text="Next &#8594;" CssClass="pgbtn" OnClick="BtnAppNext_Click" />
                        </div>
                    </div>
                    <div class="scroll-x">
                        <asp:Literal ID="LitAppTable" runat="server" />
                    </div>
                </div>

            </asp:Panel><!-- /PnlApp -->

            <!-- ══ CONNECTIONS PANEL ══ -->
            <asp:Panel ID="PnlConn" runat="server" Visible="false">
                <div class="table-wrap" style="margin-bottom:18px;">
                    <div class="table-header">
                        <h2>&#128423; Active Web Connections (Ports 80 &amp; 443)</h2>
                        <asp:Button ID="BtnRefreshConn" runat="server" Text="&#8635; Refresh Connections" CssClass="btn sec" OnClick="BtnRefreshConn_Click" />
                    </div>
                    <div class="scroll-x" style="padding: 16px;">
                        <asp:Literal ID="LitConnTable" runat="server" />
                    </div>
                </div>
            </asp:Panel><!-- /PnlConn -->

            <!-- ══ LOGIN AUDIT PANEL ══ -->
            <asp:Panel ID="PnlAudit" runat="server" Visible="false">
                <div style="display:flex; gap:14px; flex-wrap:wrap; margin-bottom:18px;">
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitAuditLoginsToday" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Logins Today</div></div>
                    <div class="kpi red"><div class="kpi-val"><asp:Literal ID="LitAuditFailures" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Failures Today</div></div>
                    <div class="kpi green"><div class="kpi-val"><asp:Literal ID="LitAuditUnique" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Unique Users (7d)</div></div>
                    <div class="kpi"><div class="kpi-val"><asp:Literal ID="LitAuditTotal" runat="server">&mdash;</asp:Literal></div><div class="kpi-lbl">Total Entries</div></div>
                </div>
                <div class="table-wrap">
                    <div class="table-header">
                        <h2>&#128221; Login Audit Trail &nbsp;<span class="page-info">Last 100 entries &mdash; 90-day rolling window</span></h2>
                    </div>
                    <div class="scroll-x" style="padding:16px;">
                        <asp:Literal ID="LitAuditTable" runat="server" />
                    </div>
                </div>
            </asp:Panel><!-- /PnlAudit -->

        </asp:Panel>
    </div>

    <asp:HiddenField ID="HidPage" runat="server" Value="0" />
    <asp:HiddenField ID="HidTab" runat="server" Value="iis" />
    <asp:HiddenField ID="HidAppPage" runat="server" Value="0" />
    <idash:Footer runat="server" />
</form>
</body>
</html>


