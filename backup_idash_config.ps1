# ═══════════════════════════════════════════════════════════════════════
# iDash Pre-Update Backup Script
# ═══════════════════════════════════════════════════════════════════════
#
# PURPOSE:  Backs up all site-specific configuration files BEFORE
#           overwriting iDash with a new build/zip.
#
# USAGE:    Run as Administrator:
#           powershell -ExecutionPolicy Bypass -File backup_idash_config.ps1
#
# RESTORE:  After unzipping the new iDash build, copy the backed-up files
#           back to their original locations. The backup preserves the
#           directory structure so you can xcopy it back.
#
# AUTHOR:   iDash Development Team
# DATE:     August 26, 2026
# ═══════════════════════════════════════════════════════════════════════

$iDashRoot   = "C:\inetpub\wwwroot\iDash"
$backupRoot  = "C:\va_rfid\idash_update_files"
$timestamp   = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupDir   = Join-Path $backupRoot $timestamp

# ─── Create backup directory ────────────────────────────────────────
if (!(Test-Path $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  iDash Pre-Update Backup" -ForegroundColor Cyan
Write-Host "  Source:  $iDashRoot" -ForegroundColor DarkGray
Write-Host "  Backup:  $backupDir" -ForegroundColor DarkGray
Write-Host "  Time:    $(Get-Date)" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ─── Define critical files ──────────────────────────────────────────
# These are site-specific and MUST NOT be overwritten during an update.

$criticalFiles = @(
    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 1: MASTER CONFIG — CONNECTION STRINGS + API KEYS │
    # │  Contains: DB connection, OAuth client ID/secret, SMTP     │
    # │  credentials, Twilio keys, email recipients, alert config  │
    # └─────────────────────────────────────────────────────────────┘
    "web.config",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 2: USER ACCOUNTS & AUTHENTICATION                │
    # │  Contains: iDash login credentials, roles, tile access     │
    # └─────────────────────────────────────────────────────────────┘
    "App_Data\idash_users.json",
    "App_Data\user_templates.json",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 3: PRINT & MQTT CONFIGURATION                    │
    # │  Contains: Printer routing rules, print mapping config,    │
    # │  Print Server appsettings reference                        │
    # └─────────────────────────────────────────────────────────────┘
    "print_mapping_config.json",
    "printing\printer_routing.json",
    "Assets\printserver_appsettings.json",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 4: EMAIL & REPORT AUTOMATION                     │
    # │  Contains: Email recipients, report schedules, cron config │
    # └─────────────────────────────────────────────────────────────┘
    "config\email_recipients.json",
    "config\report_automation.json",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 5: FHIR / HEALTH API KEYS (if configured)       │
    # │  Contains: FHIR config, private/public key pairs           │
    # └─────────────────────────────────────────────────────────────┘
    "config\fhir\fhir_config.json",
    "config\fhir\private.pem",
    "config\fhir\public.jwk",
    "config\fhir\public.pem",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 6: TRAINING & DATA                               │
    # │  Contains: Training module definitions, progress data      │
    # └─────────────────────────────────────────────────────────────┘
    "training_modules.json",
    "App_Data\training_data.json",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 7: CROSS-SITE TAG OBSERVER SERVICE               │
    # │  Contains: MQTT creds, DB connection for observer service  │
    # └─────────────────────────────────────────────────────────────┘
    "services\CrossSiteTagObserver\appsettings.json",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 8: READER DATA DUMP (site-specific readers)      │
    # └─────────────────────────────────────────────────────────────┘
    "readers_dump.json",

    # ┌─────────────────────────────────────────────────────────────┐
    # │  CATEGORY 9: READER INTELLIGENCE CONFIG                    │
    # │  Contains: Dwell time threshold, auto-reassign toggle,     │
    # │  departure timeout, email report settings                  │
    # └─────────────────────────────────────────────────────────────┘
    "config\reader_intelligence.json"
)

# ─── Also backup entire directories that contain site-specific data ──
$criticalDirs = @(
    # DB Workbench saved SQL profiles (per-site custom queries)
    "workbench_profiles",
    # ASP.NET membership DB (if used)
    "App_Data"
)

# ─── Backup individual files ────────────────────────────────────────
$backed = 0
$skipped = 0

Write-Host "Backing up critical config files..." -ForegroundColor Yellow
Write-Host ""

foreach ($relPath in $criticalFiles) {
    $src = Join-Path $iDashRoot $relPath
    $dst = Join-Path $backupDir $relPath
    
    if (Test-Path $src) {
        $dstDir = Split-Path $dst -Parent
        if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item $src $dst -Force
        $sizeKB = [math]::Round((Get-Item $src).Length / 1024, 1)
        Write-Host ("  [OK] {0}  ({1} KB)" -f $relPath, $sizeKB) -ForegroundColor Green
        $backed++
    } else {
        Write-Host ("  [--] {0}  (not found - skipping)" -f $relPath) -ForegroundColor DarkGray
        $skipped++
    }
}

# ─── Backup directories ────────────────────────────────────────────
Write-Host ""
Write-Host "Backing up data directories..." -ForegroundColor Yellow
Write-Host ""

foreach ($relDir in $criticalDirs) {
    $src = Join-Path $iDashRoot $relDir
    $dst = Join-Path $backupDir $relDir
    
    if (Test-Path $src) {
        Copy-Item $src $dst -Recurse -Force
        $count = (Get-ChildItem $src -Recurse -File).Count
        Write-Host ("  [OK] {0}\  ({1} files)" -f $relDir, $count) -ForegroundColor Green
    } else {
        Write-Host ("  [--] {0}\  (not found - skipping)" -f $relDir) -ForegroundColor DarkGray
    }
}

# ─── Summary ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Backup Complete!" -ForegroundColor Green
Write-Host "  Files backed up:  $backed" -ForegroundColor White
Write-Host "  Files skipped:    $skipped (not present on this system)" -ForegroundColor DarkGray
Write-Host "  Backup location:  $backupDir" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Unzip new iDash build over $iDashRoot"
Write-Host "  2. Copy backed-up files back:"
Write-Host "     xcopy `"$backupDir\*`" `"$iDashRoot`" /S /Y"
Write-Host "  3. Verify web.config connection string points to correct SQL instance"
Write-Host "  4. Test: http://localhost/iDash/index.aspx"
Write-Host ""

# ─── Create a restore script alongside the backup ──────────────────
$restoreScript = @"
# ═══════════════════════════════════════════════════════════════
# iDash Config RESTORE Script
# Run this AFTER unzipping a new iDash build to restore configs.
# ═══════════════════════════════════════════════════════════════

`$backupDir = "$backupDir"
`$iDashRoot = "$iDashRoot"

Write-Host "Restoring iDash config from: `$backupDir" -ForegroundColor Yellow
xcopy "`$backupDir\*" "`$iDashRoot" /S /Y /I
Write-Host "Done! Configs restored." -ForegroundColor Green
Write-Host "Verify: http://localhost/iDash/index.aspx"
"@

$restorePath = Join-Path $backupDir "RESTORE_CONFIG.ps1"
Set-Content -Path $restorePath -Value $restoreScript -Encoding UTF8
Write-Host "Restore script created: $restorePath" -ForegroundColor DarkGray
Write-Host ""
