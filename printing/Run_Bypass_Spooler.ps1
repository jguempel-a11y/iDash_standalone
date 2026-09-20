[Reflection.Assembly]::LoadFile('C:\Program Files (x86)\InfinID Technologies\iDash Print Service\Seagull.BarTender.Print.dll') | Out-Null
$engine = New-Object Seagull.BarTender.Print.Engine
$engine.Start()

# Target standalone iDash database by default
$connString = "Server=localhost\sqlexpress;Database=iDash;User ID=iDashDBAdmin;Password=iDashDBAdmin;Encrypt=False;TrustServerCertificate=True;"
if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server")) {
    # Optional Windows Auth fallback
    # $connString = "Server=localhost\sqlexpress;Database=iDash;Integrated Security=True;"
}
Write-Host "Starting Native iDash .NET SDK Print Spooler..."
Write-Host "Polling iDash Database for pending Print Jobs... (Press Ctrl+C to exit)`n"

while ($true) {
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection $connString
        $conn.Open()
        
        $sql = "SELECT p.id, p.recordid, t.filename, a.name, a.description, a.text1, a.text3, a.text8, a.rfidtag FROM printjob p INNER JOIN template t on p.templateid = t.id INNER JOIN asset a on p.recordid = a.id WHERE p.completed = 0 ORDER BY p.id ASC"
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        $reader = $cmd.ExecuteReader()
        
        $jobs = @()
        while ($reader.Read()) {
            $jobs += @{
                id = $reader["id"]
                recordid = $reader["recordid"]
                filename = $reader["filename"]
                name = if ($reader["name"] -ne [System.DBNull]::Value) { $reader["name"] } else { "" }
                description = if ($reader["description"] -ne [System.DBNull]::Value) { $reader["description"] } else { "" }
                text1 = if ($reader["text1"] -ne [System.DBNull]::Value) { $reader["text1"] } else { "" }  # Manufacturer
                text3 = if ($reader["text3"] -ne [System.DBNull]::Value) { $reader["text3"] } else { "" }  # Serial Number
                text8 = if ($reader["text8"] -ne [System.DBNull]::Value) { $reader["text8"] } else { "" }  # CMR
                rfidtag = if ($reader["rfidtag"] -ne [System.DBNull]::Value) { $reader["rfidtag"] } else { "" }
            }
        }
        $reader.Close()
        
        foreach ($job in $jobs) {
            Write-Host "Printing Job $($job.id) for Asset $($job.recordid) mapping SubStrings via .NET API..."
            
            # --- Resolve full .btw path -------------------------------------------
            # template.filename may be stored without extension or as a bare name.
            # Normalize it: ensure .btw extension and a rooted path.
            $btwFile = $job.filename.Trim()
            if (-not [System.IO.Path]::HasExtension($btwFile)) {
                $btwFile = $btwFile + ".btw"
            }
            if (-not [System.IO.Path]::IsPathRooted($btwFile)) {
                $btwFile = "C:\idash_prints\" + $btwFile
            }
            Write-Host " -> Resolved template path: $btwFile"
            # -----------------------------------------------------------------------
            
            try {
                $format = $engine.Documents.Open($btwFile)
                
                # SEVER THE BROKEN GHOST SQL DATABASE CONNECTION!
                $format.PrintSetup.UseDatabase = $false
                
                # FORCE INJECT TRUE ASSET DATA DIRECTLY INTO THE LABEL MEMORY
                if ($format.SubStrings -ne $null) {
                    try { $format.SubStrings.SetSubString("lblname", $job.name) } catch {}
                    try { $format.SubStrings.SetSubString("lbleil", $job.text8) } catch {}   # text8 = CMR
                    try { $format.SubStrings.SetSubString("lbldescription", $job.description) } catch {}
                    try { $format.SubStrings.SetSubString("lblsn", $job.text3) } catch {}             # text3 = Serial Number
                    try { $format.SubStrings.SetSubString("lblrfidtag", $job.rfidtag) } catch {}
                }
                
                # OPTIONAL DYNAMIC MASTER PRINTER ROUTING OVERRIDE!
                $routingFile = Join-Path $PSScriptRoot "printer_routing.json"
                if (Test-Path $routingFile) {
                    $printerMap = Get-Content $routingFile | ConvertFrom-Json
                    $baseFileName = [System.IO.Path]::GetFileName($job.filename)
                    if ($printerMap.$baseFileName) {
                        try { $format.PrintSetup.PrinterName = $printerMap.$baseFileName } catch {}
                        Write-Host " -> Dynamically Re-Routing Label to Hardware Printer: $($printerMap.$baseFileName)"
                    }
                }
                
                # Physically Print to Default HW (RFID Dialog succeeds because you are Interactive User)
                $result = $format.Print("iDash Job $($job.id)", 30000)
                $format.Close(1)
                
                if ($result -eq "Success") {
                    $updateCmd = $conn.CreateCommand()
                    $updateCmd.CommandText = "UPDATE printjob SET completed=1 WHERE id=$($job.id)"
                    $updateCmd.ExecuteNonQuery() | Out-Null
                    Write-Host " -> ✅ Successfully Printed and Marked Completed in DB!`n"
                } else {
                    Write-Host " -> ❌ BarTender exited with Error: $result`n"
                    $updateCmd = $conn.CreateCommand()
                    $updateCmd.CommandText = "UPDATE printjob SET completed=-1 WHERE id=$($job.id)"
                    $updateCmd.ExecuteNonQuery() | Out-Null
                }
            } catch {
                Write-Host " -> ❌ Critical Exception: $($_.Exception.Message)`n"
                try {
                    $updateCmd = $conn.CreateCommand()
                    $updateCmd.CommandText = "UPDATE printjob SET completed=-1 WHERE id=$($job.id)"
                    $updateCmd.ExecuteNonQuery() | Out-Null
                } catch {}
            }
        }
        $conn.Close()
        $conn.Dispose()
    } catch {
        Write-Host "SQL Polling Error: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 3
}
