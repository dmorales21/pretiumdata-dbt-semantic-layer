# Contract — rent, AVM, and valuation concepts

Single place for **grain**, **slot semantics**, **`month_start` meaning**, **vendor overlap**, and **consumer routing**. Model SQL headers link here; keep this file updated when behavior changes.

**Physical location:** all `models/transform/dev/concept/*` marts are configured in **`dbt_project.yml`** under **`transform.dev.concept`** as **`TRANSFORM.DEV`** (not `ANALYTICS.DBT_DEV`), so `ref('concept_*')` from **ANALYTICS** QA/FEATURE models resolves to the transform warehouse.

---

## Cross-cutting

| Topic | Rule |
|--------|------|
| **Grain** | Each row is identified by `(concept_code, vendor_code, month_start, geo_level_code, geo_id)` plus optional `metric_id_observe` when a vendor publishes multiple series in one object. |
| **Vendor precedence** | The concept unions **do not** enforce a single “winner” vendor. Downstream consumers **must** filter `vendor_code` (and often `metric_id_observe`) or use a governed **MODEL_** / **SERVING** layer that encodes precedence. |
| **Slots** | `*_current`, `*_historical`, `*_forecast` follow `concept_metric_slot(...)` naming. **NULL** in a slot means *not populated for that vendor/period*, not necessarily “missing data bug” — see per-concept tables below. |
| **`month_start`** | **Observed period** for time-series facts (e.g. Zillow `date_reference` truncated to month). **Exception:** `concept_avm_market_monthly` (Cherre) uses **snapshot alignment**: all Cherre MA rows carry `month_start = DATE_TRUNC('month', CURRENT_TIMESTAMP())` because upstream has no native period column — **do not** interpret as a historical panel for ACF or staleness months-behind. |

---

## Rent

| Item | Detail |
|------|--------|
| **Canonical union** | `concept_rent_market_monthly` is the **only** place vendor-specific rent rules should grow. `feature_rent_market_monthly_spine` is a **pass-through** read surface in ANALYTICS (plus downstream cohort stats only). |
| **Property vs market** | `concept_rent_property_monthly` (property grain) aligns to market CBSA rows via shared `cbsa_id` / county keys. **QA:** `QA_RENT_PROPERTY_MARKET_BRIDGE` (fan-out / orphan checks for APARTMENTIQ CBSA joins). |
| **`equal_rowcount` / parity** | Spine row count is tested vs `concept_rent_market_monthly`. If a **small fixed drift** is accepted (boundary months, filters), document keys here and replace strict equality with an allowlisted anti-join test — see [`FEATURE_DEVELOPMENT_GUARDRAILS.md`](./FEATURE_DEVELOPMENT_GUARDRAILS.md) and `scripts/sql/validation/feature_rent_market_spine_vs_concept_reconciliation.sql`. |
| **SERVING / consumers** | Prefer **CONCEPT** for semantic truth; **FEATURE** for cohort math and IC-facing panels that intentionally mirror concept columns. **Golden pattern:** `SELECT * FROM ANALYTICS.<ENV>.FEATURE_RENT_MARKET_MONTHLY` is equivalent to concept projection until additional FEATURE-only columns are added. |

### Add-a-vendor checklist (market rent)

1. Land or reference a **typed FACT** (or controlled `source()`) with `date_reference`, geo keys, and rent measure.  
2. Map to **`rent_current` / `rent_historical` / `rent_forecast`** (use NULL + documented gap for unused slots).  
3. Set **`vendor_code`**, **`metric_id_observe`**, **`geo_level_code`**, normalized **`geo_id`** / **`cbsa_id`**.  
4. If vendor not ready: add a **typed zero-row stub** (`WHERE 1 = 0`) so the union stays explicit.  
5. Extend **`models/transform/dev/concept/schema.yml`** tests if new `vendor_code` or grains are introduced.  
6. Re-run **`QA_SERIES_COLLISION_DUPLICATE`** / partition rowcount / parity SQL as appropriate.

---

## AVM

