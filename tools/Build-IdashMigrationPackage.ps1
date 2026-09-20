<#
.SYNOPSIS
    Builds a clean, safe iDash full-site migration package for deploying to remote laptops, carts, and servers.

.DESCRIPTION
    This script packages all application code, compiled binaries, user controls, assets, and documentation
    from the current iDash installation into a compressed archive (idash_full_site.zip) in the downloads/ folder.
    
    It strictly enforces the Safe Migration Boundary by excluding:
      - web.config (preserves the remote machine's database credentials and local connection strings)
      - App_Data/ (preserves local database tables and user credentials)
      - downloads/ (excludes large installer archives)
      - logs/ and uploads/ (preserves local operator audit trails)
      - .git and scratch/ (excludes development metadata)

.EXAMPLE
    .\Build-IdashMigrationPackage.ps1
#>

[CmdletBinding()]
param (
    [string]$SourceDir = "C:\inetpub\wwwroot\iDash",
    [string]$ZipOutput = "C:\inetpub\wwwroot\iDash\downloads\idash_full_site.zip"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " iDash Full-Site Migration Package Builder                " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $SourceDir)) {
    throw "Source directory not found: $SourceDir"
}

$stageDir = Join-Path $SourceDir "scratch\stage_full_site"
if (Test-Path $stageDir) {
    Remove-Item $stageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stageDir | Out-Null

$zipDir = [System.IO.Path]::GetDirectoryName($ZipOutput)
if (-not (Test-Path $zipDir)) {
    New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
}
if (Test-Path $ZipOutput) {
    Remove-Item $ZipOutput -Force
}

Write-Host "[1/3] Staging application files (enforcing Safe Migration Boundary)..." -ForegroundColor Yellow

# Use robocopy to mirror application files while excluding volatile data
$robocopyArgs = @(
    $SourceDir,
    $stageDir,
    "/E",
    "/XD", ".git", "scratch", "downloads", "App_Data", "logs", "uploads", "temp", "services",
    "/XF", "web.config", "*.log", "*.docx", "*.zip"
)
& robocopy.exe @robocopyArgs | Out-Null

$fileCount = (Get-ChildItem -Path $stageDir -Recurse -File).Count
Write-Host "      Staged $fileCount files successfully." -ForegroundColor Gray

Write-Host "[2/3] Compressing into migration archive: $ZipOutput..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stageDir, $ZipOutput)

# Clean up stage
Remove-Item $stageDir -Recurse -Force

$mb = [math]::Round((Get-Item $ZipOutput).Length / 1MB, 2)
Write-Host "[3/3] Migration package created successfully: $mb MB" -ForegroundColor Green

# Also ensure run_migration.sql is freshly emitted to downloads/ for zero-effort execution
$sqlScriptPath = Join-Path $zipDir "run_migration.sql"
$sqlContent = @"
-- ============================================================================
-- iDash Full-Site Migration & Replication Script
-- Executes over-the-air safe site synchronization from localhost to remote node
-- ============================================================================

-- 1. Enable xp_cmdshell temporarily for the transfer
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- 2. Download, extract, and overwrite application files (preserving Safe Boundary)
CREATE TABLE #p (line NVARCHAR(MAX));
INSERT INTO #p EXEC xp_cmdshell 'powershell.exe -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `$z = ''C:/Windows/Temp/idash_full_site.zip''; (New-Object Net.WebClient).DownloadFile(''https://lingcod.tail585c9b.ts.net/iDash/downloads/idash_full_site.zip'', `$z); Add-Type -AssemblyName System.IO.Compression.FileSystem; `$t = ''C:/Windows/Temp/stage_full_site''; if (Test-Path `$t) { Remove-Item `$t -Recurse -Force }; [System.IO.Compression.ZipFile]::ExtractToDirectory(`$z, `$t); Copy-Item -Path ''C:/Windows/Temp/stage_full_site/*'' -Destination ''C:/inetpub/wwwroot/iDash/iDash'' -Recurse -Force; Copy-Item -Path ''C:/Windows/Temp/stage_full_site/*'' -Destination ''C:/inetpub/wwwroot/idash'' -Recurse -Force; (Get-Item ''C:\inetpub\wwwroot\iDash\web.config'').LastWriteTime = Get-Date; Remove-Item `$t -Recurse -Force; Remove-Item `$z -Force; Write-Output ''FULL_SITE_MIGRATION_COMPLETE_SUCCESS'';"';

-- 3. Recycle the IIS AppPool to clear compiled ASP.NET caches
INSERT INTO #p EXEC xp_cmdshell '%windir%\system32\inetsrv\appcmd.exe recycle apppool "DefaultAppPool"';

-- 4. Re-lock SQL Server security immediately (NIST SP 800-53 AC-3 / SC-7 compliance)
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;

-- 5. Review results
SELECT line AS MigrationResult FROM #p WHERE line IS NOT NULL;
DROP TABLE #p;
"@
Set-Content -Path $sqlScriptPath -Value $sqlContent -Encoding UTF8
Write-Host "      Generated ready-to-run script: $sqlScriptPath" -ForegroundColor Gray

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " REMOTE DEPLOYMENT INSTRUCTIONS                           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "OPTION A: Over-the-Air via SQL Web Uploader (Fastest)" -ForegroundColor Yellow
Write-Host "  1. Open: https://laptop-e74ckmo5.tail2fc4c5.ts.net/idash/va_sql_upload.aspx"
Write-Host "  2. Check: [X] Allow dangerous SQL (DROP / ALTER / TRUNCATE)"
Write-Host "  3. Upload $sqlScriptPath OR paste its contents directly, then click 'Run SQL'."
Write-Host "     Docs: http://localhost/iDash/documentation/va_system_migration_guide.html#sec-method-ota"
Write-Host ""
Write-Host "OPTION B: Direct Manual Copy (USB or Network Share)" -ForegroundColor Yellow
Write-Host "  1. Copy $ZipOutput to the target machine."
Write-Host "  2. Extract and overwrite C:\inetpub\wwwroot\iDash\"
Write-Host "  3. Recycle IIS AppPool: appcmd recycle apppool 'DefaultAppPool'"
Write-Host "==========================================================" -ForegroundColor Cyan
