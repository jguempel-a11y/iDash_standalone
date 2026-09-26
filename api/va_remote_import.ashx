<%@ WebHandler Language="C#" Class="VaRemoteImport" %>

using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;

/// <summary>
/// Remote DB Import API — network-safe (no BULK INSERT).
///
/// Accepts a multipart/form-data POST with a tab-delimited .txt data file.
/// Uses SqlBulkCopy to stream rows from the IIS web server to SQL Server
/// over the network, then runs the standard merge SQL.
///
/// Usage:
///   POST /iDash/api/va_remote_import.ashx
///   Headers:  X-Api-Key: {key from web.config appSettings["RemoteImportKey"]}
///   Body:     multipart/form-data with field "datafile" (the .txt file)
///             optional field "forcesite" (3-digit station number)
///
/// Returns JSON: { status, rows, locationsInserted, assetsInserted,
///                 assetsUpdated, assetsSkipped, errors, totalAssets, detail }
/// </summary>
public class VaRemoteImport : IHttpHandler
{
    public bool IsReusable { get { return false; } }

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Server.ScriptTimeout = 1800; // 30 min for large imports

        // ── Auth check (Fail-Closed Enforcement) ──
        string configKey = ConfigurationManager.AppSettings["RemoteImportKey"];
        if (string.IsNullOrWhiteSpace(configKey))
        {
            context.Response.StatusCode = 503;
            context.Response.Write("{\"status\":\"ERROR\",\"detail\":\"Remote import endpoint is disabled: RemoteImportKey is not configured in web.config.\"}");
            return;
        }

        string headerKey = context.Request.Headers["X-Api-Key"];
        if (string.IsNullOrEmpty(headerKey) || headerKey != configKey)
        {
            context.Response.StatusCode = 401;
            context.Response.Write("{\"status\":\"ERROR\",\"detail\":\"Invalid or missing API key.\"}");
            return;
        }

        // ── Only POST ──
        if (context.Request.HttpMethod != "POST")
        {
            context.Response.StatusCode = 405;
            context.Response.Write("{\"status\":\"ERROR\",\"detail\":\"POST required.\"}");
            return;
        }

