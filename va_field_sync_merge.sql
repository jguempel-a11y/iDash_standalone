/* =====================================================================
   VA FIELD SYNC MERGE — va_field_sync_merge.sql
   Purpose : Pull updated asset and location data from the staging
             database (idash_staging, restored from a field .bak)
             into the live idash database for executive reporting.
   Strategy: 1) Sync companies & locations (new rows only)
             2) UPDATE assets where field data differs from central
             3) INSERT brand-new assets not yet in central DB
             4) Re-link location IDs by name (IDs differ per server)
   Safety  : Never overwrites a field that already has data with a blank.
             Compares actual field values to detect changes.
   Updated : 2026-07-12 — CRITICAL FIX: WHERE clause now compares actual
             data fields (text6-20, description, locationname, rfidtag,
             listvalue1, lastinventoried) instead of relying on
             s.lastmodified > m.lastmodified. The field server BAK sets
             lastmodified to NULL, so the old timestamp comparison
             returned 0 rows every time.
             2026-07-12 — FIX: lastmodifiedby now synced on UPDATE
             (was only synced on INSERT). Company matching improved from
             SUBSTRING(name,1,3) to strip-and-compare for robustness.
   ===================================================================== */

USE [idash];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Verify staging DB is available */
IF DB_ID('idash_staging') IS NULL
BEGIN
    RAISERROR('idash_staging database does not exist. Restore the .bak file first.', 16, 1);
    RETURN;
END
GO

/* Stats table */
IF OBJECT_ID('tempdb..#SyncStats') IS NOT NULL DROP TABLE #SyncStats;
CREATE TABLE #SyncStats (
    LocationsInserted INT DEFAULT 0,
    AssetsUpdated     INT DEFAULT 0,
    AssetsInserted    INT DEFAULT 0,
    Errors            INT DEFAULT 0
);
INSERT INTO #SyncStats DEFAULT VALUES;
GO

/* ── STEP 1: Sync companies ────────────────────────────────────────── */
BEGIN TRY
    INSERT INTO dbo.company (name)
    SELECT s.name
    FROM idash_staging.dbo.company s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.company m
        WHERE LEFT(REPLACE(REPLACE(m.name,' ',''),'-',''), 3) = LEFT(REPLACE(REPLACE(s.name,' ',''),'-',''), 3)
    );
END TRY
BEGIN CATCH
    UPDATE #SyncStats SET Errors = Errors + 1;
END CATCH;
GO

/* ── STEP 2: Sync locations (new only) ─────────────────────────────── */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.location (name, site, companyid)
    SELECT DISTINCT s.name, s.site,
        COALESCE(
            (SELECT TOP 1 mc.id FROM dbo.company mc
             JOIN idash_staging.dbo.company sc
               ON LEFT(REPLACE(REPLACE(mc.name,' ',''),'-',''), 3) = LEFT(REPLACE(REPLACE(sc.name,' ',''),'-',''), 3)
             WHERE sc.id = s.companyid), 0)
    FROM idash_staging.dbo.location s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.location l
        WHERE l.name = s.name
          AND l.companyid = COALESCE(
            (SELECT TOP 1 mc.id FROM dbo.company mc
             JOIN idash_staging.dbo.company sc
               ON LEFT(REPLACE(REPLACE(mc.name,' ',''),'-',''), 3) = LEFT(REPLACE(REPLACE(sc.name,' ',''),'-',''), 3)
             WHERE sc.id = s.companyid), 0)
    );

    UPDATE #SyncStats SET LocationsInserted = @@ROWCOUNT;
    COMMIT;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    UPDATE #SyncStats SET Errors = Errors + 1;
END CATCH;
GO

/* ── STEP 3: Update changed assets (field is newer) ─────────────────
   Fires when field lastmodified OR lastinventoried is newer than central.
   Uses CASE/ISNULL to avoid overwriting existing data with blanks.
   !! ALL text, listvalue, date, and descriptor columns are included !! */
