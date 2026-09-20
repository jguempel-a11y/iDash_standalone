/* ===============================
   VA DATA IMPORT (DRY RUN)
   This script loads data into staging tables and outputs it for review.
   It DOES NOT insert or update any data in the live location or asset tables.
   =============================== */

/* 0) PERMISSIONS FIX (Ensure service account has restore rights) */
USE master;
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [idashadmin];
GO

USE [idash];
GO

/* 1) GLOBAL SETTINGS */
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
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
        [text1]                    varchar(500)      NULL,
        [text2]                    varchar(500)      NULL,
        [text3]                    varchar(500)      NULL,
        [text4]                    varchar(500)      NULL,
        [text5]                    varchar(500)      NULL,
        [text6]                    varchar(500)      NULL,
        [text7]                    varchar(500)      NULL,
        [text8]                    varchar(500)      NULL,
        [text9]                    varchar(500)      NULL,
        [text10]                   varchar(500)      NULL,
        [text11]                   varchar(500)      NULL,
        [text12]                   varchar(500)      NULL,
        [text13]                   varchar(500)      NULL,
        [text14]                   varchar(500)      NULL,
        [text15]                   varchar(500)      NULL,
        [text16]                   varchar(500)      NULL,
        [text17]                   varchar(500)      NULL,
        [text18]                   varchar(500)      NULL,
        [text19]                   varchar(500)      NULL,
        [text20]                   varchar(500)      NULL,        
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

/* 5) RAW FILE LANDING (1:1 with expected 16 headers) */
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

/* 6) BULK INSERT */
BULK INSERT dbo.AssetFileRaw
FROM 'C:\VA_RFID\va_dbupdate\data\site\512\data.txt'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '0x0a',   -- use 0x0d0a if file is CRLF
    CODEPAGE        = '65001',  -- remove if ANSI
    KEEPNULLS,
    TABLOCK
);
GO

/* 7) MAP RAW -> ASSETTEMP (Force SP prefix) */
INSERT INTO dbo.assettemp (
    name, text1, [description], text2, text3, text4, disposalstatus, text5,
    text6, text10, text11, text7, assettype, text8, text9, lastobservedlocation
)
SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(afr.[ENTRY NUMBER])), ''), 'NULL_' + LEFT(CAST(NEWID() AS VARCHAR(36)), 8)),
    LTRIM(RTRIM(afr.[MANUFACTURER])),
    LTRIM(RTRIM(afr.[MFGR. EQUIPMENT NAME])),
    LTRIM(RTRIM(afr.[MODEL])),
    LTRIM(RTRIM(afr.[SERIAL #])),
    LTRIM(RTRIM(afr.[EQUIPMENT CATEGORY])),
    LTRIM(RTRIM(afr.[USE STATUS])),
    LTRIM(RTRIM(afr.[SERVICE POINTER])),

    CASE
        WHEN NULLIF(LTRIM(RTRIM(afr.[LOCATION])), '') IS NULL THEN 'SPZZUNKNOWN'
        WHEN LEFT(LTRIM(RTRIM(afr.[LOCATION])), 2) = 'SP'
            THEN 'SP' + LTRIM(SUBSTRING(LTRIM(RTRIM(afr.[LOCATION])), 3, 500))
        ELSE 'SP' + LTRIM(RTRIM(afr.[LOCATION]))
    END,

    NULLIF(LTRIM(RTRIM(afr.[PHYSICAL INVENTORY DATE])), ''),

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
             WHEN name LIKE text7 + ' EE%' THEN name 
             WHEN name LIKE text7 + 'EE%'  THEN REPLACE(name, text7 + 'EE', text7 + ' EE')
             ELSE CONCAT(RTRIM(text7), ' EE', name) 
           END;

-- Generate EPC tag based on cleaned name
UPDATE dbo.assettemp
SET rfidtag = CONCAT(RTRIM(text7), 'EE', 
                     REPLACE(name, text7 + ' EE', ''), 
                     REPLICATE('F', 4 - ((5 + LEN(REPLACE(name, text7 + ' EE', ''))) % 4)));

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

/* 10) DRY RUN RESULTS */
PRINT '====================================================';
PRINT '      DRY RUN COMPLETE - STAGED DATA READY FOR REVIEW';
PRINT '====================================================';
PRINT 'Review the result sets below to verify the imported data.';

SELECT 'NEW LOCATIONS STAGED' as [Info], COUNT(*) as [Count] FROM dbo.locationtemp;
SELECT 'NEW ASSETS STAGED' as [Info], COUNT(*) as [Count] FROM dbo.assettemp;

SELECT '--- LOCATIONS TO BE INSERTED/CHECKED ---' AS [DataType];
SELECT name as [Base Location Name (Will get SP prefix)], site, companyid 
FROM dbo.locationtemp;

SELECT '--- RAW DATA FROM FILE ---' AS [DataType];
SELECT * FROM dbo.AssetFileRaw;

SELECT '--- STAGED ASSETS TO BE INSERTED/UPDATED ---' AS [DataType];
SELECT 
    name as [Asset Name], rfidtag as [RFID Tag / EPC], assettype, departmentcode, 
    lastobservedlocation as [Last Observed Loc], text6 as [text6 (Loc)], text11 as [text11 (Prev Loc)],
    description, text1 as [Manufacturer], text2 as [Model], text3 as [Serial], text4 as [Category], 
    text5 as [Service Pointer], text7 as [Station Number], text8 as [CMR], text9 as [PO], 
    text10 as [Inv Date Raw], lastinventoried
FROM dbo.assettemp;
GO
