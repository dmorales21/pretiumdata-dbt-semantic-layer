{#-
  Singular test: returns one row per violated **MET_*** check aligned to `metric.csv`.
  **Passes when zero rows.** Tag: `catalog_metric_statistical`.

  **MET_029–MET_040** (Progress fund spine / acquisition UW): deferred — models are `enabled` only when
  `transform_dev_enable_source_entity_progress_facts` is true and SFDC column names are org-specific.
  Validate those in a follow-up once `CONCEPT_PROGRESS_*` column inventory is frozen.

  Bounds = screening (NaN, exploded magnitudes, obvious unit errors), not full IC econometrics.
-#}
{{ config(
    tags=['catalog_metric_statistical', 'qa'],
) }}

WITH

-- MET_001 BPS VALUE finite
v_met_001 AS (
    SELECT 'MET_001' AS metric_id, 'bps_permits_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bps_permits_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),

-- MET_002–005 BLS LAUS county
v_met_002 AS (
    SELECT 'MET_002' AS metric_id, 'bls_laus_unemployment_rate_pct_0_100' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_laus_county') }}
    WHERE measure_code = 3
      AND value IS NOT NULL
      AND (value < 0 OR value > 100)
),
v_met_003 AS (
    SELECT 'MET_003' AS metric_id, 'bls_laus_unemployed_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_laus_county') }}
    WHERE measure_code = 4 AND value IS NOT NULL AND value < 0
),
v_met_004 AS (
    SELECT 'MET_004' AS metric_id, 'bls_laus_employment_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_laus_county') }}
    WHERE measure_code = 5 AND value IS NOT NULL AND value < 0
),
v_met_005 AS (
    SELECT 'MET_005' AS metric_id, 'bls_laus_labor_force_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_laus_county') }}
    WHERE measure_code = 6 AND value IS NOT NULL AND value < 0
),

-- MET_006 LODES OD BG
v_met_006 AS (
    SELECT 'MET_006' AS metric_id, 'lodes_jobs_total_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_lodes_od_bg') }}
    WHERE jobs_total IS NOT NULL AND jobs_total < 0
),

-- MET_007–008 HUD (Cybersyn HUD housing timeseries)
v_met_007 AS (
    SELECT 'MET_007' AS metric_id, 'hud_county_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_hud_housing_series_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_008 AS (
    SELECT 'MET_008' AS metric_id, 'hud_cbsa_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_hud_housing_series_cbsa') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),

-- MET_009–012 IRS migration (Cybersyn IRS SOI long-form VALUE)
v_met_009 AS (
    SELECT 'MET_009' AS metric_id, 'irs_migration_characteristic_county_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_irs_soi_migration_by_characteristic_annual_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_010 AS (
    SELECT 'MET_010' AS metric_id, 'irs_od_migration_county_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_irs_soi_origin_destination_migration_annual_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_011 AS (
    SELECT 'MET_011' AS metric_id, 'irs_migration_characteristic_cbsa_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_irs_soi_migration_by_characteristic_annual_cbsa') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_012 AS (
    SELECT 'MET_012' AS metric_id, 'irs_od_migration_cbsa_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_irs_soi_origin_destination_migration_annual_cbsa') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),

-- MET_013–019 FHFA long-form (Cybersyn-backed US_REAL_ESTATE; county/CBSA slices)
v_met_013 AS (
    SELECT 'MET_013' AS metric_id, 'fhfa_house_price_county_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_fhfa_house_price_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_014 AS (
    SELECT 'MET_014' AS metric_id, 'fhfa_house_price_cbsa_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_fhfa_house_price_cbsa') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_015 AS (
    SELECT 'MET_015' AS metric_id, 'fhfa_mortgage_perf_county_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_fhfa_mortgage_performance_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_016 AS (
    SELECT 'MET_016' AS metric_id, 'fhfa_mortgage_perf_cbsa_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_fhfa_mortgage_performance_cbsa') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_017 AS (
    SELECT 'MET_017' AS metric_id, 'fhfa_uniform_appraisal_county_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_fhfa_uniform_appraisal_county') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),
v_met_018 AS (
    SELECT 'MET_018' AS metric_id, 'fhfa_uniform_appraisal_cbsa_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_fhfa_uniform_appraisal_cbsa') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),

-- MET_019 Freddie Mac housing (national weekly)
v_met_019 AS (
    SELECT 'MET_019' AS metric_id, 'freddie_mac_housing_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_freddie_mac_housing_national_weekly') }}
    WHERE value IS NOT NULL AND (value != value OR abs(value) > 1e18)
),

-- MET_020–023 QCEW
v_met_020 AS (
    SELECT 'MET_020' AS metric_id, 'qcew_employment_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_qcew_county_naics_quarterly') }}
    WHERE employment IS NOT NULL AND employment < 0
),
v_met_021 AS (
    SELECT 'MET_021' AS metric_id, 'qcew_total_wages_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_qcew_county_naics_quarterly') }}
    WHERE total_wages IS NOT NULL AND total_wages < 0
),
v_met_022 AS (
    SELECT 'MET_022' AS metric_id, 'qcew_establishments_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_qcew_county_naics_quarterly') }}
    WHERE establishments IS NOT NULL AND establishments < 0
),
v_met_023 AS (
    SELECT 'MET_023' AS metric_id, 'qcew_avg_weekly_wage_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_bls_qcew_county_naics_quarterly') }}
    WHERE avg_weekly_wage IS NOT NULL AND avg_weekly_wage < 0
),

