# Bureau of Labor Statistics — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/bls/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/bls/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_002` |
| **vendor_code** | `bls` |
| **vendor_label** | Bureau of Labor Statistics |
| **definition** | BLS employment and labor data including LAUS QCEW and OES series at county CBSA and national grain |
| **data_type** | administrative |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.BLS` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

---

## Vendor methodology (full text from `docs/vendor/bls/bls.md`)

**Catalog row:** `vendor_id` = `VND_002` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

BLS employment and labor data including LAUS QCEW and OES series at county CBSA and national grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.BLS` |
| **is_active** | TRUE |
| **data_share_type** | s3 |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`bls`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 30 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 30 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 33 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_159 | multifamily_market | housing | negative | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `UNEMPLOYMENT_RATE` |
| MET_118 | employment | place | positive | `TRANSFORM.DEV.FACT_BLS_LAUS_CBSA_MONTHLY` | `EMPLOYMENT` |
| BLS_MAN_F3D3390B2D | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_LAUS_CBSA_MONTHLY` | `LABOR_FORCE` |
| MET_117 | unemployment | place | negative | `TRANSFORM.DEV.FACT_BLS_LAUS_CBSA_MONTHLY` | `UNEMPLOYED_COUNT` |
| MET_006 | unemployment | place | neutral | `TRANSFORM.DEV.FACT_BLS_LAUS_CBSA_MONTHLY` | `UNEMPLOYMENT_RATE` |
| BLS_MAN_C9476716 | unemployment | place | negative | `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY` | `VALUE` |
| BLS_MAN_EAE6EA41FB | employment | place | positive | `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY_MONTHLY` | `EMPLOYMENT` |
| BLS_MAN_88E224649A | employment | place | positive | `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY_MONTHLY` | `EMPLOYMENT_RATIO` |
| BLS_MAN_B5DD37A7E8 | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY_MONTHLY` | `LABOR_FORCE` |
| BLS_MAN_F5E7901DAF | unemployment | place | neutral | `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY_MONTHLY` | `UNEMPLOYED_COUNT` |
| BLS_MAN_7A89C71E4C | unemployment | place | positive | `TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY_MONTHLY` | `UNEMPLOYMENT_RATE` |
| BLS_MAN_B95F5CB1A3 | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `ANNUAL_MEAN_WAGE` |
| BLS_MAN_9AE63CDB5E | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `ANNUAL_MEDIAN_WAGE` |
| BLS_MAN_E9B7CE2D3B | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `ANNUAL_PCT25_WAGE` |
| BLS_MAN_99EEF63C98 | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `ANNUAL_PCT75_WAGE` |
| BLS_MAN_D89F042CED | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `EMP_PCT_RSE` |
| BLS_MAN_1ED76E4FF9 | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `HOURLY_MEDIAN_WAGE` |
| BLS_MAN_765F65A52C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `JOBS_PER_1000` |
| BLS_MAN_E1076DF1DB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `LOCATION_QUOTIENT` |
| BLS_MAN_491A82BE00 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `SURVEY_YEAR` |
| BLS_MAN_B20D0D363E | employment | place | positive | `TRANSFORM.DEV.FACT_BLS_OES_CBSA_ANNUAL` | `TOTAL_EMPLOYMENT` |
| MET_119 | employment | place | positive | `TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY` | `AVG_WEEKLY_WAGE` |
| MET_021 | employment | place | positive | `TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY` | `employment` |
| MET_023 | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY` | `establishments` |
| MET_022 | employment | place | neutral | `TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY` | `total_wages` |
| MET_120 | automation | place | negative | `TRANSFORM.DEV.FACT_COUNTY_AI_REPLACEMENT_RISK` | `COMBINED_RISK_SCORE` |
| MET_125 | automation | place | neutral | `TRANSFORM.DEV.FACT_COUNTY_AI_REPLACEMENT_RISK` | `DEPLOYMENT_ADJUSTED_EXPOSURE` |
| MET_126 | automation | place | neutral | `TRANSFORM.DEV.FACT_COUNTY_AI_REPLACEMENT_RISK` | `RAW_SUSCEPTIBILITY` |
| MET_122 | automation | place | negative | `TRANSFORM.DEV.FACT_COUNTY_AI_REPLACEMENT_RISK` | `VALUE` |
| MET_028 | employment | place | positive | `TRANSFORM.DEV.FACT_COUNTY_SOC_EMPLOYMENT` | `estimated_employment` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
