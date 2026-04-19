# Playbook — analytics features from catalog

**Owner:** Alex (catalog + concept semantics); consuming teams co-own **(b)** when breaking.  
**Canonical repo:** pretiumdata-dbt-semantic-layer (`docs/migration/`). **pretium-ai-dbt** links here; do not fork this playbook.

**Purpose:** One place for **catalog row → FACT/CONCEPT → feature SQL → tests → registration**, plus **market selection substance**, **four-chain** alignment to pretium-ai-dbt guides, and **operational** gates (ownership, env, CI, rollback).

---

## §0 — Ownership and approval matrix

| Gate | Approver | Artifact |
|------|----------|----------|
| (a) New **`metric_derived`** row | Alex | PR: `metric_derived.csv` + `schema_metric_derived.yml` |
| (b) New **`feature_*`** physical object in **`ANALYTICS.DBT_DEV`** | Alex + consuming team if breaking | PR: model + tests + grain / content packet |
| (c) **Layout doc** vs **actual seed** (SIGNALS / MODELS) | Alex | Layout merge ≠ seed merge until explicit “seed OK” |
| (d) **Breaking grain** / rename | Alex + ADR ([ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md](./ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md)) | New `metric_derived_code` or version suffix; deprecation; `MIGRATION_LOG` short row + `MIGRATION_BATCH_INDEX` detail |
| (e) New **`CONCEPT_*` contract** (grain tuple, vendor precedence, measure family) | Alex | PR: concept SQL + YAML **`meta.parent_facts`** + playbook row |

---

## §A — Scope and physical routing

- **Reads:** `TRANSFORM.DEV` **`FACT_*`**, **`CONCEPT_*`** in mart semantic, `REFERENCE.*`.  
- **Writes (physical):** **`ANALYTICS.DBT_DEV`** for **TABLE/INCREMENTAL** `feature_*` / `model_*` / `estimate_*` when **`analytics_dbt_dev_physical: true`** in pretium-ai-dbt (see [generate_schema_name.sql](../../../../pretium-ai-dbt/dbt/macros/generate_schema_name.sql) in a sibling **pretium-ai-dbt** clone under the same parent folder as this repo).  
- **REFERENCE.CATALOG** seeds are SoT for **`metric`** / **`metric_derived`** in this repo.

---

## §B — Environment and promotion

- **Targets:** Document per env which **`dbt target`** runs **`dbt seed`** for `REFERENCE.CATALOG` vs which builds **analytics** models.  
- **REFERENCE sharing:** State whether **`REFERENCE.CATALOG`** is shared across Snowflake accounts/envs or branched.  
- **Promotion:** Who runs `dbt build` for analytics subgraph before merge vs prod; **backfill / full-refresh** owner + warehouse cost guardrails for large incrementals.

---

## §C — Lineage and observability

- **dbt exposures** (or `meta`) for downstream: Presley, BI, scorecard — link **feature model → `metric_derived_id`**.  
- **Freshness:** Per-vendor or per-feature expected refresh in YAML **`meta`** or ops table.  
- **Alerting:** Wire CI failure on catalog seeds; optional vendor drift alerts (TODO if not wired).

---

## §D — Registration order and rollback

1. Merge **`metric_derived`** (and **`metric`** if needed) **before** or **same PR** as the model that documents it.  
2. **CI order:** `dbt seed` (catalog slice) → `dbt test --select metric_derived` (or path) → `dbt compile` / `dbt build` on feature subgraph. **Enforced today:** workflow **`semantic_layer_catalog_and_quality`** (`.github/workflows/semantic_layer_catalog_and_quality.yml`) — **`dbt parse`** + catalog **`dbt ls`** smoke on qualifying PRs; optional Snowflake **`dbt seed` / `dbt test` / `dbt compile`** job is in that file (off until **`SNOWFLAKE_*`** secrets are wired). Local mirror: **`scripts/ci/run_catalog_quality_checks.sh`**.  
3. **Rollback:** Prefer **single PR** reverting CSV + model + tests. If two-step: revert **model** first to avoid readers hitting orphan catalog semantics.

