import os

import pandas as pd
import requests
import streamlit as st

from snowflake.snowpark.context import get_active_session


# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Enterprise Banking AI Platform",
    page_icon=":material/account_balance:",
    layout="wide",
    initial_sidebar_state="collapsed",
)


# ============================================================
# CUSTOM STYLING
# ============================================================

st.markdown(
    """
    <style>

    /* ========================================================
       GLOBAL
       ======================================================== */

    .stApp {
        background-color: #f6f8fb;
    }

    #MainMenu {
        visibility: hidden;
    }

    footer {
        visibility: hidden;
    }


    /* ========================================================
       MAIN HEADINGS
       ======================================================== */

    h1 {
        color: #172033 !important;
        font-size: 2.25rem !important;
        font-weight: 750 !important;
        letter-spacing: -0.8px !important;
        margin-bottom: 0.1rem !important;
    }

    h2 {
        color: #172033 !important;
        font-size: 1.35rem !important;
        font-weight: 700 !important;
    }

    h3 {
        color: #24324a !important;
        font-size: 1.1rem !important;
        font-weight: 650 !important;
    }


    /* ========================================================
       CAPTIONS
       ======================================================== */

    [data-testid="stCaptionContainer"] {
        color: #667085;
    }


    /* ========================================================
       METRIC CARDS
       ======================================================== */

    [data-testid="stMetric"] {
        background-color: #ffffff;
        border: 1px solid #e3e8ef;
        border-radius: 12px;
        padding: 16px 18px;
        min-height: 105px;
        box-shadow: 0 2px 7px rgba(16, 24, 40, 0.04);
    }

    [data-testid="stMetricLabel"] {
        color: #667085 !important;
        font-size: 0.82rem !important;
        font-weight: 600 !important;
    }

    [data-testid="stMetricValue"] {
        color: #172033 !important;
        font-size: 1.55rem !important;
        font-weight: 750 !important;
    }


    /* ========================================================
       CONTAINERS
       ======================================================== */

    [data-testid="stVerticalBlockBorderWrapper"] {
        background-color: #ffffff;
        border: 1px solid #e3e8ef;
        border-radius: 12px;
        box-shadow: 0 2px 7px rgba(16, 24, 40, 0.03);
    }


    /* ========================================================
       BUTTONS
       ======================================================== */

    .stButton > button {
        border-radius: 8px;
        min-height: 42px;
        font-weight: 650;
    }


    /* ========================================================
       INPUTS
       ======================================================== */

    div[data-baseweb="input"] {
        border-radius: 8px;
    }


    /* ========================================================
       TABS
       ======================================================== */

    button[data-baseweb="tab"] {
        color: #667085;
        font-size: 0.92rem;
        font-weight: 650;
    }

    button[data-baseweb="tab"][aria-selected="true"] {
        color: #1d4ed8;
    }


    /* ========================================================
       DATAFRAME
       ======================================================== */

    [data-testid="stDataFrame"] {
        border-radius: 10px;
    }


    /* ========================================================
       DIVIDERS
       ======================================================== */

    hr {
        border-color: #e3e8ef;
    }


    /* ========================================================
       CODE
       ======================================================== */

    pre {
        border-radius: 10px !important;
    }

    </style>
    """,
    unsafe_allow_html=True,
)


# ============================================================
# SNOWFLAKE SESSION
# ============================================================

session = get_active_session()


# ============================================================
# HELPER — CORTEX ANALYST
# ============================================================

