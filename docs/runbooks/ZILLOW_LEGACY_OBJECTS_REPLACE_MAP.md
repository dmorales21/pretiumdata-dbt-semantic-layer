# Zillow legacy objects superseded by **TRANSFORM.DEV** research facts

**Purpose:** Tie the ten long-form **`TRANSFORM.DEV.FACT_ZILLOW_*`** tables in this repo to **legacy** `TRANSFORM_PROD` / `EDW_PROD` objects that were built for the same vendor signals (wide cleaned views, fixed ZIP facts, joined rollups). Use this when planning **DROP VIEW** / consumer rewires — not as permission to drop without lineage review.

**Canonical build:** `pretiumdata-dbt-semantic-layer` → `models/transform/dev/zillow/` (not `pretium-ai-dbt` `zillow_research` duplicates).

**Sources of legacy names:** `pretium-ai-dbt` smoke audit outputs (`smoke_deletion_candidates_objects_empty_and_error.csv`, `smoke_error_execute_drop_error_views.sql`, `smoke_error_logic_log.csv`).

---

## 1. New fact → Zillow Research `RAW_*` → what legacy layer used to approximate

Legacy stacks often used **one view per series × grain** (e.g. `ZILLOW_ZHVI_CBSA`) or **ZIP “fixed” facts** with a different column contract. The new pattern is **one tall table per research dataset**, with **`metric_id`** discriminating series (from file name). Mapping is **many-to-one** onto the new fact.

| New `TRANSFORM.DEV` object | `SOURCE_PROD.ZILLOW` raw | Legacy objects (same signal family — drop only after lineage) |
|----------------------------|--------------------------|----------------------------------------------------------------|
| `FACT_ZILLOW_HOME_VALUES` | `RAW_HOME_VALUES` | `TRANSFORM_PROD.CLEANED.CLEANED_ZILLOW_ZHVI_ZIP`, `ZILLOW_ZHVI_ZIP`, `ZILLOW_ZHVI_ZIP_TEST`, `ZILLOW_ZHVI_CBSA`, `ZILLOW_ZHVI_MSA`, `TRANSFORM_PROD.FACT.FACT_ZILLOW_ZHVI_ZIP_FIXED`, `FACT_ZILLOW_ZHVI_COUNTY_FIXED`, `FACT_ZILLOW_ZHVI_STATE_FIXED`, `FACT_ZILLOW_ZHVI_PRICING`, `FACT_ZILLOW_ZIP_TS_DEDUPED`, `FACT_ZILLOW_MSA_TS_CLEAN`, `FACT_ZILLOW_STATE_TS`, `FACT_ZILLOW_CITY_TS_DEDUPED` |
| `FACT_ZILLOW_HOME_VALUES_FORECASTS` | `RAW_HOME_VALUES_FORECASTS` | `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVF_MSA`; EDW `ZILLOW_ZHVF_ZIP_TOOLS_MIN` (upstream drift / missing schema in audits) |
| `FACT_ZILLOW_RENTALS` | `RAW_RENTALS` | `ZILLOW_ZORI_CBSA`, `ZILLOW_ZODRI_CBSA`, `FACT_ZILLOW_ZORI_ZIP_FIXED`, `FACT_ZILLOW_ZORI_CBSA_FIXED`; dbt audit tables `NOT_NULL_CLEANED_ZILLOW_ZORI_*` |
| `FACT_ZILLOW_RENTAL_FORECASTS` | `RAW_RENTAL_FORECASTS` | (no dedicated row in smoke excerpt — treat as forecast-side analog to ZHVF row above once identified) |
| `FACT_ZILLOW_FOR_SALE_LISTINGS` | `RAW_FOR_SALE_LISTINGS` | `ZILLOW_LISTINGS_SFR_MSA`, `ZILLOW_LISTINGS_SFRCONDO_MSA`, `ZILLOW_PENDING_MSA` |
| `FACT_ZILLOW_SALES` | `RAW_SALES` | Joined rollups that mixed sales with other series (see §2) |
| `FACT_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS` | `RAW_DAYS_ON_MARKET_AND_PRICE_CUTS` | Often folded into `ZILLOW_ALL_METRICS_*` |
| `FACT_ZILLOW_MARKET_HEAT_INDEX` | `RAW_MARKET_HEAT_INDEX` | `ZILLOW_ALL_METRICS_*` |
| `FACT_ZILLOW_NEW_CONSTRUCTION` | `RAW_NEW_CONSTRUCTION` | `ZILLOW_ALL_METRICS_*` |
| `FACT_ZILLOW_AFFORDABILITY` | `RAW_AFFORDABILITY` | `CLEANED_ZILLOW_SHARE_HOUSEHOLD_INCOME` (empty in audit — still legacy surface) |

