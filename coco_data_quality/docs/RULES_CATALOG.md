# Rules Catalog

63 data quality rules across 5 banking tables and 7 quality dimensions.

Each rule is a SQL query stored in `DQ_RULE_CONFIG.RULE_SQL` that returns `TOTAL_RECORD_COUNT` and `FAILED_RECORD_COUNT`. A rule passes when `FAILED_RECORD_COUNT <= THRESHOLD_VALUE` (default 0).

---

## Summary

| Dimension | Rules | Description |
|-----------|:-----:|-------------|
| Completeness | 15 | NULL checks on primary keys and required fields |
| Uniqueness | 7 | Duplicate detection on primary keys and unique columns |
| Validity | 12 | Accepted values for categorical columns, format validation |
| Accuracy | 11 | Business logic: positive amounts, reasonable ranges, cross-column comparisons |
| Consistency | 1 | Cross-column logic between related fields |
| Referential Integrity | 7 | Foreign key existence checks across tables |
| Volume | 5 | Row count > 0 per table |
| Timeliness | 5 | Data freshness within threshold |

### By table

| Table | Total | HIGH | MEDIUM | LOW |
|-------|:-----:|:----:|:------:|:---:|
| BRANCHES | 9 | 5 | 3 | 1 |
| CUSTOMERS | 13 | 8 | 5 | 0 |
| ACCOUNTS | 13 | 7 | 5 | 1 |
| TRANSACTIONS | 13 | 11 | 2 | 0 |
| LOAN_APPLICATIONS | 15 | 9 | 6 | 0 |

---

## Completeness (15 rules)

Detect NULL values in columns that should always be populated.

| # | Rule | Table | Column | Priority |
|---|------|-------|--------|----------|
| 1 | BR_NULL_BRANCH_ID | BRANCHES | BRANCH_ID | HIGH |
| 2 | BR_NULL_BRANCH_NAME | BRANCHES | BRANCH_NAME | HIGH |
| 3 | BR_NULL_IFSC_CODE | BRANCHES | IFSC_CODE | HIGH |
| 7 | BR_VALID_IS_ACTIVE | BRANCHES | IS_ACTIVE | MEDIUM |
| 10 | CU_NULL_CUSTOMER_ID | CUSTOMERS | CUSTOMER_ID | HIGH |
| 11 | CU_NULL_EMAIL | CUSTOMERS | EMAIL | HIGH |
| 12 | CU_NULL_FIRST_NAME | CUSTOMERS | FIRST_NAME | HIGH |
| 23 | AC_NULL_ACCOUNT_ID | ACCOUNTS | ACCOUNT_ID | HIGH |
| 24 | AC_NULL_CUSTOMER_ID | ACCOUNTS | CUSTOMER_ID | HIGH |
| 25 | AC_NULL_BALANCE | ACCOUNTS | BALANCE | HIGH |
| 36 | TX_NULL_TXN_ID | TRANSACTIONS | TRANSACTION_ID | HIGH |
| 37 | TX_NULL_ACCOUNT_ID | TRANSACTIONS | ACCOUNT_ID | HIGH |
| 38 | TX_NULL_AMOUNT | TRANSACTIONS | AMOUNT | HIGH |
| 49 | LA_NULL_APP_ID | LOAN_APPLICATIONS | APPLICATION_ID | HIGH |
| 50 | LA_NULL_CUSTOMER_ID | LOAN_APPLICATIONS | CUSTOMER_ID | HIGH |
| 51 | LA_NULL_REQUESTED_AMT | LOAN_APPLICATIONS | REQUESTED_AMOUNT | HIGH |

**Example SQL** — `CU_NULL_EMAIL`:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(CASE WHEN EMAIL IS NULL THEN 1 ELSE 0 END) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.CUSTOMERS
```

---

## Uniqueness (7 rules)

Detect duplicate values in primary key and unique columns.

| # | Rule | Table | Column | Priority |
|---|------|-------|--------|----------|
| 4 | BR_UNIQUE_BRANCH_ID | BRANCHES | BRANCH_ID | HIGH |
| 5 | BR_UNIQUE_IFSC | BRANCHES | IFSC_CODE | HIGH |
| 13 | CU_UNIQUE_CUSTOMER_ID | CUSTOMERS | CUSTOMER_ID | HIGH |
| 14 | CU_UNIQUE_EMAIL | CUSTOMERS | EMAIL | HIGH |
| 26 | AC_UNIQUE_ACCOUNT_ID | ACCOUNTS | ACCOUNT_ID | HIGH |
| 39 | TX_UNIQUE_TXN_ID | TRANSACTIONS | TRANSACTION_ID | HIGH |
| 52 | LA_UNIQUE_APP_ID | LOAN_APPLICATIONS | APPLICATION_ID | HIGH |

**Example SQL** — `AC_UNIQUE_ACCOUNT_ID`:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       COUNT(*) - COUNT(DISTINCT ACCOUNT_ID) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.ACCOUNTS
```

