-- ============================================================
-- GOVERNANCE REGRESSION TESTS
-- ============================================================

USE ROLE ACCOUNTADMIN;


-- ============================================================
-- 1. VERIFY MASKING POLICY EXISTS
-- ============================================================

SHOW MASKING POLICIES IN SCHEMA BANKING_DQ_DB.GOVERNANCE;


-- ============================================================
-- 2. VERIFY ROW ACCESS POLICY EXISTS
-- ============================================================

SHOW ROW ACCESS POLICIES IN SCHEMA BANKING_DQ_DB.GOVERNANCE;


-- ============================================================
-- 3. VERIFY ANALYST ACCESS
-- ============================================================
-- Expected:
--   Customer rows are accessible
--   LAST_NAME is masked

USE ROLE BANKING_ANALYST;

SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    STATE
FROM BANKING_DQ_DB.RAW.CUSTOMERS
ORDER BY CUSTOMER_ID;


-- ============================================================
-- 4. VERIFY DATA STEWARD ACCESS
-- ============================================================
-- Expected:
--   Customer rows are accessible
--   LAST_NAME contains the real value

USE ROLE BANKING_DATA_STEWARD;

SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    STATE
FROM BANKING_DQ_DB.RAW.CUSTOMERS
ORDER BY CUSTOMER_ID;


-- ============================================================
-- 5. RETURN TO ADMIN ROLE
-- ============================================================

USE ROLE ACCOUNTADMIN;