# Schema Rules — Pretium Data Warehouse
# Source of truth for all object placement, naming, ownership, and lineage
# Generated from schema_rules.csv — do not hand-edit this table

## Databases in scope
# REFERENCE | RAW | SOURCE_ENTITY | SOURCE_PROD | TRANSFORM | ANALYTICS | SERVING

| OWNER | FOCUS | STAGE | PURPOSE | DB | SCHEMA | PREFIX | SUFFIX | STRUCTURE | READ FROM | OBJECT TYPE | REFRESH | RETENTION |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Jon | Market | PROD | Geography Attributes | REFERENCE | .GEOGRAPHY | | | .[geo_level] | S3 | Table | Annual | Indefinite |
| Jon | Market | PROD | Geography Level Crosswalk | REFERENCE | .GEOGRAPHY | | | .[geo1]_[geo2]_xwalk | REFERENCE.GEOGRAPHY | Table | On geo update | Indefinite |
| Alex | Market | PROD | Geography H3 Level Lookup | REFERENCE | .GEOGRAPHY | | | .[geo]_h3_[operation] | REFERENCE.GEOGRAPHY | Table | On geo update | Indefinite |
| Alex | Market | PROD | AI Prompt Templates | REFERENCE | .AI | | | .[concept]_[use_case]_[version] | SEED | Table | On SEED deploy | Indefinite |
| Alex | Market | PROD | AI Prompt Config | REFERENCE | .AI | | | .[model]_[use_case]_config | SEED | Table | On SEED deploy | Indefinite |
| Alex | Market | PROD | Catalog Canon | REFERENCE | .CATALOG | | | .[dimension] | SEED | Table | On SEED deploy | Indefinite |
| Jon/Alex | Market | PROD | Lineage & Freshness Registry | REFERENCE | .CATALOG | | | .[object]_lineage | ALL LAYERS | Table | On object refresh | Indefinite |
| Jon/Spencer | Market | PROD | Pipeline Alert Sink | REFERENCE | .CATALOG | | | .pipeline_alert | TRANSFORM, ANALYTICS, SERVING | Table | Continuous | 6 months rolling |
| David/Alex | OpCo | PROD | Schema Alignment Registry | REFERENCE | .CATALOG | | | .schema_alignment | SOURCE_ENTITY.[OPCO] | Table | On SOURCE deploy | Indefinite |
| Jon | Market | PROD | Raw Dataset | RAW | .[VENDOR] | | | .[dataset] | S3 or Iceberg | Table, Incremental Refresh | Per vendor SLA | 36 months |
| David | OpCo | PROD | OpCo Dataset - Landed | SOURCE_ENTITY | .[OPCO] | [VENDOR] | | .[dataset] | S3, Iceberg, Blob Storage, Azure SQL | Table | Per OpCo SLA | 36 months |
| David | OpCo | PROD | OpCo Dataset - Shared | SOURCE_ENTITY | .[OPCO] | [VENDOR] | | .[dataset] | Data Share, Snowflake Sync | View | Per OpCo SLA | 36 months |
| Jon | Market | PROD | Vendor Dataset Cleansed | TRANSFORM | .[VENDOR] | | | .[dataset] | RAW.[VENDOR] or Data Share | Dynamic Table | On RAW / ≤1hr lag | 36 months |
| Jon | Market | PROD | Vendor Dictionary | TRANSFORM | .[VENDOR] | | | .[dataset]_dictionary | RAW.[VENDOR] or Data Share | Table | On RAW deploy | Indefinite |
| Jon | Market | PROD | Vendor Lookup | TRANSFORM | .[VENDOR] | | | .[dataset]_lookup | TRANSFORM.[VENDOR] | Table | On cleanse update | Indefinite |
| Jon | Market | PROD | Vendor Dataset Current Only | TRANSFORM | .[VENDOR] | | | .[dataset]_latest | TRANSFORM.[VENDOR] | Dynamic Table | On cleanse / ≤1hr lag | Current only |
| Jon | Market | PROD | Vendor Dataset with Geos | TRANSFORM | .[VENDOR] | | | .[dataset]_geo | TRANSFORM.[VENDOR] | Dynamic Table | On cleanse / ≤1hr lag | 36 months |
| Jon/Alex | Market | PROD | Data Quality Monitor | TRANSFORM | .[VENDOR] | QA | | .[dataset]_[check] | TRANSFORM.[VENDOR] | Table | On cleanse refresh | 6 months rolling |
| David | OpCo | PROD | OpCo 3rd Party Dataset Cleansed | TRANSFORM | .[VENDOR] | | [OPCO] | .[dataset]_[opco] | SOURCE_ENTITY.[OPCO] | Dynamic Table | Per OpCo SLA / ≤2hr lag | 36 months |
| David | OpCo | PROD | OpCo Internal Dataset Cleansed | TRANSFORM | .[VENDOR] | | [OPCO] | .[dataset]_[opco] | SOURCE_ENTITY.[OPCO] | Dynamic Table | Per OpCo SLA / ≤2hr lag | 36 months |
| David | OpCo | PROD | OpCo Dataset Dictionary | TRANSFORM | .[VENDOR] | | [OPCO] | .[dataset]_[opco]_dictionary | SOURCE_ENTITY.[OPCO] | Table | On SOURCE deploy | Indefinite |
| David | OpCo | PROD | OpCo Dataset Lookup | TRANSFORM | .[VENDOR] | | [OPCO] | .[dataset]_[opco]_lookup | TRANSFORM.[VENDOR] | Table | On cleanse update | Indefinite |
| David | OpCo | PROD | OpCo Dataset Current Only | TRANSFORM | .[VENDOR] | | [OPCO] | .[dataset]_[opco]_latest | TRANSFORM.[VENDOR] | Dynamic Table | On cleanse / ≤1hr lag | Current only |
| David | OpCo | PROD | OpCo Dataset with Geos | TRANSFORM | .[VENDOR] | | [OPCO] | .[dataset]_[opco]_geo | TRANSFORM.[VENDOR] | Dynamic Table | On cleanse / ≤1hr lag | 36 months |
| David/Alex | OpCo | PROD | OpCo Data Quality Monitor | TRANSFORM | .[VENDOR] | QA | [OPCO] | .[dataset]_[opco]_[check] | TRANSFORM.[VENDOR] | Table | On cleanse refresh | 6 months rolling |
| Jon | Market | PROD | Vendor Dataset Cleaned | TRANSFORM | .FACT | | | .[vendor]_[dataset]_[geo_level]_[frequency] | TRANSFORM.[VENDOR] | Dynamic Table | On VENDOR refresh / ≤2hr lag | 36 months |
| David | OpCo | PROD | OpCo Dataset Cleaned | TRANSFORM | .FACT | | [OPCO] | .[opco]_[dataset]_[geo_level]_[frequency] | TRANSFORM.[VENDOR] | Dynamic Table | On VENDOR refresh / ≤2hr lag | 36 months |
| David | OpCo | PROD | OpCo FACT with Geos | TRANSFORM | .FACT | | [OPCO] | .[opco]_[dataset]_[geo_level]_[frequency]_geo | TRANSFORM.[VENDOR], REFERENCE.GEOGRAPHY | Dynamic Table | On FACT refresh / ≤1hr lag | 36 months |
| Jon | Market | PROD | Concept Dataset | TRANSFORM | .CONCEPT | | | .[concept]_[geo_level]_[frequency] | TRANSFORM.FACT | Dynamic Table | On FACT refresh / ≤1hr lag | 36 months |
| David/Spencer | OpCo | PROD | OpCo Concept Dataset | TRANSFORM | .CONCEPT | | [OPCO] | .[concept]_[opco]_[geo_level]_[frequency] | TRANSFORM.FACT | Dynamic Table | On FACT refresh / ≤1hr lag | 36 months |
| Jon | Market | PROD | Deliver Prod Data | SERVING | .MART | | | .[concept]_[geo_level]_[frequency] | TRANSFORM.CONCEPT, ANALYTICS.DBT_PROD | Iceberg | On ANALYTICS refresh | 36 months |
| Alex | Market | PROD | Deliver Prod Embeddings | SERVING | .MART | | | .[concept]_[use_case]_embedding | ANALYTICS.DBT_PROD.AI/FEATURE/MODEL | Parquet | On AI/FEATURE refresh | Current + 1 prior |
| Alex | Market | PROD | Deliver Prod Synthesis | SERVING | .MART | | | .[concept]_[use_case]_inference | ANALYTICS.DBT_PROD.AI/FEATURE/MODEL | Iceberg | On AI/FEATURE refresh | 24 months |
| Spencer | Market | PROD | Deliver Endpoints | SERVING | .COLLECTION | | | .[collection_name]_[geo_level]_[frequency] | SERVING.MART, ANALYTICS.DBT_PROD | Parquet | On MART refresh | Current + 1 prior |
| David/Spencer | OpCo | PROD | OpCo Deliver Endpoints | SERVING | .COLLECTION | | [OPCO] | .[opco]_[collection_name]_[geo_level]_[frequency] | TRANSFORM.CONCEPT, SERVING.MART | Parquet | On CONCEPT refresh | Current + 1 prior |
| Spencer | Market | PROD | Deliver Exported Data | SERVING | .EXPORT | | | .[consumer]_[concept]_[geo_level]_[frequency] | SERVING.MART or SERVING.COLLECTION | Parquet/CSV | On COLLECTION refresh | 90 days |
| David/Spencer | OpCo | PROD | OpCo Deliver Exported Data | SERVING | .EXPORT | | [OPCO] | .[opco]_[consumer]_[concept]_[geo_level]_[frequency] | SERVING.COLLECTION or SERVING.MART | Parquet/CSV | On COLLECTION refresh | 90 days |
| Alex | | PROD | Features in PROD | ANALYTICS | .DBT_PROD | FEATURE | | .[concept]_[function]_[geo_level]_[frequency] | ANALYTICS.DBT_STAGE | Dynamic Table | Nightly or on CONCEPT refresh | Indefinite |
| David | | PROD | OpCo Feature | ANALYTICS | .DBT_PROD | FEATURE | [OPCO] | .[opco]_[concept]_[function]_[geo_level]_[frequency] | TRANSFORM.CONCEPT, TRANSFORM.FACT | Dynamic Table | Nightly or on CONCEPT refresh | Indefinite |
| Alex | | PROD | Models in PROD | ANALYTICS | .DBT_PROD | MODEL | | .[concept]_[model]_[geo_level]_[frequency] | ANALYTICS.DBT_STAGE | Dynamic Table | Nightly or on FEATURE refresh | Indefinite |
| David | | PROD | OpCo Model | ANALYTICS | .DBT_PROD | MODEL | [OPCO] | .[opco]_[concept]_[model]_[geo_level]_[frequency] | ANALYTICS.DBT_PROD.FEATURE | Dynamic Table | Nightly or on FEATURE refresh | Indefinite |
| Alex | | PROD | Estimates in PROD | ANALYTICS | .DBT_PROD | ESTIMATE | | .[concept]_[model]_[estimate_type]_[geo_level]_[frequency] | ANALYTICS.DBT_STAGE | Iceberg | Nightly | 24 months |
| Alex | | PROD | BI in PROD | ANALYTICS | .DBT_PROD | BI | | .[business_team]_[concept]_[geo_level]_[frequency] | ANALYTICS.DBT_STAGE | View | Nightly or on MODEL refresh | Indefinite |
| Alex | | PROD | AI in PROD | ANALYTICS | .DBT_PROD | AI | | .[concept]_[use_case]_[version] | ANALYTICS.DBT_STAGE | Table | Nightly or on FEATURE refresh | Indefinite |
| Alex | | DEV | AI Prompt Templates in Dev | REFERENCE | .DRAFT | AI | | .[concept]_[use_case]_[version] | SEED or manual | Table | Manual | Until promoted |
| Alex | | DEV | AI Config in Dev | REFERENCE | .DRAFT | AI | | .[model]_[use_case]_config | SEED or manual | Table | Manual | Until promoted |
| Alex | | DEV | Bespoke Geography in Dev | REFERENCE | .DRAFT | GEO | | .[geo_type]_[vintage] | S3 or manual | Table | Manual | Until promoted |
| Alex | | DEV | Catalog Dimension in Dev | REFERENCE | .DRAFT | CAT | | .[dimension] | SEED or manual | Table | Manual | Until promoted |
| Alex | | DEV | Landed Dataset | SOURCE_PROD | .[VENDOR] | | | .[dataset]_[geo_level]_[frequency] | S3 | Table | Manual / on-demand | 12 months |
| David | | DEV | OpCo Landed Dataset (DEV) | SOURCE_ENTITY | .[OPCO] | [VENDOR] | DEV | .[dataset]_dev | S3, Blob Storage, manual | Table | Manual / on-demand | 12 months |
| Alex | | DEV | Raw Dataset | TRANSFORM | .DEV | RAW | | .[vendor]_[dataset]_[geo_lookup] | TRANSFORM.[VENDOR] → Data Share → SOURCE_PROD.[VENDOR] | Table | Manual / on-demand | 12 months |
| Alex | | DEV | Vendor Lookup | TRANSFORM | .DEV | REF | | .[vendor]_[dataset]_[lookup] | TRANSFORM.[VENDOR] → Data Share → SOURCE_PROD.[VENDOR] | Table | Manual | Until superseded |
| Alex | | DEV | Vendor Dataset Cleansed | TRANSFORM | .DEV | RAW | | .[vendor]_[dataset]_[geo_level]_[frequency] | TRANSFORM.[VENDOR] → Data Share → SOURCE_PROD.[VENDOR] | Table, Incremental Refresh | Manual / on-demand | 12 months |
| Alex | | DEV | Vendor Dictionary | TRANSFORM | .DEV | RAW | | .[vendor]_[dataset]_dictionary | TRANSFORM.[VENDOR] → Data Share → SOURCE_PROD.[VENDOR] | Table | Manual | Until superseded |
| Alex | | DEV | Vendor Dataset Cleaned | TRANSFORM | .DEV | FACT | | .[vendor]_[dataset]_[geo_level]_[frequency] | TRANSFORM.[VENDOR] → TRANSFORM.DEV | Dynamic Table | Manual / on-demand | 12 months |
| Alex | | DEV | Quality Check | TRANSFORM | .DEV | QA | | .[vendor]_[dataset]_[check] | TRANSFORM.DEV | Table | Manual / on-demand | 3 months |
| Alex | | DEV | Concept Dataset | TRANSFORM | .DEV | CONCEPT | | .[concept]_[geo_level]_[frequency] | TRANSFORM.DEV | Dynamic Table | Manual / on-demand | 12 months |
| David | | DEV | OpCo Dataset Cleansed (DEV) | TRANSFORM | .DEV | RAW | [OPCO] | .[dataset]_[opco] | SOURCE_ENTITY.[OPCO] | Dynamic Table | Manual / on-demand | 12 months |
| David | | DEV | OpCo Dataset Cleaned (DEV) | TRANSFORM | .DEV | FACT | [OPCO] | .[opco]_[dataset]_[geo_level]_[frequency] | TRANSFORM.DEV | Dynamic Table | Manual / on-demand | 12 months |
| David | | DEV | OpCo Quality Check (DEV) | TRANSFORM | .DEV | QA | [OPCO] | .[dataset]_[opco]_[check] | TRANSFORM.DEV | Table | Manual / on-demand | 3 months |
| Alex | | DEV | Features in Development | ANALYTICS | .DBT_DEV | FEATURE | | .[concept]_[function]_[geo_level]_[frequency] | TRANSFORM.CONCEPT → TRANSFORM.FACT → TRANSFORM.DEV | View | On-demand | Until promoted |
| Alex | | DEV | Models in Development | ANALYTICS | .DBT_DEV | MODEL | | .[concept]_[model]_[geo_level]_[frequency] | ANALYTICS.DBT_DEV.FEATURE | View | On-demand | Until promoted |
| Alex | | DEV | Estimates in Development | ANALYTICS | .DBT_DEV | ESTIMATE | | .[concept]_[model]_[estimate_type]_[version]_[geo_level]_[frequency] | ANALYTICS.DBT_DEV.MODEL | Table | On-demand | 6 months |
| Alex | | DEV | BI in Development | ANALYTICS | .DBT_DEV | BI | | .[business_team]_[concept]_[geo_level]_[frequency] | TRANSFORM.CONCEPT → TRANSFORM.FACT → TRANSFORM.DEV | View | On-demand | Until promoted |
| Alex | | DEV | AI in Development | ANALYTICS | .DBT_DEV | AI | | .[concept]_[use_case]_[version] | ANALYTICS.DBT_DEV.FEATURE, ANALYTICS.DBT_DEV.MODEL, REFERENCE.AI | Table | On-demand | Until promoted |
| Alex | | STAGE | Features Staged for PROD | ANALYTICS | .DBT_STAGE | FEATURE | | .[concept]_[function]_[geo_level]_[frequency] | ANALYTICS.DBT_DEV | Dynamic Table | Nightly | Until promoted |
| Alex | | STAGE | Models Staged for PROD | ANALYTICS | .DBT_STAGE | MODEL | | .[concept]_[model]_[geo_level]_[frequency] | ANALYTICS.DBT_DEV | Dynamic Table | Nightly | Until promoted |
| Alex | | STAGE | Estimates Staged for PROD | ANALYTICS | .DBT_STAGE | ESTIMATE | | .[concept]_[model]_[estimate_type]_[geo_level]_[frequency] | ANALYTICS.DBT_DEV | Iceberg | Nightly | 6 months |
| Alex | | STAGE | BI Staged for PROD | ANALYTICS | .DBT_STAGE | BI | | .[business_team]_[concept]_[geo_level]_[frequency] | ANALYTICS.DBT_DEV | View | Nightly | Until promoted |
| Alex | | STAGE | AI Staged for PROD | ANALYTICS | .DBT_STAGE | AI | | .[concept]_[use_case]_[version] | ANALYTICS.DBT_DEV | Table | Nightly | Until promoted |
| Alex | | STAGE | Stage Promotion Gate | ANALYTICS | .DBT_STAGE | QA | | .[object]_[check] | ANALYTICS.DBT_STAGE | Table | Nightly | 6 months rolling |
| Alex | | DEV | Deliver Dev Embeddings | SERVING | .DEMO | MART | | .[concept]_[use_case]_embedding | ANALYTICS.DBT_DEV.AI/FEATURE/MODEL | Parquet | On-demand | 3 months |
| Alex | | DEV | Deliver Dev Synthesis | SERVING | .DEMO | MART | | .[concept]_[use_case]_inference | ANALYTICS.DBT_DEV.AI/FEATURE/MODEL | Iceberg | On-demand | 3 months |
| Alex | | DEV | Deliver Dev Data | SERVING | .DEMO | MART | | .[concept]_[geo_level]_[frequency] | TRANSFORM.CONCEPT → TRANSFORM.FACT → TRANSFORM.DEV | Iceberg | On-demand | 3 months |
| Alex | | DEV | Deliver Dev Collection | SERVING | .DEMO | COLLECTION | | .[concept]_[geo_level]_[frequency] | SERVING.DEMO.MART | Parquet | On-demand | 3 months |
| Alex | | DEV | Deliver Dev Export | SERVING | .DEMO | EXPORT | | .[business_team]_[concept]_[geo_level]_[frequency] | SERVING.DEMO.MART, SERVING.DEMO.COLLECTION | Parquet/CSV | On-demand | 30 days |

