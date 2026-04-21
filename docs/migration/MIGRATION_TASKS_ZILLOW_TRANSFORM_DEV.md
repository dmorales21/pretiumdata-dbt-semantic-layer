# Migration — Zillow research `FACT_*` (`models/transform/dev/zillow`)

**Owner:** Alex  
**Governing:** `MIGRATION_RULES.md` §2–3, `MIGRATION_BASELINE_RAW_TRANSFORM.md` §3 (RAW in `TRANSFORM.DEV` → `SOURCE_PROD.ZILLOW`)  
**Runbooks:** `docs/runbooks/RUN_TRANSFORM_DEV_ZILLOW_RESEARCH_ALL.md`, per-dataset runbooks as needed  
**Task register:** `MIGRATION_TASKS.md` — **`T-TRANSFORM-DEV`** (Zillow slice)

## §1 Repo alignment (`MIGRATION_RULES.md` §3 checklist — Zillow)

- [x] **1–4:** `FACT_*` live in `models/transform/dev/zillow/`; reads **`source('zillow', 'raw_*')`** on **`SOURCE_PROD.ZILLOW`** (not `TRANSFORM.DEV` RAW).
- [x] **5–6:** Long output uses snake_case columns via macro; **`source()` / `ref()`** — no hardcoded `SOURCE_PROD` / `TRANSFORM` FQNs in fact SQL files.
- [x] **7–8:** `zillow_research_fact_enriched` applies ZIP/county xwalks + metro mapping; excludes city/neighborhood; normalizes metro/msa → **`cbsa`**.
- [x] **9:** Path matches §4 conventions (`zillow_research/` → `zillow/`).
- [x] **10:** `schema.yml` documents grain + key census columns; add **`not_null` / `unique`** PK tests when grain key is finalized (tracked in batch notes).
- [x] **11:** `sources_transform.yml` **`zillow`** source lists all **`raw_*`** tables used by facts.
- [ ] **12:** Consumer `ref()` updates + compat view retirement — **after** Snowflake parity and Alex sign-off.

## §1.4 `TRANSFORM.DEV` + **REFERENCE.GEOGRAPHY** prerequisites (Jon / Alex)

- [ ] **`TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA`:** Run **`docs/migration/sql/create_ref_zillow_metro_to_cbsa.sql`** in Snowflake (CTAS from Jon **`TRANSFORM.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING`** or other governed export — **not** **`TRANSFORM_PROD`**). Required before **`dbt build`** on Zillow facts (`source('transform_dev_vendor_ref','ref_zillow_metro_to_cbsa')`). If the physical table uses **`ZILLOW_REGION_ID` / `CBSA_ID`** instead of **`zillow_6_digit` / `census_5_digit`**, set dbt var **`zillow_metro_to_cbsa_xwalk_profile: alex_metro_ref`** (default in this repo) or run **`docs/migration/sql/reshape_ref_zillow_metro_to_cbsa_to_macro_columns.sql`** then use **`legacy_jon`**.
- [x] **ZIP → county:** **`REFERENCE.GEOGRAPHY.POSTAL_COUNTY_XWALK`** (HUD quarterly; macro picks latest YEAR/QUARTER per ZIP).
- [ ] **County → CBSA:** **`REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK`** for **`reference_geography_year()`** — Jon must grant read to migration role.

## §1.5 Inventory deliverable (Snowflake)

- [x] **§1.5 complete (batch 001):** `snowsql -c pretium -f scripts/sql/migration/inventory_zillow_source_prod_raw.sql` from inner project root; artifact **`docs/migration/artifacts/2026-04-19_batch001_zillow_raw_rowcounts.csv`**; linked from **`MIGRATION_LOG.md`** batch **001** notes.

**Exit (full Zillow cluster row):** `MIGRATION_TASKS.md` **`T-TRANSFORM-DEV`** remains **`pending`** until the rest of `models/transform/dev/**` clears the same checklist; Zillow slice is **gated**: inventory on file, `dbt compile --select path:models/transform/dev/zillow` OK (**2026-04-19**), **`TRANSFORM.DEV.RAW_ZILLOW_*`** retirement logged under **`MIGRATION_LOG.md` → Deprecation candidates** (Alex before `DROP`).

## §1.6 Absorption / for-sale ZIP panel (**`pretium-ai-dbt` only** today)

**Where the SQL lives:** These four **`FACT_*`** models are implemented under **pretium-ai-dbt** at **`dbt/models/transform/dev/zillow/`** — **not** under this repo’s **`models/transform/dev/zillow/`**, which today holds only the older **Zillow research** stack (**`source('zillow', 'raw_*')`** on **`SOURCE_PROD.ZILLOW`**, per §1 above).

| Model (pretium-ai-dbt filename) | Role |
|----------------------------------|------|
| **`fact_zillow_for_sale_inventory_zip_monthly`** | Typed wide ZIP × month from **`source('zillow', 'zip_monthly_for_sale')`** → **`SOURCE_PROD.ZILLOW.ZIP_MONTHLY_FOR_SALE`** (until mirrored to **TRANSFORM.ZILLOW**); gated by **`zillow_zip_inventory_available`**. Discovery: **`pretium-ai-dbt/scripts/discovery/discover_source_prod_zillow_zip_monthly_for_sale.sql`**. |
| **`fact_zillow_housing_inventory_metric_zip_monthly`** | Long **`HOUSING` / `HOU_INVENTORY`** metrics (`ZILLOW_*` **metric_id**s). |
| **`fact_zillow_absorption_parcl_compat_zip_monthly`** | Parcl-shaped columns for **`feature_absorption_source`** when **`use_zillow_absorption_instead_of_parcl`** (with inventory var). |
| **`fact_housing_inventory_zillow_governed_zip_monthly`** | Governance-shaped Zillow slice for **`model_signal_absorption_mls_enhanced`** when **`absorption_use_transform_dev_inventory`** selects dev backfill vs **`fact_housing_inventory_all_ts`**. |

**Prod union:** **`fact_housing_inventory_all_ts`** in pretium-ai-dbt does **not** union this Zillow path; it stays **parallel** on **`TRANSFORM.DEV`** until a governed promotion / union decision.  
**Governance gaps (CBSA, etc.):** pretium-ai-dbt **`docs/governance/CLEANED_FACT_GAP_ANALYSIS.md`** and **`docs/governance/MISSING_CLEANED_AND_METRICS_REGISTRY.yml`** (e.g. **`fact_zillow_inventory_cbsa`**, **`fact_zillow_dom_cbsa`**) — paths exist only in that repo.

**Vars (pretium-ai-dbt `dbt/dbt_project.yml`):** **`zillow_zip_inventory_available`**, **`use_zillow_absorption_instead_of_parcl`**, **`absorption_use_transform_dev_inventory`**.  
**Build (from pretium-ai-dbt root):** `./scripts/orchestrate_zillow_for_sale_dev_facts.sh` (stub-safe default), or **`--with-live-data`** once **`SOURCE_PROD.ZILLOW.ZIP_MONTHLY_FOR_SALE`** exists. Manual: `dbt run --select path:models/transform/dev/zillow --vars '{"zillow_zip_inventory_available": true}'` only after the table is present.

**Port note:** When this slice is recreated under **this** repo’s **`models/transform/dev/zillow/`**, replace §1.6 with the new paths and retire cross-repo wording.
