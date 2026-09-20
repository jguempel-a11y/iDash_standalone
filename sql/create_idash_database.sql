/* =====================================================================
   iDash Database Setup — create_idash_database.sql
   Purpose : Create the complete iDash database schema from scratch
             for iDash deployment on a new server.
   Usage   : Run in SQL Server Management Studio (SSMS) as sysadmin.
   Safety  : Fully idempotent — safe to re-run on an existing database.
             All CREATE statements are guarded with IF NOT EXISTS / IF NULL.
   Created : 2026-07-22 — ID Integration Inc.
   ===================================================================== */

-- =============================================
-- STEP 1: Create the database
-- =============================================
IF DB_ID('iDash') IS NULL
BEGIN
    CREATE DATABASE [idash];
    PRINT '✅ Database [idash] created.';
END
ELSE
    PRINT '⏭ Database [idash] already exists. Skipping.';
GO

-- =============================================
-- STEP 2: Create SQL login
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'idashadmin')
BEGIN
    CREATE LOGIN [idashadmin]
        WITH PASSWORD = 'idashadmin',
        DEFAULT_DATABASE = [idash],
        CHECK_POLICY = OFF;
    PRINT '✅ Login [idashadmin] created.';
END
ELSE
    PRINT '⏭ Login [idashadmin] already exists.';
GO

USE [idash];
GO

-- Map login to database user
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'idashadmin')
BEGIN
    CREATE USER [idashadmin] FOR LOGIN [idashadmin];
    ALTER ROLE db_owner ADD MEMBER [idashadmin];
    PRINT '✅ User [idashadmin] created and granted db_owner.';
END
GO

-- =============================================
-- STEP 3: Core Tables
-- =============================================

