using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Net;
using System.Net.NetworkInformation;
using System.Threading.Tasks;
using System.Collections.Concurrent;

namespace iDash
{
    public partial class va_log_viewer : System.Web.UI.Page
    {
        // -- W3SVC folder for the iDash site ------------------------------
        private const string LogDir = @"C:\inetpub\logs\LogFiles\W3SVC1";

        // -- Auth guard ----------------------------------------------------
        private bool IsAuthed
        {
            get { return Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"]; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            PnlLogin.Visible  = !IsAuthed;
            BtnLogout.Visible =  IsAuthed;
            PnlMain.Visible   =  IsAuthed;

            if (!IsAuthed) return;

            if (!IsPostBack)
            {
                PopulateLogFiles();
                PopulateAppFiles();
                LoadCurrentLog();
            }
        }

        // -- Login / Logout ------------------------------------------------
        protected void BtnLogin_Click(object sender, EventArgs e)
        {
            if (TxtUser.Text.Trim() == "idashadmin" && TxtPass.Text.Trim() == "idashadmin")
            {
                Session["IsAdminAuthenticated"] = true;
                Response.Redirect(Request.Url.AbsoluteUri, false);
            }
            else
            {
                LitLoginErr.Text = "<div class='err-msg'>Invalid username or password.</div>";
            }
        }

        protected void BtnLogout_Click(object sender, EventArgs e)
        {
            Session.Remove("IsAdminAuthenticated");
            Response.Redirect(Request.Url.AbsoluteUri, false);
        }

        // -- Populate log file dropdown ------------------------------------
        private void PopulateLogFiles()
        {
            DdlLogFile.Items.Clear();
            try
            {
                if (!Directory.Exists(LogDir))
                {
                    LitMsg.Text = Err("IIS log directory not found: " + LogDir);
                    return;
                }

                var files = Directory.GetFiles(LogDir, "u_ex*.log")
                                     .OrderByDescending(f => f)
                                     .ToArray();

                foreach (var f in files)
                {
                    var fi = new FileInfo(f);
                    DdlLogFile.Items.Add(new ListItem(fi.Name + " (" + FormatSize(fi.Length) + ")", fi.FullName));
                }

                if (DdlLogFile.Items.Count == 0)
                    LitMsg.Text = Err("No IIS log files found in " + LogDir);
            }
            catch (UnauthorizedAccessException ex)
            {
                LitMsg.Text = Err("Access to IIS log directory denied (" + Server.HtmlEncode(ex.Message) + "). IIS AppPool user lacks read permission on " + LogDir);
            }
            catch (Exception ex)
            {
                LitMsg.Text = Err("Error reading IIS log directory: " + Server.HtmlEncode(ex.Message));
            }
        }

        // -- Tab switching -------------------------------------------------
        protected void BtnTabIIS_Click(object sender, EventArgs e)
        {
            HidTab.Value = "iis";
            PnlIIS.Visible = true;
            PnlApp.Visible = false;
            PnlConn.Visible = false;
            PnlAudit.Visible = false;
            BtnTabIIS.CssClass = "tab-btn tab-active";
            BtnTabApp.CssClass = "tab-btn";
            BtnTabConn.CssClass = "tab-btn";
            BtnTabAudit.CssClass = "tab-btn";
            LoadCurrentLog();
        }

        protected void BtnTabApp_Click(object sender, EventArgs e)
        {
            HidTab.Value = "app";
            PnlIIS.Visible = false;
            PnlApp.Visible = true;
            PnlConn.Visible = false;
            PnlAudit.Visible = false;
            BtnTabIIS.CssClass = "tab-btn";
            BtnTabApp.CssClass = "tab-btn tab-active";
            BtnTabConn.CssClass = "tab-btn";
            BtnTabAudit.CssClass = "tab-btn";
            PopulateAppFiles();
            LoadAppLog();
        }

        protected void BtnTabConn_Click(object sender, EventArgs e)
        {
            HidTab.Value = "conn";
            PnlIIS.Visible = false;
            PnlApp.Visible = false;
            PnlConn.Visible = true;
            PnlAudit.Visible = false;
            BtnTabIIS.CssClass = "tab-btn";
            BtnTabApp.CssClass = "tab-btn";
            BtnTabConn.CssClass = "tab-btn tab-active";
            BtnTabAudit.CssClass = "tab-btn";
            LoadConnections();
        }

        protected void BtnTabAudit_Click(object sender, EventArgs e)
        {
            HidTab.Value = "audit";
            PnlIIS.Visible = false;
            PnlApp.Visible = false;
            PnlConn.Visible = false;
            PnlAudit.Visible = true;
            BtnTabIIS.CssClass = "tab-btn";
            BtnTabApp.CssClass = "tab-btn";
            BtnTabConn.CssClass = "tab-btn";
            BtnTabAudit.CssClass = "tab-btn tab-active";
            LoadLoginAudit();
        }

        private void LoadLoginAudit()
        {
            try
            {
                var stats = LoginAuditHelper.GetLoginStats();
                LitAuditLoginsToday.Text = stats.LoginsToday.ToString();
                LitAuditFailures.Text    = stats.FailuresToday.ToString();
                LitAuditUnique.Text      = stats.UniqueUsersThisWeek.ToString();
                LitAuditTotal.Text       = stats.TotalEntries.ToString();

                var entries = LoginAuditHelper.GetRecentLogins(100);
                if (entries.Count == 0)
                {
                    LitAuditTable.Text = "<div style='padding:20px; text-align:center; color:var(--muted);'>No login history recorded yet. Sign-in events will appear here after the next login.</div>";
                    return;
                }

                var sb = new StringBuilder();
                sb.Append("<table class='log' style='width:100%;'><thead><tr>");
                sb.Append("<th>Timestamp</th><th>Username</th><th>IP Address</th><th>Role</th><th>Result</th>");
                sb.Append("</tr></thead><tbody>");
                foreach (var entry in entries)
                {
                    string resultBadge = entry.Success
                        ? "<span style='color:#10b981; font-weight:700;'>&#10003; OK</span>"
                        : "<span style='color:#ef4444; font-weight:700;'>&#10007; FAILED</span>";
                    string roleLabel = string.IsNullOrEmpty(entry.Role) ? "<span style='color:var(--muted);'>\u2014</span>" : Server.HtmlEncode(entry.Role);
                    sb.AppendFormat("<tr><td style='white-space:nowrap;'>{0}</td><td style='font-weight:600;'>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td></tr>",
                        entry.Timestamp.ToString("MM/dd/yyyy hh:mm:ss tt"),
                        Server.HtmlEncode(entry.Username),
                        Server.HtmlEncode(entry.IP),
                        roleLabel,
                        resultBadge);
                }
                sb.Append("</tbody></table>");
                LitAuditTable.Text = sb.ToString();
            }
            catch (Exception ex)
            {
                LitAuditTable.Text = "<div style='color:#ef4444; padding:12px;'>Error loading login audit: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        protected void BtnRefreshConn_Click(object sender, EventArgs e)
        {
            LoadConnections();
        }

        private void LoadConnections()
        {
            try
            {
                var props = IPGlobalProperties.GetIPGlobalProperties();
                var conns = props.GetActiveTcpConnections();

                var filtered = conns.Where(c => c.LocalEndPoint.Port == 80 || c.LocalEndPoint.Port == 443)
                                    .OrderByDescending(c => c.State == TcpState.Established)
                                    .ThenBy(c => c.RemoteEndPoint.Address.ToString())
                                    .ToList();

                var sb = new StringBuilder();
                sb.Append("<table class='log' style='width:100%;'><thead><tr>");
                sb.Append("<th>Local Port</th><th>Remote IP</th><th>Remote Port</th><th>DNS Hostname</th><th>State</th>");
                sb.Append("</tr></thead><tbody>");

                if (filtered.Count == 0)
                {
                    sb.Append("<tr><td colspan='5' class='no-data'>No active connections found on ports 80 or 443.</td></tr>");
                }
                else
                {
                    var ips = filtered.Select(c => c.RemoteEndPoint.Address.ToString()).Distinct().ToList();
                    var hostnames = new ConcurrentDictionary<string, string>();
                    
                    Parallel.ForEach(ips, new ParallelOptions { MaxDegreeOfParallelism = 10 }, ip => {
                        try {
                            if (ip == "127.0.0.1" || ip == "::1") {
                                hostnames[ip] = "localhost";
                                return;
                            }
                            var entry = Dns.GetHostEntry(ip);
                            hostnames[ip] = string.IsNullOrEmpty(entry.HostName) ? "Unknown" : entry.HostName;
                        } catch { hostnames[ip] = "Unknown (No PTR)"; }
                    });

                    foreach (var c in filtered)
                    {
                        string ip = c.RemoteEndPoint.Address.ToString();
                        string host = hostnames.ContainsKey(ip) ? hostnames[ip] : "Unknown";
                        
                        string stateColor = c.State == TcpState.Established ? "var(--accent-2)" : 
                                            (c.State == TcpState.TimeWait || c.State == TcpState.CloseWait ? "var(--warn)" : "var(--text)");

                        sb.AppendFormat("<tr>" +
                            "<td>{0}</td>" +
                            "<td><span class='ip-pill'>{1}</span></td>" +
                            "<td>{2}</td>" +
                            "<td style='color:var(--muted)'>{3}</td>" +
                            "<td style='color:{4};font-weight:600;'>{5}</td>" +
                            "</tr>",
                            c.LocalEndPoint.Port,
                            ip,
                            c.RemoteEndPoint.Port,
                            HttpUtility.HtmlEncode(host),
                            stateColor,
                            c.State.ToString()
                        );
                    }
                }
                sb.Append("</tbody></table>");
                LitConnTable.Text = sb.ToString();
            }
            catch (Exception ex)
            {
                LitConnTable.Text = Err("Error reading connections: " + ex.Message);
            }
        }

        // -- Event handlers ------------------------------------------------
        protected void DdlLogFile_Changed(object sender, EventArgs e)
        {
            HidPage.Value = "0";
            LoadCurrentLog();
        }

        protected void BtnApply_Click(object sender, EventArgs e)
        {
            HidPage.Value = "0";
            LoadCurrentLog();
        }

        protected void BtnPrev_Click(object sender, EventArgs e)
        {
            int p = int.Parse(HidPage.Value);
            if (p > 0) { HidPage.Value = (p - 1).ToString(); LoadCurrentLog(); }
        }

        protected void BtnNext_Click(object sender, EventArgs e)
        {
            int p = int.Parse(HidPage.Value);
            HidPage.Value = (p + 1).ToString();
            LoadCurrentLog();
        }

        protected void DdlAppFile_Changed(object sender, EventArgs e)
        {
            HidAppPage.Value = "0";
            LoadAppLog();
        }

        protected void BtnAppApply_Click(object sender, EventArgs e)
        {
            HidAppPage.Value = "0";
            LoadAppLog();
        }

        protected void BtnAppPrev_Click(object sender, EventArgs e)
        {
            int p = int.Parse(HidAppPage.Value);
            if (p > 0) { HidAppPage.Value = (p - 1).ToString(); LoadAppLog(); }
        }

        protected void BtnAppNext_Click(object sender, EventArgs e)
        {
            int p = int.Parse(HidAppPage.Value);
            HidAppPage.Value = (p + 1).ToString();
            LoadAppLog();
        }

        protected void BtnExport_Click(object sender, EventArgs e)
        {
            var rows = ParseLog(DdlLogFile.SelectedValue, true, 0);
            if (rows == null || rows.Count == 0) { LitMsg.Text = Err("No data to export."); return; }

            var sb = new StringBuilder();
            sb.AppendLine("Date,Time,ClientIP,Method,URI,Query,Status,SubStatus,TimeTaken_ms,BytesSent,Port");
            foreach (var r in rows)
            {
                sb.AppendLine(string.Join(",",
                    new string[] {
                        Q(r.Date), Q(r.Time), Q(r.ClientIp), Q(r.Method),
                        Q(r.UriStem), Q(r.UriQuery), r.Status.ToString(),
                        r.SubStatus.ToString(), r.TimeTaken.ToString(),
                        r.BytesSent.ToString(), r.Port.ToString()
                    }));
            }

            byte[] bytes = new UTF8Encoding(true).GetBytes(sb.ToString());
            Response.Clear();
            Response.Buffer = true;
            Response.ContentType = "text/csv";
            string fn = "iis-log-" + DateTime.Now.ToString("yyyyMMdd-HHmm") + ".csv";
            Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fn + "\"");
            Response.BinaryWrite(bytes);
            try { Response.Flush(); Response.Close(); } catch { }
        }

        // -- Main load -----------------------------------------------------
        private void LoadCurrentLog()
        {
            if (DdlLogFile.Items.Count == 0) return;
            string path = DdlLogFile.SelectedValue;
            if (!File.Exists(path)) { LitMsg.Text = Err("File not found: " + path); return; }

            int pageSize = int.Parse(DdlPageSize.SelectedValue);
            int page     = int.Parse(HidPage.Value);

            var all      = ParseLog(path, false, 0);
            var filtered = ParseLog(path, true,  0);

            int total     = filtered.Count;
            int pageCount = (int)Math.Ceiling(total / (double)pageSize);
            if (page >= pageCount && pageCount > 0) { page = pageCount - 1; HidPage.Value = page.ToString(); }

            var paged = filtered.Skip(page * pageSize).Take(pageSize).ToList();

            RenderKPIs(all);
            RenderCharts(all);

            LitPageInfo.Text = string.Format("Showing {0}&#x2013;{1} of {2:N0} &nbsp;({3:N0} total in file)",
                page * pageSize + 1, Math.Min((page + 1) * pageSize, total), total, all.Count);

            BtnPrev.Enabled = (page > 0);
            BtnNext.Enabled = (page < pageCount - 1);

            LitTable.Text = BuildTable(paged);
        }

        // -- Parse IIS W3C log ---------------------------------------------
        // fieldMap: dictionary from field name -> column index (built from #Fields line)
        private List<LogEntry> ParseLog(string path, bool applyFilters, int skip)
        {
            var result = new List<LogEntry>();
            if (!File.Exists(path)) return result;

            // Field indices — filled when we hit #Fields line
            int fDate=-1, fTime=-1, fCip=-1, fMethod=-1, fStem=-1, fQuery=-1,
                fStatus=-1, fSub=-1, fTaken=-1, fBytes=-1, fPort=-1, fUA=-1;
            bool fieldsFound = false;

            string uriF    = applyFilters ? TxtUriFilter.Text.Trim().ToLower()  : "";
            string ipF     = applyFilters ? TxtIpFilter.Text.Trim()             : "";
            string methodF = applyFilters ? DdlMethod.SelectedValue             : "";
            string statusF = applyFilters ? DdlStatus.SelectedValue             : "";

            try
            {
                foreach (var line in File.ReadLines(path, Encoding.UTF8))
                {
                    if (line.StartsWith("#Fields:"))
                    {
                        var parts = line.Substring(9).Trim().Split(' ');
                        for (int i = 0; i < parts.Length; i++)
                        {
                            switch (parts[i])
                            {
                                case "date":           fDate   = i; break;
                                case "time":           fTime   = i; break;
                                case "c-ip":           fCip    = i; break;
                                case "cs-method":      fMethod = i; break;
                                case "cs-uri-stem":    fStem   = i; break;
                                case "cs-uri-query":   fQuery  = i; break;
                                case "sc-status":      fStatus = i; break;
                                case "sc-substatus":   fSub    = i; break;
                                case "time-taken":     fTaken  = i; break;
                                case "sc-bytes":       fBytes  = i; break;
                                case "s-port":         fPort   = i; break;
                                case "cs(User-Agent)": fUA     = i; break;
                            }
                        }
                        fieldsFound = true;
                        continue;
                    }
                    if (line.StartsWith("#") || !fieldsFound) continue;

                    var cols = line.Split(' ');
                    if (cols.Length < 8) continue;

                    var entry = new LogEntry();
                    entry.Date      = Col(cols, fDate);
                    entry.Time      = Col(cols, fTime);
                    entry.ClientIp  = Col(cols, fCip);
                    entry.Method    = Col(cols, fMethod);
                    entry.UriStem   = Col(cols, fStem);
                    entry.UriQuery  = Col(cols, fQuery);
                    entry.UserAgent = Col(cols, fUA);
                    entry.Status    = ColInt(cols, fStatus);
                    entry.SubStatus = ColInt(cols, fSub);
                    entry.TimeTaken = ColInt(cols, fTaken);
                    entry.BytesSent = ColLong(cols, fBytes);
                    entry.Port      = ColInt(cols, fPort);

                    if (applyFilters)
                    {
                        if (!string.IsNullOrEmpty(uriF)    && entry.UriStem.ToLower().IndexOf(uriF) < 0) continue;
                        if (!string.IsNullOrEmpty(ipF)     && entry.ClientIp.IndexOf(ipF) < 0)          continue;
                        if (!string.IsNullOrEmpty(methodF) && entry.Method != methodF)                   continue;
                        if (!string.IsNullOrEmpty(statusF) && !entry.Status.ToString().StartsWith(statusF)) continue;
                    }

                    result.Add(entry);
                }
            }
            catch (IOException) { /* IIS may have file open — return partial */ }

            return result;
        }

        // -- KPI rendering -------------------------------------------------
        private void RenderKPIs(List<LogEntry> all)
        {
            int t2  = all.Count(r => r.Status >= 200 && r.Status < 300);
            int t3  = all.Count(r => r.Status >= 300 && r.Status < 400);
            int t45 = all.Count(r => r.Status >= 400);
            int uip = all.Select(r => r.ClientIp).Distinct().Count();
            double avg  = all.Count > 0 ? all.Average(r => (double)r.TimeTaken) : 0;
            double mb   = all.Sum(r => r.BytesSent) / 1024.0 / 1024.0;

            LitTotalReqs.Text  = all.Count.ToString("N0");
            LitOkReqs.Text     = t2.ToString("N0");
            LitRedReqs.Text    = t3.ToString("N0");
            LitErrReqs.Text    = t45.ToString("N0");
            LitUniqIPs.Text    = uip.ToString("N0");
            LitAvgTime.Text    = avg.ToString("F0");
            LitTotalBytes.Text = mb.ToString("F1");
        }

        // -- Chart rendering -----------------------------------------------
        private void RenderCharts(List<LogEntry> all)
        {
            // Top pages
            var topPages = all.GroupBy(r => r.UriStem)
                              .OrderByDescending(g => g.Count())
                              .Take(8).ToList();
            int maxP = topPages.Count > 0 ? topPages[0].Count() : 1;
            var sbP = new StringBuilder();
            foreach (var g in topPages)
            {
                int pct = (int)(g.Count() * 100.0 / maxP);
                string key = g.Key ?? "";
                string lbl = key.Length > 32 ? "\u2026" + key.Substring(key.Length - 30) : key;
                sbP.AppendFormat(
                    "<div class='bar-item'><span class='bar-lbl' title='{0}'>{1}</span>" +
                    "<span class='bar-track'><span class='bar-fill' style='width:{2}%'></span></span>" +
                    "<span class='bar-num'>{3:N0}</span></div>",
                    HttpUtility.HtmlAttributeEncode(key), HttpUtility.HtmlEncode(lbl), pct, g.Count());
            }
            LitTopPages.Text = sbP.ToString();

            // Top IPs (exclude loopback)
            var topIPs = all.Where(r => r.ClientIp != "::1" && r.ClientIp != "127.0.0.1")
                            .GroupBy(r => r.ClientIp)
                            .OrderByDescending(g => g.Count())
                            .Take(8).ToList();
            int maxI = topIPs.Count > 0 ? topIPs[0].Count() : 1;
            var sbI = new StringBuilder();
            foreach (var g in topIPs)
            {
                int pct = (int)(g.Count() * 100.0 / maxI);
                sbI.AppendFormat(
                    "<div class='bar-item'><span class='bar-lbl'>{0}</span>" +
                    "<span class='bar-track'><span class='bar-fill' style='width:{1}%;background:#a78bfa'></span></span>" +
                    "<span class='bar-num'>{2:N0}</span></div>",
                    HttpUtility.HtmlEncode(g.Key), pct, g.Count());
            }
            LitTopIPs.Text = sbI.ToString();

            // Status breakdown
            var statGrps = all.GroupBy(r => (r.Status / 100) * 100)
                              .OrderBy(g => g.Key).ToList();
            int maxS = statGrps.Count > 0 ? statGrps.Max(g => g.Count()) : 1;
            var colors = new Dictionary<int, string> {
                {200,"var(--accent2)"},{300,"#f59e0b"},{400,"var(--danger)"},{500,"#f87171"}
            };
            var sbS = new StringBuilder();
            foreach (var g in statGrps)
            {
                int pct = (int)(g.Count() * 100.0 / maxS);
                string color = colors.ContainsKey(g.Key) ? colors[g.Key] : "var(--accent)";
                sbS.AppendFormat(
                    "<div class='bar-item'><span class='bar-lbl'>{0}xx</span>" +
                    "<span class='bar-track'><span class='bar-fill' style='width:{1}%;background:{2}'></span></span>" +
                    "<span class='bar-num'>{3:N0}</span></div>",
                    g.Key / 100, pct, color, g.Count());
            }
            LitStatusBreak.Text = sbS.ToString();
        }

        // -- Table HTML ----------------------------------------------------
        private string BuildTable(List<LogEntry> rows)
        {
            if (rows.Count == 0)
                return "<div class='no-data'>&#128269; No log entries match your filters.</div>";

            var sb = new StringBuilder();
            sb.Append("<table class='log'><thead><tr>");
            foreach (var h in new[] { "Date","Time","Client IP","Method","URI","Query","Status","Sub","ms","Bytes","Browser" })
                sb.AppendFormat("<th>{0}</th>", h);
            sb.Append("</tr></thead><tbody>");

            foreach (var r in rows)
            {
                string sCls  = r.Status >= 500 ? "s5" : r.Status >= 400 ? "s4" : r.Status >= 300 ? "s3" : "s2";
                string mCls  = "m" + r.Method;
                string uri   = HttpUtility.HtmlEncode(r.UriStem ?? "");
                string query = (r.UriQuery == "-" || r.UriQuery == null) ? "" : HttpUtility.HtmlEncode(r.UriQuery);
                string ua    = FriendlyAgent(r.UserAgent);
                string msStyle = r.TimeTaken > 10000 ? " style='color:var(--danger)'"
                               : r.TimeTaken > 5000  ? " style='color:#f59e0b'" : "";

                sb.AppendFormat(
                    "<tr>" +
                    "<td style='color:var(--muted)'>{0}</td>" +
                    "<td style='color:var(--muted)'>{1}</td>" +
                    "<td><span class='ip-pill'>{2}</span></td>" +
                    "<td class='{3}'>{4}</td>" +
                    "<td style='max-width:280px;overflow:hidden;text-overflow:ellipsis;' title='{5}'>{5}</td>" +
                    "<td style='color:var(--muted);max-width:180px;overflow:hidden;text-overflow:ellipsis;'>{6}</td>" +
                    "<td class='{7}'><strong>{8}</strong></td>" +
                    "<td style='color:var(--muted)'>{9}</td>" +
                    "<td{10}>{11}</td>" +
                    "<td style='color:var(--muted)'>{12}</td>" +
                    "<td style='color:var(--muted);font-size:11px;'>{13}</td>" +
                    "</tr>",
                    r.Date, r.Time,
                    HttpUtility.HtmlEncode(r.ClientIp ?? ""),
                    mCls, HttpUtility.HtmlEncode(r.Method ?? ""),
                    uri, query,
                    sCls, r.Status, r.SubStatus,
                    msStyle, r.TimeTaken.ToString("N0"),
                    r.BytesSent.ToString("N0"),
                    HttpUtility.HtmlEncode(ua));
            }

            sb.Append("</tbody></table>");
            return sb.ToString();
        }

        // -- Helpers -------------------------------------------------------
        private static string Col(string[] cols, int idx)
        {
            return (idx >= 0 && idx < cols.Length) ? cols[idx] : "";
        }
        private static int ColInt(string[] cols, int idx)
        {
            int v; int.TryParse(Col(cols, idx), out v); return v;
        }
        private static long ColLong(string[] cols, int idx)
        {
            long v; long.TryParse(Col(cols, idx), out v); return v;
        }

        private static string FriendlyAgent(string ua)
        {
            if (string.IsNullOrEmpty(ua) || ua == "-") return "";
            if (ua.Contains("Edg/"))    return "Edge";
            if (ua.Contains("Chrome"))  return "Chrome";
            if (ua.Contains("Firefox")) return "Firefox";
            if (ua.Contains("Safari"))  return "Safari";
            if (ua.Contains("curl"))    return "curl";
            return ua.Length > 36 ? ua.Substring(0, 33) + "\u2026" : ua;
        }

        private static string FormatSize(long bytes)
        {
            if (bytes > 1024 * 1024) return (bytes / 1048576.0).ToString("F1") + " MB";
            if (bytes > 1024)        return (bytes / 1024.0).ToString("F0") + " KB";
            return bytes + " B";
        }

        private static string Q(string s)
        {
            return "\"" + (s ?? "").Replace("\"", "\"\"") + "\"";
        }

        private static string Err(string msg)
        {
            return "<div style='background:#3b0d0d;border:1px solid #7f1d1d;color:#fecaca;" +
                   "padding:10px 16px;border-radius:6px;margin-bottom:14px;'>" +
                   HttpUtility.HtmlEncode(msg) + "</div>";
        }

        // -------------------------------------------------------------------
        //  APP LOGS (Serilog / C:\logs\)
        // -------------------------------------------------------------------
        private const string AppLogDir = @"C:\logs";

        private void PopulateAppFiles()
        {
            if (DdlAppFile.Items.Count > 0) return; // already populated
            DdlAppFile.Items.Clear();
            if (!Directory.Exists(AppLogDir))
            {
                LitAppDiag.Text = Err("App log directory not found: " + AppLogDir);
                return;
            }
            var files = Directory.GetFiles(AppLogDir, "*.txt")
                                 .Concat(Directory.GetFiles(AppLogDir, "*.log"))
                                 .OrderByDescending(f => f)
                                 .ToArray();
            foreach (var f in files)
            {
                var fi = new FileInfo(f);
                DdlAppFile.Items.Add(new ListItem(fi.Name + " (" + FormatSize(fi.Length) + ")", fi.FullName));
            }
            if (DdlAppFile.Items.Count == 0)
                LitAppDiag.Text = Err("No log files found in " + AppLogDir);
        }

        // -- Serilog entry model -------------------------------------------
        private class AppEntry
        {
            public string Timestamp;
            public string Level;       // ERR / WRN / INF / DBG / VRB
            public string Message;     // first line of message
            public string StackTrace;  // continuation lines
        }

        // -- Parse Serilog text file ---------------------------------------
        // Serilog compact text format: "2026-04-15 11:27:15.492 -04:00 [ERR] message..."
        private List<AppEntry> ParseAppLog(string path, bool applyFilters)
        {
            var result = new List<AppEntry>();
            if (!File.Exists(path)) return result;

            string levelF   = applyFilters ? DdlAppLevel.SelectedValue   : "";
            string kw       = applyFilters ? TxtAppKeyword.Text.Trim().ToLower() : "";

            try
            {
                var lines = File.ReadAllLines(path, Encoding.UTF8);
                AppEntry current = null;
                var stackLines  = new StringBuilder();

                Action flush = () =>
                {
                    if (current == null) return;
                    current.StackTrace = stackLines.ToString().TrimEnd();
                    stackLines.Clear();

                    if (applyFilters)
                    {
                        if (!string.IsNullOrEmpty(levelF) && current.Level != levelF) { current = null; return; }
                        if (!string.IsNullOrEmpty(kw))
                        {
                            bool hit = current.Message.ToLower().Contains(kw) ||
                                       current.StackTrace.ToLower().Contains(kw);
                            if (!hit) { current = null; return; }
                        }
                    }
                    result.Add(current);
                    current = null;
                };

                foreach (var raw in lines)
                {
                    // Check if this line starts a new log entry
                    // Pattern: YYYY-MM-DD HH:MM:SS.mmm ±HH:mm [LVL]
                    if (raw.Length > 30 &&
                        raw[4] == '-' && raw[7] == '-' && raw[10] == ' ' &&
                        raw[13] == ':' && raw[16] == ':' &&
                        raw.Contains(" [ERR]") | raw.Contains(" [WRN]") |
                        raw.Contains(" [INF]") | raw.Contains(" [DBG]") |
                        raw.Contains(" [VRB]") | raw.Contains(" [FTL]"))
                    {
                        flush();
                        // Extract level
                        int lb = raw.IndexOf('[');
                        int rb = raw.IndexOf(']', lb > 0 ? lb : 0);
                        string lvl = (lb >= 0 && rb > lb)
                            ? raw.Substring(lb + 1, rb - lb - 1).Trim().ToUpper()
                            : "INF";
                        string ts  = raw.Substring(0, lb > 0 ? lb - 1 : 26).Trim();
                        string msg = (rb > 0 && rb + 2 < raw.Length)
                            ? raw.Substring(rb + 2).Trim()
                            : "";

                        current = new AppEntry { Timestamp = ts, Level = lvl, Message = msg };
                    }
                    else if (current != null)
                    {
                        // Continuation / stack trace line
                        stackLines.AppendLine(raw);
                    }
                }
                flush();
            }
            catch (IOException) { /* partial read ok */ }

            return result;
        }

        // -- Load + render app log -----------------------------------------
        private void LoadAppLog()
        {
            PopulateAppFiles();
            if (DdlAppFile.Items.Count == 0) return;
            string path = DdlAppFile.SelectedValue;
            if (!File.Exists(path)) { LitAppDiag.Text = Err("File not found: " + path); return; }

            var all      = ParseAppLog(path, false);
            var filtered = ParseAppLog(path, true);

            // Optionally deduplicate by message
            if (DdlAppDedup.SelectedValue == "1")
                filtered = filtered.GroupBy(e => e.Message)
                                   .Select(g => g.First())
                                   .ToList();

            int pageSize = int.Parse(DdlAppPageSize.SelectedValue);
            int page     = int.Parse(HidAppPage.Value);
            int total    = filtered.Count;
            int pageCount = (int)Math.Ceiling(total / (double)pageSize);
            if (page >= pageCount && pageCount > 0) { page = pageCount - 1; HidAppPage.Value = page.ToString(); }

            var paged = filtered.Skip(page * pageSize).Take(pageSize).ToList();

            RenderAppKPIs(all);
            RenderAppCharts(all);
            RenderAppDiagnosis(all);

            LitAppPageInfo.Text = string.Format(
                "Showing {0}&#x2013;{1} of {2:N0}&nbsp;({3:N0} total in file)",
                page * pageSize + 1, Math.Min((page + 1) * pageSize, total), total, all.Count);

            BtnAppPrev.Enabled = (page > 0);
            BtnAppNext.Enabled = (page < pageCount - 1);

            LitAppTable.Text = BuildAppTable(paged);
        }

        // -- App KPIs ------------------------------------------------------
        private void RenderAppKPIs(List<AppEntry> all)
        {
            int err  = all.Count(e => e.Level == "ERR" || e.Level == "FTL");
            int wrn  = all.Count(e => e.Level == "WRN");
            int inf  = all.Count(e => e.Level == "INF");
            int uniq = all.Select(e => e.Message).Distinct().Count();
            int spam = all.Count(e => e.Level == "ERR" || e.Level == "FTL") > 0
                ? all.GroupBy(e => e.Message).Max(g => g.Count()) : 0;

            LitAppTotal.Text = all.Count.ToString("N0");
            LitAppErr.Text   = err.ToString("N0");
            LitAppWrn.Text   = wrn.ToString("N0");
            LitAppInf.Text   = inf.ToString("N0");
            LitAppUniq.Text  = uniq.ToString("N0");
            LitAppSpam.Text  = spam.ToString("N0");
        }

        // -- App Charts ----------------------------------------------------
        private void RenderAppCharts(List<AppEntry> all)
        {
            // Top recurring errors/warnings
            var topErrs = all.Where(e => e.Level == "ERR" || e.Level == "WRN" || e.Level == "FTL")
                             .GroupBy(e => TruncMsg(e.Message, 80))
                             .OrderByDescending(g => g.Count())
                             .Take(8).ToList();
            int maxE = topErrs.Count > 0 ? topErrs[0].Count() : 1;
            var sbE = new StringBuilder();
            foreach (var g in topErrs)
            {
                int pct = (int)(g.Count() * 100.0 / maxE);
                string color = "var(--danger)";
                sbE.AppendFormat(
                    "<div class='bar-item'>" +
                    "<span class='bar-lbl' title='{0}' style='width:180px;'>{1}</span>" +
                    "<span class='bar-track'><span class='bar-fill' style='width:{2}%;background:{3}'></span></span>" +
                    "<span class='bar-num'>{4:N0}&#215;</span></div>",
                    HttpUtility.HtmlAttributeEncode(g.Key),
                    HttpUtility.HtmlEncode(TruncMsg(g.Key, 45)),
                    pct, color, g.Count());
            }
            LitAppTopErr.Text = sbE.Length > 0 ? sbE.ToString() : "<div style='color:var(--accent2);font-size:13px;'>No errors found &#10003;</div>";

            // Level breakdown
            var levels = new[] { "FTL", "ERR", "WRN", "INF", "DBG", "VRB" };
            var levelColors = new Dictionary<string, string> {
                {"FTL","#f87171"},{"ERR","var(--danger)"},{"WRN","#f59e0b"},
                {"INF","var(--accent2)"},{"DBG","#a78bfa"},{"VRB","var(--muted)"}
            };
            var sbL = new StringBuilder();
            int maxL = levels.Select(l => all.Count(e => e.Level == l)).DefaultIfEmpty(1).Max();
            foreach (var lvl in levels)
            {
                int cnt = all.Count(e => e.Level == lvl);
                if (cnt == 0) continue;
                int pct = (int)(cnt * 100.0 / Math.Max(maxL, 1));
                string col = levelColors.ContainsKey(lvl) ? levelColors[lvl] : "var(--accent)";
                sbL.AppendFormat(
                    "<div class='bar-item'><span class='bar-lbl'>[{0}]</span>" +
                    "<span class='bar-track'><span class='bar-fill' style='width:{1}%;background:{2}'></span></span>" +
                    "<span class='bar-num'>{3:N0}</span></div>",
                    lvl, pct, col, cnt);
            }
            LitAppLevels.Text = sbL.ToString();
        }

        // -- App Diagnosis Banner ------------------------------------------
        private void RenderAppDiagnosis(List<AppEntry> all)
        {
            var findings = new List<string>();

            // OpenID / token failures
            int oidcFails = all.Count(e =>
                e.Message.Contains("GetTokenEndpoint") ||
                e.Message.Contains("openid-configuration") ||
                e.Message.Contains("Unable to acquire authentication token"));
            if (oidcFails > 0)
                findings.Add(string.Format(
                    "<strong>&#9888; Authentication Failure (&times;{0})</strong>: The service cannot reach the OpenID Connect discovery endpoint at " +
                    "<code>http://localhost/.well-known/openid-configuration</code>. " +
                    "<strong>Root cause:</strong> The iDash API at <code>http://localhost/</code> is not running or not reachable. " +
                    "Start the iDash site in IIS.", oidcFails));

            // Startup errors
            int startErrs = all.Count(e => e.Message.Contains("Starting application") && e.Level == "ERR");
            if (startErrs > 0)
                findings.Add("<strong>&#8505; Startup Logged as ERR</strong>: Application startup messages are being emitted at ERROR level &mdash; verify the Serilog minimum level configuration.");

            // Repeated identical errors (spam detection)
            var spam = all.Where(e => e.Level == "ERR" || e.Level == "FTL")
                          .GroupBy(e => TruncMsg(e.Message, 80))
                          .Where(g => g.Count() >= 5)
                          .OrderByDescending(g => g.Count())
                          .FirstOrDefault();
            if (spam != null)
                findings.Add(string.Format(
                    "<strong>&#128293; High-Frequency Error (&times;{0})</strong>: &ldquo;{1}&rdquo; &mdash; this error is repeating every few seconds. Fix the root cause to stop log flooding.",
                    spam.Count(), HttpUtility.HtmlEncode(TruncMsg(spam.Key, 90))));

            if (findings.Count == 0)
            {
                LitAppDiag.Text = "";
                return;
            }

            var sb = new StringBuilder();
            sb.Append("<div class='diag-banner'>");
            sb.Append("<h3>&#127269; Auto-Diagnosis</h3><ul>");
            foreach (var f in findings)
                sb.AppendFormat("<li>{0}</li>", f);
            sb.Append("</ul></div>");
            LitAppDiag.Text = sb.ToString();
        }

        // -- Build App table HTML ------------------------------------------
        private string BuildAppTable(List<AppEntry> rows)
        {
            if (rows.Count == 0)
                return "<div class='no-data'>&#128269; No log entries match your filters.</div>";

            bool hideStack = DdlAppStack.SelectedValue == "hide";
            var sb = new StringBuilder();
            sb.Append("<table class='log'><thead><tr>");
            foreach (var h in new[] { "Timestamp", "Level", "Message / Stack" })
                sb.AppendFormat("<th>{0}</th>", h);
            sb.Append("</tr></thead><tbody>");

            foreach (var r in rows)
            {
                string lvlCls = "lvl-" + r.Level.ToLower();
                if (r.Level == "FTL") lvlCls = "lvl-err";
                if (r.Level == "VRB") lvlCls = "lvl-dbg";

                bool hasStack = !string.IsNullOrWhiteSpace(r.StackTrace);
                string msgHtml = "<div class='app-msg'>" + HttpUtility.HtmlEncode(r.Message) + "</div>";
                if (hasStack && !hideStack)
                    msgHtml += "<div class='app-stack'>" + HttpUtility.HtmlEncode(r.StackTrace) + "</div>";

                string rowBg = (r.Level == "ERR" || r.Level == "FTL")
                    ? " style='background:rgba(239,68,68,0.06);'"
                    : (r.Level == "WRN" ? " style='background:rgba(245,158,11,0.05);'" : "");

                sb.AppendFormat(
                    "<tr{0}>" +
                    "<td style='color:var(--muted);white-space:nowrap;vertical-align:top;'>{1}</td>" +
                    "<td style='vertical-align:top;'><span class='{2}'>{3}</span></td>" +
                    "<td>{4}</td>" +
                    "</tr>",
                    rowBg,
                    HttpUtility.HtmlEncode(r.Timestamp),
                    lvlCls, HttpUtility.HtmlEncode(r.Level),
                    msgHtml);
            }
            sb.Append("</tbody></table>");
            return sb.ToString();
        }

        private static string TruncMsg(string s, int maxLen)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Length > maxLen ? s.Substring(0, maxLen) + "\u2026" : s;
        }

        // -- Data model ----------------------------------------------------
        private class LogEntry
        {
            public string Date;
            public string Time;
            public string ClientIp;
            public string Method;
            public string UriStem;
            public string UriQuery;
            public string UserAgent;
            public int    Status;
            public int    SubStatus;
            public int    TimeTaken;
            public long   BytesSent;
            public int    Port;
        }
    }
}