| Item | Detail |
|------|--------|
| **Purpose** | `concept_avm_market_monthly` — Cherre **median** estimated value at CBSA (MA geography type). |
| **`month_start`** | **Snapshot-aligned** to current calendar month (see cross-cutting). **Not** suitable for lag-1 ACF or “months behind latest observation” in `QA_FRESHNESS_STALENESS_REPORT` — that view **excludes** this object. |
| **`avm_historical` / `avm_forecast`** | Intentionally **NULL** until time-series AVM facts exist; do not infer “broken” from NULL alone. |
| **Second vendor** | Add only after **true period** (or relabeled snapshot object) exists; avoid stacking multiple snapshot semantics. |
| **FEATURE spine** | No `feature_avm_market_monthly_spine` yet — **read CONCEPT** until AVM time truth is fixed and parity tests are defined. |

---

## Valuation

| Item | Detail |
|------|--------|
| **Purpose** | `concept_valuation_market_monthly` — multi-vendor **price-like** valuation panel at CBSA: Cherre **average** estimated value (same upstream geo table as AVM, different column), Zillow home values + forecasts, FHFA HPI + UAD long-form. |
| **Cherre vs AVM** | Same **`cherre_avm_geo_stats`** MA rows: **AVM** = `MEDIAN_ESTIMATED_VALUE`; **valuation** = `AVG_ESTIMATED_VALUE`. IC must confirm both concepts stay published, or merge to one. **QA:** `QA_CHERRE_AVM_VALUATION_RATIO_BOUNDS` (wide median/avg ratio sanity). |
| **FHFA_UAD** | UAD variables are not all month-comparable “price levels.” Filter with **`vars.concept_valuation_fhfa_uad_variable_regex`** (empty = no extra filter for backward compatibility). Tighten in each environment after vetting Cybersyn `VARIABLE` values. |
| **Forecast slot** | Populated for **Zillow** where forecast facts join; **NULL** for Cherre snapshot and FHFA slices by design unless extended. |

---

## Decision table — which object for which question?

| Consumer need | Use | Avoid |
|---------------|-----|--------|
| CBSA rent panel (multi-vendor) | `concept_rent_market_monthly` | Re-unioning vendors in FEATURE |
| Same rent + cohort z-scores in ANALYTICS | `feature_rent_market_monthly_spine` (→ `FEATURE_RENT_MARKET_MONTHLY`) | Assuming FEATURE adds vendors |
| Property-level rent | `concept_rent_property_monthly` | Joining property to market without `cbsa_id` / month discipline |
| CBSA **collateral median** (Cherre snapshot) | `concept_avm_market_monthly` | Lag-1 ACF / staleness “months behind” on Cherre branch |
| CBSA **blended valuation** (multi-vendor) | `concept_valuation_market_monthly` | Treating every `FHFA_UAD` variable as comparable price |
| CBSA **home price** ontology (affordability, UAD in home-price path) | `concept_home_price_market_monthly` | Duplicating without checking overlap with `concept_valuation_*` |
| ZIP **YoY % change** in home price | `feature_home_price_delta_zip_monthly` | Confusing with CBSA valuation concept (different grain) |

---

## QA alignment

| QA view | Rent / AVM / valuation note |
|---------|-----------------------------|
| `QA_FRESHNESS_STALENESS_REPORT` | **Excludes** `concept_avm_market_monthly` (snapshot `month_start` would fake freshness). |
| `QA_AUTOCORRELATION_*` (Zillow rent) | Rent **concept** time series only — does not include AVM. |
| `QA_UAD_ISOLATION_VALIDATION` | Row volumes for `FHFA_UAD` on home price vs valuation. |
| `QA_RENT_PROPERTY_MARKET_BRIDGE` | Property ↔ market CBSA join integrity (APARTMENTIQ). |
| `QA_CHERRE_AVM_VALUATION_RATIO_BOUNDS` | Cherre median vs avg cross-check. |

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial contract from rent / AVM / valuation next-steps workstream. |
| **0.2** | Implemented: `concept_valuation` FHFA UAD optional regex var; freshness report excludes Cherre AVM snapshot; `QA_RENT_PROPERTY_MARKET_BRIDGE`, `QA_CHERRE_AVM_VALUATION_RATIO_BOUNDS`; model/schema cross-links. |
