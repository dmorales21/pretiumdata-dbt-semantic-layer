-- =============================================================================
-- First Street (TRANSFORM.FIRST_STREET) + RCA (TRANSFORM.RCA) — inventory & uniques
--
-- Related: docs/migration/MIGRATION_TASKS_FIRST_STREET_RCA.md
-- RCA plan: pretium-ai-dbt docs/governance/RCA_DATA_MODELING_PLAN_TRANSFORM_RCA.md
-- TRANSFORM.RCA views: pretium-ai-dbt scripts/sql/rca/16_populate_transform_rca_from_transform_prod_cleaned.sql
-- =============================================================================

-- ############################################################################
-- # FIRST STREET — TRANSFORM.FIRST_STREET
-- ############################################################################

USE DATABASE TRANSFORM;

-- FS-A) Objects in TRANSFORM.FIRST_STREET
SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'FIRST_STREET'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- FS-B) Columns (export full result to CSV for “documented vs physical” diff)
SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'FIRST_STREET'
ORDER BY table_name, ordinal_position;

-- FS-C) Row counts (extend if FS-A lists additional tables)
SELECT 'FIRST_STREET.HISTORIC_FIRE_EVENTS' AS object_id, COUNT(*) AS row_count FROM FIRST_STREET.HISTORIC_FIRE_EVENTS
UNION ALL SELECT 'FIRST_STREET.HISTORIC_FLOOD_EVENTS', COUNT(*) FROM FIRST_STREET.HISTORIC_FLOOD_EVENTS
UNION ALL SELECT 'FIRST_STREET.HISTORIC_WIND_EVENTS', COUNT(*) FROM FIRST_STREET.HISTORIC_WIND_EVENTS
UNION ALL SELECT 'FIRST_STREET.CLIMATE_RISK', COUNT(*) FROM FIRST_STREET.CLIMATE_RISK;

-- FS-D) Historic — duplicate grain (ZIP × EVENT_ID)
SELECT 'HISTORIC_FIRE_EVENTS dup zip+event' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT ZIPCODE, EVENT_ID, COUNT(*) AS c FROM FIRST_STREET.HISTORIC_FIRE_EVENTS
    WHERE ZIPCODE IS NOT NULL AND EVENT_ID IS NOT NULL GROUP BY ZIPCODE, EVENT_ID HAVING c > 1
) s;

SELECT 'HISTORIC_FLOOD_EVENTS dup zip+event' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT ZIPCODE, EVENT_ID, COUNT(*) AS c FROM FIRST_STREET.HISTORIC_FLOOD_EVENTS
    WHERE ZIPCODE IS NOT NULL AND EVENT_ID IS NOT NULL GROUP BY ZIPCODE, EVENT_ID HAVING c > 1
) s;

SELECT 'HISTORIC_WIND_EVENTS dup zip+event' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT ZIPCODE, EVENT_ID, COUNT(*) AS c FROM FIRST_STREET.HISTORIC_WIND_EVENTS
    WHERE ZIPCODE IS NOT NULL AND EVENT_ID IS NOT NULL GROUP BY ZIPCODE, EVENT_ID HAVING c > 1
) s;

-- FS-E) CLIMATE_RISK — duplicate (ZIPCODE × RISK_TYPE) and RISK_TYPE uniques
SELECT RISK_TYPE, COUNT(*) AS row_count
FROM FIRST_STREET.CLIMATE_RISK
WHERE RISK_TYPE IS NOT NULL
GROUP BY RISK_TYPE
ORDER BY row_count DESC;

SELECT 'CLIMATE_RISK dup zip+risk_type' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT ZIPCODE, RISK_TYPE, COUNT(*) AS c
    FROM FIRST_STREET.CLIMATE_RISK
    WHERE ZIPCODE IS NOT NULL AND RISK_TYPE IS NOT NULL
    GROUP BY ZIPCODE, RISK_TYPE
    HAVING c > 1
) s;

-- ############################################################################
-- # RCA — TRANSFORM.RCA (pass-through views over TRANSFORM_PROD.CLEANED.CLEANED_RCA_*)
-- ############################################################################

-- RC-A) Objects in TRANSFORM.RCA
SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'RCA'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- RC-B) Columns on TRANSACTION (quoted identifier; IS may return name without quotes)
SELECT ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'RCA'
  AND UPPER(table_name) = 'TRANSACTION'
ORDER BY ordinal_position;

-- RC-C) Row counts — core RCA consumer views (adjust names if FS-A differs)
SELECT 'RCA.TRANSACTION' AS object_id, COUNT(*) AS row_count FROM RCA."TRANSACTION"
UNION ALL SELECT 'RCA.INVESTOR', COUNT(*) FROM RCA.INVESTOR
UNION ALL SELECT 'RCA.LENDER', COUNT(*) FROM RCA.LENDER
UNION ALL SELECT 'RCA.RECORDER_DICTIONARY', COUNT(*) FROM RCA.RECORDER_DICTIONARY;

