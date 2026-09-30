# 01 — Project Overview and Engineering Journey

## Enterprise Banking AI Platform on Snowflake

> **Purpose:** Document the implemented architecture, engineering journey, technical skills, evidence, and the relationship between the Streamlit application and the separately implemented Cortex Code (CoCo) data-quality workflow.

---

## 1. Executive Summary

This project demonstrates an enterprise-style **banking analytics, data-quality, governance, and AI evaluation platform built on Snowflake**.

The implementation combines:

- **Snowflake** as the data and compute platform
- **Snowflake Semantic Views** as the business/semantic abstraction layer
- **Cortex Analyst** for natural-language analytical questions
- **Cortex Code (CoCo)** for AI-assisted Snowflake/data-quality engineering
- **Streamlit** for the user-facing application
- **SQL-based data-quality profiling and rules**
- **Controlled data-quality issue injection and verification**
- **AI evaluation using predefined business questions and expected results**
- **Snowflake RBAC**
- **Masking policies**
- **Row access policies**
- **Git/GitHub-based version control**
- **Cortex project and semantic-view configuration artifacts**

The project intentionally demonstrates **two complementary implementation experiences**:

```text
                    ENTERPRISE BANKING AI PLATFORM
                                 |
                 +---------------+---------------+
                 |                               |
          USER-FACING EXPERIENCE          ENGINEERING EXPERIENCE
                 |                               |
            Streamlit App                   Cortex Code / CoCo
                 |                               |
       +---------+---------+             +-------+-------+
       |         |         |             |       |       |
   Cortex     DQ        AI Eval       Profile  Rules  Validate
   Analyst   Monitor       |             |       |       |
       |         |         |             +-------+-------+
       +---------+---------+                     |
                 |                               |
                 +---------------+---------------+
                                 |
                           Snowflake Platform
```

### Evidence folders

- **`screenshots/`** — user-facing platform/application evidence: overview, Cortex Analyst, DQ monitoring, AI evaluation and related outputs.
- **`coco_data_quality/`** — separate Cortex Code / CoCo data-quality engineering evidence: profiling, rule development, issue testing and validation.

These folders should **not** be described as duplicate screenshot collections. They represent two different engineering perspectives around the same Snowflake foundation.

---

# 2. Business and Engineering Problem

The platform addresses two connected enterprise problems.

### Problem A — Governed natural-language analytics

Business users should be able to ask questions such as:

> **What is the total balance by account type?**

without needing to understand physical table structures, joins, SQL syntax, or aggregation logic.

The solution uses a **Snowflake Semantic View + Cortex Analyst** to provide a governed business vocabulary for AI-generated analytics.

### Problem B — AI analytics depend on data quality

Even when AI-generated SQL is syntactically valid, the result can be unreliable when the underlying data contains defects such as:

- NULL business identifiers
- duplicate identifiers
- invalid numeric values
- missing transaction amounts
- incomplete loan information
- other data-quality failures

The project therefore includes a **Data Quality Engineering layer** and a lightweight **AI evaluation layer**.

---

# 3. Project Objectives

The implementation was designed to demonstrate that an enterprise AI analytics workflow needs more than an LLM interface.

The objectives are to:

1. Build a governed banking data model in Snowflake.
2. Create a reusable semantic abstraction over the physical data.
3. Enable natural-language analytics with Cortex Analyst.
4. Make generated SQL visible for inspection.
5. Profile source data before applying quality controls.
6. Define repeatable DQ rules.
7. Introduce controlled synthetic defects to test detection.
8. Verify that DQ rules identify known defects.
9. Expose DQ status through Streamlit.
10. Evaluate AI-generated analytical answers against expected results.
11. Implement Snowflake-native governance controls.
12. Test governance behavior under different roles.
13. Maintain SQL/configuration in version control.
14. Demonstrate AI-assisted data-quality engineering with Cortex Code.
15. Clearly distinguish **implemented functionality** from **production extensions**.

---

# 4. High-Level Architecture