---

## Enforcement rules

1. Every `[concept]`, `[geo_level]`, `[frequency]`, `[function]`, `[model_type]`, `[estimate_type]`, `[business_team]`, `[opco]`, `[vertical]`, `[product_type]` token in any object name **must** have a matching active row in REFERENCE.CATALOG before the object is created.
2. `data_status_code = blocked` → no downstream reads permitted.
3. `data_status_code = deprecated` → readable but not promotable.
4. PROD objects must never read from TRANSFORM.DEV or SOURCE_PROD.
5. ANALYTICS.DBT_STAGE.QA_ must have 0 ERROR rows before any DBT_PROD write.
6. SERVING.DEMO objects are dev only — no PROD objects may read from SERVING.DEMO.
7. Prefix governs object type: FEATURE_ MODEL_ ESTIMATE_ BI_ AI_ QA_ RAW_ FACT_ CONCEPT_ REF_ GEO_ AI_ CAT_.

---

## Alex — responsibilities (semantic-layer dbt & catalog)

**Do not edit the matrix above by hand** (it is generated from `schema_rules.csv`). This section is the **Alex-owned** interpretation for **`pretiumdata-dbt-semantic-layer`**: naming, **`TRANSFORM.DEV`** facts/concepts, **`REFERENCE.CATALOG` / `REFERENCE.AI`**, **`ANALYTICS.DBT_DEV` / `DBT_STAGE` / `DBT_PROD`** (Alex rows only), and **`SERVING`** rows where OWNER = Alex.

