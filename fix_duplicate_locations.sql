/* ===============================
   FIX DUPLICATE LOCATIONS SCRIPT
   - Identifies corrupted locations (e.g., 'SPringfield' instead of 'SPSpringfield')
   - Merges duplicates into the correct location if it exists.
   - Renames corrupted locations if the correct one doesn't exist.
   =============================== */

USE [idash];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    DECLARE @MergedCount INT = 0;
    DECLARE @RenamedCount INT = 0;

    -- Create temp table to hold candidates for fixing
    IF OBJECT_ID('tempdb..#FixCandidates') IS NOT NULL DROP TABLE #FixCandidates;

    CREATE TABLE #FixCandidates (
        BadLocationId INT,
        BadName NVARCHAR(500),
        GoodLocationId INT,
        GoodName NVARCHAR(500),
        ActionType NVARCHAR(50) -- 'MERGE' or 'RENAME'
    );

    /* 1. IDENTIFY CANDIDATES
       Logic: Find locations starting with 'SP' where adding 'Sp' makes a valid-looking name match.
       The bug stripped the first 2 chars of the original name if it started with 'SP' (case insensitive).
       So 'Springfield' became 'ringfield', then got 'SP' added back -> 'SPringfield'.
       Calculated Correct Name = 'SP' + 'Sp' + SUBSTRING(BadName, 3, LEN).
    */
    INSERT INTO #FixCandidates (BadLocationId, BadName, GoodLocationId, GoodName, ActionType)
    SELECT 
        Bad.id,
        Bad.name,
        Good.id,
        'SP' + 'Sp' + SUBSTRING(Bad.name, 3, 4000), -- Constructed Good Name
        CASE WHEN Good.id IS NOT NULL THEN 'MERGE' ELSE 'RENAME' END
    FROM dbo.location Bad
    LEFT JOIN dbo.location Good 
        ON Good.name = 'SP' + 'Sp' + SUBSTRING(Bad.name, 3, 4000)
        AND Good.companyid = Bad.companyid
    WHERE Bad.name LIKE 'SP%'
      AND LEN(Bad.name) > 2
      -- Filter to only likely corruptions? 
      -- e.g. 'SPringfield' matching 'Springfield' pattern is hard to be 100% sure without a dictionary.
      -- BUT, if 'SPSpringfield' EXISTS (Merge case), it's extremely high confidence.
      -- For RENAME case, we should be careful.
      -- Let's focus on MERGE first for safety.
      AND Good.id IS NOT NULL; 
      
    /* 2. MERGE DUPLICATES (Updating Assets to point to Good Location) */
    UPDATE a
    SET a.locationid = fc.GoodLocationId
    FROM dbo.asset a
    JOIN #FixCandidates fc ON fc.BadLocationId = a.locationid
    WHERE fc.ActionType = 'MERGE';

    /* 3. DELETE BAD LOCATIONS (After Merge) */
    DELETE l
    FROM dbo.location l
    JOIN #FixCandidates fc ON fc.BadLocationId = l.id
    WHERE fc.ActionType = 'MERGE';

    SET @MergedCount = @@ROWCOUNT;

    /* 4. OPTIONAL: RENAME ORPHANED BAD LOCATIONS?
       If 'SPSpringfield' didn't exist, we might want to rename 'SPringfield' -> 'SPSpringfield'.
       Uncomment below to enable. 
    */
    /*
    UPDATE l
    SET l.name = 'SP' + 'Sp' + SUBSTRING(l.name, 3, 4000)
    FROM dbo.location l
    WHERE l.name LIKE 'SP%' 
      AND NOT EXISTS (SELECT 1 FROM dbo.location existing WHERE existing.name = 'SP' + 'Sp' + SUBSTRING(l.name, 3, 4000) AND existing.companyid = l.companyid)
      -- Add more heuristics here to be safe?
    */

    COMMIT;

    /* REPORT */
    SELECT * FROM #FixCandidates;
    PRINT 'Merged ' + CAST(@MergedCount AS VARCHAR(10)) + ' duplicate locations.';

END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    PRINT 'Error: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
