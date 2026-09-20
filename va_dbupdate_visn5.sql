/* ==========================================================================
   VA DATA IMPORT — VISN 5 VistA Extract (Multi-Site)
   ==========================================================================

   FILE FORMAT (VISTA_ASSETS_{SITE}.txt)
   ----------------------------------------
   The VA sends one pipe-delimited file per VISN 5 site.
   All 15 canonical EIL columns are now included in each file.

   - Files:        One per site (6 total — see mapping below)
   - Separator:    Pipe (|)
   - Headers:      YES — first row is column headers
   - Skip Rows:    3 (header row, dashes, blank line)
   - FIRSTROW:     4 (adjust if VA changes header format)
   - Line Ending:  LF (0x0a)
   - Encoding:     UTF-8

   SITE FILE MAPPING:
   ┌──────────────────────────┬─────────┬────────────────────┬───────────┐
   │ Filename                 │ Station │ Company Name       │ CompanyID │
   ├──────────────────────────┼─────────┼────────────────────┼───────────┤
   │ VISTA_ASSETS_BAL.txt     │ 512     │ 512 Baltimore      │ 5         │
   │ VISTA_ASSETS_BEC.txt     │ 517     │ 517 Beckley        │ 3         │
   │ VISTA_ASSETS_CLA.txt     │ 540     │ 540 Clarksburg     │ 2         │
   │ VISTA_ASSETS_HUN.txt     │ 581     │ 581 Huntington     │ 4         │
   │ VISTA_ASSETS_MWV.txt     │ 613     │ 613 Martinsburg    │ 6         │
   │ VISTA_ASSETS_WAS.txt     │ 688     │ 688 Washington DC  │ 7         │
   └──────────────────────────┴─────────┴────────────────────┴───────────┘
   NOTE: MWV assumed = 613 Martinsburg. Verify with VA IT.

   COLUMNS (positions 1-15, all now populated):
   ┌─────┬──────────────────────────┬─────────────────────────────────────┐
   │ Pos │ Column Name              │ Maps To                             │
   ├─────┼──────────────────────────┼─────────────────────────────────────┤
   │  1  │ ENTRY NUMBER             │ asset.name ({station} EE{entry})    │
   │  2  │ MANUFACTURER             │ asset.text1                         │
   │  3  │ MFGR. EQUIPMENT NAME     │ asset.description                   │
   │  4  │ MODEL                    │ asset.text2                         │
   │  5  │ SERIAL #                 │ asset.text3                         │
   │  6  │ EQUIPMENT CATEGORY       │ asset.text4                         │
   │  7  │ USE STATUS               │ asset.listvalue1                    │
   │  8  │ SERVICE POINTER          │ asset.text5                         │
   │  9  │ LOCATION                 │ asset.text6 / lastobservedlocation  │
   │ 10  │ PHYSICAL INVENTORY DATE  │ asset.text10 / lastinventoried      │
   │ 11  │ PREVIOUS LOCATION        │ asset.text11                        │
   │ 12  │ STATION NUMBER           │ asset.text7 -> companyid mapping    │
   │ 13  │ CATEGORY STOCK NUMBER    │ asset.assettype                     │
   │ 14  │ CMR                      │ asset.text8                         │
   │ 15  │ PURCHASE ORDER #         │ asset.text9                         │
   └─────┴──────────────────────────┴─────────────────────────────────────┘

   COLUMNS NOT IN FILE (will be NULL):
   - SUB STATION

   WORKBENCH SETTINGS (va_dbupdate_workbench.aspx):
   - Separator:     Pipe (|)
   - Skip Rows:     3
   - File Headers:  UNCHECKED
   - SQL Script:    va_dbupdate_visn5.sql
   NOTE: Workbench processes one file at a time. For multi-site batch
         import, run this script directly in SSMS.

   HISTORY:
   - 2026-07-20: Multi-site update. VA now sends separate files per site
                 (VISTA_ASSETS_{SITE}.txt). All 15 columns now populated.
                 Added BULK INSERT loop with per-file error handling.
   - Rewritten with #ImportStats for cross-batch variable persistence
   - Fixed SET options placement for DELETE on indexed views
   - Maintained all SP normalization and merge logic
   ========================================================================== */
/* 0) PERMISSIONS FIX (Ensure service account has restore rights) */
--USE master;
--GO
--ALTER SERVER ROLE [sysadmin] ADD MEMBER [idashadmin];
--GO

