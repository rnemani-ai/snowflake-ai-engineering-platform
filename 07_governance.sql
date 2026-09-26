-- ============================================================
-- GOVERNANCE LAYER
-- Banking data security and access controls
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================
-- 1. GOVERNANCE SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS BANKING_DQ_DB.GOVERNANCE;

USE DATABASE BANKING_DQ_DB;
USE SCHEMA GOVERNANCE;


-- ============================================================
-- 2. ROLES
-- ============================================================

CREATE ROLE IF NOT EXISTS BANKING_DATA_STEWARD;
CREATE ROLE IF NOT EXISTS BANKING_ANALYST;

-- Allow ACCOUNTADMIN to activate these roles for administration/testing.
GRANT ROLE BANKING_DATA_STEWARD TO ROLE ACCOUNTADMIN;
GRANT ROLE BANKING_ANALYST TO ROLE ACCOUNTADMIN;


-- ============================================================
-- 3. MASKING POLICY
-- ============================================================
-- Data stewards and ACCOUNTADMIN can see real last names.
-- Banking analysts see a masked value.

CREATE OR REPLACE MASKING POLICY CUSTOMER_LAST_NAME_MASK
AS (VAL VARCHAR)
RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'BANKING_DATA_STEWARD')
            THEN VAL
        ELSE '***MASKED***'
    END
COMMENT = 'Masks customer last names for restricted banking analyst roles';


-- Apply masking policy to customer last names.

ALTER TABLE BANKING_DQ_DB.RAW.CUSTOMERS
MODIFY COLUMN LAST_NAME
SET MASKING POLICY BANKING_DQ_DB.GOVERNANCE.CUSTOMER_LAST_NAME_MASK;


-- ============================================================
-- 4. ROW ACCESS POLICY
-- ============================================================
-- Current banking analyst access allows all customer rows.
-- The policy provides a framework for future regional
-- or business-unit based row restrictions.

CREATE OR REPLACE ROW ACCESS POLICY CUSTOMER_ROW_ACCESS
AS (CUSTOMER_STATE VARCHAR)
RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'BANKING_DATA_STEWARD')
            THEN TRUE
        WHEN CURRENT_ROLE() = 'BANKING_ANALYST'
            THEN TRUE
        ELSE FALSE
    END
COMMENT = 'Role-based row access policy for banking customer data';


-- Apply row access policy to customer data.

ALTER TABLE BANKING_DQ_DB.RAW.CUSTOMERS
ADD ROW ACCESS POLICY CUSTOMER_ROW_ACCESS
ON (STATE);


-- ============================================================
-- 5. ANALYST DATA ACCESS
-- ============================================================

GRANT USAGE ON DATABASE BANKING_DQ_DB
    TO ROLE BANKING_ANALYST;

GRANT USAGE ON SCHEMA BANKING_DQ_DB.RAW
    TO ROLE BANKING_ANALYST;

GRANT SELECT ON TABLE BANKING_DQ_DB.RAW.CUSTOMERS
    TO ROLE BANKING_ANALYST;


-- ============================================================
-- 6. USER ROLE ASSIGNMENTS
-- ============================================================
-- Required for portfolio testing with the RAMYA user.

GRANT ROLE BANKING_ANALYST TO USER RAMYA;
GRANT ROLE BANKING_DATA_STEWARD TO USER RAMYA;


-- ============================================================
-- 7. VERIFICATION
-- ============================================================

SHOW MASKING POLICIES IN SCHEMA BANKING_DQ_DB.GOVERNANCE;

SHOW ROW ACCESS POLICIES IN SCHEMA BANKING_DQ_DB.GOVERNANCE;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_NAME => 'BANKING_DQ_DB.RAW.CUSTOMERS',
    REF_ENTITY_DOMAIN => 'TABLE'
));