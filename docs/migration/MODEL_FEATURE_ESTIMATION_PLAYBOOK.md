# Model stack — features, estimation, and data prep (consolidated)

**Owner:** Alex  
**Status:** canonical playbook (start of consolidation). **Supersedes scattered “how to prep data for analytics” notes** by centralizing layer rules, estimation semantics, corridor/cluster prep, and **structural unemployment / automation risk** in one index.

**Related (read in this order):**

| Topic | Document |
|-------|----------|
| **`FACT_*` waves + per-model checklist** | [MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md](./MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md) |
| **Layer contract (five targets)** | [MIGRATION_RULES.md](./MIGRATION_RULES.md) |
| **Effective rent → `FEATURE_*` / `MODEL_*` / `ESTIMATE_*` SQL stages** | [MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md](./MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md) |
| **Corridor = competitive submarket clustering (pretium-ai-dbt)** | `pretium-ai-dbt` [CORRIDOR_CREATION_METHODOLOGY.md](../../../pretium-ai-dbt/docs/governance/CORRIDOR_CREATION_METHODOLOGY.md), [CORRIDOR_SUBMARKET_REDESIGN_DIRECTIVE.md](../../../pretium-ai-dbt/docs/governance/CORRIDOR_SUBMARKET_REDESIGN_DIRECTIVE.md) |
| **O*NET / QCEW / Epoch → county AI risk (legacy repo, migration source)** | `pretium-ai-dbt` [AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md](../../../pretium-ai-dbt/docs/governance/AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md) |

**Canonical rule:** closures and new models land in **this** repo per [CANONICAL_COMPLETION_DEFINITION.md](./CANONICAL_COMPLETION_DEFINITION.md). pretium-ai-dbt paths above are **reference lineage** until ported to `models/transform/dev`, `models/analytics/*`, and `models/mart/semantic/*` here.

---

## 1. Concepts vs features vs models vs estimates (definitions)

| Object | Role | What is “true” here? |
|--------|------|----------------------|
| **`concept_*`** | Domain composition: normalized panels, rent market unions, lease spines — **definitions** of quantities (e.g. “market rent for CBSA×month×vendor slot”). | **Observable or vendor-defined** series at agreed grain; **no** portfolio deciles or ML scores in this layer unless purely structural. Physical home: **`TRANSFORM.DEV`** and/or **`MART_*`.`SEMANTIC`** per project layout — **`ref()`** from analytics must match the built relation. |
| **`feature_*`** | **Pre-baked** geometry-safe, cohort-safe metrics: effective rent, z-scores, rolling stats, gating counts, county automation exposure, hex-level gravity. | **Deterministic SQL** from `FACT_*` / `concept_*` / `REFERENCE.GEOGRAPHY`. Version by model name or `alias` if logic changes. |
| **`model_*`** | **Scoring, sort keys, tiers, deciles**, bivariate blends (e.g. dual AI-risk index), corridor membership consumption. | **Ordinal / bounded indices** with documented weights; suitable for ranking and UI. |
| **`estimate_*`** | **Forward or missing-value inference**: forecasts, intervals, imputation, scenario paths. | **Stated algorithm + horizon + calibration target** (see §4). Not the same as a **concept** table that only **describes** a market; an estimate **projects** a value under uncertainty. |

**One-line distinction:** **Concept** = *what we measure or compose*; **Estimate** = *what we predict or fill in*, with explicit **goal**, **horizon**, and **method**.

---

## 2. Data prep for success (feature engineering + ML-ready pipelines)

### 2.1 Universal prep (all stacks)

