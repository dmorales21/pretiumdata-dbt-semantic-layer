# Batch 028 — Labor stack P2/P3 (`MODEL_*`, mart, AIGE fact)

**Date:** 2026-04-20  
**Task:** `T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK` (P2 partial + P3 read path)

## What shipped

| dbt model | Physical (target `dev`) | Notes |
|-----------|-------------------------|--------|
| `fact_aige_counties` | `TRANSFORM.DEV.FACT_AIGE_COUNTIES` (view) | Empty when **`aige_counties_enabled: false`**; pass-through legacy **`FACT_AIGE_COUNTIES`** when true. |
| `feature_ai_risk_county_bivariate` | `ANALYTICS.DBT_DEV.FEATURE_AI_RISK_COUNTY_BIVARIATE` | Joins **`fact_county_ai_replacement_risk`** + pivoted AIGE when **`aige_counties_enabled`**. |
| `model_county_ai_risk_dual_index` | `ANALYTICS.DBT_DEV.MODEL_COUNTY_AI_RISK_DUAL_INDEX` | Percentile blend; **`onet_soc_naics_enabled`** gate. |
| `fact_county_ai_automation_risk` | `TRANSFORM.DEV.FACT_COUNTY_AI_AUTOMATION_RISK` (table) | **`feature_structural_unemployment_risk_county`** latest + optional AIGE. |

## Vars (`dbt_project.yml`)

| Var | Default | Purpose |
|-----|---------|---------|
| `onet_soc_naics_enabled` | `false` | Labor FACT/FEATURE/MODEL/mart graph (unchanged). |
| `aige_counties_enabled` | `false` | Read legacy AIGE long-form into **`fact_aige_counties`**; populate bivariate / mart AIGE columns. |

## Validation

```bash
dbt run --select fact_aige_counties fact_bls_qcew_county_naics_quarterly ref_epoch_to_gwa_crosswalk \
  ref_epoch_capability_taxonomy fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction \
  fact_dol_onet_soc_ai_exposure fact_county_soc_employment fact_county_ai_replacement_risk \
  feature_ai_replacement_risk_county feature_structural_unemployment_risk_county \
  feature_ai_risk_county_bivariate model_county_ai_risk_dual_index fact_county_ai_automation_risk \
  --vars '{"onet_soc_naics_enabled": true}'

dbt test --select fact_aige_counties feature_ai_risk_county_bivariate model_county_ai_risk_dual_index fact_county_ai_automation_risk \
  --vars '{"onet_soc_naics_enabled": true}'
```

**Result:** PASS (Snowflake `target=dev`, AIGE var false — **`fact_aige_counties`** empty; dual-index uses O*NET strand only).

## Next

- **P6** — `metric_derived` for published MODEL/FEATURE columns.  
- **P5** — optional **`fact_county_ai_replacement_risk`** row parity warn vs legacy.  
- **AIGE on:** set **`aige_counties_enabled: true`** only when **`TRANSFORM.DEV.FACT_AIGE_COUNTIES`** exists (pretium-ai-dbt clone); re-run tests ( **`fact_aige_counties`** `not_null` tests activate).
