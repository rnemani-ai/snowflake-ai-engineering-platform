# 02 — Technical Architecture and Implementation

## Enterprise Banking AI Platform on Snowflake

> **Purpose:** Deep technical reference for the implemented Snowflake architecture, semantic layer, Cortex Analyst integration, data-quality engineering, Cortex Code workflow, Streamlit application, governance controls, testing, and source-control structure.

---

# 1. Architecture at a Glance

The platform has two complementary implementation surfaces built on a shared Snowflake foundation:

```text
                           ENTERPRISE BANKING AI PLATFORM
                                      |
                  +-------------------+-------------------+
                  |                                       |
           USER-FACING PATH                         ENGINEERING PATH
                  |                                       |
             Streamlit                              Cortex Code
                  |                                    / CoCo
        +---------+---------+                           |
        |         |         |                     DQ Engineering
        v         v         v                           |
     Cortex      DQ       AI Eval                 +-----+------+
    Analyst   Monitoring                              |     |
        |         |         |                      Profile Rules
        |         |         |                           |
        +---------+---------+                           |
                  |                                     |
                  +------------------+------------------+
                                     |
                                SNOWFLAKE
                                     |
                    +----------------+----------------+
                    |                |                |
                   RAW           ANALYTICS        GOVERNANCE
                    |                |                |
              Banking Tables    Semantic View    RBAC/Policies
```

The application path demonstrates how users consume the platform.

The CoCo path demonstrates how an engineer can build, inspect, test, and validate the data-quality capability.

---

# 2. Snowflake Object Model

The implementation uses the following primary database structures:

```text
BANKING_DQ_DB
|
+-- RAW
|   +-- CUSTOMERS
|   +-- ACCOUNTS
|   +-- TRANSACTIONS
|   +-- LOAN_APPLICATIONS
|   +-- BRANCHES
|
+-- ANALYTICS
|   +-- BANKING_ANALYTICS
|
+-- GOVERNANCE
    +-- CUSTOMER_LAST_NAME_MASK
    +-- CUSTOMER_ROW_ACCESS
```

The semantic view is:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

The governance schema is:

```text
BANKING_DQ_DB.GOVERNANCE
```

---

# 3. Source Data Model

## 3.1 CUSTOMERS

Logical purpose:

> Customer master information.

Representative attributes used by the semantic layer include:

- `CUSTOMER_ID`
- customer name attributes
- city
- state

Quality controls include customer identifier completeness and uniqueness.

---

## 3.2 ACCOUNTS

Logical purpose:

> Customer account information.

Representative attributes include:

- `ACCOUNT_ID`
- customer relationship
- branch relationship
- account type
- account status
- `BALANCE`

Quality controls include:

- account identifier completeness
- account identifier uniqueness
- balance completeness
- non-negative balance validation

---

## 3.3 TRANSACTIONS

Logical purpose:

> Account transaction information.

Representative attributes include:

- `TRANSACTION_ID`
- account relationship
- transaction type
- transaction status
- `AMOUNT`

Quality controls include:

- transaction identifier uniqueness
- transaction amount completeness

---

## 3.4 LOAN_APPLICATIONS

Logical purpose:

> Loan application information.

Representative attributes include:

- `APPLICATION_ID`
- customer relationship
- loan type
- application status
- `LOAN_AMOUNT`

Quality controls include:

- application identifier uniqueness
- loan amount completeness

---

## 3.5 BRANCHES

Logical purpose:

> Banking branch reference information.

Representative attributes include:

- `BRANCH_ID`
- branch name
- city

The current profiling SQL focuses on CUSTOMERS, ACCOUNTS, TRANSACTIONS, and LOAN_APPLICATIONS; BRANCHES is represented in the semantic model and application data landscape.

---

# 4. Semantic View Architecture

The semantic view is the central abstraction used by Cortex Analyst.

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

It contains:

### Logical tables

