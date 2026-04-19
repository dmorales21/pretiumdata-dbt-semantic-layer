# Migration Rules: pretium-ai-dbt → pretiumdata-dbt-semantic-layer
# Audience: Cursor / automated migration
# Owner: Alex
# Updated: 2026-04-18
#
# PURPOSE: These rules allow Cursor to migrate dbt models **from Alex’s old repo**
# (**pretium-ai-dbt**) **into clean canonical format** in **pretiumdata-dbt-semantic-layer**.
# **Alex owns both repositories.** Jon is scoped to the **Snowflake PROD vendor canonical layer**
# (`TRANSFORM.[VENDOR]` — Alex reads, does not write there).

---

## 1. REPO LAYOUT

**pretium-ai-dbt** (Alex — migration **source**; deprecated as the home for **new** canonical dbt writes):
  /Users/aposes/dev/pretium/pretium-ai-dbt/

**pretiumdata-dbt-semantic-layer** (Alex — migration **destination**; canonical dbt **target**):
  /Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/

**Full object register (what to migrate, inventories, cluster status):** `MIGRATION_TASKS.md` — not duplicated here.

**Audit logging (split to limit sprawl):** append a **short** row to **`MIGRATION_LOG.md`** each session; put multi-paragraph evidence, Snowflake numbers, and artifact paths in **`MIGRATION_BATCH_INDEX.md`**. **New `metric` / `metric_derived` rows:** follow **`METRIC_INTAKE_CHECKLIST.md`** and **`PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md`** (features, four chains, Pilot A, CI). **CI (parse + catalog smoke):** `.github/workflows/semantic_layer_catalog_and_quality.yml`; optional Snowflake **`dbt seed` / `dbt test`** block in that file after **`SNOWFLAKE_*`** secrets exist. **Local:** `scripts/ci/run_catalog_quality_checks.sh`.

---

## 2. LAYER RULES — WHERE THINGS LIVE

### Build order (Alex migration)

**Ship `TRANSFORM.DEV` `FACT_*` and `CONCEPT_*` in the semantic-layer repo before prioritizing `ANALYTICS.DBT_DEV`.**  
Land **`SOURCE_PROD.[VENDOR].RAW_*`** and **`TRANSFORM.DEV.REF_*`** only as needed for those facts/concepts to compile and test.

### SOURCE_PROD.[VENDOR]
- Raw landing tables only. Named RAW_* or raw_*.
- No transformation logic. No joins. No derived columns.
- Any old model that writes a RAW_* table to TRANSFORM.DEV must be
  re-targeted to SOURCE_PROD.[VENDOR] in the new repo.
- Example: old `dbt/models/transform/dev/zillow_research/raw_zillow_home_values.sql`
  writing TRANSFORM.DEV.RAW_HOME_VALUES → new model writes SOURCE_PROD.ZILLOW.RAW_HOME_VALUES

### SOURCE_SNOW.GLOBAL_GOVERNMENT (Cybersyn share)
- Native **Snowflake Marketplace** objects for the **GLOBAL_GOVERNMENT** share — **not** `SOURCE_PROD` landings. Register in **`models/sources/sources_global_government.yml`**.
- **`REFERENCE.GEOGRAPHY`** models read Cybersyn `geography_*` tables here; **`REFERENCE.CATALOG`** seeds (**`vendor`**, **`cybersyn_catalog_table_vendor_map`**) govern **underlying agency** per `CYBERSYN_DATA_CATALOG.table_name`. See [`reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`](../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md).

### TRANSFORM.DEV
- **`FACT_*`** and **`CONCEPT_*`** objects only (no base facts/concepts in **ANALYTICS**). Reads from SOURCE_PROD.[VENDOR].RAW_* (direct, no ref())
  until Jon promotes a TRANSFORM.[VENDOR] canonical schema. Cybersyn-backed facts may additionally read **`SOURCE_SNOW.GLOBAL_GOVERNMENT`** once sources and **`REFERENCE.GEOGRAPHY`** dictionary paths are stable.
