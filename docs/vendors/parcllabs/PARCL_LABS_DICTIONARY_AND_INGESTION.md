# Parcl Labs: Data Dictionary and Ingestion Structure

**Purpose:** Document Parcl Labs metrics we use, map them to the [Parcl Labs API](https://docs.parcllabs.com/reference/search_markets_v1_search_markets_get) (Search Markets + Housing Metrics), and define the structure to ingest the dictionary into DIM_METRIC (seed + `register_parcl_metrics.sql`).

**See also:** [REDFIN_VS_PARCL_METRIC_STRUCTURE.md](../../governance/REDFIN_VS_PARCL_METRIC_STRUCTURE.md), [DATA_DICTIONARY_WISHLIST.md](../../governance/DATA_DICTIONARY_WISHLIST.md), [DICTIONARY_TO_CANON.md](../../governance/DICTIONARY_TO_CANON.md).

---

## 1. Geography: Search Markets API

Parcl uses **parcl_id** (unique per market, no hierarchy) and optional **geoid** (Census 5–7 digits).

- **Endpoint:** [Search Markets](https://docs.parcllabs.com/reference/search_markets_v1_search_markets_get) `GET /v1/search/markets`
- **Query params:** `query`, `location_type`, `region`, `state_abbreviation`, `state_fips_code`, `parcl_id`, **`geoid`**, `sort_by`, `sort_order`, `limit`, `offset`
- **location_type:** `COUNTY`, `CITY`, **`ZIP5`**, `CDP`, `VILLAGE`, `TOWN`, **`CBSA`**, `ALL`
- **Response:** `parcl_id`, `country`, **`geoid`**, `state_fips_code`, `name`, `state_abbreviation`, `region`, **`location_type`**, `total_population`, …

**Pipeline:** Prefer **geoid** (ZIP5, CBSA) for canonical geography; resolve parcl_id → geoid via Search Markets or a ref table. Set GEOGRAPHY_LEVELS in DIM_METRIC to `["ZIP5","CBSA","COUNTY","CITY"]` for Parcl metrics.

---

## 2. Existing Parcl metrics in our pipeline (INGESTED = TRUE)

These metric_ids are used in facts, marts, features, or signals. All are Parcl Labs–sourced.

### 2.1 Inventory / for-sale (HOU_INVENTORY)

| METRIC_ID | Description | Source table / API |
|-----------|-------------|--------------------|
| PARCLLABS_ACTIVE_LISTING_COUNT | Active for-sale listing count | fact_parcllabs_inventory (comps); Parcl “For Sale Inventory” |
| PARCLLABS_MEDIAN_DOM | Median days on market | fact_parcllabs_inventory; Housing Event metrics |
| PARCLLABS_NEW_LISTINGS_FOR_SALE | New listings for sale | PARCLLABS_ZIP_ABSORPTION_HISTORY; Parcl “New Listings Rolling Counts” (for sale) |
| PARCLLABS_MONTHS_OF_SUPPLY | Months of supply | mart_metric_months_supply; absorption history |
| PARCLLABS_SALES | Closed sales count | PARCLLABS_ZIP_ABSORPTION_HISTORY; Housing Event Counts |
| PARCLLABS_FOR_SALE_INVENTORY | For-sale inventory | Absorption / For Sale Inventory API |
| PARCLLABS_ABSORPTION_RATE | Absorption rate | PARCLLABS_ZIP_ABSORPTION_HISTORY (SALES / NEW_LISTINGS_FOR_SALE) |
| PARCLLABS_ABSORPTION_RATE_NEW | Absorption rate (alternate) | Same |
| PARCLLABS_NEW_LISTINGS | New listings (generic) | feature_rolling_metrics |

### 2.2 Pricing (HOU_PRICING)

| METRIC_ID | Description | Source table / API |
|-----------|-------------|--------------------|
| PARCLLABS_MEDIAN_RENT_NEW_LISTINGS | Median rent (new rental listings) | fact_parcllabs_rent_listings; Housing Event Prices / Rental Price Feed |
| PARCLLABS_MEDIAN_RENT_LISTING | Median rent (listings) | fact_parcllabs_rent_listings |
| PARCLLABS_RENT_LISTINGS_COUNT | Count of rent listings | fact_parcllabs_rent_listings |
| PARCLLABS_AVG_BEDROOMS_LISTING | Avg bedrooms (listings) | fact_parcllabs_rent_listings |
| PARCLLABS_AVG_SQFT_LISTING | Avg sqft (listings) | fact_parcllabs_rent_listings |

Fact layer also uses fallback names: `HOUSING.HOU_PRICING.MEDIAN_RENT_PARCLLABS`, `HOUSING.HOU_PRICING.MEDIAN_RENT_PER_SQFT_PARCLLABS`.

### 2.3 Ownership / investor (HOU_OWNERSHIP)

| METRIC_ID | Description | Source table / API |
|-----------|-------------|--------------------|
| PARCLLABS_OWNERSHIP_PORTFOLIO_2_9_UNITS | Units in 2–9 unit portfolios | fact_parcllabs_ownership; SF Housing Stock Ownership |
| PARCLLABS_OWNERSHIP_PORTFOLIO_10_99_UNITS | Units in 10–99 unit portfolios | fact_parcllabs_ownership |
| PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS | Units in 100–999 unit portfolios | fact_parcllabs_ownership |
| PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS | Units in 1000+ unit portfolios | fact_parcllabs_ownership |
| PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS | All portfolio units | fact_parcllabs_ownership |
| PARCLLABS_HOUSING_STOCK_SF_UNITS | SFR housing stock (units) | fact_parcllabs_ownership; Housing Stock API |
| PARCLLABS_OWNERSHIP_PCT_PORTFOLIO_100_999 | % units in 100–999 portfolios | fact_parcllabs_ownership |
| PARCLLABS_OWNERSHIP_PCT_PORTFOLIO_1000_PLUS | % units in 1000+ portfolios | fact_parcllabs_ownership |
| PARCLLABS_OWNERSHIP_PCT_ALL_PORTFOLIOS | % all portfolios | fact_parcllabs_ownership |
| PARCLLABS_COUNT_PORTFOLIO_2_TO_9 | Raw count 2–9 (alternate) | fact_parcllabs_sf_housing_stock |
| PARCLLABS_COUNT_PORTFOLIO_10_TO_99 | Raw count 10–99 | fact_parcllabs_sf_housing_stock |
| PARCLLABS_COUNT_PORTFOLIO_100_TO_999 | Raw count 100–999 | fact_parcllabs_sf_housing_stock |
| PARCLLABS_COUNT_PORTFOLIO_1000_PLUS | Raw count 1000+ | fact_parcllabs_sf_housing_stock |
| PARCLLABS_COUNT_ALL_PORTFOLIOS | Raw count all portfolios | fact_parcllabs_sf_housing_stock |

### 2.4 Stock / supply (HOU_INVENTORY)

| METRIC_ID | Description | Source table / API |
|-----------|-------------|--------------------|
| PARCLLABS_STOCK_SFR | SFR housing stock | feature_supply_pressure_metrics |
| PARCLLABS_STOCK_CONDO | Condo stock | Housing Stock API |
| PARCLLABS_STOCK_TOWNHOUSE | Townhouse stock | Housing Stock API |
| PARCLLABS_STOCK_ALL | Total housing stock | Housing Stock API |

### 2.5 Other

| METRIC_ID | Description |
|-----------|-------------|
| PARCLLABS_MARKET_PRESENCE | Market presence (fact_parcllabs_market_presence) |
| PARCLLABS_PARTIES_AGGREGATE / PARCLLABS_PARTIES_GEO | Party/geography aggregates |

---

## 3. Parcl Housing Metrics API → our structure

| Parcl API area | Endpoints (examples) | Our domain/taxon | Notes |
|----------------|----------------------|------------------|-------|
| **Market metrics** | All Cash, Housing Event Counts/Prices, Housing Event Property Attributes, Housing Stock | HOUSING / HOU_INVENTORY, HOU_PRICING | Sales, inventory, DOM, prices |
| **For Sale** | For Sale Inventory, For Sale Inventory Price Changes, New Listings Rolling Counts | HOU_INVENTORY, HOU_PRICING | Align with REDFIN_* names |
| **Rental** | Gross Yield, New Listings For Rent Rolling Counts, Rental Units Concentration | HOU_PRICING, HOU_INVENTORY | Rental context |
| **Investor** | Housing Event Counts/Prices, Housing Stock Ownership, New Listings For Sale, Purchase To Sale Ratio | HOU_OWNERSHIP, HOU_INVENTORY | PARCLLABS_OWNERSHIP_* |
| **Portfolio** | Sf Housing Event Counts, Sf Housing Stock Ownership, Sf New Listings For Rent/For Sale | HOU_OWNERSHIP, HOU_INVENTORY | SFR segment |
| **New Construction** | New Construction Housing Event Counts/Prices | HOU_INVENTORY / HOU_CONSTRUCTION | |
| **Price Feed / Rental Price Feed** | Post Latest Rental Price Feed, etc. | HOU_PRICING | fact_parcllabs_pricing |

---

## 4. Ingestion structure (dictionary → DIM_METRIC)

1. **Seed:** `seeds/metric_catalog_parcl_full.csv` — same columns as Redfin: `metric_key`, `metric_name`, `domain`, `taxon`, `unit`, `frequency`, `geography`, `description`.
2. **Load:** `dbt seed` → `SOURCE_PROD.PARCLLABS.METRIC_CATALOG_PARCL_FULL` (via `dbt_project.yml`).
3. **Register:** `scripts/sql/admin/catalog/register_parcl_metrics.sql` — INSERT into ADMIN.CATALOG.DIM_METRIC from seed, METRIC_VENDOR_NAME = 'PARCLLABS', INGESTED = TRUE, GEOGRAPHY_LEVELS = `["ZIP5","CBSA","COUNTY","CITY"]`.
4. **Runner:** `scripts/run_parcl_registration.sh` (optional) — run after `dbt seed`.

Product type: Parcl is SFR-focused; use PRODUCT_TYPE_CODE = 'SFR' or 'ALL' as appropriate. Pillar: Units (SFR), Bedrooms (from listing/API); map to ref_bedroom_count_to_canonical.

---

## 5. John Burns (JBREC) and ApartmentIQ — external dictionary files

You referenced:

- **John Burns:** `JBREC_Fields_Comparison.xlsx` (OneDrive/Code paths), `John_Burns_Methodology_and_Data_Analysis.md`
- **ApartmentIQ:** `ApartmentIQ Glossary of Terms - MS Glossary of Terms.pdf`, `Summary on ApartmentIQ Data Processing.pdf`

Those paths are **outside this repo** (OneDrive, Downloads), so they are not readable by Cursor in this workspace.

**To add JBREC and ApartmentIQ dictionaries:**

1. Copy the relevant field lists (and, if possible, definitions) into the repo, for example:
   - `seeds/jbrec_fields_comparison.csv` or `seeds/metric_catalog_jbrec_full.csv`
   - `seeds/apartmentiq_glossary.csv` or `seeds/metric_catalog_apartmentiq_full.csv`
2. Add seed config in `dbt_project.yml` (e.g. `+database: source_prod`, `+schema: jbrec` / `apartmentiq`).
3. Add source definitions in `models/sources.yml` for the new seed tables.
4. Then we can add `register_jbrec_dictionary_metrics.sql` and `register_apartmentiq_metrics.sql` following the same pattern as Parcl/Redfin.

**Existing in repo:** We already have `cleaned_jbrec_*` and `cleaned_apartmentsiq_*` models and ApartmentIQ fact/validation scripts; see `docs/governance/APARTMENTIQ_CLEANED_AND_FACT.md` and `models/transform_prod/cleaned/jbrec_sfr_metrics.sql`. Dictionary registration will link those to DIM_METRIC once the seed CSVs are in the repo.