---

## §E — Pilot A (measurable exit criteria)

Use **rent market spine** as default Pilot A vendor cluster (`concept_rent_market_monthly` → `feature_rent_market_monthly_spine`).

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | One vendor cluster chosen | This section + `MIGRATION_LOG` / batch index if batch logged |
| 2 | **FACT → CONCEPT → FEATURE** path | `FACT_*` feed concept; `models/analytics/feature/feature_rent_market_monthly_spine.sql` **`ref('concept_rent_market_monthly')`** only |
| 3 | **`metric_derived`** | Existing **MDV_001** `rent_market_monthly_spine` or new row if net-new artifact |
| 4 | **Tests green** | `dbt test --select metric_derived` + model tests on spine |
| 5 | **Reconciliation Q** | Run [feature_rent_market_spine_vs_concept_reconciliation.sql](../../scripts/sql/validation/feature_rent_market_spine_vs_concept_reconciliation.sql); **tolerance T = 0** row-count delta for pass-through spine (document other T if logic diverges) |
| 6 | **Concept YAML `meta`** | Parent **`FACT_*`** / upstream marts listed for migration audit |

### Pilot A — operator commands (semantic-layer inner project)

```bash
cd pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
dbt seed --target reference --select reference.catalog.metric_derived
dbt test --target reference --select metric_derived
dbt compile --select path:models/analytics/feature
```

**CI:** Workflow **`semantic_layer_catalog_and_quality.yml`** enforces **`dbt parse`** + catalog seed resolution; enable the Snowflake block in that workflow (and secrets) to enforce the three **`dbt`** lines above on PRs touching seeds/models.

---

## §F — SQL macros and DRY

- Shared invariants (**null denom → null**, z-score windows, spine joins): **`macros/semantic/`** or agreed **`macros/analytics/`** — one implementation; exceptions documented in PR.  
- **Parity:** If Python elsewhere implements the same transform, one SoT wins or add a **diff test**.

---

## §G — PII and access

- Default **rolled-up** grain in `feature_*`; no unit-level PII without explicit approval + tagging.  
- Document who may read **`ANALYTICS.DBT_DEV`** vs raw vendor objects.

---

## §H — Outbound index (dependencies)

| Need | Path |
|------|------|
| Schema routing | pretium-ai-dbt `dbt/macros/generate_schema_name.sql`, `dbt_project.yml` **`analytics_dbt_dev_physical`** |
| **`metric_derived` tests** | `seeds/reference/catalog/schema_metric_derived.yml` |
| Seed order | [../CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md) |
| Metric intake | [METRIC_INTAKE_CHECKLIST.md](./METRIC_INTAKE_CHECKLIST.md) |
| Vendor × concept | [VENDOR_CONCEPT_COVERAGE_MATRIX.md](./VENDOR_CONCEPT_COVERAGE_MATRIX.md) |
| FACT backlog before concepts | [MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md](./MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md) |
| **`concept_methods`** | pretium-ai-dbt `registry/concept_methods/*.yml` (canonical) |
| Market / offering registry | pretium-ai-dbt `registry/MARKET_SELECTION_PRODUCT_OFFERING_MIGRATION.yml` |
| Dimensional QA | [../../scripts/sql/validation/dimensional_reference_catalog_and_geography.sql](../../scripts/sql/validation/dimensional_reference_catalog_and_geography.sql) |
| Reconciliation library index | [../../scripts/sql/validation/README.md](../../scripts/sql/validation/README.md) |
| **Catalog wishlist (blocked / next chains)** | [../reference/CATALOG_WISHLIST.md](../reference/CATALOG_WISHLIST.md) + `seeds/reference/catalog/catalog_wishlist.csv` |
| **Four-chain SoT (pretium-ai-dbt)** | [guide_offerings.md](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_offerings.md), [guide_signals.md](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_signals.md), [registry/CANONICAL_CONCEPT_ONTOLOGY.yml](../../../../pretium-ai-dbt/registry/CANONICAL_CONCEPT_ONTOLOGY.yml), [guide_models.md](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_models.md), [FEATURE_CONCEPT_BRIDGE.yml](../../../../pretium-ai-dbt/docs/analytics_engine/presley/FEATURE_CONCEPT_BRIDGE.yml) |
| **YAML cited in guides** | `registry/features/corridor_model.yaml`, `registry/models/arbitrage_score.yaml` — **confirm repo** (may live under **analytics-engine** sibling); do not duplicate. |

