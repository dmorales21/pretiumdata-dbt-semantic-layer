# Oxford Economics — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/oxford_economics/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/oxford_economics/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_018` |
| **vendor_code** | `oxford_economics` |
| **vendor_label** | Oxford Economics |
| **definition** | Oxford Economics AMREG residential market forecasts and WDMARCO macro series at CBSA and national grain |
| **data_type** | survey |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.PRETIUM` |
| **data_share_type** | sftp |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md](../migration/MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md)

---

## Vendor methodology (full text from `docs/vendor/oxford_economics/oxford_economics.md`)

**Catalog row:** `vendor_id` = `VND_018` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Oxford Economics AMREG residential market forecasts and WDMARCO macro series at CBSA and national grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | survey |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.PRETIUM` |
| **is_active** | TRUE |
| **data_share_type** | sftp |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`oxford_economics`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md`](../migration/MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 3 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 3 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 610 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| OXFORD_ECONO_MAN_AFEFC080 | income | household | positive | `TRANSFORM.DEV.FACT_OXFORD_AMREG_QUARTERLY` | `VALUE` |
| OXFORD_ECONO_MAN_57976445 | employment | place | positive | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_MONTHLY` | `VALUE` |
| MET_054 | employment | place | neutral | `TRANSFORM.DEV.FACT_OXFORD_WDMARCO_QUARTERLY` | `VALUE` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
