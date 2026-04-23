# Yardi Matrix — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/yardi_matrix/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/yardi_matrix/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_053` |
| **vendor_code** | `yardi_matrix` |
| **vendor_label** | Yardi Matrix |
| **definition** | Yardi Matrix multifamily market performance and submarket crosswalk feeds under TRANSFORM.DEV or TRANSFORM.YARDI_MATRIX |
| **data_type** | survey |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.YARDI_MATRIX` |
| **data_share_type** | snowflake_share |
| **vertical_codes** | resi |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/yardi_matrix/yardi_matrix.md`)

**Catalog row:** `vendor_id` = `VND_053` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Yardi Matrix multifamily market performance and submarket crosswalk feeds under TRANSFORM.DEV or TRANSFORM.YARDI_MATRIX

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | survey |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.YARDI_MATRIX` |
| **data_share_type** | snowflake_share |

## 3. Read path

See [OPERATING_MODEL.md](../OPERATING_MODEL.md) and [migration/MIGRATION_RULES.md](../migration/MIGRATION_RULES.md).



---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 1 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 1 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 1 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| YARDI_MATRIX_1001 | rent | housing | neutral | `TRANSFORM.DEV.FACT_YARDI_MATRIX_MARKETPERFORMANCE_BH` | `DATATYPE` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
