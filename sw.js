// ── AssetWorx Tag Team Scan – Service Worker v7 ─────────────────────────────
// Changes from v5:
//  • Bumped cache name to force clean reinstall on all devices
//  • POST requests to ASPX pages are now intercepted: if a POST fails (network
//    error, timeout), the SW returns the cached GET page shell so the browser
//    NEVER shows "This site can't be reached" — the page JS handles offline
//    scanning instead.
//  • Static assets (CSS/JS) use cache-first strategy for instant offline load
//  • ASPX pages use network-first with a 7-second timeout; falls back to cache
//  • Added fetchWithTimeout helper

const CACHE_NAME   = 'assetworx-scanners-v12';
const STATIC_CACHE = 'assetworx-static-v12';

// Pages to cache on install — fetched fresh so the shell is always warm
const PAGES_TO_CACHE = [
  'va_tagteam_scan.aspx',
  'va_ennx_live_scan.aspx',
  'va_eil_live_scan.aspx',
  'va_inventory.aspx',
  'va_universal_ennx.aspx'
];

// Static assets — cached forever, served instantly offline
const STATICS_TO_CACHE = [
  'theme.css',
  'theme-init.js',
  'sw.js',
  'manifest.json'
];

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Race a fetch against a timeout. Rejects with an error if the timeout fires
 * first, causing the caller to fall back to the cache.
 */
function fetchWithTimeout(request, timeoutMs) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('SW fetch timeout')), timeoutMs);
    fetch(request).then(
      response => { clearTimeout(timer); resolve(response); },
      err      => { clearTimeout(timer); reject(err); }
    );
  });
}

/**
 * For a given POST request URL, find the matching cached GET page.
 * This strips query strings and tries to match the ASPX page path.
 */
function findCachedPage(requestUrl) {
  const url = new URL(requestUrl);
  // Build a clean URL without query params for cache lookup
  const cleanUrl = url.origin + url.pathname;
  return caches.open(CACHE_NAME).then(cache =>
    cache.match(new Request(cleanUrl), { ignoreSearch: true })
  );
}

// ── Install ──────────────────────────────────────────────────────────────────

self.addEventListener('install', event => {
  self.skipWaiting(); // Activate immediately so new SW is used right away

  event.waitUntil(
    Promise.all([
      // Cache ASPX pages (network-first shells)
      caches.open(CACHE_NAME).then(cache =>
        Promise.all(
          PAGES_TO_CACHE.map(url =>
            cache.add(new Request(url, { cache: 'reload' }))
                 .catch(err => console.warn('[SW] Failed to pre-cache page:', url, err))
          )
        )
      ),
      // Cache static assets (cache-first)
      caches.open(STATIC_CACHE).then(cache =>
        Promise.all(
          STATICS_TO_CACHE.map(url =>
            cache.add(new Request(url, { cache: 'reload' }))
                 .catch(err => console.warn('[SW] Failed to pre-cache static:', url, err))
          )
        )
      )
    ])
  );
});

// ── Activate ─────────────────────────────────────────────────────────────────

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(key => key !== CACHE_NAME && key !== STATIC_CACHE)
          .map(key => {
            console.log('[SW] Deleting old cache:', key);
            return caches.delete(key);
          })
      )
    ).then(() => clients.claim()) // Take control of all open tabs immediately
  );
});

// ── Fetch ─────────────────────────────────────────────────────────────────────

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  const path = url.pathname.toLowerCase();

  // ── Connectivity pings must ALWAYS hit the network ─────────────────────────
  // If we served these from cache, the page would think it's online when it's not.
  if (url.searchParams.has('_ping') || url.searchParams.has('_qp') || url.searchParams.has('_nocache')) {
    return; // Let the browser handle it directly — no SW interception
  }

  // ── POST requests (ASP.NET postbacks) ──────────────────────────────────────
  // This is the critical offline safety net. When the user scans a barcode and
  // __doPostBack fires a POST but the network is down, the browser would
  // normally show "This site can't be reached". Instead, we intercept the
  // failed POST and return the cached page HTML so the page stays alive and
  // the client-side JS can handle the scan offline.
  if (event.request.method === 'POST') {
    const isAspxPage = path.endsWith('.aspx') && !path.includes('action=sync');
    const isAdminPage = path.includes('va_dbupdate') || path.includes('va_autodbupdate');
    if (isAspxPage && !isAdminPage) {
      event.respondWith(
        fetch(event.request.clone()).catch(() => {
          console.log('[SW] POST failed (offline), returning cached page shell for:', path);
          return findCachedPage(event.request.url).then(cached => {
            if (cached) return cached;
            // No cached page — return a minimal offline HTML that tells the
            // page JS to take over
            return new Response(
              '<html><body style="font-family:sans-serif;padding:30px;background:#0f172a;color:#f8fafc">' +
              '<h2>&#128683; Offline</h2>' +
              '<p>You are offline. Your scan has been saved locally and will sync when you reconnect.</p>' +
              '<p><a href="' + url.pathname + '" style="color:#38bdf8">Tap here to reload the page</a></p>' +
              '<script>' +
              '  // Signal to any surviving page JS that we went offline' +
              '  try { window._isOnline = false; } catch(e) {}' +
              '</script>' +
              '</body></html>',
              { headers: { 'Content-Type': 'text/html' } }
            );
          });
        })
      );
    }
    // For non-ASPX POSTs (like the sync endpoint), let them pass through naturally
    return;
  }

  // ── GET: Strategy 1 — Cache-first for known static assets ─────────────────
  // theme.css, theme-init.js, manifest.json, sw.js
  const isStatic = STATICS_TO_CACHE.some(s => path.endsWith(s.toLowerCase()));
  if (isStatic) {
    event.respondWith(
      caches.match(event.request, { ignoreSearch: true }).then(cached => {
        if (cached) return cached;
        // Not in cache yet — fetch and store
        return fetch(event.request).then(response => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(STATIC_CACHE).then(c => c.put(event.request, clone));
          }
          return response;
        });
      })
    );
    return;
  }

  // ── GET: Strategy 2 — Network-first with 7s timeout for SCANNER pages only ─
  // Only intercept pages we explicitly cache. All other pages (login, admin,
  // index, etc.) are left alone so they ALWAYS go straight to the server.
  const isScannerPage = PAGES_TO_CACHE.some(p => path.endsWith(p.toLowerCase()));
  if (isScannerPage) {
    event.respondWith(
      fetchWithTimeout(event.request, 7000)
        .then(response => {
          // Cache a fresh copy of successful page loads
          if (response && response.status === 200 && response.type !== 'opaque') {
            const clone = response.clone();
            caches.open(CACHE_NAME).then(c =>
              c.put(new Request(event.request.url.split('?')[0]), clone)
            );
          }
          return response;
        })
        .catch(() => {
          // Network failed or timed out — serve from cache
          console.log('[SW] Network failed, serving from cache:', event.request.url);
          return caches.match(event.request, { ignoreSearch: true }).then(cached => {
            if (cached) return cached;
            // Nothing in cache — return a simple offline response
            return new Response(
              '<html><body style="font-family:sans-serif;padding:30px;background:#0f172a;color:#f8fafc">' +
              '<h2>Offline</h2>' +
              '<p>This page has not been cached yet. Please load it while online first, then it will be available offline.</p>' +
              '</body></html>',
              { headers: { 'Content-Type': 'text/html' } }
            );
          });
        })
    );
    return;
  }

  // ── All other GETs: pass through to network with no SW interception ────────
  // This ensures login pages, admin pages, API calls, etc. always hit the
  // server directly and are never blocked or served from cache.
});
