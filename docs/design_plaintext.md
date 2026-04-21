# Database architecture (plaintext)

Plain-language view of how Snowflake areas relate in this program.  
Authoritative detail: [rules/ARCHITECTURE_RULES.md](./rules/ARCHITECTURE_RULES.md), [rules/SCHEMA_RULES.md](./rules/SCHEMA_RULES.md), [migration/MIGRATION_RULES.md](./migration/MIGRATION_RULES.md), [OPERATING_MODEL.md](./OPERATING_MODEL.md). Cybersyn share path: [reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md](./reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md).

---

## 1) Layer stack (data generally flows downward)

```
  [ Files / shares / pipelines outside Snowflake ]
              |
              v
+-------------------------------------------------------------+
|  RAW                    vendor raw landings (Jon / market) |
|  SOURCE_PROD.[VENDOR]     RAW_* only — no transform logic    |
|  SOURCE_ENTITY.[OPCO]     OpCo-specific landed / shared     |
+-------------------------------------------------------------+
              |
              v
+-------------------------------------------------------------+
|  TRANSFORM.[VENDOR]       Jon PROD: cleansed vendor layer   |
|            (Alex reads; dbt here does not write)            |
+-------------------------------------------------------------+
              |
              |  until [VENDOR] exists: FACT_* reads RAW_* in
              |  SOURCE_PROD directly; then ref() to TRANSFORM.[VENDOR]
              v
+-------------------------------------------------------------+
|  TRANSFORM.DEV            Alex: FACT_*, CONCEPT_*, REF_*    |
|            (no RAW_* here — RAW belongs in SOURCE_PROD)     |
+-------------------------------------------------------------+
              |
              v
+-------------------------------------------------------------+
|  TRANSFORM.FACT / TRANSFORM.CONCEPT   canonical PROD facts  |
|            (target state; not fully live — see ARCH rules)  |
+-------------------------------------------------------------+
              |
              v
+-------------------------------------------------------------+
|  REFERENCE.GEOGRAPHY      census spine & non-vendor xwalks  |
|  REFERENCE.CATALOG      dims / controlled vocabulary        |
|    (includes vendor + cybersyn_catalog_table_vendor_map —  |
|     see §6 and CYBERSYN bring-in matrix)                    |
|  REFERENCE.DRAFT        in-progress seeds → CATALOG           |
+-------------------------------------------------------------+
              ^
              |  joins / registry; never vendor-only xwalks in GEO
              |
+-------------------------------------------------------------+
|  ANALYTICS.DBT_DEV        FEATURE_*, MODEL_*, ESTIMATE_*     |
|  ANALYTICS.DBT_STAGE    staged for promotion               |
|  ANALYTICS.DBT_PROD     prod analytics objects             |
|            (no FACT_* / CONCEPT_* — those stay TRANSFORM)  |
+-------------------------------------------------------------+
              |
              v
+-------------------------------------------------------------+
|  SERVING.MART / COLLECTION / EXPORT   delivery surfaces     |
|  SERVING.DEMO                         dev delivery (Alex)   |
+-------------------------------------------------------------+
```

**1a) Cybersyn share (parallel ingestion, not `SOURCE_PROD`)** — `SOURCE_SNOW.GLOBAL_GOVERNMENT` holds native share tables (`geography_*`, domain `timeseries`, `CYBERSYN_DATA_CATALOG`, …). dbt **reads** them into **`REFERENCE.GEOGRAPHY`** models and (later) **`TRANSFORM.DEV`** facts; **`REFERENCE.CATALOG`** seeds record **underlying statistical agency** per `table_name` via **`cybersyn_catalog_table_vendor_map`**. Details: [reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md](./reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md).

---

## 2) Side-by-side: reference vs vendor content

```
  Vendor-native paths                Canonical reference paths
  -------------------                ---------------------------

  SOURCE_PROD.[VENDOR].RAW_*         REFERENCE.CATALOG.*
         |                                    ^
         |                                    |
         v                                    |
  TRANSFORM.[VENDOR]  ----------+           |
  (Jon PROD cleanse)             |           |
         |                       |           |
         +--> TRANSFORM.DEV      +----------+ joins / keys / metric registry
              FACT_* / CONCEPT_*              (geo spine: REFERENCE.GEOGRAPHY)

  Vendor-only crosswalks (e.g. metro→CBSA) live in TRANSFORM.DEV as REF_* until
  Jon promotes equivalents under TRANSFORM.[VENDOR]. They do not belong in
  REFERENCE.GEOGRAPHY.
```

---

## 3) Ownership snapshot (who authors where)

```
  Jon (PROD vendor / RAW promotion)     Alex (this repo / migration)
  --------------------------------      ------------------------------
  TRANSFORM.[VENDOR]                    TRANSFORM.DEV (FACT_, CONCEPT_, REF_)
  SOURCE_PROD → vendor cleanse path     SOURCE_PROD.[VENDOR] RAW_* models
  REFERENCE rows Jon owns per table     REFERENCE.CATALOG / GEOGRAPHY / DRAFT
                                        ANALYTICS.DBT_* (FEATURE/MODEL/ESTIMATE)
                                        SERVING.DEMO
```

---

## 4) This repository vs Snowflake tool paths

```
  pretiumdata-dbt-semantic-layer (this repo)
       |
       +-- dbt models/seeds for canonical contract (sources, TRANSFORM.DEV facts, REFERENCE seeds, etc.)
       |
       +-- default dbt `dev` target may map to semantic MART databases
            (see dbt_project.yml `semantic_database_map`; not the same as "TRANSFORM.DEV only via dbt")

  TRANSFORM.DEV tables created via SnowSQL / operators
       |
       +-- documented in owning repo/scripts; not assumed to be emitted by dbt `dev` alone
```

See [OPERATING_MODEL.md](./OPERATING_MODEL.md) for the split between SnowSQL → `TRANSFORM.DEV` and dbt → `ANALYTICS` / semantic marts.

---

## 5) Metric registration (conceptual gate)

```
  Column on FACT_* at grain
            |
            +--> null coverage / history / catalog codes / census-geo join coverage
                          |
                          v
              REFERENCE.DRAFT / CATALOG metric registry
              (only after all gates pass — see ARCHITECTURE_RULES.md)
```

---

## 6) Cybersyn share → reference spine (compact)

```
  CYBERSYN_DATA_CATALOG.table_name  (distinct list in docs/migration/artifacts/*.tsv)
              |
              v
  seeds/.../cybersyn_catalog_table_vendor_map.csv
  (regenerate: scripts/reference/catalog/regenerate_cybersyn_catalog_table_vendor_map.py)
              |
              +--> underlying_vendor_code -----> REFERENCE.CATALOG.vendor
              +--> matrix_tier / is_pit_companion -> bring-in matrix tiers

  SOURCE_SNOW...geography_index (+ _pit companions)
              |
              v
  REFERENCE.GEOGRAPHY.GEOGRAPHY_LEVEL_DICTIONARY  (LEVEL -> geo_level_code)
              |
              v
  REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX (+ codes, shapes, relationships, flattened latest)
```

Runbook (seed + tests): [reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md](./reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md#how-to-run-dataset-tests).
