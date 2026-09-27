/*=============================================================================
  DQ_data_profiling.sql
  Data Quality Framework — Step 1: Data Profiling
  Database: BANKING_DQ_DB  |  Schema: RAW
  Tables : BRANCHES, CUSTOMERS, ACCOUNTS, TRANSACTIONS, LOAN_APPLICATIONS
=============================================================================*/

USE DATABASE BANKING_DQ_DB;
USE SCHEMA RAW;

-- ============================================================================
-- 1. TABLE STRUCTURES
-- ============================================================================

SHOW COLUMNS IN BANKING_DQ_DB.RAW.BRANCHES;
SHOW COLUMNS IN BANKING_DQ_DB.RAW.CUSTOMERS;
SHOW COLUMNS IN BANKING_DQ_DB.RAW.ACCOUNTS;
SHOW COLUMNS IN BANKING_DQ_DB.RAW.TRANSACTIONS;
SHOW COLUMNS IN BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;

-- ============================================================================
-- 2. ROW COUNTS
-- ============================================================================

SELECT 'BRANCHES' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM BANKING_DQ_DB.RAW.BRANCHES
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM BANKING_DQ_DB.RAW.CUSTOMERS
UNION ALL SELECT 'ACCOUNTS', COUNT(*) FROM BANKING_DQ_DB.RAW.ACCOUNTS
UNION ALL SELECT 'TRANSACTIONS', COUNT(*) FROM BANKING_DQ_DB.RAW.TRANSACTIONS
UNION ALL SELECT 'LOAN_APPLICATIONS', COUNT(*) FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;

-- ============================================================================
-- 3. BRANCHES — Profiling
-- ============================================================================