### What Alex owns in the matrix (summary)

| Area | SCHEMA_RULES rows | Alex scope |
|------|-------------------|------------|
| **REFERENCE** | Geography H3 lookup; **.AI** prompts/config; **.CATALOG** canon; lineage row (Jon/Alex) | Alex authors seeds / contracts consumed by dbt; **no** Jon **TRANSFORM.[VENDOR]** writes. |
| **SOURCE_PROD** | Landed dataset (DEV) | Register sources; **no** promotion of raw layout without catalog keys. |
| **TRANSFORM.DEV** | RAW / REF / **FACT** / QA / **CONCEPT** (Alex rows) | **Primary home** for migrated **`FACT_*`**, **`CONCEPT_*`**, and **`REF_*`** crosswalks materialized for analytics (see `docs/migration/MIGRATION_RULES.md`). |
| **ANALYTICS** | **DBT_DEV**, **DBT_STAGE**, **DBT_PROD** (FEATURE / MODEL / ESTIMATE / BI / AI / QA) | Alex builds and gates promotion per **Enforcement** §5–§7. |
| **SERVING** | **DEMO** (Alex rows), **MART** embeddings/synthesis (Alex) | Dev/demo delivery only; **§6** — PROD must not read **SERVING.DEMO**. |

Jon / David / Spencer rows in the same file are **not** edited here; Alex consumes **Jon** **`TRANSFORM.[VENDOR]`** and **REFERENCE.GEOGRAPHY`** via **`source()`** / **`ref()`** only.

### `TRANSFORM.DEV` — physical names vs row 64

Matrix row **“Vendor Dataset Cleaned”** (`TRANSFORM` / **`.DEV`** / **FACT**) shows a suffix pattern **`[vendor]_[dataset]_…`**. In **this** repo, canonical migrated objects use **dbt model aliases**: **`FACT_*`**, **`CONCEPT_*`**, and corridor **`REF_*`** (e.g. **`TRANSFORM.DEV.FACT_LODES_OD_WORKPLACE_HEX_ANNUAL`**, **`TRANSFORM.DEV.REF_CORRIDOR_EMPLOYMENT_CENTERS`**). That is still **one Snowflake schema `DEV`**, not a separate **`TRANSFORM.FACT`** schema (Jon PROD pattern on rows 35–36 is different).

### Catalog & enforcement (Alex)

- **§1** — Alex ensures **`REFERENCE.CATALOG`** seeds / dimensions exist for tokens used in **Alex-authored** object names before shipping.
- **§2–§3** — Alex respects **`data_status_code`** on catalog-driven paths.
- **§4** — Alex migration work stays on **DEV / STAGE** until promotion; no PROD graph reads **TRANSFORM.DEV** (see also CI ban on legacy PROD DBs in dbt **`models/`**).
- **Lineage (non-matrix)** — cross-cutting registers live under **`registry/lineage/`** (see `registry/lineage/README.md`); they do **not** replace **REFERENCE.CATALOG** but document vendor → dataset → fact for migration slices.
