# Fund OPCO — Yardi facts in `TRANSFORM.DEV`

Ported from pretium-ai-dbt `dbt/models/transform/dev/fund_opco/` with the same naming and column contract.

## Models

| Model | Snowflake object (alias) | Grain |
|-------|--------------------------|--------|
| `fact_progress_yardi_property` | `FACT_PROGRESS_YARDI_PROPERTY` | One row per property (current state) |
| `fact_bh_yardi_property` | `FACT_BH_YARDI_PROPERTY` | One row per property (BH) |
| `fact_progress_yardi_unit` | `FACT_PROGRESS_YARDI_UNIT` | One row per unit |
| `fact_bh_yardi_unit` | `FACT_BH_YARDI_UNIT` | One row per unit (BH) |
| `fact_progress_yardi_ledger` | `FACT_PROGRESS_YARDI_LEDGER` | One row per transaction |
| `fact_bh_yardi_ledger` | `FACT_BH_YARDI_LEDGER` | One row per transaction (BH) |

## Refresh metadata (in-table)

Each fact includes:

- **`vendor_time_grain`** — `SNAPSHOT` (property/unit) or `EVENT` (ledger).
- **`expected_source_refresh_frequency`** — `DAILY` (typical silver/share cadence; operational expectation, not an SLA).

**Why not `*_property_daily`?** `_daily` suffixes are for facts whose **grain** includes a calendar date (e.g. `(entity_id, as_of_date)`). Property/unit masters here are **current-state snapshots**. True daily history would be a separate model (e.g. `fact_progress_yardi_property_daily` with `as_of_date`).

## SOURCE_ENTITY.PROGRESS — Salesforce + Yardi entity read-throughs

**Jon silver (above)** reads **`TRANSFORM.YARDI`**. **Fund modeling CRM / entity mirrors** read **`SOURCE_ENTITY.PROGRESS`** via `source('source_entity_progress', …)`:

- **`fact_sfdc_*` models (15)** — Salesforce custom objects (fund, pipeline, portfolio, acquisition, disposition, properties, …). Declared in **`models/sources/sources_source_entity_progress.yml`**.
- **`fact_se_yardi_*` models (15)** — Yardi objects landed on **SOURCE_ENTITY.PROGRESS**. **`se`** = **S**ource **E**ntity (this lineage), not Jon silver on **`TRANSFORM.YARDI`**. Model names follow **purpose** (e.g. **`fact_se_yardi_gl_period_total`** for **YARDI_GLTOTAL**), not raw landing abbreviations. **Not** the same as **`fact_progress_yardi_*` / `fact_bh_yardi_*`**.

All are **`materialized: view`**, **`SELECT *`**, tagged **`source_entity_progress_fact`**, gated by:

- **`transform_dev_enable_source_entity_progress_facts`** (default **`false`**) — set **`true`** after grants and **`vet_source_entity_progress_fund_objects.sql`** (pretium-ai-dbt) pass.
- **`source_entity_progress_schema`** (default **`PROGRESS`**) — override if your account uses a different schema name.

**dbt selection:** dbt **does not** treat `fact_sfdc_*` / `fact_se_yardi_*` as name globs — use **`tag:source_entity_progress_fact`** or **`dbt run --selector source_entity_progress_facts`** (repo **`selectors.yml`**), with **`--vars '{"transform_dev_enable_source_entity_progress_facts": true}'`** so models are **enabled**.

```bash
dbt run --select tag:source_entity_progress_fact \
  --vars '{"transform_dev_enable_source_entity_progress_facts": true}'
```

**Naming (`fact_se_yardi_*`):** **`se`** = **S**ource **E**ntity (**SOURCE_ENTITY.PROGRESS**), distinct from **`fact_progress_yardi_*`** / **`fact_bh_yardi_*`** on **TRANSFORM.YARDI** Jon silver. Suffix = **analytic purpose**, not the raw Yardi table abbreviation:

