/*=============================================================================
  DQ_Proposed_Rules.sql
  Data Quality Framework — Step 2: Recommended Data Quality Rules
  Database: BANKING_DQ_DB  |  Schema: RAW
  
  63 rules across 5 tables covering all DQ dimensions:
    Completeness, Uniqueness, Validity, Accuracy, Consistency,
    Timeliness/Freshness, Referential Integrity
  
  Rule Types: Technical (T) and Business (B)
  Priority Levels: HIGH, MEDIUM, LOW
=============================================================================*/

/*-----------------------------------------------------------------------------
  IMPLEMENTATION APPROACH:
  
  - System DMFs (Snowflake built-in): NULL_COUNT, DUPLICATE_COUNT, ROW_COUNT, 
    FRESHNESS — used for standard completeness, uniqueness, volume, timeliness.
  - ACCEPTED_VALUES: Used for categorical column validation.
  - Custom DMFs: Used for business logic, cross-column, format validation, 
    range checks, and referential integrity where system DMFs don't cover.
  
  Each rule below lists:
    Rule #, Name, Type (T/B), Dimension, Table, Column(s), Description,
    Priority (H/M/L), Implementation (System DMF / Custom DMF / ACCEPTED_VALUES)
-----------------------------------------------------------------------------*/

-- ============================================================================
-- TABLE 1: BRANCHES (9 rules)
-- ============================================================================

/*
Rule | Name                  | Type | Dimension      | Column(s)   | Description                                            | Priority | Implementation
-----|----------------------|------|----------------|-------------|--------------------------------------------------------|----------|---------------
1    | BR_NULL_BRANCH_ID    | T    | Completeness   | BRANCH_ID   | BRANCH_ID must not be NULL                             | HIGH     | System DMF: NULL_COUNT
2    | BR_NULL_BRANCH_NAME  | T    | Completeness   | BRANCH_NAME | BRANCH_NAME must not be NULL (1 NULL found in profile) | HIGH     | System DMF: NULL_COUNT
3    | BR_NULL_IFSC_CODE    | T    | Completeness   | IFSC_CODE   | IFSC_CODE must not be NULL                             | HIGH     | System DMF: NULL_COUNT
4    | BR_UNIQUE_BRANCH_ID  | T    | Uniqueness     | BRANCH_ID   | BRANCH_ID must be unique (primary key)                 | HIGH     | System DMF: DUPLICATE_COUNT
5    | BR_UNIQUE_IFSC       | T    | Uniqueness     | IFSC_CODE   | IFSC_CODE must be unique per branch                    | HIGH     | System DMF: DUPLICATE_COUNT
6    | BR_IFSC_FORMAT       | T    | Validity       | IFSC_CODE   | IFSC must match ^[A-Z]{4}0[A-Z0-9]{6}$                | MEDIUM   | Custom DMF
7    | BR_VALID_IS_ACTIVE   | T    | Validity       | IS_ACTIVE   | IS_ACTIVE must not be NULL (boolean completeness)      | MEDIUM   | System DMF: NULL_COUNT
8    | BR_ROW_COUNT         | T    | Completeness   | (table)     | Monitor table row count for anomalies                  | MEDIUM   | System DMF: ROW_COUNT
9    | BR_FRESHNESS         | T    | Timeliness     | CREATED_AT  | Monitor data freshness                                 | LOW      | System DMF: FRESHNESS
*/

-- ============================================================================
-- TABLE 2: CUSTOMERS (13 rules)
-- ============================================================================

