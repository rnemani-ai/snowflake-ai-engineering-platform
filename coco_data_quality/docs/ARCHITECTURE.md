# Architecture

## Overview

The framework follows a **metadata-driven** design pattern. Rule definitions are stored as configuration in a table, a stored procedure reads and executes them dynamically, and results are logged into dedicated tables that the dashboard reads.

```
BANKING_DQ_DB
  RAW (source data)
    BRANCHES, CUSTOMERS, ACCOUNTS, TRANSACTIONS, LOAN_APPLICATIONS

  DQ_MONITORING (framework)
    DQ_RULE_CONFIG          ← 63 rule definitions (SQL, thresholds, dimensions)
    DQ_RUN_CONTROL          ← execution tracking per rule per run
    DQ_RULE_RESULTS         ← pass/fail, counts, percentages
    DQ_ERROR_RECORDS        ← sample failing rows (VARIANT)
    DQ_ANOMALY_RESULTS      ← detected anomalies with baseline stats
    SP_RUN_DQ_FRAMEWORK()   ← orchestration stored procedure
```

## Metadata Tables

### DQ_RULE_CONFIG

Stores all rule definitions. Each rule has a `RULE_SQL` field containing a SQL query that returns `TOTAL_RECORD_COUNT` and `FAILED_RECORD_COUNT` when executed.

| Column | Type | Purpose |
|--------|------|---------|
| RULE_ID | NUMBER (PK) | Unique rule identifier |
| RULE_NAME | VARCHAR | Human-readable rule name (e.g., `CU_NULL_EMAIL`) |
| RULE_TYPE | VARCHAR | Quality dimension (COMPLETENESS, UNIQUENESS, VALIDITY, ACCURACY, CONSISTENCY, REFERENTIAL_INTEGRITY, VOLUME, TIMELINESS) |
| CRITICALITY | VARCHAR | Business priority: HIGH, MEDIUM, LOW |
| DB_NAME | VARCHAR | Fully qualified schema (`BANKING_DQ_DB.RAW`) |
| TABLE_NM | VARCHAR | Target table name |
| COLUMN_NM | VARCHAR | Target column (NULL for table-level rules) |
| RULE_SQL | VARCHAR | SQL query returning TOTAL_RECORD_COUNT and FAILED_RECORD_COUNT |
| THRESHOLD_VALUE | NUMBER | Maximum acceptable FAILED_RECORD_COUNT (default 0) |
| RULE_DIMENSION | VARCHAR | JSON array of quality dimensions |
| IS_ACTIVE | BOOLEAN | Whether the rule is executed (default TRUE) |

### DQ_RUN_CONTROL

Tracks each rule execution with timing and status.

| Column | Type | Purpose |
|--------|------|---------|
| RUN_ID | NUMBER (PK, autoincrement) | Unique run identifier |
| RULE_ID | NUMBER | Reference to DQ_RULE_CONFIG |
| RUN_START_TIME / RUN_END_TIME | TIMESTAMP_NTZ | Execution timing |
| RULE_EXEC_RESULT | VARCHAR | PASS, FAIL, or ERROR |
| RUN_STATUS | VARCHAR | RUNNING, COMPLETED, or FAILED |
| TRIGGERED_BY | VARCHAR | Execution context (MANUAL, SCHEDULED, etc.) |
| ERROR_MESSAGE | VARCHAR | Error details if execution failed |

### DQ_RULE_RESULTS

Stores the outcome of each rule evaluation.

| Column | Type | Purpose |
|--------|------|---------|
| RESULT_ID | NUMBER (PK, autoincrement) | Unique result identifier |
| RUN_ID / RULE_ID | NUMBER | References to run and rule |
| FAILED_RECORD_COUNT | NUMBER | Count of records that violated the rule |
| TOTAL_RECORD_COUNT | NUMBER | Total records evaluated |
| PASS_PERCENTAGE | NUMBER | ((total - failed) / total) * 100 |
| RESULT_STATUS | VARCHAR | PASS or FAIL (based on threshold comparison) |
| SEVERITY | VARCHAR | Inherited from rule CRITICALITY |

### DQ_ERROR_RECORDS

Captures up to 5 sample failing rows per failed rule, stored as Snowflake VARIANT for flexible schema.