```text
                              USERS
                                |
                                v
                     +----------------------+
                     |     Streamlit App    |
                     +----------+-----------+
                                |
                  +-------------+-------------+
                  |                           |
                  v                           v
           Cortex Analyst              DQ / AI Evaluation
                  |                           |
                  v                           |
        Semantic View                     Snowflake
                  |                           |
                  +-------------+-------------+
                                |
                                v
                         Snowflake RAW
                                |
             +------------------+------------------+
             |         |          |        |        |
        CUSTOMERS  ACCOUNTS  TRANSACTIONS  LOANS  BRANCHES
```

The engineering workflow is complementary:

```text
                 Cortex Code / CoCo
                         |
                         v
                 Data Exploration
                         |
                         v
                     Profiling
                         |
                         v
                   Rule Design
                         |
                         v
               Rule Implementation
                         |
                         v
             Controlled Issue Injection
                         |
                         v
                    Verification
                         |
                         v
                 Evidence / Results
```

---

# 5. Snowflake Data Foundation

The project uses a banking-oriented source model containing five core entities.

| Table | Purpose |
|---|---|
| `CUSTOMERS` | Customer-level information |
| `ACCOUNTS` | Account-level information and balances |
| `TRANSACTIONS` | Account transaction activity |
| `LOAN_APPLICATIONS` | Loan applications and amounts |
| `BRANCHES` | Branch metadata |

The semantic model exposes these physical structures as business-oriented concepts.

---

# 6. Banking Data Model

## CUSTOMERS

Representative attributes include:

- `CUSTOMER_ID`
- customer name attributes
- city
- state

## ACCOUNTS

Representative attributes include:

- `ACCOUNT_ID`
- customer relationship
- branch relationship
- account type
- account status
- `BALANCE`

## TRANSACTIONS

Representative attributes include:

- `TRANSACTION_ID`
- account relationship
- transaction type
- transaction status
- `AMOUNT`

## LOAN_APPLICATIONS

Representative attributes include:

- `APPLICATION_ID`
- customer relationship
- loan type
- application status
- `LOAN_AMOUNT`

## BRANCHES

Representative attributes include:

- `BRANCH_ID`
- branch name
- city

---

# 7. Semantic Layer

The central semantic object is:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

The semantic view provides a governed abstraction between business questions and physical Snowflake structures.

## Tables

- ACCOUNTS
- BRANCHES
- CUSTOMERS
- LOAN_APPLICATIONS
- TRANSACTIONS

## Relationships

- `ACCOUNTS_TO_BRANCHES`
- `ACCOUNTS_TO_CUSTOMERS`
- `LOANS_TO_CUSTOMERS`
- `TRANSACTIONS_TO_ACCOUNTS`

## Facts

- `BALANCE`
- `AMOUNT`
- `LOAN_AMOUNT`

## Dimensions

The model includes business-facing dimensions such as:

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

## Metrics

- `TOTAL_BALANCE`
- `AVERAGE_BALANCE`
- `ACCOUNT_COUNT`
- `TOTAL_TRANSACTION_AMOUNT`
- `TRANSACTION_COUNT`
- `TOTAL_LOAN_AMOUNT`
- `LOAN_APPLICATION_COUNT`

This demonstrates practical **semantic modeling** rather than simply exposing raw tables to an LLM.

---

# 8. Semantic-Model AI Guidance

The semantic implementation includes guidance intended to constrain analytical generation.

The guidance emphasizes:

- use defined semantic dimensions and metrics
- prefer semantic metrics
- use logical/business-facing names
- calculate and order ranking questions correctly
- do not invent tables
- do not invent columns
- do not invent dimensions
- do not invent facts
- do not invent metrics

The resulting pattern is:

```text
Physical Data Model
        |
        v
Semantic Contract
        |
        v
Natural-Language Question
        |
        v
Cortex Analyst
        |
        v
Generated SQL
```

The semantic layer therefore acts as a **business and AI abstraction boundary**.

---

# 9. Cortex Analyst

The implemented natural-language analytics path is:

```text
Business Question
       |
       v
Streamlit
       |
       v
Cortex Analyst API
       |
       v
Semantic View
       |
       v
Generated SQL
       |
       v
Snowflake Execution
       |
       v
Analytical Result
       |
       v
Streamlit
```

The Streamlit application specifies:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

as the semantic view used by Cortex Analyst.

The UI exposes:

