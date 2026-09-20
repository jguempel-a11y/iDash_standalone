# ==============================================================================
# iDash BarTender Preview Microservice
# Listens on http://localhost:5180/preview/ to render live label previews for iDash.
# Runs under interactive session or service account with zero BarTender SQL DB.
# ==============================================================================

[Reflection.Assembly]::LoadFile('C:\Program Files\Seagull\BarTender 11.5\SDK\Assemblies\Seagull.BarTender.Print.dll') | Out-Null
$engine = New-Object Seagull.BarTender.Print.Engine
$engine.Start()

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:5180/preview/")
$listener.Start()
Write-Host "BarTender Preview Sidecar Service running on http://localhost:5180/preview/..."
Write-Host "Ready to render instant label previews for iDash (Press Ctrl+C to exit)`n"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        if ($request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $json = $body | ConvertFrom-Json

            $tpl = if ($json.template) { $json.template } else { "c:\idash_prints\iDash_Std_Small.btw" }
            $tempPng = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "bt_sidecar_" + [Guid]::NewGuid().ToString("N") + ".png")

            try {
                $doc = $engine.Documents.Open($tpl)
                $doc.PrintSetup.UseDatabase = $false

                $fieldsDiscovered = @()
                if ($doc.SubStrings) {
                    foreach ($sub in $doc.SubStrings) {
                        $fieldsDiscovered += $sub.Name
                        if ($json.fields) {
                            $prop = $json.fields.PSObject.Properties[$sub.Name]
                            if ($prop) { $sub.Value = [string]$prop.Value }
                        }
                    }
                }

                $doc.ExportImageToFile($tempPng, [Seagull.BarTender.Print.ImageType]::PNG, [Seagull.BarTender.Print.ColorDepth]::ColorDepth24bit, (New-Object Seagull.BarTender.Print.Resolution 200), [Seagull.BarTender.Print.OverwriteOptions]::Overwrite)
                $doc.Close([Seagull.BarTender.Print.SaveOptions]::DoNotSaveChanges)

                $bytes = [System.IO.File]::ReadAllBytes($tempPng)
                [System.IO.File]::Delete($tempPng)
                $b64 = [Convert]::ToBase64String($bytes)

                $resObj = @{
                    Success = $true
                    ImageBase64 = $b64
                    DiscoveredFields = $fieldsDiscovered
                }
            } catch {
                $resObj = @{
                    Success = $false
                    ErrorMessage = $_.Exception.Message
                }
            }

            $resJson = $resObj | ConvertTo-Json
            $buf = [System.Text.Encoding]::UTF8.GetBytes($resJson)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Rendered preview for: $([System.IO.Path]::GetFileName($tpl))"
        } else {
            $response.StatusCode = 405
            $response.Close()
        }
    } catch {
        Write-Host "Listener error: $($_.Exception.Message)"
    }
}
