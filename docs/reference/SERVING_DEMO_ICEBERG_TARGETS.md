# `SERVING.DEMO` — dev delivery matrix, Iceberg targets, and gaps

**Canonical contract:** [`docs/rules/SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) (matrix + enforcement). **This repository** (`pretiumdata-dbt-semantic-layer`) is the **canonical dbt home** for `TRANSFORM.DEV` facts/concepts, `REFERENCE.CATALOG`, `ANALYTICS.DBT_*`, and the **Alex** `SERVING.DEMO` rows.

**Supporting / utility work** (heavy analytics corridors, legacy SnowSQL, geography Parquet loads, operational scripts) may live in **`pretium-ai-dbt`** until migrated — do **not** treat that repo as the source of truth for `SERVING` naming or catalog governance.

---

## Matrix intent (Alex `SERVING.DEMO`)

Aligned with **SCHEMA_RULES** rows **81–83**:

| Row | Purpose | Object type (matrix) | Reads from (logical) |
|-----|---------|----------------------|----------------------|
| **81** | Dev embeddings | **Parquet** | **`ANALYTICS.DBT_DEV`** — `AI_*` / `FEATURE_*` / `MODEL_*` |
| **82** | Dev synthesis | **Iceberg** | Same analytics objects |
| **83** | Dev “mart” data | **Iceberg** | **`TRANSFORM.CONCEPT` → `TRANSFORM.FACT` → `TRANSFORM.DEV`** (in practice: semantic **`concept_*`** that unions those facts) |

**Enforcement §6** ([`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md)): **`SERVING.DEMO` is dev-only** — **no PROD object may read `SERVING.DEMO`**.

---

## Physical naming note (`SERVING.DEMO.MART`)

In the matrix, **`SERVING` / `DEMO` / `MART`** are **database / schema / table-prefix family** (Alex delivery under **`.DEMO`** with **MART** in the object-type column), not a nested Snowflake schema named `MART`. Physical relations are typically **`SERVING.DEMO.<TABLE>`** (optionally prefix **`demo_`** or **`MART_`-style** names for alignment with playbook language).

---

## Proposed `SERVING.DEMO` surfaces (Iceberg-first) and upstream reads

Small, analyst-friendly slices that **already exist in this repo’s dbt graph** and align with **`metric_derived`** / semantic mart intent. Upstream Snowflake names follow target resolution (**`MART_{env}.SEMANTIC.*`**, **`ANALYTICS.DBT_DEV.*`** — mart database is profile/target-dependent; validation scripts often use **`MART_DEV.SEMANTIC`**).

| Proposed logical name | Matrix style | Reads from today (Snowflake / dbt) | Why |
|----------------------|--------------|--------------------------------------|-----|
| **`demo_concept_rent_market_monthly`** | Row **83** (dev mart data) | **`TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY`** via dbt `ref('concept_rent_market_monthly')` — `models/transform/dev/concept/concept_rent_market_monthly.sql` | Canonical market-rent union in semantic-layer **TRANSFORM**; thin `demo_*` pass-through for **`SERVING.DEMO`**. |
| **`demo_feature_rent_market_monthly`** | Row **82** (thin duplicate OK) | **`ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY`** (dbt model `feature_rent_market_monthly_spine` with `alias='feature_rent_market_monthly'`) → **`concept_rent_market_monthly`** | Stable **FEATURE_** grain for notebooks; **MDV_001** story. |
| **`demo_feature_listings_velocity_monthly`** | Row **82** | **`ANALYTICS.DBT_DEV.FEATURE_LISTINGS_VELOCITY_MONTHLY`** (`feature_listings_velocity_monthly_spine`) → Zillow DOM + for-sale listings facts | **MDV_004**; **MET_042** / **MET_043** read surface. |
| **`demo_mart_county_ai_automation_risk`** | Row **83** | **`TRANSFORM.DEV.FACT_COUNTY_AI_AUTOMATION_RISK`** — `models/transform/dev/entity/fact_county_ai_automation_risk.sql` | Small county table; labor + AIGE demo. |
| **`demo_model_county_ai_risk_dual_index`** | Row **82** (synthesis-style output) | **`ANALYTICS.DBT_DEV.MODEL_COUNTY_AI_RISK_DUAL_INDEX`** — `models/analytics/model/model_county_ai_risk_dual_index.sql` ← **`feature_ai_risk_county_bivariate`** ← **`fact_county_ai_replacement_risk`** (+ O\*NET / QCEW facts) | County-grain model output. |
| **`demo_catalog_bridge_pack`** | Supporting (vocabulary) | **`REFERENCE.CATALOG`** seeds as tables: e.g. **`product_type`**, **`metric`**, **`bridge_product_type_metric`**, optionally **`metric_derived`**, **`concept`** | Lets lake consumers **join on codes** without ad hoc Snowflake catalog queries. |

