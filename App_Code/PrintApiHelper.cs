using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Text;
using System.Web.Script.Serialization;

/// <summary>
/// Shared helper for submitting print jobs from iDash.
/// 
/// Calls POST /api/printjob/print — the endpoint that both creates
/// the DB row AND publishes the full MQTT payload to the Print Server.
///
/// Multi-site support: Each site (company) has its own clientapp entry
/// (idash_540, idash_517, etc.) so the API token carries the correct
/// cmpid claim. The helper selects credentials based on the user's company.
/// </summary>
public static class PrintApiHelper
{
    // Per-company token cache: companyId → (token, expiry)
    private static readonly Dictionary<int, TokenEntry> _tokenCache = new Dictionary<int, TokenEntry>();
    private static readonly object _tokenLock = new object();

    // Company → clientapp mapping loaded from DB on first use
    private static Dictionary<int, ClientCredentials> _credentialsMap;
    private static readonly object _credLock = new object();

    private class TokenEntry
    {
        public string Token;
        public DateTime Expiry;
    }

    private class ClientCredentials
    {
        public string ClientId;
        public string Secret;
    }

    // ---------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------

    /// <summary>
    /// Submit a single print job by inserting directly to the database.
    ///
    /// ARCHITECTURE (Sept 2026):
    ///   Previous versions called POST /api/printjob/print, which required the
    ///   API's embedded MQTT broker on port 8883 to be healthy. That broker is
    ///   shared with the Print Server's MQTT subscription, and ANY IIS app-pool
    ///   recycle (config change, restart, etc.) would kill both MQTT connections
    ///   simultaneously — breaking printing AND the fixed reader at the same time.
    ///
    ///   This version bypasses the API entirely. The print job row is inserted
    ///   with completed=0, and the Print Server's poll cycle (GET /api/PrintJobs/New
    ///   every ~2 seconds) picks it up. Zero MQTT dependency for printing.
    ///
    /// Dependencies:
    ///   - Primary: POST /api/printjob/print (generates RFID tag, inserts DB record, and dispatches MQTT to Print Server)
    ///   - Fallback: Direct database insert into dbo.printjob if API is temporarily unreachable
    /// </summary>
    public static long SubmitPrintJob(long recordId, long templateId, int companyId, string tableName = "Asset")
    {
        bool useApi = string.Equals(ConfigurationManager.AppSettings["UseDirectPrintApi"], "true", StringComparison.OrdinalIgnoreCase);
        if (useApi)
        {
            // 1. Primary: Native Print Server API call (DB insert + MQTT dispatch to Print Server)
            try
            {
                int cid = companyId > 0 ? companyId : GetCompanyIdForTemplate(templateId);
                string token = GetOAuthToken(cid);
                string url = GetApiBase() + "/printjob/print";

                var payload = new Dictionary<string, object>
                {
                    { "id", -1 },
                    { "recordID", recordId },
                    { "templateID", templateId },
                    { "tableName", tableName ?? "Asset" },
                    { "useWithService", "" }
                };

                string json = new JavaScriptSerializer().Serialize(payload);
                string response = PostJson(url, json, token);

                long jobId;
                if (long.TryParse(response.Trim().Trim('"', '\''), out jobId))
                    return jobId;
            }
            catch
            {
                // API call failed or returned unexpected response — fall through to database insert fallback
            }
        }

        // 2. Direct database insert (Native Standalone iDash Mode)
        string connStr = GetConnectionString();
        if (string.IsNullOrEmpty(connStr))
            throw new Exception("Cannot submit print job: no database connection string configured.");

        using (var cn = new SqlConnection(connStr))
        {
            cn.Open();

            using (var cmd = new SqlCommand(
                @"INSERT INTO printjob (recordid, tablename, templateid, completed, created, companyid, usewithservice)
                  VALUES (@rid, @tbl, @tid, 0, SYSDATETIMEOFFSET(), @cid, '');
                  SELECT SCOPE_IDENTITY();", cn))
            {
                cmd.Parameters.AddWithValue("@rid", recordId);
                cmd.Parameters.AddWithValue("@tbl", tableName ?? "Asset");
                cmd.Parameters.AddWithValue("@tid", templateId);
                cmd.Parameters.AddWithValue("@cid", companyId);
                var result = cmd.ExecuteScalar();
                if (result != null && result != DBNull.Value)
                    return Convert.ToInt64(result);
            }
        }

        throw new Exception("Print job insert returned no ID.");
    }


    private static string GetConnectionString()
    {
        string connStr = ConfigurationManager.ConnectionStrings["iDash"] != null
            ? ConfigurationManager.ConnectionStrings["iDash"].ConnectionString
            : ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        if (string.IsNullOrEmpty(connStr))
        {
            foreach (ConnectionStringSettings css in ConfigurationManager.ConnectionStrings)
            {
                if (css.Name != "LocalSqlServer" && !string.IsNullOrEmpty(css.ConnectionString))
                {
                    connStr = css.ConnectionString;
                    break;
                }
            }
        }
        return connStr;
    }

    /// <summary>
    /// Batch print: Submits each print job individually via the Print Server API,
    /// waiting for each job to complete before submitting the next.
    /// 
    /// WHY: BarTender templates use a "All Records" database query that prints
    /// ALL pending (completed=0) jobs each time it's triggered. If we submit
    /// job 2 before job 1 is marked complete, BarTender prints both — causing
    /// duplicate labels. By polling the printjob table for completion between
    /// submissions, we guarantee exactly one print per label.
    /// <summary>
    /// Purges stale or orphaned print jobs older than 45 seconds that are still completed=0.
    /// This prevents dead jobs from past sessions or other sites from being picked up
    /// by BarTender's "WHERE completed=0" query.
    /// </summary>
    public static void PurgeStalePrintJobs(string connStr)
    {
        try
        {
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand(
                    @"UPDATE dbo.printjob 
                      SET completed = 1, message = 'Auto-cleared stale print job'
                      WHERE completed = 0 AND (created < DATEADD(second, -45, SYSDATETIMEOFFSET()) OR created IS NULL)", cn))
                {
                    cmd.ExecuteNonQuery();
                }
            }
        }
        catch { }
    }

    /// <summary>
    /// Batch print: Submits each print job individually via the Print Server API,
    /// waiting for each job to complete before submitting the next.
    /// 
    /// WHY: BarTender templates use a "All Records" database query that prints
    /// ALL pending (completed=0) jobs each time it's triggered. If we submit
    /// job 2 before job 1 is marked complete, BarTender prints both — causing
    /// duplicate labels. By polling the printjob table for completion between
    /// submissions, we guarantee exactly one print per label.
    /// </summary>
    public static int SubmitPrintJobsBatch(
        List<long> assetIds, long templateId, int companyId,
        out List<string> errors)
    {
        errors = new List<string>();
        if (assetIds == null || assetIds.Count == 0) return 0;

        string connStr = GetConnectionString();
        // Purge any stale jobs first so BarTender's query never picks up ghost records
        PurgeStalePrintJobs(connStr);

        // Wait if an active job is currently being processed
        WaitForPendingJobsComplete(connStr, companyId, templateId, maxWaitMs: 15000);

        int submitted = 0;

        foreach (var assetId in assetIds)
        {
            try
            {
                SubmitPrintJob(assetId, templateId, companyId);
                submitted++;

                // Wait for this job to be marked complete before sending the next.
                // The Print Server + BarTender typically finishes in 2-5 seconds.
                // We poll every 500ms, timeout after 15 seconds.
                if (submitted < assetIds.Count)
                {
                    WaitForPendingJobsComplete(connStr, companyId, templateId, maxWaitMs: 15000);
                }
            }
            catch (Exception ex)
            {
                errors.Add("Print failed for asset " + assetId + ": " + ex.Message);
            }
        }

        return submitted;
    }

    /// <summary>
    /// Polls the printjob table until no pending (completed=0) jobs remain,
    /// or until the timeout is reached.
    /// CRITICAL: BarTender templates query "WHERE completed = 0" across ALL records,
    /// regardless of company or template. Therefore we must wait until total pending count is 0.
    /// If timeout is reached, any remaining pending jobs are auto-marked complete so they
    /// cannot be re-printed by subsequent jobs.
    /// </summary>
    private static void WaitForPendingJobsComplete(string connStr, int companyId, long templateId, int maxWaitMs)
    {
        int elapsed = 0;
        const int pollInterval = 500;

        while (elapsed < maxWaitMs)
        {
            System.Threading.Thread.Sleep(pollInterval);
            elapsed += pollInterval;

            try
            {
                using (var cn = new SqlConnection(connStr))
                {
                    cn.Open();
                    using (var cmd = new SqlCommand(
                        @"SELECT COUNT(*) FROM dbo.printjob WHERE completed = 0", cn))
                    {
                        int pending = (int)cmd.ExecuteScalar();
                        if (pending == 0) return; // All done, safe to submit next
                    }
                }
            }
            catch
            {
                // If we can't check, fall back to a safe fixed delay
                System.Threading.Thread.Sleep(2000);
                return;
            }
        }

        // Timeout reached — force-complete lingering pending jobs to prevent multi-print cascade
        try
        {
            using (var cn = new SqlConnection(connStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand(
                    @"UPDATE dbo.printjob 
                      SET completed = 1, message = 'Timed out waiting for completion' 
                      WHERE completed = 0", cn))
                {
                    cmd.ExecuteNonQuery();
                }
            }
        }
        catch { }
    }

    /// <summary>
    /// Submit multiple print jobs. Returns count of successfully submitted jobs.
    /// Waits for each job to complete before submitting the next to prevent
    /// BarTender's "All Records" query from causing duplicate labels.
    /// </summary>
    public static int SubmitPrintJobs(
        List<Dictionary<string, object>> jobs,
        int companyId,
        out List<string> errors)
    {
        errors = new List<string>();
        int count = 0;
        string connStr = GetConnectionString();

        // Purge any stale jobs first so BarTender's query never picks up ghost records
        PurgeStalePrintJobs(connStr);

        // Wait if an active job is currently being processed
        WaitForPendingJobsComplete(connStr, companyId, 0, maxWaitMs: 15000);

        foreach (var job in jobs)
        {
            try
            {
                long recordId = Convert.ToInt64(job.ContainsKey("recordID") ? job["recordID"] : 0);
                long templateId = Convert.ToInt64(job.ContainsKey("templateID") ? job["templateID"] : 0);
                string tableName = job.ContainsKey("tableName") ? (job["tableName"] ?? "Asset").ToString() : "Asset";

                if (recordId <= 0 || templateId <= 0)
                {
                    errors.Add("Invalid recordID or templateID: " + recordId + "/" + templateId);
                    continue;
                }

                SubmitPrintJob(recordId, templateId, companyId, tableName);
                count++;

                // Wait for this job to complete before sending the next
                if (count < jobs.Count)
                    WaitForPendingJobsComplete(connStr, companyId, templateId, maxWaitMs: 15000);
            }
            catch (Exception ex)
            {
                errors.Add("Print job failed: " + ex.Message);
            }
        }

        return count;
    }

    /// <summary>
    /// Get the template ID for a given site's company ID.
    /// Returns the first template for that company, or 0 if not found.
    /// </summary>
    public static long GetTemplateIdForCompany(int companyId)
    {
        string connStr = GetConnectionString();
        using (var cn = new SqlConnection(connStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(
                "SELECT TOP 1 id FROM template WHERE companyid = @cid AND printclientid > 0 ORDER BY id", cn))
            {
                cmd.Parameters.AddWithValue("@cid", companyId);
                var result = cmd.ExecuteScalar();
                if (result != null && result != DBNull.Value)
                    return Convert.ToInt64(result);
            }
        }
        return 0;
    }

    /// <summary>
    /// Resolve the companyId from a templateID.
    /// Each template belongs to exactly one company.
    /// </summary>
    public static int GetCompanyIdForTemplate(long templateId)
    {
        string connStr = GetConnectionString();
        using (var cn = new SqlConnection(connStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(
                "SELECT companyid FROM template WHERE id = @tid", cn))
            {
                cmd.Parameters.AddWithValue("@tid", templateId);
                var result = cmd.ExecuteScalar();
                if (result != null && result != DBNull.Value)
                    return Convert.ToInt32(result);
            }
        }
        return 0;
    }

    /// <summary>
    /// Convenience overload: auto-resolves companyId from the templateID in the job list.
    /// Uses the first job's templateID to determine the site.
    /// </summary>
    public static int SubmitPrintJobs(
        List<Dictionary<string, object>> jobs,
        out List<string> errors)
    {
        int companyId = 0;
        if (jobs != null && jobs.Count > 0)
        {
            var first = jobs[0];
            if (first.ContainsKey("templateID"))
            {
                long tid = Convert.ToInt64(first["templateID"]);
                companyId = GetCompanyIdForTemplate(tid);
            }
        }
        return SubmitPrintJobs(jobs, companyId, out errors);
    }

    // ---------------------------------------------------------------
    // Direct BarTender Printing (no iDash Print Service / MQTT)
    //
    // These methods drive BarTender directly via the SDK (TaskManager
    // or in-process Engine). Zero dependency on dbo.printjob, MQTT,
    // or the iDash Print Service poll cycle.
    // ---------------------------------------------------------------

    /// <summary>
    /// Print labels for a batch of asset IDs directly through BarTender.
    /// Queries dbo.asset for each ID to populate label SubString fields,
    /// resolves the template .btw path, and calls PrintDirect per asset.
    /// Drop-in replacement for SubmitPrintJobsBatch().
    /// </summary>
    public static int PrintAssetsDirect(
        List<long> assetIds, long templateId, out List<string> errors)
    {
        errors = new List<string>();
        if (assetIds == null || assetIds.Count == 0) return 0;

        string templatePath = BarTenderApiHelper.ResolveTemplatePath(templateId.ToString());
        string connStr = GetConnectionString();
        int printed = 0;

        foreach (var assetId in assetIds)
        {
            try
            {
                // Fetch label field values from dbo.asset
                var fields = LoadAssetLabelFields(connStr, assetId);
                if (fields == null)
                {
                    errors.Add("Asset ID " + assetId + " not found in database.");
                    continue;
                }

                var result = BarTenderApiHelper.PrintDirect(templatePath, "", fields);
                if (result.Success)
                {
                    printed++;
                }
                else
                {
                    errors.Add("Print failed for asset " + assetId + ": " + result.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                errors.Add("Print error for asset " + assetId + ": " + ex.Message);
            }
        }

        return printed;
    }

    /// <summary>
    /// Print labels from a list of job dictionaries (recordID + templateID)
    /// directly through BarTender. Drop-in replacement for SubmitPrintJobs().
    /// </summary>
    public static int PrintJobsDirect(
        List<Dictionary<string, object>> jobs,
        out List<string> errors)
    {
        errors = new List<string>();
        if (jobs == null || jobs.Count == 0) return 0;

        string connStr = GetConnectionString();
        int printed = 0;

        foreach (var job in jobs)
        {
            try
            {
                long recordId = Convert.ToInt64(job.ContainsKey("recordID") ? job["recordID"] : 0);
                long tplId = Convert.ToInt64(job.ContainsKey("templateID") ? job["templateID"] : 0);

                if (recordId <= 0 || tplId <= 0)
                {
                    errors.Add("Invalid recordID or templateID: " + recordId + "/" + tplId);
                    continue;
                }

                string templatePath = BarTenderApiHelper.ResolveTemplatePath(tplId.ToString());
                var fields = LoadAssetLabelFields(connStr, recordId);
                if (fields == null)
                {
                    errors.Add("Asset ID " + recordId + " not found in database.");
                    continue;
                }

                var result = BarTenderApiHelper.PrintDirect(templatePath, "", fields);
                if (result.Success)
                {
                    printed++;
                }
                else
                {
                    errors.Add("Print failed for asset " + recordId + ": " + result.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                errors.Add("Print job failed: " + ex.Message);
            }
        }

        return printed;
    }

    /// <summary>
    /// Queries dbo.asset by ID and returns label SubString field values.
    /// Maps: name→lblname, description→lbldescription, text3→lblsn,
    ///        text8→lbleil (CMR), rfidtag→lblrfidtag.
    /// Returns null if asset not found.
    /// </summary>
    private static Dictionary<string, string> LoadAssetLabelFields(string connStr, long assetId)
    {
        using (var cn = new SqlConnection(connStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(
                "SELECT name, description, text3, text8, rfidtag FROM dbo.asset WHERE id = @id", cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                using (var rd = cmd.ExecuteReader())
                {
                    if (!rd.Read()) return null;
                    return new Dictionary<string, string>
                    {
                        { "lblname",        rd["name"] != DBNull.Value ? rd["name"].ToString() : "" },
                        { "lbldescription", rd["description"] != DBNull.Value ? rd["description"].ToString() : "" },
                        { "lblsn",          rd["text3"] != DBNull.Value ? rd["text3"].ToString() : "" },
                        { "lbleil",         rd["text8"] != DBNull.Value ? rd["text8"].ToString() : "" },
                        { "lblrfidtag",     rd["rfidtag"] != DBNull.Value ? rd["rfidtag"].ToString() : "" }
                    };
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // OAuth Token Management (per-company)
    // ---------------------------------------------------------------

    private static string GetOAuthToken(int companyId)
    {
        lock (_tokenLock)
        {
            // Reuse cached token if still valid (with 60s buffer)
            TokenEntry cached;
            if (_tokenCache.TryGetValue(companyId, out cached))
            {
                if (cached.Token != null && DateTime.UtcNow < cached.Expiry.AddSeconds(-60))
                    return cached.Token;
            }

            // Get credentials for this company
            var creds = GetCredentials(companyId);
            string tokenUrl = ConfigurationManager.AppSettings["iDash_TokenUrl"];
            if (string.IsNullOrEmpty(tokenUrl))
                tokenUrl = "http://localhost/connect/token";

            string body = string.Format(
                "grant_type=client_credentials&client_id={0}&client_secret={1}",
                Uri.EscapeDataString(creds.ClientId),
                Uri.EscapeDataString(creds.Secret));

            var request = (HttpWebRequest)WebRequest.Create(tokenUrl);
            request.Method = "POST";
            request.ContentType = "application/x-www-form-urlencoded";
            request.Timeout = 15000;

            byte[] data = Encoding.UTF8.GetBytes(body);
            request.ContentLength = data.Length;
            using (var stream = request.GetRequestStream())
                stream.Write(data, 0, data.Length);

            using (var response = (HttpWebResponse)request.GetResponse())
            using (var reader = new StreamReader(response.GetResponseStream()))
            {
                string responseJson = reader.ReadToEnd();
                var tokenData = new JavaScriptSerializer()
                    .Deserialize<Dictionary<string, object>>(responseJson);

                string token = tokenData["access_token"].ToString();

                int expiresIn = 3600;
                if (tokenData.ContainsKey("expires_in"))
                    expiresIn = Convert.ToInt32(tokenData["expires_in"]);

                _tokenCache[companyId] = new TokenEntry
                {
                    Token = token,
                    Expiry = DateTime.UtcNow.AddSeconds(expiresIn)
                };

                return token;
            }
        }
    }

    /// <summary>
    /// Load per-site credentials from the clientapp table.
    /// Looks for entries named "idash_XXX" where XXX matches the company name prefix.
    /// Falls back to "v512" if no site-specific entry exists.
    /// </summary>
    private static ClientCredentials GetCredentials(int companyId)
    {
        lock (_credLock)
        {
            if (_credentialsMap == null)
            {
                _credentialsMap = new Dictionary<int, ClientCredentials>();
                string connStr = GetConnectionString();
                using (var cn = new SqlConnection(connStr))
                {
                    cn.Open();
                    using (var cmd = new SqlCommand(
                        "SELECT clientid, secret, companyid FROM clientapp WHERE clientid LIKE 'idash_%'", cn))
                    {
                        using (var rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                int cid = Convert.ToInt32(rdr["companyid"]);
                                _credentialsMap[cid] = new ClientCredentials
                                {
                                    ClientId = rdr["clientid"].ToString(),
                                    Secret = rdr["secret"].ToString()
                                };
                            }
                        }
                    }
                }
            }
        }

        ClientCredentials creds;
        if (_credentialsMap.TryGetValue(companyId, out creds))
            return creds;

        // Fallback: use web.config credentials (v512)
        string fallbackId = ConfigurationManager.AppSettings["iDash_ClientId"];
        string fallbackSecret = ConfigurationManager.AppSettings["iDash_ClientSecret"];
        if (!string.IsNullOrEmpty(fallbackId))
        {
            return new ClientCredentials
            {
                ClientId = fallbackId,
                Secret = fallbackSecret
            };
        }

        throw new InvalidOperationException(
            "No iDash client app configured for companyId " + companyId +
            ". Add an 'idash_XXX' entry to the clientapp table.");
    }

    // ---------------------------------------------------------------
    // HTTP Helpers
    // ---------------------------------------------------------------

    private static string GetApiBase()
    {
        string apiBase = ConfigurationManager.AppSettings["iDash_ApiBase"];
        if (string.IsNullOrEmpty(apiBase))
            apiBase = "http://localhost/api";
        else if (!apiBase.TrimEnd('/').EndsWith("/api", StringComparison.OrdinalIgnoreCase))
            apiBase = apiBase.TrimEnd('/') + "/api";
        return apiBase.TrimEnd('/');
    }

    private static string PostJson(string url, string json, string bearerToken)
    {
        var request = (HttpWebRequest)WebRequest.Create(url);
        request.Method = "POST";
        request.ContentType = "application/json; charset=utf-8";
        request.Timeout = 30000;

        if (!string.IsNullOrEmpty(bearerToken))
            request.Headers["Authorization"] = "Bearer " + bearerToken;

        byte[] data = Encoding.UTF8.GetBytes(json);
        request.ContentLength = data.Length;
        using (var stream = request.GetRequestStream())
            stream.Write(data, 0, data.Length);

        try
        {
            using (var response = (HttpWebResponse)request.GetResponse())
            using (var reader = new StreamReader(response.GetResponseStream()))
            {
                return reader.ReadToEnd();
            }
        }
        catch (WebException wex)
        {
            if (wex.Response != null)
            {
                using (var reader = new StreamReader(wex.Response.GetResponseStream()))
                {
                    string errorBody = reader.ReadToEnd();
                    throw new Exception(
                        string.Format("API error ({0}): {1}",
                            ((HttpWebResponse)wex.Response).StatusCode, errorBody));
                }
            }
            throw;
        }
    }
}
