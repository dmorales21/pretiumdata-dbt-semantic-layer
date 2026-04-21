# Catalog inventory — active `MET_*` rows by `concept_code`

**Generated:** `scripts/ci/print_catalog_metrics_by_concept_inventory.py` from `metric.csv` (active) × `concept.csv`.

**Naming:** single-token `concept_code` where practical (`homeprice`, `pipeline`, `education`, `automation`, `spine`, `underwriting`); `cap_rate` kept as a standard acronym.

| `concept_code` | Active MET rows | Promoted (`data_status_code=active`) | Distinct `table_path` (count) | Example `table_path` |
|----------------|----------------:|---------------------------------------:|------------------------------:|------------------------|
| `absorption` | 31 | 2 | 10 | `TRANSFORM.REDFIN.REDFIN_NEIGHBORHOOD_MARKET_TRACKER_LATEST` |
| `automation` | 121 | 5 | 10 | `TRANSFORM.DEV.FACT_FIRST_STREET_CLIMATE_RISK_COUNTY_SNAPSHOT` |
| `cap_rate` | 12 | 1 | 5 | `TRANSFORM.DEV.FACT_COSTAR_MARKET_SCENARIOS` |
| `concession` | 6 | 0 | 2 | `TRANSFORM.DEV.FACT_SFDC_CONCESSION_C` |
| `crime` | 10 | 0 | 3 | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` |
| `delinquency` | 23 | 2 | 7 | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` |
| `dscr` | 0 | 0 | 0 | `—` |
| `education` | 88 | 0 | 10 | `TRANSFORM.DEV.FACT_MARKERR_SCHOOLS_COUNTY_SNAPSHOT` |
| `employment` | 432 | 8 | 23 | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` |
| `homeprice` | 346 | 4 | 60 | `TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES` |
| `income` | 257 | 0 | 14 | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` |
| `inflation` | 5 | 0 | 1 | `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` |
| `labor` | 2 | 0 | 1 | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` |
| `ltv` | 17 | 0 | 3 | `TRANSFORM.DEV.FACT_CHERRE_RECORDER_MORTGAGE_H3_R8_MONTHLY` |
| `migration` | 27 | 4 | 8 | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` |
| `noi` | 8 | 0 | 2 | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` |
| `occupancy` | 67 | 2 | 23 | `TRANSFORM.DEV.FACT_MARKERR_OCCUPANCY_H3_R8_MONTHLY` |
| `permits` | 80 | 1 | 11 | `TRANSFORM.DEV.FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY` |
| `pipeline` | 2642 | 0 | 120 | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` |
| `population` | 92 | 0 | 11 | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` |
| `rates` | 11 | 0 | 1 | `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` |
| `rent` | 425 | 6 | 64 | `TRANSFORM.DEV.FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY` |
| `spine` | 44 | 6 | 7 | `TRANSFORM.DEV.FACT_OPCO_WEIGHTS_COUNTY` |
| `transactions` | 33 | 0 | 6 | `TRANSFORM.DEV.FACT_ZILLOW_SALES` |
| `underwriting` | 9 | 6 | 2 | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` |
| `unemployment` | 26 | 2 | 8 | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` |
| `vacancy` | 58 | 0 | 17 | `TRANSFORM.DEV.FACT_CHERRE_VACANT_COUNTY_SNAPSHOT` |
| `wages` | 21 | 0 | 2 | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` |

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial generator; refresh after bulk `metric.csv` changes. |

