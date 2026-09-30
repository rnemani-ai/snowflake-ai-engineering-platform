# 04 — AI Evaluation, Governance & Testing

## Enterprise Banking AI Platform on Snowflake

> **Purpose:** Document the implemented AI evaluation workflow, Snowflake governance controls, security testing, application-level reliability checks, and the boundaries between implemented capabilities and future production extensions.

---

# 1. Executive Summary

The platform does not treat natural-language analytics as complete simply because Cortex Analyst can generate SQL.

It adds two important control layers:

```text
                 Cortex Analyst
                       |
                       v
                 Generated SQL
                       |
                       v
                  Actual Result
                       |
             +---------+---------+
             |                   |
             v                   v
       AI Evaluation        Governance
             |                   |
       Expected vs Actual   RBAC / Masking
             |             / Row Access
             v                   |
          PASS/FAIL          Security Tests
```

The current implementation therefore demonstrates:

- **AI result evaluation**
- predefined analytical test cases
- expected-vs-actual comparison
- result normalization
- generated SQL visibility
- Snowflake RBAC
- column masking
- row-access-policy framework
- role-based governance testing
- application-level error handling
- explicit separation between implemented controls and future production extensions

The AI evaluation is intentionally described as a **lightweight accuracy/regression-oriented framework**, not as a complete LLM evaluation platform.

---

# 2. Why AI Evaluation Is Necessary

A natural-language analytics system can fail in several ways even when the application itself is functioning.

For example:

```text
User Question
     |
     v
Cortex Analyst
     |
     v
Generated SQL
     |
     v
SQL executes successfully
     |
     v
Wrong business result
```

Therefore:

> **SQL execution success is not equivalent to analytical correctness.**

The project addresses this by defining known business questions and expected results.

The current evaluation path is:

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
Expected Result
        |
        v
PASS / FAIL
```

---

# 3. Current AI Evaluation Scope

The implemented evaluation focuses on:

- analytical result accuracy
- repeatable evaluation questions
- expected-vs-actual comparison
- semantic coverage
- regression-oriented testing

It does **not** currently represent a full LLM evaluation suite.

The current implementation does not claim comprehensive evaluation for:

- hallucination
- groundedness
- safety
- bias
- citation accuracy
- multi-turn reliability
- production latency monitoring
- production cost monitoring
- adversarial testing
- broad semantic ambiguity testing

These are future expansion areas.

---

# 4. Evaluation Scenarios

The Streamlit application contains predefined evaluation scenarios covering questions such as:

### Scenario 1 — Total balance by account type

Question:

```text
What is the total balance by account type?
```

Expected result:

```text
CHECKING = 10200
SAVINGS  = 21200
```

This validates an aggregation over:

```text
ACCOUNT_TYPE
TOTAL_BALANCE
```

---

### Scenario 2 — Average balance by account type

The implementation includes an average-balance evaluation case.

The documented evaluation artifact specifies:

```text
CHECKING = 3400
SAVINGS  = 10600
```

**Important implementation note:** the current Streamlit source inspected during repository review contains a different expected CHECKING value (`2550`) for this scenario.

Because the repository artifacts currently disagree, this value should be **verified against the live data and source code before being presented as a final README result**.

The documentation should not silently reconcile the discrepancy.

---

### Scenario 3 — Loan applications by status

The documented expected output is:

```text
APPROVED = 3
PENDING  = 1
REJECTED = 1
```

This evaluates grouping by:

```text
APPLICATION_STATUS
```

and counting loan applications.

---

# 5. Why Expected Results Matter

A test such as:

```text
Cortex Analyst returned HTTP 200
```

only verifies that the request completed successfully.

The project instead attempts to verify:

```text
Question
   |
   v
Generated SQL
   |
   v
Actual Business Result
   |
   v
Expected Business Result
   |
   v
PASS / FAIL
```

This creates a basic regression mechanism.

For example, if a semantic-view change causes:

```text
Expected:
CHECKING = 10200

