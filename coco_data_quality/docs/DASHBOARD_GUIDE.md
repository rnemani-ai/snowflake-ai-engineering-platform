# Dashboard Guide

The DQ Monitoring Dashboard is a Streamlit-in-Snowflake application that provides interactive visualization of data quality metrics across all monitored tables.

## Running the Dashboard

1. Open `DQ_MONITORING_DASHBOARD/streamlit_app.py` in a Snowflake Workspace
2. Click **Run**
3. The dashboard reads from the 5 framework tables in `BANKING_DQ_DB.DQ_MONITORING`

The dashboard **only visualizes** existing results. To get fresh data, run the stored procedure first:
```sql
CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('MANUAL');
```

## Sidebar Filters

All tabs respond to the sidebar filters:

- **Tables** — select which tables to include
- **Rule type** — filter by quality dimension (COMPLETENESS, VALIDITY, etc.)
- **Severity** — filter by HIGH, MEDIUM, LOW
- **Status** — filter by PASS, FAIL
- **Refresh Data** — clears cached data and reloads from Snowflake
- Displays last run timestamp and database context

---

## Tab 1: Overview

The primary health monitoring view.

### KPI Row

Seven metric cards in a horizontal row:

| Metric | Source | Notes |
|--------|--------|-------|
| Overall health | Pass count / total rules * 100 | Includes delta vs previous run |
| Monitored tables | Count of selected tables | Responds to filter |
| Active rules | IS_ACTIVE = TRUE from DQ_RULE_CONFIG | Total across all tables |
| Passed | Rules with RESULT_STATUS = PASS | Filtered |
| Failed | Rules with RESULT_STATUS = FAIL | Filtered |
| Critical failures | Failed rules with SEVERITY = HIGH | Filtered |
| Anomalies detected | Total rows in DQ_ANOMALY_RESULTS | All anomalies |

### Charts

| Chart | Type | Description |
|-------|------|-------------|
| Table health scores | Bar chart | Per-table health percentage with 70% threshold line and value labels; green >=70%, red <70% |
| Rule pass/fail distribution | Donut chart | PASS vs FAIL counts with health percentage in center |
| Failures by severity | Bar chart | Failed rule count grouped by HIGH/MEDIUM/LOW |
| Failures by rule type | Bar chart | Failed rule count grouped by quality dimension |
| Top failing tables | Horizontal bar chart | Top 5 tables by failure count |
| Top failing columns | Horizontal bar chart | Top 5 columns by failure count |
| Health score trend | Area chart | Health percentage over time with 70% threshold line |

### Table Drill-Down

Select a table from the dropdown to see:

- **KPI row** — table-specific health %, rule count, passed, failed
- **Health trend** — line chart of the selected table's health over time
- **Failed rules** — data table with rule name, column, type, severity, failed/total counts, pass % (progress bar)
- **Sample error records** — from DQ_ERROR_RECORDS: rule ID, error reason, full row as VARIANT
- **Recent anomalies** — from DQ_ANOMALY_RESULTS: metric name, current/previous values, anomaly reason

---

## Tab 2: Rule Results

Detailed view of all rule execution results.

### Results Table

Sortable table showing all rules from the latest run:

| Column | Description |
|--------|-------------|
| RULE_NAME | Rule identifier |
| TABLE_NAME | Target table |
| COLUMN_NAME | Target column |
| RULE_TYPE | Quality dimension |
| SEVERITY | HIGH / MEDIUM / LOW |
| RESULT_STATUS | PASS or FAIL |
| Failed | Failed record count |
| Total | Total record count |
| Pass % | Rendered as a progress bar |
| Executed | Timestamp of execution |

### Table Drill-Down

Select a table to see:

- **KPI row** — health %, total rules, passed, failed
- **Failed rules** (left column) — data table with pass % progress bars
- **Passing rules** (right column) — data table
- **Sample error records** — VARIANT rows from DQ_ERROR_RECORDS
- **Recommended fixes** — for each failed rule: severity badge, rule name, column, failure counts

---

## Tab 3: Anomalies

Anomaly detection results from comparing consecutive DQ runs.

### KPI Row

| Metric | Description |
|--------|-------------|
| Total anomalies | Count of all detected anomalies |
| Tables affected | Distinct tables with anomalies |
| New failures | Anomalies where reason contains "New failures" |
| Failure spikes | Anomalies where reason contains "spike" |

### Charts

| Chart | Type | Description |
|-------|------|-------------|
| Anomalies by table | Bar chart | Count of anomalies per table |
| Anomaly trend | Area chart | Anomaly count over time |

### Anomaly Details

Full data table showing:
- Table name and metric name
- Current and previous failed record counts
- Human-readable anomaly reason
- Detection timestamp

Displays an informational message when no anomalies have been detected.

---

## Tab 4: Coverage

Rule configuration and distribution analysis.

### KPI Row

| Metric | Description |
|--------|-------------|
| Total rules | All rules in DQ_RULE_CONFIG |
| Active rules | Rules with IS_ACTIVE = TRUE |
| Tables covered | Distinct tables with rules |
| Rule types | Distinct quality dimensions |

### Charts and Tables

| Element | Type | Description |
|---------|------|-------------|
| Rules per table | Data table | Total and active rule counts per table |
| Rules by type | Donut chart | Distribution across quality dimensions |
| Rules by criticality per table | Stacked bar chart | HIGH/MEDIUM/LOW breakdown per table |
| Full rule configuration | Data table | All 63 rules with ID, name, type, table, column, criticality, description, and active status (checkbox) |

---

## Technical Details

- **Connection**: `st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))`
- **Caching**: All data loaders use `@st.cache_data(ttl=120)` (2-minute TTL)
- **Charts**: Altair with a custom enterprise theme (transparent backgrounds, consistent color palette)
- **Layout**: Wide mode, 4 tabs, sidebar filters, bordered containers
- **Dependencies**: `streamlit[snowflake]>=1.54.0` (default Snowflake package, no external access integration required)
