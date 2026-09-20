-- ============================================================
-- EXTRACT SCRIPT: Pull clean asset data from backup, generate
-- UPDATE statements to run on the damaged remote system
-- ============================================================
-- WORKFLOW:
-- 1. Copy the .bak from the other system to this machine
-- 2. Change the 5 paths below
-- 3. Run this script in SSMS on THIS machine
-- 4. Copy the generated UPDATE statements from the Results tab
-- 5. Paste and run them in SSMS on the OTHER (damaged) system
-- 6. Re-run the cleanup section to drop the temp DB
-- ============================================================

-- ═══════ CONFIGURE THESE ═══════
DECLARE @BackupPath NVARCHAR(500) = N'C:\path\to\backup_from_other_system.bak';
DECLARE @TempDB     NVARCHAR(128) = N'Recovery_Temp';
DECLARE @MdfPath    NVARCHAR(500) = N'C:\temp\Recovery_Temp.mdf';
DECLARE @LdfPath    NVARCHAR(500) = N'C:\temp\Recovery_Temp.ldf';
DECLARE @TargetDB   NVARCHAR(128) = N'iDash';  -- DB name on the OTHER system
-- ════════════════════════════════

-- Step 1: Get logical file names from backup
DECLARE @DataName NVARCHAR(128), @LogName NVARCHAR(128);
DECLARE @fileList TABLE (
    LogicalName NVARCHAR(128), PhysicalName NVARCHAR(260), Type CHAR(1),
    FileGroupName NVARCHAR(128), Size NUMERIC(20,0), MaxSize NUMERIC(20,0),
    FileID BIGINT, CreateLSN NUMERIC(25,0), DropLSN NUMERIC(25,0),
    UniqueID UNIQUEIDENTIFIER, ReadOnlyLSN NUMERIC(25,0), ReadWriteLSN NUMERIC(25,0),
    BackupSizeInBytes BIGINT, SourceBlockSize INT, FileGroupID INT,
    LogGroupGUID UNIQUEIDENTIFIER, DifferentialBaseLSN NUMERIC(25,0),
    DifferentialBaseGUID UNIQUEIDENTIFIER, IsReadOnly BIT, IsPresent BIT,
    TDEThumbprint VARBINARY(32), SnapshotURL NVARCHAR(360)
);
INSERT @fileList EXEC('RESTORE FILELISTONLY FROM DISK = N''' + @BackupPath + '''');
SELECT @DataName = LogicalName FROM @fileList WHERE Type = 'D';
SELECT @LogName  = LogicalName FROM @fileList WHERE Type = 'L';
PRINT 'Logical names: ' + @DataName + ' / ' + @LogName;

-- Step 2: Restore as temp DB on this machine
PRINT 'Restoring backup...';
DECLARE @restoreSql NVARCHAR(MAX) = N'RESTORE DATABASE ' + QUOTENAME(@TempDB) +
    N' FROM DISK = N''' + @BackupPath + '''' +
    N' WITH MOVE N''' + @DataName + N''' TO N''' + @MdfPath + N''',' +
    N' MOVE N''' + @LogName + N''' TO N''' + @LdfPath + N''',' +
    N' REPLACE, RECOVERY';
EXEC sp_executesql @restoreSql;
PRINT 'Restore complete.';
GO

-- ============================================================
-- Step 3: Generate UPDATE statements for damaged records
-- Run this after the restore above completes
-- ============================================================
-- IMPORTANT: In SSMS go to Query > Results To > Results to Text
-- (Ctrl+T) so you can copy the full output. Also set:
-- Tools > Options > Query Results > Max Characters per column = 8000
-- ============================================================

USE [Recovery_Temp];  -- change if you used a different @TempDB name
GO

PRINT '-- ============================================================';
PRINT '-- PASTE EVERYTHING BELOW INTO SSMS ON THE DAMAGED SYSTEM';
PRINT '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '-- Source: backup restored on recovery machine';
PRINT '-- Target: records WHERE lastmodifiedby = ''iDashDiag''';
PRINT '-- ============================================================';
PRINT '';
PRINT 'BEGIN TRANSACTION;';
PRINT '';

SELECT 
    'UPDATE dbo.asset SET ' +
    'rfidtag = '              + ISNULL('N''' + REPLACE(rfidtag, '''', '''''') + '''', 'NULL') + ', ' +
    'assettype = '            + ISNULL('N''' + REPLACE(assettype, '''', '''''') + '''', 'NULL') + ', ' +
    'departmentcode = '       + ISNULL('N''' + REPLACE(departmentcode, '''', '''''') + '''', 'NULL') + ', ' +
    'maxunseentime = '        + ISNULL('N''' + REPLACE(CAST(maxunseentime AS VARCHAR), '''', '''''') + '''', 'NULL') + ', ' +
    'lastobservedlocation = ' + ISNULL('N''' + REPLACE(lastobservedlocation, '''', '''''') + '''', 'NULL') + ', ' +
    'lastobservedtime = '     + ISNULL('''' + CONVERT(VARCHAR(50), lastobservedtime, 126) + '''', 'NULL') + ', ' +
    'checkinstatus = '        + ISNULL('N''' + REPLACE(checkinstatus, '''', '''''') + '''', 'NULL') + ', ' +
    'checkedoutto = '         + ISNULL('N''' + REPLACE(checkedoutto, '''', '''''') + '''', 'NULL') + ', ' +
    'additionalinformation = '+ ISNULL('N''' + REPLACE(additionalinformation, '''', '''''') + '''', 'NULL') + ', ' +
    'disposalstatus = '       + ISNULL('N''' + REPLACE(disposalstatus, '''', '''''') + '''', 'NULL') + ', ' +
    'disposalmethod = '       + ISNULL('N''' + REPLACE(disposalmethod, '''', '''''') + '''', 'NULL') + ', ' +
    'disposaldate = '         + ISNULL('''' + CONVERT(VARCHAR(50), disposaldate, 126) + '''', 'NULL') + ', ' +
    'disposaldestination = '  + ISNULL('N''' + REPLACE(disposaldestination, '''', '''''') + '''', 'NULL') + ', ' +
    'date1 = '                + ISNULL('''' + CONVERT(VARCHAR(50), date1, 126) + '''', 'NULL') + ', ' +
    'date2 = '                + ISNULL('''' + CONVERT(VARCHAR(50), date2, 126) + '''', 'NULL') + ', ' +
    'date3 = '                + ISNULL('''' + CONVERT(VARCHAR(50), date3, 126) + '''', 'NULL') + ', ' +
    'date4 = '                + ISNULL('''' + CONVERT(VARCHAR(50), date4, 126) + '''', 'NULL') + ', ' +
    'date5 = '                + ISNULL('''' + CONVERT(VARCHAR(50), date5, 126) + '''', 'NULL') + ', ' +
    'listvalue1 = '           + ISNULL('N''' + REPLACE(listvalue1, '''', '''''') + '''', 'NULL') + ', ' +
    'listvalue2 = '           + ISNULL('N''' + REPLACE(listvalue2, '''', '''''') + '''', 'NULL') + ', ' +
    'listvalue3 = '           + ISNULL('N''' + REPLACE(listvalue3, '''', '''''') + '''', 'NULL') + ', ' +
    'listvalue4 = '           + ISNULL('N''' + REPLACE(listvalue4, '''', '''''') + '''', 'NULL') + ', ' +
    'listvalue5 = '           + ISNULL('N''' + REPLACE(listvalue5, '''', '''''') + '''', 'NULL') + ', ' +
    'text2 = '                + ISNULL('N''' + REPLACE(text2, '''', '''''') + '''', 'NULL') + ', ' +
    'text4 = '                + ISNULL('N''' + REPLACE(text4, '''', '''''') + '''', 'NULL') + ', ' +
    'text5 = '                + ISNULL('N''' + REPLACE(text5, '''', '''''') + '''', 'NULL') + ', ' +
    'text6 = '                + ISNULL('N''' + REPLACE(text6, '''', '''''') + '''', 'NULL') + ', ' +
    'text7 = '                + ISNULL('N''' + REPLACE(text7, '''', '''''') + '''', 'NULL') + ', ' +
    'text8 = '                + ISNULL('N''' + REPLACE(text8, '''', '''''') + '''', 'NULL') + ', ' +
    'text9 = '                + ISNULL('N''' + REPLACE(text9, '''', '''''') + '''', 'NULL') + ', ' +
    'text10 = '               + ISNULL('N''' + REPLACE(text10, '''', '''''') + '''', 'NULL') + ', ' +
    'text11 = '               + ISNULL('N''' + REPLACE(text11, '''', '''''') + '''', 'NULL') + ', ' +
    'text12 = '               + ISNULL('N''' + REPLACE(text12, '''', '''''') + '''', 'NULL') + ', ' +
    'text13 = '               + ISNULL('N''' + REPLACE(text13, '''', '''''') + '''', 'NULL') + ', ' +
    'text14 = '               + ISNULL('N''' + REPLACE(text14, '''', '''''') + '''', 'NULL') + ', ' +
    'text15 = '               + ISNULL('N''' + REPLACE(text15, '''', '''''') + '''', 'NULL') + ', ' +
    'text16 = '               + ISNULL('N''' + REPLACE(text16, '''', '''''') + '''', 'NULL') + ', ' +
    'text17 = '               + ISNULL('N''' + REPLACE(text17, '''', '''''') + '''', 'NULL') + ', ' +
    'text18 = '               + ISNULL('N''' + REPLACE(text18, '''', '''''') + '''', 'NULL') + ', ' +
    'text19 = '               + ISNULL('N''' + REPLACE(text19, '''', '''''') + '''', 'NULL') + ', ' +
    'text20 = '               + ISNULL('N''' + REPLACE(text20, '''', '''''') + '''', 'NULL') + ', ' +
    'maintenancemethod = '    + ISNULL('N''' + REPLACE(maintenancemethod, '''', '''''') + '''', 'NULL') + ', ' +
    'maintenanceintervalmonths = ' + ISNULL(CAST(maintenanceintervalmonths AS VARCHAR), 'NULL') + ', ' +
    'locationid = '           + ISNULL(CAST(locationid AS VARCHAR), 'NULL') + ', ' +
    'lastmodified = '         + ISNULL('''' + CONVERT(VARCHAR(50), lastmodified, 126) + '''', 'NULL') + ', ' +
    'lastmodifiedby = '       + ISNULL('N''' + REPLACE(lastmodifiedby, '''', '''''') + '''', 'NULL') + ', ' +
    'lastinventoried = '      + ISNULL('''' + CONVERT(VARCHAR(50), lastinventoried, 126) + '''', 'NULL') +
    ' WHERE id = ' + CAST(id AS VARCHAR) + ';' AS [-- Run on damaged system]
FROM dbo.asset
WHERE id IN (177324,177325,177326,177327,177328,177329,177330,177331,177332,177333,
             177334,177335,177336,177337,177338,177339,177340,177341,177342,177343,
             177344,177345,177346,177347,177348,177349,177350,177351,177352,177353,
             177354,177355,177356,177357,177358,177359,177360,177361,177362,177363,
             177364,177365,177366,177367)
ORDER BY id;

PRINT '';
PRINT 'COMMIT;';
PRINT '';
PRINT '-- Verify: should show restored lastmodifiedby values (not iDashDiag)';
PRINT 'SELECT id, name, rfidtag, lastmodifiedby FROM dbo.asset WHERE id BETWEEN 177324 AND 177367 ORDER BY id;';

GO
-- ============================================================
-- Step 4: CLEANUP — run after you've copied the output
-- ============================================================
USE [master];
GO
DROP DATABASE IF EXISTS [Recovery_Temp];
PRINT 'Temp database dropped. Done.';
