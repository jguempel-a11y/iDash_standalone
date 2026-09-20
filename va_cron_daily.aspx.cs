using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net.Mail;
using System.Text;
using System.Web.Configuration;

public partial class va_cron_daily : System.Web.UI.Page
{
    private string ConnStr
    {
        get
        {
            var cs = WebConfigurationManager.ConnectionStrings["iDash"];
            return cs != null ? cs.ConnectionString : "";
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "text/plain";
        
        try
        {
            var config = WebConfigurationManager.OpenWebConfiguration("~");
            var settings = config.AppSettings.Settings;

            if (settings["SmsAlertsEnabled"] == null || settings["SmsAlertsEnabled"].Value.ToLower() != "true")
            {
                Response.Write("Automated Reporting is globally disabled in configuration.\n");
                return;
            }

            int reportsSent = 0;

            if (settings["Report_Ennx"] != null && settings["Report_Ennx"].Value.ToLower() == "true")
            {
                if (GenerateAndSendEnnxReport()) reportsSent++;
            }

            if (settings["Report_Stats"] != null && settings["Report_Stats"].Value.ToLower() == "true")
            {
                if (GenerateAndSendStatsReport()) reportsSent++;
            }

            Response.Write(string.Format("Cron Trigger Success. {0} daily reports successfully generated and routed via SMTP.\n", reportsSent));
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write("CRON FAILURE: " + ex.Message + "\n" + ex.StackTrace);
        }
    }

    private bool GenerateAndSendEnnxReport()
    {
        if (string.IsNullOrWhiteSpace(ConnStr)) return false;

        StringBuilder sb = new StringBuilder();
        
        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            string sql = @"
            IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EnnxLiveSession')
            BEGIN
                SELECT EnnxText, Station, CreatedBy, CreatedLocal 
                FROM dbo.EnnxLiveSession 
                WHERE CreatedLocal > DATEADD(day, -1, GETDATE())
                ORDER BY CreatedLocal ASC
            END";

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    string ennxChunk = rdr["EnnxText"].ToString();
                    sb.AppendLine(string.Format("--- SHIFT REPORT: {0} (By: {1}) at {2} ---", rdr["Station"], rdr["CreatedBy"], rdr["CreatedLocal"]));
                    sb.AppendLine(ennxChunk);
                    sb.AppendLine();
                }
            }
        }

        if (sb.Length == 0)
        {
            sb.AppendLine("No ENNX Live Sessions were actively recorded in the system over the last 24 hours.");
        }

        byte[] bytes = Encoding.UTF8.GetBytes(sb.ToString());
        using (var stream = new MemoryStream(bytes))
        {
            var attachment = new Attachment(stream, "Daily_ENNX_Extract_" + DateTime.Now.ToString("yyyyMMdd") + ".txt", "text/plain");
            AlertingService.SendSystemEmail(
                "Daily ENNX Scans Report - " + DateTime.Now.ToShortDateString(),
                "<h3>Automated ENNX Live Session Rollup</h3><p>Please find the aggregated ENNX text exports from the last 24 hours seamlessly attached.</p>",
                "Report_Ennx",
                new List<Attachment> { attachment }
            );
        }
        return true;
    }

    private bool GenerateAndSendStatsReport()
    {
        if (string.IsNullOrWhiteSpace(ConnStr)) return false;

        DataTable dt = new DataTable();
        using (SqlConnection conn = new SqlConnection(ConnStr))
        {
            conn.Open();
            string sql = @"
                SELECT 
                    name AS [Asset Name],
                    description AS [Description],
                    text4 AS [Category],
                    listvalue1 AS [Status],
                    locationname AS [Location],
                    text8 AS [EIL],
                    text7 AS [Station Code],
                    lastinventoried AS [Last Inventoried],
                    lastobservedtime AS [Last Observed],
                    rfidtag AS [RFID Tag]
                FROM dbo.v_asset ORDER BY name";

            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
            {
                da.Fill(dt);
            }
        }

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < dt.Columns.Count; i++)
        {
            sb.Append("\"" + dt.Columns[i].ColumnName + "\"");
            if (i < dt.Columns.Count - 1) sb.Append(",");
        }
        sb.AppendLine();

        foreach (DataRow dr in dt.Rows)
        {
            for (int i = 0; i < dt.Columns.Count; i++)
            {
                string cellVal = dr[i].ToString().Replace("\"", "\"\"");
                sb.Append("\"" + cellVal + "\"");
                if (i < dt.Columns.Count - 1) sb.Append(",");
            }
            sb.AppendLine();
        }

        byte[] bytes = Encoding.UTF8.GetBytes(sb.ToString());
        using (var stream = new MemoryStream(bytes))
        {
            var attachment = new Attachment(stream, "Global_Asset_Stats_" + DateTime.Now.ToString("yyyyMMdd") + ".csv", "text/csv");
            AlertingService.SendSystemEmail(
                "Daily Global Asset Statistics - " + DateTime.Now.ToShortDateString(),
                string.Format("<h3>Automated Global Asset Statistics</h3><p>The system mathematically rolled up all {0} items across all structural locations globally. Please see the attached Excel dataset.</p>", dt.Rows.Count),
                "Report_Stats",
                new List<Attachment> { attachment }
            );
        }
        return true;
    }
}
