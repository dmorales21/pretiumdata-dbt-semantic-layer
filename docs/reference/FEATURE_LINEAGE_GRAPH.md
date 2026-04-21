# FEATURE lineage graph (manual registry)

Slug **`feature_lineage_graph`** (1): dbt does not emit a queryable `ref()` graph in Snowflake; this page is the **human + PR** registry for **each `FEATURE_*` model’s primary upstreams** (extend when adding models).

| dbt model | Snowflake-style object (dev) | Primary upstreams (`ref` / `source`) | Notes |
|-----------|------------------------------|----------------------------------------|--------|
| `feature_rent_market_monthly_spine` | `ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY` | `ref('concept_rent_market_monthly')` | Pass-through spine; columns mirror concept. |
| `feature_listings_velocity_monthly_spine` | `ANALYTICS.DBT_DEV.FEATURE_LISTINGS_VELOCITY_MONTHLY` | `ref('fact_zillow_days_on_market_and_price_cuts')`, `ref('fact_zillow_for_sale_listings')` | **TODO:** reshape to `ref('concept_listings_market_monthly')` per model header. |
| `feature_employment_delta_cbsa_monthly` | `ANALYTICS.DBT_DEV.FEATURE_EMPLOYMENT_DELTA_CBSA_MONTHLY` | `ref('fact_bls_laus_county')`, `source('reference_geography','county_cbsa_xwalk')` | County roll → CBSA YoY; concept observe panel separate. |
| `feature_home_price_delta_zip_monthly` | `ANALYTICS.DBT_DEV.FEATURE_HOME_PRICE_DELTA_ZIP_MONTHLY` | `ref('fact_zillow_home_values')` | ZIP delta; align with concept home price when ready. |
| `feature_supply_pressure_cbsa_monthly` | `ANALYTICS.DBT_DEV.FEATURE_SUPPLY_PRESSURE_CBSA_MONTHLY` | `ref('fact_realtor_inventory_cbsa')` | **TODO:** concept listings spine. |
| `feature_ai_replacement_risk_county` | `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_COUNTY` | `ref('fact_county_ai_replacement_risk')` | County FACT read-through. |
| `feature_ai_replacement_risk_cbsa` | `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_CBSA` | `ref('fact_county_ai_replacement_risk')` | Roll-up to CBSA. |
| `feature_ai_replacement_risk_cbsa_rollup` | `ANALYTICS.DBT_DEV.FEATURE_AI_REPLACEMENT_RISK_CBSA_ROLLUP` | `ref('feature_ai_replacement_risk_cbsa')` | Nested FEATURE. |
| `feature_ai_risk_county_bivariate` | `ANALYTICS.DBT_DEV.FEATURE_AI_RISK_COUNTY_BIVARIATE` | `ref('fact_county_ai_replacement_risk')`, `ref('fact_aige_counties')` | Gated AIGE strand. |
| `feature_structural_unemployment_risk_county` | `ANALYTICS.DBT_DEV.FEATURE_STRUCTURAL_UNEMPLOYMENT_RISK_COUNTY` | `ref('feature_ai_replacement_risk_county')` | Derived from FEATURE. |

**Automation backlog:** generate this table from `manifest.json` (`parent_map`) in CI and diff vs this file.
