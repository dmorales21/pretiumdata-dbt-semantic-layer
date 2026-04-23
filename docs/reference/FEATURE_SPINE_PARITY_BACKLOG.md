# FEATURE spine parity backlog (SERVING / notebooks / Iceberg first)

**Default pattern:** thin **`FEATURE_*`** read surface in **ANALYTICS** ≈ **`SELECT *` from `CONCEPT_*`** (same contract, cohort stats layered only in **ANALYTICS**), unless the concept already has a **better bespoke** feature (e.g. **`feature_listings_velocity_monthly_spine`**, **`feature_employment_delta_cbsa_monthly`**).

**Companion:** [`FEATURE_DEVELOPMENT_GUARDRAILS.md`](./FEATURE_DEVELOPMENT_GUARDRAILS.md) · [`SERVING_DEMO_ICEBERG_TARGETS.md`](./SERVING_DEMO_ICEBERG_TARGETS.md) · [`SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md`](../runbooks/SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md)

**Decision rule:** If **`SERVING.DEMO` / Iceberg** needs a stable FQN for analysts, prioritize **P0–P1** spines. Corridor / composite modeling still benefits from **P0–P1** as shared inputs.

---

## SERVING.DEMO **v1** — minimal “top 5” (rent + rates + income only)

If v1 is intentionally **narrow** (not the full market panel), execute in this order:

1. **`feature_rent_market_monthly_spine`** (already exists) + optional **`demo_feature_rent_market_monthly`**.  
2. **`feature_rates_national_monthly_spine`** ← `concept_rates_national_monthly` (P0 #1).  
3. **`feature_income_market_annual_spine`** ← `concept_income_market_annual` (P0 #2).  
4. Catalog **`demo_ref_*`** pack (already in repo).  
5. Wire **`dbt test`** / parity QA for those three spines before replication labels the lake canonical.

---

## P0 — Ship first (highest leverage for demos + downstream joins)

| Priority | Target | Why |
|---------:|--------|-----|
| 1 | **`concept_rates_national_monthly` → `feature_rates_national_monthly_spine`** | Macro anchor for spreads, DSCR stress, cap-rate narratives; **national** grain → fast to build/test; unblocks many composites later. |
| 2 | **`concept_income_market_annual` → `feature_income_market_annual_spine`** | Unlocks **affordability / RTI** and pairs with **rent** + **home_price** in almost every market story. |
| 3 | **`concept_transactions_market_monthly` → `feature_transactions_market_monthly_spine`** | Liquidity / price discovery; used constantly next to listings and home price. |
| 4 | **`concept_valuation_market_monthly` → `feature_valuation_market_monthly_spine`** | Mixed vendors + slots; spine stops consumers bypassing the concept and re-joining Zillow/FHFA/Cherre ad hoc. |
| 5 | **`concept_avm_market_monthly` → `feature_avm_market_monthly_spine`** | Even when Cherre is snapshot-heavy, the **read surface** mirrors the concept contract; document time semantics in the FEATURE header (same as [`CONTRACT_RENT_AVM_VALUATION.md`](./CONTRACT_RENT_AVM_VALUATION.md)). |

---

## P1 — Second wave (supply / clearing / population spine)

| Priority | Target | Why |
|---------:|--------|-----|
| 6 | **`concept_absorption_market_monthly` → `feature_absorption_market_monthly_spine`** | Absorption as its own concept; spine enables cohort stats + consistent SERVING joins without conflating listings velocity. |
| 7 | **`concept_supply_pipeline_market_monthly` → `feature_supply_pipeline_market_monthly_spine`** | Pairs with absorption + permits for pipeline / development narratives. |
| 8 | **`concept_permits_market_monthly` → `feature_permits_market_monthly_spine`** | Cheap, stable public signal; supports pipeline + feasibility composites. |
| 9 | **`concept_population_market_annual` → `feature_population_market_annual_spine`** | Denominators for migration + normalization; low-complexity annual spine. |
| 10 | **`concept_migration_market_annual` → `feature_migration_market_annual_spine`** | Often shown with population/income; stable read surface vs ad hoc SQL. |

---

## P2 — Third wave (ops / risk / quality-of-life, slower cadence)

| Priority | Target | Why |
|---------:|--------|-----|
| 11 | **`concept_occupancy_market_monthly`** + **`concept_vacancy_market_monthly`** spines | Ship **together** with one QA pass for **complement consistency**; annual crime/school can wait if rent/transactions path is hotter. |
| 12 | **`concept_delinquency_market_monthly` spine** | Sensitive to definitions/vendor; after core macro + transactions are stable. |
| 13 | **`concept_crime_market_annual`** + **`concept_school_quality_market_annual`** spines | Annual cadence; location scoring; rarely blocking first SERVING demo slices. |
| 14 | **`concept_labor_market_annual` spine** | If it overlaps **employment / unemployment / income**, define **non-duplicative** columns vs those spines—or merge at the **CONCEPT** layer first. |

---

## Already partial — next steps (not always a new spine)

| Area | Next step |
|------|-----------|
| **rent** | Add **`feature_rent_property_monthly_spine`** (property grain parity). Keep **market** spine as-is. |
| **home_price** | Add **`feature_home_price_market_monthly_spine`** pass-through to CBSA concept **or** rename/document **`feature_home_price_delta_zip_monthly`** as **momentum-only** (not a substitute for concept read). |
| **employment / unemployment** | Minimum: **`feature_unemployment_market_monthly_spine`** for parity. Optionally keep **delta** FEATUREs *in addition*, not instead. |
| **workforce_task_automation** | If product needs **concept-aligned** consumption: **`feature_workforce_task_automation_annual_spine`**; keep **county AI bivariate** stack separate (different intent). |

---

## Lower priority for `FEATURE_*` spines

- **`concept_workforce_task_automation_annual`** — defer if the concept mart is still volatile on SOC vintage / weighting; else promote toward **P1**.  
- **Portfolio concepts** (`noi`, `dscr`, … from **`concept.csv`**): usually **`MODEL_*` / property FACT`** paths, not market **`FEATURE_*`** spines.

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial prioritized backlog (SERVING / Iceberg + thin spine parity). |
