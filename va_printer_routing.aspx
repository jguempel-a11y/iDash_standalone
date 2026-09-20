<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_printer_routing.aspx.cs" Inherits="va_printer_routing" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <title>Master Printer Routing Manager &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        body { font-family: 'Segoe UI', system-ui, Arial, sans-serif; background: var(--bg); color: var(--text); line-height: 1.5; padding: 40px; margin: 0; }
        .container { max-width: 800px; margin: 0 auto; background: var(--card); padding: 30px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border: 1px solid var(--line); }
        h1 { color: var(--accent); font-size: 28px; margin-bottom: 5px; }
        p.subtitle { color: var(--muted); margin-bottom: 25px; }
        .code-box { width: 100%; height: 350px; background: var(--chip); color: var(--text); font-family: 'Courier New', monospace; font-size: 14px; padding: 15px; border: 1px solid var(--line); border-radius: 8px; resize: vertical; box-sizing: border-box; }
        .btn { display: inline-block; padding: 12px 24px; background: var(--accent-2); color: #fff; border: none; border-radius: 6px; font-size: 16px; font-weight: bold; cursor: pointer; transition: 0.2s ease; margin-top: 20px; }
        .btn:hover { opacity: 0.85; }
        .alert { padding: 15px; border-radius: 6px; margin-top: 20px; font-weight: bold; display: none; }
        .alert.success { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--accent-2); border: 1px solid var(--accent-2); display: block; }
        .alert.error { background: color-mix(in srgb, var(--danger), transparent 85%); color: var(--danger); border: 1px solid var(--danger); display: block; }
        .nav-row { display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; }
        .nav-btn { display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; border-radius: 8px; text-decoration: none; font-size: 13px; font-weight: 600; border: 1px solid var(--line); color: var(--accent); background: transparent; transition: background .15s, border-color .15s; }
        .nav-btn:hover { border-color: var(--accent); background: color-mix(in srgb, var(--accent), transparent 90%); }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <div class="nav-row">
                <a href="va_site_config.aspx" class="nav-btn" title="Site Configuration">&#9881; Site Config</a>
                <a href="index.aspx" class="nav-btn">&#8962; Hub</a>
                <a href="va_print_mapping.aspx" class="nav-btn">&#128424; Template Mapping Config</a>
                <a href="va_print_admin.aspx" class="nav-btn">&#9881; Print Administration</a>
            </div>
            <h1>Master Printer Routing File</h1>
            <p class="subtitle">Edit the native JSON mapping file to dynamically route your BarTender templates to specific hardware printer ports on the fly.</p>
            
            <p style="font-size:13px; color:var(--muted);">Rule: Enter your <b>exact .btw File Name</b> on the left, and your <b>exact Windows Printer Name</b> on the right.</p>

            <asp:TextBox ID="TxtJson" runat="server" TextMode="MultiLine" CssClass="code-box"></asp:TextBox>
            <asp:Button ID="BtnSave" runat="server" Text="Save Configuration" OnClick="BtnSave_Click" CssClass="btn" />

            <asp:Literal ID="LitMessage" runat="server"></asp:Literal>
        </div>
    </form>
</body>
</html>