- Once TRANSFORM.[VENDOR] exists, re-point FACT/CONCEPT models to ref() calls against it.
- REF_* objects: vendor-specific crosswalks only (e.g. REF_ZILLOW_COUNTY_TO_FIPS).
  These are seeds, not models.
- CONCEPT_* objects: derived concept tables built from FACT_ tables.
- NO raw_ or RAW_ tables. If you find one, move it to SOURCE_PROD.[VENDOR].

### TRANSFORM.[VENDOR]  (**Jon — PROD layer only**; Alex does **not** author here)
- Canonical **PROD** vendor cleanse / landings. Jon promotes from SOURCE_PROD → TRANSFORM.[VENDOR].
- Alex’s **FACT_** / **CONCEPT_** models in **`TRANSFORM.DEV`** may **`ref()` / `source()`** these once they exist.
- Alex migration **never** creates or alters objects in Jon’s schemas.

### REFERENCE.GEOGRAPHY
- Census spine only: ZCTA, COUNTY, CBSA, BLOCKGROUP, TRACTS, STATE, H3 polyfills,
  and crosswalks between census geographies.
- No vendor content ever. No Zillow, Redfin, Markerr, etc. mappings here.

### REFERENCE.CATALOG
- Controlled vocabulary seeds: dimension tables, vendor registry, dataset registry.
- Seeded via `dbt seed --target reference`.
- **`cybersyn_catalog_table_vendor_map`** — one row per distinct `CYBERSYN_DATA_CATALOG.table_name` from the Cybersyn GLOBAL_GOVERNMENT share list; `underlying_vendor_code` references **`vendor`** (statistical agency / program, not the share republisher alone). Regenerate and test per [`reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`](../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md#how-to-run-dataset-tests).

### REFERENCE.DRAFT
- In-progress seeds not yet promoted to CATALOG.
- e.g. dim_metric_dev.csv — header-only until TRANSFORM.FACT exists.

### TRANSFORM.DEV (seeds)
- Vendor xwalk CSVs land here as dbt seeds.
- Path: seeds/transform_dev/*.csv
- Schema YML: seeds/transform_dev/schema_transform_dev.yml

### ANALYTICS.DBT_DEV
- **`FEATURE_`**, **`MODEL_`**, **`ESTIMATE_`** models built by Alex only.
- **No `FACT_*` and no `CONCEPT_*` in ANALYTICS** — those materialize only in **`TRANSFORM.DEV`**.
- Reads from **`TRANSFORM.DEV.FACT_*`** / **`CONCEPT_*`** (via `ref()`) or **`TRANSFORM.[VENDOR]`** (canonical vendor reads).

### SERVING.DEMO
- Delivery surface for dev analytics outputs.

---

## 2A. RETIRE OLD NAMES (CANONICAL CUTOVER)

- Each logical object has **one** canonical Snowflake name under the Alex contract (**`SOURCE_PROD` / `TRANSFORM.DEV` / `ANALYTICS.DBT_DEV` / `REFERENCE.*` / `SERVING.DEMO`** as designed). **Do not** leave production consumers on legacy **`TRANSFORM_PROD.*`**, **`ANALYTICS.FACTS.*`** (as a physical store), or stale **`EDW_PROD.*`** paths after migration.
- **Order:** (1) ship new object + wire **`strata_backend` / tearsheet / dbt** to the new name, (2) optional short-lived **compat view** with a documented sunset, (3) **`MIGRATION_LOG.md`**: list old object under **Deprecation candidates**, (4) after validation, **`DROP`** or remove view and set **`confirmed_drop`**.
- Log every rename: **`old_reference` → `new_reference`** in **`MIGRATION_LOG.md`** (and one row per consumer app change if tracked separately).

---

## 3. MODEL MIGRATION CHECKLIST

For every model migrated from pretium-ai-dbt → pretiumdata-dbt-semantic-layer:

[ ] 1. Identify where the old model writes (TRANSFORM.DEV, TRANSFORM_PROD, etc.)
[ ] 2. Classify by layer rule above — determine correct target schema in new repo
[ ] 3. If the model writes a RAW_* table → re-target to SOURCE_PROD.[VENDOR]
[ ] 4. If the model writes a FACT_* table → keep in TRANSFORM.DEV
[ ] 5. Rename columns to snake_case if not already
[ ] 6. Replace hardcoded database/schema references with dbt sources/refs
[ ] 7. Add geo enrichment joins where GEO_LEVEL_CODE appears without CBSA_ID/COUNTY_FIPS:
       - ZIP grain: join GEO_ID → REFERENCE.GEOGRAPHY.ZCTA_CBSA_XWALK
       - County grain: join GEO_ID → REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK
       - Metro grain: join GEO_ID → TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA (vendor xwalk)
         or equivalent vendor xwalk for non-Zillow sources
[ ] 8. Normalize GEO_LEVEL_CODE values to REFERENCE.CATALOG.geo_level vocabulary:
       metro → cbsa, neighborhood → EXCLUDED, city → EXCLUDED (no census spine)
[ ] 9. Place model SQL in correct new repo path (see §4 below)
[ ] 10. Write schema.yml entry with not_null + unique tests on PK, FK tests on geo keys
[ ] 11. Add to sources_transform.yml if reading from SOURCE_PROD for first time
[ ] 12. **Retire old names:** update all consumers to the canonical FQN (or `ref`/`source`); add deprecation row; remove compat views after **`confirmed_drop`**

---

## 4. NEW REPO PATH CONVENTIONS

| Model type         | Old repo path (example)                            | New repo path                                      |
|--------------------|----------------------------------------------------|----------------------------------------------------|
| RAW landing        | models/transform/dev/zillow_research/raw_*.sql     | models/sources/source_prod/zillow/raw_*.sql        |
| FACT (DEV)         | models/transform/dev/zillow_research/fact_*.sql    | models/transform/dev/zillow/fact_*.sql             |
| CONCEPT (DEV)      | models/transform/dev/concept_*.sql                 | models/transform/dev/concepts/concept_*.sql        |
| FEATURE (analytics)| models/analytics/features/feature_*.sql           | models/analytics/feature/feature_*.sql             |
| REF xwalk (seed)   | (manual CSV in old repo)                           | seeds/transform_dev/ref_[vendor]_*.csv             |

---

## 5. SOURCE DECLARATIONS

When migrating a model that reads SOURCE_PROD.[VENDOR].RAW_*:
- Add the source to models/sources/sources_transform.yml if not already present
- Use: {{ source('vendor_code', 'raw_table_name') }}
- Do NOT hardcode database.schema.table strings in model SQL

When reading TRANSFORM.DEV.FACT_* in an analytics model:
- Use: {{ ref('fact_table_name') }}
- This works because TRANSFORM.DEV models are in the same dbt project

---

## 6. GEO COMPLIANCE RULE

Any FACT_ model that has a GEO_LEVEL_CODE column MUST also populate:
- CBSA_ID (for metro, county, zip grains) via REFERENCE.GEOGRAPHY xwalk
- COUNTY_FIPS (for county, zip grains) via REFERENCE.GEOGRAPHY xwalk
- STATE_FIPS (for state grain) — derive from GEO_ID if 2-digit state FIPS

Grains with no census spine (city, neighborhood) must be EXCLUDED from FACT_ models
or tagged with a quality_flag = 'no_census_spine' column.

---

## 7. NAMING CONVENTIONS

- All column names: snake_case
- All model names: snake_case, prefixed by layer (fact_, concept_, feature_, ref_, raw_)
- Zillow GEO_LEVEL_CODE normalization:
    metro → cbsa
    county → county
    zip → zip
    state → state
    city → EXCLUDED
    neighborhood → EXCLUDED
- geo_level_code values must match REFERENCE.CATALOG.geo_level.geo_level_code

---

## 8. KNOWN VENDOR XWALKS IN TRANSFORM.DEV (seeds)

| Seed table                        | Key column        | Maps to                          |
|-----------------------------------|-------------------|----------------------------------|
| REF_ZILLOW_COUNTY_TO_FIPS         | county_region_id  | fips_5digit, cbsa_code           |
| REF_ZILLOW_CITY_TO_COUNTY         | unique_city_id    | county_name + state_abbr         |
| ZILLOW_TO_CENSUS_CBSA_MAPPING*    | zillow_6_digit    | CENSUS_5_DIGIT (CBSA)            |

* Copied from `TRANSFORM.REF` or `TRANSFORM_PROD.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING` — materialize as
  `TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA` in Snowflake. Worksheet template:
  `docs/migration/sql/create_ref_zillow_metro_to_cbsa.sql`.

---

## 9. WHAT NOT TO MIGRATE

Do NOT migrate:
- TRANSFORM.[VENDOR] canonical models (Jon's space)
- Any model that only exists to serve TRANSFORM_PROD.FACT (old canonical layer)
- Legacy `cleaned_*` models that duplicate Jon's TRANSFORM.[VENDOR] work
- Models with no downstream consumers (check with dbt ls --select +model_name)


---

## 10. REFERENCE.GEOGRAPHY — EXACT SCHEMAS

Canonical census spine. Use exact column names below in all joins — no aliasing.

### Spine tables

| Table       | PK    | Key columns                                         | Has POLYGON |
|-------------|-------|-----------------------------------------------------|-------------|
| STATE       | GEOID | GEOID (2-digit), NAME, YEAR                         | yes         |
| COUNTY      | GEOID | GEOID (5-digit FIPS), COUNTYFP, STATEFP, NAME, YEAR | yes         |
| CBSA        | GEOID | GEOID (5-digit CBSA code), NAME, YEAR               | yes         |
| TRACTS      | GEOID | GEOID (11-digit), STATEFP, COUNTYFP, TRACTCE, YEAR  | yes         |
| BLOCKGROUPS | GEOID | GEOID (12-digit), STATEFP, COUNTYFP, TRACTCE, BLKGRPCE, YEAR | yes |
| PLACE       | GEOID | GEOID, PLACEFP, STATEFP, NAME, YEAR                 | yes         |
| ZCTA        | GEOID | GEOID (5-digit ZIP), YEAR                           | yes         |

### Crosswalk tables — exact columns

**COUNTY_CBSA_XWALK**
```
COUNTY_FIPS TEXT, COUNTY_NAME TEXT, CBSA_CODE TEXT, CBSA_NAME TEXT,
YEAR NUMBER, COUNTY_COVERAGE_PCT FLOAT
```

**ZCTA_CBSA_XWALK**
```
ZCTA TEXT, CBSA TEXT, CBSA_NAME TEXT
```
⚠️ Column is named `CBSA` not `CBSA_CODE`. Use this exactly.

**CBSA_STATE_XWALK**
```
CBSA_CODE TEXT, CBSA_NAME TEXT, STATE_FIPS TEXT, STATE_NAME TEXT,
YEAR NUMBER, CBSA_COVERAGE_PCT FLOAT
```

**BLOCKGROUP_COUNTY_XWALK**
```
BG_GEOID TEXT, COUNTY_GEOID TEXT, COUNTY_NAME TEXT, YEAR NUMBER, PCT_OVERLAP FLOAT
```

**BLOCKGROUP_CBSA_XWALK**
```
BG_GEOID TEXT, CBSA_GEOID TEXT, CBSA_NAME TEXT, YEAR NUMBER, PCT_OVERLAP FLOAT
```

**BLOCKGROUP_PLACE_XWALK**
```
BG_GEOID TEXT, PLACE_GEOID TEXT, PLACE_NAME TEXT, YEAR NUMBER, PCT_OVERLAP FLOAT
```

**PLACE_COUNTY_XWALK**
```
PLACE_GEOID TEXT, PLACE_NAME TEXT, PLACEFP TEXT, PLACE_STATEFP TEXT,
COUNTY_GEOID TEXT, COUNTY_NAME TEXT, COUNTYFP TEXT, COUNTY_STATEFP TEXT,
PLACE_YEAR NUMBER, COUNTY_YEAR NUMBER, PLACE_COVERAGE_PCT FLOAT
```

**PLACE_CBSA_XWALK**
```
PLACE_GEOID TEXT, PLACE_NAME TEXT, PLACEFP TEXT, STATEFP TEXT,
CBSA_GEOID TEXT, CBSA_NAME TEXT, PLACE_YEAR NUMBER, CBSA_YEAR NUMBER,
PLACE_COVERAGE_PCT FLOAT
```

### H3 polyfill tables

**COUNTY_H3_R8_POLYFILL**: COUNTY_FIPS, CBSA_ID, H3_R8_HEX, WEIGHT, H3_R6_HEX
**COUNTY_H3_R6_POLYFILL**: COUNTY_FIPS, CBSA_ID, H3_R6_HEX, WEIGHT, H3_R4_HEX
**COUNTY_H3_R4_POLYFILL**: COUNTY_FIPS, CBSA_ID, H3_R4_HEX, WEIGHT
**CBSA_H3_R8_POLYFILL**:   CBSA_ID, CBSA_NAME, H3_R8_HEX, WEIGHT, H3_R6_HEX
**CBSA_H3_R6_POLYFILL**:   CBSA_ID, CBSA_NAME, H3_R6_HEX, WEIGHT, H3_R4_HEX
**CBSA_H3_R4_POLYFILL**:   CBSA_ID, CBSA_NAME, H3_R4_HEX, WEIGHT

### Standard geo enrichment join patterns

```sql
-- ZIP grain → CBSA
LEFT JOIN REFERENCE.GEOGRAPHY.ZCTA_CBSA_XWALK z
    ON src.geo_id = z.ZCTA
-- yields: z.CBSA (use as CBSA_ID), z.CBSA_NAME

-- County FIPS → CBSA
LEFT JOIN REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK c
    ON src.county_fips = c.COUNTY_FIPS
-- yields: c.CBSA_CODE (use as CBSA_ID), c.CBSA_NAME

-- Zillow metro GEO_ID → CBSA (vendor xwalk, TRANSFORM.DEV)
LEFT JOIN TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA m
    ON src.geo_id = m.zillow_region_id
-- yields: m.cbsa_id, m.cbsa_name

-- Zillow county GEO_ID → FIPS (vendor xwalk, TRANSFORM.DEV)
LEFT JOIN TRANSFORM.DEV.REF_ZILLOW_COUNTY_TO_FIPS x
    ON CAST(src.geo_id AS TEXT) = CAST(x.county_region_id AS TEXT)
-- yields: x.fips_5digit (use as COUNTY_FIPS), x.cbsa_code (use as CBSA_ID)

-- H3 R8 → COUNTY + CBSA
LEFT JOIN REFERENCE.GEOGRAPHY.COUNTY_H3_R8_POLYFILL h
    ON src.h3_r8_hex = h.H3_R8_HEX
-- yields: h.COUNTY_FIPS, h.CBSA_ID
```

---

## 9. WHAT NOT TO MIGRATE

Do NOT migrate:
- TRANSFORM.[VENDOR] canonical models (Jon's space)
- Any model that only exists to serve TRANSFORM_PROD.FACT (old canonical layer)
- Legacy `cleaned_*` models that duplicate Jon's TRANSFORM.[VENDOR] work
- Models with no downstream consumers (check with dbt ls --select +model_name)