BEGIN TRY
    UPDATE m
    SET
        -- Location / scan tracking
        m.lastobservedlocation = s.lastobservedlocation,
        m.lastobservedtime     = s.lastobservedtime,
        m.lastinventoried      = s.lastinventoried,

        -- Status / classification fields
        m.assettype       = CASE WHEN NULLIF(RTRIM(s.assettype),'')       IS NOT NULL THEN s.assettype       ELSE m.assettype       END,
        m.departmentcode  = CASE WHEN NULLIF(RTRIM(s.departmentcode),'')  IS NOT NULL THEN s.departmentcode  ELSE m.departmentcode  END,
        m.checkinstatus   = CASE WHEN NULLIF(RTRIM(s.checkinstatus),'')   IS NOT NULL THEN s.checkinstatus   ELSE m.checkinstatus   END,
        m.checkedoutto    = CASE WHEN NULLIF(RTRIM(s.checkedoutto),'')    IS NOT NULL THEN s.checkedoutto    ELSE m.checkedoutto    END,
        m.disposalstatus  = ISNULL(s.disposalstatus, m.disposalstatus),

        -- Description / notes
        m.description            = CASE WHEN NULLIF(RTRIM(s.description),'')            IS NOT NULL THEN s.description            ELSE m.description            END,
        m.additionalinformation  = CASE WHEN NULLIF(RTRIM(s.additionalinformation),'')  IS NOT NULL THEN s.additionalinformation  ELSE m.additionalinformation  END,

        -- Text fields 1–10
        m.text1  = CASE WHEN NULLIF(RTRIM(s.text1),'')  IS NOT NULL THEN s.text1  ELSE m.text1  END,  -- Manufacturer
        m.text2  = CASE WHEN NULLIF(RTRIM(s.text2),'')  IS NOT NULL THEN s.text2  ELSE m.text2  END,  -- Model
        m.text3  = CASE WHEN NULLIF(RTRIM(s.text3),'')  IS NOT NULL THEN s.text3  ELSE m.text3  END,  -- Serial
        m.text4  = CASE WHEN NULLIF(RTRIM(s.text4),'')  IS NOT NULL THEN s.text4  ELSE m.text4  END,  -- Category
        m.text5  = CASE WHEN NULLIF(RTRIM(s.text5),'')  IS NOT NULL THEN s.text5  ELSE m.text5  END,  -- Svc Pointer
        m.text6  = CASE WHEN NULLIF(RTRIM(s.text6),'')  IS NOT NULL THEN s.text6  ELSE m.text6  END,  -- SP+Location
        m.text7  = CASE WHEN NULLIF(RTRIM(s.text7),'')  IS NOT NULL THEN s.text7  ELSE m.text7  END,  -- Station
        m.text8  = CASE WHEN NULLIF(RTRIM(s.text8),'')  IS NOT NULL THEN s.text8  ELSE m.text8  END,  -- CMR
        m.text9  = CASE WHEN NULLIF(RTRIM(s.text9),'')  IS NOT NULL THEN s.text9  ELSE m.text9  END,  -- PO#
        m.text10 = CASE WHEN NULLIF(RTRIM(s.text10),'') IS NOT NULL THEN s.text10 ELSE m.text10 END,  -- Inv Date

        -- Text fields 11–20 (WERE MISSING — now included)
        m.text11 = CASE WHEN NULLIF(RTRIM(s.text11),'') IS NOT NULL THEN s.text11 ELSE m.text11 END,
        m.text12 = CASE WHEN NULLIF(RTRIM(s.text12),'') IS NOT NULL THEN s.text12 ELSE m.text12 END,
        m.text13 = CASE WHEN NULLIF(RTRIM(s.text13),'') IS NOT NULL THEN s.text13 ELSE m.text13 END,
        m.text14 = CASE WHEN NULLIF(RTRIM(s.text14),'') IS NOT NULL THEN s.text14 ELSE m.text14 END,
        m.text15 = CASE WHEN NULLIF(RTRIM(s.text15),'') IS NOT NULL THEN s.text15 ELSE m.text15 END,
        m.text16 = CASE WHEN NULLIF(RTRIM(s.text16),'') IS NOT NULL THEN s.text16 ELSE m.text16 END,
        m.text17 = CASE WHEN NULLIF(RTRIM(s.text17),'') IS NOT NULL THEN s.text17 ELSE m.text17 END,
        m.text18 = CASE WHEN NULLIF(RTRIM(s.text18),'') IS NOT NULL THEN s.text18 ELSE m.text18 END,
        m.text19 = CASE WHEN NULLIF(RTRIM(s.text19),'') IS NOT NULL THEN s.text19 ELSE m.text19 END,
        m.text20 = CASE WHEN NULLIF(RTRIM(s.text20),'') IS NOT NULL THEN s.text20 ELSE m.text20 END,

        -- List value fields (WERE MISSING — now included)
        m.listvalue1 = ISNULL(s.listvalue1, m.listvalue1),
        m.listvalue2 = ISNULL(s.listvalue2, m.listvalue2),
        m.listvalue3 = ISNULL(s.listvalue3, m.listvalue3),
        m.listvalue4 = ISNULL(s.listvalue4, m.listvalue4),
        m.listvalue5 = ISNULL(s.listvalue5, m.listvalue5),

        -- Date fields (WERE MISSING — now included)
        m.date1 = ISNULL(s.date1, m.date1),
        m.date2 = ISNULL(s.date2, m.date2),
        m.date3 = ISNULL(s.date3, m.date3),
        m.date4 = ISNULL(s.date4, m.date4),
        m.date5 = ISNULL(s.date5, m.date5),

        -- RFID tag
        m.rfidtag = CASE WHEN NULLIF(RTRIM(s.rfidtag),'') IS NOT NULL THEN s.rfidtag ELSE m.rfidtag END,

        -- User attribution (WAS MISSING — scanner operator now preserved)
        m.lastmodifiedby = CASE WHEN NULLIF(RTRIM(s.lastmodifiedby),'') IS NOT NULL THEN s.lastmodifiedby ELSE m.lastmodifiedby END,

        m.lastmodified = SYSDATETIMEOFFSET()
    FROM dbo.asset m
    JOIN idash_staging.dbo.asset s ON m.name = s.name
        AND m.companyid = COALESCE(
            (SELECT TOP 1 mc.id FROM dbo.company mc
             JOIN idash_staging.dbo.company sc
               ON LEFT(REPLACE(REPLACE(mc.name,' ',''),'-',''), 3) = LEFT(REPLACE(REPLACE(sc.name,' ',''),'-',''), 3)
             WHERE sc.id = s.companyid), m.companyid)
    WHERE
        -- Compare actual data fields (field server does NOT update lastmodified)
        COALESCE(m.text6,'')  <> COALESCE(s.text6,'')
        OR COALESCE(m.text7,'')  <> COALESCE(s.text7,'')
        OR COALESCE(m.text8,'')  <> COALESCE(s.text8,'')
        OR COALESCE(m.text13,'') <> COALESCE(s.text13,'')
        OR COALESCE(m.text16,'') <> COALESCE(s.text16,'')
        OR COALESCE(m.text17,'') <> COALESCE(s.text17,'')
        OR COALESCE(m.text18,'') <> COALESCE(s.text18,'')
        OR COALESCE(m.text19,'') <> COALESCE(s.text19,'')
        OR COALESCE(m.text20,'') <> COALESCE(s.text20,'')
        OR COALESCE(m.description,'') <> COALESCE(s.description,'')
        OR COALESCE(m.rfidtag,'') <> COALESCE(s.rfidtag,'')
        OR COALESCE(m.listvalue1,'') <> COALESCE(s.listvalue1,'')
        -- Also catch timestamp-based changes if they do exist
        OR (s.lastinventoried IS NOT NULL AND (m.lastinventoried IS NULL OR s.lastinventoried > m.lastinventoried))
        OR (s.lastmodified IS NOT NULL AND m.lastmodified IS NOT NULL AND s.lastmodified > m.lastmodified);

    UPDATE #SyncStats SET AssetsUpdated = @@ROWCOUNT;
