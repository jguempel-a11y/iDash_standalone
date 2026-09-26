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

namespace iDash
{
    public partial class va_data_import : System.Web.UI.Page
    {
        private string ConnStr
        {
            get
            {
                var cs = ConfigurationManager.ConnectionStrings["iDash"];
                return (cs == null) ? "" : cs.ConnectionString;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                PanelResults.Visible = false;
                PanelPreview.Visible = false;
            }
        }

        // ── Preview: parse file and show first 20 rows ──
        protected void BtnPreview_Click(object sender, EventArgs e)
        {
            LitStatus.Text = "";
            PanelResults.Visible = false;
            PanelPreview.Visible = false;

            if (!FileUploadData.HasFile)
            {
                LitStatus.Text = "<div class='msg msg-err'>No file selected. Choose a tab-delimited .txt file.</div>";
                return;
            }

            try
            {
                string content = Encoding.UTF8.GetString(FileUploadData.FileBytes);
                var lines = content.Replace("\r", "").Split('\n')
                                   .Where(l => !string.IsNullOrWhiteSpace(l)).ToArray();

                if (lines.Length < 2)
                {
                    LitStatus.Text = "<div class='msg msg-err'>File must have a header row and at least one data row.</div>";
                    return;
                }

                // Parse header
                var headers = lines[0].Split('\t');
                var dt = new DataTable();
                foreach (var h in headers)
                    dt.Columns.Add(h.Trim());

                // Parse first 20 data rows
                int previewCount = Math.Min(20, lines.Length - 1);
                for (int i = 1; i <= previewCount; i++)
                {
                    var fields = lines[i].Split('\t');
                    var row = dt.NewRow();
                    for (int j = 0; j < dt.Columns.Count; j++)
                        row[j] = (j < fields.Length) ? fields[j].Trim() : "";
                    dt.Rows.Add(row);
                }

                GridPreview.DataSource = dt;
                GridPreview.DataBind();
                PanelPreview.Visible = true;

                int totalRows = lines.Length - 1;
                string forceSiteInfo = RdoForceSite.Checked
                    ? " | Force Site: <strong>" + Server.HtmlEncode(TxtSiteNumber.Text.Trim()) + "</strong>"
                    : " | Mode: <strong>Auto-detect</strong>";

                LitStatus.Text = string.Format(
                    "<div class='msg msg-ok'>Parsed <strong>{0:N0}</strong> data rows, <strong>{1}</strong> columns. Showing first {2}.{3}</div>",
                    totalRows, dt.Columns.Count, previewCount, forceSiteInfo);
            }
            catch (Exception ex)
            {
                LitStatus.Text = "<div class='msg msg-err'>Parse error: " + Server.HtmlEncode(ex.Message) + "</div>";
            }
        }

