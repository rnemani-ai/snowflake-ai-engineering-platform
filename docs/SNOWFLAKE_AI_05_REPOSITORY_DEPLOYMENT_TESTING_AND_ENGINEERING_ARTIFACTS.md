# 05 — Repository, Deployment, Testing & Engineering Artifacts

## 1. Purpose

This document explains how the Snowflake AI Engineering Platform is organized as an engineering repository rather than only as a demonstration application.

The focus is:
- source control
- SQL, YAML, and Python artifacts
- Streamlit configuration
- Cortex Code / CoCo artifacts
- testing and validation
- reproducibility
- screenshots/evidence
- implementation vs. production boundaries
- known repository inconsistencies to resolve before the final README

Guiding principle:

> **Every important capability should be traceable from repository artifact → Snowflake object → execution → observed result → evidence.**

---

## 2. Repository at a Glance

```text
snowflake-ai-engineering-platform/
│
├── 01_semantic_layer.sql
├── 02_verified_queries.sql
├── 03_dq_profiling.sql
├── 04_dq_rules.sql
├── 05_inject_dq_issues.sql
├── 06_verify_dq_issues.sql
├── 07_governance.sql
├── 08_governance_tests.sql
│
├── cortex_project/
├── streamlit/
│   ├── streamlit_app.py
│   ├── pyproject.toml
│   └── snowflake.yml
├── screenshots/
├── coco_data_quality/
├── docs/
└── README.md
```

The repository contains two complementary implementation experiences:

```text
                 SNOWFLAKE FOUNDATION
                        │
           ┌────────────┴────────────┐
           │                         │
    APPLICATION PATH          ENGINEERING PATH
           │                         │
       Streamlit                   CoCo
           │                         │
 Present / Evaluate         Build / Test / Validate
           │                         │
           └────────────┬────────────┘
                        │
                 AI Engineering
                   Platform
```

---

## 3. Two Engineering Surfaces

### Application experience — `streamlit/` + `screenshots/`

Demonstrates:
- semantic analytics
- Cortex Analyst
- generated SQL transparency
- query results
- DQ monitoring
- AI evaluation
- banking data landscape

Question answered:

> **What does the finished platform look like to an analyst or business user?**

### Engineering experience — `coco_data_quality/`

Demonstrates:
- data inspection
- profiling
- DQ rule design
- metadata-driven execution
- controlled issue injection
- validation
- anomaly detection
- troubleshooting
- AI-assisted Snowflake engineering

Question answered:

> **How was the data-quality capability engineered, tested, and investigated?**

These are complementary, not duplicate screenshot collections.

---

## 4. Source-Control Strategy

Git/GitHub stores:
- SQL definitions
- semantic-model artifacts
- Streamlit code
- Cortex project configuration
- CoCo-generated SQL
- governance policies
- validation scripts
- documentation
- screenshots/evidence

This supports:
- change tracking
- reproducibility
- code review
- separation of implementation and validation
- historical comparison

A useful validation pattern is:

```text
Implementation
     │
     v
Validation Script
     │
     v
Observed Result
     │
     v
Evidence
```

---

## 5. Core SQL Artifacts

The root SQL files have distinct responsibilities:

| File | Responsibility |
|---|---|
| `01_semantic_layer.sql` | Semantic view and semantic-model setup |
| `02_verified_queries.sql` | Verified-query / semantic-model configuration |
| `03_dq_profiling.sql` | Initial data profiling |
| `04_dq_rules.sql` | SQL-based DQ rule definitions |
| `05_inject_dq_issues.sql` | Controlled DQ defect injection |
| `06_verify_dq_issues.sql` | Verification of injected defects |
| `07_governance.sql` | Roles, masking, row-access controls |
| `08_governance_tests.sql` | Governance validation |

The files should be understood by responsibility. The repository currently contains overlapping semantic-view definitions, so the final README should not imply an unverified one-command deployment sequence.

---

## 6. Semantic-Layer Artifacts

The principal semantic object is:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

It models:

```text
CUSTOMERS
ACCOUNTS
TRANSACTIONS
LOAN_APPLICATIONS
BRANCHES
```

The semantic model contains:
- relationships
- dimensions
- facts
- metrics
- AI SQL-generation guidance
- verified-query capability

The repository also contains a declarative semantic YAML representation and Cortex project configuration.

Traceability:

```text
Semantic YAML
     │
     v
Cortex Project Configuration
     │
     v
Snowflake Semantic View
     │
     v
Cortex Analyst
     │
     v
Generated SQL
     │
     v
Query Result
```

---

## 7. Verified Queries

A representative verified question is:

> **What is the total balance and number of accounts by account type?**

Verified queries provide known analytical examples against which generated analytical behavior can be checked.

Important repository note:

Some existing documentation refers to:

```text
cortex_project/02_verified_queries.sql
```

while the repository also contains:

```text
02_verified_queries.sql
```

Before the final README is published, one canonical location should be selected or the distinction should be documented explicitly.

---

## 8. Data-Quality Artifacts

### Profiling

`03_dq_profiling.sql` examines:
- row counts
- null identifiers
- distinct identifiers
- potential uniqueness issues

