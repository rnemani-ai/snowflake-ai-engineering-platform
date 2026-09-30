# 03 — Cortex Code (CoCo) Data Quality Engineering

## Enterprise Banking AI Platform — Detailed Implementation Document

> **Purpose:** Document the separate Cortex Code / CoCo engineering implementation used to design, build, execute, troubleshoot, and validate the Snowflake Data Quality framework.
>
> **Important:** This document describes the `coco_data_quality/` implementation as an **AI-assisted engineering workflow**. It is intentionally distinct from the `screenshots/` Streamlit application experience.

---

# 1. Executive Summary

The `coco_data_quality/` implementation demonstrates an end-to-end **Snowflake Data Quality engineering workflow built with Cortex Code (CoCo)**.

The implementation covers:

1. Synthetic banking data setup
2. Data profiling
3. Data-quality risk identification
4. Rule recommendation
5. Rule implementation
6. Metadata-driven framework configuration
7. Dynamic rule execution
8. Failed-record sampling
9. Anomaly detection
10. Streamlit monitoring
11. Controlled anomaly injection
12. Multi-run validation
13. Troubleshooting and adaptation to Snowflake edition constraints
14. Cleanup and production-extension planning

The resulting framework contains:

- **5 banking source tables**
- **63 DQ rules**
- **7 quality dimensions**
- **5 metadata/logging tables**
- **1 JavaScript orchestration stored procedure**
- **sample error-record capture**
- **run-level pass/fail tracking**
- **three anomaly-detection mechanisms**
- **a four-tab Streamlit monitoring dashboard**

The key architectural decision was to use a **SQL-based rules engine** rather than native Snowflake Data Metric Functions (DMFs), because the development environment was running on Snowflake Standard Edition.

Native DMF DDL is retained only as a **future migration/reference path**; it is not part of the executed implementation.

---

# 2. Why This Implementation Is Separate From the Main Streamlit Application

The overall repository contains two complementary implementation experiences.

## Application experience

The broader `screenshots/` and main Streamlit implementation demonstrate:

- semantic analytics
- Cortex Analyst
- DQ monitoring
- AI evaluation
- user-facing results
- generated SQL transparency

The question answered by this surface is:

> **How does a user interact with the finished platform?**

## Engineering experience

The `coco_data_quality/` implementation demonstrates:

- data inspection
- profiling
- DQ rule design
- SQL generation
- metadata-driven execution
- controlled defect injection
- validation
- anomaly detection
- troubleshooting
- AI-assisted Snowflake engineering

The question answered by this surface is:

> **How does an engineer build, test, troubleshoot, and validate the data-quality capability?**

### Combined view

```text
                    SNOWFLAKE FOUNDATION
                           |
              +------------+------------+
              |                         |
       ENGINEERING PATH            APPLICATION PATH
              |                         |
        Cortex Code / CoCo             Streamlit
              |                         |
       Build / Test / Validate     Present / Monitor
              |                         |
              +------------+------------+
                           |
                  Enterprise Platform
```

This distinction is important for the portfolio because the two folders are **not duplicate screenshot collections**. They represent two different engineering perspectives.

---

# 3. Business Problem

AI and analytics systems are only as trustworthy as the data underneath them.

A banking platform can produce syntactically valid SQL and visually polished dashboards while still producing unreliable results if the underlying data contains:

- missing identifiers
- duplicate records
- invalid categorical values
- invalid formats
- negative or extreme financial values
- orphaned foreign keys
- inconsistent business states
- stale records
- unexpected volume changes

The CoCo implementation therefore focuses on building a reusable mechanism to answer:

> **Is the underlying banking data structurally, technically, and business-wise healthy enough for downstream analytics?**

The framework is designed around a metadata-driven model rather than hard-coding every execution path into a single procedure.

---

# 4. Snowflake Scope

## Database

```text
BANKING_DQ_DB
```

## Source schema

```text
BANKING_DQ_DB.RAW
```

## Framework schema

```text
BANKING_DQ_DB.DQ_MONITORING
```

## Source tables

The framework monitors five synthetic banking tables:

```text
BRANCHES
CUSTOMERS
ACCOUNTS
TRANSACTIONS
LOAN_APPLICATIONS
```

The dataset is synthetic and intentionally contains quality issues for engineering validation.

It should **not** be described as production banking data.

---

# 5. Repository Structure

The CoCo implementation is organized around an eight-step engineering workflow.

```text
coco_data_quality/
│
├── 00_setup/
│   └── 00_load_synthetic_data.sql
│
├── 01_DQ_instructions/
│   └── data_quality_framework.md
│
├── Generated_files/
│   ├── DQ_data_profiling.sql
│   ├── DQ_Proposed_Rules.sql
│   ├── DQ_Rules.sql
│   ├── DQ_Framework_Config.sql
│   ├── DQ_Orchestration.sql
│   └── DQ_cleanup.sql
│
├── DQ_MONITORING_DASHBOARD/
│   ├── .streamlit/
│   │   └── config.toml
│   ├── pyproject.toml
│   ├── snowflake.yml
│   └── streamlit_app.py
│
└── docs/
    └── COCO_DATA_QUALITY_IMPLEMENTATION.md
```