- ACCOUNTS
- BRANCHES
- CUSTOMERS
- LOAN_APPLICATIONS
- TRANSACTIONS

### Relationships

```text
ACCOUNTS_TO_BRANCHES
ACCOUNTS_TO_CUSTOMERS
LOANS_TO_CUSTOMERS
TRANSACTIONS_TO_ACCOUNTS
```

These relationships allow Cortex Analyst to reason over the banking domain without requiring the user to explicitly specify physical joins.

---

# 5. Semantic Model Components

The semantic model uses four important concepts:

```text
Tables
   +
Relationships
   +
Dimensions / Facts
   +
Metrics
```

## Dimensions

Examples include:

- account type
- account status
- transaction type
- transaction status
- customer name
- customer city
- customer state
- branch name
- branch city
- loan type
- application status

## Facts

The model exposes numeric business facts such as:

- account balance
- transaction amount
- loan amount

## Metrics

The implementation defines:

```text
TOTAL_BALANCE
AVERAGE_BALANCE
ACCOUNT_COUNT
TOTAL_TRANSACTION_AMOUNT
TRANSACTION_COUNT
TOTAL_LOAN_AMOUNT
LOAN_APPLICATION_COUNT
```

The distinction between a raw fact and a business metric is important. A metric represents a reusable analytical definition that Cortex Analyst can use for business questions.

---

# 6. Semantic Grounding

The semantic layer provides the business vocabulary available to the natural-language analytics layer.

The intended flow is:

```text
Business language
       |
       v
Semantic concept
       |
       v
Defined dimension / metric
       |
       v
Physical Snowflake objects
       |
       v
SQL
```

The semantic instructions explicitly guide the AI to:

- use defined semantic dimensions and metrics
- prefer semantic metrics
- use logical names
- correctly calculate ranking/comparison questions
- avoid inventing unsupported columns
- avoid inventing unsupported tables
- avoid inventing unsupported dimensions
- avoid inventing unsupported facts
- avoid inventing unsupported metrics

This is a key enterprise control because it reduces the gap between an unconstrained natural-language request and the governed data model.

---

# 7. Semantic YAML and Cortex Project Artifacts

The repository also contains a declarative semantic-model artifact:

```text
BANKING_ANALYTICS.sv.yaml
```

and a Cortex project configuration:

```text
cortex-project.yaml
```

The project configuration identifies the semantic-view artifact and its target:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

This creates a version-controlled representation of the semantic layer in addition to the SQL implementation.

---

# 8. Cortex Analyst Integration

The Streamlit application communicates with Cortex Analyst through Snowflake's Cortex Analyst endpoint.

The application:

1. obtains the active Snowflake session
2. retrieves the Snowflake session token
3. identifies the Snowflake host
4. constructs the Cortex Analyst request
5. supplies the user question
6. specifies the semantic view
7. sends the request
8. validates the HTTP response
9. extracts the response text and generated SQL
10. displays the result in Streamlit

Conceptually:

```text
Streamlit
    |
    | user question
    v
Cortex Analyst API
    |
    | semantic_view =
    | BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
    v
Semantic interpretation
    |
    v
Generated SQL
    |
    v
Snowflake execution
    |
    v
Result
```

---

# 9. Snowflake Session and Authentication

The application uses:

```python
get_active_session()
```

from:

```text
snowflake.snowpark.context
```

This provides the active Snowflake session when the Streamlit application runs in the Snowflake environment.

The Cortex Analyst request uses:

- Snowflake host information
- the Snowflake session token
- OAuth token type headers
- a bounded request timeout

The request includes the appropriate Snowflake authorization header.

This avoids embedding a long-lived static credential in the application code.

---

# 10. Cortex Analyst Request Boundary

The semantic view is explicitly passed as part of the Cortex Analyst request.

This is important because the application is not asking the model to search arbitrary database objects.

Instead:

```text
User Question
      |
      v
Specified Semantic View
      |
      v
Analytical Interpretation
      |
      v
SQL
```

The semantic view acts as the intended analytical boundary.

---

# 11. Generated SQL Transparency

The application extracts and displays generated SQL.

The user can therefore inspect:

```text
Question
   ↓
Generated SQL
   ↓
Query Result
```

For example, a total-balance question can produce a semantic-view query grouped by account type.

This supports:

- debugging
- user transparency
- SQL review
- semantic-model troubleshooting
- AI evaluation

---

# 12. Verified Query Capability

The repository includes:

```text
02_verified_queries.sql
```

A representative verified query is:

> What is the total balance and number of accounts by account type?

The SQL groups by:

```text
ACCOUNT_TYPE
```

and evaluates:

```text
TOTAL_BALANCE
ACCOUNT_COUNT
```

The verified-query capability provides a starting point for known-good analytical questions that can be used as regression examples.

---

# 13. Data Quality Architecture

The DQ implementation is deliberately separated into multiple SQL scripts.

```text
03_dq_profiling.sql
        |
        v
04_dq_rules.sql
        |
        v
05_inject_dq_issues.sql
        |
        v
06_verify_dq_issues.sql
```

Each script has a distinct responsibility.

| Script | Responsibility |
|---|---|
| `03_dq_profiling.sql` | Understand baseline data characteristics |
| `04_dq_rules.sql` | Define executable quality rules |
| `05_inject_dq_issues.sql` | Create controlled test defects |
| `06_verify_dq_issues.sql` | Verify that defects are observable |

This separation improves readability and makes individual stages easier to test.

---

# 14. Profiling Implementation

The profiling stage checks basic structural quality.

Examples:

```text
COUNT(*)
COUNT(NULL identifiers)
COUNT(DISTINCT identifiers)
```

The current script profiles:

- CUSTOMERS
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS

This allows the engineer to compare total rows, NULL identifiers, and distinct identifiers.

A typical uniqueness interpretation is:

```text
COUNT(*) = COUNT(DISTINCT key)
```

when NULL handling is appropriately considered.

---

# 15. DQ Rule Implementation

The DQ rule script defines ten checks.

```text
CUSTOMER_ID_NOT_NULL
CUSTOMER_ID_UNIQUE

ACCOUNT_ID_NOT_NULL
ACCOUNT_ID_UNIQUE

BALANCE_NOT_NULL
BALANCE_NON_NEGATIVE

TRANSACTION_ID_UNIQUE
AMOUNT_NOT_NULL

APPLICATION_ID_UNIQUE
LOAN_AMOUNT_NOT_NULL
```

Each rule derives a failed-record count.

The basic evaluation pattern is:

```text
Rule
  |
  v
Count violating records
  |
  +---- 0 ------> PASS
  |
  +---- >0 -----> FAIL
```

---

# 16. DQ Rule Categories

The implemented rules cover several common enterprise DQ dimensions.

### Completeness

Examples:

- customer ID not NULL
- account ID not NULL
- balance not NULL
- transaction amount not NULL
- loan amount not NULL

### Uniqueness

Examples:

- customer ID unique
- account ID unique
- transaction ID unique
- application ID unique

### Business validity

Example:

```text
BALANCE >= 0
```

These categories can be extended as additional enterprise rules are introduced.

---

# 17. Controlled Defect Injection

The project intentionally creates known quality failures.

Implemented examples include:

```text
Negative account balance
Duplicate transaction ID
NULL transaction amount
NULL loan amount
```

The purpose is not to create realistic production incidents. The purpose is to create deterministic test conditions.

This makes it possible to validate:

```text
Expected defect
      |
      v
DQ rule
      |
      v
Failed record
      |
      v
Verification query
```

---

# 18. DQ Verification

The verification script checks the injected conditions.

Examples include:

- count negative balances
- count duplicate transaction identifiers
- count NULL transaction amounts
- count NULL loan amounts
- inspect specific injected records

