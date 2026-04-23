# CoStar — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/costar/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/costar/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_013` |
| **vendor_code** | `costar` |
| **vendor_label** | CoStar |
| **definition** | CoStar multifamily market export property metrics fund metrics and scenario forecasts |
| **data_type** | survey |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `RAW.COSTAR` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_COSTAR.md](../migration/MIGRATION_TASKS_COSTAR.md)

---

## Vendor methodology (full text from `docs/vendor/costar/costar.md`)

**Catalog row:** `vendor_id` = `VND_013` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

CoStar multifamily market export property metrics fund metrics and scenario forecasts

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | survey |
| **refresh_cadence** | quarterly |
| **contract_status** | active |
| **source_schema** | `RAW.COSTAR` |
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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`costar`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_COSTAR.md`](../migration/MIGRATION_TASKS_COSTAR.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 190 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 190 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 190 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| COSTAR_1048 | homeprice | housing | positive | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `APPRECIATION_RETURN` |
| COSTAR_1006 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_1BR` |
| COSTAR_1007 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_2BR` |
| COSTAR_1008 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_3BR` |
| COSTAR_1013 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_GROWTH_MOM` |
| COSTAR_1014 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_GROWTH_YOY` |
| COSTAR_1017 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_INDEX` |
| COSTAR_1002 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_PER_SF` |
| COSTAR_1001 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_PER_UNIT` |
| COSTAR_1005 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASKING_RENT_STUDIO` |
| COSTAR_1051 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `ASSET_VALUE` |
| COSTAR_1058 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `AVG_SALE_PRICE` |
| COSTAR_1059 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `AVG_UNITS_SOLD` |
| COSTAR_1027 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `BUILDINGS_DELIVERED` |
| COSTAR_1025 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `BUILDINGS_UNDER_CONSTRUCTION` |
| COSTAR_1050 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `CAPITAL_VALUE_INDEX` |
| COSTAR_1044 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `CAP_RATE` |
| COSTAR_1037 | rent | housing | positive | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `DEMAND_UNITS` |
| COSTAR_1010 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_1BR` |
| COSTAR_1011 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_2BR` |
| COSTAR_1012 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_3BR` |
| COSTAR_1015 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_GROWTH_MOM` |
| COSTAR_1016 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_GROWTH_YOY` |
| COSTAR_1004 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_PER_SF` |
| COSTAR_1003 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_PER_UNIT` |
| COSTAR_1009 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EFFECTIVE_RENT_STUDIO` |
| COSTAR_1033 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `EXISTING_BUILDINGS` |
| COSTAR_1053 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `HOUSEHOLDS` |
| COSTAR_1047 | homeprice | housing | positive | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `INCOME_RETURN` |
| COSTAR_1057 | employment | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `INDUSTRIAL_EMPLOYMENT` |
| COSTAR_1023 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `INVENTORY_UNITS` |
| COSTAR_1046 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MARKET_CAP_RATE` |
| COSTAR_1063 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MARKET_SALE_PRICE_GROWTH` |
| COSTAR_1062 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MARKET_SALE_PRICE_INDEX` |
| COSTAR_1061 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MARKET_SALE_PRICE_PER_UNIT` |
| COSTAR_1045 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MEDIAN_CAP_RATE` |
| COSTAR_1054 | income | household | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MEDIAN_HOUSEHOLD_INCOME` |
| COSTAR_1043 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MEDIAN_PRICE_PER_BLDG_SF` |
| COSTAR_1041 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `MEDIAN_PRICE_PER_UNIT` |
| COSTAR_1022 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `NOI_INDEX` |
| COSTAR_1019 | occupancy | housing | positive | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `OCCUPANCY_RATE` |
| COSTAR_1056 | employment | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `OFFICE_EMPLOYMENT` |
| COSTAR_1052 | population | household | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `POPULATION` |
| COSTAR_1018 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `RENT_TO_INCOME_RATIO` |
| COSTAR_1040 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `SALES_VOLUME_TRANSACTIONS` |
| COSTAR_1038 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `SALE_COUNT` |
| COSTAR_1060 | rent | housing | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `SOLD_UNITS` |
| COSTAR_1021 | vacancy | housing | negative | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `STABILIZED_VACANCY_RATE` |
| COSTAR_1055 | employment | place | neutral | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `TOTAL_EMPLOYMENT` |
| COSTAR_1049 | homeprice | housing | positive | `TRANSFORM.DEV.FACT_COSTAR_CBSA_MONTHLY` | `TOTAL_RETURN` |

*(140 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
