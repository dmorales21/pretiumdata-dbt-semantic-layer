# Batch 022 — Deprecation / governance SnowSQL evidence (pretium-ai-dbt)

**Date:** 2026-04-19  
**Connection:** `snowsql -c pretium` (`USE ROLE ACCOUNTADMIN; USE WAREHOUSE AI_WH;`)  
**Script:** `pretium-ai-dbt/scripts/sql/migration/inventory_deprecation_candidates_batch022.sql`  
**Latency caveat:** `SNOWFLAKE.ACCOUNT_USAGE.*` views can lag up to **~2 hours**.

**Authoritative prose for `MIGRATION_LOG.md` → Deprecation candidates `reason` column** (semantic intent + recreation contract) is duplicated in that file for batch **022** rows. Summary:

- **Legacy Redfin `CLEANED_REDFIN_*`:** Normalize vendor ZIP/MSA into canonical housing-market grains; MOS backfill; ZIP metrics fed quality hooks → recreate as typed **`FACT_*`** from `cleaned_redfin_market_tracker_*` / `SOURCE_PROD.REDFIN` with **`metric_id`** + **`REFERENCE.GEOGRAPHY`**.
- **`ANALYTICS_PROD.SANDBOX` (55-name cluster):** IC / BPS / DDS / stats / Zonda / Progress experiments before **`FEATURE_*`/`MODEL_*`** promotion → recreate only what you keep under **`ANALYTICS.DBT_DEV`** with catalog registration.
- **Disabled / never-built dbt names:** ACS income legacy → **`fact_household_income_acs`** pattern; economic projections views → **`MODEL_*`/`ESTIMATE_*`** with scenario grain; `MART_RENT_SIGNALS_CBSA` → canonical **`MART_RENT_AFFORDABILITY_CBSA`** (AMI + rent spine for Prism/REQ/IC per `mart_rent_affordability_cbsa.sql`).

## 1) `ANALYTICS_PROD.SANDBOX` — existence

- **`INFORMATION_SCHEMA.TABLES`:** **89** relations (`BASE TABLE` + `VIEW`) in `ANALYTICS_PROD.SANDBOX` (full list captured in first query output of the script run).

## 2) `OBJECT_DEPENDENCIES` — inbound edges to SANDBOX

Query: `REFERENCED_DATABASE = 'ANALYTICS_PROD' AND REFERENCED_SCHEMA = 'SANDBOX'`.

- **29** dependency rows (another object’s persisted definition references this SANDBOX object).
- **Notable:** `ADMIN.GOVERNANCE.*` views reference **`SBOX_T_*`** wrappers in SANDBOX (e.g. `SBOX_T_FORCED_SALE_RISK_MARKETS` → `ADMIN.GOVERNANCE.FORCED_SALE_RISK_MARKETS`). **Do not drop SANDBOX `SBOX_T_*` without EDW/ADMIN coordination.**

## 3) SANDBOX objects with **zero** inbound `OBJECT_DEPENDENCIES` edges

Anti-join: all `SANDBOX` tables/views **minus** distinct `referenced_object_name` from `OBJECT_DEPENDENCIES` for that schema.

**55** object names (graph leaves in ACCOUNT_USAGE — still may be queried ad hoc; confirm with access history / product):

`BPS_CBSA_STABLE_SERIES`, `EXP_DDS_CDI_MIS_SPEC_SIMULATION`, `FORCED_SALE_RISK_MARKETS`, `IC_CINCINNATI_BTR_PRODUCT_FIT`, `IC_CINCINNATI_COMPARABILITY_REPORT`, `IC_CINCINNATI_LONGITUDINAL_EXPORT`, `IC_CINCINNATI_STATS_CORR_CBSA`, `IC_CINCINNATI_STATS_UNIVARIATE`, `IC_CINCINNATI_ZONDA_UNITS_BY_BEDROOM_H3`, `IC_EMPLOYMENT`, `IC_FEATURES_CBSA`, `IC_FEATURES_COUNTY_SMOOTHED`, `IC_FEATURES_H3_6`, `IC_GEONAMES_CINCINNATI`, `IC_HOUSEHOLDS_CBSA`, `IC_INDUSTRY`, `IC_INVENTORY`, `IC_PERMITS`, `IC_POPULATION`, `IC_UNEMPLOYMENT`, `IC_VALUE`, `MARKETS_WITH_DEMAND_GAP`, `METRO_DEMAND_SHIFTS`, `PROGRESS_FOR_SALE_INVENTORY_MOVEMENT`, `PROGRESS_MARKERR`, `PROGRESS_REDFIN`, `PROGRESS_RENTAL_LEASING_PACE`, `PROTO_DDS_2008_SIMULATION`, `PROTO_DDS_IC_DASHBOARD`, `PR_INTERNAL_VS_EXTERNAL`, `PR_MARKET_OVERVIEW`, `PR_MARKET_VELOCITY`, `PR_VS_MARKET_BENCHMARK`, `REDFIN_SLIDE_MIAMI_ORLANDO_V2`, `RE_ACQUISITIONS_FEATURES`, `RE_ACQUISITIONS_SERIES_V1_BACKUP`, `RE_ACQUISITIONS_SERIES_V1_T`, `SBOX_T_AI_ANALYTICS_COMPOSITE_V1`, `STATS_BIVARIATE_FEATURE_PRICE_MOMENTUM_ZIP`, `STATS_PLACE_QUALITY_DIMENSIONS_DISTRIBUTION`, `STATS_UNIVARIATE_FEATURE_PRICE_MOMENTUM_ZIP`, `STATS_UNIVARIATE_IC_SANDBOX`, `SUPPLY_OUTLOOK`, `VW_INSTITUTIONAL_MARKETS`, `VW_INSTITUTIONAL_MARKETS_V2`, `VW_INSTITUTIONAL_ZIPS_V2`, `VW_OWNERSHIP_SEGMENTATION_CBSA`, `VW_TOP_INSTITUTIONAL_ZIPS`, `ZONDA_STG_DEEDS_NORMALIZED_V`, `ZONDA_UNIT_MIX_MONTHLY_V`, `ZONDA_UNIT_MIX_STATE_MOM_YOY_V`, `ZONDA_UNIT_MIX_STATE_SHARE_V`, `ZONDA_UNIT_MIX_ZIP_MOM_YOY_V`, `ZONDA_UNIT_MIX_ZIP_SHARE_V`, `_MIGRATION_LOG_EXPERIMENTS`.

