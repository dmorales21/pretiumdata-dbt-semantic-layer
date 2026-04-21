-- Realtor CBSA inventory — confirm **metric_id** slugs vs legacy ``fact_realtor_inventory_cbsa`` contract.
-- Run in Snowflake, e.g. ``snowsql -c pretium -f scripts/sql/validation/realtor_inventory_cbsa_metric_id_parity.sql``.
-- (``-c pretium`` is the **snowsql** connection name; dbt uses ``--target dev`` / ``staging`` from ``~/.dbt/profiles.yml``.)
-- Edit **WAREHOUSE** and legacy FQN if your account still uses a different path than ``TRANSFORM_PROD.FACT``.
--
-- Expect: rows for **MEDIAN_DAYS_ON_MARKET** and **ACTIVE_LISTING_COUNT**; row counts should match legacy when the
--   SOURCE_PROD.REALTOR landing matches pretium-ai-dbt ``cleaned_realtor_inventory_cbsa`` inputs.

-- USE WAREHOUSE COMPUTE_WH;

WITH sem AS (
    SELECT
        metric_id,
        COUNT(*) AS n_rows,
        COUNT(DISTINCT geo_id) AS n_cbsa,
        MIN(date_reference) AS min_dt,
        MAX(date_reference) AS max_dt
    FROM TRANSFORM.DEV.FACT_REALTOR_INVENTORY_CBSA
    WHERE metric_id IN ('MEDIAN_DAYS_ON_MARKET', 'ACTIVE_LISTING_COUNT')
    GROUP BY 1
),
leg AS (
    SELECT
        metric_id,
        COUNT(*) AS n_rows,
        COUNT(DISTINCT geo_id) AS n_cbsa,
        MIN(date_reference) AS min_dt,
        MAX(date_reference) AS max_dt
    FROM TRANSFORM_PROD.FACT.FACT_REALTOR_INVENTORY_CBSA
    WHERE metric_id IN ('MEDIAN_DAYS_ON_MARKET', 'ACTIVE_LISTING_COUNT')
    GROUP BY 1
)
SELECT
    COALESCE(sem.metric_id, leg.metric_id) AS metric_id,
    sem.n_rows AS semantic_n_rows,
    leg.n_rows AS legacy_n_rows,
    sem.n_rows - leg.n_rows AS row_diff,
    sem.n_cbsa AS semantic_n_cbsa,
    leg.n_cbsa AS legacy_n_cbsa,
    sem.min_dt AS semantic_min_dt,
    leg.min_dt AS legacy_min_dt,
    sem.max_dt AS semantic_max_dt,
    leg.max_dt AS legacy_max_dt
FROM sem
FULL OUTER JOIN leg
    ON sem.metric_id = leg.metric_id
ORDER BY 1;
