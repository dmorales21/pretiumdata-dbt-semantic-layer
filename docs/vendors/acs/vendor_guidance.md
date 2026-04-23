# US Census Bureau — ACS — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/acs/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/acs/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_001` |
| **vendor_code** | `acs` |
| **vendor_label** | US Census Bureau — ACS |
| **definition** | American Community Survey 5-year estimates covering demographics household income tenure and housing characteristics at tract block group CBSA and ZIP grain |
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.ACS` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md)

---

## Vendor methodology (full text from `docs/vendor/acs/acs.md`)

**Catalog row:** `vendor_id` = `VND_001` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

American Community Survey 5-year estimates covering demographics household income tenure and housing characteristics at tract block group CBSA and ZIP grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.ACS` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`acs`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 1 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 0 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 0 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| ACS_MAN_6FF6886F | pipeline | place | neutral | `RAW.ACS` | `TBD` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