        try
        {
            // ── Get uploaded file ──
            HttpPostedFile file = context.Request.Files["datafile"];
            if (file == null || file.ContentLength == 0)
            {
                context.Response.Write("{\"status\":\"ERROR\",\"detail\":\"No file uploaded. Send as multipart field 'datafile'.\"}");
                return;
            }

            string forceSite = (context.Request.Form["forcesite"] ?? "").Trim();

            // ── Parse tab-delimited file ──
            string content;
            using (var sr = new StreamReader(file.InputStream, Encoding.UTF8, true))
            {
                content = sr.ReadToEnd();
            }

            // Strip BOM / zero-width chars
            content = content.Replace("\uFEFF", "").Replace("\u200B", "");

            var lines = content.Replace("\r", "").Split('\n')
                               .Where(l => !string.IsNullOrWhiteSpace(l)).ToArray();

            if (lines.Length < 2)
            {
                context.Response.Write("{\"status\":\"ERROR\",\"detail\":\"File must have a header row and at least one data row.\"}");
                return;
            }

            // Standard 15 columns (matching AssetFileRaw)
            string[] columns = new string[] {
                "ENTRY NUMBER", "MANUFACTURER", "MFGR. EQUIPMENT NAME", "MODEL",
                "SERIAL #", "EQUIPMENT CATEGORY", "USE STATUS", "SERVICE POINTER",
                "LOCATION", "PHYSICAL INVENTORY DATE", "PREVIOUS LOCATION",
                "STATION NUMBER", "CATEGORY STOCK NUMBER", "CMR", "PURCHASE ORDER #"
            };

            // Check if file has SUB STATION (16th column)
            var headerFields = lines[0].Split('\t');
            bool hasSubStation = headerFields.Length >= 16;

            var dt = new DataTable();
            foreach (var col in columns)
                dt.Columns.Add(col, typeof(string));
            if (hasSubStation)
                dt.Columns.Add("SUB STATION", typeof(string));

            int dataRows = 0;
            for (int i = 1; i < lines.Length; i++)
            {
                var fields = lines[i].Split('\t');
                var row = dt.NewRow();
                int colCount = hasSubStation ? columns.Length + 1 : columns.Length;
                for (int j = 0; j < colCount; j++)
                {
                    if (j < fields.Length && !string.IsNullOrEmpty(fields[j]))
                        row[j] = fields[j].Trim();
                    else
                        row[j] = DBNull.Value;
                }
                dt.Rows.Add(row);
                dataRows++;
            }

            // ── Connect and import ──
            string connStr = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                var cmd = conn.CreateCommand();
                cmd.CommandTimeout = 120;

                // Drop/create AssetFileRaw
                cmd.CommandText = @"
IF OBJECT_ID('dbo.AssetFileRaw', 'U') IS NOT NULL DROP TABLE dbo.AssetFileRaw;
CREATE TABLE dbo.AssetFileRaw (
    [ENTRY NUMBER]             nvarchar(500) NULL,
    [MANUFACTURER]             nvarchar(500) NULL,
    [MFGR. EQUIPMENT NAME]    nvarchar(500) NULL,
    [MODEL]                    nvarchar(500) NULL,
    [SERIAL #]                 nvarchar(500) NULL,
    [EQUIPMENT CATEGORY]       nvarchar(500) NULL,
    [USE STATUS]               nvarchar(500) NULL,
    [SERVICE POINTER]          nvarchar(500) NULL,
    [LOCATION]                 nvarchar(500) NULL,
    [PHYSICAL INVENTORY DATE]  nvarchar(500) NULL,
    [PREVIOUS LOCATION]        nvarchar(500) NULL,
    [STATION NUMBER]           nvarchar(500) NULL,
    [CATEGORY STOCK NUMBER]    nvarchar(500) NULL,
    [CMR]                      nvarchar(500) NULL,
    [PURCHASE ORDER #]         nvarchar(500) NULL,
    [SUB STATION]              nvarchar(500) NULL
);
IF OBJECT_ID('dbo.locationtemp', 'U') IS NOT NULL DELETE FROM dbo.locationtemp;
IF OBJECT_ID('dbo.assettemp', 'U') IS NOT NULL DELETE FROM dbo.assettemp;";
                cmd.ExecuteNonQuery();

                // SqlBulkCopy (network-safe — streams data over SQL connection)
                using (var bulk = new SqlBulkCopy(conn))
                {
                    bulk.DestinationTableName = "dbo.AssetFileRaw";
                    bulk.BatchSize = 2000;
                    bulk.BulkCopyTimeout = 600;

                    foreach (DataColumn col in dt.Columns)
                        bulk.ColumnMappings.Add(col.ColumnName, col.ColumnName);

                    bulk.WriteToServer(dt);
                }

                // Verify
                cmd.CommandText = "SELECT COUNT(*) FROM dbo.AssetFileRaw";
                int sqlCount = (int)cmd.ExecuteScalar();

                // Build force-site clause
                string forceSiteClause = "";
                if (!string.IsNullOrEmpty(forceSite))
                {
                    forceSiteClause = string.Format(
                        "UPDATE dbo.assettemp SET text7 = '{0}' WHERE text7 IS NULL OR LTRIM(RTRIM(text7)) = '';",
                        forceSite.Replace("'", "''"));
                }

                // Run merge SQL
                cmd.CommandText = BuildMergeSql(forceSiteClause);
                cmd.CommandTimeout = 600;

                using (var reader = cmd.ExecuteReader())
                {
                    if (reader.HasRows && reader.Read())
                    {
                        int locIns = Convert.ToInt32(reader["LocationsInserted"]);
                        int assIns = Convert.ToInt32(reader["AssetsInserted"]);
                        int assUpd = Convert.ToInt32(reader["AssetsUpdated"]);
                        int assSkp = Convert.ToInt32(reader["AssetsSkipped"]);
                        int errors = Convert.ToInt32(reader["Errors"]);
                        int total  = Convert.ToInt32(reader["TotalAssetsNow"]);

                        string json = string.Format(
                            "{{\"status\":\"OK\",\"rows\":{0},\"sqlRows\":{1}," +
                            "\"locationsInserted\":{2},\"assetsInserted\":{3}," +
                            "\"assetsUpdated\":{4},\"assetsSkipped\":{5}," +
                            "\"errors\":{6},\"totalAssets\":{7}," +
                            "\"forceSite\":\"{8}\"," +
                            "\"detail\":\"Import completed successfully.\"}}",
                            dataRows, sqlCount, locIns, assIns, assUpd, assSkp,
                            errors, total,
                            HttpUtility.JavaScriptStringEncode(forceSite));

                        context.Response.Write(json);
                        return;
                    }
                }

                context.Response.Write(string.Format(
                    "{{\"status\":\"OK\",\"rows\":{0},\"sqlRows\":{1},\"detail\":\"Merge completed but no summary returned.\"}}",
                    dataRows, sqlCount));
            }
        }
        catch (Exception ex)
        {
            string msg = (ex.Message ?? "").Replace("\"", "'").Replace("\r", " ").Replace("\n", " ");
            context.Response.Write("{\"status\":\"ERROR\",\"detail\":\"" + msg + "\"}");
        }
    }

