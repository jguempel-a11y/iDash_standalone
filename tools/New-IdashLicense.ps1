<#
.SYNOPSIS
    Generates a cryptographically signed iDash local license key.

.DESCRIPTION
    Uses an RSA-2048 private key to sign a license payload containing facility metadata,
    hardware binding (MAC or Installation ID), feature flags, and expiration terms.

.EXAMPLE
    .\New-IdashLicense.ps1 -SiteName "517 Beckley VAMC" -StationNumber "517" -HardwareId "0464FAFE7FA8" -LicenseType Perpetual
#>

[CmdletBinding()]
param (
    [string]$Customer = "Veterans Health Administration",
    [string]$SiteName = "517 Beckley VAMC",
    [string]$StationNumber = "517",
    [Alias("InstallationId")]
    [string]$HardwareId = "*",
    [ValidateSet("Perpetual", "Annual", "Trial")]
    [string]$LicenseType = "Perpetual",
    [switch]$Perpetual,
    [string]$ExpirationDate = $null,
    [string[]]$Features = @(
        "hub_core",
        "cart_sync_hub",
        "license_manager",
        "user_management",
        "db_workbench",
        "auto_db_watcher",
        "field_server_sync",
        "system_update",
        "diagnostics"
    ),
    [string]$PrivateKeyPath = "",
    [Alias("OutputFile", "Path")]
    [string]$OutFile = $null
)

if ($Perpetual) {
    $LicenseType = "Perpetual"
    $ExpirationDate = $null
}

if ([string]::IsNullOrEmpty($PrivateKeyPath)) {
    $PrivateKeyPath = Join-Path $PSScriptRoot "idash_keys\idash_private_key.xml"
    if (!(Test-Path $PrivateKeyPath)) {
        $PrivateKeyPath = "C:\inetpub\wwwroot\iDash\tools\idash_keys\idash_private_key.xml"
    }
}

if (!(Test-Path $PrivateKeyPath)) {
    Write-Error "Private key not found at: $PrivateKeyPath"
    return
}

$privXml = Get-Content -Path $PrivateKeyPath -Raw
$cleanHw = $HardwareId.ToUpper().Replace(":", "").Replace("-", "").Trim()

$licenseId = "IDASH-LIC-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + (Get-Random -Minimum 1000 -Maximum 9999)
$issuedDate = (Get-Date).ToString("yyyy-MM-dd")

$payloadObj = [PSCustomObject]@{
    LicenseId      = $licenseId
    Customer       = $Customer
    SiteName       = $SiteName
    StationNumber  = $StationNumber
    HardwareId     = $cleanHw
    LicenseType    = $LicenseType
    IssuedDate     = $issuedDate
    ExpirationDate = $ExpirationDate
    Features       = $Features
}

$jsonPayload = $payloadObj | ConvertTo-Json -Compress
$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)

$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider(2048)
$rsa.FromXmlString($privXml)
$signatureBytes = $rsa.SignData($payloadBytes, [System.Security.Cryptography.CryptoConfig]::MapNameToOID('SHA256'))

$envelope = [PSCustomObject]@{
    Version   = 1
    Algorithm = "RSA2048-SHA256"
    Payload   = [Convert]::ToBase64String($payloadBytes)
    Signature = [Convert]::ToBase64String($signatureBytes)
}

$envelopeJson = $envelope | ConvertTo-Json -Compress
$keyString = "IDASH-LIC-v1-" + [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($envelopeJson))

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   iDash Cryptographic License Key Generated" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Customer:       $Customer"
Write-Host "Site:           $SiteName ($StationNumber)"
Write-Host "Hardware ID:    $cleanHw"
Write-Host "Type:           $LicenseType"
Write-Host "Expiration:     $(if ($ExpirationDate) { $ExpirationDate } else { 'None (Perpetual)' })"
Write-Host "Features:       $($Features -join ', ')"
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "`nLICENSE KEY STRING (Copy & Paste):" -ForegroundColor Yellow
Write-Host $keyString -ForegroundColor White
Write-Host "`n--------------------------------------------------------" -ForegroundColor DarkGray

if ($OutFile) {
    Set-Content -Path $OutFile -Value $keyString -Force
    Write-Host "Saved license file to: $OutFile" -ForegroundColor Green
}

return $keyString