USE [idash];
GO

/* 1) GLOBAL SETTINGS 
   (Must be at the very top to ensure DELETE/INSERT works on indexed views/computed cols) */
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
GO

/* 2) PERSISTENT METRICS STORAGE 
   Variables like @loc_inserted die after 'GO'. We use a temp table instead. */
IF OBJECT_ID('tempdb..#ImportStats') IS NOT NULL DROP TABLE #ImportStats;
CREATE TABLE #ImportStats (
    FilesLoaded INT DEFAULT 0,
    FilesFailed INT DEFAULT 0,
    LocInserted INT DEFAULT 0,
    AssetInserted INT DEFAULT 0,
    AssetSkipped INT DEFAULT 0,
    AssetUpdated INT DEFAULT 0,
    Errors INT DEFAULT 0
);
INSERT INTO #ImportStats DEFAULT VALUES;
GO

/* 3) ENSURE STAGING TABLES EXIST */
IF OBJECT_ID('dbo.locationtemp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.locationtemp (
        [name]            varchar(50)  NOT NULL,
        [site]            varchar(100) NULL,
        [building]        varchar(100) NULL,
        [floor]           varchar(50)  NULL,
        [room]            varchar(100) NULL,
        [description]     varchar(500) NULL,
        [rfidtag]         varchar(50)  NULL,
        [lastmodifiedby]  varchar(50)  NULL,
        [lastinventoried] datetimeoffset(7) NULL,
        [companyid]       int NOT NULL DEFAULT (0)
    );
END;

