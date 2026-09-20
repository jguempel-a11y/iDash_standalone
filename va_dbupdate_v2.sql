/* =================================================================
   VA DATA IMPORT v2 — AUTO-DETECT SEPARATOR EDITION
   =================================================================
   
   This script is the next-generation import script designed for use
   with the Import Workbench (va_dbupdate_workbench.aspx) and for
   automation on VA field servers.
   
   KEY DIFFERENCES FROM va_dbupdate.sql:
   
   1. FIELDTERMINATOR uses the {{FIELDTERMINATOR}} token which is
      replaced at runtime by the workbench or automation engine.
      If running manually, change it to '\t', '|', or ',' as needed.
   
   2. Includes a #PreviewLog table that captures affected records
      for the workbench dry-run preview grid.
   
   3. Includes #ImportStats with column aliases that match the
      workbench C# expectations.
   
   4. Designed for both manual (workbench) and automated use.
      For automation: replace {{DATAFILE}} and {{FIELDTERMINATOR}}
      tokens before execution.
   
   TOKENS (replaced at runtime):
     {{DATAFILE}}          - Full path to the data file
     {{FIELDTERMINATOR}}   - Field separator character (e.g. \t, |, ,)
   
   Created: 2026-07-11
   ================================================================= */

USE [idash];
GO

/* 1) GLOBAL SETTINGS */
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
GO

/* 2) PERSISTENT METRICS STORAGE */
IF OBJECT_ID('tempdb..#ImportStats') IS NOT NULL DROP TABLE #ImportStats;
CREATE TABLE #ImportStats (
    [Locations Inserted]            INT DEFAULT 0,
    [Assets Inserted]               INT DEFAULT 0,
    [Assets Updated (total)]        INT DEFAULT 0,
    [Assets Skipped (duplicates)]   INT DEFAULT 0,
    [Errors]                        INT DEFAULT 0
);
INSERT INTO #ImportStats DEFAULT VALUES;
GO

/* 3) PREVIEW LOG (for workbench dry-run) */
IF OBJECT_ID('tempdb..#PreviewLog') IS NOT NULL DROP TABLE #PreviewLog;
CREATE TABLE #PreviewLog (
    [Action]                VARCHAR(20),
    [Name]                  VARCHAR(100),
    [RFID]                  VARCHAR(100),
    [Description]           VARCHAR(500),
    [LastObservedLocation]  VARCHAR(100),
    [StationNumber]         VARCHAR(50),
    [CompanyID]             INT
);
GO

/* 4) ENSURE STAGING TABLES EXIST */
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
        [disposalstatus]           varchar(50)       NULL,
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
        [text15]                   varchar(500)      NULL,  -- ASSET VALUE
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

/* 5) CLEAR STAGING FOR THIS RUN */
DELETE FROM dbo.locationtemp;
DELETE FROM dbo.assettemp;
GO

/* 6) RAW FILE LANDING (1:1 with file columns) */
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
    [PURCHASE ORDER #]        nvarchar(500) NULL,
    [SUB STATION]             nvarchar(500) NULL
);
GO

/* 7) BULK INSERT
   The FIELDTERMINATOR uses the {{FIELDTERMINATOR}} token which is
   replaced at runtime. For manual execution, change to '\t' or '|'.
   
   AUTOMATION NOTE: When running from a scheduled task or the
   autodbupdate engine, ensure {{DATAFILE}} and {{FIELDTERMINATOR}}
   are replaced before execution. The C# engine does this via
   string replacement before passing to SqlCommand. */
BULK INSERT dbo.AssetFileRaw
FROM '{{DATAFILE}}'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '{{FIELDTERMINATOR}}',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '65001',
    KEEPNULLS,
    TABLOCK
);
GO

/* 7.5) PRE-SEED ANY MISSING COMPANIES */
IF OBJECT_ID('tempdb..#MissingCompanies') IS NOT NULL DROP TABLE #MissingCompanies;
SELECT DISTINCT 
    LTRIM(RTRIM(afr.[STATION NUMBER])) AS StationNumber,
    LTRIM(RTRIM(afr.[STATION NUMBER])) + ' Unknown' AS ExpectedName
