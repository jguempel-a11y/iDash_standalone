<#
.SYNOPSIS
    Remote iDash Database Update — run from any workstation on the network.

.DESCRIPTION
    Uploads a tab-delimited data file (.txt) to the iDash server and runs
    the full import pipeline (SqlBulkCopy + merge). No BULK INSERT is used,
    so IIS and SQL Server do NOT need to be on the same machine.

    The script POSTs the file over HTTP to the va_remote_import.ashx endpoint,
    which streams rows to SQL Server using SqlBulkCopy.

.PARAMETER DataFile
    Path to the tab-delimited .txt data file to import.

.PARAMETER ServerUrl
    Base URL of the iDash site (e.g., http://myserver/iDash).
    Defaults to http://localhost/iDash.

.PARAMETER ApiKey
    API key for authentication (must match RemoteImportKey in web.config).
    If blank, no key header is sent (OK if RemoteImportKey is not configured).

.PARAMETER ForceSite
    Optional 3-digit station number. When set, all rows without a station
    number will be assigned this value.

.EXAMPLE
    .\remote_db_update.ps1 -DataFile "C:\Data\ALLV5SITEdata.txt" -ServerUrl "http://10.0.1.50/iDash"

.EXAMPLE
    .\remote_db_update.ps1 -DataFile "\\fileserver\data\export.txt" -ServerUrl "http://idash-server/iDash" -ApiKey "mykey123"

.EXAMPLE
    .\remote_db_update.ps1 -DataFile ".\data.txt" -ForceSite "640"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the .txt data file")]
    [string]$DataFile,

    [Parameter(Mandatory = $false, HelpMessage = "Base iDash URL (e.g., http://myserver/iDash)")]
    [string]$ServerUrl = "http://localhost:8181",

    [Parameter(Mandatory = $false, HelpMessage = "API key (must match RemoteImportKey in web.config)")]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false, HelpMessage = "Force all rows to this 3-digit station number")]
    [string]$ForceSite = ""
)

# ═══════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════
$ErrorActionPreference = "Stop"

function Write-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║     iDash Remote Database Update                 ║" -ForegroundColor Cyan
    Write-Host "  ║     Network-Safe Import (SqlBulkCopy)            ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Msg, [string]$Color = "White")
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "  [$ts] " -ForegroundColor DarkGray -NoNewline
    Write-Host $Msg -ForegroundColor $Color
}

function Write-Result {
    param([string]$Label, [string]$Value, [string]$Color = "Green")
    Write-Host "    $Label : " -ForegroundColor Gray -NoNewline
    Write-Host $Value -ForegroundColor $Color
}

# ═══════════════════════════════════════════════════════════════
# VALIDATE
# ═══════════════════════════════════════════════════════════════
Write-Banner

# Resolve full path
$DataFile = (Resolve-Path $DataFile -ErrorAction SilentlyContinue).Path
if (-not $DataFile -or -not (Test-Path $DataFile)) {
    Write-Host "  ERROR: Data file not found: $DataFile" -ForegroundColor Red
    Write-Host ""
    exit 1
}

$fileInfo = Get-Item $DataFile
$fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

# Count rows (minus header)
$lineCount = 0
try {
    $lineCount = (Get-Content $DataFile -ReadCount 0).Count - 1
    if ($lineCount -lt 0) { $lineCount = 0 }
} catch { }

Write-Step "Data file   : $DataFile"
Write-Step "File size   : $fileSizeMB MB  ($lineCount data rows)"
Write-Step "Server      : $ServerUrl"
if ($ForceSite) {
    Write-Step "Force Site  : $ForceSite" "Yellow"
}
Write-Host ""

# Estimated time
$estimate = "under 30 seconds"
if ($lineCount -ge 5000)   { $estimate = "30 sec - 1 min" }
if ($lineCount -ge 15000)  { $estimate = "1 - 3 minutes" }
if ($lineCount -ge 30000)  { $estimate = "3 - 5 minutes" }
if ($lineCount -ge 60000)  { $estimate = "5 - 10 minutes" }
if ($lineCount -ge 100000) { $estimate = "10+ minutes" }