This establishes record-level evidence that the test defects exist.

---

# 19. Streamlit Data Quality Layer

The Streamlit application embeds queries for six primary DQ checks:

```text
CUSTOMER_ID_NOT_NULL
BALANCE_NON_NEGATIVE
TRANSACTION_ID_UNIQUE
AMOUNT_NOT_NULL
APPLICATION_ID_UNIQUE
LOAN_AMOUNT_NOT_NULL
```

The application calculates:

- failed-record count
- PASS/FAIL status

The dashboard therefore provides an operational presentation layer over selected DQ rules.

Important implementation boundary:

> The SQL framework contains ten rules, while the Streamlit dashboard currently surfaces six primary checks.

---

# 20. Data Landscape Metrics

The Streamlit application counts records from five banking tables:

- CUSTOMERS
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS
- BRANCHES

The application displays the table counts and total records as part of the platform overview.

This provides basic data-landscape visibility alongside DQ monitoring.

---

# 21. Streamlit Application Structure

The application uses a wide Streamlit layout and includes:

```text
Platform Overview
      |
      +-- Solution Overview
      |
      +-- Platform KPIs
      |
      +-- Banking Data Landscape
      |
      +-- DQ Monitoring
      |
      +-- Solution Details
      |
      +-- Cortex Analyst
      |
      +-- AI Evaluation
```

The UI also uses custom styling, metrics, containers, tabs, expanders, inputs, buttons, and DataFrame rendering.

---

# 22. Cortex Analyst UI

The Cortex Analyst tab allows a user to:

1. enter a banking question
2. submit the question
3. call Cortex Analyst
4. display a success/failure state
5. display the generated SQL
6. display the query result

The key user experience is:

```text
ASK
 ↓
GENERATE
 ↓
INSPECT SQL
 ↓
VIEW RESULT
```

This is more transparent than returning only a natural-language answer.

---

# 23. AI Evaluation UI

The AI Evaluation tab provides predefined evaluation questions.

The evaluation process:

```text
Select evaluation
       |
       v
Run Cortex Analyst
       |
       v
Capture result
       |
       v
Normalize result
       |
       v
Compare with expected result
       |
       v
PASS / FAIL
```

The implementation includes predefined expected outputs for the evaluation scenarios.

---

# 24. Result Normalization

The evaluation logic normalizes result fields before comparing actual and expected values.

This matters because AI-generated SQL may return equivalent information with differences in:

- field naming
- representation
- result ordering

The comparison therefore attempts to evaluate the business result rather than relying only on a raw textual comparison.

---

# 25. Governance Architecture

The governance implementation is contained in:

```text
07_governance.sql
08_governance_tests.sql
```

The governance layer creates:

```text
BANKING_DQ_DB.GOVERNANCE
```

and custom roles:

```text
BANKING_DATA_STEWARD
BANKING_ANALYST
```

---

# 26. Role-Based Access

The implementation grants database/schema/table access to the analyst role.

This demonstrates the basic Snowflake RBAC pattern:

```text
User
  |
  v
Role
  |
  v
Database privileges
  |
  v
Schema privileges
  |
  v
Table privileges
```

The data steward role provides a higher-trust governance path.

---

# 27. Masking Policy

The implementation creates:

```text
CUSTOMER_LAST_NAME_MASK
```

and applies it to:

```text
CUSTOMERS.LAST_NAME
```

The policy distinguishes privileged roles from other users.

Expected behavior:

```text
BANKING_DATA_STEWARD
        |
        +--> actual LAST_NAME

BANKING_ANALYST
        |
        +--> masked LAST_NAME
```

This demonstrates column-level data protection.

---

# 28. Row Access Policy

The implementation creates:

```text
CUSTOMER_ROW_ACCESS
```

on:

```text
CUSTOMERS(STATE)
```

The current policy permits the defined analyst role to access customer rows.