| Column | Type | Purpose |
|--------|------|---------|
| ERROR_ID | NUMBER (PK, autoincrement) | Unique error record identifier |
| RUN_ID / RULE_ID | NUMBER | References to run and rule |
| ERROR_RECORD_VARIANT | VARIANT | Full row as VARIANT via OBJECT_CONSTRUCT(*) |
| ERROR_REASON | VARCHAR | Rule description explaining the violation |

### DQ_ANOMALY_RESULTS

Logs anomalies detected by comparing the current run against previous runs.

| Column | Type | Purpose |
|--------|------|---------|
| ANOMALY_ID | NUMBER (PK, autoincrement) | Unique anomaly identifier |
| RUN_ID | NUMBER | Reference to the triggering run |
| TABLE_NAME / METRIC_NAME | VARCHAR | What was flagged |
| CURRENT_VALUE / PREVIOUS_VALUE | NUMBER | Failed counts for current vs previous run |
| BASELINE_AVG / BASELINE_STDDEV | NUMBER | Rolling statistics from last 10 runs |
| ANOMALY_REASON | VARCHAR | Human-readable description of triggered checks |

## Orchestration: SP_RUN_DQ_FRAMEWORK

**Language:** JavaScript (uses `snowflake.execute()` for dynamic SQL)
**Execution mode:** `EXECUTE AS CALLER`
**Parameter:** `P_TRIGGERED_BY` (VARCHAR) — tags each run for audit

### Execution flow

```
For each active rule in DQ_RULE_CONFIG:
  1. INSERT run control record (status = RUNNING)
  2. EXECUTE rule SQL dynamically → get TOTAL_RECORD_COUNT, FAILED_RECORD_COUNT
  3. CALCULATE pass percentage
  4. DETERMINE pass/fail against threshold
  5. INSERT result into DQ_RULE_RESULTS
  6. UPDATE run control with completion status
  7. IF failed → CAPTURE up to 5 sample bad rows into DQ_ERROR_RECORDS
  8. RUN anomaly detection (compare with previous runs)
  9. ON ERROR → log error message, continue to next rule
```

### Error handling

Each rule executes in its own try-catch block. A failing rule logs an error in `DQ_RUN_CONTROL` but does not stop the procedure. Error sampling has a nested try-catch — if sampling fails, the rule result is still recorded.

## Anomaly Detection

Anomaly detection runs automatically after each rule evaluation. Three independent checks are applied:

### 1. Row count change (>50%)

Compares `TOTAL_RECORD_COUNT` between the current and previous run. Triggers when:
```
ABS(current_total - previous_total) / previous_total > 0.5
```

### 2. New failures

Triggers when the previous run had `FAILED_RECORD_COUNT = 0` and the current run has `FAILED_RECORD_COUNT > 0`. Catches newly introduced violations that weren't present before.

### 3. Statistical spike (>2 standard deviations)

Computes a rolling baseline from the last 10 runs. Triggers when:
```
current_failed > baseline_avg + 2 * baseline_stddev
```

All three checks can fire independently for the same rule. The `ANOMALY_REASON` field concatenates all triggered reasons with semicolons.

## Data flow diagram

```
[Source Tables]     [DQ_RULE_CONFIG]
  RAW.BRANCHES  ─┐      │ (63 rules with SQL)
  RAW.CUSTOMERS  │      │
  RAW.ACCOUNTS   ├──────┤
  RAW.TRANSACTIONS│     │
  RAW.LOAN_APPS ─┘      │
                         ▼
              [SP_RUN_DQ_FRAMEWORK]
              Iterates rules, executes SQL,
              calculates pass/fail, detects anomalies
                         │
          ┌──────────────┼──────────────┐──────────────┐
          ▼              ▼              ▼              ▼
   [DQ_RUN_CONTROL] [DQ_RULE_RESULTS] [DQ_ERROR_RECORDS] [DQ_ANOMALY_RESULTS]
    Run tracking     Pass/fail +       Sample bad        Detected anomalies
    + timing         percentages       rows (VARIANT)    + baseline stats
          │              │              │              │
          └──────────────┴──────────────┴──────────────┘
                         │
                         ▼
              [Streamlit Dashboard]
              Reads all 5 tables, displays
              health scores, charts, drill-down
```
