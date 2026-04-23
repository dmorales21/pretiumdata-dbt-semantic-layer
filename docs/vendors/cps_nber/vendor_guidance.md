# NBER / CPS — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/cps_nber/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/cps_nber/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_038` |
| **vendor_code** | `cps_nber` |
| **vendor_label** | NBER / CPS |
| **definition** | Current Population Survey microdata accessed via NBER covering household demographics labor force status and income |
| **data_type** | administrative |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.NBER` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

---

## Vendor methodology (full text from `docs/vendor/cps_nber/cps_nber.md`)

**Catalog row:** `vendor_id` = `VND_038` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Current Population Survey microdata accessed via NBER covering household demographics labor force status and income

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.NBER` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`cps_nber`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 51 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 51 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 51 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| CPS_NBER_RESOLVED_HOUSEHOLD_WEIGHT | population | household | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `HOUSEHOLD_WEIGHT` |
| CPS_NBER_RESOLVED_HOUSEHOLD_SIZE | population | household | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `NUMBER_OF_HOUSEHOLD_MEMBERS` |
| CPS_NBER_RESOLVED_PERSON_AGE | population | household | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `PERSON_PROCESSED_AGE` |
| CPS_NBER_RESOLVED_PERSON_WEIGHT | population | household | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `PERSON_WEIGHT_COMPOSITE` |
| CPS_NBER_RESOLVED_PERSON_WEIGHT_OUT_ROT | population | household | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `PERSON_WEIGHT_OUTGOING_ROTATION` |
| CPS_NBER_FAM_68E3B00D421D | employment | place | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `P_MONTH` |
| CPS_NBER_FAM_9FD703B0F722 | employment | place | neutral | `TRANSFORM.DEV.FACT_CPS_COUNTY_RESOLVED` | `P_YEAR` |
| CPS_NBER_EMPLOYED_POP_RATIO | employment | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_EMPLOYED_TO_POPULATION_RATIO` |
| CPS_NBER_EMPLOYMENT_RATE | employment | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_EMPLOYMENT_RATE` |
| CPS_NBER_HEHOUSUT_COUNT | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HEHOUSUT_HOUSE_APARTMENT_FLAT` |
| CPS_NBER_HEHOUSUT_SHARE | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HEHOUSUT_HOUSE_APARTMENT_FLAT_SHARE` |
| CPS_NBER_HH_WEIGHTED_COUNT | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HOUSEHOLD_COUNT` |
| CPS_NBER_HH_COUNT_MOM_ABS | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HOUSEHOLD_COUNT_MOM_ABSOLUTE_CHANGE` |
| CPS_NBER_HH_COUNT_MOM_GROWTH | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HOUSEHOLD_COUNT_MOM_GROWTH_RATE` |
| CPS_NBER_HH_COUNT_YOY_ABS | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HOUSEHOLD_COUNT_YOY_ABSOLUTE_CHANGE` |
| CPS_NBER_HH_COUNT_YOY_GROWTH | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_HOUSEHOLD_COUNT_YOY_GROWTH_RATE` |
| CPS_NBER_MEAN_HOUSEHOLD_SIZE | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_MEAN_HRNUMHOU` |
| CPS_NBER_HH_WEIGHTED_OWNER | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_OWNER_HOUSEHOLDS` |
| CPS_NBER_OWNER_SHARE | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_OWNER_TENURE_SHARE` |
| CPS_NBER_HH_WEIGHTED_RENTER | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_RENTER_HOUSEHOLDS` |
| CPS_NBER_RENTER_SHARE | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_RENTER_TENURE_SHARE` |
| CPS_NBER_HH_WEIGHTED_RENT_FREE | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_RENT_FREE_HOUSEHOLDS` |
| CPS_NBER_RENT_FREE_SHARE | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_HH_WEIGHTED_RENT_FREE_TENURE_SHARE` |
| CPS_NBER_LFPR | labor | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_LABOR_FORCE_PARTICIPATION_RATE` |
| CPS_NBER_LFPR_LAG12M | labor | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_LFPR_LAG12M` |
| CPS_NBER_LFPR_YOY | employment | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_LFPR_YOY_CHANGE` |
| CPS_NBER_POP_MOM_ABS | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_PERSON_WEIGHTED_POPULATION_MOM_ABSOLUTE_CHANGE` |
| CPS_NBER_POP_MOM_GROWTH | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_PERSON_WEIGHTED_POPULATION_MOM_GROWTH_RATE` |
| CPS_NBER_POP_YOY_ABS | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_PERSON_WEIGHTED_POPULATION_YOY_ABSOLUTE_CHANGE` |
| CPS_NBER_POP_YOY_GROWTH | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_PERSON_WEIGHTED_POPULATION_YOY_GROWTH_RATE` |
| CPS_NBER_PERSON_TO_HH_RATIO | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_PERSON_WEIGHT_PER_HH_WEIGHT_RATIO` |
| CPS_NBER_UNEMPLOYMENT_RATE | unemployment | place | negative | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_UNEMPLOYMENT_RATE` |
| CPS_NBER_UNEMPLOYMENT_RATE_LAG12M | unemployment | place | negative | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_UNEMPLOYMENT_RATE_LAG12M` |
| CPS_NBER_UNEMPLOYMENT_RATE_LAG1M | unemployment | place | negative | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_UNEMPLOYMENT_RATE_LAG1M` |
| CPS_NBER_UNEMPLOYMENT_RATE_MOM | unemployment | place | negative | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_UNEMPLOYMENT_RATE_MOM_CHANGE` |
| CPS_NBER_UNEMPLOYMENT_RATE_YOY | unemployment | place | negative | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_UNEMPLOYMENT_RATE_YOY_CHANGE` |
| CPS_NBER_CIVILIAN_LABOR_FORCE | employment | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_CIVILIAN_LABOR_FORCE` |
| CPS_NBER_EMPLOYED_CIVILIAN | employment | place | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_EMPLOYED_CIVILIAN` |
| CPS_NBER_OUTGOING_ROTATION_SUM | population | household | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_OUTGOING_ROTATION_SUM` |
| CPS_NBER_WEIGHTED_POPULATION | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION` |
| CPS_NBER_WEIGHTED_POP_16_64 | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_AGE_16_64` |
| CPS_NBER_WEIGHTED_POP_25_PLUS | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_AGE_25_PLUS` |
| CPS_NBER_WEIGHTED_POP_65_PLUS | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_AGE_65_PLUS` |
| CPS_NBER_WEIGHTED_POP_UNDER_16 | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_AGE_UNDER_16` |
| CPS_NBER_WEIGHTED_POP_FEMALE | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_FEMALE` |
| CPS_NBER_WEIGHTED_POP_HISPANIC | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_HISPANIC` |
| CPS_NBER_WEIGHTED_POP_MALE | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_MALE` |
| CPS_NBER_WEIGHTED_POP_NON_HISPANIC | population | household | positive | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_POPULATION_NON_HISPANIC` |
| CPS_NBER_UNEMPLOYED_CIVILIAN | unemployment | place | negative | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `FEAT_CPS_WEIGHTED_UNEMPLOYED_CIVILIAN` |
| CPS_NBER_FAM_45BCC38B6BD8 | employment | place | neutral | `TRANSFORM.DEV.FACT_NBER_CPS_COUNTY` | `N_CPS_HOUSEHOLDS_IN_SAMPLE` |

*(1 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
