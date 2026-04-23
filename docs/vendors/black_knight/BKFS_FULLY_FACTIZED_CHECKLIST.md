# BKFS: What’s Needed to Fully Factize This Data

**Purpose**: Checklist to bring BKFS data to the same “fully factized” standard as Cherre (canonical metrics, catalog, governance, contract compliance).  
**References**: DATABASE_CONTRACT.md §1.3, FACT_LAYERS_SCOPE.md, FACT_LAYER_METRIC_CONTRACTS.yml, BKFS_INTEGRATION_RUNBOOK.md.

---

## 1. Already in place

| Item | Status | Notes |
|------|--------|------|
| **Cleaned layer** | Done | `cleaned_bkfs_loan`, `cleaned_bkfs_loanmonth_ts`, `cleaned_bkfs_property` |
| **Fact tables** | Done | `fact_bkfs_loan_characteristics` (incremental), `fact_bkfs_loan_performance` (view) |
| **Canonical BKFS table** | Done | `capital_cap_debt_bkfs` unions both fact models into capital-debt union schema |
| **Union with Cherre** | Done | `capital_cap_debt_all_ts` includes BKFS via `capital_cap_debt_bkfs` |
| **DIM_METRIC registration** | Script ready | `sql/admin/catalog/register_bkfs_fact_metrics.sql` — run once in Snowflake to populate ADMIN.CATALOG.DIM_METRIC |
| **Optional catalog** | Done | Both fact models use `admin_catalog_available` for GEO_KEY and METRIC_ID (synthetic when false) |
| **Segment columns in union** | Done | `product_type_code`, `tenancy_code`, `bedrooms` in union; BKFS = NULL until source supports |
| **Contract docs** | Done | FACT_LAYER_METRIC_CONTRACTS.yml, schema.yml (columns + relationship tests defined) |
| **Run order** | Documented | BKFS_INTEGRATION_RUNBOOK.md Phase 5: cleaned → fact → capital_cap_debt_bkfs |

---

## 2. Gaps to fully factize

### 2.1 DATABASE_CONTRACT §1.3 (FACT layer required fields) — ✅ Done

The contract requires these on fact models where applicable:

| Field | Required | BKFS fact tables today | Status |
|-------|----------|-------------------------|--------|
| `date_reference` | Yes | Present | ✅ |
| `geo_id` | Yes | Present | ✅ |
| `geo_level` | Yes | Present as GEO_LEVEL_CODE | ✅ |
| `quality_flag` | Yes | **Added** | ✅ 'VALID' |
| `completeness_pct` | Yes | **Added** | ✅ 1.0 |
| `data_quality_tier` | Yes | **Added** | ✅ 'TIER_1' |
| `vendor_name` | Yes | Present | ✅ |
| `source_table` | Yes | **Added** | ✅ 'cleaned_bkfs_loan' / 'cleaned_bkfs_loanmonth_ts' |
| `load_timestamp` | Yes | **Added** | ✅ CURRENT_TIMESTAMP() |

**Done**: Both `fact_bkfs_loan_characteristics` and `fact_bkfs_loan_performance` now include these contract fields. Schema.yml documents the new columns.

---

### 2.2 Catalog (ADMIN.CATALOG) and relationship tests

| Item | Status | Action |
|------|--------|--------|
| **DIM_METRIC** | Script exists; must be run | Execute `sql/admin/catalog/register_bkfs_fact_metrics.sql` in Snowflake (once). Ensures all BKFS fact metric IDs exist in DIM_METRIC. |
| **DIM_GEOGRAPHY** | Populated separately | GEO_KEYs from BKFS (ZIP/state) must exist in DIM_GEOGRAPHY for relationship tests and for “no orphan GEO_KEY” contract. Backfill ZIP/state from BKFS into DIM_GEOGRAPHY if not already present. |
| **Var `admin_catalog_available`** | Default false | Set to `true` in profile/target when catalog is populated so fact models use DIM_GEOGRAPHY/DIM_METRIC and relationship tests can run. |
| **dbt relationship tests** | In schema.yml | `fact_bkfs_loan_characteristics` and `fact_bkfs_loan_performance` have relationships to `source('admin_catalog', 'dim_metric')` and `source('admin_catalog', 'dim_geography')`. These pass only when catalog is populated and `admin_catalog_available` is true. |