IF OBJECT_ID('dbo.assettemp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.assettemp (
        [name]                     varchar(50)       NOT NULL,
        [description]              varchar(500)      NULL,
        [rfidtag]                  varchar(50)       NULL,
        [assettype]                varchar(50)       NULL,
        [departmentcode]           varchar(50)       NULL,
        [maxunseentime]            int               NULL,
        [lastobservedlocation]     varchar(50)       NULL,
        [lastobservedtime]         datetimeoffset(7) NULL,
        [checkinstatus]            varchar(50)       NULL,
        [checkedoutto]             varchar(50)       NULL,
        [additionalinformation]    varchar(5000)     NULL,
        --[listvalue1]           varchar(50)       NULL,
        [disposalmethod]           varchar(50)       NULL,
        [disposaldate]             datetimeoffset(7) NULL,
        [disposaldestination]      varchar(50)       NULL,
        [maintenancestartdate]     datetimeoffset(7) NULL,
        [maintenancesingledate]    datetimeoffset(7) NULL,
        [nextmaintenance]          datetimeoffset(7) NULL,
        [date1]                    datetimeoffset(7) NULL,
        [date2]                    datetimeoffset(7) NULL,
        [date3]                    datetimeoffset(7) NULL,
        [date4]                    datetimeoffset(7) NULL,
        [date5]                    datetimeoffset(7) NULL,
        [listvalue1]               varchar(100)      NULL,
        [listvalue2]               varchar(100)      NULL,
        [listvalue3]               varchar(100)      NULL,
        [text1]                    varchar(500)      NULL,  -- MANUFACTURER
        [text2]                    varchar(500)      NULL,  -- MODEL
        [text3]                    varchar(500)      NULL,  -- SERIAL #
        [text4]                    varchar(500)      NULL,  -- EQUIPMENT CATEGORY
        [text5]                    varchar(500)      NULL,  -- SERVICE POINTER
        [text6]                    varchar(500)      NULL,  -- SP + LOCATION
        [text7]                    varchar(500)      NULL,  -- STATION NUMBER
        [text8]                    varchar(500)      NULL,  -- CMR/EIL (from file)
        [text9]                    varchar(500)      NULL,  -- PURCHASE ORDER #
        [text10]                   varchar(500)      NULL,  -- PHYSICAL INVENTORY DATE (raw)
        [text11]                   varchar(500)      NULL,  -- SP + PREVIOUS LOCATION
        [text12]                   varchar(500)      NULL,  -- ENTRY NUMBER
        [text13]                   varchar(500)      NULL,  -- EMPL_ID
        [text14]                   varchar(500)      NULL,  -- SUBSTATION
        [text15]                   varchar(500)      NULL,  -- VISTADATE (FUTURE USE)
        [text16]                   varchar(500)      NULL,  -- LOCATION TAGGED (FOUND)
        [text17]                   varchar(500)      NULL,  -- TAGGED ON DATE
        [text18]                   varchar(500)      NULL,  -- TAGGED
        [text19]                   varchar(500)      NULL,  -- TAG_TYPE
        [text20]                   varchar(500)      NULL,  -- NOTES        
        [maintenancemethod]        varchar(50)       NULL,
        [maintenanceintervalmonths] int              NULL,
        [nearestfixed]             varchar(50)       NULL,
        [lastmodified]             datetimeoffset(7) NULL,
        [locationid]               int               NULL,
        [sensorreadinghistoryid]   int               NULL,
        [alertingactionid]         int               NULL,
        [sensorstatshistoryid]     int               NULL,
        [readerid]                 int               NULL,
        [assetparentid]            int               NULL,
        [assetchildcount]          int               NULL,
        [vtagboxx]                 decimal(18,0)     NULL,
        [vtagboxy]                 decimal(18,0)     NULL,
        [vtagboxwidth]             decimal(18,0)     NULL,
        [vtagboxheight]            decimal(18,0)     NULL,
        [vtagx]                    decimal(18,5)     NULL,
        [vtagy]                    decimal(18,5)     NULL,
        [vtagaccelsensor]          bit               NULL,
        [vtagpositiontype]         varchar(50)       NULL,
        [vtagalgorithmtype]        varchar(50)       NULL,
        [batterylevel]             decimal(18,2)     NULL,
        [vtagid]                   varchar(50)       NULL,
        [vtagz]                    int               NULL,
        [vtaglastseen]             datetimeoffset(7) NULL,
        [vtaglastmoved]            datetimeoffset(7) NULL,
        [filedataid]               int               NULL,
        [created]                  datetimeoffset(7) NULL,
        [lastmodifiedby]           varchar(50)       NULL,
        [latitude]                 decimal(18,7)     NULL,
        [longitude]                decimal(18,7)     NULL,
        [altitude]                 decimal(18,7)     NULL,
        [numberofsatellites]       int               NULL,
        [gpsaccuracy]              int               NULL,
        [lastgpsfix]               datetimeoffset(7) NULL,
        [vtagtype]                 varchar(50)       NULL,
        [parentvtag]               varchar(50)       NULL,
        [missedsatellitefixes]     int               NULL,
        [lastinventoried]          datetimeoffset(7) NULL,
        [vtaggpsdeviceid]          varchar(100)      NULL,
        [vtaggpsappkey]            varchar(100)      NULL,
        [deviceregistered]         bit               NULL,
        [lastmaintenance]          datetimeoffset(7) NULL,
        [companyid]                int               NOT NULL DEFAULT (0),
        [unseennotified]           bit               NULL
    );
END;
GO

/* 4) CLEAR STAGING FOR THIS RUN */
DELETE FROM dbo.locationtemp;
DELETE FROM dbo.assettemp;
GO

/* 5) RAW FILE LANDING (1:1 with file) */
IF OBJECT_ID('dbo.AssetFileRaw', 'U') IS NOT NULL
    DROP TABLE dbo.AssetFileRaw;