### Rules

`04_dq_rules.sql` defines **10 SQL DQ rules**, including checks for:
- identifier non-nullability
- identifier uniqueness
- balance non-nullability
- non-negative balance
- transaction uniqueness
- transaction amount non-nullability
- loan-application uniqueness
- loan amount non-nullability

### Controlled defects

`05_inject_dq_issues.sql` intentionally introduces:
- negative account balance
- duplicate transaction ID
- NULL transaction amount
- NULL loan amount

These are synthetic test defects, not production banking data.

### Verification

`06_verify_dq_issues.sql` queries the injected records and verifies that the expected problems are observable.

---

## 9. Dashboard DQ Checks vs. SQL Rules

An important distinction:

- SQL DQ layer: **10 rules**
- Streamlit dashboard: **6 primary monitoring checks**

Recommended README wording:

> **“The SQL DQ layer defines 10 checks, while the Streamlit application surfaces six primary monitoring checks.”**

Do not claim the dashboard displays all 10 unless the application is changed.

---

## 10. Streamlit Application Artifacts

The user-facing application is under:

```text
streamlit/
```

Main file:

```text
streamlit/streamlit_app.py
```

Configuration/deployment files:

```text
streamlit/pyproject.toml
streamlit/snowflake.yml
```

Responsibilities:

| Artifact | Responsibility |
|---|---|
| `streamlit_app.py` | Application UI and logic |
| `pyproject.toml` | Python project/dependency configuration |
| `snowflake.yml` | Snowflake deployment/runtime configuration |

The application uses the active Snowflake session and calls the Cortex Analyst API.

---

## 11. Cortex Analyst Request Boundary

```text
User Question
     │
     v
Streamlit
     │
     v
Cortex Analyst API
     │
     v
Semantic View
     │
     v
Generated SQL
     │
     v
Snowflake
     │
     v
Result
     │
     v
Streamlit
```

The application exposes:
- Analyst response
- generated SQL
- query result

This provides transparency into the AI-generated analytical path.

---

## 12. AI Evaluation

The current application implements a lightweight expected-vs-actual evaluation flow:

```text
Evaluation Question
       │
       v
Cortex Analyst
       │
       v
Generated SQL
       │
       v
Actual Result
       │
       v
Result Normalization
       │
       v
Expected Result
       │
       v
PASS / FAIL
```

Current scenarios include:
1. total balance by account type
2. average balance by account type
3. loan applications by status

This should be described as a **lightweight regression-oriented evaluation**, not a complete production LLM evaluation framework.

---

## 13. Important Evaluation Mismatch

There is a known discrepancy that must be resolved before the final README is published.

Existing documentation states:

```text
CHECKING average balance = 3400
```

Current Streamlit evaluation code uses:

```text
CHECKING average balance = 2550
```

Therefore, neither value should be presented as the definitive final output until the source data and evaluation code are reconciled.

---

## 14. Governance Artifacts

Governance is implemented through:

```text
07_governance.sql
08_governance_tests.sql
```

Schema:

```text
BANKING_DQ_DB.GOVERNANCE
```

The implementation includes:
- custom roles
- column masking
- row access policy
- grants
- policy inspection
- role-based validation

The last-name masking policy demonstrates different visibility for different roles.

Important boundary:

> The current row-access policy should **not** be described as active regional/state filtering. The current analyst policy permits access to the defined rows; it is a framework for future restriction logic.

---

## 15. CoCo Engineering Artifacts

The separate `coco_data_quality/` workflow contains:

```text
coco_data_quality/
├── 00_setup/
├── 01_DQ_instructions/
├── Generated_files/
├── DQ_MONITORING_DASHBOARD/
└── docs/
```

Generated artifacts cover:
- data profiling
- proposed rules
- rule definitions
- framework configuration
- orchestration
- cleanup

The documented CoCo implementation uses a metadata-driven SQL rules engine with execution/result/anomaly metadata.

The engineering chain is:

```text
CoCo Instruction
      │
      v
Generated SQL
      │
      v
Metadata / Procedure
      │
      v
Execution
      │
      v
Results
      │
      v
Anomaly Detection
      │
      v
Dashboard
```

CoCo assisted implementation, but the engineer remained responsible for review, execution decisions, validation, and interpretation.

---

## 16. Testing Strategy

Testing occurs at multiple layers.

### Semantic / AI validation

Verified queries provide known analytical examples.

### DQ validation

Controlled defects are inserted and explicitly queried.

```text
Inject defect
     ↓
Run validation
     ↓
Observe failed condition
```

### Governance validation

```text
07_governance.sql
        ↓
08_governance_tests.sql
```

The tests exercise role-dependent masking/access behavior.

### AI evaluation

Generated analytical results are compared with expected results.

This layered approach is stronger than relying only on visual inspection.

---

## 17. Reproducibility

The intended traceability chain is:

```text
GitHub Repository
       │
       ├── SQL
       ├── YAML
       ├── Python
       ├── Documentation
       └── Evidence
              │
              v
       Snowflake Objects
              │
              v
       Execution
              │
              v
       Validation
              │
              v
       Observed Results
```