-- 3a. dbo.company (Site / Facility Registry)
IF OBJECT_ID('dbo.company', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.company (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        name        NVARCHAR(255) NOT NULL,
        description NVARCHAR(500) NULL,
        created     DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
    );
    PRINT '✅ Created table: dbo.company';
END
ELSE
    PRINT '⏭ Table dbo.company already exists.';
GO

-- 3b. dbo.location (EIL Location Registry)
IF OBJECT_ID('dbo.location', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.location (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        name        NVARCHAR(255) NOT NULL,
        site        NVARCHAR(255) NULL,
        companyid   INT NOT NULL DEFAULT 0,
        description NVARCHAR(500) NULL,
        created     DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
    );
    CREATE NONCLUSTERED INDEX IX_location_name ON dbo.location(name);
    CREATE NONCLUSTERED INDEX IX_location_companyid ON dbo.location(companyid);
    PRINT '✅ Created table: dbo.location';
END
ELSE
    PRINT '⏭ Table dbo.location already exists.';
GO

-- 3c. dbo.asset (Master Asset Table)
IF OBJECT_ID('dbo.asset', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.asset (
        -- Primary key
        id                      INT IDENTITY(1,1) PRIMARY KEY,

        -- Core identity
        name                    NVARCHAR(255) NOT NULL,     -- EE number (barcode)
        barcode                 NVARCHAR(255) NULL,
        description             NVARCHAR(1000) NULL,
        serialnumber            NVARCHAR(255) NULL,
        rfidtag                 NVARCHAR(255) NULL,
        assettype               NVARCHAR(100) NULL,

        -- Foreign keys
        companyid               INT NOT NULL DEFAULT 0,
        locationid              INT NULL,

        -- Custom text fields (VA mapping: see documentation)
        text1                   NVARCHAR(500) NULL,     -- Manufacturer
        text2                   NVARCHAR(500) NULL,     -- Model
        text3                   NVARCHAR(500) NULL,     -- Serial Number (CDW)
        text4                   NVARCHAR(500) NULL,     -- Category
        text5                   NVARCHAR(500) NULL,     -- Service Pointer
        text6                   NVARCHAR(500) NULL,     -- Station+Location
        text7                   NVARCHAR(500) NULL,     -- Station Number
        text8                   NVARCHAR(500) NULL,     -- CMR Number
        text9                   NVARCHAR(500) NULL,     -- Purchase Order
        text10                  NVARCHAR(500) NULL,     -- Inventory Date
        text11                  NVARCHAR(500) NULL,
        text12                  NVARCHAR(500) NULL,
        text13                  NVARCHAR(500) NULL,
        text14                  NVARCHAR(500) NULL,
        text15                  NVARCHAR(500) NULL,
        text16                  NVARCHAR(500) NULL,
        text17                  NVARCHAR(500) NULL,
        text18                  NVARCHAR(500) NULL,
        text19                  NVARCHAR(500) NULL,
        text20                  NVARCHAR(500) NULL,

        -- List value fields
        listvalue1              NVARCHAR(255) NULL,     -- Status (In Use / Not In Use)
        listvalue2              NVARCHAR(255) NULL,
        listvalue3              NVARCHAR(255) NULL,
        listvalue4              NVARCHAR(255) NULL,
        listvalue5              NVARCHAR(255) NULL,

        -- Date fields
        date1                   DATETIMEOFFSET NULL,
        date2                   DATETIMEOFFSET NULL,
        date3                   DATETIMEOFFSET NULL,
        date4                   DATETIMEOFFSET NULL,
        date5                   DATETIMEOFFSET NULL,

        -- Tracking / scan fields
        lastobservedlocation    NVARCHAR(255) NULL,
        lastobservedtime        DATETIMEOFFSET NULL,
        lastinventoried         DATETIMEOFFSET NULL,
        lastmodified            DATETIMEOFFSET NULL,
        lastmodifiedby          NVARCHAR(255) NULL,
        created                 DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),

        -- Status / disposition
        departmentcode          NVARCHAR(100) NULL,
        checkinstatus           NVARCHAR(100) NULL,
        checkedoutto            NVARCHAR(255) NULL,
        disposalstatus          INT NULL,
        disposalmethod          NVARCHAR(255) NULL,
        disposaldate            DATETIMEOFFSET NULL,
        disposaldestination     NVARCHAR(255) NULL,
        additionalinformation   NVARCHAR(MAX) NULL,

        -- Maintenance fields
        maintenancestartdate    DATETIMEOFFSET NULL,
        maintenancesingledate   DATETIMEOFFSET NULL,
        nextmaintenance         DATETIMEOFFSET NULL,
        lastmaintenance         DATETIMEOFFSET NULL,
        maintenancemethod       INT NULL,
        maintenanceintervalmonths INT NULL,

        -- RFID / VTag hardware fields
        maxunseentime           INT NULL,
        nearestfixed            INT NULL,
        sensorreadinghistoryid  INT NULL,
        alertingactionid        INT NULL,
        sensorstatshistoryid    INT NULL,
        readerid                INT NULL,
        assetparentid           INT NULL,
        assetchildcount         INT NULL,
        vtagboxx                FLOAT NULL,
        vtagboxy                FLOAT NULL,
        vtagboxwidth            FLOAT NULL,
        vtagboxheight           FLOAT NULL,
        vtagx                   FLOAT NULL,
        vtagy                   FLOAT NULL,
        vtagz                   FLOAT NULL,
        vtagaccelsensor         INT NULL,
        vtagpositiontype        INT NULL,
        vtagalgorithmtype       INT NULL,
        batterylevel            INT NULL,
        vtagid                  NVARCHAR(255) NULL,
        vtaglastseen            DATETIMEOFFSET NULL,
        vtaglastmoved           DATETIMEOFFSET NULL,
        vtagtype                INT NULL,
        parentvtag              INT NULL,
        missedsatellitefixes    INT NULL,
        vtaggpsdeviceid         NVARCHAR(255) NULL,
        vtaggpsappkey           NVARCHAR(255) NULL,
        deviceregistered        BIT NULL,
        unseennotified          BIT NULL,

        -- GPS fields
        latitude                FLOAT NULL,
        longitude               FLOAT NULL,
        altitude                FLOAT NULL,
        numberofsatellites      INT NULL,
        gpsaccuracy             FLOAT NULL,
        lastgpsfix              DATETIMEOFFSET NULL
    );

    -- Performance indexes
    CREATE NONCLUSTERED INDEX IX_asset_name ON dbo.asset(name);
    CREATE NONCLUSTERED INDEX IX_asset_companyid ON dbo.asset(companyid);
    CREATE NONCLUSTERED INDEX IX_asset_locationid ON dbo.asset(locationid);
    CREATE NONCLUSTERED INDEX IX_asset_rfidtag ON dbo.asset(rfidtag);
    CREATE NONCLUSTERED INDEX IX_asset_lastmodified ON dbo.asset(lastmodified);
    CREATE NONCLUSTERED INDEX IX_asset_text8 ON dbo.asset(text8);

    PRINT '✅ Created table: dbo.asset (with 6 indexes)';
END
ELSE
    PRINT '⏭ Table dbo.asset already exists.';
GO

-- 3d. dbo.sysuser (iDash / RFID Scanner Users)
IF OBJECT_ID('dbo.sysuser', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.sysuser (
        id                    INT IDENTITY(1,1) PRIMARY KEY,
        username              NVARCHAR(255) NOT NULL,
        password              NVARCHAR(500) NULL,
        firstname             NVARCHAR(255) NULL,
        lastname              NVARCHAR(255) NULL,
        email                 NVARCHAR(255) NULL,
        phone                 NVARCHAR(100) NULL,
        cardid                NVARCHAR(255) NULL,
        rfidtag               NVARCHAR(255) NULL,
        usertype              NVARCHAR(50) NULL,
        companyid             INT NULL,
        hideadminpopups       BIT DEFAULT 0,
        inventorylimiteduser  BIT DEFAULT 0,
        restricteditmobile    BIT DEFAULT 0,
        created               DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
    );
    CREATE UNIQUE NONCLUSTERED INDEX IX_sysuser_username ON dbo.sysuser(username);
    PRINT '✅ Created table: dbo.sysuser';
END
ELSE
    PRINT '⏭ Table dbo.sysuser already exists.';
GO

-- 3d-patch. dbo.sysuser — add columns that may be missing from older backups
-- Safe to re-run: each ALTER is guarded by a column-existence check.
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'hideadminpopups')
BEGIN
    ALTER TABLE dbo.sysuser ADD hideadminpopups BIT NOT NULL DEFAULT 0;
    PRINT '✅ Added column: dbo.sysuser.hideadminpopups';
END
ELSE
    PRINT '⏭ Column dbo.sysuser.hideadminpopups already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'inventorylimiteduser')
BEGIN
    ALTER TABLE dbo.sysuser ADD inventorylimiteduser BIT NOT NULL DEFAULT 0;
    PRINT '✅ Added column: dbo.sysuser.inventorylimiteduser';
END
ELSE
    PRINT '⏭ Column dbo.sysuser.inventorylimiteduser already exists.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.sysuser') AND name = 'restricteditmobile')
