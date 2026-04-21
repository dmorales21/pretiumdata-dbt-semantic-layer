# Vendor-level metric catalog intake — `REFERENCE.CATALOG.metric`

**Owner:** Alex  
**Purpose:** Define **where** governed metrics are authored, **how** each CSV column must be formatted, and a **repeatable per-vendor execution** path so rows are **semantically compliant** (not just FK-valid). This complements vendor **`FACT_*`** docs (`MIGRATION_TASKS_*`) and the short checklist in **`METRIC_INTAKE_CHECKLIST.md`**.

**Governing rules:** `docs/rules/ARCHITECTURE_RULES.md` (layers, **Metric Registration Gates**, tall-format tables, geo vocabulary), `docs/CATALOG_SEED_ORDER.md` (seed waves), `docs/reference/CATALOG_METRIC_DERIVED_LAYOUT.md` (native **`metric`** vs **`metric_derived`** for analytics outputs).

---

## 1. Source of truth (non-negotiable)

| Artifact | Canonical location | Role |
|----------|-------------------|------|
| **`metric.csv`** | **`pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/seeds/reference/catalog/metric.csv`** | **Only** place to add, edit, or retire **`REFERENCE.CATALOG.metric`** rows for this program. |
| **`bridge_product_type_metric.csv`** | Same repo, `seeds/reference/catalog/` | Product / offering exposure of **`metric_code`**; must stay consistent with **`metric`** (FK tests). |
| **`scripts/_gen_metric_csv.py`** | Same repo, `scripts/` | **Scaffolding only** (coverage gaps, bridge-driven shells). **Curated vendor metrics** replace generator placeholders over time; do not treat generated text as the semantic definition of record. |
| **`scripts/sync_metric_csv_from_pretium_ai_dbt.py`** | Same repo, `scripts/` | **Bulk intake** from **`pretium-ai-dbt/dbt/seeds/reference/catalog/metric.csv`**: applies FK-safe **`geo_level_code`** remaps only (Oxford ``varies`` → ``cbsa`` / ``national``), normalizes booleans, merges **`bridge_product_type_metric`**-only rows from the current canonical file, writes **`seeds/reference/catalog/metric.csv`**. **`concept_code`** must exist in **`concept.csv`** in this repo (no concept remaps in the script). Re-run after editing the pretium-ai-dbt export. |
| **`pretium-ai-dbt/dbt/seeds/reference/catalog/metric.csv`** | Legacy / convenience mirror | **Not** a second authority. If a mirror is still needed for older workflows, **copy from the semantic-layer file** in a controlled change; do not fork definitions long-term. Vendor research CSVs under **`pretium-ai-dbt/docs/vendor/metrics/`** are **inputs** to intake, not the catalog. |

**Derived analytics metrics** (`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`) belong in **`metric_derived*.csv`** per **`CATALOG_METRIC_DERIVED_LAYOUT.md`**, not duplicated as warehouse **`metric`** rows unless the column is still a direct observable on **`TRANSFORM.DEV`**.

---

## 2. `metric.csv` column contract (formatting)

Header (exact order for seeds):

`metric_id,metric_code,metric_label,definition,concept_code,vendor_code,is_derived,source_vendor_codes,unit,direction,geo_level_code,frequency_code,is_active,data_status_code,snowflake_column,table_path,metric_category_code,is_opco_metric`

| Column | Format | Semantic notes |
|--------|--------|----------------|
| **`metric_id`** | Stable surrogate, e.g. **`MET_###`** | Never reuse IDs after delete; append-only numbering is fine. |
| **`metric_code`** | **`snake_case`**, unique, no spaces | Stable join key for **`bridge_product_type_metric`** and downstream docs; avoid vendor campaign renames. |
| **`metric_label`** | Short Title Case phrase | UI / catalog display; not the full spec (that is **`definition`**). |
| **`definition`** | Plain language, one paragraph | Must state **grain** (geo × time), **physical path** or read contract, and for tall facts the **series discriminator** (e.g. `METRIC_ID` / `MEASURE_CODE`). |
| **`concept_code`** | FK → **`concept`** | Thematic grouping; must exist and be intentional (see **`CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md`** when concept work lags). |
| **`vendor_code`** | FK → **`vendor`** | Owning vendor for the measure (not necessarily every upstream share name). |
| **`is_derived`** | **`TRUE`** / **`FALSE`** (seed boolean) | **`FALSE`** for native warehouse columns; **`TRUE`** only when still a measurable transform in **`TRANSFORM.DEV`** per architecture rules. |
| **`source_vendor_codes`** | Free text or empty | Human-readable upstream lineage; not a FK list unless you adopt a strict convention. |
| **`unit`** | Controlled vocabulary by convention | Examples: `count`, `pct`, `usd`, `index`, `varies` — align with **`definition`** and downstream calculators. |
| **`direction`** | `positive` \| `negative` \| `neutral` (typical) | Economic interpretation for directional analytics; use **`neutral`** when signedness is meaningless. |
| **`geo_level_code`** | FK → **`geo_level`** | Normalize vendor labels (e.g. metro → **`cbsa`**) per **`ARCHITECTURE_RULES.md` § Geo Level Vocabulary**. |
| **`frequency_code`** | FK → **`frequency`** | Must match the **FACT** as-of / period grain. |
| **`is_active`** | **`TRUE`** / **`FALSE`** | Soft-disable without deleting history. |
| **`data_status_code`** | FK → **`data_status`** | Allowed: **`active`**, **`deprecated`**, **`under_review`**, **`blocked`**. |
| **`snowflake_column`** | Identifier | **Wide** facts: real column name. **Tall** facts: use **`METRIC_VALUE`** (or the table’s value column name) and document series keys in **`definition`** per **`ARCHITECTURE_RULES.md` § Tall-Format Tables**. |
| **`table_path`** | Uppercase FQN | **`TRANSFORM.DEV.FACT_*`** for Alex physical facts; **`ANALYTICS.DBT_DEV.*`** only when registering a published analytics column per **`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`** and schema comments in **`schema_metrics_vendors_datasets.yml`**. |
| **`metric_category_code`** | FK → **`metric_category`** | **`leading`**, **`lagging`**, **`coincident`**. |
| **`is_opco_metric`** | **`TRUE`** / **`FALSE`** | **`TRUE`** only when the measure is OpCo-sourced / operator-internal per dataset rules. |