/*
Rule | Name                  | Type | Dimension      | Column(s)        | Description                                                      | Priority | Implementation
-----|----------------------|------|----------------|------------------|------------------------------------------------------------------|----------|---------------
10   | CU_NULL_CUSTOMER_ID  | T    | Completeness   | CUSTOMER_ID      | CUSTOMER_ID must not be NULL                                     | HIGH     | System DMF: NULL_COUNT
11   | CU_NULL_EMAIL        | T    | Completeness   | EMAIL            | EMAIL must not be NULL                                           | HIGH     | System DMF: NULL_COUNT
12   | CU_NULL_FIRST_NAME   | T    | Completeness   | FIRST_NAME       | FIRST_NAME must not be NULL                                      | HIGH     | System DMF: NULL_COUNT
13   | CU_UNIQUE_CUSTOMER_ID| T    | Uniqueness     | CUSTOMER_ID      | CUSTOMER_ID must be unique (primary key)                         | HIGH     | System DMF: DUPLICATE_COUNT
14   | CU_UNIQUE_EMAIL      | T    | Uniqueness     | EMAIL            | EMAIL must be unique per customer                                | HIGH     | System DMF: DUPLICATE_COUNT
15   | CU_EMAIL_FORMAT      | T    | Validity       | EMAIL            | EMAIL must match pattern: contains @ with valid domain           | MEDIUM   | Custom DMF
16   | CU_VALID_KYC_STATUS  | B    | Validity       | KYC_STATUS       | Must be in (VERIFIED, PENDING, REJECTED) — "DONE" is non-std    | HIGH     | Custom DMF (ACCEPTED_VALUES)
17   | CU_VALID_RISK_CATEGORY| B   | Validity       | RISK_CATEGORY    | Must be in (LOW, MEDIUM, HIGH)                                   | MEDIUM   | Custom DMF (ACCEPTED_VALUES)
18   | CU_DOB_NOT_FUTURE    | B    | Accuracy       | DATE_OF_BIRTH    | DOB must not be in the future (2030 found!)                      | HIGH     | Custom DMF
19   | CU_DOB_REASONABLE_AGE| B    | Accuracy       | DATE_OF_BIRTH    | Customer age must be between 18 and 120 years                    | MEDIUM   | Custom DMF
20   | CU_FK_BRANCH_ID      | T    | Ref Integrity  | BRANCH_ID        | BRANCH_ID must exist in BRANCHES table                           | HIGH     | Custom DMF (cross-table)
21   | CU_ROW_COUNT         | T    | Completeness   | (table)          | Monitor table row count                                          | MEDIUM   | System DMF: ROW_COUNT
22   | CU_FRESHNESS         | T    | Timeliness     | CREATED_AT       | Monitor data freshness                                           | MEDIUM   | System DMF: FRESHNESS
*/

-- ============================================================================
-- TABLE 3: ACCOUNTS (13 rules)
-- ============================================================================

/*
Rule | Name                     | Type | Dimension      | Column(s)                | Description                                                  | Priority | Implementation
-----|--------------------------|------|----------------|--------------------------|--------------------------------------------------------------|----------|---------------
23   | AC_NULL_ACCOUNT_ID       | T    | Completeness   | ACCOUNT_ID               | ACCOUNT_ID must not be NULL                                  | HIGH     | System DMF: NULL_COUNT
24   | AC_NULL_CUSTOMER_ID      | T    | Completeness   | CUSTOMER_ID              | CUSTOMER_ID must not be NULL                                 | HIGH     | System DMF: NULL_COUNT
25   | AC_NULL_BALANCE          | T    | Completeness   | BALANCE                  | BALANCE must not be NULL                                     | HIGH     | System DMF: NULL_COUNT
26   | AC_UNIQUE_ACCOUNT_ID     | T    | Uniqueness     | ACCOUNT_ID               | ACCOUNT_ID must be unique (primary key)                      | HIGH     | System DMF: DUPLICATE_COUNT
27   | AC_VALID_ACCOUNT_TYPE    | B    | Validity       | ACCOUNT_TYPE             | Must be in (SAVINGS, CURRENT, LOAN)                          | MEDIUM   | Custom DMF (ACCEPTED_VALUES)
28   | AC_VALID_ACCOUNT_STATUS  | B    | Validity       | ACCOUNT_STATUS           | Must be in (ACTIVE, DORMANT, CLOSED)                         | MEDIUM   | Custom DMF (ACCEPTED_VALUES)
29   | AC_VALID_CURRENCY        | B    | Validity       | CURRENCY                 | Must be in (INR, USD)                                        | LOW      | Custom DMF (ACCEPTED_VALUES)
30   | AC_SAVINGS_BAL_NON_NEG   | B    | Accuracy       | BALANCE, ACCOUNT_TYPE    | SAVINGS account balance must be >= 0 (negative found: -1500) | HIGH     | Custom DMF
31   | AC_OPEN_DATE_NOT_FUTURE  | B    | Accuracy       | OPEN_DATE                | OPEN_DATE must not be in the future                          | MEDIUM   | Custom DMF
32   | AC_FK_CUSTOMER_ID        | T    | Ref Integrity  | CUSTOMER_ID              | CUSTOMER_ID must exist in CUSTOMERS table                    | HIGH     | Custom DMF (cross-table)
33   | AC_FK_BRANCH_ID          | T    | Ref Integrity  | BRANCH_ID                | BRANCH_ID must exist in BRANCHES table                       | HIGH     | Custom DMF (cross-table)
34   | AC_ROW_COUNT             | T    | Completeness   | (table)                  | Monitor table row count                                      | MEDIUM   | System DMF: ROW_COUNT
35   | AC_FRESHNESS             | T    | Timeliness     | CREATED_AT               | Monitor data freshness                                       | MEDIUM   | System DMF: FRESHNESS
*/

