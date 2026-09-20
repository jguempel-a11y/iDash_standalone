/* ===============================
   VA DATA IMPORT (UPSERT & ENRICHMENT)
   - Behavior: INSERTS brand new assets if missing.
   - Behavior: UPDATES existing assets ONLY filling in fields that are currently blank.
   - This prevents overwriting valid, user-modified data.
   =============================== */

/* Removed sysadmin escalations to ensure compatibility with standard web service accounts */

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
    LocInserted INT DEFAULT 0,
    AssetInserted INT DEFAULT 0,
    AssetSkipped INT DEFAULT 0,
    AssetUpdated INT DEFAULT 0,
    Errors INT DEFAULT 0
);
INSERT INTO #ImportStats DEFAULT VALUES;
GO

/* 2.5) PREVIEW CAPTURE LOG */
IF OBJECT_ID('tempdb..#PreviewLog') IS NOT NULL DROP TABLE #PreviewLog;
CREATE TABLE #PreviewLog (
    Action VARCHAR(100),
    Name VARCHAR(100),
    RFID VARCHAR(100),
    Description VARCHAR(500),
    LastObservedLocation VARCHAR(100)
);
GO

/* 3) ENSURE STAGING TABLES EXIST */
IF OBJECT_ID('dbo.locationtemp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.locationtemp (
        [name]            varchar(50)  NOT NULL,
        [site]            varchar(100) NULL,
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
        [text15]                   varchar(500)      NULL,
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
    [CATEGORY STOCK NUMBER]   nvarchar(500) NULL,
    [CMR]                     nvarchar(500) NULL,
    [PURCHASE ORDER #]        nvarchar(500) NULL,
    [TYPE OF ENTRY]           nvarchar(500) NULL
);
GO

/* 6) BULK INSERT */
BULK INSERT dbo.AssetFileRaw
FROM '{{DATAFILE}}'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '0x0d0a',
    CODEPAGE        = '65001',
    KEEPNULLS,
    TABLOCK
);
GO

/* 7) MAP RAW -> ASSETTEMP (Force SP prefix) */
INSERT INTO dbo.assettemp (
    name, text1, [description], text2, text3, text4, disposalstatus, text5,
    text6, text10, text11, text8, text9, lastobservedlocation
)
SELECT
    LTRIM(RTRIM(afr.[ENTRY NUMBER])),
    LTRIM(RTRIM(afr.[MANUFACTURER])),
    LTRIM(RTRIM(afr.[MFGR. EQUIPMENT NAME])),
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
SET rfidtag = CONCAT(RTRIM(text7), 'EE', name, REPLICATE('F', 4 - ((5 + LEN(name)) % 4)));

UPDATE dbo.assettemp
SET name = CONCAT(RTRIM(text7), ' EE', name);

-- Map CompanyID
UPDATE at
SET at.companyid = c.id
FROM dbo.assettemp at
JOIN dbo.company c
  ON SUBSTRING(at.name,1,3) = SUBSTRING(c.name,1,3);

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
GO

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

/* Temp table to capture both rfidtag and preview data from the single INSERT OUTPUT */
IF OBJECT_ID('tempdb..#InsertedAssets') IS NOT NULL DROP TABLE #InsertedAssets;
CREATE TABLE #InsertedAssets (
    rfidtag              varchar(50)  NOT NULL,
    name                 varchar(100) NULL,
    description          varchar(500) NULL,
    lastobservedlocation varchar(100) NULL
);
GO