Actual:
CHECKING = 9800
```

the test can identify the analytical regression even though the SQL executed successfully.

---

# 6. Result Normalization

The evaluation logic normalizes result fields before comparison.

This is important because equivalent analytical results can differ in representation.

Potential differences include:

- field naming
- column ordering
- result ordering
- representation of returned values

The evaluation therefore attempts to compare the **business result** rather than requiring an exact raw response-string match.

Conceptually:

```text
Raw Cortex Result
        |
        v
Normalize Fields
        |
        v
Normalize Representation
        |
        v
Compare With Expected
        |
        v
PASS / FAIL
```

This is a more useful evaluation pattern than comparing generated natural-language responses alone.

---

# 7. Generated SQL as Evaluation Evidence

The application exposes the generated SQL in the user-facing experience.

The flow is:

```text
ASK
 ↓
GENERATE
 ↓
INSPECT SQL
 ↓
VIEW RESULT
```

For example, a question about total balance by account type is translated through the semantic view rather than requiring the user to construct physical joins manually.

The application displays:

- Analyst response
- generated SQL
- query result

This provides an important debugging boundary:

```text
Natural-language question
        |
        v
AI interpretation
        |
        v
Generated SQL
        |
        v
Business result
```

An engineer can therefore inspect where an unexpected answer originated.

---

# 8. Evaluation as Regression Testing

The current implementation can be used as a small regression suite.

Conceptually:

```text
                    SEMANTIC MODEL CHANGE
                             |
                             v
                     Run Evaluation Set
                             |
            +----------------+----------------+
            |                |                |
            v                v                v
        Test Case 1      Test Case 2      Test Case 3
            |                |                |
            v                v                v
        PASS / FAIL      PASS / FAIL      PASS / FAIL
```

This is especially useful when changes are made to:

- semantic dimensions
- metrics
- relationships
- verified queries
- semantic guidance
- underlying data structures

The current implementation demonstrates the pattern; it is not yet a comprehensive automated CI regression pipeline.

---

# 9. Evaluation Limitations

The current evaluation implementation is intentionally lightweight.

## Implemented

- predefined questions
- expected results
- actual result capture
- normalization
- PASS/FAIL comparison
- generated SQL visibility

## Not implemented

- automated test execution on every Git commit
- large evaluation datasets
- multi-turn evaluation
- adversarial prompts
- ambiguity testing
- unsupported-question suites
- hallucination scoring
- groundedness scoring
- safety evaluation
- latency dashboards
- cost dashboards
- production evaluation history

These should be described as **future evaluation capabilities**, not current features.

---

# 10. Future AI Evaluation Evolution

A broader evaluation framework could evolve toward:

```text
                 AI EVALUATION
                       |
       +---------------+---------------+
       |               |               |
   Accuracy        Grounding        Safety
       |               |               |
   SQL Quality     Evidence        Policy
       |               |               |
       +---------------+---------------+
                       |
                  Reliability
                       |
          +------------+------------+
          |                         |
       Latency                    Cost
```

Potential metrics could include:

- SQL correctness
- result correctness
- semantic correctness
- groundedness
- hallucination rate
- unsupported-question handling
- ambiguity handling
- safety
- latency
- cost
- multi-turn consistency

The current repository provides the **expected-vs-actual foundation** for this evolution.

---

# 11. Governance Architecture

Governance is implemented separately from the application UI.

The relevant scripts are:

```text
07_governance.sql
08_governance_tests.sql
```

The governance schema is:

```text
BANKING_DQ_DB.GOVERNANCE
```

The implementation creates custom roles including:

```text
BANKING_DATA_STEWARD
BANKING_ANALYST
```

The architectural intent is:

```text
User
  |
  v
Role
  |
  v
Privileges
  |
  +--> Database
  |
  +--> Schema
  |
  +--> Table
  |
  +--> Policy-controlled columns/rows
