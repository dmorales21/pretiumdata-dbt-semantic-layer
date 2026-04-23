# Zonda — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/zonda/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/zonda/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_015` |
| **vendor_code** | `zonda` |
| **vendor_label** | Zonda |
| **definition** | Zonda new construction BTR project tracking starts closings plans deeds and survey data at property and CBSA grain |
| **data_type** | survey |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.TPANALYTICS` |
| **data_share_type** | snowflake_share |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/zonda/zonda.md`)

**Catalog row:** `vendor_id` = `VND_015` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Zonda new construction BTR project tracking starts closings plans deeds and survey data at property and CBSA grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | survey |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `RAW.TPANALYTICS` |
| **is_active** | TRUE |
| **data_share_type** | snowflake_share |
| **is_motherduck_served** | TRUE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`zonda`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 53 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 53 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 54 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_145 | supply_pipeline | housing | neutral | `TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY` | `supply_pipeline_current` |
| ZONDA_MAN_B72A8BBA | transactions | housing | positive | `TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY` | `transactions_current` |
| ZONDA_MAN_BF9A006744 | rent | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_AVG_RENT_WAVG` |
| ZONDA_MAN_6E5AA4FB7E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_AVG_SQFT_WAVG` |
| ZONDA_MAN_F45CBC7AE2 | permits | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_MEDIAN_CONSTRUCTION_DAYS` |
| ZONDA_MAN_B6B3FE12DD | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_MEDIAN_DAYS_IN_LEASING` |
| ZONDA_MAN_72DE06B1BE | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_OCCUPIED_UNITS_TOTAL` |
| ZONDA_MAN_0F4BD2B110 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_OCC_PCT_STABILIZED_WAVG` |
| ZONDA_MAN_627888CD2F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_OCC_PCT_WAVG` |
| ZONDA_MAN_DE9588A802 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_PIPELINE_PRESSURE_RATIO` |
| ZONDA_MAN_B5C7F267E4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_PROJECTS_ACTIVE` |
| ZONDA_MAN_F01222E32B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_PROJECTS_PIPELINE` |
| ZONDA_MAN_F80D8113FE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_PROJECT_COUNT` |
| ZONDA_MAN_81C82D98FD | rent | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_RENT_PSF_WAVG` |
| ZONDA_MAN_D57EEC31BB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_TOTAL_UNITS_INVENTORY` |
| ZONDA_MAN_7AE97A4DC7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_UNITS_PIPELINE` |
| ZONDA_MAN_91B0531348 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `COUNTY_UNITS_STABILIZED` |
| ZONDA_MAN_5EDD5F1F91 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_COUNTY_MONTHLY` | `HEX_COUNT` |
| ZONDA_MAN_EB5DBD4AAA | rent | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `AVG_RENT_WAVG` |
| ZONDA_MAN_B9887B55C8 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `AVG_SQFT_WAVG` |
| ZONDA_MAN_AB31F147A4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `BUILDER_HHI_APPROX` |
| ZONDA_MAN_65A3C37B67 | permits | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `MEDIAN_CONSTRUCTION_DAYS` |
| ZONDA_MAN_37433E6481 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `MEDIAN_DAYS_IN_LEASING` |
| ZONDA_MAN_585DA61E8F | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `OCCUPIED_UNITS_TOTAL` |
| ZONDA_MAN_01F3A34EC0 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `OCC_PCT_STABILIZED_WAVG` |
| ZONDA_MAN_F432F018C7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `OCC_PCT_WAVG` |
| ZONDA_MAN_918688D5F2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `PIPELINE_PRESSURE_RATIO` |
| ZONDA_MAN_77B796EF5D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `PROJECTS_ACTIVE` |
| ZONDA_MAN_CA42C02F2E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `PROJECTS_PIPELINE` |
| ZONDA_MAN_D3357B9D6A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `PROJECT_COUNT` |
| ZONDA_MAN_69A4173829 | rent | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `RENT_PSF_WAVG` |
| ZONDA_MAN_16471343E9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `TOTAL_UNITS_INVENTORY` |
| ZONDA_MAN_76E3563FAE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `UNITS_LEASING` |
| ZONDA_MAN_464946250F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `UNITS_PIPELINE` |
| ZONDA_MAN_3D05B18BCA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_BTR_H3_R8_MONTHLY` | `UNITS_STABILIZED` |
| ZONDA_MAN_6F8C5B4EAA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `CASH_BUYER_SHARE` |
| ZONDA_MAN_CD423BD664 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `FLIP_SHARE` |
| ZONDA_MAN_6170E4ACB0 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `INSTITUTIONAL_BUYER_COUNT` |
| ZONDA_MAN_9491EB17EF | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `INSTITUTIONAL_BUYER_SHARE` |
| ZONDA_MAN_69CE17EBA5 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `MEDIAN_PPSF` |
| ZONDA_MAN_C647D0EBE9 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `MEDIAN_TRANSACTION_VALUE` |
| ZONDA_MAN_6672A42550 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `SALE_COUNT` |
| ZONDA_MAN_BF6BE8B891 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `YOY_MEDIAN_PRICE_PCT` |
| ZONDA_MAN_51B75C6A80 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY` | `YOY_TRANSACTION_VOLUME_PCT` |
| ZONDA_MAN_3018B6382B | pipeline | place | positive | `TRANSFORM.DEV.FACT_ZONDA_SFR_H3_R8_MONTHLY` | `SFR_ABSORPTION_RATE_WAVG` |
| ZONDA_MAN_87232B8649 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_SFR_H3_R8_MONTHLY` | `SFR_ANNUAL_CLOSINGS_WAVG` |
| ZONDA_MAN_FD19765075 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_SFR_H3_R8_MONTHLY` | `SFR_ANNUAL_STARTS_WAVG` |
| ZONDA_MAN_51D54E1D18 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_SFR_H3_R8_MONTHLY` | `SFR_INVENTORY_TOTAL_WAVG` |
| ZONDA_MAN_8A7CDA9D44 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_SFR_H3_R8_MONTHLY` | `SFR_INVENTORY_UC_WAVG` |
| ZONDA_MAN_152A81ECC7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ZONDA_SFR_H3_R8_MONTHLY` | `SFR_MEDIAN_PPSF_WAVG` |

*(3 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
