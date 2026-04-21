# Runbook — Zillow home values fact on **TRANSFORM.DEV** only

**See also:** [RUN_TRANSFORM_DEV_ZILLOW_RESEARCH_ALL.md](./RUN_TRANSFORM_DEV_ZILLOW_RESEARCH_ALL.md) (all ten Zillow research facts), [ZILLOW_LEGACY_OBJECTS_REPLACE_MAP.md](./ZILLOW_LEGACY_OBJECTS_REPLACE_MAP.md) (legacy `TRANSFORM_PROD` / `EDW_PROD` objects superseded by the new long-form facts).

**Purpose:** Build and smoke-test **`TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES`** using this repo’s contracts. Use this when you want **no `ADMIN.*`**, **no `TRANSFORM_PROD` / `ANALYTICS_PROD` / `EDW_PROD`**, and **no writes** outside the Alex dev surfaces this runbook calls out.

**Normative docs (read first):**

- [../rules/SCHEMA_RULES.md](../rules/SCHEMA_RULES.md) — DB/schema/prefix rules (`FACT_`, `REF_`, etc.).
- [../rules/ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md) — `TRANSFORM.DEV` owns dev **`FACT_*`** / **`CONCEPT_*`**; **`REF_*`** vendor xwalks stay here until promoted to **`TRANSFORM.[VENDOR]`**; tall facts use `snowflake_column = METRIC_VALUE`, `table_path = TRANSFORM.DEV.[TABLE_NAME]`.
- [../CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md) — optional **`REFERENCE.CATALOG`** / **`REFERENCE.DRAFT`** seed waves (vocabulary only; not required to compile the fact).

---

## 1. What this run **writes**

| Snowflake object | Role |
|------------------|------|
| **`TRANSFORM.DEV.REF_ZILLOW_COUNTY_TO_FIPS`** (and optional **`REF_ZILLOW_CITY_TO_COUNTY`**) | dbt **seed** — vendor xwalk per `schema_transform_dev.yml` |
| **`TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES`** | dbt **table** — model `models/transform/dev/zillow/fact_zillow_home_values.sql` (`alias = fact_zillow_home_values`) |

**Naming:** Fact table name is **`FACT_*`** (here `FACT_ZILLOW_HOME_VALUES`), database **`TRANSFORM`**, schema **`DEV`**, per `dbt_project.yml` `transform.dev.zillow` config.

---

## 2. What this run **reads** (you do not build these here)

The model compiles only if your role can **SELECT** these (declared in `models/sources/sources_transform.yml`):

| Source | Snowflake pattern | Purpose |
|--------|-------------------|---------|
| `source('zillow', 'raw_home_values')` | **`SOURCE_PROD.ZILLOW.RAW_HOME_VALUES`** | Raw VARIANT unpivot input |
| `source('zillow', 'zillow_all')` | **`SOURCE_PROD.ZILLOW.ZILLOW_ALL`** | State name → FIPS for state grain |
| `source('transform_ref', 'zillow_to_census_cbsa_mapping')` | **`TRANSFORM.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING`** | Metro → CBSA |
| `source('reference_geography', 'zip_county_xwalk')` | **`REFERENCE.GEOGRAPHY.ZIP_COUNTY_XWALK`** | ZIP → county |
| `source('reference_geography', 'county_cbsa_xwalk')` | **`REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK`** | County → CBSA (year from `reference_geography_year` var) |

If any of these are missing or your role lacks grants, **`dbt run` fails** — fix access or data loads first; do not repoint this model at `*_PROD` legacy schemas.

---

## 3. What this runbook **does not** do

- **No** `ADMIN.CATALOG` / `ADMIN.*` registration or MERGE scripts.
- **No** targets or selectors that materialize to **`ANALYTICS.DBT_PROD`**, **`TRANSFORM_PROD`**, **`EDW_PROD`**, etc.
- **No** promotion to **`TRANSFORM.FACT`** (Jon-owned); see `ARCHITECTURE_RULES.md` — Alex does not create **`TRANSFORM.FACT`** in this repo.

