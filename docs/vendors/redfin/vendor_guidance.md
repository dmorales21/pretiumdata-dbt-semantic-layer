# Redfin — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/redfin/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/redfin/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_008` |
| **vendor_code** | `redfin` |
| **vendor_label** | Redfin |
| **definition** | Redfin residential housing market data covering median sale price DOM inventory and list-to-sale ratio at MSA and ZIP grain |
| **data_type** | transactional |
| **refresh_cadence** | weekly |
| **contract_status** | active |
| **source_schema** | `RAW.REDFIN` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_STANFORD_REDFIN.md](../migration/MIGRATION_TASKS_STANFORD_REDFIN.md)

---

## Vendor methodology (full text from `docs/vendor/redfin/redfin.md`)

**Catalog row:** `vendor_id` = `VND_008` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Redfin residential housing market data covering median sale price DOM inventory and list-to-sale ratio at MSA and ZIP grain

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | transactional |
| **refresh_cadence** | weekly |
| **contract_status** | active |
| **source_schema** | `RAW.REDFIN` |
| **is_active** | TRUE |
| **data_share_type** | s3 |
| **is_motherduck_served** | TRUE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`redfin`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_STANFORD_REDFIN.md`](../migration/MIGRATION_TASKS_STANFORD_REDFIN.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 60 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 60 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 60 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| REDFIN_MAN_97A1BAA2EB | pipeline | place | positive | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `ABSORPTION_RATE` |
| REDFIN_MAN_5C12BB718B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `AVG_SALE_TO_LIST` |
| REDFIN_MAN_B42BDFC8E2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `AVG_SALE_TO_LIST_MOM` |
| REDFIN_MAN_406791C407 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `AVG_SALE_TO_LIST_YOY` |
| REDFIN_MAN_E11A23C13F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `HOMES_SOLD` |
| REDFIN_MAN_C60F6F0803 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `HOMES_SOLD_MOM` |
| REDFIN_MAN_0D5EA5F164 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `HOMES_SOLD_YOY` |
| REDFIN_MAN_1C9CABFEB9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `INVENTORY` |
| REDFIN_MAN_1FC64CEA7C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `INVENTORY_MOM` |
| REDFIN_MAN_39FEC858D0 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `INVENTORY_YOY` |
| REDFIN_MAN_0F4115B5A2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `LIST_TO_SALE_RATIO` |
| REDFIN_MAN_4AC187040A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_DOM` |
| REDFIN_MAN_98989AA405 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_DOM_MOM` |
| REDFIN_MAN_00CD93ADF4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_DOM_YOY` |
| REDFIN_MAN_C438929EF2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_LIST_PPSF` |
| REDFIN_MAN_AAA0F69E9C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_LIST_PPSF_MOM` |
| REDFIN_MAN_072744B48F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_LIST_PPSF_YOY` |
| REDFIN_MAN_D6E95B7D24 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_LIST_PRICE` |
| REDFIN_MAN_5DE5B7D63B | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_LIST_PRICE_MOM` |
| REDFIN_MAN_A785813770 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_LIST_PRICE_YOY` |
| REDFIN_MAN_F3F4BEC21D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_PPSF` |
| REDFIN_MAN_6F9041E4A9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_PPSF_MOM` |
| REDFIN_MAN_9A5B03A44C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_PPSF_YOY` |
| REDFIN_MAN_1CD9237F95 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_SALE_PRICE` |
| REDFIN_MAN_81240DF498 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_SALE_PRICE_MOM` |
| REDFIN_MAN_C0557670A7 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MEDIAN_SALE_PRICE_YOY` |
| REDFIN_MAN_BA05F263C7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MONTHS_OF_SUPPLY` |
| REDFIN_MAN_83B7030BD1 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MONTHS_OF_SUPPLY_MOM` |
| REDFIN_MAN_2DF24EF007 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `MONTHS_OF_SUPPLY_YOY` |
| REDFIN_MAN_9CE0B9811A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `NEW_LISTINGS` |
| REDFIN_MAN_8E9A765A6B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `NEW_LISTINGS_MOM` |
| REDFIN_MAN_FD8322EBDC | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `NEW_LISTINGS_YOY` |
| REDFIN_MAN_83E20A7C64 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `OFF_MARKET_IN_TWO_WEEKS` |
| REDFIN_MAN_D47EE7AABA | pipeline | place | positive | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `PENDING_SALES` |
| REDFIN_MAN_F98623C58D | pipeline | place | positive | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `PENDING_SALES_MOM` |
| REDFIN_MAN_020B04E961 | pipeline | place | positive | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `PENDING_SALES_YOY` |
| REDFIN_MAN_8B9F3A9DC2 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `PRICE_DROPS` |
| REDFIN_MAN_37568D02C2 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `PRICE_DROPS_MOM` |
| REDFIN_MAN_5BD4740C2F | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `PRICE_DROPS_YOY` |
| REDFIN_MAN_4FEDF01A39 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `SOLD_ABOVE_LIST` |
| REDFIN_MAN_33E7090FC3 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `SOLD_ABOVE_LIST_MOM` |
| REDFIN_MAN_051DF5B08E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_COUNTY_H3_MONTHLY` | `SOLD_ABOVE_LIST_YOY` |
| REDFIN_MAN_D08C4C19CF | pipeline | place | positive | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `ABSORPTION_RATE_WAVG` |
| REDFIN_MAN_4B3959AF6D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `AVG_SALE_TO_LIST_WAVG` |
| REDFIN_MAN_C91BCCD4D9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `CONTRIBUTING_ZIP_COUNT` |
| REDFIN_MAN_3C402FA581 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `HOMES_SOLD_WAVG` |
| REDFIN_MAN_E75E4484F0 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `INVENTORY_WAVG` |
| REDFIN_MAN_D3D5B3F06B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `LIST_TO_SALE_RATIO_WAVG` |
| REDFIN_MAN_05937F6D81 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `MEDIAN_DOM_WAVG` |
| REDFIN_MAN_BC3DCDC7E7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_REDFIN_H3_R8_MONTHLY` | `MEDIAN_LIST_PPSF_WAVG` |

*(10 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
