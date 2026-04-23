# Anchor Pipeline with Liberty Hill — Proposal, Run, and Validation

**Purpose:** Define the Anchor (Anchor Loans) pipeline, run order, validation with deal **LIBERTY_HILLS**, and list of models/macros to create (if any).  
**References:** [ANCHOR_SCREENER_DATA_MAP.md](ANCHOR_SCREENER_DATA_MAP.md), [ANCHOR_LOANS_PIPELINE_REVIEW.md](ANCHOR_LOANS_PIPELINE_REVIEW.md), [CANONICAL_ARCHITECTURE_CONTRACT.yml](../../governance/CANONICAL_ARCHITECTURE_CONTRACT.yml).

---

## 1. Pipeline scope

| Layer | What | Location |
|-------|------|----------|
| **Source** | Deal registry | `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` (populated by app + `PROCESS_NEW_DEALS()`) |
| **Ref / Fact** | Geography, place, housing, demographics | `TRANSFORM_PROD.REF`, `TRANSFORM_PROD.FACT` (existing) |
| **Delivery** | Screener views | `EDW_PROD.DELIVERY.V_ANCHOR_*` (dbt `tag:anchor_screener`) |

**Liberty Hill:** Deal used for validation: `DEAL_ID = 'LIBERTY_HILLS'`. Must exist in `DEALS` and return one row from `V_ANCHOR_DEAL_SCREENER`.

---

## 2. Build order (run)

1. **Upstream ref/fact** (as needed for screener):  
   Housing, place, household fact/ref models that the Anchor delivery views depend on (e.g. `housing_hou_pricing_all_ts`, `fact_place_plc_education_all_ts`, `household_hh_demographics_all_ts`, `household_hh_labor_qcew_naics`, etc.).
2. **Anchor delivery views:**  
   `dbt run --select +tag:anchor_screener`  
   (builds dependencies then all models with `tag:anchor_screener`).

**Script:** `scripts/anchor/run_anchor_pipeline.sh` (sets `DBT_DB`/`DBT_SCHEMA`, runs the above).

---

## 3. Validation (Liberty Hill)

- **Check 1:** `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` contains one row with `DEAL_ID = 'LIBERTY_HILLS'`.
- **Check 2:** `EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER` returns exactly one row for `deal_id = 'LIBERTY_HILLS'` (and optionally non-null key columns).

**Assets:**  
- `scripts/anchor/validate_anchor_liberty_hill.sql` — SQL to run in Snowflake.  
- `scripts/anchor/validate_anchor_liberty_hill.py` — Optional script using project Snowflake connection to run validation and print pass/fail.

---

## 4. Models to create

| Model | Layer | Required? | Notes |
|-------|--------|-----------|--------|
| *(none for baseline)* | — | No | Current pipeline uses `source('anchor_loans','deals')` and existing fact/ref. |
| **cleaned_anchor_deals** | Cleaned | Optional | Pass-through from `anchor_loans.deals` to `TRANSFORM_PROD.CLEANED` for canonical lineage. Delivery view could then `ref('cleaned_anchor_deals')` instead of `source('anchor_loans','deals')`. |

**Recommendation:** Run and validate the pipeline as-is first. Add `cleaned_anchor_deals` only if you want all Anchor reads to go through the cleaned layer.

---

## 5. Macros to create

| Macro | Required? | Notes |
|--------|-----------|--------|
| *(none)* | No | Macro freeze (Phase 1 complete). Screener views do not introduce new inline math that would require new macros. Haversine in `v_anchor_deal_screener` is one-off spatial logic; no need to macro it unless reused. |

---

## 6. Existing Anchor models (no new names)

- **Delivery (tag:anchor_screener):**  
  `v_anchor_deal_screener`, `v_anchor_deal_screener_retailers`, `v_anchor_deal_screener_retailers_detail`, `v_anchor_zonda_comps`, `v_anchor_starts_closings_cbsa`, `v_anchor_school_score_by_zip`, `v_anchor_crime_score_by_zip`
- **Fact (used by screener):**  
  `fact_place_major_retailers` (tag:anchor_screener)

---

## 7. How to run and validate

### Get Liberty Hill done (one deal, full pipeline)

Runs all upstream of the screener then validates that `LIBERTY_HILLS` appears in the screener:

```bash
# From repo root (sets DBT_DB/DBT_SCHEMA from .env or defaults)
./scripts/anchor/run_liberty_hill_full_pipeline.sh
```

- Runs `housing_hou_demand_all_ts` with `--full-refresh` first so the table has the current schema (avoids "invalid identifier PROPERTY_ID" if the table was built from an older model).
- Then builds: `+v_anchor_deal_screener` (all refs/facts the screener needs).
- Vars: `anchor_household_labor_from_cps: false` so labor builds as stub if `fact_cps_labor_ts` is missing.
- Then runs `validate_anchor_liberty_hill.py` (Check 1: deal in source; Check 2: one row in screener; prints key columns).

Use `--skip-validate` to run dbt only:

```bash
./scripts/anchor/run_liberty_hill_full_pipeline.sh --skip-validate
```

### Anchor screener only (no full upstream)

If upstream ref/fact are already built and you only want to refresh the Anchor delivery views:

```bash
export DBT_DB=TRANSFORM_PROD DBT_SCHEMA=DEV   # or use .env (never PUBLIC)
./scripts/anchor/run_anchor_pipeline.sh
```

Then run validation manually:

```bash
# Option A: Run SQL file in Snowflake (snowsql or worksheet)
snowsql -f scripts/anchor/validate_anchor_liberty_hill.sql

# Option B: Python validation (uses discovery Snowflake connection)
.venv/bin/python scripts/anchor/validate_anchor_liberty_hill.py
```

---

## 8. Notes

- **Compile/run/validation** require Snowflake access (dbt connects to resolve refs/sources). Run `run_anchor_pipeline.sh` and `validate_anchor_liberty_hill.py` from an environment where Snowflake is reachable (e.g. VPN, office network).
- **Python validation:** Run from repo root so `scripts.discovery.snowflake_connection` resolves: `python scripts/anchor/validate_anchor_liberty_hill.py` or `.venv/bin/python scripts/anchor/validate_anchor_liberty_hill.py`.
- **Run script** loads `.env` if present (same as `run_tethering_edw.sh`). Validation SQL includes Check 3: full screener row for LIBERTY_HILLS (key columns). Python validator prints key column values for the Liberty Hill row.

---

**Last updated:** 2026-02-10
