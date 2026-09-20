<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_mqtt_config.aspx.cs" Inherits="va_mqtt_config" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>MQTT Configuration &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--bg-base); color: var(--text-main);
            font-family: 'Inter','Segoe UI',sans-serif; font-size: 14px;
            min-height: 100vh;
        }

        .dash { max-width: 1200px; margin: 0 auto; padding: 30px 24px; }

        /* Header */
        .page-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 28px; border-bottom: 1px solid var(--panel-border);
            padding-bottom: 20px; flex-wrap: wrap; gap: 16px;
        }
        .page-header h1 {
            font-size: 26px; font-weight: 700;
            background: linear-gradient(90deg, #8B5CF6, #2EA8FF);
            -webkit-background-clip: text; background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .header-right { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .hdr-pill {
            display: inline-flex; align-items: center; gap: 5px;
            padding: 6px 12px; border-radius: 8px; font-size: 13px; font-weight: 600;
            text-decoration: none; cursor: pointer;
            border: 1px solid var(--panel-border); background: transparent;
            color: var(--accent); transition: background .15s, border-color .15s;
        }
        .hdr-pill:hover { border-color: var(--accent); background: color-mix(in srgb, var(--accent), transparent 90%); }
        .hdr-pill.hub { color: var(--accent); }

        /* Glass panels */
        .glass {
            background: var(--panel-bg);
            border: 1px solid var(--panel-border);
            border-radius: 16px; padding: 24px;
            box-shadow: var(--shadow);
            margin-bottom: 22px;
        }
        .panel-title {
            font-size: 13px; text-transform: uppercase; letter-spacing: .8px;
            color: var(--text-accent); font-weight: 700; margin-bottom: 18px;
            display: flex; align-items: center; gap: 10px;
        }

        /* Form controls */
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        @media(max-width: 700px) { .form-grid { grid-template-columns: 1fr; } }
        .form-group { margin-bottom: 14px; }
        .form-group label {
            display: block; font-size: 12px; font-weight: 600;
            color: var(--text-accent); margin-bottom: 5px; text-transform: uppercase;
            letter-spacing: .5px;
        }
        .ctrl-input {
            width: 100%; padding: 8px 12px; border-radius: 8px;
            border: 1.5px solid var(--panel-border); background: var(--panel-bg);
            color: var(--text-main); font-size: 13px; font-family: inherit;
            transition: border-color .2s;
        }
        .ctrl-input:focus { border-color: var(--accent); outline: none; }
        .ctrl-select {
            padding: 8px 12px; border-radius: 8px;
            border: 1.5px solid var(--panel-border); background: var(--panel-bg);
            color: var(--text-main); font-size: 13px; font-family: inherit; width: 100%;
        }
        .ctrl-select option { background: var(--panel-bg); color: var(--text-main); }

        /* Toggle switch */
        .toggle-row { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
        .toggle-switch { position: relative; width: 48px; height: 26px; }
        .toggle-switch input { opacity: 0; width: 0; height: 0; }
        .toggle-slider {
            position: absolute; top: 0; left: 0; right: 0; bottom: 0;
            background: var(--panel-border); border-radius: 26px; cursor: pointer;
            transition: background .3s;
        }
        .toggle-slider::before {
            content: ''; position: absolute; left: 3px; top: 3px;
            width: 20px; height: 20px; background: #fff; border-radius: 50%;
            transition: transform .3s;
        }
        .toggle-switch input:checked + .toggle-slider { background: var(--accent-2); }
        .toggle-switch input:checked + .toggle-slider::before { transform: translateX(22px); }
        .toggle-label { font-weight: 600; font-size: 14px; }

        /* Checkboxes */
        .chk-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
        @media(max-width: 600px) { .chk-grid { grid-template-columns: 1fr 1fr; } }
        .chk-label {
            display: flex; align-items: center; gap: 6px;
            font-size: 12px; cursor: pointer; padding: 6px 10px;
            border-radius: 8px; border: 1px solid var(--panel-border);
            transition: all .2s;
        }
        .chk-label:hover { border-color: var(--accent); }
        .chk-label input[type="checkbox"] { accent-color: var(--accent); }

        /* Buttons */
        .btn-primary {
            padding: 8px 20px; border-radius: 8px; border: none;
            background: var(--accent); color: #fff; font-weight: 600;
            font-size: 13px; cursor: pointer; transition: all .2s;
        }
        .btn-primary:hover { filter: brightness(1.15); transform: translateY(-1px); }
        .btn-secondary {
            padding: 8px 20px; border-radius: 8px;
            border: 1.5px solid var(--panel-border); background: transparent;
            color: var(--text-main); font-weight: 600; font-size: 13px;
            cursor: pointer; transition: all .2s;
        }
        .btn-secondary:hover { border-color: var(--accent); }
        .btn-danger {
            padding: 5px 12px; border-radius: 6px; border: 1px solid var(--danger, #dc3545);
            background: transparent; color: var(--danger, #dc3545); font-size: 11px;
            cursor: pointer; transition: all .2s; font-weight: 600;
        }
        .btn-danger:hover { background: var(--danger, #dc3545); color: #fff; }
        .btn-bar { display: flex; gap: 10px; margin-top: 16px; flex-wrap: wrap; }

        /* Status */
        .status-ok { background: color-mix(in srgb, var(--accent-2), transparent 88%); color: var(--accent-2); padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 600; margin-top: 12px; }
        .status-err { background: color-mix(in srgb, var(--danger, #dc3545), transparent 88%); color: var(--danger, #dc3545); padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 600; margin-top: 12px; }
        .count-badge { font-size: 12px; padding: 3px 10px; border-radius: 12px; background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--accent); font-weight: 600; }
        .count-badge.empty { background: color-mix(in srgb, var(--warn, #ffc107), transparent 85%); color: var(--warn, #ffc107); }



        /* Grid */
        .tbl-wrap { overflow-x: auto; margin-top: 14px; }
        table.client-grid { width: 100%; border-collapse: collapse; font-size: 13px; }
        table.client-grid th {
            text-align: left; padding: 10px 12px; font-weight: 700; font-size: 11px;
            text-transform: uppercase; letter-spacing: .5px; color: var(--text-accent);
            border-bottom: 2px solid var(--panel-border);
        }
        table.client-grid td {
            padding: 10px 12px; border-bottom: 1px solid var(--panel-border);
            vertical-align: middle;
        }
        table.client-grid tr:hover td { background: color-mix(in srgb, var(--accent), transparent 95%); }
        .access-chip {
            display: inline-block; padding: 2px 8px; border-radius: 10px;
            font-size: 10px; font-weight: 600; margin: 1px 2px;
        }
        .access-chip.on { background: color-mix(in srgb, var(--accent-2), transparent 80%); color: var(--accent-2); }
        .access-chip.off { background: var(--panel-border); color: var(--text-accent); opacity: .5; }

        /* Two column layout */
        .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 22px; }
        @media(max-width: 900px) { .two-col { grid-template-columns: 1fr; } }

        /* Separator */
        .sep { border: none; border-top: 1px solid var(--panel-border); margin: 20px 0; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">
    <!-- HEADER -->
    <div class="page-header">
        <h1>&#128225; MQTT Configuration</h1>
        <div class="header-right">
            <a href="documentation/va_mqtt_config.html" class="hdr-pill">&#128196; Docs</a>
            <a href="va_asset_master.aspx" class="hdr-pill">&#128203; Asset Master</a>
            <a href="va_site_config.aspx" class="hdr-pill" title="Site Configuration">&#9881; Site Config</a>
            <a href="index.aspx" class="hdr-pill hub">&#8962; Hub</a>
        </div>
    </div>

    <!-- STATUS -->
    <asp:Literal ID="LitStatus" runat="server" />

    <!-- SECTION 1: BROKER SETTINGS -->
    <div class="glass">
        <div class="panel-title">
            <span>&#9881; MQTT Broker Settings</span>
        </div>

        <div class="toggle-row">
            <label class="toggle-switch">
                <asp:CheckBox ID="ChkMqttEnabled" runat="server" />
                <span class="toggle-slider"></span>
            </label>
            <span class="toggle-label">MQTT Enabled</span>
        </div>

        <div class="two-col">
            <div>
                <div class="panel-title" style="font-size:11px; margin-bottom:12px;">Database Settings (applicationsetting)</div>
                <div class="form-group">
                    <label>Broker Location</label>
                    <asp:TextBox ID="TxtBrokerLocation" runat="server" CssClass="ctrl-input" placeholder="e.g., Web Server or localhost" />
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>Gateway Username</label>
                        <asp:TextBox ID="TxtGatewayUser" runat="server" CssClass="ctrl-input" placeholder="mqttgateway" />
                    </div>
                    <div class="form-group">
                        <label>Gateway Password</label>
                        <asp:TextBox ID="TxtGatewayPass" runat="server" CssClass="ctrl-input" placeholder="password" />
                    </div>
                </div>
            </div>
            <div>
                <div class="panel-title" style="font-size:11px; margin-bottom:12px;">App Settings (appsettings.json)</div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>MQTT Server</label>
                        <asp:TextBox ID="TxtMqttServer" runat="server" CssClass="ctrl-input" placeholder="hostname or IP" />
                    </div>
                    <div class="form-group">
                        <label>MQTT Port</label>
                        <asp:TextBox ID="TxtMqttPort" runat="server" CssClass="ctrl-input" placeholder="8883" />
                    </div>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>Print Client Username</label>
                        <asp:TextBox ID="TxtPrintUser" runat="server" CssClass="ctrl-input" placeholder="print user" />
                    </div>
                    <div class="form-group">
                        <label>Print Client Password</label>
                        <asp:TextBox ID="TxtPrintPass" runat="server" CssClass="ctrl-input" placeholder="print password" />
                    </div>
                </div>
            </div>
        </div>

        <hr class="sep" />
        <div class="panel-title" style="font-size:11px; margin-bottom:12px;">Global MQTT Subscriptions</div>
        <div class="chk-grid">
            <label class="chk-label"><asp:CheckBox ID="ChkSubAlarms" runat="server" Checked="true" /> Alarm Subscriptions</label>
            <label class="chk-label"><asp:CheckBox ID="ChkSubEvents" runat="server" Checked="true" /> Event Subscriptions</label>
            <label class="chk-label"><asp:CheckBox ID="ChkSubGateway" runat="server" Checked="true" /> Gateway Message Subscriptions</label>
            <label class="chk-label"><asp:CheckBox ID="ChkSubSensor" runat="server" Checked="true" /> Sensor Reading Subscriptions</label>
            <label class="chk-label"><asp:CheckBox ID="ChkSubMoves" runat="server" Checked="true" /> V-Tag Movement Subscriptions</label>
            <label class="chk-label"><asp:CheckBox ID="ChkSubObs" runat="server" Checked="true" /> Tag Observation Subscriptions</label>
        </div>

        <div class="btn-bar">
            <asp:Button ID="BtnSaveSettings" runat="server" CssClass="btn-primary"
                Text="&#128190; Save Settings" OnClick="BtnSaveSettings_Click" />
        </div>
    </div>

    <!-- SECTION 2: MQTT CLIENTS -->
    <div class="glass">
        <div class="panel-title">
            <span>&#128101; MQTT Client Management</span>
            <asp:Literal ID="LitClientCount" runat="server" />
        </div>

        <!-- Add client form -->
        <div style="background: color-mix(in srgb, var(--accent), transparent 95%); border-radius: 12px; padding: 18px; margin-bottom: 18px;">
            <div style="font-size: 12px; font-weight: 700; color: var(--accent); text-transform: uppercase; letter-spacing: .5px; margin-bottom: 12px;">
                Add New Client
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label>Site</label>
                    <asp:DropDownList ID="DdlSite" runat="server" CssClass="ctrl-select" />
                </div>
                <div class="form-group">
                    <label>Username</label>
                    <asp:TextBox ID="TxtClientUser" runat="server" CssClass="ctrl-input" placeholder="mqtt_sitename" />
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <asp:TextBox ID="TxtClientPass" runat="server" CssClass="ctrl-input" placeholder="auto-generated if blank" />
                </div>
            </div>
            <div style="margin-top: 8px;">
                <div style="font-size: 11px; font-weight: 600; color: var(--text-accent); margin-bottom: 6px;">ACCESS PERMISSIONS</div>
                <div class="chk-grid">
                    <label class="chk-label"><asp:CheckBox ID="ChkAlarms" runat="server" Checked="true" /> Alarms</label>
                    <label class="chk-label"><asp:CheckBox ID="ChkEvents" runat="server" Checked="true" /> Events</label>
                    <label class="chk-label"><asp:CheckBox ID="ChkGateway" runat="server" Checked="true" /> Gateway</label>
                    <label class="chk-label"><asp:CheckBox ID="ChkMoves" runat="server" Checked="true" /> Tag Moves</label>
                    <label class="chk-label"><asp:CheckBox ID="ChkObs" runat="server" Checked="true" /> Tag Observations</label>
                    <label class="chk-label"><asp:CheckBox ID="ChkSensors" runat="server" Checked="true" /> Sensors</label>
                </div>
            </div>
            <div class="btn-bar">
                <asp:Button ID="BtnAddClient" runat="server" CssClass="btn-primary"
                    Text="&#10133; Add Client" OnClick="BtnAddClient_Click" />
                <asp:Button ID="BtnBulkCreate" runat="server" CssClass="btn-secondary"
                    Text="&#9889; Create Client for Each Site" OnClick="BtnBulkCreate_Click"
                    OnClientClick="return confirm('Create MQTT clients for all sites that don\'t have one?');" />
            </div>
        </div>

        <asp:Literal ID="LitClientStatus" runat="server" />

        <!-- Client grid -->
        <div class="tbl-wrap">
            <asp:GridView ID="GridClients" runat="server" AutoGenerateColumns="false"
                CssClass="client-grid" ClientIDMode="Static"
                GridLines="None" EmptyDataText="No MQTT clients configured yet.">
                <Columns>
                    <asp:BoundField DataField="id" HeaderText="ID" />
                    <asp:BoundField DataField="SiteName" HeaderText="Site" />
                    <asp:BoundField DataField="username" HeaderText="Username" />
                    <asp:BoundField DataField="password" HeaderText="Password" />
                    <asp:TemplateField HeaderText="Access">
                        <ItemTemplate>
                            <span class='access-chip <%# Convert.ToBoolean(Eval("accessalarms")) ? "on" : "off" %>'>Alarms</span>
                            <span class='access-chip <%# Convert.ToBoolean(Eval("accessevents")) ? "on" : "off" %>'>Events</span>
                            <span class='access-chip <%# Convert.ToBoolean(Eval("accessgatewaymessages")) ? "on" : "off" %>'>Gateway</span>
                            <span class='access-chip <%# Convert.ToBoolean(Eval("accesstagmovements")) ? "on" : "off" %>'>Moves</span>
                            <span class='access-chip <%# Convert.ToBoolean(Eval("accesstagobservations")) ? "on" : "off" %>'>Obs</span>
                            <span class='access-chip <%# Convert.ToBoolean(Eval("accessvtagsensors")) ? "on" : "off" %>'>Sensors</span>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="">
                        <ItemTemplate>
                            <button type="button" class="btn-danger" onclick="deleteClient(<%# Eval("id") %>)">&#128465; Delete</button>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>

        <!-- Hidden delete form -->
        <asp:HiddenField ID="HidDeleteId" runat="server" />
        <asp:Button ID="BtnDeleteClient" runat="server" CssClass="btn-danger" style="display:none"
            OnClick="BtnDeleteClient_Click" />
    </div>

</div>
</form>

<script type="text/javascript">
    function deleteClient(id) {
        if (!confirm('Delete MQTT client #' + id + '?')) return;
        document.getElementById('<%= HidDeleteId.ClientID %>').value = id;
        document.getElementById('<%= BtnDeleteClient.ClientID %>').click();
    }
</script>
</body>
</html>

