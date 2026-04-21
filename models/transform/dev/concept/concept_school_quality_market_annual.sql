{#-
  **School quality** — annual **CBSA** spine.

  - **Stanford SEDA** (``ref('fact_stanford_seda_h3_r8_snapshot')``): enrollment-weighted ``school_score_avg`` and ``ses_avg``
    rolled up from H3 hex rows to ``cbsa_id``. ``month_start`` = Dec 31 of ``vars.concept_acs5_cbsa_reference_year`` (shared ACS anchor).

  - **ACS5 H3 snapshot** (``ref('fact_census_acs5_h3_r8_snapshot')``): population-weighted ``school_age_share`` and ``bachelors_plus_share``
    (demand / attainment context — not SEDA achievement). Disable: ``vars.concept_school_quality_include_acs_branch: false``.
-#}

{{ config(
    materialized='table',
    alias='concept_school_quality_market_annual',
    tags=['semantic', 'concept', 'school_quality', 'stanford', 'census', 'acs'],
) }}

{% set _yr = var('concept_acs5_cbsa_reference_year', 2024) | int %}
{% set _acs = var('concept_school_quality_include_acs_branch', true) %}

WITH stanford_cbsa AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(f.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(COALESCE(f.school_score_avg, 0) * NULLIF(f.hex_total_enrollment, 0))
            / NULLIF(
                SUM(IFF(f.school_score_avg IS NOT NULL, f.hex_total_enrollment, 0)),
                0
            ) AS school_score_wavg,
        SUM(COALESCE(f.ses_avg, 0) * NULLIF(f.hex_total_enrollment, 0))
            / NULLIF(
                SUM(IFF(f.ses_avg IS NOT NULL, f.hex_total_enrollment, 0)),
                0
            ) AS ses_wavg
    FROM {{ ref('fact_stanford_seda_h3_r8_snapshot') }} AS f
    WHERE f.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(f.cbsa_id)) <> ''
    GROUP BY 1
),

stanford_long AS (
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'stanford_seda_school_score_wavg_cbsa' AS metric_id_observe,
        school_score_wavg AS metric_value
    FROM stanford_cbsa
    WHERE school_score_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'stanford_seda_ses_wavg_cbsa' AS metric_id_observe,
        ses_wavg AS metric_value
    FROM stanford_cbsa
    WHERE ses_wavg IS NOT NULL
),

stanford_out AS (
    SELECT
        'school_quality' AS concept_code,
        'STANFORD_SEDA' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_stanford_seda_h3_r8_snapshot' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('school_quality', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('school_quality', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('school_quality', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM stanford_long AS c
    LEFT JOIN stanford_long AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = DATEADD('year', -1, c.month_start)
),

{% if _acs %}
acs_cbsa AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(f.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(COALESCE(f.school_age_share, 0) * NULLIF(f.total_population_wavg, 0))
            / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS school_age_share_wavg,
        SUM(COALESCE(f.bachelors_plus_share, 0) * NULLIF(f.total_population_wavg, 0))
            / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS bachelors_plus_share_wavg
    FROM {{ ref('fact_census_acs5_h3_r8_snapshot') }} AS f
    WHERE f.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(f.cbsa_id)) <> ''
    GROUP BY 1
),

acs_long AS (
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'acs5_h3_school_age_share_wavg_cbsa' AS metric_id_observe,
        school_age_share_wavg AS metric_value
    FROM acs_cbsa
    WHERE school_age_share_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'acs5_h3_bachelors_plus_share_wavg_cbsa' AS metric_id_observe,
        bachelors_plus_share_wavg AS metric_value
    FROM acs_cbsa
    WHERE bachelors_plus_share_wavg IS NOT NULL
),

acs_out AS (
    SELECT
        'school_quality' AS concept_code,
        'CENSUS_ACS5_H3_CBSA' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_census_acs5_h3_r8_snapshot' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('school_quality', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('school_quality', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('school_quality', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM acs_long AS c
    LEFT JOIN acs_long AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = DATEADD('year', -1, c.month_start)
)
{% endif %}

SELECT * FROM stanford_out
{% if _acs %}
UNION ALL
SELECT * FROM acs_out
{% endif %}
