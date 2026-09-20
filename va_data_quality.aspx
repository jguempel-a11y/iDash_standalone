<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_data_quality.aspx.cs" Inherits="va_data_quality" ResponseEncoding="utf-8" ContentType="text/html; charset=utf-8" EnableSessionState="ReadOnly" %>
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Data Quality &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        :root {
            --bg-base:      var(--bg);
            --panel-bg:     var(--card);
            --panel-border: var(--line);
            --text-main:    var(--text);
            --text-accent:  var(--muted);
            --highlight:    var(--accent);
            --success:      var(--accent-2);
            --accent:       #8B5CF6;
            --warning:      var(--warn);
        }

        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background: var(--bg-base);
            color: var(--text-main);
            font-family: 'Inter', 'Segoe UI', sans-serif;
            font-size: 14px;
            background-image:
                radial-gradient(circle at top left,  color-mix(in srgb, var(--accent), transparent 95%), transparent 40%),
                radial-gradient(circle at bottom right, rgba(139,92,246,0.06), transparent 40%);
            min-height: 100vh;
        }

        .dash { max-width: 1440px; margin: 0 auto; padding: 30px 24px; }

        /* ── HEADER ── */
        .page-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 28px;
            border-bottom: 1px solid var(--panel-border);
            padding-bottom: 20px;
            flex-wrap: wrap; gap: 16px;
        }
        .page-header h1 {
            font-size: 26px; font-weight: 700;
            background: linear-gradient(90deg, #EF4444, #F97316, #F59E0B);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .header-right { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }

        /* ── GLASS ── */
        .glass {
            background: var(--panel-bg);
            backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
            border: 1px solid var(--panel-border);
            border-radius: 16px; padding: 24px;
            box-shadow:var(--shadow);
            margin-bottom: 22px;
        }
        .panel-title {
            font-size: 12px; font-weight: 600;
            color: var(--text-accent);
            text-transform: uppercase; letter-spacing: 0.8px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            padding-bottom: 12px; margin-bottom: 18px;
        }

        /* ── SCORE ROW ── */
        .score-row {
            display: grid;
            grid-template-columns: 220px 1fr;
            gap: 22px; margin-bottom: 22px; align-items: start;
        }
        @media(max-width:800px) { .score-row { grid-template-columns: 1fr; } }

        /* Score gauge card */
        .score-card {
            background: var(--panel-bg);
            border: 1px solid var(--panel-border);
            border-radius: 16px; padding: 28px 20px;
            text-align: center;
            box-shadow:var(--shadow);
        }
        .score-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px; color: var(--text-accent); margin-bottom: 12px; }
        .score-val {
            font-size: 64px; font-weight: 700; line-height: 1;
            margin-bottom: 6px;
        }
        .score-grade { font-size: 18px; font-weight: 600; margin-bottom: 14px; }
        .score-ring {
            width: 120px; height: 120px; margin: 0 auto 16px;
            position: relative;
        }
        .score-ring svg { transform: rotate(-90deg); }
        .score-ring-track { fill: none; stroke: rgba(255,255,255,0.06); stroke-width: 10; }
        .score-ring-fill  { fill: none; stroke-width: 10; stroke-linecap: round; transition: stroke-dashoffset 1s ease; }
        .score-sub { font-size: 12px; color: var(--text-accent); line-height: 1.5; }

        /* Issue cards grid */
        .issue-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
        }
        @media(max-width:1150px) { .issue-grid { grid-template-columns: repeat(2, 1fr); } }
        @media(max-width:560px) { .issue-grid { grid-template-columns: 1fr; } }

        .issue-card {
            background: var(--panel-bg);
            border: 1px solid var(--panel-border);
            border-radius: 14px; padding: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.2);
            transition: border-color 0.2s, box-shadow 0.2s;
        }
        .issue-card:hover { box-shadow:var(--shadow); }

        .issue-icon { font-size: 22px; margin-bottom: 10px; }
        .issue-count {
            font-size: 38px; font-weight: 700; line-height: 1;
            margin-bottom: 4px;
        }
        .issue-pct { font-size: 13px; font-weight: 600; margin-bottom: 6px; }
        .issue-name { font-size: 13px; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
        .issue-desc { font-size: 11px; color: var(--text-accent); line-height: 1.4; }

        .sev-high   { border-top: 3px solid var(--danger); }
        .sev-medium { border-top: 3px solid var(--warning); }
        .sev-low    { border-top: 3px solid var(--highlight); }

        /* ── ISSUE DETAIL PANELS ── */
        .issue-detail { margin-bottom: 22px; }
        .detail-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 16px; flex-wrap: wrap; gap: 10px;
        }
        .detail-title { font-size: 16px; font-weight: 600; display: flex; align-items: center; gap: 10px; }
        .issue-badge {
            display: inline-flex; align-items: center;
            padding: 3px 10px; border-radius: 20px; font-size: 12px; font-weight: 700;
        }
        .badge-high    { background: color-mix(in srgb, var(--danger), transparent 85%);  color: var(--danger);  border: 1px solid rgba(239,68,68,0.3); }
        .badge-medium  { background: rgba(245,158,11,0.18); color: var(--warning); border: 1px solid rgba(245,158,11,0.3); }
        .badge-info    { background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--highlight);border: 1px solid rgba(46,168,255,0.3); }
        .badge-success { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--success); border: 1px solid rgba(16,185,129,0.3); }

        .detail-actions { display: flex; gap: 10px; flex-wrap: wrap; }

        /* ── BUTTONS ── */
        .btn-primary {
            display: inline-flex; align-items: center; gap: 6px;
            background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--highlight);
            border: 1px solid var(--highlight);
            padding: 7px 16px; border-radius: 8px; font-size: 13px; font-weight: 600;
            cursor: pointer; text-decoration: none; transition: all 0.2s;
        }
        .btn-primary:hover { background: color-mix(in srgb, var(--accent), transparent 85%); }

        .btn-success {
            display: inline-flex; align-items: center;
            background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--success);
            border: 1px solid var(--success);
            padding: 7px 16px; border-radius: 8px; font-size: 13px; font-weight: 600;
            cursor: pointer; transition: all 0.2s;
        }
        .btn-success:hover { background: color-mix(in srgb, var(--accent-2), transparent 85%); }

        .btn-ghost {
            background: rgba(255,255,255,0.04); color: var(--text-accent);
            border: 1px solid var(--line);
            padding: 7px 14px; border-radius: 8px; font-size: 13px; font-weight: 500;
            cursor: pointer; text-decoration: none; transition: all 0.2s;
        }
        .btn-ghost:hover { color: var(--text-main); border-color: var(--panel-border); }

        .btn-warn {
            background: color-mix(in srgb, var(--danger), transparent 85%); color: var(--danger);
            border: 1px solid rgba(239,68,68,0.35);
            padding: 7px 14px; border-radius: 8px; font-size: 13px; font-weight: 600;
            cursor: pointer; transition: all 0.2s;
        }
        .btn-warn:hover { background: color-mix(in srgb, var(--danger), transparent 85%); }

        .ctrl-select {
            background: var(--chip); color: var(--text-main);
            border: 1px solid var(--panel-border);
            padding: 7px 12px; border-radius: 8px; font-size: 13px; outline: none;
        }
        .ctrl-select option { background: var(--card); }

        /* ── PREVIEW GRID ── */
        .preview-wrap { overflow-x: auto; max-height: 400px; margin-top: 16px; }
        .preview-grid {
            width: 100%; border-collapse: collapse; font-size: 12px;
        }
        .preview-grid th {
            background: rgba(255,255,255,0.04); color: var(--text-accent);
            font-size: 10px; text-transform: uppercase; letter-spacing: 0.6px;
            padding: 8px 12px; text-align: left; cursor: pointer;
            border-bottom: 1px solid var(--line); user-select: none;
            position: sticky; top: 0; z-index: 1;
            white-space: nowrap;
        }
        .preview-grid th:hover { color: var(--text-main); }
        .preview-grid td { padding: 8px 12px; border-bottom: 1px solid rgba(255,255,255,0.03); color: var(--text-main); }
        .preview-grid tbody tr:hover td { background: rgba(255,255,255,0.025); }

        .filter-input {
            width: 100%; background: rgba(0,0,0,0.35); color: #fff;
            border: 1px solid var(--line); padding: 4px 7px;
            border-radius: 4px; font-size: 11px; font-weight: 400;
            margin-top: 4px;
        }
        .filter-input::placeholder { color: rgba(255,255,255,0.25); }

        .err-msg { background: color-mix(in srgb, var(--danger), transparent 85%); border: 1px solid rgba(239,68,68,0.3); padding: 12px 16px; border-radius: 8px; margin-bottom: 16px; color: var(--danger); }

        /* collapse toggle */
        .collapsible-body { overflow: hidden; transition: max-height 0.3s ease; max-height: 0; }
        .collapsible-body.open { max-height: 600px; }

        /* hidden literal count holders */
        #litCounts { display: none; }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="dash">

    <!-- ── HEADER ── -->
    <div class="page-header">
        <h1>Data Quality Command Center</h1>
        <div class="header-right">
            <asp:DropDownList ID="DdlCompany" runat="server" AutoPostBack="true"
                OnSelectedIndexChanged="DdlCompany_SelectedIndexChanged" CssClass="ctrl-select" />
            <asp:Button runat="server" Text="Refresh" CssClass="btn-primary" OnClick="BtnRefresh_Click" />
            <asp:Button ID="BtnExportExcel" runat="server" Text="Export All" CssClass="btn-success"
                OnClick="BtnExportExcel_Click" />
            <a href="documentation/va_data_quality.html" class="nav-pill nav-pill-ghost">&#128214; Docs</a>
            <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
        </div>
    </div>

    <asp:Literal ID="LitErr" runat="server" EnableViewState="false" />

    <!-- hidden count values for JS score calc -->
    <div id="litCounts">
        <span id="cnt-eil"><asp:Literal ID="LitNoEILCount"       runat="server" Text="0" /></span>
        <span id="cnt-loc"><asp:Literal ID="LitNoLocCount"       runat="server" Text="0" /></span>
        <span id="cnt-sts"><asp:Literal ID="LitStatusOtherCount" runat="server" Text="0" /></span>
        <span id="cnt-mee"><asp:Literal ID="LitMalformedEECount" runat="server" Text="0" /></span>
        <span id="cnt-tot"><asp:Literal ID="LitTotalCount"       runat="server" Text="0" /></span>
    </div>

    <!-- ── SCORE + ISSUE CARDS ── -->
    <div class="score-row">

        <!-- Overall Score Ring -->
        <div class="score-card">
            <div class="score-label">Overall Data Quality Score</div>
            <div class="score-ring">
                <svg width="120" height="120" viewBox="0 0 120 120">
                    <circle class="score-ring-track" cx="60" cy="60" r="50"/>
                    <circle class="score-ring-fill" id="scoreRingFill" cx="60" cy="60" r="50"
                        stroke-dasharray="314" stroke-dashoffset="314" stroke="var(--success)"/>
                </svg>
            </div>
            <div class="score-val" id="scoreVal">--</div>
            <div class="score-grade" id="scoreGrade"></div>
            <div class="score-sub" id="scoreSub">Loading metrics...</div>
        </div>

        <!-- Issue Cards -->
        <div class="issue-grid">

            <div class="issue-card sev-high">
                <div class="issue-icon">&#9888;</div>
                <div class="issue-count" id="ic-eil" style="color:var(--danger);">--</div>
                <div class="issue-pct"   id="ip-eil" style="color:var(--danger);">--</div>
                <div class="issue-name">Missing EIL / CMR</div>
                <div class="issue-desc">Assets with no Equipment ID Location (text8). Critical &mdash; affects tracking &amp; reporting.</div>
                <div style="margin-top:12px;">
                    <span class="issue-badge badge-high">HIGH SEVERITY</span>
                </div>
            </div>

            <div class="issue-card sev-medium">
                <div class="issue-icon">&#9650;</div>
                <div class="issue-count" id="ic-loc" style="color:var(--warning);">--</div>
                <div class="issue-pct"   id="ip-loc" style="color:var(--warning);">--</div>
                <div class="issue-name">Missing Location</div>
                <div class="issue-desc">Assets with no assigned Location ID. Affects spatial reporting &amp; site inventory.</div>
                <div style="margin-top:12px;">
                    <span class="issue-badge badge-medium">MEDIUM SEVERITY</span>
                </div>
            </div>

            <div class="issue-card sev-low">
                <div class="issue-icon">&#9632;</div>
                <div class="issue-count" id="ic-sts" style="color:var(--highlight);">--</div>
                <div class="issue-pct"   id="ip-sts" style="color:var(--highlight);">--</div>
                <div class="issue-name">Status Not "In Use"</div>
                <div class="issue-desc">Assets with a Disposal Status other than "In Use" &mdash; may include surplus, retired, or NULL.</div>
                <div style="margin-top:12px;">
                    <span class="issue-badge badge-info">INFO</span>
                </div>
            </div>

            <div class="issue-card sev-high">
                <div class="issue-icon">&#9888;</div>
                <div class="issue-count" id="ic-mee" style="color:var(--danger);">--</div>
                <div class="issue-pct"   id="ip-mee" style="color:var(--danger);">--</div>
                <div class="issue-name">Malformed EE Numbers</div>
                <div class="issue-desc">Assets where EE number deviates from standard &ldquo;site + space + EE + entry number&rdquo;.</div>
                <div style="margin-top:12px;">
                    <span class="issue-badge badge-high">HIGH SEVERITY</span>
                </div>
            </div>

        </div>
    </div>

    <!-- ── DETAIL PANEL 1: No EIL ── -->
    <div class="glass issue-detail">
        <div class="detail-header">
            <div class="detail-title">
                <span class="issue-badge badge-high">HIGH</span>
                Assets with No EIL / CMR
                <span style="font-size:13px;font-weight:400;color:var(--text-accent);">
                    &mdash; Total: <strong style="color:var(--danger);" id="hd-eil">0</strong>
                </span>
            </div>
            <div class="detail-actions">
                <button type="button" class="btn-primary" id="btnPreviewNoEIL" onclick="loadPreview('noeil', this)">Preview 50</button>
                <asp:LinkButton ID="BtnExportNoEIL" runat="server" CssClass="btn-ghost"
                    Text="Export All" OnClick="Export_Click"
                    CommandArgument="GridNoEIL|NoEILAll" />
            </div>
        </div>
        <p style="font-size:12px;color:var(--text-accent);margin-bottom:10px;">
            Assets missing &ldquo;Equipment ID Location&rdquo; (EIL/Text8). Click Preview to load the first 50 records.
        </p>
        <div class="preview-wrap" id="prev-noeil"></div>
    </div>

    <!-- ── DETAIL PANEL 2: No Location ── -->
    <div class="glass issue-detail">
        <div class="detail-header">
            <div class="detail-title">
                <span class="issue-badge badge-medium">MEDIUM</span>
                Assets with No Location
                <span style="font-size:13px;font-weight:400;color:var(--text-accent);">
                    &mdash; Total: <strong style="color:var(--warning);" id="hd-loc">0</strong>
                </span>
            </div>
            <div class="detail-actions">
                <button type="button" class="btn-primary" id="btnPreviewNoLoc" onclick="loadPreview('noloc', this)">Preview 50</button>
                <asp:LinkButton ID="BtnExportNoLoc" runat="server" CssClass="btn-ghost"
                    Text="Export All" OnClick="Export_Click"
                    CommandArgument="GridNoLoc|NoLocationAll" />
            </div>
        </div>
        <p style="font-size:12px;color:var(--text-accent);margin-bottom:10px;">
            Assets not assigned to any Location ID. Affects spatial reporting and site inventory accuracy.
        </p>
        <div class="preview-wrap" id="prev-noloc"></div>
    </div>

    <!-- ── DETAIL PANEL 3: Status Other ── -->
    <div class="glass issue-detail">
        <div class="detail-header">
            <div class="detail-title">
                <span class="issue-badge badge-info">INFO</span>
                Status Not &ldquo;In Use&rdquo;
                <span style="font-size:13px;font-weight:400;color:var(--text-accent);">
                    &mdash; Total: <strong style="color:var(--highlight);" id="hd-sts">0</strong>
                </span>
            </div>
            <div class="detail-actions">
                <button type="button" class="btn-primary" id="btnPreviewStatusOther" onclick="loadPreview('statusother', this)">Preview 50</button>
                <asp:LinkButton ID="BtnExportStatusOther" runat="server" CssClass="btn-ghost"
                    Text="Export All" OnClick="Export_Click"
                    CommandArgument="GridStatusOther|StatusOtherAll" />
            </div>
        </div>
        <p style="font-size:12px;color:var(--text-accent);margin-bottom:10px;">
            Assets with Disposal Status other than &ldquo;In Use&rdquo; or NULL &mdash; may include surplus, retired, or missing status values.
        </p>
        <div class="preview-wrap" id="prev-statusother"></div>
    </div>

    <!-- ── DETAIL PANEL 4: Malformed EE Numbers ── -->
    <div class="glass issue-detail">
        <div class="detail-header">
            <div class="detail-title">
                <span class="issue-badge badge-high">HIGH</span>
                Malformed / Non-Conforming EE Asset Numbers
                <span style="font-size:13px;font-weight:400;color:var(--text-accent);">
                    &mdash; Total: <strong style="color:var(--danger);" id="hd-mee">0</strong>
                </span>
            </div>
            <div class="detail-actions">
                <button type="button" class="btn-primary" id="btnPreviewMalformedEE" onclick="loadPreview('malformedee', this)">Preview 50</button>
                <asp:LinkButton ID="BtnExportMalformedEE" runat="server" CssClass="btn-ghost"
                    Text="Export All" OnClick="Export_Click"
                    CommandArgument="GridMalformedEE|MalformedEEAll" />
            </div>
        </div>
        <p style="font-size:12px;color:var(--text-accent);margin-bottom:10px;">
            Assets whose EE number does not conform to standard VA naming &ldquo;site + space + EE + entry number&rdquo; (e.g. missing site code, single &ldquo;E&rdquo;, embedded letters, extra spaces, or non-numeric entry digits).
        </p>
        <div class="preview-wrap" id="prev-malformedee"></div>
    </div>

