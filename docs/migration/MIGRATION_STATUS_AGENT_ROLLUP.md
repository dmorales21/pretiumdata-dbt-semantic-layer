# Migration status — agent rollup (verified against `MIGRATION_TASKS.md`)

**Purpose:** Short, **checkable** summary for automation and handoffs. Authoritative tables remain **`MIGRATION_TASKS.md`** (register) and **`MIGRATION_LOG.md`** (append-only batch audit). Update this file when those sources change materially.

## State (register)

- **Vendor / government / corridor / Oxford / Strata / tearsheet** rows in the main **`MIGRATION_TASKS.md`** table are overwhelmingly **`pending`**, with explicit exceptions below.
- **`T-TRANSFORM-PROD-CLEANED`** is **`skipped`** (Jon PROD cleanse — re-point consumers only; no duplicate cleanse in Alex targets).
- **`T-EDW-DELIVERY`**, **`T-EDW-MART`**, and **Strata** rows tied to EDW delivery/mart or CRM (`T-STRATA-DS-SFDC-ACQUISITION`, **`T-STRATA-EDW-DELIVERY-STRATA`**, **`T-STRATA-EDW-MART-STRATA`**, **`T-STRATA-SOURCE-ENTITY-CRM`**) are **`blocked`** (owner / contract). Other Strata rows are mostly **`pending`**; additional **`skipped`** Strata rows include **`T-STRATA-META-IS`**, **`T-STRATA-DEV-JAKAR`**, **`T-STRATA-TRANSFORM-VENDOR-READS`** (see register).
- **`MIGRATION_LOG.md`:** Summary counters and **Model registry** are maintained per batch (**001**, **003–005**, **007–008**, …); see file for current counts.

## Declared priority (waves 1–3)

Quoted from **`MIGRATION_TASKS.md` → Priority waves (Alex dev pipeline)** (same section numbers in source):

1. **`TRANSFORM.DEV`** — migrate and run **`FACT_*`** and **`CONCEPT_*`** for the active vendor pilot.
2. **`SOURCE_PROD.[VENDOR].RAW_*`** — only as required to feed (1), plus mandatory **`TRANSFORM.DEV.REF_*`** for joins.
3. **Pilot sequence:** **Zillow**, then **BLS → BPS → MARKERR → REDFIN**; **BH multifamily** stack: **`T-VENDOR-APARTMENTIQ-READY`** + **`T-VENDOR-YARDI-MATRIX-READY`** before calling that cluster done; similar gates for **CoStar** (`T-VENDOR-COSTAR-READY`), **Yardi BH/Progress** (`T-VENDOR-YARDI-READY`), **First Street + RCA** (`T-VENDOR-FIRST-STREET-READY` / `T-VENDOR-RCA-READY`).

## Practical support (next actions)

1. **Pick one pilot batch** (e.g. Zillow slice already under `models/transform/dev/zillow/`) — align **`T-TRANSFORM-DEV`** / Zillow with **`MIGRATION_RULES.md`**, then log batch **`001`** in **`MIGRATION_LOG.md`**.
2. **Run inventories** from inner project root: `scripts/sql/migration/inventory_*.sql` for the cluster touched; save outputs under **`docs/migration/artifacts/`** and tick **§1.5** in the matching **`MIGRATION_TASKS_*.md`**.
3. **Flip statuses** in **`MIGRATION_TASKS.md`** only when Snowflake + repo match the checklist; append **`MIGRATION_LOG.md`** in the same session.
4. **Oxford:** **`T-DEV-REF-OXFORD-METRO-CBSA`** and **`T-DEV-FACT-OXFORD-*`** are **`migrated`** in **`MIGRATION_TASKS.md`** as of batch **008** (`models/transform/dev/oxford/*`); CTAS script remains an emergency rebuild path.
5. **Catalog / CI gates (batch 021):** PRs touching catalog seeds or models run **`.github/workflows/semantic_layer_catalog_and_quality.yml`** (`dbt parse` + catalog `dbt ls`). Before merge on catalog work: **`dbt test --select path:seeds/reference/catalog`** and **`scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`** (0 hard FK failures). Local mirror: **`scripts/ci/run_catalog_quality_checks.sh`**.

---

**Playbooks:** `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md` (estimation goals, data prep, **`T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK`**); `CANONICAL_COMPLETION_DEFINITION.md` (closure surface).

*Last verified against `MIGRATION_TASKS.md` / `MIGRATION_LOG.md` (batches through **021** — CI workflow + dimensional SQL + `GEOGRAPHY_INDEX` unmapped backlog signal).*