def call_cortex_analyst(question):
    """
    Send a natural-language question to Cortex Analyst.
    """

    snowflake_host = os.getenv(
        "SNOWFLAKE_HOST"
    )

    token_path = "/snowflake/session/token"

    if not snowflake_host:
        raise RuntimeError(
            "SNOWFLAKE_HOST is not available."
        )

    if not os.path.exists(token_path):
        raise RuntimeError(
            "Snowflake session token was not found."
        )

    with open(
        token_path,
        "r"
    ) as token_file:

        token = token_file.read().strip()


    analyst_url = (
        f"https://{snowflake_host}"
        "/api/v2/cortex/analyst/message"
    )


    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": f"Bearer {token}",
        "X-Snowflake-Authorization-Token-Type": "OAUTH",
    }


    request_body = {

        "messages": [

            {
                "role": "user",

                "content": [

                    {
                        "type": "text",
                        "text": question,
                    }

                ],
            }

        ],

        "semantic_view": (
            "BANKING_DQ_DB."
            "ANALYTICS."
            "BANKING_ANALYTICS"
        ),
    }


    response = requests.post(
        analyst_url,
        headers=headers,
        json=request_body,
        timeout=120,
    )


    if response.status_code != 200:

        raise RuntimeError(
            f"Cortex Analyst API returned "
            f"HTTP {response.status_code}: "
            f"{response.text}"
        )


    return response.json()


# ============================================================
# HELPER — EXTRACT ANALYST RESPONSE
# ============================================================

def extract_analyst_response(data):
    """
    Extract text and SQL from Cortex Analyst response.
    """

    content = (
        data
        .get("message", {})
        .get("content", [])
    )


    analyst_text = None
    generated_sql = None


    for item in content:

        if item.get("type") == "text":

            analyst_text = item.get(
                "text"
            )


        elif item.get("type") == "sql":

            generated_sql = item.get(
                "statement"
            )


    return analyst_text, generated_sql


# ============================================================
# HEADER
# ============================================================

st.title(
    "Enterprise Banking AI Platform"
)

st.caption(
    "Semantic Analytics  •  Data Quality  •  AI Evaluation"
)


# ============================================================
# SOLUTION OVERVIEW
# ============================================================

with st.container(border=True):

    st.subheader(
        "Solution Overview"
    )

    st.write(
        "An enterprise banking AI platform built on Snowflake "
        "that combines a business semantic layer, automated "
        "data-quality monitoring, Cortex Analyst and AI "
        "evaluation."
    )

    st.caption(
        "The platform demonstrates a governed workflow from "
        "structured banking data to natural-language analytics "
        "and validated AI-generated results."
    )


st.write("")


# ============================================================
# DATA QUALITY RULE DETAILS
# ============================================================

dq_detail_query = """

SELECT
    TABLE_NAME,
    RULE_NAME,
    RULE_DESCRIPTION,
    FAILED_RECORDS,
    STATUS

FROM (

    /* ========================================================
       CUSTOMER ID NOT NULL
       ======================================================== */

    SELECT

        'CUSTOMERS' AS TABLE_NAME,

        'CUSTOMER_ID_NOT_NULL' AS RULE_NAME,

        'Customer ID must be populated'
            AS RULE_DESCRIPTION,

        COUNT_IF(
            CUSTOMER_ID IS NULL
        ) AS FAILED_RECORDS,

        IFF(
            COUNT_IF(
                CUSTOMER_ID IS NULL
            ) = 0,
            'PASS',
            'FAIL'
        ) AS STATUS

    FROM BANKING_DQ_DB.RAW.CUSTOMERS


    UNION ALL


    /* ========================================================
       ACCOUNT BALANCE NON NEGATIVE
       ======================================================== */

    SELECT

        'ACCOUNTS',

        'BALANCE_NON_NEGATIVE',

        'Account balance must be zero or positive',

        COUNT_IF(
            BALANCE < 0
        ),

        IFF(
            COUNT_IF(
                BALANCE < 0
            ) = 0,
            'PASS',
            'FAIL'
        )

    FROM BANKING_DQ_DB.RAW.ACCOUNTS


    UNION ALL


    /* ========================================================
       TRANSACTION ID UNIQUE
       ======================================================== */

    SELECT

        'TRANSACTIONS',

        'TRANSACTION_ID_UNIQUE',

        'Transaction ID must be unique',

        COUNT(*)
        - COUNT(
            DISTINCT TRANSACTION_ID
        ),

        IFF(
            COUNT(*)
            =
            COUNT(
                DISTINCT TRANSACTION_ID
            ),
            'PASS',
            'FAIL'
        )

    FROM BANKING_DQ_DB.RAW.TRANSACTIONS


    UNION ALL


    /* ========================================================
       TRANSACTION AMOUNT NOT NULL
       ======================================================== */

    SELECT

        'TRANSACTIONS',

        'AMOUNT_NOT_NULL',

        'Transaction amount must be populated',

        COUNT_IF(
            AMOUNT IS NULL
        ),

        IFF(
            COUNT_IF(
                AMOUNT IS NULL
            ) = 0,
            'PASS',
            'FAIL'
        )

    FROM BANKING_DQ_DB.RAW.TRANSACTIONS


    UNION ALL


    /* ========================================================
       APPLICATION ID UNIQUE
       ======================================================== */

    SELECT

        'LOAN_APPLICATIONS',

        'APPLICATION_ID_UNIQUE',

        'Loan application ID must be unique',

        COUNT(*)
        - COUNT(
            DISTINCT APPLICATION_ID
        ),

        IFF(
            COUNT(*)
            =
            COUNT(
                DISTINCT APPLICATION_ID
            ),
            'PASS',
            'FAIL'
        )

    FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS


    UNION ALL


    /* ========================================================
       LOAN AMOUNT NOT NULL
       ======================================================== */

    SELECT

        'LOAN_APPLICATIONS',

        'LOAN_AMOUNT_NOT_NULL',

        'Loan amount must be populated',

        COUNT_IF(
            LOAN_AMOUNT IS NULL
        ),

        IFF(
            COUNT_IF(
                LOAN_AMOUNT IS NULL
            ) = 0,
            'PASS',
            'FAIL'
        )

    FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS

)

ORDER BY
    STATUS DESC,
    TABLE_NAME,
    RULE_NAME

"""