-- MET_024 Epoch crosswalk
v_met_024 AS (
    SELECT 'MET_024' AS metric_id, 'epoch_exposure_weight_unit_interval' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('ref_epoch_to_gwa_crosswalk') }}
    WHERE exposure_weight IS NOT NULL
      AND (exposure_weight < 0 OR exposure_weight > 1 OR exposure_weight != exposure_weight)
),

-- MET_025–027 O*NET stack
v_met_025 AS (
    SELECT 'MET_025' AS metric_id, 'onet_gwa_activity_risk_reasonable' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_dol_onet_soc_gwa_activity_risk') }}
    WHERE gwa_activity_risk_score IS NOT NULL
      AND (gwa_activity_risk_score < -1 OR gwa_activity_risk_score > 1e6 OR gwa_activity_risk_score != gwa_activity_risk_score)
),
v_met_026 AS (
    SELECT 'MET_026' AS metric_id, 'onet_friction_index_unit_interval' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_dol_onet_soc_context_friction') }}
    WHERE friction_index IS NOT NULL
      AND (friction_index < -0.001 OR friction_index > 1.001 OR friction_index != friction_index)
),
v_met_027 AS (
    SELECT 'MET_027' AS metric_id, 'onet_friction_adjusted_exposure_reasonable' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_dol_onet_soc_ai_exposure') }}
    WHERE friction_adjusted_exposure IS NOT NULL
      AND (friction_adjusted_exposure < -1 OR friction_adjusted_exposure > 1e6 OR friction_adjusted_exposure != friction_adjusted_exposure)
),

-- MET_028 county × SOC employment (model already filters > 0; still guard negatives if rule changes)
v_met_028 AS (
    SELECT 'MET_028' AS metric_id, 'county_soc_estimated_employment_non_negative' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_county_soc_employment') }}
    WHERE estimated_employment IS NOT NULL AND estimated_employment < 0
),

-- MET_041–043 Zillow long-form metric_value
v_met_041 AS (
    SELECT 'MET_041' AS metric_id, 'zillow_rentals_metric_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_zillow_rentals') }}
    WHERE metric_value IS NOT NULL
      AND try_to_double(to_varchar(metric_value)) IS NOT NULL
      AND (abs(try_to_double(to_varchar(metric_value))) > 1e18
           OR try_to_double(to_varchar(metric_value)) != try_to_double(to_varchar(metric_value)))
),
v_met_042 AS (
    SELECT 'MET_042' AS metric_id, 'zillow_dom_metric_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_zillow_days_on_market_and_price_cuts') }}
    WHERE metric_value IS NOT NULL
      AND try_to_double(to_varchar(metric_value)) IS NOT NULL
      AND (abs(try_to_double(to_varchar(metric_value))) > 1e18
           OR try_to_double(to_varchar(metric_value)) != try_to_double(to_varchar(metric_value)))
),
v_met_043 AS (
    SELECT 'MET_043' AS metric_id, 'zillow_for_sale_listings_metric_value_finite' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_zillow_for_sale_listings') }}
    WHERE metric_value IS NOT NULL
      AND try_to_double(to_varchar(metric_value)) IS NOT NULL
      AND (abs(try_to_double(to_varchar(metric_value))) > 1e18
           OR try_to_double(to_varchar(metric_value)) != try_to_double(to_varchar(metric_value)))
),

-- MET_044–048 (Markerr / Yardi / CoStar WL_020 read-throughs): see
-- `assert_metric_bounds_wl020_readthrough_metrics.sql` (gated on `semantic_layer_qa_transform_dev_bound_tests`).

combined AS (
    SELECT * FROM v_met_001
    UNION ALL SELECT * FROM v_met_002
    UNION ALL SELECT * FROM v_met_003
    UNION ALL SELECT * FROM v_met_004
    UNION ALL SELECT * FROM v_met_005
    UNION ALL SELECT * FROM v_met_006
    UNION ALL SELECT * FROM v_met_007
    UNION ALL SELECT * FROM v_met_008
    UNION ALL SELECT * FROM v_met_009
    UNION ALL SELECT * FROM v_met_010
    UNION ALL SELECT * FROM v_met_011
    UNION ALL SELECT * FROM v_met_012
    UNION ALL SELECT * FROM v_met_013
    UNION ALL SELECT * FROM v_met_014
    UNION ALL SELECT * FROM v_met_015
    UNION ALL SELECT * FROM v_met_016
    UNION ALL SELECT * FROM v_met_017
    UNION ALL SELECT * FROM v_met_018
    UNION ALL SELECT * FROM v_met_019
    UNION ALL SELECT * FROM v_met_020
    UNION ALL SELECT * FROM v_met_021
    UNION ALL SELECT * FROM v_met_022
    UNION ALL SELECT * FROM v_met_023
    UNION ALL SELECT * FROM v_met_024
    UNION ALL SELECT * FROM v_met_025
    UNION ALL SELECT * FROM v_met_026
    UNION ALL SELECT * FROM v_met_027
    UNION ALL SELECT * FROM v_met_028
    UNION ALL SELECT * FROM v_met_041
    UNION ALL SELECT * FROM v_met_042
    UNION ALL SELECT * FROM v_met_043
)

SELECT metric_id, check_name, violation_rows
FROM combined
WHERE violation_rows > 0