### Folder responsibilities

| Area | Responsibility |
|---|---|
| `00_setup/` | Database/schema/table creation and synthetic data loading |
| `01_DQ_instructions/` | Step-by-step instructions used to direct the CoCo build |
| `Generated_files/` | SQL generated during profiling, rule development, framework creation, orchestration, and cleanup |
| `DQ_MONITORING_DASHBOARD/` | Streamlit-in-Snowflake monitoring application |
| `docs/` | Implementation documentation |

---

# 6. The CoCo-Assisted Engineering Workflow

The implementation followed a controlled sequence:

```text
1. Setup banking data
        |
        v
2. Profile data
        |
        v
3. Identify quality risks
        |
        v
4. Recommend DQ rules
        |
        v
5. Implement rules
        |
        v
6. Build metadata framework
        |
        v
7. Build orchestration
        |
        v
8. Execute and validate
        |
        v
9. Inject additional anomalies
        |
        v
10. Re-run and investigate
        |
        v
11. Visualize results
        |
        v
12. Document production extensions
```

A key engineering principle was maintained throughout:

> **CoCo assisted with implementation, but the engineer directed the workflow, reviewed generated changes, and validated execution results.**

CoCo was not treated as an autonomous decision-maker.

---

# 7. Step 1 — Data Profiling

The first major engineering artifact is:

```text
Generated_files/DQ_data_profiling.sql
```

The objective was to understand the data before defining the DQ framework.

## Profiling areas

### 7.1 Table structure

The profiling workflow inspects:

- column names
- data types
- table structures

using Snowflake metadata.

### 7.2 Row counts

The workflow calculates record counts for each source table.

This establishes the baseline for:

- volume checks
- health calculations
- anomaly detection

### 7.3 NULL analysis

The profiling checks NULL values across relevant columns.

This helps identify completeness risks such as:

```text
missing identifiers
missing email
missing transaction amount
missing loan values
```

### 7.4 Cardinality

Distinct-value counts are used to identify potential uniqueness issues.

Examples:

```text
CUSTOMER_ID
ACCOUNT_ID
TRANSACTION_ID
APPLICATION_ID
```

### 7.5 Numeric profiling

The workflow examines:

- MIN
- MAX
- AVG

for important numeric fields such as:

```text
BALANCE
AMOUNT
CREDIT_SCORE
REQUESTED_AMOUNT
```

This supports identification of:

- negative values
- extreme values
- unexpected ranges

### 7.6 Date profiling

Date/timestamp ranges are examined for fields including:

```text
CREATED_AT
DATE_OF_BIRTH
OPEN_DATE
TRANSACTION_DATE
```

This helps identify:

- future dates
- stale records
- freshness problems

### 7.7 Categorical distributions

The profiling examines values in fields such as:

```text
KYC_STATUS
RISK_CATEGORY
ACCOUNT_TYPE
ACCOUNT_STATUS
TRANSACTION_TYPE
TRANSACTION_STATUS
CHANNEL
LOAN_TYPE
APPLICATION_STATUS
```

This provides evidence for accepted-value rules.

### 7.8 Referential checks

Cross-table relationships are checked for orphaned references, including:

```text
CUSTOMERS.BRANCH_ID
ACCOUNTS.CUSTOMER_ID
ACCOUNTS.BRANCH_ID
TRANSACTIONS.ACCOUNT_ID
LOAN_APPLICATIONS.CUSTOMER_ID
LOAN_APPLICATIONS.BRANCH_ID
```

---

# 8. Profiling Findings

The profiling stage identified representative issues including:

- future date of birth
- negative balances
- non-standard categorical values
- orphaned foreign-key references

This is an important part of the engineering story.

The rules were not presented as arbitrary checks. They were developed from observed characteristics and risks in the profiled dataset.

---

# 9. Step 2 — DQ Rule Recommendation

The second major artifact is:

```text
Generated_files/DQ_Proposed_Rules.sql
```

CoCo analyzed the profiling results and produced a proposed DQ rule set.

The implementation ultimately contains:

> **63 rules across 7 quality dimensions**

Rules are also classified by:

- Technical vs Business type
- HIGH / MEDIUM / LOW criticality

The criticality classification provides a mechanism to distinguish a simple technical defect from a business-impacting financial control issue.

---

# 10. DQ Rule Coverage

| Quality Dimension | Rules | Purpose |
|---|---:|---|
| COMPLETENESS | 15 | Required-field / NULL checks |
| UNIQUENESS | 7 | Duplicate detection |
| VALIDITY | 12 | Accepted values and formats |
| ACCURACY | 11 | Business and numerical logic |
| CONSISTENCY | 1 | Cross-column business consistency |
| REFERENTIAL_INTEGRITY | 7 | Foreign-key existence |
| VOLUME | 5 | Minimum/expected table volume |
| TIMELINESS | 5 | Data freshness |

