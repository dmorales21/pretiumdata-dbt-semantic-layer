# Data layers — question each stage answers (PretiumData)

**Audience:** Anyone wiring **SOURCE → TRANSFORM → ANALYTICS → SERVING**, writing dbt in **pretiumdata-dbt-semantic-layer**, or registering **REFERENCE.CATALOG** metrics.

**Binding context:** [ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md) (ownership, `TRANSFORM.DEV` vs `ANALYTICS`), [SCHEMA_RULES.md](../rules/SCHEMA_RULES.md) (prefixes, catalog tokens, promotion gates), [CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md](../reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md) (tall grain + `metric_code`).

### Layer gate — **raw / transform before FACT** (enforced in CI + locally)

**Intent:** Alex **`TRANSFORM.DEV.FACT_*`** read-throughs must not build on unchecked Jon silver.

- **dbt** expresses upstream as **`source()`** (e.g. **`TRANSFORM.BLS.LAUS_*`**). Attach **grain + null + uniqueness** tests on those sources, tag the source with **`pretium_layer_gate_before_fact_dev_readthrough`**, and run **`dbt test --selector layer_gate_before_fact_bls_laus`** before **`dbt run`** on the dependent FACT models.
- **Script (gate only):** [`scripts/ci/dbt_layer_gate_raw_transform_before_facts.sh`](../../scripts/ci/dbt_layer_gate_raw_transform_before_facts.sh) (passes through extra dbt args, e.g. ``--target ci``).
- **Script (gate + build + tests):** [`scripts/ci/dbt_enforce_layer_gate_then_bls_laus_stack.sh`](../../scripts/ci/dbt_enforce_layer_gate_then_bls_laus_stack.sh) — runs layer gate, then **`dbt build`** on **`fact_bls_laus_*`** + **`concept_unemployment_market_monthly`** (model tests run in the same build pass).
- **PR smoke:** `.github/workflows/semantic_layer_catalog_and_quality.yml` compiles that selector (validates test SQL without Snowflake execute). Full test execution still requires a warehouse job; job **`dbt_seed_test_catalog_snowflake`** runs the enforce script after catalog seed when enabled.

**Raw (`SOURCE_PROD` / `RAW`):** same pattern — register sources, add tests, tag for a selector, run that selector before FACT models that read those landings.

---

## Mnemonic — **“Ingest → Parse → Cell → Theme → Pattern → Decide”**

