# Baseline inventory — `RAW` + `TRANSFORM` (correct migration base)

**Owner:** Alex  
**Reads:** pretium-ai-dbt rules (`.cursorrules`, `.cursor/rules/transform-vendor-source-priority.mdc`, `dbt/models/sources.yml` header), `DEPRECATION_MIGRATION_COMPLIANCE.md` (Alex five-target contract).  
**Snowflake:** Account snapshot via `SNOWFLAKE.ACCOUNT_USAGE` + `TRANSFORM.INFORMATION_SCHEMA` (role: pretium profile). **ACCOUNT_USAGE lags** ~hours; re-run before cutover.

---

## 1. Rules — which physical base to read **first**

| Priority | Database.schema | Use when |
|----------|-----------------|----------|
| **1** | **`TRANSFORM.<VENDOR>`** | Vendor-native landings the platform already materialized. **Vet** `SHOW TABLES IN SCHEMA` before adding a duplicate source (`.cursor/rules/transform-vendor-source-priority.mdc`). |
| **2** | **`TRANSFORM.DEV`** | Alex-typed **`FACT_*`**, **`CONCEPT_*`**, vendor **`REF_*`**. Per compliance doc: **`RAW_*` must not live here long-term** — migrate landings to **`SOURCE_PROD.[VENDOR].RAW_*`**. |
| **3** | **`SOURCE_PROD.<vendor>`** | Canonical when not (yet) in **`TRANSFORM.<vendor>`**, or DE-maintained historical / full-fidelity tables (e.g. `SOURCE_PROD.ZILLOW` `RAW_*` + manifests). |
| **4** | **`RAW.<vendor>`** | **Legacy** raw mirror (small footprint in this account). dbt today declares **`markerr_raw` → `RAW.MARKERR`** only. Prefer **`TRANSFORM.MARKERR`** or **`SOURCE_PROD.MARKERR`** for new work; retire **`RAW`** reads after parity. |
| **5** | Datashares / other DBs | Only when data is contractually not in `TRANSFORM` (see `sources.yml`). |

**Semantic-layer contract (Alex):** new **`RAW_*`** tables land only in **`SOURCE_PROD.[VENDOR]`**; **`TRANSFORM.DEV`** holds prefixed **`FACT_*` / `CONCEPT_*` / `REF_*`** only.

---

## 2. `TRANSFORM` database — vendor schemas (Jon / platform landings)

Non-`DEV` schemas (excluding `INFORMATION_SCHEMA`, `CORRIDOR`, `ROLLUPS`, `FACTS` per prior inventory): **~95 base tables/views** across vendors below (live `INFORMATION_SCHEMA` list, 2026-04-19).

| Schema | Approx. tables | Role |
|--------|------------------|------|
| `TRANSFORM.APARTMENTIQ` | 7 | Vendor |
| `TRANSFORM.BLS` | 3 | Vendor |
| `TRANSFORM.BPS` | 1 | Vendor |
| `TRANSFORM.CENSUS` | 1 | Vendor / ACS |
| `TRANSFORM.CHERRE` | 14 | Vendor |
| `TRANSFORM.COSTAR` | 1 | Vendor |
| `TRANSFORM.FIRST_STREET` | 4 | Vendor |
| `TRANSFORM.LODES` | 2 | Vendor |
| `TRANSFORM.MARKERR` | 8 | Vendor |
| `TRANSFORM.OVERTURE` | 1 | Vendor |
| `TRANSFORM.RCA` | 22 | Vendor (MSCI / deal universe) |
| `TRANSFORM.REDFIN` | 7 | Vendor (latest tracker views) |
| `TRANSFORM.REGRID` | 1 | Vendor |
| `TRANSFORM.STANFORD` | 1 | Vendor |
| `TRANSFORM.YARDI` | 15 | Vendor |
| `TRANSFORM.YARDI_MATRIX` | 3 | Vendor |
| `TRANSFORM.ZONDA` | 3 | Vendor |
| `TRANSFORM.CORRIDOR` | 4 | Internal / corridor |
| `TRANSFORM.ROLLUPS` | 2 | Internal |
| `TRANSFORM.DEV` | 153 | **Alex** — see §3 |