```

This demonstrates Snowflake-native governance rather than relying only on application-side access checks.

---

# 12. Role-Based Access Control

The implementation grants the analyst role appropriate access to the database/schema/table required for the customer-data test.

The governance model separates:

### Data Steward

Higher-trust role used for governance testing.

### Banking Analyst

Lower-privilege analytical role used to validate protected data behavior.

The project therefore demonstrates:

```text
Different role
      |
      v
Different access context
      |
      v
Different data visibility
```

This is the basis for the masking test.

---

# 13. Masking Policy

The implementation creates:

```text
CUSTOMER_LAST_NAME_MASK
```

and applies it to:

```text
BANKING_DQ_DB.RAW.CUSTOMERS.LAST_NAME
```

The policy distinguishes privileged roles from other access paths.

Expected behavior:

```text
BANKING_DATA_STEWARD
        |
        +--> actual LAST_NAME

BANKING_ANALYST
        |
        +--> ***MASKED***
```

This demonstrates **column-level data protection**.

---

# 14. Why Masking Is Important for an AI Platform

The semantic/AI layer may expose business information through natural-language queries.

That creates an important governance question:

> **Can the analytics experience expose sensitive attributes simply because the AI can query the underlying table?**

The masking policy provides a database-level control boundary.

Conceptually:

```text
AI / Application
       |
       v
Snowflake Query
       |
       v
Masking Policy
       |
       +---- privileged role ---> actual value
       |
       +---- analyst role ------> masked value
```

The control therefore exists below the application layer.

---

# 15. Row Access Policy

The implementation also creates:

```text
CUSTOMER_ROW_ACCESS
```

on:

```text
CUSTOMERS(STATE)
```

This establishes a row-level policy mechanism.

However, the current policy configuration does **not** enforce active state-based regional filtering for the analyst role.

The current analyst condition permits access to the customer rows.

Therefore the accurate description is:

> **A row-access-policy framework is implemented and tested; active state/regional filtering is a future extension.**

This distinction is important for technical credibility.

---

# 16. Why Keep the Row Access Policy If It Does Not Restrict the Analyst Yet?

The current implementation demonstrates the mechanism and creates an extension point for a more restrictive policy.

A future policy could evolve from:

```text
ROLE CHECK
```

to something such as:

```text
ROLE
 +
AUTHORIZED_REGION
 +
CUSTOMER.STATE
```

Conceptually:

```text
User
 |
 v
Role
 |
 +----> authorized states
 |
 v
CUSTOMER.STATE
 |
 v
Allow / Deny
```

The current repository stops before implementing that regional restriction.

---

# 17. Governance Test Script

The validation artifact is:

```text
08_governance_tests.sql
```

The script explicitly changes roles and queries customer information.

The test queries:

```text
CUSTOMER_ID
FIRST_NAME
LAST_NAME
STATE
```

The objective is to verify that the masking policy behaves differently according to the role.

---

# 18. Governance Test Flow

```text
Policy Definition
       |
       v
Role Assignment
       |
       v
Switch Role
       |
       v
Query Customer Data
       |
       v
Inspect LAST_NAME
       |
       v
Expected Visibility
```

Expected behavior:

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

This is stronger evidence than merely showing that the policy object exists.

---

# 19. Governance Testing as Security Regression

The test can be viewed as a basic security regression:

```text
Change Policy
      |
      v
Run Role-Based Query
      |
      v