INTO #MissingCompanies
FROM dbo.AssetFileRaw afr
WHERE ISNULL(LTRIM(RTRIM(afr.[STATION NUMBER])), '') <> '';

INSERT INTO dbo.company (name)
SELECT DISTINCT mc.ExpectedName
FROM #MissingCompanies mc
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.company c WHERE SUBSTRING(c.name, 1, 3) = mc.StationNumber
);
GO

/* 8) MAP RAW -> ASSETTEMP (Force SP prefix) */
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
    
    /* Default Blank Use Status to IN USE */
    CASE 
        WHEN NULLIF(LTRIM(RTRIM(afr.[USE STATUS])), '') IS NULL THEN 'IN USE'
        ELSE UPPER(LTRIM(RTRIM(afr.[USE STATUS])))
    END,
    
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

/* 9) COMPUTE FIELDS & NORMALIZE */
UPDATE dbo.assettemp
SET 
    name = CASE 
             WHEN name LIKE ISNULL(text7, '') + ' EE%' THEN name 
             WHEN name LIKE ISNULL(text7, '') + 'EE%'  THEN REPLACE(name, ISNULL(text7, '') + 'EE', ISNULL(text7, '') + ' EE')
             ELSE CONCAT(RTRIM(ISNULL(text7, '')), ' EE', name) 
           END;

-- Generate EPC tag based on cleaned name
UPDATE dbo.assettemp SET rfidtag = CONCAT(RTRIM(ISNULL(text7, '')), 'EE', REPLACE(name, ISNULL(text7, '') + ' EE', ''), REPLICATE('F', 4 - ((5 + LEN(REPLACE(name, ISNULL(text7, '') + ' EE', ''))) % 4)));

-- Map CompanyID (Dynamic Mapping based on first 3 digits matching)
UPDATE at
SET at.companyid = COALESCE(c.id, 0)
FROM dbo.assettemp at
LEFT JOIN dbo.company c
  ON SUBSTRING(at.text7,1,3) = SUBSTRING(c.name,1,3);

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

/* 10) STAGE LOCATIONS */
INSERT INTO dbo.locationtemp (name, site, companyid)
SELECT DISTINCT
       LTRIM(SUBSTRING(text6, 3, 500)),
       text7,
       companyid
FROM dbo.assettemp;

/* 11) INSERT NEW LOCATIONS (Transaction Safe) */
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
  UPDATE #ImportStats SET [Locations Inserted] = @Count;

  COMMIT;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK;
  UPDATE #ImportStats SET Errors = Errors + 1;
  THROW;
END CATCH;
GO