Write-Step "Est. time   : $estimate" "DarkYellow"
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# CONFIRM
# ═══════════════════════════════════════════════════════════════
Write-Host "  Press ENTER to start import, or Ctrl+C to cancel..." -ForegroundColor Yellow -NoNewline
Read-Host
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# UPLOAD
# ═══════════════════════════════════════════════════════════════
$endpoint = $ServerUrl.TrimEnd("/") + "/api/va_remote_import.ashx"
Write-Step "Uploading to: $endpoint" "Cyan"

$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
    # Build multipart/form-data manually (works in PS 5.1+)
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"

    $bodyLines = @()
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"datafile`"; filename=`"$($fileInfo.Name)`""
    $bodyLines += "Content-Type: text/plain"
    $bodyLines += ""

    # Read file as string and append
    $fileContent = [System.IO.File]::ReadAllText($DataFile, [System.Text.Encoding]::UTF8)

    $bodyLines += $fileContent
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"forcesite`""
    $bodyLines += ""
    $bodyLines += $ForceSite
    $bodyLines += "--$boundary--"

    $body = $bodyLines -join $LF

    $headers = @{ "Content-Type" = "multipart/form-data; boundary=$boundary" }
    if ($ApiKey) {
        $headers["X-Api-Key"] = $ApiKey
    }

    # Use .NET WebClient for large file support and better timeout handling
    Write-Step "Streaming file to server..." "White"

    $result = Invoke-WebRequest `
        -Uri $endpoint `
        -Method POST `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
        -Headers $headers `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -UseBasicParsing `
        -TimeoutSec 1800

    $sw.Stop()
    $elapsed = $sw.Elapsed.ToString("mm\:ss")

    Write-Host ""

    if ($result.StatusCode -eq 200) {
        $json = $result.Content | ConvertFrom-Json

        if ($json.status -eq "OK") {
            Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "  ║  IMPORT COMPLETED SUCCESSFULLY                  ║" -ForegroundColor Green
            Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host ""

            Write-Result "Rows parsed"          "$($json.rows)"
            Write-Result "Rows in SQL"          "$($json.sqlRows)"
            Write-Result "Locations inserted"   "$($json.locationsInserted)"
            Write-Result "Assets inserted"      "$($json.assetsInserted)"      "Green"
            Write-Result "Assets updated"       "$($json.assetsUpdated)"       "Cyan"
            Write-Result "Assets skipped"       "$($json.assetsSkipped)"       "DarkYellow"

            if ([int]$json.errors -gt 0) {
                Write-Result "Errors"            "$($json.errors)"             "Red"
            } else {
                Write-Result "Errors"            "0"                            "Green"
            }

            Write-Result "Total assets now"     "$($json.totalAssets)"         "White"
            Write-Host ""
            Write-Step "Elapsed: $elapsed" "DarkGray"
        }
        else {
            Write-Host "  ERROR from server: $($json.detail)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  HTTP $($result.StatusCode): $($result.Content)" -ForegroundColor Red
    }
}
catch {
    $sw.Stop()
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║  IMPORT FAILED                                  ║" -ForegroundColor Red
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.InnerException) {
        Write-Host "  Inner: $($_.Exception.InnerException.Message)" -ForegroundColor DarkRed
    }

    # Common troubleshooting
    Write-Host ""
    Write-Host "  Troubleshooting:" -ForegroundColor Yellow
    Write-Host "    - Is the iDash server reachable? Try: Test-NetConnection $(([System.Uri]$endpoint).Host) -Port $(([System.Uri]$endpoint).Port)" -ForegroundColor DarkGray
    Write-Host "    - Is the URL correct?  $endpoint" -ForegroundColor DarkGray
    Write-Host "    - Is the API key correct?  Check web.config -> appSettings -> RemoteImportKey" -ForegroundColor DarkGray
}

Write-Host ""
