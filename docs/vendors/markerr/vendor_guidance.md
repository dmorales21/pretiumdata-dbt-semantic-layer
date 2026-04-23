# Markerr — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/markerr/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/markerr/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_014` |
| **vendor_code** | `markerr` |
| **vendor_label** | Markerr |
| **definition** | Markerr RealRent property-level rent listings forecast SFR income employment crime and MF permits at property and ZIP grain |
| **data_type** | transactional |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.MARKERR` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/markerr/markerr.md`)

**Catalog row:** `vendor_id` = `VND_014` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Markerr RealRent property-level rent listings forecast SFR income employment crime and MF permits at property and ZIP grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | transactional |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.MARKERR` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`markerr`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

No vendor-specific migration file is mapped in `generate_vendor_context_from_seed.py` yet. Use [`migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md`](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) and [`migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`](../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md).

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 190 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 190 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 195 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_147 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `AVG_ASKING_RENT` |
| MET_148 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `AVG_CONCESSION_MOM_PCT_CHANGE` |
| MARKERR_MAN_FB97AB27 | crime | place | negative | `TRANSFORM.DEV.CONCEPT_CRIME_MARKET_ANNUAL` | `crime_current` |
| MET_131 | supply_pipeline | housing | neutral | `TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY` | `supply_pipeline_current` |
| MARKERR_MAN_76128627A7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `AMENITY_COMPOSITE_INDEX` |
| MARKERR_MAN_7D61241255 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `AVG_STUDENTS_PER_TEACHER` |
| MARKERR_MAN_EDB3F510BB | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `CRIME_INDEX_WAVG` |
| MARKERR_MAN_C6D82A000B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `ELEMENTARY_COUNT` |
| MARKERR_MAN_C9C5FB1CC6 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `ELEMENTARY_SCORE_AVG` |
| MARKERR_MAN_53F334C826 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `ELEMENTARY_SCORE_MAX` |
| MARKERR_MAN_FE4DE19865 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `HIGH_SCORE_AVG` |
| MARKERR_MAN_4FE703DE62 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `MIDDLE_SCORE_AVG` |
| MARKERR_MAN_110C792D7C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `PRIVATE_SCORE_AVG` |
| MARKERR_MAN_F911C1D82E | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `PROPERTY_CRIME_INDEX_WAVG` |
| MARKERR_MAN_856E64F8B1 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `PUBLIC_SCORE_AVG` |
| MARKERR_MAN_844F65E486 | education | household | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `SCHOOL_COUNT` |
| MARKERR_MAN_9438F7366E | education | household | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `SCHOOL_GOOD_PLUS_SHARE` |
| MARKERR_MAN_D8B25F3A85 | education | household | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `SCHOOL_SCORE_AVG` |
| MARKERR_MAN_7FA522AA87 | education | household | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `SCHOOL_SCORE_MAX` |
| MARKERR_MAN_8CD612B58F | education | household | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `SCHOOL_TOP_TIER_SHARE` |
| MARKERR_MAN_D66AB28C20 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_AMENITY_H3_R8_SNAPSHOT` | `VIOLENT_CRIME_INDEX_WAVG` |
| MARKERR_MAN_FAD8EF0038 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` | `CRIME_INDEX_WAVG` |
| MARKERR_MAN_13A42AA4D2 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` | `CRIME_INDEX_WAVG_0_100` |
| MARKERR_MAN_8D6252F112 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` | `PROPERTY_CRIME_INDEX_WAVG` |
| MARKERR_MAN_509B013B03 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` | `PROPERTY_CRIME_INDEX_WAVG_0_100` |
| MARKERR_MAN_0C476BD7E8 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` | `VIOLENT_CRIME_INDEX_WAVG` |
| MARKERR_MAN_62350F4797 | crime | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_CRIME_H3_R8_SNAPSHOT` | `VIOLENT_CRIME_INDEX_WAVG_0_100` |
| MARKERR_MAN_2D185CC55D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `COMPLETION_RATIO` |
| MARKERR_MAN_7BC4B6C915 | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `PERMIT_VALUE_PLANNING` |
| MARKERR_MAN_FEE1859583 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `PROJECTS_COMPLETED` |
| MARKERR_MAN_B7DDD7CDD3 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `PROJECTS_PLANNING` |
| MARKERR_MAN_01C026D2EC | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `PROJECTS_UNDER_CONSTRUCTION` |
| MARKERR_MAN_61296AD0DD | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_ACTIVE_SUPPLY` |
| MARKERR_MAN_EAD75EDE69 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_COMPLETED` |
| MARKERR_MAN_1363176F6E | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_CONSTRUCTION_3MO_SUM` |
| MARKERR_MAN_C78EFB0623 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_PLANNING` |
| MARKERR_MAN_8D29C79B41 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_PLANNING_3MO_SUM` |
| MARKERR_MAN_077567F26F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_PLANNING_MOM` |
| MARKERR_MAN_03B9400299 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_PLANNING_QOQ` |
| MARKERR_MAN_640D455D32 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_PLANNING_YOY` |
| MARKERR_MAN_3CB2B38C23 | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `UNITS_UNDER_CONSTRUCTION` |
| MARKERR_MAN_007E4C7649 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `ZIP_COUNT` |
| MARKERR_MAN_B762BF84F7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `MONTHS_SUPPLY` |
| MARKERR_MAN_C5739A0CCE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `PROJECTS_COUNT` |
| MARKERR_MAN_D04E8511B5 | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `UNITS_PERMITTED` |
| MARKERR_MAN_23D7FE78C5 | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `UNITS_PERMITTED_3MO_SUM` |
| MARKERR_MAN_727E496D29 | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `UNITS_PERMITTED_YOY` |
| MARKERR_MAN_DCC1A4D676 | permits | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `UNITS_PERMITTED_YOY_PCT` |
| MARKERR_MAN_40337E72E8 | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_MARKERR_OCCUPANCY_H3_R8_MONTHLY` | `AVG_AVAILABILITY_RATE` |
| MARKERR_MAN_A7B5849C9F | occupancy | housing | positive | `TRANSFORM.DEV.FACT_MARKERR_OCCUPANCY_H3_R8_MONTHLY` | `AVG_OCCUPANCY_RATE` |

*(140 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
