# Batch 025 — SOURCE_PROD BLS QCEW + O*NET vet; `FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY`

## Snowflake vet (`scripts/sql/migration/vet_source_prod_bls_qcew_onet_for_workforce_facts.sql`)

| Check | Result (2026-04-19, `snowsql -c pretium`) | Notes |
|-------|---------------------------------------------|--------|
| **A_qcew_raw_rowcount** | **213,219,014** | Full QCEW county raw history scale. |
| **A_qcew_rows_where_v_present** | **213,219,014** | VARIANT `v` populated on all counted rows. |
| **A_qcew_rows_where_area_fips_path** | **213,219,014** | Lowercase `v:area_fips` path valid. |
| **B_geo_invalid_area_fips** (1M sample, post-fix clause order) | High share of sample rows fail **county-only** rules | Raw includes **CBSA / non-county** `area_fips` (e.g. **`C2662`**), state totals, and other pseudo-areas. **Expected** — not a regression. `typeof(v:area_fips)` in a 50k sample: **INTEGER** and **VARCHAR** both appear; padding required for integer FIPS. |
| **C_raw_dup_grain_groups** (1M filtered sample) | **~2,944** duplicate `(area_fips, industry, year, qtr, own)` groups | Ownership-level duplicates; **FACT** aggregates across `own_code` to county × NAICS × quarter. |
| **D_null_or_nonpositive_employment** (1M sample) | High in raw sample | Disclosure / zero-employment rows common; **FACT** requires `employment > 0`. Spot diagnostic on 500k sample: **~290k** county-shaped rows still have null or ≤0 employment after padding — aligns with suppressed QCEW cells. |
| **E_year_distribution_sample** (1M sample) | Top buckets: 2023≈186k, 2024≈185k, 2020–2022 ~183–185k, 2025≈50k, 2019≈27k | Approximate vintage mix in sample (not full-table GROUP BY). |
| **F O*NET** | `OCCUPATION_BASE` **1,016**; `WORK_ACTIVITIES_GENERAL` **36,654**; `WORK_CONTEXT` **259,394** | `SOURCE_PROD.ONET` readable; identifiers **uppercase** in Snowflake. |

## dbt (semantic-layer)

- **Sources:** `models/sources/sources_source_prod_bls_onet.yml` — `source_prod_bls.qcew_county_raw`, `source_prod_onet.{occupation_base,work_activities_general,work_context}`.
- **FACT:** `models/transform/dev/bls/fact_bls_qcew_county_naics_quarterly.sql` — `TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY`; logic aligned to pretium-ai-dbt `cleaned_qcew_county_naics` (filters, combined NAICS, ownership rollup, **LPAD** county FIPS for integer VARIANT paths, `employment > 0`).
- **Tests:** `models/transform/dev/bls/schema_bls_qcew.yml` — grain `unique_combination_of_columns` + `not_null` on keys and employment.
- **`dbt parse`:** PASS (2026-04-19).

## Operator commands

```bash
cd pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
dbt run --select fact_bls_qcew_county_naics_quarterly
dbt test --select fact_bls_qcew_county_naics_quarterly
```

```bash
snowsql -c pretium -f scripts/sql/migration/vet_source_prod_bls_qcew_onet_for_workforce_facts.sql
```

## Follow-ups (next steps)

1. **Run** `dbt run` / `dbt test` on `fact_bls_qcew_county_naics_quarterly` in a warehouse with **SELECT on SOURCE_PROD.BLS** + **CREATE on TRANSFORM.DEV**; compare row counts to pretium-ai-dbt `cleaned_qcew_county_naics` (parity test optional).
2. **Port next FACTs** under vendor/dataset folders: O*NET SOC cleanses (dol/onet), Pretium Epoch ref tables → seeds or small FACTs, then `fact_county_soc_employment` / county replacement **CONCEPT** or composite per `AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md` §0.
3. **Catalog:** add `dataset` / `metric` rows for QCEW employment and wage columns on this grain (`METRIC_INTAKE_CHECKLIST.md`).
4. **Optional vet:** full-table (non-sample) duplicate rate on post-filter grain after mirroring FACT SQL in a `CREATE TEMP TABLE` — expensive; defer unless governance requires.
