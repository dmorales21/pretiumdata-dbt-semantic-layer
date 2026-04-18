# Migration Rules: pretium-ai-dbt → pretiumdata-dbt-semantic-layer
# Audience: Cursor / automated migration
# Owner: Alex
# Updated: 2026-04-18
#
# PURPOSE: These rules allow Cursor to migrate dbt models from the old repo
# (pretium-ai-dbt) to the new repo (pretiumdata-dbt-semantic-layer) consistently
# without human intervention on schema placement decisions.

---

## 1. REPO LAYOUT

Old repo (READ ONLY — do not write):
  /Users/aposes/dev/pretium/pretium-ai-dbt/

New repo (Alex owns — write here):
  /Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/

---

## 2. LAYER RULES — WHERE THINGS LIVE

### SOURCE_PROD.[VENDOR]
- Raw landing tables only. Named RAW_* or raw_*.
- No transformation logic. No joins. No derived columns.
- Any old model that writes a RAW_* table to TRANSFORM.DEV must be
  re-targeted to SOURCE_PROD.[VENDOR] in the new repo.
- Example: old `dbt/models/transform/dev/zillow_research/raw_zillow_home_values.sql`
  writing TRANSFORM.DEV.RAW_HOME_VALUES → new model writes SOURCE_PROD.ZILLOW.RAW_HOME_VALUES

### TRANSFORM.DEV
- FACT_* objects only. Reads from SOURCE_PROD.[VENDOR].RAW_* (direct, no ref())
  until Jon promotes a TRANSFORM.[VENDOR] canonical schema.
- Once TRANSFORM.[VENDOR] exists, re-point FACT models to ref() calls against it.
- REF_* objects: vendor-specific crosswalks only (e.g. REF_ZILLOW_COUNTY_TO_FIPS).
  These are seeds, not models.
- CONCEPT_* objects: derived concept tables built from FACT_ tables.
- NO raw_ or RAW_ tables. If you find one, move it to SOURCE_PROD.[VENDOR].

### TRANSFORM.[VENDOR]  (Jon's space — Alex does NOT write here)
- Canonical cleanse layer. Jon promotes from SOURCE_PROD → TRANSFORM.[VENDOR].
- Alex's FACT_ models may ref() these once they exist.
- Never create or modify schemas here.

### REFERENCE.GEOGRAPHY
- Census spine only: ZCTA, COUNTY, CBSA, BLOCKGROUP, TRACTS, STATE, H3 polyfills,
  and crosswalks between census geographies.
- No vendor content ever. No Zillow, Redfin, Markerr, etc. mappings here.

### REFERENCE.CATALOG
- Controlled vocabulary seeds: dimension tables, vendor registry, dataset registry.
- Seeded via `dbt seed --target reference`.

### REFERENCE.DRAFT
- In-progress seeds not yet promoted to CATALOG.
- e.g. dim_metric_dev.csv — header-only until TRANSFORM.FACT exists.

### TRANSFORM.DEV (seeds)
- Vendor xwalk CSVs land here as dbt seeds.
- Path: seeds/transform_dev/*.csv
- Schema YML: seeds/transform_dev/schema_transform_dev.yml

### ANALYTICS.DBT_DEV
- FEATURE_, MODEL_, ESTIMATE_, BI_, AI_ models built by Alex.
- Reads from TRANSFORM.DEV.FACT_* (dev path) or TRANSFORM.[VENDOR] (canonical).

### SERVING.DEMO
- Delivery surface for dev analytics outputs.

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

* Copied from TRANSFORM_PROD.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING — rename to
  REF_ZILLOW_METRO_TO_CBSA in new repo.

---

## 9. WHAT NOT TO MIGRATE

Do NOT migrate:
- TRANSFORM.[VENDOR] canonical models (Jon's space)
- Any model that only exists to serve TRANSFORM_PROD.FACT (old canonical layer)
- Legacy `cleaned_*` models that duplicate Jon's TRANSFORM.[VENDOR] work
- Models with no downstream consumers (check with dbt ls --select +model_name)
