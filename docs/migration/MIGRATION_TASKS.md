# Migration tasks — pretium-ai-dbt → pretiumdata-dbt-semantic-layer

**Owner:** Alex  
**Purpose:** Single register of **what must migrate**, target Snowflake homes, and disposition—**not** procedure (see `MIGRATION_RULES.md`) and **not** batch audit (see `MIGRATION_LOG.md`).  
**Governing contract:** pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md` (five-target + `REFERENCE.*`).

**Systematize market data as `FACT_*` (waves, checklists, scope):** `MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md` — how to bring relevant vendor / Cybersyn / government data into **`TRANSFORM.DEV`** with **`REFERENCE.CATALOG`** registration.

**Non-duplicative gap queue (fact -> metric -> concept):** `MIGRATION_FACT_GAP_WAVE_QUEUE.md` — Wave 1/2/3 execution order for true gap-fill facts only.

**Rollup index (all vendors / datasets / metrics to move):** `MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md` — links **`T-*`** clusters, **`dim_dataset_config.csv`** (147 datasets / 63 vendors), and metric catalog sources.

**Snowflake baseline (read order + what already exists in `RAW` / `TRANSFORM`):** `MIGRATION_BASELINE_RAW_TRANSFORM.md` — use this **before** picking a migration source so batches start from the **correct physical base**.

**Strata backend (`strata_backend` SQL) — full lineage + Snowflake↔dbt map:** `MIGRATION_TASKS_STRATA_BACKEND_LINEAGE.md` — every listed consumer object is tied to a **`T-STRATA-*`** task below.

**Tearsheet service (`tearsheet.service.ts`) — 38 objects, lineage + `T-TEARSHEET-*` tasks:** `MIGRATION_TASKS_TEARSHEET_SERVICE.md` (subset of EDW/ADMIN/Jon stack; ordered migration path inside that file).

**ApartmentIQ + Yardi Matrix (`TRANSFORM.APARTMENTIQ`, `TRANSFORM.YARDI_MATRIX`) — object + metric readiness:** `MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md` — inventory, column grain, DATATYPE catalog, source registration, smoke gates before full migration.

**CoStar (`TRANSFORM.COSTAR`, `SOURCE_PROD.COSTAR`, `RAW.COSTAR`, typed `FACT_*`) — object + metric readiness:** `MIGRATION_TASKS_COSTAR.md` — multi-home inventory, SCENARIOS grain/uniques, VARIANT export keys, scenario feed parity, smoke gates before full migration.

**Cherre (`TRANSFORM.CHERRE`, `RAW.CHERRE`, share `source('cherre', …)`, analytics `FACT_CHERRE_*`) — migration prep + product hope-list (market vs deal):** `MIGRATION_TASKS_CHERRE.md` — prep gates, **`REFERENCE.CATALOG` DS_025–DS_030**, corridor stock, concept-method P3–P5, Strata/tearsheet; smoke SQL `scripts/sql/migration/inventory_cherre_transform_smoke.sql`.

**Yardi operational (`TRANSFORM.YARDI` — `*_BH` + `*_PROGRESS`) — object + metric readiness:** `MIGRATION_TASKS_YARDI_BH_PROGRESS.md` — parallel OpCo tables, keys, `SSTATUS` / ledger uniques, smoke gates before full migration (**not** `YARDI_MATRIX`; that stays under ApartmentIQ/Matrix doc).

**First Street + RCA / MSCI (`TRANSFORM.FIRST_STREET`, `TRANSFORM.RCA`, shares):** `MIGRATION_TASKS_FIRST_STREET_RCA.md` — historic vs YAML column gaps, `CLIMATE_RISK` grain, RCA plan §5 keys vs physical `"TRANSACTION"`, seed vs column anti-join (see inventory SQL).

**Stanford SEDA + Redfin (`SOURCE_PROD.STANFORD` VARIANT, `TRANSFORM.STANFORD` / `TRANSFORM.DEV`, `TRANSFORM.REDFIN` + `SOURCE_PROD.REDFIN`):** `MIGRATION_TASKS_STANFORD_REDFIN.md` — Redfin interim latest vs canonical history; Stanford `OBJECT_KEYS` vs YAML + `stanford_seda_field_dictionary` seed; inventory SQL RF-* / ST-*.

**Oxford Economics (`SOURCE_ENTITY.PRETIUM.AMREG` / `WDMARCO`) → `TRANSFORM.DEV` ref + quarterly facts:** `MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md` — `REF_OXFORD_METRO_CBSA`, `FACT_OXFORD_AMREG_QUARTERLY`, `FACT_OXFORD_WDMARCO_QUARTERLY`; join contract and `metric_id` / `date_reference` locks in pretium-ai-dbt `docs/vendors/amreg/OXFORD_SOURCE_ENTITY_PROFILE_AND_CROSSWALK_JOIN.md`.

**Zillow research `FACT_*` (`models/transform/dev/zillow`) — `SOURCE_PROD.ZILLOW` reads, `TRANSFORM.DEV` facts:** `MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md` — inventory `inventory_zillow_source_prod_raw.sql`; baseline `TRANSFORM.DEV.RAW_ZILLOW_*` → `SOURCE_PROD.ZILLOW.RAW_*` in `MIGRATION_BASELINE_RAW_TRANSFORM.md` §3.

**Government / Census silver (`TRANSFORM.BPS`, `TRANSFORM.CENSUS`, `TRANSFORM.BLS`, `TRANSFORM.LODES`):** `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md` — permits CBSA grain, ACS5 EAV scale, LAUS county vs CBSA `AREA_CODE` caveat, LODES OD_BG vs `SOURCE_PROD.LEHD`; inventory `inventory_transform_bps_census_bls_lodes.sql`.

**Cybersyn `SOURCE_SNOW.GLOBAL_GOVERNMENT` (catalog matrix + geography/housing semantic spine):** `MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md` — distinct `CYBERSYN_DATA_CATALOG.table_name` bring-in matrix, **REFERENCE.GEOGRAPHY** targets, **latest** / `_pit` naming rules, tier **1–6** + de-prioritized domains, MVP shortlist; matrix: `docs/reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`.

**Concept methods — `FACT_*` only (prioritized backlog from `registry/concept_methods/*.yml`):** `MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md` — P0 government spine → P8 affordability; **Alex runs `dbt` in pretium-ai-dbt** after each batch (see `MIGRATION_LOG.md` batch **006** + field guide row **Alex handoff**).

**Corridor Ward pipeline (`corridor_pipeline.py`):** `MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md` — **`REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL`** (verify vs Python FQN), BG/zip/place bridges, **`TRANSFORM.LODES.OD_H3_R8`**, Cherre assessor stock, Overture Places, LODES employment-center dbt chain, `TRANSFORM.DEV` fact smokes; `inventory_corridor_pipeline_critical.sql`.

**Effective rent + pre-baked metrics (Snowflake-only `FEATURE_*` / `MODEL_*` / `ESTIMATE_*`):** `MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md` — layer taxonomy, SQL stages (FACT → CONCEPT → FEATURE z-scores → MODEL sort/score → ESTIMATE forecast), **`REFERENCE.CATALOG`** `metric` / `bridge_product_type_metric`, task **T-ANALYTICS-FEATURE-EFFECTIVE-RENT-STACK**.

**Model stack consolidation (features, estimation contract, data prep, corridor + ML notes, labor risk):** `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md` — index + **§4 estimation goals**; pairs **Wave G** in `MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md`; task **T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK**.

**Vendor × concept × dataset backlog + `dataset.source_schema` vs dbt `sources` vet:** `VENDOR_CONCEPT_COVERAGE_MATRIX.md` — eight vendors without `dataset` rows; stretch `concept_code` fixes; **`SOURCE_PROD.*` / `SOURCE_ENTITY.*`** source declaration gaps in this repo.

**Sources YAML — compile closure vs forward parity (`models/sources/`):** `MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md` — includes **`sources_redfin.yml`**, **`sources_cherre_share.yml`**, LODES **`od_h3_r8`** + **`fact_lodes_od_h3_r8_annual`**; wishlist **`WL_047`–`WL_048`** (`in_progress` until RF-A / corridor smokes close).

**Polaris / Iceberg population order (datasets + marts + wishlist hygiene):** `MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md` — P0–P8 migration stack, how rows enter **`catalog_wishlist.csv`**, new **`WL_041`–`WL_046`** (see seed), and **`WL_020`** reconciliation when **`bridge_product_type_metric`** changes.

**`REFERENCE.CATALOG.metric` — canonical seed, column contract, vendor-by-vendor intake:** `MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md` — **pretiumdata-dbt-semantic-layer** `seeds/reference/catalog/metric.csv` is the only long-term authority; pretium-ai-dbt copies are downstream mirrors only; task **`T-CATALOG-METRIC-VENDOR-ROLLOUT`**.

---

## Full object inventories (pretium-ai-dbt)

Regenerate after large pulls on the old repo (paths relative to **pretium-ai-dbt** repo root):

| File | Contents | Count (2026-04-19 snapshot) |
|------|----------|-----------------------------|
| `MIGRATION_TASKS_INVENTORY_models.txt` | One path per line: `dbt/models/**/*.sql` | 2,129 |
| `MIGRATION_TASKS_INVENTORY_seeds.txt` | One path per line: `dbt/seeds/**/*.csv` | 253 |
| `MIGRATION_TASKS_INVENTORY_macros.txt` | One path per line: `dbt/macros/**/*.sql` | 141 |

**Sources (YAML):** `dbt/models/sources.yml`, `dbt/models/sources_hud_jbrec.yml`, `dbt/models/transform_prod/cleaned/sources.yml` — migrate or re-register in **`models/sources/sources_transform.yml`** (and siblings) per vendor batch; no separate line list here.

---

## Target map (Alex five + reference)

| Alex target | Allowed prefixes / objects |
|-------------|----------------------------|
| `SOURCE_PROD.[VENDOR]` | `RAW_*` landings only |
| `TRANSFORM.DEV` | `FACT_*`, `CONCEPT_*`; vendor `REF_*` (seeds/tables) |
| `ANALYTICS.DBT_DEV` | **`FEATURE_*`**, **`MODEL_*`**, **`ESTIMATE_*`** only — **no** `FACT_*` / `CONCEPT_*` (those are **`TRANSFORM.DEV`** only) |
| `ANALYTICS.DBT_STAGE` | `QA_*`, stage gates |
| `SERVING.DEMO` | Dev delivery views only |
| `REFERENCE.GEOGRAPHY` / `REFERENCE.CATALOG` / `REFERENCE.DRAFT` | Census spine, registry, drafts (no vendor xwalks in GEOGRAPHY) |

---

## Task register by cluster (every model path lives in inventory file)

**Status legend:** `pending` | `in_progress` | `migrated` | `skipped` | `blocked`  
**Skip (Jon PROD):** `transform_prod/cleaned/**` — Jon’s **PROD** cleanse surface; do not duplicate in Alex migration; re-point reads to **`TRANSFORM.[VENDOR]`** when live.

| Task ID | Old repo cluster (path prefix) | Model count | Primary post-migration target | Status | Notes |
|---------|--------------------------------|-------------|--------------------------------|--------|-------|
| T-CATALOG-METRIC-VENDOR-ROLLOUT | **`REFERENCE.CATALOG`** `metric` + `bridge_product_type_metric` (all vendors touching **`TRANSFORM.DEV` `FACT_*`**) | n/a | Curated **`seeds/reference/catalog/metric.csv`** in **pretiumdata-dbt-semantic-layer** (SoT); optional mirror sync to pretium-ai-dbt | in_progress | **Playbook:** `MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md` — column contract, registration gates, per-vendor steps **V0–V6**; validation `scripts/sql/validation/catalog_metric_registration_coverage.sql`. **Scaffolding:** `scripts/_gen_metric_csv.py` is not the semantic source of record. |
| T-VENDOR-APARTMENTIQ-READY | **Snowflake** `TRANSFORM.APARTMENTIQ` + pretium-ai-dbt ApartmentIQ models (see doc) | n/a | `source()` parity → `FACT_*` / consumers per baseline | pending | **Checklist:** `MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md` §1–4, **§1.5** (run `inventory_apartmentiq_yardi_matrix_for_dev_facts.sql` A–H; artifacts on file), §6–7. **Semantic-layer `source()`:** `models/sources/sources_apartmentiq_yardi_matrix.yml` (**batch 009** — compile parity only). |
| T-VENDOR-YARDI-MATRIX-READY | **Snowflake** `TRANSFORM.YARDI_MATRIX` + Matrix DATATYPE / geo bridge | n/a | Same | pending | **Checklist:** same doc **§1.5 §G–H**; `export_yardi_matrix_datatype_catalog.sql` **diff** vs §G; validate `SUBMARKETMATCHZIPZCTA_BH`. **Semantic-layer `source()`:** same YAML (**batch 009**). |
| T-VENDOR-YARDI-READY | **Snowflake** `TRANSFORM.YARDI` — **`_BH`** + **`_PROGRESS`** operational silver + pretium-ai-dbt `fact_bh_*` / `fact_progress_*` / housing Yardi facts | n/a | `source('transform_yardi', …)` parity → **`TRANSFORM.DEV` `FACT_*`** | pending | **Checklist:** `MIGRATION_TASKS_YARDI_BH_PROGRESS.md` §1–2, **§1.5** (`inventory_yardi_bh_progress_for_dev_facts.sql` A–J; artifacts on file), §6–7. **Semantic-layer (batch 012):** `models/transform/dev/fund_opco/` **`FACT_*`** + YAML sources. **Batch 012b:** runbook + §A–B split SQL + source reconciliation doc under **`docs/migration/artifacts/batch012_yardi/`**; **TRANS_BH** / **UNITTYPE_BH** on `transform_yardi`; **DS_063**/**064** → **`transform_dev`**. **Still pending** until §A–J CSVs archived and §3 catalog row-count refresh from Snowflake. **Batch 024:** **`SOURCE_ENTITY.PROGRESS`** fund-modeling read-throughs — `sources_source_entity_progress.yml`, **`fact_sfdc_*`**, purpose-named **`fact_se_yardi_*`** (views; gated **`transform_dev_enable_source_entity_progress_facts`**). |
| T-VENDOR-FIRST-STREET-READY | **`TRANSFORM.FIRST_STREET`** + **`SOURCE_PROD.FIRST_STREET`** + historic / climate consumers | n/a | `source()` parity → **`TRANSFORM.DEV` `FACT_*`** | pending | **Checklist:** `MIGRATION_TASKS_FIRST_STREET_RCA.md` Part A; `inventory_first_street_rca_for_dev_facts.sql` FS-* |
| T-VENDOR-RCA-READY | **MSCI share** + **`TRANSFORM_PROD.CLEANED.CLEANED_RCA_*`** + **`TRANSFORM.RCA`** + `transform_rca` / seeds / tests | n/a | Same | pending | **Checklist:** `MIGRATION_TASKS_FIRST_STREET_RCA.md` Part B; plan `RCA_DATA_MODELING_PLAN_TRANSFORM_RCA.md`; inventory RC-* |
| T-VENDOR-COSTAR-READY | **Snowflake** `TRANSFORM.COSTAR` + `SOURCE_PROD.COSTAR` + `RAW.COSTAR` + `TRANSFORM.FACT`/`DEV` CoStar objects; pretium-ai-dbt CoStar models | n/a | `source()` + **`TRANSFORM.DEV` `FACT_*`** per baseline | pending | **Checklist:** `MIGRATION_TASKS_COSTAR.md` §1–2, **§1.5** (`inventory_costar_for_dev_facts.sql` **A–L**; artifacts on file), §4–7 |
| T-VENDOR-CHERRE-READY | **Snowflake** `TRANSFORM.CHERRE` + `RAW.CHERRE` + pretium-ai-dbt `source('cherre'…)` / `FACT_CHERRE_*` / corridor stock / MLS–recorder–AVM–assessor–demographics lineage | n/a | **`TRANSFORM.CHERRE`** reads → **`TRANSFORM.DEV` `FACT_*`** + **`REFERENCE.CATALOG`** DS_025–DS_030 | pending | **Checklist:** `MIGRATION_TASKS_CHERRE.md` §1–3; smoke `inventory_cherre_transform_smoke.sql`; pair **`T-CORRIDOR-CHERRE-TAX-ASSESSOR-STOCK-READY`**, **`MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md`** P3–P5 |
| T-VENDOR-REDFIN-READY | **Snowflake** `TRANSFORM.REDFIN` (latest trackers) + optional `RAW.REDFIN` / `SOURCE_PROD.REDFIN` + pretium-ai-dbt `cleaned_redfin_*` / `fact_redfin_*` | n/a | `source()` parity → **`TRANSFORM.DEV` `FACT_*`** per baseline | pending | **Checklist:** `MIGRATION_TASKS_STANFORD_REDFIN.md` Part A **§A1.5** (`inventory_stanford_redfin_for_dev_facts.sql` **RF-***; artifacts on file) |
| T-VENDOR-STANFORD-READY | **`SOURCE_PROD.STANFORD`** VARIANT parquet + `TRANSFORM.STANFORD` + `TRANSFORM.DEV` `FACT_STANFORD_*`; pretium-ai-dbt facts / corridor | n/a | Typed **`TRANSFORM.DEV` `FACT_*`** + vendor `source()` | pending | **Checklist:** `MIGRATION_TASKS_STANFORD_REDFIN.md` Part B **§B1.5–B1.6** (`inventory_stanford_redfin_for_dev_facts.sql` **ST-***; **OBJECT_KEYS** diff on file) |
| T-DEV-REF-OXFORD-METRO-CBSA | **Snowflake** `TRANSFORM.DEV.REF_OXFORD_METRO_CBSA` (Oxford metro → Pretium CBSA); upstream `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK` | 1 table | **`TRANSFORM.DEV`** `REF_OXFORD_METRO_CBSA` | migrated | **Checklist:** `MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md` §1.5; **dbt:** `models/transform/dev/oxford/ref_oxford_metro_cbsa.sql` (table). Emergency CTAS: pretium-ai-dbt `scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql`; profile/join: `OXFORD_SOURCE_ENTITY_PROFILE_AND_CROSSWALK_JOIN.md` |
| T-DEV-FACT-OXFORD-AMREG-QUARTERLY | **`SOURCE_ENTITY.PRETIUM.AMREG`** + ref crosswalk; pretium-ai-dbt staging/fact (new) | n/a | **`TRANSFORM.DEV.FACT_OXFORD_AMREG_QUARTERLY`** | migrated | **Checklist:** `MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md` §0–4; **dbt:** `models/transform/dev/oxford/fact_oxford_amreg_quarterly.sql` (view); **MSA** join + MSAD caveat in profile doc; **DS_049** text → `transform_dev` |
| T-DEV-FACT-OXFORD-WDMARCO-QUARTERLY | **`SOURCE_ENTITY.PRETIUM.WDMARCO`**; pretium-ai-dbt staging/fact (new) | n/a | **`TRANSFORM.DEV.FACT_OXFORD_WDMARCO_QUARTERLY`** | migrated | **dbt:** `models/transform/dev/oxford/fact_oxford_wdmarco_quarterly.sql` (view); **national** `geo_id=USA`; **DS_050** definition/geo_level → `national`, `transform_dev` |
| T-TRANSFORM-BPS-PERMITS-COUNTY-READY | **Snowflake** `TRANSFORM.BPS.PERMITS_COUNTY` + pretium-ai-dbt `transform_bps` / consumers | n/a | `source()` → **`TRANSFORM.DEV` `FACT_*`** per baseline | pending | **Checklist:** `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md` Part A + **§1.5**; **batch 002** phase-1 CSV; **batch 003:** semantic-layer `source('transform_bps','permits_county')` + `fact_bps_permits_county` view, `DESCRIBE` artifact `2026-04-19_batch003_bps_permits_county_describe.csv`, `dbt compile` OK. **Batch 012c:** **`dbt_utils.equal_rowcount`** (warn) vs silver — **Part A2 consumers + BPS-D grain / PK tests still open**. |
| T-TRANSFORM-CENSUS-ACS5-READY | **Snowflake** `TRANSFORM.CENSUS.ACS5` (~619M rows) + pretium-ai-dbt `fact_acs_*` / ACS5 snapshots | n/a | `source()` or typed **`TRANSFORM.DEV`** facts per cutover | pending | **Checklist:** same doc Part B; **batch 005:** `source('transform_census','acs5')` + `DESCRIBE` artifact + `inventory_transform_acs5_lodes_metadata_only.sql` — **ACS-D/E/F deferred** (warehouse window); **no** `FACT_ACS5` in semantic-layer yet |
| T-TRANSFORM-BLS-LAUS-CBSA-READY | **Snowflake** `TRANSFORM.BLS.LAUS_CBSA` | n/a | Observe / thin bridge only — **do not** equate `AREA_CODE` to OMB CBSA | pending | **Checklist:** same doc Part C; **`fact_bls_laus_cbsa_monthly`** rolls up from **LAUS_COUNTY** |
| T-TRANSFORM-BLS-LAUS-COUNTY-READY | **Snowflake** `TRANSFORM.BLS.LAUS_COUNTY` + `fact_bls_laus_county_monthly` / household labor facts | n/a | `source('bls_transform', 'laus_county')` parity → **`TRANSFORM.DEV` `FACT_*`** | pending | **Checklist:** same doc Part D; **batch 004:** `source('bls_transform','laus_county')` + `fact_bls_laus_county` view, `DESCRIBE` artifact, **`dbt build` OK** — consumer / monthly-fact parity still open |
| T-TRANSFORM-LODES-OD-BG-READY | **Snowflake** `TRANSFORM.LODES.OD_BG` (~64M) vs `SOURCE_PROD.LEHD` cleaned path | n/a | Single governed read path → **`TRANSFORM.DEV` / analytics facts** | pending | **Checklist:** same doc Part E; **batch 005:** `fact_lodes_od_bg` view + `DESCRIBE` artifact + row-count smoke. **Batch 012c:** **`equal_rowcount`** warn vs silver. **dual-path / consumer cutover** (Part E3) **still open** — feeds gravity / hex OD downstream of corridor (`MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md` downstream §). |
| T-CYBERSYN-GLOBAL-GOVERNMENT-READY | **`SOURCE_SNOW.GLOBAL_GOVERNMENT`** Cybersyn objects + `CYBERSYN_DATA_CATALOG` distinct `table_name` + `models/sources/sources_global_government.yml` + `models/reference/geography/*` + planned **`TRANSFORM.DEV`** `FACT_*` from matrix tiers **1–6** | n/a | **SOURCE_SNOW** (reads) → **REFERENCE.GEOGRAPHY** (Jon spine/dictionary) → **TRANSFORM** (Alex facts) | pending | **Checklist:** `MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md` §Required actions; matrix + MVP shortlist: `../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`; TSV: `artifacts/cybersyn_global_government_catalog_table_names.tsv` |
| T-CORRIDOR-REFERENCE-H3-SPINE-READY | **`REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL`** + **`REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL`** (BG→H3 R8), `BLOCKGROUPS` + optional **`ANALYTICS.REFERENCE`** mirror fallbacks | n/a | Align `corridor_pipeline.load_bridge` FQN with physical REFERENCE.GEOGRAPHY | pending | **Checklist:** `MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md` §1; `inventory_corridor_pipeline_critical.sql` **CORR-REF-*** |
| T-CORRIDOR-LODES-OD-H3-R8-READY | **`TRANSFORM.LODES.OD_H3_R8`** (hex-pair OD annual) | n/a | Feeds **`fact_lodes_od_h3_r8_annual`** → employment-center chain | pending | **Checklist:** corridor doc §2.2; inventory **CORR-LODES** section |
| T-CORRIDOR-LODES-EMPLOYMENT-CENTER-CHAIN-READY | dbt chain **OD_H3_R8** → `fact_lodes_od_workplace_hex_annual` → `ref_corridor_employment_centers` → `fact_lodes_nearest_center_h3_r8_annual` | n/a | Built tables in **ANALYTICS** + **TRANSFORM.DEV** per project | pending | **Checklist:** corridor doc §2.3; vintage alignment across models |
| T-CORRIDOR-CHERRE-TAX-ASSESSOR-STOCK-READY | **`source('cherre', 'TAX_ASSESSOR_V2')`** share → **`TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8`** | n/a | Ward **stock** spine column | pending | **Checklist:** corridor doc §3; `cherre_database` / `cherre_schema` vars |
| T-CORRIDOR-OVERTURE-PLACE-POI-READY | **`source('overture_maps', 'place')`** → **`FACT_OVERTURE_AMENITY_H3_R8_SNAPSHOT`** (registry) | n/a | `SOURCE_SNOW` cutover per YAML `canonical_target` | pending | **Checklist:** corridor doc §4 |
| T-TRANSFORM-DEV | `dbt/models/transform/dev/` | 81 | `TRANSFORM.DEV` (`FACT_*` / `RAW_*` misplacements → `SOURCE_PROD`) | pending | **001** Zillow; **003–004** BPS + BLS LAUS; **005** LODES OD_BG view + ACS5 source/metadata only; **008** Oxford `REF_*` + `FACT_OXFORD_*`; **009** FHFA + Freddie Mac thin facts; **010** HUD/IRS grain-split `FACT_*`; **011** FHFA mortgage performance + UAD + HPI county/CBSA slices; **012** Yardi fund_opco **`FACT_PROGRESS_YARDI_*`** / **`FACT_BH_YARDI_*`** (`MIGRATION_LOG.md`); **026** labor/automation **`FACT_DOL_ONET_*`**, Epoch refs, **`fact_county_soc_employment`**, **`fact_county_ai_replacement_risk`** + vendor ref bridge (`MIGRATION_LOG.md` batch **026**, **`LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`**). **033** corridor **`CONCEPT_*`** + `dbt_project.yml` **`transform.dev.concept`** (fixes **`CONCEPT_*`** mis-builds on **`ANALYTICS.DBT_DEV`**); **`MET_127`–`MET_132`**. Remainder pending |
| T-ANALYTICS-FACTS | `dbt/models/analytics/facts/` | 101 | **`TRANSFORM.DEV` `FACT_*`** / **`CONCEPT_*`** only (not `ANALYTICS`) | pending | Legacy folder name; physical target is always **TRANSFORM.DEV** |
| T-ANALYTICS-FEATURES | `dbt/models/analytics/features/` | 144 | `ANALYTICS.DBT_DEV` `FEATURE_*` | pending | Corridor + signal features |
| T-ANALYTICS-FEATURE-EFFECTIVE-RENT-STACK | **Snowflake SQL** `FEATURE_*` / `MODEL_*` / `ESTIMATE_*` on **`ANALYTICS.DBT_DEV`**: effective rent, cohort **median/stddev**, **z-scores**, deciles / **sort_key**, forward rent **estimate**; catalog `metric` + **`bridge_product_type_metric`** | n/a | `ref('fact_*')` / `ref('concept_*')` / mart **`concept_*`** | pending | **Checklist:** `MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md` §1–4; depends on rent/concession **FACT**/vendor readiness (Markerr, Matrix, ApartmentIQ, CoStar, Yardi, Zillow, etc.) + **`REFERENCE.GEOGRAPHY`**. **Batch 013 (partial):** `models/analytics/feature/feature_rent_market_monthly_spine.sql` — first **`FEATURE_*`** spine on **`ref('concept_rent_market_monthly')`**; physical view **`ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY`** (`alias=feature_rent_market_monthly`); completion still requires cohort/z models + **`MODEL_*`/`ESTIMATE_*`** + catalog rows. **Canonical rule:** `CANONICAL_COMPLETION_DEFINITION.md`. |
| T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK | pretium-ai-dbt **`fact_county_ai_replacement_risk`**, **`feature_ai_replacement_risk_cbsa`**, **`feature_ai_replacement_risk_county`**, **`feature_structural_unemployment_risk_county`**, **`mart_county_ai_automation_risk`** (EDW mart; canonical semantic-layer **`fact_county_ai_automation_risk`**), **`model_county_ai_risk_dual_index`** (O*NET / QCEW / Epoch / AIGE paths) | n/a | **`TRANSFORM.DEV`** `FACT_*` + **`ANALYTICS.DBT_DEV`** `FEATURE_*` / `MODEL_*`; optional **`ESTIMATE_*`** only if explicit **forward** risk forecast | pending | **Playbook:** `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md` §3; **lineage:** pretium-ai-dbt `AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md`. **Canonical register:** **`LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`**. **Batches 026–027:** FACT spine + vendor ref + geo; **batch 027** — four **FEATURE_** views from **`fact_county_ai_replacement_risk`** (`naics_code='ALL'` CBSA pattern; **`onet_soc_naics_enabled`** var). **Still open:** real CBSA×NAICS industry feature (legacy parity), **`fact_county_ai_automation_risk`** (semantic-layer) + **`MODEL_*`**, AIGE, **`metric_derived`**, optional county-AI `equal_rowcount` warn vs legacy. |
| T-ANALYTICS-MODELS | `dbt/models/analytics/models/` | 46 | `ANALYTICS.DBT_DEV` `MODEL_*` | pending | Includes rent-ready / scorecard paths |
| T-ANALYTICS-EST | `dbt/models/analytics/estimates/` | 27 | `ANALYTICS.DBT_DEV` `ESTIMATE_*` | pending | |
| T-ANALYTICS-INTEL | `dbt/models/analytics/intel/` | 15 | `ANALYTICS.DBT_DEV` `MODEL_*` or `ESTIMATE_*` (rename; no `BI_*` as analytics contract) | pending | |
| T-ANALYTICS-REF | `dbt/models/analytics/reference/` | 28 | `REFERENCE.GEOGRAPHY` **or** `ANALYTICS.DBT_DEV` bridge **view** (`MODEL_*` if materialized in analytics) | pending | Split vendor vs census per row on migrate |
| T-ANALYTICS-SCORES | `dbt/models/analytics/scores/` | 40 | `ANALYTICS.DBT_DEV` `MODEL_*` or `ESTIMATE_*` | pending | |
| T-ANALYTICS-PROG | `dbt/models/analytics/progress_market_analysis/` | 6 | `ANALYTICS.DBT_DEV` `MODEL_*` | pending | |
| T-PROD-FEATURES | `dbt/models/analytics_prod/features/` | 96 | `ANALYTICS.DBT_DEV` | pending | Market selection pillars / absorption |
| T-PROD-MODELS | `dbt/models/analytics_prod/models/` | 68 | `ANALYTICS.DBT_DEV` | pending | |
| T-PROD-INTEL | `dbt/models/analytics_prod/intel/` | 36 | `ANALYTICS.DBT_DEV` `MODEL_*` / `ESTIMATE_*` | pending | Signal inputs to CBSA scoring |
| T-PROD-SANDBOX | `dbt/models/analytics_prod/sandbox/` | 53 | `skipped` or `ANALYTICS.DBT_STAGE` | pending | Observe-only unless promoted |
| T-PROD-SIGNALS | `dbt/models/analytics_prod/signals/` | 12 | `ANALYTICS.DBT_DEV` `FEATURE_*` / `MODEL_*` | pending | |
| T-PROD-RENT-FC | `dbt/models/analytics_prod/rent_forecast/` | 14 | `ANALYTICS.DBT_DEV` | pending | Prism workbench series |
| T-TRANSFORM-PROD-FACT | `dbt/models/transform_prod/fact/` | 335 | `TRANSFORM.DEV` **or** skip if Jon canonical | pending | Per-model: if duplicate of Jon `TRANSFORM.FACT` → skip |
| T-TRANSFORM-PROD-REF | `dbt/models/transform_prod/ref/` | 140 | `TRANSFORM.DEV` `REF_*` seeds/tables | pending | Replace `TRANSFORM_PROD.REF` hardcodes |
| T-TRANSFORM-PROD-CLEANED | `dbt/models/transform_prod/cleaned/` | 316 | **skip** (Jon **PROD** `TRANSFORM.[VENDOR]` / legacy mirror) | skipped | Alex re-points consumers to Jon PROD; no duplicate cleanse in Alex targets |
| T-TRANSFORM-PREFLIGHT | `dbt/models/transform_prod/preflight_structural_risk.sql` | 1 | TBD | pending | Single file at folder root in inventory |
| T-EDW-DELIVERY | `dbt/models/edw_prod/delivery/` | 180 | `SERVING.*` / Spencer contract **not** `SERVING.DEMO` alone | blocked | Confirm owner: migrate thin **demo** subset to `SERVING.DEMO` only if Alex-owned |
| T-EDW-MART | `dbt/models/edw_prod/mart/` | 138 | blocked / partner | blocked | Spencer / IC; align with `MIGRATION_PLAN.md` before moving |
| T-EDW-REF | `dbt/models/edw_prod/reference/` | 59 | `EDW_PROD.REFERENCE` legacy vs `REFERENCE.CATALOG` | pending | Dim/geo registry—many stay EDW until catalog merge |
| T-EDW-AI | `dbt/models/edw_prod/ai/` | 60 | TBD | pending | Glossary / AI views |
| T-EDW-EXPORTS | `dbt/models/edw_prod/exports/` | 10 | TBD | pending | |
| T-EDW-DATASETS | `dbt/models/edw_prod/datasets/` | 4 | TBD | pending | |
| T-EDW-SYSTEM | `dbt/models/edw_prod/system/` | 2 | TBD | pending | |
| T-EDW-ADHOC | `dbt/models/edw_prod/adhoc/` | 1 | TBD | pending | |
| T-ADMIN-CATALOG | `dbt/models/admin/catalog/` | 58 | `ADMIN.CATALOG` (stay) or seeds in new repo | pending | Catalog dims—coordinate registry |
| T-ADMIN-GOV | `dbt/models/admin/governance/` | 8 | `ADMIN` / reference | pending | |
| T-ADMIN-AUTO-ML | `dbt/models/admin/auto_ml/` | 8 | `ADMIN.*` / `ANALYTICS.DBT_DEV` `ESTIMATE_*` or `MODEL_*` (no facts in ANALYTICS) | pending | |
| T-ADMIN-DIMS | `dbt/models/admin/dims/` | 5 | `REFERENCE.CATALOG` / `ADMIN` | pending | |
| T-ADMIN-REF | `dbt/models/admin/reference/` | 3 | `REFERENCE.*` | pending | |
| T-ADMIN-DISCOVERY | `dbt/models/admin/discovery/` | 2 | TBD | pending | |
| T-ADMIN-ROOT | `dbt/models/admin/dim_*.sql`, `macro_smoke_test.sql` | 3 | TBD | pending | Root-level admin SQL |
| T-ANCHOR | `dbt/models/anchor/` | 14 | TBD | pending | Staging/marts |
| T-BI-BKFS | `dbt/models/bi/bkfs/` | 7 | TBD | pending | |
| T-SOURCE-PROD | `dbt/models/source_prod/` | 2 | `SOURCE_PROD.*` | pending | Shovels |
| T-STAGING | `dbt/models/staging/` | 4 | `SOURCE_PROD` / `TRANSFORM.DEV` | pending | |
| T-SERVING-DEMO | `dbt/models/serving/demo/` | 1 | `SERVING.DEMO` | pending | |
| T-TIME-SPINE | `dbt/models/_time_spine.sql` | 1 | new repo semantic / time spine | pending | |