> The source implementation describes seven quality dimensions while listing the VOLUME and TIMELINESS categories as additional rule types. The table above preserves the implementation's documented rule counts rather than attempting to reinterpret the classification.

---

# 11. Rules Per Table

| Table | Total | HIGH | MEDIUM | LOW |
|---|---:|---:|---:|---:|
| BRANCHES | 9 | 5 | 3 | 1 |
| CUSTOMERS | 13 | 8 | 5 | 0 |
| ACCOUNTS | 13 | 7 | 5 | 1 |
| TRANSACTIONS | 13 | 11 | 2 | 0 |
| LOAN_APPLICATIONS | 15 | 9 | 6 | 0 |

This gives the framework broad coverage across the five-table banking model.

---

# 12. Representative DQ Rules

## Completeness

Example:

```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(
           CASE
               WHEN EMAIL IS NULL THEN 1
               ELSE 0
           END
       ) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.CUSTOMERS;
```

Rule:

```text
CU_NULL_EMAIL
```

---

## Validity

Example IFSC format validation:

```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(
           CASE
               WHEN IFSC_CODE IS NOT NULL
                AND NOT RLIKE(
                    IFSC_CODE,
                    '^[A-Z]{4}0[A-Z0-9]{6}$'
                )
               THEN 1
               ELSE 0
           END
       ) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.BRANCHES;
```

Rule:

```text
BR_IFSC_FORMAT
```

---

## Accuracy

Example business rule:

```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(
           CASE
               WHEN ACCOUNT_TYPE = 'SAVINGS'
                AND BALANCE < 0
               THEN 1
               ELSE 0
           END
       ) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.ACCOUNTS;
```

Rule:

```text
AC_SAVINGS_BAL_NON_NEG
```

---

## Referential Integrity

Example:

```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       SUM(
           CASE
               WHEN t.ACCOUNT_ID IS NOT NULL
                AND a.ACCOUNT_ID IS NULL
               THEN 1
               ELSE 0
           END
       ) AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS t
LEFT JOIN BANKING_DQ_DB.RAW.ACCOUNTS a
    ON t.ACCOUNT_ID = a.ACCOUNT_ID;
```

Rule:

```text
TX_FK_ACCOUNT_ID
```

---

## Timeliness

Example freshness rule:

```sql
SELECT COUNT(*) AS TOTAL_RECORD_COUNT,
       CASE
           WHEN DATEDIFF(
               'DAY',
               MAX(TRANSACTION_DATE),
               CURRENT_TIMESTAMP()
           ) > 7
           THEN 1
           ELSE 0
       END AS FAILED_RECORD_COUNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS;
```

Rule:

```text
TX_FRESHNESS
```

---

# 13. Step 3 — Rule Implementation

The implementation artifact is:

```text
Generated_files/DQ_Rules.sql
```

The framework uses a **SQL-based rules engine**.

Each rule is represented as metadata/configuration and contains SQL that returns:

```text
TOTAL_RECORD_COUNT
FAILED_RECORD_COUNT
```

This establishes a consistent contract between:

```text
Rule definition
      |
      v
Execution engine
      |
      v
Result processing
```

The execution framework does not need to understand the internal business logic of every rule; it consumes the standardized output.

---

# 14. Why SQL-Based Rules Were Used

The development environment was using **Snowflake Standard Edition**.

Native Snowflake Data Metric Functions were therefore not used in the executed implementation.

Instead:

```text
Rule SQL
   |
   v
Metadata table
   |
   v
Dynamic execution
   |
   v
DQ results
```

The `DQ_Rules.sql` artifact contains commented/reference DMF DDL as a future migration path.

### Important implementation boundary

**Implemented:**

- SQL-based DQ rules
- metadata-driven execution
- pass/fail calculations
- logging
- error samples
- anomaly detection

**Not implemented:**

- native DMFs
- native DMF scheduling
- native DMF result infrastructure

This distinction should remain explicit in the README and interviews.

---

# 15. Step 4 — Metadata-Driven Framework

The framework configuration is created by:

```text
Generated_files/DQ_Framework_Config.sql
```

It creates:

```text
BANKING_DQ_DB.DQ_MONITORING
```

with five metadata/logging tables.

---

# 16. Framework Tables

| Table | Purpose |
|---|---|
| `DQ_RULE_CONFIG` | Stores rule definitions and execution metadata |
| `DQ_RUN_CONTROL` | Tracks rule execution runs |
| `DQ_RULE_RESULTS` | Stores per-rule outcomes |
| `DQ_ERROR_RECORDS` | Stores sample failed records |
| `DQ_ANOMALY_RESULTS` | Stores detected anomalies and baseline statistics |

### DQ_RULE_CONFIG

Important fields include:

```text
RULE_ID
RULE_NAME
RULE_TYPE
CRITICALITY
RULE_SQL
THRESHOLD_VALUE
RULE_DIMENSION
IS_ACTIVE
```

This separates:

> **What should be checked?**

from:

> **How should the framework execute checks?**

---

# 17. Metadata-Driven Architecture

The architecture can be represented as:

```text
                 DQ_RULE_CONFIG
                       |
                       | active rules
                       v
              SP_RUN_DQ_FRAMEWORK
                       |
          +------------+-------------+
          |            |             |
          v            v             v
   Rule Results   Error Samples   Anomalies
          |            |             |
          +------------+-------------+
                       |
                       v
                 Streamlit
```

This makes the orchestration layer reusable across many rules.

For standard rule patterns, a new rule can be added through configuration without rewriting the core execution loop.

---

# 18. Step 5 — Orchestration Stored Procedure

The orchestration artifact is:

```text
Generated_files/DQ_Orchestration.sql
```

The procedure is:

```text
SP_RUN_DQ_FRAMEWORK
```

It is implemented in:

```text
JavaScript
```

and uses:

```text
EXECUTE AS CALLER
```

The procedure accepts:

```text
P_TRIGGERED_BY
```

with a default value of:

```text
MANUAL
```

Example invocation:

```sql
CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('MANUAL');
```

---

# 19. Orchestration Execution Flow

The procedure:

1. Reads active rules from `DQ_RULE_CONFIG`.
2. Orders them by `RULE_ID`.
3. Creates a run-control record.
4. Executes each rule dynamically.
5. Reads total and failed record counts.
6. Calculates pass percentage.
7. Determines PASS/FAIL against the configured threshold.
8. Writes the result to `DQ_RULE_RESULTS`.
9. Updates `DQ_RUN_CONTROL`.
10. Captures sample failed rows for failed rules.
11. Runs anomaly detection.
12. Continues to the next rule if one rule encounters an execution error.
13. Returns a run summary.

Conceptually:

```text
Active Rules
    |
    v
For Each Rule
    |
    +--> Execute SQL
    |
    +--> Total Records
    |
    +--> Failed Records
    |
    +--> Pass %
    |
    +--> PASS / FAIL
    |
    +--> Sample Errors
    |
    +--> Anomaly Checks
    |
    v
Next Rule
```

---

# 20. Pass Percentage

The framework calculates:

```text
PASS_PERCENTAGE =
((TOTAL_RECORD_COUNT - FAILED_RECORD_COUNT)
 / TOTAL_RECORD_COUNT) * 100
```

The configured threshold then determines the rule status.

This provides both:

- absolute failure count
- normalized health percentage

---

# 21. Error Handling

A major engineering consideration is preventing one broken rule from terminating the entire framework.

Each rule executes within a JavaScript `try/catch`.

If execution fails because of:

- SQL compilation
- permissions
- another runtime issue

the framework:

1. captures the error message
2. marks the rule execution as `ERROR`
3. records the failure in `DQ_RUN_CONTROL`
4. continues to the next rule

This provides **rule-level fault isolation**.

Conceptually:

```text
Rule A --> PASS
Rule B --> FAIL
Rule C --> ERROR ----+
Rule D --> PASS      |
Rule E --> FAIL <----+
                     |
              Run continues
```

---

# 22. Failed Record Sampling

For failed rules, the framework attempts to capture up to **5 sample failing rows**.

The records are stored as:

```text
VARIANT
```

in:

```text
DQ_ERROR_RECORDS
```

The implementation uses:

```text
OBJECT_CONSTRUCT(*)
```

to preserve the row as a semi-structured object.

This is useful because a dashboard that only says:

```text
Rule failed: 17 records
```

does not immediately provide investigation evidence.

The framework instead supports:

```text
Rule failure
    |
    v
Failed count
    |
    v
Sample records
    |
    v
Root-cause investigation
```

---

# 23. Error Sampling Coverage

The implementation includes sampling logic for categories such as:

- COMPLETENESS
- UNIQUENESS
- VALIDITY
- ACCURACY
- CONSISTENCY
- REFERENTIAL_INTEGRITY

For example:

```text
COMPLETENESS
    -> NULL rows

UNIQUENESS
    -> duplicate rows

VALIDITY
    -> invalid format/value rows

ACCURACY
    -> business-rule violations

REFERENTIAL_INTEGRITY
    -> orphaned references
```

### Engineering limitation

The current sampling implementation contains rule-name/type-specific branches.

Therefore, adding completely new rule patterns may require changes to the JavaScript sampling logic.

This is an important limitation to mention rather than claiming the framework is universally plug-and-play.

---

# 24. Step 6 — Anomaly Detection

Anomaly detection is built into the orchestration procedure.

It compares current metrics with historical results stored in:

```text
DQ_RULE_RESULTS
```

The framework uses three detection mechanisms.

---

# 25. Anomaly Check 1 — Row Count Change

The framework flags a volume anomaly when:

```text
ABS(current_total - previous_total)
----------------------------------- > 50%
          previous_total
```

Example:

```text
Previous TRANSACTIONS = 12
Current TRANSACTIONS  = 25

Increase = 108%
```

This is detected as a volume anomaly.

---