-- RC-D) Modeling-key non-null spot checks (transaction) — names from RCA_DATA_MODELING_PLAN §5
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE PROPERTY_ID IS NOT NULL) AS n_property_id,
    COUNT(*) FILTER (WHERE PROPERTYKEY_ID IS NOT NULL) AS n_propertykey_id,
    COUNT(*) FILTER (WHERE STATUS_DT IS NOT NULL) AS n_status_dt,
    COUNT(*) FILTER (WHERE DEAL_ID IS NOT NULL) AS n_deal_id
FROM RCA."TRANSACTION";

-- RC-E) Geography columns presence (0 = column missing or all null).
--     If this block fails to compile, a column was renamed on the slice — use RC-B output and adjust.
--     Seed lists both RCA_SUBMARKET_TX and RCA_SUB_MARKET_TX on transactions (see rca_transaction_field_inventory.csv).
SELECT
    COUNT(*) FILTER (WHERE RCA_METROS_TX IS NOT NULL) AS n_rca_metros_tx,
    COUNT(*) FILTER (WHERE RCA_MARKET_TX IS NOT NULL) AS n_rca_metro_tx,
    COUNT(*) FILTER (WHERE RCA_MARKETS_TX IS NOT NULL) AS n_rca_markets_tx,
    COUNT(*) FILTER (WHERE RCA_SUBMARKET_TX IS NOT NULL) AS n_rca_submarket_tx,
    COUNT(*) FILTER (WHERE RCA_SUB_MARKET_TX IS NOT NULL) AS n_rca_sub_market_tx,
    COUNT(*) FILTER (WHERE CBD_FG IS NOT NULL) AS n_cbd_fg
FROM RCA."TRANSACTION";

-- RC-F) Duplicate grain template — tune keys after duplicate analysis policy (plan §5.2)
SELECT 'TRANSACTION dup property_id+status_dt+deal_id' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT PROPERTY_ID, STATUS_DT, DEAL_ID, COUNT(*) AS c
    FROM RCA."TRANSACTION"
    WHERE PROPERTY_ID IS NOT NULL AND STATUS_DT IS NOT NULL
    GROUP BY PROPERTY_ID, STATUS_DT, DEAL_ID
    HAVING c > 1
) s;

-- RC-G) Export physical column names for offline diff to:
--     dbt/seeds/rca/rca_transaction_field_inventory.csv (field_name)
--     docs/governance/exports/ic_memo_msci_rca_transactions_field_catalog.csv
-- Seed may be a SUPerset of Pretium slice (~235 cols) — “missing on TRANSACTION” rows are expected for unused product fields.
SELECT column_name AS physical_column
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'RCA'
  AND UPPER(table_name) = 'TRANSACTION'
ORDER BY ordinal_position;

-- RC-G2) OPTIONAL — requires seed materialized in Snowflake (adjust database.schema.table).
-- Lists seed field_name values with no matching column on TRANSACTION (case-insensitive).
/*
SELECT s.field_name
FROM <YOUR_SEED_DB>.<YOUR_SEED_SCHEMA>.RCA_TRANSACTION_FIELD_INVENTORY s
LEFT JOIN (
    SELECT UPPER(column_name) AS ucol
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_catalog = 'TRANSFORM' AND UPPER(table_schema) = 'RCA' AND UPPER(table_name) = 'TRANSACTION'
) c ON UPPER(TRIM(s.field_name)) = c.ucol
WHERE c.ucol IS NULL
ORDER BY s.field_name;
*/

-- RC-H) OPTIONAL — inverse: physical columns not in seed (detect MSCI adds). Requires same seed table as RC-G2.
/*
SELECT c.column_name
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN <YOUR_SEED_DB>.<YOUR_SEED_SCHEMA>.RCA_TRANSACTION_FIELD_INVENTORY s
  ON UPPER(TRIM(s.field_name)) = UPPER(c.column_name)
WHERE c.table_catalog = 'TRANSFORM'
  AND UPPER(c.table_schema) = 'RCA'
  AND UPPER(c.table_name) = 'TRANSACTION'
  AND s.field_name IS NULL
ORDER BY c.ordinal_position;
*/

-- RC-I) CLEANED mirror — column parity check (TRANSFORM.RCA is SELECT * from cleaned)
SELECT COUNT(*) AS col_count_transaction_cleaned
FROM TRANSFORM_PROD.INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM_PROD'
  AND UPPER(table_schema) = 'CLEANED'
  AND UPPER(table_name) = 'CLEANED_RCA_TRANSACTION';

SELECT COUNT(*) AS col_count_transaction_transform_rca
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'RCA'
  AND UPPER(table_name) = 'TRANSACTION';

-- RC-J) Investor / lender key non-null spot checks (plan §5.3–5.4)
SELECT
    COUNT(*) AS investor_rows,
    COUNT(*) FILTER (WHERE PRINCIPAL_ENTITY_ID IS NOT NULL) AS n_principal,
    COUNT(*) FILTER (WHERE PROPERTY_ID IS NOT NULL) AS n_property_id
FROM RCA.INVESTOR;

SELECT
    COUNT(*) AS lender_rows,
    COUNT(*) FILTER (WHERE LOAN_ID IS NOT NULL) AS n_loan_id
FROM RCA.LENDER;