dq_detail_df = (
    session
    .sql(dq_detail_query)
    .to_pandas()
)


total_rules = len(
    dq_detail_df
)


passed_rules = int(
    (
        dq_detail_df["STATUS"]
        == "PASS"
    ).sum()
)


failed_rules = int(
    (
        dq_detail_df["STATUS"]
        == "FAIL"
    ).sum()
)


# ============================================================
# DATA COUNTS
# ============================================================

data_counts_query = """

SELECT
    'CUSTOMERS' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT
FROM BANKING_DQ_DB.RAW.CUSTOMERS

UNION ALL

SELECT
    'ACCOUNTS',
    COUNT(*)
FROM BANKING_DQ_DB.RAW.ACCOUNTS

UNION ALL

SELECT
    'TRANSACTIONS',
    COUNT(*)
FROM BANKING_DQ_DB.RAW.TRANSACTIONS

UNION ALL

SELECT
    'LOAN_APPLICATIONS',
    COUNT(*)
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS

UNION ALL

SELECT
    'BRANCHES',
    COUNT(*)
FROM BANKING_DQ_DB.RAW.BRANCHES

"""


data_counts = (
    session
    .sql(data_counts_query)
    .to_pandas()
)


def get_count(table_name):

    value = data_counts.loc[
        data_counts["TABLE_NAME"]
        == table_name,
        "ROW_COUNT",
    ].iloc[0]

    return int(value)


customers_count = get_count(
    "CUSTOMERS"
)

accounts_count = get_count(
    "ACCOUNTS"
)

transactions_count = get_count(
    "TRANSACTIONS"
)

loans_count = get_count(
    "LOAN_APPLICATIONS"
)

branches_count = get_count(
    "BRANCHES"
)


total_records = (
    customers_count
    + accounts_count
    + transactions_count
    + loans_count
    + branches_count
)


# ============================================================
# TOP KPI SECTION
# ============================================================

col1, col2, col3, col4 = st.columns(4)


with col1:

    st.metric(
        "Semantic Layer",
        "Active",
    )


with col2:

    st.metric(
        "Data Sources",
        5,
    )


with col3:

    st.metric(
        "Rules Passed",
        passed_rules,
    )


with col4:

    st.metric(
        "Rules Failed",
        failed_rules,
    )