### Row **81** (embeddings → Parquet)

Add **`SERVING.DEMO`** **Parquet** only when there are real **embedding** (or vector **ESTIMATE_** / **`AI_*`**) tables in **`ANALYTICS.DBT_DEV`**. **This repo does not currently ship a dedicated embedding store** in the Alex analytics tree — treat embeddings as **future** unless ported from another system.

### Rows **84–85** (`COLLECTION` / `EXPORT`)

Defer until **`collection_name`** (and export consumer) contracts exist and jobs are defined — not required for a first Iceberg demo slice.

---

## Release bundle + Iceberg gates (this repo)

**Runbook (minimal `dbt` selectors, replication SQL, release pin):** [`../runbooks/SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md`](../runbooks/SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md).

## Gaps / follow-ups

| Gap | Detail |
|-----|--------|
| **`SERVING.DEMO` FQN** | All **`models/serving/demo/*`** inherit **`+database`** / **`+schema`** from **`dbt_project.yml`** → **`models.pretiumdata_dbt_semantic_layer.serving.demo`** (**`vars.serving_database`** default **`SERVING`**, schema **`DEMO`**). Override the var if your warehouse uses a different database name. |
| **No Iceberg / external volume definitions in this repo** | Managed Iceberg (Snowflake or Polaris + S3) needs **external volume**, **catalog**, **stage**, and usually **tasks** or a **sync job** — not implemented as dbt/SQL assets here today. |
| **No replication dbt pattern** | Thin **`CREATE ICEBERG TABLE … AS SELECT`** (or export to `pret-iceberg` + REST catalog) is **not** wired in CI. [DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md](./DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md) describes **what** to publish to the share, not **how** to replicate to Iceberg. |
| **Embeddings path (row 81)** | No **`AI_*`** embedding outputs identified for Parquet landing in **`SERVING.DEMO`**. |
| **§1 catalog tokens** | New **`SERVING.DEMO`** relation names still need **`REFERENCE.CATALOG`** support for **`[concept]`**, **`[geo_level]`**, **`[frequency]`**, etc., before they are fully governed (per **§1**). |

---

## Practical first slice

If you land **two** Iceberg tables in **`SERVING.DEMO`** first:

1. **`demo_concept_rent_market_monthly`** (from **semantic mart `concept_rent_market_monthly`**), and  
2. **`demo_catalog_bridge_pack`** (from **`REFERENCE.CATALOG`** P0 tables),

you get **market truth + vocabulary** for lake consumers with minimal moving parts. Add **`demo_mart_county_ai_automation_risk`** + **`demo_model_county_ai_risk_dual_index`** when labor demo traffic matters.

---

## Related docs

- [SNOWFLAKE_ICEBERG_EXPORT_DUCKDB_BEST_PRACTICES.md](./SNOWFLAKE_ICEBERG_EXPORT_DUCKDB_BEST_PRACTICES.md) — **Snowflake Iceberg / Parquet export** tuning for **DuckDB** pushdown (`SERVING.DEMO`, `SERVING.ICEBERG`)  
- [SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md](../runbooks/SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md) — **release bundle** `dbt` selectors, replication readiness SQL, release pin checklist  
- [DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md](./DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md) — P0 catalog inventory and Duck Lake / share targets  
- [SERVING_DEMO_METRICS_CATALOG_MAP.md](./SERVING_DEMO_METRICS_CATALOG_MAP.md) — first metrics / feature population list vs `metric` / `metric_derived`  
- [PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md](./PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md) — cost framing, Snowflake vs Polaris catalog  
- [README.md](../../README.md) — `SERVING.DEMO` note and Spencer-owned **`SERVING.MART`** / **`COLLECTION`** / **`EXPORT`** still in **`pretium-ai-dbt`** until migrated
