<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_inventory_legacy.aspx.cs" Inherits="va_inventory_legacy" MaintainScrollPositionOnPostback="true" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>

        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">

        <head runat="server">
            <meta charset="utf-8" />
            <title>VA Site Inventory - iDash</title>
            <link rel="icon" type="image/png" href="Assets/branding/idintegration_icon.png" />
    <link rel="shortcut icon" href="favicon.ico" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
            <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
            <meta http-equiv="Pragma" content="no-cache" />
            <meta http-equiv="Expires" content="0" />

            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <style>



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
                    padding: 20px;
                    margin-bottom: 20px;
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
                    background: var(--bg);
                    border: 1px solid var(--line);
                    color: var(--text);
                    padding: 10px;
                    border-radius: 8px;
                    font-size: 14px;
                    outline: none;
                    width: 220px;
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
                    color: var(--accent-2);
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

                .badge-moved {
                    background: #a855f7;
                    color: #fff;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                }

                .badge-flagged {
                    background: #facc15;
                    color: #713f12;
                    padding: 4px 8px;
                    border-radius: 10px;
                    font-size: 11px;
                    font-weight: 800;
                    display: inline-block;
                }

                .status-bar {
                    display: flex;
                    justify-content: space-between;
                    background: var(--chip);
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

                /* Make standard date picker icon white for dark theme */
                ::-webkit-calendar-picker-indicator {
                    filter: var(--cal-filter);
                    cursor: pointer;
                }
                /* WebSerial section — hidden globally, not in use */
                #serialSection { display: none; }

                /* === MOBILE / SCANNER OPTIMIZATION (TC53, Android handhelds) === */
                @media (max-width: 600px) {
                    .mobile-hide { display: none !important; }
                    .sub { display: none; }
                    .wrap { margin: 6px auto; padding: 0 6px; }
                    .card { padding: 10px; margin-bottom: 8px; border-radius: 8px; }
                    .h1 { font-size: 17px; margin-bottom: 2px; }
                    .row { gap: 6px; margin-bottom: 6px; }
                    .col { gap: 2px; }
                    .lbl { font-size: 10px; letter-spacing: 0.3px; }
                    .txt { width: 100%; font-size: 14px; padding: 7px; }
                    .current-loc { font-size: 20px; }
                    .btn { padding: 7px 10px; font-size: 12px; }
                    .btn-red { padding: 5px 8px; font-size: 11px; }
                    .status-bar { padding: 4px 10px; font-size: 11px; }

                    /* Grid: compact for small screens */
                    .grid { font-size: 11px; }
                    .grid th { padding: 5px 3px; font-size: 10px; }
                    .grid td { padding: 4px 3px; }
                    .grid th a { font-size: 10px; }

                    /* Badges smaller */
                    .badge-saved, .badge-pending, .badge-404, .badge-moved, .badge-flagged {
                        font-size: 9px; padding: 2px 4px;
                    }

                    /* Auto-hide non-essential grid columns on mobile:
                       1=Checkbox  5=Serial#  6=CMR  7=DB Loc  8=Scanned Loc */
                    #GridScans.grid th:nth-child(1), #GridScans.grid td:nth-child(1),
                    #GridScans.grid th:nth-child(5), #GridScans.grid td:nth-child(5),
                    #GridScans.grid th:nth-child(6), #GridScans.grid td:nth-child(6),
                    #GridScans.grid th:nth-child(7), #GridScans.grid td:nth-child(7),
                    #GridScans.grid th:nth-child(8), #GridScans.grid td:nth-child(8) {
                        display: none !important;
                    }

                    /* Hide column toggle on mobile (CSS auto-hides already) */
                    button[onclick="toggleColMenu()"] { display: none !important; }
                    #ColToggleContainer { display: none !important; }

                    /* Bottom buttons wrap tighter */
                    .row > div { flex-wrap: wrap; gap: 6px; }
                }
            </style>
            <script>
                // ── Service Worker Registration ───────────────────────────────────────
                (function() {
                    if (!('serviceWorker' in navigator)) return;
                    navigator.serviceWorker.register('sw.js').then(function(reg) {
                        if (reg.waiting) reg.waiting.postMessage({ type: 'SKIP_WAITING' });
                    }).catch(function(err) {
                        console.warn('[Inventory] SW registration failed:', err);
                    });
                })();

                // ── Constants & State ──────────────────────────────────────────────────
                const OFFLINE_KEY    = 'Inventory_OfflineQueue';
                const OFFLINE_LOC    = 'Inventory_CurrentLocation';
                const OFFLINE_SITE   = 'Inventory_SelectedSite';
                const OFFLINE_SITETX = 'Inventory_SelectedSiteText';
                const OFFLINE_EMPL   = 'Inventory_SelectedOperator';
                const PING_TIMEOUT   = 3000;
                let   _isOnline      = navigator.onLine;
                let   _probeInFlight = false;
                let   _probeTimer    = null;

                // ── Connectivity Probe ─────────────────────────────────────────────
                function probeConnectivity() {
                    if (_probeInFlight) {
                        if (_probeTimer) return Promise.resolve(_isOnline);
                        _probeTimer = setTimeout(function() {
                            _probeInFlight = false;
                            _probeTimer = null;
                        }, 5000);
                        return Promise.resolve(_isOnline);
                    }
                    _probeInFlight = true;

                    return new Promise(function(resolve) {
                        var xhr = new XMLHttpRequest();
                        xhr.timeout = PING_TIMEOUT;
                        xhr.open('HEAD', 'va_inventory.aspx?_nocache=' + Date.now(), true);
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
                        const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                        const btnSync = document.getElementById('btnSync');
                        if (btnSync) btnSync.style.display = queue.length > 0 ? 'inline-block' : 'none';
                    } else {
                        const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                        indicator.innerHTML = '&bull; OFFLINE &mdash; Scans queuing locally (' + queue.length + ' queued)';
                        indicator.style.color = 'var(--danger)';
                    }
                }

                function checkConnectivity() {
                    return probeConnectivity().then(online => {
                        updateIndicator(online);
                        return online;
                    });
                }

                window.addEventListener('online',  function() {
                    checkConnectivity();
                    setTimeout(checkConnectivity, 1000);
                    setTimeout(checkConnectivity, 3000);
                });
                window.addEventListener('offline', function() {
                    updateIndicator(false);
                });

                // ── Offline Location, Site & Operator Persistence ─────────────────
                function persistLocation(loc) {
                    if (loc && loc !== '(None Set)') localStorage.setItem(OFFLINE_LOC, loc);
                }
                function restoreLocation() {
                    const lbl = document.getElementById('LblCurrentLocation');
                    if (!lbl) return;
                    const current = lbl.innerText.trim();
                    if (current === '' || current === '(None Set)') {
                        const saved = localStorage.getItem(OFFLINE_LOC);
                        if (saved) lbl.innerText = saved;
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
                    } else if (ddl.value) {
                        persistOperator(ddl.value);
                    }
                }

                // ── Barcode Validation (enforces 3-digit station prefix across all VA sites) ──
                const BARCODE_REGEX = /^\d{3} EE\w+$/i;
                function validateBarcode(barcode) {
                    if (!barcode || !BARCODE_REGEX.test(barcode.trim())) {
                        return { valid: false, reason: 'Invalid barcode format: "' + barcode + '". Expected 3-digit station prefix + space + EE + asset ID (e.g. "613 EE123456" or "512 EE789012").' };
                    }
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

                // ── Live Grid Visual Feedback (Offline) ─────────────────────────────
                function updateGridRowOffline(cleanBarcode) {
                    var grid = document.getElementById('GridScans');
                    if (!grid) return false;
                    var rows = grid.querySelectorAll('tr:not(:first-child)');
                    for (var i = 0; i < rows.length; i++) {
                        var cells = rows[i].querySelectorAll('td');
                        for (var c = 0; c < cells.length; c++) {
                            if (cells[c].innerText.trim().toUpperCase() === cleanBarcode) {
                                var statusSpan = rows[i].querySelector('span');
                                if (statusSpan) {
                                    statusSpan.className = 'badge-pending';
                                    statusSpan.innerText = 'Found (Pending)';
                                }
                                rows[i].style.backgroundColor = 'rgba(46, 168, 255, 0.12)';
                                return true;
                            }
                        }
                    }
                    return false;
                }

                function saveOffline(barcode) {
                    if (!barcode) return;
                    var cleanBc = barcode.trim().toUpperCase();

                    // EPC raw tag normalization
                    var epcMatch = cleanBc.match(/^(\d{3})EE(\w+)$/i);
                    if (epcMatch) cleanBc = epcMatch[1] + ' EE' + epcMatch[2];

                    var check = validateBarcode(cleanBc);
                    if (!check.valid) {
                        alert(check.reason);
                        var txtAsset = document.getElementById('TxtAssetScan');
                        if (txtAsset) { txtAsset.value = ''; txtAsset.focus(); }
                        return;
                    }

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
                    var lblLoc = document.getElementById('LblCurrentLocation');
                    var location = (lblLoc && lblLoc.innerText.trim() !== '' && lblLoc.innerText.trim() !== '(None Set)')
                        ? lblLoc.innerText.trim()
                        : (localStorage.getItem(OFFLINE_LOC) || '');
                    if (!location || location === '(None Set)') {
                        alert('You must scan a Location first before scanning assets!');
                        var locBox = document.getElementById('TxtLocationScan');
                        if (locBox) { locBox.value = ''; locBox.focus(); }
                        return;
                    }

                    const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    var existingIdx = queue.findIndex(function(x) { return (x.Barcode || '').toUpperCase() === cleanBc; });
                    const item = {
                        Barcode: cleanBc,
                        Location: location,
                        CompanyId: siteVal,
                        EmplId: emplVal,
                        TagDate: new Date().toLocaleDateString('en-CA'),
                        Status: 'Offline - Pending'
                    };

                    if (existingIdx >= 0) {
                        queue[existingIdx] = item;
                    } else {
                        queue.push(item);
                    }
                    localStorage.setItem(OFFLINE_KEY, JSON.stringify(queue));
                    updateOfflineUI();
                    updateIndicator(false);

                    // Update row in grid if present in current room sweep
                    updateGridRowOffline(cleanBc);
                }

                function removeOfflineItem(index) {
                    var queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    if (index >= 0 && index < queue.length) {
                        queue.splice(index, 1);
                        localStorage.setItem(OFFLINE_KEY, JSON.stringify(queue));
                        updateOfflineUI();
                        updateIndicator(_isOnline);
                    }
                }

                function updateOfflineUI() {
                    const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    const card = document.getElementById('pnlOffline');
                    const list = document.getElementById('offline-list');
                    const btnSync = document.getElementById('btnSync');

                    if (queue.length > 0) {
                        if (card) card.style.display = 'block';
                        if (btnSync) btnSync.style.display = 'inline-block';
                        if (list) {
                            list.innerHTML = queue.map(function(item, idx) {
                                return '<li style="display:flex; align-items:center; gap:8px; padding:3px 0;">'
                                    + '<strong>' + item.Barcode + '</strong> &mdash; ' + item.Location
                                    + ' <button type="button" onclick="removeOfflineItem(' + idx + ')" '
                                    + '  style="background:var(--danger);color:#fff;border:none;border-radius:4px;padding:2px 6px;font-size:10px;cursor:pointer;">X</button>'
                                    + '</li>';
                            }).join('');
                        }
                    } else {
                        if (card) card.style.display = 'none';
                        if (btnSync) btnSync.style.display = 'none';
                    }
                }

                async function syncScans() {
                    const queue = JSON.parse(localStorage.getItem(OFFLINE_KEY) || '[]');
                    if (queue.length === 0) return;

                    const btnSync = document.getElementById('btnSync');
                    if (btnSync) { btnSync.disabled = true; btnSync.innerText = 'Syncing...'; }

                    try {
                        const resp = await fetch('va_inventory.aspx?action=sync', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(queue)
                        });

                        if (resp.ok) {
                            const resData = await resp.json().catch(() => ({}));
                            localStorage.removeItem(OFFLINE_KEY);
                            alert('Sync complete! ' + (resData.count || queue.length) + ' scan(s) committed.');
                            window.location.href = 'va_inventory.aspx?_synced=' + Date.now();
                        } else {
                            const txt = await resp.text().catch(() => '');
                            alert('Sync failed (HTTP ' + resp.status + '). Will retry later.\n' + txt);
                            if (btnSync) { btnSync.disabled = false; btnSync.innerText = 'Sync Now'; }
                        }
                    } catch (e) {
                        alert('Error syncing: ' + e.message);
                        if (btnSync) { btnSync.disabled = false; btnSync.innerText = 'Sync Now'; }
                    }
                }

                function toggleConfigPanel() {
                    const panel = document.getElementById('locationConfigPanel');
                    const btn = document.getElementById('BtnToggleConfig');
                    if (!panel) return;
                    if (panel.style.display === 'none') {
                        panel.style.display = 'block';
                        if(btn) btn.innerHTML = '&#9881; Hide Config';
                        localStorage.setItem('aw_tagteam_config_hidden', 'false');
                    } else {
                        panel.style.display = 'none';
                        if(btn) btn.innerHTML = '&#9881; Show Config';
                        localStorage.setItem('aw_tagteam_config_hidden', 'true');
                    }
                }

                document.addEventListener('DOMContentLoaded', () => {
                    if (localStorage.getItem('aw_tagteam_config_hidden') === 'true') {
                        const panel = document.getElementById('locationConfigPanel');
                        if (panel) panel.style.display = 'none';
                        const btn = document.getElementById('BtnToggleConfig');
                        if (btn) btn.innerHTML = '&#9881; Show Config';
                    }

                    // Restore Site, Operator, and Location
                    restoreSite();
                    restoreOperator();
                    restoreLocation();

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

                    // Enter key capture on scan boxes
                    var scanBoxEl = document.getElementById('TxtAssetScan');
                    if (scanBoxEl) {
                        scanBoxEl.addEventListener('keydown', function(e) {
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

                    checkConnectivity();
                    setInterval(checkConnectivity, 4000);
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
                            input.style.color = 'var(--text)';
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

                    function handleOfflineScan() {
                        const txtAsset = document.getElementById('TxtAssetScan');
                        const locScan = document.getElementById('TxtLocationScan');
                        if (locScan && locScan.value.trim() !== '') {
                            const newLoc = locScan.value.trim().toUpperCase();
                            if (!newLoc.startsWith("SP") || newLoc.indexOf("EE") !== -1) {
                                alert('Invalid Location format: "' + newLoc + '". Location barcodes must start with SP (e.g. SP...).');
                                locScan.value = '';
                                locScan.focus();
                                return;
                            }
                            var lbl = document.getElementById('LblCurrentLocation');
                            if (lbl) lbl.innerText = newLoc;
                            var lblTotal = document.getElementById('LblLocationTotal');
                            if (lblTotal) lblTotal.style.display = 'none';
                            persistLocation(newLoc);
                            locScan.value = '';
                            if (txtAsset) setTimeout(function() { txtAsset.focus(); }, 50);
                            return;
                        }
                        if (txtAsset && txtAsset.value.trim() !== '') {
                            saveOffline(txtAsset.value.trim());
                            txtAsset.value = '';
                            setTimeout(function() { txtAsset.focus(); }, 50);
                            return;
                        }
                    }

                    // 1. Intercept ASP.NET AutoPostBacks when offline OR batch mode
                    const originalDoPostBack = window.__doPostBack;
                    window.__doPostBack = function(eventTarget, eventArgument) {
                        if (!_isOnline || !navigator.onLine) {
                            handleOfflineScan();
                            return false;
                        }
                        if (window._batchMode && eventTarget === 'TxtAssetScan') {
                            handleBatchScan();
                            return false;
                        }
                        if (originalDoPostBack) {
                            originalDoPostBack(eventTarget, eventArgument);
                        }
                    };

                    // 2. Intercept ALL standard form submits (e.g. clicking buttons or pressing Enter)
                    window.addEventListener('submit', function(e) {
                         if (!_isOnline || !navigator.onLine) {
                             e.preventDefault();
                             e.stopImmediatePropagation();
                             handleOfflineScan();
                             return false;
                         }
                         // Batch mode: intercept scan submits, but allow batch submit through
                         if (window._batchMode && !window._isSubmittingBatch) {
                             var txt = document.getElementById('TxtAssetScan');
                             if (txt && txt.value.trim()) {
                                 e.preventDefault();
                                 e.stopImmediatePropagation();
                                 handleBatchScan();
                                 return false;
                             }
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

                function toggleAllPrint(source) {
                    const checkboxes = document.querySelectorAll('.chk-print');
                    checkboxes.forEach(cb => cb.checked = source.checked);
                    updatePrintBtn();
                }

                document.addEventListener('change', function(e) {
                    if(e.target && e.target.classList.contains('chk-print')) {
                        updatePrintBtn();
                    }
                });

                function updatePrintBtn() {
                    const checked = document.querySelectorAll('.chk-print:checked');
                    const btn = document.getElementById('BtnPrintChecked');
                    const ddlTpl = document.getElementById('DdlPrintTemplate');
                    const ddlTgt = document.getElementById('DdlPrintTarget');
                    
                    if(checked.length > 0) {
                        if(btn) {
                            btn.style.display = 'inline-block';
                            btn.innerText = 'Server Print (' + checked.length + ')';
                        }
                        if(ddlTpl) ddlTpl.style.display = 'inline-block';
                        if(ddlTgt) ddlTgt.style.display = 'inline-block';
                    } else {
                        if(btn) btn.style.display = 'none';
                        if(ddlTpl) ddlTpl.style.display = 'none';
                        if(ddlTgt) ddlTgt.style.display = 'none';
                    }
                }

                async function printCheckedTags() {
                    const checked = document.querySelectorAll('.chk-print:checked');
                    if (checked.length === 0) return;

                    const ddlTpl = document.getElementById('DdlPrintTemplate');
                    const ddlTgt = document.getElementById('DdlPrintTarget');
                    const forceTplId = ddlTpl && ddlTpl.value ? parseInt(ddlTpl.value, 10) : null;
                    const forceTgt = ddlTgt && ddlTgt.value ? ddlTgt.value : null;

                    const payload = [];
                    checked.forEach(cb => {
                        const assetId = parseInt(cb.value, 10);
                        const tagType = cb.getAttribute('data-tagtype');
                        
                        let match = null;
                        let targetType = 'Default';
                        let targetValue = '';

                        if (forceTplId) {
                            match = window.awPrintConfig.printTemplates.find(item => item.id === forceTplId);
                        } else if (window.awPrintConfig) {
                            if (window.awPrintConfig.templateMappings && window.awPrintConfig.templateMappings[tagType]) {
                                const mapObj = window.awPrintConfig.templateMappings[tagType];
                                const mappedId = typeof mapObj === 'object' ? mapObj.TemplateID : parseInt(mapObj, 10);
                                if (typeof mapObj === 'object') {
                                    targetType = mapObj.TargetType || 'Default';
                                    targetValue = mapObj.TargetValue || '';
                                }
                                match = window.awPrintConfig.printTemplates.find(item => item.id === mappedId);
                            }
                            if (!match && window.awPrintConfig.printTemplates) {
                                match = window.awPrintConfig.printTemplates.find(item => item.name === tagType);
                            }
                            if (!match && window.awPrintConfig.printTemplates && window.awPrintConfig.printTemplates.length > 0) {
                                match = window.awPrintConfig.printTemplates[0];
                            }
                        }

                        if (match && !isNaN(assetId) && assetId > 0) {
                            let routingService = window.awPrintConfig && window.awPrintConfig.templateRoutes ? window.awPrintConfig.templateRoutes[match.id] : null;
                            if (!routingService) routingService = match.useWithService || 'print';
                            
                            if (targetType === 'Client' && targetValue.length > 0) routingService = targetValue;
                            if (targetType === 'Service' && targetValue.length > 0) routingService = targetValue;
                            
                            if (forceTgt) routingService = forceTgt;

                            payload.push({
                                recordID: assetId,
                                templateID: match.id,
                                tableName: 'Asset',
                                useWithService: routingService,
                                completed: false
                            });
                        }
                    });

                    if (payload.length === 0) {
                        alert('No valid Asset IDs or templates mapped. Please select a Print Template manually if auto-mapping fails.');
                        return;
                    }

                    try {
                        const btn = document.getElementById('BtnPrintChecked');
                        const originalText = btn.innerText;
                        btn.innerText = 'Printing...';
                        btn.disabled = true;

                        // Delegate print call to tagteam_scan API endpoint to avoid code duplication
                        const resp = await fetch('va_tagteam_scan.aspx?action=print', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json; charset=utf-8' },
                            body: JSON.stringify(payload)
                        });

                        if (resp.ok) {
                            alert('Sent ' + payload.length + ' tags to print successfully.');
                            checked.forEach(cb => cb.checked = false);
                            const checkAll = document.getElementById('chkAllPrint');
                            if(checkAll) checkAll.checked = false;
                            updatePrintBtn();
                        } else {
                            alert('Print API returned an error: ' + resp.status);
                        }

                        btn.innerText = originalText;
                        btn.disabled = false;
                    } catch (e) {
                        alert('Error calling print service: ' + e.message);
                        document.getElementById('BtnPrintChecked').disabled = false;
                    }
                }

                // --- WEBSERIAL: USB RFID READER SUPPORT ---
                // NOTE: Unlike the ENNX scanners (which are fully client-side), this page uses
                // ASP.NET AutoPostBack. Each scan triggers a full page reload. So the serial
                // port will disconnect after every scan. We set the value and fire __doPostBack.
                let serialPort = null;
                let serialReader = null;
                let serialKeepReading = false;
                let serialBuffer = '';

                function serialOpenClose() {
                    if (!('serial' in navigator)) {
                        document.getElementById('serialStatus').innerHTML = '<b>Status:</b> <span style="color:var(--danger);">Not Available</span>';
                        document.getElementById('serialHint').innerHTML = '<span style="color:var(--danger);"><b>WebSerial not available.</b> Requires Chrome or Edge, served over HTTPS (or localhost). Keyboard/DataWedge input still works normally.</span>';
                        return;
                    }

                    (async function () {
                        try {
                            serialPort = await navigator.serial.requestPort();
                            await serialPort.open({
                                baudRate: 115200,
                                bufferSize: 1024,
                                dataBits: 8,
                                flowControl: 'hardware',
                                parity: 'none',
                                stopBits: 1
                            });

                            serialKeepReading = true;
                            document.getElementById('btnSerialOpen').style.display = 'none';
                            document.getElementById('btnSerialClose').style.display = '';
                            document.getElementById('serialStatus').innerHTML = '<b>Status:</b> <span style="color:var(--accent-2);">Connected</span>';

                            const textDecoder = new TextDecoderStream();
                            const readableStreamClosed = serialPort.readable.pipeTo(textDecoder.writable);
                            serialReader = textDecoder.readable.getReader();

                            try {
                                while (serialKeepReading) {
                                    const { value, done } = await serialReader.read();
                                    if (done) break;
                                    serialBuffer += value;
                                    let lines = serialBuffer.split('\n');
                                    serialBuffer = lines.pop();
                                    for (const line of lines) {
                                        const trimmed = line.replace(/\r/g, '').trim();
                                        if (trimmed) {
                                            // Set the ASP.NET TextBox value and trigger postback
                                            const txt = document.getElementById('TxtAssetScan');
                                            if (txt) {
                                                txt.value = trimmed;
                                                // Trigger the same __doPostBack that AutoPostBack uses
                                                if (typeof __doPostBack === 'function') {
                                                    __doPostBack('TxtAssetScan', '');
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch (err) {
                                console.error('Serial read error:', err);
                            } finally {
                                serialReader.releaseLock();
                                await readableStreamClosed.catch(function () { });
                            }

                            await serialPort.close();
                            serialPort = null;
                            document.getElementById('btnSerialOpen').style.display = '';
                            document.getElementById('btnSerialClose').style.display = 'none';
                            document.getElementById('serialStatus').innerHTML = '<b>Status:</b> Disconnected';

                        } catch (err) {
                            console.error('Serial port error:', err);
                        }
                    })();
                }

                function serialClose() {
                    serialKeepReading = false;
                    if (serialReader) {
                        try { serialReader.cancel(); } catch (e) { }
                    }
                }

                // === BATCH SCAN MODE ===
                window._batchMode = false;
                window._isSubmittingBatch = false;
                var _batchQueue = [];

                function parseEEBarcode(raw) {
                    raw = (raw || '').trim().toUpperCase();
                    var match = raw.match(/(\d{3})EE(\d+)/);
                    if (match) return match[1] + ' EE' + match[2];
                    return raw;
                }

                function toggleBatchMode() {
                    window._batchMode = !window._batchMode;
                    var btn = document.getElementById('btnBatchToggle');
                    var panel = document.getElementById('batchPanel');
                    var list = document.getElementById('batchList');
                    if (window._batchMode) {
                        btn.innerText = '\uD83D\uDCE1 Batch ON \u2014 Scanning...';
                        btn.style.background = 'var(--accent-2)';
                        btn.style.color = '#000';
                        btn.style.borderColor = 'var(--accent-2)';
                        panel.style.display = 'inline-flex';
                        list.style.display = 'block';
                    } else {
                        btn.innerText = '\uD83D\uDCE1 Batch Mode';
                        btn.style.background = 'var(--chip)';
                        btn.style.color = 'var(--text)';
                        btn.style.borderColor = 'var(--line)';
                        panel.style.display = 'none';
                        list.style.display = 'none';
                        _batchQueue = [];
                        updateBatchUI();
                    }
                    var txt = document.getElementById('TxtAssetScan');
                    if (txt) txt.focus();
                }

                function handleBatchScan() {
                    var txt = document.getElementById('TxtAssetScan');
                    if (!txt) return;
                    var raw = txt.value.trim();
                    if (!raw) return;
                    var parsed = parseEEBarcode(raw);
                    // Deduplicate
                    var found = false;
                    for (var i = 0; i < _batchQueue.length; i++) {
                        if (_batchQueue[i] === parsed) { found = true; break; }
                    }
                    if (!found) _batchQueue.push(parsed);
                    txt.value = '';
                    txt.focus();
                    updateBatchUI();
                    // Audio feedback
                    try { new Audio('data:audio/wav;base64,UklGRl9vT19teleUQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoAAAAAA==').play(); } catch(e) {}
                }

                function updateBatchUI() {
                    var countEl = document.getElementById('batchCount');
                    if (countEl) countEl.innerText = _batchQueue.length;
                    var listEl = document.getElementById('batchList');
                    if (!listEl) return;
                    if (_batchQueue.length === 0) {
                        listEl.innerHTML = '<span style="color:var(--muted); font-size:12px;">Hold trigger \u2014 tags queue here instead of posting individually.</span>';
                    } else {
                        var html = '';
                        for (var i = 0; i < _batchQueue.length; i++) {
                            html += '<span style="display:inline-block; background:var(--chip); border:1px solid var(--line); padding:2px 8px; border-radius:4px; margin:2px; font-size:11px;">' + _batchQueue[i] + '</span>';
                        }
                        listEl.innerHTML = html;
                    }
                }

                function clearBatch() {
                    _batchQueue = [];
                    updateBatchUI();
                    var txt = document.getElementById('TxtAssetScan');
                    if (txt) txt.focus();
                }

                function submitBatch() {
                    if (_batchQueue.length === 0) return;
                    window._isSubmittingBatch = true;
                    document.getElementById('HidBatchData').value = JSON.stringify(_batchQueue);
                    document.getElementById('BtnSubmitBatch').click();
                }
            </script>
        </head>

        <body>
            <form id="form1" runat="server">
                <div class="status-bar">
                    <span>AssetWorx VA Site Inventory</span>
                    <span id="connection-indicator">Checking Connection...</span>
                </div>
                <div class="wrap">
                    <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px;margin-bottom:5px;">
                        <div class="h1">VA Site Inventory</div>
                        <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
                            <a href="documentation/va_inventory.html" class="btn btn-ghost btn-sm mobile-hide" style="text-decoration:none; font-size:12px;">&#128214; View Docs</a>
                            <asp:LinkButton ID="BtnRefreshData" runat="server" OnClick="BtnRefreshData_Click" CssClass="btn mobile-hide" style="background:var(--btn-alt); color:var(--accent); border:1px solid var(--line); font-size:13px; font-weight:600; padding:8px 12px;" UseSubmitBehavior="false">Refresh App Data</asp:LinkButton>
                            <button type="button" class="btn" id="BtnToggleConfig" style="background:var(--btn-alt); color:var(--text); border:1px solid var(--line); font-size:13px; font-weight:600; padding:8px 12px; cursor:pointer;" onclick="toggleConfigPanel()">&#9881; Hide Config</button>
                            <a href="index.aspx" style="text-decoration:none; padding:7px 18px; border-radius:999px; border:1.5px solid var(--line); color:var(--muted); font-size:14px; font-weight:500; transition:all 0.2s;">&#8962; Hub</a>
                        </div>
                    </div>
                    <div class="sub">Rapidly scan and correct asset data. Logic: Scan Location -> Scan Assets.</div>

                    <!-- OFFLINE QUEUE -->
                    <div id="pnlOffline" class="card offline-card">
                        <div style="display:flex; justify-content:space-between; align-items:center;">
                            <div>
                                <h3 style="margin:0; color:var(--danger);">Offline Scans Pending Sync</h3>
                                <ul id="offline-list" style="margin:10px 0; font-size:14px; color:var(--muted);"></ul>
                            </div>
                            <button id="btnSync" type="button" class="btn btn-green" onclick="syncScans()">Sync
                                Now</button>
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
                                        OnTextChanged="BtnSetLocation_Click" />
                                </div>
                                <div class="col" style="flex:1;">
                                    <span class="lbl">Current Location Mode</span>
                                    <asp:Label ID="LblCurrentLocation" runat="server" CssClass="current-loc" Text="(None Set)" ClientIDMode="Static" />
                                    <asp:Label ID="LblLocationTotal" runat="server" style="color:#10b981; font-weight:600; font-size:12px; margin-top:2px; display:none;" />
                                </div>
                                <div class="col mobile-hide">
                                    <span class="lbl">Sweep Date</span>
                                    <asp:TextBox ID="TxtCurrentDate" runat="server" CssClass="txt" TextMode="Date" ClientIDMode="Static" />
                                </div>
                                <div class="col" style="justify-content:center; padding-bottom: 10px;">
                                    <label style="display:flex; align-items:center; gap:5px; font-size:13px; cursor:pointer; font-weight:600;">
                                        <asp:CheckBox ID="ChkQueueMode" runat="server" />
                                        Queue Misplaced Scans
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 2. ASSET SCANNING -->
                    <asp:Panel ID="PnlScan" runat="server" DefaultButton="BtnAdd" CssClass="card">
                        <div class="row">
                            <div class="col">
                                <span class="lbl" style="color:var(--accent);">2. Scan Asset Barcode</span>
                                <asp:TextBox ID="TxtAssetScan" runat="server" CssClass="txt" style="border-color:var(--accent); font-size:16px;" placeholder="Scan EE Tag..." AutoPostBack="true" OnTextChanged="BtnAddAsset_Click" ClientIDMode="Static" />
                            </div>
                            <div class="col" style="justify-content:flex-end;">
                                <asp:Button ID="BtnAdd" runat="server" Text="Manual Add" OnClick="BtnAddAsset_Click" CssClass="btn btn-blue" />
                            </div>
                        </div>

                        <!-- BATCH SCAN MODE -->
                        <div style="margin-top:8px; display:flex; align-items:center; gap:8px; flex-wrap:wrap;">
                            <button type="button" id="btnBatchToggle" class="btn" style="background:var(--chip); color:var(--text); border:1px solid var(--line); font-size:12px; padding:6px 12px;" onclick="toggleBatchMode()">&#128225; Batch Mode</button>
                            <span id="batchPanel" style="display:none; align-items:center; gap:8px; flex-wrap:wrap;">
                                <span style="font-weight:700; color:var(--accent-2); font-size:18px;" id="batchCount">0</span>
                                <span style="color:var(--muted); font-size:12px;">tags queued</span>
                                <button type="button" class="btn btn-green" style="font-size:12px; padding:5px 12px;" onclick="submitBatch()">Submit Batch</button>
                                <button type="button" class="btn" style="background:#555; font-size:12px; padding:5px 10px;" onclick="clearBatch()">Clear</button>
                            </span>
                        </div>
                        <div id="batchList" style="display:none; margin-top:6px; max-height:100px; overflow-y:auto;"></div>
                        <asp:HiddenField ID="HidBatchData" runat="server" ClientIDMode="Static" />
                        <asp:Button ID="BtnSubmitBatch" runat="server" Text="Submit Batch" OnClick="BtnSubmitBatch_Click" style="display:none;" ClientIDMode="Static" />

                        <!-- WebSerial: Connect USB RFID Reader -->
                        <details class="serial-section" id="serialSection">
                            <summary>&#9658; WebSerial &mdash; Connect USB RFID Reader</summary>
                            <div class="serial-btnbar">
                                <button type="button" class="btn btn-blue" id="btnSerialOpen"
                                    onclick="serialOpenClose()">Select/Open Serial Port</button>
                                <button type="button" class="btn btn-red" id="btnSerialClose" style="display:none"
                                    onclick="serialClose()">Close Port</button>
                                <span style="font-size:13px;" id="serialStatus"><b>Status:</b> Disconnected</span>
                            </div>
                            <div class="serial-hint" id="serialHint">
                                WebSerial requires Chrome or Edge served over HTTPS (or localhost).
                                Each serial read will be submitted to the server as if it were scanned via keyboard.
                                <b>Note:</b> Each scan triggers a page reload. The serial connection will close and must be reopened.
                            </div>
                        </details>

                        <asp:Literal ID="LitMsg" runat="server" />
                        <asp:Literal ID="LitPrintConfig" runat="server" />
                        <asp:Literal ID="LitPrintScript" runat="server" />

                        <!-- GRID -->
                        <div style="margin-bottom:10px; display:flex; justify-content:space-between; align-items:flex-end; flex-wrap:wrap; gap:10px;">
                            <div style="display:flex; align-items:center; gap:10px;">
                                <span style="color:var(--muted); font-size:12px;">(Click header to sort. Type in boxes below headers to instantly filter rows.)</span>
                                <asp:DropDownList ID="DdlCmrFilter" runat="server" AutoPostBack="true" OnSelectedIndexChanged="DdlCmrFilter_SelectedIndexChanged" CssClass="txt" style="display:inline-block; width:auto; font-size:12px; padding:6px 12px; background:var(--chip); border:1px solid var(--accent); color:var(--text); font-weight:600; min-width:180px;" Visible="false" />
                            </div>
                            <button type="button" class="btn" style="background:var(--chip); border:1px solid var(--accent); color:var(--text); font-size:12px; padding:6px 12px; cursor:pointer; border-radius:6px;" onclick="toggleColMenu()">&#9776; Columns</button>
                        </div>
                        
                        <!-- COLUMN TOGGLE LIST -->
                        <div id="ColToggleContainer" style="background:var(--chip); border:1px solid var(--line); border-radius:8px; padding:12px; margin-bottom:12px; display:none; flex-wrap:wrap; gap:10px; font-size:13px;"></div>

                        <asp:GridView ID="GridScans" runat="server" CssClass="grid" AutoGenerateColumns="false"
                            DataKeyNames="Guid" OnRowCommand="GridScans_RowCommand"
                            AllowSorting="true" OnSorting="GridScans_Sorting" ClientIDMode="Static">
                            <Columns>
                                <asp:TemplateField>
                                    <HeaderTemplate>
                                        <input type="checkbox" id="chkAllPrint" onclick="toggleAllPrint(this);" title="Select All for Print" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input type="checkbox" class="chk-print" value='<%# Eval("AssetId") %>' data-barcode='<%# Eval("Barcode") %>' data-tagtype='<%# Eval("TagType") %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Status" SortExpression="Status">
                                    <ItemTemplate>
                                        <span class='<%# 
                                            Eval("Status").ToString() == "Found" ? "badge-saved" : 
                                            Eval("Status").ToString() == "Moved Here" ? "badge-moved" : 
                                            Eval("Status").ToString() == "Found (Pending)" ? "badge-pending" : 
                                            Eval("Status").ToString() == "Moved Here (Pending)" ? "badge-flagged" : 
                                            Eval("Status").ToString() == "Pending Move" ? "badge-flagged" : 
                                            "badge-404" 
                                        %>'>
                                            <%# Eval("Status") %>
                                        </span>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField DataField="Barcode" HeaderText="Asset Tag" ReadOnly="true" SortExpression="Barcode" />
                                <asp:BoundField DataField="Description" HeaderText="Description" ReadOnly="true" SortExpression="Description" />
                                <asp:BoundField DataField="SerialNumber" HeaderText="Serial Number" ReadOnly="true" SortExpression="SerialNumber" />
                                <asp:BoundField DataField="CMR" HeaderText="CMR" ReadOnly="true" SortExpression="CMR" />
                                <asp:BoundField DataField="DbLocation" HeaderText="Current Loc (DB)" ReadOnly="true" SortExpression="DbLocation" />
                                <asp:BoundField DataField="CurrentLocation" HeaderText="Scanned Loc" ReadOnly="true" SortExpression="CurrentLocation" />

                                <asp:TemplateField>
                                    <ItemTemplate>
                                        <asp:Button runat="server" CommandName="Remove" CommandArgument='<%# Eval("Guid") %>' Text="Remove" CssClass="btn-red" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div style="padding:20px;text-align:center;color:var(--muted);">No scans yet. Set location and start scanning assets.</div>
                            </EmptyDataTemplate>
                        </asp:GridView>

                        <div class="row" style="margin-top:20px; justify-content:space-between; align-items:center;">
                            <div style="display:flex; gap:10px; align-items:center;">
                                <asp:Button ID="BtnClear" runat="server" Text="Clear Table" OnClick="BtnClear_Click" CssClass="btn" Style="background:#333;" OnClientClick="return confirm('Clear list?');" />
                                <select id="DdlPrintTemplate" class="txt" style="display:none; padding:8px; font-size:12px; width:auto; border-color:var(--accent);">
                                    <option value="">-- Print Template --</option>
                                </select>
                                <select id="DdlPrintTarget" class="txt" style="display:none; padding:8px; font-size:12px; width:auto; border-color:var(--accent);">
                                    <option value="">-- Default Route --</option>
                                </select>
                                <button type="button" id="BtnPrintChecked" class="btn btn-blue" onclick="printCheckedTags();" style="display:none;">Server Print (#)</button>
                                <asp:Button ID="BtnCommitMoves" runat="server" Text="Commit Scans" OnClick="BtnCommitMoves_Click" CssClass="btn btn-green" Visible="false" />
                            </div>
                            <div style="display:flex; gap:10px; align-items:center;">
                                <asp:Button ID="BtnPreviewEnnx" runat="server" Text="Build ENNX" OnClick="BtnPreviewEnnx_Click" CssClass="btn" Style="background:#555;" />
                                <asp:Button ID="BtnExportExcel" runat="server" Text="Export Excel" OnClick="BtnExportExcel_Click" CssClass="btn btn-green" />
                                <asp:Button ID="BtnEmail" runat="server" Text="Email Results" OnClick="BtnEmail_Click" CssClass="btn btn-blue" />
                            </div>
                        </div>

                        <div style="margin-top:10px;">
                            <asp:TextBox ID="TxtPreview" runat="server" TextMode="MultiLine" Rows="10" Style="width:100%; background:var(--chip); color:var(--text); border:1px solid var(--line); font-family:monospace;" ReadOnly="true" />
                        </div>

                    </asp:Panel>

                    <idash:Footer runat="server" />
                </div>
            </form>
        </body>

        </html>