Verify Expected Visibility
```

If a future policy modification accidentally exposes the protected value to the analyst role, the test provides a simple mechanism to identify that regression.

The current test is SQL-driven rather than integrated into a formal CI security pipeline.

---

# 20. Application-Level Reliability

The Streamlit application contains basic operational safeguards around the Cortex Analyst request.

The application:

- obtains the active Snowflake session
- obtains the Snowflake host/session token
- sends the Cortex Analyst request
- checks the HTTP response
- applies a request timeout
- parses the response
- extracts generated SQL
- surfaces errors to the application

This is a **lightweight application reliability layer**.

It should not be described as a full production observability platform.

---

# 21. Snowflake-Native Session Model

The application uses:

```python
get_active_session()
```

to obtain the Snowflake-native session.

The Cortex Analyst integration then uses the active session context to obtain the required authorization information.

The application calls the Cortex Analyst endpoint using the Snowflake host and session token.

Conceptually:

```text
Streamlit
    |
    v
Active Snowflake Session
    |
    v
Session Authorization
    |
    v
Cortex Analyst
    |
    v
Semantic View
```

This avoids placing a separate static database password into the Streamlit interaction flow.

---

# 22. Cortex Analyst Request Boundary

The request includes the user message and the semantic-view reference:

```text
BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
```

The application therefore establishes an explicit semantic-model boundary for the analytical request.

The high-level flow is:

```text
User Question
      |
      v
Streamlit
      |
      v
Cortex Analyst
      |
      v
Semantic View
      |
      v
Generated SQL
      |
      v
Snowflake
      |
      v
Result
```

---

# 23. Application Error Handling

The Cortex Analyst helper includes checks for:

### HTTP success

The application verifies the response status.

### Timeout

The request uses a timeout boundary rather than waiting indefinitely.

### Response parsing

The application extracts expected response components.

### User-facing errors

Failures are surfaced through the Streamlit interface.

This is useful for a portfolio implementation because it demonstrates that the AI call is treated as an application dependency rather than an infallible operation.

---

# 24. Security Boundary vs Application Boundary

A useful architectural distinction is:

```text
APPLICATION CONTROLS
--------------------
Request handling
Timeout
Response parsing
UI errors


SNOWFLAKE CONTROLS
------------------
RBAC
Masking
Row access policy
Table privileges
Semantic model
```

The platform therefore does not rely entirely on Streamlit code for governance.

---

# 25. AI Evaluation + Governance Together

These two controls address different failure modes.

### AI Evaluation asks:

> **Did the AI analytics produce the expected business result?**

### Governance asks:

> **Was the user allowed to see the underlying information?**

Together:

```text
              User Question
                    |
                    v
             Cortex Analyst
                    |
          +---------+---------+
          |                   |
          v                   v
    AI Evaluation         Governance
          |                   |
   Is result correct?   Is access allowed?
          |                   |
          +---------+---------+
                    |
                    v
                Response
```

This is an important enterprise AI design principle.

Correctness and access control are separate concerns.

---

# 26. DQ + AI Evaluation + Governance

The platform can be understood as three complementary trust layers.

```text
                    AI RESPONSE
                        |
            +-----------+-----------+
            |           |           |
            v           v           v
         DATA        AI RESULT    ACCESS
        QUALITY      QUALITY      CONTROL
            |           |           |
            v           v           v
        DQ Rules    Evaluation     RBAC
        Profiling   Expected       Masking
        Validation  Results        Row Access
```

### Data Quality

Is the underlying data reliable enough?

### AI Evaluation

Did the analytical system produce the expected result?

### Governance

Was the result/data exposed under the correct access controls?

This is one of the strongest architectural themes of the overall project.

---

# 27. Testing Strategy Across the Platform

The repository contains several different types of tests/evidence.

| Test Type | Implementation |
|---|---|
| Data profiling | `03_dq_profiling.sql` |
| DQ rule execution | `04_dq_rules.sql` |
| Controlled defect injection | `05_inject_dq_issues.sql` |
| DQ defect verification | `06_verify_dq_issues.sql` |
| Governance policy definition | `07_governance.sql` |
| Governance behavior | `08_governance_tests.sql` |
| AI analytical evaluation | Streamlit AI Evaluation |
| Application error handling | Streamlit Cortex Analyst integration |

This is more representative of enterprise engineering than a single unit-test script.

---

# 28. Testing Philosophy

The project uses several complementary validation patterns.

## Known-defect testing

```text
Inject
  |
  v
