/*=============================================================================
  DQ_Orchestration.sql
  Data Quality Framework — Step 5: Orchestration Stored Procedure
  Database: BANKING_DQ_DB  |  Schema: DQ_MONITORING
  
  Procedure: SP_RUN_DQ_FRAMEWORK
  - Iterates through all active rules in DQ_RULE_CONFIG
  - Executes each rule SQL dynamically using RESULTSET pattern
  - Logs run control records (start/end/status) into DQ_RUN_CONTROL
  - Calculates pass percentage and stores results into DQ_RULE_RESULTS
  - Captures sample failing rows into DQ_ERROR_RECORDS (up to 5 per rule)
  - Detects anomalies and logs into DQ_ANOMALY_RESULTS:
      * Row count change >50%
      * New failures (was 0, now >0)
      * Failure spike > 2 stddev from baseline
  - Handles errors gracefully per rule (does not stop on failure)
  - Returns execution summary string
  
  Tables Populated:
    DQ_RUN_CONTROL      — every rule execution gets a run record
    DQ_RULE_RESULTS     — pass/fail, counts, percentages per rule
    DQ_ERROR_RECORDS    — sample bad rows (VARIANT) for failed rules
    DQ_ANOMALY_RESULTS  — anomalies detected vs previous runs
  
  Usage:
    CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('MANUAL');
    CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('SCHEDULED');
=============================================================================*/

USE DATABASE BANKING_DQ_DB;
USE SCHEMA DQ_MONITORING;

-- ============================================================================
-- ORCHESTRATION STORED PROCEDURE (JavaScript + RESULTSET approach)
-- ============================================================================

CREATE OR REPLACE PROCEDURE BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK(
    P_TRIGGERED_BY VARCHAR DEFAULT 'MANUAL'
)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
var rules_processed = 0, rules_passed = 0, rules_failed = 0, rules_errored = 0;

// Fetch all active rules from DQ_RULE_CONFIG
var stmt = snowflake.createStatement({sqlText:
    "SELECT RULE_ID, RULE_NAME, RULE_TYPE, CRITICALITY, DB_NAME, TABLE_NM, " +
    "COLUMN_NM, RULE_SQL, THRESHOLD_VALUE, RULE_DESCRIPTION " +
    "FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_CONFIG " +
    "WHERE IS_ACTIVE = TRUE ORDER BY RULE_ID"
});
var rules = stmt.execute();

