-- County rollups from ``fact_census_acs5_h3_r8_snapshot``: each H3 hex assigned to a **dominant** county via
-- ``int_h3_r8_hex_dominant_county`` (BG polyfill weights). Same weighted formulas as
-- ``int_acs5_h3_r8_cbsa_demographics_rollups`` plus ACS school-age / bachelor's shares (population-weighted).
-- Feeds ``concept_*_market_annual`` (county arms), ``concept_vacancy_market_monthly`` (ACS county), and
-- ``concept_school_quality_market_annual`` (ACS county) when enabled.
{{ config(
    materialized='table',
    alias='int_acs5_h3_r8_county_demographics_rollups',
    tags=['transform', 'transform_dev', 'census', 'acs', 'intermediate'],
) }}

SELECT
    dc.county_fips,
    SUM(COALESCE(f.labor_force_participation_rate, 0) * NULLIF(f.total_population_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS labor_force_participation_rate_wavg,
    SUM(COALESCE(f.median_hhi_wavg, 0) * NULLIF(f.total_hh_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_hh_wavg, 0)), 0) AS median_hhi_wavg,
    SUM(COALESCE(f.total_population_wavg, 0)) AS total_population_wavg_sum,
    SUM(COALESCE(f.total_vacant_share, 0) * NULLIF(f.total_population_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS total_vacant_share_wavg,
    SUM(COALESCE(f.vacant_for_rent_share, 0) * NULLIF(f.total_population_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS vacant_for_rent_share_wavg,
    SUM(COALESCE(f.for_sale_vacant_share, 0) * NULLIF(f.total_population_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS for_sale_vacant_share_wavg,
    SUM(COALESCE(f.school_age_share, 0) * NULLIF(f.total_population_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS school_age_share_wavg,
    SUM(COALESCE(f.bachelors_plus_share, 0) * NULLIF(f.total_population_wavg, 0))
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS bachelors_plus_share_wavg
FROM {{ ref('fact_census_acs5_h3_r8_snapshot') }} AS f
INNER JOIN {{ ref('int_h3_r8_hex_dominant_county') }} AS dc
    ON TRIM(TO_VARCHAR(f.h3_r8_hex)) = dc.h3_r8_hex
WHERE dc.county_fips IS NOT NULL
  AND TRIM(dc.county_fips) <> ''
GROUP BY 1
