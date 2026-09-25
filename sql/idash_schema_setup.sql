USE [iDash];
GO

-- =============================================
-- Table: dbo.[company]
-- =============================================
IF OBJECT_ID('dbo.[company]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[company] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] varchar(50) NULL
    );
    PRINT 'Created table: dbo.[company]';
END
GO

-- =============================================
-- Table: dbo.[location]
-- =============================================
IF OBJECT_ID('dbo.[location]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[location] (
    [id] int IDENTITY(1,1) NOT NULL,
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

-- =============================================
-- Table: dbo.[asset]
-- =============================================
IF OBJECT_ID('dbo.[asset]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[asset] (
    [id] int IDENTITY(1,1) NOT NULL,
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
    [sensorreadinghistoryid] int NULL,
    [alertingactionid] int NULL,
    [sensorstatshistoryid] int NULL,
    [readerid] int NULL,
    [assetparentid] int NULL,
    [assetchildcount] int NULL,
    [vtagboxx] decimal(18,0) NULL,
    [vtagboxy] decimal(18,0) NULL,
    [vtagboxwidth] decimal(18,0) NULL,
    [vtagboxheight] decimal(18,0) NULL,
    [vtagx] decimal(18,5) NULL,
    [vtagy] decimal(18,5) NULL,
    [vtagaccelsensor] bit NULL,
    [vtagpositiontype] varchar(50) NULL,
    [vtagalgorithmtype] varchar(50) NULL,
    [batterylevel] decimal(18,2) NULL,
    [vtagid] varchar(50) NULL,
    [vtagz] int NULL,
    [vtaglastseen] datetimeoffset NULL,
    [vtaglastmoved] datetimeoffset NULL,
    [filedataid] int NULL,
    [created] datetimeoffset NULL DEFAULT (sysdatetimeoffset()),
    [lastmodifiedby] varchar(50) NULL,
    [latitude] decimal(18,7) NULL,
    [longitude] decimal(18,7) NULL,
    [altitude] decimal(18,7) NULL,
    [numberofsatellites] int NULL,
    [gpsaccuracy] int NULL,
    [lastgpsfix] datetimeoffset NULL,
    [vtagtype] varchar(50) NULL,
    [parentvtag] varchar(50) NULL,
    [missedsatellitefixes] int NULL,
    [lastinventoried] datetimeoffset NULL,
    [vtaggpsdeviceid] varchar(100) NULL,
    [vtaggpsappkey] varchar(100) NULL,
    [deviceregistered] bit NULL DEFAULT ((0)),
    [lastmaintenance] date NULL,
    [companyid] int NOT NULL,
    [unseennotified] bit NULL
    );
    PRINT 'Created table: dbo.[asset]';
END
GO

-- =============================================
-- Table: dbo.[locationhistory]
-- =============================================
IF OBJECT_ID('dbo.[locationhistory]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[locationhistory] (
    [id] int IDENTITY(1,1) NOT NULL,
    [timeseen] datetimeoffset NOT NULL DEFAULT (sysdatetimeoffset()),
    [assetid] int NOT NULL,
    [locationid] int NULL,
    [companyid] int NOT NULL,
    [timeleft] datetimeoffset NULL
    );
    PRINT 'Created table: dbo.[locationhistory]';
END
GO

-- =============================================
-- Table: dbo.[sysuser]
-- =============================================
IF OBJECT_ID('dbo.[sysuser]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[sysuser] (
    [username] nvarchar(50) NOT NULL,
    [password] nvarchar(MAX) NULL,
    [firstname] nvarchar(50) NULL,
    [lastname] nvarchar(50) NULL,
    [email] nvarchar(50) NULL,
    [phone] nvarchar(50) NULL,
    [cardid] nvarchar(50) NULL,
    [hideadminpopups] bit NOT NULL DEFAULT ((0)),
    [rfidtag] nvarchar(50) NULL,
    [id] int IDENTITY(1,1) NOT NULL,
    [verificationcode] varchar(50) NULL,
    [verificationcodecreated] datetimeoffset NULL,
    [verificationattempts] int NULL,
    [companyid] int NULL,
    [usertype] varchar(500) NULL,
    [inventorylimiteduser] bit NULL,
    [restricteditmobile] bit NULL
    );
    PRINT 'Created table: dbo.[sysuser]';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[sysuser] WHERE [username] = 'idashadmin')
