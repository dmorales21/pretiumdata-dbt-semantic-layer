# Schema alignment plan — PITI / place / unemployment / Deephaven

**Purpose:** Single checklist aligning **Snowflake landings**, **`TRANSFORM_PROD`** (pretium-ai-dbt), **`TRANSFORM.DEV`** (this repo), **`CONCEPT_*` contracts**, and **`REFERENCE.CATALOG`** (`metric.csv` / `dataset.csv`).  
**Status legend:** **✅** accomplished · **🟨** partial / in flight · **⬜** not started  
**Closure:** Batch closure still follows [`CANONICAL_COMPLETION_DEFINITION.md`](./CANONICAL_COMPLETION_DEFINITION.md) and [`MIGRATION_TASKS.md`](./MIGRATION_TASKS.md).

---

## 1. Source vetting (`snowsql -c pretium`)

| Task | Status |
|------|--------|
| Row counts: `SOURCE_PROD.BANKRATE.INSURANCE_STATE`, `QUADRANT.INSURANCE_STATE_RATES`, `TAX_FOUNDATION.PROPERTY_TAXES_BY_COUNTY_2025`, `SOURCE_ENTITY.DEEPHAVEN.DEEPHAVEN_PROPERTIES` | ✅ |
| Column inventory via `INFORMATION_SCHEMA.COLUMNS` for the four objects above | ✅ |
| Runnable vet script maintained in **pretium-ai-dbt** `scripts/sql/governance/vet_piti_place_and_unemployment_lineage_pretium.sql` (cross-repo operator artifact) | ✅ |
| Uncomment §C in that script and validate `REFERENCE.CATALOG.METRIC` rows for `concept_code = unemployment` (account-dependent) | ⬜ |
| Optional: schedule / CI step to run vet SQL on a cadence | ⬜ |

---

## 2. pretium-ai-dbt — `TRANSFORM_PROD` cleaned / fact parity

| Task | Status |
|------|--------|
| `cleaned_deephaven_properties`: CBSA title from `dim_cbsa`; `NULLIF`/`LPAD` hardening on raw CBSA | ✅ |
| `fact_footprint_deephaven_properties`: `geo_id` / `geo_level_code` consistent (CBSA vs ZIP); row filter | ✅ |
| `fact_insurance_state`: emit `geo_level_code = 'STATE'` (match `schema.yml`) | ✅ |
| DC / district naming aliases on Bankrate, Quadrant, Tax Foundation cleaned models | ✅ |
| `docs/governance/CLEANED_TO_FACT_SPEC.yml` — `cleaned_deephaven_properties` sources / fact columns | ✅ |
| `dbt build --select` the touched `transform_prod` models in Snowflake (env + role) | ⬜ |
| Decide sunset: when semantic-layer is SoT, stop extending duplicate logic on **TRANSFORM_PROD** for these vendors | ⬜ |

---

## 3. pretiumdata-dbt-semantic-layer — `TRANSFORM.DEV` facts (no `TRANSFORM_PROD` in graph)

| Task | Status |
|------|--------|
| `models/sources/sources_source_entity_deephaven.yml` | ✅ |
| `models/sources/sources_source_prod_piti_place.yml` (Bankrate, Quadrant, Tax Foundation) | ✅ |
| `dbt_project.yml` — `transform.dev` config for `deephaven`, `insurance`, `tax_foundation` | ✅ |
| `models/transform/dev/deephaven/cleaned_deephaven_properties.sql` + `fact_footprint_deephaven_properties.sql` | ✅ |
| `models/transform/dev/insurance/cleaned_bankrate_insurance_state.sql`, `cleaned_quadrant_insurance_state_rates.sql`, `fact_insurance_state.sql` | ✅ |
| `models/transform/dev/tax_foundation/tax_foundation_property_taxes_by_county.sql`, `fact_property_tax_by_county.sql` | ✅ |
| `models/transform/dev/deephaven/schema.yml`, `insurance/schema.yml`, `tax_foundation/schema.yml` | ✅ |
| `models/transform/dev/README.md` — folder bullets | ✅ |
| Local `dbt compile` / `dbt parse` for the migrated node set | ✅ |
| Snowflake `dbt run` + warehouse role grants on **SOURCE_*** / **TRANSFORM.REF** / **REFERENCE.GEOGRAPHY** | ⬜ |
| Bounded parity vs **TRANSFORM_PROD** (row counts + key sample hash / diff) | ⬜ |
| Append **MIGRATION_LOG.md** / **MIGRATION_BATCH_INDEX.md** per repo process | ⬜ |

---

## 4. Concept layer — wide `CONCEPT_*` vs tall catalog row

**Target tall row (product / tool example):**  
`concept_code`, `vendor_code`, `dataset_code`, `metric_code`, `geo_level_code`, `geo_id`, `date_start`, `date_end`, `date_publish`, `frequency_code`, `value`

**Current `CONCEPT_*` pattern (e.g. `concept_unemployment_market_monthly`):**  
`concept_code`, `vendor_code`, `month_start`, `geo_level_code`, `geo_id`, `metric_id_observe`, plus wide slots from `concept_metric_slot` (e.g. `unemployment_current`, `unemployment_historical`, …).

| Task | Status |
|------|--------|
| Written gap analysis (tall vs wide + BLS LAUS vs Census ACS for “unemployment”) — see prior engineering notes / vet script header | ✅ |
| ADR or short doc: choose **(a)** tall export view, **(b)** new `concept_*_long` tables, or **(c)** extend wide schema with publish / dataset columns | ⬜ |
| `CONCEPT_*` for **insurance** and **property tax** reading `FACT_INSURANCE_STATE` / `FACT_PROPERTY_TAX_BY_COUNTY` | ⬜ |
| `metric.csv` / `dataset.csv` registrations for every emitted measure (`metric_code`, `table_path`, `snowflake_column`, `frequency_code`, …) | ⬜ |
| `schema.yml` + tests for new concept models ([`QA_CONCEPT_PREFLIGHT_CHECKLIST.md`](./QA_CONCEPT_PREFLIGHT_CHECKLIST.md) §B) | ⬜ |
| Optional: **Census ACS5** unemployment branch at county/CBSA vs today’s **BLS LAUS**-only `concept_unemployment_market_monthly` | ⬜ |

---

## 5. Deephaven — beyond OpCo footprint

| Task | Status |
|------|--------|
| Footprint path: property_id + ZIP + CBSA + title + `FACT_FOOTPRINT_DEEPHAVEN_PROPERTIES` | 🟨 (footprint only; semantic + pretium-ai-dbt) |
| Product-driven column list from `DEEPHAVEN_PROPERTIES` (33+ cols + VARIANT) for additional facts / concepts | ⬜ |
| `SHAREDFUNDINGDATA` / other feeds: land or explicitly exclude in vendor matrix | ⬜ |
| EDW / `opco_property_presence`: consume semantic-layer cleaned when cut over | ⬜ |

---

## 6. Governance matrix

| Task | Status |
|------|--------|
| Update [`VENDOR_CONCEPT_COVERAGE_MATRIX.md`](./VENDOR_CONCEPT_COVERAGE_MATRIX.md) for Bankrate / Quadrant / Tax Foundation / Deephaven | ⬜ |
| Align **use_cases** / **datasets** CSVs in pretium-ai-dbt `docs/governance/` with semantic-layer catalog seeds (no drift) | ⬜ |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-22 | Initial plan: task list with accomplishment decoration (✅ / 🟨 / ⬜). |