-- 3a. Null analysis & distinct counts
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT BRANCH_ID) AS distinct_branch_id,
  SUM(CASE WHEN BRANCH_ID IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
  SUM(CASE WHEN BRANCH_NAME IS NULL THEN 1 ELSE 0 END) AS null_branch_name,
  SUM(CASE WHEN CITY IS NULL THEN 1 ELSE 0 END) AS null_city,
  SUM(CASE WHEN STATE IS NULL THEN 1 ELSE 0 END) AS null_state,
  SUM(CASE WHEN IFSC_CODE IS NULL THEN 1 ELSE 0 END) AS null_ifsc_code,
  SUM(CASE WHEN IS_ACTIVE IS NULL THEN 1 ELSE 0 END) AS null_is_active,
  SUM(CASE WHEN CREATED_AT IS NULL THEN 1 ELSE 0 END) AS null_created_at,
  COUNT(DISTINCT IFSC_CODE) AS distinct_ifsc,
  COUNT(DISTINCT CITY) AS distinct_city,
  COUNT(DISTINCT STATE) AS distinct_state,
  MIN(CREATED_AT) AS min_created,
  MAX(CREATED_AT) AS max_created
FROM BANKING_DQ_DB.RAW.BRANCHES;

-- 3b. Sample data
SELECT * FROM BANKING_DQ_DB.RAW.BRANCHES LIMIT 10;

-- ============================================================================
-- 4. CUSTOMERS — Profiling
-- ============================================================================

-- 4a. Null analysis & distinct counts
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT CUSTOMER_ID) AS distinct_customer_id,
  SUM(CASE WHEN CUSTOMER_ID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN FIRST_NAME IS NULL THEN 1 ELSE 0 END) AS null_first_name,
  SUM(CASE WHEN LAST_NAME IS NULL THEN 1 ELSE 0 END) AS null_last_name,
  SUM(CASE WHEN EMAIL IS NULL THEN 1 ELSE 0 END) AS null_email,
  SUM(CASE WHEN PHONE IS NULL THEN 1 ELSE 0 END) AS null_phone,
  SUM(CASE WHEN DATE_OF_BIRTH IS NULL THEN 1 ELSE 0 END) AS null_dob,
  SUM(CASE WHEN KYC_STATUS IS NULL THEN 1 ELSE 0 END) AS null_kyc,
  SUM(CASE WHEN RISK_CATEGORY IS NULL THEN 1 ELSE 0 END) AS null_risk,
  SUM(CASE WHEN BRANCH_ID IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
  COUNT(DISTINCT EMAIL) AS distinct_email,
  COUNT(DISTINCT KYC_STATUS) AS distinct_kyc_status,
  COUNT(DISTINCT RISK_CATEGORY) AS distinct_risk_category,
  MIN(DATE_OF_BIRTH) AS min_dob,
  MAX(DATE_OF_BIRTH) AS max_dob,
  MIN(CREATED_AT) AS min_created,
  MAX(CREATED_AT) AS max_created
FROM BANKING_DQ_DB.RAW.CUSTOMERS;

-- 4b. KYC Status distribution
SELECT KYC_STATUS, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.CUSTOMERS GROUP BY KYC_STATUS;

-- 4c. Risk Category distribution
SELECT RISK_CATEGORY, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.CUSTOMERS GROUP BY RISK_CATEGORY;

-- 4d. Sample data
SELECT * FROM BANKING_DQ_DB.RAW.CUSTOMERS LIMIT 10;

-- ============================================================================
-- 5. ACCOUNTS — Profiling
-- ============================================================================

-- 5a. Null analysis & distinct counts
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ACCOUNT_ID) AS distinct_account_id,
  SUM(CASE WHEN ACCOUNT_ID IS NULL THEN 1 ELSE 0 END) AS null_account_id,
  SUM(CASE WHEN CUSTOMER_ID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN BRANCH_ID IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
  SUM(CASE WHEN ACCOUNT_TYPE IS NULL THEN 1 ELSE 0 END) AS null_account_type,
  SUM(CASE WHEN ACCOUNT_STATUS IS NULL THEN 1 ELSE 0 END) AS null_account_status,
  SUM(CASE WHEN OPEN_DATE IS NULL THEN 1 ELSE 0 END) AS null_open_date,
  SUM(CASE WHEN BALANCE IS NULL THEN 1 ELSE 0 END) AS null_balance,
  SUM(CASE WHEN CURRENCY IS NULL THEN 1 ELSE 0 END) AS null_currency,
  COUNT(DISTINCT ACCOUNT_TYPE) AS distinct_acct_type,
  COUNT(DISTINCT ACCOUNT_STATUS) AS distinct_acct_status,
  COUNT(DISTINCT CURRENCY) AS distinct_currency,
  MIN(BALANCE) AS min_balance,
  MAX(BALANCE) AS max_balance,
  AVG(BALANCE) AS avg_balance,
  MIN(OPEN_DATE) AS min_open_date,
  MAX(OPEN_DATE) AS max_open_date
FROM BANKING_DQ_DB.RAW.ACCOUNTS;

-- 5b. Account Type distribution
SELECT ACCOUNT_TYPE, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.ACCOUNTS GROUP BY ACCOUNT_TYPE;

-- 5c. Account Status distribution
SELECT ACCOUNT_STATUS, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.ACCOUNTS GROUP BY ACCOUNT_STATUS;

-- 5d. Currency distribution
SELECT CURRENCY, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.ACCOUNTS GROUP BY CURRENCY;

-- 5e. Sample data
SELECT * FROM BANKING_DQ_DB.RAW.ACCOUNTS LIMIT 10;

-- ============================================================================
-- 6. TRANSACTIONS — Profiling
-- ============================================================================

-- 6a. Null analysis & distinct counts
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT TRANSACTION_ID) AS distinct_txn_id,
  SUM(CASE WHEN TRANSACTION_ID IS NULL THEN 1 ELSE 0 END) AS null_txn_id,
  SUM(CASE WHEN ACCOUNT_ID IS NULL THEN 1 ELSE 0 END) AS null_account_id,
  SUM(CASE WHEN TRANSACTION_DATE IS NULL THEN 1 ELSE 0 END) AS null_txn_date,
  SUM(CASE WHEN TRANSACTION_TYPE IS NULL THEN 1 ELSE 0 END) AS null_txn_type,
  SUM(CASE WHEN AMOUNT IS NULL THEN 1 ELSE 0 END) AS null_amount,
  SUM(CASE WHEN CHANNEL IS NULL THEN 1 ELSE 0 END) AS null_channel,
  SUM(CASE WHEN MERCHANT_CATEGORY IS NULL THEN 1 ELSE 0 END) AS null_merchant,
  SUM(CASE WHEN TRANSACTION_STATUS IS NULL THEN 1 ELSE 0 END) AS null_txn_status,
  COUNT(DISTINCT TRANSACTION_TYPE) AS distinct_txn_type,
  COUNT(DISTINCT CHANNEL) AS distinct_channel,
  COUNT(DISTINCT MERCHANT_CATEGORY) AS distinct_merchant,
  COUNT(DISTINCT TRANSACTION_STATUS) AS distinct_txn_status,
  MIN(AMOUNT) AS min_amount,
  MAX(AMOUNT) AS max_amount,
  AVG(AMOUNT) AS avg_amount,
  MIN(TRANSACTION_DATE) AS min_txn_date,
  MAX(TRANSACTION_DATE) AS max_txn_date
