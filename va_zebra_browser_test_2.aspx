<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_zebra_browser_test_2.aspx.cs" Inherits="va_zebra_browser_test_2" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <title>RFID Scan Capture -- VA iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
    <script src="theme-init.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: var(--bg); color: var(--text); font-family: "Segoe UI", system-ui, sans-serif; font-size: 14px; min-height: 100vh; }
        .page-header { background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 85%) 0%, var(--card) 60%); border-bottom: 2px solid color-mix(in srgb, var(--accent), transparent 75%); padding: 12px 20px; display: flex; align-items: center; gap: 12px; position: sticky; top: 0; z-index: 100; box-shadow: 0 2px 12px color-mix(in srgb, var(--accent), transparent 90%); }
        .header-icon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #0284c7, #6366f1); font-size: 20px; color: #fff; }
        .header-title { font-size: 17px; font-weight: 700; }
        .header-sub   { font-size: 11px; color: var(--muted); }
        .container { max-width: 900px; margin: 16px auto; padding: 0 16px; }
        .scan-bar { background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 92%) 0%, var(--card) 100%); border: 2px solid var(--accent); border-radius: 14px; padding: 16px 18px; margin-bottom: 16px; box-shadow: 0 4px 20px color-mix(in srgb, var(--accent), transparent 85%); }
        .scan-label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: var(--accent); margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
        .pulse { width: 10px; height: 10px; border-radius: 50%; background: #10b981; animation: pulse-anim 1.5s infinite; }
        @keyframes pulse-anim { 0% { box-shadow: 0 0 0 0 rgba(16,185,129,0.7); } 70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); } 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); } }
        #raw { width: 100%; padding: 14px 16px; font-size: 16px; font-weight: 700; font-family: "Consolas", monospace; background: var(--bg); color: var(--text); border: 1px solid var(--line); border-radius: 10px; outline: none; }
        #raw:focus { border-color: var(--accent); }
        #raw.blurred { border-color: #f97316; background: rgba(249,115,22,0.06); }
        .stats-row { display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
        .stat { background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 12px 18px; flex: 1; min-width: 120px; text-align: center; }
        .stat-val { font-size: 28px; font-weight: 800; }
        .stat-lbl { font-size: 11px; color: var(--muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; margin-top: 4px; }
        .timing-bar { background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 10px 16px; margin-bottom: 16px; font-size: 13px; display: flex; gap: 20px; flex-wrap: wrap; }
        .timing-item { display: flex; flex-direction: column; }
        .timing-lbl { font-size: 10px; text-transform: uppercase; color: var(--muted); font-weight: 700; }
        .timing-val { font-weight: 700; font-family: monospace; font-size: 14px; }
        .toolbar { display: flex; gap: 8px; margin-bottom: 14px; flex-wrap: wrap; align-items: center; }
        .btn { background: var(--chip); color: var(--text); border: 1px solid var(--line); padding: 8px 16px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: all 0.15s; }
        .btn:hover { background: var(--line); }
        .btn-danger  { background: #ef4444; color: #fff; border-color: #ef4444; }
        .btn-success { background: #10b981; color: #fff; border-color: #10b981; }
        .card { background: var(--card); border: 1px solid var(--line); border-radius: 12px; overflow: hidden; margin-bottom: 16px; }
        .card-hdr { padding: 12px 16px; border-bottom: 1px solid var(--line); font-size: 13px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px; background: var(--chip); }
        .tag-list { max-height: 50vh; overflow-y: auto; }
        .tag-row { display: grid; grid-template-columns: 36px 1fr 80px 60px; padding: 9px 14px; border-bottom: 1px solid var(--line); font-size: 13px; align-items: center; gap: 8px; }
        .tag-row:last-child { border-bottom: none; }
        .tag-row.new { animation: flash-in 1.2s ease; }
        @keyframes flash-in { 0% { background: rgba(16,185,129,0.35); } 100% { background: transparent; } }
        .tag-num  { color: var(--muted); font-size: 11px; font-weight: 700; }
        .tag-id   { font-family: monospace; font-weight: 700; font-size: 13px; color: var(--accent); word-break: break-all; }
        .tag-time { font-size: 11px; color: var(--muted); text-align: right; }
        .tag-reads{ font-size: 12px; font-weight: 700; text-align: center; background: rgba(16,185,129,0.12); color: #10b981; border-radius: 10px; padding: 2px 6px; }
        .empty-msg { padding: 40px; text-align: center; color: var(--muted); }
        .log-box { background: #090d16; color: #a5b4fc; font-family: "Consolas", monospace; font-size: 12px; padding: 10px 12px; max-height: 160px; overflow-y: auto; line-height: 1.6; }
        .log-line { display: flex; gap: 8px; margin-bottom: 2px; }
        .log-ts  { color: #64748b; min-width: 56px; }
        .log-msg { color: #e2e8f0; word-break: break-all; }
        .status-pill { display: inline-block; padding: 3px 10px; border-radius: 10px; font-size: 11px; font-weight: 700; border: 1px solid; transition: all 0.2s; }
        .status-ready    { color: var(--muted); border-color: var(--line); }
        .status-scanning { color: #38bdf8; border-color: #38bdf8; background: rgba(56,189,248,0.1); }
        .status-paused   { color: #f97316; border-color: #f97316; background: rgba(249,115,22,0.1); }
    </style>
</head>
<body onload="document.getElementById('raw').focus(); init();">
    <div class="page-header">
        <div class="header-icon">&#9678;</div>
        <div>
            <div class="header-title">RFID Scan Capture</div>
            <div class="header-sub">simpleRFID-style keystroke capture -- iDash Diagnostic</div>
        </div>
    </div>
    <div class="container">
        <div class="scan-bar">
            <div class="scan-label">
                <div class="pulse" id="pulseDot"></div>
                <span>Active Scanner Input</span>
                <span class="status-pill status-ready" id="statusPill">&#9711; READY</span>
            </div>
            <input id="raw" type="text" autocomplete="off" autocorrect="off" spellcheck="false"
                   autocapitalize="off" placeholder="Pull RFD40 trigger to scan..." />
        </div>
        <div class="timing-bar">
            <div class="timing-item"><span class="timing-lbl">Scan Started</span><span class="timing-val" id="tStart">--:--:--</span></div>
            <div class="timing-item"><span class="timing-lbl">Last Tag Arrived</span><span class="timing-val" id="tLast">--:--:--</span></div>
            <div class="timing-item"><span class="timing-lbl">Duration Active</span><span class="timing-val" id="tDuration">0.0s</span></div>
            <div class="timing-item"><span class="timing-lbl">Tags / sec</span><span class="timing-val" id="tRate">0</span></div>
        </div>
        <div class="stats-row">
            <div class="stat"><div class="stat-val" id="cntUnique">0</div><div class="stat-lbl">Unique Tags</div></div>
            <div class="stat"><div class="stat-val" id="cntTotal">0</div><div class="stat-lbl">Total Reads</div></div>
            <div class="stat"><div class="stat-val" id="cntDupe">0</div><div class="stat-lbl">Duplicates</div></div>
        </div>
        <div class="toolbar">
            <button class="btn btn-danger" onclick="clearAll()">Clear All</button>
            <button class="btn btn-success" onclick="exportCsv()">Export CSV</button>
            <button class="btn" onclick="document.getElementById('raw').focus()">Re-Arm Scanner</button>
        </div>
        <div class="card">
            <div class="card-hdr">Captured Tags</div>
            <div class="tag-list" id="tagList">
                <div class="empty-msg" id="emptyMsg">Pull the RFD40 trigger to start scanning...</div>
            </div>
        </div>
        <div class="card">
            <div class="card-hdr">Event Log</div>
            <div class="log-box" id="logBox"></div>
        </div>
    </div>
    <script>
        var _tags=[], _tagMap={}, _totalReads=0, _dupeReads=0;
        var _scanStart=null, _lastTagTime=null, _sessionTimer=null, _sessionOpen=false;
        var IDLE_MS=1000;

        function init() {
            log("simpleRFID-style page ready. Waiting for trigger...");
            var input=document.getElementById("raw");
            input.addEventListener("focus", function() {
                input.classList.remove("blurred");
                input.placeholder="Pull RFD40 trigger to scan...";
                if (!_sessionOpen) setStatus("ready");
            });
            input.addEventListener("blur", function() {
                input.classList.add("blurred");
                input.placeholder="TAP HERE to re-arm scanner";
                setStatus("paused");
                log("INPUT LOST FOCUS -- tap to re-arm");
            });
            // IDENTICAL TO simpleRFID: keyup + Enter
            input.addEventListener("keyup", function(e) {
                if (e.key!=="Enter" && e.key!=="Tab") return;
                var val=input.value.trim().replace(/[\r\n]+$/,"").trim();
                input.value="";
                if (!val || val.length<3) return;
                processTag(val);
            });
        }

        function processTag(raw) {
            var id=raw.toUpperCase(), now=Date.now(), ts=timeStr();
            _totalReads++;
            if (!_sessionOpen) {
                _sessionOpen=true; _scanStart=now;
                setStatus("scanning");
                log("[SCAN] Session started -- first tag: "+id);
            }
            clearTimeout(_sessionTimer);
            _sessionTimer=setTimeout(closeSession, IDLE_MS);
            _lastTagTime=now;
            if (_tagMap.hasOwnProperty(id)) {
                _dupeReads++;
                _tags[_tagMap[id]].reads++;
                _tags[_tagMap[id]].lastSeen=ts;
                var el=document.getElementById("reads-"+_tagMap[id]);
                if (el) el.innerText=_tags[_tagMap[id]].reads+"x";
                updateStats(); return;
            }
            var idx=_tags.length;
            _tagMap[id]=idx;
            _tags.push({id:id,reads:1,firstSeen:ts,lastSeen:ts});
            var list=document.getElementById("tagList");
            var empty=document.getElementById("emptyMsg");
            if (empty) empty.remove();
            var row=document.createElement("div");
            row.className="tag-row new"; row.id="row-"+idx;
            row.innerHTML="<span class=\"tag-num\">"+(idx+1)+"</span>"+
                           "<span class=\"tag-id\">"+escHtml(id)+"</span>"+
                           "<span class=\"tag-time\">"+ts+"</span>"+
                           "<span class=\"tag-reads\" id=\"reads-"+idx+"\">1x</span>";
            list.appendChild(row);
            list.scrollTop=list.scrollHeight;
            updateStats();
            log("[NEW] "+id);
        }

        function closeSession() {
            _sessionOpen=false; setStatus("ready");
            var dur=_scanStart?(((Date.now()-_scanStart)/1000).toFixed(1)):"0";
            log("[DONE] Session closed -- "+_tags.length+" unique / "+_totalReads+" total in "+dur+"s");
            updateDuration();
        }

        function updateStats() {
            document.getElementById("cntUnique").innerText=_tags.length;
            document.getElementById("cntTotal").innerText=_totalReads;
            document.getElementById("cntDupe").innerText=_dupeReads;
            document.getElementById("tLast").innerText=timeStr();
            if (_scanStart) document.getElementById("tStart").innerText=new Date(_scanStart).toTimeString().split(" ")[0];
            updateDuration();
        }
        function updateDuration() {
            if (!_scanStart||!_lastTagTime) return;
            var dur=((_lastTagTime-_scanStart)/1000).toFixed(1);
            document.getElementById("tDuration").innerText=dur+"s";
            document.getElementById("tRate").innerText=dur>0?(_totalReads/dur).toFixed(1):"0";
        }
        function setStatus(s) {
            var pill=document.getElementById("statusPill"), dot=document.getElementById("pulseDot");
            if (s==="scanning") { pill.className="status-pill status-scanning"; pill.innerHTML="&#9654; SCANNING"; dot.style.background="#38bdf8"; }
            else if (s==="paused") { pill.className="status-pill status-paused"; pill.innerHTML="&#9646;&#9646; PAUSED"; dot.style.background="#f97316"; }
            else { pill.className="status-pill status-ready"; pill.innerHTML="&#9711; READY"; dot.style.background="#10b981"; }
        }
        function log(msg) {
            var box=document.getElementById("logBox"), line=document.createElement("div");
            line.className="log-line";
            line.innerHTML="<span class=\"log-ts\">"+timeStr()+"</span><span class=\"log-msg\">"+escHtml(msg)+"</span>";
            box.appendChild(line); box.scrollTop=box.scrollHeight;
        }
        function timeStr() { return new Date().toTimeString().split(" ")[0]; }
        function escHtml(s) { return String(s||"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;"); }
        function clearAll() {
            _tags=[]; _tagMap={}; _totalReads=0; _dupeReads=0;
            _scanStart=null; _lastTagTime=null; _sessionOpen=false;
            clearTimeout(_sessionTimer);
            document.getElementById("tagList").innerHTML="<div class=\"empty-msg\" id=\"emptyMsg\">Pull the RFD40 trigger to start scanning...</div>";
            ["cntUnique","cntTotal","cntDupe"].forEach(function(id){document.getElementById(id).innerText="0";});
            ["tStart","tLast"].forEach(function(id){document.getElementById(id).innerText="--:--:--";});
            document.getElementById("tDuration").innerText="0.0s";
            document.getElementById("tRate").innerText="0";
            setStatus("ready"); log("[CLEAR] All tags cleared");
            document.getElementById("raw").focus();
        }
        function exportCsv() {
            if (!_tags.length){alert("No tags to export.");return;}
            var csv="Seq,TagID,Reads,FirstSeen,LastSeen\n";
            _tags.forEach(function(t,i){csv+=(i+1)+',"'+t.id+'",'+t.reads+","+t.firstSeen+","+t.lastSeen+"\n";});
            var blob=new Blob([csv],{type:"text/csv;charset=utf-8;"}), url=URL.createObjectURL(blob);
            var a=document.createElement("a"); a.href=url; a.download="RFID_"+timeStr().replace(/:/g,"-")+".csv";
            document.body.appendChild(a); a.click(); document.body.removeChild(a);
        }
    </script>
</body>
</html>