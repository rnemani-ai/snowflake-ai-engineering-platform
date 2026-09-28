# Technical Overview

A high-level walkthrough of the Data Quality Framework implementation, focusing on which Snowflake capabilities are used at each layer and how they connect.

---

## End-to-End Flow

```
 SYNTHETIC DATA          PROFILING            RULE ENGINE           MONITORING
 ─────────────          ─────────            ───────────           ──────────
 CREATE TABLE      →    SHOW COLUMNS    →    DQ_RULE_CONFIG   →   Streamlit App
 INSERT INTO            COUNT/SUM/AGG        (63 SQL rules)        (reads all tables)
 (Set 1 + Set 2)        RLIKE patterns       SP_RUN_DQ_FRAMEWORK   4 tabs, Altair charts
                         LEFT JOIN FKs        (dynamic execution)   st.connection("snowflake")
                                              ↓
                                         DQ_RUN_CONTROL
                                         DQ_RULE_RESULTS
                                         DQ_ERROR_RECORDS
                                         DQ_ANOMALY_RESULTS
```

---

## Snowflake Features Used

### 1. Database and Schema Organization

The framework uses a **two-schema architecture** within a single database:

- **`BANKING_DQ_DB.RAW`** — source data (5 banking tables)
- **`BANKING_DQ_DB.DQ_MONITORING`** — framework metadata, results, and orchestration

This separation keeps DQ infrastructure isolated from source data, making it portable and independently manageable.

```sql
CREATE DATABASE IF NOT EXISTS BANKING_DQ_DB;
CREATE SCHEMA IF NOT EXISTS BANKING_DQ_DB.RAW;
CREATE SCHEMA IF NOT EXISTS BANKING_DQ_DB.DQ_MONITORING;
```

### 2. Table Design with Constraints and Defaults

Framework tables use Snowflake table features:

- **AUTOINCREMENT** primary keys (`START 1 INCREMENT 1`) on all logging tables for automatic ID generation without sequences
- **DEFAULT values** (`CURRENT_TIMESTAMP()`, `TRUE`, `'ON_DEMAND'`, `'PENDING'`) to reduce INSERT verbosity
- **PRIMARY KEY constraints** for documentation and query optimization hints
- **VARIANT data type** in `DQ_ERROR_RECORDS` to store heterogeneous failing rows from different source tables in a single column

```sql
CREATE TABLE DQ_ERROR_RECORDS (
    ERROR_ID             NUMBER NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
    ERROR_RECORD_VARIANT VARIANT,   -- stores any row shape
    ...
);
```

### 3. VARIANT and OBJECT_CONSTRUCT

Failing rows are captured using `OBJECT_CONSTRUCT(*)`, which converts an entire row into a single VARIANT (JSON-like) value regardless of the source table's schema. This allows `DQ_ERROR_RECORDS` to store error samples from BRANCHES, CUSTOMERS, ACCOUNTS, TRANSACTIONS, and LOAN_APPLICATIONS in one table without schema conflicts.

```sql
SELECT OBJECT_CONSTRUCT(*) AS REC
FROM BANKING_DQ_DB.RAW.CUSTOMERS
WHERE KYC_STATUS NOT IN ('VERIFIED', 'PENDING', 'REJECTED')
LIMIT 5
```

Output example:
```json
{
  "CUSTOMER_ID": "C009",
  "FIRST_NAME": "Ishaan",
  "KYC_STATUS": "DONE",
  "BRANCH_ID": "B003",
  ...
}
```

### 4. JavaScript Stored Procedure with Dynamic SQL

The orchestration procedure `SP_RUN_DQ_FRAMEWORK` is written in **JavaScript** and uses `snowflake.createStatement()` / `snowflake.execute()` for dynamic SQL execution. This allows it to read rule SQL from a config table and execute it at runtime without knowing the query at compile time.

Key Snowflake JavaScript SP features used:

- **`snowflake.execute({sqlText: ..., binds: [...]})`** — parameterized dynamic SQL execution
- **`snowflake.createStatement()`** — cursor-based iteration over rule config
- **`EXECUTE AS CALLER`** — runs with the caller's privileges, so the SP can access any table the user can
- **Result set iteration** — `while (rules.next())` pattern for row-by-row processing
- **Nested try-catch** — per-rule error isolation so one failure doesn't stop the run