-- ============================================================================
-- TABLE 4: TRANSACTIONS (13 rules)
-- ============================================================================

/*
Rule | Name                     | Type | Dimension      | Column(s)                | Description                                                       | Priority | Implementation
-----|--------------------------|------|----------------|--------------------------|-------------------------------------------------------------------|----------|---------------
36   | TX_NULL_TXN_ID           | T    | Completeness   | TRANSACTION_ID           | TRANSACTION_ID must not be NULL                                   | HIGH     | System DMF: NULL_COUNT
37   | TX_NULL_ACCOUNT_ID       | T    | Completeness   | ACCOUNT_ID               | ACCOUNT_ID must not be NULL                                       | HIGH     | System DMF: NULL_COUNT
38   | TX_NULL_AMOUNT           | T    | Completeness   | AMOUNT                   | AMOUNT must not be NULL                                           | HIGH     | System DMF: NULL_COUNT
39   | TX_UNIQUE_TXN_ID         | T    | Uniqueness     | TRANSACTION_ID           | TRANSACTION_ID must be unique (primary key)                       | HIGH     | System DMF: DUPLICATE_COUNT
40   | TX_AMOUNT_POSITIVE       | B    | Accuracy       | AMOUNT                   | Transaction amount must be > 0 (negative -50 found)               | HIGH     | Custom DMF
41   | TX_AMOUNT_RANGE          | B    | Accuracy       | AMOUNT                   | Amount must be within 0 to 10,000,000                             | MEDIUM   | Custom DMF
42   | TX_VALID_TXN_TYPE        | B    | Validity       | TRANSACTION_TYPE         | Must be in (DEBIT, CREDIT, TRANSFER) — "PAYMENT" non-standard    | HIGH     | Custom DMF (ACCEPTED_VALUES)
43   | TX_VALID_TXN_STATUS      | B    | Validity       | TRANSACTION_STATUS       | Must be in (SUCCESS, FAILED, PENDING) — "DONE" non-standard      | HIGH     | Custom DMF (ACCEPTED_VALUES)
44   | TX_VALID_CHANNEL         | B    | Validity       | CHANNEL                  | Must be in (UPI, CARD, NEFT, IMPS, ATM, CHEQUE, RTGS)            | MEDIUM   | Custom DMF (ACCEPTED_VALUES)
45   | TX_DATE_NOT_FUTURE       | B    | Accuracy       | TRANSACTION_DATE         | Transaction date must not be in the future                        | HIGH     | Custom DMF
46   | TX_FK_ACCOUNT_ID         | T    | Ref Integrity  | ACCOUNT_ID               | ACCOUNT_ID must exist in ACCOUNTS table                           | HIGH     | Custom DMF (cross-table)
47   | TX_ROW_COUNT             | T    | Completeness   | (table)                  | Monitor table row count (high-volume table)                       | HIGH     | System DMF: ROW_COUNT
48   | TX_FRESHNESS             | T    | Timeliness     | TRANSACTION_DATE         | Monitor data freshness (high-volume, critical)                    | HIGH     | System DMF: FRESHNESS
*/

-- ============================================================================
-- TABLE 5: LOAN_APPLICATIONS (15 rules)
-- ============================================================================

