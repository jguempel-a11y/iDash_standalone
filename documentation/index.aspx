<%@ Page Language="C#" ResponseEncoding="utf-8" %>
<%
    bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
    if (!isLoggedIn) { Response.Redirect("../index.aspx"); return; }
    
    string role = Convert.ToString(Session["IdashUserRole"]);
    var tiles = Session["IdashTileAccess"] as System.Collections.Generic.List<string>;
    
    Func<string, bool> CanSee = (key) => {
        if (role == "admin") return true;
        if (tiles == null || tiles.Count == 0) return false;
        if (tiles.Contains("*")) return true;
        return tiles.Contains(key);
    };
    
    Func<string[], bool> CanSeeAny = (keys) => {
        if (role == "admin") return true;
        if (tiles == null || tiles.Count == 0) return false;
        if (tiles.Contains("*")) return true;
        foreach(var k in keys) {
            if (tiles.Contains(k)) return true;
        }
        return false;
    };
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>iDash Documentation Hub</title>
    <link rel="icon" type="image/png" href="../Assets/branding/rfid.png" />
    <link rel="stylesheet" href="docs_theme.css" />
    <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; align-items: stretch; }
        @media (max-width: 768px) { .grid { grid-template-columns: 1fr; } }
        .tile { 
            display: flex; flex-direction: column;
            padding: 22px; border: 1px solid var(--line); border-radius: 14px; 
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); 
            background: color-mix(in srgb, var(--text), transparent 98%);
            text-decoration: none !important; box-sizing: border-box;
        }
        .tile p { flex: 1; }
        .tile:hover { 
            border-color: var(--accent-docs); background: rgba(46, 168, 255, 0.05); 
            transform: translateY(-4px); box-shadow: 0 12px 24px rgba(0,0,0,0.2);
        }
        .tile-title { font-size: 19px; font-weight: 700; margin-bottom: 12px; display: flex; align-items: center; gap: 10px; }
        .chip { 
            display: inline-block; background: var(--line); color: var(--text); 
            padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.02em;
        }
        .back-link { display: inline-flex; align-items: center; gap: 8px; margin-bottom: 30px; font-size: 14px; color: var(--muted-docs); }
        .back-link:hover { color: var(--accent-docs); }

        /* Search bar */
        .search-bar { position:relative; margin-bottom:24px; }
        .search-bar input {
            width:100%; padding:14px 18px 14px 46px; border:1px solid var(--line-docs, var(--line));
            border-radius:12px; background:color-mix(in srgb, var(--text, #fff), transparent 97%);
            color:var(--text-docs, var(--text)); font-size:15px; font-family:inherit; outline:none;
            transition: border-color 0.2s, box-shadow 0.2s;
        }
        .search-bar input:focus {
            border-color: var(--accent-docs, var(--accent));
            box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent-docs, var(--accent)) 20%, transparent);
        }
        .search-bar input::placeholder { color: var(--muted-docs, var(--muted)); }
        .search-bar .search-icon {
            position:absolute; left:16px; top:50%; transform:translateY(-50%);
            color: var(--muted-docs, var(--muted)); pointer-events:none;
        }
        .search-bar .search-meta {
            position:absolute; right:16px; top:50%; transform:translateY(-50%);
            font-size:12px; color: var(--muted-docs, var(--muted)); display:flex; gap:10px; align-items:center;
        }
        .search-bar .search-clear {
            background:none; border:none; color:var(--muted-docs, var(--muted)); cursor:pointer;
            font-size:18px; padding:2px 6px; border-radius:4px; display:none;
        }
        .search-bar .search-clear:hover { color:var(--accent-docs, var(--accent)); background:rgba(46,168,255,.1); }
        .doc-section-hidden { display:none !important; }

        /* Section dividers */
        .section-num { display:inline-block; background:var(--accent-docs); color:#fff; font-size:12px; font-weight:700;
            width:24px; height:24px; line-height:24px; text-align:center; border-radius:6px; margin-right:8px; }
    </style>
