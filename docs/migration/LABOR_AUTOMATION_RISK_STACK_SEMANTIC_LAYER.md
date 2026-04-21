# Labor / automation risk stack — semantic layer (`TRANSFORM.DEV`)

**Migration batches:** **026** (FACT spine) — [MIGRATION_LOG.md](./MIGRATION_LOG.md), [MIGRATION_BATCH_INDEX.md](./MIGRATION_BATCH_INDEX.md) §Batch 026, [artifacts/2026-04-19_batch026_labor_automation_risk_stack.md](./artifacts/2026-04-19_batch026_labor_automation_risk_stack.md). **027** (FEATURE views) — §Batch 027, [artifacts/2026-04-19_batch027_labor_automation_feature_views.md](./artifacts/2026-04-19_batch027_labor_automation_feature_views.md).

**Task index:** `T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK` (see [MIGRATION_TASKS.md](./MIGRATION_TASKS.md)).  
**Governance (vendor × concept, upstream chain):** pretium-ai-dbt [AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md](../../../../pretium-ai-dbt/docs/governance/AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md).  
**Stack semantics (FEATURE vs MODEL vs ESTIMATE):** [MODEL_FEATURE_ESTIMATION_PLAYBOOK.md](./MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) §3.

This document is the **canonical** description of what is implemented **in this repo** for county-level AI replacement risk inputs and the county replacement fact. pretium-ai-dbt remains **reference lineage** until those paths are archived.

---

## 1. Snowflake objects (physical)

