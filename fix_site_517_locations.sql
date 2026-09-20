-- ============================================================================
-- Beckley (Site 517) Location Auto-Provision & Linking Script
-- Run this on the target server in SQL Server Management Studio (SSMS)
-- connected to the iDash database.
--
-- PURPOSE:
-- 1. Auto-provisions all 1,300+ Beckley 517 locations into dbo.location
--    from the existing assets' lastobservedlocation / text6 fields.
-- 2. Links dbo.asset.locationid foreign keys so that all views (v_asset,
--    Assets by Location, Asset Master, and mobile scanners) display locations.
-- ============================================================================

USE idash;
GO

SET NOCOUNT ON;

-- 1. Identify Beckley company ID
DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = id 
FROM dbo.company 
WHERE name LIKE '%517%' OR name LIKE '%Beckley%';

IF @CompanyId IS NULL
BEGIN
    -- Fallback: check if assets have companyid populated
    SELECT TOP 1 @CompanyId = companyid 
    FROM dbo.asset 
    WHERE text7 = '517' OR name LIKE '%517%' OR lastobservedlocation LIKE '%-BD%';
END

IF @CompanyId IS NULL
BEGIN
    RAISERROR('Error: Beckley 517 company could not be found. Please ensure dbo.company has a record for Beckley 517.', 16, 1);
    RETURN;
END

PRINT '>>> Target Beckley Company ID: ' + CAST(@CompanyId AS VARCHAR);

-- 2. Auto-provision missing locations into dbo.location
PRINT '>>> Auto-provisioning missing locations into dbo.location...';

;WITH loc_src AS (
    SELECT DISTINCT 
        SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 50) AS loc_name,
        @CompanyId AS companyid,
        '517' AS site_code
    FROM dbo.asset a WITH(NOLOCK)
    WHERE (a.companyid = @CompanyId OR a.companyid IS NULL OR a.companyid = 0)
      AND NULLIF(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), '') IS NOT NULL
)
INSERT INTO dbo.location (name, site, companyid)
SELECT s.loc_name, s.site_code, s.companyid
FROM loc_src s
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.location l WITH(NOLOCK)
    WHERE l.name = s.loc_name AND l.companyid = s.companyid
);

PRINT '>>> New locations inserted into dbo.location: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- 3. Ensure all assets have the proper companyid
UPDATE a
SET a.companyid = @CompanyId
FROM dbo.asset a
WHERE (a.companyid IS NULL OR a.companyid = 0)
  AND (a.text7 = '517' OR a.name LIKE '%517%' OR a.lastobservedlocation LIKE '%-BD%');

-- 4. Link asset locationid to dbo.location.id
PRINT '>>> Linking asset location foreign keys (dbo.asset.locationid)...';

UPDATE a
SET a.locationid = l.id
FROM dbo.asset a
INNER JOIN dbo.location l 
   ON l.name = SUBSTRING(LTRIM(RTRIM(COALESCE(NULLIF(a.lastobservedlocation,''), NULLIF(a.text6,'')))), 1, 50)
  AND l.companyid = a.companyid
WHERE a.companyid = @CompanyId
  AND (a.locationid IS NULL OR a.locationid <> l.id);

PRINT '>>> Assets linked to dbo.location.id: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- 5. Verification Report
PRINT '------------------------------------------------------------';
PRINT 'VERIFICATION SUMMARY:';
PRINT '------------------------------------------------------------';
SELECT 
    (SELECT COUNT(*) FROM dbo.location WHERE companyid = @CompanyId) AS TotalLocationsInSite,
    (SELECT COUNT(*) FROM dbo.asset WHERE companyid = @CompanyId) AS TotalAssetsInSite,
    (SELECT COUNT(*) FROM dbo.asset WHERE companyid = @CompanyId AND locationid IS NOT NULL) AS AssetsWithLocationId,
    (SELECT COUNT(*) FROM dbo.asset WHERE companyid = @CompanyId AND locationid IS NULL) AS AssetsMissingLocationId;

PRINT 'Done!';
GO
