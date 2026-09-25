USE DATABASE BANKING_DQ_DB;
USE SCHEMA ANALYTICS;

CREATE OR ALTER SEMANTIC VIEW BANKING_ANALYTICS

TABLES (
    branches AS BANKING_DQ_DB.RAW.BRANCHES
        PRIMARY KEY (BRANCH_ID),

    customers AS BANKING_DQ_DB.RAW.CUSTOMERS
        PRIMARY KEY (CUSTOMER_ID),

    accounts AS BANKING_DQ_DB.RAW.ACCOUNTS
        PRIMARY KEY (ACCOUNT_ID),

    transactions AS BANKING_DQ_DB.RAW.TRANSACTIONS
        PRIMARY KEY (TRANSACTION_ID),

    loan_applications AS BANKING_DQ_DB.RAW.LOAN_APPLICATIONS
        PRIMARY KEY (APPLICATION_ID)
)

RELATIONSHIPS (
    accounts_to_customers AS
        accounts (CUSTOMER_ID)
        REFERENCES customers (CUSTOMER_ID),

    accounts_to_branches AS
        accounts (BRANCH_ID)
        REFERENCES branches (BRANCH_ID),

    transactions_to_accounts AS
        transactions (ACCOUNT_ID)
        REFERENCES accounts (ACCOUNT_ID),

    loans_to_customers AS
        loan_applications (CUSTOMER_ID)
        REFERENCES customers (CUSTOMER_ID)
)

FACTS (
    accounts.balance AS accounts.BALANCE
        COMMENT = 'Current account balance',

    transactions.amount AS transactions.AMOUNT
        COMMENT = 'Transaction amount',

    loan_applications.loan_amount AS loan_applications.LOAN_AMOUNT
        COMMENT = 'Requested loan amount'
)

DIMENSIONS (
    branches.branch_name AS branches.BRANCH_NAME
        COMMENT = 'Bank branch name',

    branches.branch_city AS branches.CITY
        COMMENT = 'Branch city',

    customers.customer_name AS customers.FIRST_NAME || ' ' || customers.LAST_NAME
        COMMENT = 'Full customer name',

    customers.city AS customers.CITY
        COMMENT = 'Customer city',

    customers.state AS customers.STATE
        COMMENT = 'Customer state',

    accounts.account_type AS accounts.ACCOUNT_TYPE
        COMMENT = 'Type of bank account',

    accounts.account_status AS accounts.ACCOUNT_STATUS
        COMMENT = 'Current account status',

    transactions.transaction_type AS transactions.TRANSACTION_TYPE
        COMMENT = 'Type of transaction',

    transactions.transaction_status AS transactions.TRANSACTION_STATUS
        COMMENT = 'Transaction status',

    loan_applications.loan_type AS loan_applications.LOAN_TYPE
        COMMENT = 'Type of loan',

    loan_applications.application_status AS loan_applications.APPLICATION_STATUS
        COMMENT = 'Loan application status'
)

METRICS (
    accounts.total_balance AS SUM(accounts.BALANCE)
        COMMENT = 'Total balance across accounts',

    accounts.average_balance AS AVG(accounts.BALANCE)
        COMMENT = 'Average account balance',

    accounts.account_count AS COUNT(accounts.ACCOUNT_ID)
        COMMENT = 'Number of accounts',

    transactions.total_transaction_amount AS SUM(transactions.AMOUNT)
        COMMENT = 'Total transaction amount',

    transactions.transaction_count AS COUNT(transactions.TRANSACTION_ID)
        COMMENT = 'Total number of transactions',

    loan_applications.total_loan_amount AS SUM(loan_applications.LOAN_AMOUNT)
        COMMENT = 'Total requested loan amount',

    loan_applications.loan_application_count AS COUNT(loan_applications.APPLICATION_ID)
        COMMENT = 'Number of loan applications'
)

COMMENT = 'Semantic layer for banking analytics and Cortex Analyst'

AI_SQL_GENERATION
'Use the defined semantic dimensions and metrics when generating SQL.
Prefer existing semantic metrics instead of recreating their calculations.
Use the logical table and column names defined in this semantic view.
For ranking questions such as highest, lowest, top, or bottom, calculate
the requested metric and then order the result appropriately.
Do not invent columns, tables, dimensions, facts, or metrics.'

AI_QUESTION_CATEGORIZATION
'Classify questions about customers, accounts, balances, transactions,
branches, and loan applications as banking analytics questions.
For questions involving highest, lowest, top, bottom, ranking, or comparison,
identify the requested dimension and metric before generating SQL.
If the requested information is not represented by this semantic view,
do not invent an answer.'

AI_VERIFIED_QUERIES (

    total_balance_by_account_type AS (
        QUESTION 'What is the total balance by account type?'
        ONBOARDING_QUESTION TRUE
        SQL 'SELECT
                 accounts.account_type,
                 AGG(accounts.total_balance) AS total_balance
             FROM BANKING_ANALYTICS
             GROUP BY accounts.account_type
             ORDER BY accounts.account_type'
    ),

    average_balance_by_account_type AS (
        QUESTION 'What is the average balance by account type?'
        ONBOARDING_QUESTION TRUE
        SQL 'SELECT
                 accounts.account_type,
                 AGG(accounts.average_balance) AS average_balance
             FROM BANKING_ANALYTICS
             GROUP BY accounts.account_type
             ORDER BY accounts.account_type'
    ),

    loan_applications_by_status AS (
        QUESTION 'How many loan applications are there by application status?'
        ONBOARDING_QUESTION TRUE
        SQL 'SELECT
                 loan_applications.application_status,
                 AGG(loan_applications.loan_application_count) AS loan_application_count
             FROM BANKING_ANALYTICS
             GROUP BY loan_applications.application_status
             ORDER BY loan_applications.application_status'
    ),

    total_balance_by_customer AS (
        QUESTION 'What is the total balance for each customer?'
        ONBOARDING_QUESTION TRUE
        SQL 'SELECT
                 customers.customer_name,
                 AGG(accounts.total_balance) AS total_balance
             FROM BANKING_ANALYTICS
             GROUP BY customers.customer_name
             ORDER BY customers.customer_name'
    )
);

DESC SEMANTIC VIEW BANKING_ANALYTICS;