</head>
<body>
    <div class="wrap">
        <a href="../index.aspx" class="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
            Back to iDash Home
        </a>

        <div class="card" style="background: linear-gradient(135deg, var(--card), rgba(46, 168, 255, 0.05));">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:12px;">
                <h1 style="margin-bottom:8px;">&#128214; iDash Technical & User Documentation</h1>
                <div style="display:flex; gap:8px; align-items:center; flex-shrink:0;">
                    <span style="background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs); padding:6px 14px; border-radius:20px; font-size:13px; font-weight:700;">v2.9.0</span>
                    <span style="background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs); padding:6px 14px; border-radius:20px; font-size:13px; font-weight:700;">Build 2026-09-08</span>
                </div>
            </div>
            <p style="color:var(--muted-docs); font-size:17px; line-height:1.6; max-width:800px;">
                Centralized documentation hub for iDash &mdash; RFID Asset Intelligence by ID Integration Inc. Guides are filtered by your role and tile access.
            </p>
            <!-- Compliance badges - compact inline -->
            <div style="display:flex; flex-wrap:wrap; gap:8px; margin-top:8px;">
                <a href="section508_compliance.html" style="display:inline-flex; align-items:center; gap:8px; padding:6px 16px; border:1px solid #10b981; border-radius:20px; text-decoration:none; font-size:12px; color:#10b981; font-weight:700;">
                    &#x2705; Section 508 / WCAG 2.0 AA Compliant
                </a>
                <a href="va_commercial_licensing_sbom.html" style="display:inline-flex; align-items:center; gap:8px; padding:6px 16px; border:1px solid #10b981; border-radius:20px; text-decoration:none; font-size:12px; color:#10b981; font-weight:700; background:rgba(16,185,129,0.08);">
                    &#x2705; Version 1.0 Commercial-Use Approved (SBOM &amp; MIT)
                </a>
                <a href="va_security_readiness_review.html" style="display:inline-flex; align-items:center; gap:8px; padding:6px 16px; border:1px solid #10b981; border-radius:20px; text-decoration:none; font-size:12px; color:#10b981; font-weight:700; background:rgba(16,185,129,0.12);">
                    &#x2705; Version 1.0 Security Readiness Certified (All 5 Findings Remediated)
                </a>
            </div>
        </div>

        <!-- ══════════════════ EXECUTIVE BRIEFING CALLOUT ══════════════════ -->
        <div class="card" style="border: 1px solid color-mix(in srgb, var(--accent-docs) 60%, transparent); background: linear-gradient(135deg, color-mix(in srgb, var(--accent-docs) 12%, transparent), var(--card-docs)); margin-bottom: 24px;">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:16px;">
                <div style="flex:1; min-width:300px;">
                    <div style="display:inline-flex; align-items:center; gap:6px; background:color-mix(in srgb, var(--accent-docs) 20%, transparent); color:var(--accent-docs); border:1px solid var(--accent-docs); padding:3px 10px; border-radius:12px; font-size:11px; font-weight:800; text-transform:uppercase; letter-spacing:0.5px; margin-bottom:8px;">
                        &#9733; Executive Summary &amp; Overview
                    </div>
                    <h2 style="margin:0 0 8px 0; font-size:1.4rem; color:var(--text-docs); border:none; padding:0;">
                        iDash Enterprise Asset Intelligence &amp; Field Operations Hub
                    </h2>
                    <p style="margin:0 0 12px 0; color:var(--muted-docs); font-size:14px; line-height:1.6;">
                        A zero-footprint web intelligence platform delivering defensible property accountability, real-time wave RFID scanning, and tactical Geiger-counter asset locating. Purpose-built for operational commanders, security officers (ISO), and enterprise IT (OIT).
                    </p>
                    <div style="display:flex; flex-wrap:wrap; gap:8px;">
                        <span class="chip" style="background:rgba(16,185,129,0.12); border:1px solid #10b981; color:#10b981;">&#x2713; Zero Desktop Push</span>
                        <span class="chip" style="background:rgba(59,130,246,0.12); border:1px solid #3b82f6; color:#3b82f6;">&#x2713; 1,000+ Tags/Min</span>
                        <span class="chip" style="background:rgba(139,92,246,0.12); border:1px solid #8b5cf6; color:#8b5cf6;">&#x2713; Granular RBAC</span>
                        <span class="chip" style="background:rgba(245,158,11,0.12); border:1px solid #f59e0b; color:#f59e0b;">&#x2713; Offline Batch Mode</span>
                    </div>
                </div>
                <div style="display:flex; flex-direction:column; gap:8px; align-items:flex-end; justify-content:center; flex-shrink:0;">
                    <a href="va_executive_summary.html" style="background:var(--accent-docs); color:#fff; padding:10px 22px; border-radius:8px; font-size:13px; font-weight:700; text-decoration:none; display:inline-flex; align-items:center; gap:8px; box-shadow:0 4px 12px rgba(46,168,255,0.25);">
                        &#128214; Read Full Executive Summary &#8594;
                    </a>
                    <span style="font-size:11px; color:var(--muted-docs); font-weight:600;">Leadership, ISO &amp; OIT Overview</span>
                </div>
            </div>
        </div>

        <!-- SEARCH BAR -->
        <div class="search-bar">
            <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            <input type="text" id="docSearch" placeholder="Search documentation... (Ctrl+K)" autocomplete="off" />
            <div class="search-meta">
                <span id="searchCount"></span>
                <button type="button" class="search-clear" id="searchClear" onclick="clearSearch()">&times;</button>
            </div>
        </div>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             1. SCANNING & FIELD TOOLS
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <!-- ═══════════════════════════════════════════════════════════
             USER GUIDES (WALKTHROUGHS)
             ═══════════════════════════════════════════════════════════ -->
        <% if (CanSeeAny(new[]{"guides", "docs_print", "admin_print"})) { %>
        <div class="card" style="border: 1px solid rgba(16,185,129,0.2); background: linear-gradient(135deg, var(--card), rgba(16,185,129,0.03));">
            <h2><span class="section-num" style="background:#10b981;">&#128214;</span> &#128214; User Guides &amp; Walkthroughs</h2>
            <p style="color:var(--muted-docs); font-size:14px; margin-bottom:16px;">Step-by-step procedures with screenshots for common iDash tasks. Designed for end users being trained on the system.</p>
            <div class="grid">
                <a class="tile" href="va_guide_accessing_idash.html" style="border-color: #3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">&#128274; Accessing iDash</div>
                    <p style="color:var(--muted-docs); margin:0;">How to sign in to the VA Asset Intelligence Hub, navigate the tile sections, and understand what each area provides. Includes login credentials reference and sign-out guidance.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Getting Started</span></p>
                </a>
                <a class="tile" href="va_guide_mobile_shortcuts.html" style="border-color: #10b981; background: color-mix(in srgb, #10b981, transparent 96%);">
                    <div class="tile-title" style="color:#10b981;">&#128241; Mobile Reader Shortcuts, Web Scanning, and Datawedge Setup</div>
                    <p style="color:var(--muted-docs); margin:0;">Configure 1-tap home screen shortcuts for VA Site Inventory, ENNX Live Scan, EIL Reconciliation, and Universal ENNX on Zebra TC53/TC58 handhelds, with full DataWedge profile import and Enterprise Browser setup.<br><span class="chip" style="margin-top:6px; background:rgba(16,185,129,0.15); border:1px solid #10b981; color:#10b981;">User Guide</span> <span class="chip" style="margin-top:6px; background:rgba(59,130,246,0.15); border:1px solid #3b82f6; color:#3b82f6;">Zebra TC53</span> <span class="chip" style="margin-top:6px; background:rgba(139,92,246,0.15); border:1px solid #8b5cf6; color:#8b5cf6;">Fast Scanning</span> <span class="chip" style="margin-top:6px; background:rgba(245,158,11,0.15); border:1px solid #f59e0b; color:#f59e0b;">DataWedge</span></p>
                </a>
                <% if (CanSeeAny(new[]{"guides", "excel_print", "docs_print", "admin_print"})) { %>
                <a class="tile" href="va_printing_walkthrough.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128424; Printing Guide: Excel Import</div>
                    <p style="color:var(--muted-docs); margin:0;">Sign in to iDash, load equipment data from Excel, select rows, choose a label template, and print RFID labels via MQTT/BarTender.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Screenshots</span></p>
                </a>
                <% } %>
                <% if (CanSeeAny(new[]{"guides", "rpt_asset_master", "docs_print", "admin_print"})) { %>
                <a class="tile" href="va_printing_walkthrough_asset_master.html" style="border-color: #3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">&#128424; Printing Guide: Asset Master</div>
                    <p style="color:var(--muted-docs); margin:0;">Search and filter existing assets, select rows or enter number ranges, and print RFID labels. Covers both Server Print and Print Dialog methods.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Screenshots</span></p>
                </a>
                <% } %>
                <% if (CanSee("guides")) { %>
                <a class="tile" href="va_guide_adhoc_file_generation.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128225; VA ADHOC File Generation</div>
                    <p style="color:var(--muted-docs); margin:0;">Perform ad‑hoc asset file generation for exporting new assets or latest inventory. Select a location, generate files, and sync to iDash.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span></p>
                </a>
                <a class="tile" href="va_batch_scan.html" style="border-color: #3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">&#128225; Batch Mode Scanning (Offline)</div>
                    <p style="color:var(--muted-docs); margin:0;">Scan without WiFi: enable Batch Mode, scan multiple rooms offline, then sync all stored sessions when you return to a connected area.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span></p>
                </a>
                <a class="tile" href="va_guide_locate.html" style="border-color: #8B5CF6;">
                    <div class="tile-title" style="color:#8B5CF6;">&#128205; How to Use the Locate Feature</div>
                    <p style="color:var(--muted-docs); margin:0;">Use the RFID Geiger-counter &ldquo;Locate&rdquo; mode to find specific assets by tag signal strength. Works from the ASSETS tab or during a room inventory scan.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span></p>
                </a>
                <a class="tile" href="va_guide_power_settings.html" style="border-color: #06b6d4;">
                    <div class="tile-title" style="color:#06b6d4;">&#128268; Adjusting Antenna Power</div>
                    <p style="color:var(--muted-docs); margin:0;">Control RFID read range per scanning mode (Inventory, Checkout, Associate). Lower power reduces bleed into adjacent rooms; higher power extends range for large open spaces.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06b6d4 15%, transparent); border:1px solid #06b6d4; color:#06b6d4;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span></p>
                </a>
                <a class="tile" href="va_guide_offline_printing.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128424; Offline Printing Station</div>
                    <p style="color:var(--muted-docs); margin:0;">Use the standalone BarTender printing station: Daily Scans Tagging, Emailed Labels, and Supply Chain categories. Template selection, data verification, and label printing.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">BarTender</span></p>
                </a>
                <a class="tile" href="va_guide_scanner_setup.html" style="border-color: #06b6d4;">
                    <div class="tile-title" style="color:#06b6d4;">&#128241; Zebra TC53 Scanner Setup</div>
                    <p style="color:var(--muted-docs); margin:0;">Connect to MiFi WiFi, pair the RF40 RFID sled via Bluetooth, install the RFID mobile scanner, configure the server address, and log in for the first time.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06b6d4 15%, transparent); border:1px solid #06b6d4; color:#06b6d4;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Setup</span></p>
                </a>
                <a class="tile" href="va_guide_scanner_daily_scan.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128225; Daily Scanner Workflow</div>
                    <p style="color:var(--muted-docs); margin:0;">Full end-to-end room inventory procedure: enter PIN, sync app at the Scanning PC, log in, scan room barcode, sweep for RFID assets, review color-coded results (orange/green/blue), take action on unexpected items, and sync data back when done.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Screenshots</span></p>
                </a>
                <a class="tile" href="va_guide_scanner_reference_card.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128196; Scanner &amp; ENNX Quick Reference Card</div>
                    <p style="color:var(--muted-docs); margin:0;">Pocket-sized double-sided reference card for scanning techs and trainees. Side A: TC53+sled unlock, PIN, sync, room scanning, triggers, color codes. Side B: Edge browser, iDash login, ENNX export, and email. Sized for 3&times;5&quot; and 4&times;6&quot; index card printing and laminating.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Printable Card</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Pocket Guide</span></p>
                </a>
                <a class="tile" href="va_guide_post_scan_ennx.html" style="border-color: #ec4899;">
                    <div class="tile-title" style="color:#ec4899;">&#128203; Post-Scan: ENNX Export &amp; Email</div>
                    <p style="color:var(--muted-docs); margin:0;">After returning from the field, generate and email the Equipment Not in Expected Location (ENNX) report: open iDash, set date/site/user filters, check Tagged Items Only, build, and email in one click.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ec4899 15%, transparent); border:1px solid #ec4899; color:#ec4899;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Scanner</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Screenshots</span></p>
                </a>
                <a class="tile" href="va_guide_ennx_reporting.html" style="border-color: #ec4899;">
                    <div class="tile-title" style="color:#ec4899;">&#128202; ENNX Report Generator</div>
                    <p style="color:var(--muted-docs); margin:0;">Access the Dashboard ENNX tool, generate Equipment Not in Expected Location reports, filter by user/date/location, export via copy-paste or file, and configure automated email delivery.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ec4899 15%, transparent); border:1px solid #ec4899; color:#ec4899;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Reports</span></p>
                </a>
                <a class="tile" href="va_guide_rfid_printer_settings.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#128424; RFID Printer Setup &amp; Troubleshooting</div>
                    <p style="color:var(--muted-docs); margin:0;">Configure Zebra ZT411R and ZD621R RFID printers: darkness, speed, head close settings, ribbon and media installation, network connections, and fixing VOID/offset errors.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Admin Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Printer</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Screenshots</span></p>
                </a>
                <a class="tile" href="va_guide_rfid_support.html" style="border-color: #8B5CF6;">
                    <div class="tile-title" style="color:#8B5CF6;">&#128222; Enterprise RFID Technical Support</div>
                    <p style="color:var(--muted-docs); margin:0;">Quick reference for getting help: 4-step support process, escalation path (L1&rarr;L2&rarr;L3), full contact directory for Team VIT, and RFID Roundtable schedule (3rd Friday, 2:00 PM EST).<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Admin Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Support</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ec4899 15%, transparent); border:1px solid #ec4899; color:#ec4899;">Contacts</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <% if (CanSeeAny(new[]{"scan_maps", "scan_tagteam", "scan_inventory", "scan_locator"})) { %>
        <div class="card">
            <h2><span class="section-num">1</span>&#128225; Scanning & Field Tools</h2>
            <div class="grid">
                <% if (CanSee("scan_maps")) { %>
                <a class="tile" href="va_site_maps.html">
                    <div class="tile-title">Site Location Maps</div>
                    <p style="color:var(--muted-docs); margin:0;">Visual dashboard to track progress through facility maps and ensure comprehensive tagging sweeps.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>
                <% } %>

                <% if (CanSee("scan_tagteam")) { %>
                <a class="tile" href="va_tagteam_scan.html">
                    <div class="tile-title">Tag Team Scan</div>
                    <p style="color:var(--muted-docs); margin:0;">Rapid physical inventory scanning, location tracking, and bulk RFID printing. <span style="color:var(--accent2-docs); font-weight:bold;">(Critical Guide)</span><br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>
                <% } %>

                <% if (CanSee("scan_inventory")) { %>
                <a class="tile" href="va_inventory.html">
                    <div class="tile-title">VA Site Inventory</div>
                    <p style="color:var(--muted-docs); margin:0;">High-performance real-time location sweep (30&ndash;50 tags/sec), $O(1)$ memory lookup, centralized Site Config column visibility, and automated asset relocation.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Active v2.0</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>

                <a class="tile" href="va_inventory_legacy.html" style="border-color: rgba(239, 68, 68, 0.4); opacity: 0.85;">
                    <div class="tile-title" style="color:#ef4444;">VA Site Inventory (Legacy / Archived)</div>
                    <p style="color:var(--muted-docs); margin:0;">Archived documentation for the legacy postback-driven <code>va_inventory_legacy.aspx</code> sweeping interface.<br><span class="chip" style="margin-top:6px; background:rgba(239,68,68,0.12); border:1px solid rgba(239,68,68,0.4); color:#ef4444;">Retired / Archived</span></p>
                </a>

                <a class="tile" href="va_rfid_locator.html" style="border-color: #8B5CF6;">
                    <div class="tile-title" style="color:#8B5CF6;">&#128225; RFID Asset Locator</div>
                    <p style="color:var(--muted-docs); margin:0;">Locate missing assets using Mobile RFID proximity scanning. High-speed Geiger counter meter, audio feedback, and mobile-optimized target tracking.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Active v2.0</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Mobile RFID Optimized</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             2. ENNX GENERATION
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"scan_universal_ennx", "scan_ennx", "scan_eil", "rpt_ennx"})) { %>
        <div class="card">
            <h2><span class="section-num">2</span>&#128228; ENNX Generation</h2>
            <div class="grid">
                <% if (CanSee("scan_universal_ennx")) { %>
                <a class="tile" href="va_universal_ennx.html" style="border-color:#10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128228; Universal ENNX Creator</div>
                    <p style="color:var(--muted-docs); margin:0;">High-speed in-memory ENNX creator (30&ndash;50 tags/sec), single-row filter bar, 4-color stream rows, and direct email export.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Active v2.0</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">No DB Required</span></p>
                </a>

                <a class="tile" href="va_universal_ennx_legacy.html" style="border-color: rgba(239, 68, 68, 0.4); opacity: 0.85;">
                    <div class="tile-title" style="color:#ef4444;">&#128228; Universal ENNX Creator (Legacy / Archived)</div>
                    <p style="color:var(--muted-docs); margin:0;">Archived documentation for the legacy tile-based and WebSerial <code>va_universal_ennx_legacy.aspx</code> generator.<br><span class="chip" style="margin-top:6px; background:rgba(239,68,68,0.12); border:1px solid rgba(239,68,68,0.4); color:#ef4444;">Retired / Archived</span></p>
                </a>
                <% } %>

                <% if (CanSee("scan_ennx")) { %>
                <a class="tile" href="va_ennx_live_scan.html">
                    <div class="tile-title">ENNX Live Scan</div>
                    <p style="color:var(--muted-docs); margin:0;">Live asset scanning for generating ENNX data. EIL/CMR dropdown filtered by selected site. DataWedge and WebSerial USB support.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>
                <% } %>

                <% if (CanSee("scan_eil")) { %>
                <a class="tile" href="va_eil_live_scan.html" style="border-color:#10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128203; EIL Live Scan &amp; Reconciliation</div>
                    <p style="color:var(--muted-docs); margin:0;">Targeted EIL / CMR checklist sweeps, zero-scroll mobile viewport (<code>100dvh</code>), Web Audio synthesizer feedback, room locks, and direct database commit.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Active v2.5</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Mobile RFID Optimized</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>
                <% } %>

                <% if (CanSee("rpt_ennx")) { %>
                <a class="tile" href="va_ennx.html">
                    <div class="tile-title">ENNX Export Dashboard</div>
                    <p style="color:var(--muted-docs); margin:0;">Generate dedicated ENNX logs. Multi-day ranges, site-specific filtering, OIT/No-Data preview and Excel export.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             3. PRINTING
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"docs_print", "print_mapping", "admin_print", "admin_mqtt"})) { %>
        <div class="card">
            <h2><span class="section-num">3</span>&#128424; Printing</h2>
            <div class="grid">
                <% if (CanSeeAny(new[]{"docs_print", "print_mapping", "admin_print"})) { %>
                <a class="tile" href="va_print_admin.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128424; Print Administration (Master Guide)</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete printing reference: architecture, templates, printers, MQTT setup, multi-site config, printer routing, server deployment, new machine setup checklist, config sync, and troubleshooting. <strong>Start here.</strong><br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">14 Sections</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">MQTT</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Updated 08/12</span></p>
                </a>
                <% if (CanSee("print_mapping")) { %>
                <a class="tile" href="va_print_mapping.html">
                    <div class="tile-title">Template Mapping Config</div>
                    <p style="color:var(--muted-docs); margin:0;">Tag type &rarr; template ID mapping for mobile scanning. Bind device scanning categories to specific print templates and routing destinations.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Sub-config</span></p>
                </a>
                <% } %>

                <a class="tile" href="va_printing_guide.html" style="border-color: #8B5CF6;">
                    <div class="tile-title" style="color:#8B5CF6;">&#128424; Printing Labels (User Guide)</div>
                    <p style="color:var(--muted-docs); margin:0;">Step-by-step for end users: how to print RFID labels from Asset Master. Single, range, and comma-separated input formats.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">End User</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"docs_print", "admin_print", "admin_mqtt"})) { %>
                <a class="tile" href="va_bartender_print_architecture.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#128424; BarTender Print Architecture &amp; Troubleshooting</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete print pipeline architecture, the N&times;N duplicate label bug and fix, SubStrings vs Database Fields, BarTender template setup, field mapping reference, deployment checklist, and lessons learned.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Critical Fix</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06B6D4 15%, transparent); border:1px solid #06B6D4; color:#06B6D4;">BarTender SDK</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">08/25/2026</span></p>
                </a>
                <% } %>
                <% if (CanSeeAny(new[]{"docs_print", "admin_print", "admin_mqtt", "excel_print"})) { %>
                <a class="tile" href="va_bartender_api_integration.html" style="border-color: #0284c7;">
                    <div class="tile-title" style="color:#0284c7;">&#127991;&#65039; BarTender REST API &amp; Print Engine Integration</div>
                    <p style="color:var(--muted-docs); margin:0;">100% stateless BarTender integration without local SQL database dependencies. In-browser visual label previews, real-time Zebra cart printer monitoring, Tag Team live scan integration, and microservice architecture.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #0284c7 15%, transparent); border:1px solid #0284c7; color:#0284c7;">Stateless API</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Visual Previews</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Zebra RFID</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">New</span></p>
                </a>
                <% } %>
                <% if (CanSeeAny(new[]{"excel_print", "admin_print", "admin_users"})) { %>
                <a class="tile" href="va_excel_print.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128218; Excel Equipment Import &amp; Print</div>
                    <p style="color:var(--muted-docs); margin:0;">Bulk-load equipment from <code>equipment.xlsx</code> into iDash. Site override, name prefix (e.g. EE), live Preview Names tab, upsert on name+company, optional MQTT label print.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Import &amp; Print</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">MQTT</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/26</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_diagnostics", "admin_users"})) { %>
                <a class="tile" href="va_system_diagnostics.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128202; System Diagnostics &amp; Health Monitor</div>
                    <p style="color:var(--muted-docs); margin:0;">One-click health check for the iDash platform: API auth, license validation, server registrations, and batch update simulation (mimics mobile app). Email HTML report. Solves post-restore batch-mode license failures.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Diagnostic</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">API</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/26</span></p>
                </a>
                <% } %>
                <% if (CanSeeAny(new[]{"admin_diagnostics", "admin_users", "admin_site_config"})) { %>
                <a class="tile" href="va_cart_licenses.html" style="border-color: #38bdf8;">
                    <div class="tile-title" style="color:#38bdf8;">&#128722; Mobile Cart License Directory</div>
                    <p style="color:var(--muted-docs); margin:0;">Central tracking directory for standalone mobile inventory carts across enterprise facilities (Beckley, Clarksburg, Huntington, Martinsburg, DC). Verified MAC addresses, signed keys, 1-click PowerShell apply scripts, and localhost HTTP 500 troubleshooting.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #38bdf8 15%, transparent); border:1px solid #38bdf8; color:#38bdf8;">Cart Licenses</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">PowerShell</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 09/26</span></p>
                </a>
                <a class="tile" href="va_license_fix.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#128272; License Fix: Network Adapter Change</div>
                    <p style="color:var(--muted-docs); margin:0;">Step-by-step to resolve <code>LICENSE KEY ERROR</code> after a NIC swap. Includes diagnostic SQL, key decode, and downloadable fix script.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Common Issue</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">SQL Script</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/12</span></p>
                </a>
                <a class="tile" href="va_license_manager.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#128273; License Manager</div>
                    <p style="color:var(--muted-docs); margin:0;">View reader license usage (readers + handhelds vs. limit), delete stale scanners to free slots, manage server registrations, MQTT clients, and scanner user accounts. Consolidated administration portal.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Admin Tool</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Database</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 09/26</span></p>
                </a>
                <a class="tile" href="va_idashdiag_recovery.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128657; Asset Data Recovery Tool</div>
                    <p style="color:var(--muted-docs); margin:0;">Restore asset data wiped by the old Diagnostics batch test. Cross-system recovery: restore <code>.bak</code> on any machine, generate portable UPDATE statements, paste on damaged system.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Data Recovery</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">SQL Script</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/12</span></p>
                </a>
                <a class="tile" href="va_tailscale_funnel.html" style="border-color: #3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">&#128279; Tailscale Funnel: Remote Access Setup</div>
                    <p style="color:var(--muted-docs); margin:0;">Step-by-step guide to expose iDash to VA users via Tailscale Funnel. Covers admin console config, CLI commands, persistence across reboots, security, and troubleshooting.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Networking</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">VISN5-8</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/12</span></p>
                </a>
                <a class="tile" href="va_scanner_management.html" style="border-color: #06B6D4;">
                    <div class="tile-title" style="color:#06B6D4;">&#128225; Scanner &amp; Device Registration</div>
                    <p style="color:var(--muted-docs); margin:0;">View, manage, and reset RFID scanner registrations in the <code>dbo.scanner</code> table. Compliance tracking, device audit, safe cleanup procedures, and impact analysis.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06B6D4 15%, transparent); border:1px solid #06B6D4; color:#06B6D4;">Database</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">SQL Script</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/26</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             4. MQTT & FIXED READERS
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"admin_reader_config", "admin_mqtt", "scan_ennx", "scan_eil", "docs_arch"})) { %>
        <div class="card">
            <h2><span class="section-num">4</span>&#128225; MQTT & Fixed Readers</h2>
            <div class="grid">
                <% if (CanSeeAny(new[]{"admin_reader_config", "admin_mqtt", "docs_arch"})) { %>
                <a class="tile" href="va_mqtt_architecture.html" style="border-color: #8B5CF6;">
                    <div class="tile-title" style="color:#8B5CF6;">&#128225; MQTT Fixed Reader Architecture</div>
                    <p style="color:var(--muted-docs); margin:0;">Zebra FX9600 fixed RFID reader deployment. RabbitMQ (TRM-approved), MQTTnet embedded broker, database schemas, location tracking pipeline, deduplication strategies.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Architecture</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">TRM Compliant</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_reader_config", "admin_mqtt", "docs_arch"})) { %>
                <a class="tile" href="va_rabbitmq_setup.html" style="border-color: #3fb950;">
                    <div class="tile-title" style="color:#3fb950;">&#128007; RabbitMQ MQTT Broker Setup</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete installation &amp; configuration guide for RabbitMQ 4.3.5 as the MQTT broker for fixed reader tag routing. Erlang setup, user creation, FX9600 endpoint config, iDash code changes, verification, troubleshooting.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3fb950 15%, transparent); border:1px solid #3fb950; color:#3fb950;">Infrastructure</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">TRM Compliant</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_mqtt", "admin_reader_config"})) { %>
                <a class="tile" href="va_mqtt_config.html" style="border-color: #06B6D4;">
                    <div class="tile-title" style="color:#06B6D4;">&#128225; MQTT Configuration & Print Server</div>
                    <p style="color:var(--muted-docs); margin:0;">MQTT broker settings, multi-site print client management, Print Server installation, MasterPrint architecture, <code>applicationsetting</code> fields, BarTender integration.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06B6D4 15%, transparent); border:1px solid #06B6D4; color:#06B6D4;">MQTT / Print</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_mqtt", "admin_print", "docs_print", "excel_print"})) { %>
                <a class="tile" href="va_print_queue_batch_fix.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128424; Print Queue &amp; Batch Print Fix</div>
                    <p style="color:var(--muted-docs); margin:0;">Root cause analysis of duplicate labels and stuck print jobs. BarTender "All Records" SQL query, poll-for-completion fix, <code>printjob</code> table schema, queue maintenance SQL, deployment checklist, and troubleshooting.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Bug Fix</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">BarTender</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/26</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"scan_ennx", "scan_eil", "admin_reader_config"})) { %>
                <a class="tile" href="va_reader_config.html" style="border-color: #8B5CF6;">
                    <div class="tile-title" style="color:#8B5CF6;">&#128225; Fixed Reader Configuration</div>
                    <p style="color:var(--muted-docs); margin:0;">Manage fixed RFID reader registrations, antenna port/power mappings, live online/offline status. Add, edit, delete readers; discover unregistered hardware.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">API Driven</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_reader_config", "admin_mqtt", "rpt_fixed_reader"})) { %>
                <a class="tile" href="va_fixed_reader_setup.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128225; Fixed Reader Setup &amp; Configuration Guide</div>
                    <p style="color:var(--muted-docs); margin:0;">End-to-end deployment guide: Zebra FX9600 hardware setup, MQTT broker config, antenna registration, database alignment (company/vtagid), troubleshooting, and Asset Master Fixed Reader Report.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Setup Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Lessons Learned</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_reader_config", "admin_mqtt", "docs_arch"})) { %>
                <a class="tile" href="va_guide_fixed_reader_deployment.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#128225; Fixed Reader Deployment Guide</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete deployment guide for Zebra FX9600 fixed RFID readers: IoT Connector configuration, Inventory mode setup, HTTP-POST &amp; MQTT data paths, antenna-to-location mapping, scaling to 40+ readers with 300+ antennas, and MQTT broker routing bug report with evidence.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Admin Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Fixed Reader</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Bug Report</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_fixed_reader", "admin_reader_config"})) { %>
                <a class="tile" href="va_fixed_reader.html" style="border-color: #06B6D4;">
                    <div class="tile-title" style="color:#06B6D4;">&#128225; Fixed Reader Dashboard</div>
                    <p style="color:var(--muted-docs); margin:0;">Real-time reader health monitoring. KPI summary, online/offline status, tag observation windows, device type breakdown, top observed locations, reader inventory table.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06B6D4 15%, transparent); border:1px solid #06B6D4; color:#06B6D4;">Live Data</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">API Driven</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_fixed_reader", "admin_reader_config"})) { %>
                <a class="tile" href="../va_fixed_reader_live.aspx" style="border-color: #10b981;" target="_blank">
                    <div class="tile-title" style="color:#10b981;">&#128225; Fixed Reader Live Feed <span style="font-size:10px;font-weight:800;background:color-mix(in srgb,#10b981 15%,transparent);border:1px solid #10b981;border-radius:6px;padding:1px 6px;margin-left:6px;vertical-align:middle;">LIVE</span></div>
                    <p style="color:var(--muted-docs); margin:0;">Real-time antenna-level tag read stream. Watch assets passing in front of specific fixed reader antennas as it happens &mdash; reads/min counter, unique asset tracker, sound alerts, and pause/resume. Filter by reader and antenna port.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Live Stream</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Troubleshooting</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">New</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_fixed_reader", "admin_reader_config", "docs_arch"})) { %>
                <a class="tile" href="va_fixed_reader_features.html" style="border-color: #10B981;">
                    <div class="tile-title" style="color:#10B981;">&#128225; Fixed Reader Intelligence &amp; Analytics</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete guide to the fixed reader intelligence platform: real-time live feed, asset watch list with export to CSV, one-click open in Asset Master, missing asset report with coverage analytics, cross-site visitor detection, and reader coverage metrics.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Admin Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Fixed Reader</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">New</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_reader_config", "admin_mqtt", "docs_arch"})) { %>
                <a class="tile" href="va_crosssite_tag_observer.html" style="border-color: #EF4444;">
                    <div class="tile-title" style="color:#EF4444;">&#128225; Cross-Site Tag Observer</div>
                    <p style="color:var(--muted-docs); margin:0;">Architecture and deployment guide for detecting RFID tags from other VA sites at your fixed reader location. MQTT listener design, cross-company SQL matching, Windows Service setup, and replication checklist.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #EF4444 15%, transparent); border:1px solid #EF4444; color:#EF4444;">Architecture</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">MQTT Service</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New 08/26</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             5. REPORTING & ANALYTICS
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"rpt_overview", "rpt_tagging", "rpt_cmr", "search_history", "search", "rpt_asset_master", "rpt_location_list"})) { %>
        <div class="card">
            <h2><span class="section-num">5</span>&#128202; Reporting & Analytics</h2>
            <div class="grid">
                <% if (CanSeeAny(new[]{"rpt_notifications", "rpt_asset_master", "admin_reader_config"})) { %>
                <a class="tile" href="va_idash_notifications.html" style="border-color: #3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">🔔 iDash Notifications &amp; Asset Watch List</div>
                    <p style="color:var(--muted-docs); margin:0;">Active RFID notifications, asset watch lists, detection level classifications (High, Moderate, Low, Cold), location mismatch alerts, and site-level alert architecture.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Watch List</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">New</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_overview", "rpt_asset_master"})) { %>
                <a class="tile" href="va_asset_master.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128203; Asset Master &mdash; Unified Reporting</div>
                    <p style="color:var(--muted-docs); margin:0;">One-stop asset reporting: server-side pagination (600K+ rows), filters, toggleable columns, KPI cards, CSV/Excel export, print jobs, Asset Detail Panel, and inline editing.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Server-Side</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Print Jobs</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Inline Edit</span></p>
                </a>

                <a class="tile" href="va_asset_stats.html">
                    <div class="tile-title">Asset Statistics (Consolidated)</div>
                    <p style="color:var(--muted-docs); margin:0;">Unified Asset Stats: Overview KPIs, Data Quality, Not In Use records, and Data Analytics.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">API Driven</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_data_quality", "rpt_overview", "rpt_asset_master"})) { %>
                <a class="tile" href="va_data_quality.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#9989; Data Quality Command Center</div>
                    <p style="color:var(--muted-docs); margin:0;">Audit database health: weighted scoring algorithm (0&ndash;100), missing EIL/CMR detection, blank locations, malformed EE numbers, live AJAX drill-downs, and Excel export.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Audit</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Scoring</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_location_list", "rpt_asset_master", "rpt_overview"})) { %>
                <a class="tile" href="va_location_list.html" style="border-color:#3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">&#128205; Location List &mdash; Inventory by Location</div>
                    <p style="color:var(--muted-docs); margin:0;">Sortable, paginated summary of every location: total assets, unique CMRs, age-bucket breakdowns (0&ndash;3 mo through 13+ mo), % coverage, and last inventoried date. Drill into any location to see its assets.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb,#3b82f6 15%,transparent); border:1px solid #3b82f6; color:#3b82f6;">Sortable</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb,#10b981 15%,transparent); border:1px solid #10b981; color:#10b981;">Unique CMR</span></p>
                </a>
                <% } %>

                <% if (CanSee("rpt_tagging")) { %>
                <a class="tile" href="va_tag_stats.html">
                    <div class="tile-title">Tagging Statistics (Consolidated)</div>
                    <p style="color:var(--muted-docs); margin:0;">4-module executive tagging logic: Overview, Employee KPIs, Tag Types, Sites.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">API Driven</span></p>
                </a>
                <% } %>

                <% if (CanSee("search_history")) { %>
                <a class="tile" href="va_previous_location.html">
                    <div class="tile-title">Location & Scan History</div>
                    <p style="color:var(--muted-docs); margin:0;">Search all EIL tracking and location traces.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">API Driven</span></p>
                </a>
                <% } %>

                <% if (CanSee("search")) { %>
                <a class="tile" href="va_asset_api.html">
                    <div class="tile-title">VA Asset Explorer</div>
                    <p style="color:var(--muted-docs); margin:0;">Lookup active asset records matching barcode formats.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">API Driven</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"rpt_overview", "rpt_asset_master", "rpt_location_list", "rpt_data_quality"})) { %>
                <a class="tile" href="va_idash_filtering_sorting.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128269; Column Sorting &amp; Filtering Guide</div>
                    <p style="color:var(--muted-docs); margin:0;">How to use column header sorting (click to toggle asc/desc) and inline text filters on data grids across iDash &mdash; Asset Master, Location List, Data Quality previews, and more.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">User Guide</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">All Pages</span></p>
                </a>
                <% } %>

                <% if (CanSee("rpt_overview")) { %>
                <a class="tile" href="general_pages.html">
                    <div class="tile-title">Module Overview Reference</div>
                    <p style="color:var(--muted-docs); margin:0;">Quick-reference overview of all reporting, admin, and logging tools.</p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             6. DATABASE & DATA MANAGEMENT
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"admin_manualdb", "admin_autodb", "admin_bcp"})) { %>
        <div class="card">
            <h2><span class="section-num">6</span>&#128451; Database & Data Management</h2>
            <div class="grid">
                <% if (CanSeeAny(new[]{"admin_manualdb", "admin_autodb"})) { %>
                <a class="tile" href="va_dbupdate.html">
                    <div class="tile-title">Database Update Workflows</div>
                    <p style="color:var(--muted-docs); margin:0;">Standard DB Update vs. DB Enrichment scripts, SQL uploading, Auto DB updates, and log viewing.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>

                <a class="tile" href="va_database_setup.html" style="border-left:3px solid #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128736; iDash Database Setup</div>
                    <p style="color:var(--muted-docs); margin:0;">Create the iDash database from scratch with SQL scripts. Tables, views, indexes, VA field mappings, and staging DB.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">SQL Scripts</span></p>
                </a>

                <a class="tile" href="va_dbupdate_workbench.html" style="border-left:3px solid #a855f7;">
                    <div class="tile-title" style="color:#a855f7;">&#128295; Import Workbench</div>
                    <p style="color:var(--muted-docs); margin:0;">Custom separators (tab, pipe, comma), remap column headers, preview parsed data, test run before committing.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #a855f7 15%, transparent); border:1px solid #a855f7; color:#a855f7;">Separator Config</span></p>
                </a>

                <a class="tile" href="va_remote_import.html" style="border-left:3px solid #06b6d4;">
                    <div class="tile-title" style="color:#06b6d4;">&#128225; Remote DB Update</div>
                    <p style="color:var(--muted-docs); margin:0;">Run database imports from any workstation via PowerShell. Network-safe (SqlBulkCopy).<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #06b6d4 15%, transparent); border:1px solid #06b6d4; color:#06b6d4;">Network-Safe</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_manualdb", "docs_arch"})) { %>
                <a class="tile" href="va_sitedata_export.html">
                    <div class="tile-title">&#128228; Site Data Export & Import</div>
                    <p style="color:var(--muted-docs); margin:0;">Bidirectional data migration &mdash; export site records to flat files and import using SqlBulkCopy.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Bulk UPSERT</span></p>
                </a>
                <% } %>

                <% if (CanSee("admin_bcp")) { %>
                <a class="tile" href="va_bcp_query.html">
                    <div class="tile-title">VA On Network Queries (Pull)</div>
                    <p style="color:var(--muted-docs); margin:0;">BCP extraction strings and SQLCMD batch inserts &mdash; pulls data from CDW/VistA into iDash.</p>
                </a>
                <a class="tile" href="va_bcp_awpush_query.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128228; iDash Push to VA SQL (Push)</div>
                    <p style="color:var(--muted-docs); margin:0;">BCP OUT and SQLCMD MERGE to export iDash data to a remote VA SQL server.</p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_autodb", "docs_arch"})) { %>
                <a class="tile" href="va_field_sync.html">
                    <div class="tile-title">&#128257; Field Server Sync</div>
                    <p style="color:var(--muted-docs); margin:0;">Nightly VISN field server sync pipeline. .bak restore, cross-database merge, national deployment architecture.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Database Driven</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             7. SECURITY & ACCESS CONTROL
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"admin_users", "docs_arch"})) { %>
        <div class="card">
            <h2><span class="section-num">7</span>&#128274; Security & Access Control</h2>
            <div class="grid">
                <% if (CanSee("admin_users")) { %>
                <a class="tile" href="va_user_management.html" style="border-color:var(--accent2-docs);">
                    <div class="tile-title" style="color:var(--accent2-docs);">&#128100; iDash User Management</div>
                    <p style="color:var(--muted-docs); margin:0;">Three-dimensional access model: portal roles &times; per-tile permissions &times; per-site permissions. Granular admin tile enforcement, field tech and read-only setup.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Admin Only</span></p>
                </a>

                <a class="tile" href="va_aw_user_management.html" style="border-color:#f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128100; Scanner &amp; System User Management (sysuser)</div>
                    <p style="color:var(--muted-docs); margin:0;">Create scanner &amp; API users directly from iDash via SQL. <code>dbo.sysuser</code> table, ASP.NET Core Identity V3 password hasher, CRUD operations.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Direct SQL</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_users", "docs_arch"})) { %>
                <a class="tile" href="va_security_readiness_review.html" style="border-color: #10b981; background: linear-gradient(135deg, color-mix(in srgb, var(--text), transparent 98%), rgba(16, 185, 129, 0.08));">
                    <div class="tile-title" style="color:#10b981;">&#128737; Security Readiness &amp; Certification</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete remediation register for September 2026 security review: NIST SP 800-53 Rev. 5 alignment (AC-3, SC-7 fail-closed API policies, SC-4 tenant isolation, AU-2/12 audit trails, Section 508 compliance).<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">v1.0 Certified</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Fail-Closed</span></p>
                </a>

                <a class="tile" href="va_commercial_licensing_sbom.html" style="border-color: #10b981; background: linear-gradient(135deg, color-mix(in srgb, var(--text), transparent 98%), rgba(16, 185, 129, 0.08));">
                    <div class="tile-title" style="color:#10b981;">&#128220; SBOM &amp; Commercial-Use Approval</div>
                    <p style="color:var(--muted-docs); margin:0;">Full Software Bill of Materials (SBOM) with SHA-256 binary verification, complete EPPlus Polyform noncommercial removal audit, ClosedXML MIT transition, and formal approval determination.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">v1.0 Approved</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #a855f7 15%, transparent); border:1px solid #a855f7; color:#a855f7;">MIT License</span></p>
                </a>

                <a class="tile" href="scan_security_notes.html">
                    <div class="tile-title">&#128274; Universal Scanner Security Notes</div>
                    <p style="color:var(--muted-docs); margin:0;">Architecture and security controls for the universal scan endpoint. SQL injection prevention, least-privilege design, IIS boundary protections.</p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             8. VA INTEGRATION & ENTERPRISE
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"docs_arch", "admin_users"})) { %>
        <div class="card">
            <h2><span class="section-num">8</span>&#127973; VA Integration & Enterprise</h2>
            <div class="grid">
                <a class="tile" href="va_ennx_vista_push.html" style="border-color: #e87722;">
                    <div class="tile-title" style="color:#e87722;">&#x1F4E1; ENNX &rarr; VistA Push</div>
                    <p style="color:var(--muted-docs); margin:0;">ENNX scan to AEMS/MERS workflow. Load sessions, preview scan data, push asset location updates via MERGE pipeline.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #e87722 15%, transparent); border:1px solid #e87722; color:#e87722;">AEMS/MERS</span></p>
                </a>

                <a class="tile" href="va_valip_integration.html" style="border-color: #3b82f6;">
                    <div class="tile-title" style="color:#3b82f6;">&#x1F3D7; VALIP & VA Integration Architecture</div>
                    <p style="color:var(--muted-docs); margin:0;">VA Logistics Integration Platform (VALIP), HELM program, three integration paths. FileMan 22.2, SQLI, VA coordination.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Enterprise</span></p>
                </a>

                <a class="tile" href="aems_mers_integration.html" style="border-color: var(--accent2-docs);">
                    <div class="tile-title" style="color:var(--accent2-docs);">&#128257; AEMS-MERS & VistA Integration</div>
                    <p style="color:var(--muted-docs); margin:0;">Bidirectional data synchronization between iDash and VA Systems of Record. RPC-based updates, field mapping, space file reconciliation.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Enterprise</span></p>
                </a>

                <a class="tile" href="va_fhir_bridge.html" style="border-color: var(--line-docs); opacity: 0.6;">
                    <div class="tile-title" style="color:var(--muted-docs);">&#127973; FHIR Bridge <span style="color: var(--danger); font-size: 0.8em;">(DEPRECATED)</span></div>
                    <p style="color:var(--muted-docs); margin:0;"><strong>Deprecated.</strong> Lighthouse FHIR is for patient/Veteran data. See VALIP and ENNX &rarr; VistA Push instead.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--danger) 15%, transparent); border:1px solid var(--danger); color:var(--danger);">Deprecated</span></p>
                </a>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             9. ARCHITECTURE & DEPLOYMENT
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSee("docs_arch")) { %>
        <div class="card">
            <h2><span class="section-num">9</span>&#9881; Architecture & Deployment</h2>
            <div class="grid">
                <a class="tile" href="idash_architecture_rationale.html" style="border-color: var(--warn, #f59e0b);">
                    <div class="tile-title" style="color:var(--warn, #f59e0b);">&#127959; Architecture Rationale & Developer Handoff</div>
                    <p style="color:var(--muted-docs); margin:0;">Why iDash is built the way it is. Hybrid SQL + API approach, key file map, two-pipeline IIS setup.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--warn, #f59e0b) 15%, transparent); border:1px solid var(--warn, #f59e0b); color:var(--warn, #f59e0b);">Hybrid Architecture</span></p>
                </a>

                <a class="tile" href="idash_deployment_guide.html" style="border-color: #a855f7;">
                    <div class="tile-title" style="color:#a855f7;">&#128640; Complete Deployment Guide</div>
                    <p style="color:var(--muted-docs); margin:0;">Step-by-step playbook for installing and configuring iDash on a new Windows Server.</p>
                </a>

                <a class="tile" href="va_system_migration_guide.html" style="border-color: #3b82f6; background: linear-gradient(135deg, color-mix(in srgb, var(--text), transparent 98%), rgba(59, 130, 246, 0.08));">
                    <div class="tile-title" style="color:#3b82f6;">&#128640; Local-to-Remote Migration &amp; Replication Playbook</div>
                    <p style="color:var(--muted-docs); margin:0;">Step-by-step engineering SOP for synchronizing remote field laptops, mobile inventory carts, and facility servers with the localhost development baseline &mdash; with 100% UI parity and zero database or configuration disruption.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">SOP-ENG-2026-09</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">1:1 Sync</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Tailscale &amp; Manual</span></p>
                </a>

                <a class="tile" href="va_idash_licensing_guide.html" style="border-color: #38bdf8;">
                    <div class="tile-title" style="color:#38bdf8;">&#128273; iDash Software Licensing Guide</div>
                    <p style="color:var(--muted-docs); margin:0;">Cryptographic RSA-2048 licensing architecture, Installation ID hardware node-locking, and step-by-step deployment for new carts and regional servers.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #38bdf8 15%, transparent); border:1px solid #38bdf8; color:#38bdf8;">Licensing</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Air-Gapped</span></p>
                </a>

                <a class="tile" href="va_commercial_licensing_sbom.html" style="border-color: #10b981; background: linear-gradient(135deg, color-mix(in srgb, var(--text), transparent 98%), rgba(16, 185, 129, 0.08));">
                    <div class="tile-title" style="color:#10b981;">&#128220; Third-Party Software, SBOM &amp; Commercial Approval</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete Software Bill of Materials (SBOM) with SHA-256 hashes, MIT attribution register, EPPlus replacement audit, and formal Version 1.0 commercial-use release approval determination.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">v1.0 Approved</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Full SBOM</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #a855f7 15%, transparent); border:1px solid #a855f7; color:#a855f7;">MIT License</span></p>
                </a>

                <a class="tile" href="va_security_readiness_review.html" style="border-color: #10b981; background: linear-gradient(135deg, color-mix(in srgb, var(--text), transparent 98%), rgba(16, 185, 129, 0.08));">
                    <div class="tile-title" style="color:#10b981;">&#128737; Security Readiness Review &amp; Production Certification</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete remediation register for the September 11, 2026 security review. Documents authorization consistency fixes, fail-closed API policies, CSRF HTTP POST enforcement, persistent audit logs, and unauthenticated verification results.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">v1.0 Certified</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">All 5 Findings Fixed</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Fail-Closed</span></p>
                </a>

                <a class="tile" href="va_software_agreement.html" style="border-color: #10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128220; Software Usage &amp; Non-Duplication Agreement</div>
                    <p style="color:var(--muted-docs); margin:0;">Standard end-user terms of use, non-replication covenant, and proprietary software rights agreement for all iDash installations.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">EULA</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #3b82f6 15%, transparent); border:1px solid #3b82f6; color:#3b82f6;">Terms of Use</span></p>
                </a>

                <a class="tile" href="va_system_architecture.html" style="border-color: var(--accent-docs); background: linear-gradient(135deg, color-mix(in srgb, var(--text), transparent 98%), rgba(46, 168, 255, 0.08));">
                    <div class="tile-title" style="color:var(--accent-docs);">&#128451; System &amp; Integration Architecture</div>
                    <p style="color:var(--muted-docs); margin:0;">Master 4-tier architectural specification: Zero-footprint web tier, dual-engine printing (BarTender REST + native API), non-blocking SQL concurrency, RBAC state, and external dependencies.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent-docs) 15%, transparent); border:1px solid var(--accent-docs); color:var(--accent-docs);">Enterprise Architecture</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">4-Tier Topology</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #8B5CF6 15%, transparent); border:1px solid #8B5CF6; color:#8B5CF6;">Print Pipelines</span></p>
                </a>

                <a class="tile" href="va_site_config.html" style="border-color: #ef4444;">
                    <div class="tile-title" style="color:#ef4444;">&#128274; Installation & Component Manifest</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete technical inventory for OIT Security review. ASPX pages, DLLs, SQL scripts, API endpoints, ports, security model.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #ef4444 15%, transparent); border:1px solid #ef4444; color:#ef4444;">Security Review</span></p>
                </a>

                <a class="tile" href="va_network_guidelines.html" style="border-color: var(--warn, #f59e0b);">
                    <div class="tile-title" style="color:var(--warn, #f59e0b);">&#127760; OIT Network & Server Implementation</div>
                    <p style="color:var(--muted-docs); margin:0;">Server provisioning, SQL setup, firewall/ACL ports (per ERA), WiFi onboarding, static IP printers, pre-deployment checklist.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--warn, #f59e0b) 15%, transparent); border:1px solid var(--warn, #f59e0b); color:var(--warn, #f59e0b);">ERA Reference</span></p>
                </a>

                <a class="tile" href="va_api_reference.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128268; API Reference &amp; Mobile Architecture</div>
                    <p style="color:var(--muted-docs); margin:0;">Complete technical reference: Zebra TC53 / RFD40 handheld sweep architecture, DataWedge &amp; Enterprise Browser JS APIs, in-memory continuous sweeps (30&ndash;50 tags/sec), Mobile Inventory WebMethods, fail-closed remote import, NIST SP 800-53 Rev. 5 &amp; Section 508 federal compliance, and all external REST/IoT APIs.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Reference</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #a855f7 15%, transparent); border:1px solid #a855f7; color:#a855f7;">Zebra Mobile</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">NIST / 508</span></p>
                </a>

                <a class="tile" href="va_support_request.html" style="border-color: #2ea8ff;">
                    <div class="tile-title" style="color:#2ea8ff;"><img src="../Assets/branding/rfid.png" style="height:15px;vertical-align:middle;margin-right:6px;" alt="" />Support Request</div>
                    <p style="color:var(--muted-docs); margin:0;">In-app support ticket form. AJAX + EmailHelper SMTP. User guide, developer reference, and troubleshooting.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #2ea8ff 15%, transparent); border:1px solid #2ea8ff; color:#2ea8ff;">Hub Feature</span></p>
                </a>
            </div>
        </div>
        <% } %>

        <!-- -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•
             10. GUIDES & SOPs
             -•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-•-• -->
        <% if (CanSeeAny(new[]{"docs_label_sop", "docs_cookbook", "docs_arch", "admin_system_auto"})) { %>
        <div class="card">
            <h2><span class="section-num">10</span>&#128218; Guides, SOPs & Notifications</h2>
            <div class="grid">
                <% if (CanSee("docs_label_sop")) { %>
                <a class="tile" href="va_label_sop.html">
                    <div class="tile-title">VA Label Types and Application SOP</div>
                    <p style="color:var(--muted-docs); margin:0;">Standard Operating Procedure, infection control justification, and field FAQ for IQ350 RFID labels in VA clinical environments.</p>
                </a>
                <% } %>

                <% if (CanSee("docs_cookbook")) { %>
                <a class="tile" href="idi_mobile_connectivity_cookbook.html" style="border-color:#10b981;">
                    <div class="tile-title" style="color:#10b981;">&#128241; IDI Mobile Connectivity Cookbook</div>
                    <p style="color:var(--muted-docs); margin:0;">WiFi onboarding, scanner setup, firewall rules, printer configuration, and troubleshooting for the RFID mobile scanner.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981, transparent 85%); border:1px solid #10b981; color:#10b981;">Field Guide</span></p>
                </a>
                <% } %>

                <% if (CanSee("docs_arch")) { %>
                <a class="tile" href="va_downloads.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128230; Downloads & Uploads</div>
                    <p style="color:var(--muted-docs); margin:0;">Secure file exchange &mdash; download software, templates, drivers. Drag-and-drop upload with security controls.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">File System</span></p>
                </a>
                <% } %>

                <% if (CanSeeAny(new[]{"admin_system_update", "docs_arch", "admin"})) { %>
                <a class="tile" href="va_system_migration_guide.html" style="border-color: #38bdf8; background: color-mix(in srgb, #38bdf8, transparent 96%);">
                    <div class="tile-title" style="color:#38bdf8;">&#128640; Local-to-Remote Migration &amp; Replication Playbook</div>
                    <p style="color:var(--muted-docs); margin:0;">Comprehensive deployment and synchronization playbook: 1-Click Over-The-Air Web Update, GitHub repository sync, automated robocopy, Safe Migration Boundaries (web.config preservation), and disaster recovery.<br><span class="chip" style="margin-top:6px; background:rgba(56,189,248,0.15); border:1px solid #38bdf8; color:#38bdf8;">Playbook</span> <span class="chip" style="margin-top:6px; background:rgba(16,185,129,0.15); border:1px solid #10b981; color:#10b981;">Deployment</span> <span class="chip" style="margin-top:6px; background:rgba(139,92,246,0.15); border:1px solid #8b5cf6; color:#8b5cf6;">Zero Downtime</span></p>
                </a>

                <a class="tile" href="../va_system_update.aspx" style="border-color: #10b981; background: color-mix(in srgb, #10b981, transparent 96%);">
                    <div class="tile-title" style="color:#10b981;"><img src="../Assets/branding/rfid.png" style="height:16px;vertical-align:middle;margin-right:6px;" alt="" />System Update &amp; Deployment Tool</div>
                    <p style="color:var(--muted-docs); margin:0;">Live web tool to synchronize this server or remote laptops from Master Node (Tailscale) or GitHub. Full-screen progress overlay, safe boundary protection, and IIS AppPool refresh.<br><span class="chip" style="margin-top:6px; background:rgba(16,185,129,0.15); border:1px solid #10b981; color:#10b981;">Live Tool</span> <span class="chip" style="margin-top:6px; background:rgba(56,189,248,0.15); border:1px solid #38bdf8; color:#38bdf8;">1-Click OTA</span></p>
                </a>
                <% } %>

                <% if (CanSee("admin_system_auto")) { %>
                <a class="tile" href="va_sms_alerting.html" style="border-color: #f59e0b;">
                    <div class="tile-title" style="color:#f59e0b;">&#128276; iDash Alerts &amp; System Automations</div>
                    <p style="color:var(--muted-docs); margin:0;">In-app asset watch lists, real-time location mismatch alerts, automated system failure triggers (SQL crash, print failures), and carrier SMS deprecation architecture.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, #f59e0b 15%, transparent); border:1px solid #f59e0b; color:#f59e0b;">Alerting</span> <span class="chip" style="margin-top:6px; background:color-mix(in srgb, #10b981 15%, transparent); border:1px solid #10b981; color:#10b981;">Automations</span></p>
                </a>

                <a class="tile" href="va_email_recipient_storage.html">
                    <div class="tile-title">&#128231; Email Recipient Storage</div>
                    <p style="color:var(--muted-docs); margin:0;">Email recipients migrated from <code>web.config</code> to standalone JSON. IIS app pool recycle fix.<br><span class="chip" style="margin-top:6px; background:color-mix(in srgb, var(--accent2-docs) 15%, transparent); border:1px solid var(--accent2-docs); color:var(--accent2-docs);">Architecture Fix</span></p>
                </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <div style="text-align:center; color:var(--muted-docs); font-size:12px; margin-top:40px;">
            iDash Documentation v2.9.0 &middot; Build 2026-09-08 &middot; &copy; 2026 ID Integration Inc.
        </div>
    </div>

<script>
// Documentation Hub Search
(function() {
    var input = document.getElementById('docSearch');
    var counter = document.getElementById('searchCount');
    var clearBtn = document.getElementById('searchClear');
    if (!input) return;

    var sections = document.querySelectorAll('.wrap > .card');

    input.addEventListener('input', function() {
        var q = input.value.trim().toLowerCase();
        clearBtn.style.display = q ? 'block' : 'none';

        if (!q) {
            sections.forEach(function(s) { s.classList.remove('doc-section-hidden'); });
            var allTiles = document.querySelectorAll('.wrap .grid .tile');
            allTiles.forEach(function(t) { t.style.display = ''; });
            counter.textContent = '';
            return;
        }

        var totalVisible = 0;

        sections.forEach(function(section) {
            if (section.querySelector('h1')) return;

            var grid = section.querySelector('.grid');
            if (!grid) {
                var txt = (section.textContent || '').toLowerCase();
                section.classList.toggle('doc-section-hidden', txt.indexOf(q) === -1);
                return;
            }

            var tiles = grid.querySelectorAll('.tile');
            var sectionVisible = 0;

            tiles.forEach(function(tile) {
                var tileText = (tile.textContent || '').toLowerCase();
                var match = tileText.indexOf(q) !== -1;
                tile.style.display = match ? '' : 'none';
                if (match) sectionVisible++;
            });

            totalVisible += sectionVisible;
            section.classList.toggle('doc-section-hidden', sectionVisible === 0);
        });

        counter.textContent = totalVisible + ' result' + (totalVisible !== 1 ? 's' : '');
    });

    document.addEventListener('keydown', function(e) {
        if ((e.ctrlKey && e.key === 'k') || (e.key === '/' && !e.ctrlKey && !e.altKey && document.activeElement.tagName !== 'INPUT')) {
            e.preventDefault(); input.focus(); input.select();
        }
        if (e.key === 'Escape' && document.activeElement === input) { clearSearch(); input.blur(); }
    });
})();

function clearSearch() {
    var input = document.getElementById('docSearch');
    input.value = '';
    input.dispatchEvent(new Event('input'));
    input.focus();
}
</script>
</body>
</html>