---

## Validity (12 rules)

Validate categorical values against allowed sets and check string format patterns.

| # | Rule | Table | Column | Allowed Values / Pattern | Priority |
|---|------|-------|--------|--------------------------|----------|
| 6 | BR_IFSC_FORMAT | BRANCHES | IFSC_CODE | `^[A-Z]{4}0[A-Z0-9]{6}$` | MEDIUM |
| 15 | CU_EMAIL_FORMAT | CUSTOMERS | EMAIL | Contains @ with valid domain | MEDIUM |
| 16 | CU_VALID_KYC_STATUS | CUSTOMERS | KYC_STATUS | VERIFIED, PENDING, REJECTED | HIGH |
| 17 | CU_VALID_RISK_CATEGORY | CUSTOMERS | RISK_CATEGORY | LOW, MEDIUM, HIGH | MEDIUM |
| 27 | AC_VALID_ACCOUNT_TYPE | ACCOUNTS | ACCOUNT_TYPE | SAVINGS, CURRENT, LOAN | MEDIUM |
| 28 | AC_VALID_ACCOUNT_STATUS | ACCOUNTS | ACCOUNT_STATUS | ACTIVE, DORMANT, CLOSED | MEDIUM |
| 29 | AC_VALID_CURRENCY | ACCOUNTS | CURRENCY | INR, USD | LOW |
| 42 | TX_VALID_TXN_TYPE | TRANSACTIONS | TRANSACTION_TYPE | DEBIT, CREDIT, TRANSFER | HIGH |
| 43 | TX_VALID_TXN_STATUS | TRANSACTIONS | TRANSACTION_STATUS | SUCCESS, FAILED, PENDING | HIGH |
| 44 | TX_VALID_CHANNEL | TRANSACTIONS | CHANNEL | UPI, CARD, NEFT, IMPS, ATM, CHEQUE, RTGS | MEDIUM |
| 56 | LA_VALID_LOAN_TYPE | LOAN_APPLICATIONS | LOAN_TYPE | HOME, PERSONAL, CAR, EDUCATION, BUSINESS | MEDIUM |
| 57 | LA_VALID_APP_STATUS | LOAN_APPLICATIONS | APPLICATION_STATUS | PENDING, APPROVED, REJECTED | MEDIUM |

**Example SQL** — `BR_IFSC_FORMAT`:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(CASE WHEN IFSC_CODE IS NOT NULL
           AND NOT RLIKE(IFSC_CODE, '^[A-Z]{4}0[A-Z0-9]{6}$')
           THEN 1 ELSE 0 END) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.BRANCHES
```

---

## Accuracy (11 rules)

Validate business logic: value ranges, non-future dates, cross-column relationships.

| # | Rule | Table | Column(s) | Logic | Priority |
|---|------|-------|-----------|-------|----------|
| 18 | CU_DOB_NOT_FUTURE | CUSTOMERS | DATE_OF_BIRTH | DOB must not be in the future | HIGH |
| 19 | CU_DOB_REASONABLE_AGE | CUSTOMERS | DATE_OF_BIRTH | Age must be between 18 and 120 | MEDIUM |
| 30 | AC_SAVINGS_BAL_NON_NEG | ACCOUNTS | BALANCE, ACCOUNT_TYPE | SAVINGS balance must be >= 0 | HIGH |
| 31 | AC_OPEN_DATE_NOT_FUTURE | ACCOUNTS | OPEN_DATE | Open date must not be in the future | MEDIUM |
| 40 | TX_AMOUNT_POSITIVE | TRANSACTIONS | AMOUNT | Transaction amount must be > 0 | HIGH |
| 41 | TX_AMOUNT_RANGE | TRANSACTIONS | AMOUNT | Amount must be within 0 to 10,000,000 | MEDIUM |
| 45 | TX_DATE_NOT_FUTURE | TRANSACTIONS | TRANSACTION_DATE | Transaction date must not be in the future | HIGH |
| 53 | LA_REQUESTED_AMT_POSITIVE | LOAN_APPLICATIONS | REQUESTED_AMOUNT | Requested amount must be > 0 | HIGH |
| 54 | LA_APPROVED_LEQ_REQUESTED | LOAN_APPLICATIONS | APPROVED_AMOUNT, REQUESTED_AMOUNT | Approved must not exceed requested | HIGH |
| 58 | LA_CREDIT_SCORE_RANGE | LOAN_APPLICATIONS | CREDIT_SCORE | Must be between 300 and 900 | HIGH |
| 59 | LA_APP_DATE_NOT_FUTURE | LOAN_APPLICATIONS | APPLICATION_DATE | Application date must not be in the future | MEDIUM |

**Example SQL** — `AC_SAVINGS_BAL_NON_NEG`:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(CASE WHEN ACCOUNT_TYPE = 'SAVINGS' AND BALANCE < 0
           THEN 1 ELSE 0 END) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.ACCOUNTS
```