# 26. Anomaly Check 2 — New Failure

A rule is flagged when:

```text
Previous FAILED_RECORD_COUNT = 0
Current FAILED_RECORD_COUNT  > 0
```

Example:

```text
Previous:
CUSTOMER_ID uniqueness = PASS

Current:
CUSTOMER_ID uniqueness = FAIL
```

This provides a useful signal for newly introduced data defects.

---

# 27. Anomaly Check 3 — Failure Spike

The framework calculates a baseline using the last **10 runs**.

A spike is detected when:

```text
current_failed
>
baseline_avg + 2 * baseline_stddev
```

This is intended to identify abnormal increases in failure counts rather than merely detecting whether a rule is failing.

---

# 28. Anomaly Storage

Detected anomalies are written to:

```text
DQ_ANOMALY_RESULTS
```

with information such as:

```text
CURRENT_VALUE
PREVIOUS_VALUE
BASELINE_AVG
BASELINE_STDDEV
ANOMALY_REASON
```

This gives the monitoring layer historical context rather than only the current status.

---

# 29. Controlled Anomaly Injection

The project uses two data sets/batches to validate the framework.

## Set 1

The baseline synthetic dataset already contains intentional quality problems.

This allows the framework to demonstrate that it can detect known issues.

## Set 2

A later batch intentionally introduces additional anomalies.

Examples include:

- >50% row-count increases
- duplicate primary keys
- NULL values in previously clean columns
- new invalid references
- invalid categorical values
- extreme outlier amounts

Examples documented in the implementation include:

```text
RISK_CATEGORY = 'CRITICAL'
ACCOUNT_STATUS = 'UNKNOWN'
BALANCE = 999,999,999
TRANSACTION_AMOUNT = 10,000,000
```

These are **test defects**, not real banking incidents.

---

# 30. Why Controlled Defect Injection Matters

A DQ dashboard showing only failures from an arbitrary synthetic dataset is weaker evidence.

Controlled injection creates a known test:

```text
Known defect
     |
     v
Inject defect
     |
     v
Run framework
     |
     v
Expected failure
     |
     v
Inspect evidence
```

This tests the detection mechanism itself.

It also provides an interview-friendly engineering story:

> “I deliberately introduced known defects and verified that the framework detected them at the rule, record, and anomaly levels.”

---

# 31. Validation — Baseline Run

The baseline execution produced:

```text
63 rules processed
0 execution errors

39 passed
24 failed

Overall health: 61.9%
```

Detected baseline issues included:

- NULL branch name
- invalid IFSC format
- future date of birth
- non-standard KYC status
- negative savings balance
- negative transaction amount
- non-standard transaction type
- non-standard transaction status
- orphaned foreign keys
- zero requested loan amount
- approved amount exceeding requested amount
- freshness violations

Sample error records were captured for **9 distinct failing rules**.

---

# 32. Validation — Set 2 Anomaly Run

After the second anomaly-injection batch:

```text
63 rules processed
0 execution errors

29 passed
34 failed

Overall health: 46.0%
```

The framework detected:

```text
63 anomalies
```

across the five monitored tables.

Newly detected failures included:

- duplicate BRANCH_ID
- duplicate CUSTOMER_ID
- NULL email
- invalid RISK_CATEGORY
- invalid ACCOUNT_STATUS
- NULL transaction amount
- duplicate TRANSACTION_ID
- duplicate APPLICATION_ID

Row-count anomalies were also detected across the tables because of the injected volume changes.

---

# 33. Validation Architecture

The validation evidence can be represented as:

```text
Baseline Data
     |
     v
63 DQ Rules
     |
     v
Baseline Results
     |
     v
Inject Set 2
     |
     v
Run Framework Again
     |
     +--> Rule Failures
     |
     +--> Error Samples
     |
     +--> New Failures
     |
     +--> Volume Anomalies
     |
     +--> Failure Spikes
     |
     v
Dashboard Evidence
```

This is stronger than validating only the SQL syntax.

---

# 34. Streamlit Monitoring Dashboard

The dashboard is located under:

```text
DQ_MONITORING_DASHBOARD/
```

and the main application is:

```text
streamlit_app.py
```

The documented implementation contains approximately **530 lines**.

The dashboard is designed to consume the framework's metadata and result tables.

---

# 35. Dashboard Tabs

The dashboard contains four major tabs.

## Tab 1 — Overview

Provides:

- overall health
- total rules
- passed rules
- failed rules
- table-level summaries
- general DQ status

## Tab 2 — Results

Provides:

- rule name
- table
- column
- rule type
- severity
- status
- failed count
- total count
- pass percentage
- execution timestamp

## Tab 3 — Anomalies

Provides:

- total anomalies
- affected tables
- new failures
- failure spikes
- anomalies by table
- anomaly trend
- anomaly details

## Tab 4 — Coverage

Provides:

- total rules
- active rules
- tables covered
- rule types
- rules per table
- rules by type
- criticality distribution
- full rule configuration

---

# 36. Table Drill-Down

