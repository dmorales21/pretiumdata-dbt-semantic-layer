# Batch 027 — ANALYTICS FEATURE views (labor / automation risk)

**Date:** 2026-04-19  
**Task:** `T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK` (P1 partial)

## Models

| dbt model | Physical (target `dev`) | Upstream |
|-----------|-------------------------|----------|
| `feature_ai_replacement_risk_county` | `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_COUNTY` | `ref('fact_county_ai_replacement_risk')` |
| `feature_ai_replacement_risk_cbsa` | `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_CBSA` | County fact; `naics_code = 'ALL'` |
| `feature_ai_replacement_risk_cbsa_rollup` | `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_CBSA_ROLLUP` | `ref('feature_ai_replacement_risk_cbsa')` |
| `feature_structural_unemployment_risk_county` | `ANALYTICS.DBT_DEV.FEATURE_STRUCTURAL_UNEMPLOYMENT_RISK_COUNTY` | `ref('feature_ai_replacement_risk_county')` |

## Var

- **`onet_soc_naics_enabled`** in `dbt_project.yml` (default **false**). Set **`true`** via `--vars` or profile for Snowflake runs after the eight **TRANSFORM.DEV** FACT models + **`REF_ONET_SOC_TO_NAICS`** exist.

## Semantics note

Not a line-for-line port of pretium **`analytics_prod/features/feature_ai_replacement_risk_cbsa.sql`** (that path used `fact_economy_automation_risk` + `fact_household_labor_qcew_naics`). Canonical FEATUREs read the new **`fact_county_ai_replacement_risk`** only.

## Tests

`models/analytics/feature/_feature_ai_replacement_risk.yml` — data tests use **`config.enabled: "{{ var('onet_soc_naics_enabled', false) }}"`** so CI does not require Snowflake FACT rows. **`feature_structural_unemployment_risk_county.risk_tier`** also has **`accepted_values`** (`HIGH` / `MEDIUM` / `LOW`) when the var is true (fixed cutoffs on score, not the fact’s percentile tier).
