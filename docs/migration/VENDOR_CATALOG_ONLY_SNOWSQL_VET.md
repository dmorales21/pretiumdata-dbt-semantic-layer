# Catalog-only vendors — SnowSQL vet (`snowsql -c pretium`)

**Owner:** Alex  
**Scope:** The eight **`vendor.csv`** rows with **no** matching **`dataset.csv`** rows: **`bea`**, **`cfpb`**, **`cybersyn`**, **`fbi`**, **`fdic`**, **`nws`**, **`salesforce`**, **`usps`**.  
**Re-run:** `scripts/sql/migration/vet_catalog_only_vendors_pretium.sql`  
**Session:** pretium dev account, **`snowsql -c pretium`**, 2026-04-19.

---

## 1. Executive summary

| Theme | Finding |
|-------|---------|
| **RAW vs catalog** | **`RAW`** exposes **13** non-system schemas (CENSUS, CHERRE, …) — **no** `BEA`, `CFPB`, `FBI`, `USPS`, or `NOAA` schema. Catalog **`vendor.source_schema`** values like **`RAW.BEA`** are **forward-looking** or **wrong for this account** until landings exist or are re-pointed to **`SOURCE_PROD`**. |
| **Cybersyn** | **`GLOBAL_GOVERNMENT.CYBERSYN`**: **106** tables/views in **`INFORMATION_SCHEMA`**. **`CYBERSYN_DATA_CATALOG`** lists **NOAA** (10 `noaa_*` rows in a filtered pull), **CFPB** (`financial_cfpb_complaint*`), and **FBI/FDIC/USPS** table names. **SELECT** privileges are **partial**: **`FBI_CRIME_TIMESERIES`** / **`FBI_CRIME_ATTRIBUTES`** queried successfully; **`FDIC_*`**, **`USPS_*`**, **`NOAA_*`**, **`FINANCIAL_CFPB_COMPLAINT`** returned **“does not exist or not authorized”** for this connection (metadata visible, data not). |
| **SOURCE_PROD.FDIC** | Schema exists; **`CONSTRUCTION_LOANS_RAW`** = **0** rows, **VARIANT** payload — not yet a typed **`FACT_*`**. |
| **SOURCE_ENTITY (Salesforce)** | **`SOURCE_ENTITY.PROGRESS`** exists; **`SHOW TABLES`** returned **0** visible tables for **`salesforce`** / CRM vetting — treat as **no physical surface** or **no grant** to migration role. |
| **BEA / HMDA in Cybersyn catalog** | Filter **`CYBERSYN_DATA_CATALOG`** for **`%BEA%` / `%GDP%` / `%RPP%` / `%HMDA%`** returned **no** rows in this share slice (BEA/HMDA may be absent or named differently). |
| **Product type** | **`bridge_product_type_metric.csv`** has a **minimal** row set (each `product_type_code` → **`cybersyn_fhfa_house_price_timeseries_value`** / MET_013). **WL_020** is **`in_progress`** until rent/CBSA metrics are added; catalog-only vendor rows still lack product×metric coverage beyond this HPI anchor. |

---

## 2. Per-vendor vet

### `bea`

| Check | Result |
|-------|--------|
| **Schema** | No **`RAW.BEA`** / **`SOURCE_PROD.BEA`** in schema lists used. |
| **Cybersyn catalog** | No BEA/GDP/RPP table hit in filtered **`CYBERSYN_DATA_CATALOG`** query. |
| **Uniques / nulls / geo / frequency** | N/A until a physical table is identified. |
| **Product type** | No `dataset` row → no **`product_type_codes`**. |

**Migration need:** Add **`dataset`** stub + Snowflake landing discovery (BEA may enter via non-Cybersyn path); align **`vendor.source_schema`**.

---

### `cfpb` (HMDA family)

| Check | Result |
|-------|--------|
| **Cybersyn catalog** | **`financial_cfpb_complaint`**, **`financial_cfpb_complaint_pit`** present. |
| **SELECT** | **Not authorized** on `FINANCIAL_CFPB_COMPLAINT` with **`pretium`** connection used for vet. |
| **HMDA-specific** | No **`%HMDA%`** table name in catalog filter — may be complaints-only in this slice. |

**Migration need:** Grant policy + **`source()`** registration; add **`concept`** (e.g. mortgage_market_regulatory); **`dataset`** rows per table; separate **complaints** vs **HMDA** if both exist elsewhere.

---

### `cybersyn` (umbrella vendor)

| Check | Result |
|-------|--------|
| **Registry** | **`vendor.source_schema`** = `SOURCE_SNOW.GLOBAL_GOVERNMENT` — actual objects vetted here are **`GLOBAL_GOVERNMENT.CYBERSYN`**. |
| **Object inventory** | **106** Cybersyn relations in **`INFORMATION_SCHEMA`**. |

**Migration need:** Keep **`cybersyn`** as **registry** vendor; continue registering **agency** `vendor_code` on **`dataset`** rows; document share grant matrix.

---

### `fbi`

