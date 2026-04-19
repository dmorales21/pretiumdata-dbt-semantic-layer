# How to treat each new metric (REFERENCE.CATALOG)

**Purpose:** Single checklist for **every new numeric or categorical signal** that should appear in IC, corridor, or semantic `CONCEPT_*` / `FEATURE_*` surfaces. Use before merging a new `FACT_*` or vendor column.

**Related:** `seeds/reference/catalog/metric.csv`, `dataset.csv`, `concept.csv`, `bridge_product_type_metric.csv`, `metric_derived.csv`, `MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md`, `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`, `scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`, **[PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](./PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md)** (ownership, env, four chains, Pilot A, reconciliation library).

---

## 1. Classify the measurement

| Step | Question | Action |
|------|----------|--------|
| 1.1 | Is it **vendor-native** (raw column) or **Pretium-defined** (ratio, blend, z-score)? | Native → **`metric`** row. Derived stack → **`metric_derived`** (+ optional inputs table later). |
| 1.2 | What **concept** (`concept_code`) does it answer (rent, home_price, migration, …)? | Must exist in **`concept.csv`**. If taxonomy is wrong, **add or split `concept`** first — do not overload `vacancy` / `cap_rate` for climate, insurance, or rates. |
| 1.3 | What **grain** (`geo_level_code`) and **time** (`frequency_code`)? | Must exist in **`geo_level`** / **`frequency`**. If Cybersyn `LEVEL` is new, extend **`geo_level.source_snow_cybersyn_level`** and rebuild **`GEOGRAPHY_*`**. |
| 1.4 | Which **vendor** (`vendor_code`) is accountable? | Row in **`vendor.csv`**; **`refresh_cadence`** must resolve to **`frequency`** (use **`varies`** only for true mixed-cadence umbrellas). |

---

## 2. Register in seeds (order)

1. **`dataset`** — one row per **distinct dataset grain** (vendor × concept × geo × frequency × readable `source_schema`).
2. **`metric`** — one row per **published `metric_id`** with `table_path`, `snowflake_column`, `concept_code`, `vendor_code`, `geo_level_code`, `frequency_code`, `metric_category_code`, `unit`, `direction`. **Quote CSV fields** that contain commas.
3. **`bridge_product_type_metric`** — when the metric is **meaningful per product pillar** (SFR vs MF vs BTR); until populated, document applicability in **`dataset.product_type_codes`**.
4. **`metric_derived`** — when the object is a **composite, model output, or estimate** (see `CATALOG_METRIC_DERIVED_LAYOUT.md`).

---

## 3. Wire the pipeline

| Step | Deliverable |
|------|-------------|
| 3.1 | **`FACT_*`** (or delivery view) implements the **`metric_id`** or documents the column → `metric_id` map. |
| 3.2 | **`source()`** in `models/sources/*.yml` matches **`dataset.source_schema`** (no bare FQNs in SQL per `MIGRATION_RULES.md`). |
| 3.3 | **Geography:** joins use **`ref('geography_index')`** / **`geography_latest`**; no silent ZIP↔ZCTA mix (`geo_level` seed). |
| 3.4 | **`dbt seed`** + **`dbt test`** on `path:seeds/reference/catalog`. |

**Enforced in CI (parse + catalog smoke):** GitHub Actions workflow **`.github/workflows/semantic_layer_catalog_and_quality.yml`** runs **`dbt deps` → `dbt parse` → `dbt ls`** for `path:seeds/reference/catalog` on PRs touching catalog/models/seeds. Optional Snowflake job (**`dbt_seed_test_catalog_snowflake`**) is disabled until **`SNOWFLAKE_*`** secrets are set; then flip `if: false` → `if: true` and align **`ci/profiles.yml`** with your auth (password or keypair).

**Local / pre-merge gate:** `scripts/ci/run_catalog_quality_checks.sh` (set **`RUN_SNOWFLAKE_CHECKS=1`** to also run seed, test, and feature compile against your **`DBT_TARGET`**).

---

## 4. Validate in Snowflake

Run:

`scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`

- **0 failures** on catalog FK checks.
- Treat **`GEOGRAPHY_INDEX` `unmapped`** row count as a **crosswalk backlog signal**, not a metric defect.

---

## 5. Log migration

Append **one row** to **`MIGRATION_LOG.md`** Batch History (short) and the same batch id to **`MIGRATION_BATCH_INDEX.md`** (detail + artifact links).