BEGIN
    ALTER TABLE dbo.sysuser ADD restricteditmobile BIT NOT NULL DEFAULT 0;
    PRINT '✅ Added column: dbo.sysuser.restricteditmobile';
END
ELSE
    PRINT '⏭ Column dbo.sysuser.restricteditmobile already exists.';
GO

-- =============================================
-- STEP 4: Views
-- =============================================

-- 4a. v_asset (used by most iDash dashboards)
IF OBJECT_ID('dbo.v_asset', 'V') IS NOT NULL
    DROP VIEW dbo.v_asset;
GO
CREATE VIEW dbo.v_asset AS
SELECT
    a.*,
    l.name     AS locationname,
    c.name     AS companyname
FROM dbo.asset a
LEFT JOIN dbo.location l ON a.locationid = l.id
LEFT JOIN dbo.company  c ON a.companyid  = c.id;
GO
PRINT '✅ Created view: dbo.v_asset';
GO

-- 4b. v_sysuser (used by TagTeam Scan, Inventory user dropdowns)
IF OBJECT_ID('dbo.v_sysuser', 'V') IS NOT NULL
    DROP VIEW dbo.v_sysuser;
GO
CREATE VIEW dbo.v_sysuser AS
SELECT
    u.*,
    c.name AS companyname
