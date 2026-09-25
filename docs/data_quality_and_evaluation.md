# Data Quality and AI Evaluation

## 1. Data Quality Framework

The platform includes a lightweight SQL-based data-quality framework designed to demonstrate how common banking data issues can be detected and surfaced to users.

The framework focuses on three categories:

```text
Completeness
     +
Uniqueness
     +
Business Validity
```

## 2. Data Profiling

Before defining rules, the project profiles the banking tables.

The profiling workflow checks:

- Row counts
- NULL identifiers
- Distinct identifiers
- Potential duplicate records

The profiling SQL is contained in:

```text
cortex_project/03_dq_profiling.sql
```

This provides an initial understanding of the data before applying validation rules.

## 3. Data Quality Rules

The Streamlit dashboard currently displays six primary DQ checks.

| Table | Rule | Validation |
|---|---|---|
| `CUSTOMERS` | `CUSTOMER_ID_NOT_NULL` | Customer ID must not be NULL |
| `ACCOUNTS` | `BALANCE_NON_NEGATIVE` | Account balance must be >= 0 |
| `TRANSACTIONS` | `TRANSACTION_ID_UNIQUE` | Transaction IDs must be unique |
| `TRANSACTIONS` | `AMOUNT_NOT_NULL` | Transaction amount must not be NULL |
| `LOAN_APPLICATIONS` | `APPLICATION_ID_UNIQUE` | Application IDs must be unique |
| `LOAN_APPLICATIONS` | `LOAN_AMOUNT_NOT_NULL` | Loan amount must not be NULL |

The corresponding implementation is maintained in:

```text
cortex_project/04_dq_rules.sql
```

## 4. Intentional Data-Quality Issues

The project intentionally introduces invalid records so that the DQ framework can demonstrate failures.

### Negative Account Balance

An account record contains a negative balance.

Expected rule:

```text
BALANCE >= 0
```

This produces a failure for the `BALANCE_NON_NEGATIVE` rule.

### Duplicate Transaction

A transaction ID is intentionally duplicated.

This demonstrates the:

```text
TRANSACTION_ID_UNIQUE
```

rule.

### Missing Transaction Amount

A transaction contains a NULL amount.

This demonstrates:

```text
AMOUNT_NOT_NULL
```

### Duplicate Loan Application

A loan application ID is intentionally duplicated.

This demonstrates:

```text
APPLICATION_ID_UNIQUE
```

### Missing Loan Amount

Loan application records contain NULL loan amounts.

This demonstrates:

```text
LOAN_AMOUNT_NOT_NULL
```

These records are intentionally created for demonstration and testing.

They do not represent real banking data.

## 5. DQ Monitoring

The Streamlit application summarizes each rule using:

- Source table
- Rule name
- Description
- Failed record count
- PASS / FAIL status

The dashboard uses the failed-record count to determine the status:

```text
Failed Records = 0
        ↓
      PASS

Failed Records > 0
        ↓
      FAIL
```

This provides a simple operational view of current data quality.

## 6. Why Data Quality Matters for AI

Data quality becomes particularly important when AI systems are used for analytics.

For example:

```text
Incorrect Source Data
        ↓
Incorrect Aggregation
        ↓
Incorrect AI Answer
```

An AI system can generate syntactically valid SQL while still producing an incorrect business result if the underlying data contains quality problems.

Therefore, this project treats data-quality monitoring as a separate foundational capability alongside AI analytics.

# AI Evaluation

## 7. Evaluation Approach

The project includes a lightweight evaluation framework for natural-language analytics.

Instead of only checking whether Cortex Analyst successfully executes SQL, the evaluation compares the returned analytical result with a predefined expected result.

The workflow is:

```text
Evaluation Question
        ↓
Cortex Analyst
        ↓
Generated SQL
        ↓
Actual Result
        ↓
Expected Result
        ↓
PASS / FAIL
```

This makes the evaluation focused on business-result correctness.

## 8. Evaluation Test Cases

The current application contains three evaluation scenarios.

### Test Case 1 — Total Balance by Account Type

Question:

```text
What is the total balance by account type?
```

Expected result:

```text
CHECKING = 10,200
SAVINGS  = 21,200
```

The expected checking balance reflects the intentionally inserted negative-balance test record.

### Test Case 2 — Average Balance by Account Type

Question:

```text
What is the average balance by account type?
```

Expected result:

```text
CHECKING = 3,400
SAVINGS  = 10,600
```

The evaluation compares the normalized result returned by Cortex Analyst with these expected values.

### Test Case 3 — Loan Applications by Status

Question:

```text
How many loan applications are there by status?
```

Expected result:

```text
APPROVED = 3
PENDING  = 1
REJECTED = 1
```

The evaluation verifies that Cortex Analyst returns the expected distribution.

## 9. Result Normalization

AI-generated analytical results can contain different column names depending on how Cortex Analyst constructs the SQL.

For example, an aggregation may be returned using:

```text
TOTAL_BALANCE
```

or:

```text
AVERAGE_BALANCE
```

The application normalizes relevant result fields before comparing them with the expected values.

This avoids treating harmless column-name differences as analytical failures.

## 10. What the Evaluation Does Not Claim

The current evaluation framework is intentionally lightweight.

It evaluates whether selected business questions return the expected analytical results.

It does not currently provide comprehensive evaluation of:

- Hallucination
- Groundedness
- Safety
- Bias
- Citation accuracy
- Response latency
- Cost
- Complex multi-turn reasoning

These can be added as future evaluation dimensions.

## 11. Evaluation vs. Data Quality

The two capabilities answer different questions.

### Data Quality asks:

> Is the underlying data valid?

Example:

```text
Are transaction IDs unique?
```

### AI Evaluation asks:

> Did the AI system produce the expected analytical answer?

Example:

```text
Did Cortex Analyst correctly calculate
total balance by account type?
```

Together:

```text
             Banking Data
                  │
                  ▼
          Data Quality Checks
                  │
                  ▼
          Semantic Analytics
                  │
                  ▼
           Cortex Analyst
                  │
                  ▼
            AI Evaluation
```

This separation helps distinguish a **data problem** from an **AI analytical problem**.

## 12. Future Evaluation Enhancements

A production-oriented implementation could extend the evaluation framework with:

### SQL Accuracy

Compare generated SQL against validated query patterns.

### Result Accuracy

Compare AI-generated results against trusted results across a larger test suite.

### Regression Testing

Run the evaluation suite whenever the semantic model changes.

### Semantic Coverage

Measure how many important business questions are represented by verified queries.

### Reliability

Track success rate across repeated evaluations.

### Latency

Measure the time from question submission to final result.

### Cost

Track AI and query execution costs.

### Groundedness

Verify that generated answers are supported by the available data and semantic model.

### Safety

Add checks for inappropriate or unauthorized analytical requests.

## 13. Portfolio Demonstration

The application intentionally demonstrates both successful and failed data-quality states.

This is useful for demonstrating that the framework is not simply displaying static healthy data.

The screenshots in:

```text
screenshots/
```

capture the main platform views:

- Platform overview
- Cortex Analyst
- Data Quality Monitoring
- AI Evaluation