1. Analyst response
2. Generated SQL
3. Query result

This creates a transparent chain from **business question → generated SQL → executed result**.

---

# 10. Example Cortex Analyst Output

A demonstrated question is:

> **What is the total balance by account type?**

The output is:

| ACCOUNT_TYPE | TOTAL_BALANCE |
|---|---:|
| CHECKING | 10,200 |
| SAVINGS | 21,200 |

The application also displays the generated SQL.

This is important for enterprise AI because the user can inspect the analytical path instead of receiving only an unexplained final number.

---

# 11. Verified Queries

The project includes a verified-query mechanism associated with the semantic model.

A representative verified question is:

> **What is the total balance and number of accounts by account type?**

The query groups by account type and evaluates:

- total balance
- account count

Verified questions provide a starting point for **semantic regression examples** and known analytical behavior.

---

# 12. Data Quality Engineering Lifecycle

The DQ implementation is intentionally separated into stages:

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

This separation supports maintainability and makes each stage independently inspectable.

---

# 13. Data Quality Profiling

`03_dq_profiling.sql` establishes basic data characteristics before applying quality rules.

The implementation checks:

- row counts
- NULL identifiers
- distinct identifier counts
- potential uniqueness problems

The current profiling script covers:

- CUSTOMERS
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS

The script does not currently profile BRANCHES in the same way.

This baseline profiling stage helps determine whether downstream DQ controls are detecting meaningful conditions.

---

# 14. Implemented DQ Rules

`04_dq_rules.sql` defines ten rules:

| Rule | Validation |
|---|---|
| `CUSTOMER_ID_NOT_NULL` | Customer ID must not be NULL |
| `CUSTOMER_ID_UNIQUE` | Customer ID must be unique |
| `ACCOUNT_ID_NOT_NULL` | Account ID must not be NULL |
| `ACCOUNT_ID_UNIQUE` | Account ID must be unique |
| `BALANCE_NOT_NULL` | Balance must not be NULL |
| `BALANCE_NON_NEGATIVE` | Balance must not be negative |
| `TRANSACTION_ID_UNIQUE` | Transaction ID must be unique |
| `AMOUNT_NOT_NULL` | Transaction amount must not be NULL |
| `APPLICATION_ID_UNIQUE` | Application ID must be unique |
| `LOAN_AMOUNT_NOT_NULL` | Loan amount must not be NULL |

The rules return failed-record counts and derive a **PASS/FAIL** status.

---

# 15. SQL Rule Framework vs. Streamlit Dashboard

The repository contains an important distinction:

> **The SQL DQ framework defines 10 rules, while the Streamlit dashboard currently surfaces six primary checks.**

The six primary Streamlit checks are:

- `CUSTOMER_ID_NOT_NULL`
- `BALANCE_NON_NEGATIVE`
- `TRANSACTION_ID_UNIQUE`
- `AMOUNT_NOT_NULL`
- `APPLICATION_ID_UNIQUE`
- `LOAN_AMOUNT_NOT_NULL`

This distinction should remain explicit in future documentation so the README does not incorrectly state that the dashboard displays all ten rules.

---

# 16. Controlled Data-Quality Issue Injection

`05_inject_dq_issues.sql` intentionally introduces synthetic defects for testing.

Examples include:

### Negative balance

A test account is inserted with:

```text
BALANCE = -500
```

### Duplicate transaction ID

A duplicate transaction identifier is introduced.

### NULL transaction amount

A transaction is introduced with:

```text
AMOUNT = NULL
```

### NULL loan amount

A loan application is introduced with:

```text
LOAN_AMOUNT = NULL
```

These are **controlled test defects** and should not be described as real banking-data incidents.

---

# 17. DQ Verification

`06_verify_dq_issues.sql` verifies the controlled defects.

The verification includes:

- negative-balance counts
- duplicate transaction-ID counts
- NULL transaction-amount counts
- NULL loan-amount counts
- inspection of injected records

The validation pattern is:

```text
Known Defect
     |
     v
Inject
     |
     v
Execute DQ Rule
     |
     v
Failed Record Count
     |
     v
Record-Level Verification
```

This is stronger evidence than showing only a clean PASS state because the framework is deliberately exercised against known failures.

---