**Not a 1:1 physical replacement:** `TRANSFORM_PROD.JOINED.FACT_ZILLOW_CBSA_METRICS` was referenced by **ANALYTICS_PROD.SANDBOX** views when missing; a CBSA rollup is now obtained by **querying the tall facts** with `geo_level_code = 'cbsa'` (metro normalized to CBSA in the macro) and the right **`metric_id`** filters, or a future **`TRANSFORM.DEV.CONCEPT_*`** model — not a single renamed view.

---

## 2. Joined / EDW wrappers (drop after consumers move off)

These depend on broken or missing upstreams; they do **not** live in `TRANSFORM.DEV` and are **candidates** to drop once tooling reads **`TRANSFORM.DEV.FACT_ZILLOW_*`** or **`SOURCE_PROD.ZILLOW.RAW_*`**.

| Legacy object | Notes |
|---------------|--------|
| `TRANSFORM_PROD.JOINED.ZILLOW_ALL_METRICS_MSA` | Expansion failures (`ZILLOW_ZHVF_MSA` / `RAW.ZILLOW` in audit) |
| `TRANSFORM_PROD.JOINED.ZILLOW_ALL_METRICS_ZIP` | Stale DDL (`NAME_ZIP`); blocks `EDW_PROD.TOOLS.MARKET_INTELLIGENCE_ZIP`, `ZILLOW_ZIP_APP_VIEW` |
| `TRANSFORM_PROD.JOINED.FACT_ZILLOW_CBSA_METRICS` | Missing/unauthorized — downstream sandbox views already broken |
| `EDW_PROD.TOOLS.ZILLOW_MSA_APP_VIEW` | Depends on `ZILLOW_ALL_METRICS_MSA` |
| `EDW_PROD.TOOLS.ZILLOW_ZIP_APP_VIEW` | Depends on `ZILLOW_ALL_METRICS_ZIP` |
| `EDW_PROD.TOOLS.ZILLOW_ZHVI_CBSA_TOOLS_MIN` | Audit: `TRANSFORM_PROD.GOLD` missing |
| `EDW_PROD.TOOLS.ZILLOW_ZHVF_ZIP_TOOLS_MIN` | Audit: `TRANSFORM_PROD.GOLD` missing |

---

## 3. Duplicate models in **pretium-ai-dbt** (retire runs, not Snowflake objects)

Path: `pretium-ai-dbt/dbt/models/transform/dev/zillow_research/fact_zillow_*.sql` — same intent as this repo. **Prefer a single dbt project** for builds to avoid two pipelines writing the same **`TRANSFORM.DEV`** relation names.

---

## 4. Executable drop list (optional)

Consolidated **`DROP VIEW IF EXISTS`** statements for **`TRANSFORM_PROD`** / **`EDW_PROD`** candidates live in:

[sql/legacy_zillow_drop_candidates_transform_production.sql](./sql/legacy_zillow_drop_candidates_transform_production.sql)

Read the header in that file before executing: confirm **no active lineage**, correct **role**, and policy on **EDW** tools.

---

## 5. Change log

| Date | Author | Change |
|------|--------|--------|
| 2026-04-18 | Cursor agent | Initial replacement map from smoke audit + model/raw mapping. |