FROM dbo.sysuser u
LEFT JOIN dbo.company c ON u.companyid = c.id;
GO
PRINT '✅ Created view: dbo.v_sysuser';
GO

-- 4c. locationhistory table + v_locationhistory view
IF OBJECT_ID('dbo.locationhistory', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.locationhistory (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        assetid     INT NOT NULL,
        locationid  INT NULL,
        readerid    INT NULL,
        timestamp   DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
    );
    PRINT '✅ Created table: dbo.locationhistory';
END
GO

IF OBJECT_ID('dbo.v_locationhistory', 'V') IS NOT NULL
    DROP VIEW dbo.v_locationhistory;
GO
CREATE VIEW dbo.v_locationhistory AS
SELECT
    lh.*,
    a.name   AS assetname,
    l.name   AS locationname
FROM dbo.locationhistory lh
LEFT JOIN dbo.asset    a ON lh.assetid    = a.id
LEFT JOIN dbo.location l ON lh.locationid = l.id;
GO
PRINT '✅ Created view: dbo.v_locationhistory';
GO

-- =============================================
-- STEP 5: iDash-Only Tables
-- =============================================

-- 5a. EnnxLiveSession (live scan session log)
IF OBJECT_ID('dbo.EnnxLiveSession', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.EnnxLiveSession (
        Id            INT IDENTITY(1,1) PRIMARY KEY,
        Station       NVARCHAR(50) NULL,
        CreatedBy     NVARCHAR(255) NULL,
        StartedUtc    DATETIME2 NULL,
        EndedUtc      DATETIME2 NULL,
        Summary       NVARCHAR(MAX) NULL,
        JsonPayload   NVARCHAR(MAX) NULL,
        EnnxText      NVARCHAR(MAX) NULL,
        CreatedLocal  DATETIME2 DEFAULT GETDATE()
    );
    PRINT '✅ Created table: dbo.EnnxLiveSession';
END
GO

-- 5b. AWPushStaging (Supply Chain Bridge)
IF OBJECT_ID('dbo.AWPushStaging', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AWPushStaging (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        AssetName       NVARCHAR(255) NULL,
        Station         NVARCHAR(50) NULL,
        LocationName    NVARCHAR(255) NULL,
        PushStatus      NVARCHAR(50) DEFAULT 'Pending',
        CreatedUtc      DATETIME2 DEFAULT GETUTCDATE(),
        ProcessedUtc    DATETIME2 NULL,
        ErrorMessage    NVARCHAR(MAX) NULL
    );
    PRINT '✅ Created table: dbo.AWPushStaging';
END
GO

-- =============================================
-- STEP 6: Staging Database (for Field Sync)
-- =============================================
IF DB_ID('idash_staging') IS NULL
BEGIN
    CREATE DATABASE [idash_staging];
    PRINT '✅ Created staging database: [idash_staging]';
END
ELSE
    PRINT '⏭ Staging database already exists.';
GO

USE [idash_staging];
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'idashadmin')
BEGIN
    CREATE USER [idashadmin] FOR LOGIN [idashadmin];
    ALTER ROLE db_owner ADD MEMBER [idashadmin];
    PRINT '✅ Granted staging DB access to [idashadmin].';
END
GO

-- =============================================
-- VERIFICATION
-- =============================================
USE [idash];
GO

PRINT '';
PRINT '============================================';
PRINT '  VERIFICATION — iDash Schema Check';
PRINT '============================================';

SELECT 'Tables' AS Category, name, type_desc
FROM sys.objects
WHERE type = 'U' AND name IN (
    'asset', 'company', 'location', 'sysuser',
    'EnnxLiveSession', 'AWPushStaging', 'locationhistory'
)
UNION ALL
SELECT 'Views', name, type_desc
FROM sys.objects
WHERE type = 'V' AND name IN (
    'v_asset', 'v_sysuser', 'v_locationhistory'
)
ORDER BY Category, name;

PRINT '';
PRINT '============================================';
PRINT '  ✅ iDash database setup complete!';
PRINT '  Next: Add company records, then import';
PRINT '  asset data via iDash tools.';
PRINT '============================================';
GO
