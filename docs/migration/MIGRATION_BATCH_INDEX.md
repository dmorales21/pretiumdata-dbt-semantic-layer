# Migration batch index — narrative archive

**Purpose:** Hold **verbose** batch notes, artifact paths, and Snowflake evidence so **`MIGRATION_LOG.md`** can stay a **short** audit table. **Append** new batches here in the same PR as `MIGRATION_LOG.md`.

**Short batch table (operator view):** see **`MIGRATION_LOG.md` → Batch History**.

---

## Batch 001 — Zillow pilot + Oxford ref anchor

- **Artifacts:** `artifacts/2026-04-19_batch001_zillow_raw_rowcounts.csv`
- **Scope:** 10 `FACT_*` under `models/transform/dev/zillow`; `REF_OXFORD_METRO_CBSA` count 302; task `T-DEV-REF-OXFORD-METRO-CBSA` migrated.

## Batch 002 — BPS / Census / BLS / LODES phase-1 inventory

- **Artifacts:** `artifacts/2026-04-19_batch002_transform_bps_census_bls_lodes_phase1.csv`
- **Scope:** Row counts BPS, LAUS CBSA/county, LODES OD_BG; BPS dup probe signal; ACS5 deferred.

## Batch 003 — BPS permits county FACT view

- **Artifacts:** `artifacts/2026-04-19_batch003_bps_permits_county_describe.csv`
- **Scope:** `source('transform_bps','permits_county')`, `fact_bps_permits_county` view.

## Batch 004 — BLS LAUS county FACT view

- **Artifacts:** `artifacts/2026-04-19_batch004_bls_laus_county_describe.csv`
- **Scope:** `fact_bls_laus_county` view; row count parity with batch 002.

## Batch 005 — LODES OD_BG + ACS5 describe-only

- **Artifacts:** `artifacts/2026-04-19_batch005_lodes_od_bg_describe.csv`, `artifacts/2026-04-19_batch005_acs5_describe.csv`
- **Scope:** `fact_lodes_od_bg`; ACS5 source registration without full scan FACT.

## Batch 006 — Concept methods FACT priorities (planning)

- **Doc:** `MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md`

## Batch 007 / 007b — Cybersyn HUD + IRS; IRS path → SOURCE_SNOW

- **Scope:** HUD/IRS views; IRS read path fix to `source_snow_us_real_estate`.

## Batch 008 — Oxford AMREG / WDMARCO

- **Scope:** `ref_oxford_metro_cbsa` table; quarterly FACT views; DS_049–050.

## Batch 009 / 009c — FHFA + Freddie; FHFA path fix

- **Scope:** FHFA/Freddie facts; ApartmentIQ/Matrix source YAML; FHFA Cybersyn → US_REAL_ESTATE.

## Batch 010–011 — HUD/IRS/FHFA grain splits + FHFA tier-3

- **Scope:** County/CBSA slices; MET_013–020; DS_084–085.

## Batch 012 / 012b / 012c — Fund OPCO Yardi; §1.5 artifacts; equal_rowcount tests

- **Artifacts:** `artifacts/batch012_yardi/*`
- **Scope:** Yardi FACT ports; governance runbook; BPS/LODES read-through tests.

## Batch 013 — Canonical completion + rent FEATURE spine

- **Docs:** `CANONICAL_COMPLETION_DEFINITION.md`, feature rent market spine.

## Batch 014 — Catalog seed vetting + Cybersyn TSV alignment

**REFERENCE.CATALOG seeds — read + Snowflake vetting (no dbt run in this batch):** Reviewed **`seeds/reference/catalog/`** (metric, dataset, concept, Cybersyn map, bridges, dimension CSVs). Read **`docs/migration/artifacts/cybersyn_global_government_catalog_table_names.tsv`** (351 distinct `table_name` lines + header) for Cybersyn bring-in alignment with **`cybersyn_catalog_table_vendor_map.csv`**. **`snowsql -c pretium`:** `SHOW TABLES IN SCHEMA REFERENCE.CATALOG`; row counts at audit time — **`METRIC` = 7** vs **20 rows in repo `metric.csv`** (MET_001–MET_020) → **drift** (resolved after operator `dbt seed` for `metric`); **`BRIDGE_PRODUCT_TYPE_METRIC` = 0** (seed CSV is header-only — governance gap for `MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md`); **`DATASET` = 78**, **`CYBERSYN_CATALOG_TABLE_VENDOR_MAP` = 353**, **`CONCEPT` = 20**, **`VENDOR` = 50**. The dated **`2026-04-19_batch014_reference_catalog_snowsql_rowcounts.tsv`** artifact was **deleted** as superseded once seeds and Snowflake were reconciled.

