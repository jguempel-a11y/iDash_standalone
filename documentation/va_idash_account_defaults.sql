-- ============================================================================
-- iDash Default Account Diagnostics
-- Run against: iDash database on .\sqlexpress
-- Purpose: Verify default accounts, companies, and user assignments
--          Use on fresh installs or after recovery to validate setup
-- ============================================================================

-- ============================================================================
-- 1. COMPANY / SITE LISTING
--    Shows all configured companies (sites) in the system.
--    Default install creates companies for each VA station.
-- ============================================================================
PRINT '=== COMPANIES (SITES) ==='
SELECT 
    id              AS [Company ID],
    name            AS [Site Name]
FROM dbo.company 
ORDER BY id;

-- ============================================================================
-- 2. USER ACCOUNT OVERVIEW
--    Full view of all user accounts with their company assignments.
--    Key fields:
--      usertype          - Permission level (string: "Create, Edit, Delete", "View Only", etc.)
--      companyid         - FK to company.id - determines which users/assets are visible
--      hideadminpopups   - Suppresses admin notification popups
--      inventorylimiteduser - Restricts inventory scanning capabilities
--      restricteditmobile   - Prevents editing from mobile app
-- ============================================================================
PRINT ''
PRINT '=== USER ACCOUNTS WITH COMPANY ASSIGNMENTS ==='
SELECT 
    u.id            AS [User ID],
    u.username      AS [Username],
    u.firstname     AS [First Name],
    u.lastname      AS [Last Name],
    u.email         AS [Email],
    u.phone         AS [Phone],
    u.usertype      AS [User Type],
    u.companyid     AS [Company ID],
    c.name          AS [Company / Site],
    u.cardid        AS [Card ID],
    u.rfidtag       AS [RFID Tag],
    u.hideadminpopups     AS [Hide Popups],
    u.inventorylimiteduser AS [Inv Limited],
    u.restricteditmobile   AS [Restrict Mobile],
    CASE WHEN u.password IS NOT NULL THEN 'SET' ELSE 'NOT SET' END AS [Password Status]
FROM dbo.sysuser u
LEFT JOIN dbo.company c ON u.companyid = c.id
ORDER BY u.id;

-- ============================================================================
-- 3. USERS PER COMPANY
--    Shows how many users belong to each company/site.
--    IMPORTANT: Users can only see other users in the SAME company when
--    logged into iDash. If superadmin is on Company 3 but a new user
--    is on Company 4, superadmin will NOT see that user in the admin panel.
-- ============================================================================
PRINT ''
PRINT '=== USER COUNT BY COMPANY ==='
SELECT 
    c.id            AS [Company ID],
    c.name          AS [Site Name],
    COUNT(u.id)     AS [User Count],
    STRING_AGG(u.username, ', ') AS [Usernames]
FROM dbo.company c
LEFT JOIN dbo.sysuser u ON u.companyid = c.id
GROUP BY c.id, c.name
ORDER BY c.id;

-- ============================================================================
-- 4. ORPHANED USERS (no company or invalid company)
--    Users with NULL companyid or pointing to a non-existent company.
--    These users may have login issues or not appear in any admin view.
-- ============================================================================
PRINT ''
PRINT '=== ORPHANED USERS (no valid company) ==='
SELECT 
    u.id, u.username, u.companyid,
    CASE 
        WHEN u.companyid IS NULL THEN 'NULL - no company assigned'
        WHEN c.id IS NULL THEN 'INVALID - company ID does not exist'
        ELSE 'OK'
    END AS [Status]
FROM dbo.sysuser u
LEFT JOIN dbo.company c ON u.companyid = c.id
WHERE u.companyid IS NULL OR c.id IS NULL;

-- ============================================================================
-- 5. PASSWORD STATUS CHECK
--    Identifies accounts without passwords (cannot login).
--    .NET Identity V3 hashed passwords start with 'AQAAAAEAA' (base64 header).
-- ============================================================================
PRINT ''
PRINT '=== PASSWORD STATUS ==='
SELECT 
    u.username,
    CASE 
        WHEN u.password IS NULL THEN 'NO PASSWORD - cannot login'
        WHEN u.password LIKE 'AQAAAAEAA%' THEN 'Identity V3 hash (SHA256) - OK'
        WHEN u.password LIKE 'AQAAAAIAAC%' THEN 'Identity V3 hash (SHA512) - may have compat issues'
        WHEN LEN(u.password) > 20 THEN 'Hashed (unknown format)'
        ELSE 'PLAINTEXT or SHORT - likely invalid'
    END AS [Password Format],
    LEN(u.password) AS [Hash Length]