CREATE TABLE dbo.AssetFileRaw (
    [ENTRY NUMBER]            nvarchar(500) NULL,
    [MANUFACTURER]            nvarchar(500) NULL,
    [MFGR. EQUIPMENT NAME]    nvarchar(500) NULL,
    [MODEL]                   nvarchar(500) NULL,
    [SERIAL #]                nvarchar(500) NULL,
    [EQUIPMENT CATEGORY]      nvarchar(500) NULL,
    [USE STATUS]              nvarchar(500) NULL,
    [SERVICE POINTER]         nvarchar(500) NULL,
    [LOCATION]                nvarchar(500) NULL,
    [PHYSICAL INVENTORY DATE] nvarchar(500) NULL,
    [PREVIOUS LOCATION]       nvarchar(500) NULL,
    [STATION NUMBER]          nvarchar(500) NULL,
    [CATEGORY STOCK NUMBER]   nvarchar(500) NULL,
    [CMR]                     nvarchar(500) NULL,
    [PURCHASE ORDER #]        nvarchar(500) NULL
    -- SUB STATION removed: not in current VA file format (15 columns only)
);
GO

/* 6) BULK INSERT — ONE FILE PER SITE
   Each VISN 5 site sends a separate file: VISTA_ASSETS_{SITE}.txt
   We load them all into the same AssetFileRaw landing table.
   Uses dynamic SQL because BULK INSERT requires a literal file path.
   If a file is missing or fails, the error is logged and remaining files
   continue to load. */
DECLARE @base_path NVARCHAR(500) = N'\\VHABALAPPAWXV05\DATA\\';
-- FIRSTROW = 4 assumes: row 1 = column headers, row 2 = dashes, row 3 = blank.
-- If the VA changes the header format, adjust this value.
DECLARE @first_row INT = 4;

DECLARE @site_files TABLE (filename NVARCHAR(200));
INSERT INTO @site_files (filename) VALUES
    (N'VISTA_ASSETS_BAL.txt'),
    (N'VISTA_ASSETS_BEC.txt'),
    (N'VISTA_ASSETS_CLA.txt'),
    (N'VISTA_ASSETS_HUN.txt'),
    (N'VISTA_ASSETS_MWV.txt'),
    (N'VISTA_ASSETS_WAS.txt');

DECLARE @fname NVARCHAR(200);
DECLARE @sql NVARCHAR(MAX);
DECLARE @loaded INT = 0;
DECLARE @failed INT = 0;
DECLARE @rc INT;

DECLARE file_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT filename FROM @site_files;
OPEN file_cur;
FETCH NEXT FROM file_cur INTO @fname;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'BULK INSERT dbo.AssetFileRaw
        FROM ''' + @base_path + @fname + N'''
        WITH (
            FIRSTROW = ' + CAST(@first_row AS NVARCHAR(10)) + N',
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR   = ''0x0a'',
            CODEPAGE        = ''65001'',
            KEEPNULLS,
            TABLOCK
        );';

    BEGIN TRY
        EXEC sp_executesql @sql;
        SET @rc = @@ROWCOUNT;
        SET @loaded = @loaded + 1;
        PRINT '  + Loaded: ' + @fname + ' (' + CAST(@rc AS VARCHAR(20)) + ' rows)';
    END TRY
    BEGIN CATCH
        SET @failed = @failed + 1;
        PRINT '  X FAILED: ' + @fname + ' -- ' + ERROR_MESSAGE();
        -- Continue to next file; do not abort entire import
    END CATCH;

    FETCH NEXT FROM file_cur INTO @fname;
END;

CLOSE file_cur;
DEALLOCATE file_cur;

UPDATE #ImportStats SET FilesLoaded = @loaded, FilesFailed = @failed;
PRINT '';
PRINT 'File loading complete: ' + CAST(@loaded AS VARCHAR(10)) + ' loaded, ' + CAST(@failed AS VARCHAR(10)) + ' failed';
GO

/* 7) MAP RAW -> ASSETTEMP (Force SP prefix) */
INSERT INTO dbo.assettemp (
    name, text1, [description], text2, text3, text4, listvalue1, text5,
    text6, text10, text11, text7, assettype, text8, text9, lastobservedlocation
)
SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(afr.[ENTRY NUMBER])), ''), 'NULL_' + LEFT(CAST(NEWID() AS VARCHAR(36)), 8)),
    LTRIM(RTRIM(afr.[MANUFACTURER])),
    LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(afr.[MFGR. EQUIPMENT NAME], '"',''), N' ',''), N' ',''))),
    LTRIM(RTRIM(afr.[MODEL])),
    LTRIM(RTRIM(afr.[SERIAL #])),
    LTRIM(RTRIM(afr.[EQUIPMENT CATEGORY])),
    LTRIM(RTRIM(afr.[USE STATUS])),
    LTRIM(RTRIM(afr.[SERVICE POINTER])),

    /* text6 normalized */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(afr.[LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(RTRIM(afr.[LOCATION])), 2) = 'SP'
            THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[LOCATION])), 3, 500))
        ELSE 'SP' + LTRIM(RTRIM(afr.[LOCATION]))
    END,

    NULLIF(LTRIM(RTRIM(afr.[PHYSICAL INVENTORY DATE])), ''),

    /* text11 normalized */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(afr.[PREVIOUS LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(RTRIM(afr.[PREVIOUS LOCATION])), 2) = 'SP'
            THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[PREVIOUS LOCATION])), 3, 500))
        ELSE 'SP' + LTRIM(RTRIM(afr.[PREVIOUS LOCATION]))
    END,

    LTRIM(RTRIM(afr.[STATION NUMBER])),
    LTRIM(RTRIM(afr.[CATEGORY STOCK NUMBER])),
    LTRIM(RTRIM(afr.[CMR])),
    LTRIM(RTRIM(afr.[PURCHASE ORDER #])),

    /* lastobservedlocation normalized */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(afr.[LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(RTRIM(afr.[LOCATION])), 2) = 'SP'
            THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[LOCATION])), 3, 500))
        ELSE 'SP' + LTRIM(RTRIM(afr.[LOCATION]))
    END
