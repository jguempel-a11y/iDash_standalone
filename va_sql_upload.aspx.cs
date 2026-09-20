using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Net;

namespace iDash
{
    public partial class va_sql_upload : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // ── Authentication and Role Authorization Guard ──
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn)
            {
                Response.Redirect("index.aspx?err=auth");
                return;
            }

            var tiles = Session["IdashTileAccess"] as List<string>;
            string role = Convert.ToString(Session["IdashUserRole"]);
            if (!UserManager.CanAccessTile(role, tiles, "admin_sql"))
            {
                Response.Redirect("index.aspx?err=access");
                return;
            }

            if (!IsPostBack)
            {
                // Restore grid if in session (e.g. after sort or back nav, though mainly just for postback persistence here)
                if (Session["GridSqlResultsDT"] != null)
                {
                    GridSqlResults.DataSource = Session["GridSqlResultsDT"];
                    GridSqlResults.DataBind();
                }
            }
        }

        private string ConnStr
        {
            get
            {
                var cs = ConfigurationManager.ConnectionStrings["iDash"];
                return (cs == null) ? "" : cs.ConnectionString;
            }
        }

        protected void BtnRunSql_Click(object sender, EventArgs e)
        {
            LitSqlResult.Text = "";
            LitSqlNote.Text = "";

            string sqlText = "";
            string sourceDesc = "";

            if (FileSqlUpload.HasFile)
            {
                sqlText = Encoding.UTF8.GetString(FileSqlUpload.FileBytes);
                sourceDesc = "File: " + FileSqlUpload.FileName + ", Size: " + FileSqlUpload.FileBytes.Length + " bytes";
            }
            else if (!string.IsNullOrWhiteSpace(TxtSqlDirect.Text))
            {
                sqlText = TxtSqlDirect.Text;
                sourceDesc = "Direct Input (" + sqlText.Length + " chars)";
            }
            else
            {
                LitSqlResult.Text = "<div class='err'>Please choose a .sql file or paste SQL script text into the box.</div>";
                return;
            }

            string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
            string clientIp = Request.UserHostAddress;
            try
            {
                var auditType = Type.GetType("LoginAuditHelper");
                if (auditType != null)
                {
                    var m = auditType.GetMethod("LogAdminAction");
                    if (m != null)
                    {
                        m.Invoke(null, new object[] { username, clientIp, "SqlUploadExecute", sourceDesc + ", DangerousAllowed: " + ChkAllowDangerous.Checked });
                    }
                }
            }
            catch { }

            try
            {
                // Safety filter unless checkbox is ticked
                if (!ChkAllowDangerous.Checked)
                {
                    string lowered = sqlText.ToLowerInvariant();
                    if (lowered.Contains("drop ") || lowered.Contains("truncate ") || lowered.Contains("alter "))
                    {
                        LitSqlResult.Text = "<div class='err'>Blocked unsafe command (DROP/TRUNCATE/ALTER detected). Check 'Allow dangerous SQL' to override.</div>";
                        return;
                    }
                }

                // Split into statements by semicolon and strip comments
                var allLines = sqlText.Replace("\r", "").Split('\n');
                var sbStmt = new StringBuilder();
                var stmts = new List<string>();

                foreach (var rawLine in allLines)
                {
                    var line = rawLine;

                    // Skip GO blocks (SQL Server batch separator)
                    if (line.Trim().Equals("GO", StringComparison.OrdinalIgnoreCase))
                        continue;

                    // Strip inline comments
                    int idx = line.IndexOf("--");
                    if (idx >= 0)
                        line = line.Substring(0, idx);

                    if (string.IsNullOrWhiteSpace(line))
                        continue;

                    sbStmt.AppendLine(line);

                    // Statement ends when a semicolon is found at end of line
                    if (line.Trim().EndsWith(";"))
                    {
                        stmts.Add(sbStmt.ToString().Trim().TrimEnd(';').Trim());
                        sbStmt.Clear();
                    }
                }

                // Last statement without a trailing semicolon
                if (sbStmt.Length > 0)
                    stmts.Add(sbStmt.ToString().Trim());

                // Build result table
                var dtLog = new DataTable();
                dtLog.Columns.Add("Statement", typeof(string));
                dtLog.Columns.Add("Result", typeof(string));
                dtLog.Columns.Add("IsError", typeof(bool));

                int totalAffected = 0;

                using (var cn = new SqlConnection(ConnStr))
                {
                    cn.Open();

                    foreach (var s in stmts)
                    {
                        if (string.IsNullOrWhiteSpace(s))
                            continue;

                        try
                        {
                            if (cn.State != ConnectionState.Open)
                            {
                                cn.Open();
                            }

                            using (var cmd = new SqlCommand(s, cn))
                            {
                                cmd.CommandTimeout = 600; // 10 minutes: supports large migrations, backups, and OTA syncs
                                int n = cmd.ExecuteNonQuery();
                                totalAffected += n;
                                dtLog.Rows.Add(s, "✅ Success — rows affected: " + n, false);
                            }
                        }
                        catch (Exception ex2)
                        {
                            dtLog.Rows.Add(s, "❌ Error — " + ex2.Message, true);
                        }
                    }
                }

                // Save full log and prepare capped preview (100)
                Session["SqlUploadLog"] = dtLog;

                var prev = dtLog.Clone();
                int cap = 100;
                int shown = 0;

                foreach (DataRow r in dtLog.Rows)
                {
                    if (shown >= cap) break;
                    prev.ImportRow(r);
                    shown++;
                }

                Session["GridSqlResultsDT"] = prev;
                GridSqlResults.DataSource = prev;
                GridSqlResults.DataBind();

                LitSqlShown.Text = shown.ToString();
                LitSqlTotal.Text = dtLog.Rows.Count.ToString();
                LitSqlNote.Text = (dtLog.Rows.Count > cap)
                    ? "Showing first 100 of " + dtLog.Rows.Count + " statements."
                    : "Showing " + shown + " statement(s).";

                LitSqlResult.Text = "<div>Execution complete. Total rows affected across successful statements: " + totalAffected + ".</div>";
            }
            catch (Exception ex)
            {
                LitSqlResult.Text = "<div class='err'>" + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        protected void BtnSqlExport_Click(object sender, EventArgs e)
        {
            DataTable dt = Session["SqlUploadLog"] as DataTable;
            if (dt == null || dt.Rows.Count == 0)
            {
                LitSqlResult.Text = "<div class='err'>No execution results to export. Run a script first.</div>";
                return;
            }

            var sb = new StringBuilder();
            sb.AppendLine("================================================================================");
            sb.AppendLine(" iDash SQL Script Execution Log");
            sb.AppendLine(" Generated : " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            sb.AppendLine(" Operator  : " + (Session["IdashUsername"] ?? "admin"));
            sb.AppendLine(" Host/IP   : " + Request.UserHostAddress);
            sb.AppendLine(" Total     : " + dt.Rows.Count + " statement(s)");
            sb.AppendLine("================================================================================");
            sb.AppendLine();

            int idx = 1;
            foreach (DataRow r in dt.Rows)
            {
                sb.AppendLine(string.Format("[Statement #{0}]", idx++));
                sb.AppendLine(Convert.ToString(r["Statement"]));
                sb.AppendLine("Status: " + Convert.ToString(r["Result"]));
                sb.AppendLine(new string('-', 60));
                sb.AppendLine();
            }

            string filename = string.Format("SqlExecutionLog_{0:yyyyMMdd_HHmmss}.txt", DateTime.Now);
            DownloadContent(filename, sb.ToString(), "text/plain");
        }

        protected void GridSqlResults_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                var drv = e.Row.DataItem as DataRowView;
                if (drv == null) return;

                bool isErr = false;

                if (drv.DataView.Table.Columns.Contains("IsError"))
                {
                    bool.TryParse(Convert.ToString(drv["IsError"]), out isErr);
                }

                if (isErr)
                {
                    // Red text for error rows
                    e.Row.ForeColor = System.Drawing.Color.FromArgb(0xEF, 0x44, 0x44);
                }
            }
        }

        private void DownloadContent(string fileName, string content, string contentType)
        {
            byte[] bytes = new UTF8Encoding(true).GetBytes(content);
            Response.Clear();
            Response.Buffer = true;
            Response.Charset = "";
            Response.ContentType = contentType;
            Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            Response.BinaryWrite(bytes);
            Response.End();
        }
    }
}
