using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.IO;
using System.Text;
using System.Web;

/// <summary>
/// Service layer for Live Scan logic.
/// encapsulated to be used by API handlers or Pages.
/// </summary>
public static class LiveScanService
{
    private static string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return cs == null ? "" : cs.ConnectionString;
        }
    }

    private static string SaveFolderDisk
    {
        get { return @"C:\VA_RFID\ennx_live\saved"; }
    }

    public class SaveResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public int SessionId { get; set; }
        public string FilePath { get; set; }
    }

    public static SaveResult SaveSession(string station, string user, string startedUtc, string endedUtc, string summary, string json, string ennx)
    {
        var result = new SaveResult();

        // 1. Try SQL Save
        try
        {
            result.SessionId = TryInsertSessionToSql(station, user, startedUtc, endedUtc, summary, json, ennx);
            if (result.SessionId > 0)
            {
                result.Success = true;
                result.Message = "Saved to SQL (ID: " + result.SessionId + ")";
            }
        }
        catch (Exception ex)
        {
            // Log error? For now just return it
            result.Message = "SQL Save Failed: " + ex.Message;
        }

        // 2. Always Save to Disk (Backup / Primary if SQL fails)
        try
        {
            Directory.CreateDirectory(SaveFolderDisk);
            string safeStation = string.IsNullOrWhiteSpace(station) ? "site" : station;
            string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string filename = string.Format("ennx_live_{0}_{1}.ennx.txt", safeStation, stamp);
            string path = Path.Combine(SaveFolderDisk, filename);

            File.WriteAllText(path, ennx, Encoding.UTF8);
            result.FilePath = path;

            if (!result.Success) // If SQL didn't work, mark as success because Disk worked
            {
                result.Success = true;
                result.Message = "Saved to Disk: " + filename;
            }
            else
            {
                result.Message += " + Disk Backup";
            }
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Message += " | Disk Save Failed: " + ex.Message;
        }

        return result;
    }

    private static int TryInsertSessionToSql(string station, string createdBy, string startedUtc, string endedUtc,
                                      string summary, string jsonPayload, string ennxText)
    {
        if (string.IsNullOrWhiteSpace(ConnStr)) return 0;

        using (var con = new SqlConnection(ConnStr))
        {
            con.Open();

            // Check table exists logic
            // Simplified: Just try catch the insert. If table missing, it fails.
            // But we can do a quick check if desired. 
            // For improved performance in API, better to just try.
            
            try 
            {
                using (var cmd = new SqlCommand(@"
                    IF OBJECT_ID('dbo.EnnxLiveSession', 'U') IS NOT NULL
                    BEGIN
                        INSERT INTO dbo.EnnxLiveSession
                        (Station, CreatedBy, StartedUtc, EndedUtc, Summary, JsonPayload, EnnxText, CreatedLocal)
                        OUTPUT INSERTED.SessionId
                        VALUES
                        (@Station, @CreatedBy, @StartedUtc, @EndedUtc, @Summary, @JsonPayload, @EnnxText, GETDATE())
                    END", con))
                {
                    cmd.Parameters.AddWithValue("@Station", (object)station ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@CreatedBy", (object)createdBy ?? DBNull.Value);

                    DateTime dtStart, dtEnd;
                    object oStart = DateTime.TryParse(startedUtc, out dtStart) ? (object)dtStart : (object)startedUtc;
                    object oEnd = DateTime.TryParse(endedUtc, out dtEnd) ? (object)dtEnd : (object)endedUtc;

                    cmd.Parameters.AddWithValue("@StartedUtc", oStart);
                    cmd.Parameters.AddWithValue("@EndedUtc", oEnd);
                    cmd.Parameters.AddWithValue("@Summary", (object)summary ?? "");
                    cmd.Parameters.AddWithValue("@JsonPayload", (object)jsonPayload ?? "");
                    cmd.Parameters.AddWithValue("@EnnxText", (object)ennxText ?? "");

                    object id = cmd.ExecuteScalar();
                    int sessionId;
                    if (id != null && int.TryParse(id.ToString(), out sessionId))
                        return sessionId;
                }
            }
            catch
            {
                // Table doesn't exist or other SQL error
                return 0;
            }
        }
        return 0;
    }
}