**Migration implication:** **`FACT_*`** models in the new repo should **`source()` these schemas** when the grain is vendor-native; only add **`SOURCE_PROD`** landings where **`TRANSFORM.<vendor>`** does not yet hold the table (or for **`RAW_*`** contract rows).

**ApartmentIQ / Yardi Matrix:** Before expanding migration scope for those vendors, complete **`MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`** (object inventory, column and metric catalog, smoke gates) and task IDs **`T-VENDOR-APARTMENTIQ-READY`** / **`T-VENDOR-YARDI-MATRIX-READY`** in `MIGRATION_TASKS.md`.

**CoStar:** **`TRANSFORM.COSTAR`** (e.g. **`SCENARIOS`**), **`SOURCE_PROD.COSTAR`** (scenarios metrics + parquet export + metric catalog), and **`RAW.COSTAR`** may all appear in lineage — complete **`MIGRATION_TASKS_COSTAR.md`** and **`T-VENDOR-COSTAR-READY`** before treating CoStar-backed **`FACT_*`** as migration-complete.

**Yardi operational (`TRANSFORM.YARDI`):** **`_BH`** and **`_PROGRESS`** parallel tables (property, unit, tenant, unit status, transaction ledger, etc.) — complete **`MIGRATION_TASKS_YARDI_BH_PROGRESS.md`** and **`T-VENDOR-YARDI-READY`** before treating Yardi PMS-backed **`FACT_*`** as migration-complete. **`TRANSFORM.YARDI_MATRIX`** remains a **separate** vendor surface (`MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`).

**First Street + RCA:** **`TRANSFORM.FIRST_STREET`** (historic + climate) and **`TRANSFORM.RCA`** (MSCI consumer pass-throughs) — complete **`MIGRATION_TASKS_FIRST_STREET_RCA.md`** and **`T-VENDOR-FIRST-STREET-READY`** / **`T-VENDOR-RCA-READY`** before treating those **`FACT_*`** paths as migration-complete.

**Redfin + Stanford:** **`TRANSFORM.REDFIN`** (interim latest views; pair **`RAW.REDFIN`**) vs **`SOURCE_PROD.REDFIN`** for full history; **`SOURCE_PROD.STANFORD`** VARIANT parquet vs thin **`TRANSFORM.STANFORD`** vs **`TRANSFORM.DEV`** `FACT_STANFORD_*` — complete **`MIGRATION_TASKS_STANFORD_REDFIN.md`** and **`T-VENDOR-REDFIN-READY`** / **`T-VENDOR-STANFORD-READY`** before treating Redfin- or SEDA-backed **`FACT_*`** as migration-complete.

**Oxford (`SOURCE_ENTITY.PRETIUM`):** **`TRANSFORM.DEV.REF_OXFORD_METRO_CBSA`**, **`FACT_OXFORD_AMREG_QUARTERLY`**, **`FACT_OXFORD_WDMARCO_QUARTERLY`** — complete **`MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md`** and task IDs **`T-DEV-REF-OXFORD-METRO-CBSA`**, **`T-DEV-FACT-OXFORD-AMREG-QUARTERLY`**, **`T-DEV-FACT-OXFORD-WDMARCO-QUARTERLY`** (pretium-ai-dbt profile + CTAS script today; dbt models to follow).

**BPS / Census ACS5 / BLS LAUS / LODES (Jon `TRANSFORM` silver):** **`TRANSFORM.BPS.PERMITS_COUNTY`**, **`TRANSFORM.CENSUS.ACS5`**, **`TRANSFORM.BLS.LAUS_CBSA`**, **`TRANSFORM.BLS.LAUS_COUNTY`**, **`TRANSFORM.LODES.OD_BG`** — complete **`MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`** and **`T-TRANSFORM-BPS-PERMITS-COUNTY-READY`** through **`T-TRANSFORM-LODES-OD-BG-READY`** before treating government-stats-backed facts as migration-complete.

