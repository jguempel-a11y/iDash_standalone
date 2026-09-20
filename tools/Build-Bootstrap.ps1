$zip = 'C:\inetpub\wwwroot\iDash\downloads\system_update_bootstrap.zip'
$temp = 'C:\inetpub\wwwroot\iDash\scratch\bootstrap_stage'
if (Test-Path $zip) { Remove-Item $zip -Force }
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item -ItemType Directory -Path $temp | Out-Null
Copy-Item 'C:\inetpub\wwwroot\iDash\va_system_update.aspx' $temp
Copy-Item 'C:\inetpub\wwwroot\iDash\va_system_update.aspx.cs' $temp
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp, $zip)
Remove-Item $temp -Recurse -Force
$len = (Get-Item $zip).Length
Write-Host "Bootstrap ZIP created: $zip ($len bytes)"