## Batch 014b — metric.csv quoting + `frequency.varies`

**Catalog seed fixes (post-operator `dbt test` / `dbt seed` failures):** (1) **`metric.csv`** — unquoted commas inside `definition` and inside **`metric_label`** for county/CBSA variants split rows; wrapped affected fields in RFC4180 double quotes. (2) **`vendor.refresh_cadence`** for **Cybersyn** = **`varies`** failed **`relationships` → `frequency`**; added **`FRQ_006,varies,…`** to **`frequency.csv`** and extended **`accepted_values`** on **`frequency.frequency_code`** in **`schema_data_infrastructure.yml`**. Re-run: `dbt seed --select frequency metric --full-refresh` then `dbt test --select path:seeds/reference/catalog`.

## Batch 014c — Playbook consolidation + labor stack

**Playbook consolidation + estimation contract + labor stack:** New **`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`** (concept vs feature vs model vs estimate; data prep for corridor/SQL ML; **§4 estimation goals**). **Structural unemployment / automation risk** positioned as **`FEATURE_*`** → **`MODEL_*`** with pretium-ai-dbt lineage index + migration task **`T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK`**. **`MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md`** — **Wave G** (labor/automation) + link to consolidated playbook. **`MIGRATION_TASKS.md`** — doc rollup + task row. **`MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md`** — `concept_*` physical home note (**`TRANSFORM.DEV`** / **`MART_*`.`SEMANTIC`**).

## Batch 015 — Dimensional SQL + geography unmapped signal

**Dimensional checks (Snowflake):** Added **`scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`**. **`snowsql -c pretium`** — all **`REFERENCE.CATALOG`** FK-style checks **0 failures**; **`REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX`** rows with **`GEO_LEVEL_CODE = unmapped` → 64,145** (extend **`geo_level`** Cybersyn crosswalk + rebuild geography models). Skipped vendors, migration wave order, xwalk matrix, and last-run check table: **`VENDOR_CONCEPT_COVERAGE_MATRIX.md` §7–8** (consolidated from deleted **`artifacts/VENDOR_SKIPPED_UP_NEXT_XWALK_PRIORITY.md`**).

## Batch 016 — Vendor × concept matrix doc

**Vendor × concept × dataset migration log + source vet:** **`docs/migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md`** — 8 vendors **without** `dataset` rows; concept taxonomy stretch list; vendor cluster next steps; order-of-operations checklist; **`dataset.source_schema`** crosswalk to **`models/sources/*.yml`**. Hub link in **`docs/README.md`**; rollup pointer in **`MIGRATION_TASKS.md`**.

## Batch 017 — metric_derived seed

**`REFERENCE.CATALOG.metric_derived`:** Implemented **`seeds/reference/catalog/metric_derived.csv`** (MDV_001 **`rent_market_monthly_spine`** + illustrative model/estimate rows), **`schema_metric_derived.yml`** (FK + **`dbt_utils.expression_is_true`** layer/dimension guard), **`_catalog.yml`** source entry, **Wave 6c** in **`CATALOG_SEED_ORDER.md`**, hub link in **`docs/README.md`**, **`CATALOG_METRIC_DERIVED_LAYOUT.md`** updated to “implemented”. **`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`** checklist cites **`metric_derived`**. Operator: `dbt seed --select metric_derived` after **`metric`**; `dbt test --select metric_derived`. **Gap (unchanged):** **`bridge_product_type_metric`** still empty; optional follow-on **`metric_derived_input`** per layout §6.

## Batch 018 — Catalog-only vendors SnowSQL vet

**Scope:** **`VENDOR_CATALOG_ONLY_SNOWSQL_VET.md`**, **`scripts/sql/migration/vet_catalog_only_vendors_pretium.sql`**, matrix §G links. See **`MIGRATION_LOG.md`** batch 018 short row for Snowflake evidence summary.

## Batch 019 — Analytics features playbook (plan v5)

