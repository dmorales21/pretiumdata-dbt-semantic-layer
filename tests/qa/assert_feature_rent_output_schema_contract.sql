-- Slug: **schema_evolution_guard** (15) — bidirectional column-name diff for **FEATURE_RENT_MARKET_MONTHLY** vs frozen contract.
{{ config(severity='error') }}

WITH expected AS (
    SELECT 'CONCEPT_CODE' AS column_name
    UNION ALL SELECT 'VENDOR_CODE'
    UNION ALL SELECT 'MONTH_START'
    UNION ALL SELECT 'GEO_LEVEL_CODE'
    UNION ALL SELECT 'GEO_ID'
    UNION ALL SELECT 'CBSA_ID'
    UNION ALL SELECT 'COUNTY_FIPS'
    UNION ALL SELECT 'STATE_FIPS'
    UNION ALL SELECT 'RENT_CURRENT'
    UNION ALL SELECT 'RENT_HISTORICAL'
    UNION ALL SELECT 'RENT_FORECAST'
    UNION ALL SELECT 'METRIC_ID_OBSERVE'
    UNION ALL SELECT 'METRIC_ID_FORECAST'
    UNION ALL SELECT 'FORECAST_MONTH_START'
),

actual AS (
    SELECT UPPER(TRIM(TO_VARCHAR(column_name))) AS column_name
    FROM {{ target.database }}.INFORMATION_SCHEMA.COLUMNS
    WHERE UPPER(TRIM(table_catalog)) = UPPER(TRIM('{{ target.database }}'))
      AND UPPER(TRIM(table_schema)) = UPPER(TRIM('{{ target.schema }}'))
      AND UPPER(TRIM(table_name)) = UPPER('FEATURE_RENT_MARKET_MONTHLY')
),

missing_in_actual AS (
    SELECT e.column_name, 'MISSING_IN_SNOWFLAKE_RELATION' AS drift_kind
    FROM expected AS e
    WHERE NOT EXISTS (SELECT 1 FROM actual AS a WHERE a.column_name = e.column_name)
),

unexpected_in_actual AS (
    SELECT a.column_name, 'UNEXPECTED_EXTRA_COLUMN' AS drift_kind
    FROM actual AS a
    WHERE NOT EXISTS (SELECT 1 FROM expected AS e WHERE e.column_name = a.column_name)
)

SELECT * FROM missing_in_actual
UNION ALL
SELECT * FROM unexpected_in_actual
