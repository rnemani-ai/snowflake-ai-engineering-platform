# Architecture and Implementation

## 1. Overview

The Enterprise Banking AI Platform is organized into four main layers:

```text
┌──────────────────────────────────────────────┐
│              Presentation Layer              │
│                  Streamlit                   │
└──────────────────────┬───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│                   AI Layer                   │
│              Cortex Analyst                 │
└──────────────────────┬───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│             Semantic / Quality Layer         │
│  Semantic View + DQ Rules + Evaluation       │
└──────────────────────┬───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│                  Data Layer                  │
│              Banking RAW Tables              │
└──────────────────────────────────────────────┘
```

The goal is to keep the responsibilities of each layer separate while allowing them to work together as one analytical platform.

## 2. Data Layer

The project uses a synthetic banking dataset stored in:

```text
BANKING_DQ_DB.RAW
```

The RAW schema contains:

- `BRANCHES`
- `CUSTOMERS`
- `ACCOUNTS`
- `TRANSACTIONS`
- `LOAN_APPLICATIONS`

The tables represent a simplified banking data model.

### Main Relationships

```text
CUSTOMERS
   │
   ├──────────────► ACCOUNTS
   │                    │
   │                    └──────────────► TRANSACTIONS
   │
   └──────────────► LOAN_APPLICATIONS

BRANCHES
   │
   └──────────────► ACCOUNTS
```

These relationships are represented in the semantic layer.

## 3. Semantic Layer

The semantic model is implemented as:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

The semantic view defines the business meaning of the underlying tables.

### Tables

- Branches
- Customers
- Accounts
- Transactions
- Loan Applications

### Relationships

- Accounts → Customers
- Accounts → Branches
- Transactions → Accounts
- Loan Applications → Customers

### Dimensions

Examples include:

- Branch name
- City
- Customer name
- Account type
- Account status
- Transaction type
- Transaction status
- Loan type
- Application status

### Facts

Examples include:

- Account balance
- Transaction amount
- Loan amount

### Metrics

Examples include:

- Total balance
- Average balance
- Account count
- Total transaction amount
- Transaction count
- Total loan amount
- Loan application count

The semantic layer allows business questions to be expressed using logical business concepts instead of requiring users to know the physical database structure.

## 4. Cortex Analyst Layer

The Streamlit application sends a natural-language question to Cortex Analyst using the banking semantic view.

The flow is:

```text
User Question
      │
      ▼
Streamlit
      │
      ▼
Cortex Analyst
      │
      ▼
Semantic View
      │
      ▼
Generated SQL
      │
      ▼
Snowflake Query
      │
      ▼
Query Result
      │
      ▼
Streamlit
```

For example:

```text
Question:
"What is the total balance by account type?"
```

Cortex Analyst generates analytical SQL using the semantic model rather than requiring the user to manually write SQL.

The application then displays:

1. The user question
2. The Analyst response
3. Generated SQL
4. Query result

This makes the AI workflow easier to inspect and debug.

## 5. Verified Queries

The semantic model also contains verified business questions.

A verified query provides a known question and a validated SQL query that represents the expected interpretation of that question.

This creates a useful foundation for:

- Consistent business questions
- Regression testing
- Analyst validation
- Evaluation of AI-generated SQL

The verified-query definitions are maintained in:

```text
cortex_project/02_verified_queries.sql
```

## 6. Data Quality Layer

The data-quality layer operates directly against the banking tables.

The workflow is:

```text
Banking Tables
      │
      ▼
Data Profiling
      │
      ▼
DQ Rules
      │
      ▼
Failed Record Counts
      │
      ▼
Streamlit Monitoring
```

Profiling is implemented in:

```text
03_dq_profiling.sql
```

Rules are implemented in:

```text
04_dq_rules.sql
```

Controlled test issues are introduced through:

```text
05_inject_dq_issues.sql
```

Validation is performed through:

```text
06_verify_dq_issues.sql
```

## 7. Streamlit Layer

The Streamlit application provides a single interface for the platform.

The main page provides:

- Solution overview
- Platform KPIs
- Banking data landscape
- Data-quality monitoring
- Architecture information

The application also provides two main analytical tabs:

### Cortex Analyst

Used for natural-language banking analytics.

### AI Evaluation

Used for predefined analytical test cases.

## 8. Application-to-Snowflake Access

The application uses Snowflake's active application session:

```python
from snowflake.snowpark.context import get_active_session

session = get_active_session()
```

This allows the Streamlit application running within Snowflake to access Snowflake resources without embedding database credentials in the application code.

For Cortex Analyst interaction, the application uses the Snowflake runtime authentication available to the application to call the Cortex Analyst API.

## 9. Design Principles

### Semantic Abstraction

Business users interact with business concepts rather than physical database structures.

### Transparency

The application exposes generated SQL rather than hiding the analytical query.

### Separation of Concerns

Data, semantic modeling, DQ rules, AI analytics, evaluation, and presentation are maintained separately.

### Testability

Expected analytical results are defined so that AI-generated results can be evaluated.

### Version Control

SQL, semantic definitions, application code, configuration, and documentation are maintained in GitHub.

## 10. Implementation Sequence

The project is organized in dependency order:

```text
01 Semantic Layer
        ↓
02 Verified Queries
        ↓
03 Data Profiling
        ↓
04 DQ Rules
        ↓
05 Inject Test Issues
        ↓
06 Verify DQ Issues
        ↓
Streamlit Application
        ↓
AI Evaluation
```

This makes the repository easier to understand and reproduce.

## 11. Enterprise Extension Opportunities

A production implementation could extend this architecture with:

- Role-based access control
- Automated DQ orchestration
- DQ history tables
- Alerting
- CI/CD
- Automated semantic-model testing
- AI regression testing
- Observability
- Model and prompt governance
- Audit logging
- Automated remediation workflows