**Scope:** **`PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md`** (governance §§A–O: ownership, env, lineage, registration order, Pilot A, macros, PII, outbound index, SIGNALS/MODELS design refs, analytics-engine SoT rule, ADR template, Presley optional, dense concepts §M, market selection §N, four-chain §O). **Design-only:** **`docs/reference/CATALOG_SIGNALS_LAYOUT.md`**, **`CATALOG_MODELS_LAYOUT.md`**. **`docs/migration/ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md`**. **Validation:** **`scripts/sql/validation/README.md`**, **`feature_rent_market_spine_vs_concept_reconciliation.sql`** (Pilot A reconciliation Q; defaults **`TRANSFORM.DEV`** / **`ANALYTICS.DBT_DEV`**; edit literals per env if needed). **`models/analytics/feature/_feature_rent_market.yml`:** `dbt_utils.equal_rowcount` vs **`concept_rent_market_monthly`**, `not_null` on `vendor_code` / `month_start` / `geo_id`. **pretium-ai-dbt:** **`docs/governance/SEMANTIC_LAYER_PLAYBOOK_LINK.md`**, **`docs/README.md`** quick link. **Hub:** **`docs/README.md`**, **`METRIC_INTAKE_CHECKLIST.md`**, **`MIGRATION_RULES.md`**, **`MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`**, **`CATALOG_METRIC_DERIVED_LAYOUT.md`** cross-links. **`dbt parse`** on semantic-layer project exit 0 after test YAML fix.

## Batch 021 — CI catalog gates + compliance vet

- **Workflow:** `.github/workflows/semantic_layer_catalog_and_quality.yml` — **`dbt deps`**, **`dbt parse`**, **`dbt ls --select path:seeds/reference/catalog`** on PRs touching seeds/models/macros. Optional Snowflake job (same file) remains **`if: false`** until repo **`SNOWFLAKE_*`** secrets + **`ci/profiles.yml`** target **`ci`** are wired.
- **Local script:** `scripts/ci/run_catalog_quality_checks.sh` (optional **`RUN_SNOWFLAKE_CHECKS=1`** for seed/test/compile).
- **YAML:** BPS + LODES **`equal_rowcount`** — `compare_model` nested under **`arguments:`** (dbt generic test deprecation).
- **Evidence:** `artifacts/2026-04-19_semantic_layer_quality_gate_results.md` — `dbt test --select path:seeds/reference/catalog` pass summary; **`dimensional_reference_catalog_and_geography.sql`** row counts.

## Batch 025 — SOURCE_PROD BLS QCEW + O*NET vet; `FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY`

- **Artifact:** `artifacts/2026-04-19_batch025_bls_qcew_onet_vet_and_fact.md` — Snowflake row counts (QCEW raw **213,219,014**; O*NET table sizes), geography / dup / employment quality interpretation, `dbt parse` PASS.
- **Code:** `models/sources/sources_source_prod_bls_onet.yml`; `models/transform/dev/bls/fact_bls_qcew_county_naics_quarterly.sql`; `models/transform/dev/bls/schema_bls_qcew.yml`; `scripts/sql/migration/vet_source_prod_bls_qcew_onet_for_workforce_facts.sql`.
- **Next:** `dbt run` + `dbt test` on `fact_bls_qcew_county_naics_quarterly` with warehouse + grants; optional row parity vs pretium-ai-dbt `cleaned_qcew_county_naics`; port O*NET cleanses + Epoch refs per **T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK**.

## Batch 027 — Labor / automation risk: ANALYTICS FEATURE views (county / CBSA / structural)

- **Artifact:** `artifacts/2026-04-19_batch027_labor_automation_feature_views.md`
- **Code:** `models/analytics/feature/feature_ai_replacement_risk_county.sql`, `feature_ai_replacement_risk_cbsa.sql`, `feature_ai_replacement_risk_cbsa_rollup.sql`, `feature_structural_unemployment_risk_county.sql`; `models/analytics/feature/_feature_ai_replacement_risk.yml`.
- **Semantics:** All four read **`ref('fact_county_ai_replacement_risk')`** (or downstream FEATURE refs). **Not** a line-for-line port of pretium `fact_economy_automation_risk` / `fact_household_labor_qcew_naics` CBSA×NAICS incremental logic. **`feature_ai_replacement_risk_cbsa`** exposes synthetic **`naics_code = 'ALL'`** per CBSA×date until a dedicated industry stack exists.
- **Gate:** `dbt_project.yml` var **`onet_soc_naics_enabled`** (default **false** for CI). Local / Snowflake validation: `--vars '{onet_soc_naics_enabled: true}'` after FACT eight-pack (`docs/runbooks/RUN_LABOR_AUTOMATION_RISK_STACK_DBT.md`).
- **Next (post-028):** **`metric_derived`** for FEATURE/MODEL columns; optional parity **fact_county_ai_replacement_risk** vs legacy; native AIGE cleanse if legacy **`FACT_AIGE_COUNTIES`** is retired.

## Batch 028 — Labor / automation risk: bivariate FEATURE, dual-index MODEL, mart, AIGE read path

