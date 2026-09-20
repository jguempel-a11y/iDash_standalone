<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_fixed_reader_live.aspx.cs" Inherits="va_fixed_reader_live" %>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8" />
<title>Fixed Reader Live Feed — iDash</title>
<link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet" />
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
:root{--bg:#0a0f1a;--surface:#111827;--surface2:#1a2235;--line:#1e2d42;--text:#e2e8f0;--muted:#64748b;--accent:#3b82f6;--green:#10b981;--amber:#f59e0b;--red:#ef4444;--purple:#8b5cf6;--cyan:#06b6d4;--glow-new:rgba(16,185,129,.18);--glow-loc:rgba(59,130,246,.18);}
[data-theme="light"]{--bg:#f1f5f9;--surface:#ffffff;--surface2:#f8fafc;--line:#e2e8f0;--text:#0f172a;--muted:#64748b;--glow-new:rgba(16,185,129,.12);--glow-loc:rgba(59,130,246,.12);}
html,body{height:100%;font-family:'Inter',sans-serif;background:var(--bg);color:var(--text);overflow:hidden;}
.app{display:grid;grid-template-rows:56px 1fr;grid-template-columns:310px 1fr;height:100vh;}
.topbar{grid-column:1/-1;display:flex;align-items:center;gap:14px;padding:0 20px;background:var(--surface);border-bottom:1px solid var(--line);}
.sidebar{grid-row:2;overflow-y:auto;background:var(--surface);border-right:1px solid var(--line);padding:16px;}
.main{grid-row:2;display:flex;flex-direction:column;overflow:hidden;}
.topbar-logo{font-size:17px;font-weight:800;color:var(--accent);letter-spacing:-.5px;display:flex;align-items:center;gap:8px;}
.live-dot{width:9px;height:9px;border-radius:50%;background:var(--green);box-shadow:0 0 10px var(--green);animation:pulse 2s infinite;flex-shrink:0;}
.live-dot.off{background:var(--red);box-shadow:0 0 8px var(--red);animation:none;}
@keyframes pulse{0%,100%{opacity:1;}50%{opacity:.4;}}
.sep{width:1px;height:24px;background:var(--line);}
.kpi{display:flex;flex-direction:column;align-items:center;min-width:72px;}
.kpi-val{font-size:20px;font-weight:800;font-family:'JetBrains Mono',monospace;line-height:1;}
.kpi-val.g{color:var(--green);}.kpi-val.a{color:var(--amber);}.kpi-val.b{color:var(--accent);}
.kpi-lbl{font-size:10px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-top:2px;}
.tr{margin-left:auto;display:flex;align-items:center;gap:9px;}
.btn{display:inline-flex;align-items:center;gap:6px;padding:6px 13px;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;border:1px solid;transition:all .15s;white-space:nowrap;font-family:inherit;}
.bg{background:transparent;border-color:var(--line);color:var(--muted);}.bg:hover{border-color:var(--accent);color:var(--accent);}
.bamb{background:color-mix(in srgb,var(--amber) 15%,transparent);border-color:var(--amber);color:var(--amber);}
.bgrn{background:color-mix(in srgb,var(--green) 15%,transparent);border-color:var(--green);color:var(--green);}
.back{font-size:12px;color:var(--muted);text-decoration:none;}.back:hover{color:var(--text);}
.sb-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.8px;margin-bottom:12px;}
.r-block{margin-bottom:12px;border:1px solid var(--line);border-radius:10px;overflow:hidden;}
.r-hdr{display:flex;align-items:center;gap:8px;padding:10px 12px;background:var(--surface2);cursor:pointer;user-select:none;}
.r-hdr:hover{background:color-mix(in srgb,var(--accent) 8%,var(--surface2));}
.rstat{width:8px;height:8px;border-radius:50%;flex-shrink:0;}
.rstat.on{background:var(--green);box-shadow:0 0 6px var(--green);}.rstat.off{background:var(--muted);}
.rname{font-size:13px;font-weight:700;flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.rcheck{margin-left:auto;}.rcheck input{width:15px;height:15px;accent-color:var(--accent);cursor:pointer;}
.ant-list{padding:8px 12px 10px;display:flex;flex-direction:column;gap:6px;border-top:1px solid var(--line);}
.ant-row{display:flex;align-items:center;gap:8px;}
.ant-row input{width:14px;height:14px;accent-color:var(--green);cursor:pointer;}
.ant-lbl{font-size:12px;color:var(--muted);flex:1;}
.ant-port{font-size:10px;font-weight:700;font-family:'JetBrains Mono',monospace;color:var(--purple);background:color-mix(in srgb,var(--purple) 12%,transparent);border-radius:4px;padding:1px 5px;}
.last-rd{font-size:10px;font-family:'JetBrains Mono',monospace;color:var(--green);background:color-mix(in srgb,var(--green) 10%,transparent);border-radius:4px;padding:1px 6px;opacity:0;transition:opacity .3s;}
.last-rd.show{opacity:1;}
.wall-row{display:flex;align-items:center;gap:8px;padding:10px 4px;margin-bottom:6px;}
.wall-row label{font-size:12px;font-weight:600;color:var(--muted);}
.tgl{position:relative;width:38px;height:20px;}
.tgl input{opacity:0;width:0;height:0;}
.tgl-sl{position:absolute;inset:0;background:var(--line);border-radius:20px;transition:.2s;cursor:pointer;}
.tgl-sl::before{content:'';position:absolute;width:14px;height:14px;left:3px;top:3px;background:#fff;border-radius:50%;transition:.2s;}
.tgl input:checked+.tgl-sl{background:var(--accent);}
.tgl input:checked+.tgl-sl::before{transform:translateX(18px);}
.feed-hdr{display:flex;align-items:center;gap:12px;padding:10px 18px;border-bottom:1px solid var(--line);background:var(--surface);flex-shrink:0;}
.feed-title{font-size:13px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;}
.feed-badge{font-size:11px;font-weight:700;background:color-mix(in srgb,var(--accent) 15%,transparent);color:var(--accent);border:1px solid color-mix(in srgb,var(--accent) 30%,transparent);border-radius:20px;padding:2px 10px;}
.feed-badge.paused{background:color-mix(in srgb,var(--amber) 15%,transparent);color:var(--amber);border-color:color-mix(in srgb,var(--amber) 30%,transparent);}
.col-hdr{display:grid;grid-template-columns:68px 130px 1fr 150px 48px 76px;padding:6px 18px;background:var(--surface2);border-bottom:1px solid var(--line);font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;flex-shrink:0;}
.feed-scroll{flex:1;overflow-y:auto;}.feed-scroll::-webkit-scrollbar{width:4px;}.feed-scroll::-webkit-scrollbar-thumb{background:var(--line);border-radius:4px;}
.feed-row{display:grid;grid-template-columns:68px 130px 1fr 150px 48px 76px;padding:9px 18px;border-bottom:1px solid color-mix(in srgb,var(--line) 40%,transparent);align-items:center;font-size:13px;transition:background .4s;}
.feed-row.fn{background:var(--glow-new)!important;}.feed-row.fl{background:var(--glow-loc)!important;}
.feed-row.fv{background:color-mix(in srgb,#f59e0b 12%,transparent)!important;}  /* visitor = orange tint */
.feed-row:hover{background:color-mix(in srgb,var(--accent) 5%,transparent);}
.feed-row.even{background:color-mix(in srgb,var(--surface2) 50%,transparent);}
.ct{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--muted);}
.ce{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--purple);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.ca{font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding-right:10px;}
.can{font-size:12px;color:var(--cyan);}
.cp{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--muted);text-align:center;}
.tn{font-size:10px;font-weight:700;background:color-mix(in srgb,var(--green) 15%,transparent);color:var(--green);border-radius:5px;padding:1px 6px;border:1px solid color-mix(in srgb,var(--green) 30%,transparent);}
.tm{font-size:10px;font-weight:700;background:color-mix(in srgb,var(--accent) 15%,transparent);color:var(--accent);border-radius:5px;padding:1px 6px;border:1px solid color-mix(in srgb,var(--accent) 30%,transparent);}
.ts{font-size:10px;font-weight:700;background:color-mix(in srgb,var(--muted) 12%,transparent);color:var(--muted);border-radius:5px;padding:1px 6px;border:1px solid color-mix(in srgb,var(--muted) 20%,transparent);}
@keyframes slideIn{from{opacity:0;transform:translateX(-12px);}to{opacity:1;transform:translateX(0);}}
.ni{animation:slideIn .22s ease-out;}
.empty{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;gap:14px;color:var(--muted);}
.empty-icon{font-size:52px;opacity:.25;}.empty-msg{font-size:15px;font-weight:600;}.empty-sub{font-size:13px;text-align:center;max-width:300px;line-height:1.6;}
.sbar{padding:5px 18px;background:var(--surface);border-top:1px solid var(--line);font-size:11px;color:var(--muted);display:flex;align-items:center;gap:16px;flex-shrink:0;}
.sd{width:6px;height:6px;border-radius:50%;background:var(--green);display:inline-block;margin-right:4px;}
.sd.red{background:var(--red);}
.sw{display:inline-flex;align-items:flex-end;gap:2px;height:14px;}
.sw span{width:3px;border-radius:2px;background:var(--green);animation:wv 1s ease-in-out infinite;}
.sw span:nth-child(1){animation-delay:0s;height:4px;}.sw span:nth-child(2){animation-delay:.15s;height:10px;}.sw span:nth-child(3){animation-delay:.3s;height:7px;}.sw span:nth-child(4){animation-delay:.15s;height:12px;}.sw span:nth-child(5){animation-delay:0s;height:4px;}
@keyframes wv{0%,100%{transform:scaleY(1);}50%{transform:scaleY(.3);}}
.sw.off span{animation:none;background:var(--muted);}
/* Asset Watch */
.watch-divider{border:0;border-top:1px solid var(--line);margin:16px 0 12px;}
.watch-hdr{display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;cursor:pointer;}
.watch-hdr:hover .sb-title{color:var(--accent);}
.watch-ta{width:100%;min-height:60px;max-height:120px;background:var(--surface2);border:1px solid var(--line);border-radius:8px;padding:8px 10px;font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--text);resize:vertical;line-height:1.5;}
.watch-ta::placeholder{color:var(--muted);}
.watch-btns{display:flex;gap:6px;margin-top:8px;}
.watch-btn{flex:1;padding:6px 0;border-radius:6px;font-size:11px;font-weight:700;cursor:pointer;border:1px solid;text-align:center;font-family:inherit;}
.watch-btn.primary{background:color-mix(in srgb,var(--accent) 15%,transparent);border-color:var(--accent);color:var(--accent);}
.watch-btn.primary:hover{background:color-mix(in srgb,var(--accent) 25%,transparent);}
.watch-btn.muted{background:transparent;border-color:var(--line);color:var(--muted);}
.watch-btn.muted:hover{border-color:var(--muted);}
.watch-list{margin-top:10px;display:flex;flex-direction:column;gap:4px;}
.wl-item{display:flex;flex-direction:column;gap:2px;padding:6px 8px;border-radius:6px;font-family:'JetBrains Mono',monospace;border:1px solid var(--line);background:var(--surface2);}
.wl-item.found{border-color:var(--green);background:color-mix(in srgb,var(--green) 8%,var(--surface2));}
.wl-dot{width:7px;height:7px;border-radius:50%;flex-shrink:0;}
.wl-dot.waiting{background:var(--amber);}
.wl-dot.found{background:var(--green);box-shadow:0 0 6px var(--green);}
.wl-name{font-size:11px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:170px;}
.wl-status{font-size:10px;font-weight:600;white-space:nowrap;}
.wl-status.waiting{color:var(--amber);}
.wl-status.found{color:var(--green);}
.wl-time{font-size:9px;color:var(--muted);display:block;margin-top:2px;word-break:break-all;white-space:normal;}
/* Feed row: watched asset found */
.feed-row.fw{background:color-mix(in srgb,#f59e0b 14%,transparent)!important;border-left:3px solid #f59e0b;}
.tw{font-size:10px;font-weight:700;background:color-mix(in srgb,#f59e0b 20%,transparent);color:#d97706;border-radius:5px;padding:1px 6px;border:1px solid color-mix(in srgb,#f59e0b 40%,transparent);}
.watch-count{font-size:10px;font-weight:700;background:color-mix(in srgb,var(--accent) 15%,transparent);color:var(--accent);border-radius:10px;padding:1px 7px;}
</style>
</head>
<body>
<div class="app">
  <header class="topbar">
    <div class="topbar-logo"><span class="live-dot" id="cd"></span>Fixed Reader Live Feed</div>
    <div class="sep"></div>
    <div class="kpi"><div class="kpi-val g" id="kRpm">0</div><div class="kpi-lbl">reads/min</div></div>
    <div class="kpi"><div class="kpi-val b" id="kSess">0</div><div class="kpi-lbl">session reads</div></div>
    <div class="kpi"><div class="kpi-val a" id="kUniq">0</div><div class="kpi-lbl">unique assets</div></div>
    <div class="kpi"><div class="kpi-val" id="kRdrs">0</div><div class="kpi-lbl">active readers</div></div>
    <div class="tr">
      <button class="btn bg" id="bSnd" onclick="toggleSound()"><span class="sw off" id="sw"><span></span><span></span><span></span><span></span><span></span></span> Sound</button>
      <button class="btn bamb" id="bPause" onclick="togglePause()">⏸ Pause</button>
      <button class="btn bg" onclick="clearFeed()">🗑 Clear</button>
      <div class="sep"></div>
      <a href="va_asset_master.aspx" class="btn bg" style="font-size:11px;padding:4px 10px;">Asset Master</a>
      <a href="va_fixed_reader.aspx" class="btn bg" style="font-size:11px;padding:4px 10px;">Dashboard</a>
      <div class="sep"></div>
      <a href="va_reader_config.aspx" class="btn bg" style="font-size:11px;padding:4px 10px;">&#9881; Config</a>
      <a href="documentation/va_fixed_reader.html" class="btn bg" style="font-size:11px;padding:4px 10px;">Docs</a>
      <a href="index.aspx" class="btn bg" style="font-size:11px;padding:4px 10px;">Hub</a>
      <button class="btn bg" id="bThm" onclick="toggleTheme()" style="font-size:11px;padding:4px 10px;">☀ Light</button>
    </div>
  </header>

  <aside class="sidebar">
    <div class="sb-title">Readers &amp; Antennas</div>
    <div class="wall-row">
      <label class="tgl"><input type="checkbox" id="wAll" checked onchange="onWatchAll()" /><span class="tgl-sl"></span></label>
      <label for="wAll">Watch All</label>
    </div>
    <div id="rList"></div>

    <hr class="watch-divider" />
    <div class="watch-hdr" onclick="toggleWatchPanel()">
      <div class="sb-title" style="margin-bottom:0;">🔍 Asset Watch List <span class="watch-count" id="wCount" style="display:none;">0</span></div>
      <span id="wChev" style="font-size:12px;color:var(--muted);transition:transform .2s;">▼</span>
    </div>
    <div id="watchPanel">
      <textarea class="watch-ta" id="wInput" placeholder="Enter asset numbers to watch...&#10;One per line or comma-separated&#10;e.g. 400-12345, 400-67890"></textarea>
      <div class="watch-btns">
        <button type="button" class="watch-btn primary" onclick="activateWatch()">🔍 Watch</button>
        <button type="button" class="watch-btn muted" onclick="clearWatch()">✕ Clear</button>
      </div>
      <div class="watch-list" id="wList"></div>
      <div id="watchActions" style="display:none;margin-top:8px;padding-top:8px;border-top:1px solid var(--line);">
        <div style="font-size:10px;color:var(--muted);margin-bottom:6px;">Found assets actions:</div>
        <div style="display:flex;flex-direction:column;gap:4px;">
          <button type="button" class="watch-btn primary" style="font-size:11px;padding:5px 8px;" onclick="exportWatchCsv()">📥 Export Found to CSV</button>
          <button type="button" class="watch-btn primary" style="font-size:11px;padding:5px 8px;background:color-mix(in srgb,var(--green) 15%,transparent);color:var(--green);border-color:var(--green);" onclick="openFoundInMaster()">📋 Open in Asset Master</button>
        </div>
      </div>
    </div>
  </aside>

  <main class="main">
    <div class="feed-hdr">
      <span class="feed-title">Live Tag Reads</span>
      <span class="feed-badge" id="fBadge">LIVE</span>
      <label style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--muted);margin-left:auto;">
        <input type="checkbox" id="aScroll" checked style="accent-color:var(--accent);" /> Auto-scroll
      </label>
    </div>
    <div class="col-hdr"><span>Time</span><span>EPC</span><span>Asset</span><span>Antenna / Location</span><span style="text-align:center">Port</span><span>Status</span></div>
    <div class="feed-scroll" id="fScroll">
      <div class="empty" id="emSt">
        <div class="empty-icon">📡</div>
        <div class="empty-msg">Waiting for tag reads&hellip;</div>
        <div class="empty-sub">Select readers and antennas on the left, then bring a tagged asset near an antenna.</div>
      </div>
    </div>
    <div class="sbar">
      <span><span class="sd" id="sDot"></span><span id="sTxt">Connecting…</span></span>
      <span id="sSeq">seq: 0</span>
      <span id="sBuf">rows: 0</span>
      <span style="margin-left:auto;font-size:10px;">iDash Fixed Reader Live Feed — SSE</span>
    </div>
  </main>
</div>

<script>
const RD = <%=ReadersJson%>;
// null = admin (all companies). Array = restricted to these company IDs.
const ALLOWED_COS = <%=AllowedCompanyIdsJson%>;

let es=null,paused=false,soundOn=false,lastSeq=0,sessReads=0,uniqA=new Set(),actRdrs=new Set(),rowN=0,rpm=[],watchAll=true,selR=new Set(),selA=new Set(),badges={};
let watchAssets=new Set(), watchResults=new Map(), watchPanelOpen=true;
const MAX=200;

window.addEventListener('DOMContentLoaded',()=>{buildSB();applyTheme(localStorage.getItem('idash-theme')||'dark');loadWatch();startSSE();});

function buildSB(){
  const c=document.getElementById('rList');c.innerHTML='';
  RD.forEach(r=>{
    selR.add(r.id);
    r.antennas.forEach(a=>selA.add(r.id+':'+a.port));
    let aH='';
    if(r.antennas.length){
      aH='<div class="ant-list" id="al-'+r.id+'">';
      r.antennas.forEach(a=>{
        aH+=`<div class="ant-row"><input type="checkbox" id="a-${r.id}-${a.port}" checked onchange="onAnt(${r.id},${a.port},this.checked)"/>
          <label class="ant-lbl" for="a-${r.id}-${a.port}">${a.location}</label>
          <span class="ant-port">P${a.port}</span>
          <span class="last-rd" id="bd-${r.id}-${a.port}">✓</span></div>`;
      });
      aH+='</div>';
    } else aH='<div class="ant-list"><span style="font-size:11px;color:var(--muted)">No antennas configured</span></div>';
    const b=document.createElement('div');b.className='r-block';
    b.innerHTML=`<div class="r-hdr" onclick="togAL(${r.id})"><span class="rstat ${r.online?'on':'off'}" id="rs-${r.id}"></span>
      <span class="rname">${r.name||r.physicalId}</span>
      <span class="rcheck"><input type="checkbox" id="rc-${r.id}" checked onchange="onRdr(${r.id},this.checked)" onclick="event.stopPropagation()"/></span></div>${aH}`;
    c.appendChild(b);
  });
  RD.forEach(r=>r.antennas.forEach(a=>{badges[r.id+':'+a.port]=document.getElementById('bd-'+r.id+'-'+a.port);}));
}
function togAL(id){const e=document.getElementById('al-'+id);if(e)e.style.display=e.style.display==='none'?'':'none';}
function onRdr(id,chk){
  if(chk)selR.add(id);else selR.delete(id);
  RD.filter(r=>r.id===id).forEach(r=>r.antennas.forEach(a=>{const cb=document.getElementById('a-'+id+'-'+a.port);if(cb){cb.checked=chk;onAnt(id,a.port,chk,true);}}));
  watchAll=false;document.getElementById('wAll').checked=false;restartSSE();
}
function onAnt(rid,port,chk,skipRestart){
  const k=rid+':'+port;if(chk)selA.add(k);else selA.delete(k);
  watchAll=false;document.getElementById('wAll').checked=false;if(!skipRestart)restartSSE();
}
function onWatchAll(){
  watchAll=document.getElementById('wAll').checked;
  if(watchAll){
    // Re-check all readers and antennas
    RD.forEach(r=>{const cb=document.getElementById('rc-'+r.id);if(cb)cb.checked=true;
      selR.add(r.id);
      r.antennas.forEach(a=>{const ac=document.getElementById('a-'+r.id+'-'+a.port);if(ac)ac.checked=true;
        selA.add(r.id+':'+a.port);});});
  }
  // When unchecked: leave individual selections as-is, just set watchAll=false
  restartSSE();
}
function buildUrl(){
  const p=new URLSearchParams();p.set('seq',lastSeq);
  if(!watchAll){const rids=[...selR].join(','),aps=[...selA].map(k=>k.split(':')[1]).join(',');if(rids)p.set('readers',rids);if(aps)p.set('antennas',aps);}
  // Scope by company: if null=admin skip param; if array, send IDs (empty array = no access)
  if(ALLOWED_COS !== null) p.set('companies', Array.isArray(ALLOWED_COS) ? ALLOWED_COS.join(',') : '');
  return 'va_live_feed.ashx?'+p;
}
function startSSE(){setSt('connecting');es=new EventSource(buildUrl());
  es.onopen=()=>setSt('connected');
  es.onmessage=e=>{try{const d=JSON.parse(e.data);if(d.reconnect){lastSeq=d.seq;restartSSE();return;}if(!paused)onRead(d);if(d.seq>lastSeq)lastSeq=d.seq;}catch{}};
  es.onerror=()=>{setSt('reconnecting');document.getElementById('cd').className='live-dot off';};}
function stopSSE(){if(es){es.close();es=null;}}
function restartSSE(){stopSSE();setTimeout(startSSE,200);}

function onRead(ev){
  sessReads++;uniqA.add(ev.assetId||ev.epc);actRdrs.add(ev.readerId);
  const now=Date.now();rpm.push(now);rpm=rpm.filter(t=>now-t<60000);
  document.getElementById('kRpm').textContent=rpm.length;
  document.getElementById('kSess').textContent=sessReads;
  document.getElementById('kUniq').textContent=uniqA.size;
  document.getElementById('kRdrs').textContent=actRdrs.size;
  document.getElementById('sSeq').textContent='seq: '+ev.seq;
  const rs=document.getElementById('rs-'+ev.readerId);if(rs)rs.className='rstat on';
  const bk=ev.readerId+':'+ev.antennaPort,bd=badges[bk];
  if(bd){bd.classList.add('show');bd.textContent=fmtT(ev.ts);clearTimeout(bd._t);bd._t=setTimeout(()=>bd.classList.remove('show'),3000);}
  var isWatched=checkWatchList(ev);
  if(soundOn){try{const ctx=window._ac||(window._ac=new(window.AudioContext||window.webkitAudioContext)()),o=ctx.createOscillator(),g=ctx.createGain();o.connect(g);g.connect(ctx.destination);o.frequency.value=isWatched?1100:(ev.locationChanged?880:660);g.gain.setValueAtTime(isWatched?.12:.06,ctx.currentTime);g.gain.exponentialRampToValueAtTime(.001,ctx.currentTime+(isWatched?.15:.08));o.start();o.stop(ctx.currentTime+(isWatched?.15:.08));}catch{}}
  addRow(ev,isWatched);
}
function addRow(ev,isWatched){
  const feed=document.getElementById('fScroll'),em=document.getElementById('emSt');if(em)em.remove();
  const rows=feed.querySelectorAll('.feed-row');if(rows.length>=MAX)rows[rows.length-1].remove();
  const row=document.createElement('div');rowN++;
  const isVisitor=ev.isCrossSite===true||ev.isCrossSite==='true';
  const fc=isWatched?'fw':(isVisitor?'fv':(ev.locationChanged?'fl':'fn'));
  row.className='feed-row ni '+(rowN%2?'':'even')+' '+fc;
  let tag;
  if(isWatched){
    tag='<span class="tw">🎯 Watched</span>';
  } else if(isVisitor){
    const site=ev.assetSiteName||('Site '+ev.assetCompanyId)||'Other site';
    tag=`<span class="tn" style="background:color-mix(in srgb,#f59e0b 20%,transparent);color:#d97706;border-color:#f59e0b;" title="${ev.description||''}">👁 ${site}</span>`;
  } else {
    tag=ev.locationChanged?'<span class="tm">📍 Moved</span>':(ev.assetId>0?'<span class="ts">Seen</span>':'<span class="tn">New</span>');
  }
  const assetDisplay=isVisitor
    ?`<span style="opacity:.7;font-style:italic;">${ev.assetName||ev.epc||'—'}</span>`
    :(isWatched?`<strong style="color:var(--amber);">${ev.assetName||ev.epc||'—'}</strong>`:`${ev.assetName||ev.epc||'—'}`);
  row.innerHTML=`<span class="ct">${fmtT(ev.ts)}</span><span class="ce" title="${ev.epc||''}">${ev.epc||'—'}</span>
    <span class="ca" title="${ev.description||ev.assetName||''}">${assetDisplay}</span>
    <span class="can" title="${ev.antennaName||''}">${ev.antennaName||('📡 '+ev.readerName)||'—'}</span>
    <span class="cp">${ev.antennaPort||'—'}</span><span>${tag}</span>`;
  feed.insertBefore(row,feed.firstChild);
  setTimeout(()=>row.classList.remove(fc,'ni'),1500);
  if(document.getElementById('aScroll').checked)feed.scrollTop=0;
  document.getElementById('sBuf').textContent='rows: '+feed.querySelectorAll('.feed-row').length;
}
function togglePause(){paused=!paused;const b=document.getElementById('bPause'),fb=document.getElementById('fBadge');
  b.textContent=paused?'▶ Resume':'⏸ Pause';b.className=paused?'btn bgrn':'btn bamb';
  fb.textContent=paused?'PAUSED':'LIVE';fb.className='feed-badge'+(paused?' paused':'');}
function clearFeed(){document.getElementById('fScroll').innerHTML='<div class="empty" id="emSt"><div class="empty-icon">📡</div><div class="empty-msg">Feed cleared</div><div class="empty-sub">Waiting for next tag read…</div></div>';sessReads=0;uniqA.clear();rpm=[];['kRpm','kSess','kUniq'].forEach(id=>document.getElementById(id).textContent='0');rowN=0;}
function toggleSound(){soundOn=!soundOn;document.getElementById('sw').className='sw'+(soundOn?'':' off');document.getElementById('bSnd').style.color=soundOn?'var(--green)':'';}
function setSt(s){const d=document.getElementById('sDot'),t=document.getElementById('sTxt'),cd=document.getElementById('cd');
  if(s==='connected'){d.className='sd';t.textContent='Connected — streaming live';cd.className='live-dot';}
  else if(s==='reconnecting'){d.className='sd red';t.textContent='Reconnecting…';cd.className='live-dot off';}
  else{d.className='sd red';t.textContent='Connecting…';cd.className='live-dot off';}}
function applyTheme(t){document.documentElement.setAttribute('data-theme',t);localStorage.setItem('idash-theme',t);document.getElementById('bThm').textContent=t==='dark'?'☀ Light':'🌙 Dark';}
function toggleTheme(){applyTheme(document.documentElement.getAttribute('data-theme')==='dark'?'light':'dark');}
function fmtT(iso){if(!iso)return'—';try{const d=new Date(iso);return d.toLocaleTimeString('en-US',{hour12:false,hour:'2-digit',minute:'2-digit',second:'2-digit'});}catch{return iso.substring(11,19);}}

// ── Asset Watch List ──────────────────────────────────────
function toggleWatchPanel(){
  watchPanelOpen=!watchPanelOpen;
  document.getElementById('watchPanel').style.display=watchPanelOpen?'':'none';
  document.getElementById('wChev').style.transform=watchPanelOpen?'':'rotate(-90deg)';
}
function loadWatch(){
  try{
    var saved=localStorage.getItem('idash-watch-list');
    if(saved){document.getElementById('wInput').value=saved;activateWatch(true);}
  }catch{}
}
function activateWatch(silent){
  var raw=document.getElementById('wInput').value;
  var items=raw.split(/[\n,]+/).map(function(s){return s.trim();}).filter(function(s){return s.length>0;});
  watchAssets.clear();watchResults.clear();
  items.forEach(function(a){
    var key=a.toUpperCase();
    watchAssets.add(key);
    watchResults.set(key,{name:a,found:false,time:null,location:null});
  });
  try{localStorage.setItem('idash-watch-list',raw);}catch{}
  renderWatchList();
  var cnt=document.getElementById('wCount');
  if(items.length>0){cnt.textContent=items.length;cnt.style.display='';}
  else{cnt.style.display='none';}
}
function clearWatch(){
  watchAssets.clear();watchResults.clear();
  document.getElementById('wInput').value='';
  document.getElementById('wList').innerHTML='';
  document.getElementById('wCount').style.display='none';
  try{localStorage.removeItem('idash-watch-list');}catch{}
}
function checkWatchList(ev){
  if(watchAssets.size===0)return false;
  var name=(ev.assetName||'').toUpperCase();
  var epc=(ev.epc||'').toUpperCase();
  var matched=false;
  watchAssets.forEach(function(key){
    if(name.indexOf(key)!==-1||epc.indexOf(key)!==-1||key.indexOf(name)!==-1){
      var r=watchResults.get(key);
      if(r&&!r.found){
        r.found=true;r.time=fmtT(ev.ts);r.fullTime=ev.ts||'';
        r.location=ev.antennaName||ev.readerName||'';
        r.epc=ev.epc||'';r.assetName=ev.assetName||r.name;
        r.description=ev.description||'';
        r.assignedLocation=ev.assignedLocation||'';
        renderWatchList();
      }
      matched=true;
    }
  });
  return matched;
}
function renderWatchList(){
  var el=document.getElementById('wList');el.innerHTML='';
  watchResults.forEach(function(r){
    var cls=r.found?'wl-item found':'wl-item';
    var dotCls=r.found?'wl-dot found':'wl-dot waiting';
    var statusTxt=r.found?'✅ Found':'🔍 Watching';
    var statusColor=r.found?'var(--green)':'var(--amber)';
    var html='<div class="'+cls+'">';
    html+='<div style="display:flex;align-items:center;gap:6px;">';
    html+='<span class="'+dotCls+'"></span>';
    html+='<span class="wl-name">'+r.name+'</span>';
    html+='<span style="font-size:10px;font-weight:600;color:'+statusColor+';white-space:nowrap;margin-left:auto;">'+statusTxt+'</span>';
    html+='</div>';
    if(r.found){
      html+='<div class="wl-time">'+r.time+' — '+r.location+'</div>';
      if(r.assignedLocation) html+='<div class="wl-time">📍 Assigned: '+r.assignedLocation+'</div>';
    }
    html+='</div>';
    el.innerHTML+=html;
  });
  // Show/hide actions based on whether any assets were found
  var hasFound=false;
  watchResults.forEach(function(r){if(r.found)hasFound=true;});
  var actEl=document.getElementById('watchActions');
  if(actEl)actEl.style.display=hasFound?'':'none';
}

// ── Watch List Export to CSV ─────────────────────────────────
function exportWatchCsv(){
  var rows=[['Asset Name','EPC','Status','Time Detected','Reader / Antenna','Assigned Location']];
  watchResults.forEach(function(r){
    rows.push([
      r.assetName||r.name,
      r.epc||'',
      r.found?'Found':'Not Found',
      r.found?(r.fullTime||r.time):'',
      r.found?(r.location||''):'',
      r.found?(r.assignedLocation||''):''
    ]);
  });
  var csv=rows.map(function(row){
    return row.map(function(c){return '"'+String(c).replace(/"/g,'""')+'"';}).join(',');
  }).join('\r\n');
  var blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});
  var url=URL.createObjectURL(blob);
  var a=document.createElement('a');
  a.href=url;
  a.download='WatchList-Found-'+new Date().toISOString().slice(0,10)+'.csv';
  a.click();
  URL.revokeObjectURL(url);
}

// ── Open Found Assets in Asset Master ────────────────────────
function openFoundInMaster(){
  var found=[];
  watchResults.forEach(function(r){
    if(r.found) found.push(r.assetName||r.name);
  });
  if(found.length===0){alert('No assets found yet. Wait for the reader to detect watched assets.');return;}
  // Store in sessionStorage so Asset Master can read it (avoids URL length limits)
  try{sessionStorage.setItem('idash-watch-filter',JSON.stringify(found));}catch{}
  window.open('va_asset_master.aspx?watchFilter=1','_blank');
}
</script>
</body>
</html>