# 18. Cortex Code / CoCo Data-Quality Implementation

The `coco_data_quality/` area represents a **separate Cortex Code / CoCo engineering workflow**.

It should be documented as an **AI-assisted engineering path**, not as another copy of the Streamlit screenshots.

The workflow is conceptually:

```text
Explore
  |
  v
Profile
  |
  v
Identify DQ dimensions
  |
  v
Develop DQ rules
  |
  v
Test against controlled defects
  |
  v
Inspect results
  |
  v
Iterate / Validate
```

This demonstrates practical use of an AI coding/engineering assistant for Snowflake work while the SQL files remain the implementation source of truth.

---

# 19. Two Complementary Implementation Experiences

## A. `screenshots/` — Application Experience

Use these screenshots to demonstrate:

- platform overview
- semantic-layer status
- banking data landscape
- Cortex Analyst
- generated SQL
- query results
- DQ monitoring
- AI evaluation

This answers:

> **How does an end user interact with the platform?**

## B. `coco_data_quality/` — Engineering Experience

Use these artifacts to demonstrate:

- data inspection
- profiling
- DQ development
- rule testing
- controlled issue investigation
- validation
- AI-assisted Snowflake engineering

This answers:

> **How does an engineer build and validate the data-quality capability?**

Together:

```text
                    SAME SNOWFLAKE FOUNDATION
                              |
              +---------------+---------------+
              |                               |
        ENGINEERING PATH                 USER PATH
              |                               |
         Cortex Code                     Streamlit
              |                               |
       Build / Test / Validate         Consume / Monitor / Evaluate
              |                               |
              +---------------+---------------+
                              |
                     Enterprise Platform
```

---

# 20. AI Evaluation

The Streamlit application includes an AI evaluation interface.

The evaluation path is:

```text
Evaluation Question
        |
        v
Cortex Analyst
        |
        v
Generated SQL
        |
        v
Actual Result
        |
        v
Normalize Result
        |
        v
Compare With Expected
        |
        v
PASS / FAIL
```

Current evaluation scenarios include questions involving:

- total balance by account type
- average balance by account type
- loan applications by status

The application compares actual results with predefined expected results.

---

# 21. AI Evaluation Scope

The current implementation is a **lightweight accuracy/regression-oriented evaluation**, not a complete LLM evaluation platform.

It provides a foundation for:

- result accuracy
- semantic coverage
- regression testing

Potential future evaluation dimensions include:

- SQL correctness
- semantic correctness
- groundedness
- hallucination
- ambiguous-question handling
- unsupported-question handling
- safety
- latency
- cost
- multi-turn reliability
- broader regression coverage

These should be described as **future evaluation expansion**, not current implementation.

---

# 22. Governance and Security

The governance implementation creates:

```text
BANKING_DQ_DB.GOVERNANCE
```

and custom roles including:

```text
BANKING_DATA_STEWARD
BANKING_ANALYST
```

The implementation demonstrates Snowflake-native access control rather than application-only security.

---

# 23. Masking Policy

The masking policy:

```text
CUSTOMER_LAST_NAME_MASK
```

is applied to:

```text
BANKING_DQ_DB.RAW.CUSTOMERS.LAST_NAME
```

Privileged roles can see the actual last name while other access paths receive:

```text
***MASKED***
```

This demonstrates **column-level data protection through Snowflake masking policies**.

---

# 24. Row Access Policy

The row access policy:

```text
CUSTOMER_ROW_ACCESS
```

is applied to:

```text
CUSTOMERS(STATE)
```

The current implementation provides the policy framework and role conditions, but the defined analyst access currently allows the analyst role to see the customer rows.

Therefore the correct description is:

> **A row-access-policy framework is implemented and tested; regional/state-level filtering is a future extension rather than an active restriction in the current implementation.**

---

# 25. Governance Testing

`08_governance_tests.sql` explicitly tests role behavior.

The test queries:

- CUSTOMER_ID
- FIRST_NAME
- LAST_NAME
- STATE

The intended role behavior is:

```text
BANKING_ANALYST
       |
       v
LAST_NAME masked

BANKING_DATA_STEWARD
       |
       v
LAST_NAME visible
```

