# Zillow — Data Guidance

⚠️ **INTERNAL — contains contract and commercial details**

**Intake status:** Full pass completed (`sources.yml` + `metric.csv`).  
**Regenerate metrics CSV:** `python3 scripts/catalog/generate_docs_vendors_intake.py --vendor zillow`  
**Canonical methodology stub:** [`../../vendor/zillow.md`](../../vendor/zillow.md)  
**Metric shard:** [`../../vendor/metrics/zillow_metrics.csv`](../../vendor/metrics/zillow_metrics.csv)

## 1. Overview

Zillow **ZHVI / ZORI**, for-sale **ZIP** inventory panels, and **research long facts** (affordability, home values, rentals, sales, etc.) from **`SOURCE_PROD.ZILLOW`** with typed outputs in **`TRANSFORM.DEV`** and select **`TRANSFORM_PROD.FACT`** (e.g. ZIP time series). Catalog has **198** metrics across **23** distinct `table_path` values; physical-column collapse yields **`vendor_metrics.csv`** rows (long-form `METRIC_VALUE` tables collapse many metrics per column).

## 2. Contract & Access

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_ZLW` |
| **vendor_code** | `zillow` |
| **data_type** | transactional |
| **refresh_cadence** | monthly |
| **contract_status** | active |
| **source_schema** | `SOURCE_PROD.ZILLOW` |
| **data_share_type** | snowflake_share |

- **Major sources:** `dbt/models/sources.yml` — `source('zillow', …)` including ZHVI/ZORI ZIP and MSA tables, `zip_monthly_for_sale`, `fact_zillow_zip_ts` (prod fact), research batch metadata, crosswalks (`zillow_to_census_cbsa_mapping`, city mapping).  
- **Read path:** Prefer vetted **TRANSFORM** / **FACT** objects over raw VARIANT research tables; see comments on broken `fact_zillow_zip_ts_deduped` chain in `sources.yml`.

## 3. Datasets (high level)

### Production ZIP time series

- **`TRANSFORM_PROD.FACT.FACT_ZILLOW_ZIP_TS`** — canonical **ZHVI** (and related) **ZIP** time series; **`VALUE`** column with **`METRIC_ID`** dimension in wide/metricized shape.

### For-sale ZIP monthly (DEV)

- **`TRANSFORM.DEV.FACT_ZILLOW_FOR_SALE_INVENTORY_ZIP_MONTHLY`** — inventory, DOM, listings, pending, months of supply, etc.  
- **Upstream:** `source('zillow','zip_monthly_for_sale')` on **`SOURCE_PROD.ZILLOW`** per sources.

### Research long facts (DEV, `METRIC_VALUE`)

- Tables such as **`FACT_ZILLOW_HOME_VALUES`**, **`FACT_ZILLOW_RENTALS`**, **`FACT_ZILLOW_SALES`**, **`FACT_ZILLOW_AFFORDABILITY`**, **`FACT_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS`**, etc. — **long-form** with **`METRIC_VALUE`**; disambiguate with vendor **`METRIC_ID`**.

### Parcl-compatible absorption (DEV)

- **`FACT_ZILLOW_ABSORPTION_PARCL_COMPAT_ZIP_MONTHLY`** — column names aligned to Parcl-style absorption for feature swaps.

**Physical rows:** See **`vendor_metrics.csv`** (30 unique physical columns after collapse from **198** metrics).

## 4. Concept Mapping

- **Empty `concept_code`:** **0** / 198.  
- **Domains:** Mostly **housing**; some **household** (income) on affordability series—see CSV.

## 5. Join Keys

- **ZIP:** `ID_ZIP` / ZIP tables → geography bridges (ZCTA vs postal policy in `docs/governance/DATASET_POSTAL_VS_ZCTA_INVENTORY.md`).  
- **CBSA:** Zillow **6-digit** MSA IDs → **`zillow_to_census_cbsa_mapping`** for Census **5-digit** CBSA.  
- **City:** **`ZILLOW_ALL`** for state disambiguation on city ZORI/ZHVI.  
- **`[UNKNOWN — needs profiling]`** for neighborhood-level tables if enabled.

## 6. Refresh Cadence

- **Catalog:** monthly.  
- **Vendor / S3 / research batches:** `[UNKNOWN — needs profiling]` — see `ZILLOW_RESEARCH_BATCH_METADATA` in `sources.yml`.

## 7. Known Limitations

- **197 / 198** catalog rows reference **DEV** `table_path` in current seed—only a thin slice on **PROD** (`FACT_ZILLOW_ZIP_TS`).  
- **Long-form `METRIC_VALUE`:** Do not aggregate without **`METRIC_ID`**.  
- **Broken chain:** `fact_zillow_zip_ts_deduped` documented as broken in sources—use **`fact_zillow_zip_ts`**.

## 8. Changelog

| Date | Commit | Changed Rows | Notes |
|------|--------|--------------|-------|
| 2026-04-23 | — | — | Full intake pass; physical CSV from merged `metric.csv`. |

---

## Appendix — Gap flags

| Check | Result |
|--------|--------|
| **Metrics with empty `concept_code`** | **0** / 198 |
| **`table_path` contains DEV** | **197** / 198 |
| **Distinct `table_path`** | **23** |
| **`schema.yml`** | Strong coverage under `transform/dev`, `transform_prod`, `zillow_research`—audit weekly vs monthly coexistence on long facts. |
