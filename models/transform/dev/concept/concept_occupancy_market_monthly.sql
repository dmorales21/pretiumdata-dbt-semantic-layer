{#-
  **Occupancy** — monthly **CBSA** from ``fact_hud_housing_series_cbsa_monthly`` and native **county** rows from
  ``fact_hud_housing_series_county_monthly`` (``vendor_code = HUD_CYBERSYN_COUNTY``).

  - **CBSA spine:** variables matching ``concept_occupancy_market_hud_variable_regex`` (default ``occupancy|vacancy``);
    **one** prioritized ``metric_id_observe`` per ``(month_start, cbsa_id)`` via ``ROW_NUMBER`` (same ranking idea as
    the legacy single-branch model, with the regex applied in ``WHERE`` so the pool is occupancy-like only).

  - **County spine:** all matching HUD county monthly series (multiple ``metric_id_observe`` per county × month),
    aligned with ``concept_vacancy_market_monthly`` county HUD pattern.

  **0 rows** is PASS when the account HUD slice has no series matching the regex. See
  ``docs/migration/QA_CONCEPT_PREFLIGHT_CHECKLIST.md`` §B.
-#}

{{ config(
    materialized='table',
    alias='concept_occupancy_market_monthly',
    tags=['semantic', 'concept', 'occupancy', 'hud']
) }}

{% set _occ_rx = var('concept_occupancy_market_hud_variable_regex', 'occupancy|vacancy') | replace("'", "''") %}

WITH hud_occ_ranked AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', f.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0')
            ORDER BY TRIM(TO_VARCHAR(f.variable))
        ) AS metric_rn
    FROM {{ ref('fact_hud_housing_series_cbsa_monthly') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND f.variable IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _occ_rx }}')
),

hud_occ_pick AS (
    SELECT *
    FROM hud_occ_ranked
    WHERE metric_rn = 1
),

hud_county_direct AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS county_fips,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_hud_housing_series_county_monthly') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND f.variable IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _occ_rx }}')
)

SELECT
    'occupancy' AS concept_code,
    'HUD_CYBERSYN' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_hud_housing_series_cbsa_monthly' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('occupancy', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('occupancy', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('occupancy', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM hud_occ_pick AS c
LEFT JOIN hud_occ_pick AS h
    ON c.cbsa_id = h.cbsa_id
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)

UNION ALL

SELECT
    'occupancy' AS concept_code,
    'HUD_CYBERSYN_COUNTY' AS vendor_code,
    c.month_start,
    'county' AS geo_level_code,
    c.county_fips AS geo_id,
    CAST(NULL AS VARCHAR(5)) AS cbsa_id,
    c.county_fips,
    SUBSTRING(c.county_fips, 1, 2) AS state_fips,
    TRUE AS has_census_geo,
    'fact_hud_housing_series_county_monthly' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('occupancy', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('occupancy', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('occupancy', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM hud_county_direct AS c
LEFT JOIN hud_county_direct AS h
    ON c.county_fips = h.county_fips
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