**Corridor Ward pipeline:** **`REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL`** (spine; verify Python loader FQN), **`REFERENCE.GEOGRAPHY`** bridges / blockgroups, **`TRANSFORM.LODES.OD_H3_R8`**, Cherre assessor + Overture POI + LODES employment-center chain + **`TRANSFORM.DEV`** Ward input facts — complete **`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md`** and **`T-CORRIDOR-*`** tasks (cross-links **T-TRANSFORM-CENSUS-ACS5-READY**, **T-TRANSFORM-LODES-OD-BG-READY**, **T-VENDOR-STANFORD-READY**, **T-VENDOR-RCA-READY**).

---

## 3. `TRANSFORM.DEV` — Alex dev (prefix sanity)

| Prefix bucket | Count (2026-04-19) | Expected |
|-----------------|-------------------|----------|
| `FACT_*` | 108 | Yes |
| `REF_*` | 4 | Yes (vendor xwalks / seeds materialized) |
| `RAW_*` | **11** | **Misplaced** vs Alex contract — should live **`SOURCE_PROD.[VENDOR].RAW_*`** |
| Other | 42 | Review (ints, bridges, nonstandard names) |

### `RAW_*` currently in `TRANSFORM.DEV` (move-first list)

These are the **first** objects to reconcile so new work reads from **`SOURCE_PROD`** for landings:

| Table | Target home |
|-------|----------------|
| `RAW_CPS_BASIC3_LOADED` | `SOURCE_PROD.NBER` or agreed CPS vendor schema + `RAW_*` name |
| `RAW_ZILLOW_AFFORDABILITY` | `SOURCE_PROD.ZILLOW.RAW_AFFORDABILITY` (align with existing Zillow RAW bundle) |
| `RAW_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS` | `SOURCE_PROD.ZILLOW.RAW_DAYS_ON_MARKET_AND_PRICE_CUTS` |
| `RAW_ZILLOW_FOR_SALE_LISTINGS` | `SOURCE_PROD.ZILLOW.RAW_FOR_SALE_LISTINGS` |
| `RAW_ZILLOW_HOME_VALUES` | `SOURCE_PROD.ZILLOW.RAW_HOME_VALUES` |
| `RAW_ZILLOW_HOME_VALUES_FORECASTS` | `SOURCE_PROD.ZILLOW.RAW_HOME_VALUES_FORECASTS` |
| `RAW_ZILLOW_MARKET_HEAT_INDEX` | `SOURCE_PROD.ZILLOW.RAW_MARKET_HEAT_INDEX` |
| `RAW_ZILLOW_NEW_CONSTRUCTION` | `SOURCE_PROD.ZILLOW.RAW_NEW_CONSTRUCTION` |
| `RAW_ZILLOW_RENTALS` | `SOURCE_PROD.ZILLOW.RAW_RENTALS` |
| `RAW_ZILLOW_RENTAL_FORECASTS` | `SOURCE_PROD.ZILLOW.RAW_RENTAL_FORECASTS` |
| `RAW_ZILLOW_SALES` | `SOURCE_PROD.ZILLOW.RAW_SALES` |

**Note:** `SOURCE_PROD.ZILLOW` already has **66** tables in account usage — many may duplicate these landings under the same identifiers; migration = **cut dbt `source()` from `TRANSFORM.DEV` → `SOURCE_PROD.ZILLOW`**, then **drop or archive** dev copies once parity verified.

---

## 4. `RAW` database — legacy raw mirrors (account usage)