The dashboard also supports table-level investigation.

A selected table can expose:

- health KPIs
- passing rules
- failing rules
- sample error records
- recommended fixes
- severity
- failure counts

This creates a path from:

```text
Platform health
     |
     v
Table
     |
     v
Rule
     |
     v
Failed records
```

That is closer to an engineering investigation workflow than a simple dashboard.

---

# 37. Dashboard Visualization

The implementation uses:

- Streamlit
- Altair
- cached data loaders
- KPI cards
- sidebar filters
- tables
- drill-down sections
- charts

The visual design distinguishes:

```text
PASS
FAIL
WARNING
INFO
ANOMALY
```

The important engineering point is that the dashboard reads from the DQ framework's persisted results rather than embedding the DQ logic entirely in the UI.

---

# 38. CoCo Contribution

CoCo was used across the eight-step engineering process.

### 1. Profiling

CoCo generated and executed profiling SQL and helped summarize:

- column structures
- cardinality
- distributions
- quality risks

### 2. Rule recommendation

CoCo analyzed profiling results and generated the proposed 63-rule framework.

### 3. Rule implementation

CoCo generated the SQL rule definitions.

### 4. Framework configuration

CoCo generated:

- schema DDL
- metadata tables
- rule-loading statements

### 5. Orchestration

CoCo generated the JavaScript stored procedure for:

- dynamic execution
- pass/fail calculation
- error sampling
- anomaly detection
- error handling

### 6. Dashboard

CoCo generated the Streamlit monitoring application.

### 7. Cleanup

CoCo generated the ordered cleanup script.

### 8. Execution and troubleshooting

CoCo was also used interactively during execution to diagnose issues involving:

- Standard Edition DMF availability
- compute pool state
- warehouse suspension
- anomaly-data loading
- framework verification

---

# 39. Human-in-the-Loop Engineering

A key part of the implementation is the working model:

```text
Engineer
   |
   | instruction
   v
CoCo
   |
   | generated artifact
   v
Engineer review
   |
   | approve / modify
   v
Snowflake execution
   |
   v
Observed result
   |
   v
Engineer validation
```

The implementation documentation explicitly describes CoCo as an interactive assistant rather than an autonomous builder.

This distinction is valuable when discussing AI-assisted development in interviews.

---

# 40. Important Technical Trade-Off — DMF vs SQL Rules Engine

## Native DMFs

Potential enterprise path:

```text
Snowflake Native DMF
        |
        v
Native monitoring infrastructure
```

Benefits include native data-quality functionality and deeper Snowflake integration.

## Current implementation

```text
SQL rule metadata
       |
       v
JavaScript SP
       |
       v
Custom result tables
```

Advantages for this project:

- works within the Standard Edition constraint
- transparent SQL logic
- fully inspectable rule definitions
- easy to demonstrate the execution mechanics
- supports custom result and error-record structures

Trade-off:

- more custom orchestration
- manual execution
- custom anomaly logic
- custom error sampling
- more maintenance responsibility

The project deliberately documents both the implemented path and the future DMF migration path.

---

# 41. Current Limitations

The implementation documentation identifies several boundaries.

## 41.1 No native DMFs

The current environment uses the SQL rules engine.

## 41.2 Manual execution

The framework is invoked manually:

```sql
CALL SP_RUN_DQ_FRAMEWORK('MANUAL');
```

No Snowflake TASK is configured.

## 41.3 Error sampling contains conditional logic

Some sampling behavior depends on rule/type-specific logic.

## 41.4 Single-database scope

The current configuration targets:

```text
BANKING_DQ_DB.RAW
```

## 41.5 No external alerting

There is no implemented:

- email notification
- Slack webhook
- PagerDuty integration
- other external alert channel

## 41.6 Synthetic dataset

The dataset is small and synthetic.

The implementation has not been demonstrated at production data volume.

## 41.7 Historical anomaly dependency

The anomaly logic requires previous runs.

The first run cannot establish historical anomalies.

## 41.8 Dashboard cold-start behavior

The documented implementation notes that the Streamlit environment may require a retry when the underlying compute resources are resuming.

---

# 42. Production Extensions — Not Implemented

The following are intentionally **future production considerations**, not current capabilities.

## Scheduling

Possible future implementation:

```text
Snowflake TASK
      |
      v
SP_RUN_DQ_FRAMEWORK
```

## Alerting

Potential integrations:

```text
Snowflake ALERT
Email
Slack
PagerDuty
Webhook
```

## RBAC

Possible dedicated roles:

```text
DQ_ADMIN
DQ_VIEWER
```

## Environment separation

Potential:

```text
DEV
TEST
PROD
```

## CI/CD

Potential additions:

- SQL validation
- automated deployment
- rule regression testing
- Streamlit deployment automation

## Observability

Potential metrics:

- rule execution time
- error count
- run duration
- result-table growth
- failed-rule trends

## Rule governance

Potential additions:

- rule owner
- rule version
- approval workflow
- review cadence
- data classification tags

## Automated regression