    /// <summary>
    /// Same merge SQL as va_data_import.aspx.cs — full pipeline:
    /// AssetFileRaw → assettemp/locationtemp → company/location/asset merge.
    /// </summary>
    private string BuildMergeSql(string forceSiteClause)
    {
        return @"
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;

DECLARE @loc_inserted    INT = 0;
DECLARE @asset_inserted  INT = 0;
DECLARE @asset_skipped   INT = 0;
DECLARE @asset_updated   INT = 0;
DECLARE @errors          INT = 0;

/* Ensure staging tables exist */
IF OBJECT_ID('dbo.locationtemp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.locationtemp (
        [name] varchar(50) NOT NULL, [site] varchar(100) NULL, [building] varchar(100) NULL,
        [floor] varchar(50) NULL, [room] varchar(100) NULL, [description] varchar(500) NULL,
        [rfidtag] varchar(50) NULL, [lastmodifiedby] varchar(50) NULL,
        [lastinventoried] datetimeoffset(7) NULL, [companyid] int NOT NULL DEFAULT(0)
    );
END;

IF OBJECT_ID('dbo.assettemp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.assettemp (
        [name] varchar(50) NOT NULL, [description] varchar(500) NULL, [rfidtag] varchar(50) NULL,
        [assettype] varchar(50) NULL, [departmentcode] varchar(50) NULL, [maxunseentime] int NULL,
        [lastobservedlocation] varchar(50) NULL, [lastobservedtime] datetimeoffset(7) NULL,
        [checkinstatus] varchar(50) NULL, [checkedoutto] varchar(50) NULL,
        [additionalinformation] varchar(5000) NULL, [disposalstatus] varchar(50) NULL,
        [disposalmethod] varchar(50) NULL, [disposaldate] datetimeoffset(7) NULL,
        [disposaldestination] varchar(50) NULL, [maintenancestartdate] datetimeoffset(7) NULL,
        [maintenancesingledate] datetimeoffset(7) NULL, [nextmaintenance] datetimeoffset(7) NULL,
        [date1] datetimeoffset(7) NULL, [date2] datetimeoffset(7) NULL, [date3] datetimeoffset(7) NULL,
        [date4] datetimeoffset(7) NULL, [date5] datetimeoffset(7) NULL,
        [listvalue1] varchar(100) NULL, [listvalue2] varchar(100) NULL, [listvalue3] varchar(100) NULL, [listvalue4] varchar(100) NULL, [listvalue5] varchar(100) NULL,
        [text1] varchar(500) NULL, [text2] varchar(500) NULL, [text3] varchar(500) NULL,
        [text4] varchar(500) NULL, [text5] varchar(500) NULL, [text6] varchar(500) NULL,
        [text7] varchar(500) NULL, [text8] varchar(500) NULL, [text9] varchar(500) NULL,
        [text10] varchar(500) NULL, [text11] varchar(500) NULL, [text12] varchar(500) NULL,
        [text13] varchar(500) NULL, [text14] varchar(500) NULL, [text15] varchar(500) NULL,
        [text16] varchar(500) NULL, [text17] varchar(500) NULL, [text18] varchar(500) NULL,
        [text19] varchar(500) NULL, [text20] varchar(500) NULL,
        [maintenancemethod] varchar(50) NULL, [maintenanceintervalmonths] int NULL,
        [nearestfixed] varchar(50) NULL, [lastmodified] datetimeoffset(7) NULL,
        [locationid] int NULL, [sensorreadinghistoryid] int NULL, [alertingactionid] int NULL,
        [sensorstatshistoryid] int NULL, [readerid] int NULL, [assetparentid] int NULL,
        [assetchildcount] int NULL, [vtagboxx] decimal(18,0) NULL, [vtagboxy] decimal(18,0) NULL,
        [vtagboxwidth] decimal(18,0) NULL, [vtagboxheight] decimal(18,0) NULL,
        [vtagx] decimal(18,5) NULL, [vtagy] decimal(18,5) NULL, [vtagaccelsensor] bit NULL,
        [vtagpositiontype] varchar(50) NULL, [vtagalgorithmtype] varchar(50) NULL,
        [batterylevel] decimal(18,2) NULL, [vtagid] varchar(50) NULL, [vtagz] int NULL,
        [vtaglastseen] datetimeoffset(7) NULL, [vtaglastmoved] datetimeoffset(7) NULL,
        [filedataid] int NULL, [created] datetimeoffset(7) NULL, [lastmodifiedby] varchar(50) NULL,
        [latitude] decimal(18,7) NULL, [longitude] decimal(18,7) NULL, [altitude] decimal(18,7) NULL,
        [numberofsatellites] int NULL, [gpsaccuracy] int NULL, [lastgpsfix] datetimeoffset(7) NULL,
        [vtagtype] varchar(50) NULL, [parentvtag] varchar(50) NULL, [missedsatellitefixes] int NULL,
        [lastinventoried] datetimeoffset(7) NULL, [vtaggpsdeviceid] varchar(100) NULL,
        [vtaggpsappkey] varchar(100) NULL, [deviceregistered] bit NULL,
        [lastmaintenance] datetimeoffset(7) NULL, [companyid] int NOT NULL DEFAULT(0),
        [unseennotified] bit NULL
    );
END;

DELETE FROM dbo.locationtemp;
DELETE FROM dbo.assettemp;

/* Pre-seed missing companies */
IF OBJECT_ID('tempdb..#MissingCompanies') IS NOT NULL DROP TABLE #MissingCompanies;
SELECT DISTINCT LTRIM(RTRIM(afr.[STATION NUMBER])) AS StationNumber,
       LTRIM(RTRIM(afr.[STATION NUMBER])) + ' Unknown' AS ExpectedName
INTO #MissingCompanies
FROM dbo.AssetFileRaw afr
WHERE ISNULL(LTRIM(RTRIM(afr.[STATION NUMBER])), '') <> '';

INSERT INTO dbo.company (name)
SELECT DISTINCT mc.ExpectedName FROM #MissingCompanies mc
WHERE NOT EXISTS (SELECT 1 FROM dbo.company c WHERE SUBSTRING(c.name, 1, 3) = mc.StationNumber);

/* MAP RAW -> ASSETTEMP */
INSERT INTO dbo.assettemp (
    name, text1, [description], text2, text3, text4, listvalue1, text5,
    text6, text10, text11, text7, assettype, text8, text9, lastobservedlocation
)
SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(afr.[ENTRY NUMBER])), ''), 'NULL_' + LEFT(CAST(NEWID() AS VARCHAR(36)), 8)),
    LTRIM(RTRIM(afr.[MANUFACTURER])),
    LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(afr.[MFGR. EQUIPMENT NAME], '""""',''), N' ',''), N' ',''))),
    LTRIM(RTRIM(afr.[MODEL])),
    LTRIM(RTRIM(afr.[SERIAL #])),
    LTRIM(RTRIM(afr.[EQUIPMENT CATEGORY])),
    CASE WHEN NULLIF(LTRIM(RTRIM(afr.[USE STATUS])), '') IS NULL THEN 'IN USE'
         ELSE UPPER(LTRIM(RTRIM(afr.[USE STATUS]))) END,
    LTRIM(RTRIM(afr.[SERVICE POINTER])),
    CASE WHEN NULLIF(LTRIM(RTRIM(afr.[LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
         WHEN LEFT(LTRIM(RTRIM(afr.[LOCATION])), 2) = 'SP'
             THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[LOCATION])), 3, 500))
         ELSE 'SP' + LTRIM(RTRIM(afr.[LOCATION])) END,
    NULLIF(LTRIM(RTRIM(afr.[PHYSICAL INVENTORY DATE])), ''),
    CASE WHEN NULLIF(LTRIM(RTRIM(afr.[PREVIOUS LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
         WHEN LEFT(LTRIM(RTRIM(afr.[PREVIOUS LOCATION])), 2) = 'SP'
             THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[PREVIOUS LOCATION])), 3, 500))
         ELSE 'SP' + LTRIM(RTRIM(afr.[PREVIOUS LOCATION])) END,
    LTRIM(RTRIM(afr.[STATION NUMBER])),
    LTRIM(RTRIM(afr.[CATEGORY STOCK NUMBER])),
    LTRIM(RTRIM(afr.[CMR])),
    LTRIM(RTRIM(afr.[PURCHASE ORDER #])),
    CASE WHEN NULLIF(LTRIM(RTRIM(afr.[LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
         WHEN LEFT(LTRIM(RTRIM(afr.[LOCATION])), 2) = 'SP'
             THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[LOCATION])), 3, 500))
         ELSE 'SP' + LTRIM(RTRIM(afr.[LOCATION])) END
FROM dbo.AssetFileRaw AS afr;

/* FORCE SITE (injected when mode = Force Site) */
" + forceSiteClause + @"

/* Compute name (with dupe-prefix guard) */
UPDATE dbo.assettemp SET name = CASE
    WHEN name LIKE ISNULL(text7, '') + ' EE%' THEN name
    WHEN name LIKE ISNULL(text7, '') + 'EE%'  THEN REPLACE(name, ISNULL(text7, '') + 'EE', ISNULL(text7, '') + ' EE')
    ELSE CONCAT(RTRIM(ISNULL(text7, '')), ' EE', name) END;

UPDATE dbo.assettemp SET rfidtag = CONCAT(RTRIM(ISNULL(text7, '')), 'EE',
    REPLACE(name, ISNULL(text7, '') + ' EE', ''),
    REPLICATE('F', 4 - ((5 + LEN(REPLACE(name, ISNULL(text7, '') + ' EE', ''))) % 4)));

/* Company mapping */
UPDATE at SET at.companyid = COALESCE(c.id, 0)
FROM dbo.assettemp at LEFT JOIN dbo.company c ON SUBSTRING(at.text7,1,3) = SUBSTRING(c.name,1,3);

/* Normalize dates */
UPDATE dbo.assettemp SET text10 = '01/01/1900' WHERE text10 = 'NULL';
UPDATE dbo.assettemp SET lastinventoried = CASE
    WHEN ISDATE(text10) = 1 THEN CONCAT(FORMAT(CONVERT(datetime, text10, 101), 'yyyy-MM-dd'), ' 17:00:00.0000000 +00:00')
    ELSE '1900-01-01 17:00:00.0000000 +00:00' END;
UPDATE dbo.assettemp SET date1 = lastinventoried, date2 = lastinventoried;

/* Ensure SP values */
UPDATE t SET
    t.text6 = CASE WHEN t.text6 IS NULL OR LTRIM(RTRIM(t.text6)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(t.text6),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(t.text6),3,500))
        ELSE 'SP' + LTRIM(t.text6) END,
    t.text11 = CASE WHEN t.text11 IS NULL OR LTRIM(RTRIM(t.text11)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(t.text11),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(t.text11),3,500))
        ELSE 'SP' + LTRIM(t.text11) END,
    t.lastobservedlocation = CASE WHEN t.lastobservedlocation IS NULL OR LTRIM(RTRIM(t.lastobservedlocation)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(t.lastobservedlocation),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(t.lastobservedlocation),3,500))
        ELSE 'SP' + LTRIM(t.lastobservedlocation) END
FROM dbo.assettemp t;

/* Stage locations */
INSERT INTO dbo.locationtemp (name, site, companyid)
SELECT DISTINCT LTRIM(SUBSTRING(text6, 3, 500)), text7, companyid FROM dbo.assettemp;

/* Insert new locations */
BEGIN TRY
  BEGIN TRAN;
  ;WITH src AS (SELECT LTRIM(RTRIM(lt.name)) AS base_name, lt.site, lt.companyid FROM dbo.locationtemp AS lt),
  shaped AS (SELECT name_final = 'SP' + base_name, site, companyid,
      rn = ROW_NUMBER() OVER (PARTITION BY 'SP' + base_name, companyid ORDER BY (SELECT 0)) FROM src)
  INSERT INTO dbo.location (name, site, companyid)
  SELECT s.name_final, s.site, s.companyid FROM shaped AS s WHERE s.rn = 1
    AND NOT EXISTS (SELECT 1 FROM dbo.location WITH (UPDLOCK, HOLDLOCK) WHERE name = s.name_final AND companyid = s.companyid);
  SET @loc_inserted = @@ROWCOUNT;
  COMMIT;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK;
  SET @errors = @errors + 1;
  THROW;
END CATCH;

/* Deduplicate assets */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL DROP TABLE #new_assets;
IF OBJECT_ID('tempdb..#staged_assets') IS NOT NULL DROP TABLE #staged_assets;
IF OBJECT_ID('tempdb..#asset_name_companyid_dupes') IS NOT NULL DROP TABLE #asset_name_companyid_dupes;

SELECT at.*, rn = ROW_NUMBER() OVER (PARTITION BY at.name, at.companyid ORDER BY (SELECT 0))
INTO #staged_assets FROM dbo.assettemp AS at;

SELECT name, companyid, COUNT(*) AS dup_count INTO #asset_name_companyid_dupes
FROM #staged_assets GROUP BY name, companyid HAVING COUNT(*) > 1;

SET @asset_skipped = (SELECT ISNULL(SUM(dup_count - 1), 0) FROM #asset_name_companyid_dupes);

CREATE TABLE #new_assets (rfidtag varchar(50) NOT NULL PRIMARY KEY);

/* Update / Merge existing assets matching (name, companyid) */
UPDATE a
SET
    a.description = COALESCE(NULLIF(sa.description, ''), a.description),
    a.text1 = COALESCE(NULLIF(sa.text1, ''), a.text1),               -- Manufacturer
    a.text2 = COALESCE(NULLIF(sa.text2, ''), a.text2),               -- Model
    a.text3 = COALESCE(NULLIF(sa.text3, ''), a.text3),               -- Serial #
    a.text4 = COALESCE(NULLIF(sa.text4, ''), a.text4),               -- Equipment Category
    a.text5 = COALESCE(NULLIF(sa.text5, ''), a.text5),               -- Service Pointer
    a.text7 = COALESCE(NULLIF(sa.text7, ''), a.text7),               -- Station Number
    a.text8 = COALESCE(NULLIF(sa.text8, ''), a.text8),               -- CMR
    a.text9 = COALESCE(NULLIF(sa.text9, ''), a.text9),               -- PO #
    a.text10 = CASE 
        WHEN sa.text10 IS NOT NULL AND sa.text10 <> '01/01/1900' AND sa.text10 <> 'NULL' AND sa.text10 <> ''
        THEN sa.text10 ELSE a.text10 END,                             -- Physical Inventory Date
    a.text11 = COALESCE(NULLIF(sa.text11, ''), a.text11),             -- Previous Location
    a.assettype = COALESCE(NULLIF(sa.assettype, ''), a.assettype),   -- Category Stock Number
    a.listvalue1 = COALESCE(NULLIF(sa.listvalue1, ''), a.listvalue1), -- Use Status
    a.text6 = CASE 
        WHEN sa.text6 IS NOT NULL AND sa.text6 <> 'SPZZUNKNOWN' AND sa.text6 <> ''
        THEN sa.text6 ELSE a.text6 END,
    a.lastobservedlocation = CASE 
        WHEN sa.lastobservedlocation IS NOT NULL AND sa.lastobservedlocation <> 'SPZZUNKNOWN' AND sa.lastobservedlocation <> ''
        THEN sa.lastobservedlocation ELSE a.lastobservedlocation END,
    a.lastinventoried = CASE 
        WHEN sa.lastinventoried IS NOT NULL AND sa.lastinventoried <> '1900-01-01 17:00:00.0000000 +00:00'
             AND (a.lastinventoried IS NULL OR sa.lastinventoried > a.lastinventoried)
        THEN sa.lastinventoried ELSE a.lastinventoried END,
    a.rfidtag = CASE 
        WHEN (a.rfidtag IS NULL OR a.rfidtag = '' OR a.rfidtag LIKE '%FFFF%') 
             AND NULLIF(sa.rfidtag, '') IS NOT NULL
        THEN sa.rfidtag ELSE a.rfidtag END,
    a.lastmodified = SYSDATETIMEOFFSET(),
    a.lastmodifiedby = 'iDash Remote Import'
FROM dbo.asset a
INNER JOIN #staged_assets sa 
   ON a.name = sa.name AND (a.companyid = sa.companyid OR sa.companyid = 0)
WHERE sa.rn = 1;

SET @asset_updated = @@ROWCOUNT;

/* Insert new assets that do not yet exist */
INSERT INTO dbo.asset (
    name, description, rfidtag, assettype, departmentcode, maxunseentime,
    lastobservedlocation, lastobservedtime, checkinstatus, checkedoutto,
    additionalinformation, disposalstatus, disposalmethod, disposaldate, disposaldestination,
    maintenancestartdate, maintenancesingledate, nextmaintenance, date1, date2, date3, date4, date5,
    listvalue1, listvalue2, listvalue3, listvalue4, listvalue5,
    text1, text2, text3, text4, text5,
    text6, text7, text8, text9, text10, text11, text12, text13, text14, text15, text16, text17, text18, text19, text20,
    maintenancemethod, maintenanceintervalmonths, nearestfixed, lastmodified, locationid,
    created, lastmodifiedby, lastinventoried, companyid
)
OUTPUT inserted.rfidtag INTO #new_assets(rfidtag)
SELECT
    sa.name, sa.description, sa.rfidtag, sa.assettype, sa.departmentcode, sa.maxunseentime,
    sa.lastobservedlocation, sa.lastobservedtime, sa.checkinstatus, sa.checkedoutto,
    sa.additionalinformation, sa.disposalstatus, sa.disposalmethod, sa.disposaldate, sa.disposaldestination,
    sa.maintenancestartdate, sa.maintenancesingledate, sa.nextmaintenance,
    sa.date1, sa.date2, sa.date3, sa.date4, sa.date5,
    sa.listvalue1, sa.listvalue2, sa.listvalue3, sa.listvalue4, sa.listvalue5,
    sa.text1, sa.text2, sa.text3, sa.text4, sa.text5, sa.text6, sa.text7, sa.text8, sa.text9, sa.text10,
    sa.text11, sa.text12, sa.text13, sa.text14, sa.text15, sa.text16, sa.text17, sa.text18, sa.text19, sa.text20,
    sa.maintenancemethod, sa.maintenanceintervalmonths, sa.nearestfixed, sa.lastmodified, sa.locationid,
    sa.created, sa.lastmodifiedby, sa.lastinventoried, sa.companyid
FROM #staged_assets AS sa
WHERE sa.rn = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.asset AS a WITH (UPDLOCK, HOLDLOCK) 
      WHERE a.name = sa.name AND (a.companyid = sa.companyid OR sa.companyid = 0)
  );

SET @asset_inserted = @@ROWCOUNT;

/* Single-pass backfill */
UPDATE a SET
    a.text6 = CASE WHEN a.text6 IS NULL OR LTRIM(RTRIM(a.text6)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text6),3,500))
        ELSE 'SP' + LTRIM(a.text6) END,
    a.text11 = CASE WHEN a.text11 IS NULL OR LTRIM(RTRIM(a.text11)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.text11),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text11),3,500))
        ELSE 'SP' + LTRIM(a.text11) END,
    a.lastobservedlocation = CASE WHEN a.lastobservedlocation IS NULL OR LTRIM(RTRIM(a.lastobservedlocation)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.lastobservedlocation),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.lastobservedlocation),3,500))
        ELSE 'SP' + LTRIM(a.lastobservedlocation) END,
    a.companyid = COALESCE((SELECT TOP 1 c.id FROM dbo.company c WHERE SUBSTRING(c.name, 1, 3) = SUBSTRING(a.text7, 1, 3)), a.companyid),
    a.listvalue1 = CASE WHEN NULLIF(LTRIM(RTRIM(a.listvalue1)), '') IS NULL THEN 'IN USE' ELSE a.listvalue1 END