        // ── Import: full pipeline ──
        protected void BtnImport_Click(object sender, EventArgs e)
        {
            LitStatus.Text = "";
            PanelResults.Visible = false;
            PanelPreview.Visible = false;

            if (!FileUploadData.HasFile)
            {
                LitStatus.Text = "<div class='msg msg-err'>No file selected. Choose a tab-delimited .txt file.</div>";
                return;
            }

            string forceSite = "";
            if (RdoForceSite.Checked)
            {
                forceSite = TxtSiteNumber.Text.Trim();
                if (string.IsNullOrEmpty(forceSite))
                {
                    LitStatus.Text = "<div class='msg msg-err'>Force Site mode selected but no station number entered.</div>";
                    return;
                }
            }

            var log = new StringBuilder();
            int dataRows = 0;

            try
            {
                // ── Step 1: Parse file into DataTable ──
                log.Append("<div class='step step-ok'>Step 1: Parsing file...</div>");

                string content = Encoding.UTF8.GetString(FileUploadData.FileBytes);
                var lines = content.Replace("\r", "").Split('\n')
                                   .Where(l => !string.IsNullOrWhiteSpace(l)).ToArray();

                if (lines.Length < 2)
                {
                    LitStatus.Text = "<div class='msg msg-err'>File must have a header row and at least one data row.</div>";
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

                log.AppendFormat("<div class='step step-ok'>Step 1: Parsed <strong>{0:N0}</strong> data rows ({1} columns){2}</div>",
                    dataRows, dt.Columns.Count,
                    hasSubStation ? " (with SUB STATION)" : "");

                // ── Step 2: Connect and create staging table ──
                using (var conn = new SqlConnection(ConnStr))
                {
                    conn.Open();
                    log.Append("<div class='step step-ok'>Step 2: Connected to SQL Server</div>");

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
                    log.Append("<div class='step step-ok'>Step 2: Staging tables prepared</div>");

                    // ── Step 3: SqlBulkCopy ──
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
                    log.AppendFormat("<div class='step step-ok'>Step 3: Streamed <strong>{0:N0}</strong> rows to SQL Server</div>", sqlCount);

                    // ── Step 4: Run merge SQL ──
                    log.Append("<div class='step step-run'>Step 4: Running merge logic...</div>");

                    // Build the force-site clause
                    string forceSiteClause = "";
                    if (!string.IsNullOrEmpty(forceSite))
                    {
                        forceSiteClause = string.Format(
                            "UPDATE dbo.assettemp SET text7 = '{0}' WHERE text7 IS NULL OR LTRIM(RTRIM(text7)) = '';",
                            forceSite.Replace("'", "''"));
                    }

                    string mergeSql = BuildMergeSql(forceSiteClause);
                    cmd.CommandText = mergeSql;
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

                            LitLocInserted.Text = locIns.ToString("N0");
                            LitAssetsInserted.Text = assIns.ToString("N0");
                            LitAssetsUpdated.Text = assUpd.ToString("N0");
                            LitAssetsSkipped.Text = assSkp.ToString("N0");
                            LitErrors.Text = errors.ToString("N0");
                            LitTotalAssets.Text = total.ToString("N0");

                            PanelResults.Visible = true;

                            string modeLabel = string.IsNullOrEmpty(forceSite)
                                ? "Auto-detect"
                                : "Force Site " + Server.HtmlEncode(forceSite);

                            log.AppendFormat(
                                "<div class='step step-ok'>Step 4: Merge complete ({0}) - {1:N0} assets inserted, {2:N0} locations created</div>",
                                modeLabel, assIns, locIns);

                            if (errors > 0)
                                log.AppendFormat("<div class='step step-err'>Warning: {0} error(s) during import</div>", errors);
                        }
                    }

                    log.Append("<div class='step step-ok'><strong>Import complete.</strong></div>");
                }
            }
            catch (Exception ex)
            {
                log.AppendFormat("<div class='step step-err'>Error: {0}</div>", Server.HtmlEncode(ex.Message));
                if (ex.InnerException != null)
                    log.AppendFormat("<div class='step step-err'>Inner: {0}</div>", Server.HtmlEncode(ex.InnerException.Message));
            }

            LitStatus.Text = log.ToString();
        }

        /// <summary>
        /// Builds the complete merge SQL matching va_dbupdate.sql logic.
        /// </summary>
        private string BuildMergeSql(string forceSiteClause)
        {
            // The forceSiteClause is injected between the RAW->assettemp INSERT and the name computation
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
        [listvalue1] varchar(100) NULL, [listvalue2] varchar(100) NULL, [listvalue3] varchar(100) NULL,
        [listvalue4] varchar(100) NULL, [listvalue5] varchar(100) NULL,
        [text1] varchar(500) NULL, [text2] varchar(500) NULL, [text3] varchar(500) NULL,
        [text4] varchar(500) NULL, [text5] varchar(500) NULL, [text6] varchar(500) NULL,
        [text7] varchar(500) NULL, [text8] varchar(500) NULL, [text9] varchar(500) NULL,
        [text10] varchar(500) NULL, [text11] varchar(500) NULL, [text12] varchar(500) NULL,
        [text13] varchar(500) NULL, [text14] varchar(500) NULL, [text15] varchar(500) NULL,
        [text16] varchar(500) NULL, [text17] varchar(500) NULL, [text18] varchar(500) NULL,
        [text19] varchar(500) NULL, [text20] varchar(500) NULL,
        [maintenancemethod] varchar(50) NULL, [maintenanceintervalmonths] int NULL,
        [nearestfixed] varchar(50) NULL, [lastmodified] datetimeoffset(7) NULL,
        [locationid] int NULL, [created] datetimeoffset(7) NULL, [lastmodifiedby] varchar(50) NULL,
        [lastinventoried] datetimeoffset(7) NULL, [companyid] int NOT NULL DEFAULT(0)
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
    LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(afr.[MFGR. EQUIPMENT NAME], '""',''), N' ',''), N' ',''))),
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
    a.lastmodifiedby = 'iDash Import'
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
}