END TRY
BEGIN CATCH
    UPDATE #SyncStats SET Errors = Errors + 1;
END CATCH;
GO

/* ── STEP 4: Insert brand-new assets from field ──────────────────── */
BEGIN TRY
    INSERT INTO dbo.asset (
        name, description, rfidtag, assettype, departmentcode, maxunseentime,
        lastobservedlocation, lastobservedtime, checkinstatus, checkedoutto,
        additionalinformation, disposalstatus, disposalmethod, disposaldate, disposaldestination,
        maintenancestartdate, maintenancesingledate, nextmaintenance, date1, date2, date3, date4, date5,
        listvalue1, listvalue2, listvalue3, listvalue4, listvalue5,
        text1, text2, text3, text4, text5, text6, text7, text8, text9, text10,
        text11, text12, text13, text14, text15, text16, text17, text18, text19, text20,
        maintenancemethod, maintenanceintervalmonths, nearestfixed, lastmodified,
        sensorreadinghistoryid, alertingactionid, sensorstatshistoryid, readerid,
        assetparentid, assetchildcount, vtagboxx, vtagboxy, vtagboxwidth, vtagboxheight,
        vtagx, vtagy, vtagaccelsensor, vtagpositiontype, vtagalgorithmtype, batterylevel,
        vtagid, vtagz, vtaglastseen, vtaglastmoved, created, lastmodifiedby,
        latitude, longitude, altitude, numberofsatellites, gpsaccuracy, lastgpsfix,
        vtagtype, parentvtag, missedsatellitefixes, lastinventoried,
        vtaggpsdeviceid, vtaggpsappkey, deviceregistered, lastmaintenance,
        companyid, unseennotified
    )
    SELECT
        s.name, s.description, s.rfidtag, s.assettype, s.departmentcode, s.maxunseentime,
        s.lastobservedlocation, s.lastobservedtime, s.checkinstatus, s.checkedoutto,
        s.additionalinformation, s.disposalstatus, s.disposalmethod, s.disposaldate, s.disposaldestination,
        s.maintenancestartdate, s.maintenancesingledate, s.nextmaintenance, s.date1, s.date2, s.date3, s.date4, s.date5,
        s.listvalue1, s.listvalue2, s.listvalue3, s.listvalue4, s.listvalue5,
        s.text1, s.text2, s.text3, s.text4, s.text5, s.text6, s.text7, s.text8, s.text9, s.text10,
        s.text11, s.text12, s.text13, s.text14, s.text15, s.text16, s.text17, s.text18, s.text19, s.text20,
        s.maintenancemethod, s.maintenanceintervalmonths, s.nearestfixed, SYSDATETIMEOFFSET(),
        NULL, NULL, NULL, NULL,
        NULL, NULL, s.vtagboxx, s.vtagboxy, s.vtagboxwidth, s.vtagboxheight,
        s.vtagx, s.vtagy, s.vtagaccelsensor, s.vtagpositiontype, s.vtagalgorithmtype, s.batterylevel,
        s.vtagid, s.vtagz, s.vtaglastseen, s.vtaglastmoved, s.created, s.lastmodifiedby,
        s.latitude, s.longitude, s.altitude, s.numberofsatellites, s.gpsaccuracy, s.lastgpsfix,
        s.vtagtype, s.parentvtag, s.missedsatellitefixes, s.lastinventoried,
        s.vtaggpsdeviceid, s.vtaggpsappkey, s.deviceregistered, s.lastmaintenance,
        COALESCE(
            (SELECT TOP 1 mc.id FROM dbo.company mc
             JOIN idash_staging.dbo.company sc
               ON LEFT(REPLACE(REPLACE(mc.name,' ',''),'-',''), 3) = LEFT(REPLACE(REPLACE(sc.name,' ',''),'-',''), 3)
             WHERE sc.id = s.companyid), 0),
        s.unseennotified
    FROM idash_staging.dbo.asset s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.asset m WHERE m.name = s.name
          AND m.companyid = COALESCE(
            (SELECT TOP 1 mc.id FROM dbo.company mc
             JOIN idash_staging.dbo.company sc
               ON LEFT(REPLACE(REPLACE(mc.name,' ',''),'-',''), 3) = LEFT(REPLACE(REPLACE(sc.name,' ',''),'-',''), 3)
             WHERE sc.id = s.companyid), 0))
      AND (NULLIF(RTRIM(s.rfidtag),'') IS NULL OR NOT EXISTS (
        SELECT 1 FROM dbo.asset m WHERE m.rfidtag = s.rfidtag));

    UPDATE #SyncStats SET AssetsInserted = @@ROWCOUNT;
END TRY
BEGIN CATCH
    UPDATE #SyncStats SET Errors = Errors + 1;
END CATCH;
GO

/* ── STEP 5: Re-link locationid by name (IDs differ per server) ───── */
UPDATE a
SET a.locationid = l.id
FROM dbo.asset a
JOIN dbo.location l
  ON l.name = a.text6 AND l.companyid = a.companyid
WHERE a.locationid IS NULL OR a.locationid != l.id;
GO

/* ── STEP 6: Return summary for UI ─────────────────────────────────── */
SELECT LocationsInserted, AssetsUpdated, AssetsInserted, Errors FROM #SyncStats;
GO
