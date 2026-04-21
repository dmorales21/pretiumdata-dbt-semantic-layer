# Migration readiness — **`models/sources/`** gaps (pretiumdata-dbt-semantic-layer)

**Owner:** Alex  
**Governing docs:** `MIGRATION_RULES.md` (no hardcoded FQNs), `MIGRATION_BASELINE_RAW_TRANSFORM.md`, pretium-ai-dbt `dbt/models/sources.yml` parity notes in `MIGRATION_TASKS.md`  
**Physical YAML:** `models/sources/*.yml`

**Purpose:** Separate **(A) compile-time closure** — every `source()` used by enabled SQL today has a YAML row — from **(B) forward parity** — objects the corridor pipeline, pretium-ai-dbt cleaned layers, or vendor matrices expect soon but this repo has not yet declared or consumed.

---

## §0 Naming patterns + merge gate (run tests before new `sources` rows)

**TRANSFORM vendor schemas (this repo today):**

| YAML knob | Pattern | Example |
|-----------|---------|---------|
| Source **group** `name:` | `transform_<schema_slug>` for **`TRANSFORM.<SCHEMA>`** reads (match `sources_transform.yml` siblings) | `transform_lodes` → database `TRANSFORM`, schema `LODES` |
| Source **table** `name:` | **Lower snake_case** derived from the physical table (same rule as columns in `MIGRATION_RULES.md` §3) | Snowflake `OD_BG` → `od_bg`; `OD_H3_R8` → `od_h3_r8` |
| **`identifier:`** | Physical Snowflake **table / view** name as deployed (Jon/DE) — for LODES silver, **UPPER_UNDERSCORE** | `identifier: OD_H3_R8` |

**pretium-ai-dbt parity (Redfin):** cleaned models there use **`source('redfin', '<table>')`** with a source group named **`redfin`** (not `transform_redfin`). When adding Redfin to this repo, follow **`MIGRATION_TASKS_STANFORD_REDFIN.md`** so `database` / `schema` match the interim vs canonical home; keep the **`redfin`** group name if you want drop-in SQL porting.

**Wishlist `wishlist_code` (catalog seed):** stable **snake_case**; Polaris program rows use prefix **`polaris_`**; dbt-source backlog rows here use **`semantic_sources_*`** (e.g. **`semantic_sources_redfin_dbt`**, **`semantic_sources_cherre_vendor_share`**) — avoid embedding **`transform_prod`** in the slug when the work is **`TRANSFORM.*`** vs legacy **`TRANSFORM_PROD`**.

**Merge gate — run before adding or changing declared `sources` tables that ship with model work:**

```bash
dbt test --select path:seeds/reference/catalog
# When touching TRANSFORM.LODES read-through / downstream facts:
dbt test --select fact_lodes_od_bg
# After adding a new model that references a new source() table, narrow to that model:
# dbt test --select fact_<new_model>
```

Add the **YAML `tables:` entry in the same PR** as the first SQL that calls `source(…)`, after the relevant **`dbt test`** slice is green (catalog seeds + affected models).

### §0.1 Snippet — add under `transform_lodes` when porting OD hex reads

Indent to sibling depth of **`od_bg`** inside `sources_transform.yml`:

```yaml
      - name: od_h3_r8
        identifier: OD_H3_R8
        description: >
          H3 R8 residence × workplace OD jobs counts (VINTAGE_YEAR, H3_R8_RESIDENCE, H3_R8_WORKPLACE, CBSA_ID_*,
          JOBS_*). Physical `TRANSFORM.LODES.OD_H3_R8`; call `source('transform_lodes','od_h3_r8')`.
```

---

## §A Current closure (enabled models + macros)

As of the audit that produced this doc, every `source('source_name', 'table')` reference in **`models/`** and **`macros/`** resolves to a **`sources:`** block under `models/sources/`. There is **no** “missing `sources.yml` row for an existing model” class of failure for `dbt parse` / `dbt compile` on that basis alone.

**Smoke check (maintainer):** from the inner project root, re-run periodically:

```bash
rg "source\\(['\\\"]" models macros --glob '*.sql' -o | sort -u
```

Compare the distinct `source_name` values to `name:` entries under `models/sources/`.

---

## §B Prioritized gaps (add or extend `models/sources/`)

Work is ordered by **dependency on upcoming FACT / corridor ports** and **pretium-ai-dbt divergence**.

| Priority | Gap | Why it matters | Task / wishlist anchor |
|----------|-----|----------------|-------------------------|
| **P1** | **`source('transform_lodes', 'od_h3_r8')`** | **`TRANSFORM.LODES.OD_H3_R8`** — hex OD for employment-center chain. | **Done:** `sources_transform.yml` + read-through **`fact_lodes_od_h3_r8_annual`** (`dbt test` parity warn vs silver). |
| **P2** | **Redfin `source('redfin', …)` + `source_redfin`** | Interim **`TRANSFORM.REDFIN`** trackers + canonical **`SOURCE_PROD.REDFIN`** ZIP history. | **In progress:** **`models/sources/sources_redfin.yml`**. Wishlist **`WL_047`** — set **`done`** after cleaned Redfin ports + RF-A inventory close. |
| **P3** | **Cherre share `source('cherre', …)`** | Share path vs **`cherre_transform`** on **`TRANSFORM.CHERRE`**. | **In progress:** **`models/sources/sources_cherre_share.yml`** (`tax_assessor_v2`). Wishlist **`WL_048`** — set **`done`** after corridor FACT smoke + grants verified. |
| **P4** | **`source('transform_fact', …)`** | Many **`TRANSFORM.FACT`** tables are declared in `sources_transform.yml`, but **no** semantic-layer model SQL calls them yet. Not a compile gap; becomes relevant when analytics reads Jon silver directly. | **`MIGRATION_TASKS_COSTAR.md`**, **`MIGRATION_TASKS_CHERRE.md`** (documented read path). |
| **P5** | **Catalog-only vendors (Salesforce, USPS, …)** | Polaris / matrix may require **`dataset.csv`** + matching **`sources`** before exports. | **`WL_044`** — `MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md`. |
| **P6** | **`TRANSFORM.ZILLOW` silver** (if Zillow facts stop reading **`SOURCE_PROD.ZILLOW`**) | Today Zillow research uses **`source('zillow', …)`** on **`SOURCE_PROD`**. If DE promotes silver reads to **`TRANSFORM.ZILLOW`**, add a new source name or extend `sources_transform.yml`. | **`MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md`**. |

---

## §C Wishlist rows tied to this audit

| id | Code | Role |
|----|------|------|
| **WL_047** | `semantic_sources_redfin_dbt` | **`sources_redfin.yml` shipped** — keep row **`in_progress`** until cleaned Redfin models + RF-A close; then **`done`**. |
| **WL_048** | `semantic_sources_cherre_vendor_share` | **`sources_cherre_share.yml` shipped** — keep **`in_progress`** until share grants + **`FACT_CHERRE_STOCK_H3_R8`** smoke; then **`done`**. |

When **`WL_047`** or **`WL_048`** closes, update **`MIGRATION_LOG.md`** and consider deleting or setting **`status = done`** per `docs/reference/CATALOG_WISHLIST.md`.

---

## §D Related docs (do not duplicate)

- **`VENDOR_CONCEPT_COVERAGE_MATRIX.md`** — dataset / concept coverage vs declarations.  
- **`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md`** — full corridor object matrix.  
- **`MIGRATION_TASKS.md`** — master index (links this file).
