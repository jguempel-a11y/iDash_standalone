<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_alerts.aspx.cs" Inherits="va_alerts" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <title>Alerts &amp; Notifications Hub &mdash; iDash</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
        body {
            margin: 0;
            padding: 0;
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            min-height: 100vh;
        }
        .wrap {
            max-width: 960px;
            margin: 40px auto;
            padding: 0 24px;
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--line);
            flex-wrap: wrap;
            gap: 16px;
        }
        .header-title h1 {
            margin: 0 0 6px;
            font-size: 26px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            color: var(--text);
        }
        .header-title p {
            margin: 0;
            font-size: 13px;
            color: var(--muted);
        }
        .nav-back {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            color: var(--text);
            background: var(--card);
            border: 1px solid var(--line);
            transition: all 0.15s ease;
        }
        .nav-back:hover {
            border-color: var(--accent);
            color: var(--accent);
        }
        .hub-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
            margin-bottom: 30px;
        }
        @media (max-width: 768px) {
            .hub-grid { grid-template-columns: 1fr; }
        }
        .hub-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 26px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
            transition: transform 0.2s, border-color 0.2s;
        }
        .hub-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 6px 18px rgba(0,0,0,0.08);
        }
        .card-icon {
            font-size: 32px;
            margin-bottom: 12px;
        }
        .card-title {
            font-size: 18px;
            font-weight: 700;
            margin: 0 0 8px;
        }
        .card-desc {
            font-size: 13px;
            color: var(--muted);
            line-height: 1.6;
            margin-bottom: 20px;
            flex: 1;
        }
        .card-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 18px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            transition: filter 0.15s;
        }
        .btn-blue {
            background: #3b82f6;
            color: #fff !important;
        }
        .btn-green {
            background: #10b981;
            color: #fff !important;
        }
        .card-btn:hover {
            filter: brightness(1.1);
        }
        .note-box {
            background: var(--card);
            border: 1px solid var(--line);
            border-left: 4px solid var(--accent);
            border-radius: 0 10px 10px 0;
            padding: 16px 20px;
            font-size: 13px;
            color: var(--muted);
            line-height: 1.6;
        }
        .note-box strong {
            color: var(--text);
        }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="header">
            <div class="header-title">
                <h1>&#128276; Alerts &amp; Notifications Hub</h1>
                <p>Centralized gateway for iDash operational notifications and administrative failure alerts.</p>
            </div>
            <div>
                <a href="index.aspx" class="nav-back">&#8962; Back to Hub</a>
                <a href="documentation/va_sms_alerting.html" class="nav-back" style="margin-left:6px;">&#128214; Docs</a>
            </div>
        </div>

        <div class="hub-grid">
            <!-- CARD 1: IN-APP OPERATIONAL NOTIFICATIONS -->
            <div class="hub-card" style="border-top: 4px solid #3b82f6;">
                <div>
                    <div class="card-icon">&#128276;</div>
                    <div class="card-title" style="color:#3b82f6;">Operational Alerts &amp; Watch Lists</div>
                    <div class="card-desc">
                        Live monitoring dashboard for biomedical engineering and logistics staff.
                        <ul style="padding-left:20px; margin: 10px 0 0; line-height: 1.7;">
                            <li><strong>Asset Watch Lists:</strong> Pin high-priority EE tags and monitor sweep detections.</li>
                            <li><strong>Location Mismatches:</strong> Live pulsing alerts when an asset is swept in the wrong room.</li>
                            <li><strong>Inactive Tags:</strong> Identify equipment not seen in 30+ days.</li>
                        </ul>
                    </div>
                </div>
                <a href="va_notifications.aspx" class="card-btn btn-blue">&#9654; Open Notifications Hub</a>
            </div>

            <!-- CARD 2: SYSTEM AUTOMATIONS & EVENT TRIGGERS -->
            <div class="hub-card" style="border-top: 4px solid #10b981;">
                <div>
                    <div class="card-icon">&#9881;&#65039;</div>
                    <div class="card-title" style="color:#10b981;">System Automations &amp; Event Triggers</div>
                    <div class="card-desc">
                        Administrative alert dispatching and failure notifications for system engineers.
                        <ul style="padding-left:20px; margin: 10px 0 0; line-height: 1.7;">
                            <li><strong>Automated Failure Triggers:</strong> Catch SQL crashes, missing \autoload folders, and print API drops.</li>
                            <li><strong>Global Master Switch:</strong> Instant kill-switch to silence alerts during maintenance.</li>
                            <li><strong>VA SMTP Relay:</strong> Secure internal email delivery (no carrier SMS gateway).</li>
                        </ul>
                    </div>
                </div>
                <a href="va_automated_reports.aspx" class="card-btn btn-green">&#9654; Configure Automations</a>
            </div>
        </div>

        <div class="note-box">
            <strong>&#128161; Looking for SMS text messaging?</strong><br />
            Public cellular SMS gateways (e.g. <code>@vtext.com</code>) have been officially decommissioned in favor of authenticated internal VA SMTP relays and in-app visual alerts.
            For technical details and security architecture, see the <a href="documentation/va_sms_alerting.html" style="color:var(--accent); font-weight:600;">iDash Alerts &amp; System Automations Guide</a>.
        </div>
    </div>
</body>
</html>