Therefore, the implementation should not be described as active state-based regional filtering.

Instead:

> A row-access policy mechanism is implemented and tested, and the current configuration provides a foundation for future regional/business-unit restrictions.

---

# 29. Governance Testing

The governance test script explicitly changes roles and queries customer information.

The test validates the masking behavior for:

- `BANKING_ANALYST`
- `BANKING_DATA_STEWARD`

This is an example of a security regression test:

```text
Policy Definition
       |
       v
Role Assignment
       |
       v
Query Under Role
       |
       v
Expected Visibility
       |
       v
PASS / FAIL
```

---

# 30. Cortex Code / CoCo Engineering Path

The CoCo implementation should be considered a separate engineering surface.

Its role is:

```text
AI-assisted Snowflake engineering
```

rather than:

```text
User-facing analytics
```

The workflow can be represented as:

```text
Data Question
     |
     v
Inspect Snowflake objects
     |
     v
Profile data
     |
     v
Identify quality dimensions
     |
     v
Develop SQL rules
     |
     v
Create controlled defects
     |
     v
Execute validation
     |
     v
Inspect evidence
```

The `coco_data_quality/` screenshots provide visual evidence of this workflow.

---

# 31. Why Both Implementations Matter

The two paths demonstrate different engineering skills.

### Streamlit path

Demonstrates:

- application development
- user experience
- Cortex Analyst integration
- API integration
- result presentation
- DQ monitoring
- AI evaluation

### CoCo path

Demonstrates:

- AI-assisted engineering
- Snowflake exploration
- DQ engineering
- iterative SQL development
- testing
- defect investigation
- validation

Together:

```text
CoCo
  |
  | Build / Investigate / Validate
  v
Snowflake Engineering Layer
  |
  v
Streamlit
  |
  | Present / Monitor / Evaluate
  v
Business User
```

---

# 32. Source-Control Structure

The SQL implementation is separated into numbered stages:

```text
01_semantic_layer.sql
02_verified_queries.sql
03_dq_profiling.sql
04_dq_rules.sql
05_inject_dq_issues.sql
06_verify_dq_issues.sql
07_governance.sql
08_governance_tests.sql
```

The numbering communicates an intended engineering sequence:

```text
Semantic foundation
      ↓
Verified analytics
      ↓
Profiling
      ↓
Rules
      ↓
Controlled failures
      ↓
Verification
      ↓
Governance
      ↓
Governance testing
```

This also makes the repository easier to navigate for an interviewer.

---

# 33. YAML / Configuration Artifacts

The repository contains declarative project artifacts alongside SQL.

These artifacts support:

- semantic model definition
- target object configuration
- version-controlled project structure

Keeping both SQL and declarative artifacts allows the implementation to demonstrate more than ad-hoc worksheet development.

---

# 34. Error Handling and Operational Boundaries

The Streamlit Cortex Analyst helper includes basic operational safeguards.

The application:

- validates the HTTP response
- checks for successful response status
- applies a request timeout
- extracts expected response components
- surfaces errors through the application

This is a lightweight application-level reliability layer.

It is not equivalent to a full production observability platform.

---

# 35. Enterprise Engineering Skills Demonstrated

## Snowflake

- Database and schema design
- SQL
- Tables
- Semantic Views
- Semantic dimensions
- Semantic facts
- Semantic metrics
- Semantic relationships
- Verified queries
- Snowpark session
- Snowflake-native Streamlit
- Cortex Analyst
- Cortex Code / CoCo
- RBAC
- Masking policies
- Row access policies

## Data Engineering

- Data profiling
- Completeness
- Uniqueness
- Validity
- Record-level DQ
- Controlled defect injection
- DQ verification
- Business metrics
- Relational modeling

## AI Engineering

- Natural-language analytics
- Semantic grounding
- AI-generated SQL
- AI result validation
- Expected-vs-actual evaluation
- AI-assisted engineering
- Regression-oriented evaluation

