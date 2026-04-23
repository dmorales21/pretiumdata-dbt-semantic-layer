# Recreating CPS as `TRANSFORM.NBER.CPS_COUNTY` and `TRANSFORM.NBER.CPS_CBSA`

**Purpose:** Design notes for data engineering: how to recreate the Current Population Survey (CPS) pipeline as first-class objects under **`TRANSFORM.NBER`** — **`cps_county`** (county grain) and **`cps_cbsa`** (CBSA grain) — aligned with existing slice-safe labor logic and downstream dbt.

**Related:** [CPS_CBSA_EXTRACTION_UPSTREAM.md](CPS_CBSA_EXTRACTION_UPSTREAM.md), [BLS_CPS_LAUS_PIPELINE.md](../../data/BLS_CPS_LAUS_PIPELINE.md), [bls_cps_cbsa_population_plan.md](bls_cps_cbsa_population_plan.md), `dbt/models/analytics_prod/features/bls_cps_cbsa.sql`, `dbt/models/transform_prod/fact/fact_cps_labor_ts.sql`.

---

## 1. What you are replacing

Today the CBSA path is effectively:

`SOURCE_PROD.NBER` microdata → **`CPS_BASIC3_LOADED`** → **`CPS_BASIC3_LONG`** (slice-level) → **`TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION`** (wide CBSA × month) → **`bls_cps_cbsa`** → **`fact_cps_labor_ts`**.

County-level labor from **BLS** is often satisfied by **LAUS county** (separate vendor path). A **`cps_county`** object is **CPS-derived** county aggregates (not LAUS), when you need CPS concepts at county grain.

---

## 2. Target shape in `TRANSFORM.NBER`

| Object | Grain | Purpose |
|--------|--------|--------|
| **`TRANSFORM.NBER.CPS_COUNTY`** | `(county_fips, date_reference)` — month-start `date_reference` | Person-weighted labor and population metrics **at county** from CPS microdata. |
| **`TRANSFORM.NBER.CPS_CBSA`** | `(cbsa_code, date_reference)` | Same *conceptual* output as today’s **`V_CPS_CBSA_EXTRACTION`**, but as a **table or view** in **`TRANSFORM.NBER`**, not under `TRANSFORM_PROD.CLEANED`. |

Both should expose **column families** compatible with what **`bls_cps_cbsa`** already selects (rates, counts, earnings) so downstream models can switch `FROM` with minimal change.

---

## 3. Shared upstream: one slice-safe long layer

Do **not** duplicate fragile pivot logic in two places. Build **one internal long relation** (view or table) that encodes the **same labor-force rules** as the fixed pipeline:

- **`TRANSFORM.NBER.CPS_BASIC3_LONG`** (name illustrative)

Grain: person (or household if using that weight) **plus** geography dimensions: **county FIPS**, **CBSA**, and slice keys (metro status, etc.). Include survey month, weights, employment flags, earnings, age, **civilian labor force** gating — per [CPS_CBSA_EXTRACTION_UPSTREAM.md](CPS_CBSA_EXTRACTION_UPSTREAM.md) and `scripts/sql/transform_prod/cleaned/replace_cps_basic3_long_labor_consistent.sql`.

---

## 4. Rollups: county vs CBSA

### 4.1 `CPS_COUNTY`

Aggregate **`CPS_BASIC3_LONG`** to **county × month**:

- **Sum** person weights into populations and labor-force components (LF, employed, unemployed, full-time/part-time, earnings sums for weighted means).
- **Rates** only from those sums, e.g.  
  `unemployment_rate = 100 * unemployed_count / labor_force_count` when `labor_force_count > 0`.
- Use **sum-then-divide** — **no** `MAX` of precomputed rates across incompatible slices at county grain.

### 4.2 `CPS_CBSA`

Aggregate the **same long form** to **CBSA × month**:

- If multiple **slices** exist per `(cbsa, month)`, **sum** slice-level weighted counts first, then compute rates (see upstream doc: rates from summed counts, not independent `MAX` per metric).

Example pattern:

```sql
CREATE OR REPLACE VIEW TRANSFORM.NBER.CPS_CBSA AS
SELECT
  cbsa_code,
  date_reference,
  -- summed counts then derived rates
  ...
FROM TRANSFORM.NBER.CPS_BASIC3_LONG
GROUP BY cbsa_code, date_reference;
```

Use a **materialized table** instead of a view if query cost or refresh SLAs require it.

---

## 5. DDL / contract conventions

- **`date_reference`:** `DATE_TRUNC('month', ...)::DATE` — **month-start**, consistent with monthly time-key rules in `dbt/ANALYTICS_DATABASE_CONTRACT.md`.
- **County:** `county_fips` **5-digit** (or explicit `state_fips` + `county_fips`); document FIPS vintage with microdata.
- **CBSA:** `cbsa_code` **5-digit**, zero-padded; align with `ref('bridge_geo_h3_6810_canon')` / `dim_geography` usage elsewhere.
- **Column names:** Match **`bls_cps_cbsa`** expectations (`unemployment_rate`, `labor_force_participation_rate`, `population`, `employed_count`, …) so `bls_cps_cbsa` only changes **source** location.

---

## 6. dbt wiring

1. **`sources.yml`:** Add source `nber` with `database: transform`, `schema: nber`, tables `CPS_CBSA`, `CPS_COUNTY` (identifiers per Snowflake object names).
2. **`bls_cps_cbsa.sql`:** Point `FROM` at `{{ source('nber', 'cps_cbsa') }}` (or a compatibility view — see below).
3. **Migration option:** Keep a thin view `TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION` as `SELECT * FROM TRANSFORM.NBER.CPS_CBSA` until all consumers switch.
4. **County downstream:** New facts/features use `source('nber', 'cps_county')` with `geo_level_code = 'COUNTY'`, `geo_id` = county FIPS.

---

## 7. Validation

- Slice diagnostics: same spirit as `scripts/validation/diagnostic_cps_basic3_long_one_cbsa_month.sql`; add a **county** one-key trace when county grain is new.
- **CBSA:** Compare CPS unemployment to **LAUS metro** where geography aligns ([BLS_CPS_LAUS_PIPELINE.md](../../data/BLS_CPS_LAUS_PIPELINE.md)).
- **County:** Compare to **LAUS county** where applicable; document CPS vs LAUS methodology differences.
- **Fact refresh:** `fact_cps_labor_ts` is **incremental** — after backfilling `bls_cps_cbsa`, run **`fact_cps_labor_ts --full-refresh`**.

---

## 8. Summary

**Build `TRANSFORM.NBER.CPS_BASIC3_LONG` (slice-safe, LF-consistent) → aggregate to `CPS_COUNTY` and `CPS_CBSA` with sum-then-rate logic;** repoint **`bls_cps_cbsa`** at **`TRANSFORM.NBER.CPS_CBSA`**, and add county consumers from **`TRANSFORM.NBER.CPS_COUNTY`** when needed.

---

## Revision log

| Date | Change |
|------|--------|
| 2026-04-07 | Initial document from architecture handoff. |