FROM dbo.asset a
WHERE (a.text6 IS NULL OR LEFT(LTRIM(a.text6),2) <> 'SP' OR LTRIM(a.text6) LIKE 'SP %')
   OR (a.text11 IS NULL OR LEFT(LTRIM(a.text11),2) <> 'SP' OR LTRIM(a.text11) LIKE 'SP %')
   OR (a.lastobservedlocation IS NULL OR LEFT(LTRIM(a.lastobservedlocation),2) <> 'SP' OR LTRIM(a.lastobservedlocation) LIKE 'SP %')
   OR (a.listvalue1 IS NULL OR LTRIM(RTRIM(a.listvalue1)) = '')
   OR (NULLIF(LTRIM(RTRIM(a.text7)), '') IS NOT NULL AND a.companyid NOT IN (
        SELECT id FROM dbo.company WHERE SUBSTRING(name, 1, 3) = SUBSTRING(a.text7, 1, 3)));

/* Link ALL unlinked locationids */
UPDATE a SET a.locationid = l.id FROM dbo.asset a
JOIN dbo.location l ON l.name = 'SP' + LTRIM(CASE WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN SUBSTRING(LTRIM(a.text6),3,500) ELSE a.text6 END)
  AND l.companyid = a.companyid WHERE a.locationid IS NULL;

