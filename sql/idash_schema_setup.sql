-- =============================================================================
-- iDash Database Setup & Schema Deployment Script
-- Product Platform: iDash Standalone (RFID Asset Tracking & Dashboard)
-- Intellectual Property: iDash Platform
-- Generated: 2026-09-25 21:14:49 UTC
-- =============================================================================

SET NOCOUNT ON;
GO

-- Table: dbo.[company]
IF OBJECT_ID('dbo.[company]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[company] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] varchar(50) NOT NULL
    );
    PRINT 'Created table: dbo.[company]';
END
GO

-- Table: dbo.[location]
IF OBJECT_ID('dbo.[location]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[location] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] varchar(50) NOT NULL,
        [site] varchar(100) NULL,
        [building] varchar(100) NULL,
        [floor] varchar(50) NULL,
        [room] varchar(100) NULL,
        [description] varchar(500) NULL,
        [rfidtag] varchar(50) NULL,
        [lastmodifiedby] varchar(50) NULL,
        [lastinventoried] datetimeoffset NULL,
        [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[location]';
END
GO

-- Table: dbo.[asset]
IF OBJECT_ID('dbo.[asset]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[asset] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] varchar(50) NOT NULL,
        [description] varchar(500) NULL,
        [rfidtag] varchar(50) NULL,
        [assettype] varchar(50) NULL,
        [departmentcode] varchar(50) NULL,
        [maxunseentime] int NULL,
        [lastobservedlocation] varchar(50) NULL,
        [lastobservedtime] datetimeoffset NULL DEFAULT (sysdatetimeoffset()),
        [checkinstatus] varchar(50) NULL,
        [checkedoutto] varchar(50) NULL,
        [additionalinformation] varchar(5000) NULL,
        [disposalstatus] varchar(50) NULL DEFAULT ('In Service'),
        [disposalmethod] varchar(50) NULL,
        [disposaldate] datetimeoffset NULL,
        [disposaldestination] varchar(50) NULL,
        [maintenancestartdate] datetimeoffset NULL,
        [maintenancesingledate] datetimeoffset NULL,
        [nextmaintenance] date NULL,
        [date1] datetimeoffset NULL,
        [date2] datetimeoffset NULL,
        [date3] datetimeoffset NULL,
        [date4] datetimeoffset NULL,
        [date5] datetimeoffset NULL,
        [listvalue1] varchar(100) NULL,
        [listvalue2] varchar(100) NULL,
        [listvalue3] varchar(100) NULL,
        [listvalue4] varchar(100) NULL,
        [listvalue5] varchar(100) NULL,
        [text1] varchar(500) NULL,
        [text2] varchar(500) NULL,
        [text3] varchar(500) NULL,
        [text4] varchar(500) NULL,
        [text5] varchar(500) NULL,
        [text6] varchar(500) NULL,
        [text7] varchar(500) NULL,
        [text8] varchar(500) NULL,
        [text9] varchar(500) NULL,
        [text10] varchar(500) NULL,
        [text11] varchar(500) NULL,
        [text12] varchar(500) NULL,
        [text13] varchar(500) NULL,
        [text14] varchar(500) NULL,
        [text15] varchar(500) NULL,
        [text16] varchar(500) NULL,
        [text17] varchar(500) NULL,
        [text18] varchar(500) NULL,
        [text19] varchar(500) NULL,
        [text20] varchar(500) NULL,
        [maintenancemethod] varchar(50) NULL,
        [maintenanceintervalmonths] int NULL,
        [nearestfixed] varchar(50) NULL,
        [lastmodified] datetimeoffset NULL DEFAULT (sysdatetimeoffset()),
        [locationid] int NULL,
        [created] datetimeoffset NULL DEFAULT (sysdatetimeoffset()),
        [lastmodifiedby] varchar(50) NULL,
        [lastinventoried] datetimeoffset NULL,
        [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[asset]';
END
GO

-- Table: dbo.[locationhistory]
IF OBJECT_ID('dbo.[locationhistory]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[locationhistory] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [timeseen] datetimeoffset NOT NULL,
        [assetid] int NOT NULL,
        [locationid] int NOT NULL,
        [companyid] int NOT NULL,
        [timeleft] datetimeoffset NULL
    );
    PRINT 'Created table: dbo.[locationhistory]';
END
GO

-- Table: dbo.[sysuser]
IF OBJECT_ID('dbo.[sysuser]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[sysuser] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [username] nvarchar(50) NOT NULL,
        [password] nvarchar(MAX) NULL,
        [firstname] nvarchar(50) NULL,
        [lastname] nvarchar(50) NULL,
        [email] nvarchar(50) NULL,
        [phone] nvarchar(50) NULL,
        [companyid] int NULL,
        [usertype] varchar(500) NULL
    );
    PRINT 'Created table: dbo.[sysuser]';
END
GO

-- Table: dbo.[template]
IF OBJECT_ID('dbo.[template]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[template] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] varchar(50) NOT NULL,
        [templatetype] varchar(50) NOT NULL,
        [filename] varchar(500) NOT NULL,
        [usewithservice] varchar(50) NULL,
        [printmethod] varchar(50) NULL,
        [companyid] int NOT NULL,
        [printclientid] int NULL
    );
    PRINT 'Created table: dbo.[template]';
END
GO

-- Table: dbo.[printclient]
IF OBJECT_ID('dbo.[printclient]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[printclient] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyid] int NOT NULL,
        [name] varchar(500) NOT NULL,
        [username] varchar(500) NOT NULL,
        [password] varchar(500) NOT NULL,
        [machinename] varchar(500) NULL,
        [lastseen] datetimeoffset NULL
    );
    PRINT 'Created table: dbo.[printclient]';
END
GO

-- Table: dbo.[printclientcompany]
IF OBJECT_ID('dbo.[printclientcompany]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[printclientcompany] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [printclientid] int NOT NULL,
        [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[printclientcompany]';
END
GO

-- Table: dbo.[printjob]
IF OBJECT_ID('dbo.[printjob]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[printjob] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [recordid] int NOT NULL,
        [tablename] varchar(50) NOT NULL,
        [templateid] int NOT NULL,
        [generatedrfid] varchar(50) NULL,
        [completed] bit NOT NULL,
        [created] datetimeoffset NOT NULL,
        [companyid] int NOT NULL,
        [message] varchar(5000) NULL,
        [usewithservice] varchar(500) NULL
    );
    PRINT 'Created table: dbo.[printjob]';
END
GO

-- Table: dbo.[reader]
IF OBJECT_ID('dbo.[reader]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[reader] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] varchar(50) NOT NULL,
        [readermodel] varchar(50) NOT NULL,
        [devicesettings] varchar(1000) NULL,
        [connectionstatus] varchar(50) NULL,
        [locationid] int NULL,
        [lastmodifiedby] varchar(50) NULL,
        [physicalid] varchar(50) NULL,
        [lastseen] datetimeoffset NULL,
        [companyid] int NOT NULL,
        [ipaddress] varchar(500) NULL,
        [username] varchar(500) NULL,
        [password] varchar(500) NULL,
        [lastmodified] datetimeoffset NULL,
        [mqttcontroltopic] varchar(500) NULL
    );
    PRINT 'Created table: dbo.[reader]';
END
GO

-- Table: dbo.[antenna]
IF OBJECT_ID('dbo.[antenna]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[antenna] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [locationid] int NOT NULL,
        [readerid] int NOT NULL,
        [number] int NOT NULL,
        [lastmodifiedby] varchar(50) NULL,
        [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[antenna]';
END
GO

-- Table: dbo.[applicationsetting]
IF OBJECT_ID('dbo.[applicationsetting]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[applicationsetting] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [version] varchar(50) NULL,
        [type] varchar(1000) NULL,
        [licensekey] varchar(1000) NULL,
        [company] varchar(50) NULL,
        [lastmodifiedby] varchar(50) NULL,
        [authenticationserver] varchar(5000) NULL,
        [mqttenabled] bit NOT NULL DEFAULT ((0)),
        [mqttlocation] varchar(100) NULL,
        [mqttusername] varchar(100) NULL,
        [mqttpassword] varchar(100) NULL,
        [webclientid] varchar(5000) NULL,
        [webclientsecret] varchar(5000) NULL,
        [enableglobaleventmessages] bit NOT NULL DEFAULT ((0)),
        [enableglobalalarmmessages] bit NOT NULL DEFAULT ((0)),
        [enableglobalgatewaymessages] bit NOT NULL DEFAULT ((0)),
        [enableglobalsensorreadingmessages] bit NOT NULL DEFAULT ((0)),
        [enableglobaltagmovementmessages] bit NOT NULL DEFAULT ((0)),
        [enableglobaltagobservationmessages] bit NOT NULL DEFAULT ((0))
    );
    PRINT 'Created table: dbo.[applicationsetting]';
END
GO

-- Table: dbo.[clientapp]
IF OBJECT_ID('dbo.[clientapp]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[clientapp] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [clientid] varchar(500) NOT NULL,
        [granttype] varchar(50) NOT NULL,
        [secret] varchar(5000) NOT NULL,
        [allowRefreshTokens] bit NOT NULL,
        [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[clientapp]';
END
GO

-- Table: dbo.[customfield]
IF OBJECT_ID('dbo.[customfield]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[customfield] (
        [name] varchar(50) NOT NULL,
        [value] varchar(500) NOT NULL,
        [display] bit NOT NULL,
        [displayindex] int NOT NULL,
        [uieditable] bit NOT NULL,
        [handhelddisplay] bit NOT NULL,
        [handheldvalue] varchar(50) NOT NULL,
        [handhelddisplayindex] int NOT NULL,
        [datatype] varchar(50) NOT NULL
    );
    PRINT 'Created table: dbo.[customfield]';
END
GO

-- Table: dbo.[customfieldvalue]
IF OBJECT_ID('dbo.[customfieldvalue]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[customfieldvalue] (
        [customfieldname] varchar(50) NOT NULL,
        [value] varchar(50) NOT NULL,
        [displayindex] int NOT NULL
    );
    PRINT 'Created table: dbo.[customfieldvalue]';
END
GO

-- Table: dbo.[scanner]
IF OBJECT_ID('dbo.[scanner]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[scanner] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyname] varchar(100) NOT NULL,
        [deviceid] varchar(100) NOT NULL,
        [inactive] bit NOT NULL,
        [description] varchar(500) NULL,
        [lastseen] datetimeoffset NULL
    );
    PRINT 'Created table: dbo.[scanner]';
END
GO

-- Table: dbo.[mqttclient]
IF OBJECT_ID('dbo.[mqttclient]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[mqttclient] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [companyid] int NOT NULL,
        [username] varchar(500) NOT NULL,
        [password] varchar(500) NOT NULL,
        [accessgatewaymessages] bit NOT NULL,
        [accesstagmovements] bit NOT NULL,
        [accesstagobservations] bit NOT NULL,
        [accessevents] bit NOT NULL,
        [accessalarms] bit NOT NULL
    );
    PRINT 'Created table: dbo.[mqttclient]';
END
GO

-- Table: dbo.[serverstatus]
IF OBJECT_ID('dbo.[serverstatus]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[serverstatus] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [name] varchar(50) NOT NULL,
        [lastseen] datetimeoffset NOT NULL,
        [version] varchar(50) NOT NULL,
        [companyid] int NOT NULL,
        [servertype] varchar(500) NULL
    );
    PRINT 'Created table: dbo.[serverstatus]';
END
GO

-- Table: dbo.[EnnxLiveSession]
IF OBJECT_ID('dbo.[EnnxLiveSession]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[EnnxLiveSession] (
        [SessionId] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Station] varchar(50) NOT NULL,
        [CreatedBy] varchar(100) NULL,
        [StartedUtc] datetime NOT NULL,
        [EndedUtc] datetime NULL,
        [Summary] nvarchar(MAX) NULL,
        [JsonPayload] nvarchar(MAX) NULL,
        [EnnxText] nvarchar(MAX) NULL,
        [CreatedLocal] datetime NULL
    );
    PRINT 'Created table: dbo.[EnnxLiveSession]';
END
GO

-- Table: dbo.[AssetSync]
IF OBJECT_ID('dbo.[AssetSync]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[AssetSync] (
        [id] nvarchar(500) NULL,
        [name] nvarchar(500) NULL,
        [description] nvarchar(500) NULL,
        [rfidtag] nvarchar(500) NULL,
        [assettype] nvarchar(500) NULL,
        [lastobservedlocation] nvarchar(500) NULL,
        [lastobservedtime] nvarchar(500) NULL,
        [checkinstatus] nvarchar(500) NULL,
        [text1] nvarchar(500) NULL,
        [text2] nvarchar(500) NULL,
        [text3] nvarchar(500) NULL,
        [text4] nvarchar(500) NULL,
        [text5] nvarchar(500) NULL,
        [text6] nvarchar(500) NULL,
        [text7] nvarchar(500) NULL,
        [text8] nvarchar(500) NULL,
        [text9] nvarchar(500) NULL,
        [text10] nvarchar(500) NULL,
        [text11] nvarchar(500) NULL,
        [text12] nvarchar(500) NULL,
        [text19] nvarchar(500) NULL,
        [text20] nvarchar(500) NULL,
        [companyid] nvarchar(500) NULL,
        [lastinventoried] nvarchar(500) NULL,
        [lastmodified] nvarchar(500) NULL,
        [listvalue1] nvarchar(500) NULL
    );
    PRINT 'Created table: dbo.[AssetSync]';
END
GO

-- Table: dbo.[AssetFileRaw]
IF OBJECT_ID('dbo.[AssetFileRaw]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[AssetFileRaw] (
        [ENTRY NUMBER] nvarchar(500) NULL,
        [MANUFACTURER] nvarchar(500) NULL,
        [MFGR. EQUIPMENT NAME] nvarchar(500) NULL,
        [MODEL] nvarchar(500) NULL,
        [SERIAL #] nvarchar(500) NULL,
        [EQUIPMENT CATEGORY] nvarchar(500) NULL,
        [USE STATUS] nvarchar(500) NULL,
        [SERVICE POINTER] nvarchar(500) NULL,
        [LOCATION] nvarchar(500) NULL,
        [PHYSICAL INVENTORY DATE] nvarchar(500) NULL,
        [PREVIOUS LOCATION] nvarchar(500) NULL,
        [STATION NUMBER] nvarchar(500) NULL,
        [CATEGORY STOCK NUMBER] nvarchar(500) NULL,
        [CMR] nvarchar(500) NULL,
        [PURCHASE ORDER #] nvarchar(500) NULL,
        [SUB STATION] nvarchar(500) NULL
    );
    PRINT 'Created table: dbo.[AssetFileRaw]';
END
GO

-- Table: dbo.[LocationImportRaw]
IF OBJECT_ID('dbo.[LocationImportRaw]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[LocationImportRaw] (
        [rawname] nvarchar(500) NULL
    );
    PRINT 'Created table: dbo.[LocationImportRaw]';
END
GO

-- Table: dbo.[assettemp]
IF OBJECT_ID('dbo.[assettemp]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[assettemp] (
        [name] varchar(50) NULL,
        [description] varchar(500) NULL,
        [rfidtag] varchar(50) NULL,
        [assettype] varchar(50) NULL,
        [departmentcode] varchar(50) NULL,
        [maxunseentime] int NULL,
        [lastobservedlocation] varchar(50) NULL,
        [lastobservedtime] datetimeoffset NULL,
        [checkinstatus] varchar(50) NULL,
        [checkedoutto] varchar(50) NULL,
        [additionalinformation] varchar(5000) NULL,
        [disposalstatus] varchar(50) NULL,
        [disposalmethod] varchar(50) NULL,
        [disposaldate] datetimeoffset NULL,
        [disposaldestination] varchar(50) NULL,
        [maintenancestartdate] datetimeoffset NULL,
        [maintenancesingledate] datetimeoffset NULL,
        [nextmaintenance] datetimeoffset NULL,
        [date1] datetimeoffset NULL,
        [date2] datetimeoffset NULL,
        [date3] datetimeoffset NULL,
        [date4] datetimeoffset NULL,
        [date5] datetimeoffset NULL,
        [listvalue1] varchar(100) NULL,
        [listvalue2] varchar(100) NULL,
        [listvalue3] varchar(100) NULL,
        [listvalue4] varchar(100) NULL,
        [listvalue5] varchar(100) NULL,
        [text1] varchar(500) NULL,
        [text2] varchar(500) NULL,
        [text3] varchar(500) NULL,
        [text4] varchar(500) NULL,
        [text5] varchar(500) NULL,
        [text6] varchar(500) NULL,
        [text7] varchar(500) NULL,
        [text8] varchar(500) NULL,
        [text9] varchar(500) NULL,
        [text10] varchar(500) NULL,
        [text11] varchar(500) NULL,
        [text12] varchar(500) NULL,
        [text13] varchar(500) NULL,
        [text14] varchar(500) NULL,
        [text15] varchar(500) NULL,
        [text16] varchar(500) NULL,
        [text17] varchar(500) NULL,
        [text18] varchar(500) NULL,
        [text19] varchar(500) NULL,
        [text20] varchar(500) NULL,
        [maintenancemethod] varchar(50) NULL,
        [maintenanceintervalmonths] int NULL,
        [nearestfixed] varchar(50) NULL,
        [lastmodified] datetimeoffset NULL,
        [locationid] int NULL,
        [created] datetimeoffset NULL,
        [lastmodifiedby] varchar(50) NULL,
        [lastinventoried] datetimeoffset NULL,
        [companyid] int NOT NULL DEFAULT(0)
    );
    PRINT 'Created table: dbo.[assettemp]';
END
GO

-- Table: dbo.[locationtemp]
IF OBJECT_ID('dbo.[locationtemp]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[locationtemp] (
        [name] varchar(50) NULL,
        [site] varchar(100) NULL,
        [substation] varchar(50) NULL,
        [building] varchar(100) NULL,
        [floor] varchar(50) NULL,
        [room] varchar(100) NULL,
        [description] varchar(500) NULL,
        [rfidtag] varchar(50) NULL,
        [lastmodifiedby] varchar(50) NULL,
        [lastinventoried] datetimeoffset NULL,
        [companyid] int NULL
    );
    PRINT 'Created table: dbo.[locationtemp]';
END
GO

-- Table: dbo.[AssetPushStaging]
IF OBJECT_ID('dbo.[AssetPushStaging]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[AssetPushStaging] (
        [Id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [AssetName] nvarchar(255) NULL,
        [Station] nvarchar(50) NULL,
        [LocationName] nvarchar(255) NULL,
        [PushStatus] nvarchar(50) NULL,
        [CreatedUtc] datetime2 NULL,
        [ProcessedUtc] datetime2 NULL,
        [ErrorMessage] nvarchar(MAX) NULL
    );
    PRINT 'Created table: dbo.[AssetPushStaging]';
END
GO

-- Table: dbo.[idash_license]
IF OBJECT_ID('dbo.[idash_license]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[idash_license] (
        [id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [licensekey] nvarchar(MAX) NULL,
        [customer] nvarchar(255) NULL,
        [sitename] nvarchar(255) NULL,
        [stationnumber] nvarchar(50) NULL,
        [applieddate] datetime NULL
    );
    PRINT 'Created table: dbo.[idash_license]';
END
GO

-- Seed: applicationsetting
IF NOT EXISTS (SELECT 1 FROM dbo.[applicationsetting])
BEGIN
    INSERT INTO dbo.[applicationsetting] (
        [version], [type], [company], [lastmodifiedby], [authenticationserver],
        [mqttenabled], [enableglobaleventmessages], [enableglobalalarmmessages],
        [enableglobalgatewaymessages], [enableglobalsensorreadingmessages],
        [enableglobaltagmovementmessages], [enableglobaltagobservationmessages]
    ) VALUES (
        '1.0', 'Enterprise', 'iDash', 'idashadmin', 'localhost:8181',
        0, 0, 0, 0, 0, 0, 0
    );
    PRINT 'Seeded dbo.[applicationsetting]';
END
GO

-- Seed: default sysuser (idashadmin)
IF NOT EXISTS (SELECT 1 FROM dbo.[sysuser] WHERE [username] = 'idashadmin')
BEGIN
    INSERT INTO dbo.[sysuser] ([username], [password], [firstname], [lastname], [email], [usertype])
    VALUES ('idashadmin', 'AQAAAAEAACcQAAAAEBb3W5p+7z6V2vR2yLh6D1M+k9xH5F4T3P2Q1A9Z8Y7X6W5V4U3T2S1R0Q9P8O7N6M==', 'iDash', 'Administrator', 'admin@idash.local', 'Create, Edit, Delete');
    PRINT 'Seeded default sysuser: idashadmin';
END
GO

-- =============================================
-- Core Views
-- =============================================
CREATE OR ALTER VIEW dbo.v_asset AS
SELECT a.*,
    COALESCE(l.name, 'Missing') AS locationname,
    COALESCE(l.site, 'Missing') AS locationsite,
    COALESCE(l.building, 'Missing') AS locationbuilding,
    COALESCE(l.floor, 'Missing') AS locationfloor,
    COALESCE(l.room, 'Missing') AS locationroom,
    COALESCE(l.description, 'Missing') AS locationdescription,
    COALESCE(c.name, '') AS companyname
FROM dbo.asset a
LEFT JOIN dbo.location l ON l.id = a.locationid
LEFT JOIN dbo.company c ON c.id = a.companyid;
GO

CREATE OR ALTER VIEW dbo.v_sysuser AS
SELECT u.*, c.name AS companyname
FROM dbo.sysuser u
LEFT JOIN dbo.company c ON u.companyid = c.id;
GO

CREATE OR ALTER VIEW dbo.v_reader AS
SELECT COALESCE(l.name, 'Missing') AS locationname, r.*
FROM dbo.reader r
LEFT JOIN dbo.location l ON l.id = r.locationid AND l.companyid = r.companyid;
GO

CREATE OR ALTER VIEW dbo.v_site AS
SELECT DISTINCT site FROM dbo.location WHERE site IS NOT NULL;
GO

CREATE OR ALTER VIEW dbo.v_template AS
SELECT t.*, pc.name AS printclientname
FROM dbo.template t
LEFT JOIN dbo.printclient pc ON pc.id = t.printclientid;
GO

CREATE OR ALTER VIEW dbo.v_locationhistory AS
SELECT lh.id, lh.timeseen, lh.timeleft, lh.assetid, lh.locationid, lh.companyid,
       a.name AS assetname, a.description AS assetdescription, COALESCE(l.name, 'Missing') AS locationname
FROM dbo.locationhistory lh
LEFT JOIN dbo.location l ON l.id = lh.locationid
LEFT JOIN dbo.asset a ON a.id = lh.assetid;
GO

CREATE OR ALTER VIEW dbo.v_printjob AS
SELECT a.name AS assetname, l.name AS locationname, t.name AS templatename, pj.*
FROM dbo.printjob pj
LEFT JOIN dbo.asset a ON a.id = pj.recordid
LEFT JOIN dbo.location l ON l.id = pj.recordid
LEFT JOIN dbo.template t ON t.id = pj.templateid;
GO

