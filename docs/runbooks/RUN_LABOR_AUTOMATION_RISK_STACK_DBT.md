# Run + test — labor / automation risk stack (`TRANSFORM.DEV`)

Copy the **Cursor prompt** block into **pretiumsemantic** (or any agent) when that repo should drive validation of the canonical semantic-layer project.

---

## SnowSQL preflight (optional, recommended before first `dbt run`)

From the **inner** repo root (`pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/`):

```bash
snowsql -c pretium -f scripts/sql/migration/vet_source_prod_bls_qcew_onet_for_workforce_facts.sql
snowsql -c pretium -f scripts/sql/migration/vet_labor_stack_reference_geography_and_vendor_ref.sql
```

| Script | What it checks |
|--------|----------------|
| `vet_source_prod_bls_qcew_onet_for_workforce_facts.sql` | `SOURCE_PROD.BLS.QCEW_COUNTY_RAW` row count; **VARIANT** sample probes **B** (strict 5-digit county FIPS failures) and **D** (null/non-positive employment) — **large B/D in the 1M-row sample are expected noise** (CBSA codes, state totals, disclosure rows); see script header. O*NET table row counts. |
| `vet_labor_stack_reference_geography_and_vendor_ref.sql` | `REFERENCE.GEOGRAPHY.COUNTY` / `STATE` / `COUNTY_CBSA_XWALK` (YEAR=2024); **`TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS`** row count. |

**Exit 0** on both scripts ⇒ account is unblocked for BLS + ONET + geography + landed bridge (same assumptions as `docs/migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`).

---

## Cursor prompt (paste into pretiumsemantic)

```text
You are validating the labor / automation risk dbt pipeline that lives in the canonical repo **pretiumdata-dbt-semantic-layer** (inner project path ends with `pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/` where `dbt_project.yml` lives — NOT the monorepo root).

Goals:
1. Load Snowflake credentials the same way this team usually does (e.g. `set -a && source ../pretium-ai-dbt/.env && set +a` from the inner project dir if that file exists and contains `SNOWFLAKE_*` / profiles targets).
2. From the **inner** directory, run `dbt parse` then build and test the labor stack nodes.
3. Report PASS/FAIL per model and per test; if anything fails, show the first actionable error (SQL compilation, missing table, grants).

Prerequisites (verify or state BLOCKED):
- Snowflake role can **SELECT** `SOURCE_PROD.BLS.QCEW_COUNTY_RAW`, `SOURCE_PROD.ONET` tables used by the stack (`OCCUPATION_BASE`, `WORK_ACTIVITIES_GENERAL`, `WORK_CONTEXT`), and **REFERENCE.GEOGRAPHY** (`COUNTY`, `STATE`, `COUNTY_CBSA_XWALK`) for the vintage in `var('reference_geography_year', 2024)`.
- Role can **CREATE** tables/views in **TRANSFORM.DEV**.
- Physical table **`TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS`** exists and is readable (dbt reads it only via `source('transform_dev_vendor_ref','ref_onet_soc_to_naics')`). If missing, operator must run the one-time script described in `docs/migration/sql/create_ref_onet_soc_to_naics_transform_dev.sql` (see `docs/migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`).

Commands to execute (inner project root):

  dbt parse

  dbt run --select \
    fact_bls_qcew_county_naics_quarterly \
    ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy \
    fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure \
    fact_county_soc_employment fact_county_ai_replacement_risk

  dbt test --select \
    fact_bls_qcew_county_naics_quarterly \
    ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy \
    fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure \
    fact_county_soc_employment fact_county_ai_replacement_risk

Optional (parity tests are attached to these models; they use `severity: warn` in YAML but **PASS** when legacy `TRANSFORM.DEV` tables match):

  dbt test --select fact_bls_qcew_county_naics_quarterly fact_county_soc_employment

Success criteria: `dbt run` completes with no ERROR; `dbt test` completes with **0 ERROR**; parity tests may **WARN** if legacy row counts differ — report WARN vs ERROR explicitly. *(Validated run: eight models, 34 tests PASS, 0 WARN / 0 ERROR when legacy parity tables align.)*

After FACT validation, repeat **`dbt run` / `dbt test`** for the four **FEATURE_** models with **`--vars '{onet_soc_naics_enabled: true}'`** (see **“ANALYTICS FEATURE views”** below); otherwise FEATURE tests are **disabled** (default var `false`).

Canonical documentation: `docs/migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`; migration batch **026**: `docs/migration/MIGRATION_LOG.md`, `docs/migration/artifacts/2026-04-19_batch026_labor_automation_risk_stack.md`.
```