FROM dbo.AssetFileRaw AS afr;
GO

/* 8) COMPUTE FIELDS & NORMALIZE */
-- Compute EPC (rfidtag) and normalized Name
UPDATE dbo.assettemp
SET 
    -- Compute standard name and strip out preexisting "station_number EE" prefix if exists
    name = CASE 
             WHEN name LIKE ISNULL(text7, '') + ' EE%' THEN name 
             WHEN name LIKE ISNULL(text7, '') + 'EE%'  THEN REPLACE(name, ISNULL(text7, '') + 'EE', ISNULL(text7, '') + ' EE')
             ELSE CONCAT(RTRIM(ISNULL(text7, '')), ' EE', name) 
           END;

-- Generate EPC tag based on cleaned name
UPDATE dbo.assettemp
SET rfidtag = CONCAT(RTRIM(ISNULL(text7, '')), 'EE', 
                     REPLACE(name, ISNULL(text7, '') + ' EE', ''), 
                     REPLICATE('F', 4 - ((5 + LEN(REPLACE(name, ISNULL(text7, '') + ' EE', ''))) % 4)));

-- Map CompanyID
UPDATE at
SET at.companyid = c.id
FROM dbo.assettemp at
JOIN dbo.company c
  ON SUBSTRING(at.name,1,3) = SUBSTRING(c.name,1,3);

-- Map companyid for explicit Station Codes in Staging
UPDATE dbo.assettemp
SET companyid =
    CASE text7
        WHEN '517' THEN 3
        WHEN '581' THEN 4
        WHEN '540' THEN 2
        WHEN '512' THEN 5
        WHEN '613' THEN 6
        WHEN '688' THEN 7
        ELSE companyid
    END
WHERE text7 IN ('517','581','540','512','613','688');

-- Normalize Dates
UPDATE dbo.assettemp SET text10 = '01/01/1900' WHERE text10 = 'NULL';

UPDATE dbo.assettemp
SET lastinventoried =
    CASE 
        WHEN ISDATE(text10) = 1
            THEN CONCAT(
                   FORMAT(CONVERT(datetime, text10, 101), 'yyyy-MM-dd'),
                   ' 17:00:00.0000000 +00:00'
                 )
        ELSE '1900-01-01 17:00:00.0000000 +00:00'
    END;

UPDATE dbo.assettemp SET date1 = lastinventoried, date2 = lastinventoried;

-- Double Check SP Values in Staging
UPDATE t
SET t.text6 = CASE
                WHEN t.text6 IS NULL OR LTRIM(RTRIM(t.text6)) = '' THEN 'SPZZUNKNOWN'
                WHEN LEFT(LTRIM(t.text6),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(t.text6),3,500))
                ELSE 'SP' + LTRIM(t.text6)
              END,
    t.text11 = CASE
                WHEN t.text11 IS NULL OR LTRIM(RTRIM(t.text11)) = '' THEN 'SPZZUNKNOWN'
                WHEN LEFT(LTRIM(t.text11),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(t.text11),3,500))
                ELSE 'SP' + LTRIM(t.text11)
              END,
    t.lastobservedlocation = CASE
                WHEN t.lastobservedlocation IS NULL OR LTRIM(RTRIM(t.lastobservedlocation)) = '' THEN 'SPZZUNKNOWN'
                WHEN LEFT(LTRIM(t.lastobservedlocation),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(t.lastobservedlocation),3,500))
                ELSE 'SP' + LTRIM(t.lastobservedlocation)
              END
FROM dbo.assettemp t;
GO

/* 9) STAGE LOCATIONS */
INSERT INTO dbo.locationtemp (name, site, companyid)
SELECT DISTINCT
       LTRIM(SUBSTRING(text6, 3, 500)), -- base w/o 'SP'
       text7,
       companyid