1. **Grain lock** — Primary keys documented in `schema.yml`; join never widens grain silently (e.g. county fact × tract ACS without population weighting).
2. **Time alignment** — `date_trunc` to month/quarter consistently; **as-of** semantics for snapshots; **vintage_year** for LODES and similar.
3. **Geo discipline** — Map through `REFERENCE.GEOGRAPHY` / catalog `geo_level`; no raw vendor geo strings on published columns.
4. **Variance / flatness gates** — For clustering or z-scores: drop or flag columns **constant within CBSA** (or parent cohort) so ML does not learn metro-only gradients (see corridor directive).
5. **Residualization (optional)** — For lateral submarkets: levels minus CBSA (or stratum) mean, or ratios to parent geo, **before** Ward / k-means.
6. **Winsorize + scale** — By CBSA×cohort for hex-level clustering; document percentiles.
7. **Train–serve parity** — Same SQL models in Snowflake for batch scoring; Python corridor pipeline reads **materialized** spine columns aligned with `CLUSTER_SIGNALS`.
8. **Leakage** — No future-month rent in features for month-*t* targets; no post-assignment outcomes in corridor cluster inputs unless explicitly lagged.

### 2.2 Corridor / submarket pipeline (spatial ML)

- **Spine first:** `(cbsa_id, h3_r8_hex)` universe from `REFERENCE` polyfill or stock footprint; then LEFT JOIN facts (methodology doc §4.2 order).
- **Signal dominance:** Prefer **rent, absorption, DOM, supply, concessions** (when local) over raw density and broad income for **competitive** merging; keep **urbanity** as a **separate layer** if needed.
- **Topology last:** Contiguity merge/smoothing **after** signal clustering — geography repairs labels; it does not define substitution.

### 2.3 Tabular rent / UW stack (Snowflake SQL “ML”)

- **Sparse cohorts** — Expose `cohort_n`; suppress z-scores when below *k*; ZIP → CBSA fallback documented in `FEATURE_*` YAML.
- **Product stratification** — Separate feature columns or separate runs for MF vs SFR/BTR where economics differ.

---

## 3. Structural unemployment / automation risk in the model stack

**Business meaning:** Exposure of a **geography’s employment mix** to **task automation and AI capability** (O*NET / Epoch-style exposure) combined with **industry mix** (QCEW / NAICS employment), aggregated to **county × `date_reference`**, optionally blended with other labor indices in future.

**Current lineage (pretium-ai-dbt — migrate here):**

| Stage | Example object | Layer |
|-------|------------------|--------|
| Raw / cleaned O*NET, QCEW, crosswalks | `cleaned_onet_soc_ai_exposure`, `cleaned_qcew_county_naics`, `fact_county_soc_employment` | **`TRANSFORM.DEV`** / cleanse |
| County replacement risk fact | `fact_county_ai_replacement_risk` | **`TRANSFORM.DEV`** `FACT_*` |
| CBSA NAICS features | `feature_ai_replacement_risk_cbsa` | **`ANALYTICS.DBT_DEV`** `FEATURE_*` |
| County allocation | `feature_ai_replacement_risk_county` | **`FEATURE_*`**
| Structural unemployment label | `feature_structural_unemployment_risk_county` (tier: HIGH/MEDIUM/LOW from score cutoffs) | **`FEATURE_*`**
| Combined county fact / dual index | `fact_county_ai_automation_risk`, `model_county_ai_risk_dual_index` | **`MODEL_*`** / **`FACT_*`** |

**Stack placement:** Treat **structural unemployment risk** as a **`FEATURE_*`** (continuous score + optional tier) feeding **`MODEL_*`** (indices, deciles, sorts) and **IC / corridor demand** context — **not** an `ESTIMATE_*` unless you explicitly add a **forecast** of future risk (then document horizon in §4).

**Migration goal (canonical):** Port the chain above into **`pretiumdata_dbt_semantic_layer`** with `var('onet_soc_naics_enabled')` parity, **`REFERENCE.CATALOG`** **`metric_derived`** (and optional **`metric`** for base columns) for published analytics outputs, and tests on county FIPS and date grain. Task: **`T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK`** in `MIGRATION_TASKS.md`.

**Implemented FACT / ref landing in this repo (county replacement risk spine):** see [LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md](./LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md) (QCEW fact, O*NET/Epoch facts, `REF_ONET_SOC_TO_NAICS` vendor ref, `fact_county_soc_employment`, `fact_county_ai_replacement_risk`, parity tests, geography sources).