- **Artifact:** `artifacts/2026-04-20_batch028_labor_ai_p2_p3_model_mart_aige.md`
- **Code:** `models/transform/dev/aige/fact_aige_counties.sql` + `schema_aige.yml`; `models/analytics/feature/feature_ai_risk_county_bivariate.sql` + `_feature_ai_risk_bivariate_p2.yml`; `models/analytics/model/model_county_ai_risk_dual_index.sql` + `_model_ai_risk_labor_p2.yml`; `models/transform/dev/entity/mart_county_ai_automation_risk.sql` + `_mart_county_ai_automation_risk.yml`; `dbt_project.yml` vars **`aige_counties_enabled`** + **`transform.dev.aige`** config path. *(Initial AIGE pass-through via legacy DEV table — superseded by **batch 029**.)*
- **Gate:** **`onet_soc_naics_enabled`** for analytics/mart chain; **`aige_counties_enabled`** for **`fact_aige_counties`** populated from **`SOURCE_PROD.AIGE`** (batch **029**).
- **Next:** P6 **`metric_derived`**; P5 legacy row parity; P7 consumer cutover.

## Batch 026 — Labor / automation risk: O*NET + Epoch + county SOC + county AI replacement (`TRANSFORM.DEV` FACT spine)

- **Artifact:** `artifacts/2026-04-19_batch026_labor_automation_risk_stack.md` — operator checklist, pending FEATURE/MART scope, handoff note.
- **Canonical doc:** `LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md` (object register, dbt paths, vendor ref, geography swap, `dbt` selection).
- **Code:** `models/transform/dev/dol_onet/*` (`fact_dol_onet_soc_gwa_activity_risk`, `fact_dol_onet_soc_context_friction`, `fact_dol_onet_soc_ai_exposure`); `models/transform/dev/pretium_epoch/*`; `models/transform/dev/bls/fact_county_soc_employment.sql`, `fact_county_ai_replacement_risk.sql`; `schema_bls_qcew.yml` (parity warn tests); `sources_transform.yml` → **`transform_dev_vendor_ref.ref_onet_soc_to_naics`**; `sources_transform_dev_legacy.yml` → **`fact_county_soc_employment`** (parity only); removed dbt model `ref_onet_soc_to_naics.sql` (bridge is landed table + source); `docs/migration/sql/create_ref_onet_soc_to_naics_transform_dev.sql`; `dbt_project.yml` `dol_onet` / `pretium_epoch` paths; catalog `metric.csv` MET_026–028; playbook cross-link `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md` §3.
- **Geo:** `fact_county_ai_replacement_risk` uses **`REFERENCE.GEOGRAPHY`** `county`, `state`, `county_cbsa_xwalk` + `reference_geography_year()` instead of pretium **`source('ref','h3_canon_block_group')`**.
- **Next (same task):** ~~Port **`FEATURE_*` / `MODEL_*` / mart** chain~~ → see **batch 027–028**; optional AI-risk row parity; native AIGE ingest per `AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md` if legacy table unavailable.

## Batch 029 — Zero legacy DB in dbt graph (Oxford + AIGE)

- **Log:** `MIGRATION_LOG.md` row **029**.
- **Code:** `models/sources/sources_transform_dev_oxford_ref.yml`; `models/sources/sources_source_prod_aige.yml`; `models/transform/dev/oxford/ref_oxford_metro_cbsa.sql` (reads **`TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK`** only); `models/transform/dev/aige/fact_aige_counties.sql` (unpivot **`SOURCE_PROD.AIGE.AIGE_COUNTIES`**). **Removed:** `models/sources/sources_transform_prod_ref.yml`.
- **Operator SQL:** `docs/migration/sql/land_oxford_cbsa_crosswalk_transform_dev.sql` — one-time land of Oxford crosswalk to **TRANSFORM.DEV** (script may still `SELECT` from **TRANSFORM_PROD**; dbt models do not).
- **Evidence:** `dbt parse` PASS.

## Batch 030 — MIGRATION_PLAN Layer 2: `feature_employment_delta_cbsa_monthly` (LAUS → OMB CBSA)

- **Tracker:** `MIGRATION_LAYER2_EXECUTION_TRACKER.md` — first **P1** FEATURE after labor/rent spine; marks **`feature_economic_momentum_cbsa`** successor (LAUS-only v1).
- **Code:** `models/analytics/feature/feature_employment_delta_cbsa_monthly.sql`, `_feature_employment_delta_cbsa_monthly.yml`.
- **Docs:** `MIGRATION_PLAN.md` (Layer 6 + migration order), `MIGRATION_LOG.md` row **030**, `docs/README.md` hub link to tracker.
- **Evidence:** `dbt parse` PASS.

