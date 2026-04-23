# QA — metrics across **FACT → CONCEPT → FEATURE → MODEL → ESTIMATE**

**Owner:** Alex  
**Purpose:** What to run (and in what order) so catalog-backed measures and analytics outputs validate: Snowflake parents exist, seeds match contracts, **REFERENCE.GEOGRAPHY** *GEO1_GEO2* xwalks resolve, CI stays green.

**Related:** [METRIC_INTAKE_CHECKLIST.md](./METRIC_INTAKE_CHECKLIST.md) · [QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md](./QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md) · [ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md) §Metric Registration Gates · [SERVING_DEMO_METRICS_CATALOG_MAP.md](../reference/SERVING_DEMO_METRICS_CATALOG_MAP.md) · [QA_GOVERNANCE_TEST_TYPES.md](./QA_GOVERNANCE_TEST_TYPES.md) (**GOV_*** vocabulary — no catalog tables)

---

## 0. Preflight — Snowflake parents (before blaming dbt)

**Naming (migration prose):** Treat **`REFERENCE.GEOGRAPHY`** join tables as **\<GEO1\>_\<GEO2\>_XWALK** (or polyfill spine where the physical name ends in **`_POLYFILL`**). **dbt** still uses the source name **`h3_polyfill_bridges`** and vars **`h3_polyfill_bridge_*`** for backward compatibility — that is legacy identifier noise, not the migration vocabulary.

| Risk | Check | When |
|------|--------|------|
| **ZIP ↔ H3 R8 xwalk** | `SELECT COUNT(*) FROM REFERENCE.GEOGRAPHY.BRIDGE_ZIP_H3_R8_POLYFILL` (physical **ZIP–H3 R8** polyfill table; mirror **`ANALYTICS.REFERENCE`**) | Before anything using **`source('h3_polyfill_bridges','bridge_zip_h3_r8_polyfill')`**. **`42S02`** → missing object **or** no **SELECT**. |
| **BG ↔ H3 R8 xwalk** | **`BLOCKGROUP_H3_R8_POLYFILL`** / compat **`BRIDGE_BG_H3_R8_POLYFILL`** | LODES **`OD_BG`** / hex workplace chain; **`fact_lodes_nearest_center_h3_r8_annual`** hex universe via **`bridge_bg_h3_r8_polyfill`**. |
| **Xwalk location override** | `dbt run … --vars '{"h3_polyfill_bridge_database":"ANALYTICS","h3_polyfill_bridge_schema":"REFERENCE"}'` | When xwalk tables exist only under **`ANALYTICS.REFERENCE`** — [RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md](./RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md). |
| **Admin xwalks** | `source('reference_geography', …)` present: `county`, `cbsa`, `zip_county_xwalk`, `postal_county_xwalk`, `county_cbsa_xwalk`, `zcta_cbsa_xwalk` | ZIP- / county-grain → CBSA. |
| **Place ↔ H3 R8 / ZIP** (corridor) | **`BRIDGE_PLACE_H3_R8_POLYFILL`**, **`BRIDGE_PLACE_ZIP`** — `SELECT 1` | Optional Python spine; **no** `source()` in this repo yet — see §0.1. |
| **CBSA ↔ H3 R8 hex spine** | **`CBSA_H3_R8_POLYFILL`** | Ward / corridor default hex universe. |
| **Vendor parents** | Per-vendor inventory SQL | First `dbt run` on that subtree. |

**Inventory:** `scripts/sql/migration/inventory_corridor_pipeline_critical.sql` (lists **ZIP–H3 R8** and **BG–H3 R8** polyfill identifiers under **`ANALYTICS.REFERENCE`** mirrors).

**Concept slice (checkbox walk + FEATURE alignment):** [`QA_CONCEPT_PREFLIGHT_CHECKLIST.md`](./QA_CONCEPT_PREFLIGHT_CHECKLIST.md) — per-`CONCEPT_*` vendor/geo dependencies and `FEATURE_*` parent notes.

---

## 0.1 Geography — H3 R8 and **REFERENCE.GEOGRAPHY** *GEO1_GEO2* xwalks

<a id="geo-xwalks"></a>

| Migration grain | Physical name (verify FQN) | `source()` in this repo |
|-----------------|---------------------------|-------------------------|
| Hex **H3 R8** | `H3_R8_*` on facts; **`CBSA_H3_R8_POLYFILL`** | Via LODES / corridor / facts — no single geography `source()` |
| **BG ↔ H3 R8** | **`BLOCKGROUP_H3_R8_POLYFILL`** (compat **`BRIDGE_BG_H3_R8_POLYFILL`**) | `h3_polyfill_bridges.bridge_bg_h3_r8_polyfill` |
| **ZIP ↔ H3 R8** | **`BRIDGE_ZIP_H3_R8_POLYFILL`** | `h3_polyfill_bridges.bridge_zip_h3_r8_polyfill` |
| **BG ↔ BG** (LODES) | **`TRANSFORM.LODES.OD_BG`** | `transform_lodes.od_bg` |
| **Place ↔ H3 R8** / **Place ↔ ZIP** | **`BRIDGE_PLACE_H3_R8_POLYFILL`**, **`BRIDGE_PLACE_ZIP`** | Operator / corridor only — [MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md](./MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md) §1.3 |
| **County** / **CBSA** | **`COUNTY`**, **`CBSA`** | `reference_geography` |
| **ZCTA → county** | **`ZIP_COUNTY_XWALK`** | `reference_geography.zip_county_xwalk` |
| **Postal ZIP → county** | **`POSTAL_COUNTY_XWALK`** | `reference_geography.postal_county_xwalk` |
| **County → CBSA** | **`COUNTY_CBSA_XWALK`** | `reference_geography.county_cbsa_xwalk` |
| **ZCTA → CBSA** | **`ZCTA_CBSA_XWALK`** | `reference_geography.zcta_cbsa_xwalk` |

