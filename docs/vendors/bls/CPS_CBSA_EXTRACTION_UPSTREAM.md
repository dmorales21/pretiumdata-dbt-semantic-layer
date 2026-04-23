# CPS CBSA extraction upstream (where `unemployment_rate` / `employment_rate` / LFPR are defined)

The dbt project **does not** contain the SQL that builds `TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION`. That view lives in Snowflake and is maintained in the separate transform pipeline referenced in [bls_cps_cbsa_population_plan.md](bls_cps_cbsa_population_plan.md).

## Objects in Snowflake (inspect here first)

| Object | Role |
|--------|------|
| `TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION` | Weighted CBSA rollup; defines `unemployment_rate`, `labor_force_participation_rate`, `employment_rate`, counts. |
| `ANALYTICS_PROD.FEATURES.BLS_CPS_CBSA` | Feature table populated from the view (should match extraction for the same keys). |
| `TRANSFORM_PROD.FACT.FACT_CPS_LABOR_TS` | Long fact; unpivots `BLS_CPS_CBSA` (see `dbt/models/transform_prod/fact/fact_cps_labor_ts.sql`). |

## Get the view definition in Snowflake

Run as a role that can see the view (e.g. `ACCOUNTADMIN` or your dev role):

```sql
SELECT GET_DDL('VIEW', 'TRANSFORM_PROD.CLEANED.V_CPS_CBSA_EXTRACTION');
```

Optional: list dependent objects:

```sql
SELECT * FROM TABLE(
  INFORMATION_SCHEMA.VIEW_LINEAGE(
    'TRANSFORM_PROD',
    'CLEANED',
    'V_CPS_CBSA_EXTRACTION'
  )
);
```

(Exact function availability depends on Snowflake edition; if unavailable, use `GET_DDL` and search referenced views/tables.)

## Root causes fixed in-repo (Snowflake deploy scripts)

Two bugs stacked:

1. **`CPS_BASIC3_LONG` grain**: `base_metrics` groups by state, county, region, and metropolitan status, so there are **multiple slice rows per `(DATE_REFERENCE, ID_CBSA)`** for each `META_METRIC`. The old **`V_CPS_CBSA_EXTRACTION`** pivoted with **`MAX(...)`** grouped only by CBSA, so **each metric’s MAX could come from a different slice** → employed and labor force no longer from the same geography (impossible ER/UR).
2. **Labor-force logic in `CPS_BASIC3_LONG`**: `WEIGHTED_EMPLOYED` used `(WORK_STATUS = '1' OR EMPLOYED = '1')` **without** requiring `IN_CIVILIAN_LABOR_FORCE = '1'`, and `WEIGHTED_UNEMPLOYED` **overlapped** employed when `WORK_STATUS` conflicted with `EMPLOYED`. That inflated employed + unemployed relative to civilian LF.

**Deploy order (repeatable in this repo):**

| Step | Script |
|------|--------|
| 1 | `scripts/sql/transform_prod/cleaned/replace_cps_basic3_long_labor_consistent.sql` — gate employed / unemployed / full-time / part-time / earnings on **`IN_CIVILIAN_LABOR_FORCE = '1'`**; LF = sum of weights where civilian LF flag is 1. |
| 2 | `scripts/sql/transform_prod/cleaned/replace_v_cps_cbsa_extraction_slice_safe.sql` — pivot **per slice** with `MAX` (one value per slice/metric), then **`SUM`** counts across slices to CBSA/month; **rates only from summed counts** (no `COALESCE` to slice-level precomputed rates). |
| 3 | `scripts/sql/analytics/features/update_bls_cps_cbsa_from_v_cps_extraction.sql` — refresh **`ANALYTICS_PROD.FEATURES.BLS_CPS_CBSA`** from the view. |
| 4 | `dbt run --select fact_cps_labor_ts --full-refresh` | 

Trace one bad key through long-form slices: `scripts/validation/diagnostic_cps_basic3_long_one_cbsa_month.sql`.

## Intended CBSA/month formulas (after the fixes)

| Output column | Logic |
|---------------|--------|
| Counts | **Sum** of slice-level weighted counts from `CPS_BASIC3_LONG` for the CBSA/month. |
| `UNEMPLOYMENT_RATE` | `100 * UNEMPLOYED_COUNT / LABOR_FORCE_COUNT` when `LABOR_FORCE_COUNT > 0`. |
| `EMPLOYMENT_RATE` | `100 * EMPLOYED_COUNT / LABOR_FORCE_COUNT` when `LABOR_FORCE_COUNT > 0`. |
| `LABOR_FORCE_PARTICIPATION_RATE` | `100 * LABOR_FORCE_COUNT / POPULATION_16_64` when `POPULATION_16_64 > 0`. |
| `EMPLOYMENT_TO_POPULATION_RATIO` | `100 * EMPLOYED_COUNT / POPULATION_16_64` when `POPULATION_16_64 > 0`. |

**LFPR** still uses **`POPULATION_16_64`** (age 16–64 weighted population from microdata), not CNIP 16+.

## Historical note (pre-fix DDL)

Older `GET_DDL` output for `V_CPS_CBSA_EXTRACTION` showed **`MAX`** pivot at CBSA-only grain and **`COALESCE`** to precomputed rates from long—unsafe with multi-slice long data. Use `GET_DDL` after applying the scripts above to see the current definition.

## Sanity checks after any CPS change

- For a large metro, run `scripts/validation/diagnostic_cps_cbsa_trace_batch.sql`: **Section B** should be all `OK` (no UR > 25, LFPR/ER > 100 from raw).
- For one `(CBSA, month)`, run `scripts/validation/diagnostic_cps_basic3_long_one_cbsa_month.sql`: if **`n_rows` > 1** for count metrics, CBSA rollups must **sum** slices, not **`MAX`** per metric independently.
- At person level (optional), weighted **employed + unemployed** should equal weighted **civilian labor force** when using the same `IN_CIVILIAN_LABOR_FORCE` gate.

## Repo-adjacent script paths (may live outside this git repo)

Per [bls_cps_cbsa_population_plan.md](bls_cps_cbsa_population_plan.md), the historical layout was:

- `sql/transform/cleaned/create_cps_cbsa_extraction.sql` — extraction view
- `sql/transform/cleaned/validate_cps_source_data.sql`
- `sql/analytics/features/create_bls_cps_cbsa_table.sql` / `populate_bls_cps_cbsa.sql`

If those files exist in your org’s transform repo, **that** is the authoritative place to fix formulas; then refresh `BLS_CPS_CBSA` and run `fact_cps_labor_ts` (full refresh if backfilling).

## Validation in this repo

- Single (CBSA, month): `scripts/validation/diagnostic_cps_cbsa_trace_one_month.sql`
- Batch (edit `VALUES` in script): `scripts/validation/diagnostic_cps_cbsa_trace_batch.sql`
- CPS vs LAUS: `scripts/validation/compare_cps_vs_laus_unemployment_cbsa.sql`
- All labor tables / scripts (LAUS, QCEW, CPS, marts): [LABOR_DATA_INVENTORY.md](../../data/LABOR_DATA_INVENTORY.md)
