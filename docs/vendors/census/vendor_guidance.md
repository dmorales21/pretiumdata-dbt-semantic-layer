# US Census Bureau — Decennial / PEP — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/census/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/census/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_003` |
| **vendor_code** | `census` |
| **vendor_label** | US Census Bureau — Decennial / PEP |
| **definition** | Population Estimates Program and County Business Patterns data at county and CBSA grain |
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.CENSUS` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

---

## Vendor methodology (full text from `docs/vendor/census/census.md`)

**Catalog row:** `vendor_id` = `VND_003` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Population Estimates Program and County Business Patterns data at county and CBSA grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.CENSUS` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`census`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 318 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 318 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 319 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_157 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `PCT_25_44` |
| MET_156 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `RENTER_SHARE` |
| MET_158 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `RENT_BURDEN_30_PLUS_SHARE` |
| MET_154 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `TOTAL_HOUSEHOLDS` |
| CENSUS_MAN_A49F000A | school_quality | place | neutral | `TRANSFORM.DEV.CONCEPT_SCHOOL_QUALITY_MARKET_ANNUAL` | `school_quality_current` |
| CENSUS_MAN_C165D32A45 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `ACS_YEAR` |
| CENSUS_MAN_AF75E94F76 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMPLOYED` |
| CENSUS_MAN_6B7A165DFA | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMPLOYED_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_9D069FD59E | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMPLOYED_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_9A20789213 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMPLOYED_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_C2A74B1C55 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMPLOYED_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_041DF13877 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMP_TOTAL_16PLUS` |
| CENSUS_MAN_B0E102C3B9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMP_TOTAL_16PLUS_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_31C777412B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMP_TOTAL_16PLUS_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_BE61A3CAC4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMP_TOTAL_16PLUS_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_BBF45F9437 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `EMP_TOTAL_16PLUS_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_C7C2970D46 | population | household | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `FAMILY_HOUSEHOLDS` |
| CENSUS_MAN_13647F643B | population | household | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `FAMILY_HOUSEHOLDS_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_6F241ECF36 | population | household | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `FAMILY_HOUSEHOLDS_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_4344800B8F | population | household | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `FAMILY_HOUSEHOLDS_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_186D654C31 | population | household | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `FAMILY_HOUSEHOLDS_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_0988036B0D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HH_HEAD_25_44` |
| CENSUS_MAN_00BD526CE2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HH_HEAD_25_44_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_EA1033EC5A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HH_HEAD_25_44_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_8EDF93D337 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HH_HEAD_25_44_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_18208D6BD2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HH_HEAD_25_44_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_7A02A178F2 | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_OCCUPIED` |
| CENSUS_MAN_C9951109DD | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_OCCUPIED_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_857DE44BAD | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_OCCUPIED_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_880A067FB8 | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_OCCUPIED_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_48B733E242 | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_OCCUPIED_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_0E043EFA3F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_UNITS_TOTAL` |
| CENSUS_MAN_5ADBFE1094 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_UNITS_TOTAL_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_428221A4F1 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_UNITS_TOTAL_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_D15ED44C99 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_UNITS_TOTAL_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_3977BDEC6C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_UNITS_TOTAL_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_7E52C2B24E | vacancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_VACANT` |
| CENSUS_MAN_9CC588AE3F | vacancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_VACANT_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_95A1F3326D | vacancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_VACANT_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_ACC69D1B90 | vacancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_VACANT_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_A652651C54 | vacancy | housing | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `HOUSING_VACANT_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_4BC507FE64 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `IN_LABOR_FORCE` |
| CENSUS_MAN_63A3BC9578 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `IN_LABOR_FORCE_ABS_CHANGE_ACS5_10YR` |
| CENSUS_MAN_C7A4D22716 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `IN_LABOR_FORCE_ABS_CHANGE_ACS5_5YR` |
| CENSUS_MAN_E623AFDC34 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `IN_LABOR_FORCE_PCT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_F29FEF5052 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `IN_LABOR_FORCE_PCT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_EF1AB0DDD8 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `LABOR_FORCE_PARTICIPATION_RATE` |
| CENSUS_MAN_4AD74B3123 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `LABOR_FORCE_PARTICIPATION_RATE_PPT_CHANGE_ACS5_10YR` |
| CENSUS_MAN_BDA16A02B0 | employment | place | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `LABOR_FORCE_PARTICIPATION_RATE_PPT_CHANGE_ACS5_5YR` |
| CENSUS_MAN_F16E95166C | population | household | neutral | `TRANSFORM.DEV.FACT_ACS_DEMOGRAPHICS_COUNTY` | `MARRIED_COUPLE_HOUSEHOLDS` |

*(268 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