---

## ANALYTICS FEATURE views (county / CBSA / structural)

After the eight **TRANSFORM.DEV** models exist, set **`onet_soc_naics_enabled: true`** (dbt var) so **FEATURE_** views materialize non-empty rows and data tests run.

```bash
dbt run --select \
  fact_bls_qcew_county_naics_quarterly \
  ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy \
  fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure \
  fact_county_soc_employment fact_county_ai_replacement_risk \
  feature_ai_replacement_risk_county feature_ai_replacement_risk_cbsa feature_ai_replacement_risk_cbsa_rollup \
  feature_structural_unemployment_risk_county \
  --vars '{onet_soc_naics_enabled: true}'

dbt test --select \
  feature_ai_replacement_risk_county feature_ai_replacement_risk_cbsa feature_ai_replacement_risk_cbsa_rollup \
  feature_structural_unemployment_risk_county \
  --vars '{onet_soc_naics_enabled: true}'
```

**Semantics vs pretium-ai-dbt `analytics_prod/features`:** these FEATUREs read **`fact_county_ai_replacement_risk`** (new stack), not `fact_economy_automation_risk` / `fact_household_labor_qcew_naics`. **`feature_ai_replacement_risk_cbsa`** uses synthetic **`naics_code = 'ALL'`** per CBSA×date until a real CBSA×NAICS industry feature is ported.

---

## P2 / P3 — bivariate FEATURE, dual-index MODEL, mart, AIGE fact (batch **028**)

After P1 FEATUREs validate, build the **bivariate** spine, **MODEL** dual index, **mart**, and the **AIGE** pass-through fact.

| Var | Default | When to set `true` |
|-----|---------|---------------------|
| `onet_soc_naics_enabled` | `false` | Same as P1 — FACT + labor analytics. |
| `aige_counties_enabled` | `false` | Set `true` when **`SOURCE_PROD.AIGE.AIGE_COUNTIES`** is populated and the role can SELECT it; `fact_aige_counties` unpivots VARIANT in dbt (no legacy **TRANSFORM.DEV** clone). |

```bash
# Minimal chain (O*NET-only dual index — AIGE strand null):
dbt run --select \
  fact_aige_counties \
  fact_bls_qcew_county_naics_quarterly ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy \
  fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure \
  fact_county_soc_employment fact_county_ai_replacement_risk \
  feature_ai_replacement_risk_county feature_structural_unemployment_risk_county \
  feature_ai_risk_county_bivariate model_county_ai_risk_dual_index mart_county_ai_automation_risk \
  --vars '{"onet_soc_naics_enabled": true}'

dbt test --select \
  fact_aige_counties feature_ai_risk_county_bivariate model_county_ai_risk_dual_index mart_county_ai_automation_risk \
  --vars '{"onet_soc_naics_enabled": true}'
```

**Dual AIGE + O*NET strands:** add **`aige_counties_enabled: true`** to the same `--vars` JSON once **SOURCE_PROD.AIGE** grants are in place.

Canonical detail: [LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md](../migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md); artifact [2026-04-20_batch028_labor_ai_p2_p3_model_mart_aige.md](../migration/artifacts/2026-04-20_batch028_labor_ai_p2_p3_model_mart_aige.md).

---

## Same commands (human operator)

```bash
cd /path/to/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
test -f /path/to/pretium-ai-dbt/.env && set -a && . /path/to/pretium-ai-dbt/.env && set +a

dbt parse

dbt run --select \
  fact_bls_qcew_county_naics_quarterly \
  ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy \
  fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure \
  fact_county_soc_employment fact_county_ai_replacement_risk

dbt test --select \
  fact_bls_qcew_county_naics_quarterly \
  ref_epoch_to_gwa_crosswalk ref_epoch_capability_taxonomy \
  fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure \
  fact_county_soc_employment fact_county_ai_replacement_risk
```

Adjust `.env` path to your machine. Add **`--vars '{onet_soc_naics_enabled: true}'`** when building and testing the four **FEATURE_** models (see section above).
