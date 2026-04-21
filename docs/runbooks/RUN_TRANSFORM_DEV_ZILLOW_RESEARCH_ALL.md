# Runbook — All Zillow Research facts on **TRANSFORM.DEV**

**Purpose:** Build every **`FACT_ZILLOW_*`** model under `models/transform/dev/zillow/` in one pass, using the same contracts as [RUN_TRANSFORM_DEV_ZILLOW_HOME_VALUES.md](./RUN_TRANSFORM_DEV_ZILLOW_HOME_VALUES.md).

**Normative docs:** [../rules/SCHEMA_RULES.md](../rules/SCHEMA_RULES.md), [../rules/ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md), [../CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md).

**Related:** Legacy objects these facts supersede (conceptually) are listed in [ZILLOW_LEGACY_OBJECTS_REPLACE_MAP.md](./ZILLOW_LEGACY_OBJECTS_REPLACE_MAP.md).

---

## 1. Models and upstream `RAW_*` landings

Each model is a thin wrapper on `zillow_research_fact_enriched('<raw_table>', '<dataset_slug>')`. All read **`SOURCE_PROD.ZILLOW`** via `sources_transform.yml`.

| dbt model | Snowflake relation | `source('zillow', …)` |
|-----------|-------------------|------------------------|
| `fact_zillow_affordability` | `TRANSFORM.DEV.FACT_ZILLOW_AFFORDABILITY` | `raw_affordability` |
| `fact_zillow_days_on_market_and_price_cuts` | `TRANSFORM.DEV.FACT_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS` | `raw_days_on_market_and_price_cuts` |
| `fact_zillow_for_sale_listings` | `TRANSFORM.DEV.FACT_ZILLOW_FOR_SALE_LISTINGS` | `raw_for_sale_listings` |
| `fact_zillow_home_values` | `TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES` | `raw_home_values` |
| `fact_zillow_home_values_forecasts` | `TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES_FORECASTS` | `raw_home_values_forecasts` |
| `fact_zillow_market_heat_index` | `TRANSFORM.DEV.FACT_ZILLOW_MARKET_HEAT_INDEX` | `raw_market_heat_index` |
| `fact_zillow_new_construction` | `TRANSFORM.DEV.FACT_ZILLOW_NEW_CONSTRUCTION` | `raw_new_construction` |
| `fact_zillow_rental_forecasts` | `TRANSFORM.DEV.FACT_ZILLOW_RENTAL_FORECASTS` | `raw_rental_forecasts` |
| `fact_zillow_rentals` | `TRANSFORM.DEV.FACT_ZILLOW_RENTALS` | `raw_rentals` |
| `fact_zillow_sales` | `TRANSFORM.DEV.FACT_ZILLOW_SALES` | `raw_sales` |

Shared read-only dependencies (same as the single-model runbook): **`TRANSFORM.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING`**, **`REFERENCE.GEOGRAPHY`** xwalks, **`SOURCE_PROD.ZILLOW.ZILLOW_ALL`**, plus seeds **`TRANSFORM.DEV.REF_ZILLOW_*`**.

---

## 2. Commands (from repo root `pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/`)

```bash
dbt deps --target dev
```

```bash
dbt seed --target dev --select ref_zillow_county_to_fips ref_zillow_city_to_county
```

**All Zillow research facts** (tag `fact_zillow` is on each model):

```bash
dbt run --target dev --select tag:fact_zillow
```

Equivalent path selector:

```bash
dbt run --target dev --select path:models/transform/dev/zillow
```

**First materialization or full rebuild** (large tables — expect runtime and warehouse load):

```bash
dbt run --target dev --select tag:fact_zillow --full-refresh
```

**`FACT_ZILLOW_HOME_VALUES` only** — default warehouse is **`LOAD_WH`** via `var('zillow_home_values_warehouse', 'LOAD_WH')`. Override if needed:

```bash
dbt run --target dev --select fact_zillow_home_values --full-refresh \
  --vars '{"zillow_home_values_warehouse": "YOUR_WH"}'
```

**Tests** (only where defined on these models):

```bash
dbt test --target dev --select tag:fact_zillow
```

---

## 3. Smoke pattern (per fact)

Use the same **`metric_id`** discovery as the home-values runbook: series id is **filename-derived** in `unpivot_zillow_research_long`.

```sql
-- Example: rentals at ZIP grain
SELECT metric_id, source_file_name, COUNT(*) AS n
FROM TRANSFORM.DEV.FACT_ZILLOW_RENTALS
WHERE geo_level_code = 'zip'
GROUP BY 1, 2
ORDER BY n DESC
LIMIT 30;
```

Repeat with `FACT_ZILLOW_SALES`, `FACT_ZILLOW_HOME_VALUES`, etc.

---

## 4. Run order and ops notes

- There is **no dbt dependency edge** between the ten facts; one `dbt run` fan-out is fine.
- **Largest / slowest:** `fact_zillow_home_values` — run alone with `--full-refresh` + `LOAD_WH` if the combined run times out.
- **Duplicate migration path:** `pretium-ai-dbt` still contains `dbt/models/transform/dev/zillow_research/fact_zillow_*.sql` mirroring these. **Canonical build for the new contract is this repo**; retire duplicate runs from `pretium-ai-dbt` when your team agrees (see replacement map).

---

## 5. Change log

| Date | Author | Change |
|------|--------|--------|
| 2026-04-18 | Cursor agent | Initial “all Zillow research facts” runbook + RAW_* mapping table. |