| Schema | Base + external tables | Vendors (high level) |
|--------|------------------------|----------------------|
| `RAW.CENSUS` | 4 | Census |
| `RAW.CHERRE` | 2 | Cherre |
| `RAW.COSTAR` | 2 | Costar |
| `RAW.FIRST_STREET` | 1 | First Street |
| `RAW.MARKERR` | 5 | Markerr |
| `RAW.NCES` | 2 | Education |
| `RAW.PRETIUM_BTR` | 3 | Internal |
| `RAW.REDFIN` | 7 | Redfin |
| `RAW.REGRID` | 1 | Regrid |
| `RAW.STANFORD` | 2 | Stanford |
| `RAW.ZONDA` | 3 | Zonda |

**Pairing with `TRANSFORM`:** vendors with **both** `RAW.<v>` and `TRANSFORM.<v>` today include **Redfin (7+7)**, **Zonda (3+3)**, **Cherre**, **Costar**, **First Street**, **Markerr**, **Regrid**, **Stanford**. Prefer **`TRANSFORM.<vendor>`** for dbt **`source()`** per repo rules; use **`RAW`** only if **`TRANSFORM`** row is missing or stale.

---

## 5. `SOURCE_PROD` — canonical landings (contrast, not duplicate work)

`SOURCE_PROD` holds **many** vendor schemas (ACS, Zillow 66 tables, Markerr 14, HUD, BKFS, …). **Do not re-load** what already exists there unless the contract is wrong.

**Heuristic:** For each vendor batch, **`DESCRIBE` / row-hash** `SOURCE_PROD.<v>.<table>` vs `TRANSFORM.DEV` / `RAW.<v>` / `TRANSFORM.<v>` and migrate **from the richest correct base** (usually **`TRANSFORM.<vendor>`** → **`FACT_*`**, or **`SOURCE_PROD`** for **`RAW_*`**).

---

## 6. dbt `sources.yml` alignment (pretium-ai-dbt)

Declared **`database: transform`** vendor sources include at least: **Redfin**, **First Street** (historic events), **Yardi**, **ApartmentIQ**, **BPS**, **Markerr**, **Cherre**, **Dev** (`transform.dev`), **BLS** (later in file), etc.  
Declared **`database: raw`**: **`markerr_raw` → `RAW.MARKERR`**.  
Declared **`database: source_prod`**: broad catalog (Zillow `RAW_*`, Markerr, Cherre, …).

**Action:** When porting to **pretiumdata-dbt-semantic-layer**, register **one physical source per table** following §1 priority; document interim vs canonical in `sources_transform.yml` comments.

---

## 7. Regeneration queries (Snowflake worksheet)

```sql
-- TRANSFORM: tables per vendor schema
SELECT LOWER(table_schema) AS sc, COUNT(*) AS n
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE table_type IN ('BASE TABLE','VIEW','EXTERNAL TABLE')
  AND table_schema NOT IN ('INFORMATION_SCHEMA')
GROUP BY 1 ORDER BY 1;

-- TRANSFORM.DEV: prefix buckets
SELECT CASE
         WHEN STARTSWITH(UPPER(table_name),'RAW_') THEN 'RAW_'
         WHEN STARTSWITH(UPPER(table_name),'FACT_') THEN 'FACT_'
         WHEN STARTSWITH(UPPER(table_name),'REF_') THEN 'REF_'
         ELSE 'OTHER' END AS bucket, COUNT(*)
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'DEV'
GROUP BY 1 ORDER BY 1;

-- RAW + SOURCE_PROD + TRANSFORM counts (ACCOUNT_USAGE; lag)
SELECT LOWER(table_catalog) AS db, LOWER(table_schema) AS sc, COUNT(*) AS n
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
WHERE LOWER(table_catalog) IN ('raw','source_prod','transform')
  AND table_type IN ('BASE TABLE','EXTERNAL TABLE')
  AND deleted IS NULL
GROUP BY 1,2 ORDER BY 1,2;
```

---

*Maintainer: bump the snapshot date when inventories are refreshed. Cross-link: `MIGRATION_TASKS.md`.*