The tests therefore validate that the policy is not merely defined but exercised under different roles.

---

# 26. Streamlit Application Engineering

The application is implemented in Python using:

- **Streamlit**
- **Pandas**
- **Snowpark**
- **Requests**

The Snowflake-native session is obtained through:

```python
get_active_session()
```

The Cortex Analyst integration uses the active Snowflake session and session token to call the Cortex Analyst endpoint.

The implementation includes:

- HTTP status validation
- request timeout handling
- response parsing
- generated-SQL extraction
- result presentation
- error handling

The application also uses the Snowflake host/session information rather than requiring a separate static database credential in the UI workflow.

---

# 27. Streamlit User Experience

The application includes several functional areas.

### Platform overview

Displays:

- semantic-layer status
- number of source tables
- DQ pass/fail counts
- banking data landscape

### Cortex Analyst

Provides:

- natural-language question input
- Analyst response
- generated SQL
- query result

### AI Evaluation

Provides:

- evaluation question
- expected-result comparison
- evaluation status

### DQ Monitoring

Displays selected DQ rules and failed-record counts.

---

# 28. Version Control and Reproducibility

The implementation uses Git/GitHub for source control.

Key SQL artifacts include:

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

Additional repository artifacts include:

- semantic-view YAML
- Cortex project YAML
- Streamlit application code
- documentation
- screenshots

This supports:

- change tracking
- reproducibility
- code review
- separation of implementation and validation
- historical comparison

---

# 29. Technical Skills Demonstrated

## Snowflake

- Snowflake SQL
- databases
- schemas
- tables
- roles
- grants
- Semantic Views
- semantic dimensions
- semantic facts
- semantic metrics
- semantic relationships
- verified queries
- Snowpark session
- Snowflake-native Streamlit
- Cortex Analyst
- Cortex Code / CoCo
- masking policies
- row access policies
- policy inspection and testing

## Data Engineering

- data profiling
- NULL analysis
- uniqueness analysis
- completeness checks
- validity checks
- record-level validation
- controlled test-data injection
- DQ rule execution
- DQ verification
- SQL-based testing
- relational modeling
- relationship-aware semantic design

## AI Engineering

- natural-language analytics
- semantic grounding
- Cortex Analyst
- generated SQL inspection
- AI evaluation
- expected-vs-actual comparison
- regression-oriented evaluation
- AI-assisted engineering with CoCo

## Application Engineering

- Python
- Streamlit
- Pandas
- Snowpark
- REST API integration
- JSON request/response handling
- HTTP status/error handling
- session-token authentication
- UI state and interaction
- DataFrame presentation

## Security / Governance

- Snowflake RBAC
- custom roles
- privilege grants
- column masking
- row access policies
- role-based testing
- data-access controls

## Software Engineering

- Git
- GitHub
- SQL version control
- YAML configuration
- documentation
- reproducibility
- test artifacts
- separation of implementation and validation

---

# 30. Enterprise Engineering Principles Demonstrated

### Separation of concerns

```text
Data
  |
  v
Semantic Model
  |
  v
AI Analytics
  |
  v
Data Quality
  |
  v
Evaluation
  |
  v
Application
  |
  v
Governance
```

### Transparency

Generated SQL is exposed rather than hidden.

### Testability

Known defects are intentionally injected and verified.

### Governance

RBAC, masking, and row-access policies are implemented and tested.

### Reproducibility

SQL and configuration are maintained in version control.

### Controlled experimentation

Synthetic DQ defects provide deterministic testing conditions.

### Evidence-driven AI

AI-generated analytical outputs are compared against expected results.

### Business semantics

The semantic model provides business-oriented dimensions and metrics rather than exposing only physical storage structures.

---

# 31. Implemented vs. Production Extension

This distinction should remain explicit throughout the repository.

## Implemented

- Snowflake banking data model
- Semantic View
- Cortex Analyst
- Verified-query capability
- DQ profiling
- 10 SQL DQ rules
- six primary Streamlit DQ checks
- controlled DQ issue injection
- DQ verification
- Streamlit application
- AI evaluation workflow
- Snowflake RBAC
- masking policy
- row access policy
- governance tests
- Cortex Code / CoCo DQ workflow
- Git/GitHub version control

