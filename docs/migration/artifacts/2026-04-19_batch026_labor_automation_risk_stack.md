# Batch 026 — Labor / automation risk stack (`T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK` partial)

**Date:** 2026-04-19  
**Canonical doc:** [LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md](../LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md)

## Scope (this batch)

| Area | Status |
|------|--------|
| `SOURCE_PROD.BLS` / `SOURCE_PROD.ONET` sources | Registered (batch 025); used by DOL/Epoch/QCEW models |
| `FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY` | Migrated (batch 025); cognitive NAICS trend consumes this |
| Epoch refs `REF_EPOCH_*` | Ported under `models/transform/dev/pretium_epoch/` |
| DOL / O*NET `FACT_DOL_ONET_SOC_*` | GWA, context friction, SOC AI exposure |
| `REF_ONET_SOC_TO_NAICS` | **Vendor ref** — `source('transform_dev_vendor_ref','ref_onet_soc_to_naics')`; land via `docs/migration/sql/create_ref_onet_soc_to_naics_transform_dev.sql` (no dbt materialization of bridge) |
| `FACT_COUNTY_SOC_EMPLOYMENT` | QCEW 2024 avg × bridge |
| `FACT_COUNTY_AI_REPLACEMENT_RISK` | County scores + trend; geo via `REFERENCE.GEOGRAPHY` (not `h3_canon_block_group`) |
| Parity tests | `equal_rowcount` warn: QCEW vs `cleaned_qcew_county_naics`; county SOC vs legacy `FACT_COUNTY_SOC_EMPLOYMENT` |
| Catalog | `metric.csv` MET_021–MET_028 (prior edits) |

## Still pending (same task ID)

- `FEATURE_AI_REPLACEMENT_RISK_*`, `FEATURE_STRUCTURAL_UNEMPLOYMENT_RISK_COUNTY`, `MART_COUNTY_AI_AUTOMATION_RISK`, `MODEL_COUNTY_AI_RISK_DUAL_INDEX` → **`ANALYTICS.DBT_DEV`** per playbook §3  
- `var('onet_soc_naics_enabled')` guarded empty builds  
- Optional parity: `fact_county_ai_replacement_risk` vs legacy `FACT_COUNTY_AI_REPLACEMENT_RISK`  
- AIGE / `fact_aige_counties` strand (separate vendor path)

## Operator checklist

1. Role: read `SOURCE_PROD.BLS` / `ONET`, read `REFERENCE.GEOGRAPHY` (vintage = `reference_geography_year`), create in `TRANSFORM.DEV`.  
2. Ensure **`TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS`** exists (migration SQL).  
3. From inner project dir: `dbt run --select fact_bls_qcew_county_naics_quarterly fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy fact_county_soc_employment fact_county_ai_replacement_risk`  
4. `dbt test --select` same nodes + parity tests as needed.

## pretium-ai-dbt handoff

After merge, run pretium-ai-dbt **`dbt compile`** / targeted tests on any consumer that will switch refs to semantic-layer `FACT_*` names (coordinate with Alex per `MIGRATION_LOG.md` field guide).