**Action**: Run the BKFS DIM_METRIC script; ensure DIM_GEOGRAPHY has BKFS geographies; set `admin_catalog_available: true` and run `dbt test --select fact_bkfs_loan_characteristics fact_bkfs_loan_performance`.

---

### 2.3 Governance (post-hooks and lineage) — ✅ Done

| Item | Cherre / union pattern | BKFS fact today | Status |
|------|-------------------------|------------------|--------|
| **extract_governance_metrics** | Used on `capital_cap_debt_all_ts` | **Added** to both BKFS fact models (CAPITAL_CAP_DEBT) | ✅ |
| **register_fact_governance** | Used on some housing fact models | **Added** to both BKFS fact models (BKFS, HIGH sensitivity) | ✅ |
| **Governance in union** | `capital_cap_debt_all_ts` has quality_data + governance_enriched | BKFS feeds union; fact-level hooks now run | ✅ |

**Done**: Both BKFS fact models have `post_hook` with `extract_governance_metrics(this, 'CAPITAL_CAP_DEBT')` and `register_fact_governance(..., 'BKFS', ..., 'HIGH', description)`.

---

### 2.4 Product type / tenancy / bedrooms (segment alignment)

| Item | Status | Action |
|------|--------|--------|
| **Union schema** | `capital_cap_debt_all_ts` has product_type_code, tenancy_code, bedrooms; BKFS branch passes NULL | — |
| **Decode from BKFS** | Not implemented | When product/occupancy/loan-type mappings are defined (or in catalog), derive product_type_code / tenancy_code / bedrooms in fact or in `capital_cap_debt_bkfs` and stop passing NULL. |

**Action**: Document or implement mapping from BKFS product/occupancy/loan type to product_type_code, tenancy_code, bedrooms when source or catalog supports it.

---

### 2.5 Materialization and scale

| Item | Status | Action |
|------|--------|--------|
| **fact_bkfs_loan_performance** | Materialized as **view** | For large production volumes, consider switching to `materialized='incremental'` with the same unique_key/merge pattern as characteristics, and run incremental runs. |
| **fact_bkfs_loan_characteristics** | Incremental merge | — |

**Action**: If view becomes a bottleneck, change `fact_bkfs_loan_performance` to incremental and add appropriate incremental predicates.

---

### 2.6 ID_CBSA in canonical/union

| Item | Status | Action |
|------|--------|--------|
| **capital_cap_debt_bkfs** | Passes `NULL AS ID_CBSA` | When CBSA is available (e.g. from cleaned or DIM_GEOGRAPHY), select it and pass through so union has CBSA for BKFS. |

**Action**: Backfill ID_CBSA in cleaned or fact when geography lookup supports it; then expose in `capital_cap_debt_bkfs`.

---

## 3. Summary: minimum to “fully factize”

1. **Contract** — ✅ Done: `quality_flag`, `completeness_pct`, `data_quality_tier`, `source_table`, `load_timestamp` added to both BKFS fact models.
2. **Catalog**: Run `register_bkfs_fact_metrics.sql` in Snowflake; ensure DIM_GEOGRAPHY has BKFS geos; set `admin_catalog_available: true` and run relationship tests.
3. **Governance** — ✅ Done: Fact-level post_hooks (extract_governance_metrics, register_fact_governance) added to both BKFS fact models.
4. **Segments** (optional): Add product_type_code / tenancy_code / bedrooms for BKFS when mappings exist.
5. **Scale** (optional): Switch `fact_bkfs_loan_performance` to incremental if the view does not meet performance requirements.
6. **CBSA** (optional): Populate ID_CBSA for BKFS in canonical/union when geography supports it.

---

## 4. Quick reference

- **Run pipeline**: `dbt run --select cleaned_bkfs_loan+` or `dbt run --select fact_bkfs_loan_characteristics fact_bkfs_loan_performance capital_cap_debt_bkfs`
- **Register metrics**: Execute `sql/admin/catalog/register_bkfs_fact_metrics.sql` in Snowflake (once).
- **Test (with catalog)**: `dbt test --select fact_bkfs_loan_characteristics fact_bkfs_loan_performance`
- **Contract**: docs/rules/contracts/DATABASE_CONTRACT.md §1.3  
- **Scope**: docs/architecture/FACT_LAYERS_SCOPE.md  
- **Runbook**: docs/vendors/black_knight/BKFS_INTEGRATION_RUNBOOK.md  