## Production Extensions

Potential enterprise extensions include:

- automated DQ orchestration
- historical DQ trend storage
- alerting
- CI/CD
- expanded semantic-model testing
- larger AI regression suites
- AI observability
- model/prompt governance
- audit logging
- remediation workflows
- cost and latency monitoring
- data contracts
- incident-management integration

These should not be presented as implemented unless corresponding code/evidence is added to the repository.

---

# 32. Recommended Enterprise Evolution

```text
                    ENTERPRISE AI DATA PLATFORM
                              |
        +---------------------+---------------------+
        |                     |                     |
   DATA PLATFORM         SEMANTIC / AI         GOVERNANCE
        |                     |                     |
   Snowflake             Semantic View          RBAC
   Data Layers           Cortex Analyst         Masking
   Data Contracts        Verified Queries       Row Access
        |                     |                     |
        +---------------------+---------------------+
                              |
                        DATA QUALITY
                              |
               +--------------+--------------+
               |              |              |
            Profiling       Rules       DQ History
               |              |              |
               +--------------+--------------+
                              |
                       AI EVALUATION
                              |
        +---------------------+---------------------+
        |                     |                     |
    SQL Accuracy         Result Accuracy      Groundedness
        |                     |                     |
        +---------------------+---------------------+
                              |
                       OBSERVABILITY
                              |
                    Metrics / Logs / Alerts
                              |
                         APPLICATION
                              |
                         Streamlit
```

The current project provides several foundational components for this evolution while deliberately keeping future capabilities separate.

---

# 33. Evidence Strategy for the Repository

Screenshots should be treated as **implementation evidence**, not decoration.

## `screenshots/`

Recommended usage:

- platform overview
- Cortex Analyst output
- generated SQL
- query results
- DQ monitoring
- AI evaluation

## `coco_data_quality/`

Recommended usage:

- Cortex Code workflow
- profiling
- DQ rule development
- issue injection/testing
- validation
- AI-assisted engineering steps

Each major screenshot should ideally be connected to:

```text
Screenshot
   |
   v
Source SQL / Python
   |
   v
Snowflake Object
   |
   v
Actual Output
```

This creates a much stronger portfolio narrative than a gallery of disconnected screenshots.

---

# 34. Engineering Journey

The project can be presented as a progression:

```text
1. Establish banking data foundation
                 |
                 v
2. Build semantic abstraction
                 |
                 v
3. Add natural-language analytics
                 |
                 v
4. Profile data quality
                 |
                 v
5. Define DQ rules
                 |
                 v
6. Inject controlled defects
                 |
                 v
7. Verify DQ detection
                 |
                 v
8. Add governance controls
                 |
                 v
9. Test governance behavior
                 |
                 v
10. Build Streamlit experience
                 |
                 v
11. Add AI evaluation
                 |
                 v
12. Develop separate CoCo DQ workflow
```

This progression demonstrates that the project spans **data modeling, semantic engineering, AI integration, data-quality engineering, governance, evaluation, and application development**.

---

# 35. Interview Positioning

A concise interview explanation is:

> **“I built an enterprise-style banking AI engineering platform on Snowflake with two complementary implementation paths. The Streamlit application demonstrates the user-facing experience — semantic analytics through Cortex Analyst, DQ monitoring, and AI evaluation. Separately, I used Cortex Code to develop and validate the data-quality engineering workflow through profiling, rule development, controlled issue injection, and verification. The platform also includes Snowflake semantic modeling, RBAC, masking, row-access policies, Git-based version control, and explicit AI evaluation. I kept the implementation evidence separate from future production extensions so the architecture reflects what is actually built.”**

---

# 36. Key Takeaway

The strongest positioning is not:

> “I built a Streamlit banking dashboard.”

It is:

> **“I built and validated an enterprise-style Snowflake AI engineering platform that connects semantic modeling, natural-language analytics, data-quality engineering, AI evaluation, governance, and an application layer — while demonstrating both AI-assisted engineering through Cortex Code and user-facing analytics through Streamlit.”**

The central engineering principle is:

> **AI capabilities are only useful when the semantic model, underlying data quality, evaluation process, governance controls, and user-facing evidence are designed together.**
