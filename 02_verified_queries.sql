CREATE OR ALTER SEMANTIC VIEW BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS

TABLES (
    accounts AS BANKING_DQ_DB.RAW.ACCOUNTS
        PRIMARY KEY (ACCOUNT_ID),

    customers AS BANKING_DQ_DB.RAW.CUSTOMERS
        PRIMARY KEY (CUSTOMER_ID),

    branches AS BANKING_DQ_DB.RAW.BRANCHES
        PRIMARY KEY (BRANCH_ID),

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
        COMMENT = 'Number of transactions',

    loan_applications.total_loan_amount AS SUM(loan_applications.LOAN_AMOUNT)
        COMMENT = 'Total requested loan amount',

    loan_applications.loan_application_count AS COUNT(loan_applications.APPLICATION_ID)
        COMMENT = 'Number of loan applications'
)

COMMENT = 'Semantic layer for banking analytics and Cortex Analyst'

AI_VERIFIED_QUERIES (
    accounts_by_type AS (
        QUESTION 'What is the total balance and number of accounts by account type?'
        ONBOARDING_QUESTION TRUE
        SQL 'SELECT
                 ACCOUNT_TYPE,
                 AGG(TOTAL_BALANCE) AS TOTAL_BALANCE,
                 AGG(ACCOUNT_COUNT) AS ACCOUNT_COUNT
             FROM BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
             GROUP BY ACCOUNT_TYPE
             ORDER BY ACCOUNT_TYPE'
    )
);

DESC SEMANTIC VIEW BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS;

SELECT *
FROM SEMANTIC_VIEW(
    BANKING_DQ_DB.ANALYTICS.BANKING_ANALYTICS
    DIMENSIONS accounts.account_type
    METRICS accounts.total_balance, accounts.account_count
)
ORDER BY ACCOUNT_TYPE;