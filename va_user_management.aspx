<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_user_management.aspx.cs" Inherits="va_user_management" EnableEventValidation="false" MaintainScrollPositionOnPostback="true" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash User Management</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <asp:Literal ID="LitSiteJson" runat="server" />
    <style>
        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        * { box-sizing: border-box; }
        body { margin:0; background:var(--bg); color:var(--text); font-family:Segoe UI,sans-serif; }

        .status-bar { display:flex; justify-content:space-between; background:var(--chip); padding:8px 20px; font-size:13px; border-bottom:1px solid var(--line); }

        .wrap { max-width:1280px; margin:30px auto; padding:0 24px; }
        .page-title { font-size:26px; font-weight:700; margin-bottom:4px; }
        .page-sub   { color:var(--muted); font-size:13px; margin-bottom:28px; }

        .card { background:var(--card); border:1px solid var(--line); border-radius:12px; padding:24px; margin-bottom:24px; }
        .card-title { font-size:17px; font-weight:700; margin:0 0 18px; color:var(--accent); display:flex; align-items:center; gap:10px; }

        .grid-wrap { overflow-x:auto; }
        table.ug { width:100%; border-collapse:collapse; font-size:13px; }
        table.ug th { background:var(--chip); color:var(--muted); text-align:left; padding:10px 14px; border-bottom:2px solid var(--line); font-weight:600; white-space:nowrap; }
        table.ug td { padding:10px 14px; border-bottom:1px solid var(--line); vertical-align:middle; }
        table.ug tr:last-child td { border-bottom:none; }
        table.ug tr:hover td { background:color-mix(in srgb, var(--accent), transparent 95%); }

        .badge { display:inline-flex; align-items:center; gap:4px; padding:3px 10px; border-radius:20px; font-size:11px; font-weight:700; margin:2px 2px 2px 0; white-space:nowrap; }
        .badge-admin    { background:color-mix(in srgb, var(--danger), transparent 85%);   color:#ef4444; border:1px solid rgba(239,68,68,.3); }
        .badge-user     { background:color-mix(in srgb, var(--accent), transparent 85%);  color:#2ea8ff; border:1px solid rgba(46,168,255,.3); }
        .badge-readonly { background:rgba(138,160,197,.15); color:var(--muted); border:1px solid rgba(138,160,197,.3); }
        .badge-on  { background:color-mix(in srgb, var(--accent-2), transparent 85%);  color:#10b981; border:1px solid rgba(16,185,129,.3); }
        .badge-off { background:color-mix(in srgb, var(--danger), transparent 85%);   color:#ef4444; border:1px solid rgba(239,68,68,.3); }
        .badge-full { background:color-mix(in srgb, var(--accent-2), transparent 85%); color:#10b981; border:1px solid rgba(16,185,129,.3); font-size:10px; }
        .badge-ennx { background:color-mix(in srgb, var(--accent), transparent 85%); color:#2ea8ff; border:1px solid rgba(46,168,255,.3); font-size:10px; }

        .btn { display:inline-flex; align-items:center; gap:6px; padding:8px 16px; border-radius:8px; border:none; font-weight:600; font-size:13px; cursor:pointer; transition:.15s; }
        .btn-primary { background:var(--accent);   color:#fff; }
        .btn-green   { background:var(--accent-2); color:#000; }
        .btn-danger  { background:var(--danger);   color:#fff; }
        .btn-ghost   { background:transparent; border:1px solid var(--line); color:var(--text); }
        .btn-sm      { padding:5px 10px; font-size:12px; border-radius:6px; }
        .btn:hover   { opacity:.85; transform:translateY(-1px); }

        .form-row   { display:flex; flex-wrap:wrap; gap:16px; margin-bottom:16px; }
        .form-col   { display:flex; flex-direction:column; gap:6px; min-width:160px; flex:1; }
        .form-col.narrow { max-width:200px; }
        .form-col label { font-size:12px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.4px; }
        .form-col input, .form-col select, .form-col textarea {
            background:var(--bg); border:1px solid var(--line); color:var(--text);
            padding:9px 12px; border-radius:8px; font-size:14px; outline:none; font-family:inherit;
        }
        .form-col input:focus, .form-col select:focus, .form-col textarea:focus { border-color:var(--accent); }
        .form-col textarea { resize:vertical; min-height:56px; }

        /* - Site permission builder - */
        .site-section { margin-top:4px; }
        .site-section-title { font-size:12px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.4px; margin-bottom:10px; display:flex; align-items:center; gap:10px; }
        .site-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(280px,1fr)); gap:8px; max-height:260px; overflow-y:auto; padding:2px; }
        .site-row { display:flex; align-items:center; gap:8px; background:var(--bg); border:1px solid var(--line); border-radius:8px; padding:8px 12px; transition:.15s; }
        .site-row:hover { border-color:var(--accent); }
        .site-row input[type=checkbox] { width:16px; height:16px; accent-color:var(--accent-2); cursor:pointer; flex-shrink:0; }
        .site-row .site-name { flex:1; font-size:13px; font-weight:500; }
        .site-row select { flex-shrink:0; width:170px; padding:5px 8px; font-size:12px; background:var(--chip); border:1px solid var(--line); border-radius:6px; color:var(--text); }
        .site-row.checked { border-color:var(--accent-2); background:color-mix(in srgb, var(--accent-2), transparent 92%); }
        .wildcard-row { background:rgba(250,204,21,.06); border-color:rgba(250,204,21,.3) !important; }
        .wildcard-row .site-name { color:var(--warn); font-weight:700; }

        .alert { padding:12px 16px; border-radius:8px; margin-bottom:16px; border-left:4px solid; font-size:13px; }
        .alert-ok   { background:color-mix(in srgb, var(--accent-2), transparent 85%); border-color:var(--accent-2); color:var(--accent-2); }
        .alert-err  { background:color-mix(in srgb, var(--danger), transparent 85%);  border-color:var(--danger);   color:var(--danger); }
        .alert-info { background:color-mix(in srgb, var(--accent), transparent 85%);  border-color:var(--accent);   color:var(--accent); }

        .modal-overlay { position:fixed; inset:0; background:rgba(0,0,0,.75); z-index:9000; display:flex; align-items:center; justify-content:center; }
        .modal-box { background:var(--card); border:1px solid var(--line); border-radius:14px; padding:28px; width:700px; max-width:96vw; max-height:93vh; overflow-y:auto; box-shadow:0 24px 60px rgba(0,0,0,.5); }
        .modal-title { font-size:18px; font-weight:700; color:var(--accent); margin:0 0 20px; }

        /* role capability chart */
        .role-caps { display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; }
        .role-cap { background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:12px; text-align:center; font-size:12px; line-height:1.7; }
        .role-cap .rcn { font-weight:700; font-size:13px; margin-bottom:6px; }
        .rc-admin    { border-color:color-mix(in srgb, var(--danger), transparent 55%); }
        .rc-user     { border-color:color-mix(in srgb, var(--accent), transparent 55%); }
        .rc-readonly { border-color:rgba(138,160,197,.35); }
        .check { color:var(--accent-2); } .cross { color:var(--danger); }

        .perm-legend { display:flex; gap:14px; flex-wrap:wrap; margin-top:10px; font-size:12px; }
        .perm-legend span { display:flex; align-items:center; gap:6px; color:var(--muted); }
        .dot { width:10px; height:10px; border-radius:50%; }
        .dot-full { background:#10b981; }
        .dot-ennx { background:#2ea8ff; }
        .dot-none { background:#374151; }

        hr.sep { border:none; border-top:1px solid var(--line); margin:18px 0; }
        .muted { color:var(--muted); font-size:12px; }

        @keyframes fade-in { from{opacity:0;transform:translateY(-6px)} to{opacity:1;transform:none} }
        .animate-in { animation:fade-in .22s ease; }

        /* System toggle tabs */
        .system-toggle { display:flex; gap:0; margin-bottom:24px; border-radius:12px; overflow:hidden; border:1px solid var(--line); background:var(--chip); }
        .sys-tab {
            flex:1; padding:14px 20px; text-align:center; cursor:pointer; font-weight:700; font-size:14px;
            border:none; background:transparent; color:var(--muted); transition:.2s;
            display:flex; align-items:center; justify-content:center; gap:10px; position:relative;
        }
        .sys-tab:hover { background:color-mix(in srgb, var(--accent), transparent 92%); }
        .sys-tab.active { background:var(--card); color:var(--text); box-shadow:0 2px 8px rgba(0,0,0,.1); }
        .sys-tab .sys-dot { width:10px; height:10px; border-radius:50%; flex-shrink:0; }
        .sys-tab .sys-desc { font-size:11px; font-weight:400; color:var(--muted); margin-top:2px; }
        .sys-tab-idash .sys-dot  { background:#a855f7; }
        .sys-tab-aw .sys-dot     { background:#f59e0b; }
        .sys-tab-idash.active { border-bottom:3px solid #a855f7; }
        .sys-tab-aw.active    { border-bottom:3px solid #f59e0b; }
        .section-hidden { display:none !important; }

        /* AW iframe */
        #awFrame { width:100%; border:none; border-radius:12px; min-height:700px; background:var(--card); }

        /* Floating Toast for scroll-retained operations */
        .floating-toast {
            position: fixed;
            bottom: 28px;
            right: 28px;
            z-index: 99999;
            padding: 14px 22px;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
            animation: toastSlideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            max-width: 480px;
        }
        .floating-toast.toast-ok {
            background: #059669;
            color: #ffffff;
            border: 1px solid #10b981;
        }
        .floating-toast.toast-err {
            background: #dc2626;
            color: #ffffff;
            border: 1px solid #ef4444;
        }
        .floating-toast.toast-fadeout {
            opacity: 0;
            transform: translateY(12px);
            transition: opacity 0.4s ease, transform 0.4s ease;
        }
        @keyframes toastSlideUp {
            from { opacity: 0; transform: translateY(24px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
<form id="form1" runat="server">

    <div class="status-bar">
        <span>iDash - User Management</span>
        <span style="color:#10b981; font-weight:700;">&#9679; CONNECTED</span>
    </div>

    <!-- - Access denied - -->
    <asp:Panel ID="PnlAccessDenied" runat="server" Visible="false">
        <div class="wrap" style="margin-top:80px; text-align:center;">
            <div style="font-size:48px; margin-bottom:16px;">&#128274;</div>
            <div style="font-size:22px; font-weight:700; margin-bottom:8px;">Access Restricted</div>
            <p style="color:var(--muted);">Only administrators can manage iDash users.</p>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </asp:Panel>

    <!-- - Main panel - -->
    <asp:Panel ID="PnlMain" runat="server" Visible="false">
    <div class="wrap">

        <div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-bottom:6px;">
            <div>
                <div class="page-title">&#128100; User Management</div>
                <div class="page-sub">Manage iDash portal users and RFID scanner accounts from one place.</div>
            </div>
            <div style="display:flex; gap:8px; align-items:center;">
                <a href="documentation/va_user_management.html" class="btn btn-ghost" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a>
                <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
            </div>
        </div>

        <!-- SYSTEM TOGGLE -->
        <div class="system-toggle">
            <button type="button" class="sys-tab sys-tab-idash active" onclick="switchSystem('idash')">
                <span class="sys-dot"></span>
                <div>
                    <div>iDash Portal Users</div>
                    <div class="sys-desc">Web portal login accounts &mdash; roles, tile access, site permissions</div>
                </div>
            </button>
            <button type="button" class="sys-tab sys-tab-aw" onclick="switchSystem('aw')">
                <span class="sys-dot"></span>
                <div>
                    <div>Scanner &amp; System Users</div>
                    <div class="sys-desc">Scanner &amp; mobile app accounts &mdash; dbo.sysuser table</div>
                </div>
            </button>
            <button type="button" class="sys-tab" style="border-color:#10b981;" onclick="switchSystem('companies')">
                <span class="sys-dot" style="background:#10b981;"></span>
                <div>
                    <div>Companies / Sites</div>
                    <div class="sys-desc">Add, rename, delete facility sites &mdash; dbo.company table</div>
                </div>
            </button>
        </div>

        <!-- ===== iDASH SECTION ===== -->
        <div id="idashSection">

        <asp:Literal ID="LitMsg" runat="server" />

        <!--  Role capabilities reference  -->
        <div class="card">
            <div class="card-title">&#128274; Role &amp; Permission Reference</div>
            <div class="role-caps">
                <div class="role-cap rc-admin">
                    <div class="rcn" style="color:#ef4444;">Administrator</div>
                    <div><span class="check">&#10003;</span> All Reports &amp; Research</div>
                    <div><span class="check">&#10003;</span> All Scanning &amp; Tagging</div>
                    <div><span class="check">&#10003;</span> Admin Panel</div>
                    <div><span class="check">&#10003;</span> All Documentation</div>
                    <div><span class="check">&#10003;</span> User Management</div>
                    <div style="margin-top:6px; color:var(--muted); font-size:11px;">Ignores site access rules - always full access to all sites.</div>
                </div>
                <div class="role-cap rc-user">
                    <div class="rcn" style="color:#2ea8ff;">Standard User</div>
                    <div><span class="check">&#10003;</span> Reports &amp; Research</div>
                    <div><span class="check">&#10003;</span> Scanning &amp; Tagging</div>
                    <div><span class="cross">&#10007;</span> Admin Panel</div>
                    <div><span class="check">&#10003;</span> Documentation</div>
                    <div><span class="cross">&#10007;</span> User Management</div>
                    <div style="margin-top:6px; color:var(--muted); font-size:11px;">Limited to assigned sites. Site permissions control what they can do per site.</div>
                </div>
                <div class="role-cap rc-readonly">
                    <div class="rcn" style="color:var(--muted);">Read-Only</div>
                    <div><span class="check">&#10003;</span> Reports &amp; Research</div>
                    <div><span class="cross">&#10007;</span> Scanning &amp; Tagging</div>
                    <div><span class="cross">&#10007;</span> Admin Panel</div>
                    <div><span class="check">&#10003;</span> Documentation</div>
                    <div><span class="cross">&#10007;</span> User Management</div>
                    <div style="margin-top:6px; color:var(--muted); font-size:11px;">Can view reports and generate ENNX for assigned sites only.</div>
                </div>
            </div>

            <div class="perm-legend" style="margin-top:16px;">
                <strong style="color:var(--muted); font-size:12px; align-self:center;">SITE PERMISSIONS:</strong>
                <span><span class="dot dot-full"></span><strong style="color:#10b981;">Full</strong> - move assets, commit scans, full inventory operations</span>
                <span><span class="dot dot-ennx"></span><strong style="color:#2ea8ff;">ENNX / Report Only</strong> - view data + generate ENNX reports; cannot move assets or commit</span>
                <span><span class="dot dot-none"></span><strong style="color:var(--muted);">No Access</strong> - site not shown to user</span>
            </div>
        </div>

        <!-- - User table - -->
        <div class="card">
            <div class="card-title" style="justify-content:space-between;">
                <span>&#128101; Portal Users</span>
                <button type="button" class="btn btn-green btn-sm" onclick="showAddModal()">&#43; Add User</button>
            </div>

            <div class="grid-wrap">
                <asp:GridView ID="GridUsers" runat="server" CssClass="ug" AutoGenerateColumns="false"
                    DataKeyNames="Username" OnRowCommand="GridUsers_RowCommand" ClientIDMode="Static">
                    <Columns>
                        <asp:TemplateField HeaderText="Username">
                            <ItemTemplate>
                                <strong><%# Eval("Username") %></strong><br/>
                                <span class="muted"><%# Eval("DisplayName") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Role">
                            <ItemTemplate>
                                <span class='badge badge-<%# Eval("Role") %>'>
                                    <%# UserManager.RoleLabel(Eval("Role").ToString()) %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Status">
                            <ItemTemplate>
                                <span class='badge <%# (bool)Eval("Enabled") ? "badge-on" : "badge-off" %>'>
                                    <%# (bool)Eval("Enabled") ? "&#9679; Enabled" : "&#9679; Disabled" %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Tile Access">
                            <ItemTemplate>
                                <span style="font-size:12px; color:var(--muted);"><%# UserManager.TileAccessSummary((UserManager.IdashUser)Container.DataItem) %></span>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Site Access">
                            <ItemTemplate>
                                <span style="font-size:12px; color:var(--muted);"><%# UserManager.SiteAccessSummary((UserManager.IdashUser)Container.DataItem) %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:BoundField DataField="CreatedDate" HeaderText="Created" />
                        <asp:BoundField DataField="LastLogin"   HeaderText="Last Login" />
                        <asp:TemplateField HeaderText="Agreement">
                            <ItemTemplate>
                                <%# string.IsNullOrEmpty(Eval("AgreementAcceptedDate") as string) 
                                    ? "<span class='badge badge-off' title='Pending acceptance on next login'>&#9679; Pending</span>" 
                                    : "<span class='badge badge-on' title='Accepted: " + Eval("AgreementAcceptedDate") + "'>&#10003; Accepted</span>" %>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="Notes"       HeaderText="Notes" />

                        <asp:TemplateField HeaderText="Actions">
                            <ItemTemplate>
                                <button type="button" class="btn btn-ghost btn-sm btn-edit-user"
                                    data-username='<%# Server.HtmlEncode(Eval("Username") as string ?? "") %>'
                                    data-displayname='<%# Server.HtmlEncode(Eval("DisplayName") as string ?? "") %>'
                                    data-role='<%# Server.HtmlEncode(Eval("Role") as string ?? "") %>'
                                    data-enabled='<%# (bool)Eval("Enabled") ? "true" : "false" %>'
                                    data-notes='<%# Server.HtmlEncode(Eval("Notes") as string ?? "") %>'
                                    data-siteaccess='<%# GetSiteAccessJson(Container.DataItem) %>'
                                    data-tileaccess='<%# GetTileAccessJson(Container.DataItem) %>'>Edit</button>

                                <asp:Button runat="server" Text="Delete"
                                    CommandName="DeleteUser"
                                    CommandArgument='<%# Eval("Username") %>'
                                    CssClass="btn btn-danger btn-sm"
                                    OnClientClick='<%# "return confirmDelete(\"" + Eval("Username") + "\");" %>' />
                                <button type="button" class="btn btn-ghost btn-sm btn-clone-user" style="font-size:11px;"
                                    data-role='<%# Server.HtmlEncode(Eval("Role") as string ?? "") %>'
                                    data-displayname='<%# Server.HtmlEncode(Eval("DisplayName") as string ?? "") %>'
                                    data-siteaccess='<%# GetSiteAccessJson(Container.DataItem) %>'
                                    data-tileaccess='<%# GetTileAccessJson(Container.DataItem) %>'>&#128203; Clone</button>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                    <EmptyDataTemplate>
                        <div style="padding:24px; text-align:center; color:var(--muted);">No users found.</div>
                    </EmptyDataTemplate>
                </asp:GridView>
            </div>
        </div>

        <!-- LOGIN HISTORY -->
        <div class="card">
            <div class="card-title">&#128221; Login History
                <span style="font-size:12px; font-weight:400; color:var(--muted); margin-left:auto;">Last 50 entries &mdash; auto-trimmed at 90 days / 5,000 max</span>
            </div>
            <div style="display:flex; gap:14px; flex-wrap:wrap; margin-bottom:18px;">
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:12px 18px; min-width:120px; text-align:center;">
                    <div style="font-size:22px; font-weight:800; color:var(--accent);"><asp:Literal ID="LitLoginsToday" runat="server" Text="0" /></div>
                    <div style="font-size:11px; color:var(--muted); margin-top:2px;">Logins Today</div>
                </div>
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:12px 18px; min-width:120px; text-align:center;">
                    <div style="font-size:22px; font-weight:800; color:#ef4444;"><asp:Literal ID="LitFailuresToday" runat="server" Text="0" /></div>
                    <div style="font-size:11px; color:var(--muted); margin-top:2px;">Failures Today</div>
                </div>
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:12px 18px; min-width:120px; text-align:center;">
                    <div style="font-size:22px; font-weight:800; color:#10b981;"><asp:Literal ID="LitUniqueUsers" runat="server" Text="0" /></div>
                    <div style="font-size:11px; color:var(--muted); margin-top:2px;">Unique Users (7d)</div>
                </div>
                <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:12px 18px; min-width:120px; text-align:center;">
                    <div style="font-size:22px; font-weight:800; color:var(--muted);"><asp:Literal ID="LitTotalEntries" runat="server" Text="0" /></div>
                    <div style="font-size:11px; color:var(--muted); margin-top:2px;">Total Entries</div>
                </div>
            </div>
            <div class="grid-wrap">
                <asp:Literal ID="LitLoginHistory" runat="server" />
            </div>
        </div>

        <!-- hidden postback fields -->
        <asp:HiddenField ID="HfAddUsername"    runat="server" />
        <asp:HiddenField ID="HfAddPassword"    runat="server" />
        <asp:HiddenField ID="HfAddRole"        runat="server" />
        <asp:HiddenField ID="HfAddDisplayName" runat="server" />
        <asp:HiddenField ID="HfAddNotes"       runat="server" />
        <asp:HiddenField ID="HfAddSiteAccess"  runat="server" />
        <asp:HiddenField ID="HfAddTileAccess"  runat="server" />
        <asp:HiddenField ID="HfAddAlsoCreateAw" runat="server" />
        <asp:HiddenField ID="HfAddAwUserType"   runat="server" />
        <asp:HiddenField ID="HfAddAwCompanyId"  runat="server" />

        <asp:HiddenField ID="HfEditUsername"    runat="server" />
        <asp:HiddenField ID="HfEditPassword"    runat="server" />
        <asp:HiddenField ID="HfEditRole"        runat="server" />
        <asp:HiddenField ID="HfEditDisplayName" runat="server" />
        <asp:HiddenField ID="HfEditNotes"       runat="server" />
        <asp:HiddenField ID="HfEditEnabled"     runat="server" />
        <asp:HiddenField ID="HfEditSiteAccess"  runat="server" />
        <asp:HiddenField ID="HfEditTileAccess"  runat="server" />

        <asp:Button ID="BtnAddSubmit"  runat="server" style="display:none;" OnClick="BtnAddSubmit_Click"  UseSubmitBehavior="false" />
        <asp:Button ID="BtnEditSubmit" runat="server" style="display:none;" OnClick="BtnEditSubmit_Click" UseSubmitBehavior="false" />

    </div><!-- /idashSection -->

    <!-- ===== SCANNER & SYSTEM USERS SECTION ===== -->
    <div id="awSection" class="section-hidden">
        <asp:Literal ID="LitAwMsg" runat="server" />
        <div class="card">
            <div class="card-title" style="justify-content:space-between;">
                <span>&#128737; Scanner &amp; System Users</span>
                <button type="button" class="btn btn-green btn-sm" onclick="showAwAddModal()">+ Add User</button>
            </div>
            <p style="color:var(--muted); font-size:13px; margin:0 0 14px;">
                Accounts stored in <code>dbo.sysuser</code> &mdash; used for RFID scanners and mobile handhelds.
                Username, password, user type, company/site, and scanner permissions are all managed here.
            </p>
            <div class="grid-wrap">
                <asp:GridView ID="GridAwUsers" runat="server" CssClass="ug" AutoGenerateColumns="false"
                    DataKeyNames="Id" OnRowCommand="GridAwUsers_RowCommand" ClientIDMode="Static">
                    <Columns>
                        <asp:TemplateField HeaderText="Username">
                            <ItemTemplate>
                                <strong><%# Eval("Username") %></strong><br/>
                                <span class="muted"><%# Eval("FirstName") %> <%# Eval("LastName") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="Email"       HeaderText="Email" />
                        <asp:BoundField DataField="Phone"       HeaderText="Phone" />
                        <asp:TemplateField HeaderText="Type">
                            <ItemTemplate><span class="badge badge-new"><%# Eval("UserType") %></span></ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Company (Site)">
                            <ItemTemplate>
                                <%# Eval("CompanyName") %>
                                <span class="muted"><%# Eval("CompanyId") != null ? "(ID: " + Eval("CompanyId") + ")" : "" %></span>
                            </ItemTemplate>
                        </asp:TemplateField>
                                                                        <asp:TemplateField HeaderText="Actions">
                            <ItemTemplate>
                                <button type="button" class="btn btn-ghost btn-sm btn-edit-aw-user"
                                    data-id='<%# Eval("Id") %>'
                                    data-username='<%# Server.HtmlEncode(Eval("Username") as string ?? "") %>'
                                    data-firstname='<%# Server.HtmlEncode(Eval("FirstName") as string ?? "") %>'
                                    data-lastname='<%# Server.HtmlEncode(Eval("LastName") as string ?? "") %>'
                                    data-email='<%# Server.HtmlEncode(Eval("Email") as string ?? "") %>'
                                    data-phone='<%# Server.HtmlEncode(Eval("Phone") as string ?? "") %>'
                                    data-cardid='<%# Server.HtmlEncode(Eval("CardId") as string ?? "") %>'
                                    data-rfidtag='<%# Server.HtmlEncode(Eval("RfidTag") as string ?? "") %>'
                                    data-usertype='<%# Server.HtmlEncode(Eval("UserType") as string ?? "") %>'
                                    data-companyid='<%# Eval("CompanyId") ?? "" %>'>Edit</button>
                                <asp:Button runat="server" Text="Delete"
                                    CommandName="DeleteAwUser"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CssClass="btn btn-danger btn-sm"
                                    OnClientClick='<%# "return confirmDeleteAw(\"" + Eval("Username") + "\");" %>' />
                                <button type="button" class="btn btn-ghost btn-sm btn-clone-aw-user" style="font-size:11px;"
                                    data-usertype='<%# Server.HtmlEncode(Eval("UserType") as string ?? "") %>'
                                    data-companyid='<%# Eval("CompanyId") ?? "" %>'
                                    data-email='<%# Server.HtmlEncode(Eval("Email") as string ?? "") %>'
                                    data-phone='<%# Server.HtmlEncode(Eval("Phone") as string ?? "") %>'
                                    data-cardid='<%# Server.HtmlEncode(Eval("CardId") as string ?? "") %>'>&#128203; Clone</button>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                    <EmptyDataTemplate>
                        <div style="padding:24px; text-align:center; color:var(--muted);">No scanner users found. Check database connection.</div>
                    </EmptyDataTemplate>
                </asp:GridView>
            </div>
        </div>

        <!-- AW hidden fields -->
        <asp:HiddenField ID="HfAwAddUsername"        runat="server" />
        <asp:HiddenField ID="HfAwAddPassword"        runat="server" />
        <asp:HiddenField ID="HfAwAddFirstName"       runat="server" />
        <asp:HiddenField ID="HfAwAddLastName"        runat="server" />
        <asp:HiddenField ID="HfAwAddEmail"           runat="server" />
        <asp:HiddenField ID="HfAwAddPhone"           runat="server" />
        <asp:HiddenField ID="HfAwAddCardId"          runat="server" />
        <asp:HiddenField ID="HfAwAddRfidTag"         runat="server" />
        <asp:HiddenField ID="HfAwAddUserType"        runat="server" />
        <asp:HiddenField ID="HfAwAddCompanyId"       runat="server" />
        <asp:HiddenField ID="HfAwAddHidePopups"      runat="server" />
        <asp:HiddenField ID="HfAwAddInvLimited"      runat="server" />
        <asp:HiddenField ID="HfAwAddRestrictMobile"  runat="server" />
        <asp:HiddenField ID="HfAwAddAlsoCreateIdash"  runat="server" />
        <asp:HiddenField ID="HfAwAddIdashRole"        runat="server" />
        <asp:HiddenField ID="HfAwAddIdashSiteAccess"  runat="server" />
        <asp:HiddenField ID="HfAwAddIdashTileAccess"  runat="server" />
        <asp:HiddenField ID="HfAwEditId"             runat="server" />
        <asp:HiddenField ID="HfAwEditPassword"       runat="server" />
        <asp:HiddenField ID="HfAwEditFirstName"      runat="server" />
        <asp:HiddenField ID="HfAwEditLastName"       runat="server" />
        <asp:HiddenField ID="HfAwEditEmail"          runat="server" />
        <asp:HiddenField ID="HfAwEditPhone"          runat="server" />
        <asp:HiddenField ID="HfAwEditCardId"         runat="server" />
        <asp:HiddenField ID="HfAwEditRfidTag"        runat="server" />
        <asp:HiddenField ID="HfAwEditUserType"       runat="server" />
        <asp:HiddenField ID="HfAwEditCompanyId"      runat="server" />
        <asp:HiddenField ID="HfAwEditHidePopups"     runat="server" />
        <asp:HiddenField ID="HfAwEditInvLimited"     runat="server" />
        <asp:HiddenField ID="HfAwEditRestrictMobile" runat="server" />
        <asp:Button ID="BtnAddAwUser"  runat="server" style="display:none;" OnClick="BtnAddAwUser_Click"  UseSubmitBehavior="false" />
        <asp:Button ID="BtnEditAwUser" runat="server" style="display:none;" OnClick="BtnEditAwUser_Click" UseSubmitBehavior="false" />
    </div>

    <!-- ===== COMPANIES SECTION ===== -->
    <div id="companiesSection" class="section-hidden">
        <asp:Literal ID="LitCoMsg" runat="server" />
        <div class="card">
            <div class="card-title" style="justify-content:space-between;">
                <span>&#127970; Companies / Sites</span>
                <button type="button" class="btn btn-green btn-sm" onclick="showCoAddModal()">+ Add Company</button>
            </div>
            <p style="color:var(--muted); font-size:13px; margin:0 0 14px;">
                Facility sites stored in <code>dbo.company</code>. Deleting a site removes its asset data.
                Users are reassigned to the next available site.
            </p>
            <div class="grid-wrap">
                <table class="ug">
                    <thead><tr><th>ID</th><th>Company Name</th><th style="width:160px;">Actions</th></tr></thead>
                    <tbody id="coGridBody"><!-- populated by JS --></tbody>
                </table>
            </div>
        </div>

        <!-- Company hidden fields -->
        <asp:HiddenField ID="HfAddCompanyName"  runat="server" />
        <asp:HiddenField ID="HfEditCompanyId"   runat="server" />
        <asp:HiddenField ID="HfEditCompanyName" runat="server" />
        <asp:HiddenField ID="HfDeleteCompanyId" runat="server" />
        <asp:Button ID="BtnAddCompany"   runat="server" style="display:none;" OnClick="BtnAddCompany_Click"   UseSubmitBehavior="false" />
        <asp:Button ID="BtnEditCompany"  runat="server" style="display:none;" OnClick="BtnEditCompany_Click"  UseSubmitBehavior="false" />
        <asp:Button ID="BtnDeleteCompany" runat="server" style="display:none;" OnClick="BtnDeleteCompany_Click" UseSubmitBehavior="false" />
    </div>

    </div>
    </asp:Panel>
</form>

<!-- ======== ADD USER MODAL ======== -->
<div id="modalAdd" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in">
        <div class="modal-title">&#43; Add New User</div>

        <!-- Template Selector -->
        <div class="form-row" style="margin-bottom:12px;">
            <div class="form-col">
                <label>&#128203; Quick Template</label>
                <select id="add_template" onchange="applyTemplate('add')" style="border-color:var(--accent); font-weight:600;">
                    <option value="">-- No Template (Manual) --</option>
                </select>
                <span id="add_template_desc" style="font-size:11px; color:var(--muted); margin-top:2px;"></span>
            </div>
        </div>

        <div class="form-row">
            <div class="form-col">
                <label>Username *</label>
                <input type="text" id="add_username" autocomplete="off" placeholder="e.g. jsmith" />
            </div>
            <div class="form-col">
                <label>Display Name</label>
                <input type="text" id="add_displayname" placeholder="e.g. John Smith" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>Password * (min 6 chars)</label>
                <input type="password" id="add_password" autocomplete="new-password" />
            </div>
            <div class="form-col">
                <label>Confirm Password *</label>
                <input type="password" id="add_password2" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col narrow">
                <label>Portal Role *</label>
                <select id="add_role" onchange="onRoleChange('add')">
                    <option value="user">Standard User</option>
                    <option value="admin">Administrator</option>
                    <option value="readonly">Read-Only</option>
                </select>
            </div>
            <div class="form-col">
                <label>Notes</label>
                <textarea id="add_notes" rows="2" placeholder="Optional..."></textarea>
            </div>
        </div>

        <hr class="sep" />

        <!-- Site permissions -->
        <div class="site-section" id="add_site_section">
            <div class="site-section-title">
                &#127970; Site Access Permissions
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllSites('add', 'full')" style="font-size:11px;">All - Full</button>
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllSites('add', 'ennx')" style="font-size:11px;">All - ENNX</button>
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllSites('add', '')"     style="font-size:11px;">Clear All</button>
            </div>
            <div class="alert alert-info" id="add_admin_note" style="display:none; font-size:12px; padding:10px 14px;">
                &#128274; Administrators automatically have <strong>Full Access to ALL sites</strong>. Site assignments below are ignored for admin accounts.
            </div>
            <div class="site-grid" id="add_site_grid">
                <!-- populated by JS from window.idashSites -->
            </div>
        </div>

        <hr class="sep" />
        <div class="site-section" id="add_tile_section">
            <div class="site-section-title">
                &#128187; Tile Access Permissions
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllTiles('add', true)" style="font-size:11px;">Select All</button>
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllTiles('add', false)" style="font-size:11px;">Clear All</button>
            </div>
            <div class="alert alert-info" id="add_admin_tile_note" style="display:none; font-size:12px; padding:10px 14px;">
                &#128274; Administrators automatically see <strong>ALL Tiles</strong>. Assignments below are ignored for admins.
            </div>
            <div id="add_tile_grid" style="display:flex; flex-direction:column; gap:16px;"></div>
        </div>

        <!-- Cross-platform: Also create RFID Scanner account -->
        <hr class="sep" />
        <div style="display:flex; align-items:center; gap:10px; margin-bottom:10px;">
            <input type="checkbox" id="add_also_aw" onchange="toggleAwCrossCreate()" style="width:18px; height:18px; accent-color:#f59e0b; cursor:pointer;" />
            <label for="add_also_aw" style="font-size:14px; font-weight:700; color:#f59e0b; cursor:pointer; margin:0;">Also create RFID Scanner account</label>
        </div>
        <div id="add_aw_cross_section" style="display:none; padding:14px; background:rgba(245,158,11,.06); border:1px solid rgba(245,158,11,.25); border-radius:10px;">
            <div style="font-size:12px; color:var(--muted); margin-bottom:10px;">Same username &amp; password will be used for the RFID scanner account.</div>
            <div class="form-row">
                <div class="form-col narrow">
                    <label>AW User Type</label>
                    <select id="add_aw_usertype">
                        <option value="Create, Edit, Delete" selected>Standard (Create, Edit, Delete)</option>
                        <option value="Create, Edit">Create, Edit</option>
                        <option value="View Only">View Only</option>
                    </select>
                </div>
                <div class="form-col">
                    <label>Company / Site</label>
                    <select id="add_aw_companyid"><option value="">-- Auto (first site) --</option></select>
                </div>
            </div>
        </div>

        <div id="add_err" class="alert alert-err" style="display:none; margin-top:14px;"></div>

        <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:20px;">
            <button type="button" class="btn btn-ghost" onclick="closeAddModal()">Cancel</button>
            <button type="button" class="btn btn-green" onclick="submitAdd()">&#10003; Create User</button>
        </div>
    </div>
</div>

<!-- ======== EDIT USER MODAL ======== -->
<div id="modalEdit" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in">
        <div class="modal-title">&#9998; Edit User: <span id="edit_title_name" style="color:var(--text);"></span></div>

        <div class="form-row">
            <div class="form-col">
                <label>Display Name</label>
                <input type="text" id="edit_displayname" autocomplete="off" />
            </div>
            <div class="form-col narrow">
                <label>Portal Role</label>
                <select id="edit_role" onchange="onRoleChange('edit')">
                    <option value="user">Standard User</option>
                    <option value="admin">Administrator</option>
                    <option value="readonly">Read-Only</option>
                </select>
            </div>
            <div class="form-col narrow">
                <label>Account Status</label>
                <select id="edit_enabled">
                    <option value="true">&#9679; Enabled</option>
                    <option value="false">&#9679; Disabled</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>New Password (blank&nbsp;= unchanged)</label>
                <input type="password" id="edit_password" autocomplete="new-password" placeholder="(unchanged)" />
            </div>
            <div class="form-col">
                <label>Confirm New Password</label>
                <input type="password" id="edit_password2" autocomplete="new-password" placeholder="(unchanged)" />
            </div>
            <div class="form-col">
                <label>Notes</label>
                <textarea id="edit_notes" rows="2"></textarea>
            </div>
        </div>

        <hr class="sep" />

        <div class="site-section" id="edit_site_section">
            <div class="site-section-title">
                &#127970; Site Access Permissions
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllSites('edit', 'full')" style="font-size:11px;">All - Full</button>
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllSites('edit', 'ennx')" style="font-size:11px;">All - ENNX</button>
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllSites('edit', '')"     style="font-size:11px;">Clear All</button>
            </div>
            <div class="alert alert-info" id="edit_admin_note" style="display:none; font-size:12px; padding:10px 14px;">
                &#128274; Administrators automatically have <strong>Full Access to ALL sites</strong>. Site assignments below are ignored for admin accounts.
            </div>
            <div class="site-grid" id="edit_site_grid">
                <!-- populated by JS -->
            </div>
        </div>

        <hr class="sep" />
        <div class="site-section" id="edit_tile_section">
            <div class="site-section-title">
                &#128187; Tile Access Permissions
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllTiles('edit', true)" style="font-size:11px;">Select All</button>
                <button type="button" class="btn btn-ghost btn-sm" onclick="selectAllTiles('edit', false)" style="font-size:11px;">Clear All</button>
            </div>
            <div class="alert alert-info" id="edit_admin_tile_note" style="display:none; font-size:12px; padding:10px 14px;">
                &#128274; Administrators automatically see <strong>ALL Tiles</strong>. Assignments below are ignored for admins.
            </div>
            <div id="edit_tile_grid" style="display:flex; flex-direction:column; gap:16px;"></div>
        </div>

        <div id="edit_err" class="alert alert-err" style="display:none; margin-top:14px;"></div>

        <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:20px;">
            <button type="button" class="btn btn-ghost"   onclick="closeEditModal()">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="submitEdit()">&#10003; Save Changes</button>
        </div>
    </div>
</div>

<script>
// Sites injected server-side as JSON array: [{id:"...", name:"..."}]
var idashSites = window.idashSites || [];
var _editUsername = '';

// - Modal open/close -
function showAddModal() {
    buildSiteGrid('add', {}); buildTileGrid('add', []);
    onRoleChange('add');
    // Reset template + cross-platform
    var tmpl = document.getElementById('add_template'); if(tmpl) tmpl.value='';
    var tdesc = document.getElementById('add_template_desc'); if(tdesc) tdesc.textContent='';
    var cb = document.getElementById('add_also_aw'); if(cb) cb.checked = false;
    var cs = document.getElementById('add_aw_cross_section'); if(cs) cs.style.display = 'none';
    document.getElementById('modalAdd').style.display = 'flex';
    document.getElementById('add_username').focus();
}
function closeAddModal()  { document.getElementById('modalAdd').style.display  = 'none'; clearAddForm(); }
function closeEditModal() { document.getElementById('modalEdit').style.display = 'none'; }

function clearAddForm() {
    ['add_username','add_displayname','add_password','add_password2','add_notes'].forEach(function(id){
        document.getElementById(id).value = '';
    });
    document.getElementById('add_role').value = 'user';
    document.getElementById('add_err').style.display = 'none';
}

// - Role change handler -
function onRoleChange(prefix) {
    var role = document.getElementById(prefix + '_role').value;
    var note = document.getElementById(prefix + '_admin_note');
    var tnote = document.getElementById(prefix + '_admin_tile_note');
    if (note) note.style.display = (role === 'admin') ? 'block' : 'none';
    if (tnote) tnote.style.display = (role === 'admin') ? 'block' : 'none';
}

// - Build site grid from window.idashSites -
// - Build tile grid from window.idashTileGroups -
function buildTileGrid(prefix, existing) {
    var grid = document.getElementById(prefix + '_tile_grid');
    grid.innerHTML = '';
    if (!window.idashTileGroups) return;
    
    var hasWildcard = Array.isArray(existing) && existing.indexOf('*') !== -1;

    window.idashTileGroups.forEach(function(group) {
        var gname = group[0];
        var keys = group.slice(1);
        
        var groupDiv = document.createElement('div');
        groupDiv.innerHTML = '<div style="font-size:12px; font-weight:700; color:var(--muted); margin-bottom:6px; text-transform:uppercase;">' + gname + '</div><div class="site-grid"></div>';
        var innerGrid = groupDiv.querySelector('.site-grid');
        
        keys.forEach(function(k) {
            var cbId = prefix + '_tile_' + k;
            var isChecked = hasWildcard || (Array.isArray(existing) && existing.indexOf(k) !== -1);
            
            var row = document.createElement('div');
            row.className = 'site-row' + (isChecked ? ' checked' : '');
            row.id = prefix + '_trow_' + k;
            row.innerHTML = 
                '<input type="checkbox" id="' + cbId + '" data-key="' + k + '" data-prefix="' + prefix + '" ' + (isChecked ? 'checked' : '') + ' onchange="onTileCbChange(this)" />' +
                '<span class="site-name">' + escHtml(getTileLabel(k)) + '</span>';
            innerGrid.appendChild(row);
        });
        
        grid.appendChild(groupDiv);
    });
}

function getTileLabel(k) {
    var labels = {
        // Guides & Downloads
        "downloads":"Secure Downloads", "docs":"iDash Documentation Hub",
        "docs_arch":"Architecture & Rationale", "docs_print":"Printing Guide",
        "docs_cookbook":"IDI Mobile Connectivity Cookbook",
        // Reports
        "rpt_asset_master":"Asset Master", "rpt_tagging":"Tagging Dashboards & Activity",
        "rpt_data_quality":"Data Quality Report",
        "rpt_ennx":"ENNX Export Files", "rpt_sessions":"Past Inventory Sessions",
        "rpt_automation":"Daily Report Automation", "rpt_fixed_reader":"Fixed Reader Dashboard",
        // Scanning & Tools
        "scan_maps":"Site Location Maps & Tagging", "scan_tagteam":"Tag Team Scan",
        "scan_inventory":"VA Site Inventory", "scan_ennx":"ENNX Live Scan",
        "scan_eil":"EIL Live Scan", "scan_universal_ennx":"Universal ENNX Creator",
        "scan_locator":"RFID Asset Locator",
        // Printing
        "print_mapping":"Printer Administration", "admin_printer_routing":"Printer Routing Config",
        "excel_print":"Excel Equipment Import & Print",
        // Admin Panel
        "admin_sitedata":"Cart Data & Sync Hub (All-in-One)", "admin_autodb":"Auto DB Update & Watcher",
        "admin_field_sync":"Field Server Sync (.BAK Restore)", "admin_workbench":"DB Update Workbench & SQL Staging",
        "admin_manualdb":"Manual DB Update (Legacy)", "admin_sql":"SQL Upload",
        "admin_bcp":"VA On Network Queries", "admin_excel":"Excel Merge Tool",
        "admin_logs":"System Logs & Automation History",
        "admin_loganalyzer":"IIS & App Log Analyzer", "admin_restore":"Database Restore",
        "admin_users":"User Management (Consolidated)",
        // Admin - Extended
        "admin_training":"Training & Setup Hub", "admin_site_config":"Site Configuration",
        "admin_license_manager":"License Manager & Cart Keys",
        "admin_diagnostics":"System Diagnostics & Health Monitor",
        "admin_system_update":"System Update & Deploy",
        "admin_fhir_bridge":"FHIR Bridge Sync", "admin_reader_config":"Fixed Reader Configuration",
        "admin_tag_type":"Tag Type Management", "admin_mqtt":"MQTT / RabbitMQ Broker"
    };
    return labels[k] || k;
}

function onTileCbChange(cb) {
    var prefix = cb.getAttribute('data-prefix');
    var k = cb.getAttribute('data-key');
    var row = document.getElementById(prefix + '_trow_' + k);
    if (cb.checked) row.classList.add('checked');
    else row.classList.remove('checked');
}

function selectAllTiles(prefix, isChecked) {
    var cbs = document.querySelectorAll('#' + prefix + '_tile_grid input[type=checkbox]');
    cbs.forEach(function(cb) {
        cb.checked = isChecked;
        onTileCbChange(cb);
    });
}

function collectTileAccess(prefix) {
    var result = [];
    var cbs = document.querySelectorAll('#' + prefix + '_tile_grid input[type=checkbox]:checked');
    cbs.forEach(function(cb) {
        result.push(cb.getAttribute('data-key'));
    });
    return result;
}

function buildSiteGrid(prefix, existing) {
    // existing = {siteName: "full"|"ennx", ...}
    var grid = document.getElementById(prefix + '_site_grid');
    grid.innerHTML = '';

    if (!idashSites || idashSites.length === 0) {
        grid.innerHTML = '<div style="color:var(--muted); font-size:12px; padding:8px;">No sites found in database.</div>';
        return;
    }

    idashSites.forEach(function(site) {
        var sname  = site.name;
        var cbId   = prefix + '_cb_' + sname.replace(/\W/g,'_');
        var selId  = prefix + '_perm_' + sname.replace(/\W/g,'_');
        var curVal = existing[sname] || '';

        var row = document.createElement('div');
        row.className = 'site-row' + (curVal ? ' checked' : '');
        row.id = prefix + '_row_' + sname.replace(/\W/g,'_');

        row.innerHTML =
            '<input type="checkbox" id="' + cbId + '" data-site="' + sname + '" data-prefix="' + prefix + '" ' + (curVal ? 'checked' : '') + ' onchange="onSiteCbChange(this)" />' +
            '<span class="site-name">' + escHtml(sname) + '</span>' +
            '<select id="' + selId + '" data-site="' + sname + '" style="' + (curVal ? '' : 'display:none;') + '">' +
                '<option value="full"' + (curVal === 'full' ? ' selected' : '') + '>&#9679; Full Access</option>' +
                '<option value="ennx"' + (curVal === 'ennx' ? ' selected' : '') + '>&#9675; ENNX / Report Only</option>' +
            '</select>';

        grid.appendChild(row);
    });
}

function onSiteCbChange(cb) {
    var prefix = cb.getAttribute('data-prefix');
    var sname  = cb.getAttribute('data-site');
    var safeId = sname.replace(/\W/g,'_');
    var sel  = document.getElementById(prefix + '_perm_' + safeId);
    var row  = document.getElementById(prefix + '_row_'  + safeId);

    if (cb.checked) {
        sel.style.display = '';
        row.classList.add('checked');
    } else {
        sel.style.display = 'none';
        row.classList.remove('checked');
    }
}

function selectAllSites(prefix, perm) {
    var cbs = document.querySelectorAll('#' + prefix + '_site_grid input[type=checkbox]');
    cbs.forEach(function(cb) {
        var sname  = cb.getAttribute('data-site');
        var safeId = sname.replace(/\W/g,'_');
        var sel    = document.getElementById(prefix + '_perm_' + safeId);
        var row    = document.getElementById(prefix + '_row_'  + safeId);
        if (perm === '') {
            cb.checked = false;
            sel.style.display = 'none';
            row.classList.remove('checked');
        } else {
            cb.checked = true;
            sel.style.display = '';
            sel.value = perm;
            row.classList.add('checked');
        }
    });
}

function collectSiteAccess(prefix) {
    var result = {};
    var cbs = document.querySelectorAll('#' + prefix + '_site_grid input[type=checkbox]:checked');
    cbs.forEach(function(cb) {
        var sname  = cb.getAttribute('data-site');
        var safeId = sname.replace(/\W/g,'_');
        var sel    = document.getElementById(prefix + '_perm_' + safeId);
        if (sel) result[sname] = sel.value;
    });
    return result;
}

function escHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// - Error helper -
function showErr(elId, msg) {
    var el = document.getElementById(elId);
    el.innerText = msg;
    el.style.display = 'block';
}

// - Add submit -
function submitAdd() {
    var u  = document.getElementById('add_username').value.trim();
    var dn = document.getElementById('add_displayname').value.trim();
    var p  = document.getElementById('add_password').value;
    var p2 = document.getElementById('add_password2').value;
    var r  = document.getElementById('add_role').value;
    var n  = document.getElementById('add_notes').value.trim();

    document.getElementById('add_err').style.display = 'none';
    if (!u)               { showErr('add_err','Username is required.'); return; }
    if (u.indexOf(' ') !== -1) { showErr('add_err','Username cannot contain spaces. Use a single word like "jsmith" or "jordan".'); return; }
    if (!p)          { showErr('add_err','Password is required.'); return; }
    if (p.length < 6){ showErr('add_err','Password must be at least 6 characters.'); return; }
    if (p !== p2)    { showErr('add_err','Passwords do not match.'); return; }

    var siteAccess = collectSiteAccess('add');
    var tileAccess = collectTileAccess('add');

    document.getElementById('<%= HfAddUsername.ClientID    %>').value = u;
    document.getElementById('<%= HfAddPassword.ClientID    %>').value = p;
    document.getElementById('<%= HfAddRole.ClientID        %>').value = r;
    document.getElementById('<%= HfAddDisplayName.ClientID %>').value = dn;
    document.getElementById('<%= HfAddNotes.ClientID       %>').value = n;
    document.getElementById('<%= HfAddSiteAccess.ClientID  %>').value = JSON.stringify(siteAccess);
    document.getElementById('<%= HfAddTileAccess.ClientID  %>').value = JSON.stringify(tileAccess);

    // Cross-platform AW
    var alsoAw = document.getElementById('add_also_aw');
    if (alsoAw && alsoAw.checked) {
        document.getElementById('<%= HfAddAlsoCreateAw.ClientID %>').value = '1';
        document.getElementById('<%= HfAddAwUserType.ClientID %>').value = document.getElementById('add_aw_usertype').value;
        document.getElementById('<%= HfAddAwCompanyId.ClientID %>').value = document.getElementById('add_aw_companyid').value;
    } else {
        document.getElementById('<%= HfAddAlsoCreateAw.ClientID %>').value = '';
    }

    document.getElementById('<%= BtnAddSubmit.ClientID     %>').click();
}

// - Edit open -
function openEditModal(username, displayName, role, enabled, notes, siteAccessJson, tileAccessJson) {
    _editUsername = username;
    // Show display name in title (fall back to username if blank)
    document.getElementById('edit_title_name').innerText    = displayName || username;
    document.getElementById('edit_displayname').value       = displayName;
    document.getElementById('edit_role').value              = role;
    document.getElementById('edit_enabled').value           = enabled.toString().toLowerCase();
    document.getElementById('edit_notes').value             = notes;

    // Explicitly blank password fields AFTER a short delay so browser autofill
    // cannot re-populate them after we clear (autofill fires on open, not on set).
    document.getElementById('edit_password').value  = '';
    document.getElementById('edit_password2').value = '';
    setTimeout(function() {
        document.getElementById('edit_password').value  = '';
        document.getElementById('edit_password2').value = '';
    }, 80);

    document.getElementById('edit_err').style.display = 'none';

    var existing = {};
    try { existing = JSON.parse(siteAccessJson) || {}; } catch(e) {}

    buildSiteGrid('edit', existing);
    var existTiles = [];
    try { existTiles = JSON.parse(tileAccessJson) || []; } catch(e) {}
    buildTileGrid('edit', existTiles);
    onRoleChange('edit');
    document.getElementById('modalEdit').style.display = 'flex';
}

// - Edit submit -
function submitEdit() {
    var p  = document.getElementById('edit_password').value;
    var p2 = document.getElementById('edit_password2').value;

    document.getElementById('edit_err').style.display = 'none';
    if (p && p.length < 6) { showErr('edit_err','Password must be at least 6 characters.'); return; }
    if (p !== p2)          { showErr('edit_err','Passwords do not match.'); return; }

    var siteAccess = collectSiteAccess('edit');
    var tileAccess = collectTileAccess('edit');

    document.getElementById('<%= HfEditUsername.ClientID    %>').value = _editUsername;
    document.getElementById('<%= HfEditPassword.ClientID    %>').value = p;
    document.getElementById('<%= HfEditRole.ClientID        %>').value = document.getElementById('edit_role').value;
    document.getElementById('<%= HfEditDisplayName.ClientID %>').value = document.getElementById('edit_displayname').value.trim();
    document.getElementById('<%= HfEditNotes.ClientID       %>').value = document.getElementById('edit_notes').value.trim();
    document.getElementById('<%= HfEditEnabled.ClientID     %>').value = document.getElementById('edit_enabled').value;
    document.getElementById('<%= HfEditSiteAccess.ClientID  %>').value = JSON.stringify(siteAccess);
    document.getElementById('<%= HfEditTileAccess.ClientID  %>').value = JSON.stringify(tileAccess);
    document.getElementById('<%= BtnEditSubmit.ClientID     %>').click();
}

// ===== SCROLL POSITION PRESERVATION & FLOATING NOTIFICATIONS =====
function saveScrollPosition() {
    var y = window.scrollY || window.pageYOffset || document.documentElement.scrollTop || 0;
    try {
        sessionStorage.setItem('va_user_mgmt_scroll_pos', y.toString());
    } catch(e) {}
}

function restoreScrollPosition() {
    try {
        var saved = sessionStorage.getItem('va_user_mgmt_scroll_pos');
        if (saved !== null) {
            sessionStorage.removeItem('va_user_mgmt_scroll_pos');
            var targetY = parseInt(saved, 10);
            if (!isNaN(targetY) && targetY > 0) {
                window.scrollTo(0, targetY);
                requestAnimationFrame(function() { window.scrollTo(0, targetY); });
                setTimeout(function() { window.scrollTo(0, targetY); }, 50);
                setTimeout(function() { window.scrollTo(0, targetY); }, 150);
                setTimeout(function() { window.scrollTo(0, targetY); }, 350);
            }
        }
    } catch(e) {}
}

function checkFloatingToast() {
    var alerts = document.querySelectorAll('.alert-ok, .alert-err');
    for (var i = 0; i < alerts.length; i++) {
        var a = alerts[i];
        if (a && a.innerText.trim() && a.offsetParent !== null) {
            var isOk = a.classList.contains('alert-ok');
            var toast = document.createElement('div');
            toast.className = 'floating-toast ' + (isOk ? 'toast-ok' : 'toast-err');
            toast.innerHTML = a.innerHTML;
            document.body.appendChild(toast);
            setTimeout(function() {
                toast.classList.add('toast-fadeout');
                setTimeout(function() { if (toast.parentNode) toast.parentNode.removeChild(toast); }, 500);
            }, 4000);
            break;
        }
    }
}

window.addEventListener('beforeunload', saveScrollPosition);

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        restoreScrollPosition();
        checkFloatingToast();
    });
} else {
    restoreScrollPosition();
    checkFloatingToast();
}
window.addEventListener('load', restoreScrollPosition);

function confirmDelete(username) {
    var ok = confirm('Delete user "' + username + '"?\n\nThis cannot be undone.');
    if (ok) {
        saveScrollPosition();
    }
    return ok;
}

function confirmDeleteAw(username) {
    var ok = confirm('Delete user "' + username + '"?\n\nThis cannot be undone.');
    if (ok) {
        saveScrollPosition();
    }
    return ok;
}

// Close on overlay click
document.getElementById('modalAdd').addEventListener('click', function(e)  { if(e.target===this) closeAddModal();  });
document.getElementById('modalEdit').addEventListener('click', function(e) { if(e.target===this) closeEditModal(); });

// ===== SYSTEM TOGGLE (3 tabs) =====
function switchSystem(mode) {
    var idashSec   = document.getElementById('idashSection');
    var awSec      = document.getElementById('awSection');
    var coSec      = document.getElementById('companiesSection');
    var tabs       = document.querySelectorAll('.sys-tab');

    // Hide all sections, deactivate all tabs
    [idashSec, awSec, coSec].forEach(function(s){ if(s) s.classList.add('section-hidden'); });
    tabs.forEach(function(t){ t.classList.remove('active'); });

    if (mode === 'aw') {
        if (awSec) awSec.classList.remove('section-hidden');
        var t = document.querySelector('.sys-tab-aw');
        if (t) t.classList.add('active');
        window.location.hash = 'aw';
    } else if (mode === 'companies') {
        if (coSec) coSec.classList.remove('section-hidden');
        populateCoGrid();
        var tabs2 = document.querySelectorAll('.sys-tab');
        for (var i = 0; i < tabs2.length; i++) {
            if (tabs2[i].textContent.indexOf('Companies') >= 0) { tabs2[i].classList.add('active'); break; }
        }
        window.location.hash = 'companies';
    } else {
        if (idashSec) idashSec.classList.remove('section-hidden');
        var t2 = document.querySelector('.sys-tab-idash');
        if (t2) t2.classList.add('active');
        window.location.hash = 'idash';
    }
}

// ===== COMPANY GRID (Companies tab) =====
function populateCoGrid() {
    var tbody = document.getElementById('coGridBody');
    if (!tbody) return;
    tbody.innerHTML = '';
    if (!window.idashSites || window.idashSites.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3" style="color:var(--muted);padding:14px;">No companies found.</td></tr>';
        return;
    }
    window.idashSites.forEach(function(c) {
        var safeName = (c.name || '').replace(/'/g, "\\'");
        tbody.innerHTML +=
            '<tr>' +
            '<td>' + c.id + '</td>' +
            '<td>' + (c.name || '') + '</td>' +
            '<td>' +
            '<button type="button" class="btn btn-ghost btn-sm" style="margin-right:6px;" onclick="openCoEditModal(' + c.id + ',\'' + safeName + '\')">Edit</button>' +
            '<button type="button" class="btn btn-danger btn-sm" onclick="deleteCompany(' + c.id + ',\'' + safeName + '\')">Delete</button>' +
            '</td></tr>';
    });
}

// Add Company modal
function showCoAddModal() {
    document.getElementById('co_add_name').value = '';
    document.getElementById('co_add_err').style.display = 'none';
    document.getElementById('modalCoAdd').style.display = 'flex';
    setTimeout(function(){ document.getElementById('co_add_name').focus(); }, 50);
}
function submitCoAdd() {
    var name = document.getElementById('co_add_name').value.trim();
    if (!name) { showCoErr('co_add_err', 'Company name is required.'); return; }
    document.getElementById('<%= HfAddCompanyName.ClientID %>').value = name;
    document.getElementById('<%= BtnAddCompany.ClientID %>').click();
}

// Edit Company modal
function openCoEditModal(id, name) {
    document.getElementById('co_edit_name').value = name;
    document.getElementById('co_edit_err').style.display = 'none';
    document.getElementById('<%= HfEditCompanyId.ClientID %>').value = id.toString();
    document.getElementById('modalCoEdit').style.display = 'flex';
    setTimeout(function(){ document.getElementById('co_edit_name').focus(); }, 50);
}
function submitCoEdit() {
    var name = document.getElementById('co_edit_name').value.trim();
    if (!name) { showCoErr('co_edit_err', 'Company name is required.'); return; }
    document.getElementById('<%= HfEditCompanyName.ClientID %>').value = name;
    document.getElementById('<%= BtnEditCompany.ClientID %>').click();
}

// Delete company
function deleteCompany(id, name) {
    if (!confirm('DELETE company "' + name + '" (ID: ' + id + ')?\n\nUsers will be reassigned. Asset data for this company will be removed.\n\nThis cannot be undone!')) return;
    saveScrollPosition();
    document.getElementById('<%= HfDeleteCompanyId.ClientID %>').value = id.toString();
    document.getElementById('<%= BtnDeleteCompany.ClientID %>').click();
}

function showCoErr(elId, msg) {
    var el = document.getElementById(elId); el.innerText = msg; el.style.display = 'block';
}

// ===== AW USER MODALS =====
function showAwAddModal() {
    ['aw_add_username','aw_add_password','aw_add_firstname','aw_add_lastname',
     'aw_add_email','aw_add_phone','aw_add_cardid','aw_add_rfidtag'].forEach(function(id){
        var el = document.getElementById(id); if(el) el.value = '';
    });
    var ut = document.getElementById('aw_add_usertype'); if(ut) ut.value='Create, Edit, Delete';
    var co = document.getElementById('aw_add_companyid'); if(co) co.value='';
    var tmpl = document.getElementById('aw_add_template'); if(tmpl) tmpl.value='';
    var tdesc = document.getElementById('aw_add_template_desc'); if(tdesc) tdesc.textContent='';
    var cb = document.getElementById('aw_add_also_idash'); if(cb) cb.checked = false;
    var cs = document.getElementById('aw_add_idash_cross_section'); if(cs) cs.style.display = 'none';
    document.getElementById('aw_add_err').style.display = 'none';
    document.getElementById('modalAwAdd').style.display = 'flex';
}
function submitAwAdd() {
    var u = document.getElementById('aw_add_username').value.trim();
    var co = document.getElementById('aw_add_companyid').value;
    if (!u) { showAwErr('aw_add_err','Username is required.'); return; }
    if (!co) { showAwErr('aw_add_err','Company (Site) is required.'); return; }
    document.getElementById('<%= HfAwAddUsername.ClientID %>').value = u;
    document.getElementById('<%= HfAwAddPassword.ClientID %>').value = document.getElementById('aw_add_password').value;
    document.getElementById('<%= HfAwAddFirstName.ClientID %>').value = document.getElementById('aw_add_firstname').value.trim();
    document.getElementById('<%= HfAwAddLastName.ClientID %>').value  = document.getElementById('aw_add_lastname').value.trim();
    document.getElementById('<%= HfAwAddEmail.ClientID %>').value     = document.getElementById('aw_add_email').value.trim();
    document.getElementById('<%= HfAwAddPhone.ClientID %>').value     = document.getElementById('aw_add_phone').value.trim();
    document.getElementById('<%= HfAwAddCardId.ClientID %>').value    = document.getElementById('aw_add_cardid').value.trim();
    document.getElementById('<%= HfAwAddRfidTag.ClientID %>').value   = document.getElementById('aw_add_rfidtag').value.trim();
    document.getElementById('<%= HfAwAddUserType.ClientID %>').value  = document.getElementById('aw_add_usertype').value;
    document.getElementById('<%= HfAwAddCompanyId.ClientID %>').value = co;

    // Cross-platform iDash
    var alsoIdash = document.getElementById('aw_add_also_idash');
    if (alsoIdash && alsoIdash.checked) {
        document.getElementById('<%= HfAwAddAlsoCreateIdash.ClientID %>').value = '1';
        document.getElementById('<%= HfAwAddIdashRole.ClientID %>').value = document.getElementById('aw_add_idash_role').value;
        // Default all-sites full access for new iDash users created from AW
        var allSites = {};
        if (window.idashSites) window.idashSites.forEach(function(s){ allSites[s.name] = 'full'; });
        document.getElementById('<%= HfAwAddIdashSiteAccess.ClientID %>').value = JSON.stringify(allSites);
        document.getElementById('<%= HfAwAddIdashTileAccess.ClientID %>').value = '[]';
    } else {
        document.getElementById('<%= HfAwAddAlsoCreateIdash.ClientID %>').value = '';
    }

    document.getElementById('<%= BtnAddAwUser.ClientID %>').click();
}
function openAwEditModal(id,username,firstname,lastname,email,phone,usertype,companyid) {
    document.getElementById('aw_edit_id').value         = id;
    document.getElementById('aw_edit_username').value   = username;
    document.getElementById('aw_edit_firstname').value  = firstname;
    document.getElementById('aw_edit_lastname').value   = lastname;
    document.getElementById('aw_edit_email').value      = email;
    document.getElementById('aw_edit_phone').value      = phone;
            var ut = document.getElementById('aw_edit_usertype'); if(ut) ut.value = usertype||'5';
    var co = document.getElementById('aw_edit_companyid'); if(co) co.value = companyid||'';
    document.getElementById('aw_edit_password').value = '';
    document.getElementById('aw_edit_err').style.display = 'none';
    document.getElementById('modalAwEdit').style.display = 'flex';
}
function submitAwEdit() {
    var co = document.getElementById('aw_edit_companyid').value;
    if (!co) { showAwErr('aw_edit_err','Company (Site) is required.'); return; }
    document.getElementById('<%= HfAwEditId.ClientID %>').value         = document.getElementById('aw_edit_id').value;
    document.getElementById('<%= HfAwEditPassword.ClientID %>').value   = document.getElementById('aw_edit_password').value;
    document.getElementById('<%= HfAwEditFirstName.ClientID %>').value  = document.getElementById('aw_edit_firstname').value.trim();
    document.getElementById('<%= HfAwEditLastName.ClientID %>').value   = document.getElementById('aw_edit_lastname').value.trim();
    document.getElementById('<%= HfAwEditEmail.ClientID %>').value      = document.getElementById('aw_edit_email').value.trim();
    document.getElementById('<%= HfAwEditPhone.ClientID %>').value      = document.getElementById('aw_edit_phone').value.trim();
    document.getElementById('<%= HfAwEditCardId.ClientID %>').value     = document.getElementById('aw_edit_cardid').value.trim();
    document.getElementById('<%= HfAwEditRfidTag.ClientID %>').value    = document.getElementById('aw_edit_rfidtag').value.trim();
    document.getElementById('<%= HfAwEditUserType.ClientID %>').value   = document.getElementById('aw_edit_usertype').value;
    document.getElementById('<%= HfAwEditCompanyId.ClientID %>').value  = co;
    document.getElementById('<%= BtnEditAwUser.ClientID %>').click();
}
function showAwErr(elId, msg) {
    var el = document.getElementById(elId); el.innerText = msg; el.style.display = 'block';
}

// Check for URL hash to auto-switch
if (window.location.hash === '#aw') switchSystem('aw');
if (window.location.hash === '#companies') { switchSystem('companies'); }

// Delegated click handler for user edit and clone buttons (eliminates inline quote issues)
document.addEventListener('click', function(e) {
    var editBtn = e.target.closest('.btn-edit-user');
    if (editBtn) {
        var u  = editBtn.getAttribute('data-username') || '';
        var dn = editBtn.getAttribute('data-displayname') || '';
        var r  = editBtn.getAttribute('data-role') || '';
        var en = editBtn.getAttribute('data-enabled') === 'true';
        var n  = editBtn.getAttribute('data-notes') || '';
        var sa = editBtn.getAttribute('data-siteaccess') || '{}';
        var ta = editBtn.getAttribute('data-tileaccess') || '[]';
        openEditModal(u, dn, r, en, n, sa, ta);
        return;
    }

    var cloneBtn = e.target.closest('.btn-clone-user');
    if (cloneBtn) {
        var r  = cloneBtn.getAttribute('data-role') || '';
        var dn = cloneBtn.getAttribute('data-displayname') || '';
        var sa = cloneBtn.getAttribute('data-siteaccess') || '{}';
        var ta = cloneBtn.getAttribute('data-tileaccess') || '[]';
        cloneIdashUser(r, dn, sa, ta);
        return;
    }

    var editAwBtn = e.target.closest('.btn-edit-aw-user');
    if (editAwBtn) {
        var id = editAwBtn.getAttribute('data-id') || '';
        var u  = editAwBtn.getAttribute('data-username') || '';
        var fn = editAwBtn.getAttribute('data-firstname') || '';
        var ln = editAwBtn.getAttribute('data-lastname') || '';
        var em = editAwBtn.getAttribute('data-email') || '';
        var ph = editAwBtn.getAttribute('data-phone') || '';
        var ci = editAwBtn.getAttribute('data-cardid') || '';
        var rt = editAwBtn.getAttribute('data-rfidtag') || '';
        var ut = editAwBtn.getAttribute('data-usertype') || '';
        var co = editAwBtn.getAttribute('data-companyid') || '';
        openAwEditModal(id, u, fn, ln, em, ph, ci, rt, ut, co);
        return;
    }

    var cloneAwBtn = e.target.closest('.btn-clone-aw-user');
    if (cloneAwBtn) {
        var ut = cloneAwBtn.getAttribute('data-usertype') || '';
        var co = cloneAwBtn.getAttribute('data-companyid') || '';
        var em = cloneAwBtn.getAttribute('data-email') || '';
        var ph = cloneAwBtn.getAttribute('data-phone') || '';
        var ci = cloneAwBtn.getAttribute('data-cardid') || '';
        cloneAwUser(ut, co, em, ph, ci);
        return;
    }
});

// Route Enter key in modal inputs to appropriate modal submit function
document.addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && e.target && e.target.tagName === 'INPUT' && e.target.type !== 'submit') {
        var inAdd = e.target.closest('#modalAdd');
        var inEdit = e.target.closest('#modalEdit');
        var inAwAdd = e.target.closest('#modalAwAdd');
        var inAwEdit = e.target.closest('#modalAwEdit');
        var inCoAdd = e.target.closest('#modalCoAdd');
        var inCoEdit = e.target.closest('#modalCoEdit');
        if (inAdd || inEdit || inAwAdd || inAwEdit || inCoAdd || inCoEdit) {
            e.preventDefault();
            if (inAdd) submitAdd();
            else if (inEdit) submitEdit();
            else if (inAwAdd) submitAwAdd();
            else if (inAwEdit) submitAwEdit();
            else if (inCoAdd) submitCoAdd();
            else if (inCoEdit) submitCoEdit();
            return false;
        }
    }
});

// ===== TEMPLATE SYSTEM =====
(function() {
    function populateTemplateDropdowns() {
        var templates = window.userTemplates || [];
        ['add_template', 'aw_add_template'].forEach(function(ddlId) {
            var sel = document.getElementById(ddlId);
            if (!sel) return;
            // Keep the first "-- No Template --" option
            while (sel.options.length > 1) sel.remove(1);
            templates.forEach(function(t, idx) {
                var opt = document.createElement('option');
                opt.value = idx.toString();
                opt.textContent = t.name;
                sel.appendChild(opt);
            });
        });
    }
    populateTemplateDropdowns();
})();

function applyTemplate(prefix) {
    var templates = window.userTemplates || [];
    var selId = (prefix === 'aw_add') ? 'aw_add_template' : 'add_template';
    var descId = (prefix === 'aw_add') ? 'aw_add_template_desc' : 'add_template_desc';
    var sel = document.getElementById(selId);
    var desc = document.getElementById(descId);
    if (!sel) return;
    var idx = parseInt(sel.value);
    if (isNaN(idx) || !templates[idx]) {
        if (desc) desc.textContent = '';
        return;
    }
    var t = templates[idx];
    if (desc) desc.textContent = t.description || '';

    if (prefix === 'add') {
        // iDash modal: apply idash settings
        var roleEl = document.getElementById('add_role');
        if (roleEl && t.idash && t.idash.role) { roleEl.value = t.idash.role; onRoleChange('add'); }

        // Apply site access
        if (t.idash && t.idash.siteAccess) {
            var sa = t.idash.siteAccess;
            if (sa['*']) {
                selectAllSites('add', sa['*']);
            } else {
                buildSiteGrid('add', sa);
            }
        }

        // Apply tile access
        if (t.idash && t.idash.tileAccess) {
            if (t.idash.tileAccess.indexOf('*') >= 0) {
                selectAllTiles('add', true);
            } else {
                buildTileGrid('add', t.idash.tileAccess);
            }
        }

        // Cross-platform: auto-check AW checkbox if template says so
        var awCb = document.getElementById('add_also_aw');
        if (awCb && t.idash) {
            awCb.checked = !!t.idash.autoCreate;
            toggleAwCrossCreate();
            if (t.idash.userType) {
                var ut = document.getElementById('add_aw_usertype');
                if (ut) ut.value = t.idash.userType;
            }
        }
    } else if (prefix === 'aw_add') {
        // AW modal: apply AW settings
        if (t.idash && t.idash.userType) {
            var ut = document.getElementById('aw_add_usertype');
            if (ut) ut.value = t.idash.userType;
        }
        // Auto-select first company if template says useFirstCompany
        if (t.idash && t.idash.useFirstCompany) {
            var coSel = document.getElementById('aw_add_companyid');
            if (coSel && coSel.options.length > 1) coSel.selectedIndex = 1;
        }

        // Cross-platform: auto-check iDash checkbox
        var idashCb = document.getElementById('aw_add_also_idash');
        if (idashCb && t.idash) {
            idashCb.checked = !!t.idash.autoCreate;
            toggleIdashCrossCreate();
            if (t.idash.role) {
                var roleEl = document.getElementById('aw_add_idash_role');
                if (roleEl) roleEl.value = t.idash.role;
            }
        }
    }
}

// ===== CROSS-PLATFORM TOGGLES =====
function toggleAwCrossCreate() {
    var cb = document.getElementById('add_also_aw');
    var sec = document.getElementById('add_aw_cross_section');
    if (sec) sec.style.display = (cb && cb.checked) ? 'block' : 'none';
    // Populate company dropdown
    if (cb && cb.checked) {
        var sel = document.getElementById('add_aw_companyid');
        if (sel && window.idashSites) {
            var cur = sel.value;
            sel.innerHTML = '<option value="">-- Auto (first site) --</option>';
            window.idashSites.forEach(function(c) {
                var opt = document.createElement('option');
                opt.value = c.id; opt.textContent = c.name;
                sel.appendChild(opt);
            });
            if (cur) sel.value = cur;
        }
    }
}

function toggleIdashCrossCreate() {
    var cb = document.getElementById('aw_add_also_idash');
    var sec = document.getElementById('aw_add_idash_cross_section');
    if (sec) sec.style.display = (cb && cb.checked) ? 'block' : 'none';
}

// ===== CLONE FUNCTIONS =====
function cloneIdashUser(role, displayName, siteAccessJson, tileAccessJson) {
    // Open the Add modal pre-filled with cloned user's settings
    showAddModal();
    var roleEl = document.getElementById('add_role');
    if (roleEl) { roleEl.value = role; onRoleChange('add'); }

    var existing = {};
    try { existing = JSON.parse(siteAccessJson) || {}; } catch(e) {}
    buildSiteGrid('add', existing);

    var existTiles = [];
    try { existTiles = JSON.parse(tileAccessJson) || []; } catch(e) {}
    buildTileGrid('add', existTiles);
}

function cloneAwUser(usertype, companyid, email, phone) {
    // Open the AW Add modal pre-filled
    showAwAddModal();
    setTimeout(function() {
        var ut = document.getElementById('aw_add_usertype'); if(ut) ut.value = usertype || 'Create, Edit, Delete';
        var co = document.getElementById('aw_add_companyid'); if(co && companyid) co.value = companyid;
        var em = document.getElementById('aw_add_email'); if(em) em.value = email || '';
        var ph = document.getElementById('aw_add_phone'); if(ph) ph.value = phone || '';
    }, 50);
}
</script>

<!-- ======== AW ADD USER MODAL ======== -->
<div id="modalAwAdd" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in" style="max-width:680px;">
        <div class="modal-title">+ Add RFID Scanner User</div>
        <!-- Template Selector -->
        <div class="form-row" style="margin-bottom:12px;">
            <div class="form-col">
                <label>&#128203; Quick Template</label>
                <select id="aw_add_template" onchange="applyTemplate('aw_add')" style="border-color:#f59e0b; font-weight:600;">
                    <option value="">-- No Template (Manual) --</option>
                </select>
                <span id="aw_add_template_desc" style="font-size:11px; color:var(--muted); margin-top:2px;"></span>
            </div>
        </div>
        <div id="aw_add_err" class="alert alert-err" style="display:none; margin-bottom:12px;"></div>
        <div class="form-row">
            <div class="form-col">
                <label>Username *</label>
                <input type="text" id="aw_add_username" autocomplete="off" placeholder="e.g. jsmith" />
            </div>
            <div class="form-col">
                <label>Password</label>
                <input type="password" id="aw_add_password" autocomplete="new-password" placeholder="Leave blank to auto-generate" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>First Name</label>
                <input type="text" id="aw_add_firstname" placeholder="First" />
            </div>
            <div class="form-col">
                <label>Last Name</label>
                <input type="text" id="aw_add_lastname" placeholder="Last" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>Email</label>
                <input type="email" id="aw_add_email" placeholder="user@va.gov" />
            </div>
            <div class="form-col">
                <label>Phone</label>
                <input type="text" id="aw_add_phone" placeholder="555-0100" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col narrow">
                <label>User Type *</label>
                <select id="aw_add_usertype">
                    <option value="Create, Edit, Delete" selected>Standard (Create, Edit, Delete)</option>
                    <option value="Create, Edit">Create, Edit</option>
                    <option value="View Only">View Only</option>
                </select>
            </div>
            <div class="form-col">
                <label>Company / Site *</label>
                <select id="aw_add_companyid">
                    <option value="">-- Select site --</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>Card ID</label>
                <input type="text" id="aw_add_cardid" placeholder="e.g. 12345678" />
            </div>
            <div class="form-col">
                <label>RFID Tag</label>
                <input type="text" id="aw_add_rfidtag" placeholder="Optional" />
            </div>
        </div>

        <!-- Cross-platform: Also create iDash portal account -->
        <hr class="sep" />
        <div style="display:flex; align-items:center; gap:10px; margin-bottom:10px;">
            <input type="checkbox" id="aw_add_also_idash" onchange="toggleIdashCrossCreate()" style="width:18px; height:18px; accent-color:#a855f7; cursor:pointer;" />
            <label for="aw_add_also_idash" style="font-size:14px; font-weight:700; color:#a855f7; cursor:pointer; margin:0;">Also create iDash Portal account</label>
        </div>
        <div id="aw_add_idash_cross_section" style="display:none; padding:14px; background:rgba(168,85,247,.06); border:1px solid rgba(168,85,247,.25); border-radius:10px;">
            <div style="font-size:12px; color:var(--muted); margin-bottom:10px;">Same username &amp; password will be used for the iDash portal account.</div>
            <div class="form-row">
                <div class="form-col narrow">
                    <label>Portal Role</label>
                    <select id="aw_add_idash_role">
                        <option value="user" selected>Standard User</option>
                        <option value="admin">Administrator</option>
                        <option value="readonly">Read-Only</option>
                    </select>
                </div>
                <div class="form-col">
                    <label style="font-size:11px; color:var(--muted);">Site &amp; tile access will use All Sites &mdash; Full Access defaults. Edit in iDash Users tab after creation.</label>
                </div>
            </div>
        </div>

        <hr class="sep" />
        <div class="modal-actions">
            <button type="button" class="btn btn-ghost" onclick="document.getElementById('modalAwAdd').style.display='none'">Cancel</button>
            <button type="button" class="btn btn-green" onclick="submitAwAdd()">&#10003; Create User</button>
        </div>
    </div>
</div>

<!-- ======== AW EDIT USER MODAL ======== -->
<div id="modalAwEdit" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in" style="max-width:680px;">
        <div class="modal-title">&#9998; Edit RFID Scanner User</div>
        <div id="aw_edit_err" class="alert alert-err" style="display:none; margin-bottom:12px;"></div>
        <input type="hidden" id="aw_edit_id" />
        <div class="form-row">
            <div class="form-col">
                <label>Username</label>
                <input type="text" id="aw_edit_username" readonly style="opacity:.6;" />
            </div>
            <div class="form-col">
                <label>New Password <span style="color:var(--muted);font-size:11px;">(leave blank = no change)</span></label>
                <input type="password" id="aw_edit_password" autocomplete="new-password" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>First Name</label>
                <input type="text" id="aw_edit_firstname" />
            </div>
            <div class="form-col">
                <label>Last Name</label>
                <input type="text" id="aw_edit_lastname" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>Email</label>
                <input type="email" id="aw_edit_email" />
            </div>
            <div class="form-col">
                <label>Phone</label>
                <input type="text" id="aw_edit_phone" />
            </div>
        </div>
        <div class="form-row">
            <div class="form-col narrow">
                <label>User Type *</label>
                <select id="aw_edit_usertype">
                    <option value="1">1 - SuperAdmin</option>
                    <option value="2">2 - Admin</option>
                    <option value="5">5 - Standard</option>
                    <option value="9">9 - Read-Only</option>
                </select>
            </div>
            <div class="form-col">
                <label>Company / Site *</label>
                <select id="aw_edit_companyid">
                    <option value="">-- Select site --</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-col">
                <label>Card ID</label>
                <input type="text" id="aw_edit_cardid" />
            </div>
            <div class="form-col">
                <label>RFID Tag</label>
                <input type="text" id="aw_edit_rfidtag" />
            </div>
        </div>
        <hr class="sep" />
        <div class="modal-actions">
            <button type="button" class="btn btn-ghost" onclick="document.getElementById('modalAwEdit').style.display='none'">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="submitAwEdit()">&#10003; Save Changes</button>
        </div>
    </div>
</div>

<!-- ======== COMPANY ADD MODAL ======== -->
<div id="modalCoAdd" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in" style="max-width:480px;">
        <div class="modal-title">+ Add Company / Site</div>
        <div id="co_add_err" class="alert alert-err" style="display:none; margin-bottom:12px;"></div>
        <label>Company Name *</label>
        <input type="text" id="co_add_name" autocomplete="off" placeholder="e.g. 512 - DENTAL" style="width:100%; margin-top:6px;" />
        <hr class="sep" />
        <div class="modal-actions">
            <button type="button" class="btn btn-ghost" onclick="document.getElementById('modalCoAdd').style.display='none'">Cancel</button>
            <button type="button" class="btn btn-green" onclick="submitCoAdd()">&#10003; Create Company</button>
        </div>
    </div>
</div>

<!-- ======== COMPANY EDIT MODAL ======== -->
<div id="modalCoEdit" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in" style="max-width:480px;">
        <div class="modal-title">&#9998; Rename Company / Site</div>
        <div id="co_edit_err" class="alert alert-err" style="display:none; margin-bottom:12px;"></div>
        <label>Company Name *</label>
        <input type="text" id="co_edit_name" autocomplete="off" style="width:100%; margin-top:6px;" />
        <hr class="sep" />
        <div class="modal-actions">
            <button type="button" class="btn btn-ghost" onclick="document.getElementById('modalCoEdit').style.display='none'">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="submitCoEdit()">&#10003; Save Name</button>
        </div>
    </div>
</div>

<script>
// Populate company dropdowns in AW modals from idashSites
(function() {
    function populateCompanyDdl(id) {
        var sel = document.getElementById(id);
        if (!sel || !window.idashSites) return;
        var cur = sel.value;
        sel.innerHTML = '<option value="">-- Select site --</option>';
        window.idashSites.forEach(function(c) {
            var opt = document.createElement('option');
            opt.value = c.id; opt.textContent = c.name;
            sel.appendChild(opt);
        });
        if (cur) sel.value = cur;
    }
    // Populate on modal open (called from showAwAddModal / openAwEditModal)
    var _origAdd = window.showAwAddModal;
    window.showAwAddModal = function() { populateCompanyDdl('aw_add_companyid'); if(_origAdd) _origAdd(); else { document.getElementById('modalAwAdd').style.display='flex'; } };
    var _origEdit = window.openAwEditModal;
    window.openAwEditModal = function(id,u,fn,ln,em,ph,ci,rt,ut,co) {
        populateCompanyDdl('aw_edit_companyid');
        if(_origEdit) _origEdit(id,u,fn,ln,em,ph,ci,rt,ut,co);
    };
})();
</script>

<idash:Footer runat="server" />
</body>
</html>


