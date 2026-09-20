<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_idi_tagging_reports.aspx.cs" Inherits="iDash.va_idi_tagging_reports" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <title>IDI Tagging Data Reports &mdash; iDash</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- Include Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --bg-base:      var(--bg);
            --panel-bg:     var(--card);
            --panel-border: var(--line);
            --text-main:    var(--text);
            --text-accent:  var(--muted);
            --highlight:    var(--accent);
            --success:      var(--accent-2);
            --accent:       #8B5CF6;
            --btn-bg:       var(--chip);
            --btn-hover:    var(--card);
        }

        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }

        body {
            margin: 0;
            padding: 0;
            background: var(--bg-base);
            color: var(--text-main);
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-image: radial-gradient(circle at top left, color-mix(in srgb, var(--accent), transparent 95%), transparent 40%),
                              radial-gradient(circle at bottom right, rgba(139, 92, 246, 0.05), transparent 40%);
            min-height: 100vh;
        }

        .dashboard-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 30px 20px;
        }

        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 40px;
            border-bottom: 1px solid var(--panel-border);
            padding-bottom: 20px;
        }

        h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .header-controls {
            display: flex;
            gap: 15px;
            align-items: center;
        }

        /* Glassmorphism Panel */
        .glass-panel {
            background: var(--panel-bg);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid var(--panel-border);
            border-radius: 16px;
            padding: 24px;
            box-shadow:var(--shadow);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .glass-panel:hover {
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4);
        }

        .site-select {
            background: var(--chip);
            color: var(--text-main);
            border: 1px solid var(--panel-border);
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 14px;
            margin-right: 15px;
            outline: none;
        }
        .site-select option { background: var(--card); }

        .kpi-row {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }

        .kpi-card {
            text-align: center;
            padding: 30px 20px;
        }

        .kpi-value {
            font-size: 42px;
            font-weight: 700;
            color: var(--highlight);
            margin-bottom: 10px;
            line-height: 1;
        }
        
        .kpi-card:nth-child(2) .kpi-value { color: var(--success); }
        .kpi-card:nth-child(3) .kpi-value { color: var(--accent); }
        .kpi-card:nth-child(4) .kpi-value { color: #F59E0B; }

        .kpi-title {
            color: var(--text-accent);
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 600;
        }

        .chart-row {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }

        .chart-container {
            position: relative;
            height: 350px;
            width: 100%;
        }

        .panel-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 20px;
            color: var(--text-main);
            border-bottom: 1px solid rgba(255,255,255,0.05);
            padding-bottom: 10px;
        }

        /* Buttons & Controls */
        .btn-group {
            display: flex;
            background: rgba(0,0,0,0.3);
            border-radius: 8px;
            padding: 4px;
        }

        .filter-btn {
            background: transparent;
            color: var(--text-accent);
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 500;
            transition: 0.2s;
        }

        .filter-btn.active {
            background: var(--highlight);
            color: #fff;
            box-shadow: 0 2px 10px rgba(46, 168, 255, 0.3);
        }

        .filter-btn:hover:not(.active) {
            color: var(--text-main);
            background: rgba(255,255,255,0.05);
        }

        /* Downloads Section */
        .action-row {
            display: flex;
            gap: 20px;
            align-items: center;
            justify-content: flex-end;
            margin-top: 20px;
            border-top: 1px solid var(--panel-border);
            padding-top: 20px;
        }

        .btn-action {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: var(--btn-bg);
            color: var(--highlight);
            border: 1px solid var(--highlight);
            padding: 10px 20px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            transition: 0.2s;
            cursor: pointer;
        }

        .btn-action:hover {
            background: var(--btn-hover);
            color: #fff;
            box-shadow: 0 0 15px color-mix(in srgb, var(--accent), transparent 55%);
        }

        .btn-success {
            color: var(--success);
            border-color: var(--success);
            background: color-mix(in srgb, var(--accent-2), transparent 85%);
        }
        
        .btn-success:hover {
            background: color-mix(in srgb, var(--accent-2), transparent 85%);
            color: #fff;
            box-shadow: 0 0 15px color-mix(in srgb, var(--accent-2), transparent 60%);
        }

        .loading-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(11, 18, 33, 0.8);
            backdrop-filter: blur(4px);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 9999;
            color: var(--highlight);
            font-size: 24px;
            font-weight: 600;
            transition: opacity 0.3s;
        }
        
        .nav-link { color: var(--text-accent); text-decoration: none; font-size: 14px; font-weight: 600; display: inline-flex; align-items: center;}
        .nav-link:hover { color: var(--highlight); }

        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
            color: var(--text-main);
        }
        .data-table th {
            background: rgba(0,0,0,0.4);
            color: var(--highlight);
            text-align: left;
            padding: 12px;
            position: sticky;
            top: 0;
            border-bottom: 2px solid var(--panel-border);
        }
        .data-table td {
            padding: 10px 12px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .data-table tr:hover td {
            background: rgba(255,255,255,0.05);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="loading" class="loading-overlay">Loading Executive Dashboard...</div>
        
        <div class="dashboard-container">
            <header>
                <div>
                    <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                    <h1>
                        <img src="<%= ResolveUrl("~/Assets/branding/IDIntegration.jpg") %>" style="height:32px; border-radius:4px;" alt="Logo" onerror="this.style.display='none'"/>
                        IDI Tagging Data Reports
                    </h1>
                </div>
                
                <div class="header-controls">
                    <span style="color:var(--text-accent); font-size: 14px; margin-right: 15px;" id="lastUpdateText">Last Updated: --:--:--</span>
                    <asp:DropDownList ID="DdlSite" runat="server" CssClass="site-select" ClientIDMode="Static"></asp:DropDownList>
                    <div class="btn-group">
                        <button type="button" class="filter-btn" data-range="today">Today</button>
                        <button type="button" class="filter-btn" data-range="week">This Week</button>
                        <button type="button" class="filter-btn" data-range="month">This Month</button>
                        <button type="button" class="filter-btn active" data-range="all">All Time</button>
                    </div>
                </div>
            </header>

            <!-- KPIs -->
            <div class="kpi-row">
                <div class="glass-panel kpi-card">
                    <div class="kpi-value" id="kpi-total" style="color:#F3F4F6;">0</div>
                    <div class="kpi-title">Total Infrastructure Assets</div>
                </div>
                <div class="glass-panel kpi-card">
                    <div class="kpi-value" id="kpi-tagged">0</div>
                    <div class="kpi-title">Total Assets Tagged</div>
                </div>
                <div class="kpi-panel glass-panel kpi-card">
                    <div class="kpi-value" id="kpi-types">0</div>
                    <div class="kpi-title">Tag Types Deployed</div>
                </div>
                <div class="kpi-panel glass-panel kpi-card">
                    <div class="kpi-value" id="kpi-locations">0</div>
                    <div class="kpi-title">Active Locations</div>
                </div>
                <div class="kpi-panel glass-panel kpi-card">
                    <div class="kpi-value" id="kpi-personnel">0</div>
                    <div class="kpi-title">Personnel Tagging</div>
                </div>
            </div>

            <!-- Detailed Metrics Row -->
            <div class="kpi-row" style="grid-template-columns: repeat(4, 1fr);">
                <div class="glass-panel kpi-card">
                    <div class="kpi-title">Assets Tagged</div>
                    <div class="kpi-value" id="kpi-pct-assets">0%</div>
                    <div style="color:var(--text-accent); font-size:13px;" id="kpi-txt-assets">0 / 0</div>
                </div>
                <div class="glass-panel kpi-card">
                    <div class="kpi-title">Locations Visited</div>
                    <div class="kpi-value" id="kpi-pct-locs" style="color:#F59E0B">0%</div>
                    <div style="color:var(--text-accent); font-size:13px;" id="kpi-txt-locs">0 / 0</div>
                </div>
                <div class="glass-panel kpi-card">
                    <div class="kpi-title">CMRs Engaged</div>
                    <div class="kpi-value" id="kpi-pct-cmrs" style="color:var(--accent)">0%</div>
                    <div style="color:var(--text-accent); font-size:13px;" id="kpi-txt-cmrs">0 / 0</div>
                </div>
                <div class="glass-panel kpi-card">
                    <div class="kpi-title">Tagged (Not "In Use")</div>
                    <div class="kpi-value" id="kpi-pct-notuse" style="color:#EF4444">0%</div>
                    <div style="color:var(--text-accent); font-size:13px;" id="kpi-txt-notuse">0 / 0</div>
                </div>
            </div>

            <!-- Charts -->
            <div class="chart-row">
                <div class="glass-panel" style="grid-column: span 1;">
                    <div class="panel-title">Top 10 Locations by Volume</div>
                    <div class="chart-container">
                        <canvas id="barChart"></canvas>
                    </div>
                </div>
                <div class="glass-panel">
                    <div class="panel-title">Asset Completion (Tagged vs Untagged)</div>
                    <div class="chart-container">
                        <canvas id="completionChart"></canvas>
                    </div>
                </div>
                <div class="glass-panel">
                    <div class="panel-title">Tag Type Distribution</div>
                    <div class="chart-container">
                        <canvas id="pieChart"></canvas>
                    </div>
                </div>
            </div>
            
            <div class="glass-panel chart-row" style="grid-template-columns: 1fr;">
                 <div class="panel-title">Tagging Trend History (Last 10 Active Days)</div>
                 <div class="chart-container" style="height: 250px;">
                    <canvas id="trendChart"></canvas>
                 </div>
            </div>

            <!-- Drill-Down Data Panel -->
            <div class="glass-panel" style="margin-bottom: 30px;">
                <div class="panel-title">Recent Tagging Drill-Down</div>
                <div style="overflow-x:auto; max-height: 400px; border-radius: 8px;">
                    <table class="data-table" id="drilldownTable">
                        <thead>
                            <tr>
                                <th>Asset Name / ID</th>
                                <th>Location</th>
                                <th>Tag Type</th>
                                <th>Personnel ID</th>
                                <th>Date Tagged</th>
                            </tr>
                        </thead>
                        <tbody>
                            <!-- Populated via JS -->
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Downloads Panel -->
            <div class="glass-panel">
                <div class="panel-title" style="margin-bottom:0px; border:none;">Data Publishing & Exports</div>
                <p style="color: var(--text-accent); font-size: 14px;">Retrieve the Daily ENNX submission payloads or generate a full Excel data export of all statistics directly from the database.</p>
                <div class="action-row">
                    <a href="va_ennx.aspx" target="_blank" class="btn-action">
                        &#128194; Explore ENNX Reports
                    </a>
                    <a href="va_tag_stats.aspx" target="_blank" class="btn-action btn-success">
                        &#128202; Full Tag Data Export
                    </a>
                </div>
            </div>

        </div>
    </form>

    <script>
        // Chart overrides for dark mode
        Chart.defaults.color = getComputedStyle(document.documentElement).getPropertyValue('--muted').trim();
        Chart.defaults.borderColor = 'rgba(255, 255, 255, 0.05)';
        Chart.defaults.font.family = "'Segoe UI', Roboto, sans-serif";

        let currentRange = 'all';
        let refreshTimer = null;
        const autoRefreshMs = 300000; // 5 minutes

        let barChartInst = null;
        let pieChartInst = null;
        let completionChartInst = null;
        let trendChartInst = null;

        document.addEventListener('DOMContentLoaded', () => {
            initCharts();
            loadData();

            // Setup buttons
            document.querySelectorAll('.filter-btn').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                    e.target.classList.add('active');
                    currentRange = e.target.getAttribute('data-range');
                    loadData();
                });
            });

            // Setup select box change
            document.getElementById('DdlSite').addEventListener('change', () => {
                loadData();
            });
        });

        const tooltipPercentage = {
            callbacks: {
                label: function(context) {
                    let label = context.label || '';
                    if (label) label += ': ';
                    label += context.raw;
                    let total = context.chart._metasets[context.datasetIndex].total;
                    let percentage = total > 0 ? Math.round((context.raw / total) * 100) + '%' : '0%';
                    return label + ' (' + percentage + ')';
                }
            }
        };

        function initCharts() {
            const ctxBar = document.getElementById('barChart').getContext('2d');
            barChartInst = new Chart(ctxBar, {
                type: 'bar',
                data: { labels: [], datasets: [] },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true } }
                }
            });

            const ctxPie = document.getElementById('pieChart').getContext('2d');
            pieChartInst = new Chart(ctxPie, {
                type: 'doughnut',
                data: { labels: [], datasets: [] },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    cutout: '70%',
                    plugins: { legend: { position: 'right' }, tooltip: tooltipPercentage }
                }
            });

            const ctxComp = document.getElementById('completionChart').getContext('2d');
            completionChartInst = new Chart(ctxComp, {
                type: 'doughnut',
                data: { labels: [], datasets: [] },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    cutout: '70%',
                    plugins: { legend: { position: 'right' }, tooltip: tooltipPercentage }
                }
            });
            
            const ctxTrend = document.getElementById('trendChart').getContext('2d');
            trendChartInst = new Chart(ctxTrend, {
                type: 'line',
                data: { labels: [], datasets: [] },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true } },
                    elements: { line: { tension: 0.3 } }
                }
            });
        }

        function loadData() {
            clearTimeout(refreshTimer);
            document.getElementById('loading').style.opacity = '1';
            document.getElementById('loading').style.pointerEvents = 'all';

            const siteId = document.getElementById('DdlSite').value;

            fetch(`?api=dashboardstats&range=${currentRange}&siteid=${siteId}`)
                .then(res => res.json())
                .then(data => {
                    if(data.error) {
                        alert("Error: " + data.error);
                        return;
                    }
                    
                    // Update KPIs
                    animateValue("kpi-total", 0, data.kpis.GrandTotalAssets, 1000);
                    animateValue("kpi-tagged", 0, data.kpis.TotalTagged, 1000);
                    animateValue("kpi-types", 0, data.kpis.TotalTagTypes, 1000);
                    animateValue("kpi-locations", 0, data.kpis.TotalLocations, 1000);
                    animateValue("kpi-personnel", 0, data.kpis.TotalEmployees, 1000);

                    // Calculate Percentages
                    let pctAssets = data.kpis.GrandTotalAssets > 0 ? ((data.kpis.TotalTagged / data.kpis.GrandTotalAssets) * 100).toFixed(1) : 0;
                    document.getElementById('kpi-pct-assets').innerText = pctAssets + '%';
                    document.getElementById('kpi-txt-assets').innerText = data.kpis.TotalTagged.toLocaleString() + ' / ' + data.kpis.GrandTotalAssets.toLocaleString();

                    let pctLocs = data.kpis.AbsoluteLocations > 0 ? ((data.kpis.TotalLocations / data.kpis.AbsoluteLocations) * 100).toFixed(1) : 0;
                    document.getElementById('kpi-pct-locs').innerText = pctLocs + '%';
                    document.getElementById('kpi-txt-locs').innerText = data.kpis.TotalLocations.toLocaleString() + ' / ' + data.kpis.AbsoluteLocations.toLocaleString();

                    let pctCMRs = data.kpis.AbsoluteCMRs > 0 ? ((data.kpis.TotalCMRs / data.kpis.AbsoluteCMRs) * 100).toFixed(1) : 0;
                    document.getElementById('kpi-pct-cmrs').innerText = pctCMRs + '%';
                    document.getElementById('kpi-txt-cmrs').innerText = data.kpis.TotalCMRs.toLocaleString() + ' / ' + data.kpis.AbsoluteCMRs.toLocaleString();

                    let pctNotUse = data.kpis.TotalTagged > 0 ? ((data.kpis.TaggedNotInUse / data.kpis.TotalTagged) * 100).toFixed(1) : 0;
                    document.getElementById('kpi-pct-notuse').innerText = pctNotUse + '%';
                    document.getElementById('kpi-txt-notuse').innerText = data.kpis.TaggedNotInUse.toLocaleString() + ' / ' + data.kpis.TotalTagged.toLocaleString();

                    // Update Bar Chart
                    const locLabels = data.locations.map(d => d.label);
                    const locData = data.locations.map(d => d.count);
                    barChartInst.data.labels = locLabels;
                    barChartInst.data.datasets = [{
                        label: 'Assets Tagged',
                        data: locData,
                        backgroundColor: '#2EA8FF',
                        borderRadius: 4
                    }];
                    barChartInst.update();

                    // Update Pie Chart
                    const tagLabels = data.tagTypes.map(d => d.label);
                    const tagData = data.tagTypes.map(d => d.count);
                    pieChartInst.data.labels = tagLabels;
                    pieChartInst.data.datasets = [{
                        data: tagData,
                        backgroundColor: ['#10B981', '#2EA8FF', '#8B5CF6', '#F59E0B', '#EF4444', '#EC4899', '#14B8A6'],
                        borderWidth: 0
                    }];
                    pieChartInst.update();

                    // Update Completion Pie Chart
                    completionChartInst.data.labels = ['Tagged', 'Not Tagged'];
                    completionChartInst.data.datasets = [{
                        data: [data.kpis.TotalTagged, data.kpis.TotalUntagged],
                        backgroundColor: ['#10B981', '#EF4444'],
                        borderWidth: 0
                    }];
                    completionChartInst.update();
                    
                    // Update Trend line
                    const trendLabels = data.trend.map(d => d.label);
                    const trendData = data.trend.map(d => d.count);
                    trendChartInst.data.labels = trendLabels;
                    trendChartInst.data.datasets = [{
                        data: trendData,
                        borderColor: '#8B5CF6',
                        backgroundColor: 'rgba(139, 92, 246, 0.2)',
                        fill: true,
                    }];
                    trendChartInst.update();

                    // Update Drilldown
                    const tbody = document.querySelector('#drilldownTable tbody');
                    tbody.innerHTML = '';
                    if(data.drilldown && data.drilldown.length > 0) {
                        data.drilldown.forEach(row => {
                            let tr = document.createElement('tr');
                            tr.innerHTML = `
                                <td>${row.AssetName}</td>
                                <td>${row.Location}</td>
                                <td>${row.TagType}</td>
                                <td>${row.UserId}</td>
                                <td>${row.DateTagged}</td>
                            `;
                            tbody.appendChild(tr);
                        });
                    } else {
                        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding:20px; color:var(--muted);">No tagging data found for this time period.</td></tr>';
                    }

                    const now = new Date();
                    document.getElementById('lastUpdateText').innerText = `Last Updated: ${now.toLocaleTimeString()}`;
                    
                    setTimeout(() => {
                        document.getElementById('loading').style.opacity = '0';
                        document.getElementById('loading').style.pointerEvents = 'none';
                    }, 300);

                    // Schedule next auto-refresh
                    refreshTimer = setTimeout(loadData, autoRefreshMs);
                })
                .catch(err => {
                    console.error("Failed to load data", err);
                    document.getElementById('loading').innerHTML = "Failed to load data. Please refresh the page.";
                });
        }

        // Animated counter
        function animateValue(id, start, end, duration) {
            if (start === end) {
                document.getElementById(id).innerHTML = end.toLocaleString();
                return;
            }
            let range = end - start;
            let current = start;
            let increment = end > start ? Math.ceil(range / (duration/30)) : -1;
            let stepTime = Math.abs(Math.floor(duration / range));
            if(stepTime < 30) stepTime = 30; // cap fast render

            let obj = document.getElementById(id);
            let timer = setInterval(function() {
                current += increment;
                if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
                    current = end;
                    clearInterval(timer);
                }
                obj.innerHTML = current.toLocaleString();
            }, stepTime);
        }
    </script>
</body>
</html>