**GOV_REFERENCE / GOV_COVERAGE:** vintage, ZCTA vs postal ZIP, OMB CBSA vs vendor “metro”; join coverage on BG↔hex and ZIP→CBSA paths — [QA_GOVERNANCE_TEST_TYPES.md](./QA_GOVERNANCE_TEST_TYPES.md).

---

## 0.2 KPIs — catalog seed tests (compile-time vs execution)

| KPI | Value / command | Notes |
|-----|-----------------|--------|
| **dbt parse** | `dbt parse` (target **parse**) | Merge gate; no warehouse. |
| **Tests bound to catalog seeds** | `./scripts/ci/print_catalog_seed_test_inventory.sh` → **`catalog_seed_bound_dbt_tests`** | Run after `dbt deps` (prints live count; **802** in a recent parse of this repo). |
| **Catalog seed tests executed** | `dbt build --select path:seeds/reference/catalog` | Prefer **`dbt build`** over seed-then-test so every CSV (including **`metric_derived_input`**) lands before **`42S02`** on **`METRIC_DERIVED_INPUT`**. |
| **`metric` / `metric_derived` compliance** | [§1e](#catalog-metric-qa) + [§1f](#catalog-metric-qa) | **Non-compliant `MET_*`:** rows in **§1e** output (**`failure_rows` > 0**) — bad **`table_path`**, missing relation/column, or drift vs **`INFORMATION_SCHEMA`**. Not derivable from compile-only KPIs. |

**Non-compliant metrics (operational definition):** any active **`REFERENCE.CATALOG.metric`** row whose **`table_path`** fails **§1e**, or whose lineage row is not **`qa_status = 'OK'`** in **§1f**, or that lacks required **`schema.yml`** tests per **ARCHITECTURE_RULES**. Re-run after every **`MET_*`** or FACT DDL change.

---

<a id="catalog-metric-qa"></a>

## 1. **`REFERENCE.CATALOG.metric` → `TRANSFORM.DEV` FACT_ / REF_**

| Step | Command / artifact | Pass criteria |
|------|-------------------|---------------|
| 1a | `dbt seed --select path:seeds/reference/catalog` (Snowflake **REFERENCE.CATALOG**) | Seeds load; **`metric`** tests pass. |
| 1b | **ARCHITECTURE_RULES** four gates | Before **`is_active`** on new **`MET_*`**. |
| 1c | `dbt run --selector catalog_metric_transform_dev_surface` | Listed FACT_/REF_ **SUCCESS**. |
| 1d | `dbt test --select path:models/transform/dev` (or narrower) | Schema tests on touched facts. |
| 1e | `snowsql … -f scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql` | **`failure_rows = 0`**. |
| 1f | `dbt run --select qa_catalog_metric_transform_dev_lineage` | **`qa_status = 'OK'`** for active **`TRANSFORM.DEV`** metric rows. |

**§1e scope:** only **`metric.table_path`** = **`TRANSFORM.DEV.*`**.

**Registration KPIs + object gaps:** `scripts/sql/validation/catalog_metric_registration_coverage.sql` — counts **`MET_*`** rows and lists **`TRANSFORM.DEV`** **`FACT_*` / `CONCEPT_*` / `REF_*`** relations with **no** matching **`metric.table_path`** (excludes **`QA_*`**).

**Corridor LODES:** `dbt run --selector corridor_h3_transform_dev` after §0 xwalks exist — [RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md](./RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md).

---

## 2. **CONCEPT_**

| Step | Command / artifact | Pass criteria |
|------|-------------------|---------------|
| 2a | `dbt run --select path:models/transform/dev/concept` | Compiles; refs resolve. |
| 2b | `dbt test --select path:models/transform/dev/concept` | YAML tests pass. |
| 2c | Catalog | If a concept column is a **metric**, repeat **§1e** when **`table_path`** points at CONCEPT (unusual). |

---

## 3. **FEATURE_** / 4. **MODEL_** / 5. **ESTIMATE_**

| Layer | Run | Tests / seeds |
|-------|-----|----------------|
| **FEATURE** | `dbt run --select path:models/analytics/feature` | `dbt test --select path:models/analytics/feature`; **`metric_derived`** rows — `dbt test --select metric_derived` |
| **MODEL** | `dbt run --select path:models/analytics/model` | `dbt test --select path:models/analytics/model`; **`metric_derived`** + **`schema_metric_derived.yml`** |
| **ESTIMATE** | `dbt run --select path:models/analytics/estimate` (when present) | **`metric_derived`** `analytics_layer_code = estimate` |

Details: [CATALOG_METRIC_DERIVED_LAYOUT.md](../reference/CATALOG_METRIC_DERIVED_LAYOUT.md).

### 3a Registration checkpoints (TRANSFORM.DEV MET_* / FEATURE MDV_*)

Row-level **catalog ↔ Snowflake** checks beyond seed YAML:

| Checkpoint | QA surface | Singular test (expect 0 rows) |
|------------|------------|-------------------------------|
| **TRANSFORM.DEV** `MET_*` (FACT / CONCEPT / REF / …) | `qa_catalog_metric_transform_dev_lineage` — **`data_status_code = active`** | `tests/catalog_registration/assert_catalog_metric_transform_dev_active_lineage_ok.sql` (**tag:** `metric_transform_dev_lineage`) |
| **FEATURE** `MDV_*` | `qa_catalog_metric_derived_feature_lineage` — `metric_derived` (feature, active) vs **`ANALYTICS.DBT_DEV`** | `tests/catalog_registration/assert_catalog_metric_derived_feature_registration_lineage.sql` |

**Run order (Snowflake):** `dbt build --selector catalog_metric_transform_dev_registration_enforcement` (or `scripts/ci/dbt_enforce_catalog_metric_registration.sh`) for **MET_*** on **TRANSFORM.DEV**. For full **tag:catalog_registration** (includes FEATURE singular), add `dbt run --selector catalog_metric_transform_dev_surface` (or vendor subset) → `dbt run --select path:models/analytics/feature` → `dbt run --select qa_catalog_metric_derived_feature_lineage` → `dbt test --select tag:catalog_registration`. Extend `feature_physical_map` in `qa_catalog_metric_derived_feature_lineage.sql` when adding a new **active** feature-layer `metric_derived` row.

---

## 6. CI / merge gate

| Layer | Local | Snowflake |
|-------|--------|-----------|
| Parse / graph | `dbt parse`; `scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh` | — |
| Catalog | `./scripts/ci/print_catalog_seed_test_inventory.sh` | `RUN_SNOWFLAKE_CHECKS=1` **`scripts/ci/run_catalog_quality_checks.sh`** (`dbt build` on catalog path) |
| Dimensions | — | `scripts/sql/validation/dimensional_reference_catalog_and_geography.sql` |
| **Every `MET_*` on TRANSFORM.DEV** | — | **§1e** + **§1f** |

---

## 7. Example — `fact_lodes_nearest_center_h3_r8_annual`

**Error:** `Object 'REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL' does not exist or not authorized`.

**Meaning:** **`source('h3_polyfill_bridges','bridge_bg_h3_r8_polyfill')`** defaults to that FQN (**`sources_transform.yml`** / **`dbt_project.yml`** identifier vars). Missing table **or** no **SELECT**.

**Fix:** Deploy/grant **BG ↔ H3 R8** (`BLOCKGROUP_H3_R8_POLYFILL`), or override **`h3_polyfill_bridge_*`** / **`h3_polyfill_bg_bridge_identifier`** — [RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md](./RUN_CORRIDOR_H3_TRANSFORM_DEV_OBJECTS.md).

---

## 8. **GOV_*** types

Six **GOV_*** labels are **QA categories** only — not **`REFERENCE.CATALOG`** dimensions. Table: [QA_GOVERNANCE_TEST_TYPES.md](./QA_GOVERNANCE_TEST_TYPES.md).

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial layered QA doc. |
| **0.2** | §8 → **GOV_*** taxonomy doc. |
| **0.3** | §0 county/CBSA + place + **`CBSA_H3_R8_POLYFILL`**; geography stub file. |
| **0.4** | **Condensed:** §0.1 geography merged here; **xwalk** migration vocabulary; §0.2 KPI table + **`print_catalog_seed_test_inventory.sh`**; stub **[QA_GEOGRAPHY_H3_R8_AND_ADMIN_SPINE.md](./QA_GEOGRAPHY_H3_R8_AND_ADMIN_SPINE.md)**. |
| **0.5** | §0.2 / CI: catalog path uses **`dbt build`** so **`metric_derived_input`** seeds before tests (avoids **`METRIC_DERIVED_INPUT` 42S02**). |
| **0.6** | §3a **catalog_registration** singular tests + `qa_catalog_metric_derived_feature_lineage`; selector **`catalog_registration_lineage`**. |
| **0.7** | §1: **`catalog_metric_registration_coverage.sql`** + METRIC_INTAKE scale note (**67K** vs **`MET_*`**). |
| **0.8** | §3a: unified **`assert_catalog_metric_transform_dev_active_lineage_ok`** (**tag:** `metric_transform_dev_lineage`); selector **`catalog_metric_transform_dev_registration_enforcement`**; **`dbt_enforce_catalog_metric_registration.sh`**; seed test **`metric_active_transform_dev_requires_column_and_three_part_path`**. |
