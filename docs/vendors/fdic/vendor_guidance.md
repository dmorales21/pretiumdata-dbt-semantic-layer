# FDIC — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/fdic/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/fdic/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_046` |
| **vendor_code** | `fdic` |
| **vendor_label** | FDIC |
| **definition** | FDIC Summary of Deposits and institution/branch reference as surfaced through Cybersyn tables |
| **data_type** | administrative |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `RAW.FDIC` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md](../migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md)

---

## Vendor methodology (full text from `docs/vendor/fdic/fdic.md`)

**Catalog row:** `vendor_id` = `VND_046` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

FDIC Summary of Deposits and institution/branch reference as surfaced through Cybersyn tables

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `RAW.FDIC` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`fdic`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md`](../migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md)

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
| FDIC_MAN_D4A5BC73 | pipeline | place | neutral | `RAW.FDIC` | `TBD` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
