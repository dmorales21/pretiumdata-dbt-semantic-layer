# FACT_* geography & REFERENCE enrichment inventory

**Scope:** `models/transform/dev/**/fact*.sql` in **pretiumdata-dbt-semantic-layer**.
**Strategy:** Aligns with analytics-engine sibling doc `analytics-engine/docs/reference/CONCEPT_MODEL_STRATEGY.md` — FACT grain discipline, CONCEPT unions, FEATURE/derived composites.

## Policy

| Layer | REFERENCE / H3 on **FACT** | **CONCEPT** only |
|--------|------------------------------|------------------|
| **ZIP-native vendor rows** (postal ZIP only) | ``reference_geo_zip_to_cbsa_and_h3_ctes()`` + joins → ``reference_*``, ``zip_to_h3_*``, ``zip_to_cbsa_id`` | Vendor-neutral CBSA **panels** and vendor-specific county arms stay in **CONCEPT_** unions. |
| **County / CBSA / H3-native silver** | **Do not** stack alternate rollups on the same row | Cross-vendor unions, dominance-weighted county from H3, etc. |
| **Property / CRM / GL** | Property keys + optional ZIP from entity | Market geographies via CONCEPT joins to shared spine. |

## Macros

- ``macros/semantic/reference_geo_zip_to_cbsa_ctes.sql`` — HUD ZIP → county → primary CBSA.
- ``macros/semantic/reference_geo_zip_to_cbsa_and_h3_ctes.sql`` — above + dominant **ZIP→H3** (``h3_polyfill_bridges.bridge_zip_h3_r8_polyfill``).

## Inventory