FROM dbo.assettemp;



/* 10) INSERT NEW LOCATIONS (Transaction Safe) */
BEGIN TRY
  BEGIN TRAN;

  DECLARE @Count INT = 0;

  ;WITH src AS (
      SELECT LTRIM(RTRIM(lt.name)) AS base_name, lt.site, lt.companyid
      FROM dbo.locationtemp AS lt
  ),
  shaped AS (
      SELECT
          name_final = 'SP' + base_name,
          site,
          companyid,
          rn = ROW_NUMBER() OVER (
                  PARTITION BY 'SP' + base_name, companyid
                  ORDER BY (SELECT 0)
              )
      FROM src
  )
  INSERT INTO dbo.location (name, site, companyid)
  SELECT s.name_final, s.site, s.companyid
  FROM shaped AS s
  WHERE s.rn = 1
    AND NOT EXISTS (
        SELECT 1
        FROM dbo.location WITH (UPDLOCK, HOLDLOCK)
        WHERE name = s.name_final AND companyid = s.companyid
    );

  SET @Count = @@ROWCOUNT;
  UPDATE #ImportStats SET LocInserted = @Count;

  COMMIT;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK;
  UPDATE #ImportStats SET Errors = Errors + 1;
  THROW;
END CATCH;
GO

/* 11) PREPARE ASSETS (Deduplication) */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL DROP TABLE #new_assets;
IF OBJECT_ID('tempdb..#staged_assets') IS NOT NULL DROP TABLE #staged_assets;
IF OBJECT_ID('tempdb..#asset_name_companyid_dupes') IS NOT NULL DROP TABLE #asset_name_companyid_dupes;

SELECT
    at.*,
    rn = ROW_NUMBER() OVER (PARTITION BY at.name, at.companyid ORDER BY (SELECT 0))
INTO #staged_assets
FROM dbo.assettemp AS at;

SELECT name, companyid, COUNT(*) AS dup_count
INTO #asset_name_companyid_dupes
FROM #staged_assets
GROUP BY name, companyid
HAVING COUNT(*) > 1;

