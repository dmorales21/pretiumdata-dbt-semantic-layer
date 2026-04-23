# IRS / U.S. Treasury — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/irs/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/irs/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_043` |
| **vendor_code** | `irs` |
| **vendor_label** | IRS / U.S. Treasury |
| **definition** | Tax Statistics of Income migration and filings as surfaced through Cybersyn GLOBAL_GOVERNMENT tables |
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.IRS` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/irs/irs.md`)

**Catalog row:** `vendor_id` = `VND_043` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Tax Statistics of Income migration and filings as surfaced through Cybersyn GLOBAL_GOVERNMENT tables

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.IRS` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`irs`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 24 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 24 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 24 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_014 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL_CBSA` | `VALUE` |
| MET_009 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL_COUNTY` | `VALUE` |
| IRS_MAN_58CC5B6A07 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `AVG_INBOUND_AGI` |
| IRS_MAN_E6BBE8F712 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `AVG_OUTBOUND_AGI` |
| IRS_MAN_7AF79376E9 | migration | household | positive | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `INCOME_QUALITY_RATIO` |
| IRS_MAN_A21DC71875 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `INFLOW_AGI_USD` |
| IRS_MAN_B4E1A971E2 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `INFLOW_PERSONS` |
| IRS_MAN_5FA81CE272 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `INFLOW_PERSONS_PER_RETURN` |
| IRS_MAN_39FA5DA342 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `INFLOW_RETURNS` |
| IRS_MAN_E8A001720D | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `IRS_YEAR` |
| IRS_MAN_5055E1F70D | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `MIGRATION_CHURN_RATE` |
| IRS_MAN_6CE9AB12B5 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `NET_AGI_PER_NET_RETURN` |
| IRS_MAN_444D6C04A2 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `NET_AGI_USD` |
| IRS_MAN_60AC70BEA3 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `NET_PERSONS` |
| IRS_MAN_F07D16CF37 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `NET_RETURNS` |
| IRS_MAN_4F13E54DC0 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `OUTFLOW_AGI_USD` |
| IRS_MAN_FE4F8972E3 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `OUTFLOW_PERSONS` |
| IRS_MAN_F6C9C9EEC7 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `OUTFLOW_PERSONS_PER_RETURN` |
| IRS_MAN_188A669DB8 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_COUNTY` | `OUTFLOW_RETURNS` |
| IRS_MAN_3626490D54 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_CBSA` | `SUPPRESSED` |
| MET_015 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_CBSA` | `VALUE` |
| IRS_MAN_8BFBDC8E9E | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY` | `SUPPRESSED` |
| MET_010 | migration | household | neutral | `TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY` | `VALUE` |
| MET_100 | migration | household | neutral | `TRANSFORM.DEV.fact_irs_soi_migration_by_characteristic_annual` | `VALUE` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
