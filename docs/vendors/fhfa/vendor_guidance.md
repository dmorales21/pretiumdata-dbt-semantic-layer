# FHFA — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/fhfa/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/fhfa/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_045` |
| **vendor_code** | `fhfa` |
| **vendor_label** | FHFA |
| **definition** | Federal Housing Finance Agency house price index mortgage performance and appraisal series |
| **data_type** | administrative |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `RAW.FHFA` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/fhfa/fhfa.md`)

**Catalog row:** `vendor_id` = `VND_045` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Federal Housing Finance Agency house price index mortgage performance and appraisal series

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `RAW.FHFA` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`fhfa`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 9 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 9 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 9 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_016 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_FHFA_HOUSE_PRICE_CBSA` | `VALUE` |
| MET_011 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_FHFA_HOUSE_PRICE_COUNTY` | `VALUE` |
| MET_018 | delinquency | capital | negative | `TRANSFORM.DEV.FACT_FHFA_MORTGAGE_PERFORMANCE_CBSA` | `VALUE` |
| MET_017 | delinquency | capital | negative | `TRANSFORM.DEV.FACT_FHFA_MORTGAGE_PERFORMANCE_COUNTY` | `VALUE` |
| MET_020 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_FHFA_UNIFORM_APPRAISAL_CBSA` | `VALUE` |
| MET_019 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_FHFA_UNIFORM_APPRAISAL_COUNTY` | `VALUE` |
| MET_060 | homeprice | housing | neutral | `TRANSFORM.DEV.fact_fhfa_house_price` | `VALUE` |
| MET_061 | delinquency | capital | negative | `TRANSFORM.DEV.fact_fhfa_mortgage_performance` | `VALUE` |
| MET_062 | homeprice | housing | neutral | `TRANSFORM.DEV.fact_fhfa_uniform_appraisal` | `VALUE` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