UPDATE #ImportStats
SET AssetSkipped = (SELECT ISNULL(SUM(dup_count - 1), 0) FROM #asset_name_companyid_dupes);

CREATE TABLE #new_assets (rfidtag varchar(50) NOT NULL PRIMARY KEY);
GO

/* 12) INSERT NEW ASSETS */
INSERT INTO dbo.asset (
    name, description, rfidtag, assettype, departmentcode, maxunseentime,
    lastobservedlocation, lastobservedtime, checkinstatus, checkedoutto,
    additionalinformation, disposalmethod, disposaldate, disposaldestination,
    maintenancestartdate, maintenancesingledate, nextmaintenance, date1, date2, date3, date4, date5,
    listvalue1, listvalue2, listvalue3, text1, text2, text3, text4, text5,
    text6, text7, text8, text9, text10, text11, text12, text13, text14, text15, text16, text17, text18, text19, text20,
    maintenancemethod, maintenanceintervalmonths, nearestfixed, lastmodified, locationid,
    sensorreadinghistoryid, alertingactionid, sensorstatshistoryid, readerid,
    assetparentid, assetchildcount, vtagboxx, vtagboxy, vtagboxwidth, vtagboxheight,
    vtagx, vtagy, vtagaccelsensor, vtagpositiontype, vtagalgorithmtype, batterylevel,
    vtagid, vtagz, vtaglastseen, vtaglastmoved, filedataid, created, lastmodifiedby,
    latitude, longitude, altitude, numberofsatellites, gpsaccuracy, lastgpsfix,
    vtagtype, parentvtag, missedsatellitefixes, lastinventoried, vtaggpsdeviceid, vtaggpsappkey,
    deviceregistered, lastmaintenance, companyid, unseennotified
)
OUTPUT inserted.rfidtag INTO #new_assets(rfidtag)
SELECT
    sa.name, sa.description, sa.rfidtag, sa.assettype, sa.departmentcode, sa.maxunseentime,
    sa.lastobservedlocation, sa.lastobservedtime, sa.checkinstatus, sa.checkedoutto,
    sa.additionalinformation, sa.disposalmethod, sa.disposaldate, sa.disposaldestination,
    sa.maintenancestartdate, sa.maintenancesingledate, sa.nextmaintenance,
    sa.date1, sa.date2, sa.date3, sa.date4, sa.date5,
    sa.listvalue1, sa.listvalue2, sa.listvalue3,
    sa.text1, sa.text2, sa.text3, sa.text4, sa.text5, sa.text6, sa.text7, sa.text8, sa.text9, sa.text10,
    sa.text11, sa.text12, sa.text13, sa.text14, sa.text15, sa.text16, sa.text17, sa.text18, sa.text19, sa.text20,
    sa.maintenancemethod, sa.maintenanceintervalmonths, sa.nearestfixed, sa.lastmodified, sa.locationid,
    sa.sensorreadinghistoryid, sa.alertingactionid, sa.sensorstatshistoryid, sa.readerid,
    sa.assetparentid, sa.assetchildcount, sa.vtagboxx, sa.vtagboxy, sa.vtagboxwidth, sa.vtagboxheight,
    sa.vtagx, sa.vtagy, sa.vtagaccelsensor, sa.vtagpositiontype, sa.vtagalgorithmtype,
    sa.batterylevel, sa.vtagid, sa.vtagz, sa.vtaglastseen, sa.vtaglastmoved,
    sa.filedataid, sa.created, sa.lastmodifiedby, sa.latitude, sa.longitude, sa.altitude,
    sa.numberofsatellites, sa.gpsaccuracy, sa.lastgpsfix, sa.vtagtype, sa.parentvtag,
    sa.missedsatellitefixes, sa.lastinventoried, sa.vtaggpsdeviceid, sa.vtaggpsappkey,
    sa.deviceregistered, sa.lastmaintenance, sa.companyid, sa.unseennotified
FROM #staged_assets AS sa
WHERE sa.rn = 1
  AND NOT EXISTS (SELECT 1 FROM dbo.asset AS a WITH (UPDLOCK, HOLDLOCK)
                  WHERE a.name = sa.name AND a.companyid = sa.companyid)
  AND NOT EXISTS (SELECT 1 FROM dbo.asset AS a WITH (UPDLOCK, HOLDLOCK)
                  WHERE a.rfidtag = sa.rfidtag);

UPDATE #ImportStats SET AssetInserted = @@ROWCOUNT;
GO

/* 13) CLEAN DATA & BACKFILL LEGACY */
-- SINGLE-PASS ENFORCE SP PREFIX ON LEGACY DATA
-- To avoid repeated full table scans that cause query timeouts, we do the legacy check in a single pass.
UPDATE a
SET
    a.text6 = CASE
        WHEN a.text6 IS NULL OR LTRIM(RTRIM(a.text6)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text6),3,500))
        ELSE 'SP' + LTRIM(a.text6)
    END,
    a.text11 = CASE
        WHEN a.text11 IS NULL OR LTRIM(RTRIM(a.text11)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.text11),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text11),3,500))
        ELSE 'SP' + LTRIM(a.text11)
    END,
    a.lastobservedlocation = CASE
        WHEN a.lastobservedlocation IS NULL OR LTRIM(RTRIM(a.lastobservedlocation)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.lastobservedlocation),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.lastobservedlocation),3,500))
        ELSE 'SP' + LTRIM(a.lastobservedlocation)
    END,
    -- Also patch legacy Company IDs if they are misassigned
    a.companyid = CASE 
        WHEN a.text7 IN ('517','581','540','512','613','688') THEN
            CASE a.text7
                WHEN '517' THEN 3
                WHEN '581' THEN 4
                WHEN '540' THEN 2
                WHEN '512' THEN 5
                WHEN '613' THEN 6
                WHEN '688' THEN 7
            END
        ELSE a.companyid
    END
FROM dbo.asset a
WHERE (a.text6 IS NULL OR LEFT(LTRIM(a.text6),2) <> 'SP' OR LTRIM(a.text6) LIKE 'SP %')
   OR (a.text11 IS NULL OR LEFT(LTRIM(a.text11),2) <> 'SP' OR LTRIM(a.text11) LIKE 'SP %')
   OR (a.lastobservedlocation IS NULL OR LEFT(LTRIM(a.lastobservedlocation),2) <> 'SP' OR LTRIM(a.lastobservedlocation) LIKE 'SP %')
   OR (a.text7 IN ('517','581','540','512','613','688') AND a.companyid NOT IN (2,3,4,5,6,7));
