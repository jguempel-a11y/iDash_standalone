<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_print_mapping.aspx.cs" Inherits="va_print_mapping" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Tag Type Print Mapping</title>
            <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        body { background: var(--bg); color: var(--text); font-family: Segoe UI, Arial; padding: 20px; }
        .panel { background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 16px; margin-bottom: 18px; }
        .muted { color: var(--muted); font-size: 13px; }
        .bucket-row { display: flex; gap: 10px; flex-wrap: wrap; align-items: flex-end; }
        .filter { margin-top: 10px; }
        .filter label { display: block; font-size: 12px; opacity: 0.9; margin-bottom: 6px; }
        .filter input[type="text"], .filter input[type="number"], .filter select { background: var(--chip); border: 1px solid var(--line); color: var(--text); padding: 8px 10px; border-radius: 10px; outline: none; }
        .btn { border: 2px solid var(--accent); background: transparent; color: var(--accent); padding: 8px 14px; border-radius: 8px; cursor: pointer; font-weight: 600; text-decoration: none; display: inline-block; }
        .btn:hover { background: color-mix(in srgb, var(--accent) 10%, transparent); }
        .btn-sm { font-size: 11px; padding: 4px 8px; border-color: var(--danger); color: var(--danger); }
        .btn-sm:hover { background: color-mix(in srgb, var(--danger) 10%, transparent); }
        .err { color: var(--danger); margin: 8px 0; }
        .gridWrap { overflow: auto; border: 1px solid var(--line); border-radius: 12px; margin-top: 15px; }
        .grid { width: 100%; border-collapse: collapse; }
        .grid th { background: var(--chip); color: var(--accent); padding: 10px; text-align: left; border-bottom: 2px solid var(--line); }
        .grid td { border-bottom: 1px solid var(--line); padding: 10px; }
    </style>
    <script>
        function toggleTargetUI() {
            var typeSelect = document.getElementById('<%= DdlTargetType.ClientID %>');
            var val = typeSelect ? typeSelect.value : 'Default';
            document.getElementById('uiTargetService').style.display = (val === 'Service') ? 'block' : 'none';
            document.getElementById('uiTargetClient').style.display = (val === 'Client') ? 'block' : 'none';
        }
        document.addEventListener('DOMContentLoaded', toggleTargetUI);
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <div class="panel">
            <div style="font-size:20px; font-weight:700; margin-bottom:6px; display:flex; justify-content:space-between; align-items:center;">
                <span>Print Template Mapping Config</span>
                <a href="va_printer_routing.aspx" style="font-size:14px; background:var(--accent-2); color:var(--bg); padding:6px 12px; border-radius:6px; text-decoration:none; font-weight:bold;">&#9881; Configure Hardware Printers</a>
            </div>
            <div class="muted">Map a specific Handheld Tag Type scan category string (e.g. "Small_Standard") to its corresponding target Print Template ID.<br/>Additionally securely configure static target destinations (Hostname/Service or Database Print Client).</div>
            <asp:Literal ID="LitMessage" runat="server" />
            
            <div class="bucket-row" style="margin-top:20px;">
                <div class="filter">
                    <label>Tag Type String</label>
                    <asp:TextBox ID="TxtTagType" runat="server" placeholder="e.g. Small_Metal" list="tagTypesList" />
                    <datalist id="tagTypesList">
                        <option value="IQ350" />
                        <option value="Large_Metal" />
                        <option value="Small_Metal" />
                        <option value="Small_Standard" />
                    </datalist>
                    <div style="display:flex; gap:4px; margin-top:4px;">
                        <button type="button" class="btn btn-sm" onclick="document.getElementById('<%= TxtTagType.ClientID %>').value='IQ350'">IQ350</button>
                        <button type="button" class="btn btn-sm" onclick="document.getElementById('<%= TxtTagType.ClientID %>').value='Large_Metal'">Large_Metal</button>
                        <button type="button" class="btn btn-sm" onclick="document.getElementById('<%= TxtTagType.ClientID %>').value='Small_Metal'">Small_Metal</button>
                    </div>
                </div>
                <div class="filter">
                    <label>Print Template</label>
                    <asp:DropDownList ID="DdlTemplateID" runat="server" />
                </div>
                
                <div class="filter">
                    <label>Routing Destination</label>
                    <asp:DropDownList ID="DdlTargetType" runat="server" onchange="toggleTargetUI()">
                        <asp:ListItem Value="Default" Text="Template Default (None)" />
                        <asp:ListItem Value="Client" Text="Print Client (Secure Setup MQTT)" />
                        <asp:ListItem Value="Service" Text="Service Hostname (Showroom/Network)" />
                    </asp:DropDownList>
                </div>

                <div class="filter" id="uiTargetService" style="display:none;">
                    <label>Service Hostname String</label>
                    <asp:TextBox ID="TxtTargetService" runat="server" placeholder="e.g. showroom" />
                </div>

                <div class="filter" id="uiTargetClient" style="display:none;">
                    <label>Print Client Login</label>
                    <asp:DropDownList ID="DdlTargetClient" runat="server" />
                </div>

                <div class="filter" style="margin-bottom:2px;">
                    <asp:Button ID="BtnSave" runat="server" CssClass="btn" Text="Save Mapping" OnClick="BtnSave_Click" />
                </div>
                <div class="filter" style="margin-left:auto; margin-bottom:2px; display:flex; gap:8px;">
                    <a href="documentation/va_print_mapping.html" class="btn" style="border-color:var(--accent-2); color:var(--accent-2);">&#128214; View Docs</a>
                    <a href="va_print_admin.aspx" class="btn">&#128424; Print Admin</a>
                    <a href="index.aspx" class="btn">&#8962; Hub</a>
                </div>
            </div>
        </div>

        <div class="panel">
            <div class="gridWrap">
                <asp:GridView ID="GridMappings" runat="server" AutoGenerateColumns="false" CssClass="grid" 
                    OnRowCommand="GridMappings_RowCommand" DataKeyNames="Id" GridLines="None">
                    <Columns>
                        <asp:BoundField DataField="TagType" HeaderText="Scanning Tag Type" />
                        <asp:BoundField DataField="TemplateName" HeaderText="Target Print Template" />
                        <asp:BoundField DataField="Routing" HeaderText="Service Routing Destination" />
                        <asp:TemplateField>
                            <ItemTemplate>
                                <asp:Button ID="BtnDelete" runat="server" CssClass="btn btn-sm" Text="Remove" 
                                    CommandName="DeleteRow" CommandArgument='<%# Eval("Id") %>' 
                                    OnClientClick="return confirm('Delete this template mapping?');" />
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </form>
</body>
</html>
