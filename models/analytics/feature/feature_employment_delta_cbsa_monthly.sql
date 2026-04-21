-- FEATURE: CBSA employment momentum from BLS LAUS (county roll-up to OMB CBSA).
-- Migration target for pretium-ai-dbt `feature_economic_momentum_cbsa.sql` (MIGRATION_PLAN.md Layer 2).
-- Legacy combined QCEW wages + LAUS; this v1 implements **LAUS-only** employment YoY and CBSA unemployment
-- from summed county unemployed / labor force (measure codes 4 / 6). `wage_growth_yoy_pct` reserved for a
-- future QCEW / CONCEPT join — null for now.
--
-- Upstream: `ref('fact_bls_laus_county')` (TRANSFORM.BLS.LAUS_COUNTY), `REFERENCE.GEOGRAPHY.county_cbsa_xwalk`.
--
-- **Lineage note (Phase B):** ``concept_employment_market_monthly`` is the **observe** CBSA panel; this FEATURE implements
-- **county LAUS → CBSA roll** YoY deltas and derived unemployment rate. Keeping **FACT** at county grain is intentional
-- until the same logic is folded behind a concept or thin FEATURE-on-concept helper — see ``QA_CONCEPT_PREFLIGHT_CHECKLIST.md`` §C.

{{ config(
    materialized='view',
    alias='feature_employment_delta_cbsa_monthly',
    tags=['analytics', 'feature', 'bls', 'laus', 'labor', 'cbsa', 'migration_layer2'],
) }}

WITH laus AS (
    SELECT
        date_reference,
        lpad(trim(county_fips::varchar), 5, '0') AS county_fips,
        measure_code,
        value::double AS value
    FROM {{ ref('fact_bls_laus_county') }}
    WHERE county_fips IS NOT NULL
      AND measure_code IN (3, 4, 5, 6)
      AND value IS NOT NULL
),

county_month AS (
    SELECT
        county_fips,
        date_reference,
        max(CASE WHEN measure_code = 3 THEN value END) AS unemployment_rate,
        max(CASE WHEN measure_code = 4 THEN value END) AS unemployed,
        max(CASE WHEN measure_code = 5 THEN value END) AS employment,
        max(CASE WHEN measure_code = 6 THEN value END) AS labor_force
    FROM laus
    GROUP BY 1, 2
),

primary_county_cbsa AS (
    SELECT
        county_fips,
        id_cbsa AS cbsa_code
    FROM (
        SELECT
            lpad(trim(to_varchar(x.county_fips)), 5, '0') AS county_fips,
            lpad(trim(to_varchar(x.cbsa_code)), 5, '0') AS id_cbsa,
            row_number() OVER (
                PARTITION BY lpad(trim(to_varchar(x.county_fips)), 5, '0')
                ORDER BY
                    CASE WHEN x.cbsa_code IS NULL THEN 1 ELSE 0 END,
                    trim(to_varchar(x.cbsa_name)) ASC NULLS LAST,
                    lpad(trim(to_varchar(x.cbsa_code)), 5, '0') ASC NULLS LAST
            ) AS rn
        FROM {{ source('reference_geography', 'county_cbsa_xwalk') }} AS x
        WHERE x.year = {{ reference_geography_year() }}
          AND x.county_fips IS NOT NULL
    ) AS z
    WHERE rn = 1
      AND id_cbsa IS NOT NULL
      AND county_fips != id_cbsa
),

cbsa_month AS (
    SELECT
        p.cbsa_code AS geo_id,
        'CBSA' AS geo_level_code,
        m.date_reference,
        sum(m.employment) AS employment,
        sum(m.unemployed) AS unemployed,
        sum(m.labor_force) AS labor_force,
        round(
            sum(m.unemployed) / nullif(sum(m.labor_force), 0) * 100.0,
            2
        ) AS unemployment_rate
    FROM county_month AS m
    INNER JOIN primary_county_cbsa AS p ON p.county_fips = m.county_fips
    WHERE m.employment IS NOT NULL
    GROUP BY p.cbsa_code, m.date_reference
),

with_yoy AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        employment,
        unemployed,
        labor_force,
        unemployment_rate,
        lag(employment, 12) OVER (
            PARTITION BY geo_id
            ORDER BY date_reference
        ) AS employment_prior_year
    FROM cbsa_month
)

SELECT
    geo_id,
    geo_level_code,
    date_reference,
    cast(null AS number(18, 4)) AS wage_growth_yoy_pct,
    CASE
        WHEN employment_prior_year > 0
            THEN round((employment - employment_prior_year) / employment_prior_year * 100.0, 2)
    END AS employment_growth_yoy_pct,
    unemployment_rate,
    round(
        CASE
            WHEN employment_prior_year > 0
                THEN (employment - employment_prior_year) / employment_prior_year * 100.0
        END,
        4
    ) AS composite_raw,
    employment AS employment_level
FROM with_yoy
WHERE employment IS NOT NULL
