# AssetWorx Cart 1 & Cart 2 Configuration & License Reference

This guide documents the setup instructions, fixes, and validated license keys for **Beckley Cart 1** and **Beckley Cart 2**.

---

## 1. Beckley Cart 1 License & Setup

### Specifications
- **Machine Name:** `BECKLEYCART1`
- **Ethernet MAC:** `04:64:FA:FE:7F:A8`
- **Company Name:** `Beckley Cart 1`
- **Seats / Tenants / Readers:** `-1` (Unlimited) / `5` / `15`

### Validated Base64 License Key (Cart 1)
```text
ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fFx1MjAyQTA0NjRGQUZFN0ZBOCIsDQogICJTaWduYXR1cmUiOiAiSFpPY3F6NjZpQUwvYnNEQjBBejBRR3dVZGg1VnNwNG9FQ1JJVVVXZXNmb3p3TkMxTENmQXVlVTZxVG5MczB5NkZuT3pqdEZBbUhCR0J1ek1wc0FxSy9KMXVqSFAycVdcdTAwMkJyRXJFVnhmTFx1MDAyQmJ1TmpsNmFxekdHWmFnVW5xdFJOQjNcdTAwMkJCUmNiMk82cTJIaElES1ZBYkJ1WHJuRThtczMyOXpSbUFvekxVTk9uUUtjPSINCn0=
```

### Applying License on Cart 1 via PowerShell (Run as Administrator):
```powershell
$lic = "ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fFx1MjAyQTA0NjRGQUZFN0ZBOCIsDQogICJTaWduYXR1cmUiOiAiSFpPY3F6NjZpQUwvYnNEQjBBejBRR3dVZGg1VnNwNG9FQ1JJVVVXZXNmb3p3TkMxTENmQXVlVTZxVG5MczB5NkZuT3pqdEZBbUhCR0J1ek1wc0FxSy9KMXVqSFAycVdcdTAwMkJyRXJFVnhmTFx1MDAyQmJ1TmpsNmFxekdHWmFnVW5xdFJOQjNcdTAwMkJCUmNiMk82cTJIaElES1ZBYkJ1WHJuRThtczMyOXpSbUFvekxVTk9uUUtjPSINCn0="

$conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\sqlexpress;Database=assetworx;User Id=assetworxadmin;Password=assetworxadmin;")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "UPDATE applicationsetting SET licensekey = @lic"
$cmd.Parameters.AddWithValue("@lic", $lic) | Out-Null
$cmd.ExecuteNonQuery() | Out-Null
$conn.Close()

iisreset
```

---

## 2. Beckley Cart 2 License & Setup

### Specifications
- **Machine Name:** `BECKLEYCART2`
- **Ethernet MAC:** `04:64:FA:FE:80:C6`
- **Company Name:** `Beckley Cart 1` *(as issued by vendor)*
- **Seats / Tenants / Readers:** `-1` (Unlimited) / `5` / `15`

### Validated Base64 License Key (Cart 2)
```text
ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fCBcdTIwMkEwNDY0RkFGRTgwQzYiLA0KICAiU2lnbmF0dXJlIjogIkliV0x1cXlmRVQ2ZTNRcWxOMlpBYWVYYkdYc0Jkalx1MDAyQjY1aDd1QlhjVE95d1dpSFVNRnpJRUJ5MzdIN1Q1ZHBETm5VaWhnN3pCUDdhWEJua2xsZXFDcTdmXHUwMDJCZFJnWm5RL0VkVVVZS3p5L1hSZHo4Tk1JYnI1aFJCeG9NQXp4QzNtWXFudG53M1RwQkxKWEtZdXY3djBNbGNtZjQ3NGdMWjBXVm5adkVnRk1TRnM9Ig0KfQ==
```

### Applying License on Cart 2 via PowerShell (Run as Administrator):
```powershell
$lic = "ew0KICAiTGljZW5zZUtleSI6ICJCZWNrbGV5IENhcnQgMXwtMXw1fDE1fCBcdTIwMkEwNDY0RkFGRTgwQzYiLA0KICAiU2lnbmF0dXJlIjogIkliV0x1cXlmRVQ2ZTNRcWxOMlpBYWVYYkdYc0Jkalx1MDAyQjY1aDd1QlhjVE95d1dpSFVNRnpJRUJ5MzdIN1Q1ZHBETm5VaWhnN3pCUDdhWEJua2xsZXFDcTdmXHUwMDJCZFJnWm5RL0VkVVVZS3p5L1hSZHo4Tk1JYnI1aFJCeG9NQXp4QzNtWXFudG53M1RwQkxKWEtZdXY3djBNbGNtZjQ3NGdMWjBXVm5adkVnRk1TRnM9Ig0KfQ=="

$conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\sqlexpress;Database=assetworx;User Id=assetworxadmin;Password=assetworxadmin;")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "UPDATE applicationsetting SET licensekey = @lic"
$cmd.Parameters.AddWithValue("@lic", $lic) | Out-Null
$cmd.ExecuteNonQuery() | Out-Null
$conn.Close()

iisreset
```

---

## 3. Important Setup Troubleshooting Notes

### A. Blank White Page / HTTP 500 on Authentication (`AuthServerUrl`)
- **Symptom:** You can sign in, but the page stays completely blank / white. In `C:\Logs\WebClient_log*.txt`, you see:
  `IDX20803: Unable to obtain configuration from: 'http://<MACHINENAME>/.well-known/openid-configuration'`
  followed by a socket timeout (`10060`).
- **Root Cause:** In cloned or copied installations, `appsettings.json` points `AuthServerUrl` to the old machine name (e.g. `http://BECKLEYCART1`). The .NET authentication handler attempts to make an internal HTTP call across the network instead of locally.
- **Fix:** In `C:\inetpub\wwwroot\AssetWorx.WebClient\appsettings.json`, ensure:
  ```json
  "AuthServerUrl": "http://localhost"
  ```
  Then run `iisreset`.

### B. "Bad License Key" / License Rejection
- **Root Cause:** When copying MAC addresses from Windows Network Adapter details, Windows silently injects an invisible Unicode character `U+202A` (Left-to-Right Embedding). If copied and pasted through terminal/chat/email, it becomes a literal `?` which breaks the RSA digital signature.
- **Fix:** Use the clean, pre-validated Base64 keys provided above. They preserve the exact signature and byte formatting expected by the runtime.