Detect
  |
  v
Verify
```

Used for DQ.

## Expected-result testing

```text
Question
  |
  v
Actual
  |
  v
Expected
  |
  v
PASS/FAIL
```

Used for AI evaluation.

## Role-based testing

```text
Role
  |
  v
Query
  |
  v
Expected visibility
```

Used for governance.

Together:

```text
DATA
  |
  +--> DQ Validation
  |
  +--> AI Result Validation
  |
  +--> Access Validation
```

---

# 29. Implemented vs. Future

Maintaining this distinction is important.

## Implemented

- predefined AI evaluation scenarios
- expected-vs-actual comparison
- result normalization
- generated SQL visibility
- Cortex Analyst integration
- RBAC
- `BANKING_DATA_STEWARD`
- `BANKING_ANALYST`
- `CUSTOMER_LAST_NAME_MASK`
- `CUSTOMER_ROW_ACCESS`
- governance SQL tests
- application-level timeout/error handling
- DQ validation
- controlled defect injection

## Future Extensions

- larger automated AI evaluation suites
- CI-triggered evaluation
- hallucination evaluation
- groundedness evaluation
- safety evaluation
- multi-turn testing
- latency monitoring
- cost monitoring
- automated governance regression
- active regional row filtering
- enterprise alerting
- audit/event logging
- production observability

---

# 30. Important Current Limitations

### AI evaluation

The evaluation set is small and focused on analytical result correctness.

### Evaluation automation

The current evaluation interface is not a complete CI/CD regression pipeline.

### Governance

The row-access policy does not currently implement regional/state restrictions for the analyst role.

### Monitoring

Application-level error handling exists, but a complete production observability stack is not implemented.

### Security testing

The governance tests are SQL-based and targeted; they are not a comprehensive security test suite.

### Data quality

The CoCo DQ implementation uses synthetic data and a custom SQL engine rather than native DMFs.

---

# 31. Production-Oriented Evolution

A production version could evolve toward:

```text
                         PRODUCTION AI PLATFORM
                                  |
        +-------------------------+-------------------------+
        |                         |                         |
     DATA TRUST              AI TRUST                SECURITY TRUST
        |                         |                         |
      DQ Engine             Eval Framework             RBAC
      DQ History            Regression Suite           Masking
      Alerts                Groundedness               Row Access
      Ownership             Safety                     Audit
        |                         |                         |
        +-------------------------+-------------------------+
                                  |
                           Observability
                                  |
                    +-------------+-------------+
                    |                           |
                  Cost                        Latency
                    |                           |
                    +-------------+-------------+
                                  |
                              Application
