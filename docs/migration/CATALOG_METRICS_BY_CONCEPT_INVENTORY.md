# Catalog inventory — active `MET_*` rows by `concept_code`

**Generated:** `scripts/ci/print_catalog_metrics_by_concept_inventory.py` from `metric.csv` (active) × `concept.csv`.

**Naming:** single-token `concept_code` where practical (`homeprice`, `supply_pipeline`, `school_quality`, `listings`, `automation`, `spine`, `underwriting`); `cap_rate` kept as a standard acronym.

| `concept_code` | Active MET rows | Promoted (`data_status_code=active`) | Distinct `table_path` (count) | Example `table_path` |
|----------------|----------------:|---------------------------------------:|------------------------------:|------------------------|
| `absorption` | 4 | 0 | 2 | `TRANSFORM.DEV.FACT_COSTAR_MF_MARKET_CBSA_MONTHLY` |
| `automation` | 123 | 7 | 10 | `TRANSFORM.DEV.FACT_FIRST_STREET_CLIMATE_RISK_COUNTY_SNAPSHOT` |
| `cap_rate` | 12 | 1 | 5 | `TRANSFORM.DEV.FACT_COSTAR_MARKET_SCENARIOS` |
| `concession` | 6 | 0 | 2 | `TRANSFORM.DEV.FACT_SFDC_CONCESSION_C` |
| `crime` | 16 | 6 | 4 | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` |
| `delinquency` | 23 | 2 | 7 | `TRANSFORM.DEV.FACT_PROGRESS_DELINQUENCY_MONTHLY` |
| `disposition` | 23 | 0 | 1 | `TRANSFORM.DEV.FACT_SFDC_DISPOSITION_C` |
| `dscr` | 4 | 0 | 3 | `TRANSFORM.DEV.FACT_RCA_MF_DEBT_H3_R8_MONTHLY` |
| `employment` | 432 | 8 | 23 | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` |
| `homeprice` | 249 | 4 | 54 | `TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES` |
| `housing_stock` | 0 | 0 | 0 | `—` |
| `income` | 261 | 0 | 15 | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` |
| `inflation` | 5 | 0 | 1 | `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` |
| `labor` | 2 | 0 | 1 | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` |
| `listings` | 6 | 2 | 4 | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` |
| `ltv` | 17 | 0 | 3 | `TRANSFORM.DEV.FACT_CHERRE_RECORDER_MORTGAGE_H3_R8_MONTHLY` |
| `migration` | 27 | 4 | 8 | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` |
| `multifamily_market` | 0 | 0 | 0 | `—` |
| `noi` | 8 | 0 | 2 | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` |
| `occupancy` | 63 | 2 | 22 | `TRANSFORM.DEV.FACT_MARKERR_OCCUPANCY_H3_R8_MONTHLY` |
| `permits` | 80 | 1 | 11 | `TRANSFORM.DEV.FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY` |
| `population` | 91 | 0 | 10 | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` |
| `rates` | 12 | 1 | 2 | `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` |
| `rent` | 421 | 6 | 62 | `TRANSFORM.DEV.FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY` |
| `school_quality` | 4 | 4 | 1 | `TRANSFORM.DEV.CONCEPT_SCHOOL_QUALITY_MARKET_ANNUAL` |
| `spine` | 0 | 0 | 0 | `—` |
| `supply_pipeline` | 3 | 2 | 1 | `TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY` |
| `transactions` | 39 | 3 | 8 | `TRANSFORM.DEV.FACT_ZILLOW_SALES` |
| `underwriting` | 0 | 0 | 0 | `—` |
| `unemployment` | 26 | 2 | 8 | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` |
| `vacancy` | 58 | 0 | 17 | `TRANSFORM.DEV.FACT_CHERRE_VACANT_COUNTY_SNAPSHOT` |
| `wages` | 21 | 0 | 2 | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` |

## Orphan `concept_code` on metrics (not in `concept.csv`)
- `education`: 86 active rows
- `pipeline`: 2546 active rows

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial generator; refresh after bulk `metric.csv` changes. |

