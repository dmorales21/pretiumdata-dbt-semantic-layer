# TRANSFORM.DEV Fact Gap Wave Queue (Non-duplicative)

Owner: Alex  
Status: active queue  
Scope: legacy gap list normalized to canonical semantic-layer rules.

## Operating rule (binding)

For each backlog item, execute in this order:

1. Build `fact_[dataset]` in `models/transform/dev/...`
2. Register/refresh `metric.csv` rows with `table_path = TRANSFORM.DEV.FACT_*`
3. Build/refresh `concept_[concept]` sorted rollups from the approved fact metrics

Do not add duplicate compatibility aliases unless a downstream consumer explicitly requires them.

## Wave 1 - Required, metric-backed core facts

Run selector: `dbt run --selector transform_dev_fact_gap_wave_1`

- labor/unemployment: `fact_bls_laus_county`, `fact_bls_laus_cbsa_monthly`, `fact_bls_qcew_county_naics_quarterly`, `fact_county_soc_employment`, `fact_county_ai_replacement_risk`, `fact_dol_onet_soc_gwa_activity_risk`, `fact_dol_onet_soc_context_friction`, `fact_dol_onet_soc_ai_exposure`, `fact_aige_counties`
- permits + migration + housing: `fact_bps_permits_county`, `fact_hud_housing_series_county_monthly`, `fact_hud_housing_series_cbsa_monthly`, `fact_irs_soi_migration_by_characteristic_annual_county`, `fact_irs_soi_migration_by_characteristic_annual_cbsa`, `fact_irs_soi_origin_destination_migration_annual_county`, `fact_irs_soi_origin_destination_migration_annual_cbsa`
- pricing/rates/macro: `fact_fhfa_house_price_county_monthly`, `fact_fhfa_house_price_cbsa_monthly`, `fact_freddie_mac_housing_national_weekly`, `fact_oxford_amreg_quarterly`, `fact_oxford_wdmarco_quarterly`
- mortgage performance / appraisal quality: `fact_fhfa_mortgage_performance_county_monthly`, `fact_fhfa_mortgage_performance_cbsa_monthly`, `fact_fhfa_uniform_appraisal_county_monthly`, `fact_fhfa_uniform_appraisal_cbsa_monthly`
- corridor baseline: `fact_lodes_od_bg`

## Wave 2 - Dependency chain + gap fillers

Run selector: `dbt run --selector transform_dev_fact_gap_wave_2`

- population/employment bridge: `fact_census_pep_cbsa_annual`, `fact_census_pep_county_annual`, `fact_transform_concept_employment_cbsa_monthly`, `fact_transform_concept_employment_county_monthly`
- H3 corridor chain: `fact_lodes_od_h3_r8_annual`, `fact_lodes_od_workplace_hex_annual`, `fact_lodes_nearest_center_h3_r8_annual`, `fact_lodes_h3r8_workplace_gravity`
- market inventory gap: `fact_realtor_inventory_cbsa`

## Wave 3 - Deferred / optional / operational

Run selector: `dbt run --selector transform_dev_fact_gap_wave_3 --vars '{"transform_dev_enable_source_entity_progress_facts": true}'`

- market optional: `fact_markerr_rent_sfr`, `fact_yardi_matrix_submarketmatch_zipzcta_bh`
- compatibility/de-dup candidates (only if needed by active consumers): `fact_fhfa_house_price`, `fact_fhfa_house_price_cbsa`, `fact_fhfa_house_price_county`
- fund-opco operational backlog: all `fact_se_yardi_*` and `fact_sfdc_*` models in `transform_dev_fact_gap_wave_3`

## Guardrails

- `TRANSFORM.DEV` only for `FACT_*` and `CONCEPT_*`
- no `TRANSFORM_PROD` / `ANALYTICS_PROD` / `EDW_PROD` reads in semantic-layer dbt graph
- no hardcoded FQNs in model SQL; use `source()` / `ref()`
- metric registration must precede concept promotion for each new dataset fact
