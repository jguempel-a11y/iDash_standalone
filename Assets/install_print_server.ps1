# ============================================================
# iDash Print Service - Setup Script
# Run this in an ELEVATED (Admin) PowerShell
# ============================================================

$psDir = "C:\Program Files (x86)\InfinID Technologies\iDash Print Service"

# Step 1: Update config (already done, but ensuring correct values)
Write-Host "=== Step 1: Updating Print Server config ===" -ForegroundColor Cyan
$config = Get-Content "$psDir\appsettings.json" | ConvertFrom-Json
$config.ConfigSettings.MqttServer = "localhost"
$config.ConfigSettings.MqttServerPort = 8883
$config.ConfigSettings.PrintClientUsername = "MasterPrint"
$config.ConfigSettings.PrintClientPassword = "V5MqttPrint2026!"
$config.ConfigSettings.UseForPrinting = $true
$config.ConfigSettings.AuthServerUrl = "http://localhost"
$config.ConfigSettings.AuthenticationServer = "http://localhost"
$config | ConvertTo-Json -Depth 10 | Set-Content "$psDir\appsettings.json" -Encoding UTF8
Write-Host "  Config updated." -ForegroundColor Green

# Step 2: Register as Windows service
Write-Host "`n=== Step 2: Registering Windows Service ===" -ForegroundColor Cyan
$svcName = "iDashPrintService"
$existing = Get-Service $svcName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "  Service already exists (Status: $($existing.Status))" -ForegroundColor Yellow
    if ($existing.Status -ne "Running") {
        Start-Service $svcName
        Write-Host "  Service started." -ForegroundColor Green
    }
} else {
    $exePath = "$psDir\iDash.PrintService.exe"
    New-Service -Name $svcName `
        -BinaryPathName $exePath `
        -DisplayName "iDash Print Service" `
        -StartupType Automatic `
        -Description "iDash MQTT Print Service - handles print jobs from all sites via BarTender"
    Write-Host "  Service registered." -ForegroundColor Green
    Start-Service $svcName
    Write-Host "  Service started." -ForegroundColor Green
}

# Step 3: Verify
Write-Host "`n=== Step 3: Verification ===" -ForegroundColor Cyan
$svc = Get-Service $svcName
Write-Host "  Service: $($svc.DisplayName)"
Write-Host "  Status:  $($svc.Status)"

# Check MQTT connectivity
Start-Sleep 3
$logPath = "C:\Logs"
$latestLog = Get-ChildItem $logPath -Filter "PrintServer*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestLog) {
    Write-Host "`n  Latest log: $($latestLog.FullName)"
    Write-Host "  Last 5 lines:"
    Get-Content $latestLog.FullName -Tail 5 | ForEach-Object { Write-Host "    $_" }
} else {
    Write-Host "`n  No print server logs found yet (check C:\Logs\)"
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Print Server is configured with MasterPrint credentials"
Write-Host "covering all 6 sites: 512, 517, 540, 581, 613, 688"
