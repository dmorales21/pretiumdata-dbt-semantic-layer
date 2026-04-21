{#-
  **Vacancy** — monthly CBSA.

  - **HUD (Cybersyn)** — ``fact_hud_housing_series_cbsa_monthly`` plus county → CBSA rollup via ``geography_latest``
    (same pattern as ``concept_migration_market_annual``). Series filter: ``concept_vacancy_market_hud_variable_regex``
    (default emphasizes **vacancy** / **vacant**, not occupancy-only HUD labels — adjust if your Cybersyn slice differs).

  - **ACS5 H3 snapshot (annual anchor)** — CBSA rollups from ``int_acs5_h3_r8_cbsa_demographics_rollups`` for
    ``total_vacant_share_wavg``, ``vacant_for_rent_share_wavg``, ``for_sale_vacant_share_wavg`` (population-weighted
    hex blend; **Dec 31** of ``concept_acs5_cbsa_reference_year``). These rows are **annual** values keyed on that
    month_start; YoY join uses ``DATEADD(year, -1, month_start)``.

  **Cherre** ``FACT_CHERRE_VACANT_*`` — not shipped as dbt read-throughs in this repo yet; add a branch when models land.

  Vars: ``concept_vacancy_market_hud_variable_regex``, ``concept_acs5_cbsa_reference_year`` (shared with other ACS CBSA concepts).
-#}

{{ config(
    materialized='table',
    alias='concept_vacancy_market_monthly',
    tags=['semantic', 'concept', 'vacancy', 'hud', 'census', 'acs'],
) }}

{% set _hud_rx = var('concept_vacancy_market_hud_variable_regex', 'vacancy|vacant') | replace("'", "''") %}
{% set _yr = var('concept_acs5_cbsa_reference_year', 2024) | int %}

WITH hud_cbsa_base AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_hud_housing_series_cbsa_monthly') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND f.variable IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _hud_rx }}')
),

hud_county_to_cbsa AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(gl.cbsa_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        AVG(TRY_TO_DOUBLE(TO_VARCHAR(f.value))) AS metric_value
    FROM {{ ref('fact_hud_housing_series_county_monthly') }} AS f
    INNER JOIN {{ ref('geography_latest') }} AS gl
        ON LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') = LPAD(TRIM(TO_VARCHAR(gl.geo_id)), 5, '0')
       AND LOWER(gl.geo_level_code) = 'county'
       AND gl.cbsa_id IS NOT NULL
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND f.variable IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _hud_rx }}')
    GROUP BY
        DATE_TRUNC('month', f.date_reference)::DATE,
        LPAD(TRIM(TO_VARCHAR(gl.cbsa_id)), 5, '0'),
        TRIM(TO_VARCHAR(f.variable))
),

hud_union AS (
    SELECT 'HUD_CYBERSYN_CBSA' AS vendor_code, * FROM hud_cbsa_base
    UNION ALL
    SELECT 'HUD_CYBERSYN_COUNTY_ROLLUP' AS vendor_code, * FROM hud_county_to_cbsa
),

acs_vacancy_unpivot AS (
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(r.cbsa_id)), 5, '0') AS cbsa_id,
        'census_acs5_h3_r8_total_vacant_share_wavg' AS metric_id_observe,
        r.total_vacant_share_wavg AS metric_value
    FROM {{ ref('int_acs5_h3_r8_cbsa_demographics_rollups') }} AS r
    WHERE r.total_vacant_share_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(r.cbsa_id)), 5, '0') AS cbsa_id,
        'census_acs5_h3_r8_vacant_for_rent_share_wavg' AS metric_id_observe,
        r.vacant_for_rent_share_wavg AS metric_value
    FROM {{ ref('int_acs5_h3_r8_cbsa_demographics_rollups') }} AS r
    WHERE r.vacant_for_rent_share_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(r.cbsa_id)), 5, '0') AS cbsa_id,
        'census_acs5_h3_r8_for_sale_vacant_share_wavg' AS metric_id_observe,
        r.for_sale_vacant_share_wavg AS metric_value
    FROM {{ ref('int_acs5_h3_r8_cbsa_demographics_rollups') }} AS r
    WHERE r.for_sale_vacant_share_wavg IS NOT NULL
),

acs_vacancy AS (
    SELECT
        'CENSUS_ACS5_H3_CBSA' AS vendor_code,
        u.month_start,
        u.cbsa_id,
        u.metric_id_observe,
        u.metric_value
    FROM acs_vacancy_unpivot AS u
),

vacancy_union AS (
    SELECT * FROM hud_union
    UNION ALL
    SELECT * FROM acs_vacancy
)

SELECT
    'vacancy' AS concept_code,
    v.vendor_code,
    v.month_start,
    'cbsa' AS geo_level_code,
    v.cbsa_id AS geo_id,
    v.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'concept_vacancy_market_monthly_union' AS census_geo_source,
    v.metric_id_observe,
    CAST(v.metric_value AS DOUBLE) AS {{ concept_metric_slot('vacancy', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('vacancy', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('vacancy', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM vacancy_union AS v
LEFT JOIN vacancy_union AS h
    ON v.vendor_code = h.vendor_code
   AND v.cbsa_id = h.cbsa_id
   AND v.metric_id_observe = h.metric_id_observe
   AND h.month_start = CASE
       WHEN v.vendor_code = 'CENSUS_ACS5_H3_CBSA' THEN DATEADD('year', -1, v.month_start)
       ELSE ADD_MONTHS(v.month_start, -12)
   END
