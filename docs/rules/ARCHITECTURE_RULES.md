# Architecture Rules
# Owner: Alex
# Purpose: Governing rules for the pretiumdata-dbt-semantic-layer project.
#          These are binding decisions, not suggestions. Update when new rules are established.
# Separate from SCHEMA_RULES.md which covers naming/materialization conventions.
#
# **Repositories:** **Alex** owns **100%** of **pretium-ai-dbt** and **pretiumdata-dbt-semantic-layer**.
# This repo is where **clean canonical dbt** for the new contract is **written**; **pretium-ai-dbt**
# is the **migration source** (and SnowSQL/runbooks) until retired. **Jon** owns the **Snowflake PROD**
# vendor canonical layer only (**`TRANSFORM.[VENDOR]`** — Alex **reads**, does not write).
#
# **Migration / build priority:** Ship **`TRANSFORM.DEV`** **`FACT_*`** and **`CONCEPT_*`** here
# **before** prioritizing **`ANALYTICS.DBT_DEV`**. Use **`SOURCE_PROD` `RAW_*`** and **`TRANSFORM.DEV` `REF_*`**
# only as needed for those facts/concepts to compile and pass tests.
#
# **Vendor vs catalog:** Vendor-native content stays in **`SOURCE_PROD`** / **`TRANSFORM.DEV`** / Jon **`TRANSFORM.[VENDOR]`**.
# **`REFERENCE.CATALOG`** = canonical dims / controlled vocabulary — not vendor tables.
# **`CONCEPT.domain`** is one of **`housing` \| `household` \| `place` \| `capital` \| `portfolio`** (seed **`domain.csv`**); assignment rules: **`CONCEPT_DOMAIN_POLICY.md`**.
#
# **Naming:** Keep the semantic-layer pattern (**`SCHEMA_RULES.md`**) — short, prefixed identifiers; do not
# migrate toward longer or more complex names than the new canon requires. See **`NAMING_RULES_INDEX.md`** for links.

## Source vs Transform Layer Split

- **SOURCE_PROD.[VENDOR]** — raw landings only. No transformation logic. Tables named `RAW_*`.
  Jon owns promotion of SOURCE_PROD → TRANSFORM.[VENDOR] cleaned layer.
  **RAW_ models must write to SOURCE_PROD.[VENDOR], NOT TRANSFORM.DEV.**
  Any model in the old repo (pretium-ai-dbt) that writes a RAW_* table to TRANSFORM.DEV
  is misplaced — migrate it to SOURCE_PROD.[VENDOR] in the new repo.
- **TRANSFORM.DEV** — **`FACT_*`** (vendor-native cleaned corridor / vendor tables only — typing, renames, vendor-grain fixes, vendor-appropriate rollups) and **`CONCEPT_*`** (semantic concept unions from facts with catalog-driven grain). **Multi-vendor assembly panels** (joining several corridor facts for an app surface) do **not** belong here; they materialize under **ANALYTICS** **`FEATURE_*`** (see **`SCHEMA_RULES.md`**). In Alex's dev path, these models read directly
  from SOURCE_PROD.[VENDOR].RAW_* when no TRANSFORM.[VENDOR] schema exists yet.
  Once Jon promotes a vendor's cleanse layer, FACT models re-point to ref() calls against
  TRANSFORM.[VENDOR] instead of SOURCE_PROD.
- **TRANSFORM.DEV `REF_*`** — vendor-specific crosswalks (e.g. REF_ZILLOW_COUNTY_TO_FIPS).
  Not census spine — do NOT place in REFERENCE.GEOGRAPHY. Stay in TRANSFORM.DEV until
  Jon promotes to TRANSFORM.[VENDOR].
- **REFERENCE.GEOGRAPHY** — census spine objects only (ZCTA, COUNTY, CBSA, BLOCKGROUP, H3
  polyfills, and non-vendor xwalks). No vendor-specific content ever.

- Non-vendor crosswalks (census spine, H3, ZIP-county-CBSA) must live in **REFERENCE.GEOGRAPHY**
- Vendor-specific crosswalks in **PROD** belong in **`TRANSFORM.[VENDOR]`** — **Jon’s PROD layer**; Alex does not author there.
- Until Jon promotes vendor xwalks to **`TRANSFORM.[VENDOR]`**, Alex’s dev path is **`TRANSFORM.DEV`** **`REF_*`** (seeds / tables).

## Schema Ownership Boundaries

| Schema | Owner | Notes |
|---|---|---|
| TRANSFORM.DEV | Alex | Dev **`FACT_*`** (vendor-native only), **`CONCEPT_*`**, **`REF_*`**, CLEANED_ work — **physical home for dbt-authored `CONCEPT_*` unions** (`models/transform/dev/concept/`). Do **not** place those reads on `MART_{env}.SEMANTIC`; use `ref()` and this repo’s target resolution. |
| TRANSFORM.[VENDOR] | **Jon (PROD)** | Canonical vendor **PROD** schemas — Alex **reads** only; no dbt writes from Alex migration |
| ANALYTICS.DBT_DEV | Alex | **`FEATURE_`**, **`MODEL_`**, **`ESTIMATE_`** dev models only — **no** `FACT_*` / `CONCEPT_*` (those live in **TRANSFORM.DEV** only). Legacy `BI_*` / `AI_*` names in older work → rename into **`MODEL_*`** / **`ESTIMATE_*`** (or move out of `ANALYTICS` per `SCHEMA_RULES.md`). |
| SERVING.DEMO | Alex | Delivery surface for dev analytics outputs |
| REFERENCE.GEOGRAPHY | Alex | Census spine, H3 crosswalks, ZIP-county-CBSA xwalks |
| REFERENCE.CATALOG | Alex | Controlled vocabulary and dimension registry |
| REFERENCE.DRAFT | Alex | In-progress seeds pending promotion to CATALOG |

