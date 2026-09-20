<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_aw_user_management.aspx.cs" Inherits="va_aw_user_management" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="aw" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash &mdash; User Management</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <asp:Literal ID="LitCompanies" runat="server" />
    <style>
        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        * { box-sizing: border-box; }
        body { margin:0; background:var(--bg); color:var(--text); font-family:Segoe UI,sans-serif; }

        .status-bar { display:flex; justify-content:space-between; background:var(--chip); padding:8px 20px; font-size:13px; border-bottom:1px solid var(--line); }
        .wrap { max-width:1400px; margin:30px auto; padding:0 24px; }
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
        .badge-ced   { background:color-mix(in srgb, var(--accent-2), transparent 85%); color:#10b981; border:1px solid rgba(16,185,129,.3); }
        .badge-vo    { background:rgba(138,160,197,.15); color:var(--muted); border:1px solid rgba(138,160,197,.3); }
        .badge-on    { background:color-mix(in srgb, var(--accent-2), transparent 85%); color:#10b981; border:1px solid rgba(16,185,129,.3); }
        .badge-off   { background:color-mix(in srgb, var(--danger), transparent 85%); color:#ef4444; border:1px solid rgba(239,68,68,.3); }

        .btn { display:inline-flex; align-items:center; gap:6px; padding:8px 16px; border-radius:8px; border:none; font-weight:600; font-size:13px; cursor:pointer; transition:.15s; }
        .btn-primary { background:var(--accent);   color:#fff; }
        .btn-green   { background:var(--accent-2); color:#000; }
        .btn-danger  { background:var(--danger);   color:#fff; }
        .btn-ghost   { background:transparent; border:1px solid var(--line); color:var(--text); }
        .btn-sm      { padding:5px 10px; font-size:12px; border-radius:6px; }
        .btn:hover   { opacity:.85; transform:translateY(-1px); }

        .form-row   { display:flex; flex-wrap:wrap; gap:16px; margin-bottom:16px; }
        .form-col   { display:flex; flex-direction:column; gap:6px; min-width:160px; flex:1; }
        .form-col.narrow { max-width:220px; }
        .form-col label { font-size:12px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.4px; }
        .form-col input, .form-col select, .form-col textarea {
            background:var(--bg); border:1px solid var(--line); color:var(--text);
            padding:9px 12px; border-radius:8px; font-size:14px; outline:none; font-family:inherit;
        }
        .form-col input:focus, .form-col select:focus { border-color:var(--accent); }

        .alert { padding:12px 16px; border-radius:8px; margin-bottom:16px; border-left:4px solid; font-size:13px; }
        .alert-ok   { background:color-mix(in srgb, var(--accent-2), transparent 85%); border-color:var(--accent-2); color:var(--accent-2); }
        .alert-err  { background:color-mix(in srgb, var(--danger), transparent 85%);  border-color:var(--danger);   color:var(--danger); }
        .alert-info { background:color-mix(in srgb, var(--accent), transparent 85%);  border-color:var(--accent);   color:var(--accent); }

        .modal-overlay { position:fixed; inset:0; background:rgba(0,0,0,.75); z-index:9000; display:flex; align-items:center; justify-content:center; }
        .modal-box { background:var(--card); border:1px solid var(--line); border-radius:14px; padding:28px; width:780px; max-width:96vw; max-height:93vh; overflow-y:auto; box-shadow:0 24px 60px rgba(0,0,0,.5); }
        .modal-title { font-size:18px; font-weight:700; color:var(--accent); margin:0 0 20px; }

        /* toggle switch */
        .toggle-row { display:flex; align-items:center; gap:10px; padding:8px 0; }
        .toggle-row label.toggle-label { font-size:13px; color:var(--text); text-transform:none; font-weight:500; letter-spacing:normal; cursor:pointer; }
        .toggle-switch { position:relative; width:44px; height:24px; flex-shrink:0; }
        .toggle-switch input { opacity:0; width:0; height:0; }
        .toggle-switch .slider { position:absolute; inset:0; background:var(--line); border-radius:12px; cursor:pointer; transition:.2s; }
        .toggle-switch .slider::before { content:''; position:absolute; width:18px; height:18px; left:3px; bottom:3px; background:#fff; border-radius:50%; transition:.2s; }
        .toggle-switch input:checked + .slider { background:var(--accent-2); }
        .toggle-switch input:checked + .slider::before { transform:translateX(20px); }

        /* connection status */
        .conn-status { display:flex; align-items:center; gap:8px; font-size:13px; padding:6px 14px; border-radius:8px; }
        .conn-ok  { background:color-mix(in srgb, var(--accent-2), transparent 88%); color:#10b981; border:1px solid rgba(16,185,129,.25); }
        .conn-off { background:color-mix(in srgb, var(--danger), transparent 88%); color:#ef4444; border:1px solid rgba(239,68,68,.25); }

        hr.sep { border:none; border-top:1px solid var(--line); margin:18px 0; }
        .muted { color:var(--muted); font-size:12px; }

        @keyframes fade-in { from{opacity:0;transform:translateY(-6px)} to{opacity:1;transform:none} }
        .animate-in { animation:fade-in .22s ease; }
        /* Embed mode: hide chrome when loaded in iframe */
        body.embed-mode .status-bar { display:none !important; }
        body.embed-mode .page-title-bar { display:none !important; }
        body.embed-mode .wrap { margin-top:10px !important; }
    </style>
</head>
<body>
<script>
if (window.location.search.indexOf('embed=1') !== -1) document.body.classList.add('embed-mode');
</script>
<form id="form1" runat="server">

    <div class="status-bar">
        <span>iDash &mdash; Scanner User Management (sysuser)</span>
        <span>
            <asp:Panel ID="PnlConnIndicator" runat="server" style="display:inline;">
                <span class="conn-ok" id="connOk" runat="server" visible="false">&#9679; CONNECTED</span>
                <span class="conn-off" id="connOff" runat="server">&#9675; NOT CONNECTED</span>
            </asp:Panel>
        </span>
    </div>

    <!-- -- ACCESS DENIED ----------------------------------------- -->
    <asp:Panel ID="PnlAccessDenied" runat="server" Visible="false">
        <div class="wrap" style="margin-top:80px; text-align:center;">
            <div style="font-size:48px; margin-bottom:16px;">&#128274;</div>
            <div style="font-size:22px; font-weight:700; margin-bottom:8px;">Access Restricted</div>
            <p style="color:var(--muted);">Only iDash administrators can manage scanner users.</p>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </asp:Panel>

    <!-- -- MAIN PANEL -------------------------------------------- -->
    <asp:Panel ID="PnlMain" runat="server" Visible="false">
    <div class="wrap">

        <div class="page-title-bar" style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-bottom:6px;">
            <div>
                <div class="page-title">&#128100; Scanner User Management</div>
                <div class="page-sub">Create and manage scanner login accounts directly from iDash. Changes are written to the <strong>dbo.sysuser</strong> table.</div>
            </div>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>

        <div style="background:color-mix(in srgb, var(--accent), transparent 90%); border:1px solid var(--accent); border-radius:8px; padding:12px 16px; margin-bottom:14px; font-size:12px; line-height:1.6;">
            <strong style="color:var(--accent);">&#128241; What are these accounts used for?</strong><br/>
            The user accounts managed here (<code>dbo.sysuser</code>) are used to sign in to:<br/>
            &bull; <strong>iDash Web UI</strong> &mdash; the main application at <code>http://localhost</code><br/>
            &bull; <strong>RFID Handheld Scanners</strong> &mdash; the iDash mobile application on Zebra/TSL readers<br/>
            &bull; <strong>iDash Mobile Tools</strong> &mdash; scanner-based iDash tools (Tag Team Scan, Inventory, EIL Live Scan)<br/>
            <span style="color:var(--muted);">Each scanner operator and web user needs their own account with the correct user type, site assignment, and permissions.</span>
        </div>

        <asp:Literal ID="LitMsg" runat="server" />

        <!-- -- CONNECTION CARD ----------------------------------- -->
        <asp:Panel ID="PnlNotConnected" runat="server">
        <div class="card">
            <div class="card-title">&#128268; Database Connection</div>
            <div class="alert alert-info" style="font-size:12px; margin-bottom:10px;">
                Enter SQL Server credentials with <strong>read/write</strong> access to the iDash database. Fields are pre-populated from your web.config connection string.
            </div>
            <div style="background:color-mix(in srgb, #ef4444, transparent 88%); border:1px solid #ef4444; border-radius:8px; padding:10px 14px; margin-bottom:16px; font-size:12px; color:var(--text);">
                <strong style="color:#ef4444;">&#9888; Do NOT use <code style="color:#ef4444;">admin</code> or <code style="color:#ef4444;">superadmin</code> here.</strong>
                Those are iDash application accounts for the web UI and RFID scanners &mdash; they are <strong>not</strong> SQL Server credentials.
                Sign in with <strong><code>idashadmin</code></strong> (the SQL Server database management account).
            </div>
            <div class="form-row">
                <div class="form-col">
                    <label>SQL Server *</label>
                    <asp:TextBox ID="TxtServer" runat="server" placeholder="e.g. .\sqlexpress" autocomplete="off" />
                </div>
                <div class="form-col">
                    <label>Database *</label>
                    <asp:TextBox ID="TxtDatabase" runat="server" placeholder="e.g. iDash" autocomplete="off" />
                </div>
            </div>
            <div class="form-row">
                <div class="form-col">
                    <label>SQL Username *</label>
                    <asp:TextBox ID="TxtSqlUser" runat="server" placeholder="e.g. idashadmin" autocomplete="off" />
                </div>
                <div class="form-col">
                    <label>SQL Password *</label>
                    <asp:TextBox ID="TxtSqlPassword" runat="server" TextMode="Password" placeholder="Enter password" autocomplete="new-password" />
                </div>
                <div class="form-col narrow" style="justify-content:flex-end;">
                    <asp:Button ID="BtnConnect" runat="server" Text="&#128268; Connect" OnClick="BtnConnect_Click" CssClass="btn btn-primary" />
                </div>
            </div>
        </div>
        </asp:Panel>

        <!-- -- CONNECTED STATE ----------------------------------- -->
        <asp:Panel ID="PnlConnected" runat="server" Visible="false">

        <!-- Connection info bar -->
        <div class="card" style="padding:14px 20px; display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:10px;">
            <div style="display:flex; align-items:center; gap:12px;">
                <span class="conn-ok">&#9679; CONNECTED</span>
                <span class="muted">Using stored session connection</span>
            </div>
            <div style="display:flex; gap:8px;">
                <button type="button" class="btn btn-green btn-sm" onclick="showAwAddModal()">&#43; Add Scanner User</button>
                <asp:Button ID="BtnDisconnect" runat="server" Text="&#9747; Disconnect" OnClick="BtnDisconnect_Click" CssClass="btn btn-ghost btn-sm" />
            </div>
        </div>

        <!-- -- USER TABLE ---------------------------------------- -->
        <div class="card">
            <div class="card-title" style="justify-content:space-between;">
                <span>&#128101; Scanner Users (sysuser table)</span>
                <span class="muted" style="font-weight:400; font-size:12px;">Click Edit to modify &bull; changes are saved directly to the database</span>
            </div>

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

                        <asp:TemplateField HeaderText="Email / Phone">
                            <ItemTemplate>
                                <span style="font-size:12px;"><%# Eval("Email") %></span><br/>
                                <span class="muted"><%# Eval("Phone") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="UserType">
                            <ItemTemplate>
                                <span class='badge <%# Eval("UserType").ToString().Contains("Create") ? "badge-ced" : "badge-vo" %>'>
                                    <%# Eval("UserType") %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Company (Site)">
                            <ItemTemplate>
                                <%# Eval("CompanyName") %>
                                <span class="muted"><%# Eval("CompanyId") != null ? "(ID: " + Eval("CompanyId") + ")" : "" %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Card ID">
                            <ItemTemplate>
                                <span class="muted"><%# Eval("CardId") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="RFID Tag">
                            <ItemTemplate>
                                <span class="muted"><%# Eval("RfidTag") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Options">
                            <ItemTemplate>
                                <%# (bool)Eval("HideAdminPopups") ? "<span class='badge badge-on' title='Hide Admin Popups'>HidePopups</span>" : "" %>
                                <%# (bool)Eval("InventoryLimitedUser") ? "<span class='badge badge-on' title='Inventory Limited'>InvLimited</span>" : "" %>
                                <%# (bool)Eval("RestrictEditMobile") ? "<span class='badge badge-on' title='Restrict Edit Mobile'>RestrictMobile</span>" : "" %>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Actions">
                            <ItemTemplate>
                                <asp:Button runat="server" Text="Edit"
                                    CommandName="EditAwUser"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CssClass="btn btn-ghost btn-sm"
                                    OnClientClick='<%# BuildAwEditOnClick(Container.DataItem) %>' />

                                <asp:Button runat="server" Text="Delete"
                                    CommandName="DeleteAwUser"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CssClass="btn btn-danger btn-sm"
                                    OnClientClick='<%# "return confirm(\"Delete user \\\"" + Eval("Username") + "\\\" from the system?\\n\\nThis cannot be undone.\");" %>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                    <EmptyDataTemplate>
                        <div style="padding:24px; text-align:center; color:var(--muted);">No users found in dbo.sysuser.</div>
                    </EmptyDataTemplate>
                </asp:GridView>
            </div>
        </div>

        </asp:Panel>

        <!-- -- COMPANY MANAGEMENT SECTION ---------------------- -->
        <asp:Panel ID="PnlCompanyMgmt" runat="server" Visible="false">
        <div class="card" style="margin-top:20px;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
                <div class="card-title" style="margin:0;">&#127970; Company (Site) Management</div>
                <button type="button" class="btn btn-green btn-sm" onclick="showCompanyAddModal()">+ Add Company</button>
            </div>
            <p style="color:var(--muted); font-size:13px; margin:0 0 14px;">Manage sites. Users from a deleted company are reassigned to the next available site.</p>
            <div class="grid-wrap">
                <table class="ug">
                    <thead><tr><th>ID</th><th>Company Name</th><th style="width:160px;">Actions</th></tr></thead>
                    <tbody id="companyGridBody"><!-- populated by JS --></tbody>
                </table>
            </div>
        </div>
        </asp:Panel>

        <!-- -- ADD COMPANY MODAL ------------------------------- -->
        <div id="modalCompanyAdd" class="modal-overlay" style="display:none;" onclick="if(event.target===this)this.style.display='none'">
            <div class="modal-box" style="max-width:420px;">
                <div class="modal-title">+ Add Company</div>
                <div id="co_add_err" class="alert alert-err" style="display:none;"></div>
                <div class="form-row">
                    <div class="form-col">
                        <label>Company Name *</label>
                        <input type="text" id="co_add_name" placeholder="e.g. 613 Martinsburg" maxlength="100" />
                    </div>
                </div>
                <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:14px;">
                    <button type="button" class="btn btn-ghost" onclick="document.getElementById('modalCompanyAdd').style.display='none'">Cancel</button>
                    <button type="button" class="btn btn-primary" onclick="submitCompanyAdd()">Save Company</button>
                </div>
            </div>
        </div>

        <!-- -- EDIT COMPANY MODAL ------------------------------ -->
        <div id="modalCompanyEdit" class="modal-overlay" style="display:none;" onclick="if(event.target===this)this.style.display='none'">
            <div class="modal-box" style="max-width:420px;">
                <div class="modal-title">&#9998; Edit Company</div>
                <div id="co_edit_err" class="alert alert-err" style="display:none;"></div>
                <div class="form-row">
                    <div class="form-col">
                        <label>Company Name *</label>
                        <input type="text" id="co_edit_name" placeholder="Company name" maxlength="100" />
                    </div>
                </div>
                <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:14px;">
                    <button type="button" class="btn btn-ghost" onclick="document.getElementById('modalCompanyEdit').style.display='none'">Cancel</button>
                    <button type="button" class="btn btn-primary" onclick="submitCompanyEdit()">Save Changes</button>
                </div>
            </div>
        </div>

        <!-- -- HIDDEN POSTBACK FIELDS (ADD USER) ----------------- -->
        <asp:HiddenField ID="HfAwAddUsername"       runat="server" />
        <asp:HiddenField ID="HfAwAddPassword"       runat="server" />
        <asp:HiddenField ID="HfAwAddFirstName"      runat="server" />
        <asp:HiddenField ID="HfAwAddLastName"       runat="server" />
        <asp:HiddenField ID="HfAwAddEmail"          runat="server" />
        <asp:HiddenField ID="HfAwAddPhone"          runat="server" />
        <asp:HiddenField ID="HfAwAddCardId"         runat="server" />
        <asp:HiddenField ID="HfAwAddRfidTag"        runat="server" />
        <asp:HiddenField ID="HfAwAddUserType"       runat="server" />
        <asp:HiddenField ID="HfAwAddCompanyId"      runat="server" />
        <asp:HiddenField ID="HfAwAddHidePopups"     runat="server" />
        <asp:HiddenField ID="HfAwAddInvLimited"     runat="server" />
        <asp:HiddenField ID="HfAwAddRestrictMobile"  runat="server" />

        <!-- -- HIDDEN POSTBACK FIELDS (EDIT USER) ---------------- -->
        <asp:HiddenField ID="HfAwEditId"            runat="server" />
        <asp:HiddenField ID="HfAwEditPassword"      runat="server" />
        <asp:HiddenField ID="HfAwEditFirstName"     runat="server" />
        <asp:HiddenField ID="HfAwEditLastName"      runat="server" />
        <asp:HiddenField ID="HfAwEditEmail"         runat="server" />
        <asp:HiddenField ID="HfAwEditPhone"         runat="server" />
        <asp:HiddenField ID="HfAwEditCardId"        runat="server" />
        <asp:HiddenField ID="HfAwEditRfidTag"       runat="server" />
        <asp:HiddenField ID="HfAwEditUserType"      runat="server" />
        <asp:HiddenField ID="HfAwEditCompanyId"     runat="server" />
        <asp:HiddenField ID="HfAwEditHidePopups"    runat="server" />
        <asp:HiddenField ID="HfAwEditInvLimited"    runat="server" />
        <asp:HiddenField ID="HfAwEditRestrictMobile" runat="server" />

        <!-- -- HIDDEN POSTBACK FIELDS (COMPANY ADD/EDIT/DELETE) -- -->
        <asp:HiddenField ID="HfAddCompanyName"  runat="server" />
        <asp:HiddenField ID="HfEditCompanyId"   runat="server" />
        <asp:HiddenField ID="HfEditCompanyName" runat="server" />
        <asp:HiddenField ID="HfDeleteCompanyId" runat="server" />

        <asp:Button ID="BtnAddAwUser"    runat="server" style="display:none;" OnClick="BtnAddAwUser_Click"    UseSubmitBehavior="false" />
        <asp:Button ID="BtnEditAwUser"   runat="server" style="display:none;" OnClick="BtnEditAwUser_Click"   UseSubmitBehavior="false" />
        <asp:Button ID="BtnAddCompany"   runat="server" style="display:none;" OnClick="BtnAddCompany_Click"   UseSubmitBehavior="false" />
        <asp:Button ID="BtnEditCompany"  runat="server" style="display:none;" OnClick="BtnEditCompany_Click"  UseSubmitBehavior="false" />
        <asp:Button ID="BtnDeleteCompany" runat="server" style="display:none;" OnClick="BtnDeleteCompany_Click" UseSubmitBehavior="false" />

    </div>
    </asp:Panel>
</form>

<!-- ======== ADD USER MODAL ======== -->
<div id="modalAwAdd" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in">
        <div class="modal-title">&#43; Add Scanner User</div>

        <div class="form-row">
            <div class="form-col">
                <label>Username *</label>
                <input type="text" id="aw_add_username" autocomplete="off" placeholder="e.g. jsmith" />
            </div>
            <div class="form-col">
                <label>Password</label>
                <input type="password" id="aw_add_password" autocomplete="new-password" placeholder="Scanner login password" />
            </div>
            <div class="form-col">
                <label>Confirm Password</label>
                <input type="password" id="aw_add_password2" autocomplete="new-password" />
            </div>
        </div>

        <div class="form-row">
            <div class="form-col">
                <label>First Name</label>
                <input type="text" id="aw_add_firstname" placeholder="John" />
            </div>
            <div class="form-col">
                <label>Last Name</label>
                <input type="text" id="aw_add_lastname" placeholder="Smith" />
            </div>
        </div>

        <div class="form-row">
            <div class="form-col">
                <label>Email</label>
                <input type="email" id="aw_add_email" placeholder="john@example.com" />
            </div>
            <div class="form-col">
                <label>Phone</label>
                <input type="text" id="aw_add_phone" placeholder="555-0100" />
            </div>
        </div>

        <div class="form-row">
            <div class="form-col">
                <label>Card ID</label>
                <input type="text" id="aw_add_cardid" placeholder="Badge / card number" />
            </div>
            <div class="form-col">
                <label>RFID Tag</label>
                <input type="text" id="aw_add_rfidtag" placeholder="RFID tag hex" />
            </div>
        </div>

        <div class="form-row">
            <div class="form-col narrow">
                <label>User Type *</label>
                <select id="aw_add_usertype">
                    <option value="Create, Edit, Delete">Create, Edit, Delete</option>
                    <option value="View Only">View Only</option>
                </select>
            </div>
            <div class="form-col narrow">
                <label>Company (Site) *</label>
                <select id="aw_add_companyid">
                <option value="">-- Select Company (REQUIRED) --</option>
                    <!-- populated by JS -->
                </select>
            </div>
        </div>

        <hr class="sep" />

        <div style="font-size:12px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.4px; margin-bottom:12px;">Options &amp; Restrictions</div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <input type="checkbox" id="aw_add_hidepopups" />
                <span class="slider"></span>
            </label>
            <label class="toggle-label" for="aw_add_hidepopups">Hide Admin Popups</label>
        </div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <input type="checkbox" id="aw_add_invlimited" />
                <span class="slider"></span>
            </label>
            <label class="toggle-label" for="aw_add_invlimited">Inventory Limited User</label>
        </div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <input type="checkbox" id="aw_add_restrictmobile" />
                <span class="slider"></span>
            </label>
            <label class="toggle-label" for="aw_add_restrictmobile">Restrict Edit on Mobile</label>
        </div>

        <div id="aw_add_err" class="alert alert-err" style="display:none; margin-top:14px;"></div>

        <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:20px;">
            <button type="button" class="btn btn-ghost" onclick="closeAwAddModal()">Cancel</button>
            <button type="button" class="btn btn-green" onclick="submitAwAdd()">&#10003; Create User</button>
        </div>
    </div>
</div>

<!-- ======== EDIT USER MODAL ======== -->
<div id="modalAwEdit" class="modal-overlay" style="display:none;">
    <div class="modal-box animate-in">
        <div class="modal-title">&#9998; Edit Scanner User: <span id="aw_edit_title" style="color:var(--text);"></span></div>
        <input type="hidden" id="aw_edit_id" />

        <div class="form-row">
            <div class="form-col">
                <label>New Password (blank = unchanged)</label>
                <input type="password" id="aw_edit_password" autocomplete="new-password" placeholder="(unchanged)" />
            </div>
            <div class="form-col">
                <label>Confirm New Password</label>
                <input type="password" id="aw_edit_password2" autocomplete="new-password" placeholder="(unchanged)" />
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
            <div class="form-col">
                <label>Card ID</label>
                <input type="text" id="aw_edit_cardid" />
            </div>
            <div class="form-col">
                <label>RFID Tag</label>
                <input type="text" id="aw_edit_rfidtag" />
            </div>
        </div>

        <div class="form-row">
            <div class="form-col narrow">
                <label>User Type</label>
                <select id="aw_edit_usertype">
                    <option value="Create, Edit, Delete">Create, Edit, Delete</option>
                    <option value="View Only">View Only</option>
                </select>
            </div>
            <div class="form-col narrow">
                <label>Company (Site)</label>
                <select id="aw_edit_companyid">
                    <option value="">-- Select Company (REQUIRED) --</option>
                </select>
            </div>
        </div>

        <hr class="sep" />

        <div style="font-size:12px; font-weight:600; color:var(--muted); text-transform:uppercase; letter-spacing:.4px; margin-bottom:12px;">Options &amp; Restrictions</div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <input type="checkbox" id="aw_edit_hidepopups" />
                <span class="slider"></span>
            </label>
            <label class="toggle-label" for="aw_edit_hidepopups">Hide Admin Popups</label>
        </div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <input type="checkbox" id="aw_edit_invlimited" />
                <span class="slider"></span>
            </label>
            <label class="toggle-label" for="aw_edit_invlimited">Inventory Limited User</label>
        </div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <input type="checkbox" id="aw_edit_restrictmobile" />
                <span class="slider"></span>
            </label>
            <label class="toggle-label" for="aw_edit_restrictmobile">Restrict Edit on Mobile</label>
        </div>

        <div id="aw_edit_err" class="alert alert-err" style="display:none; margin-top:14px;"></div>

        <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:20px;">
            <button type="button" class="btn btn-ghost" onclick="closeAwEditModal()">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="submitAwEdit()">&#10003; Save Changes</button>
        </div>
    </div>
</div>


<script>
// -- Company dropdown population ----------------------------------
var awCompanies = window.awCompanies || [];

function populateCompanyDropdown(selId, selectedId) {
    var sel = document.getElementById(selId);
    // Keep the first option (None)
    while (sel.options.length > 1) sel.remove(1);
    awCompanies.forEach(function(c) {
        var opt = document.createElement('option');
        opt.value = c.Id.toString();
        opt.textContent = c.Name + ' (ID: ' + c.Id + ')';
        if (selectedId && selectedId.toString() === c.Id.toString()) opt.selected = true;
        sel.appendChild(opt);
    });
}

// -- ADD modal ----------------------------------------------------
function showAwAddModal() {
    populateCompanyDropdown('aw_add_companyid', '');
    document.getElementById('modalAwAdd').style.display = 'flex';
    document.getElementById('aw_add_username').focus();
}

function closeAwAddModal() {
    document.getElementById('modalAwAdd').style.display = 'none';
    clearAwAddForm();
}

function clearAwAddForm() {
    ['aw_add_username','aw_add_password','aw_add_password2','aw_add_firstname','aw_add_lastname',
     'aw_add_email','aw_add_phone','aw_add_cardid','aw_add_rfidtag'].forEach(function(id) {
        document.getElementById(id).value = '';
    });
    document.getElementById('aw_add_usertype').value = 'Create, Edit, Delete';
    document.getElementById('aw_add_companyid').value = '';
    document.getElementById('aw_add_hidepopups').checked = false;
    document.getElementById('aw_add_invlimited').checked = false;
    document.getElementById('aw_add_restrictmobile').checked = false;
    document.getElementById('aw_add_err').style.display = 'none';
}

function submitAwAdd() {
    var u  = document.getElementById('aw_add_username').value.trim();
    var p  = document.getElementById('aw_add_password').value;
    var p2 = document.getElementById('aw_add_password2').value;

    document.getElementById('aw_add_err').style.display = 'none';
    if (!u) { showAwErr('aw_add_err', 'Username is required.'); return; }
    if (u.indexOf(' ') !== -1) { showAwErr('aw_add_err', 'Username cannot contain spaces.'); return; }
    if (p && p.length < 4) { showAwErr('aw_add_err', 'Password must be at least 4 characters.'); return; }
    if (p !== p2) { showAwErr('aw_add_err', 'Passwords do not match.'); return; }

    var cid = document.getElementById('aw_add_companyid').value;
    if (!cid) {
        // Auto-select if only one company exists
        if (awCompanies && awCompanies.length === 1) {
            document.getElementById('aw_add_companyid').value = awCompanies[0].Id.toString();
            cid = awCompanies[0].Id.toString();
        } else if (awCompanies && awCompanies.length > 1) {
            showAwErr('aw_add_err', 'Please select a Company (Site). Users without a company cannot access RFID data.');
            return;
        }
    }

    document.getElementById('<%= HfAwAddUsername.ClientID %>').value = u;
    document.getElementById('<%= HfAwAddPassword.ClientID %>').value = p;
    document.getElementById('<%= HfAwAddFirstName.ClientID %>').value = document.getElementById('aw_add_firstname').value.trim();
    document.getElementById('<%= HfAwAddLastName.ClientID %>').value = document.getElementById('aw_add_lastname').value.trim();
    document.getElementById('<%= HfAwAddEmail.ClientID %>').value = document.getElementById('aw_add_email').value.trim();
    document.getElementById('<%= HfAwAddPhone.ClientID %>').value = document.getElementById('aw_add_phone').value.trim();
    document.getElementById('<%= HfAwAddCardId.ClientID %>').value = document.getElementById('aw_add_cardid').value.trim();
    document.getElementById('<%= HfAwAddRfidTag.ClientID %>').value = document.getElementById('aw_add_rfidtag').value.trim();
    document.getElementById('<%= HfAwAddUserType.ClientID %>').value = document.getElementById('aw_add_usertype').value;
    document.getElementById('<%= HfAwAddCompanyId.ClientID %>').value = document.getElementById('aw_add_companyid').value;
    document.getElementById('<%= HfAwAddHidePopups.ClientID %>').value = document.getElementById('aw_add_hidepopups').checked ? 'true' : 'false';
    document.getElementById('<%= HfAwAddInvLimited.ClientID %>').value = document.getElementById('aw_add_invlimited').checked ? 'true' : 'false';
    document.getElementById('<%= HfAwAddRestrictMobile.ClientID %>').value = document.getElementById('aw_add_restrictmobile').checked ? 'true' : 'false';
    document.getElementById('<%= BtnAddAwUser.ClientID %>').click();
}

// -- EDIT modal ---------------------------------------------------
function openAwEditModal(id, username, firstname, lastname, email, phone, cardid, rfidtag, usertype, companyid, hidePopups, invLimited, restrictMobile) {
    document.getElementById('aw_edit_id').value = id;
    document.getElementById('aw_edit_title').innerText = username;
    document.getElementById('aw_edit_firstname').value = firstname || '';
    document.getElementById('aw_edit_lastname').value  = lastname || '';
    document.getElementById('aw_edit_email').value     = email || '';
    document.getElementById('aw_edit_phone').value     = phone || '';
    document.getElementById('aw_edit_cardid').value    = cardid || '';
    document.getElementById('aw_edit_rfidtag').value   = rfidtag || '';
    document.getElementById('aw_edit_usertype').value  = usertype || 'Create, Edit, Delete';

    populateCompanyDropdown('aw_edit_companyid', companyid);

    document.getElementById('aw_edit_hidepopups').checked     = hidePopups;
    document.getElementById('aw_edit_invlimited').checked     = invLimited;
    document.getElementById('aw_edit_restrictmobile').checked = restrictMobile;

    document.getElementById('aw_edit_password').value  = '';
    document.getElementById('aw_edit_password2').value = '';
    document.getElementById('aw_edit_err').style.display = 'none';

    document.getElementById('modalAwEdit').style.display = 'flex';
}

function closeAwEditModal() {
    document.getElementById('modalAwEdit').style.display = 'none';
}

function submitAwEdit() {
    var p  = document.getElementById('aw_edit_password').value;
    var p2 = document.getElementById('aw_edit_password2').value;

    document.getElementById('aw_edit_err').style.display = 'none';
    if (p && p.length < 4) { showAwErr('aw_edit_err', 'Password must be at least 4 characters.'); return; }
    if (p !== p2) { showAwErr('aw_edit_err', 'Passwords do not match.'); return; }

    document.getElementById('<%= HfAwEditId.ClientID %>').value = document.getElementById('aw_edit_id').value;
    document.getElementById('<%= HfAwEditPassword.ClientID %>').value = p;
    document.getElementById('<%= HfAwEditFirstName.ClientID %>').value = document.getElementById('aw_edit_firstname').value.trim();
    document.getElementById('<%= HfAwEditLastName.ClientID %>').value = document.getElementById('aw_edit_lastname').value.trim();
    document.getElementById('<%= HfAwEditEmail.ClientID %>').value = document.getElementById('aw_edit_email').value.trim();
    document.getElementById('<%= HfAwEditPhone.ClientID %>').value = document.getElementById('aw_edit_phone').value.trim();
    document.getElementById('<%= HfAwEditCardId.ClientID %>').value = document.getElementById('aw_edit_cardid').value.trim();
    document.getElementById('<%= HfAwEditRfidTag.ClientID %>').value = document.getElementById('aw_edit_rfidtag').value.trim();
    document.getElementById('<%= HfAwEditUserType.ClientID %>').value = document.getElementById('aw_edit_usertype').value;
    document.getElementById('<%= HfAwEditCompanyId.ClientID %>').value = document.getElementById('aw_edit_companyid').value;
    document.getElementById('<%= HfAwEditHidePopups.ClientID %>').value = document.getElementById('aw_edit_hidepopups').checked ? 'true' : 'false';
    document.getElementById('<%= HfAwEditInvLimited.ClientID %>').value = document.getElementById('aw_edit_invlimited').checked ? 'true' : 'false';
    document.getElementById('<%= HfAwEditRestrictMobile.ClientID %>').value = document.getElementById('aw_edit_restrictmobile').checked ? 'true' : 'false';
    document.getElementById('<%= BtnEditAwUser.ClientID %>').click();
}

// -- Helpers ------------------------------------------------------
function showAwErr(elId, msg) {
    var el = document.getElementById(elId);
    el.innerText = msg;
    el.style.display = 'block';
}

// Close modals on overlay click
document.getElementById('modalAwAdd').addEventListener('click', function(e)  { if (e.target === this) closeAwAddModal(); });
document.getElementById('modalAwEdit').addEventListener('click', function(e) { if (e.target === this) closeAwEditModal(); });

// -- Company Management ------------------------------------------
function populateCompanyGrid() {
    var tbody = document.getElementById('companyGridBody');
    if (!tbody) return;
    tbody.innerHTML = '';
    if (!awCompanies || awCompanies.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3" style="color:var(--muted);padding:14px;">No companies found.</td></tr>';
        return;
    }
    awCompanies.forEach(function(c) {
        var safeName = c.Name.replace(/'/g, "\\'");
        tbody.innerHTML +=
            '<tr>' +
            '<td>' + c.Id + '</td>' +
            '<td>' + c.Name + '</td>' +
            '<td>' +
            '<button type="button" class="btn btn-ghost btn-sm" style="margin-right:6px;" onclick="openCompanyEditModal(' + c.Id + ',\'' + safeName + '\')">Edit</button>' +
            '<button type="button" class="btn btn-danger btn-sm" onclick="deleteCompany(' + c.Id + ',\'' + safeName + '\')">Delete</button>' +
            '</td></tr>';
    });
}

function showCompanyAddModal() {
    document.getElementById('co_add_name').value = '';
    document.getElementById('co_add_err').style.display = 'none';
    document.getElementById('modalCompanyAdd').style.display = 'flex';
    document.getElementById('co_add_name').focus();
}

function submitCompanyAdd() {
    var name = document.getElementById('co_add_name').value.trim();
    if (!name) { showCoErr('co_add_err', 'Company name is required.'); return; }
    document.getElementById('<%= HfAddCompanyName.ClientID %>').value = name;
    document.getElementById('<%= BtnAddCompany.ClientID %>').click();
}

function openCompanyEditModal(id, name) {
    document.getElementById('co_edit_name').value = name;
    document.getElementById('co_edit_err').style.display = 'none';
    document.getElementById('<%= HfEditCompanyId.ClientID %>').value = id.toString();
    document.getElementById('modalCompanyEdit').style.display = 'flex';
    document.getElementById('co_edit_name').focus();
}

function submitCompanyEdit() {
    var name = document.getElementById('co_edit_name').value.trim();
    if (!name) { showCoErr('co_edit_err', 'Company name is required.'); return; }
    document.getElementById('<%= HfEditCompanyName.ClientID %>').value = name;
    document.getElementById('<%= BtnEditCompany.ClientID %>').click();
}

function deleteCompany(id, name) {
    if (!confirm('DELETE company "' + name + '" (ID: ' + id + ')?\n\nUsers assigned to this company will be reassigned to the next available site.\nAssets and history for this company will be deleted.\n\nThis cannot be undone!')) return;
    document.getElementById('<%= HfDeleteCompanyId.ClientID %>').value = id.toString();
    document.getElementById('<%= BtnDeleteCompany.ClientID %>').click();
}

function showCoErr(elId, msg) {
    var el = document.getElementById(elId);
    el.innerText = msg;
    el.style.display = 'block';
}

// Populate company grid on load
window.addEventListener('DOMContentLoaded', function() { populateCompanyGrid(); });
</script>

<aw:Footer runat="server" />
</body>
</html>