| Model | Native / implied grain | REFERENCE+H3 on FACT? | CONCEPT / int rollups |
|-------|------------------------|------------------------|-------------------------|
| `aige/fact_aige_counties.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `bls/fact_bls_laus_cbsa_monthly.sql` | BLS LAUS metro **AREA_CODE** × month | No — **AREA_CODE** is not guaranteed OMB CBSA | OMB CBSA via county path or explicit crosswalk in CONCEPT |
| `bls/fact_bls_laus_county.sql` | County FIPS × date × measure (LAUS county silver) | No | CBSA rollups in CONCEPT / QA |
| `bls/fact_bls_qcew_county_naics_quarterly.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `bls/fact_county_ai_replacement_risk.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `bls/fact_county_soc_employment.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `bps/fact_bps_permits_county.sql` | Gov / Jon silver native grain (read-through) | No — verify geo keys | CONCEPT / corridor ints |
| `census/fact_census_acs5_h3_r8_snapshot.sql` | Gov / Jon silver native grain (read-through) | No — verify geo keys | CONCEPT / corridor ints |
| `census/fact_census_pep_cbsa_annual.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `census/fact_census_pep_county_annual.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `census/fact_transform_concept_employment_cbsa_monthly.sql` | Upstream **TRANSFORM.CONCEPT** silver | N/A — grant **TRANSFORM.CONCEPT** (or repoint) | Per Jon concept table contract |
| `census/fact_transform_concept_employment_county_monthly.sql` | Upstream **TRANSFORM.CONCEPT** silver | N/A — grant **TRANSFORM.CONCEPT** (or repoint) | Per Jon concept table contract |
| `cherre/fact_cherre_stock_h3_r8.sql` | H3 R8 hex (native or bridge-backed) | No — county/CBSA via **int_h3_r8_hex_dominant_county** etc. | CONCEPT / corridor ints |
| `costar/fact_costar_mf_market_cbsa_monthly.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `costar/fact_costar_scenarios.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `dol_onet/fact_dol_onet_soc_ai_exposure.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `dol_onet/fact_dol_onet_soc_context_friction.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `dol_onet/fact_dol_onet_soc_gwa_activity_risk.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `entity/fact_county_ai_automation_risk.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `fhfa/fact_fhfa_house_price.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `fhfa/fact_fhfa_house_price_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `fhfa/fact_fhfa_house_price_cbsa_monthly.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `fhfa/fact_fhfa_house_price_county.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `fhfa/fact_fhfa_house_price_county_monthly.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `fhfa/fact_fhfa_mortgage_performance.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `fhfa/fact_fhfa_mortgage_performance_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `fhfa/fact_fhfa_mortgage_performance_cbsa_monthly.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `fhfa/fact_fhfa_mortgage_performance_county.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `fhfa/fact_fhfa_mortgage_performance_county_monthly.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `fhfa/fact_fhfa_uniform_appraisal.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `fhfa/fact_fhfa_uniform_appraisal_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `fhfa/fact_fhfa_uniform_appraisal_cbsa_monthly.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `fhfa/fact_fhfa_uniform_appraisal_county.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `fhfa/fact_fhfa_uniform_appraisal_county_monthly.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `freddie_mac/fact_freddie_mac_housing_national_weekly.sql` | National / macro panel | No | metric_derived / FEATURE |
| `fund_opco/fact_bh_yardi_ledger.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_bh_yardi_property.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_bh_yardi_unit.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_progress_yardi_ledger.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_progress_yardi_property.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_progress_yardi_unit.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_cam_opex_rule.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_cash_ledger_transaction.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_charge_payment_detail.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_gl_account_hierarchy.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_gl_line_detail.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_gl_period_total.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_investment_register_detail.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_lease_history.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_property_attribute.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_receivable_aging.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_strategy_segment.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_tenant_history.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_unit_master.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_unit_status_history.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_se_yardi_unit_type_market_rent.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_acquisition_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_acquisition_history.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_bpo_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_concession_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_disposition_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_finance_due_diligence_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_fund_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_fund_market_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_fund_pipeline_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_fund_pipeline_summary_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_hold_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_market_to_submarket_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_portfolio_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_properties_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `fund_opco/fact_sfdc_submarket_c.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `hud/fact_hud_housing_series.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `hud/fact_hud_housing_series_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `hud/fact_hud_housing_series_cbsa_monthly.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `hud/fact_hud_housing_series_county.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `hud/fact_hud_housing_series_county_monthly.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `irs/fact_irs_soi_migration_by_characteristic_annual.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `irs/fact_irs_soi_migration_by_characteristic_annual_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `irs/fact_irs_soi_migration_by_characteristic_annual_county.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `irs/fact_irs_soi_origin_destination_migration_annual_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `irs/fact_irs_soi_origin_destination_migration_annual_county.sql` | County-native (or county-primary) | No | CBSA rollups in CONCEPT / QA |
| `jbrec/fact_jbrec_btr_rent_occupancy_cleaned.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `lodes/fact_lodes_h3r8_workplace_gravity.sql` | Gov / Jon silver native grain (read-through) | No — verify geo keys | CONCEPT / corridor ints |
| `lodes/fact_lodes_nearest_center_h3_r8_annual.sql` | H3 R8 hex (native or bridge-backed) | No — county/CBSA via **int_h3_r8_hex_dominant_county** etc. | CONCEPT / corridor ints |
| `lodes/fact_lodes_od_bg.sql` | Gov / Jon silver native grain (read-through) | No — verify geo keys | CONCEPT / corridor ints |
| `lodes/fact_lodes_od_h3_r8_annual.sql` | Gov / Jon silver native grain (read-through) | No — verify geo keys | CONCEPT / corridor ints |
| `lodes/fact_lodes_od_workplace_hex_annual.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `markerr/fact_markerr_rent_listings.sql` | Listing + postal ZIP | Yes — ``reference_geo_zip_to_cbsa_and_h3_ctes()`` | County/CBSA arms in supply/transaction CONCEPT via corridor facts |
| `markerr/fact_markerr_rent_property.sql` | Property + postal ZIP | Yes — ``reference_geo_zip_to_cbsa_and_h3_ctes()`` | Market CBSA panels use other Markerr MF facts |
| `markerr/fact_markerr_rent_property_cbsa_monthly.sql` | CBSA × month (native) | No | CONCEPT rent market |
| `markerr/fact_markerr_rent_property_monthly.sql` | MSA-name monthly (Jon) → CBSA via **REFERENCE.GEOGRAPHY.CBSA** | No extra ZIP bridge | CONCEPT rent market |
| `markerr/fact_markerr_rent_sfr.sql` | Vendor **GEOGRAPHY_TYPE** × **GEO_ID** (ZIP/CBSA/…) | No on fact — vendor encodes geo; CBSA rollups in ``concept_rent_market_monthly`` | ZIP→CBSA in CONCEPT via shared spine |
| `oxford/fact_oxford_amreg_quarterly.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `oxford/fact_oxford_wdmarco_quarterly.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `parcllabs/fact_parcllabs_rent_listings_cleaned.sql` | ZIP (Parcl listing vendor grain) | Yes — ``reference_geo_zip_to_cbsa_and_h3_ctes()`` | CBSA/H3 market panels in CONCEPT |
| `progress_crm/fact_progress_disposition.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `progress_crm/fact_progress_disposition_latest.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `realtor/fact_realtor_inventory_cbsa.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
| `stanford/fact_stanford_seda_h3_r8_snapshot.sql` | H3 R8 hex (native or bridge-backed) | No — county/CBSA via **int_h3_r8_hex_dominant_county** etc. | CONCEPT / corridor ints |
| `yardi_matrix/fact_yardi_matrix_marketperformance_bh.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `yardi_matrix/fact_yardi_matrix_submarketmatch_zipzcta_bh.sql` | Property / fund / ops entity grain | No | Market geographies via CONCEPT joins |
| `zillow/fact_zillow_affordability.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_days_on_market_and_price_cuts.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_for_sale_listings.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_home_values.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_home_values_forecasts.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_market_heat_index.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_new_construction.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_rental_forecasts.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_rentals.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zillow/fact_zillow_sales.sql` | Mixed — read model header | Case-by-case | CONCEPT / FEATURE |
| `zonda/fact_zonda_btr_rent_cbsa_monthly_cleaned.sql` | CBSA-native (or CBSA-primary) | No | Cross-vendor unions in CONCEPT |