FROM BANKING_DQ_DB.RAW.TRANSACTIONS;

-- 6b. Transaction Type distribution
SELECT TRANSACTION_TYPE, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.TRANSACTIONS GROUP BY TRANSACTION_TYPE;

-- 6c. Transaction Status distribution
SELECT TRANSACTION_STATUS, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.TRANSACTIONS GROUP BY TRANSACTION_STATUS;

-- 6d. Channel distribution
SELECT CHANNEL, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.TRANSACTIONS GROUP BY CHANNEL;

-- 6e. Amount statistics
SELECT 
  MIN(AMOUNT) AS min_amt, MAX(AMOUNT) AS max_amt, AVG(AMOUNT) AS avg_amt,
  MEDIAN(AMOUNT) AS median_amt, STDDEV(AMOUNT) AS stddev_amt
FROM BANKING_DQ_DB.RAW.TRANSACTIONS;

-- 6f. Sample data
SELECT * FROM BANKING_DQ_DB.RAW.TRANSACTIONS LIMIT 10;

-- ============================================================================
-- 7. LOAN_APPLICATIONS — Profiling
-- ============================================================================

-- 7a. Null analysis & distinct counts
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT APPLICATION_ID) AS distinct_app_id,
  SUM(CASE WHEN APPLICATION_ID IS NULL THEN 1 ELSE 0 END) AS null_app_id,
  SUM(CASE WHEN CUSTOMER_ID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN BRANCH_ID IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
  SUM(CASE WHEN LOAN_TYPE IS NULL THEN 1 ELSE 0 END) AS null_loan_type,
  SUM(CASE WHEN APPLICATION_DATE IS NULL THEN 1 ELSE 0 END) AS null_app_date,
  SUM(CASE WHEN REQUESTED_AMOUNT IS NULL THEN 1 ELSE 0 END) AS null_req_amt,
  SUM(CASE WHEN APPROVED_AMOUNT IS NULL THEN 1 ELSE 0 END) AS null_appr_amt,
  SUM(CASE WHEN APPLICATION_STATUS IS NULL THEN 1 ELSE 0 END) AS null_app_status,
  SUM(CASE WHEN CREDIT_SCORE IS NULL THEN 1 ELSE 0 END) AS null_credit_score,
  COUNT(DISTINCT LOAN_TYPE) AS distinct_loan_type,
  COUNT(DISTINCT APPLICATION_STATUS) AS distinct_app_status,
  MIN(REQUESTED_AMOUNT) AS min_req_amt,
  MAX(REQUESTED_AMOUNT) AS max_req_amt,
  MIN(APPROVED_AMOUNT) AS min_appr_amt,
  MAX(APPROVED_AMOUNT) AS max_appr_amt,
  MIN(CREDIT_SCORE) AS min_credit,
  MAX(CREDIT_SCORE) AS max_credit,
  MIN(APPLICATION_DATE) AS min_app_date,
  MAX(APPLICATION_DATE) AS max_app_date
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;

-- 7b. Loan Type distribution
SELECT LOAN_TYPE, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS GROUP BY LOAN_TYPE;

-- 7c. Application Status distribution
SELECT APPLICATION_STATUS, COUNT(*) AS cnt FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS GROUP BY APPLICATION_STATUS;

-- 7d. Credit Score statistics
SELECT 
  MIN(CREDIT_SCORE) AS min_score, MAX(CREDIT_SCORE) AS max_score,
  AVG(CREDIT_SCORE) AS avg_score, MEDIAN(CREDIT_SCORE) AS median_score
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;

-- 7e. Sample data
SELECT * FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS LIMIT 10;

-- ============================================================================
-- 8. CROSS-TABLE REFERENTIAL INTEGRITY CHECKS
-- ============================================================================

-- 8a. Orphan CUSTOMER_ID in ACCOUNTS (not in CUSTOMERS)
SELECT COUNT(*) AS orphan_customer_in_accounts
FROM BANKING_DQ_DB.RAW.ACCOUNTS a
WHERE NOT EXISTS (SELECT 1 FROM BANKING_DQ_DB.RAW.CUSTOMERS c WHERE c.CUSTOMER_ID = a.CUSTOMER_ID);

-- 8b. Orphan BRANCH_ID in CUSTOMERS (not in BRANCHES)
SELECT COUNT(*) AS orphan_branch_in_customers
FROM BANKING_DQ_DB.RAW.CUSTOMERS c
WHERE NOT EXISTS (SELECT 1 FROM BANKING_DQ_DB.RAW.BRANCHES b WHERE b.BRANCH_ID = c.BRANCH_ID);

-- 8c. Orphan BRANCH_ID in ACCOUNTS (not in BRANCHES)
SELECT COUNT(*) AS orphan_branch_in_accounts
FROM BANKING_DQ_DB.RAW.ACCOUNTS a
WHERE NOT EXISTS (SELECT 1 FROM BANKING_DQ_DB.RAW.BRANCHES b WHERE b.BRANCH_ID = a.BRANCH_ID);

-- 8d. Orphan ACCOUNT_ID in TRANSACTIONS (not in ACCOUNTS)
SELECT COUNT(*) AS orphan_account_in_transactions
FROM BANKING_DQ_DB.RAW.TRANSACTIONS t
WHERE NOT EXISTS (SELECT 1 FROM BANKING_DQ_DB.RAW.ACCOUNTS a WHERE a.ACCOUNT_ID = t.ACCOUNT_ID);

-- 8e. Orphan CUSTOMER_ID in LOAN_APPLICATIONS (not in CUSTOMERS)
SELECT COUNT(*) AS orphan_customer_in_loans
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS l
WHERE NOT EXISTS (SELECT 1 FROM BANKING_DQ_DB.RAW.CUSTOMERS c WHERE c.CUSTOMER_ID = l.CUSTOMER_ID);

-- 8f. Orphan BRANCH_ID in LOAN_APPLICATIONS (not in BRANCHES)
SELECT COUNT(*) AS orphan_branch_in_loans
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS l
WHERE NOT EXISTS (SELECT 1 FROM BANKING_DQ_DB.RAW.BRANCHES b WHERE b.BRANCH_ID = l.BRANCH_ID);

/*=============================================================================
  END OF PROFILING SCRIPT
=============================================================================*/