st.write("")


# ============================================================
# BANKING DATA LANDSCAPE
# ============================================================

with st.container(border=True):

    st.subheader(
        "Banking Data Landscape"
    )

    st.caption(
        f"Five source tables containing "
        f"{total_records} total records."
    )

    st.write("")


    data_col1, data_col2, data_col3 = (
        st.columns(3)
    )

    data_col4, data_col5, data_col6 = (
        st.columns(3)
    )


    with data_col1:

        st.metric(
            "Customers",
            customers_count,
            help="Customer master records.",
        )


    with data_col2:

        st.metric(
            "Accounts",
            accounts_count,
            help="Bank account records.",
        )


    with data_col3:

        st.metric(
            "Transactions",
            transactions_count,
            help="Banking transaction records.",
        )


    with data_col4:

        st.metric(
            "Loan Applications",
            loans_count,
            help="Loan application records.",
        )


    with data_col5:

        st.metric(
            "Branches",
            branches_count,
            help="Bank branch records.",
        )


    with data_col6:

        st.metric(
            "Total Records",
            total_records,
            help="Total records across all five source tables.",
        )


st.write("")


# ============================================================
# DATA QUALITY MONITORING
# ============================================================

with st.container(border=True):

    st.subheader(
        "Data Quality Monitoring"
    )

    st.caption(
        "Automated validation across completeness, uniqueness "
        "and business-validity rules."
    )

    st.write("")


    display_dq_df = dq_detail_df.rename(
        columns={
            "TABLE_NAME":
                "Table",

            "RULE_NAME":
                "Rule",

            "RULE_DESCRIPTION":
                "What it checks",

            "FAILED_RECORDS":
                "Failed Records",

            "STATUS":
                "Status",
        }
    )


    # --------------------------------------------------------
    # Style PASS / FAIL
    # --------------------------------------------------------

    def style_status(value):

        if value == "PASS":

            return (
                "background-color: #ecfdf3; "
                "color: #027a48; "
                "font-weight: 700;"
            )

        if value == "FAIL":

            return (
                "background-color: #fef3f2; "
                "color: #b42318; "
                "font-weight: 700;"
            )

        return ""


    def style_failed_records(value):

        if value > 0:

            return (
                "background-color: #fff4ed; "
                "color: #c4320a; "
                "font-weight: 700;"
            )

        return (
            "color: #344054; "
            "font-weight: 600;"
        )


    styled_dq_df = (
        display_dq_df
        .style
        .map(
            style_status,
            subset=["Status"],
        )
        .map(
            style_failed_records,
            subset=["Failed Records"],
        )
    )


    st.dataframe(
        styled_dq_df,
        use_container_width=True,
        hide_index=True,
        column_config={

            "Table":
                st.column_config.TextColumn(
                    "Table",
                    width="medium",
                ),

            "Rule":
                st.column_config.TextColumn(
                    "Rule",
                    width="medium",
                ),

            "What it checks":
                st.column_config.TextColumn(
                    "What it checks",
                    width="large",
                ),

            "Failed Records":
                st.column_config.NumberColumn(
                    "Failed Records",
                    format="%d",
                ),

            "Status":
                st.column_config.TextColumn(
                    "Status",
                    width="small",
                ),
        },
    )


st.write("")


# ============================================================
# DQ INTERPRETATION
# ============================================================

with st.expander(
    "How to interpret the data quality results"
):

    st.markdown(
        """
        **PASS** means all records satisfy the rule.

        **FAIL** means one or more records violate the rule.

        The current dataset intentionally contains data-quality
        issues so the monitoring framework can demonstrate how
        real problems are detected.

        **Completeness**

        Required fields such as customer IDs, transaction
        amounts and loan amounts must not be NULL.

        **Uniqueness**

        Business identifiers such as transaction IDs and loan
        application IDs must be unique.

        **Business Validity**

        Account balances must satisfy the defined business
        constraint that they cannot be negative.
        """
    )


# ============================================================
# SOLUTION DETAILS
# ============================================================

