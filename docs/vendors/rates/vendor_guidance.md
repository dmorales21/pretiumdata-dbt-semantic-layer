# Pretium rates payload — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/rates/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/rates/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_052` |
| **vendor_code** | `rates` |
| **vendor_label** | Pretium rates payload |
| **definition** | Curated national daily macro rates CPI treasury and breakeven series from SOURCE_PROD.RATES flattened to TRANSFORM.DEV |
| **data_type** | administrative |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `SOURCE_PROD.RATES` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/rates/rates.md`)

**Catalog row:** `vendor_id` = `VND_052` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Curated national daily macro rates CPI treasury and breakeven series from SOURCE_PROD.RATES flattened to TRANSFORM.DEV

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `SOURCE_PROD.RATES` |
| **data_share_type** | s3 |

## 3. Read path

See [OPERATING_MODEL.md](../OPERATING_MODEL.md) and [migration/MIGRATION_RULES.md](../migration/MIGRATION_RULES.md).



---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 1 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 1 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 22 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| RATES_MAN_FF400DBD | rates | capital | negative | `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` | `VALUE` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