| SOURCE_ENTITY table | dbt model (TRANSFORM.DEV alias) | Purpose |
|---------------------|----------------------------------|---------|
| **YARDI_SEGMENTS** | `fact_se_yardi_strategy_segment` | Strategy / segment taxonomy (allocate) |
| **YARDI_PROPATTRIBUTES** | `fact_se_yardi_property_attribute` | Property attributes / risk inputs |
| **YARDI_GLTOTAL** | `fact_se_yardi_gl_period_total` | GL period rollups (returns) |
| **YARDI_GLDETAIL** | `fact_se_yardi_gl_line_detail` | GL line detail |
| **YARDI_TRANS** | `fact_se_yardi_cash_ledger_transaction` | Ledger-style cash transactions (entity path) |
| **YARDI_DETAIL** | `fact_se_yardi_charge_payment_detail` | Charge / payment lines |
| **YARDI_ACCTTREE** | `fact_se_yardi_gl_account_hierarchy` | Chart of accounts |
| **YARDI_GLINVREGDETAIL** | `fact_se_yardi_investment_register_detail` | Investment register / capex |
| **YARDI_UNITTYPE** | `fact_se_yardi_unit_type_market_rent` | Unit-type market rent benchmarks |
| **YARDI_TENANTAGING** | `fact_se_yardi_receivable_aging` | Receivable aging / credit stress |
| **YARDI_CAMRULE** | `fact_se_yardi_cam_opex_rule` | CAM / OpEx rules |
| **YARDI_UNIT** | `fact_se_yardi_unit_master` | Unit master (entity) |
| **YARDI_LEASE_HISTORY** | `fact_se_yardi_lease_history` | Lease events (deploy pacing) |
| **YARDI_TENANT_HISTORY** | `fact_se_yardi_tenant_history` | Tenant residency history |
| **YARDI_UNIT_HISTORY** | `fact_se_yardi_unit_status_history` | Unit status / occupancy over time |

## `concept_progress_*` — fund canvas concepts (TRANSFORM.DEV tables)

Purpose-named **`concept_progress_[topic]`** models join vetted **`fact_sfdc_*`** / **`fact_se_yardi_*`** read-throughs for **allocate / deploy / returns / sensitivity** workflows. Same enable flag as facts: **`transform_dev_enable_source_entity_progress_facts`**. Tagged **`source_entity_progress_concept`**.

| Model | Upstream | Fund tab |
|-------|----------|----------|
| `concept_progress_property` | `fact_sfdc_properties_c` × `fact_se_yardi_property_attribute` | Allocate, Sensitivity |
| `concept_progress_fund_allocation` | `fact_sfdc_fund_c` × `fact_sfdc_fund_market_c` | Allocate |
| `concept_progress_market_submarket` | `fact_sfdc_market_to_submarket_c` × `fact_sfdc_submarket_c` | Allocate |
| `concept_progress_acquisition_uw` | `fact_sfdc_finance_due_diligence_c` × `fact_sfdc_acquisition_c` | Returns, Sensitivity |
| `concept_progress_acquisition_velocity` | `fact_sfdc_acquisition_history` × `fact_sfdc_acquisition_c` | Deploy |
| `concept_progress_disposition_bpo` | `fact_sfdc_disposition_c` × `fact_sfdc_bpo_c` | Returns, Sensitivity |
| `concept_progress_rent` | `concept_progress_property` + `fact_se_yardi_unit_type_market_rent` + `fact_se_yardi_unit_master` + optional `UNIT_PROGRESS` roll-up | Allocate, Sensitivity |

**EDW retirement (disposition yield):** **`models/transform/dev/progress_crm/`** — **`fact_progress_disposition`** / **`fact_progress_disposition_latest`** (**`SOURCE_ENTITY.PROGRESS`** disposition + BPO) feed **`concept_disposition_yield_property`**; **`ref_disposition_cherre_subject_bridge`** ( **`TRANSFORM.DEV`** ) joins Cherre assessor + AVM; **`model_disposition_cherre_pricing_context`** and **`model_disposition_yield_portfolio`** under **`models/analytics/model/disposition/`** replace legacy **ANALYTICS** / **EDW mart** rollups; **`demo_disposition_yield_property`** / **`demo_disposition_yield_portfolio`** in **`models/serving/demo/`** expose **SERVING.DEMO** delivery shapes (**mart_updated_at** alias). Gate: **`transform_dev_enable_disposition_yield_stack`** (default **false**). **`FACT_OPCO_PROPERTY_PRESENCE`** still comes from pretium-ai-dbt **TRANSFORM.DEV** until OpCo is native here. `cbsa_title` is null until OpCo fact carries a title column.