with st.expander(
    "Solution architecture and capabilities"
):

    st.markdown(
        """
        ### Semantic Layer

        A Snowflake semantic view defines the business meaning
        of customers, accounts, transactions, branches and
        loan applications. Cortex Analyst uses this semantic
        layer to understand business questions.

        ### Data Quality

        SQL-based validation rules continuously evaluate the
        banking source data for completeness, uniqueness and
        business validity.

        ### Cortex Analyst

        Users can ask questions in natural language. Cortex
        Analyst generates SQL using the semantic layer, and
        the application executes the generated SQL against
        Snowflake.

        ### AI Evaluation

        Predefined business questions are evaluated against
        expected results to validate the accuracy of the
        AI-generated analytical output.

        ### Technology

        **Snowflake** • **Cortex Analyst** •
        **Semantic Views** • **SQL** •
        **Streamlit** • **AI Evaluation**
        """
    )


st.write("")


# ============================================================
# APPLICATION TABS
# ============================================================

tab1, tab2 = st.tabs(
    [
        "Cortex Analyst",
        "AI Evaluation",
    ]
)


# ============================================================
# TAB 1 — CORTEX ANALYST
# ============================================================

with tab1:

    st.subheader(
        "Cortex Analyst — Natural Language Analytics"
    )

    st.caption(
        "Ask a business question in natural language. "
        "Cortex Analyst uses the banking semantic layer "
        "to generate SQL and return the analytical result."
    )

    st.write("")


    question = st.text_input(
        "Banking question",
        placeholder=(
            "Example: What is the total balance by account type?"
        ),
        label_visibility="collapsed",
    )


    ask_button = st.button(
        "Ask Cortex Analyst",
        type="primary",
    )


    if ask_button:

        if not question.strip():

            st.warning(
                "Please enter a banking question."
            )

        else:

            with st.spinner(
                "Cortex Analyst is generating an answer..."
            ):

                try:

                    data = call_cortex_analyst(
                        question
                    )


                    analyst_text, generated_sql = (
                        extract_analyst_response(data)
                    )


                    st.success(
                        "Cortex Analyst completed successfully."
                    )


                    if analyst_text:

                        st.subheader(
                            "Analyst Response"
                        )

                        st.write(
                            analyst_text
                        )


                    if generated_sql:

                        st.subheader(
                            "Generated SQL"
                        )

                        st.code(
                            generated_sql,
                            language="sql",
                        )


                        st.subheader(
                            "Query Result"
                        )


                        try:

                            result_df = (
                                session
                                .sql(generated_sql)
                                .to_pandas()
                            )


                            st.dataframe(
                                result_df,
                                use_container_width=True,
                                hide_index=True,
                            )


                        except Exception as sql_error:

                            st.error(
                                "The SQL generated by "
                                "Cortex Analyst could not "
                                "be executed."
                            )

                            st.code(
                                str(sql_error)
                            )


                    else:

                        st.warning(
                            "Cortex Analyst returned a response "
                            "but no SQL statement was found."
                        )


                        with st.expander(
                            "View raw response"
                        ):

                            st.json(
                                data
                            )


                except requests.exceptions.Timeout:

                    st.error(
                        "Cortex Analyst request timed out. "
                        "Please try again."
                    )


                except requests.exceptions.RequestException as error:

                    st.error(
                        "Network error while calling "
                        "Cortex Analyst."
                    )

                    st.code(
                        str(error)
                    )


                except Exception as error:

                    st.error(
                        "Cortex Analyst request failed."
                    )

                    st.code(
                        str(error)
                    )


# ============================================================
# TAB 2 — AI EVALUATION
# ============================================================