## Metric registry — built `metric` vs backlog `metric_raw`

**Hand edits and bulk merges** go to **`seeds/reference/catalog/metric_raw.csv`**. **REFERENCE.CATALOG.METRIC**
is loaded from **`seeds/reference/catalog/metric.csv`**, which is **generated** by
`scripts/reference/catalog/build_metric_csv_from_metric_raw.py` (TRANSFORM.DEV **FACT_** / **CONCEPT_**
core ∪ catalog FK closure — see **`docs/reference/METRIC_CSV_BUILD_SPEC.md`**). CI runs the generator before `dbt parse`.

**`REFERENCE.CATALOG.METRIC`** is the **sole metric object**; **`metric_code`** is unique and is the FK for tall
concept observation rows. **Do not** add **`REFERENCE.CATALOG.CONCEPT_METRIC`** unless many-to-many or
concept-specific aliases are proven necessary — default is **`METRIC.concept_code`** plus **`vendor_code`** /
**`dataset_code`** on the observation row.

**Governance:** ACS housing burden, renter counts, and similar fields must not stay loosely grouped under
market **rent** semantics — fix **`concept_code`** / **`metric_code`** in raw before treating them as P0
canonical rent measures (see **`docs/reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md`**).

**Vendor intake:** **`docs/migration/MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md`**. Do not treat other repo copies as a second source of truth.

## Metric Registration Gates

A metric column cannot be registered in `REFERENCE.DRAFT.CATALOG_METRIC` (seed `catalog_metric`) until it passes all four gates:

1. **Null coverage** — >80% non-null at stated grain
2. **History** — ≥12 months of data
3. **Catalog compliance** — geo_level_code, frequency_code, concept_code, vendor_code must exist as active rows in REFERENCE.CATALOG
4. **Census geography compliance** — geographic IDs must join to canonical census spine at ≥95% coverage; if not, a crosswalk is required before registration

## Concept row governance gate

Adding a new row to `seeds/reference/catalog/concept.csv` requires explicit approver confirmation in the PR/chat before merge.

- Treat concept-row additions as **schema-governance changes**, not routine data edits.
- Approval must include: proposed `concept_code`, semantic definition, why existing concepts are insufficient, and expected `CONCEPT_*` / metric assignment impact.
- Without explicit approval, do not add a new active concept row; use docs/backlog notes or inactive legacy aliases instead.

## Census Geography Compliance — Canonical Spines by Grain

| Grain | Canonical spine | Key |
|---|---|---|
| ZIP | Census ZIP/ZCTA crosswalk | GEO_ID → ZCTA → COUNTY_FIPS + CBSA_ID |
| County | FIPS 5-digit | COUNTY_FIPS |
| CBSA | OMB CBSA delineation | CBSA_ID |
| H3 | H3_XWALK in REFERENCE.GEOGRAPHY | H3_R8_HEX → COUNTY_FIPS + CBSA_ID |
| Tract | 11-digit GEOID | CENSUS_TRACT_ID |

Crosswalks required before metric registration live in REFERENCE.GEOGRAPHY (non-vendor) or TRANSFORM.DEV (vendor-specific, pending Jon promotion).

## Metric Column Classification

Only measurable, directional columns are registered as metrics. Two other column types are never registered:

- **Dimension/key columns** — grouping or join keys (CBSA_ID, H3_R8_HEX, AS_OF_MONTH)
- **Metadata columns** — pipeline bookkeeping (DBT_UPDATED_AT, VENDOR_NAME, SOURCE_DATASET)

## Tall-Format Tables (e.g. Zillow)

For tall/unpivoted FACT_ tables where one row = one metric observation:
- `snowflake_column = 'METRIC_VALUE'`
- `table_path = 'TRANSFORM.DEV.[TABLE_NAME]'`
- The specific series is identified by `METRIC_ID` filter — document in the **`definition`** field of **`REFERENCE.CATALOG.metric`** (`metric.csv`)

## TRANSFORM.FACT

TRANSFORM.FACT does not yet exist. Any dataset currently pointing to TRANSFORM.FACT has
pipeline_status = source_prod_only until Jon builds the canonical fact schema. Alex does not
create TRANSFORM.FACT — that is Jon's canonical promotion target.

## Geo Level Vocabulary Alignment

REFERENCE.CATALOG.geo_level is the source of truth for valid geo_level_code values:
[property, zip, county, cbsa, state, national]

Vendor-native geo labels must be normalized to catalog codes before a FACT_ table is
promotion-eligible. Example: Zillow uses 'metro' — must be normalized to 'cbsa'.
Vendor geo labels with no catalog equivalent (e.g. 'city', 'neighborhood') require
either a crosswalk to a supported grain or are excluded from metric registration.
