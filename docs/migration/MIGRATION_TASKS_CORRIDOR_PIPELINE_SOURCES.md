# Migration readiness — **Corridor development pipeline** (Ward clustering) critical sources

**Owner:** Alex  
**Governing docs:** pretium-ai-dbt `docs/governance/CORRIDOR_PRODUCT_AGNOSTIC_DEV_PIPELINE.md`, `CORRIDOR_CREATION_METHODOLOGY.md`, `CORRIDOR_ASSIGNMENT_DELIVERY_SPEC.md`  
**Code:** `scripts/corridor_1fact/corridor_pipeline.py`, `corridor_assignment_core.py`, `scripts/corridor_1fact/registry.yaml`  
**Inventory SQL:** `scripts/sql/migration/inventory_corridor_pipeline_critical.sql`

**Purpose:** Everything that must be **present, correct, and granted** before `corridor_pipeline.py` can build a spine, run Ward clustering, and write **`TRANSFORM.DEV.FACT_CORRIDOR_*`**. This doc **adds** corridor-specific objects not fully captured elsewhere; it **references** existing tasks where overlap applies.

---

## §0 Dependency matrix (read order)

| Layer | Critical objects | Covered by |
|-------|------------------|------------|
| **REFERENCE spine** | **`REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL`** (default hex universe; ~13.1M rows, 2026-04-19). *Note:* `corridor_pipeline.py` docstring still says `reference.reference.cbsa_h3_r8_polyfill` — **verify FQN** in your account or add a compatibility view. | **T-CORRIDOR-REFERENCE-H3-SPINE-READY** |
| **REFERENCE / ANALYTICS bridges** | **`REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL`** (SnowSQL `pretium-ai-dbt/scripts/sql/reference/geography/blockgroup_h3_r8_polyfill.sql`; optional view **`BRIDGE_BG_H3_R8_POLYFILL`**) or `ANALYTICS.REFERENCE` fallback, `REFERENCE.GEOGRAPHY.BLOCKGROUPS` (water filter), `REFERENCE.GEOGRAPHY` / `ANALYTICS.REFERENCE` `BRIDGE_ZIP_H3_R8_POLYFILL`, `BRIDGE_PLACE_H3_R8_POLYFILL`, `BRIDGE_PLACE_ZIP` | Same task + **§1.5** resolution rules in `corridor_pipeline.py` |
| **TRANSFORM.LODES** | `TRANSFORM.LODES.OD_BG` (gravity), **`TRANSFORM.LODES.OD_H3_R8`** (hex-pair OD → workplace/residence flows) | **T-TRANSFORM-LODES-OD-BG-READY** + **T-CORRIDOR-LODES-OD-H3-R8-READY** |
| **TRANSFORM.CENSUS** | `TRANSFORM.CENSUS.ACS5` | **T-TRANSFORM-CENSUS-ACS5-READY** (`MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md` Part B) |
| **Stanford** | `SOURCE_PROD.STANFORD` → `TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT` | **T-VENDOR-STANFORD-READY** |
| **Cherre (stock)** | `source('cherre', 'TAX_ASSESSOR_V2')` share → `TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8` | **T-CORRIDOR-CHERRE-TAX-ASSESSOR-STOCK-READY** (vendor-wide prep: **`MIGRATION_TASKS_CHERRE.md`**) |
| **RCA (optional registry)** | `TRANSFORM.RCA.TRANSACTION` → `FACT_RCA_MF_TRANSACTIONS_H3_R8_MONTHLY` | **T-VENDOR-RCA-READY** |
| **Overture (optional registry)** | `OVERTURE_MAPS__PLACES.CARTO.PLACE` → `FACT_OVERTURE_AMENITY_H3_R8_SNAPSHOT` | **T-CORRIDOR-OVERTURE-PLACE-POI-READY** |
| **Employment-center chain (dbt)** | `FACT_LODES_OD_H3_R8_ANNUAL` → `FACT_LODES_OD_WORKPLACE_HEX_ANNUAL` → `REF_CORRIDOR_EMPLOYMENT_CENTERS` → `FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | **T-CORRIDOR-LODES-EMPLOYMENT-CENTER-CHAIN-READY** |

**Python default spine** (`build_spine` in `corridor_pipeline.py`): loads **bridge**, **ACS5** (`transform.dev.fact_census_acs5_h3_r8_snapshot`), **stock** (`transform.dev.fact_cherre_stock_h3_r8`), **Stanford SEDA**, **LODES gravity**, **LODES nearest center**, optional **place_zip_hints**.

**Not part of this spine (pretium-ai-dbt):** `path:models/transform/dev/fund_opco` includes **`source_entity_landings/`** (`dev_source_entity_progress_*` CTAS from `SOURCE_ENTITY.PROGRESS`). That is **OPCO fund-tab** work only — not LODES/Cherre/ACS/H3. Use selector **`fund_opco_yardi_silver_facts_only`** for the six `FACT_*` Yardi models only; see pretium-ai-dbt `docs/governance/CORRIDOR_PRODUCT_AGNOSTIC_DEV_PIPELINE.md` and `dbt/models/transform/dev/fund_opco/README.md`.

---

## §1 Reference — H3 spine and water filter

### §1.1 `REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL`

- [ ] Run **CORR-REF-A** (columns + row count + distinct `cbsa_id` / `h3_r8_hex`).
- [ ] Align **`corridor_pipeline.load_bridge`** `fqn` with physical **`REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL`** (or grant-compatible alias) — `reference.reference` path may be **stale** in some accounts.

### §1.2 BG bridge + TIGER blockgroups (full-water hex drop)

- [ ] **CORR-REF-B / C:** resolve **`BLOCKGROUP_H3_R8_POLYFILL`** (canonical BG→H3 R8) / legacy view `BRIDGE_BG_H3_R8_POLYFILL` and `BLOCKGROUPS` (pipeline tries `REFERENCE.GEOGRAPHY` first, then `ANALYTICS.REFERENCE`).
- [ ] Document which FQN won in **`MIGRATION_LOG.md`**.

### §1.3 Place / ZIP hint bridges (optional CBSA runs)

- [ ] **CORR-REF-D:** `ANALYTICS.REFERENCE.BRIDGE_PLACE_H3_R8_POLYFILL`, `BRIDGE_ZIP_H3_R8_POLYFILL`, `BRIDGE_PLACE_ZIP` — smoke `SELECT 1`.

---

## §2 LODES — `OD_BG` + **`OD_H3_R8`** + employment-center chain

### §2.1 `TRANSFORM.LODES.OD_BG`

- [ ] **T-TRANSFORM-LODES-OD-BG-READY** + `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md` Part E.

### §2.2 **`TRANSFORM.LODES.OD_H3_R8`**

**Physical snapshot (2026-04-19):** ~**3,904,710** rows; columns include `VINTAGE_YEAR`, `H3_R8_RESIDENCE`, `H3_R8_WORKPLACE`, `CBSA_ID_RESIDENCE`, `CBSA_ID_WORKPLACE`, `JOBS_*`, `BG_PAIR_COUNT`, `DBT_UPDATED_AT`.

- [ ] **CORR-LODES-H3-A** inventory (columns, row count, `vintage_year` distribution).
- [ ] Dup probe on `(vintage_year, h3_r8_residence, h3_r8_workplace)` (bounded vintage if expensive).

### §2.3 Employment-center dbt chain

- [ ] `fact_lodes_od_h3_r8_annual` ← **OD_H3_R8**
- [ ] `fact_lodes_od_workplace_hex_annual` ← prior ref
- [ ] `ref_corridor_employment_centers` ← workplace hex
- [ ] `fact_lodes_nearest_center_h3_r8_annual` ← centers + `bridge_bg_h3_r8_polyfill` (**`BLOCKGROUP_H3_R8_POLYFILL`**) hex universe

- [ ] Smoke max(`vintage_year`) alignment across the chain (see `corridor_pipeline` fingerprint queries).

---

## §3 Cherre — tax assessor → stock H3

- [ ] `source('cherre', 'TAX_ASSESSOR_V2')` share reachable from migration role.
- [ ] `TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8` (or compat path) row count / segment (`SFR`/`MF`) cardinality.
- [ ] Align with **`cherre_database` / `cherre_schema`** vars (`sources.yml`).

---

## §4 Overture — Places POI

- [ ] `source('overture_maps', 'place')` share (legacy DB; **`canonical_target: SOURCE_SNOW`** in YAML) — plan cutover.
- [ ] `FACT_OVERTURE_AMENITY_H3_R8_SNAPSHOT` build + smoke.

---

## §5 RCA (registry extension only)

- [ ] **T-VENDOR-RCA-READY** — `TRANSFORM.RCA.TRANSACTION` for **`fact_rca_mf_transactions_h3_r8_monthly`** (`registry.yaml`).

---

## §6 `TRANSFORM.DEV` Ward input facts (smoke matrix)

**LODES / employment-center chain (native, no `ANALYTICS.FACTS` sources):** `models/transform/dev/lodes/` + selector **`corridor_h3_transform_dev`** — materializes **`TRANSFORM.DEV`** tables from **`TRANSFORM.LODES`** + **`REFERENCE.GEOGRAPHY`** + `ref('fact_lodes_od_h3_r8_annual')`. Runbook: **`docs/migration/RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md`**. Lineage: **`registry/lineage/corridor_lodes_h3_r8_lineage.yml`**.

**Other Ward inputs** (ACS, Cherre stock, Stanford SEDA, registry extensions) remain **separate migration tasks**; do **not** add dbt `source()` definitions pointed at **`analytics.facts`**.

Run **CORR-DEV-SMOKE** block in inventory SQL (or ad hoc):

| Physical table (Python loader) | Minimum check |
|--------------------------------|----------------|
| `TRANSFORM.DEV.FACT_CENSUS_ACS5_H3_R8_SNAPSHOT` | *pending native port* — `MAX(dbt_updated_at)`, row count > 0 |
| `TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8` | *pending native port* |
| `TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT` | *pending native port* |
| `TRANSFORM.DEV.FACT_LODES_OD_WORKPLACE_HEX_ANNUAL` | `MAX(vintage_year)` |
| `TRANSFORM.DEV.REF_CORRIDOR_EMPLOYMENT_CENTERS` | `COUNT(*) WHERE is_center` > 0 (spot CBSA) |
| `TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY` | `MAX(vintage_year)` |
| `TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL` | `MAX(vintage_year)` |

---

## §7 Task IDs (in `MIGRATION_TASKS.md`)

| Task ID | Scope |
|---------|--------|
| **T-CORRIDOR-REFERENCE-H3-SPINE-READY** | §1 — CBSA H3 polyfill + BG bridge + blockgroups + optional place/zip bridges |
| **T-CORRIDOR-LODES-OD-H3-R8-READY** | §2.2 — `TRANSFORM.LODES.OD_H3_R8` |
| **T-CORRIDOR-LODES-EMPLOYMENT-CENTER-CHAIN-READY** | §2.3 — OD H3 → workplace hex → ref employment centers → nearest center fact |
| **T-CORRIDOR-CHERRE-TAX-ASSESSOR-STOCK-READY** | §3 — Cherre assessor → stock H3 |
| **T-CORRIDOR-OVERTURE-PLACE-POI-READY** | §4 — Overture Places → amenity H3 |

**Related (existing):** **T-TRANSFORM-CENSUS-ACS5-READY**, **T-TRANSFORM-LODES-OD-BG-READY**, **T-VENDOR-STANFORD-READY**, **T-VENDOR-RCA-READY**.

---

## §8 Exit

- [ ] Archive CSVs from **CORR-*** blocks under `docs/migration/artifacts/`.
- [ ] **`MIGRATION_LOG.md`** — note FQN resolutions for bridges, max LODES vintage, Cherre share DB used.
- [ ] Flip task rows to `migrated` when §1–§6 complete.