with tab2:

    st.subheader(
        "AI Evaluation — Accuracy Validation"
    )

    st.caption(
        "Validate Cortex Analyst against predefined "
        "business questions and expected results."
    )

    st.write("")


    evaluation_cases = [

        {
            "question":
                "What is the total balance by account type?",

            "expected": {
                "CHECKING": 10200,
                "SAVINGS": 21200,
            },
        },


        {
            "question":
                "What is the average balance by account type?",

            "expected": {
                "CHECKING": 3400,
                "SAVINGS": 10600,
            },
        },


        {
            "question":
                "How many loan applications are there by status?",

            "expected": {
                "APPROVED": 3,
                "PENDING": 1,
                "REJECTED": 1,
            },
        },

    ]


    selected_question = st.selectbox(
        "Evaluation question",
        [
            case["question"]
            for case in evaluation_cases
        ],
    )


    run_evaluation = st.button(
        "Run Evaluation",
        type="primary",
    )


    if run_evaluation:

        with st.spinner(
            "Running Cortex Analyst evaluation..."
        ):

            try:

                data = call_cortex_analyst(
                    selected_question
                )


                _, generated_sql = (
                    extract_analyst_response(data)
                )


                if not generated_sql:

                    st.warning(
                        "Cortex Analyst did not return SQL."
                    )


                    with st.expander(
                        "View raw response"
                    ):

                        st.json(
                            data
                        )


                    st.stop()


                st.subheader(
                    "Generated SQL"
                )


                st.code(
                    generated_sql,
                    language="sql",
                )


                result_df = (
                    session
                    .sql(generated_sql)
                    .to_pandas()
                )


                st.subheader(
                    "Actual Result"
                )


                st.dataframe(
                    result_df,
                    use_container_width=True,
                    hide_index=True,
                )


                expected = next(
                    case["expected"]
                    for case in evaluation_cases
                    if case["question"]
                    == selected_question
                )


                st.subheader(
                    "Expected Result"
                )


                st.json(
                    expected
                )


                # ------------------------------------------------
                # NORMALIZE ACTUAL RESULT
                # ------------------------------------------------

                actual_result = {}


                # Total balance
                if (
                    "ACCOUNT_TYPE"
                    in result_df.columns
                    and
                    "TOTAL_BALANCE"
                    in result_df.columns
                ):

                    for _, row in result_df.iterrows():

                        actual_result[
                            str(
                                row[
                                    "ACCOUNT_TYPE"
                                ]
                            )
                        ] = int(
                            round(
                                row[
                                    "TOTAL_BALANCE"
                                ]
                            )
                        )


                # Average balance
                elif (
                    "ACCOUNT_TYPE"
                    in result_df.columns
                    and
                    "AVERAGE_BALANCE"
                    in result_df.columns
                ):

                    for _, row in result_df.iterrows():

                        actual_result[
                            str(
                                row[
                                    "ACCOUNT_TYPE"
                                ]
                            )
                        ] = int(
                            round(
                                row[
                                    "AVERAGE_BALANCE"
                                ]
                            )
                        )


                # Loan applications
                elif (
                    "APPLICATION_STATUS"
                    in result_df.columns
                ):

                    count_column = None


                    for column in result_df.columns:

                        if "COUNT" in column:

                            count_column = column

                            break


                    if count_column:

                        for _, row in result_df.iterrows():

                            actual_result[
                                str(
                                    row[
                                        "APPLICATION_STATUS"
                                    ]
                                )
                            ] = int(
                                row[
                                    count_column
                                ]
                            )


                # ------------------------------------------------
                # EVALUATION RESULT
                # ------------------------------------------------

                st.divider()


                if actual_result == expected:

                    st.success(
                        "EVALUATION PASSED"
                    )


                else:

                    st.error(
                        "EVALUATION FAILED"
                    )


                    col1, col2 = st.columns(2)


                    with col1:

                        st.write(
                            "**Actual**"
                        )

                        st.json(
                            actual_result
                        )


                    with col2:

                        st.write(
                            "**Expected**"
                        )

                        st.json(
                            expected
                        )


            except Exception as error:

                st.error(
                    "Evaluation failed."
                )

                st.code(
                    str(error)
                )


# ============================================================
# FOOTER
# ============================================================

st.write("")

st.caption(
    "Enterprise Banking AI Platform  •  "
    "Snowflake  •  Cortex Analyst  •  "
    "Data Quality  •  AI Evaluation"
)