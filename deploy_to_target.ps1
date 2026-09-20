# ==============================================================
#  iDash Targeted Deploy Script
#  Copies ONLY the files you specify — no full folder traversal
#  Runs in seconds instead of hours.
#
#  HOW TO USE:
#    1. Save this file into your iDash source folder
#       e.g.  C:\inetpub\wwwroot\iDash\
#    2. Set $TARGET below to the destination path (UNC or local)
#    3. Add/remove file names in $FILES as needed
#    4. Run: powershell -ExecutionPolicy Bypass -File deploy_to_target.ps1
# ==============================================================

# ── DESTINATION ──────────────────────────────────────────────
# Examples:
#   Local:  "C:\inetpub\wwwroot\iDash"
#   UNC:    "\\SERVER2\c$\inetpub\wwwroot\iDash"
$TARGET = "\\SERVER2\c$\inetpub\wwwroot\iDash"

# ── SOURCE (this machine) ────────────────────────────────────
# Defaults to the folder this script lives in
$SOURCE = $PSScriptRoot

# ── FILES TO DEPLOY ──────────────────────────────────────────
# List every file you want to push. Add/remove as needed.
$FILES = @(
    # ENNX History
    "ennxhistory.aspx"

    # ENNX Export
    "va_ennx.aspx"
    "va_ennx.aspx.cs"

    # Asset Master
    "va_asset_master.aspx"
    "va_asset_master.aspx.cs"

    # Location List
    "va_location_list.aspx"
    "va_location_list.aspx.cs"

    # Prime Excel Tracking
    "va_prime_excel_tracking_sheet.aspx"
    "va_prime_excel_tracking_sheet.aspx.cs"

    # Tag Stats
    "va_tag_stats.aspx"
    "va_tag_stats.aspx.cs"

    # Site Data Export / Import
    "va_sitedata_export.aspx"
    "va_sitedata_export.aspx.cs"
    "fix_site_517_locations.sql"
)

# ── DEPLOY ───────────────────────────────────────────────────
$ok = 0; $fail = 0; $skip = 0
$width = ($FILES | Measure-Object Length -Maximum).Maximum + 2

Write-Host ""
Write-Host "  iDash Deploy" -ForegroundColor Cyan
Write-Host "  Source : $SOURCE" -ForegroundColor DarkGray
Write-Host "  Target : $TARGET" -ForegroundColor DarkGray
Write-Host ("  " + "-" * 60) -ForegroundColor DarkGray
Write-Host ""

if (-not (Test-Path $TARGET)) {
    Write-Host "  ERROR: Target path not reachable: $TARGET" -ForegroundColor Red
    Write-Host "  Check network/path and try again." -ForegroundColor Red
    exit 1
}

foreach ($file in $FILES) {
    $src = Join-Path $SOURCE $file
    $dst = Join-Path $TARGET $file

    if (-not (Test-Path $src)) {
        Write-Host ("  [SKIP]  " + $file.PadRight($width)) -NoNewline
        Write-Host "not found in source" -ForegroundColor DarkYellow
        $skip++
        continue
    }

    try {
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

        Copy-Item -Path $src -Destination $dst -Force
        $ts = (Get-Item $src).LastWriteTime.ToString("MM/dd HH:mm")
        Write-Host ("  [OK]    " + $file.PadRight($width)) -NoNewline -ForegroundColor Green
        Write-Host "modified $ts" -ForegroundColor DarkGray
        $ok++
    }
    catch {
        Write-Host ("  [FAIL]  " + $file.PadRight($width)) -NoNewline -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host ("  " + "-" * 60) -ForegroundColor DarkGray
Write-Host ("  Done.  Copied: $ok   Skipped: $skip   Failed: $fail") -ForegroundColor Cyan
Write-Host ""

if ($fail -gt 0) { exit 1 } else { exit 0 }