This does not mean the repository currently provides a fully automated production environment bootstrap. It is an engineering/portfolio implementation whose source artifacts make the design and validation inspectable.

---

## 18. Screenshot / Evidence Strategy

Screenshots are implementation evidence, not decoration.

### `screenshots/`

Use for the broader platform experience:
- platform overview
- Cortex Analyst
- generated SQL
- query results
- DQ monitoring
- AI evaluation

### `coco_data_quality/`

Use for:
- CoCo workflow
- profiling
- DQ rule design
- framework construction
- execution
- anomaly detection
- validation
- CoCo DQ dashboard

Recommended evidence chain:

```text
Screenshot
    │
    v
Source SQL / Python
    │
    v
Snowflake Object
    │
    v
Actual Output
```

---

## 19. Recommended Evidence Mapping

| Evidence | Source Artifact | Result |
|---|---|---|
| Platform overview | `streamlit_app.py` | Platform KPIs/data landscape |
| Cortex Analyst | `streamlit_app.py` + semantic view | Response + SQL |
| Semantic model | `01_semantic_layer.sql` + YAML | Semantic View |
| DQ monitoring | `04_dq_rules.sql` + app code | PASS/FAIL |
| Controlled DQ issue | `05_inject_dq_issues.sql` | Known defect |
| DQ verification | `06_verify_dq_issues.sql` | Detected defect |
| Governance | `07_governance.sql` | Policies/roles |
| Governance test | `08_governance_tests.sql` | Role-dependent result |
| AI evaluation | `streamlit_app.py` | Expected vs. actual |
| CoCo profiling | `DQ_data_profiling.sql` | Profiling output |
| CoCo framework | framework/orchestration SQL | Rule execution |
| CoCo anomaly detection | DQ framework results | Anomaly output |

---

## 20. Implemented vs. Production Extension

### Implemented / Demonstrated

- Snowflake banking data model
- semantic view
- semantic YAML / Cortex project artifacts
- Cortex Analyst integration
- generated SQL visibility
- verified-query capability
- SQL-based DQ rules
- controlled DQ defect injection
- DQ verification
- Streamlit application
- lightweight AI evaluation
- Snowflake RBAC
- masking policy
- row access policy
- governance tests
- Cortex Code / CoCo DQ engineering workflow
- Git/GitHub version control
- implementation evidence

### Production Extensions

Keep these explicitly labeled as future work:
- scheduled DQ execution
- alerting
- historical DQ trends
- CI/CD deployment automation
- expanded AI regression suites
- latency/cost observability
- model/prompt governance
- audit logging
- automated remediation
- incident-management integration
- production data contracts
- DEV → TEST → PROD promotion

---

## 21. Pre-README Cleanup Checklist

### Path consistency
Normalize references to `02_verified_queries.sql`.

### Semantic definitions
Clarify the relationship between `01_semantic_layer.sql` and `02_verified_queries.sql`.

### AI evaluation
Resolve **3400 vs. 2550** for the CHECKING average balance test.

### DQ counts
Keep **10 SQL rules** distinct from the **6 dashboard checks**.

### Governance wording
Do not describe the current analyst row-access policy as active regional filtering.

### CoCo dimensions
Use the actual rule metadata as the source of truth for the exact quality-dimension count rather than relying on inconsistent summary wording.

---

## 22. Final README Story

The README should remain a navigation layer rather than duplicate the detailed documentation.

Recommended order:

```text
# Enterprise Banking AI Platform

1. One-paragraph overview
2. Architecture image
3. Key capabilities
4. Two Implementation Experiences
5. Example outputs
6. Technology stack
7. Repository structure
8. Documentation links
9. Screenshots
10. Implemented vs. future
11. Key engineering decisions
```

The strongest README story is:

> **A version-controlled Snowflake AI engineering platform connecting semantic modeling, natural-language analytics, data-quality engineering, AI evaluation, governance, and a user-facing Streamlit application — with a separate Cortex Code workflow showing how the DQ capability was engineered and validated.**

---

## 23. Interview Narrative

> **“I structured the project as a version-controlled Snowflake engineering repository rather than just a dashboard. The SQL layer builds and validates the semantic model, data-quality checks, controlled defects, and governance controls. The Streamlit layer provides the user-facing Cortex Analyst, DQ, and AI-evaluation experience. Separately, the CoCo workflow demonstrates AI-assisted engineering for profiling, rule development, metadata-driven execution, anomaly detection, and validation. I kept screenshots tied to implementation artifacts and separated implemented capabilities from production extensions.”**

---

## 24. Final Engineering Principle

```text
                IMPLEMENTATION
                     │
          ┌──────────┼──────────┐
          │          │          │
         SQL       Python      YAML
          │          │          │
          └──────────┼──────────┘
                     │
                     v
              SNOWFLAKE OBJECTS
                     │
                     v
                EXECUTION
                     │
                     v
                VALIDATION
                     │
                     v
                 EVIDENCE
                     │
                     v
               DOCUMENTATION
```

The strongest portfolio artifact is not a screenshot by itself.

It is the **traceable engineering chain** connecting source code, Snowflake objects, tests, outputs, and documented conclusions.