/* 12) INSERT NEW ASSETS */
INSERT INTO dbo.asset (
    name, description, rfidtag, assettype, departmentcode, maxunseentime,
    lastobservedlocation, lastobservedtime, checkinstatus, checkedoutto,
    additionalinformation, disposalstatus, disposalmethod, disposaldate, disposaldestination,
    maintenancestartdate, maintenancesingledate, nextmaintenance, date1, date2, date3, date4, date5,
    listvalue1, listvalue2, listvalue3, listvalue4, listvalue5, text1, text2, text3, text4, text5,
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
OUTPUT inserted.rfidtag, inserted.name, inserted.description, inserted.lastobservedlocation
INTO #InsertedAssets(rfidtag, name, description, lastobservedlocation)
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

/* Feed #new_assets and #PreviewLog from the captured output */
INSERT INTO #new_assets (rfidtag)
SELECT rfidtag FROM #InsertedAssets;

INSERT INTO #PreviewLog (Action, Name, RFID, Description, LastObservedLocation)
SELECT 'INSERTED', name, rfidtag, description, lastobservedlocation
FROM #InsertedAssets;
GO

/* 12.5) ENRICH EXISTING ASSETS 
   - Fill in missing fields if the staging file has the data, 
   - BUT the target DB row for that asset is NULL or Empty.
*/
UPDATE a
SET 
   [description] = CASE WHEN NULLIF(RTRIM(a.[description]),'') IS NULL AND NULLIF(RTRIM(sa.[description]),'') IS NOT NULL THEN sa.[description] ELSE a.[description] END,
   text1 = CASE WHEN NULLIF(RTRIM(a.text1),'') IS NULL AND NULLIF(RTRIM(sa.text1),'') IS NOT NULL THEN sa.text1 ELSE a.text1 END,
   text2 = CASE WHEN NULLIF(RTRIM(a.text2),'') IS NULL AND NULLIF(RTRIM(sa.text2),'') IS NOT NULL THEN sa.text2 ELSE a.text2 END,
   text3 = CASE WHEN NULLIF(RTRIM(a.text3),'') IS NULL AND NULLIF(RTRIM(sa.text3),'') IS NOT NULL THEN sa.text3 ELSE a.text3 END,
   text4 = CASE WHEN NULLIF(RTRIM(a.text4),'') IS NULL AND NULLIF(RTRIM(sa.text4),'') IS NOT NULL THEN sa.text4 ELSE a.text4 END,
   text5 = CASE WHEN NULLIF(RTRIM(a.text5),'') IS NULL AND NULLIF(RTRIM(sa.text5),'') IS NOT NULL THEN sa.text5 ELSE a.text5 END,
   text6 = CASE WHEN NULLIF(RTRIM(a.text6),'') IS NULL AND NULLIF(RTRIM(sa.text6),'') IS NOT NULL THEN sa.text6 ELSE a.text6 END,
   text7 = CASE WHEN NULLIF(RTRIM(a.text7),'') IS NULL AND NULLIF(RTRIM(sa.text7),'') IS NOT NULL THEN sa.text7 ELSE a.text7 END,
   text8 = CASE WHEN NULLIF(RTRIM(a.text8),'') IS NULL AND NULLIF(RTRIM(sa.text8),'') IS NOT NULL THEN sa.text8 ELSE a.text8 END,
   text9 = CASE WHEN NULLIF(RTRIM(a.text9),'') IS NULL AND NULLIF(RTRIM(sa.text9),'') IS NOT NULL THEN sa.text9 ELSE a.text9 END,
   text10 = CASE WHEN NULLIF(RTRIM(a.text10),'') IS NULL AND NULLIF(RTRIM(sa.text10),'') IS NOT NULL THEN sa.text10 ELSE a.text10 END,
   lastobservedlocation = CASE WHEN NULLIF(RTRIM(a.lastobservedlocation),'') IS NULL AND NULLIF(RTRIM(sa.lastobservedlocation),'') IS NOT NULL THEN sa.lastobservedlocation ELSE a.lastobservedlocation END,
   disposalstatus = CASE WHEN NULLIF(RTRIM(a.disposalstatus),'') IS NULL AND NULLIF(RTRIM(sa.disposalstatus),'') IS NOT NULL THEN sa.disposalstatus ELSE a.disposalstatus END,
   lastmodified = SYSDATETIMEOFFSET()
OUTPUT 'UPDATED (ENRICHED)', inserted.name, inserted.rfidtag, inserted.description, inserted.lastobservedlocation 
INTO #PreviewLog(Action, Name, RFID, Description, LastObservedLocation)
FROM dbo.asset a
JOIN #staged_assets sa 
  ON (a.name = sa.name AND a.companyid = sa.companyid) OR (a.rfidtag = sa.rfidtag)
WHERE sa.rn = 1 
  AND NOT EXISTS (SELECT 1 FROM #new_assets na WHERE na.rfidtag = a.rfidtag) -- Skip the ones we legitimately just bulk-inserted
  AND (
       (NULLIF(RTRIM(a.[description]),'') IS NULL AND NULLIF(RTRIM(sa.[description]),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text1),'') IS NULL AND NULLIF(RTRIM(sa.text1),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text2),'') IS NULL AND NULLIF(RTRIM(sa.text2),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text3),'') IS NULL AND NULLIF(RTRIM(sa.text3),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text4),'') IS NULL AND NULLIF(RTRIM(sa.text4),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text5),'') IS NULL AND NULLIF(RTRIM(sa.text5),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text6),'') IS NULL AND NULLIF(RTRIM(sa.text6),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text7),'') IS NULL AND NULLIF(RTRIM(sa.text7),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text8),'') IS NULL AND NULLIF(RTRIM(sa.text8),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text9),'') IS NULL AND NULLIF(RTRIM(sa.text9),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.text10),'') IS NULL AND NULLIF(RTRIM(sa.text10),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.lastobservedlocation),'') IS NULL AND NULLIF(RTRIM(sa.lastobservedlocation),'') IS NOT NULL) OR
       (NULLIF(RTRIM(a.disposalstatus),'') IS NULL AND NULLIF(RTRIM(sa.disposalstatus),'') IS NOT NULL)
  );

UPDATE #ImportStats SET AssetUpdated = @@ROWCOUNT;
GO