```

Again, this diagram represents **production evolution**, not the current implemented scope.

---

# 32. Interview Narrative — 30 Seconds

> “I added an evaluation and governance layer around the Snowflake AI experience. For evaluation, I defined known banking questions with expected business results, ran them through Cortex Analyst, normalized the returned results, and compared actual versus expected values. I also exposed the generated SQL so the analytical path is inspectable. On the governance side, I implemented Snowflake RBAC, a masking policy for customer last names, a row-access-policy framework, and role-based SQL tests. I intentionally kept the evaluation lightweight and documented future expansion areas such as groundedness, safety, multi-turn testing, and automated CI regression.”

---

# 33. Interview Question — Why Evaluate Results Instead of SQL Only?

A strong answer:

> “A query can be syntactically valid and still answer the wrong business question. I therefore evaluate the business result against an expected result. Generated SQL is still displayed because it provides diagnostic evidence, but SQL validity alone isn't enough.”

---

# 34. Interview Question — Why Show Generated SQL?

> “Transparency. If a user asks for total balance by account type and the answer looks wrong, I want to see how Cortex Analyst interpreted the question. Showing the generated SQL gives me a debugging boundary between natural-language interpretation and the final result.”

---

# 35. Interview Question — Why Normalize Results?

> “A raw string comparison can fail even when the business answer is equivalent because column names, ordering, or representation can differ. Normalizing the result lets the evaluation focus more directly on the business values.”

---

# 36. Interview Question — How Does Governance Protect AI Outputs?

> “The AI application isn't the only security boundary. The underlying Snowflake objects enforce RBAC and masking. The last-name masking policy means the same underlying customer table can expose different values depending on the role. That control exists at the data layer rather than trusting only the Streamlit application.”

---

# 37. Interview Question — Is Row-Level Security Fully Implemented?

The technically accurate answer is:

> “The row-access-policy mechanism is implemented and tested, but the current analyst policy does not yet restrict rows by state. It provides the framework for a future regional or business-unit restriction. I would not describe the current project as having active state-level row filtering.”

---

# 38. Interview Question — What Happens If Cortex Analyst Fails?

> “The Streamlit integration validates the HTTP response, uses a request timeout, parses the expected response structure, and surfaces errors to the user. That's an application-level reliability layer. For production, I would add centralized logging, latency metrics, retries where appropriate, alerting, and broader observability.”

---

# 39. Interview Question — What Would You Add Next?

A technically grounded answer:

> “I would expand the evaluation suite first: SQL correctness, result correctness, ambiguous questions, unsupported questions, groundedness, and safety. Then I would integrate those tests into CI so semantic-model changes automatically run the regression suite. On the governance side, I would add active regional row filtering, stronger auditability, and policy regression tests.”

---

# 40. Evidence Mapping

A strong portfolio presentation should connect each claim to an artifact.

| Capability | Evidence |
|---|---|
| AI evaluation | Streamlit AI Evaluation tab |
| Expected results | Evaluation code/cases |
| Generated SQL | Cortex Analyst tab |
| Result inspection | Cortex Analyst output |
| RBAC | `07_governance.sql` |
| Masking | `CUSTOMER_LAST_NAME_MASK` |
| Row access | `CUSTOMER_ROW_ACCESS` |
| Governance testing | `08_governance_tests.sql` |
| DQ validation | `05_inject_dq_issues.sql` + `06_verify_dq_issues.sql` |
| CoCo engineering | `coco_data_quality/` artifacts |
| Version control | Git/GitHub repository |
| Application reliability | Streamlit Cortex Analyst helper |

This makes the repository auditable from a reviewer’s perspective.

---

# 41. Overall Trust Architecture

The platform's implemented trust story can be summarized as:

```text
                         USER QUESTION
                              |
                              v
                       CORTEX ANALYST
                              |
                              v
                       SEMANTIC VIEW
                              |
                              v
                        GENERATED SQL
                              |
                 +------------+------------+
                 |                         |
                 v                         v
            AI EVALUATION             SNOWFLAKE
                 |                         |
          Expected Result             RBAC / Policies
                 |                         |
                 v                         v
             PASS/FAIL              Data Visibility
                 |                         |
                 +------------+------------+
                              |
                              v
                         STREAMLIT
```

And underneath it:

```text
                   DATA QUALITY FOUNDATION
                              |
                     Profiling / Rules
                              |
                   Controlled Validation
                              |
                       CoCo Workflow
```

---

# 42. Final Engineering Takeaway

The strongest way to describe this portion of the project is not:

> “I added a chatbot and some security.”

The stronger description is:

> **“I treated natural-language analytics as an engineering system that requires evaluation and governance. I built a lightweight expected-vs-actual evaluation workflow around Cortex Analyst, exposed generated SQL for transparency, implemented Snowflake-native RBAC and column masking, established a row-access-policy framework, and validated access behavior through role-based SQL tests. I also kept clear boundaries around what is implemented today versus what would be required for production-scale AI evaluation and observability.”**

The core principle is:

> **An enterprise AI analytics system needs both analytical correctness and controlled data access.**
