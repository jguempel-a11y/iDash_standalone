<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_site_config.aspx.cs" Inherits="va_site_config" ResponseEncoding="utf-8" %>
<%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Site Configuration &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta charset="utf-8" />
<style>
    :root { --chip-br: var(--line); }
    [data-theme="light"] { --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1); }
    *{box-sizing:border-box;}
    body{background:var(--bg);color:var(--text);font-family:Segoe UI,Tahoma,Arial,sans-serif;margin:0;}
    .app{display:flex;min-height:100vh;}
    .side{width:260px;background:var(--chip);border-right:1px solid var(--line);padding:22px 18px;flex-shrink:0;position:sticky;top:0;height:100vh;overflow-y:auto;}
    .side h1{font-size:17px;margin:0 0 4px;color:var(--accent);}
    .side .sub{font-size:12px;color:var(--muted);margin-bottom:20px;}
    .nav-link{display:block;background:var(--chip);border:1px solid var(--chip-br);border-radius:8px;padding:9px 13px;color:var(--text);font-size:13px;font-weight:600;text-decoration:none;margin-bottom:7px;}
    .nav-link:hover{background:var(--accent);color:var(--bg);border-color:var(--accent);}
    .slabel{font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin:16px 0 7px;}
    .main{flex:1;padding:32px 42px;max-width:920px;}
    .page-title{font-size:24px;font-weight:700;margin:0 0 4px;}
    .page-sub{color:var(--muted);font-size:13px;margin-bottom:26px;}
    .panel{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:22px 26px;margin-bottom:24px;}
    .panel-sub{background:var(--chip);border:1px solid var(--line);border-radius:10px;padding:16px 20px;margin:16px 0;}
    .ptitle{font-size:16px;font-weight:700;margin:0 0 4px;color:var(--accent);}
    .ptitle2{font-size:14px;font-weight:700;margin:12px 0 8px;color:var(--accent);border-bottom:1px solid var(--line);padding-bottom:6px;}
    .psub{font-size:13px;color:var(--muted);margin-bottom:18px;}
    .fg{display:grid;grid-template-columns:210px 1fr;gap:9px 14px;align-items:center;}
    .fl{font-size:13px;font-weight:600;color:var(--muted);}
    .fl span{display:block;font-size:11px;font-weight:400;color:var(--muted);margin-top:1px;opacity:0.8;}
    input[type=text],input[type=password],input[type=time]{width:100%;padding:9px 11px;border-radius:8px;background:var(--bg);border:1px solid var(--line);color:var(--text);font-size:13px;outline:none;}
    input:focus{border-color:var(--accent);}
    select{width:100%;padding:9px 11px;border-radius:8px;background:var(--bg);border:1px solid var(--line);color:var(--text);font-size:13px;outline:none;}
    .sep{grid-column:1/-1;border:none;border-top:1px solid var(--line);margin:4px 0;}
    .btn{padding:9px 20px;background:var(--accent);color:#fff;border-radius:10px;border:1px solid var(--accent);cursor:pointer;font-weight:700;font-size:13px;margin-top:16px;transition:filter .15s;display:inline-block;}
    .btn:hover{filter:brightness(1.12);}
    .btn.green{background:var(--accent-2);border-color:var(--accent-2);color:#fff;}
    .btn.red{background:var(--danger);border-color:var(--danger);color:#fff;}
    .btn.sm{padding:5px 12px;font-size:12px;margin-top:0;}
    /* Force white on anchor-based .btn regardless of browser link colors */
    a.btn,a.btn:link,a.btn:visited{color:#fff !important;text-decoration:none;}
    a.btn.ghost,a.btn.ghost:link,a.btn.ghost:visited{background:var(--bg);color:var(--text) !important;border:1px solid var(--line);}
    a.btn.ghost:hover{border-color:var(--accent);color:var(--accent) !important;filter:none;}
    /* Compact nav-card grid */
    .nav-card-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin:0 0 8px;}
    @media(max-width:900px){.nav-card-grid{grid-template-columns:1fr 1fr;}}
    @media(max-width:600px){.nav-card-grid{grid-template-columns:1fr;}}
    .nav-card{background:var(--chip);border:1px solid var(--line);border-radius:14px;padding:16px 18px;display:flex;flex-direction:column;gap:8px;}
    .nav-card-title{font-size:13px;font-weight:700;color:var(--text);margin-bottom:2px;}
    .nav-card-desc{font-size:11px;color:var(--muted);line-height:1.5;flex:1;}
    .nav-card-btns{display:flex;flex-direction:column;gap:6px;padding-top:10px;border-top:1px solid var(--line);margin-top:4px;}
    .ncard-btn,.ncard-btn:link,.ncard-btn:visited{display:block;width:100%;padding:8px 10px;border-radius:8px;font-size:12px;font-weight:600;text-align:center;text-decoration:none;cursor:pointer;background:var(--accent);color:#fff !important;border:1px solid var(--accent);transition:filter .15s;box-sizing:border-box;font-family:inherit;}
    .ncard-btn:hover{filter:brightness(1.1);}
    .ncard-btn.ghost,.ncard-btn.ghost:link,.ncard-btn.ghost:visited{background:var(--bg);color:var(--text) !important;border:1px solid var(--line);}
    .ncard-btn.ghost:hover{border-color:var(--accent);color:var(--accent) !important;filter:none;}
    .ncard-btn.green,.ncard-btn.green:link,.ncard-btn.green:visited{background:var(--accent-2);border-color:var(--accent-2);color:#fff !important;}
    .test-result{padding:10px;margin-top:10px;border-radius:8px;font-size:12px;display:none;}
    .checklist{list-style:none;padding:0;margin:0;}
    .checklist li{display:flex;align-items:flex-start;gap:10px;padding:9px 0;border-bottom:1px solid var(--line);font-size:13px;color:var(--muted);}
    .checklist li:last-child{border-bottom:none;}
    .checklist li strong{color:var(--text);}
    .badge{display:inline-block;padding:2px 8px;border-radius:20px;font-size:11px;font-weight:700;margin-left:6px;}
    .req{background:color-mix(in srgb, var(--danger), transparent 85%);border:1px solid #ef4444;color:#ef4444;}
    .opt{background:color-mix(in srgb, var(--accent-2), transparent 85%);border:1px solid #10b981;color:#10b981;}
    .inf{background:color-mix(in srgb, var(--accent), transparent 85%);border:1px solid #2ea8ff;color:#2ea8ff;}
    pre.sql-preview{background:var(--chip);border:1px solid var(--line);border-radius:8px;padding:12px;font-size:13px;color:var(--accent);margin:12px 0 0;white-space:pre-wrap;}
    /* Recipients list */
    .rcpt-list{list-style:none;padding:0;margin:10px 0;}
    .rcpt-list li{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:9px 14px;margin-bottom:7px;display:flex;justify-content:space-between;align-items:center;font-size:13px;}
    .rcpt-add{display:flex;gap:10px;margin-top:12px;align-items:center;}
    .rcpt-add input{flex:1;margin-top:0;}
    /* Excel fields checkbox grid */
    /* Excel fields – rendered by asp:CheckBoxList RepeatColumns=3 */
    .field-grid{width:100%;}
    .field-grid table{width:100%;border-collapse:separate;border-spacing:4px;}
    .field-grid table td{background:var(--bg);border:1px solid var(--line);border-radius:6px;padding:4px 8px;vertical-align:middle;}
    .field-grid table td:hover{border-color:var(--accent);cursor:pointer;}
    .field-grid table td label{font-size:11px;cursor:pointer;white-space:nowrap;display:inline-flex;align-items:center;gap:6px;width:100%;}
    .field-grid table td input[type=checkbox]{cursor:pointer;flex-shrink:0;}
    /* Script preview */
    .script-box{background:var(--chip);border:1px solid var(--line);border-radius:8px;padding:14px;font-family:Consolas,monospace;font-size:12px;color:#facc15;margin:12px 0;white-space:pre;}
.header{background:var(--card);padding:14px 24px;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;flex-shrink:0;}
.header h1{margin:0;font-size:19px;font-weight:700;color:var(--accent);}
.header-nav{display:flex;gap:8px;align-items:center;}
</style>
</head>
<body>
<form id="form1" runat="server">

<div class="header">
    <h1>&#9881; Site Configuration</h1>
    <div class="header-nav">
        <a href="documentation/va_site_config.html" class="nav-pill nav-pill-ghost">&#128214; Docs</a>
        <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
    </div>
</div>

<div class="app">

<aside class="side">
    <h1>&#9881; Site Config</h1>
    <div class="sub">VISN Deployment Setup</div>
    <div class="slabel">Sections</div>
    <a href="#sec-db"           class="nav-link">&#128196; Database</a>
    <a href="#sec-sql"          class="nav-link">&#9654; One-Time SQL</a>
    <a href="#sec-api"          class="nav-link">&#128279; API / OAuth</a>
    <a href="#sec-mqtt"         class="nav-link">&#128225; Fixed Reader / MQTT</a>
    <a href="#sec-rabbitmq"     class="nav-link">&#128007; RabbitMQ Broker</a>
    <a href="#sec-mqtt-admin"   class="nav-link">&#128272; MQTT / Print Clients</a>
    <a href="#sec-readers"      class="nav-link">&#128250; Fixed Reader Mgmt</a>
    <a href="#sec-print-admin"  class="nav-link">&#128424; Printer Administration</a>
    <a href="va_print_setup_wizard.aspx" class="nav-link" style="color:#f59e0b; font-weight:700;">&#129668; Print Setup Wizard</a>
    <a href="#sec-print-routing" class="nav-link">&#128438; Printer Routing</a>
    <a href="#sec-email"        class="nav-link">&#9993; Email / SMTP</a>
    <a href="#sec-recipients"   class="nav-link">&#128231; Recipients</a>
    <a href="#sec-alerts"       class="nav-link">&#128276; Notifications</a>
    <a href="#sec-reports"      class="nav-link">&#128197; Report Automation</a>
    <a href="#sec-services"     class="nav-link">&#128260; Service Control</a>
    <a href="#sec-scan-columns" class="nav-link">&#128241; Scanning Columns</a>
    <a href="#sec-check"        class="nav-link">&#9989; Checklist</a>
</aside>

<main class="main">
    <div class="page-title">&#127759; Site Configuration</div>
    <div class="page-sub">
        Configure all site-specific settings for this VISN deployment.
        Changes write directly to <code>web.config</code> or local JSON files as noted.
    </div>

    <asp:Literal ID="LitMsg" runat="server" />

    <!-- DATABASE -->
    <div class="panel" id="sec-db">
        <div class="ptitle">&#128196; Database Connection</div>
        <div class="psub">How iDash connects to the local AssetWorx SQL Express instance. Server is usually <code>.\sqlexpress</code>.</div>
        <div class="fg">
            <div class="fl">SQL Server / Instance<span>e.g. .\sqlexpress</span></div>
            <asp:TextBox ID="TxtDbServer" runat="server" />
            <div class="fl">Database Name<span>Usually: assetworx</span></div>
            <asp:TextBox ID="TxtDbName" runat="server" />
            <div class="fl">SQL Username<span>Usually: assetworxadmin</span></div>
            <asp:TextBox ID="TxtDbUser" runat="server" />
            <div class="fl">SQL Password<span>Leave blank to keep existing</span></div>
            <asp:TextBox ID="TxtDbPass" runat="server" TextMode="Password" placeholder="(unchanged if blank)" />
        </div>
        <asp:Button ID="BtnSaveDb" runat="server" CssClass="btn" Text="Save Database Settings" OnClick="BtnSaveDb_Click" />
        <asp:Button ID="BtnTestConn" runat="server" CssClass="btn green" Text="&#9889; Test Connection" OnClick="BtnTestConn_Click" style="margin-left:8px;" />
        <div style="font-size:12px;color:var(--muted);margin-top:8px;">Save first, then Test to verify iDash can reach the database and core tables exist.</div>
    </div>

    <!-- API -->
    <div class="panel" id="sec-api">
        <div class="ptitle">&#128279; API / OAuth Settings</div>
        <div class="psub">Credentials used to authenticate iDash against the local AssetWorx REST API.
            The Client ID is your site-specific client registered in the <code>clientapp</code> database table
            (e.g. <code>v512</code>, <code>idash_613</code>, <code>idash_512</code>).
            The AssetWorx superadmin login is separate — sign in via AssetWorx &rarr; Tools &rarr; Options.</div>
        <div class="fg">
            <div class="fl">API Base URL<span>Usually: http://localhost/api</span></div>
            <asp:TextBox ID="TxtApiBase" runat="server" />
            <div class="fl">Token URL<span>Usually: http://localhost/connect/token</span></div>
            <asp:TextBox ID="TxtTokenUrl" runat="server" />
            <div class="fl">Client ID<span>e.g. visn5, visn8, visn19</span></div>
            <asp:TextBox ID="TxtClientId" runat="server" />
            <div class="fl">Client Secret<span>Leave blank to keep existing</span></div>
            <asp:TextBox ID="TxtClientSecret" runat="server" TextMode="Password" placeholder="(unchanged if blank)" />
        </div>
        <asp:Button ID="BtnSaveApi" runat="server" CssClass="btn" Text="Save API Settings" OnClick="BtnSaveApi_Click" />
    </div>

    <!-- FIXED READER / MQTT -->
    <div class="panel" id="sec-mqtt">
        <div class="ptitle">&#128225; Fixed Reader / MQTT</div>
        <div class="psub">
            Settings for the iDash antenna service that subscribes to RFID tag reads from the Zebra FX9600 fixed readers.
            The same MQTT broker is used for label printing. All three services (fixed reader, iDash, and printing)
            connect to the same broker with different credentials.
            Settings saved to <code>web.config</code>.
        </div>
        <div class="fg">
            <div class="fl">MQTT Broker Host<span>Usually 127.0.0.1 when on same server</span></div>
            <asp:TextBox ID="TxtMqttServer" runat="server" placeholder="127.0.0.1" />
            <div class="fl">MQTT Port<span>Usually 8883 (TLS) or 1883</span></div>
            <asp:TextBox ID="TxtMqttPort" runat="server" placeholder="8883" />
            <div class="fl">iDash Antenna Username<span>MQTT client ID for the tag observation subscriber</span></div>
            <asp:TextBox ID="TxtMqttUser" runat="server" placeholder="idash_antenna" />
            <div class="fl">iDash Antenna Password<span>Leave blank to keep existing</span></div>
            <asp:TextBox ID="TxtMqttPass" runat="server" TextMode="Password" placeholder="(unchanged if blank)" />
            <div class="fl">Tag Observation Topic<span>MQTT topic the readers publish to — e.g. awrx/7/tagobservation</span></div>
            <asp:TextBox ID="TxtMqttTopic" runat="server" placeholder="awrx/7/tagobservation" />
            <div class="fl">Tag Debounce (seconds)<span>Minimum seconds between repeated location updates for the same tag</span></div>
            <asp:TextBox ID="TxtDebounce" runat="server" placeholder="5" />
        </div>
        <asp:Button ID="BtnSaveMqtt" runat="server" CssClass="btn" Text="Save MQTT Settings" OnClick="BtnSaveMqtt_Click" />
        <asp:Button ID="BtnTestMqtt" runat="server" CssClass="btn green" Text="&#9889; Test MQTT Connection" OnClick="BtnTestMqtt_Click" style="margin-left:8px;" />
        <div style="font-size:12px;color:var(--muted);margin-top:8px;">Tests TCP connectivity to the MQTT broker. Save first if you changed the host or port.</div>
    </div>

    <!-- RABBITMQ BROKER STATUS -->
    <div class="panel" id="sec-rabbitmq">
        <div class="ptitle">&#128007; RabbitMQ Broker Status</div>
        <div class="psub">
            Live monitoring of the RabbitMQ MQTT broker. Data sourced from the RabbitMQ Management API
            (<code>http://localhost:15672/api</code>) and the iDash Antenna Service status endpoint.
            <a href="documentation/va_rabbitmq_setup.html" target="_blank" style="margin-left:8px;">&#128218; Setup Guide</a>
        </div>

        <div id="rmqStatus" style="margin-top:16px;">
            <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-bottom:16px;">
                <div class="panel-sub" style="text-align:center;">
                    <div style="font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:1px;">Service</div>
                    <div id="rmqSvc" style="font-size:20px;font-weight:700;margin-top:4px;">--</div>
                </div>
                <div class="panel-sub" style="text-align:center;">
                    <div style="font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:1px;">Connections</div>
                    <div id="rmqConns" style="font-size:20px;font-weight:700;margin-top:4px;">--</div>
                </div>
                <div class="panel-sub" style="text-align:center;">
                    <div style="font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:1px;">MQTT Messages</div>
                    <div id="rmqMsgs" style="font-size:20px;font-weight:700;margin-top:4px;">--</div>
                </div>
                <div class="panel-sub" style="text-align:center;">
                    <div style="font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:1px;">Queues</div>
                    <div id="rmqQueues" style="font-size:20px;font-weight:700;margin-top:4px;">--</div>
                </div>
            </div>

            <div id="rmqConnTable" style="margin-bottom:16px;"></div>
            <div id="rmqQueueTable" style="margin-bottom:16px;"></div>
            <div id="rmqConfig" style="margin-bottom:12px;"></div>
        </div>

        <button type="button" class="btn green" onclick="loadRmqStatus()" style="margin-top:4px;">&#9889; Refresh Status</button>
        <a href="http://localhost:15672" target="_blank" class="btn" style="margin-left:8px;text-decoration:none;display:inline-block;">&#127760; Open Management UI</a>
        <div style="font-size:12px;color:var(--muted);margin-top:8px;">Management UI login: guest / guest (localhost only).</div>
    </div>

    <script>
    function loadRmqStatus() {
        // 1. Fetch iDash antenna service status
        fetch('/idash/va_fixed_reader_live.aspx?api=status')
            .then(function(r){ return r.json(); })
            .then(function(d){
                document.getElementById('rmqMsgs').innerHTML = '<span style="color:var(--accent)">' + (d.messagesReceived||0) + '</span>';
                document.getElementById('rmqSvc').innerHTML = d.serviceRunning
                    ? '<span style="color:#3fb950">&#9679; Running</span>'
                    : '<span style="color:var(--danger)">&#9679; Stopped</span>';
            }).catch(function(){
                document.getElementById('rmqSvc').innerHTML = '<span style="color:var(--muted)">Unknown</span>';
            });

        // 2. Fetch RabbitMQ connections (via server-side proxy)
        fetch('va_site_config.aspx?api=rmq&path=connections')
            .then(function(r){ return r.json(); })
            .then(function(conns){
                if (conns.error) { throw new Error(conns.error); }
                document.getElementById('rmqConns').innerHTML = '<span style="color:var(--accent)">' + conns.length + '</span>';
                var html = '<table style="width:100%;border-collapse:collapse;font-size:13px;">';
                html += '<thead><tr style="background:var(--chip);"><th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">User</th>';
                html += '<th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">Protocol</th>';
                html += '<th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">Client ID</th>';
                html += '<th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">State</th>';
                html += '<th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">Recv/Send</th></tr></thead><tbody>';
                for (var i = 0; i < conns.length; i++) {
                    var c = conns[i];
                    var clientId = c.client_properties && c.client_properties.client_id ? c.client_properties.client_id : '\u2014';
                    var stateColor = c.state === 'running' ? '#3fb950' : 'var(--danger)';
                    html += '<tr>';
                    html += '<td style="padding:6px 10px;border:1px solid var(--line);"><code>' + (c.user||'\u2014') + '</code></td>';
                    html += '<td style="padding:6px 10px;border:1px solid var(--line);">' + (c.protocol||'\u2014') + '</td>';
                    html += '<td style="padding:6px 10px;border:1px solid var(--line);"><code>' + clientId + '</code></td>';
                    html += '<td style="padding:6px 10px;border:1px solid var(--line);"><span style="color:' + stateColor + '">&#9679; ' + (c.state||'\u2014') + '</span></td>';
                    html += '<td style="padding:6px 10px;border:1px solid var(--line);">' + (c.recv_oct||0) + 'B / ' + (c.send_oct||0) + 'B</td>';
                    html += '</tr>';
                }
                html += '</tbody></table>';
                document.getElementById('rmqConnTable').innerHTML = conns.length > 0 ? '<div style="font-size:12px;font-weight:600;margin-bottom:6px;color:var(--muted);">ACTIVE CONNECTIONS</div>' + html : '';
            }).catch(function(e){
                document.getElementById('rmqConns').innerHTML = '<span style="color:var(--muted)">N/A</span>';
                document.getElementById('rmqConnTable').innerHTML = '<div style="font-size:12px;color:var(--muted);">Could not reach RabbitMQ Management API. Is the service running?<br><small>' + (e.message||'') + '</small></div>';
            });

        // 3. Fetch RabbitMQ queues (via server-side proxy)
        fetch('va_site_config.aspx?api=rmq&path=queues')
            .then(function(r){ return r.json(); })
            .then(function(queues){
                if (queues.error) { throw new Error(queues.error); }
                document.getElementById('rmqQueues').innerHTML = '<span style="color:var(--accent)">' + queues.length + '</span>';
                if (queues.length > 0) {
                    var html = '<div style="font-size:12px;font-weight:600;margin-bottom:6px;color:var(--muted);">QUEUES</div>';
                    html += '<table style="width:100%;border-collapse:collapse;font-size:13px;">';
                    html += '<thead><tr style="background:var(--chip);"><th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">Name</th>';
                    html += '<th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">Type</th>';
                    html += '<th style="padding:6px 10px;border:1px solid var(--line);text-align:left;">Messages</th></tr></thead><tbody>';
                    for (var i = 0; i < queues.length; i++) {
                        var q = queues[i];
                        html += '<tr><td style="padding:6px 10px;border:1px solid var(--line);"><code>' + (q.name||'\u2014') + '</code></td>';
                        html += '<td style="padding:6px 10px;border:1px solid var(--line);">' + (q.type||'\u2014') + '</td>';
                        html += '<td style="padding:6px 10px;border:1px solid var(--line);">' + (q.messages||0) + '</td></tr>';
                    }
                    html += '</tbody></table>';
                    document.getElementById('rmqQueueTable').innerHTML = html;
                }
            }).catch(function(){
                document.getElementById('rmqQueues').innerHTML = '<span style="color:var(--muted)">N/A</span>';
            });

        // 4. Show current config
        var cfgHtml = '<div style="font-size:12px;font-weight:600;margin-bottom:6px;color:var(--muted);">CURRENT CONFIGURATION</div>';
        cfgHtml += '<table style="width:100%;border-collapse:collapse;font-size:13px;">';
        cfgHtml += '<tr><td style="padding:4px 10px;border:1px solid var(--line);width:200px;">Broker</td>';
        cfgHtml += '<td style="padding:4px 10px;border:1px solid var(--line);"><code>RabbitMQ 4.3.5</code> + Erlang/OTP 27.3.4</td></tr>';
        cfgHtml += '<tr><td style="padding:4px 10px;border:1px solid var(--line);">MQTT Port</td>';
        cfgHtml += '<td style="padding:4px 10px;border:1px solid var(--line);"><code>1883</code> (TCP, no TLS)</td></tr>';
        cfgHtml += '<tr><td style="padding:4px 10px;border:1px solid var(--line);">Management UI</td>';
        cfgHtml += '<td style="padding:4px 10px;border:1px solid var(--line);"><a href="http://localhost:15672" target="_blank">http://localhost:15672</a></td></tr>';
        cfgHtml += '<tr><td style="padding:4px 10px;border:1px solid var(--line);">Subscriber User</td>';
        cfgHtml += '<td style="padding:4px 10px;border:1px solid var(--line);"><code>idash_antenna</code></td></tr>';
        cfgHtml += '<tr><td style="padding:4px 10px;border:1px solid var(--line);">Topic Filter</td>';
        cfgHtml += '<td style="padding:4px 10px;border:1px solid var(--line);"><code>reader/#</code></td></tr>';
        cfgHtml += '</table>';
        document.getElementById('rmqConfig').innerHTML = cfgHtml;
    }

    // Auto-load on page ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', loadRmqStatus);
    } else {
        loadRmqStatus();
    }
    </script>

    <!-- NAV CARD GRID: Fixed Readers / MQTT / Print Admin -->
    <div class="nav-card-grid">

        <!-- Fixed Reader Management -->
        <div class="nav-card" id="sec-readers">
            <div class="nav-card-title">&#128250; Fixed Reader Management</div>
            <div class="nav-card-desc">
                Register, edit and delete Zebra FX9600 readers. Assign antenna locations, transmit power, and per-reader MQTT topics.
            </div>
            <div class="nav-card-btns">
                <a href="va_reader_config.aspx" class="ncard-btn">&#128250; Manage Readers &rarr;</a>
                <a href="va_fixed_reader.aspx" class="ncard-btn ghost">&#128202; Live Dashboard &rarr;</a>
                <asp:Button ID="BtnTestAntennaService" runat="server" CssClass="ncard-btn green" Text="&#9889; Test Antenna Service" OnClick="BtnTestAntennaService_Click" />
            </div>
        </div>

        <!-- MQTT / Print Clients -->
        <div class="nav-card" id="sec-mqtt-admin">
            <div class="nav-card-title">&#128272; MQTT / Print Clients</div>
            <div class="nav-card-desc">
                Broker host/port, TLS settings, global subscriptions, and per-site print client MQTT credentials.
            </div>
            <div class="nav-card-btns">
                <a href="va_mqtt_config.aspx" class="ncard-btn">&#128272; Open MQTT Config &rarr;</a>
            </div>
        </div>

        <!-- Printer Administration -->
        <div class="nav-card" id="sec-print-admin">
            <div class="nav-card-title">&#128424; Printer Administration</div>
            <div class="nav-card-desc">
                Templates, print client registrations, site readiness checks, configuration sync, and multi-site print setup.
            </div>
            <div class="nav-card-btns" style="display:flex; gap:8px; flex-wrap:wrap;">
                <a href="va_print_setup_wizard.aspx" class="ncard-btn" style="background:#f59e0b; border-color:#f59e0b; color:#000; font-weight:700;">&#129668; Print Setup Wizard &rarr;</a>
                <a href="va_print_admin.aspx" class="ncard-btn">&#128424; Open Print Admin &rarr;</a>
            </div>
        </div>

    </div>

    <!-- PRINTER ROUTING (full-width — has embedded JSON editor) -->
    <div class="panel" id="sec-print-routing">
        <div class="ptitle">&#128438; Printer Routing</div>
        <div class="psub">
            Maps BarTender template filenames (<code>.btw</code>) to Windows printer names for the bypass spooler.
            Edit the JSON below and save &mdash; changes apply on the next print job with no restart required.
            File: <code>C:\assetworx_prints\printer_routing.json</code>
        </div>
        <asp:TextBox ID="TxtPrintRouting" runat="server" TextMode="MultiLine"
            style="width:100%;height:240px;font-family:Consolas,monospace;font-size:13px;background:var(--chip);color:var(--text);border:1px solid var(--line);border-radius:8px;padding:12px;box-sizing:border-box;resize:vertical;"
            placeholder="{&#13;&#10;  &quot;AW_Metal_IQ350.btw&quot;: &quot;Your Printer Name Here&quot;&#13;&#10;}" />
        <asp:Button ID="BtnSavePrintRouting" runat="server" CssClass="btn" Text="Save Routing Table" OnClick="BtnSavePrintRouting_Click" style="margin-top:10px;" />
        <div style="font-size:12px;color:var(--muted);margin-top:8px;">Format: <code>{ "TemplateName.btw": "Windows Printer Name" }</code>. Printer names must match Windows print queue names exactly.</div>
    </div>

    <div class="panel" id="sec-email">
        <div class="ptitle">&#9993; Email / SMTP Settings</div>
        <div class="psub">SMTP server credentials used to send automated reports and alert notifications. Saved to <code>web.config</code>.</div>
        <div class="fg">
            <div class="fl">SMTP Host<span>e.g. smtp.office365.com</span></div>
            <asp:TextBox ID="TxtSmtpHost" runat="server" />
            <div class="fl">SMTP Port<span>Usually 587 (TLS)</span></div>
            <asp:TextBox ID="TxtSmtpPort" runat="server" />
            <div class="fl">SMTP Username</div>
            <asp:TextBox ID="TxtSmtpUser" runat="server" />
            <div class="fl">SMTP Password<span>Leave blank to keep existing</span></div>
            <asp:TextBox ID="TxtSmtpPass" runat="server" TextMode="Password" placeholder="(unchanged if blank)" />
            <hr class="sep" />
            <div class="fl">From Email Address<span>Displayed as sender</span></div>
            <asp:TextBox ID="TxtFromEmail" runat="server" />
            <div class="fl">From Display Name<span>e.g. iDash VISN 8 Reports</span></div>
            <asp:TextBox ID="TxtFromName" runat="server" />
        </div>
        <asp:Button ID="BtnSaveEmail" runat="server" CssClass="btn" Text="Save Email Settings" OnClick="BtnSaveEmail_Click" />
    </div>

    <!-- EMAIL RECIPIENTS -->
    <div class="panel" id="sec-recipients">
        <div class="ptitle">&#128231; Email Recipients</div>
        <div class="psub">
            These addresses receive all automated daily reports and system alert emails.
            Stored in <code>config/email_recipients.json</code> &mdash; changes take effect immediately with no app pool recycle.
        </div>

        <asp:Literal ID="LitRcptMsg" runat="server" />

        <ul class="rcpt-list">
            <asp:Repeater ID="RptEmails" runat="server" OnItemCommand="RptEmails_ItemCommand">
                <ItemTemplate>
                    <li>
                        <strong><%# Container.DataItem %></strong>
                        <asp:Button ID="BtnRemove" runat="server"
                            CommandName="Remove"
                            CommandArgument="<%# Container.DataItem %>"
                            Text="Remove"
                            CssClass="btn red sm"
                            OnClientClick="return confirm('Remove this recipient?');" />
                    </li>
                </ItemTemplate>
            </asp:Repeater>
        </ul>
        <asp:Panel ID="PnlNoEmails" runat="server" Visible="false">
            <div style="color:var(--danger);font-size:13px;padding:8px 0;">No email recipients configured. Add one below.</div>
        </asp:Panel>

        <div class="rcpt-add">
            <asp:TextBox ID="TxtNewEmail" runat="server" placeholder="Enter email address..." />
            <asp:Button ID="BtnAddEmail" runat="server" CssClass="btn green" Text="Add" OnClick="BtnAddEmail_Click" style="margin-top:0;" />
        </div>
    </div>

    <!-- REPORT AUTOMATION -->
    <div class="panel" id="sec-reports">
        <div class="ptitle">&#128197; Report Automation</div>
        <div class="psub">
            Configure the automated daily ENNX &amp; Excel report extraction and email dispatch.
            Settings saved to <code>config/report_automation.json</code>.
        </div>

        <div class="panel-sub">
            <div class="ptitle2">General Configuration</div>
            <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;">
                <asp:CheckBox ID="ChkEnabled" runat="server" />
                <label for="<%= ChkEnabled.ClientID %>" style="font-size:15px;font-weight:600;cursor:pointer;">Enable Automated Reporting</label>
            </div>
            <div style="color:var(--muted);font-size:12px;margin-bottom:14px;margin-left:26px;">If disabled, the task runner exits immediately without generating reports.</div>

            <div class="fg">
                <div class="fl">Scheduled Time<span>Informational — set in Task Scheduler</span></div>
                <asp:TextBox ID="TxtScheduleTime" runat="server" TextMode="Time" style="width:150px;" />
                <div class="fl">Report Subject Format<span>{Site} and {Date} tokens supported</span></div>
                <asp:TextBox ID="TxtSubject" runat="server" placeholder="e.g. Automated ENNX Report - {Site} - {Date}" />
            </div>
        </div>

        <div class="panel-sub">
            <div class="ptitle2">Excel Report Fields</div>
            <div style="font-size:12px;color:var(--muted);margin-bottom:10px;">Select which columns appear in the exported Excel report.</div>
            <div class="field-grid">
                <asp:CheckBoxList ID="CblFields" runat="server" RepeatColumns="3" RepeatLayout="Table">
                    <asp:ListItem Value="Name">Asset Barcode (Name)</asp:ListItem>
                    <asp:ListItem Value="Description">Description</asp:ListItem>
                    <asp:ListItem Value="EIL">CMR / EIL</asp:ListItem>
                    <asp:ListItem Value="Station_Number">Station Number</asp:ListItem>
                    <asp:ListItem Value="Sub_Station">Sub-Station</asp:ListItem>
                    <asp:ListItem Value="Locationname">Location Name</asp:ListItem>
                    <asp:ListItem Value="LocationTagged">Location Tagged</asp:ListItem>
                    <asp:ListItem Value="Previous_Location">Previous Location</asp:ListItem>
                    <asp:ListItem Value="Empl_ID">Employee ID</asp:ListItem>
                    <asp:ListItem Value="Tag_Date">Tag Date</asp:ListItem>
                    <asp:ListItem Value="Tag_Type">Tag Type</asp:ListItem>
                    <asp:ListItem Value="Last_Modified_By">Last Modified By</asp:ListItem>
                    <asp:ListItem Value="LastInventoried">Last Scan (UTC)</asp:ListItem>
                    <asp:ListItem Value="DisposalStatus">Disposal Status</asp:ListItem>
                    <asp:ListItem Value="Notes">Notes</asp:ListItem>
                </asp:CheckBoxList>
            </div>
        </div>

        <asp:Button ID="BtnSaveReportConfig" runat="server" CssClass="btn" Text="Save Report Settings" OnClick="BtnSaveReportConfig_Click" />
        <a href="va_automated_reports.aspx" class="btn green" style="margin-left:10px;">&#128227; Report Automation &amp; Triggers &rarr;</a>

        <div class="panel-sub" style="margin-top:20px;">
            <div class="ptitle2">Task Scheduler Script</div>
            <div style="font-size:12px;color:var(--muted);margin-bottom:10px;">
                Download this PowerShell script and schedule it in Windows Task Scheduler to trigger the nightly report run.
            </div>
            <div class="script-box"># AutoReportRunner.ps1
$url = "http://localhost/iDash/va_report_automator_runner.aspx"
$resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 300
Write-Host $resp.Content</div>
            <asp:Button ID="BtnDownloadScript" runat="server" CssClass="btn green" Text="&#128190; Download Task Script (.ps1)" OnClick="BtnDownloadScript_Click" style="margin-top:8px;" />
        </div>
    </div>

    <!-- NOTIFICATIONS -->
    <div class="panel" id="sec-alerts">
        <div class="ptitle">&#128276; Notifications &amp; Alerts</div>
        <div class="psub">Configure automated email notifications. Alerts use the SMTP settings from the Email section above.
            Notifications are delivered via email to recipients and as in-app alerts when users sign into iDash.</div>
        <div class="fg">
            <div class="fl">ENNX Report Enabled<span>Automated Equipment Not in Expected Location reports</span></div>
            <asp:DropDownList ID="DdlReportEnnx" runat="server">
                <asp:ListItem Value="true">Enabled</asp:ListItem>
                <asp:ListItem Value="false">Disabled</asp:ListItem>
            </asp:DropDownList>
            <div class="fl">ENNX Report Recipients<span>Email addresses, comma-separated</span></div>
            <asp:TextBox ID="TxtEnnxRecipients" runat="server" placeholder="user@va.gov, team@va.gov" />
            <hr class="sep" />
            <div style="font-size:13px; color:var(--muted); padding:12px 0 4px 0;"><strong>Planned Notification Types</strong> (coming soon)</div>
            <div style="font-size:12px; color:var(--muted); line-height:1.8; padding-left:4px;">
                &#128994; <strong>Asset Watch List</strong> &mdash; Notify when a watched asset is detected by a fixed reader<br/>
                &#128308; <strong>Service Health</strong> &mdash; Alert when RabbitMQ, Print Server, or IIS is down<br/>
                &#128992; <strong>Fixed Reader Offline</strong> &mdash; Alert when a reader stops reporting<br/>
                &#128994; <strong>Login Notifications</strong> &mdash; Show pending alerts as pop-ups when user signs into iDash
            </div>
        </div>
        <asp:Button ID="BtnSaveAlerts" runat="server" CssClass="btn" Text="Save Notification Settings" OnClick="BtnSaveAlerts_Click" />
        <a href="va_automated_reports.aspx" class="btn green" style="margin-left:10px;">&#128227; Advanced Automations &amp; Failure Triggers &rarr;</a>
    </div>

    <!-- ONE-TIME SQL -->
    <div class="panel" id="sec-sql" style="border-color:#10b981;">
        <div class="ptitle" style="color:#10b981;">&#9654; One-Time Company Setup SQL</div>
        <div class="psub">
            Creates the company record with the correct site name so all imported assets map correctly.
            Enter the 3-digit station number and the site's human-readable name, then click Execute.
            Safe to re-run &mdash; uses <code>IF NOT EXISTS</code>.
        </div>
        <div style="background:color-mix(in srgb, var(--accent), transparent 90%);border:1px solid var(--accent);border-radius:8px;padding:12px 16px;margin-bottom:16px;font-size:13px;">
            <strong style="color:var(--accent);">&#128161; What is a Station Number?</strong><br/>
            The 3-digit VA facility code assigned by the Veterans Health Administration. Examples:<br/>
            <code>512</code> = Baltimore &bull; <code>517</code> = Beckley &bull; <code>540</code> = Clarksburg &bull; <code>581</code> = Huntington &bull; <code>613</code> = Martinsburg &bull; <code>649</code> = Prescott &bull; <code>688</code> = Washington DC<br/>
            <span style="color:var(--muted);">Must be exactly 3 digits. The import pipeline (va_dbupdate.sql) matches companies using <code>SUBSTRING(name,1,3)</code>.</span>
        </div>
        <div class="fg">
            <div class="fl">Station Number<span>Exactly 3 digits (e.g. 649)</span></div>
            <asp:TextBox ID="TxtStationNum" runat="server" placeholder="e.g. 649" MaxLength="3" />
            <div class="fl">Site Name<span>City or facility name (e.g. San Diego)</span></div>
            <asp:TextBox ID="TxtSiteName" runat="server" placeholder="e.g. San Diego" />
        </div>
        <pre class="sql-preview" id="sqlPreview">-- Fill in station number and site name above to preview SQL --</pre>
        <asp:Button ID="BtnRunSql" runat="server" CssClass="btn green" Text="&#9654; Execute Company Setup SQL" OnClick="BtnRunSql_Click" />
        <asp:Literal ID="LitSqlResult" runat="server" />
    </div>

    <!-- SERVICE CONTROL -->
    <div class="panel" id="sec-services">
        <div class="ptitle">&#128260; Service Control</div>
        <div class="psub">
            Monitor and restart core platform services. Use <strong>Restart All</strong> to bring everything back up in the correct order
            (RabbitMQ first, then IIS, then Print Server). The Antenna Service auto-restarts on the next page request after IIS recycles.
        </div>
        <div style="margin-bottom:16px;">
            <button type="button" class="btn green" onclick="svcRefreshStatus()" style="margin-right:6px;">&#128260; Refresh Status</button>
            <button type="button" class="btn" onclick="svcRestartAll()" style="background:#ef4444;border-color:#ef4444;color:#fff;">&#9888; Restart All Services</button>
        </div>
        <div id="svcStatusGrid" style="display:grid; grid-template-columns:repeat(auto-fill, minmax(220px, 1fr)); gap:12px;">
            <div style="color:var(--muted); font-size:13px; padding:20px;">Click <strong>Refresh Status</strong> to load service states...</div>
        </div>
        <div id="svcLog" style="margin-top:16px; display:none; background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:14px; font-size:12px; font-family:monospace; max-height:300px; overflow-y:auto; white-space:pre-wrap;"></div>
    </div>

    <script>
    function svcApi(cmd, extra) {
        var url = 'va_site_config.aspx?api=svc&cmd=' + cmd;
        if (extra) url += '&' + extra;
        var method = (cmd === 'status') ? 'GET' : 'POST';
        return fetch(url, { method: method }).then(function(r) { return r.json(); });
    }

    function svcRefreshStatus() {
        var grid = document.getElementById('svcStatusGrid');
        grid.innerHTML = '<div style="color:var(--muted);font-size:13px;padding:20px;">Loading...</div>';
        svcApi('status').then(function(data) {
            if (data.error) { grid.innerHTML = '<div style="color:var(--danger);">Error: ' + data.error + '</div>'; return; }
            grid.innerHTML = '';
            (data.results || []).forEach(function(svc) {
                var isRunning = svc.status === 'Running';
                var color = isRunning ? '#10b981' : '#ef4444';
                var icon = isRunning ? '&#9679;' : '&#9675;';
                var card = document.createElement('div');
                card.style.cssText = 'background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px;border-left:4px solid ' + color;
                var uptimeStr = svc.uptime ? '<div style="font-size:11px;color:var(--muted);margin-top:4px;">Uptime: ' + svc.uptime + '</div>' : '';
                var errStr = svc.error ? '<div style="font-size:11px;color:#ef4444;margin-top:4px;">' + svc.error + '</div>' : '';
                var svcKey = svc.service === 'RabbitMQ' ? 'RabbitMQ' : svc.service === 'AssetWorxPrintServer' ? 'PrintServer' : svc.service === 'W3SVC' ? 'IIS' : svc.service === 'AntennaLocationService' ? 'Antenna' : '';
                var restartBtn = svcKey ? '<button type="button" onclick="svcRestartOne(\'' + svcKey + '\')" style="margin-top:8px;font-size:11px;padding:4px 10px;border-radius:6px;border:1px solid var(--line);background:var(--btn-alt);color:var(--text);cursor:pointer;">&#8635; Restart</button>' : '';
                card.innerHTML = '<div style="font-weight:600;font-size:13px;">' + icon + ' ' + svc.name + '</div>' +
                    '<div style="font-size:12px;color:' + color + ';font-weight:600;margin-top:4px;">' + svc.status + '</div>' +
                    uptimeStr + errStr + restartBtn;
                grid.appendChild(card);
            });
        }).catch(function(err) {
            grid.innerHTML = '<div style="color:var(--danger);">Fetch error: ' + err.message + '</div>';
        });
    }

    function svcLog(msg) {
        var log = document.getElementById('svcLog');
        log.style.display = 'block';
        var ts = new Date().toLocaleTimeString();
        log.textContent += '[' + ts + '] ' + msg + '\n';
        log.scrollTop = log.scrollHeight;
    }

    function svcRestartAll() {
        if (!confirm('Restart ALL services?\n\nThis will restart RabbitMQ, IIS, and Print Server.\nThe page will briefly disconnect during the IIS restart.\n\nContinue?')) return;
        document.getElementById('svcLog').textContent = '';
        svcLog('Starting full service restart...');
        svcLog('Order: RabbitMQ → IIS (W3SVC) → Print Server');
        svcLog('This may take 30-60 seconds...');
        svcApi('restartAll').then(function(data) {
            if (data.error) { svcLog('ERROR: ' + data.error); return; }
            (data.results || []).forEach(function(r) {
                svcLog(r.name + ': ' + (r.ok ? '✓ ' : '✗ ') + r.status + (r.error ? ' — ' + r.error : ''));
            });
            svcLog('Done. Refreshing status...');
            setTimeout(svcRefreshStatus, 2000);
        }).catch(function(err) {
            svcLog('Network error (expected during IIS restart): ' + err.message);
            svcLog('Retrying in 5 seconds...');
            setTimeout(function() {
                svcRefreshStatus();
                svcLog('Status refreshed.');
            }, 5000);
        });
    }

    function svcRestartOne(svcKey) {
        var names = {RabbitMQ:'RabbitMQ', PrintServer:'Print Server', IIS:'IIS (W3SVC)', Antenna:'Antenna Service'};
        if (!confirm('Restart ' + (names[svcKey]||svcKey) + '?')) return;
        document.getElementById('svcLog').textContent = '';
        svcLog('Restarting ' + (names[svcKey]||svcKey) + '...');
        svcApi('restart', 'svc=' + svcKey).then(function(data) {
            if (data.error) { svcLog('ERROR: ' + data.error); return; }
            (data.results || []).forEach(function(r) {
                svcLog(r.name + ': ' + (r.ok ? '✓ ' : '✗ ') + r.status + (r.error ? ' — ' + r.error : ''));
            });
            svcLog('Done.');
            setTimeout(svcRefreshStatus, 1000);
        }).catch(function(err) {
            svcLog('Network error: ' + err.message);
            if (svcKey === 'IIS') {
                svcLog('Expected during IIS restart. Retrying in 5s...');
                setTimeout(function() { svcRefreshStatus(); svcLog('Status refreshed.'); }, 5000);
            }
        });
    }
    </script>

    <!-- SCANNING PAGES COLUMN CONFIGURATION -->
    <div class="panel" id="sec-scan-columns">
        <div class="ptitle">&#128241; Mobile Scanning Page Column Visibility</div>
        <div class="psub">
            Customize which data columns appear on handheld scanning pages across this site (starting with <strong>VA Site Inventory</strong>).
            Hiding non-essential columns maximizes screen space on Zebra TC53 / Android mobile devices and eliminates horizontal scrolling.
        </div>

        <asp:Literal ID="LitColMsg" runat="server" />

        <div style="background:var(--chip); border:1px solid var(--line); border-radius:10px; padding:16px; margin-bottom:16px;">
            <div style="font-weight:700; font-size:13px; color:var(--text); margin-bottom:12px; display:flex; justify-content:space-between; align-items:center;">
                <span>VA Site Inventory (<code>va_inventory.aspx</code>)</span>
                <span style="font-size:11px; font-weight:600; color:var(--muted);">Global Handheld Configuration</span>
            </div>

            <table style="width:100%; border-collapse:collapse; font-size:12px;">
                <thead>
                    <tr style="border-bottom:2px solid var(--line); color:var(--muted); text-align:left;">
                        <th style="padding:8px 6px; width:50px; text-align:center;">Visible</th>
                        <th style="padding:8px 10px; width:200px;">Column Name</th>
                        <th style="padding:8px 10px; width:110px;">DB Field</th>
                        <th style="padding:8px 10px;">Description &amp; Mobile Recommendation</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- CORE SCANNING COLUMNS -->
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_0" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Print Checkbox</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">(system)</td>
                        <td style="padding:8px 10px; color:var(--muted);">Selection box to batch-print server tags. <span class="badge opt">Optional for sweeps</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line); background:rgba(16,185,129,0.04);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_1" runat="server" Checked="true" Enabled="false" /></td>
                        <td style="padding:8px 10px; font-weight:700; color:#10b981;">Status</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">(system)</td>
                        <td style="padding:8px 10px; color:var(--muted);">Found, Not Found, Move Here?, Unknown. <span class="badge req">Always Required</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line); background:rgba(16,185,129,0.04);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_2" runat="server" Checked="true" Enabled="false" /></td>
                        <td style="padding:8px 10px; font-weight:700; color:#10b981;">Asset Tag</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">name / rfidtag</td>
                        <td style="padding:8px 10px; color:var(--muted);">Primary barcode &amp; RFID tag identifier. <span class="badge req">Always Required</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_3" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Description</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">description</td>
                        <td style="padding:8px 10px; color:var(--muted);">Equipment description and item name. <span class="badge inf">Recommended</span></td>
                    </tr>

                    <!-- VA ASSET ATTRIBUTES: TEXT1 - TEXT20 -->
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_4" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Manufacturer</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text1</td>
                        <td style="padding:8px 10px; color:var(--muted);">Equipment manufacturer / vendor. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_5" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Model</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text2</td>
                        <td style="padding:8px 10px; color:var(--muted);">Equipment model identifier. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_6" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Serial #</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text3</td>
                        <td style="padding:8px 10px; color:var(--muted);">Manufacturer equipment serial number. <span class="badge inf">Recommended</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_7" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Equipment Category</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text4</td>
                        <td style="padding:8px 10px; color:var(--muted);">Equipment category / asset classification. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_8" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Service Pointer</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text5</td>
                        <td style="padding:8px 10px; color:var(--muted);">VA Service pointer code. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_9" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">SP + Location</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text6</td>
                        <td style="padding:8px 10px; color:var(--muted);">Official SP + Room location assigned in database. <span class="badge inf">Recommended</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_10" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Station Number</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text7</td>
                        <td style="padding:8px 10px; color:var(--muted);">VA medical center station / facility number. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_11" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">CMR / EIL</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text8</td>
                        <td style="padding:8px 10px; color:var(--muted);">CMR / Equipment Inventory Listing code (from file). <span class="badge inf">Recommended</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_12" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Purchase Order #</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text9</td>
                        <td style="padding:8px 10px; color:var(--muted);">Procurement purchase order number. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_13" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Physical Inventory Date (raw)</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text10</td>
                        <td style="padding:8px 10px; color:var(--muted);">Raw physical inventory date string from legacy feed. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_14" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">SP + Previous Location</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text11</td>
                        <td style="padding:8px 10px; color:var(--muted);">Previous room assignment before last relocation. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_15" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Entry Number</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text12</td>
                        <td style="padding:8px 10px; color:var(--muted);">VistA/AEMS entry sequence number. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_16" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Empl_ID</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text13</td>
                        <td style="padding:8px 10px; color:var(--muted);">Assigned custodian / employee ID. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_17" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Substation</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text14</td>
                        <td style="padding:8px 10px; color:var(--muted);">VA division / substation code. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_18" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Asset Value</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text15</td>
                        <td style="padding:8px 10px; color:var(--muted);">Acquisition or recorded replacement value ($). <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_19" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Location Tagged (Found)</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text16</td>
                        <td style="padding:8px 10px; color:var(--muted);">Room location where asset tag was originally commissioned. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_20" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Tagged On Date</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text17</td>
                        <td style="padding:8px 10px; color:var(--muted);">Commissioning date tag was applied to asset. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_21" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Tagged</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text18</td>
                        <td style="padding:8px 10px; color:var(--muted);">Physical tag attachment status flag. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_22" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Tag Type</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text19</td>
                        <td style="padding:8px 10px; color:var(--muted);">RFID tag hardware model classification (Alien, Confidex, etc). <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_23" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Notes</td>
                        <td style="padding:8px 10px; color:#0284c7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">text20</td>
                        <td style="padding:8px 10px; color:var(--muted);">Field technician notes and comments. <span class="badge opt">Optional</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_24" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Last Inventoried</td>
                        <td style="padding:8px 10px; color:#a855f7; font-family:Consolas,monospace; font-size:11px; font-weight:700;">lastinventoried</td>
                        <td style="padding:8px 10px; color:var(--muted);">Timestamp when asset was last observed in a physical inventory. <span class="badge opt">Optional</span></td>
                    </tr>

                    <!-- SCAN SESSION METADATA -->
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_25" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Scanned Loc</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">(session)</td>
                        <td style="padding:8px 10px; color:var(--muted);">Physical room currently being swept. <span class="badge opt">Off saves 120px width</span></td>
                    </tr>
                    <tr style="border-bottom:1px solid var(--line);">
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_26" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Reads</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">(session)</td>
                        <td style="padding:8px 10px; color:var(--muted);">Total RFID read count counter during sweep. <span class="badge inf">Recommended</span></td>
                    </tr>
                    <tr>
                        <td style="text-align:center; padding:8px 6px;"><asp:CheckBox ID="ChkCol_27" runat="server" /></td>
                        <td style="padding:8px 10px; font-weight:600;">Action (X)</td>
                        <td style="padding:8px 10px; color:var(--muted); font-family:Consolas,monospace; font-size:11px;">(session)</td>
                        <td style="padding:8px 10px; color:var(--muted);">Button to remove stray items from session. <span class="badge inf">Recommended</span></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <asp:Button ID="BtnSaveScanColumns" runat="server" CssClass="btn green" Text="&#10004; Save Column Configuration" OnClick="BtnSaveScanColumns_Click" />
    </div>

    <!-- CHECKLIST -->
    <div class="panel" id="sec-check">
        <div class="ptitle">&#9989; New Site Deployment Checklist</div>
        <div class="psub">Follow each step in order. This is designed for someone who has never set up an AssetWorx/iDash system before.</div>
        <ul class="checklist">
            <li><span>1&#65039;&#8419;</span><div><strong>Copy iDash files to new server</strong><br/>
                Copy the entire <code>iDash</code> folder to <code>C:\inetpub\wwwroot\AssetWorx.WebClient\iDash\</code> on the new server.
                Includes all <code>.aspx</code> pages, <code>.aspx.cs</code> code-behind files, and the <code>bin\</code> DLL folder.
                <br/><span style="font-size:11px;color:var(--muted);">SQL scripts (<code>va_dbupdate.sql</code>, <code>va_dbupdate_upsert_enrich.sql</code>) must be in the iDash root and <code>downloads\Scripts\</code>.</span><span class="badge req">Required</span></div></li>
            <li><span>2&#65039;&#8419;</span><div><strong>Configure Database connection</strong><br/>
                Fill in SQL Server instance (usually <code>.\sqlexpress</code>), database name (<code>AssetWorx</code>), username (<code>assetworxadmin</code>) and password.
                Click <strong>Save Database Settings</strong> then <strong>&#9889; Test Connection</strong> to verify.
                <br/><span style="font-size:11px;color:var(--muted);">If test fails: confirm SQL Server is running, the database exists, and credentials match SQL Server Management Studio.</span><span class="badge req">Required</span></div></li>
            <li><span>3&#65039;&#8419;</span><div><strong>Configure API / OAuth settings</strong><br/>
                Set <strong>Client ID</strong> to match this VISN (e.g. <code>visn5</code>). <strong>Client Secret</strong> comes from AssetWorx <code>appsettings.json</code> or the OAuth clients table.
                API Base URL is almost always <code>http://localhost/api</code>; Token URL is <code>http://localhost/connect/token</code>.
                <span class="badge req">Required</span></div></li>
            <li><span>4&#65039;&#8419;</span><div><strong>Execute One-Time Company / Site SQL</strong><br/>
                Enter the 3-digit VA station number and city name. This creates a row in <code>dbo.company</code> like <code>649 San Diego</code>.
                All asset imports use this name — if it doesn't exist, imports will fail to map assets to a site.
                <br/><span style="font-size:11px;color:var(--muted);">Safe to re-run. Skips the insert if station already exists.</span><span class="badge req">Required</span></div></li>
            <li><span>5&#65039;&#8419;</span><div><strong>Configure Fixed Reader / MQTT (if applicable)</strong><br/>
                Set the MQTT broker host/port and antenna service credentials in the <strong>Fixed Reader / MQTT</strong> section.
                Register your Zebra FX9600 readers and antenna locations in <strong>Fixed Reader Mgmt</strong> and verify with the <strong>&#9889; Test Antenna Service</strong> button.
                <br/><span style="font-size:11px;color:var(--muted);">Skip if no fixed RFID readers are deployed at this site.</span><span class="badge opt">Optional</span></div></li>
            <li><span>6&#65039;&#8419;</span><div><strong>Configure MQTT / Print Clients (if printing)</strong><br/>
                Open <strong>MQTT / Print Clients</strong> to set broker connection and per-site print client credentials.
                Open <strong>Printer Administration</strong> to register templates, and set up <strong>Printer Routing</strong> to map BarTender <code>.btw</code> files to Windows printer queues.
                <br/><span style="font-size:11px;color:var(--muted);">Skip if label printing is not used at this site.</span><span class="badge opt">Optional</span></div></li>
            <li><span>7&#65039;&#8419;</span><div><strong>Configure Email / SMTP and add recipients</strong><br/>
                Each VISN site needs its own email sending account. Typical: <code>smtp.office365.com</code>, port <code>587</code>.
                Set the From address and From Name (e.g. "iDash VISN 5 Reports"), then add recipient addresses in the <strong>Recipients</strong> section.
                <span class="badge req">Required</span></div></li>
            <li><span>8&#65039;&#8419;</span><div><strong>Create scanner user accounts</strong><br/>
                Open <a href="va_aw_user_management.aspx" style="color:var(--accent);font-weight:600;">&#128100; AssetWorx User Management</a> to create login accounts for RFID scanner operators.
                Each operator needs a username, password, user type, and site assignment.
                <br/><span style="font-size:11px;color:var(--muted);">Default accounts: <code>admin</code> / <code>superadmin</code> (password: <code>demo</code>). Change these after setup.</span><span class="badge req">Required</span></div></li>
            <li><span>9&#65039;&#8419;</span><div><strong>Run the two-pass data import</strong><br/>
                Open <a href="va_dbupdate.aspx" style="color:var(--accent);font-weight:600;">Manual DB Update</a>.<br/>
                <strong>Step A:</strong> Upload the VA data file (tab-delimited CDW/VistA export).<br/>
                <strong>Step B:</strong> Run the <strong>Enrichment script</strong> (<code>va_dbupdate_upsert_enrich.sql</code>) — inserts new assets and fills blank fields.<br/>
                <strong>Step C:</strong> Run the <strong>Standard script</strong> (<code>va_dbupdate.sql</code>) — full MERGE upsert.
                <br/><span style="font-size:11px;color:var(--muted);">See <a href="documentation/va_dbupdate.html" style="color:var(--accent);">DB Update documentation</a> for the full field mapping guide.</span><span class="badge req">Required</span></div></li>
            <li><span>10&#65039;&#8419;</span><div><strong>Configure Report Automation</strong><br/>
                Enable automated reporting, set the schedule, subject, and Excel fields in the <strong>Report Automation</strong> section.
                Download the PowerShell script and schedule it in Windows Task Scheduler for nightly runs.<span class="badge opt">Optional</span></div></li>
            <li><span>11&#65039;&#8419;</span><div><strong>Configure Notifications &amp; Alerts</strong><br/>
                In the <strong>Notifications</strong> section, enable ENNX report automation and add email recipients.
                Notifications use the SMTP settings configured in step 7. Watch list and service health alerts are configured per-user from the iDash Hub.
                <span class="badge opt">Optional</span></div></li>
            <li><span>&#128313;</span><div><strong>Verify connection in iDash Hub</strong><br/>
                Open <a href="index.aspx" style="color:var(--accent);font-weight:600;">iDash Hub</a> &mdash; the status bar should show
                <strong style="color:#10b981;">&#9679; CONNECTED</strong> and this server's machine name. Confirm tiles load and the asset overview shows data.
                <span class="badge inf">Verify</span></div></li>
        </ul>
    </div>

    <div style="text-align:center;color:var(--muted);font-size:12px;margin-top:10px;padding-bottom:40px;">
        VA Asset Intelligence Hub &mdash; Site Configuration &copy; 2026
    </div>
    <idash:Footer runat="server" />
</main>
</div>
</form>
<script>
(function(){
    var stn=document.getElementById('<%= TxtStationNum.ClientID %>');
    var nm=document.getElementById('<%= TxtSiteName.ClientID %>');
    var pre=document.getElementById('sqlPreview');
    function upd(){
        var s=stn.value.trim()||'NNN', n=nm.value.trim()||'Site Name';
        pre.textContent='-- Parameterized SQL (values are passed as @parameters, not concatenated)\nIF NOT EXISTS (SELECT 1 FROM dbo.company WHERE SUBSTRING(name,1,3) = @station)\n    INSERT INTO dbo.company (name) VALUES (@companyName);\n\n-- @station     = \'' + s + '\'\n-- @companyName = \'' + s + ' ' + n + '\'';
    }
    if(stn){stn.addEventListener('input',upd);nm.addEventListener('input',upd);upd();}
})();
</script>
</body>
</html>

