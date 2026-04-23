# ApartmentIQ — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/apartmentiq/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/apartmentiq/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_021` |
| **vendor_code** | `apartmentiq` |
| **vendor_label** | ApartmentIQ |
| **definition** | ApartmentIQ multifamily property and unit KPI competitive market data for BH OpCo |
| **data_type** | survey |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.BH` |
| **data_share_type** | snowflake_share |
| **vertical_codes** | resi |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md](../migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md)

---

## Vendor methodology (full text from `docs/vendor/apartmentiq/apartmentiq.md`)

**Catalog row:** `vendor_id` = `VND_021` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

ApartmentIQ multifamily property and unit KPI competitive market data for BH OpCo

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | survey |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.BH` |
| **is_active** | TRUE |
| **data_share_type** | snowflake_share |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | resi |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`apartmentiq`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`](../migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md)

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
| APARTMENTIQ_MAN_B71B024A | pipeline | place | neutral | `SOURCE_ENTITY.BH` | `TBD` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
