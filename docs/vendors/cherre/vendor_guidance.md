# Cherre — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/cherre/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/cherre/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_011` |
| **vendor_code** | `cherre` |
| **vendor_label** | Cherre |
| **definition** | Cherre property data platform covering MLS recorder tax assessor AVM rent roll demographics and unit availability |
| **data_type** | transactional |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `RAW.CHERRE` |
| **data_share_type** | snowflake_share |
| **vertical_codes** | — |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_CHERRE.md](../migration/MIGRATION_TASKS_CHERRE.md)

---

## Vendor methodology (full text from `docs/vendor/cherre/cherre.md`)

**Catalog row:** `vendor_id` = `VND_011` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Cherre property data platform covering MLS recorder tax assessor AVM rent roll demographics and unit availability

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | transactional |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `RAW.CHERRE` |
| **is_active** | TRUE |
| **data_share_type** | snowflake_share |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`cherre`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_CHERRE.md`](../migration/MIGRATION_TASKS_CHERRE.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 267 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 267 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 268 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_149 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `MEDIAN_MARKET_PPSF` |
| MET_155 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `PCT_PRE_1980` |
| MET_152 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `UNITS_GARDEN` |
| CHERRE_MAN_B72A8BBA | transactions | housing | positive | `TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY` | `transactions_current` |
| CHERRE_FAM_95510AA8620E | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `AVG_AVM` |
| CHERRE_FAM_BC36C400BB9A | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `AVG_CONFIDENCE_SCORE` |
| CHERRE_FAM_EBE5EB3CC005 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `AVM_TO_ASSESSED_RATIO` |
| CHERRE_FAM_13BF023F3242 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `MEDIAN_ASSESSED_VALUE` |
| CHERRE_FAM_5AC161FBC938 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `MEDIAN_AVM` |
| CHERRE_FAM_60A53186C59F | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `MEDIAN_AVM_HIGH` |
| CHERRE_FAM_02EE69D585D0 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `MEDIAN_AVM_LOW` |
| CHERRE_FAM_6C22B51860F9 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `MEDIAN_CONFIDENCE_SCORE` |
| CHERRE_FAM_8D5F762CF928 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `P25_AVM` |
| CHERRE_FAM_AECD87746472 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `P75_AVM` |
| CHERRE_FAM_F42E647FE38E | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY` | `PARCEL_COUNT` |
| CHERRE_FAM_D88B77CE9E02 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `AVG_AVM` |
| CHERRE_FAM_D17EC947391A | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `AVG_CONFIDENCE_SCORE` |
| CHERRE_FAM_A1ECF3F44BA6 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `AVM_TO_ASSESSED_RATIO` |
| CHERRE_FAM_C1170BF79C62 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `MEDIAN_ASSESSED_VALUE` |
| CHERRE_FAM_EBEE0F7CC894 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `MEDIAN_AVM` |
| CHERRE_FAM_D0F42598145E | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `MEDIAN_AVM_HIGH` |
| CHERRE_FAM_A980C68135D7 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `MEDIAN_AVM_LOW` |
| CHERRE_FAM_4C2933376BE4 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `MEDIAN_AVM_RANGE_PCT` |
| CHERRE_FAM_10BA94BB9F27 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `MEDIAN_CONFIDENCE_SCORE` |
| CHERRE_FAM_73406CD9F1A9 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `P25_AVM` |
| CHERRE_FAM_B134883A38D4 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `P75_AVM` |
| CHERRE_FAM_CBA4D2E24F9D | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_AVM_H3_R8_MONTHLY` | `PARCEL_COUNT` |
| CHERRE_FAM_AA247B943F98 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_DEMO_H3_R8_SNAPSHOT` | `ACS_YEAR_MAX` |
| CHERRE_FAM_A2033E5D3D9B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_DEMO_H3_R8_SNAPSHOT` | `COMMUTER_CAR_SHARE` |
| CHERRE_FAM_06956191130C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_DEMO_H3_R8_SNAPSHOT` | `COMMUTER_TRANSIT_SHARE` |
| CHERRE_FAM_0B86A6840E86 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_DEMO_H3_R8_SNAPSHOT` | `TOTAL_COMMUTERS_WAVG` |
| CHERRE_DEV_LISTINGS_COUNTY_ACTIVE | pipeline | place | positive | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `ACTIVE_LISTING_COUNT` |
| CHERRE_DEV_LISTINGS_COUNTY_EVENTS | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `LISTING_EVENT_COUNT` |
| CHERRE_DEV_LISTINGS_COUNTY_LIST_PRICE | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `LIST_PRICE_MEDIAN` |
| CHERRE_DEV_LISTINGS_COUNTY_PPSF | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `MARKET_PPSF_MEDIAN` |
| CHERRE_DEV_LISTINGS_COUNTY_DOM | listings | housing | negative | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `MLS_DOM_MEDIAN` |
| CHERRE_DEV_LISTINGS_COUNTY_SFR | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `SFR_LISTING_COUNT` |
| CHERRE_DEV_LISTINGS_COUNTY_SOLD | listings | housing | positive | `TRANSFORM.DEV.FACT_CHERRE_LISTINGS_COUNTY` | `SOLD_LISTING_COUNT` |
| CHERRE_FAM_857E1FE1B9F9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `APT_UNCLASSIFIED_COUNT` |
| CHERRE_FAM_503E1321D851 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `DUPLEX_COUNT` |
| CHERRE_FAM_07686C23D50D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `GARDEN_COUNT` |
| CHERRE_FAM_2BC8FF354A27 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `HIGHRISE_COUNT` |
| CHERRE_FAM_586DBEBCA515 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_ANNUAL_TAX` |
| CHERRE_FAM_23B68C7D449D | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_ASSESSED_VALUE` |
| CHERRE_FAM_C980DCDCED70 | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_ASSESSED_VALUE_PER_UNIT` |
| CHERRE_FAM_8C79C72AE755 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_BUILDING_SQFT` |
| CHERRE_FAM_94452920DE6A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_EFFECTIVE_TAX_RATE` |
| CHERRE_FAM_142C6C8E4A18 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_EFFECTIVE_YEAR_BUILT` |
| CHERRE_FAM_5FF16B087E12 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_LOT_SIZE_SQFT` |
| CHERRE_FAM_0D5E8212E79C | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_CHERRE_MF_COUNTY_SNAPSHOT` | `MEDIAN_MARKET_VALUE` |

*(217 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