### Strata backend consumer graph (`strata_backend`)

Detail: **`MIGRATION_TASKS_STRATA_BACKEND_LINEAGE.md`** (Snowflake name → pretium-ai-dbt model → upstream → Alex target).

| Task ID | Scope (strata_backend) | Primary post-migration target | Status | Notes |
|---------|-------------------------|-------------------------------|--------|-------|
| T-STRATA-META-IS | `INFORMATION_SCHEMA` patterns | **Observe** — no data migration | skipped | Governance / drift |
| T-STRATA-ADMIN-CATALOG | `ADMIN.CATALOG` bridges + dims + offering maps | `ADMIN.CATALOG` / `REFERENCE.CATALOG` seeds | pending | Pairs with `T-ADMIN-CATALOG` |
| T-STRATA-ANALYTICS-FACTS-COUNTY | County relations **strata names** `ANALYTICS.FACTS.*` (legacy namespace) | **`TRANSFORM.DEV` `FACT_*`** — update strata to `TRANSFORM.DEV` or compat view | pending | Pairs with `T-ANALYTICS-FACTS` |
| T-STRATA-ANALYTICS-FACTS-H3-MAP | H3 map `FACTS.*` in strata + `market-map.dto.ts` | **`TRANSFORM.DEV` `FACT_*`** | pending | Strata/app should not assume facts live under `ANALYTICS` |
| T-STRATA-ANALYTICS-FEATURES-H3-MAP | `FEATURE_BTR_SIGNALS_H3_R8`, `FEATURE_RCA_MF_CAPITAL_SIGNALS_H3_R8`, `FEATURE_CHERRE_MFR_TIER_H3_R8` | `ANALYTICS.DBT_DEV` | pending | Pairs with `T-ANALYTICS-FEATURES` |
| T-STRATA-ANALYTICS-MODELS-CORRIDOR-MARTS | `MART_CBSA_RANKINGS_*`, `MART_COUNTY_RANKINGS_*` | `ANALYTICS.DBT_DEV` `MODEL_*` | pending | Includes `model_market_scorecard_*` upstream |
| T-STRATA-ANALYTICS-REF-DIM-GEO | `DIM_GEO_COUNTY_CBSA` | `REFERENCE.GEOGRAPHY` + optional **`ANALYTICS.DBT_DEV` `MODEL_*`** compat view (not a fact) | pending | Pairs with `T-ANALYTICS-REF` |
| T-STRATA-ANALYTICS-PROD | `FEATURE_MARKERR_RENT_ABSORPTION_ZIP`, `SANDBOX.IC_FEATURES_H3_6` | `ANALYTICS.DBT_DEV` / sandbox **skip** | pending | Pairs with `T-PROD-FEATURES`, `T-PROD-SANDBOX` |
| T-STRATA-DEV-JAKAR | `DEV.JAKAR.GEORGIA_ALL_SCHOOLS` | **skip** (demo) | skipped | |
| T-STRATA-DS-SFDC-ACQUISITION | `DS_SOURCE_PROD_SFDC…ACQUISITION__C` | CRM / **blocked** for Alex transform | blocked | |
| T-STRATA-EDW-DELIVERY-STRATA | Listed `EDW_PROD.DELIVERY` `V_*` / `FCT_*` | `EDW_PROD` until **SERVING** contract; **`SERVING.DEMO`** subset only if agreed | blocked | Pairs with `T-EDW-DELIVERY` |
| T-STRATA-EDW-MART-STRATA | Listed `EDW_PROD.MART` `MART_*` | **blocked** / Spencer `SERVING.MART` path | blocked | Pairs with `T-EDW-MART` |
| T-STRATA-EDW-REF-DIMS | `EDW_PROD.REFERENCE` dims in strata list | `REFERENCE.CATALOG` over time; interim **EDW** | pending | |
| T-STRATA-EDW-AI-GLOSSARY | `V_GLOSSARY_MARKET_METRICS` | `EDW_PROD.AI` / glossary registry | pending | |
| T-STRATA-OVERTURE-CARTO | Overture CARTO place/segment | **External** + license observe | pending | |
| T-STRATA-RAW-CENSUS-ACS5 | `RAW.CENSUS.ACS5_RAW` | Consolidate to **`SOURCE_PROD`** / **`TRANSFORM.CENSUS`** per baseline | pending | |
| T-STRATA-REFERENCE-GEO-STRATA | `REFERENCE.GEOGRAPHY` spine tables in strata | `REFERENCE.GEOGRAPHY` | pending | |
| T-STRATA-SOURCE-ENTITY-CRM | `SOURCE_ENTITY.BH/PROGRESS` | **blocked** CRM | blocked | |
| T-STRATA-SOURCE-PROD-EDUCATION-EDGE | `SOURCE_PROD.EDUCATION.EDGE_SCHOOL_CHARACTERISTICS_2324` | `SOURCE_PROD.EDUCATION` | pending | |
| T-STRATA-TRANSFORM-VENDOR-READS | `TRANSFORM.<vendor>` tables in strata (Cherre, Markerr, …) | **Read** via `source()` — **Jon** owns objects | skipped | Alex **`FACT_*`** wrap or join only |
| T-STRATA-TRANSFORM-PROD-STRATA | `TRANSFORM_PROD` cleaned/fact/ref in strata | cleaned **skip**; fact/ref per `MIGRATION_RULES` | pending | |
| T-STRATA-MARKET-SERVICE-DYNAMIC | Dynamic `${prefix}_*` **facts** (legacy `ANALYTICS.FACTS` in app) | `ADMIN.CATALOG` allowlist + **`TRANSFORM.DEV` `FACT_*`** per prefix — **not** `ANALYTICS.DBT_DEV` | pending | |
| **T-TEARSHEET-BUNDLE** | **`tearsheet.service.ts`** — 38 qualified objects (see doc) | Per **`T-TEARSHEET-*`** in `MIGRATION_TASKS_TEARSHEET_SERVICE.md` | pending | Overlaps **T-STRATA-ADMIN-CATALOG**, **T-STRATA-EDW-MART-STRATA**, **T-STRATA-TRANSFORM-PROD-STRATA** — execute tearsheet doc for **granular** rows |

