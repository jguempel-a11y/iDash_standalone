<#
.SYNOPSIS
    Locally installs an iDash license key on the current cart or server.

.EXAMPLE
    .\Apply-IdashLicense.ps1 -LicenseKey "IDASH-LIC-v1-ey..."
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$LicenseKey,
    [string]$AppDir = ""
)

if ([string]::IsNullOrEmpty($AppDir)) {
    $AppDir = Join-Path $PSScriptRoot ".."
    if (!(Test-Path $AppDir)) {
        $AppDir = "C:\inetpub\wwwroot\iDash"
    }
}

$LicenseKey = $LicenseKey.Trim()
if (!$LicenseKey.StartsWith("IDASH-LIC-v1-")) {
    Write-Error "Invalid key format. Must start with IDASH-LIC-v1-"
    return
}

$b64Env = $LicenseKey.Substring(13)
$envJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64Env))
$envelope = $envJson | ConvertFrom-Json

$payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($envelope.Payload))
$payload = $payloadJson | ConvertFrom-Json

$appData = Join-Path $AppDir "App_Data"
if (!(Test-Path $appData)) { New-Item -ItemType Directory -Path $appData -Force | Out-Null }

$storageObj = [PSCustomObject]@{
    AppliedUtc = (Get-Date).ToUniversalTime().ToString("o")
    RawKey     = $LicenseKey
    Payload    = $payload
}

$outJson = $storageObj | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $appData "idash_license.json") -Value $outJson -Force -Encoding UTF8

Write-Host "Successfully installed iDash license to $appData\idash_license.json" -ForegroundColor Green
Write-Host "Customer:       $($payload.Customer)"
Write-Host "Site:           $($payload.SiteName) ($($payload.StationNumber))"
Write-Host "Hardware ID:    $($payload.HardwareId)"
Write-Host "Type:           $($payload.LicenseType)"
Write-Host "Expiration:     $(if ($payload.ExpirationDate) { $payload.ExpirationDate } else { 'None (Perpetual)' })"
