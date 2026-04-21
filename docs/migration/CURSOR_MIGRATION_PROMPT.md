# Cursor Migration Prompt: pretium-ai-dbt → pretiumdata-dbt-semantic-layer
# Copy this entire prompt into Cursor to initiate the migration session.

---

You are migrating dbt models from an old Pretium Partners repo into a new governed repo.
Read all referenced rule files before writing a single line of code.

## Your identity in this task
- You are operating as Alex's engineering agent (Alex owns **both** repos; you migrate **into** the new repo only)
- You own TRANSFORM.DEV, ANALYTICS.DBT_DEV, SERVING.DEMO, REFERENCE.GEOGRAPHY,
  REFERENCE.CATALOG, REFERENCE.DRAFT in Snowflake
- You do NOT write **Jon’s PROD** `TRANSFORM.[VENDOR]` canonical vendor schemas — read via `source()` only
- **Build order:** Land **`TRANSFORM.DEV.FACT_*`** and **`TRANSFORM.DEV.CONCEPT_*`** (plus minimal `SOURCE_PROD` `RAW_*` / `TRANSFORM.DEV` `REF_*` to compile them) **before** prioritizing **`ANALYTICS.DBT_DEV`**
- When in doubt about placement, consult ARCHITECTURE_RULES.md

## Rule files — read these first, in order
1. docs/rules/ARCHITECTURE_RULES.md  — binding placement and layer rules
2. docs/rules/SCHEMA_RULES.md        — naming and materialization conventions
3. docs/migration/MIGRATION_RULES.md — step-by-step migration checklist per model
4. docs/PIPELINE_STATUS.md           — pipeline_status vocabulary for dataset registry

## Repos
- Old repo (READ ONLY):  /Users/aposes/dev/pretium/pretium-ai-dbt/
- New repo (write here): /Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/

## Snowflake context
- Canonical census geography xwalks: REFERENCE.GEOGRAPHY (ZCTA, COUNTY, CBSA, etc.)
- Vendor xwalk seeds: TRANSFORM.DEV (REF_ZILLOW_COUNTY_TO_FIPS, REF_ZILLOW_CITY_TO_COUNTY)
- Raw landings: SOURCE_PROD.[VENDOR].RAW_*
- Dev facts / concepts: **`TRANSFORM.DEV.FACT_*`** and **`TRANSFORM.DEV.CONCEPT_*`** (primary migration targets)

## Migration task — Zillow (do this first as the pilot)

The 10 old Zillow FACT models live at:
  pretium-ai-dbt/dbt/models/transform/dev/zillow_research/

For each model:
1. Read the old SQL
2. Apply MIGRATION_RULES.md §3 checklist
3. Key corrections required for all Zillow models:
   a. RAW_* source tables must be declared via source('zillow', 'raw_*') pointing to
      SOURCE_PROD.ZILLOW — NOT TRANSFORM.DEV
   b. GEO_LEVEL_CODE 'metro' → normalize to 'cbsa'
   c. GEO_LEVEL_CODE 'city' and 'neighborhood' → exclude those rows
      (add WHERE geo_level_code NOT IN ('city', 'neighborhood'))
   d. Geo enrichment — add these joins where missing:
      - ZIP grain:    LEFT JOIN REFERENCE.GEOGRAPHY.ZCTA_CBSA_XWALK x
                        ON z.geo_id = x.zcta
      - County grain: JOIN {{ ref('ref_zillow_county_to_fips') }} xwalk
                        ON z.geo_id = CAST(xwalk.county_region_id AS TEXT)
      - Metro grain:  LEFT JOIN TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA xwalk
                        ON z.geo_id = xwalk.zillow_region_id
   e. CBSA_ID and COUNTY_FIPS must be populated for all rows that pass geo compliance
   f. geo_level_code must match REFERENCE.CATALOG.geo_level vocabulary exactly
4. Write migrated model to:
      new_repo/models/transform/dev/zillow/fact_zillow_<dataset>.sql
5. Write schema.yml entry to:
      new_repo/models/transform/dev/zillow/schema.yml
6. Register any new SOURCE_PROD.ZILLOW source tables in:
      new_repo/models/sources/sources_transform.yml

## After Zillow — object reduction plan

After Zillow models are migrated and passing dbt compile:
1. List every TRANSFORM.DEV table that has a corresponding migrated model in new repo
2. Flag any TRANSFORM.DEV tables that are:
   - Misnamed (RAW_* should be in SOURCE_PROD)
   - Duplicates of TRANSFORM.[VENDOR] canonical tables
   - Orphaned (no downstream ref())
3. Output a prioritized deprecation list — do NOT drop anything without Alex confirming

## Compliance check (Alex will run this after)

After migration, Alex will verify each model passes:
  [ ] Gate 1: null coverage >80% on metric columns
  [ ] Gate 2: >=12 months history
  [ ] Gate 3: geo_level_code in REFERENCE.CATALOG.geo_level
  [ ] Gate 4: CBSA_ID/COUNTY_FIPS coverage >=95% at stated grain

If a model fails any gate, mark pipeline_status = 'transform_dev' and add a comment
in the SQL header: -- GEO_COMPLIANCE: PENDING — [reason]

## Output expected from this session
- 10 migrated fact_zillow_*.sql files in new repo
- 1 schema.yml covering all 10 models
- Updated sources_transform.yml
- Deprecation candidate list for TRANSFORM.DEV cleanup
