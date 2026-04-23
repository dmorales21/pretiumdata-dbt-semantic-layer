{{ config(
    materialized='table',
    alias='concept_migration_market_annual',
    tags=['semantic', 'concept', 'migration', 'irs', 'cybersyn']
) }}

{% set _by_char_rx = var('concept_migration_market_by_characteristic_variable_regex', 'migration|return|inflow|outflow') | replace("'", "''") %}

WITH by_char_cbsa AS (
    SELECT
        DATE_TRUNC('year', f.date_reference)::DATE AS year_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_irs_soi_migration_by_characteristic_annual_cbsa') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _by_char_rx }}')
),

by_char_county_to_cbsa AS (
    SELECT
        DATE_TRUNC('year', f.date_reference)::DATE AS year_start,
        LPAD(TRIM(TO_VARCHAR(gl.cbsa_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        AVG(TRY_TO_DOUBLE(TO_VARCHAR(f.value))) AS metric_value
    FROM {{ ref('fact_irs_soi_migration_by_characteristic_annual_county') }} AS f
    INNER JOIN {{ ref('geography_latest') }} AS gl
        ON LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') = LPAD(TRIM(TO_VARCHAR(gl.geo_id)), 5, '0')
       AND LOWER(gl.geo_level_code) = 'county'
       AND gl.cbsa_id IS NOT NULL
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _by_char_rx }}')
    GROUP BY
        DATE_TRUNC('year', f.date_reference)::DATE,
        LPAD(TRIM(TO_VARCHAR(gl.cbsa_id)), 5, '0'),
        TRIM(TO_VARCHAR(f.variable))
),

migration_union AS (
    SELECT 'IRS_BY_CHARACTERISTIC_CBSA' AS vendor_code, * FROM by_char_cbsa
    UNION ALL
    SELECT 'IRS_BY_CHARACTERISTIC_COUNTY_ROLLUP' AS vendor_code, * FROM by_char_county_to_cbsa
),

migration_pick AS (
    SELECT
        vendor_code,
        year_start,
        cbsa_id,
        metric_id_observe,
        metric_value
    FROM migration_union
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY vendor_code, year_start, cbsa_id
        ORDER BY metric_id_observe
    ) = 1
),

by_char_county_direct AS (
    SELECT
        DATE_TRUNC('year', f.date_reference)::DATE AS year_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS county_fips,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_irs_soi_migration_by_characteristic_annual_county') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _by_char_rx }}')
)

SELECT
    'migration' AS concept_code,
    p.vendor_code,
    p.year_start AS month_start,
    'cbsa' AS geo_level_code,
    p.cbsa_id AS geo_id,
    p.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'irs_migration_county_cbsa_consolidated' AS census_geo_source,
    p.metric_id_observe,
    CAST(p.metric_value AS DOUBLE) AS {{ concept_metric_slot('migration', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('migration', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('migration', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM migration_pick AS p
LEFT JOIN migration_pick AS h
    ON p.vendor_code = h.vendor_code
   AND p.cbsa_id = h.cbsa_id
   AND p.metric_id_observe = h.metric_id_observe
   AND h.year_start = DATEADD('year', -1, p.year_start)

UNION ALL

SELECT
    'migration' AS concept_code,
    'IRS_BY_CHARACTERISTIC_COUNTY' AS vendor_code,
    c.year_start AS month_start,
    'county' AS geo_level_code,
    c.county_fips AS geo_id,
    CAST(NULL AS VARCHAR(5)) AS cbsa_id,
    c.county_fips,
    SUBSTRING(c.county_fips, 1, 2) AS state_fips,
    TRUE AS has_census_geo,
    'fact_irs_soi_migration_by_characteristic_annual_county' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('migration', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('migration', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('migration', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM by_char_county_direct AS c
LEFT JOIN by_char_county_direct AS h
    ON c.county_fips = h.county_fips
   AND c.metric_id_observe = h.metric_id_observe
   AND h.year_start = DATEADD('year', -1, c.year_start)