**CSV hygiene:** UTF-8, no thousands separators in numeric literals inside text fields, double-quote fields that contain commas, consistent boolean casing **`TRUE`/`FALSE`** to match other catalog seeds.

---

## 3. Semantic compliance gates (before `active`)

Apply **`METRIC_INTAKE_CHECKLIST.md`** in order, then **`ARCHITECTURE_RULES.md` § Metric Registration Gates**:

1. **Null coverage** — high non-null rate at stated grain.  
2. **History** — sufficient history for the intended signal (default expectation **≥12 months** where time series).  
3. **Catalog compliance** — every FK column value exists in **`REFERENCE.CATALOG`** seeds (**`concept`**, **`vendor`**, **`geo_level`**, **`frequency`**, **`data_status`**, **`metric_category`**).  
4. **Census / spine compliance** — geographic IDs join to the canonical spine at required coverage when the grain is census-aligned.

Until gates pass, keep **`data_status_code = under_review`** (or **`blocked`** with a note in **`definition`** / batch index).

---

## 4. Vendor-level execution template (each vendor batch)

Use this as the **default section** to paste into vendor-specific **`MIGRATION_TASKS_*.md`** files when you open or extend a vendor wave.

| Step | Action | Done when |
|------|--------|-------------|
| **V0** | Confirm **`vendor`** + **`dataset`** rows exist for this vendor / grain (`CATALOG_SEED_ORDER.md`). | Seeds load without FK errors. |
| **V1** | Inventory physical **`FACT_*`** (semantic-layer `models/transform/dev/<vendor>/`) and Snowflake **`DESCRIBE` / smoke SQL** (see vendor doc §1.5). | Column list + PK / grain documented. |
| **V2** | Map columns → **`metric_code`** (one row per **registered observable**; do not register keys/metadata per **`ARCHITECTURE_RULES.md` § Metric Column Classification**). | Code list reviewed; tall vs wide decided per column. |
| **V3** | Add or replace rows in **canonical** **`metric.csv`** only; retire **`_observe` / placeholder** rows if they were scaffolding. | Each new **`metric_code`** has complete row; **`concept_code`** intentional. |
| **V4** | Update **`bridge_product_type_metric.csv`** when a metric should surface on a **product_type** (else consumers will not see it). | `dbt test --select bridge_product_type_metric` passes. |
| **V5** | Reseed catalog wave (see **`CATALOG_SEED_ORDER.md`**) and run validation SQL **`scripts/sql/validation/catalog_metric_registration_coverage.sql`**. | KPIs + gap section show no unexpected missing **`TRANSFORM.DEV.FACT_*`** registrations for in-scope facts. |
| **V6** | Log evidence in **`MIGRATION_LOG.md`** + **`MIGRATION_BATCH_INDEX.md`**. | Batch row + artifact paths on file. |

**Polaris / wishlist hygiene:** when **`bridge_product_type_metric`** changes materially, reconcile **`catalog_wishlist`** / Polaris notes per **`MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md`**.

---

## 5. Suggested vendor rollout order (metric-focused)

Order by **dependency** and **catalog maturity** (adjust per IC priorities):

1. **Government / Pretium spine** — BPS, Census PEP, BLS LAUS, LODES (existing `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`).  
2. **High-traffic market vendors already in `TRANSFORM.DEV`** — Zillow, Oxford, Cherre slices, Redfin, Stanford (pair with each vendor doc).  
3. **OpCo / operational** — Yardi BH/Progress, Matrix, ApartmentIQ (strict **`is_opco_metric`** + dataset rules).  
4. **Long-tail vendor facts** — CoStar, First Street, RCA, Markerr, Cybersyn-fed facts — only after **`dataset`** + geo normalization are settled.

Each vendor should own a **`T-VENDOR-*-READY`** (or **`T-TRANSFORM-*`**) row in **`MIGRATION_TASKS.md`**; metric intake **closes** that vendor slice only when **§4** is complete for every promoted **`FACT_*`** column you expose to signals / Strata / tearsheets.

---

## 6. Task ID (register)

| Task ID | Scope | Primary artifacts |
|---------|--------|-------------------|
| **`T-CATALOG-METRIC-VENDOR-ROLLOUT`** | Vendor-by-vendor replacement of scaffolding with curated **`metric`** rows + **`bridge_product_type_metric`** updates | Canonical **`metric.csv`**, **`bridge_product_type_metric.csv`**, vendor **`MIGRATION_TASKS_*.md`**, **`MIGRATION_LOG.md`** |

**Status:** `in_progress` until all in-scope **`TRANSFORM.DEV.FACT_*`** for the program have **reviewed** catalog rows (not merely generator stubs) and **`data_status_code`** reflects reality.

---

## 7. Related docs

- **`METRIC_INTAKE_CHECKLIST.md`** — short ordered checklist.  
- **`MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`** — vendor × dataset × metric index.  
- **`CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md`** — when **`concept_code`** assignments need a coordinated pass.  
- **`QA_METRIC_LAYER_VALIDATION.md`** / **`QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md`** — optional QA depth.