/* 13) CLEAN DATA & BACKFILL LEGACY */
-- Clean descriptions
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL
BEGIN
    UPDATE a
    SET a.[description] = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(a.[description], '"',''), N' ',''), N' ','')))
    FROM dbo.asset AS a
    JOIN #new_assets AS na
      ON na.rfidtag = a.rfidtag
    WHERE a.[description] IS NOT NULL
      AND (a.[description] LIKE '%"%' OR a.[description] LIKE N'% %' OR a.[description] LIKE N'% %');
END

-- Enforce SP prefix on legacy data (text6)
UPDATE a
SET a.text6 =
    CASE
        WHEN a.text6 IS NULL OR LTRIM(RTRIM(a.text6)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.text6),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text6),3,500))
        ELSE 'SP' + LTRIM(a.text6)
    END
FROM dbo.asset a
WHERE a.text6 IS NULL
   OR LEFT(LTRIM(a.text6),2) <> 'SP'
   OR LTRIM(a.text6) LIKE 'SP %';

-- Enforce SP prefix on legacy data (text11)
UPDATE a
SET a.text11 =
    CASE
        WHEN a.text11 IS NULL OR LTRIM(RTRIM(a.text11)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.text11),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.text11),3,500))
        ELSE 'SP' + LTRIM(a.text11)
    END
FROM dbo.asset a
WHERE a.text11 IS NULL
   OR LEFT(LTRIM(a.text11),2) <> 'SP'
   OR LTRIM(a.text11) LIKE 'SP %';

-- Enforce SP prefix on legacy data (lastobservedlocation)
UPDATE a
SET a.lastobservedlocation =
    CASE
        WHEN a.lastobservedlocation IS NULL OR LTRIM(RTRIM(a.lastobservedlocation)) = '' THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(a.lastobservedlocation),2) = 'SP' THEN 'SP' + LTRIM(SUBSTRING(LTRIM(a.lastobservedlocation),3,500))
        ELSE 'SP' + LTRIM(a.lastobservedlocation)
    END
FROM dbo.asset a
WHERE a.lastobservedlocation IS NULL
   OR LEFT(LTRIM(a.lastobservedlocation),2) <> 'SP'
   OR LTRIM(a.lastobservedlocation) LIKE 'SP %';
GO

/* 14) LINK LOCATION IDS */
-- Link newly added OR updated assets, rather than solely relying on the `#new_assets` table.
-- All assets that have text6 but no locationid should be linked.
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
GO

/* 15) HELPERS & SANITY CHECKS */
/* Dynamic company seed: auto-creates a company row for any station number
   found in the import file that does not already have a matching entry.
   Works on every VISN server without modification - no hardcoded site numbers. */
INSERT INTO dbo.company (name)
SELECT DISTINCT LTRIM(RTRIM(at.text7)) + ' Unknown'
FROM dbo.assettemp at
WHERE NULLIF(LTRIM(RTRIM(at.text7)), '') IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM dbo.company c
    WHERE SUBSTRING(c.name, 1, 3) = SUBSTRING(at.text7, 1, 3)
  );

/* 15.5) PREVIEW LOG OUTPUT */
-- Return the first 25 records modified for UI previews
SELECT TOP 25 * FROM #PreviewLog ORDER BY Action ASC, Name ASC;
GO

/* 16) FINAL REPORT */
PRINT '====================================================';
PRINT '      VA FULL DATA ENRICHMENT IMPORT SUMMARY';
PRINT '====================================================';

DECLARE @L INT, @AI INT, @AU INT, @AS INT, @E INT;
SELECT @L = LocInserted, @AI = AssetInserted, @AU = AssetUpdated, @AS = AssetSkipped, @E = Errors FROM #ImportStats;

PRINT ' Locations Inserted:    ' + CAST(ISNULL(@L,0) AS VARCHAR(20));
PRINT ' Assets Inserted:       ' + CAST(ISNULL(@AI,0) AS VARCHAR(20));
PRINT ' Assets Updated/Enriched:' + CAST(ISNULL(@AU,0) AS VARCHAR(20));
PRINT ' Assets Skipped:        ' + CAST(ISNULL(@AS,0) AS VARCHAR(20));
PRINT ' Errors:                ' + CAST(ISNULL(@E,0) AS VARCHAR(20));
PRINT '====================================================';

-- Important: Return results for the C# code to read
SELECT * FROM #ImportStats;

/* Cleanup */
IF OBJECT_ID('tempdb..#new_assets') IS NOT NULL DROP TABLE #new_assets;
IF OBJECT_ID('tempdb..#staged_assets') IS NOT NULL DROP TABLE #staged_assets;
IF OBJECT_ID('tempdb..#asset_name_companyid_dupes') IS NOT NULL DROP TABLE #asset_name_companyid_dupes;
IF OBJECT_ID('tempdb..#ImportStats') IS NOT NULL DROP TABLE #ImportStats;
GO