## Application Engineering

- Python
- Streamlit
- Pandas
- Snowpark
- REST API
- JSON
- HTTP status handling
- Authentication/session-token usage
- UI state
- DataFrames

## Security

- RBAC
- Custom roles
- Privilege grants
- Column masking
- Row access policies
- Role-based security testing

## Software Engineering

- Git
- GitHub
- Version-controlled SQL
- YAML
- Modular scripts
- Test scripts
- Documentation
- Reproducibility

---

# 36. Enterprise Concepts Not Claimed as Implemented

The platform provides a foundation for capabilities such as:

- automated DQ orchestration
- DQ history and trend analysis
- alerting
- CI/CD pipelines
- broader AI regression suites
- AI observability
- cost monitoring
- latency monitoring
- prompt/version governance
- audit logging
- automated remediation
- production deployment controls

These should remain clearly labeled as **production extensions** unless implemented in the repository.

---

# 37. Architecture Decision Summary

| Decision | Implementation rationale |
|---|---|
| Semantic View | Gives Cortex Analyst a governed business abstraction |
| Verified queries | Establish known analytical examples |
| SQL DQ rules | Simple, transparent, executable validation |
| Controlled issue injection | Deterministic DQ testing |
| Separate verification script | Makes defects independently observable |
| Streamlit | Provides a practical user-facing Snowflake application |
| Generated SQL display | Improves transparency/debugging |
| Expected-vs-actual AI evaluation | Provides repeatable analytical validation |
| RBAC | Establishes controlled data access |
| Masking policy | Protects sensitive column values |
| Row access policy | Provides a framework for row-level restrictions |
| Git/GitHub | Supports version control and reproducibility |
| CoCo workflow | Demonstrates AI-assisted engineering separately from user-facing application |

---

# 38. End-to-End Technical Flow

The complete platform can be summarized as:

```text
                    BANKING DATA
                         |
                         v
                  Snowflake RAW
                         |
             +-----------+-----------+
             |                       |
             v                       v
       Semantic View            DQ Engineering
             |                       |
             v                 Profile → Rules
       Cortex Analyst                 |
             |                 Issue Injection
             v                       |
       Generated SQL           Verification
             |                       |
             +-----------+-----------+
                         |
                         v
                   AI Evaluation
                         |
                         v
                    Streamlit
                         |
              +----------+----------+
              |                     |
          Business User        Engineering User
              |                     |
          Analytics             CoCo / DQ
```

---

# 39. Technical Interview Summary

A strong technical explanation is:

> **“The platform is built around a Snowflake semantic abstraction that exposes banking tables, relationships, dimensions, facts, and reusable metrics to Cortex Analyst. The Streamlit application sends natural-language questions to Cortex Analyst, exposes the generated SQL, and presents the executed results. In parallel, I built a SQL-based data-quality framework covering profiling, completeness, uniqueness, and business validity, with controlled defect injection and verification. I also implemented Snowflake RBAC, masking, and row-access policies with role-based tests. Separately, the CoCo workflow demonstrates AI-assisted DQ engineering and validation. The result is a platform where semantic correctness, data quality, governance, AI evaluation, and user experience are treated as connected engineering concerns.”**

---

# 40. Core Engineering Principle

The central architecture principle is:

```text
                 TRUSTWORTHY AI ANALYTICS
                           |
        +------------------+------------------+
        |                  |                  |
   Semantic Quality    Data Quality       Governance
        |                  |                  |
   Correct meaning      Reliable data      Controlled access
        |                  |                  |
        +------------------+------------------+
                           |
                      AI Evaluation
                           |
                           v
                    User Experience
```

The project therefore demonstrates that building an enterprise AI analytics capability is not only about calling an AI model. It requires a combination of:

**semantic modeling + data quality + governance + evaluation + application engineering + reproducible implementation.**