FROM dbo.sysuser u
ORDER BY u.id;

-- ============================================================================
-- 6. DEFAULT ACCOUNT EXPECTED VALUES
--    Reference for what a fresh install should look like.
--    Use this to compare against current state after recovery.
-- ============================================================================
PRINT ''
PRINT '=== EXPECTED DEFAULTS (reference from 649 system) ==='
PRINT ''
PRINT 'DEFAULT ACCOUNTS:'
PRINT '  admin       - companyid = NULL (or orphaned/invalid)'
PRINT '                usertype  = "Create, Edit, Delete"'
PRINT '                password  = demo (hashed with .NET Identity V3 SHA256)'
PRINT '                firstname, lastname, email, phone = NULL'
PRINT ''
PRINT '  superadmin  - companyid = NULL  *** CRITICAL: must be NULL ***'
PRINT '                usertype  = "Create, Edit, Delete"'
PRINT '                password  = demo (hashed with .NET Identity V3 SHA256)'
PRINT '                firstname, lastname, email, phone = NULL'
PRINT ''
PRINT 'COMPANY ASSIGNMENT RULES:'
PRINT '  superadmin/admin: companyid = NULL means "sees ALL companies/users"'
PRINT '  Regular users:    companyid = <site company id> - only sees that site'
PRINT '  If superadmin has a non-NULL companyid, it will be filtered to'
PRINT '  only that company - this is WRONG and will hide other users.'
PRINT ''
PRINT 'User Type values used in this system:'
PRINT '  "Create, Edit, Delete"   - Full access (standard user)'
PRINT '  "Create, Edit"           - Can create and edit but not delete'
PRINT '  "View Only"              - Read-only access'
PRINT ''
PRINT 'Password hash format (Identity V3 / SHA256):'
PRINT '  Header byte: 0x01'
PRINT '  PRF:         1 (SHA256) - MUST be 1, not 0 (SHA1) for compatibility'
PRINT '  Iterations:  10000'
PRINT '  Salt:        16 bytes'
PRINT '  Subkey:      32 bytes'
PRINT '  Base64 prefix: AQAAAAEAA...'
PRINT '  Hash length:   84 characters'

-- ============================================================================
-- 7. FIX: Reset admin/superadmin to factory defaults
--    Run after recovery or if admin accounts have been misconfigured.
--    CRITICAL: superadmin must have NULL companyid to see all users.
-- ============================================================================
PRINT ''
PRINT '=== FIX SCRIPTS (uncomment to run) ==='

-- 7a. Reset superadmin to factory defaults (NULL companyid, clears name fields)
-- UPDATE dbo.sysuser
--     SET companyid = NULL, firstname = NULL, lastname = NULL,
--         email = NULL, phone = NULL, usertype = 'Create, Edit, Delete'
--     WHERE username = 'superadmin';

-- 7b. Reset admin to factory defaults
-- UPDATE dbo.sysuser
--     SET companyid = NULL, firstname = NULL, lastname = NULL,
--         email = NULL, phone = NULL, usertype = 'Create, Edit, Delete'
--     WHERE username = 'admin';

-- 7c. Reset password for superadmin to 'demo' (regenerate hash via iDash)
--     Use iDash User Management > iDash tab > Edit > set new password.
--     Or use the User Management method which generates proper V3 SHA256 hash.

-- 7d. Move a specific user to the main site company
-- UPDATE dbo.sysuser
--     SET companyid = (SELECT TOP 1 id FROM dbo.company ORDER BY id)
--     WHERE username = '<target_username>';

-- 7e. Verify all is correct after fixes
-- SELECT u.username, u.companyid, c.name,
--     CASE WHEN u.companyid IS NULL THEN 'NULL (global admin - sees all)'
--          WHEN c.id IS NULL THEN 'INVALID - company does not exist'
--          ELSE 'OK - assigned to ' + c.name
--     END as [Status]
-- FROM dbo.sysuser u
-- LEFT JOIN dbo.company c ON u.companyid = c.id
-- ORDER BY u.id;