| Check | Result |
|-------|--------|
| **Objects** | **`FBI_CRIME_TIMESERIES`** (VIEW), **`FBI_CRIME_ATTRIBUTES`** (VIEW). |
| **Rows** | Timeseries **21,232**; attributes **10**. |
| **Geo** | **52** distinct **`GEO_ID`** (Cybersyn place id — join via **`REFERENCE.GEOGRAPHY`** / **`GEOGRAPHY_INDEX`**). |
| **Frequency** | **`DATE`** from **1979-12-31** to **2023-12-31** (annual-style crime counts). |
| **Nulls** | **0** null **`VALUE`** in timeseries sample aggregate. |
| **Product type** | Crime indices are **macro / location** — map via future **`bridge_product_type_metric`** to products that consume **`crime`** (e.g. SFR/MF research), not **`ltv`**. |

**Migration need:** Add **`dataset`** + **`metric`** for **`TRANSFORM.DEV`** FBI fact if/when ported; **`metric_derived`** for any **`FEATURE_*`** crime score.

---

### `fdic`

| Check | Result |
|-------|--------|
| **SOURCE_PROD** | **`SOURCE_PROD.FDIC`** schema exists. |
| **Landing** | **`CONSTRUCTION_LOANS_RAW`**: **0** rows; columns **`ROW_NUMBER`**, **`RAW_DATA` (VARIANT)**, **`LOADED_AT`**. |
| **Cybersyn** | **`FDIC_SUMMARY_OF_DEPOSITS_*`**, **`FDIC_BRANCH_LOCATIONS_INDEX`** in catalog; **SELECT not authorized** on SOD views with vet role. |

**Migration need:** Typed **`FACT_*`** for deposits/branches; **`concept`** = financial_institution_context or similar; fix **`cap_rate`** stretch if any dataset used FDIC for non-yield semantics.

---

### `nws` (vendor) / NOAA (Cybersyn)

| Check | Result |
|-------|--------|
| **RAW.NOAA** | Not in **`RAW`** schema list (vendor lists **`RAW.NOAA`**). |
| **Cybersyn catalog** | **`noaa_*`** tables (weather metrics, NWRFC water supply, station index, `_pit` history). |
| **SELECT** | **Not authorized** on **`noaa_weather_metrics_timeseries`** in vet session. |

**Migration need:** **`dataset`** rows per NOAA table group; frequency **daily**/subdaily in attributes; geo = station / hydrologic ids — map through **`REFERENCE.GEOGRAPHY`** rules.

---

### `salesforce`

| Check | Result |
|-------|--------|
| **Catalog** | **`vendor.source_schema`** = **`SOURCE_ENTITY.PROGRESS`**. |
| **SHOW TABLES** | **`SOURCE_ENTITY.PROGRESS`**: **0** tables visible to vet role. |

**Migration need:** Confirm CRM landing schema; add **`deal_pipeline`** concept + **`dataset`** or set **`vendor.is_active=false`** until contracted.

---

### `usps`

| Check | Result |
|-------|--------|
| **Cybersyn** | **`USPS_ADDRESS_CHANGE_*`** in **`CYBERSYN_DATA_CATALOG`**. |
| **SELECT** | **Not authorized** on timeseries view in vet session. |

**Migration need:** Grants + **`dataset`** for address-change panels; geo = ZIP/state as per Cybersyn variable dictionary; link to **corridor / migration** use cases, not **`occupancy`**.

---

## 3. Relationship to **`product_type`**

- **`REFERENCE.CATALOG.product_type`** seed defines verticals (e.g. RESI, RED).  
- **`dataset.product_type_codes`** is the right column for “which products consume this vendor slice.”  
- Until **`bridge_product_type_metric`** covers rent/value/CBSA metrics (not HPI-only), treat **vendor-level product applicability** for catalog-only vendors as **documentation + `dataset.product_type_codes`** where the bridge is still thin; see **`catalog_wishlist` WL_020** + **`primary_catalog_*`** columns.

Suggested first mappings when bridge work opens:

| Vendor slice | Likely `product_type_code` notes |
|--------------|-----------------------------------|
| **FBI crime** | Research / scoring for **MF + SFR** market selection (not loan tape). |
| **FDIC deposits** | **Financial context** for market/institution screens — not core **resi** rent. |
| **USPS** | **Migration / demand** context — crosswalk to **ZIP/CBSA** for housing models. |
| **NOAA** | **Climate / operations** overlays — tie to **`first_street`** / hazard stack when concepts split. |
| **CFPB** | **Regulatory / fair lending** analytics — separate from **`occupancy`**. |

---

## 4. “Skipped” migration cluster (not a vendor)

**`T-TRANSFORM-PROD-CLEANED`** is **`skipped`** in **`MIGRATION_TASKS.md`** — Jon **`TRANSFORM.[VENDOR]`** is canonical cleanse; **do not** duplicate in Alex **`TRANSFORM.DEV`**. This is **not** the same as catalog-only vendors; no Snowflake vet required beyond consumer **`ref()`** cutover.

---

## 5. Follow-ups

1. Request **SELECT** grants on Cybersyn **FDIC / USPS / NOAA / CFPB** views for the migration role (or use elevated role in **`vet_*.sql`**).  
2. Re-run **`vet_catalog_only_vendors_pretium.sql`** after grants and attach row-count / null / distinct-geo outputs to **`docs/migration/artifacts/`**.  
3. Add **`dataset.csv`** rows + **`sources_*.yml`** for each vendor once physical path is stable.
