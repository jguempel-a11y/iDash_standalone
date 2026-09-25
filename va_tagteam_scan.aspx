<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_tagteam_scan.aspx.cs" Inherits="va_tagteam_scan" MaintainScrollPositionOnPostback="true" EnableEventValidation="false" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <title>Tag Team Scan - AssetWorx</title>
            <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
            <link rel="manifest" href="manifest.json" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
            <meta http-equiv="Pragma" content="no-cache" />
            <meta http-equiv="Expires" content="0" />
            <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
            <%-- PWA / Home Screen meta tags --%>
            <meta name="apple-mobile-web-app-capable" content="yes" />
            <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
            <meta name="apple-mobile-web-app-title" content="TagTeam Scan" />
            <meta name="mobile-web-app-capable" content="yes" />
            <meta name="theme-color" content="#0f172a" />
            <style>


                [data-theme="light"] {
                    --cal-filter: invert(0);
                }

                :root {
                    --cal-filter:   invert(1);
                }

                body {
                    background: var(--bg);
                    color: var(--text);
                    font-family: Segoe UI, sans-serif;
                    margin: 0;
                }

                .wrap {
                    max-width: 1400px;
                    margin: 30px auto;
                    padding: 0 20px;
                }

                .card {
                    background: var(--card);
                    border: 1px solid var(--line);
                    border-radius: 12px;
                    padding: 24px;
                    margin-bottom: 24px;
                    box-shadow: var(--shadow);
                }

                .h1 {
                    font-size: 24px;
                    font-weight: 700;
                    margin-bottom: 5px;
                }

                .sub {
                    color: var(--muted);
                    font-size: 14px;
                    margin-bottom: 20px;
                }

                .row {
                    display: flex;
                    gap: 15px;
                    align-items: flex-end;
                    flex-wrap: wrap;
                    margin-bottom: 15px;
                }

                .col {
                    display: flex;
                    flex-direction: column;
                    gap: 5px;
                }

                .lbl {
                    font-size: 12px;
                    font-weight: 600;
                    color: var(--muted);
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }

                .txt {
                    background: var(--chip);
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 10px 14px;
                    border-radius: 8px;
                    width: 100%;
                    outline: none;
                    transition: 0.2s;
                }

                .txt:focus {
                    border-color: var(--accent);
                }

                .btn {
                    padding: 10px 18px;
                    border-radius: 8px;
                    border: none;
                    color: #fff;
                    font-weight: 600;
                    cursor: pointer;
                }

                .btn-blue {
                    background: var(--accent);
                }

                .btn-green {
                    background: var(--accent-2);
                }

                .btn-red {
                    background: var(--danger);
                }

                .current-loc {
                    font-size: 28px;
                    font-weight: 800;
                    color: var(--accent-2);
                }

                .grid {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 15px;
                    font-size: 13px;
                }

                .grid th {
                    background: var(--chip);
                    text-align: left;
                    padding: 12px;
                    color: var(--muted);
                    border-bottom: 2px solid var(--line);
                }
                
                .grid th a {
                    color: inherit;
                    text-decoration: none;
                    display: block;
                }
                
                .grid th a:hover {
                    color: var(--accent);
                    text-decoration: underline;
                }

                .grid td {
                    padding: 10px;
                    border-bottom: 1px solid var(--line);
                }

                .grid input[type=text] {
                    background: var(--bg);
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 6px;
                    border-radius: 4px;
                    width: 100%;
                }

                .ok {
                    color: var(--ok-text);
                    padding: 10px;
                    background: color-mix(in srgb, var(--accent-2), transparent 85%);
                    border: 1px solid var(--accent-2);
                    border-radius: 8px;
                    margin-bottom: 15px;
                }

                .badge-saved {
                    background: var(--accent-2);
                    color: #000;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                }

                .badge-pending {
                    background: var(--accent);
                    color: #000;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                }

                .badge-404 {
                    background: var(--danger);
                    color: #fff;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                }

                .badge-flagged {
                    background: rgba(245, 158, 11, 0.15);
                    color: var(--warn-text);
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                    display: inline-block;
                    border: 1px solid var(--warn);
                }

                .badge-78-ignored {
                    background: rgba(139, 92, 246, 0.15);
                    color: #a78bfa;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                    display: inline-block;
                    border: 1px solid #8b5cf6;
                }

                .badge-status-warn {
                    background: rgba(249, 115, 22, 0.15);
                    color: #f97316;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                    display: inline-block;
                    border: 1px solid #f97316;
                }

                .status-bar {
                    display: flex;
                    justify-content: space-between;
                    background: var(--card);
                    padding: 8px 20px;
                    font-size: 13px;
                    border-bottom: 1px solid var(--line);
                }

                #connection-indicator {
                    font-size: 14px;
                    font-weight: 700;
                }

                .offline-card {
                    background: color-mix(in srgb, var(--danger), transparent 85%);
                    border: 1px solid var(--danger);
                    display: none;
                }

                /* Offline toast banner */
                #offline-toast {
                    display: none;
                    position: fixed;
                    bottom: 20px;
                    left: 50%;
                    transform: translateX(-50%);
                    background: var(--danger);
                    color: #fff;
                    font-weight: 700;
                    font-size: 14px;
                    padding: 12px 24px;
                    border-radius: 30px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.4);
                    z-index: 9999;
                    text-align: center;
                    animation: slideUp 0.3s ease;
                }
                #sync-toast {
                    display: none;
                    position: fixed;
                    bottom: 20px;
                    left: 50%;
                    transform: translateX(-50%);
                    background: var(--accent-2);
                    color: #000;
                    font-weight: 700;
                    font-size: 14px;
                    padding: 12px 24px;
                    border-radius: 30px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.4);
                    z-index: 9999;
                    cursor: pointer;
                    animation: slideUp 0.3s ease;
                }
                @keyframes slideUp {
                    from { opacity: 0; transform: translateX(-50%) translateY(20px); }
                    to   { opacity: 1; transform: translateX(-50%) translateY(0); }
                }

                /* Make standard date picker icon white for dark theme */
                ::-webkit-calendar-picker-indicator {
                    filter: var(--cal-filter);
                    cursor: pointer;
                }
            </style>
            <script>
                // ── Service Worker Registration ───────────────────────────────────────
                (function() {
                    if (!('serviceWorker' in navigator)) return;
                    navigator.serviceWorker.register('sw.js').then(function(reg) {
                        console.log('[TagTeam] SW registered, scope:', reg.scope);
                        if (reg.waiting) reg.waiting.postMessage({ type: 'SKIP_WAITING' });
                    }).catch(function(err) {
                        console.warn('[TagTeam] SW registration failed:', err);
                    });
                })();

                // ── Constants ──────────────────────────────────────────────────────
                const OFFLINE_KEY    = 'TagTeam_OfflineQueue';
                const OFFLINE_LOC    = 'TagTeam_CurrentLocation';  // persisted location
                const OFFLINE_SITE   = 'TagTeam_SelectedSite';     // persisted site ID
                const OFFLINE_SITETX = 'TagTeam_SelectedSiteText'; // persisted site Name
                const OFFLINE_EMPL   = 'TagTeam_SelectedOperator'; // persisted operator
                const OFFLINE_TAGTYPE = 'TagTeam_SelectedTagType'; // persisted tag type / label size
                const PING_TIMEOUT   = 3000;                        // ms before treating as offline
                let   _isOnline      = navigator.onLine;            // start with browser's best guess
                let   _probeInFlight = false;
                let   _probeTimer    = null;                         // safety timer for stuck probes

                // ── Connectivity Probe ─────────────────────────────────────────────
                // Probes the actual server using XMLHttpRequest (not fetch) to avoid
                // the Service Worker intercepting and serving from cache.
                // XHR with a short timeout is the most reliable way to detect if the
                // server is truly reachable.
                function probeConnectivity() {
                    // Safety: if a probe has been in-flight for more than 5s, assume it died
                    if (_probeInFlight) {
                        if (_probeTimer) return Promise.resolve(_isOnline);
                        // First time seeing a stuck probe — force reset after 5s
                        _probeTimer = setTimeout(function() {
                            _probeInFlight = false;
                            _probeTimer = null;
                            console.log('[TagTeam] Probe in-flight timeout — force reset');
                        }, 5000);
                        return Promise.resolve(_isOnline);
                    }
                    _probeInFlight = true;

                    return new Promise(function(resolve) {
                        var xhr = new XMLHttpRequest();
                        xhr.timeout = PING_TIMEOUT;
                        xhr.open('HEAD', 'va_tagteam_scan.aspx?_nocache=' + Date.now(), true);
                        xhr.onload  = function() { _probeInFlight = false; clearTimeout(_probeTimer); _probeTimer = null; resolve(xhr.status >= 200 && xhr.status < 400); };
                        xhr.onerror = function() { _probeInFlight = false; clearTimeout(_probeTimer); _probeTimer = null; resolve(false); };
                        xhr.ontimeout = function() { _probeInFlight = false; clearTimeout(_probeTimer); _probeTimer = null; resolve(false); };
                        try { xhr.send(); } catch(e) { _probeInFlight = false; clearTimeout(_probeTimer); _probeTimer = null; resolve(false); }
                    });
                }

                function updateIndicator(online) {
                    _isOnline = online;
                    const indicator = document.getElementById('connection-indicator');
                    if (!indicator) return;
                    if (online) {
                        indicator.innerHTML = '&bull; CONNECTED';
                        indicator.style.color = 'var(--accent-2)';
                        hideToast('offline-toast');
                        // Show sync toast if there is a pending queue
                        const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                        if (queue.length > 0) showSyncToast(queue.length);
                    } else {
                        const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                        indicator.innerHTML = '&bull; OFFLINE &mdash; Scans queuing locally (' + queue.length + ' queued)';
                        indicator.style.color = 'var(--danger)';
                        showToast('offline-toast', '&#128683; OFFLINE &mdash; Scans are being saved locally');
                        hideToast('sync-toast');
                    }
                }

                function checkConnectivity() {
                    return probeConnectivity().then(online => {
                        updateIndicator(online);
                        return online;
                    });
                }

                // Re-probe when browser fires online/offline events
                // When the browser says we're back online, do an immediate probe
                // AND a second probe 1s later (some networks take a moment to stabilize)
                window.addEventListener('online',  function() {
                    console.log('[TagTeam] Browser fired "online" event — probing server...');
                    checkConnectivity();
                    setTimeout(checkConnectivity, 1000);
                    setTimeout(checkConnectivity, 3000);
                });
                window.addEventListener('offline', function() {
                    console.log('[TagTeam] Browser fired "offline" event');
                    updateIndicator(false);
                });

                // ── Toast Helpers ──────────────────────────────────────────────────
                function showToast(id, msg) {
                    let el = document.getElementById(id);
                    if (!el) return;
                    el.innerHTML = msg;
                    el.style.display = 'block';
                }
                function hideToast(id) {
                    const el = document.getElementById(id);
                    if (el) el.style.display = 'none';
                }
                function showSyncToast(count) {
                    showToast('sync-toast',
                        '&#9729; Back online! ' + count + ' offline scan(s) ready to sync &mdash; tap to sync now');
                    const el = document.getElementById('sync-toast');
                    if (el) el.onclick = syncScans;
                }

                // ── Offline Location, Site & Operator Persistence ─────────────────
                function persistLocation(loc) {
                    if (loc && loc !== '(None Set)') {
                        localStorage.setItem(OFFLINE_LOC, loc);
                    }
                }
                function restoreLocation() {
                    const lbl = document.getElementById('LblCurrentLocation');
                    if (!lbl) return;
                    const current = lbl.innerText.trim();
                    if (current === '' || current === '(None Set)') {
                        const saved = localStorage.getItem(OFFLINE_LOC);
                        if (saved) {
                            lbl.innerText = saved;
                            console.log('[TagTeam] Restored offline location from localStorage:', saved);
                        }
                    } else {
                        persistLocation(current);
                    }
                }
                function persistSite(siteVal, siteText) {
                    if (siteVal) {
                        localStorage.setItem(OFFLINE_SITE, siteVal);
                        if (siteText) localStorage.setItem(OFFLINE_SITETX, siteText);
                    }
                }
                function restoreSite() {
                    var ddl = document.getElementById('DdlCompany');
                    if (!ddl) return;
                    var savedVal = localStorage.getItem(OFFLINE_SITE);
                    if (savedVal && (!ddl.value || ddl.selectedIndex <= 0)) {
                        ddl.value = savedVal;
                        console.log('[TagTeam] Restored offline site:', savedVal);
                    } else if (ddl.value && ddl.selectedIndex > 0) {
                        var txt = ddl.options[ddl.selectedIndex].text || '';
                        persistSite(ddl.value, txt);
                    }
                }
                function persistOperator(emplVal) {
                    if (emplVal) localStorage.setItem(OFFLINE_EMPL, emplVal);
                }
                function restoreOperator() {
                    var ddl = document.getElementById('DdlEmpl');
                    if (!ddl) return;
                    var savedVal = localStorage.getItem(OFFLINE_EMPL);
                    if (savedVal && !ddl.value) {
                        ddl.value = savedVal;
                        console.log('[TagTeam] Restored offline operator:', savedVal);
                    } else if (ddl.value) {
                        persistOperator(ddl.value);
                    }
                }
                function persistTagType(typeVal) {
                    if (typeVal) {
                        localStorage.setItem(OFFLINE_TAGTYPE, typeVal);
                    }
                }
                function restoreTagType() {
                    var ddl = document.getElementById('DdlDefaultTagType');
                    if (!ddl) return;
                    var savedVal = localStorage.getItem(OFFLINE_TAGTYPE);
                    if (savedVal && (!ddl.value || ddl.value !== savedVal)) {
                        ddl.value = savedVal;
                        console.log('[TagTeam] Restored offline tag type:', savedVal);
                    } else if (ddl.value) {
                        persistTagType(ddl.value);
                    }
                }

                // ── Barcode Validation (client-side, mirrors server regex) ──────────
                // Physical tags always have a 3-digit station prefix across all VA sites (e.g. 512, 517, 540, 581, 613)
                // Substation is resolved via system lookup, not from the physical barcode.
                const BARCODE_REGEX = /^\d{3} EE\w+$/i;
                function validateBarcode(barcode) {
                    if (!barcode || !BARCODE_REGEX.test(barcode.trim())) {
                        return { valid: false, reason: 'Invalid barcode format: "' + barcode + '". Expected 3-digit station prefix + space + EE + asset ID (e.g. "613 EE123456" or "512 EE789012").' };
                    }
                    // Check prefix matches selected site (extract first 3 chars of company name)
                    var ddlSite = document.getElementById('DdlCompany');
                    var siteText = (ddlSite && ddlSite.selectedIndex > 0) ? (ddlSite.options[ddlSite.selectedIndex].text || '') : (localStorage.getItem(OFFLINE_SITETX) || '');
                    if (siteText) {
                        var sitePrefix = siteText.substring(0, 3);
                        var scanPrefix = barcode.substring(0, 3);
                        if (/^\d{3}$/.test(sitePrefix) && sitePrefix !== scanPrefix) {
                            return { valid: false, reason: 'WARNING: Prefix mismatch! Scanned prefix "' + scanPrefix + '" does not match selected site "' + siteText + '" (expected prefix ' + sitePrefix + '). Please verify you are scanning the correct site\'s assets.' };
                        }
                    }
                    return { valid: true };
                }

                // ── Offline Queue ──────────────────────────────────────────────────
                function saveOffline(barcode) {
                    // ── CLIENT-SIDE GUARDS (same rules as server) ──────────────────
                    var ddlSite = document.getElementById('DdlCompany');
                    var siteVal = (ddlSite && ddlSite.value) || localStorage.getItem(OFFLINE_SITE) || '';
                    if (!siteVal) {
                        alert('You must select a Site before scanning assets!');
                        if (ddlSite) ddlSite.focus();
                        return;
                    }
                    var ddlEmpl = document.getElementById('DdlEmpl');
                    var emplVal = (ddlEmpl && ddlEmpl.value) || localStorage.getItem(OFFLINE_EMPL) || '';
                    if (!emplVal) {
                        alert('You must select an Operator before scanning assets!');
                        if (ddlEmpl) ddlEmpl.focus();
                        return;
                    }
                    var lbl = document.getElementById('LblCurrentLocation');
                    var location = (lbl && lbl.innerText.trim() !== '' && lbl.innerText.trim() !== '(None Set)')
                        ? lbl.innerText.trim()
                        : (localStorage.getItem(OFFLINE_LOC) || '');
                    if (!location || location === '(None Set)') {
                        alert('You must scan a Location first before scanning assets!');
                        var locBox = document.getElementById('TxtLocationScan');
                        if (locBox) { locBox.value = ''; locBox.focus(); }
                        return;
                    }

                    var check = validateBarcode(barcode);
                    if (!check.valid) {
                        alert(check.reason);
                        var txtAsset = document.getElementById('TxtAssetScan');
                        if (txtAsset) { txtAsset.value = ''; txtAsset.focus(); }
                        return;
                    }

                    var defaultNotes = document.getElementById('TxtDefaultNotes');
                    var dateInput = document.getElementById('TxtCurrentDate');
                    var tagDateVal = (dateInput && dateInput.value) ? dateInput.value : new Date().toLocaleDateString('en-CA');
                    var tagTypeVal = (document.getElementById('DdlDefaultTagType') || {}).value || 'IQ350';

                    var queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    var cleanBc = barcode.trim().toUpperCase();

                    // Deduplicate: if barcode already in queue, update it in place
                    var existingIdx = queue.findIndex(function(x) { return (x.Barcode || '').toUpperCase() === cleanBc; });
                    var item = {
                        Barcode:   cleanBc,
                        Location:  location,
                        LocTagged: location,
                        CompanyId: siteVal,
                        EmplId:    emplVal,
                        TagType:   tagTypeVal,
                        Notes:     (defaultNotes ? defaultNotes.value : '') || 'Offline Scan',
                        TagDate:   tagDateVal,
                        Tagged:    false,
                        Status:    'Offline - Pending'
                    };

                    if (existingIdx >= 0) {
                        queue[existingIdx] = item;
                        console.log('[TagTeam] Updated existing offline queue item:', cleanBc);
                    } else {
                        queue.push(item);
                    }
                    localStorage.setItem(OFFLINE_KEY, JSON.stringify(queue));
                    updateOfflineUI();
                    updateIndicator(false);
                }

                function updateOfflineUI() {
                    const queue   = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    const card    = document.getElementById('pnlOffline');
                    const list    = document.getElementById('offline-list');
                    const btnSync = document.getElementById('btnSync');

                    if (queue.length > 0) {
                        card.style.display = 'block';
                        btnSync.style.display = 'inline-block';
                        list.innerHTML = queue.map(function(item, idx) {
                            return '<li style="display:flex; align-items:center; gap:8px; padding:4px 0; flex-wrap:wrap;">'
                                + '<strong>' + item.Barcode + '</strong>'
                                + ' &mdash; ' + item.Location
                                + ' <span style="color:var(--muted);font-size:11px;">(' + item.TagDate + ')</span>'
                                + ' <select onchange="editOfflineItem(' + idx + ', this.value)" '
                                + '  style="background:var(--chip);border:1px solid var(--line);color:var(--text);padding:3px 6px;border-radius:4px;font-size:11px;" '
                                + '  title="Change tag type">'
                                + '  <option value="IQ350"' + (item.TagType==='IQ350' ? ' selected' : '') + '>IQ350</option>'
                                + '  <option value="Large_Metal"' + (item.TagType==='Large_Metal' || item.TagType==='Metal_Large' ? ' selected' : '') + '>Large Metal</option>'
                                + '  <option value="Small_Standard"' + (item.TagType==='Small_Standard' || item.TagType==='Std_Small' ? ' selected' : '') + '>Small Standard</option>'
                                + '  <option value="Small_Metal"' + (item.TagType==='Small_Metal' ? ' selected' : '') + '>Small Metal</option>'
                                + '</select>'
                                + ' <button type="button" onclick="removeOfflineItem(' + idx + ')" '
                                + '  style="background:var(--danger);color:#fff;border:none;border-radius:4px;padding:2px 8px;font-size:11px;cursor:pointer;" '
                                + '  title="Remove this scan">X</button>'
                                + '</li>';
                        }).join('');
                    } else {
                        card.style.display = 'none';
                        btnSync.style.display = 'none';
                    }
                }

                // Edit tag type on an offline queue item
                function editOfflineItem(index, newTagType) {
                    var queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    if (queue[index]) {
                        queue[index].TagType = newTagType;
                        localStorage.setItem(OFFLINE_KEY, JSON.stringify(queue));
                        console.log('[TagTeam] Offline item ' + index + ' tag type changed to: ' + newTagType);
                    }
                }

                // Remove an offline queue item
                function removeOfflineItem(index) {
                    var queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    if (index >= 0 && index < queue.length) {
                        var removed = queue.splice(index, 1);
                        localStorage.setItem(OFFLINE_KEY, JSON.stringify(queue));
                        console.log('[TagTeam] Removed offline item:', removed[0].Barcode);
                        updateOfflineUI();
                        updateIndicator(_isOnline);
                    }
                }

                async function syncScans() {
                    const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    if (queue.length === 0) return;

                    hideToast('sync-toast');
                    const btnSync = document.getElementById('btnSync');
                    if (btnSync) { btnSync.disabled = true; btnSync.innerText = 'Syncing...'; }

                    try {
                        const resp = await fetch('va_tagteam_scan.aspx?action=sync', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(queue)
                        });

                        if (resp.ok) {
                            localStorage.removeItem(OFFLINE_KEY);
                            alert('Sync complete! ' + queue.length + ' scan(s) committed to the database.');
                            // Cache-bust the reload so the SW fetches fresh from server
                            window.location.href = 'va_tagteam_scan.aspx?_synced=' + Date.now();
                        } else {
                            const txt = await resp.text().catch(() => '');
                            alert('Sync failed (HTTP ' + resp.status + '). Will retry later.\n' + txt);
                            if (btnSync) { btnSync.disabled = false; btnSync.innerText = 'Sync Now'; }
                        }
                    } catch (e) {
                        alert('Error syncing (still offline?): ' + e.message);
                        if (btnSync) { btnSync.disabled = false; btnSync.innerText = 'Sync Now'; }
                    }
                }

                // ── Config Panel Toggle ────────────────────────────────────────────
                function toggleConfigPanel() {
                    const panel = document.getElementById('locationConfigPanel');
                    const btn   = document.getElementById('BtnToggleConfig');
                    if (!panel) return;
                    if (panel.style.display === 'none') {
                        panel.style.display = 'block';
                        if (btn) btn.innerHTML = '&#9881; Hide Config';
                        localStorage.setItem('aw_tagteam_config_hidden', 'false');
                    } else {
                        panel.style.display = 'none';
                        if (btn) btn.innerHTML = '&#9881; Show Config';
                        localStorage.setItem('aw_tagteam_config_hidden', 'true');
                    }
                }

                document.addEventListener('DOMContentLoaded', () => {
                    // ── Tag Date Stale Guard ──────────────────────────────────────
                    // Blocks scanning if the tag date is not today until user confirms
                    window._tagDateConfirmRequired = false;
                    (function initTagDateGuard() {
                        var dateInput = document.getElementById('TxtCurrentDate');
                        if (!dateInput) return;

                        function getTodayStr() {
                            return new Date().toLocaleDateString('en-CA'); // YYYY-MM-DD
                        }
                        function checkDateStale() {
                            var val = dateInput.value;
                            var today = getTodayStr();
                            var banner = document.getElementById('tagdate-warn-banner');
                            var confirmBtn = document.getElementById('tagdate-confirm-btn');
                            if (val && val !== today) {
                                // Date is stale — show warning and block scans
                                window._tagDateConfirmRequired = true;
                                dateInput.style.border = '2px solid var(--danger)';
                                dateInput.style.boxShadow = '0 0 8px rgba(239,68,68,0.4)';
                                if (banner) banner.style.display = 'block';
                                if (confirmBtn) confirmBtn.style.display = 'inline-block';
                                var bannerText = document.getElementById('tagdate-warn-text');
                                if (bannerText) bannerText.innerHTML = 'WARNING: Tag Date is set to <strong>' + val + '</strong> -- not today (' + today + '). Please confirm or update before scanning.';
                            } else {
                                // Date is today — clear warning
                                window._tagDateConfirmRequired = false;
                                dateInput.style.border = '';
                                dateInput.style.boxShadow = '';
                                if (banner) banner.style.display = 'none';
                                if (confirmBtn) confirmBtn.style.display = 'none';
                            }
                        }

                        // Check on load
                        checkDateStale();

                        // Re-check when user changes date
                        dateInput.addEventListener('change', function() {
                            checkDateStale();
                        });

                        // Confirm button handler
                        window.confirmTagDate = function() {
                            window._tagDateConfirmRequired = false;
                            dateInput.style.border = '2px solid var(--accent-2)';
                            dateInput.style.boxShadow = '0 0 8px rgba(16,185,129,0.3)';
                            var banner = document.getElementById('tagdate-warn-banner');
                            if (banner) banner.style.display = 'none';
                            var confirmBtn = document.getElementById('tagdate-confirm-btn');
                            if (confirmBtn) confirmBtn.style.display = 'none';
                            // Refocus scan box
                            var scanBox = document.getElementById('TxtAssetScan');
                            if (scanBox) scanBox.focus();
                        };
                    })();

                    // ── Auto-refocus scan input after every postback ──────────────
                    (function() {
                        var scanBox = document.getElementById('TxtAssetScan');
                        if (scanBox) {
                            scanBox.focus();
                            var v = scanBox.value;
                            scanBox.value = '';
                            scanBox.value = v;
                        }
                    })();

                    if (localStorage.getItem('aw_tagteam_config_hidden') === 'true') {
                        const panel = document.getElementById('locationConfigPanel');
                        if (panel) panel.style.display = 'none';
                        const btn = document.getElementById('BtnToggleConfig');
                        if (btn) btn.innerHTML = '&#9881; Show Config';
                    }

                    // Restore Site, Operator, Location, and TagType from localStorage
                    restoreSite();
                    restoreOperator();
                    restoreLocation();
                    restoreTagType();

                    // ── Enforce 4 clean standard tag types on client dropdown ──
                    (function sanitizeTagTypes() {
                        var ddl = document.getElementById('DdlDefaultTagType');
                        if (!ddl) return;
                        var standardTypes = ['IQ350', 'Large_Metal', 'Small_Standard', 'Small_Metal'];
                        var savedVal = localStorage.getItem(OFFLINE_TAGTYPE) || '';
                        var currentVal = ddl.value || savedVal || '';
                        var hasNonStandard = Array.from(ddl.options).some(function(opt) {
                            return standardTypes.indexOf(opt.value) === -1;
                        });

                        var normVal = currentVal;
                        if (normVal.indexOf('Metal') !== -1 || normVal.indexOf('Large') !== -1 || normVal === 'Large_Metal') normVal = 'Large_Metal';
                        else if (normVal.indexOf('Std') !== -1 || normVal.indexOf('Small_Standard') !== -1 || normVal === 'Small_Standard') normVal = 'Small_Standard';
                        else if (normVal === 'Small_Metal') normVal = 'Small_Metal';
                        else if (normVal.indexOf('IQ350') !== -1 || normVal === 'IQ350') normVal = 'IQ350';
                        else if (savedVal && standardTypes.indexOf(savedVal) !== -1) normVal = savedVal;
                        else normVal = 'IQ350';

                        if (hasNonStandard || ddl.options.length !== standardTypes.length || ddl.value !== normVal) {
                            ddl.innerHTML = standardTypes.map(function(t) {
                                return '<option value="' + t + '"' + (t === normVal ? ' selected="selected"' : '') + '>' + t + '</option>';
                            }).join('');
                            ddl.value = normVal;
                            persistTagType(normVal);
                            console.log('[TagTeam] Sanitized DdlDefaultTagType options to standard 4, active:', normVal);
                        }
                    })();

                    // Attach change listeners to persist Site, Operator, and TagType
                    var ddlSiteEl = document.getElementById('DdlCompany');
                    if (ddlSiteEl) {
                        ddlSiteEl.addEventListener('change', function() {
                            var txt = ddlSiteEl.selectedIndex > 0 ? (ddlSiteEl.options[ddlSiteEl.selectedIndex].text || '') : '';
                            persistSite(ddlSiteEl.value, txt);
                        });
                    }
                    var ddlEmplEl = document.getElementById('DdlEmpl');
                    if (ddlEmplEl) {
                        ddlEmplEl.addEventListener('change', function() {
                            persistOperator(ddlEmplEl.value);
                        });
                    }
                    var ddlTagTypeEl = document.getElementById('DdlDefaultTagType');
                    if (ddlTagTypeEl) {
                        ddlTagTypeEl.addEventListener('change', function() {
                            persistTagType(ddlTagTypeEl.value);
                            console.log('[TagTeam] User changed default tag type to:', ddlTagTypeEl.value);
                        });
                    }

                    // ── Scanner Enter Key (keydown 13) capture & safety net ──────
                    var scanBoxEl = document.getElementById('TxtAssetScan');
                    if (scanBoxEl) {
                        scanBoxEl.addEventListener('keydown', function(e) {
                            if (e.key === 'Enter' || e.keyCode === 13) {
                                if (!_isOnline || !navigator.onLine) {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    handleOfflineScan();
                                    return false;
                                } else {
                                    // Pre-stash barcode as insurance before form submits
                                    if (scanBoxEl.value.trim() !== '') {
                                        localStorage.setItem('TagTeam_PendingBarcode', scanBoxEl.value.trim());
                                    }
                                }
                            }
                        });
                    }

                    var locBoxEl = document.getElementById('TxtLocationScan');
                    if (locBoxEl) {
                        locBoxEl.addEventListener('keydown', function(e) {
                            if (e.key === 'Enter' || e.keyCode === 13) {
                                if (!_isOnline || !navigator.onLine) {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    handleOfflineScan();
                                    return false;
                                }
                            }
                        });
                    }

                    // Probe real connectivity (not just navigator.onLine)
                    checkConnectivity();
                    // Periodically probe real connectivity every 4 seconds to keep status fresh
                    setInterval(checkConnectivity, 4000);

                    // ── Recover barcode from a failed POST ──────────────────────────
                    // If the Service Worker caught a failed POST and returned the cached
                    // page shell, the barcode that was being scanned is saved in
                    // localStorage under 'TagTeam_PendingBarcode'. Queue it now.
                    var pendingBarcode = localStorage.getItem('TagTeam_PendingBarcode');
                    if (pendingBarcode) {
                        localStorage.removeItem('TagTeam_PendingBarcode');
                        console.log('[TagTeam] Recovered pending barcode after SW fallback:', pendingBarcode);
                        saveOffline(pendingBarcode);
                        updateIndicator(false);
                    }

                    updateOfflineUI();
                    initGridFilters();

                    function initGridFilters() {
                        const grid = document.getElementById('GridScans');
                        if (!grid) return;

                        const headers = grid.querySelectorAll('th');
                        if (headers.length === 0) return;
                        if (grid.querySelector('.col-filter')) return;

                        headers.forEach((th, index) => {
                            // Don't add filters to checkboxes or edit/remove buttons
                            let isControlCol = (index === 0 || index === headers.length - 1 || index === headers.length - 2);
                            if (isControlCol) return;

                            const input = document.createElement('input');
                            input.type = 'text';
                            input.className = 'col-filter txt';
                            input.style.width = '100%';
                            input.style.marginTop = '6px';
                            input.style.boxSizing = 'border-box';
                            input.style.padding = '4px 6px';
                            input.style.fontSize = '11px';
                            input.style.borderColor = 'var(--line)';
                            input.style.background = 'var(--bg)';
                            input.placeholder = 'Filter...';
                            input.setAttribute('data-col', index);
                            
                            input.addEventListener('keyup', filterGrid);
                            input.addEventListener('click', e => e.stopPropagation());
                            
                            th.appendChild(input);
                        });
                    }

                    function filterGrid() {
                        const grid = document.getElementById('GridScans');
                        if (!grid) return;
                        
                        const inputs = Array.from(grid.querySelectorAll('.col-filter'));
                        const rows = grid.querySelectorAll('tr:not(:first-child)'); // Skip header

                        const filters = inputs.map(input => ({
                            index: parseInt(input.getAttribute('data-col')),
                            text: input.value.toLowerCase().trim()
                        })).filter(f => f.text !== '');

                        rows.forEach(row => {
                            const cells = row.querySelectorAll('td');
                            let match = true;
                            
                            for (const filter of filters) {
                                if (cells[filter.index]) {
                                    // Specifically handle input boxes within editable cells
                                    const editInput = cells[filter.index].querySelector('input[type="text"], select');
                                    const cellText = editInput ? editInput.value.toLowerCase() : cells[filter.index].innerText.toLowerCase();
                                    
                                    if (cellText.indexOf(filter.text) === -1) {
                                        match = false;
                                        break;
                                    }
                                }
                            }
                            row.style.display = match ? '' : 'none';
                        });
                    }

                    function handleOfflineScan(eventTarget) {
                        // Handle location scan (typed into TxtLocationScan offline)
                        const locScan  = document.getElementById('TxtLocationScan');
                        const lbl      = document.getElementById('LblCurrentLocation');
                        if (locScan && locScan.value.trim() !== '') {
                            const newLoc = locScan.value.trim().toUpperCase();
                            if (!newLoc.startsWith("SP") || newLoc.indexOf("EE") !== -1) {
                                alert('Invalid Location format: "' + newLoc + '". Location barcodes must start with SP (e.g. SP...).');
                                locScan.value = '';
                                locScan.focus();
                                return;
                            }
                            if (lbl) lbl.innerText = newLoc;
                            const lblTotal = document.getElementById('LblLocationTotal');
                            if (lblTotal) lblTotal.style.display = 'none';
                            persistLocation(newLoc);  // persist so it survives reload
                            locScan.value = '';
                            // Automatically focus asset box
                            const txtAsset = document.getElementById('TxtAssetScan');
                            if (txtAsset) setTimeout(function() { txtAsset.focus(); }, 50);
                            return; // location set, done
                        }
                        // Handle asset barcode scan
                        const txtAsset = document.getElementById('TxtAssetScan');
                        if (txtAsset && txtAsset.value.trim() !== '') {
                            var bc = txtAsset.value.trim();
                            // ── Tag date stale check (offline) ─────────────────────
                            if (window._tagDateConfirmRequired) {
                                alert('WARNING: Tag Date has not been confirmed! Please verify or update the Tag Date before scanning.');
                                txtAsset.value = '';
                                return;
                            }
                            saveOffline(bc);
                            txtAsset.value = '';
                            // Refocus for next scan
                            setTimeout(function() { txtAsset.focus(); }, 50);
                            return; // barcode queued, done
                        }
                        // If we get here, the user clicked something else while offline
                        // (Edit, Update, Cancel, etc.) — show a helpful message
                        showToast('offline-toast',
                            '&#128683; OFFLINE &mdash; Editing grid rows requires a server connection. '
                            + 'You can still scan barcodes and edit tag types on queued items above.');
                    }

                    // ── Quick XHR Probe ──────────────────────────────────────────────
                    // Uses XMLHttpRequest because fetch() is intercepted by SW.
                    // XHR HEAD requests go through the SW too, BUT with our v6 SW they
                    // are bypassed for _nocache params. For old SWs, XHR HEAD still goes
                    // to network (old SW only intercepts GET, and HEAD !== GET).
                    function quickProbeXHR(timeoutMs) {
                        return new Promise(function(resolve) {
                            if (!navigator.onLine) return resolve(false);
                            // NOTE: Do NOT short-circuit on _isOnline here.
                            // When _isOnline is false (we think we're offline), we MUST
                            // still probe the server to discover recovery. Otherwise
                            // the page gets stuck in offline mode permanently.
                            var xhr = new XMLHttpRequest();
                            xhr.timeout = timeoutMs || 2000;
                            xhr.open('HEAD', 'va_tagteam_scan.aspx?_nocache=' + Date.now(), true);
                            xhr.onload    = function() { resolve(xhr.status >= 200 && xhr.status < 400); };
                            xhr.onerror   = function() { resolve(false); };
                            xhr.ontimeout = function() { resolve(false); };
                            try { xhr.send(); } catch(e) { resolve(false); }
                        });
                    }

                    // ══════════════════════════════════════════════════════════════════
                    // NUCLEAR OPTION: Intercept form.submit() directly.
                    // ASP.NET's __doPostBack() ultimately calls theForm.submit().
                    // By monkey-patching HTMLFormElement.prototype.submit, we guarantee
                    // that NO form can ever be submitted to the server when we know
                    // we're offline — regardless of which Service Worker version is
                    // active.
                    // ══════════════════════════════════════════════════════════════════
                    var _nativeSubmit = HTMLFormElement.prototype.submit;
                    HTMLFormElement.prototype.submit = function() {
                        if (!_isOnline || !navigator.onLine) {
                            console.log('[TagTeam] form.submit() BLOCKED — offline');
                            handleOfflineScan();
                            return; // do NOT call native submit
                        }
                        // Online — allow the native submit
                        return _nativeSubmit.call(this);
                    };
                    // FIX: ASP.NET's MaintainScrollPositionOnPostback replaces
                    // form.submit with WebForm_SaveScrollPositionSubmit, which
                    // saves the original native submit in form.oldSubmit.
                    // We must overwrite oldSubmit too, or it bypasses our override.
                    if (typeof theForm !== 'undefined' && theForm && theForm.oldSubmit) {
                        theForm.oldSubmit = HTMLFormElement.prototype.submit;
                        console.log('[TagTeam] Patched theForm.oldSubmit');
                    }

                    // 1. Intercept ASP.NET AutoPostBacks ─────────────────────────────
                    // __doPostBack sets hidden fields then calls theForm.submit().
                    // We intercept it to do a quick probe FIRST. If the probe says
                    // online, we call the original (which calls our patched submit).
                    // If the probe says offline, we queue locally.
                    const originalDoPostBack = window.__doPostBack;
                    window.__doPostBack = function(eventTarget, eventArgument) {
                        // Save barcode as insurance in case the POST somehow gets through
                        var _scanBox = document.getElementById('TxtAssetScan');
                        if (_scanBox && _scanBox.value.trim() !== '') {
                            localStorage.setItem('TagTeam_PendingBarcode', _scanBox.value.trim());
                        }

                        // Fast path: if we KNOW we are offline, skip immediately
                        if (!_isOnline || !navigator.onLine) {
                            console.log('[TagTeam] __doPostBack blocked (known offline), target:', eventTarget);
                            localStorage.removeItem('TagTeam_PendingBarcode');
                            handleOfflineScan(eventTarget);
                            return false;
                        }

                        // ── Tag Date stale guard (online path) ──────────────────────
                        // Only block asset scans, not other form interactions (like Load History)
                        if (window._tagDateConfirmRequired && eventTarget && 
                            (eventTarget.indexOf('TxtAssetScan') !== -1 || eventTarget.indexOf('BtnAdd') !== -1)) {
                            alert('WARNING: Tag Date has not been confirmed! Please verify or update the Tag Date before scanning.');
                            localStorage.removeItem('TagTeam_PendingBarcode');
                            var _sb = document.getElementById('TxtAssetScan');
                            if (_sb) { _sb.value = ''; }
                            return false;
                        }

                        // Do a rapid 2-second probe to confirm server is truly reachable
                        quickProbeXHR(2000).then(function(online) {
                            if (online) {
                                // Server confirmed reachable — allow the postback
                                localStorage.removeItem('TagTeam_PendingBarcode');
                                _isOnline = true;
                                updateIndicator(true);
                                if (originalDoPostBack) {
                                    originalDoPostBack(eventTarget, eventArgument);
                                }
                            } else {
                                // Server NOT reachable — queue offline
                                console.log('[TagTeam] __doPostBack blocked (probe failed), target:', eventTarget);
                                localStorage.removeItem('TagTeam_PendingBarcode');
                                _isOnline = false;
                                updateIndicator(false);
                                handleOfflineScan(eventTarget);
                            }
                        });
                        return false; // prevent synchronous postback
                    };

                    // 2. Intercept submit events as a redundant safety layer
                    window.addEventListener('submit', function(e) {
                        var sb = document.getElementById('TxtAssetScan');
                        if (sb && sb.value.trim() !== '') {
                            localStorage.setItem('TagTeam_PendingBarcode', sb.value.trim());
                        }
                        if (!_isOnline || !navigator.onLine) {
                            e.preventDefault();
                            e.stopImmediatePropagation();
                            handleOfflineScan();
                            return false;
                        }
                    }, true);

                    // --- Custom Column Visibility Logic ---
                    window.toggleColMenu = function() {
                        const container = document.getElementById('ColToggleContainer');
                        if (container) {
                            container.style.display = container.style.display === 'none' ? 'flex' : 'none';
                        }
                    };

                    function applyColumnCSS() {
                        let styleTag = document.getElementById('GridColumnStyles');
                        if (!styleTag) {
                            styleTag = document.createElement('style');
                            styleTag.id = 'GridColumnStyles';
                            document.head.appendChild(styleTag);
                        }
                        let hiddenCols = JSON.parse(localStorage.getItem('aw_tagteam_hidden_cols') || '[]');
                        let css = '';
                        hiddenCols.forEach(index => {
                            // nth-child is 1-based index
                            css += `#GridScans th:nth-child(${index + 1}), #GridScans td:nth-child(${index + 1}) { display: none !important; }\n`;
                        });
                        styleTag.innerHTML = css;
                    }

                    function renderColumnToggles() {
                        const grid = document.getElementById('GridScans');
                        const container = document.getElementById('ColToggleContainer');
                        if (!grid || !container) return;
                        
                        const headerRow = grid.querySelector('th') ? grid.querySelector('th').parentNode : null;
                        if (!headerRow) return;
                        
                        const ths = headerRow.querySelectorAll('th');
                        container.innerHTML = '<div style="width:100%; color:var(--muted); margin-bottom:4px; font-weight:600;">Check to display column:</div>';
                        
                        let hiddenCols = JSON.parse(localStorage.getItem('aw_tagteam_hidden_cols') || '[]');
                        
                        ths.forEach((th, index) => {
                            let text = "";
                            for(let i=0; i<th.childNodes.length; i++) {
                                if (th.childNodes[i].nodeType === 3) {
                                    text += th.childNodes[i].nodeValue;
                                }
                            }
                            text = text.trim();
                            if (!text) {
                                const aTag = th.querySelector('a');
                                if (aTag) text = aTag.innerText.trim();
                            }
                            
                            // Prevent hiding core columns like Selection, Status, Edit, and Delete
                            if (index === 0 || text === "Status" || text === "Edit" || text === "") return; 

                            const label = document.createElement('label');
                            label.style.cssText = 'display:flex; align-items:center; gap:6px; cursor:pointer; background:var(--chip); padding:6px 10px; border-radius:6px; border:1px solid var(--line); color:var(--text); font-weight:normal; margin:0;';
                            
                            const cb = document.createElement('input');
                            cb.type = 'checkbox';
                            cb.style.margin = '0';
                            cb.checked = !hiddenCols.includes(index);
                            cb.onchange = function() {
                                let hc = JSON.parse(localStorage.getItem('aw_tagteam_hidden_cols') || '[]');
                                if (!this.checked && !hc.includes(index)) hc.push(index);
                                else if (this.checked) hc = hc.filter(i => i !== index);
                                localStorage.setItem('aw_tagteam_hidden_cols', JSON.stringify(hc));
                                applyColumnCSS();
                            };
                            
                            label.appendChild(cb);
                            label.appendChild(document.createTextNode(text));
                            container.appendChild(label);
                        });
                    }

                    applyColumnCSS();
                    renderColumnToggles();
                });
            </script>
        </head>

        <body>
            <%-- Offline toast banners (fixed position, outside form is fine) --%>
            <div id="offline-toast"></div>
            <div id="sync-toast"></div>
            <form id="form1" runat="server">
                <div class="status-bar">
                    <span>AssetWorx Tag Team Scan</span>
                    <span id="connection-indicator">Checking Connection...</span>
                </div>
                <div class="wrap">
                    <div class="h1">Tag Team Scan 
                        <a href="documentation/va_tagteam_scan.html" class="btn btn-ghost btn-sm" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a> <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                        <asp:LinkButton ID="BtnRefreshData" runat="server" OnClick="BtnRefreshData_Click" CssClass="btn" style="float:right; background:var(--btn-alt); color:var(--accent); border:1px solid var(--line); font-size:13px; font-weight:600; padding:8px 12px; margin-left:10px;" UseSubmitBehavior="false">Refresh App Data</asp:LinkButton>
                        <button type="button" class="btn" id="BtnToggleConfig" style="float:right; background:var(--btn-alt); color:var(--text); border:1px solid var(--line); font-size:13px; font-weight:600; padding:8px 12px; cursor:pointer;" onclick="toggleConfigPanel()">&#9881; Hide Config</button>
                    </div>
                    <div class="sub">Rapidly scan and correct asset data. Logic: Scan Location -> Scan Assets.</div>

                    <!-- OFFLINE QUEUE -->
                    <div id="pnlOffline" class="card offline-card">
                        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;">
                            <div style="flex:1;">
                                <h3 style="margin:0 0 6px; color:var(--danger);">&#128683; Offline Scans Pending Sync</h3>
                                <p style="margin:0 0 8px; font-size:13px; color:var(--muted);">These barcodes have been saved locally and will be committed to the database when you tap <strong>Sync Now</strong> after reconnecting.</p>
                                <ul id="offline-list" style="margin:10px 0; font-size:13px; color:var(--text); padding-left:18px;"></ul>
                            </div>
                            <button id="btnSync" type="button" class="btn btn-green" style="white-space:nowrap;" onclick="syncScans()">&#9729; Sync Now</button>
                        </div>
                    </div>

                    <!-- CONFIGURATION PANEL (HIDEABLE) -->
                    <div id="locationConfigPanel">
                        <!-- 1. LOCATION SETTING -->
                        <div class="card">
                            <div class="row" style="align-items:flex-start;">
                                <div class="col">
                                    <span class="lbl">Site Filter</span>
                                    <asp:DropDownList ID="DdlCompany" runat="server" CssClass="txt" ClientIDMode="Static">
                                    </asp:DropDownList>
                                </div>
                                <div class="col">
                                    <span class="lbl">Operator</span>
                                    <asp:DropDownList ID="DdlEmpl" runat="server" CssClass="txt" ClientIDMode="Static">
                                    </asp:DropDownList>
                                </div>
                                <div class="col">
                                    <span class="lbl">1. Scan Location</span>
                                    <asp:TextBox ID="TxtLocationScan" runat="server" CssClass="txt"
                                        placeholder="Scan Location (e.g. SP...)" AutoPostBack="true"
                                        OnTextChanged="BtnSetLocation_Click" ClientIDMode="Static" />
                                </div>
                                <div class="col">
                                    <span class="lbl">Tag Date</span>
                                    <asp:TextBox ID="TxtCurrentDate" runat="server" CssClass="txt" TextMode="Date"
                                        ClientIDMode="Static" />
                                    <button type="button" id="tagdate-confirm-btn" onclick="confirmTagDate();"
                                        style="display:none; margin-top:4px; background:#059669; color:#fff; border:none; border-radius:6px; padding:6px 14px; font-weight:700; font-size:12px; cursor:pointer; animation: slideUp 0.3s ease;">
                                        OK - Confirm Date
                                    </button>
                                </div>
                                <div class="col" style="flex:1; text-align:right;">
                                    <span class="lbl">Current Location</span>
                                    <asp:Label ID="LblCurrentLocation" runat="server" CssClass="current-loc"
                                        Text="(None Set)" ClientIDMode="Static" />
                                    <asp:Label ID="LblLocationTotal" runat="server" style="color:#10b981; font-weight:600; font-size:12px; margin-top:2px; display:none;" />
                                </div>
                            </div>
                            <div id="tagdate-warn-banner" style="display:none; background:color-mix(in srgb, var(--danger), transparent 85%); border:1px solid var(--danger); border-radius:8px; padding:10px 16px; margin-bottom:10px; font-size:13px; color:var(--text); font-weight:600;">
                                <span id="tagdate-warn-text"></span>
                            </div>
                            <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap; padding-top:8px; border-top:1px solid var(--line); margin-top:4px;">
                                <asp:Button ID="BtnHistory" runat="server" Text="Load Scans"
                                    OnClick="BtnLoadHistory_Click" CssClass="btn"
                                    Style="background:var(--btn-alt); font-size:12px; padding:6px 12px;"
                                    UseSubmitBehavior="false" />
                                <div style="display:flex; align-items:center; gap:6px;">
                                    <span class="lbl" style="font-size:11px; margin:0;">From</span>
                                    <asp:TextBox ID="TxtDateFrom" runat="server" CssClass="txt" TextMode="Date"
                                        style="width:140px; font-size:12px; padding:5px 8px;" />
                                    <span class="lbl" style="font-size:11px; margin:0;">To</span>
                                    <asp:TextBox ID="TxtDateTo" runat="server" CssClass="txt" TextMode="Date"
                                        style="width:140px; font-size:12px; padding:5px 8px;" />
                                </div>
                                <label style="color:var(--muted); font-size:12px; display:flex; align-items:center; gap:4px; cursor:pointer;">
                                    <asp:CheckBox ID="ChkUntaggedOnly" runat="server" />
                                    Untagged Only
                                </label>
                                <asp:Label ID="LblUserScanTotal" runat="server" style="background:var(--chip); padding:2px 8px; border-radius:12px; font-size:11px; color:var(--muted); border:1px solid var(--line); display:none;"></asp:Label>
                            </div>
                        </div>
                    </div>

                    <!-- 2. ASSET SCANNING -->
                    <asp:Panel ID="PnlScan" runat="server" DefaultButton="BtnAdd" CssClass="card">
                        <div class="row">
                            <div style="display:flex; flex-direction:column; flex:1;">
                                <div style="display:flex; padding-bottom:6px;">
                                    <div style="flex:1;"><span class="lbl" style="color:var(--accent); margin-bottom:0;">2. Scan Asset Barcode</span></div>
                                    <div style="width:150px;"><span class="lbl" style="margin-bottom:0;">Tag Type</span></div>
                                </div>
                                <div style="display:flex;">
                                    <asp:TextBox ID="TxtAssetScan" runat="server" CssClass="txt" style="flex:1; border-color:var(--accent); font-size:16px; border-radius:8px 0 0 8px; z-index:2; position:relative;"
                                        placeholder="Scan EE Tag..." AutoPostBack="true" OnTextChanged="BtnAddAsset_Click"
                                        ClientIDMode="Static" />
                                    <asp:DropDownList ID="DdlDefaultTagType" runat="server" CssClass="txt" style="max-width:180px; width:auto; border-radius:0 8px 8px 0; margin-left:-1px; border-color:var(--line); text-overflow:ellipsis;" ClientIDMode="Static" EnableViewState="false">
                                    </asp:DropDownList>
                                </div>
                            </div>
                            <div class="col">
                                <span class="lbl">Default Notes</span>
                                <asp:TextBox ID="TxtDefaultNotes" runat="server" CssClass="txt"
                                    placeholder="e.g. Relocated" ClientIDMode="Static" />
                            </div>
                             <div class="col" style="justify-content:flex-end;">
                                <asp:Button ID="BtnAdd" runat="server" Text="Manual Add" OnClick="BtnAddAsset_Click"
                                    CssClass="btn btn-blue" />
                            </div>
                            <div class="col" style="justify-content:flex-end;">
                                <label style="color:var(--text); font-size:12px; font-weight:600; display:flex; align-items:center; gap:6px; cursor:pointer; height:36px; padding-bottom:3px;" title="Automatically save and print tag when scanned">
                                    <asp:CheckBox ID="ChkAutoPrint" runat="server" ClientIDMode="Static" /> 
                                    Auto Print
                                </label>
                            </div>
                            <div class="col" style="justify-content:flex-end;">
                                <div id="btPrinterStatusBadge" style="display:inline-flex; align-items:center; gap:6px; height:36px; padding:0 12px; border-radius:8px; font-size:12px; font-weight:600; background:var(--chip); border:1px solid var(--line); color:var(--muted);" title="BarTender Print Engine Status">
                                    <span id="btStatusDot" style="width:8px; height:8px; border-radius:50%; background:#10b981; display:inline-block;"></span>
                                    <span id="btStatusText">Checking BarTender...</span>
                                </div>
                            </div>
                        </div>

                        <asp:Literal ID="LitMsg" runat="server" />
                        <asp:Literal ID="LitPrintConfig" runat="server" />
                        <asp:Literal ID="LitPrintScript" runat="server" />

                        <!-- GRID -->
                        <div style="margin-bottom:10px; display:flex; justify-content:space-between; align-items:flex-end; flex-wrap:wrap; gap:10px;">
                            <span style="color:var(--muted); font-size:12px;">(Click header to sort. Type in boxes below headers to instantly filter rows.)</span>
                            <button type="button" class="btn" style="background:var(--btn-alt); border:1px solid var(--accent); color:var(--text); font-size:12px; padding:6px 12px; cursor:pointer; border-radius:6px;" onclick="toggleColMenu()">&#9776; Columns</button>
                        </div>
                        
                        <!-- COLUMN TOGGLE LIST -->
                        <div id="ColToggleContainer" style="background:var(--card); border:1px solid var(--line); border-radius:8px; padding:12px; margin-bottom:12px; display:none; flex-wrap:wrap; gap:10px; font-size:13px; box-shadow:var(--shadow);"></div>

                        <asp:GridView ID="GridScans" runat="server" CssClass="grid" AutoGenerateColumns="false"
                            DataKeyNames="Guid" OnRowCommand="GridScans_RowCommand" OnRowEditing="GridScans_RowEditing"
                            OnRowCancelingEdit="GridScans_RowCancelingEdit" OnRowUpdating="GridScans_RowUpdating"
                            AllowSorting="true" OnSorting="GridScans_Sorting" ClientIDMode="Static">
                            <Columns>
                                <asp:TemplateField>
                                    <HeaderTemplate>
                                        <input type="checkbox" id="chkAllPrint" onclick="toggleAllPrint(this);" title="Select All for Print" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input type="checkbox" class="chk-print" value='<%# Eval("AssetId") %>' data-guid='<%# Eval("Guid") %>' data-barcode='<%# Eval("Barcode") %>' data-tagtype='<%# Eval("TagType") %>' data-desc='<%# Eval("Description") %>' data-sn='<%# Eval("SerialNumber") %>' data-cmr='<%# Eval("Cmr") %>' <%# Convert.ToInt32(Eval("AssetId")) == 0 ? "disabled='disabled' title='Commit changes to DB before printing'" : "" %> />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                  <asp:TemplateField HeaderText="Scan Status" SortExpression="Status">
                                    <ItemTemplate>
                                        <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-start;">
                                            <span class='<%# Eval("Status").ToString() == "Saved" ? "badge-saved" : (Eval("Status").ToString() == "Not Found" ? "badge-404" : "badge-pending") %>'>
                                                <%# Eval("Status") %>
                                            </span>
                                            
                                            <div visible='<%# Convert.ToBoolean(Eval("IsFlagged")) %>' runat="server">
                                                <span class="badge-flagged">Wrong Site</span>
                                            </div>

                                            <div visible='<%# Convert.ToBoolean(Eval("IsStatusFlagged")) %>' runat="server">
                                                <span class="badge-status-warn">Not In Use</span>
                                            </div>
                                            
                                            <div style="font-size:10px; color:var(--muted); font-weight:bold; margin-top:2px;">
                                                <%# Eval("AssetStatus") %>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Asset Tag" SortExpression="Barcode">
                                    <ItemTemplate>
                                        <%# Eval("Barcode") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:TextBox ID="TxtBarcodeEdit" runat="server" Text='<%# Bind("Barcode") %>' CssClass="txt" />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField DataField="SerialNumber" HeaderText="Serial # (3)" ReadOnly="true" SortExpression="SerialNumber" />

                                <asp:TemplateField HeaderText="Description (DB)" SortExpression="Description">
                                    <ItemTemplate>
                                        <%# Eval("Description") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:TextBox ID="TxtDescriptionEdit" runat="server" Text='<%# Bind("Description") %>' CssClass="txt" />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tag Type (19)" SortExpression="TagType">
                                    <ItemTemplate>
                                        <%# Eval("TagType") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:DropDownList ID="DdlTagTypeEdit" runat="server" CssClass="txt"
                                            SelectedValue='<%# GetSafeTagType(Eval("TagType")) %>' OnInit="DdlTagTypeEdit_Init">
                                            <asp:ListItem Value="">-- None --</asp:ListItem>
                                        </asp:DropDownList>
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="New Loc (6/16)" SortExpression="LocTagged">
                                    <ItemTemplate>
                                        <%# Eval("LocTagged") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:TextBox ID="TxtLocTagged" runat="server" Text='<%# Bind("LocTagged") %>' />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField DataField="DbLocation" HeaderText="Current DB Loc (6)"
                                    ReadOnly="true" SortExpression="DbLocation" />

                                <asp:TemplateField HeaderText="Empl ID (13)" SortExpression="EmplId">
                                    <ItemTemplate>
                                        <%# Eval("EmplId") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:TextBox ID="TxtEmplIdEdit" runat="server" Text='<%# Bind("EmplId") %>' />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Notes (20)" SortExpression="Notes">
                                    <ItemTemplate>
                                        <%# Eval("Notes") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:TextBox ID="TxtNotes" runat="server" Text='<%# Bind("Notes") %>' />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tag Date (17)" SortExpression="TagDate">
                                    <ItemTemplate>
                                        <%# Eval("TagDate") %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:TextBox ID="TxtTagDate" runat="server" Text='<%# Bind("TagDate") %>'
                                            TextMode="Date" CssClass="txt" />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tagged (18)" SortExpression="Tagged">
                                    <ItemTemplate>
                                        <%# (bool)Eval("Tagged") ? "YES" : "NO" %>
                                    </ItemTemplate>
                                    <EditItemTemplate>
                                        <asp:CheckBox ID="ChkTagged" runat="server" Checked='<%# Bind("Tagged") %>' />
                                    </EditItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField DataField="Cmr" HeaderText="CMR (8)" ReadOnly="true" SortExpression="Cmr" />

                                <asp:CommandField ShowEditButton="true" ControlStyle-CssClass="btn-blue"
                                    HeaderText="Edit" ButtonType="Button" />

                                <asp:TemplateField HeaderText="Preview">
                                    <ItemTemplate>
                                        <button type="button" class="btn" style="background:transparent; border:1px solid var(--accent); color:var(--accent); padding:4px 8px; font-size:11px; cursor:pointer; border-radius:4px;" onclick="previewFromRow(this);" title="Preview BarTender Label">&#128065; Preview</button>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField>
                                    <ItemTemplate>
                                        <asp:Button runat="server" CommandName="Remove"
                                            CommandArgument='<%# Eval("Guid") %>' Text="X" CssClass="btn-red" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div style="padding:20px;text-align:center;color:var(--muted);">No scans yet. Set
                                    location and start scanning assets.</div>
                            </EmptyDataTemplate>
                        </asp:GridView>

                        <asp:HiddenField ID="HdnMarkedGuids" runat="server" ClientIDMode="Static" />
                        <div class="row" style="margin-top:20px; justify-content:space-between; align-items:center;">
                            <label
                                style="color:var(--muted); font-size:13px; display:flex; gap:8px; align-items:center; cursor:pointer;">
                                <asp:CheckBox ID="ChkShowFlagged" runat="server" AutoPostBack="true"
                                    OnCheckedChanged="ChkShowFlagged_CheckedChanged" Checked="false" />
                                Display flagged assets (Items with site mismatch are hidden by default; Not In Use items are always shown)
                            </label>
                            <div style="display:flex; gap:10px; align-items:center;">
                                <asp:Button ID="BtnClear" runat="server" Text="Clear All" OnClick="BtnClear_Click"
                                    CssClass="btn" Style="background:var(--btn-alt);"
                                    OnClientClick="return confirm('Clear list?');" />
                                <select id="DdlPrintTemplate" class="txt" style="display:none; padding:8px; font-size:12px; width:auto; border-color:var(--accent);">
                                    <option value="">-- Auto-Map Template --</option>
                                </select>
                                <select id="DdlPrintTarget" class="txt" style="display:none; padding:8px; font-size:12px; width:auto; border-color:var(--accent);">
                                    <option value="">-- Default Route --</option>
                                </select>
                                <button type="button" id="BtnPreviewChecked" class="btn" style="background:#0284c7; color:#fff; display:none;" onclick="previewCheckedTag();">&#128065; Preview Tag</button>
                                <button type="button" id="BtnPrintChecked" class="btn btn-blue" onclick="printCheckedTags();" style="display:none;">Server Print (#)</button>
                                <asp:Button ID="BtnMarkSelectedTagged" runat="server" Text="Mark Selected as Tagged"
                                    OnClick="BtnMarkSelectedTagged_Click" CssClass="btn"
                                    Style="background:#7c3aed; display:none; font-size:13px;"
                                    OnClientClick="syncTagGuids(); return true;" />
                                <asp:Button ID="BtnMarkAllTagged" runat="server" Text="Mark All as Tagged"
                                    OnClick="BtnMarkAllTagged_Click" CssClass="btn"
                                    Style="background:#059669; font-size:13px;"
                                    OnClientClick="return confirm('Mark ALL items in current list as Tagged = YES?');" />
                                <asp:Button ID="BtnCommit" runat="server" Text="Finalize / Retry Failed"
                                    OnClick="BtnCommit_Click" CssClass="btn btn-green" Font-Size="16px"
                                    OnClientClick="return confirm('Retry saving any failed or pending changes to the database?');" />
                            </div>
                        </div>

                        <div style="margin-top:20px; border-top:1px solid var(--line); padding-top:20px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                            <div style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
                                <asp:Button ID="BtnPreviewEnnx" runat="server" Text="Preview ENNX File"
                                    OnClick="BtnPreviewEnnx_Click" CssClass="btn" Style="background:var(--btn-alt);" />
                                <asp:Button ID="BtnShowNoData" runat="server" Text="Show No Data Assets"
                                    OnClick="BtnShowNoData_Click" CssClass="btn" Style="background:var(--btn-alt); border:1px solid var(--danger); color:var(--danger);" />
                                <asp:Button ID="BtnShowOit" runat="server" Text="Show OIT Assets Scanned"
                                    OnClick="BtnShowOit_Click" CssClass="btn" Style="background:var(--btn-alt); border:1px solid #f59e0b; color:#f59e0b;" />
                            </div>
                            <label style="color:var(--muted); font-size:13px; display:flex; gap:6px; align-items:center; cursor:pointer;">
                                <asp:CheckBox ID="ChkIgnore78Cmr" runat="server" />
                                Ignore 78 EIL/CMR
                            </label>
                        </div>
                        <div style="margin-top:10px;">
                            <asp:TextBox ID="TxtPreview" runat="server" TextMode="MultiLine" Rows="10"
                                Style="width:100%; background:var(--preview-bg); color:var(--preview-text); border:1px solid var(--line); font-family:monospace;"
                                ReadOnly="true" />
                        </div>
                        <div style="margin-top:10px;">
                            <asp:TextBox ID="TxtNoDataPreview" runat="server" TextMode="MultiLine" Rows="6"
                                Style="width:100%; background:var(--preview-bg); color:#f87171; border:1px solid var(--danger); font-family:monospace; display:none;"
                                ReadOnly="true" />
                        </div>
                        <div style="margin-top:10px;">
                            <asp:TextBox ID="TxtOitPreview" runat="server" TextMode="MultiLine" Rows="6"
                                Style="width:100%; background:var(--preview-bg); color:#f59e0b; border:1px solid #f59e0b; font-family:monospace; display:none;"
                                ReadOnly="true" />
                        </div>

                        <!-- BarTender Label Preview Modal -->
                        <div id="btPreviewModal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; overflow:auto; background-color:rgba(0,0,0,0.65); backdrop-filter:blur(4px); align-items:center; justify-content:center;">
                            <div style="background:var(--card); border:1px solid var(--line); border-radius:16px; width:90%; max-width:620px; box-shadow:0 25px 50px -12px rgba(0,0,0,0.5); overflow:hidden;">
                                <div style="display:flex; justify-content:space-between; align-items:center; padding:16px 20px; border-bottom:1px solid var(--line); background:var(--chip);">
                                    <div style="display:flex; align-items:center; gap:8px;">
                                        <span style="font-size:18px;">&#127991;&#65039;</span>
                                        <span style="font-weight:700; font-size:16px; color:var(--text);">BarTender Label Preview</span>
                                    </div>
                                    <button type="button" onclick="closeBtPreviewModal()" style="background:none; border:none; color:var(--muted); font-size:24px; cursor:pointer; line-height:1; padding:0 4px;">&times;</button>
                                </div>
                                <div style="padding:20px; text-align:center;">
                                    <div id="btPreviewLoading" style="display:none; padding:40px; color:var(--muted);">
                                        <div style="display:inline-block; width:32px; height:32px; border:3px solid var(--line); border-top-color:var(--accent); border-radius:50%; animation:btSpin 0.8s linear infinite; margin-bottom:12px;"></div>
                                        <div style="font-size:13px; font-weight:600;">Rendering live BarTender label...</div>
                                    </div>
                                    <div id="btPreviewContainer">
                                        <img id="btPreviewImage" src="" alt="Label Preview" style="max-width:100%; max-height:360px; border-radius:8px; border:1px solid var(--line); box-shadow:0 4px 12px rgba(0,0,0,0.15); background:#fff; margin-bottom:12px;" />
                                        <div id="btPreviewMeta" style="display:flex; flex-direction:column; gap:4px; font-size:12px; color:var(--muted); text-align:left; background:var(--chip); padding:10px 14px; border-radius:8px; border:1px solid var(--line);"></div>
                                    </div>
                                </div>
                                <div style="display:flex; justify-content:flex-end; gap:10px; padding:14px 20px; border-top:1px solid var(--line); background:var(--chip);">
                                    <button type="button" class="btn" style="background:var(--btn-alt); border:1px solid var(--line); color:var(--text);" onclick="closeBtPreviewModal()">Close</button>
                                    <button type="button" id="btnModalPrint" class="btn btn-blue" onclick="printFromModal();">&#128424; Print Tag</button>
                                </div>
                            </div>
                        </div>
                        <style>
                            @keyframes btSpin { to { transform: rotate(360deg); } }
                        </style>

                        <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                checkBtPrinterStatus();
                            });

                            async function checkBtPrinterStatus() {
                                const dot = document.getElementById('btStatusDot');
                                const txt = document.getElementById('btStatusText');
                                if (!txt) return;
                                try {
                                    const resp = await fetch('api/BarTenderHandler.ashx?action=printers');
                                    if (resp.ok) {
                                        const data = await resp.json();
                                        if (data.success && data.printers && data.printers.length > 0) {
                                            if (dot) dot.style.background = '#10b981';
                                            txt.innerText = 'BarTender: ' + data.printers.length + ' Printers';
                                            txt.title = data.printers.map(function(p) { return p.Name + (p.IsDefault ? ' (Default)' : ''); }).join('\n');
                                        } else {
                                            if (dot) dot.style.background = '#f59e0b';
                                            txt.innerText = 'BarTender Engine Ready';
                                        }
                                    } else {
                                        if (dot) dot.style.background = '#f59e0b';
                                        txt.innerText = 'BarTender Engine Ready';
                                    }
                                } catch (e) {
                                    if (dot) dot.style.background = '#64748b';
                                    txt.innerText = 'BarTender Engine Ready';
                                }
                            }

                            document.addEventListener('change', function(e) {
                                if (e.target && e.target.classList.contains('chk-print')) {
                                    const checked = document.querySelectorAll('.chk-print:checked');
                                    const btnPrev = document.getElementById('BtnPreviewChecked');
                                    if (btnPrev) {
                                        btnPrev.style.display = checked.length > 0 ? 'inline-block' : 'none';
                                    }
                                }
                            });

                            let currentModalAsset = null;

                            function previewCheckedTag() {
                                const checked = document.querySelectorAll('.chk-print:checked');
                                if (checked.length === 0) {
                                    alert('Please select at least one row to preview.');
                                    return;
                                }
                                const cb = checked[0];
                                const barcode = cb.getAttribute('data-barcode') || '';
                                const desc = cb.getAttribute('data-desc') || '';
                                const sn = cb.getAttribute('data-sn') || '';
                                const cmr = cb.getAttribute('data-cmr') || '';
                                const tagType = cb.getAttribute('data-tagtype') || '';
                                const assetId = parseInt(cb.value, 10) || 0;
                                openLabelPreview(barcode, desc, sn, cmr, tagType, assetId);
                            }

                            function previewFromRow(btn) {
                                const row = btn.closest('tr');
                                if (!row) return;
                                const cb = row.querySelector('.chk-print');
                                if (!cb) return;
                                const barcode = cb.getAttribute('data-barcode') || '';
                                const desc = cb.getAttribute('data-desc') || '';
                                const sn = cb.getAttribute('data-sn') || '';
                                const cmr = cb.getAttribute('data-cmr') || '';
                                const tagType = cb.getAttribute('data-tagtype') || '';
                                const assetId = parseInt(cb.value, 10) || 0;
                                openLabelPreview(barcode, desc, sn, cmr, tagType, assetId);
                            }

                            function resolveTemplateForTag(tagType) {
                                const ddlTpl = document.getElementById('DdlPrintTemplate');
                                if (ddlTpl && ddlTpl.value) {
                                    const allTpls = (window.awPrintConfig && window.awPrintConfig.printTemplates) || [];
                                    const chosen = allTpls.find(function(t) { return t.id === parseInt(ddlTpl.value, 10); });
                                    if (chosen && chosen.filename) return chosen.filename;
                                }

                                if (typeof window.findTemplateForTag === 'function') {
                                    const ddlCompany = document.getElementById('DdlCompany');
                                    const selectedCompanyId = ddlCompany && ddlCompany.value ? parseInt(ddlCompany.value, 10) : 0;
                                    const allTemplates = (window.awPrintConfig && window.awPrintConfig.printTemplates) || [];
                                    const siteTemplates = selectedCompanyId > 0
                                        ? allTemplates.filter(function(t) { return t.companyId === selectedCompanyId || t.companyId === 0; })
                                        : allTemplates;
                                    const searchPool = siteTemplates.length > 0 ? siteTemplates : allTemplates;
                                    const matched = window.findTemplateForTag(tagType, searchPool, allTemplates);
                                    if (matched && matched.filename) return matched.filename;
                                }

                                const norm = (tagType || '').toLowerCase().replace(/[\s\-_]+/g, '');
                                if ((norm.indexOf('large') >= 0 && norm.indexOf('metal') >= 0) || norm === 'largemetal' || norm === 'metallarge') {
                                    return 'c:\\assetworx_prints\\AW_Large_Metal.btw';
                                }
                                if (norm.indexOf('iq350') >= 0) {
                                    return 'c:\\assetworx_prints\\AW_Metal_IQ350.btw';
                                }
                                return 'c:\\assetworx_prints\\AW_Std_Small.btw';
                            }

                            async function openLabelPreview(barcode, desc, sn, cmr, tagType, assetId) {
                                const modal = document.getElementById('btPreviewModal');
                                const loader = document.getElementById('btPreviewLoading');
                                const container = document.getElementById('btPreviewContainer');
                                const img = document.getElementById('btPreviewImage');
                                const meta = document.getElementById('btPreviewMeta');
                                const btnPrint = document.getElementById('btnModalPrint');

                                if (!modal) return;
                                modal.style.display = 'flex';
                                loader.style.display = 'block';
                                container.style.display = 'none';
                                currentModalAsset = { assetId: assetId, tagType: tagType, barcode: barcode };

                                const templatePath = resolveTemplateForTag(tagType);
                                const fields = {
                                    lblname: barcode || 'SAMPLE-0001',
                                    lbldescription: desc || 'TAG TEAM SAMPLE ASSET',
                                    lblsn: sn || 'SN-00000',
                                    lbleil: cmr || '138',
                                    lblrfidtag: (barcode ? 'E28011902000' + barcode.replace(/\s+/g, '') : 'E28011902000216503837493')
                                };

                                try {
                                    const resp = await fetch('api/BarTenderHandler.ashx?action=preview', {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json; charset=utf-8' },
                                        body: JSON.stringify({ template: templatePath, fields: fields })
                                    });

                                    const data = await resp.json();
                                    loader.style.display = 'none';
                                    container.style.display = 'block';

                                    if (data.Success && data.ImageBase64) {
                                        img.src = 'data:image/png;base64,' + data.ImageBase64;
                                        meta.innerHTML = 
                                            '<div><strong>Template:</strong> ' + templatePath + '</div>' +
                                            '<div><strong>Asset:</strong> ' + (barcode || 'N/A') + ' &bull; <strong>S/N:</strong> ' + (sn || 'N/A') + ' &bull; <strong>CMR:</strong> ' + (cmr || 'N/A') + '</div>' +
                                            '<div><strong>Named Data Sources (' + (data.DiscoveredFields ? data.DiscoveredFields.length : 0) + '):</strong> ' + 
                                            (data.DiscoveredFields ? data.DiscoveredFields.join(', ') : 'None') + '</div>';
                                        if (btnPrint) btnPrint.disabled = false;
                                    } else {
                                        img.src = '';
                                        meta.innerHTML = '<div style="color:var(--danger);font-weight:600;">&#9888; Preview Failed: ' + (data.ErrorMessage || 'Unknown error') + '</div>';
                                        if (btnPrint) btnPrint.disabled = true;
                                    }
                                } catch (err) {
                                    loader.style.display = 'none';
                                    container.style.display = 'block';
                                    meta.innerHTML = '<div style="color:var(--danger);font-weight:600;">&#9888; Network/API Error: ' + err.message + '</div>';
                                    if (btnPrint) btnPrint.disabled = true;
                                }
                            }

                            function closeBtPreviewModal() {
                                const modal = document.getElementById('btPreviewModal');
                                if (modal) modal.style.display = 'none';
                            }

                            async function printFromModal() {
                                if (!currentModalAsset) return;
                                closeBtPreviewModal();
                                if (currentModalAsset.assetId > 0) {
                                    if (typeof printSingleTag === 'function') {
                                        await printSingleTag(currentModalAsset.assetId, currentModalAsset.tagType);
                                    } else {
                                        alert('Tag sent to print pipeline!');
                                    }
                                } else {
                                    alert('Cannot print: Asset ID is 0. Please finalize/commit to DB first.');
                                }
                            }
                        </script>

                    </asp:Panel>

                    <idash:Footer runat="server" />
                </div>
            </form>
        </body>

        </html>