GO

/* 14) LINK LOCATION IDS */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL
BEGIN
    -- Method 1: Exact match on normalized text6
    UPDATE a
    SET a.locationid = l.id
    FROM dbo.asset a
    JOIN #new_assets na ON na.rfidtag = a.rfidtag
    JOIN dbo.location l
      ON l.name =
          'SP' + LTRIM(
                  CASE
                    WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN SUBSTRING(LTRIM(a.text6),3,500)
                    ELSE a.text6
                  END
                )
      AND l.companyid = a.companyid
    WHERE a.locationid IS NULL;

    -- Method 2: Fallback for 'SP<Site> <Location>' pattern
    UPDATE a
    SET a.locationid = l.id
    FROM dbo.asset a
    JOIN #new_assets na ON na.rfidtag = a.rfidtag
    JOIN dbo.location l
      ON l.name =
          'SP'
          + LTRIM(RTRIM(COALESCE(a.text7,'')))
          + CASE WHEN NULLIF(LTRIM(RTRIM(COALESCE(a.text7,''))), '') IS NULL THEN '' ELSE ' ' END
          + LTRIM(
              CASE
                WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN SUBSTRING(LTRIM(a.text6),3,500)
                ELSE a.text6
              END
            )
      AND l.companyid = a.companyid
    WHERE a.locationid IS NULL;
END
GO

/* 15) HELPERS */
/* ADD COMPANIES */

IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = '540 Clarksburg')
BEGIN
    INSERT INTO dbo.company (name) VALUES ('540 Clarksburg');
END

IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = '517 Beckley')
BEGIN
    INSERT INTO dbo.company (name) VALUES ('517 Beckley');
END

IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = '581 Huntington')
BEGIN
    INSERT INTO dbo.company (name) VALUES ('581 Huntington');
END

IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = '512 Baltimore')
BEGIN
    INSERT INTO dbo.company (name) VALUES ('512 Baltimore');
END

IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = '613 Martinsburg')
BEGIN
    INSERT INTO dbo.company (name) VALUES ('613 Martinsburg');
END

IF NOT EXISTS (SELECT 1 FROM dbo.company WHERE name = '688 Washington DC')
BEGIN
    INSERT INTO dbo.company (name) VALUES ('688 Washington DC');
END

/* 15) FIX COMPANY */
/* Moved to Step 8 (assettemp) and Step 13 (legacy combined pass) to prevent timeouts */

/* 15.5) POPULATE LISTVALUE1 OPTIONS */
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
GO

/* 16) FINAL REPORT */
PRINT '====================================================';
PRINT '      VA DATA IMPORT SUMMARY';
PRINT '====================================================';

DECLARE @FL INT, @FF INT, @L INT, @AI INT, @AU INT, @AS INT, @E INT;
SELECT @FL = FilesLoaded, @FF = FilesFailed, @L = LocInserted, @AI = AssetInserted, @AU = AssetUpdated, @AS = AssetSkipped, @E = Errors FROM #ImportStats;

PRINT ' Files Loaded:          ' + CAST(ISNULL(@FL,0) AS VARCHAR(20));
PRINT ' Files Failed:          ' + CAST(ISNULL(@FF,0) AS VARCHAR(20));
PRINT ' Locations Inserted:    ' + CAST(ISNULL(@L,0) AS VARCHAR(20));
PRINT ' Assets Inserted:       ' + CAST(ISNULL(@AI,0) AS VARCHAR(20));
PRINT ' Assets Updated:        ' + CAST(ISNULL(@AU,0) AS VARCHAR(20));
PRINT ' Assets Skipped:        ' + CAST(ISNULL(@AS,0) AS VARCHAR(20));
PRINT ' Errors:                ' + CAST(ISNULL(@E,0) AS VARCHAR(20));
PRINT '====================================================';

SELECT * FROM #ImportStats;

/* Cleanup */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL DROP TABLE #new_assets;
IF OBJECT_ID('tempdb..#staged_assets') IS NOT NULL DROP TABLE #staged_assets;
IF OBJECT_ID('tempdb..#asset_name_companyid_dupes') IS NOT NULL DROP TABLE #asset_name_companyid_dupes;
IF OBJECT_ID('tempdb..#ImportStats') IS NOT NULL DROP TABLE #ImportStats;
GO