A future regression suite could assert expected:

```text
pass count
fail count
error count
anomaly count
```

against a known dataset.

---

# 43. Native DMF Migration Path

If the Snowflake environment is later upgraded to an edition supporting the required native DMF functionality, the documented migration path is:

```text
Current SQL Rules Engine
          |
          v
Map Rule Definitions
          |
          v
Native DMFs
          |
          v
Native DQ Monitoring
```

The project already preserves reference DMF DDL in `DQ_Rules.sql`.

The important distinction is:

> **The project demonstrates the migration design, but native DMFs are not part of the current executed implementation.**

---

# 44. Evidence Strategy

The CoCo artifacts should be presented as implementation evidence.

A strong evidence chain is:

```text
CoCo Prompt / Instruction
          |
          v
Generated SQL
          |
          v
Snowflake Object
          |
          v
Execution
          |
          v
Observed Result
          |
          v
Screenshot / Dashboard
```

For example:

```text
DQ_Proposed_Rules.sql
       |
       v
DQ_Rules.sql
       |
       v
DQ_RULE_CONFIG
       |
       v
SP_RUN_DQ_FRAMEWORK
       |
       v
DQ_RULE_RESULTS
       |
       v
Streamlit Dashboard
```

This makes the screenshots defensible because each visual output maps back to an actual implementation artifact.

---

# 45. Recommended CoCo Screenshot Story

When adding the CoCo screenshots to the GitHub README/docs, organize them by engineering stage rather than by filename alone.

### Screenshot group 1 — Exploration

Show:

- Snowflake object inspection
- source tables
- initial investigation

### Screenshot group 2 — Profiling

Show:

- profiling SQL
- profiling output
- discovered data-quality risks

### Screenshot group 3 — Rule design

Show:

- proposed rules
- quality dimensions
- criticality

### Screenshot group 4 — Framework construction

Show:

- metadata tables
- rule configuration
- orchestration procedure

### Screenshot group 5 — Execution

Show:

- procedure execution
- processed/passed/failed counts
- execution output

### Screenshot group 6 — Anomaly validation

Show:

- Set 2 injection
- new failures
- anomaly results

### Screenshot group 7 — Dashboard

Show:

- overview
- results
- anomalies
- coverage

This gives the reviewer an engineering narrative:

```text
Explore → Profile → Design → Build → Execute → Detect → Validate
```

---

# 46. Skills Demonstrated

This implementation provides concrete evidence of:

### Snowflake

- SQL
- schemas
- metadata tables
- stored procedures
- JavaScript execution
- VARIANT
- dynamic SQL
- role-aware execution
- Streamlit in Snowflake

### Data Quality

- completeness
- uniqueness
- validity
- accuracy
- consistency
- referential integrity
- volume
- timeliness
- thresholding
- error sampling
- anomaly detection

### Engineering

- metadata-driven architecture
- separation of configuration and execution
- rule-level fault isolation
- controlled test-data injection
- regression-style validation
- troubleshooting
- implementation trade-offs

### AI-assisted engineering

- Cortex Code / CoCo
- iterative instruction
- generated SQL review
- AI-assisted debugging
- human-in-the-loop execution
- implementation verification

### Application

- Streamlit
- Altair
- filtering
- drill-down
- KPI visualization
- result presentation

---

# 47. What This Project Does Not Claim

To keep the portfolio technically credible, do **not** describe the current implementation as:

- a production-scale banking DQ platform
- native Snowflake DMF monitoring
- fully automated scheduled monitoring
- real-time DQ alerting
- multi-database DQ governance
- autonomous AI engineering
- a production banking dataset
- a fully generalized DQ framework for arbitrary schemas

The implementation supports a much stronger and more defensible statement:

> **An enterprise-style, metadata-driven Snowflake data-quality framework was designed and validated on a synthetic banking dataset using Cortex Code as an AI-assisted engineering workflow.**

---

# 48. Interview Narrative

## 30-second version

> “I used Snowflake Cortex Code as an AI-assisted engineering workflow to build a metadata-driven data-quality framework over a synthetic banking dataset. I profiled five tables, developed 63 rules across multiple quality dimensions, stored the rules as metadata, and executed them dynamically through a JavaScript stored procedure. The framework records rule results, captures sample failed records, and detects new failures, volume anomalies, and statistical failure spikes. I then injected controlled anomalies and verified that the framework detected them. Because the environment was Standard Edition, I used a SQL-based rules engine instead of native DMFs and documented the DMF migration path separately.”

---

# 49. Interview Follow-Up — Why Metadata-Driven?

A strong answer:

> “I did not want the orchestration procedure to contain all 63 rules as hard-coded branches. Instead, the rule SQL and metadata live in `DQ_RULE_CONFIG`, while the stored procedure provides the execution engine. That separates rule definition from orchestration and makes the framework easier to extend.”

---

# 50. Interview Follow-Up — Why Not DMFs?