| Stage | One-line question | Pretium “home” (typical) |
|-------|-------------------|---------------------------|
| **Ingest** | Did the file/API land cleanly? | **`RAW.[VENDOR]`**, **`SOURCE_PROD.[VENDOR]`** landings; pipeline volume/drift monitors ([SCHEMA_RULES](../rules/SCHEMA_RULES.md) matrix). |
| **Parse** | Can every consumer read this **without guessing** types, names, grain? | **Jon:** **`TRANSFORM.[VENDOR]`** cleansed tables. **Alex (dev):** typed **`REF_*`** / **`source()`** reads documented in dbt YAML — not census spine ([ARCHITECTURE_RULES § Source vs Transform](../rules/ARCHITECTURE_RULES.md#source-vs-transform-layer-split)). |
| **Cell** | Is there **exactly one comparable number** per natural fact grain? | **`TRANSFORM.DEV.FACT_*`** (`models/transform/dev/**`). Uniqueness at **(time × geo × metric identity × vendor line)** for long tables; wide tables still one business grain per row. |
| **Theme** | Under **`concept_code`**, what are we comparing **across vendors**, with **current / historical / forecast** discipline? | **`TRANSFORM.DEV.CONCEPT_*`** (`models/transform/dev/concept/`). Governed by **`seeds/reference/catalog/concept*.csv`**, domain policy ([CONCEPT_DOMAIN_POLICY.md](../rules/CONCEPT_DOMAIN_POLICY.md)), concept-row approval gate ([ARCHITECTURE_RULES § Concept row governance](../rules/ARCHITECTURE_RULES.md#concept-row-governance-gate)). |
| **Pattern** | What **joinable, testable** structure exists **across** facts/concepts (ranks, spreads, YoY, z-scores)? | **`ANALYTICS.DBT_DEV` / `DBT_STAGE` / `DBT_PROD`** objects prefixed **`FEATURE_*`** (`models/analytics/feature/`). Parent `ref()` to **`CONCEPT_*`** / **`FACT_*`** only — no new vendor truth here. |
| **Decide** | What **cohort**, **scenario**, **horizon**, or **score** ships for UW / IC / serving — with explicit **`run_id` / `scenario_id`** where applicable? | **`MODEL_*`**, **`ESTIMATE_*`** (and legacy **`BI_*`** migration targets per SCHEMA_RULES). **Not** mixed back into **`CONCEPT_*`** rows. |

**Note:** Jon’s future **`TRANSFORM.FACT`** (PROD canonical fact schema) is **out of scope** for Alex-authored dbt until promoted — see [ARCHITECTURE_RULES § TRANSFORM.FACT](../rules/ARCHITECTURE_RULES.md#transformfact).

---

## Layer detail — truth, failures, Pretium practices

### 1 — Raw / land (**Ingest**)

**Truth:** Telemetry on ingestion — row counts, drift vs last run, hard rejects, duplicate file keys.

**Pretium practices**

- **`SOURCE_PROD.[VENDOR]`** — Alex registers sources; **`RAW_*`** in prod landings stay **vendor-native**, not re-typed business facts ([ARCHITECTURE_RULES](../rules/ARCHITECTURE_RULES.md)).
- **Do not** treat raw layout as **`metric_code`**-ready; catalog registration waits on downstream **FACT** gates ([Metric registration gates](../rules/ARCHITECTURE_RULES.md#metric-registration-gates)).

---

### 2 — Vendor cleanse + corridor prep (**Parse**)

**Truth:** **Contract** — column names and types match an agreed contract; identifiers normalized (e.g. **`LPAD(..., 5, '0')`** for **`cbsa_id`**); **grain is explicit** in YAML/docs.

**Pretium practices**

- **Jon-owned** vendor PROD: **`TRANSFORM.[VENDOR]`** — Alex **reads** only.
- **Vendor crosswalks** stay **`TRANSFORM.DEV.REF_*`** until promoted; **never** vendor tables in **`REFERENCE.GEOGRAPHY`** ([ARCHITECTURE_RULES § REF](../rules/ARCHITECTURE_RULES.md)).
- **Census spine** only in **`REFERENCE.GEOGRAPHY`**; **`geo_level_code`** vocabulary from **`REFERENCE.CATALOG`** / seeds — vendor labels like Zillow `metro` → catalog **`cbsa`** ([ARCHITECTURE_RULES § Geo level vocabulary](../rules/ARCHITECTURE_RULES.md#geo-level-vocabulary-alignment)).

---

### 3 — Fact (**Cell**)

**Truth:** **Measurable history** — which **metrics** exist at which **grain**, and **uniqueness** of the fact table’s natural key (plus **`vendor_code`** / **`metric_id`** when tall).

**Pretium practices**

- **`FACT_*`** materialize in **`TRANSFORM.DEV`**; **`dbt_utils.unique_combination_of_columns`** (or equivalent) on declared grain.
- **Spine vs vendor keys (scheduled QA):** e.g. BLS LAUS county FIPS vs **`REFERENCE.GEOGRAPHY.GEOGRAPHY_LATEST`** — light **`fact_semantic_bundle`** on the FACT may omit strict spine joins when a small vendor drift is expected; a **gated** singular test fails when the miss rate reaches **0.1%** or more (tunable var; `tests/bls/assert_fact_bls_laus_county_geography_spine_miss_rate_lt_threshold.sql`, selector **`monthly_geography_spine_qa`**).
- **Tall facts:** series identity via **`METRIC_ID`** (or analogous) — document in **`metric.csv`** **`definition`** / dataset row ([ARCHITECTURE_RULES § Tall-format tables](../rules/ARCHITECTURE_RULES.md#tall-format-tables-eg-zillow)).
- **Multi-vendor “panels”** for apps **do not** belong as extra truth inside **`FACT_*`** — assemble in **`FEATURE_*`** ([ARCHITECTURE_RULES § TRANSFORM.DEV](../rules/ARCHITECTURE_RULES.md)).

---

### 4 — Concept (**Theme**)

**Truth:** **Semantics + motion** — **`concept_code`** from catalog; **vendor unions** under the same rules; **wide slots** today (`*_current`, `*_historical`, `*_forecast` via `concept_metric_slot`) express **comparability**, not raw vendor columns.

**Pretium practices**

- **New `concept.csv` rows** = governance change — explicit approval ([Concept row governance gate](../rules/ARCHITECTURE_RULES.md#concept-row-governance-gate)).
- **Success contracts** for sparse vendors (0 rows PASS when upstream empty or stub) — document in model YAML + [QA_CONCEPT_PREFLIGHT_CHECKLIST.md](../migration/QA_CONCEPT_PREFLIGHT_CHECKLIST.md) §B.
- **Tall migration:** eventual **`metric_code`** FK and grain in [CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md](../reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md); do not silently fold **affordability / burden** into **`rent`** semantics ([ARCHITECTURE_RULES § Metric registry](../rules/ARCHITECTURE_RULES.md#metric-registry--built-metric-vs-backlog-metric_raw)).
- **`metric_derived`** and cross-concept ratios (e.g. rent-to-income) stay **out** of wide concept slots unless explicitly designed as a derived mart.

---

### 5 — Feature (**Pattern**)

**Truth:** **Structure across** facts/concepts — joins, rollups, cohort windows, ranks — still **testable against parents** (`ref('concept_*')`, `ref('fact_*')`).

**Pretium practices**

- Prefix **`FEATURE_*`** under **`ANALYTICS.DBT_*`** per [SCHEMA_RULES](../rules/SCHEMA_RULES.md); read **`TRANSFORM.DEV`** concepts/facts via **`ref()`** — **no** `FACT_*` / `CONCEPT_*` authored under **`ANALYTICS`** ([ARCHITECTURE_RULES § schema ownership](../rules/ARCHITECTURE_RULES.md#schema-ownership-boundaries)).
- **Catalog-driven** feature waves: [PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md); parity / spine tests live with feature YAML + `tests/`.
- **Declarable transforms** (log, ratio, zscore, lags) preferred in registry YAML where the project uses them — **residuals / composites** need **`metric_derived_id`** + version metadata (see analytics-engine **`CONCEPT_MART_MATHEMATICAL_FEATURES`** if mirrored internally).

---

### 6 — Model / estimate (**Decide**)

**Truth:** **Decision objects** — cohort inclusion, same-store rules, **forecast horizon**, **scenario**, pairing **UW vs actual** — never ad hoc mixed into **`CONCEPT_*`** as if they were vendor observations.

**Pretium practices**

- **`MODEL_*`**, **`ESTIMATE_*`** on **`ANALYTICS`**; promotion blocked until **`ANALYTICS.DBT_STAGE.QA_*`** is clean for governed gates ([SCHEMA_RULES enforcement §5](../rules/SCHEMA_RULES.md#enforcement-rules)).
- **SERVING.DEMO** — dev/demo delivery only; **PROD must not read SERVING.DEMO** ([SCHEMA_RULES §6](../rules/SCHEMA_RULES.md#enforcement-rules), [SERVING_DEMO_ICEBERG_TARGETS.md](../reference/SERVING_DEMO_ICEBERG_TARGETS.md)).

---

## dbt tests and auto QA by layer (PretiumData checklist)

**Recommendations source:** In the **analytics-engine** repo, `docs/guides/DATA_LAYER_QUESTIONS_BY_PIPELINE_STAGE.md` **§8** (*dbt tests and auto QA by layer*) lists test **types** (freshness, uniqueness, relationships, custom SQL, orchestration, optional packages). This section **does not copy Presley** wholesale; it maps that menu onto **this** semantic-layer repo and marks **done vs backlog**.

**Mnemonic crosswalk (Presley “ISATPD” ↔ PretiumData “Ingest → … → Decide”):**

| analytics-engine §8 | PretiumData stage (this guide) |
|---------------------|--------------------------------|
| **Raw** | **Ingest** — `SOURCE_PROD` / `RAW` landings |
| **Transform** | **Parse** — Jon **`TRANSFORM.[VENDOR]`** silver read as **`source()`** |
| **Fact** | **Cell** — **`TRANSFORM.DEV.FACT_*`** |
| **Concept** | **Theme** — **`TRANSFORM.DEV.CONCEPT_*`** |
| **Feature** | **Pattern** — **`ANALYTICS…FEATURE_*`** |
| **Model / estimate** | **Decide** — **`MODEL_*`**, **`ESTIMATE_*`** |

### Ingest (Raw) — “Did it land cleanly?”

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **`source` freshness** (`loaded_at_field`, `warn_after` / `error_after`) | Staleness visible before FACT build | **Backlog** — add when landings expose a reliable timestamp column. |
| **Orchestrator SLA** (Airflow/Dagster/etc.) | Hard fail if extract incomplete | **Outside dbt** — document in runbooks; do not pretend `dbt run` replaces it. |
| **Row-count / byte drift vs prior** | Volume spike or empty file | **Backlog** — custom test or observability; optional per-`source()`. |
| **`not_null`** on minimal identity | Every row quarantine/replay addressable | Apply on **`SOURCE_PROD`** / **`RAW`** sources when grain keys exist in YAML. |
| **`unique`** on natural load key | Duplicates do not multiply downstream | Apply where vendor batch / file key is stable. |
| **PII / secret scan** | No credentials in repo | **CI policy** (existing org standards). |

### Parse (Transform) — “Is the contract parseable?”

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **`not_null`** on join keys used downstream (`DATE_REFERENCE`, `COUNTY_FIPS`, …) | No silent drops at promote-to-fact | **Done (pilot):** **`source('bls_transform','laus_*')`** — extend to other Jon silver **`source()`** parents. |
| **`dbt_utils.unique_combination_of_columns`** on declared silver grain | One row per intended fact cell | **Done (pilot):** LAUS county / CBSA sources. |
| **`accepted_values`** / **`relationships`** to seeds or **`ref('geography_latest')`** | Enum / spine drift | **Backlog** on sources (e.g. `measure_code` domain); **scheduled** spine miss-rate singular test for LAUS county (`tests/bls/assert_fact_bls_laus_county_geography_spine_miss_rate_lt_threshold.sql`). |
| **`dbt_utils.expression_is_true`** (LPAD width, no future dates, TRY_CAST safety) | Identifier + time sanity | **Partial:** FACT-level bounds on LAUS; add **source**-level expressions as contracts firm up. |
| **Layer gate before FACT** | Do not build **`FACT_*`** on unchecked silver | **Done:** selector **`layer_gate_before_fact_bls_laus`**, scripts [`dbt_layer_gate_raw_transform_before_facts.sh`](../../scripts/ci/dbt_layer_gate_raw_transform_before_facts.sh) / [`dbt_enforce_layer_gate_then_bls_laus_stack.sh`](../../scripts/ci/dbt_enforce_layer_gate_then_bls_laus_stack.sh), CI **`dbt compile`** on gate (parse job) + enforce script in Snowflake job when enabled. |

### Cell (Fact) — “One number per cell?”

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **`unique_combination_of_columns`** on fact grain | Core fact contract | **Partial** — e.g. LAUS, FHFA, HUD monthly aliases; extend per FACT family. |
| **`not_null`** on grain + measure columns | No half-keys | Column tests in `schema.yml` where adopted. |
| **`fact_semantic_bundle`** | Null geo/date, future dates, optional spine join | **Partial** — HUD, FHFA, Freddie, BLS LAUS; roll forward per `models/transform/dev/**/schema.yml`. |
| **Range / bounds** (`expression_is_true`, **`assert_metric_bounds_registered_in_catalog`**) | Screening for impossible magnitudes | **Partial** — catalog singular for **MET_*** bounds; FACT **`expression_is_true`** on LAUS. |
| **`dbt_utils.equal_rowcount`** vs upstream | Read-through parity | **Partial** — e.g. CoStar pattern; use where FACT is strict read-through. |
| **Volume by vendor × month (custom)** | Sudden disappearance of a line | **Backlog** — add where IC cares (high-value vendors). |

### Theme (Concept) — “What semantics + slots?”

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **`not_null`**, **`accepted_values`** on `concept_code`, `geo_level_code`, spine keys | Stable Presley / IC keys | **Done** on many **`concept_*_market_*`** in `models/transform/dev/concept/schema.yml`. |
| **`unique`** on concept mart grain (month × geo × vendor line × `metric_id_observe` where applicable) | No duplicate “current” rows | **Partial** — e.g. **`concept_unemployment_market_monthly`**; extend per concept. |
| **`relationships`** / QA views to **`ref('geography_latest')`** | Orphan geo | **`qa_geography_referential_integrity`**, join audits. |
| **Vendor allowlist** (singular) | No stray vendor lines in governed concepts | **`tests/concept_corridor/assert_concept_*_vendor_allowlist.sql`** (extend list). |
| **Slot / forecast rules** (`expression_is_true`) | Forecast path only when columns set | **Backlog** — add per concept YAML when rules freeze. |

### Pattern (Feature) — “Testable vs parents?”

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **`relationships`** / spine tests to **`ref('concept_*')`**, **`ref('fact_*')`** | Every feature row has a parent | **Partial** — feature YAML + rent spine parity tests where wired. |
| **`unique`** on feature grain | Idempotent builds | **Partial** — per feature `schema.yml`. |
| **Window / leakage** (custom SQL or script) | No future data in train windows | **CI:** `scripts/ci/check_feature_window_leakage.sh`. |
| **`expression_is_true`** (lags, finite z-scores) | Broken join detection | **Backlog** — add per high-risk FEATURE. |

### Decide (Model / estimate) — “Cohort / scenario / horizon?”

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **`not_null`** / **`unique`** on `run_id`, `scenario_id`, cohort keys where modeled | Reproducible decision objects | **Apply when** `MODEL_*` / `ESTIMATE_*` ship in this repo; many stacks still upstream. |
| **No model outputs merged into `CONCEPT_*`** | ISATPD / layer separation | **Policy** in [ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md); enforce with **`expression_is_true`** when risk appears. |
| **Calibration / drift (Python or NB)** | Quality gate before promote | **Outside dbt** or **Backlog** — not a substitute for economic review. |

### Cross-layer smoke (after build)

| Test / check | Purpose | PretiumData today |
|--------------|---------|-------------------|
| **Golden path** (one batch → FACT `metric_code` → CONCEPT → FEATURE → MODEL) | Audit story | **Backlog** — document in a runbook + optional singular SQL. |
| **Catalog ↔ graph** (metric `table_path`, seeds) | Drift between registry and dbt | **`scripts/sql/validation/`**, seed tests on **`path:seeds/reference/catalog`**. |

---

## Quick matrix (copy-friendly)

| Layer | Primary question | dbt / Snowflake anchor (Alex dev path) |
|-------|------------------|----------------------------------------|
| Raw | Landed cleanly? | `source('…')` → **`SOURCE_PROD`** / **`RAW`** |
| Parse | Typed & grain-clear? | **`TRANSFORM.[VENDOR]`** (Jon) + **`REF_*`** / YAML on reads |
| Fact | One cell per grain? | **`models/transform/dev/**`** → **`TRANSFORM.DEV.FACT_*`** |
| Theme | Comparable under `concept_code`? | **`models/transform/dev/concept/**`** → **`TRANSFORM.DEV.CONCEPT_*`** |
| Pattern | Testable derivation? | **`models/analytics/feature/**`** → **`ANALYTICS…FEATURE_*`** |
| Decide | Cohort / scenario / horizon explicit? | **`MODEL_*`**, **`ESTIMATE_*`** → **`ANALYTICS…`** |

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial PretiumData-specific guide: mnemonic, schema anchors, pointers to ARCHITECTURE / SCHEMA / tall contract / QA preflight. |
| **0.2** | Fact layer: LAUS county FIPS spine miss-rate singular test + **`monthly_geography_spine_qa`** selector (gated var). |
| **0.3** | Layer gate: **TRANSFORM.BLS** source tests + selector **`layer_gate_before_fact_bls_laus`**, CI compile, script **`dbt_layer_gate_raw_transform_before_facts.sh`**. |
| **0.4** | **§ dbt tests and auto QA by layer:** checklist mapped from analytics-engine §8; Pretium **done / partial / backlog** columns. |
| **0.5** | **`dbt_enforce_layer_gate_then_bls_laus_stack.sh`:** gate → **`dbt build`** (LAUS FACT + unemployment concept + tests); Snowflake CI job step when enabled. |
