# Data Quality Framework for Snowflake

An enterprise-style, metadata-driven **Data Quality (DQ) Framework** built entirely within Snowflake. Monitors a banking dataset across five relational tables using 63 data quality rules spanning seven quality dimensions, with automated anomaly detection and a Streamlit dashboard for interactive visualization.

## Highlights

- **63 rules** across completeness, uniqueness, validity, accuracy, consistency, referential integrity, and timeliness
- **Metadata-driven** — rules stored as configuration, executed dynamically by a stored procedure
- **Anomaly detection** — compares consecutive runs to flag row count spikes, new failures, and statistical outliers
- **Error sampling** — captures failing rows as VARIANT for root cause investigation
- **Streamlit dashboard** — 4-tab interactive UI with health scores, trend charts, drill-down, and coverage reporting
- **Standard and Enterprise Edition compatible** — SQL-based rules engine with reference DMF DDL for native migration

## Project Structure

```
coco_data_quality/
  00_setup/
    00_load_synthetic_data.sql         # Database, schema, tables, synthetic banking data
  01_DQ_instructions/
    data_quality_framework.md          # Step-by-step build instructions
  Generated_files/
    DQ_data_profiling.sql              # Data profiling queries
    DQ_Proposed_Rules.sql              # Recommended rules documentation
    DQ_Rules.sql                       # Rule SQL definitions + DMF reference
    DQ_Framework_Config.sql            # Framework schema/table DDL + rule loading
    DQ_Orchestration.sql               # Stored procedure definition
    DQ_cleanup.sql                     # Drop all framework objects
  DQ_MONITORING_DASHBOARD/
    .streamlit/config.toml             # Streamlit theme configuration
    pyproject.toml                     # Python dependencies
    snowflake.yml                      # Snowflake app deployment config
    streamlit_app.py                   # Dashboard application
  docs/
    README.md                          # This file
    ARCHITECTURE.md                    # Technical architecture and design
    RULES_CATALOG.md                   # Complete rule catalog by dimension
    DASHBOARD_GUIDE.md                 # Dashboard features and usage
```

## Quick Start

### 1. Create the database and load data

Run `00_setup/00_load_synthetic_data.sql` — this creates `BANKING_DQ_DB` with the `RAW` schema and loads the baseline banking dataset (Set 1). Set 2 is commented out for later anomaly testing.

### 2. Create the framework

Run in order:
```sql
-- Step 4: Create DQ_MONITORING schema and tables
-- Run: Generated_files/DQ_Framework_Config.sql

-- Step 3: Load all 63 rules into DQ_RULE_CONFIG
-- Run: Generated_files/DQ_Rules.sql

-- Step 5: Create the orchestration stored procedure
-- Run: Generated_files/DQ_Orchestration.sql
```

### 3. Execute the framework

```sql
CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('MANUAL');
```

Returns: `DQ Framework Run Complete | Processed: 63 | Passed: X | Failed: Y | Errors: Z`

### 4. View the dashboard

Open `DQ_MONITORING_DASHBOARD/streamlit_app.py` in a Snowflake Workspace and click **Run**.

### 5. Test anomaly detection

Uncomment and run Set 2 in `00_load_synthetic_data.sql`, then re-run the stored procedure. The anomaly detection will flag row count spikes, new failures, and statistical outliers.

### 6. Cleanup

`Generated_files/DQ_cleanup.sql` drops all framework objects. **Do not run unless you want to remove everything.**

## Banking Dataset

| Table | Description | Rows (Set 1) | Rows (after Set 2) |
|-------|-------------|:---:|:---:|
| BRANCHES | Bank branch locations | 7 | 11 |
| CUSTOMERS | Customer master records | 10 | 17 |
| ACCOUNTS | Bank accounts | 10 | 18 |
| TRANSACTIONS | Financial transactions | 12 | 25 |
| LOAN_APPLICATIONS | Loan applications with credit scoring | 10 | 18 |

The dataset includes intentional quality issues (NULL values, invalid formats, orphaned references, non-standard categorical values, negative balances, future dates) to demonstrate framework detection capabilities.

## Documentation

| Document | Contents |
|----------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Framework design, metadata tables, orchestration flow, anomaly detection logic |
| [RULES_CATALOG.md](RULES_CATALOG.md) | All 63 rules organized by quality dimension with SQL examples |
| [DASHBOARD_GUIDE.md](DASHBOARD_GUIDE.md) | Dashboard tabs, charts, filters, and drill-down features |

## Compatibility

- **Standard Edition**: Uses a SQL-based rules engine where each rule is a stored SQL query executed dynamically by a JavaScript stored procedure.
- **Enterprise Edition**: `DQ_Rules.sql` includes reference DDL (Section B, commented out) for Snowflake native Data Metric Functions — system DMFs (NULL_COUNT, DUPLICATE_COUNT, ROW_COUNT, FRESHNESS, ACCEPTED_VALUES) and custom DMFs. These can be activated after upgrading.

## Production Considerations

This project demonstrates the framework on a small synthetic dataset. For production use, consider:

- **Scheduling** — Snowflake TASK for automated execution (cron or `TRIGGER_ON_CHANGES`)
- **Alerting** — Email/Slack/webhook notifications on critical failures
- **RBAC** — Dedicated roles (`DQ_ADMIN`, `DQ_VIEWER`) with appropriate grants
- **Environment separation** — Separate schemas for dev/test/prod
- **Retention** — Archival policies on results tables
- **CI/CD** — Version-controlled SQL with automated deployment