while (rules.next()) {
    var rule_id    = rules.getColumnValue(1);
    var rule_name  = rules.getColumnValue(2);
    var rule_type  = rules.getColumnValue(3);
    var criticality = rules.getColumnValue(4);
    var db_name    = rules.getColumnValue(5);
    var table_nm   = rules.getColumnValue(6);
    var column_nm  = rules.getColumnValue(7);
    var rule_sql   = rules.getColumnValue(8);
    var threshold  = rules.getColumnValue(9);
    var rule_desc  = rules.getColumnValue(10);
    rules_processed++;

    try {
        // ====================================================================
        // STEP 1: Insert run control record (status = RUNNING)
        // ====================================================================
        snowflake.execute({sqlText:
            "INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL " +
            "(RULE_ID, RUN_START_TIME, RUN_STATUS, TRIGGERED_BY, CREATED_AT, UPDATED_AT) " +
            "VALUES (?, CURRENT_TIMESTAMP(), 'RUNNING', ?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())",
            binds: [rule_id, P_TRIGGERED_BY]
        });

        // Get auto-generated RUN_ID
        var rid_stmt = snowflake.execute({sqlText:
            "SELECT MAX(RUN_ID) FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL WHERE RULE_ID = ?",
            binds: [rule_id]
        });
        rid_stmt.next();
        var run_id = rid_stmt.getColumnValue(1);

        // ====================================================================
        // STEP 2: Execute the rule SQL dynamically (RESULTSET pattern)
        //         Each rule returns: TOTAL_RECORD_COUNT, FAILED_RECORD_COUNT
        // ====================================================================
        var rule_result = snowflake.execute({sqlText: rule_sql});
        rule_result.next();
        var total_count  = rule_result.getColumnValue(1);
        var failed_count = rule_result.getColumnValue(2);

        // ====================================================================
        // STEP 3: Calculate pass percentage and determine PASS/FAIL
        // ====================================================================
        var pass_pct = (total_count > 0)
            ? Math.round(((total_count - failed_count) / total_count) * 10000) / 100
            : 100.00;

        var result_status = (failed_count <= threshold) ? "PASS" : "FAIL";
        if (result_status === "PASS") { rules_passed++; } else { rules_failed++; }

        // ====================================================================
        // STEP 4: Insert rule result into DQ_RULE_RESULTS
        // ====================================================================
        snowflake.execute({sqlText:
            "INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS " +
            "(RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, COLUMN_NAME, RULE_NAME, RULE_TYPE, " +
            "EXPECTED_VALUE, ACTUAL_VALUE, FAILED_RECORD_COUNT, TOTAL_RECORD_COUNT, " +
            "PASS_PERCENTAGE, RESULT_STATUS, SEVERITY, ERROR_SAMPLE_QUERY, EXECUTED_AT) " +
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP())",
            binds: [run_id, rule_id, db_name, table_nm, column_nm, rule_name, rule_type,
                    threshold, failed_count, failed_count, total_count,
                    pass_pct, result_status, criticality, rule_sql]
        });

        // ====================================================================
        // STEP 5: Update run control with completion status
        // ====================================================================
        snowflake.execute({sqlText:
            "UPDATE BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL " +
            "SET RUN_END_TIME = CURRENT_TIMESTAMP(), RULE_EXEC_RESULT = ?, " +
            "RULE_OUTPUT_VALUE = ?, RUN_STATUS = 'COMPLETED', " +
            "UPDATED_AT = CURRENT_TIMESTAMP() WHERE RUN_ID = ?",
            binds: [result_status, failed_count, run_id]
        });

        // ====================================================================
        // STEP 6: ERROR RECORDS — Capture sample failing rows (up to 5)
        //         Only for FAILED rules with a known column
        // ====================================================================
        if (result_status === "FAIL" && table_nm && column_nm) {
            try {
                var error_sql = "";
                var fqtn = db_name + "." + table_nm;

                // Build a WHERE clause specific to this rule type/name
                if (rule_type === "COMPLETENESS") {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IS NULL LIMIT 5";
                } else if (rule_type === "UNIQUENESS") {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IN (SELECT " + column_nm +
                                " FROM " + fqtn + " GROUP BY " + column_nm +
                                " HAVING COUNT(*) > 1) LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("KYC") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('VERIFIED','PENDING','REJECTED') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("RISK") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('LOW','MEDIUM','HIGH') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("ACCOUNT_TYPE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('SAVINGS','CURRENT','LOAN') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("ACCOUNT_STATUS") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('ACTIVE','DORMANT','CLOSED') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("CURRENCY") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('INR','USD') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("TXN_TYPE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('DEBIT','CREDIT','TRANSFER') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("TXN_STATUS") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('SUCCESS','FAILED','PENDING') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("CHANNEL") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('UPI','CARD','NEFT','IMPS','ATM','CHEQUE','RTGS') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("LOAN_TYPE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('HOME','PERSONAL','CAR','EDUCATION','BUSINESS') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("APP_STATUS") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " NOT IN ('PENDING','APPROVED','REJECTED') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("IFSC") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IS NOT NULL AND NOT RLIKE(" + column_nm +
                                ", '^[A-Z]{4}0[A-Z0-9]{6}$') LIMIT 5";
                } else if (rule_type === "VALIDITY" && rule_name.indexOf("EMAIL") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IS NOT NULL AND NOT RLIKE(" + column_nm +
                                ", '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,}$') LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("DOB_NOT_FUTURE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " > CURRENT_DATE() LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("REASONABLE_AGE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IS NOT NULL AND (DATEDIFF('YEAR', " +
                                column_nm + ", CURRENT_DATE()) < 18 OR DATEDIFF('YEAR', " +
                                column_nm + ", CURRENT_DATE()) > 120) LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("AMOUNT_POSITIVE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " <= 0 LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("SAVINGS_BAL") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE ACCOUNT_TYPE = 'SAVINGS' AND BALANCE < 0 LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("CREDIT_SCORE") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IS NOT NULL AND (" + column_nm +
                                " < 300 OR " + column_nm + " > 900) LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("APPROVED_LEQ") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE APPROVED_AMOUNT IS NOT NULL AND REQUESTED_AMOUNT IS NOT NULL " +
                                "AND APPROVED_AMOUNT > REQUESTED_AMOUNT LIMIT 5";
                } else if (rule_type === "ACCURACY" && rule_name.indexOf("REQUESTED_AMT") >= 0) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE REQUESTED_AMOUNT IS NOT NULL AND REQUESTED_AMOUNT <= 0 LIMIT 5";
                } else if (rule_type === "ACCURACY" && (rule_name.indexOf("DATE_NOT_FUTURE") >= 0 ||
                           rule_name.indexOf("OPEN_DATE") >= 0)) {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE " + column_nm + " IS NOT NULL AND " + column_nm +
                                " > CURRENT_DATE() LIMIT 5";
                } else if (rule_type === "CONSISTENCY") {
                    error_sql = "SELECT OBJECT_CONSTRUCT(*) AS REC FROM " + fqtn +
                                " WHERE APPLICATION_STATUS IN ('PENDING','REJECTED') " +
                                "AND APPROVED_AMOUNT IS NOT NULL LIMIT 5";
                } else if (rule_type === "REFERENTIAL_INTEGRITY") {
                    error_sql = "SELECT OBJECT_CONSTRUCT(a.*) AS REC FROM " + fqtn + " a " +
                                "WHERE a." + column_nm + " IS NOT NULL AND a." + column_nm +
                                " NOT IN (SELECT DISTINCT " + column_nm +
                                " FROM BANKING_DQ_DB.RAW.BRANCHES " +
                                "UNION SELECT DISTINCT " + column_nm +
                                " FROM BANKING_DQ_DB.RAW.CUSTOMERS " +
                                "UNION SELECT DISTINCT " + column_nm +
                                " FROM BANKING_DQ_DB.RAW.ACCOUNTS) LIMIT 5";
                }

                // Execute error sampling and insert into DQ_ERROR_RECORDS
                if (error_sql !== "") {
                    var err_result = snowflake.execute({sqlText: error_sql});
                    while (err_result.next()) {
                        var error_rec = err_result.getColumnValue(1);
                        snowflake.execute({sqlText:
                            "INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_ERROR_RECORDS " +
                            "(RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, ERROR_RECORD_VARIANT, " +
                            "ERROR_REASON, CREATED_AT) " +
                            "VALUES (?,?,?,?,PARSE_JSON(?),?,CURRENT_TIMESTAMP())",
                            binds: [run_id, rule_id, db_name, table_nm,
                                    JSON.stringify(error_rec), rule_desc]
                        });
                    }
                }
            } catch(sample_err) {
                // Error sampling failed — continue silently
            }
        }

        // ====================================================================
        // STEP 7: ANOMALY DETECTION — compare with previous runs
        // ====================================================================
        try {
            var prev_stmt = snowflake.execute({sqlText:
                "SELECT TOTAL_RECORD_COUNT, FAILED_RECORD_COUNT " +
                "FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS " +
                "WHERE RULE_ID = ? AND RESULT_ID != " +
                "(SELECT MAX(RESULT_ID) FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS WHERE RULE_ID = ?) " +
                "ORDER BY EXECUTED_AT DESC LIMIT 1",
                binds: [rule_id, rule_id]
            });

            if (prev_stmt.next()) {
                var prev_total  = prev_stmt.getColumnValue(1);
                var prev_failed = prev_stmt.getColumnValue(2);
                var anomaly_reason = null;

                // Check 1: Row count changed >50%
                if (prev_total > 0 && Math.abs(total_count - prev_total) / prev_total > 0.5) {
                    anomaly_reason = "Row count changed >50%: prev=" + prev_total + " curr=" + total_count;
                }

                // Check 2: New failures where previously all passing
                if (prev_failed == 0 && failed_count > 0) {
                    anomaly_reason = (anomaly_reason ? anomaly_reason + "; " : "") +
                                     "New failures: was 0, now " + failed_count;
                }

                // Check 3: Failure count > 2 stddev from baseline
                var base_stmt = snowflake.execute({sqlText:
                    "SELECT AVG(FAILED_RECORD_COUNT), STDDEV(FAILED_RECORD_COUNT) " +
                    "FROM (SELECT FAILED_RECORD_COUNT " +
                    "FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS " +
                    "WHERE RULE_ID = ? ORDER BY EXECUTED_AT DESC LIMIT 10)",
                    binds: [rule_id]
                });
                if (base_stmt.next()) {
                    var baseline_avg    = base_stmt.getColumnValue(1);
                    var baseline_stddev = base_stmt.getColumnValue(2);
                    if (baseline_stddev > 0 && failed_count > baseline_avg + 2 * baseline_stddev) {
                        anomaly_reason = (anomaly_reason ? anomaly_reason + "; " : "") +
                                         "Failure spike: val=" + failed_count +
                                         " avg=" + Math.round(baseline_avg * 100) / 100;
                    }
                }

                // Log anomaly if detected
                if (anomaly_reason) {
                    snowflake.execute({sqlText:
                        "INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_ANOMALY_RESULTS " +
                        "(RUN_ID, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, METRIC_NAME, " +
                        "CURRENT_VALUE, PREVIOUS_VALUE, BASELINE_AVG, BASELINE_STDDEV, " +
                        "ANOMALY_STATUS, ANOMALY_REASON, DETECTED_AT) " +
                        "VALUES (?,?,?,?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP())",
                        binds: [run_id, "BANKING_DQ_DB", "RAW", table_nm, rule_name,
                                failed_count, prev_failed, baseline_avg, baseline_stddev,
                                "DETECTED", anomaly_reason]
                    });
                }
            }
        } catch(anomaly_err) {
            // No previous data for anomaly detection — skip silently
        }

    } catch(err) {
        // ====================================================================
        // ERROR HANDLING — log error, continue to next rule
        // ====================================================================
        rules_errored++;
        try {
            snowflake.execute({sqlText:
                "UPDATE BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL " +
                "SET RUN_END_TIME = CURRENT_TIMESTAMP(), RULE_EXEC_RESULT = 'ERROR', " +
                "RUN_STATUS = 'FAILED', ERROR_MESSAGE = ?, UPDATED_AT = CURRENT_TIMESTAMP() " +
                "WHERE RUN_ID = (SELECT MAX(RUN_ID) FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL WHERE RULE_ID = ?)",
                binds: [err.message, rule_id]
            });
        } catch(upd_err) {
            // Silently handle update errors
        }
    }
}

return "DQ Framework Run Complete | Processed: " + rules_processed +
       " | Passed: " + rules_passed +
       " | Failed: " + rules_failed +
       " | Errors: " + rules_errored;
$$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify procedure was created
SHOW PROCEDURES LIKE 'SP_RUN_DQ_FRAMEWORK' IN SCHEMA BANKING_DQ_DB.DQ_MONITORING;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

-- Run manually
-- CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('MANUAL');

-- Run as scheduled (when called from a TASK)
-- CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('SCHEDULED');

-- Optional: Schedule with a Snowflake TASK
-- CREATE OR REPLACE TASK BANKING_DQ_DB.DQ_MONITORING.TASK_DQ_DAILY
--     WAREHOUSE = COMPUTE_WH
--     SCHEDULE = 'USING CRON 0 6 * * * UTC'
--     COMMENT = 'Daily DQ framework execution at 6 AM UTC'
-- AS
--     CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('SCHEDULED');
-- ALTER TASK BANKING_DQ_DB.DQ_MONITORING.TASK_DQ_DAILY RESUME;