Join keys use **`adapter.quote()`** with defaults aligned to Progress landings: **`PROPERTYNUMBER__C`** ↔ **`SCODE`** (property), **`ENTITY__C`** ↔ **`ID`** (FDD → acquisition). Override the same-named vars after **`vet_source_entity_progress_fund_objects.sql`** if your org differs (e.g. `Acquisition__c`, `Yardi_Property_Code__c`).

```bash
dbt run --selector source_entity_progress_concepts \
  --vars '{"transform_dev_enable_source_entity_progress_facts": true}'
```

## REFERENCE.CATALOG — target state vs phased implementation

These **`concept_progress_*`** tables are not narrow “reference joins” or one-off denormalizations. They are part of Pretium’s **AI-ready market and operating data layer**: centralized market views, investment-workflow and IC-ready outputs, and tools (including natural-language interfaces) that need a **catalog and metadata layer that can describe the full decision surface**, not only the columns a single team consumes on day one.

Three connected use cases drive coverage:

1. **Market analytics** — Repeatable, AI-assisted market intelligence (rankings, Top-N, ZIP/MSA scoring, gauges, reporting suites) depends on **broad combinations** of market, macro, risk, and operating attributes, plus rich metadata so retrieval and knowledge graphs stay accurate.
2. **Fund modeling** — Operating data (fund and property management basics) and evaluation of fund models require integrating **Tribeca, Progress, BH**, and related operating sources; the **SFDC × Yardi property spine** and **acquisition × FDD** stack are first-class inputs to that target-state lake, not peripheral landings.
3. **Underwriting** — Pipelines and products feed **IC, underwriting, and anchor-loan** workflows (dashboards, risk frameworks, scenario tools, deal screening). Under-registering these concept tables weakens **underwriting QA, buy-box attribution, acquisition autopsies**, and defensible deal-memo generation.

**Positioning (PR / memo, tighter):** We treat these concept tables as **broad decision-support surfaces**, not minimally curated lookups. The business need spans **market analytics, fund modeling, and underwriting** end to end. The property spine carries **market + operating context at property grain**; the acquisition/FDD stack carries **deal evaluation, scenarios, and underwriting comparison**. **Target state:** register the **full** operating and underwriting surface the workflows require. **Implementation:** still **phase in** with a **starter metric block** (today **MET_029–MET_040**, twelve columns) so governance and tests stay tractable; expand with **one consumer or one planned model per metric** so the catalog does not become noise.

Seeds: **`seeds/reference/catalog/concept.csv`** (**`fund_property_spine`**, **`acquisition_underwriting`**) and **`metric.csv`** (starter **`snowflake_column`** = compiled dbt alias; **`table_path`** = **`TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY`** / **`TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW`**). **`metric_derived`** (spreads, rent/yield bridges, time-to-close) — separate PR once base lineage is proven.

Snowflake vet (either repo, same path): **`scripts/sql/validation/describe_concept_progress_catalog_shortlist.sql`** — also copied under **`pretium-ai-dbt`** so `snowsql -c pretium -f scripts/sql/validation/describe_concept_progress_catalog_shortlist.sql` works from that repo root.

## Vars

- **`transform_dev_enable_fund_opco_facts`** (default `true`) — gates Progress/BH property, unit, and ledgers.
- **`yardi_trans_bh_available`** (default `false`) — when **`true`**, **`fact_bh_yardi_ledger`** reads **`source('transform_yardi','TRANS_BH')`** (preferred; grants + column parity on silver).
- **`yardi_bh_available`** (default `false`) — when **`yardi_trans_bh_available`** is **`false`**, set **`true`** to build **`fact_bh_yardi_ledger`** from legacy **`source('yardi_bh','TRANS')`**. **`fact_bh_yardi_ledger`** is enabled if **either** flag is **`true`**.

## Migration

**Operator runbook (grants → facts → concepts → join vet → market gap map):**  
**`docs/migration/PROGRESS_FUND_CANVAS_TRANSFORM_RUNBOOK_AND_MARKET_GAP.md`**.

See also **`docs/migration/MIGRATION_TASKS.md`**, **`docs/migration/MIGRATION_RULES.md`**, and **`MIGRATION_TASKS_YARDI_BH_PROGRESS.md`**.