**Data prep notes specific to this stack:**

- Enable **`onet_soc_naics_enabled`** only when O*NET + QCEW + crosswalk seeds/sources are present; otherwise emit **empty guarded** relations so downstream does not break (pattern in legacy `feature_structural_unemployment_risk_county`).
- **Employment weights** — CBSA NAICS → county allocation must use **documented** county–CBSA bridge (e.g. canon xwalk); document many-to-one counties.
- **Epoch / taxonomy versions** — Pin **ref table versions** or seed hashes in model `meta` for reproducibility.

---

## 4. Estimation — goals, values, and methods (clear contract)

Use this template **per `estimate_*` model** (and for any Python forecast that claims parity).

### 4.1 Estimation goal (required)

| Field | Content |
|-------|---------|
| **Target concept** | Registry `concept_code` + column(s) being predicted (e.g. `effective_rent_monthly`, `market_rent_median`). |
| **Prediction object** | Grain: e.g. `(property_id, month)`, `(cbsa_id, product_type, month)`, `(county_fips, quarter)`. |
| **Horizon** | e.g. *h* = 1..6 months forward, or next quarter only. |
| **Loss / calibration** | e.g. minimize RMSE on holdout last *N* months; or MAPE on level; **report** backtest window in YAML. |
| **Uncertainty** | Point-only vs **interval** (e.g. 80% PI via residual bootstrap or analytic formula). |

### 4.2 Values produced (required)

| Output | Meaning |
|--------|---------|
| `estimate_*` point | Default forecast for the grain. |
| `estimate_*_p10`, `*_p90` (if used) | Lower/upper interval bounds. |
| `estimate_*_method` | Enum: `rolling_ols`, `ets`, `snowflake_ml`, `naive_drift`, etc. |
| `estimate_*_as_of` | Training cutoff timestamp for serve-time debugging. |

### 4.3 Methods (allowed catalog — extend with PR)

| Method | When to use | Snowflake pattern |
|--------|-------------|---------------------|
| **Rolling OLS / trend** | Smooth short-horizon rent | `REGR_SLOPE` / `REGR_INTERCEPT` over last *N* periods in window |
| **Seasonal naive + drift** | Sparse series | Lag-12 + level adjustment |
| **Ratio to parent** | Small-N geo | Forecast parent CBSA × child / parent historical ratio |
| **Snowflake ML** | Account policy allows | Document model type and feature list in YAML |

**Non-goals:** Do not implement **concept composition** inside `ESTIMATE_*`; that belongs in **`CONCEPT_*`**. Do not store **training labels** as if they were estimates.

---

## 5. Playbook consolidation roadmap (next merges)

1. Keep **`MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md`** focused on **`FACT_*` / Wave A–G** checklist; link **here** for analytics semantics.  
2. **`MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md`** stays the detailed rent DAG; **§4** of this file is the **general estimation** contract for all domains.  
3. **Corridor** methodology remains in pretium-ai-dbt until corridor facts/features are ported; then add a **“Corridor wave”** subsection under §2 and a **`T-CORRIDOR-*`** pointer only in `MIGRATION_TASKS.md`.  
4. **AI / structural unemployment** — migrate lineage §3; retire duplicate prose in scattered governance files by replacing with links **to this doc** (incremental PRs).

---

## 6. Quick checklist — “is this model in the right layer?”

- [ ] Vendor long / EAV → **`FACT_*`** (`TRANSFORM.DEV`).  
- [ ] Composed panel / rent union without scores → **`CONCEPT_*`**.  
- [ ] Z-score, rolling median, cohort *n*, county risk score → **`FEATURE_*`** (`ANALYTICS.DBT_DEV`).  
- [ ] Decile, sort_key, tier, blended index → **`MODEL_*`**.  
- [ ] Forward value + documented horizon + method → **`ESTIMATE_*`**.  
- [ ] Catalog: **`metric_derived.csv`** for each logical **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** output; **`metric.csv`** + **`dataset`** rows for warehouse measures; **`bridge_product_type_metric`** when product-specific.
