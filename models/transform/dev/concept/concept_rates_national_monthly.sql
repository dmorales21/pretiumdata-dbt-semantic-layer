{#-
  **Rates** — monthly **national** spine from Freddie Mac housing / PMMS-style Cybersyn feed.

  ``ref('fact_freddie_mac_housing_national_weekly')`` is weekly-dominant; this mart **month-buckets** rows and keeps the
  **last observation** in each month per ``variable`` (tie-break: latest ``date_reference``).

  Primary series filter: ``vars.concept_rates_freddie_variable_pattern`` (default targets **30-year fixed** PMMS-style names).

  Add FRED / Treasury series later as additional ``vendor_code`` branches once typed ``FACT_*`` exist under **TRANSFORM.DEV**.
-#}

{{ config(
    materialized='table',
    alias='concept_rates_national_monthly',
    tags=['semantic', 'concept', 'rates', 'freddie_mac', 'national'],
) }}

{% set _vrx = var('concept_rates_freddie_variable_pattern', '%PMMS30%') | replace("'", "''") %}

WITH freddie_raw AS (
    SELECT
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(f.date_reference)))::DATE AS month_start,
        TRIM(TO_VARCHAR(f.variable)) AS variable_name,
        TRY_TO_DATE(TO_VARCHAR(f.date_reference)) AS obs_date,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_freddie_mac_housing_national_weekly') }} AS f
    WHERE TRY_TO_DATE(TO_VARCHAR(f.date_reference)) IS NOT NULL
      AND f.value IS NOT NULL
      AND LOWER(TRIM(TO_VARCHAR(f.variable))) LIKE LOWER('{{ _vrx }}')
      AND LOWER(COALESCE(TRIM(TO_VARCHAR(f.geo_level_code)), 'national')) = 'national'
),

freddie_ranked AS (
    SELECT
        month_start,
        variable_name,
        metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY month_start, variable_name
            ORDER BY obs_date DESC
        ) AS rn
    FROM freddie_raw
),

freddie_pick AS (
    SELECT
        month_start,
        variable_name,
        metric_value
    FROM freddie_ranked
    WHERE rn = 1
)

SELECT
    'rates' AS concept_code,
    'FREDDIE_MAC' AS vendor_code,
    c.month_start,
    'national' AS geo_level_code,
    'US' AS geo_id,
    CAST(NULL AS VARCHAR(5)) AS cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    FALSE AS has_census_geo,
    'fact_freddie_mac_housing_national_weekly' AS census_geo_source,
    c.variable_name AS metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('rates', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('rates', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rates', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM freddie_pick AS c
LEFT JOIN freddie_pick AS h
    ON c.variable_name = h.variable_name
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
