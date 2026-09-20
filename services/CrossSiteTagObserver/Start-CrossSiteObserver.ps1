# ─────────────────────────────────────────────────────────────
# Start-CrossSiteObserver.ps1
# Launches the CrossSiteTagObserver as a persistent background
# process. Logs go to C:\Logs\CrossSiteObserver.log (managed
# internally by the process, NOT via PowerShell redirect).
# ─────────────────────────────────────────────────────────────

$serviceName = "CrossSiteTagObserver"
$publishDir  = "c:\inetpub\wwwroot\iDash\services\CrossSiteTagObserver\publish"
$exePath     = Join-Path $publishDir "CrossSiteTagObserver.exe"

# Kill existing instance
$existing = Get-Process $serviceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping existing $serviceName (PID $($existing.Id))..."
    $existing | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# Start as detached background process (NO stdout redirect!)
Write-Host "Starting $serviceName..."
Start-Process -FilePath $exePath -WorkingDirectory $publishDir -WindowStyle Hidden

Start-Sleep -Seconds 3
$check = Get-Process $serviceName -ErrorAction SilentlyContinue
if ($check) {
    Write-Host "[OK] $serviceName running (PID $($check.Id))"
    Write-Host "[OK] Logs at C:\Logs\CrossSiteObserver.log"
} else {
    Write-Host "[FAIL] $serviceName failed to start"
}