---

## Consistency (1 rule)

Validate cross-column logical relationships within the same table.

| # | Rule | Table | Column(s) | Logic | Priority |
|---|------|-------|-----------|-------|----------|
| 55 | LA_APPROVED_NULL_IF_NOT_OK | LOAN_APPLICATIONS | APPROVED_AMOUNT, APPLICATION_STATUS | APPROVED_AMOUNT should be NULL when status is PENDING or REJECTED | MEDIUM |

**Example SQL**:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(CASE WHEN APPLICATION_STATUS IN ('PENDING', 'REJECTED')
           AND APPROVED_AMOUNT IS NOT NULL
           THEN 1 ELSE 0 END) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS
```

---

## Referential Integrity (7 rules)

Verify foreign key values exist in the parent table using LEFT JOIN.

| # | Rule | Child Table | FK Column | Parent Table | Priority |
|---|------|-------------|-----------|--------------|----------|
| 20 | CU_FK_BRANCH_ID | CUSTOMERS | BRANCH_ID | BRANCHES | HIGH |
| 32 | AC_FK_CUSTOMER_ID | ACCOUNTS | CUSTOMER_ID | CUSTOMERS | HIGH |
| 33 | AC_FK_BRANCH_ID | ACCOUNTS | BRANCH_ID | BRANCHES | HIGH |
| 46 | TX_FK_ACCOUNT_ID | TRANSACTIONS | ACCOUNT_ID | ACCOUNTS | HIGH |
| 60 | LA_FK_CUSTOMER_ID | LOAN_APPLICATIONS | CUSTOMER_ID | CUSTOMERS | HIGH |
| 61 | LA_FK_BRANCH_ID | LOAN_APPLICATIONS | BRANCH_ID | BRANCHES | HIGH |

**Example SQL** — `TX_FK_ACCOUNT_ID`:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(CASE WHEN t.ACCOUNT_ID IS NOT NULL AND a.ACCOUNT_ID IS NULL
           THEN 1 ELSE 0 END) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS t
LEFT JOIN BANKING_DQ_DB.RAW.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
```

---

## Volume (5 rules)

Monitor that tables are not empty.

| # | Rule | Table | Priority |
|---|------|-------|----------|
| 8 | BR_ROW_COUNT | BRANCHES | MEDIUM |
| 21 | CU_ROW_COUNT | CUSTOMERS | MEDIUM |
| 34 | AC_ROW_COUNT | ACCOUNTS | MEDIUM |
| 47 | TX_ROW_COUNT | TRANSACTIONS | HIGH |
| 62 | LA_ROW_COUNT | LOAN_APPLICATIONS | MEDIUM |

---

## Timeliness (5 rules)

Check that the most recent data is within an acceptable freshness window.

| # | Rule | Table | Column | Threshold | Priority |
|---|------|-------|--------|-----------|----------|
| 9 | BR_FRESHNESS | BRANCHES | CREATED_AT | 30 days | LOW |
| 22 | CU_FRESHNESS | CUSTOMERS | CREATED_AT | 30 days | MEDIUM |
| 35 | AC_FRESHNESS | ACCOUNTS | CREATED_AT | 30 days | MEDIUM |
| 48 | TX_FRESHNESS | TRANSACTIONS | TRANSACTION_DATE | 7 days | HIGH |
| 63 | LA_FRESHNESS | LOAN_APPLICATIONS | CREATED_AT | 30 days | MEDIUM |

**Example SQL** — `TX_FRESHNESS`:
```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       CASE WHEN DATEDIFF('DAY', MAX(TRANSACTION_DATE), CURRENT_TIMESTAMP()) > 7
            THEN 1 ELSE 0 END AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS
```