```javascript
var rule_result = snowflake.execute({sqlText: rule_sql});
rule_result.next();
var total_count  = rule_result.getColumnValue(1);
var failed_count = rule_result.getColumnValue(2);
```

### 5. INSERT ALL (Multi-Table Insert)

Rules are bulk-loaded into `DQ_RULE_CONFIG` using Snowflake's `INSERT ALL` syntax, which inserts multiple rows in a single atomic statement. This is used instead of individual INSERT statements for efficiency.

```sql
INSERT ALL
INTO DQ_RULE_CONFIG (...) VALUES (1, 'BR_NULL_BRANCH_ID', ...)
INTO DQ_RULE_CONFIG (...) VALUES (2, 'BR_NULL_BRANCH_NAME', ...)
INTO DQ_RULE_CONFIG (...) VALUES (3, 'BR_NULL_IFSC_CODE', ...)
SELECT 1 FROM DUAL;
```

### 6. Analytical SQL Patterns in Rules

The 63 rule SQL queries use several Snowflake SQL capabilities:

- **Conditional aggregation** — `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` for counting violations
- **RLIKE (regex matching)** — for format validation (IFSC code pattern: `^[A-Z]{4}0[A-Z0-9]{6}$`, email format)
- **LEFT JOIN for referential integrity** — detects orphaned foreign keys without requiring declared constraints
- **DATEDIFF** — for freshness checks (`DATEDIFF('DAY', MAX(timestamp), CURRENT_TIMESTAMP())`)
- **COUNT(DISTINCT)** — for uniqueness checks (`COUNT(*) - COUNT(DISTINCT col)` gives duplicate count)
- **Cross-column predicates** — `WHERE ACCOUNT_TYPE = 'SAVINGS' AND BALANCE < 0` for business rule validation

### 7. Statistical Functions for Anomaly Detection

The anomaly detection logic within the stored procedure uses:

- **AVG() and STDDEV()** — computed over a rolling window of the last 10 runs from `DQ_RULE_RESULTS`
- **ABS()** — for symmetric row count change detection
- **Subquery with ORDER BY / LIMIT** — to get the most recent N measurements as a baseline

```javascript
// Baseline from last 10 runs
var base_stmt = snowflake.execute({sqlText:
    "SELECT AVG(FAILED_RECORD_COUNT), STDDEV(FAILED_RECORD_COUNT) " +
    "FROM (SELECT FAILED_RECORD_COUNT FROM DQ_RULE_RESULTS " +
    "WHERE RULE_ID = ? ORDER BY EXECUTED_AT DESC LIMIT 10)",
    binds: [rule_id]
});
```

### 8. DATA_METRIC_SCHEDULE (Table Property)

Although native DMFs require Enterprise Edition and are not used for rule execution, the `DATA_METRIC_SCHEDULE` table property was set on all source tables. This is a table-level configuration that controls how often Snowflake evaluates attached DMFs.

```sql
ALTER TABLE BANKING_DQ_DB.RAW.TRANSACTIONS
    SET DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES';
```

This property is in place for future Enterprise Edition migration. The `DQ_cleanup.sql` script includes `UNSET DATA_METRIC_SCHEDULE` for teardown.

### 9. INFORMATION_SCHEMA Queries

The framework uses Snowflake's `INFORMATION_SCHEMA` for validation and discovery:

- **`INFORMATION_SCHEMA.TABLES`** — verify framework table creation and row counts
- **`SHOW COLUMNS IN <table>`** — discover column names and data types during profiling
- **`SHOW PARAMETERS`** — check `DATA_METRIC_SCHEDULE` settings

### 10. Streamlit in Snowflake (Container Runtime)

The dashboard runs as a **Streamlit-in-Snowflake** application on the Container Runtime:

- **`st.connection("snowflake")`** — embedded Snowflake connection (no credentials needed)
- **`snowflake.yml`** — defines the app entity with `query_warehouse` and `compute_pool`
- **`pyproject.toml`** — declares `streamlit[snowflake]>=1.54.0` as the only dependency (no external access integration needed)
- **`@st.cache_data(ttl=120)`** — caches query results for 2 minutes to reduce warehouse load
- **`st.tabs()`** — 4-tab layout (Overview, Rule Results, Anomalies, Coverage)
- **`st.metric()` with `border=True`** — KPI cards with delta indicators
- **`st.container(horizontal=True)`** — responsive horizontal layouts for metric rows
- **`st.dataframe()` with `column_config`** — formatted tables with `ProgressColumn` for pass %, `NumberColumn` for counts, `CheckboxColumn` for active status
- **`st.selectbox()`** — drill-down table selector in Overview and Rule Results tabs

### 11. Altair Charting (via Snowflake's bundled library)

The dashboard uses Altair (bundled with Streamlit) for all visualizations:

- **`mark_bar`** with `cornerRadius` — styled bar charts for health scores and failures
- **`mark_arc`** with `innerRadius` — donut charts for pass/fail and rule type distribution
- **`mark_area`** with gradient fills — area charts for health and anomaly trends
- **`mark_line`** with `point` overlays — trend lines for per-table health
- **`mark_text`** — value labels positioned on bars
- **`mark_rule`** — threshold reference lines (70% health, warning levels)
- **`alt.condition()`** — conditional coloring (green for healthy, red for failing)
- **Custom theme registration** — `alt.themes.register("enterprise", alt_theme)` for consistent styling

### 12. Snowflake Workspace and Git Integration

The project is developed and managed in a **Snowflake Workspace** connected to a Git repository:

- **Git-backed workspace** — files sync with a GitHub repository
- **`cortex ws cp`** — workspace CLI for file operations (copy, list, remove)
- **Server-side copy** — files copied between workspace paths without local download
- **Workspace file structure** — organized under `coco_data_quality/` with subdirectories for setup, generated files, dashboard, and documentation

---

## Execution Model

```
┌─────────────────────────────────────────────────────────────┐
│                    SP_RUN_DQ_FRAMEWORK                       │
│                                                              │
│  ┌──────────────────────┐    ┌───────────────────────────┐  │
│  │   DQ_RULE_CONFIG     │───>│  Dynamic SQL Execution    │  │
│  │   (63 active rules)  │    │  snowflake.execute(sql)   │  │
│  └──────────────────────┘    └─────────────┬─────────────┘  │
│                                            │                 │
│                    ┌───────────────────────┬┼────────────┐   │
│                    │                       ││            │   │
│                    ▼                       ▼│            ▼   │
│  ┌──────────────────────┐  ┌──────────────────┐ ┌──────────────┐
│  │   PASS/FAIL Logic    │  │  Error Sampling   │ │   Anomaly    │
│  │   threshold compare  │  │  OBJECT_CONSTRUCT │ │   Detection  │
│  │   pass % calc        │  │  up to 5 rows     │ │   3 checks   │
│  └──────────┬───────────┘  └────────┬─────────┘ └──────┬───────┘
│             │                       │                   │       │
│             ▼                       ▼                   ▼       │
│     DQ_RUN_CONTROL          DQ_ERROR_RECORDS    DQ_ANOMALY_    │
│     DQ_RULE_RESULTS                             RESULTS        │
│                                                                 │
│  On error: log to DQ_RUN_CONTROL, continue next rule           │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Summary

| Layer | Snowflake Feature |
|-------|-------------------|
| Data storage | Tables with AUTOINCREMENT, DEFAULT, PRIMARY KEY, VARIANT |
| Data profiling | SHOW COLUMNS, COUNT/SUM/AVG aggregations, RLIKE, LEFT JOIN, DATEDIFF |
| Rule configuration | INSERT ALL, metadata-driven design with SQL-as-data |
| Rule execution | JavaScript stored procedure, dynamic SQL, EXECUTE AS CALLER |
| Error capture | OBJECT_CONSTRUCT(*) into VARIANT column |
| Anomaly detection | AVG, STDDEV, ABS over rolling window subqueries |
| Visualization | Streamlit in Snowflake, st.connection, @st.cache_data, Altair |
| App deployment | snowflake.yml, pyproject.toml, Container Runtime (compute pool) |
| Project management | Snowflake Workspace, git-backed, cortex ws CLI |
| Future path | DATA_METRIC_SCHEDULE set; DMF DDL ready for Enterprise Edition |
