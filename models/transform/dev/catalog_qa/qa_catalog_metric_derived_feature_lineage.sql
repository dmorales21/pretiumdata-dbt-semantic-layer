-- ============================================================================
-- QA — ANALYTICS.DBT_DEV: catalog metric_derived (FEATURE layer) vs Snowflake
-- Purpose: Row-level registration check for active **feature** outputs declared
--          in REFERENCE.CATALOG.metric_derived (seed) against ANALYTICS.INFORMATION_SCHEMA.
-- Contract: Each active `metric_derived` row with analytics_layer_code = feature
--           and data_status_code = active must have a row in `feature_physical_map`
--           (expected Snowflake table name under ANALYTICS.DBT_DEV).
-- When adding MDV_* feature rows: extend `feature_physical_map` in the same PR.
-- Related: qa_catalog_metric_transform_dev_lineage.sql, MODEL_FEATURE_ESTIMATION_PLAYBOOK.md §6.
-- ============================================================================

{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    tags=['transform', 'transform_dev', 'qa', 'catalog', 'catalog_registration'],
) }}

WITH feature_physical_map AS (
    SELECT *
    FROM (
        SELECT 'rent_market_monthly_spine' AS metric_derived_code, 'FEATURE_RENT_MARKET_MONTHLY' AS expected_table_name
        UNION ALL
        SELECT 'listings_velocity_monthly_spine', 'FEATURE_LISTINGS_VELOCITY_MONTHLY'
    ) AS m
),

md AS (
    SELECT
        d.metric_derived_id,
        d.metric_derived_code,
        d.metric_derived_label,
        d.data_status_code,
        d.is_active
    FROM {{ ref('metric_derived') }} AS d
    WHERE LOWER(TRIM(d.analytics_layer_code)) = 'feature'
),

scoped AS (
    SELECT
        m.*,
        map.expected_table_name
    FROM md AS m
    LEFT JOIN feature_physical_map AS map
        ON LOWER(TRIM(map.metric_derived_code)) = LOWER(TRIM(m.metric_derived_code))
    WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
      AND LOWER(TRIM(m.data_status_code)) = 'active'
),

ist AS (
    SELECT
        UPPER(table_catalog) AS table_catalog,
        UPPER(table_schema) AS table_schema,
        UPPER(table_name) AS table_name,
        table_type
    FROM ANALYTICS.INFORMATION_SCHEMA.TABLES
    WHERE UPPER(table_catalog) = 'ANALYTICS'
      AND UPPER(table_schema) = 'DBT_DEV'
      AND table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')
),

chk AS (
    SELECT
        s.*,
        CASE
            WHEN s.expected_table_name IS NULL THEN FALSE
            ELSE EXISTS (
                SELECT 1
                FROM ist AS i
                WHERE i.table_catalog = 'ANALYTICS'
                  AND i.table_schema = 'DBT_DEV'
                  AND i.table_name = s.expected_table_name
            )
        END AS snowflake_object_exists
    FROM scoped AS s
)

SELECT
    metric_derived_id,
    metric_derived_code,
    metric_derived_label,
    expected_table_name,
    snowflake_object_exists,
    CASE
        WHEN expected_table_name IS NULL THEN 'NO_PHYSICAL_MAP'
        WHEN NOT snowflake_object_exists THEN 'MISSING_OBJECT'
        ELSE 'OK'
    END AS qa_status,
    CURRENT_TIMESTAMP() AS qa_built_at
FROM chk