/*
Rule | Name                      | Type | Dimension      | Column(s)                          | Description                                                    | Priority | Implementation
-----|---------------------------|------|----------------|------------------------------------|----------------------------------------------------------------|----------|---------------
49   | LA_NULL_APP_ID            | T    | Completeness   | APPLICATION_ID                     | APPLICATION_ID must not be NULL                                | HIGH     | System DMF: NULL_COUNT
50   | LA_NULL_CUSTOMER_ID       | T    | Completeness   | CUSTOMER_ID                        | CUSTOMER_ID must not be NULL                                   | HIGH     | System DMF: NULL_COUNT
51   | LA_NULL_REQUESTED_AMT     | T    | Completeness   | REQUESTED_AMOUNT                   | REQUESTED_AMOUNT must not be NULL                              | HIGH     | System DMF: NULL_COUNT
52   | LA_UNIQUE_APP_ID          | T    | Uniqueness     | APPLICATION_ID                     | APPLICATION_ID must be unique (primary key)                    | HIGH     | System DMF: DUPLICATE_COUNT
53   | LA_REQUESTED_AMT_POSITIVE | B    | Accuracy       | REQUESTED_AMOUNT                   | Requested amount must be > 0 (zero found)                      | HIGH     | Custom DMF
54   | LA_APPROVED_LEQ_REQUESTED | B    | Accuracy       | APPROVED_AMOUNT, REQUESTED_AMOUNT  | Approved must not exceed requested amount                      | HIGH     | Custom DMF
55   | LA_APPROVED_NULL_IF_NOT_OK| B    | Consistency    | APPROVED_AMOUNT, APPLICATION_STATUS| APPROVED_AMOUNT NULL when STATUS = PENDING or REJECTED         | MEDIUM   | Custom DMF
56   | LA_VALID_LOAN_TYPE        | B    | Validity       | LOAN_TYPE                          | Must be in (HOME, PERSONAL, CAR, EDUCATION, BUSINESS)          | MEDIUM   | Custom DMF (ACCEPTED_VALUES)
57   | LA_VALID_APP_STATUS       | B    | Validity       | APPLICATION_STATUS                 | Must be in (PENDING, APPROVED, REJECTED)                       | MEDIUM   | Custom DMF (ACCEPTED_VALUES)
58   | LA_CREDIT_SCORE_RANGE     | B    | Accuracy       | CREDIT_SCORE                       | Must be between 300 and 900                                    | HIGH     | Custom DMF
59   | LA_APP_DATE_NOT_FUTURE    | B    | Accuracy       | APPLICATION_DATE                   | Application date must not be in the future                     | MEDIUM   | Custom DMF
60   | LA_FK_CUSTOMER_ID         | T    | Ref Integrity  | CUSTOMER_ID                        | CUSTOMER_ID must exist in CUSTOMERS table                      | HIGH     | Custom DMF (cross-table)
61   | LA_FK_BRANCH_ID           | T    | Ref Integrity  | BRANCH_ID                          | BRANCH_ID must exist in BRANCHES table                         | HIGH     | Custom DMF (cross-table)
62   | LA_ROW_COUNT              | T    | Completeness   | (table)                            | Monitor table row count                                        | MEDIUM   | System DMF: ROW_COUNT
63   | LA_FRESHNESS              | T    | Timeliness     | CREATED_AT                         | Monitor data freshness                                         | MEDIUM   | System DMF: FRESHNESS
*/

-- ============================================================================
-- SUMMARY BY DIMENSION
-- ============================================================================

/*
  Dimension            | Total Rules | HIGH | MEDIUM | LOW
  ---------------------|-------------|------|--------|----
  Completeness         |    18       |  11  |   7    |  0
  Uniqueness           |     7       |   7  |   0    |  0
  Validity             |    12       |   3  |   8    |  1
  Accuracy             |    11       |   8  |   3    |  0
  Consistency          |     1       |   0  |   1    |  0
  Referential Integrity|     7       |   7  |   0    |  0
  Timeliness           |     7       |   2  |   4    |  1
  ---------------------|-------------|------|--------|----
  TOTAL                |    63       |  38  |  23    |  2

  Implementation Breakdown:
  - System DMFs (NULL_COUNT, DUPLICATE_COUNT, ROW_COUNT, FRESHNESS): 30 rules
  - Custom DMFs (business logic, cross-column, format, range):       18 rules
  - Custom DMFs via ACCEPTED_VALUES pattern:                         10 rules
  - Cross-table referential integrity custom DMFs:                    5 rules (+ 2 using system RI if available)
*/

-- ============================================================================
-- RULE PRIORITY SUMMARY BY TABLE
-- ============================================================================

/*
  Table             | Total | HIGH | MEDIUM | LOW
  ------------------|-------|------|--------|----
  BRANCHES          |   9   |   5  |   3    |  1
  CUSTOMERS         |  13   |   8  |   4    |  1 (note: extra HIGH due to future DOB)
  ACCOUNTS          |  13   |   7  |   5    |  1
  TRANSACTIONS      |  13   |   9  |   4    |  0 (highest priority — financial data)
  LOAN_APPLICATIONS |  15   |   9  |   6    |  0
*/

/*=============================================================================
  END OF PROPOSED RULES
=============================================================================*/
