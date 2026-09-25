<%@ Page Language="C#" AutoEventWireup="true" Title="iDash License and Setup" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>iDash License and Setup</title>
    <style>
        body { background-color: #f4f6f9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; padding: 25px 15px; margin: 0; }
        .container { max-width: 960px; margin: 0 auto; }
        .card { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); margin-bottom: 25px; }
        .card-header { padding: 15px 20px; font-weight: 600; font-size: 1.15rem; border-bottom: 1px solid #e2e8f0; }
        .card-header.cart1 { background: #ebf8ff; color: #2b6cb0; }
        .card-header.cart2 { background: #f0fff4; color: #276749; }
        .card-header.trouble { background: #fffaf0; color: #9c4221; }
        .card-body { padding: 20px; }
        pre { background: #1a202c; color: #e2e8f0; padding: 15px; border-radius: 6px; font-size: 0.85rem; word-break: break-all; white-space: pre-wrap; margin-bottom: 15px; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 0.85rem; font-weight: 600; }
        .badge-info { background: #bee3f8; color: #2b6cb0; }
        .badge-success { background: #c6f6d5; color: #22543d; }
        .copy-btn { margin-bottom: 10px; }
        .d-flex { display: flex; }
        .justify-content-between { justify-content: space-between; }
        .align-items-center { align-items: center; }
        .mb-4 { margin-bottom: 1.5rem; }
        .mt-3 { margin-top: 1rem; }
        .mt-4 { margin-top: 1.5rem; }
        .text-dark { color: #1a202c; }
        .font-weight-bold { font-weight: 700; }
    </style>
</head>
<body>
    <div class="container">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
            <a href="index.aspx" style="text-decoration:none; color:#4a5568; font-weight:600; font-size:0.9rem;">&larr; Back to iDash Hub</a>
            <a href="va_license_manager.aspx#sec-carts" style="background:#3182ce; color:#fff; padding:6px 14px; border-radius:6px; text-decoration:none; font-weight:600; font-size:0.85rem;">Open in Unified License Manager &rarr;</a>
        </div>
        <div class="alert alert-info" style="background:#ebf8ff; border:1px solid #bee3f8; color:#2b6cb0; padding:12px 16px; border-radius:6px; margin-bottom:20px; font-size:0.9rem;">
            ℹ️ <strong>Integrated:</strong> This cart reference has been merged into the central <a href="va_license_manager.aspx#sec-carts" style="color:#2b6cb0; font-weight:700; text-decoration:underline;">License Manager</a> tab for easier access.
        </div>
        <h2 class="mb-4 text-dark font-weight-bold">iDash License and Setup</h2>
        
        <!-- Cart 1 Card -->
        <div class="card">
            <div class="card-header cart1 d-flex justify-content-between align-items-center">
                <span>Beckley Cart 1</span>
                <span class="badge badge-info">MAC: 04:64:FA:FE:7F:A8</span>
            </div>
            <div class="card-body">
                <h6><strong>Validated License Key:</strong></h6>
                <pre id="cart1Key">ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fFx1MjAyQTA0NjRGQUZFN0ZBOCIsDQogICJTaWduYXR1cmUiOiAiSFpPY3F6NjZpQUwvYnNEQjBBejBRR3dVZGg1VnNwNG9FQ1JJVVVXZXNmb3p3TkMxTENmQXVlVTZxVG5MczB5NkZuT3pqdEZBbUhCR0J1ek1wc0FxSy9KMXVqSFAycVdcdTAwMkJyRXJFVnhmTFx1MDAyQmJ1TmpsNmFxekdHWmFnVW5xdFJOQjNcdTAwMkJCUmNiMk82cTJIaElES1ZBYkJ1WHJuRThtczMyOXpSbUFvekxVTk9uUUtjPSINCn0=</pre>
                
                <h6 class="mt-3"><strong>Apply via PowerShell (Administrator):</strong></h6>
                <pre>$lic = "ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fFx1MjAyQTA0NjRGQUZFN0ZBOCIsDQogICJTaWduYXR1cmUiOiAiSFpPY3F6NjZpQUwvYnNEQjBBejBRR3dVZGg1VnNwNG9FQ1JJVVVXZXNmb3p3TkMxTENmQXVlVTZxVG5MczB5NkZuT3pqdEZBbUhCR0J1ek1wc0FxSy9KMXVqSFAycVdcdTAwMkJyRXJFVnhmTFx1MDAyQmJ1TmpsNmFxekdHWmFnVW5xdFJOQjNcdTAwMkJCUmNiMk82cTJIaElES1ZBYkJ1WHJuRThtczMyOXpSbUFvekxVTk9uUUtjPSINCn0="

$conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\sqlexpress;Database=assetworx;User Id=assetworxadmin;Password=assetworxadmin;")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "UPDATE applicationsetting SET licensekey = @lic"
$cmd.Parameters.AddWithValue("@lic", $lic) | Out-Null
$cmd.ExecuteNonQuery() | Out-Null
$conn.Close()

iisreset</pre>
            </div>
        </div>

        <!-- Cart 2 Card -->
        <div class="card">
            <div class="card-header cart2 d-flex justify-content-between align-items-center">
                <span>Beckley Cart 2</span>
                <span class="badge badge-success">MAC: 04:64:FA:FE:80:C6</span>
            </div>
            <div class="card-body">
                <h6><strong>Validated License Key:</strong></h6>
                <pre id="cart2Key">ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fCBcdTIwMkEwNDY0RkFGRTgwQzYiLA0KICAiU2lnbmF0dXJlIjogIkliV0x1cXlmRVQ2ZTNRcWxOMlpBYWVYYkdYc0Jkalx1MDAyQjY1aDd1QlhjVE95d1dpSFVNRnpJRUJ5MzdIN1Q1ZHBETm5VaWhnN3pCUDdhWEJua2xsZXFDcTdmXHUwMDJCZFJnWm5RL0VkVVVZS3p5L1hSZHo4Tk1JYnI1aFJCeG9NQXp4QzNtWXFudG53M1RwQkxKWEtZdXY3djBNbGNtZjQ3NGdMWjBXVm5adkVnRk1TRnM9Ig0KfQ==</pre>
                
                <h6 class="mt-3"><strong>Apply via PowerShell (Administrator):</strong></h6>
                <pre>$lic = "ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fCBcdTIwMkEwNDY0RkFGRTgwQzYiLA0KICAiU2lnbmF0dXJlIjogIkliV0x1cXlmRVQ2ZTNRcWxOMlpBYWVYYkdYc0Jkalx1MDAyQjY1aDd1QlhjVE95d1dpSFVNRnpJRUJ5MzdIN1Q1ZHBETm5VaWhnN3pCUDdhWEJua2xsZXFDcTdmXHUwMDJCZFJnWm5RL0VkVVVZS3p5L1hSZHo4Tk1JYnI1aFJCeG9NQXp4QzNtWXFudG53M1RwQkxKWEtZdXY3djBNbGNtZjQ3NGdMWjBXVm5adkVnRk1TRnM9Ig0KfQ=="

$conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\sqlexpress;Database=assetworx;User Id=assetworxadmin;Password=assetworxadmin;")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "UPDATE applicationsetting SET licensekey = @lic"
$cmd.Parameters.AddWithValue("@lic", $lic) | Out-Null
$cmd.ExecuteNonQuery() | Out-Null
$conn.Close()

iisreset</pre>
            </div>
        </div>

        <!-- Troubleshooting Reference -->
        <div class="card">
            <div class="card-header trouble">
                Troubleshooting Checklist for Cart 1 Setup
            </div>
            <div class="card-body">
                <h6><strong>1. Blank Screen / HTTP 500 After Login:</strong></h6>
                <p>Check <code>C:\inetpub\wwwroot\AssetWorx.WebClient\appsettings.json</code>. Ensure:</p>
                <pre>"AuthServerUrl": "http://localhost"</pre>
                <p>If it points to <code>http://BECKLEYCART1</code> or another machine name, internal API calls fail with socket timeouts (IDX20803).</p>
                
                <h6 class="mt-4"><strong>2. Invisible Unicode U+202A in License Keys:</strong></h6>
                <p>Windows adapter copy inserts invisible character <code>\u202A</code> right before the MAC address. Copy-pasting without unicode escaping causes signature check failure. Use the exact base64 strings above.</p>
            </div>
        </div>
    </div>
</body>
</html>