BEGIN
    INSERT INTO dbo.[sysuser] ([username], [firstname], [lastname], [email], [usertype], [hideadminpopups])
    VALUES ('idashadmin', 'iDash', 'Administrator', 'admin@idash.local', 'Create, Edit, Delete', 0);
    PRINT 'Seeded default user: idashadmin';
END
GO

-- =============================================
-- Table: dbo.[template]
-- =============================================
IF OBJECT_ID('dbo.[template]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[template] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] varchar(50) NULL,
    [templatetype] varchar(50) NULL,
    [filename] varchar(500) NULL,
    [usewithservice] varchar(50) NULL,
    [printmethod] varchar(50) NULL,
    [companyid] int NOT NULL,
    [printclientid] int NULL
    );
    PRINT 'Created table: dbo.[template]';
END
GO

-- =============================================
-- Table: dbo.[printclient]
-- =============================================
IF OBJECT_ID('dbo.[printclient]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[printclient] (
    [id] int IDENTITY(1,1) NOT NULL,
    [companyid] int NULL,
    [name] varchar(500) NULL,
    [username] varchar(500) NULL,
    [password] varchar(500) NULL,
    [machinename] varchar(500) NULL,
    [lastseen] datetimeoffset NULL
    );
    PRINT 'Created table: dbo.[printclient]';
END
GO