> “The development account was running on Standard Edition, so the native DMF path was not available for the implementation. Rather than stop the project, I built a SQL-based rules engine that produced standardized total and failed counts. I also kept reference DMF DDL so the architecture has a clear migration path if the environment moves to an edition supporting those capabilities.”

---

# 51. Interview Follow-Up — How Did You Validate It?

> “I used controlled test data. The baseline dataset contained known quality issues, and I later loaded a second anomaly batch that introduced duplicate IDs, NULLs, invalid categorical values, large volume changes, and extreme values. I reran the framework and verified rule failures, sample records, and anomaly detection results. The baseline run processed all 63 rules with 39 passing and 24 failing; after the anomaly batch, 29 passed and 34 failed, with 63 anomalies detected.”

---

# 52. Interview Follow-Up — What Did CoCo Actually Do?

> “CoCo assisted throughout the engineering workflow. It generated profiling SQL, analyzed the profiling output, proposed rules, generated the rule SQL, created the framework DDL, built the orchestration procedure and Streamlit dashboard, and helped diagnose execution issues. I directed the workflow, reviewed the generated artifacts, approved changes, and validated the actual Snowflake results.”

---

# 53. Interview Follow-Up — What Happens When One Rule Fails Technically?

> “The stored procedure isolates rule-level execution errors using try/catch handling. It records the error in the run-control table, marks that rule as an execution error, and continues processing the remaining active rules. That prevents one malformed or unavailable rule from stopping the entire DQ run.”

---

# 54. Interview Follow-Up — How Is This Different From a Simple DQ Script?

A simple script might be:

```text
Run query
  |
  v
Print result
```

This implementation adds:

```text
Rule metadata
      |
      v
Execution control
      |
      v
Run history
      |
      v
Rule results
      |
      v
Error samples
      |
      v
Anomaly detection
      |
      v
Dashboard
```

The engineering value is therefore in the **framework around the individual checks**, not simply the SQL predicates themselves.

---

# 55. Key Engineering Decisions

| Decision | Current Implementation | Reason |
|---|---|---|
| DQ engine | SQL-based | Compatible with current Standard Edition environment |
| Rule storage | Metadata table | Separates configuration from execution |
| Orchestration | JavaScript SP | Supports dynamic SQL and procedural control |
| Error records | VARIANT | Preserves flexible row-level evidence |
| Anomaly detection | Custom SQL/JavaScript logic | Provides historical monitoring without native DMFs |
| Validation | Controlled defect injection | Tests whether known defects are detected |
| UI | Streamlit | Makes DQ results inspectable and interactive |
| AI assistance | Cortex Code | Accelerates iterative Snowflake engineering |
| DMFs | Reference only | Future Enterprise Edition migration |

---

# 56. End-to-End Architecture

```text
                    SYNTHETIC BANKING DATA
                             |
             +---------------+---------------+
             |               |               |
          BRANCHES        CUSTOMERS       ACCOUNTS
             |               |               |
             +---------------+---------------+
                             |
                     TRANSACTIONS
                             |
                    LOAN_APPLICATIONS
                             |
                             v
                     DATA PROFILING
                             |
                             v
                   RULE RECOMMENDATION
                             |
                             v
                     63 DQ RULES
                             |
                             v
                    DQ_RULE_CONFIG
                             |
                             v
                 SP_RUN_DQ_FRAMEWORK
                             |
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
   DQ_RUN_CONTROL     DQ_RULE_RESULTS    DQ_ERROR_RECORDS

                             |
                             v
                    ANOMALY DETECTION
                             |
                             v
                   DQ_ANOMALY_RESULTS
                             |
                             v
                     STREAMLIT UI
```

---

# 57. How This Fits the Larger Enterprise Banking AI Platform

The CoCo DQ framework is one layer of the larger platform.

```text
                  ENTERPRISE BANKING AI PLATFORM
                              |
        +---------------------+----------------------+
        |                     |                      |
   Semantic Layer        Data Quality           Governance
        |                     |                      |
   Cortex Analyst        CoCo DQ Framework      RBAC / Masking
        |                     |                      |
        +---------------------+----------------------+
                              |
                       AI Evaluation
                              |
                         Streamlit
```

The architectural idea is:

> **Natural-language analytics, data quality, governance, and AI evaluation should be considered together rather than as disconnected features.**

---

# 58. Final Takeaway

The most important story from this implementation is not simply:

> “CoCo generated SQL.”

The stronger engineering story is:

> **“I used Cortex Code as a human-directed AI engineering assistant to build and validate a metadata-driven Snowflake data-quality framework. I started from profiling, translated observed risks into 63 rules, separated rule configuration from execution, built fault-tolerant orchestration, captured row-level evidence, added historical anomaly detection, injected controlled defects, validated the framework through multiple runs, and exposed the results through a Streamlit monitoring layer. I also explicitly documented the Standard Edition constraint and the future native-DMF migration path.”**

That narrative demonstrates **Snowflake engineering, data-quality design, AI-assisted development, testing, troubleshooting, governance thinking, and production-oriented trade-off analysis** without overstating what is currently implemented.