---

## §I — SIGNALS / MODELS (design-only seeds)

See [../reference/CATALOG_SIGNALS_LAYOUT.md](../reference/CATALOG_SIGNALS_LAYOUT.md) and [../reference/CATALOG_MODELS_LAYOUT.md](../reference/CATALOG_MODELS_LAYOUT.md). **No Snowflake seeds** until Alex signs **(c)** in §0.

---

## §J — analytics-engine and other repos

- **No duplicate SoT:** Other repos link **this playbook URL or path** only — **no second** `metric.csv` / `metric_derived.csv`.  
- pretium-ai-dbt: [SEMANTIC_LAYER_PLAYBOOK_LINK.md](../../../../pretium-ai-dbt/docs/governance/SEMANTIC_LAYER_PLAYBOOK_LINK.md) (one-line pointer).

---

## §K — ADR and deprecation

- Template: [ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md](./ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md).

---

## §L — Presley / IC (optional)

- If a feature feeds Presley **Truth / spine**, document **`metric_derived_id`**, **`as_of`**, and trust fields in model **`meta`** and link to Presley contract docs in pretium-ai-dbt.

---

## §M — Dense concept modeling (FACT → CONCEPT → FEATURE)

**North star:** One semantic concept = **`concept_code`** + **contract** (grain, measure family, horizon, vendor precedence). Physics in **`FACT_*`**; Pretium meaning in **`CONCEPT_*`**; scores / fit in **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`**.

| Layer | Holds |
|-------|--------|
| **`FACT_*`** | Vendor grain; never “Pretium meaning of rent” alone |
| **`CONCEPT_*`** | One row-set per `(concept_code, geo_grain, time_grain)` after precedence; idempotent union/coalesce over facts |
| **`FEATURE_*`** | **`ref('concept_*')` only** — transforms per [MODEL_FEATURE_ESTIMATION_PLAYBOOK.md](./MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) |
| **`MODEL_*` / `ESTIMATE_*`** | Consumes features + concepts; version via catalog ladder |

**Concept identity lock:** measure family (`level` \| `change` \| …); grain tuple; horizon (`spot` \| `trailing_12m` \| `forward` — forward in **ESTIMATE_** only); vendor precedence **only** in `CONCEPT_*` merge.

**Anti-patterns:** No `FEATURE_*` → `RAW_*`; no forward logic in `CONCEPT_*`; semantic names on concepts not vendor table names.

**Tests:** contract (rowcount vs spine, unique PK); semantic (bounds); **`meta.parent_facts`** on every `CONCEPT_*`.

**Decision rule:** Pretium meaning at (geo, time) → **`CONCEPT_*`**; vendor V raw → **`FACT_*`**; extreme / rank / fit → **FEATURE / MODEL / ESTIMATE**.

---

## §N — Market selection substance

Principles (abbreviated; full prose in committee materials):

1. **Substitution** — geo = high cross-elasticity where possible; label admin vs economic geographies.  
2. **Product** — screen by SKU (`bridge_product_type_metric` / `dataset.product_type_codes`).  
3. **Demand** — depth, income support, diversification vs headline growth.  
4. **Supply** — stock vs pipeline vs deliverability; label horizon.  
5. **Clearing** — vacancy, absorption, concessions, inventory at product grain.  
6. **Affordability ceiling** — sustainable rent growth cap in definitions.  
7. **Capital regime** — pair operating metrics with cap/spread/liquidity.  
8. **Liquidity / evidence** — coverage + freshness in `meta`.  
9. **Spatial structure** — CBSA → submarket / corridor / H3 per economic geography.  
10. **Horizon discipline** — do not mix multi-speed fundamentals in one rank without disclosure.  
11. **Incumbency** — same definitions, different confidence tiers for evidence.

---

## §O — Four forecast chains (metrics → concepts → features → estimates)

**Grain spine:** **CBSA → `corridor_h3` → segment** — catalog `geo_level_code` and YAML must match the artifact (no silent CBSA-only label on corridor-segmented outputs).

**Canonical rent form:** `rent_growth_{t+12} = f(demand_t, absorption_t, supply_t)` with staggered lags — pretium-ai-dbt [guide_models.md §4](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_models.md).

### Chains (summary)

| Chain | Primary concepts | Estimates (typical) |
|-------|------------------|---------------------|
| **Rent** | `rent` + drivers (`absorption_tightness`, `household_demographics_demand`, …) | `rent_psf` pred, `rent_growth_{t+h}`, `rent_residual`, ranks |
| **AVM** | `value_avm` | `value_psf`, `value_growth_*`, `value_residual` (+ provider / `model_id` / `as_of`) |
| **Value** | `value_avm` + `rent` + liquidity/cap | `price_growth`, stabilized value, mispricing class |
| **Income** | `labor_growth_access`, `household_demographics_demand`, `affordability_ceiling` | Income/job composites; feeds rent/cap |

**Composite example:** `arbitrage_score` / `corridor_model` / **`4_estimate`** — see guide_models, guide_real_estate, guide_signals; **not** a fifth “income-only” parallel stack.

**NOI / EGI:** Stay under **Value + rent + `occupancy_operations`** (`noi_proxy_per_unit`, `stabilized_value_fwd`) — not an isolated fifth chain.

**REFERENCE.CATALOG:** New **`metric`** / **`metric_derived`** names must **align or explicitly map** to pretium-ai-dbt **guide_signals** / **guide_offerings** vocabulary where applicable.

**Offerings “market” lens:** Use **`docs/analytics_engine/docs/guide_offerings.md`** (not a separate `guide_offerings_market.md`); pair with **guide_signals** for metric spellings.

---

## §P — Next four concept chains (as central as rent/value/income; not redundant with income)

Ontology **causal roles** + **guide_offerings** / **guide_signals** framing. Grain spine unchanged: **CBSA → corridor_h3 → segment**. Optional alternates (**`household_demographics_demand`**, **`occupancy_operations`**) use the **same stage table** — see wishlist rows **WL_010**, **WL_011** in [`catalog_wishlist.csv`](../../seeds/reference/catalog/catalog_wishlist.csv).

### Quick cross-reference (ontology roles)

| Concept | `ontology_model_role` | Typical forecast horizon |
|---------|-------------------------|---------------------------|
| `absorption_tightness` | driver | ~2 quarters; lag-sensitive |
| `construction_feasibility` | constraint | ~8 quarters; lag-sensitive |
| `transactions_sale_volume` | liquidity_proxy | ~2 quarters; lag-sensitive |
| `affordability_ceiling` | constraint | ~4 quarters |

These sit **between** macro/labor/income and **rent/value**: liquidity/clearing → **`absorption_tightness`** → **`rent`**; **construction** + **affordability** bound how far rent and development can run.

### P.1 `absorption_tightness` — market clearing / lease-up

| Stage | Expected content |
|--------|-------------------|
| **Metrics (raw)** | `vacancy_rate`, `absorption_pace`, `net_absorption`, `uc_units`, `pipeline_burndown_ratio`, `inventory_months_supply`; overlaps `occupancy_rate` as tightness proxy (`occupancy_operations` when split). |
| **Metrics (engineered)** | `tightness_score`, `tightness_alt`, `absorption_score`, `absorption_to_supply_ratio`, `lease_up_velocity`, `pipeline_demand_ratio`, `supply_pressure_forward`, `completion_risk_score`, `demand_supply_imbalance`. |
| **Concepts** | **Primary:** `absorption_tightness`. **Parents:** `household_demographics_demand`, `transactions_sale_volume`. **Child:** `rent`. |
| **Features** | Flow/stock ratios, lags/rolls, `sale_count_24m`, DOM where used in `absorption_score`; segment flags (lease vs sale sensitivity). |
| **Estimates** | Forward tightness / vacancy path **`t+h`**; absorption forecasts; tight/balanced/loose classification; ranks. **Downstream:** feeds **`rent_growth`** / lease-up narratives — avoid double-counting **rent level** in the same model if collinear. |

### P.2 `construction_feasibility` — supply response / deliverability

| Stage | Expected content |
|--------|-------------------|
| **Metrics (raw)** | `permit_volume`, `permit_to_stock_ratio`, `regulatory_supply_index`, `construction_cost_index`, `uc_units`, `pipeline_burndown_ratio`. |
| **Metrics (engineered)** | `supply_pressure_forward`, `population_to_permit_ratio`, `basis_vs_replacement_cost`, `sellout_to_basis_spread`, `completion_risk_score`, `pipeline_demand_ratio`. |
| **Concepts** | **Primary:** `construction_feasibility`. **Parents:** `rent`, `value_avm`. **Feeds:** interpretation of **`absorption_tightness`** and long-run **rent cap** (elastic vs constrained supply). |
| **Features** | Permits, starts/UC, regulatory/cost indices; `new_supply_share`, `construction_pipeline` (guide_models §4.4); interactions with demand growth. |
| **Estimates** | Pipeline delivery, `supply_growth_rate`, time-to-absorb; scenarios (rate/cost shocks on replacement cost vs `stabilized_value_fwd`); high vs low **supply elasticity** classification. |

### P.3 `transactions_sale_volume` — liquidity / price discovery

| Stage | Expected content |
|--------|-------------------|
| **Metrics (raw)** | `transaction_volume`, `days_on_market_listings`. |
| **Metrics (engineered)** | `absorption_score` (sales + DOM), turnover reads from guide_models (`log(sale_count_12m+1)`, `turnover_rate` where built); supports **`value_residual`** / exit liquidity. |
| **Concepts** | **Primary:** `transactions_sale_volume`. **Child:** `absorption_tightness`. **Co-use:** `value_avm` (thin markets distort AVM). |
| **Features** | `sfr_sales_log_24m` (corridor_model), sale counts by window, DOM, optional price volume; `liquidity_score` when versioned. |
| **Estimates** | Forward counts or **liquidity index** `t+h`; liquid vs thin classification; liquidity-adjusted absorption; **low-confidence** flags for value/rent models in thin markets. |

### P.4 `affordability_ceiling` — demand saturation / rent cap

| Stage | Expected content |
|--------|-------------------|
| **Metrics (raw)** | `rent_to_income_ratio`, `affordability_ratio`, `workforce_renter_share`; needs **`median_hh_income`** / bands + **`rent_level_median`** / **`rent_psf_median`** (inputs from `household_demographics_demand`, `rent`, `labor_growth_access`). |
| **Metrics (engineered)** | `affordability_stress_index`, `effective_demand_pressure`, `income_rent_growth_spread`, `payment_stress_delta`, `high_quality_growth`. |
| **Concepts** | **Primary:** `affordability_ceiling` (ontology **derived**). **Parents:** `rent`, `household_demographics_demand`. **Role:** **constraint** — binds forecasts; no downstream “drives” in ontology. |
| **Features** | RTI, payment burden, income vs rent growth spreads; `national_median_rti` for stress index; workforce renter cohort splits. |
| **Estimates** | Stress index or **RTI path** `t+h`; rate shock on **`payment_stress_delta`**; **cap** on rent path in joint models (bounded **`rent_growth`** or bind probability). |

### P.5 Wishlist seed (REFERENCE.CATALOG)

All **not doable right now** items (including these chains until `CONCEPT_*` + facts land) live in **`catalog_wishlist`** — see [reference/CATALOG_WISHLIST.md](../reference/CATALOG_WISHLIST.md).

---

## §Q — Two readings of “next model” after `arbitrage_score` (guide_models §4.7)

**Canonical write-up:** pretium-ai-dbt [guide_models.md §4.7a](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_models.md) (segment **five-model stack** + **Part 2** causal ladder). **`arbitrage_score`** is **item 5** in §4.7; repo modeling priority is **items 1–4** in that stack.

### Reading A — Register next: segment stack 1–4 (before the composite)

| # | Purpose | Target / output | Role vs `arbitrage_score` |
|---|---------|-----------------|---------------------------|
| **1** | Baseline rent level | `rent_psf` | Level / lag anchor for residuals and yield |
| **2** | Baseline value level | `value_psf` | Basis / collateral anchor; spread vs rent |
| **3** | Forward rent growth | `rent_growth` (**t→t+h** explicit) | Cash-flow dynamics; no leakage |
| **4** | Forward value growth | `value_growth` (or `price_{t+h}` spec) | Cap / liquidity / rates |

**Defaults:** Elastic Net–class baselines; **XGBoost / LightGBM** for production growth (same §4.7). Registry cards: stable **`object_name`**, **`corridor_model`‑class** features, **`segment_key`** versioning.

### Reading B — Fund next: Part 2 macro / flow models upstream of rent/value

| # | Part 2 family | Typical targets | Role |
|---|---------------|-----------------|------|
| **1** | Economic growth | `job_growth_{t+12}`, expansion vs contraction | Anchors labor / long-horizon demand |
| **2** | Demand | `demand_{t+12}`, `demand_score` | Tightness + rent; product weights |
| **3** | Absorption & liquidity | `absorption_{t+6}`, `liquidity_score` | Clearing + exit; feeds **`absorption_tightness`** (§P) |
| **4** | Rent (forecast + rank) | `rent_growth_{t+12}`, ranks | Surface before valuation → **`arbitrage_score`** |

**Rule of thumb:** **Reading A** = **what to put in `registry/models/` next** after the composite YAML exists. **Reading B** = **what to staff / sequence** when building **growth → demand → absorption → rent** before the valuation bridge.

---

## Retained — content packet, formatting, tests (v1)

**Per `metric_derived` / feature row:** catalog keys, semantic meaning (decision use), math (num/denom/window), SoT path, invariants, edge cases.

**Formatting:** `ref()` / `source()` only; stable `SELECT` column order; materialization with `unique_key` when incremental.

**Test tiers:** (1) schema — `not_null`, `relationships`; (2) logic — `expression_is_true` / fixtures; (3) reconciliation — [validation README](../../scripts/sql/validation/README.md); (4) parity vs external spec if applicable.

**Ask triggers:** Two valid definitions; grain mismatch; policy vs fact; ambiguous signal vs model input — **RFC** before merge.

---

## Pilot retrospective (template — fill after Pilot A)

| Question | Notes |
|----------|-------|
| What broke vs playbook v0.1? | |
| What would change in v0.2? | |
| New reconciliation scripts added? | |

---

*Update this file when gates §0, §P four-chain SoT paths, or §Q stack vs upstream framing change; append `MIGRATION_LOG.md` (short) + `MIGRATION_BATCH_INDEX.md` (detail) for material governance batches.*