**Seeds (253 files):** Tracked in `MIGRATION_TASKS_INVENTORY_seeds.txt`. Target split:

- Analytics reference seeds → `REFERENCE.CATALOG` / `REFERENCE.DRAFT` / `ANALYTICS` seed paths in new repo.
- Vendor xwalk CSVs → `TRANSFORM.DEV` seed bundle (`seeds/transform_dev/` pattern in semantic-layer).

**Macros (141 files):** Tracked in `MIGRATION_TASKS_INVENTORY_macros.txt`. Migrate with the models that call them; log macro moves in `MIGRATION_LOG.md` Summary counters (`Macro migrations`).

---

## Priority waves (Alex dev pipeline)

**Principle:** **`TRANSFORM.DEV.FACT_*`** and **`TRANSFORM.DEV.CONCEPT_*`** first — everything else supports or consumes that base.

1. **`TRANSFORM.DEV`** — migrate and run **`FACT_*`** and **`CONCEPT_*`** for the active vendor pilot (minimal slice that compiles end-to-end).  
2. **`SOURCE_PROD.[VENDOR].RAW_*`** — only as required to **feed** step 1 (plus any mandatory **`TRANSFORM.DEV.REF_*`** for joins).  
3. **Pilot sequence** for step 1–2 (vendor batches): Zillow, then BLS → BPS → MARKERR → REDFIN per plan — each batch completes **`FACT_*` / `CONCEPT_*`** before expanding scope.  
   - **BH multifamily competitive stack:** complete **`T-VENDOR-APARTMENTIQ-READY`** and **`T-VENDOR-YARDI-MATRIX-READY`** (`MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`) before treating ApartmentIQ / Yardi Matrix as migration-complete.  
   - **CoStar MF / scenarios:** complete **`T-VENDOR-COSTAR-READY`** (`MIGRATION_TASKS_COSTAR.md`) before expanding **`FACT_*`** that depend on **`TRANSFORM.COSTAR.SCENARIOS`**, **`SOURCE_PROD.COSTAR`**, or the wide DataExport parquet path.  
   - **Yardi operational (BH + Progress):** complete **`T-VENDOR-YARDI-READY`** (`MIGRATION_TASKS_YARDI_BH_PROGRESS.md`) before expanding **`FACT_*`** that read **`TRANSFORM.YARDI.*_BH`** / **`*_PROGRESS`** (ledger, occupancy, rent-ready paths).  
   - **First Street + RCA:** complete **`T-VENDOR-FIRST-STREET-READY`** and **`T-VENDOR-RCA-READY`** (`MIGRATION_TASKS_FIRST_STREET_RCA.md`) before expanding climate / MSCI-backed **`FACT_*`** that depend on **`TRANSFORM.FIRST_STREET`** or **`TRANSFORM.RCA`**.  
4. **`REFERENCE.GEOGRAPHY`** alignment for any **`FACT_*` / `CONCEPT_*`** using deprecated xwalk names.  
5. **`ANALYTICS.DBT_DEV`** — **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** that **`ref()`** the migrated **`TRANSFORM.DEV`** objects (**after** step 1 is solid).  
6. **`ANALYTICS.DBT_STAGE`** `QA_*` on those stacks.  
7. **`SERVING.DEMO`** thin views for Presley/Prism dev.  
8. **EDW / admin** clusters only after contract with Spencer / registry owners.

---

## Maintenance

- After each migration batch, update **`MIGRATION_LOG.md`** (rows + counters); update **Status** in the task table above **in place** for touched clusters.  
- Refresh the three `MIGRATION_TASKS_INVENTORY_*.txt` files when the old repo adds/removes objects (script or `find` as used for this snapshot).

---

*Snapshot generated from pretium-ai-dbt `dbt/models`, `dbt/seeds`, `dbt/macros` on 2026-04-19.*