-- =============================================
-- Table: dbo.[printclientcompany]
-- =============================================
IF OBJECT_ID('dbo.[printclientcompany]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[printclientcompany] (
    [id] int IDENTITY(1,1) NOT NULL,
    [printclientid] int NOT NULL,
    [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[printclientcompany]';
END
GO

-- =============================================
-- Table: dbo.[printjob]
-- =============================================
IF OBJECT_ID('dbo.[printjob]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[printjob] (
    [id] int IDENTITY(1,1) NOT NULL,
    [recordid] int NOT NULL,
    [tablename] varchar(50) NOT NULL,
    [templateid] int NOT NULL,
    [generatedrfid] varchar(50) NULL,
    [completed] bit NOT NULL DEFAULT ((0)),
    [created] datetimeoffset NOT NULL DEFAULT (sysdatetimeoffset()),
    [companyid] int NOT NULL,
    [message] varchar(5000) NULL,
    [usewithservice] varchar(500) NULL
    );
    PRINT 'Created table: dbo.[printjob]';
END
GO

-- =============================================
-- Table: dbo.[reader]
-- =============================================
IF OBJECT_ID('dbo.[reader]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[reader] (
    [id] int IDENTITY(1,1) NOT NULL,
    [name] varchar(50) NOT NULL,
    [readermodel] varchar(50) NOT NULL,
    [radsmodeenabled] bit NOT NULL DEFAULT ('false'),
    [port] varchar(100) NULL,
    [devicesettings] varchar(1000) NULL,
    [connectionstatus] varchar(50) NULL,
    [usewithservice] varchar(50) NULL,
    [locationid] int NULL,
    [assetmovedalertingactionid] int NULL,
    [lowbatteryalertingactionid] int NULL,
    [sensorthresholdalertingactionid] int NULL,
    [innerdirectionalertingactionid] int NULL,
    [outerdirectionalertingactionid] int NULL,
    [mapsiteid] int NULL,
    [readerdisconnectedalertingactionid] int NULL,
    [lastmodifiedby] varchar(50) NULL,
    [physicalid] varchar(50) NULL,
    [lastseen] datetimeoffset NULL,
    [securityindicationalertingactionid] int NULL,
    [vtagx] decimal(18,5) NULL,
    [vtagy] decimal(18,5) NULL,
    [vtagz] int NULL,
    [deviceregistered] bit NULL DEFAULT ((0)),
    [vtaggpsgatewayid] varchar(150) NULL,
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

-- =============================================
-- Table: dbo.[antenna]
-- =============================================
IF OBJECT_ID('dbo.[antenna]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[antenna] (
    [id] int IDENTITY(1,1) NOT NULL,
    [alertingactionid] int NULL,
    [locationid] int NULL,
    [readerid] int NULL,
    [number] int NULL,
    [lastmodifiedby] varchar(50) NULL,
    [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[antenna]';
END
GO

-- =============================================
-- Table: dbo.[applicationsetting]
-- =============================================
IF OBJECT_ID('dbo.[applicationsetting]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[applicationsetting] (
    [id] int IDENTITY(1,1) NOT NULL,
    [version] varchar(50) NULL DEFAULT ('1.0'),
    [type] varchar(1000) NULL,
    [licensekey] varchar(1000) NULL,
    [company] varchar(50) NULL DEFAULT ('iDash'),
    [lastmodifiedby] varchar(50) NULL,
    [authenticationserver] varchar(5000) NULL,
    [webclientid] varchar(5000) NULL,
    [webclientsecret] varchar(5000) NULL,
    [mqttenabled] bit NULL DEFAULT ((1)),
    [mqttlocation] varchar(100) NULL,
    [mqttusername] varchar(100) NULL,
    [mqttpassword] varchar(100) NULL,
    [enableglobaleventmessages] bit NULL DEFAULT ((1)),
    [enableglobalalarmmessages] bit NULL DEFAULT ((1)),
    [enableglobalgatewaymessages] bit NULL DEFAULT ((1)),
    [enableglobalsensorreadingmessages] bit NULL DEFAULT ((1)),
    [enableglobaltagmovementmessages] bit NULL DEFAULT ((1)),
    [enableglobaltagobservationmessages] bit NULL DEFAULT ((1))
    );
    PRINT 'Created table: dbo.[applicationsetting]';
END
-- =============================================
-- Table: dbo.[clientapp]
-- =============================================
IF OBJECT_ID('dbo.[clientapp]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[clientapp] (
    [id] int IDENTITY(1,1) NOT NULL,
    [clientid] varchar(500) NOT NULL,
    [granttype] varchar(50) NULL,
    [secret] varchar(5000) NULL,
    [allowRefreshTokens] bit NULL,
    [companyid] int NOT NULL
    );
    PRINT 'Created table: dbo.[clientapp]';
END
GO

-- =============================================
-- Table: dbo.[customfield]
-- =============================================
IF OBJECT_ID('dbo.[customfield]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[customfield] (
    [name] varchar(50) NOT NULL,
    [value] varchar(500) NOT NULL,
    [display] bit NOT NULL DEFAULT ((1)),
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

-- =============================================
-- Table: dbo.[customfieldvalue]
-- =============================================
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

-- =============================================
-- Table: dbo.[scanner]
-- =============================================
IF OBJECT_ID('dbo.[scanner]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[scanner] (
    [id] int IDENTITY(1,1) NOT NULL,
    [companyname] varchar(100) NOT NULL,
    [deviceid] varchar(100) NULL,
    [inactive] bit NULL,
    [description] varchar(500) NULL,
    [lastseen] datetimeoffset NULL DEFAULT (sysdatetimeoffset())
    );
    PRINT 'Created table: dbo.[scanner]';
END
GO

-- =============================================
-- Table: dbo.[mqttclient]
-- =============================================
IF OBJECT_ID('dbo.[mqttclient]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[mqttclient] (
    [id] int IDENTITY(1,1) NOT NULL,
    [companyid] int NOT NULL,
    [username] varchar(500) NULL,
    [password] varchar(500) NULL,
    [accessgatewaymessages] bit NULL,
    [accesstagmovements] bit NULL,
    [accesstagobservations] bit NULL,
    [accessevents] bit NULL,
    [accessalarms] bit NULL,
    [accessvtagsensors] bit NULL
    );
    PRINT 'Created table: dbo.[mqttclient]';
END
GO

-- =============================================
-- Table: dbo.[serverstatus]
-- =============================================
IF OBJECT_ID('dbo.[serverstatus]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[serverstatus] (
    [name] varchar(50) NOT NULL,
    [lastseen] datetimeoffset NOT NULL DEFAULT (sysdatetimeoffset()),
    [version] varchar(50) NULL,
    [companyid] int NULL,
    [servertype] varchar(500) NULL,
    [id] int IDENTITY(1,1) NOT NULL
    );
    PRINT 'Created table: dbo.[serverstatus]';
END
GO

-- =============================================
-- Table: dbo.[EnnxLiveSession]
-- =============================================
IF OBJECT_ID('dbo.[EnnxLiveSession]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[EnnxLiveSession] (
    [SessionId] int IDENTITY(1,1) NOT NULL,
    [Station] varchar(50) NULL,
    [CreatedBy] varchar(100) NULL,
    [StartedUtc] datetime NULL,
    [EndedUtc] datetime NULL,
    [Summary] nvarchar(MAX) NULL,
    [JsonPayload] nvarchar(MAX) NULL,
    [EnnxText] nvarchar(MAX) NULL,
    [CreatedLocal] datetime NULL DEFAULT (getdate())
    );
    PRINT 'Created table: dbo.[EnnxLiveSession]';
END
GO

-- =============================================
-- Table: dbo.[AWAssetSync]
-- =============================================
IF OBJECT_ID('dbo.[AWAssetSync]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[AWAssetSync] (
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
    PRINT 'Created table: dbo.[AWAssetSync]';
END
GO

-- =============================================
-- Table: dbo.[AssetFileRaw]
-- =============================================
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

-- =============================================
-- Table: dbo.[LocationImportRaw]
-- =============================================
IF OBJECT_ID('dbo.[LocationImportRaw]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[LocationImportRaw] (
    [rawname] nvarchar(500) NULL
    );
    PRINT 'Created table: dbo.[LocationImportRaw]';
END
GO

-- =============================================
-- Table: dbo.[assettemp]
-- =============================================
IF OBJECT_ID('dbo.[assettemp]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[assettemp] (
    [name] varchar(50) NOT NULL,
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
    [sensorreadinghistoryid] int NULL,
    [alertingactionid] int NULL,
    [sensorstatshistoryid] int NULL,
    [readerid] int NULL,
    [assetparentid] int NULL,
    [assetchildcount] int NULL,
    [vtagboxx] decimal(18,0) NULL,
    [vtagboxy] decimal(18,0) NULL,
    [vtagboxwidth] decimal(18,0) NULL,
    [vtagboxheight] decimal(18,0) NULL,
    [vtagx] decimal(18,5) NULL,
    [vtagy] decimal(18,5) NULL,
    [vtagaccelsensor] bit NULL,
    [vtagpositiontype] varchar(50) NULL,
    [vtagalgorithmtype] varchar(50) NULL,
    [batterylevel] decimal(18,2) NULL,
    [vtagid] varchar(50) NULL,
    [vtagz] int NULL,
    [vtaglastseen] datetimeoffset NULL,
    [vtaglastmoved] datetimeoffset NULL,
    [filedataid] int NULL,
    [created] datetimeoffset NULL,
    [lastmodifiedby] varchar(50) NULL,
    [latitude] decimal(18,7) NULL,
    [longitude] decimal(18,7) NULL,
    [altitude] decimal(18,7) NULL,
    [numberofsatellites] int NULL,
    [gpsaccuracy] int NULL,
    [lastgpsfix] datetimeoffset NULL,
    [vtagtype] varchar(50) NULL,
    [parentvtag] varchar(50) NULL,
    [missedsatellitefixes] int NULL,
    [lastinventoried] datetimeoffset NULL,
    [vtaggpsdeviceid] varchar(100) NULL,
    [vtaggpsappkey] varchar(100) NULL,
    [deviceregistered] bit NULL,
    [lastmaintenance] datetimeoffset NULL,
    [companyid] int NOT NULL DEFAULT ((0)),
    [unseennotified] bit NULL
    );
    PRINT 'Created table: dbo.[assettemp]';
END
GO

-- =============================================
-- Table: dbo.[locationtemp]
-- =============================================
IF OBJECT_ID('dbo.[locationtemp]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[locationtemp] (
    [name] varchar(50) NOT NULL,
    [site] varchar(100) NULL,
    [substation] varchar(50) NULL,
    [building] varchar(100) NULL,
    [floor] varchar(50) NULL,
    [room] varchar(100) NULL,
    [description] varchar(500) NULL,
    [rfidtag] varchar(50) NULL,
    [lastmodifiedby] varchar(50) NULL,
    [lastinventoried] datetimeoffset NULL,
    [companyid] int NOT NULL DEFAULT ((0))
    );
    PRINT 'Created table: dbo.[locationtemp]';
END
GO

-- =============================================
-- Table: dbo.[AWPushStaging]
-- =============================================
IF OBJECT_ID('dbo.[AWPushStaging]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[AWPushStaging] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AssetName] NVARCHAR(255) NULL,
        [Station] NVARCHAR(50) NULL,
        [LocationName] NVARCHAR(255) NULL,
        [PushStatus] NVARCHAR(50) DEFAULT 'Pending',
        [CreatedUtc] DATETIME2 DEFAULT GETUTCDATE(),
        [ProcessedUtc] DATETIME2 NULL,
        [ErrorMessage] NVARCHAR(MAX) NULL
    );
    PRINT 'Created table: dbo.[AWPushStaging]';
END
GO

-- =============================================
-- Table: dbo.[idash_license]
-- =============================================
IF OBJECT_ID('dbo.[idash_license]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[idash_license] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [licensekey] NVARCHAR(MAX) NOT NULL,
        [customer] NVARCHAR(255) NULL,
        [sitename] NVARCHAR(255) NULL,
        [stationnumber] NVARCHAR(50) NULL,
        [applieddate] DATETIME NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Created table: dbo.[idash_license]';
END
GO
-- =============================================
-- VIEWS
-- =============================================
IF OBJECT_ID('dbo.v_asset', 'V') IS NOT NULL DROP VIEW dbo.v_asset;
GO
CREATE VIEW dbo.v_asset AS
SELECT
    a.*,
    l.name AS locationname,
    c.name AS companyname
FROM dbo.asset a
LEFT JOIN dbo.location l ON a.locationid = l.id
LEFT JOIN dbo.company c ON a.companyid = c.id;
GO
PRINT 'Created view: dbo.v_asset';
GO

IF OBJECT_ID('dbo.v_sysuser', 'V') IS NOT NULL DROP VIEW dbo.v_sysuser;
GO
CREATE VIEW dbo.v_sysuser AS
SELECT
    u.*,
    c.name AS companyname
FROM dbo.sysuser u
LEFT JOIN dbo.company c ON u.companyid = c.id;
GO
PRINT 'Created view: dbo.v_sysuser';
GO

IF OBJECT_ID('dbo.v_locationhistory', 'V') IS NOT NULL DROP VIEW dbo.v_locationhistory;
GO
CREATE VIEW dbo.v_locationhistory AS
SELECT
    lh.*,
    a.name AS assetname,
    l.name AS locationname
FROM dbo.locationhistory lh
LEFT JOIN dbo.asset a ON lh.assetid = a.id
LEFT JOIN dbo.location l ON lh.locationid = l.id;
GO
PRINT 'Created view: dbo.v_locationhistory';
GO

IF OBJECT_ID('dbo.v_printjob', 'V') IS NOT NULL DROP VIEW dbo.v_printjob;
GO
CREATE VIEW dbo.v_printjob AS
SELECT 
    a.name AS assetname, 
    l.name AS locationname, 
    t.name AS templatename, 
    pj.* 
FROM dbo.printjob pj 
LEFT JOIN dbo.asset a ON a.id = pj.recordid 
LEFT JOIN dbo.location l ON l.id = pj.recordid 
LEFT JOIN dbo.template t ON t.id = pj.templateid;
GO
PRINT 'Created view: dbo.v_printjob';
GO

IF OBJECT_ID('dbo.v_reader', 'V') IS NOT NULL DROP VIEW dbo.v_reader;
GO
CREATE VIEW dbo.v_reader AS 
SELECT 
    COALESCE(l.name, 'Missing') AS locationname,
    r.*
FROM dbo.reader r
LEFT JOIN dbo.location l ON l.id = r.locationid AND l.companyid = r.companyid;
GO
PRINT 'Created view: dbo.v_reader';
GO

IF OBJECT_ID('dbo.v_site', 'V') IS NOT NULL DROP VIEW dbo.v_site;
GO
CREATE VIEW dbo.v_site AS 
SELECT DISTINCT site
FROM dbo.location
WHERE site IS NOT NULL;
GO
PRINT 'Created view: dbo.v_site';
GO

IF OBJECT_ID('dbo.v_template', 'V') IS NOT NULL DROP VIEW dbo.v_template;
GO
CREATE VIEW dbo.v_template AS 
SELECT t.*, pc.name AS printclientname 
FROM dbo.template t 
LEFT JOIN dbo.printclient pc ON pc.id = t.printclientid;
GO
PRINT 'Created view: dbo.v_template';
GO
-- =============================================
-- INDEXES & KEYS
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.company'))
    ALTER TABLE dbo.company ADD CONSTRAINT PK_company PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.location'))
    ALTER TABLE dbo.location ADD CONSTRAINT PK_location PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.asset'))
    ALTER TABLE dbo.asset ADD CONSTRAINT PK_asset PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.locationhistory'))
    ALTER TABLE dbo.locationhistory ADD CONSTRAINT PK_locationhistory PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.sysuser'))
    ALTER TABLE dbo.sysuser ADD CONSTRAINT PK_sysuser PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.template'))
    ALTER TABLE dbo.template ADD CONSTRAINT PK_template PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.printclient'))
    ALTER TABLE dbo.printclient ADD CONSTRAINT PK_printclient PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.printclientcompany'))
    ALTER TABLE dbo.printclientcompany ADD CONSTRAINT PK_printclientcompany PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.printjob'))
    ALTER TABLE dbo.printjob ADD CONSTRAINT PK_printjob PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.reader'))
    ALTER TABLE dbo.reader ADD CONSTRAINT PK_reader PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.antenna'))
    ALTER TABLE dbo.antenna ADD CONSTRAINT PK_antenna PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.scanner'))
    ALTER TABLE dbo.scanner ADD CONSTRAINT PK_scanner PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.mqttclient'))
    ALTER TABLE dbo.mqttclient ADD CONSTRAINT PK_mqttclient PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.serverstatus'))
    ALTER TABLE dbo.serverstatus ADD CONSTRAINT PK_serverstatus PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.applicationsetting'))
    ALTER TABLE dbo.applicationsetting ADD CONSTRAINT PK_applicationsetting PRIMARY KEY CLUSTERED (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [type] = 'PK' AND [parent_object_id] = OBJECT_ID('dbo.customfield'))
    ALTER TABLE dbo.customfield ADD CONSTRAINT PK_customfield PRIMARY KEY CLUSTERED (name);
GO

-- Helpful Performance Indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asset_name' AND object_id = OBJECT_ID('dbo.asset'))
    CREATE NONCLUSTERED INDEX IX_asset_name ON dbo.asset(name);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asset_rfidtag' AND object_id = OBJECT_ID('dbo.asset'))
    CREATE NONCLUSTERED INDEX IX_asset_rfidtag ON dbo.asset(rfidtag);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asset_company_loc' AND object_id = OBJECT_ID('dbo.asset'))
    CREATE NONCLUSTERED INDEX IX_asset_company_loc ON dbo.asset(companyid, locationid);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asset_lastmodified' AND object_id = OBJECT_ID('dbo.asset'))
    CREATE NONCLUSTERED INDEX IX_asset_lastmodified ON dbo.asset(lastmodified);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asset_text8' AND object_id = OBJECT_ID('dbo.asset'))
    CREATE NONCLUSTERED INDEX IX_asset_text8 ON dbo.asset(text8);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_location_name' AND object_id = OBJECT_ID('dbo.location'))
    CREATE NONCLUSTERED INDEX IX_location_name ON dbo.location(name);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_location_companyid' AND object_id = OBJECT_ID('dbo.location'))
    CREATE NONCLUSTERED INDEX IX_location_companyid ON dbo.location(companyid);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_location_rfidtag' AND object_id = OBJECT_ID('dbo.location'))
    CREATE NONCLUSTERED INDEX IX_location_rfidtag ON dbo.location(rfidtag);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_locationhistory_asset' AND object_id = OBJECT_ID('dbo.locationhistory'))
    CREATE NONCLUSTERED INDEX IX_locationhistory_asset ON dbo.locationhistory(assetid, timeseen DESC);
GO
