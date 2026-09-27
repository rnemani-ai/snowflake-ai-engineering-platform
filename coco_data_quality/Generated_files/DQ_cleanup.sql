/*=============================================================================
  DQ_cleanup.sql
  Data Quality Framework — Step 8: Cleanup Script
  
  WARNING: This script drops ALL objects created by the DQ framework.
  DO NOT execute unless you want to remove everything.
  
  Objects dropped:
    1. DQ Framework tables (DQ_MONITORING schema)
    2. Stored procedure
    3. DQ_MONITORING schema
    4. Source tables (RAW schema)
    5. RAW schema
    6. BANKING_DQ_DB database
    7. DATA_METRIC_SCHEDULE settings (if set)
=============================================================================*/

-- ============================================================================
-- 1. REMOVE DATA_METRIC_SCHEDULE FROM SOURCE TABLES (if set)
-- ============================================================================

ALTER TABLE BANKING_DQ_DB.RAW.BRANCHES UNSET DATA_METRIC_SCHEDULE;
ALTER TABLE BANKING_DQ_DB.RAW.CUSTOMERS UNSET DATA_METRIC_SCHEDULE;
ALTER TABLE BANKING_DQ_DB.RAW.ACCOUNTS UNSET DATA_METRIC_SCHEDULE;
ALTER TABLE BANKING_DQ_DB.RAW.TRANSACTIONS UNSET DATA_METRIC_SCHEDULE;
ALTER TABLE BANKING_DQ_DB.RAW.LOAN_APPLICATIONS UNSET DATA_METRIC_SCHEDULE;

-- ============================================================================
-- 2. DROP STORED PROCEDURE
-- ============================================================================

DROP PROCEDURE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK(VARCHAR);

-- ============================================================================
-- 3. DROP DQ FRAMEWORK TABLES
-- ============================================================================

DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_ANOMALY_RESULTS;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_ERROR_RECORDS;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_CONFIG;

-- ============================================================================
-- 4. DROP DQ_MONITORING SCHEMA
-- ============================================================================

DROP SCHEMA IF EXISTS BANKING_DQ_DB.DQ_MONITORING;

-- ============================================================================
-- 5. DROP SOURCE TABLES (RAW SCHEMA)
-- ============================================================================

DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.TRANSACTIONS;
DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;
DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.ACCOUNTS;
DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.CUSTOMERS;
DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.BRANCHES;

-- ============================================================================
-- 6. DROP RAW SCHEMA
-- ============================================================================

DROP SCHEMA IF EXISTS BANKING_DQ_DB.RAW;

-- ============================================================================
-- 7. DROP DATABASE
-- ============================================================================

DROP DATABASE IF EXISTS BANKING_DQ_DB;

-- ============================================================================
-- 8. VERIFICATION — Confirm cleanup is complete
-- ============================================================================

-- These should return no results after cleanup:
-- SHOW SCHEMAS IN DATABASE BANKING_DQ_DB;       -- Should error: DB doesn't exist
-- SHOW TABLES IN SCHEMA BANKING_DQ_DB.RAW;      -- Should error: DB doesn't exist
-- SHOW TABLES IN SCHEMA BANKING_DQ_DB.DQ_MONITORING; -- Should error: DB doesn't exist

/*=============================================================================
  NOTE: The Streamlit app folder (dq-monitoring-dashboard/) in the Workspace
  is a file-system artifact and is NOT dropped by SQL. Delete it manually
  from the Workspace file tree if no longer needed.
  
  Workspace script files (Data_quality_framework_with_Snowflake_CoCo/) are
  also file-system artifacts — delete manually if desired.
=============================================================================*/