Optional **governance-only** work (separate from fact build): seed **`REFERENCE.CATALOG`** / **`REFERENCE.DRAFT`** per [../CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md) and populate **`reference/draft/catalog_metric.csv`** when you are ready to record a **`metric_id`** with valid catalog codes — still **not** `ADMIN`.

---

## 4. Environment

1. Repo root for commands:

   `pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/`

2. **`~/.dbt/profiles.yml`** — use the **`dev`** output from [../PROFILES_TEMPLATE.md](../PROFILES_TEMPLATE.md) (`database: ANALYTICS`, `schema: DBT_DEV`). **`transform.dev.zillow`** models override relation database to **`TRANSFORM`** and schema **`DEV`**; seeds under `transform_dev` use **`TRANSFORM.DEV`** per `dbt_project.yml`.

3. **Warehouse:** Home values is heavy; the model defaults to **`LOAD_WH`** via `var('zillow_home_values_warehouse', 'LOAD_WH')`. Override if your profile role cannot use it:

   ```bash
   dbt run --target dev --select fact_zillow_home_values --vars '{"zillow_home_values_warehouse": "YOUR_WH"}'
   ```

---

## 5. Commands to run (order)

From the repo root in §4:

```bash
# 0) Dependencies (once per clone / after package changes)
dbt deps --target dev
```

```bash
# 1) Vendor REF_ seeds → TRANSFORM.DEV (required for county / metro enrichment joins)
dbt seed --target dev --select ref_zillow_county_to_fips ref_zillow_city_to_county
```

```bash
# 2) Build the fact table → TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES
# First-time or full rebuild of an incremental (if ever changed to incremental):
dbt run --target dev --select fact_zillow_home_values --full-refresh

# Steady state (table materialization — use full-refresh if you need a clean rebuild):
dbt run --target dev --select fact_zillow_home_values
```

```bash
# 3) Optional — model tests defined in models/transform/dev/zillow/schema.yml
dbt test --target dev --select fact_zillow_home_values
```

**Optional — catalog vocabulary only** (does not build the fact; uses **`--target reference`** per template):

```bash
# After populating seeds per CATALOG_SEED_ORDER.md waves 1–5, then vendor/dataset/metric as needed:
dbt seed --target reference --select reference.catalog.geo_level reference.catalog.frequency reference.catalog.concept
# …continue waves from ../CATALOG_SEED_ORDER.md …
dbt seed --target reference --select reference.draft.catalog_metric
```

---

## 6. Smoke checks in Snowflake (read **`TRANSFORM.DEV`** only)

**Row count (ZIP grain):**

```sql
SELECT COUNT(*) AS row_count
FROM TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES
WHERE geo_level_code = 'zip';
```

**Discover `metric_id` values (filename-derived — use for catalog rows / definitions):**

```sql
SELECT
    metric_id,
    source_file_name,
    COUNT(*) AS n
FROM TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES
WHERE geo_level_code = 'zip'
GROUP BY 1, 2
ORDER BY n DESC
LIMIT 50;
```

**Single-series smoke (replace `<METRIC_ID>` after the query above):**

```sql
SELECT
    geo_id,
    date_reference,
    metric_value,
    county_fips,
    cbsa_id,
    has_census_geo
FROM TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES
WHERE geo_level_code = 'zip'
  AND metric_id = '<METRIC_ID>'
ORDER BY date_reference DESC
LIMIT 25;
```

---

## 7. Operational notes

- **`metric_id`** in this fact is derived from the Zillow research **file name** (see macro `macros/zillow/unpivot_zillow_research_long.sql`); do not assume legacy ids like `ZILLOW_ZHVI` without verifying §6.
- **Metro / MSA** vendor labels are normalized to catalog **`geo_level_code = 'cbsa'`** in `zillow_research_fact_enriched` — aligns with **`SCHEMA_RULES.md`** / **`ARCHITECTURE_RULES.md`**.
- **`city`** and **`neighborhood`** rows are excluded upstream of the final select — do not register metrics at those grains from this pipeline until a supported crosswalk exists.

---

## 8. Change log

| Date | Author | Change |
|------|--------|--------|
| 2026-04-18 | Cursor agent | Initial runbook — TRANSFORM.DEV–scoped build/smoke; no ADMIN / `*_PROD`. |