/* 12) PREPARE ASSETS (Deduplication) */
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
SET [Assets Skipped (duplicates)] = (SELECT ISNULL(SUM(dup_count - 1), 0) FROM #asset_name_companyid_dupes);

CREATE TABLE #new_assets (rfidtag varchar(50) NOT NULL PRIMARY KEY);
GO

/* 13) INSERT NEW ASSETS */
INSERT INTO dbo.asset (
    name, description, rfidtag, assettype, departmentcode, maxunseentime,
    lastobservedlocation, lastobservedtime, checkinstatus, checkedoutto,
    additionalinformation, disposalstatus, disposalmethod, disposaldate, disposaldestination,
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
    sa.additionalinformation, sa.disposalstatus, sa.disposalmethod, sa.disposaldate, sa.disposaldestination,
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

UPDATE #ImportStats SET [Assets Inserted] = @@ROWCOUNT;

/* 13.5) POPULATE PREVIEW LOG (for workbench dry-run) */
INSERT INTO #PreviewLog ([Action], [Name], [RFID], [Description], [LastObservedLocation], [StationNumber], [CompanyID])
SELECT TOP 25
    'INSERT' AS [Action],
    sa.name,
    sa.rfidtag,
    sa.[description],
    sa.lastobservedlocation,
    sa.text7,
    sa.companyid
FROM #staged_assets sa
INNER JOIN #new_assets na ON na.rfidtag = sa.rfidtag
WHERE sa.rn = 1;

-- Also log skipped (already existed) for preview
INSERT INTO #PreviewLog ([Action], [Name], [RFID], [Description], [LastObservedLocation], [StationNumber], [CompanyID])
SELECT TOP 10
    'SKIP (EXISTS)' AS [Action],
    sa.name,
    sa.rfidtag,
    sa.[description],
    sa.lastobservedlocation,
    sa.text7,
    sa.companyid
FROM #staged_assets sa
WHERE sa.rn = 1
  AND NOT EXISTS (SELECT 1 FROM #new_assets na WHERE na.rfidtag = sa.rfidtag);
GO

/* 14) CLEAN DATA & BACKFILL LEGACY */
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
    a.companyid = COALESCE(
        (SELECT TOP 1 c.id FROM dbo.company c WHERE SUBSTRING(c.name, 1, 3) = SUBSTRING(a.text7, 1, 3)), 
        a.companyid
    ),
    a.listvalue1 = CASE
        WHEN NULLIF(LTRIM(RTRIM(a.listvalue1)), '') IS NULL THEN 'IN USE'
        ELSE a.listvalue1
    END
FROM dbo.asset a
WHERE (a.text6 IS NULL OR LEFT(LTRIM(a.text6),2) <> 'SP' OR LTRIM(a.text6) LIKE 'SP %')
   OR (a.text11 IS NULL OR LEFT(LTRIM(a.text11),2) <> 'SP' OR LTRIM(a.text11) LIKE 'SP %')
   OR (a.lastobservedlocation IS NULL OR LEFT(LTRIM(a.lastobservedlocation),2) <> 'SP' OR LTRIM(a.lastobservedlocation) LIKE 'SP %')
   OR (a.listvalue1 IS NULL OR LTRIM(RTRIM(a.listvalue1)) = '')
   OR (NULLIF(LTRIM(RTRIM(a.text7)), '') IS NOT NULL AND a.companyid NOT IN (
        SELECT id FROM dbo.company WHERE SUBSTRING(name, 1, 3) = SUBSTRING(a.text7, 1, 3)
   ));
GO

/* 15) LINK LOCATION IDS */
BEGIN
    -- Method 1: Exact match on normalized text6
    UPDATE a
    SET a.locationid = l.id
    FROM dbo.asset a
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

/* 16) POPULATE LISTVALUE1 OPTIONS */
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

/* 17) FINAL REPORT */
PRINT '====================================================';
PRINT '      VA DATA IMPORT v2 SUMMARY';
PRINT '====================================================';

DECLARE @L INT, @AI INT, @AU INT, @AS INT, @E INT;
SELECT @L = [Locations Inserted], @AI = [Assets Inserted], @AU = [Assets Updated (total)], @AS = [Assets Skipped (duplicates)], @E = [Errors] FROM #ImportStats;

PRINT ' Locations Inserted:    ' + CAST(ISNULL(@L,0) AS VARCHAR(20));
PRINT ' Assets Inserted:       ' + CAST(ISNULL(@AI,0) AS VARCHAR(20));
PRINT ' Assets Updated:        ' + CAST(ISNULL(@AU,0) AS VARCHAR(20));
PRINT ' Assets Skipped:        ' + CAST(ISNULL(@AS,0) AS VARCHAR(20));
PRINT ' Errors:                ' + CAST(ISNULL(@E,0) AS VARCHAR(20));
PRINT '====================================================';

/* Return stats for workbench C# */
SELECT * FROM #ImportStats;
GO

/* 18) PREVIEW LOG RESULTS (for workbench dry-run grid) */
SELECT * FROM #PreviewLog;
GO

/* 19) CLEANUP */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL DROP TABLE #new_assets;
IF OBJECT_ID('tempdb..#staged_assets') IS NOT NULL DROP TABLE #staged_assets;
IF OBJECT_ID('tempdb..#asset_name_companyid_dupes') IS NOT NULL DROP TABLE #asset_name_companyid_dupes;
IF OBJECT_ID('tempdb..#MissingCompanies') IS NOT NULL DROP TABLE #MissingCompanies;
IF OBJECT_ID('tempdb..#ImportStats') IS NOT NULL DROP TABLE #ImportStats;
IF OBJECT_ID('tempdb..#PreviewLog') IS NOT NULL DROP TABLE #PreviewLog;
GO
