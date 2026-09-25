<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_convert_maps.aspx.cs" Inherits="va_convert_maps" %>
<!DOCTYPE html>
<html>
<head>
    <title>Convert Maps Pipeline</title>
            <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js"></script>
    <script>pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';</script>
</head>
<body style="font-family:sans-serif; background:#1e1e1e; color:#fff;">
    <div style="padding:40px; max-width: 800px; margin: auto;">
        <h2 style="color:#3b82f6;">Client-Side Map Rendering Engine</h2>
        <p style="color:#9ca3af; line-height:1.6;">
            Because the local server doesn't have PDF libraries installed, this tool leverages your browser's internal PDF engine 
            to autonomously rasterize all blueprint files into ultra high-resolution Web PNGs. 
            Do not close this tab until completion.
        </p>
        
        <div id="status" style="margin-bottom:20px; font-size:18px; font-weight:bold; color:#10b981;">Ready to convert...</div>
        <div id="log" style="font-family:Consolas, monospace; font-size: 13px; background:#0b0f19; padding:20px; border-radius:8px; border:1px solid #1f2937; height:400px; overflow-y:auto; line-height: 1.5;"></div>
        
        <canvas id="renderCanvas" style="display:none;"></canvas>
    </div>

    <script>
        const pdfFiles = [<%= PdfFilesJson %>][0];
        let currentIndex = 0;

        function log(msg) {
            const l = document.getElementById('log');
            l.innerHTML += msg + '<br>';
            l.scrollTop = l.scrollHeight;
        }

        async function processNext() {
            if (currentIndex >= pdfFiles.length) {
                document.getElementById('status').innerText = 'All done!';
                document.getElementById('status').style.color = '#10b981';
                log('<br><span style="color:#10b981; font-weight:bold;">[SUCCESS] Autonomous map conversion pipeline fully completed! Check your maps dashboard.</span>');
                return;
            }

            const pdfPathRel = pdfFiles[currentIndex];
            const pdfUrl = 'site_maps/' + encodeURI(pdfPathRel);
            
            document.getElementById('status').innerText = `Rendering: ${pdfPathRel} (${currentIndex+1}/${pdfFiles.length})`;
            document.getElementById('status').style.color = '#f59e0b';
            log(`<b>[FILE ${currentIndex+1}/${pdfFiles.length}]</b> Retrieving: ${pdfPathRel}...`);

            try {
                const loadingTask = pdfjsLib.getDocument(pdfUrl);
                const pdf = await loadingTask.promise;
                
                const page = await pdf.getPage(1); 
                
                // Scale 2.5 represents ~300 DPI high resolution zoom so they don't lose quality!
                const scale = 2.5; 
                const viewport = page.getViewport({ scale: scale });

                const canvas = document.getElementById('renderCanvas');
                const context = canvas.getContext('2d');
                canvas.height = viewport.height;
                canvas.width = viewport.width;

                const renderContext = {
                    canvasContext: context,
                    viewport: viewport
                };

                log(`--> Rasterizing vector canvas at ${canvas.width}x${canvas.height}...`);
                await page.render(renderContext).promise;

                log(`--> Generating lossless PNG bitmap base64 payload...`);
                const dataUrl = canvas.toDataURL('image/png');

                log(`--> Pushing graphic overwrite sequence back to local server file system...`);
                const fd = new FormData();
                fd.append('pdf_path', pdfPathRel);
                fd.append('img_data', dataUrl);

                const res = await fetch('va_convert_maps.aspx', { method: 'POST', body: fd });
                if (res.ok) {
                    log(`<span style="color:#10b981">--> [OK] Server acknowledged extraction and purged original PDF container.</span><br>`);
                } else {
                    const errorText = await res.text();
                    log(`<span style="color:#ef4444">--> [SERVER ERROR] ${errorText}</span><br>`);
                }

            } catch (err) {
                log(`<span style="color:#ef4444">--> [FATAL ERROR] Engine faulted: ${err}</span><br>`);
            }

            currentIndex++;
            setTimeout(processNext, 800);  // Buffer delay to prevent memory spikes
        }

        window.onload = () => {
            if(pdfFiles.length === 0) {
                log('<span style="color:#9ca3af;">Directory scan complete. 0 PDF maps remaining to convert.</span>');
                document.getElementById('status').innerText = 'Finished. No target PDF files found.';
            } else {
                log(`<span style="color:#3b82f6;">Loaded ${pdfFiles.length} target PDF maps to digest... initializing engine...</span><br>`);
                processNext();
            }
        };
    </script>
</body>
</html>