UPDATE a SET a.locationid = l.id FROM dbo.asset a
JOIN dbo.location l ON l.name = 'SP' + LTRIM(RTRIM(COALESCE(a.text7,'')))
  + CASE WHEN NULLIF(LTRIM(RTRIM(COALESCE(a.text7,''))), '') IS NULL THEN '' ELSE ' ' END
  + LTRIM(CASE WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN SUBSTRING(LTRIM(a.text6),3,500) ELSE a.text6 END)
  AND l.companyid = a.companyid WHERE a.locationid IS NULL;

/* Seed picklist */
IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'IN USE')
    INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'IN USE', 0);
IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'LOST OR STOLEN')
    INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'LOST OR STOLEN', 1);
IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'LOANED OUT')
    INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'LOANED OUT', 2);
IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'TURNED IN')
    INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'TURNED IN', 3);
IF NOT EXISTS (SELECT 1 FROM customfieldvalue WHERE customfieldname = 'asset.listvalue1' AND value = 'OUT OF SERVICE')
    INSERT INTO customfieldvalue (customfieldname, value, displayindex) VALUES ('asset.listvalue1', 'OUT OF SERVICE', 4);

/* Cleanup temp tables */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL DROP TABLE #new_assets;
IF OBJECT_ID('tempdb..#staged_assets') IS NOT NULL DROP TABLE #staged_assets;
IF OBJECT_ID('tempdb..#asset_name_companyid_dupes') IS NOT NULL DROP TABLE #asset_name_companyid_dupes;
IF OBJECT_ID('tempdb..#MissingCompanies') IS NOT NULL DROP TABLE #MissingCompanies;

/* Return summary */
SELECT @loc_inserted AS LocationsInserted, @asset_inserted AS AssetsInserted,
       @asset_updated AS AssetsUpdated, @asset_skipped AS AssetsSkipped,
       @errors AS Errors, (SELECT COUNT(*) FROM dbo.asset) AS TotalAssetsNow;
";
    }
}