</div><!-- /dash -->
</form>

<script type="text/javascript">
    function fmtN(n) { return new Intl.NumberFormat().format(n); }
    function pctStr(v, t) { return t > 0 ? (v / t * 100).toFixed(1) + '%' : '0%'; }

    function animVal(el, target, dur) {
        if (!el || isNaN(target)) return;
        var t0 = null, fmt = new Intl.NumberFormat();
        function step(t) {
            if (!t0) t0 = t;
            var p = Math.min((t - t0) / dur, 1);
            el.textContent = fmt.format(Math.round(p * target));
            if (p < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
    }

    function setupGrid(tableEl) {
        if (!tableEl || tableEl.rows.length < 2) return;
        var thead = tableEl.querySelector('thead');
        if (!thead) {
            thead = document.createElement('thead');
            tableEl.insertBefore(thead, tableEl.firstChild);
            thead.appendChild(tableEl.rows[0]);
        }
        var tbody = tableEl.querySelector('tbody');
        if (!tbody) {
            tbody = document.createElement('tbody');
            while (tableEl.rows.length > 0) tbody.appendChild(tableEl.rows[0]);
            tableEl.appendChild(tbody);
        }
        var ths = thead.querySelectorAll('th');
        var fr = document.createElement('tr');
        ths.forEach(function(th, i) {
            th.style.cursor = 'pointer';
            th.innerHTML = th.innerText + ' <span style="font-size:9px;opacity:.5;">&#9650;&#9660;</span>';
            th.onclick = function() { sortG(tableEl, i); };
            var ftd = document.createElement('th');
            var inp = document.createElement('input');
            inp.className = 'filter-input'; inp.placeholder = '...'; inp.setAttribute('data-col', i);
            inp.oninput = function() { filterG(tableEl); };
            ftd.appendChild(inp); fr.appendChild(ftd);
        });
        thead.appendChild(fr);
    }

    var _sd = {};
    function sortG(tbl, col) {
        var tbody = tbl.querySelector('tbody'); if (!tbody) return;
        var key = tbl.id + col;
        var dir = _sd[key] === 'asc' ? 'desc' : 'asc'; _sd[key] = dir;
        var rows = Array.from(tbody.querySelectorAll('tr'));
        rows.sort(function(a, b) {
            var ta = a.cells[col] ? a.cells[col].innerText.trim() : '';
            var tb = b.cells[col] ? b.cells[col].innerText.trim() : '';
            var na = parseFloat(ta), nb = parseFloat(tb);
            if (!isNaN(na) && !isNaN(nb)) return dir==='asc' ? na-nb : nb-na;
            return dir==='asc' ? ta.localeCompare(tb) : tb.localeCompare(ta);
        });
        rows.forEach(function(r) { tbody.appendChild(r); });
    }

    function filterG(tbl) {
        var tbody = tbl.querySelector('tbody'); if (!tbody) return;
        var inputs = tbl.querySelectorAll('.filter-input');
        tbl.querySelectorAll('tbody tr').forEach(function(row) {
            var show = true;
            inputs.forEach(function(inp) {
                var col = parseInt(inp.getAttribute('data-col'));
                var val = inp.value.toLowerCase();
                var cell = row.cells[col];
                if (val && cell && cell.innerText.toLowerCase().indexOf(val) === -1) show = false;
            });
            row.style.display = show ? '' : 'none';
        });
    }

    // ── Score calculation ──────────────────────────────
    function computeScore() {
        var eil  = parseInt(document.getElementById('cnt-eil').textContent.trim()) || 0;
        var loc  = parseInt(document.getElementById('cnt-loc').textContent.trim()) || 0;
        var sts  = parseInt(document.getElementById('cnt-sts').textContent.trim()) || 0;
        var mee  = parseInt(document.getElementById('cnt-mee').textContent.trim()) || 0;
        var tot  = parseInt(document.getElementById('cnt-tot').textContent.trim()) || 1;

        // Update issue card counts
        animVal(document.getElementById('ic-eil'), eil, 800);
        animVal(document.getElementById('ic-loc'), loc, 800);
        animVal(document.getElementById('ic-sts'), sts, 800);
        animVal(document.getElementById('ic-mee'), mee, 800);
        document.getElementById('ip-eil').textContent = pctStr(eil, tot) + ' of assets';
        document.getElementById('ip-loc').textContent = pctStr(loc, tot) + ' of assets';
        document.getElementById('ip-sts').textContent = pctStr(sts, tot) + ' of assets';
        document.getElementById('ip-mee').textContent = pctStr(mee, tot) + ' of assets';

        // Write to detail panel headers
        document.getElementById('hd-eil').textContent = fmtN(eil);
        document.getElementById('hd-loc').textContent = fmtN(loc);
        document.getElementById('hd-sts').textContent = fmtN(sts);
        document.getElementById('hd-mee').textContent = fmtN(mee);

        // Score: penalise EIL (40pts weight), loc (25pts), malformed EE (25pts), status (10pts)
        var eilOk  = tot > 0 ? Math.max(0, 1 - eil / tot) : 1;
        var locOk  = tot > 0 ? Math.max(0, 1 - loc / tot) : 1;
        var meeOk  = tot > 0 ? Math.max(0, 1 - mee / tot) : 1;
        var stsOk  = tot > 0 ? Math.max(0, 1 - (sts - tot * 0.05) / tot) : 1; // status "other" up to 5% is normal

        var score = Math.round(eilOk * 40 + locOk * 25 + meeOk * 25 + Math.min(1, stsOk) * 10);
        score = Math.max(0, Math.min(100, score));

        // Animate score
        var sEl = document.getElementById('scoreVal');
        animVal(sEl, score, 1000);

        // Ring
        var fill = document.getElementById('scoreRingFill');
        var circ = 2 * Math.PI * 50; // r=50
        var offset = circ - (circ * score / 100);
        setTimeout(function() {
            fill.style.strokeDashoffset = offset;
        }, 100);

        // Color by score
        var color = score >= 80 ? 'var(--success)' : score >= 60 ? 'var(--warning)' : 'var(--danger)';
        fill.style.stroke = color;
        sEl.style.color   = color;

        // Grade
        var grade = score >= 90 ? 'A - Excellent' : score >= 80 ? 'B - Good' : score >= 70 ? 'C - Fair' : score >= 60 ? 'D - Poor' : 'F - Critical';
        var gradeEl = document.getElementById('scoreGrade');
        gradeEl.textContent = grade;
        gradeEl.style.color = color;

        document.getElementById('scoreSub').textContent =
            fmtN(tot) + ' total assets \u2022 ' + fmtN(eil + loc + mee) + ' critical issues';
    }

    // ── AJAX Preview (replaces postback buttons) ─────────────────────
    function getSiteId() {
        var ddl = document.getElementById('<%= DdlCompany.ClientID %>');
        return ddl ? ddl.value : '0';
    }

    function loadPreview(type, btn) {
        var containerId = 'prev-' + type;
        var container = document.getElementById(containerId);
        if (!container) return;

        // Toggle: if already loaded, hide/show
        if (container.dataset.loaded === '1') {
            container.style.display = container.style.display === 'none' ? '' : 'none';
            return;
        }

        btn.disabled = true;
        btn.textContent = 'Loading...';
        container.innerHTML = '<div style="padding:16px;color:var(--text-accent);font-size:13px;">&#9203; Loading preview...</div>';

        var url = 'va_data_quality.aspx?api=preview&type=' + encodeURIComponent(type)
                + '&siteid=' + encodeURIComponent(getSiteId())
                + '&t=' + Date.now();

        fetch(url)
            .then(function(r) {
                if (!r.ok) throw new Error('HTTP ' + r.status);
                return r.json();
            })
            .then(function(data) {
                btn.disabled = false;
                btn.textContent = 'Hide Preview';
                if (!data.rows || data.rows.length === 0) {
                    container.innerHTML = '<div style="padding:12px;color:var(--success);font-size:13px;">&#10003; No issues found!</div>';
                    container.dataset.loaded = '1';
                    return;
                }
                renderPreviewTable(container, data.cols, data.rows);
                container.dataset.loaded = '1';
            })
            .catch(function(e) {
                btn.disabled = false;
                btn.textContent = 'Preview 50';
                container.innerHTML = '<div style="padding:12px;color:var(--danger);font-size:13px;">Error loading preview: ' + e.message + '</div>';
            });
    }

    function renderPreviewTable(container, cols, rows) {
        var tbl = document.createElement('table');
        tbl.className = 'preview-grid';
        var thead = document.createElement('thead');
        var hrow = document.createElement('tr');
        var frow = document.createElement('tr'); // filter row
        cols.forEach(function(col, i) {
            var th = document.createElement('th');
            th.style.cursor = 'pointer';
            th.innerHTML = col + ' <span style="font-size:9px;opacity:.5;">&#9650;&#9660;</span>';
            th.onclick = function() { sortG(tbl, i); };
            hrow.appendChild(th);
            var ftd = document.createElement('th');
            var inp = document.createElement('input');
            inp.className = 'filter-input'; inp.placeholder = '...'; inp.setAttribute('data-col', i);
            inp.oninput = function() { filterG(tbl); };
            ftd.appendChild(inp); frow.appendChild(ftd);
        });
        thead.appendChild(hrow);
        thead.appendChild(frow);
        tbl.appendChild(thead);
        var tbody = document.createElement('tbody');
        rows.forEach(function(row) {
            var tr = document.createElement('tr');
            row.forEach(function(cell) {
                var td = document.createElement('td');
                td.textContent = cell === null ? '' : cell;
                tr.appendChild(td);
            });
            tbody.appendChild(tr);
        });
        tbl.appendChild(tbody);
        container.innerHTML = '';
        container.appendChild(tbl);
    }

    document.addEventListener('DOMContentLoaded', function() { computeScore(); });

</script>
</body>
</html>

