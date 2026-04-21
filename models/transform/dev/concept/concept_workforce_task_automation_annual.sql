{#-
  **Automation / workforce AI exposure** — annual anchors from **FACT_COUNTY_AI_REPLACEMENT_RISK**
  (BLS QCEW × O*NET × Epoch stack; see ``MET_120`` / ``MET_125`` / ``MET_126``).

  - **County** — ``month_start`` = Dec 31 of ``data_year`` on the fact (falls back to ``vars.concept_automation_reference_year`` when null).
    ``automation_current`` = ``COMBINED_RISK_SCORE``; ``automation_historical`` = prior ``data_year`` row on same ``county_fips``.

  - **CBSA** — population-weighted roll-up of county scores using ``total_employment`` as weight (excludes counties with null combined score).

  **National** — single row: employment-weighted mean of county ``deployment_adjusted_exposure`` (same anchor year as county slice).

  O*NET SOC-level ``FACT_DOL_ONET_SOC_AI_EXPOSURE`` is registered under ``MET_027`` at national grain per catalog; this mart focuses on **county / CBSA** outcomes from the replacement-risk fact.
-#}

{{ config(
    materialized='table',
    alias='concept_workforce_task_automation_annual',
    tags=['semantic', 'concept', 'automation', 'bls', 'onet', 'labor'],
) }}

{% set _fallback_yr = var('concept_automation_reference_year', 2024) | int %}

WITH county_base AS (
    SELECT
        COALESCE(TRY_TO_NUMBER(NULLIF(TRIM(f.data_year::VARCHAR), '')), {{ _fallback_yr }}) AS data_year,
        DATE_FROM_PARTS(COALESCE(TRY_TO_NUMBER(NULLIF(TRIM(f.data_year::VARCHAR), '')), {{ _fallback_yr }}), 12, 31)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.county_fips)), 5, '0') AS county_fips,
        LPAD(TRIM(TO_VARCHAR(f.state_fips)), 2, '0') AS state_fips,
        LPAD(TRIM(TO_VARCHAR(f.cbsa_id)), 5, '0') AS cbsa_id,
        TRY_TO_DOUBLE(TO_VARCHAR(f.combined_risk_score)) AS combined_risk_score,
        TRY_TO_DOUBLE(TO_VARCHAR(f.deployment_adjusted_exposure)) AS deployment_adjusted_exposure,
        TRY_TO_DOUBLE(TO_VARCHAR(f.total_employment)) AS total_employment
    FROM {{ ref('fact_county_ai_replacement_risk') }} AS f
    WHERE f.county_fips IS NOT NULL
),

county_scored AS (
    SELECT
        c.month_start,
        c.county_fips,
        c.state_fips,
        c.cbsa_id,
        'county_ai_replacement_risk_combined_score' AS metric_id_observe,
        c.combined_risk_score AS metric_value,
        c.deployment_adjusted_exposure,
        c.total_employment
    FROM county_base AS c
    WHERE c.combined_risk_score IS NOT NULL
),

county_out AS (
    SELECT
        'automation' AS concept_code,
        'BLS_QCEW_ONET_EPOCH' AS vendor_code,
        c.month_start,
        'county' AS geo_level_code,
        c.county_fips AS geo_id,
        CAST(NULL AS VARCHAR(5)) AS cbsa_id,
        c.county_fips,
        c.state_fips,
        FALSE AS has_census_geo,
        CAST(NULL AS VARCHAR(128)) AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('automation', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('automation', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('automation', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM county_scored AS c
    LEFT JOIN county_scored AS h
        ON c.county_fips = h.county_fips
       AND h.month_start = DATEADD('year', -1, c.month_start)
),

cbsa_agg AS (
    SELECT
        month_start,
        cbsa_id,
        SUM(metric_value * NULLIF(total_employment, 0))
            / NULLIF(SUM(NULLIF(total_employment, 0)), 0) AS wavg_combined,
        SUM(
            deployment_adjusted_exposure * NULLIF(total_employment, 0)
        ) / NULLIF(SUM(NULLIF(total_employment, 0)), 0) AS wavg_deployment
    FROM county_scored
    WHERE cbsa_id IS NOT NULL
      AND LENGTH(TRIM(cbsa_id)) > 0
    GROUP BY month_start, cbsa_id
),

cbsa_out AS (
    SELECT
        'automation' AS concept_code,
        'BLS_QCEW_ONET_EPOCH_CBSA' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        FALSE AS has_census_geo,
        CAST(NULL AS VARCHAR(128)) AS census_geo_source,
        'cbsa_employment_weighted_mean_combined_risk' AS metric_id_observe,
        CAST(c.wavg_combined AS DOUBLE) AS {{ concept_metric_slot('automation', 'current') }},
        CAST(h.wavg_combined AS DOUBLE) AS {{ concept_metric_slot('automation', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('automation', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM cbsa_agg AS c
    LEFT JOIN cbsa_agg AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = DATEADD('year', -1, c.month_start)
),

national_slice AS (
    SELECT
        month_start,
        SUM(deployment_adjusted_exposure * NULLIF(total_employment, 0))
            / NULLIF(SUM(NULLIF(total_employment, 0)), 0) AS nat_mean_deployment,
        SUM(metric_value * NULLIF(total_employment, 0))
            / NULLIF(SUM(NULLIF(total_employment, 0)), 0) AS nat_mean_combined
    FROM county_scored
    GROUP BY month_start
),

national_out AS (
    SELECT
        'automation' AS concept_code,
        'BLS_QCEW_ONET_EPOCH_NATIONAL' AS vendor_code,
        n.month_start,
        'national' AS geo_level_code,
        'US' AS geo_id,
        CAST(NULL AS VARCHAR(5)) AS cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        FALSE AS has_census_geo,
        CAST(NULL AS VARCHAR(128)) AS census_geo_source,
        'national_employment_weighted_mean_combined_risk' AS metric_id_observe,
        CAST(n.nat_mean_combined AS DOUBLE) AS {{ concept_metric_slot('automation', 'current') }},
        CAST(h.nat_mean_combined AS DOUBLE) AS {{ concept_metric_slot('automation', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('automation', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM national_slice AS n
    LEFT JOIN national_slice AS h
        ON h.month_start = DATEADD('year', -1, n.month_start)
)

SELECT * FROM county_out
UNION ALL
SELECT * FROM cbsa_out
UNION ALL
SELECT * FROM national_out
