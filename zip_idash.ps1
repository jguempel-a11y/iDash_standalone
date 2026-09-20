# ==============================================================================
# iDash Portability & Packaging Utility
# Packages the iDash application into a clean ZIP file for deployment,
# excluding Visual Studio cache, local logs, Git history, and large test files.
# ==============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentDir = Split-Path -Parent $scriptDir
$dateStamp = Get-Date -Format "yyyyMMdd-HHmm"
$zipName = "iDash_Release_$dateStamp.zip"
$targetZipPath = Join-Path $parentDir $zipName
$tempPackDir = Join-Path $parentDir "iDash_TempPack"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " iDash Packaging & Portability Tool " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Source directory: $scriptDir"
Write-Host "Target zip path : $targetZipPath"
Write-Host ""

# 1. Clean up old temporary packaging folders if they exist
if (Test-Path $tempPackDir) {
    Write-Host "Cleaning up old temporary directories..." -ForegroundColor Yellow
    Remove-Item -Path $tempPackDir -Recurse -Force
}

# 2. Re-create temporary staging folder
New-Item -ItemType Directory -Path $tempPackDir -Force | Out-Null

# 3. List of items/extensions to exclude
$excludePatterns = @(
    "\.vs",               # Visual Studio temp folder
    "\.git",              # Git repository history
    "\\logs\\",           # Local IIS or application logs
    "\\iDash_TempPack",   # The packaging folder itself
    "\.zip$",             # Any zip files
    "TTSC v1\.0\.0\.0\.xlsx$", # Large 16MB research spreadsheet
    "512 research data\.xlsx$", # Large 3MB research spreadsheet
    "db_test\.exe$",      # Temporary compilation executables
    "db_test\.cs$",
    "db_cmr_fix\.exe$",
    "db_cmr_fix\.cs$",
    "test_dump\.exe$",
    "test_dump\.cs$",
    "get_cols\.exe$",
    "get_cols\.cs$",
    "loc_check2\.exe$",
    "loc_check2\.cs$",
    "test_pb\.exe$",
    "test_pb\.cs$",
    "test_log\.cs$",
    "test\.exe$",
    "test\.cs$",
    "test\.ps1$",
    "test_db\.ps1$"
)

# 4. Copy files to temp folder while filtering out excluded items
Write-Host "Gathering and copying files..." -ForegroundColor Gray
$files = Get-ChildItem -Path $scriptDir -Recurse -File

$copyCount = 0
$skipCount = 0

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($scriptDir.Length + 1)
    
    # Check if file path matches any exclusion patterns
    $exclude = $false
    foreach ($pattern in $excludePatterns) {
        if ($file.FullName -match $pattern) {
            $exclude = $true
            break
        }
    }
    
    if ($exclude) {
        $skipCount++
        continue
    }
    
    # Ensure destination subfolders exist
    $destFilePath = Join-Path $tempPackDir $relativePath
    $destSubDir = Split-Path -Parent $destFilePath
    if (!(Test-Path $destSubDir)) {
        New-Item -ItemType Directory -Path $destSubDir -Force | Out-Null
    }
    
    # Copy the file
    Copy-Item -Path $file.FullName -Destination $destFilePath -Force
    $copyCount++
}

Write-Host "Files copied to staging area: $copyCount (Excluded/Skipped: $skipCount)" -ForegroundColor Green

# 5. Compress the staging folder using Compress-Archive
Write-Host "Creating zip archive..." -ForegroundColor Gray
if (Test-Path $targetZipPath) {
    Remove-Item -Path $targetZipPath -Force
}

Compress-Archive -Path "$tempPackDir\*" -DestinationPath $targetZipPath -Force

# 6. Clean up temporary folder
Write-Host "Cleaning up staging directory..." -ForegroundColor Gray
Remove-Item -Path $tempPackDir -Recurse -Force

# 7. Print summary
if (Test-Path $targetZipPath) {
    $zipFile = Get-Item $targetZipPath
    $zipSizeMb = [Math]::Round($zipFile.Length / 1MB, 2)
    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Archive created: $($zipFile.Name) ($zipSizeMb MB)" -ForegroundColor Green
    Write-Host "Location: $($zipFile.FullName)" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
} else {
    Write-Error "Failed to generate ZIP archive."
}