## 4) Legacy Redfin `TRANSFORM_PROD.CLEANED` (`enabled=false` in pretium-ai-dbt)

Objects **exist** in Snowflake: `CLEANED_REDFIN_ZIPCODE` (VIEW), `CLEANED_REDFIN_CBSA` (VIEW), `CLEANED_REDFIN_ZIPCODE_METRICS` (BASE TABLE).

**Inbound ACCOUNT_USAGE dependencies (must resolve before DROP):**

| Referenced (SANDBOX/CLEANED) | Referencing object |
|-----------------------------|----------------------|
| `CLEANED_REDFIN_CBSA` | `TRANSFORM_PROD.FACT.FACT_REDFIN_CBSA` |
| `CLEANED_REDFIN_ZIPCODE` | `TRANSFORM_PROD.CLEANED.REDFIN_ZIP_METRICS`, `TRANSFORM_PROD.FACT.FACT_REDFIN_ZIPCODE` |
| `CLEANED_REDFIN_ZIPCODE_METRICS` | `TRANSFORM_PROD.FACT.FACT_HOUSING_METRICS_ZIP` |

**Conclusion:** Not merge-safe to `DROP` cleaned legacy until stub facts/views are retargeted to `cleaned_redfin_market_tracker_*` (or semantic `TRANSFORM.DEV` equivalents) and consumers are cut over.

## 5) Other `enabled=false` targets — physical presence

| Intended object | `INFORMATION_SCHEMA` result |
|----------------|----------------------------|
| `TRANSFORM_PROD.FACT.FACT_HOUSEHOLD_INCOME_ACS_LEGACY` | **Not found** (only `FACT_HOUSEHOLD_INCOME_ACS`, `FACT_HOUSEHOLD_INCOME_ACS_ZIP_FROM_BG` exist in `FACT`). |
| `ANALYTICS_PROD.MODELS.V_ECONOMIC_PROJECTIONS_ZIP` / `..._CBSA` | **Not found** in `ANALYTICS_PROD.MODELS`. |
| `EDW_PROD.MART.MART_RENT_SIGNALS_CBSA` | **Not found** in `EDW_PROD.MART` (dbt placeholder; `enabled=false`). |
| `EDW_PROD.ADHOC.ADHOC_PLACEHOLDER` | **Not found** in `EDW_PROD.ADHOC`. |

## 6) `ACCESS_HISTORY` — FQN shape

`direct_objects_accessed` uses **`objectName`** like `REFERENCE.CATALOG.OWNERSHIP_TYPE` (fully qualified string). For SANDBOX probes use `ILIKE 'ANALYTICS_PROD.SANDBOX.<TABLE>'` (not split `objectDatabase` / `objectSchema` keys).

**Note:** `ILIKE 'ANALYTICS_PROD.SANDBOX.%'` also matches **dynamic / versioned** sandbox objects (e.g. `ANALYTICS_PROD.SANDBOX."versioned_WORKSPACE_analytics_sandbox_…"`) — treat counts as **workspace activity**, not only dbt-deployed models.

Spot checks (14d, `COUNT(DISTINCT query_id)` with tight FQN filters): several SANDBOX tables show **low single-digit** read volume; **`_MIGRATION_LOG_EXPERIMENTS`** had **1** distinct `query_id` in a manual probe. Use the script’s **`ACCESS_SANDBOX_SAMPLE`** query for the current top-N list.
