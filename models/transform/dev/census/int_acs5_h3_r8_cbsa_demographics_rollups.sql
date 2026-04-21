-- CBSA rollups from ``fact_census_acs5_h3_r8_snapshot`` (H3 R8 × CBSA ACS snapshot).
-- Population-weighted LFPR; HH-weighted median HHI wavg; summed population wavg as CBSA population proxy.
-- Vacancy **share** rollups: population-weighted blend of hex-level shares (approximation vs housing-unit weighting).
-- Feeds ``concept_*_market_annual`` and ``concept_vacancy_market_monthly`` (ACS branch).
{{ config(
    materialized='table',
    alias='int_acs5_h3_r8_cbsa_demographics_rollups',
    tags=['transform', 'transform_dev', 'census', 'acs', 'intermediate'],
) }}

SELECT
    LPAD(TRIM(TO_VARCHAR(f.cbsa_id)), 5, '0') AS cbsa_id,
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
        / NULLIF(SUM(NULLIF(f.total_population_wavg, 0)), 0) AS for_sale_vacant_share_wavg
FROM {{ ref('fact_census_acs5_h3_r8_snapshot') }} AS f
WHERE f.cbsa_id IS NOT NULL
  AND TRIM(TO_VARCHAR(f.cbsa_id)) <> ''
GROUP BY 1