| Object | Role |
|--------|------|
| `SOURCE_PROD.BLS.QCEW_COUNTY_RAW` | Raw QCEW county quarterly rows. |
| `SOURCE_PROD.ONET.*` | O*NET occupation, GWA, work context. |
| `TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY` | County × NAICS-2 × quarter employment / wages / establishments (dbt: `fact_bls_qcew_county_naics_quarterly`). |
| `TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS` | O*NET SOC × NAICS staffing bridge — **not** built by a dbt model in this repo; **landed** into `TRANSFORM.DEV` and read via `source('transform_dev_vendor_ref', 'ref_onet_soc_to_naics')`. |
| `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | SOC-level GWA activity risk. |
| `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | SOC-level work-context friction. |
| `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | SOC-level exposure + tiers (GWA × friction × Epoch breadth). |
| `TRANSFORM.DEV.REF_EPOCH_TO_GWA_CROSSWALK`, `TRANSFORM.DEV.REF_EPOCH_CAPABILITY_TAXONOMY` | Pretium Epoch pilot refs. |
| `TRANSFORM.DEV.FACT_COUNTY_SOC_EMPLOYMENT` | County × SOC estimated employment / wage bill (QCEW 2024 avg × bridge). |
| `TRANSFORM.DEV.FACT_COUNTY_AI_REPLACEMENT_RISK` | County grain risk scores + cognitive NAICS trend + labels (dbt: `fact_county_ai_replacement_risk`). |
| `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_COUNTY` (view) | County FEATURE from `fact_county_ai_replacement_risk` (gated `onet_soc_naics_enabled`). |
| `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_CBSA` (view) | CBSA × synthetic `naics_code='ALL'` rollup from county fact. |
| `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_CBSA_ROLLUP` (view) | One row per CBSA×date for LDI-style consumers. |
| `ANALYTICS.DBT_DEV.FEATURE_STRUCTURAL_UNEMPLOYMENT_RISK_COUNTY` (view) | IC input; fixed 0.5/0.7 tiers on county score (see FEATURE YAML vs fact percentile `risk_tier`). |

**Policy:** No **TRANSFORM_PROD**, **ANALYTICS_PROD**, or **EDW_PROD** dependency in the **dbt graph** for this stack. The O*NET→NAICS bridge must exist in **`TRANSFORM.DEV`** under the vendor-ref contract (see §3). **Oxford** `ref_oxford_metro_cbsa` reads **`TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK`** only — land with `sql/land_oxford_cbsa_crosswalk_transform_dev.sql`. **AIGE** `fact_aige_counties` reads **`SOURCE_PROD.AIGE.AIGE_COUNTIES`** when **`aige_counties_enabled`** is true.

---

## 2. dbt paths (this repo)

| Model | Path |
|-------|------|
| QCEW fact | `models/transform/dev/bls/fact_bls_qcew_county_naics_quarterly.sql` |
| County × SOC employment | `models/transform/dev/bls/fact_county_soc_employment.sql` |
| DOL / O*NET + Epoch | `models/transform/dev/dol_onet/*.sql`, `models/transform/dev/pretium_epoch/*.sql` |
| County AI replacement risk | `models/transform/dev/bls/fact_county_ai_replacement_risk.sql` |
| FEATURE county / CBSA / structural | `models/analytics/feature/feature_ai_replacement_risk_*.sql`, `feature_structural_unemployment_risk_county.sql`, `_feature_ai_replacement_risk.yml` |

**Tests / parity (warn):** `models/transform/dev/bls/schema_bls_qcew.yml` — QCEW rowcount vs legacy `cleaned_qcew_county_naics`; county SOC rowcount vs legacy `fact_county_soc_employment`.

---

## 3. Landing `REF_ONET_SOC_TO_NAICS` (vendor ref)

dbt reads **`source('transform_dev_vendor_ref', 'ref_onet_soc_to_naics')`** → identifier **`REF_ONET_SOC_TO_NAICS`** in **`TRANSFORM.DEV`**.

- **Script:** [sql/create_ref_onet_soc_to_naics_transform_dev.sql](./sql/create_ref_onet_soc_to_naics_transform_dev.sql) (one-time CTAS patterns; run with a role that can create tables in `TRANSFORM.DEV` and select the chosen upstream).
- **Column contract:** Match pretium-ai-dbt `ref_onet_soc_to_naics` / `fact_county_soc_employment` expectations (at minimum `onet_soc_code`, `occupation_title`, `naics_code`, `employment_share`, `naics_level`).

There is **no** `ref_onet_soc_to_naics` dbt model: the table is **operator-landed** or copied from a governed export, same pattern as [create_ref_zillow_metro_to_cbsa.sql](./sql/create_ref_zillow_metro_to_cbsa.sql).

---

## 4. Geography (county names, state, CBSA)

**Legacy pretium-ai-dbt** used `source('ref', 'h3_canon_block_group')` for county names and modal CBSA from block groups.

**Semantic layer** uses **`REFERENCE.GEOGRAPHY`** only:

- `source('reference_geography', 'county')` + `state` — county name, state FIPS, state name (`reference_geography_year()` / var `reference_geography_year`, default 2024).
- `source('reference_geography', 'county_cbsa_xwalk')` — primary CBSA per county with the same tie-break ordering as pretium `dim_geo_county_cbsa` (non-null CBSA first, then name, then code). Rows where CBSA code equals county FIPS are treated as non-metro (null CBSA on output), consistent with the legacy dim.

---

## 5. Cognitive NAICS “8Q” trend inside `fact_county_ai_replacement_risk`

Employment trend for NAICS **51, 52, 54, 55, 56** is computed from **`fact_bls_qcew_county_naics_quarterly`** (not a separate `cleaned_qcew` model). Logic matches pretium-ai-dbt `fact_county_ai_replacement_risk.sql` (≥6 distinct quarters, oldest vs latest `date_reference`).

---

## 6. Catalog metrics (optional)

Base metrics for QCEW grain and O*NET exposure columns live in `seeds/reference/catalog/metric.csv` (e.g. MET_021–MET_028). Extend per [METRIC_INTAKE_CHECKLIST.md](./METRIC_INTAKE_CHECKLIST.md) when publishing new **`FACT_COUNTY_AI_REPLACEMENT_RISK`** columns.

---

## 7. Suggested `dbt` selection (local)

From the **inner** project directory (where `dbt_project.yml` lives):

```bash
cd /path/to/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
dbt run --select fact_bls_qcew_county_naics_quarterly fact_county_soc_employment fact_dol_onet_soc_gwa_activity_risk fact_dol_onet_soc_context_friction fact_dol_onet_soc_ai_exposure fact_county_ai_replacement_risk
dbt test --select fact_bls_qcew_county_naics_quarterly fact_county_soc_employment fact_county_ai_replacement_risk

# FEATURE views (set var true after FACT spine + REF_ONET_SOC_TO_NAICS exist):
dbt run --select feature_ai_replacement_risk_county feature_ai_replacement_risk_cbsa feature_ai_replacement_risk_cbsa_rollup feature_structural_unemployment_risk_county --vars '{onet_soc_naics_enabled: true}'
dbt test --select feature_ai_replacement_risk_county feature_ai_replacement_risk_cbsa feature_ai_replacement_risk_cbsa_rollup feature_structural_unemployment_risk_county --vars '{onet_soc_naics_enabled: true}'
```

Prerequisites: Snowflake grants on `SOURCE_PROD.BLS` / `SOURCE_PROD.ONET`, `REFERENCE.GEOGRAPHY` vintages for `reference_geography_year`, create rights on `TRANSFORM.DEV`, and a populated **`TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS`** (§3).

---

## 8. Next migrations (after validated FACT spine)

**FACT spine status:** Eight models (`fact_bls_qcew_*`, Epoch refs, three `fact_dol_onet_soc_*`, `fact_county_soc_employment`, `fact_county_ai_replacement_risk`) are the minimal dbt graph for county replacement risk; upstreams are **sources** + landed **`REF_ONET_SOC_TO_NAICS`**. Preflight: `scripts/sql/migration/vet_source_prod_bls_qcew_onet_for_workforce_facts.sql` + `vet_labor_stack_reference_geography_and_vendor_ref.sql`; runbook: [../runbooks/RUN_LABOR_AUTOMATION_RISK_STACK_DBT.md](../runbooks/RUN_LABOR_AUTOMATION_RISK_STACK_DBT.md).

| Priority | Work | Notes |
|----------|------|--------|
| P1 | **Port `FEATURE_*` (batch 027 — partial)** — `feature_ai_replacement_risk_county`, `feature_ai_replacement_risk_cbsa`, `feature_ai_replacement_risk_cbsa_rollup`, `feature_structural_unemployment_risk_county` | **Shipped:** `models/analytics/feature/*.sql` + `_feature_ai_replacement_risk.yml`; **`onet_soc_naics_enabled`** gates empty builds. **Not yet parity** with legacy pretium CBSA×NAICS incremental (`fact_household_labor_qcew_naics` + `fact_economy_automation_risk`); CBSA model uses **`naics_code='ALL'`** until that stack exists. **`metric_derived`** for FEATURE columns still open. |
| P2 | **Port `MODEL_*` / county FACT** — `model_county_ai_risk_dual_index`, `fact_county_ai_automation_risk` (and EDW delivery views if in scope) | Consumes FEATURE + `fact_aige_counties` / AIGE path when dual-index is required; align with pretium [AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md](../../../../pretium-ai-dbt/docs/governance/AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md) §2–3. |
| P3 | **`fact_aige_counties`** + `SOURCE_PROD.AIGE` (or agreed landing) | Separate vendor strand; governance doc §2. |
| P4 | **Optional stricter guards** when bridge or O*NET reads fail at compile-time | **`onet_soc_naics_enabled`** + empty `WHERE 1=0` branches cover “downstream must not break”; extend if CI needs parse without `REF_ONET_SOC_TO_NAICS` present. |
| P5 | **Optional parity** — `dbt_utils.equal_rowcount` warn: `fact_county_ai_replacement_risk` vs legacy `FACT_COUNTY_AI_REPLACEMENT_RISK` | Add `transform_dev_legacy_pretium_ai` source + test in `schema_bls_qcew.yml` (same pattern as county SOC). |
| P6 | **Catalog** — `metric` / `metric_derived` for published **FEATURE_** / **MODEL_** columns | [METRIC_INTAKE_CHECKLIST.md](./METRIC_INTAKE_CHECKLIST.md); extend MET_* for county risk outputs as consumers require. |
| P7 | **Consumers** — retarget strata / tearsheet / BI from legacy `TRANSFORM.DEV` / `ANALYTICS` names to canonical `ref()` / `source()` | Then log **Deprecation candidates** in [MIGRATION_LOG.md](./MIGRATION_LOG.md) §2A. |

- Epoch **public model registry** / `SOURCE_PROD.EPOCH_AI` (optional) remains a **separate** strand unless explicitly joined (governance §0).
